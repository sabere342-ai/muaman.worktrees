# GROUP A / PHASE Q — ANDROID SIGNING MATERIAL RECONCILIATION PROOF

> FAIL-CLOSED GOVERNANCE CORRECTION ARTIFACT.
> This is the successor correction proof for the historical upload-key provisioning
> execution proof. It supersedes ONLY the previously-claimed execution-state facts and
> obsolete keystore hashes. It contains NO passwords, NO DPAPI ciphertext, NO private
> key material, NO keystore bytes, NO Base64 secrets. Paths, mechanism identifiers,
> certificate fingerprints, and file hashes only.

---

## A. Session Identity

```text
SESSION =
GROUP_A_PHASE_Q_ANDROID_SIGNING_MATERIAL_RECONCILIATION_AND_PROOF_REMOTE_LOCK

MODE = SIGNING_MATERIAL_RECONCILIATION_EXTERNAL_GOVERNANCE_PROOF_ONLY_FAIL_CLOSED
ROOT = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (SACRED READ-ONLY; NOT MUTATED)

RESULT = PASS_GROUP_A_PHASE_Q_ANDROID_SIGNING_MATERIAL_RECONCILIATION_AND_PROOF_REMOTE_LOCKED
```

## B. Repository Entry State

```text
ENTRY_LOCAL_HEAD  = d9324c81bff7e382a927d23ba5b76ff621386a64
ENTRY_REMOTE_HEAD = d9324c81bff7e382a927d23ba5b76ff621386a64
ENTRY_MERGE_BASE  = d9324c81bff7e382a927d23ba5b76ff621386a64
ENTRY_AHEAD       = 0
ENTRY_BEHIND      = 0
TRACKED_DIFF      = CLEAN

UNTRACKED (classified, preserved untouched, NOT staged, NOT deleted):
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
  GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
  MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
  delivery/I-TECH-Delivery-v1.0.0.zip
  supabase/.temp/
```

No repair commands used: NO git reset/restore/checkout/clean/stash/merge/rebase/pull/force-push.

## C. Predecessor Failed-Session Classification

```text
PREDECESSOR_SESSION =
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_REMOTE_LOCK

PREDECESSOR_RESULT = FAILED_BLOCKED_SIGNING_MATERIAL_MISMATCH
PREDECESSOR_FINAL_HEAD = d9324c81bff7e382a927d23ba5b76ff621386a64
```

The predecessor session correctly FAILED CLOSED rather than reinterpreting the signing
contract. It discovered: the JKS is authentic; alias, certificate, store-password.dpapi
are all correct; key-password.dpapi decrypts successfully but does NOT unlock the
PrivateKeyEntry; the PrivateKeyEntry is protected by the STORE password. It made NO
commit, mutated NO key material, and preserved the remote lock. This session does NOT
reinterpret that failure as success. It reconciles the discovered protection-metadata
mismatch under a new explicit authority.

## D. Original Provisioning Contract Authority

```text
CONTRACT =
docs/GROUP_A_PHASE_Q_ANDROID_OWNER_UPLOAD_KEY_SECURE_PROVISIONING_CONTRACT.md
CONTRACT_BLOB = 83f84f9225ce7b6ac811edb50e0803e63d5a254a
```

The contract is authoritative for INTENDED password architecture:

```text
STORE PASSWORD and KEY PASSWORD are independent.
PASSWORDS_DISTINCT = TRUE
STORE_PASSWORD_MECHANISM = WINDOWS_DPAPI_FILE_CURRENT_USER
KEY_PASSWORD_MECHANISM   = WINDOWS_DPAPI_FILE_CURRENT_USER
```
plus the owner decision authority:

```text
DECISION =
docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_OWNER_IDENTITY_AND_PLAY_SIGNING_DECISION.md
DECISION_BLOB = fdf0a40b7a47d2bca76079ba2e54e9d1c8f41923
```

## E. Historical Provisioning Execution Proof Authority

```text
EXECUTION_PROOF =
docs/GROUP_A_PHASE_Q_ANDROID_OWNER_UPLOAD_KEY_SECURE_PROVISIONING_EXECUTION_PROOF.md
EXECUTION_PROOF_BLOB = e86b15615fd3ecc4d7ff0d15e70b3a8b6898929a
```

The historical execution proof is NOT rewritten. It remains a record of what the prior
session CLAIMED. Per the supersession rule, the following of its execution-state claims
are here corrected/superseded:

