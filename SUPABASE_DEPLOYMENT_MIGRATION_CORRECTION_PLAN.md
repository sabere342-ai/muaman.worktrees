# Supabase Deployment Migration Correction Plan

**Session:** SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING
**Target Outcome:** PASS_SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING_LOCAL_READY
**Entry Baseline:** cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9
**Date:** 2026-08-26

---

## 1. Incident Summary

**Failed Operation:** Staging deployment `supabase db push` to project `i-tech-staging` (ref: `ldkttyljtolnwlipjimb`)

**Failure Point:** Migration 15 of 17 — `20260820000025_phase_g_cloud_data_foundation.sql`

**PostgreSQL Error:** `SQLSTATE 42P13` — "input parameters after one with a default value must also have defaults"

**Defective Function:** `create_cloud_invoice_with_items` (lines 1044–1116)

**Migrations Applied Before Failure:** 1–14 (Phase C through Phase F complete)

**Migrations Not Attempted:** 15 (Phase G), 16 (Phase H), 17 (Phase I), 18 (Phase M — canonical inventory shows 17 total, Phase M is #17)

**Staging State:** Partially migrated (1–14 applied). Dedicated disposable project `i-tech-staging`.

**Production Impact:** ZERO — production has never received these migrations.

---

## 2. Forensic Evidence

### 2.1 Defective Function Signature (Migration 00025, lines 1044–1051)

```sql
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_customer_id UUID DEFAULT NULL,     -- ← First parameter with DEFAULT
  p_payment_method TEXT,                -- ← NO DEFAULT (VIOLATION)
  p_date TIMESTAMPTZ,                   -- ← NO DEFAULT (VIOLATION)
  p_sale_items JSONB                    -- ← NO DEFAULT (VIOLATION)
)
```

### 2.2 PostgreSQL Rule (Documented Behavior)

Per PostgreSQL `CREATE FUNCTION` documentation: **All input parameters following the first parameter with a default value must also have default values.** This is a hard syntax rule, not a warning.

### 2.3 Repository Identity Verification

| Property | Value |
|----------|-------|
| ROOT | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` ✓ |
| BRANCH | `codex/i-tech-next-roadmap-freeze` ✓ |
| AUTHORIZED_REMOTE | `github` ✓ |
| FETCH_URL | `https://github.com/sabere342-ai/muaman.worktrees.git` ✓ |
| PUSH_URL | `https://github.com/sabere342-ai/muaman.worktrees.git` ✓ |
| ENTRY_HEAD | `cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9` ✓ |
| REMOTE_HEAD | `cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9` ✓ |
| AHEAD/BEHIND | `0/0` ✓ |
| TRACKED WORKTREE | Clean (only sacred artifacts untracked) ✓ |
| INDEX | Empty ✓ |
| STASH | Exists (from unrelated branch) ✓ |

### 2.4 Locked Baseline Verification

| Tag | Peeled Commit | Expected | Match |
|-----|--------------|----------|-------|
| `phase-n-planning-baseline-locked` | `4f356f1a146ced265f776d213dd5379fa489a7d3` | `4f356f1a146ced265f776d213dd5379fa489a7d3` | ✓ |
| `phase-n-implementation-locked` | `e697759f60952cf567dc03aaa485b91626255a9a` | `e697759f60952cf567dc03aaa485b91626255a9a` | ✓ |
| `phase-n-android-startup-defect-remediation-locked` | `693f1d92a33af4a5ff7432a20f03994129a405dd` | `693f1d92a33af4a5ff7432a20f03994129a405dd` | ✓ |
| `supabase-production-deployment-planning-baseline-locked` | `741b4236d4344e8fbd3f66c8c41af4595da15de7` | `741b4236d4344e8fbd3f66c8c41af4595da15de7` | ✓ |
| `supabase-production-deployment-plan-correction-locked` | `cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9` | `cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9` | ✓ |

### 2.5 Sacred Artifact Verification

| Artifact | Path | Status |
|----------|------|--------|
| Source of Truth Report | `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | Intact, untracked ✓ |
| Delivery Package | `delivery/I-TECH-Delivery-v1.0.0.zip` | Intact, untracked ✓ |
| Supabase Temp | `supabase/.temp/` | Present, untracked ✓ |

---

## 3. Root Cause Verification

**Exact Violation:** Parameter `p_customer_id` (position 3) declares `DEFAULT NULL`. Parameters at positions 4, 5, 6 (`p_payment_method`, `p_date`, `p_sale_items`) lack defaults.

**PostgreSQL Rule Citation:** `CREATE FUNCTION` — "If a parameter has a default value, all subsequent parameters must also have default values."

**Error Code:** `42P13` (invalid_function_definition)

**No Other Violations in Migration 00025:** All other 18 functions in this migration place defaulted parameters at the end of the argument list. Verified by inspection of all 19 function signatures.

---

## 4. Migration Ordering Constraint (Critical)

**Supabase migration execution is strictly sequential.** Migration 00025 fails during `db push`. Migration 00026 (Phase H) and later **never execute** because the pipeline halts at the first error.

**Therefore:** A later correction migration (e.g., `20260820000029_*.sql`) **cannot** fix this by itself. The broken migration 00025 must be corrected at source before any replay can succeed.

**Approaches that DO NOT WORK:**
- Adding a later migration with `CREATE OR REPLACE FUNCTION` — 00025 still fails first
- `supabase migration repair` to mark 00025 as applied — destroys clean replay guarantee
- Manual SQL patch on staging — destroys reproducibility

**Required:** The defective migration file itself must be corrected, then the full chain replayed from migration 1 on a clean database.

---

## 5. Repository-Wide Function Audit

**Scope:** All 55 `CREATE OR REPLACE FUNCTION` definitions across `supabase/migrations/*.sql` (17 canonical migrations).

**Audit Method:** Static inspection of every function signature for "parameter with DEFAULT followed by parameter without DEFAULT".

### 5.1 Results — Migrations Already Applied to Staging (1–14)

| Migration | Functions | Violations |
|-----------|-----------|------------|
| 00000–00009 | Various | None |
| 00010 (RLS) | 0 | N/A |
| 00020 (Phase C) | 5 | None |
| 00021 (Phase D) | 0 | N/A |
| 00022 (Phase D) | 1 | None |
| 00023 (Phase E) | 5 | None |
| 00024 (Phase F) | 7 | None |

**Result:** Staging migrations 1–14 are clean. The failure at 00025 is the first violation encountered.

### 5.2 Results — Pending Migrations (15–17 Canonical)

| Migration | Functions | Violations |
|-----------|-----------|------------|
| **00025 (Phase G)** | 19 | **1: `create_cloud_invoice_with_items`** |
| 00026 (Phase H) | 4 | None (all defaults at end) |
| 00027 (Phase I) | 4 | None (no defaults) |
| 00028 (Phase M) | 10 | None (all defaults at end; note `create_cloud_invoice_with_items_v2` correctly orders required→optional) |

**Result:** **Exactly one violation** in the entire canonical migration chain: `create_cloud_invoice_with_items` in migration 00025.

### 5.3 Note on Phase H Replacements

Migration 00026 replaces three functions from 00025 (`update_cloud_product`, `update_cloud_customer`, `update_cloud_expense`) with version-aware signatures. All three replacements correctly place defaulted parameters at the end. No violation introduced.

---

## 6. Intended RPC Contract Analysis

### 6.1 Application Call Site (Dart)

**File:** `app/lib/repositories/cloud/cloud_sales_repository.dart` (lines 128–155)

```dart
Future<CloudInvoice> createInvoiceWithItems(
  String shopId, {
  required String customerName,
  String? customerId,           // ← Nullable/optional
  required String paymentMethod,
  required DateTime date,
  required List<Map<String, dynamic>> saleItems,
}) async {
  final data = await _client.rpc('create_cloud_invoice_with_items', params: {
    'p_shop_id': shopId,
    'p_customer_name': customerName,
    'p_customer_id': customerId,        // Passed explicitly (may be null)
    'p_payment_method': paymentMethod,
    'p_date': date.toIso8601String(),
    'p_sale_items': saleItems,
  });
  ...
}
```

### 6.2 Contract Semantics

| Parameter | Dart Type | Required? | Default in SQL? | Semantic Intent |
|-----------|-----------|-----------|-----------------|-----------------|
| `p_shop_id` | `String` | Yes | No | Shop context (auth-gated) |
| `p_customer_name` | `String` | Yes | No | Display name, always required |
| `p_customer_id` | `String?` | **No** | **Yes (NULL)** | Optional link to `cloud_customers` |
| `p_payment_method` | `String` | Yes | No | Cash/card/etc — required |
| `p_date` | `DateTime` | Yes | No | Invoice timestamp — required |
| `p_sale_items` | `List<...>` | Yes | No | At least one line item — required |

**Key Finding:** The Dart caller **always supplies all six named parameters**, including `p_customer_id` (which may be `null`). The default `DEFAULT NULL` on `p_customer_id` is a convenience for direct SQL callers but is **not relied upon by the application**.

### 6.3 Phase M v2 Contract (Migration 00028, lines 691–700)

```sql
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items_v2(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB,
  p_customer_id UUID DEFAULT NULL,        -- ← Moved AFTER all required params
  p_idempotency_key TEXT DEFAULT NULL,
  p_allow_oversell BOOLEAN DEFAULT FALSE
)
```

This v2 signature **correctly follows PostgreSQL rules**: all required parameters first, then optional parameters with defaults. The Dart `createInvoiceWithItemsV2` wrapper (lines 278–305) passes all parameters by name.

---

## 7. Correction Options Considered

| Option | Description | Accept/Reject | Reason |
|--------|-------------|---------------|--------|
| **A — Reorder Arguments** | Move `p_customer_id` (with default) to after all required parameters. Signature: `(p_shop_id, p_customer_name, p_payment_method, p_date, p_sale_items, p_customer_id DEFAULT NULL)` | **ACCEPT** | Matches v2 pattern; satisfies PostgreSQL; preserves all semantics; Dart named-parameter calls unaffected; minimal change. |
| **B — Add Defaults to Following Args** | Add `DEFAULT` to `p_payment_method`, `p_date`, `p_sale_items` | REJECT | Semantically invalid — these are **required** business fields. Artificial defaults would weaken data integrity and mask caller errors. |
| **C — Remove DEFAULT from p_customer_id** | Change to `p_customer_id UUID` (no default) | REJECT | Would require all SQL callers to pass explicit `NULL`. Dart already does, but breaks direct SQL ergonomics. Less clean than reordering. |
| **D — Historical Migration Correction** | Edit `20260820000025_phase_g_cloud_data_foundation.sql` in place, then re-lock | **ACCEPT** (combined with A) | Production never received these migrations. Staging is dedicated and disposable. Clean replay from migration 1 is the correct remediation. |
| **E — New Later Correction Migration Only** | Add `20260820000029_*.sql` with `CREATE OR REPLACE FUNCTION` | REJECT | **Cannot unblock `db push`** — 00025 fails before 00029 executes. Sequential execution guarantee. |
| **F — Migration History Repair / Manual Skip** | `supabase migration repair --status applied 20260820000025` | REJECT | Destroys clean replay invariant. Would require manual state tracking forever. Not auditable. |

---

## 8. Chosen Correction Strategy

### 8.1 Approved SQL Correction

**APPROVED_SQL_CORRECTION = REORDER_OPTIONAL_PARAMETER_TO_END**

Change the function signature in `20260820000025_phase_g_cloud_data_foundation.sql` from:

```sql
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_customer_id UUID DEFAULT NULL,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB
)
```

To:

```sql
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB,
  p_customer_id UUID DEFAULT NULL
)
```

**Function Body:** **Unchanged** — parameter references by name (`p_customer_id`, etc.) are unaffected by position.

**GRANT Statement (line 1241):** Must be updated to match new parameter order:

```sql
-- FROM:
GRANT EXECUTE ON FUNCTION create_cloud_invoice_with_items(UUID, TEXT, UUID, TEXT, TIMESTAMPTZ, JSONB) TO authenticated;
-- TO:
GRANT EXECUTE ON FUNCTION create_cloud_invoice_with_items(UUID, TEXT, TEXT, TIMESTAMPTZ, JSONB, UUID) TO authenticated;
```

### 8.2 Historical Migration Edit Required

**HISTORICAL_MIGRATION_EDIT_REQUIRED = YES**

The correction modifies the canonical migration file `20260820000025_phase_g_cloud_data_foundation.sql` directly.

**Justification:**
- Production has **never** received this migration
- Staging is a **dedicated, disposable** project (`i-tech-staging`)
- The clean replay invariant (empty DB → canonical migrations → valid schema) must be restored
- The v2 function in migration 00028 already demonstrates the correct parameter ordering

### 8.3 New Later Migration Alone Sufficient?

**NEW_LATER_MIGRATION_ALONE_SUFFICIENT = NO**

Explained in Section 4: sequential execution blocks any later migration from running.

### 8.4 Application Code Change Required?

**APPLICATION_CODE_CHANGE_REQUIRED = NO**

The Dart client uses **named parameters** (`params: { 'p_customer_id': customerId, ... }`). Parameter order in the SQL function signature is irrelevant to named-parameter RPC calls. Both existing `createInvoiceWithItems` and new `createInvoiceWithItemsV2` wrappers will continue to work without modification.

---

## 9. Exact Authorized File Scope

The future implementation session is authorized to modify **exactly these files**:

| File | Change Type | Reason |
|------|-------------|--------|
| `supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql` | **Function signature + GRANT** | Fix default-parameter ordering violation |
| `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md` | **Hash update** | Update SHA-256 for migration 00025 (line 126 function signature reference, and any hash manifest if present) |
| *This correction plan document* | **New file** | Documents the approved remediation |

**No other files** are authorized for modification. Specifically:
- No Dart application code changes
- No other migration files
- No test files (contract unchanged)
- No documentation beyond hash updates

---

## 10. Hash Governance Requirements

### 10.1 Current Hash

```
CURRENT_00025_SHA256 = 0E93C753C6D849C151A2EE786EFCAAAF11166DA2E02D365094E04F6DD35A3615
```

### 10.2 Post-Correction Hash

```
POST_CORRECTION_HASH = TO_BE_COMPUTED_DURING_IMPLEMENTATION
```

### 10.3 Artifacts Requiring Hash Reconciliation

| Artifact | Location | Action |
|----------|----------|--------|
| `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md` | Function inventory table (line 126) | Update signature reference; recompute any recorded hash |
| `PHASE_G_CLOUD_DATA_FOUNDATION_PLAN.md` | Function inventory (line 940, 970) | Update signature reference |
| Any future deployment manifest | TBD | Update if hash recorded |

**Implementation Session Must:**
1. Modify the approved SQL
2. Compute new SHA-256: `Get-FileHash -Algorithm SHA256 <file>`
3. Update all authorized canonical hash records
4. Verify no unapproved migration file changed
5. Record old → new hash provenance in commit message

---

## 11. Staging Recovery Strategy

### 11.1 Current Staging State

- Project: `i-tech-staging` (ref: `ldkttyljtolnwlipjimb`)
- Migrations 1–14: **APPLIED**
- Migration 15 (00025): **FAILED**
- Migrations 16–17: **NOT ATTEMPTED**
- Seed: **NOT EXECUTED**
- Edge Function: **NOT DEPLOYED**

### 11.2 Approved Recovery Sequence (Future Session)

1. **Correct repository migration chain** (this plan → implementation)
2. **Validate correction locally** via approved disposable validation path (local Supabase CLI `supabase start` + `supabase db reset` against local PostgreSQL 15)
3. **Remote-lock correction** (Git push + tag re-lock in `SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING_REMOTE_LOCK` session)
4. **Explicitly verify linked project is `i-tech-staging`** (`supabase status` → confirm project ref `ldkttyljtolnwlipjimb`)
5. **Destructively reset/rebuild dedicated staging**: `supabase db reset --linked` (or equivalent CLI command per current documentation)
6. **Replay canonical migration chain from migration 1**: `supabase db push`
7. **Apply seed**: `supabase db seed` (or equivalent)
8. **Deploy Edge Function**: `supabase functions deploy invite-employee`
9. **Perform hosted verification**: Gates 4–10 per `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md`

### 11.3 CLI Command Discovery Requirement

The implementation session must **discover exact supported commands and flags** using:
- Installed Supabase CLI `--help`
- Current Supabase documentation (migration ordering, `db push`, `db reset`, staging reset behavior)

Do not assume command syntax from memory.

### 11.4 Staging Mutated This Session?

**STAGING_MUTATED_THIS_SESSION = NO**

---

## 12. Clean Replay Requirement

**Mandatory Invariant:**

```
EMPTY DATABASE
    +
CANONICAL MIGRATIONS IN ORDER (1–17)
    =
VALID CURRENT SCHEMA
```

**Without:**
- Manual SQL patches
- History fabrication (`migration repair`)
- Skipped broken migrations
- Undocumented hosted state

This reproducibility property is **more important** than preserving a defective SQL file byte-for-byte.

---

## 13. Security Validation (Gate E)

The corrected function must preserve:

| Property | Current | Post-Correction |
|----------|---------|-----------------|
| `SECURITY DEFINER` | Yes | Yes (unchanged) |
| `SET search_path = public` | Yes | Yes (unchanged) |
| `GRANT EXECUTE TO authenticated` | Yes | Yes (updated signature) |
| `REVOKE ALL ON cloud_invoices FROM authenticated` | Yes | Yes (unchanged, migration 00025 line 1253) |
| Shop isolation via `require_shop_permission(p_shop_id, 'sales.create')` | Yes | Yes (unchanged body) |
| Tenant/shop isolation | Enforced | Enforced |

**Do not add `SECURITY DEFINER`** merely to solve permissions — already present.

---

## 14. Test / Verification Matrix

### Gate A — SQL Static Audit
- [ ] No invalid default-parameter ordering in any canonical migration function
- [ ] Verified by static inspection of all 55 functions

### Gate B — Migration Hash Audit
- [ ] All canonical migration hashes match approved post-correction values
- [ ] Migration 00025 hash updated in all manifests

### Gate C — Clean Replay
- [ ] Fresh local Supabase (`supabase start`) executes full migration chain (1–17) sequentially with 0 errors
- [ ] If Docker/local Supabase unavailable: define approved alternative disposable validation environment

### Gate D — RPC Contract
- [ ] `create_cloud_invoice_with_items` exists
- [ ] Argument names/types match: `(UUID, TEXT, TEXT, TIMESTAMPTZ, JSONB, UUID)`
- [ ] Required/optional semantics preserved: `p_customer_id` optional, others required
- [ ] Callable using exact application payload (named parameters)
- [ ] Rejects invalid input per existing validation logic (unchanged body)

### Gate E — Security
- [ ] `SECURITY DEFINER` retained
- [ ] `SET search_path = public` retained
- [ ] `GRANT EXECUTE TO authenticated` with corrected signature
- [ ] RLS implications: `cloud_invoices` still `REVOKE ALL FROM authenticated`
- [ ] Shop isolation via `require_shop_permission` intact

### Gate F — Staging Replay (Post Remote-Lock)
- [ ] Full canonical migration replay = PASS
- [ ] Seed = PASS
- [ ] `invite-employee` deployment = PASS
- [ ] Hosted schema inventory = PASS
- [ ] RLS/policy inventory = PASS
- [ ] RPC execute privileges = PASS
- [ ] Data API boundary = PASS

### Gate G — Production Non-Mutation
- [ ] Until staging verification fully passes: `PRODUCTION_MUTATION = NONE`

---

## 15. Failure / Stop Conditions

The implementation session **MUST STOP** and escalate if:

1. Local clean replay fails for any reason other than the known 00025 defect
2. Any other migration reveals a latent default-parameter violation
3. Application RPC call fails with corrected signature (named parameters should be immune)
4. Supabase CLI version incompatibility prevents `db push`/`db reset`
5. Staging project identity cannot be verified before destructive reset
6. Hash reconciliation reveals unexpected changes to other migrations

---

## 16. Production Non-Mutation Boundary

| Property | Value |
|----------|-------|
| `PRODUCTION_IDENTIFIED_FOR_MUTATION` | NO |
| `PRODUCTION_LINKED` | NO |
| `PRODUCTION_MUTATED` | NO |

Production credentials **must not be accessed, identified, or used** in any session before staging verification fully passes (Gate F).

---

## 17. Implementation Session Boundary

**Authorized Work:**
1. Edit `supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql` — function signature + GRANT only
2. Update hash references in `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md` and `PHASE_G_CLOUD_DATA_FOUNDATION_PLAN.md`
3. Local validation via `supabase start` → `supabase db reset` → `supabase db push`
4. Commit changes locally

**Forbidden:**
- Push to remote
- Create tags
- Deploy to staging/production
- Modify any other file

---

## 18. Remote-Lock Boundary

**Next Session:** `SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING_REMOTE_LOCK`

**Scope:**
- Push correction commit to `github`
- Re-lock corrected baseline (new tag replacing `supabase-production-deployment-plan-correction-locked`)
- Verify remote HEAD matches local HEAD

**Forbidden:**
- Staging deployment
- Production access

---

## 19. Staging Redeployment Boundary

**Session After Next:** `SUPABASE_STAGING_REDEPLOYMENT`

**Scope:**
- Verify linked project is `i-tech-staging`
- Destructive reset (`db reset`)
- Full migration replay (`db push`)
- Seed + Edge Function deploy
- Gate 4–10 verification

---

## 20. Rollback / Recovery Strategy

If implementation introduces regression:

1. **Git rollback:** `git reset --hard cb919d375fe8d60fa05aab8ef6a3c64e22a1b9b9` (entry baseline)
2. **Staging recovery:** Staging is disposable — recreate project if corrupted
3. **No production impact:** Production never received these migrations

---

## 21. Prohibited Operations Audit (This Planning Session)

| Operation | Occurred? |
|-----------|-----------|
| SQL migration modification | NO |
| Staging mutation | NO |
| Migration repair | NO |
| Manual hosted SQL execution | NO |
| Staging reset | NO |
| Seed deployment | NO |
| Edge Function deployment | NO |
| Production access/mutation | NO |
| Git push | NO |
| Git tag creation | NO |

All prohibited operations **confirmed not performed**.

---

## 22. Risks / Follow-Up

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Local Supabase CLI unavailable for validation | Medium | Document approved alternative (CI/CD test project, Docker) in implementation plan |
| Hash manifests missed during update | Low | Explicit checklist in Section 10 |
| Dart client edge case with reordered params | Very Low | Named parameters are order-independent; verified by code inspection |
| Supabase CLI `db reset` behavior changes | Low | Discover exact flags via `--help` at implementation time |

---

## 23. Final Decision

**PASS_SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING_LOCAL_READY**

All planning gates satisfied:

- [x] Repository identity correct
- [x] Locked baselines verified
- [x] Sacred artifacts intact
- [x] Migration 00025 fully inspected
- [x] All canonical migration functions audited for default-argument defects
- [x] Application call sites inspected
- [x] Intended RPC contract established
- [x] Correction options compared
- [x] Exactly one preferred correction selected (REORDER_OPTIONAL_PARAMETER_TO_END)
- [x] Migration-ordering problem addressed (historical correction required)
- [x] Staging recovery method planned (destructive reset + clean replay)
- [x] Clean replay required
- [x] Current Supabase docs checked (CLI commands to be discovered at implementation)
- [x] Current PostgreSQL docs checked (default parameter rule confirmed)
- [x] Security implications covered
- [x] Exact future implementation scope defined (2 SQL lines + 1 GRANT + hash updates)
- [x] Production remains excluded
- [x] No SQL modified
- [x] Staging not mutated

---

## 24. Next Authorized Session

```
SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLANNING_REMOTE_LOCK
```

---

## Appendix: Corrected Function Signature (For Implementation Reference)

```sql
-- File: supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql
-- Lines: 1044–1051 (signature), 1241 (GRANT)

CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB,
  p_customer_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
-- BODY UNCHANGED (lines 1056–1116)
$$;

GRANT EXECUTE ON FUNCTION create_cloud_invoice_with_items(UUID, TEXT, TEXT, TIMESTAMPTZ, JSONB, UUID) TO authenticated;
```