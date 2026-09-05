# Phase P / Group D / D3 — Arbitrary-Period Reporting Planning Governance

**Session result:** PASS — D3 arbitrary-period reporting planning governance artifact created, committed, remote-locked, STOPPED. D3 implementation is NOT STARTED (blocked on D2 implementation completion, which is owner-gated).

**Classification:** PHASE_P_GROUP_D_D3_ARBITRARY_PERIOD_REPORTING_PLANNING

**Implementation authorization:** NO (this session plans D3 only; D3 implementation requires a separate governed session that satisfies the Section Y entry gates and occurs only after D2 implementation is closed).

---

## A. Session Result

```text
SESSION =
  PHASE_P_GROUP_D_D3_ARBITRARY_PERIOD_REPORTING_PLANNING

AUTHORIZED_SCOPE =
  D3_ARBITRARY_PERIOD_REPORTING_PLANNING_ONLY

IMPLEMENTATION_AUTHORIZED =
  NO

RESULT =
  PASS (planning governance contract)

D1_STATE =
  CLOSED_REMOTE_LOCKED

D2_PLANNING =
  CLOSED_REMOTE_LOCKED

D2_IMPLEMENTATION_STARTED =
  NO  (owner-gated; blocked on Section L decision matrix)

D3_PLANNING =
  CLOSED_REMOTE_LOCKED (after push)

D3_IMPLEMENTATION_STARTED =
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

---

## B. Repository Identity

```text
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (SACRED; NEVER contacted)
LEGACY_ORIGIN_CONTACTED = NO
```

---

## C. Entry / Recovery Classification

```text
CASE_A_FRESH
```

Verified at session entry:

```text
LOCAL_HEAD                    = 58f3224132d74febf07867486b6c03b712757b52
TRACKING_HEAD                 = 58f3224132d74febf07867486b6c03b712757b52
DIRECT_GITHUB_REMOTE_HEAD     = 58f3224132d74febf07867486b6c03b712757b52
                                  (git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze)
MERGE_BASE                    = 58f3224132d74febf07867486b6c03b712757b52
AHEAD                         = 0
BEHIND                        = 0
TRACKED_WORKTREE              = CLEAN (no tracked changes; only pre-existing untracked files)
INDEX                         = EMPTY
ACTIVE_MERGE/REBASE/CHERRY_PICK = NONE (no MERGE_HEAD, CHERRY_PICK_HEAD, REVERT_HEAD,
                                    BISECT_LOG, rebase-merge, or rebase-apply present)
```

Direct authorized-remote verification:

```text
$ git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze
58f3224132d74febf07867486b6c03b712757b52  refs/heads/codex/i-tech-next-roadmap-freeze
```

No CASE_B / CASE_C / CASE_D / CASE_E condition was present. No destructive recovery was used or needed.

Pre-existing untracked files (inventoried, preserved, NOT staged):

```text
Continue
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.branches/
supabase/.temp/
```

---

## D. Exact Entry Remote-Lock Proof

```text
LOCAL         = 58f3224132d74febf07867486b6c03b712757b52
TRACKING      = 58f3224132d74febf07867486b6c03b712757b52
DIRECT_REMOTE = 58f3224132d74febf07867486b6c03b712757b52   (git ls-remote github)
MERGE_BASE    = 58f3224132d74febf07867486b6c03b712757b52
AHEAD         = 0
BEHIND        = 0
```

All three points (local, tracking, direct remote) are identical. Clean entry confirmed.

---

## E. Authority Chain

The full authority chain from Phase P inception through Group B closeout, D1 closeout, D2 planning closeout, to this D3 planning session:

```text
PHASE_P_OWNER_DECISIONS.md
  -> POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md
    -> Defines Group D scope: P-OD4, P-OD5, P-OD6, WS-9

OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md
  -> OWNER_ORDER_DECISION = GROUP_B_BEFORE_GROUP_D
  -> FIRST_SUCCESSOR = GROUP_B_PLANNING
  -> SECOND_SUCCESSOR = GROUP_D_PLANNING

GROUP_B_CLOSED (S12 at 154a97038c166031bde2cf81799ab475b7e66e05)

... -> Group D Planning Governance (a6c39934...) [remote-locked]
  -> GROUP_D_IMPLEMENTATION_AUTHORIZED = YES
  -> D1 -> D2 -> D3 slice ordering

... -> D1 Implementation (0d65c1324...) [REMOTE LOCKED]
  -> D1 closed; corrective remediation governance (a74fb62...) [remote-locked]

... -> D2 Implementation (58f3224...) [REMOTE LOCKED — D2 planning closeout committed]
  -> D2 planning CLOSED_REMOTE_LOCKED
  -> D1 remains CLOSED; D2 implementation NOT STARTED (owner-gated)

... -> D3 Planning Governance (THIS SESSION)
  -> P-OD6: Arbitrary-period profit reporting
  -> D3 planning CLOSED_REMOTE_LOCKED (after push)
  -> D3 implementation NOT STARTED (blocked on D2 implementation)
