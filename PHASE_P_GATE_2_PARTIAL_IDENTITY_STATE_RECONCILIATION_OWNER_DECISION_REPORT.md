# PHASE_P_GATE_2_PARTIAL_IDENTITY_STATE_RECONCILIATION — OWNER DECISION REPORT

> GOVERNANCE + FORENSICS + OWNER-DECISION-PREPARATION SESSION. READ-ONLY.
> No production mutation is authorized or performed in this session.
> This artifact prepares the finite minimum-safe owner decision set after the
> blocked partial identity-link state reported by
> `PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_REPORT.md`
> (BLOCKED_PARTIAL_STATE_REQUIRES_OWNER_DECISION).
>
> THIS SESSION PERFORMED: fresh repository / Git / remote-lock forensics; read
> of the predecessor execution report and the full authorization chain; read-only
> code-path forensics of `IdentityLinker.linkExistingUser`, `CloudAuthService`,
> the settings dialog, the login GATE chain, and the server function
> `create_shop_with_owner`; emailed-state and multiple-submission safety
> analysis using only non-privileged evidence; this governance artifact.
>
> THIS SESSION DID NOT: resubmit the identity-link action, press
> «ربط الحساب السحابي», retry signup/login/link, resend confirmation, create /
> delete / update an Auth user, use Auth Admin / service_role / Dashboard, run
> corrective SQL, modify profiles/shops/memberships, force-link, rebuild or
> reinstall the APK, run migrations, activate OD7, or contact `origin`.
>
> Contains NO passwords, NO owner email value, NO service-role key, NO real
> Supabase URL value, NO anon/publishable key value, NO access tokens, NO
> signing secrets. Commit hashes, device serial, package id, mechanism names,
> and derived facts only.

---

## A. SESSION RESULT

```text
RESULT_TOKEN =
PASS_PHASE_P_GATE_2_PARTIAL_IDENTITY_STATE_RECONCILIATION_OWNER_DECISION_REMOTE_LOCKED

SESSION        = PHASE_P_GATE_2_PARTIAL_IDENTITY_STATE_RECONCILIATION_OWNER_DECISION
SESSION_CLASS  = FRESH FORENSICS + READ-ONLY STATE RECONCILIATION + OWNER DECISION
                 GOVERNANCE + SUCCESSOR AUTHORIZATION
CONTROLLING PREDECESSOR = PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_REPORT.md
PREDECESSOR RESULT      = BLOCKED_PARTIAL_STATE_REQUIRES_OWNER_DECISION
PRODUCTION_MUTATION     = NONE
IDENTITY_LINK_RETRY     = NO
EMAIL_CONFIRMATION_ACTION = NO
AUTH_ADMIN_MUTATION     = NO
DIRECT_SQL              = NO
MIGRATION_EXECUTED      = NO
OD7_SYNC_DRAIN_ACTIVATED = NO
SUCCESSOR_STARTED       = NO
MANDATORY_STOP_REACHED  = YES
ORIGIN_CONTACTED        = NO
```

---

## B. REPOSITORY IDENTITY (VERIFIED this session)

```text
ROOT           = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze            VERIFIED
GIT_DIR        = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze
                 (linked worktree; .git is NOT a directory)                     VERIFIED
BRANCH         = codex/i-tech-next-roadmap-freeze                               VERIFIED
TRACKING       = github/codex/i-tech-next-roadmap-freeze                        VERIFIED
AUTHORIZED_REMOTE = github  https://github.com/sabere342-ai/muaman.worktrees.git  VERIFIED
FORBIDDEN_REMOTE  = origin  (read locally ONLY; NEVER contacted)                VERIFIED
```

---

## C. ENTRY FORENSICS (VERIFIED this session)

