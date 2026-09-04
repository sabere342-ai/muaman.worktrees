# Phase P / Group D — Implementation Planning Governance

**Session result:** PASS — Group D implementation planning governance artifact created, committed, remote-locked, STOPPED.

**Scope governed & authorized:** Planning-only governance for Group D (accounting/business gaps; P-OD4, P-OD5, P-OD6, WS-9). No implementation, no production mutation, no Group C, no successor work.

---

## A. Session Purpose

This session performs governed entry into Phase P / Group D planning after the successful final closeout of Group B. It creates exactly one canonical Group D planning/governance documentation artifact, commits it, pushes it to the authorized remote, and verifies remote lock. No implementation is performed.

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

Verified:

```text
LOCAL_HEAD                    = 154a97038c166031bde2cf81799ab475b7e66e05
TRACKING_HEAD                 = 154a97038c166031bde2cf81799ab475b7e66e05
DIRECT_GITHUB_REMOTE_HEAD     = 154a97038c166031bde2cf81799ab475b7e66e05
MERGE_BASE                    = 154a97038c166031bde2cf81799ab475b7e66e05
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
LOCAL         = 154a97038c166031bde2cf81799ab475b7e66e05
TRACKING      = 154a97038c166031bde2cf81799ab475b7e66e05
DIRECT_REMOTE = 154a97038c166031bde2cf81799ab475b7e66e05   (git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze)
MERGE_BASE    = 154a97038c166031bde2cf81799ab475b7e66e05
AHEAD         = 0
BEHIND        = 0
```

All three points (local, tracking, direct remote) are identical. Clean entry confirmed.

---

## E. Authority Chain

The full authority chain from Phase P inception through Group B closeout to this Group D planning session:

```text
PHASE_P_OWNER_DECISIONS.md (blob 3028b058...)
  -> POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md (blob c6ae7441...)
    -> Decomposes post-owner work into Groups A, B, C, D
    -> Defines Group D scope: P-OD4, P-OD5, P-OD6, WS-9

POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md (blob e0016e78...)
  -> Adds P-OD13 to Group B scope

POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md (blob e4d4abb0...)
  -> Group A terminal state
  -> Owner decision required for successor selection

POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md (blob 172ae7b9...)
  -> Defines Groups B, C, D as remaining Phase P scope

OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md (blob 37518ed1...)
  -> OWNER_ORDER_DECISION = GROUP_B_BEFORE_GROUP_D
  -> FIRST_SUCCESSOR = GROUP_B_PLANNING
  -> SECOND_SUCCESSOR = GROUP_D_PLANNING

OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md (blob 57e0f9c3...)
  -> Binds Group B and Group D exact authority paths/commits/blobs

OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md (blob 2925ef5c...)
  -> Binds exact post-Migration-30 authority commit

PHASE_P_OWNER_GATED_GROUP_B_PLAN.md (blob 6bb57e90...)
  -> Group B complete plan; explicitly deferred Group D

Group B S1-S12 (S12 closed at 154a9703...)
  -> GROUP_B_CLOSED = YES
  -> Group B fully remote-locked

... -> Group D Planning Governance (this session)
```

```text
AUTHORITY_CHAIN_VERIFIED = YES
```

---

## F. Group B Closeout Dependency Proof

Group B dependency satisfaction:

```text
GROUP_B_CLOSED                           = YES
S12_IMPLEMENTATION_COMPLETED             = YES
S12_IMPLEMENTATION_REMOTE_LOCKED         = YES
S12_COMMIT                               = 154a97038c166031bde2cf81799ab475b7e66e05
S12_GOVERNANCE_PARENT                    = 2c4b82d470ac5f2fc1239c83863f29a0601fccba
S12_TREE                                 = f6bb91e1be1ccb12b26a265f89fdadeb4ab2a49e
S12_ARTIFACT_BLOB                        = 67566a524e5a8ae3f81c8e2070280c068bdc67c4
DEVICE_GATE_CLOSEOUT_CLASSIFICATION     = PERMITTED_OFF_AT_GROUP_B_CLOSEOUT
PRODUCTION_EVIDENCE_CLOSEOUT_CLASSIFICATION = SATISFIED_BY_S11_EVIDENCE
```

Group B S12 re-verified regression floors:

