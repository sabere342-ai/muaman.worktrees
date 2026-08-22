# PHASE J — WINDOWS CLOUD TRANSITION PLAN (IMPLEMENTATION-GRADE)

**Status:** PLANNING FROZEN — implementation not started in this session
**Branch:** `codex/i-tech-next-roadmap-freeze`
**Governing baseline (parent):** `986f0dde659233e9868b232996a777ae6b3e5fda` (`Phase I: implement legacy data migration`, PHASE_I_FINAL_CLOSURE = COMPLETE)
**Forensic discovery:** CLOSED (recovered from prior interrupted session; reconfirmed against current worktree evidence)
**Rule of this phase:** planning documentation only. No Dart/SQL/test/backup/invoice changes are made here.

---

## A. Executive Summary

Phase J is the canonical **Windows Cloud Transition**: the Windows desktop application stops being a purely local SQLite product and becomes a cloud-connected, shop-scoped client of the Supabase backend established in Phases C–I, while preserving offline-first behavior.

The dominant security workstream inside Phase J is **local/query-level tenant isolation**: today every read, update, delete, search, barcode lookup, duplicate check, dashboard aggregate and report in `DatabaseHelper` operates over the whole local database with no `shop_id` predicate. All tenant-owned tables already carry an additive `shop_id TEXT` column (schema v14 foundations), the sync queue already stamps `shop_id`, and the Phase I migration already assigns legacy rows to the licensed shop. What is missing is the enforcement layer: every tenant-owned query must become shop-scoped.

This plan freezes the contracts (read isolation, write isolation, shop/session context, uniqueness, migration handoff, sync handoff, backup/restore impact, schema decision) and a dependency-ordered set of nine implementation workstreams, plus the security-negative test matrix that future implementation must pass. Local tenant filtering is defense-in-depth; it does NOT replace Supabase RLS, server RBAC, membership validation, or licensing enforcement.

**SCHEMA_CHANGE_REQUIRED = NO.** The v14 additive foundations (`shop_id`, `cloud_uuid`, `server_version`, `sync_status*`, `sync_queue`, `legacy_migration_progress`) are structurally sufficient for query-level isolation. The single structural caveat — the GLOBAL `UNIQUE` constraint on `products.barcode` — is classified OWNER_DECISION_REQUIRED and must not be silently changed.

---

## B. Governing Authority

| Source | Authority used |
|---|---|
| `PROJECT_MASTER_PLAN.md` §13 line 219 | **Canonical phase definition:** "J \| Windows Cloud Transition \| Windows app transitions to cloud architecture" |
| `PROJECT_MASTER_PLAN.md` §12 Frozen Compatibility Register | DB filename, table names, column names, app_settings keys, permission IDs, role names FROZEN (add-only); DB schema version incrementable per-phase |
| `PROJECT_MASTER_PLAN.md` §8/§9 | Hybrid ID strategy (UUID cloud / integer local), additive schema, soft delete, idempotency, fail-closed authorization |
| `PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md` lines 143–152, 318, 344–347 | Explicit deferrals to Phase J: all queries lack tenant filter (QUERY-LEVEL); logo filename hardcoded; AppSettings keys global; CleanStartService global wipe; dashboard aggregates all data |
| `PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md` line 231 | "Local SQLite query filtering by shop_id → Phase J" |
| `PHASE_G_CLOUD_DATA_FOUNDATION_PLAN.md` §32.1 | "Phase G creates cloud infrastructure. Phase J redirects Windows UI from local SQLite to cloud." |
| `PHASE_H_OFFLINE_SYNC_CORE_PLAN.md` line 279 | Sync handoff into Phase J cloud-first behavior |
| `PHASE_I_LEGACY_DATA_MIGRATION_PLAN.md` + locked implementation `986f0dd` | Legacy row → shop assignment, snapshot/preflight/reconciliation contract |

Governing-plan wording wins over any informal sentence. The historical sentence "query-level tenant filtering was deferred to Phase J" is honored as a **workstream inside** this phase, not as a rename of it.

---

## C. Repository / Baseline Identity

```text
REPOSITORY_ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
REMOTE_NAME       = github  (https://github.com/sabere342-ai/muaman.worktrees.git)
GITHUB_REPOSITORY = sabere342-ai/muaman.worktrees

PLANNING_PARENT (expected) = 986f0dde659233e9868b232996a777ae6b3e5fda
PHASE_I_IMPLEMENTATION     = Phase I: implement legacy data migration
PHASE_I_FINAL_CLOSURE      = COMPLETE

LOCAL_SCHEMA_VERSION       = 14  (app/lib/database/database_helper.dart:312)
APP_DIR                    = app/  (Flutter, sqflite_ffi on Windows)
```

Entry state verified this session:

```text
git status --porcelain : only preserved untracked artifacts
  ?? MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  ?? delivery/I-TECH-Delivery-v1.0.0.zip
git stash list         : stash@{0} (pre-existing, unrelated branch) — UNTOUCHED
index                  : CLEAN
```

Preserved-artifact contract: the two untracked artifacts above remain untracked and untouched; they are NOT staged by the planning commit.

---

## D. Phase I Handoff (LOCKED BASELINE)

Phase I (`986f0dd`) delivered, and Phase J must treat as frozen inputs:

