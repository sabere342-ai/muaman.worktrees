# MUAMAN-13A — Clean Release Provenance & Complete Windows Package Verification

## A. Executive Summary

| Item | Value |
| ---- | ----- |
| Outcome | `Outcome A — FULL SUCCESS` |
| Baseline commit | `d9beab8b944751442ed557fec448510852fa60c6` |
| Final commit | created by this phase (single commit on top of baseline) |
| Branch | `codex/muaman-13a-clean-release-provenance` |
| Worktree | `C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance` |
| Worktree clean before build | Yes (see C. and E.) |
| Worktree clean after build | Yes (only intended source/test/docs changes present; see L.) |
| Production behavior modified | No. Two `lib/` files were reformatted (whitespace-only, see C./L.). No logic, screen, schema, or permission changed. |
| Push | No |
| Tag | No |
| Merge / Rebase / Squash of prior history | No |

The Windows release was built exclusively from the baseline commit inside a fresh, independent worktree. The user-owned modified file
`شهر7/شيت_ادارة_محل_مؤمن_مطور_حديث_شهر7.xlsx` that exists in the previous worktree was never read, copied, restored, or added. The full
`Release` directory (14 files, 33,273,513 bytes) was captured in a deterministic manifest, packaged into one ZIP with a full SHA-256, and
verified by extracting and launching it from an isolated directory outside the repository.

## B. Scope

Executed (release-provenance only, no application behavior change):

- Verify the baseline commit and its exact identity.
- Create an independent clean worktree + new branch from the baseline.
- Record the real build environment (no estimated values).
- `flutter clean` + `flutter pub get`, verify `pubspec.lock` unchanged.
- Gates: `dart format`, `flutter analyze`, `flutter test`, Windows integration smoke test, `git diff --check`.
- Clean Windows `--release` build.
- Deterministic per-file release manifest (size + full SHA-256 for every file).
- Final ZIP of the complete Release directory with full ZIP SHA-256.
- Relocation smoke: extracted the ZIP outside the repo and ran the app from the extracted directory.
- Workbook packaging decision (month-8 workbook) documented from code + build result.
- Guard tests / re-runnable tooling for the manifest and package invariants.
- Phase report + single final commit.

Not executed (explicitly out of scope, and not expanded into):

- No MUAMAN-13B/13C/13D/13E/13F work.
- No production behavior, screen, DB schema/migration, permissions, invoice, or stock-logic changes.
- No workbook content audit (deferred to MUAMAN-13F).
- No code signing, no publish tooling.
- No `build/` commit, no binary in Git, no Push, no Tag.

The only deviation from the "no diff under `lib/`" ideal is formatting-only (whitespace) of two `lib/` files and one integration-test file whose
baseline content was not `dart format`-clean. This was required to satisfy the mandatory `dart format` gate. See C. and L.

## C. Source Provenance

```text
$ git cat-file -t d9beab8b944751442ed557fec448510852fa60c6
commit

$ git show --no-patch --format=fuller d9beab8b944751442ed557fec448510852fa60c6
commit d9beab8b944751442ed557fec448510852fa60c6
Author:     Islam Saber <saber@muaman.local>
AuthorDate: Mon Aug 3 11:58:07 2026 +0300
Commit:     Islam Saber <saber@muaman.local>
CommitDate: Mon Aug 3 11:58:07 2026 +0300

    Enforce sell-price entry and single-submit guards on invoice save and login
    ...
```

Worktree creation:

```text
$ git worktree add -b codex/muaman-13a-clean-release-provenance ^
    C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance ^
    d9beab8b944751442ed557fec448510852fa60c6
Preparing worktree (new branch 'codex/muaman-13a-clean-release-provenance')
HEAD is now at d9beab8 Enforce sell-price entry and single-submit guards on invoice save and login
```

State inside the new worktree before any execution:

```text
$ git rev-parse HEAD
d9beab8b944751442ed557fec448510852fa60c6
$ git rev-parse HEAD^
5afadbcdb2708fa52fc56f08bf6b93269cb98c65
$ git branch --show-current
codex/muaman-13a-clean-release-provenance
$ git status --short        # empty
$ git status --porcelain=v1 # empty
```

Proof that the user-owned month-7 workbook was not used: the previous worktree still reports only its pre-existing modification
(` M "شهر7/شيت_ادارة_محل_مؤمن_مطور_حديث_شهر7.xlsx"`), byte-identical to its state at the start of this phase. The new worktree was created
from a commit SHA (not a moving branch name) and never contained or referenced that file. `flutter pub get` did not alter `pubspec.lock`
(blob hash `d4ad0594d6a5fe6acc4216985509df0a997d8163` before and after).