```text
MANDATORY ENTRY HEAD      = c887b3ca2e6d66893c3649f29972148e3e50e1ae          VERIFIED
HEAD_SUBJECT              = "docs: record blocked gate-2 production identity
                            link execution"                                    VERIFIED

LOCAL_HEAD          = c887b3ca2e6d66893c3649f29972148e3e50e1ae                VERIFIED
TRACKING_HEAD       = c887b3ca2e6d66893c3649f29972148e3e50e1ae                VERIFIED
DIRECT_GITHUB_HEAD  = c887b3ca2e6d66893c3649f29972148e3e50e1ae
                      (git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze;
                       no fetch, no ref mutation)                              VERIFIED
MERGE_BASE          = c887b3ca2e6d66893c3649f29972148e3e50e1ae                VERIFIED
AHEAD               = 0   BEHIND = 0                                          VERIFIED

ACTIVE_GIT_OPS      = NONE (VERIFIED)
   MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG /
   rebase-merge / rebase-apply / index.lock     ALL ABSENT                    VERIFIED
   ORIG_HEAD present only as benign residue of a past operation; not a marker
   of an active Git operation, consistent with the checked-in predecessor
   baseline.                                                                   VERIFIED

STAGED              = 0                                                       VERIFIED
TRACKED_MODIFIED    = 0                                                       VERIFIED
TRACKED_DELETED     = 0                                                       VERIFIED
STASH               = 1 entry (stash@{0}: WIP on
                      codex/muaman-13-strict-july-workbook-data-migration:
                      283ff9d ...), PRESERVED, NOT TOUCHED, NOT APPLIED        VERIFIED
ENTRY_CLASS         = CASE_A_CLEAN (with pre-existing sacred untracked inventory)
```

### Sacred Untracked Inventory (re-enumerated this session, 16 entries — PRESERVED unchanged)

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
supabase/.branches/          (NOT modified; NOT staged; NOT read)
supabase/.temp/              (may be secret-bearing; NOT read, NOT printed,
                              NOT staged, NOT modified, NOT deleted)
```

None of these was staged, modified, deleted, renamed, or normalized this session.

---

## D. CONTROLLING AUTHORIZATION CHAIN (VERIFIED this session from repository evidence)

Reconstructed commit chain (newest → oldest):

```text
c887b3c  docs: record blocked gate-2 production identity link execution   <- predecessor EXECUTION REPORT (current HEAD)
6ba0675  docs: reauthorize gate-2 identity link with new-email collision guard
         -> PHASE_P_GATE_2_..._EMAIL_UNIQUENESS_REAUTHORIZATION_REPORT.md
         -> decision: REAUTHORIZE_WITH_GENUINELY_NEW_OWNER_SELECTED_PRODUCTION_EMAIL
            AND_CANONICAL_COLLISION_GUARD; ONE canonical attempt, fail-closed.
564473b  docs: reauthorize gate-2 existing-owner production identity-link execution
         -> PHASE_P_GATE_2_..._REAUTHORIZATION_REPORT.md
         -> reauthorizes M1+M2 existing-owner link execution via canonical flow.
d1e9a68  feat: add owner-only existing-cloud-link entry in settings
         -> the installed production build source (approved APK
            53D5978D...015BE4, versionCode 3 / versionName 1.0.0 / targetSdk 36).
3fc32d7  docs: authorize gate-2 production identity linkage read-only reconciliation
         -> transaction that produced
            PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION_REPORT.md
            (all-only-smoke production tenants; recommended canonical Option A).
0fcbd27  fix: expose cloudUuid on User model to fix post-auth login crash
         (following PHASE_P_POST_PRODUCTION_CONFIG_GATE_2_IDENTITY_LINKAGE_OWNER_AUTHORIZATION
          which approved the read-only reconciliation successor on paper only).
```

```text
OWNER AUTHORIZATION      -> READ-ONLY RECONCILIATION (approved on paper)
EXECUTION REAUTHORIZATION -> M1+M2 via Settings -> «حالة المزامنة» -> «ربط الحساب السحابي»
                             -> IdentityLinker.linkExistingUser (ONE canonical attempt)
EMAIL-UNIQUENESS REAUTHORIZATION -> genuinely-new owner-selected email + canonical
                             collision guard fail-closed
