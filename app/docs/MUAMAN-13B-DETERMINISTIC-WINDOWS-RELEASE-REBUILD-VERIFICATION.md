# MUAMAN-13B — Deterministic Windows Release Rebuild Verification

## A. Executive Summary

| Item | Value |
| ---- | ----- |
| Outcome | `Outcome B — VERIFIED NON-DETERMINISM, PRECISELY IDENTIFIED` |
| Baseline commit | `804388e13c708adcc398f929d8b4174965f502c8` |
| Branch | `codex/muaman-13b-deterministic-release-rebuild-verification` |
| Worktree | `C:\dev\muaman.worktrees\muaman-13b-deterministic-release-rebuild-verification` |
| Independent clean builds | 2 (run-1, run-2), each: `flutter clean` → `flutter pub get` → `flutter build windows --release` |
| Release directory determinism | **11 of 13 files byte-identical**; 2 PE binaries differ **only in the embedded build timestamp** |
| Manifest determinism | Canonical sections structurally identical (13 paths, same order/sizes/counts); only the 2 timestamped files' SHA-256 differ |
| ZIP determinism | Same-snapshot: **proven byte-identical** for both runs. Cross-build: differs (expected, mirrors the 2 binary diffs) |
| Non-determinism root cause | MSVC `link.exe` embeds wall-clock time in the PE COFF header and the debug directory (no `/Brepro`) |
| Production behavior modified | No |
| Push | No |
| Tag | No |
| Merge / Rebase / Squash of prior history | No |

Two fully independent clean Windows release builds were produced from the exact same baseline commit in an isolated worktree. The outcome is
honest: **the release directory is not byte-for-byte reproducible on this toolchain**, and the non-determinism is confined, at byte level, to
the build-time timestamp inside two PE files (`muaman_store.exe` and `printing_plugin.dll`). Every other file — including the Flutter AOT
snapshot `data/app.so`, `flutter_windows.dll`, `pdfium.dll`, `data/icudtl.dat`, and all `data/flutter_assets/*` — is byte-identical across the
two builds. All new tooling is deterministic and was itself proven byte-reproducible (each snapshot ZIPs identically twice).

## B. Scope

Executed (determinism verification only, no application behavior change):

- Verify the baseline commit and its exact identity.
- Use the independent clean worktree + branch created from the baseline.
- Record the real build environment (no estimated values).
- **Two** independent clean builds: per run `flutter clean` → `flutter pub get` (lockfile guarded) → `flutter build windows --release` → snapshot the `Release` directory **outside** `app/build` so a later `flutter clean` can never destroy earlier evidence.
- Deterministic canonical manifest per snapshot (relative path + size + full SHA-256, sorted, no meta in the compared section).
- Deterministic ZIP builder (fixed entry order, fixed UTC timestamp, fixed deflate level, relative paths only, canonical manifest embedded).
- Same-snapshot ZIP determinism proof: each snapshot packaged twice, hashes compared.
- Cross-build comparison: file set, sizes, and SHA-256 compared; byte-level diff of the differing binaries; read-only PE/COFF metadata analysis (`tool/pe_info.dart`) to identify the exact cause.
- Gates: `dart format`, `flutter analyze`, `flutter test`, Windows integration smoke test, `git diff --check`.
- Guard tests / re-runnable tooling for manifest, ZIP, and comparison invariants.
- Phase report + single final commit.

Not executed (explicitly out of scope, and not expanded into):

- **No production, DB schema/migration, permission, invoice, stock-logic, name, version, or toolchain changes.**
- **No binary patching.** The differing binaries are reported and analyzed; they are not modified to force equality.
- **No build-config change** (e.g. no enabling of `link.exe /Brepro`). Making the build deterministic would change the produced binaries and
  the build configuration, which is a *fix*, not a *verification*, and is explicitly out of scope here.
- No code signing, no publish tooling.
- No `build/` commit, no binary in Git, no Push, no Tag.

## C. Source Provenance

```text
$ git rev-parse HEAD
804388e13c708adcc398f929d8b4174965f502c8
$ git branch --show-current
codex/muaman-13b-deterministic-release-rebuild-verification
$ git rev-list --count 804388e13c708adcc398f929d8b4174965f502c8..HEAD
0
```

