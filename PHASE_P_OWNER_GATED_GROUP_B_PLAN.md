# PHASE P — OWNER-GATED GROUP B ENGINEERING PLAN

## Licensing / Commercial / Security (P-OD8..P-OD13, WS-4)

```text
SESSION                 = PHASE_P_OWNER_GATED_GROUP_B_PLANNING_REMOTE_LOCK
MODE                    = PLANNING_ONLY / EXACT_AUTHORITY_CHAIN / FAIL_CLOSED
SESSION_TYPE            = PLANNING ONLY — ZERO IMPLEMENTATION
AUTHORIZED_SCOPE        = GROUP_B_PLANNING_ONLY
TRACKED_OUTPUT          = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
IMPLEMENTATION          = NOT_STARTED
GROUP_B_IMPLEMENTATION  = FALSE
GROUP_C/D               = OUT_OF_SCOPE / DEFERRED
PRODUCTION_MUTATION     = FALSE
PLAN_PARENT             = 1a4907bc57c00126f131b458a356749abbc4421b
```

This plan is **planning only**. It does not authorize, and does not begin, any
portion of Group B implementation. Every slice below is a future implementation
artifact to be governed through its own planning → remote-lock →
implementation → remote-lock sequence. No source, config, SQL migration, test,
or production file is modified by this session; the sole tracked mutation is
this planning artifact.

---

## 1. Entry / Recovery Classification

Fresh forensic entry performed before any tracked write (see Session Contract
§7/§8). Classification: **CASE A — FRESH**.

```text
TOPLEVEL          = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
CURRENT_BRANCH    = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (SACRED READ-ONLY; never contacted)

LOCAL_HEAD                    = 1a4907bc57c00126f131b458a356749abbc4421b
REMOTE_TRACKING_HEAD          = 1a4907bc57c00126f131b458a356749abbc4421b
DIRECT_REMOTE_HEAD            = 1a4907bc57c00126f131b458a356749abbc4421b
MERGE_BASE                    = 1a4907bc57c00126f131b458a356749abbc4421b
AHEAD                         = 0
BEHIND                        = 0

TRACKED_WORKTREE              = CLEAN
INDEX                         = EMPTY
ACTIVE_GIT_OPERATION          = NONE
STASH_STATE                   = unrelated WIP on codex/muaman-13-strict-july-workbook-data-migration (not this branch; left untouched)
```

Pre-existing untracked sacred evidence was preserved and not staged or modified:

```text
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.temp/   (untracked)
```

No destructive recovery (`git reset --hard`, `git clean`, force checkout,
rebase, `--amend`, force push) was used or needed.

---

## 2. Successor Order (Owner-Locked, Immutable)

```text
OWNER_ORDER_DECISION = GROUP_B_BEFORE_GROUP_D
FIRST_SUCCESSOR      = GROUP_B_PLANNING   (THIS SESSION)
SECOND_SUCCESSOR     = GROUP_D_PLANNING   (ORDERED_SECOND_AND_DEFERRED)
```

This order is FINAL for this session. It is not reopened, recompared, or
re-asked. The only authorized current scope is GROUP_B_PLANNING.

---

## 3. Authority Register

Exact immutable authority tuple for every Group B authority item. Verified
directly from Git objects at both the originating commit and the current entry
tree (Section 4).

| Authority | Commit SHA | Path | Blob SHA | Governed requirement |
|---|---|---|---|---|
| Owner Order Decision | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | Group B before Group D; Group B planning = first successor |
| Authority-Binding Correction | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | Group B canonical scope: licensing/commercial/security; planning authorized |
| Post-Migration-30 Exact Commit Binding | `1a4907bc57c00126f131b458a356749abbc4421b` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | Binds exact post-Migration-30 authority (`f51be8cf…`); no substitution of current HEAD |
| Post-Migration-30 Authority | `f51be8cf177e5c6c616788bf7733297cd511c640` | `POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md` | `172ae7b9a4f50236c747aeb91022a34024d11b81` | Migration 30 deployed + verified; Group B defined/not started (no re-plan of Migration 30) |
| Phase P Owner Decisions | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` | `PHASE_P_OWNER_DECISIONS.md` | `3028b058c4027557dc6d26911123a8d6a1b9def2` | P-OD8..P-OD12 (below); exact tiers/grace/revocation/tamper/Ed25519 |
| Post-Owner-Decisions Governance | `f539282898f142441781010b702c6c28d7f68d4b` | `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` | `c6ae7441b2d701814895a00394257d928da5d388` | Group B boundary + mandatory planning→remote-lock→implementation→remote-lock protocol |
| Post-Group-A Successor Governance | `7feef87a3d49c2f0d9504d23352d37b700831efb` | `POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md` | `e4d4abb0de7b79893831ffc8eaae86f79c1c2407` | Residual Group B P-OD8..P-OD12 + WS-4; delivery sequencing |
| Employee Device Trust / Final Delivery | `8d27878a69cbb6c6f440c28f4f55f3ed323312d4` | `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | P-OD13 employee device trust; threat model; 20 security cases; server-authoritative device gate |

### P-OD references bound by the above authorities

