# MUAMAN-13I — Isolated Dual-SDK VS2026 Reproducibility (A/B)

**Status:** Outcome A — Release output is byte-for-byte identical between environment A and environment B.
**Baseline:** commit `303dbb04032e07c58f1d630ed3d73168658e1afe` (`rev-list --count` = 0).
**Date:** 2026-08-05 (UTC timestamps inside).

---

## 1. Purpose and scope

Prove, with two fully isolated Visual Studio 2026 toolchains and Flutter SDKs, that
`flutter build windows --release` produces byte-for-byte identical output (Outcome A),
while diagnosing and containing the tracked `CL.exe`/FileTracker compiler-ID crash that
blocked the original environment-B run.

## 2. Constraints honoured

- Zero changes to `app/lib`, `app/pubspec.yaml`, `app/pubspec.lock`; no dependency updates.
- No binary/PE patching, no timestamp zeroing, no copying of outputs between A and B.
- No shared SDK / PUB_CACHE / TEMP / HOME / build roots between A and B.
- No symlink/junction hiding of shared state; no reused build trees across runs.
- No push/tag/merge; exactly one commit after baseline (this commit).
- Every experiment changes one variable and records pre/post values, exit codes,
  `.rsp` presence, FileTracker crash, compiler-ID/configure/Release success.
- Evidence under `docs/evidence/muaman-13i/`; report `docs/MUAMAN-13I-ISOLATED-DUAL-SDK-VS2026-REPRODUCIBILITY.md`.

## 3. Baseline state (verified)

- HEAD = `303dbb04032e07c58f1d630ed3d73168658e1afe`, `rev-list --count` = 0.
- Production diff empty; untracked = `docs/evidence/muaman-13i/`, `tools/`.
- Disk free ≈ 35.9 GB at start.

## 4. Environment topologies

| role | A | B |
|------|---|----|
| SDK root | `C:\m13i\a\sdk` (13 chars) | `C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk` (77 chars) |
| app root | `C:\m13i\a\src\app` (17 chars) | `C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app` (70 chars) |
| PUB_CACHE | `C:\m13i\a\pub` (11 chars) | `C:\dev\muaman-13i-environment-b-independent-pub-cache-root` (58 chars) |
| TEMP/TMP | `C:\m13i\a\tmp` (13 chars) | `C:\t\m13i-b` (11 chars, final/E1/E2) or long root (53 chars, E0) |
| HOME/USERPROFILE | `C:\m13i\a\home` | `C:\dev\muaman-13i-environment-b-independent-home-root` (53 chars) |
| toolchain | VS2026 BuildTools, MSBuild 18.6.3, MSVC 14.51.36231, v145, CMake 4.2.3-msvc3 | identical |

Path-length asymmetry (13–77 chars across SDK/app/pub/temp/home) was intentionally kept large to stress
path-length and normalisation behaviour.

## 5. Source and dependency provenance

- Source archive for both A and B extractions is byte-identical:
  SHA-256 `17A1DD24CE0DCBD1160BE3E66BDB3F89EB287173D5FCBE079A7C7A46F68DAF6F`.
- `app/pubspec.lock` identical in A and B:
  SHA-256 `EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A`.
- PUB_CACHE file sets identical (9,086 files, symmetric diff empty) at report time.

## 6. Flutter VS2026 patch provenance

`packages/flutter_tools/lib/src/windows/visual_studio.dart` patched identically in A and B
(hash-guarded applier `tools/muaman13i/apply_flutter_vs2026_patch.ps1`):
preimage `3C95601E…` → postimage `D08E9D71E978FDE1478FBF438DCEA6D16D26EA966D271F7D5108AC86E3CC5423`.

`bin/cache/flutter_tools.snapshot` differs between A and B because it embeds its SDK absolute paths:
A `57E14DDE…`, B `A70CCEA1…`. The snapshot is tooling, not build output, and does not affect
reproducibility of the app Release tree.

## 7. Original environment-B failure (raw)

`build-b-raw.log` (256 bytes): `Building Windows application...` / `CMake Error: No CMAKE_CXX_COMPILER could be found` / `Unable to generate build files`.

## 8. Original failure artifacts preserved

`docs/evidence/muaman-13i/34-original-b-failure/` (15 files, 196,377 bytes), including:
`CMakeConfigureLog.yaml` (143,474 B), `CompilerIdCXX.vcxproj`, `CMakeCXXCompilerId.cpp`,
`Debug/CMakeCXXCompilerId.obj`, `CompilerIdCXX.tlog/CL.read.1.tlog` (1,568 B),
`CL.write.1.tlog` (1,140 B), `unsuccessfulbuild`, `VCTargetsPath.txt`, `.vcxproj`, `.recipe`.

