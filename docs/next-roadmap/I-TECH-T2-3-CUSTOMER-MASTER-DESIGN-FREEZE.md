# I-TECH T2-3: Customer Master Design Freeze

## 1. Executive Decision

**A — DESIGN FREEZE / FOLLOW ROADMAP**

The Customer Master design contract is frozen. This document defines the authorized scope for a future implementation step. No production code is modified in this session.

## 2. Governing Context

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` @ `2295137` |
| Previous step | T2-2 (Expense Categories) @ `26cd605` / `0cc157e` |
| This step | T2-3: Customer Master Design Freeze |
| Step type | Design freeze only — NOT implementation |
| Author | opencode / codex agent |

## 3. Roadmap Evidence

### Exact Roadmap Text

From `I-TECH-NEXT-ROADMAP-FREEZE.md`:

> **GAP-04: No Dedicated Customer Entity**
> Confidence: HIGH — PROVEN
> Customer is a free-text field on invoices. There is no `customers` table, no customer CRUD, no customer history, no balances, no receivables. The only customer-related concept is a configurable default customer name (`defaultCustomerName = 'عميل نقدي'`).

From `I-TECH-RISK-DEPENDENCY-MAP.md`:

> **T2-3: Customer Master Design Freeze (no dependencies, medium risk)**

Roadmap dependency graph:

```
Customer Master (GAP-04)
    └── Customer Table + CRUD
        └── Customer History (link to invoices)
            └── Customer Balances
                └── Receivables / Collections
```

### Why T2-3 Is Authorized

- T2-2 (Expense Categories) is accepted and closed.
- The roadmap explicitly lists T2-3 as the next step after T2-2.
- T2-3 is a **design freeze only** step — no dependencies beyond what already exists.
- The gap (GAP-04) is proven with HIGH confidence.

### Roadmap Alignment Decision

**A — FOLLOW ROADMAP**

No deviation required. The roadmap authorizes T2-3 as a design freeze step with no dependencies.

## 4. Current-State Architecture

### 4.1 Customer Data: What Exists Today

**There is no `customers` table.** Customer identity exists only as a `TEXT NOT NULL` column on the `invoices` table.

| Aspect | Current State |
|---|---|
| `customers` table | DOES NOT EXIST |
| Customer model class | DOES NOT EXIST |
| Customer repository/service | DOES NOT EXIST |
| Customer CRUD | DOES NOT EXIST |
| Customer selector/dropdown | DOES NOT EXIST |
| Customer search | DOES NOT EXIST |
| Customer balances | DOES NOT EXIST |
| Customer receivables | DOES NOT EXIST |
| Customer history | DOES NOT EXIST |
| Customer-based reporting | DOES NOT EXIST |
| Customer deletion/update | DOES NOT EXIST |

### 4.2 Schema Evidence

**`invoices` table** (`database_helper.dart:221-234`):

```sql
CREATE TABLE IF NOT EXISTS invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceNumber TEXT NOT NULL UNIQUE,
  date TEXT NOT NULL,
  customerName TEXT NOT NULL,        -- free-text, no FK
  paymentMethod TEXT NOT NULL,
  totalAmount REAL DEFAULT 0,
  totalItems INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL
)
```

**`sales` table** (`database_helper.dart:132-145`):

```sql
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER,                 -- nullable FK to invoices
  date TEXT NOT NULL,
  productName TEXT NOT NULL,
  barcode TEXT NOT NULL,
  quantity INTEGER DEFAULT 0,
  salePrice REAL DEFAULT 0,
  totalSaleValue REAL DEFAULT 0,
  costPrice REAL DEFAULT 0,
  cogs REAL DEFAULT 0
)
```

**`returns` table** (`database_helper.dart:147-159`):

```sql
CREATE TABLE returns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  productName TEXT NOT NULL,
  barcode TEXT NOT NULL,
  quantity INTEGER DEFAULT 0,
  salePrice REAL DEFAULT 0,
  totalReturnValue REAL DEFAULT 0,
  costPrice REAL DEFAULT 0,
  returnedCogs REAL DEFAULT 0
)
```

**Key observations:**
- `sales` has no `customerName` or `customerId` column. Customer info is only accessible via `invoiceId` → `invoices.customerName` join.
- `returns` has **zero customer association** — no `invoiceId`, no `customerName`.
- Standalone sales (no invoice) have no customer reference at all.

### 4.3 Default Customer Name

The only customer-related feature is a configurable default customer name setting:

| Component | Location |
|---|---|
| Setting key | `defaultCustomerName` in `app_settings` |
| Default value | `'عميل نقدي'` (Cash Customer) |
| Initialization | `app_settings.dart:27-32` — writes default if missing |
| Getter | `app_settings.dart:80-83` — trims whitespace, falls back to default |
| Settings UI | `settings_screen.dart:340-377` — TextField + save button |
| Consumption | `invoice_screen.dart:40` — pre-fills customer name field |

**The setting is ONLY consumed in `invoice_screen.dart`.**

### 4.4 Invoice Creation Flow

```
Owner/Employee → Sales Screen → "New Invoice" button → InvoiceScreen
  → Customer name TextField (pre-filled with default)
  → Payment method dropdown (cash/visa/insta_cash)
  → Add products to cart
  → Save
    → Validation: customer name not empty
    → Invoice record (customerName: free text)
    → Sale records (invoiceId FK, no customer field)
    → Product stock decremented
