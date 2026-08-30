# PHASE P — OWNER-GATED GROUP A IMPLEMENTATION GOVERNANCE DETERMINATION

## A. Session Identity

| Field | Value |
|---|---|
| SESSION | `PHASE_P_OWNER_GATED_GROUP_A_IMPLEMENTATION_GOVERNANCE_DETERMINATION` |
| SESSION_TYPE | `GOVERNANCE_DETERMINATION_ONLY` (no implementation; LOCAL CLOSURE ONLY; no push, no tag) |
| EXPECTED_BASELINE | `3da5b01420b5ae6c38834415caa4c4fe330bf23c` |
| EXPECTED_BASELINE_SUBJECT | `Plan Phase P owner-gated Group A` |
| EXPECTED_LOCK_TOKEN | `PASS_PHASE_P_OWNER_GATED_GROUP_A_PLANNING_REMOTE_LOCKED` |
| ROOT | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| LEGACY_ORIGIN | `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` — READ-ONLY / UNAUTHORIZED (never fetched, pushed, renamed, deleted, or modified) |
| GOVERNING ARTIFACTS | `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md`, `PHASE_P_OWNER_DECISIONS.md`, `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md`, `PHASE_P_PRODUCTION_HARDENING_PLAN.md`, `PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md`, `PHASE_P_IMPLEMENTATION_REPAIR_REPORT.md`, `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md`, `PRODUCTIZATION_MIGRATION_PLAN.md`, `POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md` |

This session determines whether the remote-locked `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md`
now authorizes implementation of Group A (A1..A8), and if so, under what exact
implementation boundary and sequencing. It does **NOT** implement A1..A8, does NOT
flip the drain, does NOT deploy Supabase, does NOT push, and does NOT claim Phase P
final closure.

## B. Entry Forensics

Read-only forensics performed before creating any tracked file. Only `git fetch github`
was performed (the authorized remote). The legacy `origin` was inspected read-only and
never contacted.

```text
ROOT        = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze   ✓
BRANCH      = codex/i-tech-next-roadmap-freeze                     ✓
AUTHORIZED  = github -> https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY      = origin  -> C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن (present, unused)
LOCAL_HEAD  = 3da5b01420b5ae6c38834415caa4c4fe330bf23c
REMOTE_HEAD = 3da5b01420b5ae6c38834415caa4c4fe330bf23c  (github/codex/... after fetch)
MERGE_BASE  = 3da5b01420b5ae6c38834415caa4c4fe330bf23c
AHEAD       = 0
BEHIND      = 0
INDEX       = EMPTY
TRACKED WK  = CLEAN
UNTRACKED   = sacred trio + supabase/.temp/ only (preserved, not staged)
```

**RECOVERY_CLASSIFICATION = `CASE_A_FRESH_GOVERNANCE_DETERMINATION`.**

Repository reality matches the expected handoff exactly (is-ancestor checks pass,
branch up to date with `github`). No destructive recovery (`git reset --hard`,
`git clean -fd`, force checkout, history rewrite, force push) was used or needed.
Sacred untracked artifacts were preserved rather than deleted to force a clean status.

**Observation (honest note):** no dedicated remote-lock **tag** for the Group A plan
was found in the remote tag list at the time of this determination (existing
`phase-p-*` tags peel to earlier commits `21d126d` / `1a931111`). The Group A plan
commit `3da5b01` is present on the `github/codex/...` branch head. This session
accepts the authoritative framing that the planning remote lock completed
(token `PASS_PHASE_P_OWNER_GATED_GROUP_A_PLANNING_REMOTE_LOCKED`); it records the tag
observation only and takes no corrective action, per the do-not-guess operating
principle.

## C. Governing Evidence

Evidence consulted (all read directly from the locked tree):

1. `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` — the remote-locked Group A planning artifact
   defining A1..A8, dependency order, the mandatory P-OD7 evidence gate (16 criteria),
   migration/restore boundary, tenant isolation, idempotency, observability, and
   completion criteria. It describes A1..A8 as **FUTURE IMPLEMENTATION** and states it
   "adds NO behavior".
