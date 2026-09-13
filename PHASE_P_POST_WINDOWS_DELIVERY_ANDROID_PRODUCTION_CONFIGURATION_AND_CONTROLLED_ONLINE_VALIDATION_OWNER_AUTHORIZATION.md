# PHASE P — POST-WINDOWS-DELIVERY ANDROID PRODUCTION CONFIGURATION AND CONTROLLED ONLINE VALIDATION — OWNER AUTHORIZATION

> GOVERNANCE / OWNER-AUTHORIZATION-ONLY SESSION.
> This artifact records the Owner's explicit, binding decisions that authorize the
> proposed successor phase ON PAPER ONLY.
>
> THIS SESSION MUST NOT START THE SUCCESSOR.
>
> No build, no install, no device mutation, no production action, no Supabase
> mutation, no Play action, no schema/code change, and no version change is
> performed in this session. Only read-only repository forensics, a final
> documentation review, the single governance document below, one commit to
> `github`, and Remote-Lock verification are executed.
>
> Contains NO passwords, NO DPAPI ciphertext, NO private key material, NO
> keystore bytes, NO Base64 secrets, NO Supabase service-role key, NO real
> Supabase URL, NO real anon/publishable key value, NO access tokens, and NO Play
> credentials. Paths, mechanism identifiers, hashes, and redacted/derived facts
> only.

---

## A. Session Identity and Result

```text
SESSION =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_OWNER_AUTHORIZATION

SESSION_CLASS = OWNER_AUTHORIZATION_GOVERNANCE_ONLY
PURPOSE       = Record the Owner's explicit decisions governing the proposed
                successor phase. Authorizes the successor ON PAPER ONLY.
SUCCESSOR_EXECUTION_STARTED = NO
```

```text
OWNER_DECISION      = APPROVE
AUTHORIZED_SUCCESSOR =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION
AUTHORIZED_SUCCESSOR_COUNT = 1
SUCCESSOR_STARTED   = NO
PRODUCTION_ACTION   = NONE
SUPABASE_PRODUCTION_MUTATION = NONE
ANDROID_PRODUCTION_CONFIGURATION_IMPLEMENTATION_STARTED = NO
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
DEVICE_MUTATION     = NONE
PLAY_STORE_ACTION   = NONE
OD7_SYNC_DRAIN_ACTIVATION = NONE
TAG_CREATED         = NO
ORIGIN_CONTACTED    = NO
```

---

## B. Repository Identity (VERIFIED from current repository this session)

```text
REPOSITORY_ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR           = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree; .git is NOT a directory)
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github   https://github.com/sabere342-ai/muaman.worktrees.git (VERIFIED)
FORBIDDEN_REMOTE  = origin   C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن
                    (read from git config locally ONLY to prove identity; NEVER contacted)
TRACKING_BRANCH   = github/codex/i-tech-next-roadmap-freeze
```

```text
LOCAL_HEAD         = cae3e086c486fc6a0169eea7279701c28d4a7151
TRACKING_HEAD      = cae3e086c486fc6a0169eea7279701c28d4a7151 (git for-each-ref, refs/remotes/github)
DIRECT_GITHUB_HEAD = cae3e086c486fc6a0169eea7279701c28d4a7151 (git ls-remote github, read-only)
MERGE_BASE         = cae3e086c486fc6a0169eea7279701c28d4a7151
AHEAD              = 0
BEHIND             = 0
HEAD_SUBJECT       = docs: close android smoke and plan production validation
ACTIVE_GIT_OP      = NONE (MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG /
                           rebase-merge / rebase-apply / index.lock all verified ABSENT)
STAGED             = 0
TRACKED_MODIFIED   = 0
TRACKED_DELETED    = 0
STASH              = 1 entry present, PRESERVED, NOT TOUCHED, NOT APPLIED
                     (stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration:
                      283ff9d MUAMAN-12: implement local user roles and sales-only access)
```

Untracked residue inventory (PRESERVED untouched, NOT staged, NOT committed):

```text
Continue
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.branches/
supabase/.temp/
```

No deletion, clean, normalization, relocation, staging, restore, or rewrite was
applied to any of these pre-existing residue items.

---

## C. Binding Predecessor

The direct predecessor is the current committed HEAD:

```text
cae3e086c486fc6a0169eea7279701c28d4a7151
docs: close android smoke and plan production validation
```

