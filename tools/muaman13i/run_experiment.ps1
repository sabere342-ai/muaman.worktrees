# MUAMAN-13I experiment runner.
# Runs a single isolated `flutter build windows --release -v` in an isolated
# environment (SDK / PUB_CACHE / TEMP / TMP / HOME / USERPROFILE) while a
# response-file watcher captures any MSBuild *.rsp file into the evidence
# directory. Records pre/post state and structured analysis.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File run_experiment.ps1 ^
#       -ExperimentId E0 -AppRoot <app> -SdkRoot <sdk> -PubCache <pub> ^
#       -TmpRoot <tmp> -HomeRoot <home> -EvidenceDir <dir> [-SkipPubGet]
#
# Every output is written under <EvidenceDir>. Exit code mirrors the build
# exit code.

param(
  [Parameter(Mandatory=$true)][string]$ExperimentId,
  [Parameter(Mandatory=$true)][string]$AppRoot,
  [Parameter(Mandatory=$true)][string]$SdkRoot,
  [Parameter(Mandatory=$true)][string]$PubCache,
  [Parameter(Mandatory=$true)][string]$TmpRoot,
  [Parameter(Mandatory=$true)][string]$HomeRoot,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [switch]$SkipPubGet
)
$ErrorActionPreference = 'Stop'

# Resolve the evidence dir to an absolute path up front: the script
# Push-Location's into the app root, so any relative log paths would
# otherwise be resolved against the app root (and leak there).
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)

# Ensure the isolated temp root exists BEFORE any flutter/dart process starts;
# a missing TEMP directory makes dart.exe fail with 'cannot find the path'.
# The temp root is emptied and recreated again right before the build.
New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null

$env:PUB_CACHE = $PubCache
$env:TEMP = $TmpRoot
$env:TMP = $TmpRoot
$env:HOME = $HomeRoot
$env:USERPROFILE = $HomeRoot
$env:APPDATA = Join-Path $HomeRoot 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path $HomeRoot 'appdata\local'
$env:NUGET_PACKAGES = Join-Path $HomeRoot 'appdata\local\NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:FLUTTER_ROOT = ''
$env:DART_HOME = ''
$env:FLUTTER_BIN = ''
$env:PATH = (Join-Path $SdkRoot 'bin') + ';' + $env:PATH

New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
$relFile = 'packages\flutter_tools\lib\src\windows\visual_studio.dart'
$snapshot = 'bin\cache\flutter_tools.snapshot'
$buildLog = Join-Path $EvidenceDir '03-build.log'
$cleanLog = Join-Path $EvidenceDir '01-clean.log'
$pubGetLog = Join-Path $EvidenceDir '02-pubget.log'
$preJson = Join-Path $EvidenceDir '00-pre.json'
$analysisJson = Join-Path $EvidenceDir '05-analysis.json'
$stopFile = Join-Path $EvidenceDir 'watcher.stop'
$watcherOut = Join-Path $EvidenceDir '06-watcher-stderr.log'
$rspDir = Join-Path $EvidenceDir 'rsp-capture'

