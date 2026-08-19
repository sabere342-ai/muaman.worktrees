# PRE-A PRODUCT IDENTITY & GOVERNANCE PLAN

**Phase:** Pre-A
**Session Type:** PRE_A_PLANNING
**Project:** muaman_store / I Tech Product
**Owner:** I Tech للتكنولوجيا
**Baseline:** `9c85781b1d74d17aa9c8149eb6bd5958bc8f0e35` on `codex/i-tech-next-roadmap-freeze`
**Locked Tag:** `i-tech-productization-planning-baseline-locked`
**Date:** 2026-08-19

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | Pre-A — Product Identity & Governance |
| Session Type | PRE_A_PLANNING |
| Document Status | Planning artifact — not implemented |
| Baseline Commit | `9c85781b1d74d17aa9c8149eb6bd5958bc8f0e35` |
| Planning Commit Parent | `6490d2ff62023257173f41ce28ae54bd9638ac29` |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md`, `PRODUCTIZATION_MIGRATION_PLAN.md` |
| Verified By | `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` |

---

## 2. Purpose

Pre-A establishes the clean productization boundary before any backend, auth, licensing, sync, or migration implementation begins. It answers the question: "Whose product is this, what is its name, and where does customer-specific identity end?"

Without Pre-A, every subsequent phase would inherit ambiguous identity coupling, risking:
- Accidentally branding the product as "Muaman" to new customers
- Hard-coding one shop's data into shared product code
- Leaving zero-price data gaps that corrupt profit reporting
- Losing I Tech's attribution in invoices, metadata, and documentation

Pre-A removes these risks through classification, boundary-setting, and invariant enforcement without performing backend or sync implementation.

---

## 3. Governing Principles

| # | Principle | Source |
|---|-----------|--------|
| 1 | I Tech للتكنولوجيا owns/publishes/brands the product | `PROJECT_MASTER_PLAN.md` §2, D1 |
| 2 | Shop identity is configurable per tenant — never hardcoded as product default | `PROJECT_MASTER_PLAN.md` D3, D4 |
| 3 | Muaman/مؤمن is customer/legacy identity, not product brand | `PROJECT_MASTER_PLAN.md` D2 |
| 4 | Zero data loss — legacy persisted data must never be deleted | `PROJECT_MASTER_PLAN.md` Principle 1 |
| 5 | No silent business-data mutation — price/cost invariants enforced | `PROJECT_MASTER_PLAN.md` Principle 3 |
| 6 | Platform roles are authorization-based, not OS-based | `PROJECT_MASTER_PLAN.md` D7 |
| 7 | Open Owner Decisions (OD1–OD7) remain open — no invented defaults | `PROJECT_MASTER_PLAN.md` §6 |
| 8 | Frozen compatibility register must not be violated | `PROJECT_MASTER_PLAN.md` §12 |

---

## 4. Current-State Findings

### 4.1 Identity Surfaces Audit

| Surface | Current Value | Owner | Status |
|---------|--------------|-------|--------|
| pubspec name | `muaman_store` | FROZEN | Frozen until migration (§12) |
| DB filename | `muaman_store.db` | FROZEN | Frozen until migration |
| Binary name | `muaman_store.exe` | FROZEN | Frozen until migration |
| AppId | `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` | FROZEN | Frozen — installer upgrade path |
| DefaultDirName | `{localappdata}\Programs\muaman_store` | FROZEN | Frozen — per-user install |
| Window title (main.cpp:30) | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Runner.rc CompanyName | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Runner.rc ProductName | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Runner.rc FileDescription | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Runner.rc InternalName | `muaman_store` | FROZEN | Frozen |
| Runner.rc OriginalFilename | `muaman_store.exe` | FROZEN | Frozen |
| Installer AppName | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Installer AppPublisher | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Installer AppCopyright | `Copyright (C) 2026 I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Installer AppVerName | `I-TECH للتكنولوجيا 1.0.0` | PRODUCT | Already I Tech |
| Installer DefaultGroupName | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Installer UninstallDisplayName | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Installer Start Menu shortcut | `I-TECH للتكنولوجيا` | PRODUCT | Already I Tech |
| Android applicationId | `com.almuaman.muaman_store` | FROZEN | Frozen — future Android migration |
| Android label | `muaman_store` | PRODUCT-NEEDS-CHANGE | Must become configurable (Phase K) |
| Linux APPLICATION_ID | `com.almuaman.muaman_store` | FROZEN | Frozen |
| Linux window title | `muaman_store` | PRODUCT-NEEDS-CHANGE | Should become I Tech or dynamic |
| CMake project name | `muaman_store` | FROZEN | Frozen |
| CMake MUAMAN_CANONICAL_ROOT | `\\muaman\\src` | TECHNICAL | Pathmap for reproducible builds — internal only |
| secure_store LocalAppData folder | `I-TECH` | PRODUCT | Already I Tech |
| secure_store fallback folder | `.itech` | PRODUCT | Already I Tech |
| secure_store temp files | `itech_plain_`, `itech_enc_` | TECHNICAL | Internal — no user exposure |

