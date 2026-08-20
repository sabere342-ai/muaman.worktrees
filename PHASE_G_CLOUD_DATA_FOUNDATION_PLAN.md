# PHASE G: CLOUD DATA FOUNDATION PLAN

**Phase:** G - Cloud Data Foundation
**Project:** I Tech Store Management Application
**Institutional Owner:** I Tech for Technology / I Tech للتكنولوجيا
**Repository:** C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
**Branch:** codex/i-tech-next-roadmap-freeze
**Date:** 2026-08-20
**Status:** Planning artifact - not implemented

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | G - Cloud Data Foundation |
| Session Type | PHASE_G_PLANNING |
| Baseline Commit | `17934ad94c5d2e32ae53e2122f8b460a14ed2efb` |
| Predecessor Phase | F - Server-Side RBAC & Permission Sync (CLOSED) |
| Successor Phase | H - Offline Sync Core |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Phase F Closure | `PASS_PHASE_F_REMOTE_LOCKED` |

---

## 2. Verified Starting Baseline

```
PHASE_F_PLANNING_COMMIT      = c518310050a8328877f321ada6428f20d6e07057
PHASE_F_IMPLEMENTATION_COMMIT = 17934ad94c5d2e32ae53e2122f8b460a14ed2efb
IMPLEMENTATION_PARENT         = c518310050a8328877f321ada6428f20d6e07057
PLANNING_TAG                  = phase-f-planning-baseline-locked -> c518310050a8328877f321ada6428f20d6e07057
IMPLEMENTATION_TAG            = phase-f-implementation-locked -> 17934ad94c5d2e32ae53e2122f8b460a14ed2efb
LOCAL_HEAD_BEFORE             = 17934ad94c5d2e32ae53e2122f8b460a14ed2efb
REMOTE_HEAD_BEFORE            = 17934ad94c5d2e32ae53e2122f8b460a14ed2efb
LOCAL_AHEAD_BEFORE            = 0
REMOTE_AHEAD_BEFORE           = 0
```

### Verification Evidence

```
G-P01: Repository root    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze (verified)
G-P02: Branch              = codex/i-tech-next-roadmap-freeze (verified)
G-P03: GitHub remote       = github -> https://github.com/sabere342-ai/muaman.worktrees.git (verified)
G-P04: HEAD                = 17934ad94c5d2e32ae53e2122f8b460a14ed2efb (verified)
G-P05: HEAD^               = c518310050a8328877f321ada6428f20d6e07057 (verified)
G-P06: Planning tag        = c518310050a8328877f321ada6428f20d6e07057 (verified)
G-P07: Implementation tag  = 17934ad94c5d2e32ae53e2122f8b460a14ed2efb (verified)
G-P08: Divergence          = 0    0 (verified)
```

---

## 3. Governing Requirements

### 3.1 Master Plan Mandates

From `PROJECT_MASTER_PLAN.md`:
- Section 4 #1: Zero data loss
- Section 4 #2: Atomicity survives migration
- Section 4 #3: Dual-layer enforcement
- Section 4 #4: Offline by default
- Section 4 #7: Additive-only schema evolution
- Section 9 #1: Cloud authority with local cache
- Section 9 #2: UUID for cloud, integer for local
- Section 9 #4: Soft delete for sync
- Section 9 #5: Idempotent operations
- Section 9 #7: Fail-closed authorization
- Section 12: All 18 permission IDs FROZEN (add-only)
- Section 12: Inventory formula INVARIANT
- Section 12: Sale atomicity INVARIANT
- Section 12: COGS snapshot INVARIANT
- Section 16: All 16 current capabilities preserved + cloud

### 3.2 Architecture Plan Mandates

From `PRODUCTIZATION_ARCHITECTURE_PLAN.md`:
- Section 1: SQLite -> cloud evolution
- Section 9: UUID cloud PK, integer local PK; server_version, updated_at, deleted_at
- Section 10: Inventory invariant: currentQuantity = opening - sold + returned + adjustment
- Section 17: Schema v12 for Phase G (sync_version, deleted_at, updated_at)
- Section 20: P2 FIX_DURING_PHASE_G: Product deletion orphans inventory_count
- Section 20: P2 FIX_DURING_PHASE_G: UI does not catch DB duplicate barcode
- Section 20: P3 FIX_DURING_PHASE_G: Missing .trim() on some inputs

### 3.3 Phase F Handoff

Phase F established:
- Server-side RBAC via `require_shop_permission(UUID, TEXT)` function
- 18 canonical permission IDs with `check_effective_permission` resolution
- Per-shop permission overrides via `shop_permission_overrides` table
- Audit trail via `permission_audit_log` table
- Licensing + RBAC composition: `require_shop_permission` checks membership -> license -> permission
- `sync_user_permissions()` RPC for client permission cache refresh

Phase G must reuse all of the above. No second authorization system.

---

## 4. Current Local Data Architecture

### 4.1 SQLite Schema (Version 9)

Database: `muaman_store.db` via `sqflite_ffi`
Tables: 12 total
Migration path: v1 -> v2 -> v3 -> v4 -> v5 -> v6 -> v7 -> v8 -> v9

| Table | PK | Local Columns (excluding shop_id, cloud_uuid) |
|-------|-----|------------------------------------------------|
| products | id INTEGER AUTOINCREMENT | name, barcode (UNIQUE), openingQuantity, soldQuantity, returnedQuantity, currentQuantity, costPrice, totalInventoryCost, inventoryAdjustment |
| sales | id INTEGER AUTOINCREMENT | invoiceId, date, productName, barcode, quantity, salePrice, totalSaleValue, costPrice, cogs |
| returns | id INTEGER AUTOINCREMENT | date, productName, barcode, quantity, salePrice, totalReturnValue, costPrice, returnedCogs |
| expenses | id INTEGER AUTOINCREMENT | date, description, amount, category |
| expense_categories | id INTEGER AUTOINCREMENT | name (UNIQUE) |
| invoices | id INTEGER AUTOINCREMENT | invoiceNumber (UNIQUE), date, customerName, paymentMethod, totalAmount, totalItems, createdAt, customerId |
| customers | id INTEGER AUTOINCREMENT | name, phone, address, notes, isActive, isSystem, createdAt, updatedAt |
| inventory_count | id INTEGER AUTOINCREMENT | productId (FK->products.id), actualQuantity, notes, countDate |
| import_batches | id INTEGER AUTOINCREMENT | file_sha256 (UNIQUE), file_name, imported_at, products_count, sales_count, returns_count, expenses_count, adjustments_count, total_quantity, total_inventory_value, total_sales, total_returns, net_sales, total_cogs, returned_cogs, net_cogs, gross_profit, total_expenses, net_profit, reconciliation_json |
| app_settings | key TEXT | value |
| role_permissions | role TEXT | permissions, updatedAt |
| users | id INTEGER AUTOINCREMENT | displayName, username (UNIQUE), passwordHash, role, isActive, createdAt, updatedAt, lastLoginAt |

### 4.2 Explicit Local Indexes

| Table | Index | Column(s) |
|-------|-------|-----------|
| customers | idx_customers_name | name |
| customers | idx_customers_isActive | isActive |
| invoices | idx_invoices_customerId | customerId |
| products | UNIQUE on barcode | barcode |
| expense_categories | UNIQUE on name | name |
| import_batches | UNIQUE on file_sha256 | file_sha256 |
| users | UNIQUE on username | username |

### 4.3 Key Local Relationships

| Relationship | Local Columns | FK Enforced? |
|-------------|---------------|-------------|
| product -> sale | sales.barcode <-> products.barcode | NO (logical) |
| product -> return | returns.barcode <-> products.barcode | NO (logical) |
| product -> inventory_count | inventory_count.productId <-> products.id | YES |
| invoice -> sale | sales.invoiceId <-> invoices.id | NO (logical) |
| invoice -> customer | invoices.customerId <-> customers.id | NO (logical) |
| expense -> category | expenses.category <-> expense_categories.name | NO (text match) |

### 4.4 Inventory Formula (Verified from Code)

```
currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment
totalInventoryCost = currentQuantity * costPrice
```

### 4.5 Financial Calculations (Verified from Code)

- Per-sale: `totalSaleValue = quantity * salePrice`, `cogs = quantity * costPrice`
- Per-return: `totalReturnValue = quantity * salePrice`, `returnedCogs = quantity * costPrice`
- Dashboard: `netSales = totalSales - totalReturns`, `netCOGS = totalCOGS - totalReturnedCOGS`, `grossProfit = netSales - netCOGS`, `netProfit = grossProfit - totalExpenses`

### 4.6 Transaction Boundaries (Verified from Code)

| Operation | Transactional? | Pattern |
|-----------|:---:|---------|
| insertSaleAndDecrementStock | YES | db.transaction: insert sale + optimistic lock update product |
| insertInvoiceWithItems | YES | db.transaction: insert invoice + loop insert sales + optimistic lock per product |
| updateSale | YES | db.transaction: revert old product, apply new product |
| insertReturn | YES | db.transaction: insert return + update product returnedQuantity |
| updateReturn | YES | db.transaction: revert old, apply new |
| saveInventoryCount | YES | db.transaction: insert count + optimistic lock product update |
| deleteProduct | YES | db.transaction: check references then delete |
| insertProduct | NO | Single db.insert |
| updateProduct | NO | Single db.update |
| insertExpense | NO | Single db.insert |
| deleteSale | NO | revertSoldQuantity() then db.delete() - NOT transactional |
| deleteReturn | NO | revertReturnedQuantity() then db.delete() - NOT transactional |

### 4.7 Delete Behavior (Verified from Code)

- ALL deletes are PHYSICAL (hard deletes) in current SQLite
- deleteProduct: blocked if references exist in sales/returns/inventory_count
- deleteExpenseCategory: blocked if any expense uses the category name
- archiveCustomer: sets isActive = 0 (logical archive)
- deleteSale: reverts soldQuantity then physical delete
- deleteReturn: reverts returnedQuantity then physical delete

### 4.8 App Settings Classification

**Cloud-syncable (tenant business settings):**

| Key | Default | Purpose |
|-----|---------|---------|
| shopProfile.shopName | المحل | Shop display name |
| shopProfile.ownerOrManagerName | empty | Owner/manager name |
| shopProfile.phone | empty | Shop phone |
| shopProfile.address | empty | Shop address |
| supportPhone | +201014900211 | Support phone (invoice footer) |
| brandColor | #0D47A1 | Brand color hex |
| invoiceTitle | فاتورة بيع | Invoice header text |
| invoiceFooterText | شكرا لتعاملكم معنا | Invoice footer text |
| buttonStyle | filled | UI button style preference |

**Device-local settings (NOT cloud-syncable):**

| Key | Reason |
|-----|--------|
| workbookPath | Filesystem-specific path |
| backupDirectory | Filesystem-specific path |
| thermalPrinterName | Device-specific printer |
| thermalPaperWidth | Device-specific setting |
| thermalPrintCopies | Device-specific setting |
| device.installationId | Device identity |

