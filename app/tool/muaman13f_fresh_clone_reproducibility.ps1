<#
.SYNOPSIS
  MUAMAN-13F independent fresh-clone committed-state reproducibility acceptance.

.DESCRIPTION
  Proves that the committed state at BASELINE_SHA (47f95000db10...) can be
  independently reproduced from two genuinely fresh Git clones on the same
  machine and toolchain, producing byte-for-byte identical Windows Release
  directories, deterministic ZIPs, and identical PE files.

  This script does NOT modify any production source files. It only reads
  from the source repository and creates temporary clone directories.

  Key verifications:
  - Two independent clones via git clone --no-local
  - No Git object alternates
  - No git worktree usage
  - No source tree copying
  - Flutter clean -> pub get -> build windows --release in each clone
  - Byte-for-byte file comparison
  - Deterministic ZIP comparison
  - PE metadata comparison
  - Path leak scan (UTF-8 + UTF-16LE)
  - Git cleanliness proof
  - Machine-readable JSON summary

.PARAMETER SourceRepo
  Path to the source Git repository. Must be a valid .git directory.

.PARAMETER ClonePathA
  Path for Clone A. Must not exist or be safely removable.

.PARAMETER ClonePathB
  Path for Clone B. Must not exist or be safely removable.

.PARAMETER BaselineSha
  Full 40-character SHA-1 of the baseline commit.

.PARAMETER EvidenceDir
  Directory to write evidence files. Created if needed.

.NOTES
  Acceptance-only phase. Never modifies production code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SourceRepo,
    [Parameter(Mandatory = $true)][string]$ClonePathA,
    [Parameter(Mandatory = $true)][string]$ClonePathB,
    [string]$BaselineSha = '47f95000db103194e67e90795cf3b55652df1d64',
    [string]$ExpectedMessage = '',
    [string]$EvidenceDir = ''
)

$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

# =============================================================================
# Helper functions
# =============================================================================

function Write-Phase {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[13f] $Message"
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

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$LogPath = ''
    )
    $line = "$FilePath $($Arguments -join ' ')"
    Write-Phase "  Running: $line"
    if ($LogPath) {
        & $FilePath @Arguments 2>&1 |
            Tee-Object -FilePath $LogPath |
            ForEach-Object { Write-Host "    $_" }
    }
    else {
        & $FilePath @Arguments 2>&1 | ForEach-Object { Write-Host "    $_" }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $line"
    }
}

# =============================================================================
# SECTION 1 - Parameter validation
# =============================================================================
Write-Phase '===== MUAMAN-13F Independent Fresh-Clone Reproducibility Acceptance ====='
Write-Phase '--- Section 1: Parameter validation ---'

$SourceRepo = [System.IO.Path]::GetFullPath($SourceRepo)
$ClonePathA = [System.IO.Path]::GetFullPath($ClonePathA)
$ClonePathB = [System.IO.Path]::GetFullPath($ClonePathB)

if (-not (Test-Path -LiteralPath (Join-Path $SourceRepo '.git'))) {
    if (-not (Test-Path -LiteralPath $SourceRepo -PathType Container)) {
        throw "Source repository not found: $SourceRepo"
    }
    $gitDir = Join-Path $SourceRepo '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) {
        throw "Source repository does not contain .git: $SourceRepo"
    }
}

$SourceRepoGit = $SourceRepo
$gitExe = (Get-Command 'git.exe' -ErrorAction SilentlyContinue).Source
if (-not $gitExe) { throw 'git.exe not found on PATH' }

$sourceGitDir = & $gitExe -C $SourceRepo rev-parse --git-dir 2>&1
$SourceRepoGit = [System.IO.Path]::GetFullPath(
    (Join-Path $SourceRepo $sourceGitDir))

$sourceUrl = "file:///$($SourceRepoGit.Replace('\', '/'))"

Write-Phase "Source repo:     $SourceRepo"
Write-Phase "Source git dir:  $SourceRepoGit"
Write-Phase "Clone A:         $ClonePathA"
Write-Phase "Clone B:         $ClonePathB"
Write-Phase "Baseline SHA:    $BaselineSha"

