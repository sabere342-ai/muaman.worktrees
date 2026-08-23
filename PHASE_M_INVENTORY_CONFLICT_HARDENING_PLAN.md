# PHASE M — INVENTORY CONFLICT HARDENING PLAN

## 0. Document Control

| Field | Value |
|---|---|
| Phase | M — Inventory Conflict Hardening |
| Session type | PLANNING ONLY (no implementation, no push, no tags) |
| Baseline verified at session entry | `1a138a510be5453f21b68c659c20ba5432165e5c` (Phase L implementation lock) |
| Planning artifact | `PHASE_M_INVENTORY_CONFLICT_HARDENING_PLAN.md` (this file) |
| Authorized next session | `PHASE_M_PLANNING_REMOTE_LOCK` |
| Operating principle order | Zero data loss → financial truth → inventory explainability → idempotency → transactional correctness → tenant isolation → authorization → restartability → convergence → user clarity → minimal change |

All code references below were read directly from the locked Phase L tree at `1a138a510be5453f21b68c659c20ba5432165e5c`.

---

## 1. Repository / Locked Baseline

Verified at session entry (all read-only):

```text
ROOT        = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH      = codex/i-tech-next-roadmap-freeze
REMOTE      = github -> https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY      = origin  -> C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن   (untouched, unused)

HEAD        = 1a138a510be5453f21b68c659c20ba5432165e5c
HEAD^       = 914e2bdd4d724067df64ed00e0efae3be645e543
HEAD subject= Implement Phase L Android Sales/Employee

phase-l-planning-baseline-locked   tag obj = 185980cf00d737c3682c1d619051d24091166404 -> peeled 914e2bdd4d724067df64ed00e0efae3be645e543  ✓
phase-l-implementation-locked      tag obj = f750813bd549e505b2c9e197423128162426cdcc -> peeled 1a138a510be5453f21b68c659c20ba5432165e5c  ✓
phase-k-implementation-locked      peeled  = 0bb24de96f468bc439a0cf0b65525dfbfe0a5702  ✓

Ancestry: da184e2ede845ee75ae03299e6c4110eacb8faa9
          ↓ 0bb24de96f468bc439a0cf0b65525dfbfe0a5702
          ↓ 914e2bdd4d724067df64ed00e0efae3be645e543
          ↓ 1a138a510be5453f21b68c659c20ba5432165e5c     (merge-base --is-ancestor: OK)

github/codex/i-tech-next-roadmap-freeze = 1a138a510be5453f21b68c659c20ba5432165e5c  (= LOCAL_HEAD, divergence 0/0)
remote tag objects match local tag objects for both phase-l locks            ✓
```

Entry classification: **CASE A — FRESH PLANNING** (clean tracked worktree; only the two sacred untracked artifacts present; no prior Phase M planning work).

---

## 2. Canonical Phase Definition

From `PROJECT_MASTER_PLAN.md` §13:

> | M | Inventory Conflict Hardening | Concurrency, stock conflicts, reconciliation |

Dependency: after H + I foundations; roadmap position immediately after L. Non-goals: N (Excel import), O (invoice branding), P (production hardening).

Canonical conflict problem (`PRODUCTIZATION_ARCHITECTURE_PLAN.md` §10):

```text
Stock = 1
Windows offline sells 1 → local stock = 0
Android offline sells 1 → local stock = 0
Both sync → Stock should be 0 but two sales happened for stock=1
```

Governing invariant (`PRODUCTIZATION_ARCHITECTURE_PLAN.md` §10, §19 — INVARIANT class):

```text
currentQuantity = openingQuantity − soldQuantity + returnedQuantity + inventoryAdjustment
```

This equation must remain valid and explainable after every reconciliation path introduced by Phase M.

---

## 3. Governing Requirements

Read and cross-checked: `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md`, `PRODUCTIZATION_MIGRATION_PLAN.md`, `PHASE_H_OFFLINE_SYNC_CORE_PLAN.md`, `PHASE_I_LEGACY_DATA_MIGRATION_PLAN.md`, `PHASE_J_WINDOWS_CLOUD_TRANSITION_PLAN.md`, `PHASE_K_ANDROID_OWNER_FOUNDATION_PLAN.md`, `PHASE_L_ANDROID_SALES_EMPLOYEE_PLAN.md`, plus the preserved `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` (read-only).

Binding requirements extracted:

1. Per-entity conflict policies (`ARCHITECTURE_PLAN` §9, `PHASE_H` §8.4/§15.1): products/customers/expenses/settings = LWW on server timestamp; sales/returns/invoices = server-authoritative (unique events); inventory count = "latest count wins".
2. Recommended default policy (`ARCHITECTURE_PLAN` §10): server-authoritative stock for multi-device shops; offline sale allowed if local stock > 0, flagged for reconciliation; both sales recorded, stock adjusted to actual, owner alerted.
3. Phase H explicitly deferred to M (`PHASE_H` §7, §21.3): manual conflict review UI, side-by-side comparison, owner-selectable resolution, conflict history audit trail.
4. Audit disposition (`ARCHITECTURE_PLAN` §20): "No negative-stock guard at DB layer" = `FIX_DURING_PHASE_M`.
5. Phase G note (`PHASE_G` §32.4): cloud functions already enforce non-negative stock; offline policy is Phase M (OD6).
6. Quality gates (`MASTER_PLAN` §14/§19): `flutter analyze` 0 errors / 0 warnings; `flutter test` all passing except documented pre-existing failures.
7. Where documents and code disagree, current implemented reality is recorded in §4–§8 and the higher authority (master plan / architecture plan) governs.

---

## 4. Current-State Forensics

### 4.1 Production inventory mutation entry points (proven callers)

| Entry point | Caller | Path |
|---|---|---|
| Sale creation | `insertInvoiceWithItems` | `app/lib/screens/sales/invoice_screen.dart:665` |
| Return creation | `insertReturn` | `app/lib/screens/returns/returns_screen.dart:270` |
| Stocktake | `saveInventoryCount` | `app/lib/screens/inventory_count/inventory_count_screen.dart:196` |
| Product edit | `updateProduct` | `app/lib/screens/inventory/inventory_screen.dart:236` |
| Legacy import | workbook import (one tx) | `app/lib/database/workbook_importer.dart:_applyImport` |
| Cloud hydration/pull | direct row writes | `app/lib/sync/hydration_service.dart`, `incremental_sync_service.dart` |

There is exactly ONE production sale path today: multi-line invoice creation. Single-sale helpers exist but are not wired to UI (see §5).

### 4.2 Sync runtime activation status

`SyncEngine`, `SyncWorker`, `HydrationService`, `IncrementalSyncService` have **no construction sites anywhere under `app/lib/`** — they are exercised only by tests with injected fakes. The sync runtime remains frozen (Phase L freeze posture; `PHASE_L` OD-L1 records sync activation as a post-M concern). Phase M therefore hardens the machinery AND its semantics while the runtime wiring decision stays explicit (§36 DR-M09).

### 4.3 Cloud inventory surface

Tables (`20260820000025_phase_g_cloud_data_foundation.sql`): `cloud_products` (component columns opening/sold/returned/adjustment + derived `current_quantity`; CHECK constraints keep components ≥ 0), `cloud_sales`, `cloud_returns`, `cloud_inventory_count`, plus `server_version` added to all 9 cloud tables and a `sync_log` audit table with `UNIQUE(idempotency_key)` in `20260820000026_phase_h_sync_core.sql`.

