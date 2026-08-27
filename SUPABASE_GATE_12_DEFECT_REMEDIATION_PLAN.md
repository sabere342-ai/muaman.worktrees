# Supabase Gate 12 Defect Remediation Plan

## A. Executive Summary

This document defines the remediation plan for two critical defects blocking Supabase Gate 12 verification for the I Tech Store Management Application (muaman_store).

**Defect 1: shop_members RLS Infinite Recursion**
The RLS policy `shop_member_isolation` on the `shop_members` table references `shop_members` in its `USING` clause subquery. Any SELECT on `shop_members` triggers policy evaluation, which executes a subquery against `shop_members`, which re-triggers the policy, causing infinite recursion.

**Defect 2: invite-employee Null user_id**
The `invite-employee` Edge Function creates a shop membership using a `user_id` derived from Supabase Auth Admin API responses. Under certain conditions (user creation race conditions, partial API failures, or existing user lookup failures), the `user_id` can be null or undefined, leading to a membership insert with null `user_id` — violating the `NOT NULL` constraint and foreign key to `auth.users`.

**Cross-Defect Interaction**
The `invite-employee` function (line 82-87) queries `shop_members` to verify the caller is an owner. This query triggers the recursive RLS policy from Defect 1, causing the authorization check itself to fail with infinite recursion. The two defects share a failure surface: any operation reading `shop_members` fails.

**Remediation Strategy**
- Forward-only migration to replace the recursive RLS policy with a non-recursive equivalent using `SECURITY DEFINER` helper functions
- Fix the `invite-employee` Edge Function to defensively validate `user_id` before membership insertion
- Add explicit `auth.uid()` checks in the helper functions to maintain tenant isolation

## B. Governing Baseline

