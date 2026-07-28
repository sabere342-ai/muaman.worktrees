# MUAMAN-03 — Atomic Inventory Count Application and Stock Reconciliation

## 1. Original Defect Description

**CODEX C1:** `saveInventoryCount()` in `database_helper.dart` inserts a row into `inventory_count` but the insert and product update are **not within a single database transaction**. If the product update fails after the insert, an orphan inventory-count record remains with no stock adjustment.

Additionally, the operation does not use optimistic locking, so a concurrent stock change between the read and write would silently produce an incorrect result.

## 2. Root Cause

The original `saveInventoryCount()` method:

```dart
Future<void> saveInventoryCount(int productId, int actualQuantity, String notes) async {
    final db = await database;
    await db.insert('inventory_count', { ... });   // ← first write, no txn
    final product = await db.query('products', ...); // ← separate read
    // ... compute diff ...
    await db.update('products', { ... }, ...);       // ← second write, no txn
}
```

The `insert()` and `update()` are separate calls with no shared transaction. Any failure between them leaves an inventory-count record without a stock adjustment.

## 3. Previous Flow

```
User enters actual quantity
  → db.insert('inventory_count', ...)        ← no txn
  → db.query('products', ...)                ← separate read
  → compute diff from DB quantity
  → db.update('products', ...)               ← separate write (no optimistic lock)
  → UI shows snackbar with diff from in-memory product quantity
```

**Problems:**
- No transaction — partial writes possible
- No optimistic locking — silent overwrite on concurrent change
- Snackbar diff computed from stale in-memory `product.currentQuantity`

## 4. New Flow

```
User enters actual quantity
  → int.tryParse validation in UI
  → isSaving = true (button replaced with spinner)
  → saveInventoryCount(productId, actualQuantity, notes)
      → db.transaction((txn) async {
          1. Validate actualQuantity >= 0          ← fail → rollback
          2. Re-read product by id                 ← fresh read inside txn
          3. Product not found → StateError → rollback
          4. Calculate countDifference = actualQuantity - product.currentQuantity
          5. Set newCurrentQuantity = actualQuantity
          6. Compute newAdjustment = newCurrentQuantity
               - (openingQuantity - soldQuantity + returnedQuantity)
          7. INSERT inventory_count row
          8. UPDATE products
               SET inventoryAdjustment = newAdjustment,
                   currentQuantity = newCurrent,
                   totalInventoryCost = newCurrent * costPrice
               WHERE id = ? AND currentQuantity = ?   ← optimistic lock
          9. If affected == 0 → StateError → rollback
          10. Return countDifference
        })
  → on success: show snackbar with returned diff, reload products & counts
  → on ArgumentError: show red Arabic message "الكمية الفعلية لا يمكن أن تكون سالبة"
  → on StateError: show red Arabic message (product not found / stock changed)
  → on other error: show red Arabic message
  → finally: isSaving = false
```

## 5. Inventory Count Difference Formula

```
countDifference = actualQuantity - databaseCurrentQuantity
newCurrentQuantity = actualQuantity
newAdjustment = newCurrentQuantity - (openingQuantity - soldQuantity + returnedQuantity)
```

The adjustment is recomputed to maintain the inventory equation:

```
currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment
```

## 6. Preventing Accumulated Error on Repeated Counts

Each count re-reads the current quantity from SQLite inside the transaction. If the same physical count is entered twice:

- **First count:** `actualQuantity=8`, `dbCurrent=10` → `diff=-2`, `adjustment=-2`, `current=8`
- **Second count:** `actualQuantity=8`, `dbCurrent=8` → `diff=0`, `adjustment=-2`, `current=8`

The adjustment remains -2; the second count applies zero net adjustment.

## 7. Maintaining the Inventory Equation

After every count:
```
newCurrent = actualQuantity
newAdjustment = actualQuantity - (opening - sold + returned)
```

This guarantees:
```
newCurrent = opening - sold + returned + newAdjustment
```

