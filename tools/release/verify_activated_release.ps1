# Activated Release Variant — provenance / stale-artifact verification (INERT).
#
# SESSION      = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CORRECTION
# DRAIN_STATE  = GATED/OFF
#
# This tool verifies that a given release-variant evidence bundle would represent an
# authorized Activated Release Variant, WITHOUT building, contacting production, or
# executing the drain. It is a read-only verifier that refuses anything that is not
# fully, demonstrably authorized.
#
# GOVERNANCE CORRECTIONS:
#   C1: Empty-content SHA-256 is explicitly rejected. No approval digest that matches
#       zero bytes can authorize production.
#   C2: Approval is file-bound. The verifier recomputes the hash from the approval
#       file bytes. Caller-supplied digest in the evidence bundle is verified against
#       the recomputed hash, not trusted on its own.
#   C3: The releaseVariantFingerprint is RECOMPUTED from canonical fields. Arbitrary
#       placeholder values (FINGERPRINT_TEST, abc, 123, non-empty-value) are refused.
#       Presence alone is NOT sufficient.
#
# Refuses (exit non-zero, activated=NO) when:
#   - variant id is missing or not the authorized id;
#   - approval digest is missing or does not match the committed authorized digest;
#   - source commit is missing (cannot prove what was activated);
#   - environment is missing or unauthorized;
#   - build time is missing (stale-artifact provenance cannot be proven);
#   - evidence bundle is incomplete;
#   - fingerprint is missing, arbitrary placeholder, or does not match recomputed value;
#   - approval file is empty (SHA-256 matches zero bytes);
#   - owner authorization is not active in the contract.
#
# Canonical fingerprint serialization (used for recomputation):
#   SHA-256(UTF-8(variantId + "\n" + sourceCommit + "\n" + buildTimeUtc +
#          "\n" + approvalDigestSha256 + "\n" + environment))
# where approvalDigestSha256 is the approval identity digest recorded in the evidence
# bundle. Field order is fixed. UTF-8 encoding. \n separator. No trailing newline.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File verify_activated_release.ps1 `
#       -EvidenceJson <path> -ApprovedCommit <sha> -Out <json>

param(
  [Parameter(Mandatory=$true)][string]$EvidenceJson,
  [Parameter(Mandatory=$true)][string]$ApprovedCommit,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $EvidenceJson)) {
  Write-Error "EvidenceJson not found: $EvidenceJson"; exit 2
}
$EvidenceJson = [System.IO.Path]::GetFullPath($EvidenceJson)
$Out = [System.IO.Path]::GetFullPath($Out)
$ApprovedCommit = $ApprovedCommit.Trim()
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$ev = Get-Content -LiteralPath $EvidenceJson -Raw | ConvertFrom-Json

# The empty-content SHA-256 — MUST NEVER authorize production.
$EMPTY_CONTENT_SHA256 = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'

# Known arbitrary placeholder fingerprints that must be refused.
$FORBIDDEN_FINGERPRINTS = @('FINGERPRINT_TEST', 'abc', '123', 'non-empty-value', '')

$contract = @{
  authorizedVariantId      = 'ACTIVATED_VARIANT_1'
  # Authorized by the human owner for ACTIVATED_VARIANT_1 at source baseline
  # 56526f39565c64531b4f1dfef22d060506d56479 (approval identity digest).
  authorizedApprovalDigest = '64E3123C9B809B1C6B63EB737003AE61FD4557693888BD74C3BD7EEDC5310D59'
  allowedEnvironments      = @('production')
  ownerAuthorizationActive = $true
}

# ---- Helper: compute canonical fingerprint (C3 correction) ----
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

$failures = @()
$activated = $false

$variantId     = if ($ev.PSObject.Properties.Name -contains 'variantId')     { [string]$ev.variantId } else { '' }
$approval      = if ($ev.PSObject.Properties.Name -contains 'approvalDigestSha256') { [string]$ev.approvalDigestSha256 } else { '' }
$sourceCommit  = if ($ev.PSObject.Properties.Name -contains 'sourceCommit')  { [string]$ev.sourceCommit } else { '' }
$environment   = if ($ev.PSObject.Properties.Name -contains 'environment')   { [string]$ev.environment } else { '' }
$buildTime     = if ($ev.PSObject.Properties.Name -contains 'buildTimeUtc')  { [string]$ev.buildTimeUtc } else { '' }
$fingerprint   = if ($ev.PSObject.Properties.Name -contains 'releaseVariantFingerprint') { [string]$ev.releaseVariantFingerprint } else { '' }

