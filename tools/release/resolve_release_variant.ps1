# Activated Release Variant — fail-closed classifier (INERT).
#
# SESSION      = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CORRECTION
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
#   - Variant id but no approval file  -> NOT_AUTHORIZED (OFF)
#   - Approval file missing/empty/bad  -> NOT_AUTHORIZED (OFF)
#   - Approval file but wrong/missing id -> NOT_AUTHORIZED (OFF)
#   - Malformed variant id or approval  -> NOT_AUTHORIZED (OFF)
#   - Unauthorized environment          -> NOT_AUTHORIZED (OFF)
#   - Fingerprint mismatch/placeholder  -> REFUSED
#   - Owner authorization inactive      -> NOT_AUTHORIZED (OFF)
#   - ALL positive inputs consistent    -> ACTIVATED  (classifier token only;
#     requires separate authorized session; but ownerAuthorizationActive=false
#     currently prevents this path)
#
# GOVERNANCE CORRECTION (Defects C1+C2+C3):
#   C1: Empty-string SHA-256 is NEVER an authorization. ownerAuthorizationActive=false
#       structurally prevents ACTIVATED regardless of other inputs.
#   C2: Approval is FILE-BOUND. Caller must supply -ApprovalFile <path>.
#       The tool computes SHA-256 internally. Caller-supplied digest is NOT trusted.
#   C3: Fingerprint is RECOMPUTED from canonical fields. Presence alone is refused.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File resolve_release_variant.ps1 `
#       -VariantId <id> -ApprovalFile <path> -Environment <env> `
#       -DartDefineSyncDrainEnabled <bool> -OptInActivation <bool> -Out <json>
#
# Parameters beyond -Out are OPTIONAL. Their absence exercises the fail-closed default.

