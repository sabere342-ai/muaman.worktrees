# PHASE P — GROUP B S1 SERVER DATA MODEL / MIGRATION FOUNDATION — IMPLEMENTATION GOVERNANCE

```text
SESSION =
PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY
EXACT_REMOTE_LOCKED_PLAN_AUTHORITY
FAIL_CLOSED
ZERO_IMPLEMENTATION

TARGET_SLICE       = S1_SERVER_DATA_MODEL_MIGRATION_FOUNDATION
IMPLEMENTATION     = FALSE
MIGRATION_31_CREATED = FALSE
SOURCE_CHANGED     = FALSE
DEPLOY             = FALSE
```

THIS SESSION CREATED ONLY THIS GOVERNANCE ARTIFACT. IT DID NOT IMPLEMENT S1.
IT DID NOT CREATE MIGRATION `20260820000031`. IT DID NOT EDIT SQL, Dart,
Flutter, Edge Functions, RLS, RPCs, tests, or Supabase production.

---

## 1. Session Identity

```text
SESSION                = PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
MODE                   = SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY / EXACT_REMOTE_LOCKED_PLAN_AUTHORITY / FAIL_CLOSED / ZERO_IMPLEMENTATION
EXPECTED_ENTRY_PLAN_COMMIT = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
EXPECTED_PLAN_PATH     = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
EXPECTED_PLAN_BLOB     = 6bb57e90f3704a9cdee691b19c45c8107b6207af
TARGET_SLICE           = S1_SERVER_DATA_MODEL_MIGRATION_FOUNDATION
AUTHORIZED_OUTPUT      = ONE ADDITIVE S1 IMPLEMENTATION GOVERNANCE ARTIFACT ONLY
IMPLEMENTATION_ALLOWED = FALSE
```

---

## 2. Repository Identity

```text
ROOT             = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH           = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
EXPECTED_FETCH_URL = https://github.com/sabere342-ai/muaman.worktrees.git
EXPECTED_PUSH_URL = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN    = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (SACRED READ-ONLY; never contacted)
```

`origin` is sacred read-only legacy material. This session never fetched from,
pushed to, changed, or deleted `origin`. Only the authorized remote `github`
was contacted.

Identity verified before any write:

```text
git rev-parse --show-toplevel = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
git branch --show-current     = codex/i-tech-next-roadmap-freeze
git remote -v                 = github -> https://github.com/sabere342-ai/muaman.worktrees.git (fetch+push)
                                origin -> <legacy OneDrive path> (sacred, untouched)
```

Result: **REPOSITORY_IDENTITY_MATCHES = TRUE**.

---

## 3. Entry / Recovery Classification

Fresh read-only entry classification performed before any write, including a
`git fetch github` performed ONLY after proving `github` holds the exact
authorized fetch URL.

```text
ENTRY_LOCAL_HEAD                  = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
ENTRY_REMOTE_TRACKING_HEAD        = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
ENTRY_DIRECT_REMOTE_HEAD          = 9ecdc38282cdb7ca6f088263f9e152f920b7a823  (git ls-remote github)
ENTRY_MERGE_BASE                  = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
ENTRY_AHEAD                       = 0
ENTRY_BEHIND                      = 0
TRACKED_WORKTREE_STATE            = CLEAN (git diff --exit-code = no output)
INDEX_STATE                       = EMPTY (git diff --cached --exit-code = no output)
ACTIVE_GIT_OPERATION              = NONE (no sequencer/merge/rebase/cherry-pick state)
STASH_STATE                       = unrelated WIP on codex/muaman-13-strict-july-workbook-data-migration (left untouched)
SACRED_UNTRACKED_EVIDENCE_STATE   = preserved (untracked; never staged/modified)
```

Preserved sacred untracked evidence (not staged, not modified):

```text
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.temp/
```

```text
RECOVERY_CLASSIFICATION = CASE_A_FRESH
```

No destructive recovery methods were used.

---

## 4. Master-Plan Immutable Authority

```text
COMMIT = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
PATH   = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
BLOB   = 6bb57e90f3704a9cdee691b19c45c8107b6207af
```

Proven via Git objects:

```text
git cat-file -t  9ecdc38...  = commit
git ls-tree      9ecdc38...  PHASE_P_OWNER_GATED_GROUP_B_PLAN.md = 100644 blob 6bb57e90f3704a9cdee691b19c45c8107b6207af
At HEAD:          PHASE_P_OWNER_GATED_GROUP_B_PLAN.md            = 6bb57e90f3704a9cdee691b19c45c8107b6207af  ✓
```

