# I-TECH Post-T3-3 — Fresh Repository Reassessment

## 1. Purpose

This document provides an evidence-based reassessment of the I-TECH repository after completion of all governed T1/T2/T3 work. It replaces the gap list from the original frozen roadmap (`I-TECH-NEXT-ROADMAP-FREEZE.md`) with a verified current-state audit.

**This is NOT a roadmap.** It is the audit foundation for the new roadmap freeze.

## 2. Baseline

| Item | Value |
|---|---|
| Project | I-TECH / إدارة محل مؤمن |
| Platform | Flutter / Dart — Windows Desktop |
| Worktree | `C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze` |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| HEAD | `6affa41` |
| Schema version | 7 |
| DB filename | `muaman_store.db` |
| Package name | `muaman_store` |
| Version | `1.0.0+1` |
| Test count | 690 passed, 0 failed |

## 3. Completed Work Since Original Roadmap Baseline

The original roadmap was frozen at `2295137`. Since then, the following work has been completed and accepted:

| Commit | Stage | Type | What was done |
|---|---|---|---|
| `ade506a` | T1-1 | Implementation | Replaced ~26 hardcoded `Color(0xFF0D47A1)` across 7 screen files with theme-driven brand color |
| `df17d17` | T1-2 | Design Freeze | Standalone backup/restore design contract |
| `a3dacd8` | T2-1 | Implementation | Standalone backup/restore workflow (VACUUM INTO + integrity verify + restore with pre-save) |
| `26cd605` | T2-2 | Implementation | Expense categories (table + CRUD + UI + migration v7) |
| `0cc157e` | T2-2 | Governance Report | Expense categories governance report |
| `2728419` | T2-3 | Design Freeze | Customer master design contract (NOT implemented) |
| `0a61984` | T2-4 | Design Freeze | Thermal printing design contract |
| `73c9498` | T2-4 | Implementation | 80mm thermal receipt printing (renderer + delivery + config + tests) |
| `9bcc191` | T3-1 | Design Freeze | Licensing policy design (4 owner decisions frozen) |
| `798c105` | T3-2 | Design Freeze | Licensing technical contract (Ed25519, CBOR, DPAPI, state machine) |
| `6affa41` | T3-3 | Implementation | Cryptographically verified, device-bound licensing (6 new files, 5 modified, 18 write-method enforcement) |

## 4. Current Application Capability Map

### Core Domain — COMPLETE

| Capability | Status | Evidence |
|---|---|---|
| Products (CRUD) | COMPLETE | `database_helper.dart`, `inventory_screen.dart` |
| Sales (CRUD) | COMPLETE | `database_helper.dart`, `sales_screen.dart` |
| Returns (CRUD) | COMPLETE | `database_helper.dart`, `returns_screen.dart` |
| Expenses (CRUD) | COMPLETE | `database_helper.dart`, `expenses_screen.dart` |
| Expense Categories | COMPLETE | `expense_categories.dart`, `expense_categories_screen.dart`, schema v7 |
| Inventory Count / Stocktake | COMPLETE | `database_helper.dart`, `inventory_count_screen.dart` |
| Invoices (header + items) | COMPLETE | `database_helper.dart`, `invoice_repository.dart` |
| PDF invoice (A4) | COMPLETE | `invoice_pdf_renderer.dart`, `invoice_delivery.dart` |
| PDF preview | COMPLETE | `invoice_preview_screen.dart` |
| Thermal receipt (80mm) | COMPLETE | `thermal_receipt_renderer.dart`, `thermal_delivery.dart`, `thermal_receipt_config.dart` |
| Workbook import (XLSX) | COMPLETE | `workbook_importer.dart`, `xlsx_reader.dart` |
| Dashboard | COMPLETE | `dashboard_screen.dart` |
| Sales reports (3 tabs) | COMPLETE | `sales_report_screen.dart` |
| COGS tracking | COMPLETE | `database_helper.dart` (sales.cogs, returns.returnedCogs) |
| Negative stock prevention | COMPLETE | `insertSaleAndDecrementStock` |
| Orphan integrity detection | COMPLETE | `findProductReferenceIntegrityIssues` |
| Barcode auto-generation | COMPLETE | `generateBarcode()` |

