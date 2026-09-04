# Phase P / Group D / D2 — Opening Balances Planning Governance

**Session result:** PASS — D2 opening-balances planning contract completed, committed, remote-locked. D2 implementation is NOT STARTED and is owner-gated.

**Classification:** PHASE_P_GROUP_D_D2_OPENING_BALANCES_PLANNING

**Implementation authorization:** NO (this session plans D2 only; implementation requires a separate owner-authorized session that satisfies the Section Y entry gates).

---

## A. Session Result

```text
SESSION =
  PHASE_P_GROUP_D_D2_OPENING_BALANCES_PLANNING

AUTHORIZED_SCOPE =
  D2_OPENING_BALANCES_PLANNING_ONLY

IMPLEMENTATION_AUTHORIZED =
  NO

RESULT =
  PASS (owner-gated implementation contract)

D1_STATE =
  CLOSED_REMOTE_LOCKED

D2_PLANNING =
  CLOSED_REMOTE_LOCKED (after push)

D2_IMPLEMENTATION_STARTED =
  NO

D3_STARTED =
  NO

PRODUCTION_MUTATION =
  NO
MIGRATION_CREATED =
  NO
EDGE_FUNCTION_DEPLOYED =
  NO
```

D2 is **explicitly owner-gated**: the implementation session is blocked until the owner resolves the decision matrix in Section L (or accepts the recommended defaults).

---

## B. Repository Identity

```text
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_REMOTE     = origin
                   (C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن)
                   LEGACY / READ-ONLY FOR THIS WORKFLOW
LEGACY_ORIGIN_CONTACTED = NO
```

Protocol enforced: no fetch/pull/push/rewrite/delete of `origin`; no force-push; no reset; no rebase of published governance history; no destructive cleanup; normal fast-forward push to `github` only.

---

## C. Entry Classification

```text
CASE_A_FRESH
```

Verified at entry (before any edit):

```text
LOCAL_HEAD                    = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
TRACKING_HEAD                 = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
DIRECT_REMOTE_HEAD (github)   = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
MERGE_BASE                    = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
AHEAD                         = 0
BEHIND                        = 0

MERGE_IN_PROGRESS             = NO
REBASE_IN_PROGRESS            = NO
CHERRY_PICK_IN_PROGRESS       = NO
REVERT_IN_PROGRESS            = NO
INDEX (staged changes)        = EMPTY
TRACKED MODIFICATIONS         = NONE
TRACKED DELTA                 = NONE
```

Working-tree note (non-blocking, classified, not destroyed):

```text
UNTRACKED RESIDUE PRESENT (PRE-EXISTING, NOT PART OF THIS SESSION DELTA):
  GROUP_A_PHASE_P_OD7_*.md reports (root)
  GROUP_A_PHASE_Q_ANDROID_*.md report (root)
  MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
  delivery/I-TECH-Delivery-v1.0.0.zip
  supabase/.branches/
  supabase/.temp/
```

These are untracked files/directories that existed before this session. They were not modified, not staged, not committed, and not deleted (no destructive cleanup). The final tracked delta of this session is exactly one documentation file.

---

## D. Exact Remote-Lock Entry Proof

```text
LOCAL         = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
TRACKING      = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
DIRECT_REMOTE = 8bf626d744adeaf51e0c82288c6d5b904c8ab829   (git fetch github codex/i-tech-next-roadmap-freeze; refs/remotes/github/codex/i-tech-next-roadmap-freeze)
MERGE_BASE    = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
AHEAD         = 0
BEHIND        = 0
```

All three points (local, tracking, direct remote) are identical and equal to the D1 final closeout commit. Clean fresh entry confirmed.

---

## E. Authority Chain

Reconstructed from repository commits and governing artifacts (verified line-by-line in history):

```text
PHASE_P_OWNER_DECISIONS.md
  -> P-OD5 (WS-9) "opening balances" APPROVED; route = Group D: accounts/ledger schema
     (Line 54: "Additive schema (accounts/ledger); WS-1 drain"
      Line 32: P-OD5 APPROVED)

POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md
  -> Decomposes post-owner work into Groups A/B/C/D
  -> Group D = P-OD4, P-OD5, P-OD6, WS-9
  -> Line 162: "Opening balances (P-OD5) require additive accounts/ledger/supplier
     schema as explicit accounting entries"

POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md
  -> Line 126: "P-OD5 | Opening balances | APPROVED | Group D: accounts/ledger
     schema | AGENT (after Group D planning) | Group D planning boundary"

POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md
  -> Defines Groups B, C, D as remaining Phase P scope (Line 206: Group D =
     cost-change workflow P-OD4, opening balances P-OD5, arbitrary-period
     reporting P-OD6)

OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_* (authority-binding corrections)
  -> OWNER_ORDER_DECISION = GROUP_B_BEFORE_GROUP_D
  -> SECOND_SUCCESSOR     = GROUP_D_PLANNING

PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
  -> Group B complete plan; Group D deferred

Group B S1-S12
  -> Closed at 154a97038c166031bde2cf81799ab475b7e66e05 (S12 closeout commit,
     "docs: close Group B S12 final acceptance")
  -> GROUP_B_CLOSED = YES

a6c3993docs31a4... "docs: govern Phase P Group D implementation planning"
  -> Canonical Group D definition; D1 -> D2 -> D3 slices frozen
     (docs/PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md)

0d65c13 "feat: implement Phase P Group D D1 cost change history"
  -> D1 original implementation

a74fb62 "docs: govern Phase P Group D D1 corrective remediation"
  -> D1 corrective remediation governance

34a5901 "docs: record corrective remediation remote-lock evidence"

37d1efb "fix: remediate Phase P Group D D1 workflow and RPC authorization"
  -> D1 remediation / hardening (00036 + 00037)

eb41f04 "test: correct D1 cost history RLS assertions to defense-in-depth
          + add evidence closeout governance"
  -> D1 evidence closeout; TRUE incremental 00036->00037 proof

8bf626d "docs: record D1 closeout commit hash and remote-lock evidence
          in governance artifact"
  -> D1_FINAL_CLOSEOUT_COMMIT = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
  -> D1_STATE = CLOSED_REMOTE_LOCKED
  -> D1 success token:
     PASS_PHASE_P_GROUP_D_D1_EVIDENCE_CLOSEOUT_REMEDIATION_REMOTE_LOCKED

-> THIS SESSION: D2 OPENING BALANCES PLANNING (governance-only)
```

```text
AUTHORITY_CHAIN_VERIFIED = YES
```

D1 is treated as an immutable predecessor. D1 is NOT reopened. The D1 cost-change workflow is NOT redesigned. Migrations `00036` and `00037` are NOT modified.

---

## F. D2 Scope

### F.1 Canonical Meaning (RESOLVED_BY_AUTHORITY)

The roadmap label `P-OD5 = Opening Balances` (per `docs/PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md` Section I.2), read together with the owner decision chain in Section E, governs D2 as:

```text
D2 = OPENING BALANCES AS EXPLICIT ACCOUNTING ENTRIES / BALANCES
     on an additive, per-shop accounts/ledger foundation.
```

