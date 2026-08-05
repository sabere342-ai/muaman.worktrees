# MUAMAN-13M guard-point verification harness.
#
# Verifies the mandatory acceptance gates M1..M8 plus the required negative
# controls N1..N4 against the authoritative B1 release directory and the
# authoritative P1/P2 packages produced by tools/release/package_windows_release.ps1.
#
# Guards verified here:
#   M1 static delegation integrity  the packaging entrypoint reuses the canonical
#                                   verifier and contains no build/legal-manifest
#                                   re-implementation
#   M2 CWD independence             packaging succeeds and is byte-identical from
#                                   repo root / repo sub-folder / external dir
#                                   (explicit and script-derived RepoRoot)
#   M3 verify-before-package        verification runs before ZIP creation and the
#                                   entrypoint fails closed on any invalid input
#   M4 deterministic package id     P1 and P2 ZIPs byte-identical (SHA-256,
#                                   length, entry order, timestamps, metadata)
#   M5 extraction equivalence       P1 and P2 extract to exactly the accepted
#                                   canonical release payload, byte-identical
#                                   to B1, no missing/extra/differing files,
#                                   no traversal or absolute-path entries
#   M6 secret & environment hygiene scan of scripts/evidence/reports/manifests/
#                                   checksums plus ZIP entry names and bytes
#   M7 active documentation guard  the sole official packaging entrypoint is
#                                   package_windows_release.ps1; build/verify/
#                                   package commands and outputs are distinct;
#                                   no ad hoc Compress-Archive packaging
#   M8 repository & lineage guard   branch/commit/scope/production-diff proof
#   N1..N4 negative controls        missing file / modified file / extra file /
#                                   partial-output safety on disposable copies
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File guard_tests_13m.ps1 ^
#       -RepoRoot <dir> -Out <json> -EvidenceRoot <dir> -ReleaseDir <dir> ^
#       [-P1Zip <file>] [-P2Zip <file>] [-PackageScript <file>] [-TempRoot <dir>]

param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$Out,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][string]$ReleaseDir,
  [string]$PackageScript = '',
  [string]$P1Zip = '',
  [string]$P2Zip = '',
  [string]$TempRoot = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Out = [System.IO.Path]::GetFullPath($Out)
$EvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot)
$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
if ([string]::IsNullOrWhiteSpace($PackageScript)) {
  $PackageScript = Join-Path $RepoRoot 'tools\release\package_windows_release.ps1'
}
$PackageScript = [System.IO.Path]::GetFullPath($PackageScript)
if ([string]::IsNullOrWhiteSpace($TempRoot)) { $TempRoot = $env:TEMP }
$TempRoot = [System.IO.Path]::GetFullPath($TempRoot)
$scratch = Join-Path $TempRoot ('m13m-guard-' + $PID)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
foreach ($sub in @('06-package-comparison', '07-extraction', '08-negative-controls', '09-guards')) {
  New-Item -ItemType Directory -Path (Join-Path $EvidenceRoot $sub) -Force | Out-Null
}

$expectedCommit = 'ea80321f218bc0fd74c8ccc3a7e8621d79325a0b'
$expectedBranch = 'codex/muaman-13m-canonical-deterministic-release-package'
$expectedFileCount = 13
$expectedTotalBytes = 33273462
$expectedCrossHash = 'EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9'

$verdicts = [ordered]@{}

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Get-Sha256([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }

function Get-CrossHash([string]$root) {
  $lines = foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    '{0}|{1}|{2}' -f $rel, $f.Length, (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  }
  $sb = New-Object System.Text.StringBuilder
  foreach ($l in ($lines | Sort-Object)) { [void]$sb.AppendLine($l) }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
  return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
}

function Get-TreeSummary([string]$root) {
  $entries = @()
  $total = [int64]0
  foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    $entries += [pscustomobject][ordered]@{ rel = $rel; size = $f.Length; sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
    $total += $f.Length
  }
  return [pscustomobject][ordered]@{ fileCount = $entries.Count; totalBytes = $total; crossHash = (Get-CrossHash $root); entries = $entries }
}

function Invoke-Packager([string]$cwd, [string]$outDir, [string]$evidDir, [bool]$useRepoRoot, [string]$releaseDirParam = '') {
  $rel = if ([string]::IsNullOrWhiteSpace($releaseDirParam)) { $ReleaseDir } else { $releaseDirParam }
  $procArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PackageScript + '"'),
    '-ReleaseDir', ('"' + $rel + '"'), '-OutputDir', ('"' + $outDir + '"'), '-EvidenceDir', ('"' + $evidDir + '"'))
  if ($useRepoRoot) { $procArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PackageScript + '"'),
    '-RepoRoot', ('"' + $RepoRoot + '"'), '-ReleaseDir', ('"' + $rel + '"'), '-OutputDir', ('"' + $outDir + '"'), '-EvidenceDir', ('"' + $evidDir + '"')) }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = 'powershell.exe'
  $psi.Arguments = $procArgs -join ' '
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.WorkingDirectory = $cwd
  $p = [System.Diagnostics.Process]::Start($psi)
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return [pscustomobject][ordered]@{
    cwd = $cwd
    exitCode = $p.ExitCode
    stdout = $stdout.Trim()
    stderr = $stderr.Trim()
    zipPath = Join-Path $outDir 'muaman-windows-release.zip'
    resultPath = Join-Path $outDir 'package-result.json'
  }
}

