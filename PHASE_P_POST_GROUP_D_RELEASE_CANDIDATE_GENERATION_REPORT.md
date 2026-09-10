# PHASE_P_POST_GROUP_D_RELEASE_CANDIDATE_GENERATION_REPORT

Session: `PHASE_P_POST_GROUP_D_RELEASE_CANDIDATE_GENERATION` (Windows)

## 1. Scope and Authorization

Authorized workstream: prepare a **Windows release candidate** for the post-Group-D
Phase P release pipeline, as selected by the binding owner decision in the binding
predecessor commit.

- Binding predecessor commit: `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3`
  (`docs: select successor after post-group-d full test gate rerun`, parent
  `31818d9704ee7a7c6a64d2f4a43f634b195f6bab`).
- Repository: `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze`
- Branch: `codex/i-tech-next-roadmap-freeze`
- Authorized remote: `github` only. Remote `origin` MUST NEVER be contacted.
- Downstream stage NOT authorized in this session: Manual Acceptance, Final
  Closeout, Delivery, Production, P-OD7 sync-drain activation, WS-10 reopen,
  Android/AAB/APK signing.

## 2. Entry Classification and Repository Forensics

Classification: `CASE_A_FRESH`.

| Field | Value | Status |
|---|---|---|
| local HEAD | `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3` | VERIFIED |
| tracking HEAD | `github/codex/i-tech-next-roadmap-freeze` = `f6c6c51...` | VERIFIED |
| direct GitHub HEAD | `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3` | VERIFIED (`git ls-remote github`) |
| merge-base | `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3` | VERIFIED |
| ahead / behind | 0 / 0 | VERIFIED |
| tracked worktree | clean | VERIFIED |
| index | clean | VERIFIED |
| active git operation | none (MERGE/CHERRY_PICK/REVERT/BISECT/rebase all absent) | VERIFIED |
| stash | `stash@{0}` pre-existing, preserved | VERIFIED |

Pre-existing untracked residue was inventoried and **preserved untouched** (never
staged, never deleted):

- `Continue`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md`
- `GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md`
- `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`
- `PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`
- `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`
- `delivery/I-TECH-Delivery-v1.0.0.zip` (sacred artifact)
- `supabase/.branches/` (`_current_branch`)
- `supabase/.temp/` (never read; contains start-secrets)

## 3. Owner Decisions Recorded This Session

1. **RC deliverable shape** (owner-selected, `2026-09-11` session): build the
   Windows Release fresh from `f6c6c51` and capture a **NEW candidate manifest**.
2. **Packaging** (owner-selected): deterministic ZIP and installer are **deferred**.
   The canonical packager `tools/release/package_windows_release.ps1` (and its
   verifier `tools/release/verify_release.ps1`, lines 104–106) is hardwired to the
   governed T1 legal identity (16 files / 35,754,065 B / crosshash
   `13884FC5...`) and fail-closes on any fresh identity. Producing a ZIP/installer
   would require a legal-manifest swap, which belongs to the downstage Manual
   Acceptance decision — not this session.

## 4. Build Execution (canonical entrypoint)

Command (canonical 13L interface):

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  tools\release\build_windows_release.ps1 `
  -SdkRoot "C:\src\flutter" `
  -PubCache "<LOCALAPPDATA>\Pub\Cache" `
  -MsBuildBinDir "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64" `
  -StageRoot "C:\Users\saber\AppData\Local\Temp\opencode\rc-stage" `
  -ExperimentId "RC-20260910-222845"