Server RPCs (SECURITY DEFINER, all call `require_shop_permission`):

| RPC | File:lines | Stock semantics |
|---|---|---|
| `create_cloud_sale_with_stock` | migration 25:815–882 | read check `current_quantity < p_quantity` raises; conditional `UPDATE ... WHERE current_quantity >= p_quantity`; `IF NOT FOUND THEN RAISE`. Atomic plpgsql. No idempotency parameter. Returns bare UUID (no version). |
| `create_cloud_invoice_with_items` | migration 25:1044–1116 | loops `create_cloud_sale_with_stock` per item inside one atomic call; per-line guard inherited. Invoice-number allocation via `MAX+1`. |
| `delete_cloud_sale_with_revert` | migration 25:885–939 | unconditional revert of sold_quantity; soft-deletes sale; auto-deletes empty invoice. |
| `create_cloud_return_with_stock` | migration 25:942–997 | unconditional increment of returned_quantity. No idempotency parameter. |
| `delete_cloud_return_with_revert` | migration 25:1000–1041 | unconditional decrement of returned_quantity. |
| `save_cloud_inventory_count` | migration 25:1119–1164 | inserts count row; `v_adjustment := p_actual_quantity - v_product.current_quantity`; applies delta to `inventory_adjustment`. Snapshot-at-call-time semantics. No idempotency parameter. |
| `update_cloud_product` (v2) | migration 26:61–148 | `p_expected_version` mismatch returns `{status:'CONFLICT', server_version, expected_version, server_data}` JSONB; otherwise bumps `server_version`. |

Concurrency mechanism actually present server-side: READ COMMITTED + conditional UPDATE (`WHERE current_quantity >= ?`) relying on PostgreSQL row-level write locking during the UPDATE statement. **No `SELECT FOR UPDATE`, no advisory locks, no serializable isolation, no reservation table exists today** — and none is prescribed without need (see §15).

---

## 5. Existing Local Inventory Atomicity

Answers required by the mandate:

```text
LOCAL_SINGLE_DEVICE_ATOMICITY =
  PROVEN for the production paths:
  - insertInvoiceWithItems (database_helper.dart:1163–1251): one db.transaction wraps invoice header,
    each sale line insert, each product decrement, and each queue enqueue (_enqueueAfterWrite on the
    same txn). Any throw rolls back everything including queue entries.
  - insertReturn (1538–1594), deleteSale/deleteReturn, updateReturn: transactional; queue entries on same txn.
  - saveInventoryCount (2051–2111): transactional; absolute SET via derived adjustment;
    CAS guard WHERE id = ? AND currentQuantity = ? (prior-value compare), affected==0 throws.
  NOT transactional (proven gaps):
  - updateSoldQuantity/revertSoldQuantity/updateReturnedQuantity/revertReturnedQuantity
    (961–1027) are bare db.update calls with NO transaction and NO queue enqueue — but grep proves
    ZERO callers in lib/ or test/ → DEAD CODE (INTENTIONAL_SEAM / cleanup candidate).
  - data_importer.dart demo seeding is non-transactional (gated behind MUAMAN_SEED_DEMO dart-define).
  - Hydration/incremental writes apply rows one-by-one outside any transaction.

LOCAL_RACE_GUARD =
  PROVEN double guard on guarded sale paths:
  - Read check: `if (product.currentQuantity < sale.quantity) throw StateError(...)` (1120–1124; invoice variant 1209–1212).
  - Conditional SQL: `WHERE tp.prefix('id = ? AND currentQuantity >= ?')` + affected==0 throw (1143–1157);
    invoice variant uses raw 'id = ? AND currentQuantity >= ?' WITHOUT tenant prefix (1240–1242)
    → RISK (cosmetic while ids are globally unique; inconsistency vs scoped helper).
  - Duplicate line items referencing the same product are allowed; the loop re-reads the product each
    iteration so the cumulative conditional guard still prevents oversell across duplicate lines (M-C29 safe locally).
  UNGUARDED paths: insertSale (1080–1089) updates without condition (NO production callers — test seam);
    insertReturn restore (1575–1590) and updateProduct full-map write incl. quantity columns (863–868) are unconditional.

MULTI_DEVICE_AUTHORITY =
  NOT ESTABLISHED YET. Server functions enforce non-negative + conditional update (authoritative when reached),
  but client retry/idempotency gaps (below) mean multi-device replay can corrupt totals before any conflict logic runs.

CLOUD_ATOMICITY =
  PROVEN per-RPC atomicity (single plpgsql body = one transaction) for sale+stock, invoice+items,
  return+stock, count+adjustment. PROVEN gap: NO database-layer idempotency on any stock-touching RPC;
  `sync_upsert_entity` (migration 26:290–346) is an ID-ONLY STUB that checks sync_log and inserts a log row
  but never applies any payload — it is not used by any adapter flow.
```

---

## 6. Existing Cloud Inventory Semantics

- Canonical product quantity lives ONLY in `cloud_products.current_quantity`, always recomputed from the four component columns (equation holds server-side in every RPC).
- Sales DO decrement server stock; sale insert + stock decrement are one PostgreSQL transaction; the decrement is conditional (`WHERE current_quantity >= p_quantity`) → oversell rejected with exception.
- Returns increment `returned_quantity` unconditionally; counts adjust `inventory_adjustment` by snapshot delta.
- `server_version` changes atomically with stock inside the same UPDATE statements (functions bump version in the same statement or return conflict before mutating). `create_*` RPCs do NOT return the new `server_version` — the client cannot learn it from the create response (IMPLEMENTATION_GAP for convergence bookkeeping).
- Idempotency: NONE at the database layer for `create_cloud_sale_with_stock`, `create_cloud_return_with_stock`, `create_cloud_invoice_with_items`, `save_cloud_inventory_count`. A retried RPC re-executes fully: duplicate sale row + second decrement (M-C10/M-C11/M-C30 hazards are REAL today). `sync_log.idempotency_key UNIQUE` exists as infrastructure but nothing consults it in these paths.
- Tenant boundary: every RPC begins with `PERFORM require_shop_permission(p_shop_id, ...)`; shop_id scoping appears in every SELECT/UPDATE predicate; RLS enabled on `sync_log`. Direct client UPDATE of `cloud_products` quantity is not part of any client code path (clients go through repositories/RPCs only).
- Inventory count ordering: none — `count_date` is set to `now()` at the SERVER, discarding the observation time; a late-arriving older count would still compute its delta against whatever stock exists at arrival time (see §18).

---

## 7. Existing Sync/Queue/Conflict Architecture

Local `sync_queue` (SQLite v14): columns id, entity_type, entity_id, operation(CREATE/UPDATE/DELETE), payload(JSON text), created_at, synced_at, retry_count, status(PENDING/SYNCED/FAILED/CONFLICT), conflict_data(text), idempotency_key, shop_id.

Proven behaviors:

- Enqueue is transactional with the business write (`_enqueueAfterWrite`, database_helper.dart:232–274; doc comment lines 222–224 mandates same-executor usage).
- FIFO processing `created_at ASC` (`getPendingEntries`, sync_queue_repository.dart:141–157); tenant defense-in-depth guard in engine (sync_engine.dart:83–91); license/connectivity/shop gates (38–69).
- Retry: `markFailed` increments retry_count, caps at 5 then FAILED; exponential backoff delays [0s,5s,30m→(0,5s,30s,2m,10m)] in `_shouldRetryLater` (sync_engine.dart:198–215). `retryEntry` resets to PENDING.
- `markConflict(id, string)` stores a human-readable reason; **`conflict_data` is NEVER read back anywhere** (grep-proven: only writer is markConflict; only reader is round-trip serialization test).
- `cleanupSynced(olderThanDays: 7)` deletes SYNCED rows — any conflict evidence stored only on the queue dies with cleanup.
- Idempotency keys are generated LOCALLY PER ENQUEUE as `$entityType-$entityId-$op-$epochMicros-$seq` (`_generateSyncKey`, database_helper.dart:213–218). Consequences (PROVEN):
  - The dedup lookup in `enqueue` (sync_queue_repository.dart:122–125) can essentially never hit — keys are unique by construction.
  - Retries reuse the SAME queued key (good), but a crash between business-commit and queue-commit, or a duplicate user action, produces a NEW key for the same logical operation → duplicate financial effect upstream once sync activates.
- Crash windows (per §15 lettered cases):
  - A. before RPC: entry stays PENDING → retried later. Safe.
  - B./C. during RPC / after commit before response: outcome unknown to client; retry re-sends same key; server has NO idempotency → duplicate sale/decrement possible. UNSAFE.
  - D. after response before markSynced: same as C. UNSAFE.
  - E./F. during/after conflict resolution before local apply: today nothing is applied at all (§8/M), so this window collapses into "conflict silently dropped". UNSAFE (differently).
  - G. local apply before audit recording: no audit record exists to lose. GAP.

---

## 8. Proven Gaps and Non-Gaps

Each finding classified per the mandated taxonomy.

### ConflictResolver findings (file: app/lib/sync/conflict_resolver.dart)

| # | Finding | Classification |
|---|---|---|
| CR-1 | `latestTimestampWins` does NOT compare any timestamps — it unconditionally returns `localPayload` (lines 69–77, 113–120). | PROVEN BUG (name vs behavior) |
| CR-2 | `lastWriterWins` does NOT select the latest writer either — it unconditionally accepts the LOCAL payload ("LWW: local changes accepted", lines 49–57, 95–102); no timestamp/version comparison occurs. | PROVEN BUG |
| CR-3 | `serverAuthoritative` returns `serverData` as resolvedPayload and preserves zero local financial evidence beyond a log line; for sales/returns the local event row itself is untouched (it was already committed locally), so no financial row is destroyed locally — but the divergence between local row and server row persists (see SG-1). | IMPLEMENTATION_GAP |
| CR-4 | Product quantity conflicts receive the SAME whole-row payload treatment as metadata; there is no component-level merge and no protection that a resolved product snapshot preserves concurrent-sale effects. | PROVEN RISK |
| CR-5 | Resolution operates on ROW SNAPSHOTS, never on business operations (sale/return/count events are not visible to the resolver at all). | PROVEN (design fact feeding §14 model) |
| CR-6 | `localServerVersion >= currentServerVersion → null` causes markConflict("could not be resolved") — a dead-end state nothing ever reads. | INTENTIONAL_SEAM → Phase M replaces |

### Resolved-payload lifecycle finding (mandate §14) — MAJOR

Trace proven end-to-end (`sync_engine.dart:136–154`):

```text
upsertEntity result.conflict == true
→ resolveVersionConflict(...) returns ConflictResolution
→ _conflictResolved(entry, resolution) — LOGGING ONLY (217–225)
→ markSynced(entry.id)                      ← queue closed
→ NOTHING ELSE.                              ← ???
```

```text
Where is resolvedPayload applied?  NOWHERE. Not written to SQLite. Not written back to cloud.
Is serverData hydrated separately? Only if HydrationService/IncrementalSyncService run later with
                                   serverData fetched again — and neither service is constructed in
                                   production code, and neither protects rows with pending local ops.
Is the queue marked SYNCED before convergence? YES — unconditionally, immediately, for every
                                   resolvable conflict regardless of policy.
```

Classification: **PROVEN IMPLEMENTATION_GAP — "resolve" currently means "log and forget".**
For `lastWriterWins`/`latestTimestampWins` the local row keeps its data while the server keeps ITS data → permanent silent divergence (both sides claim SYNCED). For `serverAuthoritative` the local row also keeps its original data → same divergence. This is the single most important Phase M correction.

### Other proven facts

| # | Finding | Classification |
|---|---|---|
| SG-1 | No echo-suppression problem exists yet because hydration bypasses `_enqueueAfterWrite` (direct db writes) — pull does not re-enqueue. But hydration overwrites rows UNCONDITIONALLY on `server_version > local` with no check for pending queue operations on the same entity → can stomp a pending offline edit before it is pushed. | PROVEN RISK |
| SG-2 | Hydration/incremental writes are per-row autocommit, not transactional; crash mid-hydration leaves partial state but is restartable (version gate makes re-run idempotent-ish). | SAFE (restartable) / RISK (partial visibility) |
| SG-3 | `deleted_at` handling deletes the local row outright even when other local references may exist. | RISK (out-of-M scope unless sale-linked; noted) |
| SG-4 | Local schema version is 14 (`database_helper.dart:381`). | FACT |
| SG-5 | `widgets/sync_conflict_dialog.dart` exists (Phase H basic dialog) but is referenced by NO screen — dead UI seam awaiting Phase M review workflow. | INTENTIONAL_SEAM |
| SG-6 | Queue statuses PENDING/SYNCED/FAILED/CONFLICT exist; CONFLICT is terminal/unread. | FACT (feeds §20 lifecycle) |
| SG-7 | Server `create_*` RPCs do not return new `server_version` → clients cannot update their cached version from the create response. | IMPLEMENTATION_GAP |
| SG-8 | `updateSoldQuantity` family (db_helper 961–1040) is dead, non-transactional, non-enqueuing code. | SAFE-if-unused / DELETE candidate (kept frozen this session) |
| SG-9 | COGS snapshots (`cost_price`, `cogs`) are snapshotted into sale rows locally and in `create_cloud_sale_with_stock` (migration 25:856–864); no reconciliation path rewrites them. | SAFE (must stay so — INV-M14) |
| SG-10 | Negative stock: local equation CAN produce negative `currentQuantity` after two offline oversells reconcile (components stay ≥ 0 individually? no — sold_quantity grows past opening+returned+adjustment; CHECK constraints only bind individual components ≥ 0, so negative current IS representable server-side). Preflight migration tooling already detects negative stock (`migration/preflight_service.dart:70`). | FACT (feeds §17) |

---

## 9. Owner Decisions / Defaults / Open Gates

Master-plan namespace decisions, verified against ALL root documents:

| OD | Meaning | Status | Evidence chain |
|---|---|---|---|
| OD4 | Offline grace duration | **STILL_OPEN.** Phase H implemented reversible defaults (Trial: until trial_ends_at; Paid ACTIVE: 7 days; Perpetual: 14 days) — TEMPORARY_SAFE_DEFAULT / IMPLEMENTED_HISTORICAL_DEFAULT, NOT owner approval (`PHASE_H` §§20.2, 33 checklist wording "defaults set"). |
| OD6 | Negative stock policy for offline | **STILL_OPEN.** Assigned to Phase M everywhere (`MASTER_PLAN` §6; `PRE_A`:628; `PHASE_G`:396). No document claims resolution. Architecture Option D ("negative allowed") and the recommended default (server-authoritative) are ARCHITECTURAL_RECOMMENDATION only. |
| OD7 | Whether seller offline sale is allowed | **STILL_OPEN.** Phase H default: BLOCKED for salesOnly (TEMPORARY_SAFE_DEFAULT). Phase L recorded an INTERIM answer permitting local seller selling under the sync-freeze posture (`PHASE_L`:510–512) — an IMPLEMENTED_HISTORICAL_DEFAULT, explicitly labeled interim, with OD-L1 keeping the question open. |

Phase M structure rule: unresolved commercial policy (OD6 especially) MUST be isolated behind a single policy seam (see §17, slice M-I04) so the owner's eventual choice flips one decision point, not the sync engine. This plan does NOT claim any owner approval and does NOT block planning on the open gates; it freezes explicit DECISION GATES (§36 DR-M05/06/07).

---

## 10. Phase M Objective

Make every stock discrepancy under Windows/Android multi-device operation **explainable, auditable, restartable, and safe**, by:

1. Fixing the proven conflict-resolution defects (CR-1..CR-6, SG-1, §8 major gap).
2. Guaranteeing idempotent inventory effects at the DATABASE layer (server) and queue layer (client).
3. Establishing server-authoritative reconciliation for stock while preserving every legitimate financial event.
4. Defining deterministic inventory-count ordering semantics.
5. Delivering the deferred manual conflict-review workflow (owner-only, Arabic RTL, Windows+Android).
6. Persisting conflict/audit history that survives queue cleanup.
7. Preserving proven local single-device atomicity (INV-M13) — no regression.

---

## 11. In Scope

- ConflictResolver semantic corrections + strategy model (events vs snapshots).
- SyncEngine conflict lifecycle: real application of resolutions, convergence, persisted conflicts.
- Server-side idempotency for all stock-touching RPCs (additive migration).
- Server-side return of authoritative state (new server_version/current stock) from create paths.
- Reconciliation service for offline oversell detection and adjustment-event generation.
- Inventory-count cutoff/ordering semantics (observation timestamp carried from device).
- Local additive SQLite v15 evolution (conflict audit persistence + lifecycle fields where needed).
- Owner-facing conflict review UI (owner permission-gated) replacing/extending the dead `SyncConflictDialog` seam.
- Failure/restart recovery for every §15 crash window.
- Tests: full matrix §29–§30.
- Documentation of defaults vs open decisions (§9) with isolated policy seams.

## 12. Explicit Non-Goals

Phase N (cross-platform Excel import), Phase O (invoice branding/delivery), Phase P (production hardening/chaos/release), camera barcode scanning, Play Store publishing, billing/subscriptions, marketing rebrand, installer redesign, supplier/purchase domain, VAT, general sync-engine rewrite unrelated to inventory conflicts, general UI modernization, unrelated technical debt (dead-code removal happens ONLY if touched incidentally and is separately justified in the implementation session), activating the sync runtime schedule itself (DR-M09 keeps this an explicit gate — M builds and proves the machinery; runtime enablement sequencing follows Phase L OD-L1 guidance).

---

## 13. Inventory Authority Model

```text
SERVER (cloud_products component columns + current_quantity) = sole STOCK AUTHORITY for a shop.
CLIENT (SQLite products)                                     = offline projection + event capture.
FINANCIAL EVENTS (sales/returns/invoices)                    = append-only truth on BOTH sides;
                                                               never rewritten by reconciliation.
INVENTORY COUNTS                                             = observations with device observation time;
                                                               applied as adjustment EVENTS, not row wins.
```

Rules frozen:

- IA-1: When connected, stock mutations go through server RPCs whose responses carry authoritative `current_quantity` + `server_version`; clients adopt them.
- IA-2: When offline, clients sell/return/count against local projection using existing atomic guards; effects are queued as EVENTS.
- IA-3: On sync, events are APPLIED (not merged) by the server in queue order; resulting authoritative state flows back to all devices.
- IA-4: A device never "wins" stock with a snapshot. The only stock snapshots permitted are count observations converted to adjustments server-side (§18).
- IA-5: Reconciliation may change `inventory_adjustment` (creating an explicit adjustment event) — never `sold_quantity`/`returned_quantity` of an existing event, never COGS snapshots.

## 14. Financial Event vs Snapshot Model

Frozen distinction:

| Class | Entities | Conflict treatment |
|---|---|---|
| EVENT-LIKE (immutable) | sales, returns, invoices, inventory-count observations (as events), reconciliation adjustments | NEVER LWW-resolved. Replay must be idempotent (key-based). Conflicts become REVIEW items, never auto-discard. |
| SNAPSHOT (mutable) | product metadata (name/barcode/cost), customers, expenses, categories, shop settings | Timestamp/version policies permitted AFTER fixing CR-1/CR-2 (true latest-writer comparison on server timestamps). |

Rule ES-1: The generic product LWW policy MUST NOT decide `sold_quantity`/`returned_quantity`/`inventory_adjustment`/`current_quantity`. Those columns are owned exclusively by event application + count/reconciliation adjustments. Product-row pushes therefore carry metadata components; stock components travel only through sale/return/count/adjustment events. (Implementation detail frozen for slices M-I01/M-I02.)

---

## 15. Online Concurrency Model

Smallest correct mechanism given audited reality: retain the EXISTING pattern — READ COMMITTED + conditional UPDATE with row-lock semantics + version check — and add idempotency:

- OC-1: All stock-touching RPCs gain `p_idempotency_key TEXT` and a sync_log consult: if key exists with success status, return the ORIGINAL result (status IDEMPOTENT) without re-executing. Insert of the log row and business mutation share the RPC's single transaction → crash-safe (C-case retries converge).
- OC-2: `create_cloud_sale_with_stock` keeps its conditional-update guard (already correct under concurrent online sales: M-C01/M-C02 → loser gets exception, no partial state).
- OC-3: Create-path RPCs additionally RETURN `JSONB {id, current_quantity, server_version}` so clients update projections atomically-with-knowledge (fixes SG-7).
- OC-4: No `SELECT FOR UPDATE`/advisory locks/reservations are introduced — the conditional UPDATE already provides the needed critical section; adding heavier mechanisms is unjustified by evidence (minimal-change principle).
- OC-5: Invoice path unchanged structurally; inherits per-item idempotency via ONE invoice-level key + item index derivation (single logical op ⇒ single effect; M-C28/M-C29).

## 16. Offline Conflict Model

- OF-1: Offline sale pushed when server stock insufficient: the SALE EVENT IS PRESERVED (zero data loss). Server applies the event, allowing `current_quantity` to go negative ONLY IF OD6 gate resolves to policy B/C/D-family; under the CURRENT safe default the event is held in REVIEW_REQUIRED with the conflict record capturing everything (§36 DR-M06). No sale is deleted in either branch.
- OF-2: Offline/offline last-unit double-sell (canonical case): both events sync (order = queue created_at, cross-device order = server arrival order); first decrements to 0; second triggers OF-1 handling; discrepancy becomes an explicit adjustment/review artifact — always explainable.
- OF-3: Version-conflict on product metadata push: fixed LWW compares server `updated_at`/version; loser is notified via conflict record; stock components excluded per ES-1.
- OF-4: Every conflict produces a persistent record (§21) BEFORE the queue entry transitions; the queue entry may close only when the conflict record exists (restartability).

