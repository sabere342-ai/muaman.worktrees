# PHASE P — POST-GROUP-D OWNER BLOCKER DECISION REQUEST

**SESSION_TYPE:** `GOVERNANCE / OWNER_DECISION_REQUEST ONLY` — produce a precise, committed, remotely-locked Owner Decision Request for the two already-established post-Group-D owner-gated blockers.

This session performs **NO implementation**, **NO production contact**, **NO build**, **NO migration**, and **NO activation**. It exists only to convert the two binding owner-gated blockers into explicit owner decision items and to lock the request artifact to the authorized `github` remote.

---

## A. Session Identity

```
SESSION                       = PHASE_P_POST_GROUP_D_OWNER_BLOCKER_DECISION_REQUEST
SESSION_TYPE                  = GOVERNANCE_ONLY / OWNER_DECISION_REQUEST_ONLY
IMPLEMENTATION_AUTHORIZED     = NO
PRODUCTION_CONTACT_AUTHORIZED = NO
BUILD_AUTHORIZED              = NO
```

## B. Repository Identity

```
ROOT              = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
FORBIDDEN_REMOTE  = origin
FORBIDDEN_REMOTE_TARGET = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (sacred / read-only)
ORIGIN_CONTACTED  = NO
```

## C. Entry Classification

```
ENTRY_CLASSIFICATION = CASE_A_FRESH
```

Entry is independently re-verified (not assumed from prior working memory):

- Local `HEAD` == tracking `HEAD` == direct GitHub `HEAD` == merge-base
- AHEAD = 0, BEHIND = 0
- No active Git operation (MERGE_HEAD, CHERRY_PICK_HEAD, REVERT_HEAD, BISECT_LOG,
  rebase-merge, rebase-apply, index.lock = all absent)
- Tracked worktree: CLEAN
- Index: EMPTY
- No stash applied or created during this session

## D. Entry Remote-Lock Proof

Verified via read-only Git checks at session entry:

```
LOCAL_HEAD        = e31bcc7cfd73972b0319241266ad456e007de41f
TRACKING_HEAD     = e31bcc7cfd73972b0319241266ad456e007de41f   (github/codex/i-tech-next-roadmap-freeze)
DIRECT_GITHUB_HEAD = e31bcc7cfd73972b0319241266ad456e007de41f   (git ls-remote github)
MERGE_BASE         = e31bcc7cfd73972b0319241266ad456e007de41f   (tracking..HEAD)
AHEAD             = 0
BEHIND            = 0
```

```
ENTRY_REMOTE_LOCK = VERIFIED (local == tracking == direct-github == merge-base)
```

## E. Binding Predecessor Authority

```
PREDECESSOR_COMMIT = e31bcc7cfd73972b0319241266ad456e007de41f
PREDECESSOR_REPORT = PHASE_P_POST_GROUP_D_CLOSEOUT_SUCCESSOR_SCOPE_DETERMINATION_REPORT.md
PREDECESSOR_TOKEN  = PASS_PHASE_P_POST_GROUP_D_CLOSEOUT_SUCCESSOR_SCOPE_DETERMINATION_REMOTE_LOCKED
```

Verified from committed tree content (`git show e31bcc7:PHASE_P_POST_GROUP_D_CLOSEOUT_SUCCESSOR_SCOPE_DETERMINATION_REPORT.md`):

```
NEXT_SUCCESSOR_SCOPE           = PHASE_P_POST_GROUP_D_CLOSEOUT_SEQUENCE
NEXT_IMPLEMENTATION_AUTHORIZED = NO

GROUP_B_STATE = CLOSED_REMOTE_LOCKED   (commit 154a970)
GROUP_D_STATE = CLOSED_REMOTE_LOCKED   (D1 8bf626d, D2 58f3224, D3 0266b84/HEAD)
D1_REOPENED   = NO
D2_REOPENED   = NO
D3_REOPENED   = NO
```

The predecessor establishes exactly two owner-gated blockers that prevent autonomous
continuation of the successor scope:

```
BLOCKER_1 = P-OD7  SYNC DRAIN ACTIVATION        (GATED/OFF — owner/release + Criterion 16)
BLOCKER_2 = OD-K2  ANDROID PRODUCTION SIGNING    (FAILED_BLOCKED_SIGNING_MATERIAL_MISMATCH)
```

No additional blocker is introduced by this session.

## F. Closed / Immutable Scope

The following scopes are CLOSED_REMOTE_LOCKED and MUST NOT be reopened:

```
PHASE O BASELINE                          = LOCKED (commit a0798a1)
PHASE P PLANNING + OWNER DECISIONS        = LOCKED (commit 2ca65bf)
GROUP A (SYNC DRAIN WIRING — A1..A8)      = CLOSED (drain wired, GATED/OFF, NOT activated)
GROUP B (S1–S12)                          = CLOSED_REMOTE_LOCKED (commit 154a970)
DRY-PLAN BACKUP/RESTORE PROOF             = CLOSED_REMOTE_LOCKED
MIGRATION 30 DEPLOYMENT                   = CLOSED_REMOTE_LOCKED (commits 1ba42a3, ad63e9b)
D1 (COST-CHANGE HISTORY)                  = CLOSED_REMOTE_LOCKED (impl 0d65c13, remediation 37d1efb, closeout 8bf626d)
D2 (OPENING BALANCES)                     = CLOSED_REMOTE_LOCKED (impl 95d0e50, closeout 58f3224)
D3 (ARBITRARY-PERIOD REPORTING)           = CLOSED_REMOTE_LOCKED (impl 04305e7, closeout 0266b84 = HEAD)
```

D1, D2, D3, and Group B are ancestors of HEAD (`git merge-base --is-ancestor` = True
for each, independently re-verified this session).

## G. Current Successor State

```
CURRENT_ENTRY_HEAD                 = e31bcc7cfd73972b0319241266ad456e007de41f
SUCCESSOR_SCOPE                    = PHASE_P_POST_GROUP_D_CLOSEOUT_SEQUENCE
SUCCESSOR_IMPLEMENTATION_AUTHORIZED = NO

DRAIN_STATE                         = GATED/OFF
GROUP_C_STATE                       = NOT_STARTED (BLOCKED — owner signing material OD-K2)
WS_10_REVERIFICATION                = PENDING
FULL_TEST_GATE                      = NOT_EXECUTED_POST_IMPL
RELEASE_CANDIDATES                  = NOT_STARTED
PHASE_P_FINAL_CLOSURE               = NOT_COMPLETE
DELIVERY                            = v1.0.0 ZIP EXISTS (sacred; SHA-256 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418)

POST_D_P_OD7_01                = PENDING_OWNER
POST_D_OD_K2_01                = PENDING_OWNER
```

## H. P-OD7 Read-Only Forensic Findings

### Committed source evidence (HEAD e31bcc7)

| File | Line(s) | Fact (VERIFIED from committed tree) |
|------|---------|--------------------------------------|
| `app/lib/config/app_config.dart` | 39–42 | `static const bool syncDrainEnabled = bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue: false);` — defaults FALSE |
| `app/lib/main.dart` | 247–278 | `SyncRuntime.instance.configure(...)` wires the real `SyncCloudOperationsTransport`; `drainEnabled: AppConfig.syncDrainEnabled` passed at line 277 |
| `app/lib/main.dart` | 251 | Comment: "the drain seam (AppConfig.syncDrainEnabled) defaults to FALSE" |
| `app/lib/sync/sync_runtime.dart` | 51 | Comment: drain seam "With it `false` (the default) the runtime is ... no network activity" |
| `app/lib/sync/sync_runtime.dart` | 84 | `bool _drainEnabled = false;` — internal default false |
| `app/lib/sync/sync_runtime.dart` | 101 | `bool get drainEnabled => _drainEnabled;` |
| `app/lib/sync/sync_runtime.dart` | 137 | `_drainEnabled = drainEnabled ?? false;` — configure() defaults to false if omitted |
| `app/lib/sync/sync_runtime.dart` | 176–182 | **Fail-closed guard:** `if (!_drainEnabled) { ... publishStatus(); return; }` — no worker created, zero cloud calls |
| `app/lib/sync/sync_runtime.dart` | 266–283 | `_drainEnabled = false` on stop; `active = _drainEnabled && (_worker?.isRunning ?? false)` |