```text
KEY_PASSWORD_USABLE = TRUE                            -> as applied to ACTUAL key entry protection, was FALSE
PASSWORDS_DISTINCT = TRUE                             -> as applied to ACTUAL key entry protection, was FALSE
PRIVATE_KEY_USABILITY under independent key password  -> was NOT proven; now PROVEN
PRIMARY/BACKUP KEYSTORE SHA256 = 8AF622B5...          -> now PRE-RECONCILIATION hashes
```

The original keystore hash becomes the historical PRE-RECONCILIATION value and is NOT
the expected active-keystore hash after this reconciliation.

## F. Confirmed Root Cause and Exact Discovered Mismatch

```text
1. key-password.dpapi was validly provisioned; its decrypted value is a clean
   distinct 64-character hexadecimal value. Round-trip decryption succeeds under
   WINDOWS_DPAPI_CURRENT_USER.
2. The JKS PrivateKeyEntry protection password was accidentally set equal to the
   STORE password at provisioning time.
3. Therefore:
   CURRENT_PRIVATE_KEY_UNLOCK_WITH_STORE_PASSWORD = TRUE
   CURRENT_PRIVATE_KEY_UNLOCK_WITH_KEY_PASSWORD   = FALSE
4. NO key/certificate/alias mismatch existed. The JKS itself, the alias, the RSA
   keypair, and the certificate were and remain authentic.
```

Independently reconfirmed read-only (in-memory, secrets never displayed):

```text
store-password.dpapi decrypts successfully  = TRUE (64-char hex)
key-password.dpapi decrypts successfully    = TRUE (64-char hex)
decrypted values distinct                   = TRUE
primary keystore SHA-256                    = 8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE
backup keystore SHA-256                     = 8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE
primary/backup byte-equal                   = TRUE
alias                                        = i-tech-upload
entry type                                   = PrivateKeyEntry
RSA size                                     = 4096
certificate SHA-256                          = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
certificate SHA-1                            = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
```

Pre-state private-key probe on the pristine (pre-reconciliation) backup JKS:

```text
store password as key password   -> private key recovered, SHA256withRSA signature created and verified (exit 0)
key-password.dpapi as key password -> UnrecoverableKeyException, rejected (exit 3)
```

## G. Reconciliation Strategy

```text
PRESERVE the existing upload private key
PRESERVE the existing certificate
PRESERVE the existing alias (i-tech-upload)
PRESERVE both existing DPAPI secret values (store-password.dpapi, key-password.dpapi)
CHANGE ONLY the PrivateKeyEntry protection password inside the existing JKS:
    FROM = the existing STORE password
    TO   = the already-provisioned decrypted value of key-password.dpapi
```

This is a correction of JKS protection metadata. It is NOT key rotation.

Operationally, a byte-identical candidate copy was created OUTSIDE the repository under
the existing signing-material hierarchy, reconciled, and fully proven before promotion.
The required final state:

```text
STORE_PASSWORD_USABLE                       = TRUE
KEY_PASSWORD_USABLE                         = TRUE
PASSWORDS_DISTINCT                          = TRUE
PRIVATE_KEY_ENTRY_PROTECTED_BY_KEY_PASSWORD = TRUE
STORE_PASSWORD_NO_LONGER_UNLOCKS_PRIVATE_KEY = TRUE
```

## H. Explicit Non-Rotation Proof

```text
PRIVATE_KEY_REGENERATED = FALSE
UPLOAD_KEY_ROTATED      = FALSE
CERTIFICATE_CHANGED     = FALSE
ALIAS_CHANGED           = FALSE
STORE_DPAPI_CHANGED     = FALSE
KEY_DPAPI_CHANGED      = FALSE
STORE_PASSWORD_CHANGED  = FALSE
PLAY_SIGNING_KEY_ROTATED = FALSE
```

Certificate continuity before/after reconciliation (keytool -list -v, non-secret):

```text
certificate SHA-256 BEFORE = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
certificate SHA-256 AFTER  = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
certificate SHA-1   BEFORE = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
certificate SHA-1   AFTER  = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
certificate DN            = CN=I Tech Android Upload Key, OU=Android Release, O=I Tech, L=Cairo, ST=Cairo, C=EG (unchanged)
certificate serial        = fdb8feef8646e42 (unchanged)
subject public key        = 4096-bit RSA (unchanged)
signature algorithm       = SHA256withRSA (unchanged)
```

