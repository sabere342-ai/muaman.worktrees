# PHASE P GATE 2 — OD7 SYNC DRAIN ACTIVATION PREFLIGHT & EXECUTION PLANNING REPORT

## Session Identity

| Field | Value |
|-------|-------|
| SESSION | `PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING` |
| TYPE | READ-ONLY FORENSICS + VERIFICATION + PLANNING (NO ACTIVATION, NO MUTATION) |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| ENTRY_HEAD | `34141681a5138a389535428940480e91f3d9c864` |
| EXIT_HEAD | `34141681a5138a389535428940480e91f3d9c864` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| FORBIDDEN_REMOTE | `origin` (`C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن`) — NOT CONTACTED |
| SUPABASE_PROD_REF | `ckruxrgppxxeqspxmyyd` / `i-tech-production` / West EU (Ireland) |
| SUPABASE_CLI | `2.117.0` (not updated) |
| PRODUCTION_MUTATION | NO |
| DRAIN_STATE | GATED/OFF (unchanged; `SYNC_DRAIN_ENABLED` not flipped) |
| RESULT | `BLOCKED_PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING_REMOTE_LOCKED` |

## Governing Authority

- `AGENTS.md` (§6 forensics, §8 entry classification, §10–§11 remote lock,
  §12 scope, §13 owner gates, §14 allowlist, §22 testing, §23 test reporting,
  §25 security, §26 production safety, §40 report integrity, §42 no
  autonomous successor work).
- `PHASE_P_OWNER_DECISIONS.md` §A/§E — P-OD7 CONDITIONALLY AUTHORIZED
  AFTER EVIDENCE: `syncDrainEnabled` remains FALSE until a mandatory evidence
  gate is proven.
- `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` §7 — 16-criterion evidence gate.
- `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_GOVERNANCE_REPORT.md` §E —
  activation preconditions, abort conditions, per-release activation unit.
- `docs/ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CONTRACT.md` —
  `ACTIVATED_VARIANT_1`, positive authorization surface, fail-closed tooling.
- Predecessor: `PASS_PHASE_P_GATE_2_MIGRATIONS_36_37_38_PRODUCTION_RECONCILIATION_EXECUTION_REMOTE_LOCKED`.

This session is **planning-only**. It does NOT activate the drain, does NOT
build, does NOT ship, does NOT mutate Production, and does NOT begin any
successor.

---

## A. Entry Forensics (VERIFIED)

| Check | Result |
|-------|--------|
| Repository root | `C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze` |
| Git dir | `C:\dev\muaman\.git\worktrees\i-tech-next-roadmap-freeze` (linked worktree) |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Local HEAD | `34141681a5138a389535428940480e91f3d9c864` |
| Tracking branch | `github/codex/i-tech-next-roadmap-freeze` = `3414168…` |
| Direct github HEAD (`git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`) | `34141681a5138a389535428940480e91f3d9c864` |
| Merge-base | `34141681a5138a389535428940480e91f3d9c864` |
| Ahead / Behind | 0 / 0 |
| Tracked worktree | clean |
| Index | clean |
| MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG / rebase-merge / rebase-apply | None |
| index.lock | Absent |
| Stash (pre-existing, preserved) | `stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration: 283ff9d` |
| Classification | **CASE_A_FRESH** |

Pre-existing untracked artifacts (inventoried, NOT staged, NOT modified,
NOT deleted): `Continue` (0 bytes — NOT owner authorization), multiple
`GROUP_A_PHASE_P_OD7_*` reports, `PHASE_P_GATE_2_*` reports,
`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`,
`delivery/I-TECH-Delivery-v1.0.0.zip`, `supabase/.branches/`, `supabase/.temp/`.

---

## B. Production Target Verification (READ-ONLY, VERIFIED this session)

All commands executed against the linked Production project
(`ckruxrgppxxeqspxmyyd`); every statement was **SELECT / migration-list only**.
No data mutation, no DDL, no DML, no RPC invocation.

