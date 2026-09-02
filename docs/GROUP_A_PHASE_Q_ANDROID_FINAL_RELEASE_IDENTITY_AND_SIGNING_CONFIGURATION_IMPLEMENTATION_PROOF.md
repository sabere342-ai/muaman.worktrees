# GROUP A / PHASE Q — ANDROID FINAL RELEASE IDENTITY AND SIGNING CONFIGURATION IMPLEMENTATION PROOF

> FAIL-CLOSED IMPLEMENTATION + CONFIGURATION PROOF ARTIFACT.
> This is the successor implementation proof to the signing-material reconciliation.
> It records the final Android application identity and the production (upload) release
> signing configuration, implemented from the reconciled keystore material consumed as an
> immutable authority.
> It contains NO passwords, NO DPAPI ciphertext, NO private key material, NO keystore
> bytes, NO Base64 secrets, and NO credential tokens. Paths, mechanism identifiers,
> certificate fingerprints, and file hashes only.

---

## A. Session Identity

```text
SESSION =
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_REMOTE_LOCK

MODE =
FINAL_ANDROID_IDENTITY_AND_PRODUCTION_SIGNING_CONFIGURATION_IMPLEMENTATION_ONLY_FAIL_CLOSED_REMOTE_LOCK

ROOT = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (SACRED READ-ONLY; NOT MUTATED)
```

## B. Repository Entry State

```text
ENTRY_LOCAL_HEAD  = 150f7ca24c61aa8fc055a8157c2360827f58bb5c
ENTRY_REMOTE_HEAD = 150f7ca24c61aa8fc055a8157c2360827f58bb5c
ENTRY_MERGE_BASE  = 150f7ca24c61aa8fc055a8157c2360827f58bb5c
ENTRY_AHEAD       = 0
ENTRY_BEHIND      = 0
TRACKED_DIFF      = CLEAN
INDEX_STATE       = EMPTY
STASH             = stash@{0} on UNRELATED branch codex/muaman-13-strict-july-workbook-data-migration (not touched)
SEQUENCER/MERGE/REBASE = NONE
```

No repair commands used: NO git reset/restore/checkout/clean/stash/merge/rebase/pull/force-push.

Untracked predecessor/evidence files classified and PRESERVED untouched (never staged, never deleted):

```text
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.temp/
```

The failed-session report (previous blocked session) is preserved as sacred evidence.

## C. Governance Authorities (verified from the entry commit)

```text
OWNER_DECISION_BLOB            = fdf0a40b7a47d2bca76079ba2e54e9d1c8f41923
CONTRACT_BLOB                  = 83f84f9225ce7b6ac811edb50e0803e63d5a254a
HISTORICAL_EXECUTION_PROOF_BLOB = e86b15615fd3ecc4d7ff0d15e70b3a8b6898929a
RECONCILIATION_PROOF_BLOB      = a7643ff72eedc916a80251dce714a2ff5c01858c
RECONCILIATION_COMMIT          = 150f7ca24c61aa8fc055a8157c2360827f58bb5c
```

All four governance blobs verified byte-exact from the entry commit.

## D. Signing Material Authority

```text
ACTIVE_KEYSTORE_SHA256              = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
HISTORICAL_PRE_RECONCILIATION_SHA256 = 8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE
                                       (historical evidence ONLY; NOT active)

PRIMARY_SHA256            = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
BACKUP_SHA256             = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
PRIMARY_BACKUP_BYTE_EQUAL = TRUE

ALIAS            = i-tech-upload
ENTRY_TYPE       = PrivateKeyEntry
STORE_TYPE       = JKS
KEY_ALGORITHM    = RSA
KEY_SIZE         = 4096
CERTIFICATE_SHA256 = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
CERTIFICATE_SHA1   = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
```

External material paths (operative provisioning paths; not secrets):

```text
PRIMARY_KEYSTORE = C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
BACKUP_KEYSTORE  = C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks
STORE_PASSWORD_DPAPI_FILE = C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi
KEY_PASSWORD_DPAPI_FILE   = C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi
DPAPI_SCOPE = CurrentUser (WINDOWS_DPAPI_FILE_CURRENT_USER)
```

## E. Pre-Implementation Material Proof (read-only, in-memory only)

Probed with an in-memory Java KeyStore probe; both secrets were decrypted from DPAPI
only inside process memory and delivered to the probe via redirected stdin (never on a
command line, never in an environment variable, never written to disk, never echoed):

