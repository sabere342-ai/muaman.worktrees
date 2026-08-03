# MUAMAN-13D — Independent Committed-State Reproducibility Acceptance

## A. Executive Summary

| Item | Value |
| ---- | ----- |
| Outcome | `Outcome A — VERIFIED COMMITTED-STATE REPRODUCIBILITY` |
| Baseline commit | `d810e9dc4017829d8750e0f560d81243a200110e` (`MUAMAN-13C: enable reproducible Windows release linking`) |
| Branch | `codex/muaman-13d-independent-committed-state-reproducibility-acceptance` |
| Worktree | `C:\dev\muaman.worktrees\muaman-13d-independent-committed-state-reproducibility-acceptance` |
| Change | **None** to production code or build configuration — acceptance-only deliverables (orchestrator + 2 tools + committed evidence + this report) |
| Independent clean builds | 2 (run-1, run-2), each: `flutter clean` → `flutter pub get` → `flutter build windows --release`, from the pristine committed state `d810e9dc…` |
| Release directory determinism | **13 of 13 files byte-identical** (100% of 33,273,462 bytes) across the two runs |
| Manifest determinism | Canonical sections byte-identical (`sha256 3e93a6d386f31780b0191259a079a79344b7c58ac52670fecc1a3c5fdd0d2fd9` in both runs) |
| ZIP determinism | Same-snapshot proven for both runs; **cross-build byte-identical** (`sha256 334A75A0…648E8C0F`, all four ZIPs) |
| PE timestamp determinism | COFF + debug-directory timestamps identical across builds (`muaman_store.exe = 3525092928`, `printing_plugin.dll = 1526935272`) |
| Relink determinism | Real `link.exe` command lines for EXE and DLL both contain `/machine:x64 /Brepro` (both runs) |
| Linker command evidence | `/Brepro` present exactly once for both targets in both runs |
| Reconciliation with MUAMAN-13C | 10 of 13 files byte-identical to the recorded 13C artifacts; 3 locally-compiled files (`data/app.so`, `muaman_store.exe`, `printing_plugin.dll`) differ **only** in embedded absolute build-path metadata (see section X); all sizes identical; lockfile and toolchain identical |
| Production behavior modified | No (`app/lib` diff vs baseline is empty) |
| Push / Tag / Merge / Rebase / Squash | No |
| Final commit | 1 (single) commit after baseline |

Two fully independent clean Windows release builds were produced from the exact committed state (`d810e9dc…`, the MUAMAN-13C acceptance commit) with no source, dependency, or build-configuration change. The entire release directory is **byte-for-byte reproducible**: all 13 files, the canonical manifests, the deterministic ZIPs, and every PE timestamp are identical across the two runs. This is the committed-state reproducibility acceptance evidence for the MUAMAN-13C change. Because both builds ran from an unmodified working tree with an unchanged `pubspec.lock` (`EBDDB5D8…D3331A`) and the identical toolchain (Flutter 3.24.5, MSVC 14.51, CMake 4.3.3, VS 18.6.0), the proof confirms that the committed state alone determines the release output.

## B. Outcome Statement

```text
Outcome A — VERIFIED COMMITTED-STATE REPRODUCIBILITY

Two independent clean Windows release builds from the pristine committed state
d810e9dc4017829d8750e0f560d81243a200110e produce a byte-for-byte identical
release directory: 13/13 files (33,273,462 bytes), identical canonical manifest
(3e93a6d3…2fd9), identical deterministic ZIPs (334A75A0…8E8C0F), and identical
PE timestamps, with /Brepro present in the real link commands for both PEs.

Reconciliation with the historical MUAMAN-13C artifacts:
  10/13 files byte-identical; 3 files differ in size-identical artifacts solely
  due to embedded absolute build-path metadata (see section X). This is fully
  explained and does not indicate non-determinism: the two runs inside 13D,
  built at the same path, are byte-identical.
```

## C. Scope

Executed:

- Verify the baseline commit and its exact identity (`d810e9dc4017829d8750e0f560d81243a200110e`).
- Independent clean worktree + branch created from the baseline (no source/config modification).
- **Two** fully independent clean builds: per run `flutter clean` → `flutter pub get` (lockfile guarded) →
  `flutter build windows --release` → snapshot `Release/` **outside** `app/build` so a later `flutter clean` can never destroy earlier
  evidence.
- Deterministic canonical manifest per snapshot (relative path + size + full SHA-256, sorted, no time-varying meta in the compared
  section).
- Read-only PE/COFF inspection (`tool/pe_inspect.dart`): COFF header timestamp, debug-directory timestamps, machine, linker version,
  OS version, checksum, size of image, SHA-256 — for `muaman_store.exe`, `printing_plugin.dll`, `flutter_windows.dll`, `pdfium.dll`.
- Evidence relink per run: delete the two PE outputs and re-link them with MSBuild `/v:diag`, capturing the **real** `link.exe` command
  lines (diag-link-exe.log, diag-link-dll.log).
- Linker evidence (`tool/linker_evidence.dart`) from the generated `*.vcxproj` files + the diag logs.
- Deterministic ZIP builder; same-snapshot ZIP determinism proof (each snapshot packaged twice); cross-build ZIP equality.
- Cross-build comparison at four levels: file bytes, canonical manifest, PE timestamps, ZIP bytes.
- **Baseline reconciliation** against the historical MUAMAN-13C artifacts (file hashes, canonical manifest, ZIP, PE timestamps,
  toolchain, lockfile) → `baseline-reconciliation.json`.
- **Final verification build** after all evidence was frozen: a fresh release build whose 13 output hashes were re-checked against the
  run-1 manifest (`mismatches=0`).
- Gates: `dart format`, `flutter analyze`, `flutter test`, Windows integration smoke test, `git diff --check`.
- Acceptance report + single final commit; no Push/Tag/Merge.

Not executed (explicitly out of scope):

- **No `lib/` (production) code change** — verified empty against the baseline.
- **No dependency, SDK, MSVC, or plugin-source changes** — `pubspec.lock` unchanged (`EBDDB5D8…D3331A`).
- **No build-configuration change** — `windows/CMakeLists.txt` untouched; the `/Brepro` contract from MUAMAN-13C is preserved and its
  guard test still passes.
- **No binary patching, no timestamp zeroing, no post-link normalization.**
- **No build-dir commit, no binary in Git.**
- No code signing, no publish tooling, no CI wiring.

## D. Source Provenance

```text
$ git rev-parse HEAD
d810e9dc4017829d8750e0f560d81243a200110e
$ git branch --show-current
codex/muaman-13d-independent-committed-state-reproducibility-acceptance
$ git rev-list --count d810e9dc4017829d8750e0f560d81243a200110e..HEAD
0        (at experiment start)
```

The worktree was created from the baseline commit SHA (the MUAMAN-13C acceptance commit):

```text
$ git worktree add -b codex/muaman-13d-independent-committed-state-reproducibility-acceptance ^
    C:\dev\muaman.worktrees\muaman-13d-independent-committed-state-reproducibility-acceptance ^
    d810e9dc4017829d8750e0f560d81243a200110e
```

The working tree was clean (`cleanTreeAtStart=true` in `environment.json`) and remained clean of tracked modifications through both
builds. `flutter pub get` did not alter `pubspec.lock` in either run (SHA-256
`EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A`, unchanged, identical to the 13C lockfile). The Flutter tool
regenerates some tracked `generated_plugin_registrant*` files with LF line endings; `git diff` (autocrlf-normalized) shows **no content
change** for them, so they are not part of the 13D change set and were restored before the final commit.

## E. Environment

```text
Windows:      Microsoft Windows 11 Pro, 64-bit, build 26200 (recorded in environment.json)
Hostname:     ISLAM
Flutter:      3.24.5 (stable) — Dart 3.5.4
CMake:        4.3.3
Visual Studio Build Tools: 2026 (catalog product 18.6.0)
  path:       C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools
MSBuild:      C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe (18.6.3.22110)
MSVC toolset: 14.51.36231 (link.exe FileVersion 14.51.36243.0)
link.exe:     C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64\link.exe
flutter path: C:\src\flutter\bin\flutter.bat
dart path:    C:\src\flutter\bin\dart.bat
Architecture: x64
```

