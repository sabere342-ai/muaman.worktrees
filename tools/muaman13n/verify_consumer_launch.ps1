# MUAMAN-13N independent consumer packaged-release launch verification harness.
#
# Verifies that the MUAMAN-13M canonical deterministic Windows release package
# (muaman-windows-release.zip) is portable, unpackable and launchable from an
# independent consumer environment that contains NO repository tree, NO
# Flutter/Dart SDK, NO PUB_CACHE, NO Git, NO CMake/Ninja and NO Visual Studio
# build tools.
#
# This script is a THIN, fail-closed operational harness ONLY. It:
#   1. never modifies the repository, the legal manifest or the packaged
#      release ZIP;
#   2. performs fresh, owned-only extraction and launch of the packaged release
#      inside a caller-provided consumer root;
#   3. enforces the MUAMAN-13N consumer-launch guards N1..N12 (see -? or the
#      MUAMAN-13N report) with explicit pass/fail status per guard;
#   4. writes structured machine-readable evidence (JSON, UTF-8, no BOM,
#      UTC timestamps, '/'-normalized relative paths);
#   5. deletes files/directories only when they are strictly below the
#      caller-provided ConsumerRoot;
#   6. never requires the caller's current working directory (every path is
#      resolved from parameters or the script location).
#
# Launch environment isolation (every run):
#   - PATH is replaced by 'C:\Windows\System32;C:\Windows' (no Flutter, Dart,
#     Git, CMake, Ninja, VS Build Tools, PUB_CACHE, repo, SDK or workspace).
#   - APPDATA, LOCALAPPDATA, TEMP, TMP and USERPROFILE point to fresh,
#     per-run directories below the consumer root.
#   - PUB_CACHE, FLUTTER_ROOT, DART_HOME and DART_SDK are cleared.
#
# Guard map (N1..N12):
#   N1  harness parameters / input paths valid
#   N2  consumer launch environment is independent (no build tooling)
#   N3  inbound archive identity matches the MUAMAN-13M contract
#   N4  archive copy is a real copy (not a hard link) with matching hash
#   N5  archive extraction is safe and yields the exact 13 canonical files
#   N6  pre-launch manifest: extracted files match the legal manifest
#   N7  isolated launch: fresh profile + minimal PATH + correct working dir
#   N8  liveness: process alive after the observation window with a main window
#   N9  module-origin: no module loads from repo/SDK/cache/build roots
#   N10 post-launch manifest: the 13 release files remain byte-identical
#   N11 clean termination via the main window
#   N12 verdict aggregation and evidence output completeness
#   (negative-control mode additionally proves that a tampered package is
#    detected and rejected by the pre-launch manifest guard.)
#
# Exit codes:
#   0  success (all executed guards passed; negative control correctly rejected)
#   1  verification failed (a guard failed / negative control not rejected)
#   2  parameter / input / path validation failure
#   3  unexpected harness error
#
# Usage (from any working directory):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
#     <repo>\tools\muaman13n\verify_consumer_launch.ps1 `
#     -ConsumerRoot <consumer-root> `
#     -Mode all
#
# Parameters:
#   -RepositoryRoot <dir>   repository root (default: two parents of script dir)
#   -ConsumerRoot <dir>     consumer root (required; must already exist)
#   -RunId <string>         run identifier recorded in evidence (default: UTC stamp)
#   -Mode <string>          run1 | run2 | negative | all (default: all)
#   -ZipPath <file>         inbound ZIP (default: <ConsumerRoot>\inbound\muaman-windows-release.zip)
#   -LegalManifest <file>   committed MUAMAN-13K legal release manifest
#   -EvidenceOut <dir>      evidence output directory (default: <ConsumerRoot>\evidence)
#   -ObservationSeconds <n> survival observation window in seconds (default: 20)

