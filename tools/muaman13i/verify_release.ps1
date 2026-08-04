# MUAMAN-13I release verification.
# Compares two Release trees byte-for-byte (relative path + size + SHA-256)
# and scans all files for absolute-path leaks (ASCII and UTF-16LE).
# Writes manifests, a comparison result and a leak report under <EvidenceDir>.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File verify_release.ps1 ^
#       -ReleaseA <dir> -ReleaseB <dir> -EvidenceDir <dir> [-Label "final"]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseA,
  [Parameter(Mandatory=$true)][string]$ReleaseB,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [string]$Label = 'release'
)
$ErrorActionPreference = 'Stop'

$ReleaseA = [System.IO.Path]::GetFullPath($ReleaseA)
$ReleaseB = [System.IO.Path]::GetFullPath($ReleaseB)
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Sha256([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }

function Build-Manifest([string]$root) {
  $entries = Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
    [pscustomobject][ordered]@{
      rel = $_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
      size = $_.Length
      sha256 = Sha256 $_.FullName
    }
  }
  [pscustomobject]@{ root = $root; entries = @($entries) }
}

$mA = Build-Manifest $ReleaseA 'A'
$mB = Build-Manifest $ReleaseB 'B'
$mA.entries | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $EvidenceDir 'manifest-A.json') -Encoding UTF8
$mB.entries | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $EvidenceDir 'manifest-B.json') -Encoding UTF8

$mapA = @{}
foreach ($e in $mA.entries) { $mapA[$e.rel] = $e }

$diffs = @()
$onlyB = @()
foreach ($e in $mB.entries) {
  if (-not $mapA.ContainsKey($e.rel)) { $onlyB += $e.rel }
  elseif ($mapA[$e.rel].size -ne $e.size -or $mapA[$e.rel].sha256 -ne $e.sha256) { $diffs += $e.rel }
}
$onlyA = @($mA.entries | Where-Object { -not ($mB.entries | Where-Object rel -eq $_.rel) } | ForEach-Object rel)

$identical = ($diffs.Count -eq 0 -and $onlyA.Count -eq 0 -and $onlyB.Count -eq 0)

# Leak scan: look for the well-known absolute roots in ASCII and UTF-16LE.
$patterns = @(
  'C:\dev\muaman-13i-environment-b-independent-',
  'C:\m13i\',
  'C:\t\m13i-',
  'C:\Program Files (x86)\Microsoft Visual Studio',
  'C:\Users\saber',
  'C:\WINDOWS',
  'C:\dev\muaman.worktrees'
)
$leaks = @()
foreach ($e in $mB.entries) {
  $p = Join-Path $ReleaseB ($e.rel.Replace('/', '\'))
  $bytes = [System.IO.File]::ReadAllBytes($p)
  $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
  $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
  foreach ($pat in $patterns) {
    $pats = $pat.Replace('\', '\\')
    if ($ascii -match $pats) { $leaks += [ordered]@{ rel=$e.rel; encoding='ascii'; pattern=$pat } }
    if ($utf16 -match $pats) { $leaks += [ordered]@{ rel=$e.rel; encoding='utf16le'; pattern=$pat } }
  }
}

$result = [ordered]@{
  label = $Label
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  releaseA = $ReleaseA
  releaseB = $ReleaseB
  fileCountA = $mA.entries.Count
  fileCountB = $mB.entries.Count
  totalBytesA = ($mA.entries | Measure-Object -Property size -Sum).Sum
  totalBytesB = ($mB.entries | Measure-Object -Property size -Sum).Sum
  identical = $identical
  diffFiles = $diffs
  onlyInA = $onlyA
  onlyInB = $onlyB
  leakCount = $leaks.Count
  leaks = $leaks
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $EvidenceDir 'verify-result.json') -Encoding UTF8

Write-Output ("MUAMAN-13I verify [{0}]: files A={1} B={2} identical={3} diffs={4} onlyA={5} onlyB={6} leaks={7}" -f `
  $Label, $mA.entries.Count, $mB.entries.Count, $identical, $diffs.Count, $onlyA.Count, $onlyB.Count, $leaks.Count)
if (-not $identical) {
  $diffs | ForEach-Object { Write-Output ("DIFF: " + $_) }
  $onlyA | ForEach-Object { Write-Output ("ONLY-A: " + $_) }
  $onlyB | ForEach-Object { Write-Output ("ONLY-B: " + $_) }
}
exit 0
