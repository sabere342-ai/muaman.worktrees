# MUAMAN-13O deterministic Windows installer local acceptance harness.
#
# Reproducible, fail-closed driver for the full local acceptance sequence:
#
#   Preflight  -> no pre-existing installation side effects
#   BuildA     -> installer compiled from the canonical release package (root A)
#   BuildB     -> installer re-compiled identically (independent root B)
#   Compare    -> byte-for-byte determinism of A and B installer outputs
#   Install    -> silent per-user install into an isolated consumer root
#   Launch     -> isolated-profile launch, process/window/module checks
#   Uninstall  -> silent uninstall, removal + user-data preservation checks
#   Negative   -> tampered staging payload must be rejected (no installer)
#   Guards     -> O-series guard tests from the final working tree
#   All        -> the above sequence in order; stops at the first failure
#
# Every mode is fail-closed (non-zero exit on any check failure), writes a
# structured JSON result under the evidence directory, and never deletes
# anything outside the owned acceptance root.
#
# Exit codes:
#   0  success
#   1  a verification/acceptance check failed
#   2  parameter / path / invocation validation failure
#   3  an unexpected error occurred
#
# Usage (from any working directory):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     <repo>\tools\muaman13o\verify_installer_acceptance.ps1 `
#     -Mode Preflight -RepoRoot <repo> -ReleaseDir <verified-release-dir> -Root <acceptance-root>
#
#   -Mode values: Preflight|BuildA|BuildB|Compare|Install|Launch|Uninstall|Negative|Guards|All

param(
  [Parameter(Mandatory = $true)][string]$Mode,
  [string]$RepoRoot = '',
  [string]$ReleaseDir = '',
  [string]$Root = '',
  [string]$RunId = '',
  [string]$EvidenceDir = '',
  [string]$InstallerCompilerPath = '',
  [string]$InstallerPath = '',
  [switch]$KeepWorkingFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

# ---------------------------------------------------------------------------
# frozen contract constants
# ---------------------------------------------------------------------------
$ExpectedInstallerSha      = ''   # filled from BuildA result at Compare/Install time
$ExpectedZipSha256         = 'FDEE3AF699570561FC401F6FD908A0FF6EB78539F43EE072F45871F9485D2A3E'
$ExpectedInstallerFilename = 'muaman-windows-installer.exe'
$LaunchAliveSeconds        = 20
$MainWindowTimeoutSeconds  = 30

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ('[MUAMAN-13O-HARNESS] {0}' -f $message)
}

