# PHASE P / GROUP B / S6 — PLATFORM SECURE DEVICE IDENTITY — IMPLEMENTATION GOVERNANCE

> This document is the **sole tracked governance output** of one governance-only session.
> It **freezes the future S6 implementation contract**. It performs **NO** S6 implementation.
> It does **not** generate keys, add production code, mutate Supabase, or activate any device gate.

---

## A. Session Contract

```text
SESSION =
PHASE_P_GROUP_B_S6_PLATFORM_SECURE_DEVICE_IDENTITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY_FAIL_CLOSED

TARGET_SLICE =
S6_PLATFORM_SECURE_DEVICE_IDENTITY

IMPLEMENT_S6 =
FALSE

AUTHORIZED_TRACKED_OUTPUT =
EXACTLY_ONE_NEW_GOVERNANCE_ARTIFACT

S6_IMPLEMENTATION_STARTED =
NO

PRODUCTION_MUTATION =
NO
```

This session creates exactly **one** new governance artifact:

```text
docs/PHASE_P_GROUP_B_S6_PLATFORM_SECURE_DEVICE_IDENTITY_IMPLEMENTATION_GOVERNANCE.md
```

No second governance file, no speculative correction report, no implementation file.

---

## B. Repository Identity

```text
ROOT =
C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze

BRANCH =
codex/i-tech-next-roadmap-freeze

AUTHORIZED_REMOTE =
github

AUTHORIZED_FETCH_URL =
https://github.com/sabere342-ai/muaman.worktrees.git

AUTHORIZED_PUSH_URL =
https://github.com/sabere342-ai/muaman.worktrees.git

LEGACY_REMOTE =
origin

LEGACY_ORIGIN_POLICY =
SACRED READ-ONLY — NEVER FETCH / PULL / PUSH / USE FOR RECOVERY / MODIFY / DELETE / RECONFIGURE
```

The legacy `origin` remote is **never contacted** during this session.

---

## C. Entry / Recovery Classification

```text
CASE_A_FRESH
```

Verified at session entry (recorded below):

```text
LOCAL_HEAD                                  = 5801cea40fa019f2206910075fda127ea739abba
REMOTE_TRACKING_HEAD (git rev-parse @{u})   = 5801cea40fa019f2206910075fda127ea739abba
DIRECT_GITHUB_REMOTE_HEAD (git ls-remote)   = 5801cea40fa019f2206910075fda127ea739abba
MERGE_BASE (git merge-base HEAD @{u})       = 5801cea40fa019f2206910075fda127ea739abba
AHEAD = 0
BEHIND = 0
TRACKED_WORKTREE = CLEAN
INDEX = EMPTY
ACTIVE_GIT_OPERATION = NONE (no MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG /
                           rebase-merge / rebase-apply / sequencer)
```

Pre-existing **untracked sacred evidence** (delivery archive, reports, `supabase/.branches/`,
`supabase/.temp/`) is present and remains **untouched**. No baseline substitution was performed.

Entry remote check (`git ls-remote github`) returned exactly `5801cea40fa019f2206910075fda127ea739abba`.

---

## D. Exact S5 Remote-Lock Baseline

The fresh S6-governance entry baseline is exactly the prior S5 implementation remote lock:

```text
S5_IMPLEMENTATION_REMOTE_LOCK =
5801cea40fa019f2206910075fda127ea739abba

S5_IMPLEMENTATION_PARENT =
fe03d6b98e1c824005c05a2df4803999dc010c01

S5_IMPLEMENTATION_MESSAGE =
feat: implement Group B S5 client entitlement integration
```

Verified via `git show`:

```text
5801cea40fa019f2206910075fda127ea739abba fe03d6b98e1c824005c05a2df4803999dc010c01 feat: implement Group B S5 client entitlement integration
```

The S6 governance commit's parent shall be `5801cea40fa019f2206910075fda127ea739abba`.

---

## E. Authority Chain

All four governing authorities were verified by commit + path + blob before writing this artifact.
Success criterion: `S6_GOVERNANCE_AUTHORITY = VERIFIED`.

### 5.1 Owner Order — GROUP_B_BEFORE_GROUP_D (Group D DECREED SECOND AND DEFERRED)

```text
COMMIT = 221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4
PATH   = docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md
BLOB   = 37518ed12f0402e059e099be8104b21b2d07c64f   ✓ VERIFIED
AUTHORITY = GROUP_B_BEFORE_GROUP_D
```

