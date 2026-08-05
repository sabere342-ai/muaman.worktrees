# MUAMAN-13K generated fresh-process runner for run 'K1'.
# Self-contained: every value is a literal; no controller-shell state is used.
$ErrorActionPreference = 'Stop'

# ---- process identity ----
$startUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").CommandLine
[pscustomobject][ordered]@{
  runId = 'K1'
  pid = $PID
  parentPid = $ppid
  psVersion = $PSVersionTable.PSVersion.ToString()
  psExePath = (Get-Process -Id $PID).Path
  commandLine = $cmdLine
  startUtc = $startUtc
} | ConvertTo-Json | Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\process-info.json' -Encoding UTF8

# ---- snapshot inherited environment ----
Get-ChildItem Env: | Sort-Object Name | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\environment-inherited.txt' -Encoding UTF8

# ---- clear leftover experiment/VS state that must NOT be inherited ----
foreach ($v in @('FLUTTER_ROOT','DART_HOME','DART_SDK','FLUTTER_BIN','VSINSTALLDIR','VCINSTALLDIR','VCToolsInstallDir','VisualStudioVersion','MSBuildSDKsPath','MSBUILDDEBUGPATH','TRACKER_ADDPIDTOCMDLINE')) {
  Set-Item -Path "Env:\$v" -Value '' -ErrorAction SilentlyContinue
}
$env:PROGRAMDATA = 'C:\ProgramData'
$env:PUB_CACHE = 'C:\m13k\a\pub'
$env:TEMP = 'C:\m13k\a\tmp'
$env:TMP = 'C:\m13k\a\tmp'
$env:HOME = 'C:\m13k\a\home'
$env:USERPROFILE = 'C:\m13k\a\home'
$env:APPDATA = Join-Path 'C:\m13k\a\home' 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path 'C:\m13k\a\home' 'appdata\local'
$env:NUGET_PACKAGES = Join-Path 'C:\m13k\a\home' 'appdata\local\NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:MSBUILDDISABLENODEREUSE = '1'
$env:PATH = (Join-Path 'C:\m13i\a\sdk' 'bin') + ';' + $env:PATH

# ---- effective environment snapshot (what the wrapper will see) ----
Get-ChildItem Env: | Sort-Object Name | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\environment-effective.txt' -Encoding UTF8

# ---- invoke the committed hardened wrapper ----
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\m13k\a\src\tools\muaman13j\build_hardened.ps1' `
  -ExperimentId 'K1' -AppRoot 'C:\m13k\a\src\app' -SdkRoot 'C:\m13i\a\sdk' -PubCache 'C:\m13k\a\pub' `
  -TmpRoot 'C:\m13k\a\tmp' -HomeRoot 'C:\m13k\a\home' -EvidenceDir 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp' -MsBuildBinDir 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64'
$exitCode = $LASTEXITCODE
$endUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
[ordered]@{
  runId = 'K1'
  exitCode = $exitCode
  endUtc = $endUtc
} | ConvertTo-Json | Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\runner-exit.json' -Encoding UTF8
exit $exitCode