| Command | Evidence |
|---------|----------|
| `supabase projects list` | Linked project = `ckruxrgppxxeqspxmyyd` `i-tech-production` (West EU); staging `ldkttyljtolnwlipjimb` NOT linked |
| `supabase migration list --linked` | Local == Remote for `20260820000000`…`20260820000039`; every row green (no drift, no pending) |
| `supabase db query … supabase_migrations.schema_migrations` | **28 rows** present in Production, exactly `00000…00006, 00010, 00020…00039` |
| `supabase db query … counts` | shops=3, shop_members=3, auth.users=8, cloud_products=4, cloud_migration_ledger=0 |
| `supabase db query … information_schema.routines` | Production exposes `create_cloud_sale_with_stock_v2`, `create_cloud_return_with_stock_v2`, `create_cloud_invoice_with_items_v2`, `save_cloud_inventory_count_v2`, `delete_cloud_sale_with_revert_v2`, `delete_cloud_return_with_revert_v2`, `create_cloud_stock_adjustment`, `resolve_cloud_stock_adjustment`, `create_cloud_opening_balance`, `create_cloud_account`, `require_shop_permission` |

Notes / classification:
- Production migration ledgers: schema migrations = 28 (M36/M37/M38/M39
  present, no M40+, no Migration 31). `cloud_migration_ledger` = 0 rows
  (legacy Phase-I import ledger unused in Production to date) — consistent
  with Product lifecycle so far; the "28 rows" ledger referenced by the
  predecessor report is the schema-migrations ledger, which matches.
- `create_cloud_cost_history` was NOT returned by the routines probe because
  migration 36/37 named it `insert_cloud_cost_history` / 
  `get_cloud_cost_history_by_*`; migration list confirms M36/M37 present in
  Production, so the D1 surface exists (identifier naming differs from the
  probe string). Recorded as NOT VERIFIED for the exact
  `create_cloud_cost_history` name; the functionally-equivalent
  `insert_cloud_cost_history` presence is inferred from M36/M37 in the
  schema-migrations ledger.
- Auth users=8 vs. shops=3/members=3: includes owner + employee auth
  identities across tenants plus any pre-signin-linker identity rows; owners
  table count was not probed this session (predecessor reported owners=3 —
  NOT re-proven this session, preserved as predecessor-reported).

## C. Sync Architecture Forensics (VERIFIED)

### C.1 Control surface (OD7 seam)

- `app/lib/config/app_config.dart:39-42`:
  `syncDrainEnabled = bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue: false)`.
- `app/lib/main.dart:257-278`: `SyncRuntime.instance.configure(...)` wires
  `SyncCloudOperationsTransport(rpc: ..., allowOversell: true).toOperations()`
  with `shopIdProvider` (ActiveShopContext), `licenseCheck`
  (`cloudLicensingService.enforceActive()`), `connectivityCheck`
  (`isCloudLinked && isOnline`), `drainEnabled: AppConfig.syncDrainEnabled`.
- `app/lib/sync/sync_runtime.dart:176-182`: when `!_drainEnabled`,
  `ensureStarted` logs "drain disabled (shipping posture)" and returns after
  publishing status — ZERO cloud calls. Confirmed: `_drainEnabled = false`
  at line 84 default; `drainEnabled` getter line 101.
- `app/lib/sync/sync_runtime.dart:257-278` (main) + `:147 ensureStarted`,
  `:189 licensed gate`, `:199 cloudOps null gate` form the fail-closed start
  chain: bound shop → drain seam → license → transport → build/start →
  `_runInitialSynchronization`.
- DRAIN_STATE = GATED/OFF end-to-end; no `--dart-define` change, no source
  default change, no approval artifact produced.

### C.2 Transport routing (A1, dormant-but-wired)

`sync_cloud_operations_transport.dart` routes every `SyncEntityType` through a
closed allow-list to governed RPCs, all scoped by persisted queue `shop_id`:
- sale → `create_cloud_sale_with_stock_v2` (`p_invoice_id: null` — the local
  sale adapter carries no invoice link; never fabricated)
- returnItem → `create_cloud_return_with_stock_v2`
- invoice → `create_cloud_invoice_with_items_v2` (REQUIRES non-empty
  `payload['sale_items']`, else throws `CloudDataException(invalidInput)`)
- inventoryCount → `save_cloud_inventory_count_v2`
- product/customer/expense → `create_cloud_*` (no cloud_uuid) or
  `update_cloud_*` (cloud_uuid present)