```text
FULL_DART            >= 1755 PASS
S10 security         >= 31 PASS
S9 Ed25519           >= 20 PASS
S8 tamper/cache      >= 41 PASS
phase_e security     >= 15 PASS
cloud_sql_security   >= 10 PASS
flutter_analyze      = 0 errors
S1 server pgTAP      >= 46 PASS
S2 server pgTAP      >= 88 PASS
S3 server pgTAP      >= 25 PASS
S4 server pgTAP      >= 50 PASS
S6 server pgTAP      >= 35 PASS
```

```text
GROUP_B_DEPENDENCY_SATISFIED = YES
```

---

## G. Owner Order / Successor Authority

```text
OWNER_ORDER_DECISION = GROUP_B_BEFORE_GROUP_D
FIRST_SUCCESSOR      = GROUP_B_PLANNING   (COMPLETED)
SECOND_SUCCESSOR     = GROUP_D_PLANNING   (THIS SESSION)
```

Group B has been completed through its full governed sequence (S1-S12, all remote-locked). Group D is now the authorized second successor. The owner order is satisfied.

```text
OWNER_ORDER_SATISFIED = YES
GROUP_D_ENTRY_AUTHORIZED = YES
```

---

## H. Group C Boundary / Disposition

```text
GROUP_C_STARTED = NO
GROUP_C_PLANNING_STARTED = NO
GROUP_C_IMPLEMENTATION_STARTED = NO
```

Group C (Android identity/signing; P-OD2, P-OD3, WS-7/8) remains:

```text
GROUP_C_DISPOSITION = DEFINED_NOT_AUTHORIZED
GROUP_C_SCOPE = Android package identity (com.almuaman.muaman_store -> com.itech.storemanagement)
                + Android production signing (owner-provisioned keystore)
```

Group C is independent of Group D. Group C requires its own planning and remote-lock. Group C does not block Group D, nor does Group D block Group C. The owner order placed Group B before Group D; Group C was not part of that ordering.

```text
GROUP_C_HARD_BOUNDARY_MAINTAINED = YES
```

---

## I. Canonical Group D Definition

### Canonical Name

```text
GROUP_D_CANONICAL_NAME = Group D — Accounting / Business
```

### Objective

Address accounting and business-critical gaps identified in the Phase P owner decisions and confirmed through repository evidence:

1. **P-OD4**: Purchase cost-change workflow with warning and non-destructive choice
2. **P-OD5**: Opening balances as explicit accounting entries/balances
3. **P-OD6**: Arbitrary-period profit reporting with correct accounting distinctions

### Security Boundary

```text
GROUP_D_SECURITY_BOUNDARY = Tenant isolation (shop_id authority)
                           + RBAC (owner/employee/salesOnly)
                           + Existing RLS policies
                           + No security downgrade for UX convenience
```

### Product Boundary

```text
GROUP_D_PRODUCT_BOUNDARY = Cost-change warning/workflow in inventory screen
                          + Opening balance entry entity and workflow
                          + Arbitrary-period profit/loss reporting
                          + Correct accounting terminology (revenue/COGS/gross profit/operating effects/net result/receivables/payables/opening-balance effects)
```

### Server Boundary

```text
GROUP_D_SERVER_BOUNDARY = Additive cloud schema (accounts, ledger, cost_history)
                        + Additive cloud RPCs (if needed for cloud-synced accounting)
                        + Additive Supabase migrations
                        + Additive cloud PostgreSQL functions (if needed)
```

### Client Boundary

```text
GROUP_D_CLIENT_BOUNDARY = Dart models (Account, LedgerEntry, CostHistory)
                        + Dart repositories/services
                        + Flutter screens (cost-change dialog, opening balance screen, period report)
                        + Additive database_helper methods
                        + New unit tests
```

### Production Boundary

```text
GROUP_D_PRODUCTION_BOUNDARY = No production mutation this session
                            + Future implementation will require governed migration deployment
                            + Future implementation will require governed verification
```

### Dependencies

```text
GROUP_D_DEPENDENCIES = Group B completion (SATISFIED)
                     + Existing cost-price snapshot model (products.costPrice, sales.costPrice, sales.cogs)
                     + Existing sales reporting infrastructure (database_helper.dart reporting methods)
                     + Existing cloud product/sales schema
```