It carries the two committed governance artifacts below, BOTH read completely by
this session before drafting this authorization:

```text
1. PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_VALIDATION_CLOSEOUT.md
   (records the private smoke PASS and its exact limits K)

2. PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_PLAN.md
   (records the plan; its §U enumerates REQUIRES_OWNER_DECISION items 1-8 plus #P and #V)
```

Planning result recorded by the predecessor (reported, not re-computed):

```text
PASS_PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_CLOSEOUT_AND_PRODUCTION_CONFIGURATION_PLANNING
OWNER_DECISIONS_REQUIRED = YES
```

This Owner-authorization session EXISTS to resolve those required decisions. The
Owner decisions in §G below resolve each plan §U item explicitly:

| Plan §U decision | Resolved by |
|---|---|
| #1 environment | OD-PROD-01 |
| #2 identity/shop | OD-PROD-02 |
| #3 production writes | OD-PROD-03 |
| #4 clean vs upgrade on f0deca9 | OD-PROD-04 |
| #5 reuse existing production test data | OD-PROD-05 |
| #6 paid-tier vs trial-only | OD-PROD-06 |
| #7 production sync mutation | OD-PROD-07 |
| #8 AAB / Play intent | OD-PROD-08 |
| OPTIONAL #P config supply | OD-PROD-09 + OD-PROD-10 |
| OPTIONAL #V version identity | OD-PROD-11 |

The technical findings of both predecessor documents were read and are NOT
replaced by assumptions. No plan finding was contradicted; all findings are
incorporated as recorded.

---

## D. Entry Forensic Evidence (VERIFIED this session)

All lineage values verified against live repository and direct GitHub evidence:

```text
EXPECTED_ROOT_MATCH      = YES
EXPECTED_GIT_DIR_MATCH   = YES (linked worktree)
BRANCH                   = codex/i-tech-next-roadmap-freeze
LOCAL_HEAD               = cae3e086c486fc6a0169eea7279701c28d4a7151
LOCAL_HEAD_SUBJECT       = docs: close android smoke and plan production validation
TRACKING_HEAD            = cae3e086c486fc6a0169eea7279701c28d4a7151
DIRECT_GITHUB_HEAD       = cae3e086c486fc6a0169eea7279701c28d4a7151
MERGE_BASE               = cae3e086c486fc6a0169eea7279701c28d4a7151
AHEAD                    = 0
BEHIND                   = 0
STAGED                   = 0
TRACKED_MODIFIED         = 0
TRACKED_DELETED          = 0
UNTRACKED_RESIDUE        = inventoried (see §B), preserved untouched
STASH                    = preserved, not applied/dropped/created
MERGE_HEAD               = ABSENT
CHERRY_PICK_HEAD         = ABSENT
REVERT_HEAD              = ABSENT
BISECT_LOG               = ABSENT
rebase-merge             = ABSENT
rebase-apply             = ABSENT
index.lock               = ABSENT
ACTIVE_GIT_OPERATION     = NONE
UNEXPECTED_MUTATION      = NONE
ORIGIN_CONTACTED         = NO (config read only to prove identity)
```

---

## E. Entry Classification

```text
ENTRY_CLASSIFICATION = CASE_B_EXPECTED_BENIGN_RESIDUE
```

Canonical identity (root / git-dir / branch / HEAD / tracking / direct-GitHub /
merge-base / ahead=0 / behind=0) is EXACT. No tracked modification, deletion, or
staged change exists. No active Git operation. Only the previously documented,
pre-existing untracked residue is present and is PRESERVED untouched. This
matches the predecessor sessions' classification convention.

No STOP classification applies (not CASE_C, CASE_D, or CASE_E).

---

## F. Owner Authorization Status

```text
OWNER_AUTHORIZATION_STATUS = APPROVED_AND_BINDING
SCOPE                       = GOVERNANCE-ONLY RECORDING OF DECISIONS
SUCCESSOR                   = AUTHORIZED ON PAPER ONLY
SUCCESSOR_EXECUTION_STARTED = NO
```

The decisions in §G are recorded verbatim in substance and are BINDING on any
future execution session that starts the authorized successor. A recommended or
tentative option was never silently converted to approval; each decision below
is an explicit Owner decision.

---

## G. Binding OD-PROD Owner Decisions

### OD-PROD-01 — VALIDATION ENVIRONMENT