function Get-UtcNow() {
  return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Get-Sha256([string]$path) {
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

function Write-Utf8NoBom([string]$path, [string]$text) {
  $dir = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Test-IsUnder([string]$inner, [string]$outer) {
  $o = $outer.TrimEnd('\')
  $i = $inner.TrimEnd('\')
  if ($i -eq $o) { return $true }
  return $i.StartsWith($o + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Remove-OwnedDir([string]$path, [string]$root) {
  if (-not (Test-IsUnder $path $root)) {
    throw ("refusing to remove {0}: not under owned root {1}" -f $path, $root)
  }
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $path) {
    & cmd.exe /c rmdir /s /q $path
  }
}

function Write-Result([string]$mode, [hashtable]$data) {
  $json = $data | ConvertTo-Json -Depth 10
  Write-Utf8NoBom (Join-Path $EvidenceDir ('{0}-result.json' -f $mode.ToLowerInvariant())) $json
}

function Test-PreExistingInstallation() {
  $problems = @()
  $installDirDefault = Join-Path $env:LOCALAPPDATA 'Programs\muaman_store'
  if (Test-Path -LiteralPath $installDirDefault) { $problems += "default install dir exists: $installDirDefault" }

  $startMenuShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\I-TECH للتكنولوجيا.lnk'
  if (Test-Path -LiteralPath $startMenuShortcut) { $problems += "start menu shortcut exists: $startMenuShortcut" }

  $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
  if (Test-Path -LiteralPath $uninstallKey) {
    foreach ($child in Get-ChildItem -LiteralPath $uninstallKey -ErrorAction SilentlyContinue) {
      $disp = (Get-ItemProperty -LiteralPath $child.PSPath -ErrorAction SilentlyContinue).DisplayName
      if ($disp -eq 'I-TECH للتكنولوجيا') {
        $problems += ("uninstall registry key present: {0}" -f $child.PSChildName)
      }
    }
  }

  $proc = Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue
  if ($null -ne $proc) { $problems += "running muaman_store process found (pid {0})" -f $proc.Id }

  return $problems
}

function Get-DirSnapshot([string]$dir) {
  $map = [ordered]@{}
  foreach ($f in Get-ChildItem -LiteralPath $dir -Recurse -File) {
    $rel = $f.FullName.Substring($dir.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
    $map[$rel] = [ordered]@{ size = $f.Length; sha256 = (Get-Sha256 $f.FullName) }
  }
  return $map
}

function Compare-DirSnapshots([hashtable]$a, [hashtable]$b) {
  $diffs = @()
  foreach ($k in $a.Keys) {
    if (-not $b.Contains($k)) { $diffs += "only-in-a: $k"; continue }
    if ($a[$k].size -ne $b[$k].size -or $a[$k].sha256 -ne $b[$k].sha256) { $diffs += "content-diff: $k" }
  }
  foreach ($k in $b.Keys) { if (-not $a.Contains($k)) { $diffs += "only-in-b: $k" } }
  return $diffs
}

# ---------------------------------------------------------------------------
# validation + common paths
# ---------------------------------------------------------------------------
if ($Mode -notin @('Preflight','BuildA','BuildB','Compare','Install','Launch','Uninstall','Negative','Guards','All')) {
  Write-Host ("[MUAMAN-13O-HARNESS] ERROR unknown mode: {0}" -f $Mode)
  exit 2
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $scriptDir = $PSScriptRoot
  if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $RepoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

foreach ($marker in @(
  (Join-Path $RepoRoot 'app\pubspec.yaml'),
  (Join-Path $RepoRoot 'tools\release\package_windows_installer.ps1'),
  (Join-Path $RepoRoot 'installer\muaman.iss')
)) {
  if (-not (Test-Path -LiteralPath $marker)) {
    Write-Host ("[MUAMAN-13O-HARNESS] ERROR repository structure not found at {0}; missing {1}" -f $RepoRoot, $marker)
    exit 2
  }
}

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
}
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Join-Path 'C:\mu13o-acceptance' $RunId
}
$Root = [System.IO.Path]::GetFullPath($Root)
if (Test-IsUnder $Root $RepoRoot) {
  Write-Host '[MUAMAN-13O-HARNESS] ERROR Root must be OUTSIDE the repository (isolation requirement)'
  exit 2
}
if ([string]::IsNullOrWhiteSpace($EvidenceDir)) { $EvidenceDir = Join-Path $Root 'evidence' }
$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)

New-Item -ItemType Directory -Path $Root -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($InstallerCompilerPath)) {
  $InstallerCompilerPath = 'C:\m13o\toolchain\inno-6.7.3\ISCC.exe'
}
$InstallerCompilerPath = [System.IO.Path]::GetFullPath($InstallerCompilerPath)

if ([string]::IsNullOrWhiteSpace($ReleaseDir)) {
  if ([string]::IsNullOrEmpty($env:M13O_RELEASE_DIR)) {
    $ReleaseDir = 'C:\m13m\b1\src\app\build\windows\x64\runner\Release'
  } else {
    $ReleaseDir = $env:M13O_RELEASE_DIR
  }
}
$ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
if (-not (Test-Path -LiteralPath $ReleaseDir -PathType Container)) {
  Write-Host ("[MUAMAN-13O-HARNESS] ERROR ReleaseDir does not exist: {0}" -f $ReleaseDir)
  exit 2
}

$Entrypoint = Join-Path $RepoRoot 'tools\release\package_windows_installer.ps1'
$Guards = Join-Path $RepoRoot 'tools\muaman13o\guard_tests_13o.ps1'
$ContractPath = Join-Path $RepoRoot 'tools\muaman13o\installer_contract.json'
$Contract = Get-Content -LiteralPath $ContractPath -Raw | ConvertFrom-Json
$PayloadRels = @($Contract.expectedInstalledFiles | ForEach-Object { [string]$_.rel })
$BuildARoot = Join-Path $Root 'work\build-a'
$BuildBRoot = Join-Path $Root 'work\long-independent-root-b\build-b'
$OutA = Join-Path $Root 'out\build-a'
$OutB = Join-Path $Root 'out\build-b'
$InstallerA = Join-Path $OutA $ExpectedInstallerFilename
$InstallerB = Join-Path $OutB $ExpectedInstallerFilename
$ConsumerRoot = Join-Path $Root 'consumer'
$InboundDir = Join-Path $ConsumerRoot 'inbound'
$InstallRoot = Join-Path $ConsumerRoot 'install-root'
$ProfileRoot = Join-Path $ConsumerRoot 'profile'
$TempRoot = Join-Path $ConsumerRoot 'temp'
$LogsDir = Join-Path $ConsumerRoot 'logs'
$NegativeRoot = Join-Path $Root 'negative'
$PreflightResult = Join-Path $EvidenceDir 'preflight-result.json'

$modesToRun = if ($Mode -eq 'All') { @('Preflight','BuildA','BuildB','Compare','Install','Launch','Uninstall','Negative','Guards') } else { @($Mode) }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
function Invoke-Preflight() {
  $start = Get-UtcNow
  $problems = @(Test-PreExistingInstallation)
  $pass = ($problems.Count -eq 0)
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Preflight'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = if ($pass) { 0 } else { 1 } }
    checks = [ordered]@{
      defaultInstallDirAbsent = -not ($problems | Where-Object { $_ -like 'default install dir*' })
      startMenuShortcutAbsent = -not ($problems | Where-Object { $_ -like 'start menu shortcut*' })
      uninstallRegistryAbsent = -not ($problems | Where-Object { $_ -like 'uninstall registry*' })
      noRunningProcess = -not ($problems | Where-Object { $_ -like 'running muaman_store*' })
    }
    problems = $problems
    passed = $pass
    failureReason = if ($pass) { $null } else { 'pre-existing installation side effects detected' }
  }
  Write-Result 'preflight' $result
  Write-Step ("preflight {0}" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })))
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# BuildA / BuildB
# ---------------------------------------------------------------------------
function Invoke-Build([string]$label, [string]$workRoot, [string]$outDir, [string]$evidenceSub, [string]$installerOut) {
  $start = Get-UtcNow
  $evidence = Join-Path $EvidenceDir $evidenceSub
  if (Test-Path -LiteralPath $outDir) { Remove-OwnedDir $outDir $Root }
  if (Test-Path -LiteralPath $evidence) { Remove-OwnedDir $evidence $Root }
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null

  $entryArgs = @(
    '-RepoRoot', $RepoRoot,
    '-ReleaseDir', $ReleaseDir,
    '-WorkingRoot', $workRoot,
    '-OutputDir', $outDir,
    '-EvidenceDir', $evidence,
    '-InstallerCompilerPath', $InstallerCompilerPath,
    '-OutputFilename', $ExpectedInstallerFilename
  )
  if ($KeepWorkingFiles) { $entryArgs += '-KeepWorkingFiles' }

  $childOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Entrypoint @entryArgs
  $exit = $LASTEXITCODE
  $childOutput | ForEach-Object { Write-Host $_ }

  $exists = Test-Path -LiteralPath $installerOut -PathType Leaf
  $pass = ($exit -eq 0) -and $exists
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = $label
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    entrypointExitCode = $exit
    installer = if ($exists) { [ordered]@{ path = $installerOut; sha256 = (Get-Sha256 $installerOut); sizeBytes = (Get-Item -LiteralPath $installerOut).Length } } else { $null }
    passed = $pass
    failureReason = if ($pass) { $null } else { 'entrypoint failed or installer output missing' }
  }
  Write-Result $label $result
  Write-Step ("{0} {1}" -f $label, ($(if ($pass) { 'PASS' } else { 'FAIL' })))
  if ($pass) { return 0 }
  return 1
}

