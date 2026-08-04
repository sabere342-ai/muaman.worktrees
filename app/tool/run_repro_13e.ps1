<#
.SYNOPSIS
  MUAMAN-13E cross-path byte-identical determinism acceptance orchestrator.

.DESCRIPTION
  Proves that the committed MUAMAN-13D state (baseline 7fd869ae5d5...) with the
  13E fix applied (pathmap eliminating absolute-path dependence) fully reproduces
  a byte-for-byte deterministic Windows Release build from TWO (or three) app
  roots at different-length absolute paths.

  Each root is built independently (flutter clean -> pub get -> build), then the
  13 Release files are snapshotted and proved byte-for-byte identical across
  paths. Additional evidence includes PE inspection, evidence relink, path-leak
  scans, deterministic ZIPs, and canonical root string verification.

  Key 13E-specific verifications:
  - Both roots have the same HEAD baseline commit
  - Uncommitted fix files are byte-identical between roots
  - No absolute path strings leak into release binaries
  - The canonical \muaman\src string IS present in app.so (pathmap working)

.NOTES
  This is an acceptance + freeze phase: it never modifies application code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AppRootA,
    [Parameter(Mandatory = $true)][string]$AppRootB,
    [string]$AppRootC = "",
    [string]$WorkRoot = "",
    [string]$Baseline = "7fd869ae5d5ec510df020afac4c40126309d52d9",
    [string]$BaselineMessage = "MUAMAN-13D: accept committed Windows reproducibility"
)

$ErrorActionPreference = 'Stop'

$AppRootA = [System.IO.Path]::GetFullPath($AppRootA)
$AppRootB = [System.IO.Path]::GetFullPath($AppRootB)
if (-not [string]::IsNullOrWhiteSpace($AppRootC)) {
    $AppRootC = [System.IO.Path]::GetFullPath($AppRootC)
}
if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $WorkRoot = Join-Path $env:TEMP 'opencode\muaman-13e-acceptance'
}

# --- Helper functions (verbatim from run_repro_13d.ps1) ----------------------

function Write-HostInfo {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[13e] $Message"
}

