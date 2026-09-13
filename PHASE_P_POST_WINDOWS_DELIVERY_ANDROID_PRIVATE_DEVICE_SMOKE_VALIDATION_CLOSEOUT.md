# PHASE P — POST-WINDOWS-DELIVERY ANDROID PRIVATE DEVICE SMOKE VALIDATION — CLOSEOUT

> GOVERNANCE CLOSEOUT / DOCUMENTATION-ONLY SESSION.
> This artifact formally records and closes out the ALREADY-COMPLETED private
> Android release-build / device-smoke validation performed in the immediately
> preceding authorized implementation session.
>
> This closeout session performs NO build, NO install, NO device mutation, NO
> production action, NO Play action, NO Supabase mutation, and NO schema or code
> change. Only read-only repository/artifact inspection was performed to
> classify evidence, plus this documentation artifact.
>
> Contains NO passwords, NO DPAPI ciphertext, NO private key material, NO
> keystore bytes, NO Base64 secrets, NO Supabase service-role key, and NO access
> tokens. Paths, mechanism identifiers, certificate fingerprints and file hashes
> only.

---

## A. Session Identity and Result

```text
SESSION =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_CLOSEOUT_AND_PRODUCTION_CONFIGURATION_PLANNING

SESSION_CLASS = GOVERNANCE_CLOSEOUT_AND_PLANNING_ONLY
CLOSEOUT_SUBJECT = PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_RELEASE_BUILD_AND_PRIVATE_DEVICE_SMOKE_VALIDATION
PRIOR_RESULT_TOKEN = PASS_PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_RELEASE_BUILD_AND_PRIVATE_DEVICE_SMOKE_VALIDATION_REMOTE_LOCKED
```

This session officially records the prior PASS and does NOT reopen it. The prior
execution produced NO repository mutation, NO commit, NO push, NO tag, NO Play
action, NO Supabase production mutation and NO production action. Its evidence is
owned by that session's final report and by the committed predecessor artifacts
referenced below.

```text
ANDROID_PRODUCTION_BUILD_STARTED   = NO (during THIS closeout session)
ANDROID_PRODUCTION_APK_INSTALLED   = NO
PLAY_STORE_ACTION                  = NONE
PRODUCTION_ACTION                  = NONE
SUPABASE_PRODUCTION_MUTATION       = NONE
ORIGIN_CONTACTED                   = NO
```

---

## B. Repository Identity (VERIFIED_FROM_CURRENT_REPOSITORY)

```text
REPOSITORY_ROOT      = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR              = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree)
BRANCH               = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE    = github  https://github.com/sabere342-ai/muaman.worktrees.git
FORBIDDEN_REMOTE     = origin  C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (legacy; NEVER contacted)
TRACKING_BRANCH      = github/codex/i-tech-next-roadmap-freeze
```

```text
LOCAL_HEAD         = 896fc8411747ce61b82030948ef8e450ef8a1b72
TRACKING_HEAD      = 896fc8411747ce61b82030948ef8e450ef8a1b72 (git for-each-ref)
DIRECT_GITHUB_HEAD = 896fc8411747ce61b82030948ef8e450ef8a1b72 (git ls-remote github, read-only)
MERGE_BASE         = 896fc8411747ce61b82030948ef8e450ef8a1b72
AHEAD              = 0
BEHIND             = 0
HEAD_SUBJECT       = android: resume api 36 productization with canonical icon
ACTIVE_GIT_OP      = NONE (MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG /
                          rebase-merge / rebase-apply / index.lock all ABSENT)
STAGED             = 0
STASH              = PRESERVED, NOT TOUCHED
                     (stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration:
                      283ff9d MUAMAN-12: implement local user roles and sales-only access)
```

Entry classification: **CASE_B_EXPECTED_BENIGN_RESIDUE**. Canonical identity is
exact, no tracked modifications/deletions/staging, no active operation, and only
previously documented untracked residue is present and is PRESERVED untouched.

---

## C. Evidence Provenance Policy

Every material statement below is labeled with exactly one provenance class:

| Class | Meaning |
|---|---|
| A. VERIFIED_FROM_CURRENT_REPOSITORY | Inspected and verified from live repository state this session (committed source/config or the on-disk release artifact). |
| B. VERIFIED_FROM_COMMITTED_PREDECESSOR_ARTIFACTS | Recorded in a committed predecessor governance artifact which was read this session. |
| C. OWNER_SUPPLIED_PRIOR_SESSION_EVIDENCE | Reported by the Owner-provided final report of the immediately preceding smoke execution session. |
| D. NOT_REVERIFIED_THIS_SESSION | Plausible but not directly re-verified this session (no build/install/device action was authorized). |
| E. NOT_YET_VALIDATED | Explicitly NOT proven by any evidence yet (requires future controlled online validation). |

