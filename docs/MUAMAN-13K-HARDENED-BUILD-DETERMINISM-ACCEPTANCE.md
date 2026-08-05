# MUAMAN-13K — Hardened Fresh-Process Build Determinism Acceptance

**Status:** PASS — three cold-cache `flutter build windows --release` runs, each in
a genuinely fresh PowerShell process under the committed MUAMAN-13J hardened
wrapper, produced byte-identical Release payloads (13 files / 33,273,462 bytes,
cross-hash `EE892B35…`) across two independent source trees, two independent
SDK installations, two independent pub caches and HOME roots, and TEMP roots of
length 13, 53 and 11 characters.
**Baseline:** commit `e426710b…` (MUAMAN-13J; `rev-list --count` after baseline = 0).
**Date:** 2026-08-05 (UTC timestamps inside).

---

## 1. Purpose and scope

Prove that the 13J hardened build (committed wrapper
`tools/muaman13j/build_hardened.ps1` + fresh-process preflight
`tools/muaman13j/check_filetracker_state.ps1`) is **deterministic and
environment-independent** when every FileTracker-relevant root is distinct:

- source tree A vs source tree B (independent git archives),
- SDK A vs SDK B (independent VS2026-patched Flutter SDK installs),
- PUB_CACHE A vs B, HOME/USERPROFILE A vs B,
- TEMP/TMP short (13/11 chars) vs long (53 chars),
- cold pub cache for every run, fresh PowerShell process per run (never reused),
- no shared build tree (each run does `flutter clean` + `pub get` + build).

Each run is executed by `tools/muaman13k/run_fresh_hardened.ps1`, which spawns a
brand-new `powershell.exe` running a self-contained per-run `runner.ps1`; the
runner constructs the environment, invokes the committed wrapper from the
**independent source tree** (never from the controller worktree), and records
process identity, inherited/effective environment, timestamps, stdout/stderr,
and exit code.

## 2. Outcome

PASS. All three runs:
- `cleanExitCode=0`, `pubGetExitCode=0`, `buildExitCode=0`,
- `fileTrackerCrash=false`, `compilerIdSuccess=true`, `configureSuccess=true`,
  `releaseBuildSuccess=true`,
- captured 12 UTF-16LE MSBuild `tmp*.rsp` response files each (FileTracker
  production activity under the hardened TEMP root),
- produced a Release directory of exactly 13 files, 33,273,462 bytes.

Pairwise manifest comparison: **0 file diffs** in every pair (K1-K2, K2-K3,
K1-K3); cross-run canonical hash identical
`EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`.
Release path-leak scan: **leakFree=true, 0 findings** across all seven isolation
roots. Negative control K4 (injected empty FileTracker statics) confirms the
preflight genuinely fails fast and the wrapper refuses the build, then recovers
under an intact environment.

## 3. Constraints honoured

- Zero changes to `app/lib`, `app/pubspec.yaml`, `app/pubspec.lock`; no
  dependency updates; production diff empty (git status shows only new
  `docs/evidence/muaman-13k/` and `tools/muaman13k/`).
- No binary/PE patching, no timestamp zeroing, no copying of outputs between A/B.
- Secrets hygiene: the inherited/effective environment snapshots in each run had
  the live `OPENCODE_SERVER_PASSWORD` value redacted to `<redacted>` before
  commit, and `tools/muaman13k/run_fresh_hardened.ps1` now excludes
  `OPENCODE_SERVER_*` variables from those dumps so the credential is never
  captured again.
- No shared SDK / PUB_CACHE / TEMP / HOME / build roots between A and B.
- No reused PowerShell process: K1/K2/K3 fresh PIDs `6928 / 11424 / 15120`,
  each with a distinct parent PID.
- Every run does `flutter clean` + `flutter pub get` + `flutter build
  windows --release -v` under the hardened environment.
- Exactly one experiment commit after baseline; no push/tag/merge/rebase/history
  rewrite.
- Evidence under `docs/evidence/muaman-13k/`; this report at
  `docs/MUAMAN-13K-HARDENED-BUILD-DETERMINISM-ACCEPTANCE.md`.

## 4. Baseline state (verified)

- HEAD = `e426710b4fdc7a295a9715604b4bcbe0835eaf0fb` (MUAMAN-13J);
  `rev-list --count` after baseline = 0; tree clean at start.
