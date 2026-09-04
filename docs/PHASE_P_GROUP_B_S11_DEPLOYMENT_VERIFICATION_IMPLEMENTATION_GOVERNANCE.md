# Phase P / Group B / S11 — Deployment & Verification — Implementation Governance

**Document purpose:** Freeze the exact implementation-governance contract for Group B **S11 — Deployment / Verification** against the production Supabase project. This is a **GOVERNANCE-ONLY** artifact. It authorizes **no** production mutation, **no** migration apply, **no** Edge Function deployment, **no** secret mutation, **no** S11 implementation, **no** S12, and **no** Group C/D. A governance remote-lock is **not** a deployment authorization. Governance readiness does **not** equal deployment authorization.

```text
AUTHORIZED_UNIT      = S11 — DEPLOYMENT / VERIFICATION IMPLEMENTATION GOVERNANCE (governance only)
AUTHORIZED_REMOTE    = github  (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_REMOTE        = origin  (C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن) — SACRED READ-ONLY, NEVER CONTACTED
LEGACY_ORIGIN_CONTACTED = NO
EXPECTED_SUCCESS_TOKEN =
  PASS_PHASE_P_GROUP_B_S11_DEPLOYMENT_VERIFICATION_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
```

---

## A. Session Identity

```text
SESSION             = PHASE_P_GROUP_B_S11_DEPLOYMENT_VERIFICATION_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK
SESSION_MODE        = GOVERNANCE_ONLY / FAIL_CLOSED / NO_PRODUCTION_MUTATION
REPOSITORY          = muaman_store
WORKTREE ROOT       = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH              = codex/i-tech-next-roadmap-freeze
AUTHORIZED REMOTE   = github (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY REMOTE       = origin (sacred legacy local path; NEVER contacted)
ENTRY HEAD SHA      = 21383b3b93902ddba1f030204d64b204b77a81f4
ENTRY CLASS         = CASE_A_FRESH
TRACKED WORKTREE    = CLEAN (only pre-existing untracked sacred evidence remains, untouched)
INDEX               = EMPTY
```

Sole tracked output of this session: exactly one new governance artifact

```text
docs/PHASE_P_GROUP_B_S11_DEPLOYMENT_VERIFICATION_IMPLEMENTATION_GOVERNANCE.md
```

---

## B. Entry / Recovery Classification

Classified at entry **before any write**: **CASE_A_FRESH**.

```text
HEAD            = 21383b3b93902ddba1f030204d64b204b77a81f4
TRACKING        = 21383b3b93902ddba1f030204d64b204b77a81f4
DIRECT_REMOTE   = 21383b3b93902ddba1f030204d64b204b77a81f4
MERGE_BASE      = 21383b3b93902ddba1f030204d64b204b77a81f4
AHEAD           = 0
BEHIND          = 0
TRACKED_WORKTREE= CLEAN
INDEX           = EMPTY
ACTIVE_MERGE/REBASE/CHERRY_PICK = NONE
```

No CASE_B / CASE_C / CASE_D / CASE_BLOCKED condition was present. No reset / clean / rebase /
amend / force-push was used or needed.

Pre-existing untracked sacred evidence (delivery archive, Group-A/OD7 reports,
`supabase/.branches/`, `supabase/.temp/`) was **preserved untouched** and was neither staged nor
modified nor normalized.

---

## C. Exact Entry Remote-Lock Proof

```text
LOCAL         = 21383b3b93902ddba1f030204d64b204b77a81f4
TRACKING      = 21383b3b93902ddba1f030204d64b204b77a81f4
DIRECT_REMOTE = 21383b3b93902ddba1f030204d64b204b77a81f4
MERGE_BASE    = 21383b3b93902ddba1f030204d64b204b77a81f4
AHEAD  = 0
BEHIND = 0
```

DIRECT_REMOTE obtained by `git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`
= `21383b3b93902ddba1f030204d64b204b77a81f4`. Fetch performed against `github` only. No command
contacted `origin`.

---

## D. Authority Chain

Verified locally and against the authorized GitHub remote before this write.

```text
S8 Governance      = 217615514cb83aba0a629e01e619e418094fd9ae
S8 Implementation  = 7460f915197db06309aff905be91c10b379b4ab4
S9 Governance      = 2295b5d7cfcc7f59111d0cbade35f56e66c88941
S9 Implementation  = 27946b4cb26b01b3877ed3293127d224270e1484
S10 Governance     = 81984982534018c18aeac770ee160ff1fd508405
S10 Implementation = 21383b3b93902ddba1f030204d64b204b77a81f4   (REQUIRED ENTRY HEAD)
```

Parent linkage verified:

```text
S8 impl (7460f91) parent = S8 gov (2176155)
S9 gov (2295b5d) parent = S8 impl (7460f91)
S9 impl (27946b4) parent = S9 gov (2295b5d)
S10 gov (8198498) parent = S9 impl (27946b4)
S10 impl (21383b3) parent = S10 gov (8198498)   ✓ (HEAD^ == 8198498..., verified)
```