The authoritative plan material at current HEAD is unchanged and valid.
Sections read and relied upon: §3 Authority Register, §5 Group B Exact Scope,
§6 Current State Matrix, §7 Commercial/Tier Model, §8 Revocation/Grace,
§9 Integrity/Tamper, §10 Legacy Ed25519, §11 Employee Device Trust,
§12 Supabase Design, §13 Flutter/Client Design, §14 Implementation Slices,
§15 Test/Security Evidence Matrix, §16 Deployment Boundary, §17 Cross-Group
Boundary, §20 Successor Boundary.

Per the master plan, implementation slices are dependency ordered but NOT
pre-authorized. This session therefore remains governance-only.

---

## 5. Full Authority Register

Every immutable authority referenced by the master plan (exact tuples):

| # | Authority | Commit SHA | Path | Expected Blob | Governs |
|---|---|---|---|---|---|
| A1 | Owner Order Decision | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | Group B before Group D |
| A2 | Authority-Binding Correction | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | Group B canonical scope |
| A3 | Post-Migration-30 Exact Commit Binding | `1a4907bc57c00126f131b458a356749abbc4421b` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | Exact post-Migration-30 authority |
| A4 | Post-Migration-30 Authority | `f51be8cf177e5c6c616788bf7733297cd511c640` | `POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md` | `172ae7b9a4f50236c747aeb91022a34024d11b81` | Migration 30 deployed; Group B defined/not started |
| A5 | Phase P Owner Decisions | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` | `PHASE_P_OWNER_DECISIONS.md` | `3028b058c4027557dc6d26911123a8d6a1b9def2` | P-OD8..P-OD13 exact tiers/grace/etc. |
| A6 | Post-Owner-Decisions Governance | `f539282898f142441781010b702c6c28d7f68d4b` | `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` | `c6ae7441b2d701814895a00394257d928da5d388` | planning→lock→impl→lock protocol |
| A7 | Post-Group-A Successor Governance | `7feef87a3d49c2f0d9504d23352d37b700831efb` | `POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md` | `e4d4abb0de7b79893831ffc8eaae86f79c1c2407` | residual Group B P-OD8..12 + WS-4 |
| A8 | Employee Device Trust / Final Delivery | `8d27878a69cbb6c6f440c28f4f55f3ed323312d4` | `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | P-OD13 device trust; server-authoritative gate |

The exact owner order bound (A3/A4): `GROUP_B_BEFORE_GROUP_D`. Not reopened,
not recompared.

---

## 6. Authority Verification Results

For each authority record the tuple was proven directly from Git objects at the
originating commit, and the same material was confirmed unchanged at current
HEAD:

```text
A1  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (37518ed1)
A2  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (57e0f9c3)
A3  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (2925ef5c)
A4  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (172ae7b9)
A5  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (3028b058)
A6  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (c6ae7441)
A7  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (e4d4abb0)
A8  COMMIT_EXISTS=TRUE  PATH_EXISTS_AT_COMMIT=TRUE  BLOB_MATCHES_EXPECTED=TRUE  MATERIAL_AT_HEAD=UNCHANGED (e0016e78)
```

```text
RESULT = AUTHORITY_CHAIN_VERIFIED
```

Owner order remains binding. Group D is `ORDERED_SECOND_AND_DEFERRED`.

---

## 7. Exact S1 Scope

`S1 = SERVER DATA MODEL / MIGRATION FOUNDATION` — the first Group B
implementation slice (dependencies: NONE). Per master-plan §14, S1 is the
additive schema/data-model prerequisite for all later Group B slices.

S1 governs the creation of exactly one additive database migration
`20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql` **in a
future implementation session**. This governance session does NOT create that
file.

S1 prepared foundation covers:

1. `plans` / authoritative tier source (P-OD8 data-model foundation).
2. `devices` `PENDING_APPROVAL` device status (P-OD13 device-lifecycle
   foundation).
3. `devices` public-key foundation (P-OD13 proof-of-possession prerequisite).
4. `invitations` token-hash foundation (P-OD13 invitation-hardening
   prerequisite).
5. Device audit foundation (P-OD13 approval/revocation audit trail).

S1 also defines the exact data-model decisions, constraints, indexes,
backfill doctrine (deferred), compatibility strategy, and test requirements
needed so the future S1 implementation is fully deterministic.

---

## 8. Exact S1 Non-Goals

The following are explicit non-goals of S1. S1 MUST NOT:

```text
MAKE A DEVICE TRUSTED ....................... S1 only stores public material; approval/trust is a later slice.
IMPLEMENT PROOF OF POSSESSION ................ S1 only adds the public-key storage foundation.
MODIFY RLS AUTHORIZATION ..................... No RLS policy change in S1; tenant isolation unchanged.
AUTHORIZE BUSINESS-DATA ACCESS ............... No entitlement/business-data grant in S1.
DELIVER DEVICE APPROVAL UI ................... No client/UI change in S1.
FIX accept_invitation ........................ accept_invitation correction is S4; S1 only adds token storage.
DEPLOY TO PRODUCTION ......................... No deployment in S1 or this governance session.
CREATE MIGRATION 31 .......................... This governance session only; file created in future impl session.
BACKFILL EXISTING LICENSE ROWS ............... Migration-from-existing-records is S2.
ENFORCE OFFLINE GRACE / REVOCATION ........... That enforcement is S2/S3; S1 is data-model foundation only.
REGISTER / ACTIVATE / DEACTIVATE semantics .... S1 must not change register/activate/deactivate RPC behavior.
COLLECT PRIVATE KEYS OR SECRETS .............. Public key storage only; never private keys/passwords/tokens plaintext.
```

---

## 9. Current Repository Reality Audit

Read-only audit performed before writing governance. Highest existing committed
migration is `20260820000030`, confirming the planning assumption. Migration
files `00000` through `00030` are committed and immutable; none may be edited.

### 9.1 Migration inventory (committed)

Highest committed migration = `20260820000030_phase_p_a4_cloud_stock_adjustments.sql`.

No committed governance names Migration 31. Next additive Group B identifier =
`20260820000031`. No migration file is created by this session.

### 9.2 Devices (`20260820000004`, additive `20260820000023`)

Columns: `id`, `installation_id`, `shop_id`, `user_id` (nullable),
`platform` (windows|android), `device_name`, `first_seen_at`, `last_seen_at`,
`status`, `created_at`.

```text
status CHECK = ('ACTIVE','REVOKED','LOST')   ... no PENDING_APPROVAL
no public-key column                         ... no proof-of-possession foundation
no approved_by/approved_at/revoked_by/revoked_at
unique idx (installation_id, shop_id)
```

`register_device` (00023) force-sets `status='ACTIVE'`; `activate_device`
(00023) enforces `max_devices`; `deactivate_device`, `get_device_list` (00023)
are owner-only, no UI call sites.

### 9.3 Licenses (`20260820000005`, additive `20260820000023`)

Columns: `id`, `shop_id`, `license_key`, `plan` (nullable TEXT, unused),
`status` (TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL), `trial_*`, `activated_at`,
`subscription_expires_at`, `created_at`; additive `updated_at`, `max_devices`
(default 3), `revoked_at`, `metadata`.

```text
plan is a free TEXT, unused, not bound to any authoritative tier source
max_devices fixed default 3, not tier-derived
no user quota column
```

### 9.4 Activations (`20260820000006`, additive `20260820000023`)

Columns: `id`, `license_id`, `device_id`, `activated_at`, `last_verified_at`,
`status` (CHECK ACTIVE/REVOKED/EXPIRED). Not changed by S1.

### 9.5 Invitations (`20260820000021`)

Columns: `id`, `shop_id`, `email`, `role` (employee|salesOnly), `invited_by`,
`status` (PENDING/ACCEPTED/EXPIRED/REVOKED), `created_at`, `accepted_at`,
`expires_at`.

```text
NO token column — token-hash foundation absent
```

### 9.6 accept_invitation (`20260820000022`)

Client-supplied `p_user_id`, no identity proof, no token, no expiry check →
membership-takeover risk (P-OD13 §H.4). S1 does NOT fix this (S4 does); S1 only
prepares token-hash storage.

### 9.7 RBAC / RLS

`require_shop_permission` (`20260820000024:232`) — auth + membership +
entitlement + permission; **no device-status predicate**.
RLS (`20260820000010`) — `shop_devices_isolation` etc. tenant isolation via
`auth.uid()` + ACTIVE membership; **no device-trust predicate**.
S1 does not alter RLS; it only prepares the schema the later device predicate
will read.

### 9.8 `invite-employee` Edge Function

`supabase/functions/invite-employee/index.ts` — creates temp random password
never delivered (TODO), `email_confirm:true`, no invitation token. S1 does not
modify this function; S1 only prepares the token-hash field that a later slice
will populate.

### 9.9 Test infrastructure

- pgTAP-style database tests: `supabase/tests/*.test.sql` run with
  `supabase test db` (e.g., `cloud_stock_adjustments.test.sql`,
  `rls_shop_members_recursion.test.sql`).
- Flutter tests: `app/test/...` run with `flutter test`.
- Edge function test: `supabase/functions/invite-employee/index.test.ts`.

