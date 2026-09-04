# Phase P — Group B — S9 Legacy Ed25519 Retirement

## Implementation Governance

**Document purpose:** Freeze the exact future implementation contract for Group B **S9 — Legacy Ed25519 Retirement** against the committed server-authoritative entitlement, device-trust, secure-identity, and S8 tamper/cache/clock system. This is a **governance-only** artifact. It does **NOT** implement S9, does **NOT** remove/disable/isolate any Ed25519 path, and authorizes nothing beyond the exact contract recorded here. A governance remote-lock is **not** an implementation authorization.

---

## A. Session identity

```text
SESSION =
PHASE_P_GROUP_B_S9_LEGACY_ED25519_RETIREMENT_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY_FAIL_CLOSED

AUTHORIZED_UNIT =
S9 — LEGACY ED25519 RETIREMENT

SESSION_NATURE      = GOVERNANCE ONLY
AUTHORIZED_TRACKED_OUTPUT = EXACTLY_ONE_NEW_GOVERNANCE_ARTIFACT (this file)

PREDECESSOR_S8_IMPLEMENTATION = 7460f915197db06309aff905be91c10b379b4ab4

EXPECTED_SUCCESS_TOKEN =
PASS_PHASE_P_GROUP_B_S9_LEGACY_ED25519_RETIREMENT_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
```

**Non-authorizations (this session does NOT authorize):**

```text
S9_IMPLEMENTATION_STARTED = NO
S10_STARTED               = NO   (test/security convergence — separate slice)
GROUP_C_STARTED           = NO
GROUP_D_STARTED           = NO   (DEFERRED — Group B first)
SYNC_DRAIN_CHANGED        = NO
PRODUCTION_MUTATED        = NO
LEGACY_ORIGIN_CONTACTED   = NO
ANY_SQL_MIGRATION         = NO
ANY_RPC_CHANGE            = NO
ANY_RLS_CHANGE            = NO
ANY_AUTH_CHANGE           = NO
ANY_EDGE_FUNCTION_CHANGE  = NO
ANY_ANDROID_SIGNING       = NO
```

---

## B. Repository identity

```text
ROOT   = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze

AUTHORIZED_REMOTE      = github
EXPECTED_GITHUB_URL    = https://github.com/sabere342-ai/muaman.worktrees.git
VERIFIED_GITHUB_URL    = https://github.com/sabere342-ai/muaman.worktrees.git   (MATCH)

LEGACY_REMOTE          = origin
LEGACY_ORIGIN_PATH     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن
LEGACY_ORIGIN_POLICY   = SACRED READ-ONLY — NEVER FETCH / PULL / PUSH / ls-remote /
                         remote update / prune / set-url / rename / remove.
```

All network Git operations target **`github`** only. `origin` is never contacted.

---

## C. Entry / Recovery classification

Verified before any mutation, on the authorized remote `github` only:

```text
LOCAL_HEAD          = 7460f915197db06309aff905be91c10b379b4ab4
TRACKING_HEAD       = 7460f915197db06309aff905be91c10b379b4ab4
DIRECT_REMOTE_HEAD  = 7460f915197db06309aff905be91c10b379b4ab4   (git ls-remote github)
MERGE_BASE          = 7460f915197db06309aff905be91c10b379b4ab4
AHEAD               = 0
BEHIND              = 0
Index state         = clean (empty staged diff)
Tracked worktree    = clean (no tracked modifications, git diff --name-only HEAD empty)
Active git op       = none (no MERGE_HEAD / REBASE_merge / REBASE_apply / CHERRY_PICK_HEAD /
                            REVERT_HEAD / BISECT_LOG)
```

**Classification: CASE_A_FRESH** — proceed. No recovery action required. No reset/rebase/amend/clean performed.

