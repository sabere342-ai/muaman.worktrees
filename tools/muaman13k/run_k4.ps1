# MUAMAN-13K K4 negative preflight control driver.
# Proves the control property of the hardened wrapper: when FileTracker state
# validation fails, the wrapper MUST refuse to invoke the build.
#
# Three sub-checks:
#   A. Harness injection: inject an empty static into the REAL Microsoft.Build
#      .Utilities.Core assembly in-process, then run the COMMITTED
#      check_filetracker_state.ps1 in the SAME process. Preflight must exit 1
#      with a diagnostic naming the injected field. (Proves the preflight
#      detects the exact crash condition.)
#   B. Wrapper refusal: run the committed build_hardened.ps1 with a
#      MsBuildBinDir that lacks Microsoft.Build.Utilities.Core.dll so the
#      committed preflight fails (exit 1) in its fresh process. The wrapper must
#      exit non-zero and must NOT create build evidence (02-pubget.log,
#      03-build.log, 05-analysis.json) nor any Release payload. (Proves the
#      wrapper never builds when preflight fails.)
#   C. Recovery: run the committed preflight normally; it must exit 0. The
#      negative condition is then removed (no persistent mutation exists).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File run_k4.ps1 ^
#       -Tools13k <dir> -EvidenceDir <dir> [-MsBuildBinDir <dir>] [-ProbeFile <path>]

param(
  [Parameter(Mandatory=$true)][string]$Tools13k,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [string]$MsBuildBinDir = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64',
  [string]$ProbeFile = 'C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app\build\windows\x64\CMakeFiles\4.2.3-msvc3\CompilerIdCXX\CMakeCXXCompilerId.cpp'
)
$ErrorActionPreference = 'Stop'

$Tools13k = [System.IO.Path]::GetFullPath($Tools13k)
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
$MsBuildBinDir = [System.IO.Path]::GetFullPath($MsBuildBinDir)
$ProbeFile = [System.IO.Path]::GetFullPath($ProbeFile)
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

$preflight = Join-Path $Tools13k '..\muaman13j\check_filetracker_state.ps1'
$wrapper   = Join-Path $Tools13k '..\muaman13j\build_hardened.ps1'
$harness   = Join-Path $Tools13k 'k4_harness.ps1'
foreach ($p in @($preflight, $wrapper, $harness)) {
  if (-not (Test-Path -LiteralPath $p)) { Write-Error ("K4 tool missing: {0}" -f $p); exit 2 }
}

$summary = [ordered]@{
  phase = 'K4'
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  msBuildBinDir = $MsBuildBinDir
  probeFile = $ProbeFile
  checks = [ordered]@{}
}

# ---------- A. injection harness (committed preflight, in-process) ----------
foreach ($field in @('s_applicationDataPath', 's_tempPath')) {
  $aLog = Join-Path $EvidenceDir ("a-inject-{0}.log" -f $field)
  $aErr = Join-Path $EvidenceDir ("a-inject-{0}-stderr.log" -f $field)
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $harness `
    -MsBuildBinDir $MsBuildBinDir -ProbeFile $ProbeFile -InjectField $field -PreflightScript $preflight `
    *> $aLog
  $aExit = $LASTEXITCODE
  $aText = Get-Content -LiteralPath $aLog -Raw
  $aDetected = ($aExit -eq 1) -and ($aText -match ('{0} is empty' -f $field)) -and ($aText -match 'PREFLIGHT: FAILED')
  $summary.checks['A_' + $field] = [ordered]@{
    exitCode = $aExit
    detectedEmptyStatic = [bool]$aDetected
  }
}

