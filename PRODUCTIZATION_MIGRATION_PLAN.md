# PRODUCTIZATION MIGRATION PLAN

**Date:** 2026-08-19
**Baseline:** `6490d2f`
**Linked from:** `PRODUCTIZATION_ARCHITECTURE_PLAN.md` §11

---

## 1. Migration Overview

This plan covers the safe migration of existing single-store Windows SQLite data into the multi-tenant cloud architecture. The migration is designed to be **idempotent, restartable, auditable, and recoverable**.

### Guiding Principles

1. **Zero data loss** — absolute requirement
2. **Backup first** — mandatory before any migration step
3. **Idempotent steps** — safe to restart at any point
4. **Reconciliation required** — counts and financials must match
5. **Rollback possible** — every phase has undo path

---

## 2. Pre-Migration Requirements

Before any migration code executes:

| Requirement | Verification |
|-------------|-------------|
| Cloud backend deployed | Supabase project live, RLS configured |
| Auth configured | Email/password working, email delivery verified |
| Owner has cloud account | Owner registered + email verified |
| Backup created | `muaman_store.db` copied + SHA-256 computed |
| Record counts captured | Per-table counts stored in manifest |
| Financial totals captured | Sales, returns, expenses, COGS, profit stored |
| Schema version verified | Must be version 8 (current) |
| Test migration completed | Dry run on copy of production DB |

---

## 3. Migration Steps

### Step 1: Pre-Migration Backup

```
Input:  muaman_store.db (current production)
Output: backup manifest + copy

Actions:
1. Copy DB to user-selected backup location
2. Compute SHA-256 of original DB
3. Count records in all 12 tables
4. Compute financial totals:
   - sum(totalSaleValue) from sales
   - sum(cogs) from sales
   - sum(totalReturnValue) from returns
   - sum(returnedCogs) from returns
   - sum(amount) from expenses
   - sum(totalAmount) from invoices
5. Store manifest:
   - backup_path
   - sha256
   - schema_version
   - timestamp
   - record_counts (per table)
   - financial_totals
6. Verify backup is readable (open with SQLite)
```

**Rollback:** Delete backup copy (original untouched).

### Step 2: Create Cloud Shop

```
Input:  Shop profile from app_settings
Output: Cloud shop record + owner membership

Actions:
1. Generate UUID for shop
2. Create shop record in Supabase:
   - id = UUID
   - name = shopName from app_settings
   - owner_user_id = auth.uid() (from cloud account)
   - created_at = server timestamp
3. Create shop_members record:
   - shop_id = shop UUID
   - user_id = owner's auth.uid()
   - role_id = 'owner'
   - status = 'ACTIVE'
   - joined_at = server timestamp
4. Store shop UUID locally in app_settings (key: 'cloudShopId')
```

**Rollback:** Delete shop record + membership (cloud).

### Step 3: Create Role-Permission Cloud Records

```
Input:  Current role_permissions from SQLite
Output: Cloud roles + role_permissions

Actions:
1. For each system role (owner, employee, salesOnly):
   a. Create role record in cloud (is_system = true)
   b. Load current permissions from local role_permissions table
   c. Create role_permissions records in cloud
2. Verify owner role has all 18 permissions
3. Store cloud role IDs locally for mapping
```

**Rollback:** Delete cloud role records.

### Step 4: Upload User Identities

```
Input:  Users from SQLite + cloud auth accounts
Output: Cloud users linked to local users

Actions:
1. For owner:
   a. Owner already has cloud account (Step 2)
   b. Link local user record to cloud auth.uid()
   c. Store cloud_user_id in local users table (new column)
2. For existing employees/salesOnly:
   a. Create cloud auth accounts (invitation flow)
   b. Link local user records to cloud accounts
   c. Create shop_members records with appropriate roles
3. Preserve local password hashes for offline fallback
```

**Rollback:** Remove cloud_user_id links (local data preserved).

### Step 5: Upload Products

```
Input:  Products from SQLite
Output: Cloud products with cloud UUIDs

Actions:
1. For each product in SQLite:
   a. Generate cloud UUID
   b. Create product in cloud:
      - cloud_uuid
      - shop_id
      - All local fields (name, barcode, costPrice, etc.)
      - currentQuantity, soldQuantity, returnedQuantity, etc.
   c. Store mapping: local_id ↔ cloud_uuid in migration_mapping
2. Preserve barcode UNIQUE constraint in cloud
3. Verify product count matches
```

**Rollback:** Delete uploaded products (local preserved).

### Step 6: Upload Sales + Invoices

```
Input:  Sales, invoices from SQLite
Output: Cloud sales + invoices with cloud UUIDs

Actions:
1. For each invoice:
   a. Generate cloud UUID
   b. Create invoice in cloud with all fields
   c. Store mapping
2. For each sale:
   a. Generate cloud UUID
   b. Create sale in cloud with all fields
   c. Link to cloud invoice UUID (if invoiceId exists)
   d. Store mapping
3. Verify:
   - sale count matches
   - sum(totalSaleValue) matches
   - sum(cogs) matches
   - All invoice → sale relationships intact
```

**Rollback:** Delete uploaded sales/invoices (local preserved).

### Step 7: Upload Returns