### Productization / Configurability — COMPLETE

| Feature | Status |
|---|---|
| Shop name / profile | COMPLETE |
| Shop logo | COMPLETE |
| Configurable brand color | COMPLETE |
| Button style | COMPLETE |
| Permissions (18 granular) | COMPLETE |
| User roles (owner / employee / salesOnly) | COMPLETE |
| Default customer name | COMPLETE |
| Support phone | COMPLETE |
| Invoice title | COMPLETE |
| Invoice footer text | COMPLETE |
| PDF / preview parity | COMPLETE |
| Windows delivery foundation | COMPLETE |

### Auth / Permissions — COMPLETE

| Capability | Status |
|---|---|
| First-owner setup | COMPLETE |
| Login / logout | COMPLETE |
| Role-based access control | COMPLETE |
| Permission-gated navigation | COMPLETE |
| Data-layer permission enforcement | COMPLETE |
| Owner-exclusive powers | COMPLETE |
| Persistent role permissions | COMPLETE |

### Data Safety — COMPLETE

| Capability | Status |
|---|---|
| Clean-start with mandatory backup | COMPLETE |
| Backup verification (integrity + read) | COMPLETE |
| Fail-closed on backup failure | COMPLETE |
| Confirmation phrase gate | COMPLETE |
| Transactional wipe | COMPLETE |
| Preserved tables (users, settings, roles) | COMPLETE |
| Standalone backup | COMPLETE |
| Standalone restore | COMPLETE |

### Licensing (T3) — COMPLETE (client-side)

| Capability | Status |
|---|---|
| Ed25519 entitlement verification | COMPLETE |
| CBOR canonical serialization | COMPLETE |
| Device fingerprint (MachineGuid + CPU + Board) | COMPLETE |
| DPAPI-protected local storage | COMPLETE |
| 13-state entitlement machine | COMPLETE |
| Write-boundary enforcement (18 methods) | COMPLETE |
| Non-destructive restricted mode | COMPLETE |
| Licensing settings UI | COMPLETE |
| Legacy MUAMAN-* key neutralized | COMPLETE |
| Activation server | NOT DEPLOYED (protocol boundary only) |
| Production trusted keys | NOT PROVISIONED (empty dev keys) |

## 5. Proven Remaining Gaps

### GAP-C1: No Dedicated Customer Entity

**Confidence: HIGH — PROVEN**

Customer is a free-text field on invoices. There is no `customers` table, no customer CRUD, no customer history, no balances, no receivables. The only customer-related concept is a configurable default customer name (`defaultCustomerName = 'عميل نقدي'`).

**Schema impact:** Additive — new `customers` table, nullable FK on `invoices`.

### GAP-C2: No Supplier / Purchasing Domain

**Confidence: HIGH — PROVEN**

No supplier table, no purchase documents, no stock receipt from purchases, no supplier balances, no supplier payments. Products enter the system only through manual creation or XLSX workbook import.

**Schema impact:** Additive — new tables (`suppliers`, `purchases`, `purchase_items`). High domain complexity.

### GAP-C3: No VAT / Tax

**Confidence: HIGH — PROVEN**

No tax, VAT, or GST fields anywhere in models, database schema, or UI. Sales are recorded without any tax component.

**Schema impact:** Additive — new columns on `sales`, `products`. Accounting boundary.

### GAP-C4: No Multi-Currency

**Confidence: HIGH — PROVEN**

All monetary values are `REAL` with no currency field. Currency hardcoded to EGP (`ج.م`). Single currency assumed.

**Schema impact:** Additive — new fields on monetary tables. Accounting boundary.