### Committed test evidence (HEAD e31bcc7)

| File | Line(s) | Evidence |
|------|---------|----------|
| `app/test/sync/sync_cloud_operations_transport_test.dart` | 596–600 | `test('syncDrainEnabled production default remains FALSE (A1 dormant)')` — `expect(AppConfig.syncDrainEnabled, isFalse)` |
| `app/test/sync/a3_option_c_reconciliation_test.dart` | 667–669 | `'AppConfig.syncDrainEnabled stays false and the production transport ...'` — `expect(AppConfig.syncDrainEnabled, isFalse)` |
| `app/test/sync/a6_observability_test.dart` | 220 | `expect(AppConfig.syncDrainEnabled, isFalse)` |
| `app/test/sync/a6_observability_test.dart` | 360 | `expect(AppConfig.syncDrainEnabled, isFalse)` |
| `app/test/sync/idempotency_convergence_test.dart` | 891–893 | `'AppConfig.syncDrainEnabled stays false ...'` — `expect(AppConfig.syncDrainEnabled, isFalse)` |
| `app/test/sync/sync_runtime_test.dart` | 474–478 | `AppConfig.syncDrainEnabled which MUST be FALSE` — `expect(AppConfig.syncDrainEnabled, isFalse)` |

### Committed governance evidence

- `POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md` (HEAD):
  drain `GATED / OFF` — `app_config.dart:39`
  `bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue: false)`;
  activation is `OWNER / RELEASE ONLY`, not yet performed.
- `PHASE_P_POST_GROUP_D_CLOSEOUT_SUCCESSOR_SCOPE_DETERMINATION_REPORT.md` (HEAD, §D/E/§I):
  DRAIN_STATE = GATED/OFF; activation NOT executed; activation requires an
  owner-approved release build AND a proven Live Criterion 16 production probe.

### Untracked on-disk evidence (read-only, NOT staged or modified)

| File | Key finding |
|------|-------------|
| `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md` | RESULT = BLOCKED / NOT_ACTIVATED; drain GATED/OFF; 241/241 sync tests PASS; activation seam PROVEN (release-build `--dart-define=SYNC_DRAIN_ENABLED=true`); PRODUCTION_CONTACT = NO; ACTIVATION_ATTEMPTED = NO |
| `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md` | RESULT = PASS (forensic correction locked); drain GATED/OFF; Live Criterion 16 = PASS (previously proven by owner-authorized probe); no production contact this session |
| `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md` | RESULT = BLOCKED_LIVE_CRITERION_16_UNPROVABLE; Live Criterion 16 = UNPROVABLE (no production credentials in this environment); activated build NOT attempted; fail-closed STOP before build; ACTIVATION_MECHANISM_PROVEN = YES; DRAIN_PRE_STATE = GATED/OFF; DRAIN_POST_STATE = GATED/OFF |

### Effective drain state

```
SYNC_DRAIN_ENABLED_DEFAULT = FALSE (committed, app_config.dart:39-42)
DRAIN_RUNTIME_STATE        = GATED/OFF (fail-closed: sync_runtime.dart:176 returns before any cloud call when _drainEnabled is false)
DRAIN_ACTIVATION_ATTEMPTED = NO (this session and all prior post-Group-D sessions)
DRAIN_POST_STATE           = GATED/OFF (unchanged)
```

### The P-OD7 activation contract (distinguished concepts)

The repository establishes that P-OD7 cannot be activated by merely changing source code:

| Concept | Status |
|---------|--------|
| A. Owner approval to activate | NOT_SUPPLIED in this session |
| B. Release-build authority | NOT_SUPPLIED in this session |
| C. `--dart-define=SYNC_DRAIN_ENABLED=true` | PROVEN mechanism from source (`app_config.dart:39-42`), but NOT applied (would create an unshipped artifact; sacred delivery ZIP must not be overwritten) |
| D. Live Criterion 16 production proof | UNPROVABLE in this environment (no production credentials); was previously PROVEN by an owner-authorized session |
| E. Production credential/access requirement | ABSENT — no `SUPABASE_*`, no `DATABASE_*`, no `PGPASSWORD`, no `.env` (only placeholder `.env.example`), no CLI stored access token, no committed secrets |
| F. Fail-closed behavior if proof unavailable | STOP before build; drain stays GATED/OFF |

## I. POST_D_P_OD7_01 Owner Decision Request

```
DECISION_ID = POST_D_P_OD7_01
SUBJECT     = Authorize or defer the controlled P-OD7 sync-drain activation procedure
STATUS      = PENDING_OWNER
```

### Choice A — Authorize a separate controlled P-OD7 activation session

Owner elects to open a **separate, later, controlled activation/proof session** that
may:

1. Run a release build with `--dart-define=SYNC_DRAIN_ENABLED=true`, producing an
   activated binary **only if** it can be shipped via a governed path that does NOT
   overwrite the sacred delivery ZIP (`delivery/I-TECH-Delivery-v1.0.0.zip`,
   SHA-256 `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418`).
2. Supply the production read-only access required to prove Live Criterion 16
   (production `i-tech-production` schema, ref `ckruxrgppxxeqspxmyyd` —
   `*_v2` RPCs, `p_allow_oversell`, tenant/RLS/licensing/negative-stock boundaries).
3. Prove the post-activation test gate: `flutter analyze` 0/0, `dart format` green,
   `flutter test` all-passing, and the full sync suite (241 tests) passing with the
   drain seam engaged.

### Choice B — Keep sync drain GATED/OFF and defer activation

Owner elects to keep `SYNC_DRAIN_ENABLED = false` and defers P-OD7 drain activation.
The successor closeout sequence continues with: WS-10 re-verification, full test
gate, release candidate preparation (Windows), Phase-P final closure, delivery —
all without drain activation in this session.

### Critical note

Selecting Choice A authorizes ONLY a separate later activation/proof session. It
does **NOT** authorize activation in the current session. The owner must still
supply production credentials and a governed shipping path; the absence of either
keeps drain GATED/OFF.

### Prerequisites that any later activation session must prove before claiming PASS

```
[1] Owner approval explicitly authorizing the activated release build
[2] Live Criterion 16 production proof (schema/RPC presence in i-tech-production)
[3] Activated release binary built with --dart-define=SYNC_DRAIN_ENABLED=true
[4] Governed shipping path that does NOT overwrite the sacred delivery ZIP
[5] Post-activation full test gate (flutter analyze / dart format / flutter test)
[6] No production mutation during activation verification
```

## J. OD-K2 Read-Only Forensic Findings

### Committed source evidence (HEAD e31bcc7)

