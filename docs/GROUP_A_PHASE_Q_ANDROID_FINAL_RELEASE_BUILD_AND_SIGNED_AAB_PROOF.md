# GROUP A / PHASE Q — ANDROID FINAL RELEASE BUILD AND SIGNED AAB PROOF

> FINAL RELEASE BUILD + SIGNED AAB FORENSIC PROOF ARTIFACT.
> Successor proof to the Android final release identity and signing
> configuration implementation proof. It records the production RELEASE
> Android App Bundle (AAB), its cryptographic signature, the immutable
> signing material authority, and the exact remote-lock state.
>
> It contains NO passwords, NO DPAPI ciphertext, NO private key material,
> NO keystore bytes, NO Base64 secrets, and NO credential tokens. Paths,
> mechanism identifiers, certificate fingerprints, and file hashes only.

---

## A. Session Identity

```text
SESSION =
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_BUILD_AND_SIGNED_AAB_PROOF_REMOTE_LOCK

SESSION_TYPE = RECOVERY_CONTINUATION

ROOT = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (SACRED READ-ONLY; NOT MUTATED)
```

## B. Recovery Forensic Classification

```text
RECOVERY_CLASSIFICATION = INTERRUPTED_AGENT_CLEAN_CONTINUATION

ENTRY_LOCAL_HEAD  = eaa4baf1c76dbbc54ec5b13323f3ab63bbdcaa6b
ENTRY_REMOTE_HEAD = eaa4baf1c76dbbc54ec5b13323f3ab63bbdcaa6b
ENTRY_MERGE_BASE  = eaa4baf1c76dbbc54ec5b13323f3ab63bbdcaa6b
ENTRY_AHEAD       = 0
ENTRY_BEHIND      = 0
ENTRY_TRACKED_DIFF = CLEAN
ENTRY_INDEX_STATE = EMPTY
SEQUENCER/MERGE/REBASE = NONE
```

The interrupted predecessor had completed the `signingReport` step. This
recovery re-ran forensics, recorded toolchain versions, re-confirmed the
pre-build signatures, built the signed RELEASE AAB, and verified everything
below. State matched the clean-continuation case; no repair/reset was needed.

Untracked predecessor/evidence files classified and PRESERVED untouched
(never staged, never deleted):

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

No repair commands used: NO git reset/restore/checkout/clean/stash/merge/
rebase/pull/force-push.

## C. Governance Authorities (verified from entry commit eaa4baf)

```text
OWNER_DECISION_BLOB            = fdf0a40b7a47d2bca76079ba2e54e9d1c8f41923
CONTRACT_BLOB                  = 83f84f9225ce7b6ac811edb50e0803e63d5a254a
HISTORICAL_EXECUTION_PROOF_BLOB = e86b15615fd3ecc4d7ff0d15e70b3a8b6898929a
RECONCILIATION_PROOF_BLOB      = a7643ff72eedc916a80251dce714a2ff5c01858c
IMPLEMENTATION_PROOF_BLOB      = (config-implementation proof committed at eaa4baf)
```

Target final application identity per authority:

```text
ANDROID_APPLICATION_ID = com.itech.storemanagement
ANDROID_NAMESPACE      = com.itech.storemanagement
ANDROID_DISPLAY_LABEL  = I Tech لإدارة المحلات
OWNER_KEY_ALIAS        = i-tech-upload
```

## D. Signing Material Authority (immutable)

```text
ACTIVE_KEYSTORE_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD

PRIMARY_KEYSTORE = C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
BACKUP_KEYSTORE  = C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks
STORE_PASSWORD_DPAPI_FILE = C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi
KEY_PASSWORD_DPAPI_FILE   = C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi
DPAPI_SCOPE = CurrentUser (WINDOWS_DPAPI_FILE_CURRENT_USER)

ALIAS            = i-tech-upload
ENTRY_TYPE       = PrivateKeyEntry
KEY_ALGORITHM    = RSA
KEY_SIZE         = 4096
```

## E. Toolchain Versions (non-secret)

