# MUAMAN-13R: Final Governed Windows Delivery Package Acceptance

## Outcome

**PASS.** MUAMAN-13R accepts the final governed Windows delivery package for the
frozen installer. The delivery consists of `Muaman-Setup.exe` plus a user-safe
Arabic `README.txt` and a matching `SHA256SUMS.txt`, packaged into a
deterministic `Muaman-1.0.0-Windows.zip`. All 18 acceptance gates (R1-R18) and
all 10 negative controls (NC01-NC10) pass, both in pre-commit mode and in the
authoritative post-commit final-HEAD run.

- Baseline: `680102bb029e67a6d931a9daa154902a3a7d799d`
- Canonical run: `20260809-182232`
- Evidence: `docs/muaman-13r/evidence/20260809-182232/`
- Branch: `codex/muaman-13r-final-governed-windows-delivery-package-acceptance`
- Final commit (single, message below): `MUAMAN-13R: accept final governed
  Windows delivery package`; the exact final HEAD is recorded by the
  post-commit final-HEAD guards run.

## Installer Identity (frozen, unchanged from 13O/13P/13Q)

| Property | Value |
|---|---|
| File | `muaman-windows-installer.exe` (canonical) / `Muaman-Setup.exe` (delivery) |
| SHA-256 | `05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB` |
| Size (bytes) | 12,528,766 |

The same bytes are the accepted frozen identity (13O/13P/13Q), the canonical
governed input (13P evidence `20260808-225059`), the delivery installer, and
the installer extracted from the final ZIP. The installer binary is not
committed to the repository; only the governed package carries it.

## Delivery Package

| Item | Size (bytes) | SHA-256 |
|---|---|---|
| `Muaman-1.0.0-Windows/Muaman-Setup.exe` | 12,528,766 | `05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB` |
| `Muaman-1.0.0-Windows/README.txt` | 2,228 | `849964EAF83C36DDDDDA0AEA1BA5D80A0292FACB987223109272B99209D1E22C` |
| `Muaman-1.0.0-Windows/SHA256SUMS.txt` | 84 | `13AC53E029F9586FEC7085594B2B0E228346EF23C6F7859D3CFE07EAF31B5A7C` |
| `Muaman-1.0.0-Windows.zip` | 11,971,503 | `5633775FF7808FD0437F4FC3835A6ED8147455220A7A5CD33974850999C62127` |
| `Muaman-1.0.0-Windows.zip.sha256` | 92 | - |

The ZIP contains exactly three entries
(`Muaman-1.0.0-Windows/Muaman-Setup.exe`, `/README.txt`, `/SHA256SUMS.txt`);
extraction into a scratch directory reproduces the delivery tree byte-for-byte
(R17). The committed delivery root holds exactly three items: the package
directory, the ZIP, and the `.zip.sha256` sidecar.

## Environment

- Windows 11, PowerShell 5.1.
- Deterministic packaging runs D1 (in-repo) and D2 (external working
  directory) are separate child PowerShell processes against the same
  canonical installer; both produce identical ZIP bytes.

## Gate Results (R1-R18)

| Gate | Result |
|---|---|
| R1 baseline ancestry (pre-commit: HEAD == baseline; final: HEAD is the accepted final commit) | PASS |
| R2 allowed diff only (changes confined to `tools/muaman13r/`, `docs/muaman-13r/`, `delivery/`) | PASS |
| R3 production diff empty (`app/`, `installer/`, `assets/`, `pubspec.yaml`, `pubspec.lock` untouched) | PASS |
| R4 installer SHA-256 identical across accepted == canonical == delivery == ZIP | PASS |
| R5 installer size identical across accepted == canonical == delivery | PASS |
| R6 single installer in package (exactly one `.exe` entry) | PASS |
| R7 minimal package contents (3 files in tree, 3 entries in ZIP) | PASS |
| R8 no development artifacts (source/test/log/cache/build intermediates absent) | PASS |
| R9 no secrets in committed 13R files, delivery, ZIP contents, and evidence | PASS |
| R10 no absolute development paths in end-user files | PASS |
| R11 no placeholders in user-facing delivery files | PASS |
| R12 README present, non-empty, and byte-identical to the committed template | PASS |
| R13 `SHA256SUMS.txt` manifest correct for all package files | PASS |
| R14 independent package build D1 succeeds | PASS |
| R15 independent package build D2 (external working directory) succeeds | PASS |
| R16 deterministic package identity (D1 == D2 == final ZIP hash and size) | PASS |
| R17 extraction verification (ZIP == delivery tree, installer SHA preserved) | PASS |
| R18 final committed-state verification (guards re-run from the final HEAD) | PASS |