1. **Legacy row shop assignment.** `migration/preflight_service.dart` classifies rows with `cloud_uuid IS NULL` into attributed (`shop_id = <licensed shop>`) vs unattributed (`shop_id IS NULL`) and rejects foreign-shop contamination (`WHERE cloud_uuid IS NULL AND shop_id IS NOT NULL AND shop_id != ?`). The single licensed shop ADOPTS all NULL-shop legacy rows during migration.
2. **shop_id nullability in migrated tenant data.** After a completed migration, tenant-owned rows carry either their correct `shop_id` or were adopted by the single licensed shop. NULL `shop_id` is legal ONLY for pre-migration local-only states; Phase J filtering must define its treatment of residual NULLs explicitly (Section N).
3. **Reconciliation.** `reconciliation_service.dart` recounts per-table census filtered by `(cloud_uuid IS NULL) AND (shop_id IS NULL OR shop_id = ?)` against the pinned snapshot; totals must match before stamping.
4. **Partially migrated databases.** `legacy_migration_progress` (schema v14, keyed `shop_id`) tracks non-terminal batches (`status NOT IN ('COMPLETED','ABORTED')`); resume is per-shop via `latestNonTerminalBatch(shopId)`. `MigrationMaintenanceMode` blocks business writes while active.
5. **cloud_uuid continuity.** Migration writes server-side UUIDs via RPC (`p_shop_id` parameterized), preserving integer PKs locally (master plan §8 hybrid ID strategy).
6. **Snapshot integrity.** Pre-migration backup is a self-created verified SQLite snapshot (`snapshot_service.dart`), not `StandaloneRestoreService` (which still accepts only `user_version 7|8` — confirmed Phase I defect, out of scope here except WS7).

**Handoff gate for Phase J:** strict shop-scoped reads may be activated only when every tenant-owned table satisfies "no legitimate row of the active shop carries a shop_id that excludes it". The enforcement precondition is defined in Section N (NULL-treatment policy + post-migration verification query).

---

## E. Canonical Phase J Definition

```text
PHASE_J_CANONICAL_NAME   = Windows Cloud Transition
PHASE_J_CANONICAL_PURPOSE= Transition the Windows desktop app from local-only
                           SQLite architecture to cloud-connected architecture:
                           Supabase-backed identity/membership/licensing/RBAC
                           become the operating context, the local SQLite store
                           becomes a tenant-scoped operational cache, and
                           offline-first sync (Phase H) remains the availability
                           guarantee.
PHASE_J_SCOPE            = (1) Active shop/tenant context contract
                           (2) Query-level local tenant isolation (reads)
                           (3) Mutation-level local tenant isolation (writes)
                           (4) Search / lookup / aggregate / report isolation
                           (5) Sync tenant integration hardening
                           (6) Phase I migration safety handoff enforcement
                           (7) Backup/restore/import tenant safety
                           (8) Security-negative test coverage
                           (9) Regression + documentation closure
```

Explicitly absorbed deferrals (governing evidence):

| Deferred gap | Origin | Phase J treatment |
|---|---|---|
| All queries lack tenant filter (`database_helper.dart`, 50+ methods) | Phase B #3, Phase C #17 | WS2/WS3/WS4 |
| Dashboard aggregates all data (`getDashboardData` ~line 1909, `getSalesSummary`, group-by reports) | Phase B #12 | WS4 |
| AppSettings keys global (`app_settings.dart`) | Phase B #7 | WS1 (shop-profile keys already flow through `shop_settings_sync_adapter`; non-shop system keys stay global by classification) |
| CleanStartService global wipe (`clean_start_service.dart`) | Phase B #10 | WS3/WS7 (per-shop wipe semantics; global wipe remains an owner-only destructive action with explicit confirmation) |
| Logo filename hardcoded (`shop_profile_service.dart`) | Phase B #6 | WS1 (shop-profile key namespace under cloud transition; no aesthetic refactor) |

**NOT in canonical scope:** Android onboarding (K), seller flows (L), inventory conflict hardening (M), Excel import (N), invoice branding (O), production hardening (P).

---

## F. Current-State Forensics

All facts below were verified against the current worktree at `986f0dd`:

### F.1 Shop/session context today
- `SessionState.activeShopId` derives from `CloudSession.activeShopId` (`services/session_state.dart:32`). Null when not cloud-linked/offline.
- `ShopResolver.resolveActiveShop()` resolves via `get_user_shops()` RPC, auto-selects single membership, persists last-used as AppSettings key `cloud.lastShopId` (`services/shop_resolver.dart:38–91`).
- `DatabaseHelper.setSyncShopIdProvider()` registers a startup callback used to attribute writes/sync entries to the active shop (`database_helper.dart:93–100`); `_resolveSyncShopId` prefers provider over row value (`database_helper.dart:145–152`).

### F.2 Tenant-owned tables and shop_id presence
All of the following carry additive `shop_id TEXT` columns (created v9/v13/v14): `products`, `sales`, `returns`, `expenses`, `expense_categories`, `customers`, `invoices`, `inventory_count`, plus `app_settings` (shop-profile key rows), `sync_queue(shop_id)` indexed, `legacy_migration_progress(shop_id NOT NULL)`.