# ---------- B. wrapper refusal (preflight fails => no build) ----------
# Uses a TEST-SEAM COPY of the committed wrapper dir (removed afterward, inert
# in production): build_hardened.ps1 is byte-identical to the committed file,
# and its check_filetracker_state.ps1 is a seam that injects the real crash
# condition (empty FileTracker static) into the REAL Microsoft.Build assembly
# and then runs the COMMITTED preflight IN THE SAME PROCESS. The committed
# preflight therefore emits its normal stdout diagnostics ("... is empty",
# "PREFLIGHT: FAILED") and exits 1; the unchanged wrapper control flow must then
# refuse to invoke the build.
$bEvDir = Join-Path $EvidenceDir 'b-wrapper-refusal'
$bTools = Join-Path $EvidenceDir 'b-tools-seam'
New-Item -ItemType Directory -Path $bEvDir -Force | Out-Null
New-Item -ItemType Directory -Path $bTools -Force | Out-Null
$bWrapper = Join-Path $bTools 'build_hardened.ps1'
Copy-Item -LiteralPath $wrapper -Destination $bWrapper -Force
$bSeamPreflight = Join-Path $bTools 'check_filetracker_state.ps1'
function Esc-Single([string]$s) { return $s.Replace("'", "''") }
$bSeamTpl = @'
# MUAMAN-13K K4-B TEST SEAM (removed after run; never used in production builds).
# Injects an empty FileTracker static, then runs the COMMITTED preflight in-process.
param($MsBuildBinDir = '__MSBBIN__', $ProbeFile = '__PROBE__')
$ErrorActionPreference = 'Continue'
$utilDll = Join-Path $MsBuildBinDir 'Microsoft.Build.Utilities.Core.dll'
$asm = [System.Reflection.Assembly]::LoadFrom($utilDll)
$ft = $asm.GetType('Microsoft.Build.Utilities.FileTracker', $true)
$f = $ft.GetField('s_applicationDataPath', [System.Reflection.BindingFlags]'Static,NonPublic,Public')
$f.SetValue($null, '')
Write-Output 'K4-B seam: injected empty static, invoking committed preflight in-process...'
& '__REALPREFLIGHT__' -MsBuildBinDir $MsBuildBinDir -ProbeFile $ProbeFile
exit $LASTEXITCODE
'@
$bSeam = $bSeamTpl.Replace('__MSBBIN__', (Esc-Single $MsBuildBinDir)).Replace('__PROBE__', (Esc-Single $ProbeFile)).Replace('__REALPREFLIGHT__', (Esc-Single $preflight))
Set-Content -LiteralPath $bSeamPreflight -Value $bSeam -Encoding UTF8

$bCmd = Join-Path $EvidenceDir 'b-command.txt'
# Safe scratch roots INSIDE the evidence tree: the wrapper hardens TmpRoot and
# HomeRoot by creating <root>\appdata\roaming and <root>\appdata\local, so they
# must be writable dirs we own, not SystemRoot.
$bScratch = Join-Path $EvidenceDir 'b-scratch'
New-Item -ItemType Directory -Path $bScratch -Force | Out-Null
$bApp = Join-Path $bScratch 'app'; New-Item -ItemType Directory -Path $bApp -Force | Out-Null
$bSdk = Join-Path $bScratch 'sdk'; New-Item -ItemType Directory -Path $bSdk -Force | Out-Null
$bPub = Join-Path $bScratch 'pub'; New-Item -ItemType Directory -Path $bPub -Force | Out-Null
$bTmp = Join-Path $bScratch 'tmp'; New-Item -ItemType Directory -Path $bTmp -Force | Out-Null
$bHome = Join-Path $bScratch 'home'; New-Item -ItemType Directory -Path $bHome -Force | Out-Null
"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$bWrapper`" -ExperimentId K4B -AppRoot `"$bApp`" -SdkRoot `"$bSdk`" -PubCache `"$bPub`" -TmpRoot `"$bTmp`" -HomeRoot `"$bHome`" -EvidenceDir `"$bEvDir`" -MsBuildBinDir `"$MsBuildBinDir`"" | Set-Content -LiteralPath $bCmd -Encoding UTF8

$bExitFile = Join-Path $EvidenceDir 'b-wrapper-exit-code.txt'
$bShim = Join-Path $EvidenceDir 'b-run-wrapper.ps1'
$bArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$bWrapper,
  '-ExperimentId','K4B','-AppRoot',$bApp,'-SdkRoot',$bSdk,
  '-PubCache',$bPub,'-TmpRoot',$bTmp,'-HomeRoot',$bHome,
  '-EvidenceDir',$bEvDir,'-MsBuildBinDir',$MsBuildBinDir)
# Start-Process joins -ArgumentList with spaces WITHOUT adding quotes, so any
# value containing spaces or parentheses must carry literal double-quote chars
# as part of the string VALUE. Emit such values as a single-quoted literal
# whose content is "path" (the quotes survive into the child command line).
# Values without spaces are emitted as plain single-quoted literals.
$esc = $bArgs | ForEach-Object {
  if ($_ -match '\s|\(|\)') { "'" + '"' + $_ + '"' + "'" } else { "'" + $_.Replace("'", "''") + "'" }
}
$shimTpl = @'
$ErrorActionPreference = 'Continue'
$proc = Start-Process -FilePath 'powershell.exe' -ArgumentList @(__ARGS__) -PassThru -WindowStyle Hidden
$proc.WaitForExit()
Set-Content -LiteralPath '__EXITFILE__' -Value ('{0}' -f $proc.ExitCode) -Encoding UTF8
'@
$shimContent = $shimTpl.Replace('__ARGS__', ($esc -join ',')).Replace('__EXITFILE__', (Esc-Single $bExitFile))
Set-Content -LiteralPath $bShim -Value $shimContent -Encoding UTF8
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bShim
$bExit = if (Test-Path -LiteralPath $bExitFile) { [int](Get-Content -LiteralPath $bExitFile -Raw).Trim() } else { -1 }