---

## 10. Exact Future Migration Path / Name

Derived from repository naming convention (lowercase snake, `<ts>_<phase>_<desc>.sql`):

```text
FUTURE_MIGRATION_FILE =
supabase/migrations/20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql

MIGRATION_FILE_CREATED = FALSE   (this governance session creates no migration file)
```

Historical migrations `00001`..`00030` are immutable and MUST NOT be edited or
rewritten.

---

## 11. Exact Planned Schema Changes (for the future S1 implementation)

The future S1 implementation shall apply EXACTLY these additive schema changes
in one migration `20260820000031`:

### 11.1 `plans` table (authoritative tier source — P-OD8 foundation)

```text
CREATE TABLE IF NOT EXISTS plans (
  key            TEXT PRIMARY KEY,                 -- 'trial'|'starter'|'professional'|'enterprise'
  name           TEXT NOT NULL,                    -- display name
  user_limit     INTEGER,                          -- NULL = unlimited (ENTERPRISE)
  device_limit   INTEGER,                          -- NULL = unlimited (ENTERPRISE)
  trial_days     INTEGER,                          -- 14 only for trial; else NULL/0
  billing_cadence TEXT NOT NULL DEFAULT 'monthly'  -- 'monthly'|'annual'|NULL-as-compat
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_plans_key ON plans(key);
```

Seed rows are deterministic and equal the committed owner authority (P-OD8):

```text
('trial',        'Trial',        1,        1,        14, NULL)
('starter',      'Starter',      2,        3,        NULL, 'monthly')
('professional', 'Professional', 5,        10,       NULL, 'monthly')
('enterprise',   'Enterprise',   NULL,     NULL,     NULL, 'monthly')
```

`NULL` on `user_limit`/`device_limit` is the explicit representation of
unlimited (ENTERPRISE) — **no arbitrary magic integers** are used to mean
unlimited. `billing_cadence` is data-model plumbing only; no billing provider is
introduced anywhere in S1.

### 11.2 `licenses` binding foundation (additive columns only)

```text
ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS plan_key TEXT REFERENCES plans(key);

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS user_limit INTEGER;      -- NULL until derived

CREATE INDEX IF NOT EXISTS idx_licenses_plan_key ON licenses(plan_key);
```

Adding `plan_key` as a nullable FK is the schema binding that will later let the
server resolve tier limits. Existing `licenses.plan` (free TEXT) is preserved
and NOT backfilled in S1 (backfill is S2). No row mutation occurs in S1.

### 11.3 `devices` status `PENDING_APPROVAL` (additive CHECK extension)

S1 extends the device lifecycle with the exact new status:

```text
-- devices status: add PENDING_APPROVAL to the allowed set (P-OD13)
ALTER TABLE devices DROP CONSTRAINT devices_status_check;
ALTER TABLE devices ADD CONSTRAINT devices_status_check
  CHECK (status IN ('ACTIVE','REVOKED','LOST','PENDING_APPROVAL'));
```

The new device status is **`PENDING_APPROVAL`** (exact; NOT plain `PENDING`,
to avoid semantic ambiguity with the existing `invitations.status='PENDING'`).
This is an additive DDL change applied via the new migration to the current-state
`devices` table; the historical migration file `20260820000004` is never edited.

### 11.4 `devices` public-key foundation (additive columns)

```text
ALTER TABLE devices ADD COLUMN IF NOT EXISTS public_key TEXT;     -- PUBLIC material only
ALTER TABLE devices ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS revoked_by UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(shop_id, status);
```

`public_key` stores **public material only**. It MUST NOT store private keys,
passwords, reusable employee secrets, pairing tokens, or invasive device
fingerprint data beyond what exists today.

### 11.5 `invitations` token-hash foundation (additive columns)

```text
ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS token_hash TEXT;            -- server-stored HASH of one-time token
ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS accepted_by UUID REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_invitations_token_hash ON invitations(token_hash) WHERE token_hash IS NOT NULL;
```

Foundation compatible with: random token, short lifetime (reuse existing
`expires_at`), single use, server-stored hash, shop-bound, email-bound, role-bound
(role already present), expiry (already present), revocation (already present
via `status`), replay resistance. Actual invitation-acceptance logic belongs to
later slice S4.

### 11.6 Audit foundation (additive table)

```text
CREATE TABLE IF NOT EXISTS device_audit_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  device_id     UUID REFERENCES devices(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL,
  action        TEXT NOT NULL,          -- register|approve|reject|revoke|lost|proof_failed|...
  detail        JSONB DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_device_audit_shop ON device_audit_log(shop_id, created_at DESC);
```

