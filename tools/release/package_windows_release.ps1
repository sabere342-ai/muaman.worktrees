# MUAMAN-13M canonical deterministic Windows release packaging entrypoint.
#
# THE SINGLE OFFICIAL COMMAND for packaging a verified MUAMAN Windows Release
# into a deterministic, portable, operator-ready ZIP.
#
# This script is a THIN OPERATIONAL INTERFACE ONLY. It:
#   1. REUSES the canonical release verifier (tools/release/verify_release.ps1)
#      against the committed MUAMAN-13K legal release manifest;
#   2. fails closed when release verification fails (no ZIP is produced);
#   3. never modifies the verified release directory (read-only input);
#   4. never duplicates build logic, verification logic, or legal-manifest
#      logic -- the legality of the release is decided entirely by
#      verify_release.ps1 and the committed legal manifest;
#   5. produces a byte-deterministic ZIP (stable ordinal entry order, forward
#      slash archive-relative entry paths, no absolute/parent/duplicate
#      entries, no random GUIDs, no current timestamps, no archive comment,
#      constant documented DOS entry timestamp, no filesystem-order
#      dependence);
#   6. writes machine-readable outputs (package-manifest.json,
#      package-result.json, muaman-windows-release.zip.sha256);
#   7. resolves every path from explicit parameters or its own script
#      location -- never from the caller's current working directory;
#   8. is callable from any working directory (repository root, application
#      directory, or an unrelated external directory).
#
# The distributable ZIP contains ONLY the verified canonical release files.
# No reports, evidence, manifests, checksums, source files, Git metadata,
# tools, logs, or packaging scripts are placed inside the ZIP.
#
# ZIP entry timestamp policy: every entry uses the CONSTANT local wall-clock
# value 2024-01-01T00:00:00 (DOS date/time 0x5821_0000), applied to the ZIP
# metadata only. The release file bytes themselves are never modified,
# patched, touched, rewritten, or normalized.
#
# Exit codes:
#   0  success (deterministic ZIP + checksum + manifests produced)
#   1  release verification failed (fail-closed; no ZIP created)
#   2  parameter / input / path validation failure
#   3  packaging failure (archive creation or finalization failed)
#   4  unexpected error
#
# Usage (canonical command, from any working directory):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     <repo>\tools\release\package_windows_release.ps1 `
#     -RepoRoot <repo> `
#     -ReleaseDir <verified-release-dir> `
#     -OutputDir <package-output-dir> `
#     -EvidenceDir <evidence-output-dir>
#
# Optional switches:
#   -LegalManifest <json>  committed legal release manifest (default:
#                          docs/evidence/muaman-13k/04-k1-source-a-sdk-a-shorttemp/release-manifest.json)
#   -Verifier <script>     canonical verifier (default: tools/release/verify_release.ps1)
#   -ZipName <name>        distributable ZIP file name (default: muaman-windows-release.zip)
#   -ConstantZipTimestamp <yyyy-MM-ddTHH:mm:ss>  constant ZIP entry timestamp
#                          (default: 2024-01-01T00:00:00)

param(
  [string]$RepoRoot = '',
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [string]$LegalManifest = '',
  [string]$Verifier = '',
  [string]$ZipName = 'muaman-windows-release.zip',
  [string]$ConstantZipTimestamp = '2024-01-01T00:00:00'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ("[MUAMAN-13M] {0}" -f $message)
}

