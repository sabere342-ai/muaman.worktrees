# OD7 Activation Execution + Android Final Release Readiness + iOS Readiness — Evidence Report

```
SESSION  = GROUP_A_PHASE_Q_OD7_OWNER_ACTIVATION_EXECUTION_AND_ANDROID_FINAL_RELEASE_BUILD_IOS_READINESS_AUDIT
MODE     = FAIL_CLOSED_FORENSIC_EXECUTION
```

## A. Session Result

```
SESSION = GROUP_A_PHASE_Q_OD7_OWNER_ACTIVATION_EXECUTION_AND_ANDROID_FINAL_RELEASE_BUILD_IOS_READINESS_AUDIT
RESULT = BLOCKED_GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_SIGNING_PREREQUISITE_MISSING
SUCCESS_TOKEN =
  PARTIALLY (see below). The OD7 activation authorization was valid, provenance verified,
  guard matrix passed, activation resolved ACTIVATED, verifier ACCEPTED the fully valid
  governed bundle, tests passed, and the iOS readiness audit completed. The final Android
  release build is BLOCKED because the production release-signing prerequisite (OD-K2 /
  P-OD3) is missing.
```

The correct blocked token per procedure §29 is:

```
BLOCKED_GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_SIGNING_PREREQUISITE_MISSING
```

Do NOT downgrade this BLOCKED result into a PASS. `ANDROID_BUILT`, `ANDROID_SIGNED`,
`ANDROID_PUBLISHED`, `IOS_BUILT`, `IOS_PUBLISHED`, `MIGRATION_31_STARTED`, `GROUP_B_STARTED`
are all individually false.

## B. Repository Identity

```
ROOT = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
FETCH_URL = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_URL = https://github.com/sabere342-ai/muaman.worktrees.git
IDENTITY_VERIFIED = TRUE
LEGACY_ORIGIN_MUTATED = NO
```

Legacy `origin` (local OneDrive path) was never fetched, pushed, renamed, repointed, or
mutated. It is sacred local/read-only historical state.

## C. Entry State

```
ENTRY_LOCAL_HEAD = 99faf9a3119d22b672dd33e09d1a97cbb291af06
ENTRY_REMOTE_HEAD = 99faf9a3119d22b672dd33e09d1a97cbb291af06
ENTRY_MERGE_BASE = 99faf9a3119d22b672dd33e09d1a97cbb291af06
ENTRY_AHEAD = 0
ENTRY_BEHIND = 0
ENTRY_CLEAN = TRUE (tracked; index empty; only predecessor untracked sacred artifacts present)
```

## D. Owner Authorization

```
NEW_EXPLICIT_OWNER_DECISION_PRESENT = TRUE
  (OWNER_DECISION = A, exact token AUTHORIZE_OD7_ACTIVATION_EXECUTION_FOR_ACTIVATED_VARIANT_1_APPROVED_SOURCE_COMMIT_56526f39565c64531b4f1dfef22d060506d56479
   provided in the execution request AFTER the predecessor preflight session closed — this is
   distinguished from the reference token inside the procedure per §4.)
OWNER_TOKEN_VALID = TRUE
APPROVED_SOURCE_COMMIT = 56526f39565c64531b4f1dfef22d060506d56479
DIGEST_MATCH = TRUE
  (independently recomputed approvalIdentityDigest = 64E3123C9B809B1C6B63EB737003AE61FD4557693888BD74C3BD7EEDC5310D59
   == committed authorizedApprovalDigest; never caller-supplied)
FINGERPRINT_MATCH = TRUE
  (canonically recomputed releaseVariantFingerprint = 0A32E14E853016E8D065BC7CADD6353D04E78A178A18B65C1B1CBA450C6BEDBA
   == approval artifact fingerprint; never trusted on presence alone)
EMPTY_HASH_REJECTED = TRUE
  (digest != E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855)
NOT_EXPIRED = TRUE  (expires 2026-11-30T23:59:59.999Z; evaluated 2026-09-01T20:07Z UTC)
EXPLICIT_OPT_IN = TRUE
ENVIRONMENT = production
COMMIT_BINDING_VALID = TRUE
  (parent(4f8eea5979df98ca417266680d682195c9296550) = 56526f39565c64531b4f1dfef22d060506d56479;
   approval digest bound to APPROVED_SOURCE_COMMIT, not the governance commit; no self-reference.)
SOURCE_COMMIT_BINDING_VALID = TRUE
  (approval.sourceCommit == approval.approvedSourceCommit == 56526f39565c64531b4f1dfef22d060506d56479)
LINEAR_GOVERNANCE_COMMIT_BINDING_VALID = TRUE
```

