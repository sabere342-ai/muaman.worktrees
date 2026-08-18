# I-TECH T4-1 Customer Master — Implementation Governance Report

**Commit:** `601bff6`
**Branch:** `codex/i-tech-next-roadmap-freeze`
**Date:** 2026-08-17
**Decision Owner:**美的 (Owner Decision #5)

---

## 1. Executive Summary

T4-1 Customer Master has been fully implemented, tested, and committed. The implementation follows the T2-3 frozen design contract exactly, with additive schema changes, full backward compatibility, and zero data loss risk.

## 2. What Was Implemented

### 2.1 New Files
| File | Purpose |
|------|---------|
| `app/lib/models/customer.dart` | Customer model (id, name, phone, address, notes, isActive, isSystem, createdAt, updatedAt) |
| `app/lib/screens/customers/customers_screen.dart` | Customer CRUD UI (list/search/add/edit/archive/reactivate) |
| `app/test/database/customer_master_test.dart` | 26 unit tests for customer CRUD, linkage, licensing, permissions |

### 2.2 Modified Files (13 files)
| File | Changes |
|------|---------|
| `app/lib/models/invoice.dart` | Added nullable `customerId` field |
| `app/lib/database/database_helper.dart` | Schema v8 migration, customers table, customerId on invoices, 8 CRUD methods with licensing/permission gates |
| `app/lib/main.dart` | Added customer import, AppBar button, `_openCustomers()` navigation |
| `app/lib/screens/sales/invoice_screen.dart` | Replaced free-text TextField with customer dropdown selector + inline add dialog |
| `app/lib/screens/settings_screen.dart` | Removed defaultCustomerName controller, loading, UI section, save method, dispose |
| `app/lib/services/app_settings.dart` | Removed `defaultCustomerName` from `initializeDefaults()` |
| `app/lib/services/clean_start_service.dart` | Added `customers` to `transactionalTables` |
| `app/lib/services/standalone_restore_service.dart` | Accepts schema v7/v8, conditional customers table |
| `app/test/helpers/test_schema.dart` | Added customers table, customerId column on invoices, indexes |
| `app/test/database/clean_start_service_test.dart` | Added customer seeding, expect customers in report |
| `app/test/features/invoice_pdf_delivery_test.dart` | Added `seedCustomer()` helper, called in relevant test |
| `app/test/features/sales_invoice_behavior_test.dart` | Seeded customer in setUp |
| `app/test/features/sales_permissions_widget_test.dart` | Seeded customer in setUp |

### 2.3 Removed
| Item | Reason |
|------|--------|
| `defaultCustomerName` setting | Replaced by customer CRUD system |

## 3. Schema Migration (v7 → v8)

- **customers table** created with id, name, phone, address, notes, isActive, isSystem, createdAt, updatedAt
- **customerId column** added to invoices table (nullable INTEGER)
- **Indexes** created: idx_customers_name, idx_customers_isActive, idx_invoices_customerId
- **System customer** (عميل نقدي) seeded with isSystem=1
- **Existing invoices** linked to system customer via UPDATE
- **defaultCustomerName setting** removed from app_settings table
- All migration steps wrapped in transaction — atomic rollback on failure

## 4. Test Results

```
716 passed, 0 failed
```

### T4-1 Specific Tests (26 tests)
- **TC-CUST-01 to TC-CUST-19:** Customer CRUD (insert, search, update, archive, reactivate, validation, sorting)
- **TC-INV-CUST-01 to TC-INV-CUST-03:** Invoice-Customer linkage (with customerId, without customerId, archived customer reference)
- **TC-LIC-CUST-01 to TC-LIC-CUST-04:** Licensing gate enforcement on all write methods

### Fixed Pre-existing Tests (7 tests fixed)
- `sales_invoice_behavior_test.dart`: 4 tests (customer seeding)
- `sales_permissions_widget_test.dart`: 1 test (customer seeding)
- `invoice_pdf_delivery_test.dart`: 1 test (seedCustomer helper)
- `clean_start_service_test.dart`: 1 test (customer seeding in transactional data + report)

## 5. Governance Compliance

| Requirement | Status |
|-------------|--------|
| Schema additive, backward-compatible | ✅ v7→v8 migration preserves all data |
| customerName legacy field preserved | ✅ Invoices still store customerName snapshot |
| customerId nullable | ✅ Invoices without customer still work |
| System customer seeded in migration | ✅ عميل نقدي with isSystem=1 |
| defaultCustomerName removed | ✅ From app_settings and settings UI |
| Customer deletion archives only | ✅ isActive flag; invoices NOT deleted |
| Licensing gate on all writes | ✅ _enforceLicensing() on all 8 methods |
| Permission check on all writes | ✅ canCreateSales required |
| No new permissions | ✅ Reused canCreateSales |
| No licensing redesign | ✅ No changes to entitlement system |
| No architecture rewrite | ✅ Followed existing patterns |
| Single scoped commit | ✅ 16 files changed, 1497 insertions, 108 deletions |
| dart format applied | ✅ |
| git diff --check clean | ✅ (CRLF warnings only) |
| No platform files | ✅ Reverted generated_plugin_registrant files |
| No push/rebase/tag | ✅ |

## 6. Scope Boundaries (NOT Implemented)

Per T2-3 design freeze and Owner Decision #5:
- ❌ Balances / receivables
- ❌ VAT
- ❌ Suppliers
- ❌ Multi-currency
- ❌ Payment tracking
- ❌ Architecture rewrite

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Existing invoices lose customer reference | System customer auto-linked in migration |
| Invoice screen requires customer selection | Auto-selects first available customer on screen load |
| Archived customers break invoice display | customerName snapshot preserved on invoice at creation |
| Clean start wipes customer data | customers added to transactionalTables (wiped + preserved) |

## 8. Files Not Changed (Guardrails Respected)

- `app/lib/licensing/entitlement_token.dart` — No licensing redesign
- `app/lib/screens/admin/roles_permissions_screen.dart` — No new permissions
- `app/lib/services/standalone_backup_service.dart` — Backup unchanged
- Platform generated files (linux/macos/windows) — Not part of T4-1

## 9. Commit Details

```
601bff6 feat(customers): implement T4-1 customer master
 16 files changed, 1497 insertions(+), 108 deletions(-)
 create mode 100644 app/lib/models/customer.dart
 create mode 100644 app/lib/screens/customers/customers_screen.dart
 create mode 100644 app/test/database/customer_master_test.dart
```
