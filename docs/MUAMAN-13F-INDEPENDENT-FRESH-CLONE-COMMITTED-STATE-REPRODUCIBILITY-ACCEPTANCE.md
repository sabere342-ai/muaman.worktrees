# MUAMAN-13F: Independent Fresh-Clone Committed-State Reproducibility Acceptance

**Date**: 2026-08-04
**Commit**: `bc323f2e405294aecc4a279a8fa86b6191c0f52c`
**Message**: `MUAMAN-13F: verify fresh-clone Windows reproducibility`

## Summary

Two genuinely independent fresh Git clones of the same repository were created at paths of different lengths, checked out to the same committed state, and built independently on the same machine. All outputs were compared byte-for-byte. The acceptance protocol **PASSED**.

## Acceptance Protocol

### Clone Setup
| Property | Clone A | Clone B |
|----------|---------|---------|
| Path | `C:\dev\muaman.fresh\m13f-a` | `C:\dev\muaman.fresh\muaman-13f-independent-fresh-clone-committed-state-acceptance-b` |
| Path Length | 26 chars | 83 chars |
| Independence | Verified (no alternates) | Verified (no alternates) |
| Worktree | Not a worktree | Not a worktree |

### Build Results
| Property | Clone A | Clone B |
|----------|---------|---------|
| Build Duration | 106.9s | 102.7s |
| Exit Code | 0 | 0 |
| Release Files | 13 | 13 |
| Total Bytes | 33,273,462 | 33,273,462 |

### Verification Results

| Check | Result |
|-------|--------|
| File Manifest | IDENTICAL (13 files, 33,273,462 bytes) |
| Binary Comparison | ALL 13 FILES BYTE-IDENTICAL |
| Deterministic ZIP | IDENTICAL (SHA-256: `DA9C4B04...`) |
| PE Inspection | 4 PE files BYTE-IDENTICAL |
| Path Leak Scan | 0 forbidden occurrences (UTF-8 + UTF-16LE) |

### Per-File SHA-256 Comparison

| File | SHA-256 | Result |
|------|---------|--------|
| data/app.so | `8278EC71...` | IDENTICAL |
| data/flutter_assets/AssetManifest.bin | `00AF55AD...` | IDENTICAL |
| data/flutter_assets/AssetManifest.json | `4A9B3DE7...` | IDENTICAL |
| data/flutter_assets/FontManifest.json | `CD7E0364...` | IDENTICAL |
| data/flutter_assets/fonts/MaterialIcons-Regular.otf | `D9865B67...` | IDENTICAL |
| data/flutter_assets/NOTICES.Z | `AB7675DA...` | IDENTICAL |
| data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf | `67C44FE9...` | IDENTICAL |
| data/flutter_assets/shaders/ink_sparkle.frag | `3AA09424...` | IDENTICAL |
| data/icudtl.dat | `C1253702...` | IDENTICAL |
| flutter_windows.dll | `B6671371...` | IDENTICAL |
| muaman_store.exe | `194B4600...` | IDENTICAL |
| pdfium.dll | `0C88EBAC...` | IDENTICAL |
| printing_plugin.dll | `959F1E85...` | IDENTICAL |

### Deterministic ZIP
- **SHA-256**: `DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665`
- **Size**: 14,481,448 bytes
- **Identical**: Yes

### Environment
- **OS**: Microsoft Windows 11 Pro 26200 (64-bit)
- **Flutter**: 3.24.5 stable
- **Dart**: 3.5.4
- **CMake**: 4.3.3
- **Git**: 2.55.0.windows.2
- **VS**: 18.6.0
- **MSVC**: 14.51.36231

## Evidence Files

| File | Description |
|------|-------------|
| `acceptance-summary.json` | Machine-readable acceptance summary |
| `manifest-a.json` | Clone A file manifest with SHA-256 |
| `manifest-b.json` | Clone B file manifest with SHA-256 |
| `release-a.zip` | Deterministic ZIP from Clone A |
| `release-b.zip` | Deterministic ZIP from Clone B |
| `pe-inspection-a.json` | PE inspection of Clone A binaries |
| `pe-inspection-b.json` | PE inspection of Clone B binaries |
| `pe-comparison.json` | PE comparison report |
| `leak-scan-a.json` | Path leak scan for Clone A |
| `leak-scan-b.json` | Path leak scan for Clone B |

## Constraints Verified

- No modifications to `app/lib/**`, `app/windows/**`, `app/pubspec.yaml`, `app/pubspec.lock`
- Empty production diff: `git diff --exit-code 47f9500..HEAD -- app/lib app/windows app/pubspec.yaml app/pubspec.lock`
- Exactly 1 commit after baseline
- Both clones created with `git clone --no-local` (no worktrees, no source tree copies)
- Clones at different path lengths (26 vs 83 chars, delta 57)

## Verdict

**PASS** - Independent fresh-clone committed-state reproducibility verified on this machine.

> **Note**: This proves same-machine reproducibility from two genuinely independent fresh clones. It does NOT prove cross-machine reproducibility or fully hermetic builds. The builds share the same OS, SDK, and toolchain.