### 4.2 Muaman Occurrences (lib/ source only)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `database_helper.dart` | 92, 111 | `'muaman_store.db'` | FROZEN — DB filename |
| `standalone_backup_service.dart` | 59 | `'muaman_backup_$timestamp.db'` | FROZEN — backup naming |
| `standalone_restore_service.dart` | 159 | `'muaman_presave_$timestamp.db'` | FROZEN — restore naming |
| `clean_start_service.dart` | 142 | `'muaman_cleanstart_$timestamp.db'` | FROZEN — clean start naming |
| `secure_store.dart` | 14 | Comment: `muaman_store.db` | Documentation — refers to frozen DB |
| `app_settings.dart` | 204 | `'شيت_ادارة_محل_مؤمن_شهر8.xlsx'` | LEGACY — default workbook filename |

### 4.3 Muaman Occurrences (lib/ — Arabic)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `app_settings.dart` | 204 | `'شيت_ادارة_محل_ؤمن_شهر8.xlsx'` | LEGACY — default workbook filename, customer-specific |

### 4.4 I Tech Occurrences (lib/ source)

| File | Line | Content | Classification |
|------|------|---------|----------------|
| `secure_store.dart` | 33 | `I-TECH` folder path | PRODUCT — correct |
| `secure_store.dart` | 37, 276-277, 309-310 | `itech_*` paths | TECHNICAL — internal |

### 4.5 Shop Identity Model (Current)

| Field | Model Field | DB Key | Default | Status |
|-------|------------|--------|---------|--------|
| Shop name | `ShopProfile.shopName` | `shopProfile.shopName` | `'المحل'` (neutral) | Configurable |
| Owner name | `ShopProfile.ownerOrManagerName` | `shopProfile.ownerOrManagerName` | `''` (empty) | Configurable |
| Phone | `ShopProfile.phone` | `shopProfile.phone` | `''` (empty) | Configurable |
| Address | `ShopProfile.address` | `shopProfile.address` | `''` (empty) | Configurable |
| Logo | `ShopProfile.logoPath` | `shopProfile.logoPath` | `''` (empty) | Configurable |
| Support phone | `AppSettings.supportPhone` | `supportPhone` | `'+201014900211'` | NEEDS ATTENTION |
| Default customer | `AppSettings.defaultCustomerName` | `defaultCustomerName` | `'عميلنقدي'` | NEEDS ATTENTION |
| Invoice title | `AppSettings.invoiceTitle` | `invoiceTitle` | `'فاتورة بيع'` | Neutral |
| Invoice footer | `AppSettings.invoiceFooterText` | `invoiceFooterText` | `'شكراً لتعاملكم معنا'` | Neutral |
| Brand color | `AppSettings.brandColor` | `brandColor` | `'#0D47A1'` | Neutral |

---

## 5. Identity Classification Matrix

| Location | Current Value | Classification | Target Ownership | Pre-A Action | Later-Phase Action | OD Dependency | Risk |
|----------|--------------|----------------|-----------------|-------------|-------------------|--------------|------|
| `pubspec.yaml` name | `muaman_store` | FROZEN | Internal compat | No change | No change | None | LOW |
| DB filename | `muaman_store.db` | FROZEN | Internal compat | No change | No change | None | LOW |
| Binary name | `muaman_store.exe` | FROZEN | Internal compat | No change | No change | None | LOW |
| AppId GUID | `{299ADF2A-...}` | FROZEN | Installer compat | No change | No change | None | LOW |
| DefaultDirName | `{localappdata}\Programs\muaman_store` | FROZEN | Installer compat | No change | No change | None | LOW |
| CMake project | `muaman_store` | FROZEN | Build compat | No change | No change | None | LOW |
| CMake MUAMAN_CANONICAL_ROOT | `\\muaman\\src` | TECHNICAL | Internal pathmap | No change | No change | None | NONE |
| Window title (main.cpp) | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Runner.rc CompanyName | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Runner.rc ProductName | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Runner.rc FileDescription | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Runner.rc InternalName | `muaman_store` | FROZEN | Internal compat | No change | No change | None | LOW |
| Runner.rc OriginalFilename | `muaman_store.exe` | FROZEN | Internal compat | No change | No change | None | LOW |
| Installer AppName | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Installer AppPublisher | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Installer copyright | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Installer shortcuts | `I-TECH للتكنولوجيا` | PRODUCT | I Tech | No change | No change | None | NONE |
| Android applicationId | `com.almuaman.muaman_store` | FROZEN | Internal compat | No change | Phase K decision | OD1 | MEDIUM |
| Android label | `muaman_store` | PRODUCT-NEEDS-CHANGE | Configurable | No change | Phase K — new label | OD1 | MEDIUM |
| Linux title | `muaman_store` | PRODUCT-NEEDS-CHANGE | Configurable | No change | Later phase | OD1 | LOW |
| Linux APPLICATION_ID | `com.almuaman.muaman_store` | FROZEN | Internal compat | No change | Later phase | OD1 | LOW |
| secure_store folder | `I-TECH` | PRODUCT | I Tech | No change | No change | None | NONE |
| `defaultCustomerName` | `'عميلنقدي'` | NEUTRAL-DEFAULT | Shop configurable | Classify + plan removal | Phase B migration | None | MEDIUM |
| `defaultSupportPhone` | `'+201014900211'` | I-TECH-SPECIFIC | Product attribution | Classify as I Tech | Make optional/configurable | None | LOW |
| `defaultShopName` | `'المحل'` | NEUTRAL | Shop configurable | No change | Phase B — first-run | None | NONE |
| `neutralShopName` | `'المتجر'` | NEUTRAL | Shop configurable | No change | No change | None | NONE |
| `defaultInvoiceFooterText` | `'شكراً لتعاملكم معنا'` | NEUTRAL | Shop configurable | No change | No change | OD5 | NONE |
| Workbook default filename | `'شيت_ادارة_محل_ؤمن_شهر8.xlsx'` | LEGACY-CUSTOMER | Remove default | Plan removal of hardcoded path | Phase N — user-selected file | None | LOW |
| Legacy `shop_name` key (tests) | `'shop_name'` | LEGACY-KEY | Current: `shopProfile.shopName` | Update test fixtures | None | None | LOW |
| `مؤمن` in test fixtures | `'محل مؤمن'`, `'متجر مؤمن'` | TEST-FIXTURE | Replace with neutral names | Replace in test data | None | None | LOW |
| `مؤمن` in evidence/docs | Various | HISTORICAL | Preserve | No change | No change | None | NONE |
| `أحمد` in test data | Various | TEST-FIXTURE | Neutral | No change needed | None | None | NONE |