- Committed script fingerprints (G2): `build_hardened.ps1` =
  `7627DC43E6779FCE7F0713C58DBD06BF7D635CEFD4D3CFD6B450C1A0093A37A5`,
  `check_filetracker_state.ps1` =
  `88D4908532F2F6862B77A89FFFD3B86097C2646BE861117D0BB95B745B397CB7`.
- SDKs carry the identical VS2026 generator patch (`visual_studio.dart` postimage
  `D08E9D71E978FDE1478FBF438DCEA6D16D26EA966D271F7D5108AC86E3CC5423` in both A
  and B); verified unchanged (G3).

## 5. Environment topology

| role | A | B |
|------|---|----|
| SDK root | `C:\m13i\a\sdk` | `C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk` (77 chars) |
| app root | `C:\m13k\a\src\app` (17 chars) | `C:\dev\muaman-13k-environment-b-independent-source-extraction-root\app` (70 chars) |
| PUB_CACHE | `C:\m13k\a\pub` (13 chars, cold) | `C:\dev\muaman-13k-environment-b-independent-pub-cache-root` (58 chars, cold per run) |
| TEMP/TMP | `C:\m13k\a\tmp` (13 chars) | K2: long root (53 chars); K3: `C:\t\m13k-b` (11 chars) |
| HOME/USERPROFILE | `C:\m13k\a\home` | `C:\dev\muaman-13k-environment-b-independent-home-root` (53 chars) |
| toolchain | VS2026 BuildTools, MSBuild 18.6.3+84d3e95b4, MSVC 14.51.36231, v145, CMake 4.2.3-msvc3 | identical |

Both SDKs carry the hash-guarded VS2026 Flutter generator patch
(`visual_studio.dart` → `D08E9D71…`), identical to 13I/13J evidence (G3).
Full pre-run inventory: `03-sdk-and-cache-isolation/isolated-root-inventory.txt`.

## 6. Runs

| | K1 | K2 | K3 |
|---|----|----|----|
| source / SDK | A / A | B / B | B / B |
| TEMP | `C:\m13k\a\tmp` (13) | B long (53) | `C:\t\m13k-b` (11) |
| fresh PID | 6928 | 11424 | 15120 |
| outer duration | 165.4 s | 162.5 s | 169.8 s |
| build elapsed | 101.2 s | 107.6 s | 107.6 s |
| clean / pubget / build exit | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| FileTracker crash | no | no | no |
| compiler-ID / configure / release | yes / yes / yes | yes / yes / yes | yes / yes / yes |
| rsp captures | 12 | 12 | 12 |
| payload | 13 files / 33,273,462 B | same | same |

All rsp captures are UTF-16LE BOM files under each run's hardened TEMP root
(`MSBuildTemp*`), recorded into `rsp-capture/` per run. Analysis JSON per run:
`05-analysis.json`.

## 7. Determinism comparison

- `k1-k2-release-comparison.json`: directory walk, 13/13 files,
  33,273,462/33,273,462 bytes, `identical=true`, cross-hash match.
- `k1-k2-k3-manifest-comparison.json`: canonical manifest file entries,
  **0 diffs** for K1-K2, K2-K3, K1-K3; 0 only-in-A/B each.
- Cross-run canonical hash (sorted `rel|size|sha256` lines, UTF-8 SHA-256):
  `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9` for every
  run.

Conclusion: the hardened fresh-process build is byte-for-byte deterministic
across independent source, SDK, pub-cache, HOME, and TEMP roots of differing
length.

## 8. Release path-leak scan (G4)

`k1-leak-scan.json`: 13 files scanned for all isolation-root tokens in raw-ASCII
(case-insensitive) and UTF-16LE encodings → **0 findings, leakFree=true**.
No Release payload artifacts (exe/dll/app.so/icudtl.dat) exist anywhere under
`docs/evidence/muaman-13k` (G4 artifact-copy check).

## 9. Guard-point verification

`tools/muaman13k/guard_tests.ps1` → `guard-results.json`, **allPass=true**:

- G1 no production-source change — deferred to git: `git status` shows only new
  `docs/evidence/muaman-13k/` and `tools/muaman13k/`.
- G2 committed scripts unchanged — recorded hashes match expected.
- G3 SDKs unmodified — `visual_studio.dart` postimage hash matches 13I/13J in A
  and B.