Group D remains **ORDERED_SECOND_AND_DEFERRED**.

### 5.2 Authority-Binding Correction

```text
COMMIT = 8fc4be8ea06fcff5400b79dbebb373c038738ecf
PATH   = docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md
BLOB   = 57e0f9c393ea9ef3484a5312612f7703509747af   ✓ VERIFIED
```

### 5.3 Group B Master Plan

```text
COMMIT = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
PATH   = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
BLOB   = 6bb57e90f3704a9cdee691b19c45c8107b6207af   ✓ VERIFIED
```

Master Plan S6 definition, quoted faithfully:

```text
S6 Platform secure device identity
   → per-install keypair
   → Android Keystore
   → Windows DPAPI
   → proof-of-possession
   → dependencies: S4 + S5
```

### 5.4 P-OD13 Device Trust Authority

```text
COMMIT = 8d27878a69cbb6c6f440c28f4f55f3ed323312d4
PATH   = POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md
BLOB   = e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a   ✓ VERIFIED
```

Core security objective preserved:

```text
VALID EMPLOYEE EMAIL + PASSWORD ALONE
MUST NOT BE SUFFICIENT
TO ACCESS SHOP BUSINESS DATA
FROM A NEW UNTRUSTED DEVICE.
```

Device trust remains **server-authoritative**. S6 must not create client-only trust.

**Failure rule:** none of the above failed its existence/path/blob check, and none materially
conflicts with S6. `S6_GOVERNANCE_AUTHORITY = VERIFIED`.

---

## F. S4 + S5 Dependency Proof