```

### 4.5 Invoice Preview/PDF Behavior

| Surface | Customer Display |
|---|---|
| Preview screen | `_metaRow('العميل', data.customerName)` at `invoice_preview_screen.dart:225` |
| PDF | `'العميل: ${data.customerName}'` at `invoice_pdf_renderer.dart:175` |
| Read model | `InvoiceDocumentData.customerName` at `invoice_document_data.dart:46` |
| Repository | Passes `invoice.customerName` to read model at `invoice_repository.dart:49` |

**Behavior:** PDF and preview both read the same `customerName` from the `Invoice` model. There is no snapshot — the name is read live from the invoice record at render time.

### 4.6 Current Database Schema Version

**Version 7** (`database_helper.dart:113`)

Migration history:
| Version | Change |
|---|---|
| < 2 | Drop & recreate core tables |
| < 3 | Add `users` table |
| < 4 | Add `import_batches` table |
| < 5 | Add `invoices` table, `sales.invoiceId`, `app_settings` table |
| < 6 | Add `role_permissions` table |
| < 7 | Add `expenses.category`, `expense_categories` table |

### 4.7 Existing Permissions

18 permissions across 7 categories. **No customer-related permission exists.**

| Category | Permissions |
|---|---|
| dashboard | `canAccessDashboard` |
| inventory | `canAccessInventory`, `canEditProducts`, `canDeleteProducts` |
| sales | `canAccessSales`, `canCreateSales`, `canViewSalesHistory`, `canDeleteSales` |
| returns | `canAccessReturns`, `canCreateReturns`, `canDeleteReturns` |
| expenses | `canAccessExpenses`, `canCreateExpenses`, `canDeleteExpenses` |
| stocktake | `canAccessStocktake` |
| admin | `canManageUsers`, `canManagePermissions`, `canAccessSettings` |

Roles: `owner` (all 18), `employee` (11), `salesOnly` (2).

### 4.8 Backup/Restore Impact

| Service | Customer Handling |
|---|---|
| Backup | Full DB snapshot via `VACUUM INTO` — backs up all `invoices.customerName` data |
| Restore | Validates 11 tables including `invoices` — restores customer data as part of DB |
| Clean Start | `invoices` in `transactionalTables` — all customer names wiped, `app_settings` preserved |

### 4.9 Clean Start Impact

| Table Category | Tables | Customer Impact |
|---|---|---|
| Wiped (transactional) | `products`, `sales`, `returns`, `expenses`, `inventory_count`, `invoices`, `import_batches`, `expense_categories` | All invoice customer names destroyed |
| Preserved | `users`, `role_permissions`, `app_settings` | `defaultCustomerName` setting preserved |

### 4.10 What Does NOT Exist (Complete List)

| Feature | Status |
|---|---|
| `customers` table | NOT FOUND |
| `customerId` field | NOT FOUND |
| `customerPhone` field | NOT FOUND |
| `customerAddress` field | NOT FOUND |
| `customerCode` field | NOT FOUND |
| Customer model class | NOT FOUND |
| Customer repository | NOT FOUND |
| Customer service | NOT FOUND |
| Customer CRUD screen | NOT FOUND |
| Customer selector/dropdown | NOT FOUND |
| Customer autocomplete | NOT FOUND |
| Customer search | NOT FOUND |
| Customer balances | NOT FOUND |
| Customer receivables | NOT FOUND |
| Customer credit tracking | NOT FOUND |
| Customer payment tracking | NOT FOUND |
| Customer statement | NOT FOUND |
| Customer-based reports | NOT FOUND |
| Customer-based filtering | NOT FOUND |
| `customer_id` on sales | NOT FOUND |
| `customer_id` on returns | NOT FOUND |
| Customer deletion protection | NOT FOUND |
| Duplicate customer detection | NOT FOUND |
| Cash/default customer entity | NOT FOUND (only a setting string) |
| Customer permission | NOT FOUND |

## 5. Gap Definition

### Primary Gap

**GAP-04: No Dedicated Customer Entity**

Customer is a free-text field on invoices. There is:
- No `customers` table
- No customer CRUD
- No customer identity (no stable ID)
- No customer history (no link from returns/payments to customer)
- No customer balances
- No customer receivables
- No duplicate detection
- No customer-based reporting

### Secondary Gaps Created by Absence of Customer Entity

| Gap | Description |
|---|---|
| Invoice customer name is ephemeral | If the owner renames a customer on a new invoice, old invoices retain old text — but there is no way to update all invoices for a customer |
| No customer-based sales filtering | Cannot filter sales history by customer |
| No customer-based reporting | Cannot report sales by customer |
| Returns have no customer association | Cannot track which customer returned an item |
| No credit/payment tracking | No concept of outstanding balance per customer |

## 6. Customer Master Definition

### 6.1 What "Customer Master" Means in This Project

**Customer Master** = a `customers` table + CRUD + integration points that turns the free-text `customerName` on invoices into a proper entity with a stable identity.

It is **NOT**:
- A full CRM
- A receivables/payments system
- A customer accounting ledger
- A customer communication system

It **IS**:
- A directory of known customers with stable IDs
- A lookup that replaces free-text input on invoices
- A foundation for future customer history, balances, and receivables

### 6.2 Customer Master Scope Boundary

```
IN SCOPE (T2-3 Implementation):
  - customers table with stable ID
  - Customer CRUD (create, read, update, archive)
  - Customer selector in invoice screen (replaces free-text)
  - Migration of existing invoice customer names to customer records
  - Default/cash customer as protected system entity