- G4 release payload not copied into evidence — verified (0 payload files).
- G5 no PE/post-processing binaries — only committed dart/powershell tooling used.
- G6 no reused PowerShell process — PIDs distinct (6928/11424/15120).
- G7 no silent fallback — every run has `01-preflight.log` with `PREFLIGHT: OK`.
- G8 no stale-output success — per run, `muaman_store.exe` and `data\app.so`
  (always freshly compiled/linked after `flutter clean`) are newer than the run
  start; SDK-copied engine files (`flutter_windows.dll`, `icudtl.dat`,
  `MaterialIcons-Regular.otf`) legitimately retain SDK mtimes and are excluded.
- G9 deterministic payload — 13 files / 33,273,462 bytes per run, identical.

Three guard-script fixes were applied in `tools/muaman13k/guard_tests.ps1`
during this phase so the guard reports the true state:

1. G3 — reads the recorded hash **content** of the `visual_studio-dart-*-sha256.txt`
   evidence files (`Read-Txt`) instead of hashing the `.txt` files themselves,
   so the comparison is against the documented VS2026 generator patch hash.
2. G7/G8 — access per-run verdicts through the `OrderedDictionary` API
   (`runs[$run]` / `runs.Keys`) instead of `PSObject.Properties`, which threw on
   `[ordered]@{}` and produced no verdicts.
3. G8 — excludes SDK-copied engine files (`flutter_windows.dll`, `icudtl.dat`,
   `MaterialIcons-Regular.otf`), which legitimately retain the SDK artifact's
   mtime, from the freshness check; only the freshly compiled/linked
   `muaman_store.exe` and `data\app.so` are required to be newer than run start.

With the fixes, `guard_tests.ps1` reports `allPass=true` and exits 0.

## 10. Negative control (K4) — the preflight is load-bearing

`07-k4-negative-preflight-control/k4-summary.json`, **k4Pass=true**:

- A: injecting an empty static `s_applicationDataPath` / `s_tempPath` into the
  FileTracker state assembly makes the committed preflight exit 1 and report
  `is empty` diagnostics (`a-inject-*.log`).
- B: under the injected state the wrapper **refuses to build** — exit 1, no
  pub-get/build/analysis evidence, diagnostic names the empty static
  (`b-wrapper-exit-code.txt`, `b-wrapper-refusal/`).
- C: recovery — with a clean environment the real committed preflight exits 0
  and reports `PREFLIGHT: OK` (`c-recovery-positive-preflight.log`).

This proves the preflight genuinely detects the empty-path FileTracker state that
13J eliminates, and that the hardened path (not a silent fallback) is what
produced the K1/K2/K3 payloads.

## 11. Evidence index

```
docs/evidence/muaman-13k/
  00-baseline/                  baseline commits, status, branch, revcount
  01-script-audit/              audit notes + committed-script hashes
  02-source-independence/       A/B tree equality, head, origin, no build state
  03-sdk-and-cache-isolation/   root inventory, SDK identity, patch hashes
  04-k1-source-a-sdk-a-shorttemp/  run K1 (process/env/logs/analysis/rsp/manifest)
  05-k2-source-b-sdk-b-longtemp/   run K2
  06-k3-source-b-sdk-b-shorttemp/  run K3
  07-k4-negative-preflight-control/  negative control (empty-static injection)
  k1-k2-release-comparison.json    directory-level byte comparison
  k1-k2-k3-manifest-comparison.json all-pairs manifest diff
  k1-leak-scan.json                release path-leak scan
  guard-results.json               guard-point verdicts
  acceptance-summary.json          machine-readable acceptance summary

tools/muaman13k/
  run_fresh_hardened.ps1      fresh-process controller (per-run runner generation)
  make_release_manifest.ps1   canonical Release manifest generator
  compare_release.ps1         directory-level byte comparison
  leak_scan_13k.ps1           ASCII + UTF-16LE path-leak scanner
  guard_tests.ps1             guard-point verification
  k4_harness.ps1 / run_k4.ps1 negative-control harness (test-seam copy of wrapper)
```

## 12. Acceptance result

**PASS.** The 13J hardened fresh-process build is deterministic and
environment-independent: three cold builds from independent source/SDK/pub/HOME
roots with TEMP lengths 13/53/11 produced byte-identical Release payloads, with
a verified load-bearing FileTracker preflight and zero path leaks.