- expenseCategory → `create_cloud_expense_category`; UPDATE fails closed (no
  governed update RPC)
- shopSetting → `update_cloud_shop_setting` (upsert by shop+key)
- stockAdjustment → `create_cloud_stock_adjustment`
- account → `create_cloud_account` / `update_cloud_account`
- openingBalanceEntry → `create_cloud_opening_balance`
- DELETE: sale/returnItem → `*_v2` revert RPCs with idempotencyKey; product/
  customer/expense/expenseCategory → governed delete RPCs; invoice/
  inventoryCount/shopSetting/stockAdjustment/account/openingBalanceEntry →
  fail closed (no governed server delete; returns CloudDataException).

`_adoptUpsertResult` maps: stock results (`OVERSOLD`/`SYNCED`/`IDEMPOTENT`),
scalars (String = new UUID, bool = applied flag), Map (`IDEMPOTENT` →
`idempotent:true`, `SYNCED`/`success`), else fail closed. **`conflict: true`
is never emitted by the transport** (verified: only the field declaration
exists at `sync_engine.dart:1034`; no production code path sets
`CloudUpsertResult(conflict: true)`).

### C.3 Engine / worker

- `sync_worker.dart`: 30s `Timer.periodic`; `_isProcessing` guard; skip on
  session-invalid or offline; one-shot M-I05 recovery sweep at start
  (`recoverySweep`, non-fatal); `onCycleComplete` publishes truthful status.
- `sync_engine.dart processQueue`: `getPendingEntries(shopId:)` →
  `status='PENDING'` ORDER BY `created_at ASC` (**strict FIFO**; no
  topological/dependency ordering; no claim/lock). Per entry: tenant-mismatch
  guard (`entry.shopId != shopId` → logged skip), `_shouldRetryLater`
  (delay ladder 0s/5s/30s/2m/10m, retryCount ≤ 5), then DELETE/CREATE-UPDATE
  routing; `oversold` → `_handleOversold` (Option C), stockAdjustment →
  converge, `conflict` → resolver, `idempotent` → `_convergeSuccess`,
  `!success` → `markFailed`; `CloudDataException`: `permissionDenied` →
  markFailed; `networkError`/license → break cycle (retry preserved);
  otherwise markFailed. Summary `SyncResult(processed, synced, failed, conflicts)`.
- `markFailed` increments `retry_count`; at `> 5` it sets status `FAILED`,
  else keeps it `PENDING` (retry window). `retryEntry` exists
  (`sync_queue_repository.dart:393`) but has NO production caller
  (verified by grep: only definition + `getFailedEntries` definition, no UI/
  runtime call site) — a FAILED row re-enters processing only if it is
  PENDING again, and no production path re-arms FAILED → PENDING except
  manual repair. This is a **planning finding (F3)**, see §E.

### C.4 Enqueue seam (local write → queue)

- `database_helper.dart:_enqueueAfterWrite` (line 308) is the single chokepoint
  used by all 28 in-transaction call sites plus workbook-import sites. Enqueue
  commits in the SAME transaction/executor as the business write (atomic);
  suppressed inside `runWithoutSyncEnqueue`, when no adapter for the table, or
  when no shop resolves.
- Idempotency key: `_generateSyncKey` = `entityType:entityUuid:operation:occurrenceToken`
  (`database_helper.dart:289-294`); `occurrence_token` minted ONCE and
  persisted on the row (`:382`), so retry/replay reuse the SAME key.
- `cloud_uuid` minted (or read) before queue creation and persisted back to
  the row inside the transaction (`:340-348`).
- WS-5 `writer_snapshot` (v17) stamped at enqueue with entity_type, operation,
  `permission_required`, `permission_granted:true`, `entitlement_active:true`,
  shop_id, entity_uuid, `written_at`, optional writer identity
  (`:366-378`); wired via `DatabaseHelper.setWriterSnapshotProvider`
  (`main.dart:215`).
- Writer-snapshot ADJUDICATION (reading the snapshot at drain time to deny a
  now-revoked writer) is **not implemented** — snapshot is captured and
  persisted but nothing reads it during drain today (capture-only). WS-5
  adjudication UI is a documented Group-A non-goal. Verified.

