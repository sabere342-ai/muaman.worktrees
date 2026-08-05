# MUAMAN-13L canonical hardened Windows release entrypoint.
#
# This is the SINGLE documented command for producing a MUAMAN Windows Release.
# It is a THIN OPERATIONAL INTERFACE ONLY: it does not re-implement any of the
# hardened build logic. The source of truth for the actual build is the
# committed MUAMAN-13J hardened wrapper:
#
#   tools/muaman13j/build_hardened.ps1
#     -> fresh-process preflight  tools/muaman13j/check_filetracker_state.ps1
#     -> isolated runner          tools/muaman13i/run_experiment.ps1
#
# This entrypoint guarantees, before delegating to that source of truth:
#   1. repository root is resolved from the script location, NOT the current
#      working directory (works from repo root, sub-folders, and outside the
#      repository);
#   2. Flutter SDK / PUB_CACHE / MSBuild are discovered, not hard-coded;
#   3. the committed FileTracker preflight runs FIRST, in a fresh process,
#      before any `flutter pub get` or `flutter build` can happen;
#   4. if the preflight fails the entrypoint exits non-zero immediately
#      (fail-closed) and never invokes the build;
#   5. the build is delegated unchanged to the hardened source of truth.
#
# The wrapper itself re-runs the same committed preflight under the hardened
# environment before it starts the isolated pub-get/build, so the ordering and
# fail-closed property hold at BOTH layers.
#
# Exit codes:
#   0  success (Release produced at the canonical output path)
#   1  FileTracker preflight failed (environment state is unsafe; no build ran)
#   2  environment resolution failure (SDK / PUB_CACHE / MSBuild not usable)
#   3  build failed (clean/pub-get/build failed, or no Release produced)
#   4  unexpected error
#
# Usage:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     .\tools\release\build_windows_release.ps1
#
# Optional switches:
#   -SdkRoot <dir>        explicit Flutter SDK root (else FLUTTER_ROOT, else PATH)
#   -PubCache <dir>       explicit PUB_CACHE (else $env:PUB_CACHE, else default)
#   -MsBuildBinDir <dir>  explicit MSBuild Bin dir (else vswhere discovery)
#   -StageRoot <dir>      stage base for tmp/home/evidence (else under $env:TEMP)
#   -EvidenceDir <dir>    where structured evidence JSON/logs are written
#   -TmpRoot <dir>        explicit isolated TEMP root (else under StageRoot)
#   -HomeRoot <dir>       explicit isolated HOME root (else under StageRoot)
#   -ExperimentId <id>    run id (else generated from UTC timestamp)
#   -PreflightOnly        run the committed preflight and exit; no build

param(
  [string]$SdkRoot = '',
  [string]$PubCache = '',
  [string]$MsBuildBinDir = '',
  [string]$StageRoot = '',
  [string]$EvidenceDir = '',
  [string]$TmpRoot = '',
  [string]$HomeRoot = '',
  [string]$ExperimentId = '',
  [switch]$PreflightOnly
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ("[MUAMAN-13L] {0}" -f $message)
}

function Assert-Directory([string]$path, [string]$what) {
  if (-not (Test-Path -LiteralPath $path -PathType Container)) {
    throw ("{0} does not exist: {1}" -f $what, $path)
  }
}

function Resolve-PathOrEmpty([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return '' }
  return [System.IO.Path]::GetFullPath($p)
}

# ---------------------------------------------------------------------------
# 1. repository root (from script location, never from the current directory)
# ---------------------------------------------------------------------------
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$toolsDir = Split-Path -Parent $scriptDir
$repoRoot = Split-Path -Parent $toolsDir
$appRoot = Join-Path $repoRoot 'app'