2. `PHASE_P_OWNER_DECISIONS.md` — records P-OD1 (APPROVED) and P-OD7
   (CONDITIONALLY AUTHORIZED AFTER EVIDENCE) as authoritative, frozen, non-reopenable
   owner decisions; §F requires the planning→remote-lock→implementation→remote-lock
   sequence and forbids proceeding directly to implementation without a separate
   remote lock.
3. `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` — decomposed the
   post-owner Phase P work into Groups A–D and ordered Group A first, requiring its own
   planning + remote-lock boundary before implementation; Group C (Android
   identity/signing) and Groups B/D remain out of scope here.
4. `PHASE_P_PRODUCTION_HARDENING_PLAN.md`, `PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md`
   (WS-1 Complete dormant seam; WS-3 blocked pending OD6 now P-OD1; drain defaults
   FALSE), `PHASE_P_IMPLEMENTATION_REPAIR_REPORT.md` — provide the dormant-seam and
   test-baseline (1428/1428) evidence the plan builds on.
5. Repository reality checks (code over stale prose):
   - `app/lib/config/app_config.dart:39` — `syncDrainEnabled` defaults FALSE.
   - `supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql`
     ships `SELECT … FOR UPDATE` (lines 162, 286, 386, 475, 573) and
     `p_allow_oversell` — confirming the plan's §4.3 resolution that server-side stock
     serialization is already shipped (doc/claim discrepancy resolved in favor of code).
   - Latest local migration is `20260820000029_fix_shop_members_rls_recursion.sql`
     (18 local migration files). The plan's §4.3 references a ledger of 29 local
     migrations; the authoritative current sequence head for the next additive migration
     (A4) is migration **30** (number follows the last present migration file).
   - `app/lib/database/database_helper.dart:98` — `schemaVersion = 17`; A3/A4 local
     schema work would be additive v18 (restore whitelist `7..17` extended additively).

## D. Locked Planning Verification

The locked plan defines A1..A8 as future implementation, consistent with §4 of the
session brief:

```text
A1 — Production SyncCloudOperations transport                        (P-OD7 deliverable)
A2 — Drain activation wiring while seam remains OFF pending evidence
A3 — Option C reconciliation routing                                (P-OD1 local half)
A4 — Server-side Option C durability                                (P-OD1 server half, additive migration)
A5 — End-to-end idempotency + convergence plumbing
A6 — Truthful observability + retry/reconnect
A7 — Test suite + fixture transport
A8 — P-OD7 evidence-gate closeout + restore/security checks
```

Dependency ordering (plan §8):

```text
A1 ─┬→ A2 → A6
    ├→ A5 → A7
A4 ─┼→ A3
    └→ A8   (A8 gates on A1 + A4 + A5)
```

Evidence gate (plan §7): the drain MUST NOT flip until all 16 criteria are
demonstrated live or fixture-backed with documented equivalence, produced in the A8
evidence document and owner-signed. Activation mechanics: `SYNC_DRAIN_ENABLED=true`
is set only by an owner-approved release build, never by an agent commit.

The plan names NO single implementation session; it says the remote lock proceeds
"slice-by-slice" and lists each slice's scope, dependencies, and exit evidence.

## E. Governance Question

> After successful remote locking of `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md`, does
> repository evidence now authorize implementation of Group A, and if so, what exact
> implementation boundary and sequencing is authorized?

Determination: **YES — implementation IS authorized, but DECOMPOSED into separate
governed slices (OUTCOME_B)**, not as a single undifferentiated implementation group
(OUTCOME_A). OUTCOME_C (more planning) is not required because the locked plan leaves
no material implementation decision unresolved. OUTCOME_D (blocked) is not indicated:
all governing artifacts are present, P-OD1/P-OD7 are authoritative and frozen, and no
contradiction or missing hard dependency prevents authorization.

The authorization is **conditional and boundary-scoped**: implementation is authorized
for the A1..A8 slices under the §F decomposition, with DRAIN_ACTIVATION_AUTHORIZED = NO
and SUPABASE_DEPLOYMENT_AUTHORIZED = NO (each separately governed below).

### Why OUTCOME_B (decomposed), not OUTCOME_A (single group)

1. **Migration / deployment boundary ($8 of the brief):** A4 requires local migration
   implementation, migration verification, a separate migration remote lock, a separate
   production deployment session, and post-deployment verification. Its production
   deployment cannot ride inside a general implementation closure.
