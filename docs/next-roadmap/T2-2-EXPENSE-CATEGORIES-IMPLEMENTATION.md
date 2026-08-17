# T2-2 — Expense Categories

## Official Governance Report

### Outcome

**A — ACCEPTED / FOLLOW ROADMAP**

### Roadmap Alignment

**A — FOLLOW ROADMAP**

T2-2 is the third step in the recommended implementation sequence per `I-TECH-RISK-DEPENDENCY-MAP.md` line 155: "T2-2: Expense Categories (no dependencies, low risk)". The frozen roadmap at `2295137` documents GAP-08 as "No Expense Categories" with "New `category` column on `expenses`" as the schema change. The implementation follows this design exactly.

### Context Verification

```
Project:    I-TECH / إدارة محل مؤمن
Platform:   Flutter/Dart Windows Desktop
Worktree:   C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
Branch:     codex/i-tech-next-roadmap-freeze
Starting HEAD: a3dacd8
Frozen roadmap: 2295137
```

### Baseline Verification

```
Branch:       codex/i-tech-next-roadmap-freeze
Baseline:     a3dacd8 (T2-1 implementation)
Commit lineage:
  2295137  Frozen Next Roadmap
  ade506a  T1-1 Brand Color Consumption
  df17d17  T1-2 Standalone Backup/Restore Design Freeze
  a3dacd8  T2-1 Standalone Backup/Restore Implementation
  26cd605  T2-2 Expense Categories (CURRENT)
Merge commits above baseline: 0
Pre-existing working tree: 7 generated platform files (CRLF normalization noise)
```

### Discovery Findings

Pre-T2-2 expense architecture:
- `Expense` model: 4 fields (`id`, `date`, `description`, `amount`)
- `expenses` table: 4 columns, schema version 6
- No category field, no category model, no category CRUD
- CRUD: insert (permission-guarded), read (all), update (exists but unused in UI), delete (permission-guarded)
- Dashboard: `totalExpenses = SUM(amount)`, feeds `netProfit` calculation
- Backup/restore: full DB backup via VACUUM INTO, schema version 6 validation
- Clean start: `expenses` in transactional tables list
- Tests: permission tests, clean start tests, backup/restore tests (no dedicated expense tests)

### Implementation

**Schema (v6 → v7):**
- Added `category TEXT` nullable column to `expenses` table
- Added new `expense_categories` table: `id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE`
- Migration: `ALTER TABLE expenses ADD COLUMN category TEXT` + `CREATE TABLE expense_categories`

**New model:**
- `ExpenseCategory` with `id`, `name`, `copyWith`, `toMap`/`fromMap`, `normalize`, `isBlankName`

**Updated model:**
- `Expense` gained nullable `category` field, reflected in `toMap`/`fromMap`

**Database CRUD:**
- `insertExpenseCategory`: owner-only, normalizes name, rejects blanks, rejects duplicates (case-insensitive via `LOWER()`)
- `getAllExpenseCategories`: ordered by `id ASC`
- `renameExpenseCategory`: owner-only, same validation as insert, allows self-rename
- `deleteExpenseCategory`: owner-only, blocks deletion when category is in use by expenses
- `getDistinctExpenseCategories`: returns distinct non-null non-empty categories from expenses

**UI:**
- `ExpensesScreen`: category dropdown in add dialog (select from existing or leave null), category badge on expense list items
- `ExpenseCategoriesScreen`: owner-only CRUD screen, accessible from Settings > "إدارة المصروفات" section
- `SettingsScreen`: new "إدارة المصروفات" section with "تصنيفات المصروفات" navigation tile

**Compatibility updates:**
- `standalone_restore_service.dart`: schema version check updated from 6 to 7, `expense_categories` added to expected tables list
- `clean_start_service.dart`: `expense_categories` added to `transactionalTables` list
- `test_schema.dart`: updated expenses table schema, added expense_categories table

### Data Model / Schema

```
schema changed: YES
old version: 6
new version: 7
new tables: expense_categories (id, name)
new columns: expenses.category (TEXT, nullable)
migration behavior: ALTER TABLE expenses ADD COLUMN category TEXT; CREATE TABLE expense_categories IF NOT EXISTS
legacy data behavior: existing expense rows get NULL for category, remain fully readable
```

### Expense Category Contract

```
creation:       owner-only via insertExpenseCategory, name normalized (trimmed), blanks rejected, duplicates rejected (case-insensitive)
renaming:       owner-only via renameExpenseCategory, same validation, self-rename allowed
selection:      dropdown in expense add dialog, shows existing categories, optional (nullable)
mandatory:      NO - category is optional. Legacy and new expenses can have null category
deletion:       owner-only, blocked when category is used by any expense (StateError)
historical:     expense rows retain their category string even if category is deleted from master list
```