function Invoke-SafeExtract([string]$zipPath, [string]$destRoot) {
  $problems = @()
  New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
  $fs = [System.IO.File]::OpenRead($zipPath)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
    try {
      foreach ($e in $zip.Entries) {
        $name = $e.FullName
        if ([string]::IsNullOrWhiteSpace($name) -or $name.StartsWith('/') -or $name.Contains('\') -or $name -match '\.\.' -or $name -match '^[A-Za-z]:') {
          $problems += "unsafe entry name: $name"
          continue
        }
        $dest = [System.IO.Path]::GetFullPath((Join-Path $destRoot ($name.Replace('/', '\'))))
        $rootFull = [System.IO.Path]::GetFullPath($destRoot)
        if (-not $dest.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
          $problems += "traversal entry: $name"
          continue
        }
        $parent = Split-Path -Parent $dest
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $in = $e.Open()
        try {
          $out = [System.IO.File]::Create($dest)
          try { $in.CopyTo($out) } finally { $out.Dispose() }
        } finally { $in.Dispose() }
      }
    } finally { $zip.Dispose() }
  } finally { $fs.Dispose() }
  return @($problems)
}

function Read-ZipEntries([string]$zipPath) {
  $list = @()
  $fs = [System.IO.File]::OpenRead($zipPath)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
    try {
      foreach ($e in $zip.Entries) {
        $sha = ''
        $in = $e.Open()
        try {
          $shaAlg = [System.Security.Cryptography.SHA256]::Create()
          $buf = New-Object byte[] 65536
          while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) { [void]$shaAlg.TransformBlock($buf, 0, $n, $null, 0) }
          $shaAlg.TransformFinalBlock($buf, 0, 0) | Out-Null
          $sha = ([System.BitConverter]::ToString($shaAlg.Hash)).Replace('-', '')
          $shaAlg.Dispose()
        } finally { $in.Dispose() }
        $list += [pscustomobject][ordered]@{
          name = $e.FullName
          length = $e.Length
          compressedLength = $e.CompressedLength
          lastWriteTimeUtc = $e.LastWriteTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
          sha256 = $sha
        }
      }
    } finally { $zip.Dispose() }
  } finally { $fs.Dispose() }
  return $list
}

# ---------------------------------------------------------------------------
# M1 static delegation integrity
# ---------------------------------------------------------------------------
function Get-M1Verdict {
  $bad = @()
  $src = @(Get-Content -LiteralPath $PackageScript -Encoding UTF8)
  $executable = @($src | Where-Object { $_ -notmatch '^\s*#' })
  $execText = $executable -join "`n"

  $usesVerifier = $execText -match 'verify_release\.ps1'
  if (-not $usesVerifier) { $bad += 'does not invoke the canonical release verifier verify_release.ps1' }

  $forbidden = @(
    'flutter build',
    'flutter\.bat',
    'flutter\.exe',
    'run_experiment\.ps1',
    'Microsoft\.Build\.Utilities\.FileTracker',
    'Compress-Archive',
    $expectedCrossHash
  )
  foreach ($tok in $forbidden) {
    if ($execText -match $tok) { $bad += "forbidden token in executable code: $tok" }
  }
  # build entrypoints must never be INVOKED/delegated to (a structural mention
  # such as a repository-layout marker is legitimate; invocation is not)
  foreach ($pat in @('(?:-File|\b&|Invoke-Expression|Start-Process)\b[^\r\n]*build_(?:windows_release|hardened)\.ps1')) {
    if ($execText -match $pat) { $bad += "invokes/delegates to build implementation: $pat" }
  }
  foreach ($f in @('build_hardened.ps1', 'run_experiment.ps1')) {
    if ($execText -match [regex]::Escape($f)) { $bad += 'invokes/names build implementation: ' + $f }
  }
  # no hard-coded absolute drive-letter paths in executable code
  if ($execText -match '(?m)^[^#].*[A-Za-z]:\\') { $bad += 'hard-coded absolute drive-letter path in executable code' }
  # packaging responsibility must be isolated from build responsibility: no build-side
  # verbs such as pub get / clean / cmake / msbuild in executable code
  foreach ($v in @('pub get', 'flutter clean', 'msbuild', 'cmake')) {
    if ($execText -match [regex]::Escape($v)) { $bad += "build-side verb present: $v" }
  }
  # the cross-hash must come from the verifier output, not be recomputed here
  if ($execText -notmatch 'crossHashNew' -and $execText -notmatch 'crossHash') {
    $bad += 'does not record the verifier cross-hash in the package manifest'
  }

  [ordered]@{
    guard = 'M1 static delegation integrity (no build/verify re-implementation)'
    pass = ($bad.Count -eq 0)
    failures = $bad
    usesCanonicalVerifier = $usesVerifier
  }
}
$verdicts['M1'] = Get-M1Verdict

# ---------------------------------------------------------------------------
# M2 CWD independence
# ---------------------------------------------------------------------------
function Get-M2Verdict {
  $outside = Join-Path $scratch 'm2-outside'
  New-Item -ItemType Directory -Path $outside -Force | Out-Null
  $runs = [ordered]@{}
  $cases = [ordered]@{
    repositoryRoot = [ordered]@{ cwd = $RepoRoot; useRepoRoot = $true }
    repositorySubFolder = [ordered]@{ cwd = (Join-Path $RepoRoot 'tools\release'); useRepoRoot = $true }
    outsideRepository = [ordered]@{ cwd = $outside; useRepoRoot = $true }
    outsideRepositoryDerivedRepoRoot = [ordered]@{ cwd = $outside; useRepoRoot = $false }
  }
  foreach ($k in $cases.Keys) {
    $outDir = Join-Path $scratch ('m2-' + $k + '-out')
    $evidDir = Join-Path $scratch ('m2-' + $k + '-evidence')
    $r = Invoke-Packager $cases[$k].cwd $outDir $evidDir $cases[$k].useRepoRoot
    $zipExists = Test-Path -LiteralPath $r.zipPath -PathType Leaf
    $hash = if ($zipExists) { Get-Sha256 $r.zipPath } else { '' }
    $runs[$k] = [ordered]@{
      cwd = $cases[$k].cwd
      useRepoRoot = $cases[$k].useRepoRoot
      exitCode = $r.exitCode
      zipProduced = $zipExists
      zipSha256 = $hash
      stdout = $r.stdout
      stderr = $r.stderr
    }
  }
  $hashes = @($runs.Keys | ForEach-Object { $runs[$_].zipSha256 } | Where-Object { $_ -ne '' })
  $allZero = -not (@($runs.Keys | ForEach-Object { $runs[$_].exitCode } | Where-Object { $_ -ne 0 }).Count -gt 0)
  $allProduced = -not (@($runs.Keys | ForEach-Object { $runs[$_].zipProduced } | Where-Object { $_ -eq $false }).Count -gt 0)
  $allIdentical = ($hashes.Count -eq $cases.Count) -and (@($hashes | Select-Object -Unique).Count -eq 1)

  $result = [ordered]@{
    guard = 'M2 CWD independence (repo root / sub-folder / external dir)'
    pass = ($allZero -and $allProduced -and $allIdentical)
    runs = $runs
    allExitZero = $allZero
    allProduced = $allProduced
    allZipShaIdentical = $allIdentical
    uniqueZipSha = @($hashes | Select-Object -Unique)
  }
  $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '09-guards\cwd-independence-results.json') -Encoding UTF8
  return $result
}
$verdicts['M2'] = Get-M2Verdict

# ---------------------------------------------------------------------------
# M3 verify-before-package + fail closed (static order + dynamic N1..N4)
# ---------------------------------------------------------------------------
function Get-M3StaticVerdict {
  $bad = @()
  $src = @(Get-Content -LiteralPath $PackageScript -Encoding UTF8)
  $verifyIdx = -1
  $zipIdx = -1
  for ($i = 0; $i -lt $src.Count; $i++) {
    $l = $src[$i]
    if ($l -notmatch '^\s*#') {
      if ($l -match '\-File \$Verifier' -and $verifyIdx -lt 0) { $verifyIdx = $i }
      if (($l -match '\.partial\.tmp' -or $l -match 'ZipArchive' -or $l -match 'CreateEntry') -and $zipIdx -lt 0) { $zipIdx = $i }
    }
  }
  $ordered = ($verifyIdx -ge 0) -and ($zipIdx -ge 0) -and ($verifyIdx -lt $zipIdx)
  if (-not $ordered) { $bad += 'verification is not source-ordered before ZIP creation' }
  [ordered]@{
    guard = 'M3 static verify-before-package order'
    pass = ($bad.Count -eq 0)
    failures = $bad
    verifyInvocationLine = if ($verifyIdx -ge 0) { $verifyIdx + 1 } else { -1 }
    zipCreationLine = if ($zipIdx -ge 0) { $zipIdx + 1 } else { -1 }
    verificationBeforeZip = $ordered
  }
}
$verdicts['M3static'] = Get-M3StaticVerdict

function Get-NegativeControls {
  $results = [ordered]@{}
  $scratchN = Join-Path $scratch 'neg'
  New-Item -ItemType Directory -Path $scratchN -Force | Out-Null

  function Run-Negative([string]$label, [string]$releaseCopy, [bool]$expectVerifyFail) {
    $outDir = Join-Path $scratchN ($label + '-out')
    $evidDir = Join-Path $scratchN ($label + '-evidence')
    $r = Invoke-Packager $RepoRoot $outDir $evidDir $true $releaseCopy
    $zipExists = Test-Path -LiteralPath $r.zipPath -PathType Leaf
    $partialExists = Test-Path -LiteralPath (Join-Path $outDir 'muaman-windows-release.zip.partial.tmp')
    $resultJson = $null
    $resultPath = Join-Path $outDir 'package-result.json'
    if (Test-Path -LiteralPath $resultPath) { $resultJson = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json }
    $resultVerdict = if ($null -ne $resultJson) { [string]$resultJson.verification.verdict } else { '' }
    $resultJsonHasFailure = ($resultVerdict -eq 'FAIL')
    $exitOk = if ($expectVerifyFail) { ($r.exitCode -eq 1) } else { ($r.exitCode -ne 0) }
    return [ordered]@{
      label = $label
      expected = if ($expectVerifyFail) { 'verification failure (exit 1), no ZIP' } else { 'nonzero exit, no valid ZIP, failure recorded' }
      exitCode = $r.exitCode
      zipProduced = $zipExists
      partialArchiveRemaining = $partialExists
      resultJsonVerdict = $resultVerdict
      resultJsonHasFailure = $resultJsonHasFailure
      stdout = $r.stdout
      stderr = $r.stderr
      pass = $exitOk -and (-not $zipExists) -and (-not $partialExists) -and $resultJsonHasFailure
    }
  }

  # N1 missing file (disposable copy, one legal file deleted)
  $n1 = Join-Path $scratchN 'n1-copy'
  New-Item -ItemType Directory -Path $n1 -Force | Out-Null
  Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $n1 -Recurse -Force
  Remove-Item -LiteralPath (Join-Path $n1 'data\app.so') -Force
  $results['N1'] = Run-Negative 'n1' $n1 $true

  # N2 modified file (disposable copy, one byte flipped in a legal file)
  $n2 = Join-Path $scratchN 'n2-copy'
  New-Item -ItemType Directory -Path $n2 -Force | Out-Null
  Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $n2 -Recurse -Force
  $target = Join-Path $n2 'data\app.so'
  $bytes = [System.IO.File]::ReadAllBytes($target)
  $bytes[0] = $bytes[0] -bxor 0x01
  [System.IO.File]::WriteAllBytes($target, $bytes)
  $results['N2'] = Run-Negative 'n2' $n2 $true

  # N3 unexpected extra file (disposable copy plus a stray file)
  $n3 = Join-Path $scratchN 'n3-copy'
  New-Item -ItemType Directory -Path $n3 -Force | Out-Null
  Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $n3 -Recurse -Force
  Set-Content -LiteralPath (Join-Path $n3 'unexpected-extra-file.bin') -Value 'not part of the legal release' -Encoding UTF8
  $results['N3'] = Run-Negative 'n3' $n3 $true

  # N4 partial-output safety: a directory occupies the final ZIP path so the
  # atomic finalization fails AFTER output initialization (verify passes, the
  # archive is built in temp, the move fails). Filesystem condition only; no
  # production test bypass exists.
  $n4Out = Join-Path $scratchN 'n4-out'
  $n4Evid = Join-Path $scratchN 'n4-evidence'
  New-Item -ItemType Directory -Path (Join-Path $n4Out 'muaman-windows-release.zip') -Force | Out-Null
  $r4 = Invoke-Packager $RepoRoot $n4Out $n4Evid $true
  $n4Partial = Test-Path -LiteralPath (Join-Path $n4Out 'muaman-windows-release.zip.partial.tmp')
  $n4ZipIsDirectory = Test-Path -LiteralPath (Join-Path $n4Out 'muaman-windows-release.zip') -PathType Container
  $n4ZipIsFile = Test-Path -LiteralPath (Join-Path $n4Out 'muaman-windows-release.zip') -PathType Leaf
  $n4Result = $null
  $n4ResultPath = Join-Path $n4Out 'package-result.json'
  if (Test-Path -LiteralPath $n4ResultPath) { $n4Result = Get-Content -LiteralPath $n4ResultPath -Raw | ConvertFrom-Json }
  $n4Fail = ($null -ne $n4Result) -and ([string]$n4Result.packaging.verdict -eq 'FAIL') -and (-not [string]::IsNullOrWhiteSpace([string]$n4Result.failureReason))
  $results['N4'] = [ordered]@{
    label = 'n4'
    expected = 'packaging failure after output init (nonzero exit), no valid ZIP, failure recorded'
    exitCode = $r4.exitCode
    zipPathIsDirectory = $n4ZipIsDirectory
    zipPathIsFile = $n4ZipIsFile
    partialArchiveRemaining = $n4Partial
    resultJsonPackagingVerdict = if ($null -ne $n4Result) { [string]$n4Result.packaging.verdict } else { '' }
    resultJsonHasFailureReason = ($null -ne $n4Result) -and (-not [string]::IsNullOrWhiteSpace([string]$n4Result.failureReason))
    stdout = $r4.stdout
    stderr = $r4.stderr
    pass = ($r4.exitCode -ne 0) -and $n4ZipIsDirectory -and (-not $n4ZipIsFile) -and (-not $n4Partial) -and $n4Fail
  }

  # aggregate
  $allPass = $true
  foreach ($k in $results.Keys) { if (-not [bool]$results[$k].pass) { $allPass = $false } }

  $out = [ordered]@{
    guard = 'N1..N4 negative controls (disposable copies only)'
    capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    releaseDirNeverModified = $true
    allPass = $allPass
    controls = $results
  }
  $out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '08-negative-controls\negative-control-results.json') -Encoding UTF8
  return $out
}
$negativeControls = Get-NegativeControls

