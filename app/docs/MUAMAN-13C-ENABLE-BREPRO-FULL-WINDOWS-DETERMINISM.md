# MUAMAN-13C — Enable Reproducible Windows Linking and Prove Full Byte Determinism

## A. Executive Summary

| Item | Value |
| ---- | ----- |
| Outcome | `Outcome A — VERIFIED FULL BYTE-FOR-BYTE DETERMINISM` |
| Baseline commit | `8acccfdf3181a5bb326cdb827cfe5f6c11b71352` (`MUAMAN-13B: verify deterministic Windows release rebuilds`) |
| Branch | `codex/muaman-13c-enable-brepro-full-windows-determinism` |
| Worktree | `C:\dev\muaman.worktrees\muaman-13c-enable-brepro-full-windows-determinism` |
| Change | MSVC `/Brepro` enabled for Release in `app/windows/CMakeLists.txt` (EXE + SHARED linker flags) |
| Independent clean builds | 2 (run-1, run-2), each: `flutter clean` → `flutter pub get` → `flutter build windows --release` |
| Release directory determinism | **13 of 13 files byte-identical** (100% of 33,273,462 bytes) |
| Manifest determinism | Canonical sections byte-identical (`sha256 f61a25e7…e24e3381` in both runs) |
| ZIP determinism | Same-snapshot: proven for both runs. **Cross-build: byte-identical** (`sha256 561D4943…9BD94FEB34`) |
| PE timestamp determinism | COFF + debug-directory timestamps identical across builds (`muaman_store.exe = 4212839308`, `printing_plugin.dll = 4105333590`) |
| Relink determinism | Forced relink of both PE outputs reproduces the snapshot bytes exactly (both runs) |
| Linker command evidence | Real `link.exe` command lines for EXE and DLL both contain `/machine:x64 /Brepro` |
| Production behavior modified | No (`app/lib` diff vs baseline is empty) |
| Push / Tag / Merge / Rebase / Squash | No |
| Final commit | 1 (single) commit after baseline |

Two fully independent clean Windows release builds were produced from the exact same baseline commit. The previously non-deterministic PE
files (`muaman_store.exe` and `printing_plugin.dll`) are now **byte-identical across the two builds**, so the entire release directory is
byte-for-byte reproducible. This is achieved by a single, minimal build-configuration change: appending MSVC's `/Brepro` reproducible-link
option to the Release EXE and SHARED linker flags. Every one of the 13 release files — including the Flutter AOT snapshot `data/app.so`,
`flutter_windows.dll`, `pdfium.dll`, `data/icudtl.dat`, and all `data/flutter_assets/*` — is byte-identical between the runs. The proof chain
(byte comparison, canonical manifests, deterministic ZIPs, PE timestamp inspection, and the real linker command lines) is captured in
machine-readable evidence committed under `docs/muaman-13c/evidence/`.

## B. Outcome Statement

```text
Outcome A — VERIFIED FULL BYTE-FOR-BYTE DETERMINISM

Before (MUAMAN-13B): 11/13 files identical; the only difference was the MSVC
                    link.exe wall-clock timestamp in 2 PE files (4 bytes total).
After  (MUAMAN-13C): 13/13 files byte-identical; all timestamps deterministic.
```

## C. Scope

Executed:

- Verify the baseline commit and its exact identity (`8acccfdf3181a5bb326cdb827cfe5f6c11b71352`).
- Independent clean worktree + branch created from the baseline.
- Enable MSVC `/Brepro` for Release in `app/windows/CMakeLists.txt`, on the configuration-wide
  `CMAKE_EXE_LINKER_FLAGS_RELEASE` and `CMAKE_SHARED_LINKER_FLAGS_RELEASE` (so every executable and every plugin DLL target inherits it;
  Debug/Profile untouched).
- **Two** fully independent clean builds: per run `flutter clean` → `flutter pub get` (lockfile guarded) →
  `flutter build windows --release` → snapshot `Release/` **outside** `app/build` so a later `flutter clean` can never destroy earlier
  evidence.