Every toolchain element (`flutter13d`, `dart13d`, `cmake13d`, `vs13d`) matches the recorded MUAMAN-13C environment
(`toolchainMatches13c=true`). Full details are recorded in `environment.json` under `docs/muaman-13d/evidence/`.

## F. Experiment Design

Each run is fully independent:

```text
run-N:
  1. assert working state equals the pre-run snapshot (git status --porcelain) and tree is clean
  2. flutter clean
  3. flutter pub get            (guard: pubspec.lock SHA-256 must be unchanged)
  4. flutter build windows --release
  5. snapshot Release/ -> <work root>\runs\run-N\snapshot   (outside app/build)
  6. canonical manifest -> run-N-manifest.json
  7. PE inspection of the snapshot's 4 PE files -> run-N-pe-inspection.json
  8. release inventory (13 files, PE classification, timestamps) -> run-N-inventory.json
  9. evidence relink: delete the 2 PE outputs, re-link via MSBuild /v:diag,
     capture the real link.exe command lines (diag-link-exe.log, diag-link-dll.log)
 10. linker evidence -> run-N-linker-evidence.json  (vcxproj + diag logs)
 11. binary SHA-256 of the relinked 4 PEs -> run-N-binary-sha256.json
```

After both runs:

```text
 12. deterministic ZIP per snapshot (twice each), compare hashes  -> zip-comparison.json
 13. cross-build file/size/hash comparison                        -> comparison.json
 14. cross-build PE timestamp comparison                          -> pe-comparison.json
 15. file last-write/creation times of the run-2 snapshot         -> run-2-file-times.json
 16. baseline reconciliation vs historical MUAMAN-13C artifacts   -> baseline-reconciliation.json
 17. environment.json
```

Work root: `C:\Users\saber\AppData\Local\Temp\opencode\muaman-13d-acceptance`. Small, committed evidence JSONs are mirrored into
`docs/muaman-13d/evidence/`; heavy snapshots/ZIPs/logs stay in the work root (gitignored) with locations recorded in
`artifact-locations.json`.

## G. Run Results

| | run-1 | run-2 |
| ---- | ---- | ---- |
| Started at (UTC) | `2026-08-03T19:08:00.0360430Z` | `2026-08-03T19:09:51.6351552Z` |
| Built at (UTC, meta) | `2026-08-03T19:09:35.0706241Z` | `2026-08-03T19:12:35.3939942Z` |
| Build duration (`flutter build windows --release`) | 95.0 s | 163.8 s |
| Working state unchanged during build | true | true |
| `pubspec.lock` SHA-256 | `EBDDB5D8…D3331A` | `EBDDB5D8…D3331A` (same) |
| File count | 13 | 13 |
| Total bytes | 33,273,462 | 33,273,462 |

The two builds are separated by a full `flutter clean` between them and ran at least 95 s apart in wall-clock time, so a genuinely
independent build and timestamp are embedded in each; the outputs still match byte-for-byte.

## H. Release Directory Content Determinism (Level 1)

Full per-file comparison (run-1 vs run-2, canonical manifest):

```text
#  status   sizeBytes  sha256 (first 16)  path
 1. SAME      7324576  7e0047423e8ad1ac  data/app.so
 2. SAME          117  00af55ad3d6f2189  data/flutter_assets/AssetManifest.bin
 3. SAME          109  4a9b3de7eec9ba46  data/flutter_assets/AssetManifest.json
 4. SAME          208  cd7e03645bc44b2d  data/flutter_assets/FontManifest.json
 5. SAME        89152  ab7675dac8c7dcdf  data/flutter_assets/NOTICES.Z
 6. SAME      1645184  d9865b671a09d683  data/flutter_assets/fonts/MaterialIcons-Regular.otf
 7. SAME       257628  67c44fe9183b002e  data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
 8. SAME        17304  3aa09424d1dc391f  data/flutter_assets/shaders/ink_sparkle.frag
 9. SAME       778864  c12537022ef81899  data/icudtl.dat
10. SAME     18181632  b66713715a7aeaa2  flutter_windows.dll
11. SAME        90624  a7cff7e5c0fbf5cf  muaman_store.exe
12. SAME      4749824  0c88ebacc0393fd4  pdfium.dll
13. SAME       138240  0235520a7ca7c21a  printing_plugin.dll
```