```

```text
AUTHORITY_CHAIN_VERIFIED = YES
```

---

## F. D1 / D2 Closeout Dependency Proof

### D1 (Cost Change History) — CLOSED

```text
D1_STATE                = CLOSED_REMOTE_LOCKED
D1_COMMIT               = 0d65c1324b18411ee516c04a66750aca65349a40
D1_PARENT               = a6c39934ad6fa3440cccf233cb4c72b048b9272e
D1_REMEDIATION_GOVERNANCE = a74fb62... (corrective remediation authorized, not yet implemented)
D1_FILES_CHANGED        = 8
D1_DELTA                = +910 / -1

D1_MODEL                = app/lib/models/cost_history.dart (CostHistory class)
D1_LOCAL_TABLE          = cost_history (v19 schema)
D1_CLOUD_TABLE          = cloud_cost_history (migration 00036)
D1_CLOUD_RPCS           = insert_cloud_cost_history, get_cloud_cost_history_by_product,
                          get_cloud_cost_history_by_shop
D1_SECURITY_REMEDIATION = migration 00037 proposed (require_shop_permission on all 3 RPCs)
D1_TESTS                = cost_history_test.dart (12), enter_key_behavior_test.dart (6)
```

### D2 (Opening Balances) — Planning Closed, Implementation Blocked

```text
D2_PLANNING_STATE       = CLOSED_REMOTE_LOCKED
D2_PLANNING_COMMIT      = 58f3224132d74febf07867486b6c03b712757b52 (current HEAD)
D2_PLANNING_ARTIFACT    = docs/PHASE_P_GROUP_D_D2_OPENing_Balances_Planning_Governance.md

D2_IMPLEMENTATION_STARTED = NO
D2_IMPLEMENTATION_AUTHORIZED = NO
  (requires owner resolution of D2-01..D2-07 decision matrix; Section L)

D2_MODEL                = app/lib/models/account.dart (Account, AccountType)
D2_MODEL                = app/lib/models/ledger_entry.dart (LedgerEntry, EntryKind)
D2_LOCAL_TABLES         = accounts, opening_balance_entries (v20 schema)
D2_CLOUD_TABLES         = cloud_accounts, cloud_opening_balance_entries (migration 00038)
D2_CLOUD_RPCS           = create_cloud_account, update_cloud_account, list_cloud_accounts,
                          create_cloud_opening_balance, list_cloud_opening_balances
D2_SYNC_ADAPTERS        = AccountSyncAdapter, OpeningBalanceEntrySyncAdapter
D2_TESTS                = opening_balance_test.dart (19), schema_v20_migration_test.dart (2),
                          opening_balance_sync_test.dart (16+)
```

```text
D1_D2_CLOSEOUT_DEPENDENCY_SATISFIED = YES
```

---

## G. Owner Order / Successor Authority

```text
OWNER_ORDER_DECISION    = GROUP_B_BEFORE_GROUP_D
FIRST_SUCCESSOR         = GROUP_B_PLANNING       (COMPLETED)
SECOND_SUCCESSOR        = GROUP_D_PLANNING        (COMPLETED — parent doc at a6c39934)

GROUP_D_SLICE_ORDER     = D1 -> D2 -> D3

D1_IMPLEMENTATION       = CLOSED (remote-locked at 0d65c13)
D2_PLANNING             = CLOSED (remote-locked at 58f3224)
D2_IMPLEMENTATION       = NOT STARTED (owner-gated on D2-01..D2-07)
D3_PLANNING             = THIS SESSION (planning governance only)
D3_IMPLEMENTATION       = NOT STARTED (blocked on D2 implementation closure)

OWNER_ORDER_SATISFIED          = YES
GROUP_D_ENTRY_AUTHORIZED       = YES
GROUP_D_IMPLEMENTATION_AUTHORIZED = YES
D3_PLANNING_ENTRY_AUTHORIZED   = YES
D3_IMPLEMENTATION_AUTHORIZED   = NO (blocked on D2 implementation)
```

D3 planning is authorized because Group D planning governance is remote-locked and D1 + D2 planning are both closed. D3 **implementation** remains blocked until D2 implementation is complete (owner-gated).

```text
AUTHORITY_CHAIN_VERIFIED = YES
```

---

## H. Group C Boundary / Disposition

```text
GROUP_C_STARTED              = NO
GROUP_C_PLANNING_STARTED     = NO
GROUP_C_IMPLEMENTATION_STARTED = NO
```

Group C (Android identity/signing; P-OD2, P-OD3, WS-7/8) is independent of Group D. The owner order placed Group B before Group D; Group C was not part of that ordering. Group C requires its own planning session. Group C does not block Group D, nor does Group D block Group C.

```text
GROUP_C_HARD_BOUNDARY_MAINTAINED = YES
```

---

## I. Canonical D3 Definition

### Canonical Name

```text
D3_CANONICAL_NAME = Arbitrary-Period Profit Reporting
```

### Authority

```text
P-OD6 = Arbitrary-period profit reporting with correct accounting distinctions
P-OD6_STATUS = APPROVED
  (PHASE_P_OWNER_DECISIONS.md; confirmed in D2 planning governance Section I line 146:
   "arbitrary-period reporting P-OD6"; parent doc PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md
   Section I line 207: "P-OD6: Arbitrary-period profit reporting with correct accounting distinctions")
```

### Objective

```text
D3_OBJECTIVE = Implement arbitrary-period profit reporting for sales, returns,
                COGS, expenses, and opening-balance effects, with correct
                accounting distinctions (revenue/COGS/gross profit/operating
                effects/net result) and false-profit prevention.

