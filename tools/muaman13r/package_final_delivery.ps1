# MUAMAN-13R final governed Windows delivery packaging entrypoint.
#
# THE SINGLE OFFICIAL COMMAND for producing the governed end-user delivery
# package from a previously accepted (frozen) Windows installer.
#
# This phase is about DELIVERY CORRECTNESS ONLY. It:
#   1. NEVER builds an application or an installer. It consumes ONLY the
#      already-accepted installer bytes supplied as -CanonicalInstaller.
#   2. VERIFIES the canonical installer byte-identity (SHA-256 + size) against
#      the frozen, previously-accepted identity BEFORE any copy is made, and
#      fails closed (exit 2, no outputs) if the identity differs.
#   3. Copies the verified bytes to the delivery tree with a byte-preserving
#      copy (no transformation), verifies the copy again, then verifies the
#      final delivery tree (exactly three minimal files, checksum manifest
#      correct, README present and non-empty).
#   4. Produces a byte-deterministic ZIP (stable ordinal entry order, forward
#      slash archive-relative entry paths, no absolute/parent/duplicate
#      entries, no random GUIDs, no current timestamps, no archive comment,
#      constant documented DOS entry timestamp, no filesystem-order
#      dependence) exactly like the accepted MUAMAN-13M packaging convention.
#   5. Resolves every path from explicit parameters or its own script location,
#      never from the caller's current working directory, so it is callable
#      from any working directory.
#   6. Writes machine-readable outputs and evidence (installer-identity.txt,
#      delivery-tree.txt, package-result.json, ZIP checksum).
#
# The final ZIP contains ONLY the three minimal delivery files under a single
# package folder. No source code, no Git metadata, no evidence, no tests, no
# logs, no packaging scripts, no installer sources are placed inside the ZIP.
#
# ZIP entry timestamp policy: every entry uses the CONSTANT local wall-clock
# value 2024-01-01T00:00:00 (DOS date/time 0x5821_0000), applied to the ZIP
# metadata only. The packaged file bytes are never modified.
#
# Exit codes:
#   0  success (delivery tree + deterministic ZIP + checksum + manifests)
#   2  parameter / path validation failure OR canonical installer identity
#      mismatch (fail-closed; nothing is produced)
#   3  packaging failure (tree/ZIP creation or finalization failed)
#   4  unexpected error
#
# Usage (canonical command, from any working directory):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     <repo>\tools\muaman13r\package_final_delivery.ps1 `
#     -CanonicalInstaller <path-to-accepted-installer.exe> `
#     [-OutputRoot <delivery-output-root>] `
#     [-EvidenceDir <evidence-output-dir>] `
#     [-RunTag <run-tag>]