| Decision | Owner requirement (exact, from `PHASE_P_OWNER_DECISIONS.md`) |
|---|---|
| P-OD8 | Subscription-only model; 14-day trial; monthly + annual billing; tiers TRIAL 1/1, STARTER 2/3, PROFESSIONAL 5/10, ENTERPRISE ∞/∞; server authoritative; client checks UX only, never security authority. |
| P-OD9 | Offline grace TRIAL 0d / PAID 7d / PERPETUAL 14d compatibility-only; subscription-only; PERPETUAL never silently becomes a sold commercial plan. |
| P-OD10 | Server authoritative for subscription validity, license state, membership, device authorization, permission state; revocation/expiry not dependent solely on indefinitely stale local state. |
| P-OD11 | Reasonable production hardening — clock rollback/manipulation, stale entitlement cache, cache tampering, entitlement replay, server revalidation, fail-safe behavior, offline-grace abuse; no client perfect anti-tamper claim; server-authoritative bounded testable controls; no unnecessary device-sensitive data collection. |
| P-OD12 | Legacy token/signature path must not remain exposed as if active only after evidence proves no required production path depends on it. |
| P-OD13 | Employee valid email + password alone must NOT suffice for Shop business-data access from a new untrusted device; defense-in-depth (auth identity + membership + role + trusted device + license/activation + server-side tenant authorization); Owner-governed device-trust mechanism, server-enforced. |

### WS-4 (Licensing commercial model)

Part of Group B; owns subscription/tier/grace/revocation/tamper/Ed25519 and now
the P-OD13 employee device-trust requirement. Cross-platform (Windows + Android).

---

## 4. Authority Verification Results

For each authority in Section 3 the tuple was proven:

```text
COMMIT_EXISTS             = TRUE
PATH_EXISTS_AT_COMMIT     = TRUE
BLOB_MATCHES_EXPECTED     = TRUE
```

The same material is present and semantically unmodified at the current entry
tree (HEAD `1a4907bc…`, i.e., at `1a4907bc57c00126f131b458a356749abbc4421b`):

```text
At HEAD:
  PHASE_P_OWNER_DECISIONS.md                                       = 3028b058c4027557dc6d26911123a8d6a1b9def2  ✓
  POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md         = c6ae7441b2d701814895a00394257d928da5d388  ✓
  POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md = e4d4abb0de7b79893831ffc8eaae86f79c1c2407  ✓
  POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md = e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a  ✓
  docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md = 37518ed12f0402e059e099be8104b21b2d07c64f  ✓
  docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md = 57e0f9c393ea9ef3484a5312612f7703509747af  ✓
  docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md = 2925ef5cf78ed18975a7fa6be2710c6103a01649  ✓
```

```text
RESULT = AUTHORITY_CHAIN_VERIFIED   (no mismatch; no conflicting newer committed authority materially conflicts with Group B scope/order)
```

---

## 5. Group B Scope — Exact Boundary (Confirmed)

Group B consists of, as one coherent program decomposed into independently
verifiable slices:

```text
P-OD8  = Commercial / subscription / tier model
P-OD9  = Offline grace policy
P-OD10 = Server-authoritative revocation enforcement
P-OD11 = Tamper / clock / cached-entitlement integrity
P-OD12 = Legacy Ed25519 retirement
P-OD13 = Employee trusted-device / new-device business-access security
WS-4   = Licensing commercial model
```

Expected scope (driven by the exact authority, Section 3):

- subscription-only commercial model;
- Trial / Starter / Professional / Enterprise tiers;
- user/device quota enforcement (TRIAL 1/1, STARTER 2/3, PROFESSIONAL 5/10,
  ENTERPRISE ∞/∞);
- 14-day trial semantics;
- Trial offline grace = 0 days; Paid offline grace = 7 days; PERPETUAL = 14-day
  compatibility-only;
- server-authoritative entitlement;
- server-authoritative expiry/revocation;
- revocation transport/cadence design;
- cached entitlement integrity;
- bounded clock rollback/tamper handling;
- legacy Ed25519 retirement/isolation (evidence-gated);
- employee invitation hardening;
- trusted-device enrollment;
- server-enforced device gate;
- Owner device-management UI;
- device revocation semantics;
- platform secure identity/material (Windows + Android);
- Windows/Android trust behavior where Group B interfaces require it;
- offline behavior after device/license/user revocation;
- tenant isolation;
- fail-closed behavior;
- security test matrix required by P-OD13.

**Commercial provider note:** This plan does NOT add a payment gateway,
billing provider, Play Billing, Stripe, Paymob, or another external commercial
provider. The committed owner authority (P-OD8) defines a subscription/tier
commercial model but does not bind a specific billing/payment provider inside
Group B. Billing/payment-provider integration therefore remains **outside this
planning scope**. If any authoritative committed source later requires a
specific provider inside Group B, the successor planning/implementation
governance will incorporate it; none is planned here.

---

## 6. Current State Matrix (evidence-backed)

Classification read-only from the current repository. Existing Phase E/D
licensing foundation is NOT re-labelled as missing; the residual Group B gap is
identified precisely. Class codes: `ALREADY_IMPLEMENTED`, `PARTIAL`, `MISSING`,
`LEGACY`, `SERVER_AUTHORITY`, `CLIENT_ONLY`, `TEST_ONLY`, `RUNTIME_WIRED`,
`DEAD/UNUSED`.

### 6.1 Licensing foundation (existing)