Untracked pre-existing **sacred evidence** is present and remains untouched, un-staged, un-deleted:
`GROUP_A_PHASE_P_OD7_*_REPORT.md`, `GROUP_A_PHASE_Q_*_FAILED_SESSION_REPORT.md`,
`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`,
`delivery/I-TECH-Delivery-v1.0.0.zip`, `supabase/.branches/`, `supabase/.temp/`.

---

## D. Authority chain (Group B plan → S8 → S9)

Authority is reconstructed from committed material, not from this prompt alone. Fully resolved linear chain
(governance → implementation, at minimum S5 onward):

```text
9ecdc38   docs(roadmap): plan Phase P Group B            (GROUP_B_PLAN)
45018ee   docs(roadmap): govern S1
334d1ad   feat: implement Group B S1 server data model foundation
a4fcada   docs(roadmap): govern S2
85e4315   feat: implement S2 server entitlement quota authority
7d05313   docs: govern S3
62af446   feat: implement S3 revocation offline-grace authority
2df4dc7   docs: govern S4
5309749   docs: correct S4
b8889bf   feat: implement S4 device trust server gate + invitation hardening
fe03d6b   docs: govern S5
5801cea   feat: implement S5 client entitlement integration
b4e95e4   docs: govern S6 platform secure device identity
69218da   feat: implement S6 platform secure device identity
665d996   docs: govern S7 owner device management
a67996a   feat: implement S7 owner device management
2176155   docs: govern S8 tamper cache clock enforcement
7460f91   feat: implement S8 tamper cache clock enforcement      ← CURRENT HEAD (S9 BASELINE)
```

**S8 predecessor (proven, exact):**

```text
S8_GOVERNANCE     = 217615514cb83aba0a629e01e619e418094fd9ae
S8_IMPLEMENTATION = 7460f915197db06309aff905be91c10b379b4ab4   (current HEAD)
S8_SUBJECT        = feat: implement Group B S8 tamper cache clock enforcement
```

The immediate successor of S8 per the committed Group B plan and the S8 governance artifact is **S9 — Legacy
Ed25519 Retirement**. `S9_SUCCESSOR_OF = 7460f915`.

---

## E. Exact S9 ownership (successor contract)

Frozen from committed evidence (Group B plan `9ecdc382:PHASE_P_OWNER_GATED_GROUP_B_PLAN.md`):

```text
S8_OWNER  = Tamper / cache / clock enforcement convergence
S9_OWNER  = Legacy Ed25519 retirement (evidence-gated isolation; tests)
              → dependencies: S5 (prove no production dependency); independent evidence gate
S10_OWNER = Test / security convergence (P-OD13 CASE 1–20 matrix, RLS, quota, offline,
              revocation, tamper, cross-tenant, Android/Windows identity, reconnect)
```

**The full 1–20 final security-matrix convergence belongs to S10, NOT S9.** S9 owns only the legacy
Ed25519 retirement boundary. It does not absorb S4/S6/S7 device-trust, RLS, quota, or invitation
convergence responsibilities; those are covered/owned by other slices as already committed.

P-OD12 maps to S9: `P-OD12 = Legacy Ed25519 retirement/isolation (evidence-gated)`.

---

## F. P-OD12 retirement gate — FAIL CLOSED

**Authoritative gate wording** (`PHASE_P_OWNER_DECISIONS.md`; confirmed by Group A plan, Group B plan,
successor-scope determination):

```text
P-OD12 = legacy token/signature path must not remain exposed as if active only after evidence
         proves no required production path depends on it.

EVIDENCE = Repository evidence that no required production path depends on the legacy seam.
STATUS   = APPROVED (conditional on evidence)
```

**Freeze of the gate result:**

```text
P_OD12_RETIREMENT_GATE = SATISFIED
```

**Basis (repository-verifiable, frozen here):**