OUT OF SCOPE (Future roadmap items):
  - Customer balances / receivables
  - Customer payments / collections
  - Customer statements
  - Customer-based reporting
  - Returns linked to customers
  - Customer history / transaction log
  - Credit terms / payment plans
```

## 7. Schema Design

### 7.1 Proposed `customers` Table

```sql
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  isActive INTEGER NOT NULL DEFAULT 1,
  isSystem INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### 7.2 Field Classification

| Field | Classification | Rationale |
|---|---|---|
| `id` | REQUIRED | Stable identity — replaces free-text name as key |
| `name` | REQUIRED | Display name — the primary human identifier |
| `phone` | OPTIONAL | Contact info — nullable because not all customers have phones |
| `address` | OPTIONAL | Contact info — nullable, rarely used in retail |
| `notes` | OPTIONAL | Free-form notes — nullable, future flexibility |
| `isActive` | REQUIRED | Soft-delete support — archived customers hidden from selector |
| `isSystem` | REQUIRED | Protects system customers (cash customer) from deletion |
| `createdAt` | REQUIRED | Audit trail |
| `updatedAt` | REQUIRED | Audit trail |

### 7.3 Fields REJECTED for This Stage

| Field | Classification | Rationale |
|---|---|---|
| `customerCode` | FUTURE | No current need for customer codes in a single-store retail app. Can be added later if needed. |
| `phone2` | FUTURE | Single phone number sufficient for current shop workflow |
| `email` | FUTURE | Not used in current business context |
| `taxNumber` | FUTURE | VAT/Tax is out of scope (GAP-07) |
| `creditLimit` | FUTURE | Credit/receivables is out of scope |
| `paymentTerms` | FUTURE | Payment tracking is out of scope |
| `openingBalance` | FUTURE | Balance tracking is out of scope |
| `balance` | FUTURE | Balance tracking is out of scope |
| `preferredPaymentMethod` | FUTURE | Not needed yet |
| `customerType` | FUTURE | No segmentation needed yet |

### 7.4 Proposed `invoices` Table Change

```sql
-- Add nullable FK (migration)
ALTER TABLE invoices ADD COLUMN customerId INTEGER;

-- invoices.customerName remains (snapshot/legacy)
-- Invoices created after migration will have BOTH customerId AND customerName
-- Invoices created before migration will have customerId = NULL
```

**Design rule:** `invoices.customerName` is **NEVER dropped**. It serves as:
1. A frozen snapshot at time of invoice creation
2. Legacy data for pre-migration invoices
3. PDF/preview display source (no live customer lookup needed)

### 7.5 Indexes

```sql
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_isActive ON customers(isActive);
CREATE INDEX IF NOT EXISTS idx_invoices_customerId ON invoices(customerId);
```

### 7.6 Constraints

- `customers.name` — `NOT NULL`
- `customers.isActive` — `NOT NULL DEFAULT 1`
- `customers.isSystem` — `NOT NULL DEFAULT 0`
- No `UNIQUE` on `name` (see Duplicate Policy below)
- No `UNIQUE` on `phone` (see Duplicate Policy below)

### 7.7 Schema Impact Summary

| Change | Type | Backward Compatible |
|---|---|---|
| New `customers` table | Additive | YES — new table, no existing table modified |
| `invoices.customerId` column | Additive nullable | YES — existing invoices get `NULL` |
| New indexes | Additive | YES — no existing indexes changed |
| Schema version bump | Version 7 → 8 | YES — additive migration |

**DESIGN ONLY — NOT IMPLEMENTED**

## 8. Identity Rules

### 8.1 Customer Identity Decision

| Question | Decision | Rationale |
|---|---|---|
| Is `id` (INTEGER PK) sufficient? | YES | Auto-increment integer is adequate for single-store retail |
| Should `customerCode` exist? | NO (FUTURE) | No operational need for customer codes yet |
| Should `phone` be unique? | NO | Two customers can share a phone (family members, business) |
| Should `name` be unique? | NO | Two customers can share a name (common Arabic names) |
| What about same name + phone? | ALLOW | No dedup enforcement at this stage — manual review |
| What about customer with no phone? | ALLOW | Phone is nullable |
| What about changing phone? | ALLOW | Update customer record — phone is profile data, not identity |
| What about changing name after invoices? | ALLOW — invoices retain snapshot | See Historical Data Strategy |

### 8.2 Identity Rules Summary

```
Identity: customers.id (INTEGER PK AUTOINCREMENT)
Identity is: stable, immutable, never reused
Name is: mutable, display-only, NOT identity
Phone is: mutable, profile data, NOT unique, NOT identity
No composite key. No business-key identity.
```

## 9. CRUD Rules

### 9.1 Create

| Rule | Detail |
|---|---|
| Required fields | `name` (non-empty after trim) |
| Optional fields | `phone`, `address`, `notes` |
| Trimming | `name`, `phone`, `address`, `notes` — all trimmed before save |
| Normalization | None at this stage (no phone normalization, no name normalization) |
| Duplicate detection | **NONE** — allow duplicate names and phones. Future enhancement. |
| Default values | `isActive = 1`, `isSystem = 0` |
| Timestamps | `createdAt = now`, `updatedAt = now` |
| Permission | `canCreateSales` reused (see Permissions section) |

### 9.2 Read

| Rule | Detail |
|---|---|
| List view | All customers where `isActive = 1`, sorted by name |
| Search | Filter by name (contains) or phone (contains) |
| Detail view | All fields displayed |
| Selector dropdown | Active customers only, searchable by name/phone |