```text
DECISION = APPROVE
PRODUCTION_ENVIRONMENT      = AUTHORIZED_FOR_NARROW_CONTROLLED_TESTING
CUSTOMER_PRODUCTION_DATA    = FORBIDDEN
```

The controlled online validation successor is authorized to use the REAL
Supabase Production environment, BUT ONLY through an Owner-controlled dedicated
test tenant / test identity / test data boundary. REAL CUSTOMER TENANTS AND
CUSTOMER DATA ARE OUT OF SCOPE. No unrelated production tenant may be read,
changed, probed, repaired, cleaned, or used as test data.

Resolves plan §U #1 (environment = real production with Owner-controlled test
tenant).

### OD-PROD-02 — TEST IDENTITY AND TEST SHOP

```text
DECISION = APPROVE_DEDICATED_TEST_IDENTITY
```

The successor must use a dedicated I Tech-controlled test identity and test
shop. Preferred rule:

- If a clearly documented, dedicated, Owner-controlled production TEST
  identity/shop already exists and is proven isolated from customer data, it
  may be reused.
- Otherwise, the successor is authorized to create exactly the minimum dedicated
  production test identity/shop necessary for controlled validation.

It MUST NOT reuse a real customer account/shop merely for convenience. Naming
must make the test nature obvious where supported, e.g.:

```text
I Tech Android Validation
I Tech Production Test
```

or repository-compatible equivalent. Do not expose personal secrets in
governance evidence.

Resolves plan §U #2 (new dedicated test identity, or reuse of a proven dedicated
one — never a real customer).

### OD-PROD-03 — PRODUCTION WRITE AUTHORIZATION

```text
DECISION = APPROVE_NARROWLY_SCOPED_TEST_TENANT_WRITES
MINIMUM-WRITE PRINCIPLE = REQUIRED
```

The future successor is authorized to perform ONLY production writes strictly
necessary to establish and validate the dedicated test tenant. Allowed classes,
subject to repository architecture and RLS:

- dedicated test Auth identity creation if required
- dedicated test shop creation if required
- minimum tenant membership/ownership records
- controlled device registration/trust records
- server-controlled Trial initialization
- minimum reversible test-domain records required to prove application flow
- ordinary synchronization records belonging solely to the dedicated test
  tenant, if required by the authorized validation flow

NOT AUTHORIZED:

- writes to existing customer shops
- bulk updates / bulk deletes
- data migrations
- schema changes
- RLS changes / Auth policy changes
- production cleanup campaigns
- mass device actions
- paid-subscription activation
- arbitrary license issuance
- production admin/service-role operations from the Android client
- any write outside the dedicated test tenant

Every production mutation in the successor must have an explicit validation
purpose and an evidence trail.

Resolves plan §U #3 (narrowly scoped production writes, list above).

### OD-PROD-04 — INSTALL STRATEGY

```text
DECISION = FRESH_INSTALL_FIRST
DEVICE_SERIAL = f0deca9
UPGRADE_VALIDATION = NOT PART OF THE PRIMARY PASS GATE
```

Primary physical validation device remains `f0deca9`. The future successor is
authorized, when execution is separately started, to perform a controlled
fresh-install test of `com.itech.storemanagement` on device `f0deca9`. Fresh
install comes BEFORE upgrade validation. Any uninstall/clear operation must:

- target ONLY `com.itech.storemanagement`
- target ONLY device `f0deca9`
- capture relevant pre-state evidence first
- never use broad device/package cleanup

Upgrade testing becomes a later, separately governed validation after the
fresh-production-connected flow passes. THIS CURRENT OWNER-AUTHORIZATION SESSION
MUST NOT TOUCH THE DEVICE.

Resolves plan §U #4 (clean/fresh install first).

### OD-PROD-05 — TEST DATA

```text
DECISION = CREATE_DEDICATED_TEST_DATA
```

Do not reuse real customer/business data. The future successor may create
minimum synthetic/reversible data inside the dedicated Owner-controlled test
shop. Test data should:

- be obviously synthetic
- belong only to the test tenant
- be small
- be deterministic where practical
- be reversible
- avoid real customer names/numbers/private information
- allow tenant/RLS/sync/application behavior validation

No broad production cleanup is authorized. Deletion/cleanup of the dedicated
synthetic test data may occur only if clearly safe, tenant-scoped, and part of
the explicitly authorized execution contract.

Resolves plan §U #5 (create dedicated test data; no reuse of customer data).

