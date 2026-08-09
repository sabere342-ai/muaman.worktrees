# MUAMAN-13Q: Independent Fresh-User Uninstall and Reinstall Acceptance

## Outcome

**PASS.** MUAMAN-13Q verifies that a single frozen Windows installer, run for an
independent fresh standard user, supports the full lifecycle **install -> first
launch -> official registered uninstall -> post-uninstall validation ->
reinstall of identical bytes -> second launch**. All 18 gates (Q1-Q18) pass.

- Baseline: `2021140` (`20211407d033c68a9ce28201f4bdca254056d178`)
- Canonical run: `20260809-150945`
- Evidence: `docs/muaman-13q/evidence/20260809-150945/`
- Branch: `codex/muaman-13q-independent-fresh-user-uninstall-reinstall-acceptance`

## Installer Identity (frozen, unchanged from 13O/13P)

| Property | Value |
|---|---|
| File | `muaman-windows-installer.exe` |
| SHA-256 | `05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB` |
| Size (bytes) | 12,528,766 |

The same bytes were used for the first install and the reinstall (Q16: identical
provenance). The installer binary is sourced from the 13O inbound artifact and is
not committed to the repository.

## Environment

- Windows 11 Pro, build 26200 (64-bit), PowerShell 5.1.
- Fresh account: `CodexMuaman13Q`, SID
  `S-1-5-21-2052787611-3211508837-1074070108-1028`, standard user (no admin
  privileges, Medium integrity), independent of the 13P account.
- The fresh account is created/checked by the orchestrator; no profile,
  registry, or credential reuse between runs or accounts.

## Lifecycle Executed (worker steps, all passed)

1. **identity** — token user name, SID, group membership, integrity, elevation,
   privilege summary recorded (`04-user-identity.json`).
2. **prestate** — OS/user/env capture, install dir absent, no exe, no HKCU
   registration, no app/uninstaller processes, OS account-picture placeholder
   present (`05-preinstall-state.json`).
3. **install1** — silent install of the frozen installer (exit 0), app exe
   present, installer SHA verified (`06`/`07`).
4. **installedState** — HKCU uninstall registration present, full 13-file
   payload matches 13K manifest (sizes + SHA-256), no unexpected files, Start
   Menu shortcut user-scope only, no HKLM registration (`08`).
5. **launch1** — app launched: setup -> login -> dashboard; business SQLite DB
   created with the fresh owner username; screenshots + OCR/UI captures
   (`09-first-launch-*`).
6. **close1** — WM_CLOSE, app exited, no orphan processes, DB still present.
7. **preUninstallSnapshot** / **uninstallDiscovery** — pre-uninstall file/registry
   snapshot; official registered uninstaller located via `UninstallString`,
   inside install root (`10`/`11`).
8. **uninstall** — ran the registered `unins000.exe` silently (exit 0);
   registration removed, installed exe removed, uninstaller removed, no
   app/uninstaller processes (`12`).
9. **postUninstallState** — no payload files, no Inno uninstaller extras, no
   Start Menu link, no processes, DB retained (`13`).
10. **leftoverClassification** — the only install-root survivor is the business
    DB, classified `expected-retained-user-data`; no unknown leftovers in
    ProgramData, LocalAppData/AppData deltas, or HKLM; the OS account-picture
    placeholder is classified as `os-account-picture-placeholder`
    (`14`).
11. **reinstall** — silent reinstall of the identical installer bytes (exit 0),
    app exe present, SHA verified (`15`).
12. **reinstalledState** — HKCU registration present exactly once, no duplicate
    registrations/roots, full payload matches again, DB retained across
    uninstall/reinstall (`16`).
13. **launch2** — second launch after reinstall: login -> dashboard, DB retained,
    clean close, screenshots (`17-*`).
14. **finalState** — app running after second launch, DB present, single
    registration (`20-final-state.json`).

## Gate Results (Q1-Q18)

