# PHASE P GATE 2 — OD7 SYNC DRAIN — F1–F5 IMPLEMENTATION PLANNING REPORT

## 0. Session Identity

| Field | Value |
|-------|-------|
| SESSION | `PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_IMPLEMENTATION_PLANNING` |
| TYPE | PLANNING ONLY — no application code, no SQL migration authored/applied, no Migration 40 deployment, no Production mutation, no OD7 activation, no sync drain, no build, no release |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| MANDATORY ENTRY HEAD | `34e515f8400b49fcea152fa9969806316eb085ca` |
| AUTHORIZED REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| FORBIDDEN REMOTE | `origin` — NOT contacted (verified) |
| DRAIN STATE | GATED / OFF — `AppConfig.syncDrainEnabled` default remains `false` (untouched) |
| RESULT | `PASS_PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_IMPLEMENTATION_PLANNING_REMOTE_LOCKED` |

This session is **planning-only**. It does not implement F1–F5, does not author
or apply Migration 40 or any migration, does not touch Production, does not
flip the drain, and does not begin any successor work. The single new deliverable
is this report (and the formal recording of the predecessor corrective-remediation
report, per Objective A below).

---

## 1. Entry Forensics (VERIFIED)

Executed at session start with exact commands. Status:

| Check | Result |
|-------|--------|
| Repository root | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| Git dir (linked worktree) | `C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze` |
| Current branch | `codex/i-tech-next-roadmap-freeze` |
| Local HEAD | `34e515f8400b49fcea152fa9969806316eb085ca` |
| Tracking branch | `github/codex/i-tech-next-roadmap-freeze` = `34e515f8400b49fcea152fa9969806316eb085ca` |
| Merge-base | `34e515f8400b49fcea152fa9969806316eb085ca` |
| Ahead / Behind | 0 / 0 |
| Tracked worktree | clean (`git diff` empty) |
| Index | clean (`git diff --cached` empty) |
| MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG / rebase-merge / rebase-apply | absent (verified via `git rev-parse --git-path`) |
| Classification | **CASE_A_FRESH** |

Pre-existing untracked artifacts inventoried, preserved, **not staged in bulk**
and **not modified or deleted** (verified via `git status --porcelain=v1`):

- `Continue` (0-byte, not owner authorization)
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md`
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md`
- `GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md`
- `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`
- `PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_REPORT.md`
- `PHASE_P_GATE_2_EXISTING_OWNER_CLOUD_LINK_UI_IMPLEMENTATION_REPORT.md`
- `PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REPORT.md` (Objective A — formally recorded this session)
- `PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_BLOCKED_PREFLIGHT_REPORT.md`
- `PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_PLAN.md`
- `PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION_REPORT.md`
- `PHASE_P_GATE_2_PRODUCTION_SIGNIN_LINKER_PREFLIGHT_REPORT.md`
- `PHASE_P_GATE_2_UPDATED_ANDROID_BUILD_INSTALL_AND_REENTRY_PREFLIGHT_REPORT.md`
- `PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`
- `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`
- `delivery/I-TECH-Delivery-v1.0.0.zip`
- `supabase/.branches/`, `supabase/.temp/` (sacred/untracked tooling state)

Entry classification: **CASE_A_FRESH** (local == tracking == merge-base, ahead 0,
behind 0, tracked clean, index clean, no active Git operation).

---

## 2. Owner Decision Evidence (OD7 — F5 Server-Side Idempotency)

The Owner approved the architectural direction for F5 in the governing session
message (`OWNER DECISION — OD7 F5 SERVER-SIDE IDEMPOTENCY`). Verbatim decision
points recorded here as authoritative (not reinterpreted):

1. `create_cloud_customer`, `create_cloud_expense`, `create_cloud_account` must
   become **server-side idempotent before OD7 sync drain activation**.
2. Affected cloud-create RPC contracts gain an explicit `p_idempotency_key`.
3. Reuse the existing canonical server idempotency architecture:
   `phase_m_idempotency_lookup` / `phase_m_idempotency_record`, with
   **shop-scoped idempotency identity**.
4. The same logical occurrence replayed multiple times must return/reuse the
   original cloud result and **MUST NOT create duplicate rows**.
5. Idempotency must remain **tenant/shop scoped**.
6. Client retry must preserve the same occurrence token / idempotency key.
7. **No silent duplicate acceptance is permitted.**

This decision does **not** authorize implementation. It authorizes **planning**
for `F1`/`F2`/`F3`/`F5` and requires `F4` to remain capture-only.

Administrative gates encoded in the same decision:

- Mandatory entry HEAD `34e515f8400b49fcea152fa9969806316eb085ca` (satisfied — §1).
- Objectives A–K (satisfied by this report).
- Absolute prohibitions (no code, no migration, no Production mutation, no OD7
  activation, no drain, no build/release/ship, no origin contact, no force push)
  — complied with (this is a planning-only session).
- DRAIN_STATE remains GATED/OFF; `AppConfig.syncDrainEnabled` default stays `false`
  (verified untouched at `app/lib/config/app_config.dart:39-42`).

Governing predecessor evidence preserved and recorded (Objective A):
`PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REPORT.md` — the
DISPOSITION/OWNER-DECISION report of the predecessor session
(`OWNER_DECISION_REQUIRED_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REMOTE_LOCKED`).
That report is committed formally this session (see §18/§A of this report).

---

## 3. F1 Implementation Plan — Invoice `sale_items` Carrier

### 3.1 Problem (VERIFIED)

- `InvoiceSyncAdapter.localToCloudPayload` (`app/lib/sync/adapters/invoice_sync_adapter.dart:25-34`)
  emits only `invoice_number/date/customer_name/payment_method/total_amount/total_items`.
- The transport invoice route requires a non-empty `payload['sale_items']` List of
  `{barcode, quantity, sale_price}` and otherwise throws
  `CloudDataException(invalidInput)` (`sync_cloud_operations_transport.dart:140-158`).
- `DatabaseHelper.insertInvoiceWithItems` (`database_helper.dart:1767-1855`) enqueues the
  invoice header as an `invoice` CREATE (`:1792-1795`) **before** the per-line loop, then
  enqueues each sale line as an independent `sale` CREATE (`:1826-1829`).
- Server `create_cloud_invoice_with_items_v2` (`20260820000028...sql:691-700`, item loop
  `:754-765`) rejects empty `sale_items` (`jsonb_array_length = 0` rejected) and creates
  the lines under `cloud_sales.invoice_id`.
- Net effect: offline-written invoices converge as FAILED invoice entries while their
  constituent lines converge as standalone sales — a duplicate-structure divergence.
- `sales.sync_status` is write-only in `app/lib` (no readers; VERIFIED by grep), so
  suppressing per-line enqueues does not break UI or counters.

### 3.2 Approved design (owner-selected, corrective-remediation §F)

1. Capture `sale_items` (`barcode`, `quantity`, `sale_price` per line) into the invoice
   queue payload at enqueue time, deterministically, from the persisted invoice lines.
2. Stop enqueuing invoice-line `sales` entries individually (they are server-created as
   part of the invoice effect set under ONE invoice-level idempotency key).