### OD-PROD-06 — LICENSING / ENTITLEMENT SCOPE

```text
DECISION = TRIAL_ONLY_FIRST
TRIAL_DURATION       = 14 days  (product rule to validate from canonical implementation)
TRIAL users          = 1
TRIAL devices        = 1
TRIAL offline grace  = 0 days
```

The next controlled production-connected validation must test the
server-controlled Trial flow FIRST. The future successor may validate Trial
initialization, entitlement resolution, device association, and trial-state
behavior for the dedicated test tenant.

NOT AUTHORIZED during this successor:

- real payment / paid subscription purchase / real billing transaction
- manual conversion to Starter / Professional / Enterprise
- paid entitlement mutation merely to expand test coverage

Paid-tier validation requires a later explicit Owner authorization unless it can
be proven purely read-only without modifying production state.

Resolves plan §U #6 (TRIAL only first).

### OD-PROD-07 — SYNC AUTHORIZATION

```text
DECISION = ALLOW_NORMAL_TEST_TENANT_SYNC_ONLY
SYNC_DRAIN_ACTIVATION = FORBIDDEN
```

The successor may test ordinary application synchronization ONLY if:

- it is part of the currently implemented normal app flow
- it affects only the dedicated test tenant
- data is synthetic/test-only
- tenant isolation is preserved
- no administrative/global drain operation is needed

CRITICAL: OD7 SYNC DRAIN ACTIVATION REMAINS SEPARATELY GOVERNED. No global
drain, administrative drain activation, hidden drain enablement, production
drain switch, or rollout of previously frozen drain behavior. If Sync Drain is
required:

```text
STOP and report:
BLOCKED_PENDING_EXPLICIT_OD7_SYNC_DRAIN_OWNER_AUTHORIZATION
```

Resolves plan §U #7 (normal test-tenant sync only; drain separately governed).

### OD-PROD-08 — AAB / PLAY INTENT

```text
DECISION = RELEASE_CANDIDATE_EVIDENCE_ONLY
PLAY_UPLOAD_AUTHORIZED = NO
```

Any APK/AAB built by the future successor is for controlled technical
validation, signing evidence, artifact identity, and Release Candidate evidence
ONLY. It is NOT authorized for upload to Google Play. No internal/closed/open
testing upload, no production upload, no draft Play release, no rollout, no
submit for review, no publishing. Play Console remains a later separately
authorized phase.

Resolves plan §U #8 (local evidence AAB/RC; no Play).

### OD-PROD-09 — SUPABASE CLIENT CONFIGURATION

```text
DECISION = APPROVE_PUBLIC_CLIENT_CONFIGURATION_ONLY
SERVICE_ROLE_IN_ANDROID = FORBIDDEN
```

The production-connected Android candidate may receive the real production
Supabase client configuration through the repository-established safe
compile-time mechanism. Expected canonical mechanism from predecessor planning:

```text
SUPABASE_URL      = String.fromEnvironment / --dart-define
SUPABASE_ANON_KEY = String.fromEnvironment / --dart-define
```

The successor must verify the actual canonical mechanism again before use.
Allowed Android client configuration:

- production Supabase URL
- production anon/publishable client key
- other demonstrably public client-side identifiers required by the app

ABSOLUTELY FORBIDDEN IN APK:

- service_role key / secret server key / database password
- private signing material / privileged API credentials
- backend admin tokens / Play credentials
- any credential granting RLS bypass or admin authority

If the correct production URL/publishable key cannot be obtained from an
Owner-approved source without exposing privileged secrets: STOP. Do not guess
values. Do not substitute service_role. Do not commit the values merely for
convenience.

### OD-PROD-10 — CONFIGURATION SUPPLY / SECRET HANDLING

```text
DECISION = USE_OWNER_CONTROLLED_NON_COMMITTED_INPUT
```

The future successor may consume the required production PUBLIC client
configuration from an Owner-controlled local source or approved environment
mechanism, preferring ephemeral/non-committed injection. No production config
value should be committed merely to make building easier. Governance evidence
should normally record variable name, presence, mechanism, validation result,
and redacted identifier/hash where useful — not gratuitously print full values.
If a credential is privileged/secret: DO NOT expose it.

Resolves plan §U OPTIONAL #P (Owner-controlled ephemeral supply; exact project
ref and key sourcing decided at execution within this boundary).

### OD-PROD-11 — VERSION IDENTITY

