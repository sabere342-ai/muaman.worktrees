# PHASE P — POST WINDOWS DELIVERY
## PRIVATE CUSTOMER HANDOFF — CANONICAL PLANNING

> PLANNING / GOVERNANCE ONLY — REMOTE LOCK.
>
> This session is the exact single successor explicitly authorized by the
> committed Owner decision
> `PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_POST_EXECUTION_OWNER_DECISION.md`
> (commit `1c952d6a81f87587851194ca8cbbab86cd772f29`,
> result
> `PASS_PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_POST_EXECUTION_OWNER_DECISION_REMOTE_LOCKED`)
> under `OWNER_DECISION = D2`:
> `PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING`,
> `SUCCESSOR_SESSION_CLASS = PLANNING_ONLY`.
>
> This session produces the canonical governance/implementation plan for a
> CONTROLLED PRIVATE WINDOWS CUSTOMER HANDOFF. It MUST NOT execute the handoff.
>
> No publication, no distribution, no customer handoff, no file transfer, no
> upload, no cloud-share creation, no GitHub Release, no contact with any
> customer, no code signing, no installer creation, no Windows rebuild, no
> RC/ZIP regeneration, no Android work, no Production/Supabase work, no P/OD7 /
> Sync Drain work, no licensing production activation, no durable-archive
> mutation, no sacred-legacy-ZIP mutation, and no repository cleanup occurs in
> this session.
>
> This report contains NO passwords, NO DPAPI ciphertext, NO private key
> material, NO keystore bytes, NO Supabase secrets, NO service-role keys, NO
> access tokens, NO GitHub credentials, and NO recipient personal data.

---

## A. Planning Result

```text
SESSION       = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING
SESSION_CLASS = PLANNING_GOVERNANCE_ONLY

ROOT                  = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH                = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE     = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
FORBIDDEN_REMOTE      = origin

HANDOFF_CLASS  = PRIVATE_CONTROLLED_CUSTOMER_HANDOFF
PLANNING_COMPLETE = YES

RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING_REMOTE_LOCKED
```

The PASS means (all verified live this session):

```text
PLANNING_COMPLETE       = YES
PUBLICATION_EXECUTED    = NO
DISTRIBUTION_EXECUTED   = NO
CUSTOMER_HANDOFF_EXECUTED = NO
FILE_TRANSFER_EXECUTED  = NO
CUSTOMER_CONTACTED      = NO
UPLOAD_EXECUTED         = NO
GITHUB_RELEASE_CREATED  = NO
CODE_SIGNING_EXECUTED   = NO
INSTALLER_CREATED       = NO
WINDOWS_REBUILT         = NO
RC_REGENERATED          = NO
ANDROID_EXECUTED        = NO
PRODUCTION_EXECUTED     = NO
SUPABASE_MUTATION       = NO
P_OD7_EXECUTED          = NO
SYNC_DRAIN_EXECUTED     = NO

DURABLE_ARCHIVE_MODIFIED    = NO
SACRED_LEGACY_ZIP_MODIFIED  = NO
ORIGIN_CONTACTED            = NO

EXECUTION_AUTHORIZED = NO
NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED_FOR_EXECUTION = YES
SUCCESSOR_STARTED = NO
SESSION_STOPPED   = YES
```

---

## B. Repository Identity

Verified live from repository evidence (forensics, not trust of this prompt
alone):

```text
ROOT    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree)
COMMON_DIR = C:/dev/muaman/.git
BRANCH  = codex/i-tech-next-roadmap-freeze
HEAD    = 1c952d6a81f87587851194ca8cbbab86cd772f29
SUBJECT = docs: decide post-archive windows successor
TRACKING_REF = refs/remotes/github/codex/i-tech-next-roadmap-freeze
```

Remote configuration (read-only inspection of `git remote -v`, no network
mutation):

```text
github  https://github.com/sabere342-ai/muaman.worktrees.git (fetch)
github  https://github.com/sabere342-ai/muaman.worktrees.git (push)
origin  C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (legacy; FORBIDDEN)
```

```text
REPOSITORY_IDENTITY_VERIFIED = TRUE
ORIGIN_CONTACTED             = NO
```

No fetch was run; direct GitHub verification used read-only `git ls-remote
github` (no Git metadata mutated).

Product identity context (verified from repository evidence, NOT modified):

```text
APP_ROOT        = app/ (app/pubspec.yaml EXISTS)
PUBSpec_VERSION = 1.0.0+1 (semantic 1.0.0, build 1)
APPLICATION_ID (Android evidence file) = com.itech.storemanagement (reference; no Android work this session)
```

---

## C. AGENTS / Skills

AGENTS inventory (`glob **/AGENTS.md` live):

```text
AGENTS_FILES_FOUND  =
  C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/AGENTS.md
  (single applicable AGENTS.md in the canonical working root; glob confirmed no
   nested AGENTS.md anywhere else in the repository)
AGENTS_FILES_APPLIED =
  C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/AGENTS.md
  (evidence-first; linked-worktree awareness; remote-lock contract; scope
   allowlist; commit/push discipline; PowerShell 5.1 execution rules; stop
   conditions; definition of done; owner-decision gates; remote-safety;
   no-autonomous-successor rule)
AGENTS_CONFLICTS    = NONE
```

Skill discovery in THIS runtime (available skill registry, live):

```text
SKILLS_DISCOVERED =
  customize-opencode, dart-add-unit-test, dart-collect-coverage, find-skills,
  flutter-accessibility, flutter-add-integration-test, flutter-add-widget-test,
  flutter-apply-architecture-best-practices, flutter-code-review,
  flutter-core-engineering, flutter-offline-data, flutter-performance,
  flutter-release, flutter-rtl-arabic, flutter-security, flutter-testing,
  flutter-ui-ux, frontend-design
```

```text
SKILLS_USED           = flutter-release (loaded; SKILL.md read completely;
                        release-evidence-checklist read; used only as release
                        governance / artifact-identity reference)
PRIMARY_SKILL         = flutter-release
SKILL_SCOPE_EXPANSION = NONE
```

`flutter-security` was NOT loaded. Rationale (same class as the committed
predecessor planning session `PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING`):
this session only REASONS about a controlled private handoff, checksum identity,
unsigned status (not signing implementation), and a secrets-exclusion policy
stated as constraints for a future execution session. No credential handling,
no artifact transfer, no secure-transfer implementation, and no security
instrumentation is executed here. The secret/privacy boundary is a governance
policy block (section R), not an implementation task requiring the security
skill. No skill grants execution authority.

```text
GRANTS_NO_AUTHORITY          = YES
RECOMMENDATION_IS_NOT_APPROVAL = YES (explicit throughout)
```

---

## D. Entry Classification

Global Git-operation metadata checked via Git-aware path resolution
(`git rev-parse --git-path` + existence probe of the worktree-specific paths):

```text
MERGE_HEAD       = ABSENT
CHERRY_PICK_HEAD = ABSENT
REVERT_HEAD      = ABSENT
BISECT_LOG       = ABSENT
rebase-merge     = ABSENT
rebase-apply     = ABSENT
index.lock       = ABSENT
HEAD.lock        = ABSENT
ACTIVE_GIT_OPERATION = NONE
```

Index and tracking state:

```text
ENTRY_HEAD   = 1c952d6a81f87587851194ca8cbbab86cd772f29
INDEX_STATE  = EMPTY (git diff --cached --name-status = empty at entry)
STASH        = PRESERVED
               (stash@{0}: WIP on
                codex/muaman-13-strict-july-workbook-data-migration:
                283ff9d MUAMAN-12: implement local user roles and sales-only access)
               NOT TOUCHED
```

Pre-existing tracked working-tree residue (present on disk BEFORE this session,
preserved UNTOUCHED) — exactly the documented preserved-residue list carried by
every canonical predecessor; 12 legacy data files deleted on disk (never staged,
never restored, never committed):

```text
شهر7/extract_sales.py
شهر7/شيت_ادارة_محل_مؤمن_مطور_حديث_شهر7.xlsx
قديم/.~lock.شيت_ادارة_محل_مؤمن_حديث_شهر7.xlsx#
قديم/تقرير_الإقفال_الشهري_مؤمن_شهر6.pdf
قديم/جرد_مخزون_معدل_نصف_شهري_محل_مؤمن.xlsx
قديم/شيت_ادارة_محل_مؤمن_حديث.xlsx
قديم/شيت_ادارة_محل_مؤمن_حديث_شهر7.xlsx
قديم/شيت_ادارة_محل_مؤمن_شهر6.xlsx
قديم/شيت_ادارة_محل_مؤمن_شهر7.xlsx
قديم/شيت_ادارة_محل_مؤمن_متكامل_شهر7.xlsx
قديم/شيت_ادارة_محل_مؤمن_متكامل_محدث_شهر7.xlsx
قديم/مشتريات_من_23-5.xlsx
```

Count verified from live `git diff --name-status`: 12 tracked deletions.

Pre-existing untracked residue (inventoried, PRESERVED, NOT staged, NOT deleted,
NOT modified):

```text
Continue                                          (empty directory, preserved)
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip   (SACRED historical residue; preserved read-only)
supabase/.branches/                   (PRESERVED; contains no staged/committed content)
supabase/.temp/                       (PRESERVED; INCLUDES a local start-secrets
                                        docker.env — a SECRET-BEARING file. NOT read,
                                        NOT staged, NOT committed, NOT modified.)
```

```text
ENTRY_CLASSIFICATION =
CASE_B_EXPECTED_DIRTY
  (expected documented preserved residue exactly matches the canonical
   predecessor's preserved-residue list and this session's known-residue
   inventory; LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE,
   AHEAD = 0, BEHIND = 0, index EMPTY, no staged changes, no active Git
   operation. The 12 tracked deletions exist ONLY in the working tree (unstaged)
   and are preserved untouched. They fail the CASE_A tracked-clean test but are
   EXPECTED documented residue, so the state is CASE_B_EXPECTED_DIRTY, identical
   to the classification the direct-authority predecessor
   PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_AND_CHECKSUM_RECORD_EXECUTION
   recorded for the same live state. No residue threatens the allowlist or the
   authority chain.)
```

No fetch was run; direct GitHub verification used read-only `git ls-remote
github`.

```text
ORIGIN_CONTACTED = NO
```

---

## E. Entry Remote-Lock

Network verification used `github` only (read-only `git ls-remote github
refs/heads/codex/i-tech-next-roadmap-freeze`).

```text
ENTRY_LOCAL_HEAD         = 1c952d6a81f87587851194ca8cbbab86cd772f29
ENTRY_TRACKING_HEAD      = 1c952d6a81f87587851194ca8cbbab86cd772f29
ENTRY_DIRECT_GITHUB_HEAD = 1c952d6a81f87587851194ca8cbbab86cd772f29
ENTRY_MERGE_BASE         = 1c952d6a81f87587851194ca8cbbab86cd772f29
ENTRY_AHEAD              = 0
ENTRY_BEHIND             = 0
```

```text
ENTRY_REMOTE_LOCK = VERIFIED
LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE
AHEAD = 0
BEHIND = 0
```

```text
ORIGIN_CONTACTED = NO
```

---

## F. Authority Chain

The current canonical entry commit is the committed Owner decision:

```text
AUTHORIZATION_COMMIT  = 1c952d6a81f87587851194ca8cbbab86cd772f29
AUTHORIZATION_SUBJECT = docs: decide post-archive windows successor
ARTIFACT              = PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_POST_EXECUTION_OWNER_DECISION.md
ARTIFACT_TRACKED      = YES (git ls-files --error-unmatch confirmed)
```

Live review of the committed artifact confirmed the binding Owner decisions:

```text
OWNER_DECISION            = D2
OWNER_CHOICE              = WINDOWS PRIVATE CUSTOMER HANDOFF PLANNING
AUTHORIZED_SUCCESSOR_COUNT = 1
AUTHORIZED_SUCCESSOR      = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING
SUCCESSOR_SESSION_CLASS   = PLANNING_ONLY
SUCCESSOR_STARTED         = NO
```

Predecessor result token (recorded in the committed artifact):

```text
PREDECESSOR_RESULT =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_POST_EXECUTION_OWNER_DECISION_REMOTE_LOCKED
```

```text
AUTHORIZED_SUCCESSOR_COUNT = 1
MULTIPLE_SUCCESSORS        = NO
THIS_SESSION_MATCHES       = TRUE
AUTHORITY_VERIFIED         = YES
```

The immediately preceding boundary (from the committed predecessor artifact's
own authority chain, verified live):

```text
PREDECESSOR_BOUNDARY =
  PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_AND_CHECKSUM_RECORD_EXECUTION
  RESULT =
  PASS_PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_AND_CHECKSUM_RECORD_EXECUTION_REMOTE_LOCKED
  NEXT_AUTHORIZED_SUCCESSOR = NONE
  OWNER_DECISION_REQUIRED_FOR_ANY_FURTHER_WORK = YES
```

Interpretation: this session is authorized to PLAN the private customer handoff
model ONLY. It inherits NO execution authority of any kind. The explicit Owner
decision D2 is the sole authority for this session.

```text
PLANNING_AUTHORITY_IS_NOT_EXECUTION_AUTHORITY = YES
```

---

## G. Canonical Release Identity

Canonical accepted Windows release candidate (verified read-only from the
durable private archive this session — live `Get-FileHash`, no modification):

```text
ARCHIVE_DIRECTORY = C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845
DIRECTORY_IDENTITY = v1.0.0-b1-RC-20260910-222845
                     (product version 1.0.0 + build 1 + RC-20260910-222845)

FILE_NAME = muaman-windows-release.zip
SIZE      = 16279806
SHA256    = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
ATTR      = ReadOnly, Archive (immutable in practice)

FILE_NAME = release-integrity.json
SIZE      = 1466
SHA256    = 17553DE812E3DAAF1634C0F4E3A43E42E3D93325576AF5C98FB889507F221B23
ATTR      = ReadOnly, Archive (immutable in practice)
```

Contained release-set identities (from the committed canonical execution record
`PHASE_P_POST_WINDOWS_DELIVERY_DURABLE_ARCHIVE_AND_CHECKSUM_RECORD_EXECUTION`
and re-confirmed in the archived `release-integrity.json`, read-only; NOT
recomputed by rebuilding or repackaging):

```text
ACCEPTED_RC        = RC-20260910-222845
EXE_NAME           = muaman_store.exe
EXE_SIZE           = 92672
EXE_SHA256         = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7

RC_FILE_COUNT      = 18
RC_TOTAL_BYTES     = 37537520
RC_CROSSHASH       = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9

PRODUCT_NAME       = I Tech Store Management / I Tech لإدارة المحلات
PRODUCT_VERSION    = 1.0.0
PRODUCT_BUILD      = 1
IMMUTABLE_RELEASE_IDENTITY = v1.0.0 + build 1 + RC-20260910-222845
```