| Property | Value |
|----------|-------|
| Repository Root | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Authorized Remote | `github` (https://github.com/sabere342-ai/muaman.worktrees.git) |
| Governing Commit | `b9ef7a7f264f6119d051cd25e07f9b1854b463ec` |
| Remote Baseline | `github/codex/i-tech-next-roadmap-freeze = b9ef7a7f264f6119d051cd25e07f9b1854b463ec` |
| Lock Tag | `supabase-deployment-migration-correction-implementation-locked` |

## C. Gate 12 Failure Context

Gate 12 requires successful Supabase deployment verification including:
- RLS policies enforce tenant isolation without recursion errors
- Edge Functions execute without null-reference failures
- Invitation lifecycle (invite → accept → membership) completes end-to-end

Current state: **BLOCKED** — Both defects prevent any `shop_members` query from succeeding, blocking membership verification, invitation acceptance, and all shop-isolated data access.

## D. Defect 1 — shop_members RLS Infinite Recursion

### D.1 Root Cause Analysis

**Affected Policy**: `shop_member_isolation` on `shop_members` (migration `20260820000010_rls_policies.sql`, lines 43-51)

```sql
CREATE POLICY shop_member_isolation ON shop_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = shop_members.shop_id
        AND sm.user_id = auth.uid()
        AND sm.status = 'ACTIVE'
    )
  );
```

**Dependency Chain**:
1. Client executes `SELECT * FROM shop_members WHERE shop_id = '...'`
2. PostgreSQL evaluates RLS policy `shop_member_isolation`
3. Policy's `USING` clause executes subquery: `SELECT 1 FROM shop_members sm WHERE ...`
4. Subquery targets `shop_members` → RLS policy `shop_member_isolation` re-evaluates
5. Step 3 repeats → **infinite recursion detected**

**Affected Operations**:
- `SELECT` on `shop_members` — always recurses
- `INSERT`/`UPDATE`/`DELETE` on `shop_members` — denied by policy (service_role only), but any `RETURNING` clause would recurse
- Any function querying `shop_members` with `SECURITY INVOKER` (default) — recurses

**Helper Functions Impacted**:
- `get_user_shops()` — queries `shop_members` via JOIN (SECURITY DEFINER, bypasses RLS ✓)
- `verify_shop_membership()` — queries `shop_members` directly (SECURITY DEFINER, bypasses RLS ✓)
- `start_trial()` — queries `shop_members` for owner check (SECURITY DEFINER, bypasses RLS ✓)

**Critical Finding**: All existing database functions use `SECURITY DEFINER` with `SET search_path = public`, so they **bypass RLS** and do not recurse. The recursion only affects:
- Direct client queries (anon/authenticated role)
- Edge Functions using the anon/authenticated client (not service_role)
- Any future `SECURITY INVOKER` functions

### D.2 Why the Policy Was Written This Way

The policy intends: "A user can read membership rows for shops where they are an active member." The self-referential query is the natural expression of this intent but fails due to PostgreSQL's RLS evaluation semantics.

### D.3 Remediation Requirements

The fix must:
1. **Remove recursion** — Policy must not reference `shop_members` in its own `USING` clause
2. **Preserve tenant isolation** — Users only see memberships for their own active shops
3. **Not introduce privilege escalation** — No user can access another shop's memberships
4. **Maintain `SECURITY DEFINER` function compatibility** — Existing functions must continue working

## E. Defect 2 — invite-employee Null user_id

### E.1 Root Cause Analysis

**Affected Code**: `supabase/functions/invite-employee/index.ts`, lines 97-167

**Failure Paths**:

**Path A — New User Creation (lines 97-150)**:
```typescript
const { data: authUser, error: createError } = await supabaseAdmin.auth.admin
  .createUser({ email, email_confirm: true, password: crypto.randomUUID() })

// If createError but "already exists", falls through to Path B
// If createError for other reason, returns error (line 146-149)
// If success, uses authUser.id (line 157)
```
Risk: `authUser` could be `null` if `createError` is falsy but `authUser` is not set (unlikely but possible in edge cases).

**Path B — Existing User Lookup (lines 106-143)**:
```typescript
const { data: existingUser } = await supabaseAdmin.auth.admin.getUserByEmail(email)
// Uses existingUser.user.id (line 114)
```
Risk: `existingUser` could be `{ user: null }` if user not found, causing `existingUser.user.id` to throw `Cannot read property 'id' of null`.

**Path C — Race Condition**:
Between `createUser` failing with "already exists" and `getUserByEmail` succeeding, another request could delete the user, making `existingUser.user` null.

### E.2 Invitation Lifecycle — Current vs. Required

**Current Lifecycle** (implicit):
```
1. Owner calls invite-employee
2. Function creates Auth user (or finds existing)
3. Function inserts shop_members with status='INVITED'
4. Function inserts invitations record with status='PENDING'
5. Employee receives invitation (email not yet implemented)
6. Employee clicks acceptance link → calls accept_invitation(p_shop_id, p_user_id)
7. accept_invitation() updates shop_members status='ACTIVE', joined_at=now()
8. accept_invitation() updates invitations status='ACCEPTED'
```

**Required Invariants**:
| Invariant | Current Status |
|-----------|----------------|
| ACTIVE MEMBERSHIP: every ACTIVE shop_members row has valid auth.users FK | ✓ (enforced by FK) |
| PENDING INVITATION ≠ ACTIVE MEMBERSHIP | ✓ (status='INVITED' vs 'ACTIVE') |
| EXACTLY-ONCE MEMBERSHIP: one acceptance → one membership | ⚠️ Race condition possible |
| TENANT AUTHORITY: invitee cannot select shop/role | ✓ (server-controlled) |
| IDEMPOTENCY: retries don't create duplicates | ⚠️ No idempotency key |
| FAILURE SAFETY: partial failure → no unauthorized membership | ⚠️ If membership inserted but invitation fails, orphan INVITED membership |

### E.3 Null user_id Specific Fix

The fix must ensure:
```typescript
// Before ANY membership insert:
if (!userId) {
  throw new Error('User ID resolution failed — cannot create membership without valid user identity')
}
```
And the `existingUser` lookup must check `existingUser.user` exists before accessing `.id`.

## F. Cross-Defect Interaction

### F.1 Shared Failure Surface

| Operation | Defect 1 Impact | Defect 2 Impact |
|-----------|-----------------|-----------------|
| `invite-employee` authorization check (line 82-87) | **FAILS** — queries `shop_members` → infinite recursion | N/A (auth check runs before user_id resolution) |
| `accept_invitation()` function | **BYPASS** — SECURITY DEFINER ignores RLS | N/A |
| `get_user_shops()` function | **BYPASS** — SECURITY DEFINER ignores RLS | N/A |
| Client-side membership queries | **FAILS** — infinite recursion | N/A |

### F.2 Root Cause Separation

**Root Cause A (Defect 1)**: Self-referential RLS policy on `shop_members` — pure database schema defect.

**Root Cause B (Defect 2)**: Missing defensive null-checks in Edge Function user_id resolution — pure application logic defect.

**Shared Failure Surface**: `invite-employee` authorization query hits Defect 1, masking Defect 2 during testing. Fixing Defect 1 will expose Defect 2.

### F.3 Remediation Order

1. Fix Defect 1 (RLS) first — unblocks all `shop_members` queries
2. Fix Defect 2 (Edge Function) second — now testable
3. Verify end-to-end invitation flow

---

## G. Forward-Only Database Remediation

### G.1 Migration Naming

Next migration number: `20260820000029` (following `20260820000028_phase_m_inventory_conflict_hardening.sql`)

Proposed filename: `20260820000029_fix_shop_members_rls_recursion.sql`

### G.2 Object Mutations

| Object | Action | Rationale |
|--------|--------|-----------|
| Policy `shop_member_isolation` on `shop_members` | `DROP POLICY` | Recursive; cannot be altered |
| Function `get_user_shop_ids()` | `CREATE OR REPLACE FUNCTION` | SECURITY DEFINER helper returning shop_ids for current user |
| Policy `shop_member_isolation_v2` on `shop_members` | `CREATE POLICY` | Non-recursive policy using helper function |
| Function `verify_shop_membership()` | `ALTER FUNCTION` (optional) | Can be simplified to use new helper |

### G.3 Helper Function Design

```sql
CREATE OR REPLACE FUNCTION get_user_shop_ids()
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_shop_ids UUID[];
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN '{}'::UUID[];
  END IF;

  SELECT ARRAY_AGG(shop_id) INTO v_shop_ids
  FROM shop_members
  WHERE user_id = v_user_id
    AND status = 'ACTIVE';

  RETURN COALESCE(v_shop_ids, '{}'::UUID[]);
END;
$$;
```

**Security Properties**:
- `SECURITY DEFINER` — runs as function owner (bypasses RLS, no recursion)
- `SET search_path = public` — prevents search_path injection
- Returns empty array for unauthenticated users — fail-closed
- No parameters — cannot be manipulated by caller
- Owner: `supabase_admin` (default for migrations)

### G.4 Replacement Policy

```sql
DROP POLICY IF EXISTS shop_member_isolation ON shop_members;

CREATE POLICY shop_member_isolation ON shop_members
  FOR SELECT USING (
    shop_id = ANY(get_user_shop_ids())
      AND status = 'ACTIVE'
  );
```

**Why This Works**:
- Policy no longer references `shop_members` in its `USING` clause
- `get_user_shop_ids()` is `SECURITY DEFINER` → executes with owner privileges → bypasses RLS → no recursion
- `shop_id = ANY(array)` is a simple scalar comparison — no subquery on `shop_members`
- Tenant isolation preserved: user only sees rows where `shop_id` is in their active shop list

### G.5 Impact on Other Policies

The other 6 RLS policies (shops, roles, role_permissions_cloud, devices, licenses, activations) all reference `shop_members` in their `USING` clauses. They **do not recurse** because:
- They are on *different* tables
- Their subqueries target `shop_members` but the policy being evaluated is on the *outer* table
- PostgreSQL evaluates RLS per-table; a policy on `shops` querying `shop_members` does not trigger the `shop_members` policy

**However**: After fixing `shop_member_isolation`, the other policies will work correctly because `shop_members` queries inside them will now use the new non-recursive policy.

### G.6 Grant/Revoke

```sql
GRANT EXECUTE ON FUNCTION get_user_shop_ids() TO authenticated, anon, service_role;
REVOKE ALL ON FUNCTION get_user_shop_ids() FROM PUBLIC;
```

Minimal privileges: only roles that need to evaluate the policy need `EXECUTE`.

### G.7 Migration Content Summary

The forward-only migration will contain:
1. `CREATE OR REPLACE FUNCTION get_user_shop_ids()...`
2. `GRANT EXECUTE...`
3. `DROP POLICY IF EXISTS shop_member_isolation ON shop_members;`
4. `CREATE POLICY shop_member_isolation ON shop_members FOR SELECT USING (shop_id = ANY(get_user_shop_ids()) AND status = 'ACTIVE');`

No modifications to historical migrations. No data migration needed.

---

## H. Edge Function Remediation

### H.1 invite-employee Fixes

**File**: `supabase/functions/invite-employee/index.ts`

**Changes Required**:

1. **Defensive user_id validation** (after line 107, before line 110):
```typescript
if (!existingUser?.user?.id) {
  return new Response(
    JSON.stringify({ success: false, error: 'Existing user lookup returned no valid user ID' }),
    { status: 500, headers: { "Content-Type": "application/json" } }
  )
}
```

2. **Defensive authUser validation** (after line 102, before line 152):
```typescript
if (!authUser?.user?.id) {
  // Attempt cleanup if membership was created (not yet at this point)
  return new Response(
    JSON.stringify({ success: false, error: 'User creation succeeded but returned no user ID' }),
    { status: 500, headers: { "Content-Type": "application/json" } }
  )
}
```

3. **Explicit user_id variable extraction** (refactor lines 110-117 and 153-160):
```typescript
const userId = existingUser?.user?.id ?? authUser?.user?.id
if (!userId) {
  return new Response(
    JSON.stringify({ success: false, error: 'Failed to resolve user ID for membership' }),
    { status: 500, headers: { "Content-Type": "application/json" } }
  )
}
// Use userId for both membership insert paths
```

4. **Idempotency improvement** (optional but recommended):
- Add `idempotency_key` parameter to request
- Check `invitations` table for existing pending invitation with same shop_id + email + idempotency_key
- Return existing invitation if found

### H.2 accept_invitation Function — No Changes Required

The `accept_invitation()` SQL function (migration `20260820000022_add_accept_invitation.sql`) is correct:
- Requires both `p_shop_id` and `p_user_id` (validated at line 22)
- Finds pending membership by exact `(shop_id, user_id, status='INVITED')` (lines 27-31)
- Updates to `ACTIVE` with `joined_at` (lines 38-40)
- Updates `invitations` record by email lookup (lines 43-47)
- Uses `SECURITY DEFINER` with `SET search_path = public` — safe

**One Observation**: Line 46 uses `(SELECT email FROM auth.users WHERE id = p_user_id)` which assumes the auth user exists. This is valid because the FK `shop_members.user_id REFERENCES auth.users(id)` guarantees it.

### H.3 Edge Function Deployment

No schema changes required. Deployment is a separate `supabase functions deploy invite-employee` step after the database migration.

---

## I. Security and Tenant-Isolation Proof Obligations

### I.1 Defect 1 Remediation — Proof Obligations

| Obligation | Verification Method |
|------------|---------------------|
| **No recursion** | `EXPLAIN ANALYZE SELECT * FROM shop_members WHERE shop_id = '...'` shows no "infinite recursion detected" error |
| **Tenant isolation** | User A (shop 1) cannot SELECT shop_members rows for shop 2 |
| **Active-only access** | User with status='SUSPENDED' sees zero rows |
| **Unauthenticated denial** | anon role sees zero rows |
| **SECURITY DEFINER safety** | `get_user_shop_ids()` has fixed `search_path`, no SQL injection surface |
| **Least privilege** | `GRANT EXECUTE` only to `authenticated`, `anon`, `service_role` |

### I.2 Defect 2 Remediation — Proof Obligations

| Obligation | Verification Method |
|------------|---------------------|
| **No null user_id insert** | Unit test: call invite-employee with mocked Auth API returning `{ user: null }` → expect 500, no membership insert |
| **Existing user lookup safety** | Unit test: `getUserByEmail` returns `{ user: null }` → expect 500 |
| **Auth user creation safety** | Unit test: `createUser` returns `{ user: null, error: null }` → expect 500 |
| **FK enforcement** | Integration test: attempt insert with invalid UUID → expect FK violation |
| **Idempotency** | Integration test: two identical requests → one membership, one invitation |

### I.3 Cross-Cutting Security

| Property | Verification |
|----------|--------------|
| **No privilege escalation** | Non-owner cannot invite to shop; non-member cannot read shop data |
| **No cross-shop leakage** | User in shop A cannot see shop B's members, roles, devices, licenses |
| **Service role containment** | Edge Function uses service_role only for admin operations; user verification uses anon client with user JWT |

---

## J. Migration / Compatibility Analysis

### J.1 Forward-Only Migration Compatibility

| Aspect | Assessment |
|--------|------------|
| **Backward compatibility** | New policy returns same results for valid queries; only fixes recursion |
| **Existing functions** | `get_user_shops()`, `verify_shop_membership()`, `start_trial()` unchanged — all `SECURITY DEFINER` |
| **Edge Functions** | `invite-employee` uses service_role for membership queries — bypasses RLS entirely |
| **Client applications** | Any direct `shop_members` queries will now work instead of erroring |
| **Rollback** | `DROP POLICY` + `CREATE POLICY` is reversible; helper function can be dropped |

### J.2 Migration Ledger Verification

Pre-deployment checklist:
- [ ] Verify current migration ledger: `supabase migration list` shows up to `20260820000028`
- [ ] Confirm no pending local migrations
- [ ] Record migration checksum pre-deployment

Post-deployment checklist:
- [ ] Verify `20260820000029` appears in ledger
- [ ] Verify migration checksum matches local file
- [ ] Verify no "revert" or "down" migration was generated

### J.3 Database Function Compatibility

The new `get_user_shop_ids()` function:
- Does not conflict with existing function names
- Uses only `shop_members` and `auth.uid()` — stable dependencies
- Returns `UUID[]` — compatible with `= ANY()` operator
- Can be used by future policies/functions

---

## K. Automated Test Strategy

### K.1 RLS Regression Tests (SQL/pgTAP or Supabase CLI)

**Test File**: `supabase/tests/rls_shop_members_recursion.test.sql` (to be created)

```sql
-- Test 1: Own-shop membership query succeeds
SELECT * FROM shop_members WHERE shop_id = 'shop-uuid-1';
-- Expect: rows returned, no recursion error

-- Test 2: Cross-shop membership query denied
-- (as user in shop 1, query shop 2)
SELECT * FROM shop_members WHERE shop_id = 'shop-uuid-2';
-- Expect: 0 rows, no error

-- Test 3: Anonymous access denied
SET ROLE anon;
SELECT * FROM shop_members;
-- Expect: 0 rows

-- Test 4: shop_members SELECT no longer recurses
-- Direct test of the fixed policy
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM shop_members WHERE shop_id = '...';
-- Expect: no "infinite recursion detected in policy" in output

-- Test 5: Authorized INSERT succeeds (service_role)
SET ROLE service_role;
INSERT INTO shop_members (shop_id, user_id, role, status) VALUES (...);
-- Expect: success

-- Test 6: Unauthorized INSERT denied (authenticated)
SET ROLE authenticated;
INSERT INTO shop_members (shop_id, user_id, role, status) VALUES (...);
-- Expect: permission denied (no policy for INSERT)

-- Test 7: Authorized UPDATE succeeds (service_role)
SET ROLE service_role;
UPDATE shop_members SET status = 'ACTIVE' WHERE ...;
-- Expect: success

-- Test 8: Unauthorized UPDATE denied (authenticated)
SET ROLE authenticated;
UPDATE shop_members SET status = 'ACTIVE' WHERE ...;
-- Expect: permission denied

-- Test 9: Authorized DELETE succeeds (service_role)
SET ROLE service_role;
DELETE FROM shop_members WHERE ...;
-- Expect: success

-- Test 10: Unauthorized DELETE denied (authenticated)
SET ROLE authenticated;
DELETE FROM shop_members WHERE ...;
-- Expect: permission denied

-- Test 11: Helper function returns correct shop IDs
SELECT get_user_shop_ids();
-- Expect: array of shop_ids for current user

-- Test 12: Helper function returns empty for unauthenticated
SET ROLE anon;
SELECT get_user_shop_ids();
-- Expect: '{}'
```

### K.2 Invitation Flow Tests (Edge Function / TypeScript)

**Test File**: `supabase/functions/invite-employee/index.test.ts` (to be created)

```typescript
// Test 1: Unauthenticated caller → 401
// Test 2: Non-member caller → 403
// Test 3: Member without owner role → 403
// Test 4: Authorized owner → 200, membership created
// Test 5: New email address → Auth user created, membership INVITED
// Test 6: Existing Supabase Auth user → membership INVITED, no new Auth user
// Test 7: Duplicate pending invitation → 409 or idempotent success
// Test 8: Already-active member → 409 conflict
// Test 9: Expired invitation → (accept_invitation handles this)
// Test 10: Invalid role → 400
// Test 11: Cross-shop role misuse → 403 (owner of shop A cannot invite to shop B)
// Test 12: Auth API failure (network) → 500, no partial membership
// Test 13: Database failure (membership insert) → 500, no Auth user orphan (or cleanup)
// Test 14: Missing/null Auth identity in response → 500, no membership insert
// Test 15: Retry after partial failure → idempotent, no duplicates
// Test 16: Successful invitation acceptance → membership ACTIVE, joined_at set
// Test 17: Membership created exactly once per acceptance
// Test 18: Correct role persisted
// Test 19: Correct shop_id persisted
// Test 20: Correct permissions via roles/role_permissions_cloud
```

### K.3 Test Execution

```bash
# RLS tests
supabase db test --files supabase/tests/rls_shop_members_recursion.test.sql

# Edge Function tests
deno test supabase/functions/invite-employee/index.test.ts
```

---

## L. Integration Test Strategy

### L.1 End-to-End Invitation Flow

**Scenario**: Complete invitation lifecycle from owner invite → employee accept → active membership

```typescript
// Integration test: invite-accept-verify
async function testInvitationLifecycle() {
  // 1. Setup: Create shop, owner user
  const shopId = await createShopWithOwner(ownerToken);
  
  // 2. Owner invites employee
  const inviteResp = await inviteEmployee(ownerToken, {
    shop_id: shopId,
    email: 'employee@test.com',
    role: 'employee'
  });
  expect(inviteResp.success).toBe(true);
  const employeeUserId = inviteResp.user_id;
  
  // 3. Verify membership exists with INVITED status
  const membership = await getMembership(shopId, employeeUserId);
  expect(membership.status).toBe('INVITED');
  
  // 4. Verify invitation record exists
  const invitation = await getInvitation(shopId, 'employee@test.com');
  expect(invitation.status).toBe('PENDING');
  
  // 5. Employee accepts (simulate via accept_invitation RPC)
  const acceptResp = await acceptInvitation(employeeToken, shopId, employeeUserId);
  expect(acceptResp.success).toBe(true);
  
  // 6. Verify membership is now ACTIVE
  const activeMembership = await getMembership(shopId, employeeUserId);
  expect(activeMembership.status).toBe('ACTIVE');
  expect(activeMembership.joined_at).not.toBeNull();
  
  // 7. Verify invitation is ACCEPTED
  const acceptedInvitation = await getInvitation(shopId, 'employee@test.com');
  expect(acceptedInvitation.status).toBe('ACCEPTED');
  
  // 8. Verify NO RLS recursion on any query
  const members = await listMembers(employeeToken, shopId);
  expect(members.length).toBeGreaterThan(0);
  
  // 9. Verify cross-shop denial
  const otherShopMembers = await listMembers(employeeToken, otherShopId);
  expect(otherShopMembers).toEqual([]);
}
```

### L.2 Cross-Tenant Isolation Verification

```typescript
async function testCrossTenantIsolation() {
  // User A in Shop 1, User B in Shop 2
  // User A queries Shop 2 data via all 7 tables
  const tables = ['shops', 'shop_members', 'roles', 'role_permissions_cloud', 'devices', 'licenses', 'activations'];
  
  for (const table of tables) {
    const result = await queryAsUserA(`SELECT * FROM ${table} WHERE shop_id = 'shop-2-uuid'`);
    expect(result.rows).toHaveLength(0);
  }
}
```

### L.3 Performance Baseline

- Measure `shop_members` query latency before/after fix
- Ensure helper function adds <5ms overhead
- Verify no sequential scans on `shop_members` (index usage)

---

## M. Production Deployment Sequence

**Pre-Requisites**:
- [ ] Local migration file created and reviewed
- [ ] Edge Function changes tested locally
- [ ] All automated tests passing
- [ ] Production Supabase project ID confirmed
- [ ] Service role key available (securely)
- [ ] Migration ledger baseline recorded

**Deployment Steps**:

| Step | Action | Verification | Rollback Trigger |
|------|--------|--------------|------------------|
| 1 | `supabase db push --linked` (deploy migration 000029) | Migration appears in `supabase migration list`; no errors | Migration fails → stop, investigate |
| 2 | `supabase functions deploy invite-employee` | Function version updated; `ACTIVE` status | Function deploy fails → stop, do NOT proceed |
| 3 | Verify migration ledger: `supabase migration list` | 000029 present with correct checksum | Mismatch → investigate before proceeding |
| 4 | Verify Edge Function: `supabase functions list` | `invite-employee` shows latest version | Version mismatch → redeploy |
| 5 | Execute Gate 12 RLS verification (Section N) | All RLS tests pass | Any failure → Section O |
| 6 | Execute invitation lifecycle verification (Section N) | All flow tests pass | Any failure → Section O |
| 7 | Verify cross-shop denial (Section N) | Isolation tests pass | Any failure → Section O |
| 8 | Inspect production logs (15 min) | No recursion errors; no 500s on invite/accept | Errors → Section O |
| 9 | Capture forensic evidence | Screenshots, logs, test outputs | — |
| 10 | Classify final PASS/BLOCKED | All criteria met → PASS | Any BLOCKED → Section O |

**Timing**: Estimated 30 minutes total deployment + verification window.

**Personnel**: One operator with Supabase CLI access and production credentials.

---

## N. Gate 12 Reverification Sequence

### N.1 RLS Verification (Automated)

```bash
# Run against production (read-only)
supabase db test --files supabase/tests/rls_shop_members_recursion.test.sql --linked
```

**Pass Criteria**:
- All 12 RLS tests pass
- Zero "infinite recursion detected" errors in logs
- Query latency <100ms for typical shop_members queries

### N.2 Invitation Lifecycle Verification (Automated + Manual)

```bash
# Automated Edge Function tests
deno test supabase/functions/invite-employee/index.test.ts --allow-net --allow-env
```

**Manual Verification Checklist**:
- [ ] Owner can invite new email → membership INVITED created
- [ ] Owner can invite existing Auth user → membership INVITED created
- [ ] Duplicate invitation attempt → handled gracefully (409 or idempotent)
- [ ] Non-owner cannot invite → 403
- [ ] Employee accepts invitation → membership ACTIVE, joined_at set
- [ ] Accepted invitation → status ACCEPTED
- [ ] Employee can now query shop data (no recursion)
- [ ] Employee cannot query other shops

### N.3 Cross-Shop Denial Verification

```bash
# As user in shop A, attempt to access shop B data
for table in shops shop_members roles role_permissions_cloud devices licenses activations; do
  result=$(psql "postgresql://..." -c "SELECT * FROM $table WHERE shop_id = 'shop-B-uuid';")
  assert_empty "$result"
done
```

### N.4 Production Log Inspection

Monitor for 15 minutes post-deployment:
- `supabase functions logs invite-employee --linked`
- PostgreSQL logs: `ERROR: infinite recursion detected`
- Application error tracking (if integrated)

**Pass Criteria**: Zero recursion errors; zero 500s on invite/accept endpoints.

---

## O. Rollback / Failure Recovery

### O.1 SQL Migration Deployment Failure

**Symptoms**: `supabase db push` fails with syntax error, permission error, or lock timeout.

**Recovery**:
1. Do NOT retry blindly — read the error
2. If syntax/schema error: fix migration locally, generate new migration (000030), re-deploy
3. If lock timeout: wait, retry once
4. If permission error: verify service role privileges

**No Rollback Needed**: Forward-only migration not yet applied.

### O.2 Edge Function Deployment Failure

**Symptoms**: `supabase functions deploy` fails (bundle error, quota, network).

**Recovery**:
1. Fix build error locally
2. Re-deploy
3. If quota exceeded: request limit increase

**Critical**: If migration (Step 1) succeeded but function deploy (Step 2) fails:
- The database fix is live but Edge Function is old version
- Old function will now work (RLS fixed) but may have null user_id bug
- **Do NOT revert migration** — deploy function fix ASAP
- If function fix cannot deploy within 1 hour: consider temporary maintenance mode

### O.3 Post-Deployment Verification Failure

**Scenario**: Migration + function deployed, but Gate 12 tests fail.

**Failure Modes & Responses**:

| Failure | Response |
|---------|----------|
| RLS recursion still occurs | Migration not applied correctly; check `supabase migration list`; if missing, re-push |
| New policy too restrictive (legitimate queries denied) | Check `get_user_shop_ids()` logic; may need `SECURITY DEFINER` function fix → forward migration 000030 |
| Invitation flow fails (null user_id persists) | Edge Function fix not deployed; verify function version; re-deploy |
| Cross-shop leakage | Policy logic error; analyze `get_user_shop_ids()` return value; forward migration 000030 |
| Performance regression | Check query plans; add index if needed; forward migration 000030 |

**Forward Correction Preferred**: Always prefer a new forward migration (000030, 000031...) over attempting to revert. Reverting a deployed migration requires `supabase db reset` or manual `DOWN` SQL which is destructive and risky.

### O.4 New Authorization Defect Discovered

**Response**:
1. Document the defect precisely
2. Assess severity (data leakage vs. availability)
3. If critical (data leakage): enable maintenance mode, deploy forward correction
4. If non-critical: schedule forward correction in next maintenance window
5. Never silently disable RLS or grant excessive privileges

### O.5 Safe Stop Without History Rewrite

If full rollback is required (extreme case):
1. Disable Edge Function: `supabase functions delete invite-employee --linked` (removes from API gateway)
2. Database: Create forward migration `000030_revert_rls_fix.sql` that:
   - Drops `get_user_shop_ids()`
   - Drops `shop_member_isolation` (v2)
   - Recreates original recursive policy (documented for reference only)
3. **Never** use `git reset`, `git push --force`, or Supabase dashboard "revert" on production

---

## P. Explicit Non-Goals

This remediation plan **does not** include:

- [ ] Editing any existing deployed migration (000001–000028)
- [ ] Writing the actual repair migration (000029) — this plan only specifies its content
- [ ] Modifying `invite-employee/index.ts` — this plan only specifies required changes
- [ ] Deploying anything to production
- [ ] Modifying production database state
- [ ] Repairing existing corrupted data (e.g., orphaned INVITED memberships)
- [ ] Git push to any remote
- [ ] Git tag creation or push
- [ ] Declaring Gate 12 passed — this plan enables verification, verification is separate
- [ ] Implementing email delivery for invitations (noted as TODO in function)
- [ ] Adding idempotency keys to invitation API (recommended but not required for Gate 12)
- [ ] Modifying `accept_invitation()` function (currently correct)
- [ ] Changing `SECURITY DEFINER` to `SECURITY INVOKER` on any existing function

---

## Q. Implementation Session Scope

**Authorized Implementation Session** (separate from this planning session):

| Task | Owner | Dependencies |
|------|-------|--------------|
| Create migration `20260820000029_fix_shop_members_rls_recursion.sql` | DB Engineer | This plan approved |
| Apply migration to local/staging | DB Engineer | Migration created |
| Run RLS regression tests on staging | QA | Migration applied |
| Implement Edge Function fixes in `invite-employee/index.ts` | Backend Engineer | This plan approved |
| Deploy Edge Function to staging | Backend Engineer | Code changes committed |
| Run invitation flow tests on staging | QA | Function deployed |
| Run integration tests on staging | QA | Both deployed |
| Prepare production deployment runbook | Release Engineer | Staging verified |

**This Planning Session Scope**:
- [x] Document root causes
- [x] Define remediation architecture
- [x] Specify test strategies
- [x] Define deployment sequence
- [x] Define rollback procedures
- [x] Obtain approval for implementation session

---

## R. Required Approvals and Acceptance Criteria

### R.1 Approvals Required Before Implementation

| Role | Approval | Criteria |
|------|----------|----------|
| Tech Lead | Architecture | Root causes correctly identified; forward-only strategy; no privilege escalation |
| Security Reviewer | RLS Fix | Helper function `SECURITY DEFINER` with fixed search_path; least privilege grants |
| DBA | Migration | Forward-only; no data migration; reversible via forward migration |
| Backend Lead | Edge Function | Null checks added; no behavior change for success path |
| Release Manager | Deployment Plan | Sequence defined; rollback procedures documented; no history rewrite |

### R.2 Gate 12 Acceptance Criteria (Definition of Done)

| Criterion | Measurement | Pass Threshold |
|-----------|-------------|----------------|
| **RLS Recursion Eliminated** | `SELECT` on `shop_members` returns results or empty set, never "infinite recursion detected" | 0 recursion errors in 100 test queries |
| **Tenant Isolation Preserved** | Cross-shop queries return 0 rows for all 7 tables | 100% denial rate |
| **Invitation Flow Works** | Owner invite → employee accept → active membership | 10/10 successful end-to-end runs |
| **Null user_id Prevented** | Edge Function returns 500 (not 500 with FK error) when Auth API returns no user ID | 100% of negative test cases |
| **No Regression** | All existing functions (`get_user_shops`, `verify_shop_membership`, `start_trial`) work unchanged | 100% existing test suite passes |
| **Performance** | `shop_members` query latency | <100ms p95 |
| **Migration Ledger Clean** | `supabase migration list` shows 000029 applied, no pending, no failed | Clean ledger |
| **Edge Function Version** | `supabase functions list` shows latest deployed version | Version matches commit |

### R.3 Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tech Lead | | | |
| Security Reviewer | | | |
| DBA | | | |
| Backend Lead | | | |
| Release Manager | | | |

---

## Appendix: Migration File Template

```sql
-- 20260820000029_fix_shop_members_rls_recursion.sql
-- Fixes: shop_members RLS infinite recursion (Defect 1)
-- Strategy: Replace self-referential policy with SECURITY DEFINER helper function

-- 1. Helper function: returns active shop_ids for current user
CREATE OR REPLACE FUNCTION get_user_shop_ids()
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_shop_ids UUID[];
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN '{}'::UUID[];
  END IF;

  SELECT ARRAY_AGG(shop_id) INTO v_shop_ids
  FROM shop_members
  WHERE user_id = v_user_id
    AND status = 'ACTIVE';

  RETURN COALESCE(v_shop_ids, '{}'::UUID[]);
END;
$$;

COMMENT ON FUNCTION get_user_shop_ids IS 'Returns array of shop_ids where the authenticated user has ACTIVE membership. SECURITY DEFINER to bypass RLS and avoid recursion.';

-- 2. Grant minimal execute privileges
GRANT EXECUTE ON FUNCTION get_user_shop_ids() TO authenticated, anon, service_role;
REVOKE ALL ON FUNCTION get_user_shop_ids() FROM PUBLIC;

-- 3. Drop recursive policy
DROP POLICY IF EXISTS shop_member_isolation ON shop_members;

-- 4. Create non-recursive policy using helper
CREATE POLICY shop_member_isolation ON shop_members
  FOR SELECT USING (
    shop_id = ANY(get_user_shop_ids())
      AND status = 'ACTIVE'
  );

COMMENT ON POLICY shop_member_isolation ON shop_members IS 'Non-recursive shop isolation: user sees memberships only for their active shops. Uses get_user_shop_ids() helper (SECURITY DEFINER).';
```