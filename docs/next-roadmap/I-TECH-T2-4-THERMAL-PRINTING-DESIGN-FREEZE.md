# I-TECH T2-4: Thermal Printing Design Freeze

## 1. Executive Decision

**A — DESIGN FREEZE / FOLLOW ROADMAP**

The Thermal Printing design contract is frozen. This document defines the authorized scope for a future implementation step. No production code is modified in this session.

## 2. Governing Context

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` @ `2295137` |
| Previous step | T2-3 (Customer Master Design Freeze) @ `2728419` |
| This step | T2-4: Thermal Printing Design Freeze |
| Step type | Design freeze only — NOT implementation |
| Author | opencode / codex agent |

## 3. Roadmap Evidence

### Exact Roadmap Text

From `I-TECH-NEXT-ROADMAP-FREEZE.md`:

> **GAP-06: No Thermal / POS Printing**
> Confidence: HIGH — PROVEN
> Zero occurrences of `thermal`, `pos print`, `58mm`, `80mm`, `receipt print`, or `printer config` in the codebase. The only printing capability is A4 PDF generation via the `pdf` and `printing` packages.

From `I-TECH-RISK-DEPENDENCY-MAP.md`:

> **T2-4: Thermal Printing Design Freeze (invoice contract stable, medium risk)**

Roadmap dependency graph:

```
Thermal Printing (GAP-06)
    └── Invoice Data Contract (already stable)
        └── Thermal Layout Design
            └── Physical Printer Acceptance
```

### Why T2-4 Is Authorized

- T2-3 (Customer Master Design Freeze) is accepted and closed.
- The roadmap explicitly lists T2-4 as the next step after T2-3.
- T2-4 is a **design freeze only** step — no implementation dependencies.
- The gap (GAP-06) is proven with HIGH confidence.

### Roadmap Alignment Decision

**A — FOLLOW ROADMAP**

No deviation required. The roadmap authorizes T2-4 as a design freeze step with no dependencies.

## 4. Current-State Architecture

### 4.1 Current Print Pipeline

The existing print pipeline is a single path from invoice creation through A4 PDF output:

```
InvoiceScreen (creation)
  → DatabaseHelper.insertInvoiceWithItems() [transactional commit]
  → InvoicePreviewScreen (post-save, gated by canViewSalesHistory)
    → InvoiceRepository.buildDocumentData()
      → getInvoiceById() + getSalesByInvoiceId() [gated reads]
      → ShopProfileRepository.load() [shop branding]
      → AppSettings [supportPhone, invoiceTitle, invoiceFooterText]
    → InvoiceDocumentData (immutable read model)
    → InvoiceDelivery
      → .print()     → Printing.layoutPdf (A4, opens Windows print dialog)
      → .savePdf()   → FilePicker.platform.saveFile
      → .openPdf()   → Printing.sharePdf (default PDF viewer)
```

**Reprint path** (identical data pipeline):

```
SalesScreen → receipt_long icon (if sale.invoiceId != null)
  → InvoicePreviewScreen (same as above)
```

### 4.2 Key Source Files

| File | Path | Role |
|---|---|---|
| `InvoiceDocumentData` | `lib/invoices/invoice_document_data.dart` | Immutable read model for PDF/preview |
| `InvoicePdfRenderer` | `lib/invoices/invoice_pdf_renderer.dart` | A4 Arabic/RTL PDF rendering engine |
| `InvoiceDelivery` | `lib/invoices/invoice_delivery.dart` | Print/save/open delivery layer |
| `InvoiceLogoLoader` | `lib/invoices/invoice_logo_loader.dart` | Safe logo file loading |
| `InvoiceRepository` | `lib/database/invoice_repository.dart` | Read-side data assembly |
| `InvoicePreviewScreen` | `lib/screens/invoices/invoice_preview_screen.dart` | Preview UI with print/save/open actions |
| `InvoiceScreen` | `lib/screens/sales/invoice_screen.dart` | Invoice creation UI |
| `SalesScreen` | `lib/screens/sales/sales_screen.dart` | Sales list with reprint entry point |

### 4.3 Existing Dependencies

| Package | Version | Role in Printing |
|---|---|---|
| `pdf` | `^3.11.1` | PDF document generation (Dart-native, no native code) |
| `printing` | `^5.13.4` | Windows print dialog + PDF rendering via `printing_plugin.dll` |
| `file_picker` | `^8.3.7` | Save PDF file dialog |

### 4.4 Current `InvoiceDocumentData` Contract

```dart
@immutable
class InvoiceDocumentData {
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final ShopProfile shopProfile;     // shopName, ownerOrManagerName, phone, address, logoPath
  final List<InvoiceLineData> lines; // barcode, productName, quantity, unitPrice
  final String supportPhone;
  final String invoiceTitle;
  final String invoiceFooterText;
}
```

### 4.5 Invoice Data Model (Persisted)

```sql
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceNumber TEXT NOT NULL UNIQUE,
  date TEXT NOT NULL,
  customerName TEXT NOT NULL,     -- free-text snapshot
  paymentMethod TEXT NOT NULL,
  totalAmount REAL DEFAULT 0,
  totalItems INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL
)

CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER,              -- nullable FK to invoices
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

### 4.6 Previous Windows Printing History (MUAMAN-18)

A critical historical issue was discovered and fixed during the MUAMAN-17 invoice printing acceptance:

**Root Cause:** Use-after-free in `printing_plugin.dll+0x491B` when `WM_CLOSE` arrived while the Print Setup dialog (`#32770`) was open. The Flutter controller teardown freed the channel messenger while `printPdf` was still running, causing an access violation on the freed messenger vtable.

**Fix location:** `app/windows/runner/flutter_window.cpp:103-128`

**Fix mechanism:** `WM_CLOSE` handler intercepts close, searches for the Print Setup dialog via `EnumWindows` + class `#32770` + process ID, sends `IDCANCEL` to dismiss the modal loop while the messenger is still alive, then re-posts `WM_CLOSE`.

**Verification:** 20/20 stress-test cycles passed (print-dialog-open + close). Multiple negative-control runs passed.

**Residual risk:** The fix relies on the dialog being a standard `#32770` modal owned by the current process. Future printing plugin changes that alter the dialog class could bypass detection.

**Design implication:** Any thermal printing design that uses the same `Printing.layoutPdf` path inherits this WM_CLOSE protection. A design that introduces a NEW native printing plugin would NOT have this protection and would require its own lifecycle hardening.

