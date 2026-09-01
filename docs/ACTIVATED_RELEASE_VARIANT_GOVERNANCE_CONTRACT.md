# Activated Release Variant — Governance Contract

```
SESSION        = GROUP_A_PHASE_P_OD7_ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CORRECTION
IDENTITY       = ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CORRECTION (governance correction + inert tooling)
DRAIN_STATE    = GATED/OFF
AUTHORITY      = governance definition + inert fail-closed tooling ONLY
NO_ACTIVATION  = this document defines a corrected future contract; it does not authorize or perform activation
```

## 1. Purpose

This contract defines how the repository will represent an explicitly owner-authorized
"Activated Release Variant" while making **accidental activation impossible** and preserving
the **normal/default release variant as GATED/OFF**.

This session does **not** produce, ship, deploy, activate, or execute any activated release.
It only establishes the determinism the repository requires so that a later separately
owner-authorized activation session is unambiguous and auditable.

## 2. Core Principle: Separate Capability from Authorization

```
CAPABILITY_PRESENT != ACTIVATION_AUTHORIZED
```

The repository may contain code that is technically **capable** of executing drain
operations. That capability does not of itself grant authority. Any mechanism that would
switch a build from "capable" to "activated" must require an **explicit, positive, owner
authorization artifact** that is separate from the code that confers capability.

## 3. Release Variant Identity

The repository recognizes three release-variant classes:

| Variant | Identity token | Default | Drain capability |
|---|---|---|---|
| NORMAL (default) | `NORMAL_GATED_OFF` | default | seam OFF |
| UNKNOWN / MALFORMED | `INVALID` | never default | refused (fail-closed) |
| ACTIVATED (owner-authorized) | `ACTIVATED_VARIANT_1` | never default | seam ON only via explicit approval |

Rules:

1. The **default** variant is always `NORMAL_GATED_OFF`. Absence of any activation input
   yields the normal gated build.
2. `ACTIVATED_VARIANT_1` is never chosen implicitly. It is chosen **only** when the full
   positive authorization surface is present (see §5).
3. Any input that does not exactly match the authorized activation surface is treated as
   `INVALID` and is fail-closed — never partially activated.

## 4. Fail-Closed Matrix

The resolver tool must implement exactly this table. **Missing/unknown/malformed →
OFF. There is no fail-open path.**

| Condition | Resolver result | Drain-ability |
|---|---|---|
| No activation input at all (ordinary build / CI) | `NORMAL_GATED_OFF` | OFF |
| `--dart-define=SYNC_DRAIN_ENABLED=true` alone (capability only) | `CAPABLE_NOT_AUTHORIZED` | OFF |
| Activated variant ID present but no owner-approval file | `NOT_AUTHORIZED` | OFF |
| Owner-approval file missing / nonexistent | `NOT_AUTHORIZED` | OFF |
| Owner-approval file empty (SHA-256 matches zero bytes) | `NOT_AUTHORIZED` | OFF |
| Owner-approval file malformed (not valid JSON) | `NOT_AUTHORIZED` | OFF |
| Approval file present but wrong schema version | `NOT_AUTHORIZED` | OFF |
| Approval file present but wrong decision token | `NOT_AUTHORIZED` | OFF |
| Approval file present but wrong variant ID | `NOT_AUTHORIZED` | OFF |
| Approval file present but wrong environment | `NOT_AUTHORIZED` | OFF |
| Approval file present but wrong source commit | `REFUSED` | OFF |
| Approval file present but expired | `REFUSED` | OFF |
| Approval file present but explicit opt-in missing | `NOT_AUTHORIZED` | OFF |
| Approval file present but seam disabled | `NOT_AUTHORIZED` | OFF |
| Approval file present but contract has no active owner authorization | `NOT_AUTHORIZED` | OFF |
| Fingerprint missing or arbitrary placeholder | `REFUSED` | OFF |
| Fingerprint does not match recomputed canonical value | `REFUSED` | OFF |
| All required positive inputs present and consistent | `ACTIVATED` | ON (only here) |

The `--dart-define=SYNC_DRAIN_ENABLED=true` seam is treated as **capability only**. On its
own it must resolve `CAPABLE_NOT_AUTHORIZED` (OFF). It upgrades to `ACTIVATED` only when the
full positive authorization surface is also present.

## 5. Positive Authorization Surface (what activation requires)

A later activation session must supply ALL of the following to select
`ACTIVATED_VARIANT_1`:

1. **Variant identity (compile-time):** the exact authorized `-VariantId` matching
   `ACTIVATED_VARIANT_1`.
2. **Owner approval artifact (file, not committed):** a file whose SHA-256 (computed
   internally by the tool from the file bytes) matches the digest recorded for this
   variant in the committed contract. The file itself is NOT committed. A caller-supplied
   digest string is NOT accepted as sufficient authorization.
3. **Explicit opt-in flag:** the resolver is invoked with an explicit opt-in indicating the
   operator authorizes an activated build for this exact variant.
4. **Authorized environment:** the declared build environment must be in the allowlist for
   this variant (recorded in the committed contract). Debug/local/unknown are refused.
