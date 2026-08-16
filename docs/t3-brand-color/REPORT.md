# T3 Brand Color — Evidence Report

## Baseline
- **Accepted baseline**: `ed41758` (Closed T1)

## Branch
- **Branch**: `codex/i-tech-brand-color-t3`
- **Worktree**: `C:\dev\muaman.worktrees\i-tech-brand-color-t3`

## Scope
Configurable shop brand color only. Single feature, no redesign.

## Files Changed

### Production (app/lib/)
| File | Change |
|------|--------|
| `services/app_settings.dart` | Added `keyBrandColor`, `defaultBrandColor`, `getBrandColor()`, `setBrandColor()`, brand color initialization in `initializeDefaults()` |
| `main.dart` | Added brand color loading in `_MyAppState`, dynamic `ThemeData` with `ColorScheme.fromSeed`, `AppBarTheme` with brand color |
| `screens/settings_screen.dart` | Added "مظهر التطبيق" section with color swatch picker, brand color state loading/saving |
| `screens/dashboard/dashboard_screen.dart` | Removed hard-coded AppBar/FAB colors |
| `screens/sales/sales_screen.dart` | Removed hard-coded AppBar/FAB/button colors, using Theme |
| `screens/returns/returns_screen.dart` | Removed hard-coded AppBar color, FAB uses Theme |
| `screens/expenses/expenses_screen.dart` | Removed hard-coded AppBar color, FAB uses Theme |
| `screens/inventory/inventory_screen.dart` | Removed hard-coded AppBar color, FAB uses Theme |
| `screens/inventory_count/inventory_count_screen.dart` | Removed hard-coded AppBar color |
| `screens/sales/invoice_screen.dart` | Removed hard-coded AppBar/button colors |
| `screens/sales/sales_report_screen.dart` | Removed hard-coded AppBar color |
| `screens/invoices/invoice_preview_screen.dart` | Removed hard-coded AppBar/button colors |
| `screens/admin/user_management_screen.dart` | Removed hard-coded AppBar/FAB colors |
| `screens/admin/roles_permissions_screen.dart` | Removed hard-coded AppBar/button colors |

### Tests
| File | Coverage |
|------|----------|
| `test/database/app_settings_brand_color_test.dart` | 16 tests: default, persistence, malformed fallback, legacy, valid formats |

### Schema
None. Uses existing `app_settings` key/value table.

### Dependencies
None added.

### Windows/Platform
No changes.

## Implementation

### Persistence
- Key: `brandColor` in `app_settings` table
- Default: `#0D47A1`
- Format: `#RRGGBB` (6-digit hex with `#` prefix)
- Normalized on read (8-digit strips alpha, no-hash gets prefix)

### Theme Integration
- `_MyAppState` loads brand color async on `initState`
- `ThemeData` uses `ColorScheme.fromSeed(seedColor: brandColor).copyWith(primary: brandColor)`
- `AppBarTheme` set with `backgroundColor: brandColor, foregroundColor: Colors.white`
- Individual AppBars no longer override `backgroundColor`

### Settings UI
- "مظهر التطبيق" section with "لون الهوية" label
- 7 predefined color swatches (أزرق I-TECH, Teal, Indigo, Purple, Orange, Red, Green)
- Owner/settings gated
- Save on tap with SnackBar feedback
- Activation requires app restart

### Startup Behavior
- Default color shown immediately
- Brand color loaded async from DB
- Theme updates on load via `setState`
- App works correctly if user never changes color

## Default Behavior
- Missing key → `#0D47A1`
- Empty value → `#0D47A1`
- Invalid hex → `#0D47A1`
- No crash on any malformed value

## Negative Controls

### NC1 — Missing setting
brandColor key not created → PASS: uses `#0D47A1`

### NC2 — Invalid setting
brandColor = "invalid" → PASS: no crash, fallback to `#0D47A1`

### NC3 — Legacy behavior
Old DB without brandColor key → PASS: `getBrandColor()` returns default

### NC4 — Frozen boundary
`git diff --stat -- windows/ android/ ios/ pubspec.yaml pubspec.lock` → empty. No frozen boundary changes.

### NC5 — Existing permissions
Full test suite passes (517 tests). Permission tests unaffected.

## Verification

| Gate | Result |
|------|--------|
| `flutter analyze` | Clean, no issues |
| `flutter test` (targeted) | 16/16 pass |
| `flutter test` (full suite) | 517/517 pass |
| `flutter build windows --release` | Success: `muaman_store.exe` |
| `git diff --check` | Clean (CRLF warnings only) |
| Commits above baseline | 1 |
| Merge commits | 0 |
| Working tree | Clean |
| Push/Tag | None |

## Preserved Debt
- Creative-operation data-layer permission hardening
- InventoryCount defense-in-depth
- UserRepository internal gate
- Dashboard/read guards
- Editable support number
- Currency (S12)
- Invoice numbering (S13)
- Printer/paper settings (S14)
- Invoice header/footer (S15)
- Manual backup/restore UI (S16)
- Language switching (S17)
- Dark mode

## Final Commit
```
1e180fd feat(settings): add configurable shop brand color
```