### 4.7 Existing Settings Architecture

Settings are persisted in `app_settings` (key-value table in SQLite). Current keys:

| Key | Default | Purpose |
|---|---|---|
| `buttonStyle` | `filled` | UI button style |
| `supportPhone` | `+201014900211` | Support phone for invoice footer |
| `defaultCustomerName` | `عميلنقدي` | Pre-filled customer name |
| `licenseKey` | empty | License key |
| `licenseStatus` | `inactive` | License status |
| `workbookPath` | computed | XLSX import path |
| `brandColor` | `#0D47A1` | Configurable brand color |
| `invoiceTitle` | `فاتورةبيع` | Invoice heading |
| `invoiceFooterText` | `شكراًلتعاملكمعنا` | Invoice footer message |
| `backupDirectory` | empty | Backup file directory |

### 4.8 Existing Permissions Model

18 permissions across 7 categories. Print-related permissions:

| Permission | ID | Category |
|---|---|---|
| `canViewSalesHistory` | `sales.history.view` | Sales |

The invoice preview screen is gated at the database layer by `canViewSalesHistory`. Printing is accessed through the preview screen, so printing inherits this gate.

### 4.9 Current Returns Architecture

Returns are standalone records with NO invoice association:

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

- No `invoiceId` column on `returns`
- No print button on the returns screen
- No receipt/PDF output for returns
- No original-invoice reference on returns

### 4.10 Clean Start Behavior

| Table Category | Tables | Behavior |
|---|---|---|
| Wiped | `products`, `sales`, `returns`, `expenses`, `inventory_count`, `invoices`, `import_batches`, `expense_categories` | All rows deleted |
| Preserved | `users`, `role_permissions`, `app_settings` | Preserved across clean start |

Any future thermal printer settings in `app_settings` will be preserved during clean start (same as all other settings).

## 5. Thermal Printing Options Considered

### Model A — PDF-based Narrow Receipt

```
Flutter produces a 58mm/80mm receipt PDF.
Windows print stack sends it to the selected printer.
```

| Criterion | Assessment |
|---|---|
| Arabic support | STRONG — `pdf` package handles RTL via `bidi.logicalToVisual` + text direction. Already proven for A4. |
| RTL correctness | PROVEN — existing A4 renderer demonstrates correct Arabic shaping and ordering. |
| Logos | PROVEN — `InvoiceLogoLoader` safely embeds logos. Same mechanism applies. |
| Configurable header/footer | PROVEN — already in `InvoiceDocumentData`. Same fields. |
| Windows stability | PROVEN — `Printing.layoutPdf` is the existing path. WM_CLOSE fix already protects it. |
| Plugin/native dependency risk | NONE — reuses existing `pdf` + `printing` packages. No new native code. |
| Printer compatibility | GOOD — any Windows printer that accepts PDF output works. Thermal printers exposed as Windows printers work. |
| Testing | GOOD — PDF bytes can be unit-tested. Layout can be verified. |
| Maintainability | GOOD — single rendering pipeline, narrow receipt is a variant of existing A4 renderer. |
| Offline behavior | FULL — PDF generation is purely local. No network dependency. |
| Receipt speed | ADEQUATE — PDF generation is fast. Small receipt = small PDF. |
| Page cutting | PARTIAL — `Printing.layoutPdf` sends a PDF page. Physical cut depends on printer settings. |
| Printer width awareness | LOW — PDF is a fixed page format. Width mapping requires explicit page format definition. |

### Model B — Direct ESC/POS

```
Application generates printer commands directly (ESC/POS protocol).
```

| Criterion | Assessment |
|---|---|
| Arabic support | POOR — ESC/POS Arabic codepages are inconsistent across printer manufacturers. Many printers do not support Arabic natively. |
| RTL correctness | POOR — ESC/POS has no native RTL concept. Requires manual line reversal or preprocessing. |
| Logos | POOR — ESC/POS logo embedding is manufacturer-specific (GS v 0, GS v 1, varying formats). |
| Configurable header/footer | MODERATE — text output is simple, but formatting is limited. |
| Windows stability | UNKNOWN — requires new native plugin for USB/serial communication. New lifecycle risk. |
| Plugin/native dependency risk | HIGH — new native plugin (USB/serial). No existing WM_CLOSE protection. Must re-harden against shutdown UAF. |
| Printer compatibility | LOW — ESC/POS is specific to receipt printers. Different printers have different command sets. |
| Testing | POOR — cannot unit-test printer output without physical hardware. Protocol testing requires mock printer. |
| Maintainability | POOR — manufacturer-specific quirks, codepage tables, command variations. |
| Offline behavior | FULL — direct communication, no network needed. |
| Receipt speed | FAST — minimal overhead, direct stream. |
| Page cutting | GOOD — `GS V m` command for auto-cut. But manufacturer-dependent. |
| Printer width awareness | GOOD — content can be precisely formatted for 58mm/80mm. |

### Model C — Hybrid

```
PDF remains canonical for regular printers.
Thermal printers optionally use a dedicated receipt renderer/path.
```

| Criterion | Assessment |
|---|---|
| Overall | Adds complexity without sufficient justification. Two rendering paths to maintain, two test surfaces, two failure modes. |
| When justified | Only if PDF-based output proves inadequate for thermal printers after physical testing. |

### Decision: Model A — PDF-based Narrow Receipt

**Rationale:**

1. **Zero new dependencies** — reuses existing `pdf` + `printing` packages.
2. **Zero new native risk** — no new plugins, no new WM_CLOSE exposure.
3. **Proven Arabic/RTL** — the `pdf` package's bidi support is already validated in production.
4. **Proven logo embedding** — `InvoiceLogoLoader` already handles safe logo loading.
5. **Proven printer path** — `Printing.layoutPdf` works with any Windows printer, including thermal printers.
6. **Testable** — narrow receipt PDF can be unit-tested like the A4 PDF.
7. **Maintainable** — single rendering codebase, narrow receipt is a layout variant.
8. **WM_CLOSE protection inherited** — the existing `flutter_window.cpp` fix protects the `printing` package path.
9. **Offline-first** — no network, no cloud, no external services.
10. **Sufficient for I-TECH scope** — small retail shop, single Windows machine, known printer.

**If Model A proves inadequate after physical printer testing**, the fallback is to revisit Model B or C in a future roadmap step. The design freeze documents this contingency.

## 6. Receipt Content Contract

