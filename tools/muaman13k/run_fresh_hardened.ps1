# MUAMAN-13K fresh-process hardened build controller.
# Spawns a genuinely new powershell.exe process that runs the committed
# MUAMAN-13J hardened wrapper (from the independent source tree) under an
# explicitly constructed environment, and captures all fresh-process evidence:
# environment-before/inherited/effective snapshots, PID/PPID, PowerShell
# version/exe, start/end timestamps, duration, stdout/stderr, and exit code.
#
# The build therefore runs in a process that is never reused for another
# acceptance run and depends on no controller-shell functions, aliases,
# variables, or imported modules: every required value is embedded as a literal
# in a generated per-run runner script.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File run_fresh_hardened.ps1 ^
#       -RunId K1 -AppRoot <app> -SdkRoot <sdk> -PubCache <pub> -TmpRoot <tmp> ^
#       -HomeRoot <home> -EvidenceDir <dir> [-MsBuildBinDir <dir>]

param(
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(Mandatory=$true)][string]$AppRoot,
  [Parameter(Mandatory=$true)][string]$SdkRoot,
  [Parameter(Mandatory=$true)][string]$PubCache,
  [Parameter(Mandatory=$true)][string]$TmpRoot,
  [Parameter(Mandatory=$true)][string]$HomeRoot,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [string]$MsBuildBinDir = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64'
)
$ErrorActionPreference = 'Stop'

$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
$AppRoot = [System.IO.Path]::GetFullPath($AppRoot)
$SdkRoot = [System.IO.Path]::GetFullPath($SdkRoot)
$PubCache = [System.IO.Path]::GetFullPath($PubCache)
$TmpRoot = [System.IO.Path]::GetFullPath($TmpRoot)
$HomeRoot = [System.IO.Path]::GetFullPath($HomeRoot)
$MsBuildBinDir = [System.IO.Path]::GetFullPath($MsBuildBinDir)
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

# The hardened wrapper is taken from the INDEPENDENT SOURCE TREE, not from the
# controller worktree, proving it works from independent source locations.
$sourceRoot = Split-Path -Parent $AppRoot
$wrapperPath = Join-Path $sourceRoot 'tools\muaman13j\build_hardened.ps1'
if (-not (Test-Path -LiteralPath $wrapperPath)) {
  Write-Error ("Committed hardened wrapper not found in source tree: {0}" -f $wrapperPath)
  exit 1
}
$wrapperSha = (Get-FileHash -LiteralPath $wrapperPath -Algorithm SHA256).Hash
$preflightSha = (Get-FileHash -LiteralPath (Join-Path (Split-Path -Parent $wrapperPath) 'check_filetracker_state.ps1') -Algorithm SHA256).Hash

# ---------- environment-before (controller process) ----------
$beforeNames = @(
  'TEMP','TMP','USERPROFILE','HOME','LOCALAPPDATA','APPDATA','ProgramData','SystemRoot',
  'WINDIR','ComSpec','PATH','PATHEXT','FLUTTER_ROOT','PUB_CACHE','DART_SDK','DART_HOME',
  'FLUTTER_BIN','VSINSTALLDIR','VCINSTALLDIR','VCToolsInstallDir','VisualStudioVersion',
  'MSBuildSDKsPath','MSBUILDDEBUGPATH','TRACKER_ADDPIDTOCMDLINE','CI','FLUTTER_SUPPRESS_ANALYTICS'
)
$before = [ordered]@{ runId = $RunId; capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }
foreach ($n in $beforeNames) { $before[$n] = [string][Environment]::GetEnvironmentVariable($n, 'Process') }
$before['PATH_LEN'] = ([string]$env:PATH).Length
$before | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDir 'environment-before.json') -Encoding UTF8

# ---------- generate the per-run runner script ----------
# A single-quoted here-string contains NO interpolation; placeholders are
# substituted afterwards with single-quoted literal values.
$runner = Join-Path $EvidenceDir 'runner.ps1'
function Esc([string]$s) { return $s.Replace("'", "''") }

$tpl = @'
# MUAMAN-13K generated fresh-process runner for run '__RUNID__'.
# Self-contained: every value is a literal; no controller-shell state is used.
$ErrorActionPreference = 'Stop'

# ---- process identity ----
$startUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").CommandLine
[pscustomobject][ordered]@{
  runId = '__RUNID__'
  pid = $PID
  parentPid = $ppid
  psVersion = $PSVersionTable.PSVersion.ToString()
  psExePath = (Get-Process -Id $PID).Path
  commandLine = $cmdLine
  startUtc = $startUtc
} | ConvertTo-Json | Set-Content -LiteralPath '__EVIDENCEDIR__\process-info.json' -Encoding UTF8

# ---- snapshot inherited environment (sensitive vars excluded) ----
Get-ChildItem Env: | Sort-Object Name | Where-Object { $_.Name -notmatch '^OPENCODE_SERVER_' } | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath '__EVIDENCEDIR__\environment-inherited.txt' -Encoding UTF8

