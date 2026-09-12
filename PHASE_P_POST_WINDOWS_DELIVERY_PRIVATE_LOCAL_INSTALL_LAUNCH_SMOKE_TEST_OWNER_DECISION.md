# PHASE P — POST WINDOWS DELIVERY
## PRIVATE LOCAL INSTALL / LAUNCH / SMOKE TEST — EXPLICIT OWNER DECISION

> OWNER-DECISION GOVERNANCE ONLY — REMOTE LOCK.
>
> This session exists ONLY to record the Owner decision concerning the execution
> candidate produced by the completed predecessor execution record
> `PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_EXECUTION`
> (result
> `PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_EXECUTION_REMOTE_LOCKED`,
> which established: `NEXT_AUTHORIZED_SUCCESSOR = NONE`,
> `OWNER_DECISION_REQUIRED_FOR_ANY_FURTHER_WORK = YES`,
> `APP_LAUNCHED_ON_TARGET = NO`, `INSTALLATION_EXECUTED = NO`,
> `EXE_EXECUTED = NO`, `SUCCESSOR_STARTED = NO`).
>
> The Owner has EXPLICITLY AND BINDINGLY decided to authorize exactly ONE
> successor:
> `PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION`
> for the Owner-controlled test device only, where:
>
> `OWNER_CONTROLLED_TEST_DEVICE = CURRENT_WINDOWS_HOST`
>
> `TARGET_DEVICE = CURRENT_WINDOWS_HOST`
>
> `OWNER_DECISION = APPROVE_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION`.
>
> This decision session does NOT itself install, launch, or smoke-test anything.
> `SUCCESSOR_STARTED = NO`.
>
> This session performs NO application installation, NO application launch, NO
> EXE execution, NO ZIP extraction for actual testing, NO smoke test, NO
> database creation through app runtime, NO Windows package rebuild, NO RC
> rebuild/regeneration, NO installer creation, NO code signing, NO registry
> modification, NO firewall modification, NO security weakening, NO Android
> work, NO Play Console action, NO Production/Supabase mutation, NO P/OD7
> activation, NO Sync Drain, and NO licensing-production change.
>
> The durable archived RC and the sacred legacy artifact
> `delivery/I-TECH-Delivery-v1.0.0.zip` remain untouched. The delivered private
> handoff copy
> `C:\Users\saber\I-Tech\TestDeviceHandoff\v1.0.0-b1-RC-20260910-222845\muaman-windows-release.zip`
> remains the immutable test subject and is NOT modified by this decision.
>
> This report contains NO passwords, NO DPAPI ciphertext, NO private key
> material, NO keystore bytes, NO Supabase secrets, NO service-role keys, NO
> access tokens, NO GitHub credentials, and NO customer personal data.

---

## A. Session Result

```text
SESSION       = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION
SESSION_CLASS = OWNER_DECISION_GOVERNANCE_ONLY

ROOT                  = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH                = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE     = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
FORBIDDEN_REMOTE      = origin

OWNER_DECISION            = APPROVE_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
OWNER_RECIPIENT           = OWNER_CONTROLLED_TEST_DEVICE
OWNER_TEST_DEVICE         = CURRENT_WINDOWS_HOST
TARGET_DEVICE             = CURRENT_WINDOWS_HOST
TARGET_DEVICE_AUTHORIZED  = YES
AUTHORIZED_SUCCESSOR      = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
AUTHORIZED_SUCCESSOR_COUNT = 1
SUCCESSOR_STARTED         = NO

RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION_REMOTE_LOCKED
```

The PASS means all of the following are true (each verified live this session):

```text
OWNER_DECISION_RECORDED      = YES
AUTHORIZED_SUCCESSOR_COUNT   = 1
AUTHORIZED_SUCCESSOR         = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
SUCCESSOR_STARTED            = NO
INSTALLATION_STARTED         = NO
APP_LAUNCHED                 = NO
SMOKE_TEST_STARTED           = NO
EXE_EXECUTED                 = NO
COPY_EXTRACTED_FOR_TESTING   = NO
WINDOWS_REBUILT              = NO
RC_REGENERATED               = NO
CODE_SIGNING_EXECUTED        = NO
INSTALLER_CREATED            = NO
ANDROID_EXECUTED             = NO
PRODUCTION_EXECUTED          = NO
SUPABASE_MUTATION            = NO
P_OD7_EXECUTED               = NO
SYNC_DRAIN_EXECUTED          = NO
LICENSING_ACTIVATION_EXECUTED = NO
DURABLE_ARCHIVE_MODIFIED     = NO
SACRED_LEGACY_ZIP_MODIFIED   = NO
ORIGIN_CONTACTED             = NO
REMOTE_LOCK                  = VERIFIED
SESSION_STOPPED              = YES
```