1. **Legacy authority is superseded.** The only production enforcement wiring is
   `main.dart:200-201` → `DatabaseHelper.setLicensingEnforcer(() => cloudLicensingService.enforceActive())`.
   `main.dart:196` states *"CloudLicensingService replaces the old LicensingService"*. The legacy
   `LicensingService` is never registered as the enforcement boundary and its `initialize()` has **no**
   production call site (searched all `app/lib` → no call). Therefore legacy `LicensingService` is never
   authority at runtime.
2. **Legacy path cannot grant entitlement.** `entitlement_token.dart:344` sets
   `_defaultTrustedKeys = <TrustedKey>[]` (empty). `EntitlementVerifier.verify` key_id lookup
   (`entitlement_token.dart:256-264`) always returns `UNKNOWN_KEY_ID` → failure. Even if reached, the
   legacy verifier cannot grant.
3. **Legacy activation cannot succeed.** `licensing_service.dart:412-430` — `ActivationClient.activate`
   / `deactivate` always throw `SocketException('Activation server not yet deployed')`. No activation
   flow depends on the legacy seam succeeding.
4. **No required production path depends on the legacy seam.** Session bootstrap/resume and offline
   grace go entirely through the canonical cloud service: `cloud_session_resume.dart:78-81`,
   `seller_session_provisioning.dart:303-306` — both use `CloudLicensingService.instance`. The runtime
   write/entitlement gate is `CloudLicensingService.enforceActive()` only.
5. **No test depends on the legacy path.** No `app/test` file imports `entitlement_token.dart` or the
   legacy `licensing_service.dart`, and none references `EntitlementVerifier`/`EntitlementToken`/
   `parseSigned`. (Legacy-adjacent `device_identity_provider_test.dart` covers the hardware fingerprint
   metadata, which is retained, not the entitlement token.)
6. **No server authority depends on the legacy entitlement-token Ed25519 path.** Migrations `00034`
   (S4) and `00035` (S6) reference Ed25519 only as the S6 device proof-of-possession seam; the invitation
   `token_hash` is a SHA-256 digest, not a legacy entitlement token. The edge functions
   `s6-device-pop/index.ts` (S6 PoP verifier) and `invite-employee/index.ts` (invitation) do not verify
   legacy entitlement tokens. The canonical `verify_license_entitlement` RPC is server-authoritative
   SQL.

Because the evidence that no required production path depends on the legacy seam is demonstrable from
committed source + call-graph + empty-trusted-key + server-surface probe, the P-OD12 gate is **SATISFIED**.
This authorizes a future S9 implementation (separate Owner implementation order) to retire/isolate the
legacy seam. **This session performs NO retirement.**

---

## G. Legacy Ed25519 inventory (forensic discovery)

Read-only discovery at HEAD. Every relevant surface, with role classification:

```text
PATH                                                       CLASSIFICATION
---------------------------------------------------------- -------------------------------------
app/lib/licensing/entitlement_token.dart                   DEAD_CODE_CANDIDATE
  EntitlementToken / ParsedToken / Entitlements             — legacy CBOR Ed25519 token model
  EntitlementVerifier / TokenVerificationResult             — legacy Ed25519 verifier
  TrustedKey / _defaultTrustedKeys (empty)                  — no trusted key ever populated
app/lib/licensing/licensing_service.dart                   LEGACY (superseded, UI display only)
  LicensingService (initialize/activate/deactivate/enforce)  — never initialized; not authority
  ActivationClient (398-432)                                 — always throws (not yet deployed)
  LicensingSnapshot / LicensingState                         — status surface only
app/lib/screens/settings/settings_screen.dart (90/893/
  899/927/930 legacy "الترخيص" card)                        LEGACY (UI/status display only)
app/lib/licensing/licensing.dart (barrel exports :21/:23)   LEGACY export surface
app/lib/licensing/device_identity.dart                      COMPATIBILITY_BRIDGE (metadata only)
app/lib/platform/device_identity_provider.dart              COMPATIBILITY_BRIDGE (metadata only)
```

**Canonical S6/S8 path (MUST be preserved, NOT part of the legacy retirement):**

