# PHASE_P_GATE_2 — CONFIRMED EXISTING AUTH IDENTITY RECONCILIATION OWNER DECISION REPORT

> GOVERNANCE + FORENSICS + OWNER-DECISION RECORDING SESSION. READ-ONLY.
>
> The owner's live Supabase production dashboard evidence (i-tech-production →
> Authentication → Users) proves that the target Auth identity already exists,
> is email-confirmed, and has previously signed in. This report corrects the
> predecessor forensic inference of a *pending/unconfirmed* identity and records
> the reconciled successor decision. It DOES NOT and MUST NOT execute the link.
>
> THIS SESSION PERFORMED: fresh repository / Git / remote-lock forensics;
> predecessor artifact verification; read-only source-path re-verification of
> the cloud linking flow; owner decision recording; governance report; a single
> governance-only commit; a normal fast-forward push to `github`.
>
> THIS SESSION DID NOT: execute identity linking; press «ربط الحساب السحابي»;
> run signUp; run signIn against production; resend/confirm email; reset a
> password; mutate Supabase Auth; use Auth Admin / Dashboard; run or mutate SQL;
> create/update/delete shops or memberships; write/clear cloud_uuid; modify local
> linkage state; modify device records; activate OD7 Sync Drain; enqueue/drain
> sync; build/install an APK; touch Play Console; change production config;
> modify secrets/templates/redirect URLs; implement code; edit tests; contact
> `origin`.
>
> Contains NO passwords, NO service-role keys, NO Supabase URL/anon keys, NO
> access tokens, NO confirmation URLs/OTPs, NO signing secrets. Commit hashes,
> mechanism names, derived facts, and governance state only. The Auth UID is
> owner-provided and reproduced as a non-secret identifier.

---

## A. SESSION RESULT

```text
RESULT_TOKEN =
PASS_PHASE_P_GATE_2_CONFIRMED_EXISTING_AUTH_IDENTITY_RECONCILIATION_OWNER_DECISION_REMOTE_LOCKED

SESSION            = PHASE_P_GATE_2_CONFIRMED_EXISTING_AUTH_IDENTITY_RECONCILIATION_OWNER_DECISION
SESSION_CLASS      = OWNER DECISION + FORENSICS + GOVERNANCE ONLY
CONTROLLING_PREDECESSOR = PHASE_P_GATE_2_PENDING_AUTH_EMAIL_CONFIRMATION_OWNER_AUTHORIZATION_REPORT.md
PREDECESSOR_RESULT = PASS_PHASE_P_GATE_2_PENDING_AUTH_EMAIL_CONFIRMATION_OWNER_AUTHORIZATION_REMOTE_LOCKED

AUTH_IDENTITY_EXISTS           = YES
AUTH_IDENTITY_UID              = 0e681dc8-8055-4403-aba3-9d1146d4747e
EMAIL_CONFIRMED                = YES
PRIOR_SUCCESSFUL_SIGN_IN       = YES
RECONFIRMATION_REQUIRED        = NO

PREVIOUS_PENDING_IDENTITY_INFERENCE =
DISPROVED_BY_OWNER_PROVIDED_SUPABASE_AUTH_USER_EVIDENCE

SIGNUP_RETRY                   = NO
SIGNIN_LINK_EXECUTED           = NO
EMAIL_CONFIRMATION_EXECUTED    = NO
EMAIL_CONFIRMATION_RESEND      = NO
AUTH_ADMIN_MUTATION            = NO
DIRECT_SQL                     = NO
SHOP_CREATED                   = NO
MEMBERSHIP_CREATED             = NO
CLOUD_UUID_WRITTEN             = NO
IDENTITY_LINK_EXECUTED         = NO
MIGRATION_EXECUTED             = NO
OD7_SYNC_DRAIN_ACTIVATED       = NO
ANDROID_BUILD_STARTED          = NO
PRODUCTION_MUTATION            = NONE
CREDENTIAL_PROBE               = NO (no signIn/signUp/any Auth network op)

AUTHORIZED_SUCCESSOR           = PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING
AUTHORIZED_SUCCESSOR_COUNT     = 1
SUCCESSOR_STARTED              = NO

TAG_CREATED                    = NO
ORIGIN_CONTACTED               = NO
MANDATORY_STOP_REACHED         = YES
```

---

## B. REPOSITORY IDENTITY (VERIFIED this session)

```text
ROOT           = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze           VERIFIED
GIT_DIR        = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze
                 (linked worktree; .git is NOT a directory)                    VERIFIED
BRANCH         = codex/i-tech-next-roadmap-freeze                              VERIFIED
TRACKING       = github/codex/i-tech-next-roadmap-freeze                       VERIFIED
AUTHORIZED_REMOTE = github  https://github.com/sabere342-ai/muaman.worktrees.git  VERIFIED
FORBIDDEN_REMOTE  = origin  (read locally ONLY; NEVER contacted)               VERIFIED
```