function Sha256([string]$p) {
  if (Test-Path -LiteralPath $p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { 'ABSENT' }
}
function Canon([string]$p) { [System.IO.Path]::GetFullPath($p) }

# ---------- pre state ----------
$pre = [ordered]@{
  experimentId    = $ExperimentId
  capturedAtUtc   = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  appRoot         = Canon $AppRoot
  appRootLen      = (Canon $AppRoot).Length
  sdkRoot         = Canon $SdkRoot
  sdkRootLen      = (Canon $SdkRoot).Length
  pubCache        = Canon $PubCache
  pubCacheLen     = (Canon $PubCache).Length
  tmpRoot         = Canon $TmpRoot
  tmpRootLen      = (Canon $TmpRoot).Length
  homeRoot        = Canon $HomeRoot
  homeRootLen     = (Canon $HomeRoot).Length
  temp            = $env:TEMP
  tmp             = $env:TMP
  tempLen         = $env:TEMP.Length
  tmpLen          = $env:TMP.Length
  patchedVsDart   = Sha256 (Join-Path $SdkRoot $relFile)
  flutterSnapshot = Sha256 (Join-Path $SdkRoot $snapshot)
  pubspecLock     = Sha256 (Join-Path $AppRoot 'pubspec.lock')
  ci              = $env:CI
  flutterSuppress  = $env:FLUTTER_SUPPRESS_ANALYTICS
  path0           = (($env:PATH -split ';')[0])
}
$pre | ConvertTo-Json | Set-Content -LiteralPath $preJson -Encoding UTF8

# ---------- clean ----------
Push-Location $AppRoot
try {
  & cmd /c "`"$(Join-Path $SdkRoot 'bin\flutter.bat')`" clean > `"$cleanLog`" 2>&1"
  $cleanExit = $LASTEXITCODE

  if (-not $SkipPubGet) {
    & cmd /c "`"$(Join-Path $SdkRoot 'bin\flutter.bat')`" pub get -v > `"$pubGetLog`" 2>&1"
    $pubGetExit = $LASTEXITCODE
  } else {
    $pubGetExit = -1
  }

  # Empty and recreate the isolated temp root.
  if (Test-Path -LiteralPath $TmpRoot) {
    Remove-Item -LiteralPath $TmpRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null

  # ---------- watcher ----------
  if (Test-Path -LiteralPath $stopFile) { Remove-Item -LiteralPath $stopFile -Force }
  $watcherArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    (Join-Path $PSScriptRoot 'rsp_watcher.ps1'),
    '-WatchRoots', $TmpRoot,
    '-EvidenceRoot', $rspDir,
    '-StopFile', $stopFile
  )
  $watcher = Start-Process -FilePath 'powershell.exe' -ArgumentList $watcherArgs `
    -PassThru -WindowStyle Hidden -RedirectStandardError $watcherOut
  $startedFile = Join-Path $rspDir 'watcher.started'
  for ($i = 0; $i -lt 200; $i++) {
    if (Test-Path -LiteralPath $startedFile) { break }
    Start-Sleep -Milliseconds 50
  }

  # ---------- build ----------
  $startUtc = [DateTime]::UtcNow
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  & cmd /c "`"$(Join-Path $SdkRoot 'bin\flutter.bat')`" build windows --release -v > `"$buildLog`" 2>&1"
  $buildExit = $LASTEXITCODE
  $sw.Stop()
  $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
  $endUtc = [DateTime]::UtcNow

  # ---------- stop watcher ----------
  Set-Content -LiteralPath $stopFile -Value 'stop' -Encoding UTF8
  if ($watcher -and -not $watcher.HasExited) {
    $watcher.WaitForExit(5000) | Out-Null
    if (-not $watcher.HasExited) { $watcher.Kill() }
  }
} finally {
  Pop-Location
}

# ---------- analysis ----------
$releaseDir = Join-Path $AppRoot 'build\windows\x64\runner\Release'
$buildTree = Join-Path $AppRoot 'build\windows\x64'
$rspObserved = $false
$fileTrackerCrash = $false
$crashDetail = ''

$rawLog = ''
if (Test-Path -LiteralPath $buildLog) { $rawLog = Get-Content -LiteralPath $buildLog -Raw -ErrorAction SilentlyContinue }

if ($rawLog -match 'MSB4018|FileIsUnderNormalizedPath|CL.{0,3}task failed unexpectedly') {
  $fileTrackerCrash = $true
  if ($rawLog -match 'error MSB4018: The "CL" task failed unexpectedly') {
    $crashDetail = 'MSB4018 CL task failed unexpectedly'
  }
}
if ($rawLog -match 'FileIsUnderNormalizedPath') {
  $fileTrackerCrash = $true
  if (-not $crashDetail) { $crashDetail = 'FileTracker.FileIsUnderNormalizedPath' }
}

# Search all CompilerIdCXX tlog files for the actual invocation command.
$clCommands = @()
$tlogDir = Join-Path $buildTree 'CMakeFiles\4.2.3-msvc3\CompilerIdCXX'
if (Test-Path -LiteralPath $tlogDir) {
  Get-ChildItem -LiteralPath $tlogDir -Recurse -Filter 'CL.*.tlog' -File -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-Content -LiteralPath $_.FullName -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '^#Command:' } |
        ForEach-Object { $clCommands += $_ }
    }
}
foreach ($c in $clCommands) { if ($c -match '@') { $rspObserved = $true } }
if ($rawLog -match 'CL\.exe\s+@') { $rspObserved = $true }

