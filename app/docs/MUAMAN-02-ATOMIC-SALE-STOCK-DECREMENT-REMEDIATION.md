# MUAMAN-02 — Atomic Sale Recording and Stock Decrement Remediation

## 1. Original Defect Description

**CODEX C1 (revised):** The `insertSale()` method in `database_helper.dart` inserted a sale row and then called `updateSoldQuantity()` as two separate async operations **outside a database transaction**. While stock **was** being decremented (contrary to the initial CODEX claim), the lack of atomicity meant:

- A crash between `INSERT` and `UPDATE` would leave an orphan sale with no stock change.
- Two concurrent sales of the same product could cause a lost update (both read the same `soldQuantity`, both write, one overwrites the other).
- No stock validation existed at the DB layer — the UI's stale `_products` list was the only guard against overselling.

## 2. Root Cause

The original `insertSale()` method:

```dart
Future<int> insertSale(Sale sale) async {
    final db = await database;
    final id = await db.insert('sales', sale.toMap()..remove('id'));
    await updateSoldQuantity(sale.barcode, sale.quantity);
    return id;
}
```

`updateSoldQuantity` is a separate method that itself does a read → compute → write outside any transaction. Each call to `getDatabase()` returns a new `Database` reference (`await database` is a no-op if `_database` is already set, but critically: no `txn` object is shared).

## 3. Previous Flow

```
UI button press
  → UI validates: selectedProduct != null, qty > 0, qty <= selectedProduct.currentQuantity (stale)
  → insertSale(sale)
      → db.insert('sales', ...)             ← no txn
      → updateSoldQuantity(barcode, qty)
          → getProductByBarcode(barcode)    ← separate read
          → compute newSold, newCurrent
          → db.update('products', ...)      ← separate write
  → Navigator.pop()
  → _loadData()
```

## 4. New Flow

```
UI button press
  → UI validates: selectedProduct != null, qty > 0 (UX hint only)
  → isSaving = true (button disabled, spinner shown)
  → insertSaleAndDecrementStock(sale)
      → db.transaction((txn) async {
          1. Validate qty > 0             ← fail fast
          2. Read product by barcode       ← fresh read inside txn
          3. Insert sale row               ← first write
          4. Validate stock >= qty         ← fail → rollback
          5. UPDATE products
             SET soldQuantity += qty,
                 currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment,
                 totalInventoryCost = newCurrent * costPrice
             WHERE id = ? AND currentQuantity >= ?  ← optimistic lock
          6. If affected == 0 → throw → rollback
          7. Return sale id
        })
  → on success: Navigator.pop(), _loadData()
  → on StateError: show red SnackBar with arabic message
  → on other error: show red SnackBar with arabic message
  → finally: isSaving = false
```

## 5. Files Modified

| File | Change |
|------|--------|
| `lib/database/database_helper.dart` | Added `setTestDatabase()` static method for testability |
| `lib/database/database_helper.dart` | Added `insertSaleAndDecrementStock(Sale)` — full atomic transaction |
| `lib/screens/sales/sales_screen.dart` | Replaced `insertSale()` call with `insertSaleAndDecrementStock()` |
| `lib/screens/sales/sales_screen.dart` | Added `isSaving` flag — disables button, shows progress indicator |
| `lib/screens/sales/sales_screen.dart` | Added try/catch for `StateError` (insufficient stock, product not found) and generic errors |
| `lib/screens/sales/sales_screen.dart` | Dialog only closes on success, stays open on error |
| `test/database/sale_transaction_test.dart` | **New file** — 8 tests covering atomic sale behavior |

## 6. Atomicity Design

All sale + stock operations execute inside a single `db.transaction()`:

```dart
return await db.transaction((txn) async {
    // All reads and writes use 'txn', not 'db'
    // SQLite serializes all operations on a single txn
    // If any throw occurs → implicit ROLLBACK
    // If all succeed → implicit COMMIT
});
```

SQLite ensures that transactions on the same database connection are serialized. No other operation (even from the same isolate) can interleave writes within this transaction. This solves both the crash-orphan problem and the lost-update race condition.

## 7. Negative Stock Prevention

**Three layers of protection:**

| Layer | Location | Behavior |
|-------|----------|----------|
| UX hint | UI autocomplete filter | Hides products with `currentQuantity == 0` (stale, non-authoritative) |
| DB read check | Inside transaction | `product.currentQuantity < sale.quantity` → `StateError` → rollback |
| Optimistic update | `WHERE currentQuantity >= ?` | If stock changed between read and write (impossible in single txn, but defensive), update affects 0 rows → `StateError` → rollback |

## 8. Stale UI Quantity Handling

