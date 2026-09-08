# PHASE P — POST-GROUP-D ANDROID SIGNING CREDENTIAL RELATIONSHIP
## OWNER DECISION CORRECTION

> FAIL-CLOSED GOVERNANCE CORRECTION ARTIFACT.
> This session corrects a now-forensically-invalid credential-relationship decision
> recorded by the predecessor owner decision `POST_D_OD_K2_01 = A`.
> This is a governance-only session: no keystore mutation, no rekey, no key generation,
> no Android build, no Play Console contact, no implementation of source-code correction.
> Contains NO passwords, NO DPAPI ciphertext, NO private key material, NO keystore bytes.

---

## A. Session Identity

```text
SESSION =
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_CREDENTIAL_RELATIONSHIP_OWNER_DECISION_CORRECTION

SESSION_TYPE =
OWNER_DECISION_CORRECTION_ONLY

IMPLEMENTATION_AUTHORIZED_THIS_SESSION =
NO

ANDROID_BUILD_AUTHORIZED =
NO

KEYSTORE_MUTATION_AUTHORIZED =
NO

SUCCESSOR_EXECUTION_AUTHORIZED =
NO

RESULT =
PASS_PHASE_P_POST_GROUP_D_ANDROID_SIGNING_CREDENTIAL_RELATIONSHIP_OWNER_DECISION_CORRECTION_REMOTE_LOCKED
```

---

## B. Repository Identity

```text
ROOT =
C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze

BRANCH =
codex/i-tech-next-roadmap-freeze

AUTHORIZED_REMOTE =
github

AUTHORIZED_REMOTE_URL =
https://github.com/sabere342-ai/muaman.worktrees.git

FORBIDDEN_REMOTE =
origin  (OneDrive legacy remote — read-only reference; NOT contacted this session)

ORIGIN_CONTACTED =
NO
```

---

## C. Entry / Recovery Classification

Classification: **CASE_A_FRESH** with preserved blocked-session continuation.

Verified at entry:

```text
ENTRY_LOCAL_HEAD  = a19bf8c3256e378eddb51695f611fdd2ea698bf5
ENTRY_TRACKING_HEAD = a19bf8c3256e378eddb51695f611fdd2ea698bf5
ENTRY_GITHUB_HEAD = a19bf8c3256e378eddb51695f611fdd2ea698bf5
ENTRY_MERGE_BASE = a19bf8c3256e378eddb51695f611fdd2ea698bf5
ENTRY_AHEAD = 0
ENTRY_BEHIND = 0
```

Active Git-operation metadata check (all absent):

```text
MERGE_HEAD         = absent
CHERRY_PICK_HEAD   = absent
REVERT_HEAD        = absent
BISECT_LOG         = absent
index.lock         = absent
rebase-merge       = absent
rebase-apply       = absent
```

Entry graph contract satisfied: `LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE`,
`AHEAD = 0`, `BEHIND = 0`. This matches the binding predecessor baseline
`BASELINE_HEAD = a19bf8c3256e378eddb51695f611fdd2ea698bf5`.

The committed graph is clean and remote-locked; the working tree carries the
intentionally-preserved blocked-session residue (see §F). This does NOT invalidate
CASE_A_FRESH because the residue is proven blocked-session evidence, not
unauthorized tracked modification.

---

## D. Entry Remote-Lock Proof

Captured read-only before any modification:

```text
LOCAL_HEAD   = a19bf8c3256e378eddb51695f611fdd2ea698bf5
TRACKING_HEAD = a19bf8c3256e378eddb51695f611fdd2ea698bf5  (github/codex/i-tech-next-roadmap-freeze)
DIRECT_GITHUB_HEAD = a19bf8c3256e378eddb51695f611fdd2ea698bf5  (git ls-remote github)
MERGE_BASE    = a19bf8c3256e378eddb51695f611fdd2ea698bf5

AHEAD = 0
BEHIND = 0
```

Entry state: REMOTE_LOCKED (verified).

---

## E. Binding Predecessor Authority

Predecessor artifact (committed at baseline `a19bf8c`):

```text
PHASE_P_POST_GROUP_D_OWNER_BLOCKER_DECISION_RESOLUTION.md
```

Predecessor subject: resolution of the two owner blocker decisions
`POST_D_P_OD7_01` and `POST_D_OD_K2_01`.

Predecessor recorded the now-invalid credential relationship under
`POST_D_OD_K2_01 = A`:

```text
POST_D_OD_K2_01 =
A
DECISION_STATUS =
RESOLVED

PREFERRED_CREDENTIAL_MODEL =
KEY_PASSWORD_USES_THE_VALID_STORE_PASSWORD_SECRET_SOURCE

VALID_STORE_PASSWORD_WORKS_FOR_STORE =
YES

VALID_STORE_PASSWORD_WORKS_FOR_KEY =
YES

SEPARATE_CURRENT_KEY_PASSWORD_MATERIAL_WORKS =
NO

KEYPASS_EQUALS_STOREPASS_IN_EXISTING_KEYSTORE =
YES

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING =
NO
```

The predecessor ALSO recorded the correct identity-preservation contract
(`PRESERVE_EXISTING_KEYSTORE = YES`, `REPLACE_SIGNING_IDENTITY = NO`, etc.)
and the correct frozen keystore identity (see §H). Those identity clauses
remain authoritative and are NOT superseded by this correction.

---

## F. Preserved Blocked-Session Delta

The blocked implementation session
(`PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`,
SESSION_TYPE = `IMPLEMENTATION_ATTEMPT_GOVERNANCE_RECORD`) left an
uncommitted working-tree residue that is PRESERVED as forensic evidence.

Tracked residue at entry:

```text
M app/android/gradle/production-signing.gradle
```

This delta attempted to implement the now-superseded `POST_D_OD_K2_01 = A`
credential model by recovering the store-password DPAPI secret once and
feeding it to BOTH `storePassword` and `keyPassword`. It is FAIL-CLOSED
evidence: identity checks passed but private-key retrieval failed with
`UnrecoverableKeyException` because the recovered store secret is not the
PrivateKeyEntry protection password.

This session does NOT stage, commit, edit, reset, restore, or otherwise
touch this residue. It is left exactly as found for the corrective
implementation successor to resolve.

---

## G. Historical Rekey/Reconciliation Evidence

Authoritative historical reconciliation proof (committed):

```text
docs/GROUP_A_PHASE_Q_ANDROID_SIGNING_MATERIAL_RECONCILIATION_PROOF.md
```

Key historical facts (non-secret, committed evidence):

```text
PRE_RECONCILIATION_PRIMARY_SHA256 =
8AF622B5F14A61A475026EF2DE71566B51C5330C137A9BFE2FA600C2EF12F8EE

POST_RECONCILIATION_PRIMARY_SHA256 =
F97C6AB9C636C01D88C9D03D4A6092FA42C33A1575147174291AB6B1DB76E1CD
```

The historical reconciliation changed PrivateKeyEntry protection using a
`keytool -keypasswd` operation: the PrivateKeyEntry protection password was
re-keyed FROM the STORE password TO the already-provisioned key-password value.

Pre-reconciliation forensic state (recorded in the historical proof):

```text
CURRENT_PRIVATE_KEY_UNLOCK_WITH_STORE_PASSWORD =
TRUE  (pre-reconciliation)

CURRENT_PRIVATE_KEY_UNLOCK_WITH_KEY_PASSWORD =
FALSE  (pre-reconciliation)
```

Post-reconciliation forensic state (recorded in the historical proof):

```text
KEY_PASSWORD_USABLE =
TRUE  (key-password value now unlocks the key)

STORE_PASSWORD_AS_KEY_PASSWORD_REJECTED =
TRUE  (store password no longer unlocks the key)
```

The keystore on disk has SHA-256 = `f97c6ab9...` = POST_RECONCILIATION hash,
confirming the reconciliation was applied to the production keystore.

The on-disk production keystore is the **post-reconciliation** keystore:

```text
CURRENT = F97C6AB9...
```

Therefore the pre-reconciliation statement `KEYPASS_EQUALS_STOREPASS_IN_EXISTING_KEYSTORE = YES`
does NOT apply to the current post-reconciliation keystore.

---

## H. Current Keystore Identity

Frozen, verified, non-secret identity parameters.

```text
KEYSTORE_PATH =
C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks

BACKUP_KEYSTORE_PATH =
C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks

CURRENT_KEYSTORE_SHA256 =
f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd

BACKUP_KEYSTORE_SHA256 =
f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd

PRIMARY_BACKUP_BYTE_EQUAL =
YES

ALIAS =
i-tech-upload

CERTIFICATE_SHA256 =
48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27

CERTIFICATE_SHA1 =
83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05

KEY_ALGORITHM =
RSA

KEY_SIZE =
4096

STORE_TYPE =
JKS

STORE_PASSWORD_DPAPI_PATH =
C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi

KEY_PASSWORD_DPAPI_PATH =
C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi

DPAPI_SCOPE =
CurrentUser
```