| Surface | Evidence | Class | Notes |
|---|---|---|---|
| `licenses` table | `20260820000005_create_licenses.sql` | ALREADY_IMPLEMENTED (SERVER) | `plan` nullable+unused; status TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL; `max_devices` defaults 3; no tier table |
| `devices` table | `20260820000004_create_devices.sql` | ALREADY_IMPLEMENTED (SERVER) | installation_id UUID; platform windows/android; status ACTIVE/REVOKED/LOST; **no PENDING**; **no public key**; installation_id forgeable |
| `activations` table | `20260820000006_create_activations.sql` | ALREADY_IMPLEMENTED (SERVER) | license↔device bind; status ACTIVE/REVOKED/EXPIRED |
| `verify_license_entitlement` | `20260820000023_phase_e_licensing_enhancements.sql` | SERVER_AUTHORITY (partial) | resolves entitlement; **no plan/tier model; no device-trust gate** |
| `register_device` | `20260820000023…` | PARTIAL (SERVER) | **force-sets ACTIVE**; idempotent upsert; no proof-of-possession |
| `activate_device` | `20260820000023…` | PARTIAL (SERVER) | enforces `max_devices`; no device-approval concept |
| `deactivate_device` | `20260820000023…` | RUNTIME_WIRED via service; **NO UI call site** | Owner-only RPC exists; Owner device UI MISSING |
| `get_device_list` | `20260820000023…` | RUNTIME_WIRED via service; **NO UI call site** | Owner-only RPC exists; Owner device UI MISSING |
| Offline grace | `app/lib/licensing/offline_grace_policy.dart` | PARTIAL (CLIENT) | paid 7d / trial 0d / perpetual 14d already corrected (WS-4 partial); clock-rollback detect present but detach |
| Entitlement token verifier | `app/lib/licensing/entitlement_token.dart` | PARTIAL/LEGACY | `_defaultTrustedKeys = <TrustedKey>[]` (empty) at :344 — signed-token path not yet populated |
| Entitlement cache | `app/lib/licensing/entitlement_cache.dart` | PARTIAL (CLIENT) | plaintext; installation id via plain `AppSettings` (plain SQLite) |
| Device identity | `app/lib/licensing/device_identity.dart`, `app/lib/platform/device_identity_provider.dart` | PARTIAL (CLIENT) | hardware-fingerprint SHA-256 hash; **no per-install keypair / proof-of-possession**; raw ids never sent |
| Secure stores | `secure_store.dart` (Windows DPAPI), `secure_store_android.dart` (Keystore/EncryptedSharedPreferences), `platform/secure_secret_store.dart` | ALREADY_IMPLEMENTED (platform) | reusable; not yet binding a device keypair |
| RBAC / `require_shop_permission` | `20260820000024_phase_f_rbac_permission_sync.sql` (:232) | SERVER_AUTHORITY | **no device-status predicate** |
| RLS tenant isolation | `20260820000010_rls_policies.sql` (`shop_devices_isolation` :105) | ALREADY_IMPLEMENTED (SERVER) | `auth.uid()` + ACTIVE membership; **no device-trust predicate** |
| `accept_invitation` | `20260820000022_add_accept_invitation.sql` | PARTIAL/INSECURE (SERVER) | **client-supplied `p_user_id`, no identity proof/token/expiry** → membership-takeover risk (P-OD13 §H.4) |
| `invitations` | `20260820000021_add_invitations.sql` | PARTIAL | status PENDING/ACCEPTED/EXPIRED/REVOKED; `expires_at` present; **no token column** |
| invite-employee Edge Function | `supabase/functions/invite-employee/index.ts` | PARTIAL/BUGGY | temp random password never delivered (TODO); `email_confirm:true`; `null user_id` bug (documented) |
| Invitation client | `app/lib/services/invitation_service.dart` | PARTIAL (CLIENT) | accepts membership; depends on insecure `accept_invitation` |
| Auth / session resume | `app/lib/services/cloud_auth_service.dart`, `cloud_session_resume.dart`, `seller_session_provisioning.dart` | ALREADY_IMPLEMENTED (CLIENT) | no new-device approval gate in bootstrap chain |

### 6.2 Residual Group B gap summary

```text
P-OD8  Commercial/tier model ......... MISSING (no plans/tiers table; licenses.plan unused; no per-user/device quota by tier)
P-OD9  Offline grace ................. PARTIAL (paid 7d / trial 0d / perpetual 14d done; subscription-only enforcement remains)
P-OD10 Server revocation ............. PARTIAL (server RPC exists; revocation transport/cadence + device/membership revocation enforcement MISSING)
P-OD11 Tamper/clock/cache integrity .. PARTIAL (bounded controls planned; empty trusted-key path, plaintext cache; no replay binding)
P-OD12 Legacy Ed25519 retirement ..... LEGACY (evidence-gated retirement; must prove no production path depends on seam)
P-OD13 Employee device trust ......... MISSING (no device-approval/PENDING; no device keypair/proof; no server device gate; no Owner device UI; insecure accept_invitation)
WS-4   Licensing commercial model .... PARTIAL (foundation present; commercial/tier/revocation/device-trust work is Group B)
```

---

## 7. Commercial Model (P-OD8)

Precise plan preserving the committed owner decision. The **server, not the
Flutter UI, is the final security authority.**

### 7.1 Tiers (exact, from P-OD8)

| Tier | Users | Devices | Notes |
|---|---|---|---|
| TRIAL | 1 | 1 | 14-day trial; offline grace 0 days |
| STARTER | 2 | 3 | monthly + annual billing |
| PROFESSIONAL | 5 | 10 | monthly + annual billing |
| ENTERPRISE | ∞ | ∞ | monthly + annual billing |

- `TRIAL 1/1`, `STARTER 2/3`, `PROFESSIONAL 5/10`, `ENTERPRISE ∞/∞` are the
  locked quotas. Do NOT invent different tiers.

