# Phase P / Group D / D1 — Corrective Remediation Governance

**Session result:** PASS — D1 corrective remediation governance artifact created, committed, remote-locked, STOPPED.

**Classification:** POST_IMPLEMENTATION_FORENSIC_REMEDIATION_GOVERNANCE

**Scope governed:** Forensic review of existing D1 implementation, identification of two functional/security blockers, authorization of corrective remediation implementation for a future session. No implementation performed this session.

---

## A. Session Result

```text
D1_REPOSITORY_REMOTE_LOCK = PASS
D1_ORIGINAL_IMPLEMENTATION_COMMIT_EXISTS = YES

D1_FUNCTIONAL_COMPLETION = NOT_YET_SATISFIED
D1_SECURITY_COMPLETION = NOT_YET_SATISFIED

D1_STATE = REMOTE_LOCKED_WITH_REMEDIATION_REQUIRED

D2_START_AUTHORIZED = NO
D3_START_AUTHORIZED = NO

CORRECTIVE_GOVERNANCE_REMOTE_LOCKED = YES (after push)
CORRECTIVE_REMEDIATION_IMPLEMENTATION_AUTHORIZED = YES
IMPLEMENTATION_PERFORMED_THIS_SESSION = NO
```

---

## B. Repository Identity

```text
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_ORIGIN     = SACRED / MUST NOT BE CONTACTED
LEGACY_ORIGIN_CONTACTED = NO
```

---

## C. Entry / Recovery Classification

```text
CASE_A_FRESH
```

Verified:

```text
LOCAL_HEAD                    = 0d65c1324b18411ee516c04a66750aca65349a40
TRACKING_HEAD                 = 0d65c1324b18411ee516c04a66750aca65349a40
DIRECT_GITHUB_REMOTE_HEAD     = 0d65c1324b18411ee516c04a66750aca65349a40
MERGE_BASE                    = 0d65c1324b18411ee516c04a66750aca65349a40
AHEAD                         = 0
BEHIND                        = 0
TRACKED_WORKTREE              = CLEAN (no tracked changes)
INDEX                         = EMPTY
ACTIVE_MERGE/REBASE/CHERRY_PICK = NONE
```

No CASE_B / CASE_C / CASE_D condition was present. No destructive recovery was used or needed.

---

## D. Exact Entry Remote-Lock Proof

```text
LOCAL         = 0d65c1324b18411ee516c04a66750aca65349a40
TRACKING      = 0d65c1324b18411ee516c04a66750aca65349a40
DIRECT_REMOTE = 0d65c1324b18411ee516c04a66750aca65349a40   (git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze)
MERGE_BASE    = 0d65c1324b18411ee516c04a66750aca65349a40
AHEAD         = 0
BEHIND        = 0
```

All three points (local, tracking, direct remote) are identical. Clean entry confirmed.

---

## E. Authority Chain

```text
PHASE_P_OWNER_DECISIONS.md
  -> POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md
    -> Defines Group D scope: P-OD4, P-OD5, P-OD6, WS-9

OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md
  -> GROUP_B_BEFORE_GROUP_D

Group B S1-S12 (S12 closed at 154a9703...)
  -> GROUP_B_CLOSED = YES

... -> Group D Planning Governance (a6c39934...)
  -> GROUP_D_IMPLEMENTATION_AUTHORIZED = YES

... -> D1 Implementation (0d65c1324...) [REMOTE LOCKED]
  -> Two forensic blockers identified
  -> THIS SESSION: Corrective remediation governance
```

```text
AUTHORITY_CHAIN_VERIFIED = YES
```

---

## F. D1 Existing Implementation Forensic Proof

### D1 Implementation Commit

```text
D1_COMMIT             = 0d65c1324b18411ee516c04a66750aca65349a40
D1_PARENT             = a6c39934ad6fa3440cccf233cb4c72b048b9272e
D1_TREE               = e099555dad41c24e5736f0cbf4632c467e2f6767
D1_MESSAGE            = feat: implement Phase P Group D D1 cost change history
D1_FILES_CHANGED      = 8
D1_DELTA              = +910 / -1
```

### D1 Files

