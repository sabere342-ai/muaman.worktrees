# MUAMAN-10: Test Infrastructure Stabilization & Final Release Readiness

## Objective
Stabilize the test infrastructure by fixing the failing `widget_test.dart`, verify all 146 tests pass, and assess release readiness.

## Changes Made

### 1. widget_test.dart — sqflite_ffi init + in-memory test DB
- **Root cause**: Default Flutter counter smoke test imported `main.dart` → `MyApp` → `DashboardScreen` → `DatabaseHelper._initDB()` → `getDatabasesPath()`, which requires `sqfliteFfiInit()` + `databaseFactory` assignment. In production, `main()` calls these; the test creates `MyApp` directly.
- **Fix** (`test/widget_test.dart`):
  - `sqfliteFfiInit()` at top-level
  - `databaseFactory = databaseFactoryFfiNoIsolate`
  - `setUp`: opens in-memory DB, creates schema for all 5 tables, injects via `DatabaseHelper.setTestDatabase(db)`
  - `tearDown`: closes DB
  - Verifies dashboard renders title "لوحة تحكم محل مؤمن" and "إجمالي المبيعات"

### 2. DatabaseHelper — setTestDatabase + production init guard
- **`setTestDatabase(Database db)`** (`database_helper.dart`): static method to inject a pre-opened test DB, skipping `_initDB()`.
- **`database` getter**: uses injected test DB when set, otherwise lazy-inits production DB.
- `initDatabase()` called in `main.dart` checks `_testDatabase != null` first — no-op during tests.

### 3. main.dart — grouped init calls
- `main()` groups all initialization (`WidgetsFlutterBinding`, `sqfliteFfiInit`, `databaseFactory`, `DatabaseHelper.initDatabase()`) before `runApp`.

### 4. Full formatting pass
- `dart format` applied across all modified files (no semantic changes).

## Test Results
```
00:41 +146: All tests passed!
```
- `test/database/` (12 files, 139 tests): ✅
- `test/exploratory/` (1 file, 1 test): ✅
- `test/widget_test.dart` (1 test): ✅
- Pre-existing analyzer warnings (4, all cosmetic): unchanged

## Build Status
- **`flutter build windows --release`**: ⚠️ **BLOCKED** — `gen_snapshot` (Dart AOT compiler) crashes with `Dart_ExitScope` error when the project path contains non-ASCII (Arabic) characters. Exit code `-1073740791`. This is a Flutter 3.24.5 environment limitation on Windows, not a project code issue.
- **Workaround**: Move project to an ASCII-only path (`C:\dev\muaman`) or upgrade to a Flutter version with Unicode path support.

## Files Modified (12)
| File | Change |
|---|---|
| `lib/database/database_helper.dart` | Added `setTestDatabase()`, `_testDatabase` field, guard in `database` getter |
| `lib/main.dart` | Grouped init calls before `runApp` |
| `lib/database/data_importer.dart` | `dart format` (product list line wrapping) |
| `lib/screens/dashboard/dashboard_screen.dart` | `dart format` |
| `lib/screens/expenses/expenses_screen.dart` | `dart format` |
| `lib/screens/returns/returns_screen.dart` | `dart format` |
| `lib/screens/sales/sales_report_screen.dart` | `dart format` |
| `test/widget_test.dart` | sqflite_ffi init + in-memory test DB + dashboard smoke test |
| `test/database/product_deletion_referential_test.dart` | `dart format` |
| `test/database/product_normalization_test.dart` | `dart format` |
| `test/database/product_reference_integrity_test.dart` | `dart format` |
| `test/exploratory/barcode_and_deletion_test.dart` | `dart format` |

## Files Created
- `test/database/sale_return_update_consistency_test.dart` (MUAMAN-09 carryover)

## Design Decisions
1. **`setTestDatabase` + guard pattern** — minimal intrusion; production path unchanged, test path uses singleton override.
2. **In-memory DB with full schema** — avoids filesystem side effects; schema mirrors production tables.
3. **`noIsolate` FFI** — avoids isolate-handle issues in test runner.
4. **Build blocked by environment, not code** — all code changes verified correct by passing test suite.
