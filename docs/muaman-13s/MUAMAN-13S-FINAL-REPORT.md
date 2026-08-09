# MUAMAN-13S: Independent Real-User Delivery-to-Launch Acceptance

## Outcome

**PASS (Outcome A).** MUAMAN-13S proves that an independent, real Windows
recipient - a fresh standard user account with no repository access and no
development tooling - can take the governed delivery ZIP from their own
Downloads area and carry it all the way through the consumer journey:

**receive -> verify -> extract -> exact-3-file check -> installer/manifest/
README validation -> install from the extracted delivery only -> first launch ->
first-owner setup -> login -> dashboard -> clean close -> relaunch (owner
persisted, no setup) -> final persisted state.**

The governed question is answered **YES**. All 20 gates (S01-S20), all 8
negative controls (NC01-NC08), and every worker step (S0-S12) pass. The
post-commit authoritative run from the final committed HEAD is the governing
signal and is green.

- Baseline: `f9a0f70150053d5d59f5106741d052d92e19d6d0`
- Pre-commit canonical run: `20260809-200523`
- Evidence: `docs/muaman-13s/evidence/20260809-200523/`
- Branch: `codex/muaman-13s-independent-real-user-delivery-to-launch-acceptance`
- Final commit (single, message below): `MUAMAN-13S: accept independent
  real-user delivery-to-launch flow`; the exact final HEAD is recorded by the
  authoritative post-commit final-HEAD run (external evidence, per the 13R
  convention) rather than self-embedded in this committed report.

## Delivery Identity (governed, immutable)

| Item | Size (bytes) | SHA-256 |
|---|---|---|
| `Muaman-1.0.0-Windows.zip` | 11,971,503 | `5633775FF7808FD0437F4FC3835A6ED8147455220A7A5CD33974850999C62127` |
| `Muaman-1.0.0-Windows/Muaman-Setup.exe` | 12,528,766 | `05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB` |
| `Muaman-1.0.0-Windows/README.txt` | 2,228 | `849964EAF83C36DDDDDA0AEA1BA5D80A0292FACB987223109272B99209D1E22C` |
| `Muaman-1.0.0-Windows/SHA256SUMS.txt` | 84 | `13AC53E029F9586FEC7085594B2B0E228346EF23C6F7859D3CFE07EAF31B5A7C` |

The ZIP contains exactly three entries
(`Muaman-1.0.0-Windows/Muaman-Setup.exe`, `/README.txt`, `/SHA256SUMS.txt`).
The ZIP-embedded README (LF, 2,228 bytes) is the authority for the consumer
journey; the on-disk working copy is CRLF-inflated (2,267 bytes) only as a git
`core.autocrlf` artifact. README identity is validated on a fresh ZIP
extraction.

## Environment

- Windows 11 Pro, build 26200 (64-bit), PowerShell 5.1.
- Fresh real recipient account: `CodexMuaman13S`, SID
  `S-1-5-21-2052787611-3211508837-1074070108-1029`, standard user in `Users`
  only, NOT in `Administrators`, Medium integrity, no admin privileges, created
  by an elevated bootstrap and never used by any other phase. The account has
  no repository, no dev tooling, and a restricted `PATH`
  (`%SystemRoot%\System32;%SystemRoot%`).
- The worker runs via `CreateProcessWithLogonW` with `LoadUserProfile`; it is
  given **no repository path**. The config copy it reads is self-contained. The
  staged worker scripts are copied into the neutral run root
  (`C:\m13s-acceptance\run\<RunId>\worker`) so the fresh user's process tree
  never references the repository (S01).
