# MUAMAN-13H: Isolated-Cache SDK-Root Source-Archive Reproducibility Acceptance

**Date**: 2026-08-04
**Commit**: `e90643e03e8438214a9de6d8f1e70c8633efa31a`
**Message**: `MUAMAN-13G: verify source-archive Windows reproducibility`
**MUAMAN-13H commit message**: `MUAMAN-13H: verify isolated-cache Windows reproducibility`

## 1. Executive Summary

Two independent build environments were provisioned on a single host, each with its own source tree, its own Flutter SDK root extracted from the official archive, its own empty PUB_CACHE, and its own TEMP/HOME/NuGet roots at materially different path lengths (deltas 57–64 chars). Dependencies were hydrated independently over the network into the isolated empty caches. Both environments built the same canonical source tree with independent SDK toolchains and produced byte-for-byte identical Windows Release outputs: 13/13 files matching each other and the MUAMAN-13G canonical Release, all four PE files byte-identical, the deterministic ZIP matching the canonical `DA9C4B04…` hash, and zero path leaks. All quality gates passed. **Outcome A — VERIFIED ISOLATED-CACHE SDK-ROOT SOURCE-ARCHIVE REPRODUCIBILITY**.

## 2. Acceptance Goal

Prove that the committed MUAMAN Windows Release can be reproduced byte-for-byte when each build runs from an independently provisioned environment comprising: its own source tree extracted from the canonical Git-free source archive, its own Flutter SDK root extracted from the official SDK archive (no SDK cache sharing), its own empty Dart package cache hydrated independently over the network, and its own isolated TEMP/HOME/configuration roots — with all environment roots at materially different absolute path lengths.

## 3. Governing Baseline

- **Baseline commit**: `e90643e03e8438214a9de6d8f1e70c8633efa31a`
- **Baseline message**: `MUAMAN-13G: verify source-archive Windows reproducibility`
- **MUAMAN-13G outcome**: PASS — GIT-METADATA-FREE SOURCE-ARCHIVE REPRODUCIBILITY
- **MUAMAN-13G evidence**: `docs/evidence/muaman-13g/`
- **MUAMAN-13G report**: `docs/MUAMAN-13G-GIT-METADATA-FREE-SOURCE-ARCHIVE-REPRODUCIBILITY-ACCEPTANCE.md`
- **Canonical source tree**: git archive of `7890ba6ed6b0a8a17797b3d370acc662875fc79a` (304 files / 31,647,662 bytes), SHA-256 `17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F`
- **Canonical Release**: 13 files / 33,273,462 bytes (per-file hashes in `docs/evidence/muaman-13g/15-release-manifest-a.json`)
- **Canonical deterministic ZIP**: SHA-256 `DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665`, 14,481,448 bytes

## 4. Branch and Commit Policy

- **Branch**: `codex/muaman-13h-isolated-cache-sdk-root-source-archive-reproducibility`
- **Started at**: `e90643e03e8438214a9de6d8f1e70c8633efa31a`
- **Required final commit count**: 1
- **Forbidden**: Additional commits, temporary commits, merge commits, squash merges, amend operations, tags, pushes, rebases after evidence collection, history rewriting, modifying the baseline commit.

## 5. Atomic Scope

This phase proves that the committed source state produces the same canonical Windows Release when each build runs from fully isolated, independently provisioned environments: separate source extraction roots, separate Flutter SDK roots (each extracted from the official SDK archive), separate empty package caches, and separate TEMP/HOME/configuration roots. Actual Flutter build commands ran entirely inside the extracted Git-free source directories with environment variables scoped to each isolation root. This phase is not an implementation or behavior-change phase.

## 6. Explicit Non-Goals

- Cross-machine reproducibility
- Fully hermetic builds (the two environments still share the same physical host, the same Visual Studio/MSVC/Windows SDK installation, and the same network package sources)
- Two builds running concurrently (builds ran strictly sequentially)
- Code changes or behavior modifications
- New feature implementation

## 7. Production-Diff Freeze

The production diff is empty. The following paths remain unchanged from the baseline:
- `app/lib/`
- `app/windows/`
- `app/pubspec.yaml`
- `app/pubspec.lock`

