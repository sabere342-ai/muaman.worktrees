# PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING_REPORT

**Session**: `PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING`
**Date**: 2026-09-15
**Result**: `PASS_PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING_REMOTE_LOCKED`
**Successor**: `PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_OWNER_AUTHORIZATION`

---

## A. SESSION RESULT

Planning completed successfully. A safe signIn-first existing-account linker
architecture has been designed, covering authentication, UID binding, shop
reconciliation, membership reconciliation, duplicate-shop prevention, local
atomic persistence, failure/recovery, UI/UX, security, tests, and ordered
implementation.

RESULT_TOKEN: `PASS_PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING_REMOTE_LOCKED`

---

## B. REPOSITORY IDENTITY

| Field | Value |
|-------|-------|
| Root | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| Git dir | `C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze` |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Entry HEAD | `022897c0039ccf7fc14f3c8dc84aa171fe8dc209` |
| Exit HEAD | (same after planning commit) |

---

## C. ENTRY FORENSICS

| Field | Value |
|-------|-------|
| Tracking | `github/codex/i-tech-next-roadmap-freeze` |
| Direct GitHub HEAD | `022897c0039ccf7fc14f3c8dc84aa171fe8dc209` |
| Merge base | `022897c0039ccf7fc14f3c8dc84aa171fe8dc209` |
| Ahead | 0 |
| Behind | 0 |
| Active merge | NONE |
| Active rebase | NONE |
| Active cherry-pick | NONE |
| Active revert | NONE |
| Stash | 1 entry (pre-existing, unrelated to this branch) |
| Tracked modifications | NONE |
| Staged changes | NONE |
| Untracked | Pre-existing governance reports, `delivery/`, `supabase/.branches/`, `supabase/.temp/` — all preserved |

Entry state: **CASE_A_FRESH**

---

## D. PREVIOUS DECISION BASELINE

The previous session (`PASS_PHASE_P_GATE_2_CONFIRMED_EXISTING_AUTH_IDENTITY_RECONCILIATION_OWNER_DECISION_REMOTE_LOCKED`) established:

1. **Auth identity exists**: `AUTH_IDENTITY_UID = 0e681dc8-8055-4403-aba3-9d1146d4747e`
2. **Email confirmed**: YES
3. **Prior successful sign-in**: YES
4. **Reconfirmation required**: NO
5. **Owner decision**: `RECONCILE CONFIRMED EXISTING AUTH IDENTITY VIA CONTROLLED SIGNIN-BASED EXISTING-ACCOUNT LINK`
6. **Implementation must be planned first** — this session fulfills that requirement.

---

## E. CURRENT AUTH/LINK ARCHITECTURE

### Files inspected

| File | Lines | Role |
|------|-------|------|
| `app/lib/services/identity_linker.dart` | 288 | Cloud-link state machine (onboardFreshOwner, linkExistingUser, recoverOnboarding) |
| `app/lib/services/cloud_auth_service.dart` | 240 | Supabase Auth wrapper (signIn, signUp, signOut, RPCs) |
| `app/lib/services/seller_session_provisioning.dart` | 319 | Seller cloud-login (signIn → membership → shop resolve → bind) |
| `app/lib/services/shop_resolver.dart` | 101 | Shop resolution from cloud memberships |
| `app/lib/services/active_shop_context.dart` | 101 | In-process tenant context singleton |
| `app/lib/services/tenant_isolation_gate.dart` | 195 | Strict tenant-filter arming |
| `app/lib/services/session_state.dart` | 138 | In-memory session state |
| `app/lib/services/app_settings.dart` | 219 | Key-value persistence |
| `app/lib/database/user_repository.dart` | 546 | Local user CRUD + cloud_uuid management |
| `app/lib/database/database_helper.dart` | 3847 | SQLite schema (v20) + tenant stamping |
| `app/lib/models/user.dart` | 85 | User model (cloudUuid field) |
| `app/lib/models/cloud_session.dart` | 50 | Cloud session (userId, activeShopId, membershipRole) |
| `app/lib/screens/settings_screen.dart` | 2442 | Settings with cloud-link dialog |
| `app/lib/screens/auth/first_owner_setup_screen.dart` | 317 | Fresh owner bootstrap |
| `supabase/migrations/...00000_create_shops.sql` | 27 | shops table (NO unique on owner_user_id) |
| `supabase/migrations/...00001_create_shop_members.sql` | 37 | shop_members (UNIQUE(shop_id, user_id)) |
| `supabase/migrations/...00020_database_functions.sql` | 297 | create_shop_with_owner, get_user_shops, etc. |

### Three identity linkage points

1. `users.cloud_uuid` ↔ `auth.uid()` (local user → cloud identity)
2. `ShopProfile.cloudUuid` (via `app_settings['shopProfile.cloudUuid']`) ↔ `shops.id` (shop → cloud shop)
3. `app_settings['cloud.auth.email']` ↔ `auth.users.email` (email bridge)

### Existing flows

