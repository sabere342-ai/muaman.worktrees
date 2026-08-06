# MUAMAN-13O guard-point verification harness (O1..O14).
#
# Verifies the mandatory acceptance gates of the deterministic Windows installer
# phase against the frozen installer contract, the canonical release package,
# and the recorded local acceptance evidence produced by
# tools/muaman13o/verify_installer_acceptance.ps1.
#
# Guards verified here:
#   O1  baseline and initial safety      repo present, descends from the MUAMAN-13N
#                                        baseline, expected branch, no tag at HEAD
#   O2  scope guard (production diff empty) working tree + commits restricted to
#                                        tools/ docs/ installer/; app/lib, app/windows,
#                                        assets, pubspec never touched
#   O3  canonical release-source guard   installer entrypoint DELEGATES packaging to
#                                        package_windows_release.ps1 and verification to
#                                        verify_release.ps1; no build/verify re-implementation;
#                                        .iss lists the 13 legal files with NO wildcards;
#                                        verify-before-compile source ordering
#   O4  installer toolchain identity     pinned ISCC.exe present with the frozen SHA-256
#   O5  installer contract guard         installer/muaman.iss matches the frozen contract
#                                        (AppId, per-user, x64, lzma2/max, shortcut policy,
#                                        no [Run], no user-data deletion)
#   O6  release manifest guard           staging verification evidence is identical to the
#                                        committed MUAMAN-13K legal manifest
#   O7  deterministic installer guard    Build A and Build B installer outputs byte-identical
#   O8  installation guard               silent install exit 0 + payload + shortcut + registration
#   O9  installed payload guard          13 payload files present with matching size + SHA-256
#   O10 installed launch guard           process alive, main window visible, clean shutdown,
#                                        payload files unchanged after launch
#   O11 module-origin guard              every loaded module originates from the install root
#                                        or the Windows directory
#   O12 uninstallation guard             payload/uninstaller/shortcut/registry removed,
#                                        no process left, business data preserved
#   O13 negative-control guard           tampered staging rejected (nonzero exit, no installer)
#   O14 final lineage guard              (post-commit only) clean tree, exactly one commit,
#                                        no merges, no tag, scope + production-diff proof
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File guard_tests_13o.ps1 ^
#       -RepoRoot <dir> -Out <json> -AcceptanceRoot <evidence-dir> -ReleaseDir <dir> ^
#       [-CompilerPath <file>] [-InstallerA <file>] [-InstallerB <file>] ^
#       [-BaselineCommit <sha>] [-ExpectedBranch <name>] [-IncludeO14]

param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$AcceptanceRoot,
  [string]$ReleaseDir = '',
  [string]$CompilerPath = '',
  [string]$InstallerA = '',
  [string]$InstallerB = '',
  [string]$BaselineCommit = 'bacac28e63148063f47dae73c808bfb53b6394da',
  [string]$ExpectedBranch = 'codex/muaman-13o-deterministic-windows-installer-local-acceptance',
  [switch]$IncludeO14
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Out = [System.IO.Path]::GetFullPath($Out)
$AcceptanceRoot = [System.IO.Path]::GetFullPath($AcceptanceRoot)
if ([string]::IsNullOrWhiteSpace($ReleaseDir)) {
  if ([string]::IsNullOrEmpty($env:M13O_RELEASE_DIR)) {
    $ReleaseDir = 'C:\m13m\b1\src\app\build\windows\x64\runner\Release'
  } else { $ReleaseDir = $env:M13O_RELEASE_DIR }
}
$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
if ([string]::IsNullOrWhiteSpace($CompilerPath)) { $CompilerPath = 'C:\m13o\toolchain\inno-6.7.3\ISCC.exe' }
$CompilerPath = [System.IO.Path]::GetFullPath($CompilerPath)
if ([string]::IsNullOrWhiteSpace($InstallerA)) { $InstallerA = Join-Path $AcceptanceRoot 'out\build-a\muaman-windows-installer.exe' }
if ([string]::IsNullOrWhiteSpace($InstallerB)) { $InstallerB = Join-Path $AcceptanceRoot 'out\build-b\muaman-windows-installer.exe' }
$InstallerA = [System.IO.Path]::GetFullPath($InstallerA)
$InstallerB = [System.IO.Path]::GetFullPath($InstallerB)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$Entrypoint = Join-Path $RepoRoot 'tools\release\package_windows_installer.ps1'
$PackageScript = Join-Path $RepoRoot 'tools\release\package_windows_release.ps1'
$Verifier = Join-Path $RepoRoot 'tools\release\verify_release.ps1'
$Iss = Join-Path $RepoRoot 'installer\muaman.iss'
$ContractPath = Join-Path $RepoRoot 'tools\muaman13o\installer_contract.json'
$LegalManifest = Join-Path $RepoRoot 'docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\release-manifest.json'

