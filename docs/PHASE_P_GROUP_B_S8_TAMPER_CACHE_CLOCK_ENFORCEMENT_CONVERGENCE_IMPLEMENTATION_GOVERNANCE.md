# Phase P — Group B — S8 Tamper / Cache / Clock Enforcement Convergence

## Implementation Governance

**Document purpose:** Freeze the exact future implementation contract for Group B **S8 — Tamper / Cache / Clock Enforcement Convergence** against the committed server-authoritative entitlement, device-trust, and secure-identity system. This is a **governance-only** artifact. It does **NOT** implement S8. It authorizes nothing beyond the exact contract recorded here.

---

## A. Session identity

```text
SESSION =
PHASE_P_GROUP_B_S8_TAMPER_CACHE_CLOCK_ENFORCEMENT_CONVERGENCE_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY_FAIL_CLOSED

AUTHORIZED_UNIT =
S8 — TAMPER / CACHE / CLOCK ENFORCEMENT CONVERGENCE

SESSION_NATURE = GOVERNANCE ONLY
AUTHORIZED_TRACKED_OUTPUT = EXACTLY_ONE_NEW_GOVERNANCE_ARTIFACT (this file)

EXPECTED_SUCCESS_TOKEN =
PASS_PHASE_P_GROUP_B_S8_TAMPER_CACHE_CLOCK_ENFORCEMENT_CONVERGENCE_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
```

**Non-authorizations (this session does NOT authorize):**

```text
S8_IMPLEMENTATION_STARTED = NO
S9_STARTED               = NO   (legacy Ed25519 retirement — separate slice)
S10_STARTED              = NO   (test / security convergence — separate slice)
S11_STARTED              = NO   (deployment / verification)
S12_STARTED              = NO   (Group B closeout)
GROUP_C_STARTED          = NO
GROUP_D_STARTED          = NO   (DEFERRED — Group B first)
PRODUCTION_MUTATION      = NONE
```

---

## B. Repository identity

```text
ROOT   = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze

AUTHORIZED_REMOTE = github
EXPECTED_GITHUB_URL = https://github.com/sabere342-ai/muaman.worktrees.git
VERIFIED_GITHUB_URL = https://github.com/sabere342-ai/muaman.worktrees.git   (MATCH)
```

**Legacy remote `origin`** (a local filesystem path) is **SACRED / READ-ONLY**. No Git network operation was and must be performed against `origin` (no fetch / pull / push / ls-remote / remote update / remote prune / set-url / rename / remove). All network Git operations target `github` only.

---

## C. Entry / Recovery classification

Verified before any mutation, on the authorized remote `github` only (`git fetch github codex/i-tech-next-roadmap-freeze`):

```text
LOCAL_HEAD          = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
TRACKING_HEAD       = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
DIRECT_REMOTE_HEAD  = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
MERGE_BASE          = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
AHEAD               = 0
BEHIND              = 0
Index state         = clean (empty staged diff)
Tracked worktree    = clean (no tracked modifications)
Active git op       = none (no MERGE_HEAD / REBASE_HEAD / CHERRY_PICK_HEAD / BISECT_LOG)
```

**Classification: CASE_A_FRESH** — proceed. No recovery action required. No reset/rebase/amend/clean performed.

All untracked items are pre-existing **sacred evidence** (see Section U) and remain untouched, un-staged, un-deleted.

---

## D. Exact authority register

Authority is reconstructed from committed material, not from this prompt alone.

```text
ROADMAP_PLAN        = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md (commit 9ecdc38) — S8 listed as
                      "Tamper / cache / clock enforcement (server revalidation wiring;
                       monotonic timing; cache integrity; bounded controls)" → dependencies S3, S5
ROADMAP_ORDER       = GROUP B FIRST; GROUP D SECOND/DEFERRED (committed OWNER ORDER chain)
TAMPER_MANDATE      = P-OD11 "reasonable production hardening — clock rollback/manipulation,
                      stale entitlement cache, cache tampering, entitlement replay, server
                      revalidation, fail-safe behavior, offline-grace abuse"
```

**Confirmed S8 is the immediate successor of S7** and owns exactly:

```text
S8 OWNS = tamper / cache / clock enforcement convergence
```

S9 (legacy Ed25519 retirement) and S10 (test/security convergence) are explicitly separate and are **NOT** absorbed into S8.

Known milestone hashes resolved from Git (all match expected):

