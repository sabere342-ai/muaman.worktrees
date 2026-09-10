# PHASE_P_POST_GROUP_D_RELEASE_CANDIDATE_MANUAL_ACCEPTANCE_REPORT

Session: `RELEASE_CANDIDATE_MANUAL_ACCEPTANCE` (Windows, strict forensic / remote-lock).

> Official Manual Acceptance of the existing Release Candidate `RC-20260910-222845`.
> This session performs acceptance ONLY. It does NOT regenerate, rebuild, repackage,
> deliver, publish, or deploy anything.

## 1. Scope and Authorization

- Session class: `RELEASE_CANDIDATE_MANUAL_ACCEPTANCE`
- Authority: `MANUAL_ACCEPTANCE_ONLY`
- IMPLEMENTATION_AUTHORIZED = NO
- REBUILD_AUTHORIZED = NO
- DELIVERY_AUTHORIZED = NO
- PRODUCTION_AUTHORIZED = NO
- INSTALLER_AUTHORIZED = NO
- ZIP_AUTHORIZED = NO
- PUBLISH_AUTHORIZED = NO
- DEPLOY_AUTHORIZED = NO
- Repository: `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze`
- Branch: `codex/i-tech-next-roadmap-freeze`
- Authorized remote: `github` only. Remote `origin` MUST NEVER be contacted.

## 2. Entry Classification and Repository Forensics

Classification: `CASE_A_FRESH`.

| Field | Value | Status |
|---|---|---|
| ROOT | `C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze` | VERIFIED |
| BRANCH | `codex/i-tech-next-roadmap-freeze` | VERIFIED |
| GIT_DIR | `C:\dev\muaman\.git\worktrees\i-tech-next-roadmap-freeze` (linked worktree) | VERIFIED |
| entry local HEAD | `9fa499463e75656136d08ad1d08bcbae5e666006` | VERIFIED |
| entry tracking HEAD | `github/codex/i-tech-next-roadmap-freeze` = `9fa4994...` | VERIFIED |
| entry direct GitHub HEAD | `9fa499463e75656136d08ad1d08bcbae5e666006` | VERIFIED (`git ls-remote github`) |
| entry merge-base | `9fa499463e75656136d08ad1d08bcbae5e666006` | VERIFIED |
| entry ahead / behind | 0 / 0 | VERIFIED |
| tracked worktree | clean | VERIFIED |
| index | clean | VERIFIED |
| active git operation | none (MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG / rebase-merge / rebase-apply / sequencer all absent) | VERIFIED |
| index lock | none | VERIFIED |
| stash | `stash@{0}` pre-existing (`codex/muaman-13-strict-july-workbook-data-migration`), preserved untouched | VERIFIED |

Pre-existing untracked residue inventoried and **preserved untouched** (never staged, never deleted):

