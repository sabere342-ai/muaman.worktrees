# PHASE P — POST WINDOWS DELIVERY
## PUBLICATION / HANDOFF — PLANNING

> PLANNING / GOVERNANCE ONLY — REMOTE LOCK.
>
> This session is the sole authorized successor of the committed
> `PHASE_P_POST_WINDOWS_DELIVERY_OWNER_SUCCESSOR_DECISION` result
> `PASS_POST_WINDOWS_DELIVERY_OWNER_SUCCESSOR_DECISION_REMOTE_LOCKED`.
>
> It defines HOW the already-accepted, already-delivered Windows artifact could
> be safely retained, identified, handed off, and — only after a separate
> explicit Owner authorization — published or distributed.
>
> This session performs NO publication, NO distribution, NO artifact upload, NO
> installer creation, NO Windows build, NO RC/ZIP regeneration, NO code signing,
> NO Android work, NO Production/Supabase work, and NO P-OD7 / Sync Drain work.
> It never moves, copies, renames, repackages, or deletes any existing artifact.
>
> This report contains NO passwords, NO DPAPI ciphertext, NO private key
> material, NO keystore bytes, NO Supabase secrets, NO service-role keys, NO
> access tokens, NO GitHub credentials.

---

## A. Session Result

```text
SESSION       = PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING
SESSION_CLASS = PLANNING_GOVERNANCE_ONLY

ROOT                  = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH                = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE     = github
AUTHORIZED_REMOTE_URL = https://github.com/sabere342-ai/muaman.worktrees.git
FORBIDDEN_REMOTE      = origin

RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING_REMOTE_LOCKED
```

The PASS means all of the following are true (each verified live this session):

```text
PLANNING_COMPLETE                = YES
PUBLICATION_EXECUTED             = NO
EXTERNAL_DISTRIBUTION_EXECUTED   = NO
ARTIFACT_UPLOADED                = NO
INSTALLER_CREATED                = NO
WINDOWS_REBUILT                  = NO
RC_REGENERATED                   = NO
ZIP_REGENERATED                  = NO
CODE_SIGNING_EXECUTED            = NO
ANDROID_EXECUTED                 = NO
PRODUCTION_EXECUTED              = NO
SUPABASE_MUTATION                = NO
P_OD7_ACTIVATED                  = NO
SYNC_DRAIN_ACTIVATED             = NO
ORIGIN_CONTACTED                 = NO
STASH_MODIFIED                   = NO
LEGACY_RESIDUE_CLEANED           = NO
SACRED_DELIVERY_ZIP_MODIFIED     = NO
HISTORY_REWRITTEN                = NO
FORCE_PUSHED                     = NO
REMOTE_LOCK                      = VERIFIED
```

---

## B. Repository Identity

Verified live from repository evidence (forensics, not trust of this prompt
alone):

```text
ROOT    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
GIT_DIR = C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze (linked worktree)
BRANCH  = codex/i-tech-next-roadmap-freeze
HEAD    = 223de62f99aacef80adad20b7b251f8e19010df6 (entry)
```

Remote configuration (read-only inspection of `git remote -v`):

```text
github  https://github.com/sabere342-ai/muaman.worktrees.git (fetch)
github  https://github.com/sabere342-ai/muaman.worktrees.git (push)
origin  C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن  (legacy/read-only; FORBIDDEN)
```

```text
REPOSITORY_IDENTITY_VERIFIED = TRUE
ORIGIN_CONTACTED             = NO
```

---

## C. AGENTS / Skills

AGENTS inventory:

```text
AGENTS_FILES_FOUND  =
  C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/AGENTS.md
  (single applicable AGENTS.md in the canonical working root; no nested
   AGENTS.md anywhere else in the repository)
AGENTS_FILES_APPLIED =
  C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/AGENTS.md
  (evidence-first; linked-worktree awareness; remote-lock contract; scope
   allowlist; commit/push discipline; PowerShell 5.1 execution rules; stop
   conditions; definition of done)
AGENTS_CONFLICTS    = NONE
```

Skill discovery in THIS runtime (available skill registry):

```text
SKILLS_DISCOVERED =
  customize-opencode, dart-add-unit-test, dart-collect-coverage, find-skills,
  flutter-accessibility, flutter-add-integration-test, flutter-add-widget-test,
  flutter-apply-architecture-best-practices, flutter-code-review,
  flutter-core-engineering, flutter-offline-data, flutter-performance,
  flutter-release, flutter-rtl-arabic, flutter-security, flutter-testing,
  flutter-ui-ux, frontend-design
```

Project skill directories `.agents/skills` and `.codex/skills` are ABSENT in the
repository; the runtime skill registry is the authoritative discovery source.
Neither directory was created.

```text
SKILLS_USED             =
  flutter-release (loaded via the runtime skill registry)
PRIMARY_SKILL           = flutter-release
SKILL_SCOPE_EXPANSION   = NONE
```