```text
app/lib/licensing/s6_device_identity.dart     CANONICAL  per-install Ed25519 device identity
app/lib/licensing/s6_proof_of_possession.dart CANONICAL  S6 canonical PoP envelope + verify
app/lib/licensing/s8_cache_integrity.dart     CANONICAL  S8 device-bound signed cache
app/lib/licensing/entitlement_cache.dart      CANONICAL  cache snapshot + authenticated save/load
app/lib/licensing/offline_grace_policy.dart   CANONICAL  grace-window authority
app/lib/licensing/cloud_licensing_service.dart CANONICAL runtime authority + S8 orchestration
app/lib/licensing/cloud_licensing_repository.dart CANONICAL RPC gateway
app/lib/screens/settings/license_status_screen.dart CANONICAL cloud display (206 lines, non-gating)
```

**Critical P-OD12 distinction (must be preserved in every downstream artifact):**

```text
LEGACY ENTITLEMENT-TOKEN ED25519   ≠   S6 DEVICE PROOF-OF-POSSESSION ED25519
LEGACY ENTITLEMENT-TOKEN ED25519   ≠   S8 CACHE-INTEGRITY ED25519 (S6-device-signed)
```

S9 retires the **legacy entitlement-token** Ed25519 and its superseded `LicensingService` surface. The
S6 per-install identity, S6 PoP, and S8 device-bound cache integrity (all Ed25519) are **canonical** and
must remain intact and enforced.

---

## H. Legacy-vs-canonical cryptographic authority map

```text
Authority seam                    Class            Server authority      Retention
---------------------------------------------------------------------------------------------
verify_license_entitlement RPC    CANONICAL        yes (SQL)             KEEP
s6_enroll_public_key (00035)      CANONICAL        yes (SQL)             KEEP
s6-device-pop edge function       CANONICAL        yes (edge + SQL)      KEEP
s6_create_challenge / PoP         CANONICAL        yes (edge)            KEEP
S6DeviceIdentity (DPAPI/Keystore) CANONICAL        no (client)           KEEP
S8CacheIntegrity (device-bound)   CANONICAL        no (client)           KEEP
EntitlementVerifier (token)       DEAD_CODE_CANDIDATE  no               RETIRE (allowed)
EntitlementToken (CBOR model)     DEAD_CODE_CANDIDATE  no               RETIRE (allowed)
TrustedKey / _defaultTrustedKeys  DEAD_CODE_CANDIDATE  no               RETIRE (allowed)
LicensingService (legacy)         LEGACY           no                    ISOLATE/REMOVE (allowed)
ActivationClient                  LEGACY           no (no server)        ISOLATE/REMOVE (allowed)
Legacy settings card              LEGACY           no                    REWIRE/REMOVE (allowed)
DeviceIdentity hardware fingerprint COMPATIBILITY_BRIDGE  no             KEEP (compatibility metadata)
```

No `UNKNOWN` classifications remain: every discovered surface is classified
`CANONICAL`, `LEGACY`, `DEAD_CODE_CANDIDATE`, or `COMPATIBILITY_BRIDGE`.

---

## I. Dependency graph (per legacy component)