The method **always re-reads the product from the database inside the transaction**. The `_products` list in the UI is only used for the autocomplete filter (UX convenience). The authoritative stock validation happens against the live database value:

```dart
final productMaps = await txn.query('products',
    where: 'barcode = ?',
    whereArgs: [sale.barcode]);
// product is always fresh from DB
```

## 9. Inventory Field Policy

The products table has these inventory fields:

| Field | Role |
|-------|------|
| `openingQuantity` | Initial stock — never changed by sales |
| `soldQuantity` | Sum of all quantities sold → incremented by `sale.quantity` |
| `returnedQuantity` | Sum of returned quantities — unchanged by sales |
| `inventoryAdjustment` | Manual corrections (inventory count) — unchanged by sales |
| `currentQuantity` | Derived: `openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment` |

After a sale of quantity **Q**:

```
soldQuantity = soldQuantity + Q
currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment
```

The inventory equation remains valid by construction — `currentQuantity` is always recomputed from the component fields, not independently decremented.

Test 1 and Test 8 explicitly verify this equation.

## 10. New Tests

**File:** `test/database/sale_transaction_test.dart`

| Test | Scenario | Assertions |
|------|----------|------------|
| 1 | Stock 10, sell 3 | 1 sale row, stock=7, soldQty=3, equation holds |
| 2 | Stock 5, sell 5 | Sale succeeds, stock=0 |
| 3 | Stock 4, sell 5 | `StateError`, 0 sales, stock unchanged at 4 |
| 4 | Sell 0 | `ArgumentError`, no changes |
| 5 | Sell -1 | `ArgumentError`, no changes |
| 6 | Stock 5, sell 6 | `StateError`, sale rolled back (0 sales, stock=5) |
| 7 | Stale UI: DB stock=2, UI thinks 3 | `StateError`, sale rejected, stock=2 |
| 8 | Sell 4 then 3 from stock 10 | 2 sales, stock=3, soldQty=7, equation holds |

## 11. Verification Results

### `flutter analyze`
```
1 issue found: pre-existing warning in inventory_count_screen.dart (use_build_context_synchronously)
0 new issues.
```

### `flutter test` (8/8 tests)
```
All tests passed!
```

### `dart format --set-exit-if-changed`
```
3 files formatted (no remaining issues after formatting)
```

### `flutter build windows --release`
**FAILED** — Pre-existing environment limitation. The project path contains Arabic characters (`ادارة_محل_مؤمن`) which MSBuild cannot process. The `CUSTOMBUILD` error occurs because Visual Studio's build tools cannot read files at the garbled path `?????_???_????`. This is not caused by the change and would block any build from this directory on this machine.

### `git diff --check`
No whitespace errors.

## 12. Tree State

```
 M app/lib/database/database_helper.dart
 M app/lib/screens/sales/sales_screen.dart
?? CODEX.md                    (from MUAMAN-01, uncommitted)
?? app/test/database/          (new test file, uncommitted)
```

Only the 3 files described above are changed. No other files are modified.

## 13. Risks Outside Scope

- **Inventory counts (C2):** `saveInventoryCount()` still does not update product stock — not modified.
- **Foreign keys / Cascade (C3):** No FK constraints added — not modified.
- **`sale_items` table:** Still dead schema — not modified.
- **`insertSale()` (old):** Retained for backward compatibility. Not called anywhere in the codebase after this change, but kept to avoid breaking external callers.
- **`deleteSale()` / `updateSale()`:** Still use `revertSoldQuantity`/`updateSoldQuantity` without transaction. Deleting a sale could orphan a stock change if interrupted. **Out of scope for MUAMAN-02.**
- **Zero-price / zero-cost validation:** Not modified as instructed.
- **Product name / barcode trimming:** Not modified.

## 14. C2 and C3 Compliance Confirmation

- ❌ **C2 (Inventory Count Application):** NOT implemented. `saveInventoryCount()` unchanged.
- ❌ **C3 (Foreign Keys / Referential Integrity):** NOT implemented. No FKs, no cascade, `sale_items` untouched.

## 15. Final Outcome

**OUTCOME A — FULL SUCCESS**

- [x] Sale recording and stock decrement in a single transaction
- [x] No sale can be saved with insufficient stock
- [x] No negative stock possible through sale path
- [x] Any step failure → full rollback
- [x] Protection does not depend on stale UI state
- [x] Inventory fields remain consistent (equation validated)
- [x] All 8 new tests pass
- [x] No existing test regressions
- [x] Analyzer clean (0 new issues)
- [x] No out-of-scope changes

**Next recommended phase:** `MUAMAN-03 — Inventory Count Application and Stock Reconciliation`