S10 implementation subject (verified): `feat: implement Group B S10 test security convergence`.
S10 governance parent (verified): `81984982534018c18aeac770ee160ff1fd508405`.

Required immediate predecessor for this governance commit:

```text
S11_GOVERNANCE_PARENT = 21383b3b93902ddba1f030204d64b204b77a81f4
```

The authorized GitHub remote had **not** advanced beyond the expected S10 implementation SHA;
no substitution was performed.

Authority-owning treaty docs (committed, cited):

```text
PHASE_P_OWNER_GATED_GROUP_B_PLAN.md            (Group B plan; S11/S12 boundary)
docs/PHASE_P_GROUP_B_S10_TEST_SECURITY_CONVERGENCE_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S9_LEGACY_ED25519_RETIREMENT_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S8_TAMPER_CACHE_CLOCK_ENFORCEMENT_CONVERGENCE_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S6_PLATFORM_SECURE_DEVICE_IDENTITY_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE.md (+ correction)
docs/PHASE_P_GROUP_B_S3_REVOCATION_OFFLINE_GRACE_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S2_SERVER_ENTITLEMENT_QUOTA_AUTHORITY_IMPLEMENTATION_GOVERNANCE.md
docs/PHASE_P_GROUP_B_S1_SERVER_DATA_MODEL_FOUNDATION_IMPLEMENTATION_GOVERNANCE.md
POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md
OD7_ACTIVATION_ANDROID_FINAL_RELEASE_AND_IOS_READINESS_REPORT.md  (production baseline record)
```

---

## E. S10 Closure / Immutable Predecessor

S10 is **REMOTE_LOCKED** at `21383b3b93902ddba1f030204d64b204b77a81f4` and immutable.

S10 exact implementation delta (S10 Governance → S10 Implementation, verified):

```text
ADD  app/test/licensing/s10_group_b_test_security_convergence_test.dart   (+909 / -0)
```

S10 production delta (verified): `app/lib/**` = NONE, `supabase/**` = NONE, migration `00036` = ABSENT.

S10 test evidence — distinction (governance truth):

```text
COMMITTED/RECORDED EVIDENCE (frozen by S10 implementation):
  S10 targeted               = 31 pass
  S9 predecessor             = 20 pass
  S8 predecessor             = 41 pass
  selected security regression = 75 pass
  full licensing             = 267 pass
  full Dart regression       = 1755 pass
  flutter analyze            = 0 errors; 1 warning (pre-existing)
```

```text
RE-EXECUTED EVIDENCE (independently re-run THIS S11 governance session; no source changed):
  S10 targeted               = 31/31  PASS
  S9 predecessor             = 20/20  PASS
  S8 predecessor             = 41/41  PASS
  selected security regression = 75/75 PASS
  full licensing             = 267    PASS
  full Dart regression       = 1755   PASS
  flutter analyze            = 0 errors / 1 warning (pre-existing, out of scope)
```

The S11 governance session did **not** rewrite S10 tests. S10 is treated as closed and immutable.

**Note on floors:** S10 governance (pre-implementation) recorded licensing 236 / full Dart 1724.
The post-implementation floors are licensing **267** (= 236 + 31 S10 convergence tests) and full
Dart **1755** (= 1724 + 31). Both were independently re-executed and confirmed this session.

---

## F. S11 Official Purpose

From committed authority (`PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` §14 and predecessor governance):

```text
S10 = Test / security convergence        deps = all prior
S11 = Deployment / verification governance
      production migration + verification
      deps = S10 + remote-locked implementation
S12 = Group B closeout                    deps = S11
```

S11's official purpose is to **govern and later execute the production deployment and
verification of the already-committed Group B server authority** (migrations `00031..00035`,
Edge Functions `s6-device-pop` and corrected `invite-employee`), applying **only authorized
unapplied** database migrations, deploying **only required** Edge Functions, and verifying the
production server-authoritative security contracts. S11 is **not** a new feature-design slice.

```text
PREDECESSOR(S) = S1..S10 (all prior; S10 remote-locked)
SUCCESSOR      = S12 (Group B closeout) → separate Owner authorization, NOT this session
GROUP B CLOSEOUT / GROUP C / GROUP D = FORBIDDEN to S11
```

Because S11 is deployment/verification, the following are **hard-forbidden**:

```text
NEW_MIGRATION     = FORBIDDEN
MIGRATION_00036   = FORBIDDEN (unless an already-committed higher authority proves otherwise — none does)
```

---

## G. Repository Deployment Inventory

Derived from committed files and git history (not from memory). The entirety of Group B's
server-affecting surface was introduced by **S1..S6 implementation commits only**; S7/S8/S9/S10
implementation commits touched **zero** `supabase/**` files (verified by `git show --stat`).