Verification:
```
git diff e90643e03e8438214a9de6d8f1e70c8633efa31a -- app/lib app/windows app/pubspec.yaml app/pubspec.lock
```
Result: No output (empty diff).

## 8. Environment Fingerprint

| Property | Value |
|----------|-------|
| OS | Microsoft Windows 11 Pro 10.0.26200 (64-bit) |
| Host | Dell Latitude 5520, Intel Core i5-1145G7, 8 logical processors, 7919 MB RAM |
| Flutter | 3.24.5 stable (both environments, from official archive) |
| Framework revision | dec2ee5c1f (2024-11-13) |
| Engine revision | a18df97ca5 |
| Dart | 3.5.4 stable |
| VS instance used | Build Tools 2026 18.6.0 (only usable instance; Build Tools 2022 `isLaunchable=False`) |
| MSVC | 14.51.36231 (cl 19.51.36243) |
| Windows SDK | 10.0.26100.0 |
| CMake (VS-bundled, used by flutter) | 4.2.3-msvc3 |
| Git | 2.55.0.windows.2 (orchestration only) |
| PowerShell | 5.1.26100.6584 |

Note: identical to the MUAMAN-13G toolchain fingerprint except CMake 4.2.3-msvc3 (VS-bundled) is the build generator backend instead of Ninja. Visual Studio/MSVC/Windows SDK remain globally shared host components, disclosed and unchanged.

## 9. MUAMAN-13G Canonical Evidence Reconciliation

The committed MUAMAN-13G acceptance summary and release manifest were used as the canonical reference for three-way reconciliation.

| Property | MUAMAN-13G Value |
|----------|-----------------|
| Release file count | 13 |
| Release total bytes | 33,273,462 |
| PE file count | 4 |
| Deterministic ZIP SHA-256 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 |
| ZIP size | 14,481,448 bytes |
| Path-leak occurrences | 0 (A and B) |
| Lockfile SHA-256 | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A |

## 10. SDK Provisioning Method

One immutable official Flutter SDK archive was downloaded once and verified:

| Property | Value |
|----------|-------|
| Official URL | https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip |
| Official SHA-256 (releases_windows.json) | B8A7485ACD3C6FB23A76B7AC09F89E8D93D62FBFF7147C6F5F8C5686D949EEAC |
| Downloaded size | 1,033,788,155 bytes |
| Local SHA-256 | B8A7485ACD3C6FB23A76B7AC09F89E8D93D62FBFF7147C6F5F8C5686D949EEAC |
| Hash match | true |

The single immutable archive was extracted independently into both SDK roots (`tar --strip-components=1`). No SDK cache directory is shared: each SDK independently populated `bin/cache` from its own archive and from the network on first invocation. A comparison of 19 build-relevant artifacts across both SDKs reported 0 mismatches (evidence `13-sdk-artifact-comparison.txt`).

## 11. Toolchain Adaptation (VS2026)

The fresh SDKs were verified to match the MUAMAN-13G shared SDK byte-for-byte for all build-relevant artifacts. The only difference is that flutter_tools 3.24.5 hard-codes Visual Studio generator mappings through major version 17 and maps unknown majors to `"Visual Studio 16 2019"`, which CMake cannot resolve against the VS 2026 BuildTools installation. The 13G environment had already adapted the shared SDK; this phase applies the exact same 3-line patch to both fresh SDKs' `packages\flutter_tools\lib\src\windows\visual_studio.dart`:

```
18 => 'Visual Studio 18 2026',
...
case 18:
  cppToolchainDescription = 'MSVC v144 - VS 2026 C++ x64/x86 build tools';
```

Both patched files verify 0 line diffs against the 13G shared SDK and against each other (evidence `28-sdk-vs2026-toolchain-adaptation.txt`). The adaptation does not change any build logic for major 17; it only adds the major-18 mapping required by the host's VS 2026 installation.

Because `flutter_tools.stamp` only records the git revision, the flutter_tools snapshot was force-rebuilt in each environment by deleting `bin\cache\flutter_tools.stamp` and running `flutter --version` ("Building flutter tool… Running pub upgrade…"). Both snapshots rebuilt successfully in isolation (evidence `45-flutter-tools-snapshot-rebuild-proof.txt`). The snapshot size differs slightly between A and B (38,428,704 vs 38,690,816 bytes) because the snapshot embeds environment path lengths; the resulting builds are byte-identical regardless.