### 7.2 Source of truth & server representation

- Add a **planned** `plans`/tier lookup (additive) OR represent tier limits in
  license metadata; the exact representation is an implementation detail
  deferred to the Group B implementation planning, but the plan binds:
  - a single server-authoritative tier definition (limits, billing cadence,
    trial duration) — not duplicated in Flutter as an authority;
  - `licenses.plan` (currently nullable/unused) becomes populated by the
    server from an authoritative plan source;
  - a subscription/license relationship record with start/expiry per P-OD8
    (monthly + annual);
  - ENTERPRISE unbounded limits represented explicitly.
- Backward compatibility: Migration 30 is deployed; Group B licensing changes
  must be additive and must not break existing trial licenses (`status
  TRIAL/ACTIVE/PERPETUAL`) or existing `max_devices`.

### 7.3 Quotas & entitlement derivation

- User quota: enforce via ACTIVE `shop_members` count per shop (owner +
  employees) bounded by tier's user cap; ENTERPRISE unbounded.
- Device quota: extend the existing `max_devices`/`activate_device` enforcement
  to be tier-derived (not a fixed default of 3), server-authoritative.
- Entitlement derivation: server resolves tier → user/device limits → expiry;
  `verify_license_entitlement` extended (in a future implementation) to return
  tier, user capacity, device capacity/used, and entitlement status.

### 7.4 Migration from existing license records

- On deployment (future, governed), map existing `licenses` rows to a tier:
  TRIAL → TRIAL, ACTIVE with prior subscription → STARTER (default) unless
  another tier is provable, PERPETUAL stays compatibility-only (never a sold
  plan, P-OD9). No data loss; default mapping documented, additive.

---

## 8. Revocation + Offline Grace (P-OD9/P-OD10)

### 8.1 Fixed grace semantics

```text
TRIAL_OFFLINE_GRACE = 0 DAYS
PAID_OFFLINE_GRACE  = 7 DAYS
PERPETUAL_GRACE     = 14 DAYS (compatibility-only)
```

These are already reflected in `offline_grace_policy.dart`; Group B keeps them
final and adds server enforcement.

### 8.2 Behavior requirements (implementation-ready definition)

| Scenario | Expected behavior (fail-closed) |
|---|---|
| Trial expiry | no offline runway; must revalidate online; trial ends → not entitled |
| Paid expiry | 7-day offline grace from last server verification; server revalidation on reconnect |
| License revocation | future cloud access denied at next online session; cached REVOKED respected offline |
| Membership revocation (employee SUSPENDED/REVOKED) | all that employee's devices lose shop access; deny privileged ops regardless of prior device approval |
| Device revocation / lost | future access denied; offline window bounded by entitlement/revocation law; state converges to REVOKED |
| Lost device | treated as revoked |
| Owner-triggered device removal | frees device slot; denied access going forward |
| Offline startup | approved device may start per stored entitlement + grace; trial starts require online |
| Offline active session | bounded by grace; new-unapproved device MUST NOT self-authorize (P-OD13 CASE 17) |
| Offline queued sales | continue on approved device within grace; no upload/drain authorization for unapproved/revoked device |
| Reconnect after revocation | server denies reads/writes; client converges to REVOKED and clears privileged session |
| Clock rollback | bounded detection (already partial); server revalidation; no grace extension |
| Stale cached entitlement | server revalidation; cache integrity per Section 9 |

### 8.3 Revocation transport/cadence (P-OD10 design detail)

P-OD10 defers the exact cadence to planning. Driven by repository reality and a
fail-closed model, the design will use **polling-based server revalidation**
(scheduled/normalized last-known sync) as the baseline, since no realtime
mechanism is currently committed for this. The exact mechanism/cadence (e.g.,
server clock returned by entitlement RPC, periodic refresh on login/resume and
before privileged writes, plus revalidation on each cloud operation) is an
implementation detail selected at Group B implementation planning with
documented trade-offs. Baseline choice is **server revalidation on every
authoritative boundary** (login/session-resume, before privileged writes, and
reconnect) so revocation/expiry cannot depend on indefinitely stale local state
(P-OD10).

---

## 9. Integrity / Tamper (P-OD11)

Bounded, practical, server-authoritative controls. No impossible anti-tamper
claim.

- **Trusted server timestamps:** server returns authoritative time (already
  present in `verify_license_entitlement` as `server_time`); client stores last
  server-observed time; entitlement validity derived from server time where
  possible.
- **Local wall-clock rollback:** keep last-observed server clock and monotonic
  session timing; reuse/extend `detectClockRollback` (`offline_grace_policy.dart`);
  never extend grace on backward jump.
- **Monotonic/session timing where available:** use `DateTime`/`Stopwatch` /
  platform monotonic source for elapsed offline; treat negative elapsed as
  suspicious and fail-closed (already done).
- **Entitlement cache age:** grace window computed from last successful server
  verification (already in `isWithinGraceWindow`); bounded by tier grace.
- **Entitlement integrity/authenticity:** the signed/authenticated entitlement
  path (`entitlement_token.dart`) has an **empty trusted-key set** — Group B
  plans server-authoritative revalidation as the primary integrity control and
  (optionally) a signed entitlement/revalidation assertion; the exact HMAC/token
  technique is deferred to implementation design. Cache tampering is not
  treated as preventable client-side; the server remains the authority (P-OD11).
- **Secure persistence:** use platform secure stores (Keystore / DPAPI) for
  sensitive material; cache integrity metadata persisted accordingly.