These identity facts MUST remain frozen.

---

## I. Current Credential Relationship

Empirically proven current credential relationship (verified by the blocked
implementation session's Gradle configuration-only evaluation, which performed
all secret handling through fail-closed, in-process memory only):

```text
STORE_PASSWORD_DPAPI:
  successfully loads the current keystore       = YES
  unlocks current PrivateKeyEntry               = NO

KEY_PASSWORD_DPAPI:
  protects/unlocks current PrivateKeyEntry       = YES
```

The failure observed when attempting to use the store secret for both roles was:

```text
ANDROID_PROSIGNATION_FAIL_CLOSED:
signing secret did not unlock the private key entry

FAILURE POINT =
ks.getKey(UPLOAD_ALIAS, signingSecret.toCharArray())
-> UnrecoverableKeyException (signing secret is not the key-entry password)

KEYSTORE LOAD  = succeeded (signingSecret unlocked the keystore)
KEY RETRIEVAL  = FAILED (signingSecret did NOT unlock the PrivateKeyEntry)
```

Correct current relationship (authoritative):

```text
VALID_STORE_PASSWORD_WORKS_FOR_STORE =
YES

VALID_STORE_PASSWORD_WORKS_FOR_PRIVATE_KEY_ENTRY =
NO

VALID_KEY_PASSWORD_WORKS_FOR_PRIVATE_KEY_ENTRY =
YES

KEYPASS_EQUALS_STOREPASS_IN_CURRENT_KEYSTORE =
NO
```

Do not print or expose either password while recording this relationship.

---

## J. Contradiction in POST_D_OD_K2_01

The predecessor owner decision `POST_D_OD_K2_01 = A` (§E) recorded the
following credential-relationship clauses, which describe the PRE-reconciliation
keystore state and are therefore now forensically invalid for the current
on-disk keystore:

```text
PREFERRED_CREDENTIAL_MODEL =
KEY_PASSWORD_USES_THE_VALID_STORE_PASSWORD_SECRET_SOURCE

VALID_STORE_PASSWORD_WORKS_FOR_KEY =
YES

KEYPASS_EQUALS_STOREPASS_IN_EXISTING_KEYSTORE =
YES

SEPARATE_CURRENT_KEY_PASSWORD_MATERIAL_WORKS =
NO

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING =
NO
```

These clauses contradict the post-reconciliation reality established in §I:

- The PrivateKeyEntry protection password is the key-password value, NOT the
  store password.
- The store password loads the keystore but does NOT unlock the PrivateKeyEntry.
- The key-password DPAPI secret DOES unlock the PrivateKeyEntry.

The blocked implementation session empirically confirmed the contradiction:
it applied `POST_D_OD_K2_01 = A` (feeding the store secret to both fields) and
the fail-closed Gradle evaluation produced `UnrecoverableKeyException`.

This is a credential-wiring correction, not an identity migration. The signing
identity (alias, certificate, RSA-4096 key, keystore hash) is preserved
unchanged.

---

## K. Owner Corrective Decision POST_D_OD_K2_02

Record the following new owner decision.

```text
DECISION_ID =
POST_D_OD_K2_02

DECISION_STATUS =
RESOLVED

OWNER_SELECTION =
B

DECISION =
PRESERVE_CURRENT_POST_RECONCILIATION_KEYSTORE_AND_USE_ITS_ACTUAL_DISTINCT_CREDENTIAL_RELATIONSHIP
```

Binding credential model:

```text
ANDROID_SIGNING_STORE_PASSWORD_SOURCE =
STORE_PASSWORD_DPAPI_SOURCE

ANDROID_SIGNING_KEY_PASSWORD_SOURCE =
KEY_PASSWORD_DPAPI_SOURCE

STORE_PASSWORD_AND_KEY_PASSWORD_ARE_DISTINCT =
YES

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING =
YES
```

---

## L. Exact Supersession Semantics

The new decision does NOT invalidate the entire prior owner-decision artifact
`PHASE_P_POST_GROUP_D_OWNER_BLOCKER_DECISION_RESOLUTION.md`. It supersedes ONLY
the incorrect credential-relationship clauses associated with `POST_D_OD_K2_01`.