No claim is upgraded from Owner-supplied evidence to direct verification unless
this session actually produced the direct evidence (e.g., on-disk artifact
hashing / apksigner / aapt2).

---

## D. Canonical Predecessor Baseline (VERIFIED_FROM_CURRENT_REPOSITORY)

```text
CANONICAL_SMOKE_BASELINE = 896fc8411747ce61b82030948ef8e450ef8a1b72
SUBJECT                  = android: resume api 36 productization with canonical icon
```

The release-build/device-smoke work was executed against this exact HEAD. The
HEAD carries the api-36 productization config and the canonical launcher icon
resume (commit `896fc84`), which are direct prerequisites of the tested APK.

Committed predecessor artifacts read this session (B):

```text
65f4440  PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTIZATION_RECONCILIATION_AND_PLANNING.md
9cfd2cb  PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTIZATION_LAUNCHER_ICON_BLOCKER (recorded)
eb97420  PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTIZATION_RELEASE_BUILD_AND_SMOKE_VALIDATION_OWNER_AUTHORIZATION.md
aa35163  PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTIZATION_CANONICAL_LAUNCHER_ICON_OWNER_DECISION (approved)
896fc84  PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTIZATION_CANONICAL_ICON_PROVISIONING_AND_RELEASE_BUILD_RESUMPTION.md
```

The prior smoke session itself made no commit, so its execution report survives
as Owner-supplied evidence (C), corroborated where applicable by committed
source/config (A/B).

---

## E. Recovery of the Former 12 Tracked Worktree-Only Deletions

The immediately preceding smoke session reported that it recovered exactly 12
previously tracked, worktree-only deletions (Arabic legacy artifact paths under
`شهري7/` and `قديم/`) from HEAD using narrow worktree-only `git restore`
semantics, and verified all 12 byte-identical to HEAD.

Evidence classes for this closeout:

```text
COUNT OF DELETIONS RECOVERED        = 12
RESTORATION MECHANISM               = narrow worktree-only git restore (prior session)
BYTE-IDENTICAL TO HEAD AFTER RESTORE = reported TRUE (C, prior session report)
CURRENT TRACKED-DELETION STATE       = 0 deletions, 0 tracked modifications, 0 staged   (A, this session)
```

```text
CURRENT: TRACKED_MODIFIED  = 0
         TRACKED_DELETED   = 0
         STAGED            = 0
```

Current repository evidence confirms the recovered-clean state persists: the
worktree is clean with respect to tracked files at closeout entry
(A. VERIFIED_FROM_CURRENT_REPOSITORY). This closeout does NOT repeat that
restore because the entry is already clean.

---

## F. APK Identity (A + C)

```text
APK_RELATIVE_PATH = app/build/app/outputs/flutter-apk/app-release.apk
APK_SIZE          = 28,654,557 bytes
```

Verified THIS session from the on-disk artifact (A) — the artifact was NOT
rebuilt, only inspected read-only:

```text
APK_EXISTS_ON_DISK = TRUE
APK_SIZE           = 28,654,557 bytes   (matches prior session report)
APK_SHA256         = 31DBA3AFEDD608A1456FD9728A4D4D46AAA2B098F8F510DA759CE3FAF2CF543E
APK_SHA1           = ADFA353EE6375D869E30B4CAE50F9D9859931FDF
```

The on-disk hash values are byte-identical to the Owner-supplied prior session
report (C -> A corroboration). The claim that this exact on-disk artifact is the
APK that was installed on the private device remains OWNER_SUPPLIED (C) because
this session performed no device action; the byte match makes that linkage
consistent.

---

## G. Signing Certificate Fingerprints (A + B + C)

Verified THIS session with `apksigner verify --verbose --print-certs` from the
SDK build-tools 35.0.0 (read-only, exit 0, "Verifies TRUE"):

```text
SIGNER_DN        = CN=I Tech Android Upload Key, OU=Android Release,
                   O=I Tech, L=Cairo, ST=Cairo, C=EG
CERT_SHA256      = 485e4187fb0bd53a295bb0fd36f174babcf2ffdabfd72014a314c1460cc0b927
CERT_SHA1        = 8343ef47a037549707125d02c07f138aa814e105
CERT_MD5         = 86ebd4d0a3edfacef34c14d3474f135d   (informational)
KEY_ALGORITHM    = RSA, 4096-bit
SCHEMES_VERIFIED = v1 (JAR) TRUE ; v2 (APK Sig Scheme) TRUE ; v3 FALSE ; v3.1 FALSE ; v4 FALSE
NUMBER_OF_SIGNERS = 1
```

