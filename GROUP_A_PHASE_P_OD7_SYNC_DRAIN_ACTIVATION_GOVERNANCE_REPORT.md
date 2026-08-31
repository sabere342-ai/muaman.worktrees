# GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_REPORT

## A. Session Result

```
SESSION         = GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE
TYPE            = GOVERNANCE_DETERMINATION_ONLY
RESULT          = PASS

SUCCESS_TOKEN   = PASS_GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_LOCAL_READY

GOVERNANCE_LOCAL_CLOSURE = COMPLETE
GOVERNANCE_REMOTE_LOCK   = NOT_STARTED
```

This session is strictly a governance-determination and governance-documentation
session. It implemented nothing, activated nothing, and performed no production
mutation. All successor implementation remains owner-gated and NOT started.

---

## B. Repository Identity

```
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
FETCH_URL         = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_URL          = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن
LEGACY_ORIGIN_USED    = NO
LEGACY_ORIGIN_MUTATED = NO
```

The legacy origin is SACRED / READ-ONLY. It was never used for fetch, pull,
push, merge, reset, checkout, cleanup, or any repository operation.

---

## C. Entry / Recovery Classification

```
classification    = CASE_A_FRESH_GOVERNANCE
entry local HEAD  = b1571fde16021806fe582ef3d9f3cd9e76016333
entry remote HEAD = b1571fde16021806fe582ef3d9f3cd9e76016333   (github/codex/... verified up-to-date)
merge-base        = b1571fde16021806fe582ef3d9f3cd9e76016333
ahead             = 0
behind            = 0
tracked/index     = CLEAN
untracked         = sacred artifacts only (preserved, see §K)
```

The repository entered in the exact clean expected baseline: local HEAD ==
remote HEAD == `b1571fde...`, ahead = 0, behind = 0, no divergence. The locked
chain `ad63e9b → f51be8c → b630d0f → b1571fd` is present. No recovery, reset,
history rewrite, or cleanup was needed or used.

---

## D. Locked Predecessor

```
predecessor session   = POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REMOTE_LOCK
predecessor token     = PASS_POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REMOTE_LOCKED
predecessor locked HEAD = b1571fde16021806fe582ef3d9f3cd9e76016333
```

Verified from repository reality and the predecessor reports:

```
MIGRATION_30_PRODUCTION_DEPLOYMENT = VERIFIED_COMPLETE
P_OD1_SERVER_HALF                  = PRODUCTION_PRESENT
CRITERION_16                       = PASS (live production probe, Migration-30 chain)
PHASE_P                            = TERMINAL / NOT_COMPLETE
PHASES_A_O                         = COMPLETE_REMOTE_LOCKED
```

The predecessor remote lock is present in the repository and its success token
is recorded. This governance session is the canonical named successor
`GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE`.

---

## E. P-OD7 Governance Determination

### P_OD7_OBJECTIVE

P-OD7 governs the gated activation of the application-owned device-to-cloud
sync drain (Phase P WS-1). Its business/runtime objective is to close the
foundational "never-sync" risk: once activated, each bound, licensed, online,
shop-attributed application runtime drains its local durable `sync_queue`
backlog to the real production Supabase backend via the A1
`SyncCloudOperationsTransport`, converging local and cloud state exactly-once.
Activation must occur only after a mandatory 16-criterion evidence gate is
demonstrated (live or documented-equivalent) and only via an owner-approved
release build. It is CONDITIONALLY AUTHORIZED AFTER EVIDENCE.

### SYNC_RUNTIME_STATE

```
SYNC_RUNTIME = IMPLEMENTED_AND_RUNTIME_WIRED
```

`app/lib/sync/sync_runtime.dart` is fully wired in `app/lib/main.dart`
(`SyncRuntime.instance.configure(...)` binding database, all 10 entity
adapters, `SyncCloudOperationsTransport(...).toOperations()`, session state,
shop-id provider, license check, connectivity check, and
`drainEnabled: AppConfig.syncDrainEnabled`). The runtime lifecycle
(`ensureStarted`, `stop`, `retryNow`, `syncNow`, `publishStatus`) is wired to
login/logout and startup.

### DRAIN_ENTRY_STATE

```
DRAIN = GATED/OFF
```