```text
DECISION = USE_NEW_RELEASE_CANDIDATE_VERSION_CODE
VERSION_NAME = 1.0.0
VERSION_CODE = 3
FLUTTER_PUBSPEC_IDENTITY (if implementation requires changing it) = 1.0.0+3
```

The production-connected candidate MUST NOT reuse the already tested offline
APK's versionCode 2 as the new controlled production Release Candidate.
versionCode 2 uniquely identifies the prior offline/private-smoke artifact;
versionCode 3 provides a distinct monotonic identity for the first
production-connected controlled Release Candidate. The future implementation
may make the minimum version change necessary. No unrelated versioning redesign
is authorized.

Resolves plan §U OPTIONAL #V (advance to 1.0.0+3, versionCode 3).

---

## H. Exact Authorized Successor

```text
AUTHORIZED_SUCCESSOR =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION

AUTHORIZED_SUCCESSOR_COUNT = 1
```

Exactly ONE successor is authorized. The authorization applies only under all
OD-PROD decisions and restrictions above.

```text
SUCCESSOR_STARTED = NO
ANDROID_PRODUCTION_CONFIGURATION_IMPLEMENTATION_STARTED = NO
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
SUPABASE_PRODUCTION_MUTATION = NONE
PLAY_STORE_ACTION = NONE
```

---

## I. Exact Future Execution Scope (authorized on paper; NOT started here)

When a NEW session explicitly starts the authorized successor, its maximum scope
may include:

1. Re-run full entry forensics.
2. Reconcile this Owner authorization.
3. Verify the production client configuration mechanism.
4. Safely obtain Owner-approved production public client configuration
   (non-committed / ephemeral; OD-PROD-09 / OD-PROD-10).
5. Apply the minimum configuration/version change required for version 1.0.0+3
   (OD-PROD-11).
6. Validate no privileged secret enters Android.
7. Run relevant static/unit/full tests required by repository governance.
8. Build a signed Release Candidate APK and/or AAB as technically needed.
9. Capture artifact hashes, package identity, versionCode/versionName, SDK
   identity, and signing fingerprints.
10. Use device `f0deca9` with explicit `-s f0deca9` targeting (OD-PROD-04).
11. Perform fresh install first (OD-PROD-04).
12. Launch the production-connected app.
13. Validate Owner-controlled test onboarding.
14. Create/use the dedicated test tenant under the rules above (OD-PROD-02).
15. Validate Trial behavior (OD-PROD-06).
16. Validate Device Trust (OD-PROD-13).
17. Validate tenant/RLS fail-closed behavior using test identities only
    (OD-PROD-12).
18. Validate ordinary test-tenant sync where permitted (OD-PROD-07).
19. Validate restart and permitted online/offline transitions.
20. Capture crash/ANR/runtime evidence.
21. Produce formal execution evidence.
22. Commit only authorized repository changes/evidence.
23. Push only to `github`.
24. Remote-lock.
25. STOP before Play or any successor.

THIS LIST DEFINES FUTURE AUTHORITY ONLY. NONE OF IT MAY START IN THIS SESSION.

---

## J. Production Mutation Boundaries (binding for the future successor)

Allowed only within the dedicated Owner-controlled test tenant and only the
minimum writes strictly necessary (OD-PROD-03), with explicit validation
purpose + evidence trail.

Even when the successor later starts, these remain FORBIDDEN unless separately
authorized:

```text
NO production schema migration
NO RLS modification
NO Supabase Auth policy/config change
NO Edge Function deployment
NO service_role use in Android
NO production-wide SQL mutation
NO unrelated tenant mutation
NO customer data testing
NO real billing
NO paid subscription mutation
NO administrative cleanup
NO mass device operation
NO Sync Drain activation
NO Play Store action
```

If implementation discovers that any prohibited operation is technically
necessary: FAIL CLOSED. Do not expand scope automatically.

---

## K. Dedicated Test Tenant Rules

```text
- dedicated I Tech-controlled production TEST identity + TEST shop only
- reuse ONLY if already dedicated, documented, proven isolated from customer data
- otherwise create exactly the minimum dedicated test identity/shop needed
- never reuse a real customer account/shop for convenience
- test-obvious naming (e.g., "I Tech Android Validation" / "I Tech Production Test")
- all writes tenant-scoped, minimum-write, reversible, evidenced
- no real customer names/numbers/private information in test data
- no reading/probing/repairing/cleaning of unrelated production tenants
```