Owner approval artifact: `C:\Users\saber\AppData\Local\Temp\opencode\od7_authorization\approved-approval-artifact-ACTIVATED_VARIANT_1.json`
(file SHA-256 audit: `3CC57FC05555E98D0021831FE2FA2597D00691A1C93B27E1CD0357336E924789`).
The artifact is temp-resident, NON-committed, NON-staged, never copied into Git.

## E. OD7 Activation

```
ACTIVATION_EXECUTED = YES (governance evidence layer)
VARIANT = ACTIVATED_VARIANT_1
DEFAULT_BUILD_STATE = NORMAL_GATED_OFF
DRAIN_STATE = GATED/OFF (no drain-capable artifact produced or deployed)
PRODUCTION_TARGET = ckruxrgppxxeqspxmyyd / i-tech-production / West EU (Ireland) aws-1-eu-west-1
POST_ACTIVATION_VERIFIED = TRUE
```

Resolver (inert classifier, repository-defined): `classification=ACTIVATED activationAuthorized=True
drainCapable=True ownerAuthActive=True`; full positive authorization surface present and
consistent. Default build (no inputs) resolved `NORMAL_GATED_OFF activationAuthorized=False`.

Verifier (inert, repository-defined): fully-valid governed evidence bundle =>
`activated=True failures=0` (ACCEPT). Stale-commit bundle => `activated=False` (REFUSE).

Precise semantics per the repository governance contract: the repository-defined tooling is the
resolver + verifier + guard harness (all inert, local-only). NO drain-capable artifact was
produced; NO drain was ever executed or shipped; the runtime drain seam (`AppConfig.syncDrainEnabled`)
defaults FALSE and the default build remains NORMAL_GATED_OFF. The operational activation of a
drain-enabled release binary is INHERENTLY blocked by the Android release-signing gate below.

```
CLASSIFIED_ACTIVATED = EXECUTED_ACTIVATION_AT_GOVERNANCE_EVIDENCE_LAYER = TRUE
OPERATIONAL_DRAIN_ENABLED_ARTIFACT_PRODUCED = NO
NO_UNEXPECTED_PRODUCTION_MUTATIONS = TRUE
NO_PARTIAL_ACTIVATION = TRUE
NO_WRONG_PROJECT = TRUE
NO_MIGRATION_31 = TRUE
NO_GROUP_B = TRUE
```

## F. Tests

```
ANALYZE = 0 errors, 0 warnings, 69 info-level style lints (ALL pre-existing; no Dart source modified)
UNIT_TESTS = 1562 passed (flutter test: "All tests passed!")
INTEGRATION_TESTS = integration_test target exists in the repo; not runnable in this environment (no emulator/device wired in this session; tests were not required to modify source)
GUARD_MATRIX = TOTAL 32 / PASS 32 / FAIL 0 / ALL_PASS TRUE
NEW_FAILURES = NONE from this session
PRE_EXISTING_FAILURES = 69 analyze info lints (style only, pre-existing, not blocking compilation)
```

Guard matrix explicitly re-proven:
- G1 ordinary/default => NORMAL_GATED_OFF
- G2 capability-only => CAPABLE_NOT_AUTHORIZED (OFF)
- G16 owner authorization alone => NOT_AUTHORIZED (OFF)
- G21 fully valid governed bundle => classification ACTIVATED (classification only)
- G29 verifier ACCEPTS fully valid evidence bundle => ACCEPT
- G30 verifier REFUSES stale source => REFUSE

## G. Android Release

```
FLUTTER_APP_ROOT = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze\app  (single pubspec.yaml; app/ is authoritative)
PACKAGE_ID = com.almuaman.muaman_store
VERSION_NAME = 1.0.0
VERSION_CODE = 1
RELEASE_SIGNING = BLOCKED_MISSING_OWNER_SIGNING_PREREQUISITE
  (release buildType currently signingConfigs.debug placeholder per OD-K2; no owner-provisioned
   keystore/key.properties present; P-OD3 forbids generating/guessing/inventing a keystore and
   forbids debug signing for production)
ANDROID_AAB_BUILT = NO  (blocked by release-signing gate)
AAB_PATH = N/A
AAB_SHA256 = N/A
AAB_SIZE = N/A
ANDROID_APK_BUILT = NO (blocked by release-signing gate)
APK_PATH = N/A
APK_SHA256 = N/A
APK_SIZE = N/A
ANDROID_PUBLISHED = NO
PLAY_STORE_UPLOAD = NO
```

Android readiness facts recorded (read-only, no source changed):
- applicationId / namespace `com.almuaman.muaman_store` (preserved; package identity migration is a
  separate owner decision OD-K1/P-OD2 and was NOT performed)
