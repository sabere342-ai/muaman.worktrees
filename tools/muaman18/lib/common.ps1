# MUAMAN-18 WM_CLOSE teardown harness shared helpers.
# PowerShell 5.1 / Windows 11. ASCII-only source; no secrets.
#
# Provides:
#   Initialize-WinNative      P/Invoke for PostMessage / EnumWindows / GetWindowThreadProcessId
#   Start-AppProcess          launches the Release exe, returns the Process
#   Wait-MainWindow           waits for a top-level window of the process
#   Send-WmClose              genuine WM_CLOSE via PostMessage
#   Wait-ProcessExit          polls for process exit; returns state
#   Get-DescendantProcessIds  child process tree of a PID (orphan detection)
#   Assert-NoLingeringProcess fails if any descendant survives
#   Invoke-CloseCycle         one full launch -> wait window -> WM_CLOSE -> exit cycle

$script:M18WinNativeLoaded = $false

function Initialize-WinNative {
  if ($script:M18WinNativeLoaded) { return }
  Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class M18WinNative {
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

  [DllImport("user32.dll")]
  public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

  [DllImport("user32.dll")]
  public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

  [DllImport("user32.dll")]
  public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@
  $script:M18WinNativeLoaded = $true
}

# Constants
Set-Variable -Scope Script M18_WM_CLOSE 0x0010

function Get-TopLevelWindowsOfPid {
  param([int]$ProcessId)
  Initialize-WinNative
  $result = @()
  $callback = {
    param($hWnd, $lParam)
    [uint32]$winPid = 0
    [void][M18WinNative]::GetWindowThreadProcessId($hWnd, [ref]$winPid)
    if ($winPid -eq $ProcessId -and [M18WinNative]::IsWindowVisible($hWnd)) {
      $title = New-Object System.Text.StringBuilder 512
      [void][M18WinNative]::GetWindowText($hWnd, $title, 512)
      $script:M18WindowList.Add([pscustomobject]@{ Handle = $hWnd; Title = $title.ToString() })
    }
    return $true
  }
  $script:M18WindowList = New-Object System.Collections.ArrayList
  [void][M18WinNative]::EnumWindows([M18WinNative+EnumWindowsProc]$callback, [IntPtr]::Zero)
  return @($script:M18WindowList)
}

function Start-AppProcess {
  param(
    [Parameter(Mandatory=$true)][string]$ExePath,
    [string]$WorkingDir = '',
    [hashtable]$EnvOverrides = @{}
  )
  if (-not (Test-Path -LiteralPath $ExePath)) { throw "Release exe not found: $ExePath" }
  foreach ($key in $EnvOverrides.Keys) {
    Set-Item -Path ("Env:" + $key) -Value $EnvOverrides[$key]
  }
  if ([string]::IsNullOrWhiteSpace($WorkingDir)) { $WorkingDir = Split-Path -Parent $ExePath }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $ExePath
  $psi.WorkingDirectory = $WorkingDir
  $psi.UseShellExecute = $true
  $psi.RedirectStandardError = $false
  $psi.RedirectStandardOutput = $false
  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  $started = $proc.Start()
  if (-not $started) { throw "Failed to start process: $ExePath" }
  return $proc
}

function Wait-MainWindow {
  param(
    [Parameter(Mandatory=$true)]$Process,
    [int]$TimeoutSec = 60,
    [string]$TitleProbe = ''
  )
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
    try { $Process.Refresh() } catch { }
    if ($Process.HasExited) {
      return [ordered]@{ found = $false; exitedDuringWait = $true; exitCode = $Process.ExitCode; handle = [IntPtr]::Zero; title = ''; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
    }
    try {
      $handle = $Process.MainWindowHandle
      if ($handle -ne [IntPtr]::Zero) {
        $title = $Process.MainWindowTitle
        if ([string]::IsNullOrWhiteSpace($TitleProbe) -or $title -like "*$TitleProbe*") {
          return [ordered]@{ found = $true; exitedDuringWait = $false; exitCode = $null; handle = $handle; title = $title; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
        }
      }
    } catch { }
    Start-Sleep -Milliseconds 250
  }
  return [ordered]@{ found = $false; exitedDuringWait = $false; exitCode = $null; handle = [IntPtr]::Zero; title = ''; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
}

function Send-WmClose {
  param([IntPtr]$Handle)
  Initialize-WinNative
  return [M18WinNative]::PostMessage($Handle, $script:M18_WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
}

function Wait-ProcessExit {
  param(
    [Parameter(Mandatory=$true)]$Process,
    [int]$TimeoutSec = 30
  )
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
    try {
      $Process.Refresh()
      if ($Process.HasExited) {
        return [ordered]@{ exited = $true; exitCode = $Process.ExitCode; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); timedOut = $false }
      }
    } catch {
      return [ordered]@{ exited = $true; exitCode = $null; seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); timedOut = $false }
    }
    Start-Sleep -Milliseconds 250
  }
  return [ordered]@{ exited = $false; exitCode = $null; seconds = $TimeoutSec; timedOut = $true }
}

function Get-DescendantProcessIds {
  param([int]$RootPid)
  $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Select-Object ProcessId, ParentProcessId)
  $children = New-Object System.Collections.Generic.HashSet[int]
  [void]$children.Add($RootPid)
  $changed = $true
  while ($changed) {
    $changed = $false
    foreach ($p in $all) {
      if ([int]$p.ParentProcessId -in @($children) -and -not $children.Contains([int]$p.ProcessId)) {
        [void]$children.Add([int]$p.ProcessId)
        $changed = $true
      }
    }
  }
  return @($children)
}