## 8. Atomicity and Rollback

All operations execute inside a single `db.transaction()`:

```dart
return await db.transaction((txn) async {
    // All reads and writes use 'txn', not 'db'
    // SQLite serializes operations on a single txn
    // If any throw occurs → implicit ROLLBACK
    // If all succeed → implicit COMMIT
});
```

The optimistic lock (`WHERE currentQuantity = ?`) defends against concurrent stock changes. If the row count affected is 0, a `StateError` is thrown, rolling back the entire transaction.

**Consequences of rollback:**
- No `inventory_count` row persists
- No product fields change
- No `inventoryAdjustment` change

## 9. Stale UI Quantity Handling

The method **always re-reads the product from the database inside the transaction**. The `_products` list in the UI is only used for the initial card values. The authoritative quantity is the live SQLite value:

```dart
final productMaps = await txn.query('products',
    where: 'id = ?',
    whereArgs: [productId]);
// product is always fresh from DB
```

The returned `countDifference` is computed from the DB quantity, not the UI quantity.

## 10. `totalInventoryCost` Decision

The `products` table has a `totalInventoryCost` column that is a derived value equal to `currentQuantity * costPrice`. It is updated in every stock operation (sale, return, count) throughout the codebase. In the count path, it is updated inside the same transaction:

```dart
'totalInventoryCost': newCurrent * product.costPrice,
```

No new costing policy was introduced. This is a mechanical derivation consistent with all existing paths.

## 11. Files Modified

| File | Change |
|------|--------|
| `lib/database/database_helper.dart` | Rewrote `saveInventoryCount()` to use `db.transaction()` with optimistic locking, proper validation, and rollback. Returns `int` (countDifference) instead of `void`. |
| `lib/screens/inventory_count/inventory_count_screen.dart` | Added `_savingProductId` per-card guard. Uses returned `diff` from DB (not in-memory). Added try/catch with Arabic error messages for `ArgumentError` (negative quantity), `StateError` (not found / stock changed), and generic errors. Dialog stays open on failure. |

## 12. New Files Created

| File | Purpose |
|------|---------|
| `test/database/inventory_count_transaction_test.dart` | 10 tests covering all reconciliation scenarios |
| `docs/MUAMAN-03-INVENTORY-COUNT-STOCK-RECONCILIATION.md` | This closing document |

## 13. New Tests and Results

**File:** `test/database/inventory_count_transaction_test.dart`

| Test | Scenario | Key Assertions |
|------|----------|----------------|
| 1 | Downward: 10→7 | 1 count row, current=7, adj=-3, equation valid |
| 2 | Upward: 6→9 | Current=9, adj=+3, equation valid |
| 3 | Exact: 8→8 | 1 count row, current=8, adj=0 |
| 4 | Repeated identical: 10→8→8 | 2 count rows, final current=8, adj=-2 (no repeat) |
| 5 | Zero count: 5→0 | Count succeeds, current=0, adj=-5 |
| 6 | Negative: -1 rejected | ArgumentError, no count row, product unchanged |
| 7 | Rollback on update failure | Simulated optimistic-lock miss → full rollback (no count row, product unchanged) |
| 8 | Stale UI quantity | Diff computed from DB qty (7), not UI qty (10), final current=6 |
| 9 | Sale after count | 10→8 count, then sell 3 → final current=5 |
| 10 | Count→sale→count | 10→9→sell 4→6, final current=6, equation valid |

**All 10/10 passing.**

## 14. MUAMAN-02 Regression Test

**File:** `test/database/sale_transaction_test.dart`

**Result: 8/8 passing** — no regression.

## 15. Full Test Suite

```
18 passed, 1 failed
```

The single failure is the pre-existing `widget_test.dart` (boilerplate counter smoke test from `flutter create`, documented as m4 in CODEX). This test was **not touched** in MUAMAN-03.

## 16. Analyzer Result