```text
CANONICAL_ARTIFACT_IDENTITY = VERIFIED (bytes are ground truth, SHA-256-matching)
NO_VALUE_REBUILT_OR_RECREATED = TRUE
```

Historical non-canonical reference (NOT a valid handoff source; volatile):

```text
TEMP_PACKAGER_PATH_REFERENCE =
  C:\Users\saber\AppData\Local\Temp\opencode\windows-delivery-execution\out\muaman-windows-release.zip
  (temporary cache used by the original packaging/archive execution;
   MAY no longer exist and MUST NOT be treated as durable; the durable
   archive in section G/H is the ONLY canonical handoff source)
```

---

## H. Immutable Archive Boundary

The durable private archive is retention evidence, NOT a delivery workspace:

```text
DURABLE_ARCHIVE = C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845

ARCHIVE_IS_IMMUTABLE   = YES (ReadOnly attribute; write-once operational policy)
ARCHIVE_IS_PUBLICATION = NO
ARCHIVE_IS_DELIVERY_WORKSPACE = NO
```

Absolute rules for the archive (bind this session AND every future session until
a separate Owner contract changes the archive policy):

```text
OVERWRITE      = NO
RENAME         = NO
RELOCATE       = NO
EXTRACT-AND-MODIFY = NO
REPACKAGE      = NO
RECOMPRESS     = NO
REGENERATE     = NO
TOGGLE_READONLY = NO
ALTER_ACLS     = NO
ALTER_TIMESTAMPS_DELIBERATELY = NO
DELETE         = NO
MODIFY         = NO
COPY_OUT_FROM = ALLOWED ONLY BY AN EXPLICITLY AUTHORIZED FUTURE EXECUTION SESSION
                (byte-for-byte, immediately re-verified against the record)
```

```text
DURABLE_ARCHIVE_MODIFIED = NO
ARCHIVE_REMAINS_SOLE_CANONICAL_SOURCE = YES
```

---

## I. Sacred Legacy ZIP Boundary

Historical artifact, verified read-only this session:

```text
delivery/I-TECH-Delivery-v1.0.0.zip
SIZE   = 12668632
SHA256 = 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
```

Absolute rules (bind this session AND every future session):

```text
MODIFY = NO | DELETE = NO | REPLACE = NO | MOVE = NO
COPY_AS_CANONICAL = NO | ARCHIVE_AS_CURRENT_RELEASE = NO | RENAME = NO
REPACKAGE = NO | STAGE = NO | COMMIT = NO | UPLOAD = NO | DISTRIBUTE = NO
USE_AS_CUSTOMER_DELIVERY_ARTIFACT = NO
INCLUDE_IN_PLANNING_COMMIT = NO
```

```text
SACRED_LEGACY_ZIP_MODIFIED = NO
SACRED_LEGACY_ZIP_IS_NOT_THE_HANDOFF_ARTIFACT = YES
```

Wrong-artifact separation rule (see also section T):

- The two ZIP files are distinguished by PATH, NAME, SIZE, and SHA-256 together.
  Filename alone is NEVER sufficient.

---

## J. Private Customer Handoff Objective

Primary question answered by this plan:

> How can I Tech later deliver the accepted Windows RC privately to a
> controlled customer/recipient while preserving artifact identity, retention
> evidence, auditability, security, and explicit Owner authority?

Future objective (NOT executed this session):

```text
HANDOFF_CLASS = PRIVATE_CONTROLLED_CUSTOMER_HANDOFF

IT IS NOT:
  - public publication
  - open download
  - GitHub public release
  - marketplace distribution
  - mass distribution
  - Android release
  - Production deployment
```

Objectives a future authorized execution must satisfy:

```text
H1 RECIPIENT_CONTROL   - only a controlled, Owner-authorized recipient class
                         may receive the artifact;
H2 ARTIFACT_IDENTITY   - the exact accepted bytes (size + SHA-256) are preserved
                         and verified end-to-end;
H3 RETENTION_SEPARATION - the immutable archive is never the delivery workspace;
                         any delivery copy is a separately verified byte-for-byte
                         copy made ONLY under explicit authorization;
H4 AUDITABILITY        - every handoff produces a complete evidence record;
H5 SECURITY            - no secrets, private keys, credentials, or unintended
                         customer/shop data travel on the delivery path;
H6 OWNER_AUTHORITY     - actual transfer requires a fresh explicit Owner
                         execution authorization, never inferred from this plan;
H7 REVOCABILITY        - every channel choice keeps a stop/revoke path and
                         preserves the immutable archive for rollback evidence.
```

None of H1–H7 is achieved by this planning session.

---

## K. Recipient Model

The plan defines recipient eligibility GENERICALLY. No real customer
identity/name/email/phone number/account is invented here or anywhere.

```text
RECIPIENT_CLASS (must be supplied by the Owner in the future execution session):
  R1 Owner-controlled test customer
  R2 named authorized customer
  R3 authorized shop operator
  R4 controlled evaluator
  (closed class; NO unnamed mass/public recipients)

RECIPIENT_AUTHORIZATION = REQUIRED BEFORE ANY TRANSFER:
  - explicit Owner statement naming the recipient class and, where the Owner
    supplies it, the exact recipient identity;
  - the executed recipient data is recorded ONLY in the future execution
    session's evidence record, NEVER in this planning artifact.

RECIPIENT_DATA_IN_PLAN = NONE
```

Rules:

```text
- Recipient identity MUST be Owner-supplied or Owner-authorized at execution
  time; a plan can never invent it.
- Per-handoff recipient scope is single-recipient oriented; bulk/mass handling
  is NOT in scope of this plan without a further Owner decision.
- The recipient receives the exact byte-identical artifact and the integrity
  information from sections O/Q. NO custom-build, NO data-injection, NO rebrand
  is in scope.
```

---

## L. Delivery Channel Analysis

Channel classes analyzed (NO channel is exercised here; every option that
requires Owner judgment is marked `OWNER_DECISION_REQUIRED = YES`).

### Channel A — Direct local / offline handoff (class example: USB / removable media / direct device transfer)

```text
recipient control        = highest (physical, person-to-person)
unauthenticated exposure = none while carried/transferred by hand
wrong-recipient risk     = low (physical handover)
hash verification        = required before AND after copy (sections O/U)
removable-media risk     = media may be infected, lost, or contain other files;
                           treat media as untrusted and re-verify bytes on the
                           recipient machine
malware-scan boundary    = scan the copy on the OPERATOR machine and instruct
                           recipient to scan/monitor; do NOT disable Windows
                           protections (section P)
deletion/retention       = after successful handoff + verification, remove the
                           staging copy unless Owner chooses retention;
                           archive copy is NEVER removed
version/update path      = manual (operator re-delivers future versions)
opacity/auditability    = requires the evidence record (section X)
RECOMMENDATION           = preferred for in-person or courier-controlled delivery
                           to a small, controlled recipient set
OWNER_DECISION_REQUIRED  = YES (final channel approval per handoff)
```

### Channel B — Private authenticated cloud object / file link (class only; nothing uploaded)

