# run_print_close_stress.ps1 - MUAMAN-18 print-dialog-open close stress.
# IMPORTANT: this file is ASCII-only.
#
# Drives repeated full smoke acceptance runs (run_smoke.ps1). Each cycle ends
# with S12 WM_CLOSE while the printing plugin's Print Setup dialog (#32770) is
# still open - the exact condition that used to trigger the teardown UAF.
# A procdump monitor is armed for the whole run so any access-violation crash
# is captured to a dump even if the process would otherwise vanish.
#
# A cycle is PASS iff:
#   - S12 close reports exitCode == 0 via WM_CLOSE (clean, not Kill)
#   - the worker did not abort
#   - no new procdump file appeared for the cycle
#   - no orphaned muaman_store.exe / descendant processes remain
#   - the iteration finished within the watchdog timeout (no hang)
#
# Usage:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File run_print_close_stress.ps1 `
#     -ReleaseDir <dir> -OutRoot <dir> -UiStringsPath <file> [-Cycles 20]

#Requires -Version 5.1
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ReleaseDir,
  [Parameter(Mandatory = $true)][string]$OutRoot,
  [Parameter(Mandatory = $true)][string]$UiStringsPath,
  [int]$Cycles = 20,
  [int]$IterationTimeoutSec = 900,
  [int]$CooldownSec = 5,
  [string]$Procdump64 = '',
  [string]$RunIdPrefix = 'STRESS-FIX'
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$smoke = Join-Path $here '..\muaman17w\run_smoke.ps1'
if (-not (Test-Path -LiteralPath $smoke)) { throw "run_smoke.ps1 not found: $smoke" }
$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
$OutRoot = [System.IO.Path]::GetFullPath($OutRoot)
$UiStringsPath = [System.IO.Path]::GetFullPath($UiStringsPath)
if (-not (Test-Path -LiteralPath $UiStringsPath)) { throw "ui strings not found: $UiStringsPath" }

if ([string]::IsNullOrWhiteSpace($Procdump64)) {
  $Procdump64 = 'C:\Users\saber\AppData\Local\Temp\opencode\procdump\procdump64.exe'
}
if (-not (Test-Path -LiteralPath $Procdump64)) { throw "procdump64.exe not found: $Procdump64" }

$DumpsDir = Join-Path $OutRoot 'werdumps'
New-Item -ItemType Directory -Path $DumpsDir -Force | Out-Null
$ConsoleDir = Join-Path $OutRoot 'console'
New-Item -ItemType Directory -Path $ConsoleDir -Force | Out-Null

function Get-DumpCount {
  if (-not (Test-Path -LiteralPath $DumpsDir)) { return 0 }
  return @(Get-ChildItem -LiteralPath $DumpsDir -Filter '*.dmp' -File).Count
}

function Get-LiveMuamanProcesses {
  return @(Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue)
}

# Stop any leftover instances from a previous session.
foreach ($proc in Get-LiveMuamanProcesses) { try { $proc.Kill() } catch {} }

# Arm the crash monitor. -w waits for new muaman_store.exe instances. -e 1 -f
# ... only triggers dumps for the two crash signatures of interest. Note: -t is
# deliberately NOT used here because it writes a benign dump on every normal
# process termination, which would pollute the crash signal.
$procdump = Start-Process -FilePath $Procdump64 -ArgumentList @(
  '-accepteula', '-e', '1', '-f', 'c0000005', '-f', 'c000041d', '-w',
  'muaman_store.exe', $DumpsDir) -PassThru -WindowStyle Hidden

