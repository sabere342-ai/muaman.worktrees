<#
.SYNOPSIS
  MUAMAN-13B reproducibility orchestrator.

.DESCRIPTION
  Runs two fully independent clean Windows release builds from the same
  commit and proves or disproves release reproducibility:

    Run N: flutter clean -> flutter pub get -> flutter build windows --release
            -> snapshot Release/ into an isolated work area (OUTSIDE app/build,
               so a later `flutter clean` can never touch earlier snapshots)
            -> canonical manifest for that snapshot

  After both runs it builds deterministic ZIPs (twice per snapshot, to prove
  same-snapshot determinism), compares the two snapshots, and emits all
  reports under <work root> and copies them into
  <app>/build/artifacts/reproducibility/.

.NOTES
  Only tooling and evidence are produced. No application behavior is changed.
#>
[CmdletBinding()]
param(
    [string]$AppRoot = "",
    [string]$WorkRoot = "",
    [string]$Baseline = "804388e13c708adcc398f929d8b4174965f502c8",
    [int]$Runs = 2
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AppRoot)) {
    $AppRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $WorkRoot = Join-Path $env:TEMP 'opencode\muaman-13b-repro'
}

function Write-HostInfo {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[repro] $Message"
}

function Test-TrackedTreeClean {
    # True when no tracked file has been modified (unstaged or staged).
    # Untracked files (the repro tooling itself, which is not yet committed
    # during an experiment) are intentionally ignored: they are never part of
    # the release build and therefore cannot change its output.
    # git may print autocrlf warnings to stderr; those must not abort under
    # $ErrorActionPreference = 'Stop'.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & git -C $AppRoot diff --quiet 2>&1 | Out-Null
    $unstaged = $LASTEXITCODE
    & git -C $AppRoot diff --cached --quiet 2>&1 | Out-Null
    $staged = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return ($unstaged -eq 0 -and $staged -eq 0)
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$LogFile = ""
    )
    $line = "$FilePath $($Arguments -join ' ')"
    Write-HostInfo "Running: $line"
    if ($LogFile) {
        & $FilePath @Arguments 2>&1 |
            Tee-Object -FilePath $LogFile |
            ForEach-Object { Write-Host "  $_" }
    }
    else {
        & $FilePath @Arguments 2>&1 | ForEach-Object { Write-Host "  $_" }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $line"
    }
}

function Write-JsonNoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Value,
        [int]$Depth = 8
    )
    $json = $Value | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText(
        $Path,
        $json,
        (New-Object System.Text.UTF8Encoding($false)))
}

Write-HostInfo "===== MUAMAN-13B reproducibility orchestrator ====="

# --- Baseline identity and clean tree -------------------------------------
Write-HostInfo "Verifying baseline identity and clean tree..."
$head = (& git -C $AppRoot rev-parse HEAD).Trim()
if ($head -ne $Baseline) {
    throw "HEAD ($head) does not match baseline ($Baseline)"
}
if (-not (Test-TrackedTreeClean)) {
    throw "Tracked files are modified before starting."
}
$branch = (& git -C $AppRoot branch --show-current).Trim()
Write-HostInfo "HEAD=$head branch=$branch"

# --- Toolchain resolution ---------------------------------------------------
Write-HostInfo "Resolving toolchain..."
$flutterCmd = (Get-Command 'flutter.bat' -ErrorAction SilentlyContinue).Source
if (-not $flutterCmd) {
    $flutterCmd = (Get-Command 'flutter.cmd' -ErrorAction SilentlyContinue).Source
}
if (-not $flutterCmd) {
    $flutterCmd = (Get-Command 'flutter' -ErrorAction SilentlyContinue).Source
}
if (-not $flutterCmd) { throw 'flutter not found on PATH' }

$dartCmd = (Get-Command 'dart.bat' -ErrorAction SilentlyContinue).Source
if (-not $dartCmd) {
    $dartCmd = (Get-Command 'dart.cmd' -ErrorAction SilentlyContinue).Source
}
if (-not $dartCmd) {
    $dartCmd = (Get-Command 'dart' -ErrorAction SilentlyContinue).Source
}
if (-not $dartCmd) { throw 'dart not found on PATH' }