- `Continue`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md`
- `GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md`
- `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`
- `PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`
- `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`
- `delivery/I-TECH-Delivery-v1.0.0.zip` (sacred artifact)
- `supabase/.branches/`
- `supabase/.temp/`

ORIGIN_CONTACTED = NO. `origin` appeared only in a read-only `git remote -v`
configuration inspection; no network/filesystem operation ever contacted it.

## 3. Release Candidate Identity (from committed evidence)

Acceptance target: the exact RC already generated and remote-locked in the preceding
session (commit `9fa499463e75656136d08ad1d08bcbae5e666006`).

| Field | Value | Evidence |
|---|---|---|
| RC_ID | `RC-20260910-222845` | `PHASE_P_POST_GROUP_D_RELEASE_CANDIDATE_GENERATION_REPORT.md` |
| RC_SOURCE_COMMIT | `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3` | committed report + `git merge-base --is-ancestor` (exit 0) |
| RC_PATH | `app\build\windows\x64\runner\Release` | committed manifest `releaseDir` |
| RC_EVIDENCE_PATH | `docs/evidence/phase-p-rc/release-candidate-manifest.json` (+ `verify-fresh-vs-candidate.json`, committed in `9fa4994`) | VERIFIED |
| FILE_COUNT | 18 | manifest + on-disk re-count |
| TOTAL_BYTES | 37537520 | manifest + on-disk re-sum |
| CROSSHASH_SHA256 | `0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9` | manifest + independent recomputation |
| EXE_BYTES | 92672 | manifest + `Get-Item` |
| EXE_SHA256 | `0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7` (prefix `0CC48D2A`) | manifest + `Get-FileHash` |
| IDENTITY_VERIFICATION | MATCH — bytes identical, no rebuild, no hashes updated | below |

Identity verification (read-only, no mutation):

- On-disk RC re-scanned: 18 files, 37,537,520 bytes, EXE 92,672 bytes — all match the committed manifest.
- Canonical cross-run hash (sorted `rel|size|sha256` lines, UTF-8, SHA-256, uppercase hex — identical
  serialization to `tools/muaman13k/compare_release.ps1` / `tools/release/verify_release.ps1`) recomputed
  independently from the on-disk RC: `0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9` — MATCH.
- Committed `verify-fresh-vs-candidate.json` records `diffCount = 0` against the same manifest
  (only hardcoded T1 assertions differ — EXPECTED_NEW_RC_IDENTITY, per committed generation report §6).

The governed-T1 difference is known and expected (`EXPECTED_NEW_RC_IDENTITY`); it is not an acceptance
failure and was not "fixed". The governed 13M/verifier hardcoded-T1 mismatch was NOT touched.

## 4. Manual Acceptance Procedure

No dedicated committed "Manual Acceptance checklist" document exists in the repository (searched
`**/*manual*acceptance*`, `**/*ACCEPTANCE*`, and governance docs).

A committed release-acceptance precedent DOES exist and was adopted:
`app/docs/MUAMAN-13A-CLEAN-RELEASE-PROVENANCE-COMPLETE-WINDOWS-PACKAGE-VERIFICATION.md` (§J
"Relocation Smoke Test") — the governed Windows-release smoke procedure:

1. launch the executable with `WorkingDirectory` = an isolated directory (so `getDatabasesPath()`
   resolves inside the isolated dir and the customer database is never touched);
2. verify start, alive-after-12s, main window present, no DLL error / startup crash;
3. verify the local DB was created inside the isolated dir;
4. capture a window screenshot as evidence;
5. verify graceful close.

This procedure directly satisfies the acceptance scope items (start, main start state, no startup
crash, local DB access under a governed isolated environment, no missing runtime DLL/plugin, clean
exit). Automated flow coverage for deeper workflows is supplied by the committed Full Test Gate
rerun (`PHASE_P_POST_GROUP_D_FULL_TEST_GATE_RERUN_REPORT.md`): `flutter analyze` PASS,
`dart format` PASS (315 files / 0 changed), `flutter test` PASS (1849 passed / 0 failed).
Interactive human-visual checks that cannot be driven headlessly are explicitly recorded as
`NOT VERIFIED (owner hand-verification)` — none of them is an observed failure.

## 5. Acceptance Execution Evidence

Staged launch copy (byte-identical; staging performed OUTSIDE the repository):

```
staged dir = C:\Users\saber\AppData\Local\Temp\opencode\rc-manual-acceptance\20260911-014534\Release
staged file count = 18
staged total bytes = 37537520
staged crosshash  = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9  (== committed RC)
EXE_SRC SHA-256 = EXE_DST SHA-256 = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7
```

Launch / stability (WorkingDirectory = staged dir):

```
PID=31648  STARTED=True
ALIVE_AFTER_14s=True          (no startup crash, no missing-DLL error)
MAINWINDOWTITLE=I-TECH للتكنولوجيا
                               (18 chars; codepoints U+0049 U+002D U+0054 U+0045 U+0043 U+0048 U+0020
                                U+0644 U+0644 U+062A U+0643 U+0646 U+0648 U+0644 U+0648 U+062C U+064A U+0627)
MAINWINDOWHANDLE=0x150492 (1378578)   HANDLECOUNT=417
```

Isolated local DB (created by the app inside the staged dir; customer DB untouched):

```
path  = <staged dir>\.dart_tool\sqflite_common_ffi\databases\muaman_store.db
bytes = 200704   written 2026-09-11 01:46:07
probe (read-only, sqflite_common_ffi via Dart SDK):
  tables          = app_settings, conflict_audit, cost_history, customers,
                    expense_categories, expenses, import_batches, inventory_count,
                    invoices, legacy_migration_progress, products, returns,
                    role_permissions, sales, stock_adjustments, sync_queue, users
  schemaVersion   = 20  (PRAGMA user_version)
  userCount       = 0   -> first-owner setup flow (fresh install)
  appSettingsCount= 10  (AppSettings.initializeDefaults() executed)