2. **Activation boundary (§7 of the brief):** A8's evidence gate is a distinct,
   owner-signed milestone; the drain flip is a separate, later activation event. These
   cannot be merged into one unit.
3. **Hard slice dependencies (plan §8):** A3 depends on A1+A4; A6 depends on A2; A8
   depends on A1+A4+A5; A7 lands incrementally with every slice. A single closure would
   violate these dependency/evidence boundaries.
4. **Repository protocol (`PHASE_P_OWNER_DECISIONS.md` §F;**
   `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` §D):** every governed
   slice passes through its own implementation → remote-lock stage; the plan itself
   states the remote lock proceeds slice-by-slice.

## F. Implementation Authorization: Slice / Session Decomposition

Each slice below is a distinct authorized implementation session, ordered by plan §8
dependency evidence. Every slice defaults to:

```text
DEPLOYMENT_ALLOWED        = NO  (Supabase production deployment is separately governed, §H)
DRAIN_ACTIVATION_ALLOWED  = NO  (remains OFF; activation separately governed, §G)
REMOTE_LOCK_REQUIRED      = YES (a dedicated remote-lock session follows each slice)
SUPABASE_DEPLOYMENT       = NO
```

Authorized (NOT yet executed) slice order:

| Slice | SESSION_IDENTITY (suffix) | DEPENDENCIES | SCOPE / ALLOWED_MUTATIONS | FORBIDDEN_MUTATIONS | LOCAL_CLOSURE_TOKEN |
|---|---|---|---|---|---|
| A1 | `PHASE_P_OWNER_GATED_GROUP_A_A1_TRANSPORT` | none | Implement production `SyncCloudOperations` transport; per-entity RPC routing; tenant scoping from persisted `shop_id` (never ambient); error mapping; response adoption. `app/lib` + `app/test` only. | No drain flip; no deployment; no runtime wiring (A2); no server schema change (A4). | `PASS_GROUP_A_A1_LOCAL_READY` |
| A5 | `..._A5_IDEMPOTENCY_CONVERGENCE` | A1 | occurrenceToken as `p_idempotency_key`; adoption (`cloud_uuid`, `server_version`, `current_quantity`); IDEMPOTENT replay path; FAILED/CONFLICT honoring OF-4. `app/lib` + `app/test`. | No drain flip; no deployment. | `PASS_GROUP_A_A5_LOCAL_READY` |
| A4 | `..._A4_SERVER_DURABILITY_MIGRATION` | none (additive) | Additive migration **30**: `cloud_stock_adjustments` + owner-gated RPCs + RLS; migration-runner tests; restore-compat check (v18 additive). Local file creation + tests ONLY. | NO production deployment here; no rewriting of existing functions/grants; no drain flip. | `PASS_GROUP_A_A4_LOCAL_READY` |
| A3 | `..._A3_OPTION_C_ROUTING` | A1 + A4 | OVERSOLD reconciliation: preserve sale, durable local adjustment + `conflict_audit`, wire `adjustmentSink`/`ownerNotifier`, reversible adjustment sync op. `app/lib` + `app/test`. | No local-blocking change; no drain flip; no deployment. | `PASS_GROUP_A_A3_LOCAL_READY` |
| A2 | `..._A2_DRAIN_WIRING` | A1 | Attach transport to `SyncRuntime.configure(cloudOperations:)`; confirm license/connectivity/shop gates keep offline/unlicensed/unbound untouched; `AppConfig.syncDrainEnabled` stays FALSE. `app/lib` + `app/test`. | MUST NOT flip `syncDrainEnabled`; no deployment. | `PASS_GROUP_A_A2_LOCAL_READY` |
| A6 | `..._A6_OBSERVABILITY` | A2 | Truthful `SessionState` + `SyncStatusIndicator`; retry/reconnect affordance; never claim "synced" for queued/failed. `app/lib` + `app/test`. | No drain flip; no deployment. | `PASS_GROUP_A_A6_LOCAL_READY` |
| A7 | `..._A7_TEST_SUITE` | A1..A6 (incremental) | rpcOverride transport fixture; migration-runner tests for migration 30; full regression (1428 baseline deltas); integration coverage. `app/test` (+ minimal lib fix only). | No production behavior change beyond prior slices; no drain flip; no deployment. | `PASS_GROUP_A_A7_LOCAL_READY` |
| A8 | `..._A8_EVIDENCE_GATE_CLOSEOUT` | A1 + A4 + A5 minimum | Produce the P-OD7 evidence document (16 criteria, live or documented-equivalent probe); restore v7..v18 forward-compat check; no-secret-leak audit; WS-10 seal loop. Document only (+ release-build override note). | Must NOT flip the drain by agent; the owner/release executes any activation. No deployment. | `PASS_GROUP_A_A8_LOCAL_READY` |