### G.1 Postgres migrations (NEW / UNAPPLIED to production)

| Artifact | Owning slice | Type | Introduced by | Prod mutation? | Order | Idempotence | Evidence | Rollback |
|---|---|---|---|---|---|---|---|---|
| `20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql` (blob `2ab64366…`) | S1 | DDL additive (tables `plans`, `device_audit_log`; additive columns/indexes on `licenses`, `devices`, `invitations`; RLS enable on `plans`/`device_audit_log`) | `334d1ad44…` | YES (schema/data) | after 00030 | YES (`IF NOT EXISTS`) | pgTAP `s1_server_data_model_foundation.test.sql` | forward-fix |
| `20260820000032_phase_p_group_b_s2_server_entitlement_quota_authority.sql` (blob `5451fa26…`) | S2 | DDL+SQL function+trigger (SECURITY DEFINER; `s2_resolve_entitled_license`, `s2_enforce_user_quota`+trigger, `activate_device`, `verify_license_entitlement` rewrite, plan seed) | `85e43154…` | YES | after 00031 | idempotent constructs | pgTAP `s2_…test.sql` | forward-fix |
| `20260820000033_phase_p_group_b_s3_revocation_offline_grace_authority.sql` (blob `b60487110…`) | S3 | DDL + SECURITY DEFINER functions (`s3_revoke_license/device/membership`, `verify_license_entitlement`, `activate_device`, `register_device`, `idx_devices_installation_shop`) | `62af4469…` | YES | after 00032 | idempotent | pgTAP `s3_…test.sql` | forward-fix |
| `20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql` (blob `95f662dd0…`) | S4 | DDL + functions + RLS-adjacent + Edge-boundary (`device_challenges`, `device_assertions`, `s4_enforcement_config`, `s4_*`; hardened `register_device`/`accept_invitation`/`require_shop_permission`/`s4_create_invitation`/`s4_token_hash`; single-use/expiry challenge; Owner-only device mgmt) | `b8889bf5…` | YES | after 00033 | idempotent | pgTAP `s4_…test.sql` | forward-fix |
| `20260820000035_phase_p_group_b_s6_platform_secure_device_identity.sql` (blob `16f6d640b…`) | S6 | DDL + functions (`s6_enroll_public_key`, `s6_create_challenge`) — public-key enrollment + server-generated challenge | `69218da4…` | YES | after 00034 | idempotent | pgTAP `s6_…test.sql` | forward-fix |

### G.2 Edge Functions

| Function | Owning slice | Source commit | Deployment requirement | Env/secrets | Verification | Rollback/redeploy |
|---|---|---|---|---|---|---|
| `s6-device-pop` (blob `61b57d419…`) | S6 | `69218da4…` | **FIRST-TIME deploy** (NEW) | standard `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` (platform-injected) | Deno WebCrypto Ed25519 PoP; interop tests in `index_test.ts` / `index.test.ts`; s4_assert_request service-role call | redeploy previous / fix-forward |
| `invite-employee` (blob `24bd76864…`) | S4 (correction of pre-existing Phase-D fn) | `b8889bf5…` (originally `298f564…`, `a68a257…`) | **REDEPLOY (UPDATED)** pre-existing production function | standard `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` | Deno tests in `index.test.ts`; invitation security matrix | redeploy previous / fix-forward |

### G.3 Surface classification (deployment split)

```text
DATABASE DEPLOYMENT SURFACE   = migrations 00031, 00032, 00033, 00034, 00035 (Group B, NEW/UNAPPLIED)
EDGE FUNCTION DEPLOYMENT      = s6-device-pop (NEW); invite-employee (UPDATED → redeploy)
SECRET/CONFIG DEPENDENCIES    = standard Supabase runtime env vars only (SUPABASE_URL / *_SERVICE_ROLE_KEY / *_ANON_KEY), platform-injected; no custom secret introduced by Group B
TEST-ONLY SERVER FILES        = supabase/tests/s1..s6_*.test.sql, cloud_stock_adjustments.test.sql,
                                rls_shop_members_recursion.test.sql (NOT deployed; pgTAP/verification only)
CLIENT-ONLY FILES             = app/lib/** (NOT part of production DB/Edge deployment; released as app builds, out of S11 scope)
ALREADY-PRODUCTION SURFACES   = migrations 00000..00030 (Mig 30 = committed baseline), pre-existing auth/schema
NEW/UNAPPLIED SURFACES        = Group B: migrations 00031..00035 + s6-device-pop + invite-employee update
```

**Guard rail:** do NOT treat every `supabase/**` file as deployable. `supabase/tests/**` and
`supabase/config.toml` / `.temp/` are not database migrations and must not be pushed as migrations.
Only `supabase/functions/<name>/index.ts` are Edge Function deploy surfaces; only
`supabase/migrations/<name>.sql` are migration apply surfaces.