- **Stale/offline decisions:** offline behavior bounded by grace + cached
  non-entitled state (`isCachedNonEntitled`); reconnect forces revalidation.
- **Destructive/reinstall behavior:** reinstall clears/regenerates device
  identity → governed re-approval (P-OD13 CASE 15).
- **Platform limitations:** state explicitly what is mitigated versus not fully
  preventable (e.g., a rooted/jailbroken device or a modified client is
  out-of-scope of perfect anti-tamper; server-enforcement is the security
  boundary that survives client compromise).

**Explicit threat boundary statement:** the plan claims mitigation of casual
clock rollback, stale/forged local cache, and replay of stale cached
entitlements, delivered by server revalidation. It does NOT claim to prevent
deterministic client-level tampering or hardware-rooted attacks; the
server-authoritative gate is what prevents a modified client from gaining
authorized business data (P-OD13 CASE 19).

---

## 10. Legacy Ed25519 Retirement (P-OD12)

Location of existing Ed25519-related surfaces (read-only audit):

- `app/lib/licensing/entitlement_token.dart` — signed/Ed25519-style token
  verifier (`EntitlementVerifier`, `TrustedKey`) with **empty default trusted
  keys** (`:344`), i.e., the signature-verification seam exists but is not
  wired to any verifiable authority today;
- `app/lib/services/licensing_service.dart:408-431` — `ActivationClient`
  "not yet deployed" (legacy seam);
- `app/lib/screens/settings/license_status_screen.dart:832-869` —
  `LicenseStatusScreen` surfaces the legacy path.

**Evidence-gated retirement plan (do NOT delete in this session):**

1. Enumerate every reference to the legacy Ed25519/signature/activation seam
   across production, compatibility, test, and dead paths (grep + call-graph).
2. Prove no required production flow (activation, entitlement derivation,
   offline grace, session bootstrap) depends on the legacy seam.
3. Only after proof, plan an additive migration/isolate step: gate or isolate
   the legacy seam so it is not exposed as active; do not remove it until tests
   demonstrate no dependency.
4. Add tests that fail if any required path regresses to the legacy seam.

P-OD12 is `APPROVED conditional on evidence`; retirement is NOT executed here.

---

## 11. Employee Device Trust (P-OD13)

Consumed from the immutable authority `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md`
(the authoritative source; reproduced requirements are intent-faithful).

### 11.1 Security objective (exact)

```text
VALID EMPLOYEE EMAIL + PASSWORD ALONE
MUST NOT BE SUFFICIENT TO ACCESS SHOP BUSINESS DATA
FROM A NEW UNTRUSTED DEVICE.
```

Defense-in-depth composition, in order:

```text
AUTH IDENTITY
+ ACTIVE SHOP MEMBERSHIP
+ ROLE / PERMISSIONS
+ TRUSTED DEVICE
+ LICENSE / ACTIVATION
+ SERVER-SIDE TENANT AUTHORIZATION
```

### 11.2 Security-cases → control mapping (every P-OD13 acceptance case)

Each case below is mandatory for Group B closeout. Column semantics:
THREAT / EXPECTED RESULT / SERVER CONTROL / CLIENT CONTROL / TEST TYPE /
FAIL-CLOSED EXPECTATION.

| # | Threat / case | Expected result | Server control | Client control | Test type | Fail-closed expectation |
|---|---|---|---|---|---|---|
| 1 | Valid employee + ACTIVE membership + approved device | only permitted Shop A data | tenant+role+device+license gate all pass | approved-device identity asserted | integration/RPC | authorized surface granted |
| 2 | Valid credentials + NEW unapproved device | auth may succeed; business access pending/denied | device gate denies reads/writes for non-ACTIVE device | pending/approval screen; no business data | integration/RPC | denied |
| 3 | Stolen Shop A employee creds used from another phone (competitor) | no Shop A data without Owner approval | device gate denies unless device approved | pending screen | security/integration | denied |
| 4 | Attacker changes `shop_id` | server denies cross-tenant | `require_shop_permission` + row `shop_id` scoping + device gate scoped to shop | N/A | RLS/tenancy | denied |
| 5 | Direct API with stolen auth but no device-trust proof | fails (server-authoritative, not UI) | server device gate in authz path | N/A | security/integration | denied |
| 6 | Owner approves pending device | device ACTIVE, role-limited access begins | approve RPC (Owner) sets ACTIVE | polling/refresh reflects ACTIVE | integration | granted per role |
| 7 | Owner rejects | no business access | reject RPC keeps/denies | denied/pending end-state | integration | denied |
| 8 | Owner revokes ACTIVE | future access denied per revocation SLA | revoke RPC + device gate | converges REVOKED | integration | denied |
| 9 | Owner marks LOST | future access denied | LOST treated as revoked | converges REVOKED | integration | denied |
| 10 | Membership SUSPENDED/REVOKED | all employee devices lose shop access | membership gate fails all employee devices | converges | integration | denied |
| 11 | Expired invitation/pairing token | rejected | server token expiry check | N/A | unit/integration | denied |
| 12 | Used-token replay | rejected | single-use (server-stored hash invalidated) | N/A | security/integration | denied |
| 13 | Shop-A token vs Shop B | rejected | token bound to shop_id+invitation | N/A | security/integration | denied |
| 14 | Second legitimate employee device | independent approval + device quota | separate device record + quota (P-OD8) | pending flow | integration | per-approval |
| 15 | Reinstall | governed re-approval | new device identity → PENDING | prompt approval | integration | re-approval required |
| 16 | Approved device offline | entitlement/device revocation law | last-sync boundary + grace | grace window | offline/integration | bounded by grace |
| 17 | Unknown first-time device offline | MUST NOT self-authorize | server never grants without approval | fail-closed offline | offline/security | denied |
| 18 | salesOnly cannot gain manager/owner via device approval | permission escalation denied | role/perm unchanged by device approval | N/A | RBAC/integration | denied |
| 19 | Modified client / direct RLS call, unapproved device | denied → proves NOT UI-only | device gate in RLS/RPC authz path | N/A | security/RPC | denied |
| 20 | Employee sets own password; Owner does not retain reusable password | no reusable secret | no temp-password delivery; secure acceptance | set-password flow | security/integration | no shared secret |