## 12. Archive Hash Results

| Property | Archive A | Archive B |
|----------|-----------|-----------|
| SHA-256 | 17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F | 17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F |
| Size | 31,938,560 bytes | 31,938,560 bytes |
| Matches canonical | true | true |

## 13. Isolation Root Selection

| Root | Path A | Path B |
|------|--------|--------|
| Source | C:\m13h\a\src (13) | C:\dev\muaman-13h-environment-b-independent-source-extraction-root\src (70) |
| SDK | C:\m13h\a\sdk (13) | C:\dev\muaman-13h-environment-b-independent-flutter-sdk-installation-root\sdk (77) |
| PUB_CACHE | C:\m13h\a\pub (13) | C:\dev\muaman-13h-environment-b-independent-dart-package-cache-root\pub (71) |
| TEMP/TMP | C:\m13h\a\tmp (13) | C:\dev\muaman-13h-environment-b-independent-temporary-build-state-root\tmp (74) |
| HOME/APPDATA | C:\m13h\a\home (14) | C:\dev\muaman-13h-environment-b-independent-user-configuration-root\home (72) |

All roots were verified absent before creation (evidence `15/16-cold-state`). No root is inside a Git repository, and none is a symlink or junction.

## 14. Path-Length Delta

| Root | Delta (B − A) | Minimum | Result |
|------|--------------|---------|--------|
| Source | 57 | 50 | PASS |
| SDK | 64 | 50 | PASS |
| PUB_CACHE | 58 | 50 | PASS |
| TEMP/TMP | 61 | 50 | PASS |
| HOME/APPDATA | 58 | 50 | PASS |

## 15. Git-Metadata Absence Proof

For both source extraction roots (same canonical archive basis as MUAMAN-13G):

| Check | Root A Result | Root B Result |
|-------|---------------|---------------|
| .git file exists | false | false |
| .git directory exists | false | false |
| Recursive .git search | NONE FOUND | NONE FOUND |
| git rev-parse --is-inside-work-tree | fatal (not a repo) | fatal (not a repo) |

Both source trees are confirmed Git-free. (The official SDK archive ships an internal `.git` directory and `.pub-preload-cache`; these are toolchain metadata of the Flutter distribution, disclosed and not part of the Git-free requirement, which applies to the MUAMAN source trees.)

## 16. Source Tree Equivalence

| Property | Manifest A | Manifest B |
|----------|------------|------------|
| File count | 304 | 304 |
| Total bytes | 31,647,662 | 31,647,662 |
| Path sets identical | true | true |
| SHA-256 mismatches | 0 | 0 |
| pubspec.lock SHA-256 | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A |

Source trees are byte-identical before any build commands.

## 17. Dependency Hydration (Isolated Caches)

Both environments began with verified empty, independent PUB_CACHEs. Each environment ran `flutter pub get` independently, downloading over the network into its own cache (evidence `19/20-hydration`).

| Property | Cache A | Cache B |
|----------|---------|---------|
| Package directories | 127 | 127 |
| Files | 9085 | 9085 |
| Total bytes | 128,944,943 | 128,944,943 |
| Package graph (64 pinned packages) | identical | identical |

Post-hydration caches are byte-identical and independent (evidence `22/23/24`, `21-lockfile-integrity`, `21b-package-graph-comparison`). The lockfile remained byte-identical to the canonical value through both hydrations and both builds.

## 18. Build A Procedure

Working directory: `C:\m13h\a\src\app`
Environment: `PATH`/`PUB_CACHE`/`TEMP`/`TMP`/`APPDATA`/`LOCALAPPDATA`/`NUGET_PACKAGES`/`HOME` all scoped to `C:\m13h\a\*`.

```
flutter pub get      — exit 0 (into isolated empty cache)
flutter build windows --release --no-pub — exit 0
```

Total duration: 119.1 seconds. Release directory: `C:\m13h\a\src\app\build\windows\x64\runner\Release`

## 19. Build B Procedure

