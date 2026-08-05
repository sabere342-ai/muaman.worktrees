# MUAMAN-13L — Canonical Hardened Windows Release Entrypoint Adoption

**Status:** PASS — the canonical entrypoint
`tools/release/build_windows_release.ps1` is adopted and verified: CWD-independent,
fail-closed, secret-clean, scope-limited, historically guard-compatible, and it
produced a fresh-clone Release byte-identical to the MUAMAN-13K legal payload
(13 files / 33,273,462 bytes, cross-hash `EE892B35…`, 0 diffs, legal-tool
cross-check identical). All 13L guards L1–L8 report `allPass=true`.
**Baseline:** commit `4556c84c3ca6a22c9a14e91cc5c5bdefe77fe259` (MUAMAN-13K;
`rev-list --count` after baseline = 0, final count = 25).
**Branch:** `codex/muaman-13l-canonical-hardened-release-entrypoint-adoption`.
**Date:** 2026-08-05 (UTC timestamps inside).

---

## 1. Purpose and scope

Adopt a **single canonical entrypoint** for producing a MUAMAN Windows Release so
that every developer, pipeline, and future phase drives the same hardened build
path. Before 13L, the hardened build could only be started by calling the
MUAMAN-13J wrapper
(`tools/muaman13j/build_hardened.ps1`) directly, which:

- required an explicit `-AppRoot` and could not locate the repository itself,
- hard-coded its MSBuild default (fine as a committed default, but not
  discoverable),
- had no standalone "preflight first, fail closed" contract visible at the
  entrypoint boundary.

13L adds a **thin, discoverable, CWD-independent operational interface**:

```
tools/release/build_windows_release.ps1
```

It resolves the repository root from its own script location, discovers the Flutter
SDK / PUB_CACHE / MSBuild instead of hard-coding them, runs the committed
MUAMAN-13J FileTracker preflight **first** in a fresh process, exits non-zero
before any pub-get/build if the environment is unsafe (fail-closed), and then
delegates the build unchanged to the committed source of truth.

The scope is **tools and documentation only**:

- new `tools/release/build_windows_release.ps1` — canonical entrypoint,
- new `tools/release/verify_release.ps1` — 13L release verification (reuses the
  committed 13K legal manifest and `compare_release.ps1`),
- new `tools/release/guard_tests_13l.ps1` — 13L guard-point verification,
- `docs/MUAMAN-13L-CANONICAL-HARDENED-WINDOWS-RELEASE-ENTRYPOINT.md` — this report,
- `docs/evidence/muaman-13l/` — evidence.

No production code, dependency, SDK, plugin, or MSBuild change is made.

## 2. Outcome

**PASS.** The canonical entrypoint is verified by `tools/release/guard_tests_13l.ps1`
(`allPass=true` for L1–L8, `03-verification/guard-results.json`):

- is **CWD-independent** — it resolves the same repository root when invoked from
  the repo root, from a sub-folder, and from outside the repository (L2);
- is **single-source-of-truth** — it contains no second implementation of the
  FileTracker logic and no direct `flutter build windows --release`; it delegates
  to `tools/muaman13j/build_hardened.ps1` (L1);
- is **fail-closed** — the committed preflight runs before any pub-get/build in a
  fresh process; a preflight failure or an unusable environment produces a
  non-zero exit with no build artifacts (L3);
- is **secret-clean** — the commit tree contains no `OPENCODE_SERVER_PASSWORD`
  value (L4, `secrecy-scan.json` findingCount=0);