---

## C. ENTRY FORENSICS (VERIFIED this session)

```text
MANDATORY ENTRY HEAD      = e0c8e6a51dea13ecf016c3707107ca0449b47820         VERIFIED
HEAD_SUBJECT              = "docs: record pending auth email confirmation
                            owner authorization"                              VERIFIED

LOCAL_HEAD          = e0c8e6a51dea13ecf016c3707107ca0449b47820               VERIFIED
TRACKING_HEAD       = e0c8e6a51dea13ecf016c3707107ca0449b47820               VERIFIED
DIRECT_GITHUB_HEAD  = e0c8e6a51dea13ecf016c3707107ca0449b47820
                      (git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze;
                       no fetch, no ref mutation)                             VERIFIED
MERGE_BASE          = e0c8e6a51dea13ecf016c3707107ca0449b47820   VERIFIED
                      (merge-base HEAD github/codex/i-tech-next-roadmap-freeze)
AHEAD               = 0   BEHIND = 0                                          VERIFIED

ACTIVE_GIT_OPS      = NONE                                                    VERIFIED
   MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG /
   rebase-merge / rebase-apply / sequencer     ALL ABSENT                     VERIFIED

STAGED              = 0                                                     VERIFIED
TRACKED_MODIFIED    = 0                                                     VERIFIED
TRACKED_DELETED     = 0                                                     VERIFIED
STASH               = 1 entry (stash@{0}: WIP on
                      codex/muaman-13-strict-july-workbook-data-migration:
                      283ff9d ...), INSPECTED BUT PRESERVED, NOT APPLIED,
                      NOT REBASED, NOT DROPPED                                VERIFIED
ENTRY_CLASS         = CASE_A_FRESH (with pre-existing sacred untracked inventory)
```

### Sacred Untracked Inventory (re-enumerated this session, 26 porcelain entries — PRESERVED unchanged)

```text
Continue
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
PHASE_P_GATE_2_EXISTING_OWNER_CLOUD_LINK_UI_IMPLEMENTATION_REPORT.md
PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_BLOCKED_PREFLIGHT_REPORT.md
PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_PLAN.md
PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION_REPORT.md
PHASE_P_GATE_2_UPDATED_ANDROID_BUILD_INSTALL_AND_REENTRY_PREFLIGHT_REPORT.md
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.branches/_current_branch          (NOT read, NOT modified, NOT staged)
supabase/.temp/                             (possibly secret-bearing; NOT read,
                                             NOT printed, NOT staged, NOT modified,
                                             NOT deleted)
```

None of the above was staged, modified, deleted, renamed, or normalized this
session. Only the new report file
`PHASE_P_GATE_2_CONFIRMED_EXISTING_AUTH_IDENTITY_RECONCILIATION_OWNER_DECISION_REPORT.md`
was created and will be staged alone.

---

## D. CONTROLLING PREDECESSOR (VERIFIED this session)

```text
PREDECESSOR REPORT   = PHASE_P_GATE_2_PENDING_AUTH_EMAIL_CONFIRMATION_OWNER_AUTHORIZATION_REPORT.md
PREDECESSOR RESULT   = PASS_PHASE_P_GATE_2_PENDING_AUTH_EMAIL_CONFIRMATION_OWNER_AUTHORIZATION_REMOTE_LOCKED
PREDECESSOR ENTRY    = e0c8e6a51dea13ecf016c3707107ca0449b47820
                       (the state when the predecessor session began)
PREDECESSOR COMMIT   = e0c8e6a51dea13ecf016c3707107ca0449b47820
                       (the commit that recorded the predecessor report; equals current HEAD)
CHAIN CONTINUITY     = VERIFIED — the predecessor result is REMOTE_LOCKED and no
                       intermediate commit exists between it and this session.
```

Predecessor preserved forensics (re-derived where cheap, otherwise quoted):

```text
PREDECESSOR OBSERVED MESSAGE = «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول»
MAPPED CODE BRANCH           = cloud_auth_service.dart:149-152
                               (signUp: user != null && session == null)
INFERRED STATE (now DISPROVED) = pending/unconfirmed Supabase Auth identity
CLOUD_SESSION_EXISTED        = NO
create_shop_with_owner REACHED = NO
SHOP / MEMBERSHIP CREATION   = NO
LOCAL_IDENTITY_LINK_WRITTEN  = NO
LOCAL_ACCOUNT_STATE          = UNLINKED
```

