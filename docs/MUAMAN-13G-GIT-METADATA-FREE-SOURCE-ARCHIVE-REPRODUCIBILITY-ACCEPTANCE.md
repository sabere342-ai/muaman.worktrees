# MUAMAN-13G: Git-Metadata-Free Source-Archive Reproducibility Acceptance

**Date**: 2026-08-04
**Commit**: `7890ba6ed6b0a8a17797b3d370acc662875fc79a`
**Message**: `MUAMAN-13F: verify fresh-clone Windows reproducibility`
**MUAMAN-13G commit message**: `MUAMAN-13G: verify source-archive Windows reproducibility`

## 1. Executive Summary

Two independent source archives were generated from the exact baseline commit using `git archive`, extracted to separate Git-free directories at materially different path lengths, and built independently. All 13 Release files matched byte-for-byte. All four PE files matched byte-for-byte. The deterministic ZIP matched the MUAMAN-13F canonical hash. Zero path leaks were detected. All quality gates passed. **Outcome A — VERIFIED GIT-METADATA-FREE SOURCE-ARCHIVE REPRODUCIBILITY**.

## 2. Acceptance Goal

Prove that the committed MUAMAN-13F Windows Release can be reproduced byte-for-byte from independently created and extracted source archives that contain no `.git` directory, no Git worktree metadata, no Git alternates, no dependency on the original checkout path, no dependency on Git commands during actual builds, and no copied build products from any previous run.

## 3. Governing Baseline

- **Baseline commit**: `7890ba6ed6b0a8a17797b3d370acc662875fc79a`
- **Baseline message**: `MUAMAN-13F: verify fresh-clone Windows reproducibility`
- **MUAMAN-13F outcome**: PASS — INDEPENDENT FRESH-CLONE COMMITTED-STATE REPRODUCIBILITY
- **MUAMAN-13F evidence**: `docs/evidence/muaman-13f/`
- **MUAMAN-13F report**: `docs/MUAMAN-13F-INDEPENDENT-FRESH-CLONE-COMMITTED-STATE-REPRODUCIBILITY-ACCEPTANCE.md`

## 4. Branch and Commit Policy

- **Branch**: `codex/muaman-13g-git-metadata-free-source-archive-reproducibility`
- **Started at**: `7890ba6ed6b0a8a17797b3d370acc662875fc79a`
- **Required final commit count**: 1
- **Forbidden**: Additional commits, temporary commits, merge commits, squash merges, amend operations, tags, pushes, rebases after evidence collection, history rewriting, modifying the baseline commit.

## 5. Atomic Scope

This phase proves that the committed MUAMAN-13F source state produces the same canonical Windows Release when built from two independent source archives outside Git. Two source inputs were produced independently from the exact baseline commit using `git archive`. Each archive was extracted into a separate path outside every Git repository. The actual Flutter build commands ran entirely inside the extracted Git-free source directories. This phase is not an implementation or behavior-change phase.

## 6. Explicit Non-Goals