### 6.1 What a Thermal Sales Receipt Contains

| # | Field | Source | Required | Notes |
|---|---|---|---|---|
| 1 | Shop name | `InvoiceDocumentData.shopProfile.shopName` | YES | Configurable per shop |
| 2 | Shop logo | `InvoiceDocumentData.shopProfile.logoPath` | OPTIONAL | Loaded via `InvoiceLogoLoader`. Fail-safe: missing logo = no logo on receipt. |
| 3 | Invoice title | `InvoiceDocumentData.invoiceTitle` | YES | Default: `فاتورةبيع` |
| 4 | Invoice number | `InvoiceDocumentData.invoiceNumber` | YES | e.g. `INV-1723912345678` |
| 5 | Invoice date/time | `InvoiceDocumentData.date` | YES | Formatted as `yyyy/MM/dd HH:mm` |
| 6 | Customer name | `InvoiceDocumentData.customerName` | YES | Frozen snapshot from invoice creation |
| 7 | Line items | `InvoiceDocumentData.lines` | YES | Product name, quantity, unit price, line total |
| 8 | Subtotal | `InvoiceDocumentData.totalAmount` | YES | The persisted invoice total |
| 9 | Paid amount | NOT MODELED | NO | Not in current data model — out of scope |
| 10 | Remaining amount | NOT MODELED | NO | Not in current data model — out of scope |
| 11 | Payment method | `InvoiceDocumentData.paymentMethod` | YES | `نقدي` / `فيزا` / `إنستاكاش` |
| 12 | Support phone | `InvoiceDocumentData.supportPhone` | OPTIONAL | From `AppSettings` |
| 13 | Invoice footer | `InvoiceDocumentData.invoiceFooterText` | YES | Default: `شكراًلتعاملكمعنا` |
| 14 | Barcode (per item) | `InvoiceLineData.barcode` | YES | Product barcode |
| 15 | Shop owner/manager | `InvoiceDocumentData.shopProfile.ownerOrManagerName` | OPTIONAL | From shop profile |
| 16 | Shop address | `InvoiceDocumentData.shopProfile.address` | OPTIONAL | From shop profile |

### 6.2 Fields NOT on Receipt (Out of Scope)

| Field | Reason |
|---|---|
| Paid amount | Not modeled in `Invoice` or `InvoiceDocumentData` |
| Remaining/change | Not modeled |
| Discount | Not modeled in current invoice schema |
| Tax/VAT | Not modeled (GAP-07) |
| Return reference | Returns have no invoice association |
| QR code | Not currently present on A4 invoices |
| Barcode (receipt-level) | Not currently present on A4 invoices |

### 6.3 Content Rules

- The receipt renders from the **same `InvoiceDocumentData`** as the A4 PDF.
- No fields are added or removed compared to A4 content (minus layout differences).
- The receipt does NOT independently re-query business data.
- The receipt does NOT recompute accounting totals.
- The receipt consumes the persisted `totalAmount` as-is.

## 7. Data/Snapshot Source

### 7.1 Canonical Data Source Rule

```
Thermal printing consumes InvoiceDocumentData — the same immutable read model
used by A4 PDF and preview. The thermal renderer is a LAYOUT VARIANT of the
existing rendering pipeline, not a separate data pipeline.
```

### 7.2 What Is Historical (Frozen at Invoice Time)

| Field | Source | Frozen? |
|---|---|---|
| Invoice number | `invoices.invoiceNumber` | YES |
| Invoice date | `invoices.date` | YES |
| Customer name | `invoices.customerName` | YES |
| Payment method | `invoices.paymentMethod` | YES |
| Total amount | `invoices.totalAmount` | YES |
| Line items | `sales` rows (via `invoiceId`) | YES |
| Shop profile | `ShopProfileRepository.load()` | **NO — LIVE** |
| Support phone | `AppSettings.getSupportPhone()` | **NO — LIVE** |
| Invoice title | `AppSettings.getInvoiceTitle()` | **NO — LIVE** |
| Invoice footer | `AppSettings.getInvoiceFooterText()` | **NO — LIVE** |

### 7.3 Reprint Snapshot Policy

**Historical transaction fields are frozen. Branding/config fields are live.**

This is the same policy as the existing A4 PDF path:

- When reprinting an old invoice, the invoice number, date, customer, items, and total are the original values.
- The shop name, logo, support phone, invoice title, and footer reflect the **current** configuration.

**Rationale:** A reprint is a convenience action (lost receipt, customer request). It should reflect the current shop identity, not a historical branding snapshot. The financial data (totals, items) is immutable.

## 8. Paper Width Strategy

### 8.1 Supported Widths

| Width | Status | Notes |
|---|---|---|
| 80mm | **PRIMARY — FROZEN FOR T2-4** | Most common thermal receipt width. Usable print width ~72mm after margins. |
| 58mm | FUTURE EXTENSION | Narrower. Requires different column allocation and text wrapping. Not in T2-4 scope. |
| Custom | NOT SUPPORTED | No configurable custom width in T2-4. |

### 8.2 80mm Layout Specification

| Parameter | Value |
|---|---|
| Paper width | 80mm (302.36 points at 96 DPI) |
| Usable print width | ~72mm (272 points) after 4mm margins each side |
| Font sizes | Header: 12pt bold, Meta: 8pt, Items: 7.5pt, Totals: 10pt bold, Footer: 7pt |
| Logo width | Max 40mm (scaled to fit) |
| Column layout | Product name (flex), Qty × Price, Line total |
| Text wrapping | Product names wrap within column width. Long Arabic names handled by `pdf` package word-wrap. |
| Line spacing | Compact — ~2mm between item lines |
| Max items per receipt | Practically unlimited (multi-page if needed, but thermal receipts are typically short) |

### 8.3 Design Rationale for 80mm Only

- 80mm is the standard thermal receipt size in Egyptian retail.
- 58mm introduces column allocation complexity (fewer characters per line, tighter wrapping).
- Starting with 80mm provides immediate value. 58mm can be added later as a configurable option.
- The `pdf` package supports arbitrary page dimensions, so adding 58mm later requires only a new `PdfPageFormat` constant and adjusted column widths.

## 9. Printer Configuration

### 9.1 Proposed Settings