3. Preserve atomicity, restart safety, replay determinism, and idempotency.
4. No incomplete invoice may silently sync.

### 3.3 Exact implementation steps (for the authorized implementation session)

**S1 — Enqueue-time payload augmentation (single chokepoint).**
In `_enqueueAfterWrite` (`database_helper.dart:308-398`), after building the base payload
(`:350-355`) and only when `adapter.entityType == SyncEntityType.invoice`, query the
invoice's lines through the **caller's transaction executor** and set
`payload['sale_items']`:

```
rows = executor.query('sales', where: 'invoiceId = ?', whereArgs: [rowId])
payload['sale_items'] = rows.map((r) => {
  'barcode': r['barcode'],
  'quantity': r['quantity'],
  'sale_price': r['salePrice'],
})
```

Determinism: the payload is materialized once inside the same transaction that wrote the
lines; the stored JSON is replayed verbatim by the drain
(`sync_engine.dart:170-179` passes `entry.payload` verbatim). No drain-time augmentation.

**S2 — Suppress per-line sale enqueues for invoice lines.**
In `_enqueueAfterWrite`, when `adapter.entityType == SyncEntityType.sale` and
`row['invoiceId'] != null`, return before enqueueing. Standalone sales flows
(`insertSale`, `insertSaleAndDecrementStock`, `updateSale`, `deleteSale`) carry no
`invoiceId` and remain enqueued unchanged. `insertReturn` unaffected.

**S3 — Ordering invariant in `insertInvoiceWithItems`.**
Move the single invoice enqueue from `:1792-1795` (before the line loop) to **after** the
line loop completes (`:1851`, immediately before `return invoiceId`). Rationale:
- Atomicity: header, lines, stock decrements, and the enqueue commit together; any
  exception (`ArgumentError`, missing product, insufficient stock, optimistic-lock miss)
  rolls back the transaction and no queue row is created → "no incomplete invoice".
- Payload completeness: at enqueue time all `sales` rows for the invoice exist, so S1's
  `sale_items` query returns the full line set.
- Replay determinism: the queue payload is a frozen snapshot of the invoice + lines.

**S4 — Pre-existing old-shape queue entries.**
Add an idempotent, OFF-drain maintenance helper
`_backfillInvoiceSaleItemsForExistingQueueEntries()` executed once during an app-upgrade
path (never during drain): for `sync_queue` rows where `entity_type='invoice'`,
`status IN ('PENDING','FAILED')`, and payload lacks `sale_items`, re-query local
`sales WHERE invoiceId = invoices.id` and UPDATE the payload **in place**, preserving
`idempotency_key`, `occurrence_token`, `shop_id`, and `entity_id`. This makes already-
queued (pre-F1) invoice entries drainable after the F3 retry path exists. Bounded,
single-shop, low volume; run without a live drain.

**S5 — Convergence cascade (invoice).**
In `SyncEngine._convergeSuccess` (`sync_engine.dart:589-684`), after the invoice row is
marked SYNCED, mark its linked local `sales` rows SYNCED in the same transaction
(`txn.update('sales', {'sync_status': 'SYNCED'}, where: 'invoiceId = ?', whereArgs:
[<invoice local id>], executor: txn)`). The queue `entityId` for the invoice row IS the
local `invoices.id`; the adapter supplies `getLocalId`. This keeps per-line status
truthful and idempotent (replay of an already-converged invoice is a no-op convergence).

**S6 — Deliberate non-changes.**
- `InvoiceSyncAdapter` remains unchanged (its `cloudToLocalRow` continues to mirror the
  six summary keys; the server returns `invoice_number`, which is converged).
- The transport invoice route is already correct given `sale_items` present — no change
  required for F1.
- No SQLite schema change; the dead `sale_items` SQLite table is untouched
  (documented dead schema in `app/docs/...REVALIDATION.md`).

### 3.4 F1 verification contract

- Route/transport tests already prove `create_cloud_invoice_with_items_v2` fires
  **only** when `sale_items` is supplied (`sync_cloud_operations_transport_test.dart:165-196`)
  and fails closed without it (`:198-215`). F1 adds the missing producer.
- New tests: enqueue-after-write invoice tests asserting (a) one `invoice` CREATE entry,
  (b) `payload['sale_items']` equals the in-memory lines (barcode/quantity/sale_price),
  (c) NO per-line `sale` CREATE entries for invoice lines, (d) rollback on failure leaves
  zero queue rows, (e) backfill helper upgrades pre-existing entries preserving keys.
- End-to-end: a queue→engine→transport invoice flow converges as an invoice (one
  invoice-level key), lines converge via the invoice effect set.

---

## 4. F2 Implementation Plan — Transport/Server Conflict Mapping

### 4.1 Problem (VERIFIED)

- The A1 transport NEVER emits `CloudUpsertResult(conflict: true)`; no production path
  sets it (grep + constructor audit; transport test asserts `conflict` is false — `:499`).
- `p_expected_version` is never forwarded (`p_expected_version` appears zero times in
  `app/`), so the mig-26 optimistic-concurrency envelopes
  (`update_cloud_product`/`update_cloud_expense`/`update_cloud_customer`, RETURNS JSONB,
  e.g. `:100-108`, `:182-186`, `:254-261`) never fire from the drain.
- A server `{status:'CONFLICT',...}` envelope in `_adoptUpsertResult` falls into the
  `raw is Map` branch → classified as non-success → `markFailed`, never the engine's
  durable CONFLICT resolver (`sync_engine.dart:218-242` → `resolveVersionConflict` →
  `_handleConflict` → `markConflict`/REVIEW_REQUIRED).
- `update_cloud_account` has NO versioned overload (mig-38 `:163-211`, BOOLEAN return,
  unconditional UPDATE, bumps `server_version`).

### 4.2 Approved F2 target state

- Genuine version conflict → `CloudUpsertResult.conflict == true` → durable `CONFLICT`
  queue state + REVIEW_REQUIRED machinery.
- `FAILED` remains exclusively for non-conflict failures.
- No false conflict classification (only explicit server `CONFLICT` envelopes map to
  conflict; transient/validation/server failures remain FAILED).

### 4.3 Exact implementation steps

**T1 — `_adoptUpsertResult` conflict classification.**
In `sync_cloud_operations_transport.dart:379-450`, in the `raw is Map` branch, BEFORE the
`IDEMPOTENT`/`SYNCED` handling, add:

```
final status = map['status'];
if (status == 'CONFLICT') {
  return CloudUpsertResult(
    success: false,
    conflict: true,
    serverData: (map['server_data'] as Map?)?.cast<String, dynamic>(),
    localVersion: (payload['server_version'] as num?)?.toInt() ?? 0,
    currentServerVersion: (map['server_version'] as num?)?.toInt() ?? 0,
  );
}
```

Rule ("no false conflict"): a `conflict: true` result is produced **only** from the
server's explicit `{status: 'CONFLICT', expected_version, server_version, server_data}`
resolveable envelope. HTTP-level uniqueness violations (e.g., barcode-already-exists)
and all other non-success results continue through the existing FAILED/`CloudDataException`
paths. This is the exclusive mapping gate.

