# MUAMAN-13J quality gates (isolated B env, patched SDK D08E9D71)

Captured 2026-08-05 (UTC). All gates run from the isolated B app root
`C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app`
with the patched SDK `C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk`,
PUB_CACHE = B pub cache, TEMP/TMP = `C:\t\m13i-b`, USERPROFILE/HOME = B home root.

Raw logs: `01-format.log`, `02-analyze.log`, `03-test.log`.

| gate | command | result | detail |
|------|---------|--------|--------|
| format | dart format --output=none --set-exit-if-changed . | FAIL (pre-existing) | 1 file would change: `test/muaman13f_fresh_clone_guard_test.dart`. Same single file as the 13I baseline signature (`41-quality-gates`). Not modified here to keep the production diff empty. |
| analyze | flutter analyze | PASS | "No issues found! (ran in 38.9s)". 13I baseline was also PASS. |
| test | flutter test | 311 pass / 29 fail | All 29 failures are in `test/database/workbook_import_test.dart`, each `LateInitializationError: Local 'testDb' has not been initialized`. Identical signature to the 13I baseline (311 pass / 29 fail, same file, same error). Pre-existing baseline defect, not caused by isolation or by 13J. |

Classification (per 13J policy): each gate is either PASS, BASELINE-IDENTICAL
FAILURE, or NEW FAILURE.

- format: BASELINE-IDENTICAL FAILURE (same 1 file as baseline).
- analyze: PASS.
- test: BASELINE-IDENTICAL FAILURE (same 29 tests, same error, same file as baseline).

Production diff (`app/lib`, `app/pubspec.yaml`, `app/pubspec.lock`) is empty.
No gate was treated as a reason to change production files.