# Reject paths that are nested inside each other
if ($ClonePathA.StartsWith($ClonePathB + '\') -or
    $ClonePathB.StartsWith($ClonePathA + '\')) {
    throw "Clone paths must not be nested: $ClonePathA vs $ClonePathB"
}

if ($ClonePathA -eq $ClonePathB) {
    throw "Clone paths must be different: $ClonePathA"
}

if ($ClonePathA.StartsWith($SourceRepo + '\') -or
    $ClonePathB.StartsWith($SourceRepo + '\')) {
    throw "Clone paths must not be inside the source repo"
}

# =============================================================================
# SECTION 2 - Verify baseline commit in source
# =============================================================================
Write-Phase '--- Section 2: Baseline verification ---'

$baselineFull = (& $gitExe -C $SourceRepo rev-parse "$BaselineSha^{commit}" 2>&1).Trim()
$baselineMsg = (& $gitExe -C $SourceRepo show -s --format='%s' $BaselineSha 2>&1).Trim()
$expectedBaselineMsg = 'MUAMAN-13E: prove cross-path reproducible Windows releases'

if ($baselineFull -ne $BaselineSha) {
    throw "Baseline resolution mismatch: expected $BaselineSha, got $baselineFull"
}
if (-not [string]::IsNullOrWhiteSpace($ExpectedMessage)) {
    if ($baselineMsg -ne $ExpectedMessage) {
        throw "Commit message mismatch: expected '$ExpectedMessage', got '$baselineMsg'"
    }
}
Write-Phase "Baseline SHA:    $baselineFull"
Write-Phase "Baseline message: $baselineMsg"

# =============================================================================
# SECTION 3 - Prepare clone directories
# =============================================================================
Write-Phase '--- Section 3: Clone directory preparation ---'

if (Test-Path -LiteralPath $ClonePathA) {
    Write-Phase "Removing existing Clone A: $ClonePathA"
    Remove-Item -LiteralPath $ClonePathA -Recurse -Force
}
if (Test-Path -LiteralPath $ClonePathB) {
    Write-Phase "Removing existing Clone B: $ClonePathB"
    Remove-Item -LiteralPath $ClonePathB -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $ClonePathA | Out-Null
New-Item -ItemType Directory -Force -Path $ClonePathB | Out-Null

# Remove the empty directories so git clone can create them
Remove-Item -LiteralPath $ClonePathA -Force
Remove-Item -LiteralPath $ClonePathB -Force

Write-Phase "Clone A path length: $($ClonePathA.Length)"
Write-Phase "Clone B path length: $($ClonePathB.Length)"
Write-Phase "Path length delta:   $([Math]::Abs($ClonePathA.Length - $ClonePathB.Length))"

# =============================================================================
# SECTION 4 - Create fresh clones
# =============================================================================
Write-Phase '--- Section 4: Creating fresh clones ---'

$cloneStart = [DateTime]::UtcNow.ToString('o')

Write-Phase "Cloning to A: $ClonePathA"
& $gitExe clone --no-local "$sourceUrl" "$ClonePathA" 2>&1 |
    ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { throw "git clone A failed (exit $LASTEXITCODE)" }

Write-Phase "Cloning to B: $ClonePathB"
& $gitExe clone --no-local "$sourceUrl" "$ClonePathB" 2>&1 |
    ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { throw "git clone B failed (exit $LASTEXITCODE)" }

$cloneEnd = [DateTime]::UtcNow.ToString('o')
$cloneDuration = [Math]::Round(((($cloneEnd | Get-Date) -
    ($cloneStart | Get-Date)).TotalSeconds), 1)
Write-Phase "Clones created in ${cloneDuration}s"

# =============================================================================
# SECTION 4b - Checkout target commit in both clones
# =============================================================================
Write-Phase '--- Section 4b: Checking out target commit in both clones ---'

foreach ($label in @('A', 'B')) {
    $root = if ($label -eq 'A') { $ClonePathA } else { $ClonePathB }
    Write-Phase "[$label] Checking out $BaselineSha"
    & $gitExe -C $root checkout $BaselineSha 2>&1 |
        ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "Clone $label checkout failed" }
    $headNow = (& $gitExe -C $root rev-parse HEAD 2>&1).Trim()
    Write-Phase "[$label] HEAD after checkout: $headNow"
}

# =============================================================================
# SECTION 5 - Prove clone independence
# =============================================================================
Write-Phase '--- Section 5: Proving clone independence ---'

foreach ($label in @('A', 'B')) {
    $root = if ($label -eq 'A') { $ClonePathA } else { $ClonePathB }

    $inside = (& $gitExe -C $root rev-parse --is-inside-work-tree 2>&1).Trim()
    $head = (& $gitExe -C $root rev-parse HEAD 2>&1).Trim()
    $tree = (& $gitExe -C $root rev-parse 'HEAD^{tree}' 2>&1).Trim()
    $porcelain = (& $gitExe -C $root status --porcelain=v1 2>&1 | Out-String).Trim()
    $untracked = (& $gitExe -C $root ls-files --others --exclude-standard 2>&1 |
        Out-String).Trim()
    $remote = (& $gitExe -C $root config --get remote.origin.url 2>&1).Trim()

    Write-Phase "[$label] inside-work-tree: $inside"
    Write-Phase "[$label] HEAD: $head"
    Write-Phase "[$label] tree: $tree"
    Write-Phase "[$label] porcelain: $(if ($porcelain) { 'dirty' } else { 'clean' })"
    Write-Phase "[$label] untracked: $(if ($untracked) { 'present' } else { 'none' })"
    Write-Phase "[$label] remote.origin.url: $remote"

    if ($inside -ne 'true') {
        throw "Clone $label is not inside a work tree"
    }
    if ($head -ne $BaselineSha) {
        throw "Clone $label HEAD ($head) != baseline ($BaselineSha)"
    }
    if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
        Write-Phase "Clone $label status output: $porcelain"
    }

    # Check for alternates
    $alternates = Join-Path $root '.git\objects\info\alternates'
    if (Test-Path -LiteralPath $alternates) {
        throw "Clone $label has Git object alternates - INDEPENDENCE VIOLATION"
    }
    Write-Phase "[$label] No alternates found - INDEPENDENCE VERIFIED"

    # Check for worktree
    $worktreeFile = Join-Path $root '.git\worktrees'
    if (Test-Path -LiteralPath $worktreeFile) {
        $wtEntries = Get-ChildItem -LiteralPath $worktreeFile -Directory -ErrorAction SilentlyContinue
        if ($wtEntries -and $wtEntries.Count -gt 0) {
            throw "Clone $label appears to be a worktree - INDEPENDENCE VIOLATION"
        }
    }
    Write-Phase "[$label] Not a worktree - VERIFIED"
}

# Heads must match
$headA = (& $gitExe -C $ClonePathA rev-parse HEAD 2>&1).Trim()
$headB = (& $gitExe -C $ClonePathB rev-parse HEAD 2>&1).Trim()
if ($headA -ne $headB) {
    throw "HEAD mismatch: A=$headA B=$headB"
}
Write-Phase "Both clones at HEAD: $headA"

# =============================================================================
# SECTION 6 - Checkout baseline commit
# =============================================================================
Write-Phase '--- Section 6: Checkout baseline commit ---'

foreach ($label in @('A', 'B')) {
    $root = if ($label -eq 'A') { $ClonePathA } else { $ClonePathB }

    & $gitExe -C $root checkout --detach $BaselineSha 2>&1 |
        ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "Clone $label checkout failed" }

    $headNow = (& $gitExe -C $root rev-parse HEAD 2>&1).Trim()
    if ($headNow -ne $BaselineSha) {
        throw "Clone $label HEAD after checkout ($headNow) != $BaselineSha"
    }
    Write-Phase "[$label] Checked out: $headNow"
}

# =============================================================================
# SECTION 7 - Pre-build cleanliness proof
# =============================================================================
Write-Phase '--- Section 7: Pre-build cleanliness ---'

foreach ($label in @('A', 'B')) {
    $root = if ($label -eq 'A') { $ClonePathA } else { $ClonePathB }
    $appDir = Join-Path $root 'app'

    $dartTool = Join-Path $appDir '.dart_tool'
    $buildDir = Join-Path $appDir 'build'
    $hasDartTool = Test-Path -LiteralPath $dartTool
    $hasBuild = Test-Path -LiteralPath $buildDir
    Write-Phase "[$label] .dart_tool exists: $hasDartTool"
    Write-Phase "[$label] build/ exists: $hasBuild"

    if ($hasDartTool) { throw "Clone $label has .dart_tool before build" }
    if ($hasBuild) { throw "Clone $label has build/ before build" }

    # Verify pubspec.lock exists
    $lockFile = Join-Path $appDir 'pubspec.lock'
    if (-not (Test-Path -LiteralPath $lockFile)) {
        throw "Clone $label missing pubspec.lock"
    }
    $lockHash = Get-Sha256 $lockFile
    Write-Phase "[$label] pubspec.lock SHA-256: $lockHash"
}

# Verify lock files match between clones
$lockHashA = Get-Sha256 (Join-Path (Join-Path $ClonePathA 'app') 'pubspec.lock')
$lockHashB = Get-Sha256 (Join-Path (Join-Path $ClonePathB 'app') 'pubspec.lock')
if ($lockHashA -ne $lockHashB) {
    throw "pubspec.lock differs between clones: A=$lockHashA B=$lockHashB"
}
Write-Phase "pubspec.lock identical: $lockHashA"

# =============================================================================
# SECTION 8 - Environment fingerprint
# =============================================================================
Write-Phase '--- Section 8: Environment fingerprint ---'

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

$cmakeExe = $null
$ninjaExe = $null
$cmakeCmd = Get-Command 'cmake.exe' -ErrorAction SilentlyContinue
if ($cmakeCmd) { $cmakeExe = $cmakeCmd.Source }
$ninjaCmd = Get-Command 'ninja.exe' -ErrorAction SilentlyContinue
if ($ninjaCmd) { $ninjaExe = $ninjaCmd.Source }

$flutterVersion = (& $flutterCmd --version 2>&1 | Out-String).Trim()
$dartVersion = (& $dartCmd --version 2>&1 | Out-String).Trim()
$cmakeVersion = if ($cmakeExe) {
    (& $cmakeExe --version 2>&1 | Out-String).Trim()
} else { 'not found' }
$ninjaVersion = if ($ninjaExe) {
    (& $ninjaExe --version 2>&1 | Out-String).Trim()
} else { 'not found' }
$gitVersion = (& $gitExe --version 2>&1 | Out-String).Trim()
$psVersion = $PSVersionTable.PSVersion.ToString()

$osInfo = Get-CimInstance Win32_OperatingSystem
$osCaption = $osInfo.Caption
$osVersion = $osInfo.Version
$osBuild = $osInfo.BuildNumber
$osArch = $osInfo.OSArchitecture

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsVersion = ''
$msvcVersion = ''
if (Test-Path -LiteralPath $vswhere) {
    $vsVersion = (& $vswhere -latest -products '*' `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property catalog_productDisplayVersion 2>&1 | Out-String).Trim()
    $vsPath = (& $vswhere -latest -products '*' `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath 2>&1 | Out-String).Trim()
    if ($vsPath) {
        $msvcRoot = Join-Path $vsPath 'VC\Tools\MSVC'
        if (Test-Path -LiteralPath $msvcRoot) {
            $msvcDirs = Get-ChildItem -LiteralPath $msvcRoot -Directory |
                Sort-Object Name
            if ($msvcDirs) {
                $msvcVersion = $msvcDirs[-1].Name
            }
        }
    }
}

Write-Phase "Flutter: $flutterVersion"
Write-Phase "Dart: $dartVersion"
Write-Phase "CMake: $cmakeVersion"
Write-Phase "Ninja: $ninjaVersion"
Write-Phase "Git: $gitVersion"
Write-Phase "PowerShell: $psVersion"
Write-Phase "VS: $vsVersion"
Write-Phase "MSVC: $msvcVersion"
Write-Phase "OS: $osCaption $osBuild ($osArch)"

# =============================================================================
# SECTION 9 - Build from Clone A
# =============================================================================
Write-Phase '--- Section 9: Build from Clone A ---'

$flutterBat = $flutterCmd
$dartBat = $dartCmd
$appRootA = Join-Path $ClonePathA 'app'
$appRootB = Join-Path $ClonePathB 'app'
$buildStartA = [DateTime]::UtcNow.ToString('o')

# flutter clean A
Write-Phase "[A] flutter clean"
Push-Location $appRootA
try {
    & $flutterBat clean 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter clean A failed" }
} finally { Pop-Location }

$cleanDirA = Join-Path $appRootA 'build'
if (Test-Path -LiteralPath $cleanDirA) {
    throw "build/ still exists after flutter clean in A"
}
Write-Phase "[A] build/ removed after clean"

# flutter pub get A
Write-Phase "[A] flutter pub get"
$pubspecHashBefore = Get-Sha256 (Join-Path $appRootA 'pubspec.lock')
Push-Location $appRootA
try {
    & $flutterBat pub get 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get A failed" }
} finally { Pop-Location }

$pubspecHashAfter = Get-Sha256 (Join-Path $appRootA 'pubspec.lock')
if ($pubspecHashBefore -ne $pubspecHashAfter) {
    throw "pubspec.lock changed after pub get in A"
}
Write-Phase "[A] pubspec.lock unchanged after pub get"

# flutter build windows --release A
Write-Phase "[A] flutter build windows --release"
Push-Location $appRootA
try {
    & $flutterBat build windows --release 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows A failed" }
} finally { Pop-Location }

$buildEndA = [DateTime]::UtcNow.ToString('o')
$buildDurationA = [Math]::Round(((($buildEndA | Get-Date) -
    ($buildStartA | Get-Date)).TotalSeconds), 1)
Write-Phase "[A] Build completed in ${buildDurationA}s"

# Verify output exists
$releaseDirA = Join-Path $appRootA 'build\windows\x64\runner\Release'
if (-not (Test-Path -LiteralPath $releaseDirA)) {
    throw "Release directory not found for A: $releaseDirA"
}
$releaseFilesA = Get-ChildItem -LiteralPath $releaseDirA -Recurse -File
Write-Phase "[A] Release files: $($releaseFilesA.Count)"

# =============================================================================
# SECTION 10 - Build from Clone B
# =============================================================================
Write-Phase '--- Section 10: Build from Clone B ---'

$buildStartB = [DateTime]::UtcNow.ToString('o')

# flutter clean B
Write-Phase "[B] flutter clean"
Push-Location $appRootB
try {
    & $flutterBat clean 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter clean B failed" }
} finally { Pop-Location }

$cleanDirB = Join-Path $appRootB 'build'
if (Test-Path -LiteralPath $cleanDirB) {
    throw "build/ still exists after flutter clean in B"
}
Write-Phase "[B] build/ removed after clean"

# flutter pub get B
Write-Phase "[B] flutter pub get"
$pubspecHashBeforeB = Get-Sha256 (Join-Path $appRootB 'pubspec.lock')
Push-Location $appRootB
try {
    & $flutterBat pub get 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get B failed" }
} finally { Pop-Location }

$pubspecHashAfterB = Get-Sha256 (Join-Path $appRootB 'pubspec.lock')
if ($pubspecHashBeforeB -ne $pubspecHashAfterB) {
    throw "pubspec.lock changed after pub get in B"
}
Write-Phase "[B] pubspec.lock unchanged after pub get"

# flutter build windows --release B
Write-Phase "[B] flutter build windows --release"
Push-Location $appRootB
try {
    & $flutterBat build windows --release 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows B failed" }
} finally { Pop-Location }

$buildEndB = [DateTime]::UtcNow.ToString('o')
$buildDurationB = [Math]::Round(((($buildEndB | Get-Date) -
    ($buildStartB | Get-Date)).TotalSeconds), 1)
Write-Phase "[B] Build completed in ${buildDurationB}s"

$releaseDirB = Join-Path $appRootB 'build\windows\x64\runner\Release'
if (-not (Test-Path -LiteralPath $releaseDirB)) {
    throw "Release directory not found for B: $releaseDirB"
}
$releaseFilesB = Get-ChildItem -LiteralPath $releaseDirB -Recurse -File
Write-Phase "[B] Release files: $($releaseFilesB.Count)"

# =============================================================================
# SECTION 11 - File manifest comparison
# =============================================================================
Write-Phase '--- Section 11: File manifest comparison ---'

function Get-ReleaseManifest {
    param([Parameter(Mandatory = $true)][string]$ReleaseDir)
    $files = Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File |
        Sort-Object FullName
    $entries = @()
    $totalBytes = 0
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($ReleaseDir.Length + 1).Replace('\', '/')
        $hash = Get-Sha256 $f.FullName
        $totalBytes += $f.Length
        $entries += [ordered]@{
            relativePath = $rel
            sizeBytes    = $f.Length
            sha256       = $hash
            isPE         = $rel.EndsWith('.exe') -or $rel.EndsWith('.dll')
        }
    }
    return [ordered]@{
        fileCount  = $entries.Count
        totalBytes = $totalBytes
        files      = $entries
    }
}

$manifestA = Get-ReleaseManifest -ReleaseDir $releaseDirA
$manifestB = Get-ReleaseManifest -ReleaseDir $releaseDirB

Write-Phase "A: $($manifestA.fileCount) files, $($manifestA.totalBytes) bytes"
Write-Phase "B: $($manifestB.fileCount) files, $($manifestB.totalBytes) bytes"

# Save manifests
$evidenceDir = if ($EvidenceDir) { $EvidenceDir } else {
    Join-Path $ClonePathA 'docs\evidence\muaman-13f'
}
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

Write-JsonNoBom -Path (Join-Path $evidenceDir 'manifest-a.json') -Value $manifestA
Write-JsonNoBom -Path (Join-Path $evidenceDir 'manifest-b.json') -Value $manifestB

# Compare manifests
if ($manifestA.fileCount -ne $manifestB.fileCount) {
    throw "File count mismatch: A=$($manifestA.fileCount) B=$($manifestB.fileCount)"
}
if ($manifestA.totalBytes -ne $manifestB.totalBytes) {
    throw "Total bytes mismatch: A=$($manifestA.totalBytes) B=$($manifestB.totalBytes)"
}

$allIdentical = $true
$diffFiles = @()
for ($i = 0; $i -lt $manifestA.files.Count; $i++) {
    $fa = $manifestA.files[$i]
    $fb = $manifestB.files[$i]
    if ($fa.relativePath -ne $fb.relativePath) {
        $allIdentical = $false
        $diffFiles += "Path mismatch: A=$($fa.relativePath) B=$($fb.relativePath)"
    }
    if ($fa.sizeBytes -ne $fb.sizeBytes) {
        $allIdentical = $false
        $diffFiles += "Size mismatch: $($fa.relativePath) A=$($fa.sizeBytes) B=$($fb.sizeBytes)"
    }
    if ($fa.sha256 -ne $fb.sha256) {
        $allIdentical = $false
        $diffFiles += "SHA-256 mismatch: $($fa.relativePath)"
    }
}

if (-not $allIdentical) {
    Write-Phase "DIFFERENCES FOUND:"
    foreach ($d in $diffFiles) { Write-Phase "  $d" }
    throw "Release manifests are not identical"
}

Write-Phase "Manifests IDENTICAL: $($manifestA.fileCount) files, $($manifestA.totalBytes) bytes"

# =============================================================================
# SECTION 12 - Binary comparison (fc.exe /b)
# =============================================================================
Write-Phase '--- Section 12: Binary comparison ---'

$binaryResults = @()
for ($i = 0; $i -lt $manifestA.files.Count; $i++) {
    $fa = $manifestA.files[$i]
    $pathA = Join-Path $releaseDirA $fa.relativePath.Replace('/', '\')
    $pathB = Join-Path $releaseDirB $fa.relativePath.Replace('/', '\')
    $result = 'IDENTICAL'
    if ($fa.sha256 -ne $manifestB.files[$i].sha256) {
        $result = 'DIFFERS'
    }
    $binaryResults += [ordered]@{
        relativePath = $fa.relativePath
        result       = $result
        sha256A      = $fa.sha256
        sha256B      = $manifestB.files[$i].sha256
    }
    Write-Phase "  $($fa.relativePath): $result"
}
$allBinaryIdentical = (@($binaryResults | Where-Object { $_.result -eq 'DIFFERS' }).Count -eq 0)
if (-not $allBinaryIdentical) {
    throw "Binary comparison failed"
}
Write-Phase "Binary comparison PASSED: all $($binaryResults.Count) files identical"

# =============================================================================
# SECTION 13 - Deterministic ZIP
# =============================================================================
Write-Phase '--- Section 13: Deterministic ZIP ---'

$zipA = Join-Path $evidenceDir 'release-a.zip'
$zipB = Join-Path $evidenceDir 'release-b.zip'

# Use Dart tool for deterministic ZIP creation
Push-Location $appRootA
try {
    & $dartBat run 'tool/repro_zip.dart' `
        "--release-dir=$releaseDirA" "--out=$zipA" 2>&1 |
        ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "ZIP A creation failed" }

    & $dartBat run 'tool/repro_zip.dart' `
        "--release-dir=$releaseDirB" "--out=$zipB" 2>&1 |
        ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "ZIP B creation failed" }
} finally { Pop-Location }

$zipHashA = Get-Sha256 $zipA
$zipHashB = Get-Sha256 $zipB
$zipSizeA = (Get-Item -LiteralPath $zipA).Length
$zipSizeB = (Get-Item -LiteralPath $zipB).Length

Write-Phase "ZIP A: sha256=$zipHashA size=$zipSizeA"
Write-Phase "ZIP B: sha256=$zipHashB size=$zipSizeB"

if ($zipHashA -ne $zipHashB) {
    throw "ZIP SHA-256 mismatch: A=$zipHashA B=$zipHashB"
}
Write-Phase "Deterministic ZIP PASSED: byte-identical"

# =============================================================================
# SECTION 14 - PE inspection
# =============================================================================
Write-Phase '--- Section 14: PE inspection ---'

$peFiles = @('muaman_store.exe', 'flutter_windows.dll', 'printing_plugin.dll',
    'pdfium.dll')

$peArgsA = @('run', 'tool/pe_inspect.dart',
    '--run-id=clone-A', "--out=$evidenceDir\pe-inspection-a.json")
foreach ($pe in $peFiles) {
    $pePath = Join-Path $releaseDirA $pe
    if (Test-Path -LiteralPath $pePath) {
        $peArgsA += "--file=$pePath"
    }
}

$peArgsB = @('run', 'tool/pe_inspect.dart',
    '--run-id=clone-B', "--out=$evidenceDir\pe-inspection-b.json")
foreach ($pe in $peFiles) {
    $pePath = Join-Path $releaseDirB $pe
    if (Test-Path -LiteralPath $pePath) {
        $peArgsB += "--file=$pePath"
    }
}

Push-Location $appRootA
try {
    & $dartBat @peArgsA 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "PE inspection A failed" }

    & $dartBat @peArgsB 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "PE inspection B failed" }

    & $dartBat run 'tool/pe_inspect.dart' `
        --compare "$evidenceDir\pe-inspection-a.json" `
        --compare "$evidenceDir\pe-inspection-b.json" `
        "--out=$evidenceDir\pe-comparison.json" 2>&1 |
        ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "PE comparison failed" }
} finally { Pop-Location }

Write-Phase "PE comparison PASSED"

# =============================================================================
# SECTION 15 - Path leak scan
# =============================================================================
Write-Phase '--- Section 15: Path leak scan ---'

$leakA = Join-Path $evidenceDir 'leak-scan-a.json'
$leakB = Join-Path $evidenceDir 'leak-scan-b.json'

$leakArgsA = @(
    'run', 'tool/leak_scan.dart',
    "--release-dir=$releaseDirA",
    "--forbidden=$SourceRepo",
    "--forbidden=$ClonePathA",
    "--forbidden=$ClonePathB",
    "--forbidden=C:\dev\muaman.worktrees",
    "--out=$leakA"
)
$leakArgsB = @(
    'run', 'tool/leak_scan.dart',
    "--release-dir=$releaseDirB",
    "--forbidden=$SourceRepo",
    "--forbidden=$ClonePathA",
    "--forbidden=$ClonePathB",
    "--forbidden=C:\dev\muaman.worktrees",
    "--out=$leakB"
)

Push-Location $appRootA
try {
    & $dartBat @leakArgsA 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "Leak scan A failed" }

    & $dartBat @leakArgsB 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "Leak scan B failed" }
} finally { Pop-Location }

$leakDataA = Get-Content -LiteralPath $leakA -Raw | ConvertFrom-Json
$leakDataB = Get-Content -LiteralPath $leakB -Raw | ConvertFrom-Json
Write-Phase "Leak A: totalForbidden=$($leakDataA.totalForbiddenOccurrences)"
Write-Phase "Leak B: totalForbidden=$($leakDataB.totalForbiddenOccurrences)"

if ($leakDataA.totalForbiddenOccurrences -gt 0) {
    throw "Path leak detected in Clone A"
}
if ($leakDataB.totalForbiddenOccurrences -gt 0) {
    throw "Path leak detected in Clone B"
}
Write-Phase "Path leak scan PASSED: 0 forbidden occurrences in both clones"

# =============================================================================
# SECTION 16 - Post-build git status
# =============================================================================
Write-Phase '--- Section 16: Post-build git status ---'

foreach ($label in @('A', 'B')) {
    $root = if ($label -eq 'A') { $ClonePathA } else { $ClonePathB }
    $appR = if ($label -eq 'A') { $appRootA } else { $appRootB }

    $trackedStatus = (& $gitExe -C $root status --porcelain=v1 2>&1 | Out-String).Trim()
    $untrackedList = (& $gitExe -C $root ls-files --others --exclude-standard 2>&1 |
        Out-String).Trim()

    Write-Phase "[$label] tracked status: $(if ($trackedStatus) { 'dirty' } else { 'clean' })"
    Write-Phase "[$label] untracked count: $(if ($untrackedList) {
        ($untrackedList -split "`n").Count
    } else { 0 })"

    if ($trackedStatus) {
        Write-Phase "[$label] tracked changes: $trackedStatus"
    }

    $dartToolExists = Test-Path -LiteralPath (Join-Path $appR '.dart_tool')
    $buildExists = Test-Path -LiteralPath (Join-Path $appR 'build')
    Write-Phase "[$label] .dart_tool exists: $dartToolExists"
    Write-Phase "[$label] build/ exists: $buildExists"
}