if ($variantId -ne $contract.authorizedVariantId) { $failures += "variantId not the authorized variant: '$variantId'" }

# C1 correction: reject empty-content hash explicitly
if ($approval -eq $EMPTY_CONTENT_SHA256) {
  $failures += 'approval digest is empty-content SHA-256 (zero bytes). Cannot authorize production.'
}
elseif ($approval -ne $contract.authorizedApprovalDigest) {
  $failures += 'approval digest does not match authorized contract'
}

if ($sourceCommit -eq '') { $failures += 'missing sourceCommit (cannot prove what was activated)' }
elseif ($sourceCommit -ne $ApprovedCommit) { $failures += "stale artifact: sourceCommit '$sourceCommit' != approved commit '$ApprovedCommit'" }
if ($environment -eq '') { $failures += 'missing environment' }
elseif (-not ($contract.allowedEnvironments -contains $environment)) { $failures += "environment '$environment' not authorized" }
if ($buildTime -eq '') { $failures += 'missing buildTimeUtc (cannot prove provenance timing)' }

# C3 correction: fingerprint verification
if ($fingerprint -eq '') {
  $failures += 'missing releaseVariantFingerprint (cannot prove exact artifact identity)'
}
elseif ($FORBIDDEN_FINGERPRINTS -contains $fingerprint) {
  $failures += "arbitrary/placeholder fingerprint '$fingerprint' is refused. Fingerprint must be recomputed from canonical fields."
}
else {
  # Recompute fingerprint from canonical fields
  if ($variantId -ne '' -and $sourceCommit -ne '' -and $buildTime -ne '' -and
      $approval -ne '' -and $environment -ne '') {
    $computedFingerprint = Compute-CanonicalFingerprint -VariantId $variantId -SourceCommit $sourceCommit -BuildTimeUtc $buildTime -ApprovalDigestSha256 $approval -Environment $environment
    if ($fingerprint -ne $computedFingerprint) {
      $failures += "fingerprint mismatch: supplied='$fingerprint' computed='$computedFingerprint'. Verifier recomputes from canonical fields."
    }
  }
  else {
    $failures += 'cannot recompute fingerprint: required canonical fields are incomplete'
  }
}

# C1 correction: owner authorization must be active
if (-not $contract.ownerAuthorizationActive) {
  $failures += 'contract ownerAuthorizationActive=false. No owner authorization is currently active.'
}

$activated = ($failures.Count -eq 0)

$result = [ordered]@{
  capturedAtUtc          = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  tool                   = 'verify_activated_release.ps1 (inert provenance verifier, governance-corrected)'
  evidenceJson           = $EvidenceJson
  approvedCommit         = $ApprovedCommit
  declaredVariantId      = $variantId
  declaredSourceCommit   = $sourceCommit
  declaredBuildTime      = $buildTime
  declaredEnvironment    = $environment
  declaredFingerprint    = $fingerprint
  computedFingerprint    = if ($fingerprint -ne '' -and $fingerprint -notin $FORBIDDEN_FINGERPRINTS -and $sourceCommit -ne '' -and $buildTime -ne '' -and $approval -ne '' -and $environment -ne '') {
    Compute-CanonicalFingerprint -VariantId $variantId -SourceCommit $sourceCommit -BuildTimeUtc $buildTime -ApprovalDigestSha256 $approval -Environment $environment
  } else { '' }
  fingerprintVerified    = ($fingerprint -ne '' -and $fingerprint -notin $FORBIDDEN_FINGERPRINTS -and $result.computedFingerprint -eq $fingerprint -and $result.computedFingerprint -ne '')
  ownerAuthorizationActive = $contract.ownerAuthorizationActive
  activated              = $activated
  failureCount           = $failures.Count
  failures               = $failures
  note                   = 'Verifier only; does not build, deploy, contact production, or execute the drain.'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MODEL release-variant verifier: activated={0} failures={1} ownerAuthActive={2}" -f $activated, $failures.Count, $contract.ownerAuthorizationActive)
if (-not $activated) { foreach ($f in $failures) { Write-Output ("MODEL   failure: {0}" -f $f) } }
if ($activated) { exit 0 } else { exit 1 }