---

## B. Repository Identity

Verified live from repository evidence (forensics, not trust of this prompt
alone):

```text
ROOT    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree)
BRANCH  = codex/i-tech-next-roadmap-freeze
HEAD    = b695c3627b1f4ca45fea78229b75cb95a9c77700 (entry)
SUBJECT = docs: record private windows local test-device handoff
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

No fetch was run; direct GitHub verification used read-only
`git ls-remote github` (no Git metadata mutated).

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
SKILLS_USED           = NONE
PRIMARY_SKILL         = flutter-release (required-skill candidate identified by
                        the session prompt as the expected likely reference only;
                        plus flutter-security. Both granting ZERO authority)
SKILL_SCOPE_EXPANSION = NONE
```

No skill was loaded in this session. This is an
`OWNER_DECISION_GOVERNANCE_ONLY` session; no implementation, migration,
dependency, release, security-sensitive, installation, launch, or smoke-test
activity occurs. No skill grants any execution authority here.

---

## D. Entry Classification

Global Git-operation metadata checked via Git-aware path resolution
(`git rev-parse --git-dir` + existence probe of the worktree-specific paths):

```text
MERGE_HEAD       = ABSENT
CHERRY_PICK_HEAD = ABSENT
REVERT_HEAD      = ABSENT
BISECT_LOG       = ABSENT
rebase-merge     = ABSENT
rebase-apply     = ABSENT
index.lock       = ABSENT
HEAD.lock        = ABSENT
locked           = ABSENT (worktree lock marker)
ORIG_HEAD        = PRESENT (normal reference, not an active-operation marker)
ACTIVE_GIT_OPERATION = NONE
```

Index and tracking state:

```text
ENTRY_HEAD   = b695c3627b1f4ca45fea78229b75cb95a9c77700
INDEX_STATE  = EMPTY (git diff --cached --name-status = empty at entry)
STASH        = PRESERVED
               (stash@{0}: WIP on
                codex/muaman-13-strict-july-workbook-data-migration:
                283ff9d MUAMAN-12: implement local user roles and sales-only access)
               NOT TOUCHED
```

Known pre-existing tracked working-tree residue (present on disk BEFORE this
session, preserved UNTOUCHED) — exactly the documented preserved-residue list:
12 tracked legacy data files deleted on disk (never staged, never restored,
never committed):

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

Count verified from live `git diff --name-status`: 12 tracked deletions. These
deletions were NOT staged, NOT restored, NOT deleted, NOT modified, NOT
committed by this session.

Pre-existing untracked residue (inventoried, PRESERVED, NOT staged, NOT
deleted, NOT modified):

```text
Continue
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip   (SACRED historical residue; preserved read-only)
supabase/.branches/                   (PRESERVED; not staged, not read beyond inventory)
supabase/.temp/                       (PRESERVED; INCLUDES a local start-secrets
                                        material — NOT read, NOT staged, NOT
                                        committed, NOT modified)
```

```text
ENTRY_CLASSIFICATION =
CASE_B_EXPECTED_DIRTY
  (pre-existing residue exactly matches the documented preserved-residue list
   recorded by the canonical predecessor handoff record and the committed
   authority chain; LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE,
   AHEAD = 0, BEHIND = 0, index EMPTY, no staged changes, no active Git
   operation. The 12 tracked deletions exist ONLY in the working tree (unstaged)
   and are preserved untouched. No residue threatens the allowlist or the
   authority chain.)
```

No fetch was run; direct GitHub verification used read-only `git ls-remote
github`.

```text
ORIGIN_CONTACTED = NO
```

---

## E. Preserved Residue

All pre-existing residue was inventoried and PRESERVED untouched during this
session:

```text
12 tracked legacy deletions          = PRESERVED (NOT staged, NOT restored)
stash@{0}                            = PRESERVED (NOT touched)
untracked governance/report residue  = PRESERVED (NOT staged/deleted/modified)
Continue                             = PRESERVED (NOT staged/deleted/modified)
supabase/.branches/                  = PRESERVED
supabase/.temp/                      = PRESERVED (secret-bearing material NOT read)
delivery/I-TECH-Delivery-v1.0.0.zip  = PRESERVED (read-only verified)
durable release archive              = PRESERVED (immutable/read-only verified)
```