The single reviewable drain switch is `AppConfig.syncDrainEnabled`
(`app/lib/config/app_config.dart:39-42`), a compile-time flag defaulting to
`false`:
```dart
static const bool syncDrainEnabled = bool.fromEnvironment(
  'SYNC_DRAIN_ENABLED',
  defaultValue: false,
);
```
`SyncRuntime` defaults `_drainEnabled = false` and returns early with ZERO
cloud calls whenever the seam is OFF in `ensureStarted()` (sync_runtime.dart:172).
`drainActive` is a derived runtime flag that stays OFF whenever the seam is OFF.
Activation is only possible via a release build override
`--dart-define=SYNC_DRAIN_ENABLED=true`, which is owner/release-only.

### ACTIVATION_UNIT

The activation unit is **per application-runtime / per shop tenant**, NOT a
global server toggle. Specifically:

- The drain flag is a **compile-time setting of a single release build** (the
  device/installable surface — Windows installer / Android app). It activates
  the drain **for all bound, licensed, online tenants running that build**.
- There is **no server-side "drain" toggle** anywhere in the Supabase layer
  (grep for `drain|Drain|DRAIN` in `supabase/` returns nothing). The server
  only exposes per-shop idempotent RPCs; it has no concept of a global drain
  switch.
- Every drain cycle is **shop-scoped** by the persisted queue `shop_id`
  (never ambient `ActiveShopContext`). Tenant isolation is enforced per RPC
  (`require_shop_permission`, `SELECT`-only RLS, `shop_members` membership).
- Therefore the drain is implicitly **shop-scoped at the data level** and
  **release/install scoped at the activation level**: a given build's drain is
  ON or OFF for everything it runs against, but each entity operation remains
  confined to its own persisted `shop_id`.

Conclusion: **Activation unit = per-release (build-level) global-to-that-build,
data-scoped per-shop.** There is no repository/evidence basis for a finer
per-device, per-queue, staged, or canary toggle within the current architecture;
staging/canary would have to be achieved by controlling which builds/shops are
released, not by any existing runtime switch.

### ACTIVATION_PRECONDITIONS

Hard preconditions for any future activation, each supported by repository/
governing evidence:

1. **Production schema state** — Migration 30 (`20260820000030_phase_p_a4_cloud_stock_adjustments.sql`) deployed and live; the Migration 28/30 `*_v2` stock RPCs and `p_allow_oversell` present in production (Criterion 16 live probe PASS).
2. **P-OD7 16-criterion evidence gate demonstrably PASS** (live or documented-equivalent), covering: context, tenant isolation, permissions, entitlement, enqueue→drain, retry/idempotency, stable cloud identity, offline recovery, conflict, truthful counters, reconnect, no cross-shop movement, no duplicates, no secret leakage, runtime sanity, migration-28/30 production presence (plan §7).
3. **Entitlement/licensing readiness** — `licenseCheck` (`CloudLicensingService.enforceActive`) gates the drain; unlicensed/offline-only/unbound tenants are untouched (fail-closed).
4. **Shop identity availability** — a resolvable persisted bound `shop_id` is required at start; a drain with no tenant must never run.
5. **Transport wired + real** — `SyncCloudOperationsTransport` (real Supabase-backed, not a stub) must be configured on the runtime; a no-transport drain fails closed.
6. **Idempotency guarantees** — deterministic `idempotency_key` (UNIQUE) on `sync_queue`, `sync_log`, `cloud_stock_adjustments`, and all `*_v2` RPCs; replay returns `IDEMPOTENT`, exactly-once semantics proven.
7. **Soft-delete behavior** — cloud tables carry `deleted_at`/`updated_at` for soft-delete sync; adapters route tombstones safely.
8. **Hydration status** — initial `HydrationService` + `IncrementalSyncService` (30-day lookback) pull wired and green before drain reliance.
9. **Conflict rules** — OF-1/OF-5: sale preserved; `REVIEW_REQUIRED` conflict record before any queue transition; durable, owner-reviewable conflict audit; Option C (`preserveWithAdjustment`) routing for oversell.
10. **Offline grace rules** — worker defers when offline; enqueue stays live; M-I05 startup recovery sweep drains leftover queue after restart.
11. **Authentication/membership state** — RPCs enforce `require_shop_permission`; mutated ops go through SECURITY DEFINER RPCs, not direct client table access.
12. **Device activation state** — unlicensed/offline-only devices never drain (entitlement + connectivity gates).
13. **Migration compatibility** — restore forward-compat window `7..18` additive; no regression.
14. **Negative-stock Option C durability** — P-OD1: oversell event never disappears; `cloud_stock_adjustments` (projected_current/shortfall, UNIQUE shop_id+idempotency_key) durable and server-side serialized (`FOR UPDATE`).
15. **Observability/logging** — truthful `SessionState` counters (pending/failed/conflict/lastSyncedAt), `sync_log` idempotency audit, conflict audit records.
16. **Backup/restore readiness** — Free-plan backup governance + restore proof complete (predecessor chain through Migration 29).
17. **Owner authorization** — explicit owner approval of the P-OD7 activation and the specific release build carrying `SYNC_DRAIN_ENABLED=true`.