foreach ($marker in @(
  (Join-Path $appRoot 'pubspec.yaml'),
  (Join-Path $repoRoot 'tools\muaman13j\build_hardened.ps1'),
  (Join-Path $repoRoot 'tools\muaman13j\check_filetracker_state.ps1')
)) {
  if (-not (Test-Path -LiteralPath $marker)) {
    Write-Host ("[MUAMAN-13L] ERROR repository structure not found at {0}; missing {1}" -f $repoRoot, $marker)
    exit 2
  }
}

# ---------------------------------------------------------------------------
# 2. run identity and stage roots
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($ExperimentId)) {
  $ExperimentId = 'L-{0:yyyyMMdd-HHmmss}-{1}' -f [DateTime]::UtcNow, $PID
}

if ([string]::IsNullOrWhiteSpace($StageRoot)) {
  $StageRoot = Join-Path $env:TEMP ('muaman-release-' + $ExperimentId)
}
$StageRoot = [System.IO.Path]::GetFullPath($StageRoot)

if ([string]::IsNullOrWhiteSpace($EvidenceDir)) {
  $EvidenceDir = Join-Path $StageRoot 'evidence'
}
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)

if ([string]::IsNullOrWhiteSpace($TmpRoot)) {
  $TmpRoot = Join-Path $StageRoot 'tmp'
}
if ([string]::IsNullOrWhiteSpace($HomeRoot)) {
  $HomeRoot = Join-Path $StageRoot 'home'
}
$TmpRoot = [System.IO.Path]::GetFullPath($TmpRoot)
$HomeRoot = [System.IO.Path]::GetFullPath($HomeRoot)

# The stage roots are owned by this entrypoint; create them up front so the
# preflight and the hardened wrapper always write to existing locations.
New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null
New-Item -ItemType Directory -Path $HomeRoot -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

$startUtc = [DateTime]::UtcNow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Step ("canonical Windows release build, run id {0}" -f $ExperimentId)
Write-Step ("repository root : {0}" -f $repoRoot)
Write-Step ("app root        : {0}" -f $appRoot)

# ---------------------------------------------------------------------------
# 3. Flutter SDK discovery (no hard-coded drive letters or user names)
# ---------------------------------------------------------------------------
$sdkRootResolved = ''
if (-not [string]::IsNullOrWhiteSpace($SdkRoot)) {
  $sdkRootResolved = [System.IO.Path]::GetFullPath($SdkRoot)
} elseif (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) {
  $sdkRootResolved = $env:FLUTTER_ROOT
} else {
  $flutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if ($null -ne $flutterCmd -and -not [string]::IsNullOrEmpty($flutterCmd.Source)) {
    # Source is <sdk>\bin\flutter.bat -> parent -> sdk root
    $sdkRootResolved = Split-Path -Parent (Split-Path -Parent $flutterCmd.Source)
  }
}
if ([string]::IsNullOrWhiteSpace($sdkRootResolved)) {
  Write-Host '[MUAMAN-13L] ERROR could not locate the Flutter SDK (try -SdkRoot or set FLUTTER_ROOT/PATH)'
  exit 2
}
$sdkRootResolved = [System.IO.Path]::GetFullPath($sdkRootResolved)
$sdkFlutterBat = Join-Path $sdkRootResolved 'bin\flutter.bat'
if (-not (Test-Path -LiteralPath $sdkFlutterBat)) {
  Write-Host ("[MUAMAN-13L] ERROR Flutter SDK has no bin\flutter.bat: {0}" -f $sdkRootResolved)
  exit 2
}

# ---------------------------------------------------------------------------
# 4. PUB_CACHE discovery
# ---------------------------------------------------------------------------
$pubCacheResolved = ''
if (-not [string]::IsNullOrWhiteSpace($PubCache)) {
  $pubCacheResolved = [System.IO.Path]::GetFullPath($PubCache)
} elseif (-not [string]::IsNullOrWhiteSpace($env:PUB_CACHE)) {
  $pubCacheResolved = $env:PUB_CACHE
} else {
  $pubCacheResolved = Join-Path $env:LOCALAPPDATA 'Pub\Cache'
}
$pubCacheResolved = [System.IO.Path]::GetFullPath($pubCacheResolved)
New-Item -ItemType Directory -Path $pubCacheResolved -Force | Out-Null

