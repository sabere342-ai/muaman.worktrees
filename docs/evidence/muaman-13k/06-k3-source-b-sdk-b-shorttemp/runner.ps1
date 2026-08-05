# MUAMAN-13K generated fresh-process runner for run 'K3'.
# Self-contained: every value is a literal; no controller-shell state is used.
$ErrorActionPreference = 'Stop'

# ---- process identity ----
$startUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").CommandLine
[pscustomobject][ordered]@{
  runId = 'K3'
  pid = $PID
  parentPid = $ppid
  psVersion = $PSVersionTable.PSVersion.ToString()
  psExePath = (Get-Process -Id $PID).Path
  commandLine = $cmdLine
  startUtc = $startUtc
} | ConvertTo-Json | Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\06-k3-source-b-sdk-b-shorttemp\process-info.json' -Encoding UTF8

# ---- snapshot inherited environment ----
Get-ChildItem Env: | Sort-Object Name | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\06-k3-source-b-sdk-b-shorttemp\environment-inherited.txt' -Encoding UTF8

# ---- clear leftover experiment/VS state that must NOT be inherited ----
foreach ($v in @('FLUTTER_ROOT','DART_HOME','DART_SDK','FLUTTER_BIN','VSINSTALLDIR','VCINSTALLDIR','VCToolsInstallDir','VisualStudioVersion','MSBuildSDKsPath','MSBUILDDEBUGPATH','TRACKER_ADDPIDTOCMDLINE')) {
  Set-Item -Path "Env:\$v" -Value '' -ErrorAction SilentlyContinue
}
$env:PROGRAMDATA = 'C:\ProgramData'
$env:PUB_CACHE = 'C:\dev\muaman-13k-environment-b-independent-pub-cache-root'
$env:TEMP = 'C:\t\m13k-b'
$env:TMP = 'C:\t\m13k-b'
$env:HOME = 'C:\dev\muaman-13k-environment-b-independent-home-root'
$env:USERPROFILE = 'C:\dev\muaman-13k-environment-b-independent-home-root'
$env:APPDATA = Join-Path 'C:\dev\muaman-13k-environment-b-independent-home-root' 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path 'C:\dev\muaman-13k-environment-b-independent-home-root' 'appdata\local'
$env:NUGET_PACKAGES = Join-Path 'C:\dev\muaman-13k-environment-b-independent-home-root' 'appdata\local\NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:MSBUILDDISABLENODEREUSE = '1'
$env:PATH = (Join-Path 'C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk' 'bin') + ';' + $env:PATH

# ---- effective environment snapshot (what the wrapper will see) ----
Get-ChildItem Env: | Sort-Object Name | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value } |
  Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\06-k3-source-b-sdk-b-shorttemp\environment-effective.txt' -Encoding UTF8

# ---- invoke the committed hardened wrapper ----
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\dev\muaman-13k-environment-b-independent-source-extraction-root\tools\muaman13j\build_hardened.ps1' `
  -ExperimentId 'K3' -AppRoot 'C:\dev\muaman-13k-environment-b-independent-source-extraction-root\app' -SdkRoot 'C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk' -PubCache 'C:\dev\muaman-13k-environment-b-independent-pub-cache-root' `
  -TmpRoot 'C:\t\m13k-b' -HomeRoot 'C:\dev\muaman-13k-environment-b-independent-home-root' -EvidenceDir 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\06-k3-source-b-sdk-b-shorttemp' -MsBuildBinDir 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64'
$exitCode = $LASTEXITCODE
$endUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
[ordered]@{
  runId = 'K3'
  exitCode = $exitCode
  endUtc = $endUtc
} | ConvertTo-Json | Set-Content -LiteralPath 'C:\dev\muaman.worktrees\muaman-13j-eliminate-filetracker-empty-path-crash\docs\evidence\muaman-13k\06-k3-source-b-sdk-b-shorttemp\runner-exit.json' -Encoding UTF8
exit $exitCode
