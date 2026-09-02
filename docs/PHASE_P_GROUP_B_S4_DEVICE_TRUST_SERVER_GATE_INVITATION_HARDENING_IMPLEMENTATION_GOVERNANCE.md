# PHASE P — GROUP B S4 DEVICE-TRUST SERVER GATE + INVITATION HARDENING — IMPLEMENTATION GOVERNANCE

```text
SESSION =
PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED

TARGET_SLICE       = S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING
IMPLEMENTATION     = FALSE
MIGRATION_34_CREATED = FALSE
SOURCE_CHANGED     = FALSE
DEPLOY             = FALSE
PRODUCTION_MUTATED = FALSE
GROUP_D_ADVANCED   = FALSE
```

THIS DOCUMENT GOVERNS A FUTURE S4 IMPLEMENTATION.
IT DOES NOT IMPLEMENT S4.

THIS SESSION CREATED ONLY THIS GOVERNANCE ARTIFACT. IT DID NOT IMPLEMENT S4.
IT DID NOT CREATE MIGRATION `20260820000034`. IT DID NOT EDIT SQL, Dart,
Flutter, Edge Functions, RLS, RPCs, tests, or Supabase production. It did not
edit S1 (`334d1ad`), S2 (`85e4315`), S3 (`62af446`), migrations `00031`,
`00032`, `00033`, or migrations `00000..00030`.

---

## A. Session Identity

```text
SESSION                = PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
MODE                   = SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED
TARGET_UNIT            = Group B S4 - Device-trust server gate + invitation hardening
EXPECTED_SUCCESS_TOKEN = PASS_PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
IMPLEMENTATION         = FALSE
AUTHORIZED_OUTPUT      = ONE ADDITIVE S4 IMPLEMENTATION GOVERNANCE ARTIFACT ONLY
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
pushed to, modified, deleted, renamed, reconfigured, or used `origin` as
recovery. Only the authorized remote `github` was contacted (read-only
`git ls-remote` / `git fetch github`).

Identity was proven before any write:

```text
git rev-parse --show-toplevel = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
git branch --show-current     = codex/i-tech-next-roadmap-freeze
git remote -v                 = github -> https://github.com/sabere342-ai/muaman.worktrees.git (fetch+push)
                                origin -> <legacy OneDrive path> (sacred, untouched)
```

Result: **REPOSITORY_IDENTITY_VERIFIED = TRUE**.
**LEGACY_ORIGIN_CONTACTED = NO.** **LEGACY_ORIGIN_MUTATED = NO.**

---

## C. Entry / Recovery Classification

```text
ENTRY_LOCAL_HEAD           = 62af44695e664722d1ccabf5816f55678d1e049a
ENTRY_REMOTE_TRACKING_HEAD = 62af44695e664722d1ccabf5816f55678d1e049a
ENTRY_DIRECT_REMOTE_HEAD   = 62af44695e664722d1ccabf5816f55678d1e049a   (git ls-remote github)
ENTRY_MERGE_BASE           = 62af44695e664722d1ccabf5816f55678d1e049a
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
reports (`GROUP_A_PHASE_P_OD7_*.md`, `GROUP_A_PHASE_Q_*.md`),
`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`,
`delivery/I-TECH-Delivery-v1.0.0.zip`, and related untracked forensic
material. No `git clean`, no reset, no stash mutation.

No prior S4 governance commit was found (no `docs/*GROUP_B_S4*` tracked file).
Case B (governance recovery) did not apply; fresh CASE A governs.

---

## D. Authority Provenance

The committed Group B authority chain was proven directly from Git objects
(`git cat-file -t`, `git rev-parse <commit>:<path>`, `git ls-tree <commit> <path>`)
and confirmed present, unchanged, and ancestor of the current authorized
baseline `HEAD`:

| Token | Commit | Path | Expected Blob | Actual Blob | Authority | Result |
|---|---|---|---|---|---|---|
| Owner Order | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | `37518ed12f0402e059e099be8104b21b2d07c64f` | Group B before Group D | PASS |
| Authority-Binding Correction | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | `57e0f9c393ea9ef3484a5312612f7703509747af` | Group B canonical scope | PASS |
| Post-M30 Exact Binding | `1a4907bc57c00126f131b458a356749abbc4421b` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | Post-Migration-30 authority | PASS |
| Group B Master Plan | `9ecdc38282cdb7ca6f088263f9e152f920b7a823` | `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | S1..S12 slices; P-OD8..P-OD13; S4 definition & deps | PASS |
| P-OD13 Authority | `8d27878a69cbb6c6f440c28f4f55f3ed323312d4` | `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | P-OD13 employee device trust / defense-in-depth | PASS |
| S1 Governance | `334d1ad443ef709a5c95a7c657024e40c40656aa` | `docs/PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE.md` | `0612e37374b4756e28d9547ee03dd6e312aeb2db` | `0612e37374b4756e28d9547ee03dd6e312aeb2db` | S1 closure; S4 foundation (PENDING/public key/token) | PASS |
| S2 Governance | `a4fcada1538505bbf527a0fc9d707004490d4ac0` | `docs/PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md` | `9163f1bbe0c75b70e65b15788088a230d8741e31` | `9163f1bbe0c75b70e65b15788088a230d8741e31` | S2 closure; S4 dependency met | PASS |
| S3 Governance | `7d05313cf1a50765ad6721b264a7b05e51263ffd` | `docs/PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md` | `e0a4eb6d564422190e0602902403c4f181dd9feb` | `e0a4eb6d564422190e0602902403c4f181dd9feb` | S3 closure; S4 composes with S3 revocation | PASS |

```text
RESULT = AUTHORITY_CHAIN_VERIFIED   (no mismatch; no conflicting newer committed authority separately contradicting S4 scope)
```

All mandatory authority blob tuples are also equal to the same blobs at current
`HEAD` (material authority drift = NONE).

**D4 note — Master Plan resolution:** the abbreviated `9ecdc38282c...` in the
session prompt was resolved from Git objects to full commit
`9ecdc38282cdb7ca6f088263f9e152f920b7a823`, path
`PHASE_P_OWNER_GATED_GROUP_B_PLAN.md`, blob
`6bb57e90f3704a9cdee691b19c45c8107b6207af`. The plan defines S4 =
"Device-trust server gate + invitation hardening", scope (approved-device
predicate in authorization/RLS/read path; owner approve/reject/revoke/lost
device authority; proof-of-possession server side; corrected accept_invitation;
invitation token hardening), dependencies S1 + S2.

Non-owner decisions are NOT reopened. In particular, the Owner Order
(Group B before Group D) is final and not re-litigated by this session.

---

## E. Predecessor S1/S2/S3 Bindings (current committed realities)

### E.1 S1 implementation (current, immutable)

```text
COMMIT      = 334d1ad443ef709a5c95a7c657024e40c40656aa
MIGRATION   = supabase/migrations/20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql
  BLOB      = 2ab6436673ecf1ac6e9c39e7fb11403f245dfc2b
TEST        = supabase/tests/s1_server_data_model_foundation.test.sql
  BLOB      = 43f5f68cf5ffcdadb6468af066958bb310923544
GOVERNANCE  = docs/PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE.md
  BLOB      = 0612e37374b4756e28d9547ee03dd6e312aeb2db
```

S1 foundation relevant to S4 (already committed, immutable):
- `plans` authoritative tier source (user_limit/device_limit per P-OD8).
- `devices` additive: `PENDING_APPROVAL` status, `public_key`, `approved_by`,
  `approved_at`, `revoked_by`, `revoked_at`; `idx_devices_status(shop_id,status)`.
- `invitations` additive: `token_hash`, `accepted_by`; `idx_invitations_token_hash`.
- `device_audit_log` table + `plans`/`device_audit_log` RLS (SELECT-only,
  ACTIVE-membership based).
