# PHASE P — GROUP B S2 SERVER ENTITLEMENT + QUOTA AUTHORITY — IMPLEMENTATION GOVERNANCE

```text
SESSION =
PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED

TARGET_SLICE       = S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY
IMPLEMENTATION     = FALSE
MIGRATION_32_CREATED = FALSE
SOURCE_CHANGED     = FALSE
DEPLOY             = FALSE
PRODUCTION_MUTATED = FALSE
GROUP_D_ADVANCED   = FALSE
```

THIS DOCUMENT GOVERNS A FUTURE S2 IMPLEMENTATION.
IT DOES NOT IMPLEMENT S2.

THIS SESSION CREATED ONLY THIS GOVERNANCE ARTIFACT. IT DID NOT IMPLEMENT S2.
IT DID NOT CREATE MIGRATION `20260820000032`. IT DID NOT EDIT SQL, Dart,
Flutter, Edge Functions, RLS, RPCs, tests, or Supabase production. It did not
edit S1 (`334d1ad443ef709a5c95a7c657024e40c40656aa`), did not edit migration
`20260820000031`, and did not edit migrations `20260820000000..00030`.

---

## A. Title / Session Identity

```text
SESSION                = PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
MODE                   = SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED
TARGET_UNIT            = Group B S2 - Server entitlement + quota authority
EXPECTED_SUCCESS_TOKEN = PASS_PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
IMPLEMENTATION         = FALSE
AUTHORIZED_OUTPUT      = ONE ADDITIVE S2 IMPLEMENTATION GOVERNANCE ARTIFACT ONLY
```

---

## B. Repository Identity

```text
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
FETCH_URL         = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_URL          = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن   (SACRED READ-ONLY; never contacted)
```

`origin` is sacred read-only legacy material. This session never fetched from,
pushed to, modified, deleted, renamed, reconfiguration, or used `origin` as
recovery. Only the authorized remote `github` was contacted (read-only
`git ls-remote`).

Identity was proven before any write:

```text
git rev-parse --show-toplevel = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
git branch --show-current     = codex/i-tech-next-roadmap-freeze
git remote -v                 = github -> https://github.com/sabere342-ai/muaman.worktrees.git (fetch+push)
                                origin -> <legacy OneDrive path> (sacred, untouched)
```

Result: **REPOSITORY_IDENTITY_VERIFIED = TRUE**.
**LEGACY_ORIGIN_MUTATED = NO.**

---

## C. Entry / Recovery Classification

```text
ENTRY_LOCAL_HEAD           = 334d1ad443ef709a5c95a7c657024e40c40656aa
ENTRY_REMOTE_TRACKING_HEAD = 334d1ad443ef709a5c95a7c657024e40c40656aa
ENTRY_DIRECT_REMOTE_HEAD   = 334d1ad443ef709a5c95a7c657024e40c40656aa   (git ls-remote github)
ENTRY_MERGE_BASE           = 334d1ad443ef709a5c95a7c657024e40c40656aa
AHEAD                      = 0
BEHIND                     = 0

TRACKED_WORKTREE = CLEAN (git diff --exit-code = no output)
INDEX            = EMPTY  (git diff --cached --exit-code = no output)
ACTIVE_GIT_OPERATION = NONE (no MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD /
                             rebase-merge / rebase-apply / BISECT_LOG)
STASH_STATUS     = unrelated WIP on codex/muaman-13-strict-july-workbook-data-migration (left untouched)
```

```text
RECOVERY_CLASSIFICATION = CASE_A_FRESH
```

Pre-existing untracked sacred evidence preserved and not staged/modified:
`supabase/.temp/`, `supabase/.branches/`, the untracked Group A Phase Q/OD7
reports, `delivery/I-TECH-Delivery-v1.0.0.zip`, and related untracked forensic
material. No `git clean`, no reset, no stash mutation.

---

## D. Authority Provenance

The committed Group B authority chain was proven directly from Git objects
(`git cat-file`, `git ls-tree`, `git merge-base --is-ancestor`, `git rev-parse
<commit>:<path>`) and confirmed present, unchanged, and ancestor of the current
authorized baseline `HEAD`:

| Token | Commit | Path | Expected Blob | Authority |
|---|---|---|---|---|
| Owner Order | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | Group B before Group D |
| Authority Binding | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | Group B canonical scope |
| Master Plan | `9ecdc38282cdb7ca6f088263f9e152f920b7a823` | `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | S1..S12 slices; P-OD8..P-OD13 |
| S1 Governance | `45018eefdace79e0370a6b93c9afa94b149aec6b` | `docs/PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE.md` | `0612e37374b4756e28d9547ee03dd6e312aeb2db` | declares S2 the next deferred successor slice |
| Billing Correction | `c6ddbb45d5d1f9a5bc0c6095561896767fea4054` | `docs/PHASE_P_GROUP_B_S1_BILLING_CADENCE_SCHEMA_CONTRADICTION_GOVERNANCE_CORRECTION.md` | `34899f7755e5dcecd20076103214e6ede7049a22` | `billing_cadence` NULLABLE contract |
| S1 Implementation | `334d1ad443ef709a5c95a7c657024e40c40656aa` | (see Section E) | (see Section E) | completed S1 predecessor |

The historical typo prefix `c6bbdd45...` is INVALID authority and was not
substituted, normalized, or silently repaired anywhere. The valid S1 parent is
`c6ddbb45d5d1f9a5bc0c6095561896767fea4054`.

```text
RESULT = AUTHORITY_CHAIN_VERIFIED   (no mismatch; no conflicting newer committed authority)
```

All mandatory authority blob tuples also equal the same blobs at current `HEAD`
(material authority drift = NONE).

---

## E. Exact Predecessor — S1 Immutability Proof

```text
S1_COMMIT                  = 334d1ad443ef709a5c95a7c657024e40c40656aa   (feat: implement Group B S1 server data model foundation)
S1_PARENT                  = c6ddbb45d5d1f9a5bc0c6095561896767fea4054
S1_REMOTE_LOCK             = TRUE (local = tracking = direct remote = 334d1ad; AHEAD=0, BEHIND=0)
S1_MIGRATION_BLOB          = 2ab6436673ecf1ac6e9c39e7fb11403f245dfc2b   (supabase/migrations/20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql)
S1_TEST_BLOB               = 43f5f68cf5ffcdadb6468af066958bb310923544   (supabase/tests/s1_server_data_model_foundation.test.sql)
S1_IMMUTABILITY_VERIFIED   = TRUE
BILLING_CORRECTION_HONORED = TRUE
```

S1 is the completed predecessor. This governance declares the completed S1
migration **immutable**:

- migration `20260820000031` MUST NOT be edited;
- migrations `20260820000000..00030` MUST NOT be edited;
- S1 tests (`s1_server_data_model_foundation.test.sql`) MUST NOT be
  retroactively altered to manufacture S2 behavior;
- S1 historical authority MUST NOT be rewritten;
- any future S2 schema change MUST be additive and forward-only.

---

## F. Billing-Cadence Correction (Precedence)

The billing-cadence correction has higher precedence ONLY for the contradiction
it explicitly resolves. The authoritative S1 billing contract, confirmed present
in migration `20260820000031`:

```text
billing_cadence TEXT DEFAULT 'monthly'      -- NULLABLE
CHECK (billing_cadence IS NULL OR billing_cadence IN ('monthly','annual'))
```

Trial seed: `billing_cadence = NULL`.

S2 governance does NOT restore the superseded `NOT NULL` requirement, does NOT
broaden this correction into unrelated policy, and treats Trial as the NULL-
cadence (non-subscription / compatibility) case.

---

## G. Exact Authorized S2 Purpose

Committed authority (master plan §14; S1 governance §29) identifies S2 as:

```text
S2 — Server entitlement + quota authority
```

Purpose:

```text
Server entitlement + quota authority for the P-OD8 commercial/tier model.
```

Deliverables:

```text
- tier derivation
- user quota enforcement by tier
- device quota enforcement by tier
- plan population
- licenses.plan_key ← plans
- migration/backfill from existing records
```

Dependency:

```text
S1
```

Dependency status:

```text
MET / REMOTE-LOCKED
```

Tier contract (exact, from P-OD8 / master plan §7; committed and immutable):

```text
TRIAL        users = 1   devices = 1
STARTER      users = 2   devices = 3
PROFESSIONAL users = 5   devices = 10
ENTERPRISE   users = unlimited   devices = unlimited
```

Plan keys use the exact committed spelling introduced by S1 (`plans.key`):
`trial`, `starter`, `professional`, `enterprise` (`plans.name` = `Trial`,
`Starter`, `Professional`, `Enterprise`). No alternate plan keys are invented.

```text
NEXT_AUTHORIZED_UNIT   = S2 SERVER ENTITLEMENT + QUOTA AUTHORITY
IMPLEMENTATION_AUTHORIZED_THIS_SESSION = NO
```

S2 being the next slice in the ordered sequence authorizes it as the NEXT
GOVERNANCE UNIT. It does NOT pre-authorize implementation. This session stops
after governance remote-lock.

---

## H. Current-State Source Findings (read-only discovery)

The following are **CURRENT SOURCE FACT** (committed; read-only during this
session) forming the exact S2 implementation boundary.

### H.1 `plans` (from S1 migration `20260820000031`)

`CREATE TABLE plans` with columns: `key TEXT PRIMARY KEY`, `name TEXT NOT NULL`,
`user_limit INTEGER` (NULL = unlimited), `device_limit INTEGER` (NULL =
unlimited), `trial_days INTEGER`, `billing_cadence TEXT DEFAULT 'monthly'`, +
constraint (`NULL | 'monthly' | 'annual'`), `created_at`, unique index
`idx_plans_key`. Deterministic seeds already present:

```text
trial        Trial        1   1   14  NULL
starter      Starter      2   3   NULL 'monthly'
professional Professional 5   10  NULL 'monthly'
enterprise   Enterprise   NULL NULL NULL 'monthly'
```

`plans` is a read-only reference table (RLS SELECT-only via
`plans_select` for any ACTIVE `shop_members`; no client DML). This is the target
"plan population" surface.

### H.2 `licenses` (from `20260820000005`, additive `00023`, additive S1 `00031`)

Columns: `id`, `shop_id`, `license_key`, `plan` (free TEXT, unused, nullable),
`status` (TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL), `trial_*`, `activated_at`,
`subscription_expires_at`, `created_at`; additive `updated_at`, `max_devices`
(INTEGER NOT NULL DEFAULT 3, fixed default), `revoked_at`, `metadata`; additive
S1 `plan_key TEXT REFERENCES plans(key)` (nullable FK, backfill is S2) +
`user_limit INTEGER` (nullable, NULL until derived) + `idx_licenses_plan_key`.

### H.3 Device / activation model

- `devices` (`00004`, additive S1 `00031`): `installation_id`, `shop_id`,
  `user_id`, `platform` (windows|android), `device_name`, `first_seen_at`,
  `last_seen_at`, `status` (CHECK ACTIVE/REVOKED/LOST/PENDING_APPROVAL),
  `public_key`, `approved_by`, `approved_at`, `revoked_by`, `revoked_at`
  (approval/trust fields are foundation only; enforcement is S4/S6/S7).
- `activations` (`00006`, additive `00023`): `license_id → licenses`,
  `device_id → devices`, `activated_at`, `last_verified_at`, `status`
  (ACTIVE/REVOKED/EXPIRED). A device is "currently activated" when it has an
  ACTIVE activation row against the shop's license.
- `register_device` / `activate_device` / `deactivate_device` /
  `get_device_list` (`00023`), `verify_license_entitlement` (`00023`) as
  described in master plan §6.1. `activate_device` currently enforces a fixed
  `licenses.max_devices` default of 3 (NOT tier-derived). `verify_license_entitlement`
  reports `max_devices` (fixed default), `current_devices`, `device_slot_available`.

### H.4 User / membership model

`shop_members` (`00001`): `shop_id`, `user_id`, `role` (owner/employee/salesOnly),
`status` (INVITED/ACTIVE/SUSPENDED/REVOKED), timestamps, unique `(shop_id,user_id)`.
RLS `shop_member_isolation` restricts reads to ACTIVE-membership users. This is
the per-shop user roster; an ACTIVE membership is the domain notion of a
provisioned user for the shop.

### H.5 RBAC / RLS / enforcement seams

- `require_shop_permission` (`00024`) — auth + membership + entitlement +
  permission (no device-status predicate).
- RLS (`00010`) — `shop_devices_isolation`, `shop_licenses_isolation`,
  `shop_activations_isolation`, `shop_member_isolation` etc.; tenant isolation via
  `auth.uid()` + ACTIVE membership; no device-trust predicate (S4).
- Server-authoritative RPCs are `SECURITY DEFINER` (e.g.,
  `verify_license_entitlement`, `activate_device`) — the natural server-side
  enforcement seam for S2 quota authority.

### H.6 Flutter-side entitlement assumptions (CLIENT, not authority)

`app/lib/licensing/entitlement_token.dart` defines `Entitlements{tier, deviceLimit, features}`
in a legacy signed-token verifier whose default trusted-key set is empty
(master plan §6.1 / §9). `app/lib/licensing/offline_grace_policy.dart`
(paid 7d / trial 0d / perpetual 14d). These are CLIENT surfaces and are NEVER
the security/entitlement authority (P-OD8/P-OD10/P-OD11). S2 does not rely on
them; S2 establishes server-authoritative entitlement.

### H.7 Migrations naming/numbering

Migrations are sequential `2026082000NNNN_<snake_desc>.sql`. Committed highest =
`20260820000031` (S1). The next valid additive Group B identifier for S2 is:

```text
supabase/migrations/20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql
```

No migration file is created by this session. If the actual future history at
the S2 implementation session already contains an authorized migration beyond
`00031`, the successor implementation governance must adapt to real history and
MUST NOT overwrite an existing authorized migration; this document assumes the
committed state at `HEAD` where `00032` is next.

### H.8 Tenant-isolation & enforcement seams summary

```text
CURRENT SOURCE FACT
  plans                    = authoritative tier reference (read-only, membership-scoped SELECT)
  licenses.plan_key        = nullable FK foundation (NULL until S2 backfill)
  licenses.user_limit      = nullable (NULL until S2 derives)
  licenses.max_devices     = fixed default 3 (NOT tier-derived; to be reconciled by S2)
  licenses.plan            = legacy free text (unused; preserved, NOT authoritative)
  shop_members status/value ACTIVE = provisioned-user notion
  devices + activations    = device settlement (ACTIVE activation holds a slot)
  verify_license_entitlement = SECURITY DEFINER entitlement resolver (tier seam)
  activate_device          = SECURITY DEFINER device-slot enforcement surface