```text
app/lib/database/database_helper.dart              | 176 ++++++++++++-
app/lib/models/cost_history.dart                   |  51 ++++
app/lib/screens/inventory/inventory_screen.dart    |  58 +++++
app/test/database/cost_history_test.dart           | 289 +++++++++++++++++++++
app/test/features/enter_key_behavior_test.dart     |   5 +
app/test/helpers/test_schema.dart                  |  22 ++
supabase/migrations/20260820000036_..._cost_history.sql | 193 ++++++++++++++
supabase/tests/d1_cost_history_rls.test.sql        | 117 +++++++++
```

### Group D Governance Artifact Verified

```text
GOVERNANCE_ARTIFACT = docs/PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md
GOVERNANCE_BLOB     = 31705653c5044cf0f61a7db743e825e9f7c12d1c
```

### D1 Governed Contract (from Group D planning governance, Section T)

```text
OBJECTIVE          = Implement cost-change warning and non-destructive choice workflow
ALLOWED_DELTA      = additive cost_history table (local SQLite + optional cloud),
                     cost-change warning dialog in inventory_screen.dart,
                     "create new item" option on cost change,
                     database_helper.dart additive methods
TESTS              = cost-change warning tests, cost history persistence tests, new-item-creation tests
COMPLETION_EVIDENCE = warning dialog appears on cost change; cost history recorded;
                      "create new item" creates new product; existing sales unaffected
STOP_CONDITION     = cost-change warning visible; cost history queryable;
                      new-item creation works; existing tests pass
```

---

## G. Blocker A — Missing Non-Destructive New-Item Workflow

### Finding

```text
BLOCKER_A_CONFIRMED = YES
D1_FUNCTIONAL_COMPLETION = NOT_SATISFIED
```

### Evidence

The governed D1 contract requires the cost-change decision to offer three semantic outcomes:

```text
A = accept/update cost on current product
B = create a NEW distinct product instead
C = cancel
```

The actual D1 implementation in `inventory_screen.dart` (lines 369-411) provides only:

```text
C = "إلغاء" (Cancel)
A = "تأكيد التغيير" (Confirm change)
```

There is no `"create new item"` / `"إنشاء صنف جديد"` path. The `_showCostChangeWarning` dialog returns `bool?` — `true` for confirm, `false` for cancel. There is no third option.

### Detailed Inspection

`_showCostChangeWarning` (line 373-411):
- Returns `showDialog<bool>` with two actions: Cancel (`false`) and Confirm change (`true`)
- No third button or alternative flow exists
- If user confirms, the existing product's cost is updated in place (lines 249-256)

`saveProduct()` (line 211-293):
- On confirm, calls `DatabaseHelper.instance.updateProduct(...)` which mutates the existing product
- No branch exists to create a new product record instead

### Test Evidence

`cost_history_test.dart` — 12 tests covering:
1. Unchanged cost produces no history entry
2. Cost change produces exactly one history entry
3. Old and new cost captured correctly
4. Correct product identity captured
5. Correct shop identity captured
6. Repeated changes create ordered transitions
7. Existing sale cost snapshot remains unchanged
8. Unauthorized role cannot gain mutation authority
9. Cross-shop history access fails
10. Malformed/invalid cost input fails safely
11. v18 -> v19 migration is additive and idempotent
12. Product update and history insert are transactionally coherent

**No test covers:** changing cost -> choosing "create new item" -> old product remains intact -> distinct product is created.

`enter_key_behavior_test.dart` (line 232-234):
- Verifies the warning dialog appears and "تأكيد التغيير" confirms the change
- No test for a third option

### Conclusion

The D1 implementation is functionally incomplete with respect to the governed contract. The `"create new item"` path — which is a core non-destructive safety mechanism — was not implemented.

---

## H. Blocker B — SECURITY DEFINER RPC Tenant/RBAC Bypass

### Finding

```text
BLOCKER_B_CONFIRMED = YES
D1_SECURITY_COMPLETION = NOT_SATISFIED
```

### Evidence

Migration `00036` creates three SECURITY DEFINER functions:

#### 1. `insert_cloud_cost_history(...)` (lines 102-129)

```sql
SECURITY DEFINER
SET search_path = public
-- Body: plain INSERT using p_shop_id as provided by caller
INSERT INTO cloud_cost_history (shop_id, ...) VALUES (p_shop_id, ...);
```

#### 2. `get_cloud_cost_history_by_product(p_shop_id, p_product_id)` (lines 132-162)