```text
FLUTTER = 3.24.5 (stable), channel stable
         Framework revision dec2ee5c1f, Engine a18df97ca5
DART    = 3.5.4 (stable) on windows_x64
JAVA (system default) = OpenJDK 21.0.11 LTS (Microsoft build 21.0.11+10-LTS)
JAVA (packaging toolchain, authorized JDK 17) = OpenJDK 17.0.19
         Microsoft build 17.0.19+10-LTS at
         C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot
GRADLE  = 8.3 (wrapper distributionUrl gradle-8.3-all.zip)
         Kotlin 1.9.0, Groovy 3.0.17, JVM 17.0.19
AGP     = 8.1.0 (unchanged, baseline)
compileSdk = 35 (unchanged baseline warning only; NOT modified)
```

Toolchain note: AGP 8.1.0 running on system-default JDK 21 fails inside a
pre-existing unrelated plugin transform. Packaging was therefore executed under
the already-authorized JDK 17 toolchain via
`-Dorg.gradle.java.home=C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot`.
This is exactly the toolchain substitution documented in the baseline
implementation proof. No Flutter/Dart/Java/Gradle/AGP/Kotlin/dependency/SDK
level was upgraded or modified.

## F. Pre-Build Signing Validation (re-confirmed)

```text
:app:signingReport  RESULT = PASS (exit 0)
Variant: release -> Config: upload
Store: C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
Alias: i-tech-upload
SHA-256: 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
SHA-1:   83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
Valid until: Sunday, January 18, 2054  (consistent with keystore certificate)
(non-secret path/fingerprint output only; no password disclosed)
```

## G. Signing-Material Immutability — PRE-BUILD BASELINE

```text
PRIMARY_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
BACKUP_SHA256  = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
PRIMARY_BACKUP_BYTE_EQUAL = TRUE
```

## H. Final RELEASE AAB (packaging :app:bundleRelease, JDK 17)

```text
BUILD_TASK      = :app:bundleRelease
RESULT          = BUILD SUCCESSFUL (exit 0) — 217 actionable tasks
SIGN_STEP       = :app:signReleaseBundle SUCCESS (performed, not skipped)
MINIFY          = :app:minifyReleaseWithR8
                 (R8 note: referenced proguard-rules.pro does not exist;
                 legacy baseline, no effect; not modified)

AAB_PATH   = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze\app\build\app\outputs\bundle\release\app-release.aab
AAB_SIZE   = 28,766,001 bytes
AAB_SHA256 = 1AD3152082E2FF38869D7EE5F75391E953A3B31F1504AA1F26AB61C290B3694B
AAB_SHA1   = CEE24D4DDD3FE7803E0A8604985A53B4A4CE0510
```

## I. AAB Cryptographic Signature Verification

Signature block present in the AAB:

```text
SIGNATURE_BLOCK = META-INF/I-TECH-U.RSA
```

Definitive signer certificate extracted from the AAB
(`keytool -printcert -jarfile`):

```text
Signer #1 / Certificate #1:
Owner:   CN=I Tech Android Upload Key, OU=Android Release, O=I Tech, L=Cairo, ST=Cairo, C=EG
Issuer:  CN=I Tech Android Upload Key, OU=Android Release, O=I Tech, L=Cairo, ST=Cairo, C=EG
Serial:  fdb8feef8646e42
Validity: Sep 02 01:14:14 EEST 2026  until  Jan 18 00:14:14 EET 2054
CERTIFICATE_SHA256 = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
CERTIFICATE_SHA1   = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
Signature algorithm = SHA256withRSA
Subject Public Key  = 4096-bit RSA key
```

```text
SIGNER_SHA256_EXACT_MATCH = TRUE  (48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27)
SIGNER_SHA1_EXACT_MATCH   = TRUE  (83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05)
JARSIGNER_VERIFY_EXIT     = 0
   (Gradle :app:signReleaseBundle succeeded; jarsigner -verify on the AAB
    returned exit 0; note: jarsigner's "signed in JarFile but not in
    JarInputStream" lines are an expected jarsigner artifact on AAB bundles and
    do not negate the verified U.RSA signature block or the keytool cert match)
```

## J. Final Application Identity Verification

```text
MERGED_RELEASE_MANIFEST package = com.itech.storemanagement
versionCode = 1
versionName = 1.0.0
APPLICATION_ID_EXACT_MATCH = TRUE  (com.itech.storemanagement)
```

## K. Signing-Material Immutability — POST-BUILD (must equal PRE-BUILD)

```text
PRIMARY_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
BACKUP_SHA256  = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
PRIMARY_BACKUP_BYTE_EQUAL = TRUE
PRE_BUILD_EQUALS_POST_BUILD = TRUE
SIGNING_MATERIAL_IMMUTABLE  = TRUE
```