**License/Permission cache (managed by existing services, NOT cloud-synced):**

| Key Pattern | Manager |
|-------------|---------|
| licenseStatus | EntitlementCache |
| cloud.license.{shopId} | EntitlementCache |
| cloud.permissions.{shopId} | PermissionCache |
| cloud.auth.email | CloudAuthService |
| cloud.lastShopId | ShopResolver |
| shopProfile.cloudUuid | ShopProfileRepository |

**Frozen/legacy keys:** licenseKey (disabled), defaultCustomerName (removed in v8)

### 4.9 Migration v9: Cloud Readiness Columns

Schema v9 added `shop_id TEXT` and `cloud_uuid TEXT` to all 12 tables. Currently nullable (empty for existing data). Used by Phase I legacy migration.

---

## 5. Current Cloud Architecture

### 5.1 Existing Cloud Tables (10)

| Table | Phase | Purpose |
|-------|-------|---------|
| shops | C | Tenant root entity |
| shop_members | C | User-to-shop membership with role |
| roles | C | Per-shop role definitions |
| role_permissions_cloud | C | Per-role permission assignments |
| devices | C | Device registration |
| licenses | C/E | Shop licensing |
| activations | C/E | Device-license activation |
| invitations | D | Employee invitation tracking |
| shop_permission_overrides | F | Per-shop permission customization |
| permission_audit_log | F | Permission change audit trail |

### 5.2 Existing SECURITY DEFINER Functions (18)

| # | Function | Auth | Owner-Only | Phase |
|---|----------|------|-----------|-------|
| 1 | `create_shop_with_owner(p_name)` | auth.uid() | No | C |
| 2 | `get_user_shops()` | auth.uid() | No | C |
| 3 | `verify_shop_membership(p_shop_id)` | auth.uid() | No | C |
| 4 | `start_trial(p_shop_id)` | auth.uid() | Yes | E |
| 5 | `verify_trial_status(p_shop_id)` | None | No | E |
| 6 | `accept_invitation(p_shop_id, p_user_id)` | None | No | D |
| 7 | `verify_license_entitlement(p_shop_id)` | auth.uid() | No | E |
| 8 | `register_device(...)` | auth.uid() | No | E |
| 9 | `activate_device(...)` | auth.uid() | No | E |
| 10 | `deactivate_device(p_activation_id)` | auth.uid() | Yes | E |
| 11 | `get_device_list(p_shop_id)` | auth.uid() | Yes | E |
| 12 | `check_effective_permission(...)` | Internal | No | F |
| 13 | `get_effective_permissions(p_shop_id)` | auth.uid() | No | F |
| 14 | `require_shop_permission(p_shop_id, p_perm)` | auth.uid() | No | F |
| 15 | `sync_user_permissions(p_shop_id)` | auth.uid() | No | F |
| 16 | `get_shop_permission_overrides(p_shop_id)` | auth.uid() | Yes | F |
| 17 | `set_shop_permission_override(...)` | auth.uid() | Yes | F |
| 18 | `delete_shop_permission_override(...)` | auth.uid() | Yes | F |

### 5.3 RLS Strategy (Current)

All 10 existing tables use SELECT-only RLS policies based on shop_members membership. No INSERT/UPDATE/DELETE policies. All mutations go through SECURITY DEFINER functions.

### 5.4 Existing Indexes (18 explicit)

| Table | Index | Columns |
|-------|-------|---------|
| shops | idx_shops_owner_user_id | owner_user_id |
| shops | idx_shops_updated_at | updated_at |
| shop_members | idx_shop_members_shop_id | shop_id |
| shop_members | idx_shop_members_user_id | user_id |
| shop_members | idx_shop_members_shop_user | (shop_id, user_id) |
| roles | idx_roles_shop_id | shop_id |
| role_permissions_cloud | idx_role_permissions_cloud_role_id | role_id |
| devices | idx_devices_shop_id | shop_id |
| devices | idx_devices_installation_id | installation_id |
| devices | idx_devices_installation_shop (UNIQUE) | (installation_id, shop_id) |
| licenses | idx_licenses_shop_id | shop_id |
| licenses | idx_licenses_license_key | license_key |
| activations | idx_activations_license_id | license_id |
| activations | idx_activations_device_id | device_id |
| invitations | idx_invitations_shop_email | (shop_id, email) |
| invitations | idx_invitations_status | status |
| shop_permission_overrides | idx_shop_permission_overrides_shop_role | (shop_id, role) |
| permission_audit_log | idx_permission_audit_shop | (shop_id, created_at DESC) |

### 5.5 Edge Functions

| Function | Method | Purpose | Phase |
|----------|--------|---------|-------|
| invite-employee | POST | Creates auth user + membership + invitation | D |

---

## 6. Local -> Cloud Entity Gap Matrix

| Local Entity | Exists Locally | Exists Cloud | Cloud Required in G | Shop Scoped | UUID PK | Financial | Permission |
|-------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| products | YES (12 cols) | NO | YES | YES | YES | YES | inventory.view/edit/delete |
| customers | YES (10 cols) | NO | YES | YES | NO explicit | NO | inventory.view/edit |
| sales | YES (10 cols) | NO | YES | YES | YES | YES | sales.view/create/delete |
| returns | YES (10 cols) | NO | YES | YES | YES | YES | returns.view/create/delete |
| invoices | YES (10 cols) | NO | YES | YES | YES | YES | sales.view/create |
| expenses | YES (5 cols) | NO | YES | YES | YES | YES | expenses.view/create/delete |
| expense_categories | YES (2 cols) | NO | YES | YES | NO explicit | NO | expenses.view/create/delete |
| inventory_count | YES (6 cols) | NO | YES | YES | YES | NO | stocktake.view |
| import_batches | YES (20 cols) | NO | DEFER to H | YES | YES | YES | inventory.edit |
| app_settings | KEY-VALUE | NO | PARTIAL | YES | N/A | NO | admin.settings.access |
| users | YES (10 cols) | NO | NO (cloud uses auth.users + shop_members) | N/A | N/A | NO | admin.users.manage |
| role_permissions | YES (3 cols) | YES | NO (already exists) | YES | N/A | NO | admin.permissions.manage |

### Phase G creates 9 new cloud tables:

1. cloud_products
2. cloud_customers
3. cloud_sales
4. cloud_returns
5. cloud_expenses
6. cloud_expense_categories
7. cloud_invoices
8. cloud_inventory_count
9. cloud_shop_settings (key-value for tenant business settings)

### Phase G creates SECURITY DEFINER functions for:
- Simple CRUD (products, customers, expense_categories)
- Atomic compound operations (sales, returns, invoices)
- Inventory count operations
- Shop settings read/write

### Phase G does NOT create:
- import_batches cloud table (deferred to Phase N)
- User migration (Phase I handles user identity mapping)
- Sync infrastructure (Phase H)

### Discrepancy: Architecture Plan vs. Implementation

The `PRODUCTIZATION_ARCHITECTURE_PLAN.md` Section 17 lists Phase G as creating local schema v12 with `sync_version`, `deleted_at`, `updated_at` columns. However:
- `server_version`, `updated_at`, `deleted_at` are sync-engine columns owned by Phase H
- Phase G scope is the cloud business data foundation, not sync versioning infrastructure
- Phase G DOES include `deleted_at` in cloud table schemas as schema foundation (Phase H uses it for tombstone sync)
- Phase G does NOT include `server_version` or local schema changes (those belong to Phase H)
- Phase G does NOT modify the local SQLite schema

---

## 7. Phase G Scope

### 7.1 Objectives

| # | Objective | Measurable Outcome |
|---|-----------|-------------------|
| O1 | Cloud business tables | 9 new tables with correct types, constraints, indexes |
| O2 | Shop isolation | Every table has shop_id FK, RLS enforced |
| O3 | Permission enforcement | Every mutation goes through require_shop_permission |
| O4 | Licensing enforcement | Write operations require active entitlement |
| O5 | Atomic compound operations | Sales+stock, returns+stock, invoices+items are single server transactions |
| O6 | CRUD foundation | Client can create/read/update/delete cloud business data |
| O7 | Financial precision | PostgreSQL NUMERIC for all money columns |
| O8 | Validation authority | Server-side validation for all input |
| O9 | Soft-delete schema | deleted_at columns for future tombstone sync |
| O10 | Dart cloud models | Typed DTOs with serialization |
| O11 | Dart cloud repositories | Clean data access layer |
| O12 | Error contract | Consistent error taxonomy |
| O13 | Test coverage | Schema, isolation, permission, atomicity, financial tests |

### 7.2 Explicit Non-Goals

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | Sync queue / sync engine | Phase H | Phase G creates schema; Phase H adds sync behavior |
| 2 | server_version column | Phase H | Conflict detection belongs to sync engine |
| 3 | Local schema v12 changes | Phase H | Local schema sync columns are Phase H territory |
| 4 | Legacy data upload | Phase I | Phase G creates target tables; Phase I populates them |
| 5 | Data migration workflows | Phase I | Phase I owns migration execution |
| 6 | Reconciliation | Phase I | Phase I validates data integrity |
| 7 | Windows cloud transition | Phase J | Phase G creates infrastructure; Phase J redirects UI |
| 8 | Android implementation | Phase K/L | Phase G provides shared cloud foundation |
| 9 | Cross-platform Excel import | Phase N | Import batch cloud persistence deferred |
| 10 | Invoice branding/redesign | Phase O | Phase G preserves current invoice data semantics |
| 11 | Inventory conflict hardening | Phase M | Phase G establishes schema; Phase M adds conflict policy |
| 12 | Subscription billing | Owner Decision OD2 | Pricing model unresolved |
| 13 | Offline grace duration | Phase H | Owner Decision OD4 |
| 14 | Negative stock offline policy | Phase M | Owner Decision OD6 |
| 15 | Offline sale allowance | Phase H | Owner Decision OD7 |
| 16 | UI/UX redesign | Not in G | Phase G is infrastructure only |
| 17 | Edge Functions for CRUD | Not in G | Phase G uses SECURITY DEFINER DB functions |
| 18 | Real-time subscriptions | Phase H | Requires realtime infra |

---

## 8. Entity Catalog

### 8.1 Phase G Cloud Entities

| # | Entity | Cloud Table | Local Equivalent | Priority |
|---|--------|------------|-----------------|----------|
| E1 | Product | cloud_products | products | P0 |
| E2 | Customer | cloud_customers | customers | P0 |
| E3 | Sale | cloud_sales | sales | P0 |
| E4 | Return | cloud_returns | returns | P0 |
| E5 | Expense | cloud_expenses | expenses | P0 |
| E6 | Expense Category | cloud_expense_categories | expense_categories | P0 |
| E7 | Invoice | cloud_invoices | invoices | P0 |
| E8 | Inventory Count | cloud_inventory_count | inventory_count | P0 |
| E9 | Shop Settings | cloud_shop_settings | app_settings (subset) | P1 |

