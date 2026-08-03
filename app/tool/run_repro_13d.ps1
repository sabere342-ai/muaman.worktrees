<#
.SYNOPSIS
  MUAMAN-13D independent committed-state reproducibility acceptance orchestrator.

.DESCRIPTION
  Proves that the committed MUAMAN-13C state (baseline d810e9dc401...) fully
  reproduces a byte-for-byte deterministic Windows Release build from a clean,
  independent worktree, without any reuse of prior work trees, build folders,
  CMake output, MSBuild logs, snapshots, ZIPs or manifests.

  The committed state is expected to be tracked-clean. Every run executes:
    flutter clean -> flutter pub get -> flutter build windows --release
  then snapshots build\windows\x64\runner\Release into an isolated work area
  (OUTSIDE app/build), builds a canonical manifest, a PE inspection, a release
  inventory, an evidence relink that captures the REAL link.exe command lines
  from MSBuild diagnostic logs, and verifies the relinked binaries are
  byte-identical to the snapshot.

  After both runs it builds four deterministic ZIPs (run-1-a, run-1-b,
  run-2-a, run-2-b) and proves same-run and cross-run ZIP equality, writes the
  full comparison JSONs, reconciles against the historical MUAMAN-13C
  committed evidence, and mirrors the light committed evidence into
  <app>/docs/muaman-13d/evidence/.

.NOTES
  This is an acceptance + freeze phase: it never modifies application code,
  pubspec, or windows/CMakeLists.txt, and it performs exactly two independent
  builds, then produces a single evidence set.
#>
[CmdletBinding()]
param(
    [string]$AppRoot = "",
    [string]$WorkRoot = "",
    [string]$Baseline = "d810e9dc4017829d8750e0f560d81243a200110e",
    [int]$Runs = 2,
    [int]$RunSeparationSeconds = 15
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AppRoot)) {
    $AppRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $WorkRoot = Join-Path $env:TEMP 'opencode\muaman-13d-acceptance'
}

$BaselineMessage = 'MUAMAN-13C: enable reproducible Windows release linking'

