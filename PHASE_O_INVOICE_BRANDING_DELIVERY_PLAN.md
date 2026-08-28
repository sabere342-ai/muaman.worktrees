# PHASE O — INVOICE BRANDING & DELIVERY PLAN

**Date:** 2026-08-28
**Baseline:** `c4ffe8a890cf049a2dfca089e944d1db3ff058e6` on `codex/i-tech-next-roadmap-freeze`
**Governance:** `POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md` → `OUTCOME_A_RESUME_MASTER_ROADMAP_AT_PHASE_O`

---

## A. Phase Identity

| Field | Value |
|-------|-------|
| PHASE | O |
| TITLE | Invoice Branding & Delivery |
| ROADMAP_SOURCE | PROJECT_MASTER_PLAN.md §13, PRODUCTIZATION_ARCHITECTURE_PLAN.md §15 |
| GOVERNING_BASELINE | POST_GATE_12_GOVERNANCE_COMMIT = c4ffe8a890cf049a2dfca089e944d1db3ff058e6 |
| PREDECESSOR | Phase G (Cloud Data Foundation) — complete and locked |
| SUCCESSOR | Phase P (Production Hardening) — final phase |

---

## B. Objective

Phase O finalizes the customer-facing invoice presentation by:

1. **Adding the mandatory I Tech attribution footer** — a "Powered by I Tech للتكنولوجيا" line independent from the shop's own footer text, as required by Owner Decision D5 and PRE_A §6 OD5.
2. **Ensuring cross-platform delivery parity** — verifying and hardening the Windows native save/print and Android system share/print service paths for both A4 PDF and 80mm thermal receipt.
3. **Surfacing the I Tech branding slot in Settings** — so the owner can see/configure the attribution text (bound by OD5 exact wording).
4. **Preserving all existing invoice functionality** — atomic sales, PDF generation, thermal receipt, preview screen, permission gating, and data integrity invariants.

Phase O does NOT introduce cloud invoicing, multi-device sync, or licensing changes. Those belong to Phases G, H, and E respectively.

---

## C. Entry Preconditions

| Precondition | Status | Evidence |
|--------------|--------|----------|
| GATE_12 = PASS | ✅ | `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` |
| ROADMAP_DECISION = OUTCOME_A_RESUME_MASTER_ROADMAP_AT_PHASE_O | ✅ | `POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md` |
| POST_GATE_12_GOVERNANCE_REMOTE_LOCK = COMPLETE | ✅ | Tag `post-gate-12-roadmap-governance-determination-locked` peeled to `c4ffe8a...` |
| Phase G implementation complete & locked | ✅ | Tag `phase-g-implementation-locked` at `24efd2a4db01fd0fea843f98999153cdb983cf70` (ancestor of HEAD) |
| Phase N implementation complete & locked | ✅ | Tag `phase-n-implementation-locked` at `1d4620112217ff6c3d3f0bfb35d59473d842294e` (ancestor of HEAD) |
| Repository pristine (AHEAD=0, BEHIND=0, clean worktree) | ✅ | Verified at session start |

---

## D. Current-State Evidence

### D.1 Invoice PDF Rendering (`app/lib/invoices/invoice_pdf_renderer.dart`)
- A4 Arabic/RTL PDF using `pdf` package with NotoSansArabic fonts
- Header: shop name, owner/manager name, phone, address, logo (if set)
- Items table with pagination (chunked rows per page)
- Totals row
- Footer: support phone (from `AppSettings.supportPhone`) + `invoiceFooterText` (from `AppSettings.invoiceFooterText`, default "شكراً لتعاملكم معنا")
- No I Tech attribution line currently

### D.2 Thermal Receipt (`app/lib/invoices/thermal_receipt_renderer.dart` + `thermal_delivery.dart`)
- 80mm receipt format
- Uses same `InvoiceDocumentData` read model
- Footer includes support phone + `invoiceFooterText`
- No I Tech attribution line currently