## 17. Negative Stock / Oversell Policy Boundary

Options evaluated against [zero data loss, financial truth, auditability, offline-first, owner usability, inventory equation, idempotency, complexity]:

| Option | Verdict |
|---|---|
| A Reject one sale at sync | Violates zero-data-loss/financial-truth (a completed commercial event is retroactively voided). REJECTED as automatic behavior. |
| B Preserve both + allow negative calculated stock | Preserves events; equation stays explainable (negative current is derivable); simplest. Risk: usability/accounting confusion (arch-doc warning). |
| C Preserve both + reconciliation adjustment event | Same preservation, PLUS explicit adjustment row making the discrepancy a first-class record; slightly more complex. |
| D Preserve both + require owner resolution | Maximum control; adds operational burden; risk of stuck queues if owner absent. |
| E Reservation-based prevention | Largest architectural change; breaks offline-first promise; REJECTED for M. |
| F Hybrid | B or C online-visible immediately + D-style owner confirmation for the adjustment. |

FROZEN BOUNDARY: Phase M implements the MECHANISM for options B/C/D behind one isolated policy seam (`InventoryOversellPolicy`, single decision point in reconciliation service), with the SHIPPED DEFAULT = **Option C mechanics + owner-notification** (preserves events, keeps equation exact, creates the explicit adjustment, alerts owner) while OD6 REMAINS OPEN — the default is classified ARCHITECTURAL_RECOMMENDATION + TEMPORARY_SAFE_DEFAULT, NOT owner approval. Flipping to pure-B (auto-negative, no adjustment) or strict-D (block until owner acts) after owner decision touches ONLY the seam + its tests.

## 18. Inventory Count Ordering Semantics

FROZEN MODEL — count = absolute physical observation AT OBSERVATION TIME, applied as a derived adjustment event with explicit causality rules:

- IC-1: Client sends `observed_at` (device UTC timestamp of the physical count) with the count event; server stores it (additive column) instead of fabricating `count_date = now()`.
- IC-2: Application rule at server: when applying a count, first apply (in causal order) any queued sale/return events whose OPERATION time precedes `observed_at`; then set adjustment so that `current_quantity` equals the observed value MINUS the net effect of events that occur AFTER `observed_at` but are already applied. Equivalently: the count answers "how much stock existed at observed_at"; post-count events re-apply on top.
- IC-3: Two counts on one product: higher `observed_at` wins as the standing observation; the older count is retained as history but does not re-adjust (latest-OBSERVED count wins — fixes the current server-time fabrication).
- IC-4: Deterministic scenario (Device A count=10; B pending sale=2 PRE-count; C sale=1 POST-count): final stock = 10 − 1 = 9; B's sale is inside the counted baseline (its effect is absorbed by the adjustment); every step is recorded as ordered events → explainable. This ordering is enforced by applying queue events in `(observed_at/operation-time, arrival)` order server-side within the count-application function.
- IC-5: "Latest count wins" as a ROW policy is retired; counts are events (consistent with §14).

## 19. Sale/Return Reconciliation

- SR-1: Sale/return events apply exactly once (OC-1 idempotency); replay yields IDEMPOTENT no-op returning original result.
- SR-2: Return restoring stock for a sale that itself is in conflict-review: return is linked (barcode+quantity+time window evidence captured in conflict record) and held in the same review bundle rather than double-restoring (guards M-C30).
- SR-3: Deletion/revert RPCs gain the same idempotency key discipline (revert-at-most-once — INV-M03).
- SR-4: Reconciliation never edits historical `cogs`/`cost_price` snapshots (SG-9 preserved).

## 20. Conflict Lifecycle

Existing enum values PENDING/SYNCED/FAILED/CONFLICT are INSUFFICIENT (CONFLICT is unread terminal; no review states). Additive extension frozen (SQLite v15 + Dart enum):

```text
PENDING → SYNCED                       (happy path)
PENDING → FAILED (retry≤5)             (transient)
PENDING → CONFLICT → REVIEW_REQUIRED → RESOLUTION_PENDING → RESOLVED
                   └────────────── (auto-resolvable) ↗
```

- CL-1: `REVIEW_REQUIRED` — conflict persisted, needs owner (OD6-D branch, event-vs-event clashes).
- CL-2: `RESOLUTION_PENDING` — owner chose an action; system executing/verifying.
- CL-3: `RESOLVED` — terminal; carries resolution method (AUTO/POLICY/OWNER), resolved_by, resolved_at, note.
- CL-4: Old CONFLICT value maps to REVIEW_REQUIRED on upgrade (backfill, additive; no rename/drop).
- CL-5: Restart behavior: any non-terminal state resumes correctly after process death (states live in SQLite, not memory).

## 21. Conflict Persistence / Audit

Existing `sync_log` (server, UNIQUE idempotency_key, conflict_details JSONB) + queue `conflict_data` are NOT sufficient (queue rows cleaned after 7 days; conflict_data is a flat string never read back; no who/when/outcome). Smallest additive design frozen:

- LOCAL table `conflict_audit` (SQLite v15, additive): id, shop_id, entity_type, entity_id(+uuid), product_barcode/name, operation, local_before/local_after (JSON), server_before/server_after (JSON), related_event_ids (JSON), local_version, server_version, detected_at, status(lifecycle §20), resolution_method, resolved_by_user, resolved_at, resolution_note, resulting_adjustment_id.
- SERVER: extend `sync_log.conflict_details` usage + additive columns `resolved_by UUID NULL, resolved_at timestamptz NULL, resolution_note TEXT NULL` on sync_log OR a sibling `conflict_resolution_log` table — FINAL CHOICE FROZEN AS sibling-table approach is REJECTED for minimality; additive columns on sync_log chosen (migration 28 §26).
- AU-1: Records are append/transition-only; queue cleanup CANNOT remove audit history.
- AU-2: Contents prove: what/which shop/product/operations/versions/both-worlds' beliefs/who/when/resulting stock (mandate §24 list satisfied field-for-field).
- AU-3: No secrets, no personal data beyond user uuid.

## 22. Owner Review UX

Minimum workflow (extends dead seam `widgets/sync_conflict_dialog.dart` → new owner screen):

Fields shown: product identifier + name + barcode, local before/after quantities+amounts, server before/after, affected sale/return/count references, device identity, user identity, timestamps, reason, recommended action, resolution state.

Constraints frozen: Arabic RTL strings; usable on Windows (mouse/keyboard) and Android (touch); entry gated by owner-level permission (`admin.settings.access`-class — exact permission frozen in DR-M10 as `inventory.resolve` mapped onto existing owner-only role capability, fail-closed); employees/sellers can SEE conflicts caused by their own events in a read-only banner (no resolve affordance); resolution actions call server RPCs that independently re-verify permission server-side (never trust UI).

## 23. Authorization / Tenant / Licensing

