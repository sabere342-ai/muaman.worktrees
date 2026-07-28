# MUAMAN-05 — Zero Price and Zero Cost Validation (P1 Accounting)

## 1. Objective

Add two small, focused guards in the UI layer to:
- Reject zero or negative sale price before any sale record is created or inventory is modified.
- Reject zero or negative cost price before any product is inserted or updated.

## 2. Branch and Starting HEAD

| Field | Value |
|-------|-------|
| Branch | `codex/muaman-05-zero-price-zero-cost-validation` |
| Starting HEAD | `e178270` (MUAMAN-04) |
| Final commit | `fc08437` |

## 3. Governing Business/Accounting Decision

1. Sale price must be **greater than zero**.
2. Product cost price must be **greater than zero**.
3. Free samples, gifts, or promotional items at zero price are **out of scope** and require a separate accounting workflow.
4. The guard is a **hard reject** (not a warning).

**Rationale:**
- A zero-price sale generates zero revenue with positive COGS, producing a loss that misrepresents a real transaction and distorts profitability reports.
- Zero cost produces undefined/infinite profit margins and misleading accounting reports.

## 4. Files Modified

| File | Change | Reason |
|------|--------|--------|
| `lib/screens/sales/sales_screen.dart` | +13 lines | UI-level guard for zero/negative sale price |
| `lib/screens/inventory/inventory_screen.dart` | +13 lines | UI-level guard for zero/negative cost price |
| `lib/database/database_helper.dart` | +9 lines | Defense-in-depth validation at DB layer (consistent with existing quantity checks) |
| `test/database/sale_transaction_test.dart` | +41 lines | 3 new tests for zero/negative/positive sale price |
| `test/exploratory/barcode_and_deletion_test.dart` | ±28 lines | Updated existing zero-price test to expect rejection |
| `test/database/product_validation_test.dart` | +85 lines | **New file**: 6 tests for zero/negative/positive cost price (insert + update) |

Additional files formatted by `dart format` (cosmetic only): `data_importer.dart`, `main.dart`, `dashboard_screen.dart`, `expenses_screen.dart`, `returns_screen.dart`, `sales_report_screen.dart`.

## 5. Defect Before Fix

- **Sales screen**: The `_showAddSaleDialog` handler parsed `price` via `double.tryParse` (defaulting to `0` on parse failure) and passed it directly to `insertSaleAndDecrementStock` without checking `price <= 0`. A zero or negative price would create a sale record with `salePrice=0`, decrement stock, and generate COGS — producing a financial distortion.
- **Inventory screen**: The `_showAddEditDialog` handler parsed `costPrice` via `double.tryParse` (defaulting to `0` on parse failure) and passed it directly to `insertProduct`/`updateProduct` without checking `costPrice <= 0`. A zero or negative cost would be persisted.
- **Database layer**: `insertSaleAndDecrementStock` already validated quantity but not price. `insertProduct` and `updateProduct` had no validation at all.

## 6. How Zero/Negative Sale Price Is Prevented

### UI-level (sales_screen.dart:316-322)
After parsing `price` and checking `qty <= 0`, a new check `if (price <= 0)` shows a SnackBar with the message `'يجب أن يكون سعر البيع أكبر من صفر'` and returns early — before `isSaving` is set to `true` and before any DB call.

### DB-level (database_helper.dart:249-253)
In `insertSaleAndDecrementStock`, after the existing quantity check, a new check `if (sale.salePrice <= 0)` throws `ArgumentError('يجب أن يكون سعر البيع أكبر من صفر')`. Since this runs inside a transaction, any partial state is rolled back.

### Proof that rejection happens before writing
At the UI level, the guard is positioned **before** `setDialogState(() => isSaving = true)` and **before** the `try` block that calls `insertSaleAndDecrementStock`. At the DB level, the guard runs **before** `txn.insert('sales', ...)`, so no sale record, stock change, or COGS entry is ever created.

## 7. How Zero/Negative Cost Price Is Prevented

### UI-level (inventory_screen.dart:227-233)
After parsing `costPrice` and checking `nameController.text.isEmpty`, a new check `if (costPrice <= 0)` shows a SnackBar with the message `'يجب أن تكون تكلفة الصنف أكبر من صفر'` and returns early — before any DB call for both **add** and **edit** paths.

### DB-level (database_helper.dart:109-111, 136-138)
- `insertProduct`: throws `ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر')` if `product.costPrice <= 0`.
- `updateProduct`: throws `ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر')` if `product.costPrice <= 0`.

### Proof that rejection happens before writing
At the UI level, the guard returns before any `DatabaseHelper` call. At the DB level, both `insertProduct` and `updateProduct` check the cost price as their **first operation** before any database write.

## 8. New Tests