None of the residue was included in this session's commit. No cleanup was
performed.

---

## F. Entry Remote-Lock

Network verification used `github` only (read-only
`git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`):

```text
ENTRY_LOCAL_HEAD         = b695c3627b1f4ca45fea78229b75cb95a9c77700
ENTRY_TRACKING_HEAD      = b695c3627b1f4ca45fea78229b75cb95a9c77700
ENTRY_DIRECT_GITHUB_HEAD = b695c3627b1f4ca45fea78229b75cb95a9c77700
ENTRY_MERGE_BASE         = b695c3627b1f4ca45fea78229b75cb95a9c77700
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

## G. Predecessor Authority Chain

The current entry commit is the completed predecessor handoff execution
record:

```text
PREDECESSOR_COMMIT  = b695c3627b1f4ca45fea78229b75cb95a9c77700
PREDECESSOR_SUBJECT = docs: record private windows local test-device handoff
ARTIFACT            = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_EXECUTION.md
ARTIFACT_TRACKED    = YES
```

Live review of the committed predecessor execution record confirmed the exact
final token and the successor gate:

```text
PREDECESSOR_RESULT =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_CUSTOMER_HANDOFF_EXECUTION_REMOTE_LOCKED

NEXT_AUTHORIZED_SUCCESSOR                  = NONE
OWNER_DECISION_REQUIRED_FOR_ANY_FURTHER_WORK = YES
SUCCESSOR_STARTED                          = NO
APP_LAUNCHED_ON_TARGET                     = NO
INSTALLATION_EXECUTED                      = NO
EXE_EXECUTED                               = NO
CUSTOMER_HANDOFF_EXECUTED                  = YES (local, channel A,
                                           CURRENT_WINDOWS_HOST only)
RECIPIENT_SIDE_HASH_VERIFICATION           = PASS
```

The predecessor explicitly recorded:

```text
THE_PREDECESSOR_CANNOT_SELF_AUTHORIZE_LAUNCH = YES
A_FRESH_EXPLICIT_OWNER_DECISION_IS_REQUIRED  = YES
```

```text
PREDECESSOR_AUTHORITY_VERIFIED     = YES
LAUNCH_AUTHORITY_INHERITED_FROM_PREDECESSOR = NO (deliberately; predecessor
                                               grants none)
PREDECESSOR_RESULT_MATCHES         = YES
```

Live host evidence of the delivered test subject (read-only, no mutation):

```text
HANDOFF_DIR  = C:\Users\saber\I-Tech\TestDeviceHandoff\v1.0.0-b1-RC-20260910-222845
  integrity-note.txt        SIZE = 653
  muaman-windows-release.zip
    SIZE   = 16279806
    SHA256 = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
             (matches the canonical recorded identity: begins 879761AF, ends FF5C5)
```

Release identity remains immutable:

```text
WINDOWS_REBUILT               = NO
RC_REGENERATED                = NO
DELIVERED_ZIP_MODIFIED        = NO
DURABLE_ARCHIVE_MODIFIED      = NO
SACRED_LEGACY_ZIP_MODIFIED    = NO
UNSIGNED_PRIVATE_TEST_ONLY    = YES
CODE_SIGNING_EXECUTED         = NO
```

---

## H. Explicit Owner Decision — Verbatim

The explicit Owner choice supplied in the session input, recorded EXACTLY as
supplied (no reinterpretation):

```text
OWNER_DECISION = APPROVE_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION

I, as Owner, explicitly authorize exactly ONE successor:

PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION

AUTHORIZED_SUCCESSOR_COUNT = 1

The authorized successor is bounded to a controlled private local
installation/launch/smoke-test workflow using the already delivered private
handoff artifact on the Owner-controlled CURRENT_WINDOWS_HOST only.