PRODUCTION EXECUTION     -> attempt executed by owner on device f0deca9
BLOCKED PARTIAL STATE    -> BLOCKED_PARTIAL_STATE_REQUIRES_OWNER_DECISION
                             (this predecessor, committed at c887b3c)
```

Predecessor device/build facts preserved (VERIFIED in predecessor, not re-verified
by this read-only session): serial `f0deca9`, package `com.itech.storemanagement`,
installed production APK `53D5978D0F0FB1EF9324BE3F70431F7CCC474DDFFC4C7947FF58434136015BE4`
harvested from source commit `d1e9a68c20098d21c556301ec2eb18dd822bec91`.

---

## E. PREDECESSOR PARTIAL STATE (exact, preserved)

```text
PRE-MUTATION CHECKPOINT  = PASS (owner login, role owner, UNLINKED, entry visible,
                           password equality YES, new-email policy YES,
                           collision rule accepted, ONE-CANONICAL-ATTEMPT contract)
CANONICAL_SUBMISSION     = MORE THAN ONE press (owner-confirmed contract breach)
ONE_SUBMISSION_RULE      = VIOLATED by the physical operator; OpenCode performed
                           no retry (RE-RECORDED, NOT normalized, NOT concealed)
APP MESSAGE (read-only)  = «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول»
POST STATE (UI read-only)= Settings -> «حالة المزامنة» -> «ربط الحساب السحابي»
                           STILL VISIBLE; LOCAL LINK STATE = UNLINKED
M1 (CLOUD)               = NOT VERIFIED AS COMPLETED (no session ever returned)
M2 (LOCAL PERSIST)       = NOT OBSERVED (users.cloud_uuid, shopProfile.cloudUuid,
                           cloud.auth.email not written; UI reflects unlinked)
MIGRATION / OD7 / M3     = not executed
```

The predecessor did NOT commit any privileged read, any cleanup, any SQL, any
Auth Admin mutation, any service-role action, or any repair.

---

## F. CODE-PATH FINDINGS (read-only; VERIFIED against source)

### F1. Canonical flow

```text
UI           = app/lib/screens/settings_screen.dart:754 (owner-only, !isCloudLinked)
               -> _openCloudLinkDialog (:777) -> dialog (email/password/shopName)
               -> _runCloudLink (:917) -> IdentityLinker.linkExistingUser
FLOW         = app/lib/services/identity_linker.dart:85
               -> CloudAuthService.signUp  (app/lib/services/cloud_auth_service.dart:135)
               -> [only on session] createShopWithOwner (RPC create_shop_with_owner)
               -> [only on success] _persistIdentity (identity_linker.dart:220)