$ExpectedZipSha256   = '57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008'
$ExpectedCrossHash   = 'EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9'
$ExpectedFileCount   = 13
$ExpectedTotalBytes  = 33273462
$ExpectedCompilerSha = '0A8757031B33777E4C9CBFFEE40F11A5062B36D25CBE144C1DB73B6102B80AD7'
$ExpectedCompilerVersion = '6.7.3'
$ExpectedAppId       = '{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}'

$verdicts = [ordered]@{}

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Get-Sha256([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }

function Read-JsonIf([string]$p) {
  if (Test-Path -LiteralPath $p -PathType Leaf) { return Get-Content -LiteralPath $p -Raw | ConvertFrom-Json }
  return $null
}

function Invoke-Git([string]$cmd) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = 'git.exe'
  $psi.Arguments = $cmd
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.WorkingDirectory = $RepoRoot
  $p = [System.Diagnostics.Process]::Start($psi)
  $o = $p.StandardOutput.ReadToEnd()
  $e = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return [pscustomobject]@{ exit = $p.ExitCode; out = $o.Trim(); err = $e.Trim() }
}

function Get-ScriptLines([string]$p) {
  return @(Get-Content -LiteralPath $p -Encoding UTF8)
}

# ---------------------------------------------------------------------------
# O1 baseline and initial safety
# ---------------------------------------------------------------------------
function Get-O1Verdict {
  $bad = @()
  $head = (Invoke-Git 'rev-parse HEAD').out
  if ([string]::IsNullOrWhiteSpace($head)) { $bad += 'not a git repository (no HEAD)' }
  $branch = (Invoke-Git 'branch --show-current').out
  if ($branch -ne $ExpectedBranch) { $bad += "branch mismatch: $branch (expected $ExpectedBranch)" }
  $isAncestor = (Invoke-Git ('merge-base --is-ancestor {0} HEAD' -f $BaselineCommit)).exit -eq 0
  if (-not $isAncestor) { $bad += "HEAD does not descend from baseline $BaselineCommit" }
  $tag = (Invoke-Git 'tag --points-at HEAD').out
  if (-not [string]::IsNullOrWhiteSpace($tag)) { $bad += "tag present at HEAD: $tag" }
  [ordered]@{
    guard = 'O1 baseline and initial safety'
    pass = ($bad.Count -eq 0)
    failures = $bad
    head = $head
    branch = $branch
    expectedBranch = $ExpectedBranch
    descendsFromBaseline = $isAncestor
    baseline = $BaselineCommit
    tagAtHead = $tag
  }
}
$verdicts['O1'] = Get-O1Verdict