This Owner-decision session itself performs governance only.
```

```text
OWNER_DECISION_VALID       = YES
OWNER_DECISION_UNAMBIGUOUS = YES
OWNER_DECISION_VERBATIM    = YES
OWNER_DECISION_GRANTED     = EXECUTION (private local install/launch/smoke test)
```

The decision does not waive any safety gate. It grants launch/installation
permission ONLY for the single named successor, on the single named device,
subject to all boundaries in sections I–V.

---

## I. Owner-Controlled Test Device Identity

The only authorized test device is the Owner-controlled machine on which this
session itself runs:

```text
OWNER_CONTROLLED_TEST_DEVICE = CURRENT_WINDOWS_HOST
OWNER_RECIPIENT              = OWNER_CONTROLLED_TEST_DEVICE
OWNER_TEST_DEVICE            = CURRENT_WINDOWS_HOST
TARGET_DEVICE                = CURRENT_WINDOWS_HOST
TARGET_DEVICE_AUTHORIZED     = YES
```

```text
EXTERNAL_CUSTOMER_DEVICE_AUTHORIZED = NO
SECOND_PC_AUTHORIZED                = NO
VM_AUTHORIZED                       = NO (unless a separate future Owner decision
                                          explicitly authorizes one)
REMOTE_MACHINE_AUTHORIZED           = NO
CLOUD_MACHINE_AUTHORIZED            = NO
```

---

## J. Authorized Successor

```text
AUTHORIZED_SUCCESSOR        = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
AUTHORIZED_SUCCESSOR_COUNT  = 1

SUCCESSOR_PURPOSE           = perform a minimal private local verification
                              workflow ONLY:
                              1. verify delivered archive identity again,
                              2. prepare a safe local test directory,
                              3. extract the delivered Windows release locally
                                 if required,
                              4. verify extracted package structure,
                              5. verify expected EXE identity if practical,
                              6. determine portable-versus-installer form,
                              7. launch the application locally,
                              8. observe startup behavior,
                              9. perform a narrowly defined minimal smoke test,
                              10. verify basic app-shell operability,
                              11. record errors/warnings factually,
                              12. close the application,
                              13. collect only necessary local evidence,
                              14. preserve all unrelated local data,
                              15. commit ONLY the successor's own
                                  governance/evidence record if its own
                                  allowlist authorizes it,
                              16. STOP.
SUCCESSOR_MUTATION_TYPE     = private local filesystem test preparation +
                              execution observation; repository mutation limited
                              strictly to the future session's own
                              governance/evidence artifact under its own
                              allowlist
```

```text
MULTIPLE_SUCCESSORS = NO
PARALLEL_SUCCESSORS = NONE
AUTHORIZED_SUCCESSOR_COUNT = 1
NO_ALTERNATE_SUCCESSOR = YES
```

No alternate successor and no parallel successor is authorized by this decision.

---

## K. Installation Boundary

The successor must first determine the actual delivered package form and MUST
NOT assume an installer exists.

```text
INSTALLER_CREATION     = NO (no MSI/MSIX/EXE installer generation)
INSTALLER_EXISTS_KNOWN = REQUIRED_DETERMINATION (portable Flutter bundle expected)
LOCAL_INSTALL_APPLICABLE = TO_BE_DETERMINED_BY_SUCCESSOR (genuine install only if
                           the package form actually requires it)
```

If the release is a portable Flutter Windows bundle, it must be treated as a
portable bundle. No packaging system may be introduced.

```text
REGISTRY_MODIFICATION      = NOT AUTHORIZED
FIREWALL_MODIFICATION      = NOT AUTHORIZED
DEFENDER_OR_SECURITY_WEAKENING = NOT AUTHORIZED
UAC_DISABLE                = NOT AUTHORIZED
```

---

## L. Launch Boundary

```text
LOCAL_LAUNCH_AUTHORIZED        = YES (single successor, single device, private local only)
APP_LAUNCHED                   = NO (in THIS decision session)
EXE_EXECUTED                   = NO (in THIS decision session)
MUAMAN_STORE_EXE_EXECUTED      = NO
```

The future successor may launch the application only after its own preflight
passes. If Windows blocks execution in a way that requires weakening secure
controls (Defender, SmartScreen, UAC, execution policy, exclusions):

```text
STOP
REPORT_THE_BLOCKER
NO_BYPASS
NO_SECURITY_WEAKENING
```

---

## M. Smoke Test Boundary

The future successor's smoke test must remain MINIMAL. It is NOT a broad QA
mandate.

Potentially authorized checks (successor determines feasibility and safety):

```text
APP_LAUNCHES                     = allowed check
MAIN_WINDOW_RENDERS              = allowed check
OBVIOUS_FATAL_STARTUP_ERROR      = observe/record (absent or present)
ARABIC_RTL_SHELL_BASIC_RENDER    = allowed check
NAVIGATION_SHELL_OPENS_WHERE_SAFE = allowed check
APP_CLOSES_NORMALLY              = allowed check
ERRORS_AND_WARNINGS_RECORDED_FACTUALLY = required
```

```text
BROAD_QA_AUTHORIZED          = NO
PRODUCTION_FUNCTIONAL_TEST   = NO
DATA_CREATION_MUST_BE_MINIMAL = YES
SYNTHETIC_TEST_DATA_ONLY_IF_EXPLICITLY_PERMITTED = YES
NO_REAL_CUSTOMER_OR_SHOP_DATA = YES
```

If a problem is discovered:

```text
OBSERVE -> RECORD -> CLASSIFY -> STOP
REMEDIATION_IMPLEMENTATION = NOT AUTHORIZED (unless the future execution prompt
                              itself independently and explicitly authorizes it)