---

## 6. Product vs Shop Identity Model

### Conceptual Identity Layers

```
┌─────────────────────────────────────────────────┐
│  PRODUCT IDENTITY (I Tech)                       │
│  - Manufacturer / Publisher: I Tech للتكنولوجيا │
│  - Copyright holder                              │
│  - License issuer                                │
│  - Invoice attribution source                    │
│  - Documentation owner                           │
│  - NOT configurable per shop                     │
├─────────────────────────────────────────────────┤
│  SHOP IDENTITY (Configurable)                    │
│  - Shop name                                     │
│  - Owner/manager name                            │
│  - Phone, address                                │
│  - Logo                                          │
│  - Invoice header / title                        │
│  - Invoice footer (shop-level)                   │
│  - Brand color                                   │
│  - Support phone (shop contact)                  │
│  - DEFAULTS: empty or neutral only               │
├─────────────────────────────────────────────────┤
│  USER IDENTITY (Auth-bound)                      │
│  - Username, password hash                       │
│  - Role (owner/employee/salesOnly)               │
│  - Permissions                                   │
│  - Cloud identity (Phase D+)                     │
├─────────────────────────────────────────────────┤
│  SELLER IDENTITY (Session-bound)                 │
│  - Currently logged-in user                      │
│  - Displayed on invoice as seller                │
├─────────────────────────────────────────────────┤
│  CUSTOMER IDENTITY (Business entity)             │
│  - Customer name, phone, address                 │
│  - System customer (عميلنقدي) for walk-ins       │
│  - Managed via Customer CRUD (Phase T4+)         │
├─────────────────────────────────────────────────┤
│  LEGACY DATA (Historical)                        │
│  - Muaman-specific values in existing DB         │
│  - Evidence files, build logs                    │
│  - Historical test fixtures                      │
│  - PRESERVED — never deleted                     │
└─────────────────────────────────────────────────┘
```

### Rules

1. Product identity (I Tech) appears in: publisher metadata, copyright, invoice footer attribution slot, documentation ownership, license ownership.
2. Shop identity appears in: shop header, invoice header, UI title bar (dynamic), settings screen, customer-facing documents.
3. I Tech attribution and shop identity never replace each other.
4. Legacy data (Muaman) is preserved in historical records and evidence but never used as a product default.

---

## 7. I Tech Attribution Rules

### Where I Tech MUST Appear

| Location | Current Status | Pre-A Action |
|----------|---------------|-------------|
| Publisher/manufacturer metadata (Runner.rc, installer) | Already present | No change |
| Copyright notice (installer) | Already present | No change |
| Invoice footer attribution slot | Not yet present | Phase O — define boundary, mark OD5 |
| Documentation ownership | Already in governing docs | No change |
| License ownership | Phase E | No change in Pre-A |
| About screen / product info | Not yet present | Phase O or P |

### Where I Tech MUST NOT Appear

| Location | Reason |
|----------|--------|
| Shop name field | Shop-specific |
| Shop owner name | Shop-specific |
| Invoice header (shop section) | Shop-specific |
| Customer data | Shop-specific |
| Shop-specific settings defaults | Shop-specific |

---

## 8. Muaman De-Coupling Strategy

### 8.1 Principles

1. **No global find/replace** — Muaman occurrences span frozen, legacy, test, evidence, and technical categories with different rules.
2. **Frozen identifiers stay frozen** — pubspec name, DB filename, binary name, AppId, installer paths per `PROJECT_MASTER_PLAN.md` §12.
3. **Legacy historical data is preserved** — evidence files, build logs, UIA snapshots, documentation of prior work.
4. **Test fixtures get neutral names** — replace `مؤمن` with neutral Arabic shop names in test data.
5. **Source code gets surgical treatment** — only where Muaman coupling exists in active product behavior.

### 8.2 Action Plan by Category