### D.3 Invoice Read Model (`app/lib/invoices/invoice_document_data.dart`)
```dart
class InvoiceDocumentData {
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final ShopProfile shopProfile;
  final List<InvoiceLineData> lines;
  final String supportPhone;        // from AppSettings
  final String invoiceTitle;        // from AppSettings, default "فاتورة بيع"
  final String invoiceFooterText;   // from AppSettings, default "شكراً لتعاملكم معنا"
}
```

### D.4 Shop Profile (`app/lib/models/shop_profile.dart` + service/repository)
- Fields: `shopName`, `ownerOrManagerName`, `phone`, `address`, `logoPath`, `cloudUuid`
- Persisted in `app_settings` table (additive keys, no schema change)
- Loaded via `ShopProfileService` (ChangeNotifier singleton)

### D.5 Delivery (`app/lib/invoices/invoice_delivery.dart`)
- `PdfDeliveryMode.nativeSaveDialog` (Windows) → `FilePicker.saveFile` + write bytes
- `PdfDeliveryMode.systemShare` (Android) → `Printing.sharePdf`
- `ThermalDelivery.print()` → `Printing.layoutPdf` with thermal page format

### D.6 Settings (`app/lib/services/app_settings.dart`)
- `keyInvoiceTitle` → default "فاتورة بيع"
- `keyInvoiceFooterText` → default "شكراً لتعاملكم معنا"
- `keySupportPhone` → default "+201014900211"

### D.7 Preview Screen (`app/lib/screens/invoices/invoice_preview_screen.dart`)
- Read-only preview with actions: Print A4, Print Thermal, Save PDF, Open PDF
- All reads gated by `AppPermission.canViewSalesHistory` at database layer

### D.8 Invoice Creation (`app/lib/screens/sales/invoice_screen.dart`)
- Creates `Invoice` + `Sale` items in single transaction via `DatabaseHelper.insertInvoiceWithItems`
- Navigates to `InvoicePreviewScreen` on success (if permission allows)

### D.9 Database Schema (`app/lib/database/database_helper.dart`)
```sql
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceNumber TEXT NOT NULL UNIQUE,
  date TEXT NOT NULL,
  customerName TEXT NOT NULL,
  paymentMethod TEXT NOT NULL,
  totalAmount REAL DEFAULT 0,
  totalItems INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL,
  shop_id TEXT,
  cloud_uuid TEXT,
  customerId INTEGER
)
```

---

## E. Gap Analysis

| Requirement (from PRODUCTIZATION_ARCHITECTURE_PLAN §15) | Current State | Target State | Gap | Evidence |
|--------------------------------------------------------|---------------|--------------|-----|----------|
| I Tech attribution footer ("Powered by I Tech للتكنولوجيا") | **NOT_IMPLEMENTED** | Rendered as second footer line, independent from shop footer | Missing footer line in PDF renderer (both A4 and thermal) | `invoice_pdf_renderer.dart:_footer()` only renders `supportPhone` + `invoiceFooterText` |
| I Tech attribution slot in Settings | **NOT_IMPLEMENTED** | Visible in Settings, read-only or configurable per OD5 | No UI for I Tech attribution; only shop footer text exists | `app_settings.dart` has `invoiceFooterText` but no `itechAttributionText` |
| Cross-platform A4 delivery | **IMPLEMENTED_AND_REUSABLE** | Windows native save dialog + Android system share | Already works; needs verification on Android | `InvoiceDelivery.savePdf()` uses `PlatformCapabilities.isAndroid` |
| Cross-platform thermal delivery | **IMPLEMENTED_AND_REUSABLE** | Windows print dialog + Android print service | Already works via `Printing.layoutPdf` | `ThermalDelivery.print()` |
| Shop branding in header (name, owner, phone, address, logo) | **IMPLEMENTED_AND_REUSABLE** | Preserved | None | `invoice_pdf_renderer.dart:_header()` |
| Invoice title configurable | **IMPLEMENTED_AND_REUSABLE** | Preserved | None | `AppSettings.getInvoiceTitle()` |
| Shop footer text configurable | **IMPLEMENTED_AND_REUSABLE** | Preserved | None | `AppSettings.getInvoiceFooterText()` |
| Support phone in footer | **IMPLEMENTED_AND_REUSABLE** | Preserved | None | `AppSettings.getSupportPhone()` |
| OD1 (product marketing name) | **OPEN** | Planning input only | Surfaced as blocker for Android package ID | `PROJECT_MASTER_PLAN.md` §6 |
| OD5 (I Tech invoice footer exact text) | **OPEN** | Must be resolved before implementation commit | Planning documents the boundary; implementation waits for owner | `PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md` §6 |