### GAP-C5: Activation Server Not Deployed

**Confidence: HIGH — PROVEN**

The `ActivationClient` in `licensing_service.dart` implements the protocol boundary but throws `SocketException('Activation server not yet deployed')` when called. No server infrastructure exists.

**Impact:** Existing T3-3 licensing is structurally complete but functionally unusable for new activations. Existing installations remain in `uninitialized` state until server is deployed.

### GAP-C6: Production Trusted Keys Empty

**Confidence: HIGH — PROVEN**

`_defaultTrustedKeys` in `entitlement_token.dart` is empty. No Ed25519 production keypair has been generated or provisioned.

**Impact:** Even with a deployed server, token verification would fail without valid trusted keys embedded at build time.

### GAP-C7: No Customer Display

**Confidence: HIGH — PROVEN**

No secondary display, customer-facing screen, or display protocol.

**Impact:** Optional hardware feature. Low priority for current delivery.

### GAP-C8: No Barcode Scanner Integration

**Confidence: MEDIUM**

Barcode is a text field on products. No camera-based scanning, no USB scanner listener.

**Impact:** Optional hardware feature. Current text-based barcode entry is functional.

## 6. Completed / Closed Old Gaps

The following gaps from the original roadmap (`I-TECH-NEXT-ROADMAP-FREEZE.md`) are now **CLOSED** and must NOT be re-scheduled:

| Old Gap | Original Status | Current Status | Closure Evidence |
|---|---|---|---|
| GAP-01: Hardcoded Brand Color | OPEN | **CLOSED** | `ade506a` — theme-driven brand color across 7 screens; only 3 legitimate fallbacks remain |
| GAP-02: No Standalone Backup/Restore | OPEN | **CLOSED** | `a3dacd8` — full standalone backup + restore implementation |
| GAP-03: Licensing Is Cosmetic | OPEN | **CLOSED** | `6affa41` — T3-3 cryptographically verified, device-bound licensing with write enforcement |
| GAP-06: No Thermal/POS Printing | OPEN | **CLOSED** | `73c9498` — 80mm thermal receipt rendering + delivery + config + tests |
| GAP-08: No Expense Categories | OPEN | **CLOSED** | `26cd605` — expense categories with CRUD, UI, and schema v7 migration |

### Old Gaps That Remain OPEN

| Old Gap | Original Status | Current Status | Notes |
|---|---|---|---|
| GAP-04: No Dedicated Customer Entity | OPEN | **STILL OPEN** | Design frozen at T2-3 (`2728419`) but NOT implemented |
| GAP-05: No Supplier/Purchasing | OPEN | **STILL OPEN** | No design freeze or implementation |
| GAP-07: No VAT/Tax | OPEN | **STILL OPEN** | No design freeze or implementation |
| GAP-10: No Multi-Currency | OPEN | **STILL OPEN** | No design freeze or implementation |
| GAP-09: No Barcode Scanner | OPEN | **STILL OPEN** | Optional hardware; low priority |
| GAP-11: No Customer Display | OPEN | **STILL OPEN** | Optional hardware; low priority |

## 7. Licensing Position After T3-3

### Completed Licensing Implementation (commit `6affa41`)

- Ed25519 asymmetric signature verification
- CBOR canonical token serialization
- Windows device fingerprint (MachineGuid + CPU + Board Serial → SHA-256)
- DPAPI-protected local activation state (separate from business database)
- HMAC-SHA256 integrity on local state
- 13-state entitlement state machine
- Write-boundary enforcement on 18 business mutation methods
- Non-destructive restricted mode (reads/backup always allowed)
- Licensing settings UI with activate/deactivate
- Legacy MUAMAN-* key neutralization
- `LicenseActivationRequiredException` for enforcement
- Startup initialization and enforcement wiring

### Infrastructure Debt (not implementation gaps)