# Wrapper writes 00-hardened-env.json and 01-preflight.log only; build evidence
# must be absent.
$bPubGet = Test-Path -LiteralPath (Join-Path $bEvDir '02-pubget.log')
$bBuild  = Test-Path -LiteralPath (Join-Path $bEvDir '03-build.log')
$bAnalysis = Test-Path -LiteralPath (Join-Path $bEvDir '05-analysis.json')
$bPreflightLog = Join-Path $bEvDir '01-preflight.log'
$bPreflightText = if (Test-Path -LiteralPath $bPreflightLog) { Get-Content -LiteralPath $bPreflightLog -Raw } else { '<missing>' }
$bRefused = ($bExit -ne 0) -and (-not $bPubGet) -and (-not $bBuild) -and (-not $bAnalysis) -and
            ($bPreflightText -match 'PREFLIGHT: FAILED') -and ($bPreflightText -match 'is empty')
$summary.checks['B_wrapper_refuses_build'] = [ordered]@{
  exitCode = $bExit
  preflightFailed = [bool]($bPreflightText -match 'PREFLIGHT: FAILED')
  diagnosticNamesEmptyStatic = [bool]($bPreflightText -match 'is empty')
  buildInvoked_pubgetPresent = [bool]$bPubGet
  buildInvoked_buildLogPresent = [bool]$bBuild
  buildInvoked_analysisPresent = [bool]$bAnalysis
  buildRefused = [bool]$bRefused
  seamRemoved = $false
}

# ---------- C. recovery: positive preflight succeeds ----------
$cLog = Join-Path $EvidenceDir 'c-recovery-positive-preflight.log'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflight `
  -MsBuildBinDir $MsBuildBinDir -ProbeFile $ProbeFile *> $cLog
$cExit = $LASTEXITCODE
$cText = Get-Content -LiteralPath $cLog -Raw
$cOk = ($cExit -eq 0) -and ($cText -match 'PREFLIGHT: OK')
$summary.checks['C_recovery_positive_preflight'] = [ordered]@{
  exitCode = $cExit
  preflightOk = [bool]$cOk
}

# ---------- cleanup: remove the test-only seam ----------
# Remove the seam (wrapper copy + injected preflight) so the negative condition
# is gone and nothing inert-but-dangerous remains on disk. Done BEFORE the
# summary evaluation so seamRemoved reflects the final state.
$seamRemoved = $true
foreach ($d in @($bTools, $bScratch)) {
  if (Test-Path -LiteralPath $d) {
    try {
      Remove-Item -LiteralPath $d -Recurse -Force
      if (Test-Path -LiteralPath $d) { $seamRemoved = $false }
    } catch { $seamRemoved = $false }
  }
}
if ($summary.checks.Contains('B_wrapper_refuses_build')) {
  $summary.checks['B_wrapper_refuses_build'].seamRemoved = $seamRemoved
}

# ---------- summary ----------
$allPass = $true
$excludedNames = @('exitCode','preflightFailed','buildInvoked_pubgetPresent','buildInvoked_buildLogPresent','buildInvoked_analysisPresent','fileCount','totalBytes')
foreach ($k in $summary.checks.Keys) {
  $c = $summary.checks[$k]
  foreach ($pn in $c.Keys) {
    if ($pn -in $excludedNames) { continue }
    if ($c[$pn] -is [bool] -and -not [bool]$c[$pn]) { $allPass = $false }
  }
}
if (-not $seamRemoved) { $allPass = $false }

$summary.k4Pass = $allPass
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceDir 'k4-summary.json') -Encoding UTF8

Write-Output ("MUAMAN-13K K4: pass={0}" -f $allPass)
if (-not $allPass) {
  Write-Output ("A(applicationData)={0} A(tempPath)={1} B(refused)={2} C(recovery)={3} seamRemoved={4}" -f `
    $summary.checks['A_s_applicationDataPath'].detectedEmptyStatic, `
    $summary.checks['A_s_tempPath'].detectedEmptyStatic, `
    $summary.checks['B_wrapper_refuses_build'].buildRefused, `
    $summary.checks['C_recovery_positive_preflight'].preflightOk, `
    $seamRemoved)
  exit 1
}
exit 0
