# I-TECH Next Controlled Roadmap Freeze

## 1. Executive Decision

**A — NEW ROADMAP FROZEN / FOLLOW ROADMAP**

The previous Productization / Configurability lineage is closed. A new controlled post-productization roadmap has been frozen based on verified repository evidence. No production implementation is authorized in this session.

## 2. Governing Baseline

| Item | Value |
|---|---|
| Repository | I-TECH / إدارة محل مؤمن |
| Baseline commit | `a0c2eb7e25363bda10985c09f47267eb851783f9` (short: `a0c2eb7`) |
| Accepted branch | `codex/i-tech-invoice-header-footer-config` |
| DB filename | `muaman_store.db` |
| Package name | `muaman_store` |
| Version | `1.0.0+1` |
| Windows CompanyName | I-TECH |
| DB schema version | 6 |

## 3. Previous Closed Lineage

| Item | Status |
|---|---|
| Productization / Configurability lineage | **CLOSED** |
| Last accepted commit | `a0c2eb7` |
| Governing decision | A — FOLLOW ROADMAP |
| Reopening forbidden | YES |

Frozen T2 compatibility identity:
- `muaman_store.db`
- `BINARY_NAME` / executable identity
- `muaman_store` pubspec package name
- Windows `Runner.rc` CompanyName / ProductName identity
- install/data paths
- All persisted `app_settings` keys

## 4. Repository / Git Evidence

```
Branch:           codex/i-tech-next-roadmap-freeze
HEAD:             a0c2eb7e25363bda10985c09f47267eb851783f9
Commits after:    0
Relation to base: HEAD = a0c2eb7 (identical)
Working tree:     clean (no production changes)
```

## 5. Current Application Capability Map

### Core Domain

| Capability | Status | Evidence |
|---|---|---|
| Products (CRUD) | COMPLETE | `database_helper.dart`, `inventory_screen.dart` |
| Sales (CRUD) | COMPLETE | `database_helper.dart`, `sales_screen.dart`, `invoice_screen.dart` |
| Returns (CRUD) | COMPLETE | `database_helper.dart`, `returns_screen.dart` |
| Expenses (CRUD) | COMPLETE | `database_helper.dart`, `expenses_screen.dart` |
| Inventory Count / Stocktake | COMPLETE | `database_helper.dart`, `inventory_count_screen.dart` |
| Invoices (header + items) | COMPLETE | `database_helper.dart`, `invoice_repository.dart` |
| PDF invoice (A4) | COMPLETE | `invoice_pdf_renderer.dart`, `invoice_delivery.dart` |
| PDF preview | COMPLETE | `invoice_preview_screen.dart` |
| Workbook import (XLSX) | COMPLETE | `workbook_importer.dart`, `xlsx_reader.dart` |
| Dashboard | COMPLETE | `dashboard_screen.dart` |
| Sales reports (3 tabs) | COMPLETE | `sales_report_screen.dart` |
| COGS tracking | COMPLETE | `database_helper.dart` (sales.cogs, returns.returnedCogs) |
| Negative stock prevention (sales) | COMPLETE | `insertSaleAndDecrementStock` |
| Orphan integrity detection | COMPLETE | `findProductReferenceIntegrityIssues` |
| Barcode auto-generation | COMPLETE | `generateBarcode()` |

### Productization / Configurability (Closed Lineage)

| Feature | Status |
|---|---|
| Shop name / profile | COMPLETE |
| Shop logo | COMPLETE |
| Configurable brand color | COMPLETE |
| Button style | COMPLETE |
| Permissions (16 granular) | COMPLETE |
| User roles (owner / employee / salesOnly) | COMPLETE |
| Default customer name | COMPLETE |
| Support phone | COMPLETE |
| Invoice title | COMPLETE |
| Invoice footer text | COMPLETE |
| PDF / preview parity | COMPLETE |
| Windows delivery foundation | COMPLETE |

### Auth / Permissions

