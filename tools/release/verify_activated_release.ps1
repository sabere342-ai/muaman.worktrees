# Activated Release Variant — provenance / stale-artifact verification (INERT).
#
# SESSION      = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_AND_TOOLING
# DRAIN_STATE  = GATED/OFF
#
# This tool verifies that a given release-variant evidence bundle would represent an
# authorized Activated Release Variant, WITHOUT building, contacting production, or
# executing the drain. It is a read-only verifier that refuses anything that is not
# fully, demonstrably authorized.
#
# Refuses (exit non-zero, activated=NO) when:
#   - variant id is missing or not the authorized id;
#   - approval digest is missing or does not match the committed authorized digest;
#   - source commit is missing (cannot prove what was activated);
#   - environment is missing or unauthorized;
#   - build time is missing (stale-artifact provenance cannot be proven);
#   - evidence bundle is incomplete.
#
# It also enforces the stale-artifact guard: the reported sourceCommit must equal the
# currently-approved lock commit for this variant, else the artifact is refused as stale.
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

$contract = @{
  authorizedVariantId      = 'ACTIVATED_VARIANT_1'
  authorizedApprovalDigest = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
  allowedEnvironments      = @('production')
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
if ($approval -ne $contract.authorizedApprovalDigest) { $failures += 'approval digest does not match authorized contract' }
if ($sourceCommit -eq '') { $failures += 'missing sourceCommit (cannot prove what was activated)' }
elseif ($sourceCommit -ne $ApprovedCommit) { $failures += "stale artifact: sourceCommit '$sourceCommit' != approved commit '$ApprovedCommit'" }
if ($environment -eq '') { $failures += 'missing environment' }
elseif (-not ($contract.allowedEnvironments -contains $environment)) { $failures += "environment '$environment' not authorized" }
if ($buildTime -eq '') { $failures += 'missing buildTimeUtc (cannot prove provenance timing)' }
if ($fingerprint -eq '') { $failures += 'missing releaseVariantFingerprint (cannot prove exact artifact identity)' }

$activated = ($failures.Count -eq 0)

$result = [ordered]@{
  capturedAtUtc        = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  tool                 = 'verify_activated_release.ps1 (inert provenance verifier)'
  evidenceJson         = $EvidenceJson
  approvedCommit       = $ApprovedCommit
  declaredVariantId    = $variantId
  declaredSourceCommit = $sourceCommit
  declaredBuildTime    = $buildTime
  declaredEnvironment  = $environment
  declaredFingerprint  = $fingerprint
  activated            = $activated
  failureCount         = $failures.Count
  failures             = $failures
  note                 = 'Verifier only; does not build, deploy, contact production, or execute the drain.'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding UTF8

Write-Output ("MODEL release-variant verifier: activated={0} failures={1}" -f $activated, $failures.Count)
if (-not $activated) { foreach ($f in $failures) { Write-Output ("MODEL   failure: {0}" -f $f) } }
if ($activated) { exit 0 } else { exit 1 }
