# PHASE I — LEGACY DATA MIGRATION PLAN (IMPLEMENTATION-GRADE)

**Status:** PLANNING FROZEN — implementation not started in this session
**Branch:** `codex/i-tech-next-roadmap-freeze`
**Governing baseline (parent):** `884f128d4055d289deff8abec017c782827193d1` (`Phase H: implement offline-first cloud sync foundation`, tag `phase-h-implementation-locked`)
**Forensic discovery:** CLOSED (repository/code archaeology, local SQLite / Phase H sync analysis, cloud table mapping, sync_status lifecycle verification, file-by-file evidence, architecture evidence)
**Rule of this phase:** planning documentation only. No Dart/SQL/test/backup/invoice fixes are made here.

---

## 0. HASH-PRESERVED ARTIFACTS (BEFORE hashes, recorded before planning)

| Artifact | SHA-256 |
|----------|---------|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` |

These hashes must be re-verified (AFTER check) at Phase I implementation start. Any mismatch aborts implementation until explained.

Note: the source-of-truth report was generated against an older baseline (HEAD `6490d2f`, schema v6). Where this plan cites schema facts, the current worktree evidence at `884f128` (schema v13) supersedes the report.

---

## 1. CONFIRMED FORENSIC FINDINGS (EVIDENCE-BACKED)

### 1.1 Source DB identity
- Local store: SQLite file `muaman_store.db` via `sqflite_ffi` on Windows desktop (`app/lib/database/database_helper.dart:253`, `_initDB` line 299–304).
- Current schema version at baseline: **13** (`version: 13` at `database_helper.dart:303`).
- Legacy field DBs (production v1.0.0 delivery) run **v6–v8**: v6 = released 10-table schema; v7 adds `expenses.category` + `expense_categories`; v8 adds `customers` + `invoices.customerId`.
- The restore service currently accepts **only** `user_version 7 or 8` (`standalone_restore_service.dart:102`).

### 1.2 Backup/restore current-schema compatibility issue (CONFIRMED DEFECT — not fixed in this session)
- `StandaloneRestoreService._validateBackup` rejects any backup whose `PRAGMA user_version != 7 && != 8` (`standalone_restore_service.dart:100–105`).
- Consequence A: backups produced by the current v13 build are **rejected by restore** ("إصدار قاعدة البيانات غير متوافق: 13").
- Consequence B: restoring an old v7/v8 backup succeeds only because `reopen()` re-opens through `openDatabase(version: 13)` which replays `_onUpgrade` 8→9→13 (adds `shop_id`, `cloud_uuid`, `server_version`, `sync_status`, `last_synced_at`, creates `sync_queue`). Restored legacy rows arrive with NULL `cloud_uuid` and no queue state.
- Migration-safety consequence: the migration flow cannot rely on `StandaloneRestoreService` for its mandatory pre-migration backup of a v13 DB; it must create its own verified snapshot (Section 7).

### 1.3 Invoice / fresh-vs-upgrade schema parity issue (CONFIRMED DEFECT — not fixed in this session)
- Fresh installs: `_createDB` creates `invoices` **without** `customerId` (`database_helper.dart:424–439`: id, invoiceNumber, date, customerName, paymentMethod, totalAmount, totalItems, createdAt, shop_id, cloud_uuid).
- Upgraded installs: `_migrateToV8` adds `customerId INTEGER` + index and backfills system-customer linkage (`database_helper.dart:497–534`). `_onUpgrade` runs V8 only when `oldVersion < 8` (`database_helper.dart:240–242`); `onCreate` never calls it.
- Runtime impact: `Invoice.toMap()` always emits `'customerId'` (`app/lib/models/invoice.dart:34`) and `insertInvoiceWithItems` writes it (`database_helper.dart:1033–1039`) → invoice creation fails with "no such column: customerId" on fresh databases.
- Migration impact: historical import must tolerate both shapes when reading local rows (column-presence probe via `PRAGMA table_info`), exactly like `_migrateToV13` already does (`database_helper.dart:599–614`).

### 1.4 Nine-table cloud mapping (VERIFIED)
Local table → adapter → Supabase table (`cloudTableName` in each `app/lib/sync/adapters/*_sync_adapter.dart:16`):

| # | SyncEntityType | Local table | Cloud table | Adapter |
|---|----------------|-------------|-------------|---------|
| 1 | product | products | cloud_products | product_sync_adapter.dart |
| 2 | sale | sales | cloud_sales | sale_sync_adapter.dart |
| 3 | returnItem | returns | cloud_returns | return_sync_adapter.dart |
| 4 | expense | expenses | cloud_expenses | expense_sync_adapter.dart |
| 5 | expenseCategory | expense_categories | cloud_expense_categories | expense_category_sync_adapter.dart |
| 6 | customer | customers | cloud_customers | customer_sync_adapter.dart |
| 7 | invoice | invoices | cloud_invoices | invoice_sync_adapter.dart |
| 8 | inventoryCount | inventory_count | cloud_inventory_count | inventory_count_sync_adapter.dart |
| 9 | shopSetting | app_settings (shop-profile keys) | cloud_shop_settings | shop_settings_sync_adapter.dart |

Excluded from migration universe (no adapter, stays local): `users`, `role_permissions`, `import_batches` (has v9/v13 columns but no adapter), `sync_queue`.

### 1.5 sync_status lifecycle (VERIFIED)
- Queue-level (`SyncQueueStatus`, `sync_status.dart:9–16`): `PENDING → SYNCED | FAILED | CONFLICT`; engine marks synced/idempotent (`sync_engine.dart:143–151`), failed on permission/server error (`153–167`), conflict via resolver (`122–140`).
- Entity-level (`EntitySyncStatus`, `sync_status.dart:18–24`): `SYNCED | PENDING | CONFLICT`, stored in per-table `sync_status` column; business writes stamp `PENDING` inside the same transaction as the write + enqueue (`insertInvoiceWithItems` pattern, `database_helper.dart:1037`).
- Retry/backoff: delays `[0, 5s, 30s, 2m, 10m]` keyed on `retry_count` (`sync_engine.dart:184–201`).
- Error taxonomy (`SyncErrorType`, `sync_status.dart:46–65`) with `isRetryable` limited to network/server/unknown.

### 1.6 Phase H handoff contract (VERIFIED — no-echo / cloud_uuid / server_version)
- Enqueue is transactional with the business write (`_enqueueAfterWrite`, `database_helper.dart:168–210`), payload = `{id, cloud_uuid, server_version, ...adapter.localToCloudPayload(row)}`, unique `idempotency_key`.
- Cloud-applied writes are suppressed from re-enqueue via static `runWithoutSyncEnqueue` nesting counter (`database_helper.dart:77–110`) — this is the **no-echo guarantee**.
- Pull path (`hydration_service.dart`, `incremental_sync_service.dart`): match local row by `cloud_uuid` (`incremental_sync_service.dart:121–130`); apply only if `server_version > local server_version` (`63–66`); inserts stamp `{cloud_uuid, shop_id, server_version, sync_status:'SYNCED', last_synced_at}` (`83–90`); soft-delete via cloud `deleted_at` (`95–103`).
- Upload path: DELETE carries pre-delete snapshot including `cloud_uuid` (`sync_engine.dart:98–108`); CREATE/UPDATE results can be `conflict` (resolver), `idempotent` (markSynced, no echo), or success (`109–152`).
- Shop binding at enqueue: active provider wins over row value — `_resolveSyncShopId` (`database_helper.dart:140–147`).

---

## 2. FROZEN ARCHITECTURE DECISIONS

Each decision below is FINAL for Phase I implementation unless a real blocker emerges during implementation (new investigation loop only then, narrowly scoped).

### D1. Migration universe
The 9 adapter-backed entity families of §1.4, plus nothing else. Historical data migrates per **business record** (sale lines, invoice headers, etc.), preserving denormalized copies as stored locally. `users` / `role_permissions` / `import_batches` / `sync_queue` do NOT migrate.

### D2. Source DB identity
Migration operates on a **pinned snapshot**, never the live file:
1. Owner-triggered `VACUUM INTO` snapshot of the live v13 DB (same mechanism as pre-save backup, `standalone_restore_service.dart:161`).
2. Snapshot pinned by SHA-256 recorded in the ledger batch row.
3. All reads during import come from the snapshot; all writes go to cloud only. Live DB is mutated only by the final stamping step (§D14/D15).
If live writes occurred between snapshot and completion (detected via live `MAX(rowid)`/count deltas or app-usage lock), the batch aborts as superseded; a new batch is required. Frozen policy: **migration runs under maintenance mode** (D11) so concurrent writes cannot happen.

### D3. Shop binding
Every imported cloud row is bound to exactly one `shop_id` resolved from the licensing/membership context (the same provider contract as `_shopIdProvider` in `SyncEngine`, `sync_engine.dart:23–24,60–69`). Rows whose snapshot `shop_id` is NULL or divergent from the active tenant are quarantined into the reconciliation report, never silently bound. One batch == one shop; multi-shop devices require one batch per shop.

### D4. Server-authoritative historical import
Cloud receives historical rows through a **dedicated migration ingest path** (Supabase RPC/function family, e.g. `migration_upsert_<entity>`), not through the client-side `SyncEngine` upload loop:
- Server assigns `id` (uuid), `server_version`, `created_at`/`updated_at`.
- Client-preserved fields: all business columns INCLUDING original business timestamps (`date`, `createdAt`, …) and financial snapshots (`costPrice`, `cogs`, `returnedCogs`, totals). Business time ≠ sync time: cloud `updated_at` is set to server import time so other devices pull the history exactly once via the existing incremental watermark (`updated_at >= since`, `incremental_sync_service.dart:50–57`).
- Server validates shop membership + license state before accepting; fail-closed like existing cloud data paths.

### D5. Local ID ↔ cloud_uuid mapping & cloud migration ledger
One authoritative mapping store, **cloud-side**: table `cloud_migration_ledger`:
```
batch_id TEXT NOT NULL            -- UUIDv4, generated once per batch
shop_id TEXT NOT NULL
local_table TEXT NOT NULL         -- 'products', 'sales', ...
local_id INTEGER NOT NULL         -- snapshot-local INTEGER id
cloud_uuid TEXT NOT NULL          -- server-assigned uuid
content_fingerprint TEXT NOT NULL -- stable hash of business payload (canonical JSON, excludes local ids)
server_version INTEGER NOT NULL
status TEXT NOT NULL              -- IMPORTED | SKIPPED_DUPLICATE | CONFLICT
created_at TIMESTAMPTZ DEFAULT now()
UNIQUE(batch_id, local_table, local_id)
UNIQUE(shop_id, local_table, content_fingerprint)  -- cross-batch idempotency
```
Ledger rules:
- Written server-side in the same transaction as the entity upsert (atomic mapping).
- It is the ONLY source of truth for "was this local row already migrated".
- Local mirror table `legacy_migration_progress` (SQLite, §D12) caches checkpoints for resume UI but is never authoritative.
- Natural-key collisions across shops are impossible (ledger scoped by shop_id).

### D6. Dependency order (import sequence)
Per-shop, strictly sequential phases; within a phase, chunked batches ordered by local id ascending:

```
P0 preflight        snapshot + hash pin + maintenance mode + license/shop verify
P1 expense_categories      (no deps)
P2 products                (no deps among migrated)
P3 customers               (no deps among migrated)
P4 expenses                → needs P1 (category name/categoryId resolution)
P5 inventory_count         → needs P2 (productId)
P6 sales                   → needs P2 (barcode/productName denormalized already; invoiceId deferred link)
P7 invoices                → needs P3 (customerId) ; after P6 so invoice.saleIds/sales links resolve
P8 returns                 → needs P2 + P6 (saleId reference)
P9 post-pass               invoice↔sale link repair on cloud side, ledger completeness check
P10 reconcile + finalize   §D17 counts/checksums; then local stamping (§D15)
```
Rationale: every FK-like reference points to an earlier phase; denormalized name/barcode columns travel inside their own row so ordering only matters for resolvable references. If a referenced parent is missing (e.g., sale barcode deleted from products), the child imports anyway (denormalized design, CODEX C3 accepted) and the missing-reference pair is recorded in the reconciliation report — never dropped silently.

### D7. Dedicated migration vs sync_queue relationship
- Migration is a **separate one-shot pipeline** (`LegacyMigrationService`) with its own ingest RPCs; it does NOT enqueue into `sync_queue` and does NOT run the `SyncEngine` loop.
- During P0–P10 the sync worker is suspended (maintenance mode) and the queue is frozen: existing pending entries stay untouched and are processed normally only after migration completes.
- After completion, migrated local rows are stamped directly (§D15) — they never pass through `sync_queue`, preventing duplicate upload of history through the continuous-sync path.
- Guard test requirement: zero new `sync_queue` rows attributable to migration (assert via count-before/count-after under suppression seam).

### D8. SQLite v14 need — YES (approved)
Schema bump **13 → 14** adding ONE local bookkeeping table (no changes to existing tables):
```sql
CREATE TABLE legacy_migration_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id TEXT NOT NULL UNIQUE,
  shop_id TEXT NOT NULL,
  phase TEXT NOT NULL,             -- current P-phase label
  status TEXT NOT NULL,            -- NOT_STARTED/RUNNING/PAUSED/RECONCILING/COMPLETED/FAILED/ABORTED
  snapshot_path TEXT,
  snapshot_sha256 TEXT,
  last_table TEXT,                 -- checkpoint: table being imported
  last_local_id INTEGER,           -- checkpoint: resume cursor
  stats_json TEXT,                 -- per-table {imported, skipped, conflict}
  started_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT
);
```
- Created in `_migrateToV14`; `onCreate` includes it in `_createDB` (with the §1.3 lesson applied: any future column added via ALTER in a migration MUST also be added to `_createDB` — enforced by review checklist + parity test).
- Version gate: opening a v13 DB auto-runs V14 (trivial additive migration, guarded style of `_migrateToV13`).

### D9. State machine (batch lifecycle)
```
NOT_STARTED → BACKUP_VERIFIED → RUNNING ⇄ PAUSED
RUNNING → RECONCILING → COMPLETED
any of {RUNNING, PAUSED, RECONCILING} → FAILED(resumable) → RUNNING   [resume]
any → ABORTED (owner-initiated; keeps completed sub-phases, marks batch closed)
BACKUP_VERIFIED requires: snapshot exists + sha256 matches ledger + integrity_check ok
COMMITTED terminal states: COMPLETED, ABORTED (FAILED without further resume attempts becomes ABORTED after N=3 resume failures)
```
Transitions are persisted to `legacy_migration_progress` in the same transaction as each chunk's ledger confirmation callback, so crash-recovery resumes from the last durable checkpoint (`last_table`, `last_local_id`).

### D10. Idempotency
- Per-row: `UNIQUE(shop_id, local_table, content_fingerprint)` on the cloud ledger — re-importing the same snapshot (or any snapshot containing the same business row) is a server-side no-op returning the existing `cloud_uuid` (ledger lookup first, INSERT otherwise).
- Per-chunk: ingest RPC accepts `{batch_id, table, rows[]}`; response reports per-row `IMPORTED | DUPLICATE | CONFLICT`; client advances checkpoint only after persisting the response.
- Batch-level: rerunning a COMPLETED batch id is rejected outright; rerunning a FAILED/PAUSED batch continues.
- Fingerprint definition: canonical JSON of adapter business fields sorted by key, UTF-8, SHA-256, computed identically client/server side. Excluded: local `id`, `cloud_uuid`, `server_version`, `sync_status*`, `shop_id`, sync timestamps.

### D11. Snapshot / concurrent-write policy
- Maintenance mode: owner-only screen locks business screens (write APIs throw early), suspends `SyncWorker` polling, shows persistent banner. Implementation seam: reuse `runWithoutSyncEnqueue` counter pattern with a dedicated maintenance flag; DB-level safety net remains (writes still possible programmatically → hence snapshot-hash + live-delta detection of §D2 as second line of defense).
- Snapshot: `VACUUM INTO` (online, consistent, WAL-safe), then `PRAGMA integrity_check` + sha256 pin before P1 starts.
- No direct live-DB writes during P1–P9 except progress-table updates.

### D12. Retry / resume
- Network failure mid-chunk: exponential backoff (reuse `[0,5s,30s,2m,10m]` constants), max 5 attempts per chunk, then batch → `FAILED(resumable)`.
- Resume: owner relaunches migration → service loads latest non-terminal batch for shop → verifies snapshot sha256 (re-hash file) → jumps to `last_table`/`last_local_id` → continues. Ledger idempotency makes overlap harmless.
- Process crash: same resume path; checkpoints durable per D9.
- Resume attempts capped at 3 before requiring explicit owner reset (ABORTED + new batch).

### D13. Existing cloud data policy
- NEVER mutate or delete pre-existing cloud rows of the target shop.
- Collision handling when fingerprint differs but natural key matches (natural keys: `products.barcode`, `invoices.invoiceNumber`, `expense_categories.name` UNIQUE, `customers` by (name,phone)):
  - `barcode`/`invoiceNumber` collision → row imported under SKIP rule? NO — frozen rule: **skip import of the colliding row, status `CONFLICT` in ledger, listed in report with both versions**. Server-authoritative: existing cloud row wins. Owner resolves manually after review; resolution is out of scope for the automated pipeline.
  - Non-natural-keyed tables (sales, returns, expenses, inventory_count, shop profile values): no natural key → always import as new rows (history append semantics).
- Cloud rows previously created by Phase H continuous sync (have `cloud_uuid` already set locally) are **skipped** by migration entirely (fingerprint check hits ledger/local uuid presence) — migration targets legacy rows with `cloud_uuid IS NULL` first-class; rows with `cloud_uuid IS NOT NULL` are excluded from the universe at P0 census.

### D14. Financial integrity
- Preserve snapshots exactly: `costPrice`, `cogs` (sale-time COGS), `returnedCogs`, `totalSaleValue`, `totalReturnValue`, `totalAmount`, amounts as REAL round-tripped byte-stable (serialize with repr-exact formatting; REAL is IEEE754 on both sides — assert equality, not tolerance).
- Invariant checks pre-import (snapshot) vs post-import (cloud aggregates):
  - `Σ totalSaleValue(sales)` equal;
  - `Σ cogs(sales)` equal; `Σ returnedCogs(returns)` equal;
  - `Σ totalAmount(invoices)` equal; `Σ amount(expenses)` equal;
  - per-product `currentQuantity` formula unchanged (`openingQuantity − soldQuantity + returnedQuantity + inventoryAdjustment`).
- Zero/negative anomalies present in legacy data are migrated as-is (historical truth) and merely reported; no silent normalization (consistent with open issues M1/M4 policy).

### D15. Reconciliation
After P9, per table: compare `COUNT(*)` and financial sums (D14) between snapshot query and cloud aggregate RPC filtered by `batch_id` via ledger join. Produce `ReconciliationReport`:
```
per table: expected_rows, imported, duplicates_skipped, conflicts, missing_refs
financials: expected vs actual per invariant sum
verdict: PASS (all equal, conflicts==listed-and-reviewed) | FAIL (blocks finalization)
```
Report persisted (stats_json + full JSON artifact next to snapshot). Only verdict PASS unlocks P10 stamping.

### D16. Backup/restore safety (interim policy until standalone defect is fixed in its own remediation phase)
- Migration creates its own verified `VACUUM INTO` backup independent of `StandaloneRestoreService` validation (which still gates at user_version 7/8 — documented defect §1.2).
- Pre-migration checklist enforces: fresh backup exists outside app dirs, sha256 pinned in batch row, restore drill instructions included in operator doc (manual copy-back path documented since automated restore would reject a v13 backup).
- The restore-gate fix and invoice-parity fix are EXPLICITLY OUT OF SCOPE here; they are registered as prerequisite remediations that MUST land before general-availability rollout of migration (see §5 blockers).

### D17. Phase H sync handoff (finalization contract)
At COMPLETED (post-reconciliation), for every ledger `IMPORTED` row, local stamping in one transaction per table, wrapped in `runWithoutSyncEnqueue`:
```
UPDATE <table> SET
  cloud_uuid     = ledger.cloud_uuid,
  server_version = ledger.server_version,
  sync_status    = 'SYNCED',
  last_synced_at = now
WHERE id = ledger.local_id AND cloud_uuid IS NULL;
```
Then: clear stale PENDING queue entries only for rows now stamped SYNCED (defensive no-op normally); leave other queue entries intact. Result: continuous Phase H sync sees migrated rows as fully synced (nothing to upload), other devices receive them once via incremental pull on `updated_at` watermark (§D4). No echo, no double-import (ledger uniqueness), no queue pollution (D7).

---

## 3. IMPLEMENTATION WORK BREAKDOWN (for the implementation session — NOT this session)

| W# | Unit | Files (planned) | Notes |
|----|------|-----------------|-------|
| W1 | Schema v14 | database_helper.dart (+test/sync/schema_v14_test.dart) | D8; include onCreate-parity assertions |
| W2 | Migration models/services | lib/migration/legacy_migration_service.dart, migration_state_machine.dart, fingerprint.dart | D2,D9,D10 |
| W3 | Cloud ingest RPC contracts | lib/migration/cloud_migration_client.dart + Supabase SQL migrations (cloud_migration_ledger, per-entity ingest fns) | D4,D5 |
| W4 | Chunked importer + dependency orchestrator | lib/migration/migration_orchestrator.dart | D6 order P1..P9, chunk size 200 rows default |
| W5 | Reconciliation engine | lib/migration/reconciliation_service.dart | D14,D15 |
| W6 | Finalization/stamping | extension of LegacyMigrationService | D17 |
| W7 | Maintenance mode + owner UI | settings entry, banner widget | D11 |
| W8 | Census/preflight report | preflight: row counts per table, cloud_uuid-null census, anomaly list | feeds owner consent screen |

Chunk size, timeouts, and log phrasing finalized in implementation session; defaults above are binding starting points.

## 4. TEST MATRIX (binding minimum for implementation session)

1. v14 upgrade path 13→14 and fresh-create parity (columns identical via PRAGMA table_info diff — also retro-tests §1.3 shape).
2. Ledger idempotency: same snapshot imported twice ⇒ second run all-DUPLICATE, zero new cloud rows.
3. Crash/resume: kill after P6 chunk 2 ⇒ resume completes P6..P10, final counts exact.
4. Echo guard: during full migration, `sync_queue` row delta == 0.
5. Conflict: pre-existing cloud product with same barcode ⇒ ledger CONFLICT + report entry + local row left unstamped.
6. Financial invariants: seeded dataset with known sums ⇒ reconciliation PASS; tampered case ⇒ FAIL blocks stamping.
7. Multi-device pull: second device pulls migrated history exactly once; watermark respected.
8. Fresh-vs-upgrade invoice tolerance: importer handles both invoices shapes (PRAGMA probe path).
9. Shop isolation: two shops' batches never cross-leadger.
10. Existing suite green: `flutter test test/sync/` and full suite unaffected except additive files.

## 5. REGISTERED BLOCKERS / PREREQUISITE REMEDIATIONS (documented only)

| ID | Finding | Evidence | Required before GA rollout |
|----|---------|----------|---------------------------|
| B1 | Restore validation rejects current-version backups (gate stuck at 7/8) | standalone_restore_service.dart:100–105 | Yes — own remediation commit |
| B2 | Invoice fresh-vs-upgrade schema parity (fresh lacks customerId; toMap always writes it) | database_helper.dart:424–439 vs :500; models/invoice.dart:34; database_helper.dart:1033–1039 | Yes — own remediation commit |
| B3 | `_onUpgrade oldVersion<2` destroys all data (DROP+recreate) — acceptable only because field floor is v6; must stay documented | database_helper.dart:213–221 | Documentation only |
| B4 | Engine retry cap: entries with retryCount>5 bypass backoff gating indefinitely | sync_engine.dart:184–187 | Phase H follow-up, not blocking Phase I |

None of these block producing the Phase I implementation itself; B1/B2 block production rollout of it.

## 6. VALIDATION GATES FOR THIS SESSION (executed after this document)

1. `flutter test test/sync/` — all green, no source modifications.
2. `flutter analyze` — no new issues.
3. Diff audit: only `PHASE_I_LEGACY_DATA_MIGRATION_PLAN.md` added; zero Dart/SQL/test changes.
4. Single local commit `Plan Phase I legacy data migration` with parent `884f128d...`; no remote operations.

---

*End of plan. Implementation begins in the Phase I implementation session against this frozen document.*