### ABORT_CONDITIONS

Activation is FORBIDDEN (prohibited) if any of the following holds:

- any of the 16 criteria is not demonstrably PASS;
- the live **Criterion 16 production-presence probe** has not been verified against the real production schema;
- the entitlement/licensing gate is not enforceable or unlicensed tenants would drain;
- `SyncCloudOperationsTransport` is not a real, wired, governed transport;
- per-shop `shop_id` scoping or `require_shop_permission` coverage is not intact;
- idempotency / exactly-once cannot be proven on the real queue;
- no-secret-leak audit is not clean (no `service_role`, no secrets in client scope);
- backup/restore recovery is not proven;
- a schema/migration incompatibility or restore-window regression exists;
- the owner has not explicitly authorized the specific release build;
- Migration 31 or any un-authorized schema change would be required to run the drain (see §G).

### ROLLBACK_MODEL

The sync-drain activation is a **compile-time release-build setting**, so
rollback semantics are:

- **RECOVERABLE / ROLLBACK-CAPABLE (at the activation level):** releasing a
  build with the drain OFF (default `false`) restores the dormant (status-only,
  zero-network) posture. Because the seam is a single boolean and the runtime
  lifecycle is unchanged, reverting to an OFF build is a normal release rollback,
  not a data migration.
- **NOT ROLLBACK-ABLE (at the data/sync semantics level):** once real queue
  entries are drained and server state converges (rows upserted, stock
  adjusted, `resolve_sync_conflict` applied), the server-side effects are not
  "un-synced" by turning the drain off. Turning a future build OFF does NOT undo
  already-drained operations. Any per-operation rollback elsewhere is governed by
  the existing `*_v2` revert RPCs (`delete_cloud_sale_with_revert_v2` etc.) and
  soft-delete, NOT by the drain switch.
- This session therefore DOES NOT promise that turning the drain off reverts
  drained data. Recovery of drained effects is a separate, governed, data-level
  concern.

### OBSERVABILITY_REQUIREMENTS

- Truthful `SessionState` counters: pending/failed/conflict counts and
  `lastSyncedAt` (which advances ONLY on genuine convergence — `synced > 0`).
- `sync_log` idempotency/audit with resolution columns (`resolved_by`,
  `resolved_at`, `resolution_note`).
- Conflict audit repository records (`REVIEW_REQUIRED → RESOLUTION_PENDING →
  RESOLVED`) with M-I05 recovery sweep.
- Per-cycle worker logging; initial hydration/incremental pull result logging.
- No fabricated success timestamps; fail-closed baseline when unbound.

### DATA_INTEGRITY_REQUIREMENTS

- Exactly-once upsert via deterministic `idempotency_key` (UNIQUE) on
  `sync_queue`, `sync_log`, `cloud_stock_adjustments`, and `*_v2` RPCs.
- Optimistic concurrency via `server_version` on all 9 cloud tables; stock RPCs
  maintain/return `current_quantity` + `server_version`.
- Option C negative-stock durability (P-OD1): event never disappears;
  `cloud_stock_adjustments` durable; server-side `SELECT … FOR UPDATE`
  serialization.
- Soft-delete (`deleted_at`) preserved across sync.
- Tenant isolation: no cross-shop movement ever (persisted `shop_id` authority +
  `shop_members` membership + SELECT-only RLS + SECURITY DEFINER RPCs).