```
Input:  Returns from SQLite
Output: Cloud returns with cloud UUIDs

Actions:
1. For each return:
   a. Generate cloud UUID
   b. Create return in cloud with all fields
   c. Link to cloud sale UUID (if saleId exists)
   d. Store mapping
2. Verify:
   - return count matches
   - sum(totalReturnValue) matches
   - sum(returnedCogs) matches
```

**Rollback:** Delete uploaded returns.

### Step 8: Upload Expenses + Categories

```
Input:  Expenses, expense_categories from SQLite
Output: Cloud expenses + categories

Actions:
1. For each expense category:
   a. Generate cloud UUID
   b. Create category in cloud
   c. Store mapping
2. For each expense:
   a. Generate cloud UUID
   b. Create expense in cloud with category UUID link
   c. Store mapping
3. Verify:
   - expense count matches
   - sum(amount) matches
   - category assignments preserved
```

**Rollback:** Delete uploaded expenses/categories.

### Step 9: Upload Remaining Entities

```
Input:  customers, inventory_count, import_batches, app_settings
Output: Cloud records

Actions:
1. Upload customers → cloud customers
2. Upload inventory_count → cloud inventory_count (with product UUID links)
3. Upload import_batches → cloud import_batches
4. Upload app_settings → cloud shop settings
5. Verify counts for each
```

**Rollback:** Delete uploaded records.

### Step 10: Reconciliation

```
Input:  Migration mapping + cloud data
Output: Reconciliation report

Actions:
1. For each table:
   a. Count local rows
   b. Count cloud rows (filtered by shop_id)
   c. Verify counts match
2. Financial reconciliation:
   a. Cloud total sales = local total sales
   b. Cloud total COGS = local total COGS
   c. Cloud total returns = local total returns
   d. Cloud total expenses = local total expenses
   e. Cloud gross profit = local gross profit
   f. Cloud net profit = local net profit
3. Relationship integrity:
   a. All sale → invoice links valid
   b. All return → sale links valid
   c. All expense → category links valid
   d. All inventory_count → product links valid
4. If ANY mismatch: STOP, report discrepancy, do not proceed
```

### Step 11: Enable Cloud Sync

```
Input:  Reconciliation passed
Output: Cloud sync enabled

Actions:
1. Mark migration_complete in local DB (new flag)
2. Enable sync_queue processing
3. Initial sync: push any changes since migration started
4. Verify sync is functioning
5. Switch UI to cloud-first data source (with local fallback)
```

---

## 4. Migration Mapping Table

```sql
-- Local SQLite table (created during migration)
CREATE TABLE migration_mapping (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,        -- 'product', 'sale', etc.
    local_id INTEGER NOT NULL,        -- local SQLite PK
    cloud_uuid TEXT NOT NULL,         -- cloud UUID
    migrated_at TEXT NOT NULL,        -- ISO timestamp
    UNIQUE(entity_type, local_id)
);
```

---

## 5. Migration Checkpoints

| Checkpoint | Step | Validation |
|------------|------|------------|
| CP-1 | After Step 1 | Backup exists, hash verified |
| CP-2 | After Step 2 | Cloud shop exists, owner linked |
| CP-3 | After Step 5 | Product count matches |
| CP-4 | After Step 6 | Sales count + financial totals match |
| CP-5 | After Step 10 | Full reconciliation passed |
| CP-6 | After Step 11 | Cloud sync operational |

---

## 6. Error Recovery

| Error | Recovery |
|-------|----------|
| Network failure during upload | Resume from last successfully uploaded entity |
| Cloud service unavailable | Retry with exponential backoff; local data safe |
| Partial upload (some entities) | Reconciliation catches mismatch; re-upload failed entities |
| Reconciliation failure | STOP migration; investigate; do not enable sync |
| Auth failure | Verify cloud credentials; re-authenticate |
| Duplicate key error | Idempotent: skip already-uploaded entity |

---

## 7. Post-Migration Verification

After migration completes:

1. **Functional test:** Create a sale on Windows → verify it appears in cloud
2. **Functional test:** Create a sale on Android → verify it appears in Windows
3. **Data integrity:** Run reconciliation script again
4. **Financial check:** Dashboard totals match pre-migration values
5. **Performance:** No noticeable slowdown in operations
6. **Offline test:** Disconnect internet → create sale → reconnect → verify sync

---

## 8. Migration Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|-------------|
| Step 1: Backup | Minutes | None |
| Step 2: Cloud shop | Minutes | Cloud account |
| Step 3: Roles | Minutes | Step 2 |
| Step 4: Users | 10-30 min | Steps 2-3 (email invitations) |
| Step 5: Products | Minutes | Step 2 |
| Step 6: Sales+Invoices | Minutes-Hours | Steps 2, 5 |
| Step 7: Returns | Minutes | Steps 2, 6 |
| Step 8: Expenses | Minutes | Step 2 |
| Step 9: Remaining | Minutes | Step 2 |
| Step 10: Reconciliation | Minutes | All previous |
| Step 11: Enable sync | Minutes | Step 10 |
| **Total** | **Minutes to Hours** | Based on data volume |

---

*This document is the migration strategy for I Tech productization.*
*Linked from PRODUCTIZATION_ARCHITECTURE_PLAN.md.*