Non-tenant/system tables (MUST NOT be shop-filtered blindly): `users`, `role_permissions`, `import_batches`, `sync_queue` internals, licensing caches.

### F.3 Read scoping gaps (CONFIRMED)
No read path in `DatabaseHelper` applies a `shop_id` predicate: list queries, `id = ?` lookups, `getProductByBarcode` (`barcode = ?`), name lookups, duplicate checks (`SELECT id FROM products WHERE trim(barcode) = ?`), date-range sale queries, dashboard `getDashboardData()`, `getSalesGroupByDate/Product`, `getSalesSummary`, expense category usage counts — all scan the whole store.

### F.4 Write scoping gaps (CONFIRMED)
Updates/deletes/upserts match by local numeric id or barcode alone (`WHERE id = ?`, `WHERE barcode = ?`); inserts never stamp `shop_id` locally outside the sync-enqueue path; soft-delete/sync-status updates are unscoped.

### F.5 Sync tenant behavior (PRESENT — must be preserved)
- Queue entries persist `shop_id` (`sync_queue_repository.dart`, indexed).
- `SyncEngine` reads `_shopIdProvider()` once per cycle and drains ONLY `getPendingEntries(shopId:)` (`sync_engine.dart:60–71`) — queued work from Shop A cannot execute under Shop B while this contract holds.
- Hydration/incremental sync stamp `'shop_id': shopId` into applied rows (`hydration_service.dart:80`, `incremental_sync_service.dart:86`).
- `runWithoutSyncEnqueue` prevents cloud→local→queue echo loops (`database_helper.dart:106–113`).

### F.6 Migration handoff (see Section D) — locked.
### F.7 Backup/restore implications
- `StandaloneRestoreService._validateBackup` accepts only `user_version 7|8`; restored legacy DBs replay upgrades to v14 with NULL `cloud_uuid`/NULL `shop_id` rows. Restore therefore RE-INTRODUCES unattributed tenant rows after a completed migration — Phase J must define restore-time attribution policy (Section P).
- Import paths (`workbook_importer.dart`, `data_importer.dart`) write tenant rows without shop stamping — WS7.
### F.8 Uniqueness behavior
- `products.barcode TEXT UNIQUE NOT NULL` (global constraint, `database_helper.dart:320`). Other tables' barcode columns are plain `TEXT NOT NULL`. Invoice numbers and customer names are checked application-side without tenant predicates.
### F.9 RLS/RBAC relationship
Server-side enforcement lives in Supabase RLS (Phases C/G migrations incl. `20260820000027_phase_i_legacy_migration.sql`) and server RBAC (Phase F). Local filtering is additive defense-in-depth only.

---

## G. Gap Analysis

| # | Gap | Severity | Workstream |
|---|---|---|---|
| G1 | No active-shop context object usable by the data layer (only ad-hoc providers for sync enqueue) | HIGH | WS1 |
| G2 | All tenant reads unscoped → full cross-shop read leakage in multi-shop installs | CRITICAL | WS2 |
| G3 | Updates/deletes match by bare local id/barcode → cross-shop mutation by ID guess | CRITICAL | WS3 |
| G4 | Inserts/upserts do not stamp active shop; upsert collisions possible across shops | HIGH | WS3 |
| G5 | Search, barcode lookup, duplicate checks leak other shops' records | HIGH | WS4 |
| G6 | Dashboard/report aggregates include all shops' money data | HIGH | WS4 |
| G7 | Global `products.barcode UNIQUE` forbids legitimate per-shop barcodes once multi-shop data coexists | DECISION | Z (owner) / WS3 conditional |
| G8 | Restore/import re-introduce NULL-shop rows post-migration | MEDIUM | WS7 |
| G9 | Clean start wipes globally regardless of active shop | MEDIUM | WS3/WS7 |
| G10 | No negative tests exist for any cross-shop scenario | HIGH | WS8 |

---

## H. Cross-Tenant Threat Model

Format per threat: PREVENTION_BOUNDARY / EXPECTED_TEST / FAILURE_MODE.

