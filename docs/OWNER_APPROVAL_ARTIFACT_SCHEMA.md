# Owner Approval Artifact — Future Schema Definition

```
SESSION = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CORRECTION
PURPOSE = Define the STRUCTURE and VALIDATION RULES for a future owner approval artifact.
          This session does NOT create a real approval artifact.
          This schema is for reference only until a future owner-authorized session
          creates the actual approval file.
```

## 1. Purpose

This document defines the strict schema that a future owner-approval artifact MUST follow
to be accepted by the governance tooling. The approval artifact is a **separate, non-committed
file** created by the repository owner in a dedicated authorization session.

The approval artifact is NOT code. It is NOT committed to the repository. It is NOT generated
by any tool in this repository. It is created by the owner and supplied at activation time.

## 2. Schema Definition

The approval artifact is a JSON file with the following required fields:

```json
{
  "schemaVersion": "1.0.0",
  "decision": "APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1",
  "variantId": "ACTIVATED_VARIANT_1",
  "approvedSourceCommit": "<40-character lowercase hex SHA-1>",
  "environment": "production",
  "authorizationId": "<unique identifier for this authorization>",
  "issuedAtUtc": "<ISO-8601 UTC timestamp>",
  "expiresAtUtc": "<ISO-8601 UTC timestamp>",
  "explicitOptIn": true,
  "sourceCommit": "<must match approvedSourceCommit>",
  "buildTimeUtc": "<ISO-8601 UTC timestamp of the build>",
  "releaseVariantFingerprint": "<SHA-256 of canonical variant identity>"
}
```

## 3. Field Definitions

| Field | Type | Required | Description |
|---|---|---|---|
| `schemaVersion` | string | YES | Must be `"1.0.0"` for the current schema. Unknown versions are rejected. |
| `decision` | string | YES | Must be exactly `"APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1"`. Any other value is rejected. |
| `variantId` | string | YES | Must be exactly `"ACTIVATED_VARIANT_1"`. Must match the authorized variant in the committed contract. |
| `approvedSourceCommit` | string | YES | 40-character lowercase hex SHA-1 of the exact Git commit authorized for activation. Must match `sourceCommit`. |
| `environment` | string | YES | Must be `"production"`. Debug/local/staging/unknown environments are rejected. |
| `authorizationId` | string | YES | Unique identifier for this authorization event (e.g., UUID). Used for audit trail. |
| `issuedAtUtc` | string | YES | ISO-8601 UTC timestamp of when this authorization was issued. |
| `expiresAtUtc` | string | YES | ISO-8601 UTC timestamp of when this authorization expires. Expired approvals are rejected. |
| `explicitOptIn` | boolean | YES | Must be `true`. Any other value (including `false` or missing) is rejected. |
| `sourceCommit` | string | YES | Must match `approvedSourceCommit`. Used for fingerprint canonicalization. |
| `buildTimeUtc` | string | YES | ISO-8601 UTC timestamp of the build. Used for fingerprint canonicalization. |
| `releaseVariantFingerprint` | string | YES | SHA-256 of the canonical variant identity. Must be recomputed by the verifier; cannot be an arbitrary placeholder. |

## 4. Canonical Fingerprint Serialization

The `releaseVariantFingerprint` MUST be computed as:

```
releaseVariantFingerprint =
  SHA-256(UTF-8(variantId + "\n" + sourceCommit + "\n" + buildTimeUtc
         + "\n" + approvalIdentityDigest + "\n" + environment))
```

where `approvalIdentityDigest` is the digest of the approval **identity payload**:

```
approvalIdentityDigest =
  SHA-256(UTF-8(schemaVersion + "\n" + decision + "\n" + variantId + "\n"
         + approvedSourceCommit + "\n" + environment + "\n" + authorizationId
         + "\n" + issuedAtUtc + "\n" + expiresAtUtc + "\n"
         + (explicitOptIn ? "true" : "false") + "\n" + sourceCommit + "\n"
         + buildTimeUtc))
```

The identity payload deliberately EXCLUDES `releaseVariantFingerprint`. This makes the
digest independent of the fingerprint itself (the file must not contain a value that is a
function of its own hash).