```

### F2. Answers to the mandated questions (evidence-grounded)

**Q1. Does the flow call signUp before signIn?**
YES with respect to ordering, and it never calls signIn at all. `linkExistingUser`
calls `_cloudAuth.signUp` only (identity_linker.dart:111). `signInWithPassword`
appears only in `LoginScreen._attemptCloudSession` (login_screen.dart:152), which
is gated on a NON-EMPTY local `users.cloud_uuid` (`:145`) and
`cloud.auth.email` (`:148`) — i.e. reaches GATE_3 only after a link already
persisted. VERIFIED.

**Q2. Under email-confirmation-required configuration, what state can exist after signUp returns but before confirmation?**
When Supabase Auth requires email confirmation, `signUp` returns an HTTP success
carrying a `user` row with `session == null`. The app maps exactly this to
`unknownError('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول')`
(cloud_auth_service.dart:149-151). In that state an Auth identity exists
(unconfirmed/pending) and the client holds NO authenticated session. VERIFIED
from code + Supabase Auth contract.

**Q3. Can signUp create an Auth identity without returning an authenticated session?**
YES. In confirmation-required mode `signUp` creates the identity and returns no
session; that is precisely the observed code branch. VERIFIED.

**Q4. What exact code is expected to perform M1?**
M1 = one Supabase Auth identity via `CloudAuthService.signUp`
(cloud_auth_service.dart:140), then ONE shop + ONE owner ACTIVE membership via
the `create_shop_with_owner` RPC
(supabase/migrations/20260820000020_database_functions.sql:18). This motion is
only reachable when `signUpResult.session != null` (identity_linker.dart:122).
VERIFIED.

**Q5. What exact code is expected to perform M2?**
M2 = `IdentityLinker._persistIdentity` (identity_linker.dart:220-241) writing
`users.cloud_uuid`, `app_settings['shopProfile.cloudUuid']`,
`app_settings['cloud.auth.email']`. VERIFIED.

**Q6. Does M2 occur only after a valid session?**
YES. `_persistIdentity` runs only after a non-null signUp session AND a
successful `createShopWithOwner`. VERIFIED.

**Q7. Could repeated physical presses result in repeated signUp attempts, "user already registered", confirmation-related error, rate-limit, or another deterministic state?**
Each press that re-submits the dialog result re-invokes `linkExistingUser` → one
`signUp` call (tests likewise assert `signUpCalls == 1` per canonical attempt).
For the SAME email, Supabase Auth holds a uniqueness invariant on email across
Auth identities, so repeated `signUp` cannot mint a second identity. Per the
GoTrue contract the calls can resolve as:
  (a) user + `session:null` again (unconfirmed user exists) → same
      «يرجى تأكيد...» message — CONSISTENT WITH OBSERVED STATE;
  (b) an "already registered" error for a CONFIRMED existing email → app maps to
      `cloudAccountExists` → «هذا البريد الإلكتروني مسجل مسبقًا في حساب سحابي»
      (settings_screen.dart:961) — NOT observed;
  (c) rate-limit (HTTP 429) → raw `unknownError` message — NOT observed.
Because the last observed message was the confirmation message, the repeated
attempts are consistent with a single pending/unconfirmed identity.
VERIFIED (mechanics from code + auth contract); ACTUAL SERVER COUNT of emails
sent/attempt dispositions NOT VERIFIED.

**Q8. Is any retry idempotent?**
`signUp` against an EXISTING UNCONFIRMED email is row-idempotent: Supabase's
email-uniqueness invariant prevents a second identity. It can, however, trigger
GoTrue's confirmation-email dispatch behavior (possible re-send) and rate-limit
counters — side effects, not row duplication. The pre-submission
`cloud_uuid` check in `linkExistingUser` (identity_linker.dart:92-107) is
read-only and returns early success when a cloud_uuid already exists. VERIFIED.

**Q9. Is any retry NOT idempotent?**
`signUp` on a genuinely NEW email creates a NEW identity (not idempotent), which
is why the governing policy restricted the execution to ONE canonical attempt.
Repeated presses against a NEW email would each be a distinct attempt with the
uniqueness invariant preventing duplicates, but the confirmation-dispatch /
rate-limit side effects are not idempotent. The result-classification of the
second attempt can also flip from "confirmation required" to "already
registered" once the identity becomes confirmed. VERIFIED mechanics.

**Q10. Minimum safe reconciliation path (derived, not executed):**
Never re-submit the link for the same email before the pending identity is
resolved. Confirmation is an owner-side action (clicking the emailed
link/OTP), distinct from link submission. NOTE (VERIFIED code-level caveat):
after the email becomes CONFIRMED, `signUp` for that SAME email returns
"already registered" → `cloudAccountExists` fail-closed — the current
canonical dialog is a *create-new-account* flow (signUp), NOT a *link-existing-
confirmed-account* flow (signIn). Therefore confirming the pending email does
NOT by itself complete the local link; a subsequent authorized decision is
required for HOW to link (see Section K).

---

## G. EMAIL-CONFIRMATION ANALYSIS

Observed message: «يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول».

```text
THE ONLY string producer is cloud_auth_service.dart:150-151:
   if (response.user != null) return
       CloudSignUpResult.unknownError('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول');