Reference language:
- Group D planning governance, Section I.2: "P-OD5: Opening balances as explicit accounting entries/balances"
- Group D planning governance, Section K/P-OD5: "Additive accounts/ledger/supplier schema as explicit accounting entries; No fabricated historical transactions; Auditability required"
- Group D planning governance, Section T/D2: "Implement opening balances as explicit accounting entries"; ALLOWED_DELTA = "additive accounts table, opening_balance entries, opening balance UI screen/workflow, database_helper.dart additive methods"
- Group D planning governance, Section U: frozen new files `account.dart`, `ledger_entry.dart`, `screens/accounting/opening_balance_screen.dart`, `cloud_accounting_repository.dart`, `cloud_accounting_service.dart`, `accounting_sync_adapter.dart`, `opening_balance_test.dart`

### F.2 Boundaries Settled by Repository Authority

```text
CUSTOMER OPENING RECEIVABLES  = NOT_IN_D2_SCOPE
SUPPLIER OPENING PAYABLES     = NOT_IN_D2_SCOPE

D2_ACCOUNT_TARGET             = PER-SHOP ACCOUNTING ACCOUNTS (accounts/ledger)
D2_ENTRY_KIND                 = EXPLICIT OPENING-BALANCE ACCOUNTING ENTRY
D2_FABRICATED_TRANSACTIONS    = FORBIDDEN
D2_AUDITABILITY               = REQUIRED (frozen)
D2_SECURITY_INVARIANTS        = tenant isolation + RBAC + no D1 regression
```

### F.3 Scope Determination Detail

The session prompt required explicitly determining whether D2 covers customer opening receivables and supplier opening payables. Repository authority is **decisive** and no owner gate is required for scope:

1. **Customer opening receivables — NOT IN SCOPE.**
   - Group D planning governance, Non-Goals (line 271): "Customer receivables/payables tracking (future scope)".
   - `docs/next-roadmap/I-TECH-T2-3-CUSTOMER-MASTER-DESIGN-FREEZE.md` (line 351): `` `openingBalance` | FUTURE | Balance tracking is out of scope ``; line 352 `` `balance` | FUTURE ``; lines 1015-1017: Future Implementation MUST NOT "Add `balance` field" / "Add `openingBalance` field" / "Create a receivables / payments system".
   - Forensic proof (Section H): customers have **no** balance field (stored or derived), **no** payments/collections table, and **no** per-customer money aggregation anywhere.

2. **Supplier opening payables — NOT IN SCOPE.**
   - Group D planning governance, Non-Goals (line 269): "Supplier purchasing domain (T5-2, separate roadmap item)".
   - Forensic proof (Section H): the word `supplier` / `purchase` has **zero** matches in `app/lib/**/*.dart` and `supabase/**/*.sql`. No supplier entity, table, model, screen, or purchase domain exists.

3. **Product opening stock quantities — RELATED_BUT_OUT_OF_SCOPE.** `products.openingQuantity` (`app/lib/database/database_helper.dart:594`) and `cloud_products.opening_quantity` are inventory stock opening quantities governed by the equation `currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment` (`app/lib/models/product.dart:26-27`). They are financially distinct from accounting opening balances and are NOT merged into D2. Financial opening balance and inventory opening quantity are different concepts (Section 20 of the session contract).

4. **Product opening cost — D1 CLOSED scope.** D1 cost history is CLOSED_REMOTE_LOCKED (Section E); no D2 work touches it.

5. **Abstract accounting domains** (cash drawer, bank, general-ledger opening journal, owner capital, expenses, retained earnings, tax opening positions, historical invoices/purchases, D3 reporting redesign, Excel/import redesign): all remain **excluded unless the owner later amends governance**. D2 implements only the opening-balance entry mechanism and the workflow over the account catalog that the owner approves in Section L. Full double-entry accounting is an explicit Group D non-goal (line 266).

> If the owner intends D2 to include per-customer opening receivables, per-supplier opening payables, or any abstract GL account set, a formal governance amendment to THIS contract (and to the Group D planning governance non-goals) is required before implementation. This contract does not authorize it.

---

## G. D2 Explicit Non-Scope

```text
D2_NON_SCOPE =
  customer opening receivables (per-customer)
  supplier opening payables (per-supplier)
  supplier/purchase domain creation (T5-2)
  customer balance / customer receivable tracking (future scope)
  product opening stock quantities (existing products.openingQuantity; out of D2)
  product opening cost / cost-history changes (D1 CLOSED)
  cash drawer opening balance
  bank account opening balance
  general-ledger opening journal / double-entry GL (Group D non-goal)
  owner capital / retained earnings / expense opening positions
  tax opening positions / VAT (T5-1)
  historical invoice/purchase backfill
  fabricated sales/invoices/payments/receipts/stock movements to seed balances
  D3 arbitrary-period reporting
  Excel/import redesign
  any modification of customers/suppliers models, repositories, or UI
  any modification of sales/returns/expenses/products existing tables
  production deployment
```

---

## H. Existing Architecture Findings (Forensic Evidence)

### H.1 Customers

```text
LOCAL TABLE  customers  = identity/profile master only.
  Columns: id, name, phone, address, notes, isActive, isSystem, createdAt,
           updatedAt, shop_id, cloud_uuid, server_version, sync_status,
           last_synced_at
  (app/lib/database/database_helper.dart:802-816; v9 additions 877-880;
   v13 sync triad 925-940)

CLOUD TABLE  cloud_customers = identity/profile master only.
  Columns: id, shop_id, name, phone, address, notes, is_active, is_system,
           created_at, updated_at, deleted_at, server_version
  (supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql:48-61;
   server_version 20260820000026_phase_h_sync_core.sql:12)

BALANCE SOURCE OF TRUTH = NONE EXISTS
  No balance column (stored). No per-customer aggregation query (derived).
  No payments/collections table in local SQLite or cloud.
  sales/returns carry NO customer column; invoices link customer only as
  identity snapshot (invoices.customerId nullable + invoices.customerName
  snapshot; database_helper.dart:750-765, 826).
  paymentMethod on invoices is a label ('cash'/'visa'/'insta_cash'), not a
  payment transaction (app/lib/screens/sales/invoice_screen.dart:23).

MODELS = app/lib/models/customer.dart (9 fields, no money)
         app/lib/models/cloud/cloud_customer.dart (11 fields, no money)

REPOSITORIES/SERVICES = database_helper.dart customers block (2896-3071)
                        app/lib/repositories/cloud/cloud_customer_repository.dart
                        (RPC create/update/delete; no balance)

SYNC = app/lib/sync/adapters/customer_sync_adapter.dart
       lastWriterWins; local 'customers'; cloud 'cloud_customers';
       requiredPermission = 'inventory.edit';
       NOTE: local insert gates on canCreateSales (database_helper.dart:2899)
       while the sync adapter requires inventory.edit — a recorded asymmetry
       not relevant to D2 but not to be silently changed.

SOFT DELETE = local isActive flag only (archiveCustomer, 3008-3042;
              system customers protected 3018-3020); cloud deleted_at soft
              delete (migration 25:599-600).

TENANT = shop_id locally + _TenantPredicate (database_helper.dart:3174-3211);
         shop_id UUID + RLS SELECT-only via shop_members ACTIVE on cloud
         (migration 25:213-220; reinforced at 20260820000034:775-787);
         mutations via SECURITY DEFINER RPCs with
         require_shop_permission(..., 'inventory.edit') (migration 25:518,552,590);
         direct table DML revoked from authenticated (migration 25:1248).

SCREENS EXPOSING BALANCE = NONE. customers_screen.dart shows identity only.
                           Dashboard shows global aggregates only.
```