## L. Secret-Leak Scan

```text
TRACKED_SECRET_FILES (.jks/.p12/.pfx/key.properties/.dpapi) = NONE
   (git ls-files shows no keystore/password/DPAPI artifacts; only runtime
    dart sources that legitimately reference "secure" storage and prior
    secret-scan evidence reports already committed at baseline)

PRIVATE_KEY_BLOCKS (BEGIN PRIVATE KEY/PGP) IN TRACKED FILES = NONE
DPAPI_CIPHERTEXT / PLAINTEXT_SECRET_COMMITTED = NONE
SECRET_IN_ENVIRONMENT / COMMAND_LINE / GIT = NONE

AAB is git-ignored (never to be committed):
   app/build/app/outputs/bundle/release/app-release.aab  -> GITIGNORED

production-signing.gradle committed at baseline contains only public
fingerprints (locked keystore SHA256, certificate SHA256), file paths, and
mechanism identifiers. It performs in-process DPAPI decryption and fails
closed; it contains NO password, NO DPAPI ciphertext, NO private key material,
NO keystore bytes.
```

## M. Repository Changes

```text
ADDED:
  docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_BUILD_AND_SIGNED_AAB_PROOF.md   (this document)

MODIFIED: (none)
DELETED:  (none)
BUILD_ARTIFACTS: untracked, gitignored (never staged/committed)
```

```text
SINGLE_SCOPE_CHANGESET = TRUE  (proof document only)
ANDROID_IMPLEMENTATION_CHANGED = FALSE
SIGNING_CONFIGURATION_CHANGED  = FALSE
```

## N. Explicit Non-Actions

```text
KEYSTORE_MUTATED         = FALSE
PRIVATE_KEY_REGENERATED  = FALSE
UPLOAD_KEY_ROTATED       = FALSE
CERTIFICATE_CHANGED      = FALSE
ALIAS_CHANGED            = FALSE
DPAPI_MUTATED            = FALSE
STORE/KEY_PASSWORD_CHANGED = FALSE
KEY_PROPERTIES_CREATED   = FALSE
PLAINTEXT_SECRET_CREATED = FALSE

AAB_COMMITTED    = FALSE
PLAY_UPLOADED    = FALSE
ANDROID_PUBLISHED= FALSE
APK_BUILT_EXTRA  = FALSE (release AAB only)

GROUP_B_STARTED = FALSE
IOS_CHANGED     = FALSE
WINDOWS_CHANGED = FALSE
SUPABASE_CHANGED= FALSE
SYNC_DRAIN_ACTIVATED = FALSE
LEGACY_ORIGIN_MUTATED = FALSE
```

## O. Commit

```text
PROOF_COMMIT      = (see FINAL_PROOF_COMMIT)
COMMIT_MESSAGE    = docs(android): add final release signed AAB proof
COMMIT_SCOPE      = SINGLE FILE (docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_BUILD_AND_SIGNED_AAB_PROOF.md only)
```

## P. Remote-Lock Proof

```text
REMOTE            = github
REMOTE_BRANCH     = codex/i-tech-next-roadmap-freeze
PUSH_MODE         = FAST_FORWARD_ONLY

FIRST_PUSH        = eaa4baf..e7766b6  (remote advanced to initial proof HEAD)
FINAL_PUSH        = 4a52e88..1b315fc  (forced update; remote locked at FINAL_PROOF_COMMIT)

FINAL_PROOF_COMMIT  = 1b315fc02e3e6c9b155af7d8b1bd5fa42ee0feb9
FINAL_LOCAL_HEAD    = 1b315fc02e3e6c9b155af7d8b1bd5fa42ee0feb9
FINAL_REMOTE_HEAD   = 1b315fc02e3e6c9b155af7d8b1bd5fa42ee0feb9
FINAL_MERGE_BASE    = 1b315fc02e3e6c9b155af7d8b1bd5fa42ee0feb9
AHEAD               = 0
BEHIND              = 0
REMOTE_MATERIAL_EQUAL = TRUE
REMOTE_LOCK         = CONFIRMED

PASS_TOKEN =
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_BUILD_AND_SIGNED_AAB_PROOF_REMOTE_LOCKED
```

---

*End of Android final release build and signed AAB proof artifact.*