```sql
SECURITY DEFINER
SET search_path = public
-- Body: SELECT WHERE ch.shop_id = p_shop_id
```

#### 3. `get_cloud_cost_history_by_shop(p_shop_id)` (lines 165-193)

```sql
SECURITY DEFINER
SET search_path = public
-- Body: SELECT WHERE ch.shop_id = p_shop_id
```

### Security Analysis

All three functions:

| Check | Required | Present |
|-------|----------|---------|
| `auth.uid()` is non-null | YES | NO |
| Caller is active member of `p_shop_id` | YES | NO |
| Caller has appropriate role | YES | NO |
| Cross-shop `p_shop_id` rejected | YES | NO |
| `search_path` fixed | YES | YES |

### Cross-Shop Attack Vector

An authenticated user who is a member of Shop A can:

```text
SELECT * FROM get_cloud_cost_history_by_shop('<Shop-B-UUID>');
INSERT INTO cloud_cost_history(...) -- via insert function
```

The SECURITY DEFINER runs as the function owner, bypassing table RLS. The function body blindly trusts the caller-supplied `p_shop_id` parameter with no authorization check. This violates the fundamental tenant isolation invariant.

### Established Project Pattern

The project's canonical SECURITY DEFINER pattern uses `require_shop_permission(p_shop_id, permission)` as the first statement in every RPC function body. This function (defined in migration 00034, lines 987-1060) performs:

1. `auth.uid()` non-null check (authentication)
2. ACTIVE membership check for the caller in `p_shop_id` (shop membership)
3. Device gate check if enabled (request-bound device approval)
4. License/entitlement check (entitlement enforcement)
5. Owner bypass for full authority
6. RBAC permission resolution via `check_effective_permission()`

Example from `create_cloud_product` (migration 00025, line 331):

```sql
PERFORM require_shop_permission(p_shop_id, 'inventory.edit');
```

The D1 functions do NOT call `require_shop_permission` or any equivalent. Every other SECURITY DEFINER function in the codebase (70+ instances across migrations 00020-00035) follows this pattern. The D1 functions are the sole exception.

### pgTAP Test Coverage Gap

The existing `d1_cost_history_rls.test.sql` contains 20 assertions but they are entirely structural:

| Test | Type | Covers |
|------|------|--------|
| T1 | Structural | Table exists |
| T2 | Structural | RLS enabled |
| T3a-f | Structural | Columns exist |
| T4a | Structural | shop_id type |
| T5a-b | Structural | NOT NULL constraints |
| T6 | Structural | Function exists |
| T7 | Structural | Function exists |
| T8 | Structural | Function exists |
| T9-T10 | Structural | Indexes exist |
| T11-T12 | Structural | No permissive true policies |
| T13-T14 | Structural | Policy names exist |

**Zero behavioral RPC authorization tests.** No test invokes any RPC under an authenticated identity and proves cross-shop access is denied.

### Conclusion

The D1 migration introduces a tenant-isolation security gap in three SECURITY DEFINER functions that bypass the established `require_shop_permission` authorization pattern. The pgTAP tests validate structure but not security behavior.

---

## I. Migration 00036 Immutability Classification

```text
MIGRATION_00036 = IMMUTABLE_HISTORICAL_D1_MIGRATION_SOURCE
MIGRATION_00036_MODIFIED_THIS_SESSION = NO
MIGRATION_00036_MODIFIED_FUTURE_SESSION = FORBIDDEN

PRODUCTION_00036_APPLIED = NO (from governance evidence; no production connection performed)
```

Migration 00036 is committed in the remote-locked D1 implementation. The Group D planning governance established:

```text
no modification of existing migrations
```

Therefore, migration 00036 cannot be silently rewritten. Its functions/tables exist as-is in the migration history. Corrective security must be delivered via an additive successor migration.

---

## J. Corrective Migration Strategy

```text
CORRECTIVE_MIGRATION = 00037
CORRECTIVE_MIGRATION_PATH = supabase/migrations/20260820000037_phase_p_group_d_d1_security_remediation.sql
MIGRATION_00037_IMPLEMENTED_THIS_SESSION = FORBIDDEN
```

### Strategy: Hardened SECURITY DEFINER with require_shop_permission