Preserved integrations (verified present): `ActiveShopContext` (services/active_shop_context.dart), `TenantIsolationGate` (services/tenant_isolation_gate.dart), `PermissionResolver` (rbac + services/permission_resolver.dart), server `require_shop_permission` in every RPC, license gates in SyncEngine (49–58) and worker session check.

Frozen authority matrix:

| Action | Who |
|---|---|
| View conflicts | Owner (+seller read-only own-event banner) |
| Acknowledge conflict | Owner |
| Resolve conflict / choose override | Owner (UI) + server-side permission re-check (RPC) |
| Create inventory adjustment | Owner (existing inventory.edit/stocktake permissions preserved) |
| Retry failed operation | Owner; seller retries only own pending non-conflicted ops |
| Override recommended resolution | Owner (always requires note) |

TA-1: Conflict records carry shop_id end-to-end; every query filtered by bound shop; cross-shop impossibility re-tested (M-C19). TA-2: Revoked/suspended/license-invalid mid-retry behaves as today (permissionDenied → FAILED; license → cycle break) with NEW guarantee: no half-applied reconciliation (transactional apply, §24). TA-3: Server authorization is the enforcement point; client gating is UX only.

## 24. Idempotency / Crash Recovery

Every §15 window after Phase M:

| Window | Guarantee |
|---|---|
| A before RPC | unchanged (retry PENDING) |
| B/C/D around RPC | SAME idempotency key re-sent; server sync_log consult returns original outcome; at-most-once effect (OC-1). Client marks SYNCED from IDEMPOTENT/SYNCED response carrying authoritative state. |
| E during resolution | conflict record written transactionally WITH lifecycle transition; crash leaves REVIEW_REQUIRED recoverable (CL-5). |
| F after resolution before apply | apply step is a keyed, restartable local transaction; re-run detects completion marker. |
| G apply before audit | audit row + apply share one local transaction. |

Duplicate-key-vs-different-key: same key ⇒ no-op (M-C11); different key for same logical event ⇒ prevented at SOURCE by deriving keys deterministically from event identity (`entityUuid:operation:occurrence-token` persisted with the event at creation time — replaces micros/counter scheme; M-C12/M-C10).

## 25. Cross-Platform Behavior

All domain logic (resolver, reconciliation, queue, audit) stays in shared `app/lib/sync/**` + `app/lib/database/**` — zero platform forks. Behavior parity matrix Windows↔Windows, Windows↔Android, Android↔Android covered by scenarios M-C25/26/27 with identical expected outcomes (only device identity differs). No Gradle/Android-specific changes. No package rebranding/signing/scanner/publishing.

## 26. Schema / Migration Impact

```text
PHASE_M_SCHEMA_IMPACT = ADDITIVE_MIGRATION_REQUIRED
```

Justification (from §5–§8 evidence): DB-layer idempotency (OC-1), count observation timestamps (IC-1), conflict lifecycle states (§20), durable audit (§21) cannot be built on the current schemas.

Planned (NOT executed in this session):

SQLite: version 14 → 15, `onUpgrade` additive script + fresh-create parity in `_createDB`:
- `CREATE TABLE conflict_audit (...)` (fields per §21).
- `ALTER TABLE sync_queue ADD COLUMN resolution_status TEXT` (nullable; legacy rows = implicit old semantics; CONFLICT backfill → 'REVIEW_REQUIRED').
- `ALTER TABLE sync_queue ADD COLUMN occurrence_token TEXT` (deterministic key derivation; nullable for legacy rows).
- Rollback: v15 additions are ignored-by-old-code columns/table; downgrade path = document-only (no destructive revert); backup-before-migrate per house convention; migration tests in `app/test/database/`.

Supabase: single additive migration `supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql` (filename/order next after 27):
- Replace (CREATE OR REPLACE — additive behavior) stock RPCs with idempotency-key + rich-return variants (OC-1/OC-3).
- `ALTER TABLE cloud_inventory_count ADD COLUMN IF NOT EXISTS observed_at TIMESTAMPTZ` (+ use in ordering logic).
- `ALTER TABLE sync_log ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES auth.users(id), ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ, ADD COLUMN IF NOT EXISTS resolution_note TEXT`.
- New GRANTs consistent with existing pattern; RLS unchanged in spirit (shop-scoped).
- Backfill: observed_at = count_date for existing rows; NULL resolution columns = unresolved/legacy.
- Rollback/recovery: additive columns nullable → previous-version code unaffected; functions remain callable with new optional args defaulted NULL (old signatures preserved).

No renames, no drops, no frozen-structure changes. No migration is created in THIS session.

## 27. Exact Implementation File Manifest

Classification frozen (CREATE / MODIFY / DELETE / NO CHANGE):

| Path | Action | Reason |
|---|---|---|
| `PHASE_M_INVENTORY_CONFLICT_HARDENING_PLAN.md` | NO CHANGE (already committed by planning) | — |
| `app/lib/sync/sync_status.dart` | MODIFY | lifecycle states, oversell policy enum, event-policy types |
| `app/lib/sync/adapters/entity_sync_adapter.dart` | MODIFY | contract additions (event identity, metadata-vs-stock payload split, observed_at passthrough) |
| `app/lib/sync/adapters/product_sync_adapter.dart` | MODIFY | metadata-only payload split (ES-1), version handling |
| `app/lib/sync/adapters/sale_sync_adapter.dart` | MODIFY | event idempotency identity, rich-return adoption |
| `app/lib/sync/adapters/return_sync_adapter.dart` | MODIFY | same as sale |
| `app/lib/sync/adapters/inventory_count_sync_adapter.dart` | MODIFY | observed_at, event treatment |
| `app/lib/sync/adapters/invoice_sync_adapter.dart` | MODIFY | invoice-level idempotency key propagation |
| `app/lib/sync/adapters/customer_sync_adapter.dart` | MODIFY | true-LWW comparison inputs (timestamps) |
| `app/lib/sync/adapters/expense_sync_adapter.dart` | MODIFY | true-LWW comparison inputs |
| `app/lib/sync/adapters/shop_settings_sync_adapter.dart` | MODIFY | true-LWW comparison inputs |
| `app/lib/sync/conflict_resolver.dart` | MODIFY | fix CR-1/CR-2; event-vs-snapshot strategies; evidence-preserving outputs |
| `app/lib/sync/sync_engine.dart` | MODIFY | apply resolutions (real apply), lifecycle transitions, conflict-record writes, keyed retries |
| `app/lib/sync/sync_queue_repository.dart` | MODIFY | new states, deterministic key storage, read-back APIs, transactional transitions |
| `app/lib/sync/hydration_service.dart` | MODIFY | pending-op protection (SG-1), transactional batch apply, echo-safety retained |
| `app/lib/sync/incremental_sync_service.dart` | MODIFY | same as hydration |
| `app/lib/sync/sync_worker.dart` | MODIFY | reconciliation pass hook + recovery sweep on start |
| `app/lib/sync/reconciliation_service.dart` | CREATE | oversell detection, adjustment-event creation, OD6 policy seam |
| `app/lib/sync/conflict_audit_repository.dart` | CREATE | conflict_audit CRUD + lifecycle queries |
| `app/lib/sync/inventory_oversell_policy.dart` | CREATE | isolated OD6 decision point (§17) |
| `app/lib/database/database_helper.dart` | MODIFY | v15 migration + fresh-create parity; tenant-prefix fix on invoice/count guards; deterministic key generator replacement |
| `app/lib/widgets/sync_conflict_dialog.dart` | MODIFY | become reviewed component used by owner screen (RTL, fields §22) |
| `app/lib/screens/admin/conflict_review_screen.dart` | CREATE | owner conflict review list + detail + resolution actions |
| `app/lib/screens/returns/returns_screen.dart` | NO CHANGE | return creation path already transactional+enqueued; no edits needed |
| `app/lib/screens/sales/invoice_screen.dart` | NO CHANGE | creation path unchanged (guards fixed inside database_helper) |
| `app/lib/screens/inventory_count/inventory_count_screen.dart` | MODIFY | pass observed_at (device time) to saveInventoryCount |
| `app/lib/models/*` | NO CHANGE | models already carry needed fields; adjustment events modeled via payloads |
| `app/lib/rbac/**`, `app/lib/services/active_shop_context.dart`, `tenant_isolation_gate.dart` | NO CHANGE | integration points verified sufficient |
| `supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql` | CREATE | §26 server additive migration |
| `supabase/migrations/*` (existing 10–27) | NO CHANGE | frozen |
| `app/test/database/schema_v15_migration_test.dart` | CREATE | v14→v15 upgrade + fresh-create parity |
| `app/test/database/inventory_atomicity_regression_test.dart` | CREATE | §29-A regression lock |
| `app/test/sync/conflict_resolution_semantics_test.dart` | CREATE | resolver fixes + event/snapshot model |
| `app/test/sync/conflict_apply_convergence_test.dart` | CREATE | §8-major-gap closure: resolvedPayload actually applied both directions |
| `app/test/sync/idempotency_server_contract_test.dart` | MODIFY (existing `idempotency_test.dart` extended) | keyed replay matrix M-C10..C13 |
| `app/test/sync/reconciliation_test.dart` | CREATE | oversell scenarios M-C03/04/05/09, policy seam branches |
| `app/test/sync/inventory_count_ordering_test.dart` | CREATE | IC-1..IC-5, M-C06..C08 |
| `app/test/sync/crash_recovery_test.dart` | CREATE | windows A–G restartability |
| `app/test/features/conflict_review_screen_test.dart` | CREATE | owner UX, permissions, RTL |
| `app/test/tenant_isolation/conflict_tenant_isolation_test.dart` | CREATE | M-C19/20/21/22 |
| existing suites (`sale_transaction_test.dart`, `sync_engine_test.dart`, `sync_queue_test.dart`, `hydration_test.dart`, `schema_v13/14_test.dart`, …) | NO CHANGE | must keep passing unmodified |

