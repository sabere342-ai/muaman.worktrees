# POST_PHASE_P_FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION_REPORT

## A. Session Identity

```text
SESSION = FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION
SESSION_TYPE = GOVERNANCE / BACKUP-GENERATION EVIDENCE CORRECTION ONLY
GOVERNING_LAW = POST_PHASE_P_FREE_PLAN_BACKUP_GOVERNANCE_CORRECTION.md (§H, §I, §J, §K, §P)
              + POST_PHASE_P_FREE_PLAN_BACKUP_GENERATION_REPORT.md (superseded in part)
MODEL = OWNER_MANAGED_LOGICAL_BACKUP_AND_VERIFIED_RESTORE
```

This artifact is an **additive governance correction** that supersedes the backup
artifact evidence recorded in `POST_PHASE_P_FREE_PLAN_BACKUP_GENERATION_REPORT.md`.
It truthfully corrects the governance record to reflect the NEW official production
backup generated through:

- Docker Desktop (operational)
- Supabase CLI 2.115.0
- `supabase db dump --linked` official CLI commands

This session does NOT:

- perform a restore
- deploy Migration 29 or Migration 30
- activate drain
- start Group B / C / D
- mutate production in any way
- push to any remote
- create any tag
- regenerate any backup

---

## B. Entry / Recovery Classification

```text
CASE = CASE_A_FRESH_GOVERNANCE_CONTINUATION
ENTRY_LOCAL_HEAD  = 45a1db97a0b7ba780bcfb81991dd9ba7134bc797
ENTRY_REMOTE_HEAD = 82ea5f434794bdab33e4a3cdd134da7e8a361601
MERGE_BASE        = 82ea5f434794bdab33e4a3cdd134da7e8a361601
AHEAD = 1
BEHIND = 0
TRACKED = CLEAN
INDEX = CLEAN
UNTRACKED = sacred artifacts only (see §E)
AUTHORIZED_REMOTE = github (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (READ-ONLY / UNAUTHORIZED — NOT CONTACTED)
```

At entry the sole ahead commit is:

```text
45a1db9 Record Free-plan production backup generation
```

This commit recorded the previous manual/pg_dump fallback backup evidence. It is
preserved as historical evidence and is NOT rewritten or amended. The correction
supersedes its governed backup artifact set, not the commit itself.

`git fetch github` was performed and confirmed the authorized GitHub branch was
up to date at the entry remote HEAD (no drift).

---

## C. Reason Correction Was Required

The previous generation session (`POST_PHASE_P_FREE_PLAN_BACKUP_GENERATION_REPORT.md`,
commit `45a1db9`) produced its backup artifact set using **local pg_dump / pg_dumpall**
PostgreSQL 18.4 tools as a fallback because Docker was not installed at that time.

Since that session, Docker Desktop has been installed and made operational. The
official Supabase CLI `supabase db dump --linked` mechanism is now available and
has been used to produce the authoritative backup artifact set from the linked
production project. The official CLI mechanism wraps pg_dump with Supabase-specific
filtering (internal-schema exclusions, storage-vector exclusions) and is the
governing-law-preferred mechanism (§H of the governance correction).

Therefore the previous pg_dump-produced artifact set and its evidence commit must
NOT be remotely locked as the final governed backup generation evidence. This
correction truthfully records the official CLI-generated artifact set as the
authoritative backup-generation candidate.

---

## D. Docker / Supabase CLI / Production Project State

```text
DOCKER DESKTOP           = INSTALLED AND OPERATIONAL
DOCKER_CLIENT_VERSION    = 29.7.2
DOCKER_ENGINE_VERSION    = 29.7.2
DOCKER_PLATFORM          = Linux/amd64

SUPABASE CLI VERSION     = 2.115.0 (not upgraded during this session)

PRODUCTION_PROJECT_NAME  = i-tech-production
PRODUCTION_PROJECT_REF   = ckruxrgppxxeqspxmyyd
PRODUCTION_ORG           = tgqscrybhnbrkhnoyvxx
LINKED_CONFIRMATION      = supabase/.temp/linked-project.json (project_ref matches above)

STAGING_PROJECT_REF      = ldkttyljtolnwlipjimb (MUST NOT be confused with production)
STAGING_LINKED_STATUS    = NOT LINKED (production is linked)
```

