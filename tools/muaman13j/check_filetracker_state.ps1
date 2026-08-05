# MUAMAN-13J FileTracker state preflight.
# Runs in a FRESH process (spawned by build_hardened.ps1 after the environment
# has been hardened) and asserts that every FileTracker exclusion-path static
# resolves to a non-empty string, plus the raw Environment producers.
#
# An empty static is the proven trigger of the original MSB4018
# IndexOutOfRangeException in Microsoft.Build.Utilities.FileTracker.
# This script fails fast (exit 1) with per-field diagnostics if any static is
# empty, so a build can never silently run under a FileTracker state that is
# known to crash the CL tracked-input post-step.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File check_filetracker_state.ps1 ^
#       [-MsBuildBinDir <dir>] [-ProbeFile <path>]

param(
  [string]$MsBuildBinDir = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64',
  [string]$ProbeFile = 'C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app\build\windows\x64\CMakeFiles\4.2.3-msvc3\CompilerIdCXX\CMakeCXXCompilerId.cpp'
)
$ErrorActionPreference = 'Stop'

$utilDll = Join-Path $MsBuildBinDir 'Microsoft.Build.Utilities.Core.dll'
if (-not (Test-Path -LiteralPath $utilDll)) {
  Write-Error ("Microsoft.Build.Utilities.Core.dll not found under: {0}" -f $MsBuildBinDir)
  exit 1
}

# ---- raw producers ---------------------------------------------------------
$producers = [ordered]@{
  'GetTempPath()'                        = [System.IO.Path]::GetTempPath()
  'GetFolderPath(ApplicationData)'       = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
  'GetFolderPath(LocalApplicationData)'  = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
  'GetFolderPath(CommonApplicationData)' = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData)
  'GetFolderPath(UserProfile)'           = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
}
$bad = @()
foreach ($k in $producers.Keys) {
  $v = [string]$producers[$k]
  Write-Output ("{0} = [{1}]" -f $k, $v)
  if ([string]::IsNullOrEmpty($v)) { $bad += ("{0} is empty" -f $k) }
}

# ---- FileTracker statics ---------------------------------------------------
$asm = [System.Reflection.Assembly]::LoadFrom($utilDll)
$ft = $asm.GetType('Microsoft.Build.Utilities.FileTracker', $true)
$fields = @(
  's_tempPath', 's_tempShortPath', 's_tempLongPath',
  's_applicationDataPath', 's_localApplicationDataPath', 's_localLowApplicationDataPath',
  's_commonApplicationDataPaths'
)
foreach ($name in $fields) {
  $f = $ft.GetField($name, [System.Reflection.BindingFlags]'Static,NonPublic,Public')
  if ($null -eq $f) { $bad += ("{0}: field not found" -f $name); Write-Output ("FileTracker.{0} = [<missing>]" -f $name); continue }
  $v = $f.GetValue($null)
  if ($name -eq 's_commonApplicationDataPaths') {
    $list = @($v)
    if ($list.Count -eq 0) {
      $bad += 's_commonApplicationDataPaths is an empty list'
      Write-Output 'FileTracker.s_commonApplicationDataPaths = [<empty list>]'
    } else {
      $joined = ($list | ForEach-Object { "'{0}'" -f $_.ToString() }) -join ', '
      Write-Output ("FileTracker.s_commonApplicationDataPaths = [{0}]" -f $joined)
      foreach ($e in $list) {
        if ([string]::IsNullOrEmpty([string]$e)) { $bad += 's_commonApplicationDataPaths contains an empty entry' }
      }
    }
  } else {
    $s = [string]$v
    Write-Output ("FileTracker.{0} = [{1}]" -f $name, $s)
    if ([string]::IsNullOrEmpty($s)) { $bad += ("{0} is empty" -f $name) }
  }
}

# ---- optional live probe of the exact crash method --------------------------
if ($ProbeFile -and (Test-Path -LiteralPath $ProbeFile)) {
  $excl = $ft.GetMethod('FileIsExcludedFromDependencies', [System.Reflection.BindingFlags]'Static,NonPublic,Public')
  try {
    $res = $excl.Invoke($null, [object[]]@($ProbeFile))
    Write-Output ("FileIsExcludedFromDependencies('{0}') = {1} (no exception)" -f $ProbeFile, $res)
  } catch {
    $inner = $_.Exception.InnerException
    if ($null -eq $inner) { $inner = $_.Exception }
    $bad += ("FileIsExcludedFromDependencies threw: {0}: {1}" -f $inner.GetType().Name, $inner.Message)
    Write-Output ("FileIsExcludedFromDependencies('{0}') THREW {1}: {2}" -f $ProbeFile, $inner.GetType().Name, $inner.Message)
  }
} elseif ($ProbeFile) {
  Write-Output ("ProbeFile not found (skipping live probe): {0}" -f $ProbeFile)
}

if ($bad.Count -gt 0) {
  Write-Output ''
  Write-Output 'PREFLIGHT: FAILED'
  foreach ($b in $bad) { Write-Output ("  - {0}" -f $b) }
  exit 1
}
Write-Output ''
Write-Output 'PREFLIGHT: OK - all FileTracker statics and producers are non-empty'
exit 0