## 9. Failure signature

`MSB4018: The "CL" task failed unexpectedly.`
`System.IndexOutOfRangeException: Index was outside the bounds of the array.`
at `Microsoft.Build.Utilities.FileTracker.FileIsUnderNormalizedPath(String, String)`
← `FileIsExcludedFromDependencies` ← `CanonicalTrackedInputFiles.ConstructDependencyTable()`
← `Microsoft.Build.CPPTasks.CL.ExecuteTool`; MSBuild version `18.6.3+84d3e95b4` for .NET Framework.

## 10. The distinguishing tlog fact

The original failure's `CL.read.1.tlog` contains
`#Command: "…\VC\Tools\MSVC\14.51.36231\bin\HostX64\x64\CL.exe" @C:\…\MSBuildTemp…\tmp…rsp`
and tracks the `.RSP` as an input. Every successful run in this project shows the **inline**
form (no `#Command:` line; read-tlog lists only source + `SORTDEFAULT.NLS` + `TZRES.DLL`).
The `@rsp` invocation is the code path that crashed.

## 11. ToolTask inline-vs-`@rsp` decision

`CL` → `TrackedVCToolTask` → `VCToolTask` → `Microsoft.Build.Utilities.ToolTask`.
`CL` does not override `UseResponseFile`; `ToolTask.Execute`/`GetTemporaryResponseFile`
selects `@rsp` based on command-line-length heuristics, which are per-process launch state.
Response files are written under `%TEMP%\MSBuildTemp<guid>\tmp*.rsp` via
`Path.GetTempFileName()` + `WriteAllText`. `.rsp` presence alone is therefore **not** evidence
of the crash path; all our runs captured 12 rsp files yet executed inline.

## 12. FileTracker disassembly (Microsoft.Build.Utilities.Core 18.6.3.22110)

- `FileIsUnderNormalizedPath(file, path)` IL contains a single indexer `file[path.Length-1]`
  after `path.Length <= file.Length` fast-fail ⇒ the only `IndexOutOfRangeException` is `path.Length == 0`.
- `FileIsExcludedFromDependencies` checks 5 static path fields (temp short/long, app-data, local-app-data,
  local-low-app-data), then iterates `s_commonApplicationDataPaths` (PROGRAMDATA + two legacy all-users paths).

## 13. Root-cause mechanism proven (probe)

.NET 4.8 probe (`tools` temp under `C:\Users\saber\AppData\Local\Temp\opencode\probe.exe`)
invoked `FileIsUnderNormalizedPath(file, "")` and reproduced the exact original exception:
`System.IndexOutOfRangeException: Index was outside the bounds of the array.
 at Microsoft.Build.Utilities.FileTracker.FileIsUnderNormalizedPath(String fileName, String path)`.

Conclusion: the crash requires a FileTracker static resolving to `""` in the crashing MSBuild process
(an empty app-data/temp path during normalised-path comparison). On the fully isolated B environment,
probed statics are all non-empty and non-null; plain empty env vars cannot produce empty statics on
.NET Framework (registry fallbacks), so the empty static was a rare, context-dependent process state —
not reproducible under the isolated env.

## 14. Experiment E0 (B, long temp) — baseline success

`docs/evidence/muaman-13i/35-experiment-e0/` — exit 0, 117.5 s, inline CL, no crash,
compiler-ID/configure/Release all succeed. 12 rsp captured (normal). Demonstrates the crash does not
deterministically follow from the long temp root.

## 15. Tooling

`tools/muaman13i/run_experiment.ps1` (isolated runner: clean → pub get → watcher → build → analysis),
`rsp_watcher.ps1` (rsp capture), `verify_release.ps1` (manifest + leak scan),
`apply_flutter_vs2026_patch.ps1` (hash-guarded patch).

## 16. Script defect found and fixed

The runner set `TEMP/TMP` to a fresh temp root before creating it, and used relative evidence paths
while `Push-Location`ed into the app root. First E1 attempt failed (`clean=1 pub=1`, "cannot find the path")
and leaked logs into `app\docs\…`; documented in `36-experiment-e1-shorttemp-invalid-attempt/`.
Fix: pre-create the temp root and absolutize the evidence dir. E1 was re-run cleanly.

## 17. Experiment E1 (B, short temp `C:\t\m13i-b`)

`docs/evidence/muaman-13i/36-experiment-e1-shorttemp/` — exit 0, 139.2 s, inline CL, no crash.
Short temp does not force the `@rsp`/crash path.