Result: **13 of 13 files (100% of 33,273,462 bytes) are byte-identical.** `comparison.json` records
`identical=true`, `allFilesByteIdentical=true`, `changedFiles=[]`, `addedFiles=[]`, `removedFiles=[]`,
`sameSizeDifferentHashFiles=[]`, `fileCount=13`, `totalBytes=33273462`.

## I. Manifest Determinism (Level 2)

- Canonical sections of the two full manifests are byte-identical: same 13 relative paths, same sort order, same per-file `sizeBytes` and
  `sha256`, same `fileCount` (13) and `totalBytes` (33,273,462).
- `run1CanonicalManifestSha256 = run2CanonicalManifestSha256 = 3e93a6d386f31780b0191259a079a79344b7c58ac52670fecc1a3c5fdd0d2fd9`.
- Full-manifest `meta` differs only in `runId` and `builtAt`, both intentionally excluded from the canonical comparison.

## J. ZIP Determinism (Level 3)

Deterministic ZIP construction: entries sorted by normalized relative path, fixed UTC timestamp (`2000-01-01T00:00:00Z`), fixed deflate
level, relative paths only, canonical manifest embedded as `manifest.canonical.json`.

```text
run-1-a.zip / run-1-b.zip / run-2-a.zip / run-2-b.zip
  14,482,661 B each, sha256 334A75A0A60BDC02807A2FB0F70B3F0E4C867EA6B00E287F116EB367648E8C0F
```

- **Same-snapshot determinism: proven** for both runs (`run1aEqualsRun1b=true`, `run2aEqualsRun2b=true`).
- **Cross-build ZIP equality: true** — all four ZIPs are the identical byte stream (`allFourZipsByteIdentical=true`).

## K. PE Timestamp Determinism (Level 4)

`pe_inspect.dart` records the COFF header timestamp and every IMAGE_DEBUG_DIRECTORY timestamp per file, plus full SHA-256.

```text
file                coffTimeDateStamp  debug timestamps             byteIdentical
muaman_store.exe    3525092928         3525092928, 3525092928        true
printing_plugin.dll 1526935272         1526935272, 1526935272        true
flutter_windows.dll 1731463209         1731463209 ×3                 true
pdfium.dll          1654405200         1654405200 ×2                 true
```

`pe-comparison.json`: `allFilesByteIdentical=true`; every `coffTimeDateStampRun1 == coffTimeDateStampRun2` and all debug timestamps
equal across runs. The two linker-produced PEs (`muaman_store.exe`, `printing_plugin.dll`) carry deterministic `/Brepro`-derived
timestamps identical in both runs; the other two PEs are static SDK/plugin binaries with identical timestamps as well.

## L. Relink Determinism Proof

For each run, after snapshotting, the two PE outputs were deleted and re-linked with the identical generated command (MSBuild
`-v:diag`). The relinked binaries were re-hashed and recorded (`run-N-binary-sha256.json`):

```text
run-1 exe  a7cff7e5c0fbf5cf4dd2c5809827220b2861353be741ddb0cc0205b08b6c04d3
run-1 dll  0235520a7ca7c21aded291e866746f7bd82d9063ee7c5d6d0ef383e243079834
run-2 exe  a7cff7e5c0fbf5cf4dd2c5809827220b2861353be741ddb0cc0205b08b6c04d3
run-2 dll  0235520a7ca7c21aded291e866746f7bd82d9063ee7c5d6d0ef383e243079834
```

These match the snapshot hashes in section H exactly. The final verification build (section O) reproduces the same 13 hashes again,
proving the link step is reproducible under forced re-link and under a fresh build.

## M. Linker Command Evidence