| Flow | Entry | Auth method | Target |
|------|-------|-------------|--------|
| Fresh owner onboarding | `FirstOwnerSetupScreen._createOwner()` | `signUp` | New account + new shop |
| Existing owner linking | `SettingsScreen._runCloudLink()` → `IdentityLinker.linkExistingUser()` | `signUp` | New account + new shop |
| Seller cloud login | `LoginScreen._cloudLogin()` → `provisionSellerSession()` | `signInWithPassword` | Existing membership (owner REJECTED by D-L3) |
| Cold-start resume | `resumeCloudSessionAtStartup()` | Existing session | Existing membership |
| Invitation acceptance | `AcceptInvitationScreen._acceptInvitation()` | `signInWithPassword` | Existing invitation |

---

## F. VERIFIED EXISTING FAILURE PATH

The blocking failure occurs in `identity_linker.dart:111`:

```
linkExistingUser()
  → _cloudAuth.signUp(email, password)           [line 111]
  → Supabase returns user != null, session == null  [email already registered, confirmation required]
  → cloud_auth_service.dart:150 maps to:
     CloudSignUpResult.unknownError('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول')
  → identity_linker.dart:122 maps to:
     LinkResult.unknownError('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول')
  → settings_screen.dart:967 displays the error message
  → DEAD END: no signIn-first path exists
```

The email IS confirmed. The identity HAS signed in successfully before. The
application architecture simply lacks a signIn-first existing-account linker.

The seller login path (`provisionSellerSession`) DOES use
`signInWithPassword`, but it explicitly REJECTS owner-role memberships at
line 184 (D-L3). It cannot be repurposed for owner linking.

---

## G. EXISTING CLOUD-STATE MODEL

### shops table

```sql
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settings JSONB DEFAULT '{}'::jsonb
);
-- INDEX: idx_shops_owner_user_id ON shops(owner_user_id)
-- NO UNIQUE CONSTRAINT on owner_user_id
```

### shop_members table

```sql
CREATE TABLE shop_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'employee', 'salesOnly')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (...),
  UNIQUE(shop_id, user_id)
);
```

### create_shop_with_owner RPC

```sql
CREATE OR REPLACE FUNCTION create_shop_with_owner(p_name TEXT)
RETURNS UUID
-- SECURITY DEFINER, SET search_path = public
-- 1. Validates auth.uid() is not null
-- 2. Validates p_name is not empty
-- 3. INSERT INTO shops (name, owner_user_id) VALUES (trim(p_name), v_user_id)
-- 4. INSERT INTO shop_members (shop_id, user_id, role, status, joined_at) VALUES (v_shop_id, v_user_id, 'owner', 'ACTIVE', now())
-- 5. Seeds system roles
-- 6. Returns v_shop_id
-- NO CHECK for existing owner shops — always creates
```

### get_user_shops RPC

```sql
CREATE OR REPLACE FUNCTION get_user_shops()
RETURNS TABLE (shop_id, shop_name, owner_user_id, membership_role, membership_status, created_at)
-- Returns all shops where auth.uid() has an ACTIVE membership
-- Includes owner_user_id in the result — useful for ownership verification
```

---

## H. THREAT AND CONFLICT MODEL

### Threat 1: Duplicate Shop Creation
**Risk**: A careless retry or race condition creates two shops for the same Auth owner.
**Current state**: `create_shop_with_owner` has NO guard. `shops.owner_user_id` has NO unique constraint.
**Mitigation required**: Database-level invariant + RPC-level guard.

### Threat 2: Wrong-UID Binding
**Risk**: Local `cloud_uuid` is set to a different user's Auth UID.
**Current state**: `cloud_uuid` is immutable once set (line 414 of user_repository.dart).
**Mitigation required**: Explicit UID mismatch rejection before any persistence.

### Threat 3: Duplicate Membership
**Risk**: Owner membership row created twice.
**Current state**: `UNIQUE(shop_id, user_id)` on shop_members prevents this.
**Mitigation**: Already handled by existing DB constraint.

### Threat 4: Partial Local Persistence
**Risk**: `cloud_uuid` written but `shop_id` not written, or vice versa.
**Current state**: `_persistIdentity` (line 220) performs three separate writes (users.update, AppSettings x2). Not atomic.
**Mitigation required**: Wrap in a single SQLite transaction.

### Threat 5: Race Condition — Double Tap
**Risk**: User taps "link" twice quickly. Two concurrent signIn → create shop flows.
**Mitigation required**: UI double-submit prevention + idempotent server-side + unique constraint.

### Threat 6: Race Condition — Two Devices
**Risk**: Same owner signs in on two devices simultaneously, both try to create a shop.
**Mitigation required**: DB UNIQUE constraint on `shops.owner_user_id` prevents duplicates.

### Threat 7: Wrong-Account Sign-In
**Risk**: Owner signs into a different Supabase account than intended.
**Mitigation required**: After signIn, verify the authenticated UID's shop ownership matches expectations. If the UID already owns a shop, confirm with user before proceeding. If the UID belongs to a completely different shop, reject.

### Threat 8: Client Crash After Server Commit
**Risk**: Shop created on server, but app crashes before local persistence.
**Mitigation required**: `recoverOnboarding` must handle this case (shop exists, local linkage missing).

### Threat 9: Network Timeout With Unknown Commit State
**Risk**: signIn or shop creation times out; server state unknown.
**Mitigation required**: Retry must be idempotent. Use `get_user_shops` to probe server state before retrying shop creation.

### Threat 10: Session Expiry During Flow
**Risk**: JWT expires between signIn and subsequent RPC calls.
**Mitigation required**: Supabase auto-refresh handles this. If session is null after signIn, treat as network/auth failure.

