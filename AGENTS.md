# I Tech Store Management — Agent Operating Contract

## 1. Purpose

This repository is governed by strict evidence-first implementation,
Git-forensic, testing, security, and remote-lock procedures.

An AI coding agent must optimize for:

1. correctness,
2. repository evidence,
3. scope discipline,
4. preservation of existing work,
5. reproducibility,
6. explicit owner authorization,
7. security,
8. remote-lock integrity.

Never optimize for speed by skipping governance or verification.

## 2. Repository Identity

Canonical working repository:

`C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze`

Canonical branch:

`codex/i-tech-next-roadmap-freeze`

Authorized remote:

`github`

Forbidden / sacred remote:

`origin`

`origin` MUST NEVER be contacted.

Reading local Git configuration that displays the origin URL is permitted.
Network or filesystem remote operations against origin are prohibited.

## 3. Project Identity

Durable project facts (re-verify from repository evidence before relying on
them; do not copy transient session state here):

- Product: I Tech Store Management
- Arabic product name: I Tech لإدارة المحلات
- Primary platforms: Windows Desktop and Android
- Primary language behavior: Arabic, RTL-first
- Currency: EGP (`ج.م`)
- Flutter application root: `app/`
- Local persistence: SQLite via `sqflite` / `sqflite_common_ffi`
- Cloud backend: Supabase / PostgreSQL
- Multi-tenant shop isolation keyed by `shop_id`
- Row Level Security applied to server tables
- Android application ID (verified in
  `app/android/app/build.gradle`): `com.itech.storemanagement`

Established architecture layers in `app/lib/`: `database`, `repositories`,
`services`, `sync`, `licensing`, `rbac`, `screens`, and `widgets`.

## 4. Instruction Precedence

When instructions conflict, precedence is:

1. explicit owner/user instruction,
2. binding repository governance / committed authority,
3. closest applicable `AGENTS.md`,
4. selected task skills,
5. general engineering defaults.

Skills never create authority. A skill alone never authorizes
implementation, migration, dependency changes, release, push, deployment,
production work, or destructive actions.

## 5. Evidence-First Rule

Never assume repository state, architecture, dependencies, phase state,
authorization, migration number, test command, or implementation status.

Inspect actual repository evidence first.

Distinguish explicitly between:

- VERIFIED
- NOT VERIFIED
- INFERRED

Do not present inferred facts as verified facts.

When governance documents conflict or differ chronologically:

1. identify both authorities,
2. determine chronology and supersession,
3. prefer the strongest later authority where explicitly justified,
4. preserve older documents as historical evidence,
5. do not call an older artifact "invalid" merely because a later closeout exists,
6. report unresolved contradictions instead of silently reconciling them.

## 6. Mandatory Session Entry Forensics

Before any implementation, modification, commit, deployment, migration,
or governance mutation, verify:

- repository root
- current branch
- local HEAD
- tracking branch
- tracking HEAD
- direct authorized remote HEAD when network verification is required
- merge-base
- ahead
- behind
- tracked worktree state
- index state
- untracked state
- active merge
- active rebase
- active cherry-pick
- active revert
- active bisect

For direct GitHub verification prefer:

`git ls-remote github refs/heads/<current-branch>`

over `git fetch`.

A read-only forensic session should avoid `git fetch` because fetch mutates
local Git metadata such as FETCH_HEAD and possibly remote-tracking refs.

If a fetch is explicitly authorized, report it as a Git metadata mutation.

## 7. Linked-Worktree Awareness

This repository uses a linked Git worktree.

Never assume `.git` is a directory.

Use Git-aware path resolution:

`git rev-parse --git-dir`
`git rev-parse --git-path <name>`

for MERGE_HEAD, CHERRY_PICK_HEAD, REVERT_HEAD, BISECT_LOG,
rebase-merge, rebase-apply, and similar Git-operation metadata.

## 8. Entry Classification

Classify repository entry explicitly.

### CASE_A_FRESH

Use only when:

- local HEAD == tracking HEAD,
- direct authorized remote HEAD == local HEAD when checked,
- merge-base == local HEAD,
- ahead == 0,
- behind == 0,
- tracked worktree clean,
- index clean,
- no active Git operation.

Pre-existing untracked files do not automatically invalidate CASE_A_FRESH,
but they must be inventoried and preserved.

### CASE_B_EXPECTED_LOCAL_IMPLEMENTATION_RECOVERY

Use only when repository evidence proves the local state belongs to the
expected authorized unfinished/current implementation.

Do not create duplicate commits.

Re-verify prior work before continuing.

### CASE_C_UNEXPECTED_DIRTY

Use when tracked modifications or staged changes exist that cannot be proven
to belong to the authorized task.

STOP.

Do not overwrite, restore, stash, reset, or delete them.

### CASE_D_REMOTE_DIVERGENCE

Use when local/tracking/direct-authorized-remote ancestry or ahead/behind
does not satisfy the expected contract.

STOP.

Do not pull, merge, rebase, reset, or force push.

### CASE_E_ACTIVE_GIT_OPERATION

Use when merge/rebase/cherry-pick/revert/bisect or another unexpected
Git operation is active.

STOP unless the task explicitly authorizes recovery from that exact operation.

## 9. Preserve Existing Work

Never destroy or hide pre-existing work.

Forbidden unless explicitly owner-authorized for a precisely identified target:

- `git reset --hard`
- `git clean`
- broad `git restore`
- broad checkout restoration
- automatic stash
- rebase
- commit amend
- force push
- force-with-lease
- deleting unknown untracked files

Never revert changes merely because they were not created by the current agent.

If unexpected modifications exist:

STOP and report them.

## 10. Remote Safety

Only `github` is authorized for Git network operations.

Never contact `origin`.

Never use:

`git fetch --all`

or commands that implicitly contact every remote.

Never force push.

Normal pushes must be ordinary fast-forward pushes to the explicitly
authorized `github` branch only.

Before push, verify destination remote and branch explicitly.

After push, prove remote lock.

## 11. Remote-Lock Contract

When a task explicitly authorizes commit and push, successful closeout requires
post-push proof.

Verify:

POST_PUSH_LOCAL_HEAD
POST_PUSH_TRACKING_HEAD
POST_PUSH_DIRECT_GITHUB_HEAD
POST_PUSH_MERGE_BASE
POST_PUSH_AHEAD
POST_PUSH_BEHIND

Expected lock:

LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE
AHEAD == 0
BEHIND == 0

Also verify:

- normal push only
- no force push
- origin not contacted

Never claim REMOTE_LOCKED without this evidence.

## 12. Scope and Governance Boundaries

The current task/slice/phase authorization is an allowlist.

Do only what is explicitly authorized.

Never begin:

- successor slice,
- successor group,
- successor phase,
- adjacent remediation,
- opportunistic refactor,
- unrelated cleanup

without explicit authorization.

A technically useful change is still forbidden when outside scope.

If implementation depends on unresolved owner decisions:

DO NOT IMPLEMENT.

Report the owner gate and STOP.

Before working on Phase P / Group D or successors, inspect the latest relevant
governance artifacts.

Do not assume a historical D1/D2 status remains current.

## 13. Owner Decisions

Owner-gated decisions are hard implementation gates.

A recommended/default option is NOT equivalent to owner approval.

Never silently convert:

RECOMMENDED

into:

APPROVED

or:

AUTHORIZED.

When a decision is PENDING_OWNER and documented as blocking implementation:

STOP before implementation.

## 14. Allowlist Discipline

When a task provides an authorized file allowlist:

- modify only those files,
- do not expand scope,
- inspect `git diff --name-only` before validation,
- inspect it again before commit,
- fail closed on any unexpected tracked file.

Generated/build/cache artifacts must not be confused with authorized source
changes.

## 15. Flutter / Dart Safety

Flutter application root must be verified from repository evidence.

Inspect `app/pubspec.yaml` and confirm the Flutter app root is `app/`.

Dart tests live under `app/test/`.

Do not invent test paths.