### 8.2 Entities NOT in Phase G

| Entity | Reason | Phase |
|--------|--------|-------|
| Import Batches | Cross-platform import is Phase N | N |
| Users | Cloud uses auth.users + shop_members | I (mapping) |
| Role Permissions | Already exists as role_permissions_cloud | C (done) |
| Shops | Already exists | C (done) |
| Shop Members | Already exists | C (done) |
| Devices | Already exists | C/E (done) |
| Licenses | Already exists | E (done) |
| Activations | Already exists | E (done) |
| Invitations | Already exists | D (done) |

---

## 9. Data Ownership Model

### 9.1 Multi-Tenant Principle

ALL business data belongs to exactly one shop.
Every cloud business row MUST have `shop_id UUID NOT NULL`.
`shop_id` references `shops(id)`.

### 9.2 Ownership Matrix

| Entity | Owner (Row) | Read | Create | Update | Delete/Void | Required Permission |
|--------|------------|------|--------|--------|-------------|-------------------|
| cloud_products | shop_id | Active shop member | inventory.edit | inventory.edit | inventory.delete | inventory.view/edit/delete |
| cloud_customers | shop_id | Active shop member | inventory.edit | inventory.edit | inventory.edit | inventory.view/edit |
| cloud_sales | shop_id | sales.view or sales.history.view | sales.create | N/A (append-only) | sales.delete | sales.view/create/delete |
| cloud_returns | shop_id | returns.view | returns.create | N/A (append-only) | returns.delete | returns.view/create/delete |
| cloud_expenses | shop_id | expenses.view | expenses.create | expenses.create | expenses.delete | expenses.view/create/delete |
| cloud_expense_categories | shop_id | Active shop member | expenses.create | expenses.create | expenses.delete (blocked if refs) | expenses.view/create/delete |
| cloud_invoices | shop_id | sales.view or sales.history.view | sales.create | N/A (append-only) | sales.delete | sales.view/create/delete |
| cloud_inventory_count | shop_id | stocktake.view | stocktake.view | stocktake.view | stocktake.view | stocktake.view |
| cloud_shop_settings | shop_id | Active shop member | admin.settings.access | admin.settings.access | N/A (upsert) | admin.settings.access |

### 9.3 Cross-Shop Isolation

- RLS policies enforce: `auth.uid()` is `active_members_of(shop_id)`
- SECURITY DEFINER functions validate: caller's `auth.uid()` is active member of the supplied `shop_id`
- No cross-shop query is possible through PostgREST or RPCs
- Random shop UUID guessing yields zero rows (RLS blocks) or function error

### 9.4 Employee vs. SalesOnly Access

| Entity | Owner | Employee | SalesOnly |
|--------|:-----:|:-------:|:---------:|
| Products (read) | YES | YES | NO |
| Products (write) | YES | YES (edit) | NO |
| Products (delete) | YES | NO (default) | NO |
| Customers (read/write) | YES | YES | NO |
| Sales (read history) | YES | YES | NO |
| Sales (create) | YES | YES | YES |
| Sales (delete) | YES | NO (default) | NO |
| Returns (read) | YES | YES | NO |
| Returns (create) | YES | YES | NO |
| Returns (delete) | YES | NO (default) | NO |
| Expenses (read/write) | YES | YES | NO |
| Expenses (delete) | YES | NO (default) | NO |
| Expense Categories | YES | YES | NO |
| Inventory Count | YES | YES | NO |
| Shop Settings | YES | NO (default) | NO |

---

## 10. Cloud ID Strategy

### 10.1 Primary Key Strategy

| Scope | Type | Generation |
|-------|------|-----------|
| Cloud PK (all Phase G tables) | UUID | `gen_random_uuid()` server-side |
| Local SQLite PK | INTEGER | AUTOINCREMENT (existing, FROZEN) |
| Cloud FK references | UUID | References cloud UUID PKs |

### 10.2 UUID Generation Decision

Server-generated UUIDs via `DEFAULT gen_random_uuid()`.
- Phase G is cloud CRUD foundation. New records get server-generated UUIDs.
- Phase I (legacy migration) will use `gen_random_uuid()` for batch upload.
- Phase H (offline sync) will need client-generated UUIDs. Phase H solves that.
- Phase G does not need to solve the offline UUID problem.

### 10.3 Legacy ID Mapping

- Local integer PKs remain in SQLite (FROZEN)
- `cloud_uuid TEXT` in local tables stores the mapping (populated by Phase I)
- Phase G does NOT create migration_mapping table (Phase I)
- Phase G cloud tables do NOT store local integer PKs (Phase I)

### 10.4 External/Business Identifiers

| Identifier | Type | Scope |
|-----------|------|-------|
| Product barcode | TEXT | Per-shop unique: `UNIQUE(shop_id, barcode)` |
| Invoice number | TEXT | Per-shop unique: `UNIQUE(shop_id, invoice_number)` |
| Expense category name | TEXT | Per-shop unique: `UNIQUE(shop_id, name)` |
| Customer name | TEXT | Per-shop non-unique |

---

## 11. Field Mapping per Entity

### E1: cloud_products

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| name | TEXT | NO | - | name (TEXT) |
| barcode | TEXT | NO | - | barcode (TEXT) |
| opening_quantity | INTEGER | NO | 0 | openingQuantity |
| sold_quantity | INTEGER | NO | 0 | soldQuantity |
| returned_quantity | INTEGER | NO | 0 | returnedQuantity |
| current_quantity | INTEGER | NO | 0 | currentQuantity |
| cost_price | NUMERIC(12,2) | NO | 0 | costPrice (REAL) |
| total_inventory_cost | NUMERIC(14,2) | NO | 0 | totalInventoryCost (REAL) |
| inventory_adjustment | INTEGER | NO | 0 | inventoryAdjustment |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| updated_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `UNIQUE(shop_id, barcode)`, `CHECK(opening_quantity >= 0)`, `CHECK(sold_quantity >= 0)`, `CHECK(returned_quantity >= 0)`, `CHECK(cost_price >= 0)`

Computed invariant: `current_quantity = opening_quantity - sold_quantity + returned_quantity + inventory_adjustment`, `total_inventory_cost = current_quantity * cost_price`

### E2: cloud_customers

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| name | TEXT | NO | - | name (TEXT) |
| phone | TEXT | YES | NULL | phone |
| address | TEXT | YES | NULL | address |
| notes | TEXT | YES | NULL | notes |
| is_active | BOOLEAN | NO | true | isActive (INTEGER 0/1) |
| is_system | BOOLEAN | NO | false | isSystem (INTEGER 0/1) |
| created_at | TIMESTAMPTZ | NO | now() | createdAt (TEXT) |
| updated_at | TIMESTAMPTZ | NO | now() | updatedAt (TEXT) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

### E3: cloud_sales

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| invoice_id | UUID | YES | NULL | invoiceId (INTEGER) |
| date | TIMESTAMPTZ | NO | - | date (TEXT ISO8601) |
| product_name | TEXT | NO | - | productName |
| barcode | TEXT | NO | - | barcode |
| quantity | INTEGER | NO | - | quantity |
| sale_price | NUMERIC(12,2) | NO | - | salePrice (REAL) |
| total_sale_value | NUMERIC(14,2) | NO | - | totalSaleValue (REAL) |
| cost_price | NUMERIC(12,2) | NO | - | costPrice (REAL) |
| cogs | NUMERIC(14,2) | NO | - | cogs (REAL) |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `CHECK(quantity > 0)`, `CHECK(sale_price >= 0)`

### E4: cloud_returns

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| date | TIMESTAMPTZ | NO | - | date (TEXT ISO8601) |
| product_name | TEXT | NO | - | productName |
| barcode | TEXT | NO | - | barcode |
| quantity | INTEGER | NO | - | quantity |
| sale_price | NUMERIC(12,2) | NO | - | salePrice (REAL) |
| total_return_value | NUMERIC(14,2) | NO | - | totalReturnValue (REAL) |
| cost_price | NUMERIC(12,2) | NO | - | costPrice (REAL) |
| returned_cogs | NUMERIC(14,2) | NO | - | returnedCogs (REAL) |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `CHECK(quantity > 0)`, `CHECK(sale_price >= 0)`

### E5: cloud_expenses

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| date | TIMESTAMPTZ | NO | - | date (TEXT ISO8601) |
| description | TEXT | NO | - | description |
| amount | NUMERIC(12,2) | NO | 0 | amount (REAL) |
| category_name | TEXT | YES | NULL | category (TEXT) |
| category_id | UUID | YES | NULL | - (FK to cloud_expense_categories) |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `CHECK(amount >= 0)`

Design: Expenses reference category by BOTH `category_name` (text, for backward compatibility) AND `category_id` (UUID FK, for referential integrity). `category_id` is authoritative; `category_name` is denormalized.

### E6: cloud_expense_categories

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| name | TEXT | NO | - | name (TEXT) |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `UNIQUE(shop_id, name)`

### E7: cloud_invoices

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| invoice_number | TEXT | NO | - | invoiceNumber |
| date | TIMESTAMPTZ | NO | - | date (TEXT ISO8601) |
| customer_name | TEXT | NO | - | customerName |
| customer_id | UUID | YES | NULL | customerId (INTEGER) |
| payment_method | TEXT | NO | - | paymentMethod |
| total_amount | NUMERIC(14,2) | NO | 0 | totalAmount (REAL) |
| total_items | INTEGER | NO | 0 | totalItems |
| created_at | TIMESTAMPTZ | NO | now() | createdAt (TEXT) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `UNIQUE(shop_id, invoice_number)`, `CHECK(total_amount >= 0)`, `CHECK(total_items >= 0)`

### E8: cloud_inventory_count

| Cloud Column | Type | Nullable | Default | Local Equivalent |
|-------------|------|:--------:|---------|-----------------|
| id | UUID | NO | gen_random_uuid() | id (INTEGER) |
| shop_id | UUID | NO | - | shop_id (TEXT) |
| product_id | UUID | NO | - | productId (INTEGER) |
| actual_quantity | INTEGER | NO | 0 | actualQuantity |
| notes | TEXT | NO | '' | notes |
| count_date | TIMESTAMPTZ | NO | - | countDate (TEXT ISO8601) |
| created_at | TIMESTAMPTZ | NO | now() | - (new in cloud) |
| deleted_at | TIMESTAMPTZ | YES | NULL | - (soft delete) |

Constraints: `CHECK(actual_quantity >= 0)`

### E9: cloud_shop_settings

| Cloud Column | Type | Nullable | Default | Notes |
|-------------|------|:--------:|---------|-------|
| shop_id | UUID | NO | - | FK to shops(id), part of composite PK |
| setting_key | TEXT | NO | - | Setting identifier |
| setting_value | TEXT | NO | - | String value |
| updated_at | TIMESTAMPTZ | NO | now() | |
| updated_by | UUID | YES | NULL | FK to auth.users(id) |