---

## I. PROPOSED SIGNIN-FIRST LINKER ARCHITECTURE

### Overview

The proposed architecture adds a new method `linkExistingUserViaSignIn` to
`IdentityLinker`. This method uses `signInWithPassword` instead of `signUp`,
then reconciles cloud state (shops owned by the authenticated UID) against
local state, and safely establishes the three linkage points.

A companion server-side RPC `link_owner_reconcile` provides atomic
server-side guarantees.

### Architecture diagram (text)

```
Settings Screen
  │
  ├── Dialog: email, password (NO shop name needed for existing account)
  │
  └── IdentityLinker.linkExistingUserViaSignIn()
        │
        ├── 1. Precondition checks (local user exists, not already linked)
        │
        ├── 2. CloudAuthService.signInWithEmail(email, password)
        │     ├── Success → authenticated UID obtained
        │     ├── invalidCredentials → return error
        │     ├── emailNotConfirmed → return error (should not happen for confirmed identity)
        │     └── networkUnavailable → return error
        │
        ├── 3. UID binding verification
        │     ├── localUser.cloud_uuid == null → proceed (fresh link)
        │     ├── localUser.cloud_uuid == authenticated UID → idempotent (already linked)
        │     └── localUser.cloud_uuid != authenticated UID → REJECT (wrong account)
        │
        ├── 4. Cloud state lookup via get_user_shops()
        │     ├── 0 shops owned by this UID → create via RPC
        │     ├── 1 shop owned by this UID → reuse
        │     ├── 2+ shops owned by this UID → anomaly STOP
        │     └── shops exist but this UID is not owner → check membership
        │
        ├── 5. Server reconciliation via link_owner_reconcile RPC
        │     (atomic: validate UID → check/create shop → ensure membership → return shop_id)
        │
        ├── 6. Local atomic persistence (SQLite transaction)
        │     ├── users.cloud_uuid = authenticated UID
        │     ├── app_settings['shopProfile.cloudUuid'] = shop_id
        │     └── app_settings['cloud.auth.email'] = email
        │
        └── 7. Return LinkResult.success(cloudUserId, shopId)
```

---

## J. AUTHENTICATION STATE MACHINE

```
IDLE
  │
  ├── [user taps link]
  │
  ▼
PRECONDITION_CHECK
  ├── local user null → LOCAL_USER_NOT_FOUND → IDLE
  ├── already linked (cloud_uuid set) → ALREADY_LINKED → IDLE
  ├── Supabase not configured → NETWORK_UNAVAILABLE → IDLE
  │
  ▼
SIGN_IN
  ├── signInWithPassword(email, password)
  │
  ├── invalidCredentials → WRONG_PASSWORD → IDLE (retry allowed)
  ├── emailNotConfirmed → EMAIL_NOT_CONFIRMED → IDLE
  ├── networkUnavailable → NETWORK_UNAVAILABLE → IDLE (retry allowed)
  ├── unknown error → UNKNOWN_ERROR → IDLE
  │
  ├── success → authenticated UID obtained
  │
  ▼
UID_BINDING_CHECK
  ├── local.cloud_uuid == null → FRESH_LINK → proceed
  ├── local.cloud_uuid == auth.uid → IDEMPOTENT → recover linkage → DONE
  ├── local.cloud_uuid != auth.uid → UID_CONFLICT → IDLE (manual resolution)
  │
  ▼
CLOUD_STATE_LOOKUP (get_user_shops)
  ├── RPC fails → NETWORK_UNAVAILABLE → IDLE (retry allowed)
  │
  ├── 0 shops owned by auth.uid → NEEDS_SHOP_CREATION → proceed
  ├── 1 shop owned by auth.uid → HAS_SHOP → proceed
  ├── 2+ shops owned by auth.uid → ANOMALY → STOP
  │
  ▼
SERVER_RECONCILIATION (link_owner_reconcile RPC)
  ├── RPC fails → UNKNOWN_ERROR → IDLE (retry safe due to idempotency)
  ├── anomaly detected → ANOMALY → STOP
  │
  ├── success → shop_id obtained
  │
  ▼
LOCAL_PERSISTENCE (SQLite transaction)
  ├── transaction fails → LOCAL_PERSISTENCE_FAILED → IDLE (retry safe)
  │
  ├── success → DONE
  │
  ▼
LINKED
```

---

## K. UID BINDING RULES

### Rule 1: Fresh Link (local cloud_uuid is null)
- Authenticated UID becomes the linked UID.
- No conflict possible.

### Rule 2: Idempotent Re-Link (local cloud_uuid == authenticated UID)
- Already linked. Re-persist linkage points if any are missing.
- No mutation of cloud_uuid needed.

### Rule 3: UID Conflict (local cloud_uuid != authenticated UID)
- **REJECT** with explicit error.
- The user likely signed into the wrong Supabase account.
- Display: "هذا الحساب السحابي مرتبط بحساب محلي آخر. سجّل الدخول بالحساب الصحيح."
- Do NOT overwrite cloud_uuid.
- Do NOT create any cloud resources.

### Rule 4: Cloud Ownership Mismatch
- Authenticated UID owns a shop, but local state suggests a different shop.
- If local `shopProfile.cloudUuid` is null → proceed with the owned shop.
- If local `shopProfile.cloudUuid` differs from the owned shop → REJECT with anomaly message.
- Display: "يوجد تعارض بين المتجر المحلي والمتجر السحابي المرتبط بهذا الحساب."