| Key | Type | Default | Validation | UI Location | Runtime Behavior | Fallback |
|---|---|---|---|---|---|---|
| `thermalPrinterName` | String | empty (use system dialog) | Any non-empty string is valid | Settings → Printer section | Stored Windows printer name. If set, thermal print sends directly to this printer. | Falls back to Windows print dialog if printer not found. |
| `thermalPaperWidth` | String | `80` | `58` or `80` | Settings → Printer section | Controls the PDF page width for thermal output. | Default `80` if invalid. |
| `thermalPrintCopies` | String | `1` | `1` to `10` | Settings → Printer section | Number of copies sent per print request. | Default `1` if invalid. |

### 9.2 Settings NOT Proposed (Rejected)

| Setting | Reason Rejected |
|---|---|
| `thermalEnabled` | Thermal printing is an action, not a mode. The user explicitly chooses thermal print. No toggle needed. |
| `thermalAutoCut` | Auto-cut is controlled by the printer hardware, not the application. Adding a software toggle creates false expectations. |
| `thermalPrintLogo` | Logo is always included if available. Removing a configurable logo per-printer is premature complexity. |
| `thermalPrintBarcode` | Barcode is always included per-item (if present in data). No per-printer toggle needed. |

### 9.3 Printer Selection Behavior

| Scenario | Behavior |
|---|---|
| No printer configured (`thermalPrinterName` empty) | Opens Windows print dialog. User selects printer manually. |
| Printer configured but not found | Shows error snackbar: `الطابعة غير موجودة: <name>`. Offer to open Windows print dialog as fallback. |
| Printer configured and found | Sends directly to the named printer without dialog (future optimization). For T2-4, always opens Windows dialog. |
| Printer renamed | Same as "not found" — fallback to dialog. |
| User cancels Windows print dialog | Returns `false` from `Printing.layoutPdf`. No error shown. Sale remains committed. |
| No Windows printers installed | `Printing.layoutPdf` fails. Error snackbar shown. |

### 9.4 Printer Name Portability

**Printer names are machine-specific.** A Windows printer name on one PC may not exist on another.

| Scenario | Behavior |
|---|---|
| Backup/restore to same machine | Printer name preserved and works. |
| Backup/restore to different machine | Printer name preserved in settings but printer not found. Fallback to Windows dialog. |
| Clean start | Printer name preserved (in `app_settings`). |

## 10. Sale Transaction / Printing Boundary

### 10.1 Atomicity Rule

```
Printing must NEVER be part of the financial transaction boundary.
A printer failure must never roll back or corrupt a completed sale.
```

### 10.2 Sequence

```
1. Validate sale (customer name, items, prices, quantities, stock).
2. Commit sale/inventory/accounting transaction (insertInvoiceWithItems).
3. Return invoiceId to the caller.
4. Navigate to InvoicePreviewScreen (or show thermal print option).
5. Build InvoiceDocumentData from persisted invoice (read-only).
6. Attempt print.
7. If print fails → show retry/reprint state. Sale remains committed.
```

### 10.3 Current Behavior Verified

The existing `invoice_screen.dart` already follows this pattern:

```dart
// Line 524-542: Sale is committed FIRST
final savedInvoiceId = await DatabaseHelper.instance
    .insertInvoiceWithItems(invoice, items, currentRole: ...);
// THEN navigates to preview/print
await Navigator.push(context, MaterialPageRoute(
  builder: (_) => InvoicePreviewScreen(invoiceId: savedInvoiceId, ...),
));
```

**No change needed.** Thermal printing is triggered from the preview screen, which is always after the transaction commits.

### 10.4 Forbidden Patterns

| Pattern | Status |
|---|---|
| `printer error → database rollback` | FORBIDDEN — never implemented |
| `printer success → required for sale persistence` | FORBIDDEN — sale commits independently |
| `print before commit` | FORBIDDEN — print always after commit |
| `print as part of transaction` | FORBIDDEN — print is post-transaction |

## 11. Reprint Behavior

### 11.1 Reprint Rules

| Rule | Decision |
|---|---|
| Can historical invoices be reprinted? | YES — via `receipt_long` icon on `SalesScreen` |
| Does reprint read the original frozen invoice snapshot? | YES — `InvoiceRepository.buildDocumentData()` reads from `invoices` + `sales` tables |
| Are current shop settings applied? | YES — shop profile, support phone, invoice title, footer are loaded live |
| Are invoice title/footer historically frozen? | NO — live config is applied on reprint |
| Is thermal reprint the same as A4 reprint? | YES — same `InvoiceDocumentData`, different renderer |

### 11.2 Historical vs Live Fields on Reprint

| Field | Source | Frozen or Live |
|---|---|---|
| Invoice number | `invoices.invoiceNumber` | FROZEN |
| Date | `invoices.date` | FROZEN |
| Customer name | `invoices.customerName` | FROZEN |
| Payment method | `invoices.paymentMethod` | FROZEN |
| Total amount | `invoices.totalAmount` | FROZEN |
| Line items | `sales` rows | FROZEN |
| Shop name | `ShopProfileRepository.load()` | LIVE |
| Logo | `InvoiceLogoLoader.loadBytes(shopProfile.logoPath)` | LIVE |
| Support phone | `AppSettings.getSupportPhone()` | LIVE |
| Invoice title | `AppSettings.getInvoiceTitle()` | LIVE |
| Invoice footer | `AppSettings.getInvoiceFooterText()` | LIVE |

### 11.3 Multiple Copies

Sending multiple copies (e.g. 2 copies per transaction) does NOT duplicate the transaction. Each copy sends the same PDF bytes to the printer. The `thermalPrintCopies` setting controls how many times `Printing.layoutPdf` is called.

## 12. Arabic / RTL Acceptance Requirements

### 12.1 Design Decision

**Arabic correctness is guaranteed by the PDF-based architecture.** The `pdf` package renders Arabic text as a rasterized PDF page with correct bidi support. This is the same mechanism used for A4 invoices and is proven in production.

### 12.2 Acceptance Criteria

| Criterion | Expected Behavior | How Verified |
|---|---|---|
| Arabic shaping | Correct letter forms (initial, medial, final, isolated) | Visual inspection on physical printer |
| RTL ordering | Right-to-left text flow | Visual inspection |
| Mixed Arabic/English | Correct bidirectional text flow | Visual inspection |
| Arabic digits | Arabic-Indic digits render correctly (if used) | Visual inspection |
| Currency | `ج.م` suffix renders correctly | Unit test on PDF bytes |
| Long product names | Text wraps within column width | Unit test + visual inspection |
| Long customer names | Text wraps within meta section | Unit test + visual inspection |
| Totals alignment | Total line aligned right-to-left | Unit test + visual inspection |
| Punctuation | Commas, periods render correctly | Visual inspection |
| Logo placement | Logo centered or right-aligned, scaled to fit | Unit test + visual inspection |
| Font fallback | NotoSansArabic fonts bundled with app | Already in `assets/fonts/` |
| No glyph boxes | No missing-glyph rectangles | Visual inspection |
| No mirrored text | Correct character order | Visual inspection |
| Multi-line wrapping | Long lines wrap to next line | Unit test + visual inspection |

