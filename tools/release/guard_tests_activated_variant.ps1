# Activated Release Variant — guard harness (INERT, deterministic).
#
# SESSION      = GROUP_A_PHASE_P_OD7_OWNER_ACTIVATION_DECISION (authorization preparation)
# DRAIN_STATE  = GATED/OFF
#
# Proves the fail-closed matrix of resolve_release_variant.ps1 using LOCAL test doubles
# only. This harness:
#   - invokes the resolver with each row of the fail-closed matrix;
#   - asserts every non-fully-authorized row resolves to activationAuthorized=NO;
#   - asserts the ordinary/default build (no inputs) is NORMAL_GATED_OFF;
#   - asserts the capability-only build (SYNC_DRAIN_ENABLED=true) is CAPABLE_NOT_AUTHORIZED;
#   - proves that owner authorization active alone (without the complete authorization
#     surface) does NOT activate;
#   - proves that authorizedApprovalDigest being set alone does NOT activate;
#   - proves that arbitrary/placeholder fingerprints are refused;
#   - proves that stale source commits are refused;
#   - proves that the canonical fingerprint is correctly recomputed;
#   - proves that the one fully valid positive path (full authorization surface, real
#     owner-authorized contract state) resolves ACTIVATED — CLASSIFICATION ONLY, and does
#     not authorize build, ship, deploy, drain execution, or production contact.
#
# PRODUCTION CONTRACT tests: with ownerAuthorizationActive=true and the authorized
#                             approval digest recorded, owner authorization alone !=
#                             activation. Activation requires the complete positive
#                             authorization surface simultaneously.
#
# This harness cannot contact production and cannot produce a drain-capable artifact.

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

# Real authorized source baseline locked by the owner authorization for ACTIVATED_VARIANT_1.
$approvedCommit = '56526f39565c64531b4f1dfef22d060506d56479'

$EMPTY_CONTENT_SHA256 = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'

# The approval identity digest recorded in the committed contract. The harness recomputes
# the positive-path fixture's identity digest and PROVES it equals the committed value,
# so the positive-path proof exercises the real owner-authorized contract state.
$COMMITTED_AUTHORIZED_APPROVAL_DIGEST = '64E3123C9B809B1C6B63EB737003AE61FD4557693888BD74C3BD7EEDC5310D59'

# The canonical fingerprint of the real owner-authorized approval identity.
$REAL_APPROVAL_FINGERPRINT = '0A32E14E853016E8D065BC7CADD6353D04E78A178A18B65C1B1CBA450C6BEDBA'

function Invoke-Resolver {
  param([string]$OutPath, [string]$VariantId = '', [string]$ApprovalFile = '', [string]$Env = '', [bool]$Seam = $false, [bool]$OptIn = $false)
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$resolver,
    '-Out',$OutPath)
  if ($VariantId -ne '') { $args += @('-VariantId', $VariantId) }
  if ($ApprovalFile -ne '') { $args += @('-ApprovalFile', $ApprovalFile) }
  if ($Env -ne '') { $args += @('-Environment', $Env) }
  $args += @('-DartDefineSyncDrainEnabled', $(if ($Seam) { 'true' } else { 'false' }))
  $args += @('-OptInActivation', $(if ($OptIn) { 'true' } else { 'false' }))
  & powershell.exe @args | Out-Null
  return $LASTEXITCODE
}

function Compute-FileHash256 {
  param([string]$FilePath)
  $bytes = [System.IO.File]::ReadAllBytes($FilePath)
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace('-', '').ToUpper()
}

function Compute-CanonicalFingerprint {
  param(
    [string]$VariantId,
    [string]$SourceCommit,
    [string]$BuildTimeUtc,
    [string]$ApprovalDigestSha256,
    [string]$Environment
  )
  $canonical = "$VariantId`n$SourceCommit`n$BuildTimeUtc`n$ApprovalDigestSha256`n$Environment"
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace('-', '').ToUpper()
}

