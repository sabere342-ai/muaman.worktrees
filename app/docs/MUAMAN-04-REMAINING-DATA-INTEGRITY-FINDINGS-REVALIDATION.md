# MUAMAN-04 — Remaining Data-Integrity Findings Revalidation

## 1. Executive Summary

MUAMAN-04 is a **revalidation and scope-freeze phase** with zero production-code changes. All 10 findings from the original MUAMAN-01 audit were re-examined with fresh evidence, exploratory tests, and source-code review.

**Key result:** 1 P1 finding confirmed, 4 P2 findings confirmed, 5 P3 findings confirmed. The single recommended next phase is zero-price and zero-cost validation.

## 2. Branch and Starting HEAD

| Field | Value |
|-------|-------|
| Branch | `codex/muaman-04-remaining-integrity-findings-revalidation` |
| Starting HEAD | `a271bf5` (MUAMAN-03) |
| Final commit | TBD |

## 3. Tree State

```
 M CODEX.md
?? app/docs/MUAMAN-04-REMAINING-DATA-INTEGRITY-FINDINGS-REVALIDATION.md
?? app/test/exploratory/barcode_and_deletion_test.dart
```

Only documentation and exploratory test files changed. No production code modified.

## 4. Core Test Results

| Suite | Result |
|-------|--------|
| MUAMAN-02 (sale_transaction_test.dart) | **8/8 passing** |
| MUAMAN-03 (inventory_count_transaction_test.dart) | **10/10 passing** |
| Full database tests | **18/18 passing** |
| Pre-existing widget_test.dart | 1 failure (boilerplate, unchanged) |

## 5. Analyzer

```
No issues found.
```

Same as MUAMAN-03 baseline.

## 6. Windows Build

```
NOT VERIFIED — blocked by pre-existing Arabic-path/MSBuild environment limitation
```

Identical to MUAMAN-02 and MUAMAN-03.

## 7. Findings Revalidation Table

### 7.1 Zero Sale Price

| Attribute | Value |
|-----------|-------|
| **Original ID** | M1 |
| **Still present?** | YES |
| **File:line** | `lib/screens/sales/sales_screen.dart:316` — `double.tryParse(priceController.text) ?? 0` |
| **Evidence** | UI accepts empty or 0 price. No `price > 0` guard (only `qty <= 0` guarded). DB layer has no CHECK constraint either. |
| **Impact scenario** | Sale with price=0: `totalSaleValue=0`, `cogs=quantity*costPrice` > 0. This produces a false loss entry in reports. Zero revenue with positive COGS misrepresents profit. |
| **Classification** | **P1 — Accounting Incorrectness** |
| **Requires business decision?** | YES — need to confirm whether zero-price sales (samples, gifts, promotions) are intentional. If yes, downgrade to P2 (warning/clarification needed). |
| **Requires migration?** | No |
| **Expected repair scope** | Add `price > 0` validation in `_showAddSaleDialog()` + optional DB CHECK constraint |

### 7.2 Zero Cost Price

| Attribute | Value |
|-----------|-------|
| **Original ID** | M4 |
| **Still present?** | YES |
| **File:line** | `lib/screens/inventory/inventory_screen.dart:227` — `double.tryParse(costController.text) ?? 0` |
| **Evidence** | No `costPrice > 0` validation. Seed data includes "تحزية" with `costPrice: 0.0`. Zero cost produces 100% profit margin in reports. |
| **Impact scenario** | Product with costPrice=0 → `cogs=0` for every sale → infinite gross profit margin. Distorts COGS, gross profit, and net profit calculations. |
| **Classification** | **P1 — Accounting Incorrectness** |
| **Requires business decision?** | YES — "تحزية" may be a legitimately zero-cost bundled item. Need policy: is zero cost allowed? For which products? |
| **Requires migration?** | No |
| **Expected repair scope** | Add `costPrice > 0` validation in add/edit dialog, or allow zero but flag it in reports |

### 7.3 Barcode Uniqueness

| Attribute | Value |
|-----------|-------|
| **Original ID** | m2 (originally claimed "No unique constraint") |
| **Still present?** | PARTIALLY — UNIQUE constraint EXISTS in schema |
| **File:line** | `lib/database/database_helper.dart:46` — `barcode TEXT UNIQUE NOT NULL` |
| **Evidence** | SQLite UNIQUE constraint is present and functional. Duplicate insert triggers `DatabaseException`. UI does NOT catch this exception — user sees an unhandled error. Barcode generator (`generateBarcode()`) uses `MAX(id)+1` which could theoretically collide but is unlikely. |
| **Impact scenario** | If duplicate is attempted via import or manual operation, DB rejects it with an unhandled error. No data corruption proven. |
| **Classification** | **P2 — Reliability** (unhandled exception in UI) |
| **Requires business decision?** | No |
| **Requires migration?** | No |
| **Expected repair scope** | Wrap `insertProduct()` in try/catch for `DatabaseException` and show user-friendly Arabic message. Or use INSERT OR IGNORE / ON CONFLICT. |