| Item | Classification | Why it's separate |
|---|---|---|
| Activation server deployment | **Separate infrastructure project** | Server is an independent backend service; not a Flutter/Dart task |
| Production Ed25519 keypair provisioning | **Build-time configuration** | Keys generated on server, public key embedded at build time |
| DPAPI via PowerShell subprocess | **Known technical debt** | Functional; FFI migration is optional performance improvement |

### Owner / Commercial Decisions (NOT engineering gaps)

| Decision | Classification | Impact on current delivery |
|---|---|---|
| Grandfathering existing installations | OWNER DECISION | Architecture supports both options; blocks no engineering work |
| Trial duration / policy | OWNER DECISION | Token format supports `expires_at`; blocks no engineering work |
| Pricing tiers | OWNER DECISION | Token format supports tier differentiation; blocks no engineering work |
| Activation count / device transfer policy | ALREADY FROZEN in T3-1 | 1 active device + controlled transfer; no change needed |
| Offline-only vs activation-server | ALREADY FROZEN in T3-1 | Online activation + offline runtime; no change needed |

### Optional Future Hardening (not required for current delivery)

| Item | Classification | Priority |
|---|---|---|
| Native DPAPI FFI migration | Performance improvement | LOW |
| Activation server deployment | Required for NEW activations only | HIGH for resale; LOW for current shop |
| Production key provisioning | Required for production builds | HIGH for resale; LOW for current shop |
| Token expiry field | Future commercial feature | DEFERRED until owner decides on trial/subscription |

## 8. Permissions / Security Audit

### Enforcement Layers

Permissions are enforced at **both** the UI level and the database level:

| Layer | Mechanism | Evidence |
|---|---|---|
| UI navigation | `SessionState.hasPermission()` filters nav items | `full_app_shell.dart` |
| Screen access | Permission checks on screen entry | Individual screens |
| Database writes | `_requirePermission()` on every write method | `database_helper.dart` |
| Licensing writes | `_enforceLicensing()` on 18 business mutations | `database_helper.dart` |

### Protected Operations

| Operation | DB-level enforcement | UI-level enforcement |
|---|---|---|
| Product CRUD | YES | YES |
| Sales CRUD | YES | YES |
| Returns CRUD | YES | YES |
| Expenses CRUD | YES | YES |
| Inventory count | YES | YES |
| Invoice creation | YES | YES |
| User management | YES (owner-only) | YES |
| Permission management | YES (owner-only) | YES |
| Settings changes | Via licensing enforcement only | Via permission check |
| Backup/restore | Owner-only gate | Owner-only gate |
| Clean start | Owner-only + confirmation phrase | Owner-only |

### Assessment

**No bypassable security gaps found.** All business write operations have dual-layer enforcement (UI + database). Licensing enforcement adds a third layer for commercial protection.

## 9. Windows Delivery Assessment

| Aspect | Status | Notes |
|---|---|---|
| Windows identity | FROZEN | CompanyName=I-TECH, ProductName=I-TECH, BINARY_NAME=muaman_store |
| Build system | WORKING | Flutter Windows desktop build functional |
| Runtime dependencies | COMPLETE | sqflite_common_ffi, pdf, printing, cryptography, cbor, http |
| Fresh-profile behavior | VERIFIED | First-owner setup → full application |
| App naming/branding | COMPLETE | Arabic name "إدارة محل مؤمن" in UI |
| Installer | NOT ASSESSED | No installer artifacts in repository |
| Code signing | NOT ASSESSED | Not in repository scope |
| Production keys | NOT PROVISIONED | Empty trusted key set |

## 10. Schema Assessment

### Current Tables (v7)

| Table | Purpose | Row estimate |
|---|---|---|
| `products` | Product catalog with stock tracking | Core |
| `sales` | Sale line items (per-product per-invoice) | Core |
| `returns` | Return line items | Core |
| `expenses` | Business expenses with category | Core |
| `expense_categories` | Expense category names | Small |
| `invoices` | Invoice headers | Core |
| `inventory_count` | Stocktake records | Core |
| `import_batches` | XLSX import audit trail | Audit |
| `users` | User accounts with roles | Small |
| `role_permissions` | Role→permission mapping | Small (3 rows) |
| `app_settings` | Key-value configuration | Small |