5. **Owner authorization active:** the committed contract must have
   `ownerAuthorizationActive=true`. This is the master switch that structurally prevents
   activation when set to `false`.
6. **Valid fingerprint:** the `releaseVariantFingerprint` in the approval artifact must be
   a SHA-256 of the canonical variant identity, recomputed by the verifier. Arbitrary
   placeholders are refused.

## 6. Why This Prevents Accidental Activation

- **Ordinary build → OFF:** no activation input is present by default; resolver returns
  `NORMAL_GATED_OFF`.
- **Ordinary CI → OFF:** CI passes no activation input; the resolver never flips the default.
- **Release scripts cannot silently inherit activation:** `SYNC_DRAIN_ENABLED=true` alone is
  capability, not authority; resolver still returns `CAPABLE_NOT_AUTHORIZED`.
- **Stale binaries guarded:** every activated artifact must carry a variant identity token,
  source commit SHA, and build-time; a stale artifact whose variant token or commit does not
  match the currently approved contract is refused (see §9).
- **Accidental developer/local activation:** debug/local/unknown environments are refused in
  the authorization allowlist check.
- **Empty-content hash cannot authorize:** the SHA-256 of empty content is explicitly
  rejected. No zero-byte file can masquerade as owner authorization.
- **Caller-supplied digest rejected:** the resolver requires an approval file path
  (`-ApprovalFile`). It computes the SHA-256 internally. A bare digest parameter is not
  accepted.
- **Fingerprint must be recomputed:** the verifier independently computes the canonical
  fingerprint from the variant identity fields. Arbitrary placeholder values are refused.
- **Owner authorization master switch:** `ownerAuthorizationActive=false` in the contract
  structurally prevents the ACTIVATED classification regardless of other inputs.

## 7. Available Inert Tooling

The following tools are defined in `tools/release/`. They are **inert**: they classify,
verify, and emit evidence only. They cannot build, deploy, contact production, or execute
the drain.

| Tool | Purpose |
|---|---|
| `resolve_release_variant.ps1` | Classifies a release variant from explicit inputs per the fail-closed matrix. Requires `-ApprovalFile` (not digest). Recomputes fingerprint. Emits JSON evidence. Never activates. |
| `verify_activated_release.ps1` | Given a produced artifact evidence bundle, verifies variant identity, commit provenance, authorization digest (hash computed from file), and recomputed fingerprint. Refuses anything not fully authorized. Never activates. |
| `guard_tests_activated_variant.ps1` | Deterministic guard harness that proves the fail-closed matrix using inert test doubles. Separates PRODUCTION CONTRACT tests from SYNTHETIC TEST-ONLY authorization tests. Never contacts production. |

## 8. Authorized Activation Digest (committed contract)

The committed contract records the digest of the **authorized owner-approval marker** for
`ACTIVATED_VARIANT_1`. The digest value is the **approval identity digest**: SHA-256 of the
canonical approval identity payload (every approval field except `releaseVariantFingerprint`)
as defined in `docs/OWNER_APPROVAL_ARTIFACT_SCHEMA.md`. **The digest alone does not authorize
activation** — it is the comparison target for the separate approval artifact whose hash is
computed internally.

```
ACTIVATED_VARIANT_1_APPROVAL_DIGEST = NOT_SET  (no owner authorization active)
ACTIVATED_VARIANT_1_ALLOWED_ENVS    = ["production"]
OWNER_AUTHORIZATION_ACTIVE           = false
```

**GOVERNANCE CORRECTION (C1):** The empty-content SHA-256
(`E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`) is NOT used as
the authorized digest. It is explicitly rejected by both the resolver and verifier.

**GOVERNANCE CORRECTION (C2):** The resolver requires `-ApprovalFile <path>` and computes
the digest internally from the file's identity payload. A caller-supplied `-ApprovalDigest`
parameter is NOT accepted.

**GOVERNANCE CORRECTION (C3):** The verifier independently recomputes the
`releaseVariantFingerprint` from canonical fields (variantId, sourceCommit, buildTimeUtc,
approvalIdentityDigest, environment) using UTF-8 encoding with newline separators. Arbitrary
placeholder fingerprints are refused.

Because the actual owner-approval file is not committed (it is generated by the owner in the
authorization session), the presence of this committed digest does NOT create an activated
build. It only enables the resolver to later confirm that a supplied approval file carried
the authorized marker. And because `ownerAuthorizationActive=false`, even a matching digest
cannot currently authorize activation.

## 9. Provenance, Stale-Artifact Guard, and Identity

Any activated artifact produced in a future session must record, and `verify_activated_release.ps1`
must confirm:

- `variantId` = `ACTIVATED_VARIANT_1`
- `sourceCommit` = exact Git commit SHA of the activated build
- `buildTimeUtc` = build timestamp
- `approvalDigestSha256` = the approval identity digest (SHA-256 of the approval identity
  payload), computed internally by the resolver and recorded in the evidence bundle