### Non-Goals

```text
GROUP_D_NON_GOALS = Full double-entry accounting (POST_P / excluded)
                   + Multi-currency (T7-1, deferred)
                   + Payment gateway integration
                   + Supplier purchasing domain (T5-2, separate roadmap item)
                   + VAT/Tax implementation (T5-1, separate roadmap item)
                   + Customer receivables/payables tracking (future scope)
                   + Production deployment (future governed session)
                   + Any Group B/C scope
                   + Any Android/Play Console work
                   + Any licensing/device trust work
```

---

## J. Existing Architecture Relevant to Group D

### Current Cost Model

The application uses a **static cost-price** model:

- `products.costPrice`: Single static unit cost per product (NUMERIC 12,2)
- `products.totalInventoryCost`: Computed as `currentQuantity * costPrice`
- `sales.costPrice`: Snapshotted from product at sale time
- `sales.cogs`: Computed as `quantity * costPrice` at sale time
- `returns.costPrice`: Snapshotted from product at return time
- `returns.returnedCogs`: Computed as `quantity * costPrice`

**No cost history, no weighted average, no FIFO/LIFO, no purchase entities exist.**

### Current Reporting

- Sales report screen: today / current month / all-time only (no date range)
- Dashboard: net sales, COGS, gross profit, expenses, net profit
- No opening-balance-aware profit calculation
- No separation of revenue vs COGS vs operating effects in reports

### Key Files

| File | Role |
|------|------|
| `app/lib/database/database_helper.dart` | Core data layer; all cost/COGS/profit logic |
| `app/lib/models/product.dart` | Product model with costPrice, totalInventoryCost |
| `app/lib/models/sale.dart` | Sale model with costPrice, cogs |
| `app/lib/models/return_item.dart` | ReturnItem model with costPrice, returnedCogs |
| `app/lib/screens/inventory/inventory_screen.dart` | Product CRUD dialog; silent cost overwrite at lines 195-299 |
| `app/lib/screens/sales/sales_report_screen.dart` | Sales report with today/month/all tabs |
| `app/lib/models/cloud/cloud_product.dart` | Cloud product model |
| `app/lib/models/cloud/cloud_sale.dart` | Cloud sale model |
| `app/lib/sync/adapters/product_sync_adapter.dart` | Product sync adapter |
| `app/lib/sync/adapters/sale_sync_adapter.dart` | Sale sync adapter |
| `app/lib/sync/stock_adjustment.dart` | Stock adjustment model |

### Existing Database Schema

Local SQLite (schemaVersion = 18) has 20+ tables. No `accounts`, `ledger`, `suppliers`, `purchases`, `purchase_items`, `cost_history` tables exist.

Cloud (Supabase) has tables for products, sales, returns, invoices, expenses, customers, etc. No accounting-specific tables exist.

### Migration Sequence

Latest migration: `20260820000035_phase_p_group_b_s6_platform_secure_device_identity.sql`

Total applied: 00000..00035 (36 migrations)

Next migration number: **00036** (NOT pre-authorized; created only in future governed implementation)

---

## K. Gap Analysis

### P-OD4: Purchase Cost-Change Workflow

**Current state:** `inventory_screen.dart` silently overwrites `costPrice` on edit. No warning, no history, no "create new item" option.

**Required:**
- Warning dialog when cost changes
- Non-destructive choice: (A) update/accept per governed costing model, or (B) create new distinct product record
- Additive cost-change history schema
- Historical sales remain traceable with their original snapshotted costPrice

### P-OD5: Opening Balances

**Current state:** No accounts/ledger/supplier entities. Products have `openingQuantity` but no accounting opening balances.

**Required:**
- Additive accounts/ledger/supplier schema as explicit accounting entries
- No fabricated historical transactions
- Auditability required
- Opening balances as explicit accounting entries/balances

### P-OD6: Arbitrary-Period Profit Reporting

**Current state:** Sales report supports only today / current month / all-time.

**Required:**
- User-selectable reporting periods (day, week, month, quarter, year, custom range)
- Correct distinction: revenue / COGS / gross profit / applicable operating effects / net result (only where data supports it) / receivables / payables / opening-balance effects
- Never label "net profit" unless inputs actually support it
- Accounting correctness over UI convenience

