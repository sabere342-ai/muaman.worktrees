<#
.SYNOPSIS
  MUAMAN-13C reproducibility orchestrator: prove full Windows byte determinism.

.DESCRIPTION
  Runs two fully independent clean Windows release builds from the same
  commit with the `/Brepro` linker option enabled and proves that the two
  builds are byte-for-byte identical, including the previously
  non-deterministic PE files (muaman_store.exe and printing_plugin.dll).

  Per run:
    flutter clean -> flutter pub get -> flutter build windows --release
      -> snapshot runner/Release/ into an isolated work area (OUTSIDE app/build,
         so a later `flutter clean` can never touch earlier snapshots)
      -> canonical manifest + PE inspection of the snapshot
      -> evidence relink: delete the two PE outputs, relink them via MSBuild
         with /v:diag, capture the REAL link.exe command lines, prove the
         relinked binaries are byte-identical to the snapshot (deterministic
         relink), and emit linker evidence JSON.

  After both runs it builds deterministic ZIPs (twice per snapshot, to prove
  same-snapshot determinism), compares the two snapshots (byte level, manifest
  level, PE level, ZIP level) and emits all reports under <work root>, then
  mirrors the committed evidence into <app>/docs/muaman-13c/evidence/.

.NOTES
  Only tooling and evidence are produced. No application behavior is changed.
#>
[CmdletBinding()]
param(
    [string]$AppRoot = "",
    [string]$WorkRoot = "",
    [string]$Baseline = "8acccfdf3181a5bb326cdb827cfe5f6c11b71352",
    [int]$Runs = 2
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AppRoot)) {
    $AppRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $WorkRoot = Join-Path $env:TEMP 'opencode\muaman-13c-repro'
}

function Write-HostInfo {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[repro] $Message"
}