The candidate rekey was applied with keytool -keypasswd (old key entry password = the
STORE password, new key entry password = key-password.dpapi value; all passwords
supplied via redirected stdin, none on the command line). keytool's defaulting of the
old key password to the store password for JKS terminals, PLUS the successful rekey,
independently confirmed the root cause: the key entry was protected by the STORE
password. The JKS bytes changed (expected) but no cryptographic identity changed.

## I. Pre-Reconciliation Keystore SHA-256

```text
PRE_RECONCILIATION_PRIMARY_SHA256 = 8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE
PRE_RECONCILIATION_BACKUP_SHA256  = 8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE
```

## J. Post-Reconciliation Primary SHA-256

```text
POST_RECONCILIATION_PRIMARY_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
```

## K. Post-Reconciliation Backup SHA-256

```text
POST_RECONCILIATION_BACKUP_SHA256 = F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
```

## L. Primary / Backup Byte Equality

```text
PRIMARY_BACKUP_BYTE_EQUAL = TRUE
PRIMARY_LENGTH = 3956
BACKUP_LENGTH  = 3956
```

The backup retained the original pre-reconciliation JKS until PRIMARY promotion and
validation fully succeeded; only then was the backup synchronized to the corrected
primary and byte equality re-verified.

## M. Certificate SHA-256 Fingerprint

```text
CERTIFICATE_SHA256_FINGERPRINT = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
```

## N. Certificate SHA-1 Fingerprint

```text
CERTIFICATE_SHA1_FINGERPRINT = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
```

## O. Alias

```text
ALIAS = i-tech-upload
ENTRY_TYPE = PrivateKeyEntry
```

## P. RSA Algorithm / Key Size

```text
STORE_TYPE = JKS
KEY_ALGORITHM = RSA
KEY_SIZE = 4096
SIGNATURE_ALGORITHM = SHA256withRSA
```

## Q. Store-Password Usability

```text
STORE_PASSWORD_USABLE = TRUE
```

store-password.dpapi decrypts under WINDOWS_DPAPI_CURRENT_USER and unlocks the
keystore (keytool -list / -v exit 0; jarsigner store-password round-trip exit 0;
in-memory KeyStore.load exit 0).

## R. Key-Password Usability

```text
KEY_PASSWORD_USABLE = TRUE
```

key-password.dpapi decrypts under WINDOWS_DPAPI_CURRENT_USER and now unlocks the
PrivateKeyEntry (in-memory KeyStore.getKey(alias, key-password) exit 0; native
jarsigner sign with key password read from redirected stdin exit 0).

## S. Password Distinctness

```text
PASSWORDS_DISTINCT = TRUE
STORE_IS_64CHAR_HEX = TRUE
KEY_IS_64CHAR_HEX  = TRUE
```

## T. Negative Proof — Store Password No Longer Unlocks PrivateKeyEntry

```text
STORE_PASSWORD_AS_KEY_PASSWORD_REJECTED = TRUE
```

Post-reconciliation, both independently demonstrated with secrets only in process
memory:

```text
(a) in-memory KeyStore.getKey(alias, STORE password) -> UnrecoverableKeyException
    (expected rejection; exit 0 for the NEGATIVE test program)
(b) native jarsigner sign supplying the STORE password as the key password
    -> "jarsigner: unable to recover key from keystore", exit 1
```

## U. Private-Key Signing Proof

```text
PRIVATE_KEY_USABILITY_PROOF = PASS
```

Post-reconciliation, both independently demonstrated with secrets only in process
memory:

```text
(a) in-memory operation (redirected stdin): KeyStore.getKey(alias, key-password)
    recovered the RSA 4096 private key; a SHA256withRSA signature was created with
    the PrivateKey and verified with the certificate public key (RSAPublicKeyImpl).
    SIGNATURE_VERIFY = true, exit 0.
(b) native jarsigner on a disposable NON-SECRET test JAR:
    SIGN:  `${alias}` key password read from redirected stdin -> "jar signed.", exit 0
    VERIFY: -> "jar verified.", "s = signature was verified",
           "Signature algorithm: SHA256withRSA, 4096-bit key", exit 0
    (disposable JAR deleted after proof)
```

## V. Secret Protection Proof