Constraints: `PRIMARY KEY (shop_id, setting_key)`

**Settings included:** shopProfile.shopName, shopProfile.ownerOrManagerName, shopProfile.phone, shopProfile.address, supportPhone, brandColor, invoiceTitle, invoiceFooterText, buttonStyle

**Settings excluded:** workbookPath, backupDirectory, thermalPrinterName, thermalPaperWidth, thermalPrintCopies, device.installationId, licenseStatus, cloud.license.*, cloud.permissions.*, cloud.auth.email, cloud.lastShopId, shopProfile.cloudUuid, defaultCustomerName

---

## 12. Relationship Model

### 12.1 Foreign Key Definitions

| Parent Table | Child Table | FK Column | On Delete |
|-------------|------------|-----------|-----------|
| shops | cloud_products | shop_id | CASCADE |
| shops | cloud_customers | shop_id | CASCADE |
| shops | cloud_sales | shop_id | CASCADE |
| shops | cloud_returns | shop_id | CASCADE |
| shops | cloud_expenses | shop_id | CASCADE |
| shops | cloud_expense_categories | shop_id | CASCADE |
| shops | cloud_invoices | shop_id | CASCADE |
| shops | cloud_inventory_count | shop_id | CASCADE |
| shops | cloud_shop_settings | shop_id | CASCADE |
| cloud_invoices | cloud_sales | invoice_id | SET NULL |
| cloud_expense_categories | cloud_expenses | category_id | SET NULL |
| cloud_products | cloud_inventory_count | product_id | RESTRICT |

### 12.2 Delete Rules Rationale

| Relationship | Rule | Rationale |
|-------------|------|-----------|
| shop -> all business data | CASCADE | Tenant deletion removes all tenant data |
| invoice -> sales | SET NULL | Voiding invoice preserves sale records for audit |
| category -> expenses | SET NULL | Deleting category preserves expense history |
| product -> inventory_count | RESTRICT | Cannot delete product with stocktake records |

Additional rules enforced in SECURITY DEFINER functions:
- product (barcode) -> sales: RESTRICT (cannot delete product with sales history)
- product (barcode) -> returns: RESTRICT (cannot delete product with return history)
- expense_category -> expenses: RESTRICT (cannot delete category with expenses, text match)

### 12.3 Barcode as Logical FK

`cloud_sales.barcode` and `cloud_returns.barcode` reference `cloud_products.barcode`. NOT an enforced PostgreSQL FK (barcode is a business identifier, not a primary key). Referential integrity maintained in SECURITY DEFINER functions.

---

## 13. Financial Type Strategy

| Financial Concept | SQLite Type | Cloud Type | Precision |
|-------------------|-------------|-----------|-----------|
| Cost price | REAL | NUMERIC(12,2) | 2 decimal places, up to 999,999,999.99 |
| Sale price | REAL | NUMERIC(12,2) | 2 decimal places |
| Total sale value | REAL | NUMERIC(14,2) | 2 decimal places, up to 99,999,999,999.99 |
| COGS | REAL | NUMERIC(14,2) | 2 decimal places |
| Total return value | REAL | NUMERIC(14,2) | 2 decimal places |
| Returned COGS | REAL | NUMERIC(14,2) | 2 decimal places |
| Total inventory cost | REAL | NUMERIC(14,2) | 2 decimal places |
| Expense amount | REAL | NUMERIC(12,2) | 2 decimal places |
| Invoice total | REAL | NUMERIC(14,2) | 2 decimal places |
| Quantities | INTEGER | INTEGER | Whole numbers |

Precision preservation: SQLite REAL is IEEE 754 double (15-17 significant digits). PostgreSQL NUMERIC is exact decimal. Migration from REAL to NUMERIC is safe. Egyptian Pound uses 2 decimal places (piasters).

---

## 14. Inventory Invariants

### 14.1 Canonical Formula

```
current_quantity = opening_quantity - sold_quantity + returned_quantity + inventory_adjustment
total_inventory_cost = current_quantity * cost_price
```

### 14.2 Stock Mutation Operations

| Operation | Cloud Function | Effect on Product |
|-----------|---------------|-------------------|
| Create sale | create_cloud_sale_with_stock(...) | sold_quantity += qty, recompute current_quantity |
| Delete sale | delete_cloud_sale_with_revert(...) | sold_quantity -= qty, recompute |
| Create return | create_cloud_return_with_stock(...) | returned_quantity += qty, recompute |
| Delete return | delete_cloud_return_with_revert(...) | returned_quantity -= qty, recompute |
| Save inventory count | save_cloud_inventory_count(...) | inventory_adjustment += (actual - current), recompute |
| Update product | update_cloud_product(...) | Recompute from provided quantities |

### 14.3 Optimistic Locking (Cloud)

```sql
UPDATE cloud_products
SET sold_quantity = sold_quantity + p_quantity,
    current_quantity = opening_quantity - (sold_quantity + p_quantity) + returned_quantity + inventory_adjustment,
    total_inventory_cost = (...) * cost_price,
    updated_at = now()
WHERE id = p_product_id AND current_quantity >= p_quantity AND deleted_at IS NULL
```

If `ROW_COUNT() = 0`, function raises exception (insufficient stock or concurrent modification).

---

## 15. CRUD Contract Matrix

### 15.1 Simple Entity CRUD

| Entity | Read | Create | Update | Delete | Permission | Atomic? |
|--------|------|--------|--------|--------|-----------|---------|
| cloud_products | PostgREST + RLS | create_cloud_product(shop_id, ...) | update_cloud_product(shop_id, ...) | delete_cloud_product(shop_id, ...) | inventory.view/edit/delete | No |
| cloud_customers | PostgREST + RLS | create_cloud_customer(shop_id, ...) | update_cloud_customer(shop_id, ...) | delete_cloud_customer(shop_id, ...) | inventory.view/edit | No |
| cloud_expense_categories | PostgREST + RLS | create_cloud_expense_category(shop_id, ...) | update_cloud_expense_category(shop_id, ...) | delete_cloud_expense_category(shop_id, ...) | expenses.view/create/delete | No |
| cloud_expenses | PostgREST + RLS | create_cloud_expense(shop_id, ...) | update_cloud_expense(shop_id, ...) | delete_cloud_expense(shop_id, ...) | expenses.view/create/delete | No |
| cloud_shop_settings | get_cloud_shop_settings(shop_id) | (via update) | update_cloud_shop_setting(shop_id, key, value) | N/A (upsert) | admin.settings.access | No |

### 15.2 Compound Atomic Operations

| Operation | Function | Permission | What It Does Atomically |
|-----------|----------|-----------|------------------------|
| Create sale with stock | create_cloud_sale_with_stock(shop_id, ...) | sales.create | 1. Verify product + stock 2. Insert sale 3. Update product 4. Return sale UUID |
| Create invoice with items | create_cloud_invoice_with_items(shop_id, ...) | sales.create | 1. Validate 2. Insert invoice 3. Loop: insert sale + update product 4. Return invoice UUID |
| Delete sale + revert stock | delete_cloud_sale_with_revert(shop_id, ...) | sales.delete | 1. Find sale 2. Revert product 3. Soft-delete sale 4. Optionally delete orphaned invoice |
| Create return with stock | create_cloud_return_with_stock(shop_id, ...) | returns.create | 1. Verify product 2. Insert return 3. Update product 4. Return return UUID |
| Delete return + revert stock | delete_cloud_return_with_revert(shop_id, ...) | returns.delete | 1. Find return 2. Revert product 3. Soft-delete return |
| Save inventory count | save_cloud_inventory_count(shop_id, ...) | stocktake.view | 1. Verify product 2. Insert count 3. Update product inventory_adjustment |

---

## 16. Permission Matrix

### 16.1 Permission -> Operation Mapping

| Permission ID | Cloud Operations |
|--------------|-----------------|
| dashboard.view | Read-only dashboard queries (aggregates) |
| inventory.view | Read cloud_products, cloud_inventory_count |
| inventory.edit | Create/update cloud_products, cloud_customers |
| inventory.delete | Delete cloud_products (with reference check) |
| sales.view | Read cloud_sales, cloud_invoices |
| sales.create | Create cloud_sales, cloud_invoices (with stock atomicity) |
| sales.history.view | Read cloud_sales, cloud_invoices (historical reports) |
| sales.delete | Delete cloud_sales (with stock revert) |
| returns.view | Read cloud_returns |
| returns.create | Create cloud_returns (with stock atomicity) |
| returns.delete | Delete cloud_returns (with stock revert) |
| expenses.view | Read cloud_expenses, cloud_expense_categories |
| expenses.create | Create/update cloud_expenses, cloud_expense_categories |
| expenses.delete | Delete cloud_expenses, cloud_expense_categories (with ref check) |
| stocktake.view | Read/write cloud_inventory_count |
| admin.users.manage | User management (Phase D/F) |
| admin.permissions.manage | Permission management (Phase F) |
| admin.settings.access | Read/write cloud_shop_settings |

### 16.2 Permission Enforcement Architecture

Every Phase G SECURITY DEFINER function calls `require_shop_permission(shop_id, permission_id)` internally. This function (Phase F) verifies:
1. `auth.uid()` is authenticated
2. `auth.uid()` is active member of `shop_id`
3. Active license/trial entitlement exists
4. The effective permission is granted for the caller's role

No additional permission check needed in Phase G functions.

---

## 17. Licensing Enforcement

### 17.1 Trust Chain

```
authenticated user (auth.uid())
  -> active shop membership (shop_members: status='ACTIVE')
    -> active license/trial entitlement (verify_license_entitlement)
      -> required permission (require_shop_permission)
        -> validated input
          -> atomic mutation
```

### 17.2 Implementation

Every Phase G mutation function calls `require_shop_permission(p_shop_id, p_permission_id)`. This function (Phase F) already enforces:
1. Authentication: `auth.uid() IS NOT NULL`
2. Membership: Active member of shop
3. Licensing: Active entitlement (TRIAL/ACTIVE/PERPETUAL) for write permissions
4. Permission: Effective permission granted for caller's role

Phase G does NOT need to add separate licensing checks.

---

## 18. RLS Model

### 18.1 Policy Pattern

Every Phase G business table uses the same RLS pattern:

```sql
ALTER TABLE cloud_<entity> ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shop_isolation_<entity>" ON cloud_<entity>
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_<entity>.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );
```

### 18.2 RLS Summary

| Table | RLS Enabled | SELECT Policy | INSERT | UPDATE | DELETE |
|-------|:-----------:|:-------------:|:------:|:------:|:------:|
| cloud_products | YES | shop_isolation | NONE | NONE | NONE |
| cloud_customers | YES | shop_isolation | NONE | NONE | NONE |
| cloud_sales | YES | shop_isolation | NONE | NONE | NONE |
| cloud_returns | YES | shop_isolation | NONE | NONE | NONE |
| cloud_expenses | YES | shop_isolation | NONE | NONE | NONE |
| cloud_expense_categories | YES | shop_isolation | NONE | NONE | NONE |
| cloud_invoices | YES | shop_isolation | NONE | NONE | NONE |
| cloud_inventory_count | YES | shop_isolation | NONE | NONE | NONE |
| cloud_shop_settings | YES | shop_isolation | NONE | NONE | NONE |