**T2 — Forward `p_expected_version`.**
For `SyncEntityType.product`/`customer`/`expense` UPDATE routes (create/update split at
`_dispatchUpsert`), add `'p_expected_version': payload['server_version']` when the route
selects the versioned server overload. The queue payload already carries the persisted
`server_version` (`database_helper.dart:353`). The mig-26 overloads accept
`p_expected_version INTEGER DEFAULT NULL`, so supplying the current local epoch arms the
optimistic-concurrency branch.

For `SyncEntityType.account`, forward `p_expected_version` **only after Migration 40 adds
the versioned `update_cloud_account` JSONB overload** (see §7.7); until then accounts stay
blind-update and produce no false conflicts.

**T3 — Engine nuance (no engine change required for F2).**
The engine's `result.conflict` branch already exists (`sync_engine.dart:218-242`) and the
resolver/`_handleConflict` path is already regression-tested with injected
`CloudUpsertResult(conflict: true)` fixtures. No engine logic change is required for F2 to
activate; only the transport producer changes.

**T4 — Update-account versioned overload (Recommended, part of Migration 40).**
Add an additive JSONB overload `update_cloud_account(...)` with a trailing
`p_expected_version INTEGER DEFAULT NULL` (matching the mig-26 family semantics:
`CONFLICT` envelope on mismatch, `SYNCED`+`server_version` on success), preserving the
existing BOOLEAN overload verbatim for legacy callers. This is a forward-compat parity
additive; it changes no existing client behavior. Recommended default; treated as a
planning-resolved design detail (implementation session must follow unless the Owner
overrides at implementation authorization).

**T5 — Conflict-resolution determinism.**
The engine `_shouldRetryLater`, `markFailed`, `markConflict` semantics are preserved:
`markConflict` produces the durable `CONFLICT` state with `conflict_data`
(`sync_queue_repository.dart:345-356`); FAILED remains for non-conflict failures only.

### 4.4 F2 verification contract

- Transport unit tests: (a) server `CONFLICT` envelope → `conflict:true` with correct
  versions; (b) `p_expected_version` forwarded on product/customer/expense/account updates;
  (c) non-conflict failures (serverError/validation/network) never set `conflict:true`;
  (d) update-account routing selects the versioned overload when present.
- Engine regression remains green (existing `conflict:true` fixtures already prove durable
  CONFLICT + REVIEW_REQUIRED).
- A version-conflict scenario in `idempotency_server_contract_test`-style fixture proves
  FAILED entries are NOT produced for genuine version conflicts.

---

## 5. F3 Implementation Plan — Bounded Manual FAILED → PENDING Recovery

### 5.1 Problem (VERIFIED)

- `SyncQueueRepository.retryEntry` (`sync_queue_repository.dart:393-403`) re-arms a single
  entry to PENDING with `retry_count=0`, **preserving** `entity_type/entity_id/operation/
  payload/idempotency_key/shop_id/occurrence_token` (it only touches `status`/`retry_count`).
- `getFailedEntries` (`:242-258`) lists `status='FAILED'`.
- Neither has a production caller; `processQueue` only pulls `PENDING` (`:224-240`), so a
  FAILED row is terminal in production today.
- `SyncRuntime.retryNow()` (`sync_runtime.dart:232-238`) re-evaluates gates via
  `ensureStarted` and re-drives a cycle; it does NOT re-arm FAILED entries.

### 5.2 Approved F3 design (owner-selected, corrective-remediation §H)

Surface a MANUAL, operator-initiated, bounded FAILED→PENDING re-arm through the existing
retry affordance using `retryEntry`, gated exactly like `retryNow` (license/tenant/
connectivity), preserving original occurrence token + idempotency key + shop identity,
and re-arming **only entries whose entity/operation has a governed, retriable RPC**.

### 5.3 Exact implementation steps

**R1 — `SyncRuntime.retryFailed({int maxEntries = 50})` (new, `sync_runtime.dart`).**
1. `await ensureStarted(shopId: boundShopId)` — reuses the SAME fail-closed chain
   (bound shop → drain seam → license → transport), so licensing and tenant gates remain
   mandatory (same as `retryNow`).
2. If the worker is not running / gates failed → publish status and return (no mutation).
3. `final failed = await _queueRepository.getFailedEntries(shopId: boundShopId);`
4. Filter to a **retriable allowlist** derived from the governed transport allow-list:
   - Retriable (CREATES/UPDATES/DELETES that are idempotent-safe or keyed): sale,
     returnItem, invoice, inventoryCount, product, customer, expense, expenseCategory
     (CREATE only), shopSetting, stockAdjustment, account, openingBalanceEntry.
   - **Excluded (fail-closed by design; re-arm would deterministically re-fail):**
     invoice DELETE, inventoryCount DELETE, shopSetting DELETE, stockAdjustment DELETE,
     account DELETE, openingBalanceEntry DELETE, expenseCategory UPDATE.
   The filter is a fixed allowlist in the runtime (no free-form retry).
5. Take the first `maxEntries` of the filtered set, call `retryEntry(id)` for each
   (bounded batch; retry ladder `0s/5s/30s/2m/10m`, cap 5 — `_shouldRetryLater`,
   `sync_engine.dart:307-324` — keeps any post-re-arm cycle bounded).
6. `await syncNow(); await publishStatus();`

**R2 — UI affordance (settings screen).**
In `_buildSyncStatusSection()` (`settings_screen.dart:643`), add a manual
"إعادة محاولة الأخطاء الفاشلة" (`retry failed (N)`) button — visible only when
`failedSyncCount > 0`, calling `SyncRuntime.instance.retryFailed()`. Disabled while a
cycle is in flight via the existing status guard. The existing PENDING retry button
(`:737-749`) is unchanged; `SyncStatusIndicator.onRetry → retryNow()` is unchanged.

**R3 — Safety properties (verified design guarantees).**
- Original occurrence token preserved: `retryEntry` does not touch `occurrence_token`
  (F5 idempotency identity unchanged).
- Idempotency key preserved: unchanged → server dedup holds on replay.
- Shop identity preserved: `shop_id` column untouched; engine tenant guard still applies.
- Licensing/tenant gates: `ensureStarted` re-checks before re-arm and before drain.
- Bounded: batch cap + retry ladder; no unbounded/automatic re-arm; no silent acceptance.

### 5.4 F3 verification contract

- Unit (runtime): retryFailed respects gates; bounded batch; allowlist filter; preserves
  key/token/shop; re-arms PENDING then drains.
- Widget: button visibility (failed>0), disabled during cycle, invokes retryFailed.
- Regression: FAILED entries re-enter processing ONLY through retryFailed; nothing
  automatic; a network-off gate blocks re-arm.
- Pre-existing invoice entries missing `sale_items` (pre-F1) converge after F1 backfill
  (§3.3 S4) + retryFailed.

---

## 6. F4 — Deferred / Documented Non-Goal

**No implementation. No automatic conflict adjudication. No automatic conflict winner. No
destructive overwrite.**

Rationale (corrective-remediation §I / preflight §C.4/F4):
- `writer_snapshot` (v17) is captured at enqueue (`database_helper.dart:366-378`) and
  wired (`main.dart:215`) but has no reader in `app/lib/sync` — capture-only by design.