| Category | Occurrences | Pre-A Action |
|----------|-------------|-------------|
| **Frozen identifiers** (pubspec, DB, binary, AppId, installer paths) | ~25 in source, ~200 in tools | NO CHANGE — per governing plan §12 |
| **Source code active behavior** (lib/) | 6 muaman in DB/backup paths | Classify as frozen; no Pre-A change |
| **Default workbook filename** (app_settings.dart:204) | 1 | Plan removal — LEGACY customer-specific default |
| **Test fixtures with `مؤمن`** | ~11 occurrences in test/ | Replace with neutral Arabic names |
| **Test imports** (`package:muaman_store/`) | ~160 import lines | NO CHANGE — package name is frozen |
| **Test files named `muaman*`** | 3 test files | NO CHANGE — frozen internal names |
| **Test assertions about `muaman_backup_`** | ~5 occurrences | NO CHANGE — frozen backup naming |
| **Linux window title** | 1 (`my_application.cc:43,47`) | Plan later-phase change (not Pre-A source change) |
| **Android label** | 1 (`AndroidManifest.xml:3`) | Plan Phase K change (blocked by OD1) |
| **Documentation** | 556+ occurrences | NO CHANGE — historical reference |
| **Evidence/logs** | 3200+ occurrences | NO CHANGE — historical evidence |
| **Tools/scripts** | 196+ occurrences | NO CHANGE — frozen build tooling |

### 8.3 Pre-A Test Fixture Replacement

Replace `مؤمن` in test fixtures with neutral names:

| File | Current | Replacement |
|------|---------|-------------|
| `test/database/standalone_backup_restore_test.dart:79,241` | `'متجر مؤمن'` | `'متجر تجريبي'` |
| `test/database/app_settings_configurables_test.dart:101-109` | `'مؤمن'` in test names/assertions | `'مؤمن'` stays as NEGATIVE assertion (testing that it is NOT used) |
| `test/features/invoice_pdf_delivery_test.dart:165` | `'محل مؤمن'` | `'محل تجريبي'` |
| `test/database/clean_start_service_test.dart:140` | `'متجر مؤمن'` | `'متجر تجريبي'` |
| `test/features/thermal_receipt_test.dart:59` | `'محل مؤمن'` | `'محل تجريبي'` |
| `test/database/workbook_import_test.dart:23` | `'شيت_ادارة_محل_ؤمن_شهر8.xlsx'` | `'شيت_ادارة_متجر_تجريبي.xlsx'` |

### 8.4 Legacy `shop_name` Key Migration

Three test files use the legacy key `'shop_name'` instead of `'shopProfile.shopName'`:

| File | Line |
|------|------|
| `test/database/standalone_backup_restore_test.dart` | 78, 240 |
| `test/database/clean_start_service_test.dart` | 139 |

Pre-A Action: Update these test fixtures to use `'shopProfile.shopName'` or verify they intentionally test legacy key migration.

---

## 9. Platform Metadata Strategy

### Windows

| Element | Current | Pre-A Action | OD1 Dependency |
|---------|---------|-------------|----------------|
| Window title (main.cpp) | `I-TECH للتكنولوجيا` | None — already correct | No |
| Runner.rc CompanyName | `I-TECH للتكنولوجيا` | None — already correct | No |
| Runner.rc ProductName | `I-TECH للتكنولوجيا` | None — already correct | No |
| Runner.rc InternalName | `muaman_store` | None — frozen | No |
| Runner.rc OriginalFilename | `muaman_store.exe` | None — frozen | No |
| Installer AppName | `I-TECH للتكنولوجيا` | None — already correct | No |
| Installer AppPublisher | `I-TECH للتكنولوجيا` | None — already correct | No |

### Android (Future Target)

| Element | Current | Pre-A Action | OD1 Dependency |
|---------|---------|-------------|----------------|
| applicationId | `com.almuaman.muaman_store` | None — frozen scaffold | YES — package rename blocked by OD1 |
| android:label | `muaman_store` | None — Phase K will change | YES — blocked by OD1 |
| namespace | `com.almuaman.muaman_store` | None — Phase K | YES — blocked by OD1 |
| MainActivity.kt package | `com.almuaman.muaman_store` | None — Phase K | YES — blocked by OD1 |

**Note:** Android package naming is explicitly listed as blocked by OD1 in `PROJECT_MASTER_PLAN.md` §6. Pre-A does not resolve OD1. The current `com.almuaman.muaman_store` is a development scaffold; the final package ID requires the marketing name.

### Linux

| Element | Current | Pre-A Action | OD1 Dependency |
|---------|---------|-------------|----------------|
| Window title | `muaman_store` | Plan later-phase change | Partial — should match product identity |
| BINARY_NAME | `muaman_store` | None — frozen | No |
| APPLICATION_ID | `com.almuaman.muaman_store` | None — frozen scaffold | Partial |

---

## 10. Shop Configuration Strategy

### Current State

Shop identity is already configurable through the Settings screen:
- `ShopProfile` model with `shopName`, `ownerOrManagerName`, `phone`, `address`, `logoPath`
- `ShopProfileRepository` persists to `app_settings` table
- `ShopProfileService` manages lifecycle
- Settings screen UI provides input fields
- Empty `shopName` falls back to `ShopProfile.defaultShopName` (`'المحل'`)

### Pre-A Requirements

1. **Remove the hardcoded default workbook filename** (`'شيت_ادارة_محل_ؤمن_شهر8.xlsx'` in `app_settings.dart:204`). This is a legacy customer-specific path that should never be a product default. Mark it as explicitly removed from defaults.
2. **Review `defaultSupportPhone`** (`'+201014900211'`). This is I Tech's support phone. It is appropriate as a product-level default (I Tech support contact), but should be documented as such and clearly separated from shop phone.
3. **No premature cloud schema** — Pre-A does not implement the cloud `shops` table.

---

## 11. Invoice / Receipt Identity Strategy

### Current Architecture