| File | Line(s) | Fact (VERIFIED from committed tree) |
|------|---------|--------------------------------------|
| `app/android/app/build.gradle` | 9 | `namespace = "com.itech.storemanagement"` (Phase Q PD-K1: final owner-locked identity) |
| `app/android/app/build.gradle` | 26–28 | `applicationId = "com.itech.storemanagement"`; comment: "Phase Q (PD-K1): final owner-locked applicationId" |
| `app/android/app/build.gradle` | 37–41 | `buildTypes.release { }` — comment: "Phase Q (PD-K2): production (upload) signing is provided by the fail-closed DPAPI-backed helper below. No debug fallback." |
| `app/android/app/build.gradle` | 51 | `apply from: "$rootDir/gradle/production-signing.gradle"` |
| `app/android/app/src/main/AndroidManifest.xml` | 14 | `android:label="I Tech لإدارة المحلات"` |
| `app/android/app/src/main/kotlin/com/itech/storemanagement/MainActivity.kt` | 1 | `package com.itech.storemanagement` |
| `app/android/gradle/production-signing.gradle` | 1–17 | Non-secret helper; fail-closed; NO passwords, NO DPAPI ciphertext, NO private key, NO keystore bytes; fails closed on any mismatch |
| `app/android/gradle/production-signing.gradle` | 29 | `ACTIVE_KEYSTORE_SHA256 = "f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd"` |
| `app/android/gradle/production-signing.gradle` | 30 | `UPLOAD_ALIAS = "i-tech-upload"` |
| `app/android/gradle/production-signing.gradle` | 31 | `CERT_SHA256 = "485e4187fb0bd53a295bb0fd36f174babcf2ffdabfd72014a314c1460cc0b927"` |
| `app/android/gradle/production-signing.gradle` | 32 | `CERT_SHA1 = "8343ef47a037549707125d02c07f138aa814e105"` |
| `app/android/gradle/production-signing.gradle` | 33–36 | Keystore & DPAPI file paths (see §K) |
| `app/android/gradle/production-signing.gradle` | 101 | `failClosed(!storePassword.equals(keyPassword), "store and key passwords are identical")` — requires store ≠ key password |
| `app/android/gradle/production-signing.gradle` | 105–107 | `failClosed(false, "key password did not unlock the private key entry")` — key password must unlock the private key |
| `app/android/gradle/production-signing.gradle` | 117–124 | `failClosed(storePasswordRejected, "store password unexpectedly unlocked the private key entry")` — store password must NOT unlock the key entry |

### Verified on-disk state (read-only, non-secret)

| Artifact | Path | State |
|----------|------|-------|
| Primary keystore | `C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks` | EXISTS; SHA-256 = `f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd` (matches committed `ACTIVE_KEYSTORE_SHA256`) |
| Backup keystore | `C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks` | EXISTS; byte-equal to primary |
| Store password DPAPI | `C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi` | EXISTS |
| Key password DPAPI | `C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi` | EXISTS |

### Certificate fingerprint (non-secret, from committed governance)

```
CERTIFICATE_SHA256 = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
CERTIFICATE_SHA1   = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
ALIAS              = i-tech-upload
OWNER              = CN=I Tech Android Upload Key, OU=Android Release, O=I Tech, L=Cairo, ST=Cairo, C=EG
KEY                = RSA 4096, SHA256withRSA
```

### Signing material blocker state (from untracked on-disk evidence)

File: `GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md`
(read from disk, 207 lines, contains NO secrets — paths, mechanism identifiers,
certificate fingerprints, and file hashes only)

```
RESULT                           = FAILED_BLOCKED_SIGNING_MATERIAL_MISMATCH
SIGNING_MATERIAL_CONTRACT        = independent key password via key-password.dpapi
ACTUAL_KEYSTORE_STATE            = private key password == STORE password (keypass==storepass)
KEY_PASSWORD_DPAPI_REJECTED      = YES (key-password.dpapi decrypts to valid 64-hex; keystore returns UnrecoverableKeyException)
STORE_PASSWORD_DPAPI_ACCEPTED    = YES (store-password.dpapi decrypts to valid value; works as both store AND key password)
CONTRADICTION                    = EXECUTION_PROOF_CLAIM KEY_PASSWORD_USABLE=TRUE (contradicted by material reality)
```

The committed `production-signing.gradle` enforces `failClosed(!storePassword.equals(keyPassword))`
at line 101. The actual keystore reality is `keypass==storepass`, which directly
contradicts the committed contract. No agent may reinterpret, shorten, rename,
relocate, normalize, or substitute any path or mechanism (per the governance
contract). Mutating the keystore's key password would break the locked
SHA-256 proof.

The on-disk keystore hash (`f97c6ab...`) matches the committed `ACTIVE_KEYSTORE_SHA256`.
An earlier failed-session report recorded a different on-disk keystore hash
(`8AF622B5...` uppercased), indicating the keystore was re-provisioned at some
point between that failed session and the current entry baseline. Regardless of
which keystore revision is present, the committed fail-closed contract at
`production-signing.gradle:101` (store ≠ key password) remains unmet if the
re-provisioned keystore also has `keypass==storepass`. The owner must reconcile
the contract with the material.