| Threat | Prevention boundary | Expected test | Failure mode if violated |
|---|---|---|---|
| Shop A lists Shop B products/sales/purchases/customers/suppliers(expenses)/expenses | Mandatory `shop_id = :active` predicate on every tenant-owned SELECT (WS2) | Negative list tests per table | Data leakage across tenants |
| Cross-shop read by numeric ID (`getProductById(id)`, invoice/sale/return/customer/expense lookups) | Predicate `id = ? AND shop_id = ?` (or post-fetch ownership assertion where join shape demands) | Fetch-B-row-as-A returns null/not-found | Silent cross-tenant record disclosure |
| Search leakage (product/customer name search) | Same scoped predicate inside LIKE searches | Search-B-term-as-A yields empty | Enumeration of B's catalog |
| Barcode lookup leakage (`getProductByBarcode`) | Scoped barcode query | B barcode scanned in A → "not found" | Wrong product priced/sold in A |
| Invoice lookup leakage | Scoped invoice number/id resolution | B invoice number opens nothing in A | Wrong financial document shown |
| Duplicate-check leakage | Duplicate checks run within ACTIVE shop scope only (per approved uniqueness decision, Section M) | Duplicate allowed across shops iff owner chose PER_SHOP; blocked within shop | False duplicates block legit entry, or false uniqueness across tenants |
| Dashboard aggregate leakage (`getDashboardData`, sales summary) | Aggregates computed over scoped subquery | Seeded A+B data → totals equal A-only | B revenue visible in A |
| Report aggregation leakage (group-by date/product) | Same scoping in GROUP BY sources | Report rows contain no B entities | Cross-shop analytics leakage |
| Cross-shop UPDATE by local id | `UPDATE ... WHERE id = ? AND shop_id = ?` (+ ownership assert) | Update-B-id-as-A is no-op/error | Tampering with B inventory/prices |
| Cross-shop DELETE by local id | Same predicate on DELETE/soft-delete | Delete-B-id-as-A is no-op/error | Destructive cross-tenant loss |
| Restore/import assigns wrong shop | Restore/import stamp active-or-attributed shop per Section P rules | Import lands with correct shop_id | Rows invisible or mis-tenantized |
| Legacy migration assigns wrong shop | Phase I preflight/reconciliation unchanged; Phase J adds post-filter visibility check | Migrated records visible to owning shop | Legitimate data "disappears" |
| Inbound sync writes into wrong shop | Hydration stamps authoritative server `shop_id`; apply path validates against queue-entry shop | Hydrate-B-payload-as-A rejected/routed to B | Tenant corruption |
| Queued sync executes after switch using wrong current shop | Queue drained strictly by persisted entry `shop_id` (already true in `SyncEngine`); execution context = entry shop, never ambient current | Queue A entry survives switch to B and executes as A | A's sales pushed as B's |

Standing failure-mode rule: any violation fails CLOSED — return empty/no-op and surface an error state, never fall back to unscoped access.

---

## I. Target Architecture

```text
UI / Services (Flutter)
        │  resolves via SessionState + ShopResolver
        ▼
ActiveShopContext  (NEW, WS1 — single authoritative in-process tenant context)
        │  shopId: String?   // null = no authorized cloud tenant
        │  change-notifying; validated against memberships on switch
        ▼
DatabaseHelper / repositories
        │  every tenant-owned read/write takes or resolves ActiveShopContext
        │  NULL context → reads return empty, writes fail closed
        ▼
SQLite v14 (tenant-scoped operational cache)
        ▲
        │  Phase H sync engine (entry.shop_id = execution identity)
        ▼
Supabase: RLS + server RBAC + licensing  (authoritative enforcement)
```

Design rules:
1. One context object; no per-call ambient globals beyond it. The existing `setSyncShopIdProvider` startup hook is re-pointed at `ActiveShopContext` rather than duplicated.
2. Derived-from-context by default, explicit parameter where a call crosses an execution boundary (sync apply, migration, restore) — explicit/testable boundaries preferred over unsafe ambient mutable state.
3. Context is validated against the user's ACTIVE memberships at acquisition and at switch (`ShopResolver.getAllMemberships`); a stale/foreign shopId fails closed.
4. Cloud UUID remains the cross-system identity; integer PKs remain local-only identifiers (master plan §8).

## J. Read Isolation Contract

Every tenant-owned SELECT gains `AND (shop_id = :active)` once strict mode is armed (Section N precondition), applied at:

- List queries (products, sales, returns, expenses, expense categories, customers, invoices, inventory counts)
- ID lookups → `WHERE id = ? AND shop_id = ?`
- Search (name LIKE) and barcode lookup → scoped predicates
- Invoice number/id resolution → scoped
- Duplicate/existence checks → scoped per Section M decision
- Aggregates: dashboard totals, sales summary, group-by date/product reports, category usage counts → scoped source subqueries
- Joins (sale→product by barcode, invoice→sales): outer entity scoped first; inner lookups scoped to prevent join-mediated leakage

Truly global/system data read WITHOUT shop predicate (classified, not filtered blindly): `users`, `role_permissions`, `import_batches`, app_settings system keys (non-shop-profile), sync_queue metadata for status UI, licensing caches.

NULL-shop rows under strict mode are INVISIBLE to business reads (they belong to no authorized shop) except inside the migration/restore attribution flows that explicitly adopt them.

## K. Write Isolation Contract

| Operation | Contract |
|---|---|
| insert | Stamp `shop_id = :active` when context present; refuse business insert with NULL context (fail closed) rather than silently local-only |
| update | `WHERE id = ? AND shop_id = ?`; zero-rows → ownership error surfaced, not silent success |
| delete | Same scoped predicate; soft-delete path sets tombstone within scope |
| upsert | Natural-key checks run INSIDE active shop scope; no cross-shop collision possible after M decision |
| sync hydration | Applies with authoritative server shop_id; runs under `runWithoutSyncEnqueue`; validates payload shop == queue-entry shop |
| migration writes | Exclusively through locked Phase I orchestrator paths (unchanged); maintenance mode blocks concurrent business writes |
| clean start | Per-shop wipe of tenant tables when context active; full destructive wipe stays owner-gated global action |

Shop identity source of truth: `ActiveShopContext` (validated membership). Callers may pass shopId explicitly ONLY at trust boundaries (sync engine passes entry.shop_id; orchestrator passes progress-row shop_id); DatabaseHelper validates any passed value equals context before executing.