```text
recipient control        = configurable (invited/authenticated access, sign-in gate)
unauth exposure risk     = accidental public sharing if link settings are wrong
access restriction       = must be per-recipient share, not "anyone with the link"
expiration               = REQUIRED where the provider supports it; short-lived
download auditing        = REQUIRED (who/when/what downloaded)
revocation               = share/link must be revocable and revoke-rechecked before
                           the recipient is told it is final
hash verification        = still required on both sides; a link is NOT identity
wrong-recipient risk     = low-moderate (addressable by invitation-only sharing)
attachment limits        = not applicable (link-based), but object size and
                           provider rules must be checked
provider trust           = the provider and its data location must be acceptable
                           to the Owner; proprietary artifact MUST NOT be sent to
                           an unapproved service
RECOMMENDATION           = acceptable ONLY as an explicit Owner-approved,
                           access-controlled, expiring, revocable per-recipient
                           share for remote recipients; NOT as an open link
OWNER_DECISION_REQUIRED  = YES (provider + access model + retention/expiry)
```

### Channel C — Direct authenticated electronic transfer (class example: private direct message / email / file-transfer mechanism)

```text
recipient control        = moderate (direct to addressed recipient)
wrong-recipient risk     = MODERATE-HIGH (misaddressing / auto-complete error);
                           double-check exact recipient before send
attachment limits        = may block/exceed limits for a 16 MB ZIP on some
                           services; confirm capability BEFORE promising delivery
integrity verification   = checksum still required on both sides
message retention        = copies may persist in mail/log servers; disclose
                           that this is a controlled private delivery, not secret
unauthorized forwarding  = recipient controls the message afterwards; a direct
                           message is not a durable delivery channel
RECOMMENDATION           = LAST choice among the three; only for small, identical
                           recipient sets where A/B are impractical, with exact
                           recipient confirmation and full hash pre/post checks
OWNER_DECISION_REQUIRED  = YES (mechanism + recipient confirmation policy)
```

### Channel D — Other controlled mechanism

```text
Available only if repository/environment evidence from the FUTURE session
supports a safe mechanism (e.g., a private, authenticated operator-run transfer
service). No such mechanism is evidenced today; Channel D is NOT recommended
without live evidence and Owner approval.
RECOMMENDATION           = NOT RECOMMENDED unless later evidence + Owner approval
OWNER_DECISION_REQUIRED  = YES
```

### Channel conclusion (planning recommendation ONLY)

```text
RECOMMENDED_CHANNEL_ORDER (safety-first):
  1. Channel A — direct local/offline handoff (primary for controlled,
     person-mediated delivery; least exposure, strongest control);
  2. Channel B — private authenticated cloud link (secondary for remote
     recipients, ONLY as an access-controlled, expiring, revocable,
     per-recipient share);
  3. Channel C — direct authenticated electronic transfer (tertiary/last resort,
     small recipient set, exact recipient confirmation);
  4. Channel D — ONLY with live evidence + Owner approval.

PRIMARY_RECOMMENDATION = Channel A for the default case, Channel B only as an
                         explicitly approved remote alternative.
```

```text
RECOMMENDATION_IS_NOT_AUTHORIZATION = YES
PUBLICATION/OPEN_LINK/GH-PUBLIC/MASS_CHANNELS = PROHIBITED (never recommended)
```

---

## M. Recommended Controlled Handoff Model

Two-layer model (planning recommendation; no authority):

```text
LAYER 1 — CANONICAL SOURCE
  The immutable private archive (section H):
  C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845\muaman-windows-release.zip
  (SIZE 16279806, SHA-256 879761AF...FF5C5, ReadOnly).
  This is ALWAYS the byte-source of truth. Never the sacred ZIP, never a temp
  cache, never a rebuilt file.

LAYER 2 — CONTROLLED DELIVERY COPY
  A future execution session, ONLY under explicit Owner authorization, creates a
  byte-for-byte delivery/staging copy (section N), verifies it, delivers it via
  the Owner-approved channel (section L), verifies it again, records evidence
  (section X), and cleans it up (section N).
```

Handoff model invariants:

```text
SOURCE_SOURCE_ALWAYS_THE_ARCHIVE = YES
DELIVERY_COPY_MUST_MATCH_ARCHIVE_BYTES = YES (size + SHA-256, both sides)
NO_CUSTOM_BUILD_OR_DATA_INJECTION = YES
NO_REBRAND_OR_PACKAGE_RENAME = YES (filename identity preserved on the copy unless
                              a separate future Owner decision authorizes a rename,
                              which would then require its own identity record)
OWNER_EXECUTION_AUTHORIZATION_REQUIRED = YES
```

---

## N. Retention Copy vs Delivery Copy

### A. Durable Retention Artifact

```text
LOCATION = C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845
PURPOSE  = canonical retention; integrity evidence; recovery/rollback evidence
STATUS   = immutable/read-only; MUST stay untouched (section H)
```

### B. Future Delivery / Staging Copy

```text
CREATION_ALLOWED = ONLY by an explicitly authorized future execution session.
COPY_METHOD      = byte-for-byte file copy (e.g., System.IO.File.Copy with
                   overwrite:FALSE, or an equivalent no-clobber copy); NO
                   compression, NO repackaging, NO rebuild.
```

Deterministic staging location rules (to be executed only by the future
authorized session; the planning session creates NOTHING):

```text
ALLOWED_STAGING_ROOT (class) =
  C:\Users\<operator>\I-Tech\HandoffStaging\<handoff-id>\
  where <handoff-id> = handoff-<YYYY-MM-DD>-<seq> (e.g., handoff-2026-09-15-01),
  a fresh deterministic directory chosen ONLY after proving it does not exist.

LOCATION_REQUIREMENTS (each must hold, else STOP):
  - outside the Git repository (never inside this worktree, incl. delivery/);
  - outside the immutable archive directory itself;
  - outside temp/cache (C:\Users\saber\AppData\Local\Temp\...) UNLESS an
    explicit transient transfer-buffer step is separately authorized and the
    buffer is wiped after transfer;
  - outside OneDrive/cloud-synced folders;
  - outside Downloads;
  - on a local fixed disk with enough free space (verify free space before copy);
  - operator-controlled (write-probe permitted before use);
  - NOT a UNC/reparse/linked path.

FORBIDDEN_DESTINATIONS =
  - inside the repository (any path under C:/dev/muaman.worktrees/...);
  - the immutable archive directory;
  - OneDrive / any synced or network-mapped folder;
  - Downloads / public web roots / publicly linkable storage;
  - removable media as the ONLY copy;
  - any path colliding with an existing file (fail closed, section U).
```

Overwrite / collision rules (see section U for full policy):

```text
NO_SILENT_OVERWRITE = YES
DESTINATION_COLLISION => STOP and choose a fresh deterministic destination,
                         OR report for Owner direction; NEVER reuse an
                         existing same-named file without full identity check.
```

Required hash verification sequence for the future execution:

```text
1. HASH SOURCE ARTIFACT  - hash the archived ZIP (must equal the canonical
                           SHA-256 879761AF...FF5C5 AND size 16279806);
2. COPY                 - byte-for-byte copy to the fresh staging path
                           (overwrite:FALSE; pre-check destination absent);
3. HASH DELIVERY COPY   - hash the staging copy (must equal source);
4. COMPARE              - exact full SHA-256 + size equality (not a prefix);
5. TRANSFER             - deliver via the Owner-approved channel;
6. RECIPIENT-SIDE CHECK - if technically possible, verify the recipient-side
                           received file size + SHA-256 and record the result;
7. RECORD EVIDENCE      - commit the evidence record per section X,
                           then clean up per policy below.
```