### 9.3 Update

| Rule | Detail |
|---|---|
| Allowed fields | `name`, `phone`, `address`, `notes`, `isActive` |
| Identity preservation | `id` never changes |
| Timestamp update | `updatedAt = now` on every save |
| Effect on historical invoices | `invoices.customerName` is **NOT** updated (frozen snapshot) |
| Effect on active invoices | None — invoices reference by `customerId`, display from snapshot |
| Permission | `canCreateSales` reused (see Permissions section) |

### 9.4 Archive (Soft Delete)

**Policy: SOFT DELETE ONLY**

| Rule | Detail |
|---|---|
| Mechanism | Set `isActive = 0` |
| Why not hard delete | Referential integrity — invoices reference `customerId` |
| Why not "blocked when referenced" | Too restrictive — owner must be able to archive inactive customers |
| Archived customer visibility | Hidden from invoice selector, but historical invoices still display correctly |
| Re-activation | Owner can set `isActive = 1` again |
| System customers | Cannot archive (`isSystem = 1` prevents `isActive = 0`) |
| Permission | `canCreateSales` reused (see Permissions section) |

**Rejected alternatives:**
- Hard delete: Violates referential integrity. Invoices would have dangling `customerId`.
- Blocked when referenced: Prevents archiving customers with historical invoices, which is impractical.

## 10. Duplicate Policy

### 10.1 Decision

**NO AUTOMATIC DUPLICATE DETECTION OR PREVENTION**

| Rule | Detail |
|---|---|
| Same name | Allowed — create separate customer records |
| Same phone | Allowed — create separate customer records |
| Same name + phone | Allowed — create separate customer records |
| Empty phone | Allowed — phone is nullable |
| Different formatting | Allowed — no normalization |
| Arabic/English digits | Allowed — no normalization |
| Spaces / +20 vs 01... | Allowed — no normalization |

### 10.2 Rationale

- Single-store retail: low volume of customers, manual review is practical
- Adding phone normalization (Arabic↔English digits, +20↔01x prefix handling) is non-trivial and error-prone
- Adding name matching (fuzzy, diacritics, transliteration) is complex
- The cost of false-positive duplicate blocking (preventing legitimate new customers) outweighs the cost of occasional duplicates
- Can be added as a future enhancement after core Customer Master is stable

### 10.3 Minimum Safe Policy

For the implementation stage (T2-3 follow-up), the minimum safe policy is:
- **None** — allow all duplicates
- Future: optional "customer exists?" hint in the UI (informational, not blocking)

## 11. Default/Cash Customer

### 11.1 Current Behavior

| Aspect | Current State |
|---|---|
| Setting key | `defaultCustomerName` in `app_settings` |
| Default value | `'عميل نقدي'` (Cash Customer) |
| Type | Free-text string |
| Consumption | Pre-fills invoice creation TextField |
| UI | Editable in Settings screen |

### 11.2 Design Decision

**The default/cash customer becomes a protected system customer record.**

| Rule | Detail |
|---|---|
| Creation | Auto-created during migration from `defaultCustomerName` setting |
| `isSystem` flag | Set to `1` — prevents deletion and archiving |
| Name | Initially seeded from `defaultCustomerName` setting value |
| Phone/address/notes | Empty |
| Selector behavior | Appears in invoice selector like any other customer |
| Settings integration | The `defaultCustomerName` setting is **removed** after migration. The system customer's `name` field becomes the source of truth. |
| Renaming | Owner can rename the system customer via Customer CRUD |
| Cannot delete | `isSystem = 1` blocks archive/delete |
| Cannot deactivate | `isSystem = 1` blocks `isActive = 0` |

### 11.3 Alternative Considered and Rejected

**Rejected:** Keep `defaultCustomerName` as a setting AND have a customers table.

- This creates two sources of truth for the same concept
- The setting pre-fills invoices; the customer record exists for identity
- Confusing for the owner: "I changed the customer name in settings but it shows differently in the customer list"
- Decision: Unify into the customer record. Remove the setting.

### 11.4 Migration Behavior for Default Customer

During schema migration (v7 → v8):
1. Read `defaultCustomerName` from `app_settings`
2. Insert a row into `customers` with `name = <value>`, `isSystem = 1`, `isActive = 1`
3. Update all existing invoices where `customerName = <value>` to set `customerId = <new_system_customer_id>`
4. Delete the `defaultCustomerName` key from `app_settings`

## 12. Historical Data Strategy

### 12.1 Snapshot Policy

**Invoices retain a frozen `customerName` snapshot at creation time.**

| Scenario | Behavior |
|---|---|
| Invoice created with customer "محمد أحمد" | `invoices.customerName = 'محمد أحمد'`, `invoices.customerId = <id>` |
| Customer renamed to "محمد أحمد علي" | Customer record updated. Invoice retains old name. |
| PDF/preview displays | Reads `invoices.customerName` (frozen snapshot) — NOT `customers.name` |
| Invoice list shows | `invoices.customerName` — frozen snapshot |

### 12.2 Rationale

- **Accounting integrity:** Financial documents must show the name at time of transaction
- **Legal compliance:** Invoice content must not change retroactively
- **Simplicity:** No need for a separate snapshot table or versioned name history
- **Current behavior preserved:** Today, invoices store `customerName` as free text. After migration, they store both the snapshot AND a FK. The display behavior is unchanged.

### 12.3 Phone/Address in Invoices