```
InvoiceDocumentData
├── shopProfile (ShopProfile)
│   ├── shopName          → SHOWN in invoice header
│   ├── ownerOrManagerName → SHOWN in invoice header
│   ├── phone              → SHOWN in invoice header
│   ├── address            → SHOWN in invoice header
│   └── logoPath           → SHOWN in invoice header
├── supportPhone           → SHOWN in invoice footer
├── invoiceTitle           → SHOWN as invoice heading
├── invoiceFooterText      → SHOWN at bottom of invoice
├── lines[]                → Transaction data
└── customerName           → Customer identity
```

### Missing: I Tech Attribution Slot

Currently there is **no I Tech attribution** in the invoice. The architecture plan (`PRODUCTIZATION_ARCHITECTURE_PLAN.md` §15) specifies:

```
Powered by I Tech للتكنولوجيا
```

This is defined as a **product attribution footer**, separate from the shop's own footer text.

### Pre-A Boundary

| Element | Source | Phase |
|---------|--------|-------|
| Shop header (name, owner, phone, address, logo) | ShopProfile | Current — already configurable |
| Invoice title | AppSettings.invoiceTitle | Current — already configurable |
| Invoice footer text | AppSettings.invoiceFooterText | Current — already configurable |
| I Tech attribution footer | NOT YET PRESENT | Phase O |
| I Tech footer exact text | BLOCKED_BY_OD5 | Phase O (OD5 controls wording) |

**Pre-A does not implement the I Tech invoice footer.** It establishes the boundary: Phase O must add an I Tech attribution slot independent from the shop's footer text. OD5 controls the exact wording.

---

## 12. P1 Finding — Zero Sale Price

### Finding Source

`PRODUCTIZATION_ARCHITECTURE_PLAN.md` §20:
> P1: Zero sale price accepted | FIX_BEFORE_PRODUCTIZATION | Pre-A

### Current Implementation Behavior

| Code Path | Validation | Zero Allowed? |
|-----------|-----------|--------------|
| `insertSaleAndDecrementStock()` (database_helper.dart:644) | `salePrice <= 0` → throw | **BLOCKED** |
| `updateSale()` (database_helper.dart:806) | `salePrice <= 0` → throw | **BLOCKED** |
| `insertInvoiceWithItems()` (database_helper.dart:712) | `item.salePrice <= 0` → throw | **BLOCKED** |
| `insertSale()` (database_helper.dart:601-633) | **NO VALIDATION** | **ALLOWED** ← CRITICAL GAP |
| `insertReturn()` (database_helper.dart:965-998) | **NO VALIDATION** | **ALLOWED** ← CRITICAL GAP |
| `updateReturn()` (database_helper.dart:1014) | `salePrice <= 0` → throw | **BLOCKED** |
| Invoice screen UI (invoice_screen.dart:627-638) | `salePrice <= 0` → show error | **BLOCKED** |
| Returns screen UI (returns_screen.dart:256-257) | **NO price validation** | **ALLOWED** ← CRITICAL GAP |
| Workbook importer (workbook_importer.dart:249-273) | **Raw `txn.insert()`** — bypasses all validation | **ALLOWED** ← CRITICAL GAP |

### Affected Files

- `app/lib/database/database_helper.dart` — `insertSale()` at line 601
- `app/lib/database/database_helper.dart` — `insertReturn()` at line 965
- `app/lib/screens/returns/returns_screen.dart` — line 256
- `app/lib/database/workbook_importer.dart` — lines 210, 226, 249-273

### Business Risk

- Zero sale prices silently enter the database through `insertSale()`, `insertReturn()`, and the workbook importer.
- Profit calculations (`gross_profit`, `net_profit`) become meaningless when sale price is zero.
- Reports show incorrect totals.
- Migration to cloud sync would propagate corrupted data.

### Expected Invariant

```
salePrice > 0 for all sale records (new inserts)
salePrice > 0 for all return records (new inserts)
```

### Migration/Backward Compatibility

- Existing historical records with salePrice = 0 may exist in production databases.
- These must NOT be rejected on read or migration.
- The invariant applies to **new inserts only**.
- Existing zero-price records are classified as historical data and preserved.

### Tests Needed

1. `insertSale()` rejects salePrice = 0
2. `insertSale()` rejects salePrice < 0
3. `insertSale()` rejects salePrice = NaN
4. `insertSale()` rejects salePrice = Infinity
5. `insertReturn()` rejects salePrice = 0
6. `insertReturn()` rejects salePrice < 0
7. Returns screen UI rejects zero/empty price
8. Workbook importer rejects zero sale prices (or warns and skips)
9. Existing zero-price records still load correctly (read path unchanged)

### Implementation Acceptance Criteria

- `insertSale()` contains the same validation as `insertSaleAndDecrementStock()`
- `insertReturn()` contains the same validation as `updateReturn()`
- Returns screen validates price > 0 before submission
- Workbook importer validates or warns on zero prices
- All existing tests continue to pass
- New tests cover each gap

---

## 13. P1 Finding — Zero Cost Price

### Finding Source

`PRODUCTIZATION_ARCHITECTURE_PLAN.md` §20:
> P1: Zero cost price accepted | FIX_BEFORE_PRODUCTIZATION | Pre-A

### Current Implementation Behavior