```

---

## N. Data / Database Safety

```text
REAL_CUSTOMER_DATA_IMPORT_FOR_TESTING  = NOT AUTHORIZED
REAL_DATABASE_COPY_INTO_APP            = NOT AUTHORIZED
REAL_BACKUP_RESTORE_FOR_TESTING        = NOT AUTHORIZED
SENSITIVE_REAL_WORLD_DATA_ENTRY        = NOT AUTHORIZED
```

If launching the app would create a brand-new local empty test database as
normal first-run behavior, the execution successor must detect and document it
before proceeding.

If an existing database is discovered in the intended runtime path:

```text
DO NOT overwrite it
DO NOT migrate it
DO NOT reuse it automatically
STOP or isolate safely according to the future execution prompt
```

This governance session has not touched any database and creates no data.

---

## O. Unsigned Windows Boundary

Current governance identity:

```text
ALLOW_UNSIGNED_PRIVATE_ONLY = YES
WINDOWS_APP_SIGNING_STATUS   = UNSIGNED
CODE_SIGNING_EXECUTED        = NO
UNSIGNED_PRIVATE_TEST_ONLY   = YES
```

The successor must disclose that the artifact is unsigned (unless verified
otherwise) and MUST NEVER claim publisher-signing exists. It MUST NEVER disable
Windows Defender, SmartScreen, UAC, or endpoint protection, and MUST NEVER run
bypass commands or weaken PowerShell execution policy globally.

```text
UNSIGNED_DISCLOSURE_READY = YES (required before any launch)
HASH_VERIFICATION_BEFORE_TRUST = YES
NO_DISABLING_WINDOWS_SECURITY  = YES
NO_BYPASS_INSTRUCTIONS         = YES
NO_PRESENTATION_AS_SIGNED      = YES
```

---

## P. Backend / Network Boundary

The successor is NOT authorized to convert a local smoke test into a live
backend integration test.

```text
SUPABASE_MUTATION      = NO
PRODUCTION_API_CALLS_TARGETED = NO
LICENSING_ACTIVATION   = NO
ACCOUNT_CREATION_FOR_TEST = NO
PRODUCTION_LOGIN_FOR_TEST_ONLY = NO
SYNC_DRAIN_ACTIVATION  = NO
CLOUD_WRITE_TESTING    = NO
```

If the application attempts unavoidable network activity at launch, the
execution session must observe and reason conservatively. It must NOT weaken
security controls to make the app work.

---

## Q. Docker / Supabase Protection Boundary

This machine may host another project's Docker/Supabase runtime or
project-specific local Supabase state. Nothing of that kind may be touched.

```text
DOCKER_STOP            = NO
DOCKER_START           = NO
DOCKER_RESTART         = NO
DOCKER_PROCESS_KILL    = NO
DOCKER_PRUNE           = NO
CONTAINER_REMOVAL      = NO
VOLUME_REMOVAL         = NO
DOCKER_NETWORK_CHANGE  = NO
UNRELATED_SUPABASE_CONTAINER_TOUCH = NO
```

For this I Tech repository specifically, local runtime residue is preserved:

```text
supabase/.temp/     = PRESERVED
supabase/.branches/ = PRESERVED
SUPABASE_MUTATION   = NO
```

---

## R. Android Hard Stop

```text
ANDROID     = NO
APK_BUILD   = NO
AAB_BUILD   = NO
GRADLE_RELEASE = NO
PACKAGE_IDENTITY_CHANGE = NO
SIGNING_CONFIGURATION_CHANGE = NO
SIGNING_KEY_ROTATION = NO
PLAY_CONSOLE = NO
BUNDLE_UPLOAD = NO
RELEASE_CREATION = NO
TRACK_CHANGE = NO
ANDROID_TESTING = NO
ANDROID_DEVICE_INSTALL = NO
```

---

## S. Production Hard Stop

```text
PRODUCTION = NO
ENVIRONMENT_SWITCH        = NO
PROMOTION                 = NO
CUSTOMER_WIDE_RELEASE     = NO
PRODUCTION_CONFIG_CHANGE  = NO
PRODUCTION_DATA_MIGRATION = NO
PRODUCTION_SYNC_ACTIVATION = NO
PRODUCTION_LICENSING_ENABLE = NO
CUSTOMER_RELEASE_SEND     = NO
```

---

## T. P/OD7 / Sync Drain Hard Stop

```text
P_OD7             = NO
SYNC_DRAIN        = NO
LICENSING_ACTIVATION = NO
```

---

## U. Publication / Distribution Hard Stop

```text
PUBLICATION        = NO
GITHUB_RELEASE     = NO
PUBLIC_URL         = NO
CLOUD_UPLOAD       = NO
SHARED_DRIVE       = NO
EMAIL_TRANSFER     = NO
NETWORK_TRANSFER   = NO
REMOTE_CUSTOMER_TRANSFER = NO
USB_TRANSFER       = NO
REMOVABLE_MEDIA_WRITTEN = NO
EXTERNAL_DEVICE_HANDOFF = NO
```

---

## V. Repository Mutation / Allowlist

```text
ALLOWLIST =
  PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION.md (new, this file)
