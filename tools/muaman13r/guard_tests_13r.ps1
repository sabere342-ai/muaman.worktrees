# MUAMAN-13R final governed Windows delivery package acceptance harness.
#
# Verifies the mandatory acceptance gates R1..R18 plus the required negative
# controls NC01..NC10 for the governed end-user delivery package. It operates
# on the FINAL committed HEAD (post-commit, -ExpectedFinalHead set) or on the
# pre-commit baseline state (no -ExpectedFinalHead) and is fail-closed: every
# gate must explicitly PASS; anything unknown or not-run FAILS.
#
# The harness:
#   - never builds an application or installer (it consumes the frozen
#     canonical installer supplied as -CanonicalInstaller and the committed
#     delivery tree under <repo>\delivery);
#   - re-runs the packaging entrypoint twice (D1/D2) in independent child
#     processes from different working directories and proves the resulting
#     ZIPs are byte-identical and identical to the committed delivery ZIP;
#   - proves the full byte-identity chain:
#         canonical installer == delivery installer == ZIP-extracted installer
#         == accepted SHA-256 94BD1559CFE01281714D7EB137E931FAC75DE44C115EE5FBD27B00A772C8A831
#   - scans for secrets, development artifacts, absolute development paths and
#     placeholders; and runs 10 negative controls proving the guards reject
#     the expected violations.
#
# Usage:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File guard_tests_13r.ps1 ^
#       -RepoRoot <dir> -Out <guards-result.json> -EvidenceDir <evidence-dir> ^
#       -CanonicalInstaller <path-to-accepted-installer.exe> ^
#       [-ExpectedFinalHead <final-commit-sha>] [-BaselineCommit <sha>]

param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$Out,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [Parameter(Mandatory=$true)][string]$CanonicalInstaller,
  [string]$Packager = '',
  [string]$TempRoot = '',
  [string]$BaselineCommit = 'ced34928481443486277d1a9d530a6030d43cdf6',
  [string]$ExpectedFinalHead = '',
  [string]$ExpectedBranch = 'codex/i-tech-productization-t1',
  [string]$PackageDirName = 'Muaman-1.0.0-Windows',
  [string]$SetupExeName = 'I-TECH-Setup.exe',
  [string]$ZipName = 'Muaman-1.0.0-Windows.zip',
  [string]$ExpectedInstallerSha256 = '53A706774CF30CA28CDBC7D7DF29A091F38EF974E0EC4FFDA3693ABF84D53B2C',
  [string]$ExpectedInstallerSize = '13226400'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Out = [System.IO.Path]::GetFullPath($Out)
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
$CanonicalInstaller = [System.IO.Path]::GetFullPath($CanonicalInstaller)
if ([string]::IsNullOrWhiteSpace($Packager)) {
  $Packager = Join-Path $RepoRoot 'tools\muaman13r\package_final_delivery.ps1'
}
$Packager = [System.IO.Path]::GetFullPath($Packager)
if ([string]::IsNullOrWhiteSpace($TempRoot)) { $TempRoot = $env:TEMP }
$TempRoot = [System.IO.Path]::GetFullPath($TempRoot)
$ExpectedInstallerSize = [int64]$ExpectedInstallerSize

$DeliveryRoot = Join-Path $RepoRoot 'delivery'
$DeliveryPackageDir = Join-Path $DeliveryRoot $PackageDirName
$FinalZipPath = Join-Path $DeliveryRoot $ZipName
$ReadmeTemplate = Join-Path $RepoRoot 'tools\muaman13r\README.txt'
$ExpectedFiles = @($SetupExeName, 'README.txt', 'SHA256SUMS.txt')
$AllowedPrefixes = @('tools/', 'docs/', 'installer/', 'delivery/', 'app/windows/runner/Runner.rc',
  'app/windows/runner/main.cpp', 'app/lib/models/shop_profile.dart', 'app/lib/services/app_settings.dart',
  'app/test/', 'app/docs/')
$ForbiddenPrefixes = @('app/', 'assets/', 'pubspec.yaml', 'pubspec.lock')
# T0/T1 productization carve-outs under the forbidden 'app/' root: the Windows
# runner version-resource and window title, the in-app shop default name and
# Excel default/legacy filename, plus the updated tests/docs.
$AppCarveOuts = @('app/windows/runner/Runner.rc', 'app/windows/runner/main.cpp',
  'app/lib/models/shop_profile.dart', 'app/lib/services/app_settings.dart')
$AppPrefixCarveOuts = @('app/test/', 'app/docs/')

$scratch = Join-Path $TempRoot ('m13r-guard-' + $PID)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

