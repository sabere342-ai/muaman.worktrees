# MUAMAN-13O deterministic Windows installer packaging entrypoint.
#
# THE SINGLE OFFICIAL COMMAND for building the muaman Windows installer from the
# canonical deterministic release package. It is a THIN OPERATIONAL INTERFACE
# ONLY:
#
#   1. DELEGATES the release build/verification/packaging entirely to
#      tools/release/package_windows_release.ps1 (which itself delegates to
#      verify_release.ps1 + the committed MUAMAN-13K legal manifest). This
#      script NEVER runs flutter build, never invokes CMake directly, never
#      reads build\windows, never re-invents the release manifest, and never
#      collects files from multiple places.
#   2. Verifies the produced release package against the accepted MUAMAN-13N
#      identity (ZIP SHA-256 / size / entry count / cross-hash).
#   3. Extracts the package to an OWNED staging root and verifies the extracted
#      13-file release manifest (via the canonical verifier) BEFORE compiling.
#   4. Compiles the installer with the pinned Inno Setup compiler (identity
#      checked against the frozen contract: version + SHA-256). Any missing,
#      unexpected, or ambiguous compiler causes a refusal.
#   5. Verifies the installer output (exists, non-empty, SHA-256 recorded).
#   6. Is fail-closed, non-interactive, deterministic, writes structured logs
#      and a machine-readable result, and resolves every path from explicit
#      parameters or its own script location (never from the caller's working
#      directory).
#
# Exit codes:
#   0  success (installer produced and verified)
#   1  release verification / package identity / staging manifest failure
#   2  parameter / input / path validation failure
#   3  installer compilation failure
#   4  unexpected error
#
# Usage (from any working directory):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     <repo>\tools\release\package_windows_installer.ps1 `
#     -RepoRoot <repo> `
#     -ReleaseDir <verified-release-dir> `
#     -WorkingRoot <owned-working-root> `
#     -OutputDir <installer-output-dir> `
#     -EvidenceDir <evidence-output-dir>
#
# Optional switches:
#   -InstallerCompilerPath <file>  ISCC.exe (default: contract pinned compiler)
#   -OutputFilename <name>         installer file name (default: muaman-windows-installer.exe)
#   -StagingDir <dir>              consume a pre-existing verified staging payload
#                                  instead of package+extract (negative control /
#                                  preflight reuse); the staging is ALWAYS
#                                  re-verified against the legal manifest.
#   -PreflightOnly                 stop after staging manifest verification
#                                  (no installer compilation)
#   -KeepWorkingFiles              do not remove the packaging temporary tree

