# MUAMAN-13L release verification (refreshed for the governed delivery package
# refresh of the accepted MUAMAN-19 canonical release).
#
# Compares a freshly produced Windows Release directory against the committed
# legal release manifest (docs/windows-delivery-refresh/evidence/legal
# /release-manifest.json) on the exact same relative-path set, per-file size and
# per-file SHA-256, plus the canonical cross-run hash.
#
# The cross-run hash serialization is IDENTICAL to the one implemented in the
# committed legal tool tools/muaman13k/compare_release.ps1 (sorted
# "rel|size|sha256" lines, appended with StringBuilder.AppendLine, UTF-8 bytes,
# SHA-256, uppercase hex). It is re-implemented here ONLY as a standalone verifier;
# the authoritative byte-for-byte comparison can additionally be delegated to
# compare_release.ps1 itself when a reference release directory is available via
# -CompareReleaseA.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File verify_release.ps1 ^
#       -ReleaseDir <dir> -LegalManifest <json> -Out <json> [-CompareReleaseA <dir>]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [Parameter(Mandatory=$true)][string]$LegalManifest,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$CompareReleaseA = ''
)
$ErrorActionPreference = 'Stop'

$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$LegalManifest = [System.IO.Path]::GetFullPath($LegalManifest)
$Out = [System.IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

if (-not (Test-Path -LiteralPath $ReleaseDir)) { Write-Error ("ReleaseDir not found: {0}" -f $ReleaseDir); exit 1 }
if (-not (Test-Path -LiteralPath $LegalManifest)) { Write-Error ("LegalManifest not found: {0}" -f $LegalManifest); exit 1 }

$legal = Get-Content -LiteralPath $LegalManifest -Raw | ConvertFrom-Json

function Get-CrossHashFromRoot([string]$root) {
  $lines = foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    '{0}|{1}|{2}' -f $rel, $f.Length, $h
  }
  $sb = New-Object System.Text.StringBuilder
  foreach ($l in ($lines | Sort-Object)) { [void]$sb.AppendLine($l) }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
  return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
}

function Get-CrossHashFromManifest($m) {
  $lines = @($m.files | ForEach-Object { '{0}|{1}|{2}' -f $_.rel, $_.size, $_.sha256 })
  $sb = New-Object System.Text.StringBuilder
  foreach ($l in ($lines | Sort-Object)) { [void]$sb.AppendLine($l) }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
  return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
}