- S1 explicitly defers device-trust / proof-of-possession and invitation token
  validation to S4.

### E.2 S2 implementation (current, immutable)

```text
COMMIT      = 85e43154de37f9b4987e9bab1a55548e1c9433fc
MIGRATION   = supabase/migrations/20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql
  BLOB      = 5451fa269870bc98f33aae21ceeb9e74b8db12b8
TEST        = supabase/tests/s2_server_entitlement_quota_authority.test.sql
  BLOB      = 6c9655f589e897e3e912581ef99f55f44ddb4514
GOVERNANCE  = docs/PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md
  BLOB      = 9163f1bbe0c75b70e65b15788088a230d8741e31
```

S2 foundation relevant to S4 (already committed, immutable):
- `s2_resolve_entitled_license(shop_id)` server-authoritative entitlement/tier.
- `s2_enforce_user_quota()` trigger on `shop_members` ACTIVE transitions.
- `activate_device()` rewritten with plan-based device quota.
- `verify_license_entitlement()` rewritten with plan-based limits.
- Canonical shop-keyed advisory-lock namespace
  `hashtextextended(p_shop_id::text, 0)`.

### E.3 S3 implementation (current, immutable)

```text
COMMIT      = 62af44695e664722d1ccabf5816f55678d1e049a  (== this session's ENTRY HEAD)
MIGRATION   = supabase/migrations/20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql
  BLOB      = b60487110f9ddd9ade0d6cfde65b0e0b64218bbd
TEST        = supabase/tests/s3_revocation_offline_grace_authority.test.sql
  BLOB      = a1a1311fe863030aa4bedcac48bc2bb89c2bc9df
GOVERNANCE  = docs/PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md
  BLOB      = e0a4eb6d564422190e0602902403c4f181dd9feb
```

S3 ownership relevant to S4 (already committed, immutable):
- `licenses.status` includes terminal `REVOKED`; `licenses.revoked_at` authority.
- `s3_revoke_license(shop_id, reason)` — owner-only, cascades devices+activations.
- `s3_revoke_device(shop_id, device_id, reason)` — owner-only, tenant-scoped,
  cascades activations, audits.
- `s3_revoke_membership(shop_id, member_user_id, reason)` — owner-only, cascades
  member's devices+activations, cannot revoke own owner membership.
- `verify_license_entitlement()` extended to 16 columns (is_revoked, revoked_at).
- `activate_device()` rejects REVOKED device; `register_device()` rejects
  REVOKED re-registration.
- All revocation-plus-activation mutations serialize under the same shop-keyed
  advisory-lock namespace used by S2.

### E.4 Lineage / ancestor proof

```text
334d1ad (S1 impl) -> 45018ee -> 9ecdc38 (plan) ... S1 impl
334d1ad -> c6ddbb4 -> a4fcada (S2 gov) -> 85e4315 (S2 impl)
85e4315 -> 7d05313 (S3 gov) -> 62af446 (S3 impl) = HEAD
```

All S1/S2/S3 files and authorities are ancestors of HEAD and unmodified
(blobs at HEAD equal blobs at their originating commits). S1, S2, S3 migration/
test/governance files are immutable for S4.

---

## F. Exact S4 Scope

S4 (server side only) owns:

```text
1. Approved / trusted-device SERVER model and lifecycle transitions
   (PENDING_APPROVAL/APPROVED-ACTIVE/REJECTED/REVOKED/LOST), composed with the
   S1 PENDING_APPROVAL + approval metadata and S3 revocation authority.
2. A canonical server approved-device predicate usable by the authorization /
   RLS / read path (P-OD13 core gate).
3. Owner serve-side device-state transitions: approve / reject / revoke / lost.
4. Server-side proof-of-possession contract (public-key registration, challenge,
   single-use, verification) — SERVER HALF ONLY (S6 owns client/Keystore/DPAPI).
5. Corrected `accept_invitation` (auth.uid()-bound, token proof, expiry,
   single-use, revocation-aware).
6. Invitation token hardening (hash storage, single-use, expiry, binding).
7. Necessary RLS / server-authorization integration for the approved-device gate.
```

### F.1 Exact dependencies

```text
DEPENDENCY_S1  = MET  (server data model / migration foundation present)
DEPENDENCY_S2  = MET  (server entitlement + quota authority present)
DEPENDENCY_S3  = MET  (revocation / offline-grace authority present; composed, NOT duplicated)
S5 / S6 / S7 / S8 = NOT STARTED by S4; boundaries preserved (Section M).
```

### F.2 Explicit forbidden scope (S4 must NOT do)

```text
MIGRATION_00034_CREATED   = FALSE (governance session; and S4 impl must create ONLY 00034)
CLIENT ENROLLMENT UI      = S7
OWNER DEVICE UI           = S7
PLATFORM KEYPAIR / STORAGE= S6 (Android Keystore, Windows DPAPI, client proof impl)
CLIENT CACHE/TAMPER       = S8
CLIENT ENTITLEMENT CONSUMPTION = S5
LEGACY ED25519 RETIREMENT = S9
PAYMENT / BILLING PROVIDER= OUT_OF_SCOPE (never introduced into S4)
SMTP / EMAIL DELIVERY     = DEFERRED (see Section I8 decision)
```

---

## G. Current-State Matrix

Classification read-only from the current repository (HEAD `62af446`).
Classes: `ALREADY_IMPLEMENTED`, `PARTIAL`, `MISSING`, `SERVER_AUTHORITY`,
`INSECURE`, `RUNTIME_WIRED`, `CLIENT_ONLY`, `LEGACY`.

### G.1 devices

```text
CURRENT_COLUMNS = id, installation_id, shop_id, user_id, platform,
                  device_name, first_seen_at, last_seen_at, status, created_at,
                  public_key (S1), approved_by (S1), approved_at (S1),
                  revoked_by (S1), revoked_at (S1)
STATUS_CHECK    = ('ACTIVE', 'REVOKED', 'LOST', 'PENDING_APPROVAL')   (S1 extended)
PENDING_APPROVAL= PRESENT (S1 status value; not yet enforced by any gate)
PUBLIC_KEY      = PRESENT (S1 TEXT column; not yet registered/validated)
APPROVAL_META   = approved_by / approved_at / revoked_by / revoked_at (S1) — no reject/lost meta beyond status
USER_ASSOC      = user_id UUID FK auth.users (last user, nullable) — NOT the security authority
UNIQUENESS      = UNIQUE(installation_id, shop_id) (S3 register_device)
SHOP_ISOLATION  = FK shop_id; RLS shop_devices_isolation (ACTIVE-membership SELECT)
INSTALLATION_ID = UUID local (Side-effect: forgeable; S4 adds public-key/proof — no raw hardware ids)
```

Result: the historical plan condition (PENDING absent, public key absent) is
**no longer true**; S1 added them. S1/S2/S3 did **not** implement any
approval-gate or proof-of-possession logic — devices are still set `ACTIVE` by
`register_device` today. **S4 must convert ACTIVE enrollment into the governed
trusted-device gate.**

### G.2 invitations

```text
CURRENT_COLUMNS = id, shop_id, email, role, invited_by, status, created_at,
                  accepted_at, expires_at,
                  token_hash (S1), accepted_by (S1)
STATUS_CHECK    = ('PENDING','ACCEPTED','EXPIRED','REVOKED')
EXPIRES_AT      = PRESENT (NOT NULL)
TOKEN_HASH      = PRESENT (S1; never populated/validated — S4 owns)
SHOP/EMAIL/ROLE = PRESENT
ACCEPTED_AT     = PRESENT
SINGLE_USE      = NOT ENFORCED (S4 owns)
RLS             = shop_owner_invitations_select (SELECT-only, owner ACTIVE); INSERT/UPDATE/DELETE service-role only
```