| Gate | Result |
|---|---|
| Q1 baseline integrity (HEAD == `2021140`, scope clean) | PASS |
| Q2 frozen installer identity (SHA + size) | PASS |
| Q3 fresh independent standard user (SID, groups, no admin) | PASS |
| Q4 clean pre-install state (no dir/exe/registration/processes) | PASS |
| Q5 first silent install (exit 0, exe present, SHA match) | PASS |
| Q6 installed-state integrity (registration, payload, shortcuts) | PASS |
| Q7 first launch (setup->login->dashboard, DB + owner, clean close) | PASS |
| Q8 official uninstaller discovery (registered, in install root) | PASS |
| Q9 official uninstall via registered UninstallString (exit 0, all removed) | PASS |
| Q10 post-uninstall registration removed, no processes | PASS |
| Q11 installer-owned files removed (exe, payload, unins extras, shortcut) | PASS |
| Q12 leftover classification clean (only retained DB + OS placeholder) | PASS |
| Q13 reinstall of same bytes (exit 0, exe present, SHA match) | PASS |
| Q14 reinstalled-state integrity (single registration, payload, DB retained) | PASS |
| Q15 second launch after reinstall (login->dashboard, clean close) | PASS |
| Q16 same installer provenance for both installs | PASS |
| Q17 secret hygiene (no secret leaks in evidence/run root, secrets file removed) | PASS |
| Q18 repository integrity at gate time (scope clean, no prod diff) | PASS |

## Known False Positive Handled

- The OS account-picture placeholder `C:\ProgramData\Microsoft\User Account
  Pictures\CodexMuaman13Q.dat` (and the 13P account's equivalent) is an OS
  artifact, not an installer leftover. The leftover scan excludes only exact
  `<account>.dat` placeholder paths for real local accounts; any other
  muaman-named file (including one adjacent to the placeholder) still fails the
  gate (negative control NC09).

## Leftover Classification

After the official uninstall the only item remaining under the install root is:

- `.dart_tool/sqflite_common_ffi/databases/muaman_store.db` (94,208 bytes) —
  the business SQLite database, **expected retained user data** (the installer
  preserves user data and only removes the app directory when empty). It is
  retained across uninstall and carried into the reinstall (Q14/Q15 confirm the
  DB survives).

The Inno uninstaller itself removes the executable, all 13 payload files,
`unins000.{exe,dat,msg,shl}`, the HKCU registration, and the Start Menu
shortcut. ProgramData and AppData deltas show only informational temp churn.

## Negative Controls

`guard_negative_controls.ps1` — all PASS (re-verified after final changes):

- NC01 baseline green
- NC02 missing evidence fails the gate
- NC03 bad installer SHA fails the gate
- NC04 duplicate registration fails the gate
- NC05 secret sentinel fails the gate
- NC06 missing `worker-done.json` detected
- NC07 unknown installer leftover fails the gate
- NC08 incomplete post-uninstall scan fails the gate
- NC09 account-picture precision (muaman-named file near placeholder fails)
- NC10 malformed key scan safe

## Secret Hygiene

- No plaintext secrets are committed. The fresh-account password lives in a
  DPAPI-protected file (`m13q-cred.txt`, current-user scope, outside the repo)
  and is exported to run-scoped environment variables only inside the worker
  wrapper, then the secrets file is deleted. Q17 scans evidence + run root and
  reports zero leaks.

## Harness Reliability Fixes During This Run

Four strict-mode/robustness defects were found and fixed in the harness
(`tools/muaman13q/`):

1. `Get-HkcuUninstallMuamanKeys` catch path `return @()` collapsed to `$null`
   under `Set-StrictMode`, breaking `.Count` on a fresh user with no HKCU
   Uninstall root; fixed with `return ,@()`.
2. DB file lock during first launch: the app holds its SQLite file open for its
   lifetime; `Get-DbFacts` now reads via a shared read/write helper with bounded
   retries instead of `ReadAllBytes`/`Get-FileHash`.
3. Process-id helpers (`Get-MuamanProcessIds`, `Get-UninstallerProcessIds`)
   returned `$null`/scalar for zero/one processes, breaking `.Count` under
   strict mode; fixed to return arrays; a double-wrap in the uninstall
   `processes-gone` poll was removed so the empty-array result is evaluated
   correctly.
4. `Diff-DirListings` accessed `.sha256` on listing entries captured without
   hashes; made the hash comparison strict-mode-safe.

These fixes are covered by the re-run of all 10 negative controls (all green).

## Git Integrity

- Single commit intended on top of `2021140`; only `tools/muaman13q/` and
  `docs/muaman-13q/` are added; no production files changed (Q1/Q18 enforced by
  the harness preflight and gates).
- The installer binary and failed-run evidence directories are not committed.

## Limitations

- The acceptance is executed in a Windows 11 VM-like environment under the
  developer's non-elevated session; the fresh user runs via
  `CreateProcessWithLogonW` with profile loading.
- The wrapper exits with code 1 after a successful worker+guard run (known 13P
  harness cosmetic issue); the authoritative signals are `workerAllStepsPassed`
  and `gatesAllPass` in `00-orchestration.json`.
- OCR/UI captures are Arabic (ar-SA) and depend on the same rendering path
  verified in earlier phases.