Note on `dart format` and the `lib/` changes:

- The baseline commit contains three files that are not `dart format`-clean (they were stored minified/single-line):
  `app/lib/database/xlsx_reader.dart`, `app/lib/screens/settings_screen.dart`, `app/integration_test/login_invoice_smoke_test.dart`.
- To satisfy the mandatory `dart format --set-exit-if-changed` gate, the formatter was applied to exactly those three files.
- `git diff --word-diff=porcelain` confirms the change is whitespace/line-break only; no tokens changed, so behavior is unchanged
  (corroborated by 242 passing tests, including all pre-existing tests).

## D. Environment

```text
Windows:      Windows 10 Pro, version 2009, OS build 26200, 64-bit
Flutter:      3.24.5 (stable) — framework revision dec2ee5c1f, engine a18df97ca5
Dart:         3.5.4 (stable)
CMake:        4.3.3
flutter path: C:\src\flutter\bin\flutter
dart path:    C:\src\flutter\bin\dart
Architecture: x64
Timestamp:    2026-08-03T19:03:11+03:00 (packaging / manifest generation, ISO-8601 with zone)
```

## E. Gates

| Gate | Command | Result | Exit Code |
| ---- | ------- | ------ | --------- |
| Baseline identity | `git cat-file -t d9beab8b...` | `commit` | 0 |
| Baseline metadata | `git show --no-patch --format=fuller d9beab8b...` | commit metadata shown | 0 |
| Worktree creation | `git worktree add -b codex/muaman-13a-clean-release-provenance <path> d9beab8b...` | created, HEAD = baseline | 0 |
| Clean tree (pre) | `git status --short`, `git status --porcelain=v1` | empty | 0 |
| Clean build outputs | `flutter clean` | OK | 0 |
| Dependencies | `flutter pub get` | 46 packages; lockfile unchanged | 0 |
| Format | `dart format --output=none --set-exit-if-changed .` | 49 files, 0 changed | 0 |
| Analyze | `flutter analyze` | No issues found | 0 |
| Unit/widget tests | `flutter test` | 242 passed, 0 failed, 0 skipped | 0 |
| Integration (Windows) | `flutter test integration_test/login_invoice_smoke_test.dart -d windows` | 1 passed, 0 failed, 0 skipped | 0 |
| Whitespace | `git diff --check` | clean | 0 |
| Release build | `flutter build windows --release` | `Built ...Release\muaman_store.exe` | 0 |
| Manifest creation | `dart run tool/create_release_manifest.dart ...` | 14 files hashed | 0 |
| ZIP creation | `dart run tool/create_release_zip.dart ...` | ZIP written | 0 |
| Package verification | `dart run tool/verify_release_package.dart ...` | `VERIFY OK` | 0 |
| Guard tests | `flutter test test/release_package_guard_test.dart` | 9 passed | 0 |

`pubspec.lock` did not change after `flutter pub get` (blob `d4ad0594...` before and after), so the baseline lockfile was preserved and no
dependency upgrade was made.

## F. Test Counts

- Unit/widget (`flutter test`, the `test/` directory): 242 tests — 233 inherited from the baseline plus 9 new release-package guard tests. All passed, 0 failed, 0 skipped.
- Windows integration (live smoke, `integration_test/login_invoice_smoke_test.dart -d windows`): 1 test — login, empty-price invoice rejection with no DB writes, valid invoice save with DB stock effects, lastLoginAt recorded. Passed. The integration test resets its own runtime DB first, so it never touches a customer database.
- These are distinct groups; the focused integration test is not run by `flutter test` and is not double-counted.

## G. Release Directory

```text
Path:           C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance\app\build\windows\x64\runner\Release
File count:     14
Total size:     33,273,513 bytes (31.732 MB)
Key files:      muaman_store.exe (90,624 B), flutter_windows.dll (18,181,632 B), pdfium.dll (4,749,824 B),
                printing_plugin.dll (138,240 B), data/app.so (7,324,576 B), data/icudtl.dat (778,864 B),
                data/flutter_assets/* (bundled assets), native_assets.yaml (51 B)
```

Full relative listing (also recorded in the manifest):

