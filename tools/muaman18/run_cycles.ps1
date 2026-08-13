# MUAMAN-18 WM_CLOSE acceptance: repeated launch -> close cycles.
# Usage:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File run_cycles.ps1 `
#     -ReleaseDir <dir> -RunId <id> -OutDir <dir> [-Cycles 20] [-Scenario x] [-CooldownMs 1500]

param(
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(Mandatory=$true)][string]$OutDir,
  [int]$Cycles = 20,
  [string]$Scenario = 'launch-close',
  [int]$WindowTimeoutSec = 60,
  [int]$ExitTimeoutSec = 30,
  [int]$CooldownMs = 1500,
  [string]$TitleProbe = '',
  [string]$ExeName = 'muaman_store.exe'
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'lib\common.ps1')

$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$exe = Join-Path $ReleaseDir $ExeName
if (-not (Test-Path -LiteralPath $exe)) { throw "Release exe not found: $exe" }

$records = @()
for ($i = 1; $i -le $Cycles; $i++) {
  $rec = Invoke-CloseCycle -ExePath $exe -RunId $RunId -Scenario "$Scenario/cycle-$i" `
    -WindowTimeoutSec $WindowTimeoutSec -ExitTimeoutSec $ExitTimeoutSec -TitleProbe $TitleProbe
  $records += $rec
  $crashTag = if ($rec.crashCode) { 'CRASH' } elseif (-not $rec.ok) { 'FAIL' } else { 'ok' }
  Write-Host ("cycle {0}/{1}: pid={2} found={3} exited={4} code={5} sec={6} linger={7} => {8}" -f `
    $i, $Cycles, $rec.pid, $rec.windowFound, $rec.exited, (Format-ExitCode $rec.exitCode), $rec.exitSeconds, `
    ($rec.lingeringPids -join ','), $crashTag)
  Start-Sleep -Milliseconds $CooldownMs
}

$crashes = @($records | Where-Object { $null -ne $_.crashCode })
$failures = @($records | Where-Object { -not $_.ok })
$hangs = @($records | Where-Object { $_.timedOut })
$lingers = @($records | Where-Object { $_.lingeringPids.Count -gt 0 })
$forced = @($records | Where-Object { $_.forcedKillUsed })
$clean = @($records | Where-Object { $_.ok })

$summary = [ordered]@{
  runId = $RunId
  scenario = $Scenario
  exe = $exe
  cyclesRequested = $Cycles
  cyclesExecuted = $records.Count
  passed = $clean.Count
  failed = $failures.Count
  crashes = $crashes.Count
  hang = $hangs.Count
  lingering = $lingers.Count
  forcedKills = $forced.Count
  crashCodes = @($crashes | ForEach-Object { Format-ExitCode $_.exitCode } | Select-Object -Unique)
  passRate = if ($records.Count -gt 0) { [math]::Round(($clean.Count / $records.Count) * 100, 1) } else { 0 }
  status = if ($crashes.Count -eq 0 -and $failures.Count -eq 0 -and $records.Count -eq $Cycles) { 'PASS' } else { 'FAIL' }
}

$outRuns = Join-Path $OutDir 'shutdown-runs.json'
$records | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $outRuns -Encoding UTF8
$outSummary = Join-Path $OutDir 'shutdown-summary.json'
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $outSummary -Encoding UTF8

Write-Host ("summary: {0}" -f ($summary | ConvertTo-Json -Compress))
exit $(if ($summary.status -eq 'PASS') { 0 } else { 1 })
