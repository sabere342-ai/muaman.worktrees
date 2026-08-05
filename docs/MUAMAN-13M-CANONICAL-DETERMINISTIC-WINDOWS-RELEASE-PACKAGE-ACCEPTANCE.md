# MUAMAN-13M - Canonical Deterministic Windows Release Package Acceptance

**Status:** PASS - the sole official packaging entrypoint
`tools/release/package_windows_release.ps1` is adopted and verified: it
reproduces the accepted canonical release payload byte-for-byte, produces
byte-deterministic ZIP packages across independent processes and working
directories, fails closed on every negative control, is secret-clean, and keeps
the historical 13L and 13K guards passing. All M1..M8 gates and N1..N4 negative
controls report `pass=true` on the final HEAD.

**Baseline:** commit `ea80321f218bc0fd74c8ccc3a7e8621d79325a0b` (MUAMAN-13L;
the 13M branch is created at this commit and the final branch contains exactly
one additional commit, `rev-list --count` after baseline = 1).
**Branch:** `codex/muaman-13m-canonical-deterministic-release-package`.
**Date:** 2026-08-06 (all UTC timestamps recorded inside the evidence tree).

---

## 1. Purpose and scope

Add the **single official packaging entrypoint** for turning a verified MUAMAN
Windows Release into a deterministic, portable, operator-ready ZIP. Before 13M,
the release pipeline ended at a verified Release directory: there was no
canonical packaging command, no deterministic archive contract, and no
fail-closed gate that refused to package a tampered or incomplete release.

13M adds a **thin operational interface only**:

- new `tools/release/package_windows_release.ps1` - the sole official packaging
  entrypoint (deterministic ZIP + SHA-256 + package manifest + result JSON),
- new `tools/muaman13m/guard_tests_13m.ps1` - the M1..M8 / N1..N4 guard-point
  harness,
- `docs/MUAMAN-13M-CANONICAL-DETERMINISTIC-WINDOWS-RELEASE-PACKAGE-ACCEPTANCE.md`
  - this report (26 sections),
- `docs/evidence/muaman-13m/` - evidence (00-baseline .. 10-final-state).

The packager **reuses** the committed canonical verifier
`tools/release/verify_release.ps1` and the committed MUAMAN-13K legal manifest;
it never duplicates build, verification, or legal-manifest logic, never runs
`flutter build` of any kind, never invokes `build_hardened.ps1`, and never
modifies the verified release directory (read-only input). The scope is tools
and documentation only: no production code, dependency, SDK, plugin, MSBuild,
or app-tree change is made. No binary ZIP is committed to the repository.

## 2. Outcome

**PASS.** Verified by `tools/muaman13m/guard_tests_13m.ps1` on the final HEAD
(`allPass=true`):

- **M1** static delegation integrity - the packager contains no build logic, no
  verifier re-implementation, and no `Compress-Archive`; it delegates legality
  entirely to the canonical verifier + committed legal manifest;
- **M2** CWD independence - packaging succeeds and is byte-identical from the
  repo root, a repo sub-folder, an external directory, and with a
  script-derived `-RepoRoot`;
- **M3** verify-before-package + fail-closed - verification runs before any ZIP
  creation and every invalid input produces a non-zero exit with no ZIP;
- **M4** deterministic package identity - authoritative P1 and P2 ZIPs are
  byte-identical (SHA-256, length, 13-entry ordinal order, per-entry
  metadata);
- **M5** extraction equivalence - P1 and P2 extract to exactly the accepted
  canonical payload, byte-identical to B1, no missing/extra/differing files,
  no traversal or absolute-path entries;
- **M6** secret and environment hygiene - scripts, report, evidence, checksums,
  and both ZIPs scan clean (findings = 0);
- **M7** active documentation - the report declares the sole official packaging
  entrypoint and the build -> verify -> package -> checksum flow; no active doc
  instructs ad hoc `Compress-Archive` packaging;
- **M8** repository and lineage integrity - branch, baseline ancestry, exactly
  one commit, clean tree, no merges/tags/upstream, no scope or
  production/dependency/SDK/plugin diffs;
- **N1..N4** negative controls all pass on disposable copies only (missing
  file, modified file, extra file, partial-output safety); the authoritative B1
  release directory is never modified.

Historical guards stay green: `tools/release/guard_tests_13l.ps1` reports
L1..L8 `allPass=true` against B1 and `tools/muaman13k/guard_tests.ps1` reports
G1..G10 `allPass=true`.

