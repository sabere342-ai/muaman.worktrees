# MUAMAN-13I response-file (.rsp) capture watcher.
# Polls the given watch roots for any *.rsp file and copies each newly seen
# file into an evidence directory before MSBuild/temp-cleanup can delete it.
# The original file is never modified. Every capture is recorded (with
# SHA-256, byte length, BOM analysis, encoding guess, and original path) into
# a JSONL metadata file next to the captured copies.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File rsp_watcher.ps1 ^
#       -WatchRoots C:\tmp1,C:\tmp2 -EvidenceRoot <dir> -StopFile <path> [-MaxSeconds 1800]
#
# The watcher exits when the stop file appears (checked between sweeps) or
# after MaxSeconds. It writes <EvidenceRoot>\watcher.started as soon as it
# has begun so an orchestrator can wait for readiness.

param(
  [Parameter(Mandatory=$true)][string]$WatchRoots,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][string]$StopFile,
  [int]$MaxSeconds = 1800
)
$ErrorActionPreference = 'Continue'

New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
$started = Join-Path $EvidenceRoot 'watcher.started'
if (-not (Test-Path -LiteralPath $started)) {
  "started_utc=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))" |
    Set-Content -LiteralPath $started -Encoding UTF8
}

$roots = @($WatchRoots -split ',' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
$meta = Join-Path $EvidenceRoot 'capture.jsonl'
$seen = @{}
$startUtc = [DateTime]::UtcNow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

function Get-BomInfo([string]$path) {
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $info = @{
    bom = 'none'
    bomBytes = 0
    utf16LE = $false
    utf16BE = $false
    utf8 = $true
    encodingGuess = 'utf8-nobom'
  }
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $info.bom = 'utf8'; $info.bomBytes = 3; $info.encodingGuess = 'utf8-bom'
  } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $info.bom = 'utf16le'; $info.bomBytes = 2; $info.utf16LE = $true; $info.encodingGuess = 'utf16le'
  } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $info.bom = 'utf16be'; $info.bomBytes = 2; $info.utf16BE = $true; $info.encodingGuess = 'utf16be'
  }
  $hasNul = $false
  for ($i = 0; $i -lt [Math]::Min($bytes.Length, 4096); $i++) { if ($bytes[$i] -eq 0) { $hasNul = $true; break } }
  if ($info.bom -eq 'none') { $info.encodingGuess = if ($hasNul) { 'utf16-nobom' } else { 'ansi-or-utf8' } }
  return $info
}

while ($true) {
  if (Test-Path -LiteralPath $StopFile -ErrorAction SilentlyContinue) { break }
  if ($sw.Elapsed.TotalSeconds -ge $MaxSeconds) { break }

  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root -ErrorAction SilentlyContinue)) { continue }
    Get-ChildItem -LiteralPath $root -Filter *.rsp -Recurse -File -ErrorAction SilentlyContinue |
      ForEach-Object {
        $key = $_.FullName.ToUpperInvariant()
        if ($seen.ContainsKey($key)) { return }
        for ($attempt = 1; $attempt -le 40; $attempt++) {
          try {
            $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')
            $safeName = ($_.Name -replace '[^A-Za-z0-9._-]', '_')
            $destination = Join-Path $EvidenceRoot "${stamp}_${safeName}"
            Copy-Item -LiteralPath $_.FullName -Destination $destination -ErrorAction Stop
            $h = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            $fi = Get-Item -LiteralPath $destination
            $bom = Get-BomInfo $destination
            $record = [pscustomobject]@{
              capturedAtUtc   = $stamp
              originalPath    = $_.FullName
              originalPathLen = $_.FullName.Length
              destination     = $destination
              lengthBytes     = $fi.Length
              sha256          = $h
              bom             = $bom.bom
              encodingGuess   = $bom.encodingGuess
            } | ConvertTo-Json -Compress
            Add-Content -LiteralPath $meta -Value $record -Encoding UTF8
            $seen[$key] = $true
            break
          } catch {
            Start-Sleep -Milliseconds 25
          }
        }
      }
  }
  Start-Sleep -Milliseconds 20
}