`flutter-security` was NOT loaded: this planning session only reasons about
Windows distribution compatibility, checksum identity, and signature STATUS (not
signature implementation), which the `flutter-release` skill and the release
evidence checklist cover. Loading `flutter-release` does NOT authorize release
creation, publishing, artifact upload, signing, production, Android, or remote
mutation outside the authorized documentation commit/push of this session.

```text
CONTACTED_AUTHORITY_BOUNDARY =
  The plan below is a recommendation only. Recommendation is NOT Owner approval.
```

No skill file was modified.

---

## D. Entry Classification

Global Git-operation metadata checked via Git-aware path resolution
(`git rev-parse --git-path` + existence probe):

```text
MERGE_HEAD       = ABSENT
CHERRY_PICK_HEAD = ABSENT
REVERT_HEAD      = ABSENT
BISECT_LOG       = ABSENT
rebase-merge     = ABSENT
rebase-apply     = ABSENT
index.lock       = ABSENT
ACTIVE_GIT_OPERATION = NONE
```

Index and tracking state:

```text
ENTRY_HEAD    = 223de62f99aacef80adad20b7b251f8e19010df6
INDEX_STATE   = EMPTY (git diff --cached --name-status = empty)
STASH         = PRESERVED
               (stash@{0}: WIP on
                codex/muaman-13-strict-july-workbook-data-migration:
                283ff9d MUAMAN-12: implement local user roles and sales-only access)
               NOT TOUCHED
```

Known pre-existing tracked working-tree residue (present on disk BEFORE this
session, NOT introduced by this session, PRESERVED UNTOUCHED) — the 12 tracked
deletions under the legacy data directories, identical to the residue already
documented and preserved by the committed predecessor sessions (`شهر7/`,
`قديم/`):

```text
12 tracked data files deleted on disk (legacy data directories):
  - شهر7/extract_sales.py
  - شهر7/شيت_ادارة_محل_مؤمن_مطور_حديث_شهر7.xlsx
  - قديم/.~lock.شيت_ادارة_محل_مؤمن_حديث_شهر7.xlsx#
  - قديم/تقرير_الإقفال_الشهري_مؤمن_شهر6.pdf
  - قديم/جرد_مخزون_معدل_نصف_شهري_محل_مؤمن.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_حديث.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_حديث_شهر7.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_شهر6.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_شهر7.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_متكامل_شهر7.xlsx
  - قديم/شيت_ادارة_محل_مؤمن_متكامل_محدث_شهر7.xlsx
  - قديم/مشتريات_من_23-5.xlsx
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
delivery/I-TECH-Delivery-v1.0.0.zip   (SACRED residue; preserved read-only)
supabase/.branches/
supabase/.temp/
```

```text
ENTRY_CLASSIFICATION =
CASE_C_UNEXPECTED_DIRTY
  (12 pre-existing tracked deletions in legacy data directories, preserved
   untouched; LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE,
   AHEAD = 0, BEHIND = 0, index empty, no active Git operation;
   known sacred residue preserved per predecessor evidence)
```

No fetch was run; direct GitHub verification used read-only `git ls-remote
github` (no Git metadata mutated).

```text
ORIGIN_CONTACTED = NO
```

---

## E. Entry Remote-Lock Proof

Network verification used `github` only (read-only `git ls-remote github
refs/heads/codex/i-tech-next-roadmap-freeze`).

```text
ENTRY_LOCAL_HEAD         = 223de62f99aacef80adad20b7b251f8e19010df6
ENTRY_TRACKING_HEAD      = 223de62f99aacef80adad20b7b251f8e19010df6
ENTRY_DIRECT_GITHUB_HEAD = 223de62f99aacef80adad20b7b251f8e19010df6
ENTRY_MERGE_BASE         = 223de62f99aacef80adad20b7b251f8e19010df6
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

The current canonical entry commit is the committed Owner successor decision
report:

```text
PREDECESSOR_COMMIT  = 223de62f99aacef80adad20b7b251f8e19010df6
PREDECESSOR_SUBJECT = docs: select successor after windows delivery
PREDECESSOR_ARTIFACT =
  PHASE_P_POST_WINDOWS_DELIVERY_OWNER_SUCCESSOR_DECISION.md
PREDECESSOR_PARENT  = 04b822de58724acbced381a460b47df4bda5a209
```

Verified from the committed report (live `git show`):

```text
RESULT_TOKEN =
PASS_POST_WINDOWS_DELIVERY_OWNER_SUCCESSOR_DECISION_REMOTE_LOCKED

OWNER_DECISION             = APPROVE
AUTHORIZED_SUCCESSOR_COUNT = 1
AUTHORIZED_SUCCESSOR       =
  PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING

IMPLEMENTATION_AUTHORIZED        = NO
PUBLICATION_AUTHORIZED           = NO
EXTERNAL_DISTRIBUTION_AUTHORIZED = NO
INSTALLER_AUTHORIZED             = NO
ANDROID_AUTHORIZED               = NO
PRODUCTION_AUTHORIZED            = NO
SUPABASE_MUTATION_AUTHORIZED     = NO
P_OD7_AUTHORIZED                 = NO
SYNC_DRAIN_AUTHORIZED            = NO
```

```text
PREDECESSOR_AUTHORITY_VERIFIED = TRUE
AUTHORIZED_SUCCESSOR_COUNT     = 1
AUTHORIZED_SUCCESSOR           =
  PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING
```

Interpretation: this session is authorized to PLAN the publication/handoff
model ONLY. It inherits NO execution authority of any kind.

---

## G. Accepted RC / Delivery ZIP Identity

Reference identities recorded from committed predecessor evidence (NOT
re-verified by rebuilding or repackaging; the RC and ZIP were NOT regenerated):

```text
ACCEPTED_RC  = RC-20260910-222845

RC committed identity (verified from committed evidence):
  RUN_ID      = PHASE-P-RELEASE-CANDIDATE-1 (docs/evidence/phase-p-rc/)
  FILE_COUNT  = 18
  TOTAL_BYTES = 37537520
  CROSSHASH   = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9
  EXE_SIZE    = 92672
  EXE_SHA256  = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7

WINDOWS_DELIVERY_ZIP (accepted execution artifact, NOT committed to git):
  FILENAME = muaman-windows-release.zip
  SIZE     = 16279806 bytes
  SHA256   = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
  SHASUMS  = muaman-windows-release.zip.sha256 (generated by packager)
  EXECUTABLE = muaman_store.exe  (92672 bytes;
                SHA256 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7)
  PARENT SESSION =
    PHASE_P_POST_GROUP_D_WINDOWS_DELIVERY_EXECUTION (RESULT_TOKEN = PASS, REMOTE_LOCKED)
```

Determinism (from predecessor execution evidence): two independent packaging
runs produced the identical ZIP

```text
ZIP_SHA256_RUN_1 = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
ZIP_SHA256_RUN_2 = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
IDENTICAL        = TRUE
```

Current physical location of the accepted delivery ZIP (from predecessor
execution evidence, verified to exist during that session only, OUTSIDE the
repository):

```text
ZIP_PATH =
  C:\Users\saber\AppData\Local\Temp\opencode\windows-delivery-execution\out\muaman-windows-release.zip
```

IMPORTANT: this planning session did NOT verify, move, copy, or touch the ZIP.
The ZIP lives in a TEMPORARY cache location; a durable retention location is a
planning outcome below (section O), NOT an action performed here.

---

## H. Sacred Artifact Boundary

The existing file `delivery/I-TECH-Delivery-v1.0.0.zip` is SACRED pre-existing
residue. Observed read-only this session:

```text
SACRED_DELIVERY_ZIP = delivery/I-TECH-Delivery-v1.0.0.zip
SACRED_SIZE         = 12668632 bytes
SACRED_SHA256       = 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
```

Rules (applied this session and PLANNED to remain):

```text
MODIFY     = NO
DELETE     = NO
REPLACE    = NO
REPACKAGE  = NO
RENAME     = NO
STAGE      = NO
COMMIT     = NO
UPLOAD     = NO
DISTRIBUTE = NO
```

The sacred legacy ZIP is a DIFFERENT artifact from the accepted Windows
delivery ZIP:

```text
DISTINCTION:
  sacred legacy ZIP:
    - path        delivery/I-TECH-Delivery-v1.0.0.zip
    - size        12668632
    - sha256      70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
    - name basis  I-TECH-Delivery v1.0.0 (historical)
    - git state   untracked residue (never staged/committed)

  accepted delivery ZIP:
    - filename    muaman-windows-release.zip
    - size        16279806
    - sha256      879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
    - RC basis    RC-20260910-222845 (18 files, 37537520 bytes)
    - git state   NOT tracked; resides outside repository in temp evidence dir
```

Any record that reports hashes, sizes, or version meaning MUST keep the two ZIP
files distinguishable by name AND by integrity values. The publish/handoff
identity (section I/M) applies ONLY to the accepted delivery ZIP, never to the
sacred legacy ZIP.

---

## I. Publication Objectives

The accepted delivery ZIP is an already-accepted, already-validated Windows
artifact. The objectives of any FUTURE authorized publication/handoff are:

```text
O1  durable retention                 - the artifact and its checksum record
                                        survive in an immutable canonical location;
O2  unambiguous identity              - any recipient can verify integrity with
                                        exact bytes/hashes, not trust alone;
O3  controlled handoff                - verified recipient receives a verified
                                        artifact with auditable evidence;
O4  safe update path                  - future versions supersede without silent
                                        replacement of released bytes;
O5  rollback/revocation capability    - a released version can be withdrawn
                                        without destroying forensic evidence;
O6  compliance with product privacy   - no public exposure unless Owner decides
                                        public distribution is appropriate.
