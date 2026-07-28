# Code Integrity Audit — محل مؤمن

**Branch:** `codex/muaman-03-inventory-count-stock-reconciliation`
**Date:** 2026-07-28
**Last update:** MUAMAN-03 completed
**Scope:** All source files under `app/lib/` and `app/test/`

---

## Progress

| Phase | Status | Outcome |
|-------|--------|---------|
| MUAMAN-01 | ✅ Completed | Audit / Scope freeze |
| MUAMAN-02 | ✅ Completed | C2 — Atomic Sale + Stock Decrement (Outcome A) |
| MUAMAN-03 | ✅ Completed | C1 — Inventory Count Application (Outcome A) |

---

## Critical Issues

### C1. Inventory counts are recorded but never applied to stock [FIXED]

**Fixed in MUAMAN-03.** `saveInventoryCount()` now wraps the count insert and product update in a single `db.transaction()` with optimistic locking. The inventory equation is always maintained. 10 new tests verify reconciliation, rollback, and edge cases.

**Modified files:**
- `app/lib/database/database_helper.dart` — `saveInventoryCount()` rewritten
- `app/lib/screens/inventory_count/inventory_count_screen.dart` — `isSaving` guard, error handling, DB-authoritative diff

**Tests:** `test/database/inventory_count_transaction_test.dart` — 10/10 passing

### C2. Sale insertion and stock decrement are not atomic [FIXED]

`sales_screen.dart:319-328` calls `insertSale()` on line 319 and `updateProductQuantity()` is called from `insertSale`'s internals — wait, let me re-check. Actually `insertSale` does NOT update product quantity. Let me check DatabaseHelper.insertSale again.

Looking at `database_helper.dart:135-155`:

```dart
Future<int> insertSale(Sale sale) async {
  final db = await database;
  return await db.insert('sales', sale.toMap());
}

Future<void> updateProductQuantity(int productId, int newQuantity) async {
  final db = await database;
  await db.update(
    'products',
    {'current_quantity': newQuantity},
    where: 'id = ?',
    whereArgs: [productId],
  );
}
```

These are two separate methods. In `sales_screen.dart:319-328`:

```dart
await DatabaseHelper.instance.insertSale(sale);
// No explicit call to updateProductQuantity here!
```

Wait — actually I need to re-read the sales screen code more carefully. Lines 319-328:

```dart
await DatabaseHelper.instance.insertSale(
  Sale(
    date: selectedDate,
    productName: selectedProduct!.name,
    barcode: selectedProduct!.barcode,
    quantity: qty,
    salePrice: price,
    costPrice: selectedProduct!.costPrice,
  ),
);
if (context.mounted) Navigator.pop(context);
_loadData();
```

There's NO call to `updateProductQuantity` after `insertSale`. So **selling a product does NOT decrement stock at all**. This is the most critical bug.

- **Files:** `database_helper.dart:135-155`, `sales_screen.dart:319-328`
- **Impact:** `current_quantity` in the products table is never decremented when a sale is made. The inventory becomes completely inaccurate from the very first sale.

**FIX REQUIRED:** `insertSale()` must be wrapped in a transaction that both inserts the sale row AND decrements `products.current_quantity`.

### C3. No DB-level referential integrity

- No foreign key constraints on any table.
- If a product is deleted (`database_helper.dart:89-97`), its `sales` and `inventory_counts` rows become orphaned with no cleanup.
- The `sale_items` table exists in the schema (`database_helper.dart:46-55`) but is **never written to or read by any code** — it is dead schema.

---

## Moderate Issues

### M1. No price validation

- `sales_screen.dart:309` — only rejects `qty <= 0`; a sale with `price = 0` is accepted, producing zero `totalSaleValue` and breaking profit calculations.
- `products_screen.dart` — the add product dialog does not validate `costPrice > 0`.

### M2. No negative-stock guard at the DB layer

Only the UI (`sales_screen.dart:312-316`) checks `qty > currentQuantity`. A concurrent request, direct DB write, or future code path can oversell without any CHECK constraint or trigger at the SQLite level.

### M3. Race condition in sale dialog

`_showAddSaleDialog` captures `_products` at dialog-open time (line 215: `_products.where((p) => p.currentQuantity > 0)`). If another sale is completed while the dialog is open, the stale list may still show a now-depleted product as available.

### M4. Product cost price can be zero

`products_screen.dart` — adding/editing a product does not enforce `costPrice > 0`. Zero cost → zero COGS → infinite profit margin in reports.

---

## Minor Issues

### m1. No input sanitization

Product names and barcodes are not `.trim()`-ed before insert. Leading/trailing whitespace can cause duplicate-name bugs and barcode lookup failures.

### m2. No unique constraint on barcode

Only checked in UI before insert. Two concurrent inserts or a direct DB write could create duplicate barcodes.

### m3. `sale_items` table is dead code

Created in `_onCreate` (line 46-55) but never referenced elsewhere. This wastes schema space and confuses future developers.

### m4. Widget test is default Flutter boilerplate

`widget_test.dart` contains the counter-app smoke test from `flutter create`. It imports `muaman_store/main.dart` which has no counter — the test will fail immediately.

### m5. Sale model has redundant computed properties

`sale.dart:24-25` defines `computedTotalSaleValue` and `computedCogs` as getters, but `toMap()` on lines 35/37 computes these values eagerly into `totalSaleValue`/`cogs`. The getters are dead code; the map fields duplicate what could be derived.

---

## Summary

| Tier | Count | Criticality |
|------|-------|-------------|
| Critical (open) | 1 | C3 — No FK / referential integrity |
| Critical (fixed) | 2 | C1 (MUAMAN-03), C2 (MUAMAN-02) |
| Moderate | 4 | Zero-price sales, no DB guards, race conditions, zero cost |
| Minor | 5 | Sanitization, uniqueness, dead code, tests, redundant model |

**Next recommended phase:** Re-evaluate remaining findings by actual impact — zero price, zero cost, barcode uniqueness, returns path, orphan records.