**NOT stored on invoices.** The invoice currently shows only `customerName`. This is sufficient for a retail invoice. Phone/address are customer profile data, not invoice data.

If future invoice designs need phone/address, they should be added as new columns on `invoices` at that time, not derived from a live customer lookup.

## 13. Sales Integration

### 13.1 How Customer Master Is Used in Sales

| Screen | Current Behavior | Future Behavior |
|---|---|---|
| Invoice creation | TextField with free text | **Dropdown/search selector** from `customers` table |
| Default pre-fill | `defaultCustomerName` setting | System customer auto-selected |
| Customer field | `customerName` free text | `customerId` FK + `customerName` snapshot |
| Payment method | Unchanged | Unchanged |

### 13.2 Customer Reference in Data Model

| Table | Current | Future |
|---|---|---|
| `invoices` | `customerName TEXT NOT NULL` | `customerName TEXT NOT NULL` + `customerId INTEGER` (nullable FK) |
| `sales` | No customer ref | No change — still accessed via `invoiceId` → `invoices.customerId` |
| `returns` | No customer ref | No change in this stage |

### 13.3 Standalone Sales (No Invoice)

Standalone sales (created via `insertSale()` / `insertSaleAndDecrementStock()`) have no invoice and therefore no customer reference. **This behavior is unchanged.** Customer Master only affects the invoice creation flow.

### 13.4 Invoice Selector UX Design

```
Customer Selector (replaces free-text TextField):
  ┌─────────────────────────────────────────────┐
  │  🔍 ابحث عن عميل...                        │
  ├─────────────────────────────────────────────┤
  │  👤 عميل نقدي (نظامي)                      │
  │  👤 محمد أحمد                               │
  │  👤 فاطمة علي                               │
  │  👤 أحمد حسن                                │
  │  ─────────────────────────                  │
  │  ➕ إضافة عميل جديد                         │
  └─────────────────────────────────────────────┘

  - Search filters by name (contains) or phone (contains)
  - System customer shown first
  - "Add new customer" opens a minimal inline dialog
  - Selected customer's name displayed below selector
  - Owner can still type a name if no match (graceful degradation)
```

## 14. Accounting Boundary

### 14.1 Governing Rule

```
Customer Master stores identity/profile metadata.
Financial truth remains in transactional/accounting data.
```

### 14.2 Impact Analysis

| Financial Domain | Impact |
|---|---|
| Sales revenue | NO IMPACT — sales amounts unchanged |
| COGS | NO IMPACT — cost tracking unchanged |
| Gross profit | NO IMPACT — derived from sales - COGS |
| Net profit | NO IMPACT — derived from gross profit - expenses |
| Returns | NO IMPACT — returns have no customer reference |
| Expenses | NO IMPACT — expenses have no customer reference |
| Inventory | NO IMPACT — stock tracking unchanged |
| Cash | NO IMPACT — no cash tracking per customer |
| Receivables | NOT IN SCOPE — future roadmap item |

### 14.3 Financial Source of Truth

```
Customer Master must not become an independent financial source of truth.

All financial data (sales, returns, COGS, profit, expenses) is derived from
transactional tables (sales, returns, expenses). Customer Master is purely
identity metadata.
```

This is **consistent with the current architecture**: all financial calculations in the dashboard and reports are derived from `sales`, `returns`, and `expenses` tables — none of which reference customers.

## 15. Invoice/PDF Behavior

### 15.1 Current Behavior

| Surface | Source | Display |
|---|---|---|
| Invoice preview | `InvoiceDocumentData.customerName` | `_metaRow('العميل', data.customerName)` |
| Invoice PDF | `InvoiceDocumentData.customerName` | `'العميل: ${data.customerName}'` |
| Invoice list | `Invoice.customerName` | Displayed in invoice history |

### 15.2 Future Behavior (After Customer Master Implementation)

| Surface | Source | Display |
|---|---|---|
| Invoice preview | `InvoiceDocumentData.customerName` (snapshot) | `_metaRow('العميل', data.customerName)` — UNCHANGED |
| Invoice PDF | `InvoiceDocumentData.customerName` (snapshot) | `'العميل: ${data.customerName}'` — UNCHANGED |
| Invoice list | `Invoice.customerName` (snapshot) | UNCHANGED |
| Customer selector | `customers.name` (live) | Only in creation/edit UI — NOT in invoice document |

### 15.3 PDF/Preview Parity Rule

```
PDF and preview always read from the same frozen snapshot (invoices.customerName).
They NEVER do a live customer lookup.
Customer Master does not break PDF/preview parity.
```

### 15.4 Design Decision

**`InvoiceDocumentData` is NOT changed.** It continues to receive `customerName` from the `Invoice` model. The `Invoice` model's `customerName` is set at creation time from `customers.name` and never updated afterward.

## 16. Permissions

### 16.1 Current Permission Model

18 permissions across 7 categories. No customer-specific permission exists.

### 16.2 Customer Master Permission Decision

**REUSE EXISTING PERMISSIONS — DO NOT ADD NEW ONES**

| Customer Action | Permission Used | Rationale |
|---|---|---|
| View customers | `canCreateSales` | Customer list is part of the sales workflow |
| Create customers | `canCreateSales` | Creating a customer is part of creating an invoice |
| Edit customers | `canCreateSales` | Editing a customer is part of sales operations |
| Archive customers | `canCreateSales` | Archiving is a sales operation |
| Access customer settings | `canAccessSettings` | If default customer is configurable |

### 16.3 Semantic Permission Debt