`linker_evidence.dart` parses the generated `*.vcxproj` files (the actual commands MSBuild will run) and extracts the real `link.exe`
command line executed from the `-v:diag` logs. Both targets in both runs report `/Brepro` present exactly once:

```text
target=muaman_store     configuration=Release|x64  breproPresent=true  breproOccurrences=1  linkCommand=true
target=printing_plugin  configuration=Release|x64  breproPresent=true  breproOccurrences=1  linkCommand=true
```

Real executed command lines (excerpts, run-1):

```text
muaman_store:    ...muaman_store.lib" /MACHINE:X64  /machine:x64 /Brepro muaman_store.dir\Release\Runner.res
printing_plugin: ...printing_plugin.lib" /MACHINE:X64  /machine:x64 /Brepro /DLL printing_plugin.dir\Release\printing.obj
```

`allTargetsBreproPresent=true`. The Debug/Profile configuration blocks in the generated projects are untouched (no `/Brepro`). Evidence
JSONs: `docs/muaman-13d/evidence/run-1-linker-evidence.json`, `run-2-linker-evidence.json`.

## N. Build-Config Change

**None.** `app/windows/CMakeLists.txt` is byte-identical to the baseline. The `/Brepro` Release-only linker flags introduced in MUAMAN-13C
are preserved exactly as committed; the `brepro_build_config_guard_test.dart` guard still passes. This phase is purely an acceptance
verification of the committed state.

## O. Gates

| Gate | Command | Result | Exit Code |
| ---- | ------- | ------ | --------- |
| Baseline identity | `git rev-parse HEAD` | `d810e9dc4017829d8750e0f560d81243a200110e` | 0 |
| Branch | `git branch --show-current` | `codex/muaman-13d-independent-committed-state-reproducibility-acceptance` | 0 |
| Working state unchanged during builds | `git status --porcelain` compare | unchanged, clean (both runs) | 0 |
| Clean build outputs | `flutter clean` | OK (both runs) | 0 |
| Dependencies | `flutter pub get` | `pubspec.lock` unchanged, matches 13C (both runs) | 0 |
| Format | `dart format --output=none --set-exit-if-changed .` | 12 files, 0 changed | 0 |
| Analyze | `flutter analyze` | No issues found! | 0 |
| Unit/widget tests | `flutter test` | 282 passed, 0 failed, 0 skipped | 0 |
| Integration (Windows) | `flutter test integration_test/login_invoice_smoke_test.dart -d windows` | 1 passed, 0 failed, 0 skipped | 0 |
| Whitespace | `git diff --check` | clean | 0 |
| Release build 1 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (95.0 s) | 0 |
| Release build 2 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (163.8 s) | 0 |
| Manifest generation | `dart run tool/repro_manifest.dart …` | 13 files hashed (both runs) | 0 |
| PE inspection | `dart run tool/pe_inspect.dart …` | 4 PE files inspected (both runs) | 0 |
| Release inventory | `dart run tool/repro_inventory_13d.dart …` | 13 files, 4 PEs classified (both runs) | 0 |
| Linker evidence | `dart run tool/linker_evidence.dart …` | `/Brepro` present for all 2 targets (both runs) | 0 |
| ZIP generation + rebuild | `dart run tool/repro_zip.dart …` | ZIP written ×4, all identical | 0 |
| Byte comparison | `dart run tool/repro_compare.dart …` | `COMPARE OK: identical` | 0 |
| PE comparison | `dart run tool/pe_compare_13d.dart …` | `PE COMPARE OK: byte-identical` | 0 |
| Baseline reconciliation | `baseline-reconciliation.json` | 10/13 match 13C; 3 explained (section X) | 0 |
| Final verification build | `flutter build windows --release` + hash check | fresh build reproduces all 13 hashes (`mismatches=0`) | 0 |
| Production diff | `git diff <baseline> -- app/lib` | empty | 0 |
| Build config diff | `git diff <baseline> -- windows/CMakeLists.txt` | empty | 0 |

## P. Test Counts

- Unit/widget (`flutter test`, `test/` directory): **282 tests** — the full inherited suite from the 13C baseline, all passed, 0 failed,
  0 skipped. No tests were modified or removed; the 13C guard/unit tests (19) remain green and continue to protect the `/Brepro`
  build-config contract, the linker-evidence parser, and the PE inspector.