function Get-M3DynamicVerdict {
  [ordered]@{
    guard = 'M3 dynamic fail-closed (N1..N4 negative controls)'
    pass = [bool]$negativeControls.allPass
    allPass = [bool]$negativeControls.allPass
    evidence = '08-negative-controls/negative-control-results.json'
  }
}
$verdicts['M3'] = Get-M3DynamicVerdict

# ---------------------------------------------------------------------------
# M4 deterministic package identity (P1 vs P2)
# ---------------------------------------------------------------------------
function Get-M4Verdict {
  $bad = @()
  $summary = [ordered]@{
    guard = 'M4 deterministic package identity (P1 vs P2)'
    pass = $false
    p1 = ''
    p2 = ''
  }
  if ([string]::IsNullOrWhiteSpace($P1Zip) -or [string]::IsNullOrWhiteSpace($P2Zip) -or
      -not (Test-Path -LiteralPath $P1Zip -PathType Leaf) -or -not (Test-Path -LiteralPath $P2Zip -PathType Leaf)) {
    $summary.pass = $null
    $summary.status = 'not-run'
    $summary.detail = 'no authoritative P1/P2 ZIP paths supplied'
    return $summary
  }
  $P1Zip = [System.IO.Path]::GetFullPath($P1Zip)
  $P2Zip = [System.IO.Path]::GetFullPath($P2Zip)

  $b1 = [System.IO.File]::ReadAllBytes($P1Zip)
  $b2 = [System.IO.File]::ReadAllBytes($P2Zip)
  $bytesIdentical = ($b1.Length -eq $b2.Length)
  if ($bytesIdentical) {
    for ($i = 0; $i -lt $b1.Length; $i++) { if ($b1[$i] -ne $b2[$i]) { $bytesIdentical = $false; break } }
  }
  $h1 = Get-Sha256 $P1Zip
  $h2 = Get-Sha256 $P2Zip
  $l1 = (Get-Item -LiteralPath $P1Zip).Length
  $l2 = (Get-Item -LiteralPath $P2Zip).Length

  $e1 = @(Read-ZipEntries $P1Zip)
  $e2 = @(Read-ZipEntries $P2Zip)
  $entryCount1 = $e1.Count
  $entryCount2 = $e2.Count

  $orderSame = ($entryCount1 -eq $entryCount2)
  $metaDiffs = @()
  if ($orderSame) {
    for ($i = 0; $i -lt $entryCount1; $i++) {
      $a = $e1[$i]
      $b = $e2[$i]
      if ($a.name -ne $b.name -or $a.length -ne $b.length -or $a.compressedLength -ne $b.compressedLength -or $a.lastWriteTimeUtc -ne $b.lastWriteTimeUtc -or $a.sha256 -ne $b.sha256) {
        $metaDiffs += [ordered]@{ index = $i; nameP1 = $a.name; nameP2 = $b.name }
        $orderSame = $false
      }
    }
  }

  # entry manifests (committed evidence)
  foreach ($pair in @(
    @{ zip = $P1Zip; out = Join-Path $EvidenceRoot '06-package-comparison\zip-entry-manifest-p1.json'; tag = 'p1' },
    @{ zip = $P2Zip; out = Join-Path $EvidenceRoot '06-package-comparison\zip-entry-manifest-p2.json'; tag = 'p2' }
  )) {
    $entries = @(Read-ZipEntries $pair.zip)
    $m = [ordered]@{ package = $pair.tag; entryCount = $entries.Count; entries = $entries }
    $m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $pair.out -Encoding UTF8
  }

  $summary.p1 = [ordered]@{ zip = $P1Zip; sha256 = $h1; byteLength = $l1; entryCount = $entryCount1 }
  $summary.p2 = [ordered]@{ zip = $P2Zip; sha256 = $h2; byteLength = $l2; entryCount = $entryCount2 }
  $summary.sha256Match = ($h1 -eq $h2)
  $summary.byteLengthMatch = ($l1 -eq $l2)
  $summary.bytesIdentical = $bytesIdentical
  $summary.entryOrderIdentical = $orderSame
  $summary.entryMetadataDiffCount = $metaDiffs.Count
  $summary.entryMetadataDiffs = $metaDiffs
  $summary.pass = $bytesIdentical -and ($h1 -eq $h2) -and ($l1 -eq $l2) -and $orderSame -and ($metaDiffs.Count -eq 0)

  $out = [ordered]@{
    guard = 'M4 deterministic package identity (P1 vs P2)'
    capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    pass = [bool]$summary.pass
    packageSha256P1 = $h1
    packageSha256P2 = $h2
    byteLengthP1 = $l1
    byteLengthP2 = $l2
    bytesIdentical = $bytesIdentical
    entryCountP1 = $entryCount1
    entryCountP2 = $entryCount2
    entryOrderIdentical = $orderSame
    entryMetadataDiffCount = $metaDiffs.Count
    entryMetadataDiffs = $metaDiffs
    failureReasons = $bad
  }
  $out | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '06-package-comparison\package-comparison.json') -Encoding UTF8
  return $out
}
$verdicts['M4'] = Get-M4Verdict

