# MUAMAN-13L phase guard harness.
#
# Runs the light, focused 13L guards:
#   L1 static delegation guard      entrypoint has no second FileTracker/build
#                                   implementation and delegates to the committed
#                                   source of truth
#   L2 CWD independence             entrypoint resolves the SAME repository root
#                                   from repo root / sub-folder / outside repo
#   L3 preflight ordering           preflight is source-ordered and gated before
#                                   the wrapper; environment refusal is fail-closed
#   L4 secret hygiene               committed-tree scan for OPENCODE_SERVER_* values
#   L5 historical guards            MUAMAN-13K guard_tests.ps1 in a fresh process,
#                                   output outside the repository
#   L7 release verification         fresh release vs committed 13K legal manifest
#                                   (run only when -ReleaseDir is provided)
#   L8 active-docs guard            the active release doc must use the canonical
#                                   command and must not direct users to run
#                                   `flutter build windows --release` directly
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File guard_tests_13l.ps1 ^
#       -RepoRoot <dir> -Out <json> [-EvidenceOut <dir>] ^
#       [-ReleaseDir <dir>] [-CompareReleaseA <dir>] [-TempRoot <dir>]

param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$EvidenceOut = '',
  [string]$ReleaseDir = '',
  [string]$CompareReleaseA = '',
  [string]$TempRoot = ''
)
$ErrorActionPreference = 'Stop'

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Out = [System.IO.Path]::GetFullPath($Out)
if ([string]::IsNullOrWhiteSpace($EvidenceOut)) { $EvidenceOut = Split-Path -Parent $Out }
$EvidenceOut = [System.IO.Path]::GetFullPath($EvidenceOut)
if ([string]::IsNullOrWhiteSpace($TempRoot)) { $TempRoot = $env:TEMP }
$TempRoot = [System.IO.Path]::GetFullPath($TempRoot)

New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceOut -Force | Out-Null

$entrypoint = Join-Path $RepoRoot 'tools\release\build_windows_release.ps1'
$verifyTool = Join-Path $RepoRoot 'tools\release\verify_release.ps1'
$legalManifest = Join-Path $RepoRoot 'docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\release-manifest.json'
$activeDoc = Join-Path $RepoRoot 'docs\MUAMAN-13L-CANONICAL-HARDENED-WINDOWS-RELEASE-ENTRYPOINT.md'

$verdicts = [ordered]@{}

# ---------------------------------------------------------------------------
# L1 static delegation guard
# ---------------------------------------------------------------------------
function Get-L1Verdict {
  $bad = @()
  $required = @()
  $src = Get-Content -LiteralPath $entrypoint -Encoding UTF8
  $executable = @($src | Where-Object { $_ -notmatch '^\s*#' })
  $execText = $executable -join "`n"

  $forbidden = @(
    'Microsoft.Build.Utilities.FileTracker',
    'GetField(',
    'SetValue(',
    'LoadFrom(',
    'System.Reflection.Assembly',
    'FileIsExcludedFromDependencies',
    'FileIsUnderNormalizedPath',
    's_applicationDataPath',
    's_tempPath',
    's_tempShortPath',
    's_tempLongPath',
    's_localApplicationDataPath',
    's_localLowApplicationDataPath',
    's_commonApplicationDataPaths',
    'build windows --release'
  )
  foreach ($tok in $forbidden) {
    if ($execText -match [regex]::Escape($tok)) { $bad += "forbidden token in executable code: $tok" }
  }
  # no hard-coded absolute drive-letter paths in executable code
  if ($execText -match '(?m)^[^#].*[A-Za-z]:\\') { $bad += 'hard-coded absolute drive-letter path in executable code' }

  if ($execText -notmatch 'build_hardened\.ps1') { $bad += 'does not delegate to build_hardened.ps1 (source of truth)' }
  if ($execText -notmatch 'check_filetracker_state\.ps1') { $bad += 'does not invoke the committed preflight' }

  # required delegation references
  foreach ($r in @('build_hardened\.ps1', 'check_filetracker_state\.ps1')) {
    if ($execText -match $r) { $required += $r }
  }

  [ordered]@{
    guard = 'L1 static delegation (single source of truth)'
    pass = ($bad.Count -eq 0)
    failures = $bad
    delegationTargets = $required
  }
}
$verdicts['L1'] = Get-L1Verdict