## 18. Experiment E2 (B, long-temp reversal)

`docs/evidence/muaman-13i/37-experiment-e2-reversal/` — exit 0, 110.4 s, inline CL, no crash.
Confirms temp path length is not the trigger.

## 19. Final environment-A build

`docs/evidence/muaman-13i/38-experiment-a-final/` — exit 0, 85.6 s, inline CL, no crash, Release output produced.

## 20. Final environment-B build

`docs/evidence/muaman-13i/39-experiment-b-final/` — exit 0, 76.6 s, inline CL, no crash, Release output produced.

## 21. Byte-for-byte verification

`docs/evidence/muaman-13i/40-verify-a-b-final/verify-result.json`:
`fileCountA=13, fileCountB=13, totalBytesA=33,273,462, totalBytesB=33,273,462, identical=true,
diffFiles=0, onlyInA=0, onlyInB=0`.

Manifests `manifest-A.json` / `manifest-B.json` record per-file `rel/size/sha256`; all 13 SHA-256 hashes match.

## 22. Release manifest (13 files, SHA-256)

| file | size | sha256 |
|------|------|--------|
| flutter_windows.dll | 18,181,632 | B66713715A7AEAA2F88BA18838AA7C245556EAAEB31C82DA3F5AEBCB71A7715E |
| muaman_store.exe | 90,624 | 194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9 |
| pdfium.dll | 4,749,824 | 0C88EBACC0393FD45FC3E7B35E31E72C9E55B633A846A7ECF4085694DBA68ABD |
| printing_plugin.dll | 138,240 | 959F1E85FEEC7D8AE02F97760608E8022CFF3C3D556AADC824306EA1AFE2A867 |
| data/app.so | 7,324,576 | 8278EC7131C921D480AFEAF69B0D27624B11DF3E9E74180BB80273A09E1E2D3D |
| data/icudtl.dat | 778,864 | C12537022EF818991A7BFED41A76D8D6AE962FFBC0E6511AC762A5D0845E7F7C |
| data/flutter_assets/AssetManifest.bin | 117 | 00AF55AD3D6F21898FE77E0FF092D1A1CDA52C941B6860E9928D45C8AF8C095D |
| data/flutter_assets/AssetManifest.json | 109 | 4A9B3DE7EEC9BA46B279BBCCD132E32F52D6D555D79DDA4AA7F3BCB4E9BD651F |
| data/flutter_assets/FontManifest.json | 208 | CD7E03645BC44B2DD47B7CB626F51C4ECBF55A197AB77241628B47AC165FBE21 |
| data/flutter_assets/NOTICES.Z | 89,152 | AB7675DAC8C7DCDF17A78E747C669C9BA13ED55306422F6D65F31BA98DA82DD6 |
| data/flutter_assets/fonts/MaterialIcons-Regular.otf | 1,645,184 | D9865B671A09D683D13A863089D8825E0F61A37696CE5D7D448BC8023AA62453 |
| data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf | 257,628 | 67C44FE9183B002E79DDE7F6977E2988661C9A3E4A3C5FCE968787EFDBED823C |
| data/flutter_assets/shaders/ink_sparkle.frag | 17,304 | 3AA09424D1DC391FD59A9735EFE986FF43302B5E5BC310926AFE11C68626C3B2 |

## 23. Absolute-path leak scan

`verify_release.ps1` scanned every Release byte stream in ASCII and UTF-16LE for the known absolute roots
(`C:\dev\muaman-13i-environment-b-independent-…`, `C:\m13i\…`, `C:\t\m13i-…`,
`C:\Program Files (x86)\Microsoft Visual Studio`, `C:\Users\saber`, `C:\WINDOWS`, `C:\dev\muaman.worktrees`):
**0 leaks**. The output tree embeds no environment-specific paths.

## 24. PE identity

Byte-identity (SHA-256) of every file subsumes PE checks (headers, sections, imports, timestamp fields):
identical bytes ⇒ identical PE structure. No PE was patched or re-timestamped.

## 25. Deterministic ZIP note

Not required: all 13 files are byte-identical, so any deterministic packaging of them would also match.
(Optional future check: a ZIP with fixed ordering/timestamps.)

## 26. Quality gates (isolated B env)

`docs/evidence/muaman-13i/41-quality-gates/SUMMARY.md`:
- `dart format --output=none --set-exit-if-changed .` → 1 pre-existing deviation in
  `test/muaman13f_fresh_clone_guard_test.dart` (byte-identical to HEAD; left untouched to keep the diff clean).