```text
S4_IMPLEMENTATION = b8889bf59d65037915fcec618f06fc1c1a49ae40
S5_GOVERNANCE     = fe03d6b98e1c824005c05a2df4803999dc010c01
S5_IMPLEMENTATION = 5801cea40fa019f2206910075fda127ea739abba
S6_GOVERNANCE     = b4e95e43863d82916ffe30c45f6e438a2fe0b1cc
S6_IMPLEMENTATION = 69218da499ed004f5dc378c6d378add574c592b4
S7_GOVERNANCE     = 665d99607eb693078cac80ae81ef324d866a2f05
S7_IMPLEMENTATION = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
```

No fabricated or unresolved hash is relied upon.

---

## E. Predecessor S1→S7 binding

The committed linear Group-B chain (governance → implementation per at least S5/S6/S7) is intact:

```text
9ecdc38 plan Phase P Group B
45018ee govern S1 … 334d1ad implement S1
a4fcada govern S2 … 85e4315 implement S2
7d05313 govern S3 … 62af446 implement S3
2df4dc7/5309749 govern/correct S4 … b8889bf implement S4
fe03d6b govern S5 … 5801cea implement S5
b4e95e4 govern S6 … 69218da implement S6
665d996 govern S7 … a67996a implement S7   ← CURRENT HEAD
```

**S7 baseline (verified):**

```text
S7_IMPLEMENTATION_COMMIT = a67996aeb62da483f2d900ecc206ca1b4e6f5cb2
SUBJECT                   = feat: implement Group B S7 owner device management
S7_GOVERNANCE_PARENT      = 665d99607eb693078cac80ae81ef324d866a2f05
FILES_CHANGED             = 9  (app/ Dart only)
SQL_DELTA                 = NONE
MIGRATION                 = NONE
SACRED_FILES              = NONE
```

S7 is treated as a **closed predecessor**. S8 preserves S7 unless repository truth proves a required interoperability seam (none found; S8 is a client-side convergence of existing entitlement/cache/clock machinery).

---

## F. Current repository forensic findings

Read-only audit of HEAD (current committed implementation), not restatement of prior reports.

### F.1 Entitlement state

- `EntitlementSnapshot` (`entitlement_cache.dart`) models shop scope, license status, trial/paid/perpetual, revocation (`isRevoked`/`revokedAt`), expiry, and three persisted timestamps: `serverTimeAtVerification`, `localWallClockAtVerification`, `lastSuccessfulVerificationAt`.
- Schema versioning exists: `kEntitlementCacheSchemaVersion = 1`; `isCompatibleSchema()` gates consumption; unknown/future schema routes to `staleOffline` (fail-closed) in `_resolveStateFromCache` (`cloud_licensing_service.dart`).
- REVOKED precedence is enforced in both server (`_resolveStateFromServer`, H-Gap-1) and cache (`_resolveStateFromCache`) paths regardless of grace. `isCachedNonEntitled` and `blocksWrites` also respect REVOKED / SUSPENDED / EXPIRED / inactive-trial.
- `_isMalformedSecurityState` fails closed on a server result that claims a license with no usable entitlement signal.
- Offline grace (already correct, predecessor-floored): TRIAL = 0, PAID = 7d, PERPETUAL = 14d (`offline_grace_policy.dart`).

### F.2 Cache persistence

- Cache is stored as **plaintext JSON** in `AppSettings` (a plain local SQLite preferences table), keyed `cloud.license.<shopId>`. It is **not** DPAPI/Keystore-protected and carries **no integrity MAC / signature / authenticity tag**.
- Any local user can edit the persisted JSON (status, timestamps, tier, grace) to fabricate offline entitlement. This is the central S8 gap: **no CAS / integrity / anti-rollback binding**.
- Fields treated as integrity-sensitive (must be bound in S8): `licenseStatus`, `isRevoked`, `revokedAt`, `isTrial`/`trialActive`, `trialExpiresAt`, `subscriptionExpiresAt`, `serverTimeAtVerification`, `localWallClockAtVerification`, `lastSuccessfulVerificationAt`, `shopId`, `schemaVersion`.
- ~~`recordWallClock`/`getLastObservedClock`~~ persist a plaintext last-observed clock in the same editable store — insufficient against tamper.
- Corruption / parse failure / delete currently returns `null` from `load`, which routes to `offlineNoLicense`/`stale` (fail-closed), not to a fabricated grant.

### F.3 Clock behavior

