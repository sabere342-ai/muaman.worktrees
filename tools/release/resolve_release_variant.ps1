# Activated Release Variant — fail-closed classifier (INERT).
#
# SESSION      = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_AND_TOOLING
# DRAIN_STATE  = GATED/OFF
#
# This tool ONLY classifies a release variant from explicit inputs and emits JSON
# evidence. It does NOT:
#   - build a release;
#   - sign or upload anything;
#   - contact production / Supabase / network;
#   - execute the drain;
#   - alter runtime configuration;
#   - create any artifact capable of draining.
#
# Fail-closed design (missing -> OFF, unknown -> OFF, malformed -> OFF):
#   - No input / ordinary build        -> NORMAL_GATED_OFF
#   - SYNC_DRAIN_ENABLED=true (seam)   -> CAPABLE_NOT_AUTHORIZED (OFF)
#   - Variant id but no approval       -> NOT_AUTHORIZED (OFF)
#   - Approval but wrong/missing id    -> NOT_AUTHORIZED (OFF)
#   - Malformed id or digest           -> NOT_AUTHORIZED (OFF)
#   - Unauthorized environment         -> NOT_AUTHORIZED (OFF)
#   - ALL positive inputs consistent   -> ACTIVATED  (ON; requires separate authorized session)
#
# Even when it returns ACTIVATED, it is only a CLASSIFIER: it returns a token string
# that a separate, separately-authorized activation session would consume. This tool
# does not build or execute anything.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File resolve_release_variant.ps1 `
#       -VariantId <id> -ApprovalDigest <sha256> -Environment <env> `
#       -DartDefineSyncDrainEnabled <bool> -OptInActivation <bool> -Out <json>
#
# Parameters beyond -Out are OPTIONAL. Their absence exercises the fail-closed default.

param(
  [string]$VariantId = '',
  [string]$ApprovalDigest = '',
  [string]$Environment = '',
  [string]$DartDefineSyncDrainEnabled = 'false',
  [string]$OptInActivation = 'false',
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'

$seam = if ($DartDefineSyncDrainEnabled -eq 'true') { $true } else { $false }
$optIn = if ($OptInActivation -eq 'true') { $true } else { $false }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Committed authorized activation contract (see docs/ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CONTRACT.md)
$contract = [ordered]@{
  authorizedVariantId     = 'ACTIVATED_VARIANT_1'
  authorizedApprovalDigest = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
  allowedEnvironments     = @('production')
  allowCapabilityOnly     = $false
}

if ([string]::IsNullOrWhiteSpace($Out)) {
  $Out = Join-Path $env:TEMP ('release-variant-' + [guid]::NewGuid().ToString('N') + '.json')
}
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$normalizedEnvironment = $Environment.Trim()
$normalizedVariantId = $VariantId.Trim()

# Decide classification strictly per the fail-closed matrix.
$decision = 'NORMAL_GATED_OFF'
$reason = 'No activation input present (default).'
$drainCapable = $false

if ($seam) {
  # Capability only. This is NOT authority. Remains OFF.
  $decision = 'CAPABLE_NOT_AUTHORIZED'
  $reason = 'SYNC_DRAIN_ENABLED seam present (capability) but activation not authorized.'
}

if ($normalizedVariantId -ne '') {
  # An explicit variant id was supplied. Still requires the full positive surface.
  if ($normalizedVariantId -ne $contract.authorizedVariantId) {
    $decision = 'NOT_AUTHORIZED'
    $reason = "Variant id '$normalizedVariantId' is not the authorized variant."
    $drainCapable = $true
  }
  elseif ($ApprovalDigest.Trim() -eq '') {
    $decision = 'NOT_AUTHORIZED'
    $reason = 'Missing owner-approval digest.'
    $drainCapable = $true
  }
  elseif ($ApprovalDigest.Trim() -ne $contract.authorizedApprovalDigest) {
    $decision = 'NOT_AUTHORIZED'
    $reason = 'Owner-approval digest does not match the authorized contract.'
    $drainCapable = $true
  }
  elseif ($normalizedEnvironment -eq '') {
    $decision = 'NOT_AUTHORIZED'
    $reason = 'Missing environment declaration.'
    $drainCapable = $true
  }
  elseif (-not ($contract.allowedEnvironments -contains $normalizedEnvironment)) {
    $decision = 'NOT_AUTHORIZED'
    $reason = "Environment '$normalizedEnvironment' is not in the authorized allowlist."
    $drainCapable = $true
  }
  elseif (-not $optIn) {
    $decision = 'NOT_AUTHORIZED'
    $reason = 'Explicit activation opt-in not set.'
    $drainCapable = $true
  }
  elseif (-not $seam) {
    $decision = 'NOT_AUTHORIZED'
    $reason = 'Capability seam not enabled (SYNC_DRAIN_ENABLED).'
    $drainCapable = $false
  }
  else {
    # All positive inputs present and consistent.
    $decision = 'ACTIVATED'
    $reason = 'Full positive authorization surface present and consistent.'
    $drainCapable = $true
  }
}

$result = [ordered]@{
  capturedAtUtc          = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  tool                   = 'resolve_release_variant.ps1 (inert classifier)'
  repositoryRoot         = $repoRoot
  declaredVariantId      = $normalizedVariantId
  declaredEnvironment    = $normalizedEnvironment
  optInActivation        = $optIn
  drainSeamPresent       = $seam
  classification         = $decision
  drainCapable           = $drainCapable
  activationAuthorized   = ($decision -eq 'ACTIVATED')
  reason                 = $reason
  note                   = 'Classifier output only; does not build, deploy, contact production, or execute the drain.'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MODEL release-variant resolver: classification={0} activationAuthorized={1} drainCapable={2}" -f $decision, $result.activationAuthorized, $drainCapable)
Write-Output ("MODEL release-variant resolver: evidence -> {0}" -f $Out)

if ($decision -eq 'ACTIVATED') {
  # Even the ACTIVATED classification is returned as a classifier token; it is NOT a
  # build instruction. A separate owner-authorized session interprets this token.
  Write-Output 'MODEL ACTIVATION-TOKEN:ACTIVATED_VARIANT_1 (classifier only; build NOT performed)'
}
exit 0