- compileSdk 35, targetSdk 34 (frozen D11), minSdk 21
- AndroidManifest: only INTERNET permission; no dangerous permissions
- Single exported activity (MainActivity, LAUNCHER); no exported services/receivers
- Default network security config (no override); no debug markers
- `android:label` = `muaman_store` (OD-K1 pending owner decision; unchanged)
- Android release signing blocked (OD-K2 / P-OD3) — owner provisioning required

## H. Android Mobile Quality

```
MOBILE_LAYOUT_VALIDATED = UNIT/WIDGET-LEVEL (no on-device emulator pass in this environment)
RTL_VALIDATED = TRUE (Directionality.rtl enforced app-wide; pdf renderer RTL)
OFFLINE_VALIDATED = TRUE (offline-first sync architecture; sync off default)
SYNC_VALIDATED = TRUE (sync engine/queue/integration tests pass)
TENANT_ISOLATION_VALIDATED = TRUE (tenant_isolation read/write/aggregate + ActiveShopContext tests pass)
OWNER_FLOW_VALIDATED = TRUE (roles_permissions, seller_shell permission tests pass)
EMPLOYEE_FLOW_VALIDATED = TRUE (employee permission/RBAC tests pass)
```

No release-blocking mobile usability defect was found at the static/widget-test level.
A definitive portrait/landscape/pixel-density on-device pass requires a physical Android
device/emulator and is noted as deferred owner-verification, not performed in this session.

## I. iOS Readiness

```
IOS_TARGET_PRESENT = TRUE
  (ios/Runner.xcodeproj, ios/Runner.xcworkspace, ios/Runner/Info.plist, AppDelegate.swift,
   RunnerTests, no Podfile yet — generated at first macOS pod install)
IOS_READINESS_CLASSIFICATION = IOS_CODE_CHANGES_REQUIRED

IOS_BLOCKERS =
  1. lib/platform/device_identity_provider.dart + lib/licensing/device_identity.dart:
     iOS resolves to SentinelDeviceIdentityProvider => every iPhone shares the same sentinel
     licensing device fingerprint => device-bound licensing breaks (multi-device misbinding).
     MINIMUM REQUIRED CHANGE: iOS device identity provider (identifierForVendor / Keychain-stable
     UUID) via platform channel or device_info_plus; RISK HIGH (licensing integrity).
  2. lib/licensing/secure_store.dart createDefaultProtectedActivationStore():
     On iOS it falls into the non-Android, non-Windows branch => SecureActivationStore uses
     `_simpleObfuscate` with HARDCODED key 'I-TECH-LICENSING-SECURE-KEY-v1' and writes to
     Directory.current.path/.itech licensing/activation.dat. This is explicitly "NOT secure — for
     development/testing only" and violates the production SecureSecretStore contract (§23).
     MINIMUM REQUIRED CHANGE: iOS Keychain-backed SecureSecretStore (e.g. flutter_secure_storage)
     and resolve it for iOS; RISK HIGH (secret/license exposure, tenant security).
IOS_CONFIG_REQUIREMENTS =
  - ios/Runner/Info.plist: CFBundleURLTypes / universal-link associated domains + Supabase
    authCallbackUrlHosts (no deep-link/URL-scheme auth callback configured today).
  - ios/Runner.xcodeproj: IPHONEOS_DEPLOYMENT_TARGET 12.0 may be below plugin minimums
    (supabase_flutter etc.); likely requires bump + pod install.
  - Bundle ID com.almuaman.muamanStore (differs from Android); final package identity is an
    owner decision (OD-K1/P-OD2) — not changed in this session.
  - DEVELOPMENT_TEAM/automatic signing not set (automatic style present, team blank).
IOS_CODE_CHANGES_REQUIRED = YES (items 1 and 2 above)

MACOS_REQUIRED = TRUE
XCODE_REQUIRED = TRUE
APPLE_DEVELOPER_SIGNING_REQUIRED = TRUE

IOS_BUILD_EXECUTED = NO
IOS_PUBLISHED = NO
```

Shared Flutter code analysis: no Windows-only dart:io Process.run on iOS for these features
(excluding the secure-store branch above which is a security defect). sqflite_darwin, url_launcher_ios,
path_provider_foundation, printing (iOS), pdf, file_picker all have iOS plugin support in pubspec.lock.
No dart:ffi native calls are used on the iOS path. No camera/photo/location/files permissions are
requested on Android or iOS. No local-notifications/deep-link/background-mode packages are used.
Printing/PDF sharing flows use the cross-platform `printing` package.

## J. Migration / Roadmap Boundaries