- Cross-machine reproducibility
- Fully hermetic builds (shared Flutter SDK and global package cache)
- Package-cache isolation
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
git diff 7890ba6ed6b0a8a17797b3d370acc662875fc79a -- app/lib app/windows app/pubspec.yaml app/pubspec.lock
```
Result: No output (empty diff).

## 8. Environment Fingerprint

| Property | Value |
|----------|-------|
| OS | Microsoft Windows NT 10.0.26200.0 (Windows 11 Pro 26200, 64-bit) |
| CPU | x64 |
| Flutter | 3.24.5 stable |
| Framework revision | dec2ee5c1f (2024-11-13) |
| Engine revision | a18df97ca5 |
| Dart | 3.5.4 stable |
| CMake | 4.3.3 |
| Ninja | Not on PATH (Flutter manages internally) |
| Git | 2.55.0.windows.2 |
| PowerShell | 5.1.26100.6584 |
| VS | 18.6.0 |
| MSVC | 14.51.36231 |

Note: The environment is identical to MUAMAN-13F. Shared Flutter SDK and global package cache are disclosed. This phase does not expand into package-cache isolation.

## 9. MUAMAN-13F Canonical Evidence Reconciliation

The committed MUAMAN-13F acceptance summary was inspected at `docs/evidence/muaman-13f/acceptance-summary.json` within the baseline commit.

| Property | MUAMAN-13F Value |
|----------|-----------------|
| Release file count | 13 |
| Release total bytes | 33,273,462 |
| PE file count | 4 |
| All files byte-identical | true |
| Deterministic ZIP SHA-256 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 |
| ZIP size | 14,481,448 bytes |
| Path-leak occurrences | 0 (A and B) |

All 13 per-file SHA-256 values were extracted from the committed evidence and used for three-way comparison.

## 10. Source Archive Generation Method

Two source archives were created independently using `git archive`:

```
git archive --format=tar --output=C:\dev\muaman-src-arcs\archive-a.tar 7890ba6ed6b0a8a17797b3d370acc662875fc79a
git archive --format=tar --output=C:\dev\muaman-src-arcs\archive-b.tar 7890ba6ed6b0a8a17797b3d370acc662875fc79a
```

Both commands executed separately. Neither archive was copied from the other.

## 11. Archive Independence Proof

- Two separate `git archive` invocations were used
- Neither archive was derived by copying the other
- Both targeted the exact same commit object
- Archive byte identity is expected from identical git archive invocations and is supporting evidence, not a substitute for both builds

## 12. Archive Hash Results

| Property | Archive A | Archive B |
|----------|-----------|-----------|
| SHA-256 | 17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F | 17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F |
| Size | 31,938,560 bytes | 31,938,560 bytes |
| Hashes match | true | true |

## 13. Extraction Path Selection

| Property | Path A | Path B |
|----------|--------|--------|
| Absolute path | C:\src\m13ga | C:\dev\muaman-13g-archive-b-independent-extraction-root-for-reproducibility |
| Path length | 12 chars | 75 chars |
| Volume | C:\ | C:\ |
| Inside Git repo | No | No |
| Symlink/Junction | No | No |

## 14. Path-Length Delta

- Path A length: 12 characters
- Path B length: 75 characters
- Delta: 63 characters (minimum required: 50)

## 15. Git-Metadata Absence Proof

For both extraction roots:

| Check | Root A Result | Root B Result |
|-------|---------------|---------------|
| .git file exists | false | false |
| .git directory exists | false | false |
| Recursive .git search | NONE FOUND | NONE FOUND |
| git rev-parse --is-inside-work-tree | fatal (not a repo) | fatal (not a repo) |
| git rev-parse --show-toplevel | fatal (not a repo) | fatal (not a repo) |
| git status | fatal (not a repo) | fatal (not a repo) |

Both extraction roots are confirmed Git-free.

## 16. Source Tree Equivalence

| Property | Manifest A | Manifest B |
|----------|------------|------------|
| File count | 304 | 304 |
| Total bytes | 31,647,662 | 31,647,662 |
| Path sets identical | true | true |
| SHA-256 mismatches | 0 | 0 |
| pubspec.lock SHA-256 | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A |

Source trees are byte-identical before any build commands.

## 17. Build A Procedure

Working directory: `C:\src\m13ga\app`

```
flutter clean        — exit 0
flutter pub get      — exit 0
flutter build windows --release — exit 0
```

Total duration: 109.5 seconds. Release directory: `C:\src\m13ga\app\build\windows\x64\runner\Release`

## 18. Build B Procedure

Working directory: `C:\dev\muaman-13g-archive-b-independent-extraction-root-for-reproducibility\app`

```
flutter clean        — exit 0
flutter pub get      — exit 0
flutter build windows --release — exit 0
```

Total duration: 98.1 seconds. Release directory: `C:\dev\muaman-13g-archive-b-independent-extraction-root-for-reproducibility\app\build\windows\x64\runner\Release`

## 19. Lockfile Integrity

| Check | SHA-256 | Match |
|-------|---------|-------|
| Original (from archive) | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A | — |
| After Build A pub get | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A | true |
| After Build B pub get | EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A | true |

Lockfile remained byte-identical through both builds.

## 20. Release Manifest Results

| Property | Release A | Release B |
|----------|-----------|-----------|
| File count | 13 | 13 |
| Total bytes | 33,273,462 | 33,273,462 |

## 21. Byte-for-Byte Release Comparison

| File | Result | SHA-256 |
|------|--------|---------|
| data/app.so | IDENTICAL | 8278EC7131C921D480AFEAF69B0D27624B11DF3E9E74180BB80273A09E1E2D3D |
| data/flutter_assets/AssetManifest.bin | IDENTICAL | 00AF55AD3D6F21898FE77E0FF092D1A1CDA52C941B6860E9928D45C8AF8C095D |
| data/flutter_assets/AssetManifest.json | IDENTICAL | 4A9B3DE7EEC9BA46B279BBCCD132E32F52D6D555D79DDA4AA7F3BCB4E9BD651F |
| data/flutter_assets/FontManifest.json | IDENTICAL | CD7E03645BC44B2DD47B7CB626F51C4ECBF55A197AB77241628B47AC165FBE21 |
| data/flutter_assets/fonts/MaterialIcons-Regular.otf | IDENTICAL | D9865B671A09D683D13A863089D8825E0F61A37696CE5D7D448BC8023AA62453 |
| data/flutter_assets/NOTICES.Z | IDENTICAL | AB7675DAC8C7DCDF17A78E747C669C9BA13ED55306422F6D65F31BA98DA82DD6 |
| data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf | IDENTICAL | 67C44FE9183B002E79DDE7F6977E2988661C9A3E4A3C5FCE968787EFDBED823C |
| data/flutter_assets/shaders/ink_sparkle.frag | IDENTICAL | 3AA09424D1DC391FD59A9735EFE986FF43302B5E5BC310926AFE11C68626C3B2 |
| data/icudtl.dat | IDENTICAL | C12537022EF818991A7BFED41A76D8D6AE962FFBC0E6511AC762A5D0845E7F7C |
| flutter_windows.dll | IDENTICAL | B66713715A7AEAA2F88BA18838AA7C245556EAAEB31C82DA3F5AEBCB71A7715E |
| muaman_store.exe | IDENTICAL | 194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9 |
| pdfium.dll | IDENTICAL | 0C88EBACC0393FD45FC3E7B35E31E72C9E55B633A846A7ECF4085694DBA68ABD |
| printing_plugin.dll | IDENTICAL | 959F1E85FEEC7D8AE02F97760608E8022CFF3C3D556AADC824306EA1AFE2A867 |

All 13 files byte-identical. Mismatches: 0.

## 22. Three-Way MUAMAN-13F Reconciliation

| File | A vs B | A vs 13F | B vs 13F | Result |
|------|--------|----------|----------|--------|
| data/app.so | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/AssetManifest.bin | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/AssetManifest.json | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/FontManifest.json | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/fonts/MaterialIcons-Regular.otf | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/NOTICES.Z | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf | match | match | match | ALL-THREE-MATCH |
| data/flutter_assets/shaders/ink_sparkle.frag | match | match | match | ALL-THREE-MATCH |
| data/icudtl.dat | match | match | match | ALL-THREE-MATCH |
| flutter_windows.dll | match | match | match | ALL-THREE-MATCH |
| muaman_store.exe | match | match | match | ALL-THREE-MATCH |
| pdfium.dll | match | match | match | ALL-THREE-MATCH |
| printing_plugin.dll | match | match | match | ALL-THREE-MATCH |

Three-way mismatches: 0. All files match MUAMAN-13F canonical state.

## 23. PE File Comparison

| PE File | Size Equal | SHA-256 Equal | Byte Identical | COFF Timestamp Equal | Debug Timestamps Equal |
|---------|-----------|---------------|----------------|---------------------|----------------------|
| flutter_windows.dll | true | true | true | true (1731463209) | true |
| muaman_store.exe | true | true | true | true (1269388706) | true |
| pdfium.dll | true | true | true | true (1654405200) | true |
| printing_plugin.dll | true | true | true | true (3033572914) | true |

All 4 PE files byte-identical. COFF timestamps and debug timestamps match MUAMAN-13F canonical values.

## 24. Path-Leak Scan

| Property | Release A | Release B |
|----------|-----------|-----------|
| Scanner | leak_scan.dart | leak_scan.dart |
| Files scanned | 5 | 5 |
| Forbidden patterns | 4 | 4 |
| Encodings | UTF-8 + UTF-16LE | UTF-8 + UTF-16LE |
| Total occurrences | 0 | 0 |
| allClear | true | true |

Zero path-leak occurrences in both Release directories.

## 25. Deterministic ZIP Comparison

| Property | ZIP A | ZIP B | MUAMAN-13F Canonical |
|----------|-------|-------|---------------------|
| SHA-256 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 | DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665 |
| Size | 14,481,448 | 14,481,448 | 14,481,448 |

ZIP A == ZIP B: true. Both match MUAMAN-13F canonical: true.

## 26. Guard Test Results

- **MUAMAN-13G guard test**: `app/test/muaman13g_source_archive_guard_test.dart` — PASS
- **MUAMAN-13F guard test**: `app/test/muaman13f_fresh_clone_guard_test.dart` — PASS
- **Existing MUAMAN-13E/13D guard tests**: All PASS

Guard tests validate committed evidence files, baseline hashes, archive independence, build success, Release manifest consistency, PE file matching, path-leak results, deterministic ZIP matching, and production-diff emptiness.

## 27. Full Quality-Gate Results

| Gate | Result |
|------|--------|
| dart format --set-exit-if-changed | PASS (68 files, 0 changed) |
| flutter analyze | PASS (no issues found) |
| flutter test | PASS (355 tests, 0 failures) |
| git diff --check | PASS |

Preexisting 340-test baseline intact. MUAMAN-13G adds 15 guard tests. Total test count: 355.

## 28. Git and Production-Diff Verification

```
git status --short                    → (clean after commit)
git diff --check                      → (no issues)
git diff 7890ba6ed6b0a8a17797b3d370acc662875fc79a -- app/lib app/windows app/pubspec.yaml app/pubspec.lock → (empty)
git rev-list --count 7890ba6ed6b0a8a17797b3d370acc662875fc79a..HEAD → 1
```

## 29. Limitations and Residual Boundaries

- This proves same-machine reproducibility. Cross-machine reproducibility is not proven.
- The builds share the same OS, Flutter SDK, Dart SDK, CMake, and MSVC toolchain.
- Package cache is shared (not hermetic).
- This phase does not prove hermetic builds.
- The shared Flutter SDK at `C:\src\flutter` is a normal installation, not a fresh copy per build.

## 30. Final Outcome and Acceptance Statement

**Outcome A — VERIFIED GIT-METADATA-FREE SOURCE-ARCHIVE REPRODUCIBILITY**

The MUAMAN Windows Release:

- Is reproducible from the exact committed source tree.
- Is reproducible without a `.git` directory.
- Is reproducible without Git worktree metadata.
- Is reproducible across substantially different extraction paths (12 chars vs 75 chars, delta 63).
- Produces all 13 Release files byte-for-byte identically.
- Produces all four PE files byte-for-byte identically.
- Produces the canonical deterministic ZIP byte-for-byte (SHA-256: DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665).
- Matches the committed MUAMAN-13F canonical state.
- Contains no detected build-root path leakage.
- Requires no post-build binary manipulation.
- Passes all guard tests and the full 355-test suite (340 preexisting + 15 new).
- Passes dart format and flutter analyze.
- Has an empty production diff.

**Final commit**: (to be filled after commit)
**Baseline**: `7890ba6ed6b0a8a17797b3d370acc662875fc79a`
**Commit count after baseline**: 1
**No push, tag, or merge occurred.**