---

## L. SHOP RECONCILIATION RULES

### Case 1: Authenticated UID owns 0 shops
- Safe to create a new shop.
- Call `link_owner_reconcile` RPC with `p_action = 'create'`.
- RPC validates no existing owner shop under DB constraint, creates shop, returns ID.

### Case 2: Authenticated UID owns exactly 1 shop
- Reuse this shop. Do NOT create another.
- Call `link_owner_reconcile` RPC with `p_action = 'ensure'`.
- RPC validates the shop exists, ensures owner membership, returns shop ID.

### Case 3: Authenticated UID owns 2+ shops
- **ANOMALY**. This should not happen under normal operation.
- STOP. Display: "يوجد أكثر من متجر مرتبط بهذا الحساب السحابي. يرجى التواصل مع الدعم."
- Do NOT create any new resources.
- Log anomaly for server-side review.

### Case 4: Authenticated UID has membership (not owner) in shops
- The seller login path handles this (D-L3 rejects owner elevation).
- For the owner linker, this is an anomalous state — STOP.

---

## M. MEMBERSHIP RECONCILIATION RULES

### Rule 1: New Shop Creation
- The `link_owner_reconcile` RPC creates the owner membership atomically with the shop.
- No separate membership creation step needed.

### Rule 2: Existing Shop Recovery
- The `link_owner_reconcile` RPC verifies owner membership exists.
- If missing (should not happen), it creates it.
- If membership exists with a different role → anomaly STOP.

### Rule 3: Idempotency
- Calling `link_owner_reconcile` twice with the same UID and `p_action = 'ensure'`
  is safe: it returns the existing shop ID without creating a duplicate.

---

## N. DUPLICATE-SHOP PREVENTION DECISION

**Decision**: `BOTH_RECOMMENDED`

**Evidence**:

1. **Database UNIQUE constraint on `shops.owner_user_id`**:
   - Provides the ultimate safety net against duplicate owner shops.
   - Prevents race conditions from two devices/threads.
   - Prevents retry duplication.
   - Migration-compatible: preflight query can verify no legacy duplicates before applying.
   - Multi-shop-per-owner is NOT a current product requirement.
   - If needed in the future, a migration can remove the constraint (owner has no shops → add constraint is safe; owner has shops → constraint already satisfied).

2. **RPC-level guard in `link_owner_reconcile`**:
   - Provides clear, user-friendly error messages.
   - Handles the anomaly gracefully (returns error code, not a DB exception).
   - Performs the atomic check-create-ensure sequence.

3. **Why not only one**:
   - RPC-only: a direct `create_shop_with_owner` call (bypassing the new linker) could still create duplicates.
   - UNIQUE-only: DB constraint violation produces an opaque error, not a user-friendly message.
   - BOTH: defense in depth — RPC provides UX, UNIQUE provides safety net.

**Migration considerations**:
- The `shops` table currently has no legacy duplicate rows for any existing owner (verified by Supabase Auth evidence showing only one prior sign-in).
- Preflight query: `SELECT owner_user_id, count(*) FROM shops GROUP BY owner_user_id HAVING count(*) > 1` — must return empty.
- If non-empty, remediation is required before constraint application.
- The constraint should be created as: `ALTER TABLE shops ADD CONSTRAINT uniq_shops_owner_user_id UNIQUE (owner_user_id)`.

---

## O. SERVER ATOMICITY / RPC DESIGN

### Proposed RPC: `link_owner_reconcile`

```sql
-- Pseudocode — NOT executable. Design only.
CREATE OR REPLACE FUNCTION link_owner_reconcile(
  p_action TEXT DEFAULT 'ensure'  -- 'ensure' or 'create'
)
RETURNS TABLE (
  shop_id UUID,
  shop_name TEXT,
  is_new BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_existing_shop RECORD;
  v_new_shop_id UUID;
  v_new_shop_name TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- 1. Check for existing shops owned by this user
  SELECT s.id, s.name INTO v_existing_shop
  FROM shops s
  WHERE s.owner_user_id = v_user_id
  LIMIT 1;

  IF FOUND THEN
    -- 2a. Shop exists — verify owner membership
    IF NOT EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_id = v_existing_shop.id
        AND user_id = v_user_id
        AND role = 'owner'
        AND status = 'ACTIVE'
    ) THEN
      -- Membership missing or wrong role — create/fix owner membership
      INSERT INTO shop_members (shop_id, user_id, role, status, joined_at)
      VALUES (v_existing_shop.id, v_user_id, 'owner', 'ACTIVE', now())
      ON CONFLICT (shop_id, user_id) DO UPDATE
        SET role = 'owner', status = 'ACTIVE', updated_at = now();
    END IF;

    RETURN QUERY SELECT v_existing_shop.id, v_existing_shop.name, false;
    RETURN;
  END IF;

  -- 2b. No shop exists — create one only if action is 'create'
  IF p_action != 'create' THEN
    RAISE EXCEPTION 'No shop exists for this user and action is not create';
  END IF;

  -- Create shop (same logic as create_shop_with_owner but scoped)
  INSERT INTO shops (name, owner_user_id)
  VALUES ('المتجر', v_user_id)
  RETURNING id INTO v_new_shop_id;

  INSERT INTO shop_members (shop_id, user_id, role, status, joined_at)
  VALUES (v_new_shop_id, v_user_id, 'owner', 'ACTIVE', now());

  INSERT INTO roles (shop_id, name, is_system)
  VALUES
    (v_new_shop_id, 'owner', true),
    (v_new_shop_id, 'employee', true),
    (v_new_shop_id, 'salesOnly', true);

  RETURN QUERY SELECT v_new_shop_id, 'المتجر'::TEXT, true;
  RETURN;
END;
$$;
```