PLUS a `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` column on
`device_audit_log` (required for the ordering index; the column is part of the
governed definition). Audit records approval/rejection/revocation/lost/failed
proof. **No secrets or PII in audit `detail`.** This is a separate audit
surface from the existing `permission_audit_log` (00024).

### 11.7 RLS on new objects

S1 adds RLS enabling for any new tables it creates (`plans`, `device_audit_log`)
with minimal SELECT-only membership-based isolation comparable to the existing
`permission_audit_log`/`shop_permission_overrides` pattern, and INSERT/UPDATE/
DELETE restricted to service_role. RLS enabling on new tables is a data-model
foundation (not a business-data authz change); it keeps tenant isolation
unchanged for existing business tables. `plans` is a read-only reference table;
its SELECT isolation mirrors tier metadata access for ACTIVE members.

---

## 12. Existing Objects Explicitly Preserved

The following are immutably preserved by S1 (no edit):

```text
All migrations 00000..00030  (never edited, never rewritten)
licenses                     (additive columns only; existing rows/plan/status untouched)
devices                      (additive columns + CHECK re-add only; existing rows untouched)
activations                  (unchanged)
invitations                  (additive columns only; existing rows untouched)
roles / role_permissions_cloud (unchanged)
shop_members                 (unchanged)
register_device              (behavior unchanged)
activate_device              (behavior unchanged)
deactivate_device            (behavior unchanged)
get_device_list              (behavior unchanged)
verify_license_entitlement   (behavior unchanged)
require_shop_permission      (unchanged)
check_effective_permission / get_effective_permissions / sync_user_permissions (unchanged)
accept_invitation            (unchanged — fixed in S4)
RLS policies (20260820000010) (unchanged — device-trust predicate is S4)
invite-employee Edge Function (unchanged)
```

---

## 13. Tier / Commercial Data-Model Decision

Decision from repository reality: a **dedicated `plans` lookup table** is the
correct minimal additive representation, rather than embedding tier limits only
in `licenses` metadata. Rationale:

- Master plan §7.2 requires "a single server-authoritative tier definition
  (limits, billing cadence, trial duration) — not duplicated in Flutter as an
  authority."
- A dedicated table is the single deterministic authoritative source; the
  existing `licenses.plan` (free TEXT) and `licenses.max_devices` (fixed default
  3) are NOT authoritative tier sources.
- `NULL` user/device limits represent unlimited (ENTERPRISE), avoiding magic
  integers.
- S1 only binds `licenses.plan_key` as a nullable FK foundation; it does not
  backfill existing rows (that is S2 migration-from-existing-records).

No external billing provider, payment gateway, Stripe, Paymob, Play Billing,
App Store billing, or billing webhook is introduced in S1.

---

## 14. Device Lifecycle / Status Data-Model Decision

New device status = **`PENDING_APPROVAL`** (exact). Added to the device status
CHECK set. Semantics (data-model only; enforcement in later slices):

```text
PENDING_APPROVAL -> ACTIVE   (Owner approves)      [S4 + S7]
ACTIVE           -> REVOKED  (Owner revokes/membership revoked)  [S4]
ACTIVE           -> LOST     (Owner marks lost)     [S4]
```

`PENDING_APPROVAL` is preferred over plain `PENDING` to avoid ambiguity with
`invitations.status='PENDING'`. Existing statuses ACTIVE/REVOKED/LOST remain
backward compatible. S1 does not change any RPC behavior; it simply makes the
state representable.

---

## 15. Device Public-Key Foundation

`devices.public_key` (TEXT). Public material only. Supports future
proof-of-possession (S4/S6) without implementing any cryptographic protocol now.
Approval metadata columns (`approved_by`, `approved_at`, `revoked_by`,
`revoked_at`) support the owner-approval lifecycle. **Never store private keys,
passwords, reusable employee secrets, plaintext pairing tokens, or unnecessary
hardware identifiers/fingerprints.**

---

## 16. Invitation Token / Hash Foundation

`invitations.token_hash` (TEXT) stores a server-side hash of a one-time pairing
token; `invitations.accepted_by` records the accepting auth user. No plaintext
token stored. Reuses existing `expires_at` (short lifetime) and existing `status`
(revocation/single-use). Actual token issuance, acceptance validation,
`accept_invitation` correction, and replay/expiry enforcement are S4. Static
shared shop-code as an authorization factor remains REJECTED (P-OD13 §K).

---

## 17. Audit Foundation

`device_audit_log` additive table records owner device-approval lifecycle and
any later proof-failure markers. Separate from `permission_audit_log`. No
secrets/PII in audit detail. Population and enforcement of audit entries occur
in later slices; S1 only defines the storage shape.