**Historical immutability:** the predecessor report remains untouched. This is a
forward corrective governance record, not a history rewrite.

---

## E. NEW OWNER-PROVIDED SUPABASE AUTH EVIDENCE

Source: owner inspection of the Supabase production project `i-tech-production`,
`Authentication → Users`.

```text
AUTH_USER_EXISTS     = YES
AUTH_USER_UID        = 0e681dc8-8055-4403-aba3-9d1146d4747e
CREATED_AT           = 14 Sep 2026 15:34
CONFIRMATION_SENT_AT = 2026-09-14 12:34:38.153556+00
CONFIRMED_AT         = 14 Sep 2026 15:36
LAST_SIGNED_IN       = 14 Sep 2026 15:43
EMAIL_PROVIDER       = ENABLED
```

Consequences (OWNER-PROVIDED EVIDENCE classification):

```text
EMAIL_CONFIRMED           = YES
PRIOR_SUCCESSFUL_SIGN_IN  = YES
RECONFIRMATION_REQUIRED   = NO
```

The owner also reported that opening an *older* confirmation email link later
returned in the browser URL:

```text
error=access_denied
error_code=otp_expired
error_description=Email link is invalid or has expired
```

That stale expired OTP/link is NOT evidence about current account state. The
dashboard `Authentication -> Users` evidence supersedes any earlier
pending/unconfirmed inference. The old link simply means its OTP has elapsed —
expected, and orthogonal to confirmed status.

Evidence classification note (per AGENTS.md 5):
- Dashboard observations = OWNER-PROVIDED EXTERNAL EVIDENCE; NOT labeled as
  repository-VERIFIED.
- No Auth Admin read and no Auth mutation was performed to re-verify.

---

## F. CORRECTION OF PREVIOUS PENDING-IDENTITY INFERENCE

```text
PREVIOUS_PENDING_IDENTITY_INFERENCE =
DISPROVED_BY_OWNER_PROVIDED_SUPABASE_AUTH_USER_EVIDENCE
```

The predecessor governance chain inferred *pending/unconfirmed identity* from
the client message «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول»
(user != null && session == null after signUp). New owner evidence shows the
target identity was in fact created, then confirmed, then signed in
successfully. The identity is not pending and not unconfirmed.

Timeline reconciliation (INFERRED, grounded in verified code + owner evidence):

```text
14 Sep 15:34  app signUp (identity-link attempt) CREATES auth user
              session == null -> client shows «يرجى تأكيد البريد…»  -> message
              was TRUTHFUL AT THAT MOMENT (genuinely unconfirmed)
14 Sep 15:36  email confirmed (dashboard CONFIRMED_AT)                -> now confirmed
14 Sep 15:43  successful sign-in recorded (dashboard LAST_SIGNED_IN)  -> prior sign-in
~~ later ~~   stale confirmation-link click -> access_denied / otp_expired
              (artifact of elapsed OTP; NOT current-state evidence)
```

So: the message was not malicious — it accurately described a real confirmation
requirement for a just-created account. What is now disproved is any claim that
the identity is *currently* pending/unconfirmed or needs re-confirmation.

---

## G. CURRENT CODE PATH RE-VERIFICATION (read-only, live repository)

All paths below re-verified against the current working tree this session.

### G1. CloudAuthService (app/lib/services/cloud_auth_service.dart)

```text
signUp (140-163):
  response = _auth.signUp(email, password)
  response.session != null  -> CloudSignUpResult.success(session)   VERIFIED
  response.user != null && session == null
      -> CloudSignUpResult.unknownError(
           «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول»)          VERIFIED (149-152)
  AuthException "already registered" -> emailAlreadyRegistered
                                              (via _mapSignUpError 222-229)  VERIFIED
  network error -> networkUnavailable                                     VERIFIED

signInWithEmail (111-132):
  _auth.signInWithPassword returns session -> CloudAuthResult.success(session)  VERIFIED
  AuthException:
     invalid login credentials / invalid grant  -> invalidCredentials    VERIFIED
     email not confirmed                        -> emailNotConfirmed     VERIFIED
     already registered / user already          -> emailAlreadyRegistered VERIFIED
```

### G2. IdentityLinker (app/lib/services/identity_linker.dart)