The worktree was created from the baseline commit SHA (not a moving branch name):

```text
$ git worktree add -b codex/muaman-13b-deterministic-release-rebuild-verification ^
    C:\dev\muaman.worktrees\muaman-13b-deterministic-release-rebuild-verification ^
    804388e13c708adcc398f929d8b4174965f502c8
```

`flutter pub get` did not alter `pubspec.lock` in either run (SHA-256
`EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A` before and after each run). The user-owned month-7 workbook that exists in
the previous worktree was never read, copied, restored, or added; it does not exist in this worktree.

The orchestrator verifies at start and before every run that no **tracked** file differs from the baseline (autocrlf-normalized
`git diff --quiet`). Untracked files (the repro tooling itself, which is not yet committed while the experiment runs) are intentionally not
part of the release build and cannot change its output.

## D. Environment

```text
Windows:      Microsoft Windows 11 Pro, build 10.0.26200, 64-bit
Flutter:      3.24.5 (stable) — framework revision dec2ee5c1f, engine a18df97ca5
Dart:         3.5.4 (stable)
CMake:        4.3.3
Visual Studio Build Tools: 2026, catalog product 18.6.0
  path:       C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools
flutter path: C:\src\flutter\bin\flutter.bat
dart path:    C:\src\flutter\bin\dart.bat
Architecture: x64
```

Full details (OS, versions, paths, commands) are recorded in `environment.json` in the artifacts directory.

## E. Gates

| Gate | Command | Result | Exit Code |
| ---- | ------- | ------ | --------- |
| Baseline identity | `git rev-parse HEAD` | `804388e…f502c8` (baseline) | 0 |
| Branch | `git branch --show-current` | `codex/muaman-13b-deterministic-release-rebuild-verification` | 0 |
| Clean tracked tree (pre, per run) | `git diff --quiet` | clean (autocrlf-normalized) | 0 |
| Clean build outputs | `flutter clean` | OK (both runs) | 0 |
| Dependencies | `flutter pub get` | 46 packages; `pubspec.lock` unchanged (both runs) | 0 |
| Format | `dart format --set-exit-if-changed .` | 56 files, 0 changed | 0 |
| Analyze | `flutter analyze` | No issues found | 0 |
| Unit/widget tests | `flutter test` | 263 passed, 0 failed, 0 skipped | 0 |
| Integration (Windows) | `flutter test integration_test/login_invoice_smoke_test.dart -d windows` | 1 passed, 0 failed, 0 skipped | 0 |
| Whitespace | `git diff --check` | clean | 0 |
| Release build 1 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (98.4 s) | 0 |
| Release build 2 | `flutter build windows --release` | `Built ...Release\muaman_store.exe` (94.4 s) | 0 |
| Manifest generation | `dart run tool/repro_manifest.dart …` | 13 files hashed (both runs) | 0 |
| ZIP generation + rebuild | `dart run tool/repro_zip.dart …` | ZIP written ×4 | 0 |
| Comparison | `dart run tool/repro_compare.dart …` | compared (see H–K) | 0 |

## F. Test Counts

- Unit/widget (`flutter test`, the `test/` directory): **263 tests** — 242 inherited from the baseline plus **21 new guard tests**
  (`6` in `repro_manifest_test.dart`, `7` in `repro_zip_test.dart`, `8` in `repro_compare_test.dart`). All passed, 0 failed, 0 skipped.
- Windows integration (live smoke, `integration_test/login_invoice_smoke_test.dart -d windows`): 1 test — login, empty-price invoice
  rejection, valid invoice save. Passed. The integration test resets its own runtime DB first, so it never touches a customer database.
- These are distinct groups; the focused integration test is not run by `flutter test` and is not double-counted.

## G. Experiment Design

Each run is fully independent:

```text
run-N:
  1. verify tracked source tree equals the baseline commit
  2. flutter clean
  3. flutter pub get          (guard: pubspec.lock SHA-256 must be unchanged)
  4. flutter build windows --release
  5. snapshot Release/ -> <work root>\runs\run-N\snapshot   (outside app/build)
  6. canonical manifest -> <work root>\runs\run-N\run-N-manifest.json
```

After both runs:

```text
  7. deterministic ZIP per snapshot (twice), compare hashes -> zip-comparison.json
  8. cross-build file/size/hash comparison                  -> comparison.json
  9. byte-level + PE/COFF analysis of any differing file    -> this report
```

Work root: `C:\Users\saber\AppData\Local\Temp\opencode\muaman-13b-repro`. Results are copied into
`app/build/artifacts/reproducibility/` (see M). All evidence lives outside the committed tree.

## H. Run Results

| | run-1 | run-2 |
| ---- | ---- | ---- |
| Built at (UTC, meta) | `2026-08-03T17:11:43.7021599Z` | `2026-08-03T17:13:27.6964371Z` |
| Build duration | 98.4 s | 94.4 s |
| Source clean before/after | true / true | true / true |
| File count | 13 | 13 |
| Total bytes | 33,273,462 | 33,273,462 |
| `pubspec.lock` SHA-256 | `EBDDB5D8…D3331A` | `EBDDB5D8…D3331A` (same) |

The `builtAt` meta values intentionally differ between runs (that meta field is excluded from canonical comparison by design).

## I. Release Directory Content Determinism (Level 1)

Full per-file comparison (run-1 vs run-2, canonical manifest):

```text
#  status   sizeBytes  sha256 (first 16)  path
 1. SAME      7324576  cf8b16f24ef46266  data/app.so
 2. SAME          117  00af55ad3d6f2189  data/flutter_assets/AssetManifest.bin
 3. SAME          109  4a9b3de7eec9ba46  data/flutter_assets/AssetManifest.json
 4. SAME          208  cd7e03645bc44b2d  data/flutter_assets/FontManifest.json
 5. SAME        89152  ab7675dac8c7dcdf  data/flutter_assets/NOTICES.Z
 6. SAME      1645184  d9865b671a09d683  data/flutter_assets/fonts/MaterialIcons-Regular.otf
 7. SAME       257628  67c44fe9183b002e  data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
 8. SAME        17304  3aa09424d1dc391f  data/flutter_assets/shaders/ink_sparkle.frag
 9. SAME       778864  c12537022ef81899  data/icudtl.dat
10. SAME     18181632  b66713715a7aeaa2  flutter_windows.dll
11. DIFF        90624  eb5dd87607cdf6f1  muaman_store.exe      (run1) / 290e39e434979bb6 (run2)
12. SAME      4749824  0c88ebacc0393fd4  pdfium.dll
13. DIFF       138240  98d670e8af106404  printing_plugin.dll   (run1) / fa73143313da813c (run2)
```

Result: **11 of 13 files (33,055,672 of 33,273,462 bytes) are byte-identical.** The two differing files have identical sizes and file sets —
no file is only in one run, no size mismatch.

## J. Manifest Determinism (Level 2)

- Canonical section structure: identical in both runs — same 13 relative paths, same sort order, same per-file `sizeBytes`, same
  `fileCount` (13) and `totalBytes` (33,273,462).
- Canonical section content: differs **only** in the two SHA-256 values for `muaman_store.exe` and `printing_plugin.dll`, which is exactly
  the binary difference found in Level 1. The canonical comparison is therefore fully deterministic given identical file contents.
- Full manifest meta differs only in `runId` and `builtAt`, both of which are intentionally excluded from the canonical comparison.

## K. ZIP Determinism (Level 3)

Deterministic ZIP construction: entries sorted by normalized relative path, every entry gets a fixed UTC timestamp
(`2000-01-01T00:00:00Z`), fixed deflate level (6), relative paths only, and the snapshot's canonical manifest is embedded as
`manifest.canonical.json`.

```text
run-1-deterministic.zip         14,482,520 B  sha256 A1F6B2B54F0947CB9D9E83431A6F31EC2AF431A3DAEE2BF36DAAE1485AA39909
run-1-deterministic.rebuild.zip 14,482,520 B  sha256 A1F6B2B54F0947CB9D9E83431A6F31EC2AF431A3DAEE2BF36DAAE1485AA39909
run-2-deterministic.zip         14,482,521 B  sha256 920E9910B496E3372462DFBAE6E2AC39BAA70EE5DA9C95DF5EC770C17634DB54
run-2-deterministic.rebuild.zip 14,482,521 B  sha256 920E9910B496E3372462DFBAE6E2AC39BAA70EE5DA9C95DF5EC770C17634DB54
```