| Capability | Status |
|---|---|
| First-owner setup | COMPLETE |
| Login / logout | COMPLETE |
| Role-based access control | COMPLETE |
| Permission-gated navigation | COMPLETE |
| Data-layer permission enforcement | COMPLETE |
| Owner-exclusive powers | COMPLETE |
| Persistent role permissions | COMPLETE |

### Data Safety

| Capability | Status |
|---|---|
| Clean-start with mandatory backup | COMPLETE |
| Backup verification (integrity + read) | COMPLETE |
| Fail-closed on backup failure | COMPLETE |
| Confirmation phrase gate | COMPLETE |
| Transactional wipe | COMPLETE |
| Preserved tables (users, settings, roles) | COMPLETE |

## 6. Proven Gaps

### GAP-01: Hardcoded Brand Color in Individual Screens

**Confidence: HIGH — PROVEN**

28 occurrences of `Color(0xFF0D47A1)` across 7 production screen files. The `main.dart` correctly loads the configurable brand color and applies it via `ThemeData.colorScheme`, but individual screens bypass the theme and hardcode the same default blue value.

**Impact:** When the owner changes the brand color in settings, the theme (AppBar, buttons) updates, but icons, card backgrounds, text accents, and section headers across sales, settings, dashboard, invoices, and reports remain the original blue. This is a material inconsistency in the configurable brand-color promise.

**Files affected:**
- `screens/sales/sales_screen.dart` (5 occurrences)
- `screens/sales/sales_report_screen.dart` (5 occurrences)
- `screens/sales/invoice_screen.dart` (1 occurrence)
- `screens/invoices/invoice_preview_screen.dart` (2 occurrences)
- `screens/settings_screen.dart` (10 occurrences)
- `screens/dashboard/dashboard_screen.dart` (1 occurrence)
- `screens/admin/roles_permissions_screen.dart` (2 occurrences)
- `main.dart` (2 occurrences — legitimate default/fallback)
- `services/app_settings.dart` (1 occurrence — legitimate default constant)

**Production-impacting:** ~26 occurrences (excluding the 2 legitimate fallbacks in main.dart and the constant in app_settings.dart).

### GAP-02: No Standalone Backup / Restore Workflow

**Confidence: HIGH — PROVEN**

The `CleanStartService` implements a backup-before-wipe pattern. Backup is created via `VACUUM INTO` and verified with `PRAGMA integrity_check` + table count. However:

- Backup is ONLY accessible through the clean-start flow (owner-only, requires typing confirmation phrase, then wipes all data)
- There is NO standalone "backup now" button
- There is NO "restore from backup" feature
- There is NO automatic/scheduled backup
- There is NO encryption of backup files
- There is NO retention policy
- There is NO cross-machine restore validation

**Current-shop sufficiency:** For a single-store Windows deployment where the owner manages the machine directly, the clean-start backup provides a safety net before data wipe. The owner can manually copy `muaman_store.db` as a crude backup. This is marginally sufficient for current delivery.

**Future-product gap:** A reusable retail product needs a dedicated backup/restore workflow independent of destructive operations.

### GAP-03: Licensing Is Cosmetic / Non-Enforcing

**Confidence: HIGH — PROVEN**

The `AppSettings.validateLicenseKey()` method accepts any key starting with `MUAMAN-` that is at least12 characters. There is no cryptographic validation, no expiration check, no machine binding, no trial period, and no enforcement gate. The application runs fully regardless of license status.

**Current-shop delivery:** Adequate. The shop is a known deployment to a specific owner.

**Future-product gap:** For resale, licensing needs real enforcement, machine binding, and optionally trial expiration.

### GAP-04: No Dedicated Customer Entity

**Confidence: HIGH — PROVEN**

Customer is a free-text field on invoices. There is no `customers` table, no customer CRUD, no customer history, no balances, no receivables. The only customer-related concept is a configurable default customer name (`defaultCustomerName = 'عميل نقدي'`).

### GAP-05: No Supplier / Purchasing Domain

**Confidence: HIGH — PROVEN**

No supplier table, no purchase documents, no stock receipt from purchases, no supplier balances, no supplier payments. Products enter the system only through manual creation or XLSX workbook import.

### GAP-06: No Thermal / POS Printing