```text
linkExistingUser (85-150):
  guarded pre-check: local user already has cloud_uuid -> early SUCCESS     VERIFIED (92-108)
  signUp (111-114)
  emailAlreadyRegistered -> LinkResult.cloudAccountExists  (fail-closed)   VERIFIED (116-118)
  networkUnavailable    -> LinkResult.networkUnavailable                    VERIFIED
  !success || session == null -> LinkResult.unknownError                    VERIFIED (122-126)
  session != null -> cloudUserId = session.user.id                          VERIFIED (128)
  createShopWithOwner(shopName) -> shopId                                   VERIFIED (132)
  _persistIdentity(localUserId, cloudUserId, shopId, email)                 VERIFIED (133-138)

onboardFreshOwner (161-217): same signUp-gated shape; not the active path for an
  already-existing local owner.                                              VERIFIED

_persistIdentity (220-241):
  users.cloud_uuid = cloudUserId                                            VERIFIED
  app_settings shopProfile.cloudUuid = shopId                               VERIFIED
  app_settings cloud.auth.email = email                                     VERIFIED
  NOTE: _persistIdentity itself has NO overwrite guard; safety relies on the
  caller checks (local cloud_uuid early-return at 92-108).                  VERIFIED

recoverOnboarding (246-287):
  get_user_shops() (needs a real authenticated session)                     VERIFIED
  local user lookup where cloud_uuid = currentUser.id                       VERIFIED (263-264)
  NO "local user with no cloud_uuid yet" branch — equality query does not
  match NULL. Therefore recoverOnboarding CANNOT link an UNLINKED local
  owner to an existing confirmed cloud identity.                            VERIFIED (261-279)
```

### G3. UI entry — Settings (app/lib/screens/settings_screen.dart)

```text
«ربط الحساب السحابي» entry shown ONLY when owner && !isCloudLinked         VERIFIED (754-762)
isCloudLinked = SessionState._cloudSession != null
                (app/lib/services/session_state.dart:37)                     VERIFIED
_openCloudLinkDialog: collects email / password / shop name                  VERIFIED (777-915)
dialog copy: «سيتم إنشاء حساب سحابي جديد مرتبط بهذا المتجر...» — i.e. the
             dialog itself is signUp/nonew-account framed                    VERIFIED (814-820)
_runCloudLink calls linker.linkExistingUser                                  VERIFIED (917-970)
cloudAccountExists maps to «هذا البريد الإلكتروني مسجل مسبقًا في حساب سحابي» — a
             DEAD END (no sign-in route offered)                             VERIFIED (960-962)
```

### G4. Existing signIn precedents in the app

```text
login_screen.dart _attemptCloudSession (143-198): after LOCAL login, if the
  local user has cloud_uuid + cloud.auth.email, it signs in with
  signInWithPassword and binds the session. This is read-only w.r.t. linkage —
  it never writes cloud_uuid.                                                 VERIFIED
seller_session_provisioning.dart _defaultSignIn (259-293): signInWithEmail ->
  get_user_shops -> ... (seller path; owner rejected; requires ACTIVE membership) VERIFIED
```

### G5. Server side

```text
create_shop_with_owner (supabase/migrations/20260820000020_database_functions.sql:18-56):
  requires auth.uid() non-NULL (28-32)
  INSERT shops; INSERT shop_members(owner); seed 3 system roles              VERIFIED
  NO guard against a user owning a second shop (owner_user_id has no UNIQUE
  constraint — migrations/20260820000000_create_shops.sql:8-15)              VERIFIED
get_user_shops (00020:67-103): returns ACTIVE memberships for auth.uid()      VERIFIED
shop_members UNIQUE(shop_id, user_id) — prevents per-shop duplicate memberships VERIFIED (00001:19)
accept_invitation (00022 / hardened in 00034) — employee invitation path only,
  derived from auth.uid(); NOT an existing-owner link function                VERIFIED
No server RPC exists that links an existing owner to an existing shop.        VERIFIED (grep)
```

---

## H. SIGNUP VS EXISTING-CONFIRMED-ACCOUNT ANALYSIS

```text
H1  The canonical owner link flow (linkExistingUser) is signUp-gated:
    signUp -> session -> create_shop_with_owner -> _persistIdentity.         VERIFIED
H2  For the target identity (sabere342@gmail.com), signUp can NEVER again
    produce a fresh session: the account exists, is confirmed, and mounts
    the standard "already registered" collision path (OAuth-collision awaits:
    code maps an "already registered" AuthException to emailAlreadyRegistered
    -> LinkResult.cloudAccountExists).                                       INFERRED
H3  Server-version nuance NOT PROVEN: whether signUp against a confirmed
    existing email returns (a) AuthException "already registered" (typical
    GoTrue) or (b) a user-without-session payload (some anti-enumeration
    configurations) is NOT VERIFIED for this production project. In BOTH
    cases the current client fails closed with no sign-in fallback:
      (a) -> cloudAccountExists -> «مسجل مسبقًا في حساب سحابي» (dead end)
      (b) -> «يرجى تأكيد البريد…» (misleading: reconfirmation not needed)
    Neither case yields a session; neither case proceeds to shop creation.
                                                                             NOT PROVEN (server
                                                                             nuance) / VERIFIED (client)
H4  signInWithPassword (existing code, cloud_auth_service.dart:111-132) is
    the correct mechanism to obtain a real session for an existing CONFIRMED
    identity. The app already relies on it for owner post-local-login cloud
    session resume and for seller provisioning.                              VERIFIED
H5  CONCLUSION: the technically correct successor mechanism is a SIGNIN-based
    existing-account link (Route 1), but current implementation does not have
    it — a code change is required (see L / M).
```