### No permitted debug-signing fallback

The committed `build.gradle` release block is empty (comment only); signing is
applied entirely by `production-signing.gradle` which fails closed on any
password/hash/fingerprint mismatch. There is no debug-signing fallback path.

## K. Signing Material Non-Secret Metadata (Safe to Record)

The following are non-secret file paths, hashes, and fingerprints only. No
password, no DPAPI ciphertext, no private key material, no keystore bytes are
recorded in this document.

```
PRIMARY_KEYSTORE_PATH  = C:\Users\saber\.i-tech\android-signing\primary\i-tech-upload.jks
BACKUP_KEYSTORE_PATH   = C:\Users\saber\.i-tech\android-signing\backup\i-tech-upload.jks
STORE_PASSWORD_DPAPI   = C:\Users\saber\.i-tech\android-signing\secrets\store-password.dpapi
KEY_PASSWORD_DPAPI     = C:\Users\saber\.i-tech\android-signing\secrets\key-password.dpapi
DPAPI_SCOPE            = WINDOWS_DPAPI_CURRENT_USER
UPLOAD_ALIAS           = i-tech-upload
KEY_ALGORITHM          = RSA 4096
KEY_SIGNATURE          = SHA256withRSA
PRIMARY_KEYSTORE_SHA256 = f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd  (on-disk == committed expected)
CERTIFICATE_SHA256     = 48:5E:41:87:FB:0B:D5:3A:29:5B:B0:FD:36:F1:74:BA:BC:F2:FF:DA:BF:D7:20:14:A3:14:C1:46:0C:C0:B9:27
CERTIFICATE_SHA1       = 83:43:EF:47:A0:37:54:97:07:12:5D:02:C0:7F:13:8A:A8:14:E1:05
```

### Secret provisioning mechanism (owner-controlled)

Secrets are provisioned solely through the **Windows DPAPI CurrentUser** `.dpapi`
files at the paths listed above. The `production-signing.gradle` script recovers
them via a captured child PowerShell process whose stdout is read directly into
Gradle process memory — values are never logged, never written to disk, never put
on a command line, never placed in an environment variable. The owner controls
re-provisioning of these `.dpapi` files outside this repository.

## L. POST_D_OD_K2_01 Owner Decision Request

```
DECISION_ID = POST_D_OD_K2_01
SUBJECT     = Resolve owner-controlled Android production signing material
STATUS      = PENDING_OWNER
```

### Choice A — Re-provision / reconcile the intended existing production upload key material

Owner action: reconcile the governance contract (`production-signing.gradle:101`
requires `storePassword != keyPassword`) with the actual keystore material where
`keypass==storepass`.

Permitted under a new owner authorization:
- **(a)** Record that the private key is password-protected by the store password
  (`keypass==storepass`) and feed the key password from the SAME CurrentUser DPAPI
  store file (`store-password.dpapi`) — no keystore mutation; this requires an
  owner-decision amendment to the committed fail-closed contract.
- **(a-alt)** Re-provision the keystore so the key has a distinct password, with
  the new key password stored in `key-password.dpapi` (new DPAPI file, owner
  provisioned) and the keystore re-locked to the same alias/certificate. The
  committed `ACTIVE_KEYSTORE_SHA256` would be updated to the new keystore hash
  under a separately authorized, owner-approved amendment.

Both sub-options require a **separately authorized reconciliation session** —
not this session.

### Choice B — Provide a separate owner decision for a different signing-key recovery or replacement path

Owner elects a path not listed in (A), e.g. providing an entirely new owner-
controlled upload key. This requires explicit owner authority and **must not**
occur in this session. Key replacement may interact with Google Play upload-key
rules (App-Signing-by-Google-Play key upgrades) and existing app identity
(`com.itech.storemanagement`); the owner must document the Play-key interaction
and authorize separately.

### Critical note

Choice A or B does NOT authorize key replacement in this session. The owner must
explicitly approve any keystore mutation or DPAPI re-provisioning under a new
authority. The committed SHA-256 proof (`f97c6ab...`) and the fail-closed
contract (`production-signing.gradle:101`) must be satisfied by the owner's
resolution.