### Accounting / Inventory Safety

**Invariant verified:**
- Same expense amount before and after categorization → same accounting effect
- `getTotalExpenses()` = `SUM(amount)` — category is not involved in financial calculations
- `netProfit = grossProfit - totalExpenses` — unchanged
- Dashboard values — unchanged
- COGS, inventory, sales, returns — completely unaffected
- Category is classification metadata only

### Permissions

- Category management (CRUD): guarded by `AppPermission.canManageUsers` (owner-only in default config)
- Category selection when creating expense: available to anyone who can create expenses (`AppPermission.canCreateExpenses`)
- No new permission IDs added — reuses existing `canManageUsers` for management

### Backup / Restore Compatibility

- Schema version updated from 6 → 7 in `standalone_restore_service.dart`
- `expense_categories` added to expected tables list in restore validation
- Backup captures all tables including `expense_categories` via VACUUM INTO
- Old schema-version-6 backups are correctly rejected by the version check
- Pre-save safety backup created before restore — unchanged behavior

### Files Changed

```
Production (6 files):
  app/lib/database/database_helper.dart              (+93/-3)
  app/lib/models/expense.dart                        (+4/-0)
  app/lib/models/expense_category.dart               (NEW, 40 lines)
  app/lib/screens/expenses/expenses_screen.dart       (rewritten, 261 lines)
  app/lib/screens/expenses/expense_categories_screen.dart (NEW, 286 lines)
  app/lib/screens/settings_screen.dart               (+36/-0)
  app/lib/services/clean_start_service.dart          (+1/-0)
  app/lib/services/standalone_restore_service.dart   (+4/-3)

Tests (4 files):
  app/test/database/expense_categories_test.dart     (NEW, 542 lines, 38 tests)
  app/test/database/clean_start_service_test.dart    (+3/-0)
  app/test/database/standalone_backup_restore_test.dart (+6/-6)
  app/test/helpers/test_schema.dart                  (+9/-2)

Docs: none (this report only)
Schema: embedded in database_helper.dart
Dependencies: none
Platform: none
Generated/noise: 7 platform files (pre-existing, not committed)
```

### Validation

```
targeted tests (expense_categories_test.dart): 38/38 PASSED
full flutter test: 658/658 PASSED
flutter analyze: 0 warnings, 0 errors
git diff --check: clean
git diff HEAD^ HEAD --check: clean
```

### Risks

```
Supabase / Cloud:       unchanged, out of scope
Android:                unchanged, out of scope
Sync / Offline:         unchanged, out of scope
Accounting / Inventory: affected and verified — category is metadata only, no financial impact
Backup / Restore:       affected and verified — schema v7, expense_categories in expected tables
Licensing / Trial:      unchanged
Windows Delivery:       unchanged
UI / UX:                affected and verified — new category badge on expense list, dropdown in add dialog
```

### Blockers

None.

### Git State

```
Branch:           codex/i-tech-next-roadmap-freeze
Baseline:         a3dacd8
Final commit:     26cd605
Commits above baseline: 1
Merge commits:    0
Working tree:     7 generated platform files (CRLF normalization noise, uncommitted)
Push:             NOT DONE (per instructions)
Tag:              NOT DONE (per instructions)
```

### Single Next Authorized Step

Per `I-TECH-RISK-DEPENDENCY-MAP.md` line 159:

**T2-3: Customer Master Design Freeze (no dependencies, medium risk)**

This is a design/contract freeze document only — not implementation.

---

## Continuity Clause

```
Outcome:              A — ACCEPTED / FOLLOW ROADMAP
Roadmap alignment:    A — FOLLOW ROADMAP
What was inspected:   Full expense architecture, database schema, backup/restore, clean start, permissions, tests
What changed:         Added expense_categories table, category column on expenses, category management UI, 38 new tests
What intentionally did not change: Financial calculations, dashboard, sales, returns, inventory, licensing, brand color, permissions model
Schema impact:        v6 → v7, new table + nullable column
Migration behavior:   ALTER TABLE + CREATE TABLE IF NOT EXISTS, legacy rows get NULL category
Accounting impact:    None — category is classification metadata only
Backup/restore impact: Schema version updated, expense_categories added to expected tables
Permissions impact:   Category management uses existing canManageUsers (owner-only)
Blockers:             None
Branch:               codex/i-tech-next-roadmap-freeze
Baseline:             a3dacd8
Final HEAD:           26cd605
Working-tree status:  7 generated platform files (CRLF noise, uncommitted)
Validation results:   658/658 tests passed, 0 analyze warnings
Preserved risks:      Accounting, inventory, backup/restore, licensing all verified unchanged
One and only one next authorized step: T2-3 — Customer Master Design Freeze
```
