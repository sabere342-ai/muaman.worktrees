# MUAMAN-19 — Evidence Index

Ticket: MUAMAN-19 (Safe Demo-Data Commissioning / Clean-Start Flow)
Branch: `codex/muaman-19-safe-demo-data-commissioning-clean-start`
Baseline: `23cb92e64bbc7b1761457335626641aace8b0951`

All evidence below was produced in this worktree on baseline `23cb92e` before the
single atomic commit.

## Verification runs

| Artifact | Result | Notes |
|---|---|---|
| `test-results.txt` | `All tests passed!` (+501) | full `flutter test`, exit 0 |
| `analyze.txt` | `No issues found!` | `flutter analyze`, exit 0 |
| `format.txt` | `Formatted 6 files (0 changed)` | `dart format --output=none --set-exit-if-changed`, exit 0 |
| `release-build/` | `build-result.json` status `PASS` (exit 0) | canonical `tools/release/build_windows_release.ps1`, no `--dart-define` |
| `release-build/release-manifest.json` | 16 files, 35,753,553 bytes | production (define-free) artifact manifest |
| `dev-seed-build/build.log` | `√ Built ...muaman_store.exe` | `flutter build windows --release --dart-define=MUAMAN_SEED_DEMO=true` |
| `binary-probe.json` | prod app.so: 0 barcode hits; seeded app.so: 1 hit | AOT tree-shaking proves define was compiled in/out |

## Runtime acceptance

Run with `runtime-acceptance/run_isolated_app.ps1`: copies the Release tree into an
isolated stage dir, strips any copied `.dart_tool` databases folder (so the app MUST
create a fresh database via `onCreate`), launches the exe, waits for the database to
be created, stops the app, then the database is inspected with Python `sqlite3`
(`PRAGMA integrity_check` + per-table row counts).

| Case | Exe | `db-inspection.json` summary |
|---|---|---|
| `runtime-acceptance/prod/` | canonical release (no define) | integrity `ok`; products=0, sales=0, returns=0, expenses=0, invoices=0, import_batches=0, inventory_count=0, users=0, role_permissions=0; app_settings=4 runtime defaults only |
| `runtime-acceptance/seed/` | `--dart-define=MUAMAN_SEED_DEMO=true` release | integrity `ok`; products=86, sales=225, returns=8, expenses=32; first product barcode `2000000000001` (`تي شيرت 2سوستة تركي`); invoices/import_batches/inventory_count/users/role_permissions still 0 |

Interpretation:
- **Production default**: a fresh production database is empty — no demo/trial data.
- **Dev define**: only a build compiled with `--dart-define=MUAMAN_SEED_DEMO=true`
  seeds the transactional demo data; the seeded build's `data/app.so` keeps
  `DataImporter` (1 barcode hit) while the production `data/app.so` has it
  tree-shaken out (0 hits).

## Notes on evidence integrity

- The canonical release build was re-run after the final source state (including the
  `curly_braces_in_flow_control_structures` lint fix) with `build-result.json`
  status `PASS`; the release tree is the production (define-free) artifact.
- The full test suite, analyzer, and formatter were re-run after that fix; all pass.
- No push, no tag, no merge was performed. The evidence directory itself is part of
  the single atomic commit.