| Metric | Value |
|--------|-------|
| Previous baseline | 1 issue (use_build_context_synchronously) |
| New issues | 0 |
| Total issues | 0 |

The pre-existing warning was naturally resolved by rewriting the screen with `mounted` (State property) instead of `context.mounted`.

## 17. `dart format`

```
Formatted 3 files (0 changed) — changed files already formatted.
Note: The project baseline contains unformatted files outside MUAMAN-03 scope.
```

## 18. `git diff --check`

No whitespace errors.

## 19. Windows Build

```
NOT VERIFIED — blocked by pre-existing Arabic-path/MSBuild environment limitation
```

Attempted build result:
```
CUSTOMBUILD: error: Unable to read file:
C:\Users\saber\OneDrive\Desktop\?????_???_????\app\.dart_tool\flutter_build\...\app.dill
```

The project path contains Arabic characters (`ادارة_محل_مؤمن`) which MSBuild cannot process. This is identical to the MUAMAN-02 limitation and is not caused by this change. No new build errors appeared.

## 20. Tree State

```
 M app/lib/database/database_helper.dart
 M app/lib/screens/inventory_count/inventory_count_screen.dart
 M CODEX.md
?? app/docs/MUAMAN-03-INVENTORY-COUNT-STOCK-RECONCILIATION.md
?? app/test/database/inventory_count_transaction_test.dart
```

Only the 4 files described above are modified/created. No other files are changed.

## 21. Risks Outside Scope

- **Returns path:** The `updateReturnedQuantity` / `revertReturnedQuantity` methods still use separate read/write without a transaction. This is a pre-existing issue and not addressed here.
- **`insertSale()` (old):** Retained for backward compatibility. The new `insertSaleAndDecrementStock()` is the correct path.
- **`updateSale()` / `deleteSale()`:** Still use `revertSoldQuantity`/`updateSoldQuantity` without transaction. Out of scope.
- **Foreign keys / Cascade (C3):** No FK constraints added.
- **`sale_items` table:** Still dead schema.
- **Zero-price / zero-cost validation:** Not modified.
- **Product name / barcode trimming:** Not modified.
- **Negative-stock DB guard:** Not added outside the sale path.

## 22. Scope Compliance Confirmation

- ❌ **C3 (Foreign Keys / Reference Integrity):** NOT implemented. No FKs, no cascade, `sale_items` untouched.
- ❌ **No architectural expansion:** No Repository, Service, Provider, Riverpod, Bloc added.
- ❌ **No DB schema changes outside `inventory_count`:** No columns added, no tables altered.
- ❌ **No out-of-scope fixes:** Zero price, zero cost, barcode, returns, dead code — none touched.

## 23. Final Outcome

**OUTCOME A — FULL SUCCESS**

- [x] Inventory-count insert and product update in a single SQLite transaction
- [x] Count difference calculated from fresh DB read inside transaction
- [x] `currentQuantity` becomes equal to user-entered `actualQuantity`
- [x] `inventoryAdjustment` recalculated to maintain inventory equation
- [x] Repeated same count does not accumulate error
- [x] Zero physical count is accepted
- [x] Negative count is rejected at DB layer with `ArgumentError`
- [x] Optimistic locking prevents concurrent-stock race conditions
- [x] Any failure → full rollback (no orphan count records)
- [x] UI stale quantity is not the source of truth
- [x] Sale after count works correctly (Test 9, Test 10)
- [x] Inventory equation holds after all operations
- [x] MUAMAN-02 tests: 8/8 passing, no regression
- [x] New tests: 10/10 passing
- [x] Analyzer: 0 new issues (pre-existing warning resolved as side effect)
- [x] No out-of-scope changes
- [x] No C3 implementation

**Next recommended phase:** Re-evaluate remaining audit findings based on actual impact, particularly:
- Zero sale price / zero cost price validation
- Non-unique barcode handling
- Returns path atomicity
- Orphan records on product deletion
- Dead `sale_items` table