---

## 18. Constraints / Indexes

Additive constraints and indexes governed by S1:

```text
devices_status_check             = ('ACTIVE','REVOKED','LOST','PENDING_APPROVAL')
idx_devices_status               = (shop_id, status)
idx_plans_key                    = UNIQUE (plans.key)
idx_licenses_plan_key            = (licenses.plan_key)
idx_invitations_token_hash       = (invitations.token_hash) WHERE token_hash IS NOT NULL
idx_device_audit_shop            = (device_audit_log.shop_id, created_at DESC)
plans PK                         = key TEXT PRIMARY KEY
device_audit_log PK              = id UUID PRIMARY KEY
```

No changes to existing constraints on activations/licenses beyond the additive
columns above.

---

## 19. Data Migration / Backfill Strategy

S1 does **NO** row backfill. Governing doctrine:

- Existing `licenses` rows (TRIAL/ACTIVE/PERPETUAL) are left untouched by S1.
- Any mapping of existing license records to a tier (master plan §7.4: TRIAL→TRIAL,
  ACTIVE→STARTER default, PERPETUAL stays compatibility-only) is performed ONLY in
  later slice S2, governed separately, and only after S1's schema is locked.
- S1 migration must be replayable/idempotent: all `CREATE TABLE IF NOT EXISTS`,
  `ADD COLUMN IF NOT EXISTS`, `CREATE ... IF NOT EXISTS`; the `devices` CHECK
  constraint drop/re-add must be written to be safe against re-run if the target
  constraint already has the extended set.

---

## 20. Compatibility Strategy

- Additive-only: no destructive column/table change; no data loss.
- Existing `devices` ACTIVE/REVOKED/LOST rows remain valid.
- Existing `licenses.plan` free text preserved.
- Existing RPCs (register/activate/deactivate/get_device_list/verify/
  require_shop_permission) keep current signatures and behavior.
- RLS tenant isolation unchanged or strengthened; never weakened.
- New status `PENDING_APPROVAL` is additive; no existing client breaks, and the
  future approval flow reads it.
- Migration 31 replays cleanly on a fresh local stack and on top of committed
  00030 in the governed deployment stage.

---

## 21. Security / Privacy Boundaries

```text
S1 DOES NOT MAKE A DEVICE TRUSTED.
S1 DOES NOT IMPLEMENT PROOF OF POSSESSION.
S1 DOES NOT MODIFY RLS AUTHORIZATION for business data.
S1 DOES NOT AUTHORIZE BUSINESS-DATA ACCESS.
S1 DOES NOT DELIVER DEVICE APPROVAL UI.
S1 DOES NOT FIX accept_invitation.
S1 DOES NOT DEPLOY TO PRODUCTION.
```

Device public-key storage stores public material only. Never: private keys,
passwords, reusable employee secrets, plaintext pairing tokens where hash
storage is required, unnecessary hardware identifiers, invasive device
fingerprint data beyond existing legitimate needs.

Invitation token foundation is compatible with: random, short lifetime, single
use, server-stored hash, shop-bound, email-bound, role-bound, expiry,
revocation, replay resistance. Acceptance logic stays in later authorized slice
S4.

---

## 22. P-OD13 CASE 1-20 S1 Coverage Classification

```text
FOUNDATION_PREPARED  = S1 stores/represents the data needed for the control
NOT_YET_ENFORCED     = the control is enforced by a later slice
NOT_APPLICABLE_TO_S1 = no S1 surface involvement
```

| # | Case | S1 classification |
|---|---|---|
| 1 | Employee + ACTIVE membership + approved device | FOUNDATION_PREPARED (device status + public key stored) |
| 2 | New unapproved device denied | FOUNDATION_PREPARED (PENDING_APPROVAL representable) |
| 3 | Stolen creds from another device | FOUNDATION_PREPARED (public key + approval fields) |
| 4 | shop_id change / cross-tenant | NOT_YET_ENFORCED (S4 RLS/device predicate) |
| 5 | Direct API, no device-trust proof | NOT_YET_ENFORCED (S4 server gate) |
| 6 | Owner approves pending device | FOUNDATION_PREPARED (approved_by/at fields) |
| 7 | Owner rejects | FOUNDATION_PREPARED (audit + status) |
| 8 | Owner revokes ACTIVE | FOUNDATION_PREPARED (revoked_by/at + audit) |
| 9 | Owner marks LOST | FOUNDATION_PREPARED (REVOKED/LOST + audit) |
| 10 | Membership suspended/revoked | NOT_YET_ENFORCED (S4 membership gate) |
| 11 | Expired invitation/pairing token | NOT_YET_ENFORCED (S4; S1 stores token_hash) |
| 12 | Used-token replay | NOT_YET_ENFORCED (S4; S1 stores token_hash) |
| 13 | Shop-A token vs Shop B | NOT_YET_ENFORCED (S4; S1 shops-bound) |
| 14 | Second legitimate device | FOUNDATION_PREPARED (device rows + quota data model) |
| 15 | Reinstall | FOUNDATION_PREPARED (new device identity -> PENDING_APPROVAL) |
| 16 | Approved device offline | NOT_APPLICABLE_TO_S1 (S2/S3 grace) |
| 17 | Unknown first-time device offline | NOT_YET_ENFORCED (S4 server never grants) |
| 18 | salesOnly gains no higher role | NOT_YET_ENFORCED (S4 RBAC unchanged by approval) |
| 19 | Modified client / direct RLS call | NOT_YET_ENFORCED (S4 server gate) |
| 20 | No reusable password retained | NOT_APPLICABLE_TO_S1 (S4 invitation correction) |