The cert DN and fingerprints are also committed in
`app/android/gradle/production-signing.gradle` as the reconciliation-locked
upload-key material (B/A), and match the release artifact (A). The GENERIC
apksigner v1 warnings about unprotected `META-INF/...  .version` gradle metadata
entries are benign packaging metadata, not a signing failure.

Keystore material is recorded HASH-ONLY from committed config (B/A):

```text
ACTIVE_KEYSTORE_SHA256 = f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd
STORE/KEY_SECRETS      = NOT read, NOT printed, NOT committed (DPAPI two-source fail-closed)
```

---

## H. Package / Version / API Identity (A)

Verified THIS session with `aapt2 dump badging` from SDK build-tools 35.0.0
(read-only, exit 0):

```text
PACKAGE          = com.itech.storemanagement
VERSION_CODE     = 2
VERSION_NAME     = 1.0.0
COMPILE_SDK      = 36
MIN_SDK          = 21
TARGET_SDK       = 36
APPLICATION_LABEL= I Tech لإدارة المحلات
LAUNCHABLE_ACTIVITY = com.itech.storemanagement.MainActivity
USES_PERMISSIONS = android.permission.INTERNET
                   (+ system auto-granted com.itech.storemanagement.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
                    declared by AndroidX profileinstaller; no dangerous permissions)
NATIVE_ABIS      = arm64-v8a, armeabi-v7a, x86, x86_64
```

The `versionCode=2` / `versionName=1.0.0` correspond to the committed
`app/pubspec.yaml` `version: 1.0.0+2` at the canonical baseline. `compileSdk 36 /
targetSdk 36 / minSdk 21` match the committed `app/android/app/build.gradle`.

---

## I. Real Device Evidence (C, Owner-supplied prior session)

```text
DEVICE_SERIAL        = f0deca9
DEVICE               = Redmi Note 7 / MIUI Global 12.5.3-class environment (as observed)
ADB_DEVICE_STATE     = device / authorized
INSTALL_INTENT       = adb install of app-release.apk
INITIAL_RESULT       = INSTALL_FAILED_USER_RESTRICTED
                       (established as MIUI's ADB-install confirmation flow,
                        NOT a packaging defect)
OWNER-APPROVED REINSTALL = adb install result: Success
PM_PATH_EXISTS         = TRUE
DUMPSYS_PACKAGE        = versionCode 2 ; versionName 1.0.0 ; minSdk 21 ; targetSdk 36
LAUNCH                 = am start -n
                         com.itech.storemanagement/com.itech.storemanagement.MainActivity
                         -> EXIT 0
PROCESS_STABILITY      = process remained alive after dwell checks;
                         MainActivity remained foreground/resumed
FATAL EXCEPTION        = NONE
ANR                    = NONE
DART/FLUTTER_FATAL     = NONE
```

Owner visually confirmed on the device (C):

```text
ARABIC_UI_SANITY       = confirmed (Arabic-first UI)
RTL_SANITY             = confirmed
REACHED_SURFACE        = FirstOwnerSetupScreen
```

`uiautomator dump` unavailability on this MIUI + Flutter device was classified by
the prior session as a device-side limitation, NOT an application defect (C).

---

## J. Offline / Placeholder Supabase Configuration (A + C + E)

The tested APK was NOT a production-connected build.

Source defaults (A, committed at baseline):

```text
app/lib/config/app_config.dart:
  SUPABASE_URL      = String.fromEnvironment('SUPABASE_URL',
                       defaultValue: 'https://your-project-ref.supabase.co')
  SUPABASE_ANON_KEY = String.fromEnvironment('SUPABASE_ANON_KEY',
                       defaultValue: 'your-anon-key')
  isConfigured      = true ONLY when both values differ from placeholders
app/lib/main.dart:
  if (AppConfig.isConfigured) await Supabase.initialize(url, publishableKey)  // else offline-only
```

The prior session reported the tested installation reached the placeholder /
unconfigured posture (`AppConfig.isConfigured == false`) and therefore
deterministically surfaced `FirstOwnerSetupScreen` (C). A read-only embedded
-string probe inside the on-disk APK was attempted this session but was
inconclusive (no ASCII/UTF-16 match found with the chosen quick scan); binary
string-level confirmation is therefore NOT claimed and remains
D. NOT_REVERIFIED_THIS_SESSION. The placeholder posture is corroborated by (A)
committed defaults and (C) owner-supplied report.