The project's established pattern (`require_shop_permission`) is the correct remediation strategy. SECURITY DEFINER is retained because:

1. It is the universal project pattern (70+ functions)
2. It allows the function to bypass table RLS while performing its own authorization
3. It is compatible with the existing RBAC/entitlement/device-gate infrastructure
4. Switching to SECURITY INVOKER would require verifying that the `authenticated` role has direct table privileges AND that RLS correctly enforces the same invariants — a strictly larger security surface with no benefit

### Corrective Migration Actions

Migration 00037 must:

1. **DROP and re-CREATE** the three affected functions with `require_shop_permission` authorization:

```sql
-- insert_cloud_cost_history: require p_shop_id + 'inventory.edit'
PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

-- get_cloud_cost_history_by_product: require p_shop_id + 'inventory.view'
PERFORM require_shop_permission(p_shop_id, 'inventory.view');

-- get_cloud_cost_history_by_shop: require p_shop_id + 'inventory.view'
PERFORM require_shop_permission(p_shop_id, 'inventory.view');
```

2. **Grant EXECUTE** explicitly to `authenticated` and revoke from `PUBLIC`:

```sql
GRANT EXECUTE ON FUNCTION insert_cloud_cost_history(...) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cloud_cost_history_by_product(...) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cloud_cost_history_by_shop(...) TO authenticated;
REVOKE ALL ON FUNCTION insert_cloud_cost_history(...) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_cloud_cost_history_by_product(...) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_cloud_cost_history_by_shop(...) FROM PUBLIC;
```

3. **NOT modify** any existing table, policy, or migration.

### Security Invariants to Prove

```text
Invariant 1: Shop A caller + Shop B p_shop_id = DENIED (READ)
Invariant 2: Shop A caller + Shop B p_shop_id = DENIED (INSERT)
Invariant 3: Unauthenticated / anon caller = DENIED (ALL)
Invariant 4: salesOnly caller = DENIED (INSERT cost history)
Invariant 5: salesOnly caller = DENIED (READ cost history)
Invariant 6: Employee can only access their own shop
Invariant 7: Owner can access their own shop
```

---

## K. Corrective UI Workflow Contract

The D1 remediation implementation must make the cost-change decision explicit with three semantic outcomes when editing a product and the cost actually changes:

```text
1. تحديث سعر التكلفة للصنف الحالي  (Update current product cost)
2. إنشاء صنف جديد بدل تعديل الصنف الحالي  (Create new product instead of editing)
3. إلغاء  (Cancel)
```

### Path 1: Update Current

```text
update existing product cost
record exactly one cost-history transition
preserve historical sales/returns cost snapshots
```

### Path 2: Create New

```text
NOT mutate the original product's historical identity/cost record
create a genuinely distinct product record with:
  - new name (existing name + suffix or user-chosen name)
  - new barcode (generated via existing generateBarcode())
  - new requested cost
  - opening quantity = 0 (or user-specified)
  - current quantity = 0 (or user-specified)
preserve old product untouched
respect barcode uniqueness (use existing generateBarcode())
 respect tenant isolation
 respect RBAC
```

### Path 3: Cancel

```text
return to edit dialog with no changes
```

### Product Creation Reuse

The remediation must reuse the existing `DatabaseHelper.instance.insertProduct(...)` method for the create-new path. It must not invent new product creation patterns. If product naming/barcode business rules create ambiguity that cannot safely be resolved from existing code, the implementation must STOP rather than invent new product policy.

---

## L. Security / RBAC / Tenant Invariants

All invariants from the Group D planning governance (Section L) are preserved:

```text
TENANT_ISOLATION              = shop_id authority preserved on all new tables
RLS_AUTHORITY                 = All new tables must have RLS enabled with shop_id isolation
RBAC_BOUNDARY                 = owner/employee/salesOnly roles respected; no permission escalation
SERVER_AUTHORITY              = Server is authority for accounting correctness where cloud path used
FAIL_CLOSED                   = Missing data -> no false "net profit" claim
COST_SNAPSHOT_INTEGRITY       = Existing sale cost snapshots must NOT be retroactively modified
HISTORICAL_TRACEABILITY       = Historical sales remain traceable to their original costPrice
```

Additional invariant for D1 remediation:

```text
RPC_AUTHORIZATION_PATTERN     = All SECURITY DEFINER functions must call require_shop_permission()
EXECUTE_PRIVILEGE_CONTROL     = EXECUTE granted to authenticated; revoked from PUBLIC
```

No security downgrade may be justified as UX convenience.

---

## M. Required RPC Behavior Tests

The corrective pgTAP tests must expand D1 coverage from structural-only to behavioral. Required test categories:

### Owner Role

```text
Owner Shop A:
- can INSERT into Shop A cloud_cost_history (via RPC) -> succeeds
- can READ Shop A cloud_cost_history (via RPC) -> returns rows
- cannot INSERT Shop B (via RPC with Shop B uuid) -> raises exception
- cannot READ Shop B (via RPC with Shop B uuid) -> returns zero rows
```

### Employee Role

```text
Employee Shop A (with inventory.view + inventory.edit permissions):
- can INSERT into Shop A -> succeeds
- can READ Shop A -> returns rows
- cannot INSERT Shop B -> raises exception
- cannot READ Shop B -> returns zero rows
```

### salesOnly Role

```text
salesOnly Shop A:
- cannot INSERT cost history -> raises exception (no inventory.edit)
- cannot READ cost history -> raises exception or returns zero rows (no inventory.view)
```

### Unauthenticated / Anon

```text
anon caller:
- cannot execute insert_cloud_cost_history -> raises exception
- cannot execute get_cloud_cost_history_by_product -> raises exception
- cannot execute get_cloud_cost_history_by_shop -> raises exception
```

### Direct Table RLS vs RPC

```text
Direct INSERT into cloud_cost_history:
- authenticated user without owner/employee role -> blocked by RLS
- employee in Shop A -> allowed by RLS (INSERT policy)

Direct SELECT from cloud_cost_history:
- authenticated user without owner/employee role -> blocked by RLS
- employee in Shop A -> allowed by RLS (SELECT policy)
- employee in Shop A querying Shop B data -> returns zero rows (RLS)
```

### Minimum Required Behavior Tests

At minimum, the corrected pgTAP test file must include behavioral tests for:

1. Owner can RPC insert into own shop
2. Owner can RPC read own shop
3. Owner RPC insert cross-shop -> denied
4. Owner RPC read cross-shop -> returns zero
5. Employee can RPC insert own shop
6. Employee can RPC read own shop
7. Employee RPC insert cross-shop -> denied
8. Employee RPC read cross-shop -> returns zero
9. salesOnly RPC insert -> denied
10. salesOnly RPC read -> denied
11. Anon RPC insert -> denied
12. Anon RPC read -> denied
13. Direct table insert by owner (RLS allows)
14. Direct table insert by employee (RLS allows)
15. Direct table insert by salesOnly (RLS denies)
16. Direct table select cross-shop (RLS denies)

These 16 behavioral tests must pass alongside the existing 20 structural tests.

---

## N. Exact Future Implementation Allowlist

### Client Files

```text
app/lib/screens/inventory/inventory_screen.dart          (MODIFY — add three-option dialog)
app/test/database/cost_history_test.dart                  (MODIFY — may need updates if new-item path changes test setup)
app/test/features/enter_key_behavior_test.dart            (MODIFY — add new-item creation test via widget)
app/test/features/d1_cost_change_workflow_test.dart       (CREATE — dedicated workflow test, if materially cleaner)
```

### Server Files

```text
supabase/migrations/20260820000037_phase_p_group_d_d1_security_remediation.sql   (CREATE)
supabase/tests/d1_cost_history_rls.test.sql                                       (MODIFY — add behavioral RPC tests)
```

### Files NOT Authorized

```text
app/lib/database/database_helper.dart                     FORBIDDEN (no new methods needed for remediation)
app/lib/models/cost_history.dart                          FORBIDDEN (model is correct)
app/test/helpers/test_schema.dart                         FORBIDDEN (schema is correct)
```

### Explicit Justification for Each Authorized File

| File | Action | Justification |
|------|--------|---------------|
| inventory_screen.dart | MODIFY | Must add third "create new item" option to cost-change dialog |
| cost_history_test.dart | MODIFY | May need adjustment if new-item path affects test setup/assertions |
| enter_key_behavior_test.dart | MODIFY | Add test for new-item creation via widget interaction |
| d1_cost_change_workflow_test.dart | CREATE | Dedicated workflow test proving A/B/C paths if cleaner than modifying existing |
| 00037_...sql | CREATE | Additive corrective migration for RPC authorization |
| d1_cost_history_rls.test.sql | MODIFY | Add 16+ behavioral RPC authorization tests |

