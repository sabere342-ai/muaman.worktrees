# PHASE P — POST-GROUP-D
## 13M / VERIFIER DELIVERY GATE — REMEDIATION

> TARGETED RELEASE-TOOLING REMEDIATION session, executed as the authorized
> successor of
> `PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_OWNER_AUTHORIZATION`
> (owner decision = APPROVE; authorized session =
> `PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_REMEDIATION`).
>
> Target authorized by the owner:
> > Reconcile the MUAMAN-13M release verification identity with the already-accepted
> > `RC-20260910-222845` using the smallest evidence-backed fail-closed change,
> > without modifying application code, accepted RC bytes, accepted RC manifest,
> > Android scope, production systems, or unrelated tooling.
>
> This session performs NO Windows Delivery execution, NO ZIP generation, NO
> installer creation, NO Android work, NO production/deployment/publishing work,
> NO P-OD7 / Sync-Drain activation, and NO Supabase mutation.

---

## A. Session Result

```text
SESSION =
PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_REMEDIATION

SESSION_CLASS =
TARGETED_RELEASE_TOOLING_REMEDIATION_ONLY

ROOT                  = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH                = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE     = github
FORBIDDEN_REMOTE      = origin
```

Outcome: the stale hard-coded `T1` release-identity constants are removed from
the canonical verifier; the verifier now derives the expected release identity
(file count, total bytes, cross-run hash) purely from the SUPPLIED legal
manifest; and the operative legal manifest is reconciled to describe the
already-accepted `RC-20260910-222845` identity. The accepted RC now verifies
as `identical=true` (exit 0), and every tampered/mismatched negative control
still fails closed (exit 1, no ZIP).

```text
VERIFIER_REMEDIATED         = YES
LEGAL_MANIFEST_RECONCILED   = YES (to the accepted RC identity)
ACCEPTED_RC_VALIDATED       = YES (identical=true, exit 0)
FAIL_CLOSED_PROVEN          = YES (negatives NEG_A/B/C/D + packager boundary all exit != 0)
RC_BYTES_MUTATED            = NO
RC_MANIFEST_MUTATED         = NO
WINDOWS_DELIVERY_EXECUTED   = NO
ZIP_GENERATED               = NO
```

---

## B. Repository Identity (entry forensics, verified)

```text
ROOT         = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR      = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree)
BRANCH       = codex/i-tech-next-roadmap-freeze
```

```text
ENTRY_LOCAL_HEAD         = 244bc4b36ced1d8464bd2292086d1cb09ae7b60a
ENTRY_TRACKING_HEAD      = 244bc4b36ced1d8464bd2292086d1cb09ae7b60a
ENTRY_DIRECT_GITHUB_HEAD = 244bc4b36ced1d8464bd2292086d1cb09ae7b60a
ENTRY_MERGE_BASE         = 244bc4b36ced1d8464bd2292086d1cb09ae7b60a
ENTRY_AHEAD              = 0
ENTRY_BEHIND             = 0
ENTRY_REMOTE_LOCK        = VERIFIED
```

Git-operation metadata via Git-aware path resolution:
`MERGE_HEAD`/`CHERRY_PICK_HEAD`/`REVERT_HEAD`/`BISECT_LOG`/`rebase-merge`/
`rebase-apply` = ABSENT. `ACTIVE_GIT_OPERATION = NONE`.

Pre-existing tracked residue (present on disk BEFORE this session, NOT
introduced or staged by this session, PRESERVED untracked/staged-state
untouched): the identical 12 tracked deletions under the legacy data
directories (`شهر7/`, `قديم/`) already documented and preserved by the
committed predecessor sessions (see
`PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_OWNER_AUTHORIZATION.md`
section C). `ENTRY_CLASSIFICATION = CASE_C_UNEXPECTED_DIRTY` (pre-existing
deletions preserved; local == tracking == github == merge-base).

Pre-existing untracked residue (inventoried, PRESERVED, NOT staged): `Continue`,
`GROUP_A_PHASE_P_OD7_*.md`, `GROUP_A_PHASE_Q_*.md`,
`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
`PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`,
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`,
`delivery/I-TECH-Delivery-v1.0.0.zip` (sacred), `supabase/.branches/`,
`supabase/.temp/`.