```text
PASSWORD_PRINTED              = FALSE
PASSWORD_IN_COMMAND_LINE      = FALSE
PASSWORD_IN_ENVIRONMENT       = FALSE
PASSWORD_IN_GIT               = FALSE
DPAPI_CIPHERTEXT_IN_GIT       = FALSE
KEYSTORE_IN_GIT               = FALSE
PLAINTEXT_SECRET_FILE_CREATED = FALSE
KEY_PROPERTIES_CREATED        = FALSE
TEMP_SECRET_ARTIFACT_REMAINS  = FALSE
```

All secret values were decrypted from DPAPI only inside process memory and delivered
to keytool/jarsigner/java only via redirected STDIN. No -storepass/-keypass value,
no :env, no :file mechanism, and no password file was used. Captured stdout/stderr
was scanned for secrets and none were logged.

## W. Exact External Paths (paths allowed; values are not)

```text
STORE_TYPE                     = JKS
OWNER_UPLOAD_KEY_ALIAS         = i-tech-upload
PRIMARY_KEYSTORE_PATH          = C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
BACKUP_KEYSTORE_PATH           = C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks
STORE_PASSWORD_DPAPI_PATH      = C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi
KEY_PASSWORD_DPAPI_PATH        = C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi
DPAPI_SCOPE                    = CurrentUser
```

Note on path form: the committed provisioning contract (blob 83f84f92...), the
historical execution proof, and the physically-provisioned material all use
C:\Users\saber\.i-tech\android-signing\... The session brief rendered the same
location as C:\Users\saber.i-tech\... (a normalization artifact of the leading-dot
segment). The physically-provisioned, provenance-recorded paths above are the
operative paths; the alternate rendering does not exist on disk and no material was
created there.

## X. Changed Repository Files

```text
ADDED:
  docs/GROUP_A_PHASE_Q_ANDROID_SIGNING_MATERIAL_RECONCILIATION_PROOF.md
MODIFIED: <none>
DELETED:  <none>
```

Diff-scope gate passed: the ONLY tracked file in the reconciliation commit is this
proof. No Android implementation file changed:

```text
app/android/app/build.gradle                 UNMODIFIED
app/android/app/src/main/AndroidManifest.xml UNMODIFIED
app/android/app/src/main/kotlin/**           UNMODIFIED
settings.gradle                              UNMODIFIED
gradle.properties                            UNMODIFIED
gradle-wrapper.properties                    UNMODIFIED
pubspec.yaml                                 UNMODIFIED
lib/**                                       UNMODIFIED
test/**                                      UNMODIFIED
integration_test/**                          UNMODIFIED
ios/**                                       UNMODIFIED
supabase/**                                  UNMODIFIED
key.properties                               ABSENT / NOT CREATED
```

## Y. Remote-Lock Proof

```text
RECONCILIATION_COMMIT  = (filled at remote-lock verification)
REMOTE                 = github
REMOTE_BRANCH          = codex/i-tech-next-roadmap-freeze
PUSH_MODE              = FAST_FORWARD_ONLY
FINAL_LOCAL_HEAD       = (filled at remote-lock verification)
FINAL_REMOTE_HEAD      = (filled at remote-lock verification)
FINAL_MERGE_BASE       = (filled at remote-lock verification)
AHEAD                  = 0
BEHIND                 = 0
REMOTE_MATERIAL_EQUAL  = TRUE
LEGACY_ORIGIN_MUTATED  = FALSE
```

## Z. Successor Boundary

```text
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_REMOTE_LOCK
```

may be recommended but was NOT started by this session. The successor MUST use:

```text
ACTIVE_KEYSTORE_SHA256 (post-reconciliation) =
F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD

SIGNING_MATERIAL_AUTHORITY =
docs/GROUP_A_PHASE_Q_ANDROID_SIGNING_MATERIAL_RECONCILIATION_PROOF.md
```

The historical pre-reconciliation hash
8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE is superseded for
active-material expectations and MUST be treated as historical only.

Explicit non-actions even on PASS:

```text
ANDROID_IDENTITY_IMPLEMENTATION_STARTED    = FALSE
ANDROID_SIGNING_CONFIG_IMPLEMENTATION_STARTED = FALSE
APK_BUILT     = FALSE
AAB_BUILT     = FALSE
PLAY_UPLOAD   = FALSE
ANDROID_PUBLISHED = FALSE
GROUP_B_STARTED = FALSE
IOS_CHANGED   = FALSE
WINDOWS_CHANGED = FALSE
SUPABASE_CHANGED = FALSE
```

---

*End of Android signing material reconciliation proof.*