- Windows integration (live smoke, `integration_test/login_invoice_smoke_test.dart -d windows`): 1 test — login, empty-price invoice
  rejection, valid invoice save. Passed. The integration test resets its own runtime DB first, so it never touches a customer database.
- These are distinct groups; the integration test is not run by `flutter test` and is not double-counted.

## Q. Guard Tests and Tooling

Inherited guard tests (unchanged from the 13C baseline, all green):

- `test/brepro_build_config_guard_test.dart` — source build-config contract: `/Brepro` appended to the Release EXE and SHARED linker
  flags, inside `if(MSVC)`, not on Debug/Profile, no post-build binary patching.
- `test/linker_evidence_test.dart` — unit tests for `tool/linker_evidence.dart` (vcxproj Release link-block parsing, `/Brepro`
  presence/count, Debug isolation, real link-command extraction, UTF-8/UTF-16 decoding).
- `test/pe_inspect_test.dart` — unit tests for `tool/pe_inspect.dart` (COFF/debug timestamps, non-PE rejection, `compareInspections`
  semantics).

New 13D tooling (all read-only over build outputs):

- `tool/run_repro_13d.ps1` — orchestrator implementing this acceptance experiment end to end (the reproducibility script).
- `tool/repro_inventory_13d.dart` — release-directory inventory: 13 files, PE classification, size + SHA-256 + PE timestamp per file.
- `tool/pe_compare_13d.dart` — cross-run PE inspection comparison (byte-identical + timestamp equality).

## R. Change Set

```text
A  app/tool/run_repro_13d.ps1           (tooling — acceptance orchestrator)
A  app/tool/repro_inventory_13d.dart    (tooling — release inventory)
A  app/tool/pe_compare_13d.dart         (tooling — PE comparison)
A  app/docs/MUAMAN-13D-INDEPENDENT-COMMITTED-STATE-REPRODUCIBILITY-ACCEPTANCE.md   (documentation)
A  app/docs/muaman-13d/evidence/*.json  (small artifact — committed evidence)
```

Classification: Tooling, Documentation, and small committed JSON evidence only. No production code, no dependencies, no build
configuration change, no platform file change.

## S. Production Diff Verification

```text
$ git diff d810e9dc4017829d8750e0f560d81243a200110e -- app/lib
(empty)

$ git diff d810e9dc4017829d8750e0f560d81243a200110e -- windows/CMakeLists.txt
(empty)

$ git diff d810e9dc4017829d8750e0f560d81243a200110e -- pubspec.yaml pubspec.lock
(empty)
```

The production `lib/` tree, the Windows build configuration, and the dependency manifests are byte-identical to the baseline.

## T. Risks and Limitations

- The determinism proof is specific to this toolchain snapshot (Flutter 3.24.5, MSVC 14.51, Release x64) and to this checkout path. A
  toolchain upgrade may change `/Brepro` behaviour; the guard test protects the build-config contract but not the toolchain.
- The three locally-compiled files (`data/app.so`, `muaman_store.exe`, `printing_plugin.dll`) embed **absolute build-path metadata**
  (section X). Building the same committed state in a differently-named directory produces a different binary for exactly those files —
  this is a property of the toolchain (path-derived lambda-RTTI names, embedded `file:///` URIs) and is why byte equality with the
  historical 13C artifacts holds for 10 of 13 files only. It is not a determinism defect: within one path, two independent clean builds
  are byte-identical (proven here), and a third fresh build reproduced the identical hashes.
- `flutter clean` / the integration build regenerate some tracked `generated_plugin_registrant*` files with LF line endings (content
  unchanged after autocrlf normalization); they were restored before the final commit and are not part of the 13D change set.
- The `pdfium.dll` and `flutter_windows.dll` timestamps are static (prebuilt inputs); the proof of determinism rests on the two
  linker-produced PEs plus all other files, which are byte-identical.
