# PHASE P — OWNER-GATED GROUP A PLAN (P-OD1 + P-OD7)

## 0. Document Control

| Field | Value |
|---|---|
| Phase | P — Production Hardening, Group A (owner-gated) |
| Governs | P-OD1 (WS-3/Od6 Option C durability) + P-OD7 (WS-1 sync-drain gated activation) |
| Session type | PLANNING ONLY (no implementation, no push, no tags, no deployment) |
| Session identity | `PHASE_P_OWNER_GATED_GROUP_A_PLANNING` |
| Baseline verified at session entry | `f539282898f142441781010b702c6c28d7f68d4b` (LOCKED_BASELINE) |
| Baseline parent | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` |
| Baseline subject | `Determine post-owner-decisions Phase P successor` |
| Planning artifact | `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` (this file, single tracked delta) |
| Commit message | `Plan Phase P owner-gated Group A` |
| Authorized next session | `PHASE_P_OWNER_GATED_GROUP_A_PLANNING_REMOTE_LOCK` |
| Success token (this session) | `PASS_PHASE_P_OWNER_GATED_GROUP_A_PLANNING_LOCAL_READY` |
| Operating principle order | Zero data loss → financial truth → inventory explainability → idempotency → transactional correctness → tenant isolation → authorization → restartability → convergence → user clarity → minimal change |

All code references below were read directly from the locked baseline tree at
`f539282898f142441781010b702c6c28d7f68d4b` (working tree clean; index empty).
This document adds NO behavior: it records the evaluated Group A implementation
slices, the mandatory evidence gate (P-OD7), and the Option C durability design
(P-OD1) exactly as the owner decisions require.

---

## 1. Repository / Locked Baseline

Verified at session entry (all read-only, no mutation):

```text
ROOT        = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH      = codex/i-tech-next-roadmap-freeze
AUTHORIZED  = github -> https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY      = origin  -> C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن   (untouched, unused, never fetched)

LOCAL_HEAD  = f539282898f142441781010b702c6c28d7f68d4b
REMOTE_HEAD = f539282898f142441781010b702c6c28d7f68d4b
MERGE_BASE  = f539282898f142441781010b702c6c28d7f68d4b
AHEAD/BEHIND= 0/0
INDEX       = empty
UNTRACKED   = sacred trio + supabase/.temp/ only
TRACKED     = 8421 files
```

Entry classification: **CASE_A_FRESH** — clean WORKTREE, index empty, no
divergence from the remote (is-ancestor checks pass). No Group A planning
artifact existed before this file.

---

## 2. Canonical Phase Definition

From `PROJECT_MASTER_PLAN.md` §13:

> | P | Production hardening | Production-grade hardening: sync, conflicts, licensing, restore, security |

Dependency: after N + O (owner decisions). Roadmap position is immediately after
the post-owner Phase P decision baseline `f5392828…`.

Governing dead-seam confirmation (`POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md`,
`PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md` §3/§6): EVERY WS-1..WS-10 artifact is
**compiled and dormant**. The mandatory Group A work is activation-facing, and
activation of the drain is itself owner-gated (P-OD7).

---

## 3. Governing Requirements

Cross-checked: `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md`,
`PHASE_P_PRODUCTION_HARDENING_PLAN.md`, `PHASE_P_OWNER_DECISIONS.md`,
`PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md`, `PHASE_P_IMPLEMENTATION_REPAIR_REPORT.md`,
`POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md`, `PHASE_M…PLAN.md`,
the preserved sacred reports (read-only).

### 3.1 Binding owner decisions (authoritative input, not reopenable)

- **P-OD1 (APPROVED — WS-3/Od6):** a negative-stock sale/event MUST never
  disappear. Event, stock state, explicit adjustment evidence, and an
  immutable/durable audit MUST persist. Server-side stock changes MUST be
  concurrency-safe (row-level serialization / `SELECT … FOR UPDATE` where
  architecturally applicable). Multi-device reconciliation MUST NOT silently
  overwrite/erase the oversell event. Reports stay mathematically traceable to
  persisted transactions and adjustments.
- **P-OD7 (CONDITIONALLY AUTHORIZED AFTER EVIDENCE — WS-1 activation gate):**
  `syncDrainEnabled` remains FALSE until a mandatory evidence gate proves the
  real production `SyncCloudOperations` transport across: context, tenant
  isolation, permissions, entitlement, enqueue→drain, retry/idempotency, stable
  cloud identity, offline recovery, conflict, counters, reconnect, no cross-shop
  movement, no duplicates, no secret leakage, runtime sanity.
- Owner-recorded discipline (`PHASE_P_OWNER_DECISIONS.md` §D, lines 75–84):
  this and downstream sessions MUST NOT flip `syncDrainEnabled`, MUST NOT
  implement Option C durability, MUST NOT modify subscription/tier/revocation
  logic or deploy, MUST NOT remove/isolate the legacy Ed25519 path (P-OD12
  evidence pending).

### 3.2 Frozen identifiers (never renamed/modified/reinterpreted)

```text
muaman_store            (pubspec / binary name)       -> pubspec.yaml:1
muaman_store.db         (production database filename)
muaman_store.exe        (legacy binary compatibility)
{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}  (Windows AppId) -> installer/muaman.iss
I-TECH للتكنولوجيا      (installer AppName / window title)
muaman_store            (Linux/CMake identities)
com.almuaman.muaman_store (Android namespace/applicationId today; P-OD2 reserved)
All table/column/permission/role names (add-only)
```

### 3.3 Sacred artifacts (byte-identical must-remain)

| Artifact | SHA-256 (session entry, verified) |
|---|---|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | `C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733` |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` |
| `supabase/.temp/` (9 metadata files) | untracked, unmodified (must stay untracked) |

