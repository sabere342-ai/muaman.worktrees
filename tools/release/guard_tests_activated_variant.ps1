# Activated Release Variant — guard harness (INERT, deterministic).
#
# SESSION      = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_AND_TOOLING
# DRAIN_STATE  = GATED/OFF
#
# Proves the fail-closed matrix of resolve_release_variant.ps1 using LOCAL test doubles
# only. It:
#   - invokes the resolver with each row of the fail-closed matrix;
#   - asserts every non-fully-authorized row resolves to activationAuthorized=NO;
#   - asserts the ordinary/default build (no inputs) is NORMAL_GATED_OFF;
#   - asserts the capability-only build (SYNC_DRAIN_ENABLED=true) is CAPABLE_NOT_AUTHORIZED;
#   - asserts the fully-authorized row produces ACTIVATED (classifier token only; the
#     resolver does not build); then verifies that a matching evidence bundle passes
#     verify_activated_release.ps1 only for an exactly-matching approved commit, and is
#     REFUSED (stale) for a different commit.
#
# This harness cannot contact production and cannot produce a drain-capable artifact: it
# only runs the classifiers against JSON evidence in the temp directory.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File guard_tests_activated_variant.ps1 `
#       -RepoRoot <dir> -Out <json> [-TempRoot <dir>]

param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$TempRoot = ''
)
$ErrorActionPreference = 'Stop'

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Out = [System.IO.Path]::GetFullPath($Out)
if ([string]::IsNullOrWhiteSpace($TempRoot)) { $TempRoot = $env:TEMP }
$TempRoot = [System.IO.Path]::GetFullPath($TempRoot)
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$resolver = Join-Path $RepoRoot 'tools\release\resolve_release_variant.ps1'
$verifier = Join-Path $RepoRoot 'tools\release\verify_activated_release.ps1'
$approvedCommit = '3581f02fced55e0f2a5f437eaed1cfdee1bd9e9b'

function Invoke-Resolver {
  param([string]$OutPath, [string]$VariantId = '', [string]$Approval = '', [string]$Env = '', [bool]$Seam = $false, [bool]$OptIn = $false)
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$resolver,
    '-Out',$OutPath)
  if ($VariantId -ne '') { $args += @('-VariantId', $VariantId) }
  if ($Approval -ne '') { $args += @('-ApprovalDigest', $Approval) }
  if ($Env -ne '') { $args += @('-Environment', $Env) }
  $args += @('-DartDefineSyncDrainEnabled', $(if ($Seam) { 'true' } else { 'false' }))
  $args += @('-OptInActivation', $(if ($OptIn) { 'true' } else { 'false' }))
  & powershell.exe @args | Out-Null
  return $LASTEXITCODE
}

$verdicts = [ordered]@{}
$passCount = 0
$failCount = 0

function Add-Verdict {
  param([string]$name, [bool]$pass, [string]$detail)
  if ($pass) { $script:passCount++ } else { $script:failCount++ }
  $script:verdicts[$name] = [ordered]@{ guard = $name; pass = $pass; detail = $detail }
}

# ---- G1 ordinary/default build (no inputs) -> NORMAL_GATED_OFF, not authorized ----
$resOut = Join-Path $TempRoot 'g1-ordinary.json'
Invoke-Resolver -OutPath $resOut
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G1 ordinary build defaults OFF' (($r.classification -eq 'NORMAL_GATED_OFF') -and -not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G2 capability-only (SYNC_DRAIN_ENABLED=true, nothing else) -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g2-capability.json'
Invoke-Resolver -OutPath $resOut -Seam $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G2 capability-only is NOT authorized' (($r.classification -eq 'CAPABLE_NOT_AUTHORIZED') -and -not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G3 variant id only (no approval) -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g3-variant-only.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Seam $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G3 variant-only is NOT authorized' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G4 wrong variant id -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g4-wrong-variant.json'
Invoke-Resolver -OutPath $resOut -VariantId 'SOME_OTHER_VARIANT' -Approval 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G4 wrong variant is NOT authorized' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G5 malformed/absent approval digest -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g5-bad-approval.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Approval 'not-a-valid-digest' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G5 malformed approval is NOT authorized' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G6 unauthorized (debug/local) environment -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g6-unauthorized-env.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Approval 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855' -Env 'local' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G6 unauthorized environment is NOT authorized' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G7 opt-in not set -> NOT authorized ----
$resOut = Join-Path $TempRoot 'g7-no-optin.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Approval 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855' -Env 'production' -Seam $true -OptIn $false
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G7 missing opt-in is NOT authorized' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G8 fully-authorized -> ACTIVATED (classifier token only) ----
$resOut = Join-Path $TempRoot 'g8-authorized.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Approval 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G8 fully-authorized resolves to ACTIVATED classifier token' (($r.classification -eq 'ACTIVATED') -and $r.activationAuthorized -and $r.drainCapable) "classification=$($r.classification)"

# ---- G9 provenance verifier: matching commit passes ----
$ev = Join-Path $TempRoot 'evidence-authorized.json'
@{
  variantId = 'ACTIVATED_VARIANT_1'
  approvalDigestSha256 = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  environment = 'production'
  releaseVariantFingerprint = 'FINGERPRINT_TEST'
} | ConvertTo-Json | Set-Content -LiteralPath $ev -Encoding UTF8
$vOut = Join-Path $TempRoot 'v-ok.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $ev -ApprovedCommit $approvedCommit -Out $vOut | Out-Null
$vExit = $LASTEXITCODE
$v = Get-Content -LiteralPath $vOut -Raw | ConvertFrom-Json
Add-Verdict 'G9 provenance verifier accepts matching commit' (($vExit -eq 0) -and $v.activated) "exit=$vExit"

# ---- G10 provenance verifier REFUSES stale (mismatched) commit ----
$vOut2 = Join-Path $TempRoot 'v-stale.json'
$staleCommit = '0000000000000000000000000000000000000000'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $ev -ApprovedCommit $staleCommit -Out $vOut2 | Out-Null
$vExit2 = $LASTEXITCODE
$v2 = Get-Content -LiteralPath $vOut2 -Raw | ConvertFrom-Json
Add-Verdict 'G10 provenance verifier REFUSES stale commit' (($vExit2 -ne 0) -and (-not $v2.activated)) "exit=$vExit2 activated=$($v2.activated)"

$allPass = ($failCount -eq 0)
$result = [ordered]@{
  phase          = 'Activated Release Variant governance guard harness'
  capturedAtUtc  = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  allPass        = $allPass
  passCount      = $passCount
  failCount      = $failCount
  note           = 'Inert local classifiers only; no production contact; no drain-capable artifact produced.'
  verdicts       = $verdicts
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Out -Encoding UTF8
Write-Output ("MODEL guard_tests_activated_variant: allPass={0} pass={1} fail={2}" -f $allPass, $passCount, $failCount)
if (-not $allPass) { exit 1 }
exit 0