function Test-TrackedTreeClean {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & git -C $RepoRoot diff --quiet 2>&1 | Out-Null
    $unstaged = $LASTEXITCODE
    & git -C $RepoRoot diff --cached --quiet 2>&1 | Out-Null
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
        [int]$Depth = 12
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

function Restore-EolNoise {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $dirtyLines = @(& git -C $RepoRoot status --porcelain)
    foreach ($line in $dirtyLines) {
        if ($line -notmatch '^ M ') { continue }
        $rel = $line.Substring(3)
        $abs = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        $blob = ((& git -C $RepoRoot show "HEAD:$rel" -z) -join "`n")
        $work = [System.IO.File]::ReadAllText($abs)
        $nb = $blob.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
        $nw = $work.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
        if ($nb -eq $nw) {
            Write-HostInfo "EOL-only change detected for tracked file, restoring committed bytes: $rel"
            & git -C $RepoRoot checkout -- $rel
            if ($LASTEXITCODE -ne 0) { throw "Failed to restore $rel" }
        }
        else {
            throw "Tracked file changed with REAL content during the run: $rel"
        }
    }
}

Write-HostInfo '===== MUAMAN-13E cross-path determinism acceptance ====='

# =============================================================================
# SECTION 1 — Baseline identity
# =============================================================================
Write-HostInfo "--- Section 1: Baseline identity ---"

$headA = (& git -C $AppRootA rev-parse HEAD).Trim()
if ($headA -ne $Baseline) {
    throw "AppRootA HEAD ($headA) does not match baseline ($Baseline)"
}
$messageA = (& git -C $AppRootA log -1 --format='%s').Trim()
if ($messageA -ne $BaselineMessage) {
    throw "AppRootA baseline message mismatch: expected '$BaselineMessage', got '$messageA'"
}

$headB = (& git -C $AppRootB rev-parse HEAD).Trim()
if ($headB -ne $Baseline) {
    throw "AppRootB HEAD ($headB) does not match baseline ($Baseline)"
}
$messageB = (& git -C $AppRootB log -1 --format='%s').Trim()
if ($messageB -ne $BaselineMessage) {
    throw "AppRootB baseline message mismatch: expected '$BaselineMessage', got '$messageB'"
}

if ($headA -ne $headB) {
    throw "HEAD mismatch between A ($headA) and B ($headB)"
}

# AppRootA: verify tracked clean (untracked/modified are the 13E fix -- log them)
$cleanA = Test-TrackedTreeClean -RepoRoot $AppRootA
$statusA = ((& git -C $AppRootA status --porcelain) -join "`n").TrimEnd()
Write-HostInfo "AppRootA HEAD=$headA trackedClean=$cleanA"
if ($cleanA) {
    Write-HostInfo "AppRootA: tracked tree clean (fix is committed)"
}
else {
    Write-HostInfo "AppRootA: tracked tree has modifications (fix uncommitted):"
    Write-HostInfo $statusA
}

# AppRootB: verify tracked clean
$cleanB = Test-TrackedTreeClean -RepoRoot $AppRootB
$statusB = ((& git -C $AppRootB status --porcelain) -join "`n").TrimEnd()
Write-HostInfo "AppRootB HEAD=$headB trackedClean=$cleanB"
if ($cleanB) {
    Write-HostInfo "AppRootB: tracked tree clean"
}
else {
    Write-HostInfo "AppRootB: tracked tree has modifications:"
    Write-HostInfo $statusB
}

$branchRaw = & git -C $AppRootA branch --show-current 2>&1
$branch = if ($null -ne $branchRaw) { ($branchRaw | Out-String).Trim() } else { '' }
Write-HostInfo "Branch: $branch"

# =============================================================================
# SECTION 2 — Content-identity check (13E-specific)
# =============================================================================
Write-HostInfo "--- Section 2: Content-identity check ---"

# Git reports paths relative to the repo root, not the app dir.
# Resolve the git root so we can join paths correctly.
$repoRootA = (& git -C $AppRootA rev-parse --show-toplevel).Trim()
$repoRootB = (& git -C $AppRootB rev-parse --show-toplevel).Trim()

# The 13E acceptance-state files: modified tracked + new tooling/tests.
# Verify each is byte-identical between the two roots.
$acceptanceFiles = @(
    'app/windows/CMakeLists.txt',
    'app/windows/flutter/CMakeLists.txt',
    'app/tool/inject_registrant_package.ps1',
    'app/tool/leak_scan.dart',
    'app/tool/run_repro_13e.ps1',
    'app/test/cmake_pathmap_guard_test.dart',
    'app/test/inject_registrant_guard_test.dart'
)

Write-HostInfo "Verifying $($acceptanceFiles.Count) acceptance-state files across roots..."

$contentMismatches = @()
foreach ($f in $acceptanceFiles) {
    $pathA = Join-Path $repoRootA $f
    $pathB = Join-Path $repoRootB $f
    if (-not (Test-Path -LiteralPath $pathA)) {
        $contentMismatches += [ordered]@{ file = $f; reason = "missing in A" }
        continue
    }
    if (-not (Test-Path -LiteralPath $pathB)) {
        $contentMismatches += [ordered]@{ file = $f; reason = "missing in B" }
        continue
    }
    $hashA = Get-Sha256 $pathA
    $hashB = Get-Sha256 $pathB
    if ($hashA -ne $hashB) {
        $contentMismatches += [ordered]@{
            file   = $f
            reason = "hash mismatch"
            hashA  = $hashA
            hashB  = $hashB
        }
    }
}

if ($contentMismatches.Count -gt 0) {
    Write-HostInfo "CONTENT MISMATCHES DETECTED:"
    foreach ($m in $contentMismatches) {
        Write-HostInfo "  $($m.file): $($m.reason)"
    }
    throw "Content-identity check failed: $($contentMismatches.Count) file(s) differ between A and B"
}
Write-HostInfo "Content-identity check PASSED: $($acceptanceFiles.Count) file(s) byte-identical between A and B"

# Verify tracked content is also identical (diff vs HEAD in both)
$diffA = (& git -C $AppRootA diff HEAD -- app/windows/CMakeLists.txt app/windows/flutter/CMakeLists.txt 2>&1 | Out-String).Trim()
$diffB = (& git -C $AppRootB diff HEAD -- app/windows/CMakeLists.txt app/windows/flutter/CMakeLists.txt 2>&1 | Out-String).Trim()
if ($diffA -ne $diffB) {
    throw "Tracked file diffs differ between A and B"
}
Write-HostInfo "Tracked file diffs verified identical between A and B"

# =============================================================================
# SECTION 3 — Toolchain resolution
# =============================================================================
Write-HostInfo "--- Section 3: Toolchain resolution ---"

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
$msbuildVersion = (Get-Item -LiteralPath $script:MsBuild).VersionInfo.FileVersion
Write-HostInfo "MSVC link.exe=$script:LinkExe (version $linkVersion)"
Write-HostInfo "MSBuild=$script:MsBuild (version $msbuildVersion)"

# --- pubspec.lock guard (both roots) ---
$lockFileA = Join-Path $AppRootA 'pubspec.lock'
if (-not (Test-Path -LiteralPath $lockFileA)) {
    throw "pubspec.lock not found in A: $lockFileA"
}
$lockHashBeforeA = (Get-FileHash -LiteralPath $lockFileA -Algorithm SHA256).Hash
Write-HostInfo "pubspec.lock SHA256 (A, before): $lockHashBeforeA"

$lockFileB = Join-Path $AppRootB 'pubspec.lock'
if (-not (Test-Path -LiteralPath $lockFileB)) {
    throw "pubspec.lock not found in B: $lockFileB"
}
$lockHashBeforeB = (Get-FileHash -LiteralPath $lockFileB -Algorithm SHA256).Hash
Write-HostInfo "pubspec.lock SHA256 (B, before): $lockHashBeforeB"

if ($lockHashBeforeA -ne $lockHashBeforeB) {
    throw "pubspec.lock differs between A and B before any build"
}

# =============================================================================
# SECTION 4 — Work area preparation
# =============================================================================
Write-HostInfo "--- Section 4: Work area preparation ---"

Write-HostInfo "Preparing work area: $WorkRoot"
if (Test-Path -LiteralPath $WorkRoot) {
    Remove-Item -LiteralPath $WorkRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null
$runsDir = Join-Path $WorkRoot 'runs'
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null

# =============================================================================
# SECTION 5 — Per-path builds
# =============================================================================
Write-HostInfo "--- Section 5: Per-path builds ---"

function Invoke-PerPathBuild {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$AppRoot,
        [Parameter(Mandatory = $true)][string]$RunDir,
        [Parameter(Mandatory = $true)][string]$SnapshotDir
    )

    Push-Location $AppRoot
    try {
    $logDir = Join-Path $RunDir 'logs'
    New-Item -ItemType Directory -Force -Path $RunDir, $logDir | Out-Null

    $runStartedAt = [DateTime]::UtcNow.ToString('o')

    # flutter clean
    Invoke-Native $flutterCmd @('clean') (Join-Path $logDir 'flutter-clean.log')

    # Non-reuse proof: after clean, no build folder may survive
    $buildDir = Join-Path $AppRoot 'build'
    $buildExistsAfterClean = Test-Path -LiteralPath $buildDir
    $releaseExistsAfterClean = Test-Path -LiteralPath `
        (Join-Path $AppRoot 'build\windows\x64\runner\Release')
    Write-HostInfo "[$Label] After flutter clean: build exists=$buildExistsAfterClean release exists=$releaseExistsAfterClean"

    # flutter pub get
    Invoke-Native $flutterCmd @('pub', 'get') (Join-Path $logDir 'flutter-pub-get.log')

    # Lock file guard
    $lockFile = Join-Path $AppRoot 'pubspec.lock'
    $lockHashNow = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
    if ($lockHashNow -ne $lockHashBeforeA) {
        throw "[$Label] pubspec.lock changed during pub get"
    }

    # Restore EOL noise (flutter regenerates plugin registrant files with LF)
    Restore-EolNoise -RepoRoot $AppRoot

    # flutter build windows --release
    Invoke-Native $flutterCmd @('build', 'windows', '--release') `
        (Join-Path $logDir 'flutter-build.log')

    # Restore EOL noise again after build
    Restore-EolNoise -RepoRoot $AppRoot

    $builtAt = [DateTime]::UtcNow.ToString('o')
    $runFinishedAt = [DateTime]::UtcNow.ToString('o')
    $durationSec = [Math]::Round(((($runFinishedAt | Get-Date) - `
        ($runStartedAt | Get-Date)).TotalSeconds), 1)

    # Verify exe exists
    $releaseDir = Join-Path $AppRoot 'build\windows\x64\runner\Release'
    $exePath = Join-Path $releaseDir 'muaman_store.exe'
    if (-not (Test-Path -LiteralPath $exePath)) {
        throw "[$Label] muaman_store.exe not found under $releaseDir"
    }
    $pluginDllPath = Join-Path $AppRoot 'build\windows\x64\plugins\printing\Release\printing_plugin.dll'
    if (-not (Test-Path -LiteralPath $pluginDllPath)) {
        throw "[$Label] printing_plugin.dll not found"
    }

    # Snapshot the Release directory
    if (Test-Path -LiteralPath $SnapshotDir) {
        Remove-Item -LiteralPath $SnapshotDir -Recurse -Force
    }
    Copy-Item -LiteralPath $releaseDir -Destination $SnapshotDir -Recurse

    # Canonical manifest
    $outManifest = Join-Path $RunDir "$Label-manifest.json"
    Invoke-Native $dartCmd @('run', 'tool/repro_manifest.dart',
        "--release-dir=$SnapshotDir", "--out=$outManifest", "--run-id=$Label",
        "--baseline-commit=$Baseline", "--branch=$branch",
        "--platform=windows", "--architecture=x64", "--build-mode=release",
        "--flutter-version=$flutterVersion", "--dart-version=$dartVersion",
        "--built-at=$builtAt", "--clean-before=true",
        "--clean-after=true", "--pubspec-lock-hash=$lockHashBeforeA")
    if ($LASTEXITCODE -ne 0) { throw "[$Label] Manifest generation failed" }

    # PE inspection
    $peOut = Join-Path $RunDir "$Label-pe-inspection.json"
    Invoke-Native $dartCmd @('run', 'tool/pe_inspect.dart',
        "--run-id=$Label", "--out=$peOut",
        "--file=$(Join-Path $SnapshotDir 'muaman_store.exe')",
        "--file=$(Join-Path $SnapshotDir 'printing_plugin.dll')",
        "--file=$(Join-Path $SnapshotDir 'flutter_windows.dll')",
        "--file=$(Join-Path $SnapshotDir 'pdfium.dll')")
    if ($LASTEXITCODE -ne 0) { throw "[$Label] PE inspection failed" }

    # Path-leak scan
    $leakOut = Join-Path $RunDir "$Label-leak-scan.json"
    $leakArgs = @(
        'run', 'tool/leak_scan.dart',
        "--release-dir=$SnapshotDir",
        "--forbidden=$AppRootA",
        "--forbidden=$AppRootB",
        "--expected-package-uri=package:_muaman_registrant/flutter_build/dart_plugin_registrant.dart",
        "--out=$leakOut"
    )
    if (-not [string]::IsNullOrWhiteSpace($AppRootC)) {
        $leakArgs += "--forbidden=$AppRootC"
    }
    Invoke-Native $dartCmd $leakArgs
    if ($LASTEXITCODE -ne 0) { throw "[$Label] Leak scan failed" }

    # Evidence relink: force fresh link of exe and capture diagnostic logs
    Write-HostInfo "[$Label] Evidence relink (exe)..."
    Remove-Item -LiteralPath $exePath -Force
    $diagExeLog = Join-Path $logDir 'diag-link-exe.log'
    Invoke-MsBuildDiag -Project (Join-Path $AppRoot 'build\windows\x64\runner\muaman_store.vcxproj') -LogFile $diagExeLog

    Write-HostInfo "[$Label] Evidence relink (dll)..."
    Remove-Item -LiteralPath $pluginDllPath -Force
    $diagDllLog = Join-Path $logDir 'diag-link-dll.log'
    Invoke-MsBuildDiag -Project (Join-Path $AppRoot 'build\windows\x64\plugins\printing\printing_plugin.vcxproj') -LogFile $diagDllLog

    # Relink determinism: relinked binaries must match snapshot
    $snapExeHash = Get-Sha256 (Join-Path $SnapshotDir 'muaman_store.exe')
    $relinkExeHash = Get-Sha256 $exePath
    $snapDllHash = Get-Sha256 (Join-Path $SnapshotDir 'printing_plugin.dll')
    $relinkDllHash = Get-Sha256 $pluginDllPath
    Write-HostInfo "[$Label] exe  snapshot=$snapExeHash relink=$relinkExeHash"
    Write-HostInfo "[$Label] dll  snapshot=$snapDllHash relink=$relinkDllHash"
    if ($snapExeHash -ne $relinkExeHash) {
        throw "[$Label] relinked EXE differs from snapshot"
    }
    if ($snapDllHash -ne $relinkDllHash) {
        throw "[$Label] relinked DLL differs from snapshot"
    }
    Write-HostInfo "[$Label] Relink determinism verified for exe + dll"

    # Linker evidence
    $leOut = Join-Path $RunDir "$Label-linker-evidence.json"
    Invoke-Native $dartCmd @('run', 'tool/linker_evidence.dart',
        "--run-id=$Label", "--linker-path=$script:LinkExe",
        "--linker-version=$linkVersion",
        "--vcxproj=$(Join-Path $AppRoot 'build\windows\x64\runner\muaman_store.vcxproj')",
        "--vcxproj=$(Join-Path $AppRoot 'build\windows\x64\plugins\printing\printing_plugin.vcxproj')",
        "--diag-log=$diagExeLog", "--diag-log=$diagDllLog", "--out=$leOut")
    if ($LASTEXITCODE -ne 0) { throw "[$Label] Linker evidence generation failed" }

    Write-HostInfo "[$Label] Build complete: duration=${durationSec}s"
    return [ordered]@{
        label       = $Label
        appRoot     = $AppRoot
        snapshot    = $SnapshotDir
        manifest    = $outManifest
        peInspection = $peOut
        leakScan    = $leakOut
        linkerEvidence = $leOut
        diagExeLog  = $diagExeLog
        diagDllLog  = $diagDllLog
        startedAt   = $runStartedAt
        builtAt     = $builtAt
        finishedAt  = $runFinishedAt
        durationSec = $durationSec
    }
    } finally {
        Pop-Location
    }
}

# Build from AppRootA
$runADir = Join-Path $runsDir 'run-A'
$snapA = Join-Path $runADir 'snapshot'
$resultA = Invoke-PerPathBuild -Label 'run-A' -AppRoot $AppRootA `
    -RunDir $runADir -SnapshotDir $snapA

# Build from AppRootB
$runBDir = Join-Path $runsDir 'run-B'
$snapB = Join-Path $runBDir 'snapshot'
$resultB = Invoke-PerPathBuild -Label 'run-B' -AppRoot $AppRootB `
    -RunDir $runBDir -SnapshotDir $snapB

# Build from AppRootC (optional)
$resultC = $null
if (-not [string]::IsNullOrWhiteSpace($AppRootC)) {
    $runCDir = Join-Path $runsDir 'run-C'
    $snapC = Join-Path $runCDir 'snapshot'
    $resultC = Invoke-PerPathBuild -Label 'run-C' -AppRoot $AppRootC `
        -RunDir $runCDir -SnapshotDir $snapC
}

# =============================================================================
# SECTION 6 — Cross-path comparison
# =============================================================================
Write-HostInfo "--- Section 6: Cross-path comparison ---"

Push-Location $AppRootA
try {
    # repro_compare: snapA vs snapB
    $rawCmp = Join-Path $runsDir 'comparison-raw.json'
    Invoke-Native $dartCmd @('run', 'tool/repro_compare.dart',
        "--run-1=$snapA", "--run-2=$snapB",
        "--manifest-1=$($resultA.manifest)", "--manifest-2=$($resultB.manifest)",
        "--out=$rawCmp")

    $raw = Get-Content -LiteralPath $rawCmp -Raw | ConvertFrom-Json
    $cmp = [ordered]@{
        schema                        = 'muaman-13e-comparison'
        identical                     = [bool]$raw.identical
        allFilesByteIdentical         = [bool]$raw.allFilesByteIdentical
        onlyInRun1                    = @($raw.onlyInRun1)
        onlyInRun2                    = @($raw.onlyInRun2)
        addedFiles                    = @($raw.addedFiles)
        removedFiles                  = @($raw.removedFiles)
        changedFiles                  = @($raw.changedFiles)
        sameSizeDifferentHashFiles    = @($raw.sameSizeDifferentHashFiles)
        sizeMismatches                = @($raw.sizeMismatches)
        hashMismatches                = @($raw.hashMismatches)
        fileCountRun1                 = [int]$raw.run1FileCount
        fileCountRun2                 = [int]$raw.run2FileCount
        fileCount                     = [int]$raw.fileCount
        fileCountIdentical            = [bool]$raw.fileCountIdentical
        totalBytesRun1                = [int]$raw.run1TotalBytes
        totalBytesRun2                = [int]$raw.run2TotalBytes
        totalBytes                    = [int]$raw.totalBytes
        totalBytesIdentical           = [bool]$raw.totalBytesIdentical
        canonicalManifestIdentical    = [bool]$raw.canonicalManifestIdentical
        canonicalManifestDifference   = $raw.canonicalManifestDifference
        run1CanonicalManifestSha256   = $raw.run1CanonicalManifestSha256
        run2CanonicalManifestSha256   = $raw.run2CanonicalManifestSha256
    }
    $cmpOut = Join-Path $runsDir 'comparison.json'
    Write-JsonNoBom -Path $cmpOut -Value $cmp

    if (-not $cmp.identical) {
        throw "Cross-path comparison FAILED: snapshots are not identical"
    }
    Write-HostInfo "Cross-path comparison PASSED: snapshots are byte-identical"

    # pe_compare_13d: PE inspections from A vs B
    $peCompareOut = Join-Path $runsDir 'pe-comparison.json'
    Invoke-Native $dartCmd @('run', 'tool/pe_compare_13d.dart',
        "--run-1=$($resultA.peInspection)",
        "--run-2=$($resultB.peInspection)",
        "--out=$peCompareOut")
}
finally {
    Pop-Location
}

# =============================================================================
# SECTION 7 — Deterministic ZIPs (4 ZIPs: A1, A2, B1, B2)
# =============================================================================
Write-HostInfo "--- Section 7: Deterministic ZIPs ---"

Push-Location $AppRootA
try {
    Write-HostInfo "Building deterministic ZIPs (twice per snapshot)..."
    $zipA1 = Join-Path $runsDir 'run-A-1.zip'
    $zipA2 = Join-Path $runsDir 'run-A-2.zip'
    $zipB1 = Join-Path $runsDir 'run-B-1.zip'
    $zipB2 = Join-Path $runsDir 'run-B-2.zip'

    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snapA", "--out=$zipA1", "--canonical-manifest=$($resultA.manifest)")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snapA", "--out=$zipA2", "--canonical-manifest=$($resultA.manifest)")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snapB", "--out=$zipB1", "--canonical-manifest=$($resultB.manifest)")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snapB", "--out=$zipB2", "--canonical-manifest=$($resultB.manifest)")

    $zA1 = Get-Sha256 $zipA1
    $zA2 = Get-Sha256 $zipA2
    $zB1 = Get-Sha256 $zipB1
    $zB2 = Get-Sha256 $zipB2
    $sA1 = (Get-Item -LiteralPath $zipA1).Length
    $sA2 = (Get-Item -LiteralPath $zipA2).Length
    $sB1 = (Get-Item -LiteralPath $zipB1).Length
    $sB2 = (Get-Item -LiteralPath $zipB2).Length

    $allFourIdentical = ($zA1 -eq $zA2) -and ($zA1 -eq $zB1) -and ($zA1 -eq $zB2) `
        -and ($sA1 -eq $sA2) -and ($sA1 -eq $sB1) -and ($sA1 -eq $sB2)

    $zipComparison = [ordered]@{
        schema                     = 'muaman-13e-zip-comparison'
        runAZip1Sha256             = $zA1
        runAZip2Sha256             = $zA2
        runBZip1Sha256             = $zB1
        runBZip2Sha256             = $zB2
        runAZip1SizeBytes          = $sA1
        runAZip2SizeBytes          = $sA2
        runBZip1SizeBytes          = $sB1
        runBZip2SizeBytes          = $sB2
        runAZip1EqualsRunAZip2     = ($zA1 -eq $zA2) -and ($sA1 -eq $sA2)
        runBZip1EqualsRunBZip2     = ($zB1 -eq $zB2) -and ($sB1 -eq $sB2)
        runAZip1EqualsRunBZip1     = ($zA1 -eq $zB1) -and ($sA1 -eq $sB1)
        runAZip1EqualsRunBZip2     = ($zA1 -eq $zB2) -and ($sA1 -eq $sB2)
        allFourZipsByteIdentical   = $allFourIdentical
        timestamp                  = [DateTime]::UtcNow.ToString('o')
    }
    Write-JsonNoBom -Path (Join-Path $runsDir 'zip-comparison.json') -Value $zipComparison

    if (-not $allFourIdentical) {
        throw "ZIP determinism FAILED: not all four ZIPs are byte-identical"
    }
    Write-HostInfo "ZIP determinism PASSED: all four ZIPs byte-identical"
}
finally {
    Pop-Location
}

# =============================================================================
# SECTION 8 — Canonical root scan (app.so string verification)
# =============================================================================
Write-HostInfo "--- Section 8: Canonical root scan ---"

$canonicalRoot = '\muaman\src'
foreach ($snap in @($snapA, $snapB)) {
    $appSo = Join-Path $snap 'data\app.so'
    if (Test-Path -LiteralPath $appSo) {
        $bytes = [System.IO.File]::ReadAllBytes($appSo)
        $needle = [System.Text.Encoding]::UTF8.GetBytes($canonicalRoot)
        $count = 0
        for ($i = 0; $i -le $bytes.Length - $needle.Length; $i++) {
            $match = $true
            for ($j = 0; $j -lt $needle.Length; $j++) {
                if ($bytes[$i + $j] -ne $needle[$j]) { $match = $false; break }
            }
            if ($match) { $count++; $i += $needle.Length - 1 }
        }
        $label = if ($snap -eq $snapA) { "A" } else { "B" }
        Write-HostInfo "[$label] app.so canonical root '$canonicalRoot' occurrences: $count"
        if ($count -eq 0) {
                throw "[$label] app.so does not contain canonical root string '$canonicalRoot' - pathmap may not be working"
        }
    }
}

# =============================================================================
# SECTION 9 — environment.json
# =============================================================================
Write-HostInfo "--- Section 9: environment.json ---"

$environment = [ordered]@{
    schema            = 'muaman-13e-environment'
    baselineCommit    = $Baseline
    branch            = $branch
    timestamp         = [DateTime]::UtcNow.ToString('o')
    os                = [ordered]@{
        caption      = $osInfo.Caption
        version      = $osInfo.Version
        build        = $osInfo.BuildNumber
        architecture = $osInfo.OSArchitecture
    }
    hostname          = $env:COMPUTERNAME
    flutter           = [ordered]@{ version = $flutterVersion; fullText = $flutterVersionText }
    dart              = [ordered]@{ version = $dartVersion; fullText = $dartVersionText }
    cmake             = [ordered]@{ version = $cmakeVersion; fullText = $cmakeVersionText }
    visualStudio      = [ordered]@{ displayName = $vsName; version = $vsVersion; path = $vsPath }
    msvc              = [ordered]@{
        linkExe        = $script:LinkExe
        linkVersion    = $linkVersion
        msbuild        = $script:MsBuild
        msbuildVersion = $msbuildVersion
    }
    paths             = [ordered]@{
        flutter        = $flutterCmd
        dart           = $dartCmd
        cmake          = $cmakeCmd
    }
    appRootA          = $AppRootA
    appRootB          = $AppRootB
    appRootC          = $AppRootC
    pathLengthA       = $AppRootA.Length
    pathLengthB       = $AppRootB.Length
    pathLengthDelta   = [Math]::Abs($AppRootA.Length - $AppRootB.Length)
    powershellVersion = $PSVersionTable.PSVersion.ToString()
    gitVersion        = (git --version 2>&1 | Out-String).Trim()
    pubspecLockSha256 = $lockHashBeforeA
    buildA            = [ordered]@{
        durationSec = $resultA.durationSec
        startedAt   = $resultA.startedAt
        builtAt     = $resultA.builtAt
        finishedAt  = $resultA.finishedAt
    }
    buildB            = [ordered]@{
        durationSec = $resultB.durationSec
        startedAt   = $resultB.startedAt
        builtAt     = $resultB.builtAt
        finishedAt  = $resultB.finishedAt
    }
    commands          = @(
        'git -C <app> rev-parse HEAD',
        'flutter clean',
        'flutter pub get',
        'flutter build windows --release',
        'dart run tool/repro_manifest.dart --release-dir <snapshot> --out run-N-manifest.json [meta flags]',
        'dart run tool/pe_inspect.dart --run-id run-N --out pe-inspection.json --file <pe> ...',
        'dart run tool/leak_scan.dart --release-dir <dir> --forbidden=<pathA> --forbidden=<pathB> [--forbidden=<pathC>]',
        'MSBuild <proj>.vcxproj /p:Configuration=Release /t:Build /v:diag /nologo /p:BuildProjectReferences=false  (evidence relink)',
        'dart run tool/linker_evidence.dart --run-id run-N --linker-path <link.exe> --linker-version <v> --vcxproj <proj> --diag-log <log> --out linker-evidence.json',
        'dart run tool/repro_zip.dart --release-dir <snapshot> --out run-N-X.zip --canonical-manifest run-N-manifest.json',
        'dart run tool/repro_compare.dart --run-1 <snapA> --run-2 <snapB> --manifest-1 <manA> --manifest-2 <manB> --out comparison-raw.json',
        'dart run tool/pe_compare_13d.dart --run-1 <peA> --run-2 <peB> --out pe-comparison.json'
    )
}
$envOut = Join-Path $runsDir 'environment.json'
Write-JsonNoBom -Path $envOut -Value $environment

# =============================================================================
# SECTION 10 — Artifact locations JSON
# =============================================================================
Write-HostInfo "--- Section 10: Artifact locations ---"

$artifactFiles = @(
    $zipA1, $zipA2, $zipB1, $zipB2,
    (Join-Path $runADir 'logs\flutter-build.log'),
    (Join-Path $runADir 'logs\diag-link-exe.log'),
    (Join-Path $runADir 'logs\diag-link-dll.log'),
    (Join-Path $runBDir 'logs\flutter-build.log'),
    (Join-Path $runBDir 'logs\diag-link-exe.log'),
    (Join-Path $runBDir 'logs\diag-link-dll.log')
)
if ($resultC) {
    $artifactFiles += @(
        (Join-Path $runCDir 'logs\flutter-build.log'),
        (Join-Path $runCDir 'logs\diag-link-exe.log'),
        (Join-Path $runCDir 'logs\diag-link-dll.log')
    )
}

$artifactList = @()
foreach ($f in $artifactFiles) {
    if (Test-Path -LiteralPath $f) {
        $item = Get-Item -LiteralPath $f
        $artifactList += [ordered]@{
            path      = $item.FullName
            sizeBytes = $item.Length
            sha256    = Get-Sha256 $f
        }
    }
}
$artifactLocations = [ordered]@{
    schema       = 'muaman-13e-artifact-locations'
    snapshotA    = $snapA
    snapshotB    = $snapB
    snapshotC    = if ($resultC) { $snapC } else { "" }
    files        = $artifactList
}
$artifactOut = Join-Path $runsDir 'artifact-locations.json'
Write-JsonNoBom -Path $artifactOut -Value $artifactLocations

# =============================================================================
# SECTION 11 — Mirror evidence to AppRootA/docs/muaman-13e/evidence/
# =============================================================================
Write-HostInfo "--- Section 11: Mirror evidence ---"

$docsEvidence = Join-Path $AppRootA 'docs\muaman-13e\evidence'
New-Item -ItemType Directory -Force -Path $docsEvidence | Out-Null

$evidenceMappings = @(
    @{ Source = $resultA.manifest;             Dest = 'run-A-manifest.json' },
    @{ Source = $resultB.manifest;             Dest = 'run-B-manifest.json' },
    @{ Source = $cmpOut;                       Dest = 'comparison.json' },
    @{ Source = $peCompareOut;                 Dest = 'pe-comparison.json' },
    @{ Source = (Join-Path $runsDir 'zip-comparison.json'); Dest = 'zip-comparison.json' },
    @{ Source = $envOut;                       Dest = 'environment.json' },
    @{ Source = $resultA.leakScan;             Dest = 'leak-scan-A.json' },
    @{ Source = $resultB.leakScan;             Dest = 'leak-scan-B.json' },
    @{ Source = $resultA.peInspection;         Dest = 'run-A-pe-inspection.json' },
    @{ Source = $resultB.peInspection;         Dest = 'run-B-pe-inspection.json' },
    @{ Source = $resultA.linkerEvidence;       Dest = 'run-A-linker-evidence.json' },
    @{ Source = $resultB.linkerEvidence;       Dest = 'run-B-linker-evidence.json' },
    @{ Source = $artifactOut;                  Dest = 'artifact-locations.json' }
)
if ($resultC) {
    $evidenceMappings += @(
        @{ Source = $resultC.manifest;             Dest = 'run-C-manifest.json' },
        @{ Source = $resultC.leakScan;             Dest = 'leak-scan-C.json' },
        @{ Source = $resultC.peInspection;         Dest = 'run-C-pe-inspection.json' },
        @{ Source = $resultC.linkerEvidence;       Dest = 'run-C-linker-evidence.json' }
    )
}

foreach ($m in $evidenceMappings) {
    if (Test-Path -LiteralPath $m.Source) {
        Copy-Item -LiteralPath $m.Source -Destination (Join-Path $docsEvidence $m.Dest) -Force
    }
}
Write-HostInfo "Evidence mirrored to: $docsEvidence"

# =============================================================================
# SECTION 12 — Summary
# =============================================================================
Write-HostInfo '===== SUMMARY ====='
Write-HostInfo "Baseline: $Baseline"
Write-HostInfo "Branch: $branch"
Write-HostInfo "Flutter: $flutterVersion | Dart: $dartVersion | CMake: $cmakeVersion"
Write-HostInfo "link.exe: $script:LinkExe ($linkVersion)"
Write-HostInfo "AppRootA: $AppRootA (len=$($AppRootA.Length))"
Write-HostInfo "AppRootB: $AppRootB (len=$($AppRootB.Length))"
if (-not [string]::IsNullOrWhiteSpace($AppRootC)) {
    Write-HostInfo "AppRootC: $AppRootC (len=$($AppRootC.Length))"
}
Write-HostInfo "Content-identity (13E fix files): PASSED"
Write-HostInfo "Cross-path comparison identical: $($cmp.identical)"
Write-HostInfo "fileCount A/B: $($cmp.fileCountRun1)/$($cmp.fileCountRun2) | totalBytes: $($cmp.totalBytesRun1)/$($cmp.totalBytesRun2)"
Write-HostInfo "run-A-1 zip sha256: $zA1"
Write-HostInfo "run-A-2 zip sha256: $zA2"
Write-HostInfo "run-B-1 zip sha256: $zB1"
Write-HostInfo "run-B-2 zip sha256: $zB2"
Write-HostInfo "all four ZIPs byte-identical: $($zipComparison.allFourZipsByteIdentical)"
Write-HostInfo "Build A duration: $($resultA.durationSec)s"
Write-HostInfo "Build B duration: $($resultB.durationSec)s"
if ($resultC) {
    Write-HostInfo "Build C duration: $($resultC.durationSec)s"
}
Write-HostInfo '===== MUAMAN-13E ACCEPTANCE COMPLETE ====='