Conclusion: **no customer balance concept exists in any form.** Any customer balance feature is future scope (T2-3), independent of D2.

### H.2 Suppliers

```text
SUPPLIER ENTITY = DOES NOT EXIST
  grep (?i)supplier in app/lib/**/*.dart            -> 0 matches
  grep (?i)supplier in supabase/**/*.sql            -> 0 matches
  grep (?i)supplier|purchase in app/lib/**/*.dart   -> 0 matches
  No supplier table, model, repository, service, screen, sync adapter,
  or purchase/purchase_items table exists (verified locally and in cloud).
  Supplier purchasing domain = T5-2, separate roadmap item,
  Group D non-goal (Group D planning governance line 269).
```

Conclusion: **supplier opening payables cannot be scoped into D2** because no supplier domain exists and none is authorized for Group D.

### H.3 Existing "opening" concepts

```text
PRODUCT OPENING QUANTITY = EXISTS, INVENTORY ONLY
  products.openingQuantity INTEGER DEFAULT 0 (database_helper.dart:594)
  cloud_products.opening_quantity (migration 25 cloud_products)
  Equation: current = opening - sold + returned + adjustment
            (app/lib/models/product.dart:26-27;
             app/lib/database/database_helper.dart:1456-1510;
             app/lib/sync/reconciliation_service.dart:23-24)

OPENING BALANCE (accounting) = DOES NOT EXIST
  grep opening_balance|initial_balance|openingBalance in *.dart/*.sql -> 0
  No accounts, ledger, journal, entries, chart-of-accounts anywhere:
    - Local: no accounts/ledger/suppliers/purchases tables (17 local tables)
    - Cloud: only "ledger" object is cloud_migration_ledger (migration 27:18),
      which is legacy import bookkeeping, NOT an accounting ledger.
```

### H.4 Local database / migration architecture

```text
CURRENT SCHEMA VERSION = 19
  static const int schemaVersion = 19 (database_helper.dart:110)

_LOCAL TABLES (17) = products, sales, returns, expenses, inventory_count,
  import_batches, invoices, app_settings, role_permissions,
  expense_categories, customers, sync_queue, legacy_migration_progress,
  conflict_audit, stock_adjustments, cost_history, users

MIGRATION LADDER (_onUpgrade, database_helper.dart:405-460):
  v<2 full rebuild, v<3 users, v<4 import_batches, v<5 invoices,
  v<6 role_permissions, v<7 expense_categories, v<8 _migrateToV8,
  v<9 _migrateToV9, v<13 _migrateToV13, v<14 _migrateToV14,
  v<15 _migrateToV15, v<16 _migrateToV16, v<17 _migrateToV17,
  v<18 _migrateToV18, v<19 _migrateToV19

_MIGRATE_FUNCTIONS = _migrateToV8 (823-860), _migrateToV9 (862-881),
  _migrateToV13 (883-941), _migrateToV14 (946-948), _migrateToV15 (983-1001),
  _migrateToV16 (1047-1087, data-only), _migrateToV17 (1094-1102),
  _migrateToV18 (1116-1118), _migrateToV19 (1129-1131)

FRESH == UPGRADED guarantee: _createDB replays additive steps v13/v15/v16/
  v17/v18/v19 (database_helper.dart:679-713).

TEST SEAMS: runCreateDbForTest (476-496), runUpgradeToV15..V19ForTest
  (502-539), runFreshOnCreateForTest (553-557).

ESTABLISHED MIGRATION TEST PROTOCOL (three legs):
  1. Fresh-install parity (byte-equivalent shape) — e.g.
     app/test/database/schema_v14_fresh_parity_test.dart:74-100
  2. Upgrade from immediately-previous version, business data untouched —
     e.g. app/test/database/schema_v18_migration_test.dart:120-162
  3. Replay idempotency — e.g. schema_v16_migration_test.dart:175-187
```

### H.5 Cloud schema architecture

```text
CURRENT HIGHEST MIGRATION = 20260820000037 (D1 security remediation)
  NEXT AVAILABLE          = 20260820000038 (virtual name: 00038)

CLOUD TABLES (28) = shops, shop_members, roles, role_permissions_cloud,
  devices, licenses, activations, invitations, shop_permission_overrides,
  permission_audit_log, cloud_expense_categories, cloud_products,
  cloud_customers, cloud_shop_settings, cloud_expenses,
  cloud_inventory_count, cloud_invoices, cloud_sales, cloud_returns,
  sync_log, cloud_migration_ledger, cloud_stock_adjustments, plans,
  device_audit_log, device_challenges, device_assertions,
  s4_enforcement_config, cloud_cost_history

CANONICAL CLOUD SECURITY SHAPE:
  RLS enabled + SELECT-only policy for authenticated via shop_members ACTIVE
  (canonical example: cloud_products policy, migration 25:202-211;
   S1 idempotent DO block, migration 31:164-174)
  All mutations via SECURITY DEFINER functions with
    SET search_path = public
    PERFORM require_shop_permission(p_shop_id, '<permission>')
    (canonical D1 shape: 20260820000037:10-43)
  Grants: REVOKE ALL FROM PUBLIC; GRANT EXECUTE TO authenticated
    (canonical D1: 00037:127-145)
  Direct table DML revoked from authenticated
    (migration 25:1247-1255)
```

### H.6 Sync / conflict / RBAC

```text
SYNC ENGINE = app/lib/sync/sync_engine.dart (1059 lines); per-entry tenant
  guard 119-130; idempotent replay 244-253; version-conflict path 218-242;
  retry/backoff 307-324.

ADAPTER CONTRACT = app/lib/sync/adapters/entity_sync_adapter.dart (36 lines):
  entityType, conflictPolicy, localToCloudPayload, cloudToLocalRow,
  getCloudUuid, getLocalId, getServerVersion, isServerAuthoritative,
  localTableName, cloudTableName, requiredPermission, getLocalUpdatedAt

ADAPTER REGISTRY = app/lib/sync/sync_runtime.dart:26-37 (10 entities;
  cost_history/conflict_audit are NOT queue-synced).

IDEMPOTENCY = local sync_queue idempotency_key
  (database_helper.dart:896; _generateSyncKey 277-282; occurrence_token
   v15 976-993) + cloud sync_log.idempotency_key UNIQUE (migration 26:31)
  + sync_upsert_entity IDEMPOTENT short-circuit (migration 26:308-318).

CONFLICT = LWW (conflict_resolver.dart:191-192) or serverAuthoritative;
  local-only conflict_audit evidence table (database_helper.dart:1005-1030)
  with owner review UI (screens/admin/conflict_review_screen.dart).

D1 COST-HISTORY PATTERN (closest precedent for D2):
  append-only audit entries; NOT queue-synced; local table cost_history
  (database_helper.dart:1162-1174) written transactionally by
  recordCostChange (2720-2742) inside updateProduct (1351) gated by
  canEditProducts (1284); cloud cloud_cost_history (migration 36:13-27)
  with changed_by + changed_at; RPCs hardened in 00037.

RBAC CATALOG = app/lib/services/permissions.dart (19 local permissions,
  lines 35-162); cloud seed = 18 permissions
  (supabase/seed.sql:17-41; admin.devices.manage is local-only).
  Roles default: owner = all; employee = minus deletions/admin/settings;
  salesOnly = sales.view + sales.create (permissions.dart:207-223).
  RESOLUTION precedence: cloud snapshot > local overrides; owner bypass;
  fail-closed (app/lib/services/permission_resolver.dart:10-22).
  Server enforcement: require_shop_permission() (migration 24:232-298).
  NOTE: NO existing permission semantically covers "accounting / opening
  balances". T2-3 forbids new AppPermission values ONLY within the customer
  master domain; D2 RBAC permission is therefore an owner decision (L.D2-06).
```