- The application is not code-signed (pre-existing); SmartScreen may warn on first run. Unchanged here.
- Relink determinism is proven for identical inputs/commands; a source change that alters link inputs will, correctly, change the binary
  (including its `/Brepro`-derived timestamp).

## U. Reproducibility Instructions

Run the committed orchestrator from the app directory:

```text
powershell -ExecutionPolicy Bypass -File tool\run_repro_13d.ps1 ^
    -AppRoot <app> -WorkRoot <work root>
```

It reproduces the entire acceptance experiment end to end: two independent clean builds, snapshots, manifests, PE inspection, evidence
relinks, linker evidence, release inventory, deterministic ZIPs, all comparisons, baseline reconciliation, and the committed evidence
mirror. Individual steps are documented in `environment.json` `commands`.

## V. Artifacts

Committed under `app/docs/muaman-13d/evidence/` (small JSON):

```text
comparison.json               (Level-1 byte comparison; identical=true)
pe-comparison.json            (Level-4 PE timestamp comparison; all byte-identical)
zip-comparison.json           (Level-3 ZIP hashes; all four byte-identical)
baseline-reconciliation.json  (13D vs historical 13C; 10/13 match, 3 explained)
environment.json              (OS/toolchain/paths/commands/run timings)
artifact-locations.json       (heavy artifact locations and hashes)
run-1-manifest.json           (canonical + meta manifest)
run-2-manifest.json
run-1-inventory.json          (release inventory: 13 files, 4 PEs)
run-2-inventory.json
run-1-pe-inspection.json      (PE metadata of the 4 PE files)
run-2-pe-inspection.json
run-1-linker-evidence.json    (vcxproj + real link commands)
run-2-linker-evidence.json
run-1-binary-sha256.json      (relinked PE hashes)
run-2-binary-sha256.json
run-2-file-times.json         (snapshot file creation/last-write times)
```

Heavy artifacts (snapshots, ZIPs, diag logs, build logs) are preserved in
`C:\Users\saber\AppData\Local\Temp\opencode\muaman-13d-acceptance\` with locations recorded in `artifact-locations.json`.

## W. Comparison with MUAMAN-13C

| | 13C historical artifacts | 13D run-1 / run-2 |
| ---- | ---- | ---- |
| Release files identical to 13C | — | **10 / 13** byte-identical |
| Differing files (13D) | — | `data/app.so`, `muaman_store.exe`, `printing_plugin.dll` (sizes identical) |
| Canonical manifest | `f61a25e7…e24e3381` | `3e93a6d3…d2fd9` (both runs, identical to each other) |
| Deterministic ZIP | `561D4943…9BD94FEB34` | `334A75A0…648E8C0F` (both runs, all four identical) |
| `muaman_store.exe` PE timestamp | `4212839308` | `3525092928` (both runs, equal) |
| `printing_plugin.dll` PE timestamp | `4105333590` | `1526935272` (both runs, equal) |
| Linker version | `14.51.36243.0` | `14.51.36243.0` (match) |
| `pubspec.lock` | `EBDDB5D8…D3331A` | `EBDDB5D8…D3331A` (match) |
| Toolchain (Flutter/Dart/CMake/VS) | 3.24.5 / 3.5.4 / 4.3.3 / 18.6.0 | 3.24.5 / 3.5.4 / 4.3.3 / 18.6.0 (match) |
| Cross-build determinism (two clean builds) | verified (13C) | **re-verified, byte-identical (this phase)** |

The 13C artifacts were built in a differently-named worktree (`muaman-13c-enable-brepro-full-windows-determinism`). The three
differing files are precisely the locally-compiled artifacts that embed absolute build-path metadata; every other file (prebuilt SDK
DLLs, ICU data, and all `flutter_assets`) is byte-identical to the 13C artifacts.

## X. Analysis: Why the 3 Files Differ from 13C

The two runs inside 13D are byte-identical to each other — determinism within the committed state is proven. The three files that
differ from the *historical 13C artifacts* do so for a fully determined reason: they embed absolute build-path metadata whose bytes
depend on the checkout directory name, which differs between the 13C worktree and the 13D worktree.

- **`data/app.so`** — the Dart AOT snapshot embeds the absolute source path, including a `file:///` URI pointing at
  `…\muaman-13d-independent-committed-state-reproducibility-acceptance\app\.dart_tool\flutter_build\…\dart_plugin_registrant.dart`.
  Same size (7,324,576 B), scattered small (1–70 byte) differences localized to path-bearing regions; string tables are otherwise
  identical.
