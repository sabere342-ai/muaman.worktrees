# GROUP A / PHASE Q — ANDROID OWNER UPLOAD KEY SECURE PROVISIONING CONTRACT

```
SESSION = GROUP_A_PHASE_Q_ANDROID_OWNER_UPLOAD_KEY_SECURE_PROVISIONING_CONTRACT_RECORDING_REMOTE_LOCK
MODE    = OWNER_EXPLICIT_PROVISIONING_CONTRACT_GOVERNANCE_ONLY_FAIL_CLOSED
ROOT    = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH  = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE    = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
```

> THIS IS A GOVERNANCE-ONLY CONTRACT-RECORDING ARTIFACT.
> It records the owner's explicit provisioning contract for the Android upload key lineage.
> It does NOT generate, create, modify, encrypt, or provision ANY secret or keystore material.
> This session must NOT provision anything.
> It contains NO signing passwords, NO secret values, NO private key material, NO keystore contents,
> NO alias-encrypted payloads, NO Base64 secrets. Paths and mechanism identifiers only.

---

## A. Session Identity

```text
SESSION =
GROUP_A_PHASE_Q_ANDROID_OWNER_UPLOAD_KEY_SECURE_PROVISIONING_CONTRACT_RECORDING_REMOTE_LOCK

MODE =
OWNER_EXPLICIT_PROVISIONING_CONTRACT_GOVERNANCE_ONLY_FAIL_CLOSED
```

## B. Repository Identity

```text
ROOT     = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH   = codex/i-tech-next-roadmap-freeze
GITHUB_FETCH_URL = https://github.com/sabere342-ai/muaman.worktrees.git
GITHUB_PUSH_URL  = https://github.com/sabere342-ai/muaman.worktrees.git

PREDECESSOR_COMMIT = 786ba2a782af745f7dabbfd58fdca9f061b320f4
PREDECESSOR_ARTIFACT =
docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_OWNER_IDENTITY_AND_PLAY_SIGNING_DECISION.md
```

The predecessor established the Android identity and Play App Signing architecture:

```text
ANDROID_APPLICATION_ID = com.itech.storemanagement
ANDROID_NAMESPACE      = com.itech.storemanagement
ANDROID_DISPLAY_LABEL  = I Tech لإدارة المحلات
PLAY_APP_SIGNING_MODEL = MODEL_A
UPLOAD_KEY_CUSTODY     = Owner-controlled outside repository
SIGNING_SECRETS_IN_GIT = PROHIBITED
OD_K2_SECRET_PROVISIONING = WAITING_FOR_OWNER_SECURE_PROVISIONING
```

The present owner contract resolves ONLY the provisioning-contract gap. It does NOT
claim that actual secret provisioning has already occurred.

```text
OD_K2_PROVISIONING_CONTRACT = RECORDED
OD_K2_SECRET_PROVISIONING   = STILL_NOT_EXECUTED
ANDROID_SIGNING_PROVISIONING_COMPLETE = FALSE
```

## C. Owner Contract

The owner explicitly authorizes the following upload-key provisioning contract for
this product lineage. These are PATHS AND MECHANISM IDENTIFIERS ONLY. They are NOT
password values.

```text
OWNER_KEY_ALIAS =
i-tech-upload

OWNER_UPLOAD_KEYSTORE_PATH =
C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks

OWNER_STORE_PASSWORD_MECHANISM =
WINDOWS_DPAPI_FILE_CURRENT_USER

STORE_PASSWORD_DPAPI_FILE =
C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi

OWNER_KEY_PASSWORD_MECHANISM =
WINDOWS_DPAPI_FILE_CURRENT_USER

KEY_PASSWORD_DPAPI_FILE =
C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi

OWNER_KEYSTORE_BACKUP_LOCATION =
C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks

BACKUP_KEYSTORE =
C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks
```

Interpretation:

```text
PRIMARY_KEYSTORE =
owner-controlled Windows filesystem location outside Git

PASSWORD_SECRET_STORAGE =
Windows DPAPI protected to the provisioning Windows user

PASSWORD_VALUES_IN_GIT =
PROHIBITED

PASSWORD_VALUES_IN_GOVERNANCE_ARTIFACT =
PROHIBITED

KEYSTORE_IN_GIT =
PROHIBITED

KEYSTORE_BACKUP_IN_GIT =
PROHIBITED

KEY_ALIAS =
exactly i-tech-upload
```

No agent may reinterpret, shorten, rename, relocate, normalize, or substitute any
path or mechanism above.

## D. Explicit Security Rules

```text
SECRET_VALUES_RECORDED =
FALSE

STORE_PASSWORD_VALUE_RECORDED =
FALSE

KEY_PASSWORD_VALUE_RECORDED =
FALSE

KEYSTORE_CONTENT_RECORDED =
FALSE

KEYSTORE_GENERATED =
FALSE

DPAPI_SECRET_FILES_CREATED =
FALSE

KEY_PROPERTIES_CREATED =
FALSE

REPOSITORY_SECRET_WRITE =
FALSE
```

## E. Mechanism Semantics

```text
WINDOWS_DPAPI_FILE_CURRENT_USER =
Secret value must be encrypted using Windows DPAPI CurrentUser scope and persisted
only to the explicitly authorized .dpapi destination.

DPAPI_SECRET_FILE_CONTENT =
opaque encrypted bytes only

PLAINTEXT_SECRET_FILE =
PROHIBITED

PLAINTEXT_PASSWORD_ENVIRONMENT_PERSISTENCE =
PROHIBITED

PLAINTEXT_PASSWORD_COMMAND_LINE =
PROHIBITED

PLAINTEXT_PASSWORD_LOGGING =
PROHIBITED
```

The governance artifact does NOT contain actual passwords or generated encrypted
payloads. Paths and mechanism identifiers are governance terminology and are not
secret values.

## F. Backup Meaning

```text
PRIMARY_KEYSTORE =
C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks

BACKUP_KEYSTORE =
C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks

BACKUP_IS_OUTSIDE_REPOSITORY =
TRUE

BACKUP_PASSWORD_FILE_COPY =
NOT_AUTHORIZED_BY_THIS CONTRACT
```

This local backup is the authorized provisioning backup location for this phase. A
future separately governed offline/external disaster-recovery copy may be added
without changing the cryptographic identity of the upload key.

## G. Successor Authorization Boundary

```text
PROVISIONING_CONTRACT_RECORDED =
TRUE

PROVISIONING_EXECUTION_STARTED =
FALSE

PROVISIONING_EXECUTION_AUTHORIZED_BY_THIS_SESSION =
FALSE

ANDROID_IDENTITY_IMPLEMENTATION_AUTHORIZED_BY_THIS_SESSION =
FALSE

ANDROID_RELEASE_BUILD_AUTHORIZED_BY_THIS_SESSION =
FALSE

PLAY_UPLOAD_AUTHORIZED =
FALSE
```

The only allowed future work is a NEW separately authorized governed session:

```text
RECOMMENDED_NEXT =
GROUP_A_PHASE_Q_ANDROID_OWNER_UPLOAD_KEY_SECURE_PROVISIONING_EXECUTION
```

That successor may begin only after separate owner authorization. It is not started
automatically. Authorization is never inferred from silence.

---

## Post-Condition Meaning

Successful completion of this session means ONLY:

```text
OWNER_PROVISIONING_CONTRACT_RECORDED =
TRUE

OWNER_PROVISIONING_CONTRACT_REMOTE_LOCKED =
TRUE
```

It MUST NOT mean:

```text
KEYSTORE_CREATED         = FALSE
PASSWORD_CREATED         = FALSE
DPAPI_SECRET_CREATED     = FALSE
SIGNING_CONFIGURED       = FALSE
ANDROID_PACKAGE_MIGRATED = FALSE
AAB_BUILT                = FALSE
APK_BUILT                = FALSE
ANDROID_RELEASE_READY    = FALSE
PLAY_PUBLISHED           = FALSE
```

---

*End of Android owner upload key secure provisioning contract record.*