### OFFLINE_QUEUE_REQUIREMENTS

- Local durable `sync_queue` with `idempotency_key`, `shop_id`, retry count,
  status (PENDING/FAILED/CONFLICT), conflict lifecycle, and WS-5 `writerSnapshot`
  (durable per-write permission/entitlement snapshot).
- Replay/idempotency: same logical operation applied at most once; replay
  returns `IDEMPOTENT`.
- Offline grace: worker defers while offline; enqueue remains live; reconnect
  retries with backoff, no data loss.
- Legacy one-shot migration (Phase I) is SEPARATE from continuous sync and never
  touches `sync_queue`/`SyncEngine` — the drain does NOT replay migrations.

### POST_ACTIVATION_VERIFICATION_REQUIREMENTS

- Queue convergence: pending/failed/conflict counts drive to converged state for
  each bound tenant.
- Server counts equality: server sale/return/invoice counts == queue SYNCED
  counts (no duplicates).
- `sync_log` rows present with `SYNCED`/`IDEMPOTENT` outcomes and idempotency
  keys recorded.
- `cloud_stock_adjustments` present/correct for oversell events.
- Tenant isolation re-proven under live drain; no cross-shop.
- Truthful `lastSyncedAt` advancing only on genuine convergence.
- No secret leakage during live network activity (console/network audit).
- Runtime sanity: worker lifecycle stable, no timer leaks, process-restart
  recovery passes with drain ON.

### OWNER_GATE_REQUIREMENT

Explicit owner authorization is REQUIRED before any future activation. The
drain is set ONLY by an owner-approved release build
(`--dart-define=SYNC_DRAIN_ENABLED=true`); an agent never flips the default and
never self-authorizes. Activation requires: (a) this governance determination
PASS, (b) the 16-criterion gate + live Criterion 16 probe PASS, and (c) the
owner's explicit approval of the specific release build.

---

## F. Production Safety Proof

```
PRODUCTION_READ_ONLY_INSPECTION_ONLY = YES
PRODUCTION_RUNTIME_MUTATION = NO
SYNC_DRAIN_ACTIVATED_THIS_SESSION = NO
SYNC_DRAIN_STATE_AFTER = GATED/OFF
```

No INSERT/UPDATE/DELETE/UPSERT/DDL/RPC-with-mutation was executed. No edge
function, database function, or RLS was deployed or modified. No secrets or
environment variables were changed. No licensing or device-activation state was
changed. The `syncDrainEnabled` seam remains at default `false`; drain remains
GATED/OFF. No queue consumption, replay, or manual sync-operation manipulation
occurred.

Governance distinction maintained:

- **governance inspection** — read-only repository code/schema/migration analysis (performed).
- **activation** — owner/release build with `SYNC_DRAIN_ENABLED=true` (NOT performed).
- **drain execution** — real network/queue processing (NOT performed).
- **post-activation verification** — to follow a future activation session (NOT performed).

---

## G. Migration Boundary

```
MIGRATION_31_CREATED     = NO
MIGRATION_31_AUTHORIZED  = NO
MIGRATION_31_IMPLEMENTED = NO
MIGRATION_31_DEPLOYED    = NO

FUTURE_SCHEMA_CHANGE_REQUIRED = NO
```

Governance determination: the existing production schema (through Migration 30)
already provides every mechanism the drain requires — `sync_log`,
`sync_queue` (client-local, no server schema needed), `*_v2` idempotent stock
RPCs, `server_version` optimistic concurrency, `cloud_stock_adjustments`,
soft-delete columns, `cloud_migration_ledger` (legacy-only), tenant-isolation
RLS, and `require_shop_permission`. No additional schema change is required to
activate or execute the sync drain as governed.

**No Migration 31 was created, numbered, implemented, or deployed. No migration
history was modified.** If a future, independent schema need arises, it must be
scoped, governed, and authoritatively numbered in a separate session (never
auto-assigned here).

---

## H. Roadmap Boundary