### 7.4 Foreign Keys

| Attribute | Value |
|-----------|-------|
| **Original ID** | C3 |
| **Still present?** | YES (but no proven corruption) |
| **Evidence** | `inventory_count` has FK syntax in DDL but `PRAGMA foreign_keys` is OFF. Sales/returns use denormalized `productName` + `barcode` (no FK). No actual orphan-related crash or data loss could be proven in testing. |
| **Classification** | **P3 — Maintainability** |
| **Requires business decision?** | No |
| **Requires migration?** | Would need `PRAGMA foreign_keys = ON` + data cleanup |
| **Expected repair scope** | Large — not recommended as next phase |

### 7.5 Cascade Deletes

| Attribute | Value |
|-----------|-------|
| **Original ID** | C3 (combined with FK) |
| **Still present?** | YES — no cascades exist |
| **Evidence** | No CASCADE, RESTRICT, or SET NULL on any table. Product deletion succeeds silently regardless of child records. This is actually **correct behavior** for historical financial records — cascade delete would destroy financial history. |
| **Classification** | **P3 — Design choice** (restrict deletion is preferred over cascade) |
| **Requires business decision?** | YES — should product deletion be prevented? Or should soft-delete be used? |
| **Expected repair scope** | Medium — prevent deletion or implement soft-delete |

### 7.6 `sale_items` Table

| Attribute | Value |
|-----------|-------|
| **Original ID** | m3 |
| **Still present?** | NO — NOT in current schema |
| **Evidence** | The current `_createDB()` does NOT include `sale_items`. It only creates 5 tables (products, sales, returns, expenses, inventory_count). The table was removed from the schema definition. It only exists as an empty orphan table on databases upgraded from version 1. |
| **Classification** | **P3 — Migration residue** (no impact, empty table) |
| **Requires business decision?** | No |
| **Requires migration?** | Would need DROP IF EXISTS in a future schema version |
| **Expected repair scope** | Add `DROP TABLE IF EXISTS sale_items` to `_onUpgrade` |

### 7.7 Product Deletion

| Attribute | Value |
|-----------|-------|
| **Original ID** | C3 |
| **Still present?** | YES |
| **File:line** | `lib/database/database_helper.dart:142-144` |
| **Evidence** | `deleteProduct()` deletes without referential check. Sales/returns persist (denormalized) — historical data is preserved. `inventory_count` records become orphaned (`productId` references deleted product). Barcode can be reused after deletion, creating a new identity with no connection to old records. |
| **Impact scenario** | Deleting a product with `inventory_count` records leaves orphaned `productId` values. These counts are no longer meaningful. Reusing barcode creates two sets of records sharing a barcode but belonging to different product identities. |
| **Classification** | **P2 — Reliability** (orphaned records, identity confusion) |
| **Requires business decision?** | YES — is product deletion intended to be allowed? Should it be prevented, or should it cascade? |
| **Requires migration?** | Would need to clean orphaned inventory_count records |
| **Expected repair scope** | Add check before delete: refuse if inventory_count references exist. Or add soft-delete column. |

### 7.8 Input Trimming

| Attribute | Value |
|-----------|-------|
| **Original ID** | m1 |
| **Still present?** | YES |
| **Files** | `inventory_screen.dart:188` (name), `inventory_screen.dart:197` (cost), `expenses_screen.dart:166` (description), `inventory_count_screen.dart:109` (count notes) |
| **Evidence** | No `.trim()` call on any TextField input. Space-padded barcode or name could bypass barcode uniqueness check and cause lookup failures. |
| **Impact scenario** | `"Product"` vs `" Product "` treated as different products. Barcode `"2000001 "` ≠ `"2000001"` in lookups. |
| **Classification** | **P3 — Maintainability** |
| **Requires business decision?** | No |
| **Requires migration?** | Would need data cleanup for existing entries |
| **Expected repair scope** | Add `.trim()` to all text-field reads + migration to clean existing data |

### 7.9 Broken Widget Test

| Attribute | Value |
|-----------|-------|
| **Original ID** | m4 |
| **Still present?** | YES |
| **File** | `test/widget_test.dart` |
| **Evidence** | Default `flutter create` counter-app smoke test. Imports `muaman_store/main.dart` which has no counter. Fails with `databaseFactory not initialized` + text-not-found errors. |
| **Classification** | **P3 — Test maintenance** |
| **Requires business decision?** | No |
| **Requires migration?** | No |
| **Expected repair scope** | Replace with a minimal widget test or delete the file |