Working directory: `C:\dev\muaman-13h-environment-b-independent-source-extraction-root\src\app`
Environment: `PATH`/`PUB_CACHE`/`TEMP`/`TMP`/`APPDATA`/`LOCALAPPDATA`/`NUGET_PACKAGES`/`HOME` all scoped to `C:\dev\muaman-13h-environment-b-independent-…\*`.

```
flutter pub get      — exit 0 (into isolated empty cache)
flutter build windows --release --no-pub — exit 0
```

Total duration: 128.9 seconds. Release directory: `C:\dev\muaman-13h-environment-b-independent-source-extraction-root\src\app\build\windows\x64\runner\Release`

## 20. Release Manifest Results

| Property | Release A | Release B |
|----------|-----------|-----------|
| File count | 13 | 13 |
| Total bytes | 33,273,462 | 33,273,462 |
| Canonical total bytes | 33,273,462 | 33,273,462 |

## 21. Byte-for-Byte Release Comparison

A vs B: 13/13 files byte-identical, 0 differences (evidence `32`). Full three-way reconciliation vs the MUAMAN-13G canonical Release (evidence `33`): 0 differences for both A and B. All 13 per-file SHA-256 values match the canonical manifest `docs/evidence/muaman-13g/15-release-manifest-a.json`, including:

| File | SHA-256 |
|------|---------|
| data/app.so | 8278EC7131C921D480AFEAF69B0D27624B11DF3E9E74180BB80273A09E1E2D3D |
| data/flutter_assets/AssetManifest.bin | 00AF55AD3D6F21898FE77E0FF092D1A1CDA52C941B6860E9928D45C8AF8C095D |
| data/flutter_assets/AssetManifest.json | 4A9B3DE7EEC9BA46B279BBCCD132E32F52D6D555D79DDA4AA7F3BCB4E9BD651F |
| data/flutter_assets/FontManifest.json | CD7E03645BC44B2DD47B7CB626F51C4ECBF55A197AB77241628B47AC165FBE21 |
| data/flutter_assets/fonts/MaterialIcons-Regular.otf | D9865B671A09D683D13A863089D8825E0F61A37696CE5D7D448BC8023AA62453 |
| data/flutter_assets/NOTICES.Z | AB7675DAC8C7DCDF17A78E747C669C9BA13ED55306422F6D65F31BA98DA82DD6 |
| data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf | 67C44FE9183B002E79DDE7F6977E2988661C9A3E4A3C5FCE968787EFDBED823C |
| data/flutter_assets/shaders/ink_sparkle.frag | 3AA09424D1DC391FD59A9735EFE986FF43302B5E5BC310926AFE11C68626C3B2 |
| data/icudtl.dat | C12537022EF818991A7BFED41A76D8D6AE962FFBC0E6511AC762A5D0845E7F7C |
| flutter_windows.dll | B66713715A7AEAA2F88BA18838AA7C245556EAAEB31C82DA3F5AEBCB71A7715E |
| muaman_store.exe | 194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9 |
| pdfium.dll | 0C88EBACC0393FD45FC3E7B35E31E72C9E55B633A846A7ECF4085694DBA68ABD |
| printing_plugin.dll | 959F1E85FEEC7D8AE02F97760608E8022CFF3C3D556AADC824306EA1AFE2A867 |

## 22. PE File Comparison

| PE File | Byte Identical (A vs B) | COFF Timestamp |
|---------|--------------------------|----------------|
| flutter_windows.dll | true | 1731463209 |
| muaman_store.exe | true | 1269388706 |
| pdfium.dll | true | 1654405200 |
| printing_plugin.dll | true | 3033572914 |

All 4 PE files byte-identical; COFF timestamps match MUAMAN-13G canonical values (evidence `34/35/36`, "PE COMPARE OK: all inspected files byte-identical").

## 23. Cross-Run Contamination Proof

- Both builds ran strictly sequentially on one host; Build A completed before Build B began.
- The app-built outputs (`muaman_store.exe`, `printing_plugin.dll`, `pdfium.dll`, `data/app.so`) carry distinct filesystem LastWriteTimes per environment (e.g. `muaman_store.exe` A=20:37:20, B=20:41:19), proving independent compilation rather than file copies.
- Engine artifacts copied by flutter (`flutter_windows.dll`, `icudtl.dat`) preserve their archive LastWriteTime (2024-11-13) in both environments — expected, not contamination.
- 0 reparse points / symlinks / junctions in either Release tree.
- The two Release directories resolve to distinct physical paths (evidence `44`).