---

## I. CURRENT MISLEADING EMAIL-CONFIRMATION MESSAGE ANALYSIS

Message: «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول»
Source branch: `cloud_auth_service.dart:149-152` (signUp → user != null &&
session == null); mirrored in `seller_session_provisioning.dart:284` for
`emailNotConfirmed` sign-in mapping.

```text
Semantics at the moment the owner saw it:
  App signUp CREATED the account (owner dashboards CREATED_AT 15:34) and the
  confirmation email had just been dispatched; session was null because email
  confirmation is required. The message was ACCURATE then.                  VERIFIED-consistent

Semantics today:
  The identity is CONFIRMED (dashboard CONFIRMED_AT 15:36). Re-confirmation is
  NOT required. Reading the message as "the identity is currently unconfirmed"
  is WRONG.                                                                 OWNER-PROVIDED EVIDENCE

Why it is misleading as a forward instruction:
  - It tells the owner "confirm your email", but the email is already confirmed
    and a stale link returns access_denied / otp_expired (expected).
  - The link flow offers NO existing-account sign-in path, so both branches of
    H3 terminate in a dead end with no way to obtain a session for the
    confirmed account.

Classification:
  MESSAGE_AT_DISPLAY_TIME  = ACCURATE (genuine confirmation requirement for a
                             newly created account)
  MESSAGE_AS_CURRENT_STATUS = MISLEADING (identity is confirmed)
  DIALOG_COPY («سيتم إنشاء حساب سحابي جديد...») = MISLEADING for an existing
                             identity (no new account is created)
  LINK_FLOW_COMPLETABILITY = BROKEN for the existing confirmed identity without
                             a signIn-based path
```

---

## J. LOCAL OWNER / AUTH UID / SHOP / MEMBERSHIP STATE MODEL

```text
LOCAL (on-device):
  users row (owner)         exists                                             VERIFIED (predecessor +
                                                                              code path)
  users.cloud_uuid          NULL/unwritten                                     INFERRED*
  app_settings['cloud.auth.email']  empty                                     INFERRED*
  app_settings['shopProfile.cloudUuid']  empty                               INFERRED*
  in-memory cloud session   none -> isCloudLinked == false -> UI shows
                            «غير مرتبط بالسحابة» + link button visible        VERIFIED (predecessor UI
                                                                              + session_state.dart:37)

AUTH (production, owner-provided):
  Auth UID                  0e681dc8-8055-4403-aba3-9d1146d4747e             OWNER-PROVIDED EVIDENCE
  email                     confirmed; provider ENABLED                       OWNER-PROVIDED EVIDENCE
  prior successful sign-in  YES                                               OWNER-PROVIDED EVIDENCE

SHOPS / MEMBERSHIPS (production):
  owner shop                none — create_shop_with_owner unreachable without
                            a session; latest read-only reconciliation showed
                            only 2 smoke shops, neither the owner's            INFERRED*
  owner membership          none (same reasoning)                              INFERRED*
  membership uniqueness     UNIQUE(shop_id, user_id) on shop_members          VERIFIED (00001:19)

*INFERRED classification: grounded in verified code paths (createFirstOwner
  inserts cloud_uuid NULL; only _persistIdentity writes it and only after
  signUp+createShopWithOwner, which never completed) plus predecessor live-UI
  evidence. Local DB was NOT read this session (protected, out of scope).
```

Q12 answer (cloud_uuid null/unwritten?):

```text
users.cloud_uuid for the local owner = NULL / UNWRITTEN   classification: INFERRED
  (strong code-path grounding; not a direct local-DB read; predecessor UI
   evidence consistent). No local-DB mutation was performed to test.
```

Q13 answer (should UID 0e681dc8... become cloud_uuid?):

```text
Target cloud_uuid for the intended local owner = 0e681dc8-8055-4403-aba3-9d1146d4747e
  classification: INFERRED (it is the identity minted by the app's own link
  attempt for the owner's email). NOT VERIFIED as "same human owns both" until
  the execution session reconfirms with owner + sign-in proof.
  NOT WRITTEN this session.
```

---