### H.7 Regression floors baseline (D1 closeout, docs/PHASE_P_GROUP_D_D1_EVIDENCE_CLOSEOUT_REMEDIATION_GOVERNANCE.md Sections O/P/Q)

```text
FULL_DART        = 1771 PASS
D1_WORKFLOW      = 4     COST_HISTORY = 12    ENTER_KEY = 6
S8               = 41    S9 = 20              S10 = 31    PHASE_E = 15
pgTAP:  D1 = 38   S1 = 46   S2 = 88   S3 = 25   S4 = 50   S6 = 35
flutter analyze  = 0 errors, 1 pre-existing warning
                  (device_management_screen.dart:4 unused_import)
```

---

## I. Customer Balance Semantics

There is **no customer balance concept** in the product today (Section H.1). Customer opening receivables are explicitly **out of D2 scope** (Section F.3), so no customer-balance sign convention is required by D2.

Observed state (for the record):

```text
CUSTOMER_BALANCE_STORED    = NO
CUSTOMER_BALANCE_DERIVED   = NO
POSITIVE_CUSTOMER_MEANING  = UNDEFINED (no customer money arithmetic exists)
CUSTOMER_RECEIVABLES_SCOPE = FUTURE_ROADMAP (T2-3 / Group D non-goal)
```

No silent inference is made about customer balance meaning. If the owner later authorizes per-customer receivable opening balances, a new governance amendment is required (independent of this D2 contract).

---

## J. Supplier Balance Semantics

No supplier domain exists (Section H.2). Supplier opening payables are **not in D2 scope**:

```text
SUPPLIER_BALANCE_STORED    = N/A (entity does not exist)
SUPPLIER_BALANCE_DERIVED   = N/A
POSITIVE_SUPPLIER_MEANING  = UNDEFINED / NOT_APPLICABLE
SUPPLIER_PAYABLES_SCOPE    = T5-2 FUTURE_ROADMAP, Group D non-goal
```

---

## K. Opening-Balance Accounting Contract (frozen semantics)

The following contract is frozen by this governance for D2 implementation, based on repository authority (Group D planning governance Sections I/K/T, and its non-goals):

```text
K1  OPENING BALANCE = explicit, additive, shop-scoped accounting entry;
     NOT a sale, NOT a purchase, NOT an expense, NOT a cash collection,
     NOT a payment, NOT an inventory movement, NOT a product cost change.

K2  NO FABRICATED TRANSACTIONS. Creating fake sales invoices, purchase
     invoices, payments, receipts, or stock movements to simulate an
     opening balance is FORBIDDEN.

K3  DEFAULT = ZERO. An existing shop, existing account, existing customer,
     or newly created account that has no opening-balance entry has an
     opening balance of zero. No backfill of fabricated balances.

K4  DOUBLE-COUNTING BARRIER. Opening-balance entries NEVER enter the
     legacy aggregates (sales totals, returns totals, expenses totals,
     COGS, stock quantities, dashboard net profit). They are stored in
     additive tables only. Consequently:
         current_account_balance = sum(opening-balance entries)
                                   + post-opening movements for that
                                     account (none in D2 scope; D3 era)
     must be recomputed ONLY from additive D2 data, and never by mutating
     existing tables (Section 10 of the session contract).

K5  INVENTORY vs FINANCIAL SEPARATION. products.openingQuantity
     (inventory) and financial opening balances are different concepts.
     Neither may drive the other.

K6  D1 SEPARATION. D2 does not touch cloud_cost_history, cost_history,
     the cost-change workflow, or migrations 00036/00037.

K7  AUDITABILITY = REQUIRED (frozen by Group D planning: "Auditability
     required"). Every opening-balance entry must carry actor + timestamp
     (+ prior/new value for corrections). Reuse the existing additive
     audit spirit of cost_history (changed_by) and the local conflict_audit
     table rather than inventing a parallel audit subsystem.

K8  SIGN CONVENTION = owner-gated (Section L.D2-02). No convention is
     invented here.

K9  ZERO = absence of an opening-balance entry for the account, or an
     explicit zero entry with amount = 0. Both must render as "no
     opening balance". Numeric precision must match the frozen money type
     (NUMERIC(12,2) cloud precedent).

K10 NEGATIVES = owner-gated (Section L.D2-03). Default recommendation =
     invalid/rejected (see Section L).

K11 EFFECTIVE DATE = owner-gated (Section L.D2-04). Opening balances must
     NOT back-date into or be applied to pre-existing sales/returns.

K12 EDIT/CORRECTION = owner-gated (Section L.D2-05). Default
     recommendation = append-only entries with corrective adjustment
     entries; no in-place mutation of a posted entry.

K13 WHO MAY SET/CORRECT = owner-gated (Section L.D2-06). Server keeps
     authority where the cloud path is used (require_shop_permission),
     matching D1 hardening. No permission escalation.
```

This contract is not hard-coded into any formula beyond what is stated here; the exact SQL/PgSQL arithmetic is an implementation detail constrained by K1-K13.

---

## L. Owner Decisions / Resolution Matrix

These decisions are NOT resolvable from repository authority (no accounting code exists anywhere; Section H). The framework requires them to be recorded and owner-resolved rather than invented. Each carries a recommended default so the owner may accept defaults in one action.

