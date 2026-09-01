# GROUP A / PHASE Q — ANDROID FINAL RELEASE OWNER IDENTITY AND PLAY SIGNING DECISION

```
SESSION = GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_OWNER_IDENTITY_AND_PLAY_SIGNING_DECISION_RECORDING_REMOTE_LOCK
MODE    = OWNER_DECISION_RECORDING_GOVERNANCE_ONLY_FAIL_CLOSED
ROOT    = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH  = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE    = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
```

> THIS IS A GOVERNANCE-ONLY DECISION-RECORDING ARTIFACT.
> It records the owner's explicit decisions for the Android release lineage.
> It does NOT implement those decisions, does NOT configure signing, does NOT build, and does NOT publish.
> It contains NO signing passwords, NO private key material, NO keystore contents, NO aliases, NO Base64 secrets.

---

## A. Repository Identity

```
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze   ✓
BRANCH            = codex/i-tech-next-roadmap-freeze                     ✓
GITHUB_FETCH_URL  = https://github.com/sabere342-ai/muaman.worktrees.git ✓
GITHUB_PUSH_URL   = https://github.com/sabere342-ai/muaman.worktrees.git ✓
IDENTITY_VERIFIED = TRUE
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن
LEGACY_ORIGIN_MUTATED = NO
```

## B. Predecessor Commit

```
PREDECESSOR_FORENSIC_COMMIT = e2abeda2517c14af02d1d92e73e07f989b524c3d
PREDECESSOR_RESULT          = BLOCKED_ANDROID_RELEASE_GOVERNANCE_CONFLICT
                             (OD-K1 authority conflict + OD-K2 provisioning absent)
PREDECESSOR_BLOCKED_TOKEN   =
BLOCKED_GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_PREREQUISITE_NOT_AUTHORIZED
```

The predecessor was a prerequisite-gap report exposing missing owner decisions.
This successor session resolves the decision layer ONLY. It is not a failed
implementation and is not reinterpreted as one.

## C. Entry State

```
ENTRY_LOCAL_HEAD  = e2abeda2517c14af02d1d92e73e07f989b524c3d
ENTRY_REMOTE_HEAD = e2abeda2517c14af02d1d92e73e07f989b524c3d
ENTRY_MERGE_BASE  = e2abeda2517c14af02d1d92e73e07f989b524c3d
ENTRY_AHEAD       = 0
ENTRY_BEHIND      = 0
INDEX_STAGED      = <none>
TRACKED_WORKTREE  = CLEAN

UNTRACKED (classified, preserved, NOT staged, NOT deleted):
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
  GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
  MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
  delivery/I-TECH-Delivery-v1.0.0.zip
  supabase/.temp/
```

All gate checks passed; no repair/reset/stash/checkout/clean/merge/rebase/pull used.

## D. Explicit Owner Decision — OD-K1 (Android Identity)

The owner explicitly resolves the Android application identity as follows:

```text
ANDROID_APPLICATION_ID = com.itech.storemanagement

ANDROID_NAMESPACE = com.itech.storemanagement

ANDROID_NAMESPACE_RULE =
namespace MUST equal the permanent Android applicationId for this product lineage.

ANDROID_DISPLAY_LABEL = I Tech لإدارة المحلات
```

These values are FINAL for the Android release lineage and are recorded here as the
governance authority. They supersede all earlier competing/placeholder values for
future implementation, including:

```text
com.almuaman.muaman_store   # legacy/current implementation placeholder only
com.itech.store             # rejected as the final package identity
muaman_store                # placeholder application label
```

`com.itech.storemanagement` is CONFIRMED as the permanent canonical package identity.
No agent may reinterpret, shorten, normalize, translate, or replace this exact package identifier.

## E. Superseded Identity Authorities

Older documents and governance sources that still textually contain:

```text
com.itech.store
com.almuaman.muaman_store
muaman_store
```

are NOT silently edited by this session. Those historical references are recorded here
as SUPERSEDED for future implementation by the explicit owner decision in section D.
Reconciliation of implementation/governance sources, if required, belongs to the
separately authorized implementation/configuration successor session.

## F. Explicit Owner Decision — Play App Signing

```text
PLAY_APP_SIGNING_MODEL = MODEL_A

MODEL_A =
Google Play App Signing enabled for Play distribution,
with an owner-controlled upload key / upload keystore kept outside Git.

GOOGLE_PLAY_APP_SIGNING_KEY_CUSTODY =
Google Play App Signing

UPLOAD_KEY_CUSTODY =
Owner-controlled outside repository

UPLOAD_KEY_BACKUP_OWNERSHIP =
Owner

SIGNING_SECRETS_IN_GIT =
PROHIBITED
```

This decision authorizes ONLY the distribution/signing architecture. It does NOT
provide or invent:

* keystore bytes
* alias
* store password
* key password
* secret-store values
* certificate material
* Play Console credentials

## G. OD-K2 Provisioning Gap