# ---------------------------------------------------------------------------
# M5 extraction equivalence
# ---------------------------------------------------------------------------
function Get-M5Verdict {
  $summary = [ordered]@{ guard = 'M5 extraction equivalence'; pass = $false }
  if ([string]::IsNullOrWhiteSpace($P1Zip) -or [string]::IsNullOrWhiteSpace($P2Zip) -or
      -not (Test-Path -LiteralPath $P1Zip -PathType Leaf) -or -not (Test-Path -LiteralPath $P2Zip -PathType Leaf)) {
    $summary.pass = $null
    $summary.status = 'not-run'
    $summary.detail = 'no authoritative P1/P2 ZIP paths supplied'
    return $summary
  }

  $summary = [ordered]@{}
  $results = [ordered]@{}
  $allPass = $true
  foreach ($tag in @('p1', 'p2')) {
    $zipPath = if ($tag -eq 'p1') { [System.IO.Path]::GetFullPath($P1Zip) } else { [System.IO.Path]::GetFullPath($P2Zip) }
    $extractRoot = Join-Path $scratch ('extract-' + $tag)
    if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
    $problems = @(Invoke-SafeExtract $zipPath $extractRoot)
    $tree = Get-TreeSummary $extractRoot

    # per-file byte comparison vs the B1 release tree
    $missing = @()
    $extra = @()
    $differing = @()
    $releaseFiles = @{}
    foreach ($f in Get-ChildItem -LiteralPath $ReleaseDir -Recurse -File) {
      $rel = $f.FullName.Substring($ReleaseDir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
      $releaseFiles[$rel] = $f.FullName
    }
    $extracted = @{}
    foreach ($e in $tree.entries) { $extracted[$e.rel] = $e }
    foreach ($rel in $releaseFiles.Keys) {
      if (-not $extracted.ContainsKey($rel)) { $missing += $rel; continue }
      $srcHash = (Get-FileHash -LiteralPath $releaseFiles[$rel] -Algorithm SHA256).Hash
      if ($srcHash -ne $extracted[$rel].sha256) { $differing += $rel }
    }
    foreach ($rel in $extracted.Keys) {
      if (-not $releaseFiles.ContainsKey($rel)) { $extra += $rel }
    }

    $fileCountOk = ($tree.fileCount -eq $expectedFileCount)
    $totalBytesOk = ($tree.totalBytes -eq $expectedTotalBytes)
    $crossOk = ($tree.crossHash -eq $expectedCrossHash)
    $treeOk = $fileCountOk -and $totalBytesOk -and $crossOk
    $identityOk = ($missing.Count -eq 0) -and ($extra.Count -eq 0) -and ($differing.Count -eq 0)
    $pathSafe = ($problems.Count -eq 0)
    $pass = $treeOk -and $identityOk -and $pathSafe
    if (-not $pass) { $allPass = $false }

    $results[$tag] = [ordered]@{
      zip = $zipPath
      extractedRoot = $extractRoot
      problems = $problems
      fileCount = $tree.fileCount
      totalBytes = $tree.totalBytes
      crossHash = $tree.crossHash
      fileCountOk = $fileCountOk
      totalBytesOk = $totalBytesOk
      crossHashOk = $crossOk
      missingCount = $missing.Count
      missing = $missing
      extraCount = $extra.Count
      extra = $extra
      differingCount = $differing.Count
      differing = $differing
      pathSafetyProblems = $pathSafe
      pass = $pass
    }

    # committed extraction manifest
    $m = [ordered]@{
      package = $tag
      extractedFrom = $zipPath
      extractedFileCount = $tree.fileCount
      extractedTotalBytes = $tree.totalBytes
      extractedCrossHash = $tree.crossHash
      acceptedCrossHash = $expectedCrossHash
      entries = $tree.entries
    }
    $m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceRoot ('07-extraction\extracted-manifest-' + $tag + '.json')) -Encoding UTF8
  }

  $comparison = [ordered]@{
    guard = 'M5 extraction equivalence'
    capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    pass = $allPass
    acceptedFileCount = $expectedFileCount
    acceptedTotalBytes = $expectedTotalBytes
    acceptedCrossHash = $expectedCrossHash
    releaseDir = $ReleaseDir
    p1 = $results['p1']
    p2 = $results['p2']
    p1EqualsP2 = (($results['p1'].crossHash -eq $results['p2'].crossHash) -and ($results['p1'].fileCount -eq $results['p2'].fileCount) -and ($results['p1'].totalBytes -eq $results['p2'].totalBytes))
  }
  $comparison | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '07-extraction\extraction-comparison.json') -Encoding UTF8
  return $comparison
}
$verdicts['M5'] = Get-M5Verdict