- keeps the **historical 13K guards passing** (L5, `allPass=true`);
- produced a **fresh-clone Release build** equal to the 13K legal payload: 13
  files / 33,273,462 bytes, cross-hash
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`, 0 diffs,
  legal-tool cross-check identical (L6+L7);
- is the **only documented release path** — the active release docs use the
  canonical command and never direct users to a raw `flutter build windows --release`
  (L8).

## 3. Constraints honoured

- Exactly **one** commit after the 13K baseline
  (`4556c84c3ca6a22c9a14e91cc5c5bdefe77fe259`); no intermediate commits, no
  push/tag/merge/rebase/history rewrite.
- Change scope limited to `tools/`, `docs/` (with `docs/evidence/muaman-13l/`).
  **No** `lib/`, `app/lib/`, `windows/runner/`, `windows/flutter/`,
  `pubspec.yaml`, `pubspec.lock`, `app/pubspec.yaml`, or `app/pubspec.lock`
  changes; production diff empty (verified by final `git status`/scope audit).
- **No production/dependency/SDK/plugin/MSBuild changes.**
- The hardened build logic stays where it is (MUAMAN-13J/K committed tooling); the
  entrypoint is an operational interface, not a re-implementation.
- **No duplicated FileTracker logic** in the new scripts — the preflight and the
  build both live in the committed 13J/K source of truth.
- Secrets hygiene: no live `OPENCODE_SERVER_*` value is captured into any log or
  evidence file; the secrecy scan (L4) proves the commit tree is clean.
- No SDK / build / cache artifacts are committed under
  `docs/evidence/muaman-13l/`; only text/JSON evidence.
- Scripts follow the repository conventions: UTF-8 no-BOM source, CRLF working
  tree (LF in git via `i/lf w/crlf`).

## 4. Baseline state (verified)

- HEAD = `4556c84c3ca6a22c9a14e91cc5c5bdefe77fe259` (MUAMAN-13K accept);
  `rev-list --count` = 24, tree clean at phase start (only new `tools/release/`
  and `docs/evidence/muaman-13l/` untracked).
- Committed source-of-truth fingerprints (unchanged, G2): `build_hardened.ps1` =
  `7627DC43E6779FCE7F0713C58DBD06BF7D635CEFD4D3CFD6B450C1A0093A37A5`,
  `check_filetracker_state.ps1` =
  `88D4908532F2F6862B77A89FFFD3B86097C2646BE861117D0BB95B745B397CB7`.
- Legal 13K manifest: `docs/evidence/muaman-13k/04-k1-source-a-sdk-a-shorttemp/release-manifest.json`
  — 13 files / 33,273,462 bytes; canonical cross-hash
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`.
- VS2026 generator patch postimage hash (both A/B SDKs): `D08E9D71…`.

## 5. Canonical entrypoint design (Model A — wrapper, single source of truth)

`tools/release/build_windows_release.ps1` is a thin operational interface
(325 lines including documentation). Execution order:

1. **Repository root** — derived from `$PSScriptRoot`
   (`tools/release` → `tools` → repo root) and validated against committed
   markers (`app/pubspec.yaml`, `tools/muaman13j/build_hardened.ps1`,
   `tools/muaman13j/check_filetracker_state.ps1`). Never derived from the current
   directory.
2. **Run identity and stage roots** — `-ExperimentId` (default
   `L-<UTC>-<PID>`), `-StageRoot` (default under `%TEMP%`), `-EvidenceDir`,
   `-TmpRoot`, `-HomeRoot`; all created up front.
3. **SDK discovery** — `-SdkRoot` → `$env:FLUTTER_ROOT` → `flutter.bat` on PATH;
   requires `bin\flutter.bat`. No hard-coded drive letters or user names.
4. **PUB_CACHE discovery** — `-PubCache` → `$env:PUB_CACHE` →
   `%LOCALAPPDATA%\Pub\Cache`.
5. **MSBuild discovery** — `-MsBuildBinDir` → vswhere
   (`MSBuild\**\Bin\amd64\MSBuild.exe`, fallback `Bin\MSBuild.exe`) requiring
   `Microsoft.Build.Utilities.Core.dll`. No hard-coded install path.
6. **Delegation targets** — the committed preflight and wrapper paths are checked
   to exist before anything runs.