function Get-LiveDescendantIds {
  param([int]$RootPid)
  $desc = @(Get-DescendantProcessIds -RootPid $RootPid)
  $live = @()
  foreach ($childId in $desc) {
    if ($childId -eq $RootPid) { continue }
    $p = Get-Process -Id $childId -ErrorAction SilentlyContinue
    if ($null -ne $p) { $live += $childId }
  }
  return $live
}

# One full cycle. Returns an [ordered] record (ConvertTo-Json friendly).
function Invoke-CloseCycle {
  param(
    [Parameter(Mandatory=$true)][string]$ExePath,
    [string]$RunId,
    [string]$Scenario = 'default',
    [int]$WindowTimeoutSec = 60,
    [int]$ExitTimeoutSec = 30,
    [string]$TitleProbe = ''
  )
  $record = [ordered]@{
    runId = $RunId
    scenario = $Scenario
    exe = $ExePath
    launchUtc = $null
    windowFoundAtUtc = $null
    closeSentAtUtc = $null
    exitUtc = $null
    pid = $null
    windowHandle = $null
    windowTitle = ''
    windowFound = $false
    exitedDuringWait = $false
    closePosted = $false
    exited = $false
    exitCode = $null
    crashCode = $null
    exitSeconds = $null
    timedOut = $false
    lingeringPids = @()
    method = 'WM_CLOSE'
    forcedKillUsed = $false
    ok = $false
  }

  $record.launchUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  $proc = $null
  try {
    $proc = Start-AppProcess -ExePath $ExePath
  } catch {
    $record.ok = $false
    return $record
  }
  try { $record.pid = $proc.Id } catch { }

  try {
    $win = Wait-MainWindow -Process $proc -TimeoutSec $WindowTimeoutSec -TitleProbe $TitleProbe
  } catch {
    $win = [ordered]@{ found = $false; exitedDuringWait = $false; exitCode = $null; handle = [IntPtr]::Zero; title = ''; seconds = 0 }
  }

  if (-not $win.found) {
    $record.windowFound = $false
    if ($win.exitedDuringWait) { $record.exitedDuringWait = $true; $record.exitCode = $win.exitCode; $record.crashCode = $win.exitCode }
    if (-not $proc.HasExited) {
      $record.timedOut = $true
    }
    $record.ok = $false
    return $record
  }

  $record.windowFound = $true
  $record.windowFoundAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  $record.windowHandle = $win.handle
  $record.windowTitle = $win.title

  $record.closeSentAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  $record.closePosted = Send-WmClose -Handle $win.handle

  $exitState = Wait-ProcessExit -Process $proc -TimeoutSec $ExitTimeoutSec
  $record.exitUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  $record.exited = $exitState.exited
  $record.exitCode = $exitState.exitCode
  $record.exitSeconds = $exitState.seconds
  $record.timedOut = $exitState.timedOut

  $crashCodes = @(0xC0000005, 0xC0000409, 0xC00000FD, 0x80000003)
  if ($record.exitCode -is [int] -and $record.exitCode -in $crashCodes) {
    $record.crashCode = $record.exitCode
  } elseif ($null -ne $record.exitCode -and [int64]$record.exitCode -lt 0) {
    # Negative exit codes are NTSTATUS crash signatures (e.g. -1073741819 = 0xC0000005)
    $record.crashCode = $record.exitCode
  }

  $record.lingeringPids = @(Get-LiveDescendantIds -RootPid $record.pid)

  $record.ok = ($record.exited -and -not $record.timedOut -and $null -eq $record.crashCode -and $record.lingeringPids.Count -eq 0 -and -not $record.forcedKillUsed)

  return $record
}

# Exit code -> hex NTSTATUS helper
function Format-ExitCode {
  param($Code)
  if ($null -eq $Code) { return 'null' }
  # Two's-complement low 32 bits -> correct hex for negative NTSTATUS codes.
  return ('0x{0:X8}' -f ($Code -band 0xFFFFFFFF))
}