---

## H. Production Environment Identity Contract

These facts are derived from **committed governance evidence**; live read-only re-confirmation
was **not** possible this session (see §K).

```text
LINKED PROJECT REF  = ckruxrgppxxeqspxmyyd
PROJECT NAME (cfg)  = i-tech-store-dev  (linked identity; production project port)
RECORDED TARGET     = ckruxrgppxxeqspxmyyd / i-tech-production / West EU (Ireland) aws-1-eu-west-1
                      (from OD7_ACTIVATION_ANDROID_FINAL_RELEASE_AND_IOS_READINESS_REPORT.md)
PRODUCTION BASELINE = Migration 30 (20260820000030_phase_p_a4_cloud_stock_adjustments.sql) is the
                      committed-to-production baseline (OD7 report: no 0031 exists in production).
```

The future S11 implementation MUST **positively re-verify** the production project identity and
environment before any mutation (Gates 6/7). Governance never assumes the linked local project
ref is the production project; it is verified at run time.

---

## I. Database Migration Deployment Boundary

### I.1 Migration 00036 freeze

```text
NEW_MIGRATION   = FORBIDDEN
MIGRATION_00036 = FORBIDDEN
```

If a genuine schema defect requiring a new migration is discovered at deployment time, the
future S11 implementation MUST NOT create it; it MUST mark S11 **BLOCKED**, document the defect,
identify the exact predecessor contract violated, and return to Owner-governed remediation. No
such defect is known/committed today.

### I.2 Reconciliation method (first fail-closed discovery gate of S11 implementation)

The future session MUST first compare the local migration inventory against the **live**
production migration history and derive, explicitly and evidence-backed:

```text
LOCAL MIGRATION INVENTORY   (all committed migrations present, 00000..00035)
PRODUCTION MIGRATION HISTORY (live read: applied versions)
UNAPPLIED_EXPECTED           (expected: 00031..00035 Group B; anything else is drift)
ALREADY_APPLIED_EXPECTED     (expected: 00000..00030)
UNEXPECTED_REMOTE            (foreign migration on production not in local set)
UNEXPECTED_LOCAL             (local migration not known to production when production has moved ahead)
ORDER_GAPS
DRIFT
```

Production is expected to have exactly migrations up to and including `00030` applied, and the
Group B set `00031..00035` **unapplied**. Any unexplained drift, foreign migration, order gap, or
partial state MUST **BLOCK** deployment with no partial mutation.

### I.3 Eligible migration mechanism + versions

The **only** eligible migration mechanism is the standard Supabase CLI migration apply
(`supabase db push` / `supabase migration up` against the linked project) applied exactly in the
committed numeric order, **only** for the expected unapplied Group B set, and **only** those born
from the committed local migration files (blobs verified in §G.1). No local creation, edit, or
rewrite of any migration is allowed in S11.

---

## J. Edge Function Deployment Boundary

Deploy **only** the two enumerated functions; do not deploy every function indiscriminately.

```text
FUNCTION_NAME        = s6-device-pop
OWNING SLICE         = S6
SOURCE COMMIT        = 69218da499ed004f5dc378c6d378add574c592b4
DEPLOYMENT           = FIRST-TIME (deploy once; idempotent redeploy)
REQUIRED CONFIG      = SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (standard, platform-injected)
VERIFICATION         = Deno WebCrypto Ed25519 PoP accept/reject; single-use/expiry; s4_assert_request
                       service-role call; interop tests
ROLLBACK             = redeploy previous verifier / fix-forward
```

```text
FUNCTION_NAME        = invite-employee
OWNING SLICE         = S4 (corrected pre-existing Phase-D function)
SOURCE COMMIT        = b8889bf59d65037915fcec618f06fc1c1a49ae40 (correction)
DEPLOYMENT           = REDEPLOY (updated existing production function)
REQUIRED CONFIG      = SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (standard)
VERIFICATION         = Deno tests (index.test.ts); invitation security matrix (single-use, expiry, binding)
ROLLBACK             = redeploy previous / fix-forward
```

**Device-gate activation boundary (crucial):** S6/S4 governance froze
`DEVICE_GATE_ENABLED = FALSE` and `REQUEST_BOUND_LIVE_ENFORCEMENT_READY = NO`. Deploying the
migrations and the `s6-device-pop`/`invite-employee` functions does **NOT** authorize flipping
`device_gate_enabled` to `true` via `s4_set_device_gate_enforcement(true)`. Live business-data
device-gate activation requires separately proven request-bound enforcement and a separate Owner
authorization. S11 governance does **not** enable live gate enforcement.

---

## K. Secrets / Configuration Boundary

```text
secrets are NEVER committed;                                         FROZEN
existing production secret NAMES may be checked without revealing values;  ALLOWED (read-only)
secret VALUES never enter logs / governance docs / reports;          FROZEN
missing required secrets BLOCK deployment;                           FROZEN
no secret rotation unless separately authorized.                     FROZEN
```