$records = @()
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
for ($i = 1; $i -le $Cycles; $i++) {
  $cycleStart = [DateTime]::UtcNow
  $runId = '{0}-{1}-c{2:000}' -f $RunIdPrefix, $timestamp, $i
  $outDir = Join-Path $OutRoot $runId
  $stdout = Join-Path $ConsoleDir ("c{0:000}-stdout.log" -f $i)
  $stderr = Join-Path $ConsoleDir ("c{0:000}-stderr.log" -f $i)
  $dumpsBefore = Get-DumpCount

  $rec = [ordered]@{
    runId = $runId
    cycle = $i
    startedUtc = $cycleStart.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    durationSec = $null
    workerExited = $false
    timedOut = $false
    aborted = $null
    s12Close = $null
    crashCode = $null
    dumpWritten = $false
    orphanPids = @()
    forcedKill = $false
    ok = $false
  }

  $child = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $smoke),
    '-RunId', ('"{0}"' -f $runId),
    '-ReleaseDir', ('"{0}"' -f $ReleaseDir),
    '-EvidenceRoot', ('"{0}"' -f $outDir),
    '-UiStringsPath', ('"{0}"' -f $UiStringsPath)) -PassThru `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while (-not $child.HasExited -and $sw.Elapsed.TotalSeconds -lt $IterationTimeoutSec) {
    Start-Sleep -Milliseconds 1000
  }
  $rec.durationSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
  $rec.timedOut = -not $child.HasExited
  $rec.workerExited = $child.HasExited

  if ($rec.timedOut) {
    try { $child.Kill() } catch {}
    foreach ($p in Get-LiveMuamanProcesses) { try { $p.Kill() } catch {} }
    $rec.forcedKill = $true
  }

  $doneFile = Join-Path $outDir 'json\worker-done.json'
  if (Test-Path -LiteralPath $doneFile) {
    try {
      $done = Get-Content -LiteralPath $doneFile -Raw | ConvertFrom-Json
      $rec.aborted = $done.aborted
      $s12 = $done.steps.'S12-logout-close'
      if ($null -ne $s12 -and $null -ne $s12.result -and $null -ne $s12.result.close) {
        $rec.s12Close = [ordered]@{
          method = $s12.result.close.method
          exited = $s12.result.close.exited
          exitCode = $s12.result.close.exitCode
          seconds = $s12.result.close.seconds
        }
      }
    } catch { }
  }

  $rec.dumpWritten = (Get-DumpCount -gt $dumpsBefore)
  if ($rec.dumpWritten) {
    $rec.crashCode = '0xC0000005/0xC000041D-dump'
  } elseif ($null -ne $rec.s12Close -and $null -ne $rec.s12Close.exitCode -and $rec.s12Close.exitCode -isnot [string]) {
    $code = [int64]$rec.s12Close.exitCode
    if ($code -ne 0) {
      $rec.crashCode = ('0x{0:X8}' -f ($code -band 0xFFFFFFFF))
    }
  }

  $rec.orphanPids = @(Get-LiveMuamanProcesses | ForEach-Object { $_.Id })

  $closeClean = ($null -ne $rec.s12Close -and $rec.s12Close.method -eq 'WM_CLOSE' -and
                 $rec.s12Close.exited -eq $true -and [int64]$rec.s12Close.exitCode -eq 0)
  $rec.ok = (-not $rec.timedOut -and $rec.workerExited -and -not $rec.aborted -and
             $closeClean -and -not $rec.dumpWritten -and -not $rec.forcedKill -and
             $rec.orphanPids.Count -eq 0)

  $records += $rec
  $tag = if ($rec.ok) { 'ok' } elseif ($rec.timedOut) { 'HANG' } elseif ($rec.dumpWritten) { 'CRASH' } else { 'FAIL' }
  $closeStr = if ($rec.s12Close) { "close=$($rec.s12Close.method)/exit=$($rec.s12Close.exitCode)/sec=$($rec.s12Close.seconds)" } else { 'close=n/a' }
  Write-Host ("cycle {0}/{1} {2}: sec={3} {4} aborted={5} dumps={6} orphans={7} => {8}" -f `
    $i, $Cycles, $runId, $rec.durationSec, $closeStr, $rec.aborted, $rec.dumpWritten,
    ($rec.orphanPids -join ','), $tag)
  Start-Sleep -Seconds $CooldownSec
}

try { if (-not $procdump.HasExited) { $procdump.Kill() } } catch {}

$passed = @($records | Where-Object { $_.ok })
$hangs = @($records | Where-Object { $_.timedOut })
$dumps = @($records | Where-Object { $_.dumpWritten })
$badExit = @($records | Where-Object { -not $_.ok -and -not $_.timedOut -and -not $_.dumpWritten })
$orphans = @($records | Where-Object { $_.orphanPids.Count -gt 0 })

$summary = [ordered]@{
  runIdPrefix = $RunIdPrefix
  startedUtc = $null
  finishedUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  cyclesRequested = $Cycles
  cyclesExecuted = $records.Count
  passed = $passed.Count
  hang = $hangs.Count
  crashDumps = $dumps.Count
  badExit = $badExit.Count
  orphanCycles = $orphans.Count
  forcedKills = @($records | Where-Object { $_.forcedKill }).Count
  crashCodes = @($records | Where-Object { $_.crashCode } | ForEach-Object { $_.crashCode } | Select-Object -Unique)
  status = if ($Cycles -gt 0 -and $records.Count -eq $Cycles -and $passed.Count -eq $Cycles) { 'PASS' } else { 'FAIL' }
}
$summary.startedUtc = $records[0].startedUtc

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutRoot 'stress-summary.json') -Encoding UTF8
$records | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutRoot 'stress-records.json') -Encoding UTF8

Write-Host ("summary: {0}" -f ($summary | ConvertTo-Json -Compress))
exit $(if ($summary.status -eq 'PASS') { 0 } else { 1 })