### C.5 Invoice payload gap (planning finding F1)

- `_enqueueAfterWrite` builds the queue payload from
  `adapter.localToCloudPayload(row)` (line ~354). `InvoiceSyncAdapter.localToCloudPayload`
  returns `invoice_number/date/customer_name/payment_method/total_amount/total_items`
  — **it NEVER produces `sale_items`** (verified `invoice_sync_adapter.dart:25-34`).
- A client invoice write path (`DatabaseHelper.insertInvoiceWithItems`,
  line ~1784-1795) enqueues an `invoice` CREATE row; the sale lines are also
  enqueued individually as `sale` rows.
- When the drain routes the invoice entry to `create_cloud_invoice_with_items_v2`,
  the transport throws `CloudDataException(invalidInput)` because
  `payload['sale_items']` is missing/empty → the engine marks the invoice
  entry FAILED (eventually) while the individual sale lines succeed.
- Therefore, **offline-written invoices cannot converge as invoices through
  the drain today**; their constituent sales do converge, but the invoice
  header does not. `sync_cloud_operations_transport_test.dart:198-215`
  explicitly asserts the fail-closed behavior for an invoice without
  `sale_items` (test passes). The unit test at `:165-196` proves routing only
  when `sale_items` is supplied — which the local adapter never supplies.

### C.6 Conflict surface (planning finding F2)

- Engine conflict branch is reachable in tests via injected
  `CloudUpsertResult(conflict:true)` (`sync_engine.dart:218`), but the A1
  transport never sets `conflict:true` (verified above). Non-idempotency
  version conflicts (the mig-26 `update_cloud_*` JSONB overloads) would be
  surfaced by the transport as a Map without `IDEMPOTENT`/`SYNCED` status →
  treated as non-success → `markFailed`, not routed through the
  `_conflictResolver` REVIEW_REQUIRED machinery.
- Additionally the transport calls `update_cloud_product/customer/expense`
  WITHOUT `p_expected_version`, so the mig-26 optimistic-concurrency branch
  (`IF p_expected_version IS NOT NULL AND …`) never fires for these
  entity types; the mig-25 boolean/non-versioned BOOLEAN overloads coexist.
  OF-5 conflict records and `resolve_sync_conflict` remain reachable for the
  *server-side* resolution path, but the client drain path that feeds them is
  not exercised by the A1 transport for version conflicts. Review-required
  conflicts (REVIEW_REQUIRED) are produced by the engine for oversold/Option C
  and audit-lifecycle paths; OF-1 (sale preserved) is enforced server-side by
  `_v2` + `FOR UPDATE` + oversell.

## D. Server-Side Idempotency Surface (VERIFIED)

- `sync_log.idempotency_key TEXT UNIQUE NOT NULL` + index (mig 26); global
  (not shop-scoped) uniqueness.
- `phase_m_idempotency_lookup(p_key)` SECURITY INVOKER — SELECT-first, returns
  JSONB `{'status':'IDEMPOTENT', original_status, original_result,
  server_version, current_quantity}` for a previously recorded key; NULL
  otherwise.
- `phase_m_idempotency_record(...)` — `INSERT … ON CONFLICT (idempotency_key)
  DO NOTHING` (concurrent-duplicate backstop).
- All six `_v2` RPCs + `create_cloud_stock_adjustment` consume lookup→mutation→
  record in one transaction. `cloud_stock_adjustments` carries
  `UNIQUE (shop_id, idempotency_key)` (second guard); adjust insert uses
  `ON CONFLICT DO NOTHING`.
- `create_cloud_opening_balance` SELECT-first (scoped shop/account/kind) +
  `cloud_opening_balance_entries.idempotency_key UNIQUE` (global).
- `create_cloud_account`/`update_cloud_account`/`create_cloud_*` generic RPCs
  do NOT take idempotency keys (non-idempotent); determinism for those
  entities relies on client key + server `ON CONFLICT` at table level (absent)
  — accounted for in the retry model: generic CRUD retried under the same key
  does not reach an idempotent RPC; a duplicated generic create would create
  a duplicate cloud row (mitigation: cloud_uuid-driven UPSERT absent for
  generic `create_cloud_*`). Recorded as planning consideration; the
  transport's per-entity generic creates are create-once-and-retry with the
  same key only for the *queue* entry, not server dedupe.