### Missing Business Domain Entities

| Entity | Impact | Complexity |
|---|---|---|
| Customers | MEDIUM — enables customer history, balances | Medium (new table + CRUD + invoice FK) |
| Suppliers | HIGH — enables purchasing workflow | High (full domain redesign) |
| Purchases | HIGH — enables stock receipt from suppliers | High (new tables + accounting integration) |
| Supplier payments | HIGH — enables payables tracking | High (depends on supplier + purchase) |
| Customer payments/receivables | MEDIUM — enables credit tracking | Medium (depends on customer entity) |
| Tax/VAT | MEDIUM — enables tax compliance | Medium (schema + accounting logic) |

## 11. Owner Decisions Required

The following are genuine owner/product decisions that may affect roadmap prioritization. None blocks the immediate next step.

### Decision 1 — Delivery Target

**Question:** What is the immediate delivery target?

| Option | Description |
|---|---|
| A | Current shop only (known deployment, known owner) |
| B | Resale to multiple independent shops |
| C | Both — current shop now, resale later |

**Impact:** Determines whether activation server / production keys are urgent (B/C) or deferred (A).

### Decision 2 — Grandfathering

**Question:** When the activation server is deployed, should existing installations be grandfathered?

| Option | Description |
|---|---|
| A | No grandfathering — all must activate through new system |
| B | Grace period — existing installations get N days of continued operation |
| C | Permanent grandfathering — existing installations always treated as valid |

**Impact:** Architecture supports all options. Decision affects migration UX.

### Decision 3 — Trial Policy

**Question:** Should there be a trial period for new installations?

| Option | Description |
|---|---|
| A | No trial — activation required immediately |
| B | Time-limited trial (e.g., 14/30 days) |
| C | Deferred — decide later |

**Impact:** Token format supports `expires_at` field. No structural change needed.

### Decision 4 — Pricing Model

**Question:** What commercial model applies?

| Option | Description |
|---|---|
| A | Perpetual license (one-time purchase) |
| B | Subscription (annual/monthly) |
| C | Deferred — decide later |

**Impact:** Affects token expiry behavior. Architecture supports all options.

### Decision 5 — Customer Entity Priority

**Question:** Is customer management a priority for current delivery?

| Option | Description |
|---|---|
| A | Yes — implement customer CRUD and invoice linkage |
| B | No — free-text customer name is sufficient for now |
| C | Deferred — decide after current shop feedback |

**Impact:** Affects whether T4-1 (customer master implementation) is the next step.

## 12. Assessment Summary

| Domain | Status | Remaining Work |
|---|---|---|
| Core CRUD (products, sales, returns, expenses) | COMPLETE | None |
| Expense categories | COMPLETE | None |
| Invoice system (A4 + thermal) | COMPLETE | None |
| Productization / configurability | COMPLETE | None |
| Auth / permissions | COMPLETE | None |
| Data safety / backup / restore | COMPLETE | None |
| Licensing (client-side) | COMPLETE | Server deployment is separate infrastructure |
| Brand color consistency | COMPLETE | None |
| Customer entity | DESIGN FROZEN (T2-3) | Implementation needed |
| Supplier / purchasing | NOT STARTED | Design freeze + implementation needed |
| VAT / tax | NOT STARTED | Design freeze + implementation needed |
| Multi-currency | NOT STARTED | Design freeze + implementation needed |
| Activation server | NOT STARTED | Separate infrastructure project |
| Production key provisioning | NOT STARTED | Build-time configuration |
| Windows installer | NOT ASSESSED | Separate packaging task |

---

```
I-TECH Post-T3-3 — Fresh Repository Reassessment
Document complete. Basis for new roadmap freeze.
```
