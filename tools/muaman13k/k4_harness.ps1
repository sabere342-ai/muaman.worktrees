# MUAMAN-13K K4 negative preflight control harness.
# Injects a deliberately-empty FileTracker exclusion-path static into the REAL
# Microsoft.Build.Utilities.Core assembly instance loaded in this process, then
# runs the COMMITTED check_filetracker_state.ps1 IN THE SAME PROCESS (via `&`)
# so the injected static is observed as empty by the real validation logic.
#
# Because statics are per-process and LoadFrom() returns the already-loaded
# assembly instance, the mutation is visible to the committed preflight and
# cannot persist outside this process. The preflight's `exit` terminates this
# harness process, so the harness exit code IS the preflight exit code.
#
# This is a TEST-ONLY seam: it exists only in the 13K tooling tree and is never
# part of the production wrapper invocation. No installed MSBuild or SDK file is
# modified.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File k4_harness.ps1 ^
#       -MsBuildBinDir <dir> -ProbeFile <path> -InjectField <name> ^
#       -PreflightScript <path-to-committed-check_filetracker_state.ps1>

param(
  [string]$MsBuildBinDir = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64',
  [string]$ProbeFile = 'C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app\build\windows\x64\CMakeFiles\4.2.3-msvc3\CompilerIdCXX\CMakeCXXCompilerId.cpp',
  [Parameter(Mandatory=$true)][string]$InjectField,
  [Parameter(Mandatory=$true)][string]$PreflightScript
)
$ErrorActionPreference = 'Continue'

$utilDll = Join-Path $MsBuildBinDir 'Microsoft.Build.Utilities.Core.dll'
if (-not (Test-Path -LiteralPath $utilDll)) {
  Write-Error ("Microsoft.Build.Utilities.Core.dll not found under: {0}" -f $MsBuildBinDir)
  exit 2
}

Write-Output ("K4 harness: injecting empty value into FileTracker.{0} (in-process, process {1})" -f $InjectField, $PID)
$asm = [System.Reflection.Assembly]::LoadFrom($utilDll)
$ft = $asm.GetType('Microsoft.Build.Utilities.FileTracker', $true)
$f = $ft.GetField($InjectField, [System.Reflection.BindingFlags]'Static,NonPublic,Public')
if ($null -eq $f) {
  Write-Error ("K4 harness: field {0} not found on FileTracker" -f $InjectField)
  exit 2
}
$f.SetValue($null, '')
Write-Output "K4 harness: injection applied; invoking committed preflight in this process..."
Write-Output "--------------------------------------------------------------"

# In-process invocation: the committed preflight will LoadFrom() the SAME
# already-loaded assembly, observe the injected empty static, and exit 1.
& $PreflightScript -MsBuildBinDir $MsBuildBinDir -ProbeFile $ProbeFile
exit $LASTEXITCODE