---

## F. In-Scope Work

| ID | Work Item | Description |
|----|-----------|-------------|
| O-01 | Add I Tech attribution field to `InvoiceDocumentData` | New field `itechAttributionText` with default "Powered by I Tech للتكنولوجيا" |
| O-02 | Extend `AppSettings` with `keyItechAttributionText` | Persist the attribution text; default per OD5 (owner-decided exact wording) |
| O-03 | Update A4 PDF renderer footer | Render two-line footer: (1) shop footer text, (2) I Tech attribution |
| O-04 | Update thermal receipt renderer footer | Same two-line footer for thermal receipt |
| O-05 | Add I Tech attribution to Settings screen | Read-only display (or editable if OD5 permits) in Shop/Branding settings section |
| O-06 | Update `InvoiceRepository.buildDocumentData` | Load new `itechAttributionText` from `AppSettings` and pass to `InvoiceDocumentData` |
| O-07 | Verify cross-platform delivery on Android | Manual verification: A4 share, thermal print service, PDF open |
| O-08 | Verify cross-platform delivery on Windows | Manual verification: A4 save/print, thermal print, PDF open |
| O-09 | Add unit tests for I Tech attribution rendering | Test `_footer()` widget produces both lines; test thermal footer |
| O-10 | Add widget test for Settings I Tech attribution display | Verify Settings shows the attribution text |
| O-11 | Regression test: existing invoice flows unchanged | All existing invoice tests pass; `flutter analyze` 0 errors/warnings |

---

## G. Explicitly Out of Scope

| Item | Reason |
|------|--------|
| Cloud invoices / multi-device sync | Phase G/H scope |
| Licensing / trial integration | Phase E scope |
| Android app creation / onboarding | Phase K scope |
| Camera barcode scanning | Future feature |
| Play Store publishing | Phase P+ scope |
| VAT/tax expansion | Not in current productization |
| Supplier/purchase domain | Not in current productization |
| Accounting redesign | Not in current productization |
| Sync runtime activation (DR-M09) | Explicitly gated post-Phase L |
| Schema migrations for invoices | No schema change needed (uses existing `app_settings`) |
| Invoice numbering scheme change | Preserved as-is (`INV-${timestamp}`) |
| Thermal paper width / copies settings | Already implemented, preserved |

---

## H. Expected File / Component Touch Set

| File | Change Type | Rationale |
|------|-------------|-----------|
| `app/lib/invoices/invoice_document_data.dart` | Modify | Add `itechAttributionText` field |
| `app/lib/services/app_settings.dart` | Modify | Add `keyItechAttributionText`, default, getter |
| `app/lib/invoices/invoice_pdf_renderer.dart` | Modify | Update `_footer()` to render two lines |
| `app/lib/invoices/thermal_receipt_renderer.dart` | Modify | Update thermal footer to render two lines |
| `app/lib/database/invoice_repository.dart` | Modify | Load new setting in `buildDocumentData` |
| `app/lib/screens/settings/settings_screen.dart` | Modify | Add I Tech attribution display in branding section |
| `app/test/unit/invoice_pdf_renderer_test.dart` | New | Unit tests for footer rendering |
| `app/test/widget/settings_branding_test.dart` | New | Widget test for Settings attribution display |

---

## I. Data Model / Migration Plan

**No database schema migration required.**

All Phase O data is stored in the existing `app_settings` key-value table (additive only):

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `itechAttributionText` | TEXT | `"Powered by I Tech للتكنولوجيا"` | Owner Decision OD5 controls exact wording |