```text
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-01
QUESTION     | What is the D2 account model? Which accounting accounts may
             |   carry an opening balance in a shop?
WHY_REQUIRED | P-OD5 is accounts/ledger-based. The implementation cannot
             |   build schema or UI without knowing account granularity
             |   (per-account catalog vs fixed system set) and account types.
OPTIONS      | A) Per-shop additive account catalog (accounts table) seeded
             |      EMPTY; owner opts accounts in and enters balance per account.
             | B) Fixed minimal system-set of accounts for every shop.
             | C) Single implicit "shop opening balance" (no account dimension).
ACCOUNTING_IMPACT   | A/B preserve per-account truth; C loses per-account truth.
DATA_MIGRATION_IMPACT| A/B need accounts table; C needs only balance table.
SECURITY_IMPACT      | All variants remain shop-scoped + RBAC-gated (D2-06).
RECOMMENDED_DEFAULT  | A) additive per-shop account catalog, empty by default.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-02
QUESTION     | What does a POSITIVE opening balance mean for an account?
WHY_REQUIRED | No sign convention exists anywhere in the app. UI display,
             |   summaries, and DB CHECKs all depend on it.
OPTIONS      | A) Positive = asset/new-value owned by or owed to the shop
             |      (debit-like; "the shop holds this").
             | B) Positive = liability/obligation of the shop (credit-like).
             | C) Sign is per-account-type (type-aware direction: asset
             |      accounts A, liability accounts B).
ACCOUNTING_IMPACT   | Determines whether D3-era sums and UI labels are inverted.
DATA_MIGRATION_IMPACT| Stable once written; needs a CHECK + display labels only.
SECURITY_IMPACT      | None directly; display correctness is an accounting-truth issue.
RECOMMENDED_DEFAULT  | C) type-aware direction, with account types limited to:
             |      CASH / BANK / RECEIVABLE_SUMMARY (positive = owned/owed to
             |      shop) and PAYABLE_SUMMARY / CAPITAL (positive = obligation).
             |      If only a single generic account is chosen (D2-01 C), use A.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-03
QUESTION     | Are NEGATIVE opening balances valid?
WHY_REQUIRED | DB CHECK constraints, validation, and UI all treat this.
OPTIONS      | A) Invalid: reject negative; zero/positive only.
             |      Correct direction errors via a new entry (append-only).
             | B) Valid: signed amounts with per-type semantics.
ACCOUNTING_IMPACT   | A is simpler and matches cost_history non-negative CHECK
             |      precedent (migration 36:24-25 chk old/new >= 0).
DATA_MIGRATION_IMPACT| A needs CHECK (amount >= 0) on balance table.
SECURITY_IMPACT      | None directly.
RECOMMENDED_DEFAULT  | A) negatives rejected; signed semantics expressed only
             |      via the account TYPE (D2-02 C), not via negative amounts.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-04
QUESTION     | What is the effective-date semantics of an opening balance?
WHY_REQUIRED | Whether an entry carries a date and how the date participates
             |   in balance-as-of computation (D3 will consume it later).
OPTIONS      | A) No explicit date; entries are "as of shop opening".
             | B) Shop-level single effective date set once.
             | C) Per-entry effective date (account-specific / import date).
ACCOUNTING_IMPACT   | A/B treat opening balance as a constant basis; C allows
             |      staged opening (import of later accounts).
DATA_MIGRATION_IMPACT| C stores a date column with index; A/B may omit it.
SECURITY_IMPACT      | None directly; date must not permit backdating into
             |      existing sales/returns (K11).
RECOMMENDED_DEFAULT  | C) per-entry effective_date column (defaults to entry
             |      date), additive, indexed; used ONLY by future D3
             |      as-of computations. No application to existing data.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-05
QUESTION     | Can an opening balance be edited/corrected, and how?
WHY_REQUIRED | Controls schema (append-only vs mutating), audit rows, and
             |   whether a correction screen exists.
OPTIONS      | A) Once entered, immutable; corrections = new explicit
             |      adjustment entries referencing/offsetting the original.
             | B) Editable in place until "locked"; lock once any
             |      operational transaction exists.
             | C) Fully editable any time (mutating).
ACCOUNTING_IMPACT   | A preserves accounting truth and audit (K7); C risks
             |      silent rewrites; B is a compromise.
DATA_MIGRATION_IMPACT| A/B need audit/version columns; C only needs latest value.
SECURITY_IMPACT      | A/B give clean cross-device semantics (see D2-07).
RECOMMENDED_DEFAULT  | A) append-only + corrective adjustment entries,
             |      keyed idempotently; mirrors the cost_history audit pattern.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-06
QUESTION     | Which roles may view / set / correct opening balances?
WHY_REQUIRED | No existing permission covers accounting. Server RPC guards
             |   (require_shop_permission) need an exact permission id, and
             |   local resolver gates need the same id.
OPTIONS      | A) Owner-only set/correct; owner-only view.
             | B) Owner set/correct; owner + employee view.
             | C) New accounting permission pair
             |      (e.g., accounting.view / accounting.edit) added to the
             |      AppPermission catalog + cloud seed, defaulted owner-only.
             | D) Reuse an existing permission (e.g., inventory.edit) without
             |      expanding the catalog.
ACCOUNTING_IMPACT   | None beyond governance of who owns the books.
DATA_MIGRATION_IMPACT| C needs role_permissions/cloud seed/permission catalog
             |      changes (behavioral delta, must be governed).
SECURITY_IMPACT      | C adds new capacity keys (must be distributed carefully);
             |      A/B/D are least-privilege by construction.
RECOMMENDED_DEFAULT  | B) owner set/correct + owner/employee read-only view,
             |      implemented via reuse of an existing owner-gated path OR
             |      a new accounting.read/view pair IF the owner-elects C.
             |      salesOnly and unauthenticated always denied.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
DECISION_ID  | D2-07
QUESTION     | Where is an opening balance entered?
WHY_REQUIRED | UI surface and whether account creation can seed a balance.
OPTIONS      | A) Dedicated accounting/opening-balance owner screen + workflow
             |      only.
             | B) Also allow entering a balance inline at account creation.
             | C) Also allow it during customer creation (NOT permitted by
             |      T2-3 — rejected).
ACCOUNTING_IMPACT   | B risks accidental moral-seeding at creation; A keeps
             |      one explicit workflow.
DATA_MIGRATION_IMPACT| None materially differ.
SECURITY_IMPACT      | A cleanly funnels all writes through one owner-gated path.
RECOMMENDED_DEFAULT  | A) dedicated opening-balance setup workflow, owner-
             |      gated; never inside customer or supplier creation.
IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES
--------------------------------------------------------------------------------------------------
```

```text
OWNER_DECISIONS_REQUIRED = D2-01..D2-07 (all IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES)
NOT_FABRICATED = YES (no owner approval is assumed; defaults are recommendations only)
```

---

## M. Data Model Plan

Semantic contract only; exact DDL is for the implementation session under the entry gates.

### M.1 Core D2 entities (additive, per-shop)

```text
accounts (local) / cloud_accounts (cloud)
  id / cloud_uuid, shop_id, name, account_type (per D2-01/D2-02),
  created_at, created_by, updated_at, deleted_at (soft where canonical),
  server_version, sync_status (local)

opening_balance_entries (local) / cloud_opening_balance_entries (cloud)
  id / cloud_uuid, shop_id, account_id (FK -> accounts),
  amount NUMERIC(12,2)-style money (D2-02/D2-03 semantics),
  effective_date (D2-04), entry_kind = OPENING | ADJUSTMENT | CORRECTION
  (D2-05), pre_entry_id (for corrections, optional),
  notes, created_by, created_at,
  idempotency_key + occurrence fields (canonical sync),
  server_version, sync_status, last_synced_at
```