**Confidence: HIGH — PROVEN**

Zero occurrences of `thermal`, `pos print`, `58mm`, `80mm`, `receipt print`, or `printer config` in the codebase. The only printing capability is A4 PDF generation via the `pdf` and `printing` packages.

### GAP-07: No VAT / Tax

**Confidence: HIGH — PROVEN**

No tax, VAT, or GST fields anywhere in models, database schema, or UI. Sales are recorded without any tax component.

### GAP-08: No Expense Categories

**Confidence: HIGH — PROVEN**

The `Expense` model has only: `id`, `date`, `description`, `amount`. No category field, no category CRUD, no category reporting.

### GAP-09: No Barcode Scanner Integration

**Confidence: MEDIUM**

Barcode is a text field on products. There is no camera-based scanning, no USB scanner listener, no scanner-specific integration. Products are found by typing barcode or name in search fields.

### GAP-10: No Multi-Currency

**Confidence: HIGH — PROVEN**

All monetary values are `REAL` with no currency field. Single currency assumed.

### GAP-11: No Customer Display

**Confidence: HIGH — PROVEN**

No secondary display, customer-facing screen, or display protocol.

## 7. Rejected / Unproven Suspected Gaps

### REJECTED: Negative Stock Protection Defect

The `insertSaleAndDecrementStock` method at `database_helper.dart:500` enforces `currentQuantity >= sale.quantity` with an optimistic lock (`WHERE id = ? AND currentQuantity >= ?`). Returns also check stock availability before reversal (`ReturnStockReversalException`). **No defect found.**

### REJECTED: Missing COGS Tracking

COGS is tracked at the sale line level (`sales.cogs`) and return line level (`returns.returnedCogs`). Dashboard computes `grossProfit = netSales - netCOGS`. **No defect found.**

### REJECTED: Missing Accounting Totals

Dashboard computes: totalSales, totalReturns, netSales, totalCOGS, totalReturnedCOGS, netCOGS, grossProfit, totalExpenses, netProfit. Sales reports provide daily and product-level grouping. **No defect found.**

### UNPROVEN: Negative Stock via Inventory Adjustment

The `saveInventoryCount` method allows setting `inventoryAdjustment` to any value that results in `actualQuantity >= 0`. However, the adjustment calculation at line 1084 could theoretically produce an `inventoryAdjustment` that makes `currentQuantity` of OTHER products negative if cross-product constraints were needed. In the current single-product-per-operation model this is not a practical defect. **Low priority, unproven as a real issue.**

## 8. Gap Prioritization

| Gap | Current-Shop Need | Future-Product Need | Risk | Dependencies | Schema Impact |
|---|---|---|---|---|---|
| GAP-01 Brand Color | HIGH VALUE | REQUIRED | Low | None | None |
| GAP-02 Backup/Restore | OPTIONAL | REQUIRED | Medium | None | Additive (new UI only) |
| GAP-03 Licensing | NOT NEEDED NOW | REQUIRED | Low | None | Additive (new keys) |
| GAP-04 Customer Entity | OPTIONAL | HIGH VALUE | High | Requires schema | Additive (new table) |
| GAP-05 Supplier/Purchase | NOT NEEDED NOW | HIGH VALUE | Very High | Requires full domain redesign | Additive (new tables) |
| GAP-06 Thermal Printing | OPTIONAL | HIGH VALUE | Medium | Requires printer hardware | None |
| GAP-07 VAT/Tax | OPTIONAL | REQUIRED | High | Requires schema + accounting | Additive (fields + logic) |
| GAP-08 Expense Categories | OPTIONAL | OPTIONAL | Low | None | Additive (new field) |
| GAP-09 Barcode Scanner | OPTIONAL | OPTIONAL | Low | Requires hardware | None |
| GAP-10 Multi-Currency | NOT NEEDED NOW | OPTIONAL | High | Requires schema + accounting | Additive (fields) |
| GAP-11 Customer Display | NOT NEEDED NOW | OPTIONAL | Medium | Requires hardware | None |

## 9. Dependency Graph