## K. DUPLICATE AND CONFLICT INVARIANTS

Targets and their actual guards today:

```text
INVARIANT_1  AUTH_IDENTITY_DUPLICATION
  current guard: GoTrue email uniqueness (an Auth email maps to exactly one
  user) + client fail-closed on "already registered".                        VERIFIED
  residual risk: a human trying a NEW email would mint a second Auth identity
  and a second shop -> FORBIDDEN by governance (no new-email route selected).

INVARIANT_2  SHOP_DUPLICATION
  current guard: none at server level (no UNIQUE on shops.owner_user_id;
  create_shop_with_owner does not check for an existing shop).               VERIFIED (00000/00020)
  current reachability: for THIS confirmed identity no live client path can
  reach create_shop_with_owner again (signUp-collision fail-closed).        VERIFIED (trace)
  FUTURE REQUIREMENT: a signIn-based linker MUST NEVER call create_shop_with_owner;
  it must reuse get_user_shops membership. Otherwise a second shop is possible
  at server level.                                                          REQUIRED (design)

INVARIANT_3  MEMBERSHIP_DUPLICATION
  current guard: UNIQUE(shop_id, user_id).                                  VERIFIED (00001:19)
  FUTURE: no membership insert is needed for the existing owner — the owner
  membership already exists iff a shop exists; get_user_shops is the single
  source of truth.                                                          REQUIRED (design)

INVARIANT_4  LOCAL_LINK_OVERWRITE
  current guard: linkExistingUser early-return when local users.cloud_uuid is
  already non-empty (identity_linker.dart:92-108).                           VERIFIED
  _persistIdentity alone has NO guard — it must only be reached through a
  guarded wrapper.                                                          VERIFIED
  FUTURE: refuse to write users.cloud_uuid / shopProfile.cloudUuid /
  cloud.auth.email when any of them is already set to a conflicting value.  REQUIRED (design)
```

Q11 — exact conditions required before ANY future production link execution
(fail-closed checklist; NOT executed):

```text
C1  Session: obtained ONLY via signInWithPassword against the existing
    confirmed identity. NO signUp, NO new-email creation, NO Auth Admin.
C2  Session identity: session.user.id == 0e681dc8-8055-4403-aba3-9d1146d4747e
    AND session.user.email == the intended email.
C3  Membership: get_user_shops() returns exactly ONE ACTIVE membership with
    role == 'owner'. If zero -> STOP (do NOT create). If >1 -> STOP (ambiguous;
    owner decision required).
C4  Shop: the returned shop_id must match the intended local shop profile
    (name match). Never create_shop_with_owner on this path.
C5  Local owner: target local users row resolved; users.cloud_uuid IS NULL/empty.
C6  Local linkage keys: shopProfile.cloudUuid and cloud.auth.email unset OR
    already consistent with the target; otherwise STOP (no overwrite).
C7  Atomicity: the three _persistIdentity writes execute within one SQLite
    transaction.
C8  Post-write verification: read-back cloud_uuid == session.user.id,
    shopProfile.cloudUuid == shop_id, cloud.auth.email == email; app restart/
    login gate then establishes the cloud session normally.
```

---

## L. CANDIDATE ROUTES (evaluated; NONE executed)

### ROUTE 1 — EXISTING-ACCOUNT SIGNIN-BASED LINK

```text
Concept:
  existing local owner
  + existing confirmed Auth account (0e681dc8-...)
  -> signInWithPassword (real session)
  -> session identity validated (uid + email)
  -> get_user_shops (existing membership validated, owner ACTIVE)
  -> shop identity validated
  -> _persistIdentity (cloud_uuid + shopProfile.cloudUuid + cloud.auth.email)
  -> post-write verification
  NO create_shop_with_owner on this path.

Feasibility WITHOUT code change: NO.
  - linkExistingUser is signUp-gated (G2); recoverOnboarding requires an
    already-linked local row (G2); no other linker path exists (G4).
  - Therefore ROUTE 1 requires an implementation step first.
Classification: PRIMARY_CANDIDATE (with mandatory implementation prerequisite).
```

### ROUTE 2 — MODIFY CLIENT LINKER TO SUPPORT EXISTING ACCOUNTS

```text
Concept: add a signIn-first branch to the identity linker (new method or
  refactor of linkExistingUser) implementing the C1-C8 invariants; update the
  Settings dialog copy; add tests (regression + existing-account + duplicate
  guards). This is the REQUIRED PREREQUISITE for Route 1.
Status: REQUIRED. Must be a separate implementation/planning session.
Classification: REQUIRED (implementation prerequisite for ROUTE 1).
```

### ROUTE 3 — NEW EMAIL / NEW AUTH IDENTITY