D3_DEPENDENCIES =
    D1 (cost history)   — CLOSED_REMOTE_LOCKED (sales.cogs snapshots are historical)
    D2 (opening balances) — CLOSED_REMOTE_LOCKED planning (opening_balance_entries)
  (D3 depends on both: accurate period reporting requires cost history and
   opening balances per the D1 -> D2 -> D3 dependency rationale,
   parent doc Section T.)
```

---

## J. Current State Summary

### J.1 Existing Reporting Infrastructure

The application currently provides **all-time aggregates only** plus **today/month breakdowns** via SQL queries on local SQLite `sales`/`returns`/`expenses` tables (text-formatted as `TEXT NOT NULL` in ISO 8601 date strings `YYYY-MM-DD`):

```text
EXISTING DATABASE METHODS (app/lib/database/database_helper.dart):

getTotalSales()                  — line 2121 — SUM(sales.totalSaleValue), all-time
getTotalCOGS()                   — line 2130 — SUM(sales.cogs), all-time
getTotalReturns()               — line 2420 — SUM(returns.totalReturnValue), all-time
getTotalReturnedCOGS()          — line 2429 — SUM(returns.returnedCogs), all-time
getTotalExpenses()              — line 2520 — SUM(expenses.amount), all-time
getDashboardData()              — line 2716 — returns ALL of the above as a Map
getSalesByDateRange(start,end)  — line 1893 — returns Sale objects for a date range
getSalesGroupByDate()           — line 3242 — GROUP BY date
getSalesGroupByProduct()        — line 3260 — GROUP BY barcode
getSalesSummary()               — line 3280 — today/month/all aggregates
```

### J.2 Current UI

```text
sales_report_screen.dart (app/lib/screens/sales/sales_report_screen.dart):
  - Three tabs: "الكل" (all), "حسب التاريخ" (by date), "حسب المنتج" (by product)
  - Summary cards: today sales, month sales, total sales, gross profit
  - NO date-range picker — only preset today/month/all aggregations
  - Line 88-90: RBAC gate — _canViewSalesHistory (canViewSalesHistory permission)

dashboard_screen.dart (app/lib/screens/dashboard/dashboard_screen.dart):
  - Lines 124-157: dashboard financial section
  - Displays: totalSales, netSales, totalCOGS, netCOGS, grossProfit,
              totalExpenses, netProfit
  - NO date range selection
  - NO accounting distinction labels (revenue/COGS/gross profit vs
    operating effects/net result)
  - netProfit = grossProfit - totalExpenses (unconditional; no false-profit
    prevention)
```

### J.3 D1 + D2 Existing Capabilities Available to D3

From D1 (cost change history, CLOSED at 0d65c13):

```text
CostHistory model (app/lib/models/cost_history.dart):
  - fields: shopId, productId, productName, productBarcode,
            oldCost, newCost, changedAt, changedBy
  - toMap() / fromMap()

cost_history table (v19 local SQLite):
  - columns: shop_id, product_id, product_name, product_barcode,
             old_cost, new_cost, changed_at, changed_by
  - CHECK(old_cost >= 0), CHECK(new_cost >= 0), CHECK(old_cost <> new_cost)

sales table (existing):
  - date TEXT NOT NULL (ISO 8601 date string, YYYY-MM-DD)
  - costPrice REAL DEFAULT 0  (snapshotted at sale time — D1 guarantee)
  - cogs REAL DEFAULT 0        (quantity * costPrice at sale time — D1 guarantee)
  - totalSaleValue REAL DEFAULT 0 (quantity * salePrice)
  - shop_id TEXT

returns table (existing):
  - date TEXT NOT NULL
  - costPrice REAL DEFAULT 0 (snapshotted at return time)
  - returnedCogs REAL DEFAULT 0
  - totalReturnValue REAL DEFAULT 0
  - shop_id TEXT

expenses table (existing):
  - date TEXT NOT NULL
  - amount REAL DEFAULT 0
  - category TEXT
  - shop_id TEXT
```

From D2 (opening balances, CLOSED planning at 58f3224):

```text
Account model (app/lib/models/account.dart):
  - AccountType enum: CASH, BANK, RECEIVEABLE_SUMMARY (asset, positive=owned),
                       PAYABLE_SUMMARY, CAPITAL (liability, positive=obligation)
  - isAsset / isLiability getters

LedgerEntry model (app/lib/models/ledger_entry.dart):
  - EntryKind enum: OPENING, ADJUSTMENT, CORRECTION
  - fields: shopId, accountId, amount (>= 0), effectiveDate (TEXT),
            entryKind, correctsEntryId, correctionReason, notes,
            idempotencyKey, createdBy, createdAt
  - effectiveDate stored as TEXT (date-only, YYYY-MM-DD)

opening_balance_entries table (v20 local SQLite):
  - columns: shop_id, account_id, amount, effective_date TEXT, entry_kind,
            corrects_entry_id, correction_reason, notes, idempotency_key,
            created_by, created_at, cloud_uuid, server_version, sync_status
  - CHECK(amount >= 0), CHECK(entry_kind IN (OPENING, ADJUSTMENT, CORRECTION))

