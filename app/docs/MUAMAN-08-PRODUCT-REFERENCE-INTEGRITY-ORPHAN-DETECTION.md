# MUAMAN-08: Product Reference Integrity & Orphan Detection

## Objective
Enforce product reference integrity across all write paths. Detect existing orphan records and prevent creation of new orphans through all data-layer write paths.

## Changes Made

### 1. New Exception Class
- **`ProductReferenceIntegrityException`** (`database_helper.dart:724-728`) — thrown when a write operation references a non-existent product.
- **`IntegrityIssueReport`** (`database_helper.dart:731-747`) — value object returned by the scan detector, reporting orphans found in `sales`, `returns`, and `inventory_count`.

### 2. Orphan Detector
- **`findProductReferenceIntegrityIssues()`** (`database_helper.dart:750-778`) — read-only scan that queries all three reference tables for rows pointing to missing products. Uses `NOT IN (SELECT ...)` subqueries for correctness.

### 3. Transactional Guards
- **`_requireExistingProductById(txn, productId)`** (`database_helper.dart:782-790`) — throws if product `id` missing.
- **`_requireExistingProductByBarcode(txn, barcode)`** (`database_helper.dart:794-802`) — throws if product `barcode` missing.
- Both run queries inside the active transaction so the check is atomic with the write.

### 4. Guarded Write Paths
| Method | Guard Added | Change |
|---|---|---|
| `insertSale()` | New transaction + barcode check | Previously non-transactional; stock update could silently no-op |
| `insertReturn()` | New transaction + barcode check | Previously non-transactional; stock update could silently no-op |
| `updateSale()` | Transaction + revert/apply in txn + barcode check | Previously non-transactional, partial-update risk |
| `updateReturn()` | Transaction + revert/apply in txn + barcode check | Previously non-transactional, partial-update risk |
| `insertSaleAndDecrementStock()` | Already guarded (MUAMAN-02) | Unchanged |
| `saveInventoryCount()` | Already guarded (MUAMAN-03) | Unchanged |
| `deleteProduct()` | Already guarded (MUAMAN-06) | Unchanged |

### 5. Test Suite — `product_reference_integrity_test.dart`
30 tests covering:
- Exception & report value-object semantics (4 tests)
- `findProductReferenceIntegrityIssues` detector (5 tests)
- `insertSale` guard: rejection, atomicity, valid path (4 tests)
- `insertReturn` guard: rejection, atomicity, valid path (4 tests)
- `updateSale` guard: rejection, no-partial-write, valid path (3 tests)
- `updateReturn` guard: rejection, valid path (2 tests)
- Existing guarded paths still work (3 tests)
- Transaction atomicity on guard rejection (2 tests)
- Defense in depth (2 tests)

## Design Decisions
1. **No schema changes, no migration, no cascade** — per constraint. All protection is at the data layer (`DatabaseHelper`).
2. **Product existence checks run inside the same transaction** as the write, guaranteeing atomicity. A rejected guard leaves zero side effects.
3. **`sales` and `returns` use `barcode` (snapshot)** not `productId`. The detector and guards match on `barcode`, which is the natural key visible in those tables.
4. **`updateSale()`/`updateReturn()`** revert old stock and re-apply new stock inside a single transaction. Previously these were three separate non-atomic operations.
5. **Arabic error messages** for end-user-facing exceptions (`ProductReferenceIntegrityException`).

## Test Results
```
91 passed, 1 failed (pre-existing widget_test — databaseFactory not initialized + counter mismatch, same as MUAMAN-07 baseline)
```
Full regression suite (MUAMAN-02/03/05/06/07 + MUAMAN-08): **zero regressions**.

## Files Modified
- `app/lib/database/database_helper.dart` — added exception, report class, detector, guards; refactored 4 write methods

## Files Created
- `app/test/database/product_reference_integrity_test.dart` — 30 tests
- `app/docs/MUAMAN-08-PRODUCT-REFERENCE-INTEGRITY-ORPHAN-DETECTION.md` — this report