- Adjudication (denying a now-revoked writer at drain time) is a documented Group-A
  non-goal and a successor boundary. WS-5 adjudication UI is out of scope.
- F4 is therefore recorded, not scheduled. This report preserves it as a boundary so no
  successor session drifts into it.

---

## 7. F5 — Migration 40 Exact Design (Server-Side Idempotency)

### 7.0 Numbering authority (VERIFIED)

Next migration number is **40** (`20260820000040_...sql`). Highest existing migration is
`20260820000039_phase_p_gate2_owner_shop_uniqueness.sql`; the `YYYYMMDD00000N` convention
is confirmed by the complete sorted migration inventory (§8). No file collision.
Proposed filename: `20260820000040_phase_p_gate2_od7_f5_cloud_create_idempotency.sql`.

### 7.1 Target surface (VERIFIED current state)

| RPC | Signature (today) | Return | Idempotency today |
|-----|-------------------|--------|-------------------|
| `create_cloud_customer` | `(p_shop_id UUID, p_name TEXT, p_phone TEXT, p_address TEXT, p_notes TEXT, p_is_active BOOLEAN, p_is_system BOOLEAN)` with the 4 optional trailing params DEFAULT NULL | UUID | NONE (plain INSERT) |
| `create_cloud_expense` | `(p_shop_id UUID, p_date TIMESTAMPTZ, p_description TEXT, p_amount NUMERIC(12,2), p_category_id UUID DEFAULT NULL)` | UUID | NONE (plain INSERT) |
| `create_cloud_account` | `(p_shop_id UUID, p_name TEXT, p_account_type TEXT)` | UUID | NONE (plain INSERT) |

Canonical store: `sync_log.idempotency_key TEXT UNIQUE NOT NULL` (mig-26),
`phase_m_idempotency_lookup(p_idempotency_key TEXT)` RETURNS JSONB (INVOKER, mig-28
`:51-84`), `phase_m_idempotency_record(p_shop_id UUID, p_entity_type TEXT, p_entity_id
UUID, p_operation TEXT, p_idempotency_key TEXT, p_status TEXT, p_details JSONB)` RETURNS
VOID with `ON CONFLICT (idempotency_key) DO NOTHING` (INVOKER, mig-28 `:88-114`).

### 7.2 Constraints that drive the design