```

None of these objectives is executed this session. They define the shape of a
future authorized execution session.

---

## J. Channel Decision Matrix

Evaluation of candidate distribution channels. All entries are PLANNING
recommendations; every choice that requires Owner judgment is marked
`OWNER_DECISION_REQUIRED = YES`.

### 1. GitHub Release

```text
privacy                 = repo-narrow unless set Public / attended by visibility
discoverability         = good for a technical audience
update experience       = release page + asset download; no auto-update today
auditability            = full (release identity, tag, asset hash, timestamps)
checksum presentation   = manual (release notes / asset list)
ability to revoke       = delete/promote superseding release possible
artifact retention      = durable, versioned, immutable per tag
customer usability      = poor for non-technical Arabic-speaking shops
authentication          = public or private depending on repo visibility
cost                    = free
operational complexity  = low
source visibility risk  = the repo ALSO contains proprietary governance and
                          legacy data references; a PUBLIC repo is NOT acceptable
                          unless the repository is private/restricted
binaries public?        = only if Owner explicitly chooses public exposure
RECOMMENDATION          = viable ONLY as a PRIVATE/restricted GitHub Release for
                          controlled download, NOT public at this stage
OWNER_DECISION_REQUIRED = YES (repo visibility + public-vs-private)
```

### 2. Private direct customer handoff

```text
privacy                 = highest (recipient-specific)
discoverability         = none
update experience       = manual (operator-mediated)
auditability            = requires a handoff evidence record (section P)
checksum presentation   = per-recipient verified handoff
ability to revoke       = high (operator stops further handoff, notifies)
artifact retention      = operator-controlled immutable archive
customer usability      = good for small shop count
authentication          = personal verification by operator
cost                    = low
operational complexity  = low-moderate (manual)
source visibility risk  = none
binaries public?        = no
RECOMMENDATION          = STRONG candidate for the current stage (few shops,
                          privacy-first, Arabic-first, unsigned binary)
OWNER_DECISION_REQUIRED = YES
```

### 3. Internal / private archive

```text
privacy                 = high
discoverability         = operator-only
update experience       = operator pulls, then hands off
auditability            = good with inventory record
checksum presentation   = internal manifest
ability to revoke       = archive keeps superseded immutably
artifact retention      = designed for indefinite retention
customer usability      = none (not customer-facing)
cost                    = low
operational complexity  = low
source visibility risk  = none
binaries public?        = no
RECOMMENDATION          = ADOPT as the durable canonical retention layer for ALL
                          releases, independent of the distribution channel
OWNER_DECISION_REQUIRED = YES (archive location policy)
```

### 4. Official website / download page

```text
privacy                 = low unless behind authentication
discoverability         = highest for customers
update experience       = download page versioning
auditability            = medium
checksum presentation   = page + checksum file
ability to revoke       = take page / link down
artifact retention      = host-managed
customer usability      = good
authentication          = usually none unless gated
cost                    = hosting cost
operational complexity  = moderate
source visibility risk  = if served from the same site as source: risk; otherwise low
binaries public?        = yes (public download)
RECOMMENDATION          = DEFER until signing/tamper and support model are
                          decided; NOT recommended for the current stage
OWNER_DECISION_REQUIRED = YES
```

### 5. Other controlled channel

```text
(e.g., gated OneDrive/Google Drive link, private FTP, or an app-store-style
private distribution service)

privacy                 = configurable
discoverability         = low
update experience       = link-based
auditability            = medium
checksum presentation   = manual
ability to revoke       = revoke shared link
artifact retention      = host-managed
customer usability      = medium
cost                    = low
operational complexity  = low-moderate
source visibility risk  = low (no source coupling)
binaries public?        = link is shareable; treat as private until Owner decides
RECOMMENDATION          = acceptable ONLY as an explicitly-authorized, access-
                          controlled interim channel after Owner approval
OWNER_DECISION_REQUIRED = YES
```

### Matrix conclusion

```text
RECOMMENDED_MODEL (planning recommendation only):
  Layer 1 - durable private artifact archive (immutable, checksum-recorded)
  Layer 2 - GitHub Release as PRIVATE/restricted only if Owner approves and the
            repository is not publicly exposed as a side effect
  Layer 3 - operator-mediated private customer handoff for actual shops
  Layer 4 - public download ONLY after: Owner decision, code-signing decision,
            privacy/security review, support contract, rollback plan

PRIMARY_RECOMMENDATION = PRIVATE controlled model (internal archive + private
                         customer handoff); public exposure DEFERRED.
```

---

## K. Public vs Private Recommendation

```text
PUBLIC_RECOMMENDATION_STATE = PRIVATE
(planning recommendation ONLY; does not create authority)