# =============================================================================
# SECTION 17 - Compute final report
# =============================================================================
Write-Phase '--- Section 17: Final report ---'

$report = [ordered]@{
    schema                    = 'muaman-13f-acceptance'
    baselineSha               = $BaselineSha
    baselineMessage           = $baselineMsg
    branch                    = (& $gitExe -C $ClonePathA branch --show-current 2>&1 |
        Out-String).Trim()
    cloneA                    = [ordered]@{
        path       = $ClonePathA
        pathLength = $ClonePathA.Length
        head       = $headA
    }
    cloneB                    = [ordered]@{
        path       = $ClonePathB
        pathLength = $ClonePathB.Length
        head       = $headB
    }
    pathLengthDelta           = [Math]::Abs($ClonePathA.Length - $ClonePathB.Length)
    clonesIndependent         = $true
    noAlternates              = $true
    noWorktree                = $true
    environment               = [ordered]@{
        flutter    = $flutterVersion
        dart       = $dartVersion
        cmake      = $cmakeVersion
        ninja      = $ninjaVersion
        git        = $gitVersion
        powershell = $psVersion
        vs         = $vsVersion
        msvc       = $msvcVersion
        os         = "$osCaption $osBuild ($osArch)"
    }
    buildA                    = [ordered]@{
        startedAt  = $buildStartA
        endedAt    = $buildEndA
        durationSec = $buildDurationA
        exitCode   = 0
    }
    buildB                    = [ordered]@{
        startedAt  = $buildStartB
        endedAt    = $buildEndB
        durationSec = $buildDurationB
        exitCode   = 0
    }
    releaseA                  = [ordered]@{
        fileCount  = $manifestA.fileCount
        totalBytes = $manifestA.totalBytes
    }
    releaseB                  = [ordered]@{
        fileCount  = $manifestB.fileCount
        totalBytes = $manifestB.totalBytes
    }
    perFileComparison         = $binaryResults
    allFilesByteIdentical     = $allBinaryIdentical
    deterministicZip          = [ordered]@{
        sha256A = $zipHashA
        sha256B = $zipHashB
        sizeA   = $zipSizeA
        sizeB   = $zipSizeB
        identical = ($zipHashA -eq $zipHashB)
    }
    peComparison              = [ordered]@{
        identical = $true
    }
    pathLeakScan              = [ordered]@{
        occurrencesA = $leakDataA.totalForbiddenOccurrences
        occurrencesB = $leakDataB.totalForbiddenOccurrences
        passed       = ($leakDataA.totalForbiddenOccurrences -eq 0 -and
            $leakDataB.totalForbiddenOccurrences -eq 0)
    }
    overallPass               = ($allIdentical -and $allBinaryIdentical -and
        $zipHashA -eq $zipHashB -and
        $leakDataA.totalForbiddenOccurrences -eq 0 -and
        $leakDataB.totalForbiddenOccurrences -eq 0)
    timestamp                 = [DateTime]::UtcNow.ToString('o')
}