Result: token storage exists (S1) but no issuance/validation; S4 owns token
creation/registration, hashing, single-use enforcement, expiry/revocation
server checks, and corrected acceptance.

### G.3 accept_invitation

```text
SIGNATURE   = accept_invitation(p_shop_id UUID, p_user_id UUID) RETURNS JSONB
SECURITY    = SECURITY DEFINER, SET search_path = public
CURRENT     = client-supplied p_user_id; looks up shop_members where
              shop_id=p_shop_id AND user_id=p_user_id AND status='INVITED';
              sets status='ACTIVE', joined_at=now(); updates invitation if the
              email matches auth.users(id=p_user_id) and status='PENDING'.
INSECURE SEAM= p_user_id is CLIENT-NOMINATED. No auth.uid() binding. No token
              proof. No expiry check. No single-use/revocation check on token.
              A caller can activate any pending membership it knows/guesses.
              This is the P-OD13 §H.4 membership-takeover seam.
S1/S2/S3 EFFECT = NONE — none of S1/S2/S3 modified accept_invitation.
```

S4 must correct this function. The accepted membership's user must be derived
from `auth.uid()` (the authenticated caller), never from a caller-nominated
`p_user_id`.

### G.4 require_shop_permission + authorization

```text
require_shop_permission(p_shop_id, p_permission_id) RETURNS TEXT
  - auth.uid() required
  - ACTIVE membership (role) required
  - license_required for non-view permissions (TRIAL/ACTIVE/PERPETUAL inline)
  - owner bypass -> returns role
  - non-owner -> check_effective_permission
check_effective_permission(p_shop_id, p_role, p_permission_id)  (SECURITY DEFINER)
get_effective_permissions(p_shop_id)                            (SECURITY DEFINER)
sync_user_permissions(p_shop_id)                                (SECURITY DEFINER)
```

**Where membership/role/shop_id/auth.uid() are checked today** (server):
- `require_shop_permission` checks auth + ACTIVE membership role + permission.
- Every business RPC that calls `require_shop_permission` inherits this.
- RLS on Shop business-data tables (`shops`, `shop_members`, `roles`,
  `role_permissions_cloud`, `devices`, `licenses`, `activations`, and Phase
  G/H business tables) uses the ACTIVE-membership `EXISTS(shop_members)` pattern.
- No surface today requires an **approved/trusted device**.

**Narrowest reliable SERVER-side seam for the trusted-device gate:** add a
single canonical approved-device predicate and enforce it inside
`require_shop_permission` (which fronts server RPC authorization) and, for the
RLS/read path, inside a SECURITY DEFINER approved-device predicate reusing the
existing ACTIVE-membership RLS pattern without recursion (Section I4). The
predicate is scoped by `shop_id` + `auth.uid()` + device identity, so it is not
a client-attested flag and cannot be bypassed by a modified client.

### G.5 device identity (client)

```text
app/lib/licensing/device_identity.dart  = fingerprint (SHA-256 of hardware
    components) via DeviceIdentityProvider; raw ids never sent; no per-install keypair.
app/lib/platform/device_identity_provider.dart = Windows MachineGuid/CPU/baseboard;
    Android SSAID; Sentinel fallback.
SECURE STORE  = secure_store*.dart / platform/secure_secret_store.dart (DPAPI /
    Keystore) already exist (reusable in S6).
```

S4 does NOT implement the keypair or client proof; it governs the server
contract that S6's client will consume.

### G.6 invite-employee Edge Function

```text
supabase/functions/invite-employee/index.ts
  - verifies caller is ACTIVE owner (via service-role membership read)
  - creates auth user with email_confirm:true and password = crypto.randomUUID() (temp password)
  - "Temporary password — employee will set their own" comment; NO delivery path
  - null user_id guard exists (added after prior bug reports)
  - creates shop_members (INVITED) and invitations (PENDING, expires 7 days)
  - invitation record is OPTIONAL (service failure logged but not surfaced)
  - TODO: send invitation email (future SMTP)
```

Historical Group B plan issues ("temporary password not delivered", "email_confirm:true",
"null user_id bug") are confirmed present in the current truth:
- temp password not delivered — CONFIRMED (random UUID, no delivery).
- email_confirm:true — CONFIRMED.
- null user_id bug — guard present at `index.ts:134`; lookup edge remains.

### G.7 S2 quota / S3 revocation composition surfaces

```text
S2: plans (trial 1/1, starter 2/3, professional 5/10, enterprise NULL/NULL);
    s2_resolve_entitled_license; s2_enforce_user_quota trigger; activate_device
    plan quota; verify_license_entitlement plan limits.
S3: licenses REVOKED; s3_revoke_license/device/membership; 16-col
    verify_license_entitlement; revocation-aware activate/register.
ADVISORY_LOCK_NAMESPACE = hashtextextended(p_shop_id::text, 0)  (shop-keyed)
```

Device quota today is enforced by `activate_device` against ACTIVE
device activations (S2/S3). See Section I10 for the S4 pending-device quota
decision.

---

## H. Residual Implementation Gap (S4)

```text
MISSING   — device trust gate: no approved/trusted-device predicate in authz/RLS/read path
MISSING   — no server transition to APPROVED/ACTIVE via owner approve
MISSING   — no reject / lost transitions distinct from S1/S3 current state handling
MISSING   — no proof-of-possession server contract (public-key registration, challenge, verification)
MISSING   — no corrected accept_invitation (auth.uid-bound + token + expiry)
MISSING   — no invitation token issuance/validation/single-use/revocation server path
MISSING   — RLS read path has no approved-device requirement where P-OD13 demands it
PARTIAL   — device public_key/approval metadata present (S1) but unused
PARTIAL   — invitation token_hash present (S1) but unused
```

---

## I. Exact Future Implementation Delta

### I.1 Authorized migration file

```text
NEXT_VALID_MIGRATION (at HEAD) = 20260820000034
MIGRATION_FILE =
  supabase/migrations/20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql
```

At entry, the highest committed migration is `20260820000033`. No `00034*`
file exists. `00034` is genuinely next. If real history at the S4
implementation session already contains an authorized migration beyond `00033`,
adapt to actual history and MUST NOT overwrite an existing authorized migration.

Migration must be ADDITIVE / IDEMPOTENT / REPLAY-SAFE / FORWARD-ONLY /
NON-DESTRUCTIVE, matching the S1/S2/S3 implementation doctrine (RLS delta as
governed in Section I4).

### I.2 Authorized test file

```text
TEST_FILE =
  supabase/tests/s4_device_trust_server_gate_invitation_hardening.test.sql
```

### I.3 Allowed modification paths (S4 implementation session ONLY)

```text
supabase/migrations/20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql
  (exactly one additive migration — the ONLY migration file S4 may create)

supabase/tests/s4_device_trust_server_gate_invitation_hardening.test.sql
  (exactly one new pgTAP test file)
```

The server surfaces governed below (S4 functions/predicates/challenge
tables/columns) must live inside the single `00034` migration. Business-data
RLS changes (Section I4) also live in `00034`.

### I.4 Forbidden paths (S4 implementation MUST NOT touch)

```text
supabase/migrations/20260820000000.sql .. 20260820000033.sql  (immutable)
supabase/tests/s1_server_data_model_foundation.test.sql  (immutable)
supabase/tests/s2_server_entitlement_quota_authority.test.sql  (immutable)
supabase/tests/s3_revocation_offline_grace_authority.test.sql  (immutable)
supabase/functions/**            (Edge Functions — invite-employee correction decision in Section I8)
app/lib/**                       (Flutter production source — S4 server-only)
supabase/config.toml             (no infra/config change)
supabase/seed.sql                (no seed change by S4)
.env* / secrets / keystores      (no secret mutation)
```

### I.5 Broad permissions NOT granted

The allowlist is the narrowest set above. No wildcard permissions like
`supabase/**`, `lib/**`, `test/**` are granted.