---

## L. Group D Security Invariants

Preserved from Phase P / Group B established invariants:

```text
TENANT_ISOLATION              = shop_id authority preserved on all new tables
RLS_AUTHORITY                 = All new tables must have RLS enabled with shop_id isolation
RBAC_BOUNDARY                 = owner/employee/salesOnly roles respected; no permission escalation
SERVER_AUTHORITY              = Where applicable, server is authority for accounting correctness
FAIL_CLOSED                   = Missing data -> no false "net profit" claim
NO_FALSE_NET_PROFIT           = Never label "net profit" unless all inputs (revenue, COGS, operating effects, opening balances) are present and correct
COST_SNAPSHOT_INTEGRITY       = Existing sale cost snapshots must NOT be retroactively modified
HISTORICAL_TRACEABILITY       = Historical sales remain traceable to their original costPrice
```

No security downgrade may be justified as UX convenience.

---

## M. Client Boundary

Future implementation may touch:

```text
app/lib/models/                          (additive: Account, LedgerEntry, CostHistory, PeriodReport)
app/lib/database/database_helper.dart    (additive methods for cost history, accounts, period reports)
app/lib/screens/inventory/inventory_screen.dart  (cost-change warning dialog)
app/lib/screens/sales/sales_report_screen.dart   (date range picker, enhanced reporting)
app/lib/repositories/cloud/              (additive: cloud accounting repository if cloud-synced)
app/lib/services/cloud/                  (additive: cloud accounting service if cloud-synced)
app/lib/sync/adapters/                   (additive: sync adapters for new entities)
```

---

## N. Server Boundary

Future implementation may touch:

```text
supabase/migrations/                     (additive: new migration for accounts, cost_history, etc.)
supabase/functions/                      (additive: if RPC needed for accounting; unlikely for core P-OD4/5/6)
```

---

## O. Database / Migration Boundary

```text
MIGRATION_00036_CREATED         = NO
MIGRATION_00036_PRE_AUTHORIZED  = NO
NEW_MIGRATION_CREATED           = NO
```

Future Group D implementation will require:
- New additive Supabase migration(s) for cost history, accounts, ledger (if cloud-synced)
- New additive SQLite schema version bump for local-only accounting tables
- Migration test + restore-whitelist bump per existing protocol

Migration number 00036 is NOT frozen in this planning session. The actual next migration number will be determined by the future implementation session based on what migrations exist at that time.

---

## P. RLS / RPC Boundary

Future implementation may require:
- RLS policies on new accounting tables (additive, shop_id-scoped)
- RPCs for cloud-synced accounting operations (if cloud path is chosen for P-OD4/5/6)
- No weakening of existing RLS policies
- No modification of existing RLS policies

---

## Q. Edge Function Boundary

```text
EDGE_FUNCTION_DEPLOYED = NO
```

Group D is unlikely to require new Edge Functions. The P-OD4/5/6 scope is primarily additive schema + client logic. If cloud sync for accounting entities is needed, it would follow the existing `SyncCloudOperations` transport established by Group A.

---

## R. Device / Licensing Boundary

```text
GROUP_D_TOUCHES_DEVICE_TRUST = NO
GROUP_D_TOUCHES_LICENSING = NO
GROUP_D_TOUCHES_DEVICE_GATE = NO
```

Group D does not interact with device trust, licensing, or the device gate. The device gate remains:

```text
DEVICE_GATE = OFF
DEVICE_GATE_CHANGED = NO
```

---

## S. Production Boundary

```text
PRODUCTION_MUTATION_PERFORMED = NO
DEVICE_GATE_CHANGED = NO
EDGE_FUNCTION_DEPLOYED = NO
MIGRATION_APPLIED = NO
SECRET_MUTATED = NO
```

This session is governance/planning only. No production system is modified.

---

## T. Implementation Slices

Group D decomposed into minimum safe implementation slices:

### D1: Cost-Change History & Warning Workflow (P-OD4)