Cleanup / retention policy after successful handoff:

```text
CLEANUP_DEFAULT = after recipient-side verification (or evidence of verified
                  receipt) and evidence recording, DELETE the staging copy
                  (and any transient transfer buffer), UNLESS the Owner
                  explicitly directs retention of the staging copy for evidence.
ARCHIVE_RETENTION = the immutable archive copy is NEVER deleted.
COLLISION_RESIDUE = if the delivered artifact is later superseded, a NEW identity
                    record marks the old one superseded; no deletion of archive
                    or evidence.
```

```text
STAGING_COPY_CREATED = NO (this session)
STAGING_COPY_DELETED = NO (this session)
```

---

## O. Artifact Integrity Protocol

Deterministic Windows-friendly verification procedure for a future authorized
execution session. Prefer built-in mechanisms.

Hash command (PowerShell 5.1+):

```text
Get-FileHash -LiteralPath <file> -Algorithm SHA256
```

Full required procedure (7 steps, from section N):

```text
STEP 1 SOURCE HASH
   Get-FileHash -LiteralPath "C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845\muaman-windows-release.zip" -Algorithm SHA256
   REQUIRED = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
   ALSO verify size = 16279806 bytes ((Get-Item ...).Length).
   MISMATCH => STOP. Report. Regenerate NOTHING.

STEP 2 COPY
   byte-for-byte copy to the fresh staging path (overwrite:FALSE).
   Destination pre-existence check MUST show ABSENT.

STEP 3 DELIVERY-COPY HASH
   Get-FileHash on the staging copy; REQUIRED == STEP 1 value AND size equal.

STEP 4 COMPARE
   Full (not prefix) SHA-256 string equality + byte-size equality,
   for the ZIP; if the EXE is transferred separately, also verify
   EXE name muaman_store.exe, size 92672,
   EXE SHA-256 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7.

STEP 5 TRANSFER
   deliver via the Owner-approved channel (section L).

STEP 6 RECIPIENT-SIDE VERIFICATION (if technically available)
   recipient runs the same Get-FileHash and reports the value; compare exact.

STEP 7 EVIDENCE
   record per section X; cleanup per section N.
```

Rules:

```text
NEVER_RELY_ON_FILENAME_ALONE = YES
FULL_SHA256_COMPARISON       = YES (no prefix/partial match acceptance)
SIZE_AND_HASH_TOGETHER       = YES (both must match)
MISMATCH_IS_STOP             = YES (never treat a mismatched file as canonical;
                                never quietly "fix" the copy; never regenerate)
```

---

## P. Unsigned Release Policy

Canonical predecessor governance permits:

```text
ALLOW_UNSIGNED_PRIVATE_ONLY = YES
WINDOWS_APP_SIGNING_STATUS   = UNSIGNED (verified from committed evidence;
                               release-integrity.json unsigned_status = UNSIGNED)
ALLOW_UNSIGNED_PUBLIC_DISTRIBUTION = NO
```

Private-only boundary:

```text
The artifact may be handed off ONLY on a PRIVATE CONTROLLED basis. No public
distribution of the unsigned artifact.
```

Recipient/operator disclosure requirements (applicable to every future handoff
while unsigned):

```text
REQUIRED_DISCLOSURES_TO_RECIPIENT:
  - the Windows build is UNSIGNED (no cryptographic publisher identity);
  - Windows SmartScreen / "Windows protected your PC" / unknown-publisher
    warnings are EXPECTED and are NOT proof of malware;
  - the correct SHA-256 (and size) MUST be verified BEFORE executing;
  - on any mismatch the recipient MUST stop, not run the file, and report to the
    operator;
  - the recipient MUST NOT be told to disable SmartScreen, Defender, UAC, or any
    endpoint protection;
  - the artifact is a private controlled delivery, not a public release.
```

Prohibitions (bind this session AND every future execution unless a separate
Owner contract expressly authorizes a change):

```text
NO_DISABLING_WINDOWS_SECURITY = YES
NO_BYPASS_INSTRUCTIONS        = YES
NO_PRESENTATION_AS_SIGNED     = YES (never claim cryptographic publisher
                                    signature when UNSIGNED)
NO_MUTATION_OF_EXECUTABLE     = YES (signing or any byte change would create a
                                    NEW artifact with a NEW identity)
```

Future code-signing (separate workstream, NOT authorized anywhere in this plan):

```text
CODE_SIGNING = a separately authorized future workstream (acquisition, secure
               key custody, timestamping, pipeline integration under a NEW
               release identity if bytes change). This plan neither opens nor
               closes that workstream.
```

```text
CODE_SIGNING_EXECUTED   = NO
CERTIFICATE_ACQUIRED    = NO
SIGNING_KEYS_CREATED    = NO
EXECUTABLE_BYTES_MODIFIED = NO
```

---

## Q. Customer-Facing Integrity Information

Required integrity information the future recipient should receive with every
handoff:

```text
Product                         = I Tech Store Management / I Tech لإدارة المحلات
Version/build identifier        = v1.0.0 (build 1) / RC-20260910-222845
ZIP file name                  = muaman-windows-release.zip
ZIP size                        = 16279806 bytes
ZIP SHA-256                     = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
Private/controlled release status = YES — PRIVATE CONTROLLED CUSTOMER HANDOFF ONLY
Unsigned status                 = UNSIGNED Windows application
Hash verification instruction   = PowerShell:
                                  Get-FileHash -LiteralPath <file> -Algorithm SHA256
                                  (see section O; on mismatch: stop, do not run,
                                  report to I Tech)
Support/contact identity        = I Tech (existing undefined/generic support
                                  identity to be finalized ONLY by Owner; NO
                                  contact details are invented here)
```

The plan permits a future execution session to produce a small TEXT integrity
manifest for the recipient (customer-distribution material). Example TEMPLATE
(placeholders `[...]` must be filled only by the Owner-authorized future
session; nothing personal is embedded in the template):

```text
======= I Tech Store Management — Private Delivery =======
Product        : I Tech Store Management / I Tech لإدارة المحلات
Version        : v1.0.0 (build 1), RC-20260910-222845
File           : muaman-windows-release.zip
Size (bytes)   : 16279806
SHA-256        : 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
Status         : PRIVATE CONTROLLED DELIVERY (not public)
Signed         : NO (UNSIGNED Windows application)
Verify (PowerShell):
  Get-FileHash -LiteralPath "<saved file path>" -Algorithm SHA256
Expected value must equal the SHA-256 above.
Security note : Do NOT disable SmartScreen/Defender. If the hash differs, do
                not run the file and contact I Tech.
Recipient      : [Owner-authorized recipient identifier — execution session
                  fills; never a plan]
Delivered via  : [approved channel — execution session fills]
Delivered on   : [UTC timestamp — execution session fills]
Operator       : [executing operator — execution session fills]
======= End of integrity info =======
```

Rules:

```text
MANIFEST_IS_PROHIBITED_UNTIL_EXECUTION = YES (planning only)
MANIFEST_MUST_CONTAIN_NO_PERSONAL_RECIPIENT_DATA = YES
MANIFEST_MUST_NOT_CLAIM_SIGNING = YES
```

```text
CUSTOMER_DISTRIBUTION_MATERIAL_CREATED = NO (this session)
```