7. **PREFLIGHT (first gate)** — spawns a **fresh** `powershell.exe` running
   `tools/muaman13j/check_filetracker_state.ps1 -MsBuildBinDir <discovered>`;
   output captured to `00-entrypoint-preflight.log`; `preflight-result.json` is
   written; on failure the entrypoint prints a refusal and **exits 1 before any
   `flutter pub get` / `flutter build`** (fail-closed). `-PreflightOnly` exits
   here with 0 on PASS.
8. **BUILD** — delegates to `tools/muaman13j/build_hardened.ps1` with the
   discovered SDK/pub-cache/MSBuild and the stage roots (hardened environment,
   its own fresh-process preflight, then the 13I isolated runner).
9. **Result capture** — `build-result.json`, `release-dir.txt`, `exit-code.txt`;
   success requires build exit 0 **and** `muaman_store.exe` present.
10. **Canonical manifest** — regenerated via the committed legal generator
    `tools/muaman13k/make_release_manifest.ps1` (no new manifest logic).

Exit codes: `0` success · `1` preflight failed (no build) · `2` environment
resolution failure · `3` build failed · `4` unexpected error.

The entrypoint **never** runs `flutter build windows --release` itself and
contains **no** FileTracker reflection code — those live only in the committed
13J/K source of truth. L1 guards this statically.