**S1 does NOT claim CASE 1-20 compliance.** S1 only prepares the data-model
foundation for these controls.

---

## 23. Expected Implementation Files / Surfaces (future S1 session)

```text
CREATE
supabase/migrations/20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql   (the single additive migration)
supabase/tests/s1_server_data_model_foundation.test.sql                                   (pgTAP structural tests)
```

NO other source, Dart, Flutter, Edge Function, RLS, RPC, or test file is changed
by the governed S1 implementation. One implementation commit unless evidence
requires otherwise.

---

## 24. Tests Required During S1 Implementation

Determined from repository reality (pgTAP `supabase/tests/*.test.sql` via
`supabase test db`, plus `flutter test` where relevant):

```text
Database (pgTAP) — supabase/tests/s1_server_data_model_foundation.test.sql:
  T1  plans table exists, RLS enabled, PK on key
  T2  plans seeded exactly: trial 1/1/14, starter 2/3, professional 5/10, enterprise NULL/NULL
  T3  ENTERPRISE user_limit & device_limit are NULL (no magic integer)
  T4  licenses.plan_key column exists and is a nullable FK to plans
  T5  devices.status CHECK accepts PENDING_APPROVAL
  T6  devices.public_key / approved_by / approved_at / revoked_by / revoked_at columns exist
  T7  devices has no column storing private material (no private_key / secret / password column present)
  T8  invitations.token_hash + accepted_by columns exist (token_hash never plaintext by definition of storage column)
  T9  device_audit_log exists, RLS enabled, has shop_id + created_at + ordering index
  T10 migration replayable/idempotent: applying migration to a fresh stack and re-running leaf constructs yields a clean schema
  T11 historical migrations 00000..00030 unchanged (no git diff) and schema after 00030 is intact
  T12 no business RLS policy weakened; tenant isolation intact (existing rls tests still pass)

Flutter (unchanged by S1; regression only):
  flutter test  (all existing app/test suite passes — confirms no client regression introduced by governance)

Edge Function:
  existing invite-employee test unaffected (S1 does not modify the function)
```

---

## 25. Migration Replay Requirements

- The S1 migration is single, additive, and idempotent (`IF NOT EXISTS`).
- Clean `supabase db reset` / `supabase migration up` (local) applies 00000..00031
  with no error.
- The CHECK constraint drop/re-add must be guarded to be safe on re-run.
- No historical migration rewritten; no rollback migration required for additive
  schema (forward-fix doctrine applies, see §27).

---

## 26. Acceptance Criteria (future S1 implementation)

The future S1 implementation passes ONLY when:

```text
Exactly the governed additive migration 20260820000031 exists
Historical migrations 00000..00030 unchanged (clean git diff of migrations/ = only the new file)
Clean migration replay on local stack
plans seeds deterministic and equal P-OD8 tiers; ENTERPRISE unlimited represented as NULL
devices PENDING_APPROVAL status representable; existing statuses backward compatible
devices public-key columns present and store public material only (no private/secret column)
invitations token_hash/accepted_by present; token foundation safe
device_audit_log present with RLS and no secrets/PII column contract
No accidental commercial entitlement escalation (no row backfill, no tier change in S1)
Tenant isolation unchanged or strengthened; RLS not weakened
No temp-password regression (invite-employee function untouched)
All pgTAP tests (§24) pass via supabase test db
Existing Flutter/server/app tests unaffected (flutter test passes)
No production deployment
One implementation commit unless evidence requires otherwise
Normal fast-forward remote lock after implementation commit
```

---

## 27. Failure / Rollback / Forward-Fix Considerations