### 11.3 Invitation & pairing hardening (P-OD13 §J, §K)

- **Invitation model:** Owner authorizes person (bound to `shop_id` + email +
  role + invited_by + status + expiry); employee establishes own credential via
  secure acceptance; resulting `auth.user` bound **server-side** to the invited
  `shop_members` membership. Replace the current delivered-random-password model.
- **Static shared Shop Code is REJECTED** as an authorization factor (P-OD13
  §K). Optional one-time pairing/invitation token only, with: random, short
  lifetime, single-use, server-stored as hash, bound to shop+invitation/email+
  role, expiry, revocable, unusable after use (replay/expiry), never replaces
  membership/device/server authorization.
- **`accept_invitation` correction:** caller-identity bound + token proof +
  expiry. Currently client-supplied `p_user_id`, no verification → membership-
  takeover risk. This is a security correction and belongs in Group B.
- **Emails:** remove reliance on the never-sent temp password; govern actual
  invitation delivery (SMTP or Owner-delivered secure token) as implementation
  detail.

### 11.4 Device trust mechanics (P-OD13 §I, §M — server-authoritative)

- **State:** additive `PENDING_APPROVAL` on `devices` (additive migration; do
  NOT edit `20260820000004`); lifecycle `PENDING → ACTIVE (Owner approve)`,
  `ACTIVE → REVOKED`, `ACTIVE → LOST`; plus `ACTIVE → REVOKED` on membership
  SUSPENDED/REVOKED.
- **Device identity:** per-installation keypair bound to platform secure store
  (Android Keystore; Windows DPAPI/equivalent). Register the device **public
  key** server-side; server issues a challenge; client proves possession; server
  grants active-device status only to proof-passing, Owner-approved devices.
  Prefer installation-bound cryptographic identity over fragile hardware
  fingerprinting.
- **Server-enforcement (not UI-only):** introduce device-trust into the server
  authorization layer so it cannot be bypassed by a modified client — at minimum
  enforce ACTIVE-approved device in new write RPCs / `require_shop_permission`-
  gated surface and, where the threat model requires read protection, the
  relevant RLS/read path (approved-device SECURITY DEFINER predicate / RLS USING
  extension). Convey device/session proof server-side (Edge Function exchange or
  signed/session-bound assertion); never rely on a client-attested flag.
- If final implementation protects writes only, reads from an unapproved device
  remain until read path migrated — the successor must record this truthfully
  (§M consequences), and this plan requires the read path to be covered to
  satisfy CASE 2/3/5/19 fully.
- **Second device / reinstall / abuse / race:** independent approval + quota;
  reinstall → governed re-approval; design for approval race conditions
  (idempotent state transitions); audit evidence.
- **Composition:** device trust composes with license/activation (defense-in-
  depth), never substitutes. `deactivate_device`/`get_device_list` server
  surfaces exist (no UI) → Owner device-management UI is required (Section 12).

### 11.5 Owner device-management UI + employee experience

- Owner UI (pending / approved / reject / revoke / lost; employee↔device
  relationship) — `getDeviceList`/`deactivateDevice` currently have **zero UI
  call sites**.
- Employee experience: login → new-device approval gate → pending screen →
  polling/refresh → access only when ACTIVE.
- Cross-tenant isolation and audit (approval/rejection/revocation/lost/failed
  proof) recorded; no secrets/PII in logs.

---

## 12. Supabase Design (planned, additive; nothing deployed)

Required server surface (all as **future implementation artifacts**, none
created/deployed here):

- **New tables (planned):** `plans`/tier lookup (or authoritative tier metadata);
  optionally `device_approvals` / invitation-token fields (hashed); audit rows.
- **Additive columns (planned):** `licenses.plan` populated from authoritative
  tier source; `licenses` user/device capacity by tier (or derived); `devices`
  additive `PENDING` status + public-key column + `approved_by`/`revoked_by`
  timestamps; `invitations.token_hash` (+ token expiry already present).
- **New status values (planned):** device `PENDING_APPROVAL` (additive CHECK
  extension); extension of activation/license statuses only as authority permits.
- **RPCs/functions (planned):** Owner approve/reject/revoke/lost device; device
  proof validation (challenge / proof-of-possession); corrected `accept_invitation`
  (identity-bound + token + expiry); entitlement revalidation with device-trust
  gate; user/device quota by tier.
- **RLS changes (planned):** add approved-device predicate to authorization path
  (write RPCs and relevant read/RLS path) per Section 11.4, maintaining
  `shop_id` multi-tenant isolation and fail-closed semantics.
- **Invitation hardening:** per Section 11.3.
- **Indexes/constraints (planned):** indexes supporting device approval queries,
  invitation-token lookup (hashed), tier lookup; additive constraints.