| Code Path | Validation | Zero Allowed? |
|-----------|-----------|--------------|
| `insertProduct()` (database_helper.dart:380) | `costPrice <= 0` → throw | **BLOCKED** |
| `updateProduct()` (database_helper.dart:435) | `costPrice <= 0` → throw | **BLOCKED** |
| Product UI (inventory_screen.dart:222-230) | `costPrice <= 0` → show error | **BLOCKED** |
| Workbook importer (workbook_importer.dart:210-226) | **Raw `txn.insert()`** — bypasses validation | **ALLOWED** ← CRITICAL GAP |
| Workbook preflight (workbook_importer.dart:146-160) | Warns for non-`تحزية` products; allows with flag | **CONDITIONAL** |

### Affected Files

- `app/lib/database/workbook_importer.dart` — lines 210, 226
- `app/lib/database/workbook_importer.dart` — lines 146-160 (preflight)

### Business Risk

- Cost price is critical for: gross profit, period profit, monthly profit, inventory valuation, cost-based reporting.
- When costPrice = 0 in the products table:
  - `totalInventoryCost` becomes 0 (even when `currentQuantity > 0`)
  - COGS on new sales becomes 0
  - Gross profit is overstated
  - Inventory valuation is understated
- The workbook importer inserts products directly via `txn.insert()`, completely bypassing the `insertProduct()` validation that enforces `costPrice > 0`.

### Expected Invariant

```
costPrice > 0 for all product records (new inserts via any path)
```

### Migration/Backward Compatibility

- Existing historical products with costPrice = 0 may exist in production databases.
- These must NOT be rejected on read, display, or migration.
- The invariant applies to **new inserts only**.
- The workbook importer's `allowZeroCost` flag for the special `تحزية` product should be reviewed: if this product is a genuine exception (e.g., a bundled/complimentary item), the exception should be documented. If it is a data artifact, the exception should be removed.

### Tests Needed

1. Workbook importer rejects zero costPrice for normal products
2. Workbook importer behavior with `allowZeroCost` flag is documented and tested
3. Existing zero-cost products still load correctly
4. New test confirming the full data flow: workbook import → product creation → costPrice > 0

### Implementation Acceptance Criteria

- Workbook importer enforces costPrice > 0 for all normal products
- The `تحزية` exception is either documented as intentional or removed
- All existing tests continue to pass
- New tests cover the import validation path

---

## 14. Data Preservation Rules

| Rule | Statement |
|------|-----------|
| R1 | Legacy persisted data must not be deleted |
| R2 | Customer-specific historical data must remain recoverable |
| R3 | Identity cleanup must distinguish defaults from real data |
| R4 | Migration must be restartable where applicable |
| R5 | No destructive migration without explicit evidence |
| R6 | Frozen identifiers (§12 master plan) remain frozen |
| R7 | Evidence files are historical records — never modified |
| R8 | Zero-price/cost legacy records are preserved on read paths |

---

## 15. Exact Implementation Scope

### Source Changes (lib/)

| File | Change | Reason |
|------|--------|--------|
| `lib/database/database_helper.dart` | Add price validation to `insertSale()` (~lines 644 pattern) | P1: zero sale price gap |
| `lib/database/database_helper.dart` | Add price validation to `insertReturn()` (~lines 1014 pattern) | P1: zero sale price gap (returns) |
| `lib/screens/returns/returns_screen.dart` | Add price > 0 validation before `insertReturn()` call | P1: zero sale price gap (UI) |
| `lib/database/workbook_importer.dart` | Add costPrice > 0 validation for product inserts | P1: zero cost price gap |
| `lib/database/workbook_importer.dart` | Add salePrice > 0 validation/warning for sale imports | P1: zero sale price gap |
| `lib/services/app_settings.dart` | Remove or neutralize hardcoded workbook filename default | Legacy customer data removal |

### Test Changes (test/)

| File | Change | Reason |
|------|--------|--------|
| `test/database/standalone_backup_restore_test.dart` | Replace `مؤمن` fixture data; update `shop_name` → `shopProfile.shopName` key | Identity cleanup + legacy key |
| `test/database/clean_start_service_test.dart` | Replace `مؤمن` fixture data; update `shop_name` → `shopProfile.shopName` key | Identity cleanup + legacy key |
| `test/features/invoice_pdf_delivery_test.dart` | Replace `محل مؤمن` with `محل تجريبي` | Identity cleanup |
| `test/features/thermal_receipt_test.dart` | Replace `محل مؤمن` with `محل تجريبي` | Identity cleanup |
| `test/database/workbook_import_test.dart` | Replace `مؤمن` filename fixture | Identity cleanup |
| `test/database/sale_transaction_test.dart` | Add tests for `insertSale()` price validation | P1: zero sale price |
| `test/database/sale_return_update_consistency_test.dart` | Add tests for `insertReturn()` price validation | P1: zero sale price |
| `test/database/workbook_import_test.dart` | Add tests for workbook importer price/cost validation | P1: zero price/cost |
| `test/features/returns_validation_test.dart` (new) | Add UI tests for returns screen price validation | P1: zero sale price (UI) |

### Configuration Changes

None. No `pubspec.yaml`, `CMakeLists.txt`, `build.gradle`, `AndroidManifest.xml`, `Runner.rc`, or `muaman.iss` changes in Pre-A.

### Documentation Changes

| File | Change | Reason |
|------|--------|--------|
| (none new) | The planning artifact itself is the documentation | Sufficient for Pre-A scope |