## M. Secret Handling Contract

Owner secrets must NEVER be committed to Git. Examples include:

```
KEYSTORE PASSWORD           (store-password.dpapi plaintext)
KEY PASSWORD               (key-password.dpapi plaintext)
PRIVATE KEY                (from i-tech-upload.jks)
RAW DPAPI PLAINTEXT        (decrypted .dpapi contents)
GOOGLE PLAY CREDENTIALS
SUPABASE PRODUCTION CREDENTIALS
SERVICE ROLE KEY
ACCESS TOKEN
```

This repository artifact records ONLY:
- Decision state (PENDING_OWNER)
- Expected secret location/mechanism (Windows DPAPI CurrentUser paths)
- Verification outcome (keystore hash, certificate fingerprints, key algorithm)
- Non-secret metadata (file paths, hashes, fingerprints, DPAPI scope)
- Owner authorization references

**No secret value** appears in this document. No `.dpapi` file contents are
printed. No password is printed. No keystore is committed.

## N. Canonical Ordering Preservation

The canonical post-Group-D closeout ordering is preserved verbatim from committed
authority (`POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md`
§M/L and `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_...md`):

```
Group-A drain closure → Group B → Group D → Group C + OD-K2 → WS-10 seal
→ full test gate → release candidates → manual acceptance
→ Phase-P final closure → delivery
```

Owner order (committed `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_...md`):

```
GROUP_B → GROUP_D → REMAINING_EXPLICITLY_AUTHORIZED_NON_RELEASE_SCOPES
→ FINAL_STABILIZATION → RELEASE_FREEZE → FRESH_FINAL_ANDROID_RELEASE_CANDIDATE
→ FRESH_BUILD_SIGNING_RELEASE_PROOF → PLAY_RELEASE_GOVERNANCE
→ RELEASE_PUBLISH → DELIVERY → POST_P
```

Both Group B and Group D are CLOSED_REMOTE_LOCKED. P-OD7 (drain) and OD-K2
(Android signing) are the two remaining owner-gated blockers in their canonical
positions. No reordering is performed.

```
ROADMAP_REORDERED      = NO
SUCCESSOR_SCOPE_CHANGED = NO
IMPLEMENTATION_STARTED  = NO
```

## O. Explicit Non-Authorization

This session performs NO implementation, NO activation, NO release build, NO
migration, NO production contact, and NO force push.

```
GROUP_C_IMPLEMENTATION_AUTHORIZED           = NO
GROUP_C_IMPLEMENTATION_STARTED              = NO
P_OD7_ACTIVATION_AUTHORIZED                 = NO
P_OD7_ACTIVATION_ATTEMPTED                  = NO
ANDROID_RELEASE_BUILD_ATTEMPTED             = NO
SYNC_DRAIN_STATE                            = GATED/OFF
PRODUCTION_CONTACT_AUTHORIZED              = NO
PRODUCTION_CONTACTED                        = NO
PRODUCTION_MUTATED                          = NO
MIGRATION_CREATED                           = NO (Migration 31 = ABSENT)
MIGRATION_APPLIED                           = NO
SUCCESSOR_IMPLEMENTATION_AUTHORIZED         = NO
SUCCESSOR_IMPLEMENTATION_STARTED            = NO
WS_10_EXECUTION_STARTED                     = NO
FULL_REGRESSION_GATE_STARTED                = NO
PHASE_P_FINAL_CLOSURE_STARTED               = NO
DELIVERY_PREPARED                           = NO
POST_P_STARTED                              = NO
NEXT_IMPLEMENTATION_AUTHORIZED              = NO
```

## P. Owner Response Contract

The owner may answer using the following copy/paste-safe structure:

```text
POST_D_P_OD7_01 =
A | B

POST_D_OD_K2_01 =
A | B

OWNER_NOTES =
<optional non-secret instructions>
```