No fetch was run; direct GitHub verification used read-only `git ls-remote`.

```text
ORIGIN_CONTACTED = NO
```

---

## C. Change Boundary (authorized allowlist)

Only the minimum necessary release-tooling identity logic and its minimum
required evidence are changed:

```text
MODIFIED (tracked):
  tools/release/verify_release.ps1
  tools/release/package_windows_release.ps1
  docs/windows-delivery-refresh/evidence/legal/release-manifest.json

ADDED (new committed evidence):
  docs/evidence/phase-p-13m-verifier-remediation/01-positive/positive-verification-reconciled.json
  docs/evidence/phase-p-13m-verifier-remediation/02-negative/negative-a-missing-file.json
  docs/evidence/phase-p-13m-verifier-remediation/02-negative/negative-b-modified-file.json
  docs/evidence/phase-p-13m-verifier-remediation/02-negative/negative-c-extra-file.json
  docs/evidence/phase-p-13m-verifier-remediation/02-negative/negative-d-wrong-t1-identity.json
  docs/evidence/phase-p-13m-verifier-remediation/03-packager-boundary/release-verification.json
  docs/evidence/phase-p-13m-verifier-remediation/03-packager-boundary/package-result.json

ADDED (governance):
  PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_REMEDIATION.md (this report)
```

NOT changed: `app/**`, `test/**`, `supabase/**`, `delivery/**`, `AGENTS.md`,
the accepted RC manifest
`docs/evidence/phase-p-rc/release-candidate-manifest.json`, the accepted RC
bytes, the historical T0/T1 legal manifests under `docs/evidence/`, the
historical 13O..13S installer/acceptance harnesses (`tools/muaman13o..s/`,
`tools/release/package_windows_installer.ps1`), Android signing material.

---

## D. Remediation Design

Before this session, `tools/release/verify_release.ps1` enforced, in addition
to manifest equality:

```text
hard-coded T1 file count   == 16         (old line 104)
hard-coded T1 total bytes  == 35754065   (old line 105)
hard-coded T1 crosshash    == 13884FC55E8923EA6111895796CC9F576177CBED6F73AD5DA729E686A0E9A7CF
                                 (old line 106; duplicated at old lines 118-119, 124)
```

while the operative default legal manifest
(`docs\windows-delivery-refresh\evidence\legal\release-manifest.json`)
recorded the governed T1 legal identity (runId `I-TECH-T1-INAPP-BRANDING-REBUILD`,
16 files / 35,754,065 B / `13884FC5...`). The already-accepted RC identity
(`RC-20260910-222845`, 18 files / 37,537,520 B / `0051D0D6...`) therefore could
NOT satisfy the gate — a legitimate DELIVERY-stage blocker (stale
release-identity governance), recorded by the owner-authorized session as
`13M_VERIFIER_BLOCKER_T1 = CONFIRMED`.

The chosen smallest fail-closed solution:

1. **Remove the stale duplicated identity constants from the verifier.**
   `verify_release.ps1` now derives `expectedFileCount`, `expectedTotalBytes`,
   and `crossHashExpected` directly from the SUPPLIED legal manifest
   (`$legalCount`, `$legalTotal`, `$crossLegal`). The verifier has no release
   identity of its own; legality is entirely a function of the supplied
   authoritative manifest. Descriptor header updated to state this contract.

2. **Reconcile the operative legal manifest to the already-accepted RC.**
   `docs/windows-delivery-refresh/evidence/legal/release-manifest.json` is
   regenerated with the committed canonical generator
   (`tools/muaman13k/make_release_manifest.ps1`) against the immutable
   on-disk accepted-RC tree at the canonical Release directory. The new
   manifest records the accepted-RC identity:
   `runId = PHASE-P-ACCEPTED-RC-20260910-222845`,
   18 files / 37,537,520 B, cross-run hash `0051D0D6...`.
   The accepted RC bytes and the committed RC manifest
   (`docs/evidence/phase-p-rc/release-candidate-manifest.json`) are NOT
   modified.