function Compute-ApprovalIdentityDigest {
  param($Artifact)
  $optIn = if ($Artifact.explicitOptIn) { 'true' } else { 'false' }
  $parts = @(
    [string]$Artifact.schemaVersion,
    [string]$Artifact.decision,
    [string]$Artifact.variantId,
    [string]$Artifact.approvedSourceCommit,
    [string]$Artifact.environment,
    [string]$Artifact.authorizationId,
    [string]$Artifact.issuedAtUtc,
    [string]$Artifact.expiresAtUtc,
    $optIn,
    [string]$Artifact.sourceCommit,
    [string]$Artifact.buildTimeUtc
  )
  $canonical = $parts -join "`n"
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace('-', '').ToUpper()
}

# ---- Build the REAL owner-authorized approval fixture ----
# This reproduces the exact owner-authorized approval identity (the same canonical fields
# that produced the committed authorizedApprovalDigest). It is used ONLY to prove that the
# fully valid positive path resolves ACTIVATED in the inert classifier against the real
# contract. It is a TEST fixture, never the real on-disk owner artifact, and is cleaned up
# after verification.
$realApprovalFile = Join-Path $TempRoot 'real-owner-approved-fixture.json'
$realIdentityDigest = ''
$realFingerprint = ''
function Build-RealApprovalObject {
  return [ordered]@{
    schemaVersion = '1.0.0'
    decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
    variantId = 'ACTIVATED_VARIANT_1'
    approvedSourceCommit = $approvedCommit
    environment = 'production'
    authorizationId = 'ac05fe60-ae8b-41bc-9acb-b0f249bfc5c4'
    issuedAtUtc = '2026-09-01T18:55:50.325Z'
    expiresAtUtc = '2026-11-30T23:59:59.999Z'
    explicitOptIn = $true
    sourceCommit = $approvedCommit
    buildTimeUtc = '2026-09-01T18:55:50.325Z'
    releaseVariantFingerprint = ''
    testOnly = $true
    testOnlyNote = 'SYNTHETIC FIXTURE reproducing the owner-approved identity. Never a real approval. Not production-active.'
  }
}

# Build the real-positive fixture: compute identity digest, assert it equals the committed
# contract digest, compute fingerprint, write file.
$realApprovalObj = Build-RealApprovalObject
$realIdentityDigest = Compute-ApprovalIdentityDigest -Artifact $realApprovalObj
$realFingerprint = Compute-CanonicalFingerprint -VariantId 'ACTIVATED_VARIANT_1' -SourceCommit $approvedCommit -BuildTimeUtc '2026-09-01T18:55:50.325Z' -ApprovalDigestSha256 $realIdentityDigest -Environment 'production'
$realApprovalObj.releaseVariantFingerprint = $realFingerprint
$realApprovalObj | ConvertTo-Json | Set-Content -LiteralPath $realApprovalFile -Encoding UTF8

# Assert the fixture reproduces the committed contract digest and the real fingerprint.
# If either fails, the harness cannot prove the positive path against the real contract.
if ($realIdentityDigest -ne $COMMITTED_AUTHORIZED_APPROVAL_DIGEST) {
  throw "Guard harness bootstrapping failure: real-positive fixture digest $realIdentityDigest does not match committed authorizedApprovalDigest $COMMITTED_AUTHORIZED_APPROVAL_DIGEST"
}
if ($realFingerprint -ne $REAL_APPROVAL_FINGERPRINT) {
  throw "Guard harness bootstrapping failure: real-positive fixture fingerprint $realFingerprint does not match expected $REAL_APPROVAL_FINGERPRINT"
}

# ---- Empty file for testing ----
$emptyFile = Join-Path $TempRoot 'empty-approval.txt'
Set-Content -LiteralPath $emptyFile -Value '' -NoNewline -Encoding UTF8

# ---- Create a well-formed but unauthorized approval file (wrong commit) ----
$wrongCommitFile = Join-Path $TempRoot 'wrong-commit-approval.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = '0000000000000000000000000000000000000000'
  environment = 'production'
  authorizationId = 'TEST_ONLY_WRONG_COMMIT'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = '0000000000000000000000000000000000000000'
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $wrongCommitFile -Encoding UTF8

$verdicts = [ordered]@{}
$passCount = 0
$failCount = 0

function Add-Verdict {
  param([string]$name, [bool]$pass, [string]$detail)
  if ($pass) { $script:passCount++ } else { $script:failCount++ }
  $script:verdicts[$name] = [ordered]@{ guard = $name; pass = $pass; detail = $detail }
}