- **Doctrine:** additive-only migration; shop_id multi-tenant isolation; server
  authority; RLS; idempotency; soft-delete/revocation semantics; backward
  compatibility. Migration 30 (deployed) and all prior migrations are NOT edited.

**Next migration identifier:** highest existing migration is
`20260820000030_phase_p_a4_cloud_stock_adjustments.sql`. There is no committed
governance naming a Migration 31; the next valid additive Group B migration
identifier is **`20260820000031`** (to be created only in a future governed
implementation session). No migration file is created by this session.

---

## 13. Flutter / Client Design (planned boundaries)

- **Domain models (planned):** tier, entitlement, device, device-approval,
  trusted-device gate states.
- **Repositories/services (planned):** extend `cloud_licensing_repository.dart`
  / `cloud_licensing_service.dart`; new device-approval repository; corrected
  invitation service.
- **Entitlement cache:** keep server-authoritative; add integrity/staleness
  metadata; never the security authority.
- **Secure storage:** reuse `secure_store*.dart` / `platform/secure_secret_store.dart`
  to bind the per-install device keypair.
- **Device identity:** extend `device_identity.dart` to generate/register a
  per-install keypair (public key registration) alongside the existing
  fingerprint; proof-of-possession challenge.
- **Auth/session bootstrap:** insert new-device approval gate after auth and
  membership resolution, before any business-data access
  (`seller_session_provisioning.dart` / `cloud_session_resume.dart`).
- **Trusted-device gate:** fail-closed client state; pending/approval flow;
  polling/refresh.
- **Offline state transitions:** approved/new/revoked-offline per Section 8.
- **Owner device UI:** Section 11.5.
- **Employee experience:** login → gate → pending → access.
- **Error/result mapping & sync interaction:** map server fail-closed responses;
  compose with WS-1 drain (dormant) only as required; backward compatible with
  existing Phase E/D client.

No client-only security: every sensitive authorization decision has a
corresponding server-enforced control.

---

## 14. Implementation Slices (dependency order; none pre-authorized)

Explicit dependency order (repository evidence + immutable authority decide the
exact final slices; this is the planned decomposition):

```text
S1  Server data model / migration foundation (plans/tier source; device PENDING + public key; invitation token; audit)
    → dependencies: none (additive migration `20260820000031` in a future session)
S2  Server entitlement + quota authority (tier derivation; user/device quota; expiry; plan population; migration from existing records)
    → dependencies: S1
S3  Revocation / offline-grace authority (device+membership+license revocation RPCs; revalidation gate; grace enforcement)
    → dependencies: S2
S4  Device-trust server gate + invitation hardening (approved-device predicate in authz/RLS/read path; approve/reject/revoke/lost; proof-of-possession; corrected accept_invitation; token)
    → dependencies: S1, S2
S5  Client entitlement integration (models, repositories, entitlement cache integrity, tier/grace consumption)
    → dependencies: S2, S3
S6  Platform secure device identity (per-install keypair; Android Keystore; Windows DPAPI; proof-of-possession)
    → dependencies: S4 (for server keys), S5
S7  Owner device management (UI: pending/approve/reject/revoke/lost; employee↔device)
    → dependencies: S4, S6
S8  Tamper / cache / clock enforcement (server revalidation wiring; monotonic timing; cache integrity; bounded controls)
    → dependencies: S3, S5
S9  Legacy Ed25519 retirement (evidence-gated isolation; tests)
    → dependencies: S5 (prove no production dependency); independent evidence gate
S10 Test / security convergence (P-OD13 CASE 1–20 matrix, RLS, quota, offline, revocation, tamper, cross-tenant, Android/Windows identity, reconnect)
    → dependencies: all prior
S11 Deployment / verification governance (production migration + verification; NOT authorized by this session)
    → dependencies: S10 + remote-locked implementation
S12 Group B closeout (final acceptance, remote lock, successor to Group D planning)
    → dependencies: S11
```

For every slice the successor implementation governance must specify: scope,
dependencies, files/surfaces expected to change, migration/deployment boundary,
tests, acceptance criteria, rollback considerations, and explicit non-goals.
This plan establishes the intended dependency order only; it does **not**
authorize S1 or any slice now.

---

## 15. Test / Security Evidence Matrix (implementation-ready)

Server / database (mandatory before closeout): migration replay tests for
`20260820000031` and successors; RLS/tenant-isolation tests (CASE 4, 5, 13, 19);
`require_shop_permission` device-gate tests; entitlement tests (tier
derivation, quota, expiry); user/device quota tests (P-OD8); offline-grace tests
(P-OD9); revocation tests (license/membership/device — P-OD10); tamper/clock/
cache tests (P-OD11); invitation-security tests (CASE 11, 12, 20); trusted/
untrusted-device tests (CASE 1–3, 6–10, 14–18, 20); device-revocation tests;
stolen-credentials tests; cross-shop access tests; reconnect-after-offline-
revocation tests; legacy Ed25519 retirement proof (P-OD12).

Client: unit tests for cached-entitlement integrity, offline state transitions,
error/result mapping, secure identity provisioning; Android identity-storage
tests (Keystore); Windows identity-storage tests (DPAPI).

Production/deployment evidence (post-deploy, governed): directed security
probe of a new unapproved device being denied (CASE 19), approved-device grant
(CASE 1/6), revocation convergence (CASE 8/9/10) against production — only in
the governed deployment/verification stage, not here.