### 18.3 Direct Table Write Policy

HARD RULE: No client-side INSERT/UPDATE/DELETE on any cloud business table.
All mutations MUST go through SECURITY DEFINER functions. Enforced by:
1. RLS blocks direct mutations (no INSERT/UPDATE/DELETE policies)
2. `authenticated` PostgreSQL role has no direct write grants
3. Only `supabase_admin` (SECURITY DEFINER function owner) can write

---

## 19. SECURITY DEFINER Strategy

### 19.1 Function Standards

Every function MUST follow:
- `SECURITY DEFINER`
- `SET search_path = public`
- `auth.uid()` for caller identity
- `require_shop_permission()` for authorization
- Input validation before mutation
- Structured error messages via `RAISE EXCEPTION`

### 19.2 Function Catalog (Phase G)

| # | Function | Returns | Permission | Atomic? |
|---|----------|---------|-----------|---------|
| 1 | create_cloud_product(shop_id, name, barcode, ...) | UUID | inventory.edit | No |
| 2 | update_cloud_product(shop_id, product_id, ...) | BOOLEAN | inventory.edit | No |
| 3 | delete_cloud_product(shop_id, product_id) | BOOLEAN | inventory.delete | Yes (reference check) |
| 4 | create_cloud_customer(shop_id, name, ...) | UUID | inventory.edit | No |
| 5 | update_cloud_customer(shop_id, customer_id, ...) | BOOLEAN | inventory.edit | No |
| 6 | delete_cloud_customer(shop_id, customer_id) | BOOLEAN | inventory.edit | No |
| 7 | create_cloud_expense_category(shop_id, name) | UUID | expenses.create | No |
| 8 | delete_cloud_expense_category(shop_id, category_id) | BOOLEAN | expenses.delete | Yes (reference check) |
| 9 | create_cloud_expense(shop_id, date, desc, amount, cat_id) | UUID | expenses.create | No |
| 10 | update_cloud_expense(shop_id, expense_id, ...) | BOOLEAN | expenses.create | No |
| 11 | delete_cloud_expense(shop_id, expense_id) | BOOLEAN | expenses.delete | No |
| 12 | create_cloud_sale_with_stock(shop_id, barcode, qty, price, ...) | UUID | sales.create | YES |
| 13 | delete_cloud_sale_with_revert(shop_id, sale_id) | BOOLEAN | sales.delete | YES |
| 14 | create_cloud_return_with_stock(shop_id, barcode, qty, price, ...) | UUID | returns.create | YES |
| 15 | delete_cloud_return_with_revert(shop_id, return_id) | BOOLEAN | returns.delete | YES |
| 16 | create_cloud_invoice_with_items(shop_id, invoice_data, sale_items) | UUID | sales.create | YES |
| 17 | save_cloud_inventory_count(shop_id, product_id, actual_qty, notes) | UUID | stocktake.view | YES |
| 18 | get_cloud_shop_settings(shop_id) | TABLE | admin.settings.access | No |
| 19 | update_cloud_shop_setting(shop_id, key, value) | BOOLEAN | admin.settings.access | No |

---

## 20. Atomic Sales Strategy

### 20.1 create_cloud_sale_with_stock

PL/pgSQL function that:
1. Authenticates via `auth.uid()`
2. Authorizes via `require_shop_permission(p_shop_id, 'sales.create')`
3. Validates input (quantity > 0, sale_price > 0)
4. Finds product by barcode within shop (not deleted)
5. Checks `current_quantity >= sale quantity`
6. Inserts sale row with computed `total_sale_value` and `cogs`
7. Updates product `sold_quantity` + `current_quantity` with optimistic lock
8. Returns sale UUID

### 20.2 delete_cloud_sale_with_revert

PL/pgSQL function that:
1. Authenticates + authorizes (sales.delete)
2. Finds sale by ID within shop
3. Reverts product `sold_quantity` and recomputes `current_quantity`
4. Soft-deletes the sale (`deleted_at = now()`)
5. If invoice has no more active sales, soft-deletes the invoice too

### 20.3 create_cloud_invoice_with_items

PL/pgSQL function that:
1. Authenticates + authorizes (sales.create)
2. Validates inputs
3. Generates per-shop sequential invoice number (INV-00000001, etc.)
4. Creates invoice header row
5. Loops through sale items JSONB, calling `create_cloud_sale_with_stock` for each
6. Updates invoice `total_amount` and `total_items`
7. If any item fails, entire function rolls back (implicit PL/pgSQL transaction)

### 20.4 Invoice Number Generation

Server-generated per-shop sequential: `INV-00000001`, `INV-00000002`, etc.
- Unique per shop (UNIQUE constraint as safety net)
- Sequential (derived from max existing number)
- Server-generated (no client collision risk)

---

## 21. Atomic Returns Strategy

### 21.1 create_cloud_return_with_stock

Mirrors sale pattern: validates product, inserts return with computed `total_return_value` and `returned_cogs`, updates product `returned_quantity` + `current_quantity`.

### 21.2 delete_cloud_return_with_revert

Mirrors sale delete: finds return, reverts product `returned_quantity`, soft-deletes return.

---

## 22. Delete/Void/Tombstone Strategy

### 22.1 Decision: Soft Delete Schema in Phase G

Phase G creates `deleted_at` columns on all business tables. Actual tombstone sync behavior is Phase H.

Rationale: `deleted_at` is a schema-level concern. Tombstone synchronization (reading `deleted_at` to propagate deletes across devices) is a sync-engine concern (Phase H).

### 22.2 Financial Record Deletion

- Physical DELETE is forbidden for audit trail integrity
- Soft DELETE (`deleted_at = now()`) is the standard pattern
- Delete functions for sales/returns also revert inventory quantities

### 22.3 Product Deletion

Products with sales, returns, or inventory_count references CANNOT be deleted (RESTRICT). Products without references can be soft-deleted.

### 22.4 Customer Deletion

Customers are soft-deleted. Invoices reference customers by UUID FK; deleting a customer does NOT delete invoices.

---

## 23. Index/Constraint Strategy

### 23.1 Indexes per Table

| Table | Index | Columns | Type |
|-------|-------|---------|------|
| cloud_products | idx_cloud_products_shop_id | shop_id | BTREE |
| cloud_products | idx_cloud_products_barcode | (shop_id, barcode) | BTREE UNIQUE |
| cloud_products | idx_cloud_products_updated_at | (shop_id, updated_at) | BTREE |
| cloud_customers | idx_cloud_customers_shop_id | shop_id | BTREE |
| cloud_customers | idx_cloud_customers_name | (shop_id, name) | BTREE |
| cloud_sales | idx_cloud_sales_shop_id | shop_id | BTREE |
| cloud_sales | idx_cloud_sales_invoice_id | invoice_id | BTREE |
| cloud_sales | idx_cloud_sales_barcode | (shop_id, barcode) | BTREE |
| cloud_sales | idx_cloud_sales_date | (shop_id, date) | BTREE |
| cloud_sales | idx_cloud_sales_updated_at | (shop_id, updated_at) | BTREE |
| cloud_returns | idx_cloud_returns_shop_id | shop_id | BTREE |
| cloud_returns | idx_cloud_returns_barcode | (shop_id, barcode) | BTREE |
| cloud_returns | idx_cloud_returns_date | (shop_id, date) | BTREE |
| cloud_returns | idx_cloud_returns_updated_at | (shop_id, updated_at) | BTREE |
| cloud_expenses | idx_cloud_expenses_shop_id | shop_id | BTREE |
| cloud_expenses | idx_cloud_expenses_date | (shop_id, date) | BTREE |
| cloud_expenses | idx_cloud_expenses_category_id | category_id | BTREE |
| cloud_expense_categories | idx_cloud_exp_categories_shop_id | shop_id | BTREE |
| cloud_invoices | idx_cloud_invoices_shop_id | shop_id | BTREE |
| cloud_invoices | idx_cloud_invoices_number | (shop_id, invoice_number) | BTREE UNIQUE |
| cloud_invoices | idx_cloud_invoices_customer_id | customer_id | BTREE |
| cloud_invoices | idx_cloud_invoices_date | (shop_id, date) | BTREE |
| cloud_inventory_count | idx_cloud_inv_count_shop_id | shop_id | BTREE |
| cloud_inventory_count | idx_cloud_inv_count_product_id | product_id | BTREE |

### 23.2 Unique Constraints

| Table | Constraint | Columns |
|-------|-----------|---------|
| cloud_products | uniq_cloud_products_shop_barcode | (shop_id, barcode) |
| cloud_expense_categories | uniq_cloud_exp_cat_shop_name | (shop_id, name) |
| cloud_invoices | uniq_cloud_invoices_shop_number | (shop_id, invoice_number) |
| cloud_shop_settings | PRIMARY KEY | (shop_id, setting_key) |

### 23.3 Updated-At Index Rationale

The `idx_*_updated_at` indexes on products, sales, and returns serve Phase H sync engine: "all records updated since timestamp X" queries. Created now because they are additive schema.

---

## 24. App Settings Classification

See Section 4.8 for complete classification. Summary:

| Category | Keys | Cloud Sync? |
|----------|------|:-----------:|
| Shop Business Profile | shopName, ownerOrManagerName, phone, address | YES |
| Invoice/Branding | supportPhone, brandColor, invoiceTitle, invoiceFooterText | YES |
| UI Preference | buttonStyle | YES |
| Device Hardware | thermalPrinterName, thermalPaperWidth, thermalPrintCopies | NO |
| Device Identity | installationId | NO |
| Filesystem | workbookPath, backupDirectory | NO |
| License Cache | licenseStatus, cloud.license.* | NO (managed by EntitlementCache) |
| Permission Cache | cloud.permissions.* | NO (managed by PermissionCache) |
| Auth Metadata | cloud.auth.email, cloud.lastShopId | NO |
| Identity Link | shopProfile.cloudUuid | NO |
| Legacy | licenseKey (disabled), defaultCustomerName (removed) | NO |

---

## 25. Dart Model Strategy

### 25.1 Cloud DTOs

Phase G introduces cloud-specific DTOs. NOT modifications to existing local models.

| DTO | File | Purpose |
|-----|------|---------|
| CloudProduct | app/lib/models/cloud/cloud_product.dart | Cloud product serialization |
| CloudCustomer | app/lib/models/cloud/cloud_customer.dart | Cloud customer serialization |
| CloudSale | app/lib/models/cloud/cloud_sale.dart | Cloud sale serialization |
| CloudReturn | app/lib/models/cloud/cloud_return.dart | Cloud return serialization |
| CloudExpense | app/lib/models/cloud/cloud_expense.dart | Cloud expense serialization |
| CloudExpenseCategory | app/lib/models/cloud/cloud_expense_category.dart | Cloud category serialization |
| CloudInvoice | app/lib/models/cloud/cloud_invoice.dart | Cloud invoice serialization |
| CloudInventoryCount | app/lib/models/cloud/cloud_inventory_count.dart | Cloud inventory count serialization |
| CloudShopSetting | app/lib/models/cloud/cloud_shop_setting.dart | Cloud setting serialization |