- **`muaman_store.exe` / `printing_plugin.dll`** — MSVC emits lambda-RTTI names whose hash is derived from the source path, e.g.
  `<lambda_7c786b5666b85dd1061714a325a14d4e>` (13D) vs `<lambda_38cf32145e538265ef2e3ca7412348d4>` (13C); the `/Brepro`-derived
  COFF/debug timestamps (a hash of link inputs, which include those path-bearing objects) also differ: `3525092928` vs `4212839308`
  (exe) and `1526935272` vs `4105333590` (dll). A 32-byte digest region differs as well.

Because determinism is defined as *identical committed state + identical environment + identical checkout path → identical output*, and
both 13D runs share that exact triple and are byte-identical, this phase accepts the committed state as reproducible. Byte-equality with
the historical 13C artifacts is not achievable from a differently-named directory for these three files, and this is a documented
toolchain property, not a non-determinism.

## Y. Evidence Chain of Custody and Independence

- Run-2 was a fully independent build: `flutter clean` deleted all run-1 build products before run-2's configure/build; run-2 re-ran
  `flutter pub get` from the same lockfile and a fresh build.
- Run-1 binaries were never copied into run-2; the only shared inputs are the source tree (unchanged and clean) and the toolchain.
- Snapshots were taken **before** any evidence relink, so Level-1/2/3/4 comparisons describe the pristine Flutter builds.
- Evidence relinks consumed no snapshot bytes; they re-linked from intermediates and their output hashes were recorded separately
  (`run-N-binary-sha256.json`) and match the snapshots.
- All comparison tools are deterministic and were themselves proven reproducible (same-snapshot ZIP equality).
- The committed evidence was generated with the exact tools that are committed, at the exact same commits, for full provenance.
- A **final verification build** after evidence freeze reproduced all 13 release hashes (`mismatches=0`), independently confirming the
  committed state.

## Z. Final Verdict

```text
Outcome A — VERIFIED COMMITTED-STATE REPRODUCIBILITY
```

All mandatory gates passed. Two independent clean Windows release builds from the pristine committed state `d810e9dc…` (the MUAMAN-13C
acceptance commit) produce a byte-for-byte identical release directory (13/13 files, 33,273,462 bytes), identical canonical manifests
(`3e93a6d3…d2fd9`), identical deterministic ZIPs (all four `334A75A0…648E8C0F`), identical PE timestamps, and real-link-command proof that
`/Brepro` reaches both the executable and the plugin DLL. Reconciliation with the historical 13C artifacts is fully accounted for: 10/13
files byte-identical; the 3 locally-compiled files differ only in embedded absolute build-path metadata (section X) and are identical
across the two 13D runs. No production code, dependencies, or build configuration were touched; no binaries are patched; there is exactly
one commit after the baseline; no Push, no Tag, and the final tracked tree is clean.

## AA. Commit Identity

```text
$ git log --oneline d810e9dc4017829d8750e0f560d81243a200110e..HEAD
<single commit> MUAMAN-13D: accept committed Windows reproducibility
```

## AB. File-by-File Determinism Table (run-1 vs run-2)

See section H for the full table; all 13 entries are `SAME` with identical SHA-256 in both runs.

## AC. Environment Command Record

The exact commands executed are recorded in `docs/muaman-13d/evidence/environment.json` under `commands` and in `run_repro_13d.ps1`.

## AD. Future Work

- Track MSVC `/Brepro` behaviour across toolchain upgrades; keep the guard tests green.
- Consider normalizing embedded absolute build-path metadata (e.g. reproducible kernel snapshot / relative RTTI) if cross-directory byte
  equality becomes a requirement.
- Optionally extend determinism proof to `flutter build windows --profile` and CI release pipelines.
- Consider signing/notarization as a separate, orthogonal concern.
