# MUAMAN-13O FINAL REPORT - Deterministic Per-User Windows Installer

- **Phase:** MUAMAN-13O
- **Branch:** `codex/muaman-13o-deterministic-windows-installer-local-acceptance`
- **Baseline:** `bacac28e63148063f47dae73c808bfb53b6394da` (MUAMAN-13N HEAD)
- **Result:** **Outcome A (verified deterministic installer acceptance)**

## 1. Summary

MUAMAN-13O adds the canonical per-user Windows installer for the verified
MUAMAN-13M/13N release payload. The installer is built by the new official
entrypoint `tools/release/package_windows_installer.ps1`, which delegates
packaging to the canonical `package_windows_release.ps1` and verification to the
canonical `verify_release.ps1`, compiles `installer/muaman.iss` with the pinned
Inno Setup 6.7.3 compiler, and is proven deterministic: two independent builds
(Build A and Build B) in isolated roots produced a **byte-identical** installer.

The acceptance harness `tools/muaman13o/verify_installer_acceptance.ps1`
installed the installer silently into an isolated consumer root, launched the
application in an isolated environment, verified module origin (no loads
outside the install root or the Windows directory), uninstalled it while
preserving user business data, and confirmed the entrypoint rejects a tampered
staging tree (fail-closed negative control). All 13 guard points O1..O13 pass
on the pre-commit tree, and O14 passes on the final committed HEAD.

## 2. Installer identity (frozen)

| Property | Value |
|----------|-------|
| Output filename | `muaman-windows-installer.exe` |
| Installer SHA-256 (frozen) | `05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB` |
| Installer size | 12,528,766 bytes |
| Compiler | Inno Setup 6.7.3 (`C:\m13o\toolchain\inno-6.7.3\ISCC.exe`) |
| Compiler SHA-256 (pinned) | `0A8757031B33777E4C9CBFFEE40F11A5062B36D25CBE144C1DB73B6102B80AD7` |
| AppId | `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` (frozen once, drives per-user HKCU registration) |
| App version | 1.0.0 (from `pubspec.yaml` 1.0.0+1) |
| Install scope | per-user (`PrivilegesRequired=lowest`), no elevation |
| Default install dir | `%LOCALAPPDATA%\Programs\muaman_store` |
| Architecture | x64 (`ArchitecturesAllowed/InstallIn64BitMode=x64compatible`) |
| Compression | `lzma2/max`, `SolidCompression=yes` |
| Payload | 13 canonical release files / 33,273,462 bytes / cross-hash `EE892B35...` |

The installer consumes only the verified 13-file release payload produced by
`package_windows_release.ps1` (ZIP `muaman-windows-release.zip`, SHA-256
`57C00E79605340E8AE3477393EC060EE155F9ACA9D346E7314F2F3014FD1A008`). No
timestamp, GUID, or random value is introduced by the `.iss`; determinism was
confirmed empirically by two independent compilations.

## 3. Determinism proof

Build A (working root `work\build-a`) and Build B (working root
`work\long-independent-root-b\build-b`) both compiled the installer from
independently staged copies of the verified release package:

```
Build A SHA-256  05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB  12,528,766 B
Build B SHA-256  05509FA7CF68896BA3718B919C47F72DB35B034484C423C496AC1E60B48007EB  12,528,766 B
byte-identical   true
```

A pre-fix installer (before removing the explicit `.lnk` from the `[Icons]`
names) had SHA-256 `168A9B22...` (12,528,769 B) and is superseded; the frozen
identity is `05509FA7...07EB`.

## 4. Acceptance run (run1)

Executed at `C:\mu13o-acceptance\run1` with the harness:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  C:\dev\muaman\tools\muaman13o\verify_installer_acceptance.ps1 `
  -RepoRoot C:\dev\muaman -ReleaseDir C:\m13m\b1\src\app\build\windows\x64\runner\Release `
  -Root C:\mu13o-acceptance\run1 -InstallerCompilerPath C:\m13o\toolchain\inno-6.7.3\ISCC.exe `
  -Mode all
```

