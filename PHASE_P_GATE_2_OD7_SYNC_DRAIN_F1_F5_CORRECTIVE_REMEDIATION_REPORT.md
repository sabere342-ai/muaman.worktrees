# PHASE P GATE 2 — OD7 SYNC DRAIN — F1–F5 CORRECTIVE REMEDIATION REPORT

## A. Session Result

RESULT_TOKEN = `OWNER_DECISION_REQUIRED_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REMOTE_LOCKED`

Reason:
- Finding F5 (generic `create_cloud_customer` / `create_cloud_expense` /
  `create_cloud_account` idempotency) is UNSAFE and cannot be remediated
  without a server schema change (Migration 40+), which this session is
  prohibited from authoring.
- The Owner elected to **abort all code changes** this session (explicit
  instruction). Only this disposition/schema-proposal report is produced.
- No OD7 activation occurs. The drain remains GATED/OFF (see Section K).
- The pre-existing remote lock was verified at entry and preserved
  (Sections C/E/O): no commit, no push, no ref mutation.

Session kind: DISPOSITION + OWNER-DECISION REPORT (no implementation).

## B. Repository Identity

- Canonical working repository: `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze`
- Git directory (linked worktree): `C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze`
- Current branch: `codex/i-tech-next-roadmap-freeze` (VERIFIED)
- Authorized remote: `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`)
- Forbidden remote: `origin` — NOT contacted this session (VERIFIED)
- Product: I Tech Store Management (Arabic first, RTL). Flutter root `app/`.
- Supabase production ref (read-only posture only): `ckruxrgppxxeqspxmyyd` /
  `i-tech-production` / West EU (Ireland).

## C. Entry / Recovery Classification

Classification: CASE_A_FRESH (VERIFIED this session).

- Tracked worktree clean: no `git diff` output (VERIFIED)
- Index clean: no cached diff (VERIFIED)
- No active Git operation: MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD /
  BISECT_LOG / rebase-merge / rebase-apply / index.lock all absent (VERIFIED)
- Pre-existing untracked items preserved and inventoried — 17 entries
  (VERIFIED via `git status --porcelain=v1`): `Continue`;
  `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md`;
  `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md`;
  `GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md`;
  `GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md`;
  `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`;
  `PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_REPORT.md`;
  `PHASE_P_GATE_2_EXISTING_OWNER_CLOUD_LINK_UI_IMPLEMENTATION_REPORT.md`;
  `PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_BLOCKED_PREFLIGHT_REPORT.md`;
  `PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_PLAN.md`;
  `PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION_REPORT.md`;
  `PHASE_P_GATE_2_PRODUCTION_SIGNIN_LINKER_PREFLIGHT_REPORT.md`;
  `PHASE_P_GATE_2_UPDATED_ANDROID_BUILD_INSTALL_AND_REENTRY_PREFLIGHT_REPORT.md`;
  `PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md`;
  `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`;
  `delivery/I-TECH-Delivery-v1.0.0.zip`; `supabase/.branches/`; `supabase/.temp/`.
- New untracked artifact created this session: this report itself
  (`PHASE_P_GATE_2_OD7_SYNC_DRAIN_F1_F5_CORRECTIVE_REMEDIATION_REPORT.md`).

## D. Predecessor Proof

- Governing findings source: `PHASE_P_GATE_2_OD7_SYNC_DRAIN_ACTIVATION_PREFLIGHT_AND_EXECUTION_PLANNING_REPORT.md`
  (§C.5, §C.6, §D, §E table, §F verdict). Findings F1–F5 recorded there with
  severity HIGH/MEDIUM and owner-gated successor actions.
- Predecessor baseline: `flutter test test/sync --concurrency=1` = 260 passing
  (recorded in predecessor closeout). NOT re-run this session because no code
  change was made (see Section N).

## E. Remote Lock Baseline (entry, preserved)

VERIFIED this session (commands executed fresh):

| Metric | Value |
|--------|-------|
| LOCAL_HEAD | `34e515f8400b49fcea152fa9969806316eb085ca` |
| TRACKING_HEAD | `github/codex/i-tech-next-roadmap-freeze` = `34e515f8400b49fcea152fa9969806316eb085ca` |
| DIRECT_GITHUB_HEAD (`git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`) | `34e515f8400b49fcea152fa9969806316eb085ca` |
| MERGE_BASE | `34e515f8400b49fcea152fa9969806316eb085ca` |
| AHEAD | 0 |
| BEHIND | 0 |

LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE. No commits, no push, no
force operations performed. The lock is preserved (REMOTE_LOCKED satisfied as
a preserved, not post-push, state — no refs moved).

## F. Finding F1 — Invoice convergence via `sale_items` (HIGH)

### Verdict
DISPOSITION APPROVED / IMPLEMENTATION DEFERRED (owner abort). No schema change
required.

### Verified evidence
- `InvoiceSyncAdapter.localToCloudPayload` (`app/lib/sync/adapters/invoice_sync_adapter.dart:25-34`)
  emits only `invoice_number/date/customer_name/payment_method/total_amount/
  total_items` — NEVER `sale_items` (VERIFIED by read).
- `DatabaseHelper.insertInvoiceWithItems` (`app/lib/database/database_helper.dart:1784-1830`)
  enqueues the invoice row (`:1792`) with `_enqueueAfterWrite`, then enqueues
  EACH sale line individually as a `sales` CREATE entry (`:1826`).
- Server `create_cloud_invoice_with_items_v2`
  (`supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql:691`)
  requires a NON-EMPTY `p_sale_items` JSONB array of `barcode`/`quantity`/
  `sale_price` and fails closed otherwise (`RAISE EXCEPTION 'At least one item
  required'`). Transport consequence: the invoice entry is resolved to
  `CloudDataException` and the engine eventually marks it FAILED, while the
  line-level `sale` entries converge individually.
- Preflight confirmed transport assertions (`sync_cloud_operations_transport_test.dart:198-215`
  fail-closed; `:165-196` routing only when `sale_items` supplied).

### Approved design (owner-selected option)
1. Capture `sale_items` (barcode, quantity, sale_price per line) into the
   invoice queue payload at enqueue time so the A1 drain can converge invoices
   as invoices through `create_cloud_invoice_with_items_v2`.
2. STOP enqueuing invoice-line `sales` entries individually. Otherwise the
   individual `sale` drain uses a different idempotency key than the
   invoice-level key → server creates each sale twice (once via the invoice
   transaction `cloud_sales.invoice_id`, once via the standalone sale RPC).
   The server schema is already designed to hold lines under the invoice
   (`cloud_sales.invoice_id`, `cloud_invoices.invoice_number` unique per shop).
3. `sales.sync_status` is write-only in `app/lib` (VERIFIED by grep — no
   readers), so suppressing per-line queue entries does not break UI/counters.
4. Review ALL invoice write paths (insert/update/delete) for consistency with
   the new enqueue contract, plus transport + regression tests.

### Owner gate
Owner approved the design but aborted implementation this session. Executing
this change is the successor scope (no migration needed).

## G. Finding F2 — Transport never emits `conflict`; version conflicts degrade to FAILED (MEDIUM)

### Verdict
DISPOSITION APPROVED / IMPLEMENTATION DEFERRED (owner abort). Client-side only.

### Verified evidence
- Engine has a complete conflict path: `sync_engine.dart:218` routes
  `CloudUpsertResult.conflict == true` into `_conflictResolver.resolveVersionConflict`
  → `_handleConflict` / durable `markConflict` + conflict audit; never a fake
  SYNCED.
- The A1 transport NEVER sets `conflict: true` (VERIFIED by read: transport
  resolves business failures to `CloudDataException`, e.g.
  `sync_cloud_operations_transport.dart:144,163,255,368,382,447,462`, and
  non-success maps fall into `sync_engine.dart:255-265` → `markFailed`).
- The transport does NOT forward `p_expected_version`, so the mig-26
  optimistic-concurrency branch on the versioned `update_cloud_*` overloads
  never fires for product/customer/expense (preflight §C.6 VERIFIED).

### Approved design
1. Classify server version-conflict / unique-violation / serialization failures
   as `CloudUpsertResult(conflict: true, ...)` in the transport so the engine's
   durable CONFLICT/REVIEW_REQUIRED machinery engages instead of FAILED.
2. Optionally forward `p_expected_version` where the entity adapter carries a
   known `serverVersion`, arming the mig-26 overloads. Overload selection must
   be verified per entity before activation.