### 12.3 Why NOT ESC/POS for Arabic

ESC/POS text mode relies on the printer's built-in Arabic codepage, which:
- Varies by manufacturer (Epson, Star, Bixolon, etc. each differ)
- Often produces incorrect shaping (missing initial/medial forms)
- Cannot handle mixed Arabic/English bidirectional text
- May not support all Arabic Unicode characters
- Cannot embed custom fonts

The PDF-based approach bypasses all printer-side Arabic limitations by rendering text as rasterized graphics at the application level.

## 13. Logo / Branding Behavior

### 13.1 Branding Sources

| Branding Element | Source | Configurable? |
|---|---|---|
| Shop name | `ShopProfile.shopName` | YES — Settings screen |
| Shop logo | `ShopProfile.logoPath` | YES — Settings screen |
| Shop owner/manager | `ShopProfile.ownerOrManagerName` | YES — Settings screen |
| Shop phone | `ShopProfile.phone` | YES — Settings screen |
| Shop address | `ShopProfile.address` | YES — Settings screen |
| Support phone | `AppSettings.supportPhone` | YES — Settings screen |
| Invoice title | `AppSettings.invoiceTitle` | YES — Settings screen |
| Invoice footer | `AppSettings.invoiceFooterText` | YES — Settings screen |
| Brand color | `AppSettings.brandColor` | YES — Settings screen |

### 13.2 Hardcoded Values — Public vs Per-Shop Identity

| Element | Classification | Source |
|---|---|---|
| `I-TECH` (app product name) | Public app identity | Windows runner identity — NOT on receipt |
| `إدارة محل مؤمن` (app tagline) | Public app identity | Windows runner — NOT on receipt |
| Shop name | Per-shop configurable | `ShopProfile.shopName` — ON receipt |
| Logo | Per-shop configurable | `ShopProfile.logoPath` — ON receipt |
| `فاتورةبيع` | Per-shop configurable | `AppSettings.invoiceTitle` — ON receipt |
| `شكراًلتعاملكمعنا` | Per-shop configurable | `AppSettings.invoiceFooterText` — ON receipt |
| `+201014900211` | Per-shop configurable | `AppSettings.supportPhone` — ON receipt |

### 13.3 Thermal Receipt Must Not Hardcode

The thermal receipt renderer must NOT hardcode:
- Shop names
- Phone numbers
- Invoice titles
- Footer text
- Logo paths
- Brand colors

All must come from `InvoiceDocumentData` and its embedded `ShopProfile`.

## 14. PDF / Preview Coexistence

### 14.1 Coexistence Rule

```
Thermal printing is an ADDITIONAL output path.
The existing A4 PDF path is PRESERVED and UNCHANGED.
```

### 14.2 Output Paths After T2-4 Implementation

| Path | Trigger | Renderer | Format |
|---|---|---|---|
| A4 PDF Print | "طباعة" button on preview | `InvoiceDelivery.print()` → `Printing.layoutPdf` (A4) | A4 PDF |
| A4 PDF Save | "حفظ PDF" button on preview | `InvoiceDelivery.savePdf()` | A4 PDF file |
| A4 PDF Open | "فتح PDF" button on preview | `InvoiceDelivery.openPdf()` | A4 PDF in viewer |
| Thermal Print | NEW "طباعة حرارية" button on preview | NEW `ThermalReceiptRenderer` → `Printing.layoutPdf` (80mm) | 80mm PDF |

### 14.3 No Regression

- A4 print/save/open buttons remain unchanged.
- A4 PDF rendering code remains unchanged.
- A4 test suite remains passing.
- Thermal printing is purely additive.

## 15. Returns Scope

### 15.1 Decision

**T2-4 thermal printing supports SALES ONLY. Returns are OUT OF SCOPE.**

### 15.2 Rationale

| Factor | Assessment |
|---|---|
| Returns have no `invoiceId` | No association to invoices — cannot reference an original transaction |
| Returns have no print button | No existing print path for returns |
| Returns have no receipt/PDF | No existing output format for returns |
| Returns have no customer association | Cannot display customer on return receipt |
| Return receipt UX is undefined | Would require new design decisions (what goes on a return receipt?) |

### 15.3 Future Extension

If return receipts are needed in a future roadmap step:
- Add `invoiceId` to `returns` table (schema change)
- Add return receipt content model
- Add return receipt renderer
- This requires its own design freeze step

## 16. Permissions Impact

### 16.1 Decision

**REUSE EXISTING PERMISSIONS — NO NEW PERMISSION ENUM VALUES**

| Action | Permission | Rationale |
|---|---|---|
| View invoice (prerequisite for print) | `canViewSalesHistory` | Already gates `InvoicePreviewScreen` |
| Print from preview screen | `canViewSalesHistory` | Print is accessed through the preview screen |
| Reprint historical invoice | `canViewSalesHistory` | Reprint is the same preview → print flow |
| Configure thermal printer | `canAccessSettings` | Printer settings are in Settings screen |

### 16.2 Semantic Permission Debt

Using `canViewSalesHistory` for printing is semantically imprecise — viewing and printing are different actions. However:

- Adding a `canPrintInvoices` permission requires modifying `AppPermission` enum
- Adding a new permission requires modifying `role_permissions` table
- Adding a new permission requires UI changes in roles/permissions screen
- **The roadmap does not authorize permission model expansion in T2-4**

**Decision:** Document as `semantic permission debt`. The implementation stage may add print-specific permissions if the roadmap authorizes it in a future step.

## 17. Schema Impact

**Schema impact: NONE**

Printer configuration is stored in `app_settings` (key-value table). No new tables, no new columns, no new indexes.

| Change | Type | Status |
|---|---|---|
| New `app_settings` keys | Additive | Future implementation (NOT in design freeze) |
| New tables | NONE | Not needed |
| New columns | NONE | Not needed |
| Schema version bump | NONE | Not needed |

## 18. Backup / Restore Impact