This branch is reached ONLY when signUp returned user != null AND session == null.
(cf. seller path seller_session_provisioning.dart:284 uses the same string for a
 DIFFERENT route — signIn 'email not confirmed' — but that flow is NOT the owner
 settings link flow.)
```

Interpretation classified:

```text
VERIFIED   The canonical signUp request ended in a user-present / session-absent
           response (the exact app branch that produced the observed message).
VERIFIED   NO authenticated session was held by the flow at that point; therefore
           createShopWithOwner (requires auth.uid()) was NOT executed for this
           attempt; no shop and no membership could be created.
INFERRED   A pending/unconfirmed Auth identity now exists for the entered email
           (GoTrue confirmation-required contract). "Pending", not "confirmed",
           because no session was issued.
UNKNOWN    The exact confirmation status, the identity UID, and whether GoTrue
           resent confirmation messages on later presses — these require a
           privileged Auth-admin read (NOT authorized this session).
```

The message is NOT the `cloudAccountExists` string («هذا البريد الإلكتروني مسجل
مسبقًا...»), so at the time of the observation the flow was on the
confirmation-required path, not the already-registered-confirmed path.
Classification: (A/B in the outer question) — signUp succeeded and confirmation
is pending (A) OR an existing unconfirmed user was encountered (C); the app
cannot distinguish those two server-side, and neither can any non-privileged
client. BOTH reduce to "pending identity exists; no session; no app-level
cloud linkage."

---

## H. MULTIPLE-SUBMISSION SAFETY ANALYSIS

Re-recorded without normalization:
```text
ONE_SUBMISSION_RULE = VIOLATED.
CANONICAL_SUBMISSION_PRESSES = MORE THAN ONCE (owner-confirmed).
RETRY_COUNT          = 1+ (owner-confirmed; rule-violating).
OPECODE RETRY        = NONE.
```

Safety assessment from code/schema/constraints (no mutation performed):

```text
MULTIPLE AUTH IDENTITIES  = PREVENTED. Supabase Auth enforces email uniqueness
                            across identities for the email identity provider;
                            repeated signUp for one email can never create a
                            second identity row.            VERIFIED (platform constraint)
MULTIPLE SHOPS            = PREVENTED. create_shop_with_owner runs only with a
                            non-null auth.uid() (migration 00020:28-31). No
                            session ever existed ⇒ the RPC was not reachable.
                                                            VERIFIED (code path)
MULTIPLE MEMBERSHIPS      = PREVENTED. Memberships are created only inside
                            create_shop_with_owner (00020:44-45), which was not
                            reachable without a session.    VERIFIED (code path)
LOCAL DUPLICATE LINKS     = NONE. _persistIdentity never ran (UI still UNLINKED).
                                                            VERIFIED (predecessor observation)
REPEATED CONFIRMATION DISPATCH / RATE-LIMIT = POSSIBLE side effects of repeated
                            signUp calls; no row-level duplication.
                                                            INFERRED / UNKNOWN
NET DISPOSITION           = at most ONE pending/unconfirmed identity for the
                            entered email. Exact server disposition not
                            externally verifiable without privileged read.
                                                            INFERRED
```

NET: the breach created controllable, non-compounding risk (no duplicate
identities/shops/memberships/local rows). Its primary cost is confirmation/
rate-limit side effects and the loss of the clean one-attempt contract. It must
nonetheless be recorded transparently, as done here.

---

## I. READ-ONLY RECONCILIATION RESULT

Method: only already-authorized, non-privileged, non-mutating evidence —
repository source, tests, and the operator-observed in-app API signal recorded
by the predecessor. No Auth Admin, no service_role, no Dashboard, no SQL, no
CLI dump (a live re-probe would require reading sacred `supabase/.temp`-bound
credentials and would still be unable to read `auth.users`, both of which are
excluded).

```text
STATE A (no cloud identity)            = CANNOT BE EXCLUDED by non-privileged
                                         evidence; contradicted by the strong
                                         app-signal inference below.