---

## L. Client Configuration / Secret Boundary

```text
IN APK (allowed, public only):  production Supabase URL; anon/publishable key;
                                public client-side identifiers required by app
NOT IN APK (forbidden):         service_role key; server secret key; DB password;
                                private signing material; privileged API credentials;
                                backend admin tokens; Play credentials; any RLS-bypass/
                                admin-authority credential
SUPPLY:                         Owner-controlled, ephemeral/non-committed
                                (--dart-define / --dart-define-from-file per repo
                                mechanism), never committed for convenience
EVIDENCE:                       variable name / presence / mechanism / validation
                                result / redacted identifier-hash; no gratuitous values
```

---

## M. Version Decision

```text
VERSION_NAME = 1.0.0
VERSION_CODE = 3
FLUTTER_PUBSPEC_IDENTITY = 1.0.0+3 (minimum change only if implementation requires it)
Rationale: versionCode 2 = tested offline/private-smoke artifact.
           versionCode 3 = first production-connected controlled Release Candidate.
```

---

## N. Device Target

```text
DEVICE_SERIAL = f0deca9
TARGET_PACKAGE = com.itech.storemanagement
Every future adb command MUST carry -s f0deca9. No broad/multi-device commands.
```

---

## O. Fresh-Install-First Decision

```text
FRESH_INSTALL_FIRST = APPROVED  (prior to any upgrade validation)
UPGRADE_VALIDATION   = NOT PART OF THE PRIMARY PASS GATE (later separate governance)
Uninstall/clear restricted to ONLY com.itech.storemanagement on ONLY f0deca9,
with pre-state evidence captured first; no broad device/package cleanup.
```

---

## P. Trial-Only-First Decision

```text
TRIAL_ONLY_FIRST = APPROVED
TRIAL_DURATION   = 14 days (product rule from canonical implementation)
TRIAL tier       = 1 user / 1 device / offline grace 0 days (to validate)
Paid-tier testing = NOT authorized this successor (requires later explicit Owner
                    authorization unless purely read-only with no production change).
```

---

## Q. RLS / Tenant Isolation Requirements

```text
FAIL_CLOSED_TEST_TENANT_VALIDATION = APPROVED
Purpose: prove, using Owner-controlled test identities ONLY:
  - correct tenant can access its authorized records
  - shop_id ownership/membership is enforced
  - unauthorized tenant access fails
  - unauthorized mutation fails
  - Android client cannot bypass RLS
  - Android client contains no service-role credential
  - no arbitrary tenant switch/bypass exists through normal client behavior
DO NOT probe real customer tenants.
If a second identity/tenant is technically required for isolation proof, create
or use only a dedicated Owner-controlled isolation-test identity/tenant; it must
remain synthetic and Owner-controlled.
```

---

## R. Device Trust Scope

```text
DEVICE_TRUST_SCOPE = ALLOW_TEST_DEVICE_REGISTRATION
Only device: f0deca9
Only tenant: the dedicated production test tenant (OD-PROD-02)
Allowed: minimum server-side device record needed by the normal production flow
Forbidden: unrelated device modification / mass revocation / touching existing
           customer devices
```

---

## S. Sync Scope and OD7 Prohibition

```text
SYNC_SCOPE      = ALLOW_NORMAL_TEST_TENANT_SYNC_ONLY
  - part of currently implemented normal app flow
  - affects only the dedicated test tenant
  - synthetic/test-only data
  - tenant isolation preserved
  - no administrative/global drain operation
OD7_SYNC_DRAIN_ACTIVATION = FORBIDDEN
  - no global drain / administrative drain activation / hidden drain enablement
  - no production drain switch / rollout of frozen drain behavior
  - if Sync Drain is required: STOP and report
    BLOCKED_PENDING_EXPLICIT_OD7_SYNC_DRAIN_OWNER_AUTHORIZATION
```

---

## T. AAB / Release Candidate Intent

```text
RELEASE_ARTIFACT_PURPOSE = CONTROLLED_RELEASE_CANDIDATE (evidence-backed only)
  - controlled technical validation
  - signing evidence / artifact identity / RC evidence
  - NOT automatically a public release
  - NOT automatically Play-ready
PLAY_UPLOAD_AUTHORIZED = NO
```

---

## U. Play Store Prohibition