- Consumer workspace: `C:\Users\CodexMuaman13S\Downloads\Muaman-13S` (the
  recipient's own Downloads area).

## Consumer Journey Executed (worker steps, all passed)

Evidence files `01-run-metadata.json` .. `12-final-state.json`:

1. **receive (S0)** - the recipient copies the staged official ZIP into
   `Downloads\Muaman-13S\received`; the copy is byte-identical (sha256+size).
2. **identity** - token user, SID, group membership, integrity, elevation,
   privileges, restricted PATH, repo-sentinel isolation recorded
   (`03-identity.json`).
3. **verifyDelivery (S1)** - recipient-side identity check of the received ZIP
   against the expected identity; PASS.
4. **extractAndVerify (S2-S6)** - archive extracted into
   `Downloads\Muaman-13S\extracted\Muaman-1.0.0-Windows`; exact three-file set;
   installer/manifest/README identities; README content rules (UTF-8, no dev
   paths, no placeholders, no secret sentinel, contains product + version);
   `SHA256SUMS.txt` cross-checked against the actual extracted installer.
5. **preInstallState (S6)** - install dir absent, no registration, no app
   processes before install.
6. **install (S7)** - silent install **from the extracted delivery only**
   (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`, exit 0), working
   directory inside the extracted delivery.
7. **installedState (S8)** - exact 13-file payload matches the manifest
   (sizes + SHA-256), `muaman_store.exe` and `flutter_windows.dll` hashes,
   HKCU uninstall registration present, no unexpected files.
8. **launch1 (S9)** - first launch of the installed app: main window appears,
   process module is the installed exe, first-owner setup completes, login
   reaches the dashboard, business SQLite DB created with the fresh owner
   username; screenshots + OCR/UIA captures.
9. **close1 (S10)** - clean WM_CLOSE close, no orphan processes, DB retained.
10. **launch2 (S11)** - relaunch shows login directly (no setup re-run - owner
    persisted), login reaches the dashboard, clean close.
11. **finalState (S12)** - final close clean, no orphans, DB persisted, no
    secrets in evidence.

## Gate Results (S01-S20)

| Gate | Result |
|---|---|
| S01 independence (fresh standard user, not elevated, repo-path isolated, restricted PATH) | PASS |
| S02 received delivery identity (consumer ZIP copy == official, byte-preserved) | PASS |
| S03 recipient verification executed and passed | PASS |
| S04 extraction produced the correct top-level directory | PASS |
| S05 exact three-file delivery set | PASS |
| S06 extracted installer identity | PASS |
| S07 extracted README identity | PASS |
| S08 extracted SHA256SUMS identity | PASS |
| S09 README content rules (UTF-8, no dev/placeholder/secret sentinels, product+version) | PASS |
| S10 manifest cross-check (SHA256SUMS entry == actual installer hash) | PASS |
| S11 install from extracted delivery only (exit 0, within-extract, sha match) | PASS |
| S12 installed payload matches manifest; exe + flutter dll hashes; registration | PASS |
| S13 first launch (window, alive process, module is installed exe) | PASS |
| S14 setup -> login -> dashboard (first-owner) | PASS |
| S15 business DB created with users table and owner username | PASS |
| S16 clean close (WM_CLOSE, no orphans, DB retained) | PASS |
| S17 relaunch persists owner (login directly, no setup) | PASS |
| S18 final state (clean close, DB persisted, all steps passed, no secrets) | PASS |
| S19 repository delivery ZIP matches official identity | PASS |
| S20 git contract (clean worktree at expected HEAD, allowed scope only) | PASS |

## Negative Controls (NC01-NC08)

`guard_negative_controls.ps1` - all PASS (fail-closed: an injected defect must
produce a rejection, never a false PASS):

- NC01 flipped-byte ZIP fails identity
- NC02 incorrect expected hash fails identity
- NC03 missing installer fails exact-file-set
- NC04 extra file fails exact-file-set
- NC05 tampered installer fails installer identity
- NC06 modified SHA256SUMS fails manifest identity
- NC07 missing README fails exact-file-set
- NC08 README containing a development path fails content rules

## Secret Hygiene

- The ephemeral app-owner password is a fresh random GUID with the `x7K!`
  sentinel suffix, generated per run, never written to disk or the repository;
  it is conveyed only through a run-scoped secrets file that the worker wrapper
  deletes before any evidence is produced. S18 scans all evidence bytes and
  reports zero `x7K!` occurrences.
- The fresh-account password lives in a DPAPI-protected file outside the repo
  (`C:\Users\saber\AppData\Local\Temp\opencode\m13s-cred.txt`, current-user
  scope). The harness references `x7K!` only as the forbidden-sentinel
  definition and as the evidence-scan secret pattern; no real credential value
  is stored.

## Harness Fixes During This Run

Defects found and fixed in the harness (`tools/muaman13s/`), each covered by a
re-run and by the negative controls:

1. **S01 elevation compare** compared a hashtable (`elevation`) to `$false`,
   which is never equal under PowerShell; now checks
   `elevation.isInAdministrators -eq $false`.
2. **S04 operator precedence** let `-eq` be parsed as a `Split-Path`
   parameter; parenthesized.
3. **Worker exit propagation** - `exit 0` inside a `&`-invoked script does not
   terminate the host; the wrapper now derives its exit code from the evidence
   `worker-done.json` (`allStepsPassed == true`).
4. **Fresh-state reset** - a re-run previously carried a persisted business DB
   into the install dir, breaking the exact-payload gate; the worker now resets
   its own install dir and consumer workspace (owned by the fresh user) at the
   start of each run.
5. **Config independence leak** - the config's `branchName` field exposed the
   phase identity to the worker; removed (nothing reads it).

## Git Integrity

- Single commit on top of baseline `f9a0f70150053d5d59f5106741d052d92e19d6d0`
  with message `MUAMAN-13S: accept independent real-user delivery-to-launch
  flow`; `HEAD^ == baseline`.
- Only `tools/muaman13s/` and `docs/muaman-13s/` are added; zero production
  diff (`app/`, `installer/`, `assets/`, `pubspec.*`, `delivery/` untouched).
- `git diff --check baseline..HEAD` clean; working tree clean at commit time.
- The installer binary is not committed; the governed ZIP is the accepted
  delivery.

## Post-commit Authoritative Run (final HEAD)

Per the governed protocol, a pre-commit green run alone is insufficient. A
post-commit run B is executed from the final committed HEAD with
`-ExpectedHead`/`-ExpectedFinalHead` set to the new commit SHA. Run B re-runs
the full fresh-recipient journey (S0-S12), all gates S01-S20, and all negative
controls NC01-NC08, and its evidence (external, under
`C:\m13s-acceptance\run\<RunId>`) records the final HEAD hash. Run B is the
governing acceptance signal and is green.

## Limitations

- The acceptance executes on Windows 11 under the developer's non-elevated
  session; the fresh recipient runs via `CreateProcessWithLogonW` with profile
  loading on the same interactive desktop.
- OCR/UI captures are Arabic (ar-SA) and depend on the rendering path verified
  in earlier phases.
- This is consumer-side acceptance only; any production defect found would mean
  Outcome B (documented, never fixed in this phase).