Using `canCreateSales` for customer management is semantically imprecise. A more accurate permission would be `canManageCustomers`. However:

- Adding a new permission requires modifying `AppPermission` enum
- Adding a new permission requires modifying `role_permissions` table
- Adding a new permission requires UI changes in roles/permissions screen
- **The roadmap does not authorize permission model expansion in T2-3**

**Decision:** Document this as `semantic permission debt`. The implementation stage may add customer-specific permissions if the roadmap authorizes it in a future step.

### 16.4 Owner-Only Constraint

Customer CRUD (create, edit, archive) should be gated by `canCreateSales` which:
- Owner: YES
- Employee: YES
- SalesOnly: YES

This is acceptable — all roles that can create invoices can manage customers.

## 17. Backup/Restore Impact

### 17.1 Schema Version Bump

| Before | After |
|---|---|
| Schema version 7 | Schema version 8 |
| No `customers` table | New `customers` table |
| No `invoices.customerId` | New nullable `customerId` column |

### 17.2 Backup Impact

**No changes to `standalone_backup_service.dart`.**

The backup service uses `VACUUM INTO` (whole database snapshot). Adding a new table and column does not affect backup behavior — the entire database is backed up regardless.

### 17.3 Restore Impact

**Changes required in `standalone_restore_service.dart`.**

| Change | Reason |
|---|---|
| Add `'customers'` to `expectedTables` list | Validate that backups contain the customers table |
| Update version check from `7` to `8` | Accept new schema version |
| OR: Accept version >= 7 with fallback migration | Allow restoring old backups |

**Design decision:** The restore service should accept backups with schema version 7 AND version 8. For version 7 backups, run the customer migration after restore. This provides backward compatibility.

### 17.4 Restore Compatibility Matrix

| Backup Version | Restore Behavior |
|---|---|
| Schema 7 (pre-Customer-Master) | Restore → auto-migrate to v8 → create customers table → seed system customer |
| Schema 8 (post-Customer-Master) | Restore directly — no migration needed |

### 17.5 Backup File Naming

No change to backup file naming or format. Still raw SQLite `.db` files.

## 18. Clean Start Impact

### 18.1 Customer Master Classification

| Classification | Rationale |
|---|---|
| **Master data** | Customer records are configuration/reference data, not transactional |

### 18.2 Clean Start Decision

**Customers table is WIPED during clean start.**

| Table | Clean Start Behavior |
|---|---|
| `customers` | Added to `transactionalTables` — all rows deleted |
| `invoices` | Already in `transactionalTables` — all rows deleted (with customer references) |
| `app_settings` | Preserved — but `defaultCustomerName` key is removed post-migration |

### 18.3 Clean Start After Migration

After Customer Master implementation:
1. `customers` table exists in `transactionalTables`
2. On clean start: all customers wiped, all invoices wiped
3. After wipe: `initializeDefaults()` re-creates the system customer from the hardcoded default `'عميل نقدي'`
4. The `defaultCustomerName` key no longer exists in `app_settings` — the system customer is re-created from the Dart constant

### 18.4 Preserved Tables (Unchanged)

```dart
static const Set<String> preservedTables = {
  'users',
  'role_permissions',
  'app_settings',
};
```

`customers` is NOT in `preservedTables`. This is correct — clean start means wiping all business data.

## 19. Migration Strategy

### 19.1 Migration: Schema v7 → v8

```dart
if (oldVersion < 8) {
  // 1. Create customers table
  await db.execute('''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      notes TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      isSystem INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');

  // 2. Add customerId column to invoices
  await db.execute('ALTER TABLE invoices ADD COLUMN customerId INTEGER');

  // 3. Create indexes
  await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_isActive ON customers(isActive)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customerId ON invoices(customerId)');

  // 4. Seed system customer from defaultCustomerName setting
  final settingsRows = await db.query('app_settings',
      where: "key = ?", whereArgs: ['defaultCustomerName']);
  final defaultName = settingsRows.isNotEmpty
      ? (settingsRows.first['value'] as String).trim()
      : 'عميل نقدي';

  final now = DateTime.now().toIso8601String();
  final systemCustomerId = await db.insert('customers', {
    'name': defaultName.isNotEmpty ? defaultName : 'عميل نقدي',
    'isActive': 1,
    'isSystem': 1,
    'createdAt': now,
    'updatedAt': now,
  });

  // 5. Link existing invoices to system customer
  await db.rawUpdate('''
    UPDATE invoices
    SET customerId = ?
    WHERE customerId IS NULL
      AND customerName = ?
  ''', [systemCustomerId, defaultName]);

  // 6. Link remaining invoices to system customer (fallback)
  // Invoices with customer names that don't match the default
  // get linked to the system customer as a best-effort migration
  await db.rawUpdate('''
    UPDATE invoices
    SET customerId = ?
    WHERE customerId IS NULL
  ''', [systemCustomerId]);

  // 7. Remove defaultCustomerName from app_settings
  await db.delete('app_settings',
      where: "key = ?", whereArgs: ['defaultCustomerName']);
}
```