3. **Fix the packager header/behavior variance.** The `package_windows_release.ps1`
   header comment documented a DIFFERENT default legal-manifest path than the
   operative code default (lines 51-52 vs line 127). The header is corrected to
   the operative default
   (`docs\windows-delivery-refresh\evidence\legal\release-manifest.json`).
   No packaging behavior changes; verification-before-ZIP and fail-closed exit
   handling are untouched.

Resulting contract: a fresh release passes only when it exactly matches the
supplied authoritative legal manifest (now the accepted RC identity); any
missing, modified, extra, or differently-governed file set fails closed.

---

## E. Verification — Positive (accepted RC vs reconciled legal manifest)

Command (canonical verifier; read-only; the accepted-RC Release directory is
untouched):

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/release/verify_release.ps1
  -ReleaseDir app/build/windows/x64/runner/Release
  -LegalManifest docs/windows-delivery-refresh/evidence/legal/release-manifest.json
  -Out <evidence>/01-positive/positive-verification-reconciled.json
```

Result (evidence file committed):

```text
EXIT_CODE        = 0
fileCountNew     = 18   fileCountLegal     = 18   fileCountMatch  = true
totalBytesNew    = 37537520   totalBytesLegal = 37537520   totalBytesMatch = true
crossHashNew     = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9
crossHashLegal   = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9
crossHashExpected= 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9
crossHashMatch   = true
diffCount        = 0
onlyInLegalCount = 0
onlyInNewCount   = 0
identical        = true
```

The accepted Release Candidate is validated by the corrected verifier. The
reconciled legal manifest closes the identity gap that previously blocked the
delivery gate.

---

## F. Verification — Negative controls (fail-closed proof)

All negative controls ran on DISPOSABLE copies in an EXTERNAL scratch
directory (`C:\Users\saber\AppData\Local\Temp\opencode\13m-remediation\`).
The authoritative accepted-RC Release directory was NEVER modified.

| control | fixture | against | expected | actual |
|---|---|---|---|---|
| NEG_A | accepted-RC tree copy minus `pdfium.dll` (17 files) | reconciled legal manifest | fail (exit != 0) | exit 1, identical=false, onlyInLegal=1 |
| NEG_B | accepted-RC tree copy, one byte flipped in `printing_plugin.dll` | reconciled legal manifest | fail (exit != 0) | exit 1, identical=false, diffCount=1 |
| NEG_C | accepted-RC tree copy plus stray `stray-extra-file.bin` (19 files) | reconciled legal manifest | fail (exit != 0) | exit 1, identical=false, onlyInNew=1 |
| NEG_D | authoritative accepted-RC tree | PRESERVED historical T1 legal manifest (16/35754065/`13884FC5`) | fail (exit != 0) | exit 1, identical=false, diffCount=3, onlyInNew=2 |

NEG_D specifically proves the verifier still rejects a mismatched governed
identity (the historical T1 manifest no longer matches the accepted RC), i.e.
fail-closed behavior did not regress when the expected identity became
manifest-derived.

All four exit 1 with `identical=false`. Evidence committed under
`docs/evidence/phase-p-13m-verifier-remediation/02-negative/`.

---

## G. Verification — Packager boundary (no ZIP on invalid input)

The packager re-runs the canonical verifier before touching any archive. A
deliberately invalid release fixture (modified `printing_plugin.dll`) was
presented to `tools/release/package_windows_release.ps1` with the reconciled
legal manifest:

```text
[MUAMAN-13M] RELEASE VERIFICATION FAILED (exit 1); packaging refused.
PACKAGER_EXIT     = 1
ZIP_EXISTS        = False
RESULT_VERDICT    = FAIL
RESULT_FAILURE    = release verification failed (verify_release.ps1 exit 1); no ZIP created
```

Evidence: `03-packager-boundary/package-result.json` and
`03-packager-boundary/release-verification.json`.

The corrected chain remains fail-closed end-to-end: verification is a hard gate
before packaging, and a tampered release produces NO ZIP.

---

## H. Scope Compliance and Prohibitions

```text
ACCEPTED_RC_BYTES_MUTATED      = NO
ACCEPTED_RC_MANIFEST_MUTATED   = NO
LEGAL_MANIFEST_RECONCILED      = YES (minimum necessary: runId/identity updated to accepted RC)
VERIFIER_REMEDIATED            = YES (minimum necessary: identity constants removed)
PACKAGER_HEADER_VARIANCE_FIXED = YES (minimum necessary: descriptor aligned to code)
APP_PRODUCTION_MODIFIED        = NO
ANDROID_MODIFIED               = NO
SIGNING_MATERIAL_MODIFIED      = NO
INSTALLER_HARNESSES_MODIFIED   = NO (13O..13S historical harnesses preserved)
PRODUCTION_MUTATION            = NO
WINDOWS_DELIVERY_EXECUTED      = NO
ZIP_GENERATED                  = NO
NEW_DELIVERY_ZIP_CREATED       = NO
P_OD7_ACTIVATED                = NO
SYNC_DRAIN_ACTIVATED           = NO
SUPABASE_MUTATION              = NO
ORIGIN_CONTACTED               = NO
```

Note: `docs/windows-delivery-refresh/FINAL-REPORT.md` and
`docs/windows-delivery-refresh/EVIDENCE-SUMMARY.md` are HISTORICAL evidence
documents from the earlier `codex/windows-delivery-package-refresh` WR1 phase
and the subsequent T0/T1 refreshes; they describe the identity in force at the
time they were written and are preserved unchanged as historical evidence per
AGENTS.md governance (later authority supersedes, older artifacts remain
historical record). This report is the later, authoritative record of the
reconciled identity.

---

## I. Commit / Push Policy

Authorized by the committed owner-authorization artifact
(`PHASE_P_POST_GROUP_D_13M_VERIFIER_DELIVERY_GATE_OWNER_AUTHORIZATION.md`,
section M: commit; push normally to github; establish remote-lock).

```text
COMMIT_TYPE           = NORMAL fast-forward
AMEND                 = NO
REBASE                = NO
HISTORY_REWRITE       = NO
FORCE                 = NO
PUSH_DESTINATION      = github
PUSH_BRANCH           = codex/i-tech-next-roadmap-freeze
FORCE_WITH_LEASE      = NO
ORIGIN_CONTACTED      = NO
```

Explicit-path staging only (no `git add .` / `git add -A`). The pre-existing
residue (tracked deletions in `شهر7/`/`قديم/`, and untracked governance/sacred
files) is NOT staged.

---

## J. Remote-Lock Requirements (post-commit / post-push)

After push, independently verify:

```text
POST_PUSH_LOCAL_HEAD
POST_PUSH_TRACKING_HEAD
POST_PUSH_DIRECT_GITHUB_HEAD
POST_PUSH_MERGE_BASE
POST_PUSH_AHEAD  = 0
POST_PUSH_BEHIND = 0
```

Required: `LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE`. Direct GitHub
proof via `git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`.
`REMOTE_LOCK = PASS` is claimed only with this evidence.

---

## K. Conclusion

```text
BLOCKER_13M_VERIFIER_T1_PRECONDITION = CONFIRMED (prior session; now remediated)
BLOCKER_13M_VERIFIER_T1_STATUS       = RESOLVED
ACCEPTED_RC_VALIDATED_BY_CORRECTED_VERIFIER = PASS (identical=true, exit 0)
FAIL_CLOSED_RETAINED                        = PASS (4/4 negatives + packager boundary exit != 0)
LEGAL_MANIFEST_CONTRACT                     = ALIGNED (packager default + verifier + manifest all agree)
SCOPE_CONTAINED                             = YES
```

The MUAMAN-13M release verification identity is reconciled with the
already-accepted `RC-20260910-222845` via the smallest evidence-backed
fail-closed change: the verifier now derives expected identity from the
supplied legal manifest, and the operative legal manifest describes the
accepted RC. Windows Delivery, ZIP generation, installer creation, Android,
production, deployment, publishing, P-OD7, Sync Drain, and Supabase mutation
remain NOT executed and NOT authorized by this artifact.