| Test File | Test Name | What It Verifies |
|-----------|-----------|------------------|
| `sale_transaction_test.dart` | Test 9: Zero sale price is rejected | `insertSaleAndDecrementStock` with `salePrice=0` throws `ArgumentError`; no sale record; stock unchanged |
| `sale_transaction_test.dart` | Test 10: Negative sale price is rejected | `insertSaleAndDecrementStock` with `salePrice=-50` throws `ArgumentError`; no sale record; stock unchanged |
| `sale_transaction_test.dart` | Test 11: Positive sale price still accepted | `insertSaleAndDecrementStock` with `salePrice=100` succeeds; sale record created; stock decremented |
| `barcode_and_deletion_test.dart` | Zero sale price is rejected | Updated existing test from "accepted" to "rejected" behavior |
| `product_validation_test.dart` | Zero cost price is rejected | `insertProduct` with `costPrice=0` throws `ArgumentError`; no product created |
| `product_validation_test.dart` | Negative cost price is rejected | `insertProduct` with `costPrice=-50` throws `ArgumentError`; no product created |
| `product_validation_test.dart` | Positive cost price is accepted | `insertProduct` with `costPrice=150` succeeds |
| `product_validation_test.dart` | Update with zero cost price is rejected | `updateProduct` with `costPrice=0` throws `ArgumentError`; original data unchanged |
| `product_validation_test.dart` | Update with negative cost price is rejected | `updateProduct` with `costPrice=-20` throws `ArgumentError`; original data unchanged |
| `product_validation_test.dart` | Update with positive cost price is accepted | `updateProduct` with `costPrice=200` succeeds; data updated |

**Total new tests: 9** (3 in sale_transaction_test, 1 updated in barcode_and_deletion_test, 6 in new product_validation_test).

## 9. Focused Tests Results

| Suite | Tests | Result |
|-------|-------|--------|
| `sale_transaction_test.dart` | 11 | **11/11 passing** |
| `product_validation_test.dart` | 6 | **6/6 passing** |
| `barcode_and_deletion_test.dart` | 5 | **5/5 passing** |
| `inventory_count_transaction_test.dart` | 10 | **10/10 passing** |

## 10. Regression Tests Results

| Suite | Tests | Result |
|-------|-------|--------|
| All database tests (focused) | 32 | **32/32 passing** |
| `widget_test.dart` | 1 | 1 failure (pre-existing — boilerplate smoke test broken before this phase) |

## 11. Analyzer

```
Analyzing app...
No issues found.
```

## 12. Formatting

`dart format` ran successfully. 19 files checked, 10 formatted (mostly cosmetic whitespace in unrelated files).

## 13. `git diff --check`

No whitespace errors found. Only CRLF normalization warnings (expected on Windows).

## 14. Windows Build

**NOT VERIFIED** — blocked by pre-existing Arabic-path/MSBuild environment limitation (same as MUAMAN-02, MUAMAN-03, MUAMAN-04).

## 15. Scope Boundaries

### In scope
- UI-level zero/negative sale price guard in `sales_screen.dart`
- UI-level zero/negative cost price guard in `inventory_screen.dart`
- DB-level defense-in-depth validation in `database_helper.dart`
- Tests for all of the above

### Out of scope (explicitly excluded)
- No schema migration
- No database table changes
- No backup format changes
- No gift/sample/free-item workflow
- No new transaction types
- No COGS calculation changes
- No profit margin calculation changes
- No negative inventory policy changes
- No product deletion safety
- No wide refactoring
- No mass renaming
- No unnecessary design changes
- No dependency additions
- No generated file modifications
- No bug fixes unrelated to this phase

## 16. Future Notes on Gift/Sample Workflow

Free samples, promotional items, and zero-price sales are **not supported** in this phase. If required in the future, they need an independent accounting workflow that:
- Preserves inventory cost
- Clearly classifies the transaction type (gift, sample, promotion)
- Does not distort revenue or COGS reports
- Is explicitly scoped and authorized in a separate phase

## 17. Schema or Migration Changes

**No.** No tables, columns, or constraints were added, removed, or altered.

## 18. Push or Tag

**No.** No `git push` or `git tag` was executed.

## 19. Final Commit

```
MUAMAN-05: reject zero sale price and product cost
```

## 20. Tree State

Final tree is clean. No untracked or uncommitted files.

## 21. Outcome

**Outcome A — FULL SUCCESS**

All acceptance criteria met:
- [x] Zero/negative sale price rejected before any permanent write
- [x] Zero/negative cost price rejected before any permanent write
- [x] Arabic error messages displayed
- [x] No partial stock/accounting changes on rejection
- [x] Positive prices and costs still accepted
- [x] No schema or migration changes
- [x] No out-of-scope changes
- [x] Focused tests: 32/32 passing
- [x] Analyzer: no issues
- [x] Formatter: clean
- [x] `git diff --check`: clean
- [x] Tree is clean after final commit
- [x] No push or tag executed

## 22. Residual Risk

No significant residual risk. The guards at both UI and DB layers provide defense in depth. The DB-layer validation in `insertSaleAndDecrementStock` runs inside a transaction, so even if called directly (bypassing UI), any partial state is rolled back on failure.

## 23. Next Phase Recommendation

Consider a phase for **Product Deletion Safety** (prevent deletion of products with existing sales/returns history, or require confirmation with impact summary). This was identified in MUAMAN-04 as a potential future scope but remains unaddressed.