Frozen security invariants (restated as testable contract):
```text
UPDATE/DELETE MUST NOT CROSS TENANTS BY LOCAL NUMERIC ID ALONE.
A USER OPERATING IN SHOP A MUST NOT READ OR WRITE SHOP B DATA.
BACKGROUND SYNC MUST PRESERVE ORIGINATING SHOP IDENTITY.
QUEUED WORK FROM SHOP A MUST NEVER EXECUTE UNDER SHOP B AFTER SWITCHING.
LOCAL TENANT ISOLATION IS DEFENSE-IN-DEPTH AND REPLACES NEITHER SUPABASE RLS,
NOR RBAC MEMBERSHIP CHECKS, NOR SERVER AUTHORIZATION, NOR LICENSING ENFORCEMENT.
```

## L. Shop / Session Context Contract

- **Acquisition:** login + cloud-link → ShopResolver resolves → `ActiveShopContext.bind(shopId)` after membership validation; SessionState.activeShopId and context must agree.
- **Lifecycle:** bound for the authenticated session; cleared at logout/cloud-unlink.
- **No-shop behavior:** offline-before-first-cloud-link legacy installs keep current behavior behind an explicit compatibility flag (strict-mode arm switch, Section N); once cloud-linked, NULL context = fail-closed reads/writes.
- **Switch:** unbind → drain-or-defer decision (in-flight cycle completes under OLD shop id from entry data; new cycle uses NEW) → bind new shop after validation → UI rebuild. Ambient context MUST NOT be swapped mid-cycle: `SHOP_CONTEXT_AT_EXECUTION ≠ SHOP_CONTEXT_AT_OPERATION_ORIGIN` is permitted only because queue entries carry persisted origin shop_id and the engine executes strictly per entry.
- **Background operations:** SyncWorker resolves entry.shop_id per entry (already implemented); retry preserves original entry unchanged (Phase H idempotency keys untouched); conflict resolution applies to the row of the entry's own shop.
- **Migration/hydration/restore:** each carries its own explicit shopId argument; never read ambient context.

## M. Uniqueness Decisions

| Identifier | Current state | Classification | Resolution path |
|---|---|---|---|
| `products.barcode` | GLOBAL SQLite UNIQUE constraint | **OWNER_DECISION_REQUIRED** (GLOBAL vs PER_SHOP). No governing doc found deciding multi-shop barcode policy. | If GLOBAL retained: constraint already correct; duplicate check becomes shop-scoped lookup but constraint enforces global uniqueness (documented asymmetry). If PER_SHOP chosen: requires unique index `(barcode, shop_id)` replacing bare UNIQUE → schema bump v15 + table rebuild; deferred to owner decision session, NOT bundled into Phase J implementation silently. |
| Invoice number | App-level uniqueness check, unscoped | RESOLVED for Phase J: scope duplicate check to active shop; global invoice numbering across shops not required by any governing evidence; flagged informational in Z |
| Customer name / expense-category name | Unscoped case-insensitive checks | RESOLVED for Phase J: PER_SHOP semantics (names are shop-local business data); no schema dependency |
| Local numeric PKs / cloud_uuid | Hybrid per master plan §8 | NOT_RELEVANT_TO_PHASE_J |

No business policy invented here; the single genuinely open item (barcode) is routed to the owner-decision register (Z).

## N. Legacy Migration Handoff

**Strict-filter arming precondition (gate):**
1. Migration state for active shop is COMPLETED (`legacy_migration_progress` terminal), OR install never had legacy data (fresh post-J database), OR compatibility flag keeps pre-cloud installs on legacy behavior.
2. Post-migration visibility probe before arming: for each tenant table, count rows that would be invisible to the active shop but carry `cloud_uuid NOT NULL` — must be 0 (all migrated rows attributed).
3. Residual `cloud_uuid IS NULL AND shop_id IS NULL` rows (legacy local-only, never migrated): remain invisible under strict mode until adopted by an explicitly-run attribution/migration pass; count is surfaced in the arming report, never silently discarded.

This guarantees: **Phase I migrated records must remain accessible to their correct tenant after filtering is enabled**, and partially-migrated databases cannot lose data by arming early.

## O. Sync Handoff

Preserved untouched (Phase H contracts): offline-first queue-and-flush, idempotency keys, no-echo via enqueue suppression, `server_version` optimistic concurrency, soft-delete tombstones, incremental cursor sync, conflict resolver, hydration suppression.

Tenant guarantees ADDED by Phase J:
- Outbound: enqueue stamps context shop (existing provider re-pointed to ActiveShopContext); payload carries row's persisted shop_id.
- Inbound: hydration/incremental apply writes authoritative server `shop_id`, never ambient; mismatch between payload shop and applying context → route/reject, log, never merge into wrong tenant.
- Retry/background: entries execute strictly under their persisted `entry.shop_id` (already enforced by `getPendingEntries(shopId:)`); Phase J adds regression tests so this invariant cannot regress.
- Conflict resolution: compared/applied within entry's shop only.
- Switch: queue survives switches; entries never re-attributed to the newly selected shop.

## P. Backup / Restore Impact