```

| Field | Value | Status |
|---|---|---|
| run id | `RC-20260910-222845` | VERIFIED |
| started / ended (UTC) | `2026-09-10T22:28:46.225Z` / `2026-09-10T22:30:56.053Z` | VERIFIED |
| duration | 129.8 s | VERIFIED |
| entrypoint preflight exit | 0 | VERIFIED |
| hardened preflight exit | 0 | VERIFIED |
| clean / pub get / build exit | 0 / 0 / 0 | VERIFIED |
| release produced | `app\build\windows\x64\runner\Release\muaman_store.exe` exists | VERIFIED |

Toolchain (VERIFIED):

- Flutter 3.24.5 stable (revision `dec2ee5c1f98f8e84a7d5380c05eb8a3d0a81668`), Dart 3.5.4.
- SDK root `C:\src\flutter`; patched `packages/flutter_tools/lib/src/windows/visual_studio.dart`
  SHA-256 `D08E9D71E978FDE1478FBF438DCEA6D16D26EA966D271F7D5108AC86E3CC5423`
  (matches committed 13K patch token).
- `flutter_tools.snapshot` SHA-256 `2AE8801499892ED5212F42E9463724F5FD4B636EE2486D5DACEF42759244860A`.
- `app/pubspec.lock` SHA-256 `3AFE4F722CDE8217C5042510A8A2E1610AD4DC42A0CA4FE8E305590F17CD26BB`
  (unchanged by the build; `pub get` did not mutate it).
- MSBuild: `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin\amd64`.
- PUB_CACHE: `<LOCALAPPDATA>\Pub\Cache`.

Stage evidence (not committed, preserved on temp):
`C:\Users\saber\AppData\Local\Temp\opencode\rc-stage\evidence`
(`build-result.json`, `00-pre.json`, `02-pubget.log`, `03-build.log`,
`05-analysis.json`, preflight logs, `rsp-capture/`).

## 5. Release Candidate Identity (NEW identity)

Source commit: `f6c6c510dcb1a5c5dbe7fa8593ff88e478834ad3`.

| Field | Value |
|---|---|
| file count | 18 |
| total bytes | 37,537,520 |
| cross-run hash | `0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9` |
| main executable | `muaman_store.exe` — 92,672 B, SHA-256 `0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7` |

Committed candidate manifest:
`docs/evidence/phase-p-rc/release-candidate-manifest.json` (run id
`PHASE-P-RELEASE-CANDIDATE-1`, generated by `tools/muaman13k/make_release_manifest.ps1`).

## 6. Verification Evidence

### 6.1 Fresh Release vs governed legal identity (expected non-identical)

Command: `verify_release.ps1 -ReleaseDir <fresh> -LegalManifest docs\windows-delivery-refresh\evidence\legal\release-manifest.json`.

Result (committed `verify-fresh-vs-governed-t1.json`): `identical=false`, exit 1
(**expected** fail-closed against the governed T1 identity; the fresh build is a
deliberately different identity and is NOT claimed to byte-match T1).

- `diffCount = 3`
  1. `data/app.so` — 9,290,656 → 10,814,368 B (kernel/bytecode changed)
  2. `data/flutter_assets/NOTICES.Z` — 89,413 → 102,372 B (dependency notices changed)
  3. `muaman_store.exe` — 92,160 → 92,672 B
- `onlyInNew = 2`: `app_links_plugin.dll`, `url_launcher_windows_plugin.dll`
  (native plugin registration present in the current source tree)
- `onlyInLegal = 0`

Classification: EXPECTED new-identity deviation caused by authorized source work
between the governed T1 commit and `f6c6c51`.

### 6.2 Fresh Release vs candidate manifest (integrity of the candidate)

Command: `verify_release.ps1 -ReleaseDir <fresh> -LegalManifest docs\evidence\phase-p-rc\release-candidate-manifest.json`.

Result (committed `verify-fresh-vs-candidate.json`): `identical=false`, exit 1,
**but** `diffCount=0`, `onlyInLegal=0`, `onlyInNew=0`. The only non-matching
fields (`fileCountMatch`, `totalBytesMatch`, `crossHashMatch`) are false solely
because `verify_release.ps1` hardcodes the T1 constants (16 / 35,754,065 /
`13884FC5...`), which a fresh identity cannot satisfy.

Classification: candidate manifest **faithfully describes the fresh Release
directory** (file set, sizes, per-file SHA-256). Cross-run hash matches the
candidate identity above.

## 7. Packaging Status

- Deterministic ZIP: **NOT PRODUCED** (owner decision, Section 3). Canonical 13M
  packager is governed-identity-locked and fails closed on fresh identity.
- Installer: **NOT PRODUCED** (same reason; no ISCC toolchain present either).
- Not an acceptance substitute: the RC is a candidate awaiting the separate
  Manual Acceptance stage.

## 8. Repository Preservation

- No tracked file modified by this session (post-build `git status`/`git diff`
  verified clean; `app/pubspec.lock` unchanged).
- Build output `app/build/` is git-ignored (`app/.gitignore` line 32).
- All pre-existing untracked residue preserved.

## 9. Guard Sheet

| Guard | Value |
|---|---|
| ORIGIN_CONTACTED | NO |
| WS_10_REOPENED | NO |
| P_OD7_ACTIVATED | NO |
| SYNC_DRAIN_ACTIVATED | NO |
| MANUAL_ACCEPTANCE_STARTED | NO |
| FINAL_CLOSURE_STARTED | NO |
| DELIVERY_STARTED | NO |
| PRODUCTION_STARTED | NO |
| Android signing / AAB / APK / keystore activity | NO |
| GoGIT fetch/fetch-all executed | NO (only `ls-remote github` + `git fetch`-free reads) |
| Production mutation | NO |
| Secret exposure | NO |

## 10. Session Result

Session state: `RC_GENERATED_READY_FOR_SEPARATE_MANUAL_ACCEPTANCE`.

This is a release **candidate**, not an acceptance. Manual Acceptance is a
separate, explicitly authorized session and is NOT started here.

STOP — RELEASE CANDIDATE GENERATION SESSION COMPLETE; DOWNSTREAM STAGES NOT
STARTED.