- `DateTime.now()` is used at multiple security-relevant points: `lastSuccessfulVerificationAt`, `localWallClockAtVerification`, `recordWallClock`, and implicitly (via `DateTime.now().toUtc()`) in `isWithinGraceWindow`.
- `isWithinGraceWindow` computes `now - lastSuccessfulVerificationAt` and treats a negative elapsed as suspicious (returns false → no grace extension on backward jump), but does **not** persist a trusted high-water mark, so a plaintext edit of `lastSuccessfulVerificationAt` extends the window.
- The existing `detectClockRollback` (30 min threshold, `clockSkewTolerance` 5 min declared but unused in the grace decision) is advisory only and editable in the same plaintext store.
- No monotonic time is currently persisted or used for authority.
- Restart/reboot rebuilds state from the editable plaintext cache — attacker can restore an older valid cache.

### F.4 Server time

- The server **already returns an authoritative timestamp**: `verify_license_entitlement` RPC returns `server_time TIMESTAMPTZ := now()` (migration `20260820000033`, S3), surfaced as `EntitlementResult.serverTime` (`cloud_licensing_repository.dart`).
- This is the exact authoritative server timestamp field. **No new RPC/schema is required** to obtain trusted server time.

### F.5 Secure device identity composition (S6)

- Per-install Ed25519 keypair (`s6_device_identity.dart`), seed held in DPAPI CurrentUser (Windows) / Android Keystore (`secure_store_android.dart`), never leaves protected storage except transient in-process signing.
- Enrollment binds `public_key` to a device exactly once (server-side `s6_enroll_public_key`, migration 35); challenge/PoP via `s6_create_challenge` and the canonical `S6CanonicalEnvelope` `/ S6ProofOfPossession` (cross-verified Dart ↔ Deno golden vector).
- The S6 public identity and PoP material are suitable to bind S8 cache integrity to the installation identity / public key.

### F.6 Revocation / offline composition

- Cached REVOKED / SUSPENDED / EXPIRED / inactive-trial are respected offline ahead of grace (fail-closed composition of S3/S5 semantics).
- Device LOST / REVOKED terminal states (S4/S7) are not re-opened; S8 must not introduce an offline restoration seam that contradicts terminal-state rules (invariant R12).

---

## G. S8 exact scope

S8 OWNS the client-side convergence of:

```text
offline grace policy (verify/strengthen)
monotonic / trusted-time (high-water-mark) enforcement
entitlement cache integrity + authenticity binding
clock rollback / forward-jump handling
stale entitlement policy and server revalidation cadence
fail-closed behavior on unknown/corrupt/unbound cache
```

**The implementation boundary is Flutter/Dart (app/) only.** No server schema, RPC, Edge Function, RLS, Auth, or migration change is required (Sections P/Q prove this from existing committed server authority).

**Exact non-scope**

```text
S8 does NOT: alter verify_license_entitlement (server_time already authoritative)
S8 does NOT: alter the legacy Ed25519 token path (S9 owns retirement)
S8 does NOT: redesign S7 device-management UI / lifecycle / permission model
S8 does NOT: change S4 RPC semantics or S6 key identity
S8 does NOT: activate the global production device gate
S8 does NOT: touch secrets / secure-store layout beyond adding S8-owned integrity metadata
```

---

## H. Explicit non-scope / S9/S10/S11/S12 boundaries

```text
S9  = legacy Ed25519 retirement          → FORBIDDEN to S8 (evidence-gated separate slice)
S10 = test / security convergence        → FORBIDDEN to S8 (final CASE/threat convergence)
S11 = deployment / verification          → FORBIDDEN to S8
S12 = Group B closeout                   → FORBIDDEN to S8
GROUP C / GROUP D                        → FORBIDDEN to S8
```

Recorded deferred coverage (truthful, for S9/S10):

```text
SERVER_REQUIRED threat classes (fully-compromised-client cases) → S10 server-enforcement
Final CASE 1–20 test matrix              → S10
Legacy token retirement                  → S9
```

---

## I. Threat model

The realistic security boundary: the client runs under an OS user that may possess local read/write access to app-private data. S8 provides **device-bound tamper evidence and bounded, server-authoritative enforcement**. It does **NOT** claim to prevent deterministic tampering by a fully compromised administrator/root-privileged process, a dump-and-edit of plaintext at rest, or hardware-rooted attacks. The **server remains the authority** (R1); the security boundary that survives client compromise is server-side enforcement.

Per-threat classification:

```text
T1  Manual system-clock rollback to extend offline grace ..... BLOCK (trusted high-water + local monotonic; see K)
T2  Manual clock forward-jump then rollback .................. DETECT_AND_BLOCK (persist high-water; rollback behind it fails closed)
T3  Copy older valid cache over newer revoked/expired cache ... DETECT_AND_BLOCK (anti-rollback high-water + integrity binding)
T4  Edit cached status REVOKED/EXPIRED → ACTIVE .............. BLOCK (integrity/authenticity binding; status is integrity-protected)
T5  Edit cached timestamps .................................... BLOCK (timestamps integrity/binding protected)
T6  Edit cached tier / grace fields .......................... BLOCK (canonical payload binding)
T7  Copy another device's cache to this device ............... BLOCK (device/installation binding)
T8  Copy another shop/user's cache ........................... BLOCK (shop/tenant + user binding)
T9  Delete integrity metadata keeping payload ................. DETECT_AND_BLOCK (missing/bound-invalid metadata fails closed)
T10 Truncate / corrupt cache ................................. FAIL_CLOSED (parse/encode failure → no grant)
T11 Unknown future cache schema on older app .................. FAIL_CLOSED (per S5 versioning; scale up cleanly)
T12 Restart / reboot to reset anti-tamper state .............. FAIL_CLOSED (trusted high-water persists in protected store)
T13 Offline launch after locally known REVOKED / LOST ......... BLOCK (cached revoked/LOST respected; invariant R2/R12)
T14 Malformed / incomplete server-time response ............... FAIL_CLOSED (missing/invalid server_time → revalidation/deny)
T15 Modified client fabricating "trusted" timestamp .......... NOT_SOLVABLE_LOCALLY / SERVER_REQUIRED (server_time is authority; local value never establishes it)
T16 Legitimate clock correction / timezone / DST ............. ALLOWED_WITH_BOUNDED_POLICY (UTC-normalized; small tolerated correction per K; never extends grace)
T17 Secure-store value missing / inaccessible ................ FAIL_CLOSED (no identity binding → deny cache authority; revalidation path)
T18 Key rotation / reinstallation ............................ OUT_OF_SCOPE (S6-governed; S8 re-binds on re-enrollment)
T19 Replay of previously valid but stale server response ...... BLOCK (server_time baseline; TTL/staleness; revalidation)
T20 Windows / Android semantic divergence .................... ALLOWED_WITH_BOUNDED_POLICY (same S8 contract; platform store differs only)
```

---

## J. Security invariants

The future implementation **must** preserve at least these (committed authority does not weaken them):

```text
R1   Server authority remains supreme  — local cache never creates stronger entitlement than latest trusted server authority.
R2   Revocation is irreversible from stale local evidence — REVOKED/LOST/EXPIRED never → ACTIVE without fresh authoritative server
     evidence per existing server rules.
R3   Cache corruption never grants access — parse failure / schema mismatch / integrity failure / missing critical field /
     invalid timestamp relation / invalid binding never yields an active entitlement.
R4   Clock rollback cannot extend grace — persisted trusted-time / high-water-mark model (or evidence-backed equivalent) prevents
     backward wall-clock movement from extending offline authority.
R5   No client-fabricated authority — DateTime.now() / cached bool / preference / local SQLite field / UI state never independently
     establishes server authorization.
R6   Device binding — if cache integrity is device-bound, fail closed when the binding cannot be proven.
R7   Tenant binding — no cache from Shop A authorizes Shop B.
R8   Identity binding — no cache of another user/device silently authorizes this session unless committed product authority
     explicitly permits portability (none does).
R9   Unknown schema fails closed — preserve S5 versioning discipline.
R10  TRIAL offline grace = 0 (invariant).
R11  PAID ≤ 7d, PERPETUAL ≤ 14d are maxima; tamper handling must not increase them.
R12  Terminal device state stays terminal — S8 introduces no offline restoration seam contradicting S4/S7 terminal-state rules.
```

---

## K. Clock-trust contract

Governing principle: **prefer UTC for security timestamps; never use local timezone/DST as entitlement authority.**

```text
TRUSTED   timestamp = server-authoritative `server_time` (TIMESTAMPTZ now()) from verify_license_entitlement,
                      carried as EntitlementResult.serverTime (already present).
UNTRUSTED  value    = wall clock (DateTime.now()) at any local offset; used for UX only, never as entitlement authority.
PERSISTED  state    = a trusted high-water mark "lastTrustedServerTimeUtc" (a monotone-in-time value derived from the most
                      recent authoritative server_time) plus an S8 cache-schema version marker.
WHERE      persisted= in the S6-protected secret store (or an equivalent protected/authenticated location) OR as authenticated
                      metadata bound to the cache record — see L. A local-only plaintext marker is NOT sufficient (edit/rollback).
INTEGRITY  protected= the high-water mark and the cache binding are integrity/authenticity protected (L).
```