## Negative Controls

`guard_tests_13r.ps1` negative controls NC01-NC10 — all PASS:

- NC01 single byte flip in installer fails the gate
- NC02 installer with wrong size fails the gate
- NC03 second installer present fails the gate
- NC04 source code file added in delivery fails the gate
- NC05 secret sentinel added inside delivery fails the gate
- NC06 absolute development path in README fails the gate
- NC07 wrong `SHA256SUMS` manifest fails the gate
- NC08 placeholder in user-facing file fails the gate
- NC09 README missing or empty fails the gate
- NC10 unknown file inside package/ZIP fails the gate

## Secret Scan

`secret-scan.txt`: 22 files scanned, 0 findings, PASS. Two occurrences of the
Inno Setup documented command-line usage example (the `/PASSWORD` switch with a
single-word placeholder value) were surfaced and classified **known-benign**:
one inside the installer's built-in help text (UTF-16LE) and one in the harness
source comment that documents that exact exception. No real secret patterns
(tokens, keys, credentials) are present anywhere in the committed scope,
delivery, ZIP, or evidence.

## Deterministic Packaging

- D1 ZIP SHA-256 `5633775FF7808FD0437F4FC3835A6ED8147455220A7A5CD33974850999C62127`
  (11,971,503 bytes)
- D2 ZIP SHA-256 `5633775FF7808FD0437F4FC3835A6ED8147455220A7A5CD33974850999C62127`
  (11,971,503 bytes)
- Final committed ZIP: identical hash and size.
- ZIP entry timestamps are pinned to `2024-01-01T00:00:00Z` (13M convention);
  compression is deterministic (see `package-run-d1.txt`, `package-run-d2.txt`,
  `package-hashes.txt`).

## Git Integrity

- Single commit on top of baseline `680102bb029e67a6d931a9daa154902a3a7d799d`.
- Only `tools/muaman13r/`, `docs/muaman-13r/`, and `delivery/` are added; no
  production files changed (R2/R3 enforced by the harness preflight and gates).
- `git diff --check` is clean for the working tree and for `baseline..HEAD`.
- The installer binary is not committed; the canonical 13P input lives outside
  this repository.

## Harness Reliability Fixes During This Run

Defects found and fixed in the harness (`tools/muaman13r/guard_tests_13r.ps1`),
each covered by the re-run of the affected gates and all negative controls:

1. **NC01/NC02 (tamper detection was a no-op):** the negative packager passed a
   tampered installer but `Invoke-Packager` always read the canonical installer,
   so the corrupted bytes were never packaged. `Invoke-Packager` now accepts an
   `-InstallerOverride` that the negative controls use.
2. **NC03 (extra installer undetected):** the single-installer check only
   counted entries with the exact expected name, so an extra
   differently-named `.exe` still passed. It now requires exactly one `.exe`
   entry total and one exact-name match, and `.exe` was added to the forbidden
   development-artifact extension list.
3. **R7/R8 (expected ZIP names collapsed):** the expected-name array used a
   comma-expression that PowerShell evaluated with array-concatenation
   precedence, mangling the three names into one string and failing the ZIP
   set-diff. Each element is now parenthesized.
4. **Extraction verification used a 3-argument `Join-Path`** (no such overload
   in PowerShell 5.1); replaced with a nested two-argument form. All `Join-Path`
   call sites verified as two-argument.
5. **R9 false positive:** the installer contains Inno Setup's built-in help
   text documenting the `/PASSWORD` switch with a placeholder value. The scanner
   now separates real findings from known-benign occurrences and records them
   explicitly in `secret-scan.txt` under `knownBenign:`.

## Limitations

- Acceptance is executed on Windows 11 under the developer's non-elevated
  session; the deterministic packaging child processes run in the same session.
- The report records the final-HEAD commit hash via the post-commit guards
  result rather than embedding a self-referential hash inside the committed
  report.