STATE B (one pending/unconfirmed Auth identity; no shop/membership)
                                       = MOST PLAUSIBLE. VERIFIED that signUp
                                         returned user-without-session
                                         (exact code branch observed generated
                                         the message); INFERRED that a pending
                                         identity exists; VERIFIED that no
                                         shop/membership can exist.
STATE C (confirmed identity; no app rows) = IMPOSSIBLE to verify as reached;
                                         not evidenced (no session issued).
STATE D (identity + partial app rows)  = EXCLUDED (no session ⇒ RPC unreachable
                                         ⇒ no app rows).  VERIFIED (code path)
STATE E (completed cloud objects, local M2 failed)
                                       = EXCLUDED (M2 failure with completed
                                         cloud objects would require a session
                                         having existed; none ever did).
                                                 VERIFIED (code path)
STATE F (cannot be established safely without privileged production access)
                                       = APPLIES TO THE EXACT A-vs-B EMail
                                         DISPOSITION. Establishing the exact
                                         Auth identity row (UID, confirmation
                                         status) requires a privileged
                                         readonly Auth-admin read, which the
                                         owner has not authorized.
```

```text
CONCLUSION:
1. A cloud session was provably never obtained (VERIFIED).
2. No shop / no membership for the attempted email can exist (VERIFIED via code
   reachability).
3. The link did NOT complete, locally or cloud-side at the app layer (VERIFIED).
4. At most ONE pending/unconfirmed Auth identity plausibly exists for the
   attempted email (VERIFIED code branch + INFERRED server state; exact A-vs-B
   not externally provable without privileged read → STATE F).
```

DEVICE / LOCAL STATE: preserved. No reinstall, no data clear, no local field
write performed here or required for this reconciliation.

---

## J. VERIFIED / INFERRED / UNKNOWN MATRIX

| Fact | Classification |
|------|----------------|
| Repository at c887b3c; remote-locked local==tracking==direct-github==merge-base; ahead/behind 0/0 | VERIFIED |
| Tracked/index clean; no active Git op; stash[0] preserved; 16 sacred untracked entries preserved | VERIFIED |
| Authority chain commits (0fcbd27→3fc32d7→d1e9a68→564473b→6ba0675→c887b3c) | VERIFIED |
| Canonical flow = signUp (not signIn); M1 shop via create_shop_with_owner only with a session | VERIFIED |
| M2 only via _persistIdentity after session + shop creation | VERIFIED |
| Observed message is the exact `user != null && session == null` branch (cloud_auth_service.dart:149-152) | VERIFIED |
| signUp can create an identity without issuing a session (confirmation-required) | VERIFIED |
| No session ⇒ no shop/membership possible (RPC requires auth.uid()) | VERIFIED |
| Local link never written (UI still unlinked) | VERIFIED |
| Email uniqueness prevents multiple identities for one email | VERIFIED (platform constraint) |
| A pending/unconfirmed Auth identity now exists for the attempted email | INFERRED |
| Exact confirmation status / UID / GoTrue dispatch behavior on repeated presses | UNKNOWN |
| STATE B (vs A) as authoritative server fact | UNKNOWN / STATE F without privileged read |
| Migration deployment contradiction (27 local vs 24 remote applied; group-D deferred) — predecessor-dispositioned, unchanged | ACKNOWLEDGED_AND_OWNER_DEFERRED |

---

## K. VIABLE OWNER OPTIONS

The decision set is finite. Each option states prerequisites, allowed scope,
forbidden actions, mutation risk, email-confirmation involvement, privileged
involvement, whether link submission is allowed, and local/device preservation.

### OPTION A — CONFIRM THE EXISTING PENDING EMAIL ONLY (owner-side action)

Only if the owner can confirm the pending identity (they would click the
confirmation link / enter the OTP from the email that the canonical attempt
generated).

```text
PREREQUISITES        = A confirmation email/OTP exists for the attempted email
                       (INFERRED) and the owner controls that mailbox.
ALLOWED SCOPE        = Owner performs the confirmation OUTSIDE the app and
                       outside OpenCode. OpenCode does nothing at this step.