```text
P-OD3_INTEGRATION_APPROVAL = APPROVED

PLAY_APP_SIGNING_MODEL = MODEL_A

OD_K2_ARCHITECTURE_DECISION = COMPLETE

OD_K2_SECRET_PROVISIONING = WAITING_FOR_OWNER_SECURE_PROVISIONING
```

Decision vs provisioning is explicit:

```text
OD_K1_APPLICATION_ID_DECIDED        = TRUE
OD_K1_NAMESPACE_DECIDED             = TRUE
OD_K1_DISPLAY_LABEL_DECIDED         = TRUE
PLAY_APP_SIGNING_MODEL_DECIDED      = TRUE

OWNER_UPLOAD_KEYSTORE_PROVIDED      = FALSE
KEY_ALIAS_PROVIDED                  = FALSE
STORE_PASSWORD_MECHANISM_PROVIDED   = FALSE
KEY_PASSWORD_MECHANISM_PROVIDED     = FALSE
KEYSTORE_BACKUP_LOCATION_PROVIDED   = FALSE

ANDROID_IDENTITY_OWNER_DECISION_COMPLETE        = TRUE
ANDROID_SIGNING_ARCHITECTURE_DECISION_COMPLETE  = TRUE
ANDROID_SIGNING_PROVISIONING_COMPLETE           = FALSE
ANDROID_RELEASE_IMPLEMENTATION_AUTHORIZED       = FALSE
```

This session DOES NOT claim:
`ANDROID_PRODUCTION_KEYSTORE_OWNER_PROVIDED = TRUE`.

## H. Implementation Prohibition

```text
ANDROID_IDENTITY_IMPLEMENTED = FALSE
ANDROID_PRODUCTION_SIGNING_CONFIG_MODIFIED = NO
ANDROID_KEYSTORE_GENERATED = NO
ANDROID_AAB_BUILT = NO
ANDROID_APK_BUILT = NO
ANDROID_PUBLISHED = NO
PLAY_STORE_UPLOAD = NO
```

Do NOT begin the package migration merely because the owner decision is now clear.
Implementation requires a NEW separately authorized session.

## I. Authorized Scope

This session created exactly ONE new governance artifact:
`docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_OWNER_IDENTITY_AND_PLAY_SIGNING_DECISION.md`

No other tracked file changed. No implementation file was modified:

```text
app/android/app/build.gradle                          UNMODIFIED
app/android/app/src/main/AndroidManifest.xml         UNMODIFIED
app/android/app/src/main/kotlin/**                   UNMODIFIED
app/android/key.properties                            ABSENT / NOT CREATED
gradle.properties                                     UNMODIFIED
settings.gradle                                      UNMODIFIED
pubspec.yaml                                         UNMODIFIED
lib/**                                               UNMODIFIED
test/**                                              UNMODIFIED
integration_test/**                                  UNMODIFIED
ios/**                                               UNMODIFIED
supabase/**                                          UNMODIFIED
```

No package directory renamed. No change to applicationId / namespace / android:label /
MainActivity package / signingConfigs / release signingConfig / versionCode / versionName.

## J. Secret-Material Preservation

```text
SECRET_VALUES_READ = NONE
KEYSTORE_PRIVATE_KEY_MATERIAL_READ = NONE
KEYSTORE_PRIVATE_KEY_MATERIAL_WRITTEN = NONE
KEYSTORE_PRIVATE_KEY_MATERIAL_COMMITTED = NONE
KEY_PROPERTIES_CREATED = NO
PASSWORDS_PRINTED = NO
ALIASES_INVENTED = NO
BASE64_SECRETS_CREATED = NO
REPOSITORY_HOLDS_SECRETS = NO
```

## K. Changed Files

```
ADDED:
  docs/GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_OWNER_IDENTITY_AND_PLAY_SIGNING_DECISION.md
MODIFIED: <none>
DELETED:  <none>
```

Diff gate passed: the only permitted tracked file is this decision artifact.

## L. Governance Commit (Remote Lock)

```
COMMIT            = (filled at remote-lock verification)
MESSAGE           = governance(android): lock owner identity and Play signing decisions
REMOTE            = github
REMOTE_BRANCH     = codex/i-tech-next-roadmap-freeze
PUSH_MODE         = FAST_FORWARD_ONLY
FINAL_LOCAL_HEAD  = (filled at remote-lock verification)
FINAL_REMOTE_HEAD = (filled at remote-lock verification)
FINAL_MERGE_BASE  = (filled at remote-lock verification)
AHEAD             = 0
BEHIND            = 0
REMOTE_MATERIAL_EQUAL = (filled at remote-lock verification)
```

## M. Successor-Session Rules

This session stops after remote lock. The only allowed future work is a NEW separately
authorized governed session:

```
RECOMMENDED_NEXT =
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION
```

That future session may begin only after separately proving secure signing provisioning
prerequisites. It is not started automatically. Authorization is never inferred from silence.

---

*End of owner identity and Play signing decision record.*