**Deterministic rules to implement (no improvisation):**

1. On every successful `verify_license_entitlement`, persist `lastTrustedServerTimeUtc = max(prev, server_time)` in the protected/authenticated store. Writing it in the plaintext AppSettings cache is forbidden for authority.
2. Offline grace is computed from the **trusted** high-water server time, not from an editable `lastSuccessfulVerificationAt` in plaintext cache.
3. If current wall clock < trusted high-water (i.e. rollback detected): FAIL CLOSED for offline grant; require online revalidation. Backward movement never extends grace. A legitimate small correction is handled under rule 6 tolerance, and revalidation re-syncs.
4. When current wall clock jumps forward: allowed only transiently (offline grant still bounded by the trusted high-water + grace against the trusted baseline, so a forward jump does not create a fresh baseline). A forward jump cannot itself establish authority (R5).
5. After reboot / process restart: reconstruct the high-water from the protected/authenticated store; plaintext cache alone cannot lower or overwrite it.
6. **Tolerance for normal clock correction:** use UTC-normalized comparisons; DST/timezone changes are normalized because all security math uses UTC. Adopt a small **skew tolerance** (existing `clockSkewTolerance = 5 minutes`) ONLY for detecting mere clock skew, **not** for extending grace. Because no defensible exact tolerance beyond the existing 5-minute skew window exists during governance, the rule is: **any backward wall-clock movement beyond the declared skew tolerance that would otherwise extend or preserve offline authority FAILS CLOSED**; the exact sub-5-minute edge is resolved conservatively at implementation and recorded as an explicit unresolved value rather than invented here.
7. Offline clearing of a clock anomaly: NOT allowed. Only a fresh authoritative `server_time` from `verify_license_entitlement` can re-establish/advance the trusted high-water.
8. Malformed / missing / non-UTC / unparseable `server_time`: FAIL CLOSED (revalidation path, no offline grant from that response).

Where monotonic time is used (windows/desktop and Android device-independent tools), it is an **additional** detection signal, never the sole authority; the trusted server-time high-water is the authority.

---

## L. Cache-integrity / authenticity contract

**Findings:** the current cache is plaintext, unbound JSON. S8 must add authenticity/integrity WITHOUT a new server secret. Platform facilities already present: S6 per-install Ed25519 private key held in protected storage, and existing `public_key`/device binding.

**Decision (evidence-backed):** bind the cache record via an **S6-device-private-key signature (Ed25519) over a canonical payload**, stored as authenticated metadata. This is **device-bound tamper evidence — NOT a server signature**: the client itself holds the key, so a fully compromised client can re-sign; the guarantee is that a *modified cache without the private key* cannot be presented as authentic, and unbound/by-value edits are rejected. This is the strongest local guarantee obtainable without a server secret and is deliberately **staged under the server-authoritative model (R1/R5)**. A hash-only scheme is explicitly rejected (attacker with file write can recompute a hash over a tampered payload).

Canonical integrity payload (must be specified exactly and kept in lock-step with any schema bump):

```text
shopId                 (tenant binding, R7)
installationId         (device binding, R7/T8)
userBoundary           (identity binding, R8 — bind to the user context when the product model associates one)
schemaVersion          (R9)
licenseStatus / isRevoked / revokedAt / isTrial / trialActive / trialExpiresAt / subscriptionExpiresAt   (status/revocation, R2/T4)
serverTimeAtVerification (server-price authority baseline, K)
lastTrustedServerTimeUtc (trusted high-water, K/R4)
graceBasis              (explicit TRIAL/PAID/PERPETUAL classification used for grace, R10/R11)
```

Anti-rollback: the trusted high-water `lastTrustedServerTimeUtc` (K) is persisted in the protected/authenticated store and monotonically advanced; a cache whose baseline is behind the protected high-water fails closed (T3/T5).

Versioning: bump the S8 cache schema tag. Migration from the existing S5 cache is governed in Section N. Unknown/newer schema loaded by an older app fails closed (R9, and see T11 — scale gracefully, no re-use of values).