---

## E. Sacred Hash Verification (PRE and POST)

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  expected: 3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07
  PRE:      3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07

SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
  expected: C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733
  PRE:      C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733

delivery/I-TECH-Delivery-v1.0.0.zip
  expected: 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
  PRE:      70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418

supabase/.temp/ (9 entries)
  status: untracked, unmodified, not staged — preserved
```

Result: **PASS** — all sacred artifact hashes match. No sacred artifact was changed
during this session.

---

## F. Official Supabase CLI Backup Artifact Set

All artifacts were generated from the linked production project using official
`supabase db dump --linked` CLI commands and written to the Owner-controlled
OFF-repository backup directory:

```text
BACKUP_DIRECTORY = C:\Users\saber\Backups\I-Tech-Store-Management\production\pre-migration-30\20260831_204142
```

This location is **outside** the repository tree and is NOT tracked by git.

### Official Generation Mechanism

```text
TOOL = Supabase CLI 2.115.0 via Docker Desktop
COMMANDS = supabase db dump --linked (official CLI mechanism)
```

The official CLI generation commands were:

```text
supabase db dump --linked --file <backupDir>\roles.sql --role-only
supabase db dump --linked --file <backupDir>\schema.sql
supabase db dump --linked --file <backupDir>\data.sql --use-copy --data-only -x "storage.buckets_vectors" -x "storage.vector_indexes"
supabase db dump --linked --file <backupDir>\history_schema.sql --schema supabase_migrations
supabase db dump --linked --file <backupDir>\history_data.sql --use-copy --data-only --schema supabase_migrations
```

### First Roles Dump Auth Failure + Successful Retry

The first official `roles.sql` dump attempt encountered:

```text
FATAL: (EAUTHQUERY) unsupported or invalid secret format
```

This transient authentication failure occurred after the Docker image was initially
pulled. A subsequent retry succeeded. Therefore: all final artifact-producing
Supabase CLI dump commands succeeded. The first transient failure is a known
Docker/CLI initialization artifact, not a data corruption or CLI defect.

### Official Artifact Metadata

| Artifact          | Size (bytes) | SHA-256                                                             | Verified |
|-------------------|-------------|-----------------------------------------------------------------------|----------|
| roles.sql         | 370         | 168A95A9C745AF5ED4679751F90419AC9DC434240A213B03E32A06D5664C2308      | PASS     |
| schema.sql        | 189824      | DE72E30C270114677F7AF8283B02E9254A2C8673FB004FAA9521C03C2B18EE08      | PASS     |
| data.sql          | 31689       | 46D32A0DB1AC977B51BA621A6F22DF65C0972961C44E6E361F444ED74D9945DE      | PASS     |
| history_schema.sql| 887         | 18B99FBBB3EC9FBB964BB255A56171329ACD99B6977ECE2ADDD89FDF5AA5105B      | PASS     |
| history_data.sql  | 171015      | 9A24D34B9BE9D77C1EDF21C8C81CAC47FD17975BB9C1DE7AB2BFCE90946F9DAC      | PASS     |

All five artifacts exist, are regular files, are non-empty, and SHA-256 values match
exactly. Sizes match exactly. The backup directory is outside the repository. None of
these files is staged or tracked by git.

No SQL contents are reproduced in this report. No business/customer/transaction data
is displayed.

---

## G. Supersession of Previous Manual Backup

```text
PREVIOUS_MANUAL_BACKUP_DIRECTORY = C:\Users\saber\Backups\I-Tech-Store-Management\production\pre-migration-30\20260831_173627
PREVIOUS_MANUAL_BACKUP_STATUS    = SUPERSEDED_AS_GOVERNED_MIGRATION_30_BACKUP_EVIDENCE

