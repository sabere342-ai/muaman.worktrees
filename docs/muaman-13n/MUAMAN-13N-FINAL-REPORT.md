# MUAMAN-13N - Independent Consumer Packaged-Release Launch Acceptance

**Status:** PASS (outcome A - verified launch) - the MUAMAN-13M canonical
deterministic Windows release package is portable, unpackable and launchable
from an independent consumer environment that contains NO repository tree, NO
Flutter/Dart SDK, NO PUB_CACHE, NO Git, NO CMake/Ninja and NO Visual Studio
build tools. Two fresh, isolated extraction-and-launch runs passed every
consumer-launch guard N1..N12, and a third tampered copy was correctly rejected
by the harness (negative control). Verified by the committed harness
`tools/muaman13n/verify_consumer_launch.ps1` on the final HEAD.

**Baseline:** commit `14da91a15253658b736b22aeeac801ede688cdc4` (MUAMAN-13M;
the 13N branch is created at this exact commit with a clean tree and the final
branch contains exactly one additional commit, `rev-list --count` after
baseline = 1).
**Branch:** `codex/muaman-13n-independent-consumer-packaged-release-launch-acceptance`.
**Date:** 2026-08-06 (all UTC timestamps recorded inside the evidence tree).

---

## 1. Purpose and scope

MUAMAN-13N is the closed-scope acceptance phase that proves the official
MUAMAN-13M Windows release ZIP is a self-contained, portable artifact: a
consumer with no toolchain and no access to the repository must be able to
download the ZIP, unpack it, and run the store. This is the final link in the
release chain after deterministic build (13K), canonical hardened build
entrypoint (13L), and canonical deterministic packaging (13M).

13N adds a **thin operational verification harness only**:

- new `tools/muaman13n/verify_consumer_launch.ps1` - fail-closed,
  non-interactive, repeatable consumer-launch harness (guards N1..N12,
  negative-control mode, explicit exit codes 0/1/2/3),
- `docs/MUAMAN-13N-FINAL-REPORT.md` - this report,
- `docs/muaman-13n/evidence/` - 22 numbered evidence files produced by the
  harness from two independent consumer runs plus one negative control.

The harness **never modifies** the repository, the legal manifest, or the
packaged ZIP; it performs fresh, owned-only extraction and launch inside a
caller-provided consumer root; it deletes files only strictly below that
root. No production code, dependency, SDK, plugin, MSBuild, or app-tree change
is made. No binary ZIP is committed to the repository. The MUAMAN-13M package
was re-produced for 13N through the sole official packaging entrypoint
`tools/release/package_windows_release.ps1` and is byte-identical to the
accepted 13M package.

## 2. Outcome

**PASS.** The packaged release was verified launchable from an independent
consumer environment, twice, plus one rejected tamper control:

- **run1** and **run2** - independent fresh extractions of the canonical ZIP
  into separate consumer roots (`extract-run1`, `extract-run2`); both survived
  the 20-second liveness window with a main window, terminated cleanly, kept
  all 13 release files byte-identical pre/post launch, and loaded zero modules
  from any repo/SDK/cache/build root. Both report `verdict=PASS` with all
  guards N1..N11 `PASS`.
- **negative control** - a third copy of the ZIP was extracted, one critical
  runtime DLL (`flutter_windows.dll`) was replaced with 4,096 corrupt bytes,
  and the harness **rejected** it (`verdict=REJECTED`, N6 guard FAIL on size
  and hash mismatch). This proves the pre-launch manifest guard detects
  tampering and will not launch a compromised package.
- **N12** aggregated all modes: `overall=PASS`, exit code `0`.
- The app-created runtime database is self-contained beside the executable
  (`<extract>\ .dart_tool\sqflite_common_ffi\databases\muaman_store.db`) and is
  treated as a runtime artifact, not a release-file change; run1 and run2 DBs
  are byte-identical (deterministic seed import).

Historical guards stay green on the final HEAD: `guard_tests_13l.ps1` reports
L1..L8 `allPass=true` (including a fresh 13K G1..G10 suite), and
`guard_tests_13m.ps1` reports M1..M7 `pass=true`. M8 is documented below as an
expected phase-lineage difference.

`flutter analyze` reports **No issues found** and `flutter test` runs
**380 tests, all passed** on the final HEAD (after a plain `flutter pub get`
which only regenerates the gitignored `.dart_tool/package_config.json`; no
tracked file changed).