function Get-Sha256([string]$path) {
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

function Test-IsUnder([string]$inner, [string]$outer) {
  $o = $outer.TrimEnd('\')
  $i = $inner.TrimEnd('\')
  if ($i -eq $o) { return $true }
  return $i.StartsWith($o + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Write-PackageResult([hashtable]$data) {
  $json = $data | ConvertTo-Json -Depth 8
  foreach ($dir in @($OutputDir, $EvidenceDir)) {
    try {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
      Set-Content -LiteralPath (Join-Path $dir 'package-result.json') -Value $json -Encoding UTF8
    } catch { }
  }
}

# ---------------------------------------------------------------------------
# stage tracking (drives the exit code and the failure result)
# ---------------------------------------------------------------------------
$stage = 'validate'
$startUtc = [DateTime]::UtcNow
$tempZipPath = ''
$finalZipPath = ''

try {

# ---------------------------------------------------------------------------
# 1. repository root (from script location, never from the current directory)
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $scriptDir = $PSScriptRoot
  if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $RepoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

if ([string]::IsNullOrWhiteSpace($Verifier)) {
  $Verifier = Join-Path $RepoRoot 'tools\release\verify_release.ps1'
}
if ([string]::IsNullOrWhiteSpace($LegalManifest)) {
  $LegalManifest = Join-Path $RepoRoot 'docs\windows-delivery-refresh\evidence\legal\release-manifest.json'
}

foreach ($marker in @(
  (Join-Path $RepoRoot 'app\pubspec.yaml'),
  (Join-Path $RepoRoot 'tools\release\build_windows_release.ps1')
)) {
  if (-not (Test-Path -LiteralPath $marker)) {
    Write-Host ("[MUAMAN-13M] ERROR repository structure not found at {0}; missing {1}" -f $RepoRoot, $marker)
    exit 2
  }
}

# ---------------------------------------------------------------------------
# 2. resolve and validate every input path
# ---------------------------------------------------------------------------
$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
$Verifier = [System.IO.Path]::GetFullPath($Verifier)
$LegalManifest = [System.IO.Path]::GetFullPath($LegalManifest)

if (-not (Test-Path -LiteralPath $ReleaseDir -PathType Container)) {
  Write-Host ("[MUAMAN-13M] ERROR ReleaseDir does not exist: {0}" -f $ReleaseDir)
  exit 2
}
if (-not (Test-Path -LiteralPath $Verifier -PathType Leaf)) {
  Write-Host ("[MUAMAN-13M] ERROR canonical verifier missing: {0}" -f $Verifier)
  exit 2
}
if (-not (Test-Path -LiteralPath $LegalManifest -PathType Leaf)) {
  Write-Host ("[MUAMAN-13M] ERROR legal release manifest missing: {0}" -f $LegalManifest)
  exit 2
}
if ([string]::IsNullOrWhiteSpace($ZipName) -or $ZipName -match '[\\/]') {
  Write-Host '[MUAMAN-13M] ERROR ZipName must be a plain file name (no path separators)'
  exit 2
}
if ($ConstantZipTimestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$') {
  Write-Host '[MUAMAN-13M] ERROR ConstantZipTimestamp must match yyyy-MM-ddTHH:mm:ss'
  exit 2
}

if (Test-IsUnder $OutputDir $ReleaseDir) {
  Write-Host ('[MUAMAN-13M] ERROR OutputDir is inside the input release directory: {0}' -f $OutputDir)
  exit 2
}
if (Test-IsUnder $EvidenceDir $ReleaseDir) {
  Write-Host ('[MUAMAN-13M] ERROR EvidenceDir is inside the input release directory: {0}' -f $EvidenceDir)
  exit 2
}
if (Test-IsUnder $ReleaseDir $OutputDir) {
  Write-Host ('[MUAMAN-13M] ERROR the input release directory is inside OutputDir: {0}' -f $OutputDir)
  exit 2
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

# ---------------------------------------------------------------------------
# 3. immutable snapshot of the verified release tree (read-only enumeration)
# ---------------------------------------------------------------------------
$files = @(Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File)
if ($files.Count -eq 0) {
  Write-Host ('[MUAMAN-13M] ERROR release directory contains no files: {0}' -f $ReleaseDir)
  exit 2
}

$entries = @()
$totalBytes = [int64]0
$seen = @{}
foreach ($f in $files) {
  $rel = $f.FullName.Substring($ReleaseDir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
  if ([string]::IsNullOrWhiteSpace($rel) -or $rel.StartsWith('/') -or $rel.Contains('..')) {
    Write-Host ("[MUAMAN-13M] ERROR unsafe archive entry path derived from release tree: {0}" -f $rel)
    exit 2
  }
  if ($seen.ContainsKey($rel)) {
    Write-Host ("[MUAMAN-13M] ERROR duplicate archive entry path: {0}" -f $rel)
    exit 2
  }
  $seen[$rel] = $true
  $h = Get-Sha256 $f.FullName
  $entries += [pscustomobject][ordered]@{
    rel = $rel
    size = $f.Length
    sha256 = $h
    path = $f.FullName
  }
  $totalBytes += $f.Length
}

# stable ordinal entry ordering (no culture-sensitive / filesystem-order sorting)
$relNames = [string[]]@($entries | ForEach-Object { $_.rel })
$indices = [int[]]@(0..($entries.Count - 1))
[Array]::Sort($relNames, $indices, [System.StringComparer]::Ordinal)
$entries = @($indices | ForEach-Object { $entries[$_] })

# ---------------------------------------------------------------------------
# 4. canonical release verification (BEFORE any ZIP creation; fail closed)
# ---------------------------------------------------------------------------
$stage = 'verify'
$verifyOut = Join-Path $EvidenceDir 'release-verification.json'
Write-Step ("verifying release {0} against {1}" -f $ReleaseDir, $LegalManifest)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Verifier -ReleaseDir $ReleaseDir -LegalManifest $LegalManifest -Out $verifyOut
$verifyExit = $LASTEXITCODE
$verify = $null
if (Test-Path -LiteralPath $verifyOut) { $verify = Get-Content -LiteralPath $verifyOut -Raw | ConvertFrom-Json }
$verified = ($verifyExit -eq 0) -and ($null -ne $verify) -and ([bool]$verify.identical)

if (-not $verified) {
  $finish = [DateTime]::UtcNow
  Write-PackageResult @{
    schemaVersion = '1.0'
    run = [ordered]@{ startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); finishedAtUtc = $finish.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); exitCode = 1 }
    verification = [ordered]@{ verdict = 'FAIL'; verifierExitCode = $verifyExit; releaseDir = $ReleaseDir }
    packaging = [ordered]@{ verdict = 'NOT-RUN' }
    outputs = [ordered]@{ outputDir = $OutputDir; evidenceDir = $EvidenceDir }
    failureReason = ('release verification failed (verify_release.ps1 exit {0}); no ZIP created' -f $verifyExit)
  }
  Write-Host ("[MUAMAN-13M] RELEASE VERIFICATION FAILED (exit {0}); packaging refused. See {1}" -f $verifyExit, $verifyOut)
  exit 1
}
Write-Step ("release verification PASS (exit {0}); files={1} bytes={2} cross={3}" -f $verifyExit, $verify.fileCountNew, $verify.totalBytesNew, $verify.crossHashNew)

# ---------------------------------------------------------------------------
# 5. deterministic ZIP creation
# ---------------------------------------------------------------------------
$stage = 'package'
$constantLocal = [DateTime]::SpecifyKind(
  [DateTime]::ParseExact($ConstantZipTimestamp, 'yyyy-MM-ddTHH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture),
  [DateTimeKind]::Local)

$tempZipPath = Join-Path $OutputDir ($ZipName + '.partial.tmp')
if (Test-Path -LiteralPath $tempZipPath) { Remove-Item -LiteralPath $tempZipPath -Force }

Write-Step ("creating deterministic ZIP with {0} entries (constant entry timestamp {1})" -f $entries.Count, $ConstantZipTimestamp)

$fs = [System.IO.File]::Open($tempZipPath, [System.IO.FileMode]::Create)
try {
  $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $true)
  try {
    foreach ($e in $entries) {
      $entry = $zip.CreateEntry($e.rel, [System.IO.Compression.CompressionLevel]::Optimal)
      $entry.LastWriteTime = $constantLocal
      $inStream = [System.IO.File]::OpenRead($e.path)
      try {
        $outStream = $entry.Open()
        try { $inStream.CopyTo($outStream) } finally { $outStream.Dispose() }
      } finally { $inStream.Dispose() }
    }
  } finally { $zip.Dispose() }
} finally { $fs.Dispose() }

$zipHash = Get-Sha256 $tempZipPath
$zipSize = (Get-Item -LiteralPath $tempZipPath).Length
Write-Step ("ZIP created: {0} bytes, SHA-256 {1}" -f $zipSize, $zipHash)

# ---------------------------------------------------------------------------
# 6. atomic finalization (temp -> final name)
# ---------------------------------------------------------------------------
$finalZipPath = Join-Path $OutputDir $ZipName
if (Test-Path -LiteralPath $finalZipPath -PathType Leaf) { Remove-Item -LiteralPath $finalZipPath -Force }
[System.IO.File]::Move($tempZipPath, $finalZipPath)
$tempZipPath = ''
Write-Step ("ZIP finalized: {0}" -f $finalZipPath)

# ---------------------------------------------------------------------------
# 7. checksum output (sha256sum style: UPPER_HEX two-spaces file name)
# ---------------------------------------------------------------------------
$shaPath = Join-Path $OutputDir ($ZipName + '.sha256')
("{0}  {1}" -f $zipHash, $ZipName) | Set-Content -LiteralPath $shaPath -Encoding ASCII

# ---------------------------------------------------------------------------
# 8. package manifest (deterministic; describes the package, not the run)
# ---------------------------------------------------------------------------
$toolHash = Get-Sha256 $MyInvocation.MyCommand.Path
$manifestEntries = @($entries | ForEach-Object { [ordered]@{ rel = $_.rel; size = $_.size; sha256 = $_.sha256 } })

$releaseSuffix = ''
$releaseRepoRel = $null
if ($ReleaseDir.StartsWith($RepoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
  $releaseRepoRel = $ReleaseDir.Substring($RepoRoot.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
}
if ($ReleaseDir -match '(app[/\\]build[/\\]windows[/\\]x64[/\\]runner[/\\]Release)\s*$') {
  $releaseSuffix = $Matches[1].Replace('\', '/')
}

$manifest = [ordered]@{
  schemaVersion = '1.0'
  package = [ordered]@{
    filename = $ZipName
    byteLength = $zipSize
    sha256 = $zipHash
  }
  inputRelease = [ordered]@{
    releaseDir = $ReleaseDir
    releaseDirRepoRel = $releaseRepoRel
    releaseDirSuffix = $releaseSuffix
    fileCount = $entries.Count
    totalBytes = $totalBytes
    crossHash = [string]$verify.crossHashNew
    crossHashExpected = [string]$verify.crossHashExpected
    crossHashMatch = [bool]$verify.crossHashMatch
    releaseVerification = [ordered]@{
      tool = 'tools/release/verify_release.ps1'
      output = 'release-verification.json'
      verifierExitCode = $verifyExit
      identical = $true
    }
  }
  zip = [ordered]@{
    entryCount = $entries.Count
    constantEntryTimestampLocal = $ConstantZipTimestamp
    constantEntryTimestampDos = '0x58210000'
    entrySeparators = '/'
    archiveComment = ''
    absolutePaths = $false
    parentTraversalEntries = $false
    duplicateEntries = $false
  }
  entries = $manifestEntries
  packagingTool = [ordered]@{
    name = 'tools/release/package_windows_release.ps1'
    version = '1.0'
    sha256 = $toolHash
  }
  success = $true
}

$manifestJson = $manifest | ConvertTo-Json -Depth 8
Set-Content -LiteralPath (Join-Path $OutputDir 'package-manifest.json') -Value $manifestJson -Encoding UTF8
Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-manifest.json') -Value $manifestJson -Encoding UTF8

# ---------------------------------------------------------------------------
# 9. package result (run record)
# ---------------------------------------------------------------------------
$finishUtc = [DateTime]::UtcNow
$result = [ordered]@{
  schemaVersion = '1.0'
  run = [ordered]@{
    startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    finishedAtUtc = $finishUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    exitCode = 0
  }
  verification = [ordered]@{
    verdict = 'PASS'
    identical = $true
    verifierExitCode = $verifyExit
    fileCount = $entries.Count
    totalBytes = $totalBytes
    crossHash = [string]$verify.crossHashNew
  }
  packaging = [ordered]@{
    verdict = 'PASS'
    zipFilename = $ZipName
    zipSha256 = $zipHash
    zipSize = $zipSize
    entryCount = $entries.Count
    constantEntryTimestampLocal = $ConstantZipTimestamp
    constantEntryTimestampDos = '0x58210000'
  }
  outputs = [ordered]@{
    outputDir = $OutputDir
    evidenceDir = $EvidenceDir
    zipPath = $finalZipPath
    sha256Path = $shaPath
    packageManifestPath = Join-Path $OutputDir 'package-manifest.json'
    packageResultPath = Join-Path $OutputDir 'package-result.json'
    releaseVerificationPath = $verifyOut
  }
  failureReason = $null
}
$resultJson = $result | ConvertTo-Json -Depth 8
Set-Content -LiteralPath (Join-Path $OutputDir 'package-result.json') -Value $resultJson -Encoding UTF8
Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-result.json') -Value $resultJson -Encoding UTF8

# command record for audit traceability
$cmdLine = if (-not [string]::IsNullOrWhiteSpace($MyInvocation.Line)) { $MyInvocation.Line.Trim() } else { '' }
$commandRecord = @(
  'MUAMAN-13M canonical deterministic Windows release packaging command',
  '======================================================================',
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '"',
  '  -RepoRoot "' + $RepoRoot + '"',
  '  -ReleaseDir "' + $ReleaseDir + '"',
  '  -OutputDir "' + $OutputDir + '"',
  '  -EvidenceDir "' + $EvidenceDir + '"',
  'resolved verifier     : ' + $Verifier,
  'resolved legal manifest: ' + $LegalManifest,
  'zip name              : ' + $ZipName,
  'constant entry stamp  : ' + $ConstantZipTimestamp + ' (DOS 0x58210000)',
  ('captured command line : ' + $cmdLine)
) -join "`r`n"
Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-command.txt') -Value $commandRecord -Encoding UTF8

Write-Step ("RESULT: PASS (exit 0)")
Write-Step ("ZIP: {0} ({1} bytes)" -f $finalZipPath, $zipSize)
Write-Step ("SHA-256: {0}" -f $zipHash)
exit 0

} catch {
  $err = $_.Exception.Message
  if (-not [string]::IsNullOrWhiteSpace($tempZipPath) -and (Test-Path -LiteralPath $tempZipPath)) {
    Remove-Item -LiteralPath $tempZipPath -Force -ErrorAction SilentlyContinue
  }
  $finish = [DateTime]::UtcNow
  $code = switch ($stage) {
    'validate' { 2 }
    'verify' { 1 }
    'package' { 3 }
    default { 4 }
  }
  try {
    Write-PackageResult @{
      schemaVersion = '1.0'
      run = [ordered]@{ startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); finishedAtUtc = $finish.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); exitCode = $code }
      verification = [ordered]@{ verdict = if ($stage -eq 'verify') { 'FAIL' } else { 'PASS' } }
      packaging = [ordered]@{ verdict = if ($stage -eq 'package') { 'FAIL' } else { 'NOT-RUN' } }
      outputs = [ordered]@{ outputDir = $OutputDir; evidenceDir = $EvidenceDir }
      failureReason = $err
    }
  } catch { }
  Write-Host ("[MUAMAN-13M] PACKAGING FAILED (stage {0}, exit {1}): {2}" -f $stage, $code, $err)
  exit $code
}