### 18.1 Printer Settings in Backup

Printer settings (`thermalPrinterName`, `thermalPaperWidth`, `thermalPrintCopies`) will be stored in `app_settings`. Since `app_settings` is part of the full database backup (`VACUUM INTO`), these settings are automatically backed up and restored.

### 18.2 Machine-Specific Printer Name

| Scenario | Behavior |
|---|---|
| Backup + restore to same machine | Printer name works |
| Backup + restore to different machine | Printer name preserved but printer not found → fallback to Windows dialog |
| No printer configured | Windows dialog always opens (portable behavior) |

### 18.3 Design Decision

**Retain printer name but validate/fallback.** Do NOT reset machine-specific printer selection on restore. The printer name is harmless if the printer doesn't exist — the fallback to Windows dialog handles it gracefully.

### 18.4 Backup Service Changes

**NONE.** The backup service uses `VACUUM INTO` (whole database snapshot). Adding settings keys does not affect backup behavior.

### 18.5 Restore Service Changes

**NONE.** The restore service restores the entire database. Settings keys are restored as part of `app_settings`.

## 19. Clean Start Impact

### 19.1 Thermal Printer Settings Classification

| Classification | Rationale |
|---|---|
| **Business configuration** | Printer settings are configuration, not transactional data |

### 19.2 Clean Start Decision

**Thermal printer settings are PRESERVED during clean start.**

This is consistent with the existing behavior: `app_settings` is in the `preservedTables` set. All settings keys (including future thermal printer settings) survive clean start.

**Rationale:** The printer configuration is a machine setup concern, not business data. After clean start, the owner should not need to reconfigure which printer to use.

## 20. Windows Platform Behavior

### 20.1 Printing Integration Model

```
Application (Flutter/Dart)
  → pdf package (generates PDF bytes)
  → printing package (Dart API)
    → printing_plugin.dll (native Windows)
      → Windows GDI / Print Spooler
        → Installed printer (USB / Network / Serial)
```

### 20.2 Printer Exposure Model

| Connection Type | How Exposed | Application Requirement |
|---|---|---|
| USB printer | Windows printer driver installed → appears as Windows printer | Windows printer driver must be installed |
| Network printer | Windows printer sharing → appears as Windows printer | Network connectivity to printer |
| Serial printer | Windows printer driver installed → appears as Windows printer | Serial port driver configured |
| Direct USB (raw) | NOT supported by this architecture | Out of scope |
| Bluetooth | NOT supported by this architecture | Out of scope |

### 20.3 Key Distinction

**A printer installed in Windows and accessible through the Windows print stack is different from direct USB ESC/POS access.**

This design requires the printer to be installed as a Windows printer with a driver. The application does NOT communicate directly with USB/serial hardware. This is a deliberate choice that:
- Avoids native plugin lifecycle risks (no new `*_plugin.dll`)
- Leverages existing Windows print infrastructure
- Is compatible with any printer that has a Windows driver
- Inherits the existing WM_CLOSE protection for the `printing` package

### 20.4 x64 Compatibility

The `printing` package and `printing_plugin.dll` are already built for x64 in the existing application. No new native compilation is needed.

### 20.5 Installer Impact

**NONE.** No new DLLs, no new runtime dependencies. The thermal receipt feature is purely Dart-level code that uses existing packages.

## 21. Dependency Implications

### 21.1 New Dependencies

**NONE.** The thermal receipt renderer uses:
- `pdf` (already in `pubspec.yaml`: `^3.11.1`)
- `printing` (already in `pubspec.yaml`: `^5.13.4`)

### 21.2 Candidate Packages Evaluated and Rejected

| Package | Reason Rejected |
|---|---|
| `esc_pos_printer` | ESC/POS — Arabic issues, new native dependency, lifecycle risk |
| `flutter_pos_printer` | ESC/POS — same issues |
| `thermal_printer` | Manufacturer-specific, limited Arabic support |
| `raw_printer` | Raw USB access — no Windows print stack integration |
| `pdf_render` | PDF viewing, not printing — already have `printing` |

### 21.3 Maintenance Risk

**LOW.** Reusing existing well-maintained packages (`pdf` at 3.x, `printing` at 5.x) with no new dependencies.

## 22. Accounting / Inventory Impact

### 22.1 Governing Rule

```
Thermal printing is a presentation/output concern.
It does not alter financial or inventory truth.
```

### 22.2 Impact Analysis

| Domain | Impact |
|---|---|
| Sales revenue | NONE — renderer consumes persisted totals |
| COGS | NONE — not displayed on receipt |
| Gross profit | NONE — not displayed on receipt |
| Net profit | NONE — not displayed on receipt |
| Inventory | NONE — renderer does not touch stock |
| Expenses | NONE — not displayed on receipt |
| Cash | NONE — no cash tracking on receipt |
| Customer balances | NONE — not modeled |
| Invoice totals | NONE — renderer consumes `totalAmount` as-is |
| Permissions model | NONE — no new permissions |

### 22.3 Thermal Renderer Accounting Boundary

The thermal renderer receives pre-calculated `InvoiceDocumentData` and renders it. It does NOT:
- Recalculate totals
- Verify payment status
- Track revenue
- Modify any database record
- Affect any financial report

## 23. Failure Handling Matrix

| Failure | User-Facing Outcome | Sale Committed? | Retry Possible? | Data Changes? |
|---|---|---|---|---|
| Configured printer missing | Error snackbar: `الطابعة غير موجودة: <name>` + offer Windows dialog | YES | YES — retry from preview | NO |
| Printer offline | Windows print error shown. Error snackbar. | YES | YES — retry from preview | NO |
| Paper out | Printer hardware error (not app-controlled). Snackbar shown. | YES | YES — retry after paper loaded | NO |
| Windows spooler error | Error snackbar with details. | YES | YES — retry from preview | NO |
| Printer renamed | Same as "printer missing" — fallback to dialog or error | YES | YES | NO |
| Unsupported paper width | Print may succeed with incorrect layout, or printer rejects. Error from Windows. | YES | YES — change setting and retry | NO |
| Receipt generation failure | Error snackbar. PDF bytes could not be built. | YES | YES — retry from preview | NO |
| Logo decoding failure | Receipt prints without logo (fail-safe from `InvoiceLogoLoader`). | YES | N/A — logo is optional | NO |
| Arabic/font failure | Should not occur (fonts bundled). If it does, error snackbar. | YES | YES — retry | NO |
| User cancels Windows print dialog | No error shown. Silent return. | YES | YES — tap print again | NO |
| Print succeeds but app cannot confirm physical output | Snackbar: `تم إرسال الفاتورة إلى الطابعة`. No confirmation of physical output. | YES | YES — reprint available | NO |
| Duplicate print request | Each request sends a separate print job. No deduplication. | YES | YES | NO |
| App closes immediately after print request | WM_CLOSE fix dismisses dialog safely. Sale was already committed. | YES | YES — reprint from sales list | NO |
| printing_plugin.dll crash (UAF) | PREVENTED by WM_CLOSE fix in `flutter_window.cpp`. 20/20 stress cycles passed. | YES | YES | NO |