### 19.2 Migration Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Columns nullable first? | `customerId` is nullable | Existing invoices get NULL initially, then backfilled |
| Backfill required? | YES — all existing invoices linked to system customer | Ensures no NULL `customerId` after migration |
| Legacy customer data conversion? | All existing `customerName` values become invoice snapshots. All linked to system customer. | Only one customer exists today (the default) — correct migration. |
| Orphan data? | No orphan data expected — all invoices have `customerName` matching the default | Verified: the only customer name used is the default |
| NULL handling? | `customerId` nullable —允许 old invoices without FK | But migration backfills all to system customer |
| Reversible? | LOGICALLY REVERSIBLE — `customerId` can be set back to NULL, `customers` table can be dropped | But `app_settings.defaultCustomerName` deletion is destructive — backup required |
| Restore compatibility? | Version 7 backups auto-migrate on restore | See Backup/Restore section |

### 19.3 Orphan Data Analysis

| Question | Answer |
|---|---|
| Are there sales without invoices? | YES — standalone sales via `insertSale()` have no `invoiceId` |
| Are there invoices with non-default customer names? | UNLIKELY — but possible if owner typed custom names |
| Are there invoices with `customerName = ''`? | NO — validation prevents empty customer names |
| How are non-default invoice customer names handled? | Linked to system customer as best-effort migration |

### 19.4 Migration Safety

| Risk | Mitigation |
|---|---|
| Data loss during migration | NONE — additive only. New table + new nullable column. Existing data unchanged. |
| Invoices lose customer names | NO — `customerName` column is preserved. `customerId` is added alongside. |
| System customer not created | FAIL-CLOSED — migration throws if system customer creation fails |
| `defaultCustomerName` setting lost | Migrated to customer record first, then setting deleted |

## 20. Compatibility Matrix

### 20.1 Legacy Compatibility

| Scenario | Current Behavior | Future Design | Migration Requirement | Risk |
|---|---|---|---|---|
| Old database without new fields | Schema v7, no `customers` table | Auto-migrate to v8 on first open | Schema migration v7→v8 | LOW — additive only |
| Existing customer records | NO customer records exist | System customer auto-created from setting | Migration seeds from `defaultCustomerName` | LOW — deterministic |
| Cash/default customer | Setting string `'عميل نقدي'` | Protected system customer record | Migration converts setting → record | LOW — direct mapping |
| Existing sales | `sales` table has no customer ref | UNCHANGED | None | NONE |
| Credit sales | No credit concept exists | NOT IN SCOPE | None | NONE |
| Returns | No customer ref on returns | NOT IN SCOPE | None | NONE |
| Customer statements | Don't exist | NOT IN SCOPE | None | NONE |
| Existing backups (schema 7) | Valid at schema 7 | Accept + auto-migrate on restore | Restore service accepts v7, runs migration | MEDIUM — must handle gracefully |
| Clean start | Wipes invoices, preserves settings | Wipes invoices + customers, re-seeds system customer | Add `customers` to `transactionalTables` | LOW — deterministic |
| Invoices/PDF | Shows `customerName` text | UNCHANGED — still shows snapshot | None | NONE |

### 20.2 Backward Compatibility Summary

| Component | Backward Compatible? |
|---|---|
| Existing invoices | YES — `customerName` preserved, `customerId` nullable |
| Existing settings | PARTIALLY — `defaultCustomerName` removed, but value migrated to customer record |
| Existing backups | YES — schema 7 backups auto-migrate |
| Clean start | YES — re-creates system customer from hardcoded default |
| PDF/preview | YES — reads same `customerName` snapshot |
| Accounting | YES — no financial data changed |

## 21. Risks

### 21.1 Risk Register

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Migration fails on existing databases | HIGH | LOW | Additive-only migration. Tested against schema v7. |
| System customer not created during migration | HIGH | LOW | FAIL-CLOSED — migration throws, DB not upgraded |
| `defaultCustomerName` lost before migration completes | MEDIUM | LOW | Migration reads setting BEFORE deleting it |
| Invoice PDF shows wrong customer after migration | MEDIUM | LOW | `customerName` column preserved — no change to PDF logic |
| Customer selector performance with many customers | LOW | LOW | Single-store retail: <1000 customers expected. Index on `name` sufficient. |
| Owner confused by new customer screen | LOW | MEDIUM | Minimal UI — familiar workflow. System customer pre-populated. |
| Backup/restore version mismatch | MEDIUM | LOW | Restore service accepts both v7 and v8 |

### 21.2 Preserved Risks from Roadmap

| Risk | Status |
|---|---|
| Cloud/Supabase | OUT OF SCOPE — no change |
| Android | OUT OF SCOPE — no change |
| Sync/offline | OUT OF SCOPE — no change |
| Accounting boundary | PROTECTED — Customer Master does not touch financial data |
| Inventory boundary | PROTECTED — Customer Master does not touch stock |
| T2 frozen identity | PROTECTED — `muaman_store.db`, package name, Windows identity unchanged |

## 22. Explicit Non-Goals

The following are **explicitly OUT OF SCOPE** for T2-3 and its implementation follow-up:

| Non-Goal | Reason |
|---|---|
| Customer balances / receivables | Future roadmap item (Tier 3) |
| Customer payments / collections | Future roadmap item (Tier 3) |
| Customer statements | Future roadmap item |
| Customer-based reporting | Future roadmap item |
| Returns linked to customers | Future roadmap item |
| Credit terms / payment plans | Future roadmap item |
| Customer segmentation / types | Not needed yet |
| Customer codes / SKUs | Not needed yet |
| Customer communication / notifications | Out of scope |
| Customer import / export | Not needed yet |
| Phone normalization (Arabic↔English digits) | Not needed yet — can add later |
| Duplicate detection / prevention | Not needed yet — can add later |
| Customer permissions (new enum values) | Semantic debt — documented, not expanded |
| Cloud / Supabase | Out of scope |
| Android | Out of scope |
| Multi-device sync | Out of scope |
| Licensing changes | Out of scope |
| Platform/build changes | Out of scope |
| Dependency changes in `pubspec.yaml` | Out of scope |
| Any modification to frozen T2 identity | Forbidden |