| Mode | Result | Evidence |
|------|--------|----------|
| Preflight | PASS | `preflight-result.json` |
| BuildA | PASS | `builda-result.json`, `build-a\installer-result.json` |
| BuildB | PASS | `buildb-result.json`, `build-b\installer-result.json` |
| Compare | PASS (byte-identical) | `compare-result.json` |
| Install | PASS | `install-result.json` |
| Launch | PASS | `launch-result.json` |
| Uninstall | PASS | `uninstall-result.json` |
| Negative | PASS (rejected) | `negative-result.json` |
| Guards O1..O13 | PASS | `guards-result.json` |

### 4.1 Install

Silent install (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`) into
`consumer\install-root` returned exit 0. The 13 payload files were verified
per-file against the frozen contract (all `match=true`, no unexpected files).
The Start Menu shortcut `muaman_store.lnk` was created, and the per-user
uninstall registration was present under
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\` with
`InstallLocation` equal to the install root. `unexpectedFiles=[]`.

### 4.2 Launch

Launched `muaman_store.exe` from the install root with an isolated profile
(APPDATA/LOCALAPPDATA/TEMP/TMP/USERPROFILE redirected under
`consumer\profile` and `consumer\temp`). The process stayed alive with a
visible main window titled `muaman_store`, loaded 78 modules (all originating
from the install root or the Windows directory, `moduleOriginIssues=[]`),
terminated cleanly via `CloseMainWindow`, and left all 13 shipped payload files
byte-identical (`payloadFilesUnchangedAfterLaunch=true`).

The application created its SQLite business database at runtime inside the
install directory:
`.dart_tool\sqflite_common_ffi\databases\muaman_store.db` (94,208 B). This is
recorded as observed runtime behavior (per-user writable install dir), not a
payload change.

### 4.3 Uninstall

Silent uninstall (`unins000.exe /VERYSILENT ...`) returned exit 0. The
uninstaller removed all 13 payload files, the uninstaller itself
(`unins000.*`), the Start Menu shortcut, and the HKCU uninstall registration,
left no `muaman_store` process running, preserved the business database and
the isolated user profile, and left the (now non-empty) install root in place.
The `[UninstallDelete]` rule `Type: dirifempty; Name: "{app}"` removes `{app}`
only when empty, so user business data is never deleted.

### 4.4 Negative control

A fresh reference package was created, extracted into an owned staging tree,
and `muaman_store.exe` was tampered with a single-byte flip (package SHA-256
verified first: `tamper.packageShaVerified=true`). Preflight on the tampered
staging exited **1**, no installer artifact was produced
(`installerArtifactProduced=false`), and the run was fail-closed
(`failClosed=true`). The entrypoint therefore rejects any staging tree that
does not exactly match the legal release manifest.

## 5. Guards O1..O14

`tools/muaman13o/guard_tests_13o.ps1` verifies the mandatory acceptance gates
against the frozen contract and the recorded run1 evidence:

| Guard | Meaning | Status |
|-------|---------|--------|
| O1 | baseline and initial safety (branch, ancestry, no tag) | PASS |
| O2 | scope guard (production diff empty; only `tools/`, `docs/`, `installer/`) | PASS |
| O3 | canonical release-source guard (delegation, verify-before-compile, 13 `.iss` sources, no wildcards, no `[Run]`) | PASS |
| O4 | installer toolchain identity (pinned ISCC 6.7.3 SHA-256) | PASS |
| O5 | installer contract guard (AppId, per-user, x64, lzma2/max, shortcut policy, no user-data deletion) | PASS |
| O6 | release manifest guard (staging evidence == 13K legal manifest) | PASS |
| O7 | deterministic installer guard (Build A == Build B, live hashes) | PASS |
| O8 | installation guard (exit 0, payload, shortcut, registration, no unexpected files) | PASS |
| O9 | installed payload guard (13 files match frozen contract hashes) | PASS |
| O10 | installed launch guard (alive, visible window, clean shutdown, payload unchanged) | PASS |
| O11 | module-origin guard (all modules from install root or WINDIR) | PASS |
| O12 | uninstallation guard (payload/uninstaller/shortcut/registry removed, data + profile preserved) | PASS |
| O13 | negative-control guard (tampered staging rejected, no artifact) | PASS |
| O14 | final lineage guard (post-commit: clean tree, exactly one commit, no merges/tag) | PASS |

O14 is only computed with `-IncludeO14` after the single commit.

## 6. Historical guards

- **13L** (`tools/release/guard_tests_13l.ps1`): L1..L8 `allPass=true` against
  B1 (`C:\m13m\b1\src\app\build\windows\x64\runner\Release`), including L5
  fresh 13K suite and L7 release verification (13 / 33,273,462 bytes,
  `diffs=0`, cross `EE892B35...`).
- **13K** (`tools/muaman13k/guard_tests.ps1`): G1..G10 `allPass=true` (fresh,
  run via 13L L5).
- **13M** (`tools/muaman13m/guard_tests_13m.ps1`): M1..M7 `pass=true`
  (including N1..N4 negative controls). **M8 `pass=false` by design**: the 13M
  suite bakes in the 13M phase expectations
  (`expectedBranch=codex/muaman-13m-canonical-deterministic-release-package`,
  `expectedBaseline=ea80321f...`), which differ on the 13O HEAD by definition.
  Lineage facts are otherwise correct: `descendsFromBaseline=true`,
  `mergeCommitCount=0`, `tagAtHead=` (none), `productionDiff=[]`. Documented as
  an expected phase-lineage difference, not a defect (same as 13N).

## 7. Static analysis and tests

- `flutter pub get` (from `app\`): OK; writes only to the gitignored
  `app\.dart_tool\`.
- `flutter analyze`: **No issues found** (exit 0).
- `flutter test`: **380 tests, all passed** (exit 0).

## 8. Constraints honoured

- Exactly **one** commit after baseline `bacac28e63148063f47dae73c808bfb53b6394da`;
  final tree clean; no push, tag, merge, rebase, or upstream.
- No edits to `app/lib/`, `app/windows/`, `assets/`, `pubspec.yaml`, or
  `pubspec.lock`. Production diff vs baseline is empty. Changed-file scope is
  limited to `tools/`, `docs/`, `installer/`.
- The installer is per-user, non-elevated, with no service/scheduled-task/
  startup/firewall/network dependency, no `[Run]` auto-launch, a required Start
  Menu shortcut, and an optional unchecked desktop-icon task.
- Uninstall removes installed program files and metadata but preserves user
  business data.
- The entrypoint pins the compiler by name and SHA-256 and refuses anything
  else; fails closed on any invalid input; performs no silent fallback.
- All evidence is UTF-8 no BOM with UTC timestamps; deletion only under owned
  roots; no secrets or personal data.

## 9. Evidence inventory

Committed under `docs/muaman-13o/evidence/`:

| # | File | What it proves |
|---|------|----------------|
| 00 | `00-environment.json` | environment probe (Flutter 3.24.5 / Dart 3.5.4, git 2.55.0, non-admin) |
| 01 | `01-baseline-preflight.txt` | baseline tree/state before 13O work |
| 02 | `02-existing-installer-discovery.json` | discovery of existing installer tooling candidates |
| 03 | `03-muaman13n-release-contract.json` | 13N/13M package contract the installer consumes |
| 04 | `04-installer-toolchain.json` | pinned Inno Setup 6.7.3 compiler identity |
| 05 | `05-acceptance-run1/**` | full run1 acceptance evidence (mode results, per-build installer results, staging verification, compile logs, O1..O13 guard result) |

Supporting external evidence (not committed): the acceptance root
`C:\mu13o-acceptance\run1\` (installers under `out\`, builders under `work\`,
consumer tree under `consumer\`, negative tree under `negative\`) and the
historical guard outputs under `C:\m13o-guards\`.

## 10. Conclusion

The MUAMAN-13O deterministic per-user Windows installer is accepted: two
independent builds are byte-identical, the installer installs and launches in
an isolated consumer environment with no module-origin violations, uninstalls
cleanly while preserving user data, rejects a tampered staging tree, and the
O1..O14 guard suite plus all historical guards remain green. **Outcome A
(verified deterministic installer acceptance).**
