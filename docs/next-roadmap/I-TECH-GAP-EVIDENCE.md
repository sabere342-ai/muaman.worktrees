# I-TECH Gap Evidence Report

## GAP-01: Hardcoded Brand Color in Individual Screens

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
28 matches for `0xFF0D47A1` across production screen files.

**Files and line numbers:**

| File | Lines | Occurrences | Classification |
|---|---|---|---|
| `app/lib/main.dart` | 44, 79 | 2 | Legitimate default/fallback |
| `app/lib/services/app_settings.dart` | 20 | 1 | Legitimate default constant |
| `app/lib/screens/settings_screen.dart` | 190, 204, 255, 307, 361, 415, 533, 551, 625, 870 | 10 | Configurability violation |
| `app/lib/screens/sales/sales_screen.dart` | 148, 174, 245, 317 | 4 | Configurability violation |
| `app/lib/screens/sales/sales_report_screen.dart` | 115, 218, 346, 418, 474 | 5 | Configurability violation |
| `app/lib/screens/sales/invoice_screen.dart` | 223 | 1 | Configurability violation |
| `app/lib/screens/invoices/invoice_preview_screen.dart` | 309, 322 | 2 | Configurability violation |
| `app/lib/screens/dashboard/dashboard_screen.dart` | 163 | 1 | Configurability violation |
| `app/lib/screens/admin/roles_permissions_screen.dart` | 297, 365 | 2 | Configurability violation |

**Total:** 28 occurrences
- Legitimate: 3 (main.dart fallbacks + app_settings constant)
- Production-impacting configurability violations: 25

**Current behavior:** `main.dart` loads the configurable brand color via `AppSettings.getBrandColor()`, parses it, and applies it through `ThemeData.colorScheme.fromSeed(seedColor: _brandColor)`. The AppBar and ElevatedButton styles correctly inherit from this theme. However, individual screens directly reference `Color(0xFF0D47A1)` for icons, card decorations, text colors, section backgrounds, and accents.

**Business impact:** When the owner changes the brand color in Settings, the AppBar and buttons update correctly, but dozens of visual elements across the app retain the original blue. This undermines the "configurable brand color" feature promise.

**Current-shop relevance:** HIGH — the owner can already change brand color and will notice the inconsistency.

**Future-product relevance:** REQUIRED — a reusable retail product must have consistent brand color consumption.

**Risk:** LOW — straightforward theme adoption, no logic changes.

**Dependencies:** None.

**Schema impact:** None.

---

## GAP-02: No Standalone Backup / Restore

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
`app/lib/services/clean_start_service.dart` (193 lines), `app/lib/screens/settings_screen.dart` (lines 629-809).

**Current behavior:**
- Owner navigates to Settings > Clean Start section (owner-only, gated by `_isOwner` check).
- Owner selects a backup directory.
- Owner types the exact confirmation phrase `'مسح البيانات'`.
- `CleanStartService.run()` creates a backup via `VACUUM INTO`, verifies it with `PRAGMA integrity_check` + table count, then wipes all transactional tables in a single transaction.
- Backup file: `muaman_cleanstart_<timestamp>.db` in the selected directory.
- Preserved tables: `users`, `role_permissions`, `app_settings`.

**What does NOT exist:**
- No "backup now" button outside clean-start flow.
- No "restore from backup" feature.
- No automatic/scheduled backup.
- No backup encryption.
- No retention policy.
- No cross-machine restore validation.
- No standalone backup accessible to the owner outside a destructive operation.

**Business impact:** The owner has no routine way to back up data without also wiping it. They can manually copy `muaman_store.db`, but this is not surfaced in the UI and requires knowing the file location.

**Current-shop relevance:** OPTIONAL — for a single-store deployment, manual DB file copy is a crude but functional workaround. The clean-start backup provides safety before wipe.

**Future-product relevance:** REQUIRED — a reusable retail product needs dedicated backup/restore.

**Risk:** MEDIUM — a restore feature would need schema version compatibility checks.

**Dependencies:** None for backup. Restore requires future schema compatibility design.

**Schema impact:** None for standalone backup. Restore may need metadata table.

---

## GAP-03: Licensing Is Cosmetic

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
`app/lib/services/app_settings.dart` lines 106-115:

```dart
static Future<bool> validateLicenseKey(String key) async {
  final normalized = key.trim();
  if (normalized.isEmpty) return false;
  if (normalized.startsWith('MUAMAN-') && normalized.length >= 12) {
    await setValue(keyLicenseKey, normalized);
    await setValue(keyLicenseStatus, 'active');
    return true;
  }
  return false;
}
```

**Current behavior:** Any string starting with `MUAMAN-` and at least12 characters is accepted. No cryptographic validation, no expiration, no machine binding. The application runs fully regardless of `licenseStatus`. The settings screen shows "active" / "not activated" but this has no effect on functionality.

**Business impact:** None for current shop deployment. The application is fully functional without any license key.

**Current-shop relevance:** NOT NEEDED — the shop is a known deployment.

**Future-product relevance:** REQUIRED — resale requires real licensing.

**Risk:** LOW — strengthening is additive, does not affect core functionality.

**Dependencies:** None.

**Schema impact:** Additive (new app_settings keys).

---

## GAP-04: No Dedicated Customer Entity

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
- `invoices` table has `customerName TEXT NOT NULL` — a free-text string field.
- `invoice_screen.dart:22` has `_customerController = TextEditingController()`.
- `invoice_screen.dart:40` loads default customer name from settings.
- No `customers` table exists in `database_helper.dart:_createDB`.
- No customer model exists (only `invoice.dart` which has `customerName` as a field).
- No customer CRUD screen.

**Current behavior:** Every invoice records a customer name as free text. The default is configurable (`defaultCustomerName = 'عميل نقدي'`). There is no customer history, no balances, no receivables.

**Business impact:** The shop cannot track repeat customers, their purchase history, or outstanding balances.

**Current-shop relevance:** OPTIONAL — many small shops operate fine without customer records.

**Future-product relevance:** HIGH VALUE — customer tracking is a core retail feature.

**Risk:** HIGH — introducing customers changes the data model and requires careful FK design.

**Dependencies:** Standalone (can be designed independently).

**Schema impact:** New `customers` table, nullable FK on `invoices`.

---

## GAP-05: No Supplier / Purchasing Domain

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
Zero occurrences of `supplier`, `vendor`, `purchase`, `payable`, `receivable` in any model, database table, or screen. Products enter via manual creation or XLSX workbook import only.

**Current behavior:** No supplier concept exists. Inventory is seeded manually or imported from Excel.

**Business impact:** None for current shop if the owner manually manages stock. Significant gap for any shop that purchases from suppliers regularly.

**Current-shop relevance:** NOT NEEDED NOW — the shop currently uses XLSX import.

**Future-product relevance:** HIGH VALUE — but requires major domain expansion.

**Risk:** VERY HIGH — purchases affect inventory costing, COGS, payables, and require reversal logic.

**Dependencies:** Full domain redesign (suppliers → purchases → inventory receipt → costing → payables → payments → returns/reversals).

**Schema impact:** Multiple new tables.

---

## GAP-06: No Thermal / POS Printing

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
Zero matches for `thermal`, `pos print`, `58mm`, `80mm`, `receipt print`, or `printer config` in the entire `app/lib/` directory.

**Current behavior:** A4 PDF generation via `pdf` and `printing` packages. No thermal printer support.

**Business impact:** Small shops often use 58mm/80mm thermal receipt printers. The current A4-only approach requires paper and a full-size printer.

**Current-shop relevance:** OPTIONAL — if the shop has an A4 printer.

**Future-product relevance:** HIGH VALUE — thermal printing is standard for retail.

**Risk:** MEDIUM — requires physical printer testing and layout design.

**Dependencies:** Invoice data contract (already stable).

**Schema impact:** None.

---

## GAP-07: No VAT / Tax

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
No `tax`, `vat`, or `gst` fields in any model, database table, or UI. All monetary values are plain `REAL` numbers without tax component.

**Current behavior:** Prices are recorded without tax.

**Business impact:** In jurisdictions requiring VAT, the shop cannot produce tax-compliant invoices.

**Current-shop relevance:** OPTIONAL — depends on the shop's tax obligations.

