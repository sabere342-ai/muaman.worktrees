# Settings Configurables — Report

## Baseline
- **Accepted baseline:** `c02fd30` (Permission Hardening final commit)
- **Branch:** `codex/i-tech-settings-configurables`
- **Worktree:** `C:\dev\muaman.worktrees\i-tech-permission-hardening`

## Scope
Expose two existing DB-backed settings (`defaultCustomerName`, `supportPhone`) in the Settings UI with full edit/save/persistence, after confirming they were the first real remaining gap post brand-color + permission-hardening.

## Pre-State Investigation

### What was already complete
- **Store name (اسم المتجر):** Fully configurable via TextField in Settings. Stored in `app_settings`. Used in app title, login, dashboard, invoice.
- **Store logo (شعار المحل):** Fully configurable via FilePicker. Managed copy stored. Shown in login, dashboard, invoice.
- **Brand color (لون الهوية):** Fully configurable (7 swatches). Drives ThemeData.
- **Button style:** Fully configurable (filled/outlined). Used in invoice screen.
- **Permission hardening:** All mutations guarded at data layer.

### First real gap found
1. **`defaultCustomerName`** — DB key exists (`defaultCustomerName`), default `'عميل نقدي'`, actively consumed by `invoice_screen.dart:40` to pre-fill customer name on new invoices. **Zero UI exposure in Settings.**
2. **`supportPhone`** — DB key exists (`supportPhone`), default `+201014900211`, displayed in Settings but **read-only** (no TextField, no save mechanism).

## What Changed

### Production files (2)

| File | Change |
|------|--------|
| `app/lib/screens/settings_screen.dart` | Replaced read-only support phone ListTile with editable TextField + save button. Added new "إفتراضيات الفاتورة" section with default customer name TextField + save button. Added `_supportPhoneController`, `_defaultCustomerNameController`. Removed unused `Clipboard` import. |
| `app/lib/services/app_settings.dart` | Added `.trim()` to `getSupportPhone()` and `getDefaultCustomerName()` getters for defense-in-depth. |

### Test files (1 new)

| File | Coverage |
|------|----------|
| `app/test/database/app_settings_configurables_test.dart` | 20 tests: default, persistence, trimming, empty/malformed fallback, no-مؤمن fallback for both `defaultCustomerName` and `supportPhone`. |

### Documentation (1)

| File | Content |
|------|---------|
| `docs/settings-configurables/SETTINGS-CONFIGURABLES-REPORT.md` | This report. |

## Persistence Model
- Both settings use existing `app_settings` key-value table via `AppSettings.setValue()`/`AppSettings.getValue()`.
- No schema changes. No migrations.

## Fallback Behavior

| Setting | Default | Empty DB | Empty string in DB | Malformed |
|---------|---------|----------|-------------------|-----------|
| `defaultCustomerName` | `'عميل نقدي'` | `'عميل نقدي'` | `'عميل نقدي'` | N/A (text) |
| `supportPhone` | `'+201014900211'` | `'+201014900211'` | `'+201014900211'` | N/A (text) |

Both getters now `.trim()` values before fallback check.

## Updated Surfaces
- **Settings screen:** New "إفتراضيات الفاتورة" section with editable customer name. "دعم ومساعدة" section now has editable phone TextField + save button.
- **Invoice screen:** No code changes needed — already reads `AppSettings.getDefaultCustomerName()`.

## Tests

### Targeted (20/20 PASS)

**defaultCustomerName (11 tests):**
- Returns default when no key exists
- Returns default after initializeDefaults
- Set and get returns same value
- Persists across multiple reads (restart simulation)
- Overwrites previous value
- Persists after initializeDefaults does not overwrite
- Trims whitespace
- Returns default for empty string in DB
- Returns default when key never created
- Default fallback is not مؤمن
- Empty value falls back to neutral default, not مؤمن

**supportPhone (9 tests):**
- Returns default when no key exists
- Returns default after initializeDefaults
- Set and get returns same value
- Persists across multiple reads
- Overwrites previous value
- Persists after initializeDefaults does not overwrite
- Trims whitespace
- Returns default for empty string in DB
- Returns default when key never created

### Full suite: 570/570 PASS

## Validation

| Gate | Result | Evidence |
|------|--------|----------|
| `flutter analyze` | 0 issues | run output |
| `flutter test` (targeted) | 20/20 PASS | run output |
| `flutter test` (full suite) | 570/570 PASS | run output |
| `flutter build windows --release` | PASS | `muaman_store.exe` built |
| `git diff --check` | PASS | CRLF warnings only (pre-existing) |
| Schema changes | 0 | — |
| New dependencies | 0 | — |
| Secret/artifact scan | 0 findings | grep verified |

## Known Debt (Preserved)
- Currency (S12)
- Invoice numbering (S13)
- Printer/paper settings (S14)
- Invoice header/footer (S15)
- Manual backup/restore UI (S16)
- Language switching (S17)
- Dark mode

## Git
- **Branch:** `codex/i-tech-settings-configurables`
- **Baseline:** `c02fd30`
- **Commits above baseline:** 0 (pre-commit)
- **Merge commits:** 0
- **Working tree:** 3 files changed (2 modified, 1 new)
- **Push:** NO
- **Tag:** NO