Note on the ZIP hash history: the original packaging contract records
`962BE5C8…` (`MUAMAN…REPORT.md` §M; `tools/…/installer_contract.json`). The
sacred ZIP at `delivery/` was subsequently regenerated; every governed
Phase I/G/K/L/N/P report records the then-current and current canonical value
`70F8480D…` (verified byte-identical again this session). The two hash families
refer to two distinct packaging generations and are not a tampering signal.

### 3.4 Test / quality gates (documented baseline, not re-run in planning)

`PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md` §5: full `flutter test` = **1428/1428
passed**; sync suite 161; database+sync+backup/restore 663; feature/widget 52;
licensing 56; crash handler 4. `dart format` green (277 files); `flutter analyze`
0 errors / 0 warnings. `PHASE_P_IMPLEMENTATION_REPAIR_REPORT.md` =
`PASS_PHASE_P_IMPLEMENTATION_REPAIR_LOCAL_READY`. Test file inventory this
session: 115 `*.dart` under `app/test/` (regex-counted 1298 `test(` declarations
on start-of-line; declared 1428 is authoritative since multi-line declarations
are not start-of-line).

---

## 4. Current-State Forensics (shipped-and-dormant)

### 4.1 Drain seam is dormant twice-over

- `app/lib/config/app_config.dart:39-42` — `syncDrainEnabled =
  bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue: false)`.
- `app/lib/sync/sync_engine.dart:539` — `SyncCloudOperations` is a
  **functional interface** (upsertEntity/deleteEntity-style contract). It is
  NEVER constructed in `app/lib/` (grep of `SyncCloudOperations(` across lib
  yields only the class definition + test wiring). The `SyncRuntime`/main.dart
  drain path exists as a dormant seam: `main.dart:252-268` configures the
  runtime with `shopIdProvider`, `licenseCheck`, `connectivityCheck`
  (`isCloudLinked && isOnline`) and `drainEnabled: AppConfig.syncDrainEnabled`,
  but passes NO `cloudOperations`, so with the seam OFF it only manages and
  publishes queue status — zero cloud calls.
- `app/lib/services/cloud_session_resume.dart:42` and
  `app/lib/services/seller_session_provisioning.dart:136-137` (D-L7): "the sync
  runtime is intentionally NOT touched here or anywhere else" — confirmed UUID,
  no runtime construction in Phase L/K paths.

### 4.2 Option C seam is dormant

- `app/lib/sync/inventory_oversell_policy.dart:17-18` — shipped default
  `preserveWithAdjustment` (Option C mechanics + owner notification); doc text
  still says "OD6 REMAINS OPEN" (pre-P-OD1 phrasing; P-OD1 approval now makes
  Option C the owner-posture — do not reopen).
- `app/lib/sync/reconciliation_service.dart:104-170` — `StockBelief`,
  `OversellAdjustmentArtifact` (shopId/barcode/projected/shortfall/
  relatedEventIds), `adjustmentSink`/`ownerNotifier` both nullable and unused in
  lib, `createsAdjustmentArtifact` honored only when wired.