Rules:
- **Encoding:** UTF-8 (no BOM)
- **Field order:** fixed as listed for each canonicalization
- **Separator:** ASCII newline (`\n`, U+000A) between each field
- **Trailing newline:** NONE
- **Case normalization:** None (fields are used as-is; hex SHA values should be lowercase)
- **Whitespace:** Fields are the raw values taken from the approval artifact JSON; no trimming
- **`explicitOptIn`:** serialized as the strings `"true"` or `"false"`
- **Hash algorithm:** SHA-256
- **Output:** Uppercase hex string (64 characters)

The resolver computes both the `approvalIdentityDigest` and the
`releaseVariantFingerprint` itself. The verifier recomputes the
`releaseVariantFingerprint` from the evidence bundle fields. Arbitrary placeholders
(`FINGERPRINT_TEST`, `abc`, `123`, `non-empty-value`, empty string) are explicitly refused.

## 5. Validation Rules

The governance tooling validates the approval artifact in this order:

1. **File existence:** File must exist at the specified path.
2. **File non-empty:** File must contain at least one byte (empty files are rejected).
3. **Valid JSON:** File content must be parseable as JSON.
4. **Schema version:** `schemaVersion` must be `"1.0.0"`.
5. **Decision token:** `decision` must be exactly `"APPROVE_OD7_ACTIVATED_RELEASE_VARIANT_1"`.
6. **Variant match:** `variantId` must match the authorized variant in the committed contract.
7. **Environment match:** `environment` must match the declared build environment.
8. **Explicit opt-in:** `explicitOptIn` must be `true`.
9. **Expiration:** `expiresAtUtc` must be in the future.
10. **Source commit:** `sourceCommit` must match `approvedSourceCommit`.
11. **Identity digest match:** the `approvalIdentityDigest` (computed internally from the
    identity payload, see §4) must match the digest recorded in the committed contract.
12. **Fingerprint recomputation:** `releaseVariantFingerprint` must match the recomputed canonical fingerprint.
13. **Owner authorization active:** The committed contract must have `ownerAuthorizationActive=true`.

If ANY check fails, the approval is rejected and the resolver returns `NOT_AUTHORIZED`
or `REFUSED`.

## 6. Relationship to Committed Contract

The committed contract in `resolve_release_variant.ps1` records:

```
authorizedApprovalDigest = <SHA-256 of the approval identity payload (see §4)>
ownerAuthorizationActive = false  (must be set to true by a future owner-authorized session)
```

The tooling:
1. Reads the approval file from disk.
2. Computes the `approvalIdentityDigest` internally from the approval identity payload.
3. Computes the SHA-256 of the full file bytes as well (audit/tamper evidence).
4. Compares the computed identity digest to the committed `authorizedApprovalDigest`.
5. Only proceeds if they match, all validation rules pass, AND `ownerAuthorizationActive=true`.

A caller-supplied digest string is NEVER accepted as sufficient authorization.

## 7. Creation Process (Future Session)

In a future owner-authorized session:

1. The owner creates the approval artifact file following this schema.
2. The owner computes the `approvalIdentityDigest` from the identity payload (see §4).
3. A governance session updates the committed contract:
   - Sets `authorizedApprovalDigest` to the computed identity digest.
   - Sets `ownerAuthorizationActive = $true`.
4. The activation session supplies the approval file path via `-ApprovalFile`.
5. The tooling validates the file, recomputes the identity digest internally, and verifies it matches.

## 8. Revocation

To revoke an authorization:
- Set `ownerAuthorizationActive = $false` in the committed contract.
- OR update `authorizedApprovalDigest` to a different value.
- OR let the approval expire via `expiresAtUtc`.

## 9. Single-Use Semantics

Each approval artifact is intended for a single activation. The `authorizationId` field
provides uniqueness. A future session may enforce single-use by recording used
`authorizationId` values, but this is outside the scope of the current tooling.

## 10. Example (TEST-ONLY — NOT a real approval)

The guard test harness creates a synthetic approval artifact for testing purposes.
It is marked with `"testOnly": true` and is cleaned up after test execution.
It must NEVER be committed to the repository or left in a production-reachable location.