## 24. Path-Leak Scan

| Property | Release A | Release B |
|----------|-----------|-----------|
| Scanner | leak_scan.dart (5 binaries) + full-tree scan (all 13 files) | leak_scan.dart (5 binaries) + full-tree scan (all 13 files) |
| Forbidden patterns | A roots, B roots, worktree path, VS path, temp path | A roots, B roots, worktree path, VS path, temp path |
| Encodings | UTF-8 + UTF-16LE (case-insensitive) | UTF-8 + UTF-16LE (case-insensitive) |
| Total occurrences | 0 | 0 |
| allClear | true | true |

Zero path-leak occurrences in either Release tree (evidence `37/38/39/40`).

## 25. Deterministic ZIP Comparison

| Property | ZIP A | ZIP B | Canonical |
|----------|-------|-------|-----------|
| SHA-256 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 |
| Size | 14,481,448 | 14,481,448 | 14,481,448 |
| Entries | 13 (fixed timestamp 2000-01-01, deflate level 6) | 13 | 13 |

ZIP A == ZIP B == canonical: true (evidence `41/42/43`).

## 26. Guard Test Results

- **MUAMAN-13H guard test**: `app/test/muaman13h_isolated_cache_sdk_root_guard_test.dart` — PASS (25 checks)
- **MUAMAN-13G guard test**: `app/test/muaman13g_source_archive_guard_test.dart` — PASS
- **All earlier guard tests (MUAMAN-13F through 13B)**: PASS

## 27. Full Quality-Gate Results

| Gate | Result |
|------|--------|
| dart format --set-exit-if-changed | PASS (69 files, 0 changed) |
| flutter analyze | PASS (no issues found) |
| flutter test (full suite incl. 25 new guard checks) | PASS |
| git diff --check | PASS |

## 28. Git and Production-Diff Verification

```
git status --short                    → (clean after commit)
git diff --check                      → (no issues)
git diff e90643e03e8438214a9de6d8f1e70c8633efa31a -- app/lib app/windows app/pubspec.yaml app/pubspec.lock → (empty)
git rev-list --count e90643e03e8438214a9de6d8f1e70c8633efa31a..HEAD → 1
```

## 29. Limitations and Residual Boundaries

- This proves same-machine reproducibility. Cross-machine reproducibility is not proven.
- Both environments share the same physical host, OS, Visual Studio/MSVC toolset, and Windows SDK installation, and the same network package sources.
- Builds ran sequentially, not concurrently.
- The VS2026 generator mapping patch is applied to both fresh SDKs and matches the 13G shared SDK exactly; it is required by the host's VS 2026 installation and does not alter major-17 build logic.
- The official SDK archive ships internal `.git`/`.pub-preload-cache` metadata; it is the upstream Flutter distribution and was not modified except for the documented 3-line `visual_studio.dart` adaptation.

## 30. Final Outcome and Acceptance Statement

**Outcome A — VERIFIED ISOLATED-CACHE SDK-ROOT SOURCE-ARCHIVE REPRODUCIBILITY**

The MUAMAN Windows Release:

- Is reproducible from two independently provisioned environments with isolated source trees, isolated SDK roots, isolated empty package caches hydrated independently over the network, and isolated TEMP/HOME/configuration roots.
- Is reproducible across materially different absolute path lengths for all five isolation roots (deltas 57–64 chars, minimum required 50).
- Produces all 13 Release files byte-for-byte identically across environments and vs the MUAMAN-13G canonical state.
- Produces all four PE files byte-for-byte identically.
- Produces the canonical deterministic ZIP byte-for-byte (SHA-256: DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665).
- Contains no detected build-root path leakage.
- Required no binary manipulation and no canonical-file substitution.
- Has an empty production diff.
- Passes all guard tests and the full test suite, plus dart format and flutter analyze.

**Final commit**: (to be filled after commit)
**Baseline**: `e90643e03e8438214a9de6d8f1e70c8633efa31a`
**Commit count after baseline**: 1
**No push, tag, or merge occurred.**