```text
PRIMARY_KEYSTORE_EXISTS = TRUE
BACKUP_KEYSTORE_EXISTS  = TRUE
STORE_DPAPI_EXISTS      = TRUE
KEY_DPAPI_EXISTS        = TRUE

PRIMARY_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD  (match)
BACKUP_SHA256  = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD  (match)
PRIMARY_BACKUP_BYTE_EQUAL = TRUE

STORE_SECRET_FORMAT = 64 HEX   (validated in memory)
KEY_SECRET_FORMAT   = 64 HEX   (validated in memory)
PASSWORDS_DISTINCT  = TRUE

STORE_PASSWORD_USABLE   = TRUE   (KeyStore.load exit 0)
ALIAS_EXISTS            = TRUE
ENTRY_TYPE              = PrivateKeyEntry
CERT_SHA256_MATCH       = TRUE
CERT_SHA1_MATCH         = TRUE
KEY_ALGORITHM_RSA       = TRUE
KEY_SIZE_MATCH(4096)    = TRUE
KEY_PASSWORD_USABLE     = TRUE   (getKey exit 0)
PRIVATE_KEY_SIGN_VERIFY = TRUE   (SHA256withRSA sign + verify with cert public key)
STORE_PASSWORD_AS_KEY_PASSWORD_REJECTED = TRUE   (getKey(store) -> UnrecoverableKeyException)
PROBE_RESULT = PASS (exit 0)
```

## F. Password Separation / Usability

```text
STORE_PASSWORD_USABLE                        = TRUE
KEY_PASSWORD_USABLE                          = TRUE
PASSWORDS_DISTINCT                           = TRUE
PRIVATE_KEY_ENTRY_PROTECTED_BY_KEY_PASSWORD  = TRUE
STORE_PASSWORD_AS_KEY_PASSWORD_REJECTED      = TRUE
```

## G. Android Identity Implementation

```text
ANDROID_APPLICATION_ID = com.itech.storemanagement
ANDROID_NAMESPACE      = com.itech.storemanagement
ANDROID_DISPLAY_LABEL  = I Tech لإدارة المحلات
MAIN_ACTIVITY_PACKAGE  = com.itech.storemanagement

MAIN_ACTIVITY_SOURCE =
app/android/app/src/main/kotlin/com/itech/storemanagement/MainActivity.kt

OLD_PACKAGE_RUNTIME_REFERENCES_REMAIN = FALSE
OLD_LABEL_RUNTIME_REFERENCE_REMAINS   = FALSE
ACTIVE_ANDROID_RUNTIME_REFERENCE_TO_com.almuaman.muaman_store = FALSE
ACTIVE_ANDROID_RUNTIME_REFERENCE_TO_com.itech.store           = FALSE
RELEASE_SIGNING_USES_DEBUG = FALSE
```

Historical governance documents containing superseded identity values are NOT rewritten
and are not classified as implementation failures.

## H. Signing Configuration Implementation

```text
RELEASE_DEBUG_SIGNING_REMOVED = TRUE
   (signingConfig = signingConfigs.debug removed from release build type)

PRODUCTION_SIGNING_CONFIGURED = TRUE
   signingConfig name   = upload
   storeFile            = C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
   keyAlias             = i-tech-upload
   storePassword        = decrypted store-password.dpapi value (process memory only)
   keyPassword          = decrypted key-password.dpapi value (process memory only)

DPAPI_RUNTIME_SECRET_LOADING_CONFIGURED = TRUE
   helper = app/android/gradle/production-signing.gradle
   The helper performs a captured child-process DPAPI (CurrentUser) retrieval whose
   stdout is read directly into the Gradle process memory. No password appears on any
   command line, no password is placed in any environment variable, no plaintext file
   is created, child stdout is never inherited/displayed, stderr cannot disclose a
   secret, recovered values are never logged, and a fresh PowerShell child loads
   System.Security before Unprotect.

FAIL_CLOSED_GUARDS = TRUE
   configuration fails when: PowerShell/OS mechanism unavailable; primary keystore
   missing; active keystore SHA-256 mismatch; backup mismatch / not byte-equal; DPAPI
   file missing; DPAPI decryption failure; recovered value malformed (not 64 hex);
   store/key passwords identical; alias missing or not a PrivateKeyEntry; certificate
   fingerprints differ; key password does not unlock the private key; sign/verify probe
   fails; store password unexpectedly unlocks the private key entry.

BACKUP_IS_DEFAULT = FALSE  (backup keystore is a continuity proof copy, never the default source)
```

## I. Secret-Security Proof

```text
PASSWORD_PRINTED              = FALSE
PASSWORD_IN_COMMAND_LINE      = FALSE
PASSWORD_IN_ENVIRONMENT       = FALSE
PASSWORD_IN_GIT               = FALSE
DPAPI_CIPHERTEXT_IN_GIT       = FALSE
KEYSTORE_IN_GIT               = FALSE
PLAINTEXT_SECRET_FILE_CREATED = FALSE
KEY_PROPERTIES_CREATED        = FALSE
NO_SECRET_DISCLOSURE          = TRUE
NO_SECRET_IN_GIT              = TRUE
```

The committed helper `app/android/gradle/production-signing.gradle` contains NO password,
NO DPAPI ciphertext, NO private key, NO certificate bytes and NO keystore bytes.

## J. Validation (non-packaging only)