## 3. Constraints honoured

- Exactly **one** commit after the baseline `ea80321`; `HEAD^` equals the
  baseline; no push, tag, merge, or upstream; final tree clean.
- The packaging entrypoint reuses `tools/release/build_windows_release.ps1`
  and `tools/release/verify_release.ps1`; build/verify/legal-manifest logic is
  never duplicated.
- The raw `flutter build windows --release` is never invoked and
  `build_hardened.ps1` is never used for packaging.
- Accepted release identity to reproduce: **13 files / 33,273,462 bytes /
  cross-hash `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9`**.
  If B1 differed the phase would stop and investigate (Outcome C); B1 matched
  exactly.
- Deterministic ZIP: ordinal entry order, forward slashes, archive-relative
  paths only, no duplicates/traversal/absolute paths, no random GUIDs, no
  current timestamps, no archive comment, constant documented entry timestamp,
  no filesystem-enumeration dependence; the input release is never modified.
- The ZIP contains only verified release files; no reports/evidence/source/Git
  metadata/tools/logs inside the archive.
- Outputs: `muaman-windows-release.zip`, `.zip.sha256`, `package-manifest.json`,
  `package-result.json`; evidence committed under `docs/evidence/muaman-13m/`;
  no binary ZIP committed.
- Permitted changes: `tools/release/**`, `tools/muaman13m/**`, `docs/**`.
  Forbidden: app production/dependency/SDK/plugin diffs, MSI/MSIX/NSIS/signing/
  publish/auto-update, manual binary editing, reuse of old artifacts.
- Package/build-critical scripts are frozen (hash + diff recorded in
  `02-freeze`) before the authoritative B1/P1/P2 runs and proven unchanged
  after the final commit.
- PowerShell quality: strict mode, terminating errors, absolute-path
  resolution, no alias reliance, ordinal ordering, streaming hashes, atomic
  temp-to-final ZIP move, non-zero exits, no `Compress-Archive` (proven .NET
  `ZipArchive` instead).

## 4. Baseline state (verified)

Recorded in `docs/evidence/muaman-13m/00-baseline/baseline-state.txt`:

- worktree `baseline-commit=ea80321f218bc0fd74c8ccc3a7e8621d79325a0b`,
- `branch=codex/muaman-13m-canonical-deterministic-release-package`,
- `git status --porcelain` at phase start: only the new untracked 13M files
  (`tools/muaman13m/`, `tools/release/package_windows_release.ps1`,
  `docs/evidence/muaman-13m/`),
- `git diff HEAD --stat` (tracked files): empty,
- HEAD subject: `MUAMAN-13L: adopt canonical hardened Windows release entrypoint`.

The 13M worktree was created clean at the baseline; nothing was committed before
the single final commit.

## 5. Environment topology

Recorded in `docs/evidence/muaman-13m/01-environment/environment-probe.txt`:

- OS: Microsoft Windows 11 Pro 10.0.26200, machine `ISLAM`, processor AMD64,
  user `saber`.
- PowerShell: **5.1.26100.6584 (Desktop)** - `powershell.exe` only; `pwsh.exe`
  is not installed, so every canonical command and every guard runs on Windows
  PowerShell 5.1 (matches repo conventions).
- Git: 2.55.0.windows.2.
- Flutter: `C:\src\flutter\bin\flutter.bat` 3.24.5 stable, framework revision
  `dec2ee5c1f`, engine revision `a18df97ca5`, Dart 3.5.4, DevTools 2.37.3
  (queried via `--version --machine`).
- SDK A (the committed 13I/13K build SDK): `C:\m13i\a\sdk`; the patched
  `visual_studio.dart` postimage hash is
  `D08E9D71E978FDE1478FBF438DCEA6D16D26EA966D271F7D5108AC86E3CC5423`, matching
  the 13K guard expectation (G3).
- MSBuild: auto-discovered by the 13L entrypoint at `MSBuild\Current\Bin\amd64`
  under the VS 2026 BuildTools install; PUB_CACHE auto-discovered at the
  platform pub cache (`%LOCALAPPDATA%\Pub\Cache`).
- .NET Framework runtime 4.0.30319.42000 (ZipArchive / SHA256 used by the
  packager and the harness).

## 6. Accepted release identity

The identity that 13M must reproduce is the accepted MUAMAN-13K legal payload,
captured in the committed legal manifest
`docs/evidence/muaman-13k/04-k1-source-a-sdk-a-shorttemp/release-manifest.json`
and re-verified by the 13L phase:

| attribute    | value                                                            |
|--------------|------------------------------------------------------------------|
| file count   | 13                                                               |
| total bytes  | 33,273,462                                                       |
| cross-hash   | `EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9` |

Per-file (`rel | size | sha256`) from the B1 manifest
(`03-b1-build/release-manifest.json`):

| rel | size | sha256 |
|-----|------|--------|
| `data/app.so` | 7,324,576 | `8278EC7131C921D480AFEAF69B0D27624B11DF3E9E74180BB80273A09E1E2D3D` |
| `data/flutter_assets/AssetManifest.bin` | 117 | `00AF55AD3D6F21898FE77E0FF092D1A1CDA52C941B6860E9928D45C8AF8C095D` |
| `data/flutter_assets/AssetManifest.json` | 109 | `4A9B3DE7EEC9BA46B279BBCCD132E32F52D6D555D79DDA4AA7F3BCB4E9BD651F` |
| `data/flutter_assets/FontManifest.json` | 208 | `CD7E03645BC44B2DD47B7CB626F51C4ECBF55A197AB77241628B47AC165FBE21` |
| `data/flutter_assets/NOTICES.Z` | 89,152 | `AB7675DAC8C7DCDF17A78E747C669C9BA13ED55306422F6D65F31BA98DA82DD6` |
| `data/flutter_assets/fonts/MaterialIcons-Regular.otf` | 1,645,184 | `D9865B671A09D683D13A863089D8825E0F61A37696CE5D7D448BC8023AA62453` |
| `data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf` | 257,628 | `67C44FE9183B002E79DDE7F6977E2988661C9A3E4A3C5FCE968787EFDBED823C` |
| `data/flutter_assets/shaders/ink_sparkle.frag` | 17,304 | `3AA09424D1DC391FD59A9735EFE986FF43302B5E5BC310926AFE11C68626C3B2` |
| `data/icudtl.dat` | 778,864 | `C12537022EF818991A7BFED41A76D8D6AE962FFBC0E6511AC762A5D0845E7F7C` |
| `flutter_windows.dll` | 18,181,632 | `B66713715A7AEAA2F88BA18838AA7C245556EAAEB31C82DA3F5AEBCB71A7715E` |
| `muaman_store.exe` | 90,624 | `194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9` |
| `pdfium.dll` | 4,749,824 | `0C88EBACC0393FD45FC3E7B35E31E72C9E55B633A846A7ECF4085694DBA68ABD` |
| `printing_plugin.dll` | 138,240 | `959F1E85FEEC7D8AE02F97760608E8022CFF3C3D556AADC824306EA1AFE2A867` |

## 7. Canonical packaging design (sole official entrypoint)

`tools/release/package_windows_release.ps1` is a **thin operational interface**
with a strict contract:

1. resolves every path from explicit parameters or its own script location
   (`$PSScriptRoot` / `$RepoRoot`) - never from the caller CWD;
2. runs the canonical verifier `tools/release/verify_release.ps1` **in a fresh
   process** against the committed legal manifest before touching any archive;
3. fails closed with exit 1 and **no ZIP** when verification fails;
4. reads the release directory read-only and never modifies, touches, patches,
   or normalizes any release file;
5. produces the ZIP through .NET `ZipArchive` only (no `Compress-Archive`);
6. writes the package manifest and result JSON describing the package and the
   run, plus a sha256sum-style `.sha256` file;
7. stages the archive as `*.partial.tmp` and moves it into place atomically
   (`[System.IO.File]::Move`) so no partial ZIP can appear at the final path;
8. exits 0/1/2/3/4 (success / verification failure / parameter failure /
   packaging failure / unexpected error), each stage tracked.

The packager contains **no build logic** (M1), **no verifier
re-implementation** (M1), **no legal-manifest re-implementation** (M1), and
never invokes `build_hardened.ps1`. The cross-hash it reports is read from the
verifier output; it is never recomputed by the packager.

## 8. Canonical command (build -> verify -> package -> checksum flow)

The supported, documented operator flow is exactly three commands plus the
automatic checksum:

**Step 1 - build (canonical 13L entrypoint, unchanged):**

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/release/build_windows_release.ps1 -SdkRoot C:\m13i\a\sdk -ExperimentId <id> -EvidenceDir <evidence>
```

resolves the repository root from its own location, runs the committed
FileTracker preflight first in a fresh process, and delegates the hardened
build to `tools/muaman13j/build_hardened.ps1`. Output: the verified Release
directory `app/build/windows/x64/runner/Release`.

**Step 2 - verify (canonical verifier, run automatically by the packager):**

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/release/verify_release.ps1 -ReleaseDir <release-dir> -LegalManifest <manifest> -Out <json>
```

compares the release against the committed legal manifest on the exact
relative-path set, per-file size and SHA-256, plus the canonical cross-run
hash.

**Step 3 - package (sole official packaging entrypoint):**

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/release/package_windows_release.ps1 -RepoRoot <repo> -ReleaseDir <release-dir> -OutputDir <out> -EvidenceDir <evidence>
```

Optionals: `-LegalManifest`, `-Verifier`, `-ZipName` (default
`muaman-windows-release.zip`), `-ConstantZipTimestamp` (default
`2024-01-01T00:00:00`). The packager re-runs verification internally (fresh
process) and produces the ZIP only after verification passes.

**Step 4 - checksum (automatic):**

```
<output>/muaman-windows-release.zip.sha256
```

sha256sum-style line `UPPER_HEX  muaman-windows-release.zip` written alongside
the ZIP, matching the ZIP byte SHA-256.

The outputs are distinct: `build_windows_release.ps1` produces a Release
directory; `verify_release.ps1` produces a verification JSON; the packager
produces the ZIP + `.sha256` + `package-manifest.json` + `package-result.json`.
No active documentation directs operators to package with ad hoc
`Compress-Archive` commands or any second packaging script.

## 9. Deterministic ZIP design

The packager guarantees byte-deterministic archives:

- **ordinal entry order** - entries are collected and sorted with ordinal
  string comparison (`.NET` `StringComparer.Ordinal`); the order does not
  depend on NTFS directory enumeration;
- **forward slashes** - every entry name uses `/`; `data/app.so`,
  `data/flutter_assets/...`, `data/icudtl.dat`, and the four DLL/EXE files at
  the archive root;
- **archive-relative paths only** - no absolute paths, no `..`, no duplicate
  entry names, no traversal;
- **constant entry timestamp** - every entry uses the constant local wall-clock
  `2024-01-01T00:00:00` (DOS date/time `0x58210000`), applied to ZIP metadata
  only; release file bytes are never touched;
- **no random GUIDs, no current timestamps, no archive comment** - the ZIP has
  no comment and no per-run randomness;
- **no filesystem-enumeration dependence** - deterministic given the same
  release payload;
- **single producer** - one verified release, one ZIP, produced identically
  from any working directory and any output directory.

The proven package identity is therefore stable: the authoritative P1/P2 ZIP is
`muaman-windows-release.zip`, **14,485,278 bytes**, SHA-256
`57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`, with 13
entries in ordinal order and constant timestamp metadata.

## 10. Freeze discipline

Before any authoritative B1/P1/P2 run, the package/build-critical scripts were
frozen: SHA-256 + `git diff/status` recorded in
`02-freeze/package-critical-sha256.txt`:

| path | sha256 | tracking |
|------|--------|----------|
| `tools/release/build_windows_release.ps1` | `19B911DB6ACEEB6347AAF5EC7C99E74FB302119DDD8E4B8783BCD0C576C8F8DA` | tracked |
| `tools/release/verify_release.ps1` | `8DCFE24A0523E291D42199E73FCBABAB0AFF94EECB2D59EC8E09BCD861E200A5` | tracked |
| `tools/release/package_windows_release.ps1` | `BF72C6DCC5D41D2FD353B01FAD0CC7F6B414E575155A69FEBA17540CA3DFF452` | new |
| `tools/muaman13i/run_experiment.ps1` | `E42729D6640CCA5B814BCA91DFAFC56B28D3D91F2E7ECDBC001E497A940968EE` | tracked |
| `tools/muaman13j/build_hardened.ps1` | `1FD42351E5FC0D06ABC61CCA0BD6E111CD18626C42FF7337AAF345FED40F5761` | tracked |
| `tools/muaman13j/check_filetracker_state.ps1` | `4772BBFDF77363205E2D8FB1F614A9A968776E34DB9BE2DE7F2F64EE7570028D` | tracked |
| `tools/muaman13k/compare_release.ps1` | `D6D4107647AFD2F221461CA28C16048E95D821DF303A648C9EB38EB6F714B200` | tracked |
| `tools/muaman13k/guard_tests.ps1` | `A2034753F81AC45AB9C3DE6A26070ED7F4256F255A66671CD0539AF358D2E90B` | tracked |
| `tools/muaman13k/leak_scan_13k.ps1` | `ABD87422222D2962451A1BFD9406DDC8363E870BA297D532401C352EFFD96654` | tracked |
| `tools/muaman13k/make_release_manifest.ps1` | `05DED7D39BA41ED4FE983A4B5CC97C96463299AEBE1E7C3F369F8380830EACA1` | tracked |
| `tools/muaman13m/guard_tests_13m.ps1` | `E61DA1C576CF59E63445D343BC3714A2FD7934A730EA372D27F5450426594EDC` | new |

These hashes are re-computed and compared after the final commit
(`10-final-state`); no frozen file changes after the freeze point. The only
freeze updates were (a) the packager's `.sha256` output-format fix (sha256sum
style, no angle brackets) and (b) LF normalization of the guard harness
line endings; both were made before the commit and re-recorded in `02-freeze`.

## 11. B1 fresh canonical build

B1 was produced from a **fresh clone** `C:\m13m\b1\src` at the baseline commit
`ea80321`, built by the canonical 13L entrypoint (controller CWD outside the
clone, mirroring the 13L L6 run exactly):

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\m13m\b1\src\tools\release\build_windows_release.ps1 -SdkRoot C:\m13i\a\sdk -ExperimentId B1 -EvidenceDir C:\m13m\b1\evidence
```