## 3. Constraints honoured

- Exactly **one** commit after the baseline `14da91a`; `HEAD^` equals the
  baseline; no push, tag, merge, rebase, or upstream; final tree clean.
- The baseline was confirmed at the exact commit `14da91a1525...` with a clean
  tree before any 13N work; branch and baseline verified via `git rev-parse`.
- No edits to `lib/`, `windows/`, `assets/`, `pubspec.yaml`, `pubspec.lock`,
  dependencies, DB schema, business logic, or UI. Production diff vs baseline
  is empty.
- Only the canonical packaging entrypoint `tools/release/package_windows_release.ps1`
  was used to reproduce the 13M package (inner build/verify steps were never
  called directly as a substitute).
- The reproduced package matches the 13M identity exactly: **13 files /
  33,273,462 bytes / cross-hash
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`**, ZIP
  SHA-256 `57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`,
  14,485,278 bytes, 13 entries, constant entry timestamp `2024-01-01T00:00:00`.
- Consumer root `C:\mu13n-consumer\20260806\` is outside the repository and all
  worktrees. Launch PATH is `C:\Windows\System32;C:\Windows`; APPDATA,
  LOCALAPPDATA, TEMP, TMP and USERPROFILE are fresh per-run profiles; PUB_CACHE,
  FLUTTER_ROOT, DART_HOME and DART_SDK are cleared.
- Negative control runs only on a disposable third copy; the authoritative
  package is never modified.
- Evidence: UTF-8 no BOM, UTC timestamps, `/`-normalized relative paths,
  deletion only under the consumer root, consistent uppercase hashes. No
  secrets or personal data in any evidence.

## 4. Consumer-launch guards N1..N12

| Guard | Meaning | run1 | run2 | negative |
|-------|---------|------|------|----------|
| N1  | harness parameters / input paths valid | PASS | PASS | PASS |
| N2  | consumer launch environment independent (no build tooling) | PASS | PASS | n/a |
| N3  | inbound archive identity matches MUAMAN-13M contract | PASS | PASS | PASS |
| N4  | archive copy is a real copy (not a hard link), hash matches | PASS | PASS | PASS |
| N5  | extraction safe, yields exactly the 13 canonical files | PASS | PASS | PASS |
| N6  | pre-launch manifest: extracted files match legal manifest | PASS | PASS | **FAIL (rejected)** |
| N7  | isolated launch: fresh profile + minimal PATH + correct CWD | PASS | PASS | n/a |
| N8  | liveness: process alive after 20 s with a main window | PASS | PASS | n/a |
| N9  | module-origin: no loads from repo/SDK/cache/build roots | PASS | PASS | n/a |
| N10 | post-launch manifest: 13 release files remain byte-identical | PASS | PASS | n/a |
| N11 | clean termination via the main window | PASS | PASS | n/a |
| N12 | verdict aggregation and evidence completeness | PASS | PASS | PASS |

Negative-control N6 detail (evidence `21-negative-control.json`):
`size: flutter_windows.dll act=4096 exp=18181632; hash: flutter_windows.dll`.
The harness refuses to launch and reports `REJECTED`.

## 5. How the verification was executed

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  C:\dev\muaman\tools\muaman13n\verify_consumer_launch.ps1 `
  -ConsumerRoot C:\mu13n-consumer\20260806 `
  -RepositoryRoot C:\dev\muaman `
  -Mode all
```

`Mode all` performs: inbound copy + hash/safety checks, fresh extraction,
pre-launch manifest equality, isolated 20 s launch with liveness + module
snapshot, clean termination, post-launch manifest equality for run1 and run2,
then the negative-control mode on a third tampered copy. Exit code 0; the
canonical package and legal manifest are never modified.

The 13M package reproduction itself was executed through the canonical
entrypoint from the accepted 13M release directory and reproduced the exact 13M
identity (see `C:\m13n\p1-package\evidence\`).

## 6. Module-origin evidence

run1 loaded 78 modules: 73 from `C:\Windows\System32`, 4 from the extract
directory (the app itself plus its bundled DLLs), and 1 from the OS WinSxS
common-controls component (`COMCTL32.dll` 5.82.26100.5074). run2 identical
distribution. `violations=0`, `verdict=PASS` for both. The native SQLite
source is the OS `winsqlite3.dll` (v3.43.2, present in System32) via
`package:sqlite3`; `package:sqflite_common_ffi` ships its own DLL only for
debug/dev, so this is the expected release behaviour and is acceptable for the
module-origin guard (System32 is an allowed root; the guard flags only modules
outside System32 and the extract directory).

## 7. Historical guards

- **L1..L8 (13L)** - `guard_tests_13l.ps1` from the final HEAD:
  `allPass=true`; includes L5 fresh 13K suite G1..G10 `allPass=true`, no source
  changes, build and preflight hashes match; L7 release comparison vs the 13K
  legal manifest: 13/33,273,462 bytes, `diffs=0`, cross
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`.
- **M1..M7 (13M)** - `guard_tests_13m.ps1` from the final HEAD:
  `pass=true` for M1, M2, M3, M3static, M4, M5, M6, M7 (including N1..N4
  negative controls).
