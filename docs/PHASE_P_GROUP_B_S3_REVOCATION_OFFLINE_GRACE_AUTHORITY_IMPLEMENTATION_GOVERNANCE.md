# PHASE P — GROUP B S3 REVOCATION / OFFLINE-GRACE AUTHORITY — IMPLEMENTATION GOVERNANCE

```text
SESSION =
PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED

TARGET_SLICE       = S3_REVOCATION_OFFLINE_GRACE_AUTHORITY
IMPLEMENTATION     = FALSE
MIGRATION_33_CREATED = FALSE
SOURCE_CHANGED     = FALSE
DEPLOY             = FALSE
PRODUCTION_MUTATED = FALSE
GROUP_D_ADVANCED   = FALSE
```

THIS DOCUMENT GOVERNS A FUTURE S3 IMPLEMENTATION.
IT DOES NOT IMPLEMENT S3.

THIS SESSION CREATED ONLY THIS GOVERNANCE ARTIFACT. IT DID NOT IMPLEMENT S3.
IT DID NOT CREATE MIGRATION `20260820000033`. IT DID NOT EDIT SQL, Dart,
Flutter, Edge Functions, RLS, RPCs, tests, or Supabase production. It did not
edit S1 (`334d1ad`), S2 (`85e4315`), migration `00031`, migration `00032`,
or migrations `00000..00030`.

---

## A. Session Identity

```text
SESSION                = PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
MODE                   = SINGLE_SLICE_OWNER_GATED_GOVERNANCE_ONLY_FAIL_CLOSED
TARGET_UNIT            = Group B S3 - Revocation / offline-grace authority
EXPECTED_SUCCESS_TOKEN = PASS_PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
IMPLEMENTATION         = FALSE
AUTHORIZED_OUTPUT      = ONE ADDITIVE S3 IMPLEMENTATION GOVERNANCE ARTIFACT ONLY
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
**LEGACY_ORIGIN_MUTATED = NO.**

---

## C. Entry / Recovery Classification

```text
ENTRY_LOCAL_HEAD           = 85e43154de37f9b4987e9bab1a55548e1c9433fc
ENTRY_REMOTE_TRACKING_HEAD = 85e43154de37f9b4987e9bab1a55548e1c9433fc
ENTRY_DIRECT_REMOTE_HEAD   = 85e43154de37f9b4987e9bab1a55548e1c9433fc   (git ls-remote github)
ENTRY_MERGE_BASE           = 85e43154de37f9b4987e9bab1a55548e1c9433fc
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
(`git cat-file -t`, `git rev-parse <commit>:<path>`) and confirmed present,
unchanged, and ancestor of the current authorized baseline `HEAD`:

| Token | Commit | Path | Expected Blob | Actual Blob | Authority | Result |
|---|---|---|---|---|---|---|
| Owner Order | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | `37518ed12f0402e059e099be8104b21b2d07c64f` | Group B before Group D | PASS |
| Authority Binding | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | `57e0f9c393ea9ef3484a5312612f7703509747af` | Group B canonical scope | PASS |
| Post-M30 Binding | `1a4907bc57c00126f131b458a356749abbc4421b` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | Post-M30 authority | PASS |
| Master Plan | `9ecdc38282cdb7ca6f088263f9e152f920b7a823` | `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | S1..S12 slices; P-OD8..P-OD13 | PASS |
| S2 Governance | `a4fcada1538505bbf527a0fc9d707004490d4ac0` | `docs/PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md` | `9163f1bbe0c75b70e65b15788088a230d8741e31` | `9163f1bbe0c75b70e65b15788088a230d8741e31` | S2 closure; S3 dependency met | PASS |

```text
RESULT = AUTHORITY_CHAIN_VERIFIED   (no mismatch; no conflicting newer committed authority)
```

All mandatory authority blob tuples are also equal to the same blobs at current
`HEAD` (material authority drift = NONE).

**Newer-authority inspection**: commits between the Group B plan
(`9ecdc382`) and HEAD (`85e4315`) are:

```
85e4315 feat: implement Group B S2 server entitlement quota authority
a4fcada docs: govern Group B S2 entitlement and quota authority
334d1ad feat: implement Group B S1 server data model foundation
c6ddbb4 docs: resolve S1 billing cadence schema contradiction
45018ee docs(roadmap): govern Phase P Group B S1 implementation
```

All are S1/S2 governance/implementation. None introduce newer conflicting
authority for S3 scope. S3 remains exactly as defined in the Group B plan
section 14.

---

## E. S2 Prerequisite Closure

S2 is the direct prerequisite for S3. S2 is complete and remotely locked.

```text
S2_COMMIT                  = 85e43154de37f9b4987e9bab1a55548e1c9433fc
S2_PARENT                  = a4fcada1538505bbf527a0fc9d707004490d4ac0
S2_MIGRATION               = 20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql
S2_MIGRATION_BLOB          = 5451fa269870bc98f33aae21ceeb9e74b8db12b8
S2_TEST                    = supabase/tests/s2_server_entitlement_quota_authority.test.sql
S2_TEST_BLOB               = 6c9655f589e897e3e912581ef99f55f44ddb4514
S2_REMOTE_LOCK             = TRUE (local = tracking = direct remote = 85e4315; AHEAD=0, BEHIND=0)
S2_IMMUTABILITY_VERIFIED   = TRUE
```

S2 migration `00032` and S2 tests are **immutable**. They MUST NOT be edited
by the S3 implementation.

S1 is also immutable:

```text
S1_COMMIT                  = 334d1ad443ef709a5c95a7c657024e40c40656aa
S1_MIGRATION_BLOB          = 2ab6436673ecf1ac6e9c39e7fb11403f245dfc2b
S1_TEST_BLOB               = 43f5f68cf5ffcdadb6468af066958bb310923544
```

---

## F. Exact S3 Scope

From the committed Group B plan, section 14:

```text
S3  Revocation / offline-grace authority
    (device+membership+license revocation RPCs; revalidation gate; grace enforcement)
    dependencies: S2