### Key properties

1. **Atomic**: Single transaction — no partial state.
2. **Idempotent**: Calling twice with same UID returns same result.
3. **Race-safe**: DB UNIQUE constraint on `owner_user_id` prevents duplicate creation even under concurrent calls.
4. **Server-authoritative**: Uses `auth.uid()` — client cannot spoof.
5. **SECURITY DEFINER**: Bypasses RLS for internal operations, enforces auth at function level.

### Alternative: Enhance `create_shop_with_owner` in-place

Rather than a new RPC, the existing `create_shop_with_owner` could be enhanced
with an owner-shop-exists check. However, this changes the semantics of an
existing RPC that may have callers. A new RPC is safer for backward
compatibility.

**Recommendation**: Create `link_owner_reconcile` as a new RPC. Leave
`create_shop_with_owner` unchanged (it remains useful for fresh onboarding
where no shop exists yet). Deprecation of `create_shop_with_owner` can be
considered in a future phase.

---

## P. LOCAL ATOMIC PERSISTENCE DESIGN

### Current state

`_persistIdentity` in `identity_linker.dart:220` performs three separate writes:
1. `db.update('users', {'cloud_uuid': cloudUserId}, ...)` — line 229
2. `AppSettings.setValue(AppSettings.keyShopProfileCloudUuid, shopId)` — line 237
3. `AppSettings.setValue('cloud.auth.email', email)` — line 240

These are NOT wrapped in a transaction. A crash between writes leaves partial state.

### Proposed design

Wrap all three writes in a single SQLite transaction:

```dart
Future<void> _persistIdentityAtomically({
  required int localUserId,
  required String cloudUserId,
  required String shopId,
  required String email,
}) async {
  final db = await _dbHelper.database;
  await db.transaction((txn) async {
    await txn.update(
      'users',
      {'cloud_uuid': cloudUserId},
      where: 'id = ?',
      whereArgs: [localUserId],
    );
    await txn.insert(
      'app_settings',
      {'key': AppSettings.keyShopProfileCloudUuid, 'value': shopId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await txn.insert(
      'app_settings',
      {'key': 'cloud.auth.email', 'value': email.trim()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  });
}
```

### Idempotency

- `users.cloud_uuid` is immutable once set (no-op if already matching).
- `app_settings` uses `ConflictAlgorithm.replace` — safe for repeated writes.
- The transaction is safe to retry.

### Recovery from partial write

If the transaction partially completed (e.g., crash during commit):
- `cloud_uuid` may be set but `shopProfile.cloudUuid` missing.
- `recoverOnboarding` already handles this: it looks up shops via RPC and re-persists.
- The new linker should also handle this in the idempotent re-link path (Rule 2).

---

## Q. FAILURE AND RECOVERY MATRIX

| # | Failure | User-visible behavior | Retry safe? | Local mutation? | Cloud mutation? | Manual reconciliation? |
|---|---------|----------------------|-------------|-----------------|-----------------|----------------------|
| 1 | sign-in fails (wrong password) | "بيانات الدخول غير صحيحة" | YES | NO | NO | NO |
| 2 | sign-in succeeds but get_user_shops fails | "تعذر الاتصال بالخادم" | YES | NO | NO | NO |
| 3 | shop exists but membership lookup fails | "تعذر التحقق من العضوية" | YES | NO | NO | NO |
| 4 | shop creation succeeds but response lost | On retry: shop found via get_user_shops, idempotent recovery | YES | NO (on retry) | NO (on retry) | NO |
| 5 | membership creation succeeds but local persistence fails | On retry: cloud state correct, re-persist locally | YES | YES (re-persist) | NO | NO |
| 6 | server reconciliation succeeds but app crashes before writing cloud_uuid | On restart: recoverOnboarding detects cloud state, re-persists | YES | YES (on restart) | NO | NO |
| 7 | cloud_uuid written but shop_id not written | On retry: idempotent re-link re-persists shop_id | YES | YES (re-persist) | NO | NO |
| 8 | shop_id written but cloud_uuid not written | On retry: cloud_uuid already set (immutable), re-persists shop_id | YES | YES (re-persist) | NO | NO |
| 9 | local DB transaction fails | "حدث خطأ في حفظ البيانات" | YES | NO (transaction rolled back) | Depends on server state | NO |
| 10 | retry after partial local write | Idempotent: cloud_uuid check + cloud state probe + re-persist | YES | YES (idempotent) | NO | NO |
| 11 | second device runs same flow | signIn on second device → same UID → same cloud state → idempotent link | YES | YES (idempotent) | NO | NO |
| 12 | duplicate Shop anomaly discovered | "يوجد أكثر من متجر مرتبط بهذا الحساب. يرجى التواصل مع الد 지원." | NO | NO | NO | YES |
| 13 | authenticated UID differs from local cloud_uuid | "هذا الحساب السحابي مرتبط بحساب محلي آخر" | NO (user must sign in with correct account) | NO | NO | NO |
| 14 | existing shop owner UID differs | "يوجد تعارض بين المتجر المحلي والسحابي" | NO | NO | NO | YES |
| 15 | user signs into wrong Supabase account | Same as #13 — UID mismatch detected | NO (user must sign in with correct account) | NO | NO | NO |
| 16 | session expires during flow | Supabase auto-refresh handles. If refresh fails: treated as network error | YES | NO | Depends | NO |
| 17 | RLS denial | "صلاحية غير كافية" — should not happen for owner path | NO | NO | NO | YES |
| 18 | network timeout with unknown commit state | On retry: get_user_shops probes server state before any mutation | YES | NO (probe first) | Depends on probe result | NO |