- Deterministic canonical manifest per snapshot (relative path + size + full SHA-256, sorted, no time-varying meta in the compared
  section).
- Read-only PE/COFF inspection (`tool/pe_inspect.dart`): COFF header timestamp, debug-directory timestamps, machine, linker version,
  OS version, checksum, size of image, SHA-256 — for `muaman_store.exe`, `printing_plugin.dll`, `flutter_windows.dll`, `pdfium.dll`.
- Evidence relink per run: delete the two PE outputs and re-link them with MSBuild `/v:diag`, capturing the **real** `link.exe` command
  lines, then prove the relinked binaries are byte-identical to the snapshot.
- Linker evidence (`tool/linker_evidence.dart`) from the generated `*.vcxproj` files + the diag logs.
- Deterministic ZIP builder; same-snapshot ZIP determinism proof (each snapshot packaged twice); cross-build ZIP equality.
- Cross-build comparison at four levels: file bytes, canonical manifest, PE timestamps, ZIP bytes.
- Guard/unit tests for the build-config contract, the linker-evidence parser, and the PE inspector.
- Gates: `dart format`, `flutter analyze`, `flutter test`, Windows integration smoke test, `git diff --check`.
- Phase report + single final commit; no Push/Tag/Merge.

Not executed (explicitly out of scope):

- **No `lib/` (production) code change** — verified empty against the baseline.
- **No dependency, SDK, MSVC, or plugin-source changes** — the printing plugin is still built from the unmodified symlinked source.
- **No binary patching, no timestamp zeroing, no post-link normalization.**
- **No build-dir commit, no binary in Git.**
- No code signing, no publish tooling, no CI wiring.

## D. Source Provenance

```text
$ git rev-parse HEAD
8acccfdf3181a5bb326cdb827cfe5f6c11b71352
$ git branch --show-current
codex/muaman-13c-enable-brepro-full-windows-determinism
$ git rev-list --count 8acccfdf3181a5bb326cdb827cfe5f6c11b71352..HEAD
0        (at experiment start)
```

The worktree was created from the baseline commit SHA:

```text
$ git worktree add -b codex/muaman-13c-enable-brepro-full-windows-determinism ^
    C:\dev\muaman.worktrees\muaman-13c-enable-brepro-full-windows-determinism ^
    8acccfdf3181a5bb326cdb827cfe5f6c11b71352
```

`flutter pub get` did not alter `pubspec.lock` in either run (SHA-256
`EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A`, unchanged before and after each run).

Because the 13C build-config change is intentionally uncommitted while the experiment runs (it is committed once at the very end), the
orchestrator does not require a clean tracked tree. Instead it records `git status --porcelain` before the run and asserts the working state
is **exactly unchanged** after every build (builds must never modify tracked files; the only 13C-tracked delta is `windows/CMakeLists.txt`
and `tool/repro_compare.dart`). Both runs passed this check. The Flutter tool regenerates some tracked `generated_plugin_registrant*` files
with LF line endings; `git diff` (autocrlf-normalized) shows **no content change** for them, so they are not part of the 13C change set.

## E. Environment

```text
Windows:      Microsoft Windows 11 Pro, 64-bit (recorded in environment.json)
Flutter:      3.24.5 (stable) — Dart 3.5.4
CMake:        4.3.3
Visual Studio Build Tools: 2026 (catalog product 18.6.0)
  path:       C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools
MSBuild:      C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe
MSVC toolset: 14.51.36231 (link.exe FileVersion 14.51.36243.0)
link.exe:     C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64\link.exe
flutter path: C:\src\flutter\bin\flutter.bat
dart path:    C:\src\flutter\bin\dart.bat
Architecture: x64
```

Full details (OS, versions, paths, commands) are recorded in `environment.json` under `docs/muaman-13c/evidence/`.

## F. Experiment Design

Each run is fully independent:

```text
run-N:
  1. assert working-state equals the pre-run snapshot (git status --porcelain)
  2. flutter clean
  3. flutter pub get            (guard: pubspec.lock SHA-256 must be unchanged)
  4. flutter build windows --release
  5. snapshot Release/ -> <work root>\runs\run-N\snapshot   (outside app/build)
  6. canonical manifest -> run-N-manifest.json
  7. PE inspection of the snapshot's 4 PE files -> pe-inspection.json
  8. evidence relink: delete the 2 PE outputs, re-link via MSBuild /v:diag,
     capture the real link.exe command lines (diag-link-exe.log, diag-link-dll.log)
  9. relink determinism: relinked bytes == snapshot bytes (must match)
 10. linker evidence -> linker-evidence.json  (vcxproj + diag logs)
```

After both runs:

```text
 11. deterministic ZIP per snapshot (twice each), compare hashes -> zip-comparison.json
 12. cross-build file/size/hash comparison                     -> comparison.json
 13. cross-build PE timestamp comparison                       -> pe-comparison.json
 14. environment.json
```

Work root: `C:\Users\saber\AppData\Local\Temp\opencode\muaman-13c-repro`. Small, committed evidence JSONs are mirrored into
`docs/muaman-13c/evidence/`; heavy snapshots/ZIPs/logs stay in the work root and in `app/build/artifacts/reproducibility/muaman-13c/`
(gitignored).

## G. Run Results

| | run-1 | run-2 |
| ---- | ---- | ---- |
| Built at (UTC, meta) | `2026-08-03T18:11:04.0018121Z` | `2026-08-03T18:14:24.4669424Z` |
| Build duration (`flutter build windows --release`) | 211.4 s | 168.6 s |
| Working state unchanged during build | true | true |
| `pubspec.lock` SHA-256 | `EBDDB5D8…D3331A` | `EBDDB5D8…D3331A` (same) |
| File count | 13 | 13 |
| Total bytes | 33,273,462 | 33,273,462 |

The `builtAt` meta values intentionally differ between runs (meta is excluded from canonical comparison by design). The two builds ran at
least 80 s apart in wall-clock time, so a genuinely independent timestamp is embedded in each; they still match.

## H. Release Directory Content Determinism (Level 1)

Full per-file comparison (run-1 vs run-2, canonical manifest):

```text
#  status   sizeBytes  sha256 (first 16)  path
 1. SAME      7324576  ea6f802772e272d5  data/app.so
 2. SAME          117  00af55ad3d6f2189  data/flutter_assets/AssetManifest.bin
 3. SAME          109  4a9b3de7eec9ba46  data/flutter_assets/AssetManifest.json
 4. SAME          208  cd7e03645bc44b2d  data/flutter_assets/FontManifest.json
 5. SAME        89152  ab7675dac8c7dcdf  data/flutter_assets/NOTICES.Z
 6. SAME      1645184  d9865b671a09d683  data/flutter_assets/fonts/MaterialIcons-Regular.otf
 7. SAME       257628  67c44fe9183b002e  data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
 8. SAME        17304  3aa09424d1dc391f  data/flutter_assets/shaders/ink_sparkle.frag
 9. SAME       778864  c12537022ef81899  data/icudtl.dat
10. SAME     18181632  b66713715a7aeaa2  flutter_windows.dll
11. SAME        90624  36d4959f5601d452  muaman_store.exe
12. SAME      4749824  0c88ebacc0393fd4  pdfium.dll
13. SAME       138240  622759580251ebba  printing_plugin.dll
```

Result: **13 of 13 files (100% of 33,273,462 bytes) are byte-identical.** `comparison.json` records
`identical=true`, `allFilesByteIdentical=true`, `changedFiles=[]`, `addedFiles=[]`, `removedFiles=[]`,
`sameSizeDifferentHashFiles=[]`, `fileCount=13`, `totalBytes=33273462`.

## I. Manifest Determinism (Level 2)

- Canonical sections of the two full manifests are byte-identical: same 13 relative paths, same sort order, same per-file `sizeBytes` and
  `sha256`, same `fileCount` (13) and `totalBytes` (33,273,462).
- `run1CanonicalManifestSha256 = run2CanonicalManifestSha256 = f61a25e731e61fbe2f52685b8cd0416194567910bcb653632f075e52e24e3381`.
- Full-manifest `meta` differs only in `runId` and `builtAt`, both intentionally excluded from the canonical comparison.