$cmakeCmd = (Get-Command 'cmake.exe' -ErrorAction SilentlyContinue).Source

$flutterVersionText = (& $flutterCmd --version 2>&1 | Out-String).Trim()
$dartVersionText = (& $dartCmd --version 2>&1 | Out-String).Trim()
$cmakeVersionText = ''
if ($cmakeCmd) { $cmakeVersionText = (& $cmakeCmd --version 2>&1 | Out-String).Trim() }

$flutterVersion = ''
if ($flutterVersionText -match 'Flutter\s+(\d+\.\d+\.\d+)') {
    $flutterVersion = $matches[1]
}
$dartVersion = ''
if ($dartVersionText -match '(\d+\.\d+\.\d+)') { $dartVersion = $matches[1] }
$cmakeVersion = ''
if ($cmakeVersionText -match 'cmake version\s+([\d\.]+)') {
    $cmakeVersion = $matches[1]
}

Write-HostInfo "Flutter=$flutterVersion Dart=$dartVersion CMake=$cmakeVersion"

# --- OS and Visual Studio info ---------------------------------------------
$osInfo = Get-CimInstance Win32_OperatingSystem
$vsName = ''
$vsVersion = ''
$vsPath = ''
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $vsName = (& $vswhere -latest -products '*' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property displayName).Trim()
    $vsVersion = (& $vswhere -latest -products '*' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property catalog_productDisplayVersion).Trim()
    $vsPath = (& $vswhere -latest -products '*' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath).Trim()
}

# --- pubspec.lock guard -----------------------------------------------------
$lockFile = Join-Path $AppRoot 'pubspec.lock'
if (-not (Test-Path -LiteralPath $lockFile)) {
    throw "pubspec.lock not found: $lockFile"
}
$lockHashBefore = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
Write-HostInfo "pubspec.lock SHA256 (before): $lockHashBefore"

# --- Work area --------------------------------------------------------------
Write-HostInfo "Preparing work area: $WorkRoot"
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null
$runsDir = Join-Path $WorkRoot 'runs'
if (Test-Path -LiteralPath $runsDir) {
    Get-ChildItem -LiteralPath $runsDir -Directory |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
}
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null