DELETE: none. Nothing qualifies as conclusively deletable; dead seams (SG-8, SG-5) are repurposed or left frozen.

## 28. Implementation Slices

Ordered, atomic; each lists gate/failure/rollback:

| ID | Objective | Key files (manifest refs) | Precondition | Schema | Tests | Pass gate | Failure condition | Rollback boundary |
|---|---|---|---|---|---|---|---|---|
| M-I01 | Domain primitives & resolver semantics | sync_status, conflict_resolver, adapters, entity_sync_adapter | baseline green | none | conflict_resolution_semantics_test + existing sync suite | analyzer 0/0; suite green | any existing-test regression | revert resolver/enum files |
| M-I02 | Server concurrency + rich returns | migration 28 (RPC replaces), cloud_sales/inventory repos | M-I01 | Supabase additive | server-contract tests (local pg/emulator harness or RPC-mock contract fixtures) | contract tests green | RPC signature misuse | migration is CREATE-OR-REPLACE w/ old-signature compatibility → redeploy prior fn bodies |
| M-I03 | Idempotent inventory effects | migration 28, sync_queue_repository, database_helper key gen | M-I02 | both (token column) | idempotency_server_contract_test | M-C10..13 green | duplicate-effect test fails | stop-rollout flag: engines skip new keys, fall back legacy path |
| M-I04 | Offline oversell detection + policy seam | reconciliation_service, inventory_oversell_policy | M-I01 | none | reconciliation_test | canonical M-C03 outcome per DR-M06 default | policy leak outside seam | seam default flip = config-only |
| M-I05 | Reconciliation engine + convergence apply | sync_engine, hydration, incremental, worker | M-I04 | none | conflict_apply_convergence_test | no silent-divergence cases remain | divergence detector fires | disable reconcile pass via worker flag |
| M-I06 | Count ordering | count adapter, screen, migration 28 observed_at, db_helper | M-I02 | observed_at col | inventory_count_ordering_test | M-C06..08 deterministic | ordering ambiguity test fails | observed_at nullable; legacy now()-fallback retained |
| M-I07 | Conflict persistence/audit | conflict_audit_repository, db_helper v15 | M-I01 | SQLite v15 | schema_v15_migration_test, audit tests | audit survives cleanupSynced | data loss on cleanup test fails | v15 additive-only → old build ignores |
| M-I08 | Owner review/resolution | conflict_review_screen, sync_conflict_dialog, rbac mapping, migration 28 resolution cols | M-I07 | sync_log cols | conflict_review_screen_test + permission denial tests | owner-only enforce UI+server | unauthorized resolution possible | hide route (feature-off) |
| M-I09 | Recovery/restart | worker, engine, queue repo | M-I05,07 | none | crash_recovery_test | all windows A–G restartable | stuck-state reproduced | recovery sweep is idempotent no-op fallback |
| M-I10 | Full regression/invariant gate | all | all above | — | FULL flutter test + invariant checklist §31 | §34 exit criteria met | any INV violation | per-slice rollback above |

Dependencies strictly linear M-I01 → {I02, I04, I07} → {I03, I05, I06} → I08/I09 → I10 (parallel branches where stated).

## 29. Detailed Test Matrix

Categories A–R (mandate §30 letters) mapped to concrete planned tests:

- A Local transaction regression → `inventory_atomicity_regression_test.dart` (invoice/return/count atomicity + guards unchanged; includes duplicate-line M-C29).
- B Server concurrency → `idempotency_server_contract_test.dart` + RPC contract fixtures asserting conditional-update rejection (M-C01/02) and version-conflict JSONB shape.
- C Idempotency → same file: M-C10/11/12/13 matrix (same-key replay = IDEMPOTENT; different-key duplicate blocked at source; lost-response converges).
- D Offline/offline oversell → `reconciliation_test.dart` M-C03 (both events kept; policy-default outcome; adjustment artifact exists; equation holds).
- E Online/offline conflict → M-C04 in reconciliation + convergence tests.
- F Sale/return ordering → M-C05, M-C17 (FIFO/causal order), M-C30 (return for conflicted sale bundles — SR-2).
- G Inventory-count ordering → `inventory_count_ordering_test.dart` M-C06/07/08 + IC-4 scenario verbatim.
- H Queue restart/recovery → `crash_recovery_test.dart` windows A–G incl. kill-mid-apply simulation.
- I Conflict persistence → audit-survives-cleanupSynced test; conflict_data→record promotion test.
- J Manual resolution authorization → `conflict_review_screen_test.dart` (owner can, seller cannot, fail-closed route + server-side denial path).
- K Tenant isolation → `conflict_tenant_isolation_test.dart` M-C19 (shop A conflict cannot alter shop B; hydration tenant guard retained).
- L Permission denial → M-C20 revoked-while-pending → FAILED + no partial apply.
- M License/membership changes → M-C21/22 → cycle break preserved; reconciliation resumable.
- N Cloud-to-local convergence → `conflict_apply_convergence_test.dart` (post-fix: LWW loser adopts server state; serverAuthoritative hydrates serverData; versions updated).
- O No sync echo loop → hydration/pull writes produce zero queue entries (assert getPendingEntries unchanged) — regression for INV-M10.
- P Windows/Android shared behavior → shared-code tests parametrized over platform-fake device identities M-C25/26/27 (logic identical by construction; widget smoke on both idioms).
- Q Migration tests → `schema_v15_migration_test.dart` (upgrade from v14 fixture db + fresh-create parity + CONFLICT→REVIEW_REQUIRED backfill).
- R Historical financial invariants → COGS immutability assertions (SG-9/INV-M14) inside reconciliation + convergence suites.