param(
  [string]$RepoRoot = '',
  [Parameter(Mandatory = $true)][string]$ReleaseDir,
  [Parameter(Mandatory = $true)][string]$WorkingRoot,
  [Parameter(Mandatory = $true)][string]$OutputDir,
  [string]$EvidenceDir = '',
  [string]$InstallerCompilerPath = '',
  [string]$OutputFilename = 'muaman-windows-installer.exe',
  [string]$StagingDir = '',
  [switch]$PreflightOnly,
  [switch]$KeepWorkingFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

# ---------------------------------------------------------------------------
# governed delivery-package refresh contract constants (accepted MUAMAN-19
# canonical release; supersedes the frozen MUAMAN-13N / MUAMAN-13O identity)
# ---------------------------------------------------------------------------
$ExpectedZipSha256        = 'FEC8B79BA57FEB01EE12561AD21A32183073BFFFD8054E5AE1CCB62F83683355'
$ExpectedZipSize          = 15555975
$ExpectedZipEntryCount    = 16
$ExpectedCrossHash        = '7BC418546CABA55A3389C22A277B327D32683ABC91DA6CAF75FDA163E7204D6F'
$ExpectedFileCount        = 16
$ExpectedTotalBytes       = 35753553
$ExpectedCompilerVersion  = '6.7.3'
$ExpectedCompilerSha256   = '0A8757031B33777E4C9CBFFEE40F11A5062B36D25CBE144C1DB73B6102B80AD7'
$ApplicationVersion       = '1.0.0'

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ('[MUAMAN-13O] {0}' -f $message)
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
  if ($i.StartsWith($o + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $false
}

function Get-RelPath([string]$full, [string]$base) {
  return $full.Substring($base.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
}

function Remove-OwnedDir([string]$path, [string]$root) {
  if (-not (Test-IsUnder $path $root)) {
    throw ("refusing to remove {0}: not under owned root {1}" -f $path, $root)
  }
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
  }
}

# ---------------------------------------------------------------------------
# stage tracking
# ---------------------------------------------------------------------------
$stage = 'validate'
$startUtc = Get-UtcNow
$compileLog = ''

try {

  # -------------------------------------------------------------------------
  # 1. repository root resolution + validation
  # -------------------------------------------------------------------------
  if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $scriptDir = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
  }
  $RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
  if ([string]::IsNullOrWhiteSpace($EvidenceDir)) { $EvidenceDir = Join-Path $WorkingRoot 'evidence' }

  foreach ($marker in @(
    (Join-Path $RepoRoot 'app\pubspec.yaml'),
    (Join-Path $RepoRoot 'tools\release\package_windows_release.ps1'),
    (Join-Path $RepoRoot 'installer\muaman.iss')
  )) {
    if (-not (Test-Path -LiteralPath $marker)) {
      Write-Host ("[MUAMAN-13O] ERROR repository structure not found at {0}; missing {1}" -f $RepoRoot, $marker)
      exit 2
    }
  }

  $ReleaseDir = [System.IO.Path]::GetFullPath($ReleaseDir)
  $WorkingRoot = [System.IO.Path]::GetFullPath($WorkingRoot)
  $OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
  $EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
  $InstallerDefinition = Join-Path $RepoRoot 'installer\muaman.iss'
  $PackageEntrypoint = Join-Path $RepoRoot 'tools\release\package_windows_release.ps1'
  $Verifier = Join-Path $RepoRoot 'tools\release\verify_release.ps1'
  $LegalManifest = Join-Path $RepoRoot 'docs\windows-delivery-refresh\evidence\legal\release-manifest.json'

  if (-not (Test-Path -LiteralPath $ReleaseDir -PathType Container)) {
    Write-Host ("[MUAMAN-13O] ERROR ReleaseDir does not exist: {0}" -f $ReleaseDir); exit 2
  }
  if ([string]::IsNullOrWhiteSpace($OutputFilename) -or $OutputFilename -match '[\\/]') {
    Write-Host '[MUAMAN-13O] ERROR OutputFilename must be a plain file name (no path separators)'; exit 2
  }
  if ($WorkingRoot -ieq $RepoRoot) {
    Write-Host '[MUAMAN-13O] ERROR WorkingRoot must not equal the repository root'; exit 2
  }
  if (Test-IsUnder $WorkingRoot $RepoRoot) {
    Write-Host '[MUAMAN-13O] ERROR WorkingRoot must be OUTSIDE the repository (isolation requirement)'; exit 2
  }
  if (Test-IsUnder $ReleaseDir $WorkingRoot) {
    Write-Host '[MUAMAN-13O] ERROR ReleaseDir must not be inside WorkingRoot'; exit 2
  }
  if (Test-IsUnder $OutputDir $WorkingRoot) {
    Write-Host '[MUAMAN-13O] ERROR OutputDir must be OUTSIDE WorkingRoot (installer artifacts kept separate from working tree)'; exit 2
  }

  New-Item -ItemType Directory -Path $WorkingRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
  New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

  # -------------------------------------------------------------------------
  # 2. installer compiler identity (frozen contract check)
  # -------------------------------------------------------------------------
  $stage = 'compiler'
  if ([string]::IsNullOrWhiteSpace($InstallerCompilerPath)) {
    $InstallerCompilerPath = 'C:\m13o\toolchain\inno-6.7.3\ISCC.exe'
  }
  $InstallerCompilerPath = [System.IO.Path]::GetFullPath($InstallerCompilerPath)
  if (-not (Test-Path -LiteralPath $InstallerCompilerPath -PathType Leaf)) {
    Write-Host ("[MUAMAN-13O] ERROR installer compiler missing: {0}" -f $InstallerCompilerPath); exit 2
  }
  $compilerSha = Get-Sha256 $InstallerCompilerPath
  $compilerName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerCompilerPath)
  if ($compilerName -ne 'ISCC') {
    Write-Host ("[MUAMAN-13O] ERROR unexpected compiler executable name: {0}" -f $compilerName); exit 2
  }
  if ($compilerSha -ne $ExpectedCompilerSha256) {
    Write-Host ("[MUAMAN-13O] ERROR unexpected installer compiler SHA-256 {0}; expected {1} (frozen MUAMAN-13O contract). Refusing to build." -f $compilerSha, $ExpectedCompilerSha256)
    exit 2
  }
  Write-Step ("compiler identity OK: {0} SHA-256 {1}" -f $InstallerCompilerPath, $compilerSha)

  # -------------------------------------------------------------------------
  # 3. canonical release packaging (DELEGATION - never re-implemented here)
  # -------------------------------------------------------------------------
  $packageOut = Join-Path $WorkingRoot 'package\out'
  $packageEvidence = Join-Path $WorkingRoot 'package\evidence'
  $zipPath = Join-Path $packageOut 'muaman-windows-release.zip'
  if (Test-Path -LiteralPath $packageOut) { Remove-OwnedDir $packageOut $WorkingRoot }
  if (Test-Path -LiteralPath $packageEvidence) { Remove-OwnedDir $packageEvidence $WorkingRoot }

  $staging = $null
  if ([string]::IsNullOrWhiteSpace($StagingDir)) {
    $stage = 'package'
    Write-Step ("packaging verified release {0} via canonical entrypoint" -f $ReleaseDir)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PackageEntrypoint `
      -RepoRoot $RepoRoot `
      -ReleaseDir $ReleaseDir `
      -OutputDir $packageOut `
      -EvidenceDir $packageEvidence
    $pkgExit = $LASTEXITCODE
    if ($pkgExit -ne 0 -or -not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
      Write-Host ("[MUAMAN-13O] canonical packaging failed (exit {0}); no ZIP produced" -f $pkgExit)
      exit 1
    }
    Write-Step ("canonical packaging PASS (exit {0})" -f $pkgExit)

    # --- verify package identity against the accepted MUAMAN-13N contract ----
    $stage = 'package-identity'
    $zipSha = Get-Sha256 $zipPath
    $zipSize = (Get-Item -LiteralPath $zipPath).Length
    $zipIdOk = ($zipSha -eq $ExpectedZipSha256) -and ($zipSize -eq $ExpectedZipSize)
    if (-not $zipIdOk) {
      Write-Host ("[MUAMAN-13O] ERROR package identity mismatch: sha={0} size={1}; expected sha={2} size={3}" -f $zipSha, $zipSize, $ExpectedZipSha256, $ExpectedZipSize)
      exit 1
    }
    $entryCount = [System.IO.Compression.ZipFile]::OpenRead($zipPath).Entries.Count
    if ($entryCount -ne $ExpectedZipEntryCount) {
      Write-Host ("[MUAMAN-13O] ERROR package entry count mismatch: {0}; expected {1}" -f $entryCount, $ExpectedZipEntryCount)
      exit 1
    }
    Write-Step ("package identity OK: sha={0} size={1} entries={2}" -f $zipSha, $zipSize, $entryCount)

    # --- extract to owned staging root ---
    $stage = 'extract'
    $staging = Join-Path $WorkingRoot 'staging'
    Remove-OwnedDir $staging $WorkingRoot
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $staging)
    Write-Step ("package extracted to {0}" -f $staging)
  } else {
    $staging = [System.IO.Path]::GetFullPath($StagingDir)
    if (-not (Test-Path -LiteralPath $staging -PathType Container)) {
      Write-Host ("[MUAMAN-13O] ERROR StagingDir does not exist: {0}" -f $staging); exit 2
    }
    Write-Step ("using caller-provided staging {0}" -f $staging)
  }

  # -------------------------------------------------------------------------
  # 4. staging manifest verification (canonical verifier) BEFORE any compile
  # -------------------------------------------------------------------------
  $stage = 'staging-verify'
  $verifyOut = Join-Path $EvidenceDir 'staging-verification.json'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Verifier `
    -ReleaseDir $staging `
    -LegalManifest $LegalManifest `
    -Out $verifyOut
  $verifyExit = $LASTEXITCODE
  $verify = $null
  if (Test-Path -LiteralPath $verifyOut) { $verify = Get-Content -LiteralPath $verifyOut -Raw | ConvertFrom-Json }
  $verified = ($verifyExit -eq 0) -and ($null -ne $verify) -and ([bool]$verify.identical)
  if (-not $verified) {
    Write-Host ("[MUAMAN-13O] STAGING MANIFEST MISMATCH (verify exit {0}); installer compilation refused. See {1}" -f $verifyExit, $verifyOut)
    exit 1
  }
  Write-Step ("staging manifest verification PASS (exit {0}); files={1} bytes={2} cross={3}" -f $verifyExit, $verify.fileCountNew, $verify.totalBytesNew, $verify.crossHashNew)

  # -------------------------------------------------------------------------
  # 5. installer compilation (only when not in preflight-only mode)
  # -------------------------------------------------------------------------
  $installerPath = Join-Path $OutputDir $OutputFilename
  if ($PreflightOnly) {
    Write-Step "preflight-only: staging verified; no installer compiled"
    exit 0
  }

  if (Test-Path -LiteralPath $installerPath -PathType Leaf) { Remove-Item -LiteralPath $installerPath -Force }
  $stage = 'compile'
  $compileLog = Join-Path $EvidenceDir 'installer-compile.log'
  $isccArgs = @(
    ('/DAppSourceDir="{0}"' -f $staging),
    ('/DOutDir="{0}"' -f $OutputDir),
    ('/DOutName="{0}"' -f ([System.IO.Path]::GetFileNameWithoutExtension($OutputFilename))),
    $InstallerDefinition
  )
  $startCompile = Get-UtcNow
  & $InstallerCompilerPath $isccArgs *>&1 | Tee-Object -FilePath $compileLog | Out-Null
  $compileExit = $LASTEXITCODE
  $finishCompile = Get-UtcNow
  if ($compileExit -ne 0 -or -not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    Write-Host ("[MUAMAN-13O] installer compilation FAILED (ISCC exit {0}). Log: {1}" -f $compileExit, $compileLog)
    exit 3
  }
  $installerSize = (Get-Item -LiteralPath $installerPath).Length
  $installerSha = Get-Sha256 $installerPath
  Write-Step ("installer compiled: {0} ({1} bytes) SHA-256 {2}" -f $installerPath, $installerSize, $installerSha)

  # -------------------------------------------------------------------------
  # 6. result record
  # -------------------------------------------------------------------------
  $result = [ordered]@{
    schemaVersion = '1.0'
    phase = 'MUAMAN-13O'
    run = [ordered]@{ startedAtUtc = $startUtc; finishedAtUtc = (Get-UtcNow); exitCode = 0 }
    sourceReleasePackage = [ordered]@{
      path = if ([string]::IsNullOrWhiteSpace($StagingDir)) { $zipPath } else { $null }
      sha256 = if ([string]::IsNullOrWhiteSpace($StagingDir)) { $zipSha } else { $null }
      sizeBytes = if ([string]::IsNullOrWhiteSpace($StagingDir)) { $zipSize } else { $null }
      identityVerified = if ([string]::IsNullOrWhiteSpace($StagingDir)) { $zipIdOk } else { $true }
    }
    staging = [ordered]@{ path = $staging; manifestVerificationPassed = $true; verifierExitCode = $verifyExit }
    installer = [ordered]@{
      outputPath = $installerPath
      outputFilename = $OutputFilename
      sha256 = $installerSha
      sizeBytes = $installerSize
      compileExitCode = $compileExit
      compileStartedAtUtc = $startCompile
      compileFinishedAtUtc = $finishCompile
    }
    application = [ordered]@{ version = $ApplicationVersion; architecture = 'x64' }
    toolchain = [ordered]@{ technology = 'Inno Setup 6'; compilerPath = $InstallerCompilerPath; compilerVersion = $ExpectedCompilerVersion; compilerSha256 = $compilerSha }
    manifestVerification = [ordered]@{ fileCount = $verify.fileCountNew; totalBytes = $verify.totalBytesNew; crossHash = $verify.crossHashNew }
    preflightOnly = [bool]$PreflightOnly
    outputs = [ordered]@{ installerPath = $installerPath; compileLog = $compileLog; stagingVerification = $verifyOut; packageResult = (Join-Path $packageEvidence 'package-result.json') }
    failureReason = $null
  }
  Write-Utf8NoBom (Join-Path $EvidenceDir 'installer-result.json') ($result | ConvertTo-Json -Depth 10)

  # -------------------------------------------------------------------------
  # 7. owned temporary cleanup (unless the caller asks to keep the working tree)
  # -------------------------------------------------------------------------
  if (-not $KeepWorkingFiles) {
    Remove-OwnedDir (Join-Path $WorkingRoot 'package') $WorkingRoot
    Remove-OwnedDir $staging $WorkingRoot
  }

  Write-Step "RESULT: PASS (exit 0)"
  Write-Step ("INSTALLER: {0} ({1} bytes)" -f $installerPath, $installerSize)
  Write-Step ("SHA-256: {0}" -f $installerSha)
  exit 0

} catch {
  $err = $_.Exception.Message
  $code = switch ($stage) {
    'validate' { 2 }
    'compiler' { 2 }
    'package' { 1 }
    'package-identity' { 1 }
    'extract' { 3 }
    'staging-verify' { 1 }
    'compile' { 3 }
    default { 4 }
  }
  try {
    $fail = [ordered]@{
      schemaVersion = '1.0'; phase = 'MUAMAN-13O'
      run = [ordered]@{ startedAtUtc = $startUtc; finishedAtUtc = (Get-UtcNow); exitCode = $code }
      stage = $stage
      failureReason = $err
    }
    Write-Utf8NoBom (Join-Path $EvidenceDir 'installer-result.json') ($fail | ConvertTo-Json -Depth 8)
  } catch { }
  Write-Host ("[MUAMAN-13O] FAILED (stage {0}, exit {1}): {2}" -f $stage, $code, $err)
  exit $code
}
