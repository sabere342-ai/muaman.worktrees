# PHASE P — POST-PRODUCTION-CONFIG GATE-2 IDENTITY LINKAGE — OWNER AUTHORIZATION

> GOVERNANCE / OWNER-AUTHORIZATION-ONLY SESSION.
> This artifact records the Owner's explicit, binding decision that authorizes
> the proposed successor phase ON PAPER ONLY.
>
> THIS SESSION MUST NOT START THE SUCCESSOR.
>
> No production query, no Supabase mutation, no Auth mutation, no identity-link
> mutation, no shop/membership mutation, no entitlement mutation, no OD7
> activation, no Play action, no device mutation, and no schema/code change is
> performed in this session. Only read-only repository forensics, the single
> governance document below, one commit to `github`, and Remote-Lock
> verification are executed.
>
> Contains NO passwords, NO secrets, NO Supabase service-role key, NO real
> Supabase URL, NO real anon/publishable key value, NO access tokens, and NO
> Play credentials. Paths, mechanism identifiers, hashes, and redacted/derived
> facts only.

---

## A. Session Identity and Result

```text
SESSION =
PHASE_P_POST_PRODUCTION_CONFIG_GATE_2_IDENTITY_LINKAGE_OWNER_AUTHORIZATION

SESSION_CLASS = OWNER_DECISION_GOVERNANCE_AND_READ_ONLY_RECONCILIATION_AUTHORIZATION_ONLY
PURPOSE       = Record the Owner's explicit decision authorizing exactly ONE
                successor: read-only production identity-linkage reconciliation.
SUCCESSOR_EXECUTION_STARTED = NO
```

```text
OWNER_DECISION      = APPROVE
AUTHORIZED_SUCCESSOR =
PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION
AUTHORIZED_SUCCESSOR_COUNT = 1
SUCCESSOR_STARTED   = NO
PRODUCTION_QUERY_STARTED = NO
PRODUCTION_MUTATION = NONE
SUPABASE_MUTATION   = NONE
IDENTITY_LINK_MUTATION = NONE
SHOP_MUTATION       = NONE
MEMBERSHIP_MUTATION = NONE
ENTITLEMENT_MUTATION = NONE
OD7_SYNC_DRAIN_ACTIVATION = NONE
PLAY_STORE_ACTION   = NONE
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
LOCAL_HEAD         = 0fcbd27164ddd17f81c530258d9952673bc6191f
TRACKING_HEAD      = 0fcbd27164ddd17f81c530258d9952673bc6191f (git rev-parse "@{u}")
DIRECT_GITHUB_HEAD = 0fcbd27164ddd17f81c530258d9952673bc6191f (git ls-remote github, read-only)
MERGE_BASE         = 0fcbd27164ddd17f81c530258d9952673bc6191f
AHEAD              = 0
BEHIND             = 0
HEAD_SUBJECT       = fix: expose cloudUuid on User model to fix post-auth login crash
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
11 pre-existing sacred/evidence entries, exactly as expected:

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
0fcbd27164ddd17f81c530258d9952673bc6191f
fix: expose cloudUuid on User model to fix post-auth login crash
```

Its lineage (immediately preceding commits) provides the production-config and
first-owner-bootstrap context for this decision:

```text
0fcbd27 fix: expose cloudUuid on User model to fix post-auth login crash
4a2ba6f fix: restore first-owner bootstrap via fail-closed createFirstOwner
15880ef docs: authorize android production validation
```

---

## D. Predecessor Acceptance

```text
PREDECESSOR_RESULT =
PASS_PHASE_P_SUPABASE_PRODUCTION_DEFINES_REBUILD_AND_DEVICE_VALIDATION

GATE_1              = PASS
FIRST_FAILING_GATE  = GATE_2_IDENTITY
IS_CLOUD_LINKED     = FALSE
SUPABASE_MUTATION   = NONE
ENTITLEMENT_MUTATION = NONE
OD7_SYNC_DRAIN_ACTIVATION = NONE
PLAY_STORE_ACTION   = NONE
MANDATORY_STOP_REACHED = YES
SUCCESSOR_STARTED   = NO
```

Predecessor verified Gate 1 (App/defines configuration) as PASS. The first
failing cloud gate is GATE_2_IDENTITY. The exact missing identity component was
INFERRED, not directly observed from the protected device database, so the
successor must not assume the exact remediation until read-only reconciliation
completes.

---

## E. Owner Decision

```text
OWNER_DECISION          = APPROVE
AUTHORIZED_SUCCESSOR    = PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION
AUTHORIZED_SUCCESSOR_COUNT = 1
```

The Owner authorizes exactly ONE successor covering:

```text
* repository/source inspection
* existing production identity architecture inspection
* READ-ONLY Supabase reconciliation
* READ-ONLY Auth identity discovery where supported and authorized
* READ-ONLY shop/membership/user/entitlement reconciliation
* determination of the minimum safe identity-link operation required
* production mutation planning
* final owner decision matrix
```

This authorization DOES NOT cover performing the mutation.

---

## F. Requirement Not to Re-investigate Gate 1

The successor must NOT:

```text
* rebuild Android merely to investigate Gate 2
* modify dart-defines
* change AppConfig
* weaken `isConfigured`
* change `_attemptCloudSession`
* bypass identity checks
* create temporary cloud identities
* invent `cloud_uuid`
* manually force `isCloudLinked=true`
```

Gate 1 is not the issue.

---

## G. Authorization Boundary