```

---

## I. Scope — Explicit In-Scope / Out-of-Scope

### I.1 Explicit in-scope (this governance covers the future S2 implementation)

```text
- canonical plan/tier derivation (server-authoritative)
- user quota authority by tier (server-enforced)
- device quota authority by tier (server-enforced), reconciling fixed max_devices
- plans population / plan seeds correctness (already present from S1; S2 confirms/uses)
- licenses.plan_key ← plans binding/backfill from existing records
- deterministic existing-record tier backfill
- server-side deterministic rejection (error contract) on quota exhaustion
- additive forward-only schema/migration/backfill governance
- security invariants (server authority, tenant isolation, no RLS weakening)
- future test/evidence requirements (including P-OD13 CASE matrix ownership)
```

### I.2 Explicit out-of-scope (S2 MUST NOT absorb)

```text
- payment provider / Stripe / Paymob / Google Play Billing / Apple billing
- payment webhooks, charging customers, subscription revenue recognition,
  invoice settlement, provider reconciliation
- device-trust / proof-of-possession ENFORCEMENT    (S4/S6/S7)
- run-time enforcement of approved-device gate       (S4)
- revocation/offline-grace enforcement               (S3)
- invitation hardening / accept_invitation correction (S4)
- Owner device-management UI                          (S7)
- tamper / clock / cache enforcement                 (S8)
- legacy Ed25519 retirement                           (S9)
- production deployment                              (S11)
- Group B closeout / any Group D work
```

---

## J. Required S2 Governance Questions — Decisions

### J.1 Plan derivation (canonical source of truth)

```text
COMMITTED REQUIREMENT: a single server-authoritative tier definition; no client-only authority.
CURRENT SOURCE FACT:  plans table (key/name/user_limit/device_limit/billing_cadence); licenses.plan_key FK.
GOVERNED DECISION:    plans is THE canonical source of truth for tier limits.
                      licenses.plan_key is the authoritative per-license tier binding and
                      MUST reference a valid plans.key. Tier limits (user/device) are DERIVED
                      from the referenced plans row, NOT from licenses.plan (legacy free text),
                      NOT from licenses.max_devices alone, NOT from any client field.