Use existing repository/governance evidence to select validation commands.

Never run dependency upgrades unless explicitly authorized.

Do not run:

`flutter pub upgrade`

during ordinary implementation or validation.

Do not alter pubspec files unless allowlisted.

## 16. Required Skill Routing

For non-trivial Flutter work, classify the task, select the minimal relevant
skill set, verify each selected skill exists, read each selected `SKILL.md`
completely, read only relevant references, then inspect the existing
implementation before acting.

Route task types to skills:

- General Flutter implementation: `flutter-core-engineering`
- UI / UX work: core + `flutter-ui-ux`, `flutter-rtl-arabic`,
  `flutter-accessibility`, `flutter-testing`
- Business logic / bug fix: core + `flutter-testing`
- Database / offline / sync: core + `flutter-offline-data`,
  `flutter-testing`; add `flutter-security` when auth, licensing, tenant,
  sensitive data, or permissions are involved
- Performance work: core + `flutter-performance`, `flutter-testing`
- Security / auth / licensing / device trust / permissions: core +
  `flutter-security`, `flutter-testing`
- Review-only: `flutter-code-review`; add a specialist skill only when the
  review scope requires it
- Release / build / signing: `flutter-release`; add
  `flutter-security` and `flutter-testing` only where the release contract
  requires them

Mandatory rule:

DO NOT LOAD ALL SKILLS FOR EVERY TASK.

Use the minimum relevant set.

## 17. Required Skill Availability Rule

Before non-trivial Flutter work:

1. classify the task,
2. select the minimal relevant skills,
3. verify the selected skills exist,
4. read the selected `SKILL.md`,
5. read only relevant references,
6. inspect the existing implementation,
7. then act within current authorization.

If a required skill is unavailable:

do not pretend it loaded.

Return:

REQUIRED_SKILL_UNAVAILABLE
SKILL = <name>
ACTION = STOP_BEFORE_IMPLEMENTATION

## 18. Architecture Invariants

PRESERVE ESTABLISHED ARCHITECTURE.

Do not interpret Flutter best-practice guidance as permission to rewrite the
application architecture.

No wholesale migration to:

- BLoC
- Riverpod
- Provider
- Redux
- MVVM
- Clean Architecture
- another navigation framework
- another database
- another backend

unless explicitly authorized.

Apply improvements incrementally within the current authorization.

Keep business and accounting invariants out of presentation-only code and
preserve transaction ownership.

## 19. UI / UX / RTL Rules

Arabic-first and RTL behavior are product requirements.

Consider:

- RTL layouts and directional APIs
- mixed Arabic/English text
- EGP display
- tables
- reports
- PDFs
- forms
- dialogs
- focus and keyboard behavior
- desktop density
- Android touch ergonomics

Prefer directional concepts over hard-coded left/right assumptions where
appropriate.

Reuse existing theme/widgets.

Do not require visual redesign unless the task calls for it.

## 20. Data and Persistence Rules

Treat local persistence and its lifecycle as durable.

Sensitive areas:

- SQLite data
- migrations
- existing customer data
- offline queues
- retries
- duplicate prevention
- idempotency
- sync conflicts
- backups
- restore
- clock assumptions

Persistent schema changes must consider:

- fresh install
- upgrade path
- existing data
- tests
- restore/backup interaction

No casual schema mutation.

Never trust a client-supplied `shop_id` without server-side authorization.

## 21. Static Analysis Reporting

Never flatten or hide analyzer results.

Always preserve separately:

- command
- exit code
- errors
- warnings
- infos
- total issues

Never claim that `0 errors` means the analyzer command exited successfully.

Likewise, do not automatically classify an established non-zero analyzer
baseline as implementation failure unless the governing acceptance contract
requires exit code zero.

Report BOTH:

1. raw analyzer result,
2. acceptance classification under the applicable governance contract.

Never silently change one into the other.

## 22. Testing Requirements

Choose the test type that matches the behavior under change:

- Business logic change: unit test
- Widget behavior: widget test
- Bug fix: regression test
- Critical workflow: integration test
- Database migration: fresh DB test and upgrade-path test
- Roles/permissions: authorized case and unauthorized case
- Offline behavior: offline, reconnect, retries, duplicates, conflicts where
  applicable

Never treat:

`flutter analyze`

as a substitute for tests.

Never treat:

`flutter test`

as proof that a packaged Windows or Android release works.

## 23. Test Reporting

For every executed test command preserve:

- exact command
- exit code
- passed count
- failed count

Do not report PASS merely because output appears favorable if the command
exit code is non-zero.

Do not fix unrelated failures unless explicitly authorized.

Classify them as:

- task-caused,
- pre-existing,
- environmental,
- NOT VERIFIED

only when evidence supports the classification.

## 24. Performance Requirements

Do not claim performance improvement without measurement on representative
Windows/Android data and an appropriate build mode.

Relevant investigation may include:

- rebuilds
- large lists/tables
- startup
- DB queries
- memory
- PDF/report generation
- blocking I/O
- jank

Do not force performance work into unrelated tasks.

## 25. Security Requirements

Never embed secrets.

Never expose tokens in reports.

Verify authorization server-side:

UI hiding is not authorization.

Tenant isolation requires negative tests.

RLS-sensitive work requires explicit tests.

Licensing/entitlement changes require bypass/tamper consideration.

Local storage of secrets requires review.

Production penetration testing is not implicitly authorized.

`NOT_VERIFIED` must never be reported as `PASS`.

Critical/High security findings block release unless explicitly dispositioned
under project governance.

Protected durable domains:

- authentication
- authorization
- owner/seller role boundaries
- multi-tenant isolation
- RLS
- shop ownership boundaries
- device trust
- licensing
- entitlement
- offline grace
- clock/tamper handling
- local cache
- inventory integrity
- financial/reporting integrity
- PDF/report generation
- release signing

Changes touching these domains require explicit testing and heightened review.

Also apply the secret-handling rules below.

### Secret Handling

Never expose, print, commit, summarize, or transmit secrets.

Do not read secret-bearing files unless explicitly necessary and authorized.

Sensitive examples include:

- `.env`
- private keys
- Android signing keys
- keystores
- key passwords
- Supabase service-role keys
- access tokens
- production credentials

`.env.example` may be inspected only as a non-secret template.

Never put secrets into logs, governance artifacts, prompts, commits, or reports.

## 26. Supabase / Production Safety

Production mutation is forbidden by default.

Never perform without explicit task authorization:

- production migration
- production SQL mutation
- Edge Function deployment
- production secrets change
- production Auth mutation
- production RLS change
- production data repair

A governance/planning/testing task does NOT imply production authorization.

Local or isolated test database execution does not imply production permission.

## 27. Migration Discipline

Never invent the next migration number.

Inspect:

- existing migrations,
- authoritative governance,
- remote/production state when explicitly authorized to inspect it.

Do not rewrite already deployed migrations unless a specific governing contract
explicitly authorizes that operation.

Prefer additive corrective migrations where required by repository governance.

## 28. Accessibility Requirements

UI changes must consider:

- semantics
- keyboard navigation
- focus
- text scaling
- labels (including Arabic)
- contrast
- error feedback
- touch targets

Keep requirements proportional to task scope.

## 29. Platform Rules

Verify platform-specific behavior separately.

Preserve:

- application/package identity
- secure storage behavior
- file/database locations
- runtime plugins
- assets/fonts
- manifest intent

Do not assume a Windows result proves Android behavior.

## 30. Documentation and Governance Accuracy

Governance artifacts are evidence documents.

Do not fabricate:

- command output,
- commit hashes,
- test counts,
- remote-lock values,
- production evidence,
- timestamps,
- approval state.

If evidence is unavailable:

write `NOT VERIFIED`.

Never write placeholders as if they were completed proof.

## 31. Commit Discipline

A commit requires explicit authorization from the current task.

Before commit:

- verify allowlist
- verify diff
- verify tests
- verify governance acceptance
- verify no unintended files

Do not amend an existing published commit unless explicitly authorized.