---

## 16. Explicit Out-of-Scope

The following are **explicitly NOT implemented** in Pre-A:

| Item | Phase | Reason |
|------|-------|--------|
| Supabase backend setup | C | Pre-A is identity only |
| RLS implementation | F | Backend phase |
| Cloud authentication | D | Backend phase |
| License implementation | E | Backend phase |
| 14-day trial | E | Backend phase |
| Sync engine | H | Backend phase |
| Offline queue | H | Backend phase |
| Android UI build-out | K, L | Platform phase |
| Multi-user invitation flow | D | Backend phase |
| Full legacy data migration | I | Migration phase |
| Billing/subscription | E | Backend phase |
| I Tech invoice footer text | O | Blocked by OD5 |
| Cloud schema creation | C | Backend phase |
| New Supabase project resources | C | Backend phase |
| Android package rename | K | Blocked by OD1 |
| pubspec rename | J+ | Frozen until migration |
| DB rename | J+ | Frozen until migration |
| Binary rename | J+ | Frozen until migration |
| AppId change | J+ | Frozen — installer upgrade |
| Full Muaman removal from tools/ | Later | Frozen build tooling |
| Full Muaman removal from evidence/ | Never | Historical evidence |

---

## 17. Owner Decision Dependencies

| OD | Decision | Relevant to Pre-A? | Blocks Implementation? | Safe Placeholder? | Deferred Phase |
|----|----------|--------------------|-----------------------|-------------------|----------------|
| OD1 | Final product marketing name | Partially — Android package naming | No — current `com.almuaman` is a development scaffold | Use internal placeholder `I Tech Store Management Product` for any new non-frozen references | Phase K |
| OD2 | License pricing model | No | No | N/A | Phase E |
| OD3 | Max users/devices per plan | No | No | N/A | Phase E+ |
| OD4 | Offline grace duration | No | No | N/A | Phase H |
| OD5 | Invoice footer exact text | Yes — invoice attribution slot design | No — Pre-A defines the boundary, not the text | Slot defined as `BLOCKED_BY_OD5` | Phase O |
| OD6 | Negative stock policy while offline | No | No | N/A | Phase M |
| OD7 | Seller offline sale allowed | No | No | N/A | Phase H |

**OD1 Note:** The absence of a final marketing name does NOT permit continued use of Muaman as the product name. Any new non-frozen references should use a neutral internal placeholder.

**OD5 Note:** Pre-A defines the architectural slot for I Tech invoice attribution (Phase O). The exact footer text is controlled by OD5 and is NOT resolved in Pre-A.

---

## 18. Testing Strategy

### Unit Tests

| Test Area | Files | Pre-A Changes |
|-----------|-------|-------------|
| Price validation (insertSale) | `sale_transaction_test.dart` | Add tests for gap in `insertSale()` |
| Price validation (insertReturn) | `sale_return_update_consistency_test.dart` | Add tests for gap in `insertReturn()` |
| Price validation (workbook import) | `workbook_import_test.dart` | Add tests for importer validation |
| Returns UI validation | New `returns_validation_test.dart` | Add UI-level price validation tests |
| Product cost validation | `product_validation_test.dart` | No change — already covered |
| Sale price validation (atomic) | `sale_transaction_test.dart` | No change — already covered |
| Identity regression | Existing tests | Update fixture data only |

### Existing Regression Suite

- `flutter test` — 716/716 passing at baseline
- All existing tests must continue to pass after Pre-A changes
- New tests are additive only

### Identity Regression Tests

The following existing tests serve as identity regression guards:
- `app_settings_configurables_test.dart:101-109` — verifies `defaultCustomerName` is NOT `مؤمن`
- `shop_profile_test.dart:43-46` — verifies `neutralShopName` is generic

---

## 19. Static Analysis / Formatting Gates