```text
Concept: abandon 0e681dc8-... ; create a new Auth identity with a fresh email.
Status: REJECTED for this situation — no technical requirement forces a new
  identity; the existing identity is confirmed and valid (owner evidence); a
  new identity would orphan the confirmed one and mint an unnecessary second
  shop risk. Would require explicit owner authorization if ever reconsidered.
Classification: REJECTED_AS_PRIMARY (not authorized).
```

### ROUTE 4 — AUTH ADMIN / SQL / CONTROLLED CLEANUP

```text
High-risk privileged mutation (delete/recreate user, SQL repair). Not
  authorized; must not be selected casually. Not needed — the identity is
  confirmed and usable.
Classification: NOT_AUTHORIZED_BY_DEFAULT.
```

### ROUTE 5 — ABANDON CLOUD LINK

```text
Least-risk / zero-action. Only relevant if the owner prefers to keep the app
  offline-only. Documented for completeness; not selected.
Classification: AVAILABLE (owner choice), not selected.
```

---

## M. OWNER DECISION

```text
OWNER_DECISION =
RECONCILE CONFIRMED EXISTING AUTH IDENTITY VIA A CONTROLLED SIGNIN-BASED
EXISTING-ACCOUNT LINK, WITH AN IMPLEMENTATION PLANNING STEP FIRST.

AUTH_IDENTITY_EXISTS  = YES           (0e681dc8-8055-4403-aba3-9d1146d4747e)
EMAIL_CONFIRMED       = YES
PRIOR_SIGN_IN         = YES
RECONFIRMATION_NEEDED = NO
SIGNUP_RETRY          = NO
NEW_EMAIL_ROUTE       = NO
AUTH_ADMIN / SQL      = NO

REQUIRED_PRECONDITION = The client linker MUST first gain a signIn-based
  existing-account path (ROUTE 2 as prerequisite of ROUTE 1). Planned and
  authorized ONLY as a next planning session; execution still requires a NEW
  explicit owner authorization.
```

Selection rule applied: the execution-planning variant of the successor
(`...SIGNIN_LINK_EXECUTION_PLANNING`) is NOT selected because the live code
evidence proves the current implementation cannot safely execute Route 1
without a change. Therefore the evidence-supported successor is the
implementation-planning variant.

---

## N. AUTHORIZED SUCCESSOR

```text
AUTHORIZED_SUCCESSOR_COUNT = 1
AUTHORIZED_SUCCESSOR       = PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING
SUCCESSOR_CLASS            = PLANNING ONLY (implementation + test + execution-gate planning)
SUCCESSOR_IN SCOPE         = design the signIn-first linker path (C1-C8); UI copy;
                             test plan (existing identity, duplicate guards,
                             membership reuse, no-shop-creation);
                             execution plan that REQUIRES a further owner
                             authorization gate before any production action.
SUCCESSOR MUST NOT         = implement/commit code, run signIn/signUp against
                             production, write cloud_uuid, create shop/membership,
                             mutate Auth/SQL, build/release, or start anything.
SUCCESSOR_STARTED          = NO
```

## O. FORENSIC QUESTION RESULTS (explicit)

```text
Q1  Does signUp user!=null && session==null == "unconfirmed" without
    distinguishing an existing confirmed account?
    PARTIAL — the equation is VERIFIED in code (cloud_auth_service.dart:149-152);
    for an existing CONFIRMED account standard GoTrue signUp instead raises
    "already registered" → cloudAccountExists fail-closed (VERIFIED mapping).
    Whether this server can emit user-without-session for a confirmed account
    is NOT PROVEN. Either way the flow has no sign-in fallback (VERIFIED). Entity
    distinction is absent for the "already exists" case (dead end).

Q2  Can that explain the owner's production observation? When first shown, the
    message matched a genuinely new unconfirmed account (created 15:34). It does
    NOT explain a currently-unconfirmed state, which has been DISPROVED. The
    misleading risk is forward (retry dead-ends, no sign-in path).

Q3  Auth identity exists + confirmed?               OWNER-PROVIDED EVIDENCE = YES
Q4  Prior successful login?                          OWNER-PROVIDED EVIDENCE = YES
Q5  Another confirmation email needed?               NO (owner evidence; none dispatched)
Q6  signUp retry forbidden for this identity?        YES — account exists+confirmed;
                                                        retry cannot produce a session
                                                        and is governance-forbidden.
Q7  signIn-based route technically correct?          YES — VERIFIED (signInWithPassword
                                                        returns a real session for
                                                        confirmed credentials).
Q8  Reuse existing persistence/link logic after signIn? PARTIAL — _persistIdentity is
        reusable in principle but has no overwrite guard and only the guarded
        wrappers may call it; current wrappers are signUp-gated; a new guarded
        signIn-first wrapper is REQUIRED. recoverOnboarding does NOT apply to an
        unlinked local owner (equality query vs NULL).
Q9  Any current path call create_shop_with_owner after signIn?  NO — createShopWithOwner
        is reached only after a NEW successful signUp; unreachable for this
        confirmed identity (VERIFIED trace).
Q10 Could that create a second shop? At SERVER level YES if create_shop_with_owner
        were invoked again (no UNIQUE, no RPC check — VERIFIED). At CLIENT level NO
        for this identity today (unreachable). Future linker MUST hard-forbid it.
Q11 Exact preconditions?      See Section K (C1-C8) — all must hold; fail closed.
Q12 cloud_uuid null/unwritten? INFERRED = NULL/UNWRITTEN (code-path grounding + UI
        evidence; local DB NOT read; nothing written).
Q13 0e681dc8-... → eventual cloud_uuid? INFERRED YES; must be confirmed at
        execution; NOT written this session.
Q14 Minimum future production sequence? See Section K (C1-C8) conceptual sequence.
        SignUp excluded; create_shop_with_owner excluded; signIn only.
```