Failure behavior: any failed parse / missing canonical field / signature mismatch / binding mismatch / missing metadata / high-water rollback → FAIL CLOSED (no offline entitlement; route to server revalidation), matching current `isCompatibleSchema` philosophy but at the integrity/binding layer.

Platform notes: the signature must be verifiable with the S6 public key derived via `s6_device_identity.dart`; the canonical payload must be byte-deterministic (reuse the `S6CanonicalEnvelope` canonicalization discipline). Windows (DPAPI) and Android (Keystore) differ only in the secret store backing the private key; the S8 contract itself is identical (T20).

---

## M. Anti-rollback contract

```text
MECHANISM          = persisted trusted high-water mark `lastTrustedServerTimeUtc`, monotonically non-decreasing,
                     protected/authenticated (K), advanced only by authoritative server_time.
DIRECTION          = high-water can only increase (or be reset by governed re-enrollment per S6).
REBOOT / RESTART   = high-water reconstructed from protected/authenticated store; plaintext cache cannot lower it.
CLEAR OFFLINE      = NOT allowed; only a fresh authoritative server response re-syncs/advances it.
ROLLBACK BEHAVIOR  = wall clock (or cache baseline) behind trusted high-water → offline authority denied; online revalidation required.
```

This satisfies R4 and blocks T1/T2/T3/T5.

---

## N. Existing-cache upgrade contract

Caches created before S8 (plaintext S5, schema v1, no integrity binding) are **not** verifiable for offline authority. Governed outcome:

```text
OLD_CACHE_REQUIRES_ONLINE_REVALIDATION
```

```text
First launch after upgrade (online) ........ revalidate via verify_license_entitlement; persist S8-bound cache.
Offline first launch after upgrade ......... NO offline grant from old unbound cache; online revalidation required (fail-closed on authority).
Existing paid customer ..................... online revalidation restores paid capability per server authority (max 7d offline grace from the fresh trusted baseline).
Existing perpetual customer ................ online revalidation restores perpetual capability per server authority (max 14d).
Trial customer ............................. online revalidation; TRIAL offline grace stays 0 (R10).
Already revoked customer ................... revalidation enforces revocation (R2); old cache cannot restore.
Missing secure identity / S6 key ............ fail closed; re-enroll per S6 governance, then revalidate.
Corrupt / truncated old cache .............. parse/integrity failure → fail closed; online revalidation.
```

Security precedence: an unverifiable historical offline grant is never preserved over server authority.

---

## O. S3/S5/S6/S7 composition

```text
S3 (revocation/offline-grace authority) ....... provides server_time + revocation signals; S8 consumes, does not redefine semantics.
S5 (client entitlement integration) .......... provides EntitlementSnapshot + OfflineGracePolicy; S8 strengthens integrity/clock over this model (keep surfaces, add binding).
S6 (platform secure device identity + PoP) ... provides the Ed25519 private key + canonical-envelope discipline for S8 cache binding.
S7 (owner device management) ................. terminal device state (LOST/REVOKED) stays terminal (R12); S8 adds no restoration seam.
```

No predecessor-owned surface is redesigned; S8 only adds the convergence layer (integrity, authenticated timestamps, anti-rollback) on top of existing authority.

---

## P. Server / schema / RPC / Edge / RLS delta determination

Proven from committed authority (not assumed):

```text
S8_SERVER_SCHEMA_DELTA  = NONE   — server_time already returned by verify_license_entitlement (migration 33, S3); revocation/expiry/status
                                      already server-authoritative. R1/R2 need no schema.
S8_RPC_DELTA            = NONE   — verify_license_entitlement already returns authoritative server_time (EntitlementResult.serverTime).
S8_EDGE_FUNCTION_DELTA  = NONE   — no Edge function change required for the client-side convergence.
S8_RLS_DELTA            = NONE   — RLS model unchanged; S8 adds no server read/column dependency.
S8_AUTH_DELTA           = NONE   — auth/JWT model unchanged.
S8_CLIENT_DELTA         = REQUIRED — S8 is a client-side (app/ Dart) convergence: cache integrity/authenticity, trusted-time
                                      high-water, anti-rollback, fail-closed routing (Sections K/L/M/N).
```

For each `NONE`, the existing committed server authority is cited as sufficient (server_time + revocation signals + RLS + device-trust already in place from S1–S7).

---

## Q. Migration-number gate

