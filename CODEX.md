# Code Integrity Audit - مؤمن شوب

**Branch:** `codex/muaman-04-remaining-integrity-findings-revalidation`
**Date:** 2026-07-28
**Last update:** MUAMAN-04 completed
**Scope:** All source files under `app/lib/` and `app/test/`

---

## Progress

| Phase | Status | Outcome |
|-------|--------|---------|
| MUAMAN-01 | ✔ Completed | Audit / Scope freeze |
| MUAMAN-02 | ✔ Completed | C2 — Atomic Sale + Stock Decrement (Outcome A) |
| MUAMAN-03 | ✔ Completed | C1 — Inventory Count Application (Outcome A) |
| MUAMAN-04 | ✔ Completed | Revalidate 10 findings → Recommend zero price/cost validation (Outcome A) |

---

## Critical Issues

### C1. Inventory counts are recorded but never applied to stock [FIXED]

**Fixed in MUAMAN-03.** `saveInventoryCount()` now wraps the count insert and product update in a single `db.transaction()` with optimistic locking. The inventory equation is always maintained. 10 new tests verify reconciliation, rollback, and edge cases.

**Modified files:**
- `app/lib/database/database_helper.dart` — `saveInventoryCount()` rewritten
- `app/lib/screens/inventory_count/inventory_count_screen.dart` — `isSaving` guard, error handling, DB-authoritative diff

**Tests:** `test/database/inventory_count_transaction_test.dart` — 10/10 passing

### C2. Sale insertion and stock decrement are not atomic [FIXED]

**Fixed in MUAMAN-02.** `insertSaleAndDecrementStock()` wraps both operations in a single `db.transaction()` with optimistic locking and insufficient-stock guard. 8 new tests verify atomicity, rollback, and concurrent-sale safety.

**Modified files:**
- `app/lib/database/database_helper.dart` — added `insertSaleAndDecrementStock()` with transaction
- `app/lib/screens/sales/sales_screen.dart` — switched call to `insertSaleAndDecrementStock`

**Tests:** `test/database/sale_transaction_test.dart` — 8/8 passing

### C3. No FK referential integrity [MUAMAN-04: P3 — no proven corruption]

**Revalidated in MUAMAN-04.**
- No foreign key constraints enforced (PRAGMA foreign_keys OFF). This is **by design** for financial records: sales/returns use denormalized productName+barcode (no FK), so historical records survive product deletion.
- Product deletion (`database_helper.dart:142-144`) orphans `inventory_count` records (P2 — identified separately), but no cascade crashes or data loss were proven.
- `sale_items` table: **removed from current `_createDB` schema** (line 41 creates only 5 tables). Exists only as empty residue on databases upgraded from version 1.

---

## Moderate Issues

### M1. No price validation [P1 — Accounting Incorrectness]

**Revalidated in MUAMAN-04.** `sales_screen.dart:316` — `priceController.text` parsed via `double.tryParse(...) ?? 0`. No `price > 0` guard. A sale with `price=0` produces `totalSaleValue=0` while `cogs=quantity*costPrice > 0`, generating a false loss entry in reports.

**Proof:** Explorer test confirms zero-price sale is accepted.

### M2. No negative-stock guard at the DB layer [P3 — Defense in depth]

**Revalidated in MUAMAN-04.** The UI (`sales_screen.dart:312-316`) checks `qty > currentQuantity`, but there's no CHECK constraint or trigger at the SQLite level. The only DB-level guard is `insertSaleAndDecrementStock`'s optimistic lock (`WHERE currentQuantity >= ?`), which catches race conditions but not direct DB writes.

### M3. Race condition in sale dialog [P3 — Low likelihood]

**Revalidated in MUAMAN-04.** `_showAddSaleDialog` captures `_products` at dialog-open time (line 215: `_products.where((p) => p.currentQuantity > 0)`). If another sale completes while the dialog is open, the stale list may still show a now-depleted product as available. Proof-of-concept not executed but code path is clear.

### M4. Product cost price can be zero [P1 — Accounting Incorrectness]

**Revalidated in MUAMAN-04.** `inventory_screen.dart:227` — `costController.text` parsed via `double.tryParse(...) ?? 0`. No `costPrice > 0` validation in add or edit dialogs. Seed data includes "تحزية" with `costPrice: 0.0`. Zero cost → zero COGS → infinite/undefined gross profit margin.

**Proof:** Seed product "تحزية" explicitly has `costPrice: 0.0`.

---

## Minor Issues

### m1. No input sanitization [P3]

**Revalidated in MUAMAN-04.** No `.trim()` call in `inventory_screen.dart:188` (name), `inventory_screen.dart:197` (cost), `expenses_screen.dart:166` (description), `inventory_count_screen.dart:109` (count notes). Space-padded barcode/name could bypass uniqueness or cause lookup failures.

### m2. Barcode uniqueness [MUAMAN-04: PARTIALLY CORRECTED]

**MUAMAN-04 found: The UNIQUE constraint EXISTS** at `database_helper.dart:46` (`barcode TEXT UNIQUE NOT NULL`). The original CODEX claim "No unique constraint on barcode" was inaccurate — the constraint is in the DDL. However, the UI does NOT catch `DatabaseException` on duplicate insert, so the user sees an unhandled error.

### m3. `sale_items` table [MUAMAN-04: OUTDATED — removed from schema]

**MUAMAN-04 found: `sale_items` is NOT in current `_createDB`.** The schema (lines 41-104) creates only 5 tables: products, sales, returns, expenses, inventory_count. `sale_items` was dropped from schema between version 1 and 2. It only exists as empty residue on upgraded databases.

### m4. Widget test is default Flutter boilerplate [P3]

Unchanged since MUAMAN-01. `widget_test.dart` tests a counter app that doesn't exist in this project. Pre-existing failure.

### m5. Sale model computed properties [MUAMAN-04: NOT A DEFECT]

**MUAMAN-04 found: NOT redundant.** `computedTotalSaleValue` and `computedCogs` are getters that compute values at serialization time (`toMap()` uses them). They serve a distinct purpose: ensuring stored values are consistent at write time. No discrepancy between computed and stored values was found.

---

## Summary

| Tier | Count | Criticality |
|------|-------|-------------|
| Critical (fixed) | 2 | C1 (MUAMAN-03), C2 (MUAMAN-02) |
| Critical (open) | 0 | All reclassified in MUAMAN-04 |
| P1 — Accounting Incorrectness | 2 | M1 (zero sale price), M4 (zero cost price) |
| P2 — Reliability | 2 | Product deletion orphans, unhandled DB exception |
| P3 — Maintainability/Defense | 5 | Negative-stock guard, race condition, trimming, widget test, sale_items residue |

**Next recommended phase: MUAMAN-05 — Zero Price and Zero Cost Validation**

Highest-priority proven defect: acceptance of zero sale prices and zero cost prices producing incorrect accounting entries (P1). Fix is small and atomic. Requires business decision on whether zero values are ever legitimate (samples, gifts, bundled "تحزية").