- `app/lib/sync/conflict_audit_repository.dart` — `ConflictAuditRepository`
  instantiated only in tests; local SQLite `conflict_audit` table (schema v15)
  with `resulting_adjustment_id` column; writes conflict record BEFORE queue
  transition (OF-4), append/transition-only (AU-1), executor seam for atomicity
  (INV-M17).
- Local sale path blocks oversell: `database_helper.dart` sale insert throws
  `StateError('Insufficient stock: available X, requested Y')` inside the
  transaction (lines ~1433-1437). Option C recovery is therefore a
  server-authoritative reconciliation-path behavior, not a change to local
  blocking.

### 4.3 Server-side stock serialization is ALREADY SHIPPED (documentation discrepancy resolved)

`supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql`
has been read in full (871 lines). Repository evidence **supersedes** the
plan-text and closure-report claims that `SELECT … FOR UPDATE` is "outstanding
(DR-M03)":

- The migration header comment (lines 12–13) asserts "DR-M03: no SELECT FOR
  UPDATE / advisory locks / reservations", but the **body ships** exactly that
  mechanism: `SELECT * … FOR UPDATE` on `cloud_products` at lines 162, 286, 386,
  475, 573 inside SECURITY DEFINER RPCs, plus a conditional-UPDATE
  compare-and-set guard (`phase_m_oversell_guard`, lines 202, 235-245) that
  re-validates availability with the row lock held.
- `create_cloud_sale_with_stock_v2` honors `p_allow_oversell BOOLEAN DEFAULT
  FALSE`; when lifted, `current_quantity` is allowed negative and the response
  status is `OVERSOLD` (lines 168-178). Revert functions (`…_v2`) recompute the
  component equation exactly. `save_cloud_inventory_count_v2` implements
  latest-observed-wins with `observed_at` clamping and post-observation
  re-baselining (IC-1..IC-5).
- Idempotency is a shared-transaction helper pair: `phase_m_idempotency_lookup`
  (replay returns original JSONB) and `phase_m_idempotency_record`
  (`ON CONFLICT (idempotency_key) DO NOTHING`, lines 51-114). Invoice RPC uses
  ONE invoice-level key for the whole effect set with per-item key NULL (line
  763) — safe because the outer lookup short-circuits replays before the loop.
- Production application status of migration 28 is a **deployment-verification
  item** for the implementation sessions (the earlier SUPABASE report recorded
  17 migrations at its time; the ledger now contains 29 local migrations). The
  evidence gate in §7 makes this explicit.

### 4.4 Existing building blocks (Group A reuse surface)

| Block | Location | State |
|---|---|---|
| `SyncRuntime` (configure/ensureStarted/stop/publishStatus/syncNow) | `lib/sync/sync_runtime.dart` (290-352 wires Engine/Worker/Hydration/Incremental) | dormant, wired via main.dart |
| `SyncWorker` (30s Timer tick, `_isProcessing` guard, M-I05 recovery sweep, WS-1 onCycleComplete hook) | `lib/sync/sync_worker.dart` | dormant |
| `SyncEngine` + `SyncCloudOperations` interface (line 539) + `HydrationCloudSource` | `lib/sync/sync_engine.dart`, `lib/sync/hydration_service.dart:202` | interfaces only |
| Sync queue (status, retry, occurrenceToken, writerSnapshot v17, idempotencyKey, shopId) | `lib/sync/sync_queue_repository.dart` (+ `_migrateToV17` in database_helper) | live, local-only |
| Sync adapters (9 entity types, local↔cloud payloads, conflictPolicy) | `lib/sync/adapters/*` | live, dormant use |
| `ConflictResolver` (serverAuthoritative, event-like review, ES-1 stock-component protection) | `lib/sync/conflict_resolver.dart` | live, dormant use |
| Cloud `_v2` stock RPC clients + `StockRpcResult` | `lib/repositories/cloud/cloud_sales_repository.dart:191-305`, `stock_rpc_result.dart` | live, no production caller |
| `CloudDataErrorType.insufficientStock` mapping | `lib/errors/cloud_data_exception.dart` | live |
| `SessionState` sync counters + `SyncStatusIndicator` (sales_screen.dart:97) | `lib/services/session_state.dart`, `lib/widgets/sync_status_indicator.dart` | live, statuses must become truthful |
| `ActiveShopContext` bind/switch validation (fail-closed `TenantContextException`) | `lib/services/active_shop_context.dart` | live |
| Restore (versions 7..schemaVersion=17, expected-tables check, PRAGMA integrity) | `lib/services/standalone_restore_service.dart` | live; v18 support additive |
| `database_helper._generateSyncKey` = `entityType:entityUuid:operation:occurrenceToken`; occurrence token minted once per logical op, persisted | `lib/database/database_helper.dart:265-270,284+` | live |