Specifically superseded (by `POST_D_OD_K2_02`):

```text
KEY_PASSWORD_USES_THE_VALID_STORE_PASSWORD_SECRET_SOURCE

VALID_STORE_PASSWORD_WORKS_FOR_KEY = YES

SEPARATE_CURRENT_KEY_PASSWORD_MATERIAL_WORKS = NO

KEYPASS_EQUALS_STOREPASS_IN_EXISTING_KEYSTORE = YES

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING = NO
```

Correct replacements (effective under POST_D_OD_K2_02):

```text
STORE_PASSWORD_SOURCE =
STORE_PASSWORD_DPAPI_SOURCE

KEY_PASSWORD_SOURCE =
KEY_PASSWORD_DPAPI_SOURCE

VALID_STORE_PASSWORD_WORKS_FOR_PRIVATE_KEY_ENTRY =
NO

VALID_KEY_PASSWORD_WORKS_FOR_PRIVATE_KEY_ENTRY =
YES

KEYPASS_EQUALS_STOREPASS_IN_CURRENT_KEYSTORE =
NO

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING =
YES
```

Everything else in the predecessor authority remains governed by its existing
authority unless explicitly changed here. In particular, all identity-preservation
clauses (`PRESERVE_EXISTING_KEYSTORE = YES`, `REPLACE_SIGNING_IDENTITY = NO`,
`GENERATE_NEW_UPLOAD_IDENTITY = NO`, `PRESERVE_EXISTING_ALIAS = YES`,
`PRESERVE_EXISTING_CERTIFICATE_IDENTITY = YES`), the `POST_D_P_OD7_01 = B`
sync-drain decision, and all closed-scope state are unchanged and remain
authoritative.

---

## M. Owner Intent — Why Option B Is Selected

The owner explicitly chooses preservation of the **current production upload
key material** over mutating the keystore merely to force password equality.

The selected direction preserves:

```text
CURRENT KEYSTORE
CURRENT PRIVATE KEY
CURRENT ALIAS
CURRENT CERTIFICATE
CURRENT RSA-4096 IDENTITY
CURRENT PRIMARY/BACKUP EQUALITY
CURRENT POST-RECONCILIATION KEYSTORE HASH
```

This is a credential-wiring correction, not an identity migration.

---

## N. Frozen Signing Identity

No identity mutation occurs in this session or authorized by this decision.

```text
KEYSTORE_REKEYED =
NO

KEYSTORE_REPLACED =
NO

KEYSTORE_MUTATED =
NO

NEW_UPLOAD_KEY_GENERATED =
NO

CERTIFICATE_CHANGED =
NO

ALIAS_CHANGED =
NO
```

The corrective direction (§K) keeps the distinct store and key DPAPI secret
sources. The corrective source-code correction that wires `storePassword` to
`STORE_PASSWORD_DPAPI_SOURCE` and `keyPassword` to `KEY_PASSWORD_DPAPI_SOURCE`
is deferred to the separately authorized successor implementation session
(§P). It is NOT started in this session.

---

## O. Secret Handling Constraints

This is a governance correction session. No secret handling occurs.
Constraints observed:

```text
PASSWORD_PRINTED              = NO
PASSWORD_IN_COMMAND_LINE      = NO
PASSWORD_IN_ENVIRONMENT       = NO
PASSWORD_IN_GIT               = NO
DPAPI_CIPHERTEXT_COMMITTED    = NO
PLAINTEXT_SECRET_FILE_CREATED = NO
SECRET_VALUE_PRESENT_IN_ARTIFACT = NO
```

The governance artifact records only non-secret metadata: keystore path,
keystore SHA-256, alias, certificate fingerprints, RSA key algorithm/size,
DPAPI file paths, DPAPI scope, and the credential-relationship relationship
(yes/no) — never secret values.

---

## P. Successor Authorization

If and only if this decision-resolution session completes and remote-locks
successfully, authorize exactly one successor:

```text
NEXT_AUTHORIZED_SESSION =
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION_CORRECTIVE_CONTINUATION
```

The future implementation session may correct `app/android/gradle/production-signing.gradle`
to use:

```text
storePassword <- STORE_PASSWORD_DPAPI_SOURCE
keyPassword   <- KEY_PASSWORD_DPAPI_SOURCE
```