GOVERNED DECISION:    Trial → plans.key 'trial' (user_limit 1, device_limit 1, billing_cadence NULL).
                      Paid tiers → 'starter'|'professional'|'enterprise' (billing_cadence 'monthly').
                      Missing plan_key (legacy, before backfill) → backfill per J.4.
                      Invalid plan_key (references no plans row, or a value outside the four
                      committed keys) → MUST NOT grant entitlement; treat as entitlement-gated /
                      deterministic error, fail closed, and surface a deterministic server error.
                      No client-only authority: the client MAY render, never decide authority.
```

### J.2 Plan population

```text
COMMITTED REQUIREMENT: P-OD8 tiers exist as the commercial tier set.
CURRENT SOURCE FACT:  plans is already seeded deterministically by S1 migration 00031.
GOVERNED DECISION:    S2 confirms and must not weaken the S1 seed. The canonical intended records are:
                          ('trial','Trial',1,1,14,NULL)
                          ('starter','Starter',2,3,NULL,'monthly')
                          ('professional','Professional',5,10,NULL,'monthly')
                          ('enterprise','Enterprise',NULL,NULL,NULL,'monthly')
                      Population is idempotent/replay-safe (ON CONFLICT DO NOTHING, matching S1).
                      Commercial entitlement tier metadata (limits, cadence, trial_days) is allowed.
                      Payment-provider / revenue / pricing fields are NOT introduced.
```

### J.3 Enterprise unlimited semantics

```text
COMMITTED REQUIREMENT: ENTERPRISE = unlimited users/devices.
CURRENT SOURCE FACT:  plans.enterprise.user_limit IS NULL and device_limit IS NULL.
GOVERNED DECISION:    NULL IS the durable representation of unlimited (consistent with S1 +
                      billing correction and S1 pgTAP T4d/T10: NULL/NULL). NO magic integer
                      (e.g., 999999/2147483647) is used to mean unlimited. Server code MUST
                      interpret NULL limit as "no numerical cap" (unlimited). This is a
                      COMMITTED representation; no governance blocker.
```

### J.4 Existing-record backfill

```text
COMMITTED REQUIREMENT: licenses.plan_key ← plans; migration/backfill from existing records.
CURRENT SOURCE FACT:  licenses.plan_key is NULL for existing rows (S1 left it null); licenses.plan
                      (free text) is unused; licenses.status has TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL.
GOVERNED DECISION:    deterministic, idempotent, additive backfill. Eligible records and default mapping:
                          license.status = 'TRIAL'          principal-state → plan_key 'trial'
                          license.status = 'ACTIVE'         default → plan_key 'starter' (master plan §7.4 default
                                                             unless another tier is provable from existing evidence)
                          license.status = 'PERPETUAL'      compatibility-only, NEVER auto-sold as a paid tier;
                                                             no plan_key grant that implies an active commercial paid
                                                             entitlement unless separately authorized; preserve as-is /
                                                             map to a governed non-sold treatment and document it.
                          EXPIRED / SUSPENDED               ↓ non-entitled: plan_key MAY still be set for display,
                                                             but quota authority applies only to entitled states;
                                                             do NOT silently grant unlimited/paid access.