- **M8 (13M)** - `pass=false` **by design**: the 13M suite bakes in the 13M
  phase expectations `expectedBranch=codex/muaman-13m-canonical-deterministic-release-package`
  and `expectedBaseline=ea80321f...`. On the 13N HEAD the branch and baseline
  differ by definition. Lineage facts are otherwise correct and green:
  `descendsFromBaseline=true` (14da91a descends from ea80321f),
  `revListCountAfterBaseline=1`, `mergeCommitCount=0`, `tagAtHead=` (none),
  `productionDiff=[]`, `dependencyDiff=[]`, `sdkDiff=[]`, `pluginDiff=[]`.
  This is documented as an expected phase-lineage difference, not a defect.
- **G1..G10 (13K)** - re-run fresh via L5: `allPass=true`.

## 8. Static analysis and tests

- `flutter analyze` (from `app\`, after `flutter pub get`):
  **No issues found** (exit 0).
- `flutter test` (from `app\`): **380 tests, all passed** (exit 0).
- `pub get` writes only to the gitignored `app\.dart_tool\`; `git status` and
  `git diff` confirm no tracked file changed.

## 9. Evidence inventory

`docs/muaman-13n/evidence/` (22 numbered files, copied from the harness
`C:\mu13n-consumer\20260806\evidence\`):

| # | File | What it proves |
|---|------|----------------|
| 01-02 | `inbound-run1/2.json` | archive copy + hash + non-hardlink (N3, N4) |
| 03-04 | `extract-safety-run1/2.json` | safe extraction, 13 canonical files, no traversal (N5) |
| 05-06 | `pre-manifest-run1/2.json` | pre-launch manifest equality vs legal manifest (N6) |
| 07-08 | `env-probe-run1/2.json` | isolated env: no Flutter/Dart/Git/CMake/Ninja/VS tools on PATH (N2) |
| 09-10 | `launch-run1/2.json` | isolated launch params: fresh profile, minimal PATH, CWD (N7) |
| 11-12 | `liveness-run1/2.json` | process alive after 20 s with main window (N8) |
| 13-14 | `modules-run1/2.json` | module-origin proof: no repo/SDK/cache loads (N9) |
| 15-16 | `post-manifest-run1/2.json` | post-launch manifest equality of the 13 release files (N10) |
| 17-18 | `result-run1/2.json` | per-run guard verdicts, clean termination (N11) |
| 19 | `inbound-negative.json` | negative-control inbound copy |
| 20 | `extract-safety-negative.json` | negative-control extraction |
| 21 | `negative-control.json` | tampered `flutter_windows.dll` detected and rejected |
| 22 | `consumer-launch-verdict.json` | aggregated N12 verdict: overall PASS, exit 0 |

Supporting external evidence (not committed): the reproduced package and its
verification under `C:\m13n\p1-package\` and the 13L/13M guard outputs under
`C:\m13n\guards\`.

## 10. Constraints not changed / not done

No installer, no code signing, no auto-update, no network/cloud/mobile work,
no performance work, no tooling restructure, no fixes to out-of-scope issues,
no partial pass, and no production/dependency/SDK/plugin/MSBuild change.

## 11. Conclusion

The MUAMAN-13M canonical deterministic Windows release package is a portable,
self-contained artifact: an independent consumer with no repository, no
Flutter/Dart SDK, no PUB_CACHE, no Git, no CMake/Ninja and no Visual Studio
build tools can download the ZIP, unpack it, and launch the store. Two
independent runs passed every guard, the negative control proved tampering is
detected and refused, historical guards remain green, and the single
verification commit contains only the harness plus evidence. **Outcome A
(verified launch) is accepted.**