PUBLIC    = NO
PRIVATE   = RECOMMENDED (planning)
INTERNAL_ONLY = RECOMMENDED for the canonical archive (planning)
UNDECIDED_PENDING_OWNER = YES - Owner must decide public exposure explicitly
PUBLICATION_AUTHORITY   = NONE (no committed evidence authorizes public exposure)
NO_PUBLICATION_AUTHORITY = CONFIRMED
```

The current Windows build is product-mature but the distribution surface is
NOT public-ready without: (a) an Owner public-distribution decision, (b) a
code-signing decision, (c) a support/contact contract, (d) a privacy check of
anything placed where it can be read publicly. Until those exist, do NOT
publish.

```text
DEFAULT = NO PUBLICATION AUTHORITY
```

---

## L. Version Naming Plan

Verified application version from `app/pubspec.yaml`:

```text
PUBSpec_VERSION = 1.0.0+1
   semantic/product version = 1.0.0
   build number              = 1
```

Proposed canonical identity model (PLANNING; no metadata changed):

```text
PRODUCT_NAME               = I Tech لإدارة المحلات (I Tech Store Management)
PRODUCT_VERSION            = 1.0.0        (matches pubspec semantic version)
PRODUCT_BUILD              = 1            (matches pubspec build number)
INTERNAL_RC_IDENTITY       = RC-20260910-222845
IMMUTABLE_RELEASE_IDENTITY =
  v1.0.0 + build 1 + RC-20260910-222845 (three values bound to one release)
DELIVERY_FILENAME_IF_RENAMED =
  I-TECH-v1.0.0-b1-RC-20260910-222845-windows-release.zip
  (proposed; renaming requires a future authorized session)
```

Rules (planning):

```text
- v1.0.0 IS justified: it matches the committed pubspec semantic version 1.0.0.
- filename SHOULD carry version + RC so different artifacts cannot collide.
- immutable release identity = exact bytes (SHA-256) bound to version + RC;
  the hash, not the filename, is the ground truth.
- future updates increment PRODUCT_VERSION (1.0.1 ...) and/or build as defined
  by the Owner's future versioning decision; each released version gets its own
  RC identity and its own SHA-256 record.
- no file may be silently overwritten; a new version is a NEW file with a NEW
  identity.
- `pubspec.yaml` / `pubspec.lock` version changes require a separately
  authorized session. This session modifies no metadata.
```

```text
FILENAME_COLLISION_PREVENTION = YES (version+RC in future names)
IMMUTABLE_RELEASE_IDENTITY    = SHA-256 (ground truth)
```

---

## M. Checksum / Signature Plan

Values a recipient SHOULD verify against the accepted delivery ZIP:

```text
recipient-verifiable:
  ZIP FILENAME = muaman-windows-release.zip
  ZIP SHA-256  = 879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5
  ZIP SIZE     = 16279806 bytes
  EXE SHA-256  = 0CC48D2A47AE1F014A536A60A2FA4387405C8938C3A008E5395019177B4278E7
  EXE SIZE     = 92672 bytes

internal forensic (NOT typically recipient-level):
  RC CROSSHASH = 0051D0D60800F53F048320DB28AAE24161785FEF2E54A244C967464108A166B9
                 (deterministic hash across the 18-file release set)
  RC FILE_COUNT = 18
  RC TOTAL_BYTES = 37537520
```

Presentation contract (planning):

```text
- Publish the ZIP SHA-256, ZIP size, EXE SHA-256, and EXE size alongside any
  future authorized handoff; keep them in one immutable record.
- Label RC CROSSHASH and FILE_COUNT/TOTAL_BYTES as internal forensic release-set
  values for the engineering/ops record, not as a customer-facing checksum.
- Do NOT claim the artifact is digitally signed (see below); checksums assert
  byte integrity, NOT identity of the publisher.
- Each recipient instruction MUST include: how to compute SHA-256 on Windows
  (certutil / Get-FileHash equivalent) and what to do on mismatch (stop, do not
  run, report to the operator).
```

```text
CHECKSUMS_VERIFIED = YES (reference values already exist in committed evidence)
CODE_SIGNING_PRESENT = NO
```

---

## N. Windows Trust / SmartScreen Considerations

Code-signing status determination from repository evidence:

```text
SIGNING_STATUS = UNSIGNED
```

Evidence basis:

```text
- The canonical release pipeline (tools/release/build_windows_release.ps1 and
  packager tools/release/package_windows_release.ps1) contains NO code-signing
  step and NO certificate reference.
- The committed MUAMAN-13N final report explicitly states: "No installer, no
  code signing, no auto-update..." (docs/muaman-13n/MUAMAN-13N-FINAL-REPORT.md).
- No Authenticode/PFX/P12/signature evidence exists for the Windows application
  binary; the only Authenticode reference found is to the Inno Setup compiler
  authenticity, not the app.
```

No signature was executed or inspected beyond this textual evidence search.

Likely user-visible behavior for the unsigned accepted ZIP:

```text
- SmartScreen "Windows protected your PC" warning for the EXE, and/or
  "unknown publisher" in the Zone identifier flow / antivirus reputation gating.
- This is EXPECTED behavior for an unsigned Windows desktop binary.