### Owner gate
Implementation deferred by owner abort. No migration required.

## H. Finding F3 — No production path re-arms FAILED → PENDING (MEDIUM)

### Verdict
DISPOSITION APPROVED / IMPLEMENTATION DEFERRED (owner abort). Client-side only.

### Verified evidence
- `SyncQueueRepository.retryEntry` (`app/lib/sync/sync_queue_repository.dart:393-403`)
  re-arms a single entry to PENDING with `retry_count` reset, preserving
  entity/occurrence/idempotency/shop columns — no production caller (VERIFIED by grep).
- `SyncRuntime.retryNow()` (`app/lib/sync/sync_runtime.dart:232-238`) re-evaluates
  session/license/connectivity/shop gates via `ensureStarted` and re-drives a
  cycle; it does NOT re-arm FAILED entries.
- Retry affordance is wired in `settings_screen.dart` (~745) and
  `sales_screen.dart` (~111) via `SyncStatusIndicator.onRetry` → `retryNow()`.

### Approved design
Surface a MANUAL, operator-initiated, bounded FAILED→PENDING re-arm through the
existing retry affordance using `retryEntry` (never automatic-only; never
bypasses license/tenant gates; preserves the same idempotency key so server
dedup holds). The drain's retry ladder (`retry_count`, `_shouldRetryLater`,
`sync_engine.dart:307`) keeps any post-re-arm cycle bounded.

### Owner gate
Implementation deferred by owner abort. No migration required.

## I. Finding F4 — `writer_snapshot` v17 capture-only (MEDIUM)

### Verdict
DOCUMENTED GROUP-A NON-GOAL — no change. Matches preflight action.

### Verified evidence
- Snapshot captured at enqueue (`app/lib/database/database_helper.dart:366-378`),
  provider wired at `main.dart:215`; no reader of the snapshot in `app/lib/sync`
  (VERIFIED by grep).
- Adjudication (denying a now-revoked writer at drain time) remains a
  successor boundary, per preflight §C.4/F4.

## J. Finding F5 — Generic `create_cloud_*` idempotency (MEDIUM)

### Verdict
OWNER_DECISION_REQUIRED. UNSAFE paths cannot be made safe without a server
schema change; Migration 40+ is prohibited this session.

### Verified classification (server surface, read-only)
| RPC | Protection | Classification |
|-----|------------|----------------|
| `create_cloud_sale_with_stock_v2`, return/invoice/count `_v2` | `sync_log.idempotency_key UNIQUE` + `phase_m_idempotency_lookup/record` (mig 26/28) | SAFE_SERVER_IDEMPOTENT |
| `create_cloud_stock_adjustment` | `UNIQUE (shop_id, idempotency_key)` + `ON CONFLICT DO NOTHING` (mig 30:73,259) | SAFE_SERVER_IDEMPOTENT |
| `create_cloud_opening_balance` | SELECT-first + global unique `idempotency_key` (mig 38:248) | SAFE_SERVER_IDEMPOTENT |
| `update_cloud_shop_setting` | UPSERT by PK `(shop_id, setting_key)` (mig 25:1191) | SAFE_SERVER_IDEMPOTENT |
| `create_cloud_product` | `UNIQUE (shop_id, barcode)` + fail-closed pre-check raise (mig 25:41,314) | SAFE_BY_UNIQUE_CONSTRAINT |
| `create_cloud_expense_category` | `UNIQUE (shop_id, name)` + fail-closed pre-check raise (mig 25:22,607) | SAFE_BY_UNIQUE_CONSTRAINT |
| `create_cloud_customer` | none (mig 25:501) | **UNSAFE** |
| `create_cloud_expense` | none (mig 25:685) | **UNSAFE** |
| `create_cloud_account` | none (mig 38:124) | **UNSAFE** |

UNSAFE consequence (VERIFIED reasoning): a generic create that commits
server-side but whose response is lost, then replayed under the same queue
idempotency key, creates a SECOND cloud row (customer / expense / account).
The queue key alone dedupes the client queue entry, not the server row.

### Required owner decision (blocking READY)
Does the owner require server-side idempotency for these three creates before
first production OD7 activation, or accept the documented residual?