# --- Two independent builds --------------------------------------------------
Push-Location $AppRoot
try {
    for ($i = 1; $i -le $Runs; $i++) {
        Write-HostInfo "===== RUN $i / $Runs ====="
        $runDir = Join-Path $runsDir "run-$i"
        $snapshot = Join-Path $runDir 'snapshot'
        $logDir = Join-Path $runDir 'logs'
        New-Item -ItemType Directory -Force -Path $runDir, $logDir | Out-Null

        $cleanBefore = Test-TrackedTreeClean
        if (-not $cleanBefore) {
            throw "Tracked working tree dirty before build run $i"
        }
        $cleanBeforeStr = 'false'
        if ($cleanBefore) { $cleanBeforeStr = 'true' }

        Invoke-Native $flutterCmd @('clean') (Join-Path $logDir 'flutter-clean.log')
        Invoke-Native $flutterCmd @('pub', 'get') (Join-Path $logDir 'flutter-pub-get.log')

        $lockHashNow = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
        if ($lockHashNow -ne $lockHashBefore) {
            throw "pubspec.lock changed during run $i (was $lockHashBefore now $lockHashNow)"
        }
        Write-HostInfo "pubspec.lock unchanged after pub get ($lockHashNow)"

        Invoke-Native $flutterCmd @('build', 'windows', '--release') `
            (Join-Path $logDir 'flutter-build.log')

        $releaseDir = Join-Path $AppRoot 'build\windows\x64\runner\Release'
        if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'muaman_store.exe'))) {
            throw "Run ${i}: muaman_store.exe not found under $releaseDir"
        }

        if (Test-Path -LiteralPath $snapshot) {
            Remove-Item -LiteralPath $snapshot -Recurse -Force
        }
        Copy-Item -LiteralPath $releaseDir -Destination $snapshot -Recurse
        Write-HostInfo "Snapshot copied: $snapshot"

        $cleanAfter = Test-TrackedTreeClean
        $cleanAfterStr = 'false'
        if ($cleanAfter) { $cleanAfterStr = 'true' }
        $builtAt = [DateTime]::UtcNow.ToString('o')

        $outManifest = Join-Path $runDir "run-$i-manifest.json"
        & $dartCmd run tool/repro_manifest.dart `
            "--release-dir=$snapshot" `
            "--out=$outManifest" `
            "--run-id=run-$i" `
            "--baseline-commit=$Baseline" `
            "--branch=$branch" `
            "--platform=windows" `
            "--architecture=x64" `
            "--build-mode=release" `
            "--flutter-version=$flutterVersion" `
            "--dart-version=$dartVersion" `
            "--built-at=$builtAt" `
            "--clean-before=$cleanBeforeStr" `
            "--clean-after=$cleanAfterStr" `
            "--pubspec-lock-hash=$lockHashBefore"
        if ($LASTEXITCODE -ne 0) {
            throw "Manifest generation failed for run $i (exit $LASTEXITCODE)"
        }
        Write-HostInfo "Manifest written: $outManifest"
    }
}
finally {
    Pop-Location
}

# --- Deterministic ZIPs + comparison ----------------------------------------
$run1Dir = Join-Path $runsDir 'run-1'
$run2Dir = Join-Path $runsDir 'run-2'
$snap1 = Join-Path $run1Dir 'snapshot'
$snap2 = Join-Path $run2Dir 'snapshot'
$man1 = Join-Path $run1Dir 'run-1-manifest.json'
$man2 = Join-Path $run2Dir 'run-2-manifest.json'

Push-Location $AppRoot
try {
    Write-HostInfo "Building deterministic ZIPs (twice per snapshot)..."
    $zip1 = Join-Path $runsDir 'run-1-deterministic.zip'
    $zip2 = Join-Path $runsDir 'run-2-deterministic.zip'
    $zip1Rebuild = Join-Path $runsDir 'run-1-deterministic.rebuild.zip'
    $zip2Rebuild = Join-Path $runsDir 'run-2-deterministic.rebuild.zip'

    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap1", "--out=$zip1", "--canonical-manifest=$man1")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap2", "--out=$zip2", "--canonical-manifest=$man2")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap1", "--out=$zip1Rebuild", "--canonical-manifest=$man1")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap2", "--out=$zip2Rebuild", "--canonical-manifest=$man2")

    $zip1Hash = (Get-FileHash -LiteralPath $zip1 -Algorithm SHA256).Hash
    $zip2Hash = (Get-FileHash -LiteralPath $zip2 -Algorithm SHA256).Hash
    $zip1RHash = (Get-FileHash -LiteralPath $zip1Rebuild -Algorithm SHA256).Hash
    $zip2RHash = (Get-FileHash -LiteralPath $zip2Rebuild -Algorithm SHA256).Hash

    Write-HostInfo "run-1 zip sha256: $zip1Hash"
    Write-HostInfo "run-1 zip rebuild sha256: $zip1RHash"
    Write-HostInfo "run-2 zip sha256: $zip2Hash"
    Write-HostInfo "run-2 zip rebuild sha256: $zip2RHash"

    $zipComparison = [ordered]@{
        schema                      = 'muaman-repro-zip-comparison'
        run1ZipSha256               = $zip1Hash
        run2ZipSha256               = $zip2Hash
        run1ZipRebuildSha256        = $zip1RHash
        run2ZipRebuildSha256        = $zip2RHash
        run1ZipSizeBytes            = (Get-Item -LiteralPath $zip1).Length
        run2ZipSizeBytes            = (Get-Item -LiteralPath $zip2).Length
        sameSnapshotDeterministicRun1 = ($zip1Hash -eq $zip1RHash)
        sameSnapshotDeterministicRun2 = ($zip2Hash -eq $zip2RHash)
        crossBuildZipEqual          = ($zip1Hash -eq $zip2Hash)
        timestamp                   = [DateTime]::UtcNow.ToString('o')
    }
    Write-JsonNoBom -Path (Join-Path $runsDir 'zip-comparison.json') `
        -Value $zipComparison

    $comparisonOut = Join-Path $runsDir 'comparison.json'
    Invoke-Native $dartCmd @('run', 'tool/repro_compare.dart',
        "--run-1=$snap1", "--run-2=$snap2",
        "--manifest-1=$man1", "--manifest-2=$man2",
        "--out=$comparisonOut")
}
finally {
    Pop-Location
}

# --- environment.json --------------------------------------------------------
$environment = [ordered]@{
    schema          = 'muaman-repro-environment'
    baselineCommit  = $Baseline
    branch          = $branch
    timestamp       = [DateTime]::UtcNow.ToString('o')
    os              = [ordered]@{
        caption     = $osInfo.Caption
        version     = $osInfo.Version
        architecture = $osInfo.OSArchitecture
    }
    flutter         = [ordered]@{ version = $flutterVersion; fullText = $flutterVersionText }
    dart            = [ordered]@{ version = $dartVersion; fullText = $dartVersionText }
    cmake           = [ordered]@{ version = $cmakeVersion; fullText = $cmakeVersionText }
    visualStudio    = [ordered]@{ displayName = $vsName; version = $vsVersion; path = $vsPath }
    paths           = [ordered]@{
        flutter     = $flutterCmd
        dart        = $dartCmd
        cmake       = $cmakeCmd
        appRoot     = $AppRoot
        workRoot    = $WorkRoot
    }
    pubspecLockSha256 = $lockHashBefore
    commands        = @(
        'git -C <app> rev-parse HEAD',
        'flutter clean',
        'flutter pub get',
        'flutter build windows --release',
        'dart run tool/repro_manifest.dart --release-dir <snapshot> --out run-N-manifest.json [meta flags]',
        'dart run tool/repro_zip.dart --release-dir <snapshot> --out run-N-deterministic.zip --canonical-manifest run-N-manifest.json',
        'dart run tool/repro_compare.dart --run-1 <snap1> --run-2 <snap2> --manifest-1 <man1> --manifest-2 <man2> --out comparison.json'
    )
}
$envOut = Join-Path $runsDir 'environment.json'
Write-JsonNoBom -Path $envOut -Value $environment

# --- Copy artifacts ----------------------------------------------------------
$artifactsDir = Join-Path $AppRoot 'build\artifacts\reproducibility'
New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null
Copy-Item -LiteralPath $man1 -Destination $artifactsDir -Force
Copy-Item -LiteralPath $man2 -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'comparison.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath $zip1 -Destination (Join-Path $artifactsDir 'run-1-deterministic.zip') -Force
Copy-Item -LiteralPath $zip2 -Destination (Join-Path $artifactsDir 'run-2-deterministic.zip') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'zip-comparison.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath $envOut -Destination $artifactsDir -Force
Write-HostInfo "Artifacts copied to: $artifactsDir"

# --- Summary ------------------------------------------------------------------
Write-HostInfo '===== SUMMARY ====='
Write-HostInfo "Baseline: $Baseline"
Write-HostInfo "Branch: $branch"
Write-HostInfo "Flutter: $flutterVersion | Dart: $dartVersion | CMake: $cmakeVersion"
Write-HostInfo "run-1 zip sha256: $zip1Hash"
Write-HostInfo "run-2 zip sha256: $zip2Hash"
Write-HostInfo "same-snapshot determinism run-1: $($zip1Hash -eq $zip1RHash)"
Write-HostInfo "same-snapshot determinism run-2: $($zip2Hash -eq $zip2RHash)"
Write-HostInfo "cross-build zip equality: $($zip1Hash -eq $zip2Hash)"