S6 depends on BOTH S4 and S5. All required commits were verified as **ancestors of entry HEAD**
(`git merge-base --is-ancestor`.

### S4

```text
S4_GOVERNANCE           = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5   IS_ANCESTOR = YES
S4_GOVERNANCE_CORRECTION= 5309749995244c8bfb423b46d897150b839c1f81   IS_ANCESTOR = YES
S4_IMPLEMENTATION       = b8889bf59d65037915fcec618f06fc1c1a49ae40   IS_ANCESTOR = YES
```

Current S4 migration file:

```text
supabase/migrations/20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql
```

Blob at the S5 baseline (verified, not assumed):

```text
95f662dd0b6ba86c453cfb16c2ecd1eec910c65a   ✓ VERIFIED
```

### S5

```text
S5_GOVERNANCE            = fe03d6b98e1c824005c05a2df4803999dc010c01   IS_ANCESTOR = YES
S5_IMPLEMENTATION        = 5801cea40fa019f2206910075fda127ea739abba   IS_ANCESTOR = YES
```

S5 governance artifact:

```text
docs/PHASE_P_GROUP_B_S5_CLIENT_ENTITLEMENT_INTEGRATION_IMPLEMENTATION_GOVERNANCE.md
```

Expected governance blob:

```text
7857730fca6b5ac355d208d859516f1bea4b2f89   ✓ VERIFIED
```

S5 is **CLOSED** and must not be reopened by S6. No S5 entitlement semantics are redesigned here.

---

## G. Current Repository Forensics

Actual inspected surfaces (read-only) and exact findings. This section is evidence-based, not assumed.

### G.1 Device identity sources

- `app/lib/licensing/device_identity.dart` — `DeviceIdentity` computes a salted **SHA-256**
  fingerprint (hardware/SSAID components + fixed app salt). Returns a digest; no private key.
- `app/lib/platform/device_identity_provider.dart` — injectable provider; Windows =
  MachineGuid + CPU ProcessorId + WMI Baseboard SerialNumber; Android = SSAID via
  `itech.app/device_identity` channel; sentinel fallback elsewhere. Raw identifiers never
  leave the process.
- `MainActivity.kt` exposes `itech.app/device_identity#getSsaid` and the
  `itech.app/secure_storage` channel.

### G.2 Server public-key foundation (S1)

- `devices.public_key TEXT` (public only) — S1 comment: *"public key material only ...
  Proof-of-possession enforced in later slice."*
- `register_device(p_shop_id, p_installation_id, p_platform, p_device_name)` (S4 rewrite)
  does **NOT** accept or bind `public_key`. **No RPC currently binds/updates `devices.public_key`.**

### G.3 S4 PoP server skeleton

- Tables: `device_challenges`, `device_assertions`.
- Functions: `s4_create_challenge(UUID shop, UUID device, TEXT challenge, INTEGER ttl=300)`,
  `s4_assert_request(UUID challenge_id, TEXT signature, TEXT format='ed25519')`,
  `s4_current_request_device_is_approved(UUID shop)`, `s4_enforcement_config`,
  `s4_device_gate_enabled()`, `s4_set_device_gate_enforcement(boolean)`.
- Ed25519 verification is described as running **outside PostgreSQL** (Edge Function /
  Deno WebCrypto). See §J / Gap S6-E.

### G.4 S4 device enforcement is OFF

- `s4_enforcement_config.device_gate_enabled = false` (default), not client-writable,
  toggled only by service-role `s4_set_device_gate_enforcement`. Confirmed OFF and intentional.

### G.5 Android native secure storage

- `app/lib/licensing/secure_store_android.dart` → `KeystoreChannelSecretStore` (+
  `KeystoreActivationStore`) over `itech.app/secure_storage`.
- `MainActivity.kt#securePrefsOrNull()` → **`EncryptedSharedPreferences`** (
  `PrefKeyEncryptionScheme.AES256_SIV`, `PrefValueEncryptionScheme.AES256_GCM`) with master key
  from `MasterKeys.getOrCreate(AES256_GCM_SPEC)` in the Android Keystore. **Fail-closed**;
  `null` on init failure → error, no plaintext fallback. This is **Keystore-encrypted-at-rest
  symmetric AES-GCM**, **not** an asymmetric Keystore Ed25519 key handle.

### G.6 Windows secure storage

- `app/lib/licensing/secure_store.dart` → `SecureActivationStore` uses PowerShell + DPAPI:
  `CryptProtectData`/`CryptUnprotectData` at **`LocalMachine` scope**, invoked by writing
  **plaintext bytes to a temp file** (`...\itech_plain_$pid.bin` / `...\itech_enc_$pid.bin`).
- `.hmac_secret` is stored as a plaintext sibling file; HMAC secret is generated from
  `DateTime.now().microsecondsSinceEpoch` (weak RNG, not CSPRNG).
- Non-Windows path falls back to **XOR obfuscation** (explicitly non-secure).
- **Not suitable as-is** for S6 private-key storage (see §M).

### G.7 Licensing / entitlement (S5)

- `cloud_licensing_repository.dart` — Supabase RPC gateway (verify_license_entitlement,
  start_trial, register_device, activate_device, deactivate_device, get_device_list).
- `cloud_licensing_service.dart` — `allowsWrites` gated on `entitled || entitledCached`
  (line 93–95); REVOKED-precedence fail-closed on malformed security state.
- `entitlement_cache.dart` — `kEntitlementCacheSchemaVersion = 1`; `isCompatibleSchema()`
  exact equality; `blocksWrites` revocation-aware; grace values live in `OfflineGracePolicy`.
- `cloud_session_resume.dart`, `seller_session_provisioning.dart` — bootstrap/resume call
  licensing initialize/register/activate; fail-closed on resolution/bind error.
- `pubspec.yaml` deps include `crypto`, `cryptography`, `cbor`, `supabase_flutter`.

### G.8 Ed25519 occurrences (repo search)

- Legacy entitlement token verification: `app/lib/licensing/entitlement_token.dart:270`
  uses the Dart `cryptography` package (`KeyPairType.ed25519`) to **verify a server-signed
  legacy entitlement token** against embedded `_trustedKeys`. This is the
  **LEGACY ENTITLEMENT-TOKEN ED25519** path (S9 owns its retirement). Not S6 device PoP.
- Migration `20260820000034` uses `p_signature_format ... 'ed25519'`.
- No live Edge Function verifies Ed25519/WebCrypto against `devices.public_key`.

---

## H. S6 Security Objective

S6 provides a **per-install cryptographic identity** and a **server-verified
proof-of-possession** seam such that, composed with S4 + S5 + membership/role/license,
device trust is **server-authoritative**. It exists to make true P-OD13's core objective:

```text
VALID EMPLOYEE EMAIL + PASSWORD ALONE
MUST NOT BE SUFFICIENT
TO ACCESS SHOP BUSINESS DATA
FROM A NEW UNTRUSTED DEVICE.
```

S6 does **not** weaken any other factor. No factor (auth, membership, role, device trust,
license/entitlement, tenant authorization) replaces another.

---

## I. Current Device Identity Classification

The existing `DeviceIdentity` is:

```text
compatibility / fingerprint metadata
SHA-256 over hardware/SSAID components
```

It is **NOT** a private key, a proof-of-possession identity, a server authorization proof,
or a substitute for S6. It is **not removed** by S6. **A hardware fingerprint is never
treated as a trusted device or as a possession proof** (§Q / AC18).

---

## J. Public-Key Enrollment Contract (Gap S6-A RESOLUTION)

**Finding (verified):** `devices.public_key` exists (S1) but `register_device(...)` does not
accept or bind a public key, and **no RPC currently binds/updates `devices.public_key`**.
Therefore a **new additive server seam is genuinely necessary** for a secure enrollment.

**Bounded additive correction (future S6 prerequisite):** an additive, replay-safe migration
`00035` is governed to introduce a **narrow enrollment RPC** that accepts a canonicalized
public key and binds it **exactly once** to a single `devices` row. It must satisfy:

- private key never uploaded (public only);
- public key **canonicalized** to an exact deterministic representation (see §O/N);
- **no silent replacement** of an already-trusted (ACTIVE) public key — re-enrollment and
  rotation are **explicit** and governed;
- **cross-shop** and **cross-user** key substitution **denied**;
- terminal REVOKED / LOST / REJECTED devices **cannot** regain trust by key overwrite;
- the binding is `(device_id, shop_id, user_id, installation_id)`-scoped.

**No edit to migration `00034`.** `00035` (if created by the separately-authorized S6
implementation) is the only permitted additive path, and only for this exact gap. This
governance session itself creates **zero** migration files.

---

## K. Per-Install Key Lifecycle Contract

```text
FIRST INSTALL / NO KEY            -> generate ONE cryptographically secure keypair
NORMAL RESTART                    -> load SAME installation keypair; DO NOT regenerate
SECURE STORE LOST / APP REINSTALL -> old private key unavailable; generate NEW per-install
                                     identity; server treats as new/re-enrollment;
                                     governed re-approval required; NEVER silently inherit
                                     old trust
CORRUPT KEY MATERIAL              -> FAIL CLOSED; do not fabricate valid identity;
                                     re-enrollment path
SERVER PUBLIC KEY MISMATCH        -> FAIL CLOSED; no silent overwrite
DEVICE REVOKED / LOST / REJECTED  -> local private-key presence cannot restore authorization
```

Private key absolute invariants:

```text
NEVER logged
NEVER in error strings
NEVER in analytics
NEVER in SQLite
NEVER in AppSettings
NEVER in entitlement cache
NEVER uploaded to server
NEVER in backup/export
NEVER in plaintext production files
```

Public key is not secret and may be transmitted **only** through the governed enrollment path
(§J).

---

## L. Android Keystore Contract

**Finding:** current storage is EncryptedSharedPreferences + Keystore master key (AES-GCM/SIV),
fail-closed, no plaintext fallback. It is **not** currently an asymmetric Keystore Ed25519 key.

**Governed Android decision (class 2 selected unless capability evidence justifies class 1):**

```text
2. cryptographically generated Ed25519 private material encrypted at rest through the
   existing Keystore-backed secure secret store, with NO claim that the Ed25519 private key
   itself is non-exportable.
```

The S6 implementation must NOT claim `hardware-backed / StrongBox-backed / non-exportable
Ed25519 private key` unless platform evidence for the **target Android range** actually proves
it. Documented for the chosen design:

```text
what is protected       : the Ed25519 private material and the per-install identity
where it lives          : Keystore-encrypted storage (EncryptedSharedPreferences or a
                          dedicated Keystore-backed asymmetric key if capability is proven)
whether it enters Dart  : only as transient signing material, never persisted/logged
whether it is exportable: MUST be reported truthfully (default: exportable; class-1 only if
                          actual non-exportable hardware keystore is proven)
what happens on reinstall: old identity unavailable -> new identity + re-enrollment
what happens on Keystore invalidation: fail closed -> re-enrollment
what fails closed       : any read/decrypt/init failure denies S6 identity usage
```

**No plaintext fallback on Android production.**

---

## M. Windows DPAPI Contract

**Finding:** `SecureActivationStore` is **not safe to reuse as-is** for S6 private keys: it
(a) invokes DPAPI by writing **plaintext bytes to a temp file**; (b) uses **`LocalMachine`
scope**; (c) stores `.hmac_secret` in plaintext with a **weak RNG**; (d) has a non-Windows
**XOR obfuscation** fallback.

**Governed decision:** S6 needs a **dedicated DPAPI `SecureSecretStore`** implementation
for Windows device private-key storage. Future production contract:

```text
DPAPI-protected at rest
no plaintext persistent key file
no plaintext private-key temporary file (no temp-file DPAPI workaround)
CurrentUser scope (NOT LocalMachine) for per-user device identity
CSPRNG-derived identity material (never timestamp-derived)
no SQLite storage
no backup inclusion
fail closed on decrypt/integrity failure
no insecure fallback on Windows production (no XOR/obfuscation for a device key)
```

**Do not claim TPM / non-exportability unless actually implemented.**

---

## N. Cryptographic Algorithm + Key Format

- The committed S4 seam binds its proof to **Ed25519 / WebCrypto**. No committed
  incompatibility was found. Therefore **option A is selected**:

```text
A. bind S6 device PoP to the existing Ed25519 S4 protocol.
```

- Key format: RFC 8032 Ed25519. Public key = raw 32-byte point; canonical representation =
  base64url (no padding) of the raw bytes. Private material = 32-byte seed (or 64-byte
  expanded) held only in protected local storage.

**Critical P-OD12 distinction (must be preserved in every downstream artifact):**

```text
LEGACY ENTITLEMENT-TOKEN ED25519   ≠   S6 DEVICE PROOF-OF-POSSESSION ED25519
```

- Legacy path = server-signed entitlement token verified in `entitlement_token.dart`
  (S9 owns its evidence-gated retirement).
- S6 path = client proves possession of its per-install private key whose public key is
  server-bound.
- S6 does **not** delete/retire the legacy Ed25519 path. S9 is not pre-implemented here.

---

## O. Canonical PoP Challenge / Signature Protocol

The server must NOT accept an ambiguous or caller-chosen message. The signature is over a
**canonical UTF-8 envelope** (JSON with a **fixed, documented key order** and no
whitespace/duplicate keys), exactly:

```text
{
  "protocol": "itech-s6-pop",
  "version": 1,
  "challenge_id": "<uuid>",
  "challenge": "<server challenge text/nonce>",
  "shop_id": "<uuid>",
  "device_id": "<uuid>",
  "user_id": "<uuid>",
  "installation_id": "<uuid>",
  "expires_at": "<RFC3339 UTC>",
  "purpose": "device-proof"
}
```

Byte layout: UTF-8 encoded bytes of this canonical JSON are signed; both signing (Dart /
native) and verifying (Deno WebCrypto) MUST operate on the identical byte sequence. A
**golden vector** (see matrix #28) pins byte-identical behavior across implementations.

**Gap S6-B — Challenge freshness / replay (RESOLVED):** the current `s4_create_challenge`
accepts a **caller-supplied `challenge` text**. The future S6 verifier must **never** accept
a caller-chosen ambiguous challenge. The future flow:
- server issues the challenge (server-generated nonce and expiry), caller supplies only
  `shop_id` / `device_id`;
- canonical envelope binds protocol/version, challenge_id, nonce, shop_id, device_id,
  user_id, installation_id, expiry;
- reusing a signature from a prior challenge, replaying the same challenge text, or
  transplanting a proof across device/shop/user/install all fail because the bound fields
  mismatch or the challenge is single-use.

Replay rejection is enforced server-side: **single-use** challenge (already-consumed fails)
and **expiry** (expired fails), plus the canonical-field binding. A future additive verifier
must reject duplicate challenge-text reuse with the same nonce/challenge_id.

---

## P. S4 Challenge / Assertion Seam Viability

The S4 seam is viable as the **server-authoritative record**, but the **contract must be
focused**:

- `s4_create_challenge` must be hardened (additively) so the challenge/nonce is
  **server-generated**, not caller-supplied, and bound to shop/device at creation.
- `s4_assert_request` (service role only) already: consumes the challenge single-use
  (`used_at`), rejects expiry, requires `device.status = 'ACTIVE'`, records
  `device_assertions` with `is_request_bound=true`, and publishes
  `set_config('s4.asserted_device'/'s4.request_device_id')`. It is correct as a
  **server-authoritative assertion recorder**; the Ed25519 verification is performed by an
  (future) Edge Function before this call.

The seam does not currently perform the signature verification itself — the future verifier
Edge Function owns that step and then calls `s4_assert_request` under the service role.

---

## Q. Owner-Approval vs PoP State Ordering (Gap S6-D RESOLVED)

**Finding (verified):** `s4_assert_request` requires the device already be `status = 'ACTIVE'`.
`register_device` always ends a new enrollment `PENDING_APPROVAL`, and `s4_approve_device`
moves `PENDING_APPROVAL -> ACTIVE` **without requiring a proof**. Consequently the current
ordering is *approve-then-assert*, so:

```text
ACTIVE  ⇏  "proof passed"
proof passing currently REQUIRES an already-ACTIVE device
```

The governance **never claims** `ACTIVE/trusted == proof-passing`. This is a real ordering
constraint. The safe future lifecycle must freeze a **non-circular** order. The governed
approach:

```text
enroll (bind public key; PENDING_APPROVAL)
  -> owner approval (ACTIVE)            [P-OD13 OWNER APPROVAL]
  -> on first business request, client proves possession (PoP)
  -> assertion recorded (request-bound) [P-OD13 PROOF OF POSSESSION]
  -> only then may live enforcement require the proven, request-bound device
```

If enforcing "PoP before ANY ACTIVE business access" is required, that needs the **bounded
additive `00035`** correction: make `s4_create_challenge` usable for a PENDING device and
make the future verifier/assertion path not depend on a pre-ACTIVE status — while still
requiring **owner approval before business-data access**. S6 documents this as a bounded
prerequisite/correction rather than weakening P-OD13. No circular claim is made.

---

## R. Request-Bound Enforcement / GUC Viability (Gap S6-C RESOLVED)

**Finding (verified):** `s4_assert_request` publishes the context via

```text
set_config('s4.asserted_device', 'true', true)
set_config('s4.request_device_id', <id>::text, true)
```

The third argument (`true`) means the GUC is **transaction-local**. It survives only the
current PostgreSQL **transaction** and does **not** authenticate a later, independent
PostgREST business request. A GUC set in one RPC does not carry into a separate later request.

Therefore:

```text
REQUEST_BOUND_LIVE_ENFORCEMENT_READY = NO
DEVICE_GATE_ENABLED                  = FALSE
```

S6 identity / keypair / PoP **may proceed**, but **live business-data device-gate
enforcement must REMAIN OFF** until a separately proven, end-to-end **request-bound**
authorization path exists that cannot be bypassed. No silent overclaim; no client-only
substitute (§X / AC22). Existing legitimate clients are never bricked.

---

## S. S5 Entitlement Composition

S5 is complete and preserved. S6 consumes it, does not redesign it:

```text
server entitlement authority
REVOKED precedence
is_revoked / revoked_at propagation
cache schema compatibility checks (kEntitlementCacheSchemaVersion = 1, exact equality)
TRIAL grace = 0d
PAID grace = 7d
PERPETUAL compatibility grace = 14d
revoked/expired/suspended never overridden by grace
allowsWrites only for entitled / entitledCached
```

Composition (no factor replaces another):

```text
AUTH + MEMBERSHIP + ROLE + DEVICE TRUST + LICENSE / ENTITLEMENT + SERVER TENANT AUTHORIZATION
```

---

## T. Future Exact File Allowlist

This governance session modifies **no** implementation file. It freezes the exact future S6
implementation allowlist **after forensics**. No "and any other relevant files",
"as needed", "etc.", or "implementation may decide later".

**Client surfaces (candidates subject to S6-scope justification in the S6 implementation
session):**

```text
app/lib/licensing/device_identity.dart                  (new per-install crypto identity integration)
app/lib/platform/device_identity_provider.dart          (if needed to source/sign per-install identity)
app/lib/licensing/secure_store.dart                     (new Windows DPAPI SecureSecretStore)
app/lib/platform/secure_secret_store.dart               (interface reused/extended)
app/lib/licensing/secure_store_android.dart             (reuse Keystore secret store)
app/lib/licensing/cloud_licensing_repository.dart       (add S6 enrollment/proof RPC calls, narrow)
new narrowly-scoped S6 client identity/proof classes
new S6 tests
Android native secure-storage MethodChannel handler      (only if an asymmetric Keystore key is
                                                          selected, or to add a signing method)
```

**Server surfaces (ONLY if current-state evidence proves required):**

```text
possible dedicated PoP proof-verifier Edge Function — REQUIRED:
   No live verifier exists (Gap S6-E = NO). A new, narrow Deno Edge Function is the governed
   home for Ed25519/WebCrypto verification + server-authoritative s4_assert_request.

possible additive migration 00035 — REQUIRED for secure enrollment binding (Gap S6-A/J) and,
   if PoP-before-ACTIVE is required, a bounded ordering correction (Gap S6-D/Q). Additive /
   replay-safe / limited to the exact S6 gaps.
```

**Doctrine:**

```text
NO SCHEMA CHANGE unless proven necessary.
NO RLS CHANGE unless proven necessary.
NO S4 00034 EDIT under any circumstance.
```

The S6 implementation session is a separate authorization. This governance session creates
**zero** migration files.

---

## U. Exact Test / Security Matrix

`S6_GOVERNED_SCENARIOS = 30` (one integer; no `>= N`, no merging of security cases).

```text
 1. First install creates exactly one per-install identity.
 2. Restart reuses same identity.
 3. Concurrent first-load cannot create two conflicting identities.
 4. Reinstall / secure-store loss creates new identity and requires re-enrollment.
 5. Corrupt private material fails closed.
 6. Private key never appears in server registration payload.
 7. Private key never appears in cache/AppSettings/SQLite.
 8. Public key is stable and canonical.
 9. Wrong private key fails verification.
10. Tampered signed payload fails.
11. Expired challenge fails.
12. Consumed challenge replay fails.
13. Duplicate challenge-text replay cannot reuse an old signature.
14. Wrong challenge_id fails.
15. Cross-device proof fails.
16. Cross-shop proof fails.
17. Cross-user proof fails.
18. Revoked device proof cannot restore trust.
19. LOST device proof cannot restore trust.
20. REJECTED device proof cannot restore trust.
21. New unapproved device cannot gain business access merely from credentials.
22. Hardware fingerprint alone cannot satisfy PoP.
23. installation_id alone cannot satisfy PoP.
24. Android secure-store failure fails closed.
25. Windows DPAPI failure fails closed.
26. Android signing/verifying interoperability with Deno WebCrypto.
27. Windows/Dart signing/verifying interoperability with Deno WebCrypto.
28. Canonical payload golden vector is byte-identical across implementations.
29. No production plaintext fallback.
30. S5 entitlement behavior remains unchanged.
```

---

## V. Regression Gates

Future S6 implementation must run targeted + regression gates. Preserved baseline:

```text
S1 pgTAP = 46 PASS
S2 pgTAP = 88 PASS
S3 pgTAP = 25 PASS
S4 pgTAP = 50 PASS
```

S5:

```text
s5_client_entitlement_integration_test.dart = all 27 existing assertions/tests PASS
```

Also:

```text
app/test/licensing/              all tests PASS
session_resume_binding_test.dart all PASS
seller_login_flow_test.dart      all PASS
flutter analyze                  = 0 errors
full flutter test                = 0 failures
```

Prior S5 full-suite baseline: **1590 PASS**. S6 must not reduce coverage by
deleting/weakening tests; added tests increase the total accordingly. If the new verifier
Edge Function is created, require **deterministic Ed25519 WebCrypto interoperability tests**.
If Android native code changes, require Android compile/test proof for the actual surface.
If Windows DPAPI changes, require Windows-targeted proof. No physical-device-only security
claim may be reported as proven if it was not actually tested on hardware.

---

## W. Failure / Recovery / Key Rotation Semantics

Defined safe behavior (from §K plus operational cases):

```text
secure-store read failure        -> fail closed (identity unavailable), governed re-enrollment
secure-store write failure       -> fail closed; do not persist partial identity
partial first-generation crash   -> retry generates ONE identity; no duplicate/conflicting rows
public key registered but private key lost -> re-enrollment, no silent reuse of old trust
private key created but server registration failed -> discard/retry; never partial trust
server public-key mismatch       -> fail closed; no silent overwrite
duplicate enrollment             -> enforce single binding (device/shop/user/install-scoped)
key rotation                     -> explicit, governed; not silent
device reinstall                 -> new identity; re-enrollment
device transfer                  -> explicit re-enrollment; no silent inheritance
backup restoration onto another machine -> new/untrusted; re-approval
cloned database                  -> public key + install binding must still hold; no bypass
clock change                     -> server freshness (expires_at) is authoritative
offline startup                  -> S6 identity may load locally; PoP/trust requires server
network failure during PoP       -> fail closed; retry, never fabricate trust
challenge expiration during signing -> fail closed; acquire a fresh challenge
```

Fail-safe rule (inviolable):

```text
failure may require re-enrollment,
but failure must never fabricate device trust.
```

No automatic overwrite of a trusted server key.

---

## X. Deployment + Enforcement Boundary (Device-Gate Activation Boundary)

S6 governance cleanly separates:

```text
S6 IDENTITY / KEYPAIR / PoP IMPLEMENTATION
```
from
```text
LIVE BUSINESS-DATA DEVICE-GATE ACTIVATION
```

It is **NOT** authorized to call `s4_set_device_gate_enforcement(true)` merely because a
signature verifies. Live enforcement activation requires proof that the **actual
business-data request** is bound to the proved device (not merely that a proof happened in an
earlier unrelated RPC).

Current governing truth:

```text
REQUEST_BOUND_LIVE_ENFORCEMENT_READY = NO
DEVICE_GATE_ENABLED                  = FALSE
```

Activation is **DEFERRED**. No silent security overclaim. No client-only substitute.

---

## Y. Explicit Forbidden Scope (Non-Goals)

S6 does **not** own:

```text
Owner device-management UI                 -> S7
tamper/cache/clock convergence             -> S8
legacy entitlement Ed25519 retirement      -> S9
full CASE 1–20 convergence                 -> S10
production deployment                      -> S11
Group B closeout                           -> S12
Group D                                    -> DEFERRED (ordered second and deferred)
```

Also:

```text
no payment gateway
no Play Billing
no Stripe
no Paymob
no new commercial tier design
no Android release publication
no iOS implementation
```

---

## Z. Acceptance Criteria + Successor Boundary

### Acceptance criteria (frozen for the S6 implementation session)

```text
AC01  Per-install cryptographic identity exists.
AC02  Private key never leaves local protected storage except transient signing use required by implementation.
AC03  Public key has deterministic canonical representation.
AC04  Restart reuses identity.
AC05  Reinstall/secure-store loss becomes a new governed identity.
AC06  Server binding is shop/user/device scoped.
AC07  Public key cannot be silently replaced on terminal/trusted device.
AC08  Proof uses the private key corresponding to server-bound public key.
AC09  Challenge replay fails.
AC10  Cross-device replay fails.
AC11  Cross-shop replay fails.
AC12  Cross-user replay fails.
AC13  Expired challenge fails.
AC14  Tampered payload/signature fails.
AC15  Android production persistence is Keystore-protected with no plaintext fallback.
AC16  Windows production persistence is DPAPI-protected with no plaintext private-key temp file.
AC17  Security properties reported truthfully; no unsupported hardware/non-exportability claim.
AC18  Current hardware fingerprint is not authorization proof.
AC19  Credentials alone cannot establish trusted-device state.
AC20  Revoked/lost/rejected state cannot be bypassed by local key possession.
AC21  S5 entitlement semantics remain unchanged.
AC22  S4 enforcement switch remains OFF unless request-bound live gate is separately proven safe.
AC23  No private key/secrets appear in logs/cache/database/backups.
AC24  Android/Dart ↔ Deno Ed25519 interoperability proven.
AC25  Windows/Dart ↔ Deno interoperability proven.
AC26  All governed S6 scenarios pass (S6_GOVERNED_SCENARIOS = 30).
AC27  S1/S2/S3/S4 regression pgTAP passes.
AC28  S5 regression passes.
AC29  flutter analyze has zero errors.
AC30  full Flutter suite has zero failures.
```

### Successor boundary

After this S6 governance remote-lock:

```text
S6_IMPLEMENTATION = NOT_STARTED
```

The **only** next authorized entry point is a **separate**
`PHASE_P_GROUP_B_S6_PLATFORM_SECURE_DEVICE_IDENTITY_IMPLEMENTATION` session bound to:

```text
the exact S6 governance commit
+ the exact governance artifact blob
+ the existing authority chain
+ S4 implementation
+ S5 implementation
```

S7 and Group D are **not** started by this session.

> **END OF S6 IMPLEMENTATION GOVERNANCE DOCUMENT.**