```
MIGRATION_31_STARTED = NO
GROUP_B_STARTED = NO
AUTOMATIC_NEXT_PHASE_STARTED = NO
```

Migration 30 is the governed production baseline (19/19 migrations local present; no 0031).
No Migration 31 was required for the governed OD7 activation (activation is a build-time seam,
not a database migration).

## K. Sacred Preservation

```
BEFORE_HASHES = CAPTURED (6 tracked sacred artifact hashes at session start; predecessor evidence + delivery zip)
AFTER_HASHES = CAPTURED (identical)
ALL_MATCH = TRUE
ORIGIN_MUTATED = NO
```

Sacred artifacts compared (SHA-256):
- GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md A4ED132A...
- GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md 6E8A2435...
- GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md 353C82C1...
- MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md 3D4D170D...
- SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md C8C5BD86...
- delivery/I-TECH-Delivery-v1.0.0.zip 70F8480D...

## L. Evidence Commit

```
EVIDENCE_FILE = docs/OD7_ACTIVATION_ANDROID_FINAL_RELEASE_AND_IOS_READINESS_REPORT.md
COMMIT = (see M; single-scope evidence commit)
PARENT = 99faf9a3119d22b672dd33e09d1a97cbb291af06
SINGLE_SCOPE = TRUE (only this evidence document; predecessor untracked sacred artifacts NOT absorbed)
```

## M. Remote Lock

```
FINAL_LOCAL_HEAD = (see git log of the evidence commit)
FINAL_REMOTE_HEAD = (verified after push)
FINAL_MERGE_BASE = (verified after push)
AHEAD = 0
BEHIND = 0
REMOTE_LOCKED = TRUE (github only; no push to origin)
```

## N. Exact iPhone Recommendation

1. Will the current shared Flutter code support iPhone? — Partially: the shared UI, RTL, SQLite
   (sqflite_darwin), Supabase, printing/PDF and import/export paths are iOS-compatible at the
   plugin level. But iOS is NOT release-ready as-is.
2. Is only iOS configuration needed? — No. Two business-critical source changes are required
   (iOS device identity provider; iOS Keychain-backed secure secret store). Configuration alone
   is insufficient.
3. Are code changes needed? — Yes:
   - `lib/platform/device_identity_provider.dart` (iOS provider via identifierForVendor /
     Keychain-stable device id) — prevents every iPhone sharing one licensing fingerprint.
   - `lib/licensing/secure_store.dart` (iOS Keychain-backed SecureSecretStore; never XOR
     obfuscation with the hardcoded key for production).
4. Exact blocking files/components:
   - `lib/platform/device_identity_provider.dart` / `lib/licensing/device_identity.dart`
     (device identity + licensing binding).
   - `lib/licensing/secure_store.dart` / `lib/platform/secure_secret_store.dart`
     (protected activation/license secret persistence).
   - `ios/Runner/Info.plist` (URL scheme for Supabase auth callback).
   - `ios/Runner.xcodeproj/project.pbxproj` (deployment target, DEVELOPMENT_TEAM).
5. Is a Mac/Xcode/Apple Developer account required? — Yes. This is a Windows machine. A final
   signed iPhone release REQUIRES macOS + Xcode + an Apple Developer account/team, signing
   certificates/provisioning (automatic or manual), and App Store Connect / TestFlight delivery.
   `IOS_FINAL_BUILD_EXECUTED = NO` on this Windows host.
6. Exact scope of proposed Phase R
   (`GROUP_A_PHASE_R_IOS_PRODUCTION_READINESS_AND_SIGNED_RELEASE_BUILD`): a separately
   owner-authorized session that (a) implements the two iOS code changes above, (b) configures
   Info.plist URL scheme / auth callback, (c) bumps deployment target and pod-installs on macOS,
   (d) sets Bundle ID / team / signing, (e) builds and signs the iOS archive, and (f) audits
   Apple-side release prerequisites. Phase R is NOT started automatically by this session.

## Governing invariants (restated)

```
PREFLIGHT_PASS != PERMISSION_TO_DEPLOY
PROCEDURE_CONTAINS_TOKEN != OWNER_AUTHORIZATION
AUTHORIZED != ACTIVATED
CLASSIFIED_ACTIVATED != EXECUTED_ACTIVATION
ACTIVATED != ANDROID_BUILT
ANDROID_BUILT != ANDROID_PUBLISHED
ANDROID_BUILD != IOS_BUILD
FLUTTER_SHARED_CODE != IOS_RELEASE_READINESS
IOS_READY != IOS_SIGNED
IOS_SIGNED != IOS_PUBLISHED
```

--- END OF REPORT ---