PREVIOUS_LOCAL_COMMIT            = 45a1db97a0b7ba780bcfb81991dd9ba7134bc797
PREVIOUS_LOCAL_COMMIT_STATUS     = PRESERVED_HISTORICAL_EVIDENCE / NOT_REMOTE_LOCKED_AS_FINAL_BACKUP_GENERATION

OFFICIAL_BACKUP_STATUS           = 20260831_204142 artifact set is the authoritative backup-generation candidate
```

The previous manual backup files at `20260831_173627` are NOT deleted. The previous
commit `45a1db9` is NOT rewritten. However, the governance record now clearly states
that the previous backup was a manual/pg_dump fallback produced when Docker was not
installed, and has been superseded as the governed migration-30 backup evidence by the
official Supabase CLI-generated artifact set.

The previous backup is NOT described as corrupted or invalid. Its issue is
governance/tooling provenance — it was produced via local pg_dump rather than the
official `supabase db dump --linked` CLI mechanism, which is now available.

---

## H. Acceptance Matrix Result

Governing law §P (CASE 1–20). This session completes the **part that belongs to
backup GENERATION**. Restore-proof CASES (9–19) belong to the later
`FREE_PLAN_BACKUP_RESTORE_PROOF` session and are marked PENDING here, NOT falsely
passed.

```text
CASE 1  roles dump created successfully                 = PASS (roles.sql, 370 bytes, non-empty)
CASE 2  schema dump created successfully                = PASS (schema.sql, 189824 bytes, non-empty)
CASE 3  data dump created successfully                  = PASS (data.sql, 31689 bytes, non-empty)
CASE 4  migration history captured                      = PASS (history_schema.sql + history_data.sql)
CASE 5  all backup artifacts non-empty where expected   = PASS (all 5 non-empty)
CASE 6  backup SHA-256 recorded for each artifact       = PASS (§F)
CASE 7  backup stored OUTSIDE tracked repo              = PASS (off-repository, §F)
CASE 8  no secret printed into governance/log artifact  = PASS (§I)
CASE 9  safe non-production recovery environment set up = PENDING (restore-proof session)
CASE 10 roles restore PASS                              = PENDING
CASE 11 schema restore PASS                             = PENDING
CASE 12 data restore PASS                               = PENDING
CASE 13 migration-history restore PASS                  = PENDING
CASE 14 critical row-count comparisons PASS             = PENDING
CASE 15 RLS/policies/RPCs exist after restore           = PENDING
CASE 16 shop_members + tenant isolation preserved       = PENDING
CASE 17 Migration 28/29 baseline recognizable           = PENDING
CASE 18 recovery environment destroyed/secured          = PENDING
CASE 19 production remains untouched during restore     = PENDING (this session: NO restore)
CASE 20 backup retention location confirmed             = PASS (Owner-controlled path, §F; retention boundary §J)
```

GENERATION GATES = COMPLETE (CASES 1–8, 20)
RESTORE-PROOF GATES = PENDING (CASES 9–19)

This report deliberately records the restore CASES as PENDING. Do NOT treat a nominal
dump as restore-proof; the restore-proof session MUST actually restore and verify
before Migration-30 deployment governance resumes.

---

## I. Secret Handling

```text
No database password / connection-string-with-password / service_role secret / JWT
  is recorded in this report or any tracked artifact.

A temporary CLI-generated credential appeared in interactive dry-run output.
It is intentionally not reproduced in governance evidence.