## 6. Canonical command

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/release/build_windows_release.ps1
```

Optional switches: `-SdkRoot`, `-PubCache`, `-MsBuildBinDir`, `-StageRoot`,
`-EvidenceDir`, `-TmpRoot`, `-HomeRoot`, `-ExperimentId`, `-PreflightOnly`.
The exact command used for the fresh-clone build is recorded in
`docs/evidence/muaman-13l/canonical-command.txt` and `01-clone/clone-metadata.json`.

This is the **only** documented release path. Raw `flutter build windows --release`
is **NOT** the supported release command; it is only ever executed *inside* the
committed hardened runner as part of the canonical path (as in 13K).

## 7. Guard-point verification (L1–L8)

`tools/release/guard_tests_13l.ps1` → `docs/evidence/muaman-13l/03-verification/guard-results.json`,
**allPass=true** (final run after the fresh-clone build; see evidence):

- **L1 static delegation** — the entrypoint contains none of the forbidden
  FileTracker/reflection/build tokens (`Microsoft.Build.Utilities.FileTracker`,
  `GetField(`, `SetValue(`, `LoadFrom(`, `System.Reflection.Assembly`,
  `FileIsExcludedFromDependencies`, `FileIsUnderNormalizedPath`,
  `s_applicationDataPath`/`s_tempPath`/etc., `build windows --release`) in
  executable code, no hard-coded drive-letter absolute paths, and it references
  both `build_hardened.ps1` and `check_filetracker_state.ps1` as delegation
  targets.
- **L2 CWD independence** — the entrypoint with `-PreflightOnly` resolves the
  SAME repository root from (a) the repo root, (b) `tools/release`, (c) a
  directory outside the repository; each run exits 0.
  `03-verification/cwd-independence-results.json`.
- **L3 preflight ordering + fail-closed** — (static) the preflight invocation is
  source-ordered before the wrapper invocation with a fail-closed `exit 1`
  between them, and the source of truth orders its own preflight before the
  runner; (dynamic) `-PreflightOnly -MsBuildBinDir <unusable>` exits non-zero and
  produces **no** wrapper/build artifacts; committed K4 negative control still
  reports `k4Pass=true`.
- **L4 secret hygiene** — byte-level scan of the whole working tree (ASCII +
  UTF-16LE) for the live `OPENCODE_SERVER_PASSWORD` value and for
  `OPENCODE_SERVER_*=…` assignments → **0 findings**.
  `03-verification/secrecy-scan.json`.
- **L5 historical guards** — `tools/muaman13k/guard_tests.ps1` re-run in a fresh
  process against the committed 13K evidence → `allPass=true`, exit 0
  (`03-verification/guard-results-13k-fresh.json`).
- **L6 fresh-clone build** — one fresh `git clone --no-local` of the branch at a
  dedicated root; the canonical command runs from a CWD **outside** the clone
  root; preflight PASS + build exit 0 + Release produced
  (`01-clone/clone-metadata.json`, `02-run/*`).
- **L7 release verification** — `tools/release/verify_release.ps1` compares the
  fresh-clone Release against the committed 13K legal manifest: file count 13,
  total 33,273,462 bytes, cross-hash
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`, 0 per-file
  diffs; optionally cross-checked byte-for-byte against the committed
  `tools/muaman13k/compare_release.ps1`.
  `03-verification/release-comparison.json`.
- **L8 active-docs guard** — this report documents the canonical command and does
  not direct users to `flutter build windows --release` as the supported release
  command (a mention, if any, must declare it unsupported).

## 8. Fresh-clone build (L6)

A dedicated clone root (`C:\m13l\src`, short path) holds a `git clone --no-local`
of the branch commit that contains the tools/docs (checkout `773dc95`, branch
`codex/muaman-13l-probe`). The canonical command was run with the controller CWD
set to `C:\m13l` — **outside** the clone root — so the entrypoint had to resolve
the repository root from its own script location:

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\m13l\src\tools\release\build_windows_release.ps1 -SdkRoot C:\m13i\a\sdk -ExperimentId L6 -EvidenceDir C:\m13l\evidence
```

- repository root resolved to `C:\m13l\src` (the clone), not the CWD,
- entrypoint first gate: committed preflight in a fresh process → `PASS` (exit 0),
- hardened build delegated to the source of truth → build exit 0,
- duration 242.3 s (start `20:22:49Z`, end `20:26:51Z`),
- Release produced at `C:\m13l\src\app\build\windows\x64\runner\Release`.

Identity, clone URL/root, checkout commit, controller CWD, exact command, and
timestamps are recorded in `docs/evidence/muaman-13l/01-clone/clone-metadata.json`
and `01-clone/canonical-command.txt`. The run's `preflight-result.json`,
`build-result.json`, `release-manifest.json` and `release-dir.txt` are committed
under `02-run/`. The SDK was pinned to the committed 13I/13K SDK A (carrying the
`visual_studio.dart` postimage `D08E9D71…`); PUB_CACHE and MSBuild were
auto-discovered by the entrypoint.

## 9. Release verification (L7)

`tools/release/verify_release.ps1` reads the fresh Release dir and the committed
legal manifest and computes: file count, total bytes, per-file size/SHA256 diffs,
and the canonical cross-hash (sorted `rel|size|sha256` lines, UTF-8 SHA-256,
uppercase — the same serialization used by the 13K legal tooling). It exits 0 only
when the fresh payload matches the legal payload exactly. When a reference release
dir is available it also delegates a byte-for-byte comparison to the committed
`tools/muaman13k/compare_release.ps1`. Results:
`docs/evidence/muaman-13l/03-verification/release-comparison.json` (own verifier)
and `release-comparison-legal-tool.json` (legal-tool cross-check).

Fresh-clone result (L6/L7): `fileCountNew=13`, `totalBytesNew=33,273,462`,
`diffCount=0`, `onlyInLegalCount=0`, `onlyInNewCount=0`,
`crossHashNew=EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`,
`identical=true`; legal-tool compare vs the K1 reference release:
`A=13/33273462B B=13/33273462B identical=True diffs=0 crossA=crossB=EE892B35…`.

## 10. Secret hygiene and scope audit

- **Secrecy (L4):** `secrecy-scan.json` reports `scannedFiles` (whole tree) and
  `findingCount = 0`. No `OPENCODE_SERVER_*` value is written by the entrypoint,
  the verifier, or the guard harness; evidence files contain no environment dumps
  of inherited variables (unlike 13K's redacted snapshots, 13L evidence captures
  no secret-bearing environment at all).
- **Scope:** `scope-audit.json` enumerates every path in the final commit vs the
  baseline: additions are limited to `tools/release/`, `docs/evidence/muaman-13l/`,
  and the governing report; **zero** changes to `app/lib`, `windows/`,
  `pubspec.*`; no dependency/SDK/plugin/MSBuild files.

## 11. Post-commit gates

After the single final commit:

- `git diff HEAD^ --check` clean (no whitespace errors),
- `git status --short` empty (clean working tree),
- `rev-list --count HEAD` = 25 (exactly one commit after baseline 24),
- scope audit on the committed diff (`git diff-tree --no-commit-id --name-only -r`)
  limited to the allowlist,
- baseline subject/commit recorded in `00-baseline/final-commit.txt`,
- full guard pass (L1–L8) re-run and recorded as the committed
  `03-verification/guard-results.json`.

Commit-flow note: the deliverable branch carries **exactly one commit** after the
13K baseline. A throwaway probe branch (`codex/muaman-13l-probe`) was used to
commit the tools/docs so a fresh clone could be built from a committed state; that
branch was deleted and never touches the deliverable branch history. The
post-commit gate outputs (`final-commit.txt`, `git-verification.txt`) were
captured after the commit and folded into the same single commit with
`git commit --amend --no-edit`, so the branch retains exactly one commit after
baseline with the complete evidence set.

## 12. Evidence index

```
docs/evidence/muaman-13l/
  00-baseline/                   baseline.txt, branch.txt, initial-state.txt,
                                 final-commit.txt (post-commit)
  canonical-command.txt          exact canonical command
  01-clone/                      clone-metadata.json, canonical-command.txt (L6)
  02-run/                        preflight-result.json, build-result.json,
                                 release-manifest.json, release-dir.txt (L6)
  03-verification/               guard-results.json, guard-results-13k-fresh.json,
                                 cwd-independence-results.json, secrecy-scan.json,
                                 scope-audit.json, release-comparison.json,
                                 release-comparison-legal-tool.json,
                                 git-verification.txt (post-commit)

tools/release/
  build_windows_release.ps1      canonical hardened Windows release entrypoint
  verify_release.ps1             13L release verification (legal-manifest compare)
  guard_tests_13l.ps1            13L guard-point verification (L1–L8)
```

No SDK / build / cache artifacts, no binaries, and no secret-bearing files are
committed under evidence.

## 13. Model-selection rationale

**Model A (wrapper) was chosen over Model B (re-implemented entrypoint)** because
the hardened build logic already exists and is proven (13I/13J/13K). Re-implementing
FileTracker hardening inside `tools/release` would create a second, drift-prone
copy of the most safety-critical logic and contradict 13J's own conclusions. The
wrapper keeps a single source of truth, and the guards enforce that the entrypoint
remains a thin operational interface forever.

## 14. Risks and mitigations

- **Drift** — the entrypoint could grow build logic later. Mitigation: L1 scans
  for the forbidden tokens/patterns in the committed entrypoint on every guard
  pass.
- **New VS/SDK default drift** — MSBuild discovery uses vswhere rather than a
  pinned path, with an explicit `-MsBuildBinDir` override. SDK and PUB_CACHE are
  explicit or environment-discovered; deterministic builds pin them via switches.
- **False confidence in preflight ordering** — the wrapper's own committed
  preflight (13J) still runs under the hardened environment after the entrypoint
  gate; L3 asserts ordering at both layers and keeps K4 as the negative control.

## 15. Acceptance result

**PASS.** All 13L outcome criteria hold (see `03-verification/guard-results.json`,
`secrecy-scan.json`, `scope-audit.json`, `release-comparison.json`, and the
post-commit `git-verification.txt`): the canonical hardened Windows release
entrypoint is adopted, CWD-independent, fail-closed, secret-clean,
scope-limited, historically guard-compatible, and produces a fresh-clone Release
byte-identical to the 13K legal payload. The deliverable branch contains exactly
one commit after baseline `4556c84…` with a clean tree.