- preflight (committed FileTracker check, fresh process): **PASS**, exit 0;
- hardened build: exit 0; 13I run `exit=0 rsp=False fileTrackerCrash=False
  compilerId=True configure=True release=True`, elapsed 70.5 s; total wall
  time 77.4 s;
- release output: `C:\m13m\b1\src\app\build\windows\x64\runner\Release`;
- manifest: **13 files / 33,273,462 bytes** (`03-b1-build/release-manifest.json`).

The fresh clone was verified pristine before the build: no 13M untracked files,
no pre-existing build directory, HEAD exactly the baseline.

## 12. B1 release verification

The authoritative B1 verification ran through the canonical verifier
`tools/release/verify_release.ps1` against the committed 13K legal manifest:

```
new=13/33273462B legal=13/33273462B identical=True diffs=0 crossNew=EE892B351DC7CC343D4005C49F745CC24F69DCD243C46D5AF526701C11FCB0A9
```

`identical=True`, 0 diffs, cross-hash exactly the accepted
`EE892B35...FCB0A9`. As an independent byte-for-byte cross-check, the 13L
guard's L7 delegated the comparison to the committed legal tool
`tools/muaman13k/compare_release.ps1` (B1 vs the 13K K1 release directory):
`identical=true`, 0 diffs, `crossHashA == crossHashB == EE892B...`. **B1
matches the accepted identity; Outcome C did not occur.**

## 13. P1 and P2 packaging runs (CWD independence)

Two authoritative packaging runs in **separate fresh processes** against the
same immutable B1 release directory:

- **P1** - invoked with the repository root as the working directory, output
  `C:\m13m\p1\out`, evidence `C:\m13m\p1\evidence`;
- **P2** - invoked from an unrelated external directory `C:\m13m\p2`, output
  `C:\m13m\p2\out`, evidence `C:\m13m\p2\evidence`.

Both ran `tools/release/package_windows_release.ps1` with the same
`-RepoRoot -ReleaseDir` and the default ZIP name and constant timestamp. Both
reported: release verification PASS (exit 0), 13 files / 33,273,462 bytes /
cross-hash `EE892B...`, ZIP created 14,485,278 bytes, SHA-256
`57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`, exit 0.
Evidence and command records are committed under `04-p1-package/` and
`05-p2-package/`. The harness M2 additionally executed independent packaging
from four contexts (repository root, repository sub-folder, outside the
repository, outside with script-derived `-RepoRoot`); all four produced the
same byte-identical ZIP.

## 14. Deterministic package identity (byte-identical ZIPs)

`06-package-comparison/p1-p2-byte-comparison.json` and the harness M4
`package-comparison.json` prove:

- byte-identical (full-content comparison): `true`;
- length P1 = length P2 = **14,485,278**;
- SHA-256 P1 = SHA-256 P2 = `57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`;
- entry count 13 = 13; ordinal entry order identical;
- per-entry metadata (name, length, compressed length, timestamp, SHA-256)
  identical for all 13 entries (diff count 0);