- `create_cloud_sale_with_stock_v2` sets `p_allow_oversell` default FALSE;
  production signature verified via `p_allow_oversell` parameter naming only
  (see predecessor Live Criterion 16 = PASS preserved).
- Concurrent same-key race: lookup precedes `SELECT … FOR UPDATE`; two truly
  concurrent same-key transactions could both pass lookup, both mutate a sale/
  return row, and only the log row dedupes; the sale/return row itself is not
  key-unique. This is an INFERRED theoretical race that does not arise in the
  single-runtime-per-shop serial drain model (one worker, `_isProcessing`),
  but is recorded for the execution plan (do not run multiple runtimes
  draining the same shop concurrently).

## E. Planning Findings

| ID | Finding | Evidence | Severity | Action |
|----|---------|----------|----------|--------|
| F1 | Invoice entries cannot converge as invoices through the A1 drain (no `sale_items` producer); they fail closed and land FAILED | `invoice_sync_adapter.dart:25-34`; `sync_cloud_operations_transport.dart:140-158`; `database_helper.dart:1784-1795`; `sync_cloud_operations_transport_test.dart:198-215` | HIGH (invoice cloud convergence) | Owner-gated successor slice: adapter/transport must carry the per-item breakdown or invoice drain must be consciously scoped-out and documented |
| F2 | `CloudUpsertResult.conflict` is never emitted by the A1 transport; version conflicts on generic entities degrade to FAILED instead of REVIEW_REQUIRED conflict resolution; `p_expected_version` not forwarded | `sync_cloud_operations_transport.dart` `_adoptUpsertResult` (379-450); `sync_engine.dart:1032-1058`; mig-26 overloads | MEDIUM (conflict handling completeness) | Owner-gated successor slice or documented equivalence; OF-1/Option-C/oversold conflict path remains server-enforced |
| F3 | No production path re-arms FAILED → PENDING; `retryEntry`/`getFailedEntries` have no caller | `sync_queue_repository.dart:242,393`; grep of `app/lib` | MEDIUM (durable retry/self-heal) | Owner-gated successor slice: surfaced-retry UI or automatic re-arm with guard; M-I05 only re-drives RESOLUTION_PENDING audits, not FAILED queue rows |
| F4 | WS-5 writer_snapshot is capture-only; adjudication at drain time is not implemented | `database_helper.dart:366-378`; no reader grep hit in `app/lib/sync` | MEDIUM (revocation adjudication) | Documented Group-A non-goal; keep as successor boundary |
| F5 | Generic `create_cloud_product/customer/expense/category` have no server idempotency key / UPSERT; retry of a partially-committed generic create could duplicate a cloud row | mig-25 RPC signatures; transport `_dispatchUpsert` | MEDIUM (exactly-once for generic creates) | Keep queue-side key; add owner decision on whether server-side uniqueness is required before first production activation |
| F6 | Local migration inventory == remote ledger exactly (28 files, M00–M06 + M10 + M20–M39); no local-file/ledger mismatch, no M40+ | `supabase/migrations/` glob = 28 files (VERIFIED this session); `supabase migration list --linked` green; schema_migrations = 28 rows | INFO | No action; consistent with predecessor reconciliation |

Grading model: F1–F5 are findings that REDUCE readiness-confidence for a
specific-entity unconditional activation. Per the evidence-first contract,
they block a `PASS` readiness claim and produce a `BLOCKED` result for the
ordering of the first activation: the drain is NOT declared "ready to activate
as-is for ALL entity types and ALL operator flows." The engine, transport,
server idempotency core, RLS, and 260-test sync suite are verified; the gaps
above are entity/feature-specific and must be resolved or explicitly
owner-scoped before an owner-approved release build activates the drain.