- `releaseVariantFingerprint` = SHA-256 of the canonical variant identity — recomputed by the
  verifier from: `variantId + "\n" + sourceCommit + "\n" + buildTimeUtc + "\n" +
  approvalDigestSha256 + "\n" + environment` (UTF-8, newline-separated, no trailing newline)

`verify_activated_release.ps1` refuses (exit non-zero, `ACTIVATED = NO`) when:

- the variant id is missing or not `ACTIVATED_VARIANT_1`;
- the source commit does not match the currently approved/locked commit for this variant;
- the approval digest is missing or does not match the committed authorized digest;
- the approval digest is the empty-content SHA-256;
- the fingerprint is missing, is an arbitrary placeholder, or does not match the recomputed
  canonical value;
- the artifact evidence bundle is incomplete;
- `ownerAuthorizationActive=false` in the committed contract.

## 10. Default Release Invariant (must remain true)

```
DEFAULT_BUILD => DRAIN GATED/OFF
```

The intended invariant is proven by the guard harness in `guard_tests_activated_variant.ps1`
for every case in the fail-closed matrix. The harness separates:

- **PRODUCTION CONTRACT TESTS** (G1-G20, G25-G28, G29-G32): prove that
  `ownerAuthorizationActive=false` prevents activation under all input combinations.
- **SYNTHETIC TEST-ONLY TESTS** (G21-G24): prove the positive path works under a temporary
  resolver override with `ownerAuthorizationActive=true` and a synthetic test-only approval
  artifact that is cleaned up after verification.

## 11. Owner Approval Artifact Schema

The structure and validation rules for a future owner-approval artifact are defined in:

```
docs/OWNER_APPROVAL_ARTIFACT_SCHEMA.md
```

Key requirements:
- File-bound: the tool computes SHA-256 from file bytes internally.
- Schema-validated: must contain all required fields with correct types/values.
- Time-bounded: must include `expiresAtUtc` or explicit single-use semantics.
- Commit-bound: `approvedSourceCommit` must match the exact authorized commit.
- Environment-bound: `environment` must match the declared build environment.
- Fingerprint-verified: `releaseVariantFingerprint` must be recomputed from canonical fields.

## 12. What a Later Owner-Authorized Activation Session Must Answer

A future activation session may use this contract and tooling to deterministically answer:

1. Exact commit being activated → `sourceCommit` from evidence.
2. Exact release variant representing activation authority → `ACTIVATED_VARIANT_1`.
3. Inputs distinguishing that variant → the §5 positive authorization surface.
4. How accidental creation is prevented → default OFF + fail-closed matrix + guard tests.
5. How accidental execution is prevented → capability != authorization split + provably
   inert resolver + owner authorization master switch.
6. How default build is proven OFF → guard harness results.
7. How artifact provenance is proven → `verify_activated_release.ps1` recomputed fingerprint chain.
8. What owner approval is needed → the non-committed approval artifact matching the digest,
   with schema validation and fingerprint recomputation.
9. What production preflight must pass → a future production-preflight gate (see §13).
10. Exact stop conditions → the fail-closed matrix `NOT_AUTHORIZED` and `REFUSED` outcomes.
11. What telemetry/evidence is captured → evidence json produced by resolver + verifier.
12. What rollback/disable path exists → re-deploy the normal `NORMAL_GATED_OFF` variant;
    the resolver defaults to OFF, so removing activation inputs restores gated/OFF.
13. What proves shipped binary corresponds to approved commit → recomputed `releaseVariantFingerprint`.
14. What prevents stale activated binary reuse → stale-artifact guard (variant id + commit +
    fingerprint) in `verify_activated_release.ps1`.
15. What separate session authorizes actual build/ship/activation → a distinct
    owner-authorized session; this governance session does NOT authorize it.

## 13. Future Production Preflight (referenced, not performed)

Some preflight gates require production information that this session must not obtain.
Where a gate needs production data, it is recorded only as a **future activation-session
gate** and is not evaluated here. Explicitly deferred to the future authorized session:

- live production drain-state verification;
- live production edge-function health check;
- live production queue/bucket state.

These are named here so they are deterministic requirements of the future session, but they
are NOT run in this session (production contact is forbidden).

## 14. Boundary Statement

- This session corrected the governance contract and inert fail-closed tooling.
- This session did NOT create, ship, deploy, activate, or execute any activated release.
- This session did NOT contact production.
- This session did NOT create a real owner approval artifact.
- Activation requires a separate, explicit, owner-authorized session.

## 15. Authoritative Reference

- `tools/release/resolve_release_variant.ps1` — fail-closed variant classifier (corrected).
- `tools/release/verify_activated_release.ps1` — provenance / stale-artifact guard (corrected).
- `tools/release/guard_tests_activated_variant.ps1` — deterministic fail-closed proof (expanded).
- `docs/OWNER_APPROVAL_ARTIFACT_SCHEMA.md` — future approval artifact schema (new).
- `app/lib/config/app_config.dart` — existing compile-time `SYNC_DRAIN_ENABLED` seam
  (capability, default OFF).