All release validation tasks are compilation/validation tasks only; they did not produce
final APK/AAB release deliverables and are not release package tasks.

```text
:app:signingReport
   RESULT = PASS (exit 0)
   Variant: release -> Config: upload -> Store: primary i-tech-upload.jks, Alias: i-tech-upload
   SHA-256: 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
   SHA-1:   83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
   (non-secret path/fingerprint output only; no password disclosed)

:app:validateSigningRelease
   RESULT = PASS (exit 0)

:app:processReleaseMainManifest
   RESULT = PASS (exit 0)

:app:compileReleaseKotlin (forced with --rerun-tasks)
   RESULT = PASS (exit 0) — migrated com.itech.storemanagement.MainActivity compiles

IDENTITY_VALIDATION    = PASS (source grep + merged release manifest: package/label/MainActivity exact)
MANIFEST_VALIDATION    = PASS (merged release manifest: package="com.itech.storemanagement",
                               android:name="com.itech.storemanagement.MainActivity",
                               android:label="I Tech لإدارة المحلات")
KOTLIN_PACKAGE_VALIDATION = PASS
SIGNING_CONFIG_VALIDATION = PASS
PRIVATE_KEY_POSITIVE_PROOF = PASS (SHA256withRSA sign + verify true)
PRIVATE_KEY_NEGATIVE_PROOF = PASS (store password as key password rejected)
STAGED_SECRET_SCAN         = PASS (see below)
```

Toolchain substitution note: AGP 8.1.0 running on JDK 21 fails inside the pre-existing
plugin `core-for-system-modules.jar` jlink transform (`:app_links:compileReleaseJavaWithJavac`).
That incompatibility is unrelated to this change and exists at the untouched baseline.
Non-packaging release validation tasks that require compilation (`validateSigningRelease`,
`processReleaseMainManifest`, `compileReleaseKotlin`) were therefore executed with the
same-system JDK 17 toolchain
(`-Dorg.gradle.java.home=C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot`).
`:app:signingReport` additionally validated under the system default JDK 21 with identical
certificate output. No build packaging task (assembleRelease/bundleRelease) was executed.

## K. Repository Changes

```text
ADDED:
  app/android/app/src/main/kotlin/com/itech/storemanagement/MainActivity.kt
  app/android/gradle/production-signing.gradle
  docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_PROOF.md

MODIFIED:
  app/android/app/build.gradle
  app/android/app/src/main/AndroidManifest.xml

RENAMED:
  app/android/app/src/main/kotlin/com/almuaman/muaman_store/MainActivity.kt
     -> app/android/app/src/main/kotlin/com/itech/storemanagement/MainActivity.kt
        (package-only migration; runtime behavior preserved)

DELETED:
  app/android/app/src/main/kotlin/com/almuaman/muaman_store/MainActivity.kt
```

```text
ANDROID_IMPLEMENTATION_SCOPE_ONLY = TRUE
SINGLE_SCOPE_CHANGESET            = TRUE
```

## L. Commit

```text
IMPLEMENTATION_COMMIT = (filled at remote-lock verification)
COMMIT_MESSAGE        = feat(android): implement final release identity and signing configuration
```

## M. Explicit Non-Actions

```text
PRIVATE_KEY_REGENERATED = FALSE
UPLOAD_KEY_ROTATED      = FALSE
CERTIFICATE_CHANGED     = FALSE
ALIAS_CHANGED           = FALSE
STORE_DPAPI_CHANGED     = FALSE
KEY_DPAPI_CHANGED       = FALSE
STORE_PASSWORD_CHANGED  = FALSE
KEY_PASSWORD_CHANGED    = FALSE

APK_BUILT      = FALSE
AAB_BUILT      = FALSE
PLAY_UPLOAD    = FALSE
ANDROID_PUBLISHED = FALSE

GROUP_B_STARTED = FALSE
IOS_CHANGED     = FALSE
WINDOWS_CHANGED = FALSE
SUPABASE_CHANGED = FALSE
LEGACY_ORIGIN_MUTATED = FALSE
```

## N. Remote-Lock Proof (filled at remote-lock verification)

```text
REMOTE            = github
REMOTE_BRANCH     = codex/i-tech-next-roadmap-freeze
PUSH_MODE         = FAST_FORWARD_ONLY
FINAL_LOCAL_HEAD  = (filled at remote-lock verification)
FINAL_REMOTE_HEAD = (filled at remote-lock verification)
FINAL_MERGE_BASE  = (filled at remote-lock verification)
AHEAD             = 0
BEHIND            = 0
REMOTE_MATERIAL_EQUAL = (filled at remote-lock verification)
REMOTE_LOCK       = (filled at remote-lock verification)
```

## O. Successor Boundary

```text
ANDROID FINAL RELEASE BUILD / SIGNED AAB PROOF
```

may be recommended but was NOT started by this session.

---

*End of Android final release identity and signing configuration implementation proof.*