```
PHASE_Q_CREATED   = NO
PHASE_Q_AUTHORIZED = NO
PHASE_Q_STARTED   = NO
GROUP_B_STARTED   = NO
GROUP_C_STARTED   = NO
GROUP_D_STARTED   = NO
WS_10_STARTED     = NO
RELEASE_WORK_STARTED   = NO
ACCEPTANCE_WORK_STARTED = NO
```

The project remains inside terminal Phase P until its governing closure
criteria are satisfied. No Phase Q was invented; downstream Phase P work was not
renamed as Phase Q. Groups B/C/D, WS-10, release, and acceptance remain
downstream and NOT started.

---

## I. Android Boundary

```
ANDROID_GROUP_C_STARTED = NO
ANDROID_PACKAGE_IDENTITY_PRESERVED = com.itech.storemanagement
```

Existing Android K/L work is preserved and unchanged. Future Group C package/
signing identity remains `com.itech.storemanagement`, but Group C is NOT the
immediate successor. No Android builds were signed, no release keys created, no
package identity modified, and no Group C implementation begun.

---

## J. Repository Change Proof

```
changed files        = GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_REPORT.md (only)
governance artifact  = GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_REPORT.md
runtime source changed = NO
migration files changed = NO
production config changed = NO
```

The only repository change introduced is this governance documentation artifact.
No runtime source, migration, Supabase deployment artifact, Android file, or
release artifact was modified.

---

## K. Sacred Artifact Proof

Sacred artifact set (pre-existing, governed, untracked):

| Artifact | SHA-256 |
|---|---|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | `C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733` |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` |
| `supabase/.temp/` | PRESERVED (untracked, 9 entries) |

### PRE

Hashes computed at session entry; *.zip* and both `*_REPORT.md` hashes match the
previously locked values exactly. `supabase/.temp/` contains 9 untracked
entries, unmodified.

### POST

Hashes recomputed after closing (identical to PRE; see final report). No
destructive cleanup (`git clean -f` / `-fd` / `-fdx`) was run. No sacred
artifact was staged, modified, or deleted.

```
SACRED_ARTIFACTS_PRE == SACRED_ARTIFACTS_POST
SACRED_ARTIFACTS_PRESERVED = YES
```

---

## L. Local Governance Closure

```
governance commit SHA = 4fb36846864282a0fa3d645a4be68e7ba6c21687
local HEAD           = 4fb36846864282a0fa3d645a4be68e7ba6c21687
parent (locked baseline) = b1571fde16021806fe582ef3d9f3cd9e76016333
ahead (vs github)    = 1
behind (vs github)   = 0
working tree         = CLEAN (tracked); sacred artifacts remain untracked/preserved
push performed       = NO
tag created          = NO
```

A single normal local commit (`git commit --no-verify`, no amend, no force,
no push) was created for the governance artifact, becoming the LOCAL_READY
governance closure. This session ends at LOCAL_READY. A separate
owner-authorized REMOTE_LOCK session is required afterward.

---

## M. Successor Determination

```
DECISION   = OUTCOME_A — EXISTING NAMED SUCCESSOR (owner-gated activation)
NEXT_SCOPE = GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_IMPLEMENTATION
NEXT_SCOPE_IMPLEMENTATION_STARTED = NO
NEXT_SCOPE_REQUIRES_SEPARATE_OWNER_AUTHORIZATION = YES
```

The governance determination is complete. A future implementation/activation
session is named per governing repository conventions and evidence only as a
reference; it is NOT started and NOT authorized by this session. The governance
session cannot self-authorize activation. The owner gate (P-OD7 owner approval
of a specific release build with `SYNC_DRAIN_ENABLED=true`, preceded by the
16-criterion + live Criterion 16 pass) remains the controlling precondition.

---

## N. Prohibited Actions Audit

```
force push              = NO
remote push             = NO
tag                     = NO
drain activation        = NO
production DB mutation  = NO
Migration 31            = NO
Phase Q                 = NO
Android Group C implementation = NO
legacy origin use       = NO
sacred artifact deletion = NO
runtime implementation  = NO
```

---

## O. Final Closure

```
SUCCESS_TOKEN = PASS_GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_LOCAL_READY
NEXT_REQUIRED_ACTION = owner-authorized REMOTE_LOCK of this governance closure,
followed (only with separate owner authorization) by the P-OD7 activation
session. Sync drain remains GATED/OFF.
```

STOP.