## 24. Testing Strategy

### 24.1 Unit Tests

| Test | What It Verifies |
|---|---|
| Thermal receipt PDF generation | `ThermalReceiptRenderer.buildDocument()` produces valid PDF bytes |
| 80mm page dimensions | PDF page format matches 80mm width specification |
| Arabic text rendering | RTL text is correctly ordered in the PDF |
| Line item wrapping | Long product names wrap within column width |
| Missing logo handling | Receipt generates without logo when logo file is missing |
| Empty fields handling | Receipt handles empty support phone, footer, etc. |
| Money formatting | `formatMoney()` produces correct output on receipt |
| Payment method labels | Arabic labels render correctly |
| Multiple items | Receipt handles 1, 5, 20+ items correctly |

### 24.2 Widget/Integration Tests

| Test | What It Verifies |
|---|---|
| Thermal print button appears on preview screen | UI integration |
| Print action triggers thermal renderer | End-to-end flow |
| Fallback to Windows dialog when printer not configured | Error handling |

### 24.3 Manual / Hardware Tests (Windows)

| Test | What It Verifies |
|---|---|
| Physical 80mm receipt print | Layout, margins, text clarity |
| Arabic text on physical printer | Shaping, ordering, readability |
| Logo print quality | Resolution, sizing, placement |
| Multiple copies | Correct number of copies printed |
| Reprint from sales history | Historical invoice prints correctly |
| WM_CLOSE during thermal print | No crash (stress test) |

### 24.4 Negative Tests

| Test | What It Verifies |
|---|---|
| Print with no printer installed | Graceful error handling |
| Print with printer offline | Graceful error handling |
| Print with paper out | Graceful error handling |
| Rapid repeated print requests | No duplicate transactions, no crash |
| App close during print dialog | WM_CLOSE fix works for thermal path too |

## 25. Explicit Non-Goals

The following are **explicitly OUT OF SCOPE** for T2-4 and its implementation follow-up:

| Non-Goal | Reason |
|---|---|
| Direct raw USB protocol implementation | Requires native plugin, new lifecycle risk |
| Bluetooth printing | Not supported by Windows print stack model |
| Android printing | Out of scope (Windows only) |
| Cloud printing | Out of scope (offline-first) |
| Supabase printing | Out of scope (no cloud) |
| Remote print server | Out of scope |
| Printer fleet management | Not needed for single-store |
| Cash drawer control | Separate hardware, separate domain |
| Customer display hardware | Separate hardware, separate domain |
| Kitchen printing | Not in current business model |
| Label printing | Not in current business model |
| Barcode label printers | Not in current business model |
| Receipt audit log | Not required by roadmap |
| Print queue persistence | Not required |
| Automatic retry daemon | Not required |
| New permission enum values | Semantic debt — documented, not expanded |
| Accounting changes | Presentation-only concern |
| Customer receivables | Not in scope |
| Schema changes | Settings in `app_settings` — no schema needed |
| Installer changes | No new DLLs or runtime dependencies |
| 58mm paper support | Future extension — T2-4 freezes 80mm only |
| Auto-cut control | Printer hardware setting, not application |
| Receipt template customization | Not needed yet |
| Multi-receipt template system | Overdesign for current scope |
| Receipt preview before print | Thermal receipts are small; physical print is the verification |
| Print history tracking | Not required by roadmap |
| Print count tracking | Not required by roadmap |
| Receipt numbering system | Invoice numbers already serve this purpose |
| Thermal-specific fonts | NotoSansArabic already bundled; sufficient for thermal |
| Custom paper sizes | 80mm frozen; custom sizes are future extension |

## 26. Migration / Implementation Sequence

The following is the frozen implementation contract for the step that follows this design freeze.

### 26.1 Implementation MAY:

- Create `lib/invoices/thermal_receipt_renderer.dart` — narrow receipt PDF renderer
- Create `lib/invoices/thermal_receipt_config.dart` — page dimensions and layout constants
- Add thermal print button to `InvoicePreviewScreen`
- Add thermal printer settings to `SettingsScreen`
- Add `thermalPrinterName`, `thermalPaperWidth`, `thermalPrintCopies` keys to `AppSettings`
- Add unit tests for thermal receipt PDF generation
- Reuse `InvoiceDocumentData`, `InvoiceLogoLoader`, `InvoiceRepository`

### 26.2 Implementation MUST:

- Consume `InvoiceDocumentData` — the same read model as A4 PDF
- Use `PdfPageFormat` with 80mm width (custom `PdfPageFormat`)
- Use the same NotoSansArabic fonts already bundled
- Use the same `InvoiceLogoLoader` for logo embedding
- Use `Printing.layoutPdf` for the print path (inheriting WM_CLOSE protection)
- Gate thermal print access behind `canViewSalesHistory`
- Preserve the existing A4 print/save/open buttons unchanged
- Handle printer-missing errors gracefully
- Handle user-canceled print dialog gracefully
- Not modify any existing production file beyond adding the thermal print trigger
- Not modify `InvoiceDocumentData` or `InvoicePdfRenderer`
- Not modify `InvoiceDelivery`
- Not modify the database schema
- Not modify `pubspec.yaml` dependencies
- Not modify platform files
- Not modify `flutter_window.cpp`

### 26.3 Implementation MUST NOT:

- Add new dependencies to `pubspec.yaml`
- Add new native plugins
- Modify the database schema
- Modify the A4 PDF renderer
- Modify the existing print/save/open buttons
- Add new permission enum values
- Modify `AppPermission` enum
- Modify `UserRole` enum
- Add ESC/POS commands
- Add USB/serial communication
- Add printer discovery
- Add auto-print
- Add cash drawer control
- Add barcode/QR generation (unless already present)
- Modify `InvoiceScreen` creation flow
- Modify the sale transaction boundary
- Modify backup/restore services
- Modify clean-start behavior
- Modify `flutter_window.cpp`
- Modify any platform files