$configureLog = Join-Path $buildTree 'CMakeFiles\CMakeConfigureLog.yaml'
$compilerIdSuccess = $false
$configureSuccess = Test-Path -LiteralPath (Join-Path $buildTree 'CMakeCache.txt')
if (Test-Path -LiteralPath $configureLog) {
  $cfg = Get-Content -LiteralPath $configureLog -Raw -ErrorAction SilentlyContinue
  if ($cfg -match 'Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed') {
    $compilerIdSuccess = $false
  }
  if ($cfg -match 'Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp"\.\.\.\s*$') {
    $compilerIdSuccess = $true
  }
}
# compiler ID binary present => identification compiled
if (Test-Path -LiteralPath (Join-Path $tlogDir 'Debug\CMakeCXXCompilerId.obj')) { $compilerIdSuccess = $true }
if (Test-Path -LiteralPath (Join-Path $tlogDir 'Debug\CMakeCXXCompilerId.exe')) { $compilerIdSuccess = $true }

$releaseSuccess = Test-Path -LiteralPath $releaseDir

$rspCaptures = @()
$meta = Join-Path $rspDir 'capture.jsonl'
if (Test-Path -LiteralPath $meta) {
  $rspCaptures = @(Get-Content -LiteralPath $meta | ForEach-Object { $_ | ConvertFrom-Json })
}

$analysis = [ordered]@{
  experimentId          = $ExperimentId
  capturedAtUtc         = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  startedAtUtc          = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  endedAtUtc            = $endUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  elapsedSeconds        = $elapsedSec
  cleanExitCode         = $cleanExit
  pubGetExitCode        = $pubGetExit
  buildExitCode         = $buildExit
  responseFileObserved  = $rspObserved
  fileTrackerCrash      = $fileTrackerCrash
  crashDetail           = $crashDetail
  compilerIdSuccess     = $compilerIdSuccess
  configureSuccess      = $configureSuccess
  releaseBuildSuccess   = $releaseSuccess
  clCommands            = $clCommands
  rspCaptures           = @($rspCaptures | ForEach-Object { [ordered]@{ path=$_.originalPath; pathLen=$_.originalPathLen; lengthBytes=$_.lengthBytes; sha256=$_.sha256; bom=$_.bom; encoding=$_.encodingGuess } })
  rspCaptureCount       = $rspCaptures.Count
  buildLogBytes         = if (Test-Path -LiteralPath $buildLog) { (Get-Item -LiteralPath $buildLog).Length } else { 0 }
  releaseDir            = if ($releaseSuccess) { (Get-ChildItem -LiteralPath $releaseDir -Recurse -File | Measure-Object).Count } else { 0 }
}
$analysis | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $analysisJson -Encoding UTF8

Write-Output ("MUAMAN-13I {0}: exit={1} rsp={2} fileTrackerCrash={3} compilerId={4} configure={5} release={6} elapsed={7}s" -f `
  $ExperimentId, $buildExit, $rspObserved, $fileTrackerCrash, $compilerIdSuccess, $configureSuccess, $releaseSuccess, $elapsedSec)
exit $buildExit