---

## R. Privacy / Secrets / Customer Data Boundary

### Secrets — prohibited content on any delivery path

The plan prohibits inclusion of (bind the future execution session):

```text
Supabase secrets / service-role keys / anon keys      = PROHIBITED
Passwords / credential material                      = PROHIBITED
GitHub credentials / tokens                          = PROHIBITED
Keystore secrets / private keys / PFX/P12 material   = PROHIBITED
API tokens / local .env secrets / DPAPI material     = PROHIBITED
Internal database credentials                        = PROHIBITED
Unintended customer/shop data                        = PROHIBITED
```

Rules:

```text
- The Windows ZIP is treated as IMMUTABLE; nothing is unpacked or modified to
  remediate anything.
- A future execution session MUST NOT transmit, log, or embed any of the above.
- If canonical evidence indicates a secret-contamination risk at execution time:
  STOP and report it. Do NOT distribute.
- This planning artifact contains NO secrets (verified by construction; the
  repository's pre-existing `supabase/.temp/start-secrets/.../docker.env` was
  NOT read, NOT staged, NOT committed, NOT modified).
```

### Customer data boundary

```text
DEFAULT_DESIRED_BOUNDARY =
  CUSTOMER_DATA_IN_RELEASE_ARTIFACT = NONE
```

Verification status:

```text
CUSTOMER_DATA_BOUNDARY_VERIFIED = NOT VERIFIED
  (canonical evidence proves the ZIP's structural identity — 18-file release
   set, EXE identity, crosshash — and the archive record states
   distribution_policy=PRIVATE_ARCHIVE_ONLY, but no committed evidence proves
   the release artifact contains NO bundled live shop/customer business data.)
```

Future pre-handoff verification gate (required before any execution handoff;
READ-ONLY):

```text
GATE_READONLY_RELEASE_AUDIT =
  1. read-only inventory/audit of the ZIP's contents (no extraction to a run
     location, no modification);
  2. confirm the ZIP contains only the expected release set and no exported/
     embedded shop/customer database or personal data;
  3. if any customer/shop data file is found: STOP, do NOT hand off, report to
     the Owner and determine a separately authorized remediation (which may never
     be silent repacking of the accepted RC);
  4. add the audit result to the pre-handoff evidence record.
```

```text
NO_PACKAGE_MODIFICATION_TO_REMEDIATE = YES
CUSTOMER_DATA_HANDOFF_PREVENTED_UNTIL_GATE_PASS = YES
```

---

## S. Optional Security Scan Boundary

A read-only pre-handoff security scan MAY be part of a future execution session
(Owner-tool-neutral):

```text
SCAN_ALLOWED = OPTIONAL, READ-ONLY, pre-handoff, per Owner direction

TOOL_NEUTRAL_REQUIREMENTS:
  - scan only a verified byte-identical copy (or read-only scan of the archive);
  - explore/scan the file WITHOUT executing or modifying it;
  - record the scanner identity/version and result separately from the
    cryptographic identity;
  - NO scan result changes or replaces the SHA-256 evidence;
  - local/offline scanning preferred; see upload rule below.

UPLOAD_RULE:
  - do NOT upload proprietary artifacts to third-party scanning services without
    explicit Owner approval;
  - NO security scan requiring artifact upload is authorized by this plan.

BOUNDARIES:
  - the scan MUST NOT modify executable bytes;
  - a scan PASS is NOT an authenticity claim and NOT a signature;
  - a scan FAIL is a STOP-and-report, never a silent remediation.
```

```text
SECURITY_SCAN_EXECUTED = NO (this session)
SECURITY_SCAN_AUTHORIZED = NO (requires Owner direction at execution time)
```

---

## T. Wrong-Artifact Prevention

The plan explicitly prevents confusion between:

```text
A. CURRENT ACCEPTED RC (HANDOFF ARTIFACT)
   name  = muaman-windows-release.zip
   size  = 16279806
   SHA256 = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
   path  = C:\Users\saber\I-Tech\ReleaseArchive\v1.0.0-b1-RC-20260910-222845\muaman-windows-release.zip

B. SACRED HISTORICAL ZIP (NEVER A HANDOFF ARTIFACT)
   name  = I-TECH-Delivery-v1.0.0.zip
   size  = 12668632
   SHA256 = 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
   path  = delivery/I-TECH-Delivery-v1.0.0.zip
```

Mandatory identity rule:

```text
BEFORE ANY FUTURE HANDOFF, require FULL SIZE + FULL SHA-256 identity:
  size 16279806 AND SHA256 879761AF...FF5C5 for the delivery copy.
FILENAME ALONE IS NEVER SUFFICIENT. Any file that fails either value is
NOT the canonical artifact and MUST NOT be handed off.
```

Verification command set (future execution):

```text
$f = <delivery copy path>
(Get-Item -LiteralPath $f).Length             # MUST equal 16279806
(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToUpperInvariant()
                                              # MUST equal 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
Record both before deciding to transfer.
```

```text
CANONICAL_VS_SACRED_DISTINCTION_REQUIRED = YES
WRONG_ARTIFACT_CHECK_PLACED_AT_EVERY_STEP = YES (step 1, step 3, step 4,
                                                step 6 in section O)
```

---

## U. Collision / Non-Overwrite Policy

Future execution MUST be fail-closed:

```text
RULE 1  NO silent overwrite. A copy that would overwrite is FORBIDDEN.
RULE 2  destination collision => STOP; either choose a fresh deterministic
        destination (new <handoff-id>) or report to the Owner; NEVER write into
        an occupied path.
RULE 3  an existing same-named file at the chosen destination MUST be hashed
        and its size+hash compared BEFORE any decision; only an exact match to
        the canonical identity may (optionally, per Owner) be treated as an
        already-verified copy; EVERYTHING else is a mismatch.
RULE 4  mismatched hash => NEVER treat it as canonical; STOP; do not delete the
        existing file (it may be pre-existing residue); choose a fresh name or
        report.
RULE 5  no destructive replacement of any existing file.
RULE 6  no archive overwrite (the immutable archive is never a write target).
RULE 7  no sacred-ZIP overwrite (untouchable).
RULE 8  staging copy identity must equal the archive identity byte-for-byte
        before it may be named for delivery.
```

```text
FAIL_CLOSED_ON_COLLISION = YES
SILENT_FIX_FORBIDDEN    = YES
```

---

## V. Execution Preconditions

Evidence required BEFORE any actual customer handoff (a future execution session
must verify ALL):

```text
V1 OWNER_EXECUTION_AUTHORIZATION   - a fresh, explicit Owner decision
                                     authorizing THIS execution (commit/artifact);
V2 RECIPIENT_AUTHORIZATION         - recipient class/identity supplied or
                                     authorized by the Owner;
V3 CHANNEL_AUTHORIZED              - the exact channel (section L) approved;
V4 ARTIFACT_IDENTITY               - source archive present with size 16279806 +
                                     SHA256 879761AF...FF5C5 (canonical);
V5 DELIVERY_COPY_IDENTITY          - staging copy size+hash equal after copy;
V6 CUSTOMER_DATA_GATE              - read-only release audit (section R) PASS;
V7 SECURITY_SCAN                   - optional scan disposition per Owner
                                     (section S);
V8 PRIVATE_SCOPE_CONFIRMED         - handoff class = PRIVATE_CONTROLLED
                                     CUSTOMER_HANDOFF only;
V9 EVIDENCE_TEMPLATE_READY         - section X record schema prepared;
V10 REMOTE/GOV STATUS              - repository remote-lock + authority chain
                                     re-verified at execution entry.
```