### 4.5 Idempotency model (source of truth)

Key format `entityType:entityUuid:operation.label:occurrenceToken`; token created
once per logical operation and persisted in `sync_queue.occurrence_token`;
`writer_snapshot` column (v17) captures the pre-write permission/entitlement
snapshot for sync-time adjudication (WS-5). Server side keys are opaque strings
shared with the `_v2` RPCs (`p_idempotency_key`). This is the end-to-end mapping
that the drain transport must preserve (A5).

### 4.6 Supabase / secret posture (verified)

- `supabase/config.toml` — no secrets; local CLI dev-only values.
- `.env.example` — placeholders only; service-role key commented OUT of client
  scope.
- Edge-function surface = 1 (`invite-employee`, with `index.test.ts`).
- RPCs are `SECURITY DEFINER` gated by `require_shop_permission`; the owner-only
  `resolve_sync_conflict` re-verifies `admin.settings.access` server-side
  (DR-M10) — UI is never the authority.
- Realtime enabled (config) — no client dependency on it today; do not add.

---

## 5. Group A Scope

Group A bundles exactly the two decisions whose evidence can be produced and
verified in sequence:

1. **P-OD1 evidence + design** — Option C durability (adjustment artifact +
   audit + server serialization) is the *behavior* the evidence gate must prove,
   because a live drain that can oversell MUST have the Option C audit path.
2. **P-OD7 evidence gate** — the live `SyncCloudOperations` transport proof that
   un-gates the `SYNC_DRAIN_ENABLED` flip.

Non-goals (owned by later groups): WS-2 duplicate-key/backfill, WS-4 entitlement/
revocation, WS-5 seller snapshot adjudication UI, WS-6/7 restore-app, WS-7 signing,
WS-8 android packaging, WS-9 accounts/ledger, WS-10 seal, and all Group B/C/D
planning.

---

## 6. Implementation Slices A1..A8 — Evaluation

Every slice below is **future implementation**, listed here with evidence,
scope, dependencies, and exit evidence so the remote lock can proceed
slice-by-slice.

### A1 — Production `SyncCloudOperations` transport (P-OD7 deliverable)

- **Goal:** implement the dormant functional interface with a real Supabase
  transport: per-entity RPC routing (sale/return/invoice → `*_v2` idempotent
  stock RPCs; product/expense/customer/settings → `sync_upsert_entity`-family
  per permission; DELETE → `*_v2` reverts / `sync_delete_entity`), tenant
  scoping from persisted `entry.shop_id` (never ambient), error mapping to
  `CloudDataException` types, response adoption (`id`→cloud_uuid,
  `server_version`, `current_quantity`).
- **Evidence baseline:** interface `sync_engine.dart:539`; `_v2` client
  contract `cloud_sales_repository.dart:191-305`; RPC grant surface
  `migration 28:865-871`; `StockRpcResult`.
- **Risks:** RPC signature drift vs production schema (recheck via gate §7);
  cloud table row shapes must match adapter `cloudToLocalRow`.
- **Dependencies:** none (stands on shipped seams).
- **Exit evidence:** integration tests with `rpcOverride` + a live-project probe
  run documented in the §7 evidence gate.

### A2 — Drain activation wiring (gate on §7, still OFF for offline/non-bound tenants)

- **Goal:** attach the A1 transport to `SyncRuntime.configure(cloudOperations:)`
  and confirm the existing `licenseCheck` + `connectivityCheck` +
  `shopIdProvider` gates keep offline-only/unlicensed/unbound tenants untouched;
  keep `AppConfig.syncDrainEnabled` FALSE until §7 evidence is owner-signed.
- **Evidence baseline:** `sync_runtime.dart:290-352`; `main.dart:252-268`;
  P-OD7. `retryEntry` (queue) gains its first production caller here.