# ---------------------------------------------------------------------------
# L2 CWD independence
# ---------------------------------------------------------------------------
function Invoke-FromCwd([string]$cwd, [string]$stdout, [string]$stderr) {
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$entrypoint,'-PreflightOnly')
  $esc = $args | ForEach-Object {
    if ($_ -match '\s|\(|\)') { "'" + '"' + $_ + '"' + "'" } else { "'" + $_.Replace("'", "''") + "'" }
  }
  $shim = Join-Path $TempRoot ('l2-run-{0}-{1}.ps1' -f $PID, [guid]::NewGuid().ToString('N').Substring(0,8))
  $shimContent = @"
`$proc = Start-Process -FilePath 'powershell.exe' -ArgumentList @($($esc -join ',')) -WorkingDirectory '$($cwd.Replace("'", "''"))' -PassThru -WindowStyle Hidden -RedirectStandardOutput '$($stdout.Replace("'", "''"))' -RedirectStandardError '$($stderr.Replace("'", "''"))'
`$proc.WaitForExit()
exit `$proc.ExitCode
"@
  Set-Content -LiteralPath $shim -Value $shimContent -Encoding UTF8
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $shim
  $code = $LASTEXITCODE
  Remove-Item -LiteralPath $shim -Force -ErrorAction SilentlyContinue
  return $code
}

function Get-L2Verdict {
  $outside = Join-Path $TempRoot 'l2-cwd-outside'
  New-Item -ItemType Directory -Path $outside -Force | Out-Null
  $cwds = [ordered]@{
    repositoryRoot = $RepoRoot
    subFolder = (Join-Path $RepoRoot 'tools\release')
    outsideRepository = $outside
  }
  $runs = [ordered]@{}
  $detectedRoots = @()
  $preflightExits = @()
  foreach ($k in $cwds.Keys) {
    $outFile = Join-Path $TempRoot ("l2-{0}-stdout.txt" -f $k)
    $errFile = Join-Path $TempRoot ("l2-{0}-stderr.txt" -f $k)
    foreach ($f in @($outFile, $errFile)) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }
    $code = Invoke-FromCwd $cwds[$k] $outFile $errFile
    $text = ''
    if (Test-Path -LiteralPath $outFile) { $text = Get-Content -LiteralPath $outFile -Raw }
    $m = [regex]::Match($text, 'repository root\s*:\s*(.+)')
    $detected = if ($m.Success) { $m.Groups[1].Value.Trim() } else { '' }
    $detectedRoots += $detected
    $preflightExits += $code
    $runs[$k] = [ordered]@{ cwd = $cwds[$k]; exitCode = $code; detectedRepositoryRoot = $detected; output = $text.Trim() }
  }
  $allSame = (($detectedRoots | Select-Object -Unique).Count -eq 1) -and ($detectedRoots[0] -eq $RepoRoot)
  $allPreflightOk = -not (($preflightExits | Where-Object { $_ -ne 0 }).Count -gt 0)

  $result = [ordered]@{
    guard = 'L2 CWD independence'
    expectedRepositoryRoot = $RepoRoot
    runs = $runs
    detectedRoots = @($detectedRoots)
    allResolvedSameRoot = $allSame
    allPreflightExitZero = $allPreflightOk
    pass = ($allSame -and $allPreflightOk)
  }
  $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceOut 'cwd-independence-results.json') -Encoding UTF8
  return $result
}
$verdicts['L2'] = Get-L2Verdict

# ---------------------------------------------------------------------------
# L3 preflight ordering (static source order + dynamic fail-closed refusal)
# ---------------------------------------------------------------------------
function Get-L3Verdict {
  $bad = @()
  $entryLines = Get-Content -LiteralPath $entrypoint -Encoding UTF8
  $preflightIdx = -1
  $wrapperIdx = -1
  for ($i = 0; $i -lt $entryLines.Count; $i++) {
    $l = $entryLines[$i]
    if ($l -notmatch '^\s*#') {
      if ($l -match '-File\s+\$preflightScript' -and $preflightIdx -lt 0) { $preflightIdx = $i }
      if ($l -match '-File\s+\$wrapperScript' -and $wrapperIdx -lt 0) { $wrapperIdx = $i }
    }
  }
  $ordered = ($preflightIdx -ge 0) -and ($wrapperIdx -ge 0) -and ($preflightIdx -lt $wrapperIdx)
  if (-not $ordered) { $bad += 'preflight invocation is not source-ordered before the wrapper invocation' }

  # fail-closed: an exit on preflight failure exists between the two calls
  $between = ''
  if ($preflightIdx -ge 0 -and $wrapperIdx -gt $preflightIdx) {
    $between = (($entryLines[($preflightIdx + 1)..($wrapperIdx - 1)]) -join "`n")
  }
  if ($between -notmatch 'exit 1') { $bad += 'no fail-closed exit 1 between preflight and wrapper invocation' }

  # source-of-truth ordering: build_hardened.ps1 runs preflight before the 13I runner
  $wrapperSrc = Get-Content -LiteralPath (Join-Path $RepoRoot 'tools\muaman13j\build_hardened.ps1') -Encoding UTF8
  $wPreflightIdx = -1
  $wRunnerIdx = -1
  for ($i = 0; $i -lt $wrapperSrc.Count; $i++) {
    $l = $wrapperSrc[$i]
    if ($l -notmatch '^\s*#') {
      if ($l -match 'check_filetracker_state\.ps1' -and $wPreflightIdx -lt 0) { $wPreflightIdx = $i }
      if ($l -match 'run_experiment\.ps1' -and $wRunnerIdx -lt 0) { $wRunnerIdx = $i }
    }
  }
  $sourceOfTruthOrdered = ($wPreflightIdx -ge 0) -and ($wRunnerIdx -ge 0) -and ($wPreflightIdx -lt $wRunnerIdx)
  if (-not $sourceOfTruthOrdered) { $bad += 'source of truth (build_hardened.ps1) does not order preflight before the runner' }

  # dynamic fail-closed: unusable MSBuild => non-zero exit and no build artifacts
  $probeStage = Join-Path $TempRoot ("l3-refusal-{0}" -f [guid]::NewGuid().ToString('N').Substring(0,8))
  $probeEvidence = Join-Path $probeStage 'evidence'
  New-Item -ItemType Directory -Path $probeEvidence -Force | Out-Null
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$entrypoint,
    '-PreflightOnly','-MsBuildBinDir',(Join-Path $probeStage 'no-such-msbuild'),
    '-StageRoot',$probeStage,'-EvidenceDir',$probeEvidence)
  $esc = $args | ForEach-Object {
    if ($_ -match '\s|\(|\)') { "'" + '"' + $_ + '"' + "'" } else { "'" + $_.Replace("'", "''") + "'" }
  }
  $shim = Join-Path $TempRoot ('l3-run-{0}.ps1' -f $PID)
  $shimContent = "`$proc = Start-Process -FilePath 'powershell.exe' -ArgumentList @($($esc -join ',')) -PassThru -WindowStyle Hidden -Wait`nexit `$proc.ExitCode"
  Set-Content -LiteralPath $shim -Value $shimContent -Encoding UTF8
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $shim
  $refusalExit = $LASTEXITCODE
  Remove-Item -LiteralPath $shim -Force -ErrorAction SilentlyContinue

  $wrapperArtifacts = @(
    (Join-Path $probeEvidence '00-hardened-env.json'),
    (Join-Path $probeEvidence '02-pubget.log'),
    (Join-Path $probeEvidence '03-build.log'),
    (Join-Path $probeEvidence 'release-dir.txt')
  )
  $anyWrapperArtifact = @($wrapperArtifacts | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
  $refused = ($refusalExit -ne 0) -and (-not $anyWrapperArtifact)

  $k4Summary = Join-Path $RepoRoot 'docs\evidence\muaman-13k\07-k4-negative-preflight-control\k4-summary.json'
  $k4Pass = $false
  if (Test-Path -LiteralPath $k4Summary) {
    $k4 = Get-Content -LiteralPath $k4Summary -Raw | ConvertFrom-Json
    $k4Pass = ($k4.k4Pass -eq $true)
  }

  if (-not $refused) { $bad += 'entrypoint did not fail closed with an unusable MSBuild directory' }
  if (-not $k4Pass) { $bad += 'committed K4 negative control no longer reports k4Pass' }

  [ordered]@{
    guard = 'L3 preflight ordering + fail-closed'
    pass = ($bad.Count -eq 0) -and $ordered -and $sourceOfTruthOrdered -and $refused -and $k4Pass
    failures = $bad
    entrypointPreflightLine = if ($preflightIdx -ge 0) { $preflightIdx + 1 } else { -1 }
    entrypointWrapperLine = if ($wrapperIdx -ge 0) { $wrapperIdx + 1 } else { -1 }
    preflightBeforeWrapper = $ordered
    failClosedExit1Present = ($between -match 'exit 1')
    sourceOfTruthPreflightBeforeRunner = $sourceOfTruthOrdered
    dynamic = [ordered]@{
      test = 'entrypoint -PreflightOnly -MsBuildBinDir <unusable>'
      exitCode = $refusalExit
      anyBuildOrWrapperArtifact = $anyWrapperArtifact
      failClosed = $refused
      committedK4NegativeControlPass = $k4Pass
    }
  }
}
$verdicts['L3'] = Get-L3Verdict