---

## R. UI/UX PLAN

### Dialog redesign

The current dialog collects email, password, AND shop name. For an existing
confirmed account, shop name should NOT be collected (the shop already exists
on the server or will be created by the RPC with a default name).

**Proposed dialog states**:

#### State 1: Initial (existing-account linking)
- Title: "ربط حساب سحابي موجود"
- Description: "سجّل الدخول بحسابك السحابي لربطه بهذا المتجر."
- Fields: email, password (NO shop name)
- Submit button: "تسجيل الدخول والربط"

#### State 2: Loading
- CircularProgressIndicator (existing pattern)

#### State 3: Success
- SnackBar: "تم ربط الحساب السحابي بنجاح. أعد تسجيل الدخول لتفعيل المزامنة."

#### State 4: Error — wrong password
- Error text: "بيانات الدخول غير صحيحة. أعد المحاولة."

#### State 5: Error — UID conflict
- Error text: "هذا الحساب السحابي مرتبط بحساب محلي آخر. سجّل الدخول بالحساب الصحيح."

#### State 6: Error — anomaly
- Error text: "يوجد حالة غير طبيعية. يرجى التواصل مع الدعم الفني."

#### State 7: Error — network
- Error text: "لا يوجد اتصال بالإنترنت — أعد المحاولة لاحقًا."

### Preserving the existing "create new account" path