## J. ZIP Determinism (Level 3)

Deterministic ZIP construction: entries sorted by normalized relative path, fixed UTC timestamp (`2000-01-01T00:00:00Z`), fixed deflate
level, relative paths only, canonical manifest embedded as `manifest.canonical.json`.

```text
run-1-deterministic.zip          14,482,496 B  sha256 561D49437C9EBDFB33E6F7980CD432A24857E4AC25798E1A72D16D3BD94FEB34
run-1-deterministic.rebuild.zip  14,482,496 B  sha256 561D49437C9EBDFB33E6F7980CD432A24857E4AC25798E1A72D16D3BD94FEB34
run-2-deterministic.zip          14,482,496 B  sha256 561D49437C9EBDFB33E6F7980CD432A24857E4AC25798E1A72D16D3BD94FEB34
run-2-deterministic.rebuild.zip  14,482,496 B  sha256 561D49437C9EBDFB33E6F7980CD432A24857E4AC25798E1A72D16D3BD94FEB34
```

- **Same-snapshot determinism: proven** for both runs.
- **Cross-build ZIP equality: true** — all four ZIPs are the identical byte stream (this was the failure point in MUAMAN-13B).

## K. PE Timestamp Determinism (Level 4)

`pe_inspect.dart` records the COFF header timestamp and every IMAGE_DEBUG_DIRECTORY timestamp per file, plus full SHA-256.

```text
file                coffTimeDateStamp  debug timestamps             byteIdentical
muaman_store.exe    4212839308         4212839308, 4212839308        true
printing_plugin.dll 4105333590         4105333590, 4105333590        true
flutter_windows.dll 1731463209         1731463209 ×3                 true
pdfium.dll          1654405200         1654405200 ×2                 true
```

`pe-comparison.json`: `allFilesByteIdentical=true`; every `coffTimeDateStampEqual=true` and `debugTimeDateStampsEqual=true`. The two
linker-produced PEs (`muaman_store.exe`, `printing_plugin.dll`) carry deterministic hash-derived timestamps that are identical in both runs;
the other two PEs are static SDK/plugin binaries with identical timestamps as well.

## L. Relink Determinism Proof

For each run, after snapshotting, the two PE outputs were deleted and re-linked with the identical generated command (MSBuild `-v:diag`).
The relinked binaries were required to be byte-identical to the snapshot taken from the pristine Flutter build:

```text
run-1 exe  snapshot=36D4959F5601D452F18D389335A6C5EF302D337F1C3F277E7BE02D5D70E772D5  relink=same
run-1 dll  snapshot=622759580251EBBAA6C604FAAE99C2BEEAB2546D33CD8747B005C03C5408D7FC  relink=same
run-2 exe  snapshot=36D4959F5601D452F18D389335A6C5EF302D337F1C3F277E7BE02D5D70E772D5  relink=same
run-2 dll  snapshot=622759580251EBBAA6C604FAAE99C2BEEAB2546D33CD8747B005C03C5408D7FC  relink=same
```

This proves the link step is reproducible not only across clean builds but also under a forced re-link with identical inputs.

## M. Linker Command Evidence

`linker_evidence.dart` parses the generated `*.vcxproj` files (the actual commands MSBuild will run) and extracts the real `link.exe`
command line executed from the `-v:diag` logs. Both targets in both runs report `/Brepro` present exactly once:

```text
target=muaman_store     configuration=Release|x64  breproPresent=true  breproOccurrences=1  linkCommand=true
target=printing_plugin  configuration=Release|x64  breproPresent=true  breproOccurrences=1  linkCommand=true
```

Real executed command lines (excerpts):

```text
muaman_store:    ...muaman_store.lib" /MACHINE:X64  /machine:x64 /Brepro muaman_store.dir\Release\Runner.res
printing_plugin: ...printing_plugin.lib" /MACHINE:X64  /machine:x64 /Brepro /DLL printing_plugin.dir\Release\printing.obj
```