```
Data Safety
    └── Standalone Backup (GAP-02)
        └── Restore workflow
        └── Retention guidance

Brand Consistency
    └── Configurable Color Consumption (GAP-01)
        └── Can proceed independently, zero risk

Customer Master
    └── Customer Table + CRUD (GAP-04)
        └── Customer History
            └── Customer Balances
                └── Receivables / Collections

Supplier Master
    └── Supplier Table + CRUD (GAP-05)
        └── Purchase Documents
            ├── Inventory Receipt / Costing
            └── Supplier Payables
                └── Supplier Payments

Tax / VAT
    └── Tax Rate Configuration (GAP-07)
        └── Tax Calculation on Sales
        └── Tax Reporting

Thermal Printing
    └── Invoice Data Contract
        └── Thermal Layout
            └── Physical Printer Acceptance

Commercial Protection
    └── Licensing Policy (GAP-03)
        └── Binding Strategy
            └── Enforcement
```

## 10. Schema / Data Impact Map

| Candidate | Schema Change | Migration Type | Backward Compatible |
|---|---|---|---|
| GAP-01 Brand Color | None | None | N/A |
| GAP-02 Standalone Backup | None (UI only) | None | N/A |
| GAP-03 Licensing | Additive keys in `app_settings` | Additive | YES |
| GAP-04 Customer Entity | New `customers` table | Additive | YES |
| GAP-04 Invoice customer link | Nullable FK on `invoices` | Additive | YES |
| GAP-05 Supplier Entity | New `suppliers` table | Additive | YES |
| GAP-05 Purchase Documents | New `purchases` + `purchase_items` tables | Additive | YES |
| GAP-06 Thermal Printing | None (UI/rendering only) | None | N/A |
| GAP-07 VAT/Tax | New columns on `sales`, `products` | Additive | YES |
| GAP-08 Expense Categories | New `category` column on `expenses` | Additive | YES |

All proposed schema changes are additive nullable or new tables. No destructive migration required. Frozen T2 identity (`muaman_store.db` filename, package identity, Windows identity) remains untouched.

## 11. Risk Assessment

| Domain | Current State | Roadmap Risk | Mitigation | Blocks First Step |
|---|---|---|---|---|
| Cloud/Supabase | None | No risk | Out of scope | NO |
| Android | None | No risk | Out of scope | NO |
| Sync/offline | None | No risk | Out of scope | NO |
| Accounting | Correct (COGS, gross/net profit) | Future purchase domain could affect | Isolate purchase domain | NO |
| Inventory | Correct (negative stock prevented on sales) | Future purchase domain could affect | Isolate purchase domain | NO |
| Backup/Restore | Clean-start backup only | Standalone backup adds no risk | UI-only change | NO |
| Licensing | Cosmetic only | Strengthening is low-risk | Isolate from core flow | NO |
| Windows Delivery | Established baseline | No change needed | None | NO |
| UI/UX | Brand color inconsistency (GAP-01) | Fixing is low-risk | Theme-first approach | NO |
| Schema/data | Version 6, all additive | Future tables are additive | Additive-only policy | NO |
| T2 frozen identity | Protected | No change proposed | None | NO |

## 12. Roadmap Tier 1 — Recommended Next Controlled Work

### T1-1: Configurable Brand Color Consumption Audit & Fix

**Objective:** Ensure all UI elements that currently hardcode `Color(0xFF0D47A1)` consume the configurable brand color from the theme or `AppSettings`.

**Scope:** Replace ~26 hardcoded `Color(0xFF0D47A1)` usages in 7 screen files with `Theme.of(context).colorScheme.primary` or the resolved brand color.

**Forbidden scope:** No new features, no schema changes, no new dependencies, no new screens, no licensing changes, no backup changes.

**Expected files:** `sales_screen.dart`, `sales_report_screen.dart`, `invoice_screen.dart`, `invoice_preview_screen.dart`, `settings_screen.dart`, `dashboard_screen.dart`, `roles_permissions_screen.dart`.

**Schema impact:** None.
**Persistence impact:** None.
**Compatibility impact:** None.

