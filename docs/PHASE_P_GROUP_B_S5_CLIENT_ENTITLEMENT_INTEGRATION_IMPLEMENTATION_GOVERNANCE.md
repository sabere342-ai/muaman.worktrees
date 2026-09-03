# Phase P Group B S5 — Client Entitlement Integration — Implementation Governance

**Document type:** Implementation governance (owner-gated contract for a future S5 implementation session)

**Repo:** I Tech Store Management / `muaman_store` (worktree `i-tech-next-roadmap-freeze`)

**Branch:** `codex/i-tech-next-roadmap-freeze`

**Authorized remote (push/verify):** `github` (https://github.com/sabere342-ai/muaman.worktrees.git)

**Legacy remote `origin`:** SACRED READ-ONLY. MUST NOT be contacted.

---

## A. Session Contract

```text
SESSION    = PHASE_P_GROUP_B_S5_CLIENT_ENTITLEMENT_INTEGRATION_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
MODE       = SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY_FAIL_CLOSED
AUTHORITY  = VERIFY → GOVERN S5 → CREATE EXACTLY ONE GOVERNANCE ARTIFACT → COMMIT → NORMAL PUSH → PROVE LOCK → STOP
IMPLEMENTATION = STRICTLY FORBIDDEN in this session
```

This session does **not** implement S5. It produces a repository-evidence-backed governance contract that a future, separately-authorized S5 implementation session must satisfy.

---

## B. Repository / Entry Identity

| Item | Value |
|------|-------|
| ROOT | `C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` |
| github FETCH_URL | `https://github.com/sabere342-ai/muaman.worktrees.git` |
| github PUSH_URL | `https://github.com/sabere342-ai/muaman.worktrees.git` |
| LEGACY origin | local path `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` (read-only) |
| ENTRY_HEAD | `b8889bf59d65037915fcec618f06fc1c1a49ae40` |
| ENTRY_PARENT | `5309749995244c8bfb423b46d897150b839c1f81` |

**Entry verification at session start (all PASS):**
- `git rev-parse --show-toplevel` = repo root (match).
- `git branch --show-current` = `codex/i-tech-next-roadmap-freeze` (match).
- `git rev-parse HEAD` = `b8889bf59d65037915fcec618f06fc1c1a49ae40` (match).
- `git rev-parse @{u}` = `b8889bf59d65037915fcec618f06fc1c1a49ae40` (match).
- `git merge-base HEAD @{u}` = `b8889bf59d65037915fcec618f06fc1c1a49ae40` (match).
- `git rev-list --left-right --count HEAD...@{u}` = `0  0` (AHEAD 0, BEHIND 0).
- `git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze` = `b8889bf59d65037915fcec618f06fc1c1a49ae40` (match).
- `git diff --name-status` = empty (tracked worktree clean).
- `git diff --cached --name-status` = empty (index empty).
- `git status --short` = only pre-existing untracked sacred evidence (see below); no tracked changes.
- Active Git operation check: `rebase-merge`, `rebase-apply`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `BISECT_LOG`, `sequencer` — all absent (NONE).

**Pre-existing untracked / sacred evidence (NOT staged, NOT deleted, NOT `git clean`-ed):**
`GROUP_A_PHASE_P_OD7_*` reports, `GROUP_A_PHASE_Q_ANDROID_*` report, `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`, `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`, `delivery/I-TECH-Delivery-v1.0.0.zip`, `supabase/.branches/`, `supabase/.temp/`. These are preserved exactly as found.

---

## C. Entry / Recovery Classification

**Classification: `CASE_A_FRESH`**

```text
LOCAL_HEAD        = b8889bf59d65037915fcec618f06fc1c1a49ae40
REMOTE_TRACK      = b8889bf59d65037915fcec618f06fc1c1a49ae40
DIRECT_REMOTE     = b8889bf59d65037915fcec618f06fc1c1a49ae40
AHEAD             = 0
BEHIND            = 0
TRACKED_WORKTREE  = CLEAN
INDEX             = EMPTY
ACTIVE_OP         = NONE
```

No prior interrupted S5 governance attempt exists. No recovery required.

---

## D. Current Remote-Lock Baseline

At governance time the branch is remote-locked at the S4 implementation head:

```text
LOCAL == TRACKING == DIRECT_REMOTE == b8889bf59d65037915fcec618f06fc1c1a49ae40
AHEAD = 0, BEHIND = 0
```

---

## E. Authority Chain

Verified from committed Git objects at HEAD:

| # | Authority | COMMIT | PATH | BLOB (verified) |
|---|-----------|--------|------|-----------------|
| 1 | OWNER_ORDER_DECISION (GROUP_B before GROUP_D) | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` ✓ |
| 2 | AUTHORITY-BINDING CORRECTION | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` ✓ |
| 3 | GROUP B MASTER PLAN | `9ecdc38282cdb7ca6f088263f9e152f920b7a823` | `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` ✓ |

**Material rules (confirmed):**
- GROUP_B comes BEFORE GROUP_D; Group D remains `ORDERED_SECOND_AND_DEFERRED`.
- Group B is the licensing / commercial / security authority. Per-slice governance → implementation → remote-lock protocol applies.
- Master plan §14 defines S5 = **Client entitlement integration** (models, repositories, entitlement cache integrity, tier/grace consumption), dependencies **S2, S3**.
- S5 = NEXT AUTHORIZED SLICE. S12 = Group B closeout. Group D = STILL DEFERRED. S4 completion does **not** equal Group B completion (S4 is not Group B closeout).

**Slice-order derivation (per master plan §14):**
```text
S6  depends on S4 + S5
S7  depends on S4 + S6
S8  depends on S3 + S5
S9  depends on S5 + independent evidence gate
S10 depends on all prior
S11 deployment / verification governance
S12 Group B closeout
```

---

## F. S2 / S3 Dependency Remote-Lock Proof

S5 depends on S2 and S3. Both are verified as committed and reachable from HEAD (ancestor check = YES for each):

| Slice | Role | COMMIT | Ancestor of HEAD |
|-------|------|--------|------------------|
| S2 governance | | `a4fcada1538505bbf527a0fc9d707004490d4ac0` | YES ✓ |
| S2 implementation | | `85e43154de37f9b4987e9bab1a55548e1c9433fc` | YES ✓ |
| S3 governance | | `7d05313cf1a50765ad6721b264a7b05e51263ffd` | YES ✓ |
| S3 implementation | | `62af44695e664722d1ccabf5816f55678d1e049a` | YES ✓ |

**Immutable migrations present at HEAD:**
- `supabase/migrations/20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql` (`plans` authority, `s2_resolve_entitled_license`, user/device quota, `verify_license_entitlement` plan-based limits, `server_time`).
- `supabase/migrations/20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql` (license/device/membership revocation + cascades, `verify_license_entitlement` 16-column surface with `is_revoked`/`revoked_at`, TRIAL=0d / PAID=7d / PERPETUAL=14d grace anchor, revocation-aware `activate_device`/`register_device`).

These slices are closed and remote-locked. S5 must not reopen S2/S3 implementation.

---

## G. S4 Boundary Proof

S4 is complete and REMOTE_LOCKED but is **not** Group B closeout:

| Item | COMMIT |
|------|--------|
| S4 GOVERNANCE | `2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5` |
| S4 GOVERNANCE CORRECTION | `5309749995244c8bfb423b46d897150b839c1f81` |
| S4 IMPLEMENTATION (entry HEAD) | `b8889bf59d65037915fcec618f06fc1c1a49ae40` |

**S4 boundary finding:** `supabase/migrations/20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql` does **not** modify `verify_license_entitlement` (verified via `git grep` = no match in the S4 migration). S4 provides server-side device-trust / invitation authority that later slices may consume, but S5's direct dependency contract remains **S2 + S3** per the master plan. S4 files are not modified or reopened.

---

## H. Current Client State Forensics (at HEAD)

Repository evidence, not plan assumptions. The licensing/entitlement stack lives in `app/lib/licensing/` (not `app/lib/repositories/` or `app/lib/models/`, which hold business data models and cloud CRUD repos). Key current files:

| File | Role |
|------|------|
| `app/lib/licensing/cloud_licensing_repository.dart` | **Sole** Supabase licensing RPC layer (`verify_license_entitlement`, `start_trial`, `register_device`, `activate_device`, `deactivate_device`, `get_device_list`). |
| `app/lib/licensing/entitlement_cache.dart` | `EntitlementSnapshot` model + `EntitlementCache` persistence (AppSettings KV, shop-scoped). |
| `app/lib/licensing/cloud_licensing_service.dart` | `CloudEntitlementState` enum + `CloudEntitlementSnapshot` + orchestrator (server/cache/grace/device). |
| `app/lib/licensing/offline_grace_policy.dart` | Grace durations + `isWithinGraceWindow` / `isCachedNonEntitled` / clock rollback detection. |
| `app/lib/licensing/license_exception.dart` | Cloud-era exception types. |
| `app/lib/licensing/device_identity.dart` + `platform/device_identity_provider.dart` | Device fingerprint (fingerprint, not per-install keypair). |
| `app/lib/database/database_helper.dart` | Write gate: `_enforceLicensing()` → registered `CloudLicensingService.instance.enforceActive()` at 25+ business-write call sites. |
| `app/lib/services/cloud_session_resume.dart`, `seller_session_provisioning.dart` | Bootstrap / resume call sites for licensing initialize/register/activate. |
| `app/lib/widgets/trial_remaining_banner.dart`, `app/lib/screens/settings/license_status_screen.dart` | License/trial UI consumption. |

**Call sites located:** `verify_license_entitlement` (repository→service), `EntitlementSnapshot`/`EntitlementCache` (cache save/load/clear), offline grace checks (grace policy), license/trial status consumption (service + UI), device slot / max device consumption, subscription expiry consumption, `server_time` consumption, cloud session bootstrap / resume (`cloud_session_resume.dart`, `seller_session_provisioning.dart`), write blocking / entitlement gates (`database_helper.dart`).

### Current-state matrix

| Concern | Classification | Evidence / detail |
|---------|----------------|-------------------|
| Server entitlement fetch (verify_license_entitlement) | ALREADY_IMPLEMENTED | `cloud_licensing_repository.dart:118-125`. |
| RPC → `EntitlementResult` mapping (has_license, license_status, is_trial, trial_active, trial_started/expires, days/hours, activated_at, subscription_expires_at, max_devices, current_devices, device_slot_available, server_time) | ALREADY_IMPLEMENTED | `cloud_licensing_repository.dart:37-64`. |
| `is_revoked` / `revoked_at` server-field parsing | **MISSING** | S3 server returns 16 columns including `is_revoked`/`revoked_at`; current `EntitlementResult` does NOT parse either field. |
| `EntitlementSnapshot` cache model (server_time, grace anchor, shop scope) | ALREADY_IMPLEMENTED | `entitlement_cache.dart`. |
| Cache persistence (save/load/clear), shop-scoped | ALREADY_IMPLEMENTED | `EntitlementCache` keyed `cloud.license.<shopId>`. |
| Cache must not grant NEW entitlement | ALREADY_IMPLEMENTED | `EntitlementSnapshot.blocksWrites`; `EntitlementCache` doc comment: "CACHE ONLY — server is always the authority." |
| Offline grace (TRIAL 0d, PAID 7d, PERPETUAL 14d) | ALREADY_IMPLEMENTED | `OfflineGracePolicy` constants + `isWithinGraceWindow`. |
| Cached non-entitled (EXPIRED/SUSPENDED/REVOKED) respected offline | ALREADY_IMPLEMENTED | `OfflineGracePolicy.isCachedNonEntitled`. |
| Offline grace window -> `entitledCached` | ALREADY_IMPLEMENTED | `_resolveStateFromCache` → `entitledCached`. |
| Beyond grace window -> `staleOffline` (blocks writes) | ALREADY_IMPLEMENTED | `_resolveStateFromCache` → `staleOffline`. |
| State mapping EXPIRED/SUSPENDED/REVOKED from server | ALREADY_IMPLEMENTED (PARTIAL, see gap) | `_resolveStateFromServer` status branches. See H-Gap-1. |
| Server-time consumption into cache | ALREADY_IMPLEMENTED | `serverTimeAtVerification` stored; exposed in snapshots. |
| Subscription-expiry consumption | PARTIAL | `subscriptionExpiresAt` parsed + cached but not consumed for grace/status decisions in server-state resolution. |
| Device quota fields (max/current/slot) | ALREADY_IMPLEMENTED | parsed + carried in snapshots + surface in quota exceptions. |
| Tier identity (plan_key / tier label) carried client-side | PARTIAL / **MISSING** | `verify_license_entitlement` does NOT return `plan_key`/tier name; `license_status` + `is_trial` + device limits are the closest server-authoritative signals (no client-derived tier authority should be invented). |
| Revalidation replacing stale cache | ALREADY_IMPLEMENTED (basic) | `resolveEntitlement` overwrites `_currentState` + saves cache on success. |
| Reconnect convergence (revalidation after offline) | PARTIAL | `refreshEntitlement`/`resolveEntitlement` exists; explicit reconnect-triggered revalidation wiring is minimal. |
| Malformed/missing server payload fail-close | PARTIAL | `fromRpc` defaulted fields; no explicit validation/versioning metadata on cache → S5 must add bounded validation. |
| Malformed local cache fail-safe | ALREADY_IMPLEMENTED | `EntitlementCache.load` catch → null (fail-safe). |
| Clock rollback detection | ALREADY_IMPLEMENTED (bounded) | `OfflineGracePolicy.detectClockRollback` (>30 min). Full enforcement deferred to S8. |
| Device activation snapshot (deviceActivated) | PARTIAL | `deviceActivated` set from `deviceSlotAvailable` — conflates "slot available" with "this device activated"; S5 must not overclaim. Device-trust (single-device activation state per verified install) belongs to S4/S6 authority surfaced later. |

### H-Gap-1 — REVOKED detection precedence (fail-closed criticality)

S3 returns a revoked license as `has_license=false`, `license_status='REVOKED'`, `is_revoked=true`, `revoked_at=<ts>`. In the current `_resolveStateFromServer` (`cloud_licensing_service.dart:312-405`) the first branch is `if (!result.hasLicense) → noLicense`, which returns **before** the `status == 'REVOKED'` branch. Therefore a server-authoritative revocation currently maps to `noLicense` (blocks writes, which is fail-closed-safe, but mislabels the UX reason and does not surface `revoked_at`). S5 must reconcile mapping so an authoritative `REVOKED` / `is_revoked=true` result maps deterministically to `revoked` (and `blocked`), while preserving fail-closed write blocking in every case.

### H-Gap-2 — S3 revocation signal not carried into cache/snapshot

`EntitlementResult`, `EntitlementSnapshot`, and `CloudEntitlementSnapshot` do not carry `is_revoked` / `revoked_at`. To satisfy S5's offline-revocation contract, the cache must persist the authoritative revoked state so an offline client that cached a revoked/non-entitled result stays blocked (already blocked via `isCachedNonEntitled`, but the revocation metadata is dropped at the mapping boundary today).

---

## I. Exact S5 Scope

S5 integrates on the **client** the already-committed S2/S3 server entitlement/revocation/quota authority. It owns:

1. Complete, exact client mapping of the current `verify_license_entitlement` server surface (including the S3 16-column surface with `is_revoked`/`revoked_at`).
2. Client entitlement model(s) and repository/service boundary for entitlement fetching.
3. Entitlement cache integrity/versioning/staleness metadata (bounded, non-authoritative).
4. Tier / quota consumption from server-authoritative fields.
5. Offline-grace consumption per the committed grace contract.
6. Revoked / expired / suspended / not-entitled state mapping and fail-closed error mapping.
7. Proven fail-closed semantics via defined test matrix.

S5 does **not** own tamper/clock full enforcement (S8), per-install cryptographic device identity (S6), owner device-management UI (S7), legacy Ed25519 retirement (S9), or server/DB authority changes.

---

## J. Server Contract Consumed by S5

The authoritative surface is `verify_license_entitlement(UUID)` returning **16 columns** (S3 final; S2 added plan-based limits; S4 did not change it):

```text
has_license BOOLEAN
license_status TEXT          (TRIAL | ACTIVE | PERPETUAL | EXPIRED | SUSPENDED | REVOKED | NULL)
is_trial BOOLEAN
trial_active BOOLEAN
trial_started_at TIMESTAMPTZ
trial_expires_at TIMESTAMPTZ
days_remaining INTEGER
hours_remaining INTEGER
activated_at TIMESTAMPTZ
subscription_expires_at TIMESTAMPTZ
max_devices INTEGER          (NULL => enterprise/unlimited)
current_devices BIGINT
device_slot_available BOOLEAN
server_time TIMESTAMPTZ
is_revoked BOOLEAN           (S3)
revoked_at TIMESTAMPTZ       (S3)
```

**Authoritative semantics:** For an entitled license `is_revoked=false, revoked_at=NULL`. For a REVOKED license `has_license=false, license_status='REVOKED', is_revoked=true, revoked_at=<licenses.revoked_at>, server_time=now()`. `max_devices IS NULL` = unlimited (enterprise). `server_time` is the authoritative timestamp anchor.

**Client mapping decision (Section M of the super-prompt):** The tier-identity requirement (plan_key / tier label) is **not obtainable** through the existing committed `verify_license_entitlement` surface. Per classification option **B**: S5 consumes the already-authoritative existing fields — `license_status`, `is_trial`, `trial_*`, `max_devices`/`current_devices`/`device_slot_available`, and subscription/trial expiry — as the surrogate tier/quota signals. The governance does **not** invent a client-derived tier authority and does **not** add a new server surface (no new migration, no RPC change). Any genuine future need for a client-visible tier name/label is explicitly governed as a **future server-interface adjustment** requiring separately committed authority (NOT part of S5 implementation, NOT authorized by this governance).

---

## K. Tier / Quota Consumption

Authoritative tier limits (committed commercial authority, `plans` seed from S1; S2 uses these):

```text
TRIAL        users = 1,   devices = 1,    trial = 14 days
STARTER      users = 2,   devices = 3
PROFESSIONAL users = 5,   devices = 10
ENTERPRISE   users = unlimited, devices = unlimited
```

The server is the authority for these limits. The client **consumes** the effective limits surfaced via `verify_license_entitlement` (`max_devices`, `current_devices`, `device_slot_available`) rather than hard-coding tier tables. The client must treat `max_devices == null` as **unlimited** (enterprise) and must not fabricate a numeric limit.

**Commercial model:** subscription-only; monthly + annual cadence; PERPETUAL is compatibility-only and MUST NOT be represented as a newly sold tier. **No new billing/payment provider** (Stripe, Paymob, Play Billing, or any other) is introduced by S5 or allowed within S5 scope.

---

## L. Offline Grace Consumption

Authoritative owner-approved contract (P-OD9, committed in offline_grace_policy and S3):

```text
TRIAL      = 0 days offline grace
PAID       = 7 days offline grace
PERPETUAL  = 14 days compatibility-only grace
```

S5 consumes these semantics through the existing `OfflineGracePolicy`:
- TRIAL never operates offline (even an active trial gets no runway).
- PAID/ACTIVE offline grace = 7 days from `lastSuccessfulVerificationAt`.
- PERPETUAL offline grace = 14 days (launch compatibility only).
- The server-authoritative anchor is `verify_license_entitlement.server_time` and `activations.last_verified_at`; the client anchors the grace window on `serverTimeAtVerification` / `lastSuccessfulVerificationAt` stored in the cache.
- Cached non-entitled states (EXPIRED/SUSPENDED/REVOKED/inactive trial) are respected offline and never overridden by grace.

**Boundary:** S5 integrates entitlement/grace data into the client entitlement model. S8 remains the dedicated later slice for monotonic-timing hardening, dedicated clock/tamper enforcement, and advanced cache-integrity enforcement. S5 does **not** absorb S8.

---

## M. Revocation / Expiry / Suspension Mapping

Server-status → client-state mapping required for S5 (`_resolveStateFromServer`):

| Server signal | Client state | Writes |
|---------------|--------------|--------|
| `is_revoked=true` / `license_status='REVOKED'` (even when `has_license=false`) | `revoked` | BLOCK |
| `license_status='SUSPENDED'` | `suspended` | BLOCK |
| `license_status='EXPIRED'` | `expired` | BLOCK |
| trial present but `trial_active=false` | `expired` (trial) | BLOCK |
| `has_license=false`, no REVOKED/SUSPENDED/EXPIRED | `noLicense` (online) / `offlineNoLicense` (offline) | BLOCK |
| trial active | `entitled` | ALLOW |
| paid active (ACTIVE/PERPETUAL) | `entitled` | ALLOW |
| offline within grace | `entitledCached` | ALLOW (maintains existing entitlement only) |
| offline beyond grace | `staleOffline` | BLOCK |
| clock rollback suspected | `clockTamper` | BLOCK |

`CloudEntitlementSnapshot.allowsWrites` must remain `true` **only** for `entitled` and `entitledCached`. Every revoked/expired/suspended/not-entitled state must block writes.

---

## N. Fail-Closed Error Mapping

Doctrine (P-OD10/P-OD11):

```text
SERVER = SECURITY AUTHORITY
CLIENT = UX / CACHE / OFFLINE CONSUMER
LOCAL CACHE MUST NOT CREATE NEW ENTITLEMENT
LOCAL CACHE MUST NOT OVERRIDE REVOKED / EXPIRED / SUSPENDED / NOT_ENTITLED
SERVER REVALIDATION MUST CONVERGE CLIENT STATE
UNKNOWN / MALFORMED / INCONSISTENT SECURITY-RELEVANT STATE = FAIL CLOSED
```

Required S5 behavior for each failure class:

| Condition | Required behavior |
|-----------|-------------------|
| Server unreachable (network/timeout) | Use cache within grace → `entitledCached`; else `staleOffline` (blocked). |
| Cached snapshot absent + offline | `offlineNoLicense` / `offlineNoActivation` (blocked). |
| Cached non-entitled (REVOKED/EXPIRED/SUSPENDED/no license/inactive trial) | Remain blocked; never overridden by grace. |
| Malformed / missing server fields | **FAIL CLOSED** → treat as blocked/non-entitled; do not fabricate entitlement. |
| Malformed / corrupt local cache JSON | Discard → treat as no cache → blocked until valid server resolution. |
| Invalid/mismatched cache version or schema | Treat as incompatible/non-authoritative → do not trust → blocked pending revalidation. |
| Clock rollback / tamper suspected (bounded) | Require online revalidation; block writes until converged (bounded; full enforcement in S8). |
| Server authorization error (not-a-member, authentication) | Block; propagate distinct error; no entitlement granted. |

The governance explicitly does **not** claim that local cache integrity provides perfect anti-tamper protection. P-OD11 requires bounded practical controls; S8 is responsible for the later dedicated tamper/cache/clock enforcement slice. S5 establishes only the cache-integrity and entitlement-consumption foundation needed by its own scope.

---

## O. Exact Future Implementation Allowlist

The future S5 implementation session (**separately authorized**) is limited to the narrowest justified paths. All paths are bounded per-file or tightly bounded path sets under `app/lib/licensing/` and `app/test/licensing/`; **no wildcard** (`app/lib/**`, `app/test/**`, `supabase/**`) is authorized.

Authorized to **modify**:
- `app/lib/licensing/cloud_licensing_repository.dart` — add `is_revoked`/`revoked_at` parsing to `EntitlementResult`; add bounded result validation/versioning metadata.
- `app/lib/licensing/entitlement_cache.dart` — extend `EntitlementSnapshot` with revocation metadata (`is_revoked`/`revoked_at`) and cache-integrity/version metadata; keep fail-safe load; keep shop-scoped isolation; do NOT change installation-identity semantics.
- `app/lib/licensing/cloud_licensing_service.dart` — reconcile H-Gap-1 (REVOKED mapping precedence), add server-time/subscription-expiry consumption, cache-version/schema validation, reconnect revalidation wiring; keep `allowsWrites` = {entitled, entitledCached} only.
- `app/lib/licensing/offline_grace_policy.dart` — only if a tiny, proven-unavoidable seam for S5 grace consumption requires it (document precisely; otherwise do NOT touch).
- `app/lib/licensing/license_exception.dart` — only to add/adjust S5-specific exception types for malformed/invalid-schema states if required.
- `app/test/licensing/cloud_licensing_test.dart` — preserve, add S5 scenarios per matrix below (no deletion/weakening).
- `app/test/licensing/` new files — ONLY `app/test/licensing/s5_client_entitlement_integration_test.dart` (and, if justified, `..._revocation_mapping_test.dart`).

Authorized to **create**:
- New test file `app/test/licensing/s5_client_entitlement_integration_test.dart` (primary).
- No new production files beyond the ones already in `app/lib/licensing/`; if a new model is genuinely required it must be a tightly bounded new file under `app/lib/licensing/` (e.g., `app/lib/licensing/entitlement_cache_meta.dart`) justified by repository evidence — never a wildcard.

**Explicitly NOT authorized by this allowlist:** any modification to `supabase/**` (all migrations, functions, tests), any modification to business data models (`app/lib/models/**`), cloud CRUD repos (`app/lib/repositories/**`), authentication/business services (`app/lib/services/**` outside the licensing bootstrap path), `app/lib/database/**`, device identity/crypto (`app/lib/licensing/device_identity.dart`, `entitlement_token.dart`, `secure_store*.dart`), or any change to installation identity semantics (S6).

---

## P. Forbidden Paths / Non-Goals

S5 implementation MUST NOT (unless a directly required tiny compatibility seam is proven unavoidable and separately governed):

```text
NO new Supabase migration
NO production database deployment
NO RLS redesign
NO S4 device-approval implementation
NO per-install cryptographic keypair generation
NO Android Keystore device-key implementation
NO Windows DPAPI device-key implementation
NO proof-of-possession implementation
NO Owner device-management UI
NO pending-device approval UI
NO dedicated S8 clock/tamper enforcement
NO Ed25519 retirement
NO full P-OD13 CASE 1–20 convergence
NO Group B deployment
NO Group B closeout
NO Group D planning
NO Group D implementation
NO Android release build
NO AAB upload
NO Play publication
NO P-OD7 drain activation/change
NO Migration 30 modification
NO editing migrations 00031..00034
NO production mutation
```

Slice ownership is respected: S6 = secure platform device identity; S7 = owner device-management UI; S8 = tamper/cache/clock enforcement; S9 = Ed25519 retirement; S10 = test/security convergence; S11 = deployment/verification governance; S12 = final Group B closeout.

---

## Q. Test Matrix

### Existing tests (preserve / classify)

| File / group | Classification for S5 |
|--------------|-----------------------|
| `app/test/licensing/cloud_licensing_test.dart` — `EntitlementResult` parsing group | **Preserve**; extend for `is_revoked`/`revoked_at` + malformed/missing-field fail-closed cases. |
| `... `EntitlementSnapshot` group (serialization round-trip, blocksWrites for expired/revoked/suspended, allows for active trial/paid) | **Preserve**; extend for revocation metadata round-trip + cache-corruption fail-safe + shop-scope isolation. |
| `...` OfflineGracePolicy group (trial 0, paid 7, perpetual 14, cached non-entitled, clock-backwards) | **Preserve** (unchanged semantics); these already bind grace. |
| `...` LicenseException classes group | **Preserve**. |
| `...` CloudEntitlementSnapshot allowsWrites/blocksWrites group | **Preserve**; add missing REVOKED-server-precedence scenario. |
| `cloud_session_resume_binding_test.dart`, `seller_login_flow_test.dart`, `session_resume_binding_test.dart` | **Preserve**; regression only (S5 must not regress bootstrap/resume). |
| Supabase pgTAP tests `s1..s4.*.test.sql` + `s3_revocation_offline_grace_authority.test.sql` | **Preserve / regression** (S5 must not regress server slices). |

### Tests the future S5 implementation session must add/satisfy

Message: **do not invent an arbitrary assertion count to mimic S1–S4.** Counts below are derived by enumerating scenarios; each bullet is a required scenario.

**A. Server mapping & state resolution (per-row→client state):**
1. ACTIVE paid → `entitled`, writes allowed.
2. TRIAL active → `entitled`, writes allowed.
3. TRIAL expired (trial_active=false) → `expired`, writes blocked.
4. REVOKED via `license_status='REVOKED'` with `is_revoked=true` AND when `has_license=false` → MUST map to `revoked` (H-Gap-1 precedence), writes blocked.
5. EXPIRED → `expired`, writes blocked.
6. SUSPENDED → `suspended`, writes blocked.
7. no license (`has_license=false`, no revoked/suspended/expired) → `noLicense`, writes blocked.
8. `is_revoked=true`/`revoked_at` parsed from S3 16-column surface.
9. unlimited enterprise (`max_devices==null`) → `device_slot_available` stays true / unlimited semantics.
10. malformed/missing fields → FAIL CLOSED (blocked), no fabricated entitlement.
11. server-time handling: `server_time` captured as authoritative anchor.
12. subscription-expiry handling: `subscription_expires_at` consumed for status/grace decisions where server-authoritative.

**B. Cache contract:**
13. cache save/load round trip (with revocation + version metadata).
14. cache corruption / malformed JSON → fail-safe (treated as no cache / blocked).
15. cache cannot grant NEW entitlement (an empty/absent/corrupt cache never yields `entitled`/`entitledCached`).
16. cached revoked/non-entitled state blocks writes (offline).
17. shop-scoped cache isolation (shop A snapshot never used for shop B).
18. cache version/schema mismatch → treated as non-authoritative, blocked pending revalidation.

**C. Offline grace:**
19. TRIAL offline = zero grace (blocked offline even if trial active).
20. PAID offline = seven days (entitledCached within window; staleOffline after).
21. PERPETUAL compatibility = fourteen days.
22. cached non-entitled respected offline (never overridden by grace).

**D. Convergence / reconnect:**
23. revalidation replaces stale cache with fresh server truth.
24. reconnect convergence: revoked-while-offline converges to blocked on revalidation; re-entitled converges to allowed.

**E. Backward compatibility (justified only):**
25. parsing remains backward-compatible with pre-S3 payloads where S5 mapping can safely default (document any default; missing revocation signal must still fail closed, never grant).

### Regression suites the S5 implementation must run (later gate)
- S1 pgTAP regression, S2 pgTAP regression, S3 pgTAP regression, S4 pgTAP regression.
- Relevant Flutter entitlement/licensing tests (cloud_licensing_test.dart + new S5 tests).
- Relevant cloud-session tests (session-resume/login-flow binding).
- Full Flutter test suite where operationally practical.
- `dart analyze` / `flutter analyze` per repository precedent.

No test may be deleted, skipped, weakened, or rewritten merely to manufacture green status. Any pre-existing failure must be provenance-classified; known historical unrelated failures must not be relabeled as S5 failures.

---

## R. Regression Gates

The future S5 implementation must not regress already remote-locked server slices. At minimum the S5 implementation session must pass/gate:
- S1–S4 pgTAP regressions (server authority).
- Flutter entitlement/licensing + cloud-session regressions.
- Full Flutter suite where operationally practical.
- `dart analyze` / `flutter analyze`.

Any failure is provenance-classified before attribution to S5.

---

## S. Rollback / Compatibility Considerations

- S5 is **client-only**; no server migration, so there is no server rollback surface created by S5.
- S5 must preserve backward-compatible parsing of the pre-S3 and S3 server payloads (no regression for older committed server surface), while failing closed on missing revocation security signals.
- Cache schema/version additions must be forward-compatible: a cache written by a future version must be readable by the current build in a fail-safe manner (never trust unknown schema for entitlement).
- If an S5 cache/version change would mismatch an older build, the version metadata must route to "treat as non-authoritative, revalidate" rather than granting entitlement.
- Removal of any currently-committed behavior (e.g., the 24h revalidation cap) already happened in a prior slice and is not reopened.

---

## T. Acceptance Criteria

S5 is complete (in the future, separately-authorized implementation session) only when:
1. `verify_license_entitlement` 16-column surface (incl. `is_revoked`/`revoked_at`) is mapped on the client.
2. H-Gap-1 is resolved: authoritative REVOKED maps deterministically to `revoked` and blocks writes in all cases.
3. H-Gap-2 is resolved: revocation metadata is carried through repository → snapshot → cache, and cached revoked/non-entitled state blocks writes offline.
4. Server remains the security authority; the cache cannot create new entitlement.
5. Offline grace contract holds: TRIAL 0 / PAID 7 / PERPETUAL 14.
6. Fail-closed holds for malformed/missing/unknown security-relevant state, corrupt cache, cache version/schema mismatch.
7. Reconnect revalidation converges client state to server truth.
8. `allowsWrites` is `true` only for `entitled` and `entitledCached`.
9. All Q-matrix scenarios pass; all regression gates pass; no test deleted/weakened to green.
10. No server migration, no DB deployment, no RLS change, no device-key crypto, no S6/S7/S8/S9 implementation.

---

## U. Successor Boundary

```text
S5 GOVERNANCE SUCCESS != S5 IMPLEMENTATION AUTHORIZATION
```

After this governance is remote-locked:

```text
S5_IMPLEMENTATION = NOT_STARTED
S6 = NOT_STARTED
S7 = NOT_STARTED
S8 = NOT_STARTED
S9 = NOT_STARTED
S10 = NOT_STARTED
S11 = NOT_STARTED
S12 = NOT_STARTED
GROUP_D = DEFERRED
```

A separate, explicit Owner authorization / session is required before S5 implementation begins. This governance session stops after its own remote lock.

---

## V. Separate Owner Authorization Requirement for S5 Implementation

S5 **implementation** is NOT authorized by this document. A future S5 implementation session MUST:
- cite this governance artifact as the controlling contract,
- request and receive an explicit Owner approval to begin S5 implementation,
- then follow the same governance → implementation → remote-lock protocol (normal commit, normal fast-forward push to `github`, no force/reset/rebase/amend).

This governance session performs no S5 implementation and creates no S5 production/test source changes.

---

## X. Mandatory Prohibited-Action Proof (this governance session)

```text
S5_IMPLEMENTATION_STARTED       = NO
FLUTTER_PRODUCTION_SOURCE_CHANGED = NO
FLUTTER_TEST_IMPLEMENTATION_CHANGED = NO
SUPABASE_MIGRATION_CREATED      = NO
SUPABASE_MIGRATION_CHANGED      = NO
EDGE_FUNCTION_CHANGED           = NO
RLS_CHANGED                     = NO
SUPABASE_PRODUCTION_MUTATED     = NO
S6_STARTED                      = NO
S7_STARTED                      = NO
S8_STARTED                      = NO
S9_STARTED                      = NO
S10_STARTED                     = NO
S11_STARTED                     = NO
S12_STARTED                     = NO
GROUP_B_CLOSEOUT_STARTED        = NO
GROUP_D_PLANNING_STARTED        = NO
GROUP_D_IMPLEMENTATION_STARTED  = NO
ANDROID_RELEASE_BUILD_STARTED   = NO
AAB_UPLOAD_STARTED              = NO
PLAY_PUBLICATION_STARTED        = NO
LEGACY_ORIGIN_CONTACTED         = NO
FORCE_PUSH_USED                 = NO
RESET_REBASE_AMEND_USED         = NO
```

---

## Y. Governance Artifact Proof

Single tracked governance artifact authored by this session:

```text
PATH = docs/PHASE_P_GROUP_B_S5_CLIENT_ENTITLEMENT_INTEGRATION_IMPLEMENTATION_GOVERNANCE.md
```

Verified before commit: no pre-existing committed artifact at this path (conflict check = none). No competing S5 naming authority exists in the repository at governance time.

The only tracked delta of this session is this single file.
```