- **Dependencies:** A1.
- **Exit evidence:** worker lifecycle tests (start/drain/stop/reconnect/recovery
  sweep) on the fixture transport; zero cloud calls with seam OFF.

### A3 — Option C reconciliation routing (P-OD1 local half)

- **Goal:** when a drained sale returns `OVERSOLD`, preserve the sale, create a
  durable local adjustment record + `conflict_audit` entry (wires
  `resulting_adjustment_id`), invoke the policy seam's `adjustmentSink` and
  `ownerNotifier`, and enqueue a reversible adjustment sync op.
- **Evidence baseline:** `reconciliation_service.dart:154-170`;
  `conflict_audit_repository.dart`; `sync_status.dart:90-103`;
  `inventory_oversell_policy.dart`.
- **Risks:** must not alter local blocking behavior; concurrency with manual
  stocktake adjustments (IC rules) — adjustment applies as an additive artifact,
  never rewriting sold/returned counters.
- **Dependencies:** A1 (drain) + A4 (server durability, for mirror).
- **Exit evidence:** reconciliation tests (dual-offline canonical case,
  M-C03 shape) asserting equation holds and artifact+audit exist.

### A4 — Server-side Option C durability (P-OD1 server half, additive migration)

- **Goal:** additive migration (next number after 29) adding durable
  `cloud_stock_adjustments` (shop_id, product_id, barcode, projected_current,
  shortfall, related s-sale/return ids, idempotency_key, status, resolved_by/
  at, created_by/at) + owner-gated RPCs (`admin.settings.access`) to create/list
  adjustments, and — additively — auto-adjustment recording inside
  `create_cloud_sale_with_stock_v2` when an oversell occurs. Never rewrites
  existing functions/grants; preserves already-shipped `FOR UPDATE` + CAS.
- **Evidence baseline:** migration 28 body (lines 119-345) is the extension
  target; `sync_log.conflict_details` JSONB already carries
  current_quantity/server_version/oversold.
- **Risks:** report traceability requires the adjustment row to be tied to the
  exact sale idempotency key; RLS policy for the new table.