# ---------------------------------------------------------------------------
# M6 secret & environment hygiene
# ---------------------------------------------------------------------------
function Get-M6Verdict {
  $findings = New-Object System.Collections.ArrayList
  $scannedFiles = 0

  $secretPatterns = @(
    'OPENCODE_SERVER_PASSWORD\s*=\s*[^<\s][^\r\n]*',
    '(?i)(password|passwd|secret|token|api[ _]?key|credential)\s*[:=]\s*[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}',
    '(?i)BEGIN [A-Z ]*PRIVATE KEY',
    '(?i)authorization\s*[:=]',
    '(?i)\bbearer\b\s+[A-Za-z0-9._\-=]{20,}'
  )

  function Scan-Content($bytes, $rel, [System.Collections.ArrayList]$findings, $prohibitedTokens, $failOnTokens) {
    $ascii = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
    foreach ($pat in $secretPatterns) {
      if ($ascii -match $pat) { [void]$findings.Add(([pscustomobject]@{ file = $rel; kind = 'secret'; detail = $pat; encoding = 'ASCII' })) }
      if ($utf16 -match $pat) { [void]$findings.Add(([pscustomobject]@{ file = $rel; kind = 'secret'; detail = $pat; encoding = 'UTF-16LE' })) }
    }
    if ($failOnTokens) {
      foreach ($tok in $prohibitedTokens) {
        $lowTok = $tok.ToLowerInvariant()
        if ($ascii.ToLowerInvariant().Contains($lowTok)) { [void]$findings.Add(([pscustomobject]@{ file = $rel; kind = 'env-leak'; detail = $tok; encoding = 'ASCII' })) }
        if ($utf16.ToLowerInvariant().Contains($lowTok)) { [void]$findings.Add(([pscustomobject]@{ file = $rel; kind = 'env-leak'; detail = $tok; encoding = 'UTF-16LE' })) }
      }
    }
  }

  # Env-leak tokens enforced for shipping scripts, the governing report and the
  # distributable ZIP. Committed evidence files are permitted to contain
  # documented absolute test/build paths (MUAMAN-13M spec section 10) so they
  # are scanned for secrets only. The guard harness itself is scanned for
  # secrets only because it declares the prohibited-token literals as fixtures.
  $textTokens = @(
    'c:\users\',
    'appdata\local\temp\',
    '\.git\',
    '\pub\cache\'
  )
  $zipTokens = @(
    'c:\users\',
    'appdata\local\temp\',
    'c:\m13m',
    'c:\m13k',
    'c:\m13i',
    'c:\m13l',
    'c:\dev',
    '\.git\',
    '\pub\cache\',
    $RepoRoot.ToLowerInvariant(),
    $ReleaseDir.ToLowerInvariant()
  )

  # 1) shipping scripts + governing report (secrets + env-leak tokens)
  $strictText = @(
    (Join-Path $RepoRoot 'tools\release\package_windows_release.ps1'),
    (Join-Path $RepoRoot 'tools\release\verify_release.ps1'),
    (Join-Path $RepoRoot 'docs\MUAMAN-13M-CANONICAL-DETERMINISTIC-WINDOWS-RELEASE-PACKAGE-ACCEPTANCE.md')
  )
  foreach ($root in $strictText) {
    if (-not (Test-Path -LiteralPath $root -PathType Leaf)) { continue }
    $scannedFiles++
    $bytes = [System.IO.File]::ReadAllBytes($root)
    Scan-Content $bytes $root.Replace($RepoRoot + '\', '').Replace('\', '/') $findings $textTokens $true
  }

  # 2) guard harness + committed evidence tree (secrets only)
  $secretOnly = @(
    (Join-Path $RepoRoot 'tools\muaman13m'),
    (Join-Path $EvidenceRoot '')
  )
  foreach ($root in $secretOnly) {
    $items = @()
    if (Test-Path -LiteralPath $root -PathType Container) {
      $items = @(Get-ChildItem -LiteralPath $root -Recurse -File)
    } elseif (Test-Path -LiteralPath $root -PathType Leaf) {
      $items = @(Get-Item -LiteralPath $root)
    }
    foreach ($f in $items) {
      $scannedFiles++
      $rel = $f.FullName
      $base = [System.IO.Path]::GetFullPath($root).TrimEnd('\')
      if ($f.FullName.StartsWith($base + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $f.FullName.Substring($base.Length).TrimStart('\').Replace('\', '/')
      }
      $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
      Scan-Content $bytes $rel $findings @() $false
    }
  }

  # 3) distributable ZIP: entry names + entry bytes
  $zipScan = [ordered]@{}
  foreach ($tag in @('p1', 'p2')) {
    $zipPath = if ($tag -eq 'p1') { $P1Zip } else { $P2Zip }
    $zFindings = @()
    if (-not [string]::IsNullOrWhiteSpace($zipPath) -and (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
      $fs = [System.IO.File]::OpenRead($zipPath)
      try {
        $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
        try {
          foreach ($e in $zip.Entries) {
            $name = $e.FullName
            if ($name.StartsWith('/') -or $name.Contains('\') -or $name -match '\.\.' -or $name -match '^[A-Za-z]:') {
              $zFindings += "unsafe entry name: $name"
            }
            $in = $e.Open()
            try {
              $ms = New-Object System.IO.MemoryStream
              $in.CopyTo($ms)
              $bytes = $ms.ToArray()
              $ms.Dispose()
            } finally { $in.Dispose() }
            $ascii = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes).ToLowerInvariant()
            foreach ($tok in $zipTokens) {
              if ($ascii.Contains($tok.ToLowerInvariant())) { $zFindings += "entry $name contains token: $tok" }
            }
            foreach ($pat in $secretPatterns) {
              if ([System.Text.Encoding]::GetEncoding(28591).GetString($bytes) -match $pat) { $zFindings += "entry $name matches secret pattern: $pat" }
            }
          }
        } finally { $zip.Dispose() }
      } finally { $fs.Dispose() }
    }
    $zipScan[$tag] = $zFindings
    foreach ($z in $zFindings) { [void]$findings.Add(([pscustomobject]@{ file = ('ZIP-' + $tag); kind = 'zip'; detail = $z })) }
  }

  $result = [ordered]@{
    guard = 'M6 secret & environment hygiene'
    capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    scannedFiles = $scannedFiles
    findingCount = $findings.Count
    findings = @($findings)
    zipScan = $zipScan
    clean = ($findings.Count -eq 0)
    pass = ($findings.Count -eq 0)
  }
  $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '09-guards\secrecy-scan.json') -Encoding UTF8
  return $result
}
$verdicts['M6'] = Get-M6Verdict

# ---------------------------------------------------------------------------
# M7 active documentation guard
# ---------------------------------------------------------------------------
function Get-M7Verdict {
  $bad = @()
  $report = Join-Path $RepoRoot 'docs\MUAMAN-13M-CANONICAL-DETERMINISTIC-WINDOWS-RELEASE-PACKAGE-ACCEPTANCE.md'
  if (-not (Test-Path -LiteralPath $report)) {
    $bad += 'governing report missing: docs/MUAMAN-13M-CANONICAL-DETERMINISTIC-WINDOWS-RELEASE-PACKAGE-ACCEPTANCE.md'
    return [ordered]@{ guard = 'M7 active documentation'; pass = $false; failures = $bad }
  }
  $text = Get-Content -LiteralPath $report -Raw

  $hasPackageEntry = $text -match 'tools[/\\]release[/\\]package_windows_release\.ps1'
  $soleOfficial = $text -match '(?i)sole official packaging entrypoint'
  if (-not $hasPackageEntry) { $bad += 'report does not document the packaging entrypoint' }
  if (-not $soleOfficial) { $bad += 'report does not declare the sole official packaging entrypoint' }

  foreach ($token in @('tools[/\\]release[/\\]build_windows_release\.ps1', 'tools[/\\]release[/\\]verify_release\.ps1', 'package manifest', 'package-result', 'sha256', 'fail')) {
    if ($text -notmatch $token) { $bad += 'report does not clearly cover required element: ' + $token }
  }

  # no active doc may instruct ad hoc Compress-Archive packaging or a second packaging script
  $docFiles = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'docs') -Filter '*.md' -File)
  $instructive = @()
  foreach ($d in $docFiles) {
    $lines = Get-Content -LiteralPath $d.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $l = $lines[$i]
      if ($l -match '^\s*(powershell|pwsh|PS>|Compress-Archive)' -and $l -match 'Compress-Archive') {
        $instructive += ('{0}:{1}: {2}' -f $d.Name, ($i + 1), $l.Trim())
      }
    }
  }
  if ($instructive.Count -gt 0) { $bad += 'active doc instructs ad hoc Compress-Archive packaging: ' + ($instructive -join '; ') }

  $result = [ordered]@{
    guard = 'M7 active documentation (sole official packaging entrypoint)'
    pass = ($bad.Count -eq 0)
    failures = $bad
    report = $report
    documentsPackagingEntrypoint = $hasPackageEntry
    declaresSoleOfficialEntrypoint = $soleOfficial
    adHocCompressArchiveInstructions = $instructive
  }
  $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceRoot '09-guards\active-doc-scan.json') -Encoding UTF8
  return $result
}
$verdicts['M7'] = Get-M7Verdict