- **Same-snapshot determinism: proven.** Each snapshot packages to the identical byte stream twice (`run1` equal, `run2` equal).
- **Cross-build ZIP equality: false.** Expected: the embedded canonical manifest and the two compressed PE files differ, mirroring the
  Level-1 binary difference. The 1-byte size delta between run-1 and run-2 ZIPs is the deflate-output difference of the two slightly
  different PE files plus the embedded manifest.

## L. Root Cause Analysis (Non-Determinism)

Byte-level diff of the two `muaman_store.exe` files: exactly **4 differing bytes in 2 locations**, holding the same value twice:

```text
peOff = 272
COFF header timestamp  @ 280..283: run1 CD CB 70 6A = 1785777101 (2026-08-03T17:11:41Z)
                                run2 36 CC 70 6A = 1785777206 (2026-08-03T17:13:26Z)
Debug directory stamp  @ 37572..37575: identical duplicated values (same delta)
```

`printing_plugin.dll` shows the same pattern (`1785777095` vs `1785777200`). Read-only PE/COFF metadata
(`tool/pe_info.dart`):

```text
muaman_store.exe  x64  checksum=0x0  sizeOfImage=102400  linker=13070  osVersion=6.0   (identical besides timestamp)
printing_plugin.dll x64 checksum=0x0  sizeOfImage=155648  linker=13070  osVersion=6.0  (identical besides timestamp)
```

Conclusion: the only difference between the two builds is the **wall-clock build time stamped by MSVC `link.exe`** into the PE COFF header
and the IMAGE_DEBUG_DIRECTORY. This is the default, well-known non-determinism of the MSVC linker; it is eliminated by `/Brepro`
(reproducible build flag). Flutter 3.24.5's Windows toolchain does not enable `/Brepro` by default. All other build outputs — including the
Flutter AOT snapshot `data/app.so` — are deterministic.

Per the phase constraints, no binary is patched and no build configuration is changed to hide or "fix" this; it is documented honestly.

## M. Artifacts

Copied to `app/build/artifacts/reproducibility/` (gitignored via `app/.gitignore` `/build/`):

```text
comparison.json                   (cross-build file/size/hash comparison)
environment.json                  (OS/toolchain/paths/commands)
run-1-deterministic.zip           (deterministic ZIP of run-1 snapshot)
run-1-manifest.json               (run-1 canonical + meta manifest)
run-2-deterministic.zip           (deterministic ZIP of run-2 snapshot)
run-2-manifest.json               (run-2 canonical + meta manifest)
zip-comparison.json               (same-snapshot + cross-build ZIP hashes)
```

Full per-run evidence (snapshots, manifests, ZIPs, logs) is preserved in
`C:\Users\saber\AppData\Local\Temp\opencode\muaman-13b-repro\runs\`.

## N. Risks and Limitations

- The release directory is **not** byte-for-byte reproducible on this toolchain without changing the linker configuration. The
  difference is isolated to the PE timestamp of 2 of 13 files.
- Enabling determinism (e.g. MSVC `/Brepro` or a fixed `SOURCE_DATE_EPOCH`-style override) is a build/toolchain change and was
  intentionally **not** applied; it is a follow-up decision, not part of this verification.
- The ZIP "cross-build equal" result is false by construction because the underlying snapshots differ; the tooling itself is proven
  deterministic (same-snapshot rebuilds are byte-identical).
- The application is not code-signed (pre-existing); SmartScreen may warn on first run. Unchanged here.
- Flutter's own output determinism was verified for `data/app.so` and `flutter_windows.dll` (identical across both builds), which is a
  strong positive signal for the AOT snapshot pipeline.

## O. Final Verdict

```text
Outcome B — VERIFIED NON-DETERMINISM, PRECISELY IDENTIFIED
```

All mandatory gates passed. Two independent clean release builds were produced from the baseline. The verification methodology and all new
tooling are deterministic and were themselves proven reproducible (same-snapshot ZIP determinism holds for both runs). The release directory
is byte-identical in 11 of 13 files; the two differing PE binaries differ only in the linker-embedded build timestamp (COFF header + debug
directory). No production code changed, no binaries were patched, no Push, no Tag, exactly one commit after the baseline, and the final
tracked tree is clean.