GOVERNED DECISION:    Never guess customer billing status. If an existing record cannot be mapped
                      deterministically (e.g., no TRIAL/ACTIVE/PERPETUAL state, or ambiguous
                      status/text), LEAVE plan_key NULL for that row and record it as a
                      governed NULL/unknown plan case (deterministic behavior: not entitled /
                      entitlement-gated, fail closed), rather than inventing a tier.
GOVERNED DECISION:    Duplicate/ambiguous handling: per-shop license is a single record; if a shop
                      has multiple license rows, deterministic ordering (favor most recent by
                      created_at among entitled states, consistent with verify_license_entitlement's
                      ORDER BY created_at DESC semantics) and only ONE binding applied; no
                      double-count. Idempotency: re-run must produce identical state (no drift).
                      Rerun safety: pure additive mapping; never destructive; no history rewrite.
```

### J.5 User quota authority

```text
CURRENT SOURCE FACT:  per-shop users = shop_members rows for shops.id where the membership is the
                      provisioned notion. ACTIVE membership = provisioned user. role ∈ {owner,employee,salesOnly}.
GOVERNED DECISION:    user_count for a shop = number of DISTINCT user_id in shop_members for that
                      shop with status = 'ACTIVE'. Owner IS included (owner is the first ACTIVE member
                      created by create_shop_with_owner). employee and salesOnly ACTIVE members count.
                      INVITED (not-yet-accepted) DO NOT count. SUSPENDED / REVOKED DO NOT count.
                      Deleted members (no row) do not count. Duplicate identities collapse to one
                      distinct user_id (UNIQUE(shop_id,user_id) enforces one membership per shop-user).
                      Cross-shop identities: a user who is ACTIVE in two shops counts once in EACH
                      shop's quota independently (tenant isolation per shop).
GOVERNED DECISION:    quota enforcement is SERVER-AUTHORITATIVE via MEMBERSHIP CREATE/UPDATE surface
                      (DML restricted to service_role; enforced in the server path that provisions
                      a membership), never in Flutter. Inviting a new member off of an over-quota plan
                      MUST be rejected deterministically per J.8. Existing over-quota states (e.g., a
                      shop downgraded from a larger tier while having more ACTIVE members than the new
                      cap) MUST be graced/flagged, MUST NOT silently reduce members, and MUST be
                      reported as a governed entitlement-overshoot state (fail closed on NEW adds).
```

### J.6 Device quota authority

```text
CURRENT SOURCE FACT:  device slot = an ACTIVE activation row (activations.status='ACTIVE') linking the
                      device to the shop's license, with the linked device.status='ACTIVE' (matching
                      verify_license_entitlement / activate_device counting). devices table holds
                      per-installation records with installation_id + shop_id.
GOVERNED DECISION:    device_count for a shop = number of distinct devices with an ACTIVE activation
                      against the shop's entitled license AND device.status = 'ACTIVE'. REVOKED /
                      LOST devices do not count. Deleted devices (no row) do not count. PENDING_APPROVAL
                      devices do NOT hold a quota slot until ACTIVE (device trust enforcement is
                      S4/S6/S7 — S2 does NOT implement proof-of-possession). Replacement devices: each
                      device is a distinct record; a NEW device counts as a new slot until the old
                      device is REVOKED/deactivated (activate_device frees a slot on deactivate). Duplicate
                      registration resolves to the single (installation_id, shop_id) record
                      (idx_devices_installation_shop).
GOVERNED DECISION:    device quota is SERVER-AUTHORITATIVE and tier-derived. S2 reconciles the fixed
                      licenses.max_devices default of 3 so the effective device cap comes from the
                      referenced plans.device_limit for the shop's tier (TRIAL 1, STARTER 3,
                      PROFESSIONAL 10, ENTERPRISE unlimited/NULL), enforced in the server device-
                      settlement surface (activate_device / entitlement path), never in the UI.
GOVERNED DECISION:    ownership is per-shop/per-license; S2 enforces only the P-OD8 numeric
                      entitlement boundary. It does NOT prematurely implement S3/S4/S6/S7 device-trust
                      enforcement. Do not claim device-trust compliance from S2.
```

### J.7 Enforcement timing and atomicity

```text
GOVERNED DECISION:    quota enforcement MUST be server/database-authoritative and atomic so concurrent
                      requests cannot bypass limits. Concretely: run counts and cap checks inside the
                      same SECURITY DEFINER transaction that inserts a membership/activation, using
                      advisory locks or equivalent mutual exclusion keyed to the shop_id (or a unique
                      DB constraint) PLUS an absolute-cap check BEFORE insert; reject N+1 deterministically.
                      Do not rely on read-then-write without concurrency control. Do not weaken RLS.
                      Do not rely exclusively on Flutter UI validation (client-only checks are UX-only).
