param(
  [string]$ReleaseDir = '',
  [string]$StageDir = '',
  [string]$OutDir = '',
  [int]$MaxWaitSeconds = 60
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReleaseDir)) { throw 'ReleaseDir is required' }
if ([string]::IsNullOrWhiteSpace($StageDir)) { throw 'StageDir is required' }
if ([string]::IsNullOrWhiteSpace($OutDir)) { throw 'OutDir is required' }

$releaseExe = Join-Path $ReleaseDir 'muaman_store.exe'
if (-not (Test-Path -LiteralPath $releaseExe)) { throw "Release exe not found: $releaseExe" }

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

# Copy the entire Release tree into an isolated stage dir so the app runs with a
# fresh CWD and no pre-existing DB. sqflite_common_ffi resolves its databases
# path relative to the process working directory (.dart_tool/sqflite_common_ffi/databases).
Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $StageDir -Recurse -Force

# Strip any runtime database artifacts that may have been copied along with the
# Release tree. sqflite_common_ffi keeps its databases under
# <CWD>/.dart_tool/sqflite_common_ffi/databases; a stale file here would make the
# app REUSE an existing DB (skipping onCreate) instead of creating a fresh one.
$copiedDotTool = Join-Path $StageDir '.dart_tool'
if (Test-Path -LiteralPath $copiedDotTool) {
  Remove-Item -LiteralPath $copiedDotTool -Recurse -Force
}

$exe = Join-Path $StageDir 'muaman_store.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "staged exe missing: $exe" }

$p = Start-Process -FilePath $exe -WorkingDirectory $StageDir -PassThru
"pid=$($p.Id)" | Set-Content -LiteralPath (Join-Path $OutDir 'pid.txt') -Encoding UTF8
"launchedAt=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))" | Set-Content -LiteralPath (Join-Path $OutDir 'launched.txt') -Encoding UTF8
"cwd=$StageDir" | Set-Content -LiteralPath (Join-Path $OutDir 'cwd.txt') -Encoding UTF8

$db = $null
$deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
while ((Get-Date) -lt $deadline) {
  if ($p.HasExited) { break }
  $found = Get-ChildItem -LiteralPath $StageDir -Recurse -Filter 'muaman_store.db' -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { $db = $found.FullName; break }
  Start-Sleep -Milliseconds 500
}

if (-not $db) {
  "dbFile=NOT_FOUND" | Set-Content -LiteralPath (Join-Path $OutDir 'db-result.txt') -Encoding UTF8
  if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
  "status=FAIL(db not created within ${MaxWaitSeconds}s)" | Set-Content -LiteralPath (Join-Path $OutDir 'status.txt') -Encoding UTF8
  throw 'muaman_store.db was not created under the staged app dir'
}

"dbFile=$db" | Set-Content -LiteralPath (Join-Path $OutDir 'db-result.txt') -Encoding UTF8
$dbSize = (Get-Item -LiteralPath $db).Length
"dbBytes=$dbSize" | Set-Content -LiteralPath (Join-Path $OutDir 'db-size.txt') -Encoding UTF8

Start-Sleep -Seconds 3
"observedAt=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))" | Set-Content -LiteralPath (Join-Path $OutDir 'observed.txt') -Encoding UTF8

if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force; $p.WaitForExit(5000) | Out-Null; $p.Refresh() }
"status=DB_CREATED_AND_STOPPED" | Set-Content -LiteralPath (Join-Path $OutDir 'status.txt') -Encoding UTF8

Write-Output "db=$db"
Write-Output "status=DB_CREATED_AND_STOPPED"