Implementation closure must pass:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
git diff --check
```

Baseline values:
- `flutter analyze`: 0 errors, 0 warnings, 7 infos
- `flutter test`: 716/716 passing

Post-implementation targets:
- `flutter analyze`: 0 errors, 0 warnings (infos may increase from new test files)
- `flutter test`: 716+ passing (all existing + new tests)

---

## 20. Pre-A Entry Criteria

| Criterion | Status |
|-----------|--------|
| Locked baseline verified at `9c85781b` | VERIFIED |
| Branch is `codex/i-tech-next-roadmap-freeze` | VERIFIED |
| HEAD matches expected baseline | VERIFIED |
| Tag `i-tech-productization-planning-baseline-locked` resolves to parent | VERIFIED |
| Worktree logically clean (CRLF-only noise) | VERIFIED |
| Index clean | VERIFIED |
| Pre-existing stash unchanged | VERIFIED |
| Governing plans read and reconciled | VERIFIED |
| `flutter analyze` baseline captured | 0 errors / 0 warnings / 7 infos |
| `flutter test` baseline captured | 716/716 passing |
| Product identity inventory complete | COMPLETE |
| P1 audit findings located and analyzed | COMPLETE |

---

## 21. Pre-A Exit Criteria

| # | Criterion | Verification Method |
|---|-----------|-------------------|
| 1 | `insertSale()` validates `salePrice > 0` | Code inspection + test |
| 2 | `insertReturn()` validates `salePrice > 0` | Code inspection + test |
| 3 | Returns screen validates price > 0 | Code inspection + test |
| 4 | Workbook importer validates `costPrice > 0` | Code inspection + test |
| 5 | Workbook importer validates/warns `salePrice > 0` | Code inspection + test |
| 6 | No inappropriate Muaman product-brand occurrences in new code | Code review |
| 7 | Test fixtures with `مؤمن` replaced with neutral names | Grep verification |
| 8 | Legacy `shop_name` test keys migrated or justified | Code review |
| 9 | Hardcoded workbook filename removed/neutralized | Code inspection |
| 10 | `flutter analyze` = 0 errors, 0 warnings | Automated |
| 11 | `flutter test` = all passing (≥716) | Automated |
| 12 | No unintended schema/backend/dependency changes | `git diff --stat` |
| 13 | Planning-only commit | `git diff --cached --name-status` |

---

## 22. Implementation Sequence

| Step | Description | Dependencies |
|------|------------|-------------|
| 1 | Add price validation to `insertSale()` | None |
| 2 | Add price validation to `insertReturn()` | None |
| 3 | Add UI price validation to returns screen | None |
| 4 | Add workbook importer price/cost validation | None |
| 5 | Remove/neutralize hardcoded workbook filename | None |
| 6 | Update test fixtures: replace `مؤمن` with neutral names | None |
| 7 | Update test fixtures: migrate legacy `shop_name` key | None |
| 8 | Add new unit tests for each validation gap | Steps 1-4 |
| 9 | Add new UI test for returns price validation | Step 3 |
| 10 | Run `flutter analyze` | Steps 1-9 |
| 11 | Run `flutter test` | Steps 1-9 |
| 12 | Run `git diff --check` | Steps 1-11 |
| 13 | Create planning commit (if planning changes) | Step 12 |

Steps 1-7 are independent and can be parallelized.
Steps 8-9 depend on their respective implementation steps.
Steps 10-12 are verification gates.

---

## 23. Rollback / Risk Strategy

| Risk | Mitigation |
|------|-----------|
| Breaking existing stored settings | Pre-A does NOT change any app_settings keys or defaults in the database. Only code-level validation is added. |
| Changing executable/app identifiers | Pre-A does NOT change any frozen identifiers. |
| Losing shop branding | Pre-A does NOT change ShopProfile or any shop settings. |
| Mutating historical invoices | Pre-A does NOT change any read/display paths for existing data. |
| Breaking imports | Workbook importer gains validation — may reject previously-accepted zero-price rows. This is the intended behavior. Add warning/confirm flow. |
| Breaking reports | Reports read existing data — no change. New validation prevents future zero-price data. |
| Incorrectly rejecting legacy zero-price rows | All validation is on INSERT paths only. Read/update of existing zero-price rows is NOT affected. |
| Test fixture contamination | Test fixtures are changed from `مؤمن` to neutral names. No behavioral change. |
| `insertSale()` is called from a code path we did not discover | Search for all callers of `insertSale()` vs `insertSaleAndDecrementStock()`. The `insertSale()` method appears to be an older/alternate path — adding validation matches the newer atomic path. |

---

## 24. Definition of Done

```
PRE_A_DONE = (
  insertSale validates salePrice > 0 AND
  insertReturn validates salePrice > 0 AND
  returns_screen validates price > 0 AND
  workbook_importer validates costPrice > 0 AND
  workbook_importer validates salePrice > 0 AND
  hardcoded workbook filename neutralized AND
  test fixtures with مؤمن replaced AND
  legacy shop_name test keys migrated AND
  flutter analyze = 0 errors, 0 warnings AND
  flutter test = all passing AND
  git diff --check clean AND
  planning commit created AND
  no source/schema/dependency changes outside scope AND
  no push/tag/deploy performed
)
```

---

## 25. Governance Consistency Check

| Governing Plan Topic | Pre-A Plan Alignment | Verdict |
|---------------------|---------------------|---------|
| Phase ordering (A → B → C → ...) | Pre-A is Phase A, first in chain | CONSISTENT |
| Supabase backend | Pre-A does not touch Supabase | CONSISTENT |
| SQLite preserved | Pre-A does not change SQLite schema or behavior | CONSISTENT |
| Multi-tenancy via shop_id | Pre-A does not implement cloud multi-tenancy | CONSISTENT |
| shop_id RLS | Pre-A does not implement RLS | CONSISTENT |
| Licensing | Pre-A does not implement licensing | CONSISTENT |
| 14-day trial | Pre-A does not implement trial | CONSISTENT |
| Windows + Android targets | Pre-A does not change platform targeting | CONSISTENT |
| Muaman as product brand = FORBIDDEN | Pre-A classifies and de-couples Muaman | CONSISTENT |
| I Tech ownership | Pre-A confirms I Tech attribution surfaces | CONSISTENT |
| Frozen compatibility register | Pre-A respects all frozen identifiers | CONSISTENT |
| Zero data loss | Pre-A does not delete any persisted data | CONSISTENT |
| Additive-only schema | Pre-A does not change schema | CONSISTENT |
| OD1-OD7 preserved | All 7 open decisions preserved, none resolved | CONSISTENT |
| P1 findings addressed | Both P1 findings (zero sale/cost price) analyzed with exact scope | CONSISTENT |
| Migration strategy | Pre-A does not implement migration | CONSISTENT |

**GOVERNANCE_CONSISTENCY = PASS**

---

*This document is the Pre-A planning artifact for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md phase roadmap.*