```text
ALL_PRECONDITIONS_SATISFIED = NO (not claimed; they are future gates)
THIS_PLAN_GRANTS_NONE_OF_V1-V10 = YES
```

---

## W. Failure / Abort / Revocation Model

Enumerated STOP conditions for future execution (fail closed; no silent
regeneration):

```text
F1 wrong HEAD / missing authority
F2 remote-lock failure (local/tracking/github divergence)
F3 canonical archived ZIP absent
F4 hash mismatch (source or delivery copy)
F5 size mismatch
F6 archive mutation detected
F7 recipient identity unavailable (not Owner-supplied/authorized)
F8 unapproved channel requested
F9 unexpected secret/data exposure on the path
F10 copy / destination collision without an Owner-approved fresh target
F11 transfer partial/failed (no silent retry loop without evidence)
F12 recipient destination ambiguous (cannot verify where it landed)
F13 artifact altered after verification
F14 unexpected repository mutation
F15 any request to publish publicly / create public link / mass-distribute
F16 any request to execute Android / Production / Supabase / P-OD7 / Sync Drain /
     licensing-production work as part of the handoff
```

No failure may trigger silent artifact regeneration (rebuild/repack/re-sign).

Rollback / abort model for future execution (priority order):

```text
P1 REVOKE / STOP EXPOSURE     - revoke the cloud link / terminate the transfer /
                                 halt further copies; for Channel B re-check that
                                 the share is revoked and no longer accessible.
P2 PRESERVE EVIDENCE          - keep the source archive, integrity record, and any
                                 evidence produced so far (never delete evidence).
P3 PRESERVE IMMUTABLE ARCHIVE - the archive stays untouched (rollback eligibility
                                 is preserved).
P4 NOTIFY OWNER               - report exact failure, evidence, and what the Owner
                                 must decide next.
P5 REQUIRE NEW AUTHORIZATION  - if scope changes (new recipient, new channel,
                                 remediation, regeneration), require a fresh Owner
                                 decision before continuing.
```

Abort points:

```text
PRE_TRANSFER_ABORT        - nothing exposed; delete/retain staging per Owner;
                            archive untouched.
TRANSFER_FAILURE          - partial recipient receipt => STOP, do NOT resend
                            without re-verifying; record.
POST_TRANSFER_HASH_MISMATCH - recipient reports a different hash => STOP usage
                            advisory, re-verify source, record; do NOT silently
                            resend a "corrected" file that differs from the
                            accepted RC.
WRONG_ARTIFACT_RECEIVED   - if the recipient received the sacred ZIP or any
                            non-canonical file: record, notify Owner, re-deliver
                            ONLY the canonical artifact under a fresh check;
                            never "repair".
LINK_ACCIDENTALLY_PUBLIC  - revoke immediately, confirm revocation, notify Owner.
STAGING_COPY_CLEANUP      - after verified handoff, cleanup per section N; if
                            cleanup cannot be verified, record and report.
CLOUD_LINK_REVOCATION      - if applicable, revoke + re-check; keep provider
                            audit evidence.
```

```text
ROLLBACK_EXECUTED   = NO (nothing to roll back; nothing transferred)
REVOCATION_EXECUTED = NO
```

---

## X. Future Evidence Record Schema

Template (schema) ONLY — this plan does NOT create a fake completed record.
A future authorized execution session fills one record per handoff.

```text
HANDOFF_EVIDENCE_FIELDS:
  handoff_id                         = handoff-<YYYY-MM-DD>-<seq>
  handoff_timestamp_utc              = exact UTC timestamp
  owner_authorization_reference      = commit/artifact id of the fresh Owner
                                       execution authorization
  recipient_class                    = from section K (R1..R4)
  recipient_identifier               = Owner-supplied (no invention)
  delivery_channel                   = Channel A/B/C/D exactly as approved
  channel_revocation_reference        = revocation evidence reference if channel B/C
  source_artifact_identity           = name muaman-windows-release.zip,
                                       size 16279806,
                                       sha256 879761AF...FF5C5,
                                       path = archive directory
  staging_delivery_copy_path          = exact staging path used
  execution_artifacts                = exact commands run (Get-FileHash / copy)
  pre_transfer_sha256                = full hash read immediately before transfer
  post_copy_sha256                   = full hash read after copy
  transfer_result                    = OK / PARTIAL / FAILED
  recipient_side_verification_status = VERIFIED / NOT_VERIFIED / MISMATCH
                                       (only if technically available)
  unsigned_release_acknowledgment    = YES/NO (recipient informed of UNSIGNED
                                       status per section P)
  archive_untouched_status           = YES (verified before and after)
  sacred_legacy_zip_untouched_status = YES (verified before and after)
  customer_data_gate_result          = PASS / NOT_VERIFIED / FAILED (section R)
  security_scan_disposition          = NOT_RUN / PASS / FAIL (section S; status
                                       recorded separately from crypto identity)
  operator                            = executing human/agent identity
  cleanup_performed                   = staging copy deleted / retained (per Owner)
  publishing_evidence                = NONE (publication is prohibited)
```

```text
FAKE_HANDOFF_RECORD_CREATED = NO (this session only defines the schema)
HANDOFF_EXECUTED            = NO
```

---

## Y. Future Execution Success Criteria

Explicit PASS criteria for a future authorized execution session:

```text
OWNER_EXECUTION_AUTHORIZATION = VERIFIED     (fresh Owner execution decision)
RECIPIENT_AUTHORIZATION       = VERIFIED     (Owner-supplied class/identity)
CHANNEL_AUTHORIZED            = VERIFIED     (exact channel from section L)
SOURCE_ARTIFACT_IDENTITY      = VERIFIED     (size 16279806 + SHA-256 exact)
DELIVERY_COPY_IDENTITY        = VERIFIED     (post-copy size + SHA-256 exact)
TRANSFER_COMPLETE             = YES
HASH_MATCH                    = YES          (recipient-side if available)
ARCHIVE_UNTOUCHED             = YES
SACRED_LEGACY_ZIP_UNTOUCHED   = YES
PUBLICATION                   = NO
UNAUTHORIZED_DISTRIBUTION     = NO
EVIDENCE_RECORD_COMPLETE      = YES          (per section X, recorded)
CUSTOMER_DATA_GATE            = PASS         (section R)
```

```text
PLANNING_THESE_CRITERIA_DOES_NOT_SATISFY_THEM = YES
```

---

## Z. Explicit Non-Authorizations

This planning session and its planning artifact DO NOT authorize any future
action that is not separately Owner-approved. In particular the following remain
NOT AUTHORIZED:

```text
PUBLICATION                       = NOT AUTHORIZED
DISTRIBUTION                      = NOT AUTHORIZED
CUSTOMER_HANDOFF_EXECUTION        = NOT AUTHORIZED
RECIPIENT_CONTACTED               = NOT AUTHORIZED
FILE_TRANSFER                     = NOT AUTHORIZED
UPLOAD                            = NOT AUTHORIZED
CLOUD_SHARE_LINK                  = NOT AUTHORIZED
EMAIL / MESSAGE / ATTACHMENT SEND = NOT AUTHORIZED
GITHUB_RELEASE                    = NOT AUTHORIZED (private or public)
WEB_PUBLICATION                   = NOT AUTHORIZED
USB / MEDIA TRANSFER              = NOT AUTHORIZED
DELIVERY_STAGING_COPY             = NOT AUTHORIZED
ZIP_EXTRACTION / REPACKAGING      = NOT AUTHORIZED (accepted bytes immutable)
WINDOWS_REBUILD                   = NOT AUTHORIZED
RC / ZIP REGENERATION             = NOT AUTHORIZED
CODE_SIGNING                      = NOT AUTHORIZED (separate future workstream)
CERTIFICATE ACQUISITION/IMPORT    = NOT AUTHORIZED
SIGNING KEYS CREATED              = NOT AUTHORIZED
INSTALLER CREATION                = NOT AUTHORIZED
ANDROID BUILD / SIGNING / RELEASE = NOT AUTHORIZED
PLAY CONSOLE ACTION               = NOT AUTHORIZED
PRODUCTION DEPLOYMENT             = NOT AUTHORIZED
SUPABASE MUTATION / DEPLOYMENT    = NOT AUTHORIZED
EDGE FUNCTION DEPLOYMENT          = NOT AUTHORIZED
RLS / AUTH / SECRETS CHANGE       = NOT AUTHORIZED
P_OD7                             = NOT AUTHORIZED
SYNC DRAIN                        = NOT AUTHORIZED
LICENSING PRODUCTION ACTIVATION   = NOT AUTHORIZED
DURABLE ARCHIVE MUTATION          = NOT AUTHORIZED
SACRED LEGACY ZIP MUTATION        = NOT AUTHORIZED
REPOSITORY CLEANUP                = NOT AUTHORIZED
```

```text
PLANNING_AUTHORITY_NEVER_GRANTS_EXECUTION_AUTHORITY = YES
```

---

## AA. Implementation / Execution Successor Candidate

The natural future candidate is IDENTIFIED but NOT authorized:

```text
CANDIDATE_FUTURE_SESSION =
  PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_EXECUTION
  (class: AUTHORIZED_PRIVATE_CUSTOMER_HANDOFF_EXECUTION — to be granted ONLY by
   a fresh explicit Owner decision)
```

Current successor status:

```text
NEXT_AUTHORIZED_SUCCESSOR            = NONE
OWNER_DECISION_REQUIRED_FOR_EXECUTION = YES
EXECUTION_AUTHORIZED                 = NO
SUCCESSOR_STARTED                    = NO
THE_PLANNING_DOCUMENT_CANNOT_SELF_AUTHORIZE_EXECUTION = YES
A_FRESH_EXPLICIT_OWNER_DECISION_IS_REQUIRED = YES
```

---

## AB. Owner Decision Gate

Before any execution session:

```text
REQUIRED_FRESH_OWNER_DECISIONS (non-exhaustive, all blocking):
  - explicit execution authorization + session class;
  - recipient class / identity authorization;
  - channel approval (section L);
  - staging location approval (section N);
  - security-scan disposition (section S);
  - cleanup/retention disposition for the staging copy;
  - confirmation that artifact identity and unsigned status are still the
    accepted RC values (no silent change to the accepted RC).
```

```text
NO_OWNER_DECISION_IS_IMPLIED_OR_INVENTED = YES
RECOMMENDED_OPTION_IS_NOT_APPROVAL      = YES
```

---

## AC. Repository Allowlist

Preferred mutation allowlist:

```text
ALLOWLIST =
  PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING.md
  (new, this file; exactly ONE planning file)
```

Do NOT modify: application code, Flutter/Dart files, pubspec, lockfiles,
generated files, build artifacts, release artifacts, archive files, legacy data
files, `supabase/` files (including the secret-bearing start-secrets files), or
any existing governance document.

Before commit verify:

```text
git diff --cached --name-status
must contain EXACTLY the planning artifact.
```

Staging rule: explicit path staging only; NEVER `git add .`, `git add -A`, or
`git add -u`.

```text
ALLOWLIST_VIOLATION = NONE
BROAD_STAGING_USED  = NO
```

---

## AD. Commit / Push Rules

Commit (if and only if planning completes successfully):

```text
COMMIT_SUBJECT = docs: plan private windows customer handoff
COMMIT_TYPE    = one normal commit
NO_AMEND = YES | NO_REBASE = YES | NO_SQUASH = YES
NO_RESET = YES | NO_FORCE = YES | NO_HISTORY_REWRITE = YES
```

Push:

```text
PUSH_DEST  = github (https://github.com/sabere342-ai/muaman.worktrees.git)
BRANCH     = codex/i-tech-next-roadmap-freeze
PUSH_TYPE  = normal fast-forward push only
NO_PUSH_ORIGIN = YES
NO_FETCH_ORIGIN = YES
NO_FORCE_PUSH = YES
NO_FORCE_WITH_LEASE = YES
ORIGIN_CONTACTED = NO
```

---

## AE. Final Remote-Lock

After the planning commit and push, verify from live evidence:

```text
FINAL_LOCAL_HEAD
FINAL_TRACKING_HEAD
FINAL_DIRECT_GITHUB_HEAD (read-only `git ls-remote github` preferred)
FINAL_MERGE_BASE
FINAL_AHEAD
FINAL_BEHIND
```

Required lock:

```text
FINAL_LOCAL == FINAL_TRACKING == FINAL_DIRECT_GITHUB == FINAL_MERGE_BASE
FINAL_AHEAD  = 0
FINAL_BEHIND = 0
```

Only then may this planning session claim Remote-Locked PASS. Values are
verified live after the push and reported in the session's final forensic
report.

---

## AF. Mandatory STOP

After remote-locking the plan:

```text
STOP. THIS SESSION DOES NOT:
  - begin execution;
  - transfer the ZIP;
  - create a staging copy;
  - request or infer customer contact details as a pretext to continue.

ABSOLUTE_STOP_BEFORE_CUSTOMER_HANDOFF = YES
THE_NEXT_SESSION_MUST_FIRST_RESOLVE_EXPLICIT_OWNER_AUTHORITY = YES

NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED_FOR_EXECUTION = YES
EXECUTION_AUTHORIZED = NO
SUCCESSOR_STARTED = NO
SESSION_STOPPED = YES
```

```text
PLANNING_COMPLETE = YES

PUBLICATION_EXECUTED      = NO
DISTRIBUTION_EXECUTED     = NO
CUSTOMER_HANDOFF_EXECUTED = NO
FILE_TRANSFER_EXECUTED    = NO
CUSTOMER_CONTACTED        = NO
UPLOAD_EXECUTED           = NO
GITHUB_RELEASE_CREATED    = NO
CODE_SIGNING_EXECUTED     = NO
INSTALLER_CREATED         = NO
WINDOWS_REBUILT           = NO
RC_REGENERATED            = NO
ANDROID_EXECUTED          = NO
PRODUCTION_EXECUTED       = NO
SUPABASE_MUTATION         = NO
P_OD7_EXECUTED            = NO
SYNC_DRAIN_EXECUTED       = NO

DURABLE_ARCHIVE_MODIFIED   = NO
SACRED_LEGACY_ZIP_MODIFIED = NO
ORIGIN_CONTACTED           = NO

EXECUTION_AUTHORIZED = NO
NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED_FOR_EXECUTION = YES
SUCCESSOR_STARTED = NO
```

```text
RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_PLANNING_REMOTE_LOCKED
```