## F. Readiness Verdict (16-criterion frame, plan §7)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| 1 Context (auth user + shop) | PASS (verified) | `main.dart:266` shopIdProvider; `sync_runtime.dart` bound-shop resolve |
| 2 Tenant isolation | PASS (verified) | persisted `shop_id` scoping + engine guard (`sync_engine.dart:123-130`); RLS `*_approval` policies; `sync_tenant_test.dart` |
| 3 Permissions | PASS (verified) | `require_shop_permission` in-editor on every governed RPC; sync only queues permitted writes |
| 4 Entitlement | PASS (verified) | `licenseCheck` (enforceActive) gate before worker start; offline/license-fail safe |
| 5 Enqueue→drain | PASS for most entities; **F1 for invoice** | `enqueue_after_write_test`; invoice gap recorded |
| 6 Retry/idempotency | PASS (verified) for `_v2`/adjustment/opening-balance; **F5 for generic creates** | `sync_log` UNIQUE + lookup/record + `_v2`; transport test 29 |
| 7 Stable cloud identity | PASS (verified) | `cloud_uuid` minted/persisted at enqueue; adapter identity tests |
| 8 Offline recovery | PASS (verified) | M-I05 sweep; restart/replay (`crash_recovery_test`) |
| 9 Conflict | PASS for OF-1/Option-C server path; **F2 for client version-conflict routing** | `_v2` FOR UPDATE/oversold; engine resolver tests; transport gap recorded |
| 10 Truthful counters | PASS (verified) | `SessionState` publish; `a6_observability_test` 16 |
| 11 Reconnect | PASS (verified) | retry ladder + `_shouldRetryLater`; offline-defer tests |
| 12 No cross-shop movement | PASS (verified) | queue-shop guard + `sync_tenant_test.dart` |
| 13 No duplicates | PASS for idempotent surface; **F5 residual for generic creates** | sync_log UNIQUE; convergence tests |
| 14 No secret leakage | PASS (verified) | transport uses anon client + `Supabase.instance.client.rpc`; no service_role in client scope; config.toml/.env posture reported clean by predecessors |
| 15 Runtime sanity | PASS (verified) | worker lifecycle & `_isProcessing`; `sync_runtime_test` 15 |
| 16 Migration 28/30/36/37/38/39 production presence | PASS (VERIFIED this session) | `supabase migration list --linked` + schema_migrations 28 rows + routines probe |

**BLOCKING FINDINGS**: F1 (HIGH), F2/F3/F4/F5 (MEDIUM). Predecessor static
gates (15/15 YES) and test gates (241→260 sync) are preserved; the 
readiness verdict changes only because this preflight traced the A1 transport
end-to-end and exposed entity-specific convergence gaps not covered by the
predecessor's dormant-posture claims.

## G. Execution Plan (for a SEPARATE owner-authorized session)

Precondition: none of G.1–G.5 may begin until the Owner explicitly authorizes
the successor session AND, per P-OD7, an owner-approved release build exists.

### G.1 Activation sequencing (when authorized)
1. Owner approves the specific successor session + activation build intent.
2. Source default stays FALSE (`app_config.dart` untouched). A committed
   owner-approved approval artifact (SHA-256 bound) is produced per
   `docs/OWNER_APPROVAL_ARTIFACT_SCHEMA.md`.
3. Release build created with `--dart-define=SYNC_DRAIN_ENABLED=true` through
   the `ACTIVATED_VARIANT_1` tooling path
   (`tools/release/resolve_release_variant.ps1 -ApprovalFile …`,
   `verify_activated_release.ps1`, `guard_tests_activated_variant.ps1`), in a
   separate `delivery/activation-candidate/<unique-build-id>/` output — NEVER
   overwriting `delivery/I-TECH-Delivery-v1.0.0.zip`.
4. Ship/install only after G.1.3 guard matrix (G1–G10) and the complete
   positive authorization surface (variant id, approval artifact, opt-in,
   env allowlist, active owner authorization, fingerprint) all pass.
5. Activate per shop by releasing to the bound, licensed, online tenant
   runtime; observe the drain, do not run two runtimes against the same shop.

### G.2 Pre-drain checks (immediately before activation)
- Re-run §B read-only production checks (migration list green against the
  shipped commit; ledger 28; RPC surface).
- Verify no production queue/bucket/edge drift (read-only API/health checks per
  contract §13 that the previous sessions explicitly deferred).