## P. REMOTE LOCK EVIDENCE

```text
PRE-PUSH ENTRY LOCK (certified immediately before commit/push this session):

LOCAL_HEAD         = e0c8e6a51dea13ecf016c3707107ca0449b47820               VERIFIED
TRACKING_HEAD      = e0c8e6a51dea13ecf016c3707107ca0449b47820
                     (github/codex/i-tech-next-roadmap-freeze)              VERIFIED
DIRECT_GITHUB_HEAD = e0c8e6a51dea13ecf016c3707107ca0449b47820
                     (git ls-remote github refs/heads/codex/i-tech-next-
                      roadmap-freeze; no fetch)                             VERIFIED
MERGE_BASE         = e0c8e6a51dea13ecf016c3707107ca0449b47820               VERIFIED
AHEAD              = 0     BEHIND = 0                                       VERIFIED

POST-PUSH VERIFICATION (executed after the normal fast-forward push; not
fabricated): LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE with AHEAD = 0
and BEHIND = 0, verified by re-running the identical checks and recorded in the
session terminal evidence. Normal push only; no force; no tag; origin never
contacted; sacred untracked inventory preserved byte-for-byte; no active Git
operation.

REMOTE_LOCK_STATUS = LOCKED
```

---

## Q. TEAM / OWNERSHIP BOUNDARY

```text
This work is owned by AGENTS.md_authorized I Tech Store Management / muaman_store
only. No GRAIN WAREHOUSE (Codex) and no Teacher Assistant (Kilo) work was
touched, invoked, imitated, or handed off.
```

---

## R. FINAL DECLARATIONS

```text
OWNER_DECISION =
  RECONCILE CONFIRMED EXISTING AUTH IDENTITY VIA CONTROLLED SIGNIN-BASED
  EXISTING-ACCOUNT LINK (implementation planning first)

AUTH_IDENTITY_EXISTS           = YES
AUTH_IDENTITY_UID              = 0e681dc8-8055-4403-aba3-9d1146d4747e
EMAIL_CONFIRMED                = YES
PRIOR_SUCCESSFUL_SIGN_IN       = YES
RECONFIRMATION_REQUIRED        = NO
PREVIOUS_PENDING_IDENTITY_INFERENCE =
  DISPROVED_BY_OWNER_PROVIDED_SUPABASE_AUTH_USER_EVIDENCE
SIGNUP_RETRY                   = NO
SIGNIN_LINK_EXECUTED           = NO
EMAIL_CONFIRMATION_EXECUTED    = NO
EMAIL_CONFIRMATION_RESEND      = NO
AUTH_ADMIN_MUTATION            = NO
DIRECT_SQL                     = NO
SHOP_CREATED                   = NO
MEMBERSHIP_CREATED             = NO
CLOUD_UUID_WRITTEN             = NO
IDENTITY_LINK_EXECUTED         = NO
MIGRATION_EXECUTED             = NO
OD7_SYNC_DRAIN_ACTIVATED       = NO
ANDROID_BUILD_STARTED          = NO
PRODUCTION_MUTATION            = NONE
AUTHORIZED_SUCCESSOR           = PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_PLANNING
AUTHORIZED_SUCCESSOR_COUNT     = 1
SUCCESSOR_STARTED              = NO
TAG_CREATED                    = NO
ORIGIN_CONTACTED               = NO
MANDATORY_STOP_REACHED         = YES
```

*End of confirmed existing auth identity reconciliation owner decision report.*