No secret value enters Git.
```

Result: **PASS**.

---

## J. Off-Repository Verification

```text
Backup dir        = C:\Users\saber\Backups\I-Tech-Store-Management\production\pre-migration-30\20260831_204142
Repo root         = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
Backup inside repo? = NO (verified by path containment check)
Backup .sql tracked in git? = NO (verified: only pre-existing supabase/migrations + seed/test SQL are tracked)
```

Result: **PASS** — the production backup artifact set is OFF-repository and untracked.

---

## K. Repository Evidence (Local Commit)

This session creates **exactly ONE** local governance evidence commit containing only
this file.

```text
File added      = POST_PHASE_P_FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION_REPORT.md
Commit subject  = Correct Free-plan backup generation to official Supabase CLI
Remote push     = NO (not performed)
Tag             = NO (not created)
```

The backup artifact set itself stays OFF-repository (§J).

---

## L. Prohibited Actions

```text
RESTORE_EXECUTED          = NO
PRODUCTION_SQL_EXECUTED   = NO
PRODUCTION_MUTATION       = NO
BACKUP_REGENERATED        = NO

MIGRATION_29_LIVE_PROBED  = NO
MIGRATION_30_DEPLOYED     = NO
DRAIN_ACTIVATED           = NO

GROUP_B_STARTED           = NO
GROUP_C_STARTED           = NO
GROUP_D_STARTED           = NO

RELEASE_BUILD             = NO
ANDROID_BUILD             = NO

TAG_CREATED               = NO
PUSH_OCCURRED             = NO

LEGACY_ORIGIN_CONTACTED   = NO
```

Only production READ operations, `git fetch github`, sacred hash verification, and
backup artifact hash verification were used.

---

## M. Restore-Proof State

```text
BACKUP_GENERATION        = OFFICIAL_CLI_ARTIFACT_SET_GENERATED
BACKUP_RESTORE_PROOF     = NOT_STARTED

GENERATION GATES         = COMPLETE (§H CASES 1–8, 20)
RESTORE-PROOF GATES      = PENDING (§H CASES 9–19 inclusive = 11 cases)

RESTORE_CASES_9_THROUGH_19 = 11 cases (NOT 12)
```

Do not falsely mark restore acceptance cases as PASS. Do not state `all 20 cases
pass` while restore cases are pending. The restore-proof session must actually
restore and verify before Migration-30 deployment governance resumes.

---

## N. Closure State

```text
SESSION                              = FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION
SESSION_RESULT                       = PASS (local ready — backup-generation evidence correction only)
RECOVERY_CLASSIFICATION              = CASE_A_FRESH_GOVERNANCE_CONTINUATION
MODEL                                = OWNER_MANAGED_LOGICAL_BACKUP_AND_VERIFIED_RESTORE
OFFICIAL_BACKUP_GENERATION           = COMPLETE
OFFICIAL_BACKUP_ARTIFACT_SET         = 20260831_204142
PREVIOUS_MANUAL_BACKUP               = SUPERSEDED_AS_GOVERNED_MIGRATION_30_BACKUP_EVIDENCE
BACKUP_RESTORE_PROOF                 = NOT_STARTED
GENERATION_GATES                     = COMPLETE
RESTORE_PROOF_GATES                  = PENDING
PRODUCTION_MUTATION                  = NO
RESTORE_EXECUTED                     = NO
MIGRATION_30_DEPLOYED                = NO
DRAIN_ACTIVATED                      = NO
PUSH_OCCURRED                        = NO
TAG_CREATED                          = NO
SACRED_HASHES                        = VERIFIED PRE (POST recorded after commit)
SECRET_DISCLOSURE                    = NONE
LOCAL_CLOSURE_TOKEN                  = PASS_FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION_LOCAL_READY
NEXT_AUTHORIZED_SESSION              = FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION_REMOTE_LOCK
```

---

## O. Next Authorized Session

```text
NEXT_AUTHORIZED_SESSION_1 = FREE_PLAN_BACKUP_GENERATION_OFFICIAL_CLI_CORRECTION_REMOTE_LOCK
NEXT_AUTHORIZED_SESSION_2 = FREE_PLAN_BACKUP_RESTORE_PROOF
```

This session does NOT start either. After the remote lock, the restore-proof
session must actually restore the official artifact set into a safe non-production
recovery environment and verify the CASE 9–19 pending gates before Migration-30
production deployment governance resumes.

**END OF ARTIFACT**