- Verify the specific release build's drain-flag is the ONLY delta vs. the
  frozen canonical v1.0.0 OFF identity (provenance verifier recomputes
  fingerprint; stale/mismatched commit refused).

### G.3 During-drain observability
- `SessionState` counters (pending/failed/conflict/lastSyncedAt) must move
  truthfully per shop.
- `sync_log` rows appear for every drained operation; idempotent replays
  return `IDEMPOTENT` without duplicate side effects.
- Oversold sales surface durable `cloud_stock_adjustments` + local
  conflict_audit/stock_adjustments evidence.
- Watch for FAILED accumulation (F3) and invoice FAILED rows (F1) — abort
  criteria below take precedence over "just keep draining."

### G.4 Abort / stop criteria
- Any unexpected cross-shop entry observed (must never happen; guard already
  skips+logs).
- Any unauthorized entity drained to an RPC that does not match its governed
  allow-list entry.
- Any secret leakage or unanticipated PUBLIC/grant exposure discovered.
- F1/F2/F5 surfacing as high-volume FAILED in a real shop within the first
  production window → stop build distribution, revert to OFF build (normal
  release rollback) while queue/cloud state remains inspectable.
- License/entitlement gate failure or unlicensed tenant beginning to drain.
- Migration drift (any local/remote ledger mismatch) discovered mid-run.

### G.5 Rollback model
- Activation-level rollback: release an OFF (NORMAL_GATED_OFF) build — the
  runtime returns to dormant status-only, ZERO cloud calls. This is a normal
  release rollback; no data migration.
- Data-level: already-drained server effects are NOT reverted by turning the
  drain off. Per-operation correction is via the existing `*_v2` revert RPCs
  and soft-delete. Turning the drain off does not "unsync" data (governance
  report §E is explicit).

## H. Scope Boundaries / Successor Boundary

This session did NOT and must not be treated as having begun:
- OD7 drain activation itself (owner gate; P-OD7).
- Any new migration (no M40+; no Migration 31; numbering frozen at 39).
- Any production mutation/DDL/DML/RPC, any build/package/ship/install, any
  edge-function deploy, any RLS/grant change.
- Group B/C/D successor work or WS-4/WS-10 successors.
- Any fix of F1–F5 in this session (they are recorded, not implemented).

## I. Result

```
PREFLIGHT_AND_EXECUTION_PLANNING = COMPLETE
PLANNING_REMOTE_LOCK = PERFORMED
READINESS_GATE = NOT PASS (BLOCKED by F1–F5; precursor activation as-is is NOT advised)
PRODUCTION_MUTATION = NO
DRAIN_STATE = GATED/OFF
FINAL_HEAD = 34141681a5138a389535428940480e91f3d9c864
RESULT = BLOCKED_PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING_REMOTE_LOCKED
NEXT_RECOMMENDED_SESSION = OWNER_DECISION_REQUIRED
```