# ---------------------------------------------------------------------------
# L4 secret hygiene scan (working tree that becomes the commit tree)
# ---------------------------------------------------------------------------
function Get-L4Verdict {
  # Value-agnostic secret patterns: the live credential value is NOT embedded
  # here. The committed 13K evidence env dumps legitimately contain
  # `OPENCODE_SERVER_PASSWORD=<redacted>` (accepted at 13K) and
  # `OPENCODE_SERVER_USERNAME=opencode`; pattern 1 requires a real value after
  # the password key and pattern 2 requires a UUID-shaped secret stored under a
  # secret-ish key, so neither flags that accepted baseline.
  $patterns = @(
    'OPENCODE_SERVER_PASSWORD\s*=\s*[^<\s][^\r\n]*',
    '(?i)(password|passwd|secret|token|api[_ ]?key|credential)\s*[:=]\s*[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
  )
  $files = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\\.git\\' }
  $findings = @()
  $scanned = 0
  foreach ($f in $files) {
    $scanned++
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $ascii = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
    foreach ($pat in $patterns) {
      if ($ascii -match $pat) {
        $findings += [pscustomobject]@{ file = $f.FullName.Substring($RepoRoot.Length).TrimStart('\').Replace('\','/'); pattern = $pat; encoding = 'ASCII' }
      }
      if ($utf16 -match $pat) {
        $findings += [pscustomobject]@{ file = $f.FullName.Substring($RepoRoot.Length).TrimStart('\').Replace('\','/'); pattern = $pat; encoding = 'UTF-16LE' }
      }
    }
  }
  $result = [ordered]@{
    guard = 'L4 secret hygiene'
    scannedFiles = $scanned
    findingCount = $findings.Count
    findings = $findings
    clean = ($findings.Count -eq 0)
    pass = ($findings.Count -eq 0)
  }
  $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $EvidenceOut 'secrecy-scan.json') -Encoding UTF8
  return $result
}
$verdicts['L4'] = Get-L4Verdict

# ---------------------------------------------------------------------------
# L5 historical guards (fresh process, output outside the repository)
# ---------------------------------------------------------------------------
function Get-L5Verdict {
  $freshOut = Join-Path $TempRoot 'guard-results-13k-fresh.json'
  if (Test-Path -LiteralPath $freshOut) { Remove-Item -LiteralPath $freshOut -Force }
  $guard13k = Join-Path $RepoRoot 'tools\muaman13k\guard_tests.ps1'
  $evidence13k = Join-Path $RepoRoot 'docs\evidence\muaman-13k'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $guard13k -EvidenceRoot $evidence13k -Out $freshOut | Out-Null
  $exit5 = $LASTEXITCODE
  $allPass5 = $false
  if (Test-Path -LiteralPath $freshOut) {
    $g = Get-Content -LiteralPath $freshOut -Raw | ConvertFrom-Json
    $allPass5 = ($g.allPass -eq $true)
  }
  # keep a copy of the fresh run inside the evidence dir (outside the repo is the original)
  Copy-Item -LiteralPath $freshOut -Destination (Join-Path $EvidenceOut 'guard-results-13k-fresh.json') -Force
  [ordered]@{
    guard = 'L5 historical MUAMAN-13K guards (fresh process)'
    pass = ($exit5 -eq 0) -and $allPass5
    exitCode = $exit5
    allPass = $allPass5
    freshOutputPath = $freshOut
  }
}
$verdicts['L5'] = Get-L5Verdict

# ---------------------------------------------------------------------------
# L7 release verification (only when a release dir is supplied)
# ---------------------------------------------------------------------------
function Get-L7Verdict {
  if ([string]::IsNullOrWhiteSpace($ReleaseDir)) {
    return [ordered]@{ guard = 'L7 release verification vs MUAMAN-13K'; pass = $null; status = 'not-run'; detail = 'no -ReleaseDir supplied' }
  }
  $verifyOut = Join-Path $EvidenceOut 'release-comparison.json'
  $ca = ''
  if (-not [string]::IsNullOrWhiteSpace($CompareReleaseA)) { $ca = $CompareReleaseA }
  $invokeArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$verifyTool,
    '-ReleaseDir',$ReleaseDir,'-LegalManifest',$legalManifest,'-Out',$verifyOut)
  if ($ca) { $invokeArgs += @('-CompareReleaseA', $ca) }
  & powershell.exe @invokeArgs
  $exit7 = $LASTEXITCODE
  $v = Get-Content -LiteralPath $verifyOut -Raw | ConvertFrom-Json
  $legalToolOk = $true
  if ($v.PSObject.Properties.Name -contains 'legalToolCompare') {
    $legalToolOk = ($v.legalToolCompare.identical -eq $true) -and ($v.legalToolCompare.crossHashMatch -eq $true)
  }
  [ordered]@{
    guard = 'L7 release verification vs MUAMAN-13K legal manifest'
    pass = ($exit7 -eq 0) -and ($v.identical -eq $true) -and $legalToolOk
    exitCode = $exit7
    fileCount = $v.fileCountNew
    totalBytes = $v.totalBytesNew
    diffCount = $v.diffCount
    crossHash = $v.crossHashNew
    legalToolComparePass = $legalToolOk
    output = $verifyOut
  }
}
$verdicts['L7'] = Get-L7Verdict

# ---------------------------------------------------------------------------
# L8 active-docs guard
# ---------------------------------------------------------------------------
function Get-L8Verdict {
  $bad = @()
  $missing = $false
  if (-not (Test-Path -LiteralPath $activeDoc)) {
    $bad += ('active release doc missing: {0}' -f $activeDoc)
    $missing = $true
  }
  $docText = if ($missing) { '' } else { Get-Content -LiteralPath $activeDoc -Raw }
  $hasCanonicalCommand = $docText -match 'tools[/\\]release[/\\]build_windows_release\.ps1'
  if (-not $hasCanonicalCommand) { $bad += 'active doc does not document the canonical command tools\release\build_windows_release.ps1' }
  $mentionsDirect = $docText -match 'flutter build windows --release'
  $declaresUnsupported = $docText -match '(?i)NOT.{0,12}the supported release (command|path)' -or $docText -match 'غير معتمد'
  if ($mentionsDirect -and -not $declaresUnsupported) {
    $bad += 'active doc mentions the direct command without declaring it unsupported'
  }
  [ordered]@{
    guard = 'L8 active release docs use the canonical command'
    pass = ($bad.Count -eq 0)
    failures = $bad
    activeDocs = @($activeDoc)
    canonicalCommandDocumented = $hasCanonicalCommand
    directCommandMentioned = $mentionsDirect
    directCommandDeclaredUnsupported = $declaresUnsupported
  }
}
$verdicts['L8'] = Get-L8Verdict

# ---------------------------------------------------------------------------
# aggregate
# ---------------------------------------------------------------------------
$allPass = $true
foreach ($k in $verdicts.Keys) {
  $v = $verdicts[$k]
  if ($null -ne $v.pass -and -not [bool]$v.pass) { $allPass = $false }
}

$result = [ordered]@{
  phase = 'MUAMAN-13L guard-point verification'
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  allPass = $allPass
  verdicts = $verdicts
}
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Out -Encoding UTF8
Write-Output ("MUAMAN-13L guard tests: allPass={0}" -f $allPass)
if (-not $allPass) { exit 1 }
exit 0