- Backups remain whole-database file snapshots (all shops) — no tenant filtering in backup content.
- Restore of a legacy v7/v8 backup replays upgrades to v14 producing NULL-shop rows → after restore, strict mode must treat the database as PRE-MIGRATION (arming gate resets; user re-runs migration/attribution). Restore completion sets a marker so Phase J gating does not half-arm over unattributed data.
- Restoring a CURRENT-schema backup restores all shops' rows atomically; active shop's visibility is restored automatically by scoping (no per-shop restore in scope).
- Importers (`workbook_importer.dart`, `data_importer.dart`) MUST stamp imported tenant rows with active shop context; import with NULL context fails closed (WS7 tests).

---

## Q. Schema Decision

```text
SCHEMA_CHANGE_REQUIRED = NO
```

Justification: the v14 additive foundations already provide every structural element query-level isolation needs — `shop_id TEXT` on all tenant-owned tables, `cloud_uuid`, `server_version`, `sync_status*`, `last_synced_at`, indexed `sync_queue(shop_id)`, `legacy_migration_progress(shop_id)`. Phase J is context + query/repository hardening, not a structural change.

Contingency (documented, NOT executed): if the owner resolves barcode uniqueness as PER_SHOP (Section M), a v15 bump replacing `products.barcode UNIQUE` with a `(barcode, shop_id)` unique index (table rebuild in SQLite) becomes REQUIRED and must go through the master-plan schema-change gate (backup + migration test). Until that decision, no speculative bump is made.

## R. RLS / RBAC / Security Non-Regression

- Supabase RLS remains the authoritative tenant boundary for cloud tables; local SQLite scoping is defense-in-depth for the offline cache.
- Server RBAC (Phase F permission sync), membership validation (`get_user_shops`), and licensing enforcement hooks remain untouched and independently authoritative.
- Existing local guards stay intact: permission checks at mutation boundaries (`codex/i-tech-permission-hardening` lineage), licensing enforcer callback, `MigrationMaintenanceMode` write block.
- Phase J adds predicates; it does NOT weaken, bypass, or duplicate any server-side check. No service-role material enters the client.

## S. In-Scope

1. WS1 Active shop context object + startup wiring + switch lifecycle
2. WS2 Shop-scoped reads across all tenant-owned DatabaseHelper/repository methods
3. WS3 Scoped mutations (update/delete/upsert/soft-delete/insert stamping/clean-start semantics)
4. WS4 Search/barcode/invoice/duplicate/aggregate/dashboard/report isolation
5. WS5 Sync tenant integration hardening + regression tests of entry-shop execution
6. WS6 Strict-mode arming gate over Phase I migration state + visibility probes
7. WS7 Import stamping + restore arming-reset marker
8. WS8 Cross-tenant security-negative test suite (Section W/X)
9. WS9 Documentation, regression gates, closure report

## T. Explicit Non-Goals

- No Android work (Phases K/L)
- No inventory concurrency redesign (Phase M)
- No Excel import feature changes beyond shop stamping (Phase N)
- No invoice branding/delivery changes (Phase O)
- No production hardening (Phase P)
- No Supabase deployment or production migration execution in this phase's planning session
- No barcode-uniqueness policy change without owner decision (Z-1)
- No aesthetic refactoring of DatabaseHelper; changes are predicate/context additions at existing boundaries only
- No replacement of RLS/RBAC/licensing with local checks
- No multi-shop concurrent-session support on one device (single active shop per session, per current architecture)

## U. Dependency-Ordered Implementation Workstreams

**WS1 — Windows Cloud / Active Shop Context Contract**
OBJECTIVE: single validated tenant context consumed by the data layer.
DEPENDENCIES: none (first).
FILES/SYMBOLS: new `lib/services/active_shop_context.dart`; wiring in `main.dart` startup next to `setSyncShopIdProvider`/`setLicensingEnforcer`; `SessionState`, `ShopResolver`.
INVARIANTS: context == validated ACTIVE membership; null = fail-closed; bind/unbind atomic with UI notification; sync provider delegates to it.
TESTS: bind/validate/switch/null-context unit tests.
RISKS: ambient-state misuse → mitigated by single choke point + explicit args at trust boundaries.

**WS2 — Tenant-Safe Local Read Boundaries**
OBJECTIVE: every tenant-owned SELECT scoped.
DEPENDENCIES: WS1; arming gate from WS6 available behind flag.
FILES: `database_helper.dart` read methods (~50+), `invoice_repository.dart`, repositories under `lib/repositories/`.
INVARIANTS: J-contract predicates; system tables untouched; NULL-shop rows invisible in strict mode.
TESTS: seeded two-shop fixtures; list/id/search/barcode negative tests.
RISKS: missed call site → mitigated by exhaustive method inventory audit checklist in implementation session.

**WS3 — Tenant-Safe Mutation Boundaries**
OBJECTIVE: writes cannot cross tenants by id/barcode alone.
DEPENDENCIES: WS1 (WS2 recommended first).
FILES: update/delete/upsert/soft-delete paths in `database_helper.dart`; `clean_start_service.dart`.
INVARIANTS: K-contract; zero-row mutation = surfaced error; insert stamps context shop.
TESTS: cross-shop update/delete no-op+error tests; insert stamping tests.
RISKS: silent no-op masking bugs → require explicit ownership-error signal.