### Exact schema proposal (owner authorization required; NOT built this session)
Retrofit the three UNFAF list RPCs to the existing Phase-M idempotency pattern
(identical to the six `_v2` RPCs already consumed by the drain):

1. Add parameter `p_idempotency_key TEXT DEFAULT NULL` to
   `create_cloud_customer`, `create_cloud_expense`, `create_cloud_account`.
2. At function top: `SELECT phase_m_idempotency_lookup(p_idempotency_key)`;
   if an IDEMPOTENT result exists, `RETURN` the recorded result/`original_status`
   before any mutation.
3. Perform the existing validated mutation.
4. `SELECT phase_m_idempotency_record(...)` with:
   - idempotency key = the client queue key (already persisted as
     `sync_queue.idempotency_key` = `<entityType>:<entityUuid>:<operation>:<occurrenceToken>`),
     namespaced to avoid cross-entity collisions, e.g.
     `customer:<occurrenceToken>` / `expense:<occurrenceToken>` /
     `account:<occurrenceToken>`.
   - original_status = `'SYNCED'`, original_result = the returned UUID/JSON.
5. Delivery vehicle: a new migration (40+, additive `CREATE OR REPLACE
   FUNCTION`), plus the `_v2`-style test surface (fresh DB idempotent replay
   proving repeated delivery of the same occurrence does not duplicate a row).

Alternative evaluated and NOT recommended for customers/accounts: add natural-key
uniqueness (`UNIQUE(shop_id,name)`) — legitimate duplicate names are possible
and it would reject valid business data.

Backup/restore and fresh-install impact: none beyond function definitions
(additive); no table/RLS change required for the recommended approach.

## K. OD7 REMAINS GATED / OFF

VERIFIED: `AppConfig.syncDrainEnabled` (`app/lib/config/app_config.dart`) is
`bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue: false)`. Default is
OFF. No build, configuration, or code change in this session toggles it.
Activation requires the Owner decision in Section J, F1–F3 implementation, and
a SEPARATE owner-authorized activation session with an owner-approved release
build. No OD7 activation was performed or prepared.

## L. NO MIGRATION > 39

No migration file was authored, edited, or deployed this session. Migration
boundary 39 is preserved (VERIFIED source state unchanged; production read-only).

## M. Production Safety

No production mutation performed. Supabase production was not contacted for any
write/deploy. This session performed local repository read-only forensics only
(`git ls-remote github` on the authorized remote is a read; `origin` was never
contacted).

## N. Test Evidence

- No code change was made this session, so no new test execution was
  appropriate. The predecessor `flutter test test/sync --concurrency=1`
  baseline (260 passing) is carried forward as historical evidence only;
  a re-run is NOT VERIFIED for this session.
- No analyzer run was executed this session (no code under change). This
  report does NOT claim any test/analyzer result.

## O. Repository Change Proof

- Tracked changes: NONE (empty `git diff` / `git diff --cached`). VERIFIED.
- Commits: NONE. Push: NONE. Force operations: NONE.
- Remote lock preserved: LOCAL == TRACKING == DIRECT_GITHUB == MERGE_BASE ==
  `34e515f8400b49fcea152fa9969806316eb085ca`; AHEAD=0; BEHIND=0. VERIFIED.
- New untracked artifact this session: this report file (preserved, not
  staged). All prior untracked items preserved.
- The 25-field final-closeout response is delivered at session close with the
  token recorded in Section A.

## P. Readiness Conclusion

WILL NOT CLAIM READY. Conclusion: OWNER_DECISION_REQUIRED.

Blocking owner decision: F5 — whether server-side idempotency is required for
customer/expense/account creates before first production activation.

Deferred implementation (owner abort): F1 (sale_items carrier), F2 (conflict
classification + `p_expected_version`), F3 (manual FAILED→PENDING re-arm).
F4 stays a documented non-goal.

A follow-up session after the Owner decision may implement F1–F3, build the F5
schema proposal if authorized (Migration 40+ under separate authorization),
then proceed to a distinct owner-authorized OD7 activation session.

## Q. Final Closure

SESSION_CLASS = OWNER_DECISION_REQUIRED
OD7_ACTIVATED = NO
CODE_CHANGED = NO
STOP_CONFIRMATION = YES — no successor work, no activation, no migration was
started or implied by this report. The next step requires an explicit Owner
decision and authorization.