while retaining the current production keystore identity and all fail-closed
identity checks (keystore SHA-256, alias, certificate fingerprints, RSA-4096,
primary/backup byte equality, key-password unlocks PrivateKeyEntry,
store-password does NOT unlock PrivateKeyEntry).

However:

```text
SUCCESSOR_IMPLEMENTATION_STARTED_THIS_SESSION =
NO
```

This session does NOT perform that correction.

---

## Q. Commit Evidence

Prepared only after all governance validation passed.

```text
COMMIT_MESSAGE        = docs: correct Android signing credential relationship owner decision
COMMIT_TYPE           = NORMAL (no amend, no history rewrite, no force)
STAGED_FILES          = ONLY PHASE_P_POST_GROUP_D_ANDROID_SIGNING_CREDENTIAL_RELATIONSHIP_OWNER_DECISION_CORRECTION.md
TRACKED_SOURCE_CHANGES = NONE
SIGNING_GRADLE_STAGED = NO
KEYSTORE_MUTATED      = NO
SECRET_FILE_STAGED    = NO
UNRELATED_FILE_STAGED = NO
GIT_ADD_DOT           = NO  (targeted single-file add only)
GIT_ADD_A             = NO
```

---

## R. Push Evidence

```text
PUSH_DESTINATION    = github
PUSH_URL            = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_BRANCH         = codex/i-tech-next-roadmap-freeze
PUSH_TYPE           = NORMAL_FAST_FORWARD
FORCE_PUSH          = NO
FORCE_WITH_LEASE    = NO
ORIGIN_CONTACTED    = NO
```

---

## S. Independent Remote-Lock Proof

To be filled at verification time after push (see Final State §T).

Required proof:

```text
FINAL_LOCAL_HEAD         = POST_PUSH_LOCAL_HEAD
FINAL_TRACKING_HEAD      = POST_PUSH_TRACKING_HEAD
FINAL_DIRECT_GITHUB_HEAD = POST_PUSH_DIRECT_GITHUB_HEAD
FINAL_MERGE_BASE         = POST_PUSH_FINAL_MERGE_BASE
FINAL_AHEAD              = 0
FINAL_BEHIND             = 0
FINAL_NORMAL_PUSH        = YES
FINAL_FORCE_PUSH         = NO
FINAL_ORIGIN_CONTACTED   = NO
FINAL_REMOTE_LOCK        = VERIFIED (local == tracking == direct-github == merge-base)
```

---

## T. Final State

```text
OWNER_DECISION_CORRECTION_STATUS =
RESOLVED

POST_D_OD_K2_02 =
B

SELECTED_MODEL =
PRESERVE_CURRENT_POST_RECONCILIATION_KEYSTORE_AND_USE_ITS_ACTUAL_DISTINCT_CREDENTIAL_RELATIONSHIP

STORE_PASSWORD_SOURCE =
STORE_PASSWORD_DPAPI_SOURCE

KEY_PASSWORD_SOURCE =
KEY_PASSWORD_DPAPI_SOURCE

STORE_PASSWORD_AND_KEY_PASSWORD_ARE_DISTINCT =
YES

KEYPASS_EQUALS_STOREPASS_IN_CURRENT_KEYSTORE =
NO

SEPARATE_KEY_PASSWORD_SECRET_REQUIRED_FOR_ACTIVE_SIGNING =
YES

CURRENT_KEYSTORE_SHA256_PRESERVED =
f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd

ALIAS_PRESERVED =
i-tech-upload

CERTIFICATE_SHA256_PRESERVED =
48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27

RSA_4096_IDENTITY_PRESERVED =
YES

KEYSTORE_MUTATED =
NO

SECRET_PRINTED =
NO

SECRET_COMMITTED =
NO

ANDROID_IMPLEMENTATION_STARTED =
NO
```

---

## U. Stop Boundary

This session is authoritatively complete upon successful commit and independent
remote-lock proof. It does NOT start the corrective implementation successor.

```text
COMMITTED_GOVERNANCE_STATE =
REMOTE_LOCKED

PRESERVED_UNCOMMITTED_BLOCKED_IMPLEMENTATION_DELTA =
PRESENT  (app/android/gradle/production-signing.gradle)

NEXT_AUTHORIZED_SESSION =
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION_CORRECTIVE_CONTINUATION

NEXT_SESSION_STARTED =
NO
```

---

*End of Android signing credential relationship owner decision correction.*
