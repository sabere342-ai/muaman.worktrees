# MUAMAN-13I quality gates (isolated B env, patched SDK D08E9D71)

Captured 2026-08-05 (UTC). All gates run from the isolated B app root
`C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app`
with the patched SDK `C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk`,
PUB_CACHE=B pub cache, TEMP/TMP=`C:\t\m13i-b`.

| gate | command | result | detail |
|------|---------|--------|--------|
| format | dart format --output=none --set-exit-if-changed . | FAIL (pre-existing) | 1 file would change: `test/muaman13f_fresh_clone_guard_test.dart`. File is byte-identical to HEAD (blob `f6f2ee29...` for the sibling test file; this file unmodified vs HEAD per `git diff --quiet` = 0). Not modified here to keep the production diff empty. |
| analyze | flutter analyze | PASS | "No issues found! (ran in 72.4s)" |
| test | flutter test | 311 pass / 29 fail | All 29 failures are in `test/database/workbook_import_test.dart`, each `LateInitializationError: Local 'testDb' has not been initialized`. File is byte-identical to HEAD (git blob `f6f2ee29bb28f2041e95a34dd4b8eb377202b0b1`). Reproduces standalone (`flutter test test/database/workbook_import_test.dart` => +0 -29), i.e. a file-level setUp bug present at baseline, not caused by isolation. |

Notes:
- Production diff (`app/lib`, `app/pubspec.yaml`, `app/pubspec.lock`) is empty.
- Neither gate was treated as a reason to change production files.
- `workbook_import_test.dart` blob at HEAD equals B extraction blob (f6f2ee29...) proving byte-identity.