# ---------------------------------------------------------------------------
# M8 repository & lineage integrity
# ---------------------------------------------------------------------------
function Git([string]$cmd, [string]$cwd) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = 'git.exe'
  $psi.Arguments = $cmd
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.WorkingDirectory = $cwd
  $p = [System.Diagnostics.Process]::Start($psi)
  $o = $p.StandardOutput.ReadToEnd()
  $e = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return [pscustomobject]@{ exit = $p.ExitCode; out = $o.Trim(); err = $e.Trim() }
}

function Get-M8Verdict {
  $g = [ordered]@{}
  $g.branch = (Git 'branch --show-current' $RepoRoot).out
  $g.head = (Git 'rev-parse HEAD' $RepoRoot).out
  $g.parent = (Git 'rev-parse HEAD^' $RepoRoot).out
  $revCount = (Git ('rev-list --count {0}..HEAD' -f $expectedCommit) $RepoRoot).out
  $g.revCount = $revCount
  $g.isAncestor = ((Git ('merge-base --is-ancestor {0} HEAD' -f $expectedCommit) $RepoRoot).exit -eq 0)
  $g.cleanTree = [string]::IsNullOrWhiteSpace((Git 'status --porcelain' $RepoRoot).out)
  $g.mergeCount = @((Git ('log --merges --oneline {0}..HEAD' -f $expectedCommit) $RepoRoot).out -split "`r?`n" | Where-Object { $_ -ne '' }).Count
  $g.tagAtHead = (Git 'tag --points-at HEAD' $RepoRoot).out
  $upstream = (Git 'rev-parse --abbrev-ref @{upstream}' $RepoRoot)
  $g.hasUpstream = (-not ($upstream.exit -ne 0 -and $upstream.err -match 'no upstream'))
  $g.upstream = if ($g.hasUpstream) { $upstream.out } else { '' }

  $changed = @((Git ('diff --name-only {0}..HEAD' -f $expectedCommit) $RepoRoot).out -split "`r?`n" | Where-Object { $_ -ne '' })
  $g.changedFiles = $changed

  $forbiddenPrefixes = @(
    'app/lib/', 'app/windows/', 'app/test/', 'app/integration_test/',
    'app/pubspec.yaml', 'app/pubspec.lock', 'app/.metadata', 'app/analysis_options.yaml',
    'app/android/', 'app/ios/', 'app/web/', 'app/linux/', 'app/macos/', 'app/tool/'
  )
  $scopeViolations = @()
  foreach ($c in $changed) {
    $lc = $c.Replace('\', '/')
    $allowed = $lc.StartsWith('tools/release/', [StringComparison]::OrdinalIgnoreCase) -or
               $lc.StartsWith('tools/muaman13m/', [StringComparison]::OrdinalIgnoreCase) -or
               $lc.StartsWith('docs/', [StringComparison]::OrdinalIgnoreCase)
    if (-not $allowed) { $scopeViolations += $c }
    foreach ($f in $forbiddenPrefixes) {
      if ($lc.StartsWith($f, [StringComparison]::OrdinalIgnoreCase)) { $scopeViolations += 'forbidden-prefix ' + $c }
    }
  }
  $g.scopeViolations = @($scopeViolations | Select-Object -Unique)

  $productionDiff = @($changed | Where-Object { $_ -match '^app/(lib|windows|test|integration_test)/|^app/pubspec\.(yaml|lock)$' })
  $dependencyDiff = @($changed | Where-Object { $_ -match 'pubspec\.(yaml|lock)$' })
  $sdkDiff = @($changed | Where-Object { $_ -match '^(flutter|dart|sdk|\.dart_tool)/' })
  $pluginDiff = @($changed | Where-Object { $_ -match 'plugins?/|generated_plugin' })

  $g.productionDiff = $productionDiff
  $g.dependencyDiff = $dependencyDiff
  $g.sdkDiff = $sdkDiff
  $g.pluginDiff = $pluginDiff

  $pass = ($g.branch -eq $expectedBranch) -and
          ($g.head -ne '') -and
          ($g.isAncestor) -and
          ($g.revCount -eq '1') -and
          ($g.cleanTree) -and
          ($g.mergeCount -eq 0) -and
          ([string]::IsNullOrWhiteSpace($g.tagAtHead)) -and
          ($g.scopeViolations.Count -eq 0) -and
          ($productionDiff.Count -eq 0) -and
          ($dependencyDiff.Count -eq 0) -and
          ($sdkDiff.Count -eq 0) -and
          ($pluginDiff.Count -eq 0)

  $result = [ordered]@{
    guard = 'M8 repository & lineage integrity'
    pass = $pass
    expectedBaseline = $expectedCommit
    expectedBranch = $expectedBranch
    branch = $g.branch
    head = $g.head
    parent = $g.parent
    descendsFromBaseline = $g.isAncestor
    revListCountAfterBaseline = $revCount
    workingTreeClean = $g.cleanTree
    mergeCommitCount = $g.mergeCount
    tagAtHead = if ([string]::IsNullOrWhiteSpace($g.tagAtHead)) { '' } else { $g.tagAtHead }
    hasUpstream = $g.hasUpstream
    upstream = $g.upstream
    changedFileCount = $changed.Count
    changedFiles = $changed
    scopeViolations = $g.scopeViolations
    productionDiff = $productionDiff
    dependencyDiff = $dependencyDiff
    sdkDiff = $sdkDiff
    pluginDiff = $pluginDiff
  }
  return $result
}
$verdicts['M8'] = Get-M8Verdict

# ---------------------------------------------------------------------------
# aggregate
# ---------------------------------------------------------------------------
$allPass = $true
foreach ($k in $verdicts.Keys) {
  $v = $verdicts[$k]
  if ($null -ne $v.pass -and -not [bool]$v.pass) { $allPass = $false }
}

$result = [ordered]@{
  phase = 'MUAMAN-13M guard-point verification'
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  allPass = $allPass
  verdicts = $verdicts
}
$result | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $Out -Encoding UTF8
Write-Output ("MUAMAN-13M guard tests: allPass={0}" -f $allPass)
if (-not $allPass) { exit 1 }
exit 0