The Debug/Profile configuration blocks in the generated projects are untouched (no `/Brepro`). Evidence JSONs:
`docs/muaman-13c/evidence/run-1-linker-evidence.json`, `run-2-linker-evidence.json`.

## N. Build-Config Change

The only permanent build-configuration change is in `app/windows/CMakeLists.txt` (14 added lines, comment + guard):

```cmake
if(MSVC)
  string(APPEND CMAKE_EXE_LINKER_FLAGS_RELEASE " /Brepro")
  string(APPEND CMAKE_SHARED_LINKER_FLAGS_RELEASE " /Brepro")
endif()
```

- Set at the configuration-wide level so both the executable and every shared-library plugin target inherit it (the `printing` plugin is
  built by a separate CMake subproject generated under `windows/flutter/ephemeral/.plugin_symlinks/printing/`).
- Release only; Debug/Profile keep their default flags (Profile is a copy of Release taken before the append, so it is not affected).
- No post-build steps, no binary patching.

## O. Gates

| Gate | Command | Result | Exit Code |
| ---- | ------- | ------ | --------- |
| Baseline identity | `git rev-parse HEAD` | `8acccfdf3181a5bb326cdb827cfe5f6c11b71352` | 0 |
| Branch | `git branch --show-current` | `codex/muaman-13c-enable-brepro-full-windows-determinism` | 0 |
| Working state unchanged during builds | `git status --porcelain` compare | unchanged (both runs) | 0 |
| Clean build outputs | `flutter clean` | OK (both runs) | 0 |
| Dependencies | `flutter pub get` | `pubspec.lock` unchanged (both runs) | 0 |
| Format | `dart format --output=none --set-exit-if-changed .` | 61 files, 0 changed | 0 |
| Analyze | `flutter analyze` | No issues found! | 0 |
| Unit/widget tests | `flutter test` | 282 passed, 0 failed, 0 skipped | 0 |
| Integration (Windows) | `flutter test integration_test/login_invoice_smoke_test.dart -d windows` | 1 passed, 0 failed, 0 skipped | 0 |
| Whitespace | `git diff --check` | clean | 0 |
| Release build 1 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (211.4 s) | 0 |
| Release build 2 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (168.6 s) | 0 |
| Manifest generation | `dart run tool/repro_manifest.dart …` | 13 files hashed (both runs) | 0 |
| PE inspection | `dart run tool/pe_inspect.dart …` | 4 PE files inspected (both runs) | 0 |
| Linker evidence | `dart run tool/linker_evidence.dart …` | `/Brepro` present for all 2 targets (both runs) | 0 |
| ZIP generation + rebuild | `dart run tool/repro_zip.dart …` | ZIP written ×4 | 0 |
| Byte comparison | `dart run tool/repro_compare.dart …` | `COMPARE OK: identical` | 0 |
| PE comparison | `dart run tool/pe_inspect.dart --compare …` | `PE COMPARE OK: byte-identical` | 0 |
| Production diff | `git diff <baseline> -- app/lib` | empty | 0 |

## P. Test Counts

- Unit/widget (`flutter test`, `test/` directory): **282 tests** — 263 inherited from the 13B baseline plus **19 new guard/unit tests**
  (`6` in `brepro_build_config_guard_test.dart`, `8` in `linker_evidence_test.dart`, `5` in `pe_inspect_test.dart`). All passed, 0 failed,
  0 skipped.
- Windows integration (live smoke, `integration_test/login_invoice_smoke_test.dart -d windows`): 1 test — login, empty-price invoice
  rejection, valid invoice save. Passed. The integration test resets its own runtime DB first, so it never touches a customer database.
- These are distinct groups; the integration test is not run by `flutter test` and is not double-counted.

## Q. Guard Tests and Tooling

New guard tests:

- `test/brepro_build_config_guard_test.dart` — source build-config contract: `/Brepro` must be appended to the Release EXE and SHARED
  linker flags, inside `if(MSVC)`, not on Debug/Profile, and no post-build binary patching. This test fails if the change is ever removed
  or moved.
- `test/linker_evidence_test.dart` — unit tests for `tool/linker_evidence.dart`: Release link-block parsing from generated vcxproj XML,
  `/Brepro` presence/count, Debug-block isolation, real link-command extraction from diag logs, and robust UTF-8/UTF-16 decoding.