Prefer one coherent normal commit when the task contract requires one.

Never create an extra "cleanup" or evidence commit unless the governing task
requires it.

## 32. Push Discipline

A push requires explicit authorization.

Never infer push permission merely because commit permission exists.

Push only to:

`github`

and only to the authorized current branch.

No force variants.

After push perform remote-lock proof before reporting success.

## 33. Release Governance Rules

Encode durable release principles, not transient release state.

- Debug != Release
- Test PASS != packaged-artifact PASS
- Windows and Android release evidence are separate
- release artifact identity matters
- signing matters
- package/application ID matters
- version identity matters
- accepted RC bytes must not silently mutate
- Delivery/Production require explicit authorization when project governance
  says so
- never infer downstream authority from an upstream PASS

Do not encode a specific RC ID or current downstream blocker into this file.

## 34. Untracked Files

Pre-existing untracked files may be important artifacts.

Inventory but do not delete, stage, modify, move, or clean them unless the
current task explicitly authorizes those exact paths.

Do not let pre-existing untracked files silently enter a commit.

Use targeted staging, never indiscriminate staging, when sensitive artifacts
exist.

Avoid:

`git add .`

and:

`git add -A`

unless the exact resulting set has been independently proven safe and the task
explicitly permits it.

Prefer explicit path staging.

## 35. Agent-Created Runtime Files

Do not create AI-agent configuration, snapshots, caches, or metadata inside
this repository unless explicitly authorized.

In particular do not create `.kilo/` during ordinary repository work.

Project instructions live in root `AGENTS.md`.

## 36. PowerShell / Windows Execution

The environment is Windows and commands may execute through PowerShell.

Do not assume Bash syntax.

In particular:

- `&&` may not be valid in legacy Windows PowerShell.
- quote Git revision expressions such as `"@{u}"`.
- check `$LASTEXITCODE` when accurate native-process exit status matters.
- do not confuse PowerShell success with the exit code of the external tool.

Recover from shell-syntax errors by correcting the command.
Do not infer the intended output.

## 37. Tool Errors

A failed command is evidence of failure to execute, not evidence of the result
the command was intended to inspect.

If a command fails:

1. preserve the error,
2. determine whether syntax/environment caused it,
3. retry safely if allowed,
4. never fabricate the missing result.

## 38. Todo / Planning Discipline

For multi-step implementation, maintain a task list when supported.

A task checkbox represents actual completion, not intent.

Do not mark:

tests,
commit,
push,
remote lock,
production verification

complete until their evidence exists.

## 39. Stop Conditions

STOP instead of improvising when any of these occurs:

- unexpected tracked dirty state
- unexpected staged state
- unauthorized active Git operation
- remote divergence
- unauthorized file would need modification
- owner decision unresolved
- production mutation would be required without authorization
- secret exposure risk
- authority conflict cannot be resolved
- test contract cannot be determined
- requested action exceeds the current slice

State exactly what blocked continuation.

## 40. Final Report Integrity

Final reports must distinguish:

- actions actually executed,
- evidence actually observed,
- conclusions,
- unresolved items.

Never claim:

PASS
COMPLETE
CLOSED
REMOTE_LOCKED
DEPLOYED
AUTHORIZED

unless the applicable evidence contract has been satisfied.

## 41. Definition of Done

A change is done when:

- scope and architecture are preserved,
- behavior is verified with proportionate tests,
- analyzer/test/build evidence is exact,
- RTL, accessibility, security, persistence, performance, and platform risks
  relevant to the change are addressed,
- no unrelated files or operations were introduced,
- the agent stops at the authorized boundary.

## 42. No Autonomous Successor Work

After completing the authorized task:

STOP.

Do not automatically start the next roadmap item.

Do not interpret "continue" from an older governance document as current owner
authorization for a successor task.

## 43. Core Principle

When safety, governance, repository preservation, and speed conflict:

choose safety, governance, and preservation.

When evidence and assumption conflict:

choose evidence.

When scope and opportunity conflict:

choose scope.

When owner authorization is missing:

STOP.