PLANNED guidance (must not encourage unsafe behavior):
  - never instruct customers to disable SmartScreen or Defender;
  - never tell them to "ignore the warning";
  - future authorized handoff instructions: explain WHO published it, verify the
    SHA-256 BEFORE executing, keep the operator accountable;
  - prefer private pilot handoff (few shops, direct operator support) over public
    download while unsigned, so any warning is explainable and supported.
```

Future signing path (planning only):

```text
- Windows Authenticode certificate (EV or standard code-signing) with a private
  key held in a hardware-backed store;
- timestamping server tie;
- signing step inserted into the authorized release pipeline under a NEW release
  identity if bytes change (an accepted RC's bytes must not be mutated);
- publication should be blocked until the Owner decides on signing, because
  unsigned PUBLIC distribution materially raises trust friction and
  malware-reputation risk.
```

```text
SMARTScreen_Guidance = PRIVATE PILOT BEFORE PUBLIC WHILE UNSIGNED
PUBLICATION_BLOCKED_UNTIL_SIGNING_DECISION = PLANNING RECOMMENDATION
```

---

## O. Retention / Archive Policy

Planning policy (nothing moved/copied this session):

```text
CANONICAL_RETAINED_ARTIFACT = the accepted delivery ZIP
                              (muaman-windows-release.zip, SHA-256
                              879761AF3A8A081B44B6CF805336BE50D217AA7CD17D37E204E7BE9EDEDFF5C5)
STRATEGY:

1. IMMUTABLE archive location concept - a durable, non-temp, versioned archive
   directory OUTSIDE the repository (e.g. an operator-controlled secure store),
   where each release lives in its own folder named by release identity.
2. IMMUTABLE CHECKSUM RECORD - one record per release binding:
   filename, size, SHA-256, EXE SHA-256, RC id, product version, build,
   capturing timestamp, operator, source evidence commit.
3. DATE/VERSION METADATA - store the release identity + RC id, not just the
   filename, so history is traceable.
4. MULTIPLE HISTORICAL RELEASES - retain previous releases; do NOT overwrite;
   only add new versions.
5. ROLLBACK PRESERVATION - the archive keeps the exact bytes that shipped so a
   rollback equals re-issuing an already-stored, already-verified version.
6. WHO MAY REPLACE - only a separately Owner-authorized operator may ADD a new
   release; no one may silently overwrite an existing release record.
7. NO SILENT OVERWRITE - if the same name would be reused, a new version gets a
   new identity; discrepancies are reported, never silently reconciled.
```

Current gap documented (NOT fixed this session):

```text
The accepted delivery ZIP currently resides ONLY in a temporary packager cache
(C:\Users\saber\AppData\Local\Temp\opencode\windows-delivery-execution\out\).
No durable archive copy exists yet. Establishing the durable archive + checksum
record is the FIRST actuator item of a future authorized execution session.
```

```text
RETENTION_OWNER_DECISION_REQUIRED = YES (archive location + retention horizon +
                                      backup/offline-copy policy)
```

---

## P. Handoff Evidence Contract

Design of the evidence required by a FUTURE authorized handoff session (this
session records no recipient/handoff data because NO handoff occurred):

```text
HANDOFF_EVIDENCE_REQUIRED_FIELDS:
  artifact filename      = exact name provided to recipient
  artifact SHA-256       = exact ZIP hash verified at handoff
  artifact size          = exact bytes
  release/version        = product version + build (+ RC identity)
  recipient/channel      = recipient identifier + channel (private link/email/
                           archive path) - only what the Owner authorizes
  handoff timestamp      = UTC timestamp
  operator               = the human/agent acting on Owner authority
  verification result    = PASS/FAIL of identity verification performed at
                           handoff (hash recalculated, not trusted)
  rollback reference     = pointer to the retained immutable previous version
                           that can be re-issued if this handoff is withdrawn
  authorization commit   = the commit carrying the Owner's explicit
                           publication/handoff authorization
```

As of this session:

```text
ACTUAL_HANDOFF_COUNT      = 0
RECIPIENT_DATA_RECORDED   = NONE (no nonexistent data invented)
HANDOFF_EVIDENCE_EMITTED  = YES (the contract above, ready for future use)
```

The same field set should be used to UPDATE the immutable checksum record when a
new release supersedes an existing one (marking the old one as superseded, never
deleting it).

---

## Q. Rollback / Revocation Plan

Planning only; NO rollback is authorized or executed:

```text
IF THE ACCEPTED RELEASE MUST BE WITHDRAWN:

1. STOP further handoff         - operator halts any link sharing / email /
                                  distribution immediately.
2. REVOKE DOWNLOAD LINK         - remove/disable the channel access, keep the
                                  archive copy intact.
3. PRESERVE FORENSIC ARCHIVE    - the released bytes and checksum record are
                                  retained unchanged; they are evidence.
4. PUBLISH CORRECTED IDENTITY   - if bytes are wrong (not merely version-super-
                                  seded): issue a NEW identity/checksum record;
                                  NEVER silently replace or correct the old
                                  record. Mark old record 'withdrawn', keep it.
5. CUSTOMER NOTIFICATION        - notify affected recipients with the correct
                                  replacement identity and instructions.
6. SUPERSEDING BUILD            - ship the next RC under a new RC id + version;
                                  no reuse of the withdrawn name or RC id.
7. ROLLBACK ELIGIBILITY         - a rollback re-issues the last known-good
                                  version still present in the immutable archive.
8. LICENSE/BACKEND COMPATIBILITY - before authorizing rollback, confirm the
                                  retained version is compatible with the
                                  current licensing/backend behavior; rollback
                                  is not allowed to silently break tenant
                                  compatibility assumptions.
```

```text
ROLLBACK_EXECUTED        = NO
REVOCATION_EXECUTED      = NO
ROLLBACK_PLAN_DEFINED    = YES
ROLLBACK_OWNER_DECISION_REQUIRED = YES (any actual rollback)
```

---

## R. Publication Prerequisite Gate

Gate checklist for any FUTURE authorized publication/handoff:

```text
#   PREREQUISITE                                     CLASSIFICATION
1   Owner publication authorization                  UNSATISFIED (blocking)
2   Artifact identity verified (SHA-256/ZIP/EXE/RC)  SATISFIED
3   Checksum record established                       UNSATISFIED (needs durable archive session)
4   Version name approved                            OWNER_DECISION_REQUIRED
5   Distribution channel approved                    OWNER_DECISION_REQUIRED
6   Code-signing status understood                   SATISFIED (UNSIGNED; decision pending)
7   Privacy/security review of the channel           UNSATISFIED (must precede public)
8   Licensing compatibility confirmed                OWNER_DECISION_REQUIRED
9   Support/contact instructions defined              UNSATISFIED
10  Rollback plan defined                            SATISFIED (this document, section Q)
11  Release notes ready                              UNSATISFIED
12  Recipient instructions (incl. SHA-256 verify)    UNSATISFIED
13  Immutable archive in place                       UNSATISFIED
14  Clear Git evidence state (remote-lock)            SATISFIED (at this checkpoint)
15  No accidental Android/Production coupling         SATISFIED (boundaries in section T)
```

Classification semantics:

```text
SATISFIED                 = already true from committed/live evidence
UNSATISFIED               = work in a future authorized execution session
OWNER_DECISION_REQUIRED   = Owner judgment gate, must be explicit
NOT_APPLICABLE            = not applicable to this release
```

Compulsory blocking gate summary:

```text
OWNER_PUBLICATION_AUTHORIZATION = REQUIRED (NOT held by this or any prior
                                  committed session)
```

---

## S. Security / Secret Boundary

This planning document contains NO secrets:

```text
PASSWORDS              = NONE
ACCESS_TOKENS          = NONE
SUPABASE_SERVICE_ROLE  = NONE
SUPABASE_ANON_KEYS     = NONE (not needed for planning)
PRIVATE_KEYS           = NONE
ANDROID KEYSTORE BYTES = NONE
WINDOWS SIGNING KEYS   = NONE
DPAPI CIPHERTEXT       = NONE
GITHUB CREDENTIALS     = NONE
CUSTOMER SECRETS       = NONE
```

No secret-bearing file was read this session. No environment secret was printed.

---

## T. Explicit Non-Authorization Boundaries

```text
PUBLICATION_AUTHORIZED            = NO
EXTERNAL_DISTRIBUTION_AUTHORIZED  = NO
GITHUB_RELEASE_CREATED            = NO
ARTIFACT_UPLOADED                 = NO
ATTACHED_TO_RELEASE               = NO
EMAILED_OR_SHARED                 = NO
WEBSITE_PUBLISHED                 = NO
INSTALLER_CREATED (MSIX/MSI/SETUP) = NO
WINDOWS_REBUILT                   = NO
RC_REGENERATED                    = NO
ZIP_REGENERATED                   = NO
CODE_SIGNING_EXECUTED             = NO
ANDROID_BUILD                     = NO
ANDROID_SIGNING                   = NO
ANDROID_RELEASE                   = NO
PLAY_CONSOLE                      = NO
AAB                               = NO
APK                               = NO
PRODUCTION                        = NO
SUPABASE_MUTATION                 = NO
SQL_EXECUTION                     = NO
MIGRATION                         = NO
RLS_CHANGE                        = NO
AUTH_CHANGE                       = NO
EDGE_FUNCTION_DEPLOY              = NO
SECRETS_CHANGE                    = NO
LICENSING_MUTATION                = NO
P_OD7                             = NO
SYNC_DRAIN                        = NO
ACTIVATION                        = NO
```

No action above was performed or will be performed by this session.

---

## U. Owner Decisions Still Required

Even though THIS plan recommends a private-controlled model, the following must
be decided explicitly by the Owner before any execution:

```text
DECISION 1 - PUBLIC vs PRIVATE vs INTERNAL_ONLY staging for the accepted build.
DECISION 2 - channel approval: which channel(s) may be used
             (private archive / private GitHub Release / customer handoff /
              website / other).
DECISION 3 - version naming approval (incl. whether to rename future delivery
             artifacts to embed version+RC).
DECISION 4 - code-signing direction (proceed unsigned privately, or authorize a
             signing workstream with certificate acquisition).
DECISION 5 - durable archive location + retention horizon.
DECISION 6 - whether public distribution is blocked until signing is resolved.
DECISION 7 - release notes / support / contact contract for recipients.
DECISION 8 - explicit authorization for the NEXT session (see section V).
```

```text
OWNER_DECISION_REQUIRED = YES (multiple, listed above)
```

---

## V. Future Successor Eligibility

No committed authority of any prior session names a successor beyond this
planning session. The productive next step (a durable-archive + checksum-record
execution session, or a publication/handoff execution session) is NOT authorized
by this document or by any existing committed authority.

```text
NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED   = YES
```

A future Owner decision will be needed EITHER to:

```text
(a) authorize an execution session that establishes the durable artifact
    archive + immutable checksum record (retention), and/or
(b) authorize a publication/handoff execution for an approved channel.
```

Neither may be inferred from the completeness of this plan.

---

## W. Files Changed / Allowlist

Exact repository mutation for this governance session — a single new planning
file:

```text
PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING.md (new, this file)
```

```text
ALLOWLIST_VERIFIED =
  git diff --cached --name-status == exactly the authorized planning file
  (verified immediately before commit)
```

No other tracked file was created, modified, staged, or committed. No generated
artifact, ZIP, manifest, run record, Windows binary, Supabase file, Android
file, test, script, release tool, CI, pubspec, lockfile, or signing config was
modified. Pre-existing residue was preserved unstaged.

---

## X. Validation

This is a governance/planning-only session. Validation chosen accordingly
(no expensive Flutter build/test ritual was run):

```text
VALIDATION_ITEMS:
  - repository identity / linked-worktree git-dir resolution   = PASS
  - entry HEAD / branch / tracking / merge-base equality        = PASS
  - direct github HEAD (ls-remote, read-only)                   = PASS
  - git-operation path absence (MERGE_HEAD ... index.lock)      = PASS
  - index empty                                                 = PASS
  - stash + legacy deletions + untracked residue preserved      = PASS
  - predecessor authority document verified (committed)          = PASS
  - predecessor windows delivery evidence verified (committed)   = PASS
  - RC / EXE / ZIP identity references verified from committed evidence = PASS
  - sacred ZIP size + SHA-256 re-observed read-only              = PASS
  - planning file absence confirmed before creation              = PASS
  - allowlist diff validated before commit                       = PASS
  - content review of the planning file                          = PASS
```

```text
VALIDATION_RESULT = PASS (governance-only)
```

---

## Y. Commit / Push / Remote-Lock

```text
COMMIT_SUBJECT  = docs: plan windows publication handoff
STAGING         = git add -- PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING.md
                  (explicit path only; no git add ., no git add -A)
AMEND_REBASE_SQUASH_RESET_FORCE = NO

PUSH_DEST       = github (branch codex/i-tech-next-roadmap-freeze)
PUSH_TYPE       = normal fast-forward push only
ORIGIN_CONTACTED = NO
```

Final Remote-Lock is proven in section Z/report after push:

```text
FINAL_LOCAL_HEAD
FINAL_TRACKING_HEAD
FINAL_DIRECT_GITHUB_HEAD
FINAL_MERGE_BASE
=> must all be equal; FINAL_AHEAD = 0; FINAL_BEHIND = 0
```

---

## Z. Mandatory STOP / Exact Result Token

After the planning file is committed, pushed normally to `github`, and final
Remote-Lock is proven, this session STOPS.

```text
PLANNING_COMPLETE            = YES
PUBLICATION_EXECUTED         = NO
EXTERNAL_DISTRIBUTION_EXECUTED = NO
ARTIFACT_UPLOADED            = NO
INSTALLER_CREATED            = NO
WINDOWS_REBUILT              = NO
RC_REGENERATED               = NO
ZIP_REGENERATED              = NO
CODE_SIGNING_EXECUTED        = NO
ANDROID_EXECUTED             = NO
PRODUCTION_EXECUTED          = NO
SUPABASE_MUTATION            = NO
P_OD7_ACTIVATED              = NO
SYNC_DRAIN_ACTIVATED         = NO

NEXT_AUTHORIZED_SUCCESSOR = NONE
OWNER_DECISION_REQUIRED   = YES
SESSION_STOPPED           = YES
REMOTE_LOCK               = VERIFIED (after push, section Y)
```

```text
RESULT_TOKEN =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_PUBLICATION_HANDOFF_PLANNING_REMOTE_LOCKED
```