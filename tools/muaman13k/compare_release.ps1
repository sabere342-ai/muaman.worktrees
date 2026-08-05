# MUAMAN-13K byte-for-byte Release comparison.
# Compares two unpacked Release payloads on the exact same relative-path set,
# file count, total bytes, per-file size and per-file SHA-256. Also reports
# only-in-A / only-in-B sets. Does NOT compare ZIPs.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File compare_release.ps1 ^
#       -ReleaseA <dir> -ReleaseB <dir> -Out <json> [-Label <text>]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseA,
  [Parameter(Mandatory=$true)][string]$ReleaseB,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$Label = ''
)
$ErrorActionPreference = 'Stop'

$ReleaseA = [System.IO.Path]::GetFullPath($ReleaseA)
$ReleaseB = [System.IO.Path]::GetFullPath($ReleaseB)
$Out = [System.IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null
if (-not (Test-Path -LiteralPath $ReleaseA)) { Write-Error ("ReleaseA not found: {0}" -f $ReleaseA); exit 1 }
if (-not (Test-Path -LiteralPath $ReleaseB)) { Write-Error ("ReleaseB not found: {0}" -f $ReleaseB); exit 1 }

function Build-FileMap([string]$root) {
  $map = [ordered]@{}
  foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $map[$rel] = [pscustomobject]@{ size = $f.Length; sha256 = $h }
  }
  return $map
}

$mA = Build-FileMap $ReleaseA
$mB = Build-FileMap $ReleaseB
$keysA = @($mA.Keys | Sort-Object)
$keysB = @($mB.Keys | Sort-Object)

$diffs = @()
$onlyA = @()
$onlyB = @()
foreach ($k in $keysA) {
  if (-not $mB.Contains($k)) { $onlyA += $k }
  elseif ($mA[$k].size -ne $mB[$k].size -or $mA[$k].sha256 -ne $mB[$k].sha256) {
    $diffs += [pscustomobject][ordered]@{ rel = $k; sizeA = $mA[$k].size; sizeB = $mB[$k].size; shaA = $mA[$k].sha256; shaB = $mB[$k].sha256 }
  }
}
foreach ($k in $keysB) {
  if (-not $mA.Contains($k)) { $onlyB += $k }
}

$countA = $keysA.Count
$countB = $keysB.Count
$totalA = ($keysA | ForEach-Object { $mA[$_].size } | Measure-Object -Sum).Sum
$totalB = ($keysB | ForEach-Object { $mB[$_].size } | Measure-Object -Sum).Sum
$identical = ($diffs.Count -eq 0 -and $onlyA.Count -eq 0 -and $onlyB.Count -eq 0)

# cross-run manifest hash: SHA-256 of the canonical A manifest lines
function Cross-Hash([string]$root) {
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

$result = [ordered]@{
  label = $Label
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  releaseA = $ReleaseA
  releaseB = $ReleaseB
  fileCountA = $countA
  fileCountB = $countB
  totalBytesA = $totalA
  totalBytesB = $totalB
  identical = $identical
  diffCount = $diffs.Count
  diffs = $diffs
  onlyInACount = $onlyA.Count
  onlyInA = $onlyA
  onlyInBCount = $onlyB.Count
  onlyInB = $onlyB
  crossHashA = (Cross-Hash $ReleaseA)
  crossHashB = (Cross-Hash $ReleaseB)
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MUAMAN-13K compare [{0}]: A={1}/{2}B B={3}/{4}B identical={5} diffs={6} onlyA={7} onlyB={8} crossA={9} crossB={10}" -f `
  $Label, $countA, $totalA, $countB, $totalB, $identical, $diffs.Count, $onlyA.Count, $onlyB.Count, $result.crossHashA, $result.crossHashB)
exit 0