Tests mandatory **before** Group B closeout: the full P-OD13 CASE 1–20 matrix,
RLS/tenant, quota, offline grace, revocation, tamper, invitation, Ed25519
retirement proof, and migration replay. Production evidence is mandatory in the
deployment stage.

---

## 16. Deployment Boundary

```text
REPOSITORY IMPLEMENTATION ...... future governed implementation session
DATABASE MIGRATION CREATION .... future governed implementation session (`20260820000031` + successors)
LOCAL TESTING .................. future governed implementation session
REMOTE IMPLEMENTATION LOCK ..... future governed remote-lock session
PRODUCTION DEPLOYMENT .......... NOT AUTHORIZED by this planning session — future governed deployment session
POST-DEPLOY VERIFICATION ....... future governed verification session
GROUP B FINAL CLOSEOUT ......... future governed closeout session
```

Production deployment is NOT authorized by this planning session. Nothing is
deployed here.

---

## 17. Cross-Group Boundary

```text
GROUP_C_IMPLEMENTATION        = OUT_OF_SCOPE
GROUP_D_PLANNING              = DEFERRED (ordered second)
GROUP_D_IMPLEMENTATION        = OUT_OF_SCOPE

ANDROID_FINAL_RELEASE_BUILD   = OUT_OF_SCOPE
AAB_BUILD                     = OUT_OF_SCOPE
AAB_UPLOAD                    = OUT_OF_SCOPE
PLAY_PUBLICATION              = OUT_OF_SCOPE

P_OD7_DRAIN_CHANGE            = OUT_OF_SCOPE
MIGRATION_30_CHANGE           = OUT_OF_SCOPE

GROUP_B_PLANNING              = THIS SESSION (authorized)
GROUP_B_IMPLEMENTATION        = NOT STARTED
```

Group B planning identifies interfaces with Windows/Android device trust
(platform secure identity, new-device flow) but MUST NOT begin Group C
package/signing work. Group D remains `ORDERED_SECOND_AND_DEFERRED`.

---

## 18. Self-Audit Confirmation

```text
NO TBD AUTHORITY REFERENCES            = TRUE (all SHAs exact, Section 3)
NO CURRENT-HEAD AUTHORITY PLACEHOLDERS  = TRUE
NO GROUP D IMPLEMENTATION               = TRUE
NO GROUP C IMPLEMENTATION               = TRUE
NO ANDROID BUILD / AAB / PLAY UPLOAD    = TRUE
NO PRODUCTION MUTATION                  = TRUE
NO SUPABASE DEPLOYMENT                  = TRUE
NO DRAIN CHANGE                         = TRUE
NO KEYSTORE CHANGE                      = TRUE
NO LEGACY ORIGIN MUTATION               = TRUE
NO SOURCE IMPLEMENTATION                = TRUE

P-OD8  .. P-OD13 represented           = TRUE (Sections 7–11)
P-OD13 security cases mapped           = TRUE (Section 11.2, CASE 1–20)
IMPLEMENTATION STARTED                 = FALSE
```

---

## 19. Non-Actions / Deferred Groups

```text
GROUP_B_IMPLEMENTATION_STARTED  = FALSE
GROUP_C_PLANNING_STARTED        = FALSE
GROUP_C_IMPLEMENTATION_STARTED  = FALSE
GROUP_D_PLANNING_STARTED        = FALSE
GROUP_D_IMPLEMENTATION_STARTED  = FALSE
SOURCE_IMPLEMENTATION_CHANGED   = FALSE
ANDROID_BUILD_EXECUTED          = FALSE
AAB_BUILT                       = FALSE
AAB_UPLOADED                    = FALSE
PLAY_CHANGED                    = FALSE
PUBLICATION_STARTED             = FALSE
SUPABASE_PRODUCTION_CHANGED     = FALSE
SUPABASE_DEPLOYMENT_EXECUTED    = FALSE
SYNC_DRAIN_CHANGED              = FALSE
SIGNING_CONFIGURATION_CHANGED   = FALSE
KEYSTORE_MUTATED                = FALSE
WINDOWS_IMPLEMENTATION_CHANGED  = FALSE
IOS_CHANGED                     = FALSE
MIGRATION_30_CHANGED            = FALSE
LEGACY_ORIGIN_MUTATED           = FALSE
FORCE_PUSH_USED                 = FALSE
FORCE_WITH_LEASE_USED           = FALSE
```

---

## 20. Successor Boundary

Successful completion of THIS session means only:

```text
GROUP_B_PLAN = CREATED + COMMITTED + REMOTE_LOCKED
```

It does NOT authorize Group B implementation in this session. On closeout:

```text
NEXT_SESSION_CLASS =
GROUP_B_IMPLEMENTATION_GOVERNANCE / IMPLEMENTATION SUCCESSOR
AS DEFINED BY THE REMOTE-LOCKED GROUP B PLAN
```

The exact next implementation boundary/slice is derived from the Group B plan
and repository governance. Group D remains `ORDERED_SECOND_AND_DEFERRED`.

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION = CASE_A_FRESH
ENTRY_HEAD           = 1a4907bc57c00126f131b458a356749abbc4421b
ENTRY_PARENT         = 8fc4be8ea06fcff5400b79dbebb373c038738ecf
DIFF PROFILE         = 1 added file (this artifact), 0 modified, 0 deleted
SACRED EVIDENCE      = preserved (untracked; never staged/modified)
COMMIT               = <set at commit>
AHEAD / BEHIND       = (1/0 after commit, pre-push)
```