# ---------------------------------------------------------------------------
# 5. MSBuild Bin directory discovery (vswhere; no hard-coded install path)
# ---------------------------------------------------------------------------
$msBuildBinDirResolved = ''
if (-not [string]::IsNullOrWhiteSpace($MsBuildBinDir)) {
  $msBuildBinDirResolved = [System.IO.Path]::GetFullPath($MsBuildBinDir)
} else {
  $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', 'Process')
  if ([string]::IsNullOrEmpty($pf86)) { $pf86 = $env:ProgramFiles }
  $vswhere = Join-Path $pf86 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path -LiteralPath $vswhere) {
    $candidates = @(& $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\amd64\MSBuild.exe' 2>$null)
    if ($candidates.Count -eq 0) {
      $candidates = @(& $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' 2>$null)
    }
    foreach ($c in $candidates) {
      if ([string]::IsNullOrWhiteSpace($c)) { continue }
      $dir = Split-Path -Parent ([System.IO.Path]::GetFullPath($c.Trim()))
      if (Test-Path -LiteralPath (Join-Path $dir 'Microsoft.Build.Utilities.Core.dll')) {
        $msBuildBinDirResolved = $dir
        break
      }
    }
  }
}
if ([string]::IsNullOrWhiteSpace($msBuildBinDirResolved)) {
  Write-Host '[MUAMAN-13L] ERROR could not locate an MSBuild Bin directory (try -MsBuildBinDir)'
  exit 2
}
$msBuildBinDirResolved = [System.IO.Path]::GetFullPath($msBuildBinDirResolved)
$utilDll = Join-Path $msBuildBinDirResolved 'Microsoft.Build.Utilities.Core.dll'
if (-not (Test-Path -LiteralPath $utilDll)) {
  Write-Host ("[MUAMAN-13L] ERROR Microsoft.Build.Utilities.Core.dll not found under: {0}" -f $msBuildBinDirResolved)
  exit 2
}

# ---------------------------------------------------------------------------
# 6. committed source-of-truth paths (delegation targets)
# ---------------------------------------------------------------------------
$preflightScript = Join-Path $repoRoot 'tools\muaman13j\check_filetracker_state.ps1'
$wrapperScript = Join-Path $repoRoot 'tools\muaman13j\build_hardened.ps1'
foreach ($p in @($preflightScript, $wrapperScript)) {
  if (-not (Test-Path -LiteralPath $p)) {
    Write-Host ("[MUAMAN-13L] ERROR committed hardened tool missing: {0}" -f $p)
    exit 2
  }
}

# ---------------------------------------------------------------------------
# 7. PREFLIGHT (first gate; before any pub get / build)
# ---------------------------------------------------------------------------
$preflightLog = Join-Path $EvidenceDir '00-entrypoint-preflight.log'
Write-Step ("preflight        : running committed preflight (fresh process)...")
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflightScript -MsBuildBinDir $msBuildBinDirResolved *> $preflightLog
$preflightExit = $LASTEXITCODE

$preflightOk = ($preflightExit -eq 0)
[ordered]@{
  runId = $ExperimentId
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  stage = 'entrypoint-first-gate'
  preflightScript = $preflightScript
  msBuildBinDir = $msBuildBinDirResolved
  log = $preflightLog
  exitCode = $preflightExit
  status = if ($preflightOk) { 'PASS' } else { 'FAIL' }
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDir 'preflight-result.json') -Encoding UTF8

if (-not $preflightOk) {
  Write-Host ("[MUAMAN-13L] PREFLIGHT FAILED (exit {0}): FileTracker state unsafe; build REFUSED. See {1}" -f $preflightExit, $preflightLog)
  Write-Host '[MUAMAN-13L] No flutter pub get / flutter build was started.'
  exit 1
}
Write-Step ("preflight        : PASS (exit {0})" -f $preflightExit)

if ($PreflightOnly) {
  Write-Step 'PreflightOnly   : yes; build not started.'
  Write-Step ("preflight status: PASS")
  exit 0
}

# ---------------------------------------------------------------------------
# 8. BUILD (delegated to the hardened source of truth)
# ---------------------------------------------------------------------------
Write-Step 'build           : delegating to tools/muaman13j/build_hardened.ps1 (source of truth)'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wrapperScript `
  -ExperimentId $ExperimentId -AppRoot $appRoot -SdkRoot $sdkRootResolved -PubCache $pubCacheResolved `
  -TmpRoot $TmpRoot -HomeRoot $HomeRoot -EvidenceDir $EvidenceDir -MsBuildBinDir $msBuildBinDirResolved
$buildExit = $LASTEXITCODE
$sw.Stop()
$elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
$endUtc = [DateTime]::UtcNow

# ---------------------------------------------------------------------------
# 9. result capture
# ---------------------------------------------------------------------------
$releaseDir = Join-Path $appRoot 'build\windows\x64\runner\Release'
$releaseExists = Test-Path -LiteralPath (Join-Path $releaseDir 'muaman_store.exe')
$buildOk = ($buildExit -eq 0 -and $releaseExists)

$buildResult = [ordered]@{
  runId = $ExperimentId
  capturedAtUtc = $endUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  endedAtUtc = $endUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  durationSeconds = $elapsedSec
  repositoryRoot = $repoRoot
  appRoot = $appRoot
  sdkRoot = $sdkRootResolved
  pubCache = $pubCacheResolved
  msBuildBinDir = $msBuildBinDirResolved
  stageRoot = $StageRoot
  evidenceDir = $EvidenceDir
  preflightExitCode = $preflightExit
  buildExitCode = $buildExit
  releaseDir = $releaseDir
  releaseExists = $releaseExists
  status = if ($buildOk) { 'PASS' } else { 'FAIL' }
}
$buildResult | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EvidenceDir 'build-result.json') -Encoding UTF8
$releaseDir | Set-Content -LiteralPath (Join-Path $EvidenceDir 'release-dir.txt') -Encoding UTF8
("exit code: {0}" -f $buildExit) | Set-Content -LiteralPath (Join-Path $EvidenceDir 'exit-code.txt') -Encoding UTF8