A7 is not a discrete lock; it lands incrementally with each slice. Each non-A7 slice is
followed by a dedicated remote-lock session before the next slice begins.

## G. Migration / Deployment Boundary

```text
MIGRATION_IMPLEMENTATION      = AUTHORIZED (slice A4, local additive migration 30 + tests, in the implementation boundary)
MIGRATION_VERIFICATION        = AUTHORIZED (slice A4 migration-runner tests; A7 re-runs; restore-compat check in A8)
MIGRATION_REMOTE_LOCK         = REQUIRED   (a dedicated migration remote-lock session locks migration 30 locally-prerequisite state)
PRODUCTION_DEPLOYMENT         = NOT AUTHORIZED by this determination (separate, dedicated production-deployment session required; SUPABASE_DEPLOYMENT = NO here)
POST_DEPLOYMENT_VERIFICATION  = REQUIRED   (separate governed verification session after production deployment)
```

A local migration file may be authorized (A4) while production deployment remains
separately governed and NOT authorized in any implementation slice.

## H. P-OD7 Evidence-Gate Boundary

```text
TRANSPORT_IMPLEMENTATION     = AUTHORIZED (slice A1)
TRANSPORT_VERIFICATION       = AUTHORIZED (slice A1 exit evidence; A7 integration; production presence probe in A8)
P_OD7_EVIDENCE_GATE          = NOT YET PASSED (owner-signed gate required; produced only at/after A8)
DRAIN_ACTIVATION             = NOT AUTHORIZED by any implementation slice (SYNC_DRAIN_ENABLED stays FALSE)
DRAIN_RELEASE_OVERRIDE_ENABLED = NO (only an owner-approved release build may set SYNC_DRAIN_ENABLED=true)
```

These are distinct and NOT synonyms:
`IMPLEMENTATION_AUTHORIZED = YES`, while
`DRAIN_ACTIVATION_AUTHORIZED = NO`.

## I. Drain Activation Boundary

`AppConfig.syncDrainEnabled` remains FALSE throughout all A1..A8 implementation slices
(a verified: `app/lib/config/app_config.dart:39` default FALSE). No implementation
session may change the default. Activation requires: A8 evidence gate passed AND an
owner-approved release-build override (owner/release executes the flip, never an agent
commit inside this phase).

## J. Security / Tenant Isolation / Idempotency Constraints

Preserved for every implementation slice (from the locked plan):

1. Tenant isolation: every transport call scoped by persisted `entry.shop_id`; no
   ambient context; bound-context mismatch = error (fail-closed).
2. Idempotency: one occurrence token per logical op; server lookup/record pair;
   exactly-once across retry/reconnect; replays marked SYNCED without re-execution.
3. Permissions: `require_shop_permission` covers entity RPCs; sync only queues
   permitted operations.
4. Entitlement: `licenseCheck` gates the drain; offline-only/unlicensed unaffected.
5. RLS posture: new `cloud_stock_adjustments` table ships RLS policies matching the
   existing `shop_id` row-level pattern; grants to `authenticated` only for the owner RPC.
6. No secrets: `.env.example` / `config.toml` untouched; service-role key never in
   client scope; edge surface stays minimal (1 function, `invite-employee`).
7. No cross-shop movement; no duplicates; truthful counters; reconnect with retry/
   backoff; runtime sanity (no timer leaks, `_isProcessing` guard, restart recovery).
8. The full 16-criterion P-OD7 evidence gate must be preserved; implementation
   authorization does not waive any criterion.

## K. Frozen Identifiers / Non-Goals

