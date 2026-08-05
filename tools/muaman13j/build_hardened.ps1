# MUAMAN-13J hardened build wrapper.
# Neutralizes the rare MSBuild FileTracker empty-static crash (MSB4018
# IndexOutOfRangeException in FileTracker.FileIsUnderNormalizedPath) by making
# the FileTracker-relevant process environment deterministic and verified:
#
#   1. Harden the environment: TEMP/TMP, APPDATA, LOCALAPPDATA, USERPROFILE,
#      HOME and PROGRAMDATA all point at existing, resolvable roots; PUB_CACHE
#      is set; MSBUILDDISABLENODEREUSE=1 forces fresh MSBuild node processes so
#      no stale node with a different environment block can be reused.
#   2. Preflight (fresh process): load Microsoft.Build.Utilities.Core and assert
#      every FileTracker exclusion-path static resolves to a non-empty string.
#      Fail fast with diagnostics if not.
#   3. Build: delegate to the 13I isolated runner (same evidence format) under
#      the hardened environment.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File build_hardened.ps1 ^
#       -ExperimentId H1 -AppRoot <app> -SdkRoot <sdk> -PubCache <pub> ^
#       -TmpRoot <tmp> -HomeRoot <home> -EvidenceDir <dir>

param(
  [Parameter(Mandatory=$true)][string]$ExperimentId,
  [Parameter(Mandatory=$true)][string]$AppRoot,
  [Parameter(Mandatory=$true)][string]$SdkRoot,
  [Parameter(Mandatory=$true)][string]$PubCache,
  [Parameter(Mandatory=$true)][string]$TmpRoot,
  [Parameter(Mandatory=$true)][string]$HomeRoot,
  [Parameter(Mandatory=$true)][string]$EvidenceDir,
  [string]$MsBuildBinDir = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64'
)
$ErrorActionPreference = 'Stop'

$EvidenceDir = [System.IO.Path]::GetFullPath($EvidenceDir)
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

foreach ($r in @($AppRoot, $SdkRoot, $PubCache)) {
  if (-not (Test-Path -LiteralPath $r)) { Write-Error ("Required root does not exist: {0}" -f $r); exit 1 }
}

# ---------- 1. harden environment ----------
# The temp root is short by design (13I guidance) and created before any
# flutter/dart process starts; app-data/profile roots are created too so every
# FileTracker producer resolves to an existing path.
New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null
New-Item -ItemType Directory -Path $HomeRoot -Force | Out-Null
$roaming = Join-Path $HomeRoot 'appdata\roaming'
$local   = Join-Path $HomeRoot 'appdata\local'
New-Item -ItemType Directory -Path $roaming -Force | Out-Null
New-Item -ItemType Directory -Path $local   -Force | Out-Null

$env:PUB_CACHE = $PubCache
$env:TEMP = $TmpRoot
$env:TMP  = $TmpRoot
$env:HOME = $HomeRoot
$env:USERPROFILE = $HomeRoot
$env:APPDATA = $roaming
$env:LOCALAPPDATA = $local
$env:NUGET_PACKAGES = Join-Path $local 'NuGet\packages'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:MSBUILDDISABLENODEREUSE = '1'
if ([string]::IsNullOrEmpty($env:PROGRAMDATA)) { $env:PROGRAMDATA = 'C:\ProgramData' }
$env:PATH = (Join-Path $SdkRoot 'bin') + ';' + $env:PATH

$hardenedJson = Join-Path $EvidenceDir '00-hardened-env.json'
[ordered]@{
  experimentId = $ExperimentId
  capturedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  hardening = [ordered]@{
    temp = $env:TEMP; tmp = $env:TMP
    appdata = $env:APPDATA; localappdata = $env:LOCALAPPDATA
    userprofile = $env:USERPROFILE; home = $env:HOME
    programdata = $env:PROGRAMDATA
    pubCache = $env:PUB_CACHE
    msbuildDisableNodeReuse = $env:MSBUILDDISABLENODEREUSE
  }
} | ConvertTo-Json | Set-Content -LiteralPath $hardenedJson -Encoding UTF8

# ---------- 2. preflight (fresh process) ----------
$preflightScript = Join-Path $PSScriptRoot 'check_filetracker_state.ps1'
$preflightLog = Join-Path $EvidenceDir '01-preflight.log'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflightScript -MsBuildBinDir $MsBuildBinDir *> $preflightLog
$preflightExit = $LASTEXITCODE
if ($preflightExit -ne 0) {
  Write-Host ("PREFLIGHT FAILED (exit {0}): a FileTracker static resolves to empty under the hardened env; see {1}" -f $preflightExit, $preflightLog)
  exit $preflightExit
}
Write-Host ('MUAMAN-13J {0}: preflight OK (FileTracker statics non-empty)' -f $ExperimentId)

# ---------- 3. build (delegated to 13I runner, inherits hardened env) ----------
$runner = Join-Path $PSScriptRoot '..\muaman13i\run_experiment.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner `
  -ExperimentId $ExperimentId -AppRoot $AppRoot -SdkRoot $SdkRoot `
  -PubCache $PubCache -TmpRoot $TmpRoot -HomeRoot $HomeRoot `
  -EvidenceDir $EvidenceDir
$buildExit = $LASTEXITCODE
Write-Host ("MUAMAN-13J {0}: build exit={1}" -f $ExperimentId, $buildExit)
exit $buildExit