```text
HIGHEST_COMMITTED_MIGRATION_AT_ENTRY = 20260820000035_phase_p_group_b_s6_platform_secure_device_identity.sql
NEXT_NUMERIC_MIGRATION_IF_REQUIRED   = <reserved only if a DB delta is authorized> — none is
S8_MIGRATION_REQUIRED                = NO  (from evidence: S8 is client-only; server authority sufficient)
```

**NO `00036` migration is authorized by this governance.** Do not create or reserve a `00036` file merely because it is the next number. No empty reservation migrations.

---

## R. Future implementation exact file allowlist

Derived to be as narrow as repository evidence permits. No file is edited in this governance session. An S8 implementation session is authorized to touch **only** the following (plus a matching test file), and to add at most ONE new production file with the named responsibility below:

```text
app/lib/licensing/entitlement_cache.dart        — add authenticated/integrity-bound serialization + high-water persistence (existing surface)
app/lib/licensing/offline_grace_policy.dart      — wire grace computation to trusted high-water; clock anomaly fail-closed handling
app/lib/licensing/cloud_licensing_service.dart   — persist/consume lastTrustedServerTimeUtc; route fail-closed; bind cache on save/load
app/lib/licensing/s6_device_identity.dart        — expose read-only public-key/sign primitives for S8 cache binding (minimal addition)
app/lib/licensing/s8_cache_integrity.dart        — NEW single production file: canonical payload, sign/verify, anti-rollback helper
app/test/licensing/s8_tamper_cache_clock_test.dart — NEW S8 test file (scenario matrix, Section S)
```

**Explicitly forbidden patterns:** `app/**`, `supabase/**`, and any other broad glob. No Supabase production/SQL/RPC/Edge/RLS/migration change is authorized (P/Q).

---

## S. Future test scenario matrix

Deterministic requirements; exact assertion count is reconciled against the actual test file at implementation time (do not invent a count now).

### Cache integrity
- valid current cache accepted according to policy
- payload mutation rejected
- status mutation rejected
- timestamp mutation rejected
- tenant mismatch rejected
- device mismatch rejected
- unknown schema rejected
- truncated cache rejected
- missing integrity metadata rejected
- old pre-S8 cache handled according to upgrade policy (Section N)

### Clock
- normal forward progression
- small legitimate correction if allowed by governed rule (K tolerance)
- backward clock rollback
- large forward jump
- forward jump then rollback
- restart preserves anti-rollback state
- reboot-equivalent persisted-state reconstruction
- timezone change does not extend grace
- DST change does not extend grace
- future-dated trusted metadata fails according to governed rule

### Entitlement
- TRIAL offline denied
- PAID ≤ 7d governed grace
- PAID > 7d denied
- PERPETUAL ≤ 14d governed grace
- PERPETUAL > 14d denied
- REVOKED always wins
- EXPIRED cannot be restored by stale cache

### Device / identity
- wrong device binding denied
- missing secure identity fails closed
- device LOST denied where locally authoritative state exists
- device REVOKED denied
- valid S6 identity composition succeeds

### Online recovery
- fresh authoritative server response can update trusted high-water
- malformed server timestamp fails closed
- server failure does not fabricate fresh authority
- successful revalidation rotates/updates cache according to contract

---

## T. Regression / immutability gates

Future S8 implementation must satisfy (and must NOT weaken predecessor tests to obtain green):

```text
FULL_DART >= 1663  (unless legitimate restructuring is explicitly reconciled at implementation time)
S1 pgTAP = 46
S2 pgTAP = 88
S3 pgTAP = 25
S4 pgTAP = 50
S6 pgTAP = 35
S6 Deno  = 16
S6 Dart  = 36
```

Static / quality gates:

```text
dart format --set-exit-if-changed
flutter analyze (0 errors)
all targeted S8 tests PASS
FULL_DART regression PASS
S1/S2/S3/S4/S6 regressions PASS (applicable)
git diff --check PASS
secret scan PASS (no committed private key / token / password / service-role secret)
```

Because S8 is conclusively client-only (P), no pgTAP / Deno / migration-replay gate is required for the S8 slice.

**Pre-existing out-of-scope defect (documented, NOT caused by S8, MUST NOT be fixed/masked/deleted/altered):**

```text
supabase/tests/cloud_stock_adjustments.test.sql
   → pre-existing SQL defect (pg_get_constraintdef(oid) without FROM), exit = 3, predates S7.
```

---

## U. Secret / sacred protections