param(
  [string]$RepoRoot = '',
  [Parameter(Mandatory=$true)][string]$CanonicalInstaller,
  [string]$OutputRoot = '',
  [string]$EvidenceDir = '',
  [string]$RunTag = '',
  [string]$PackageDirName = 'Muaman-1.0.0-Windows',
  [string]$SetupExeName = 'I-TECH-Setup.exe',
  [string]$ZipName = 'Muaman-1.0.0-Windows.zip',
  [string]$ConstantZipTimestamp = '2024-01-01T00:00:00'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

# ---------------------------------------------------------------------------
# frozen, previously accepted installer identity (governing)
# ---------------------------------------------------------------------------
$ExpectedInstallerSha256 = '94BD1559CFE01281714D7EB137E931FAC75DE44C115EE5FBD27B00A772C8A831'
$ExpectedInstallerSize = [int64]13223003
$ExpectedZipEntryCount = 3

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ("[MUAMAN-13R] {0}" -f $message)
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
  foreach ($dir in @($OutputRoot, $EvidenceDir)) {
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
$deliveryPackageDir = ''

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

foreach ($marker in @(
  (Join-Path $RepoRoot 'app\pubspec.yaml'),
  (Join-Path $RepoRoot 'tools\muaman13r\package_final_delivery.ps1')
)) {
  if (-not (Test-Path -LiteralPath $marker)) {
    Write-Host ("[MUAMAN-13R] ERROR repository structure not found at {0}; missing {1}" -f $RepoRoot, $marker)
    exit 2
  }
}

# ---------------------------------------------------------------------------
# 2. resolve and validate every input path
# ---------------------------------------------------------------------------
$CanonicalInstaller = [System.IO.Path]::GetFullPath($CanonicalInstaller)
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $RepoRoot 'delivery' }
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
if ([string]::IsNullOrWhiteSpace($EvidenceDir)) {
  $EvidenceDir = Join-Path $RepoRoot ('docs\muaman-13r\evidence\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)

if (-not (Test-Path -LiteralPath $CanonicalInstaller -PathType Leaf)) {
  Write-Host ("[MUAMAN-13R] ERROR canonical installer file not found: {0}" -f $CanonicalInstaller)
  exit 2
}
if ([string]::IsNullOrWhiteSpace($PackageDirName) -or $PackageDirName -match '[\\/]') {
  Write-Host '[MUAMAN-13R] ERROR PackageDirName must be a plain folder name (no path separators)'
  exit 2
}
if ([string]::IsNullOrWhiteSpace($SetupExeName) -or $SetupExeName -match '[\\/]') {
  Write-Host '[MUAMAN-13R] ERROR SetupExeName must be a plain file name (no path separators)'
  exit 2
}
if ([string]::IsNullOrWhiteSpace($ZipName) -or $ZipName -match '[\\/]') {
  Write-Host '[MUAMAN-13R] ERROR ZipName must be a plain file name (no path separators)'
  exit 2
}
if ($ConstantZipTimestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$') {
  Write-Host '[MUAMAN-13R] ERROR ConstantZipTimestamp must match yyyy-MM-ddTHH:mm:ss'
  exit 2
}

# the canonical installer must not be inside the output tree we are about to fill
if (Test-IsUnder $CanonicalInstaller $OutputRoot) {
  Write-Host ('[MUAMAN-13R] ERROR canonical installer is inside the output root: {0}' -f $CanonicalInstaller)
  exit 2
}
if (Test-IsUnder $EvidenceDir $OutputRoot) {
  Write-Host ('[MUAMAN-13R] ERROR EvidenceDir is inside the output root: {0}' -f $EvidenceDir)
  exit 2
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

$deliveryPackageDir = Join-Path $OutputRoot $PackageDirName

# ---------------------------------------------------------------------------
# 3. canonical installer byte-identity verification (fail closed)
# ---------------------------------------------------------------------------
$stage = 'verify-installer'
Write-Step ("verifying canonical installer identity: {0}" -f $CanonicalInstaller)
$canonicalHash = Get-Sha256 $CanonicalInstaller
$canonicalSize = (Get-Item -LiteralPath $CanonicalInstaller).Length
$identityOk = ($canonicalHash -eq $ExpectedInstallerSha256) -and ($canonicalSize -eq $ExpectedInstallerSize)

if (-not $identityOk) {
  $finish = [DateTime]::UtcNow
  Write-PackageResult @{
    schemaVersion = '1.0'
    run = [ordered]@{ startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); finishedAtUtc = $finish.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); exitCode = 2; runTag = $RunTag }
    installerIdentity = [ordered]@{
      verdict = 'FAIL'
      canonicalInstaller = $CanonicalInstaller
      sha256 = $canonicalHash
      sizeBytes = $canonicalSize
      expectedSha256 = $ExpectedInstallerSha256
      expectedSizeBytes = $ExpectedInstallerSize
      sha256Match = ($canonicalHash -eq $ExpectedInstallerSha256)
      sizeMatch = ($canonicalSize -eq $ExpectedInstallerSize)
    }
    delivery = [ordered]@{ verdict = 'NOT-RUN' }
    packaging = [ordered]@{ verdict = 'NOT-RUN' }
    failureReason = 'canonical installer identity mismatch (SHA-256 or size); delivery refused'
  }
  Write-Host ("[MUAMAN-13R] CANONICAL INSTALLER IDENTITY MISMATCH sha={0} size={1} expected={2}/{3}" -f $canonicalHash, $canonicalSize, $ExpectedInstallerSha256, $ExpectedInstallerSize)
  Write-Host '[MUAMAN-13R] delivery refused; nothing was produced.'
  exit 2
}
Write-Step ("canonical installer identity PASS sha={0} size={1}" -f $canonicalHash, $canonicalSize)

# ---------------------------------------------------------------------------
# 4. build the minimal delivery tree (byte-preserving copy only)
# ---------------------------------------------------------------------------
$stage = 'delivery'
if (Test-Path -LiteralPath $deliveryPackageDir -PathType Container) {
  Remove-Item -LiteralPath $deliveryPackageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deliveryPackageDir -Force | Out-Null

$setupPath = Join-Path $deliveryPackageDir $SetupExeName
$readmePath = Join-Path $deliveryPackageDir 'README.txt'
$checksumPath = Join-Path $deliveryPackageDir 'SHA256SUMS.txt'
$readmeTemplate = Join-Path $RepoRoot 'tools\muaman13r\README.txt'

if (-not (Test-Path -LiteralPath $readmeTemplate -PathType Leaf)) {
  Write-Host ('[MUAMAN-13R] ERROR committed README template missing: {0}' -f $readmeTemplate)
  exit 3
}

# byte-preserving copy: no transformation of any kind
[System.IO.File]::Copy($CanonicalInstaller, $setupPath, $true)
[System.IO.File]::Copy($readmeTemplate, $readmePath, $true)

# verify the copied installer is byte-identical before writing the manifest
$copyHash = Get-Sha256 $setupPath
$copySize = (Get-Item -LiteralPath $setupPath).Length
if ($copyHash -ne $canonicalHash -or $copySize -ne $canonicalSize) {
  Write-Host '[MUAMAN-13R] ERROR byte identity broken during delivery copy; refusing to continue.'
  exit 3
}

$readmeSize = (Get-Item -LiteralPath $readmePath).Length
if ($readmeSize -le 0) {
  Write-Host '[MUAMAN-13R] ERROR README is empty; refusing to continue.'
  exit 3
}

# SHA256SUMS manifest (sha256sum style: UPPER_HEX two-spaces file name)
("{0}  {1}" -f $copyHash, $SetupExeName) | Set-Content -LiteralPath $checksumPath -Encoding ASCII

# ---------------------------------------------------------------------------
# 5. verify the delivery tree is minimal and correct
# ---------------------------------------------------------------------------
$treeFiles = @(Get-ChildItem -LiteralPath $deliveryPackageDir -Recurse -File)
$treeNames = @($treeFiles | ForEach-Object { $_.Name } | Sort-Object -Unique)
$expectedNames = @($SetupExeName, 'README.txt', 'SHA256SUMS.txt')
$minimalOk = ($treeFiles.Count -eq $ExpectedZipEntryCount)
$namesOk = ($treeNames.Count -eq $expectedNames.Count)
if ($namesOk) {
  foreach ($n in $expectedNames) { if ($treeNames -notcontains $n) { $namesOk = $false } }
}
$checksumContent = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
$checksumOk = ($checksumContent -eq ("{0}  {1}" -f $copyHash, $SetupExeName))
$readmeOk = ($readmeSize -gt 0)

if (-not ($minimalOk -and $namesOk -and $checksumOk -and $readmeOk)) {
  Write-Host ('[MUAMAN-13R] ERROR delivery tree verification failed minimal={0} names={1} checksum={2} readme={3}' -f $minimalOk, $namesOk, $checksumOk, $readmeOk)
  exit 3
}
Write-Step ("delivery tree verified: {0} files, installer sha={1} size={2}" -f $treeFiles.Count, $copyHash, $copySize)

# ---------------------------------------------------------------------------
# 6. deterministic ZIP creation (folder-prefixed entries, constant timestamp)
# ---------------------------------------------------------------------------
$stage = 'package'
$constantLocal = [DateTime]::SpecifyKind(
  [DateTime]::ParseExact($ConstantZipTimestamp, 'yyyy-MM-ddTHH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture),
  [DateTimeKind]::Local)

$tempZipPath = Join-Path $OutputRoot ($ZipName + '.partial.tmp')
if (Test-Path -LiteralPath $tempZipPath) { Remove-Item -LiteralPath $tempZipPath -Force }

# stable ordinal entry ordering
$relNames = [string[]]@($expectedNames | ForEach-Object { $PackageDirName + '/' + $_ })
$sortedRel = [string[]]@($relNames)
$indices = [int[]]@(0..($relNames.Count - 1))
[Array]::Sort($sortedRel, $indices, [System.StringComparer]::Ordinal)

Write-Step ("creating deterministic ZIP with {0} entries (constant entry timestamp {1})" -f $ExpectedZipEntryCount, $ConstantZipTimestamp)

$fs = [System.IO.File]::Open($tempZipPath, [System.IO.FileMode]::Create)
try {
  $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $true)
  try {
    foreach ($i in $indices) {
      $name = $sortedRel[$i]
      $rel = $name.Substring($name.IndexOf('/') + 1)
      $src = Join-Path $deliveryPackageDir $rel
      $entry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
      $entry.LastWriteTime = $constantLocal
      $inStream = [System.IO.File]::OpenRead($src)
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
# 7. atomic finalization (temp -> final name)
# ---------------------------------------------------------------------------
$finalZipPath = Join-Path $OutputRoot $ZipName
if (Test-Path -LiteralPath $finalZipPath -PathType Leaf) { Remove-Item -LiteralPath $finalZipPath -Force }
[System.IO.File]::Move($tempZipPath, $finalZipPath)
$tempZipPath = ''
Write-Step ("ZIP finalized: {0}" -f $finalZipPath)

# ---------------------------------------------------------------------------
# 8. checksum output for the ZIP itself
# ---------------------------------------------------------------------------
$zipShaPath = Join-Path $OutputRoot ($ZipName + '.sha256')
("{0}  {1}" -f $zipHash, $ZipName) | Set-Content -LiteralPath $zipShaPath -Encoding ASCII

# ---------------------------------------------------------------------------
# 9. evidence: installer identity + delivery tree + package result
# ---------------------------------------------------------------------------
$installerIdentityText = @(
  'MUAMAN-13R governed delivery installer identity',
  '================================================',
  'phase            : MUAMAN-13R',
  'runTag           : ' + $RunTag,
  'canonicalInstallerSource : ' + $CanonicalInstaller,
  'deliveryInstaller       : ' + $setupPath,
  ('sha256           : ' + $copyHash),
  ('expectedSha256   : ' + $ExpectedInstallerSha256),
  ('sizeBytes        : ' + $copySize),
  ('expectedSizeBytes: ' + $ExpectedInstallerSize),
  ('sha256Match      : ' + ($copyHash -eq $ExpectedInstallerSha256)),
  ('sizeMatch        : ' + ($copySize -eq $ExpectedInstallerSize))
) -join "`r`n"
Set-Content -LiteralPath (Join-Path $EvidenceDir 'installer-identity.txt') -Value $installerIdentityText -Encoding UTF8

$treeLines = @(
  'MUAMAN-13R governed delivery package tree',
  '===========================================',
  ('packageDir : ' + $PackageDirName)
)
foreach ($f in $treeFiles) {
  $rel = $f.FullName.Substring($deliveryPackageDir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
  $treeLines += ('{0}|{1}|{2}' -f $rel, $f.Length, (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
}
$treeLines += ''
$treeLines += ('zip        : ' + $finalZipPath)
$treeLines += ('zipSha256  : ' + $zipHash)
$treeLines += ('zipSize    : ' + $zipSize)
Set-Content -LiteralPath (Join-Path $EvidenceDir 'delivery-tree.txt') -Value ($treeLines -join "`r`n") -Encoding UTF8

$toolHash = Get-Sha256 $MyInvocation.MyCommand.Path
$result = [ordered]@{
  schemaVersion = '1.0'
  run = [ordered]@{
    startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    finishedAtUtc = ([DateTime]::UtcNow).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    exitCode = 0
    runTag = $RunTag
  }
  installerIdentity = [ordered]@{
    verdict = 'PASS'
    canonicalInstaller = $CanonicalInstaller
    sha256 = $copyHash
    sizeBytes = $copySize
    expectedSha256 = $ExpectedInstallerSha256
    expectedSizeBytes = $ExpectedInstallerSize
    sha256Match = $true
    sizeMatch = $true
  }
  delivery = [ordered]@{
    verdict = 'PASS'
    packageDirName = $PackageDirName
    setupExeName = $SetupExeName
    fileCount = $treeFiles.Count
    minimalFileNames = $expectedNames
    checksumManifestCorrect = $checksumOk
    readmeNonEmpty = $readmeOk
  }
  packaging = [ordered]@{
    verdict = 'PASS'
    zipFilename = $ZipName
    zipSha256 = $zipHash
    zipSize = $zipSize
    entryCount = $ExpectedZipEntryCount
    constantEntryTimestampLocal = $ConstantZipTimestamp
    constantEntryTimestampDos = '0x58210000'
  }
  outputs = [ordered]@{
    outputRoot = $OutputRoot
    evidenceDir = $EvidenceDir
    deliveryPackageDir = $deliveryPackageDir
    zipPath = $finalZipPath
    zipChecksumPath = $zipShaPath
  }
  packagingTool = [ordered]@{
    name = 'tools/muaman13r/package_final_delivery.ps1'
    version = '1.0'
    sha256 = $toolHash
  }
  failureReason = $null
}
$resultJson = $result | ConvertTo-Json -Depth 8
Set-Content -LiteralPath (Join-Path $OutputRoot 'package-result.json') -Value $resultJson -Encoding UTF8
Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-result.json') -Value $resultJson -Encoding UTF8

Write-Step ("RESULT: PASS (exit 0)")
Write-Step ("DELIVERY: {0}" -f $deliveryPackageDir)
Write-Step ("ZIP: {0} ({1} bytes)" -f $finalZipPath, $zipSize)
Write-Step ("ZIP SHA-256: {0}" -f $zipHash)
exit 0

} catch {
  $err = $_.Exception.Message
  if (-not [string]::IsNullOrWhiteSpace($tempZipPath) -and (Test-Path -LiteralPath $tempZipPath)) {
    Remove-Item -LiteralPath $tempZipPath -Force -ErrorAction SilentlyContinue
  }
  $finish = [DateTime]::UtcNow
  $code = switch ($stage) {
    'verify-installer' { 2 }
    'delivery' { 3 }
    'package' { 3 }
    default { 4 }
  }
  try {
    Write-PackageResult @{
      schemaVersion = '1.0'
      run = [ordered]@{ startedAtUtc = $startUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); finishedAtUtc = $finish.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'); exitCode = $code; runTag = $RunTag }
      installerIdentity = [ordered]@{ verdict = if ($stage -eq 'verify-installer') { 'FAIL' } else { 'PASS' } }
      delivery = [ordered]@{ verdict = if ($stage -eq 'delivery') { 'FAIL' } else { 'NOT-RUN' } }
      packaging = [ordered]@{ verdict = if ($stage -eq 'package') { 'FAIL' } else { 'NOT-RUN' } }
      outputs = [ordered]@{ outputRoot = $OutputRoot; evidenceDir = $EvidenceDir }
      failureReason = $err
    }
  } catch { }
  Write-Host ("[MUAMAN-13R] PACKAGING FAILED (stage {0}, exit {1}): {2}" -f $stage, $code, $err)
  exit $code
}