### M.2 Invariants

- All rows own `shop_id`; every read/write path goes through the canonical tenant predicates locally and the canonical RPC/RLS path in cloud.
- Opening-balance entries never touch `sales`, `returns`, `expenses`, `products`, `invoices`, `cost_history`.
- Default on migration for existing shops: **zero rows**, zero effect on any existing aggregate.
- Audit columns `created_by` + `created_at` on every entry (K7); correction pattern per D2-05.

### M.3 Precedent reuse

- Money precision: `NUMERIC(12,2)` cloud precedent (migrations 36:19-20).
- Local money scaled as existing REAL/long-currency pattern in `database_helper.dart`.
- Audit shape modeled on `cost_history` (database_helper.dart:1162-1174) + `conflict_audit` (database_helper.dart:1005-1030); not a new audit subsystem.

---

## N. Local SQLite Plan

```text
LOCAL_SCHEMA_CHANGE_PROBABLE = YES (additive, schemaVersion 19 -> 20)
LOCAL_TABLES_ADDED           = accounts, opening_balance_entries
                               (+ optional audit history columns on the
                                entries table)
PROTOCOL_REQUIRED:
  1. Bump schemaVersion to 20 (database_helper.dart:110, doc comment 92-109)
  2. Add _migrateToV20(db) (additive CREATE TABLE only)
  3. Replay in _createDB fresh path so fresh == upgraded
  4. Add runCreateDbForTest / runUpgradeToV20ForTest seams (pattern:
     476-496 / 537-539)
  5. Migration tests: fresh-parity, upgrade v19 -> v20 with business rows
     untouched, replay idempotency (protocol in Section H.4)
  6. Existing-row default = zero (no migrated opening rows)
BACKWARD_COMPATIBILITY = additive columns/tables only; frozen legacy
   database identity untouched (no rename/restructure of existing tables)
FAILURE/RECOVERY = follow existing transactional additive migration seams
                   (idempotent re-run)
```

---

## O. Supabase / RLS / RBAC Plan

```text
SERVER_SCHEMA_DELTA = PROBABLE (one additive migration, see Section R)
SERVER_TABLES_ADDED = cloud_accounts, cloud_opening_balance_entries
                      (naming per implementation)

RLS (canonical, never weakened):
  ALTER TABLE ... ENABLE ROW LEVEL SECURITY
  SELECT-only policy for authenticated via shop_members ACTIVE + shop_id
  (canonical shape migration 25:202-211; idempotent DO-guard migration 31)
  NO permissive TRUE write policies

MUTATIONS via SECURITY DEFINER functions:
  SET search_path = public (fixed)
  PERFORM require_shop_permission(p_shop_id, '<D2-06 permission>')
  create_opening_balance / correct_opening_balance / list_opening_balances
  (guard: authenticated-only, shop membership, permission; cross-shop and
   unauthenticated denial; least privilege; no owner-only bypass beyond
   require_shop_permission's canonical owner handling)

GRANTS:
  REVOKE ALL ... FROM PUBLIC;
  GRANT EXECUTE ... TO authenticated;   (anon = NO EXECUTE)
  Direct-table DML REVOKE from authenticated (canonical: migration 25:1247-1255)
  No grants to anon

RBAC:
  D2-06 determines the permission id. Recommended default B (owner
  set/correct; owner+employee view). salesOnly always denied on
  accounting. No D1 security regression: existing RLS/RPC/grants of
  00036/00037 remain byte-identical.
```

---

## P. Offline / Sync Plan

The application is offline-first. D2 reuses the canonical sync framework and adds ONE entity family; no D2-specific sync framework is invented.

```text
LOCAL SOURCE OF TRUTH      = SQLite (append entries offline first)
CLOUD REPRESENTATION       = cloud_accounts / cloud_opening_balance_entries
                             via canonical SyncCloudOperations transport
SYNC INTEGRATION           = new accounting adapter implementing
                             EntitySyncAdapter (entity_sync_adapter.dart:4-36);
                             register in buildStandardAdapters
                             (sync_runtime.dart:26-37); extend SyncEntityType;
                             add transport branch mirroring
                             sync_cloud_operations_transport.dart patterns
                             (stock_adjustment / cost-history-style governed
                             RPC param threading incl. p_idempotency_key)
IDEMPOTENCY                = local idempotency_key + occurrence_token
                             (database_helper.dart:896, 976-993) and cloud
                             sync_log.idempotency_key UNIQUE
                             (migration 26:31) — same queue/dedup machinery
CONFLICT / DUPLICATES      = RECOMMENDED: append-only + server-authoritative
                             per-entry (like D1 cost_history channel);
                             cross-device independent edits of the SAME
                             posted entry are structurally impossible
                             (no in-place mutation, D2-05 default A).
                             A duplicate retry converges via idempotency
                             envelope; surviving conflicts use the canonical
                             conflict_audit + review path.
RETRIES                    = existing backoff ladder (sync_engine.dart:307-324)
TIMESTAMPS/VERSIONING      = server_version optimistic guard on every row
                             (schema_v13_test.dart:97-147 canonical);
                             entry created_at/created_by audit
TENANT BINDING             = per-entry shop_id persisted in queue at enqueue
                             (sync_engine.dart:119-130)
RECONCILIATION             = server-authoritative adoption after sync
                             (sync_engine.dart applyServerWinner path)
CROSS-DEVICE EDIT QUESTION =
  "Same opening balance edited independently on two devices?"
  -> Prevents by construction IF D2-05 = append-only (default A):
     no posted entry is ever edited in place; each device appends; the
     account basis is the auditable append chain, and corrections are
     distinct adjustment entries. If the owner instead elects in-place
     editing (D2-05 B/C), canonical LWW/server_version conflict handling
     applies with silent-overwrite risk made explicit to the owner.
```

---

## Q. UI/UX Plan

Planning only — no UI is implemented in this session.

```text
LOCATION      = dedicated accounting area
               (frozen new file: app/lib/screens/accounting/opening_balance_screen.dart)
WORKFLOW      = owner-gated setup/correction screen (D2-07 default A);
                list accounts, enter opening balance per account,
                corrections as explicit adjustments (D2-05 default A)
CONSTRAINTS   -
   Arabic RTL compatible
   Non-accountant understandable: use plain labels + type-aware direction
   (D2-02 default C)
   Explicit direction: distinguish "ما للمتجر / رصيد مدين" vs "على المتجر /
   رصيد دائن" per account type, resistant to sign inversion
   Clear copy that an opening balance is NOT a payment, NOT an invoice,
   NOT a stock movement
   Permission-gated per D2-06
   Safe against Enter/double-submit (single-submit guards are an existing
   house pattern, e.g. D1 workflow / enter_key tests)
NO REDESIGN  = no unrelated customer/supplier/sales/inventory UI redesign
```

---

## R. Migration Plan