**Migration Properties:**
- Additive only (new key in existing table)
- No data rewrite
- Backward compatible: missing key falls back to default
- Zero downtime
- Rollback: delete the key (reverts to default)

---

## J. Runtime Integration Plan

No new services, no startup wiring changes, no dependency construction changes.

The I Tech attribution text flows through existing read model:

```
AppSettings.getItechAttributionText()
    → InvoiceRepository.buildDocumentData()
        → InvoiceDocumentData.itechAttributionText
            → InvoicePdfRenderer._footer() (A4)
            → ThermalReceiptRenderer._footer() (thermal)
```

**Offline behavior:** Unchanged — all data is local.
**Sync behavior:** Unchanged — `app_settings` sync handled by Phase H (shop-scoped).
**Failure behavior:** Unchanged — missing key falls back to default constant.

---

## K. Security / Authorization

No new permissions, no RBAC changes.

Existing authorization preserved:
- Invoice creation: `AppPermission.canCreateSales`
- Invoice preview/print: `AppPermission.canViewSalesHistory`
- Settings (shop branding): `AppPermission.canAccessSettings`
- Shop profile edit: `AppPermission.canAccessSettings`

The I Tech attribution is **read-only for non-owners** (displayed on invoice) and **owner-configurable in Settings** (if OD5 permits editing). The default is enforced by code.

---

## L. Testing Plan

| Category | Test Files | Requirements |
|----------|------------|--------------|
| Unit: PDF footer rendering | `app/test/unit/invoice_pdf_renderer_test.dart` (new) | `_footer()` produces two `pw.Text` widgets: shop footer + I Tech attribution |
| Unit: Thermal footer rendering | `app/test/unit/thermal_receipt_renderer_test.dart` (new or extend) | Thermal footer produces two lines |
| Unit: AppSettings getter | `app/test/unit/app_settings_test.dart` (extend) | `getItechAttributionText()` returns default when unset; returns stored value when set |
| Widget: Settings branding | `app/test/widget/settings_branding_test.dart` (new) | Settings screen shows I Tech attribution text in branding section |
| Integration: Invoice preview | `app/test/integration/invoice_preview_test.dart` (new or extend) | Preview screen shows both footer lines |
| Regression: Full suite | `flutter test` | All existing tests pass; no new failures |
| Static analysis | `flutter analyze` | 0 errors, 0 warnings (info count ≤ 62 baseline) |

**Manual Verification Matrix:**

| Platform | A4 Print | A4 Save PDF | A4 Share | Thermal Print | PDF Open |
|----------|----------|-------------|----------|---------------|----------|
| Windows | ✅ Required | ✅ Required | N/A | ✅ Required | ✅ Required |
| Android | N/A | N/A | ✅ Required (real device) | ✅ Required (real device) | ✅ Required (real device) |

**Device Requirements:**
- Windows: Automated + manual (developer machine)
- Android: **REAL_DEVICE_REQUIRED** for share/print service verification (emulator lacks system share sheet fidelity)

---

## M. Static Analysis / Formatting

Mandatory commands for implementation closure:

```powershell
# From app/ directory
flutter analyze              # 0 errors, 0 warnings (info ≤ 62)
flutter test                 # All tests green
dart format --set-exit-if-changed .  # Clean formatting
git diff --check             # No conflict markers
```

---

## N. Manual Verification

| Verification | Type | Requirement |
|--------------|------|-------------|
| Windows A4 invoice print | AUTOMATED_REQUIREMENT | Print dialog opens, PDF renders correctly |
| Windows A4 invoice save | AUTOMATED_REQUIREMENT | Save dialog writes valid PDF |
| Windows thermal print | AUTOMATED_REQUIREMENT | Print dialog opens, 80mm format correct |
| Android A4 share | REAL_DEVICE_REQUIRED | System share sheet appears, PDF shared |
| Android thermal print | REAL_DEVICE_REQUIRED | Print service receives 80mm PDF |
| Android PDF open | REAL_DEVICE_REQUIRED | Default viewer opens PDF |
| Footer text: shop + I Tech | AUTOMATED_REQUIREMENT | Both lines visible in all formats |
| Settings shows I Tech attribution | AUTOMATED_REQUIREMENT | Branding section displays attribution |