No Group B Edge Function requires a custom secret beyond the standard Supabase runtime variables.
The future session verifies presence of `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
`SUPABASE_ANON_KEY` for the linked production project **by name only** (never value).

**Production-state inspection result this session:**

```text
PRODUCTION_STATE_INSPECTION = INFRASTRUCTURE_BLOCKED
```

No live read-only connection to the production Supabase project was established this session:
this is a governance-only session and, consistent with predecessor governance (S1..S10 all record
`INFRASTRUCTURE_BLOCKED` for live server access, with no positively-safe authenticated read-only
path demonstrated), the conservative fail-closed decision is to **not** emit any live command that
could risk mutation or secret exposure. Therefore production-state discovery is encoded as the
**first fail-closed gate (Phase 1) of the future S11 implementation**. No production fact herein is
fabricated; the committed production baseline (Mig 30) and linked project identity are recorded
evidence only and must be live-re-verified before mutation.

---

## L. Backup / Recovery Contract

Grounded in committed Phase P deployment governance and Free-plan constraints. **No
enterprise-only mechanism is invented.** The project is governed by Supabase **Free-plan**
constraints (per OD7 production preflight), so acceptable recovery evidence is bounded to what
Free plan offers.

```text
ACCEPTABLE PRE-DEPLOYMENT BACKUP/EVidence:
  - full read-only capture of current production migration history and schema invariants
    (migration ledger, table/function/RLS existence) before the first mutation
  - deterministic, documented pre-image of each migration's effect where feasible
HOW CURRENT PRODUCTION STATE IS PRESERVED:
  - Supabase Free plan does not allow user-premise physical backups; the committed local
    migration inventory 00000..00030 + Group B 00031..00035 IS the canonical replayable source of truth
WHERE LOCAL BACKUP EVIDENCE MAY RESIDE:
  - in the working tree as untracked local evidence (NEVER committed if sensitive); or in
    C:\Users\saber\AppData\Local\Temp\opencode for non-repo scratch
SACRED ARTIFACTS:
  - any captured DB dump/secret-adjacent evidence is SACRED and must NOT be committed
WHICH RESTORE PROOF ALREADY EXISTS:
  - OD7/MUAMAN reproducibility reports demonstrate clean-stack replay of committed migrations
    (00000..00030 baseline); Group B migrations are additive and idempotent, ruled replayable
WHAT MUST BE REVALIDATED BEFORE S11 DEPLOYMENT:
  - clean replay of 00000..00035 on a private stack; migration order; idempotency; invariant suite
```

### L.1 Recovery strategy decision for additive Group B migrations

Group B migrations are **additive-only** (DDL + additive columns/new tables, `IF NOT EXISTS`,
idempotent). Accordingly, the authorized recovery strategy is:

```text
ROLLBACK BY DATABASE RESTORE      = Free-plan bounded (local replay + re-apply; no enterprise restore tooling invented)
FORWARD FIX                        = PRIMARY (a defect discovered post-apply is corrected by a future additive,
                                     separately-governed corrective migration — NEVER created in S11)