```text
PLAY_STORE_ACTION = NONE
  - NO internal/closed/open testing upload
  - NO production upload
  - NO draft Play release / rollout / submit for review / publish
  - NO Play Console open/change (including by successor without new authority)
If controlled production-connected validation passes, Play becomes a later
Owner-decision successor. It MUST NOT be started automatically.
```

---

## V. Explicit Actions NOT Performed This Session

```text
PRODUCTION_ACTION            = NONE
SUPABASE_PRODUCTION_MUTATION = NONE
ANDROID_PRODUCTION_CONFIGURATION_IMPLEMENTATION_STARTED = NO
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
DEVICE_MUTATION              = NONE  (no install/uninstall/pm clear/settings on f0deca9)
PLAY_STORE_ACTION            = NONE
OD7_SYNC_DRAIN_ACTIVATION    = NONE
TAG_CREATED                  = NO
ORIGIN_CONTACTED             = NO
CODE/MIGRATION/SQL/FUNCTION/RLS/SECRET CHANGE = NONE
VERSION CHANGE (pubspec to +3) = NOT PERFORMED (deferred to successor execution)
REPOSITORY MUTATION          = exactly ONE governance markdown file (this artifact)
```

---

## W. Successor-Start Prohibition

```text
SUCCESSOR_STARTED = NO
The actions of the authorized successor belong to a NEW session AFTER this
authorization is committed and Remote-Locked.
DO NOT:
  change app code; bump version to +3 yet; inject Supabase production config;
  build APK/AAB; uninstall/install the app; create the production test identity;
  create the production test shop; register device f0deca9; initialize the Trial;
  write production test data; test RLS; test sync; activate OD7; interact with
  the Play Console — in this session or automatically after it.
```

---

## X. Commit / Push / Remote-Lock Evidence

Recorded after execution in this session:

```text
COMMIT_COUNT   = 1 (this governance document, normal commit, no amend/squash/force)
STAGED_SET     = exactly this single governance file
PUSH_DEST      = github/codex/i-tech-next-roadmap-freeze (normal push only)
```

Post-push verification fields populated after the push (see session report):

```text
POST_PUSH_LOCAL_HEAD
POST_PUSH_TRACKING_HEAD
POST_PUSH_DIRECT_GITHUB_HEAD
POST_PUSH_MERGE_BASE
POST_PUSH_AHEAD = 0
POST_PUSH_BEHIND = 0
REMOTE_LOCKED   = proven only with the evidence above
```

---

## Y. Final State

```text
OWNER_DECISION            = APPROVE
AUTHORIZED_SUCCESSOR      =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION
AUTHORIZED_SUCCESSOR_COUNT= 1
SUCCESSOR_STARTED         = NO
PRODUCTION_ACTION         = NONE
SUPABASE_PRODUCTION_MUTATION = NONE
ANDROID_PRODUCTION_CONFIGURATION_IMPLEMENTATION_STARTED = NO
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
DEVICE_MUTATION           = NONE
PLAY_STORE_ACTION         = NONE
OD7_SYNC_DRAIN_ACTIVATION = NONE
ORIGIN_CONTACTED          = NO
TAG_CREATED               = NO
FINAL_ENTRY_CLASSIFICATION = CASE_B_EXPECTED_BENIGN_RESIDUE
```

---

## Z. Result Token

```text
PASS_PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_OWNER_AUTHORIZATION_REMOTE_LOCKED

SKILLS_DISCOVERED = flutter-release, flutter-security, flutter-offline-data
                    (+ flutter-testing, flutter-core-engineering) — verified available
SKILLS_USED       = NONE (governance-only session; no Flutter implementation executed;
                    content read deferred to the successor execution session per plan)
PRIMARY_SKILL     = flutter-release (advisory for the successor; skills grant no authority)
SKILL_SCOPE_EXPANSION = NONE
ORIGIN_CONTACTED  = NO
PLAY_STORE_ACTION = NONE
PRODUCTION_ACTION = NONE
SUPABASE_PRODUCTION_MUTATION = NONE
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
SUCCESSOR_STARTED = NO
TAG_CREATED       = NO
```

The success token above is claimed ONLY if all of the following hold true after
this session completes: entry forensics pass; Owner decisions recorded; exactly
one governance file committed; push succeeds; Remote-Lock is proven; successor
is NOT started; no production/device/Play action occurs. Otherwise the matching
fail-closed token applies and Remote-Lock is NOT claimed.

---

*End of Owner authorization artifact.*