param(
  [string]$VariantId = '',
  [string]$ApprovalFile = '',
  [string]$Environment = '',
  [string]$DartDefineSyncDrainEnabled = 'false',
  [string]$OptInActivation = 'false',
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'

$seam = if ($DartDefineSyncDrainEnabled -eq 'true') { $true } else { $false }
$optIn = if ($OptInActivation -eq 'true') { $true } else { $false }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# The empty-content SHA-256 — MUST NEVER authorize production.
$EMPTY_CONTENT_SHA256 = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'

# Committed authorized activation contract (see docs/ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CONTRACT.md)
# GOVERNANCE CORRECTION: ownerAuthorizationActive is the master switch.
# When false, NO combination of other inputs can produce ACTIVATED.
# The authorizedApprovalDigest below is a structural placeholder for future activation;
# it is NOT the empty-string hash and cannot be matched by any real approval file
# until a future owner-authorized session sets ownerAuthorizationActive=true.
$contract = [ordered]@{
  authorizedVariantId      = 'ACTIVATED_VARIANT_1'
  # NOT_SET: no owner authorization is currently active. A future session must
  # update this and set ownerAuthorizationActive=$true for activation to be possible.
  authorizedApprovalDigest = 'NOT_SET'
  allowedEnvironments      = @('production')
  allowCapabilityOnly      = $false
  ownerAuthorizationActive = $false
}

if ([string]::IsNullOrWhiteSpace($Out)) {
  $Out = Join-Path $env:TEMP ('release-variant-' + [guid]::NewGuid().ToString('N') + '.json')
}
New-Item -ItemType Directory -Path (Split-Path -Parent $Out) -Force | Out-Null

$normalizedEnvironment = $Environment.Trim()
$normalizedVariantId = $VariantId.Trim()

# ---- Helper: compute canonical fingerprint (C3 correction) ----
# Canonical serialization:
#   releaseVariantFingerprint = SHA-256(UTF-8(variantId + "\n" + sourceCommit + "\n"
#                                          + buildTimeUtc + "\n" + approvalDigestSha256 + "\n"
#                                          + environment))
# where approvalDigestSha256 = the approval identity digest (see below).
# This must match the verifier's recomputation exactly.
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

# ---- Helper: compute the approval identity digest ----
# The identity digest binds the authorization PAYLOAD (every approval field EXCEPT
# releaseVariantFingerprint, which is self-referential). It is a newline-joined
# canonical string, JSON-format independent, so it is deterministic regardless of
# file formatting:
#   SHA-256(UTF-8(schemaVersion + "\n" + decision + "\n" + variantId + "\n"
#              + approvedSourceCommit + "\n" + environment + "\n" + authorizationId
#              + "\n" + issuedAtUtc + "\n" + expiresAtUtc + "\n"
#              + (explicitOptIn ? "true" : "false") + "\n" + sourceCommit + "\n"
#              + buildTimeUtc))
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

# ---- Helper: compute SHA-256 of a file ----
function Compute-FileHash256 {
  param([string]$FilePath)
  $bytes = [System.IO.File]::ReadAllBytes($FilePath)
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace('-', '').ToUpper()
}

# ---- Helper: parse approval artifact JSON ----
function Parse-ApprovalArtifact {
  param([string]$FilePath)
  if (-not (Test-Path -LiteralPath $FilePath)) { return $null }
  $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
  if ([string]::IsNullOrWhiteSpace($content)) { return $null }
  try {
    return ($content | ConvertFrom-Json)
  } catch {
    return $null
  }
}

# Arbitrary placeholder fingerprints that MUST be refused.
function Test-ForbiddenFingerprint {
  param([string]$Value)
  return ($Value -in @('FINGERPRINT_TEST', 'abc', '123', 'non-empty-value', ''))
}

# ---- Classify strictly per the fail-closed matrix ----
$decision = 'NORMAL_GATED_OFF'
$reason = 'No activation input present (default).'
$drainCapable = $false
$approvalFileProvided = $false
$approvalFileExists = $false
$approvalFileHash = ''
$approvalIdentityDigest = ''
$approvalArtifact = $null
$fingerprintComputed = ''
$fingerprintSupplied = ''
$fingerprintMatch = $false
$ownerAuthActive = $contract.ownerAuthorizationActive
# Prioritized failure reason. 'REFUSED' outranks 'NOT_AUTHORIZED'.
$failureLevel = ''   # '', 'NOT_AUTHORIZED', or 'REFUSED'
$failureReason = ''

if ($seam) {
  # Capability only. This is NOT authority. Remains OFF.
  $decision = 'CAPABLE_NOT_AUTHORIZED'
  $reason = 'SYNC_DRAIN_ENABLED seam present (capability) but activation not authorized.'
}

if ($normalizedVariantId -ne '') {
  # An explicit variant id was supplied. Still requires the full positive surface.

  if ($normalizedVariantId -ne $contract.authorizedVariantId) {
    if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
    $failureReason = "Variant id '$normalizedVariantId' is not the authorized variant."
  }
  elseif ([string]::IsNullOrWhiteSpace($ApprovalFile)) {
    # C2 correction: require -ApprovalFile, not -ApprovalDigest
    if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
    $failureReason = 'Missing required -ApprovalFile parameter. Caller-supplied digest is NOT accepted.'
  }
  else {
    $approvalFileProvided = $true

    if (-not (Test-Path -LiteralPath $ApprovalFile)) {
      if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
      $failureReason = "Approval file does not exist: $ApprovalFile"
    }
    else {
      $approvalFileExists = $true

      # C1 correction: compute hash of approval file bytes internally
      $approvalFileHash = Compute-FileHash256 -FilePath $ApprovalFile

      # C1 correction: explicit rejection of empty-content hash
      if ($approvalFileHash -eq $EMPTY_CONTENT_SHA256) {
        if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
        $failureReason = 'Approval file is empty (SHA-256 matches zero bytes). Empty content cannot authorize production.'
      }

      # Parse the artifact for schema + fingerprint validation regardless of digest match,
      # so fingerprint/invalidity is always caught and reported (C3).
      $approvalArtifact = Parse-ApprovalArtifact -FilePath $ApprovalFile
      if ($null -eq $approvalArtifact) {
        if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
        $failureReason = 'Approval file is not valid JSON.'
      }
      else {
        # C2: compute the approval identity digest internally from the artifact payload.
        $approvalIdentityDigest = Compute-ApprovalIdentityDigest -Artifact $approvalArtifact

        # ---- Schema field-presence validation (C2) ----
        $schemaErrors = @()
        foreach ($f in @('schemaVersion','decision','variantId','approvedSourceCommit','environment','authorizationId','issuedAtUtc','expiresAtUtc','explicitOptIn','sourceCommit')) {
          if (-not ($approvalArtifact.PSObject.Properties.Name -contains $f)) { $schemaErrors += "missing $f" }
        }
        if ($schemaErrors.Count -gt 0) {
          if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
          $failureReason = "Approval artifact schema invalid: $($schemaErrors -join '; ')"
        }
        else {
          # ---- Field-value validation ----
          if ($approvalArtifact.schemaVersion -ne '1.0.0') {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = "Approval schemaVersion '$($approvalArtifact.schemaVersion)' is not the authorized '1.0.0'."
          }
          elseif ($approvalArtifact.decision -ne 'APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1') {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = "Approval decision token '$($approvalArtifact.decision)' is not the authorized decision."
          }
          elseif ($approvalArtifact.variantId -ne $contract.authorizedVariantId) {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = "Approval variantId '$($approvalArtifact.variantId)' does not match authorized variant."
          }
          elseif ($approvalArtifact.environment -ne $normalizedEnvironment) {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = "Approval environment '$($approvalArtifact.environment)' does not match declared environment '$normalizedEnvironment'."
          }
          elseif (-not $approvalArtifact.explicitOptIn) {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = 'Approval artifact does not contain explicitOptIn=true.'
          }
          elseif ($approvalArtifact.sourceCommit -ne $approvalArtifact.approvedSourceCommit) {
            if ($failureLevel -ne 'REFUSED') { $failureLevel = 'NOT_AUTHORIZED' }
            $failureReason = "Approval sourceCommit does not match approvedSourceCommit."
          }
          elseif ($approvalArtifact.expiresAtUtc) {
            $expiresAt = [DateTime]::Parse($approvalArtifact.expiresAtUtc).ToUniversalTime()
            if ([DateTime]::UtcNow -gt $expiresAt) {
              $failureLevel = 'REFUSED'
              $failureReason = "Approval artifact expired at $($approvalArtifact.expiresAtUtc)."
            }
          }
        }

        # ---- C3: fingerprint recomputation always runs, independent of above ----
        if ($approvalArtifact.PSObject.Properties.Name -contains 'releaseVariantFingerprint' -and
            $approvalArtifact.PSObject.Properties.Name -contains 'sourceCommit' -and
            $approvalArtifact.PSObject.Properties.Name -contains 'buildTimeUtc') {
          $fingerprintSupplied = [string]$approvalArtifact.releaseVariantFingerprint
          if (Test-ForbiddenFingerprint -Value $fingerprintSupplied) {
            $failureLevel = 'REFUSED'
            $failureReason = "Fingerprint '$($fingerprintSupplied)' is empty or an arbitrary placeholder. Fingerprint must be recomputed from canonical fields."
            if ([string]::IsNullOrWhiteSpace($fingerprintSupplied)) { $failureReason = 'Empty fingerprint in approval artifact. Presence alone is not sufficient.' }
          }
          else {
            $fingerprintComputed = Compute-CanonicalFingerprint -VariantId $approvalArtifact.variantId -SourceCommit $approvalArtifact.sourceCommit -BuildTimeUtc $approvalArtifact.buildTimeUtc -ApprovalDigestSha256 $approvalIdentityDigest -Environment $approvalArtifact.environment
            $fingerprintMatch = ($fingerprintSupplied -eq $fingerprintComputed)
            if (-not $fingerprintMatch) {
              $failureLevel = 'REFUSED'
              $failureReason = "Fingerprint mismatch: supplied='$fingerprintSupplied' computed='$fingerprintComputed'. Verifier recomputes from canonical fields."
            }
          }
        }
      }
    }
  }

  # ---- Combined gate: everything must pass to reach ACTIVATED ----
  if ($failureLevel -eq '') {
    # No structural/content failure yet. Now require remaining authorization gates.
    if ($contract.authorizedApprovalDigest -eq 'NOT_SET' -or $approvalIdentityDigest -ne $contract.authorizedApprovalDigest) {
      if ($contract.authorizedApprovalDigest -eq 'NOT_SET') {
        $failureReason = 'Contract has no active owner authorization (authorizedApprovalDigest=NOT_SET).'
      } else {
        $failureReason = 'Approval identity digest does not match the authorized contract digest.'
      }
      $failureLevel = 'NOT_AUTHORIZED'
    }
    elseif (-not $seam) {
      $failureLevel = 'NOT_AUTHORIZED'
      $failureReason = 'Capability seam not enabled (SYNC_DRAIN_ENABLED).'
    }
    elseif (-not $optIn) {
      $failureLevel = 'NOT_AUTHORIZED'
      $failureReason = 'Explicit activation opt-in not set.'
    }
    elseif (-not $ownerAuthActive) {
      $failureLevel = 'NOT_AUTHORIZED'
      $failureReason = 'Contract ownerAuthorizationActive=false. Future owner approval required.'
    }
    else {
      $decision = 'ACTIVATED'
      $reason = 'Full positive authorization surface present and consistent.'
      $drainCapable = $true
    }
  }

  # Apply the failure if one was recorded (REFUSED outranks NOT_AUTHORIZED)
  if ($failureLevel -ne '') {
    $decision = $failureLevel
    $reason = $failureReason
    if ($failureLevel -eq 'NOT_AUTHORIZED') { $drainCapable = $true }
    else { $drainCapable = $false }
  }
}

$result = [ordered]@{
  capturedAtUtc              = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  tool                       = 'resolve_release_variant.ps1 (inert classifier, governance-corrected)'
  repositoryRoot             = $repoRoot
  declaredVariantId          = $normalizedVariantId
  declaredEnvironment        = $normalizedEnvironment
  optInActivation            = $optIn
  drainSeamPresent           = $seam
  approvalFileProvided       = $approvalFileProvided
  approvalFileExists         = $approvalFileExists
  approvalFileHash           = $approvalFileHash
  approvalIdentityDigest     = $approvalIdentityDigest
  fingerprintSupplied        = $fingerprintSupplied
  fingerprintComputed        = $fingerprintComputed
  fingerprintMatch           = $fingerprintMatch
  ownerAuthorizationActive   = $ownerAuthActive
  classification             = $decision
  drainCapable               = $drainCapable
  activationAuthorized       = ($decision -eq 'ACTIVATED')
  reason                     = $reason
  note                       = 'Classifier output only; does not build, deploy, contact production, or execute the drain.'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MODEL release-variant resolver: classification={0} activationAuthorized={1} drainCapable={2} ownerAuthActive={3}" -f $decision, $result.activationAuthorized, $drainCapable, $ownerAuthActive)
Write-Output ("MODEL release-variant resolver: evidence -> {0}" -f $Out)

if ($decision -eq 'ACTIVATED') {
  Write-Output 'MODEL ACTIVATION-TOKEN:ACTIVATED_VARIANT_1 (classifier only; build NOT performed)'
}
exit 0