function Test-TrackedTreeClean {
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

function Invoke-MsBuildDiag {
    param(
        [Parameter(Mandatory = $true)][string]$Project,
        [Parameter(Mandatory = $true)][string]$LogFile
    )
    & $script:MsBuild $Project /p:Configuration=Release /t:Build `
        /v:diag /nologo /p:BuildProjectReferences=false 2>&1 |
        Out-File -FilePath $LogFile -Encoding utf8
    if ($LASTEXITCODE -ne 0) {
        throw "MSBuild diag build failed (exit $LASTEXITCODE): $Project"
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

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

Write-HostInfo '===== MUAMAN-13C reproducibility orchestrator ====='

# --- Baseline identity and working-state snapshot ---------------------------
Write-HostInfo "Verifying baseline identity..."
$head = (& git -C $AppRoot rev-parse HEAD).Trim()
if ($head -ne $Baseline) {
    throw "HEAD ($head) does not match baseline ($Baseline)"
}
$branch = (& git -C $AppRoot branch --show-current).Trim()
# The 13C change to windows/CMakeLists.txt is intentionally uncommitted during
# the experiment (we commit once at the very end). We therefore do not require
# a clean tree; instead we record the working state and assert it does not
# change during any build (builds must never modify tracked files).
$statusBefore = ((& git -C $AppRoot status --porcelain) -join "`n").TrimEnd()
Write-HostInfo "HEAD=$head branch=$branch"

# --- Toolchain resolution ---------------------------------------------------
Write-HostInfo "Resolving toolchain..."
$flutterCmd = (Get-Command 'flutter.bat' -ErrorAction SilentlyContinue).Source
if (-not $flutterCmd) {
    $flutterCmd = (Get-Command 'flutter.cmd' -ErrorAction SilentlyContinue).Source
}
if (-not $flutterCmd) { throw 'flutter not found on PATH' }

$dartCmd = (Get-Command 'dart.bat' -ErrorAction SilentlyContinue).Source
if (-not $dartCmd) {
    $dartCmd = (Get-Command 'dart.cmd' -ErrorAction SilentlyContinue).Source
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

# --- Visual Studio / MSVC / MSBuild resolution ------------------------------
$osInfo = Get-CimInstance Win32_OperatingSystem
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsName = ''
$vsVersion = ''
$vsPath = ''
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
if (-not $vsPath) { throw 'Visual Studio Build Tools (VC) not found via vswhere' }

$msvcRoot = Join-Path $vsPath 'VC\Tools\MSVC'
$msvcDirs = Get-ChildItem -LiteralPath $msvcRoot -Directory | Sort-Object Name
if (-not $msvcDirs) { throw "No MSVC toolset found under $msvcRoot" }
$script:LinkExe = Join-Path $msvcDirs[-1].FullName 'bin\Hostx64\x64\link.exe'
if (-not (Test-Path -LiteralPath $script:LinkExe)) {
    throw "link.exe not found: $script:LinkExe"
}
$linkVersion = (Get-Item -LiteralPath $script:LinkExe).VersionInfo.FileVersion

$script:MsBuild = Join-Path $vsPath 'MSBuild\Current\Bin\amd64\MSBuild.exe'
if (-not (Test-Path -LiteralPath $script:MsBuild)) {
    throw "MSBuild.exe not found: $script:MsBuild"
}
Write-HostInfo "MSVC link.exe=$script:LinkExe (version $linkVersion)"
Write-HostInfo "MSBuild=$script:MsBuild"

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

# --- Per-run builds, snapshots and linker evidence ---------------------------
Push-Location $AppRoot
try {
    for ($i = 1; $i -le $Runs; $i++) {
        Write-HostInfo "===== RUN $i / $Runs ====="
        $runDir = Join-Path $runsDir "run-$i"
        $snapshot = Join-Path $runDir 'snapshot'
        $logDir = Join-Path $runDir 'logs'
        New-Item -ItemType Directory -Force -Path $runDir, $logDir | Out-Null

        $cleanBeforeStr = 'false'
        if (($statusBefore -eq '') -and (Test-TrackedTreeClean)) { $cleanBeforeStr = 'true' }

        Invoke-Native $flutterCmd @('clean') (Join-Path $logDir 'flutter-clean.log')
        Invoke-Native $flutterCmd @('pub', 'get') (Join-Path $logDir 'flutter-pub-get.log')

        $lockHashNow = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
        if ($lockHashNow -ne $lockHashBefore) {
            throw "pubspec.lock changed during run $i"
        }

        Invoke-Native $flutterCmd @('build', 'windows', '--release') `
            (Join-Path $logDir 'flutter-build.log')

        $releaseDir = Join-Path $AppRoot 'build\windows\x64\runner\Release'
        $exePath = Join-Path $releaseDir 'muaman_store.exe'
        if (-not (Test-Path -LiteralPath $exePath)) {
            throw "Run ${i}: muaman_store.exe not found under $releaseDir"
        }
        $pluginDllPath = Join-Path $AppRoot 'build\windows\x64\plugins\printing\Release\printing_plugin.dll'
        if (-not (Test-Path -LiteralPath $pluginDllPath)) {
            throw "Run ${i}: printing_plugin.dll not found (was the plugin built?)"
        }

        # Snapshot BEFORE any relink so it reflects the pristine flutter build.
        if (Test-Path -LiteralPath $snapshot) {
            Remove-Item -LiteralPath $snapshot -Recurse -Force
        }
        Copy-Item -LiteralPath $releaseDir -Destination $snapshot -Recurse

        # The build must never modify tracked files or add unexpected
        # untracked files outside build/. Assert the working state is exactly
        # what it was before the run started.
        $statusNow = ((& git -C $AppRoot status --porcelain) -join "`n").TrimEnd()
        if ($statusNow -ne $statusBefore) {
            throw "Working tree changed during build run $i.`nBefore:`n$statusBefore`nAfter:`n$statusNow"
        }
        $cleanAfterStr = 'false'
        if (($statusBefore -eq '') -and (Test-TrackedTreeClean)) { $cleanAfterStr = 'true' }
        $builtAt = [DateTime]::UtcNow.ToString('o')

        # Canonical manifest from the snapshot.
        $outManifest = Join-Path $runDir "run-$i-manifest.json"
        Invoke-Native $dartCmd @('run', 'tool/repro_manifest.dart',
            "--release-dir=$snapshot", "--out=$outManifest", "--run-id=run-$i",
            "--baseline-commit=$Baseline", "--branch=$branch",
            "--platform=windows", "--architecture=x64", "--build-mode=release",
            "--flutter-version=$flutterVersion", "--dart-version=$dartVersion",
            "--built-at=$builtAt", "--clean-before=$cleanBeforeStr",
            "--clean-after=$cleanAfterStr", "--pubspec-lock-hash=$lockHashBefore")
        if ($LASTEXITCODE -ne 0) { throw "Manifest generation failed for run $i" }

        # PE inspection of the snapshot's PE files.
        $peOut = Join-Path $runDir 'pe-inspection.json'
        Invoke-Native $dartCmd @('run', 'tool/pe_inspect.dart',
            "--run-id=run-$i", "--out=$peOut",
            "--file=$exePath",
            "--file=$(Join-Path $releaseDir 'printing_plugin.dll')",
            "--file=$(Join-Path $releaseDir 'flutter_windows.dll')",
            "--file=$(Join-Path $releaseDir 'pdfium.dll')")
        if ($LASTEXITCODE -ne 0) { throw "PE inspection failed for run $i" }

        # Evidence relink: force a fresh link of the two previously
        # non-deterministic PEs and capture the REAL link.exe command line.
        Write-HostInfo "Evidence relink (exe)..."
        Remove-Item -LiteralPath $exePath -Force
        $diagExeLog = Join-Path $logDir 'diag-link-exe.log'
        Invoke-MsBuildDiag -Project (Join-Path $AppRoot 'build\windows\x64\runner\muaman_store.vcxproj') -LogFile $diagExeLog

        Write-HostInfo "Evidence relink (dll)..."
        Remove-Item -LiteralPath $pluginDllPath -Force
        $diagDllLog = Join-Path $logDir 'diag-link-dll.log'
        Invoke-MsBuildDiag -Project (Join-Path $AppRoot 'build\windows\x64\plugins\printing\printing_plugin.vcxproj') -LogFile $diagDllLog

        # Relink determinism: relinked binaries must be byte-identical to the
        # snapshot taken from the pristine flutter build.
        $snapExeHash = Get-Sha256 (Join-Path $snapshot 'muaman_store.exe')
        $relinkExeHash = Get-Sha256 $exePath
        $snapDllHash = Get-Sha256 (Join-Path $snapshot 'printing_plugin.dll')
        $relinkDllHash = Get-Sha256 $pluginDllPath
        Write-HostInfo "exe  snapshot=$snapExeHash relink=$relinkExeHash"
        Write-HostInfo "dll  snapshot=$snapDllHash relink=$relinkDllHash"
        if ($snapExeHash -ne $relinkExeHash) {
            throw "Run ${i}: relinked EXE differs from snapshot (non-deterministic relink)"
        }
        if ($snapDllHash -ne $relinkDllHash) {
            throw "Run ${i}: relinked DLL differs from snapshot (non-deterministic relink)"
        }
        Write-HostInfo "Relink determinism verified for exe + dll (run $i)."

        # Linker evidence from the generated vcxproj files + real link commands.
        $leOut = Join-Path $runDir 'linker-evidence.json'
        Invoke-Native $dartCmd @('run', 'tool/linker_evidence.dart',
            "--run-id=run-$i", "--linker-path=$script:LinkExe",
            "--linker-version=$linkVersion",
            "--vcxproj=$(Join-Path $AppRoot 'build\windows\x64\runner\muaman_store.vcxproj')",
            "--vcxproj=$(Join-Path $AppRoot 'build\windows\x64\plugins\printing\printing_plugin.vcxproj')",
            "--diag-log=$diagExeLog", "--diag-log=$diagDllLog", "--out=$leOut")
        if ($LASTEXITCODE -ne 0) { throw "Linker evidence generation failed for run $i" }

        Write-HostInfo "Run $i complete: manifest, pe-inspection, linker-evidence written."
    }
}
finally {
    Pop-Location
}

# --- Deterministic ZIPs + byte comparison ------------------------------------
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

    $zip1Hash = Get-Sha256 $zip1
    $zip2Hash = Get-Sha256 $zip2
    $zip1RHash = Get-Sha256 $zip1Rebuild
    $zip2RHash = Get-Sha256 $zip2Rebuild

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

    # PE-level comparison between the two runs.
    $peCompareOut = Join-Path $runsDir 'pe-comparison.json'
    Invoke-Native $dartCmd @('run', 'tool/pe_inspect.dart',
        "--compare=$(Join-Path $run1Dir 'pe-inspection.json')",
        "--compare=$(Join-Path $run2Dir 'pe-inspection.json')",
        "--out=$peCompareOut")
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
    msvc            = [ordered]@{ linkExe = $script:LinkExe; linkVersion = $linkVersion; msbuild = $script:MsBuild }
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
        'dart run tool/pe_inspect.dart --run-id run-N --out pe-inspection.json --file <pe> ...',
        'MSBuild <proj>.vcxproj /p:Configuration=Release /t:Build /v:diag /nologo /p:BuildProjectReferences=false  (evidence relink)',
        'dart run tool/linker_evidence.dart --run-id run-N --linker-path <link.exe> --linker-version <v> --vcxproj <proj> --diag-log <log> --out linker-evidence.json',
        'dart run tool/repro_zip.dart --release-dir <snapshot> --out run-N-deterministic.zip --canonical-manifest run-N-manifest.json',
        'dart run tool/repro_compare.dart --run-1 <snap1> --run-2 <snap2> --manifest-1 <man1> --manifest-2 <man2> --out comparison.json',
        'dart run tool/pe_inspect.dart --compare run-1/pe-inspection.json run-2/pe-inspection.json --out pe-comparison.json'
    )
}
$envOut = Join-Path $runsDir 'environment.json'
Write-JsonNoBom -Path $envOut -Value $environment

# --- Mirror artifacts --------------------------------------------------------
$artifactsDir = Join-Path $AppRoot 'build\artifacts\reproducibility\muaman-13c'
New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null
Copy-Item -LiteralPath $man1 -Destination $artifactsDir -Force
Copy-Item -LiteralPath $man2 -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'comparison.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'pe-comparison.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'zip-comparison.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath $envOut -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'pe-inspection.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'pe-inspection.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'linker-evidence.json') -Destination $artifactsDir -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'linker-evidence.json') -Destination $artifactsDir -Force

# Committed evidence mirror (tracked, small JSON only).
$docsEvidence = Join-Path $AppRoot 'docs\muaman-13c\evidence'
New-Item -ItemType Directory -Force -Path $docsEvidence | Out-Null
Copy-Item -LiteralPath $man1 -Destination (Join-Path $docsEvidence 'run-1-manifest.json') -Force
Copy-Item -LiteralPath $man2 -Destination (Join-Path $docsEvidence 'run-2-manifest.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'comparison.json') -Destination (Join-Path $docsEvidence 'comparison.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'pe-comparison.json') -Destination (Join-Path $docsEvidence 'pe-comparison.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'zip-comparison.json') -Destination (Join-Path $docsEvidence 'zip-comparison.json') -Force
Copy-Item -LiteralPath $envOut -Destination (Join-Path $docsEvidence 'environment.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'pe-inspection.json') -Destination (Join-Path $docsEvidence 'run-1-pe-inspection.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'pe-inspection.json') -Destination (Join-Path $docsEvidence 'run-2-pe-inspection.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'linker-evidence.json') -Destination (Join-Path $docsEvidence 'run-1-linker-evidence.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'linker-evidence.json') -Destination (Join-Path $docsEvidence 'run-2-linker-evidence.json') -Force
Write-HostInfo "Committed evidence mirrored to: $docsEvidence"

# --- Summary ------------------------------------------------------------------
Write-HostInfo '===== SUMMARY ====='
Write-HostInfo "Baseline: $Baseline"
Write-HostInfo "Branch: $branch"
Write-HostInfo "Flutter: $flutterVersion | Dart: $dartVersion | CMake: $cmakeVersion"
Write-HostInfo "link.exe: $script:LinkExe ($linkVersion)"
Write-HostInfo "run-1 zip sha256: $zip1Hash"
Write-HostInfo "run-2 zip sha256: $zip2Hash"
Write-HostInfo "same-snapshot determinism run-1: $($zip1Hash -eq $zip1RHash)"
Write-HostInfo "same-snapshot determinism run-2: $($zip2Hash -eq $zip2RHash)"
Write-HostInfo "cross-build zip equality: $($zip1Hash -eq $zip2Hash)"