## 27. Risks

### 27.1 Risk Register

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| 80mm layout doesn't fit receipt content | MEDIUM | LOW | Unit test PDF dimensions. Visual verification on physical printer. |
| Arabic text wraps incorrectly on narrow paper | MEDIUM | LOW | `pdf` package word-wrap handles this. Visual verification. |
| Logo too large for receipt width | LOW | LOW | `InvoiceLogoLoader` already caps at 4MB. Scale to fit in renderer. |
| Printer doesn't accept PDF format | LOW | LOW | Most modern thermal printers with Windows drivers accept PDF. Fallback: user saves PDF and prints manually. |
| Thermal printer speed too slow | LOW | LOW | PDF generation is fast. Print speed is hardware-limited. |
| WM_CLOSE issue resurfaces for thermal path | LOW | LOW | Same `Printing.layoutPdf` path. Same fix applies. |
| 58mm demand before it's implemented | LOW | MEDIUM | Documented as future extension. 80mm is primary. |
| Settings UI becomes cluttered | LOW | LOW | Minimal 3 settings. Organized in a dedicated "Printer" section. |

### 27.2 Preserved Risks from Roadmap

| Risk | Status |
|---|---|
| Cloud/Supabase | OUT OF SCOPE — no change |
| Android | OUT OF SCOPE — no change |
| Sync/offline | OUT OF SCOPE — no change |
| Accounting boundary | PROTECTED — thermal printing is presentation-only |
| Inventory boundary | PROTECTED — thermal printing does not touch stock |
| Backup/Restore | PRESERVED — settings backup/restore is automatic via `app_settings` |
| Licensing | PRESERVED — no change |
| Windows delivery | PRESERVED — no new DLLs or installer changes |
| UI/UX | NEUTRAL — thermal printing is additive |
| Native printing/plugin stability | PRESERVED — same `printing_plugin.dll`, same WM_CLOSE fix |

## 28. Compatibility Matrix

| Scenario | Behavior | Risk |
|---|---|---|
| Thermal print on machine with no thermal printer | Windows dialog shows all printers. User selects or cancels. | LOW |
| Thermal print on machine with thermal printer configured | Works as designed. | NONE |
| Thermal print after backup/restore to different machine | Printer name not found → fallback to dialog. | LOW |
| Thermal print after clean start | Settings preserved. Printer still configured. | NONE |
| Thermal print with old invoices (pre-thermal) | Same `InvoiceDocumentData` pipeline. Works identically. | NONE |
| Thermal print with Customer Master (T2-3) invoices | `InvoiceDocumentData` receives snapshot `customerName`. Works identically. | NONE |
| Thermal print alongside A4 print | Both paths available. No conflict. | NONE |
| App version upgrade (pre-thermal → post-thermal) | Settings keys added with defaults. No migration needed. | NONE |

## 29. Final Frozen Decisions

| # | Decision | Value |
|---|---|---|
| 1 | Architecture | **Model A — PDF-based narrow receipt** |
| 2 | Paper width | **80mm only** (58mm is future extension) |
| 3 | Data source | **`InvoiceDocumentData`** — same as A4 PDF |
| 4 | Reprint source | **Same `InvoiceDocumentData`** — transaction fields frozen, branding fields live |
| 5 | Sale boundary | **Print is post-transaction** — never part of financial commit |
| 6 | Permissions | **Reuse `canViewSalesHistory`** — no new permission enum |
| 7 | Schema impact | **NONE** — settings in `app_settings` |
| 8 | Dependencies | **NONE** — reuse existing `pdf` + `printing` |
| 9 | Printer selection | **Windows print dialog** (configurable default printer is future) |
| 10 | Returns | **OUT OF SCOPE** — sales only |
| 11 | Arabic/RTL | **PDF-based rendering** — same proven mechanism as A4 |
| 12 | Logo | **Included if available** — same fail-safe as A4 |
| 13 | PDF coexistence | **A4 path preserved unchanged** |
| 14 | Backup/restore | **Settings preserved automatically** — printer name portable with fallback |
| 15 | Clean start | **Printer settings preserved** — machine config, not business data |
| 16 | Windows native | **No new native code** — no new plugins, no new DLLs |
| 17 | WM_CLOSE | **Existing fix applies** — same `Printing.layoutPdf` path |
| 18 | Offline | **Fully offline** — no cloud, no network required |
| 19 | Non-goals | **USB/BT/cloud/ESC-POS/cash-drawer/kitchen/label** — all excluded |
| 20 | Auto-print | **NOT in T2-4** — user explicitly triggers print |

## 30. Next Authorized Roadmap Step

Per `I-TECH-RISK-DEPENDENCY-MAP.md`:

> **T2-4: Thermal Printing Design Freeze (invoice contract stable, medium risk)**

After T2-4 is accepted, the next authorized step is:

**T2-4 Implementation: Thermal Printing Implementation**

This is the implementation phase that follows this design freeze. It should be authorized as a separate step after this design freeze is accepted.

The roadmap's recommended sequence after T2-4:

```
1. T1-1: Brand Color Consumption ✓ (accepted)
2. T2-1: Standalone Backup ✓ (accepted)
3. T2-2: Expense Categories ✓ (accepted)
4. T2-3: Customer Master Design Freeze ✓ (accepted)
5. T2-4: Thermal Printing Design Freeze ← THIS STEP
6. T2-4 Implementation: Thermal Printing ← NEXT AUTHORIZED STEP
7. Further items require separate authorization
```

---

## Continuity Clause

| Item | Value |
|---|---|
| Project | I-TECH / إدارة محل مؤمن |
| Platform | Flutter/Dart Windows Desktop |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Baseline | `2728419` (T2-3 Customer Master Design Freeze) |
| Final HEAD | `2728419` (no production changes) |
| Schema version | 7 (unchanged) |
| Design freeze output | `docs/next-roadmap/I-TECH-T2-4-THERMAL-PRINTING-DESIGN-FREEZE.md` |
| Production code changed | NO |
| Tests run | Pending validation |
| Working tree | 7 generated platform files (CRLF noise — pre-existing) |
| Merge commits | 0 |
| Push | NOT PERFORMED |
| Tag | NOT PERFORMED |
| Next authorized step | T2-4 Implementation: Thermal Printing |
