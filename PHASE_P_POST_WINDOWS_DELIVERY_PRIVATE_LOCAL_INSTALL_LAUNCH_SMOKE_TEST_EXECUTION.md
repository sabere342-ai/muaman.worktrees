# PHASE_P — POST WINDOWS DELIVERY
## PRIVATE LOCAL INSTALL / LAUNCH SMOKE TEST — EXECUTION REPORT

> PRIVATE PRIVATE PRIVATE. Local host smoke-test execution ONLY. Remote-lock
> discipline enforced throughout.

---

## Part 0. Entry Forensics + Authority (recorded at session entry)

```text
SESSION_CANONICAL_NAME =
PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION

ROOT           = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
GIT_DIR        = C:\dev\muaman\.git\worktrees\i-tech-next-roadmap-freeze
WORKTREE       = LINKED (git-common-dir detached worktree)
BRANCH         = codex/i-tech-next-roadmap-freeze
TRACKING_BRANCH = github/codex/i-tech-next-roadmap-freeze
HEAD           = 6019627fc5e06feef0783d719262bdc3da8de0bb
HEAD_SUBJECT   = docs: authorize private local windows install launch smoke test execution
```

Entry remote-lock evidence (read-only, no mutation):

```text
ENTRY_LOCAL_HEAD        = 6019627fc5e06feef0783d719262bdc3da8de0bb
ENTRY_TRACKING_HEAD     = 6019627fc5e06feef0783d719262bdc3da8de0bb
ENTRY_DIRECT_GITHUB_HEAD= 6019627fc5e06feef0783d719262bdc3da8de0bb
ENTRY_MERGE_BASE        = 6019627fc5e06feef0783d719262bdc3da8de0bb
ENTRY_AHEAD             = 0
ENTRY_BEHIND            = 0
REMOTE_LOCK_ENTRY       = VERIFIED
```

No active Git operation, no locks, origin NOT contacted.

---

## Part 1. Authority Chain

```text
OWNER_DECISION            = APPROVE_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
OWNER_DECISION_ARTIFACT   = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION.md (committed, at HEAD)
AUTHORIZED_SUCCESSOR_COUNT= 1
SUCCESSOR_STARTED         = YES (this session)
TARGET_DEVICE             = CURRENT_WINDOWS_HOST (OWNER_CONTROLLED_TEST_DEVICE)
TARGET_DEVICE_AUTHORIZED  = YES
```

The Owner decision grants exactly one successor, this session, confined to the
private local install/launch/smoke-test workflow on THIS Windows host only.
No successor is authorized beyond this session. No remediation, no successor
autostart.

---

## Part 2. Package Form Determination

Delivered archive identity (live-verified):

```text
DELIVERED_ARCHIVE         = muaman-windows-release.zip
DELIVERED_ARCHIVE_PATH    = C:\Users\saber\I-Tech\DeliveryArchive\v1.0.0-b1-RC-20260910-222845\muaman-windows-release.zip
DELIVERED_ARCHIVE_SIZE    = 16279806
DELIVERED_ARCHIVE_SHA256  = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
```

Package form classification (from archive inspection, not from the prompt):

```text
PACKAGE_FORM        = PORTABLE_FLUTTER_WINDOWS_BUNDLE
INSTALLER_PRESENT   = NO
INSTALLER_APPLICABLE= NO
PORTABLE_PACKAGE    = YES
```

The archive is a portable Flutter Windows release bundle containing:
`muaman_store.exe`, `flutter_windows.dll`, `pdfium.dll`, `printing_plugin.dll`,
`url_launcher_windows_plugin.dll`, `app_links_plugin.dll`, `data/app.so`,
`data/flutter_assets/*`, `data/icudtl.dat`, fonts (`NotoSansArabic-Bold.ttf`,
`NotoSansArabic-Regular.ttf`), `MaterialIcons-Regular.otf`,
`CupertinoIcons.ttf`, and plugin DLLs.

Because the form is PORTABLE (no installer, no MSI), the smoke procedure is
EXTRACTION + LAUNCH — not a silent-install-per-se. The delivered bundle is used
byte-identical (verified EXE identity below).

---

## Part 3. Private Local Test Runtime Preparation

Authorized, owner-controlled, current Windows host only. No registry, no
firewall, no Defender/SmartScreen/UAC weakening, no signing, no installer.

```text
TEST_RUNTIME_ROOT      = C:\Users\saber\I-Tech\TestDeviceRuntime
RUNTIME_SUBDIR         = v1.0.0-b1-RC-20260910-222845
EXTRACTION_DIR         = C:\Users\saber\I-Tech\TestDeviceRuntime\v1.0.0-b1-RC-20260910-222845
EXTRACTION_FRESH       = YES (target was absent before this session; created fresh)
```

The delivered archive was extracted into the fresh private test runtime
directory. The delivered archive itself was NOT modified (source SHA unchanged
before/after extraction).

---

## Part 4. Extracted Delivery / EXE Identity Verification

```text
EXTRACTED_EXE_PATH     = C:\Users\saber\I-Tech\TestDeviceRuntime\v1.0.0-b1-RC-20260910-222845\muaman_store.exe
EXTRACTED_EXE_SIZE     = 92672
EXTRACTED_EXE_SHA256   = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7
CANONICAL_EXE_SHA256   = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7
EXE_IDENTITY_MATCH     = PASS
```