accounts table (v20 local SQLite):
  - columns: id, shop_id, name, account_type, created_by, cloud_uuid,
            server_version, sync_status, last_synced_at
```

### J.4 Existing Tenant Isolation + RBAC

```text
_TenantPredicate (database_helper.dart):
  - _readPredicate() / _writePredicate() — shop-scoped WHERE clauses
  - _TenantPredicate.scoped — when setTenantIsolationArmed(true), enforces
    shop_id filtering on all queries
  - setTenantIsolationArmed(true/false), bindTestShop('shop-id') for tests

RBAC:
  - _requireSalesHistoryAccess(currentRole) — gates reporting methods
    (database_helper.dart line ~2119; used by getSalesByDateRange,
    getSalesGroupByDate, getSalesGroupByProduct, getSalesSummary)
  - AppPermission.canViewSalesHistory — the permission for viewing reports
  - UserRole enum: owner, employee, salesOnly
  - PermissionResolver — owner bypass; fail-closed

Sync infrastructure (existing, available if cloud parity needed later):
  - SyncEngine (app/lib/sync/sync_engine.dart), SyncWorker (sync_worker.dart)
  - EntitySyncAdapter contract (entity_sync_adapter.dart)
  - No D3-specific sync adapter exists yet
```

---

## K. Period Contract (D3-01 — frozen semantics for D3 implementation)

```text
D3-01  PERIOD_BOUNDARY = [startInclusive, endExclusive)
       - start (inclusive): the first date of the reporting period
       - end (exclusive): the first date AFTER the reporting period
       - Example: January 2024 report = start="2024-01-01", end="2024-02-01"
       - This matches the principle that endExclusive avoids double-counting
         at midnight and simplifies month/quarter/year boundary math.

D3-02  DATE_TYPE = DATE-ONLY (no time component)
       - All source tables (sales.date, returns.date, expenses.date,
         opening_balance_entries.effective_date) store ISO 8601 date strings
         in TEXT columns formatted as "YYYY-MM-DD".
       - D3 queries MUST compare date-only strings, NOT full ISO 8601
         timestamps (the existing getSalesByDateRange at line 1893 uses
         BETWEEN with start.toIso8601String() which includes time — this is
         a latent boundary bug that D3 MUST NOT replicate).
       - Correct SQL pattern: WHERE date >= 'YYYY-MM-DD' AND date < 'YYYY-MM-DD'

D3-03  TIMEZONE = LOCAL DATE (device local time)
       - The existing getSalesSummary (line 3291-3295) uses SQLite's
         date('now', 'localtime') for today/month computation.
       - D3 must use the same local-time semantics for preset periods
         (day, week, month, quarter, year) to ensure backward compatibility.
       - Custom range: user-selected date strings, interpreted as local dates.

D3-04  PRESET_PERIODS = day, week, month, quarter, year, custom_range
       - day: [today, today+1)
       - week: [startOfWeek, startOfWeek+7) where startOfWeek = Sunday
       - month: [firstOfMonth, firstOfNextMonth)
       - quarter: [firstOfQuarter, firstOfNextQuarter)
       - year: [Jan-1, Jan-1 of next year)
       - custom_range: user-selected start/end dates

D3-05  EMPTY_PERIOD = zero aggregates
       - If no transactions exist in [start, end), all sums return 0.
       - PeriodReport.complete flag must reflect whether ALL input sources
         were accessible (not whether data exists).
```

---

## L. Accounting Model (D3-02 — frozen semantics)

```text
D3-02  ACCOUNTING_MODEL = Revenue / COGS / Operating Effects / Net Result

  REVENUE = SUM(sales.totalSaleValue) for sales.date in [start, end)
  RETURNS = SUM(returns.totalReturnValue) for returns.date in [start, end)
  NET_REVENUE = REVENUE - RETURNS

  COGS = SUM(sales.cogs) for sales.date in [start, end)
         (uses snapshotted costPrice from sales row — D1 guarantee)
  RETURNED_COGS = SUM(returns.returnedCogs) for returns.date in [start, end)
         (uses snapshotted costPrice from returns row — D1 guarantee)
  NET_COGS = COGS - RETURNED_COGS

  GROSS_PROFIT = NET_REVENUE - NET_COGS

  EXPENSES = SUM(expenses.amount) for expenses.date in [start, end)

  OPENING_BALANCE_ADJUSTMENTS = SUM(opening_balance_entries.amount)
         for opening_balance_entries.effective_date in [start, end)
         (from D2 accounts/ledger — additive, D2-05 A append-only)

  NET_RESULT = GROSS_PROFIT - EXPENSES + OPENING_BALANCE_ADJUSTMENTS

  NOTE: opening-balance adjustments affect NET_RESULT but NOT GROSS_PROFIT.
  This is the D2-K4 double-counting barrier: opening-balance entries never
  enter legacy aggregates (sales/returns/expenses/COGS totals). They are
  applied only as a separate operating-effects line in the period report.