### 25.2 DTO Design Principles

- 1:1 mapping to cloud table columns
- `fromJson(Map<String, dynamic>)` for Supabase response parsing
- `toJson()` for RPC parameter passing
- UUID fields as String (Dart has no native UUID type)
- DateTime for TIMESTAMPTZ fields
- double for NUMERIC fields (Dart JSON deserializes numbers as double)
- null for nullable columns
- No business logic in DTOs
- No database interaction in DTOs

### 25.3 Relationship to Existing Local Models

- Product, Sale, ReturnItem, etc. (existing local models) remain UNCHANGED
- Cloud DTOs are separate classes in a `cloud/` subdirectory
- No shared base class (different concerns)
- Conversion functions (local <-> cloud DTO) belong to Phase I, not Phase G

---

## 26. Repository/Service Strategy

### 26.1 Cloud Repositories

| Repository | File | Responsibility |
|-----------|------|---------------|
| CloudProductRepository | app/lib/repositories/cloud/cloud_product_repository.dart | Supabase calls for product CRUD |
| CloudCustomerRepository | app/lib/repositories/cloud/cloud_customer_repository.dart | Supabase calls for customer CRUD |
| CloudSalesRepository | app/lib/repositories/cloud/cloud_sales_repository.dart | Supabase calls for sale/return/invoice operations |
| CloudExpenseRepository | app/lib/repositories/cloud/cloud_expense_repository.dart | Supabase calls for expense/category CRUD |
| CloudInventoryRepository | app/lib/repositories/cloud/cloud_inventory_repository.dart | Supabase calls for inventory count operations |
| CloudSettingsRepository | app/lib/repositories/cloud/cloud_settings_repository.dart | Supabase calls for shop settings |

### 26.2 Repository Responsibilities

- Call Supabase client methods (`supabase.from('table').select()`, `supabase.rpc('function_name', params: {...})`)
- Convert Supabase JSON responses to typed DTOs
- Normalize errors to consistent `CloudDataException` types
- NO UI concerns (no BuildContext, no navigation)
- NO business logic (permission checks are in server functions)
- NO local database interaction

### 26.3 Service Layer

| Service | File | Responsibility |
|---------|------|---------------|
| CloudProductService | app/lib/services/cloud/cloud_product_service.dart | Domain operations for products |
| CloudSalesService | app/lib/services/cloud/cloud_sales_service.dart | Domain operations for sales/returns/invoices |
| CloudExpenseService | app/lib/services/cloud/cloud_expense_service.dart | Domain operations for expenses |
| CloudSettingsService | app/lib/services/cloud/cloud_settings_service.dart | Domain operations for shop settings |

Services sit between repositories and UI. No modification to existing local data layer.

---

## 27. Error Contract

### 27.1 Error Taxonomy

| Error Code | HTTP | Server Message Pattern | Client Handling |
|-----------|------|----------------------|-----------------|
| unauthenticated | 401 | Authentication required | Redirect to login |
| not_member | 403 | Not a member of this shop | Show access error |
| membership_inactive | 403 | Membership is not active | Show suspended message |
| license_required | 403 | Active license required | Prompt license activation |
| license_expired | 403 | License has expired | Prompt renewal |
| permission_denied | 403 | Permission denied: {permission} | Hide/disable UI element |
| invalid_input | 400 | Specific validation message | Show inline error |
| not_found | 404 | Resource not found | Show not-found message |
| conflict | 409 | Resource already exists | Show duplicate error |
| constraint_violation | 409 | Specific constraint message | Show error |
| insufficient_stock | 409 | Insufficient stock: available X, requested Y | Show stock error |
| network_error | 503 | Connection timeout/failure | Retry / offline mode |
| server_error | 500 | Internal server error | Show generic error |

### 27.2 Implementation

- Server functions raise `RAISE EXCEPTION` with structured messages
- Supabase client receives `PostgrestException`
- Cloud repositories map `PostgrestException` to `CloudDataException`
- UI catches `CloudDataException` and displays appropriate message

---

## 28. Security Threat Model

| # | Threat | Risk | Mitigation |
|---|--------|------|-----------|
| T1 | Cross-tenant row access | HIGH | RLS policies + membership verification in every function |
| T2 | Direct PostgREST mutation bypass | HIGH | No INSERT/UPDATE/DELETE RLS policies; REVOKE on authenticated |
| T3 | Forged shop_id in function call | HIGH | require_shop_permission verifies caller membership |
| T4 | Forged user ID (auth bypass) | CRITICAL | auth.uid() is JWT-verified; functions use auth.uid() directly |
| T5 | Permission bypass | HIGH | require_shop_permission checks effective permission including overrides |
| T6 | License bypass | MEDIUM | Write permissions gated by require_shop_permission (includes license check) |
| T7 | SQL function search-path attack | MEDIUM | All functions use SET search_path = public |
| T8 | Overly broad grants | MEDIUM | REVOKE direct table access; GRANT only on specific functions |
| T9 | Mass assignment | LOW | Functions accept explicit parameters, not JSON blobs |
| T10 | FK relationship poisoning | MEDIUM | Functions validate FK targets exist within same shop |
| T11 | Financial precision loss | LOW | NUMERIC for all money; no floating-point in PostgreSQL |
| T12 | Historical-record destruction | MEDIUM | Soft delete preserves audit trail |
| T13 | Duplicate transaction submission | MEDIUM | Phase H adds idempotency keys |
| T14 | Unauthorized settings mutation | MEDIUM | admin.settings.access permission required |
| T15 | Leakage of secrets into Flutter | CRITICAL | No service_role key in client; Supabase anon key only |
| T16 | Weak RLS on new tables | HIGH | All new tables get shop_isolation SELECT policy |
| T17 | Concurrent stock modification | MEDIUM | Optimistic locking with user-visible error |
| T18 | Invoice number collision | LOW | Server-generated sequential; UNIQUE constraint safety net |

### Trust Boundary Summary

```
FLUTTER CLIENT (UNTRUSTED):
  Can: Read cloud data via PostgREST (RLS-filtered)
  Can: Call SECURITY DEFINER functions via supabase.rpc()
  Cannot: Directly INSERT/UPDATE/DELETE on any table
  Cannot: Access service_role key
  Cannot: Bypass RLS
  Cannot: Forge auth.uid()

CLOUD (Supabase - TRUSTED):
  PostgreSQL RLS: Shop isolation on all tables
  SECURITY DEFINER functions: auth.uid() verified, membership verified, license verified, permission verified, input validated, atomic transactions
```

---

## 29. Validation Rules

### 29.1 Server-Side Validation (Authoritative)

| Entity | Field | Rule | Error Message |
|--------|-------|------|--------------|
| Product | name | NOT NULL, trimmed, non-empty | Product name is required |
| Product | barcode | NOT NULL, trimmed, non-empty, UNIQUE per shop | Barcode is required / exists |
| Product | cost_price | > 0 | Cost price must be > 0 |
| Product | opening_quantity | >= 0 | Cannot be negative |
| Product | sold_quantity | >= 0 | Cannot be negative |
| Product | returned_quantity | >= 0 | Cannot be negative |
| Customer | name | NOT NULL, trimmed, non-empty | Customer name is required |
| Sale | quantity | > 0 | Must be > 0 |
| Sale | sale_price | > 0 | Must be > 0 |
| Sale | barcode | Product exists in shop | Product not found |
| Sale | quantity | <= current_quantity | Insufficient stock |
| Return | quantity | > 0 | Must be > 0 |
| Return | sale_price | > 0 | Must be > 0 |
| Return | barcode | Product exists in shop | Product not found |
| Expense | description | NOT NULL, trimmed, non-empty | Description is required |
| Expense | amount | >= 0 | Cannot be negative |
| Invoice | customer_name | NOT NULL, trimmed, non-empty | Customer name is required |
| Invoice | sale_items | Array length > 0 | At least one item required |
| Invoice | payment_method | NOT NULL | Payment method is required |
| ExpenseCategory | name | NOT NULL, trimmed, non-empty, UNIQUE per shop | Required / exists |
| InventoryCount | actual_quantity | >= 0 | Cannot be negative |
| InventoryCount | product_id | Product exists in shop | Product not found |

---

## 30. Phase G vs H Boundary

### 30.1 Phase G Creates (Schema Foundation)

- 9 cloud business tables with shop_id, deleted_at, updated_at
- SECURITY DEFINER CRUD functions (19)
- RLS policies for shop isolation
- Indexes including updated_at for sync queries
- Dart cloud DTOs and repositories
- deleted_at columns (Phase H uses for tombstone sync)
- updated_at columns (Phase H uses for changed-since queries)

### 30.2 Phase H Creates (NOT in G)

- sync_queue table
- server_version columns
- Idempotency key infrastructure
- Sync engine (retry, orchestration, conflict detection)
- Tombstone query logic (reads deleted_at)
- Changed-since query logic (reads updated_at)
- Offline pending-write processor
- Real-time subscriptions
- Background sync worker
- Local schema v12 changes (sync columns)
- Conflict resolution UI

---

## 31. Phase G vs I Boundary

### 31.1 Phase G Creates (Target Schema)

- Cloud tables that Phase I will populate
- CRUD functions that Phase I will use for batch upload
- Permission model that Phase I relies on

### 31.2 Phase I Creates (NOT in G)

- Legacy data upload workflows
- migration_mapping table
- Local<->Cloud ID mapping logic
- Reconciliation scripts
- Pre-migration backup flow
- Post-migration verification
- Rollback procedures

### 31.3 Phase G Compatibility Requirements for I

- All columns nullable with defaults where data may not exist yet
- gen_random_uuid() default allows server-generated IDs during upload
- created_at defaults to now() - Phase I can override with original timestamps
- No unique constraints that conflict with partial uploads
- Financial columns use NUMERIC - Phase I converts from SQLite REAL (safe)

---

## 32. Phase G vs J/N/O/M Boundaries

### 32.1 Phase J (Windows Cloud Transition)

Phase G creates cloud infrastructure. Phase J redirects Windows UI from local SQLite to cloud. Phase G does NOT modify any Windows-specific code.

### 32.2 Phase N (Cross-Platform Excel Import)

Phase G does NOT create cloud import_batches table. Phase N will add cloud_import_batches table as needed.

### 32.3 Phase O (Invoice Branding & Delivery)

Phase G preserves current invoice data semantics. Phase O may extend cloud_shop_settings with branding keys.

### 32.4 Phase M (Inventory Conflict Hardening)