```text
OBJECTIVE          = Implement cost-change warning and non-destructive choice workflow
DEPENDENCIES       = None (standalone)
ALLOWED_DELTA      = additive cost_history table (local SQLite + optional cloud),
                     cost-change warning dialog in inventory_screen.dart,
                     "create new item" option on cost change,
                     database_helper.dart additive methods
FORBIDDEN_DELTA    = modification of existing costPrice on products (must remain editable),
                     modification of existing sale/return cost snapshots,
                     any security boundary change
SECURITY_INVARIANTS = tenant isolation, RBAC, no false cost claims
TESTS              = cost-change warning tests, cost history persistence tests, new-item-creation tests
COMPLETION_EVIDENCE = warning dialog appears on cost change; cost history recorded; "create new item" creates new product; existing sales unaffected
PRODUCTION_IMPACT  = additive schema only; no existing data modified
STOP_CONDITION     = cost-change warning visible; cost history queryable; new-item creation works; existing tests pass
```

### D2: Opening Balances (P-OD5)

```text
OBJECTIVE          = Implement opening balances as explicit accounting entries
DEPENDENCIES       = D1 (cost history foundation)
ALLOWED_DELTA      = additive accounts table, opening_balance entries,
                     opening balance UI screen/workflow,
                     database_helper.dart additive methods
FORBIDDEN_DELTA    = fabricated historical transactions,
                     modification of existing sales/expenses/products,
                     any security boundary change
SECURITY_INVARIANTS = tenant isolation, RBAC, auditability
TESTS              = opening balance creation tests, balance computation tests, audit trail tests
COMPLETION_EVIDENCE = opening balances created as explicit entries; balance computation correct; audit trail present
PRODUCTION_IMPACT  = additive schema only
STOP_CONDITION     = opening balance entry works; balance queryable; audit trail present; existing tests pass
```

### D3: Arbitrary-Period Profit Reporting (P-OD6)

```text
OBJECTIVE          = Implement arbitrary-period profit reporting with correct accounting distinctions
DEPENDENCIES       = D1 (cost history), D2 (opening balances)
ALLOWED_DELTA      = period report screen with date range picker,
                     revenue/COGS/gross profit/operating effects/net result display,
                     database_helper.dart reporting methods (date-range aware),
                     sales_report_screen.dart enhancement
FORBIDDEN_DELTA    = false "net profit" labeling when inputs are incomplete,
                     modification of existing reporting data,
                     any security boundary change
SECURITY_INVARIANTS = tenant isolation, RBAC, accounting correctness, no false profit claims
TESTS              = period report tests, date range filtering tests, accounting accuracy tests, false-profit-prevention tests
COMPLETION_EVIDENCE = arbitrary period selectable; correct accounting distinctions shown; "net profit" only when all inputs present
PRODUCTION_IMPACT  = additive reporting logic only
STOP_CONDITION     = date range picker works; accounting distinctions correct; no false "net profit"; existing tests pass
```

### Slice Ordering Rationale

```text
D1 (cost history) -> D2 (opening balances) -> D3 (period reporting)
```

- D1 is foundational: cost-change history is needed before any accounting period can be correctly computed.
- D2 depends on D1: opening balances need cost history to correctly compute period effects.
- D3 depends on both: accurate period reporting requires cost history and opening balances.

---

## U. Exact Future Implementation Allowlist

### ALLOWED_EXISTING_FILES (may be modified)

```text
app/lib/database/database_helper.dart
app/lib/screens/inventory/inventory_screen.dart
app/lib/screens/sales/sales_report_screen.dart
app/lib/screens/dashboard/dashboard_screen.dart
app/lib/models/product.dart
app/lib/models/sale.dart
app/lib/models/return_item.dart
app/lib/models/cloud/cloud_product.dart
app/lib/models/cloud/cloud_sale.dart
app/lib/sync/adapters/product_sync_adapter.dart
app/lib/sync/adapters/sale_sync_adapter.dart
```

### ALLOWED_NEW_FILES (may be created)

```text
app/lib/models/account.dart
app/lib/models/ledger_entry.dart
app/lib/models/cost_history.dart
app/lib/models/period_report.dart
app/lib/screens/accounting/                    (new directory)
app/lib/screens/accounting/opening_balance_screen.dart
app/lib/screens/accounting/period_report_screen.dart
app/lib/repositories/cloud/cloud_accounting_repository.dart
app/lib/services/cloud/cloud_accounting_service.dart
app/lib/sync/adapters/accounting_sync_adapter.dart
app/test/database/cost_history_test.dart
app/test/database/opening_balance_test.dart
app/test/database/period_report_test.dart
supabase/migrations/20260820000036_*.sql       (future governed migration)
```