# ---- build a map of the freshly produced release ----
$newMap = [ordered]@{}
$newTotal = [int64]0
foreach ($f in Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File) {
  $rel = $f.FullName.Substring($ReleaseDir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
  $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  $newMap[$rel] = [pscustomobject]@{ size = $f.Length; sha256 = $h }
  $newTotal += $f.Length
}
$newCount = $newMap.Count

# ---- legal manifest map ----
$legalMap = [ordered]@{}
$legalTotal = [int64]0
foreach ($e in $legal.files) {
  $legalMap[[string]$e.rel] = [pscustomobject]@{ size = [int64]$e.size; sha256 = [string]$e.sha256 }
  $legalTotal += [int64]$e.size
}
$legalCount = $legalMap.Count

# ---- diffs ----
$diffs = @()
$onlyLegal = @()
$onlyNew = @()
foreach ($k in $legalMap.Keys) {
  if (-not $newMap.Contains($k)) { $onlyLegal += $k }
  elseif ($legalMap[$k].size -ne $newMap[$k].size -or $legalMap[$k].sha256 -ne $newMap[$k].sha256) {
    $diffs += [pscustomobject][ordered]@{
      rel = $k
      sizeLegal = $legalMap[$k].size
      sizeNew = $newMap[$k].size
      shaLegal = $legalMap[$k].sha256
      shaNew = $newMap[$k].sha256
    }
  }
}
foreach ($k in $newMap.Keys) {
  if (-not $legalMap.Contains($k)) { $onlyNew += $k }
}

$crossNew = Get-CrossHashFromRoot $ReleaseDir
$crossLegal = Get-CrossHashFromManifest $legal

$fileCountMatch = ($newCount -eq $legalCount -and $newCount -eq 16)
$totalBytesMatch = ($newTotal -eq $legalTotal -and $newTotal -eq 35754065)
$crossHashMatch = ($crossNew -eq $crossLegal) -and ($crossNew -eq '3A8CFA42656EABC8B06EEF835FB9222F95006E5B490D9B837AE76673A87794B0')
$identical = ($diffs.Count -eq 0 -and $onlyLegal.Count -eq 0 -and $onlyNew.Count -eq 0) -and
             $fileCountMatch -and $totalBytesMatch -and $crossHashMatch

$result = [ordered]@{
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  releaseDir = $ReleaseDir
  legalManifest = $LegalManifest
  fileCountNew = $newCount
  fileCountLegal = $legalCount
  totalBytesNew = $newTotal
  totalBytesLegal = $legalTotal
  expectedFileCount = 16
  expectedTotalBytes = 35754065
  fileCountMatch = $fileCountMatch
  totalBytesMatch = $totalBytesMatch
  crossHashNew = $crossNew
  crossHashLegal = $crossLegal
  crossHashExpected = '3A8CFA42656EABC8B06EEF835FB9222F95006E5B490D9B837AE76673A87794B0'
  crossHashMatch = $crossHashMatch
  diffCount = $diffs.Count
  diffs = $diffs
  onlyInLegalCount = $onlyLegal.Count
  onlyInLegal = $onlyLegal
  onlyInNewCount = $onlyNew.Count
  onlyInNew = $onlyNew
  identical = $identical
}

# ---- optional: delegate the byte-for-byte comparison to the committed legal
# tool (compare_release.ps1) when a reference release directory is provided ----
if (-not [string]::IsNullOrWhiteSpace($CompareReleaseA)) {
  $CompareReleaseA = [System.IO.Path]::GetFullPath($CompareReleaseA)
  $legalTool = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tools\muaman13k\compare_release.ps1'
  if (Test-Path -LiteralPath $legalTool) {
    $compareOut = Join-Path (Split-Path -Parent $Out) 'release-comparison-legal-tool.json'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $legalTool `
      -ReleaseA $CompareReleaseA -ReleaseB $ReleaseDir -Out $compareOut -Label 'L7-new-vs-13k-k1'
    $toolExit = $LASTEXITCODE
    $toolResult = $null
    if (Test-Path -LiteralPath $compareOut) { $toolResult = Get-Content -LiteralPath $compareOut -Raw | ConvertFrom-Json }
    $result.legalToolCompare = [ordered]@{
      exitCode = $toolExit
      referenceReleaseDir = $CompareReleaseA
      output = $compareOut
      identical = if ($null -ne $toolResult) { [bool]$toolResult.identical } else { $false }
      diffCount = if ($null -ne $toolResult) { [int]$toolResult.diffCount } else { -1 }
      crossHashA = if ($null -ne $toolResult) { [string]$toolResult.crossHashA } else { '' }
      crossHashB = if ($null -ne $toolResult) { [string]$toolResult.crossHashB } else { '' }
      crossHashMatch = if ($null -ne $toolResult) { ([string]$toolResult.crossHashA -eq [string]$toolResult.crossHashB) } else { $false }
    }
  } else {
    $result.legalToolCompare = [ordered]@{ exitCode = -1; error = 'compare_release.ps1 not found'; identical = $false }
  }
}

$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MUAMAN-13L verify: new={0}/{1}B legal={2}/{3}B identical={4} diffs={5} crossNew={6}" -f `
  $newCount, $newTotal, $legalCount, $legalTotal, $identical, $diffs.Count, $crossNew)
if (-not $identical) { exit 1 }
exit 0