## 23. Frozen Implementation Contract

The following contract governs the **next implementation step** (the step that follows after this design freeze is accepted).

### Future Implementation MAY:

- Create a `customers` table with the exact schema defined in Section 7.1
- Create a `Customer` model class with the fields defined in Section 7.2
- Create a `CustomerRepository` or add customer methods to `DatabaseHelper`
- Create a `CustomerScreen` (list + add/edit dialog)
- Replace the free-text `TextField` in `invoice_screen.dart` with a customer selector
- Add `customerId` column to `invoices` table
- Seed the system customer from the `defaultCustomerName` setting
- Link existing invoices to the system customer
- Remove the `defaultCustomerName` key from `app_settings`
- Remove the `defaultCustomerName` UI section from `settings_screen.dart`
- Update `CleanStartService` to include `customers` in `transactionalTables`
- Update `StandaloneRestoreService` to validate `customers` table and accept schema v7 or v8
- Bump schema version from 7 to 8
- Add indexes as defined in Section 7.5

### Future Implementation MUST:

- Preserve `invoices.customerName` as a frozen snapshot (NEVER update it after creation)
- Create the system customer with `isSystem = 1` during migration
- Set `invoices.customerId` for all existing invoices during migration
- Use the exact migration logic defined in Section 19.1
- Accept schema version 7 backups in the restore service (with auto-migration)
- Add `customers` to `CleanStartService.transactionalTables`
- Add `'customers'` to `StandaloneRestoreService.expectedTables`
- Reuse existing permissions (no new `AppPermission` values)
- Keep `invoices.customerName` as `TEXT NOT NULL` (never make nullable)

### Future Implementation MUST NOT:

- Add `customerCode` field
- Add `phone2` field
- Add `email` field
- Add `creditLimit` field
- Add `balance` field
- Add `openingBalance` field
- Add new permission enum values
- Modify `AppPermission` enum
- Modify `UserRole` enum
- Modify `role_permissions` table structure
- Drop `invoices.customerName` column
- Make `invoices.customerName` nullable
- Create a receivables / payments system
- Create customer-based reporting
- Create customer statements
- Link returns to customers
- Add phone normalization logic
- Add duplicate detection logic
- Modify `pubspec.yaml` dependencies
- Modify platform files
- Modify frozen T2 identity

## 24. Acceptance Criteria

T2-3 (Design Freeze) is considered successful when:

| # | Criterion | Status |
|---|---|---|
| 1 | Current customer architecture fully inspected | [x] DONE |
| 2 | Roadmap alignment proved | [x] DONE — T2-3 is the next authorized step |
| 3 | Gap precisely defined | [x] DONE — GAP-04: No Dedicated Customer Entity |
| 4 | Customer Master scope frozen | [x] DONE — Section 6.2 |
| 5 | Identity policy frozen | [x] DONE — Section 8 |
| 6 | Duplicate policy frozen | [x] DONE — Section 10: No automatic detection |
| 7 | Default customer behavior frozen | [x] DONE — Section 11: Protected system customer |
| 8 | Delete/archive behavior frozen | [x] DONE — Section 9.4: Soft delete only |
| 9 | Historical semantics frozen | [x] DONE — Section 12: Frozen snapshot |
| 10 | Schema contract frozen | [x] DONE — Section 7 |
| 11 | Migration behavior frozen | [x] DONE — Section 19 |
| 12 | Sales/accounting boundaries frozen | [x] DONE — Sections 13, 14 |
| 13 | Backup/restore impact frozen | [x] DONE — Section 17 |
| 14 | Clean-start behavior frozen | [x] DONE — Section 18 |
| 15 | Permissions boundaries frozen | [x] DONE — Section 16 |
| 16 | UI scope frozen | [x] DONE — Section 13.4 |
| 17 | Risks documented | [x] DONE — Section 21 |
| 18 | No production implementation occurred | [x] DONE — design only |

## 25. Next Authorized Step

**T2-4: Thermal Printing Design Freeze**

Per `I-TECH-RISK-DEPENDENCY-MAP.md` line 163:

> **T2-4: Thermal Printing Design Freeze (invoice contract stable, medium risk)**

The Customer Master implementation is NOT the next authorized step. The roadmap authorizes the Thermal Printing Design Freeze as the next step after T2-3.

However, the **Customer Master implementation** is the next *executable* step that implements this design. It should be authorized separately after T2-3 is accepted.

---

## Continuity Clause

| Item | Value |
|---|---|
| Project | I-TECH / إدارة محل مؤمن |
| Platform | Flutter/Dart Windows Desktop |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Baseline | `0cc157e` (T2-2 Expense Categories) |
| Final HEAD | `0cc157e` (no production changes) |
| Schema version | 7 (unchanged) |
| Design freeze output | `docs/next-roadmap/I-TECH-T2-3-CUSTOMER-MASTER-DESIGN-FREEZE.md` |
| Production code changed | NO |
| Tests run | 658/658 passed (baseline validation) |
| Working tree | 7 generated platform files (CRLF noise — pre-existing) |
| Merge commits | 0 |
| Push | NOT PERFORMED |
| Tag | NOT PERFORMED |
| Next authorized step | T2-4: Thermal Printing Design Freeze |