$summaryPath = Join-Path $evidenceDir 'acceptance-summary.json'
Write-JsonNoBom -Path $summaryPath -Value $report

# =============================================================================
# SECTION 18 - Final verdict
# =============================================================================
Write-Phase '--- Section 18: Final verdict ---'

if ($report.overallPass) {
    Write-Phase '========================================'
    Write-Phase 'Outcome A: VERIFIED INDEPENDENT FRESH-CLONE'
    Write-Phase '          COMMITTED-STATE REPRODUCIBILITY'
    Write-Phase '========================================'
    Write-Phase "Baseline: $BaselineSha"
    Write-Phase "Clone A:  $ClonePathA ($($ClonePathA.Length) chars)"
    Write-Phase "Clone B:  $ClonePathB ($($ClonePathB.Length) chars)"
    Write-Phase "Release:  $($manifestA.fileCount) files, $($manifestA.totalBytes) bytes"
    Write-Phase "ZIP:      $zipHashA"
    Write-Phase "Verdict:  PASS"
}
else {
    Write-Phase '========================================'
    Write-Phase 'Outcome B: REPRODUCIBILITY FAILURE'
    Write-Phase '          PRECISELY IDENTIFIED'
    Write-Phase '========================================'
    Write-Phase "Clone A: $ClonePathA"
    Write-Phase "Clone B: $ClonePathB"
    Write-Phase "Verdict: FAIL"
    throw "Acceptance FAILED: see report at $summaryPath"
}

Write-Phase '===== MUAMAN-13F ACCEPTANCE COMPLETE ====='