---

## J. S4 Security Contract

### J.1 Trusted-device state machine (I1)

**Decision: `ACTIVE == APPROVED/TRUSTED`.** Do NOT add a separate explicit
approval boolean. The existing `devices.status` lifecycle already distinguishes
`PENDING_APPROVAL`, `ACTIVE`, `REVOKED`, `LOST`, and S1 added the approval
metadata columns. Reusing `status` avoids duplicating authoritative state.

New state value added by S4: **`REJECTED`** (additive to the `devices_status_check`
CHECK, idempotent drop/re-add like S1/S3). The four tuned states:

```text
PENDING_APPROVAL  (already S1)
APPROVED / ACTIVE (same state; ACTIVE means trusted/approved)
REJECTED          (NEW, S4; terminal denied, distinct from REVOKED/LOST)
REVOKED           (S3 terminal denial — cascade path)
LOST              (S3/S1 — treated as revoked-level denial)
```

Transition table (each row: from → to, who, required current state, target,
audit, idempotency, device-slot quota consequence, authorization consequence):

```text
1. REGISTER (no prior) -> PENDING_APPROVAL
   who: any authenticated ACTIVE member of shop (the enrolling user via auth.uid())
   state: new installation_id in shop (upsert per S3 register_device, revocation-aware)
   target: PENDING_APPROVAL (NOT ACTIVE — key change from today's force-ACTIVE)
   audit: device_audit_log 'S4_REGISTER_PENDING'
   idempotent: registering same (installation_id,shop) that is PENDING -> no-op success
   quota: does NOT consume a licensed device slot (Section I10 decision)
   authorization: business-data NOT granted (still must be approved)

2. PENDING_APPROVAL -> ACTIVE (Owner approve)
   who: ACTIVE owner of the shop (auth.uid() + role='owner' server-verified)
   state: current PENDING_APPROVAL (or idempotent on an already-ACTIVE target)
   target: ACTIVE; approved_by=auth.uid(); approved_at=now()
   audit: device_audit_log 'S4_DEVICE_APPROVED'
   idempotent: yes (already ACTIVE = success no-op); approval race serialized via shop lock
   quota: consumes one licensed device slot (activation binding; quota check at approve)
   authorization: trusted device; permitted per membership + role + license

3. PENDING_APPROVAL / ACTIVE -> REJECTED (Owner reject)
   who: ACTIVE owner of the shop
   state: current PENDING_APPROVAL or ACTIVE may be rejected (owner discretion)
   target: REJECTED (approved_by NOT set; rejected records reason via audit)
   audit: device_audit_log 'S4_DEVICE_REJECTED'
   idempotent: yes (already REJECTED/REVOKED/LOST = safe no-op)
   quota: no active activation; frees no slot (it never consumed one if never approved)
   authorization: denied

4. ACTIVE -> REVOKED (Owner revoke) [compose with S3, do not duplicate]
   who: ACTIVE owner (or S3 cascade from license/membership/device revocation)
   state: current ACTIVE (S3's s3_revoke_device is the canonical revocation path)
   target: REVOKED; revoked_by=actor; revoked_at=now()
   audit: device_audit_log 'S3_DEVICE_REVOKE' (reuse S3; do NOT create S4_DEVICE_REVOKE)
   idempotent: yes (via S3)
   quota: frees the licensed slot (activation revoked)
   authorization: denied going forward

5. ACTIVE / PENDING_APPROVAL -> LOST (Owner mark lost)
   who: ACTIVE owner
   state: current ACTIVE or PENDING_APPROVAL (or idempotent on already LOST/REVOKED)
   target: LOST; audit 'S4_DEVICE_LOST'
   audit: device_audit_log 'S4_DEVICE_LOST'
   idempotent: yes
   quota: if it had an ACTIVE activation, activation revoked -> slot freed
   authorization: LOST treated as revoked-level denial (deny predicate)

6. ACTIVE -> REVOKED via membership/activation/license S3 cascade (no S4 new authority)
   Reuse s3_revoke_membership / s3_revoke_license / s3_revoke_device cascade.
```

**Idempotency/race rule:** every owner transition that can race with another
owner transition OR with activation/quota/revocation within the same shop MUST
acquire the shop-keyed advisory lock
`pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))` (Section J6).

### J.2 Owner authority (I2)

Future S4 functions (server-verified owner-only; never trust caller-supplied
role; use auth.uid() + ACTIVE owner membership + shop_id):

```text
s4_approve_device(p_shop_id UUID, p_device_id UUID, p_reason TEXT DEFAULT NULL) RETURNS BOOLEAN
s4_reject_device(p_shop_id UUID, p_device_id UUID, p_reason TEXT DEFAULT NULL) RETURNS BOOLEAN
s4_mark_device_lost(p_shop_id UUID, p_device_id UUID, p_reason TEXT DEFAULT NULL) RETURNS BOOLEAN
s4_list_devices(p_shop_id UUID) RETURNS TABLE(...)   -- owner/member managed surface, tenant-scoped
```

Revocation (`ACTIVE -> REVOKED`) reuses existing `s3_revoke_device`; S4 does
NOT create a competing `s4_revoke_device`. All owner RPCs:
- require authenticated caller,
- resolve shop membership via `auth.uid()`,
- require `role='owner'` AND `status='ACTIVE'` in the target `shop_id`,
- scope every entity lookup by `shop_id` (cross-tenant fails closed with a
  deterministic `S4_CROSS_SHOP_DENIED`-style guard),
- audit every transition into `device_audit_log`,
- serialize via the shop-keyed advisory lock.

### J.3 Device gate — canonical approved/trusted-device predicate (I3)

One canonical predicate, e.g.:

```text
s4_device_is_approved(p_shop_id UUID, p_device_id UUID) RETURNS BOOLEAN  (SECURITY DEFINER)
  TRUE iff a device exists for p_shop_id with id = p_device_id
        AND status = 'ACTIVE'            (approved/trusted)
        AND (optionally) p_device_id belongs to the current device/session
```

or, where the authorization path identifies the caller, a caller-scoped form
resolving the device used by `auth.uid()` in `p_shop_id`. The exact shape is an
implementation detail, but it MUST be a single server-side function reused
consistently by:
- `require_shop_permission` (server RPC authorization), and
- any S4-gated RLS predicate / read path (Section I4),
so that a modified client cannot bypass the gate by choosing a friendlier check.

Gate semantics (fail-closed):
- Shop scope: `shop_id` scoped (never global).
- Auth scope: derived from `auth.uid()` (server identity), never client-attested.
- Device identity: resolved from the served device act as established by S6's
  future proof-of-possession binding (S4 reserves the server columns/contract;
  S6 binds client identity) — see Section J5.
- Device approval: `status = 'ACTIVE'` required for business-data access that
  P-OD13 gates.
- Membership state: caller must have ACTIVE membership.
- License/revocation: S3 revocation (license/membership/device) overrides
  device approval (Section J9).

**P-OD13 core law:** authenticated identity + membership + role + license/
activation are NOT sufficient alone; server approved-device state is MANDATORY
for business-data access. `require_shop_permission` must therefore fail closed
for a caller whose served device is not `ACTIVE` (or treat as not-trusted),
across the business RPC surface, and the read/RLS path must be covered per
Section I4.

### J.4 RLS / authorization integration (I4) and change sets

#### Approached scope decision

Consistent with S3 (`RLS_POLICY_DELTA = ZERO` at function level) but S4's
master-plan mandate explicitly permits/requires an approved-device predicate in
the server authorization/read path. S4's RLS delta is therefore **non-zero but
narrow and additive**.

#### RLS_CHANGE_SET (the policies/helpers S4 intends to change, and why)