### 7.10 Sale Computed Properties

| Attribute | Value |
|-----------|-------|
| **Original ID** | m5 |
| **Still present?** | YES but NOT a defect |
| **File** | `lib/models/sale.dart:24-25` |
| **Evidence** | `computedTotalSaleValue` and `computedCogs` are getters used by `toMap()` to ensure stored values are consistent at write time. `fromMap()` reads the stored values. These are not "redundant" — they serve a distinct purpose (computation at serialization time). No proven discrepancy between computed and stored values. |
| **Classification** | **P3 — Not a defect** |
| **Requires business decision?** | No |
| **Requires migration?** | No |
| **Expected repair scope** | None |

## 8. Priority Score Matrix

| Finding | Data Impact | Likelihood | Reachability | Repair Confidence | Migration Risk | Scope Size | Score |
|---------|:-----------:|:----------:|:------------:|:-----------------:|:--------------:|:----------:|:-----:|
| Zero sale price | P1 — 3 | 3 | 3 | 3 | 0 | 1 | **11** |
| Zero cost price | P1 — 3 | 3 | 3 | 3 | 0 | 1 | **11** |
| Product deletion | P2 — 2 | 3 | 3 | 2 | 1 | 2 | 7 |
| Barcode error handling | P2 — 1 | 2 | 2 | 3 | 0 | 1 | 7 |
| Input trimming | P3 — 1 | 2 | 2 | 3 | 1 | 3 | 4 |
| Widget test | P3 — 0 | 3 | 1 | 3 | 0 | 1 | 6 |
| sale_items cleanup | P3 — 0 | 1 | 1 | 3 | 1 | 1 | 3 |
| Computed properties | P3 — 0 | 0 | 1 | 1 | 0 | 1 | 1 |
| FK/Cascade | P3 — 1 | 1 | 1 | 2 | 3 | 4 | -2 |

## 9. Single Recommended Next Phase

### MUAMAN-05 — Zero Price and Zero Cost Validation

**Exact defect:** The sales screen accepts `salePrice = 0` and the inventory screen accepts `costPrice = 0`, producing incorrect accounting entries (P1).

**Allowed files:**
- `lib/screens/sales/sales_screen.dart` — add `price > 0` guard
- `lib/screens/inventory/inventory_screen.dart` — add `costPrice > 0` guard in both add and edit dialogs
- `lib/database/database_helper.dart` — optional DB CHECK constraint
- `test/database/` — new test file for price/cost validation
- `test/exploratory/barcode_and_deletion_test.dart` — may be relocated or removed

**Required tests:**
- Sale with `price = 0` → rejected
- Sale with `price > 0` → accepted
- Product creation with `costPrice = 0` → rejected (or warned)
- Product creation with `costPrice > 0` → accepted
- Product editing to `costPrice = 0` → rejected (or warned)
- Regression: MUAMAN-02 and MUAMAN-03 tests still pass

**Explicit exclusions:**
- No barcode changes
- No schema changes (optional CHECK constraint excluded) unless necessary
- No product deletion changes
- No returns path changes
- No sale_items changes
- No input trimming
- No widget test fix
- No FK/cascade

**Migration requirement:** None

**Business decision prerequisite:** Confirm whether zero-price sales (samples, gifts, promotions) and zero-cost products (bundled accessories like "تحزية") are intentionally allowed. If YES → add warning/clarification instead of hard reject. If NO → hard validation.

## 10. Compliance Confirmation

- [x] No production Dart files modified
- [x] No Foreign Keys added
- [x] No Cascade Deletes added
- [x] No sale_items changes
- [x] No schema changes
- [x] No returns path changes
- [x] No architectural expansion
- [x] No State Manager, Repository, or Service Layer added
- [x] No widget test fixed (out of scope)
- [x] No input trimming implemented (out of scope)
- [x] Single next phase identified: zero price/cost validation

## 11. Final Outcome

**OUTCOME A — SINGLE TARGET IDENTIFIED**

Next phase: **MUAMAN-05 — Zero Price and Zero Cost Validation**

The highest-priority proven defect is the acceptance of zero sale prices and zero cost prices, which directly produce incorrect accounting entries (P1 — Accounting Incorrectness). The fix is small, atomic, and does not require a database migration. It does require a business decision about whether zero values are ever legitimate.

**Fallback if blocked:** MUAMAN-05 redirected to Product Deletion Safety (prevent deletion when inventory_count references exist, P2).