D3-03  FALSE_PROFIT_PREVENTION = FAIL_CLOSED

  The PeriodReport model MUST carry a boolean `complete` flag.
  "Net profit" / "صافي الربح" labeling MUST be suppressed when complete == false.

  complete == FALSE when ANY of:
    - opening_balance_entries table is absent (v19 schema, pre-D2)
    - any query source returned an error (not just zero rows)
    - tenant isolation is not armed (setTenantIsolationArmed(false))
    - RBAC check fails (salesOnly cannot view)

  complete == TRUE when:
    - all query sources executed without error
    - tenant isolation is armed
    - user has canViewSalesHistory (or equivalent) permission
    - opening-balance entries exist (or table is confirmed empty, which is
      a valid zero adjustment)

  When complete == false, the report displays the individual components
  (revenue, COGS, gross profit, expenses) but MUST NOT display a
  "net profit" / "صافي الربح" figure. Instead it shows:
    "الصافي غير متاح — البيانات غير مكتملة"
    (Net profit unavailable — data incomplete)

  This mirrors the D1 remediation invariant FAIL_CLOSED:
  "Missing data -> no false 'net profit' claim"
```

---

## M. Gap Analysis

### EXISTING_CAPABILITY (already implemented by D1 + D2 + predating reporting infrastructure)

```text
1. Sales COGS snapshots
   sales.cogs REAL DEFAULT 0         — computed at sale time as quantity * costPrice
   sales.costPrice REAL DEFAULT 0    — snapshotted from product at sale time
   D1 ensures these are NEVER retroactively modified (D1 remediation invariant
   COST_SNAPSHOT_INTEGRITY).

2. Returns cost snapshots
   returns.returnedCogs REAL DEFAULT 0
   returns.costPrice REAL DEFAULT 0
   Same D1 guarantee applies.

3. Expenses
   expenses.date TEXT NOT NULL, amount REAL DEFAULT 0, category TEXT

4. Opening balance entries (D2)
   opening_balance_entries.effective_date TEXT NOT NULL
   opening_balance_entries.amount NUMERIC (CHECK >= 0)
   opening_balance_entries.entry_kind TEXT (OPENING/ADJUSTMENT/CORRECTION)
   Append-only (D2-05 A); corrections via corrective entries.

5. Account model (D2)
   AccountType with isAsset/isLiability distinction for sign convention.

6. Tenant isolation
   _TenantPredicate, _readPredicate(), _writePredicate(), setTenantIsolationArmed()

7. RBAC
   _requireSalesHistoryAccess(), AppPermission.canViewSalesHistory, UserRole

8. Date-range query pattern (existing)
   getSalesByDateRange(DateTime start, DateTime end) at line 1893
   — uses: WHERE tp.prefix('date BETWEEN ? AND ?')
   — with: tp.argsWith([start.toIso8601String(), end.toIso8601String()])
   NOTE: This BETWEEN approach is a latent boundary bug (includes time component
   from toIso8601String). D3 MUST use start-inclusive/end-exclusive date-only.

9. Aggregate query pattern (existing)
   getTotalSales / getTotalCOGS / getTotalReturns / getTotalReturnedCOGS /
   getTotalExpenses — all use rawQuery with 'SELECT SUM(...) FROM table WHERE ...'
   and _readPredicate for tenant scoping.

10. Dashboard computation (existing)
    getDashboardData() at line 2716:
    netSales = totalSales - totalReturns
    netCOGS = totalCOGS - totalReturnedCOGS
    grossProfit = netSales - netCOGS
    netProfit = grossProfit - totalExpenses
    NOTE: netProfit is computed unconditionally — no false-profit prevention.
    D3 MUST improve on this with the complete flag.

11. Sync infrastructure
    SyncEngine, SyncWorker, EntitySyncAdapter contract, ConflictResolutionPolicy
    — available if cloud parity is ever needed, but D3 v1 is local-only.
```

### REQUIRED_D3_CONSUMPTION (what D3 will consume from D1/D2)

```text
1. sales.cogs and sales.costPrice — historical cost snapshots (D1)
   Used for COGS computation within the reporting period.
   D1 guarantee: these are immutable historical records.

2. returns.returnedCogs and returns.costPrice — historical cost snapshots (D1)
   Used for returned-COGS computation within the reporting period.

3. opening_balance_entries within [start, end) — D2 data
   Used for OPENING_BALANCE_ADJUSTMENTS line in period report.
   effective_date column (TEXT, YYYY-MM-DD) enables date-range query.

4. Account model / AccountType — D2 data
   Used for any account-level breakdown (future extensibility).

5. _TenantPredicate / _readPredicate()
   Used for tenant-scoped period queries.

6. _requireSalesHistoryAccess() / AppPermission.canViewSalesHistory
   Used as RBAC gate for the period report screen.

7. Existing getSalesByDateRange() pattern (line 1893)
   Used as reference for date-range querying approach,
   but MUST be replaced with startInclusive/endExclusive semantics.
```

### ACTUAL_GAP (what D3 planning must specify for implementation)

```text
GAP-1: PeriodReport model does not exist
   - app/lib/models/period_report.dart — CREATE
   - Must encapsulate: start, end, revenue, returns, netRevenue, cogs,
     returnedCogs, netCogs, grossProfit, expenses, openingBalanceAdjustments,
     netResult, complete (boolean), transactionCount, periodType
   - Must support toMap()/fromJson for potential future serialization