```text
1. require_shop_permission (SECURITY DEFINER helper, not an RLS policy):
   Add approved-device gate (call s4_device_is_approved) so every server RPC
   that requires a shop permission also requires a trusted device.
   WHY: this is the narrowest reliable server-side seam; it fronts all business
   write RPCs and is the natural P-OD13 enforcement point.

2. A new SECURITY DEFINER predicate e.g.
   s4_shop_approved_device_access(p_shop_id UUID) as the read-path gate,
   reusing the EXISTING ACTIVE-membership EXISTS(shop_members) pattern and adding
   `AND devices of this auth.uid() in this shop are ACTIVE-approved`.
   WHY: read protection for CASE 2/3/5/19 (a new/unapproved device must not
   read business data). Must be added to the business-data table RLS USING
   clauses that P-OD13 requires be gated.

3. Any business-data table whose read is gated by the approved-device predicate:
   add an additive RLS USING condition (OR-preserving the existing shop
   isolation as the base, then requiring approval) — EXACT list to be finalized
   by the S4 implementation after enumerating every RLS policy over Shop
   business-data tables, per the narrowest-evidence principle.
```

**The exact set of business tables to gate** in `RLS_CHANGE_SET` must be
determined by enumerating the RLS policies defined since `20260820000010`
(Phase G/H cloud-data foundation `00025..00030` plus base `00010`) and the
write RPCs that call `require_shop_permission`. The governance artifact binds
the following invariants (below) and requires the implementation to produce the
full policy-by-policy list inside `00034` and its pgTAP.

#### RLS_NON_CHANGE_SET (must remain byte/semantically unchanged)

```text
plans_select                          (S1; global reference metadata)
shop_device_audit_isolation           (S1; device_audit_log)
shop_isolation / shop_member_isolation / shop_roles_isolation /
shop_role_permissions_isolation / shop_devices_isolation /
shop_licenses_isolation / shop_activations_isolation  (00010)
shop_overrides_isolation / shop_audit_isolation (00024)
all Phase G/H RLS that are not business-data-read-approved-device surfaces
Invitation policies except as the corrected accept path requires (00021/00022)
```

None of the `NON_CHANGE_SET` policies may be deleted, renamed, or semantically
weakened.

#### Tenant-isolation / recursion / search_path guarantees

```text
- Retain shop_id tenant isolation on every gated table.
- NO recursive RLS: the approved-device predicate and require_shop_permission
  (SECURITY DEFINER) must use direct queries / an explicit helper that resolves
  shop membership WITHOUT introducing a policy that queries a table whose RLS
  itself consults shop_members in a cycle. Mitigate by resolving the caller's
  ACTIVE membership + approved device in the SECURITY DEFINER helper (which runs
  as owner and is not itself subject to the row's RLS), mirroring the existing
  require_shop_permission / check_effective_permission pattern (which already
  query shop_members inside SECURITY DEFINER without recursion).
- Avoid introducing policy recursion through shop_members: the predicate must
  NOT query shop_members with a policy that in turn requires the predicate.
- SECURITY DEFINER helpers MUST set a controlled search_path = public (existing
  convention) to prevent search-path hijacking.
- Authenticated identity alone is insufficient; membership alone is
  insufficient; device approval is mandatory where P-OD13 requires business-data
  access.
- Cross-shop access remains impossible (every query scoped by shop_id).
- Server RPC authorization must not depend solely on RLS: require_shop_permission
  is the server RPC gate; RLS is defense-in-depth for the read path.
- Do NOT broaden RLS beyond what source evidence requires: only the
  business-data surfaces P-OD13 gates change.
```

### J.5 Proof of possession — SERVER HALF ONLY (I5)

S4 precedes S6. S4 governs ONLY the server contract S6's client will satisfy.
S6 owns Android Keystore / Windows DPAPI / client key generation and storage /
client proof implementation.

```text
DEVICE PUBLIC-KEY REPRESENTATION:
  devices.public_key (S1, TEXT) holds the device PUBLIC key only. NEVER private
  keys/secret material. Format: PEM or base64-encoded public key, selected by
  the algorithm; bind to installation_id and shop_id.

KEY REGISTRATION RULES:
  Server endpoint/function e.g. s4_register_device_key(p_shop_id, p_installation_id,
  p_public_key, ...) that (a) requires auth.uid() + ACTIVE membership,
  (b) re-uses register_device enrollment to PENDING_APPROVAL, (c) stores the
  public key, (d) does NOT grant ACTIVE/trusted status by itself — approval +
  proof are required.

CHALLENGE CREATION:
  Additive challenge surface (e.g. s4_create_challenge(p_shop_id, p_device_id)
  -> challenge token/nonce). Server-random, cryptographically strong,
  single-use, expiring (short TTL, e.g. minutes), bound server-side to
  {shop_id, device_id, auth.uid()} and a challenge row (or a signed/session-
  bound assertion). Never reused.

CHALLENGE EXPIRY:
  Server checks challenge expiry at verification; expired -> rejected.

SINGLE-USE / REPLAY:
  Server consumes (invalidates) the challenge on first verification; reuse of
  the same challenge is rejected. Replay-resistance is server-side.

SIGNATURE/PROOF VERIFICATION:
  Server verifies the client-signed (or otherwise bound) proof over
  {challenge, device, shop, user} using the stored public key. Verify with the
  platform crypto library; never place private-key trust server-side.

BINDING:
  proof bound to shop + authenticated user + device + challenge + server
  timestamp; cross-tenant / cross-user binding fails closed.

SERVER TIMESTAMPS:
  use now(); record created_at / verified_at in the challenge/audit surfaces.

ROTATION / RE-ENROLLMENT:
  Rotation = re-registration governed as a NEW enrollment -> PENDING ->
  approval (Section J2), preventing a lost/compromised key from silently
  rotating into trust (ties to S3 revocation and CASE 11/15).

NEVER:
  store private keys server-side; store raw unnecessary hardware-sensitive
  identifiers; claim perfect anti-tamper. The security boundary is the server
  authorization gate (a modified client cannot bypass server checks).

ALGORITHM:
  The master plan (P-OD11 in PHASE_P_OWNER_DECISIONS.md) commits Ed25519 for
  the platform identity path. S5/S6 compatibility: S4's public-key column and
  challenge/verify contract must be compatible with an Ed25519 public key.
  S4 must not silently invent a divergent commercial/security requirement; use
  Ed25519 as the compatible default consistent with committed authority unless
  a committed source overrides it. The exact verification primitive lives in
  S6's platform layer; S4's server simply stores the public key and verifies
  the proof using the platform cryptographic validation available server-side.
```

### J.6 Concurrency / locking contract (I10 tail, J)

Same shop-keyed namespace used by S2/S3:
`pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))`.

Required serialization for:
```text
approve vs revoke
approve vs lost
approve vs membership revocation (S3)
approve vs license revocation (S3)
approve vs device-quota consumption (S2 activate_device)
reject vs approve
invitation accept vs invitation revoke
invitation accept vs expiry
two simultaneous invitation accepts
proof challenge replay / concurrent reuse
```

No global lock is introduced. Cross-shop operations remain independent (each
uses its own shop key). Real two-session proof versus deterministic pgTAP is
distinguished in Section K.

### J.7 S2 quota composition (I10)

**Explicit decision:**
```text
A PENDING_APPROVAL (unapproved) device does NOT consume a licensed device slot.
A device consumes a licensed slot only once it is APPROVED (ACTIVE) and has an
ACTIVE activation, consistent with S2's activate_device counting
activations of ACTIVE devices.
```

Rationale:
- `activate_device`/`verify_license_entitlement` count only ACTIVE devices'
  ACTIVE activations; a PENDING device has no activation.
- Enrolling many pending devices must not exhaust quota / allow denial-of-
  service via slot-capture before approval.
- Approval (step 2) MUST re-check quota (device_limit) at approve time, so an
  Owner cannot approve beyond plan capacity.