---

## O. Implementation Commit Discipline

Expected implementation commit boundaries (for future implementation session):

1. **Core model + settings** — `invoice_document_data.dart`, `app_settings.dart`, `invoice_repository.dart`
2. **PDF renderer footer** — `invoice_pdf_renderer.dart`, `thermal_receipt_renderer.dart`
3. **Settings UI** — `settings_screen.dart` branding section
4. **Tests** — all new unit/widget tests
5. **Verification evidence** — manual test records (separate commit or appended)

Each commit: `flutter analyze` + `flutter test` green, `git diff --check` clean.

---

## P. Remote Lock Discipline

Explicitly stated:

**`PHASE_O_PLANNING_REMOTE_LOCK`** will be performed in a separate authorized session after this planning commit.

No tags, no pushes, no remote mutations in this session.

---

## Q. Implementation Completion Criteria (PASS Conditions)

Phase O implementation session succeeds iff:

| Criterion | Verification |
|-----------|--------------|
| `flutter analyze` | 0 errors, 0 warnings (info ≤ 62) |
| `flutter test` | All tests pass (including new O-* tests) |
| `git diff --check` | Clean |
| A4 PDF footer | Two lines: shop footer + "Powered by I Tech للتكنولوجيا" |
| Thermal receipt footer | Two lines: shop footer + "Powered by I Tech للتكنولوجيا" |
| Settings branding | I Tech attribution visible in Shop/Branding section |
| Cross-platform delivery | Windows + Android manual verification recorded |
| Sacred artifacts | Untouched (untracked, byte-identical) |
| No scope creep | Only files in §H touched; no cloud/migration/Android app changes |

---

## R. Blockers / Open Questions

| ID | Item | Impact | Resolution Path |
|----|------|--------|-----------------|
| OD5 | I Tech invoice footer exact text | Blocks implementation commit (not planning) | Owner must provide exact Arabic wording before implementation session |
| OD1 | Final product marketing name | Blocks Android package ID (Phase K) | Planning documents as input; does not block Phase O |
| Android real device | Manual verification | Required for Android delivery verification | Must be available for implementation session; if not, Android verification is CONDITIONAL |
| Thermal receipt footer space | 80mm width constraint | Two-line footer may need smaller font or truncation | Test on real 80mm printer; adjust font size if needed |

---

## Appendix: Authoritative Roadmap Evidence

### PROJECT_MASTER_PLAN.md §13
```
| O | Invoice Branding & Delivery | Dynamic shop profile, I Tech footer, cross-platform |
```
Dependency chain: `O (after G)`

### PRODUCTIZATION_ARCHITECTURE_PLAN.md §15
```
Target State (Phase O):
Invoice Layout:
┌─────────────────────────────┐
│ SHOP NAME (dynamic)         │
│ Owner/Manager Name          │
│ Phone | Address             │
│ Logo (if set)               │
├─────────────────────────────┤
│ Invoice lines               │
├─────────────────────────────┤
│ Totals                      │
├─────────────────────────────┤
│ "شكراً لتعاملكم معنا"       │
│ Powered by I Tech للتكنولوجيا│
└─────────────────────────────┘

Platform Delivery:
| Platform | Delivery Method |
|----------|----------------|
| Windows  | Print dialog + PDF save (current) |
| Android  | Share intent + PDF save + print service |
```

### PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md §6 (OD5)
| OD5 | Invoice footer exact text | Invoice template | OPEN |
**OD5 Note:** Pre-A defines the architectural slot for I Tech invoice attribution (Phase O). The exact footer text is controlled by OD5 and is NOT resolved in Pre-A.

### POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md
- Phase O prerequisites satisfied (Phase G complete)
- No Phase O artifacts exist (plan, commit, tag, implementation)
- Next authorized session: `PHASE_O_PLANNING`

---

**END OF PLAN — Frozen by PHASE_O_PLANNING session**