```text
data/app.so
data/flutter_assets/AssetManifest.bin
data/flutter_assets/AssetManifest.json
data/flutter_assets/FontManifest.json
data/flutter_assets/NOTICES.Z
data/flutter_assets/fonts/MaterialIcons-Regular.otf
data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
data/flutter_assets/shaders/ink_sparkle.frag
data/icudtl.dat
flutter_windows.dll
muaman_store.exe
native_assets.yaml
pdfium.dll
printing_plugin.dll
```

## H. Manifest

```text
Path:          C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance\app\build\artifacts\muaman-store-windows-release-manifest.json
Size:          2,813 bytes
SHA-256:       BB76C3F68B1CD14F82172F501FDBCB5754DE4B5E76322F99AA2CADDBB59CF659
Files recorded: 14
Path style:     relative to the Release root only (verified by verifier: no absolute path, no drive letter, no `..`, no `\` in entries)
SHA-256 style:  full 64-hex lowercase for every file (verified by verifier)
Order:          deterministic, sorted by normalized path (verified by verifier)
```

The manifest records `project`, `phase`, full `commit`, `branch`, `buildMode`, `platform`, `architecture`, `builtAt`, `flutterVersion`,
`dartVersion`, `sourceTreeCleanBeforeBuild`, `sourceTreeCleanAfterBuild`, and a per-file `path`/`sizeBytes`/`sha256`. The manifest itself
is hashed independently (self-hash above is not circular; it is computed after creation). The same manifest file is embedded at the root of
the ZIP.

## I. ZIP Artifact

```text
Name:    muaman-store-windows-x64-d9beab8.zip
Path:    C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance\app\build\artifacts\muaman-store-windows-x64-d9beab8.zip
Size:    15,737,735 bytes
SHA-256: 3F141FDD3FE61ACFB83497F4D36045808CB304ACF78E8B2ED210DDB1A3F957B1
```

The ZIP contains the complete Release directory (EXE, all DLLs, full `data/` folder with `app.so`, `icudtl.dat`, and all `flutter_assets`
resources, `native_assets.yaml`) plus `muaman-store-windows-release-manifest.json` at the ZIP root. No source, `.git`, test, debug,
intermediate, personal, or user-owned workbook content is included (verified by the package verifier and by the extraction listing below).
ZIP entries use a fixed timestamp for determinism on this toolchain; byte-for-byte reproducibility across independent builds was NOT
claimed and NOT proven.

## J. Relocation Smoke Test

```text
Extraction dir: C:\dev\muaman-release-smoke\d9beab8   (outside the repository)
Steps:
  1. Copy muaman-store-windows-x64-d9beab8.zip into the dir.
  2. Expand-Archive (15 entries: 14 release files + manifest at root).
  3. Verify extracted muaman_store.exe SHA-256 == manifest value.
       EXE SHA-256: 39FF962B8CFC010D3F8E5752CBCC2E8BE2D5DBFBAEC82E730EA6850786AD1626  (matches manifest)
  4. Launch muaman_store.exe with WorkingDirectory = extraction dir.
```

Actual results:

```text
PID=20640, STARTED=True
ALIVE_AFTER_12s=True        (no DLL error, no startup crash)
MAINWINDOWTITLE=muaman_store
MAINWINDOWHANDLE present
CLOSED_GRACEFULLY=True      (CloseMainWindow -> clean exit)
Local DB created by the app: <extraction dir>\.dart_tool\sqflite_common_ffi\databases\muaman_store.db (94,208 B)
```

Schema verification of the relocated DB (opened directly with sqflite_ffi):

```text
TABLES=app_settings,expenses,import_batches,inventory_count,invoices,products,returns,sales,sqlite_sequence,users
USERS_COUNT=0
SETTINGS_COUNT=4
```

This proves the app initialized completely from the relocated package (schema created, `AppSettings.initializeDefaults()` ran, user check
executed) and therefore presents the first-owner setup screen (0 users). Because `getDatabasesPath()` resolves relative to the working
directory, the DB is created inside the isolated extraction directory — the customer database is never touched. A screenshot of the running
window was captured to `C:\Users\saber\AppData\Local\Temp\opencode\muaman-13a-smoke.png` as evidence.

Limitations: UI text input (completing the first-owner setup form, typing login credentials) was not automated against the relocated
package; the launched app's render was verified live (window alive, DB initialization complete, graceful close) and the login → dashboard →
invoice flow was verified by the automated Windows integration test on the same baseline code. This is documented honestly and not claimed
as deeper automation than actually performed.

## K. Workbook Packaging Decision