```text
READ_ONLY_PRODUCTION_RECONCILIATION_AUTHORIZED = YES
  Allowed: SELECT-style DB inspection, schema introspection, existing Auth
  identity lookup, existing shop lookup, existing user/member lookup, existing
  entitlement lookup, existing device relationship lookup, existing role/
  membership lookup — strictly non-mutating only.
  Credentials: only already-approved, appropriately scoped credentials.
  Secrets: never revealed, committed, or printed.

PRODUCTION_MUTATION_AUTHORIZED      = NO
AUTH_USER_CREATION_AUTHORIZED      = NO
AUTH_USER_UPDATE_AUTHORIZED        = NO
CLOUD_UUID_MUTATION_AUTHORIZED     = NO
SHOP_CREATION_AUTHORIZED           = NO
MEMBERSHIP_MUTATION_AUTHORIZED     = NO
ENTITLEMENT_MUTATION_AUTHORIZED    = NO
LICENSING_MUTATION_AUTHORIZED      = NO
OD7_AUTHORIZED                     = NO
PLAY_STORE_AUTHORIZED              = NO
LOCAL_DEVICE_MUTATION_AUTHORIZED   = NO
  (device f0deca9 may be used for controlled observation only; forbidden:
   adb uninstall, pm clear, app-data deletion, extraction, rooting, direct
   SQLite modification, credential deletion)
```

Forbidden in the successor unless the Owner separately approves: INSERT,
UPDATE, DELETE, UPSERT, RPC mutation, Auth user creation/update, password
reset, email mutation, shop/membership creation, cloud_uuid assignment, user
linking, device mutation, license/entitlement creation, subscription
activation, trial modification, RLS changes, migration execution, Edge
Function deployment, Storage/Realtime/Cron/Queue mutation, production
configuration changes. If any are required: DOCUMENT AND STOP.

---

## H. Identity Reconciliation Mandate (read-only)

The successor must resolve, with evidence, the state of the production identity
model covering: Supabase Auth identity, application user identity,
`users.cloud_uuid`, `shop_id`, `shops`, memberships/role relationships, owner
identity, device registrations where relevant, entitlement/license records,
tenant binding, identity linker behavior, FirstOwnerSetup behavior, and login
cloud-session gates.

The actual repository schema and migrations are the authority. The successor
must NOT assume table or column names absent from the repository.

Identity reconciliation questions to answer (Q1..Q8): existence of Auth
identity, existence of app user, shop membership, shop existence, owner
membership existence, entitlement existence, linkability via existing identity,
and the exact fields requiring change. Field names such as `users.cloud_uuid`
are examples only and are NOT assumed until repository-confirmed.

---

## I. Gate-2 Subclass and Minimum-Mutation Principle

The successor must classify Gate 2 precisely (e.g.,
GATE_2A_LOCAL_CLOUD_UUID_MISSING ... GATE_2G_IDENTITY_STATE_AMBIGUOUS, or
another repository-supported classification) and design the smallest safe
operation that could repair Gate 2, in this priority order:

```text
1. Reuse existing valid production identity.
2. Reuse existing shop.
3. Reuse existing owner membership.
4. Avoid duplicate Supabase Auth users.
5. Avoid duplicate shops.
6. Avoid duplicate memberships.
7. Avoid entitlement creation unless separately required.
8. Avoid direct SQL when an existing canonical application/RPC flow exists.
9. Preserve local owner data.
10. Preserve tenant isolation and RLS.
```

Duplicate-prevention must be proven before recommending any creation operation.
Identity linkage and licensing remain conceptually separate; entitlement
changes must NOT be bundled into the identity-link mutation.

---

## J. Mandatory Stop and Successor Output

The successor session MUST finish with a concrete plan:

```text
REQUIRED_MUTATION_COUNT = N
M1: TARGET/OPERATION/PURPOSE/PRECONDITION/ROLLBACK/RISK
M2: ...
MUTATION_EXECUTED = NO
OWNER_AUTHORIZATION_REQUIRED = YES
MANDATORY_STOP_REACHED = YES
SUCCESSOR_STARTED = NO
```

It must also produce an owner decision matrix comparing the actual options
found (reuse existing cloud identity; create missing cloud identity only if
proven absent; create missing shop/membership only if proven absent; take no
mutation because state is ambiguous; or actual options based on findings) with
purpose, exact records affected, mutation type, risk, reversibility, duplicate
risk, tenant/RLS implications, recommendation, and required authorization.
Exactly ONE next action is recommended; it is NOT executed.

---

## K. Governance Artifact

```text
COMMIT_CREATED = YES (this document, exactly one normal commit)
COMMIT_SHA     = <filled post-commit>
TAG_CREATED    = NO
PUSH_PERFORMED = YES (to github only)
REMOTE_LOCKED  = YES (verified post-push)
ORIGIN_CONTACTED = NO
```

Expected lock after push:

```text
LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE
AHEAD = 0
BEHIND = 0
```

---

## L. Mandatory End State

```text
OWNER_DECISION =
APPROVE
AUTHORIZED_SUCCESSOR =
PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION
AUTHORIZED_SUCCESSOR_COUNT =
1
SUCCESSOR_STARTED =
NO
PRODUCTION_QUERY_STARTED =
NO
PRODUCTION_MUTATION =
NONE
SUPABASE_MUTATION =
NONE
IDENTITY_LINK_MUTATION =
NONE
ENTITLEMENT_MUTATION =
NONE
OD7_SYNC_DRAIN_ACTIVATION =
NONE
PLAY_STORE_ACTION =
NONE
MANDATORY_STOP_REACHED =
YES
```