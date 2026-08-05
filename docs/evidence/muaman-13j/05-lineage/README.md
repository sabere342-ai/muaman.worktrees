# MUAMAN-13J evidence lineage

This document records the provenance chain of every artifact used to prove the
root cause and the mitigation of the MSBuild FileTracker empty-static crash.

## 1. Inherited from MUAMAN-13I (baseline `48493512`)

All 13I artifacts are preserved in the 13I worktree
`C:\dev\muaman.worktrees\muaman-13i-deterministic-official-sdk-patch-provenance`
under `docs\evidence\muaman-13i\`:

- `34-original-b-failure/` — the original crashing build tree: `CMakeConfigureLog.yaml`
  (4 identical MSB4018 crashes at 2026-08-04 23:40:14/15 and 23:41:11/12),
  `CompilerIdCXX.vcxproj`, `CMakeCXXCompilerId.cpp`, `CMakeCXXCompilerId.obj`,
  `CompilerIdCXX.tlog\CL.read.1.tlog`, `CL.write.1.tlog`, `unsuccessfulbuild`.
- `35-experiment-e0/`, `36-experiment-e1-shorttemp/`, `37-experiment-e2-reversal/`,
  `38-experiment-a-final/`, `39-experiment-b-final/` — all successful builds.
- `40-verify-a-b-final/` — byte-for-byte identity (13 files, 33,273,462 bytes, 0 leaks).
- `41-quality-gates/` — baseline gate signatures.

13I concluded (report section 12-13) that the crash requires a FileTracker
static resolving to `""` in the crashing MSBuild process and could not be
reproduced under the isolated environment.

## 2. New evidence produced by MUAMAN-13J (this commit)

All under `docs\evidence\muaman-13j\`:

| dir | artifact | producer | purpose |
|-----|----------|----------|---------|
| `01-reproduction-r1-b-long/` | `05-analysis.json` etc. | 13J run via `tools\muaman13i\run_experiment.ps1` | Reproduction attempt of the original B long-temp config (exit 0, no crash). |
| `02-reproduction-r2-b-short/` | same | 13J run | B short-temp reproduction (exit 0, no crash). |
| `03-reproduction-r3-a-short/` | same | 13J run | A short-temp reproduction (exit 0, no crash). |
| `04-verify-r3a-r2b/` | `verify-result.json` | `tools\muaman13i\verify_release.ps1` | Byte-for-byte A-vs-B identity of the matrix releases. |
| `05-lineage/` | this file | 13J | Provenance chain. |
| `06-hardened-h1-b-short/` | `00-hardened-env.json`, `01-preflight.log`, `05-analysis.json` | `tools\muaman13j\build_hardened.ps1` + `check_filetracker_state.ps1` | First hardened build (exit 0, no crash). |
| `07-verify-r3a-h1b/` | `verify-result.json` | `verify_release.ps1` | Hardened B payload byte-identical to A. |
| `08-quality-gates/` | `SUMMARY.md`, `01-format.log`, `02-analyze.log`, `03-test.log` | 13J gate runs | Baseline-identical gate signatures. |
| `09-root-cause-probes/` | `01-empty-static-probe.log`, `empty_static_probe.cs`, `02-getfolderpath-probe.log`, `getfolderpath_probe.cs`, `03-probe13j-full.log` | 13J probes | Empirical proof of the crash mechanism and of the producer constraints. |

## 3. Scratch artifacts (outside the repo, in `C:\Users\saber\AppData\Local\Temp\opencode\`)

Intermediate diagnostics used to build the probes above:
`empty_static_probe.cs/.exe/.log`, `getfolderpath_probe.cs/.exe/.log`,
`probe13j_main.cs/.exe/.log`, `dumpil.ps1`, `dumpil2.ps1`, `inspect_type.ps1`,
`resolve_tokens.ps1`, `resolve_memberrefs.ps1`, `tracker_probe.cs`, `repro_test.ps1`.

## 4. Integrity

- Repo state entered clean at HEAD `48493512a05e47ff75de1d49cd5434d8844ded5a`
  (`rev-list --count 48493512..HEAD` = 0 before 13J work).
- No production file (`app\lib`, `app\pubspec.yaml`, `app\pubspec.lock`) was touched.
- All builds used separate physical roots; no output was copied between A and B;
  byte-for-byte verification compares live Release trees produced by independent runs.