## J. Final Report — 45-Line Summary
1. SESSION PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING COMPLETE
2. TYPE READ-ONLY FORENSICS + VERIFICATION + PLANNING; NO ACTIVATION, NO BUILD, NO SHIP, NO MUTATION
3. BRANCH codex/i-tech-next-roadmap-freeze
4. ENTRY_HEAD 34141681a5138a389535428940480e91f3d9c864
5. EXIT_HEAD 34141681a5138a389535428940480e91f3d9c864
6. CLASSIFICATION CASE_A_FRESH (VERIFIED)
7. AHEAD 0 / BEHIND 0
8. AUTHORIZED_REMOTE github; origin NOT CONTACTED (VERIFIED)
9. PROD_REF ckruxrgppxxeqspxmyyd i-tech-production West EU (Ireland)
10. SUPABASE_CLI 2.117.0 NOT UPDATED
11. PRODUCTION_MUTATION NO (VERIFIED)
12. DRAIN_STATE GATED/OFF (UNCHANGED, VERIFIED)
13. PRODUCTION SCHEMA: local==remote M00…M39 (migration list green, VERIFIED)
14. PRODUCTION SCHEMA: schema_migrations 28 rows (M36/M37/M38/M39 present; no M40+; no M31)
15. PRODUCTION DATA: shops=3 members=3 auth.users=8 products=4 legacy_ledger=0 (READ-ONLY)
16. PRODUCTION ROUTINES: *_v2 + stock/opening-balance/account RPCs present (VERIFIED)
17. CONTROL SURFACE: AppConfig.syncDrainEnabled default FALSE (app_config.dart:39-42, VERIFIED)
18. CONTROL SURFACE: main.dart:257-278 wires A1 transport allowOversell:true drainEnabled seam (VERIFIED)
19. RUNTIME GATES: bound shop → drain seam → license → transport → start (fail-closed, VERIFIED)
20. ENQUEUE: single _enqueueAfterWrite chokepoint, atomic-with-write, occurrence token persisted (VERIFIED)
21. IDEMPOTENCY: key = entityType:entityUuid:operation:occurrenceToken, persisted, replays reuse (VERIFIED)
22. SERVER IDEMPOTENCY: sync_log UNIQUE + lookup/record + _v2 + UNIQUE(shop,key) on adjustments (VERIFIED)
23. TENANT ISOLATION: persisted queue shop_id + engine guard + RLS *_approval (VERIFIED)
24. RETRY: ladder 0/5/30/120/600s cap 5; network/license break preserve queue (VERIFIED)
25. ORDERING: FIFO created_at ASC; no topological ordering; single worker _isProcessing (VERIFIED)
26. FAILURE MODEL: per-entry transactions; partial-failure counts truthful (VERIFIED)
27. OBSERVABILITY: SessionState counters + a6 history + sync-status indicator (VERIFIED)
28. WS-5: writer_snapshot v17 captured at enqueue; adjudication NOT implemented (F4, capture-only)
29. TEST EVIDENCE: flutter test test/sync --concurrency=1 → All tests passed (+260 in 21 files) (VERIFIED)
30. TRANSPORT TESTS: 29 pass incl. fail-closed invoice without sale_items (VERIFIED)
31. FINDING F1 (HIGH): invoice adapter never supplies sale_items → invoices fail closed at drain (VERIFIED)
32. FINDING F2 (MEDIUM): A1 transport never emits conflict:true; version conflicts degrade to FAILED (VERIFIED)
33. FINDING F3 (MEDIUM): no production path re-arms FAILED→PENDING; retryEntry unreferenced (VERIFIED)
34. FINDING F5 (MEDIUM): generic create_cloud_* have no server idempotency key/UPSERT (VERIFIED)
35. READINESS VERDICT: 16 criteria covered; F1–F5 reduce confidence → NOT READY as-is (BLOCKED)
36. EXECUTION PLAN: defined G.1 activation sequencing, G.2 pre-drain, G.3 observability, G.4 abort, G.5 rollback
37. ABORT CRITERIA: cross-shop, unauthorized RPC, secret/grant drift, FAILED accumulation, license gate loss, migration drift
38. ROLLBACK: OFF build normal release rollback; drained data NOT auto-reverted (governance §E)
39. SCOPE: no migration >39, no production mutation, no build/ship/install, no Group B/C/D, no successor (preserved)
40. SACRED ARTIFACTS: inventory-only; none staged/modified/deleted (VERIFIED)
41. STASH/UNTracked: precondition residue inventoried and preserved (VERIFIED)
42. PRODUCTION LEDGER COUNT 28 rows matches predecessor expectation (VERIFIED)
43. AUTHORIZATION: P-OD7 CONDITIONALLY AUTHORIZED AFTER EVIDENCE accepted; evidence incomplete → activation NOT authorized this session
44. RESULT BLOCKED_PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING_REMOTE_LOCKED
45. NEXT_RECOMMENDED_SESSION OWNER_DECISION_REQUIRED — Owner must decide on F1–F5 disposition and a specific activated release build

## STOP STATEMENT

This session is complete. The OD7 sync drain remains GATED/OFF. No activation,
no build, no shipping, no production mutation, and no successor work was
performed. Activation requires a separate, explicit, owner-authorized session
that first resolves/owner-scopes planning findings F1–F5 and produces the
specific owner-approved release build per P-OD7 and the
ACTIVATED_RELEASE_VARIANT_GOVERNANCE_CONTRACT. STOP.