Frozen desktop/database identifiers are preserved (add-only). No identifier migration
is authorized. The Android package migration (`com.almuaman.muaman_store` →
`com.itech.storemanagement`, P-OD2 / Group C) is out of scope and NOT part of Group A.
Group B and Group D remain out of scope for every Group A session.

## L. Sacred Artifact Verification (session record)

| Artifact | SHA-256 (PRE == POST) | Result |
|---|---|---|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` | ✓ unchanged |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | `C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733` | ✓ unchanged |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` | ✓ unchanged |
| `supabase/.temp/` | untracked, unmodified, not staged | ✓ preserved |

Sacred artifacts were verified byte-identical at session entry and preserved; they
were not added to Git to clean status.

## M. Authorized Next Session

Exactly ONE immediate successor is authorized:

```text
PHASE_P_OWNER_GATED_GROUP_A_IMPLEMENTATION_GOVERNANCE_DETERMINATION_REMOTE_LOCK
```

Per the repository's governance protocol and §15 of the session brief, this local
determination is NOT an implementation trigger. The remote lock of this
determination must complete first. After it completes, the first authorized
implementation slice is **A1 — Production `SyncCloudOperations` transport**
(`PHASE_P_OWNER_GATED_GROUP_A_A1_TRANSPORT`), faithful to §F.

No competing immediate successor is authorized.

## N. Deferred / Forbidden Work (this session)

This session performed/did NOT perform:

```text
implement A1..A8                                = NOT PERFORMED (forbidden here)
create production SyncCloudOperations           = NOT PERFORMED
wire cloudOperations into runtime               = NOT PERFORMED
change syncDrainEnabled default                 = NOT PERFORMED
activate drain                                  = NOT PERFORMED
create Option C production durability behavior  = NOT PERFORMED
create/edit production Supabase migrations for Group A = NOT PERFORMED
deploy Supabase                                 = NOT PERFORMED
change subscription/licensing rules             = NOT PERFORMED
change Android package identity                 = NOT PERFORMED
create signing material                         = NOT PERFORMED
implement Group B / C / D                       = NOT PERFORMED
modify sacred artifacts                         = NOT PERFORMED
push / tag                                      = NOT PERFORMED
claim Phase P final closure                     = NOT PERFORMED
```

## O. Closure Conditions

This governance determination completes when:

1. This artifact is the single tracked delta (A HEAD, index EMPTY).
2. Sacred artifacts byte-identical PRE == POST (§L).
3. Local commit `Determine Phase P Group A implementation governance` created with
   AHEAD=1 / BEHIND=0 / INDEX=EMPTY; no push, no tag.
4. Success token
   `PASS_PHASE_P_OWNER_GATED_GROUP_A_IMPLEMENTATION_GOVERNANCE_DETERMINATION_LOCAL_READY`
   minted.
5. Next authorized session is the governance-determination REMOTE_LOCK (§M).

`PHASE_P_FINAL_CLOSURE` is NOT claimed by this session.

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION      = CASE_A_FRESH_GOVERNANCE_DETERMINATION
RECOVERY                 = none required (fresh handoff matched)
DETERMINATION            = OUTCOME_B — IMPLEMENTATION AUTHORIZED, DECOMPOSED INTO GOVERNED SLICES
IMPLEMENTATION_AUTHORIZED= YES (slices A1..A8, §F)
IMPLEMENTATION_MODEL     = OUTCOME_B (decomposed, remote-locked slice-by-slice)
DRAIN_ACTIVATION_AUTHORIZED = NO
SUPABASE_DEPLOYMENT_AUTHORIZED = NO
CURRENT_HEAD             = 3da5b01420b5ae6c38834415caa4c4fe330bf23c
DIFF PROFILE             = 1 added file (this artifact), 0 modified, 0 deleted
SACRED PRE  = 3D4D17… / C8C5BD… / 70F848…  ✓ (full values §L)
SACRED POST = (recorded after commit)
COMMIT      = (set after commit)
AHEAD/BEHIND= (1/0 after commit)
SESSION TOKEN = PASS_PHASE_P_OWNER_GATED_GROUP_A_IMPLEMENTATION_GOVERNANCE_DETERMINATION_LOCAL_READY
```