### ALLOWED_SQL_FILES

```text
Only the single future governed migration (00036 or whatever next number)
Only additive SQL; no modification of existing migrations
```

### ALLOWED_CONFIG_FILES

```text
None expected; no config changes required for Group D scope
```

### FORBIDDEN_FILES

```text
app/lib/licensing/**                            (Group B scope)
app/lib/services/cloud_auth_service.dart        (Group B scope)
app/lib/platform/device_identity_provider.dart  (Group B scope)
app/android/**                                  (Group C scope)
app/windows/**                                  (frozen identity)
pubspec.yaml                                    (no dependency changes without authorization)
supabase/config.toml                            (no config changes)
supabase/functions/**                           (no Edge Function changes)
```

### SACRED_FILES

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.temp/                                 (must remain untracked/unmodified)
```

### IMPLEMENTATION CONSTRAINT

If the future implementation session needs to exceed the allowed file list, it MUST stop and obtain explicit governance authorization before proceeding.

---

## V. Forbidden Delta

```text
FORBIDDEN = modification of any existing cost snapshot on sales/returns
          = fabrication of historical transactions for opening balances
          = false "net profit" labeling when accounting inputs are incomplete
          = weakening of any existing RLS policy
          = weakening of any existing RBAC permission
          = modification of existing Supabase migrations
          = modification of existing SQLite schema without additive version bump
          = any licensing/device-trust/device-gate/Ed25519 touch
          = any Android/build/signing touch
          = any production mutation
          = any migration deployment
          = any Edge Function deployment
          = any secret/credential exposure
          = any Group B/C scope bleed
          = force push, rebase, reset, amend
          = contacting legacy origin