MUTATED_PATHS   = exactly the allowlisted decision artifact
APPLICATION CODE = NOT TOUCHED
DEPENDENCIES     = NOT TOUCHED
TESTS            = NOT TOUCHED
SCRIPTS          = NOT TOUCHED
PUBSPEC FILES    = NOT TOUCHED
BUILD OUTPUTS    = NOT TOUCHED
SUPABASE FILES   = NOT TOUCHED
DELIVERY ARTIFACTS = NOT TOUCHED
HANDOFF DIRECTORY  = NOT TOUCHED
ARCHIVES         = NOT TOUCHED
BINARIES         = NOT TOUCHED
DOCKER STATE     = NOT TOUCHED
EXISTING GOVERNANCE DOCUMENTS = NOT TOUCHED
```

Staging uses explicit path only:

```text
git add -- PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION.md
```

`git add .`, `git add -A`, and `git add -u` were NOT used and are forbidden.
All pre-existing residue remains unstaged.

---

## W. Commit

```text
COMMIT_SUBJECT = docs: authorize private local windows install launch smoke test execution
COMMIT_TYPE    = single normal commit
AMEND          = NO
REBASE         = NO
SQUASH         = NO
RESET          = NO
FORCE          = NO
CHERRY_PICK    = NO
```

The staged allowlist is proven immediately before commit via
`git diff --cached --name-status` (documented in this session's final forensic
output; expected exactly this one file).

---

## X. Push

```text
PUSH_DEST  = github (https://github.com/sabere342-ai/muaman.worktrees.git)
BRANCH     = codex/i-tech-next-roadmap-freeze
PUSH_TYPE  = normal fast-forward push only
FORCE      = NO
FORCE_WITH_LEASE = NO
FETCH_ALL  = NO
ORIGIN_CONTACTED = NO
```

---

## Y. Final Remote-Lock

After the push, the session verifies from live evidence (read-only
`git ls-remote github`):

```text
FINAL_LOCAL_HEAD
FINAL_TRACKING_HEAD
FINAL_DIRECT_GITHUB_HEAD
FINAL_MERGE_BASE
FINAL_AHEAD
FINAL_BEHIND
```

Lock contract:

```text
FINAL_LOCAL == FINAL_TRACKING == FINAL_DIRECT_GITHUB == FINAL_MERGE_BASE
FINAL_AHEAD  = 0
FINAL_BEHIND = 0
REMOTE_LOCK  = VERIFIED
```

The exact post-push values are verified live after the push and reported in this
session's final forensic report. No remote-lock claim is made without that
evidence.

---

## Z. Explicit Non-Authorizations

This decision does NOT authorize anything not explicitly stated. In particular:

```text
INSTALLING_RIGHT_NOW              = NOT AUTHORIZED (in this decision session)
LAUNCHING_RIGHT_NOW               = NOT AUTHORIZED
SMOKE_TESTING_RIGHT_NOW           = NOT AUTHORIZED
FIXING_BUGS                       = NOT AUTHORIZED
WINDOWS_REBUILD                   = NOT AUTHORIZED
RC_REGENERATION                   = NOT AUTHORIZED
CODE_SIGNING                      = NOT AUTHORIZED
CERTIFICATE ACQUISITION/IMPORT    = NOT AUTHORIZED
INSTALLER CREATION                = NOT AUTHORIZED
PUBLICATION / DISTRIBUTION        = NOT AUTHORIZED
EXTERNAL CUSTOMER HANDOFF         = NOT AUTHORIZED
ARTIFACT MOVED TO ANOTHER DEVICE  = NOT AUTHORIZED
SECOND_PC / VM / REMOTE DEVICE    = NOT AUTHORIZED
NETWORK_TRANSFER                  = NOT AUTHORIZED
USB / REMOVABLE MEDIA             = NOT AUTHORIZED
CLOUD_UPLOAD                      = NOT AUTHORIZED
EMAIL                             = NOT AUTHORIZED
GITHUB_RELEASE                    = NOT AUTHORIZED
ANDROID BUILD / SIGNING / RELEASE = NOT AUTHORIZED
PLAY CONSOLE ACTION               = NOT AUTHORIZED
PRODUCTION DEPLOYMENT             = NOT AUTHORIZED
SUPABASE MUTATION / DEPLOYMENT    = NOT AUTHORIZED
RLS / AUTH / SECRETS CHANGE       = NOT AUTHORIZED
P_OD7                             = NOT AUTHORIZED
SYNC DRAIN                        = NOT AUTHORIZED
LICENSING PRODUCTION ACTIVATION   = NOT AUTHORIZED
DOCKER MAINTENANCE                = NOT AUTHORIZED
DURABLE ARCHIVE MUTATION          = NOT AUTHORIZED
SACRED LEGACY ZIP MUTATION        = NOT AUTHORIZED
REPOSITORY CLEANUP                = NOT AUTHORIZED
```

The authorized successor scope is ONLY the narrowly bounded private local
install/launch/smoke-test workflow on CURRENT_WINDOWS_HOST per sections I–P.

---

## AA. Final Result Token

```text
OWNER_DECISION_RECORDED      = YES
AUTHORIZED_SUCCESSOR_COUNT   = 1
AUTHORIZED_SUCCESSOR         = PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION
SUCCESSOR_STARTED            = NO
INSTALLATION_STARTED         = NO
APP_LAUNCHED                 = NO
SMOKE_TEST_STARTED           = NO
EXE_EXECUTED                 = NO
WINDOWS_REBUILT              = NO
RC_REGENERATED               = NO
CODE_SIGNING_EXECUTED        = NO
INSTALLER_CREATED            = NO
PUBLICATION                 = NO
NETWORK_TRANSFER            = NO
REMOVABLE_MEDIA_WRITTEN      = NO
CLOUD_UPLOAD                 = NO
EMAIL_TRANSFER              = NO
GITHUB_RELEASE              = NO
ANDROID                      = NO
PLAY_CONSOLE                 = NO
PRODUCTION                   = NO
SUPABASE_MUTATION           = NO
P_OD7                        = NO
SYNC_DRAIN                   = NO
LICENSING_ACTIVATION        = NO
DURABLE_ARCHIVE_MODIFIED     = NO
SACRED_LEGACY_ZIP_MODIFIED   = NO
ORIGIN_CONTACTED             = NO
SESSION_STOPPED              = YES
```

```text
RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_OWNER_DECISION_REMOTE_LOCKED
```

---

## AB. Mandatory STOP

This session stops here. It does NOT begin the authorized successor session.

```text
INSTALLATION_STARTED   = NO
APP_LAUNCHED           = NO
SMOKE_TEST_STARTED     = NO
EXE_EXECUTED           = NO
COPY_EXTRACTED_FOR_TESTING = NO
SUCCESSOR_STARTED      = NO
SESSION_STOPPED        = YES
```

The next execution step requires a NEW separate session using
`PHASE_P_POST_WINDOWS_DELIVERY_PRIVATE_LOCAL_INSTALL_LAUNCH_SMOKE_TEST_EXECUTION`
as its sole authority.