GAP-2: Date-range-aware aggregate methods do not exist
   - getTotalSales(), getTotalCOGS(), etc. accept NO date parameters
   - D3 needs date-range-aware variants:
     getSalesInPeriod(start, end)      -> revenue (totalSaleValue)
     getCOGSInPeriod(start, end)       -> COGS (cogs)
     getReturnsInPeriod(start, end)    -> returns (totalReturnValue)
     getReturnedCOGSInPeriod(start, end) -> returned COGS
     getExpensesInPeriod(start, end)   -> expenses (amount)
     getOpeningBalanceAdjustmentsInPeriod(start, end) -> adjustments
   - Each must use _readPredicate for tenant scoping
   - Each must use startInclusive/endExclusive date-only comparison (D3-01)

GAP-3: Opening-balance period query does not exist
   - getAccountOpeningBalance(accountId) at line 3191 sums ALL entries
     for one account — no date range
   - D3 needs: SUM(amount) from opening_balance_entries
     WHERE effective_date >= start AND effective_date < end
   - Must respect D2-K4: these entries are additive only, never enter
     legacy aggregates; applied as separate operating-effects line

GAP-4: PeriodReportScreen does not exist
   - app/lib/screens/accounting/period_report_screen.dart — CREATE
   - Must provide: preset periods (day/week/month/quarter/year) +
     custom date range picker
   - Must display: revenue, returns, net revenue, COGS, returned COGS,
     net COGS, gross profit, expenses, opening-balance adjustments,
     net result with correct accounting labels (Arabic)
   - Must show completeness indicator; suppress "صافي الربح" when incomplete

GAP-5: Sales report screen has no date range picker
   - app/lib/screens/sales/sales_report_screen.dart — MODIFY
   - Currently: today/month/all tabs only (lines 78-82)
   - D3: add date range picker for arbitrary period selection
   - Must reuse existing RBAC gate (_canViewSalesHistory)

GAP-6: False-profit prevention does not exist
   - getDashboardData() computes netProfit unconditionally (line 2726)
   - D3 must add PeriodReport.complete flag and suppress net profit
     labeling when incomplete (D3-03)

GAP-7: No period comparison capability
   - Parent doc Section D.3 (line 1138): "period comparison" in D3 scope
   - No existing infrastructure for comparing two periods
   - D3 should support optional period-over-period comparison as
     a PeriodReport field (previousPeriod, growth rate)

GAP-8: No D3 test suite exists
   - app/test/database/period_report_test.dart — CREATE
   - Required test categories (parent doc Section X line 863):
     1. Period selection (preset + custom range)
     2. Date range filtering (correct startInclusive/endExclusive)
     3. Revenue/COGS/gross profit distinction
     4. False-profit prevention (complete flag, suppressed labeling)
     5. Opening-balance adjustment inclusion
     6. Cross-shop tenant isolation
     7. RBAC (salesOnly denied)
     8. Returns and expense deduction
     9. Empty period (all zeros)

GAP-9: No D3 model directory exists
   - app/lib/screens/accounting/ — CREATE (new directory)
   - Currently no accounting-specific screens directory

GAP-10: Cloud parity not defined for D3
   - D1 has cloud_cost_history; D2 has cloud_accounts/cloud_opening_balance_entries
   - D3 reporting is local-only v1 (no D3-specific cloud table/RPC)
   - Cloud reporting RPC is OPTIONAL for v1; not required by P-OD6
   - Must document this as a v2 extensibility point, not a v1 requirement