**WS4 — Search / Lookup / Aggregate / Dashboard / Report Isolation**
OBJECTIVE: leakage-free lookups and totals.
DEPENDENCIES: WS2 patterns established.
FILES: `getDashboardData`, `getSalesSummary`, `getSalesGroupByDate/Product`, category usage counts, barcode/name/invoice lookups.
INVARIANTS: aggregates equal active-shop-only sums under mixed fixtures.
TESTS: dashboard/report exclusion tests; barcode/invoice leakage tests.
RISKS: subquery scoping mistakes altering totals → golden-number tests vs seeded fixtures.

**WS5 — Windows Cloud Sync Tenant Integration**
OBJECTIVE: tenant guarantees around queue/hydration/retry/conflict.
DEPENDENCIES: WS1.
FILES: `sync_engine.dart`, `hydration_service.dart`, `incremental_sync_service.dart`, adapters (payload contracts unchanged), `sync_queue_repository.dart`.
INVARIANTS: O-contract; entry.shop_id = execution identity preserved.
TESTS: queued-entry-survives-switch test; hydration cross-shop rejection; retry attribution.
RISKS: touching engine hot paths → prefer assertions/validation additions over rewrites.

**WS6 — Phase I Migration Safety Handoff**
OBJECTIVE: strict-mode never hides legitimate migrated data.
DEPENDENCIES: WS2 (consumes gate).
FILES: arming logic near `ActiveShopContext`/startup; probes reading `legacy_migration_progress` + per-table counts.
INVARIANTS: N-precondition; partial migration blocks arming; visibility report emitted.
TESTS: completed/partial/unmigrated database matrix tests.
RISKS: false arming → conservative default (unarmed) + explicit user-visible state.

**WS7 — Backup / Restore / Import Safety**
OBJECTIVE: P-section rules enforced.
DEPENDENCIES: WS1, WS6.
FILES: `standalone_restore_service.dart` (arming reset marker only — version-accept defect stays out-of-scope unless trivially adjacent), `workbook_importer.dart`, `data_importer.dart`, `standalone_backup_service.dart`.
INVARIANTS: import stamps context shop; restore resets arming gate.
TESTS: import-with/wrong-context tests; restore-then-arm-blocked test.
RISKS: scope creep into restore-version fix → explicitly deferred unless owner directs.

**WS8 — Cross-Tenant Security-Negative Tests**
OBJECTIVE: codify Section 19/W matrix as automated suite.
DEPENDENCIES: WS2–WS7 complete.
FILES: new `app/test/tenant_isolation/` suite.
INVARIANTS: every listed threat has a red-then-green proof.
RISKS: flaky async sync timing → deterministic fakes per existing Phase H test patterns.

**WS9 — Documentation / Verification / Closure**
OBJECTIVE: full regression gates, closure report, updated roadmap docs.
DEPENDENCIES: all above.
DELIVERABLES: closure report mirroring Phase I style; analyze/test/format green; preserved-artifact hash recheck.

## V. File / Symbol Impact Forecast

| Path | Symbol(s) | Change type | Why | Risk | Test coverage |
|---|---|---|---|---|---|
| `app/lib/services/active_shop_context.dart` | NEW class | MUST_CHANGE | Single tenant context | Low | WS1 unit |
| `app/lib/main.dart` | startup wiring | MUST_CHANGE | Bind context + repoint sync provider | Low | smoke |
| `app/lib/services/session_state.dart` | activeShopId consistency | LIKELY_CHANGE | Agree with context | Low | unit |
| `app/lib/database/database_helper.dart` | ~50+ read/write methods | MUST_CHANGE | Predicates + stamping (J/K contracts) | HIGH — largest surface | WS8 suite + existing regression |
| `app/lib/database/invoice_repository.dart` | lookups | LIKELY_CHANGE | Scoped invoice resolution | Medium | WS4 |
| `app/lib/sync/sync_engine.dart` | cycle shop resolution | MAY_CHANGE | Validation assertions only | Medium | WS5 |
| `app/lib/sync/hydration_service.dart`, `incremental_sync_service.dart` | apply paths | MAY_CHANGE | Authoritative shop validation | Medium | WS5 |
| `app/lib/services/clean_start_service.dart` | wipe scope | MAY_CHANGE | Per-shop semantics | Medium | WS3 |
| `app/lib/database/workbook_importer.dart`, `data_importer.dart` | insert stamping | MUST_CHANGE | Wrong-shop prevention | Medium | WS7 |
| `app/lib/services/standalone_restore_service.dart` | post-restore marker | MAY_CHANGE | Arming reset | Low | WS7 |
| `app/lib/migration/*` | orchestrator/specs | MUST_NOT_CHANGE | Locked Phase I contract | — | existing tests |
| `app/lib/rbac/*`, `licensing/*` | — | MUST_NOT_CHANGE | Independent authority | — | existing tests |
| `supabase/**` | — | MUST_NOT_CHANGE | No deploy this phase | — | — |
| schema version (14) | `_onUpgrade` | MUST_NOT_CHANGE (contingent v15 only via Z-1) | Q-decision | — | — |

---

## W. Test Strategy