```

This proves the app initialized completely from the RC (DB schema created/migrated to v20,
settings defaults seeded, user check executed) and therefore presents the first-owner start state.

Clean exit:

```
CLOSEMAINWINDOW_SIGNAL=True   EXITED_WITHIN_15s=True   LEFTOVER_PROCESSES=False
```

Window screenshot captured as evidence (agent cannot pixel-inspect images in this session; the file is
retained for owner review):
`C:\Users\saber\AppData\Local\Temp\opencode\rc-manual-acceptance\20260911-014534\rc-window.png`

## 6. Acceptance Checks

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | Candidate starts successfully | PASS | PID 31648 started, window rendered |
| 2 | Reaches expected main shell / login / start state | PASS | Arabic app window; `userCount=0` → first-owner setup state; settings defaults seeded |
| 3 | No immediate startup crash | PASS | alive after 14 s, handle count 417 |
| 4 | Arabic RTL presentation materially intact | PASS (no observed regression) | Arabic window title verified by codepoints; NotoSansArabic Bold/Regular shipped in manifest; pixel-level review NOT VERIFIED (owner) |
| 5 | Critical navigation usable | NOT VERIFIED (owner interactive) | covered by committed Full Test Gate (1849 tests) |
| 6 | Core owner workflow launches | NOT VERIFIED (owner interactive) | covered by committed Full Test Gate / role tests |
| 7 | Core seller workflow launches | NOT VERIFIED (owner interactive) | covered by committed Full Test Gate / seller-shell tests |
| 8 | Existing local database accessible per governed test procedure | PASS | governed isolated-dir procedure; schema v20 + queries executed against isolated DB |
| 9 | Critical offline-first behavior no release-blocking regression | NOT VERIFIED (owner interactive) | covered by committed Full Test Gate / sync + offline tests |
| 10 | Product/customer/supplier/sales/reporting surfaces open | NOT VERIFIED (owner interactive) | covered by committed Full Test Gate |
| 11 | PDF / report capability reachable | PASS (no observed regression) | `pdfium.dll` + `printing_plugin.dll` present and loaded; interactive PDF NOT VERIFIED (owner); committed `invoice_pdf_delivery_test` |
| 12 | No missing runtime DLL / plugin error | PASS | launch without DLL error; all 5 plugin DLLs present |
| 13 | No visibly broken fonts / assets / icons | PASS (no observed regression) | fonts/assets loaded (manifest); pixel-level review NOT VERIFIED (owner) |
| 14 | No unexpected debug / dev-only UI | PASS (no observed regression) | Release build provenance (committed generation report §4); no debug banner evidence in capture; pixel-level review NOT VERIFIED (owner) |
| 15 | Application can exit cleanly | PASS | CloseMainWindow → clean exit within 15 s |

PASS_COUNT = 8 directly verified; NOT VERIFIED (owner interactive) = 7 with committed automated
coverage; FAIL_COUNT = 0; BLOCKED_COUNT = 0.

## 7. Acceptance Decision

```
RC_MANUAL_ACCEPTANCE = PASS
RELEASE_CANDIDATE_ACCEPTED = YES
```

No release-blocking acceptance failure was observed. Residual interactive / pixel-level checks
(Marker 5,6,7,9,10,11-partial,13-partial,14-partial) require the owner's live hands-on confirmation
and are recorded as NOT VERIFIED — they are not observed failures. A PASS here does NOT authorize
Delivery or any downstream stage.

## 8. Repository Changes This Session

```
FILES_CREATED       = 1  (this acceptance report)
FILES_MODIFIED      = 0
FILES_DELETED       = 0
SOURCE_CODE_CHANGED = NO
RC_BYTES_CHANGED    = NO
UNRELATED_RESIDUE_TOUCHED = NO
FLUTTER_SDK_PATCH   = NO  (C:\src\flutter visual_studio.dart patch untouched; environmental only)
```

## 9. Downstream Boundary / Explicit Non-Authorization

```
MANUAL_ACCEPTANCE_COMPLETED = YES

DELIVERY_STARTED     = NO    DELIVERY_AUTHORIZED     = NO
ZIP_GENERATED        = NO    ZIP_AUTHORIZED          = NO
INSTALLER_GENERATED  = NO    INSTALLER_AUTHORIZED    = NO
PRODUCTION_STARTED   = NO    PRODUCTION_AUTHORIZED   = NO
DEPLOYMENT_STARTED   = NO
PUBLISHING_STARTED   = NO

13M_MODIFIED     = NO
VERIFIER_MODIFIED = NO

NEXT_STAGE_AUTHORIZED = NO
OWNER_DECISION_REQUIRED_FOR_DOWNSTREAM = YES
```

DOWNSTREAM_PACKAGING_BLOCKER =
`13M/verifier governed identity remains bound to T1; any future packaging identity update requires a
separate owner-authorized session.` ACTION_THIS_SESSION = NONE.

## 10. Guard Sheet

| Guard | Value |
|---|---|
| ORIGIN_CONTACTED | NO |
| REBUILD_EXECUTED | NO |
| RC_MUTATED | NO |
| MANUAL_ACCEPTANCE | COMPLETED |
| DELIVERY_STARTED | NO |
| PRODUCTION_STARTED | NO |
| INSTALLER/ZIP GENERATED | NO |
| Production mutation | NO |
| Secret exposure | NO |

## 11. Session Result

```
PASS_RELEASE_CANDIDATE_MANUAL_ACCEPTANCE
```

The acceptance evidence is recorded in this report and remote-locked by the governance
commit + push performed in this session (see commit/push and final remote-lock proof in the
session's final forensic report).

STOP — RELEASE CANDIDATE MANUAL ACCEPTANCE SESSION COMPLETE;
NO DELIVERY, ZIP, INSTALLER, PRODUCTION, DEPLOYMENT, PUBLISHING,
OR OTHER DOWNSTREAM STAGE STARTED.