This placeholder posture is the DESIGNED offline-only fail-closed behavior: with
placeholders, Supabase never initializes, no cloud session, no cloud licensing
resolution, no device activation, no sync drain.

---

## K. Exact Limitations of This Smoke (E — NOT_YET_VALIDATED)

The private offline smoke PROVES:

```text
- Release APK builds and signs successfully with the production upload key (A/C)
- APK installs on a real Android device (Redmi Note 7, serial f0deca9) (C)
- Package identity com.itech.storemanagement is correct (A/C)
- MainActivity launches and the base Flutter runtime survives startup (C)
- Arabic/RTL surface renders sanely to Owner (C)
- No immediate licensing/device-trust fatal startup crash (C)
```

It does NOT prove (E):

```text
- production Supabase connectivity
- production Auth behavior
- real production shop provisioning
- production RLS behavior
- server-controlled trial behavior
- production entitlement behavior
- real Device Trust registration
- owner license-token behavior against production
- offline grace behavior after a valid online lease
- sync against production
- cross-tenant isolation against live production
- Play Store readiness beyond artifact-level checks
```

This closeout explicitly does NOT represent the private offline smoke as
production validation. The private smoke and any future Play submission are
separate evidence domains.

---

## L. Explicit Non-Actions (this closeout session)

```text
PLAY_STORE_ACTION              = NONE
PRODUCTION_ACTION              = NONE
SUPABASE_PRODUCTION_MUTATION   = NONE
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
SUCCESSOR_STARTED              = NO
TAG_CREATED                    = NO
DEVICE_F_MUTATED               = NO (no install/uninstall/pm/settings on f0deca9)
APK_REBUILT                    = NO (artifact inspected read-only, never regenerated)
SECRET_READ_EXPOSED            = NO
SECRET_PRINTED/COMMITTED       = NO
ORIGIN_CONTACTED               = NO
LEGACY_UNTRACKED_RESIDUE_TOUCHED = NO (inventoried and preserved)
```

---

## M. Evidence Classification Summary

```text
REPOSITORY_IDENTITY / HEAD / REMOTE_LOCK        A  VERIFIED_FROM_CURRENT_REPOSITORY
FORMER 12 DELETIONS RECOVERY                    C  OWNER_SUPPLIED (preceding session report)
CURRENT CLEAN TRACKED STATE                     A  VERIFIED_FROM_CURRENT_REPOSITORY
APK PATH / SIZE / SHA-256 / SHA-1               A  VERIFIED_FROM_CURRENT_ARTIFACT (+C match)
APK IS THE EXACT TESTED ARTIFACT                C  OWNER_SUPPLIED (byte-consistent, not device-linked this session)
SIGNING CERT DN / FINGERPRINTS                  A  VERIFIED (apksigner + committed gradle config)
KEYSTORE HASH                                   B/A VERIFIED_FROM_COMMITTED_CONFIG
PACKAGE / VERSION / API IDENTITY                A  VERIFIED (aapt2 + committed gradle/pubspec)
DEVICE f0deca9 → INSTALL/LAUNCH/PROCESS/NO-FATAL C  OWNER_SUPPLIED (no device action this session)
ARABIC/RTL/FIRSTOWNER SURFACE CONFIRMATION      C  OWNER_SUPPLIED
PLACEHOLDER / UNCONFIGURED POSTURE (tested)     C  OWNER_SUPPLIED, corroborated by committed defaults (A)
EMBEDDED-STRING PROBE IN APK                    D  NOT_REVERIFIED_THIS_SESSION (inconclusive quick scan)
PRODUCTION CONNECTIVITY / AUTH / RLS / LICENSING /
DEVICE TRUST / SYNC / PLAY READINESS            E  NOT_YET_VALIDATED
```

---

## N. Closeout Statement

The private Android release-build/device-smoke validation is formally CLOSED as
PASS within the exact scope proven above, and its limitations under §K are
explicitly recorded. No claim of production connectivity, production validation,
or Play Store readiness is made.

```text
CLOSEOUT_RESULT =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_VALIDATION_CLOSEOUT
PRIVATE_DEVICE_SMOKE_IS_PRODUCTION_VALIDATION = NO
PRODUCTION_VALIDATION_STARTED                 = NO
```

The next phase (production configuration + controlled online validation) is
PLANNED ONLY in the companion artifact
`PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_PLAN.md`
and requires a separate explicit Owner authorization before any execution.

---

*End of Android private device smoke validation closeout artifact.*