Layers:
1. **Unit (context):** bind/validate/switch/clear of ActiveShopContext; provider delegation.
2. **Data-layer negative suite (`app/test/tenant_isolation/`):** two-shop seeded SQLite fixtures per existing Phase H test infrastructure; every Section-X matrix row as a named test.
3. **Sync integration:** deterministic fake cloud source (Phase H patterns); queued-entry-survives-switch; hydration rejection on shop mismatch; retry attribution.
4. **Migration gating matrix:** completed / partial / never-migrated databases × arming attempts.
5. **Regression preservation:** all existing Phase B–I tests remain green untouched — `schema_v9_migration_test`, `schema_v13_test`, `schema_v14_test`, `migration_orchestrator_test`, permission/licensing suites.

Required minimum negatives (implementation must prove):
```text
Shop A cannot list Shop B rows (per tenant table)
Shop A cannot fetch Shop B row by ID
Shop A cannot search Shop B data
Shop A cannot update Shop B row
Shop A cannot delete Shop B row
Aggregates exclude Shop B data
Dashboard counts exclude Shop B
Reports exclude Shop B
Barcode lookup cannot leak Shop B
Invoice lookup cannot leak Shop B
Duplicate checks use approved tenant scope
Queued sync preserves original shop across switch
Hydration cannot cross tenants
Shop switching does not leak ambient context
Phase I migrated records remain visible to their correct tenant
Existing offline-first behavior remains operational without cloud link
RLS/server authorization remains independently enforced (contract-level assertion)
```

## X. Acceptance Gates

1. `flutter analyze` — zero new issues vs baseline
2. `flutter test` — full suite green including WS8 suite
3. `dart format --output=none --set-exit-if-changed lib test` — clean
4. `git diff --check` — clean
5. Two-shop fixture proof: every X-matrix negative passes
6. Arming-gate matrix proof: no path arms strict filtering over unattributed migrated data
7. Phase H sync contracts: all existing sync tests green unchanged
8. Preserved artifacts hash recheck (MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md, delivery ZIP) — unchanged from Phase I record
9. Clean repository except authorized closure-report artifact
10. Single local implementation commit; no push/tag/deploy without separate authorization

## Y. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Missed unscoped query in 50+ method surface | Medium | Critical leak | Method inventory audit checklist + grep-verification step in implementation session |
| Strict mode hides legitimate rows (bad arming) | Low | Data-loss perception | WS6 gate + visibility probe + conservative unarmed default |
| Ambient context race during switch | Low | Cross-shop execution | Entry-persisted shop identity (already structural); WS5 regression tests |
| Performance regression from added predicates | Low | UX | Indexed shop_id columns; measure on seeded large fixture |
| Barcode decision blocks multi-shop product entry | Open | Business friction | Z-1 routed to owner before PER_SHOP-dependent work |
| Scope creep into restore-version defect | Medium | Schedule | Explicit non-goal unless owner directs |

## Z. Owner Decisions

| ID | Decision | Status |
|---|---|---|
| Z-1 | `products.barcode` uniqueness: GLOBAL (current constraint) vs PER_SHOP (requires v15 unique-index rebuild) | **OWNER_DECISION_REQUIRED** — must be resolved before any work depending on cross-shop duplicate-barcode entry; GLOBAL-retention keeps SCHEMA_CHANGE_REQUIRED = NO |
| Z-2 | Invoice numbering scope (per-shop assumed per M) | RESOLVED_BY_DEFAULT — confirm at closure if objection |
| Z-3 | Clean-start semantics: per-shop wipe when cloud-linked vs global destructive wipe retention | OWNER_CONFIRMATION recommended at implementation start; default = per-shop when context active, global wipe stays owner-gated |
| Z-4 | Treatment of residual NULL-shop legacy rows post-transition (adopt vs archive) | OWNER_DECISION_REQUIRED before strict-mode general availability in production installs |

## AA. Phase J Implementation Session Contract

1. Entry precondition: this plan committed; baseline parent `986f0dd`; preserved artifacts hash-verified.
2. Order: WS1 → WS6-gate scaffolding → WS2 → WS3 → WS4 → WS5 → WS7 → WS8 → WS9 (WS4 may parallel WS3 after WS2 patterns).
3. No file outside the Section-V forecast is modified without a documented reason appended to the closure report.
4. Every WS lands with its tests in the same commit series; analyze/test/format run per commit.
5. Any discovered blocker uses `BLOCKED_PHASE_J_IMPLEMENTATION_<REASON>` and stops without destructive repair.
6. Closure produces `PHASE_J_WINDOWS_CLOUD_TRANSITION_REPORT.md` mirroring the Phase I report style, then stops before remote mutation.

## AB. Final / Remote Integrity Contract

```text
AUTHORIZED_MUTATIONS_THIS_SESSION = one local planning commit:
  "Plan Phase J Windows Cloud Transition"
  paths: PHASE_J_WINDOWS_CLOUD_TRANSITION_PLAN.md only

PROHIBITED: git push, tags, Supabase deploy, production migrations,
Phase J implementation, Phase K start, history rewrite, stash mutation,
preserved-artifact modification.

EXPECTED POST-COMMIT STATE:
  PLANNING_PARENT = 986f0dde659233e9868b232996a777ae6b3e5fda
  LOCAL_AHEAD     = 1   (expected; remote lock is a separate session)
  REMOTE_AHEAD    = 0
  WORKTREE        = clean except preserved untracked artifacts

NEXT_AUTHORIZED_SESSION = PHASE_J_REMOTE_PLANNING_BASELINE_LOCK
```

---

*End of Phase J planning artifact.*