Phase G establishes optimistic locking in atomic functions. Phase M adds multi-device conflict resolution policy. Phase G does NOT resolve offline negative stock (Owner Decision OD6).

---

## 33. Open Owner Decision Impact

| Decision | Blocks Phase G? | Reason |
|----------|:---------------:|--------|
| OD1: Final product marketing name | NO | No impact on data schema |
| OD2: License pricing model | NO | Phase G uses existing trial/active/expired model |
| OD3: Max users/devices per plan | NO | Device management is Phase E/C |
| OD4: Offline grace duration | NO | Phase H territory |
| OD5: Invoice footer text | NO | Stored in cloud_shop_settings, no schema impact |
| OD6: Negative stock offline policy | NO | Phase G cloud functions enforce non-negative; offline policy is Phase M |
| OD7: Offline sale allowance | NO | Phase H territory |

No open owner decisions block Phase G.

---

## 34. Proposed SQL Migration Layout

### 34.1 Migration File

`supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql`

Single migration file (all Phase G tables, functions, indexes, RLS, grants).

### 34.2 Migration Execution Order

1. **CREATE TABLES** (dependency order):
   - cloud_expense_categories
   - cloud_products
   - cloud_customers
   - cloud_shop_settings
   - cloud_expenses (FK -> cloud_expense_categories)
   - cloud_inventory_count (FK -> cloud_products)
   - cloud_invoices (FK -> cloud_customers, nullable)
   - cloud_sales (FK -> cloud_invoices, nullable)

2. **CREATE INDEXES** (all from Section 23.1)

3. **ENABLE RLS + CREATE POLICIES** (all from Section 18.2)

4. **CREATE SECURITY DEFINER FUNCTIONS** (all 19 from Section 19.2)

5. **GRANT EXECUTE** on all functions to authenticated

6. **REVOKE** direct table access from authenticated

### 34.3 Migration Rules

- All changes additive (new tables, functions, indexes)
- No modification to existing Phase C-F objects
- No destructive operations
- Rollback: DROP the new tables, functions, and indexes

---

## 35. Proposed File Manifest

### 35.1 SQL Files

| File | Status | Purpose |
|------|--------|---------|
| supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql | NEW SQL | All Phase G cloud tables, functions, RLS, indexes, grants |

### 35.2 Dart Model Files (NEW DART)

| File | Purpose |
|------|---------|
| app/lib/models/cloud/cloud_product.dart | Cloud product DTO |
| app/lib/models/cloud/cloud_customer.dart | Cloud customer DTO |
| app/lib/models/cloud/cloud_sale.dart | Cloud sale DTO |
| app/lib/models/cloud/cloud_return.dart | Cloud return DTO |
| app/lib/models/cloud/cloud_expense.dart | Cloud expense DTO |
| app/lib/models/cloud/cloud_expense_category.dart | Cloud category DTO |
| app/lib/models/cloud/cloud_invoice.dart | Cloud invoice DTO |
| app/lib/models/cloud/cloud_inventory_count.dart | Cloud inventory count DTO |
| app/lib/models/cloud/cloud_shop_setting.dart | Cloud setting DTO |

### 35.3 Dart Repository Files (NEW DART)

| File | Purpose |
|------|---------|
| app/lib/repositories/cloud/cloud_product_repository.dart | Product cloud CRUD |
| app/lib/repositories/cloud/cloud_customer_repository.dart | Customer cloud CRUD |
| app/lib/repositories/cloud/cloud_sales_repository.dart | Sales/Returns/Invoices cloud CRUD |
| app/lib/repositories/cloud/cloud_expense_repository.dart | Expense/Category cloud CRUD |
| app/lib/repositories/cloud/cloud_inventory_repository.dart | Inventory count operations |
| app/lib/repositories/cloud/cloud_settings_repository.dart | Shop settings CRUD |

### 35.4 Dart Service Files (NEW DART)

| File | Purpose |
|------|---------|
| app/lib/services/cloud/cloud_product_service.dart | Product domain operations |
| app/lib/services/cloud/cloud_sales_service.dart | Sales domain operations |
| app/lib/services/cloud/cloud_expense_service.dart | Expense domain operations |
| app/lib/services/cloud/cloud_settings_service.dart | Settings domain operations |

### 35.5 Error Files (NEW DART)

| File | Purpose |
|------|---------|
| app/lib/errors/cloud_data_exception.dart | Cloud data error types |

### 35.6 Test Files (NEW TEST)

| File | Purpose |
|------|---------|
| app/test/cloud_schema_test.dart | Cloud schema existence and structure |
| app/test/cloud_tenant_isolation_test.dart | Cross-tenant access prevention |
| app/test/cloud_permission_test.dart | Permission enforcement per operation |
| app/test/cloud_atomicity_test.dart | Atomic sale/return/invoice operations |
| app/test/cloud_financial_precision_test.dart | Financial value round-trip |
| app/test/cloud_dto_test.dart | DTO serialization/deserialization |

### 35.7 Files NOT Modified

| File | Status |
|------|--------|
| app/lib/database/database_helper.dart | NO CHANGE |
| app/lib/models/product.dart | NO CHANGE |
| app/lib/models/sale.dart | NO CHANGE |
| app/lib/services/permissions.dart | NO CHANGE |
| supabase/migrations/20260820000000_*.sql through 0024_*.sql | NO CHANGE |
| app/test/widget_test.dart | NO CHANGE |
| pubspec.yaml | NO CHANGE |

---

## 36. Detailed Test Matrix

### 36.1 Database Schema Tests (cloud_schema_test.dart)

| ID | Test Case | Verification |
|----|-----------|-------------|
| S-01 | cloud_products table exists | Correct columns |
| S-02 | cloud_customers table exists | Correct columns |
| S-03 | cloud_sales table exists | Correct columns |
| S-04 | cloud_returns table exists | Correct columns |
| S-05 | cloud_expenses table exists | Correct columns |
| S-06 | cloud_expense_categories table exists | Correct columns |
| S-07 | cloud_invoices table exists | Correct columns |
| S-08 | cloud_inventory_count table exists | Correct columns |
| S-09 | cloud_shop_settings table exists | Correct columns |
| S-10 | All tables have shop_id UUID NOT NULL | Column verified |
| S-11 | All tables have deleted_at TIMESTAMPTZ NULL | Column verified |
| S-12 | Foreign keys exist and correct | FK constraints verified |
| S-13 | Unique constraints exist | Verified |
| S-14 | Indexes exist | All from Section 23.1 |
| S-15 | RLS enabled on all tables | relrowsecurity = true |
| S-16 | SELECT policies exist | Policy names verified |
| S-17 | No INSERT/UPDATE/DELETE policies | Direct mutation blocked |
| S-18 | All SECURITY DEFINER functions exist | 19 functions callable |
| S-19 | Financial columns are NUMERIC | Not FLOAT/DOUBLE |
| S-20 | Barcode uniqueness per shop | UNIQUE(shop_id, barcode) verified |

### 36.2 Tenant Isolation Tests (cloud_tenant_isolation_test.dart)

| ID | Test Case | Expected |
|----|-----------|----------|
| T-01 | Shop A member reads shop A products | SUCCESS |
| T-02 | Shop A member reads shop B products | EMPTY (RLS blocks) |
| T-03 | Shop A member creates product in shop A | SUCCESS |
| T-04 | Shop A member creates product in shop B | EXCEPTION |
| T-05 | Shop A member updates shop B product | EXCEPTION |
| T-06 | Shop A member deletes shop B product | EXCEPTION |
| T-07 | Random shop UUID bypass | EMPTY/EXCEPTION |
| T-08 | Suspended member cannot read | EMPTY |
| T-09 | Suspended member cannot write | EXCEPTION |
| T-10 | Unauthenticated cannot read | EMPTY |
| T-11 | Unauthenticated cannot write | EXCEPTION |

### 36.3 Permission Tests (cloud_permission_test.dart)

| ID | Test Case | Role | Expected |
|----|-----------|------|----------|
| P-01 | Owner creates product | owner | SUCCESS |
| P-02 | Employee creates product | employee | SUCCESS |
| P-03 | SalesOnly creates product | salesOnly | EXCEPTION |
| P-04 | Owner creates sale | owner | SUCCESS |
| P-05 | Employee creates sale | employee | SUCCESS |
| P-06 | SalesOnly creates sale | salesOnly | SUCCESS |
| P-07 | Owner deletes sale | owner | SUCCESS |
| P-08 | Employee deletes sale | employee | EXCEPTION (default) |
| P-09 | SalesOnly deletes sale | salesOnly | EXCEPTION |
| P-10 | Owner creates expense | owner | SUCCESS |
| P-11 | Employee creates expense | employee | SUCCESS |
| P-12 | SalesOnly creates expense | salesOnly | EXCEPTION |
| P-13 | Owner accesses settings | owner | SUCCESS |
| P-14 | Employee accesses settings | employee | EXCEPTION (default) |
| P-15 | SalesOnly accesses settings | salesOnly | EXCEPTION |
| P-16 | Employee with override accesses denied permission | employee | SUCCESS |

### 36.4 Atomicity Tests (cloud_atomicity_test.dart)

| ID | Test Case | Verification |
|----|-----------|-------------|
| A-01 | Create sale: stock decremented atomically | Both sale + product succeed or fail |
| A-02 | Create sale insufficient stock: both fail | No sale, product unchanged |
| A-03 | Create sale: concurrent modification detected | Optimistic lock failure |
| A-04 | Delete sale: stock reverted atomically | Both soft-delete + product update |
| A-05 | Create return: stock incremented atomically | Both return + product |
| A-06 | Delete return: stock reverted atomically | Both soft-delete + product |
| A-07 | Create invoice with items: all-or-nothing | Either all created or none |
| A-08 | Create invoice with one bad item: rollback | No invoice, no sales, no product changes |
| A-09 | Save inventory count: product adjusted atomically | Both count + product |
| A-10 | Product deletion blocked with references | Exception, product not deleted |

### 36.5 Financial Precision Tests (cloud_financial_precision_test.dart)

| ID | Test Case | Verification |
|----|-----------|-------------|
| F-01 | Cost price 19.99 stored exactly | No precision loss |
| F-02 | Sale total = qty * price exact | 3 * 19.99 = 59.97 |
| F-03 | COGS = qty * cost exact | 3 * 10.50 = 31.50 |
| F-04 | Sum of sales is exact | SUM returns exact NUMERIC |
| F-05 | Large values within range | 999,999.99 * 999 no overflow |
| F-06 | Zero values rejected | cost_price=0 rejected |
| F-07 | Round-trip JSON NUMERIC to double | Reasonable precision |

### 36.6 DTO Tests (cloud_dto_test.dart)

| ID | Test Case | Verification |
|----|-----------|-------------|
| D-01 | CloudProduct.fromJson/toJson round-trip | Fields preserved |
| D-02 | CloudSale.fromJson with null invoice_id | Nullable handled |
| D-03 | CloudInvoice.fromJson with all fields | All mapped |
| D-04 | CloudShopSetting composite key | Correct |
| D-05 | DateTime serialization | ISO8601 correct |
| D-06 | NUMERIC to double conversion | Reasonable precision |
| D-07 | UUID string handling | Valid format |