- `phase_m_idempotency_lookup` is **NOT shop-scoped** (queries `sync_log` by key only,
  global UNIQUE). Reusing it verbatim would permit a cross-shop replay to return another
  shop's recorded UUID — an idempotency/tenant leak. The Owner mandates shop-scoped
  identity (`OD7` #4). Therefore a shop-scoped lookup helper is required (§7.4).
- `phase_m_idempotency_record` IS shop-scoped correctly (writes `shop_id`), reuses
  `ON CONFLICT (idempotency_key) DO NOTHING` as a backstop. Reused verbatim.
- `sync_log.idempotency_key` is globally UNIQUE. Client keys are
  `entityType:cloud_uuid:operation:occurrenceToken`, where `cloud_uuid` is a client-minted
  UUIDv4 and `occurrence_token` is a UUIDv4 → effective uniqueness across shops. The
  global UNIQUE remains a hostile-input backstop.
- Existing grants on the 7/5/3-param signatures must remain valid (PostgREST dispatches by
  parameter count/name). Adding a trailing `p_idempotency_key TEXT DEFAULT NULL` creates
  NEW overloads; each new overload needs its own `GRANT EXECUTE ... TO authenticated`.
- The functions stay `SECURITY DEFINER SET search_path = public` (matching the entire
  `create_cloud_*`/`update_cloud_*` family and the four `_v2` guards).
- Return type **stays `UUID`** for backward compatibility. PostgREST returns the created/
  replayed UUID string; the transport `raw is String` branch
  (`_adoptUpsertResult:427-430`) already handles it and converges.

### 7.3 New internal helper (additive, INVISIBLE to API)

```
CREATE OR REPLACE FUNCTION phase_m_idempotency_lookup_shop(
  p_shop_id UUID,
  p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_other UUID;      -- a shop that already owns the key
  v_log   RECORD;
BEGIN
  IF p_idempotency_key IS NULL OR p_idempotency_key = '' THEN
    RETURN NULL;
  END IF;

  -- fail-closed cross-shop collision signal (never leaks the other shop's data)
  SELECT shop_id INTO v_other
    FROM sync_log
   WHERE idempotency_key = p_idempotency_key AND shop_id <> p_shop_id
   LIMIT 1;
  IF v_other IS NOT NULL THEN
    RETURN jsonb_build_object('status', 'CROSS_SHOP_COLLISION');
  END IF;

  SELECT * INTO v_log
    FROM sync_log
   WHERE idempotency_key = p_idempotency_key AND shop_id = p_shop_id
   LIMIT 1;
  IF v_log IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'status', 'IDEMPOTENT',
    'original_status', v_log.status,
    'original_result', COALESCE(v_log.conflict_details, '{}'::jsonb),
    'server_version', COALESCE((v_log.conflict_details->>'server_version')::INTEGER, 0),
    'shop_id', v_log.shop_id
  );
END;
$$;
```

Purpose: `CREATE OR REPLACE`-compatible, SECURITY INVOKER (like the two existing phase_m
helpers), no direct grants (only invoked from SECURITY DEFINER wrappers). The existing
one-arg `phase_m_idempotency_lookup` is left untouched (7 live call sites among the _v2/
adjustment functions).

### 7.4 Lookup behavior (exact)

For each of the three create functions, with a non-null `p_idempotency_key`:

1. `PERFORM require_shop_permission(p_shop_id, '<perm>')` FIRST (before any dedup
   short-circuit — deliberately different from the legacy _v2 order, which looks up first;
   this is the security-first ordering required for a tenant-keyed dedup):
   - customer → `inventory.edit`; expense → `expenses.create`; account →
     `inventory.edit` + owner-only `accounting.edit` role gate (as today).
2. `PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text || '|' ||
   p_idempotency_key, 0));` — xact-scoped advisory lock keyed on (shop, key). Released
   automatically at commit/rollback.
3. `v_prior := phase_m_idempotency_lookup_shop(p_shop_id, p_idempotency_key);`
   - `NULL` → proceed to mutation (key unknown for this shop).
   - `status='CROSS_SHOP_COLLISION'` → `RAISE EXCEPTION 'idempotency_key_cross_shop_collision'`
     (fail closed; no data leak; no cross-shop acceptance).
   - `status='IDEMPOTENT'` → replay path: extract original `id`, verify payload fingerprint
     (§7.5), then `RETURN (v_prior->'original_result'->>'id')::UUID;` — no mutation.

### 7.5 Mismatched payload under the same key — fail closed (exact)

A canonical fingerprint is stored at record time in `conflict_details` under `'fp'`, computed
over the exact forwarding parameters the function receives:

- customer: `md5(jsonb_build_object('name', trim(p_name), 'phone', p_phone, 'address',
  p_address, 'notes', p_notes, 'is_active', p_is_active, 'is_system', p_is_system)::text)`
- expense: `md5(jsonb_build_object('date', p_date, 'description', trim(p_description),
  'amount', p_amount, 'category_id', p_category_id)::text)`
- account: `md5(jsonb_build_object('name', trim(p_name), 'account_type', p_account_type)::text)`

On replay: recompute the fingerprint and compare to the stored `'fp'`. Mismatch →
`RAISE EXCEPTION 'idempotency_payload_mismatch'` (fail closed; **no silent acceptance**,
OD7 #7). A stored row without a fingerprint (never produced by M40) is treated as a
mismatch (fail closed) — conservative default.

### 7.6 Mutation + record + post-commit self-check (exact)

1. Existing validation sequence (name required / description required / amount ≥ 0 /
   category exists / account_type valid / account name required) unchanged, performed
   before the INSERT.
2. `INSERT ... RETURNING id INTO v_id;` (same DML as today).
3. `PERFORM phase_m_idempotency_record(p_shop_id, '<entity>', v_id, 'CREATE',
   p_idempotency_key, 'SYNCED', jsonb_build_object('id', v_id, 'server_version', 1,
   'fp', v_fp));` — `<entity>` ∈ {customer, expense, account}.
4. Self-check (defense in depth; "no silent duplicate acceptance"): if
   `p_idempotency_key IS NOT NULL` then verify the record persisted for THIS
   shop/entity/id; if `NOT EXISTS(SELECT 1 FROM sync_log WHERE idempotency_key =
   p_idempotency_key AND shop_id = p_shop_id AND entity_id = v_id)`, `RAISE EXCEPTION
   'idempotency_record_conflict'` → whole transaction rolls back the just-created row
   (guards the hostile global-UNIQUE-claimed-key corner).
5. `RETURN v_id;`

### 7.7 Versioned `update_cloud_account` overload (F2 parity, additive)

```
CREATE OR REPLACE FUNCTION update_cloud_account(
  p_shop_id UUID,
  p_account_id UUID,
  p_name TEXT DEFAULT NULL,
  p_account_type TEXT DEFAULT NULL,
  p_deleted BOOLEAN DEFAULT NULL,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
```
- Old 5-arg BOOLEAN overload preserved verbatim (legacy clients unaffected).
- Semantics mirror mig-26: optimistic branch returns
  `{status:'CONFLICT', server_version, expected_version, server_data}` on mismatch; else
  updates and returns `{status:'SYNCED', server_version}`.
- Owner-only `accounting.edit` gate preserved.
- This enables F2 T2/T4 for accounts (no false conflicts, genuine version conflicts reach
  the durable CONFLICT path).

### 7.8 Exact signatures — BEFORE → AFTER

| Function | BEFORE (args) | AFTER (args added, trailing) | Return |
|----------|---------------|------------------------------|--------|
| `create_cloud_customer` | 7 | + `p_idempotency_key TEXT DEFAULT NULL` (8) | UUID (unchanged) |
| `create_cloud_expense` | 5 | + `p_idempotency_key TEXT DEFAULT NULL` (6) | UUID (unchanged) |
| `create_cloud_account` | 3 | + `p_idempotency_key TEXT DEFAULT NULL` (4) | UUID (unchanged) |
| `update_cloud_account` | 5 (BOOLEAN overload) | new JSONB overload 6 args with `p_expected_version` | JSONB (new overload) |
| new helper | — | `phase_m_idempotency_lookup_shop(UUID, TEXT)` | JSONB |

**Nullability:** `p_idempotency_key` is `TEXT DEFAULT NULL`. `NULL`/empty → legacy
non-idempotent behavior (no lookup, no lock, no record, plain INSERT). Non-null → governed
idempotent path. This is the compatibility seam (§9).

### 7.9 Behavior matrix (OD7 requirements 7–10)

| Scenario | Behavior |
|----------|----------|
| Committed-but-response-lost request (#7) | Retry with same key → `IDEMPOTENT` replay → same `entity_id` returned; no duplicate row; no mutation. |
| Concurrent duplicate delivery, same key+shop (#8) | Txn A obtains advisory lock, inserts+records+commits; Txn B blocks on the lock, then reads committed state, `IDEMPOTENT` replay → one row total. |
| Concurrent duplicate delivery, key collision across shops | `CROSS_SHOP_COLLISION` fail-closed RAISE; no cross-shop acceptance, no leakage. |
| Mismatched payload under same key (#9) | Fingerprint mismatch → `idempotency_payload_mismatch` fail-closed RAISE; no silent acceptance. |
| Replay returns original cloud result | Same UUID string as the original create (return-type preserved). |
| Error behavior (#10) | All new RAISEs abort the single RPC transaction (PostgREST → 4xx); any failure before record leaves NO partial row; fail-closed semantics throughout. |

### 7.10 Transaction boundaries (exact)

- Each RPC runs in one transaction (PostgREST function-call boundary): lookup → lock →
  validation → INSERT → record → self-check commit atomically.
- `pg_advisory_xact_lock` is transaction-scoped; released automatically.
- No client-initiated multi-statement transaction; no explicit `COMMIT` in functions.
- The advisory lock is the only concurrency primitive added; no `SERIALIZABLE` required
  under READ COMMITTED because the (shop,key)-scoped lock serializes same-key deliveries.

### 7.11 RLS / SECURITY DEFINER / search_path

- All new/redefined functions: `SECURITY DEFINER SET search_path = public` (consistent
  with the existing family). No `SET ROLE`, no ownership change.
- `require_shop_permission` (mig-34 canonical, SECURITY DEFINER) remains the single
  authorization chokepoint and runs BEFORE any idempotency short-circuit.
- `cloud_customers/cloud_expenses/cloud_accounts` RLS: SELECT policies exist
  (`shop_isolation_*_approval`, `cloud_accounts_select`); INSERTs happen under the table
  owner (definer), matching today's behavior. Verify no `FORCE ROW LEVEL SECURITY` is
  applied on these tables (none exists today). No RLS policy change required.
- `sync_log`: INSERT only via `phase_m_idempotency_record` under definer context, and
  SELECT via the new helper under definer context. No new RLS policy; no grant needed for
  internal invocation. Read-only SELECT policy remains `shop_isolation_sync_log_approval`.

### 7.12 Grants and permissions (exact)

New grants required (additive — all existing grants preserved):
- `GRANT EXECUTE ON FUNCTION create_cloud_customer(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN, TEXT) TO authenticated;`
- `GRANT EXECUTE ON FUNCTION create_cloud_expense(UUID, TIMESTAMPTZ, TEXT, NUMERIC(12,2), UUID, TEXT) TO authenticated;`
- `GRANT EXECUTE ON FUNCTION create_cloud_account(UUID, TEXT, TEXT, TEXT) TO authenticated;`
- `GRANT EXECUTE ON FUNCTION update_cloud_account(UUID, UUID, TEXT, TEXT, BOOLEAN, INTEGER) TO authenticated;` (new JSONB overload)
- No `REVOKE` on legacy signatures; no grants on `phase_m_idempotency_lookup_shop`
  (definer-internal only); advisory lock needs no grant.

### 7.13 Migration 40 composition (exact, additive-only)

1. `phase_m_idempotency_lookup_shop` (new helper).
2. `create_cloud_customer` 8-param overload (idempotent) + redefine 7-param overload to
   delegate to the 8-param with `p_idempotency_key := NULL` (single-body maintenance,
   byte-identical legacy behavior) OR keep 7-param body untouched (no delegation) — the
   implementation session MUST pick delegation for single-body maintenance and MUST verify
   legacy behavior unchanged by test.
3. `create_cloud_expense` 6-param overload (same pattern).
4. `create_cloud_account` 4-param overload (same pattern).
5. `update_cloud_account` JSONB versioned overload (§7.7).
6. Grants (§7.12).
7. No ALTER TABLE, no data migration, no index change, no RLS change, no REVOKE.

---

## 8. RPC / Function Inventory (VERIFIED, pre-M40 baseline, and F5 impact)

| Function | Location | Security | Status / F5 impact |
|----------|----------|----------|--------------------|
| `phase_m_idempotency_lookup(TEXT)` | mig28:51-84 | INVOKER | Reused verbatim by legacy `_v2`; NOT usable alone for shop-scoped dedup |
| `phase_m_idempotency_record(...)` | mig28:88-114 | INVOKER | Reused verbatim by all idempotent paths (writes shop_id, global-UNIQUE backstop) |
| `phase_m_idempotency_lookup_shop(UUID,TEXT)` | NEW (M40) | INVOKER | New shop-scoped lookup helper |
| `create_cloud_sale_with_stock_v2` | mig28/30 | DEFINER | SAFE_SERVER_IDEMPOTENT (legacy pattern; lookup-first) — unchanged |
| `create_cloud_return_with_stock_v2` | mig28 | DEFINER | idempotent — unchanged |
| `create_cloud_invoice_with_items_v2` | mig28 | DEFINER | idempotent — unchanged; F1 supplies its `sale_items` |
| `delete_cloud_sale_with_revert_v2`, `delete_cloud_return_with_revert_v2`, `save_cloud_inventory_count_v2` | mig28 | DEFINER | idempotent — unchanged |
| `create_cloud_stock_adjustment` | mig30 | DEFINER | idempotent (shop-scoped UNIQUE(shop_id, key)) — unchanged |
| `create_cloud_opening_balance` | mig38 | DEFINER | SELECT-first + global-UNIQUE — unchanged |
| `create_cloud_product` | mig25:314 | DEFINER | SAFE_BY_UNIQUE_CONSTRAINT — unchanged |
| `create_cloud_expense_category` | mig25:607 | DEFINER | SAFE_BY_UNIQUE_CONSTRAINT — unchanged |
| `create_cloud_customer` | mig25:501 | DEFINER | **UNSAFE → M40 new idempotent overload** |
| `create_cloud_expense` | mig25:685 | DEFINER | **UNSAFE → M40 new idempotent overload** |
| `create_cloud_account` | mig38:124 | DEFINER | **UNSAFE → M40 new idempotent overload** |
| `update_cloud_product` / `update_cloud_expense` / `update_cloud_customer` (JSONB versioned) | mig26 | DEFINER | Exist; F2 now forwards `p_expected_version` |
| `update_cloud_account` | mig38:163 | DEFINER | BOOLEAN only; **M40 adds JSONB versioned overload** |
| `update_cloud_shop_setting` / assorted getters/legacy RPCs | mig25 | DEFINER | Unchanged |
| `require_shop_permission(UUID,TEXT)` | mig34:987 | DEFINER | Unchanged; authorization chokepoint for M40 paths |

Client-side RPC wrapper surface changed by F2/F5 (implementation session allowlist):
`sync_cloud_operations_transport.dart` — adds `p_idempotency_key` to the three creates,
forwards `p_expected_version` on versioned updates, maps `CONFLICT` envelopes.

---

## 9. Client / Server Compatibility (H — Backward Compatibility Determination)

**Determination: Migration 40 can be safely backward-compatible.** No STOP required, with
a documented coordinated rollout ordering.

Evidence for compatibility:
1. New create overloads are trailing-parameter additives (`DEFAULT NULL`); the legacy
   signatures and their grants remain fielded. Old app binaries (7/5/3-param calls) hit the
   legacy overloads with byte-identical behavior (non-idempotent, exactly as today).
2. Return type of the three creates is unchanged (`UUID`); the transport `raw is String`
   branch still converges created/replayed rows.
3. `update_cloud_account` BOOLEAN overload preserved; new JSONB overload is additive.
4. No table DDL, no RLS change, no REVOKE, no search_path change.
5. `sync_log` fills append-only; no data migration, no backfill of existing rows.

**Rollout ordering / coordinated sequence (mandatory):**
1. Deploy Migration 40 to Production FIRST (old clients keep working unchanged).
2. Then release the F1–F5 client (new transport) that speaks the new overloads.
3. A NEW client against a PRE-M40 server is unsupported (PostgREST would reject the
   unknown `p_idempotency_key` param) — therefore **server-first** is the only safe order.
4. OD7 drain activation happens only after F1–F5 implementation AND an owner-approved
   release build (`ACTIVATED_VARIANT_1` path); never before.
5. Old client binaries running concurrently after M40 are safe (legacy overloads), but the
   OD7 drain path is new-client-only.

---

## 10. RLS / Security Analysis

- **Server-side authorization first:** all M40 paths call `require_shop_permission` before
  any dedup short-circuit (differs from legacy `_v2` lookup-first ordering); cross-shop/
  unlicensed/unpermitted calls fail closed before any stored data is touched.
- **Cross-shop idempotency safety:** the shop-scoped helper returns only the caller's shop
  row; the `CROSS_SHOP_COLLISION` signal raises without exposing the other shop's UUID or
  payload — no cross-shop data disclosure, no cross-shop acceptance.
- **RLS integrity preserved:** definer functions insert under the function owner as today;
  SELECT policies for authenticated (`_approval` family) unchanged; `sync_log` SELECT
  policy unchanged; no grant widening to `anon`/public.
- **UI hiding ≠ authorization:** unchanged — server gates remain authoritative; client
  changes (F2/F3) do not weaken `require_shop_permission`/license checks.
- **Secrets:** none introduced; no `.env`/key material touched. Anon Supabase client only
  (no service_role in client scope) — unchanged.
- **Device-gate interplay:** mig-34 `s4_device_gate_enabled()` is DORMANT; when activated
  it applies inside `require_shop_permission`, so M40 paths inherit it automatically.
- **Negative tests required** (§15): cross-shop attempt, RLS denial, cross-shop key
  collision, unlicensed write denial.

---

## 11. Licensing Analysis

- Client gate: `SyncRuntime.ensureStarted` runs `_licenseCheck()`
  (`cloudLicensingService.enforceActive()`) before any cycle/retry; `retryFailed` (F3)
  reuses this gate. Licensing and tenant gates remain mandatory for F3 retries (OD7 F3).
- Server gate: `require_shop_permission` enforces write-license validity
  (`license_required` / `license_expired` RAISEs) — M40 paths inherit it because they call
  it first.
- OD7 drain activation remains impossible without an active license; invalid-license
  scenario → drain does not start; replay safety is unaffected by license state (dedup only
  fires for authenticated, permitted calls).
- No license/tier/entitlement schema or logic change in scope.

---

## 12. Transaction / Idempotency Semantics

| Property | Semantics |
|----------|-----------|
| Atomicity | Per-RPC single transaction; lookup→lock→validate→insert→record→self-check commit together; any RAISE rolls back everything (no partial row, no orphan sync_log record). |
| Exactly-once (same occurrence) | (shop,key) advisory lock serializes; first success records; replay returns original UUID; no second row. |
| Restart safety | advisory xact locks vanish on abort; retry of an aborted call re-runs cleanly. |
| Reply determinism | queue payload is the frozen snapshot; same key → same server UUID; fingerprint guard prevents payload drift. |
| Shop scope | helper + advisory lock keyed on (shop,key); cross-shop collision fail-closed. |
| Concurrent delivery | lock + `ON CONFLICT DO NOTHING` + post-commit self-check = belt, braces, and verification. |
| Queue-state semantics | unchanged after F1–F5: PENDING→SYNCED/FAILED/CONFLICT; FAILED only for non-conflict failures (F2); manual bounded F3 re-arm only via operator action. |

---

## 13. Rollback Strategy

- Migration 40 is **additive**: new functions/overloads/grants only; no data or DDL
  mutation. There is nothing destructive to un-apply.
- If a Migration-40 defect surfaces post-deploy: ship a corrective additive migration
  (M41) redefining the new overloads (planned fix), never a destructive drop; do not
  delete `sync_log` rows (audit/append-only).
- Old client rollback: an OFF (NORMAL_GATED_OFF) build restores the dormant, zero-call
  posture at the app level (normal release rollback; per P-OD7/Group-A governance).
- If the new client must be rolled back but M40 stays: old clients still work via legacy
  overloads; queue entries created by new clients retain their keys (no loss); the drain
  remains GATED/OFF until re-authorized.
- No force push, no history rewrite, no migration renumbering.

---

## 14. Deployment Ordering

1. **Local**: author `20260820000040_...sql` + pgTAP suite; apply to local Supabase; run
   the full server test suite + fresh-DB and upgrade-path checks.
2. **Optional staging** (ref `ldkttyljtolnwlipjimb`, not linked today): apply + verify if
   this session is separately authorized to use it.
3. **Production migration deploy** — SEPARATE, explicitly owner-authorized deploy session
   (read-only preflight probes first: migration list green at 39, routines inventory,
   counts). Apply M40 via the governed Supabase deploy path only after full local+test
   PASS. Verify post-deploy: `information_schema.routines` shows the new overloads, grants
   present, legacy signatures intact.
4. **Client implementation** (F1–F3, F5 transport): committed and test-verified (this is
   the successor implementation session).
5. **Release build**: owner-approved release build with `ACTIVATED_VARIANT_1` governance
   (never `SYNC_DRAIN_ENABLED=true` by a commit flipping the default) — the drain seam
   stays `false` at source.
6. **Post-migration verification**: read-only production probes (routines/grant/ledger) +
   a controlled, owner-authorized idempotency replay exercise in a disposable test shop
   (destructive cleanup owned by that session), or documented-equivalent evidence.
7. **OD7 activation**: a separate, owner-authorized activation session per P-OD7 after
   F1–F5 complete and the 16-criterion gate re-passes post-remediation.

---

## 15. Test Matrix (K)

Legend: C = Flutter unit/widget/integration (`app/test/...`, run
`flutter test test/sync --concurrency=1`), S = server pgTAP (`supabase/tests/...`,
`supabase test db --local ...`), M = DB migration/test harness.

| # | Test | Type | Surface | Must prove |
|---|------|------|---------|------------|
| 1 | Invoice one-line sync | C+M | `enqueue_after_write_test` / new `invoice_sale_items_carrier_test` | one `invoice` CREATE; `sale_items` length 1 (barcode/quantity/sale_price); converges via `_v2`; linked sales marked SYNCED |
| 2 | Invoice multi-line sync | C+M | same | `sale_items` length N; server creates N lines under `cloud_sales.invoice_id`; one invoice-level key |
| 3 | Offline enqueue | C | DB helper | offline `insertInvoiceWithItems` → durable PENDING queue with full payload |
| 4 | Restart before drain | C | `crash_recovery_test` extension | queue survives restart; drains after start; no partial/duplicate |
| 5 | Network loss after server commit | S+C | `idempotency_server_contract_test`/pgTAP | server committed; response lost; retry same key → IDEMPOTENT; row count == 1 |
| 6 | Replay same occurrence | S+C | idempotency tests | same key → same UUID; no second row |
| 7 | Concurrent duplicate replay | S | new pgTAP (two sessions/`dblink`/serial) | (shop,key) advisory lock ⇒ exactly one customer/expense/account row for two concurrent same-key calls |
| 8 | Customer duplicate replay | S+C | new pgTAP + transport | replay returns original UUID; fingerprint OK; unconditioned (2 calls, 1 row) |
| 9 | Expense duplicate replay | S+C | new pgTAP + transport | expense: 2 calls, 1 row, same UUID |
| 10 | Account duplicate replay | S+C | new pgTAP + transport | account (owner-only): 2 calls, 1 row, same UUID; employee denied |
| 11 | Version conflict | C+S | transport + engine + server | stale `p_expected_version` → server `CONFLICT` envelope → `conflict:true` → durable CONFLICT + REVIEW_REQUIRED (never FAILED) |
| 12 | Non-conflict server failure | C | transport + engine | 5xx/validation/network → FAILED, `conflict` stays false (no false conflict) |
| 13 | Manual FAILED retry | C | `sync_runtime_test`/widget | `retryFailed` gates; bounded batch; allowlist filter (non-retriable ops skipped); preserves key/token/shop; drains after re-arm |
| 14 | Invalid license | C+S | runtime + pgTAP | drain gate blocks start; server RAISE on unlicensed write; no drain of unlicensed tenant |
| 15 | Cross-shop attempt | C+S | engine tenant guard + pgTAP | engine skips mismatch; server same-key-other-shop → fail closed; 2 shops, 2 independent rows; no leakage |
| 16 | RLS denial | S | pgTAP negative | non-member SELECT on cloud_* / sync_log denied; definer inserts still mediated by `require_shop_permission` |
| 17 | Malformed payload | S+C | pgTAP + queue | missing barcode/quantity/name / negative amount → server RAISE; invoice fails closed; no partial invoice; queue FAILED (not silent) |
| 18 | Restart/recovery | C | `crash_recovery_test`/M-I05 | recovery sweep re-drives queue after restart; no loss |
| 19 | Queue observability | C | `a6_observability_test` extension | pending/failed/conflict/synced counters truthful after F1/F2/F3 flows |
| 20 | Idempotency-key mismatch behavior | S+C | new pgTAP + transport | payload mismatch fail-closed RAISE; cross-shop collision fail-closed; `idempotency_record_conflict` self-check rollback |

Additional mandatory pre-production gates:
- `flutter analyze` (app) with exact raw result preserved (§23 AGENTS.md).
- Full `flutter test test/sync --concurrency=1` baseline (260 passing at predecessor; full
  suite re-run required in the implementation session).
- Server: full pgTAP tree (all `supabase/tests/*.test.sql` green on fresh DB) and the
  `d1_cost_history_rls`, `d2_opening_balances`, `s*` suites.
- Migration 40 fresh-install and upgrade-path (M39→M40) apply tests.

---

## 16. Changed-File Forecast (I)

### Flutter (client)
- `app/lib/sync/sync_cloud_operations_transport.dart` — F2 conflict classification (T1),
  `p_expected_version` forwarding (T2/T4), F5 `p_idempotency_key` on the three creates.
- `app/lib/database/database_helper.dart` — F1 S1 (sale_items at enqueue), S2 (per-line
  suppression), S3 (enqueue ordering in `insertInvoiceWithItems`), S4 (backfill helper).
- `app/lib/sync/sync_engine.dart` — F1 S5 (invoice convergence cascade: linked sales SYNCED).
- `app/lib/sync/sync_runtime.dart` — F3 R1 (`retryFailed`, bounded, allowlist-filtered).
- `app/lib/screens/settings_screen.dart` — F3 R2 (retry-failed button).
- (Optional, only if needed) `app/lib/sync/sync_queue_repository.dart` — expose filtered
  failed listing helper; expected minimal/no change.

### SQL (server)
- `supabase/migrations/20260820000040_phase_p_gate2_od7_f5_cloud_create_idempotency.sql`
  (new) — §7 composition.

### Tests
- `app/test/sync/sync_cloud_operations_transport_test.dart` — F2/F5 transport contracts.
- `app/test/sync/enqueue_after_write_test.dart` — F1 invoice enqueue assertions.
- `app/test/sync/invoice_sale_items_carrier_test.dart` (new) — F1 end-to-end.
- `app/test/sync/f3_failed_retry_test.dart` (new) — F3 runtime/allowlist/UI behavior.
- `app/test/sync/sync_engine_test.dart` / `app/test/sync/sync_runtime_test.dart` — F2/F3
  regressions (conflict routing, retryFailed).
- `app/test/sync/a6_observability_test.dart` — extended counters (test 19).
- `app/test/sync/crash_recovery_test.dart` / `idempotency_*` — expansion for scenarios
  4/5/6/18.
- `supabase/tests/od7_f5_cloud_create_idempotency.test.sql` (new) — pgTAP M40 suite.

### Documentation / governance (this planning chain)
- This planning report (committed this session).
- `PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REPORT.md` (formally recorded
  this session, Objective A).
- Successor implementation session governance/authorization artifacts (next session).

### Transport adapters / RPC wrappers / queue-retry-UI (consolidation)
- RPC wrappers: `sync_cloud_operations_transport.dart` (above).
- Transport adapters: **no adapter changes required** (`InvoiceSyncAdapter`,
  `CustomerSyncAdapter`, `ExpenseSyncAdapter`, `AccountSyncAdapter` unchanged for F1/F5).
- Queue/retry/UI files: `sync_runtime.dart`, `settings_screen.dart` (F3).

---

## 17. Implementation Session Allowlist (successor — NOT this session)

The NEXT implementation session is authorized to touch **only** these paths:

- `app/lib/sync/sync_cloud_operations_transport.dart`
- `app/lib/database/database_helper.dart`
- `app/lib/sync/sync_engine.dart`
- `app/lib/sync/sync_runtime.dart`
- `app/lib/screens/settings_screen.dart`
- (optional) `app/lib/sync/sync_queue_repository.dart`
- `supabase/migrations/20260820000040_phase_p_gate2_od7_f5_cloud_create_idempotency.sql` (new)
- `supabase/tests/od7_f5_cloud_create_idempotency.test.sql` (new)
- Test files listed in §16 (new/extended)
- Governance/report artifacts of the implementation session

Explicitly **excluded** (hard boundaries): `app_config.dart` (`syncDrainEnabled` default
must stay `false`), `pubspec.yaml`/dependencies, Android/Windows build config, signing,
`delivery/`, Production Supabase mutation, OD7 activation, Migration 41+, any file not on
this list. Any deviation requires a fresh owner authorization.

---

## 18. Production Safety Constraints

- Planning session: no production contact; remote touched only via `git ls-remote github`
  (read) and the final push (§20). `origin` never contacted.
- Future production access remains strictly read-only except the explicitly owner-authorized
  Migration 40 deploy session and the owner-authorized post-migration verification.
- No build/APK/AAB/Windows release/install/ship in any session covered by this plan.
- DRAIN must remain GATED/OFF until: F1–F5 implemented and tested, Migration 40 deployed
  and verified, 16-criterion gate re-passed, and a SEPARATE owner-approved release build +
  activation session.

---

## 19. Readiness Conclusion

- The F1–F5 corrective-remediation is fully planned at the implementation level with exact
  server signatures, lookups, records, lock semantics, fingerprint fail-closed behavior,
  grants, compatibility analysis, rollback, deployment ordering, changed files, sequencing,
  and an explicit test matrix.
- Migration 40 is demonstrably **backward-compatible** (additive overloads; legacy
  signatures/grants preserved) with a documented **server-first** rollout requiring no STOP.
- F4 remains a documented non-goal.
- No unresolved architecture decision remains at planning level. Design defaults that the
  implementation session must follow unless the Owner overrides at implementation
  authorization: (a) versioned `update_cloud_account` JSONB overload in M40; (b)
  fingerprint-fail-closed mismatch policy; (c) advisory-lock concurrency guard; (d)
  single-body delegation of legacy overloads; (e) F1 enqueue-time payload augmentation +
  end-of-transaction enqueue ordering; (f) fixed-retriable-allowlist for F3 retryFailed.

**READINESS: PLANNING COMPLETE.**

RESULT_TOKEN =
`PASS_PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_IMPLEMENTATION_PLANNING_REMOTE_LOCKED`

---

## 20. Next Authorized Session Recommendation

1. **Owner authorization message** for implementation of F1 (invoice `sale_items` carrier),
   F2 (conflict mapping + `p_expected_version`), F3 (bounded manual FAILED→PENDING retry),
   and F5 (Migration 40 server-side idempotency) per this plan's allowlist (§17).
2. Implement server-first: author + locally apply Migration 40 and the pgTAP suite;
   verify fresh + M39→M40 upgrade paths.
3. Implement client F5 transport keys, F2 conflict mapping, F1 invoice carrier + backfill,
   F3 retryFailed + UI.
4. Execute the full test matrix (§15) + `flutter analyze`; report raw results exactly.
5. **Separate** owner-authorized session to deploy Migration 40 to Production (read-only
   preflight + push + read-only post-verification).
6. Post-remediation OD7 preflight — re-run the 16-criterion gate (Group-A plan §7) including
   live Criterion 16 probe; then a **separate** owner-authorized activation session with an
   owner-approved `ACTIVATED_VARIANT_1` release build flips the drain.

---

## 21. STOP Statement

Planning is complete and locked locally after this session's commit/push/remote-lock
evidence (§22). No application code changed, no SQL migration authored/applied, no
Migration 40 deployed, no Production mutation, no OD7 activation, no drain, no
build/release/ship, no origin contact, no force push. The OD7 sync drain remains
GATED/OFF with `AppConfig.syncDrainEnabled` at default `false`. Implementation is a
separately authorized successor scope. STOP.