The dialog must also offer a path for creating a NEW cloud account (for
owners who don't yet have one). This can be handled by:

1. Primary action: "تسجيل الدخول والربط" (signIn-first)
2. Secondary action: "إنشاء حساب سحابي جديد" (existing signUp path)

The secondary action would use the existing `linkExistingUser` method. This
preserves backward compatibility.

### Avoiding automatic confirmation email resend

When `signUp` returns `emailAlreadyRegistered`, the current code displays
"يرجى تأكيد البريد الإلكتروني". The new code avoids `signUp` entirely for
existing accounts, so this message is never triggered for the confirmed-identity case.

---

## S. SECURITY / TRUST BOUNDARIES

### Trust boundaries preserved

1. **Supabase Auth as authentication authority**: signInWithPassword is the only way to obtain an authenticated UID. No client-side UID claim.

2. **`auth.uid()` as server identity authority**: All RPCs use `auth.uid()` to determine the caller. The client never sends a trusted UUID.

3. **RLS**: All business data tables are protected by RLS. The linker RPCs use SECURITY DEFINER to bypass RLS for internal operations, but the auth check is explicit.

4. **Least privilege**: The anon key is used for client operations. No service-role key in the client.

5. **No admin shortcuts**: The linker does not use Supabase Admin API or service-role credentials.

6. **No credential logging**: Passwords are never logged, stored in governance artifacts, or persisted beyond the auth call.

7. **No token persistence in governance**: Access tokens, refresh tokens, and JWTs are never included in reports.

8. **D-L3 ownership hijack prevention**: The seller login path continues to reject owner-role memberships. The new owner linker is a separate path that does NOT weaken D-L3.

9. **cloud_uuid immutability**: Once set, `users.cloud_uuid` is never overwritten. This prevents a compromised retry from binding to a different UID.

---

## T. TEST PLAN

### Unit tests (app/test/)

| Test | Category | Description |
|------|----------|-------------|
| `signInLink_existingConfirmed_correctPassword` | Auth/linker | signIn succeeds → UID obtained → 0 shops → create → persist → success |
| `signInLink_existingConfirmed_wrongPassword` | Auth/linker | signIn fails → invalidCredentials → no mutation |
| `signInLink_existingConfirmed_nonexistentIdentity` | Auth/linker | signIn fails → invalidCredentials → no mutation |
| `signInLink_existingConfirmed_sessionEstablished` | Auth/linker | signIn succeeds → session non-null → proceed |
| `signInLink_existingConfirmed_noSession` | Auth/linker | signIn succeeds but session null → treated as error |
| `signInLink_existingConfirmed_networkError` | Auth/linker | signIn throws network error → networkUnavailable → no mutation |
| `signInLink_existingConfirmed_matchingCloudUuid` | UID binding | cloud_uuid == auth.uid → idempotent re-link → success |
| `signInLink_existingConfirmed_conflictingCloudUuid` | UID binding | cloud_uuid != auth.uid → UID_CONFLICT → no mutation |
| `signInLink_existingConfirmed_matchingShopId` | Shop reconcile | shopProfile.cloudUuid matches server shop → success |
| `signInLink_existingConfirmed_conflictingShopId` | Shop reconcile | shopProfile.cloudUuid differs from server shop → anomaly → no mutation |
| `signInLink_noShopExists_createsShop` | Shop reconcile | 0 shops → RPC create → success |
| `signInLink_oneShopExists_reusesShop` | Shop reconcile | 1 shop → RPC ensure → success |
| `signInLink_duplicateShopAnomaly_stops` | Shop reconcile | 2+ shops → anomaly → no mutation |
| `signInLink_rpcFails_network` | RPC | link_owner_reconcile throws → network error → no mutation |
| `signInLink_rpcFails_anomaly` | RPC | link_owner_reconcile returns anomaly → STOP |

### Repository/service tests

| Test | Category | Description |
|------|----------|-------------|
| `signInLink_noShopExists_rpcCreates` | Service | RPC creates shop atomically |
| `signInLink_oneShopExists_rpcEnsures` | Service | RPC ensures membership, returns existing shop |
| `signInLink_duplicateOwnerShops_rpcRejects` | Service | RPC detects anomaly, returns error |
| `signInLink_membershipMissing_rpcCreates` | Service | RPC creates owner membership for existing shop |
| `signInLink_membershipExists_rpcReturns` | Service | RPC is idempotent on re-call |

### Database/RPC tests (pgTAP)

| Test | Category | Description |
|------|----------|-------------|
| `T首创: link_owner_reconcile creates shop for new owner` | RPC | First call creates shop + membership + roles |
| `T: link_owner_reconcile is idempotent on second call` | RPC | Second call returns same shop_id |
| `T: link_owner_reconcile rejects non-authenticated` | RPC | Anonymous call raises exception |
| `T: UNIQUE constraint prevents duplicate owner shops` | DB | Second INSERT with same owner_user_id violates constraint |
| `T: link_owner_reconcile with create when shop exists returns existing` | RPC | create action returns existing shop, no duplicate |
| `T: link_owner_reconcile with ensure when no shop exists fails` | RPC | ensure action without shop raises exception |
| `T: RLS enforcement on shops table` | DB | Direct INSERT bypassing RPC is blocked by RLS |
| `T: owner membership is canonical after reconcile` | RPC | After reconcile, exactly one ACTIVE owner membership exists |

### Flutter/widget tests

| Test | Category | Description |
|------|----------|-------------|
| `signInLinkDialog_showsEmailPasswordOnly` | UI | Dialog shows email + password, no shop name |
| `signInLinkDialog_loadingState` | UI | Submitting shows spinner, disables buttons |
| `signInLinkDialog_wrongPassword_showsError` | UI | Wrong password displays Arabic error |
| `signInLinkDialog_success_showsSuccessMessage` | UI | Success displays Arabic success snackbar |
| `signInLinkDialog_uidConflict_showsConflictMessage` | UI | UID mismatch displays Arabic conflict message |
| `signInLinkDialog_networkError_showsRetryMessage` | UI | Network error displays Arabic retry message |
| `signInLinkDialog_preventsDoubleSubmit` | UI | Double tap does not trigger two signIn calls |
| `signInLinkDialog_cancelPreservesState` | UI | Cancel closes dialog, no mutation |

### Regression tests

| Test | Category | Description |
|------|----------|-------------|
| `freshOwnerOnboarding_stillWorks` | Regression | FirstOwnerSetupScreen flow unaffected |
| `alreadyLinkedAccount_recoveryStillWorks` | Regression | recoverOnboarding still functions |
| `offlineBehavior_doesNotFalselyLink` | Regression | No cloud linking without network |
| `sellerLogin_stillRejectsOwner` | Regression | D-L3 owner rejection unchanged |

---

## U. PLANNED FILE CHANGES

| # | File | Current responsibility | Planned change | Risk | Tests required |
|---|------|----------------------|----------------|------|----------------|
| 1 | `app/lib/services/identity_linker.dart` | linkExistingUser (signUp-gated) | Add `linkExistingUserViaSignIn()` method | HIGH | Unit tests for all branches |
| 2 | `app/lib/services/cloud_auth_service.dart` | signIn, signUp, RPCs | Add `linkOwnerReconcile()` RPC wrapper | LOW | Unit tests for result mapping |
| 3 | `app/lib/screens/settings_screen.dart` | Cloud-link dialog (email, password, shop name) | Redesign dialog for signIn-first flow with fallback to signUp | MEDIUM | Widget tests for all dialog states |
| 4 | `app/lib/database/user_repository.dart` | setCloudUuid, upsertCloudUser | No change needed (existing APIs sufficient) | NONE | Existing tests |
| 5 | `supabase/migrations/XXXXXX_add_unique_owner_shop.sql` | N/A (new file) | Add UNIQUE constraint on shops.owner_user_id + link_owner_reconcile RPC | HIGH | pgTAP tests |
| 6 | `app/test/unit/sign_in_linker_test.dart` | N/A (new file) | Unit tests for signIn-first linker | LOW | N/A |
| 7 | `app/test/features/existing_owner_sign_in_link_test.dart` | N/A (new file) | Widget tests for new dialog | LOW | N/A |
| 8 | `supabase/tests/p1_link_owner_reconcile.test.sql` | N/A (new file) | pgTAP tests for new RPC | LOW | N/A |

### Files NOT modified

- `app/lib/database/database_helper.dart` — no schema change needed
- `app/lib/services/seller_session_provisioning.dart` — D-L3 path unchanged
- `app/lib/services/shop_resolver.dart` — no change needed
- `app/lib/services/active_shop_context.dart` — no change needed
- `app/lib/services/tenant_isolation_gate.dart` — no change needed
- `app/lib/services/session_state.dart` — no change needed
- `app/lib/screens/auth/first_owner_setup_screen.dart` — no change needed (fresh onboarding unaffected)

---

## V. PLANNED MIGRATION/RPC CHANGES

### Migration purpose

Add a UNIQUE constraint on `shops.owner_user_id` and create the
`link_owner_reconcile` RPC function.

### Prerequisite forensic checks

Before applying the migration:

```sql
-- Check for existing duplicate owner shops
SELECT owner_user_id, count(*) as cnt
FROM shops
GROUP BY owner_user_id
HAVING count(*) > 1;
-- Must return 0 rows
```

If non-empty, remediation is required before constraint application.

### Constraint

```sql
ALTER TABLE shops
ADD CONSTRAINT uniq_shops_owner_user_id
UNIQUE (owner_user_id);
```

### RPC

See Section O for the full `link_owner_reconcile` pseudocode.

### Rollback

The migration can be rolled back by:
1. `ALTER TABLE shops DROP CONSTRAINT uniq_shops_owner_user_id;`
2. `DROP FUNCTION IF EXISTS link_owner_reconcile;`

### pgTAP coverage

See Section T for the complete pgTAP test list.

---

## W. ORDERED FUTURE IMPLEMENTATION PLAN

1. **Migration: DB invariant** — Add UNIQUE constraint on `shops.owner_user_id` with preflight duplicate check
2. **Migration: RPC** — Create `link_owner_reconcile` SECURITY DEFINER function
3. **pgTAP tests** — Verify RPC idempotency, constraint enforcement, RLS
4. **CloudAuthService: RPC wrapper** — Add `linkOwnerReconcile()` method
5. **IdentityLinker: signIn-first method** — Add `linkExistingUserViaSignIn()` with full state machine
6. **IdentityLinker: atomic local persistence** — Wrap `_persistIdentity` in SQLite transaction
7. **Settings screen: UI redesign** — New dialog for signIn-first flow with fallback
8. **Unit tests** — All branches of signIn-first linker
9. **Widget tests** — All dialog states and transitions
10. **Regression tests** — Existing flows unaffected
10. **Static validation** — `flutter analyze` clean
11. **Owner authorization** — Owner reviews and authorizes production execution

---

## X. PRODUCTION EXECUTION GOVERNANCE SPLIT

### Session A: Implementation (future)

Scope:
- Migration creation
- RPC creation
- Client code changes
- All tests
- Static validation
- Commit to branch

### Session B: Production execution (future, separate authorization)

Scope:
- Run migration against production Supabase
- Verify constraint applied
- Verify RPC deployed
- Execute owner identity link for the specific Auth identity
- Verify local persistence
- Verify cloud session establishment
- Remote lock

**The implementation must NOT automatically execute production linking.**

---

## Y. RISKS / OPEN QUESTIONS

### Risk 1: Migration on production data
The UNIQUE constraint migration must be preceded by a duplicate check. If the
production database has any shops with duplicate `owner_user_id`, the migration
will fail. This is actually the desired behavior — it forces explicit remediation.

### Risk 2: Shop name defaulting
When creating a shop via `link_owner_reconcile`, the shop name defaults to
'المتجر'. The owner may want a custom name. Options:
- (a) Accept default, rename later via existing shop settings
- (b) Pass shop name as RPC parameter
- (c) Show shop name field in dialog for the "create new" path only

**Recommendation**: Option (a) for the signIn-first path (shop already exists
or will be created with default). Option (b) as a future enhancement.

### Risk 3: Existing `create_shop_with_owner` callers
The new RPC does not replace `create_shop_with_owner`. Fresh onboarding
(`FirstOwnerSetupScreen`) continues to use `create_shop_with_owner` for the
happy path (no existing account). If a future migration adds the UNIQUE
constraint, `create_shop_with_owner` must also be updated or gated.

**Recommendation**: Add the same owner-shop-exists check to
`create_shop_with_owner` in the same migration. This prevents fresh onboarding
from creating a duplicate if the Auth identity already has a shop (e.g., owner
setup on a second device).

### Risk 4: Third-party/multi-tenant expansion
If I Tech ever supports one owner managing multiple shops, the UNIQUE
constraint must be removed. This is a clean migration (drop constraint).

### Open question: Should `create_shop_with_owner` also be updated?
The prompt asks whether `create_shop_with_owner` should get the owner-exists
guard. Given the risk of fresh onboarding on a second device creating a
duplicate, **yes** — the same migration should add a pre-check to
`create_shop_with_owner`.

---

## Z. RECOMMENDED OWNER DECISION / SUCCESSOR

**Recommended successor**: `PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_OWNER_AUTHORIZATION`

This successor session should:
1. Review this planning report
2. Authorize (or modify) the implementation plan
3. If authorized, start the implementation session

**Do NOT skip owner authorization.** Planning does not imply implementation permission.

---

**End of report.**