```

### J.8 Error contract

```text
GOVERNED DECISION:    deterministic server-side rejection on quota exhaustion reusing existing error
                      patterns (SECURITY DEFINER RAISE EXCEPTION with an explicit message, consistent
                      with start_trial / activate_device / require_shop_permission). Expected shape:
                      a stable, machine-checkable error code + message for "user quota reached (n/cap)"
                      and "device quota reached (n/cap)", and for invalid/missing plan (fail closed).
                      No broad API redesign. Document the exact reserved error identifiers in the future
                      implementation, aligned with existing error conventions.
```

### J.9 Security invariants (mandatory)

```text
- server authoritative
- tenant isolation preserved (shop_id scoped; no cross-shop entitlement leakage)
- no RLS weakening
- no trust in client-supplied tier/quota
- no cross-shop entitlement leakage
- no bypass by offline/local-only mutation
- additive forward-fix only
```

Every future quota decision must be enforced server-side and cross-checked
against `shop_members` ACTIVE membership + entitled license + plan; the client may
render but never authorize.

---

## K. RLS / Auth / Device-Trust Boundaries

```text
COMMITTED DECOMPOSITION: RLS device-trust predicate and approved-device enforcement → S4.
                         Device proof-of-possession / platform identity → S6. Owner device UI → S7.
GOVERNED DECISION: S2 does NOT add the approved-device RLS predicate, does NOT change register/activate/
                   deactivate/get_device_list's device-trust semantics, and does NOT implement
                   proof-of-possession. S1's device-trust schema preparation does NOT authorize full
                   device enforcement in S2. S2 enforces only the P-OD8 numeric user/device entitlement
                   boundary server-side. If authority assigns RLS/device/auth enforcement to S4/S6/S7,
                   S2 explicitly defers it. S2 must NOT become a disguised implementation of S3, S4,
                   S6, S7, later Group B slices, or Group D.
```

---

## L. Billing / Revenue Boundary

```text
LOBOUNDARY:  P-OD8 tier ENTITLEMENTS (limits, cadence metadata, trial_days) are in scope.
             A real payment provider is NOT bound by this authority.
OUT OF SCOPE (unless explicit newer authority): Stripe, Paymob, Google Play Billing, Apple billing,
             payment webhooks, charging customers, invoice settlement, subscription revenue
             recognition, provider reconciliation.
GOVERNED DECISION: S2 governs entitlement authority only. It does not equate entitlement with
             payment-provider implementation and introduces no provider/pricing/revenue table.
```

---

## M. Migration Governance

```text
NEXT_VALID_MIGRATION (at HEAD) = 20260820000032
FUTURE_MIGRATION_FILE =
  supabase/migrations/20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql

MIGRATION_FILE_CREATED = FALSE   (this governance session creates no migration file)
```

Rules for the future S2 migration:

```text
- additive only
- forward only
- idempotent
- deterministic
- existing migrations immutable (do not edit 00031; do not edit 00000..00030)
- no destructive history rewrite; no rollback migration required for additive schema
```

If real history at the future implementation session already contains an
authorized migration beyond `00031`, adapt to actual history rather than
overwriting an existing authorized migration and re-derive the next identifier.

---

## N. Test Governance (future S2 proof requirements)

Use existing pgTAP conventions (`supabase/tests/*.test.sql` via `supabase test
db`) and `flutter test` regression where relevant. Future S2 tests MUST cover,
where applicable:

```text
- tier seed/population correctness (plans unchanged; exact four rows)
- Trial    1 user / 1 device
- Starter  2 users / 3 devices
- Professional 5 users / 10 devices
- Enterprise unlimited semantics (NULL limit interpreted as unlimited; no magic integer)
- quota edge boundaries (at cap allowed; N+1 rejected)
- rejection at N+1 (deterministic error)
- deterministic plan derivation (plan_key → plans limits; Trial vs paid; invalid plan fails closed)
- legacy-record backfill (TRIAL→trial, ACTIVE→starter default, PERPETUAL compat, EXPIRED/SUSPENDED
  non-entitled, NULL/unknown → not-entitled fail closed)
- NULL/unknown plan behavior
- idempotent rerun (re-apply backfill yields identical state)
- concurrent quota attempts (no bypass; atomic enforcement)
- tenant isolation (no cross-shop quota/entitlement leakage)
- no RLS regression (existing RLS tests still pass; no policy weakened)
- no S1 regression (s1_server_data_model_foundation.test.sql still passes)
- migration replay (clean 00000..00032 on fresh local stack)
- Flutter regression suite (flutter test still passes; no client authority introduced)
```

S2 MUST NOT manufacture tests unrelated to S2.

---

## O. P-OD13 CASE 1–20 Matrix (S2 ownership)

Each case classified against S2 scope. Classes:
`COVERED_BY_S2`, `PARTIALLY_RELEVANT_TO_S2`, `DEFERRED_TO_ANOTHER_SLICE`,
`NOT_APPLICABLE_TO_S2`, `BLOCKED_BY_MISSING_AUTHORITY`.

| # | Case | S2 classification |
|---|---|---|
| 1 | Employee + ACTIVE membership + approved device gets only Shop A data | PARTIALLY_RELEVANT_TO_S2 (quota/entitlement boundary; full grant needs S4 device gate) |
| 2 | New unapproved device denied | DEFERRED_TO_ANOTHER_SLICE (S4 device gate) |
| 3 | Stolen creds from another device | DEFERRED_TO_ANOTHER_SLICE (S4/S6/S7 device trust) |
| 4 | shop_id change / cross-tenant | PARTIALLY_RELEVANT_TO_S2 (S2 tenant-isolated quota counts; full device/seam is S4) |
| 5 | Direct API without device-trust proof | DEFERRED_TO_ANOTHER_SLICE (S4 server gate) |
| 6 | Owner approves pending device | DEFERRED_TO_ANOTHER_SLICE (S4/S7 approve; device quota status may be read by S2) |
| 7 | Owner rejects | DEFERRED_TO_ANOTHER_SLICE (S4/S7) |
| 8 | Owner revokes ACTIVE | DEFERRED_TO_ANOTHER_SLICE (S4/S7; S2 device-count semantics respect REVOKED) |
| 9 | Owner marks LOST | DEFERRED_TO_ANOTHER_SLICE (S4/S7; S2 counts LOST as non-slot) |
| 10 | Membership suspended/revoked | PARTIALLY_RELEVANT_TO_S2 (S2 user_count excludes SUSPENDED/REVOKED; full device loss is S4) |
| 11 | Expired invitation/pairing token | DEFERRED_TO_ANOTHER_SLICE (S4 invitation) |
| 12 | Used-token replay | DEFERRED_TO_ANOTHER_SLICE (S4) |
| 13 | Shop-A token vs Shop B | DEFERRED_TO_ANOTHER_SLICE (S4) |
| 14 | Second legitimate device | PARTIALLY_RELEVANT_TO_S2 (S2 device quota boundary per tier); approval mechanics S4 |
| 15 | Reinstall → re-approval | DEFERRED_TO_ANOTHER_SLICE (S4/S6) |
| 16 | Approved device offline | NOT_APPLICABLE_TO_S2 (S3/S8 grace) |
| 17 | Unknown first-time device offline must not self-authorize | DEFERRED_TO_ANOTHER_SLICE (S4 server never grants) |
| 18 | salesOnly cannot gain higher role via approval | NOT_APPLICABLE_TO_S2 (RBAC; S4 unchanged by approval) |
| 19 | Modified client / direct RLS call, unapproved device | DEFERRED_TO_ANOTHER_SLICE (S4 server gate) |
| 20 | No reusable password retained | NOT_APPLICABLE_TO_S2 (S4 invitation) |

S2 does NOT claim CASE 1–20 compliance; it owns only the numeric entitlement /
quota portion relevant to cases 1, 4, 10, 14, and preserves tenant isolation.
This matrix explicitly prevents scope inflation from the P-OD13 case set.

---

## P. Implementation Boundary — Allowed / Forbidden / Immutable / Sacred Paths

Derived from read-only repository inspection.

```text
ALLOWED FUTURE IMPLEMENTATION PATHS
  supabase/migrations/20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql
    (exactly one additive migration when implementation is separately authorized)

ALLOWED FUTURE TEST PATHS
  supabase/tests/s2_server_entitlement_quota_authority.test.sql   (pgTAP)
  (no changes to existing tests except ADDITIVE new S2 test files)

CONDITIONALLY ALLOWED PATHS (only when implementing the exact governed S2 server surfaces)
  supabase/migrations/             (new additive files ONLY; never edit 00000..00031)
  supabase/tests/                  (new additive S2 test file only)
  (server RPC definition changes, if any, must be bounded to entitlement/quota surfaces
   and introduced only inside the allowed migration / additive functions; no client production code)

FORBIDDEN PATHS (in this governance session and in the future S2 implementation unless
                 a separate authority explicitly expands scope)
  app/lib/**                       (Flutter production source — S2 server-only)
  supabase/functions/**            (Edge Functions — none changed by S2)
  supabase/config.toml             (no infra/config change)
  supabase/seed.sql                (no seed change by S2; plans already seeded by 00031)
  .env* / secrets / keystores      (no secret mutation)

IMMUTABLE HISTORICAL PATHS
  supabase/migrations/20260820000000.sql ... 20260820000030.sql
  supabase/migrations/20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql
  supabase/tests/s1_server_data_model_foundation.test.sql
  supabase/tests/cloud_stock_adjustments.test.sql
  supabase/tests/rls_shop_members_recursion.test.sql
  app/lib/licensing/offline_grace_policy.dart
  app/lib/licensing/entitlement_token.dart

SACRED PATHS (must remain untouched by this governance session and by S2 impl unless separately authorized)
  Group_A reports (untracked evidence)
  delivery/I-TECH-Delivery-v1.0.0.zip
  supabase/.temp/*
  supabase/.branches/*
  unrelated untracked forensic evidence
  stash@{0} and other unrelated stashes
  legacy origin repository (C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن)
  unrelated user work
```

Broad permissions such as `lib/**`, `supabase/**`, `test/**` are NOT granted.
The allowlist is the narrowest set above and is individually justified.

---

## Q. Production Prohibition

```text
PROJECT = ckruxrgppxxeqspxmyyd

THIS SESSION MUST NOT and DID NOT perform:
  supabase db push / remote migrations / production SQL / production data mutation
  Edge Function deployment / secrets mutation / auth mutation / RLS mutation
  project reset / production verification requiring mutation
```

Read-only local/repository inspection only. No production deployment is
authorized before the separately governed S11 production-deployment slice.

---

## R. Group D Prohibition

```text
GROUP_D = ORDERED_SECOND_AND_DEFERRED
This session did not plan, implement, edit, advance, or inspect Group D for
opportunistic cleanup, and did not combine Group D with S2. Stay on S2 governance only.
```

---

## S. Successor / Deferred Slice Boundary

```text
S2 (this governance)  → implementations: S3 (revocation/offline-grace), S4 (device-trust gate +
                        invitation), S5 (client entitlement), S6 (platform identity), S7 (owner UI),
                        S8 (tamper/cache/clock), S9 (Ed25519), S10 (test convergence), S11 (deployment),
                        S12 (closeout). Group D is separate and deferred.
```

None of these are performed in this session. S2 documents its interfaces and
dependencies with them.

---

## T. Implementation Entry Gates (future S2 implementation session)

The future S2 implementation session may run ONLY when ALL of the following hold:

```text
- this S2 governance artifact is committed and remote-locked (authority present)
- S1 is unchanged and remote-locked
- repository is clean in the governed sense and no active Git operation
- the next authorized migration (00032 at HEAD, or adapted to real history) is confirmed
- the implementer stays within the ALLOWED paths and server-only boundary
- separate owner authorization for the S2 IMPLEMENTATION session exists
  (governance alone does not authorize implementation)
```

---

## U. Implementation Stop Conditions (future S2 implementation session)

The future S2 implementation MUST STOP and fail closed if any of:

```text
- any edit to 00000..00031 or to S1 tests is required
- any client (Flutter) or Edge Function change is required
- any RLS weakening or device-trust predicate is required (that is S4/S6/S7)
- any payment-provider / revenue semantics are required
- any arbitrary "large number = infinity" representation would be introduced
- any non-additive / non-idempotent / destructive migration is required
- any production mutation or deployment is required
- any Group D work becomes required
- any scope not described in this governance artifact becomes required
```

---

## V. Non-Actions Ledger (this governance session)

```text
S2 IMPLEMENTATION_STARTED   = FALSE
SQL_MIGRATION_CREATED       = FALSE   (no 00032)
PRODUCTION_SOURCE_CHANGED   = FALSE
EDGE_FUNCTION_CHANGED       = FALSE
RLS_CHANGED                 = FALSE
AUTH_CHANGED                = FALSE
DEVICE_LOGIC_CHANGED        = FALSE
LICENSE_IMPL_CHANGED        = FALSE
TESTS_CHANGED_AS_IMPL       = FALSE
CONFIGURATION_CHANGED       = FALSE
PRODUCTION_DEPLOYED         = FALSE
S1_MIGRATION_EDITED         = FALSE
S1_TEST_EDITED              = FALSE
MIGRATION_00000..00030_EDITED = FALSE
GROUP_B_OTHER_SLICES_STARTED = FALSE
GROUP_C_STARTED             = FALSE
GROUP_D_ADVANCED            = FALSE
SYNC_DRAIN_CHANGED          = FALSE
ANDROID_BUILD / AAB / PLAY  = FALSE
LEGACY_ORIGIN_MUTATED       = FALSE
SACRED_EVIDENCE_MUTATED     = FALSE
UNRELATED_STASH_MUTATED     = FALSE
FORCE_PUSH_USED             = FALSE
FORCE_WITH_LEASE_USED       = FALSE
REBASE_USED                 = FALSE
AMEND_USED                  = FALSE
HARD_RESET_USED             = FALSE
GIT_CLEAN_USED              = FALSE
```

---

## W. Successor Boundary

Successful completion of THIS session means only:

```text
S2_IMPLEMENTATION_GOVERNANCE = CREATED + COMMITTED + NORMAL_FAST_FORWARD_PUSHED + REMOTE-LOCKED
S2_IMPLEMENTATION            = NOT_STARTED
PRODUCTION                   = UNCHANGED
GROUP_D                      = DEFERRED
```

The terminal state is:

```text
S2 GOVERNANCE          = CREATED / COMMITTED / NORMAL FAST-FORWARD PUSHED / REMOTE-LOCKED
S2 IMPLEMENTATION      = NOT STARTED
PRODUCTION             = UNCHANGED
GROUP D                = DEFERRED
```