- archive comment: empty.

The full ordinal entry list (identical in P1 and P2):
`data/app.so`, `data/flutter_assets/AssetManifest.bin`,
`data/flutter_assets/AssetManifest.json`, `data/flutter_assets/FontManifest.json`,
`data/flutter_assets/NOTICES.Z`,
`data/flutter_assets/fonts/MaterialIcons-Regular.otf`,
`data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf`,
`data/flutter_assets/shaders/ink_sparkle.frag`, `data/icudtl.dat`,
`flutter_windows.dll`, `muaman_store.exe`, `pdfium.dll`, `printing_plugin.dll`.

## 15. Extraction equivalence

`07-extraction/extraction-comparison.json` and the harness M5 prove that both
packages extract to exactly the accepted canonical payload:

- extracted file count = 13 = 13 = 13 (B1 / P1 / P2);
- extracted total bytes = 33,273,462 (all three);
- extracted cross-hash = `EE892B...` (all three);
- per-file comparison vs B1: **0 missing, 0 extra, 0 differing** for P1 and P2;
- path safety: no traversal, no absolute-path, no backslash, no drive-qualified
  entry names in either archive.

## 16. Negative controls (N1-N4)

`08-negative-controls/negative-control-results.json` records all four controls,
each run by the harness M3 on **disposable copies only** (the authoritative B1
release directory was never touched; `releaseDirNeverModified=true`):

| control | scenario | expected | actual |
|---------|----------|----------|--------|
| N1 | legal release copy with one file deleted | verification failure (exit 1), no ZIP | exit 1, no ZIP, verdict FAIL, no partial archive |
| N2 | legal release copy with one byte flipped in a legal file | verification failure (exit 1), no ZIP | exit 1, no ZIP, verdict FAIL (1 diff), no partial archive |
| N3 | legal release copy plus a stray extra file | verification failure (exit 1), no ZIP | exit 1, no ZIP, verdict FAIL, no partial archive |
| N4 | a directory occupies the final ZIP name | packaging failure, no valid ZIP, failure recorded | exit 3, no valid ZIP, failure reason recorded, no partial archive |

Every control produced the expected non-zero exit and left **no partial or
valid ZIP** behind, proving the packager fails closed on all invalid inputs.

## 17. Secret and environment hygiene (M6)

`09-guards/secrecy-scan.json` reports the M6 scan (`findingCount=0`, `clean`):

- **shipping scripts** (`package_windows_release.ps1`,
  `verify_release.ps1`) and **this report** are scanned for secret patterns
  **and** env-leak tokens (shipping artifacts must not contain user-profile,
  temp, dot-git, or pub-cache path literals);
- the **guard harness** and the **committed evidence tree** are scanned for
  secrets (documented absolute test/build paths under `C:\m13m` are permitted
  in evidence);
- both **ZIPs** are scanned on entry names and entry bytes for secret patterns
  and documented build/absolute tokens: **zero findings** in P1 and P2.

The historical 13L L4 secret-hygiene scan (full committed-tree scan) also
reports `findingCount=0` (`09-guards/secrecy-scan-13l.json`).

## 18. Guard-point verification (M1-M8)

`tools/muaman13m/guard_tests_13m.ps1` verdicts (authoritative inputs: B1
release + P1/P2 ZIPs). The pre-commit run reports M1, M2, M3static, M3, M4, M5,
M6 `pass=true`; M7 is `pass=true` once this report exists; M8 is verified on
the final HEAD (exactly one commit, clean tree) and the post-commit result is
reported in `10-final-state` and the closing response. Negative controls
N1..N4 (M3 dynamic) `allPass=true`.

- **M1** static delegation integrity - the packager is the only new release
  tool; it contains no `flutter build` invocation, no `build_hardened.ps1`
  invocation, no `run_experiment.ps1` invocation, no `Compress-Archive`, and
  no verifier re-implementation; it invokes only
  `tools/release/verify_release.ps1`.
- **M2** CWD independence - byte-identical packages from repo root /
  sub-folder / external dir / script-derived `-RepoRoot`.
- **M3** verify-before-package + fail-closed - static order check
  (M3static) and the dynamic N1..N4 controls all pass.
- **M4** deterministic package identity - byte-identical P1/P2 (section 14).
- **M5** extraction equivalence - sections 15.
- **M6** secret and environment hygiene - section 17.
- **M7** active documentation - this report declares the sole official
  packaging entrypoint; build/verify/package/checksum commands and outputs are
  distinct; no ad hoc `Compress-Archive` instructions in any active doc.