### 36.7 Regression Tests

| ID | Test Case | Verification |
|----|-----------|-------------|
| R-01 | flutter analyze passes | 0 errors |
| R-02 | flutter test existing tests | Same results as Phase F |
| R-03 | No new warnings | Compare count |
| R-04 | No modification to existing files | git diff shows only new files |

---

## 37. Implementation Order

### 37.1 Task Sequence

```
T1: Create SQL migration file (tables + constraints)
T2: Add indexes to migration
T3: Add RLS policies to migration
T4: Create simple CRUD SECURITY DEFINER functions
T5: Create atomic compound functions (sales, returns, invoices, inventory)
T6: Add GRANT/REVOKE to migration
T7: Create Dart cloud DTOs (9 model files)
T8: Create error taxonomy (CloudDataException)
T9: Create cloud repositories (6 files)
T10: Create cloud services (4 files)
T11: Create schema existence tests
T12: Create tenant isolation tests
T13: Create permission tests
T14: Create atomicity tests
T15: Create financial precision tests
T16: Create DTO serialization tests
T17: Run flutter analyze
T18: Run flutter test
T19: Git diff verification
T20: Secret scan + conflict marker check
T21: Local commit
```

### 37.2 Critical Path

```
T1 -> T4 -> T5 -> T7 -> T9 -> T10 -> T11 -> T17 -> T18 -> T21
```

---

## 38. Rollback / Recovery Strategy

### 38.1 SQL Migration Rollback

DROP all 19 functions, then DROP all 9 tables (in reverse dependency order).

### 38.2 Dart Code Rollback

All new Dart files are additions. Removing them is sufficient.

### 38.3 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Migration SQL syntax error | LOW | HIGH | Test against local Supabase first |
| Missing index | LOW | MEDIUM | Schema verification tests |
| Permission function not found | LOW | HIGH | Verify Phase F functions exist |
| RLS policy error | LOW | HIGH | Pattern matches existing policies |
| Dart analysis errors | LOW | LOW | Run flutter analyze |

---

## 39. Risks and Mitigations

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | NUMERIC to Dart double precision loss | LOW | Values within safe double range |
| 2 | Invoice number gap if concurrent | LOW | Gap acceptable |
| 3 | Soft-delete query performance | LOW | Index on shop_id covers most queries |
| 4 | Function search-path vulnerability | LOW | SET search_path = public |
| 5 | Overly permissive GRANT | MEDIUM | Explicit GRANT only on specific functions |
| 6 | Phase F functions not deployed | HIGH | Verify Phase F migration exists |
| 7 | Expense category text-match inconsistency | LOW | Both category_id FK and category_name |
| 8 | Concurrent stock modification race | MEDIUM | Optimistic locking |
| 9 | Phase H may need additional columns | LOW | Phase G is additive |
| 10 | Missing test coverage | MEDIUM | Comprehensive test matrix |

---

## 40. Exit Criteria

Phase G implementation is complete when:

1. All 9 cloud business tables created with correct schema
2. All 19 SECURITY DEFINER functions deployed and callable
3. RLS enabled on all new tables with SELECT-only policies
4. All indexes created
5. GRANT/REVOKE properly configured
6. 9 Dart cloud DTOs created with serialization
7. 6 Dart cloud repositories created
8. 4 Dart cloud services created
9. Error taxonomy implemented
10. Schema tests pass
11. Tenant isolation tests pass
12. Permission tests pass
13. Atomicity tests pass
14. Financial precision tests pass
15. DTO tests pass
16. flutter analyze clean (0 errors)
17. flutter test passes (no regressions)
18. git diff --check clean (no conflict markers)
19. No secrets in committed code
20. Preserved artifacts intact

---

## 41. Gate Table

| Gate | Description | Status | Evidence |
|------|------------|:------:|---------|
| G-P01 | Repository root verified | PASS | C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze |
| G-P02 | Correct branch verified | PASS | codex/i-tech-next-roadmap-freeze |
| G-P03 | Correct GitHub remote verified | PASS | github -> https://github.com/sabere342-ai/muaman.worktrees.git |
| G-P04 | Phase F implementation HEAD verified | PASS | 17934ad94c5d2e32ae53e2122f8b460a14ed2efb |
| G-P05 | Phase F direct parent verified | PASS | c518310050a8328877f321ada6428f20d6e07057 |
| G-P06 | Phase F planning tag verified | PASS | c518310050a8328877f321ada6428f20d6e07057 |
| G-P07 | Phase F implementation tag verified | PASS | 17934ad94c5d2e32ae53e2122f8b460a14ed2efb |
| G-P08 | Local/remote divergence = 0/0 | PASS | 0    0 |
| G-P09 | Preserved report hash verified | PASS | 3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07 |
| G-P10 | Preserved delivery hash verified | PASS | 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418 |
| G-P11 | Preserved stash verified | PASS | 3f9e4d2e04b52377a9a8d30db35eae43321dc9f3 |
| G-P12 | Initial worktree integrity verified | PASS | Only untracked preserved artifacts |
| G-P13 | Master plan reviewed | PASS | Full content read |
| G-P14 | Architecture plan reviewed | PASS | Full content read |
| G-P15 | Migration plan reviewed | PASS | Full content read |
| G-P16 | Phase F handoff reviewed | PASS | Trust model, permission catalog analyzed |
| G-P17 | Local SQLite schema forensically inventoried | PASS | 12 tables documented |
| G-P18 | Existing cloud schema inventoried | PASS | 10 tables, 18 functions documented |
| G-P19 | All operational entities classified | PASS | Gap matrix and entity catalog complete |
| G-P20 | Customer entity explicitly covered | PASS | E2: cloud_customers with full field mapping |
| G-P21 | App settings classified | PASS | Classification tables complete |
| G-P22 | Ownership matrix completed | PASS | CRUD + permission per entity |
| G-P23 | Local/cloud ID strategy resolved | PASS | Server-generated UUIDs |
| G-P24 | Relationships/FKs resolved | PASS | Full relationship model |
| G-P25 | Financial data types resolved | PASS | NUMERIC(12,2) and NUMERIC(14,2) |
| G-P26 | Atomic sale/return strategy resolved | PASS | Full PostgreSQL function specs |
| G-P27 | CRUD permission matrix completed | PASS | Full CRUD + permission mapping |
| G-P28 | Licensing integration defined | PASS | Reuse require_shop_permission chain |
| G-P29 | RLS model defined | PASS | SELECT-only policies |
| G-P30 | SECURITY DEFINER model defined | PASS | 19 functions specified |
| G-P31 | Phase G/H boundary explicit | PASS | G creates schema, H creates sync |
| G-P32 | Phase G/I boundary explicit | PASS | G creates target, I populates |
| G-P33 | Phase G/J boundary explicit | PASS | G creates infra, J redirects UI |
| G-P34 | Open owner decisions classified | PASS | None block Phase G |
| G-P35 | Security threat model completed | PASS | 18 threats with mitigations |
| G-P36 | Test strategy completed | PASS | 7 categories, 60+ test cases |
| G-P37 | Proposed implementation manifest completed | PASS | File manifest with status |
| G-P38 | Exactly one planning artifact changed | PASS | Only PHASE_G_CLOUD_DATA_FOUNDATION_PLAN.md |
| G-P39 | No app/lib production changes | PASS | No existing files modified |
| G-P40 | No app/test changes | PASS | No existing test files modified |
| G-P41 | No Supabase migration changes | PASS | No existing migrations modified |
| G-P42 | No deployment | PASS | No deployment performed |
| G-P43 | No secrets | PASS | No secrets in planning document |
| G-P44 | No conflict markers | PASS | git diff --check clean |
| G-P45 | Baseline validations show no regression | PASS | No production code modified |
| G-P46 | Planning document committed locally | PENDING | Awaiting commit |
| G-P47 | Commit parent is Phase F implementation commit | PENDING | Awaiting commit |
| G-P48 | Commit contains only Phase G planning artifact | PENDING | Awaiting commit |
| G-P49 | Preserved hashes reverified after commit | PENDING | Awaiting commit |
| G-P50 | Preserved stash reverified after commit | PENDING | Awaiting commit |
| G-P51 | Final worktree integrity confirmed | PENDING | Awaiting commit |
| G-P52 | No push/tag/history rewrite performed | PENDING | Awaiting commit |

---

## 42. Phase H Handoff

Phase G hands off to Phase H:

```
PHASE_G_CREATES:
  - 9 cloud business tables with shop_id, deleted_at, updated_at
  - SECURITY DEFINER CRUD functions (19)
  - RLS policies for shop isolation
  - Indexes including updated_at for sync queries
  - Dart cloud DTOs and repositories
  - Permission enforcement via require_shop_permission
  - Financial type strategy (NUMERIC)
  - Atomic compound operations

PHASE_H_MUST_CREATE:
  - sync_queue table
  - server_version columns
  - Idempotency key infrastructure
  - Sync engine (retry, orchestration, conflict detection)
  - Tombstone query logic (reads deleted_at)
  - Changed-since query logic (reads updated_at)
  - Offline pending-write processor
  - Real-time subscriptions
  - Background sync worker
  - Local schema v12 changes (sync columns)
  - Conflict resolution UI
  - Offline reconciliation
```

---

## 43. Final Planning Closure Contract

### Verification Checklist

**BASELINE:**
- [x] Repository identity correct
- [x] Phase F baseline locked
- [x] Ancestry chain intact
- [x] Remote divergence = 0
- [x] All governing documents reviewed
- [x] Existing cloud schema reviewed
- [x] Local SQLite schema forensically inventoried

**DESIGN:**
- [x] Entity catalog completed (9 new tables)
- [x] Data ownership matrix completed
- [x] Cloud ID strategy resolved
- [x] Financial type strategy resolved
- [x] Inventory invariants preserved
- [x] Atomic operations specified
- [x] CRUD + permission matrix completed
- [x] RLS model defined
- [x] SECURITY DEFINER strategy defined
- [x] Licensing integration verified
- [x] Error contract defined
- [x] Security threat model completed
- [x] Validation rules specified

**BOUNDARIES:**
- [x] Phase G/H boundary explicit
- [x] Phase G/I boundary explicit
- [x] Phase G/J/N/O/M boundaries explicit
- [x] Open owner decisions classified (none block G)

**DELIVERABLES:**
- [x] SQL migration layout defined
- [x] Dart file manifest defined
- [x] Test matrix defined (7 categories, 60+ cases)
- [x] Implementation order specified
- [x] Rollback strategy defined

**PREPARATION:**
- [x] No production code modified in this session
- [x] Preserved artifacts verified
- [x] Worktree integrity confirmed

**NEXT SESSION:**
Phase G Remote Planning Baseline Lock Session