function Invoke-BuildA() {
  if (Test-Path -LiteralPath $InstallerA -PathType Leaf) { Remove-Item -LiteralPath $InstallerA -Force }
  return Invoke-Build 'BuildA' $BuildARoot $OutA 'build-a' $InstallerA
}

function Invoke-BuildB() {
  if (Test-Path -LiteralPath $InstallerB -PathType Leaf) { Remove-Item -LiteralPath $InstallerB -Force }
  return Invoke-Build 'BuildB' $BuildBRoot $OutB 'build-b' $InstallerB
}

# ---------------------------------------------------------------------------
# Compare (byte-for-byte determinism)
# ---------------------------------------------------------------------------
function Invoke-Compare() {
  $start = Get-UtcNow
  $missing = @()
  if (-not (Test-Path -LiteralPath $InstallerA -PathType Leaf)) { $missing += $InstallerA }
  if (-not (Test-Path -LiteralPath $InstallerB -PathType Leaf)) { $missing += $InstallerB }
  if ($missing.Count -gt 0) {
    Write-Result 'compare' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Compare'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; missingInstallers = $missing; passed = $false; failureReason = 'BuildA/BuildB outputs missing' })
    Write-Step "compare FAIL (missing: $missing)"
    return 2
  }
  $shaA = Get-Sha256 $InstallerA
  $shaB = Get-Sha256 $InstallerB
  $sizeA = (Get-Item -LiteralPath $InstallerA).Length
  $sizeB = (Get-Item -LiteralPath $InstallerB).Length
  $byteA = [System.IO.File]::ReadAllBytes($InstallerA)
  $byteB = [System.IO.File]::ReadAllBytes($InstallerB)
  $same = $true
  if ($byteA.Length -ne $byteB.Length) { $same = $false }
  else {
    for ($i = 0; $i -lt $byteA.Length; $i++) { if ($byteA[$i] -ne $byteB[$i]) { $same = $false; break } }
  }
  $pass = $same -and ($shaA -eq $shaB) -and ($sizeA -eq $sizeB)
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Compare'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    buildA = [ordered]@{ path = $InstallerA; sha256 = $shaA; sizeBytes = $sizeA }
    buildB = [ordered]@{ path = $InstallerB; sha256 = $shaB; sizeBytes = $sizeB }
    byteIdentical = $same
    passed = $pass
    failureReason = if ($pass) { $null } else { 'installer outputs are not byte-identical' }
  }
  Write-Result 'compare' $result
  Write-Step ("compare {0} (sha {1})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $shaA)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# Install (silent per-user install into the isolated consumer root)
# ---------------------------------------------------------------------------
function Invoke-Install() {
  $start = Get-UtcNow
  $incoming = if ([string]::IsNullOrWhiteSpace($InstallerPath)) { $InstallerA } else { [System.IO.Path]::GetFullPath($InstallerPath) }
  if (-not (Test-Path -LiteralPath $incoming -PathType Leaf)) {
    Write-Result 'install' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Install'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; passed = $false; failureReason = "installer not found: $incoming" })
    Write-Step "install FAIL (installer not found: $incoming)"
    return 2
  }
  $incomingSha = Get-Sha256 $incoming
  if ($incoming -eq $InstallerA) {
    $ref = Join-Path $EvidenceDir 'builda-result.json'
    $refResult = if (Test-Path -LiteralPath $ref) { Get-Content -LiteralPath $ref -Raw | ConvertFrom-Json } else { $null }
    if ($null -ne $refResult -and $null -ne $refResult.installer -and $refResult.installer.sha256 -ne $incomingSha) {
      Write-Result 'install' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Install'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 1 }; passed = $false; failureReason = 'inbound installer does not match BuildA reference' })
      Write-Step "install FAIL (inbound installer does not match BuildA reference)"
      return 1
    }
  }

  $problems = @(Test-PreExistingInstallation)
  if ($problems.Count -gt 0) {
    Write-Result 'install' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Install'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 1 }; passed = $false; preExistingProblems = $problems; failureReason = 'pre-existing installation detected' })
    Write-Step "install FAIL (pre-existing installation detected)"
    return 1
  }

  Remove-OwnedDir $ConsumerRoot $Root
  New-Item -ItemType Directory -Path $InboundDir -Force | Out-Null
  New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
  New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $ProfileRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

  $inbound = Join-Path $InboundDir $ExpectedInstallerFilename
  Copy-Item -LiteralPath $incoming -Destination $inbound
  $inboundSha = Get-Sha256 $inbound
  $inboundSize = (Get-Item -LiteralPath $inbound).Length
  $notHardlink = $inboundSha -eq $incomingSha
  if (-not $notHardlink) {
    Write-Result 'install' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Install'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 1 }; passed = $false; failureReason = 'inbound copy failed hash check' })
    Write-Step "install FAIL (inbound copy failed hash check)"
    return 1
  }

  $installLog = Join-Path $LogsDir 'install.log'
  $argsList = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', ('/DIR=' + $InstallRoot), ('/LOG=' + $installLog))
  Write-Step "running silent install: $inbound"
  $p = Start-Process -FilePath $inbound -ArgumentList $argsList -Wait -PassThru
  $installExit = $p.ExitCode

  $installedExe = Join-Path $InstallRoot 'muaman_store.exe'
  $installed = Test-Path -LiteralPath $installedExe -PathType Leaf

  # --- installed payload verification against the frozen contract ------------
  $contractPath = Join-Path $RepoRoot 'tools\muaman13o\installer_contract.json'
  $contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
  $payloadIssues = @()
  $payloadFiles = @()
  foreach ($e in $contract.expectedInstalledFiles) {
    $rel = [string]$e.rel
    $f = Join-Path $InstallRoot ($rel.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { $payloadIssues += "missing: $rel"; continue }
    $size = (Get-Item -LiteralPath $f).Length
    $sha = Get-Sha256 $f
    $payloadFiles += [ordered]@{ rel = $rel; size = $size; sha256 = $sha; match = (($size -eq [int64]$e.size) -and ($sha -eq [string]$e.sha256)) }
    if ($size -ne [int64]$e.size) { $payloadIssues += "size-mismatch: $rel" }
    if ($sha -ne [string]$e.sha256) { $payloadIssues += "hash-mismatch: $rel" }
  }
  $allowedExtras = @('unins000.exe', 'unins000.dat', 'unins000.msg')
  $actualRels = @(Get-ChildItem -LiteralPath $InstallRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($InstallRoot.Length).TrimStart('\').Replace('\', '/').TrimStart('/') })
  $unexpected = @($actualRels | Where-Object { $_ -notin (@($payloadFiles | ForEach-Object { $_.rel }) + $allowedExtras) })
  if ($unexpected.Count -gt 0) { $payloadIssues += ("unexpected-installed-files: " + ($unexpected -join ', ')) }

  $startMenuShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\I-TECH للتكنولوجيا.lnk'
  $shortcutPresent = Test-Path -LiteralPath $startMenuShortcut -PathType Leaf

  $uninstallKeyPresent = $false
  $uninstallKeyInstallLocation = ''
  $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
  if (Test-Path -LiteralPath $uninstallKey) {
    foreach ($child in Get-ChildItem -LiteralPath $uninstallKey -ErrorAction SilentlyContinue) {
      $p = Get-ItemProperty -LiteralPath $child.PSPath -ErrorAction SilentlyContinue
      if ($p.DisplayName -eq 'I-TECH للتكنولوجيا') {
        $uninstallKeyPresent = $true
        $uninstallKeyInstallLocation = [string]$p.InstallLocation
      }
    }
  }

  $payloadVerified = ($payloadIssues.Count -eq 0)
  $pass = ($installExit -eq 0) -and $installed -and $payloadVerified -and $shortcutPresent -and $uninstallKeyPresent

  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Install'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    inbound = [ordered]@{ path = $inbound; sha256 = $inboundSha; sizeBytes = $inboundSize; sourceSha256 = $incomingSha }
    installCommand = [ordered]@{ installer = $inbound; arguments = ($argsList -join ' '); installDir = $InstallRoot; log = $installLog }
    installExitCode = $installExit
    installedExePresent = $installed
    payload = [ordered]@{ fileCount = $payloadFiles.Count; verified = $payloadVerified; files = $payloadFiles; allowedInstallerOwnedFiles = $allowedExtras; unexpectedFiles = $unexpected }
    startMenuShortcut = [ordered]@{ path = $startMenuShortcut; present = $shortcutPresent }
    uninstallRegistration = [ordered]@{ present = $uninstallKeyPresent; installLocation = $uninstallKeyInstallLocation }
    passed = $pass
    failureReason = if ($pass) { $null } else { 'install or payload/shortcut/registry verification failed' }
  }
  Write-Result 'install' $result
  Write-Step ("install {0} (exit {1}, payload {2}, shortcut {3}, uninstall-key {4})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $installExit, $payloadVerified, $shortcutPresent, $uninstallKeyPresent)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# Launch (isolated-profile launch with process/window/module checks)
# ---------------------------------------------------------------------------
function Invoke-Launch() {
  $start = Get-UtcNow
  $installedExe = Join-Path $InstallRoot 'muaman_store.exe'
  if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) {
    Write-Result 'launch' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Launch'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; passed = $false; failureReason = 'installed exe missing; run Install first' })
    Write-Step "launch FAIL (installed exe missing)"
    return 2
  }

  $before = Get-DirSnapshot $InstallRoot

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $installedExe
  $psi.WorkingDirectory = $InstallRoot
  $psi.UseShellExecute = $false
  $psi.EnvironmentVariables['APPDATA'] = $ProfileRoot
  $psi.EnvironmentVariables['LOCALAPPDATA'] = $ProfileRoot
  $psi.EnvironmentVariables['TEMP'] = $TempRoot
  $psi.EnvironmentVariables['TMP'] = $TempRoot
  $psi.EnvironmentVariables['USERPROFILE'] = $ProfileRoot
  $psi.EnvironmentVariables['HOMEDRIVE'] = Split-Path -Qualifier $ProfileRoot
  $psi.EnvironmentVariables['HOMEPATH'] = $ProfileRoot.Substring(2)
  $psi.EnvironmentVariables['FLUTTER_BUILD_DIR'] = $InstallRoot

  $proc = [System.Diagnostics.Process]::Start($psi)
  Write-Step ("launched muaman_store pid {0}" -f $proc.Id)

  Start-Sleep -Seconds $LaunchAliveSeconds
  $proc.Refresh()
  $aliveAfter = -not $proc.HasExited

  $windowOk = $false
  $deadline = [DateTime]::UtcNow.AddSeconds($MainWindowTimeoutSeconds)
  while ([DateTime]::UtcNow -lt $deadline -and -not $proc.HasExited) {
    $proc.Refresh()
    if ($proc.MainWindowHandle -ne 0) { $windowOk = $true; break }
    Start-Sleep -Milliseconds 500
  }
  $mainWindowTitle = if ($windowOk) { $proc.MainWindowTitle } else { '' }

  $moduleIssues = @()
  $moduleCount = 0
  if ($aliveAfter) {
    try {
      foreach ($m in $proc.Modules) {
        $moduleCount++
        $f = $m.FileName
        if ([string]::IsNullOrWhiteSpace($f)) { continue }
        $f = [System.IO.Path]::GetFullPath($f)
        $ok = (Test-IsUnder $f $InstallRoot) -or (Test-IsUnder $f $env:WINDIR)
        if (-not $ok) { $moduleIssues += $f }
      }
    } catch { $moduleIssues += ('module enumeration error: ' + $_.Exception.Message) }
  }

  $cleanShutdown = $false
  $shutdownMethod = 'none'
  if ($aliveAfter) {
    $proc.Refresh()
    if ($windowOk -and -not $proc.HasExited) {
      $shutdownMethod = 'CloseMainWindow'
      $cleanShutdown = $proc.CloseMainWindow()
      if (-not $proc.WaitForExit(15000)) { $shutdownMethod = 'Kill'; $proc.Kill() }
    } else {
      $shutdownMethod = 'Kill'
      $proc.Kill()
    }
    $proc.WaitForExit()
    $cleanShutdown = $cleanShutdown -and ($proc.HasExited)
  }

  $after = Get-DirSnapshot $InstallRoot
  $snapshotDiffs = @(Compare-DirSnapshots $before $after)

  # The acceptance gate is the 13 shipped payload files: they must be byte-identical
  # after launch (no shipped file modified or removed). New files that the
  # application itself creates at runtime inside the (per-user writable) install
  # directory - e.g. its SQLite business database - are recorded as observed
  # runtime behavior, not treated as failures.
  $payloadUnchanged = $true
  $payloadDiffDetails = @()
  foreach ($rel in $PayloadRels) {
    $b = $before[$rel]
    $a = $after[$rel]
    if ($null -eq $b -or $null -eq $a) { $payloadUnchanged = $false; $payloadDiffDetails += "missing-or-added: $rel"; continue }
    if ($b.size -ne $a.size -or $b.sha256 -ne $a.sha256) { $payloadUnchanged = $false; $payloadDiffDetails += "modified: $rel" }
  }
  $runtimeCreated = @($after.Keys | Where-Object { -not $before.Contains($_) } | Sort-Object)

  $pass = $aliveAfter -and $windowOk -and ($moduleIssues.Count -eq 0) -and $cleanShutdown -and $payloadUnchanged
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Launch'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    process = [ordered]@{
      pid = $proc.Id
      aliveAfterSeconds = $aliveAfter
      mainWindowVisible = $windowOk
      mainWindowTitle = $mainWindowTitle
      modulesLoaded = $moduleCount
      moduleOriginIssues = $moduleIssues
      shutdownMethod = $shutdownMethod
      cleanShutdown = $cleanShutdown
    }
    isolatedEnvironment = [ordered]@{ APPDATA = $ProfileRoot; LOCALAPPDATA = $ProfileRoot; TEMP = $TempRoot; TMP = $TempRoot; USERPROFILE = $ProfileRoot }
    payloadFilesUnchangedAfterLaunch = $payloadUnchanged
    payloadDiffDetails = $payloadDiffDetails
    runtimeDataCreatedInInstallDir = $runtimeCreated
    fullTreeDiffs = $snapshotDiffs
    passed = $pass
    failureReason = if ($pass) { $null } else { 'one or more launch checks failed' }
  }
  Write-Result 'launch' $result
  Write-Step ("launch {0} (pid {1}, window {2}, modules {3}, payload-unchanged {4})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $proc.Id, $windowOk, $moduleCount, $payloadUnchanged)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# Uninstall (silent uninstall + removal / data-preservation checks)
# ---------------------------------------------------------------------------
function Invoke-Uninstall() {
  $start = Get-UtcNow
  $uninstaller = Join-Path $InstallRoot 'unins000.exe'
  if (-not (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
    Write-Result 'uninstall' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Uninstall'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; passed = $false; failureReason = 'uninstaller missing; run Install first' })
    Write-Step "uninstall FAIL (uninstaller missing)"
    return 2
  }

  $profilePreserved = (Test-Path -LiteralPath $ProfileRoot)
  $profileFileCount = if ($profilePreserved) { @(Get-ChildItem -LiteralPath $ProfileRoot -Recurse -File).Count } else { 0 }

  # Capture the application's business data stored INSIDE the install directory
  # (created at runtime, e.g. the SQLite database). This is what uninstall must
  # preserve: the uninstaller removes every installed payload file, and the
  # [UninstallDelete] dirifempty rule leaves any non-empty {app} untouched.
  $dataBefore = [ordered]@{}
  $uninstallerOwned = @('unins000.exe', 'unins000.dat', 'unins000.msg')
  if (Test-Path -LiteralPath $InstallRoot) {
    foreach ($f in Get-ChildItem -LiteralPath $InstallRoot -Recurse -File) {
      $rel = $f.FullName.Substring($InstallRoot.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
      if ($rel -notin $PayloadRels -and $rel -notin $uninstallerOwned) { $dataBefore[$rel] = $f.Length }
    }
  }

  $uninstallLog = Join-Path $LogsDir 'uninstall.log'
  $argsList = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', ('/LOG=' + $uninstallLog))
  $p = Start-Process -FilePath $uninstaller -ArgumentList $argsList -Wait -PassThru
  $uninstallExit = $p.ExitCode

  $installRootGone = -not (Test-Path -LiteralPath $InstallRoot)
  for ($i = 0; $i -lt 6 -and -not $installRootGone; $i++) {
    Start-Sleep -Seconds 2
    $installRootGone = -not (Test-Path -LiteralPath $InstallRoot)
  }
  $uninsGone = -not (Test-Path -LiteralPath (Join-Path $InstallRoot 'unins000.exe'))
  $startMenuShortcutGone = -not (Test-Path -LiteralPath (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\I-TECH للتكنولوجيا.lnk'))

  $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
  $registryGone = $true
  if (Test-Path -LiteralPath $uninstallKey) {
    foreach ($child in Get-ChildItem -LiteralPath $uninstallKey -ErrorAction SilentlyContinue) {
      $disp = (Get-ItemProperty -LiteralPath $child.PSPath -ErrorAction SilentlyContinue).DisplayName
      if ($disp -eq 'I-TECH للتكنولوجيا') { $registryGone = $false }
    }
  }

  $procRunning = $null -ne (Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue)

  # All 16 shipped payload files must be gone.
  $payloadAllGone = $true
  $payloadRemaining = @()
  foreach ($rel in $PayloadRels) {
    $f = Join-Path $InstallRoot ($rel.Replace('/', '\'))
    if (Test-Path -LiteralPath $f) { $payloadAllGone = $false; $payloadRemaining += $rel }
  }

  # Business data must survive.
  $dataMissingAfter = @()
  foreach ($k in $dataBefore.Keys) {
    $f = Join-Path $InstallRoot ($k.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $f)) { $dataMissingAfter += $k }
  }
  $businessDataPreserved = ($dataMissingAfter.Count -eq 0)
  $installRootState = if ($installRootGone) { 'absent' } elseif (Test-Path -LiteralPath $InstallRoot) { 'present' } else { 'unknown' }

  $pass = ($uninstallExit -eq 0) -and $payloadAllGone -and $uninsGone -and $startMenuShortcutGone -and $registryGone -and (-not $procRunning) -and $businessDataPreserved -and $profilePreserved
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Uninstall'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    uninstallCommand = [ordered]@{ uninstaller = $uninstaller; arguments = ($argsList -join ' '); log = $uninstallLog }
    uninstallExitCode = $uninstallExit
    businessDataBeforeUninstall = @($dataBefore.Keys)
    checks = [ordered]@{
      installedPayloadRemoved = $payloadAllGone
      payloadRemaining = $payloadRemaining
      uninstallerRemoved = $uninsGone
      startMenuShortcutRemoved = $startMenuShortcutGone
      uninstallRegistryRemoved = $registryGone
      noProcessRunning = (-not $procRunning)
      businessDataPreserved = $businessDataPreserved
      businessDataMissingAfter = $dataMissingAfter
      userProfilePreserved = $profilePreserved
      preservedProfileFileCount = $profileFileCount
      installRootState = $installRootState
    }
    passed = $pass
    failureReason = if ($pass) { $null } else { 'one or more uninstall checks failed' }
  }
  Write-Result 'uninstall' $result
  Write-Step ("uninstall {0} (exit {1}, payload-removed {2}, data-preserved {3}, profile {4})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $uninstallExit, $payloadAllGone, $businessDataPreserved, $profilePreserved)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# Negative (tampered staging payload must be rejected)
# ---------------------------------------------------------------------------
function Invoke-Negative() {
  $start = Get-UtcNow
  $referenceInstaller = Join-Path $EvidenceDir 'builda-result.json'
  if (-not (Test-Path -LiteralPath $referenceInstaller)) {
    Write-Result 'negative' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Negative'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; passed = $false; failureReason = 'BuildA evidence missing' })
    Write-Step "negative FAIL (BuildA evidence missing)"
    return 2
  }

  if (Test-Path -LiteralPath $NegativeRoot) { Remove-OwnedDir $NegativeRoot $Root }
  New-Item -ItemType Directory -Path (Join-Path $NegativeRoot 'evidence') -Force | Out-Null

  $packageOut = Join-Path $NegativeRoot 'package'
  $pkgOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'tools\release\package_windows_release.ps1') `
    -RepoRoot $RepoRoot -ReleaseDir $ReleaseDir -OutputDir $packageOut -EvidenceDir (Join-Path $NegativeRoot 'package-evidence')
  $pkgExit = $LASTEXITCODE
  $pkgOutput | ForEach-Object { Write-Host $_ }
  if ($pkgExit -ne 0) {
    Write-Result 'negative' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Negative'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 1 }; passed = $false; failureReason = 'could not create reference package for tampering' })
    Write-Step "negative FAIL (package creation failed)"
    return 1
  }

  $zipPath = Join-Path $packageOut 'muaman-windows-release.zip'
  $zipSha = Get-Sha256 $zipPath
  $zipOk = $zipSha -eq $ExpectedZipSha256
  $tamperedStaging = Join-Path $NegativeRoot 'staging'
  New-Item -ItemType Directory -Path $tamperedStaging -Force | Out-Null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tamperedStaging)

  $victim = Join-Path $tamperedStaging 'muaman_store.exe'
  $victimShaBefore = Get-Sha256 $victim
  $bytes = [System.IO.File]::ReadAllBytes($victim)
  $bytes[0] = ($bytes[0] -bxor 0xFF)
  [System.IO.File]::WriteAllBytes($victim, $bytes)
  $tamperApplied = (Get-Sha256 $victim) -ne $victimShaBefore

  $negOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Entrypoint `
    -RepoRoot $RepoRoot `
    -ReleaseDir $ReleaseDir `
    -WorkingRoot (Join-Path $NegativeRoot 'work') `
    -OutputDir (Join-Path $NegativeRoot 'out') `
    -EvidenceDir (Join-Path $NegativeRoot 'evidence') `
    -InstallerCompilerPath $InstallerCompilerPath `
    -OutputFilename $ExpectedInstallerFilename `
    -StagingDir $tamperedStaging `
    -PreflightOnly
  $negExit = $LASTEXITCODE
  $negOutput | ForEach-Object { Write-Host $_ }

  $noInstallerProduced = -not (Test-Path -LiteralPath (Join-Path $NegativeRoot 'out\muaman-windows-installer.exe'))
  $failClosed = ($negExit -ne 0) -and $noInstallerProduced
  $pass = $failClosed

  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Negative'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    tamper = [ordered]@{
      stagingDir = $tamperedStaging
      tamperedFile = 'muaman_store.exe'
      method = 'single-byte xor flip (0x40 bit) applied to the owned staging COPY only'
      packageShaVerified = $zipOk
      tamperApplied = $tamperApplied
    }
    preflightExitCode = $negExit
    failClosed = $failClosed
    installerArtifactProduced = (-not $noInstallerProduced)
    passed = $pass
    failureReason = if ($pass) { $null } else { 'tampered staging was NOT rejected (expected non-zero exit and no installer)' }
  }
  Write-Result 'negative' $result
  Write-Step ("negative {0} (preflight exit {1})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $negExit)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# Guards (O-series)
# ---------------------------------------------------------------------------
function Invoke-Guards() {
  $start = Get-UtcNow
  if (-not (Test-Path -LiteralPath $Guards -PathType Leaf)) {
    Write-Result 'guards' ([ordered]@{ schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Guards'; run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = 2 }; passed = $false; failureReason = 'guard_tests_13o.ps1 missing' })
    Write-Step "guards FAIL (guard_tests_13o.ps1 missing)"
    return 2
  }
  $guardOut = Join-Path $EvidenceDir 'guards-verdicts.json'
  $guardOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Guards -RepoRoot $RepoRoot -Out $guardOut -AcceptanceRoot $Root -ReleaseDir $ReleaseDir -CompilerPath $InstallerCompilerPath
  $guardExit = $LASTEXITCODE
  $guardOutput | ForEach-Object { Write-Host $_ }
  $pass = $guardExit -eq 0
  $result = [ordered]@{
    schemaVersion = '1.0'; phase = 'MUAMAN-13O'; mode = 'Guards'
    run = [ordered]@{ startedAtUtc = $start; finishedAtUtc = (Get-UtcNow); exitCode = $(if ($pass) { 0 } else { 1 }) }
    guardsExitCode = $guardExit
    guardsOutput = $guardOut
    passed = $pass
    failureReason = if ($pass) { $null } else { 'O-series guard tests failed' }
  }
  Write-Result 'guards' $result
  Write-Step ("guards {0} (exit {1})" -f ($(if ($pass) { 'PASS' } else { 'FAIL' })), $guardExit)
  if ($pass) { return 0 }
  return 1
}

# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------
Write-Step ("mode(s): {0}; root {1}; run-id {2}" -f ($modesToRun -join ','), $Root, $RunId)
$finalExit = 0
foreach ($m in $modesToRun) {
  $code = switch ($m) {
    'Preflight' { Invoke-Preflight }
    'BuildA' { Invoke-BuildA }
    'BuildB' { Invoke-BuildB }
    'Compare' { Invoke-Compare }
    'Install' { Invoke-Install }
    'Launch' { Invoke-Launch }
    'Uninstall' { Invoke-Uninstall }
    'Negative' { Invoke-Negative }
    'Guards' { Invoke-Guards }
    default { 2 }
  }
  if ($code -ne 0) { $finalExit = $code; break }
}
Write-Step ("harness finished with exit {0}" -f $finalExit)
exit $finalExit