# ---- clear leftover experiment/VS state that must NOT be inherited ----
foreach ($v in @('FLUTTER_ROOT','DART_HOME','DART_SDK','FLUTTER_BIN','VSINSTALLDIR','VCINSTALLDIR','VCToolsInstallDir','VisualStudioVersion','MSBuildSDKsPath','MSBUILDDEBUGPATH','TRACKER_ADDPIDTOCMDLINE')) {
  Set-Item -Path "Env:\$v" -Value '' -ErrorAction SilentlyContinue
}
$env:PROGRAMDATA = 'C:\ProgramData'
$env:PUB_CACHE = '__PUBCACHE__'
$env:TEMP = '__TMPROOT__'
$env:TMP = '__TMPROOT__'
$env:HOME = '__HOMEROOT__'
$env:USERPROFILE = '__HOMEROOT__'
$env:APPDATA = Join-Path '__HOMEROOT__' 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path '__HOMEROOT__' 'appdata\local'
$env:NUGET_PACKAGES = Join-Path '__HOMEROOT__' 'appdata\local\NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:MSBUILDDISABLENODEREUSE = '1'
$env:PATH = (Join-Path '__SDKROOT__' 'bin') + ';' + $env:PATH

# ---- effective environment snapshot (what the wrapper will see; sensitive vars excluded) ----
Get-ChildItem Env: | Sort-Object Name | Where-Object { $_.Name -notmatch '^OPENCODE_SERVER_' } | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath '__EVIDENCEDIR__\environment-effective.txt' -Encoding UTF8

# ---- invoke the committed hardened wrapper ----
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File '__WRAPPER__' `
  -ExperimentId '__RUNID__' -AppRoot '__APPROOT__' -SdkRoot '__SDKROOT__' -PubCache '__PUBCACHE__' `
  -TmpRoot '__TMPROOT__' -HomeRoot '__HOMEROOT__' -EvidenceDir '__EVIDENCEDIR__' -MsBuildBinDir '__MSBUILDDIR__'
$exitCode = $LASTEXITCODE
$endUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
[ordered]@{
  runId = '__RUNID__'
  exitCode = $exitCode
  endUtc = $endUtc
} | ConvertTo-Json | Set-Content -LiteralPath '__EVIDENCEDIR__\runner-exit.json' -Encoding UTF8
exit $exitCode
'@

$runnerContent = $tpl
$runnerContent = $runnerContent.Replace('__RUNID__', (Esc $RunId))
$runnerContent = $runnerContent.Replace('__EVIDENCEDIR__', (Esc $EvidenceDir))
$runnerContent = $runnerContent.Replace('__PUBCACHE__', (Esc $PubCache))
$runnerContent = $runnerContent.Replace('__TMPROOT__', (Esc $TmpRoot))
$runnerContent = $runnerContent.Replace('__HOMEROOT__', (Esc $HomeRoot))
$runnerContent = $runnerContent.Replace('__SDKROOT__', (Esc $SdkRoot))
$runnerContent = $runnerContent.Replace('__APPROOT__', (Esc $AppRoot))
$runnerContent = $runnerContent.Replace('__WRAPPER__', (Esc $wrapperPath))
$runnerContent = $runnerContent.Replace('__MSBUILDDIR__', (Esc $MsBuildBinDir))
Set-Content -LiteralPath $runner -Value $runnerContent -Encoding UTF8

# ---------- command.txt ----------
$commandLine = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$runner`""
[ordered]@{
  runId = $RunId
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  commandLine = $commandLine
  wrapperSha256 = $wrapperSha
  preflightSha256 = $preflightSha
  appRoot = $AppRoot
  sdkRoot = $SdkRoot
  pubCache = $PubCache
  tmpRoot = $TmpRoot
  homeRoot = $HomeRoot
  msBuildBinDir = $MsBuildBinDir
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDir 'command.txt') -Encoding UTF8

# ---------- launch the fresh process ----------
$stdout = Join-Path $EvidenceDir 'stdout.log'
$stderr = Join-Path $EvidenceDir 'stderr.log'
$outerStart = [DateTime]::UtcNow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$proc = Start-Process -FilePath 'powershell.exe' `
  -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$runner) `
  -PassThru -WindowStyle Hidden `
  -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$proc.WaitForExit()
$sw.Stop()
$outerEnd = [DateTime]::UtcNow
$exitCode = $proc.ExitCode

$outerInfo = [ordered]@{
  runId = $RunId
  outerStartUtc = $outerStart.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  outerEndUtc = $outerEnd.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  durationSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
  pid = $proc.Id
  exitCode = $exitCode
}
$outerInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDir 'process-info-outer.json') -Encoding UTF8
[math]::Round($sw.Elapsed.TotalSeconds, 1) | Set-Content -LiteralPath (Join-Path $EvidenceDir 'duration.txt') -Encoding UTF8
$exitCode | Set-Content -LiteralPath (Join-Path $EvidenceDir 'exit-code.txt') -Encoding UTF8

Write-Output ("MUAMAN-13K {0}: fresh-process exit={1} pid={2} duration={3}s" -f $RunId, $exitCode, $proc.Id, [math]::Round($sw.Elapsed.TotalSeconds, 1))
exit $exitCode