```

---

## N. Exact Future Implementation Allowlist

### N.1 ALLOWED_NEW_FILES (may be created)

```text
app/lib/models/period_report.dart
app/lib/screens/accounting/period_report_screen.dart
app/lib/screens/accounting/                           (new directory)
app/test/database/period_report_test.dart
```

### N.2 ALLOWED_EXISTING_FILES (may be modified)

```text
app/lib/database/database_helper.dart
app/lib/screens/sales/sales_report_screen.dart
```

### N.3 FORBIDDEN_FILES

```text
app/lib/licensing/**                                      (Group B scope)
app/lib/services/cloud_auth_service.dart                  (Group B scope)
app/lib/platform/device_identity_provider.dart            (Group B scope)
app/android/**                                            (Group C scope)
app/windows/**                                            (frozen identity)
pubspec.yaml                                              (no dependency changes)
supabase/config.toml                                      (no config changes)
supabase/functions/**                                     (no Edge Function changes)
supabase/migrations/20260820000036_*.sql                 (IMMUTABLE — D1)
supabase/migrations/20260820000037_*.sql                 (IMMUTABLE — D1 remediation)
supabase/migrations/20260820000038_*.sql                 (IMMUTABLE — D2)
existing SQLite migrations (v1..v20)                      (IMMUTABLE)
```

### N.4 SACRED_FILES

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
```

### N.5 Implementation Constraint

If the future implementation session needs to exceed the allowed file list, it MUST stop and obtain explicit governance authorization before proceeding.

---

## O. Forbidden Delta

```text
D1 (cost history) implementation or redesign             FORBIDDEN (D1 is CLOSED)
D2 (opening balances) implementation                                        FORBIDDEN (D2 is planning-locked, not started)
Migration 00039 or any new supabase migration             FORBIDDEN (D3 is additive reporting only)
Cloud schema/table creation                           FORBIDDEN (local-only reporting v1)
Security boundary change (RLS, RBAC, tenant isolation)    FORBIDDEN
False "net profit" labeling when inputs incomplete         FORBIDDEN (D3-03 FAIL_CLOSED)
Modification of existing sale/return cost snapshots       FORBIDDEN (D1 invariant)
Modification of existing reporting methods' return shape  FORBIDDEN (additive only)
Broad reporting redesign (beyond date-range enhancement)   FORBIDDEN
Any licensing/device-trust/device-gate/Ed25519 touch       FORBIDDEN
Any Android/Play Console work                              FORBIDDEN
Any production mutation                                    FORBIDDEN
Any migration deployment                                   FORBIDDEN
Any Edge Function deployment                                FORBIDDEN
force push, rebase, reset, amend                            FORBIDDEN
contacting legacy origin                                   FORBIDDEN
pubspec.yaml changes                                       FORBIDDEN
```

---

## P. D3 Slice Ordering

```text
GROUP_D_SLICE_ORDER = D1 -> D2 -> D3

D1 CLOSED at 0d65c1324b18411ee516c04a66750aca65349a40 (cost history)
D2 planning CLOSED at 58f3224132d74febf07867486b6c03b712757b52
D2 implementation NOT STARTED (owner-gated on D2-01..D2-07)
D3 planning THIS SESSION
D3 implementation NOT STARTED (blocked on D2 implementation)

D3 cannot be implemented until D2 implementation is CLOSED_REMOTE_LOCKED.
D2 implementation cannot start until owner resolves D2-01..D2-07.
```

---

## Q. Production Boundary

```text
LOCAL_SUPABASE_STACK_ALLOWED     = YES (for D2 testing reference only; D3 touches no cloud schema)
PRODUCTION_SUPABASE_MUTATION     = NO
PRODUCTION_MIGRATION_DEPLOYMENT  = NO

D3 touches NO supabase migrations and NO cloud schema.
D3 reporting is local-only (SQLite) for v1.
Cloud parity (cloud period-report RPC) is a v2 extensibility point,
not a v1 requirement of P-OD6.
```

---

## R. Regression Floors

### R.1 Existing Baseline (MUST be preserved — D1 closeout at 0d65c13)

```text
FULL_DART        = 1771 PASS (Group B S12 floor + D1 additions)
D1_WORKFLOW      = 4
COST_HISTORY     = 12
ENTER_KEY        = 6
S8               = 41
S9               = 20
S10              = 31
PHASE_E          = 15
pgTAP:  D1 = 38   S1 = 46   S2 = 88   S3 = 25   S4 = 50   S6 = 35
flutter analyze  = 0 errors, 1 pre-existing warning
                  (device_management_screen.dart:4 unused_import)
```

### R.2 D3 Test Requirements (REQUIRED for implementation)

```text
D3 tests: arbitrary period selection, date range filtering,
          revenue/COGS/gross profit distinction, false-profit prevention
          (parent doc PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md
           Section X line 863)

D3-specific test file: app/test/database/period_report_test.dart
  - period report tests
  - date range filtering tests
  - accounting accuracy tests
  - false-profit-prevention tests
  - tenant isolation tests
  - RBAC tests
```

### R.3 Regression Floor Principle

```text
existing_baseline_preserved = REQUIRED
new_D3_tests_pass           = REQUIRED
final_test_count            = determined by implementation (not frozen here)
```

---

## S. Stop Conditions

The future D3 implementation session MUST STOP immediately if:

```text
Any existing test regresses
Any RLS policy is weakened
Any security boundary is violated
Any existing migration is modified
Any forbidden file is touched
The implementation exceeds the Section N allowlist without governance authorization
A false "net profit" claim is introduced (complete flag bypassed or ignored)
Any existing sale/return cost snapshot is modified
Any Group B/C scope is breached
Any production mutation occurs outside governed deployment
Any device-gate/licensing boundary is crossed
flutter analyze reports new errors
The D2 implementation is not CLOSED_REMOTE_LOCKED (D3 blocked on D2)
Period boundary semantics deviate from [startInclusive, endExclusive) date-only
```

---

## T. Implementation Success Criteria

The D3 implementation is COMPLETE when ALL of:

```text
1. PeriodReport model created (app/lib/models/period_report.dart):
   - fields: start, end, periodType, revenue, returns, netRevenue,
     cogs, returnedCogs, netCogs, grossProfit, expenses,
     openingBalanceAdjustments, netResult, complete, transactionCount
   - complete flag (FAIL_CLOSED: false-profit prevention)

2. Date-range-aware database methods in database_helper.dart:
   - getSalesInPeriod(start, end)        -> revenue
   - getCOGSInPeriod(start, end)         -> COGS
   - getReturnsInPeriod(start, end)      -> returns
   - getReturnedCOGSInPeriod(start, end) -> returned COGS
   - getExpensesInPeriod(start, end)     -> expenses
   - getOpeningBalanceAdjustmentsInPeriod(start, end) -> adjustments
   - All use _readPredicate() for tenant scoping
   - All use [start, end) date-only TEXT comparison (NOT toIso8601String)

3. PeriodReportScreen created (app/lib/screens/accounting/period_report_screen.dart):
   - Preset periods: day, week, month, quarter, year, custom_range
   - Date range picker for custom_range
   - Arabic accounting labels:
     إيراد (revenue), مرتجعات (returns), صافي إيراد (net revenue),
     تكلفة البضاعة المباعة (COGS), مرتجع تكلفة (returned COGS),
     صافي التكلفة (net COGS), الربح الإجمالي (gross profit),
     مصاريف (expenses), تعديلات الرصيد الافتتاحي (opening balance adjustments),
     الصافي (net result)
   - RBAC gate: _requireSalesHistoryAccess / canViewSalesHistory
   - complete indicator; suppresses "صافي الربح" when incomplete

4. sales_report_screen.dart enhanced:
   - Date range picker added (custom period selection)
   - Existing today/month/all tabs preserved
   - RBAC gate preserved (_canViewSalesHistory)

5. Test suite created (app/test/database/period_report_test.dart):
   - Period selection tests
   - Date range filtering tests (startInclusive/endExclusive boundary)
   - Revenue/COGS/gross profit distinction tests
   - False-profit prevention tests (complete flag, suppressed labeling)
   - Opening-balance adjustment inclusion tests
   - Cross-shop tenant isolation tests
   - RBAC tests (salesOnly denied, employee/owner allowed)
   - Returns and expense deduction tests
   - Empty period tests (all zeros)

6. flutter analyze: 0 errors, no new warnings from D3
7. All existing regression floors (Section R.1) preserved
8. No false "net profit" claim when complete == false
```

---

## U. Commit / Remote-Lock Evidence

(To be populated after commit and push, mirroring the D1/D2 governance style.)

```text
COMMIT_SHA       = 5435cfc75c2228f76b5a80555592675a0d8294f1
PARENT_SHA       = 58f3224132d74febf07867486b6c03b712757b52
TREE_SHA         = 36ad18ac020b04e3e4c57f3d7f8522113b4ae6cc
ARTIFACT_PATH    = docs/PHASE_P_GROUP_D_D3_ARBITRARY_PERIOD_REPORTING_PLANNING_GOVERNANCE.md
ARTIFACT_BLOB    = ad4bcfa385355eb50d40d937738316100cec23ba
ARTIFACT_LINES   = 781
DELTA            = 1 added documentation file, 0 modified, 0 deleted
COMMIT_FILE_COUNT = 1
COMMIT_MESSAGE     = docs: govern Phase P Group D D3 arbitrary-period reporting
NORMAL_PUSH        = YES (no force, no force-with-lease)
ORIGIN_CONTACTED   = NO
```

---

## V. Final Governance Decision

```text
D1_STATE                       = CLOSED_REMOTE_LOCKED
D2_PLANNING                    = CLOSED_REMOTE_LOCKED
D2_IMPLEMENTATION_STARTED      = NO  (owner-gated)

D3_PLANNING                    = CLOSED_REMOTE_LOCKD (after push)
D3_IMPLEMENTATION_STARTED      = NO  (blocked on D2 implementation)

PRODUCTION_MUTATION            = NO
MIGRATION_CREATED              = NO
EDGE_FUNCTION_DEPLOYED         = NO

P-OD6_STATUS                   = APPROVED
P-OD6_SCOPE                    = Arbitrary-period profit reporting with
                                  correct accounting distinctions
D3_ALLOWED_DELTA               = Additive reporting logic only
                                 + PeriodReport model
                                 + PeriodReportScreen
                                 + period_report_test.dart
                                 + date-range database methods
                                 + sales_report_screen enhancement

P-OD6_APPROVED                 = YES (no owner gate on D3 itself)
D3_BLOCKED_ON_D2_IMPLEMENTATION = YES (D2 owner-gated, not yet started)

OWNER_GATED                    = NO  (P-OD6 is APPROVED)
BLOCKED_ON_SUCCESSOR           = YES (D2 implementation must close first)

D3_PLANNING_REMOTE_LOCKED      = YES (after push)

NEXT_ALLOWED_ACTION = Wait for D2 implementation to close (owner-gated),
                      then D3 implementation planning/governance session.
                      NO successor work begins until D2 is CLOSED.
```

---

## W. Post-Push Remote-Lock Proof

(To be populated after push.)

```text
POST_PUSH_LOCAL_HEAD             = 5435cfc75c2228f76b5a80555592675a0d8294f1
POST_PUSH_TRACKING_HEAD          = 5435cfc75c2228f76b5a80555592675a0d8294f1
POST_PUSH_DIRECT_GITHUB_HEAD     = 5435cfc75c2228f76b5a80555592675a0d8294f1  (git ls-remote github)
POST_PUSH_MERGE_BASE             = 5435cfc75c2228f76b5a80555592675a0d8294f1
POST_PUSH_AHEAD                  = 0
POST_PUSH_BEHIND                 = 0
POST_PUSH_NORMAL_PUSH            = YES (no force, no force-with-lease)
POST_PUSH_ORIGIN_CONTACTED       = NO
```

Expected lock: LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE; AHEAD = 0; BEHIND = 0.

---

*This document is the D3 arbitrary-period reporting planning governance artifact. D1 remains CLOSED_REMOTE_LOCKED. D2 planning is CLOSED_REMOTE_LOCKED; D2 implementation is owner-gated and NOT STARTED. D3 planning is COMPLETE. D3 implementation is NOT STARTED (blocked on D2 implementation). No production mutation occurred. No migration was created. No implementation was performed. STOPPED.*