- **Rollback:** S1 is additive-only. If a defect is found after S1 is applied,
  the doctrine is **forward-fix** (a new additive corrective migration), not
  editing migration 31 or rewriting 00000..00030.
- **Idempotency:** all constructs idempotent; re-apply safe.
- **Backward compatibility:** existing rows/statuses untouched; no data migration
  in S1.
- **Deployment:** S1 is NOT deployed by this governance session and is NOT
  deployed by the S1 implementation-only session without separate deployment
  authorization (S11 stage governs production migration/verification).
- If any acceptance criterion fails, fail closed: no commit, no push; report
  blocker.

---

## 28. Deployment Boundary

```text
S1 MIGRATION CREATION ........... future governed S1 implementation session
S1 LOCAL TESTING ................ future governed S1 implementation session
S1 REMOTE IMPLEMENTATION LOCK ... future governed remote-lock session
PRODUCTION DEPLOYMENT ........... NOT authorized by this session; future governed deployment (S11) stage
POST-DEPLOY VERIFICATION ........ future governed verification (S11) stage
```

No Supabase CLI deployment, no `supabase db push`, no `supabase migration up`
against production, no `supabase functions deploy`, no psql production mutation
in this session or in the S1 implementation-only session without separate
deployment authority.

---

## 29. Explicit Deferred Slices S2-S12

```text
S2  Server entitlement + quota authority
S3  Revocation / offline-grace authority
S4  Device-trust server gate + invitation hardening
S5  Client entitlement integration
S6  Platform secure device identity
S7  Owner device management UI
S8  Tamper / cache / clock enforcement
S9  Legacy Ed25519 retirement
S10 Test / security convergence
S11 Deployment / verification governance
S12 Group B closeout
```

None of these are performed by this session. S1 only documents its interfaces
and dependencies with them (e.g., S1's device status/public-key/token columns
are consumed by S2/S4/S6).

---

## 30. Group C / D Boundary

```text
GROUP_C_IMPLEMENTATION = OUT_OF_SCOPE
GROUP_D_PLANNING       = DEFERRED (ordered second)
GROUP_D_IMPLEMENTATION = OUT_OF_SCOPE

ANDROID_FINAL_RELEASE_BUILD = OUT_OF_SCOPE
AAB_BUILD / AAB_UPLOAD      = OUT_OF_SCOPE
PLAY_PUBLICATION            = OUT_OF_SCOPE
P_OD7_DRAIN_CHANGE          = OUT_OF_SCOPE
MIGRATION_30_CHANGE         = OUT_OF_SCOPE
```

Owner order `GROUP_B_BEFORE_GROUP_D` is not reopened; Group D is ordered second
and deferred.

---

## 31. Non-Actions Ledger

```text
S1 IMPLEMENTATION         = FALSE
MIGRATION_31_CREATED      = FALSE
SOURCE_CODE_CHANGED       = FALSE
EDIT SQL / DART / FLUTTER = FALSE
EDGE FUNCTIONS CHANGED    = FALSE
RLS CHANGED               = FALSE
RPC FUNCTIONS CHANGED     = FALSE
DATABASE_MIGRATION_CREATED = FALSE
PRODUCTION_MIGRATION_RUN  = FALSE
SUPABASE_DEPLOYMENT       = FALSE
PRODUCTION_DATA_CHANGED   = FALSE
SYNC_DRAIN_CHANGED        = FALSE
ANDROID_BUILD / AAB       = FALSE
PLAY_CONSOLE_CHANGED      = FALSE
SIGNING / KEYSTORE        = FALSE
GROUP_C_STARTED           = FALSE
GROUP_D_STARTED           = FALSE
MIGRATION_30_REOPENED     = FALSE
LEGACY_ORIGIN_MUTATED     = FALSE
SACRED_EVIDENCE_DELETED   = FALSE
FORCE_PUSH_USED           = FALSE
FORCE_WITH_LEASE_USED     = FALSE
REBASE_USED               = FALSE
AMEND_USED                = FALSE
HARD_RESET_USED           = FALSE
GIT_CLEAN_USED            = FALSE
```

---

## 32. Implementation-Successor Boundary

Successful completion of THIS governance session means only:

```text
S1_IMPLEMENTATION_GOVERNANCE = CREATED + COMMITTED + REMOTE_LOCKED
S1_IMPLEMENTATION            = NOT_STARTED
```

The next session is:

```text
PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION
```

That future session may implement ONLY the exact S1 contract defined by this
governance artifact (single additive migration `20260820000031` + pgTAP tests),
and still may NOT deploy production unless separately authorized (S11).