```

### F.1 Canonical S3 name

```text
S3_ID                 = S3
S3_CANONICAL_NAME     = Revocation / offline-grace authority
S3_CANONICAL_UPPER    = REVOCATION_OFFLINE_GRACE_AUTHORITY
```

### F.2 S3 Objective

Server-authoritative revocation enforcement for license, device, and membership
revocation, with server-side revalidation gate ensuring revocation/expiry cannot
depend on indefinitely stale local state, and with offline grace enforcement
boundaries defined and enforced server-side.

### F.3 Owner Decisions Driving S3

| Decision | Requirement | S3 Impact |
|---|---|---|
| P-OD9 | Offline grace: TRIAL 0d, PAID 7d, PERPETUAL 14d compatibility-only. Subscription-only. PERPETUAL never a sold plan. | S3 enforces server-side grace windows; returns authoritative `last_verified_at` for client grace computation; does NOT sell PERPETUAL. |
| P-OD10 | Server authoritative for subscription validity, license state, membership, device authorization, permission state. Revocation/expiry not dependent on indefinitely stale local state. | S3 creates revocation RPCs; `verify_license_entitlement` enhanced to report revocation; revalidation gate on every authoritative boundary. |
| P-OD11 | Reasonable production hardening: clock rollback, stale entitlement cache, cache tampering, entitlement replay, server revalidation, fail-safe, offline-grace abuse. Server-authoritative bounded testable controls. | S3 enforces server-side; does NOT claim perfect client anti-tamper; provides server time in entitlement responses for client bounded checks. |

### F.4 Prerequisites (all met)

```text
S1 = REMOTE-LOCKED (334d1ad)
S2 = REMOTE-LOCKED (85e4315)
```

### F.5 Forbidden Boundary (S3 MUST NOT absorb)

```text
- S4: device-trust gate / invitation hardening / proof-of-possession / approved-device predicate
- S5: client entitlement integration / Flutter models / repositories
- S6: platform secure device identity / per-install keypair
- S7: Owner device management UI
- S8: tamper / cache / clock enforcement (beyond server revalidation time in RPC)
- S9: legacy Ed25519 retirement
- S11: production deployment
- S12: Group B closeout
- Group D planning or implementation
- Payment provider / Stripe / Paymob / billing
- Flutter/Dart production source changes
- Edge Function changes
- RLS policy changes (unless explicitly required for revocation enforcement)
- Seed changes
```

---

## G. Current-State Matrix

### G.1 Server surfaces (read-only audit from committed baseline `85e4315`)

| Surface | Classification | S3 Relevance |
|---|---|---|
| `licenses.status` CHECK (`TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL`) | ALREADY_IMPLEMENTED | S3 needs to ADD `REVOKED` to CHECK and create revocation RPC. Currently no mechanism to set `licenses.status = 'REVOKED'`. |
| `devices.status` CHECK (`ACTIVE/REVOKED/LOST/PENDING_APPROVAL`) | ALREADY_IMPLEMENTED | S3 creates device revocation RPC that sets `devices.status = 'REVOKED'` and `revoked_by`/`revoked_at`. |
| `devices.revoked_by`, `devices.revoked_at` | ALREADY_IMPLEMENTED (S1) | Columns exist but no RPC populates them for revocation. S3 fills this gap. |
| `devices.device_audit_log` | ALREADY_IMPLEMENTED (S1) | Audit table exists; S3 records revocation events. |
| `activations.status` CHECK (`ACTIVE/REVOKED/EXPIRED`) | ALREADY_IMPLEMENTED | `deactivate_device()` already sets activation `REVOKED`. S3 may optionally cascade. |
| `verify_license_entitlement(p_shop_id)` | ALREADY_IMPLEMENTED (S2) | Returns only entitled licenses (`TRIAL/ACTIVE/PERPETUAL`). Revoked licenses are silently absent. S3 enhances this to report revocation state when license is REVOKED. |
| `s2_resolve_entitled_license(p_shop_id)` | ALREADY_IMPLEMENTED (S2) | Only resolves entitled states. S3 may add a parallel `s3_resolve_revocation_status()` or extend verification. |
| `activate_device(p_shop_id, p_installation_id)` | ALREADY_IMPLEMENTED (S2) | Enforces plan-based device quota. Does NOT check device revocation status. S3 adds revocation awareness. |
| `deactivate_device(p_activation_id)` | ALREADY_IMPLEMENTED (Phase E) | Owner-only. Sets activation `REVOKED`. Does NOT set `devices.status = 'REVOKED'` or `revoked_by`/`revoked_at`. |
| `register_device(...)` | ALREADY_IMPLEMENTED (Phase E) | Upserts device with `status = 'ACTIVE'`. Does NOT check if device was previously REVOKED. S3 adds revocation-aware re-registration rejection. |
| `require_shop_permission(p_shop_id, p_permission_id)` | ALREADY_IMPLEMENTED (Phase F) | Checks auth + membership + entitlement + permission. Does NOT check device revocation. S3 does NOT add device-trust gate (that is S4). |
| `shop_members.status` CHECK (`INVITED/ACTIVE/SUSPENDED/REVOKED`) | ALREADY_IMPLEMENTED | Status values exist. No RPC to revoke a membership. S3 creates membership revocation RPC. |
| `s2_enforce_user_quota()` trigger | ALREADY_IMPLEMENTED (S2) | Fires on ACTIVE membership transitions. Respects SUSPENDED/REVOKED for quota counting. No change needed by S3. |
| RLS policies | ALREADY_IMPLEMENTED | `shop_devices_isolation` etc. RLS is S4 scope. S3 does NOT modify RLS. |
| `plans` table | ALREADY_IMPLEMENTED (S1+S2) | Read-only reference. `trial_days` (14) relevant for grace. No change needed by S3. |

### G.2 Client surfaces (read-only audit)

| Surface | Classification | S3 Relevance |
|---|---|---|
| `offline_grace_policy.dart` | PARTIAL (CLIENT) | Implements type-specific grace (0/7/14d). Client-side only. S3 adds server-side revalidation gate; client continues using this for offline UX decisions. |
| `entitlement_cache.dart` | PARTIAL (CLIENT) | Stores entitlement snapshot. `blocksWrites` checks for REVOKED. S3 does NOT modify client cache. |
| `cloud_licensing_service.dart` | PARTIAL (CLIENT) | `deviceRevoked` state defined but never set. S3 does NOT fix this (S5 scope). |
| `cloud_licensing_repository.dart` | PARTIAL (CLIENT) | Calls `verify_license_entitlement`. S3 enhances server response; client may consume new fields. |

### G.3 Test surfaces

| Surface | Classification | S3 Relevance |
|---|---|---|
| `s1_server_data_model_foundation.test.sql` | ALREADY_IMPLEMENTED | Immutable. S3 does not modify. |
| `s2_server_entitlement_quota_authority.test.sql` | ALREADY_IMPLEMENTED | Immutable. S3 does not modify. |
| S3 revocation tests | MISSING | S3 governance requires new pgTAP test file. |

### G.4 Residual gap for S3

```text
MISSING — license-level revocation RPC (no mechanism to revoke a license)
MISSING — device-level revocation RPC (deactivate_device exists but is activation-level; does not set devices.status/revoked_by/revoked_at)
MISSING — membership revocation RPC with cascading device deactivation
MISSING — server-side revalidation gate (no server concept of "when was this last verified"; no authoritative revocation timestamp returned to client for revalidation)
MISSING — verify_license_entitlement does not report REVOKED license state
MISSING — register_device does not reject REVOKED devices from re-registration
MISSING — activate_device does not check device.status for REVOKED before activating
MISSING — offline grace enforcement on server side (server has no grace concept; grace is purely client-computed)
MISSING — pgTAP tests for revocation scenarios
PARTIAL  — deactivate_device exists but incomplete (no device.status change, no audit log)
PARTIAL  — offline grace policy exists but client-only
ALREADY  — status values for REVOKED exist in licenses/devices/activations/shop_members
ALREADY  — S2 entitlement resolver works for entitled states
ALREADY  — S2 device/user quota enforcement works
```

---

## H. Residual Implementation Gap

S3 must close ONLY these gaps:

1. **License revocation RPC**: Owner revokes a license → `licenses.status = 'REVOKED'`, `licenses.revoked_at` set. All active activations for that license are cascade-revoked. All devices under that shop's license lose activation. Deterministic, idempotent, server-authoritative.

2. **Device revocation RPC**: Owner revokes a device → `devices.status = 'REVOKED'`, `devices.revoked_by`/`revoked_at` populated, device's active activation set to `REVOKED`. Audit logged. Deterministic, idempotent, owner-only.

3. **Membership revocation enforcement**: When `shop_members.status` transitions to `SUSPENDED` or `REVOKED`, cascade-deactivate all that member's device activations. Server-authoritative, atomic with the status change.

4. **Revalidation gate**: `verify_license_entitlement` enhanced to return `is_revoked BOOLEAN` and `revoked_at TIMESTAMPTZ` when the shop's license is REVOKED. This gives the client a server-authoritative revocation signal on every revalidation call. The server-time `server_time` already returned enables bounded clock checks.

5. **Revocation-aware device activation**: `activate_device` must reject activation of a device whose `devices.status = 'REVOKED'`.

6. **Revocation-aware device registration**: `register_device` must reject re-registration of a REVOKED device (owner must explicitly un-revoke or create a new installation).

7. **Offline grace server-side anchor**: The server returns `last_verified_at` (already present via `activations.last_verified_at` and `server_time` from `verify_license_entitlement`). S3 documents this as the authoritative anchor for client grace computation. No separate server-side grace timer needed — the client computes grace from `server_time` vs local clock, which is already the implemented pattern.

---

## I. Exact Future Implementation Delta

### I.1 Authorized migration file

```text
NEXT_VALID_MIGRATION (at HEAD) = 20260820000033
MIGRATION_FILE =
  supabase/migrations/20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql
```

If real history at the S3 implementation session already contains an authorized
migration beyond `00032`, adapt to actual history and MUST NOT overwrite an
existing authorized migration.

### I.2 Authorized test file

```text
TEST_FILE =
  supabase/tests/s3_revocation_offline_grace_authority.test.sql
```

### I.3 Allowed modification paths (S3 implementation session ONLY)

```text
supabase/migrations/20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql
  (exactly one additive migration)

supabase/tests/s3_revocation_offline_grace_authority.test.sql
  (exactly one new pgTAP test file)
```

### I.4 Forbidden paths (S3 implementation MUST NOT touch)

```text
app/lib/**                       (Flutter production source — S3 server-only)
supabase/functions/**            (Edge Functions — none changed by S3)
supabase/config.toml             (no infra/config change)
supabase/seed.sql                (no seed change by S3)
.env* / secrets / keystores      (no secret mutation)
supabase/migrations/20260820000000.sql .. 00032.sql  (immutable)
supabase/tests/s1_server_data_model_foundation.test.sql  (immutable)
supabase/tests/s2_server_entitlement_quota_authority.test.sql  (immutable)
```

### I.5 Broad permissions NOT granted

The allowlist is the narrowest set above. No wildcard permissions like
`supabase/**`, `lib/**`, `test/**` are granted.

---

## J. Database Contract

### J.1 Migration scope

```text
MIGRATION_33_FILE = 20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql
TYPE = ADDITIVE ONLY
FORWARD_ONLY = TRUE
IDEMPOTENT = TRUE
NON_DESTRUCTIVE = TRUE
```

### J.2 Schema changes

#### J.2.1 `licenses` table — add `REVOKED` to CHECK constraint

```sql
ALTER TABLE licenses
  DROP CONSTRAINT IF EXISTS licenses_status_check;

ALTER TABLE licenses
  ADD CONSTRAINT licenses_status_check
  CHECK (status IN ('TRIAL', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'PERPETUAL', 'REVOKED'));
```

`REVOKED` is a terminal state (like PERPETUAL). A revoked license cannot be
un-revoked by re-activation; it requires explicit owner action (a new license
record or explicit un-revocation, deferred to Owner UI / S7).

#### J.2.2 No new tables

S3 does NOT create new tables. All surfaces use existing tables:
- `licenses` (revocation status)
- `devices` (revocation status)
- `activations` (activation revocation)
- `shop_members` (membership revocation)
- `device_audit_log` (audit trail)

#### J.2.3 No new columns

All needed columns already exist from S1/S2:
- `licenses.revoked_at` (Phase E)
- `devices.revoked_by`, `devices.revoked_at` (S1)
- `devices.status` CHECK includes `REVOKED` (S1)
- `device_audit_log` (S1)

#### J.2.4 No RLS changes

```text
RLS_POLICY_DELTA = ZERO
```

S3 does NOT modify any RLS policy. Revocation enforcement is via RPC-level
checks, not RLS predicates. RLS device-trust predicates are S4 scope.

### J.3 Server functions (created by S3 migration)

#### J.3.1 `s3_revoke_license(p_shop_id UUID, p_reason TEXT DEFAULT NULL)`

```text
OWNER-ONLY. Sets licenses.status = 'REVOKED', licenses.revoked_at = now().
Cascade: for all activations linked to this license with status = 'ACTIVE',
  SET activations.status = 'REVOKED'.
Also: for all devices under this shop with status = 'ACTIVE',
  SET devices.status = 'REVOKED', devices.revoked_by = caller, devices.revoked_at = now().
Audit: INSERT INTO device_audit_log for each affected device.
Idempotent: if already REVOKED, return success without re-processing.
Advisory lock: shop-keyed for atomicity.
Error: deterministic S3_LICENSE_REVOCATION_FAILED on unexpected state.
```

#### J.3.2 `s3_revoke_device(p_shop_id UUID, p_device_id UUID, p_reason TEXT DEFAULT NULL)`

```text
OWNER-ONLY. Sets devices.status = 'REVOKED', devices.revoked_by = caller,
  devices.revoked_at = now().
Cascade: SET activations.status = 'REVOKED' for this device's ACTIVE activations
  against the shop's license.
Audit: INSERT INTO device_audit_log.
Idempotent: if already REVOKED, return success.
Advisory lock: shop-keyed.
Error: deterministic S3_DEVICE_REVOCATION_FAILED on unexpected state.
```

#### J.3.3 `s3_revoke_membership(p_shop_id UUID, p_member_user_id UUID, p_reason TEXT DEFAULT NULL)`

```text
OWNER-ONLY. Sets shop_members.status = 'REVOKED' for the target member.
Cascade: for all devices belonging to this user in this shop with status = 'ACTIVE',
  SET devices.status = 'REVOKED', devices.revoked_by = caller, devices.revoked_at = now(),
  AND SET their activations.status = 'REVOKED'.
Audit: INSERT INTO device_audit_log for each affected device.
Idempotent: if already REVOKED, return success.
Advisory lock: shop-keyed.
Cannot revoke the owner's own membership (guard).
Error: deterministic S3_MEMBERSHIP_REVOCATION_FAILED.
```

#### J.3.4 Enhanced `verify_license_entitlement(p_shop_id UUID)`

```text
ADD to existing return signature (additive, backward-compatible):
  is_revoked BOOLEAN       -- TRUE if the shop's license status is REVOKED
  revoked_at  TIMESTAMPTZ  -- when the license was revoked (NULL if not revoked)

Logic change: after finding the license, also check if the most recent license
  (regardless of status) is REVOKED. If so, return is_revoked = TRUE,
  revoked_at = licenses.revoked_at, with all other fields as NULL/false/0.
  This ensures the client gets a server-authoritative revocation signal.
```

This is an **additive return-column change**. The existing 14-column return
signature becomes 16 columns. Existing callers that SELECT specific columns
are unaffected. Callers that use `SELECT *` will see two new columns (backward
compatible).

#### J.3.5 Revocation-aware `activate_device(p_shop_id UUID, p_installation_id UUID)`

```text
ADD check after finding device: IF v_device.status = 'REVOKED' THEN
  RETURN jsonb_build_object('success', false, 'error', 'S3_DEVICE_REVOKED: device has been revoked').
This prevents re-activation of a revoked device without explicit owner action.
```

#### J.3.6 Revocation-aware `register_device(...)`

```text
ADD check after upsert attempt: IF the existing device has status = 'REVOKED',
  do NOT overwrite status to 'ACTIVE'. Instead raise an exception:
  'S3_DEVICE_REVOKED: this device has been revoked and cannot be re-registered'.
  This forces the owner to explicitly un-revoke or the user to create a new installation.
```

### J.4 Idempotency

All revocation RPCs are idempotent. Re-calling `s3_revoke_device` on an
already-REVOKED device returns success without double-processing or audit
duplication.

### J.5 Concurrency

```text
CONCURRENCY_PROOF = REQUIRED
REASON = License/device/membership revocation races with concurrent activation or registration.
```

Shop-keyed PostgreSQL transaction advisory locks (`pg_advisory_xact_lock`) are
required in all revocation RPCs to prevent:

- revocation racing with activation (device activated during revocation)
- membership revocation racing with device registration
- license revocation racing with device activation

The implementation must demonstrate that a revocation in progress blocks
concurrent activation, and vice versa, via the advisory lock.

### J.6 Rollback characteristics

```text
ROLLBACK = NON_DESTRUCTIVE (additive migration; CHECK constraint extension is safe)
REVOCATION IS SEMI-IRREVERSIBLE: revoked status requires explicit owner action to undo.
  S3 does NOT provide an "un-revoke" RPC (that is S7 Owner UI scope).
```

---

## K. Server Authority Contract

### K.1 Who may call what

| RPC | Caller requirement | Server validates |
|---|---|---|
| `s3_revoke_license` | Authenticated + owner ACTIVE membership in shop | Shop exists, caller is owner, license exists and is in revocable state |
| `s3_revoke_device` | Authenticated + owner ACTIVE membership in shop | Shop exists, caller is owner, device exists in shop, device is in revocable state |
| `s3_revoke_membership` | Authenticated + owner ACTIVE membership in shop | Shop exists, caller is owner, target is a member, target is not the owner themselves, target is in revocable state |
| `verify_license_entitlement` | Authenticated + ACTIVE membership in shop | (existing; enhanced return) |
| `activate_device` | Authenticated + ACTIVE membership in shop | (existing; enhanced with revocation check) |
| `register_device` | Authenticated + ACTIVE membership in shop | (existing; enhanced with revocation check) |

### K.2 Server validates

- Authentication (`auth.uid()` not null)
- Active membership (`shop_members.status = 'ACTIVE'`)
- Owner role for revocation RPCs
- Entity existence (license/device/member exists in shop)
- Entity state (not already revoked — idempotent guard)
- Cross-tenant isolation (all queries scoped to `shop_id`)
- No client-supplied IDs for revoker identity (uses `auth.uid()`)

### K.3 Client role

The client may call these RPCs but has NO authority over:
- Whether revocation succeeds (server decides)
- Whether an entity is revocable (server checks state)
- The revoker identity (server uses `auth.uid()`)
- Cascade effects (server handles atomically)

---

## L. Client Contract

### L.1 S3 does NOT change client code

```text
FLUTTER_SOURCE_CHANGED = FALSE
```

S3 is entirely server-side (migration + tests). Client changes that consume
S3's enhanced `verify_license_entitlement` return (e.g., handling
`is_revoked`/`revoked_at`) are S5 scope.

### L.2 Client behavior expectations (for future S5 awareness)

- Client calls `verify_license_entitlement` → receives `is_revoked` +
  `revoked_at` → if `is_revoked = true`, block all writes (existing
  `blocksWrites` logic already handles REVOKED license status in cache).
- Client offline: grace policy (`offline_grace_policy.dart`) continues
  computing grace from `server_time` vs local clock. S3 does NOT change this.
- Client revocation UI: not in S3 scope (S7).

### L.3 Platforms

```text
WINDOWS =UNCHANGED
ANDROID  = UNCHANGED
```

---

## M. Security / Threat Matrix

| # | Threat / attack case | S3 expected outcome | Fail-closed behavior |
|---|---|---|---|
| 1 | Owner revokes license; device continues operating offline | Client's cached entitled state expires per grace policy (0/7/14d). On next online session, `verify_license_entitlement` returns `is_revoked = true`. Writes blocked. | Grace expires → denied. Online → denied. |
| 2 | Owner revokes device; device tries re-activation | `activate_device` checks `devices.status`, rejects REVOKED device with `S3_DEVICE_REVOKED`. | Denied. |
| 3 | Owner revokes device; device tries re-registration | `register_device` checks existing device status, rejects REVOKED device. | Denied. |
| 4 | Owner revokes membership; employee devices continue | Membership revocation cascades: all member's devices REVOKED, activations REVOKED. Employee loses all shop access. | Denied. |
| 5 | Concurrent revocation and activation | Advisory lock ensures serial execution. Revocation wins if lock acquired first; activation checks post-lock. | No double-allocation. |
| 6 | Revocation of already-revoked entity | Idempotent: returns success, no side effects. | No error, no drift. |
| 7 | Non-owner tries revocation | Server checks `role = 'owner'`. Non-owner gets deterministic error. | Denied. |
| 8 | Cross-shop revocation attempt | All queries scoped to `shop_id`. Cannot revoke entity in another shop. | Denied. |
| 9 | License revocation when no active license | Guard: only revoke TRIAL/ACTIVE/PERPETUAL. EXPIRED/SUSPENDED/REVOKED → idempotent no-op. | No unintended state change. |
| 10 | Stale cached entitlement after revocation | Client's `isCachedNonEntitled` checks REVOKED status. Offline grace expired → denied. Online revalidation → denied. | Fail-closed on stale cache. |

### M.1 Explicit threat boundary

S3 provides server-authoritative revocation enforcement. It does NOT provide:

- Real-time push revocation (no WebSocket/notification channel). Revocation is
  detected on next online interaction. This is the committed baseline design.
- Perfect offline revocation (a device within grace window can continue offline
  operations on cached entitled state). This is the committed grace policy.
- Client anti-tamper (a modified client can ignore revocation locally). The
  server enforces on every online interaction; this is the security boundary
  per P-OD11.

---

## N. Test Contract

### N.1 pgTAP test file

```text
TEST_FILE = supabase/tests/s3_revocation_offline_grace_authority.test.sql
```

### N.2 Required test scenarios

| # | Test | Invariant proven |
|---|---|---|
| T1 | License revocation sets status = REVOKED | `licenses.status = 'REVOKED'` after `s3_revoke_license` |
| T2 | License revocation sets `revoked_at` | `licenses.revoked_at IS NOT NULL` and is recent |
| T3 | License revocation cascades to activations | All active activations for the license → status = REVOKED |
| T4 | License revocation cascades to devices | All active devices under shop → status = REVOKED, `revoked_by`/`revoked_at` populated |
| T5 | License revocation audit trail | `device_audit_log` entries created for each affected device |
| T6 | License revocation idempotent | Second call returns success, no additional audit entries |
| T7 | Device revocation sets status + revoked_by + revoked_at | `devices.status = 'REVOKED'`, `revoked_by` = caller, `revoked_at` recent |
| T8 | Device revocation cascades to activations | Active activations for the device → REVOKED |
| T9 | Device revocation idempotent | Second call returns success |
| T10 | Membership revocation sets status = REVOKED | `shop_members.status = 'REVOKED'` |
| T11 | Membership revocation cascades to member's devices | All active devices belonging to the revoked member → REVOKED |
| T12 | Membership revocation cascades to activations | Activations for cascaded devices → REVOKED |
| T13 | Membership revocation blocks owner self-revocation | Owner cannot revoke own membership |
| T14 | Non-owner revocation rejected | Non-owner calling `s3_revoke_license` / `s3_revoke_device` / `s3_revoke_membership` → exception |
| T15 | verify_license_entitlement returns is_revoked for REVOKED license | `is_revoked = TRUE`, `revoked_at IS NOT NULL` |
| T16 | verify_license_entitlement returns normal for entitled license | `is_revoked = FALSE` for TRIAL/ACTIVE/PERPETUAL |
| T17 | activate_device rejects REVOKED device | Attempting to activate a REVOKED device → `S3_DEVICE_REVOKED` error |
| T18 | register_device rejects REVOKED device | Attempting to re-register a REVOKED device → `S3_DEVICE_REVOKED` error |
| T19 | Tenant isolation: revocation scoped to shop | Revoking in Shop A does not affect Shop B entities |
| T20 | Concurrency: revocation blocks concurrent activation | Advisory lock prevents activation during revocation |
| T21 | S1 regression | `s1_server_data_model_foundation.test.sql` still passes |
| T22 | S2 regression | `s2_server_entitlement_quota_authority.test.sql` still passes |

### N.3 Regression gates

```text
S1_PG_TAP            = 46/46 (must remain)
S2_PG_TAP            = 88/88 (must remain)
S1_PLUS_S2           = 134 (must remain)
S3_PG_TAP            = 22 (must pass)
S3_PLUS_S1_PLUS_S2   = 156 (must pass)
FLUTTER_TEST         = 1562/1562 (must remain; S3 changes no client code)
```

### N.4 Pre-existing unrelated failures

```text
cloud_stock_adjustments     = pre-existing (NOT S3 defect)
rls_shop_members_recursion  = pre-existing (NOT S3 defect)
```

These are NOT S3 defects and must not be "fixed" by the S3 implementation
unless the exact committed S3 authority explicitly includes them — which it
does not.

---

## O. P-OD13 CASE 1–20 Matrix (S3 ownership)

| # | Case | S3 classification |
|---|---|---|
| 1 | Employee + approved device → only Shop A data | NOT_APPLICABLE_TO_S3 (S4 device gate) |
| 2 | New unapproved device denied | DEFERRED_TO_S4 |
| 3 | Stolen creds from another device | DEFERRED_TO_S4 |
| 4 | shop_id change / cross-tenant | PARTIALLY_RELEVANT (S3 enforces tenant-scoped revocation) |
| 5 | Direct API without device proof | DEFERRED_TO_S4 |
| 6 | Owner approves pending device | DEFERRED_TO_S4 |
| 7 | Owner rejects | DEFERRED_TO_S4 |
| 8 | Owner revokes ACTIVE | COVERED_BY_S3 (device revocation RPC) |
| 9 | Owner marks LOST | PARTIALLY_RELEVANT (LOST device treatment; S3 device revocation covers the "denied" outcome) |
| 10 | Membership suspended/revoked | COVERED_BY_S3 (membership revocation RPC with device cascade) |
| 11 | Expired invitation/token | DEFERRED_TO_S4 |
| 12 | Used-token replay | DEFERRED_TO_S4 |
| 13 | Shop-A token vs Shop B | DEFERRED_TO_S4 |
| 14 | Second legitimate device | NOT_APPLICABLE_TO_S3 (S2 quota) |
| 15 | Reinstall → re-approval | DEFERRED_TO_S4 |
| 16 | Approved device offline | PARTIALLY_RELEVANT (S3 defines grace; offline boundary) |
| 17 | Unknown first-time device offline | DEFERRED_TO_S4 |
| 18 | salesOnly cannot gain higher role | NOT_APPLICABLE_TO_S3 |
| 19 | Modified client / direct RLS | DEFERRED_TO_S4 |
| 20 | No reusable password | NOT_APPLICABLE_TO_S3 |

S3 explicitly claims ONLY cases 8, 10, and the revocation-related portions of
4, 9, 16. All other cases remain deferred to their owning slices.

---

## P. Regression Gates

### P.1 S1/S2 immutability

```text
S1_MIGRATION_EDITED    = FALSE
S1_TEST_EDITED         = FALSE
S2_MIGRATION_EDITED    = FALSE
S2_TEST_EDITED         = FALSE
MIGRATION_00000..00030_EDITED = FALSE
```

### P.2 Pre-existing test status (must not regress)

```text
s1_server_data_model_foundation.test.sql    = 46/46
s2_server_entitlement_quota_authority.test.sql = 88/88
cloud_stock_adjustments.test.sql            = pre-existing failure (not S3 defect)
rls_shop_members_recursion.test.sql         = pre-existing failure (not S3 defect)
```

### P.3 Flutter regression

```text
FLUTTER_TEST = 1562/1562 (must remain; S3 changes no client code)
```

---

## Q. Forbidden Scope

```text
S4_STARTED           = NO (device-trust gate / invitation hardening — deferred)
S5_STARTED           = NO (client entitlement integration — deferred)
S6_STARTED           = NO (platform secure device identity — deferred)
S7_STARTED           = NO (Owner device management UI — deferred)
S8_STARTED           = NO (tamper/cache/clock enforcement — deferred)
S9_STARTED           = NO (legacy Ed25519 retirement — deferred)
S10_STARTED          = NO (test/security convergence — deferred)
S11_STARTED          = NO (deployment/verification — deferred)
S12_STARTED          = NO (Group B closeout — deferred)
GROUP_C_STARTED      = NO
GROUP_D_STARTED      = NO
GROUP_D_ADVANCED     = NO
PRODUCTION_MUTATION  = NO
PAYMENT_PROVIDER_WORK = NO
LEGACY_ORIGIN_CONTACTED = NO
```

---

## R. Implementation Entry Contract

The future S3 implementation session may run ONLY when ALL of the following hold:

```text
- this S3 governance artifact is committed and remote-locked (authority present)
- S1 is unchanged and remote-locked (334d1ad)
- S2 is unchanged and remote-locked (85e4315)
- repository is clean in the governed sense and no active Git operation
- the next authorized migration (00033 at HEAD, or adapted to real history) is confirmed
- the implementer stays within the ALLOWED paths (migration + test only)
- separate owner authorization for the S3 IMPLEMENTATION session exists
  (governance alone does not authorize implementation)
```

---

## S. Commit / Push Contract

```text
COMMIT_STYLE     = normal commit (no amend, no rebase, no squash)
PUSH_MODE        = NORMAL_FAST_FORWARD_ONLY
FORCE_PUSH       = NEVER
FORCE_WITH_LEASE = NEVER
REMOTE           = github ONLY (origin is sacred read-only)
HISTORY_REWRITE  = NEVER
```

---

## T. Mandatory Stop

```text
STOP AFTER S3 GOVERNANCE REMOTE LOCK.
DO NOT IMPLEMENT S3 IN THIS SESSION.
DO NOT START S4.
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
S3_IMPLEMENTATION_STARTED    = FALSE
SQL_MIGRATION_CREATED        = FALSE   (no 00033)
PRODUCTION_SOURCE_CHANGED    = FALSE
EDGE_FUNCTION_CHANGED        = FALSE
RLS_CHANGED                  = FALSE
AUTH_CHANGED                 = FALSE
DEVICE_LOGIC_CHANGED         = FALSE
LICENSE_IMPL_CHANGED         = FALSE
TESTS_CHANGED_AS_IMPL        = FALSE
CONFIGURATION_CHANGED        = FALSE
PRODUCTION_DEPLOYED          = FALSE
S1_MIGRATION_EDITED          = FALSE
S1_TEST_EDITED               = FALSE
S2_MIGRATION_EDITED          = FALSE
S2_TEST_EDITED               = FALSE
MIGRATION_00000..00030_EDITED = FALSE
GROUP_B_OTHER_SLICES_STARTED = FALSE
GROUP_C_STARTED              = FALSE
GROUP_D_ADVANCED             = FALSE
SYNC_DRAIN_CHANGED           = FALSE
ANDROID_BUILD / AAB / PLAY   = FALSE
LEGACY_ORIGIN_MUTATED        = FALSE
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
S3_IMPLEMENTATION_GOVERNANCE = CREATED + COMMITTED + NORMAL_FAST_FORWARD_PUSHED + REMOTE-LOCKED
S3_IMPLEMENTATION            = NOT_STARTED
PRODUCTION                   = UNCHANGED
GROUP_D                      = DEFERRED
```

The terminal state is:

```text
S3 GOVERNANCE          = CREATED / COMMITTED / NORMAL FAST-FORWARD PUSHED / REMOTE-LOCKED
S3 IMPLEMENTATION      = NOT STARTED
PRODUCTION             = UNCHANGED
GROUP D                = DEFERRED
```

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION = CASE_A_FRESH
ENTRY_HEAD           = 85e43154de37f9b4987e9bab1a55548e1c9433fc
ENTRY_PARENT         = a4fcada1538505bbf527a0fc9d707004490d4ac0
DIFF PROFILE         = 1 added file (this artifact), 0 modified, 0 deleted
SACRED EVIDENCE      = preserved (untracked; never staged/modified)
COMMIT               = <set at commit>
AHEAD / BEHIND       = (1/0 after commit, pre-push)
```