No other files are authorized for modification. If the remediation implementation determines another file is strictly required, it MUST stop and obtain explicit governance authorization.

### Forbidden Files

```text
app/lib/licensing/**                            (Group B scope)
app/lib/services/cloud_auth_service.dart        (Group B scope)
app/lib/platform/device_identity_provider.dart  (Group B scope)
app/android/**                                  (Group C scope)
app/windows/**                                  (frozen identity)
pubspec.yaml                                    (no dependency changes)
supabase/config.toml                            (no config changes)
supabase/functions/**                           (no Edge Function changes)
supabase/migrations/20260820000036_*.sql        (IMMUTABLE — D1 original migration)
existing migrations 00000..00035                (IMMUTABLE)
```

---

## O. Forbidden Delta

```text
D2 work                                            FORBIDDEN
D3 work                                            FORBIDDEN
opening balances                                   FORBIDDEN
accounts                                           FORBIDDEN
ledger implementation                             FORBIDDEN
period reporting                                   FORBIDDEN
licensing/**                                       FORBIDDEN
device identity                                    FORBIDDEN
device trust                                       FORBIDDEN
device gate                                        FORBIDDEN
Ed25519 licensing work                             FORBIDDEN
Android/**                                         FORBIDDEN
Windows identity work                              FORBIDDEN
Supabase Edge Functions                            FORBIDDEN
supabase/config.toml                               FORBIDDEN
existing migrations 00000..00036                   FORBIDDEN (no modification)
MIGRATION_00036_MODIFIED                           FORBIDDEN
MIGRATION_00037_IMPLEMENTED_THIS_SESSION           FORBIDDEN
production deployment                              FORBIDDEN
production migration application                   FORBIDDEN
production data mutation                           FORBIDDEN
force push                                         FORBIDDEN
amend                                              FORBIDDEN
rebase                                             FORBIDDEN
reset                                              FORBIDDEN
legacy origin access                               FORBIDDEN
modification of existing sale/return cost snapshots FORBIDDEN
any security boundary downgrade                    FORBIDDEN
any Group B/C scope bleed                          FORBIDDEN
```

---

## P. Regression Floors

### Existing D1 Baseline (MUST be preserved)

```text
D1_DART                      >= 12 existing tests (plus new remediation tests)
FULL_DART                    >= 1767 (Group B S12 floor + D1 additions)
flutter analyze              = 0 errors, no new warnings attributable to remediation
S8 tamper/cache              >= 41
S9 Ed25519                   >= 20
S10 security                 >= 31
phase_e security             >= 15
S1 server pgTAP              >= 46
S2 server pgTAP              >= 88
S3 server pgTAP              >= 25
S4 server pgTAP              >= 50
S6 server pgTAP              >= 35
```

### D1 pgTAP Requirement

```text
D1 pgTAP:
  - must not regress from existing 20 structural assertions
  - must add behavioral RPC authorization tests
  - final assertion count NOT frozen (depends on test design)
  - ALL REQUIRED RPC TENANT/RBAC CASES MUST PASS (Section M)
```

### Regression Floor Principle

```text
existing baseline preserved = REQUIRED
new remediation tests pass  = REQUIRED
final test count            = determined by implementation (not frozen here)
```

---

## Q. Production Boundary

```text
LOCAL_SUPABASE_STACK_ALLOWED     = YES
PRODUCTION_SUPABASE_MUTATION     = NO
PRODUCTION_MIGRATION_DEPLOYMENT  = NO
```

Future remediation implementation should test migration sequence locally:

```text
... -> 00035 -> 00036 -> 00037
```

And prove:

```text
fresh local apply succeeds
existing local stack incremental apply succeeds
RPC security tests pass
no migration history rewriting
```

No production migration deployment is authorized by D1 remediation. Production deployment requires a separate governed session.

---

## R. Stop Conditions

The corrective remediation implementation session MUST STOP immediately if:

```text
Any existing test regresses
Any RLS policy is weakened
Any security boundary is violated
Any existing migration (00000..00036) is modified
Any forbidden file from Section N/O is touched
The implementation exceeds the Section N allowlist without governance authorization
Any Group B/C scope is breached
Any production mutation occurs outside governed deployment
Any device-gate/licensing boundary is crossed
flutter analyze reports new errors attributable to remediation
The three-option dialog cannot be safely implemented (STOP, do not invent)
Product creation business rules create unresolvable ambiguity (STOP)
require_shop_permission cannot be used (STOP, investigate)
```

---

## S. Implementation Success Criteria

The corrective remediation implementation is COMPLETE when ALL of:

```text
1. inventory_screen.dart cost-change dialog offers THREE options:
   - update current product cost
   - create new product
   - cancel

2. "Create new product" path:
   - creates a genuinely distinct product record
   - uses existing insertProduct + generateBarcode
   - preserves original product untouched
   - respects tenant isolation
   - respects RBAC

3. Migration 00037:
   - re-creates three functions with require_shop_permission
   - grants EXECUTE to authenticated
   - revokes EXECUTE from PUBLIC
   - does NOT modify any existing table/policy/migration

4. pgTAP tests:
   - all existing 20 structural assertions preserved
   - new behavioral tests prove cross-shop denial for all roles
   - new behavioral tests prove anon/unauthenticated denial
   - new behavioral tests prove salesOnly denial
   - new behavioral tests prove direct table RLS isolation

5. Dart tests:
   - all existing D1 tests preserved (>= 12)
   - new test proves "create new item" workflow end-to-end

6. flutter analyze: 0 errors, no new warnings from remediation

7. All regression floors from Section P met
```

---

## T. Final Governance Determination

```text
D1_REPOSITORY_REMOTE_LOCK          = PASS
D1_ORIGINAL_IMPLEMENTATION_COMMIT  = 0d65c1324b18411ee516c04a66750aca65349a40
D1_ORIGINAL_IMPLEMENTATION_EXISTS  = YES
D1_ORIGINAL_8_FILES_VERIFIED       = YES
D1_ORIGINAL_DELTA_VERIFIED         = +910 / -1

D1_FUNCTIONAL_COMPLETION           = NOT_YET_SATISFIED
  BLOCKER_A                        = CONFIRMED (missing create-new-item workflow)

D1_SECURITY_COMPLETION             = NOT_YET_SATISFIED
  BLOCKER_B                        = CONFIRMED (SECURITY DEFINER RPC tenant bypass)

D1_STATE                           = REMOTE_LOCKED_WITH_REMEDIATION_REQUIRED

CORRECTIVE_MIGRATION               = 00037 (authorized, not yet implemented)
CORRECTIVE_GOVERNANCE_THIS_SESSION = PASS

D2_START_AUTHORIZED                = NO
D3_START_AUTHORIZED                = NO

MIGRATION_00036_IMMUTABLE          = YES
MIGRATION_00037_AUTHORIZED         = YES (future session only)
PRODUCTION_MUTATION_PERFORMED      = NO
DEVICE_GATE_CHANGED                = NO

NEXT_ALLOWED_ACTION = PHASE P / GROUP D / D1 CORRECTIVE REMEDIATION IMPLEMENTATION
```

---

## U. Commit / Remote-Lock Evidence

(To be populated after commit and push)

```text
CORRECTIVE_GOVERNANCE_COMMIT     = <set at commit>
CORRECTIVE_GOVERNANCE_PARENT     = 0d65c1324b18411ee516c04a66750aca65349a40
CORRECTIVE_GOVERNANCE_TREE       = <set at commit>
CORRECTIVE_GOVERNANCE_ARTIFACT   = docs/PHASE_P_GROUP_D_D1_CORRECTIVE_REMEDIATION_GOVERNANCE.md
CORRECTIVE_GOVERNANCE_ARTIFACT_BLOB = <set at commit>
ARTIFACT_LINE_COUNT              = <set at commit>
COMMIT_FILE_COUNT                = 1
COMMIT_MESSAGE                   = docs: govern Phase P Group D D1 corrective remediation
```

---

*This document is the corrective remediation governance artifact for Phase P Group D D1. D1 is remote-locked but functionally and security-incomplete. Two blockers are confirmed. Corrective remediation implementation is authorized for the next session. No implementation was performed. No production was mutated. STOPPED.*