- `test/pe_inspect_test.dart` — unit tests for `tool/pe_inspect.dart`: COFF/debug timestamps read from a synthetic PE32 image, non-PE
  rejection, and `compareInspections` semantics.

New tooling (all read-only over build outputs):

- `tool/pe_inspect.dart` — PE/COFF inspection and cross-run comparison (record + compare modes).
- `tool/linker_evidence.dart` — vcxproj parse + real link-command evidence.
- `tool/run_repro_13c.ps1` — orchestrator implementing the full experiment (this document's reproducibility script).
- `tool/repro_compare.dart` — extended with spec-level fields (`allFilesByteIdentical`, `changedFiles`, `addedFiles`, `removedFiles`,
  `sameSizeDifferentHashFiles`, `fileCount`, `totalBytes`, canonical-manifest SHA-256).

## R. Change Set

```text
M  app/windows/CMakeLists.txt                              (Windows build config — /Brepro)
M  app/tool/repro_compare.dart                             (tooling — spec comparison fields)
A  app/tool/pe_inspect.dart                                (tooling — PE inspection)
A  app/tool/linker_evidence.dart                           (tooling — linker evidence)
A  app/tool/run_repro_13c.ps1                              (tooling — orchestrator)
A  app/test/brepro_build_config_guard_test.dart            (test — build-config contract)
A  app/test/linker_evidence_test.dart                      (test — linker evidence parser)
A  app/test/pe_inspect_test.dart                           (test — PE inspector)
A  app/docs/MUAMAN-13C-ENABLE-BREPRO-FULL-WINDOWS-DETERMINISM.md   (documentation)
A  app/docs/muaman-13c/evidence/*.json                     (small artifact — committed evidence)
```

Classification: Windows build configuration, Test, Tooling, Documentation, and small committed JSON evidence only. No production code,
no dependencies, no platform files other than the Windows build config.

## S. Production Diff Verification

```text
$ git diff 8acccfdf3181a5bb326cdb827cfe5f6c11b71352 -- app/lib
(empty)
```

The production `lib/` tree is byte-identical to the baseline.

## T. Risks and Limitations

- The determinism proof is specific to this toolchain snapshot (Flutter 3.24.5, MSVC 14.51, Release x64). A toolchain upgrade may change
  /Brepro behaviour; the guard test protects the build-config contract but not the toolchain.
- `flutter clean` regenerates some tracked `generated_plugin_registrant*` files with LF line endings (content unchanged after
  autocrlf normalization); they were restored before the final commit and are not part of the 13C change set.
- The `pdfium.dll` and `flutter_windows.dll` timestamps are static (prebuilt inputs); the proof of determinism rests on the two
  linker-produced PEs plus all other files, which are byte-identical.
- The application is not code-signed (pre-existing); SmartScreen may warn on first run. Unchanged here.
- Relink determinism is proven for identical inputs/commands; a source change that alters link inputs will, correctly, change the binary
  (including its `/Brepro`-derived timestamp).

## U. Reproducibility Instructions

Run the committed orchestrator from the app directory:

```text
powershell -ExecutionPolicy Bypass -File tool\run_repro_13c.ps1 ^
    -AppRoot <app> -WorkRoot <work root>
```

It reproduces the entire experiment end to end: two independent clean builds, snapshots, manifests, PE inspection, evidence relinks,
linker evidence, deterministic ZIPs, all comparisons, and the committed evidence mirror. Individual steps are documented in
`environment.json` `commands`.

## V. Artifacts

Committed under `app/docs/muaman-13c/evidence/` (small JSON):

```text
comparison.json               (Level-1 byte comparison; identical=true)
pe-comparison.json            (Level-4 PE timestamp comparison; all byte-identical)
zip-comparison.json           (Level-3 ZIP hashes; cross-build equal=true)
run-1-manifest.json           (canonical + meta manifest)
run-2-manifest.json
run-1-pe-inspection.json      (PE metadata of the 4 PE files)
run-2-pe-inspection.json
run-1-linker-evidence.json    (vcxproj + real link commands)
run-2-linker-evidence.json
environment.json              (OS/toolchain/paths/commands)
```

Heavy artifacts (snapshots, ZIPs, diag logs, build logs) are preserved in
`C:\Users\saber\AppData\Local\Temp\opencode\muaman-13c-repro\` and mirrored to `app/build/artifacts/reproducibility/muaman-13c/`
(gitignored).

## W. Comparison with MUAMAN-13B

| | 13B (baseline) | 13C (this change) |
| ---- | ---- | ---- |
| `muaman_store.exe` / `printing_plugin.dll` | differ by 4 bytes (wall-clock timestamp) | byte-identical |
| Files identical | 11 / 13 | **13 / 13** |
| Cross-build ZIP equal | false | **true** |
| Canonical manifests | structurally identical, 2 hashes differ | byte-identical |
| Root cause | MSVC link.exe embeds wall-clock time (no `/Brepro`) | eliminated by `/Brepro` |

## X. Analysis: Why `/Brepro` Fixes the Root Cause

MSVC `link.exe` by default stamps the PE COFF header timestamp and the IMAGE_DEBUG_DIRECTORY timestamps with the wall-clock build time,
so two identical builds minutes apart produce different binaries. `/Brepro` replaces that time with a deterministic value derived from a
hash of the link inputs and command line, so identical inputs produce an identical timestamp. Because the option is placed on the
configuration-wide Release linker flags (EXE **and** SHARED), both `muaman_store.exe` and the plugin DLL `printing_plugin.dll` receive it —
confirmed by the real executed `link.exe` command lines in the diag logs (`/machine:x64 /Brepro`). All other release files were already
deterministic (verified in 13B), so enabling `/Brepro` for the two linker outputs is sufficient for full release-directory determinism.

## Y. Evidence Chain of Custody and Independence

- Run-2 was a fully independent build: `flutter clean` deleted all run-1 build products before run-2's configure/build; run-2 re-ran
  `flutter pub get` from the same lockfile and a fresh build.
- Run-1 binaries were never copied into run-2; the only shared inputs are the source tree (unchanged) and the toolchain.
- Snapshots were taken **before** any evidence relink, so Level-1/2/3/4 comparisons describe the pristine Flutter builds.
- Evidence relinks consumed no snapshot bytes; they re-linked from intermediates and were compared against the snapshot (byte-equal).
- All comparison tools are deterministic and were themselves proven reproducible (same-snapshot ZIP equality).
- The committed evidence was regenerated with the exact tools that are committed, at the exact same commits, for full provenance.

## Z. Final Verdict

```text
Outcome A — VERIFIED FULL BYTE-FOR-BYTE DETERMINISM
```

All mandatory gates passed. Two independent clean Windows release builds from the baseline produce a byte-for-byte identical release
directory (13/13 files, 33,273,462 bytes), identical canonical manifests, identical deterministic ZIPs (same-snapshot and cross-build),
identical PE timestamps, and a real-link-command proof that `/Brepro` reaches both the executable and the plugin DLL. The change is a
minimal Release-only linker-flag addition; production code is untouched; no binaries are patched; there is exactly one commit after the
baseline; no Push, no Tag, and the final tracked tree is clean.

## AA. Commit Identity

```text
$ git log --oneline 8acccfdf3181a5bb326cdb827cfe5f6c11b71352..HEAD
<single commit> MUAMAN-13C: enable reproducible Windows release linking
```

## AB. File-by-File Determinism Table (run-1 vs run-2)

See section H for the full table; all 13 entries are `SAME` with identical SHA-256 in both runs.

## AC. Environment Command Record

The exact commands executed are recorded in `docs/muaman-13c/evidence/environment.json` under `commands` and in `run_repro_13c.ps1`.

## AD. Future Work

- Track MSVC `/Brepro` behaviour across toolchain upgrades; keep the guard tests green.
- Optionally extend determinism proof to `flutter build windows --profile` and CI release pipelines.
- Consider signing/notarization as a separate, orthogonal concern.