# ---------------------------------------------------------------------------
# O2 scope guard (production diff empty)
# ---------------------------------------------------------------------------
function Get-O2Verdict {
  $bad = @()
  $changed = New-Object System.Collections.Generic.HashSet[string]

  # working tree (unstaged + staged + untracked)
  $st = (Invoke-Git 'status --porcelain').out -split "`r?`n" | Where-Object { $_ -ne '' }
  foreach ($line in $st) {
    $p = if ($line.Length -gt 3) { $line.Substring(3).Trim() } else { '' }
    if ([string]::IsNullOrWhiteSpace($p)) { continue }
    if ($p.StartsWith('"')) {
      $p = $p.Trim('"').Replace('\\', '\')
    }
    [void]$changed.Add($p.Replace('\', '/'))
  }
  # committed since baseline
  $committed = @((Invoke-Git ('diff --name-only {0}..HEAD' -f $BaselineCommit)).out -split "`r?`n" | Where-Object { $_ -ne '' })
  foreach ($c in $committed) { [void]$changed.Add($c.Replace('\', '/')) }

  $allowed = @('tools/', 'docs/', 'installer/')
  $forbidden = @('app/lib/', 'app/windows/', 'assets/', 'app/pubspec.yaml', 'app/pubspec.lock')
  $scopeViolations = @()
  foreach ($c in @($changed)) {
    $ok = $false
    foreach ($a in $allowed) { if ($c.StartsWith($a, [System.StringComparison]::OrdinalIgnoreCase)) { $ok = $true; break } }
    if (-not $ok) { $scopeViolations += $c }
    foreach ($f in $forbidden) {
      if ($c.StartsWith($f, [System.StringComparison]::OrdinalIgnoreCase)) { $scopeViolations += "forbidden-prefix $c" }
    }
  }
  $productionDiff = @($changed | Where-Object {
    $_ -match '^app/(lib|windows)/' -or $_ -match '^assets/' -or $_ -match '^app/pubspec\.(yaml|lock)$'
  })
  $scopeViolations = @($scopeViolations | Select-Object -Unique)

  if ($productionDiff.Count -gt 0) { $bad += 'production diff is not empty: ' + ($productionDiff -join ', ') }
  if ($scopeViolations.Count -gt 0) { $bad += 'scope violations: ' + ($scopeViolations -join ', ') }

  [ordered]@{
    guard = 'O2 scope guard (production diff empty)'
    pass = ($bad.Count -eq 0)
    failures = $bad
    changedFiles = @($changed)
    productionDiff = $productionDiff
    scopeViolations = $scopeViolations
  }
}
$verdicts['O2'] = Get-O2Verdict

# ---------------------------------------------------------------------------
# O3 canonical release-source guard
# ---------------------------------------------------------------------------
function Get-O3Verdict {
  $bad = @()
  $src = @(Get-ScriptLines $Entrypoint)
  $exec = @($src | Where-Object { $_ -notmatch '^\s*#' })
  $execText = $exec -join "`n"

  if (-not (Test-Path -LiteralPath $Entrypoint -PathType Leaf)) { $bad += "installer entrypoint missing: $Entrypoint" }
  else {
    if ($execText -notmatch 'package_windows_release\.ps1') { $bad += 'entrypoint does not delegate to the canonical packager package_windows_release.ps1' }
    if ($execText -notmatch 'verify_release\.ps1') { $bad += 'entrypoint does not invoke the canonical verifier verify_release.ps1' }
    foreach ($tok in @('flutter build', 'Compress-Archive', 'cmake', 'msbuild', 'pub get', 'flutter clean')) {
      if ($execText -match [regex]::Escape($tok)) { $bad += "forbidden token in executable code: $tok" }
    }
    # verify-before-compile source ordering: the staging verifier invocation must
    # appear before the ISCC compile invocation
    $verifyIdx = -1; $compileIdx = -1
    for ($i = 0; $i -lt $src.Count; $i++) {
      $l = $src[$i]
      if ($l -notmatch '^\s*#') {
        if ($l -match '\-File \$Verifier' -and $verifyIdx -lt 0) { $verifyIdx = $i }
        if (($l -match 'InstallerCompilerPath.*isccArgs' -or $l -match '\$InstallerCompilerPath \$isccArgs') -and $compileIdx -lt 0) { $compileIdx = $i }
      }
    }
    if ($verifyIdx -lt 0) { $bad += 'no staging verifier invocation found' }
    if ($compileIdx -lt 0) { $bad += 'no ISCC compile invocation found' }
    elseif ($verifyIdx -ge 0 -and $verifyIdx -ge $compileIdx) { $bad += 'verification is not source-ordered before installer compilation' }
  }

  # .iss: exactly the 13 legal files, no wildcards
  $legalRels = @($null)
  if (Test-Path -LiteralPath $ContractPath) {
    $c = Read-JsonIf $ContractPath
    $legalRels = @($c.expectedInstalledFiles | ForEach-Object { [string]$_.rel })
  }
  if (-not (Test-Path -LiteralPath $Iss -PathType Leaf)) { $bad += "installer definition missing: $Iss" }
  else {
    $issLines = @(Get-ScriptLines $Iss)
    $sourceLines = @($issLines | Where-Object { $_ -match '^\s*Source\s*:' })
    if ($sourceLines.Count -ne $ExpectedFileCount) { $bad += ".iss [Files] source count is $($sourceLines.Count); expected $ExpectedFileCount" }
    foreach ($s in $sourceLines) {
      if ($s -match '\*') { $bad += ".iss [Files] entry uses a wildcard: $s" }
    }
    # each Source path must correspond to one of the 13 legal rel paths
    if ($legalRels.Count -eq 13) {
      foreach ($s in $sourceLines) {
        $m = [regex]::Match($s, 'Source:\s*"\{#AppSourceDir\}\\([^"]+)"')
        if ($m.Success) {
          $rel = $m.Groups[1].Value.Replace('\', '/')
          if ($rel -notin $legalRels) { $bad += ".iss source not in legal release manifest: $rel" }
        }
      }
    }
    if ($issLines -match '^\s*\[Run\]') { $bad += '.iss contains a [Run] section (auto-launch prohibited)' }
  }

  [ordered]@{
    guard = 'O3 canonical release-source guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    entrypoint = $Entrypoint
    installerDefinition = $Iss
  }
}
$verdicts['O3'] = Get-O3Verdict

# ---------------------------------------------------------------------------
# O4 installer toolchain identity
# ---------------------------------------------------------------------------
function Get-O4Verdict {
  $bad = @()
  $exists = Test-Path -LiteralPath $CompilerPath -PathType Leaf
  $sha = if ($exists) { Get-Sha256 $CompilerPath } else { '' }
  $name = if ($exists) { [System.IO.Path]::GetFileNameWithoutExtension($CompilerPath) } else { '' }
  if (-not $exists) { $bad += "pinned compiler missing: $CompilerPath" }
  else {
    if ($name -ne 'ISCC') { $bad += "unexpected compiler executable name: $name" }
    if ($sha -ne $ExpectedCompilerSha) { $bad += "compiler SHA-256 mismatch: $sha (expected $ExpectedCompilerSha)" }
  }
  # recorded compile evidence must agree with the frozen version/hash
  $result = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\build-a\installer-result.json')
  if ($null -eq $result) { $bad += 'no build-a installer-result.json evidence' }
  else {
    if ([string]$result.toolchain.compilerVersion -ne $ExpectedCompilerVersion) { $bad += "recorded compiler version mismatch: $($result.toolchain.compilerVersion)" }
    if ([string]$result.toolchain.compilerSha256 -ne $ExpectedCompilerSha) { $bad += 'recorded compiler SHA mismatch' }
  }
  [ordered]@{
    guard = 'O4 installer toolchain identity'
    pass = ($bad.Count -eq 0)
    failures = $bad
    compilerPath = $CompilerPath
    compilerPresent = $exists
    compilerSha256 = $sha
    expectedCompilerSha256 = $ExpectedCompilerSha
    expectedCompilerVersion = $ExpectedCompilerVersion
  }
}
$verdicts['O4'] = Get-O4Verdict

# ---------------------------------------------------------------------------
# O5 installer contract guard
# ---------------------------------------------------------------------------
function Get-O5Verdict {
  $bad = @()
  $c = Read-JsonIf $ContractPath
  if ($null -eq $c) { $bad += 'installer_contract.json missing' }
  else {
    if ([string]$c.installer.outputFilename -ne 'muaman-windows-installer.exe') { $bad += 'contract outputFilename mismatch' }
    if ([string]$c.installer.installScope -ne 'per-user') { $bad += 'contract install scope is not per-user' }
    if ([string]$c.installer.defaultInstallLocation -notlike '*LOCALAPPDATA*Programs*muaman_store*') { $bad += 'contract default install location mismatch' }
    if ([string]$c.installer.installerCompilerSha256 -ne $ExpectedCompilerSha) { $bad += 'contract compiler SHA mismatch' }
  }

  if (-not (Test-Path -LiteralPath $Iss -PathType Leaf)) { $bad += "installer definition missing: $Iss" }
  else {
    $issText = (Get-ScriptLines $Iss) -join "`n"
    foreach ($token in @(
      "AppId={{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}",
      'PrivilegesRequired=lowest',
      'ArchitecturesAllowed=x64compatible',
      'ArchitecturesInstallIn64BitMode=x64compatible',
      'DefaultDirName={localappdata}\Programs\muaman_store',
      'Compression=lzma2/max',
      'SolidCompression=yes',
      'Name: "{autoprograms}\muaman_store"',
      'Flags: unchecked'
    )) {
      if ($issText -notmatch [regex]::Escape($token)) { $bad += ".iss missing required token: $token" }
    }
    if ($issText -match '^\s*\[Run\]') { $bad += '.iss contains a [Run] section' }
    if ($issText -match 'Type:\s*files') { $bad += '.iss [UninstallDelete] deletes files (user data deletion prohibited)' }
    if ($issText -notmatch 'Type: dirifempty; Name: "\{app\}"') { $bad += '.iss lacks the safe dirifempty {app} cleanup rule' }
    $issLines = @(Get-ScriptLines $Iss)
    $tasksDesktop = @($issLines | Where-Object { $_ -match 'Name:\s*"desktopicon"' -and $_ -match 'Flags: unchecked' })
    if ($tasksDesktop.Count -lt 1) { $bad += '.iss lacks an optional unchecked desktop-icon [Tasks] entry' }
    $desktopIcons = @($issLines | Where-Object { $_ -match 'Name:\s*"\{autodesktop\}' })
    if ($desktopIcons.Count -eq 0) { $bad += '.iss has no desktop icon definition' }
    else {
      foreach ($l in $desktopIcons) {
        if ($l -notmatch 'Tasks: desktopicon') { $bad += '.iss hard-codes desktop icon creation (no Tasks gating): ' + $l.Trim() }
      }
    }
  }

  [ordered]@{
    guard = 'O5 installer contract guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    contract = $ContractPath
    installerDefinition = $Iss
  }
}
$verdicts['O5'] = Get-O5Verdict

# ---------------------------------------------------------------------------
# O6 release manifest guard
# ---------------------------------------------------------------------------
function Get-O6Verdict {
  $bad = @()
  $verif = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\build-a\staging-verification.json')
  if ($null -eq $verif) { $bad += 'no build-a staging-verification.json evidence' }
  else {
    if (-not [bool]$verif.identical) { $bad += 'staging verification identical=false' }
    if ([int]$verif.fileCountNew -ne $ExpectedFileCount) { $bad += "file count mismatch: $($verif.fileCountNew)" }
    if ([int64]$verif.totalBytesNew -ne $ExpectedTotalBytes) { $bad += "total bytes mismatch: $($verif.totalBytesNew)" }
    if ([string]$verif.crossHashNew -ne $ExpectedCrossHash) { $bad += "cross-hash mismatch: $($verif.crossHashNew)" }
    if (-not [bool]$verif.crossHashMatch) { $bad += 'cross-hash match=false' }
    if ([int]$verif.diffCount -ne 0) { $bad += "diff count mismatch: $($verif.diffCount)" }
  }
  if (-not (Test-Path -LiteralPath $LegalManifest -PathType Leaf)) { $bad += "legal manifest missing: $LegalManifest" }
  else {
    $legal = Read-JsonIf $LegalManifest
    if ($null -eq $legal -or @($legal.files).Count -ne $ExpectedFileCount) { $bad += 'legal manifest file count is not 13' }
  }
  [ordered]@{
    guard = 'O6 release manifest guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    legalManifest = $LegalManifest
    evidence = 'evidence/build-a/staging-verification.json'
  }
}
$verdicts['O6'] = Get-O6Verdict

# ---------------------------------------------------------------------------
# O7 deterministic installer guard
# ---------------------------------------------------------------------------
function Get-O7Verdict {
  $bad = @()
  $cmp = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\compare-result.json')
  if ($null -eq $cmp) { $bad += 'no compare-result.json evidence' }
  else {
    if (-not [bool]$cmp.byteIdentical) { $bad += 'build A and B are not byte-identical' }
    if ([string]$cmp.buildA.sha256 -ne [string]$cmp.buildB.sha256) { $bad += 'build A and B SHA-256 differ' }
    if ([int64]$cmp.buildA.sizeBytes -ne [int64]$cmp.buildB.sizeBytes) { $bad += 'build A and B sizes differ' }
  }
  if ((Test-Path -LiteralPath $InstallerA -PathType Leaf) -and (Test-Path -LiteralPath $InstallerB -PathType Leaf)) {
    $shaA = Get-Sha256 $InstallerA
    $shaB = Get-Sha256 $InstallerB
    if ($shaA -ne $shaB) { $bad += "live installer hashes differ: $shaA vs $shaB" }
  }
  [ordered]@{
    guard = 'O7 deterministic installer guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    buildA = $InstallerA
    buildB = $InstallerB
    evidence = 'evidence/compare-result.json'
  }
}
$verdicts['O7'] = Get-O7Verdict

# ---------------------------------------------------------------------------
# O8 installation guard
# ---------------------------------------------------------------------------
$ExpectedInstallerSha = '05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB'
function Get-O8Verdict {
  $bad = @()
  $install = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\install-result.json')
  if ($null -eq $install) { $bad += 'no install-result.json evidence' }
  else {
    if (-not [bool]$install.passed) { $bad += 'installation evidence passed=false' }
    if ([int]$install.installExitCode -ne 0) { $bad += "install exit code is $($install.installExitCode); expected 0" }
    if (-not [bool]$install.installedExePresent) { $bad += 'installed executable not present' }
    if (-not [bool]$install.startMenuShortcut.present) { $bad += 'start menu shortcut not present' }
    if (-not [bool]$install.uninstallRegistration.present) { $bad += 'uninstall registration not present' }
    if ([int]$install.payload.fileCount -ne $ExpectedFileCount) { $bad += "payload file count is $($install.payload.fileCount); expected $ExpectedFileCount" }
    if (-not [bool]$install.payload.verified) { $bad += 'installed payload verification failed' }
    if (@($install.payload.unexpectedFiles).Count -ne 0) { $bad += 'unexpected files in install root: ' + (@($install.payload.unexpectedFiles) -join ', ') }
    if ([string]$install.inbound.sha256 -ne $ExpectedInstallerSha) { $bad += "installed installer SHA mismatch: $($install.inbound.sha256) (expected $ExpectedInstallerSha)" }
    if ([string]$install.inbound.sourceSha256 -ne [string]$install.inbound.sha256) { $bad += 'inbound installer SHA differs from produced installer SHA' }
  }
  [ordered]@{
    guard = 'O8 installation guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    installDir = if ($null -ne $install) { [string]$install.installCommand.installDir } else { '' }
    installerSha256 = if ($null -ne $install) { [string]$install.inbound.sha256 } else { '' }
    expectedInstallerSha256 = $ExpectedInstallerSha
    evidence = 'evidence/install-result.json'
  }
}
$verdicts['O8'] = Get-O8Verdict

# ---------------------------------------------------------------------------
# O9 installed payload guard
# ---------------------------------------------------------------------------
function Get-O9Verdict {
  $bad = @()
  $install = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\install-result.json')
  $c = Read-JsonIf $ContractPath
  if ($null -eq $install) { $bad += 'no install-result.json evidence' }
  if ($null -eq $c) { $bad += 'installer_contract.json missing' }
  if ($null -eq $install -or $null -eq $c) {
    return [ordered]@{ guard = 'O9 installed payload guard'; pass = ($bad.Count -eq 0); failures = $bad; evidence = 'evidence/install-result.json + installer_contract.json' }
  }
  if (@($install.payload.files).Count -ne $ExpectedFileCount) { $bad += "recorded payload count is $(@($install.payload.files).Count); expected $ExpectedFileCount" }
  foreach ($f in @($install.payload.files)) {
    if (-not [bool]$f.match) { $bad += "recorded payload file not matched: $($f.rel)" }
  }
  $expected = [ordered]@{}
  foreach ($f in @($c.expectedInstalledFiles)) { $expected[[string]$f.rel] = [ordered]@{ sha256 = [string]$f.sha256; size = [int64]$f.size } }
  if ($expected.Count -ne $ExpectedFileCount) { $bad += "contract expectedInstalledFiles count is $($expected.Count); expected $ExpectedFileCount" }
  $recordedRels = New-Object System.Collections.Generic.HashSet[string]
  $mismatches = @()
  foreach ($f in @($install.payload.files)) {
    $rel = [string]$f.rel
    [void]$recordedRels.Add($rel)
    if (-not $expected.Contains($rel)) { $mismatches += "not-in-contract: $rel"; continue }
    if ([string]$f.sha256 -ne [string]$expected[$rel].sha256 -or [int64]$f.size -ne [int64]$expected[$rel].size) { $mismatches += "contract-mismatch: $rel" }
  }
  foreach ($k in @($expected.Keys)) {
    if (-not $recordedRels.Contains([string]$k)) { $mismatches += "not-recorded: $k" }
  }
  if ($mismatches.Count -gt 0) { $bad += 'payload-to-contract cross-check mismatches: ' + ($mismatches -join ', ') }
  [ordered]@{
    guard = 'O9 installed payload guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    contractFileCount = @($c.expectedInstalledFiles).Count
    recordedFileCount = @($install.payload.files).Count
    crossCheckMismatches = $mismatches
    evidence = 'evidence/install-result.json + installer_contract.json'
  }
}
$verdicts['O9'] = Get-O9Verdict

# ---------------------------------------------------------------------------
# O10 installed launch guard
# ---------------------------------------------------------------------------
function Get-O10Verdict {
  $bad = @()
  $launch = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\launch-result.json')
  if ($null -eq $launch) { $bad += 'no launch-result.json evidence' }
  else {
    if (-not [bool]$launch.passed) { $bad += 'launch evidence passed=false' }
    if (-not [bool]$launch.process.aliveAfterSeconds) { $bad += 'process did not stay alive' }
    if (-not [bool]$launch.process.mainWindowVisible) { $bad += 'main window not visible' }
    if ([string]$launch.process.mainWindowTitle -ne 'muaman_store') { $bad += "unexpected main window title: $($launch.process.mainWindowTitle)" }
    if ([int]$launch.process.modulesLoaded -lt 1) { $bad += 'no modules enumerated' }
    if (@($launch.process.moduleOriginIssues).Count -ne 0) { $bad += 'module origin issues: ' + (@($launch.process.moduleOriginIssues) -join ', ') }
    if (-not [bool]$launch.process.cleanShutdown) { $bad += 'clean shutdown not achieved' }
    if ([string]$launch.process.shutdownMethod -ne 'CloseMainWindow') { $bad += "shutdown method is $($launch.process.shutdownMethod); expected CloseMainWindow" }
    if (-not [bool]$launch.payloadFilesUnchangedAfterLaunch) { $bad += 'payload files changed after launch' }
    if (@($launch.payloadDiffDetails).Count -ne 0) { $bad += 'payload diffs after launch: ' + (@($launch.payloadDiffDetails) -join ', ') }
  }
  [ordered]@{
    guard = 'O10 installed launch guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    pid = if ($null -ne $launch) { [int]$launch.process.pid } else { -1 }
    mainWindowTitle = if ($null -ne $launch) { [string]$launch.process.mainWindowTitle } else { '' }
    modulesLoaded = if ($null -ne $launch) { [int]$launch.process.modulesLoaded } else { -1 }
    runtimeDataCreatedInInstallDir = if ($null -ne $launch) { @($launch.runtimeDataCreatedInInstallDir) } else { @() }
    evidence = 'evidence/launch-result.json'
  }
}
$verdicts['O10'] = Get-O10Verdict

# ---------------------------------------------------------------------------
# O11 module-origin guard
# ---------------------------------------------------------------------------
function Get-O11Verdict {
  $bad = @()
  $launch = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\launch-result.json')
  if ($null -eq $launch) { $bad += 'no launch-result.json evidence' }
  else {
    if ([int]$launch.process.modulesLoaded -lt 1) { $bad += 'module enumeration did not run (modulesLoaded=0)' }
    if (@($launch.process.moduleOriginIssues).Count -ne 0) { $bad += 'module origin violations: ' + (@($launch.process.moduleOriginIssues) -join ', ') }
  }
  [ordered]@{
    guard = 'O11 module-origin guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    modulesLoaded = if ($null -ne $launch) { [int]$launch.process.modulesLoaded } else { -1 }
    moduleOriginIssueCount = if ($null -ne $launch) { @($launch.process.moduleOriginIssues).Count } else { -1 }
    policy = 'every loaded module must originate from the install root or the Windows directory'
    evidence = 'evidence/launch-result.json'
  }
}
$verdicts['O11'] = Get-O11Verdict

# ---------------------------------------------------------------------------
# O12 uninstallation guard
# ---------------------------------------------------------------------------
function Get-O12Verdict {
  $bad = @()
  $un = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\uninstall-result.json')
  if ($null -eq $un) { $bad += 'no uninstall-result.json evidence' }
  else {
    if (-not [bool]$un.passed) { $bad += 'uninstall evidence passed=false' }
    if ([int]$un.uninstallExitCode -ne 0) { $bad += "uninstall exit code is $($un.uninstallExitCode); expected 0" }
    if (-not [bool]$un.checks.installedPayloadRemoved) { $bad += 'installed payload not removed' }
    if (-not [bool]$un.checks.uninstallerRemoved) { $bad += 'uninstaller not removed' }
    if (-not [bool]$un.checks.startMenuShortcutRemoved) { $bad += 'start menu shortcut not removed' }
    if (-not [bool]$un.checks.uninstallRegistryRemoved) { $bad += 'uninstall registry key not removed' }
    if (-not [bool]$un.checks.noProcessRunning) { $bad += 'process still running after uninstall' }
    if (-not [bool]$un.checks.businessDataPreserved) { $bad += 'business data not preserved' }
    if (-not [bool]$un.checks.userProfilePreserved) { $bad += 'user profile not preserved' }
    if (@($un.checks.payloadRemaining).Count -ne 0) { $bad += 'payload files remaining: ' + (@($un.checks.payloadRemaining) -join ', ') }
    if (@($un.checks.businessDataMissingAfter).Count -ne 0) { $bad += 'business data missing after uninstall: ' + (@($un.checks.businessDataMissingAfter) -join ', ') }
  }
  [ordered]@{
    guard = 'O12 uninstallation guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    businessDataBefore = if ($null -ne $un) { @($un.businessDataBeforeUninstall) } else { @() }
    installRootState = if ($null -ne $un) { [string]$un.checks.installRootState } else { '' }
    evidence = 'evidence/uninstall-result.json'
  }
}
$verdicts['O12'] = Get-O12Verdict

# ---------------------------------------------------------------------------
# O13 negative-control guard
# ---------------------------------------------------------------------------
function Get-O13Verdict {
  $bad = @()
  $neg = Read-JsonIf (Join-Path $AcceptanceRoot 'evidence\negative-result.json')
  if ($null -eq $neg) { $bad += 'no negative-result.json evidence' }
  else {
    if (-not [bool]$neg.passed) { $bad += 'negative evidence passed=false' }
    if (-not [bool]$neg.tamper.packageShaVerified) { $bad += 'reference package SHA not verified' }
    if (-not [bool]$neg.tamper.tamperApplied) { $bad += 'tamper was not applied' }
    if ([int]$neg.preflightExitCode -eq 0) { $bad += 'preflight succeeded on tampered staging (exit 0)' }
    if (-not [bool]$neg.failClosed) { $bad += 'negative control was not fail-closed' }
    if ([bool]$neg.installerArtifactProduced) { $bad += 'installer artifact produced from tampered staging' }
  }
  [ordered]@{
    guard = 'O13 negative-control guard'
    pass = ($bad.Count -eq 0)
    failures = $bad
    tamperedFile = if ($null -ne $neg) { [string]$neg.tamper.tamperedFile } else { '' }
    preflightExitCode = if ($null -ne $neg) { [int]$neg.preflightExitCode } else { -1 }
    failClosed = if ($null -ne $neg) { [bool]$neg.failClosed } else { $false }
    evidence = 'evidence/negative-result.json'
  }
}
$verdicts['O13'] = Get-O13Verdict

# ---------------------------------------------------------------------------
# O14 final lineage guard (post-commit only)
# ---------------------------------------------------------------------------
if ($IncludeO14) {
  function Get-O14Verdict {
    $bad = @()
    $o2 = Get-O2Verdict
    if (-not [bool]$o2.pass) { $bad += 'scope guard failed: ' + (@($o2.failures) -join '; ') }
    $status = (Invoke-Git 'status --porcelain').out
    if (-not [string]::IsNullOrWhiteSpace($status)) { $bad += 'working tree is not clean' }
    $head = (Invoke-Git 'rev-parse HEAD').out
    if ([string]::IsNullOrWhiteSpace($head)) { $bad += 'no HEAD' }
    $branch = (Invoke-Git 'branch --show-current').out
    if ($branch -ne $ExpectedBranch) { $bad += "branch mismatch: $branch" }
    $commitCount = (Invoke-Git ('rev-list --count {0}..HEAD' -f $BaselineCommit)).out
    if ($commitCount -ne '1') { $bad += "commit count since baseline is $commitCount; expected exactly 1" }
    $merges = (Invoke-Git ('rev-list --merges {0}..HEAD' -f $BaselineCommit)).out
    $mergeCount = if ([string]::IsNullOrWhiteSpace($merges)) { 0 } else { @($merges -split "`r?`n" | Where-Object { $_ -ne '' }).Count }
    if ($mergeCount -gt 0) { $bad += "merge commits present since baseline: $mergeCount" }
    $tag = (Invoke-Git 'tag --points-at HEAD').out
    if (-not [string]::IsNullOrWhiteSpace($tag)) { $bad += "tag present at HEAD: $tag" }
    $isAncestor = (Invoke-Git ('merge-base --is-ancestor {0} HEAD' -f $BaselineCommit)).exit -eq 0
    if (-not $isAncestor) { $bad += 'HEAD does not descend from baseline' }
    [ordered]@{
      guard = 'O14 final lineage guard'
      pass = ($bad.Count -eq 0)
      failures = $bad
      head = $head
      branch = $branch
      commitCountSinceBaseline = $commitCount
      mergeCountSinceBaseline = $mergeCount
      tagAtHead = $tag
      workingTreeClean = [string]::IsNullOrWhiteSpace($status)
    }
  }
  $verdicts['O14'] = Get-O14Verdict
}

# ---------------------------------------------------------------------------
# verdict aggregation and output
# ---------------------------------------------------------------------------
$failedGuards = @($verdicts.GetEnumerator() | Where-Object { -not $_.Value.pass } | ForEach-Object { $_.Key })
$overallPass = $failedGuards.Count -eq 0
$summary = [ordered]@{
  schemaVersion = '1.0'
  phase = 'MUAMAN-13O'
  tool = 'tools/muaman13o/guard_tests_13o.ps1'
  repoRoot = $RepoRoot
  acceptanceRoot = $AcceptanceRoot
  baselineCommit = $BaselineCommit
  expectedBranch = $ExpectedBranch
  overallPass = $overallPass
  guardCount = $verdicts.Count
  passedCount = $verdicts.Count - $failedGuards.Count
  failedCount = $failedGuards.Count
  failedGuards = $failedGuards
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  guards = $verdicts
}
[System.IO.File]::WriteAllText($Out, ($summary | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
foreach ($k in @($verdicts.Keys)) {
  $v = $verdicts[$k]
  Write-Host ('{0} {1}' -f ($(if ($v.pass) { 'PASS' } else { 'FAIL' })), $k)
}
Write-Host ('OVERALL {0} ({1}/{2} guards passed)' -f ($(if ($overallPass) { 'PASS' } else { 'FAIL' })), ($verdicts.Count - $failedGuards.Count), $verdicts.Count)
if ($overallPass) { exit 0 }
exit 1