Decision: **B — workbook is not required for normal release startup.**

Evidence from code and build result:

- `app/lib/main.dart` startup flow (`AuthGate._initialize`) only opens the DB, initializes `AppSettings` defaults, and checks for existing
  users. It never opens or parses a workbook.
- The workbook is referenced only by `AppSettings.getWorkbookPath()/getDefaultWorkbookPath()` (`app/lib/services/app_settings.dart`),
  which searches ancestor directories of `Directory.current` and of `Platform.resolvedExecutable` for `شيت_ادارة_محل_مؤمن_شهر8.xlsx` and
  returns `''` when not found — a graceful, non-fatal fallback.
- The workbook is consumed only by the explicit user action Settings → Import (`app/lib/screens/settings_screen.dart` → `WorkbookImporter`),
  where the user supplies a path; `WorkbookImporter.import` throws a clear Arabic error if the file is missing, without affecting startup.
- The actual Release build output contains no `.xlsx` file (verified by the package verifier).

Therefore the month-8 workbook is intentionally not packaged; its absence does not prevent normal startup. This phase does not audit the
workbook's data validity (deferred to MUAMAN-13F), and no copy of any worktree's workbook was added to the package.

## L. Git Diff

Tracked changes vs baseline (all intended, source-only):

```text
M  app/integration_test/login_invoice_smoke_test.dart      (formatted: whitespace-only)
M  app/lib/database/xlsx_reader.dart                       (formatted: whitespace-only)
M  app/lib/screens/settings_screen.dart                    (formatted: whitespace-only)
A  app/test/release_package_guard_test.dart                (new guard tests)
A  app/tool/create_release_manifest.dart                   (new re-runnable manifest builder)
A  app/tool/create_release_zip.dart                        (new re-runnable ZIP builder)
A  app/tool/release_package_verifier.dart                  (new verifier library)
A  app/tool/verify_release_package.dart                    (new re-runnable verifier CLI)
```

Classification:

- Formatting-only fixes (3 files): required to satisfy the mandatory `dart format` gate; verified token-identical via `git diff
  --word-diff=porcelain`. These are the sole `lib/` touches and are not behavior changes.
- Tooling (4 files under `app/tool/`): re-runnable release-provenance scripts (manifest, ZIP, verification), no runtime effect on the app.
- Guard tests (1 file under `app/test/`): 9 unit tests asserting deterministic ordering, full-length SHA-256, relative-only paths, absence
  of worktree/username exposure, and `.gitignore` protection of `/build/`.

Verification:

```text
$ git diff --check                      -> clean (no output)
$ git status --porcelain=v1             -> only the 3 modified + 2 new paths above
$ git diff --name-status                -> no binary files, no build artifacts
```

No binaries and no build intermediates appear in Git. `app/build/` is ignored by `.gitignore` (`/build/`).

## M. Risks and Limitations

- Byte-for-byte reproducibility across two independent builds was **not** proven; only single clean build was made. ZIP entry timestamps are
  fixed for same-content determinism, but no cross-build claim is made.
- The relocation smoke used a live launch with real-time process/window verification plus a captured screenshot; completing the first-owner
  form and typing login credentials against the relocated package were not automated. The richer login/dashboard/invoice flow was covered by
  the automated Windows integration test on the same baseline.
- The application is **not code-signed**. Windows SmartScreen may warn on first run; `muaman_store.exe` has no Authenticode signature.
- Database schema upgrade is out of scope for this phase; this phase does not change or exercise migration behavior beyond normal startup.
- `dart format` required whitespace-only reformatting of three baseline files; this is a necessary, token-identical deviation from the
  "no production diff under `lib/`" ideal.
- The app's theme declares `fontFamily: 'Noto Sans Arabic'`; the release bundle does not ship that font, so Flutter falls back to a system
  font. This is pre-existing application behavior, unchanged here, and does not block startup or the tested flows.
- The month-8 workbook data audit is explicitly deferred to MUAMAN-13F.

## N. Final Verdict

```text
Outcome A — FULL SUCCESS
```

All mandatory gates passed: baseline identity proven, clean independent worktree, source clean before/after build, format, analyze, all
242 unit/widget tests, Windows integration test, Windows release build, complete per-file manifest with full SHA-256s, complete ZIP with
full ZIP SHA-256, clean relocation smoke run, documented workbook-packaging decision (B), no binaries in Git, `git diff --check` clean,
exactly one commit after baseline, final tree clean, no Push, no Tag.