- **M8** repository and lineage integrity - branch matches, HEAD descends from
  the baseline, exactly one commit, clean tree, no merges, no tag at HEAD, no
  scope violations, no production/dependency/SDK/plugin diffs (post-commit).

## 19. Final response format (section-19 contract)

The closing response for MUAMAN-13M must be delivered in the accepted final
format. The contract is:

1. State the phase name and the final outcome (**PASS**).
2. Report the final commit SHA (from `git rev-parse HEAD` on the 13M branch),
   `HEAD^` = baseline `ea80321`, and `rev-list --count` after baseline = 1.
3. Report the final working-tree state (`git status --porcelain` empty) and
   the absence of pushes/tags/merges.
4. Report the post-commit guard results: M1..M8 `pass=true`, N1..N4
   `pass=true`, 13L guards L1..L8 and 13K guards G1..G10 `allPass=true`.
5. Report the accepted identities: release cross-hash `EE892B...` and package
   SHA-256 `57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`.
6. Reconfirm the frozen script hashes are unchanged after the commit.
7. Close with the acceptance statement and the location of the committed
   evidence (`docs/evidence/muaman-13m/`).

This report is section 19 of the 26-section governing document; the contract is
mirrored here so the acceptance criteria are unambiguous at review time.

## 20. Historical 13L and 13K guard re-runs

`09-guards/guard-results-13l.json` and `09-guards/guard-results-13k.json`:

- **13L** (`tools/release/guard_tests_13l.ps1`, with B1 as the fresh release
  and the 13K K1 directory as the comparison A): **allPass=true** for
  L1 (static delegation), L2 (CWD independence), L3 (preflight ordering),
  L4 (secret hygiene), L5 (13K guard fresh process), L7 (release
  verification, byte-identical vs K1 via the legal tool), L8 (active docs).
- **13K** (`tools/muaman13k/guard_tests.ps1`, committed 13K evidence tree):
  **allPass=true** for G1..G10, including G2 (committed script hashes
  unchanged), G3 (SDK patch hash `D08E9D71...`), G9 (deterministic payload
  identity) and G10 (fresh-process preflight).

The 13M work introduces no regression to either historical phase.

## 21. Post-commit gates

After the single commit, the following are verified and recorded in
`10-final-state/` and the closing response:

- `git rev-parse HEAD` = the 13M commit; `HEAD^` = baseline `ea80321`;
- `rev-list --count ea80321..HEAD` = 1 (exactly one commit);
- `git status --porcelain` = empty (clean tree);
- `git diff --check` = no whitespace errors;
- no `git push`, no tags, no merges, no upstream configured;
- changed-file scope limited to `tools/release/**`, `tools/muaman13m/**`,
  `docs/**`; no app production/dependency/SDK/plugin diffs;
- frozen script SHA-256s re-computed and equal to `02-freeze`;
- guards re-run from the final HEAD (results reported in the closing response,
  evidence not re-committed because a commit cannot contain its own proof).

## 22. Scope audit

`git diff --name-only <baseline>..HEAD` is limited to:

- `tools/release/package_windows_release.ps1` (new),
- `tools/muaman13m/guard_tests_13m.ps1` (new),
- `docs/MUAMAN-13M-CANONICAL-DETERMINISTIC-WINDOWS-RELEASE-PACKAGE-ACCEPTANCE.md` (new),
- `docs/evidence/muaman-13m/**` (new evidence).

No change touches `app/` production, dependency, SDK, plugin, or Windows
platform files. No MSI/MSIX/NSIS/signing/publish/auto-update artifact is
produced. No binary ZIP is committed. The only change to previously committed
tracked files is the addition of a packaging pointer in the active 13L release
documentation (section 24), which stays within the `docs/**` scope and keeps
all 13L guards green.

## 23. Risks and mitigations

- **Build reproducibility risk** - the build embeds no build-path that
  affects the accepted files, proven by B1 (built at `C:\m13m\b1`) matching
  K1 (built at `C:\m13k`) and the 13L L6 run byte-for-byte. Mitigation:
  canonical verifier + legal tool cross-check on every run.
- **Zip-metadata drift risk** - archives could differ in timestamps, order, or
  comments. Mitigation: constant entry timestamp, ordinal ordering, no
  comment, byte-level comparison (M4).