- Approval must serialize with S2/S3 operations sharing the shop lock.

### J.8 Invitation hardening — corrected accept_invitation (I6)

Future corrected acceptance (replacing `accept_invitation` in `00034`) must:

```text
- derive the accepted membership user from auth.uid() (authenticated caller);
  NEVER accept a client-supplied p_user_id as the security authority.
- bind: auth.uid() + invitation(id/token) + shop_id + role + recipient
  identity/email + token proof + expiry + (revocation) state.
- verify the caller matches the invitation's intended recipient (email bound,
  where the invite specified one) and the INVITED membership targets auth.uid().
- verify the token proof server-side (compare against invitations.token_hash
  storage; never store plaintext).
- enforce expiry (expires_at must be in the future).
- enforce single-use (upon success mark the token consumed / invitation
  ACCEPTED; subsequent reuse rejected).
- enforce revocation state (REVOKED / EXPIRED invitation unusable).
- set shop_members.status = 'ACTIVE' + joined_at, invitations.status =
  'ACCEPTED' + accepted_at = now() + accepted_by = auth.uid() (S1 column).
- run under the shop-keyed advisory lock for the shop, so two simultaneous
  accepts of the same invitation cannot double-activate (only one wins; the
  other fails closed with a deterministic single-use error).
- fail closed on ANY mismatch (wrong shop/role/email/expired/revoked/used).
```

Return shape and error codes are implementation detail; determinism and
fail-closed are mandatory.

### J.9 Invitation token (I7)

```text
Static shared Shop Code is NOT an authorization factor.
If a pairing/invitation token is used (recommended, server-issued):
  - cryptographically random (e.g., >= 128-bit entropy)
  - short-lived (server-set expiry; S1 invitations.expires_at)
  - single-use (consumed on acceptance; replay rejected)
  - stored server-side ONLY as a hash (invitations.token_hash, S1). Never
    plaintext token persisted.
  - bound to: invitation + shop_id + intended recipient identity/email (where
    authority requires) + intended role
  - revocable (REVOKED invitation -> token unusable)
  - expiry checked server-side
  - unusable after acceptance
  - replay rejected
Token possession alone MUST NOT replace authentication, membership, device
approval, or server authorization.
The invite flow that issues the token is decided in Section I8 (Edge Function
boundary).
```

### J.10 Invitation token edge function boundary (I8)

Current truth (Section G.6): invite-employee leaves temp password undelivered,
uses email_confirm:true, has an (added) null-user-id guard, and does not create
or deliver a token.

**DECISION — invite-employee Edge Function correction is DEFERRED, NOT S4.**
Rationale:
- S4's authoritative invitation-hardening requirement is the **server-side
  corrected accept_invitation + token validation** (client identity binding,
  token proof, expiry, single-use). That is purely a DB migration concern,
  implementable and testable within `00034` without touching the Edge Function.
- The Edge Function's temp-password/email-delivery issue is an SMTP/delivery
  concern tied to how owners create invitations (and a future secure accept
  flow). It interacts with S6 (client identity) and the future secure
  employee-onboarding UX (S5/S7), and would silently expand S4 into an
  SMTP/external-provider project, which the session contract forbids (payment
  provider stays out of scope).
- Therefore: invitation **schema + token-hash + corrected accept_invitation
  server function** are IN_S4 (in `00034`); the **Edge Function
  (`invite-employee/index.ts`) is DEFERRED** and stays byte-unchanged for S4.
- Consequence to record truthfully: until the deferred Edge Function is
  corrected, an owner-invited employee's `token_hash` will be NULL and
  `invitations.expires_at` set by the current Edge Function; the corrected
  server accept path must therefore fail closed (no token -> no acceptance)
  until the Edge Function is updated in a later slice, OR accept a governed
  transition path — the S4 implementation must state which and keep it
  fail-closed and non-regressing.

This decision is based only on the authoritative S4 invitation-hardening
requirement and dependency structure; it does NOT absorb SMTP/payment/external-
provider work.

### J.11 Revocation compatibility with S3 (I9)

S4 composes with, and does not duplicate, S3:

```text
- ACTIVE -> REVOKED : REUSE s3_revoke_device (and s3_revoke_membership /
  s3_revoke_license cascades). DO NOT create a competing s4_revoke_device.
- reject (-> REJECTED) and lost (-> LOST) are S4-owned terminal transitions
  NOT currently covered by S3; they are additive, not conflicting.
- S3's revoked-device denial is the canonical revocation model; S4's
  approved-device predicate must treat REVOKED and LOST and REJECTED as
  not-trusted (denied).
```

### J.12 Employee invite / membership / license authority (defense-in-depth)

The corrected server gate requires the full chain (P-OD13):
```text
auth.uid() defined                      (authentication)
ACTIVE membership in shop               (membership)
role/permission (require_shop_permission) (authorization)
approved/ACTIVE device                  (device trust – S4)
entitled license / activation           (license/activation – S2/S3)
server-side tenant authorization        (shop_id scoping throughout)
```
A modified client cannot bypass the server gate.

---

## K. Test Contract (exact S4 matrix)

### K.1 pgTAP test file

```text
TEST_FILE = supabase/tests/s4_device_trust_server_gate_invitation_hardening.test.sql
```

### K.2 Governed scenarios and expected assertion mapping

Each row states the invariant and how many pgTAP assertions the S4
implementation must produce for it. The count is an EXPLICIT scenario→assertion
mapping the implementation MUST reconcile before commit (avoids the S3
plan-count mismatch, Section P.4). "real two-session" cases require the
advisory-lock concurrency proof; all others are deterministic pgTAP.

| # | Governed scenario | Proof type | Assertion plan |
|---|---|---|---|
| 1 | New employee device is untrusted by default (ends PENDING_APPROVAL, not ACTIVE) | deterministic | >= 2 (status + not-approved) |
| 2 | Authenticated employee on unapproved device denied business data (read) | deterministic (RLS/RPC deny) | >= 2 |
| 3 | Approved device obtains permitted access | deterministic | >= 2 |
| 4 | Approval is Owner-only (employee/other rejected) | deterministic | >= 1 |
| 5 | Reject is Owner-only | deterministic | >= 1 |
| 6 | Revoke / lost is Owner-only | deterministic | >= 2 |
| 7 | Cross-shop device approval denied | deterministic | >= 1 |
| 8 | Revoked membership cannot use previously approved device | deterministic | >= 1 |
| 9 | Revoked device remains denied | deterministic | >= 1 |
| 10 | Lost device denied | deterministic | >= 1 |
| 11 | Revoked/lost device cannot silently re-register as trusted | deterministic | >= 2 |
| 12 | Invitation caller cannot nominate another p_user_id (auth.uid-bound) | deterministic | >= 2 |
| 13 | Expired invitation denied | deterministic | >= 1 |
| 14 | Revoked invitation denied | deterministic | >= 1 |
| 15 | Invalid token denied | deterministic | >= 1 |
| 16 | Replayed token denied | deterministic | >= 1 |
| 17 | Invitation token hash (not plaintext) is persisted | deterministic | >= 2 |
| 18 | Successful acceptance binds authenticated caller | deterministic | >= 2 |
| 19 | Accepted invitation is single-use | deterministic | >= 2 |
| 20 | Proof challenge expiry | deterministic | >= 1 |
| 21 | Proof challenge replay rejection | deterministic | >= 2 |
| 22 | Invalid proof rejection | deterministic | >= 1 |
| 23 | Proof bound to correct user/device/shop | deterministic | >= 2 |
| 24 | Approval does not bypass S2 quota | deterministic | >= 2 |
| 25 | S3 license revocation overrides device approval | deterministic | >= 2 |
| 26 | S3 membership revocation overrides device approval | deterministic | >= 2 |
| 27 | Same-shop concurrency serialization (approve vs revoke; two accepts; challenge reuse) | real two-session advisory-lock proof | >= 2 |
| 28 | Cross-shop operations do not globally block | real two-session (concurrent different shops) OR deterministic | >= 1 |
| 29 | RLS tenant isolation remains intact | deterministic | >= 2 |
| 30 | Previously authorized server operations fail for unapproved device where P-OD13 requires the gate | deterministic (require_shop_permission) | >= 2 |