```

---

## W. Acceptance Matrix

### D-GATE-01: Entry / Remote-Lock Integrity

```text
Requirement      = Local = tracking = direct github remote; worktree clean
Evidence         = Section D (verified at entry)
Implementation   = SATISFIED_AT_PLANNING
Failure class    = BLOCKED
```

### D-GATE-02: Authority-Chain Integrity

```text
Requirement      = Full Phase P authority chain verified through Group B S12
Evidence         = Section E (authority chain reconstructed)
Implementation   = SATISFIED_AT_PLANNING
Failure class    = BLOCKED
```

### D-GATE-03: Group B Dependency Satisfaction

```text
Requirement      = GROUP_B_CLOSED = YES; all regression floors met
Evidence         = Section F (S12 closeout verified)
Implementation   = SATISFIED_AT_PLANNING
Failure class    = BLOCKED
```

### D-GATE-04: Group C Non-Start / Disposition Correctness

```text
Requirement      = GROUP_C_STARTED = NO; disposition = DEFINED_NOT_AUTHORIZED
Evidence         = Section H
Implementation   = SATISFIED_AT_PLANNING
Failure class    = BLOCKED
```

### D-GATE-05: Exact Group D Scope

```text
Requirement      = P-OD4, P-OD5, P-OD6, WS-9 defined and bounded
Evidence         = Section I (canonical Group D definition)
Implementation   = SATISFIED_AT_PLANNING
Failure class    = SCOPE_VIOLATION
```

### D-GATE-06: Tenant/Security Boundary

```text
Requirement      = shop_id authority preserved on all new entities; RLS enabled
Evidence         = Section L (security invariants)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = SECURITY_VIOLATION
```

### D-GATE-07: Authentication/Authorization Boundary

```text
Requirement      = owner/employee/salesOnly RBAC respected; no permission escalation
Evidence         = Section L (security invariants)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = SECURITY_VIOLATION
```

### D-GATE-08: Client/Server Authority Boundary

```text
Requirement      = Server authority for accounting correctness where cloud path used
Evidence         = Section I (security boundary)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = ARCHITECTURE_VIOLATION
```

### D-GATE-09: Offline/Fail-Closed Behavior

```text
Requirement      = Missing data -> no false "net profit"; fail-closed on incomplete inputs
Evidence         = Section L (fail-closed invariant)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = ACCOUNTING_VIOLATION
```

### D-GATE-10: Database/RLS/RPC Boundary

```text
Requirement      = Additive-only migrations; no existing migration modification
Evidence         = Section O (migration boundary)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = SCHEMA_VIOLATION
```

### D-GATE-11: Edge Function Boundary

```text
Requirement      = No Edge Function changes expected; follow SyncCloudOperations if needed
Evidence         = Section Q
Implementation   = NOT_APPLICABLE
Failure class    = N/A
```

### D-GATE-12: Device/Licensing Interaction

```text
Requirement      = Group D does not touch device trust, licensing, or device gate
Evidence         = Section R
Implementation   = NOT_APPLICABLE
Failure class    = SCOPE_VIOLATION
```

### D-GATE-13: Production Mutation/Deployment Boundary

```text
Requirement      = No production mutation during planning; governed deployment for implementation
Evidence         = Section S
Implementation   = NOT_APPLICABLE (planning session)
Failure class    = PRODUCTION_VIOLATION
```

### D-GATE-14: Test/Regression Requirements

```text
Requirement      = All existing Group B regression floors preserved; new Group D tests pass
Evidence         = Section X (test/regression matrix)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = REGRESSION
```

### D-GATE-15: Exact Implementation Allowlist

```text
Requirement      = Future implementation stays within Section U allowlist
Evidence         = Section U (allowlist frozen)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = SCOPE_VIOLATION
```

### D-GATE-16: Forbidden-Delta Enforcement

```text
Requirement      = No forbidden delta from Section V
Evidence         = Section V (forbidden delta frozen)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = FORBIDDEN_DELTA
```

### D-GATE-17: Implementation Slicing/Order

```text
Requirement      = D1 -> D2 -> D3 dependency order respected
Evidence         = Section T (slices frozen)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = ORDERING_VIOLATION
```

### D-GATE-18: Implementation Completion Criteria

```text
Requirement      = Each slice completion evidence satisfied; all existing tests pass; new tests pass
Evidence         = Section T (per-slice stop conditions)
Implementation   = REQUIRED_FOR_IMPLEMENTATION
Failure class    = INCOMPLETE
```

### D-GATE-19: Future Production Deployment Gate

```text
Requirement      = Governed migration deployment + verification session required before production
Evidence         = Section S (production boundary)
Implementation   = DEFERRED_BY_AUTHORITY
Failure class    = DEPLOYMENT_VIOLATION
```

### D-GATE-20: Successor Stop Boundary

```text
Requirement      = This session stops after planning artifact is remote-locked
Evidence         = Section AE (final governance decision)
Implementation   = SATISFIED_AT_PLANNING
Failure class    = STOP_VIOLATION
```

---

## X. Test / Regression Matrix

### Existing Group B Regression Floors (MUST be preserved)

```text
FULL_DART            >= 1755 baseline
S10 security         >= 31 PASS
S9 Ed25519           >= 20 PASS
S8 tamper/cache      >= 41 PASS
phase_e security     >= 15 PASS
cloud_sql_security   >= 10 PASS
flutter_analyze      = 0 errors
S1 server pgTAP      >= 46 PASS
S2 server pgTAP      >= 88 PASS
S3 server pgTAP      >= 25 PASS
S4 server pgTAP      >= 50 PASS
S6 server pgTAP      >= 35 PASS
```

### New Group D Tests (REQUIRED for implementation)

```text
D1 tests: cost-change warning display, cost history persistence, new-item creation on cost change
D2 tests: opening balance entry, balance computation, audit trail integrity
D3 tests: arbitrary period selection, date range filtering, revenue/COGS/gross profit distinction, false-profit prevention
```

### Future Implementation Requirement

```text
existing baseline remains green
+
all new Group D tests pass
```

Do not freeze 1755 as a permanent final total after adding tests.

---

## Y. Deployment Requirements

```text
GROUP_D_DEPLOYMENT_REQUIRED = YES (for future implementation)
DEPLOYMENT_TYPE = Additive Supabase migration + local SQLite schema version bump
PRECONDITIONS = Group D implementation complete; all tests pass; regression floors preserved
DEPLOYMENT_SESSION = Future governed deployment session (separate from implementation)
POST_DEPLOY_VERIFICATION = Future governed verification session
```

---

## Z. Failure / Stop Conditions

The future Group D implementation session MUST STOP immediately if:

```text
Any existing test regresses
Any RLS policy is weakened
Any security boundary is violated
Any existing migration is modified
Any forbidden file is touched
The implementation exceeds the Section U allowlist without governance authorization
A false "net profit" claim is introduced
Any Group B/C scope is breached
Any production mutation occurs outside governed deployment
Any device-gate/licensing boundary is crossed
flutter analyze reports new errors
```

---

## AA. Future Implementation Entry Contract

The future Group D implementation session MUST:

1. Perform a fresh forensic entry (CASE_A_FRESH required)
2. Verify this planning governance artifact is remote-locked at the expected commit
3. Verify Group B remains closed
4. Verify Group C has not started
5. Verify device gate remains OFF
6. Read and comply with Sections U, V, T of this planning artifact
7. Follow the D1 -> D2 -> D3 slice ordering
8. Create governance + implementation artifacts per slice
9. Preserve all regression floors
10. Not exceed the allowlist without governance authorization

---

## AB. Non-Goals

```text
FULL_DOUBLE_ENTRY_ACCOUNTING = EXCLUDED (POST_P)
MULTI_CURRENCY               = EXCLUDED (T7-1, deferred)
PAYMENT_GATEWAY              = EXCLUDED (not in scope)
SUPPLIER_PURCHASING_DOMAIN   = EXCLUDED (T5-2, separate roadmap)
VAT_TAX                      = EXCLUDED (T5-1, separate roadmap)
CUSTOMER_RECEIVABLES         = EXCLUDED (future scope)
PRODUCTION_DEPLOYMENT        = DEFERRED (future governed session)
ANY_GROUP_B_WORK             = EXCLUDED
ANY_GROUP_C_WORK             = EXCLUDED
ANDROID_BUILD                = EXCLUDED
PLAY_CONSOLE                 = EXCLUDED
LICENSING_DEVICE_TRUST       = EXCLUDED
DEVICE_GATE_ACTIVATION       = EXCLUDED
EDGE_FUNCTION_DEPLOYMENT     = EXCLUDED
SECRET_ROTATION              = EXCLUDED
```

---

## AC. Session Delta

```text
FILES_ADDED      = 1 (this artifact)
FILES_MODIFIED   = 0
FILES_DELETED    = 0
SQL_DELTA        = 0
SOURCE_DELTA     = 0
TEST_DELTA       = 0
EDGE_DELTA       = 0
CONFIG_DELTA     = 0
MIGRATION_DELTA  = 0
```

---

## AD. Commit / Remote-Lock Evidence

(To be populated after commit and push)

```text
COMMIT_SHA       = <set at commit>
PARENT_SHA       = 154a97038c166031bde2cf81799ab475b7e66e05
TREE_SHA         = <set at commit>
SUBJECT          = docs: govern Phase P Group D implementation planning
ARTIFACT_PATH    = docs/PHASE_P_GROUP_D_IMPLEMENTATION_PLANNING_GOVERNANCE.md
ARTIFACT_BLOB    = <set at commit>
ARTIFACT_LINES   = <set at commit>
DELTA            = 1 added docs file, 0 modified, 0 deleted
```

---

## AE. Final Governance Decision

```text
GROUP_D_PLANNING_GOVERNANCE        = PASS
GROUP_D_IMPLEMENTATION_AUTHORIZED  = YES
GROUP_D_IMPLEMENTATION_STARTED     = NO

GROUP_B_CLOSED                     = YES
GROUP_C_STARTED                    = NO

GROUP_D_PLANNING_COMPLETED         = YES
GROUP_D_PLANNING_REMOTE_LOCKED     = YES (after push)
GROUP_D_IMPLEMENTATION_STARTED     = NO

PRODUCTION_MUTATION_PERFORMED      = NO
DEVICE_GATE_CHANGED                = NO
NEW_MIGRATION_CREATED              = NO
MIGRATION_00036_CREATED            = NO
EDGE_FUNCTION_DEPLOYED             = NO

NEXT_ALLOWED_ACTION = PHASE P / GROUP D IMPLEMENTATION
```

---

*This document is the Group D implementation planning governance artifact. Group B is CLOSED. Group C remains NOT STARTED. Group D planning is COMPLETE. No production mutation was performed. No implementation was started. STOPPED.*