Concurrency realism requirement: overlap-producing harnesses (Completer-gated fakes / barrier-synchronized futures / serialized interleaving drivers) are REQUIRED for B/D/E/N — two sequential awaits do NOT qualify; each such test documents its barrier mechanism.

## 30. Failure Injection / Concurrency Tests

Explicit injection points: throw-after-server-commit-before-response (fake transport), process-kill simulation between transaction steps (sqflite in-memory + step hooks), duplicated delivery replays, clock skew (device clock ±hours for observed_at/LWW), stale server_version caches, queue corruption (missing payload). Each scenario in the M-C01..C30 matrix (plan §17 of the mandate) is assigned to a named test file in §29; the full 30-scenario grid (initial stock, operations, network state, expected server/local results, financial record, stock, queue, conflict/audit, notification, authorization) is carried into the implementation session as the acceptance checklist embedded in these files — the grid's governing outcomes are frozen by §13–§21 rules above.

## 31. Data & Financial Invariants

Adopted mandate list INV-M01..M15 verbatim, extended with code-derived additions:

- INV-M16: Component columns (opening/sold/returned/adjustment) change ONLY through event application or explicit count/adjustment events — never via metadata row merges (ES-1).
- INV-M17: Every queue transition is transactional with its cause (business write, conflict record, or resolution apply).
- INV-M18: `cleanupSynced` never removes unresolved lifecycle states or audit rows.
- INV-M19: Deterministic idempotency keys are stable across process restarts (persisted at creation).
- INV-M20: Server responses after M carry enough state (version/current stock) that clients never guess convergence.

## 32. Rollback / Recovery Strategy

- Per-slice rollback boundaries in §28; feature flags: worker-level reconciliation toggle, review-screen route gate, oversell-policy seam constant — each can disable the corresponding behavior without schema rollback.
- SQLite v15: additive-only → prior app version opens v15 db without failure (ignored columns/table); documented downgrade = restore-from-backup (house convention) since no destructive change exists to reverse.
- Supabase migration 28: all changes additive/optional-arg; rollback = CREATE OR REPLACE prior function bodies (retained in migration history) + ignore new columns.
- Data recovery: conflict audit retains both worlds' payloads enabling manual reapplication; backups precede every migration execution (implementation session duty).

## 33. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Resolver behavior change breaks existing tests' expectations | M-I01 runs full existing sync suite first; expectation updates confined to NEW tests (existing suites must pass unmodified — manifest NO CHANGE lock) |
| Idempotency key derivation collision | occurrence_token = uuid-based event identity; uniqueness tests; server UNIQUE constraint backstop |
| OD6 decided differently post-implementation | policy seam isolation (§17) + seam-flip tests |
| Hydration stomping pending ops (SG-1) regression in existing hydration tests | pending-guard designed against `hydration_test.dart` expectations; if conflict arises → treat as pre-existing-behavior bug, document, extend new tests only |
| Performance of per-event server round-trips | batching deferred; correctness first; queue already processes sequentially |
| Clock skew abuse of observed_at | server clamps future observed_at; skew recorded in audit; ordering uses (observed_at, arrival) pair |
| Scope creep toward N/O/P | §12 non-goals + manifest NO CHANGE locks |

## 34. Implementation Exit Criteria

1. `flutter analyze` 0 errors 0 warnings.
2. `flutter test` green except the documented 7 pre-existing failures (exact classification carried from this baseline).
3. All M-C01..C30 scenarios demonstrably covered with named passing tests.
4. INV-M01..M20 checklist asserted by tests.
5. Migration tests prove v14→v15 upgrade + fresh parity; Supabase migration applied to a TEST project only.
6. No silent-divergence path remains: proof test shows every conflict ends in RESOLVED or REVIEW_REQUIRED (never dropped).
7. Owner review workflow usable RTL on Windows+Android, fail-closed.
8. Existing suites unmodified and passing.
9. Clean repository, one implementation commit series per slice, local commits only.

## 35. Remote-Lock Handoff

After implementation session completes and THIS planning commit is remote-locked by `PHASE_M_PLANNING_REMOTE_LOCK` (tag `phase-m-planning-baseline-locked` authorized THERE, not here), the implementation session proceeds per §28 slices. This session creates NO tags and performs NO pushes.

## 36. Final Decision Register

| ID | Decision | Status |
|---|---|---|
| DR-M01 | Stock authority = server components; clients = projection + events | FROZEN |
| DR-M02 | Events immutable; snapshots may LWW after true-timestamp fix (ES-1 stock-component exclusion) | FROZEN |
| DR-M03 | Concurrency mechanism = existing conditional-update pattern + DB idempotency; no FOR UPDATE/advisory/reservations | FROZEN |
| DR-M04 | Idempotency: DB-layer keyed RPCs + deterministic persisted client keys | FROZEN |
| DR-M05 | OD4 grace defaults remain TEMPORARY_SAFE_DEFAULT (unchanged by M) | OPEN-GATE preserved |
| DR-M06 | OD6 negative-stock: ship Option-C mechanics + owner alert behind `InventoryOversellPolicy` seam; OD6 remains OPEN | OPEN-GATE preserved (default = recommendation, not approval) |
| DR-M07 | OD7 seller-offline: remains OPEN; M changes nothing about role policy; seam untouched | OPEN-GATE preserved |
| DR-M08 | Count = observed-at absolute snapshot applied as adjustment event; (observed_at, arrival) ordering; latest-observed wins | FROZEN |
| DR-M09 | Sync RUNTIME activation scheduling stays OUTSIDE M scope (machinery built+proved; enablement per OD-L1 follow-up) | FROZEN |
| DR-M10 | Resolution permission = owner-only, enforced UI + server (`require_shop_permission` re-check); exact permission label finalized in M-I08 against existing RBAC table without inventing new roles | FROZEN (mechanism) |
| DR-M11 | Schema: ADDITIVE_MIGRATION_REQUIRED (SQLite v15 + supabase migration 28) | FROZEN |
| DR-M12 | Conflict lifecycle: PENDING/SYNCED/FAILED + CONFLICT→REVIEW_REQUIRED→RESOLUTION_PENDING→RESOLVED | FROZEN |
| DR-M13 | Audit: local `conflict_audit` table + sync_log additive columns; survives cleanup | FROZEN |

---

END OF PHASE M PLANNING ARTIFACT — planning only; no implementation performed in this session.
