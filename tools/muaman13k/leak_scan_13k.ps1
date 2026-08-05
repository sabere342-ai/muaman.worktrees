# MUAMAN-13K Release path-leak scan.
# Scans every file in a Release payload for any of the provided root tokens,
# in BOTH raw-ASCII (case-insensitive byte search) and UTF-16LE encodings.
# A zero-leak result is the required outcome.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File leak_scan_13k.ps1 ^
#       -ReleaseDir <dir> -Roots @('C:\a\b','C:\x\y') -Out <json> [-Label <text>]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [Parameter(Mandatory=$true)][string[]]$Roots,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$Label = ''
)
$ErrorActionPreference = 'Stop'

$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$Out = [System.IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null
if (-not (Test-Path -LiteralPath $ReleaseDir)) { Write-Error ("ReleaseDir not found: {0}" -f $ReleaseDir); exit 1 }

$normalized = @()
foreach ($r in $Roots) {
  $normalized += [System.IO.Path]::GetFullPath($r).TrimEnd('\')
}

function Contains-AsciiInsensitive([byte[]]$haystack, [string]$needle) {
  if ($needle.Length -eq 0) { return $true }
  $n = [System.Text.Encoding]::ASCII.GetBytes($needle.ToLowerInvariant())
  $hi = $haystack.Length - $n.Length
  if ($hi -lt 0) { return $false }
  for ($i = 0; $i -le $hi; $i++) {
    $match = $true
    for ($j = 0; $j -lt $n.Length; $j++) {
      $b = $haystack[$i + $j]
      if ($b -ge 65 -and $b -le 90) { $b = $b + 32 }
      if ($b -ne $n[$j]) { $match = $false; break }
    }
    if ($match) { return $true }
  }
  return $false
}

$findings = @()
$scanned = 0
foreach ($f in Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File) {
  $scanned++
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $rel = $f.FullName.Substring($ReleaseDir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
  foreach ($tok in $normalized) {
    if (Contains-AsciiInsensitive $bytes $tok) {
      $findings += [pscustomobject]@{ rel = $rel; token = $tok; encoding = 'ASCII' }
    }
  }
  $uni = [System.Text.Encoding]::Unicode.GetString($bytes).ToLowerInvariant()
  foreach ($tok in $normalized) {
    if ($uni.Contains($tok.ToLowerInvariant())) {
      $findings += [pscustomobject]@{ rel = $rel; token = $tok; encoding = 'UTF-16LE' }
    }
  }
}

$result = [ordered]@{
  label = $Label
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  releaseDir = $ReleaseDir
  rootsScanned = @($normalized)
  filesScanned = $scanned
  findingCount = $findings.Count
  findings = $findings
  leakFree = ($findings.Count -eq 0)
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MUAMAN-13K leak scan [{0}]: files={1} findings={2} leakFree={3}" -f $Label, $scanned, $findings.Count, $result.leakFree)
exit 0