if (-not $buildOk) {
  Write-Host ("[MUAMAN-13L] BUILD FAILED (exit {0}, release exists {1}); see evidence at {2}" -f $buildExit, $releaseExists, $EvidenceDir)
  exit 3
}

# ---------------------------------------------------------------------------
# 10. canonical release manifest (committed legal generator, no new logic)
# ---------------------------------------------------------------------------
$manifestScript = Join-Path $repoRoot 'tools\muaman13k\make_release_manifest.ps1'
$manifestOut = Join-Path $EvidenceDir 'release-manifest.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $manifestScript `
  -ReleaseDir $releaseDir -Out $manifestOut -RunId $ExperimentId
$manifestExit = $LASTEXITCODE
if ($manifestExit -ne 0 -or -not (Test-Path -LiteralPath $manifestOut)) {
  Write-Host "[MUAMAN-13L] WARNING release manifest generation failed (the build itself succeeded)."
}

Write-Step ("build status     : {0} (exit {1})" -f $(if ($buildOk) { 'PASS' } else { 'FAIL' }), $buildExit)
Write-Step ("release output   : {0}" -f $releaseDir)
Write-Step ("evidence dir     : {0}" -f $EvidenceDir)
Write-Step ("duration         : {0}s" -f $elapsedSec)
Write-Step ("RESULT: PASS")
exit 0
