# MUAMAN-13K canonical Release manifest generator.
# Walks a Release directory and emits, for every file (including zero-byte and
# nested), a canonical record: normalized relative path, size in bytes,
# SHA-256, and file type / extension. Sorted by normalized relative path using
# ordinal ordering. Written as JSON to <Out> and mirrored to stdout summary.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File make_release_manifest.ps1 ^
#       -ReleaseDir <dir> -Out <json> [-RunId <id>]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$RunId = ''
)
$ErrorActionPreference = 'Stop'

$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$Out = [System.IO.Path]::GetFullPath($Out)
if (-not (Test-Path -LiteralPath $ReleaseDir)) {
  Write-Error ("Release directory not found: {0}" -f $ReleaseDir)
  exit 1
}
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$comparer = [System.StringComparer]::Ordinal
$entries = @()
foreach ($f in Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File | Sort-Object FullName) {
  $rel = $f.FullName.Substring($ReleaseDir.Length).TrimStart('\').Replace('\', '/')
  $rel = $rel.TrimStart('/')
  $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  $ext = $f.Extension
  if ($ext -eq '') { $ext = '<none>' }
  $entries += [pscustomobject][ordered]@{
    rel = $rel
    size = $f.Length
    sha256 = $hash
    ext = $ext
  }
}
# ordinal sort on normalized relative path
$entries = @($entries | Sort-Object rel)

$total = ($entries | Measure-Object -Property size -Sum).Sum
$manifest = [ordered]@{
  runId = $RunId
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  releaseDir = $ReleaseDir
  fileCount = $entries.Count
  totalBytes = $total
  files = $entries
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MUAMAN-13K manifest [{0}]: files={1} totalBytes={2} -> {3}" -f $RunId, $entries.Count, $total, $Out)
exit 0