The extracted executable is byte-identical to the canonical release identity
recorded in the committed release-candidate manifest and the predecessor
release verification evidence.

---

## Part 5. Launch + Smoke Test Evidence

### 5.1 Controlled Launch (single, working directory = extraction dir)

```text
LAUNCH_METHOD           = Start-Process (NormalPriority, WorkingDirectory = EXTRACTION_DIR)
LAUNCH_WORKING_DIR      = C:\Users\saber\I-Tech\TestDeviceRuntime\v1.0.0-b1-RC-20260910-222845
LAUNCH_COUNT            = 1 (single controlled launch only)
PRE_EXISTING_PROCESS    = NONE (no prior muaman_store.exe process before launch)
APP_LAUNCHED            = YES
```

### 5.2 Startup Observation

```text
PROCESS_STARTED         = YES
ALIVE_AFTER_LAUNCH      = YES
MAIN_WINDOW_PRESENT     = YES
WINDOW_HANDLE_PRESENT   = YES
APP_RESPONDING          = YES
```

### 5.3 Arabic / RTL Shell Render

```text
MAIN_WINDOW_TITLE       = I-TECH للتكنولوجيا
TITLE_UTF8_HEX          = 492D5445434820D984D984D8AAD983D986D984D988D8ACD98AD8A7
ARABIC_RTL_SHELL_RENDER = PASS (Arabic window title confirmed; RTL-first shell)
```

### 5.4 Fresh Isolated First-Run Database

```text
DB_FILE_NAME = muaman_store.db
DB_PATH      = C:\Users\saber\I-Tech\TestDeviceRuntime\v1.0.0-b1-RC-20260910-222845\.dart_tool\sqflite_common_ffi\databases\muaman_store.db
DB_FRESH     = PASS (created fresh in this extraction dir; no pre-existing DB)
DB_SCOPE     = LOCAL test runtime only (cwd-scoped; isolated; NOT placed in host app-data)
```

The database is created under the portable working directory as documented in
the repository's offline-data evidence (extraction-dir scoped). No host-level
residue was created.

### 5.5 Fatal Startup Error

```text
OBVIOUS_FATAL_STARTUP_ERROR = ABSENT (app stayed alive and responsive)
```

---

## Part 6. Graceful Close + Post-Close Forensics

```text
CLOSE_METHOD             = WM_CLOSE (normal Windows close)
CLOSED_GRACEFULLY        = YES
POST_CLOSE_PROCESS_COUNT = 0 (process fully exited)
EXE_IDENTITY_POST_CLOSE  = PASS (SHA-256 unchanged end-to-end)
```

Host residue boundary (checked after close):

```text
LOCALAPPDATA\I-TECH\licensing  = ABSENT
HOST_APP_DATA_RESIDUE          = NONE created (no localappdata I-TECH licensing residue)
```

The application's startup indicated an unconfigured/private-local (non-cloud)
state as expected for a fresh first-run on the owner test device; no
cloud/backend initialization, no licensing production activation, no
Supabase mutation, no network write occurred. This is consistent with offline
first-run behavior.

---

## Part 7. Errors and Warnings (factual)

```text
STARTUP_FATAL_ERRORS        = NONE OBSERVED
WINDOW_CLOSE_ERRORS         = NONE OBSERVED
SECURITY_WEAKENING          = NONE (no Defender/SmartScreen/UAC/policy changes)
HOST_MUTATION_OUTSIDE_DIR   = NONE
REPORTED_AS_PASS_JUSTIFIED  = YES — all authorized smoke gates passed on the
                              private local test runtime; no defect, no
                              remediation, no further successor started.
```

---

## Part 8. Scope / Boundary Compliance (all recorded as NOR / NO)

```text
INSTALLER_CREATED       = NO
REBOOT                 = NO
REGISTRY_MODIFICATION  = NO
FIREWALL_MODIFICATION  = NO
DEFENDER_WEAKENING     = NO
CODE_SIGNING           = NO
SIGNING_KEY_OPERATION  = NO
ANDROID                = NO
APK/AAB                = NO
PLAY_CONSOLE           = NO
SUPABASE_MUTATION      = NO
SUPABASE_ACCESS        = NO
DOCKER                 = NO
ORIGIN_CONTACTED       = NO
PRODUCTION             = NO
CUSTOMER_CONTACT       = NO
NETWORK_WRITE          = NO
CLOUD_UPLOAD           = NO
PUBLICATION            = NO
RELEASE_CHANGE         = NO
DURABLE_ARCHIVE_CHANGE = NO
SACRED_ZIP_CHANGE      = NO
```

---

## Part 9. Final Result Token (execution outcome)

```text
SESSION_RESULT =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
REMOTE_LOCKED
```

The private local install (portable extraction) + launch + smoke test executed
successfully on the OWNER-CONTROLLED current Windows host. The delivered EXE
launched, rendered the Arabic/RTL shell, created a fresh isolated first-run DB
in the private test runtime, closed gracefully, and left no host-app-data
residue. Exit is remote-locked; no successor is authorized.

---

## Part 10. Session Stopped

```text
SESSION_STOPPED = YES
NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED_FOR_ANY_FURTHER_WORK = YES
```

STOP. No successor session is started. No autonomous successor work.