- **Dependencies:** none (can land before A3's mirror).
- **Exit evidence:** SQL migration-runner tests (DB-addressable in CI),
  grant/RLS review, and restore-compatibility check (A8).

### A5 — End-to-end idempotency + convergence plumbing

- **Goal:** SyncEngine drain passes `entry.occurrenceToken` as
  `p_idempotency_key` on every stock RPC; adopts responses (
  cloud_uuid/server_version stamping, `current_quantity` reconciliation);
  `IDEMPOTENT` replay path marks entry SYNCED without re-execution;
  FAILED/CONFLICT transitions honor conflict_audit-before-queue (OF-4).
- **Evidence baseline:** `_generateSyncKey` (database_helper 265-270),
  occurrenceToken persistence, migration-28 lookup/record pair.
- **Dependencies:** A1.
- **Exit evidence:** duplicate-delivery integration tests (same token twice)
  asserting exactly-once server effects.

### A6 — Truthful observability + retry/reconnect

- **Goal:** `SessionState` + `SyncStatusIndicator` render real states
  (local-only/queued/syncing/synced/retrying/conflicted/
  requires-reconciliation/failed/offline/transport-unavailable); add retry
  affordance wired to `retryEntry`; never claim "synced" for queued/failed
  entries.
- **Evidence baseline:** `session_state.dart` counters; `sync_queue_repository
  .retryEntry`:393; `sync_status_indicator.dart`; sales_screen.dart:97.
- **Dependencies:** A2.
- **Exit evidence:** widget tests + manual truthfulness audit.

### A7 — Test suite + fixture transport

- **Goal:** rpcOverride-based transport fixture (`cloud_sales_repository.dart:19`
  pattern), migration-runner tests for migration 30, full regression re-run, and
  integration coverage for the A1..A6 acceptance criteria.
- **Dependencies:** A1..A6 (landshape per slice).
- **Exit evidence:** documented suite deltas vs the 1428 baseline.

### A8 — Evidence gate closeout (P-OD7) + restore/security checks

- **Goal:** produce the mandatory evidence document (16 criteria, §7) with live
  probe results; confirm restore v7..v18 forward compatibility; confirm no
  secret leakage; loop into WS-10 seal.
- **Dependencies:** A1 + A4 + A5 minimum.
- **Exit evidence:** owner-signed gate passing; `SYNC_DRAIN_ENABLED=true` becomes
  a release-build documented override (flip executed by owner/release, NOT by an
  agent inside this phase).

---

## 7. Mandatory Evidence Gate (P-OD7) — activation is owner-confirmed only

The drain **must not flip** until ALL of the following are demonstrated, live or
fixture-backed with a documented equivalence, and noted in the A8 evidence
document:

1. Context — transport resolves the authenticated cloud user + bound shop.
2. Tenant isolation — every RPC scoped by persisted `shop_id`; ActiveShopContext
   bind/switch validation enforced; no cross-shop movement ever.
3. Permissions — `require_shop_permission` fully covers the entity RPCs; sync
   only queues permitted operations.
4. Entitlement — `licenseCheck` (cloudLicensingService.enforceActive) gates the
   drain; unlicensed/offline-only tenants untouched.
5. Enqueue→drain — PENDING → SYNCED transitions observed end-to-end on a real
   queue write.
6. Retry/idempotency — same logical operation applied at most once (token shown
   reaching `p_idempotency_key`; replay returns IDEMPOTENT without re-execution).
7. Stable cloud identity — `cloud_uuid` stamped and stable across re-syncs.
8. Offline recovery — M-I05 sweep drains leftover queue after restart.
9. Conflict — OF-1/OF-5 behaviors: sale preserved; REVIEW_REQUIRED conflict
   record before queue transition; owner review possible.
10. Counters — SessionState pending/failed/conflict/lastSyncedAt truthful.
11. Reconnect — transient transport failure → retry with backoff; no data loss.
12. No cross-shop movement — multi-shop membership test.
13. No duplicates — server sale/return counts equal queue SYNCED counts.
14. No secret leakage — network/console audit; config.toml/.env posture intact.
15. Runtime sanity — worker lifecycle (start/stop), `_isProcessing` guard, no
    timer leaks, process-restart recovery.
16. Migration 28 production presence — `*_v2` RPCs and `p_allow_oversell`
    verified present in the production schema before relying on them.

Activation mechanics stay governed: `SYNC_DRAIN_ENABLED=true` is set only by an
owner-approved release build (Windows installer / Android app) — never by an
agent commit flipping the default.

---

## 8. Proposed Order

```
A1 (transport) ─┬→ A2 (wiring) ─→ A6 (observability)
                ├→ A5 (idempotency/convergence) ─→ A7 (tests)
A4 (server durability) ───────┼→ A3 (Option C routing)
                              └→ A8 (evidence gate + restore/security)
```

Rationale: A1 first (dormant-interface activation is the highest risk),
A4 additive alongside (server durability independent), A3 only after both
(A1/A4) so the OVERSOLD path has its server mirror, A8 last (gate + seal
closeout). A7 lands incrementally with every slice.

---

## 9. Higher-Authority Discipline

- P-OD1..P-OD12 recorded in `PHASE_P_OWNER_DECISIONS.md` are authoritative
  inputs; no reinterpretation, no reopening.
- Where documents and code disagree (e.g., DR-M03 lock claim in migration-28
  header vs shipped `FOR UPDATE`), the repository reality governs and is
  recorded in §4.3 for the implementation sessions.
- Option C default (`preserveWithAdjustment`) is confirmed by P-OD1 approval;
  the "OD6 REMAINS OPEN" doc text is stale phrasing only, never a reason to
  flip the seam.

---

## 10. Quality Gates

- `dart format` on changed Dart files; `flutter analyze` 0 errors / 0 warnings;
  full `flutter test` green (baseline 1428/1428, deltas per A7); SQL migration
  tests green; no new pre-existing failures introduced.
- Sacred artifacts byte-identical before and after every session (§19).
- Docs-only edits for planning/evidence artifacts; no behavior change outside
  the gate-signed slices.

---

## 11. Security / RLS Posture

- Server-authoritative trust boundary preserved: RLS + `require_shop_permission`
  + SECURITY DEFINER RPCs; UI is UX only (`resolve_sync_conflict` re-verifies
  owner server-side).
- New `cloud_stock_adjustments` table ships RLS policies matching the existing
  row-level `shop_id` pattern; grants to `authenticated` only for the owner RPC.
- No secrets: `.env.example`/`config.toml` untouched; service-role key never in
  client code; edge surface stays minimal (1 function, `invite-employee`) unless
  the owner extends.
- Keystore/signing per P-OD3 (out of Group A scope; never generated/guessed).

---

## 12. Migration / Restore Compatibility

- All future schema work additive: `PRAGMA user_version` increments in
  `database_helper.schemaVersion` (currently **17**) with a migration function
  + test; fresh installs get the same final shape as upgrades.
- A3/A4 introduced tables/columns must not break the restore expectation-table
  check (`standalone_restore_service`); v18 restore support is additive to the
  existing `versions 7..17` window (A8 verifies end-to-end).
- Server migrations additive only; existing RPC signatures/behavior preserved
  for legacy callers (`migration 28:14-16` discipline).

---

## 13. Tenant Isolation / Shop Context

- `ActiveShopContext` is the single authoritative tenant binding (fail-closed);
  queue entries execute strictly under their persisted `shop_id`, never ambient
  (`active_shop_context.dart:76-81`). Transport (A1) MUST scope every call by
  `entry.shop_id` and treat a bound-context mismatch as an error (no fallback).

---

## 14. Idempotency Discipline

- Client: one occurrence token per logical op persisted in
  `sync_queue.occurrence_token`; key = `entityType:entityUuid:operation:
  occurrenceToken`.
- Server: `phase_m_idempotency_lookup/record` inside the same transaction as the
  business mutation; invoice-level key covers the whole effect set.
- A5 must prove exactly-once across reconnect/retry and mark replays SYNCED
  without re-execution.

---

## 15. Observability Discipline

- Statuses truthful: no "synced" for queued/failed; OVERSOLD surfaces as
  `requires-reconciliation`; transport-unavailable distinct from offline.
- Recovery sweep on startup (M-I05) remains the restartability contract.

---

## 16. Known Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Migration-28 production absence | §7.16 gate probe before drain reliance |
| Clock skew on observed events | Server clamps future `observed_at` to `now()` (IC-1); audit surfaces skew |
| Connectivity source is session-derived, no `connectivity_plus` | Keep drain gated on `isCloudLinked && isOnline` + license; transport errors → FAILED + retry |
| Idempotency token loss across uninstall/reinstall | writerSnapshot + stable cloud_uuid; server idempotency log is the backstop |
| Oversell reconciliation vs manual counts | Additive adjustment artifacts; counters never rewritten |
| Release build flips drain unintentionally | Activation only via documented owner-signed build override |

---

## 17. Completion Criteria / Exit Definition

This session completes with:
1. This artifact replacing `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` absence in the
   tree (single tracked delta).
2. Sacred artifacts byte-identical (PRE == POST, §3.3 hashes).
3. Local commit `Plan Phase P owner-gated Group A` (no push, no tag).
4. AHEAD=1 / BEHIND=0 after commit.
5. Token `PASS_PHASE_P_OWNER_GATED_GROUP_A_PLANNING_LOCAL_READY`, next session
   `PHASE_P_OWNER_GATED_GROUP_A_PLANNING_REMOTE_LOCK`.

Out-of-scope for every Group A session: implementing A1..A8, flipping the drain,
deploying any migration, pushing/tagging, touching Group B/C/D artifacts, and
altering frozen identifiers or sacred artifacts.

---

## 18. Traceability to Session Requirements

- This artifact covers the required planning surface: decision records (P-OD1,
  P-OD7), evidence gate, slice evaluations (A1..A8), proposed order, quality
  gates, security/RLS, migration/restore compatibility, tenant isolation,
  idempotency, observability, risks, completion criteria, sacred-artifact
  verification, and explicit out-of-scope discipline.

---

## 19. Sacred-Artifact Verification (session record)

Session entry (PRE) — all four verified, byte-identical to §3.3 table. Session
end (POST) re-verification occurs after the commit in §20; findings are recorded
in the final session report. Any delta would abort the token.

---

## 20. Execution Record (filled by this session)

```text
ENTRY CLASSIFICATION  = CASE_A_FRESH
PLAN ARTIFACT WRITTEN = PHASE_P_OWNER_GATED_GROUP_A_PLAN.md  (this file)
DIFF PROFILE          = 1 added file, 0 modified, 0 deleted (tracked)
SACRED PRE  = 3D4D17… / C8C5BD… / 70F848…  ✓ (see §3.3 for full values)
SACRED POST = <recorded after commit>
COMMIT      = <set after commit>
AHEAD/BEHIND= <1/0 after commit, verified>
SESSION TOKEN = <minted after commit>
```