- **CWD dependence risk** - packaging could depend on the caller's directory.
  Mitigation: all paths resolve from parameters / script location; M2 runs
  four contexts.
- **Fail-open risk** - a tampered release could still be packaged. Mitigation:
  verification runs first in a fresh process and the packager exits 1 with no
  ZIP on any mismatch (M3, N1..N3).
- **Partial-output risk** - a crash could leave a half-written ZIP. Mitigation:
  `*.partial.tmp` staging + atomic move; N4 proves no partial remains.
- **Secret-leak risk** - build paths or secrets could leak into scripts, the
  report, or the archive. Mitigation: M6 scan of scripts/report/evidence/ZIP
  entry names and bytes (0 findings).
- **Evidence-immutability risk** - a commit cannot contain its own proof.
  Mitigation: 13L-style `final-state` note + closing-response post-commit
  verification; frozen hashes re-checked after the commit.

## 24. Operator documentation updates

The active 13L release document
`docs/MUAMAN-13L-CANONICAL-HARDENED-WINDOWS-RELEASE-ENTRYPOINT.md` is updated
with a packaging subsection that:

- declares `tools/release/package_windows_release.ps1` the **sole official
  packaging entrypoint**;
- documents the complete build -> verify -> package -> checksum flow
  (section 8 of this report);
- lists the four outputs (ZIP, `.sha256`, `package-manifest.json`,
  `package-result.json`);
- points to this 13M report and the committed evidence tree for details.

The update keeps the canonical build command unchanged, adds no raw
`flutter build` instructions, and keeps L8 (active-docs guard) passing.

## 25. Evidence index

All evidence is committed under `docs/evidence/muaman-13m/`:

- `00-baseline/` - baseline commit, branch, initial `git status`, untracked
  new files;
- `01-environment/` - `environment-probe.txt` (OS, PS 5.1, git, Flutter, SDK A
  patch hash, MSBuild, .NET);
- `02-freeze/` - `package-critical-sha256.txt` (frozen hashes + git state);
- `03-b1-build/` - `canonical-command.txt`, `release-dir.txt`,
  `b1-build-console.txt`, `preflight-result.json`, `build-result.json`,
  `release-manifest.json`, `release-verification.json`, hardened-env/clean/
  preflight/pubget/build/analysis logs;
- `04-p1-package/` - `package-command.txt`, `package-result.json`,
  `package-manifest.json`, `release-verification.json`, `muaman-windows-release.zip.sha256`;
- `05-p2-package/` - same for P2;
- `06-package-comparison/` - `p1-p2-byte-comparison.json`,
  `package-comparison.json`, `zip-entry-manifest-p1.json`,
  `zip-entry-manifest-p2.json`, `zip-entries-metadata.txt`;
- `07-extraction/` - `extraction-comparison.json`,
  `extracted-manifest-p1.json`, `extracted-manifest-p2.json`;
- `08-negative-controls/` - `negative-control-results.json`;
- `09-guards/` - `guard-result.json` (M1..M8), `secrecy-scan.json`,
  `active-doc-scan.json`, `guard-results-13l.json`,
  `guard-results-13k.json`, `guard-results-13k-fresh.json`,
  `secrecy-scan-13l.json`, `cwd-independence-results.json`,
  `release-comparison.json`, `release-comparison-legal-tool.json`;
- `10-final-state/` - `final-state.txt` (post-commit state note, mirrors the
  13L convention that a commit cannot embed its own hash).

## 26. Acceptance result

**PASS.** MUAMAN-13M is accepted:

- the **sole official packaging entrypoint** is
  `tools/release/package_windows_release.ps1` (declared in section 7, enforced
  by M7);
- one fresh canonical B1 build reproduces the accepted payload
  (13 / 33,273,462 / `EE892B...`) byte-for-byte, verified by the canonical
  verifier and the committed legal tool;
- authoritative P1/P2 packaging runs produce **byte-deterministic** ZIPs
  (14,485,278 bytes, SHA-256 `57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`),
  identical across processes and working directories, with constant entry
  timestamps and ordinal entry order;
- extraction equivalence is exact; all four negative controls fail closed with
  no partial or valid ZIP; the M6 hygiene scan is clean; historical 13L/13K
  guards remain green;
- exactly one commit after the baseline, final tree clean, scope limited to
  tools/documentation/evidence;
- the build -> verify -> package -> checksum flow is documented and is the
  only documented packaging path.