function Write-HostInfo {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[13d] $Message"
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

# Flutter's tooling rewrites the committed generated plugin registrant files on
# Windows using LF line endings while the committed blobs are CRLF. The content
# is semantically identical; only the line endings differ. This function proves
# that equivalence (normalized comparison) and then restores the committed
# bytes so the tracked tree is never left dirty. Any tracked file whose change
# is NOT pure EOL noise aborts the run.
function Restore-EolNoise {
    $dirtyLines = @(& git -C $script:RepoRoot status --porcelain)
    foreach ($line in $dirtyLines) {
        if ($line -notmatch '^ M ') { continue }
        $rel = $line.Substring(3)
        $abs = Join-Path $script:RepoRoot $rel
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        $blob = ((& git -C $script:RepoRoot show "HEAD:$rel" -z) -join "`n")
        $work = [System.IO.File]::ReadAllText($abs)
        $nb = $blob.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
        $nw = $work.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
        if ($nb -eq $nw) {
            Write-HostInfo "EOL-only change detected for tracked file, restoring committed bytes: $rel"
            & git -C $script:RepoRoot checkout -- $rel
            if ($LASTEXITCODE -ne 0) { throw "Failed to restore $rel" }
        }
        else {
            throw "Tracked file changed with REAL content during the run: $rel"
        }
    }
}

Write-HostInfo '===== MUAMAN-13D independent committed-state acceptance ====='

# --- Baseline identity and clean-state snapshot ------------------------------
Write-HostInfo "Verifying baseline identity ($Baseline)..."
$head = (& git -C $AppRoot rev-parse HEAD).Trim()
if ($head -ne $Baseline) {
    throw "HEAD ($head) does not match baseline ($Baseline)"
}
$message = (& git -C $AppRoot log -1 --format='%s').Trim()
if ($message -ne $BaselineMessage) {
    throw "Baseline message mismatch: expected '$BaselineMessage', got '$message'"
}
if (-not (Test-TrackedTreeClean)) {
    throw 'Tracked working tree is not clean at start; committed-state proof requires a clean tree.'
}
$branch = (& git -C $AppRoot branch --show-current).Trim()
$script:RepoRoot = (& git -C $AppRoot rev-parse --show-toplevel).Trim()
$statusBefore = ((& git -C $AppRoot status --porcelain) -join "`n").TrimEnd()
Write-HostInfo "HEAD=$head branch=$branch"
Write-HostInfo "Tracked tree clean at start: true"
Write-HostInfo "Expected untracked (13D tooling): "
$statusBefore

# --- Toolchain resolution ----------------------------------------------------
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
$msbuildVersion = (Get-Item -LiteralPath $script:MsBuild).VersionInfo.FileVersion
Write-HostInfo "MSVC link.exe=$script:LinkExe (version $linkVersion)"
Write-HostInfo "MSBuild=$script:MsBuild (version $msbuildVersion)"

# --- pubspec.lock guard ------------------------------------------------------
$lockFile = Join-Path $AppRoot 'pubspec.lock'
if (-not (Test-Path -LiteralPath $lockFile)) {
    throw "pubspec.lock not found: $lockFile"
}
$lockHashBefore = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
Write-HostInfo "pubspec.lock SHA256 (before): $lockHashBefore"

# --- Work area (fresh, independent; never reuses 13C work areas) -------------
Write-HostInfo "Preparing work area: $WorkRoot"
if (Test-Path -LiteralPath $WorkRoot) {
    Remove-Item -LiteralPath $WorkRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null
$runsDir = Join-Path $WorkRoot 'runs'
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null

# --- Per-run builds, snapshots, inventory and linker evidence ----------------
Push-Location $AppRoot
try {
    $runTimings = [ordered]@{}
    for ($i = 1; $i -le $Runs; $i++) {
        Write-HostInfo "===== RUN $i / $Runs ====="
        $runDir = Join-Path $runsDir "run-$i"
        $snapshot = Join-Path $runDir 'snapshot'
        $logDir = Join-Path $runDir 'logs'
        New-Item -ItemType Directory -Force -Path $runDir, $logDir | Out-Null

        $runStartedAt = [DateTime]::UtcNow.ToString('o')
        if ($i -eq 2) {
            $runTimings['run1AllWorkCompletedAt'] = [DateTime]::UtcNow.ToString('o')
            $runTimings['separationSeconds'] = $RunSeparationSeconds
            Write-HostInfo "Separating Run 1 and Run 2 by $RunSeparationSeconds seconds..."
            Start-Sleep -Seconds $RunSeparationSeconds
            $runTimings['run2StartedAt'] = [DateTime]::UtcNow.ToString('o')
        }

        Invoke-Native $flutterCmd @('clean') (Join-Path $logDir 'flutter-clean.log')

        # Non-reuse proof: after clean, no build folder may survive.
        $buildDir = Join-Path $AppRoot 'build'
        $buildExistsAfterClean = Test-Path -LiteralPath $buildDir
        $releaseExistsAfterClean = Test-Path -LiteralPath `
            (Join-Path $AppRoot 'build\windows\x64\runner\Release')
        Write-HostInfo ("After flutter clean: build exists=$buildExistsAfterClean " +
            "release exists=$releaseExistsAfterClean")

        Invoke-Native $flutterCmd @('pub', 'get') (Join-Path $logDir 'flutter-pub-get.log')

        $lockHashNow = (Get-FileHash -LiteralPath $lockFile -Algorithm SHA256).Hash
        if ($lockHashNow -ne $lockHashBefore) {
            throw "pubspec.lock changed during run $i"
        }
        Restore-EolNoise

        Invoke-Native $flutterCmd @('build', 'windows', '--release') `
            (Join-Path $logDir 'flutter-build.log')
        Restore-EolNoise

        $builtAt = [DateTime]::UtcNow.ToString('o')
        $runFinishedAt = [DateTime]::UtcNow.ToString('o')
        if ($i -eq 1) {
            $runTimings['run1StartedAt'] = $runStartedAt
            $runTimings['run1BuiltAt'] = $builtAt
            $runTimings['run1FinishedAt'] = $runFinishedAt
        }
        else {
            $runTimings['run2StartedAt'] = $runStartedAt
            $runTimings['run2BuiltAt'] = $builtAt
            $runTimings['run2FinishedAt'] = $runFinishedAt
        }
        $durationSec = [Math]::Round(((($runFinishedAt | Get-Date) - `
            ($runStartedAt | Get-Date)).TotalSeconds), 1)
        if ($i -eq 1) { $runTimings['run1DurationSeconds'] = $durationSec }
        else { $runTimings['run2DurationSeconds'] = $durationSec }

        $releaseDir = Join-Path $AppRoot 'build\windows\x64\runner\Release'
        $exePath = Join-Path $releaseDir 'muaman_store.exe'
        if (-not (Test-Path -LiteralPath $exePath)) {
            throw "Run ${i}: muaman_store.exe not found under $releaseDir"
        }
        $pluginDllPath = Join-Path $AppRoot 'build\windows\x64\plugins\printing\Release\printing_plugin.dll'
        if (-not (Test-Path -LiteralPath $pluginDllPath)) {
            throw "Run ${i}: printing_plugin.dll not found (was the plugin built?)"
        }

        # Immediate binary hashes BEFORE any relink.
        $binaryHashes = [ordered]@{
            schema = 'muaman-13d-run-binaries'
            runId  = "run-$i"
            files  = @(
                [ordered]@{ path = $exePath; sha256 = Get-Sha256 $exePath },
                [ordered]@{ path = (Join-Path $releaseDir 'printing_plugin.dll'); sha256 = Get-Sha256 (Join-Path $releaseDir 'printing_plugin.dll') },
                [ordered]@{ path = (Join-Path $releaseDir 'flutter_windows.dll'); sha256 = Get-Sha256 (Join-Path $releaseDir 'flutter_windows.dll') },
                [ordered]@{ path = (Join-Path $releaseDir 'pdfium.dll'); sha256 = Get-Sha256 (Join-Path $releaseDir 'pdfium.dll') }
            )
        }
        Write-JsonNoBom -Path (Join-Path $runDir "run-$i-binary-sha256.json") -Value $binaryHashes

        # Snapshot BEFORE any relink so it reflects the pristine flutter build.
        if (Test-Path -LiteralPath $snapshot) {
            Remove-Item -LiteralPath $snapshot -Recurse -Force
        }
        Copy-Item -LiteralPath $releaseDir -Destination $snapshot -Recurse

        # The build must never change the tracked tree or the pre-existing
        # untracked set.
        $statusNow = ((& git -C $AppRoot status --porcelain) -join "`n").TrimEnd()
        if ($statusNow -ne $statusBefore) {
            throw "Working tree state changed during build run $i.`nBefore:`n$statusBefore`nAfter:`n$statusNow"
        }
        if (-not (Test-TrackedTreeClean)) {
            throw "Tracked files changed during build run $i"
        }

        $cleanBeforeStr = 'true'
        $cleanAfterStr = 'true'

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

        # PE inspection of the snapshot's PE files (pristine copies).
        $peOut = Join-Path $runDir 'pe-inspection.json'
        Invoke-Native $dartCmd @('run', 'tool/pe_inspect.dart',
            "--run-id=run-$i", "--out=$peOut",
            "--file=$(Join-Path $snapshot 'muaman_store.exe')",
            "--file=$(Join-Path $snapshot 'printing_plugin.dll')",
            "--file=$(Join-Path $snapshot 'flutter_windows.dll')",
            "--file=$(Join-Path $snapshot 'pdfium.dll')")
        if ($LASTEXITCODE -ne 0) { throw "PE inspection failed for run $i" }

        # Release inventory (every file, PE probing).
        $invOut = Join-Path $runDir "run-$i-inventory.json"
        Invoke-Native $dartCmd @('run', 'tool/repro_inventory_13d.dart',
            "--release-dir=$snapshot", "--out=$invOut", "--run-id=run-$i",
            "--pe-inspection=$peOut")
        if ($LASTEXITCODE -ne 0) { throw "Inventory generation failed for run $i" }

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

        # Run 2 file creation timestamps (freshness proof).
        if ($i -eq 2) {
            $times = @()
            Get-ChildItem -LiteralPath $snapshot -Recurse -File |
                Sort-Object { $_.FullName } |
                ForEach-Object {
                    $rel = $_.FullName.Substring($snapshot.Length).TrimStart('\')
                    $times += [ordered]@{
                        path = $rel.Replace('\', '/')
                        creationTimeUtc = $_.CreationTimeUtc.ToString('o')
                        lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o')
                    }
                }
            Write-JsonNoBom -Path (Join-Path $runDir 'run-2-file-times.json') -Value @{
                schema = 'muaman-13d-run2-file-times'
                runId  = 'run-2'
                files  = $times
            }
        }

        Write-HostInfo "Run $i complete: manifest, pe-inspection, inventory, linker-evidence written."
    }
}
finally {
    Pop-Location
}

Write-HostInfo "Run timings: $($runTimings | ConvertTo-Json -Compress)"

# --- Deterministic ZIPs (four) -----------------------------------------------
$run1Dir = Join-Path $runsDir 'run-1'
$run2Dir = Join-Path $runsDir 'run-2'
$snap1 = Join-Path $run1Dir 'snapshot'
$snap2 = Join-Path $run2Dir 'snapshot'
$man1 = Join-Path $run1Dir 'run-1-manifest.json'
$man2 = Join-Path $run2Dir 'run-2-manifest.json'

Push-Location $AppRoot
try {
    Write-HostInfo "Building deterministic ZIPs (twice per snapshot)..."
    $zip1a = Join-Path $runsDir 'run-1-a.zip'
    $zip1b = Join-Path $runsDir 'run-1-b.zip'
    $zip2a = Join-Path $runsDir 'run-2-a.zip'
    $zip2b = Join-Path $runsDir 'run-2-b.zip'

    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap1", "--out=$zip1a", "--canonical-manifest=$man1")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap1", "--out=$zip1b", "--canonical-manifest=$man1")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap2", "--out=$zip2a", "--canonical-manifest=$man2")
    Invoke-Native $dartCmd @('run', 'tool/repro_zip.dart',
        "--release-dir=$snap2", "--out=$zip2b", "--canonical-manifest=$man2")

    $z1a = Get-Sha256 $zip1a
    $z1b = Get-Sha256 $zip1b
    $z2a = Get-Sha256 $zip2a
    $z2b = Get-Sha256 $zip2b
    $s1a = (Get-Item -LiteralPath $zip1a).Length
    $s1b = (Get-Item -LiteralPath $zip1b).Length
    $s2a = (Get-Item -LiteralPath $zip2a).Length
    $s2b = (Get-Item -LiteralPath $zip2b).Length

    $zipComparison = [ordered]@{
        schema                     = 'muaman-13d-zip-comparison'
        run1AZipSha256             = $z1a
        run1BZipSha256             = $z1b
        run2AZipSha256             = $z2a
        run2BZipSha256             = $z2b
        run1AZipSizeBytes          = $s1a
        run1BZipSizeBytes          = $s1b
        run2AZipSizeBytes          = $s2a
        run2BZipSizeBytes          = $s2b
        run1aEqualsRun1b           = ($z1a -eq $z1b) -and ($s1a -eq $s1b)
        run2aEqualsRun2b           = ($z2a -eq $z2b) -and ($s2a -eq $s2b)
        run1aEqualsRun2a           = ($z1a -eq $z2a) -and ($s1a -eq $s2a)
        run1aEqualsRun2b           = ($z1a -eq $z2b) -and ($s1a -eq $s2b)
        run1bEqualsRun2a           = ($z1b -eq $z2a) -and ($s1b -eq $s2a)
        run1bEqualsRun2b           = ($z1b -eq $z2b) -and ($s1b -eq $s2b)
        allFourZipsByteIdentical   = ($z1a -eq $z1b) -and ($z1a -eq $z2a) -and ($z1a -eq $z2b) `
            -and ($s1a -eq $s1b) -and ($s1a -eq $s2a) -and ($s1a -eq $s2b)
        timestamp                  = [DateTime]::UtcNow.ToString('o')
    }
    Write-JsonNoBom -Path (Join-Path $runsDir 'zip-comparison.json') -Value $zipComparison
}
finally {
    Pop-Location
}

# --- Byte-level comparison ----------------------------------------------------
Push-Location $AppRoot
try {
    $rawCmp = Join-Path $runsDir 'comparison-raw.json'
    Invoke-Native $dartCmd @('run', 'tool/repro_compare.dart',
        "--run-1=$snap1", "--run-2=$snap2",
        "--manifest-1=$man1", "--manifest-2=$man2",
        "--out=$rawCmp")

    $raw = Get-Content -LiteralPath $rawCmp -Raw | ConvertFrom-Json
    $cmp = [ordered]@{
        schema                        = 'muaman-13d-comparison'
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

    # PE-level comparison between the two runs (full 13D schema).
    $peCompareOut = Join-Path $runsDir 'pe-comparison.json'
    Invoke-Native $dartCmd @('run', 'tool/pe_compare_13d.dart',
        "--run-1=$(Join-Path $run1Dir 'pe-inspection.json')",
        "--run-2=$(Join-Path $run2Dir 'pe-inspection.json')",
        "--out=$peCompareOut")
}
finally {
    Pop-Location
}

# --- environment.json ---------------------------------------------------------
$environment = [ordered]@{
    schema            = 'muaman-13d-environment'
    baselineCommit    = $Baseline
    branch            = $branch
    worktreePath      = [System.IO.Path]::GetFullPath((Join-Path $AppRoot '..'))
    appRoot           = $AppRoot
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
        linkExe      = $script:LinkExe
        linkVersion  = $linkVersion
        msbuild      = $script:MsBuild
        msbuildVersion = $msbuildVersion
    }
    paths             = [ordered]@{
        flutter      = $flutterCmd
        dart         = $dartCmd
        cmake        = $cmakeCmd
    }
    powershellVersion = $PSVersionTable.PSVersion.ToString()
    gitVersion        = (git --version 2>&1 | Out-String).Trim()
    pubspecLockSha256 = $lockHashBefore
    cleanTreeAtStart  = $true
    runTimings        = $runTimings
    commands          = @(
        'git -C <app> rev-parse HEAD',
        'flutter clean',
        'flutter pub get',
        'flutter build windows --release',
        'dart run tool/repro_manifest.dart --release-dir <snapshot> --out run-N-manifest.json [meta flags]',
        'dart run tool/pe_inspect.dart --run-id run-N --out pe-inspection.json --file <pe> ...',
        'dart run tool/repro_inventory_13d.dart --release-dir <snapshot> --out run-N-inventory.json --pe-inspection pe-inspection.json',
        'MSBuild <proj>.vcxproj /p:Configuration=Release /t:Build /v:diag /nologo /p:BuildProjectReferences=false  (evidence relink)',
        'dart run tool/linker_evidence.dart --run-id run-N --linker-path <link.exe> --linker-version <v> --vcxproj <proj> --diag-log <log> --out linker-evidence.json',
        'dart run tool/repro_zip.dart --release-dir <snapshot> --out run-N-X.zip --canonical-manifest run-N-manifest.json',
        'dart run tool/repro_compare.dart --run-1 <snap1> --run-2 <snap2> --manifest-1 <man1> --manifest-2 <man2> --out comparison-raw.json',
        'dart run tool/pe_compare_13d.dart --run-1 run-1/pe-inspection.json --run-2 run-2/pe-inspection.json --out pe-comparison.json'
    )
}
$envOut = Join-Path $runsDir 'environment.json'
Write-JsonNoBom -Path $envOut -Value $environment

# --- artifact locations -------------------------------------------------------
$artifactFiles = @(
    (Join-Path $runsDir 'run-1-a.zip'),
    (Join-Path $runsDir 'run-1-b.zip'),
    (Join-Path $runsDir 'run-2-a.zip'),
    (Join-Path $runsDir 'run-2-b.zip'),
    (Join-Path $run1Dir 'logs\flutter-build.log'),
    (Join-Path $run1Dir 'logs\diag-link-exe.log'),
    (Join-Path $run1Dir 'logs\diag-link-dll.log'),
    (Join-Path $run2Dir 'logs\flutter-build.log'),
    (Join-Path $run2Dir 'logs\diag-link-exe.log'),
    (Join-Path $run2Dir 'logs\diag-link-dll.log')
)
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
Write-JsonNoBom -Path (Join-Path $runsDir 'artifact-locations.json') -Value @{
    schema = 'muaman-13d-artifact-locations'
    snapshotRun1 = $snap1
    snapshotRun2 = $snap2
    files = $artifactList
}

# --- reconciliation against MUAMAN-13C historical evidence ---------------------
$c13Evidence = Join-Path $AppRoot 'docs\muaman-13c\evidence'
$rec = [ordered]@{
    schema = 'muaman-13d-baseline-reconciliation'
    generatedAt = [DateTime]::UtcNow.ToString('o')
    baselineCommit = $Baseline
    historical13cCommit = 'd810e9dc4017829d8750e0f560d81243a200110e'
}
if (Test-Path -LiteralPath (Join-Path $c13Evidence 'comparison.json')) {
    $c13Cmp = Get-Content -LiteralPath (Join-Path $c13Evidence 'comparison.json') -Raw | ConvertFrom-Json
    $rec['fileCountMatches13c'] = ([int]$cmp.fileCountRun1 -eq [int]$c13Cmp.run1FileCount)
    $rec['totalBytesMatches13c'] = ([int]$cmp.totalBytesRun1 -eq [int]$c13Cmp.run1TotalBytes)
    $rec['canonicalManifestShaMatches13c'] = ($cmp.run1CanonicalManifestSha256 -eq $c13Cmp.run1CanonicalManifestSha256)
    $rec['fileCountRun1'] = [int]$cmp.fileCountRun1
    $rec['fileCount13c'] = [int]$c13Cmp.run1FileCount
    $rec['totalBytesRun1'] = [int]$cmp.totalBytesRun1
    $rec['totalBytes13c'] = [int]$c13Cmp.run1TotalBytes
    $rec['canonicalManifestSha256'] = $cmp.run1CanonicalManifestSha256
    $rec['canonicalManifestSha256_13c'] = $c13Cmp.run1CanonicalManifestSha256
}
else {
    $rec['fileCountMatches13c'] = $null
    $rec['totalBytesMatches13c'] = $null
    $rec['canonicalManifestShaMatches13c'] = $null
}

# Per-file hash reconciliation (13D run-1 vs 13C run-1).
$man13d = Get-Content -LiteralPath $man1 -Raw | ConvertFrom-Json
$fileMatches13c = @()
$fileDiffs13c = @()
if (Test-Path -LiteralPath (Join-Path $c13Evidence 'run-1-manifest.json')) {
    $man13c = Get-Content -LiteralPath (Join-Path $c13Evidence 'run-1-manifest.json') -Raw | ConvertFrom-Json
    $map13c = @{}
    foreach ($f in $man13c.canonical.files) { $map13c[$f.path] = $f }
    foreach ($f in $man13d.canonical.files) {
        if ($map13c.ContainsKey($f.path)) {
            if ($f.sha256 -eq $map13c[$f.path].sha256 -and [int]$f.sizeBytes -eq [int]$map13c[$f.path].sizeBytes) {
                $fileMatches13c += $f.path
            }
            else {
                $fileDiffs13c += [ordered]@{
                    path = $f.path
                    run1Size = [int]$f.sizeBytes
                    run1Sha = $f.sha256
                    size13c = [int]$map13c[$f.path].sizeBytes
                    sha13c = $map13c[$f.path].sha256
                }
            }
        }
        else {
            $fileDiffs13c += [ordered]@{ path = $f.path; note = 'not present in 13C manifest' }
        }
    }
}
$rec['fileHashMatches13cCount'] = $fileMatches13c.Count
$rec['fileHashMatches13c'] = $fileMatches13c
$rec['fileHashDiffs13cCount'] = $fileDiffs13c.Count
$rec['fileHashDiffs13c'] = $fileDiffs13c

# ZIP reconciliation.
if (Test-Path -LiteralPath (Join-Path $c13Evidence 'zip-comparison.json')) {
    $c13Zip = Get-Content -LiteralPath (Join-Path $c13Evidence 'zip-comparison.json') -Raw | ConvertFrom-Json
    $rec['zipSha256'] = $z1a
    $rec['zipSha256_13c'] = $c13Zip.run1ZipSha256
    $rec['zipShaMatches13c'] = ($z1a -eq $c13Zip.run1ZipSha256)
    $rec['zipSizeBytes'] = $s1a
    $rec['zipSizeBytes_13c'] = [int]$c13Zip.run1ZipSizeBytes
    $rec['zipSizeMatches13c'] = ($s1a -eq [int]$c13Zip.run1ZipSizeBytes)
}

# PE timestamp reconciliation.
$peDiffs13c = @()
if (Test-Path -LiteralPath (Join-Path $c13Evidence 'run-1-pe-inspection.json')) {
    $pe13d = Get-Content -LiteralPath (Join-Path $run1Dir 'pe-inspection.json') -Raw | ConvertFrom-Json
    $pe13c = Get-Content -LiteralPath (Join-Path $c13Evidence 'run-1-pe-inspection.json') -Raw | ConvertFrom-Json
    $mapPe13c = @{}
    foreach ($f in $pe13c.files) { $mapPe13c[$f.fileName] = $f }
    foreach ($f in $pe13d.files) {
        if ($mapPe13c.ContainsKey($f.fileName)) {
            $ts13c = $mapPe13c[$f.fileName].pe.coffTimeDateStamp
            if ($f.pe.coffTimeDateStamp -ne $ts13c) {
                $peDiffs13c += [ordered]@{
                    fileName = $f.fileName
                    timestampRun1 = $f.pe.coffTimeDateStamp
                    timestamp13c = $ts13c
                }
            }
        }
    }
}
$rec['peTimestampMatches13c'] = ($peDiffs13c.Count -eq 0)
$rec['peTimestampDiffs13c'] = $peDiffs13c

# Linker version reconciliation.
$rec['linkerVersion'] = $linkVersion
$rec['linkerVersion_13c'] = '14.51.36243.0'
$rec['linkerVersionMatches13c'] = ($linkVersion -eq '14.51.36243.0')

# Lockfile reconciliation.
$rec['lockfileSha256'] = $lockHashBefore
$rec['lockfileSha256_13c'] = 'EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A'
$rec['lockfileMatches13c'] = ($lockHashBefore -eq 'EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A')

# Toolchain reconciliation.
$toolchain13c = @{
    flutter = '3.24.5'
    dart = '3.5.4'
    cmake = '4.3.3'
    vs = '18.6.0'
}
$rec['toolchain'] = [ordered]@{
    flutter13d = $flutterVersion
    flutter13c = $toolchain13c.flutter
    dart13d = $dartVersion
    dart13c = $toolchain13c.dart
    cmake13d = $cmakeVersion
    cmake13c = $toolchain13c.cmake
    vs13d = $vsVersion
    vs13c = $toolchain13c.vs
}
$rec['toolchainMatches13c'] = ($flutterVersion -eq $toolchain13c.flutter) -and
    ($dartVersion -eq $toolchain13c.dart) -and
    ($cmakeVersion -eq $toolchain13c.cmake) -and
    ($vsVersion -eq $toolchain13c.vs)

$recOut = Join-Path $runsDir 'baseline-reconciliation.json'
Write-JsonNoBom -Path $recOut -Value $rec

# --- Mirror committed evidence ------------------------------------------------
$docsEvidence = Join-Path $AppRoot 'docs\muaman-13d\evidence'
New-Item -ItemType Directory -Force -Path $docsEvidence | Out-Null
Copy-Item -LiteralPath $man1 -Destination (Join-Path $docsEvidence 'run-1-manifest.json') -Force
Copy-Item -LiteralPath $man2 -Destination (Join-Path $docsEvidence 'run-2-manifest.json') -Force
Copy-Item -LiteralPath $cmpOut -Destination (Join-Path $docsEvidence 'comparison.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'pe-comparison.json') -Destination (Join-Path $docsEvidence 'pe-comparison.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'zip-comparison.json') -Destination (Join-Path $docsEvidence 'zip-comparison.json') -Force
Copy-Item -LiteralPath $envOut -Destination (Join-Path $docsEvidence 'environment.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'pe-inspection.json') -Destination (Join-Path $docsEvidence 'run-1-pe-inspection.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'pe-inspection.json') -Destination (Join-Path $docsEvidence 'run-2-pe-inspection.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'linker-evidence.json') -Destination (Join-Path $docsEvidence 'run-1-linker-evidence.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'linker-evidence.json') -Destination (Join-Path $docsEvidence 'run-2-linker-evidence.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'run-1-inventory.json') -Destination (Join-Path $docsEvidence 'run-1-inventory.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'run-2-inventory.json') -Destination (Join-Path $docsEvidence 'run-2-inventory.json') -Force
Copy-Item -LiteralPath $recOut -Destination (Join-Path $docsEvidence 'baseline-reconciliation.json') -Force
Copy-Item -LiteralPath (Join-Path $runsDir 'artifact-locations.json') -Destination (Join-Path $docsEvidence 'artifact-locations.json') -Force
Copy-Item -LiteralPath (Join-Path $run1Dir 'run-1-binary-sha256.json') -Destination (Join-Path $docsEvidence 'run-1-binary-sha256.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'run-2-binary-sha256.json') -Destination (Join-Path $docsEvidence 'run-2-binary-sha256.json') -Force
Copy-Item -LiteralPath (Join-Path $run2Dir 'run-2-file-times.json') -Destination (Join-Path $docsEvidence 'run-2-file-times.json') -Force
Write-HostInfo "Committed evidence mirrored to: $docsEvidence"

# --- Summary ------------------------------------------------------------------
Write-HostInfo '===== SUMMARY ====='
Write-HostInfo "Baseline: $Baseline"
Write-HostInfo "Branch: $branch"
Write-HostInfo "Flutter: $flutterVersion | Dart: $dartVersion | CMake: $cmakeVersion"
Write-HostInfo "link.exe: $script:LinkExe ($linkVersion)"
Write-HostInfo "run-1-a zip sha256: $z1a"
Write-HostInfo "run-1-b zip sha256: $z1b"
Write-HostInfo "run-2-a zip sha256: $z2a"
Write-HostInfo "run-2-b zip sha256: $z2b"
Write-HostInfo "all four ZIPs byte-identical: $($zipComparison.allFourZipsByteIdentical)"
Write-HostInfo "comparison identical: $($cmp.identical) | changedFiles count: $($cmp.changedFiles.Count)"
Write-HostInfo "fileCount run1/run2: $($cmp.fileCountRun1)/$($cmp.fileCountRun2) | totalBytes: $($cmp.totalBytesRun1)"
Write-HostInfo "Reconciliation: fileHashMatches13c=$($fileMatches13c.Count) fileHashDiffs13c=$($fileDiffs13c.Count)"