```
GOVERNED_SCENARIOS            = 30
EXPECTED_PG_TAP_ASSERTIONS    = SUM of the per-scenario minimums above, PLUS
                                migration/base assertions and the regression
                                references; the implementation MUST reconcile
                                the exact running total against the real test
                                file before commit (the S3 plan-count mismatch,
                                Section P.4, is explicitly NOT repeated).
```

### K.3 Regression (S1 + S2 + S3 must remain green)

```text
S1_PG_TAP            = committed 46/46 (must remain)
S2_PG_TAP            = committed 88/88 (must remain)
S3_PG_TAP            = committed 22 planned / actual > (Section P.4 note) (must remain)
S4_PG_TAP            = K.2 above (must pass)
COMBINED_GOVERNED    = S1 + S2 + S3 + S4 (must pass)
FLUTTER_REGRESSION   = must remain green (S4 changes no client code)
MIGRATION_REPLAY/RESET = 00000..00034 replay/idempotence must pass
RLS_TENANT_ISOLATION_REGRESSION = must remain
```

### K.4 Pre-existing unrelated failures (not S4 defects)

```text
cloud_stock_adjustments    = pre-existing (column "oid" does not exist)
rls_shop_members_recursion = pre-existing (information_schema.policies does not exist)
```

These are NOT S4 defects and MUST NOT be fixed by the S4 implementation unless
the exact committed S4 authority explicitly includes them — which it does not.
Record them as pre-existing; only re-verify if S4's pgTAP run surfaces them.

### K.5 P-OD13 CASE 1–20 mapping (S4 ownership)

S4 claims its CASE slices and explicitly does NOT claim the full matrix (final
convergence = S10).

| # | Case | S4 classification (with S1/S2/S3 already in place) |
|---|---|---|
| 1 | employee + approved device -> only Shop A data | COVERED_BY_S4 (gate allows; tenant+role+device+license) |
| 2 | new unapproved device denied | COVERED_BY_S4 |
| 3 | stolen creds from another device | COVERED_BY_S4 (approval gate) |
| 4 | shop_id change / cross-tenant | COVERED_BY_S4 (tenant-scoped predicate) |
| 5 | direct API without device proof | COVERED_BY_S4 (server gate, not UI) |
| 6 | owner approves pending | COVERED_BY_S4 |
| 7 | owner rejects | COVERED_BY_S4 |
| 8 | owner revokes ACTIVE | COVERED_BY_S3 (composed; not duplicated by S4) |
| 9 | owner marks LOST | COVERED_BY_S4 (lost) |
| 10 | membership suspended/revoked | COVERED_BY_S3 (composed) |
| 11 | expired invitation | COVERED_BY_S4 (corrected accept) |
| 12 | used-token replay | COVERED_BY_S4 |
| 13 | shop-A token vs shop B | COVERED_BY_S4 (binding) |
| 14 | second legitimate device | PARTIAL (S2 quota + S4 approval) |
| 15 | reinstall -> re-approval | PARTIAL (S4 enrollment -> PENDING; S6 identity regen; final S10) |
| 16 | approved device offline | DEFERRED (S5/S8 grace convergence) |
| 17 | unknown first-time device offline | COVERED_BY_S4 (server never grants without approval) — but offline client enforcement S8 |
| 18 | salesOnly cannot gain higher role | NOT_APPLICABLE_TO_S4 (role unchanged by approval; RBAC intact) |
| 19 | modified client / direct RLS | COVERED_BY_S4 (server gate in authz + RLS read path) |
| 20 | no reusable password | DEFERRED (invite Edge Function / onboarding later slice) |

S4 explicitly claims full coverage of cases 1–7, 9, 11–13, 17, 19; it composes
with S3 for 8, 10; it is partial/deferred for 14, 15, 16, 18, 20. Final
convergence of the full 1–20 matrix belongs to S10.

---

## L. Regression / Immutability Gates

### L.1 Predecessor immutability

```text
S1_MIGRATION_EDITED  = FALSE   (00031 unchanged)
S1_TEST_EDITED       = FALSE
S2_MIGRATION_EDITED  = FALSE   (00032 unchanged)
S2_TEST_EDITED       = FALSE
S3_MIGRATION_EDITED  = FALSE   (00033 unchanged)
S3_TEST_EDITED       = FALSE
MIGRATION_00000..00030_EDITED = FALSE
```

### L.2 Sourcing convention for S4 implementation

The S4 implementation must derive its full content from the committed source,
not from this governance summary alone. The migration and test files must be
written against the actual committed schema/function reality (this document
records it; implementations re-verify).

### L.3 Forbidden scope (S4 implementation)

```text
S5_STARTED  = NO (client entitlement integration)
S6_STARTED  = NO (platform secure device identity / Keystore / DPAPI / client proof)
S7_STARTED  = NO (Owner device management UI)
S8_STARTED  = NO (tamper/cache/clock enforcement)
S9_STARTED  = NO (legacy Ed25519 retirement)
S10_STARTED = NO (test/security convergence)
S11_STARTED = NO (deployment/verification)
S12_STARTED = NO (Group B closeout)
GROUP_C_STARTED = NO
GROUP_D_STARTED = NO
PRODUCTION_MUTATION  = NO
PAYMENT_PROVIDER_WORK = NO
LEGACY_ORIGIN_CONTACTED = NO
```

---

## M. Implementation Boundary S4 / S5 / S6 / S7 / S8 (preserve master-plan decomposition)

```text
S4 OWNS: server device-trust model; server approved-device authorization gate;
         server invitation hardening; server proof-of-possession contract;
         necessary RLS/server authz integration; Owner server-side device-state
         transitions.
S5 OWNS: client entitlement integration; cache/model/repository consumption.
S6 OWNS: per-install platform secure keypair; Android Keystore; Windows DPAPI;
         client proof-of-possession implementation.
S7 OWNS: Owner device-management UI; pending/approve/reject/revoke/lost
         workflows; employee<->device UI.
S8 OWNS: tamper/cache/clock enforcement convergence.
```

S4 does NOT absorb S5/S6/S7/S8 work. In particular S4 governs the server
contact for proof-of-possession but leaves the client keypair and platform
storage (S6) and all UI (S7) and tamper/cache/clock (S8) to their slices.

---

## N. Governance Artifact Requirements Checklist (session contract N.)

```text
1.  session identity                         = Section A
2.  repository identity                     = Section B
3.  entry/recovery classification           = Section C
4.  exact authority register                = Section D
5.  predecessor S1/S2/S3 bindings           = Section E
6.  current-state forensic findings         = Section G
7.  S4 exact scope                         = Section F
8.  explicit forbidden scope               = Section F.2 / L.3
9.  schema delta contract                  = Section J + I.1
10. function/RPC contract                  = Section J
11. invitation/token contract              = Section J.8 / J.9 / J.10
12. trusted-device state machine           = Section J.1
13. proof-of-possession server contract    = Section J.5
14. RLS change set                         = Section J.4
15. RLS non-change set                     = Section J.4
16. tenant-isolation guarantees            = Section J.4
17. concurrency/locking contract           = Section J.6
18. S2/S3 composition contract             = Section J.7 / J.11
19. implementation file allowlist (future) = Section I
20. migration-number gate                  = Section I.1 / P
21. exact pgTAP scenario matrix            = Section K
22. regression gates                       = Section K.3 / L
23. expected implementation evidence       = Section O
24. success/failure criteria               = Section O
25. implementation authorization statement = Section R
26. explicit stop before implementation    = Section T
```