Sacred pre-existing untracked evidence (present at entry) is preserved unchanged, un-staged:

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
GROUP_A_PHASE_P_OD7_*_REPORT.md (3 files) + GROUP_A_PHASE_Q_*_FAILED_SESSION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.branches/
supabase/.temp/
```

Rules: DO NOT delete/move/modify/stage/package/clean/normalize. Stage the exact governance artifact path only. Never `git add .` / `git add -A`.

Never expose or commit: Supabase service_role keys, private Ed25519 device seeds/keys, Android Keystore/upload keys/passwords, refresh tokens, JWTs, invitation secrets, DPAPI-protected plaintext. Tests use synthetic fixtures only (reuse `S6TestIdentity`/golden-vector discipline, never production material).

---

## V. Future implementation entry contract

A separate Owner-authorized S8 implementation session must, before writing:

```text
classify entry/recovery fresh;
prove LOCAL == TRACKING == github remote;
confirm the S1→S7 chain and that HEAD is this S8 governance commit;
read this governance artifact and preserve its exact contracts;
touch only the Section R allowlist;
respect Section P/Q (NO server/migration delta);
not start S9/S10/S11/S12 or Groups C/D.
```

---

## W. Commit / push contract

- ONE governance-only commit of exactly this artifact.
- Pre-commit proof: `git diff --name-status` + `git status --short` indicate the artifact is the only new intended tracked mutation; stage with the exact path only.
- Staged profile: exactly 1 governance artifact; 0 production files, 0 tests, 0 SQL, 0 migration, 0 Edge, 0 sacred evidence.
- Commit message: `docs: govern Group B S8 tamper cache clock enforcement`; NO amend/rebase/squash/history rewrite.
- Pre-push drift gate on `github`: require `DIRECT_GITHUB_REMOTE_HEAD == GOVERNANCE_COMMIT_PARENT`, AHEAD=1, BEHIND=0, else STOP (REMOTE_DRIFT).
- Push: exactly one normal fast-forward to `github codex/i-tech-next-roadmap-freeze`. Forbidden: --force / --force-with-lease, delete branch, new/tag push, push to origin.
- Post-push: prove LOCAL == TRACKING == DIRECT_GITHUB_REMOTE_HEAD == new S8 governance commit, AHEAD=0, BEHIND=0, and (where practical) blob equality of the commit/remote-tracking artifact.

---

## X. Mandatory stop

This governance artifact being ready does **NOT** authorize implementation. A separate explicit Owner instruction is required. After this governance remote lock:

```text
DO NOT IMPLEMENT S8.
DO NOT CREATE S8 PRODUCTION CODE.
DO NOT CREATE MIGRATION 00036.
DO NOT MODIFY CACHE FORMAT.
DO NOT MODIFY CLOCK ENFORCEMENT.
DO NOT MODIFY SECURE STORAGE.
DO NOT START S9 / S10 / S11 / S12 / GROUP C / GROUP D.
DO NOT DEPLOY TO SUPABASE, BUILD ANDROID RELEASE/AAB, USE PLAY CONSOLE, ACTIVATE RELEASE/DRAIN.
```

---

## Y. Expected future implementation evidence

On the separate implementation session, prove:

```text
correct S8 signed/authenticated cache round-trip (Windows + Android paths where runnable);
offline denial beyond governed windows;
rollback/forward-jump denial via trusted high-water;
TRIAL=0 / PAID≤7d / PERPETUAL≤14d;
REVOKED/EXPIRED never restored offline;
tenant/device/identity binding denial;
unknown/corrupt/truncated/unbound cache fail-closed;
malformed server_time fail-closed;
FULL_DART + predecessor regression floors PASS;
no new server/migration/pgTAP delta.
```

---

## Z. Success / failure conditions

Success (mint) only when all hold:

```text
repository identity verified; authority verified; S8 confirmed immediate successor;
entry/recovery safely classified (CASE_A_FRESH); S7 remote lock proven; S1→S7 chain preserved;
actual tamper/cache/clock implementation audited; threat model governed; clock model governed;
cache integrity/authenticity model governed; anti-rollback model governed; upgrade behavior governed;
server/schema/RPC/Edge/RLS/Auth delta explicitly NONE with evidence;
migration gate explicitly NO (no 00036);
future implementation allowlist exact; future test contract exact;
exactly one governance artifact committed; normal fast-forward push only;
local == tracking == direct github remote; sacred evidence preserved;
no secrets exposed; no production mutation; S8/S9+ not started; Group C/D not started; origin never contacted.
```

Any deviation → return a precise BLOCKED/FAILED token and STOP.

---

*End of S8 governance artifact.*