FORBIDDEN            = any app-side link submission; any resend; any retry of
                       «ربط الحساب السحابي»; any privileged action.
PRODUCTION MUTATION RISK = LOW and owner-side; creates the CONFIRMED identity,
                       which is exactly the natural disposition of the pending one.
EMAIL CONFIRMATION   = YES — this option IS the confirmation action.
PRIVILEGED ACCESS    = NO.
IDENTITY-LINK SUBMISSION ALLOWED = NO at this step.
LOCAL/DEVICE PRESERVED = YES.
CRITICAL CAVEAT      = Confirming alone does NOT complete the link: the current
                       canonical dialog is signUp-based. Once confirmed,
                       signUp with the same email fails closed with
                       cloudAccountExists. A further separate owner decision on
                       HOW to link is therefore REQUIRED after this option
                       (see note in Section L).
```

### OPTION B — READ-ONLY PRIVILEGED RECONCILIATION FIRST

Only if the owner needs the exact A-vs-B answer (identity UID / confirmation
status) before deciding anything else.

```text
PREREQUISITES        = owner explicitly authorizes a narrowly scoped privileged
                       READ-ONLY inspection (scoped Authorized-Auth lookup for
                       the attempted email ONLY / SELECT-style).
ALLOWED SCOPE        = privileged READ ONLY; no mutation of any kind.
FORBIDDEN            = create/delete/update Auth, resend, SQL mutation, RLS,
                       service-role writes, Dashboard mutation, link submission.
PRODUCTION MUTATION RISK = NONE (read-only only).
EMAIL CONFIRMATION   = NOT performed here.
PRIVILEGED ACCESS    = YES (read-only only).
IDENTITY-LINK SUBMISSION ALLOWED = NO.
LOCAL/DEVICE PRESERVED = YES.
```

### OPTION C — CONTROLLED RECOVERY / CLEANUP (separate authorization; NOT this session)

Only if evidence supports that a partial production object must be repaired or
removed (e.g., the owner abandons the attempted email and wants the orphan
pending identity deleted).

```text
PREREQUISITES        = a separate, explicit owner authorization naming the exact
                       object and the exact privileged cleanup scope.
ALLOWED SCOPE        = that authorized cleanup ONLY.
FORBIDDEN            = anything not in that authorization; any unapproved repair.
PRODUCTION MUTATION RISK = HIGH (production destructive action) — requires its
                       own gate; MUST NOT start from this session.
EMAIL CONFIRMATION   = not applicable / not to be conflated.
PRIVILEGED ACCESS    = YES (Auth Admin / service-role cleanup).
IDENTITY-LINK SUBMISSION ALLOWED = NO.
LOCAL/DEVICE PRESERVED = YES (target server object only).
```

### OPTION D — ABANDON THE CURRENT IDENTITY-LINK ATTEMPT

Only if the owner chooses to stop pursuing the current link entirely.

```text
PREREQUISITES        = owner accepts the pending identity may remain (or be
                       cleaned later under a separate OPTION C authorization).
ALLOWED SCOPE        = no further cloud-link action; app continues local-only
                       («غير مرتبط بالسحابة» remains).
FORBIDDEN            = link submission; automated cleanup without a separate
                       authorization.
PRODUCTION MUTATION RISK = NONE now; orphan identity remains unless separately
                       dispositioned.
EMAIL CONFIRMATION   = NOT required.
PRIVILEGED ACCESS    = NO (unless later cleanup authorized).
IDENTITY-LINK SUBMISSION ALLOWED = NO.
LOCAL/DEVICE PRESERVED = YES.
```

### OPTION E — OTHER EXACT MINIMUM-SAFE SUCCESSOR

Allowed ONLY if forensics proves A-D do not correctly represent the state. No
such proof exists; no OTHER option is proposed by this session.

---

## L. RECOMMENDED MINIMUM-SAFE OPTION (recommendation ONLY — NOT execution authorization)

```text
RECOMMENDATION = OPTION A FIRST (owner controls the pending-email confirmation
                 click, entirely outside OpenCode), THEN a NEW explicit owner
                 decision to select the linking route, because:

  1. The strongly preferred safety direction (session section 11) forbids any
     further identity-link submission until the pending identity is resolved.
  2. No privileged access, no production mutation by an agent, and no app-side
     resubmission are needed for OPTION A.
  3. OPTION B remains the definitive answer-er ONLY if the owner prefers proof
     before acting or cannot confirm the email.