---

## O. Expected Implementation Evidence (future S4 implementation session)

```text
- ONE additive migration 20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql
- ONE pgTAP test file with the reconciled scenario matrix (K.2) and a stated
  assertion total matching the real file (no S3 plan-count mismatch)
- proof that S1 pgTAP (46), S2 pgTAP (88), S3 pgTAP remain green
- proof that RLS tenant isolation regression remains green
- proof that the approved-device gate denies the unapproved-device business
  read/write (P-OD13), and that a modified client cannot bypass it
- proof that no S1/S2/S3 file, no Edge Function, no Flutter source, no config,
  no seed changed
- migration replay/reset passes on 00000..00034
```

## P. Migration Number Gate (session-relevant)

```text
HIGHEST_COMMITTED_MIGRATION_AT_ENTRY = 20260820000033
NEXT_VALID_MIGRATION                 = 20260820000034
00034_EXISTS_AT_ENTRY                = FALSE
CONTRADICTION                        = NONE
FUTURE S4 IMPLEMENTATION MIGRATION   = 20260820000034 (created ONLY by the future
                                     S4 implementation session, NOT by this governance)
```

No migration `00034` was created by this governance session. This document does
not reserve it by writing an empty migration.

### P.4 (S3 plan-count learning — governance-learning note)

S3 governance committed a planned assertion count (22) that differed from the
actual S3 test file assertion-call count (25 counted at entry). This is the
"S3 plan-count mistake" the S4 contract explicitly must not repeat: the S4
test matrix (Section K.2) requires scenario→assertion mapping and mandates
reconciliation of the final assertion total against the real test file before
commit.

---

## Q. Forbidden Scope (this governance session)

```text
MIGRATION_CREATED        = FALSE
DB_SCHEMA_CHANGED        = FALSE
RLS_CHANGED              = FALSE
FLUTTER_CHANGED          = FALSE
EDGE_FUNCTION_CHANGED    = FALSE
CONFIG_CHANGED           = FALSE
SEED_CHANGED             = FALSE
S1_CHANGED               = FALSE
S2_CHANGED               = FALSE
S3_CHANGED               = FALSE
S4_IMPLEMENTATION        = NOT_STARTED
S5_STARTED               = FALSE
S6_STARTED               = FALSE
S7_STARTED               = FALSE
S8_STARTED               = FALSE
GROUP_C_STARTED          = FALSE
GROUP_D_STARTED          = FALSE
PRODUCTION_MUTATION      = FALSE
PAYMENT_PROVIDER_WORK    = FALSE
LEGACY_ORIGIN_CONTACTED  = FALSE
```

---

## R. Implementation Entry Contract

The future S4 implementation session may run ONLY when ALL of the following hold:

```text
- this S4 governance artifact is committed and remote-locked (authority present)
- S1 is unchanged and remote-locked (334d1ad)
- S2 is unchanged and remote-locked (85e4315)
- S3 is unchanged and remote-locked (62af446)
- repository is clean in the governed sense and no active Git operation
- the next authorized migration (00034 at HEAD, or adapted to real history) is confirmed
- the implementer stays within the ALLOWED paths (migration + test ONLY, Section I.3)
- separate owner authorization for the S4 IMPLEMENTATION session exists
  (governance alone does not authorize implementation)
```

This document is an implementation GOVERNANCE contract for the NEXT session
only. It does not authorize, and does not begin, S4 implementation now.

---

## S. Commit / Push Contract (this governance session)

```text
COMMIT_STYLE     = normal commit (no amend, no rebase, no squash)
PUSH_MODE        = NORMAL_FAST_FORWARD_ONLY
FORCE_PUSH       = NEVER
FORCE_WITH_LEASE = NEVER
REMOTE           = github ONLY (origin is sacred read-only)
HISTORY_REWRITE  = NEVER
RECOMMENDED_MESSAGE = docs: govern Group B S4 device trust and invitation hardening
EXPECTED_PARENT  = 62af44695e664722d1ccabf5816f55678d1e049a
```

---

## T. Mandatory Stop

```text
STOP AFTER S4 GOVERNANCE REMOTE LOCK.
DO NOT IMPLEMENT S4 IN THIS SESSION.
DO NOT START S5.
DO NOT START S6.
DO NOT START S7.
DO NOT START S8.
DO NOT START S9.
DO NOT START S10.
DO NOT START S11.
DO NOT START S12.
DO NOT START GROUP C.
DO NOT START GROUP D.
```

---

## U. Non-Actions Ledger (this governance session)

```text
S4_IMPLEMENTATION_STARTED    = FALSE
SQL_MIGRATION_CREATED        = FALSE   (no 00034; no empty reservation)
PRODUCTION_SOURCE_CHANGED    = FALSE
EDGE_FUNCTION_CHANGED        = FALSE
RLS_CHANGED                  = FALSE
AUTH_CHANGED                 = FALSE
DEVICE_LOGIC_CHANGED         = FALSE
INVITATION_LOGIC_CHANGED     = FALSE
LICENSE_IMPL_CHANGED         = FALSE
TESTS_CHANGED_AS_IMPL        = FALSE
CONFIGURATION_CHANGED        = FALSE
PRODUCTION_DEPLOYED          = FALSE
S1_MIGRATION_EDITED          = FALSE
S1_TEST_EDITED               = FALSE
S2_MIGRATION_EDITED          = FALSE
S2_TEST_EDITED               = FALSE
S3_MIGRATION_EDITED          = FALSE
S3_TEST_EDITED               = FALSE
MIGRATION_00000..00033_EDITED = FALSE
GROUP_B_OTHER_SLICES_STARTED = FALSE
GROUP_C_STARTED              = FALSE
GROUP_D_ADVANCED             = FALSE
SYNC_DRAIN_CHANGED           = FALSE
ANDROID_BUILD / AAB / PLAY   = FALSE
LEGACY_ORIGIN_MUTATED        = FALSE
LEGACY_ORIGIN_CONTACTED      = FALSE
SACRED_EVIDENCE_MUTATED      = FALSE
UNRELATED_STASH_MUTATED      = FALSE
FORCE_PUSH_USED              = FALSE
FORCE_WITH_LEASE_USED        = FALSE
REBASE_USED                  = FALSE
AMEND_USED                   = FALSE
HARD_RESET_USED              = FALSE
GIT_CLEAN_USED               = FALSE
```

---

## V. Successor Boundary

Successful completion of THIS session means only:

```text
S4_IMPLEMENTATION_GOVERNANCE = CREATED + COMMITTED + NORMAL_FAST_FORWARD_PUSHED + REMOTE-LOCKED
S4_IMPLEMENTATION            = NOT_STARTED
PRODUCTION                   = UNCHANGED
S5                           = NOT_STARTED
S6                           = NOT_STARTED
S7                           = NOT_STARTED
S8                           = NOT_STARTED
GROUP C                      = NOT_STARTED
GROUP D                      = DEFERRED
```

The terminal state is:

```text
S4 GOVERNANCE          = CREATED / COMMITTED / NORMAL FAST-FORWARD PUSHED / REMOTE-LOCKED
S4 IMPLEMENTATION      = NOT STARTED
PRODUCTION             = UNCHANGED
S5                     = NOT STARTED
GROUP C                = NOT STARTED
GROUP D                = DEFERRED
```

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION = CASE_A_FRESH
ENTRY_HEAD           = 62af44695e664722d1ccabf5816f55678d1e049a
ENTRY_PARENT         = 7d05313cf1a50765ad6721b264a7b05e51263ffd
DIFF PROFILE         = 1 added file (this artifact), 0 modified, 0 deleted
SACRED EVIDENCE      = preserved (untracked; never staged/modified)
COMMIT               = <set at commit>
AHEAD / BEHIND       = (1/0 after commit, pre-push)
```