```text
component:  EntitlementToken / EntitlementVerifier (entitlement_token.dart)
caller(s):  LicensingService (licensing_service.dart:50,100,108,180,198)
consumer(s): none at runtime (LicensingService never initialized; not authority)
data/state: CBOR payload + signature bytes in legacy LicensingState (AppSettings legacy path)
canonical replacement: CloudLicensingService + verify_license_entitlement; S6/S8 not token-based
retirement strategy: REMOVE (safe: not trusted, not reached, not tested)
compatibility risk: none for canonical path; only the legacy UI card needs rewiring/removal
test obligation: none exist; no legacy tests to migrate (Section P)

component:  TrustedKey / _defaultTrustedKeys (entitlement_token.dart)
caller(s):  EntitlementVerifier default
consumer(s): none (empty set)
data/state: none
canonical replacement: none needed (server public-key binding is canonical)
retirement strategy: REMOVE
compatibility risk: none
test obligation: none

component:  LicensingService + LicensingSnapshot + ActivationClient (licensing_service.dart)
caller(s):  settings_screen.dart (90/893/899/927/930); barrel licensing.dart
consumer(s): settings "الترخيص" card (display only)
data/state: legacy LicensingState (AppSettings), hardware fingerprint
canonical replacement: CloudLicensingService + settings cloud card
retirement strategy: ISOLATE → REMOVE via UI rewire
compatibility risk: only the legacy settings card visual; no authority/security impact
test obligation: no legacy tests; ensure no canonical path regresses

component:  legacy settings "الترخيص" card (settings_screen.dart)
caller(s):  settings UI
consumer(s): user-facing status display
canonical replacement: cloud entitlement card
retirement strategy: REMOVE / REWIRE to cloud (retain a truthful display if desired)
compatibility risk: UI only
test obligation: widget tests for settings if the card changes

component:  DeviceIdentity hardware fingerprint (device_identity.dart + provider)
caller(s):  LicensingService (superseded); retained as compatibility metadata
consumer(s): legacy service only
canonical replacement: S6DeviceIdentity (cryptographic possession)
retirement strategy: KEEP_FOR_COMPATIBILITY (metadata; S6 §I/AC18 — never treated as authority)
compatibility risk: none (never authority)
test obligation: keep device_identity_provider_test.dart green

component:  licensing.dart barrel exports of legacy symbols
caller(s):  surfaces importing the barrel
consumer(s): settings_screen.dart
canonical replacement: remove legacy exports; keep canonical exports
retirement strategy: MIGRATE (adjust exports only when legacy consumers are removed)
compatibility risk: compile-time only, managed in the implementation
test obligation: full Dart compile + analyzer must stay green
```

**Feasibility result:**

```text
S9_IMPLEMENTATION_FEASIBILITY = PROVEN
```

Rationale: the legacy entitlement-token Ed25519 path is verifiably superseded, non-authoritative,
non-granting, untested, and un-depended-upon by any production or server surface; retirement is safe
without weakening the canonical S6/S8 model.

---

## J. Server schema / RPC / Edge delta gate

Frozen with evidence (no migration invented to "have an S9 migration"):

```text
S9_SERVER_SCHEMA_RPC_DELTA = NONE
S9_RPC_DELTA               = NONE   — verify_license_entitlement + S6 PoP route are wholly canonical
S9_EDGE_FUNCTION_DELTA     = NONE   — s6-device-pop + invite-employee unchanged
S9_RLS_DELTA               = NONE
S9_AUTH_DELTA              = NONE
S9_MIGRATION               = NO     — NO `00036` is authorized or reserved by this governance
S9_CLIENT_DELTA            = REQUIRED — client-side (app/ Dart) retirement/isolation of legacy surface
HIGHEST_COMMITTED_MIGRATION = 20260820000035_phase_p_group_b_s6_platform_secure_device_identity.sql
```

Existing server authority (S2/S3 RPC, S4/S6 device-trust, RLS model, S6 PoP edge function) is
sufficient; no server change is required to retire a client-side dead entitlement-token seam.

---

## K. Compatibility / upgrade / retirement safety proof

Analysis of the Section 10 factors:

```text
A. Active-client compatibility  — No installed client relies on the legacy path for authority.
   The runtime authority is CloudLicensingService.enforceActive(); the legacy card is display-only.
B. Existing device registrations — Canonical enrollment uses S6 public-key binding (00035), not the
   legacy token. Existing enrolled devices hold canonical S6 material, not legacy tokens.
C. Offline authentication/licensing — Offline authority is the S6/S8 signed cache + server-backed
   grace (S8). The legacy token path contributes nothing to offline grants (empty trusted keys).
D. S8 signed-cache compatibility — S9 does not touch s8_cache_integrity / entitlement_cache /
   offline_grace_policy / cloud_licensing_service. S8 anti-replay, high-water, public-key binding,
   and cache signature verification remain intact (invariant R3/R4, see Section M).
E. Invitation/device trust — S4/S6/S7 invitation + device flows use S4/S6 PoP and invitation token
   hash (SHA-256), not legacy entitlement tokens; unaffected.
F. Server-side verification — No RPC / Edge Function / DB state accepts or requires legacy
   entitlement-token Ed25519 material; server authority is canonical S2/S3 + S6 PoP.
G. Migration/upgrade — Because no live production or test path depends on the legacy seam, a hard
   client-side removal is safe after the implementation removes the legacy card consumers. No staged
   server migration is required. The compatibility bridge (hardware fingerprint) is retained as metadata.
H. Rollback safety — A downgrade to a build that still references the legacy barrel/symbols would fail
   to compile if symbols are removed; the implementation must therefore coordinate removal of the
   legacy consumers (settings card) in the same slice and keep the canonical enforcer untouched.
I. Key-material preservation — Retirement never serializes or exposes private seed/private-key. The S6
   private seed stays in DPAPI/Keystore; no legacy private key material exists in the repo.
```

**Compatibility strategy (Section 16.N):** Given the proof, the frozen future strategy is:

```text
S9_COMPATIBILITY_STRATEGY = STAGED_RETIREMENT
   Stage 1 — remove the legacy entitlement-token Ed25519 surface (entitlement_token.dart symbols)
             and the superseded LicensingService/ActivationClient, and rewire/remove the legacy
             settings card, in one coordinated slice so no dangling reference remains.
   Stage 2 — keep the canonical S6/S8/cloud surfaces and the hardware-fingerprint compatibility
             bridge untouched; verify no legacy reference remains reachable.
```

---

## L. Forbidden paths / sacred surfaces

```text
supabase/**                     FORBIDDEN (no schema/RPC/Edge/RLS/Auth/migration change)
app/lib/licensing/s6_device_identity.dart        FORBIDDEN (canonical; preserve)
app/lib/licensing/s6_proof_of_possession.dart    FORBIDDEN (canonical; preserve)
app/lib/licensing/s8_cache_integrity.dart        FORBIDDEN (canonical; preserve)
app/lib/licensing/entitlement_cache.dart         FORBIDDEN (canonical S8; preserve)
app/lib/licensing/offline_grace_policy.dart      FORBIDDEN (canonical; preserve)
app/lib/licensing/cloud_licensing_service.dart   FORBIDDEN (canonical authority; preserve)
app/lib/licensing/cloud_licensing_repository.dart FORBIDDEN (canonical; preserve)
app/lib/screens/settings/license_status_screen.dart FORBIDDEN (canonical cloud display)
app/lib/services/cloud_session_resume.dart       FORBIDDEN (canonical)
app/lib/services/seller_session_provisioning.dart FORBIDDEN (canonical)
app/test/licensing/s6_*, s8_*, cloud_*, phase_e_*, s5_* FORBIDDEN (canonical test floors)
supabase/functions/**            FORBIDDEN
supabase/tests/cloud_stock_adjustments.test.sql   FORBIDDEN (pre-existing out-of-scope defect)
origin remote                    FORBIDDEN (SACRED, never contacted)
Aleatory untracked evidence      FORBIDDEN (never staged/deleted)
```

No change to any canonical or server surface is authorized by this governance.

---

## M. Security invariants

The future S9 implementation **must not** weaken or alter:

```text
I1  Private-key material is NEVER serialized into plaintext cache (S6 seed stays in protected store).
I2  Canonical S6 private seed remains protected (DPAPI/Keystore), never logged/exported/plaintext.
I3  No weaker cryptographic fallback is introduced; the visible algorithm set is unchanged.
I4  Verification remains fail closed (unknown/malformed/unsigned input never grants).
I5  Tenant/user/device boundaries preserved (S8 canonical payload binding unchanged).
I6  S8 anti-replay / high-water (lastTrustedServerTimeUtc) semantics preserved.
I7  After authorized retirement, legacy acceptance is NOT silently reachable; any legacy reference
    is removed, not merely dormant.
I8  Older malformed/unknown data cannot become trusted (S8 version/integrity fail-closed stays).
I9  Server authority remains supreme (R1-equivalent); local state never creates stronger entitlement.
I10 Revocation (REVOKED/LOST/EXPIRED) stays irreversible from stale local evidence.
I11 Terminal device states stay terminal; S9 introduces no restoration seam.
I12 No secret bytes (seed/key/JWT/token/password) appear in any diff or artifact.
```

---

## N. Regression floors (must not be reduced)

Preserved, current known passing floors (established at the S8 implementation remote lock):

```text
S8_TARGETED   = 41 / 41  PASS   (app/test/licensing/s8_tamper_cache_clock_test.dart)
LICENSING     = 216      PASS   (app/test/licensing/ suite)
FULL_DART     = 1704     PASS   (full `flutter test`)
```

A future S9 implementation must keep these floors green (do not delete/weaken canonical tests to
obtain green). It may add S9-specific tests (Section P). Any legitimate test-ownership change must be
explicitly justified.

---

## O. Future S9 implementation exact file allowlist

Freeze the **minimal exact tracked-path allowlist** for a separate Owner-authorized S9 implementation.
No file below is modified in this governance session:

```text
app/lib/licensing/entitlement_token.dart                    — REMOVE legacy token/verifier surface
app/lib/licensing/licensing_service.dart                    — REMOVE/ISOLATE superseded LicensingService
                                                            + ActivationClient + legacy snapshot state
app/lib/screens/settings/settings_screen.dart               — REMOVE/REWIRE the legacy "الترخيص" card
                                                            and its LicensingService.instance calls
app/lib/licensing/licensing.dart                            — remove legacy barrel exports (keep canonical)
+ NEW app/test/licensing/s9_legacy_ed25519_retirement_test.dart — S9 test file (scenario matrix, Section P)
```

**Explicitly forbidden patterns:** `app/**`, `supabase/**`, and any broad glob. No modification of the
canonical S6/S8/cloud files listed in Section L. The hardware-fingerprint compatibility bridge
(`device_identity.dart`, `device_identity_provider.dart`) is retained and must **not** be deleted.

If the implementation discovers an additional legacy consumer beyond the allowlist, it must STOP and
report rather than broaden scope.

---

## P. Future S9 test contract (define, do not implement)

The future S9 implementation must add `app/test/licensing/s9_legacy_ed25519_retirement_test.dart`
covering all applicable cases:

```text
1.  canonical S6 proof continues to verify (s6 PoP untouched).
2.  legacy-only verification path is no longer reachable after authorized retirement (no
    EntitlementVerifier/parseSigned reference).
3.  unknown legacy signature format fails closed (never grants).
4.  malformed signatures fail closed.
5.  legacy private-key/seed material is never migrated into plaintext.
6.  S8 authenticated cache remains valid under canonical identity.
7.  replay/rollback protection remains intact.
8.  protected trusted-time high-water remains intact.
9.  valid existing canonical enrolled device survives upgrade (S6 identity reuse).
10. user boundary remains enforced.
11. shop boundary remains enforced.
12. revoked entitlement remains revoked.
13. stale authority remains stale.
14. no silent fallback from canonical verification to legacy verification.
15. migration/compatibility behavior matches P-OD12 (staged retirement per Section K).
16. older unsupported state fails safely.
17. invitation/device-trust regressions remain green (S4/S6/S7).
18. licensing regressions remain green (LICENSING floor).
19. full Dart regression remains at or above the governed floor (FULL_DART).
20. compiler/analyzer confirms no dangling legacy references survive the removal.
```