Where:
- `POST_D_P_OD7_01 = A` authorizes a separate controlled P-OD7 activation session.
- `POST_D_P_OD7_01 = B` keeps sync drain GATED/OFF and defers activation.
- `POST_D_OD_K2_01 = A` authorizes re-provisioning/reconciliation of the intended
  existing signing material.
- `POST_D_OD_K2_01 = B` authorizes a separately approved different signing-key
  recovery/replacement path.

No passwords, DPAPI files, keystore bytes, or private keys should be pasted into
Git governance documents. Secure provisioning of secrets must occur through the
Windows DPAPI CurrentUser mechanism (`C:\Users\saber\.i-tech\android-signing\secrets\`)
outside this repository.

## Q. Next Session Rules

The only legitimate successor to this session is a **separately authorized owner
decision resolution session** after the owner supplies the required decisions
(`POST_D_P_OD7_01` and `POST_D_OD_K2_01`).

```
NEXT_SESSION_AUTHORIZED = OWNER_DECISION_RESOLUTION_ONLY_AFTER_OWNER_INPUT
NEXT_IMPLEMENTATION_AUTHORIZED = NO
```

No successor implementation is begun autonomously. Per `AGENTS.md` §29 (No
Autonomous Successor Work) and §11 (Owner Decisions): when an owner decision is
PENDING and documented as blocking implementation, STOP before implementation.

## R. Git Delta

```
STAGED_FILES = ONLY PHASE_P_POST_GROUP_D_OWNER_BLOCKER_DECISION_REQUEST.md
TRACKED_SOURCE_CHANGES   = NONE
TRACKED_TEST_CHANGES     = NONE
TRACKED_MIGRATION_CHANGES = NONE
TRACKED_ANDROID_CHANGES  = NONE
TRACKED_PRODUCTION_CHANGES = NONE
GIT_ADD_DOT              = NO  (targeted single-file add only)
GIT_ADD_A                = NO
```

The pre-existing untracked residue (8 root-level files, 1 delivery file, 2
supabase subdirectories) is preserved and NOT staged.

## S. Commit

```
COMMIT_MESSAGE = docs: request post-Group-D owner blocker decisions
COMMIT_TYPE    = NORMAL (no amend, no history rewrite, no force)
COMMIT_AUTHOR  = Islam Saber <saber@muaman.local>
```

(To be populated after execution.)

## T. Push

```
PUSH_DESTINATION = github
PUSH_BRANCH       = codex/i-tech-next-roadmap-freeze
PUSH_TYPE         = NORMAL FAST-FORWARD
FORCE_PUSH        = NO
ORIGIN_CONTACTED  = NO
```

(To be populated after execution.)

## U. Final Remote-Lock Proof

(To be independently verified via `git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`
after push; expected LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE, AHEAD=0, BEHIND=0.)

## V. Final State

```
OWNER_DECISION_REQUEST          = COMPLETE
POST_D_P_OD7_01                 = PENDING_OWNER
POST_D_OD_K2_01                 = PENDING_OWNER
P_OD7_ACTIVATION_AUTHORIZED     = NO
ANDROID_SIGNING_RECONCILIATION_AUTHORIZED = NO
GROUP_C_IMPLEMENTATION_AUTHORIZED = NO
SUCCESSOR_IMPLEMENTATION_AUTHORIZED = NO
PRODUCTION_CONTACT_AUTHORIZED   = NO
```

```
D1_REOPENED = NO
D2_REOPENED = NO
D3_REOPENED = NO
GROUP_B_REOPENED = NO
GROUP_C_IMPLEMENTATION_STARTED = NO
P_OD7_ACTIVATION_ATTEMPTED = NO
SYNC_DRAIN_STATE = GATED/OFF
ANDROID_RELEASE_BUILD_ATTEMPTED = NO
PRODUCTION_CONTACTED = NO
PRODUCTION_MUTATED = NO
MIGRATION_CREATED = NO
MIGRATION_APPLIED = NO
SUCCESSOR_IMPLEMENTATION_STARTED = NO
ORIGIN_CONTACTED = NO
FORCE_PUSH = NO
```