```text
CURRENT_TOP    = 20260820000037 (D1 security remediation)
D1_MIGRATIONS  = 00036 IMMUTABLE, 00037 FROZEN

PROPOSED_NEXT_MIGRATION = 20260820000038 (implementation session reserves it;
                           NOT created this session)
MIGRATION_CREATED_THIS_SESSION = NO

SEMANTIC DELTA EXPECTED IN 00038 (additive only):
  new tables: cloud_accounts, cloud_opening_balance_entries
  constraints: CHECK (amount semantics per D2-02/D2-03),
               shop_id NOT NULL + FK, account FK
  indexes: shop_id, account_id, effective_date, idempotency_key unique
  RLS: enabled + SELECT-only authenticated policies (canonical shape)
  functions/RPCs: SECURITY DEFINER create/correct/list with
                  require_shop_permission + fixed search_path
  grants/revokes: REVOKE ALL FROM PUBLIC; GRANT EXECUTE TO authenticated;
                  direct DML revoked from authenticated
  audit/history: entry-embedded audit columns (created_by/created_at;
                 correction linkage) — no new audit subsystem
  upgrade defaults: existing shops/accounts get ZERO opening entries

RULES:
  ADDITIVE_ONLY where feasible
  NO REWRITE OF 00036
  NO REWRITE OF 00037
  NO SQUASHING
  NO PRODUCTION DEPLOYMENT (future governed deployment session)
  D2_SERVER_SCHEMA_DELTA = NONE IS NOT SELECTED (schema change is required
                           for the accounts/ledger opening-balance model,
                           pending D2-01). If the owner elects D2-01
                           option (single implicit balance, no accounts
                           dimension), the delta shrinks accordingly; the
                           existence of a migration is not automatic.
```

---

## S. Security Threat Model

```text
THREAT                    MITIGATION
unauth INSERT/UPDATE      RLS enabled; no direct INSERT/UPDATE policies;
                          DML revoked from authenticated; anon no EXECUTE
unauthenticated RPC       SECURITY DEFINER functions call require_shop_permission
                          which rejects auth.uid() = NULL (canonical D1 00037)
wrong-shop access         shop_id predicate locally (_TenantPredicate) +
                          EXISTS(shop_members shop_id + ACTIVE) in RLS +
                          require_shop_permission shop-scoped check (server)
cross-shop data leak       balances listable only through shop-scoped RPC/RLS
role escalation           permission id resolution fail-closed
                          (permission_resolver.dart:10-22); salesOnly denied
                          accounting (D2-06); no new owner bypass
direct-table access       no grants to authenticated on cloud_accounts /
                          cloud_opening_balance_entries (canonical 25:1247-1255)
search_path injection     SET search_path = public on every SECURITY DEFINER fn
double-submit / dup op    local idempotency_key + occurrence_token + cloud
                          sync_log UNIQUE replay envelope
D1 regression             no modification of 00036/00037 or their RLS/RPC/grants
fabricated balances        append-only entry model + default zero (K2/K3)
tenant contamination      sync engine per-entry origin guard (sync_engine.dart:119-130)
invalid money             NUMERIC(12,2) precedent + anchored CHECKs; negatives
                          per D2-03 default A
```

---

## T. Reporting Impact Classification

Existing reports/views were enumerated (Section H) and classified:

```text
dashboard financial section (dashboard_screen.dart:124-157)   MAY_CHANGE_LATER (D3)
  -> unchanged by D2 (zero default; opening entries never enter legacy sums)
sales report screens (sales_screen.dart / sales_report_screen.dart)  D3_SCOPE
customer balance displays?  NONE EXIST  -> UNRELATED
supplier balance displays?  NONE EXIST  -> UNRELATED
statement / PDF / export outputs         UNRELATED (no balance outputs exist)
NEW opening-balance screen + queries     MUST_CHANGE_FOR_D2_CORRECTNESS (new files)
sync serialization for new entities      MUST_CHANGE_FOR_D2_CORRECTNESS (additive adapter)
```

Only `MUST_CHANGE_FOR_D2_CORRECTNESS` items (the new D2 files in Section W) enter the D2 implementation allowlist.

---

## U. Test Matrix

Tests are planned below; NONE are written in this session.

### U.1 Functional

```text
customer zero opening balance           (N/A: customer balance out of scope)
customer positive opening balance       (N/A: out of scope)
supplier zero/positive opening balance  (N/A: entity does not exist)
account zero opening balance            entry absent or amount 0 -> renders zero
account positive opening balance        entry persists, displays correctly
create account with opening balance     if D2-07 B elected (default A => not at creation)
edit/correct opening balance            only via corrective adjustment per D2-05
cancellation/no mutation                cancel in dialog -> no DB write
reopen/reload persistence               entries survive app restart
existing-account migration default      no fabricated rows; business data untouched
```

### U.2 Accounting

```text
opening balance included exactly once   sum over entries == displayed balance
new sale/purchase changes balance       (only where domain exists; D2 scope accounts)
payment / return/refund effect          N/A for D2 unless owner expands scope
opening balance NOT counted as revenue  assert legacy sales totals unchanged
opening balance NOT counted as expense  assert legacy expense totals unchanged
opening balance does NOT mutate stock   assert product currentQuantity unchanged
opening balance does NOT mutate D1 cost history   assert cost_history count unchanged
```

### U.3 Security

```text
authorized role succeeds                owner (and employee-view if D2-06 B) PASS
unauthorized role denied                salesOnly denied; permission-less denied
wrong-shop access denied                cross-shop RPC + RLS denial
unauth access denied                    anon/no-session denial (RPC + table)
direct-table access denied              no authenticated grants on D2 tables
RLS isolation                           per-shop data invisible cross-shop
RPC permission enforcement              require_shop_permission present on all D2 RPCs
```

### U.4 Sync / offline (reuse canonical fixtures)

```text
offline creation/update                 append entry offline -> queue entry
queue replay                            single entry pushed
duplicate replay                        idempotent envelope, no double-write
retry                                   backoff ladder, non-success not faked
conflict                                no in-place conflict when append-only;
                                        surviving conflicts -> conflict_audit review
reconnect                               suspended queue resumes
cross-device reconciliation             server-authoritative adoption
```

### U.5 Migration

```text
clean install                           fresh DB full shape
upgrade from 00037                      isolated stack 00000..00038 clean apply
migration replay                        re-run is idempotent
existing rows safe default              zero balance rows; business data untouched
no mutation of historical transactions  sales/returns/expenses unchanged
no D1 regression                        D1 RLS/RPC pgTAP still pass
local v19 -> v20                        upgrade protocol three legs (Section N)
```

---

## V. Regression Floors

The D1 closeout (docs/PHASE_P_GROUP_D_D1_EVIDENCE_CLOSEOUT_REMEDIATION_GOVERNANCE.md Sections O/P/Q) is the minimum known floor. No floor may be lowered. The implementation contract requires ALL existing suites PLUS D2 deltas to pass.

```text
FULL_DART        >= 1771 PASS
D1_WORKFLOW      >= 4
COST_HISTORY     >= 12
ENTER_KEY        >= 6
S8               >= 41
S9               >= 20
S10              >= 31
PHASE_E          >= 15

pgTAP:
  D1 = 38, S1 = 46, S2 = 88, S3 = 25, S4 = 50, S6 = 35
  (+ future D2 pgTAP suite)

flutter analyze  = 0 errors
                   (1 pre-existing warning: device_management_screen.dart:4:8
                    unused_import; no new warnings)

Also preserved for the Phase-P exit contract where applicable:
  dart format (no drift), migration replay clean on isolated stack,
  backup/restore suites, production schema verification,
  RLS/RBAC verification, release/build validation.
```