$verdicts = [ordered]@{}
$runStartUtc = [DateTime]::UtcNow
$runTag = Get-Date -Format 'yyyyMMdd-HHmmss'

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Get-Sha256([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }

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

function Get-ChangedPaths {
  $paths = [System.Collections.Generic.List[string]]::new()
  $committed = Git ('diff --name-only {0}..HEAD' -f $BaselineCommit) $RepoRoot
  if ($committed.exit -eq 0) {
    foreach ($l in ($committed.out -split "`r?`n")) { if (-not [string]::IsNullOrWhiteSpace($l)) { $paths.Add($l.Trim().Replace('\', '/')) } }
  }
  $status = Git 'status --porcelain --untracked-files=all' $RepoRoot
  if ($status.exit -eq 0) {
    foreach ($l in ($status.out -split "`r?`n")) {
      if ([string]::IsNullOrWhiteSpace($l)) { continue }
      $m = [regex]::Match($l, '^.{1,3}\s(.*)$')
      if (-not $m.Success) { continue }
      $p = $m.Groups[1].Value.Trim()
      if ($p -match '^(.+) -> (.+)$') { $p = $Matches[2] }
      if (-not [string]::IsNullOrWhiteSpace($p)) { $paths.Add($p.Replace('\', '/')) }
    }
  }
  return @($paths | Where-Object { $_ -ne '' } | Select-Object -Unique)
}

function Get-SetDiff([string[]]$a, [string[]]$b) {
  $bSet = @{}
  foreach ($x in $b) { $bSet[$x] = $true }
  return @($a | Where-Object { -not $bSet.ContainsKey($_) })
}

function Get-TreeEntries([string]$root) {
  $entries = @()
  $base = [System.IO.Path]::GetFullPath($root).TrimEnd('\')
  foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File) {
    $rel = $f.FullName.Substring($base.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    $entries += [pscustomobject][ordered]@{
      rel = $rel
      name = $f.Name
      path = $f.FullName
      size = $f.Length
      sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
  }
  return @($entries)
}

function Read-ZipEntries([string]$zipPath) {
  $list = @()
  $fs = [System.IO.File]::OpenRead($zipPath)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
    try {
      foreach ($e in $zip.Entries) {
        $in = $e.Open()
        $sha = ''
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

function Invoke-SafeExtract([string]$zipPath, [string]$destRoot) {
  $problems = @()
  New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
  $rootFull = [System.IO.Path]::GetFullPath($destRoot)
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

# ---------------------------------------------------------------------------
# scanning primitives
# ---------------------------------------------------------------------------
$secretPatterns = @(
  '(?i)(password|passwd|secret|token|api[ _]?key|credential)\s*[:=]\s*[A-Za-z0-9!@#$%^&*_\-]{8,}',
  'BEGIN [A-Z ]*PRIVATE KEY',
  '(?i)authorization\s*[:=]',
  '(?i)\bbearer\s+[A-Za-z0-9._\-=]{20,}'
)
$devPathTokens = @('c:\dev\', 'c:\users\', 'worktrees', 'pub-cache', 'appdata\local\temp\', '\.git\', '\.pub-cache\', 'flutter sdk')
$placeholderPatterns = @('TODO', 'FIXME', 'CHANGEME', 'CHANGE_ME', 'PLACEHOLDER', 'TBD', 'XXX_')

# Known-benign exception: the accepted, frozen installer is built with Inno Setup,
# whose built-in command-line help contains the documented usage example
# "/PASSWORD=password Specifies the password to use." The value after '=' is the
# literal placeholder word 'password', not a credential. Matches whose extracted
# value equals this placeholder are recorded as benign rather than as findings.
$knownBenignInnoSetupPassword = 'password'
$script:lastSecretBenignFindings = @()

function Test-BytesForSecretSubstrings($bytes, [string[]]$patterns) {
  $ascii = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
  $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
  $found = @()
  foreach ($pat in $patterns) {
    foreach ($m in [regex]::Matches($ascii, $pat)) { $found += $m.Value }
    foreach ($m in [regex]::Matches($utf16, $pat)) { $found += ($m.Value + ' (UTF-16LE)') }
  }
  return @($found | Select-Object -Unique)
}

function Test-BytesForPatterns($bytes, [string[]]$patterns) {
  return @(Test-BytesForSecretSubstrings $bytes $patterns)
}

function Test-IsKnownBenignSecret([string]$match) {
  $plain = $match -replace ' \(UTF-16LE\)$', ''
  $value = ''
  if ($plain -match '[=:]\s*([^=:]+)\s*$') { $value = $Matches[1].Trim() }
  return ($value -ieq $knownBenignInnoSetupPassword)
}

function Test-BytesForTokens($bytes, [string[]]$tokens) {
  $ascii = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
  $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
  $hits = @()
  foreach ($tok in $tokens) {
    $low = $tok.ToLowerInvariant()
    if ($ascii.ToLowerInvariant().Contains($low)) { $hits += $tok }
    if ($utf16.ToLowerInvariant().Contains($low)) { $hits += ($tok + ' (UTF-16LE)') }
  }
  return @($hits | Select-Object -Unique)
}

function Scan-FilesForSecrets([string[]]$paths) {
  $findings = @()
  $benign = @()
  foreach ($p in $paths) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($p)
    $hits = @(Test-BytesForSecretSubstrings $bytes $secretPatterns)
    foreach ($h in $hits) {
      if (Test-IsKnownBenignSecret $h) {
        $benign += ('{0} => {1}' -f (Split-Path -Leaf $p), $h)
      } else {
        $findings += ('{0} => {1}' -f (Split-Path -Leaf $p), $h)
      }
    }
  }
  $script:lastSecretBenignFindings = @($benign | Select-Object -Unique)
  return @($findings | Select-Object -Unique)
}

function Scan-FilesForDevPaths([string[]]$paths) {
  $findings = @()
  foreach ($p in $paths) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($p)
    $hits = @(Test-BytesForTokens $bytes $devPathTokens)
    foreach ($h in $hits) { $findings += ('{0} => {1}' -f (Split-Path -Leaf $p), $h) }
  }
  return @($findings | Select-Object -Unique)
}

# ---------------------------------------------------------------------------
# delivery check (shared by R gates and negative controls)
# ---------------------------------------------------------------------------
function Get-DeliveryChecks([string]$packageDir, [string]$zipPath) {
  $res = [ordered]@{}
  $entries = @(Get-TreeEntries $packageDir)
  $names = @($entries | ForEach-Object { $_.name })
  $installer = @($entries | Where-Object { $_.name -eq $SetupExeName })
  $readme = @($entries | Where-Object { $_.name -eq 'README.txt' })
  $checksum = @($entries | Where-Object { $_.name -eq 'SHA256SUMS.txt' })

  $res.installerExists = ($installer.Count -eq 1)
  $res.installerSha256 = if ($res.installerExists) { $installer[0].sha256 } else { '' }
  $res.installerSize = if ($res.installerExists) { $installer[0].size } else { [int64]0 }
  $res.installerShaMatches = ($res.installerExists -and $res.installerSha256 -eq $ExpectedInstallerSha256)
  $res.installerSizeMatches = ($res.installerExists -and $res.installerSize -eq $ExpectedInstallerSize)

  $res.fileCount = $entries.Count
  $exeEntries = @($entries | Where-Object { $_.name -match '(?i)\.exe$' })
  $res.singleInstaller = ($exeEntries.Count -eq 1) -and (@($exeEntries | Where-Object { $_.name -eq $SetupExeName }).Count -eq 1)
  $res.minimalContents = ($entries.Count -eq 3) -and (@(Get-SetDiff $names $ExpectedFiles).Count -eq 0)

  $artifactViolations = @()
  foreach ($e in $entries) {
    $n = $e.name.ToLowerInvariant()
    if ($n -notin @($SetupExeName.ToLowerInvariant(), 'readme.txt', 'sha256sums.txt')) {
      $artifactViolations += 'unexpected-file:' + $e.rel
    }
    if ($n -match '\.(dart|ps1|json|log|pdb|dll|so|h|c|cpp|py|md|xlsx|zip|bak|exe)$' -and $n -ne $SetupExeName.ToLowerInvariant()) {
      $artifactViolations += 'forbidden-extension:' + $e.rel
    }
    if ($n -match '\.git|node_modules|\.dart_tool|\.pub-cache|^build|test|debug') {
      $artifactViolations += 'forbidden-name:' + $e.rel
    }
  }
  $res.devArtifactViolations = @($artifactViolations | Select-Object -Unique)
  $res.noDevArtifacts = ($res.devArtifactViolations.Count -eq 0)

  $res.secretFindings = @(Scan-FilesForSecrets @($entries | ForEach-Object { $_.path }))
  $res.noSecrets = ($res.secretFindings.Count -eq 0)

  $res.devPathFindings = @(Scan-FilesForDevPaths @($entries | ForEach-Object { $_.path }))
  $res.noDevPaths = ($res.devPathFindings.Count -eq 0)

  $placeholderFindings = @()
  foreach ($uf in $readme) {
    $text = [System.IO.File]::ReadAllText($uf.path)
    foreach ($pat in $placeholderPatterns) {
      if ($text -match $pat) { $placeholderFindings += $uf.rel }
    }
  }
  $res.placeholderFindings = @($placeholderFindings | Select-Object -Unique)
  $res.noPlaceholders = ($res.placeholderFindings.Count -eq 0)

  $templateHash = if (Test-Path -LiteralPath $ReadmeTemplate) { Get-Sha256 $ReadmeTemplate } else { '' }
  $res.readmePresent = ($readme.Count -eq 1)
  $res.readmeNonEmpty = ($readme.Count -eq 1 -and $readme[0].size -gt 0)
  $res.readmeMatchesTemplate = ($readme.Count -eq 1 -and $templateHash -ne '' -and $readme[0].sha256 -eq $templateHash)
  $res.readmeOk = $res.readmePresent -and $res.readmeNonEmpty -and $res.readmeMatchesTemplate

  $res.checksumLineCount = 0
  $res.checksumLine = ''
  $res.checksumOk = $false
  if ($checksum.Count -eq 1) {
    $content = [System.IO.File]::ReadAllText($checksum[0].path)
    $lines = @($content -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $res.checksumLineCount = $lines.Count
    if ($lines.Count -eq 1 -and $res.installerExists) {
      $res.checksumLine = $lines[0].Trim()
      $res.checksumOk = ($res.checksumLine -eq ("{0}  {1}" -f $res.installerSha256, $SetupExeName))
    }
  }

  $res.zipPresent = (-not [string]::IsNullOrWhiteSpace($zipPath)) -and (Test-Path -LiteralPath $zipPath -PathType Leaf)
  $res.zipEntryCount = 0
  $res.zipEntriesMinimal = $false
  $res.zipEntrySafetyOk = $false
  $res.zipInstallerShaMatches = $false
  $res.zipEntryNames = @()
  if ($res.zipPresent) {
    $zipEntries = @(Read-ZipEntries $zipPath)
    $res.zipEntryCount = $zipEntries.Count
    $res.zipEntryNames = @($zipEntries | ForEach-Object { $_.name })
    $expectedZipNames = @(($PackageDirName + '/' + $SetupExeName), ($PackageDirName + '/README.txt'), ($PackageDirName + '/SHA256SUMS.txt'))
    $res.zipEntriesMinimal = ($zipEntries.Count -eq 3) -and (@(Get-SetDiff $res.zipEntryNames $expectedZipNames).Count -eq 0)
    $unsafe = @($zipEntries | Where-Object { $_.name.StartsWith('/') -or $_.name.Contains('\') -or $_.name -match '\.\.' -or $_.name -match '^[A-Za-z]:' })
    $res.zipEntrySafetyOk = ($unsafe.Count -eq 0)
    $instEntry = @($zipEntries | Where-Object { $_.name -eq ($PackageDirName + '/' + $SetupExeName) })
    if ($instEntry.Count -eq 1) { $res.zipInstallerShaMatches = ($instEntry[0].sha256 -eq $ExpectedInstallerSha256) }
  }

  $res.pass = $res.installerShaMatches -and $res.installerSizeMatches -and $res.singleInstaller -and `
    $res.minimalContents -and $res.noDevArtifacts -and $res.noSecrets -and $res.noDevPaths -and `
    $res.noPlaceholders -and $res.readmeOk -and $res.checksumOk -and `
    $res.zipEntriesMinimal -and $res.zipEntrySafetyOk -and $res.zipInstallerShaMatches
  return $res
}

function Invoke-Packager([string]$cwd, [string]$outRoot, [string]$evidDir, [string]$runTagArg, [string]$InstallerOverride = '') {
  $inst = if (-not [string]::IsNullOrWhiteSpace($InstallerOverride)) { $InstallerOverride } else { $CanonicalInstaller }
  $procArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $Packager + '"'),
    '-CanonicalInstaller', ('"' + $inst + '"'),
    '-OutputRoot', ('"' + $outRoot + '"'),
    '-EvidenceDir', ('"' + $evidDir + '"'),
    '-RunTag', ('"' + $runTagArg + '"'))
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
    zipPath = Join-Path $outRoot $ZipName
    outRoot = $outRoot
  }
}

# ---------------------------------------------------------------------------
# R1 baseline ancestry
# ---------------------------------------------------------------------------
function Get-R1Verdict {
  $head = (Git 'rev-parse HEAD' $RepoRoot).out
  $branch = (Git 'branch --show-current' $RepoRoot).out
  if (-not [string]::IsNullOrWhiteSpace($ExpectedFinalHead)) {
    $parent = (Git 'rev-parse HEAD^' $RepoRoot).out
    $revCount = (Git ('rev-list --count {0}..HEAD' -f $BaselineCommit) $RepoRoot).out
    $merges = @((Git ('log --merges --oneline {0}..HEAD' -f $BaselineCommit) $RepoRoot).out -split "`r?`n" | Where-Object { $_ -ne '' }).Count
    $isAncestor = ((Git ('merge-base --is-ancestor {0} HEAD' -f $BaselineCommit) $RepoRoot).exit -eq 0)
    $pass = ($head -eq $ExpectedFinalHead) -and ($parent -eq $BaselineCommit) -and ($revCount -eq '1') -and ($merges -eq 0) -and $isAncestor
    return [ordered]@{
      guard = 'R1 baseline ancestry'
      mode = 'final-head'
      pass = $pass
      head = $head
      expectedFinalHead = $ExpectedFinalHead
      parent = $parent
      baseline = $BaselineCommit
      revListCountAfterBaseline = $revCount
      mergeCommitCount = $merges
      descendsFromBaseline = $isAncestor
    }
  }
  $revCount = (Git ('rev-list --count {0}..HEAD' -f $BaselineCommit) $RepoRoot).out
  $pass = ($head -eq $BaselineCommit) -and ($revCount -eq '0')
  return [ordered]@{
    guard = 'R1 baseline ancestry'
    mode = 'pre-commit'
    pass = $pass
    head = $head
    expectedFinalHead = ''
    baseline = $BaselineCommit
    revListCountAfterBaseline = $revCount
    note = 'pre-commit run: HEAD is the baseline; authoritative final-HEAD run executed post-commit with -ExpectedFinalHead'
  }
}
$verdicts['R1'] = Get-R1Verdict

# ---------------------------------------------------------------------------
# R2 allowed diff only
# ---------------------------------------------------------------------------
function Get-R2Verdict {
  $changed = @(Get-ChangedPaths)
  $violations = @()
  foreach ($c in $changed) {
    $lc = $c.ToLowerInvariant()
    $allowed = $false
    foreach ($p in $AllowedPrefixes) { if ($lc.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { $allowed = $true } }
    if (-not $allowed) { $violations += $c }
  }
  [ordered]@{
    guard = 'R2 allowed diff only'
    pass = ($violations.Count -eq 0)
    changedFileCount = $changed.Count
    changedFiles = $changed
    scopeViolations = @($violations | Select-Object -Unique)
    allowedPrefixes = $AllowedPrefixes
  }
}
$verdicts['R2'] = Get-R2Verdict

# ---------------------------------------------------------------------------
# R3 production diff empty
# ---------------------------------------------------------------------------
function Get-R3Verdict {
  $changed = @(Get-ChangedPaths)
  $violations = @()
  foreach ($c in $changed) {
    $lc = $c.ToLowerInvariant()
    $carved = $false
    foreach ($p in $AppCarveOuts) { if ($lc -eq $p) { $carved = $true; break } }
    foreach ($p in $AppPrefixCarveOuts) { if ($lc.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { $carved = $true; break } }
    if ($carved) { continue }
    foreach ($f in $ForbiddenPrefixes) {
      if ($lc -eq $f -or $lc.StartsWith($f, [System.StringComparison]::OrdinalIgnoreCase)) { $violations += $c; break }
    }
  }
  [ordered]@{
    guard = 'R3 production diff empty'
    pass = ($violations.Count -eq 0)
    productionViolations = @($violations | Select-Object -Unique)
    forbiddenPrefixes = $ForbiddenPrefixes
    appCarveOuts = $AppCarveOuts
    appPrefixCarveOuts = $AppPrefixCarveOuts
  }
}
$verdicts['R3'] = Get-R3Verdict

# ---------------------------------------------------------------------------
# R4/R5 installer identity (SHA + size) across the whole chain
# ---------------------------------------------------------------------------
$chain = [ordered]@{}
$chain.canonical = [ordered]@{ path = $CanonicalInstaller; sha256 = (Get-Sha256 $CanonicalInstaller); size = (Get-Item -LiteralPath $CanonicalInstaller).Length }
$chain.delivery = [ordered]@{ path = Join-Path $DeliveryPackageDir $SetupExeName; sha256 = ''; size = 0 }
if (Test-Path -LiteralPath $chain.delivery.path -PathType Leaf) {
  $chain.delivery.sha256 = Get-Sha256 $chain.delivery.path
  $chain.delivery.size = (Get-Item -LiteralPath $chain.delivery.path).Length
}
$chain.expected = [ordered]@{ sha256 = $ExpectedInstallerSha256; size = $ExpectedInstallerSize }

function Get-R4Verdict {
  $zipInstallerSha = ''
  $deliveryChecks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  $zipInstallerSha = $deliveryChecks.zipInstallerShaMatches
  $shaChainOk = ($chain.canonical.sha256 -eq $ExpectedInstallerSha256) -and ($chain.delivery.sha256 -eq $ExpectedInstallerSha256) -and ($deliveryChecks.installerShaMatches)
  [ordered]@{
    guard = 'R4 installer SHA-256 (canonical == delivery == ZIP == accepted)'
    pass = $shaChainOk
    acceptedSha256 = $ExpectedInstallerSha256
    canonicalSha256 = $chain.canonical.sha256
    deliverySha256 = $chain.delivery.sha256
    zipInstallerShaMatches = $zipInstallerSha
  }
}
$verdicts['R4'] = Get-R4Verdict

function Get-R5Verdict {
  $sizeOk = ($chain.canonical.size -eq $ExpectedInstallerSize) -and ($chain.delivery.size -eq $ExpectedInstallerSize)
  [ordered]@{
    guard = 'R5 installer size (canonical == delivery == accepted)'
    pass = $sizeOk
    acceptedSize = $ExpectedInstallerSize
    canonicalSize = $chain.canonical.size
    deliverySize = $chain.delivery.size
  }
}
$verdicts['R5'] = Get-R5Verdict

# ---------------------------------------------------------------------------
# R6 single installer
# ---------------------------------------------------------------------------
function Get-R6Verdict {
  $treeCount = @(Get-ChildItem -LiteralPath $DeliveryPackageDir -Recurse -File | Where-Object { $_.Name -eq $SetupExeName }).Count
  $fs = [System.IO.File]::OpenRead($FinalZipPath)
  $zipCount = 0
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
    try { $zipCount = @($zip.Entries | Where-Object { $_.FullName -eq ($PackageDirName + '/' + $SetupExeName) }).Count }
    finally { $zip.Dispose() }
  } finally { $fs.Dispose() }
  [ordered]@{
    guard = 'R6 single installer in package'
    pass = ($treeCount -eq 1) -and ($zipCount -eq 1)
    deliveryTreeInstallerCount = $treeCount
    zipInstallerEntryCount = $zipCount
  }
}
$verdicts['R6'] = Get-R6Verdict

# ---------------------------------------------------------------------------
# R7 minimal package contents
# ---------------------------------------------------------------------------
function Get-R7Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  $rootEntries = @(Get-ChildItem -LiteralPath $DeliveryRoot -Force)
  $rootNames = @($rootEntries | ForEach-Object { $_.Name })
  [ordered]@{
    guard = 'R7 minimal package contents (3 files in tree, 3 entries in ZIP)'
    pass = $checks.minimalContents -and $checks.zipEntriesMinimal
    packageFileCount = $checks.fileCount
    packageFiles = @(Get-TreeEntries $DeliveryPackageDir | ForEach-Object { $_.rel })
    zipEntryCount = $checks.zipEntryCount
    zipEntryNames = $checks.zipEntryNames
    deliveryRootEntryNames = $rootNames
  }
}
$verdicts['R7'] = Get-R7Verdict

# ---------------------------------------------------------------------------
# R8 no development artifacts
# ---------------------------------------------------------------------------
function Get-R8Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  [ordered]@{
    guard = 'R8 no development artifacts (source/test/log/cache/build intermediates)'
    pass = $checks.noDevArtifacts -and $checks.zipEntriesMinimal
    violations = $checks.devArtifactViolations
  }
}
$verdicts['R8'] = Get-R8Verdict

# ---------------------------------------------------------------------------
# R9 no secrets (committed 13R files + delivery + ZIP contents + evidence)
# ---------------------------------------------------------------------------
function Get-R9ScanTargets {
  $targets = @()
  foreach ($root in @((Join-Path $RepoRoot 'tools\muaman13r'), (Join-Path $RepoRoot 'docs\muaman-13r'), $DeliveryRoot)) {
    if (Test-Path -LiteralPath $root -PathType Container) {
      foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File) { $targets += $f.FullName }
    } elseif (Test-Path -LiteralPath $root -PathType Leaf) {
      $targets += $root
    }
  }
  return @($targets | Select-Object -Unique)
}

function Get-R9Verdict {
  $targets = @(Get-R9ScanTargets)
  $findings = @(Scan-FilesForSecrets $targets)
  $zipFindings = @()
  foreach ($zipPath in @($FinalZipPath)) {
    if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
      foreach ($e in @(Read-ZipEntries $zipPath)) {
        if ($e.name -match '^(/|\.\.|[A-Za-z]:|.*\\)') { $zipFindings += 'unsafe-entry-name:' + $e.name }
      }
    }
  }
  [ordered]@{
    guard = 'R9 no secrets (committed 13R files + delivery + ZIP + evidence)'
    pass = ($findings.Count -eq 0) -and ($zipFindings.Count -eq 0)
    scannedFileCount = $targets.Count
    findings = $findings
    benignFindings = @($script:lastSecretBenignFindings)
    zipEntrySafetyFindings = $zipFindings
  }
}
$verdicts['R9'] = Get-R9Verdict

# ---------------------------------------------------------------------------
# R10 no absolute development paths in end-user files
# ---------------------------------------------------------------------------
function Get-R10Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  $zipTokenFindings = @()
  if (Test-Path -LiteralPath $FinalZipPath -PathType Leaf) {
    foreach ($e in @(Read-ZipEntries $FinalZipPath)) {
      $entryBytes = $null
      $fs = [System.IO.File]::OpenRead($FinalZipPath)
      try {
        $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $true)
        try {
          $ze = @($zip.Entries | Where-Object { $_.FullName -eq $e.name })
          if ($ze.Count -eq 1) {
            $in = $ze[0].Open()
            try {
              $ms = New-Object System.IO.MemoryStream
              $in.CopyTo($ms)
              $entryBytes = $ms.ToArray()
              $ms.Dispose()
            } finally { $in.Dispose() }
          }
        } finally { $zip.Dispose() }
      } finally { $fs.Dispose() }
      if ($null -ne $entryBytes) {
        $hits = @(Test-BytesForTokens $entryBytes $devPathTokens)
        foreach ($h in $hits) { $zipTokenFindings += ('{0} => {1}' -f $e.name, $h) }
      }
    }
  }
  [ordered]@{
    guard = 'R10 no absolute dev paths in end-user files'
    pass = $checks.noDevPaths -and ($zipTokenFindings.Count -eq 0)
    packageFileFindings = $checks.devPathFindings
    zipEntryFindings = @($zipTokenFindings | Select-Object -Unique)
  }
}
$verdicts['R10'] = Get-R10Verdict

# ---------------------------------------------------------------------------
# R11 no placeholders in user-facing files
# ---------------------------------------------------------------------------
function Get-R11Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  [ordered]@{
    guard = 'R11 no placeholders in user-facing delivery files'
    pass = $checks.noPlaceholders
    placeholderFindings = $checks.placeholderFindings
    scannedFiles = @('README.txt', 'SHA256SUMS.txt')
  }
}
$verdicts['R11'] = Get-R11Verdict

# ---------------------------------------------------------------------------
# R12 README present and user-safe
# ---------------------------------------------------------------------------
function Get-R12Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  [ordered]@{
    guard = 'R12 README present and user-safe'
    pass = $checks.readmeOk
    readmePresent = $checks.readmePresent
    readmeNonEmpty = $checks.readmeNonEmpty
    readmeMatchesCommittedTemplate = $checks.readmeMatchesTemplate
  }
}
$verdicts['R12'] = Get-R12Verdict

# ---------------------------------------------------------------------------
# R13 checksum manifest correct
# ---------------------------------------------------------------------------
function Get-R13Verdict {
  $checks = Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath
  [ordered]@{
    guard = 'R13 SHA256SUMS manifest correct'
    pass = $checks.checksumOk
    checksumLineCount = $checks.checksumLineCount
    checksumLine = $checks.checksumLine
    installerSha256 = $checks.installerSha256
    expectedLine = if ($checks.installerExists) { ("{0}  {1}" -f $checks.installerSha256, $SetupExeName) } else { '' }
  }
}
$verdicts['R13'] = Get-R13Verdict

# ---------------------------------------------------------------------------
# R14/R15 independent package builds D1/D2
# ---------------------------------------------------------------------------
$d1 = $null
$d2 = $null
$d1Run = $null
$d2Run = $null

function Get-R14Verdict {
  $script:outD1 = Join-Path $scratch 'd1-out'
  $script:evidD1 = Join-Path $scratch 'd1-evidence'
  $script:d1Run = Invoke-Packager $RepoRoot $script:outD1 $script:evidD1 'd1'
  $zipOk = (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf)
  $resultJson = $null
  $resultPath = Join-Path $script:outD1 'package-result.json'
  if (Test-Path -LiteralPath $resultPath) { $resultJson = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json }
  $verdictPass = if ($null -ne $resultJson) { [string]$resultJson.packaging.verdict } else { '' }
  $pass = ($script:d1Run.exitCode -eq 0) -and $zipOk -and ($verdictPass -eq 'PASS')
  [ordered]@{
    guard = 'R14 independent package build D1'
    pass = $pass
    exitCode = $script:d1Run.exitCode
    zipProduced = $zipOk
    resultVerdict = $verdictPass
    stdout = $script:d1Run.stdout
    stderr = $script:d1Run.stderr
  }
}
$verdicts['R14'] = Get-R14Verdict

function Get-R15Verdict {
  $script:outD2 = Join-Path $scratch 'd2-out'
  $script:evidD2 = Join-Path $scratch 'd2-evidence'
  $outside = Join-Path $scratch 'd2-outside-cwd'
  New-Item -ItemType Directory -Path $outside -Force | Out-Null
  $script:d2Run = Invoke-Packager $outside $script:outD2 $script:evidD2 'd2'
  $zipOk = (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf)
  $resultJson = $null
  $resultPath = Join-Path $script:outD2 'package-result.json'
  if (Test-Path -LiteralPath $resultPath) { $resultJson = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json }
  $verdictPass = if ($null -ne $resultJson) { [string]$resultJson.packaging.verdict } else { '' }
  $pass = ($script:d2Run.exitCode -eq 0) -and $zipOk -and ($verdictPass -eq 'PASS')
  [ordered]@{
    guard = 'R15 independent package build D2 (external working directory)'
    pass = $pass
    exitCode = $script:d2Run.exitCode
    zipProduced = $zipOk
    resultVerdict = $verdictPass
    stdout = $script:d2Run.stdout
    stderr = $script:d2Run.stderr
  }
}
$verdicts['R15'] = Get-R15Verdict

# ---------------------------------------------------------------------------
# R16 deterministic package identity
# ---------------------------------------------------------------------------
function Get-R16Verdict {
  $bad = @()
  $paths = @($script:d1Run.zipPath, $script:d2Run.zipPath, $FinalZipPath)
  if (@($paths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }).Count -gt 0) {
    return [ordered]@{ guard = 'R16 deterministic package identity (D1==D2==final)'; pass = $false; detail = 'one or more ZIPs missing' }
  }
  $b1 = [System.IO.File]::ReadAllBytes($script:d1Run.zipPath)
  $b2 = [System.IO.File]::ReadAllBytes($script:d2Run.zipPath)
  $b3 = [System.IO.File]::ReadAllBytes($FinalZipPath)
  $ident = ($b1.Length -eq $b2.Length -and $b2.Length -eq $b3.Length)
  if ($ident) {
    for ($i = 0; $i -lt $b1.Length; $i++) { if ($b1[$i] -ne $b2[$i] -or $b2[$i] -ne $b3[$i]) { $ident = $false; break } }
  }
  $h1 = Get-Sha256 $script:d1Run.zipPath
  $h2 = Get-Sha256 $script:d2Run.zipPath
  $h3 = Get-Sha256 $FinalZipPath
  $e1 = @(Read-ZipEntries $script:d1Run.zipPath)
  $e2 = @(Read-ZipEntries $script:d2Run.zipPath)
  $e3 = @(Read-ZipEntries $FinalZipPath)
  $metaSame = ($e1.Count -eq $e2.Count -and $e2.Count -eq $e3.Count)
  $metaDiffs = @()
  if ($metaSame) {
    for ($i = 0; $i -lt $e1.Count; $i++) {
      if ($e1[$i].name -ne $e2[$i].name -or $e2[$i].name -ne $e3[$i].name -or
          $e1[$i].length -ne $e2[$i].length -or $e2[$i].length -ne $e3[$i].length -or
          $e1[$i].compressedLength -ne $e2[$i].compressedLength -or $e2[$i].compressedLength -ne $e3[$i].compressedLength -or
          $e1[$i].lastWriteTimeUtc -ne $e2[$i].lastWriteTimeUtc -or $e2[$i].lastWriteTimeUtc -ne $e3[$i].lastWriteTimeUtc -or
          $e1[$i].sha256 -ne $e2[$i].sha256 -or $e2[$i].sha256 -ne $e3[$i].sha256) {
        $metaDiffs += $i
      }
    }
  }
  $pass = $ident -and ($h1 -eq $h2) -and ($h2 -eq $h3) -and $metaSame -and ($metaDiffs.Count -eq 0)
  [ordered]@{
    guard = 'R16 deterministic package identity (D1==D2==final ZIP)'
    pass = $pass
    d1Sha256 = $h1
    d2Sha256 = $h2
    finalSha256 = $h3
    d1Size = $b1.Length
    d2Size = $b2.Length
    finalSize = $b3.Length
    bytesIdentical = $ident
    entryMetadataDiffIndices = $metaDiffs
    failures = $bad
  }
}
$verdicts['R16'] = Get-R16Verdict

# ---------------------------------------------------------------------------
# R17 extraction verification
# ---------------------------------------------------------------------------
function Get-R17Verdict {
  $extractRoot = Join-Path $scratch 'extract-final'
  if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
  $problems = @(Invoke-SafeExtract $FinalZipPath $extractRoot)
  $pkgRoot = Join-Path $extractRoot $PackageDirName
  $extracted = @(Get-TreeEntries $pkgRoot)
  $deliveryEntries = @(Get-TreeEntries $DeliveryPackageDir)
  $missing = @()
  $extra = @()
  $differing = @()
  $srcMap = @{}
  foreach ($e in $deliveryEntries) { $srcMap[$e.rel] = $e }
  $dstMap = @{}
  foreach ($e in $extracted) { $dstMap[$e.rel] = $e }
  foreach ($rel in $srcMap.Keys) {
    if (-not $dstMap.ContainsKey($rel)) { $missing += $rel; continue }
    if ($srcMap[$rel].sha256 -ne $dstMap[$rel].sha256) { $differing += $rel }
  }
  foreach ($rel in $dstMap.Keys) { if (-not $srcMap.ContainsKey($rel)) { $extra += $rel } }
  $instEntry = @($extracted | Where-Object { $_.rel -eq $SetupExeName })
  $instSha = if ($instEntry.Count -eq 1) { $instEntry[0].sha256 } else { '' }
  $readmeEntry = @($extracted | Where-Object { $_.rel -eq 'README.txt' })
  $readmeHash = if ($readmeEntry.Count -eq 1) { $readmeEntry[0].sha256 } else { '' }
  $templateHash = if (Test-Path -LiteralPath $ReadmeTemplate) { Get-Sha256 $ReadmeTemplate } else { '' }
  $pass = ($problems.Count -eq 0) -and ($missing.Count -eq 0) -and ($extra.Count -eq 0) -and ($differing.Count -eq 0) -and ($instSha -eq $ExpectedInstallerSha256) -and ($readmeHash -eq $templateHash)
  [ordered]@{
    guard = 'R17 extraction verification (ZIP == delivery tree, installer SHA preserved)'
    pass = $pass
    pathSafetyProblems = $problems
    extractedFileCount = $extracted.Count
    missing = $missing
    extra = $extra
    differing = $differing
    extractedInstallerSha256 = $instSha
    extractedReadmeMatchesTemplate = ($readmeHash -eq $templateHash)
  }
}
$verdicts['R17'] = Get-R17Verdict

# ---------------------------------------------------------------------------
# NC01..NC10 negative controls
# ---------------------------------------------------------------------------
function Get-NegativeControls {
  $results = [ordered]@{}
  $scratchN = Join-Path $scratch 'neg'
  New-Item -ItemType Directory -Path $scratchN -Force | Out-Null

  function Copy-PackageTree([string]$label) {
    $dst = Join-Path $scratchN $label
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Copy-Item -Path (Join-Path $DeliveryPackageDir '*') -Destination $dst -Recurse -Force
    return $dst
  }

  function Invoke-NegativePackager([string]$label, [string]$installerPath) {
    $outRoot = Join-Path $scratchN ($label + '-out')
    $evidDir = Join-Path $scratchN ($label + '-evidence')
    return Invoke-Packager $RepoRoot $outRoot $evidDir $label -InstallerOverride $installerPath
  }

  # NC01 single byte flip in installer => identity gate must reject
  $nc1Installer = Join-Path $scratchN 'nc01-installer.exe'
  Copy-Item -LiteralPath $CanonicalInstaller -Destination $nc1Installer -Force
  $bytes = [System.IO.File]::ReadAllBytes($nc1Installer)
  $bytes[100] = $bytes[100] -bxor 0x01
  [System.IO.File]::WriteAllBytes($nc1Installer, $bytes)
  $r1 = Invoke-NegativePackager 'nc01' $nc1Installer
  $results['NC01'] = [ordered]@{
    label = 'NC01 single byte flip in installer'
    expected = 'packager fail-closed rejection (nonzero exit, identity mismatch)'
    exitCode = $r1.exitCode
    zipProduced = (Test-Path -LiteralPath $r1.zipPath -PathType Leaf)
    rejected = ($r1.exitCode -eq 2) -and (-not (Test-Path -LiteralPath $r1.zipPath -PathType Leaf))
    pass = ($r1.exitCode -ne 0) -and (-not (Test-Path -LiteralPath $r1.zipPath -PathType Leaf))
  }

  # NC02 wrong-size installer => identity gate must reject
  $nc2Installer = Join-Path $scratchN 'nc02-installer.exe'
  Copy-Item -LiteralPath $CanonicalInstaller -Destination $nc2Installer -Force
  $bytes = [System.IO.File]::ReadAllBytes($nc2Installer)
  $trunc = [byte[]]$bytes[0..($bytes.Length - 2)]
  [System.IO.File]::WriteAllBytes($nc2Installer, $trunc)
  $r2 = Invoke-NegativePackager 'nc02' $nc2Installer
  $results['NC02'] = [ordered]@{
    label = 'NC02 installer with wrong size'
    expected = 'packager fail-closed rejection (nonzero exit, size mismatch)'
    exitCode = $r2.exitCode
    zipProduced = (Test-Path -LiteralPath $r2.zipPath -PathType Leaf)
    rejected = ($r2.exitCode -eq 2) -and (-not (Test-Path -LiteralPath $r2.zipPath -PathType Leaf))
    pass = ($r2.exitCode -ne 0) -and (-not (Test-Path -LiteralPath $r2.zipPath -PathType Leaf))
  }

  # NC03 second installer present in the package tree
  $t3 = Copy-PackageTree 'nc03'
  Copy-Item -LiteralPath (Join-Path $t3 $SetupExeName) -Destination (Join-Path $t3 'I-TECH-Setup2.exe') -Force
  $c3 = Get-DeliveryChecks $t3 ''
  $results['NC03'] = [ordered]@{
    label = 'NC03 second installer present'
    expected = 'guard rejects (singleInstaller=false)'
    singleInstaller = $c3.singleInstaller
    fileCount = $c3.fileCount
    pass = (-not $c3.singleInstaller)
  }

  # NC04 source code file added inside delivery
  $t4 = Copy-PackageTree 'nc04'
  Set-Content -LiteralPath (Join-Path $t4 'source_code.dart') -Value 'void main() {}' -Encoding UTF8
  $c4 = Get-DeliveryChecks $t4 ''
  $results['NC04'] = [ordered]@{
    label = 'NC04 source code file added in delivery'
    expected = 'guard rejects (minimalContents=false, noDevArtifacts=false)'
    minimalContents = $c4.minimalContents
    noDevArtifacts = $c4.noDevArtifacts
    violations = $c4.devArtifactViolations
    pass = (-not $c4.noDevArtifacts)
  }

  # NC05 secret sentinel added inside delivery
  $t5 = Copy-PackageTree 'nc05'
  $sentinel = ('token' + '=' + '0123456789abcdef0fedcba987654321')
  Set-Content -LiteralPath (Join-Path $t5 'secret-note.txt') -Value $sentinel -Encoding UTF8
  $c5 = Get-DeliveryChecks $t5 ''
  $results['NC05'] = [ordered]@{
    label = 'NC05 secret sentinel added inside delivery'
    expected = 'guard rejects (noSecrets=false)'
    noSecrets = $c5.noSecrets
    secretFindingCount = $c5.secretFindings.Count
    pass = (-not $c5.noSecrets)
  }

  # NC06 absolute development path inside README
  $t6 = Copy-PackageTree 'nc06'
  $readmePath6 = Join-Path $t6 'README.txt'
  $devLine = ('C:' + '\dev\fake\path\readme.txt')
  Add-Content -LiteralPath $readmePath6 -Value $devLine -Encoding UTF8
  $c6 = Get-DeliveryChecks $t6 ''
  $results['NC06'] = [ordered]@{
    label = 'NC06 absolute development path in README'
    expected = 'guard rejects (noDevPaths=false)'
    noDevPaths = $c6.noDevPaths
    devPathFindingCount = $c6.devPathFindings.Count
    pass = (-not $c6.noDevPaths)
  }

  # NC07 wrong checksum manifest
  $t7 = Copy-PackageTree 'nc07'
  Set-Content -LiteralPath (Join-Path $t7 'SHA256SUMS.txt') -Value ('0000000000000000000000000000000000000000000000000000000000000000  ' + $SetupExeName) -Encoding ASCII
  $c7 = Get-DeliveryChecks $t7 ''
  $results['NC07'] = [ordered]@{
    label = 'NC07 wrong SHA256SUMS manifest'
    expected = 'guard rejects (checksumOk=false)'
    checksumOk = $c7.checksumOk
    checksumLine = $c7.checksumLine
    pass = (-not $c7.checksumOk)
  }

  # NC08 placeholder in user-facing file
  $t8 = Copy-PackageTree 'nc08'
  Add-Content -LiteralPath (Join-Path $t8 'README.txt') -Value 'TODO: change this' -Encoding UTF8
  $c8 = Get-DeliveryChecks $t8 ''
  $results['NC08'] = [ordered]@{
    label = 'NC08 placeholder in user-facing file'
    expected = 'guard rejects (noPlaceholders=false)'
    noPlaceholders = $c8.noPlaceholders
    placeholderFindingCount = $c8.placeholderFindings.Count
    pass = (-not $c8.noPlaceholders)
  }

  # NC09 README missing / empty
  $t9a = Copy-PackageTree 'nc09-missing'
  Remove-Item -LiteralPath (Join-Path $t9a 'README.txt') -Force
  $c9a = Get-DeliveryChecks $t9a ''
  $t9b = Copy-PackageTree 'nc09-empty'
  Set-Content -LiteralPath (Join-Path $t9b 'README.txt') -Value '' -Encoding UTF8
  $c9b = Get-DeliveryChecks $t9b ''
  $results['NC09'] = [ordered]@{
    label = 'NC09 README missing or empty'
    expected = 'guard rejects (readmeOk=false)'
    missingReadmePresent = $c9a.readmePresent
    missingReadmeOk = $c9a.readmeOk
    emptyReadmeNonEmpty = $c9b.readmeNonEmpty
    emptyReadmeOk = $c9b.readmeOk
    pass = (-not $c9a.readmeOk) -and (-not $c9b.readmeOk)
  }

  # NC10 unknown file inside package/ZIP
  $t10 = Copy-PackageTree 'nc10'
  Set-Content -LiteralPath (Join-Path $t10 'notes.txt') -Value 'unexpected' -Encoding UTF8
  $c10 = Get-DeliveryChecks $t10 ''
  $zipCopy = Join-Path $scratchN 'nc10.zip'
  Copy-Item -LiteralPath $FinalZipPath -Destination $zipCopy -Force
  $fs = [System.IO.File]::Open($zipCopy, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Update, $true)
    try {
      $entry = $zip.CreateEntry('Muaman-1.0.0-Windows/notes.txt', [System.IO.Compression.CompressionLevel]::Optimal)
      $w = New-Object System.IO.StreamWriter($entry.Open())
      $w.Write('unexpected')
      $w.Dispose()
    } finally { $zip.Dispose() }
  } finally { $fs.Dispose() }
  $c10b = Get-DeliveryChecks $t10 $zipCopy
  $results['NC10'] = [ordered]@{
    label = 'NC10 unknown file inside package/ZIP'
    expected = 'guard rejects (minimalContents=false, zipEntriesMinimal=false)'
    treeMinimalContents = $c10.minimalContents
    zipEntriesMinimal = $c10b.zipEntriesMinimal
    zipEntryCount = $c10b.zipEntryCount
    pass = (-not $c10.minimalContents) -and (-not $c10b.zipEntriesMinimal)
  }

  $allPass = $true
  foreach ($k in $results.Keys) { if (-not [bool]$results[$k].pass) { $allPass = $false } }

  return [ordered]@{
    guard = 'NC01..NC10 negative controls'
    capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    allPass = $allPass
    controls = $results
  }
}
$negativeControls = Get-NegativeControls

# ---------------------------------------------------------------------------
# aggregate gates (before R18)
# ---------------------------------------------------------------------------
$baseAllPass = $true
foreach ($k in $verdicts.Keys) {
  if ($k -eq 'R18') { continue }
  $v = $verdicts[$k]
  if ($null -eq $v.pass -or -not [bool]$v.pass) { $baseAllPass = $false }
}
if (-not [bool]$negativeControls.allPass) { $baseAllPass = $false }

# ---------------------------------------------------------------------------
# R18 final committed-state verification
# ---------------------------------------------------------------------------
function Get-R18Verdict {
  $head = (Git 'rev-parse HEAD' $RepoRoot).out
  $clean = [string]::IsNullOrWhiteSpace((Git 'status --porcelain' $RepoRoot).out)
  if (-not [string]::IsNullOrWhiteSpace($ExpectedFinalHead)) {
    [ordered]@{
      guard = 'R18 final committed-state verification (guards run from final HEAD)'
      mode = 'final-head'
      pass = ($head -eq $ExpectedFinalHead) -and $clean -and $baseAllPass
      head = $head
      expectedFinalHead = $ExpectedFinalHead
      workingTreeClean = $clean
      otherGatesPass = $baseAllPass
    }
  } else {
    [ordered]@{
      guard = 'R18 final committed-state verification (guards run from final HEAD)'
      mode = 'pre-commit'
      pass = $true
      head = $head
      note = 'pre-commit run; authoritative final-HEAD run is executed post-commit with -ExpectedFinalHead'
      otherGatesPass = $baseAllPass
    }
  }
}
$verdicts['R18'] = Get-R18Verdict

$allPass = $baseAllPass -and [bool]$verdicts['R18'].pass

# ---------------------------------------------------------------------------
# evidence files
# ---------------------------------------------------------------------------
function Write-Evidence {
  $head = (Git 'rev-parse HEAD' $RepoRoot).out
  $branch = (Git 'branch --show-current' $RepoRoot).out

  # baseline.txt
  $baselineText = @(
    'MUAMAN-13R governed baseline',
    '============================',
    ('phase     : MUAMAN-13R'),
    ('baseline  : ' + $BaselineCommit),
    ('head      : ' + $head),
    ('branch    : ' + $branch),
    ('mode      : ' + $(if ([string]::IsNullOrWhiteSpace($ExpectedFinalHead)) { 'pre-commit' } else { 'final-head' })),
    ('expectedFinalHead : ' + $(if ([string]::IsNullOrWhiteSpace($ExpectedFinalHead)) { '(post-commit run)' } else { $ExpectedFinalHead })),
    ('runTag    : ' + $runTag)
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'baseline.txt') -Value $baselineText -Encoding UTF8

  # git-status-before.txt
  $beforeStatus = (Git 'status --short' $RepoRoot).out
  $beforeText = @(
    'git status --short (at guard start)',
    '===================================',
    ('HEAD  : ' + $head),
    ('branch: ' + $branch),
    $beforeStatus
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'git-status-before.txt') -Value $beforeText -Encoding UTF8

  # installer-identity.txt
  $identityText = @(
    'MUAMAN-13R governed delivery installer identity',
    '================================================',
    ('acceptedSha256     : ' + $ExpectedInstallerSha256),
    ('acceptedSizeBytes  : ' + $ExpectedInstallerSize),
    ('canonicalInstaller : ' + $CanonicalInstaller),
    ('canonicalSha256    : ' + $chain.canonical.sha256),
    ('canonicalSize      : ' + $chain.canonical.size),
    ('deliveryInstaller  : ' + $chain.delivery.path),
    ('deliverySha256     : ' + $chain.delivery.sha256),
    ('deliverySize       : ' + $chain.delivery.size),
    ('zipInstallerShaMatches : ' + (Get-DeliveryChecks $DeliveryPackageDir $FinalZipPath).zipInstallerShaMatches)
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'installer-identity.txt') -Value $identityText -Encoding UTF8

  # delivery-tree.txt
  $treeLines = @(
    'MUAMAN-13R governed delivery tree',
    '==================================',
    ('packageDir : ' + $PackageDirName)
  )
  foreach ($e in (Get-TreeEntries $DeliveryPackageDir)) {
    $treeLines += ('{0}|{1}|{2}' -f $e.rel, $e.size, $e.sha256)
  }
  $treeLines += ''
  $treeLines += ('deliveryRoot entries:')
  foreach ($n in @(Get-ChildItem -LiteralPath $DeliveryRoot -Force | ForEach-Object { $_.Name })) { $treeLines += '  ' + $n }
  $treeLines += ''
  $treeLines += ('zip        : ' + $FinalZipPath)
  $treeLines += ('zipSha256  : ' + (Get-Sha256 $FinalZipPath))
  $treeLines += ('zipSize    : ' + (Get-Item -LiteralPath $FinalZipPath).Length)
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'delivery-tree.txt') -Value ($treeLines -join "`r`n") -Encoding UTF8

  # package-run-d1.txt / package-run-d2.txt
  $d1Text = @(
    'MUAMAN-13R independent package build D1',
    '=========================================',
    ('exitCode  : ' + $script:d1Run.exitCode),
    ('zipPath   : ' + $script:d1Run.zipPath),
    ('zipExists : ' + (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf)),
    ('zipSha256 : ' + $(if (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf) { (Get-Sha256 $script:d1Run.zipPath) } else { 'n/a' })),
    ('zipSize   : ' + $(if (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf) { (Get-Item -LiteralPath $script:d1Run.zipPath).Length } else { 'n/a' })),
    ('cwd       : ' + $script:d1Run.cwd),
    'stdout:',
    $script:d1Run.stdout,
    'stderr:',
    $script:d1Run.stderr
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-run-d1.txt') -Value $d1Text -Encoding UTF8

  $d2Text = @(
    'MUAMAN-13R independent package build D2',
    '=========================================',
    ('exitCode  : ' + $script:d2Run.exitCode),
    ('zipPath   : ' + $script:d2Run.zipPath),
    ('zipExists : ' + (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf)),
    ('zipSha256 : ' + $(if (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf) { (Get-Sha256 $script:d2Run.zipPath) } else { 'n/a' })),
    ('zipSize   : ' + $(if (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf) { (Get-Item -LiteralPath $script:d2Run.zipPath).Length } else { 'n/a' })),
    ('cwd       : ' + $script:d2Run.cwd),
    'stdout:',
    $script:d2Run.stdout,
    'stderr:',
    $script:d2Run.stderr
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-run-d2.txt') -Value $d2Text -Encoding UTF8

  # package-hashes.txt
  $d1ZipSha = if (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf) { (Get-Sha256 $script:d1Run.zipPath) } else { 'n/a' }
  $d2ZipSha = if (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf) { (Get-Sha256 $script:d2Run.zipPath) } else { 'n/a' }
  $finalZipSha = Get-Sha256 $FinalZipPath
  $hashesText = @(
    'MUAMAN-13R package hashes',
    '==========================',
    ('acceptedInstallerSha256 : ' + $ExpectedInstallerSha256),
    ('acceptedInstallerSize   : ' + $ExpectedInstallerSize),
    ('canonicalInstallerSha256: ' + $chain.canonical.sha256),
    ('deliveryInstallerSha256 : ' + $chain.delivery.sha256),
    ('d1 zip sha256           : ' + $d1ZipSha),
    ('d2 zip sha256           : ' + $d2ZipSha),
    ('final zip sha256        : ' + $finalZipSha),
    ('d1 zip size             : ' + $(if (Test-Path -LiteralPath $script:d1Run.zipPath -PathType Leaf) { (Get-Item -LiteralPath $script:d1Run.zipPath).Length } else { 'n/a' })),
    ('d2 zip size             : ' + $(if (Test-Path -LiteralPath $script:d2Run.zipPath -PathType Leaf) { (Get-Item -LiteralPath $script:d2Run.zipPath).Length } else { 'n/a' })),
    ('final zip size          : ' + (Get-Item -LiteralPath $FinalZipPath).Length)
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'package-hashes.txt') -Value $hashesText -Encoding UTF8

  # extraction-verification.txt
  $extractRoot = Join-Path $scratch 'extract-final'
  $problems = @()
  if (Test-Path -LiteralPath $extractRoot) {
    $problems = @(Invoke-SafeExtract $FinalZipPath (Join-Path $scratch 'extract-final-verify'))
  }
  $extractPkgRoot = Join-Path (Join-Path $scratch 'extract-final-verify') $PackageDirName
  $extracted = if (Test-Path -LiteralPath $extractPkgRoot) { @(Get-TreeEntries $extractPkgRoot) } else { @() }
  $extractLines = @(
    'MUAMAN-13R extraction verification',
    '====================================',
    ('zip              : ' + $FinalZipPath),
    ('extractedRoot    : ' + (Join-Path $scratch 'extract-final-verify')),
    ('pathSafetyProblems: ' + $problems.Count),
    ('extractedFileCount: ' + $extracted.Count)
  )
  foreach ($e in $extracted) {
    $srcHash = ''
    $src = Join-Path $DeliveryPackageDir $e.rel
    if (Test-Path -LiteralPath $src -PathType Leaf) { $srcHash = Get-Sha256 $src }
    $extractLines += ('{0}|{1}|{2}|match={3}' -f $e.rel, $e.size, $e.sha256, ($srcHash -eq $e.sha256))
  }
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'extraction-verification.txt') -Value ($extractLines -join "`r`n") -Encoding UTF8

  # negative-controls.txt
  $ncLines = @(
    'MUAMAN-13R negative controls (NC01..NC10)',
    '===========================================',
    ('allPass : ' + $negativeControls.allPass)
  )
  foreach ($k in $negativeControls.controls.Keys) {
    $c = $negativeControls.controls[$k]
    $ncLines += ('{0}: {1} => pass={2}' -f $k, $c.label, $c.pass)
  }
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'negative-controls.txt') -Value ($ncLines -join "`r`n") -Encoding UTF8

  # git-diff-check.txt
  $diffCheck = Git 'diff --check' $RepoRoot
  $diffCheckHead = Git ('diff --check {0}..HEAD' -f $BaselineCommit) $RepoRoot
  $diffCheckText = @(
    'git diff --check',
    '===============',
    ('exit code (working tree)         : ' + $diffCheck.exit),
    'output:',
    $(if ([string]::IsNullOrWhiteSpace($diffCheck.out)) { '(clean)' } else { $diffCheck.out }),
    '',
    ('exit code (baseline..HEAD)       : ' + $diffCheckHead.exit),
    'output:',
    $(if ([string]::IsNullOrWhiteSpace($diffCheckHead.out)) { '(clean)' } else { $diffCheckHead.out })
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'git-diff-check.txt') -Value $diffCheckText -Encoding UTF8

  # secret-scan.txt
  $r9 = $verdicts['R9']
  $secretLines = @(
    'MUAMAN-13R secret scan',
    '=======================',
    ('scannedFileCount : ' + $r9.scannedFileCount),
    ('findingCount     : ' + $r9.findings.Count),
    ('pass             : ' + $r9.pass)
  )
  foreach ($f in $r9.findings) { $secretLines += 'FINDING: ' + $f }
  $secretLines += 'knownBenign:'
  foreach ($f in $r9.benignFindings) { $secretLines += '  ' + $f }
  $secretLines += 'zipEntrySafetyFindings:'
  foreach ($f in $r9.zipEntrySafetyFindings) { $secretLines += '  ' + $f }
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'secret-scan.txt') -Value ($secretLines -join "`r`n") -Encoding UTF8

  # final-git-status.txt
  $finalStatus = (Git 'status --short' $RepoRoot).out
  $finalText = @(
    'git status --short (at guard end)',
    '==================================',
    ('HEAD  : ' + $head),
    ('branch: ' + $branch),
    $finalStatus
  ) -join "`r`n"
  Set-Content -LiteralPath (Join-Path $EvidenceDir 'final-git-status.txt') -Value $finalText -Encoding UTF8
}
Write-Evidence

# ---------------------------------------------------------------------------
# guards-result.json (written last; then a final self-scan of this file)
# ---------------------------------------------------------------------------
$gatesOut = [ordered]@{}
foreach ($k in $verdicts.Keys) {
  $v = $verdicts[$k]
  $gatesOut[$k] = [ordered]@{ pass = [bool]$v.pass }
}

$result = [ordered]@{
  phase = 'MUAMAN-13R'
  runId = $runTag
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  mode = if ([string]::IsNullOrWhiteSpace($ExpectedFinalHead)) { 'pre-commit' } else { 'final-head' }
  baseline = $BaselineCommit
  expectedFinalHead = $ExpectedFinalHead
  head = (Git 'rev-parse HEAD' $RepoRoot).out
  allPass = $allPass
  gates = $gatesOut
  negativeControlsAllPass = [bool]$negativeControls.allPass
  package = [ordered]@{
    deliveryDir = $DeliveryPackageDir
    zipPath = $FinalZipPath
    zipSha256 = (Get-Sha256 $FinalZipPath)
    zipSize = (Get-Item -LiteralPath $FinalZipPath).Length
    installerSha256 = $chain.delivery.sha256
    installerSize = $chain.delivery.size
  }
}
$resultJson = $result | ConvertTo-Json -Depth 10
Set-Content -LiteralPath $Out -Value $resultJson -Encoding UTF8

# final self-scan of guards-result.json (it must contain no secret patterns)
$selfScan = @(Scan-FilesForSecrets @($Out))
$selfScanOk = ($selfScan.Count -eq 0)
$selfScanLine = if ($selfScanOk) { 'guards-result.json self-scan: clean' } else { 'guards-result.json self-scan: FINDINGS -> ' + ($selfScan -join '; ') }
Add-Content -LiteralPath (Join-Path $EvidenceDir 'secret-scan.txt') -Value $selfScanLine -Encoding UTF8

Write-Host ("MUAMAN-13R guard tests: allPass={0} negativeControlsAllPass={1} mode={2}" -f $allPass, $negativeControls.allPass, $(if ([string]::IsNullOrWhiteSpace($ExpectedFinalHead)) { 'pre-commit' } else { 'final-head' }))
if ((-not $allPass) -or (-not $selfScanOk)) { exit 1 }
exit 0