REDEPLOY PREVIOUS EDGE FUNCTION    = rollback path for Edge Functions
```

Governance does **not** claim reversible SQL DDL. For the additive Group B migrations the frozen
default is **forward-fix**, with restore-by-replay as the bounded Free-plan fallback. The future
S11 implementation must NOT create a compensating/rollback migration during deployment.

---

## M. Pre-Deployment Gates (mandatory for future S11 implementation)

The future S11 implementation MUST pass ALL gates below **before the first production mutation**.
If any fails: NO PRODUCTION MUTATION, NO PARTIAL DEPLOYMENT, STOP AND REPORT BLOCKED.

```text
GATE 1   correct repository/worktree/branch
GATE 2   HEAD exactly the S11 governance remote-lock commit (this artifact's commit SHA)
GATE 3   local == tracking == direct github remote
GATE 4   tracked worktree clean / index empty
GATE 5   legacy origin untouched (NEVER contacted)
GATE 6   production Supabase project identity positively verified (live read-only)
GATE 7   expected project/environment positively verified as PRODUCTION (not a dev/test project)
GATE 8   local migration inventory frozen (00000..00035, all blobs verified)
GATE 9   remote migration history captured
GATE 10  no unexplained drift / gaps / foreign migrations
GATE 11  deployment order deterministic (00031→032→033→034→035; Edge after DB)
GATE 12  backup/recovery prerequisite satisfied (§L)
GATE 13  required Edge Function secret/config NAMES present
GATE 14  security test baseline healthy (§Q floors)
GATE 15  no migration 00036
GATE 16  no unrelated repository delta
```

---

## N. Exact Deployment Runbook (future S11 implementation)

```text
PHASE 0   Entry remote-lock + environment identity (Gates 1-3)
PHASE 1   Production state read-only discovery (Gate 6,7,9,10) — FIRST FAIL-CLOSED GATE
PHASE 2   Backup/recovery gate (§L; Gate 8,12)
PHASE 3   Local/server migration reconciliation (Gate 8,9,10,11)
PHASE 4   Local test/security baseline (§Q; Gate 14)
PHASE 5   Apply ONLY authorized unapplied DB migrations 00031..00035 (Gate 15,16)
PHASE 6   Verify migration ledger immediately (all 5 applied; no drift)
PHASE 7   Verify schema/RLS/RPC invariants (table/function/trigger existence; device_challenges/
          device_assertions/s4_* / s6_* / s2_* / s3_* present; RLS intact)
PHASE 8   Deploy ONLY required Group B Edge Functions (s6-device-pop first-time; invite-employee redeploy)
PHASE 9   Verify function deployment/config (names present; no secret values)
PHASE 10  Run production-safe verification matrix (§O — READ_ONLY / SAFE fixtures only)
PHASE 11  Re-run client/server regression evidence where applicable (local, non-production)
PHASE 12  Capture forensic evidence (no PII/secrets)
PHASE 13  Commit allowed S11 evidence artifact(s) ONLY (allowed delta per §R)
PHASE 14  Normal fast-forward push to github
PHASE 15  Remote-lock proof
PHASE 16  STOP before S12
```

This order is determined by the actual dependency graph (DB migrations before Edge Functions that
depend on schema; verification after mutation; evidence after verification).

---

## O. Production Verification Matrix (post-deploy, production-safe)

Governance defines explicit post-deploy checks, NOT a bare "smoke test". Every check is
classified per §P.

### Entitlement
- plan/tier authority (plans table present; tier-derived user/device limits)
- trial/paid/perpetual behavior (server `verify_license_entitlement` returns correct status)
- server-authoritative entitlement resolution
- quota outputs (user quota trigger; device capacity)
- expiry handling
- revoked/suspended behavior override cached/stale entitlement

### Tenant isolation
- Shop A cannot read/write Shop B
- RLS remains effective after migration
- direct RPC/API paths do not bypass tenant/device authorization

### Device trust
- pending device
- approved device
- rejected device
- revoked device
- lost device
- terminal state behavior
- device quota

### Invitation
- valid invitation
- expired invitation
- replay/single-use rejection
- cross-shop mismatch rejection
- token/hash integrity (hashed, never plaintext)

### S6 secure identity / PoP
- public-key enrollment contract (s6_enroll_public_key single binding, canonicalized)
- challenge creation (s6_create_challenge server-generated nonce/expiry)
- valid proof accepted (via s6-device-pop Deno verifier)
- invalid signature rejected
- wrong key rejected
- replay/challenge misuse rejected (single-use, expiry, bound fields)

### Offline / revocation boundary
Production-side authority needed by client:

```text
Trial      = 0 day offline grace
Paid       = 7 days
Perpetual  = 14 days (compatibility-only)
```
and verify revoked/non-entitled state **cannot** be converted into offline entitlement
(server returns non-entitled; `isCachedNonEntitled` honored; REVOKED overrides grace).

### S8/S9 preservation
Deployment must not regress:
- S8 cache integrity authority assumptions (client-side; regression re-run)
- trusted server time contract (server_time authoritative; anti-rollback)
- revocation precedence
- S9 legacy Ed25519 retirement (no re-introduction; client-side static + regression)

---

## P. Safe Verification / Fixture Rules

Every future production verification is classified as one of:

```text
READ_ONLY                     = allowed
SAFE_TRANSACTIONAL_TEST       = allowed only if isolated fixture + deterministic cleanup
MUTATING_WITH_EXPLICIT_FIXTURE= allowed ONLY in a deliberately isolated verification tenant/fixture
                                if existing authority permits; deterministic cleanup required
NOT_SAFE_FOR_PRODUCTION       = forbidden (destructive tests against real customer data)
```

Rules (frozen):
- No destructive tests against real customer/shop records.
- No repurposing real production customer data.
- If mutation is required, use a deliberately isolated verification tenant/fixture ONLY if existing
  committed authority permits it; define deterministic cleanup.
- Never weaken RLS.
- Never use service-role access to "prove" normal-user authorization.
- Preserve forensic evidence without leaking PII/secrets.

Because no safe production mutation fixture is committed, governance requires the future session
to prefer: **non-production server regression evidence + read-only production invariant
verification**; dangerous production writes must not be substituted for proof. Request-bound
device-gate enforcement stays OFF (§J; not enabled).

---

## Q. Test & Static Security Gates

### Q.1 Test floors (frozen; re-executed and confirmed this session)

Future S11 implementation must keep the floors green (no reduction):

```text
S10 targeted                     >= 31  (RE-EXECUTED 31/31)
S9 predecessor                   >= 20  (RE-EXECUTED 20/20)
S8 predecessor                   >= 41  (RE-EXECUTED 41/41)
selected security regression     >= 75  (RE-EXECUTED 75/75)
full licensing                   >= 267 (RE-EXECUTED 267)
full Dart regression             >= 1755 (RE-EXECUTED 1755)
```

### Q.2 Committed server suites for Group B (pgTAP)

Committed and retained as evidence (execution requires a local Postgres/Supabase stack):

```text
supabase/tests/s1_server_data_model_foundation.test.sql
supabase/tests/s2_server_entitlement_quota_authority.test.sql
supabase/tests/s3_revocation_offline_grace_authority.test.sql
supabase/tests/s4_device_trust_server_gate_invitation_hardening.test.sql
supabase/tests/s6_platform_secure_device_identity.test.sql
```

Recorded pgTAP evidence (from S6 governance §V): S1=46, S2=88, S3=25, S4=50.

```text
LOCAL SERVER-SUITE EXECUTION = INFRASTRUCTURE_BLOCKED (no local Postgres/Supabase stack)
```

The later deployment environment MUST re-execute these server suites. No count is invented;
these are the recorded figures.

### Q.3 Edge Function / Deno tests

```text
supabase/functions/s6-device-pop/index_test.ts
supabase/functions/invite-employee/index.test.ts
(plus s6-device-pop interop / golden-vector tests)
```

### Q.4 Cross-language S6 PoP

Deno WebCrypto ↔ Dart Ed25519 interoperability and canonical golden-vector byte-equality are
covered by committed tests (S6 governance matrix #26-28); re-validation required in the deploy env.

### Q.5 Flutter Analyze

```text
errors        = 0  (FROZEN; re-confirmed 0)
new warnings  = 0  (FROZEN)
pre-existing warning .. app/lib/screens/settings/device_management_screen.dart:4:8
                         (unused import '../../models/user_role.dart') — unchanged, out of scope
```

New analyzer debt caused by S11 is forbidden.

---

## R. Expected S11 Implementation Delta

### R.1 S11_IMPLEMENTATION_ALLOWLIST

```text
EVIDENCE/DOC-ONLY repository delta (preferred model):
  - one S11 closeout/implementation evidence artifact that records the executed deployment,
    migration ledger, Edge deployment, verification matrix results, and forensic proof,
    following the repo naming convention (e.g., docs/PHASE_P_GROUP_B_S11_..._EXECUTION_REPORT.md)
  - NO Flutter production code change
  - NO Group B migration source edit
  - NO new migration, NO 00036
  - NO schema/RPC/RLS redesign
  - NO server source edit beyond what is strictly required to deploy already-committed artifacts
    (deployment does not rewrite migrations or functions)
```

### R.2 S11_IMPLEMENTATION_DENYLIST

```text
feature implementation
Flutter production changes
client entitlement / security redesign
migration source edits
migration 00036
schema redesign / new table / new column
RLS weakening
Auth mutation
secret mutation / rotation
flipping device gate enforcement ON
creating compensating/rollback migration
touching app/lib/**, app/test/** (except S11 execution evidence under docs/, test-only if needed)
contacting origin
Group C / Group D / S12 start
```

The precise evidence filename must follow the repository `docs/PHASE_P_GROUP_B_...` convention and
be chosen only after confirming naming conventions at implementation time; it is **not** fabricated
in this governance artifact.

---

## S. Failure / Abort Conditions (future deployment)

Governance freezes a **no-mutation abort** on any of:

```text
WRONG_PRODUCTION_PROJECT
UNEXPECTED_REMOTE_MIGRATION
MISSING_EXPECTED_MIGRATION
MIGRATION_ORDER_GAP
SCHEMA_DRIFT
RLS_DRIFT
RPC_SIGNATURE_DRIFT
MISSING_REQUIRED_SECRET
BACKUP_GATE_FAILED
BASELINE_TEST_FAILURE
UNEXPECTED_REPO_DIFF
UNEXPECTED_BRANCH_MOVEMENT
REMOTE_DIVERGENCE
PRODUCTION_ALREADY_PARTIALLY_CHANGED
MIGRATION_00036_DISCOVERED
AUTHORITY_CONTRADICTION
```

Fail closed. Never "continue and fix later". Stop, report BLOCKED, and escalate to Owner.

---

## T. Rollback / Forward-Fix Decision Matrix

| Event | Strategy |
|---|---|
| Additive DB migration defect post-apply | FORWARD-FIX (future additive corrective migration, separately governed) |
| Migration partially applied | STOP; do not fabricate; reconcile ledger; no partial-mutation correction in S11 |
| Edge Function defect | REDEPLOY PREVIOUS EDGE FUNCTION |
| Live device-gate accidentally enabled | re-disable via governed `s4_set_device_gate_enforcement(false)` (service-role), documented |
| Revocation regression | FORWARD-FIX + verify precedence invariants |
| Secret exposure discovered | HARD STOP; report; do not print value |

Never create a compensating migration during S11 governance or implementation.

---

## U. Evidence Requirements

Future S11 implementation evidence must record, with clear COMMITTED vs RE-EXECUTED vs
LIVE-PRODUCTION distinction:
- exact entry remote-lock proof (LOCAL/TRACKING/DIRECT/MERGE_BASE/AHEAD/BEHIND)
- production project identity + environment confirmation (live read-only)
- full migration ledger before/after (applied = 00031..00035 expected; no 00036)
- Edge Function deployment confirmation per function
- production-safe verification matrix results with classification (§P)
- rollback/forward-fix posture exercised where applicable
- no secrets/PII in evidence; no secret values printed

---

## V. Explicit Non-Goals / Forbidden Scope

```text
NO production migration execution in S11 governance
NO supabase db push against production in governance
NO Edge Function deploy in governance
NO production secrets mutation
NO production Auth mutation
NO production PostgreSQL mutation
NO new migration / migration 00036
NO modification of app/lib/**, app/test/**
NO modification of supabase/** (governance: none; implementation: deploy-only for the two Edge functions)
NO Flutter production code change
NO server code change (governance)
NO S11 implementation start (governance = contract only)
NO S12 start / no Group B closeout declaration
NO Group C / Group D
NO branch change / merge / rebase / amend / reset / force-push
NO legacy origin contact
NO enabling of live device-gate enforcement
```

---

## W. S12 Boundary

```text
S11 = deployment + verification governance/execution lifecycle
S12 = Group B final acceptance / closeout (separate, later, deps S11)
```

This governance session does **not** create an S12 artifact, does not declare Group B fully closed,
and does not authorize Group C/D or a successor roadmap. Even after successful S11 governance:

```text
NEXT = separate Owner authorization for S11 implementation
```

not S12.

---

## X. Commit / Push / Remote-Lock Contract

Governance commit (this session):
- stage only `docs/PHASE_P_GROUP_B_S11_DEPLOYMENT_VERIFICATION_IMPLEMENTATION_GOVERNANCE.md`
- normal commit, subject: `docs: govern Group B S11 deployment verification`
- no amend / squash / rebase / extra commit
- parent must be `21383b3b93902ddba1f030204d64b204b77a81f4`

Push (this session):
- normal fast-forward push **only** to `github` / `codex/i-tech-next-roadmap-freeze`
- no `--force`, no `--force-with-lease`, never to `origin`
- if rejected because remote advanced: STOP, reclassify, report

Post-push remote lock must satisfy:
```text
LOCAL == TRACKING == DIRECT_REMOTE == MERGE_BASE == S11_GOV_SHA; AHEAD=0; BEHIND=0
```
and commit delta = exactly one governance artifact (no app/lib/**, no app/test/**, no supabase/**,
no migration, no production implementation).

The future S11 **implementation** session begins from this S11 governance commit remote-locked and
requires a **separate explicit Owner authorization**.

---

## Y. Final Governance Decision

```text
S11_IMPLEMENTATION_GOVERNANCE_READY
```

Evidence:
- Entry forensically `CASE_A_FRESH`; local = tracking = direct GitHub remote =
  `21383b3b93902ddba1f030204d64b204b77a81f4`; AHEAD=0 / BEHIND=0.
- Full authority chain S8→S10 verified; S10 remote-locked and immutable.
- Group B deployment inventory reconstructed from committed files + git history
  (migrations 00031..00035 + Edge functions s6-device-pop / invite-employee).
- Production baseline = Migration 30; Group B server surface is NEW/UNAPPLIED.
- Production-state inspection classified INFRASTRUCTURE_BLOCKED (fail-closed; runbook makes
  live read-only discovery the first gate).
- Test/analyzer floors re-executed this session: 31/20/41/75/267/1755 all pass; analyzer 0 errors.
- Server pgTAP suites retained as recorded evidence (infra-blocked locally).
- Migration 00036 forbidden; S12/Group C/D forbidden; legacy origin sacred.
- Governance implements the committed Group B plan §21 successor-implementation requirements:
  scope, dependencies, files/surfaces, migration/deployment boundary, tests, acceptance criteria,
  rollback, explicit non-goals — all specified above.

```text
PRODUCTION_MUTATION_PERFORMED = NO
S11_IMPLEMENTATION_STARTED    = NO
S12_STARTED                   = NO
GROUP_C_STARTED               = NO
GROUP_D_STARTED               = NO
MIGRATION_00036_CREATED       = NO
LEGACY_ORIGIN_CONTACTED       = NO
```

---

*This document is governance only. It authorizes no deployment. S11 production deployment /
verification requires a separate explicit Owner instruction after this artifact is remote-locked.
Governance ready != deployment authorized.*