**Tests required:** Existing `app_settings_brand_color_test.dart` must pass. Visual verification on Windows.

**Negative controls:** Changing brand color in settings must immediately reflect across ALL screens, not just AppBar/buttons.

**Rollback/recovery:** Git revert (single commit).

**Acceptance criteria:**
1. Every UI element that previously showed the default blue now shows the configured brand color.
2. No remaining `Color(0xFF0D47A1)` in screen files except the legitimate fallback in `main.dart` and constant in `app_settings.dart`.
3. `flutter analyze` passes.
4. Existing tests pass.

**Stop conditions:** If more than 5 files require changes beyond simple color replacement, stop and reassess.

### T1-2 (Future, after T1-1 accepted): Standalone Backup / Restore Design Freeze

**Objective:** Freeze the design contract for a standalone owner-facing backup/restore workflow.

**NOT implementation.** This would be a narrow design/contract freeze document before any code.

## 13. Roadmap Tier 2 — Domain / Product Expansion

Items requiring broader domain/schema evolution. Each requires its own design freeze before implementation.

| Item | Dependencies | Risk | Priority |
|---|---|---|---|
| Standalone Backup/Restore | None | Medium | HIGH |
| Expense Categories | None | Low | MEDIUM |
| Customer Master | None | High | MEDIUM |
| Thermal/POS Printing | Invoice data contract | Medium | MEDIUM |
| VAT/Tax Configuration | Schema + accounting design | High | MEDIUM |
| Customer History / Balances | Customer Master | High | LOW-MEDIUM |

## 14. Roadmap Tier 3 — Future Commercial / Platform Work

| Item | Dependencies | Risk | Notes |
|---|---|---|---|
| Licensing Hardening | Delivery policy + identity decision | Low-Medium | Separate from current shop |
| Anti-Cloning Strategy | Licensing + DB encryption | High | Future resale only |
| Cloud / Supabase | Independently authorized roadmap | High | OUT OF SCOPE |
| Android | Independently authorized roadmap | High | OUT OF SCOPE |
| Multi-Device Sync | Cloud + schema design | Very High | OUT OF SCOPE |
| Supplier / Purchase Domain | Full domain redesign | Very High | Major expansion |
| Customer Receivables | Customer Master + payment design | High | Major expansion |
| Multi-Currency | Schema + accounting redesign | High | Future resale |
| Customer Display | Hardware protocol | Medium | Optional hardware |

## 15. Explicit Exclusions

The following are explicitly OUT OF SCOPE for this roadmap:

- Cloud / Supabase / Firebase / remote backend
- Android / iOS / mobile adaptation
- Multi-device synchronization
- Supplier / purchase domain implementation
- Customer receivables / payments / collections
- VAT / tax implementation
- Multi-currency
- Licensing implementation / hardening
- Database encryption
- Any modification to frozen T2 compatibility identity
- Any modification to `muaman_store.db` filename
- Any modification to package name, AppId, Windows identity
- Any modification to existing accounting logic
- Any modification to existing inventory logic
- Any new dependencies in `pubspec.yaml`
- Any platform runner changes
- Any Android Gradle changes

## 16. Acceptance Philosophy for Future Steps

Every future executable step must:

1. Be based on verified repository evidence, not assumptions.
2. Have a clear objective, scope, and forbidden scope.
3. Have defined schema impact (prefer additive nullable).
4. Be independently committable and accept/rejectable.
5. Have defined tests (automated where possible, Windows interactive where needed).
6. Have defined rollback expectations.
7. Not modify frozen T2 identity.
8. Not open Cloud/Android scope.
9. Be easy to stop after acceptance — each step stands alone.
10. Have a single next step authorized at any time.

## 17. Single Next Authorized Step

**T1-1: Configurable Brand Color Consumption Audit & Fix**

Replace ~26 hardcoded `Color(0xFF0D47A1)` usages across 7 screen files with theme-based or settings-based brand color consumption. This is the only authorized implementation step.

All other implementation (standalone backup, customer entity, thermal printing, licensing, suppliers, VAT, expense categories, etc.) remains unauthorized until that step is completed and accepted.