During planning, the repository has NOT advanced beyond these numbers (D1 is the latest closed slice), so the floors above represent the current floor, not a total.

---

## W. Exact Implementation Allowlist

Exact proposed D2 implementation file list — evidence-driven, no vague "other related files" entries. Anything not listed is forbidden unless governance is formally amended.

### W.1 EXISTING_MODIFY (proven necessary)

```text
app/lib/database/database_helper.dart        additive v20 migration + D2 CRUD
app/lib/sync/sync_runtime.dart               register accounting adapter
app/lib/sync/sync_status.dart                extend SyncEntityType (account)
app/lib/sync/sync_cloud_operations_transport.dart   additive accounting RPC
                                             branches threading p_idempotency_key
```

### W.2 NEW_FILE

```text
app/lib/models/account.dart
app/lib/models/ledger_entry.dart             (opening/adjustment entry model)
app/lib/screens/accounting/opening_balance_screen.dart
app/lib/repositories/cloud/cloud_accounting_repository.dart
app/lib/services/cloud/cloud_accounting_service.dart
app/lib/sync/adapters/accounting_sync_adapter.dart
app/test/database/opening_balance_test.dart
app/test/sync/opening_balance_sync_test.dart
supabase/migrations/20260820000038_opening_balances_*.sql
supabase/tests/d2_opening_balances_rls.test.sql
```

### W.3 OPTIONAL_IF_FORENSICALLY_REQUIRED

```text
app/lib/services/permissions.dart            ONLY if owner-elects D2-06 option C
                                             (new accounting permission pair)
app/lib/services/permission_resolver.dart    same condition (D2-06 C)
supabase/seed.sql                            same condition (D2-06 C); governed
app/test/features/d2_opening_balance_workflow_test.dart  if UI workflow tests needed
app/test/helpers/test_schema.dart            mirror new tables for unit tests
```

```text
ALLOWED_DELTA_TYPE = additive code/schema only
CUSTOMER/SUPPLIER MODEL/REPO/UI = NOT IN ALLOWLIST (out of D2 scope)
```

---

## X. Exact Denylist

Anything not on the Section W allowlist plus the following explicit denials:

```text
D1 redesign / reopen
D3 arbitrary-period reporting (any from/to report, period comparison,
   D3 RPCs, D3 date-range UI, profitability redesign)
licensing / device identity / device management / entitlement cache
Ed25519 retirement work
invitation flows
sync drain activation changes
Android signing / release / Play Console
unrelated inventory redesign  / sales redesign / purchase redesign
broad reporting redesign
unrelated database cleanup
migration renumbering
edits to 20260820000036_*
edits to 20260820000037_*
customer balance / openingBalance fields (T2-3 frozen rejection)
supplier entity / purchase domain creation
fabricated transactions to seed balances
per-customer receivables or per-supplier payables tracking
general-ledger / double-entry accounting (Group D non-goal)
multi-currency / VAT / tax / payment gateway
Excel/import redesign (opening-balance import boundary, Section 23)
Edge Function deploy / creation
supabase/config.toml changes
pubspec.yaml dependency changes
platform files (app/windows, app/android identity)
contacting legacy origin; force push; rebase; reset; amend
production mutation / migration deployment
```

---

## Y. Implementation Entry Gates

The future D2 implementation session MUST satisfy ALL gates before starting; otherwise it must stop as BLOCKED/DEFINED_NOT_AUTHORIZED.

```text
GATE_Y1  Fresh forensic entry (CASE_A_FRESH): local == tracking == github
         remote == merge-base; AHEAD/BEHIND = 0 (Section C/D protocol)
GATE_Y2  D1 remains CLOSED_REMOTE_LOCKED at 8bf626d744adeaf51e0c82288c6d5b904c8ab829
GATE_Y3  This planning governance artifact is verified remote-locked
GATE_Y4  D3 NOT STARTED; Group C NOT STARTED; device gate unchanged
GATE_Y5  OWNER RESOLUTION: owner decisions D2-01..D2-07 resolved or recommended
         defaults explicitly accepted (documented owner artifact required).
         No implementation may proceed while any D2-0x is unresolved.
GATE_Y6  Scope/no-scope compliance with Sections F, G, K
GATE_Y7  Implementation constrained to Section W allowlist; Section X denylist
         untouchable
GATE_Y8  All regression floors (Section V) green + all new D2 tests (Section U)
         pass; flutter analyze 0 errors; dart format clean
GATE_Y9  Migration replay proven on an isolated temp stack (00000..00038)
         before any deployment consideration
GATE_Y10 Separately owner-authorized deployment + verification sessions
         required for production; this contract deploys nothing
```

---

## Z. Final Determination / Success Token

```text
D1_STATE                       = CLOSED_REMOTE_LOCKED
D2_PLANNING_STATE              = CLOSED_REMOTE_LOCKED (after push)
D2_IMPLEMENTATION_STARTED      = NO
D3_STARTED                     = NO

PRODUCTION_MUTATION            = NO
MIGRATION_CREATED              = NO
EDGE_FUNCTION_DEPLOYED         = NO
NEW_MIGRATION                  = 20260820000038 PROPOSED (NOT CREATED)

CANONICAL_D2_SCOPE             = opening balances as explicit accounting
                                 entries on an additive accounts/ledger
                                 foundation; supplier/customer receivable
                                 scope excluded by repository authority

OWNER_GATED                    = YES (D2-01..D2-07; implementation blocked
                                 until resolved/confirmed)

D2_IMPLEMENTATION_AUTHORIZED   =
  NO — requires a separate owner-authorized implementation session that
  satisfies Section Y gates.

SUCCESS_TOKEN =
  PASS_PHASE_P_GROUP_D_D2_OPENING_BALANCES_PLANNING_REMOTE_LOCKED
  (emitted ONLY upon successful commit + fast-forward push to github +
   post-push remote-lock proof)
```

---

## AA. Post-Commit Evidence

(To be populated after commit and push, mirroring the D1 governance style.)

```text
COMMIT_SHA       = <set at commit>
PARENT_SHA       = 8bf626d744adeaf51e0c82288c6d5b904c8ab829
ARTIFACT_PATH    = docs/PHASE_P_GROUP_D_D2_OPENING_BALANCES_PLANNING_GOVERNANCE.md
DELTA            = 1 added documentation file, 0 modified, 0 deleted
LOCAL            = tracking = remote = merge-base
AHEAD            = 0
BEHIND           = 0
PRE_PUSH_AHEAD   = 1   (after local governance commit)
POST_PUSH_LOCK   = <set after push>
```

---

*This document is the D2 opening-balances planning governance artifact. D1 remains CLOSED. D2 is planned but NOT implemented. D3 is not started. No production mutation occurred. No migration was created. The D2 implementation is owner-gated on the Section L decision matrix. STOPPED.*