REQUIRED FURTHER DECISION AFTER CONFIRMATION (do NOT proceed automatically):
  The current canonical dialog is signUp-based; a CONFIRMED email cannot be
  re-registered by signUp (it fails closed with cloudAccountExists). So the
  owner must still choose one of:
    L1. A genuinely-NEW owner-selected email through the same canonical flow
        (re-authorization for a new execution session; the pending/confirmed
        old address is left as an orphan or separately cleaned under OPTION C).
    L2. Authorize a code change for a signIn-based "link existing confirmed
        account" path (implementation authorization + tests), then a new
        execution session.
    L3. OPTION D (abandon cloud linking) instead.
  DECISION BETWEEN L1/L2/L3 = OWNER ONLY.
```

This recommendation is advisory. It grants no authority to OpenCode to confirm,
resend, submit, sign in, create, delete, or repair anything.

---

## M. EXPLICIT NON-ACTIONS (this session)

```text
IDENTITY-LINK SUBMISSION / RETRY   = NO
«ربط الحساب السحابي» PRESSED       = NO
EMAIL CONFIRMATION / RESEND        = NO
AUTH USER CREATE / DELETE / UPDATE = NO
SHOP / MEMBERSHIP CREATE or DELETE = NO
users.cloud_uuid / shopProfile.cloudUuid / cloud.auth.email WRITE = NO
LOCAL DB / DEVICE DATA MUTATION    = NO
DIRECT SQL / RPC MUTATION          = NO
SERVICE-ROLE                       = NO
AUTH ADMIN (read or write)         = NO
SUPABASE DASHBOARD                 = NO
MIGRATIONS (00036/00037/00038)     = NO
OD7 SYNC DRAIN                     = NO
APK REBUILD / REINSTALL / PM CLEAR = NO
FORCE-LINK / MERGE / ATTACHMENT    = NO
SMOKE TENANT REUSE (290c617f-…, aa8542a9-…) = NO
SOURCE / CONFIG CHANGE             = NO
ORIGIN CONTACT                     = NO
SECRETS READ / PRINTED / COMMITTED = NO (incl. supabase/.temp/ untouched)
STAT. LIVE PROBE                   = NO (credential-bound .temp access excluded;
                                       would not have resolved A-vs-B anyway)
```

---

## N. SUCCESSOR AUTHORIZATION STATUS

```text
SUCCESSOR_STARTED   = NO
OWNER GATE          = OPEN — a NEW explicit owner decision is required before
                      any further production action, privileged read, code
                      change, confirmation handling, or cleanup.
POSSIBLE SUCCESSORS = 1) owner performs OPTION A confirmation, then another
                      separately-authorized session for L1/L2/L3;
                      2) OPTION B privileged-read-only reconciliation session;
                      3) OPTION C cleanup session (separate authorization);
                      4) OPTION D abandon.
NO successor may begin in, or be inferred from, this session.
```

---

## O. STOP DECLARATION

```text
SUCCESSOR_STARTED          = NO
PRODUCTION_MUTATION        = NONE
IDENTITY_LINK_RETRY        = NO
EMAIL_CONFIRMATION_ACTION  = NO
AUTH_ADMIN_MUTATION        = NO
DIRECT_SQL                 = NO
MIGRATION_EXECUTED         = NO
OD7_SYNC_DRAIN_ACTIVATED   = NO
MANDATORY_STOP_REACHED     = YES
```

Even though OPTION A appears straightforward, it is presented as a
recommendation only. This session stops and waits for the explicit owner
decision.

*End of predecessor-state reconciliation owner-decision report.*