Security-negative cases are required, not only happy paths. No S9 tests are created in this session.

---

## Q. Sync drain / durability / subscription boundaries

```text
SYNC_DRAIN_CHANGE = FORBIDDEN    (syncDrainEnabled not flipped; defaults FALSE)
```

No drain activation, no subscription-tier / grace-window / billing / entitlement-quota / durability /
cache-redesign / invitation-redesign / device-management-redesign / Group D work is combined with S9.

---

## R. No-secrets requirement

No private seed / JWT / token / password / service-role key / upload key may appear in any diff or
committed artifact. Tests use synthetic fixtures only (reuse the S6 golden-vector discipline; never
production material). `git diff --check` and a secret scan must pass.

---

## S. Rollout / rollback assumptions (no deployment performed)

```text
ROLLOUT   = Next release ships the S9 removal in one coordinated client slice (legacy surface +
            consumers removed together) so no dangling reference exists in any published build.
ROLLBACK  = A pre-S9 build can be re-issued; canonical S6/S8/cloud authority is unaffected.
            No server deployment, no migration, no Edge change, no production Supabase mutation.
```

These are planning assumptions; this session performs no deployment.

---

## T. STOP boundary

This governance artifact, including a `PROVEN` feasibility result and a `SATISFIED` P-OD12 gate, does
**NOT** authorize S9 implementation. `GOVERNANCE_REMOTE_LOCKED` ≠ `IMPLEMENTATION_AUTHORIZED`.

A separate explicit Owner implementation order is required before any S9 code is written. After this
governance remote-lock:

```text
DO NOT IMPLEMENT S9.
DO NOT REMOVE / ISOLATE / DISABLE ANY Ed25519 PATH.
DO NOT CREATE MIGRATION 00036.
DO NOT MODIFY ANY CANONICAL S6/S8/CLOUD FILE.
DO NOT START S10 / GROUP C / GROUP D.
DO NOT DEPLOY / MUTATE PRODUCTION / FLIP SYNC DRAIN.
```

---

## U. Recording pre-existing (out-of-scope) findings

Truthfully recorded, NOT modified by this session:

```text
app/lib/screens/settings/device_management_screen.dart:4   unused import '../../models/user_role.dart'
   (pre-existing analyzer info predating S9; untouched).
supabase/tests/cloud_stock_adjustments.test.sql            pre-existing SQL defect
   (pg_get_constraintdef(oid) without FROM, exit = 3; predates S7; untouched unless separately authorized).
```

---

## V. Commit / push contract

- ONE governance-only commit of exactly this artifact.
- Pre-commit profile: `git status --short` + `git diff --name-status` show the artifact is the only new
  tracked mutation; stage the exact path only (never `git add .` / `-A`).
- Committed tracked delta must be exactly:

```text
A docs/PHASE_P_GROUP_B_S9_LEGACY_ED25519_RETIREMENT_IMPLEMENTATION_GOVERNANCE.md
```

- Commit message: `docs: govern Group B S9 legacy Ed25519 retirement`; NO amend/rebase/squash/history
  rewrite.
- Pre-push drift gate on `github`: require `DIRECT_GITHUB_REMOTE_HEAD == 7460f915…`, AHEAD=1, BEHIND=0,
  else STOP (REMOTE_DRIFT).
- Push: exactly one normal fast-forward to `github codex/i-tech-next-roadmap-freeze`. Forbidden:
  `--force` / `--force-with-lease`, delete branch, new/tag push, push to `origin`.
- Post-push: prove LOCAL == TRACKING == DIRECT_GITHUB_REMOTE_HEAD == new S9 governance commit, AHEAD=0,
  BEHIND=0, and working tree has no tracked S9 implementation.

---

*End of S9 governance artifact.*