# ===========================================================================
# SECTION A: PRODUCTION CONTRACT TESTS
# These prove that even with ownerAuthorizationActive=true and an authorizedApprovalDigest
# recorded, activation REQUIRES the complete positive authorization surface. Partial,
# malformed, missing, mismatched, expired, stale, or mis-bound inputs stay OFF/REFUSED.
# ===========================================================================

# ---- G1 ordinary/default build (no inputs) -> NORMAL_GATED_OFF ----
$resOut = Join-Path $TempRoot 'g1-ordinary.json'
Invoke-Resolver -OutPath $resOut
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G1 ordinary build defaults OFF' (($r.classification -eq 'NORMAL_GATED_OFF') -and (-not $r.activationAuthorized)) "classification=$($r.classification)"

# ---- G2 capability-only (SYNC_DRAIN_ENABLED=true, nothing else) -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g2-capability.json'
Invoke-Resolver -OutPath $resOut -Seam $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G2 capability-only is NOT AUTHORIZED' (($r.classification -eq 'CAPABLE_NOT_AUTHORIZED') -and (-not $r.activationAuthorized)) "classification=$($r.classification)"

# ---- G3 variant id only (no approval file) -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g3-variant-only.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Seam $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G3 variant-only is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G4 approval-file path missing (empty string) -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g4-missing-approval-file.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile '' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G4 missing approval-file path is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G5 approval file nonexistent -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g5-nonexistent-file.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile (Join-Path $TempRoot 'nonexistent-file.json') -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G5 nonexistent approval file is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G6 approval file empty -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g6-empty-file.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $emptyFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G6 empty approval file is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G7 malformed approval file (not JSON) -> NOT AUTHORIZED ----
$malformedFile = Join-Path $TempRoot 'malformed-approval.txt'
Set-Content -LiteralPath $malformedFile -Value 'this is not json at all {{{' -Encoding UTF8
$resOut = Join-Path $TempRoot 'g7-malformed-file.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $malformedFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G7 malformed approval file is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G8 wrong schema version -> NOT AUTHORIZED ----
$wrongSchemaFile = Join-Path $TempRoot 'wrong-schema-approval.json'
@{
  schemaVersion = '99.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $wrongSchemaFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g8-wrong-schema.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $wrongSchemaFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G8 wrong schema version is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G9 wrong decision token -> NOT AUTHORIZED ----
$wrongDecisionFile = Join-Path $TempRoot 'wrong-decision-approval.json'
@{
  schemaVersion = '1.0.0'
  decision = 'WRONG_DECISION_TOKEN'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $wrongDecisionFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g9-wrong-decision.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $wrongDecisionFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G9 wrong decision token is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G10 wrong variant in approval -> NOT AUTHORIZED ----
$wrongVariantFile = Join-Path $TempRoot 'wrong-variant-approval.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'WRONG_VARIANT'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $wrongVariantFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g10-wrong-variant.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $wrongVariantFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G10 wrong variant in approval is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G11 wrong environment -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g11-wrong-env.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $realApprovalFile -Env 'local' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G11 wrong environment is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G12 wrong source commit (stale) -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g12-wrong-commit.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $wrongCommitFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G12 wrong source commit is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G13 expired approval -> REFUSED or NOT AUTHORIZED ----
$expiredFile = Join-Path $TempRoot 'expired-approval.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST_EXPIRED'
  issuedAtUtc = '2020-01-01T00:00:00.000Z'
  expiresAtUtc = '2020-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $expiredFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g13-expired.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $expiredFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G13 expired approval is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G14 missing explicit opt-in -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g14-no-optin.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $realApprovalFile -Env 'production' -Seam $true -OptIn $false
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G14 missing opt-in is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G15 seam disabled -> NOT AUTHORIZED ----
$resOut = Join-Path $TempRoot 'g15-seam-off.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $realApprovalFile -Env 'production' -Seam $false -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G15 seam disabled is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G16 active owner auth alone does NOT activate (no approval file) ----
# Even with ownerAuthorizationActive=true recorded in the contract, a build with the
# capability seam and explicit opt-in but NO approval file must remain NOT AUTHORIZED.
# ACTIVE OWNER AUTHORIZATION != ACTIVATION.
$resOut = Join-Path $TempRoot 'g16-auth-alone.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
$g16Detail = "classification=$($r.classification) ownerAuthActive=$($r.ownerAuthorizationActive) approvalProvided=$($r.approvalFileProvided)"
Add-Verdict 'G16 active owner auth alone (no approval file) is NOT AUTHORIZED' ((-not $r.activationAuthorized) -and $r.ownerAuthorizationActive) $g16Detail

# ---- G17 caller-supplied digest without approval file -> NOT AUTHORIZED ----
# The resolver no longer accepts -ApprovalDigest. Only -ApprovalFile is accepted.
$resOut = Join-Path $TempRoot 'g17-caller-digest-no-file.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G17 no approval file => NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G18 arbitrary non-empty fingerprint -> REFUSED ----
$arbFingerprintFile = Join-Path $TempRoot 'arb-fingerprint.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'COMPLETELY_ARBITRARY_VALUE_12345'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $arbFingerprintFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g18-arbitrary-fingerprint.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $arbFingerprintFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G18 arbitrary non-empty fingerprint is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ---- G19 one-byte fingerprint mutation -> REFUSED ----
$mutatedFp = $realFingerprint.Substring(0, $realFingerprint.Length - 1) + '0'
$mutFingerprintFile = Join-Path $TempRoot 'mut-fingerprint.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'ac05fe60-ae8b-41bc-9acb-b0f249bfc5c4'
  issuedAtUtc = '2026-09-01T18:55:50.325Z'
  expiresAtUtc = '2026-11-30T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  releaseVariantFingerprint = $mutatedFp
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $mutFingerprintFile -Encoding UTF8
$resOut = Join-Path $TempRoot 'g19-mutated-fingerprint.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $mutFingerprintFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G19 one-byte fingerprint mutation is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ---- G20 stale source commit -> REFUSED ----
$resOut = Join-Path $TempRoot 'g20-stale-commit.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $wrongCommitFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G20 stale source commit is REFUSED or NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ===========================================================================
# SECTION B: POSITIVE PATH (CLASSIFICATION ONLY) + TAMPERING NEGATIVES
# The single fully valid positive path resolves ACTIVATED against the REAL
# owner-authorized contract state. This is classifier/verification only and does NOT
# authorize build, ship, deploy, drain execution, or production contact.
# ===========================================================================

# ---- G21 canonical fingerprint correctly recomputed + full surface -> ACTIVATED ----
$resOut = Join-Path $TempRoot 'g21-real-positive.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $realApprovalFile -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
$g21FpMatch = ($r.fingerprintMatch -eq $true)
Add-Verdict 'G21 full positive surface (real contract) -> ACTIVATED (classification only)' (($r.classification -eq 'ACTIVATED') -and $r.activationAuthorized -and $g21FpMatch) "classification=$($r.classification) fpMatch=$($r.fingerprintMatch) computed=$($r.fingerprintComputed)"

# ---- G22 modified buildTime with old fingerprint -> REFUSED ----
$g22File = Join-Path $TempRoot 'g22-modified-buildtime.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'ac05fe60-ae8b-41bc-9acb-b0f249bfc5c4'
  issuedAtUtc = '2026-09-01T18:55:50.325Z'
  expiresAtUtc = '2026-11-30T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-02T12:30:00.000Z'
  releaseVariantFingerprint = $realFingerprint
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g22File -Encoding UTF8
$resOut = Join-Path $TempRoot 'g22-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g22File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G22 modified buildTime with old fingerprint is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ---- G23 modified environment with old fingerprint -> REFUSED ----
$g23File = Join-Path $TempRoot 'g23-modified-environment.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'staging'
  authorizationId = 'ac05fe60-ae8b-41bc-9acb-b0f249bfc5c4'
  issuedAtUtc = '2026-09-01T18:55:50.325Z'
  expiresAtUtc = '2026-11-30T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  releaseVariantFingerprint = $realFingerprint
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g23File -Encoding UTF8
$resOut = Join-Path $TempRoot 'g23-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g23File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G23 modified environment with old fingerprint is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ---- G24 modified approval digest (different identity) with old fingerprint -> REFUSED ----
$g24File = Join-Path $TempRoot 'g24-modified-approval-digest.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'DIFFERENT_AUTHORIZATION_ID'
  issuedAtUtc = '2026-09-01T18:55:50.325Z'
  expiresAtUtc = '2026-11-30T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  releaseVariantFingerprint = $realFingerprint
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g24File -Encoding UTF8
# The G24 file has the same fields as the real-positive fixture except a different
# authorizationId, so its identity digest differs from the committed digest and the
# fingerprint no longer matches. The resolver must REFUSE.
$resOut = Join-Path $TempRoot 'g24-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g24File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G24 modified approval digest with old fingerprint is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ---- G25 production/default resolver state -> activationAuthorized = FALSE ----
# A default build remains NORMAL_GATED_OFF and activationAuthorized=false even though
# ownerAuthorizationActive=true is recorded. Active owner auth != activation.
$resOut = Join-Path $TempRoot 'g25-production-default.json'
Invoke-Resolver -OutPath $resOut
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G25 production default: activationAuthorized=FALSE' ((-not $r.activationAuthorized) -and ($r.classification -eq 'NORMAL_GATED_OFF')) "classification=$($r.classification) ownerAuthActive=$($r.ownerAuthorizationActive)"

# ---- Additional negative tests ----

# ---- G26 approval file with wrong schema version 2.0 -> NOT AUTHORIZED ----
$g26File = Join-Path $TempRoot 'g26-wrong-schema-2.json'
@{
  schemaVersion = '2.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g26File -Encoding UTF8
$resOut = Join-Path $TempRoot 'g26-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g26File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G26 wrong schema version 2.0 is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G27 missing explicitOptIn field -> NOT AUTHORIZED ----
$g27File = Join-Path $TempRoot 'g27-missing-optin-field.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = 'PLACEHOLDER'
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g27File -Encoding UTF8
$resOut = Join-Path $TempRoot 'g27-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g27File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G27 missing explicitOptIn field is NOT AUTHORIZED' (-not $r.activationAuthorized) "classification=$($r.classification)"

# ---- G28 empty fingerprint -> REFUSED ----
$g28File = Join-Path $TempRoot 'g28-empty-fingerprint.json'
@{
  schemaVersion = '1.0.0'
  decision = 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1'
  variantId = 'ACTIVATED_VARIANT_1'
  approvedSourceCommit = $approvedCommit
  environment = 'production'
  authorizationId = 'TEST'
  issuedAtUtc = '2026-09-01T00:00:00.000Z'
  expiresAtUtc = '2099-12-31T23:59:59.999Z'
  explicitOptIn = $true
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T00:00:00.000Z'
  releaseVariantFingerprint = ''
  testOnly = $true
} | ConvertTo-Json | Set-Content -LiteralPath $g28File -Encoding UTF8
$resOut = Join-Path $TempRoot 'g28-result.json'
Invoke-Resolver -OutPath $resOut -VariantId 'ACTIVATED_VARIANT_1' -ApprovalFile $g28File -Env 'production' -Seam $true -OptIn $true
$r = Get-Content -LiteralPath $resOut -Raw | ConvertFrom-Json
Add-Verdict 'G28 empty fingerprint is REFUSED' ((-not $r.activationAuthorized) -and ($r.classification -eq 'REFUSED')) "classification=$($r.classification)"

# ===========================================================================
# SECTION C: VERIFIER TESTS
# ===========================================================================

# ---- G29 verifier: fully valid real evidence bundle is ACCEPTED ----
$ev = Join-Path $TempRoot 'evidence-real-authorized.json'
@{
  variantId = 'ACTIVATED_VARIANT_1'
  approvalDigestSha256 = $realIdentityDigest
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  environment = 'production'
  releaseVariantFingerprint = $realFingerprint
} | ConvertTo-Json | Set-Content -LiteralPath $ev -Encoding UTF8
$vOut = Join-Path $TempRoot 'v-ok-real.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $ev -ApprovedCommit $approvedCommit -Out $vOut | Out-Null
$vExit = $LASTEXITCODE
$v = Get-Content -LiteralPath $vOut -Raw | ConvertFrom-Json
# With ownerAuthorizationActive=true and a fully valid, matched real evidence bundle the
# verifier ACCEPTS (activated=true). This is verification only.
Add-Verdict 'G29 verifier ACCEPTS fully valid real evidence bundle' (($v.activated) -and ($vExit -eq 0)) "exit=$vExit activated=$($v.activated)"

# ---- G30 verifier: stale commit -> REFUSED ----
$vOut2 = Join-Path $TempRoot 'v-stale.json'
$staleCommit = '0000000000000000000000000000000000000000'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $ev -ApprovedCommit $staleCommit -Out $vOut2 | Out-Null
$vExit2 = $LASTEXITCODE
$v2 = Get-Content -LiteralPath $vOut2 -Raw | ConvertFrom-Json
Add-Verdict 'G30 verifier REFUSES stale commit' (($vExit2 -ne 0) -and (-not $v2.activated)) "exit=$vExit2 activated=$($v2.activated)"

# ---- G31 verifier: arbitrary fingerprint -> REFUSED ----
$evArb = Join-Path $TempRoot 'evidence-arb-fingerprint.json'
@{
  variantId = 'ACTIVATED_VARIANT_1'
  approvalDigestSha256 = $realIdentityDigest
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  environment = 'production'
  releaseVariantFingerprint = 'FINGERPRINT_TEST'
} | ConvertTo-Json | Set-Content -LiteralPath $evArb -Encoding UTF8
$vOut3 = Join-Path $TempRoot 'v-arb.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $evArb -ApprovedCommit $approvedCommit -Out $vOut3 | Out-Null
$vExit3 = $LASTEXITCODE
$v3 = Get-Content -LiteralPath $vOut3 -Raw | ConvertFrom-Json
Add-Verdict 'G31 verifier REFUSES FINGERPRINT_TEST placeholder' (($vExit3 -ne 0) -and (-not $v3.activated)) "exit=$vExit3 activated=$($v3.activated)"

# ---- G32 verifier: empty-content approval digest -> REFUSED ----
$evEmpty = Join-Path $TempRoot 'evidence-empty-digest.json'
@{
  variantId = 'ACTIVATED_VARIANT_1'
  approvalDigestSha256 = $EMPTY_CONTENT_SHA256
  sourceCommit = $approvedCommit
  buildTimeUtc = '2026-09-01T18:55:50.325Z'
  environment = 'production'
  releaseVariantFingerprint = 'SOME_VALUE'
} | ConvertTo-Json | Set-Content -LiteralPath $evEmpty -Encoding UTF8
$vOut4 = Join-Path $TempRoot 'v-empty-digest.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifier -EvidenceJson $evEmpty -ApprovedCommit $approvedCommit -Out $vOut4 | Out-Null
$vExit4 = $LASTEXITCODE
$v4 = Get-Content -LiteralPath $vOut4 -Raw | ConvertFrom-Json
Add-Verdict 'G32 verifier REFUSES empty-content SHA-256 digest' (($vExit4 -ne 0) -and (-not $v4.activated)) "exit=$vExit4 activated=$($v4.activated)"

# ---- Cleanup test fixtures ----
Remove-Item -LiteralPath $realApprovalFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $emptyFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $malformedFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $wrongSchemaFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $wrongDecisionFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $wrongVariantFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $wrongCommitFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $expiredFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $arbFingerprintFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $mutFingerprintFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g22File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g23File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g24File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g26File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g27File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $g28File -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $ev -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $evArb -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $evEmpty -Force -ErrorAction SilentlyContinue

$allPass = ($failCount -eq 0)
$result = [ordered]@{
  phase             = 'Activated Release Variant governance guard harness (post-authorization, fail-closed)'
  capturedAtUtc     = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  allPass           = $allPass
  passCount         = $passCount
  failCount         = $failCount
  productionContractTests = 'G1-G20, G25-G28, G29-G32: prove active owner authorization != activation and all partial/malformed/mismatched cases stay OFF/REFUSED'
  positivePathTests        = 'G21: one fully valid positive path resolves ACTIVATED in the inert classifier (classification only)'
  committedApprovalDigest  = $COMMITTED_AUTHORIZED_APPROVAL_DIGEST
  approvedCommit           = $approvedCommit
  note              = 'Inert local classifiers only; no production contact; no drain-capable artifact produced. Test fixtures cleaned up after verification.'
  verdicts          = $verdicts
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Out -Encoding UTF8
Write-Output ("MODEL guard_tests_activated_variant: allPass={0} pass={1} fail={2}" -f $allPass, $passCount, $failCount)
if (-not $allPass) { exit 1 }
exit 0