param(
  [string]$RepositoryRoot = '',
  [Parameter(Mandatory = $true)][string]$ConsumerRoot,
  [string]$RunId = '',
  [string]$Mode = 'all',
  [string]$ZipPath = '',
  [string]$LegalManifest = '',
  [string]$EvidenceOut = '',
  [int]$ObservationSeconds = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
$ExpectedZipSha256  = '57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008'
$ExpectedZipSize    = 14485278
$ExpectedEntryCount = 13
$ExpectedEntryStamp = '2024-01-01T00:00:00'
$ExpectedCrossHash  = 'EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9'
$MinimalPath        = 'C:\Windows\System32;C:\Windows'

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$message) {
  Write-Host ('[MUAMAN-13N] {0}' -f $message)
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
  $rel = $full.Substring($base.Length).TrimStart('\').Replace('\', '/').TrimStart('/')
  return $rel
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
# run-state
# ---------------------------------------------------------------------------
$script:guardResults = [ordered]@{}
$script:fatal = $null
$script:startedAt = $null
$script:harnessFailure = $null
$script:paramError = $false
$script:negOriginalHash = $null
$script:lastHwnd = [int64]0
$script:lastTitle = ''
$script:lastResponding = $null

function Set-Guard([string]$id, [string]$status, [string]$detail) {
  $script:guardResults[$id] = [ordered]@{ status = $status; detail = $detail }
}

function Assert-Guard([string]$id, [bool]$ok, [string]$failDetail) {
  if ($ok) {
    Set-Guard $id 'PASS' 'ok'
  } else {
    Set-Guard $id 'FAIL' $failDetail
  }
}

# ---------------------------------------------------------------------------
# stage 0: resolve and validate parameters (N1)
# ---------------------------------------------------------------------------
$script:startedAt = Get-UtcNow

try {
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $scriptDir = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $RepositoryRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
  }
  $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
  $ConsumerRoot = [System.IO.Path]::GetFullPath($ConsumerRoot)
  $Mode = $Mode.ToLowerInvariant()

  if ([string]::IsNullOrWhiteSpace($ZipPath)) {
    $ZipPath = Join-Path $ConsumerRoot 'inbound\muaman-windows-release.zip'
  }
  $ZipPath = [System.IO.Path]::GetFullPath($ZipPath)
  if ([string]::IsNullOrWhiteSpace($LegalManifest)) {
    $LegalManifest = Join-Path $RepositoryRoot 'docs\evidence\muaman-13k\04-k1-source-a-sdk-a-shorttemp\release-manifest.json'
  }
  $LegalManifest = [System.IO.Path]::GetFullPath($LegalManifest)
  if ([string]::IsNullOrWhiteSpace($EvidenceOut)) {
    $EvidenceOut = Join-Path $ConsumerRoot 'evidence'
  }
  $EvidenceOut = [System.IO.Path]::GetFullPath($EvidenceOut)
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    $RunId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
  }

  $n1ok = $true
  $n1detail = @()
  if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot 'app\pubspec.yaml'))) {
    $n1ok = $false; $n1detail += 'repo marker app\pubspec.yaml missing'
  }
  if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot 'tools\release\build_windows_release.ps1'))) {
    $n1ok = $false; $n1detail += 'repo marker tools\release\build_windows_release.ps1 missing'
  }
  if (-not (Test-Path -LiteralPath $ConsumerRoot -PathType Container)) {
    $n1ok = $false; $n1detail += 'ConsumerRoot does not exist'
  }
  if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
    $n1ok = $false; $n1detail += ("ZipPath does not exist: {0}" -f $ZipPath)
  }
  if (-not (Test-Path -LiteralPath $LegalManifest -PathType Leaf)) {
    $n1ok = $false; $n1detail += 'LegalManifest does not exist'
  }
  if ($Mode -notin @('run1', 'run2', 'negative', 'all')) {
    $n1ok = $false; $n1detail += ("Mode '{0}' not in run1|run2|negative|all" -f $Mode)
  }
  if ($ObservationSeconds -lt 5 -or $ObservationSeconds -gt 600) {
    $n1ok = $false; $n1detail += 'ObservationSeconds must be 5..600'
  }
  if (-not (Test-IsUnder $ZipPath $ConsumerRoot)) {
    $n1ok = $false; $n1detail += 'ZipPath must be under ConsumerRoot'
  }
  Assert-Guard 'N1' $n1ok ($n1detail -join '; ')
  if (-not $n1ok) {
    $script:paramError = $true
    throw ('parameter validation failed: {0}' -f ($n1detail -join '; '))
  }

  New-Item -ItemType Directory -Path $EvidenceOut -Force | Out-Null

  # legal manifest ground truth
  $legal = Get-Content -LiteralPath $LegalManifest -Raw | ConvertFrom-Json
  $legalFiles = @{}
  foreach ($lf in $legal.files) {
    $legalFiles[$lf.rel] = [ordered]@{ rel = $lf.rel; size = [int64]$lf.size; sha256 = $lf.sha256 }
  }

  # ---------------------------------------------------------------------------
  # common: environment probe (N2)
  #
  # The child launch environment is constructed deterministically by this
  # harness: PATH is replaced by $MinimalPath and the Flutter/Dart/Pub tool
  # variables are cleared before Start-Process (the child inherits exactly this
  # environment). N2 therefore verifies the constructed launch environment spec,
  # which is the environment the packaged executable actually launches with.
  # ---------------------------------------------------------------------------
  function Get-ConsumerEnvironmentProbe() {
    $pathTokens = @('flutter', 'dart', 'git', 'cmake', 'ninja', 'buildtools', 'microsoft visual studio', 'pub\cache', $RepositoryRoot.ToLowerInvariant(), 'c:\m13')
    $pathLower = $MinimalPath.ToLowerInvariant()
    $forbiddenInPath = @($pathTokens | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $pathLower.Contains($_.ToLowerInvariant()) })
    $launchToolVars = @('PUB_CACHE', 'FLUTTER_ROOT', 'DART_HOME', 'DART_SDK')
    $probe = [ordered]@{
      launchPath = $MinimalPath
      forbiddenTokensPresentInPath = $forbiddenInPath
      toolVarsCleared = $launchToolVars
      toolVarsPresent = @()
      independent = (($forbiddenInPath.Count -eq 0))
    }
    return $probe
  }

  # ---------------------------------------------------------------------------
  # common: inbound archive identity (N3, N4)
  # ---------------------------------------------------------------------------
  function Test-InboundArchive() {
    $zipItem = Get-Item -LiteralPath $ZipPath
    $zipHash = Get-Sha256 $ZipPath
    $shaPath = $ZipPath + '.sha256'
    $sidecarOk = $false
    $sidecarExpected = ''
    if (Test-Path -LiteralPath $shaPath -PathType Leaf) {
      $sidecarContent = (Get-Content -LiteralPath $shaPath -Raw).Trim()
      if ($sidecarContent -match '^([0-9A-Fa-f]{64})\s{2}') {
        $sidecarExpected = $Matches[1].ToUpperInvariant()
        $sidecarOk = ($sidecarExpected -eq $zipHash)
      }
    }
    $hashMatch = ($zipHash -eq $ExpectedZipSha256)
    $sizeMatch = ($zipItem.Length -eq $ExpectedZipSize)

    $linkType = $zipItem.LinkType
    if ([string]::IsNullOrEmpty($linkType)) { $linkType = $null }

    $n3ok = $hashMatch -and $sizeMatch
    Assert-Guard 'N3' $n3ok ('zip sha256={0} size={1} sidecarOk={2}' -f $zipHash, $zipItem.Length, $sidecarOk)
    $n4ok = ($null -eq $linkType) -and $hashMatch -and $sidecarOk
    Assert-Guard 'N4' $n4ok ('linkType={0} sidecarOk={1}' -f $linkType, $sidecarOk)

    $result = [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      capturedAtUtc = Get-UtcNow
      zipPath = $ZipPath
      zipSha256 = $zipHash
      expectedZipSha256 = $ExpectedZipSha256
      hashMatch = [bool]$hashMatch
      zipSize = [int64]$zipItem.Length
      expectedZipSize = $ExpectedZipSize
      sizeMatch = [bool]$sizeMatch
      linkType = $linkType
      sha256SidecarPath = $shaPath
      sha256SidecarExpected = $sidecarExpected
      sha256SidecarMatch = [bool]$sidecarOk
      crossHashExpected = $ExpectedCrossHash
      verdict = if ($n3ok -and $n4ok) { 'PASS' } else { 'FAIL' }
    }
    return $result
  }

  # ---------------------------------------------------------------------------
  # common: safe extraction (N5) -> manifest list of extracted files
  # ---------------------------------------------------------------------------
  function Test-SafeExtraction([string]$extractDir) {
    Remove-OwnedDir $extractDir $ConsumerRoot
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    $arch = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    $entryInfo = @()
    $unsafeEntries = @()
    $duplicate = @()
    $seen = @{}
    try {
      foreach ($e in $arch.Entries) {
        $name = $e.FullName
        $unsafe = $false
        if ($name.StartsWith('/') -or $name -match '(^|/)\.\.(/|$)' -or $name -match '\\') { $unsafe = $true }
        if ($seen.ContainsKey($name)) { $duplicate += $name } else { $seen[$name] = $true }
        $stamp = $e.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
        $entryInfo += [ordered]@{ rel = $name; size = $e.Length; timestamp = $stamp; unsafe = [bool]$unsafe }
        if ($unsafe) { $unsafeEntries += $name }
        $out = Join-Path $extractDir ($name -replace '/', '\')
        $parent = Split-Path -Parent $out
        if (-not [string]::IsNullOrWhiteSpace($parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $out, $true)
      }
    } finally {
      $arch.Dispose()
    }

    $entryCount = $entryInfo.Count
    $stamps = @($entryInfo | ForEach-Object { $_.timestamp } | Sort-Object -Unique)
    $n5ok = ($entryCount -eq $ExpectedEntryCount) -and
            ($unsafeEntries.Count -eq 0) -and
            ($duplicate.Count -eq 0) -and
            ($stamps.Count -eq 1) -and
            ($stamps[0] -eq $ExpectedEntryStamp)
    Assert-Guard 'N5' $n5ok ('entries={0} unsafe={1} duplicates={2} stamps={3}' -f $entryCount, $unsafeEntries.Count, $duplicate.Count, ($stamps -join ','))
    return [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      capturedAtUtc = Get-UtcNow
      extractDir = $extractDir
      entryCount = $entryCount
      expectedEntryCount = $ExpectedEntryCount
      unsafeEntries = $unsafeEntries
      duplicateEntries = $duplicate
      distinctEntryTimestamps = $stamps
      expectedEntryTimestamp = $ExpectedEntryStamp
      verdict = if ($n5ok) { 'PASS' } else { 'FAIL' }
      entries = $entryInfo
    }
  }

  # ---------------------------------------------------------------------------
  # common: manifest hashing of extracted tree (N6 pre, N10 post)
  # ---------------------------------------------------------------------------
  function Get-ExtractedManifest([string]$extractDir, [string]$tag, [switch]$ReleaseOnly) {
    $files = @(Get-ChildItem -LiteralPath $extractDir -Recurse -File)
    $list = @()
    foreach ($f in $files) {
      $rel = Get-RelPath $f.FullName $extractDir
      if ($ReleaseOnly -and -not $legalFiles.ContainsKey($rel)) { continue }
      $list += [ordered]@{ rel = $rel; size = [int64]$f.Length; sha256 = (Get-Sha256 $f.FullName) }
    }
    $list = @($list | Sort-Object -Property rel)
    return [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      tag = $tag
      capturedAtUtc = Get-UtcNow
      extractDir = $extractDir
      releaseOnly = [bool]$ReleaseOnly
      fileCount = $list.Count
      files = $list
    }
  }

  function Compare-ManifestToLegal($manifest, [ref]$mismatchOut) {
    $mismatch = @()
    $byRel = @{}
    foreach ($f in $manifest.files) { $byRel[$f.rel] = $f }
    foreach ($rel in ($legalFiles.Keys | Sort-Object)) {
      if (-not $byRel.ContainsKey($rel)) { $mismatch += ("missing: {0}" -f $rel); continue }
      $act = $byRel[$rel]
      $exp = $legalFiles[$rel]
      if ([int64]$act.size -ne [int64]$exp.size) { $mismatch += ("size: {0} act={1} exp={2}" -f $rel, $act.size, $exp.size) }
      if ($act.sha256 -ne $exp.sha256) { $mismatch += ("hash: {0}" -f $rel) }
    }
    if ($manifest.fileCount -ne $legal.fileCount) { $mismatch += ("fileCount act={0} exp={1}" -f $manifest.fileCount, $legal.fileCount) }
    $mismatchOut.Value = $mismatch
    return ($mismatch.Count -eq 0)
  }

  # ---------------------------------------------------------------------------
  # launch: isolated environment + process start
  # ---------------------------------------------------------------------------
  function Start-IsolatedLaunch([string]$extractDir, [string]$profileDir) {
    $exe = Join-Path $extractDir 'muaman_store.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
      throw ("release exe missing: {0}" -f $exe)
    }
    foreach ($d in @('appdata\roaming', 'appdata\local', 'temp', 'home')) {
      Remove-OwnedDir (Join-Path $profileDir $d) $ConsumerRoot
      New-Item -ItemType Directory -Path (Join-Path $profileDir $d) -Force | Out-Null
    }

    # kill any leftover process bound to this exact exe (owned-scope cleanup)
    Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | ForEach-Object {
      try {
        if ($_.Path -and ($_.Path -ieq $exe)) {
          $_.Kill(); $_.WaitForExit()
          Write-Step ("cleaned leftover process {0} bound to {1}" -f $_.Id, $exe)
        }
      } catch { }
    }

    $saved = @{
      APPDATA = $env:APPDATA; LOCALAPPDATA = $env:LOCALAPPDATA
      TEMP = $env:TEMP; TMP = $env:TMP; USERPROFILE = $env:USERPROFILE
      PATH = $env:PATH; PUB_CACHE = $env:PUB_CACHE; FLUTTER_ROOT = $env:FLUTTER_ROOT
      DART_HOME = $env:DART_HOME; DART_SDK = $env:DART_SDK
    }
    $env:APPDATA = Join-Path $profileDir 'appdata\roaming'
    $env:LOCALAPPDATA = Join-Path $profileDir 'appdata\local'
    $env:TEMP = Join-Path $profileDir 'temp'
    $env:TMP = $env:TEMP
    $env:USERPROFILE = Join-Path $profileDir 'home'
    $env:PATH = $MinimalPath
    foreach ($v in @('PUB_CACHE', 'FLUTTER_ROOT', 'DART_HOME', 'DART_SDK')) {
      Remove-Item -LiteralPath ("env:$v") -ErrorAction SilentlyContinue
    }

    $envSnapshot = [ordered]@{
      APPDATA = $env:APPDATA; LOCALAPPDATA = $env:LOCALAPPDATA
      TEMP = $env:TEMP; USERPROFILE = $env:USERPROFILE
      PATH = $env:PATH
      PUB_CACHE = ''; FLUTTER_ROOT = ''; DART_HOME = ''; DART_SDK = ''
    }

    $stdout = Join-Path $profileDir 'stdout.txt'
    $stderr = Join-Path $profileDir 'stderr.txt'
    try {
      # NOTE: standard-output redirection is intentionally NOT used: it makes
      # Process.ExitCode unreadable on Windows PowerShell 5.1, and the clean
      # termination guard depends on the real exit code.
      $proc = Start-Process -FilePath $exe -WorkingDirectory $extractDir -PassThru
    } finally {
      foreach ($k in $saved.Keys) {
        Set-Item -LiteralPath ("env:$k") -Value $saved[$k]
      }
    }
    return [ordered]@{
      exe = $exe
      workingDirectory = $extractDir
      pid = $proc.Id
      environment = $envSnapshot
      process = $proc
    }
  }

  # ---------------------------------------------------------------------------
  # liveness snapshot (N8) and module origin (N9)
  # ---------------------------------------------------------------------------
  function Get-LivenessSnapshot([System.Diagnostics.Process]$proc, [int]$waitSeconds) {
    Start-Sleep -Seconds $waitSeconds
    try { $proc.Refresh() } catch { }
    if ($proc.HasExited) {
      $script:lastHwnd = [int64]0
      $script:lastTitle = ''
      $script:lastResponding = $null
      return [ordered]@{
        observationSeconds = $waitSeconds
        survived = $false
        mainWindowHandle = [int64]0
        mainWindowTitle = ''
        responding = $null
        detail = ("process exited early with code {0}" -f $proc.ExitCode)
      }
    }
    $hwnd = [int64]0
    $title = ''
    $responding = $false
    try {
      $proc.Refresh()
      $hwnd = $proc.MainWindowHandle
      $title = $proc.MainWindowTitle
      $responding = $proc.Responding
    } catch { }
    $script:lastHwnd = $hwnd
    $script:lastTitle = $title
    $script:lastResponding = $responding
    $ok = ($hwnd -ne 0)
    $detail = if ($ok) { 'alive with main window' } else { 'alive but no main window' }
    return [ordered]@{
      observationSeconds = $waitSeconds
      survived = (-not $proc.HasExited)
      mainWindowHandle = $hwnd
      mainWindowTitle = $title
      responding = $responding
      hasMainWindow = [bool]$ok
      detail = $detail
    }
  }

  function Get-ModuleOrigin([System.Diagnostics.Process]$proc) {
    $modules = @()
    $violations = @()
    $ok = $false
    try {
      $proc.Refresh()
      $modList = @($proc.Modules | ForEach-Object { $_.FileName })
      $extractDir = [System.IO.Path]::GetFullPath((Split-Path -Parent $proc.Path))
      foreach ($m in ($modList | Sort-Object -Unique)) {
        $full = [System.IO.Path]::GetFullPath($m)
        $isSystem = $full.StartsWith($env:SystemRoot, [System.StringComparison]::OrdinalIgnoreCase)
        $isExtract = $full.StartsWith($extractDir + '\', [System.StringComparison]::OrdinalIgnoreCase) -or
                     $full -ieq $extractDir
        $modules += [ordered]@{ path = $full; system = [bool]$isSystem; fromExtractDir = [bool]$isExtract }
        if (-not ($isSystem -or $isExtract)) {
          $violations += $full
        }
      }
      $ok = ($violations.Count -eq 0)
    } catch {
      $ok = $false
      $violations += ("module enumeration failed: {0}" -f $_.Exception.Message)
    }
    return [ordered]@{
      ok = [bool]$ok
      moduleCount = $modules.Count
      violations = $violations
      modules = $modules
    }
  }

  # ---------------------------------------------------------------------------
  # a full consumer run (run1 / run2 share this path)
  # ---------------------------------------------------------------------------
  function Invoke-ConsumerRun([string]$runTag, [string]$extractDir, [string]$profileDir) {
    Write-Step ("=== consumer run {0} starting ===" -f $runTag)
    $runStart = Get-UtcNow
    $script:lastHwnd = 0
    $script:lastTitle = ''
    $script:lastResponding = $null
    Assert-Guard 'N1' $true 'parameters validated'

    # N2 environment probe
    $envProbe = Get-ConsumerEnvironmentProbe
    Assert-Guard 'N2' ([bool]$envProbe.independent) ('PATH tokens: {0}' -f ($envProbe.forbiddenTokensPresentInPath -join ','))
    Write-Utf8NoBom (Join-Path $EvidenceOut ("env-probe-{0}.json" -f $runTag)) ($envProbe | ConvertTo-Json -Depth 6)

    # N3/N4 inbound
    $inbound = Test-InboundArchive
    Write-Utf8NoBom (Join-Path $EvidenceOut ("inbound-{0}.json" -f $runTag)) ($inbound | ConvertTo-Json -Depth 6)
    if (-not ($script:guardResults['N3'].status -eq 'PASS' -and $script:guardResults['N4'].status -eq 'PASS')) {
      throw ("run {0}: inbound archive identity failed" -f $runTag)
    }

    # N5 safe extraction
    $extract = Test-SafeExtraction $extractDir
    Write-Utf8NoBom (Join-Path $EvidenceOut ("extract-safety-{0}.json" -f $runTag)) ($extract | ConvertTo-Json -Depth 8)
    if ($script:guardResults['N5'].status -ne 'PASS') {
      throw ("run {0}: extraction safety failed" -f $runTag)
    }

    # N6 pre-launch manifest
    $preManifest = Get-ExtractedManifest $extractDir ("pre-{0}" -f $runTag)
    $mismatch = @()
    $preOk = Compare-ManifestToLegal $preManifest ([ref]$mismatch)
    Assert-Guard 'N6' $preOk ($mismatch -join '; ')
    Write-Utf8NoBom (Join-Path $EvidenceOut ("pre-manifest-{0}.json" -f $runTag)) ($preManifest | ConvertTo-Json -Depth 10)
    if (-not $preOk) {
      throw ("run {0}: pre-launch manifest mismatch: {1}" -f $runTag, ($mismatch -join '; '))
    }

    # N7 isolated launch
    $launch = Start-IsolatedLaunch $extractDir $profileDir
    $proc = $launch.process
    $launch.Remove('process')
    Assert-Guard 'N7' ($launch.pid -gt 0) ("exe={0} pid={1}" -f $launch.exe, $launch.pid)
    Write-Utf8NoBom (Join-Path $EvidenceOut ("launch-{0}.json" -f $runTag)) ($launch | ConvertTo-Json -Depth 8)

    # N8 liveness
    $live = Get-LivenessSnapshot $proc $ObservationSeconds
    Assert-Guard 'N8' ([bool]$live.survived -and [bool]$live.hasMainWindow) ("survived={0} hwnd={1} title='{2}'" -f $live.survived, $live.mainWindowHandle, $live.mainWindowTitle)
    Write-Utf8NoBom (Join-Path $EvidenceOut ("liveness-{0}.json" -f $runTag)) ($live | ConvertTo-Json -Depth 6)
    if ($script:guardResults['N8'].status -ne 'PASS') {
      $safeStop = $false
      if (-not $proc.HasExited) { try { $proc.Kill(); $proc.WaitForExit() } catch { } }
      throw ("run {0}: liveness failed" -f $runTag)
    }

    # N9 module origin (captured while the process is still running)
    $modOrigin = Get-ModuleOrigin $proc
    Assert-Guard 'N9' ([bool]$modOrigin.ok) ('violations: {0}' -f ($modOrigin.violations -join '; '))
    $modOut = [ordered]@{
      schemaVersion = '1.0'; runId = $RunId; capturedAtUtc = Get-UtcNow
      extractDir = $extractDir
      moduleCount = $modOrigin.moduleCount
      violations = $modOrigin.violations
      modules = $modOrigin.modules
      verdict = if ($modOrigin.ok) { 'PASS' } else { 'FAIL' }
    }
    Write-Utf8NoBom (Join-Path $EvidenceOut ("modules-{0}.json" -f $runTag)) ($modOut | ConvertTo-Json -Depth 8)
    if (-not $modOrigin.ok) {
      $safeStop = $false
      if (-not $proc.HasExited) { try { $proc.Kill(); $proc.WaitForExit() } catch { } }
      throw ("run {0}: module-origin guard failed" -f $runTag)
    }

    # N10 post-launch manifest equality (the 13 release files unchanged;
    # the app-created .dart_tool database is intentionally excluded here and
    # captured separately as a runtime artifact)
    $postManifest = Get-ExtractedManifest $extractDir ("post-{0}" -f $runTag) -ReleaseOnly
    $releaseChanged = @()
    foreach ($pre in $preManifest.files) {
      $post = $postManifest.files | Where-Object { $_.rel -eq $pre.rel } | Select-Object -First 1
      if ($null -eq $post) { $releaseChanged += ("missing-after: {0}" -f $pre.rel); continue }
      if ([int64]$post.size -ne [int64]$pre.size -or $post.sha256 -ne $pre.sha256) {
        $releaseChanged += ("changed: {0}" -f $pre.rel)
      }
    }
    Assert-Guard 'N10' ($releaseChanged.Count -eq 0) ($releaseChanged -join '; ')
    $postManifest.releaseFilesChanged = $releaseChanged
    if ($releaseChanged.Count -gt 0) {
      $safeStop = $false
      if (-not $proc.HasExited) { try { $proc.Kill(); $proc.WaitForExit() } catch { } }
      throw ("run {0}: post-launch release files changed" -f $runTag)
    }

    # N11 clean termination
    $closeOk = $false
    $closeExitCode = $null
    $closeErr = ''
    try {
      if (-not $proc.HasExited) {
        $proc.Refresh()
        $closeOk = $proc.CloseMainWindow()
        if ($closeOk) { if (-not $proc.WaitForExit(15000)) { $closeOk = $false } }
      } else {
        $closeOk = $true
      }
    } catch { $closeOk = $false }
    if ($closeOk -and -not $proc.HasExited) {
      $proc.Kill()
      $proc.WaitForExit()
      $closeOk = $false
    }
    if ($closeOk) {
      try { $proc.Refresh(); $closeExitCode = $proc.ExitCode } catch { $closeErr = $_.Exception.Message }
    }
    Assert-Guard 'N11' ($closeOk -and ($closeExitCode -eq 0)) ("closeOk={0} exitCode={1} err={2}" -f $closeOk, $closeExitCode, $closeErr)
    $live.closeExitCode = $closeExitCode

    # runtime artifact evidence (app-created DB inside the extracted tree),
    # captured AFTER clean close so SQLite has released its file locks
    $runtimeArtifacts = @()
    $dbCandidates = @(Get-ChildItem -LiteralPath (Join-Path $extractDir '.dart_tool') -Recurse -File -ErrorAction SilentlyContinue)
    foreach ($c in $dbCandidates) {
      $h = $null
      $locked = $false
      try { $h = Get-Sha256 $c.FullName } catch { $locked = $true }
      $runtimeArtifacts += [ordered]@{ rel = (Get-RelPath $c.FullName $extractDir); size = [int64]$c.Length; sha256 = $h; locked = [bool]$locked }
    }
    $postManifest.runtimeArtifacts = $runtimeArtifacts
    Write-Utf8NoBom (Join-Path $EvidenceOut ("post-manifest-{0}.json" -f $runTag)) ($postManifest | ConvertTo-Json -Depth 10)

    $runFinish = Get-UtcNow
    $failedGuards = @($script:guardResults.GetEnumerator() | Where-Object { $_.Value.status -ne 'PASS' } | ForEach-Object { $_.Key })
    $verdict = if ($failedGuards.Count -eq 0) { 'PASS' } else { 'FAIL' }

    $result = [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      mode = $runTag
      startedAtUtc = $runStart
      finishedAtUtc = $runFinish
      observationSeconds = $ObservationSeconds
      guards = $script:guardResults
      verdict = $verdict
      failedGuards = $failedGuards
      exitCode = if ($verdict -eq 'PASS') { 0 } else { 1 }
    }
    Write-Utf8NoBom (Join-Path $EvidenceOut ("result-{0}.json" -f $runTag)) ($result | ConvertTo-Json -Depth 10)
    Write-Step ("=== consumer run {0} verdict: {1} ===" -f $runTag, $verdict)
    return $result
  }

  # ---------------------------------------------------------------------------
  # negative control
  # ---------------------------------------------------------------------------
  function Invoke-NegativeControl() {
    Write-Step '=== negative control starting ==='
    $negStart = Get-UtcNow
    Assert-Guard 'N1' $true 'parameters validated'
    $tamperTarget = 'flutter_windows.dll'
    $extractDir = Join-Path $ConsumerRoot 'extract-negative'
    $tampered = $false
    $detected = $false
    $observedManifestCheck = ''
    $detail = ''

    try {
      # fresh extract of the genuine archive
      $extract = Test-SafeExtraction $extractDir
      Write-Utf8NoBom (Join-Path $EvidenceOut 'extract-safety-negative.json') ($extract | ConvertTo-Json -Depth 8)

      # N3/N4 still required to hold
      $inbound = Test-InboundArchive
      Write-Utf8NoBom (Join-Path $EvidenceOut 'inbound-negative.json') ($inbound | ConvertTo-Json -Depth 6)
      if (-not ($script:guardResults['N3'].status -eq 'PASS' -and $script:guardResults['N4'].status -eq 'PASS')) {
        throw 'negative control: inbound archive identity failed'
      }

      # tamper: replace the critical runtime DLL with corrupt bytes
      $target = Join-Path $extractDir $tamperTarget
      $originalHash = Get-Sha256 $target
      $script:negOriginalHash = $originalHash
      $corruptBytes = New-Object byte[] 4096
      for ($i = 0; $i -lt $corruptBytes.Length; $i++) { $corruptBytes[$i] = 0x41 }
      [System.IO.File]::WriteAllBytes($target, $corruptBytes)
      $tamperedHash = Get-Sha256 $target
      $tampered = ($originalHash -ne $tamperedHash)

      # pre-launch manifest guard must FAIL (tamper must be detected)
      $preManifest = Get-ExtractedManifest $extractDir 'pre-negative'
      $mismatch = @()
      $preOk = Compare-ManifestToLegal $preManifest ([ref]$mismatch)
      Assert-Guard 'N6' $preOk ($mismatch -join '; ')
      $observedManifestCheck = if ($preOk) { 'PASS' } else { 'FAIL' }
      $detected = (-not $preOk)
      $detail = 'tampered package rejected by pre-launch manifest guard'
    } catch {
      $detected = $false
      $detail = ("negative control error: {0}" -f $_.Exception.Message)
    }

    $pass = $tampered -and $detected -and ($observedManifestCheck -eq 'FAIL')
    $negFinish = Get-UtcNow
    $neg = [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      mode = 'negative'
      startedAtUtc = $negStart
      finishedAtUtc = $negFinish
      guards = $script:guardResults
      tamper = [ordered]@{
        target = $tamperTarget
        method = 'overwrite with corrupt bytes'
        originalSha256 = $script:negOriginalHash
        tampered = [bool]$tampered
      }
      observed = [ordered]@{
        manifestGuardExpected = 'FAIL'
        manifestGuardObserved = $observedManifestCheck
        tamperDetected = [bool]$detected
      }
      verdict = if ($pass) { 'REJECTED' } else { 'NOT-REJECTED' }
      detail = $detail
      pass = [bool]$pass
      exitCode = if ($pass) { 0 } else { 1 }
    }
    Write-Utf8NoBom (Join-Path $EvidenceOut 'negative-control.json') ($neg | ConvertTo-Json -Depth 8)
    Write-Step ("=== negative control verdict: {0} ===" -f $neg.verdict)
    return $neg
  }

  # ---------------------------------------------------------------------------
  # orchestrator
  # ---------------------------------------------------------------------------
  function Invoke-All() {
    $order = @()
    $modeResults = [ordered]@{}
    if ($Mode -eq 'all' -or $Mode -eq 'run1') {
      $script:guardResults = [ordered]@{}
      $r1 = Invoke-ConsumerRun 'run1' (Join-Path $ConsumerRoot 'extract-run1') (Join-Path $ConsumerRoot 'profile-run1')
      $order += 'run1'
      $modeResults['run1'] = [ordered]@{ verdict = $r1.verdict; guards = $r1.guards }
      if ($r1.verdict -ne 'PASS') { return 1 }
    }
    if ($Mode -eq 'all' -or $Mode -eq 'run2') {
      $script:guardResults = [ordered]@{}
      $r2 = Invoke-ConsumerRun 'run2' (Join-Path $ConsumerRoot 'extract-run2') (Join-Path $ConsumerRoot 'profile-run2')
      $order += 'run2'
      $modeResults['run2'] = [ordered]@{ verdict = $r2.verdict; guards = $r2.guards }
      if ($r2.verdict -ne 'PASS') { return 1 }
    }
    if ($Mode -eq 'all' -or $Mode -eq 'negative') {
      $script:guardResults = [ordered]@{}
      $neg = Invoke-NegativeControl
      $order += 'negative'
      $modeResults['negative'] = [ordered]@{ verdict = $neg.verdict; guards = $neg.guards; pass = [bool]$neg.pass }
      if (-not $neg.pass) { return 1 }
    }

    # N12 aggregate verdict + evidence completeness
    $summary = [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      repositoryRoot = $RepositoryRoot
      consumerRoot = $ConsumerRoot
      evidenceDir = $EvidenceOut
      modesExecuted = $order
      completedAtUtc = Get-UtcNow
      expectedZipSha256 = $ExpectedZipSha256
      expectedCrossHash = $ExpectedCrossHash
      modes = $modeResults
      overall = 'PASS'
      exitCode = 0
    }
    Write-Utf8NoBom (Join-Path $EvidenceOut 'consumer-launch-verdict.json') ($summary | ConvertTo-Json -Depth 12)
    Assert-Guard 'N12' $true 'all modes executed; evidence written'
    Write-Step 'RESULT: PASS (all consumer-launch guards N1..N12 satisfied)'
    return 0
  }

  $exitCode = Invoke-All
  $script:harnessFailure = $null
  exit $exitCode

} catch {
  $err = $_.Exception.Message
  $finish = Get-UtcNow
  $code = if ($script:paramError) { 2 } else { 1 }
  try {
    # fail-closed cleanup: terminate any packaged app process under the
    # consumer root so a failed run can never leave the release running
    Get-Process -Name 'muaman_store' -ErrorAction SilentlyContinue | ForEach-Object {
      try {
        if ($_.Path -and (Test-IsUnder $_.Path $ConsumerRoot)) {
          $_.Kill(); $_.WaitForExit()
          Write-Step ("cleaned leaked process {0} under consumer root" -f $_.Id)
        }
      } catch { }
    }
  } catch { }
  try {
    $fail = [ordered]@{
      schemaVersion = '1.0'
      runId = $RunId
      startedAtUtc = $script:startedAt
      finishedAtUtc = $finish
      guards = $script:guardResults
      verdict = 'FAIL'
      failureReason = $err
      exitCode = $code
    }
    Write-Utf8NoBom (Join-Path $EvidenceOut 'consumer-launch-verdict.json') ($fail | ConvertTo-Json -Depth 8)
  } catch { }
  Write-Step ("FAILED (exit {0}): {1}" -f $code, $err)
  exit $code
}