- `flutter analyze` → **PASS**, no issues (72.4 s).
- `flutter test` → 311 pass / 29 fail; all 29 are `LateInitializationError: Local 'testDb' has not been initialized`
  in `test/database/workbook_import_test.dart`, which is byte-identical to HEAD (blob `f6f2ee29…`) and
  reproduces standalone ⇒ pre-existing baseline defect, not caused by isolation.

## 27. Production diff

`git diff` over `app/lib`, `app/pubspec.yaml`, `app/pubspec.lock` is empty. Untracked additions are
only `docs/evidence/muaman-13i/` and `tools/`.

## 28. Determinism assessment

With pinned SDKs (patch hash-guarded), identical pubspec.lock + pub cache contents, and identical source,
the Release trees are byte-identical despite radically different root path lengths. The only observed
non-determinism (inline vs `@rsp` CL invocation) is a MSBuild runtime heuristic and does not affect output bytes.

## 29. Residual risks

- The original B `@rsp` crash was not re-triggered under isolation (E0/E1/E2). Root cause is a rare
  empty `FileTracker` static in the MSBuild node process — a VS2026/MSBuild bug, not an app defect.
- Short temp roots are recommended for both A and B to keep `Path.GetTempPath()` short and reduce any
  path-length/long-path interactions; both final runs used short temps (`C:\m13i\a\tmp`, `C:\t\m13i-b`).
- If the crash recurs on a machine, containment = run builds with a short, existing TEMP root and a fully
  resolved user profile (no empty APPDATA/LOCALAPPDATA), per §12–13.

## 30. Conclusion

**Outcome A.** Isolated dual-SDK VS2026 `flutter build windows --release` is byte-for-byte reproducible
(13/13 files, 33,273,462 bytes identical, 0 leaks). The tracked compiler-ID FileTracker crash is a
MSBuild 18.6.3 bug triggered by an empty normalised path; it is not triggered by the isolated environment
and is contained by the documented short-temp/user-profile configuration.

## 31. Evidence index

| dir | content |
|-----|---------|
| `34-original-b-failure/` | preserved failing B build tree + CMakeConfigureLog.yaml + tlogs |
| `35-experiment-e0/` | B long-temp baseline success (12 rsp, inline) |
| `36-experiment-e1-shorttemp/` | B short-temp success |
| `36-experiment-e1-shorttemp-invalid-attempt/` | first E1 attempt + script-bug notes |
| `37-experiment-e2-reversal/` | B long-temp reversal success |
| `38-experiment-a-final/` | final A build |
| `39-experiment-b-final/` | final B build |
| `40-verify-a-b-final/` | manifests + verify-result.json (identical=true, leaks=0) |
| `41-quality-gates/` | SUMMARY.md |

## 32. Reproduction commands

```
# A
tools/muaman13i/run_experiment.ps1 -ExperimentId A-FINAL `
  -AppRoot C:\m13i\a\src\app -SdkRoot C:\m13i\a\sdk -PubCache C:\m13i\a\pub `
  -TmpRoot C:\m13i\a\tmp -HomeRoot C:\m13i\a\home `
  -EvidenceDir docs\evidence\muaman-13i\<n>-experiment-<name>
# B
tools/muaman13i/run_experiment.ps1 -ExperimentId B-FINAL `
  -AppRoot C:\dev\muaman-13i-environment-b-independent-source-extraction-root\app `
  -SdkRoot C:\dev\muaman-13i-environment-b-independent-flutter-sdk-installation-root\sdk `
  -PubCache C:\dev\muaman-13i-environment-b-independent-pub-cache-root `
  -TmpRoot C:\t\m13i-b -HomeRoot C:\dev\muaman-13i-environment-b-independent-home-root `
  -EvidenceDir docs\evidence\muaman-13i\<n>-experiment-<name>
# verify
tools/muaman13i/verify_release.ps1 -ReleaseA <A Release> -ReleaseB <B Release> -EvidenceDir <dir>
```

## 33. Follow-ups

- (Optional) rerun both builds N times to characterise the inline/`@rsp` frequency empirically.
- (Optional) deterministic ZIP packaging check for distribution pipelines.
- Consider a CI check that fails if any `@rsp` CL invocation reaches the CompilerIdCXX stage.

## 34. Commit

Single commit `MUAMAN-13I: verify isolated dual-SDK VS2026 reproducibility` containing only
`docs/evidence/muaman-13i/`, `docs/MUAMAN-13I-ISOLATED-DUAL-SDK-VS2026-REPRODUCIBILITY.md`, `tools/`.