**Future-product relevance:** REQUIRED — tax compliance is mandatory in most markets.

**Risk:** HIGH — tax calculation affects pricing, accounting, and reporting.

**Dependencies:** Schema design, accounting impact analysis.

**Schema impact:** Additive columns on `products`, `sales`, `returns`; new tax configuration.

---

## GAP-08: No Expense Categories

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:**
`Expense` model (`models/expense.dart`): `id`, `date`, `description`, `amount`. No category field.
`expenses` table: `id`, `date`, `description`, `amount`. No category column.
`expenses_screen.dart`: No category picker or filter.

**Current behavior:** All expenses are unstructured free-text descriptions.

**Business impact:** Cannot group or filter expenses by category for reporting.

**Current-shop relevance:** OPTIONAL — depends on owner's reporting needs.

**Future-product relevance:** OPTIONAL — useful but not critical.

**Risk:** LOW — simple additive field.

**Dependencies:** None.

**Schema impact:** Additive nullable `category` column on `expenses`.

---

## GAP-09: No Barcode Scanner Integration

**Status:** MEDIUM CONFIDENCE

**Evidence:**
Barcode is a text field. Products are searched by typing barcode or name. No camera/USB scanner integration found. However, a standard USB barcode scanner that acts as a keyboard wedge would work with the existing text fields without any code changes.

**Current behavior:** Manual text entry for barcodes. USB keyboard-wedge scanners would work implicitly.

**Business impact:** Minimal — keyboard-wedge scanners work today. Camera-based scanning is absent.

**Current-shop relevance:** OPTIONAL.

**Future-product relevance:** OPTIONAL — convenience feature.

**Risk:** LOW.

**Dependencies:** None.

**Schema impact:** None.

---

## GAP-10: No Multi-Currency

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:** All monetary fields are `REAL` without currency标识.

**Current behavior:** Single currency assumed (Egyptian Pound based on UI context).

**Business impact:** None for single-currency shops.

**Current-shop relevance:** NOT NEEDED.

**Future-product relevance:** OPTIONAL.

**Risk:** HIGH — multi-currency affects all monetary calculations.

**Dependencies:** Major accounting redesign.

**Schema impact:** Additive fields across multiple tables.

---

## GAP-11: No Customer Display

**Status:** PROVEN — HIGH CONFIDENCE

**Evidence:** No secondary display, customer-facing screen, or display protocol.

**Current behavior:** Single-screen operation only.

**Business impact:** None — standard for small shops.

**Current-shop relevance:** NOT NEEDED.

**Future-product relevance:** OPTIONAL.

**Risk:** MEDIUM — hardware-dependent.

**Dependencies:** Hardware protocol design.

**Schema impact:** None.

---

## REJECTED FINDINGS

### REJECTED: Negative Stock Protection Defect

**Suspected:** Negative stock may be possible through certain paths.

**Result:** REJECTED

**Reason:** `insertSaleAndDecrementStock` (line 500) enforces `currentQuantity >= sale.quantity` with optimistic lock. `insertReturn` updates `returnedQuantity` and recomputes `currentQuantity`. Return edits check `ReturnStockReversalException` before allowing reversal. Stocktake sets `inventoryAdjustment` to reconcile.

**Evidence:** `database_helper.dart` lines 500-553, 826-858, 866-1003, 1064-1112.

### REJECTED: Missing COGS Tracking

**Suspected:** COGS may not be tracked.

**Result:** REJECTED

**Reason:** `sales.cogs` and `returns.returnedCogs` are stored per-line. Dashboard computes `grossProfit = netSales - netCOGS`. Sales reports show COGS per product and per day.

**Evidence:** `database_helper.dart` lines 819-823, 1116-1139, 1237-1303.

### REJECTED: Missing Accounting Reports

**Suspected:** Reports may be incomplete.

**Result:** REJECTED

**Reason:** Dashboard provides: totalSales, totalReturns, netSales, totalCOGS, totalReturnedCOGS, netCOGS, grossProfit, totalExpenses, netProfit. Sales reports provide daily and product-level grouping with COGS and gross profit. Inventory summary provides item count, total quantity, total value.

**Evidence:** `database_helper.dart` lines 1116-1303, `dashboard_screen.dart`.
