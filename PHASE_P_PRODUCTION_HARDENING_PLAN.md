# PHASE P — PRODUCTION HARDENING PLAN

**Date:** 2026-08-29
**Baseline:** `a0798a1f26db82d43cc0b5137474967501760ea9` on `codex/i-tech-next-roadmap-freeze`
**Governance:** Owner decisions OD1–OD7 resolved post-Phase-O (this session's authoritative input) → `NEXT_AUTHORIZED_WORK = PHASE_P_PLANNING`
**Phase P identity:** PRODUCTION_HARDENING (final roadmap phase per `PROJECT_MASTER_PLAN.md` §13)

---

## A. Purpose

Phase P hardens the I Tech Store Management application for production readiness. It is a **planning-only** document for `PHASE_P_PLANNING`; it does **not** authorize Phase P implementation. Implementation begins only after a separate, explicitly-authorized `PHASE_P_IMPLEMENTATION` session.

This plan is **repository-first**: every workstream is grounded in current-source evidence (verified file:line citations), not a generic hardening wish-list. The plan preserves all completed roadmap work (Phases A–O) and all frozen identifiers.

### Frozen legacy identifiers (NOT to be renamed by Phase P)
- `muaman_store` (pubspec name / binary name)
- `muaman_store.db` (production DB filename, `database_helper.dart:371,403`)
- Existing Windows identity (AppId `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}`, Inno AppName `I-TECH للتكنولوجيا`)
- Existing Linux identity, CMake identities

Android package identity is a **separate** concern and is treated independently (see Workstream E); it does NOT require renaming the frozen desktop/database identifiers above.

---

## B. Authoritative Prerequisites

| Precondition | Status | Evidence |
|--------------|--------|----------|
| Phase A–O complete | ✅ | Git log HEAD = `a0798a1` "feat: implement phase O"; Phase O implementation locked (tag `phase-o-implementation-locked`) |
| PHASE_O_IMPLEMENTATION + LOCAL_CLOSURE + REMOTE_LOCK + FINAL_CLOSURE = COMPLETE | ✅ | Phase O plan → implementation lineage; OD5 resolved (`OWNER_DECISION_OD5_INVOICE_ATTRIBUTION.md`); `PHASE_O_IMPLEMENTATION_OD5_GATE = CLEARED` |
| Owner decisions OD1–OD7 resolved | ✅ | This session's authoritative owner input (treat as requirements, not reopened design) |
| Phase P is the roadmap successor of Phase O | ✅ | `PROJECT_MASTER_PLAN.md` §13 (P = final); `PHASE_O_INVOICE_BRANDING_DELIVERY_PLAN.md` §A "SUCCESSOR = Phase P (Production Hardening) — final phase" |
| Repository identity matches | ✅ | Expected branch/remote verified at session start (see Section C) |

---

## C. Session Entry / Recovery Classification

| Field | Value |
|-------|-------|
| ROOT | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| LOCAL_HEAD | `a0798a1f26db82d43cc0b5137474967501760ea9` |
| REMOTE_HEAD (`github/...`) | `a0798a1f26db82d43cc0b5137474967501760ea9` |
| MERGE_BASE | `a0798a1f26db82d43cc0b5137474967501760ea9` |
| AHEAD / BEHIND | 0 / 0 |
| INDEX | EMPTY |
| TRACKED WORKTREE | CLEAN |
| UNTRACKED | 4 preserved sacred artifacts (see D) |

**Recovery classification:** `CASE_A_FRESH_CONTINUATION`. The immediately preceding OpenCode session hit a model/provider error (`[404] Provider returned error`) during an unrelated `Get-ChildItem -Recurse -Filter "*OD*"` exploration. It made **no tracked mutations**; only the 4 pre-existing untracked sacred artifacts remain, which were already present before the failed session (verified against `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` §B, which records the identical 4-artifact untracked set). No preserved in-progress work was lost; nothing ambiguous to resolve.

**Note:** During this planning session `dart format --set-exit-if-changed .` was once run with write output; the 19 files it reformatted were reverted to HEAD immediately (verified: tracked worktree clean). Formatting changes are explicitly outside planning scope.

---

## D. Current-State Baseline (verified)

### D.1 Test / Quality baseline (`app/`)
- `flutter analyze`: **PASS — no errors, no warnings** (62 `info`-level lints, all pre-existing style hints: `prefer_const_constructors`, `constant_identifier_names`, etc.; `lib/` and `test/`)
- `dart format --output=none --set-exit-if-changed .`: **FAIL — 19 of 270 files not formatted** (pre-existing baseline; NOT fixed during planning)
- `flutter test`: **1396 passing / 3 failing** (of ~1399 completed)
  - Pre-existing failures at HEAD (not introduced, not repaired during planning):
    1. `test/features/shop_profile_settings_widget_test.dart` — "owner can save the shop profile from the UI and it persists" (UI hit-test off-screen in 800×600 viewport)
    2. `test/features/shop_profile_settings_widget_test.dart` — "blank shop name shows a validation message and nothing saves" (same class of issue)
    3. `test/sync/crash_recovery_test.dart` — "window G — local apply / audit boundary … resolved entry can never exist without its audit evidence" (expects fully-resolved `SYNCED`+`RESOLVED` row to be removable from queue; row remains — consistent with sync-drain dead-seam finding)

### D.2 Runtime cloud integration (Domain A) — the foundational finding
**The device→cloud sync runtime is NOT constructed or started by the application.** Enqueue (write-side) is live; drain (read-side) is dead.

| Component | Status | Evidence |
|-----------|--------|----------|
| `SyncEngine` construction | NOT_CONSTRUCTED (tests-only) | `sync_engine.dart:34`; zero `lib/` construction sites |
| `HydrationService` construction/execution | NOT_CONSTRUCTED (tests-only) | `hydration_service.dart:15`; `hydrate()` never called from `lib/` |
| `IncrementalSyncService` / scheduled sync | NOT_CONSTRUCTED (tests-only) | `incremental_sync_service.dart:16`; no timer/pull in `lib/` |
| `SyncWorker` runtime wiring | NOT_CONSTRUCTED (tests-only) | `sync_worker.dart:32,46`; `Timer.periodic` only started in tests |
| login/session transitions | CONSTRUCTED_AND_RUNNING | `main.dart:230-238`, `login_screen.dart:125-233` |
| shop/business context lifecycle | CONSTRUCTED_AND_RUNNING | `active_shop_context.dart:30`; `main.dart:196-205`; fresh `arm()` path dead (`tenant_isolation_gate.dart:155`) |
| offline/online transitions | NOT_CONSTRUCTED | no `connectivity_plus`; no auth-state listener subscribed; `SyncStatusIndicator` unused |
| queue draining/retry | Enqueue LIVE; Drain DEAD | `database_helper.dart:256-305` enqueues; `retryEntry` (`sync_queue_repository.dart:362`) has zero `lib/` callers |
| Supabase client wiring | CONSTRUCTED_AND_RUNNING | `main.dart:47-56`; gated on `AppConfig.isConfigured` |

Governing comment confirming intent: `seller_session_provisioning.dart:136-138` — "The sync runtime is intentionally NOT touched here or anywhere else in Phase L (D-L7): SyncEngine/SyncWorker/HydrationService remain unconstructed." The runtime callback `session_state.dart:44` (`updateSyncStatus`, "called by SyncWorker after each cycle") has zero callers.

**Production risk:** every queued business write (sales, returns, products, invoices, imported rows) is durably written to SQLite and enqueued to `sync_queue`, but **never reaches Supabase**. Offline seller sales and all cloud-tenant writes are silently stranded = cloud data loss / never-sync.

### D.3 Licensing (Domain B)
| Item | Status | Evidence |
|------|--------|----------|
| 14-day trial, server-authoritative start/expiry | PARTIALLY (server start/expiry ✓; no expiry state transition job) | `database_functions.sql:159-216`; `phase_e_licensing_enhancements.sql:129-143` |
| Monthly/annual subscription model | NOT_IMPLEMENTED (only TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL) | `20260820000005_create_licenses.sql:14-15`; no plans table; `licenses.plan` nullable+unused |
| Tier limits (shops/devices per plan) | NOT_IMPLEMENTED (no tiers; single `max_devices=3` default) | `phase_e_licensing_enhancements.sql:17`; `database_functions.sql:18-56` (no quota) |
| Device limits | PARTIALLY (server count ✓; binding by forgeable `installationId` UUID, not hardware fingerprint; `DeviceIdentity` hash never sent) | `phase_e_licensing_enhancements.sql:167-228,329-336`; `entitlement_cache.dart:156-196` |
| Paid offline grace (7 days) | PARTIALLY — effective cap is **24h**, not 7d | `offline_grace_policy.dart:8,13,48-51` (global `revalidationWindow=24h` checked first) |
| Trial offline behavior (0-day intent) | MISMATCH — `trialGrace=0` unused; trial usable offline until trial expiry (≤24h) | `offline_grace_policy.dart:10,54-61` |
| Server-authoritative state | ALREADY_SATISFIED (online) | `phase_e_licensing_enhancements.sql:45-160` (SECURITY DEFINER RPC) |
| Expiry/revocation | PARTIALLY — pull-only; no poll/realtime/webhook; effective latency = next online resolve | `cloud_licensing_service.dart:185-236,326-370` |
| Launch/startup offline | PARTIALLY — cold start `initialize()` with no shopId leaves state unknown/blocking | `cloud_licensing_service.dart:153-179`; `main.dart:182` |
| Tamper resistance | PARTIALLY / largely DEAD — Ed25519 token machinery empty-keyed (`_defaultTrustedKeys` empty); production path trusts Supabase RPC JSON; cache is plaintext; clock-rollback detect never invoked | `entitlement_token.dart:12,344`; `entitlement_cache.dart:89-137`; `offline_grace_policy.dart:79-93` |
| Legacy Ed25519 path | DEAD_SEAM (ActivationClient throws "not yet deployed"); still surfaced in Settings (`LicenseStatusScreen`) | `licensing_service.dart:408-431`; `settings_screen.dart:832-869` |

### D.4 Negative-stock Option C (Domain C)
| Item | Status | Evidence |
|------|--------|----------|
| Option C durable persistence/audit | **DEAD_SEAM** — `InventoryOversellPolicy.preserveWithAdjustment` is a default constant not read in production; `ReconciliationService.adjustmentSink/ownerNotifier` nullable+unused; `ConflictAuditRepository` never instantiated in `lib/` | `inventory_oversell_policy.dart:17-18`; `reconciliation_service.dart:104-110`; `conflict_audit_repository.dart` |
| Local oversell behavior | Local path blocks oversell ("Insufficient stock") so Option C recovery is not locally exercised | `database_helper.dart:1232-1298` |
| Server (Phase M) `p_allow_oversell` paths | exist but no production caller | `cloud_sales_repository.dart:191-210` |
| Durable audit / conflict record | typed model + transition-only repository exist (tests-only) | `conflict_audit_record.dart`; `conflict_audit_repository.dart` |
| Server `SELECT … FOR UPDATE` on stock RPCs | NOT_IMPLEMENTED (DR-M03 outstanding) | Phase M migration `20260820000028...sql` |

The known concern in this prompt is **confirmed**: the durable Option C persistence/audit path is a dead seam (not runtime-wired), and OD6 is **STILL OPEN** per repository evidence (`PHASE_M` §DR-M06 preserves the OPEN-GATE).

### D.5 Offline seller sales (Domain D)
| Item | Status | Evidence |
|------|--------|----------|
| Permission gate (`salesOnly` can create sale) | ALREADY_SATISFIED (local) | `permissions.dart:211-214`; `database_helper.dart:1182,1235,1303` |
| Entitlement enforcement on sale path | ALREADY_SATISFIED (local) | `main.dart:181-184`; `cloud_licensing_service.dart:290-296` |
| Queued offline sale | ALREADY_SATISFIED (enqueue) | `database_helper.dart:1271-1272,1359` |
| Later synchronization (drain) | **DEAD_SEAM — never syncs** | no `SyncWorker` in `main.dart`; constructions only in tests |
| Revoked permission/license | PARTIALLY — intended server re-check is unreachable (never uploaded) | `require_shop_permission` SQL; no runtime drain |
| Conflict handling | DEAD_SEAM (implemented+tested, not wired) | `sync_engine.dart:255-516` |
| Idempotency / dup prevention | PARTIALLY — key form exists but no stable client `cloud_uuid` for new sales (keyed off `local-<id>`) | `database_helper.dart:291`; `models/sale.dart` (no `cloud_uuid`) |
| Sync status visibility | DEAD_SEAM — counters never updated; `SyncStatusIndicator` unused | `session_state.dart:43-55`; `sync_status_indicator.dart` |

**Owner divergence note:** The current repository default for offline `salesOnly` sales was historically "BLOCKED" (Phase H) then an interim "permitted" (`PHASE_L`). The owner now permits offline seller sales under existing entitlement/permission, so Phase P must **harden** the behavior (wire the drain + idempotency + visibility) rather than remove it. This is a `BLOCKED_OWNER_DECISION` until the sync-drain decision is confirmed in implementation.

### D.6 Android production readiness (Domain E)
| Item | Status | Evidence |
|------|--------|----------|
| Package identity | `com.almuaman.muaman_store` — diverges from internet-registered productization intent `com.itech.storemanagement`; NOT the frozen desktop/db identity (separate concern) | `app/android/app/build.gradle:9,28` |
| Permissions | only `INTERNET` | `AndroidManifest.xml:6` |
| Storage / secure secrets | EncryptedSharedPreferences (AES256), KeystoreChannelSecretStore, fail-closed <API23 | `secure_store_android.dart:17-40`; `MainActivity.kt:113-140` |
| Release signing | **DEBUG signing config used for release — BLOCKED_OWNER_DECISION (OD-K2)** | `build.gradle:41` |
| minSdk/targetSdk | minSdk 21, targetSdk 34 (D11 frozen), compileSdk 35 | `build.gradle:13,32-33` |
| Seller/offline path on Android | functional; same sync dead-end applies | `cloud_licensing_service.dart:495-510`; `main.dart:322-333` |

### D.7 Security / Supabase (Domain F)
| Item | Status | Evidence |
|------|--------|----------|
| Server-side RBAC (not client-trust) | ALREADY_SATISFIED — client explicitly "never the security authority"; every cloud RPC re-authorized by `require_shop_permission` (SECURITY DEFINER) | `permission_sync_service.dart:17-18`; `20260820000024...sql:232-298`; `20260820000025...sql:331-1181` |
| RLS coverage | ALREADY_SATISFIED — RLS + SELECT-policy via `auth.uid()` + active membership across tables; INSERT/UPDATE/DELETE restricted to `service_role` | `20260820000010_rls_policies.sql`; `20260820000021...sql`; `20260820000029_fix_shop_members_rls_recursion.sql` |
| Edge functions | only `invite-employee` exists; service-role key; owner verified from JWT | `functions/invite-employee/index.ts:37-51` |
| Secret handling | no real secrets committed; AppConfig placeholders + `isConfigured` guard; dart-define injection | `app_config.dart:12-30` |
| Dangerous client trust | resolved server-side; residual: no `SELECT…FOR UPDATE` on inventory, no client validate of RPC response signature | see C, B |

### D.8 Sync / data durability (Domain G)
- Enqueue side completes (idempotency key + unique occurrence token): `database_helper.dart:237-242,290-304`, schema V13/V15 (`:728,822-825`) — GOOD.
- Drain/replay/reconnect/recovery/multi-device all built+tested but **unwired** in runtime (see D.2, D.5).
- Server `sync_log` idempotency + entity index for RLS: `20260820000026...sql:25-50,308-318` ✓.
- Client `cloud_uuid` generation for new entities is MISSING (only server/migration/hydration stamping) — fundamental multi-device/multi-reinstall mapping gap.

### D.9 Backup / restore / local DB (Domain H)
| Item | Status | Evidence |
|------|--------|----------|
| Backup | ALREADY_SATISFIED (owner-only, permission-checked) | `standalone_backup_service.dart:40` |
| Restore | **CRITICAL BUG** — restore accepts only `user_version` 7 or 8, but current `schemaVersion=15`; a current backup is rejected | `standalone_restore_service.dart:108-113` vs `database_helper.dart:93` |
| Schema compat / integrity check | PARTIAL (integrity_check + table presence ✓; version whitelist stale) | `standalone_restore_service.dart:100-139` |
| Production DB location | `getDatabasesPath()/muaman_store.db` | `database_helper.dart:401-404` |
| Upgrade safety | schema V15; additive migrations | `database_helper.dart:93` |

### D.10 Release / build hardening (Domain I)
| Item | Status | Evidence |
|------|--------|----------|
| Windows release build + installer | ALREADY_SATISFIED (Inno Setup, pinned ISCC SHA-256, deterministic tooling, leak_scan + manifest) | `tools/release/package_windows_installer.ps1`; `installer/muaman.iss`; `tool/leak_scan.dart` |
| Android release build | PARTIALLY — debug signing blocks real release | `build.gradle:41` |
| Analyzer | PASS (no errors/warnings) | `flutter analyze` |
| Formatting | 19/270 files unformatted (baseline) | `dart format --output=none` |
| Versioning | `1.0.0+1` | `pubspec.yaml:19` |
| Crash/error handling | mostly local try/catch; no centralized crash reporting | repository scan |
| Logging / secret leakage | leak_scan tool exists; no committed secrets found | `tool/leak_scan.dart` |

### D.11 Business-critical requirements (Domain J)
| Requirement | Status | Evidence |
|-------------|--------|----------|
| Mandatory cost price | ALREADY_SATISFIED (UI + DB) | `inventory_screen.dart:222-230`; `database_helper.dart:903-905,979-981` |
| Purchase-cost-change warning | **NOT_IMPLEMENTED** | no match; `inventory_screen.dart:195-299` edits without warning |
| "Create new item" on cost change | **NOT_IMPLEMENTED** | same edit dialog |
| Opening balances per account | **NOT_IMPLEMENTED** (no suppliers/accounts/ledger entity) | schema scan |
| Monthly/period profit reporting | PARTIAL — today/month/all aggregates only; no arbitrary-period range filter | `sales_report_screen.dart:80-81,122-148`; `sales_screen.dart:356-371` |
| Excel import | ALREADY_SATISFIED (zero-cost guard, atomic, sync enqueue) | `workbook_importer.dart:468-479,528`; `settings_screen.dart:2238` |
| Inventory correctness | ALREADY_SATISFIED (atomic sales, Phase M server functions) | `database_helper.dart`; `phase_m...sql` |
| Invoice/printing behavior | ALREADY_SATISFIED (A4 + thermal, Phase O) | `invoice_delivery.dart:45-91`; `thermal_delivery.dart:23-26` |

---

## E. Scope (Phase P)

### E.1 In-scope (minimum defensible production-hardening scope)
1. **WS-1 Runtime Sync Lifecycle (drain)** — construct and own a real device→cloud sync runtime (SyncWorker/SyncEngine + SyncCloudOperations + HydrationService + IncrementalSyncService) in the app runtime, including wired retry, reconnect, crash-recovery sweep, and status publication. This is the highest-severity, cross-cutting item (fixes D.2, D.5, D.8).
2. **WS-2 Sync Data Integrity** — client-generated stable `cloud_uuid` for new entities; idempotency correctness; conflict audit wiring; soft-delete/multi-device mapping.
3. **WS-3 Negative-stock Option C durability** — activate `InventoryOversellPolicy.preserveWithAdjustment` in the runtime reconciliation path, persist durable adjustments + audit trail, plus server `SELECT…FOR UPDATE` on stock RPCs.
4. **WS-4 Licensing commercial model** — implement monthly/annual subscription + tier limits (shops/devices), correct offline-grace semantics (paid 7d / trial 0d / perpetual 14d-compat), server-authoritative expiry/revocation propagation, offline startup behavior, tamper-hardening where reasonably applicable (cached-entitlement integrity + clock handling).
5. **WS-5 Offline seller sales hardening** — keep the permitted behavior; harden by enabling the drain (WS-1), adding per-write permission snapshot for later adjudication, visible pending-sync status, and duplicate prevention via WS-2. Dependency: WS-1/WS-2.
6. **WS-6 Backup/restore safety** — fix restore schema-version whitelist (forward-compatible to V15+); confirm backup/restore correctness and corruption handling.
7. **WS-7 Android release readiness** — resolve release signing (BLOCKED_OWNER_DECISION), confirm package identity boundary (freeze `com.almuaman.muaman_store` or approved migration), release config, platform-specific failure handling.
8. **WS-8 Release/build hardening** — Android release pipeline, crash/error handling, versioning, logging-without-secrets confirmation, formatting baseline correction.
9. **WS-9 Business-critical gaps** — purchase-cost-change warning + "create new item" option, opening balances per account, arbitrary-period profit reporting.
10. **WS-10 Security/supabase final verification (seal)** — RLS coverage confirmation, edge-function surface (expected: only `invite-employee` unless owner extends), secret handling, migration consistency, server-authoritative trust boundaries.

### E.2 Non-scope (explicit exclusions)
- **Renaming frozen identifiers** (`muaman_store`, `muaman_store.db`, Windows/Linux/AppId/CMake identities).
- Reopening Phases A–O decisions (GV/let chain, OD5 text, trial-to-EXPIRED semantics are its own decision, etc.).
- Introducing a real payment/billing provider integration (enterprise invoicing, Stripe/Play Billing) — subscription model is implemented as entitlement; external billing is `POST_P`/`BLOCKED_EXTERNAL`.
- Play Store / app-store publishing (marketed as `POST_P`).
- Client-side-only security authority (server remains authoritative).
- Unrelated pre-existing test/violation repairs (e.g., the 2 shop-profile widget-test failures) unless they block a Phase P acceptance gate.
- Centralized crash-reporting SaaS onboarding (unless owner decides in WS-8; default `POST_P`).

---

## F. Workstreams — Detail

### F.1 Workstream sequencing (safe order)
```
WS-1 (Runtime Sync Lifecycle)         — foundational; unblocks 2,3,5
   └→ WS-2 (Sync Data Integrity)       — depends on WS-1
   └→ WS-3 (Option C durability)       — depends on WS-1
   └→ WS-5 (Offline seller hardening)  — depends on WS-1, WS-2
WS-6 (Backup/restore safety)           — independent, do early (critical bug)
WS-4 (Licensing commercial model)      — independent of sync
WS-7 (Android release readiness)       — BLOCKED_OWNER_DECISION (signing/package)
WS-8 (Release/build hardening)         — after WS-7
WS-9 (Business-critical gaps)          — independent
WS-10 (Security/supabase seal)         — final verification workstream
```
Rationale: WS-1 first because the single largest production risk (never-sync) blocks the correct behavior of offline sales, Option C durability, conflict handling, and status. WS-6 next because restore is currently functionally broken against the active schema. WS-7 is owner-gated; its implementation is sequenced after the decision. WS-10 is a sealing verification, last.

### F.2 WS-1 — Runtime Sync Lifecycle (drain)

1. **Problem / current evidence:** No `SyncWorker`/`SyncEngine`/`HydrationService`/`IncrementalSyncService` is constructed or started in `lib/` or `main.dart` (D.2). Enqueue is live; drain is dead. All cloud-tenant business writes are stranded.
2. **Production risk:** Cloud data loss (never-sync) for every queued write; offline sales never reach the shop ledger; reports/backups diverge from server; silent failure.
3. **Exact intended behavior:** On successful login/resume/session/shop-context establishment (and while licensed + connected + shop bound), the runtime constructs and starts a `SyncWorker` that periodically drains `sync_queue` through `SyncEngine.processQueue`, performs initial `HydrationService.hydrate()` and `IncrementalSyncService.pullChanges()`, handles offline/online transitions, retries with backoff, runs the crash/restart recovery sweep on startup, and publishes status via `SessionState.updateSyncStatus` (populating counters + `SyncStatusIndicator`).
4. **Likely source files/modules:** `main.dart`, `services/session_state.dart`, `services/cloud_session_resume.dart`, `services/seller_session_provisioning.dart`, `sync/sync_worker.dart`, `sync/sync_engine.dart`, `sync/hydration_service.dart`, `sync/incremental_sync_service.dart`, `sync/sync_queue_repository.dart`, `widgets/sync_status_indicator.dart`, `rbac/permission_sync_service.dart`.
5. **Dependencies:** WS-1 depends on a live `SyncCloudOperations` (needs enabled/edge capability verifying `require_shop_permission`+`sync_upsert_entity`/Phase M RPC presence), licensing/entitlement gating (WS-4 interplay), and connectivity detection. Must be gated so it never runs unlicensed or for a non-cloud (offline-only) tenant.
6. **Data/schema implications:** none required to start (schema V15 + `sync_queue` already present). Possibly new fields for per-write snapshot (see WS-5/WS-2).
7. **Offline implications:** SyncWorker must detect offline and defer (no drain) while keeping enqueue live; no loss of queued rows on process restart (leveraging M-I05/DR-M09 recovery sweep already built).
8. **Security implications:** drain only within bound shop + active entitlement + permission; server already re-authorizes each RPC; no client-trust regression.
9. **Test requirements:** activate existing (currently test-only) sync integration/conflict/idempotency/crash-recovery suites against a runtime harness; add startup/session-transition wiring tests; assert queue drains with bounded retries.
10. **Manual verification:** sign in online → create sale → observe sync into Supabase; go offline → create sale → come online → observe drain; kill process mid-queue → restart → recovery sweep drains remaining.
11. **Acceptance criteria:** after sign-in a bounded `SyncWorker` is running; a live write reaches Supabase within the defined interval; `SessionState` counters reflect real queue state; process-restart recovery completes without duplicate application.
12. **Explicit exclusions:** no change to permission model; no change to server schema unless a WS-specific decision requires it.

### F.3 WS-2 — Sync Data Integrity

1. **Problem / current evidence:** new offline entities are enqueued with idempotency keys derived from `local-<id>` with `cloud_uuid` NULL (`database_helper.dart:291`); no stable client identity for multi-device/reinstall mapping; conflict audit repository unwired.
2. **Production risk:** duplicate logical records across reinstalls/devices; inability to match local offline sale to server entity; audit gaps on conflict resolution.
3. **Exact intended behavior:** every new business entity gets a client-generated stable `cloud_uuid` at creation (created BEFORE enqueue); idempotency keys become cloud-stable; conflict audit records are durably written on resolution transitions.
4. **Likely source:** `database_helper.dart` (insert paths), `models/*` (add `cloud_uuid`), `sync/entity_sync_adapter.dart`, `sync/sale_sync_adapter.dart`, `sync/conflict_audit_repository.dart`, `sync/sync_engine.dart`.
5. **Dependencies:** WS-1 (drain) to make idempotency meaningful end-to-end.
6. **Data/schema implications:** possible new `cloud_uuid` columns or backfill for existing entities (additive migration; schema V16+ with migration test).
7. **Offline implications:** improves safe offline entity creation and later reconciliation.
8. **Security/conflict implications:** reduces duplicate/`REVIEW_REQUIRED` conflicts; audit trail intact.
9. **Test requirements:** idempotency server-contract tests already exist (`test/sync/idempotency_server_contract_test.dart`); extend to assert cloud-stable keys; migration test for `cloud_uuid` backfill.
10. **Manual verification:** create offline sale on device A, sync, reinstall, confirm no duplicate on device B; conflict → `REVIEW_REQUIRED` → resolution writes audit row.
11. **Acceptance criteria:** stable UUID present on all new entities; reinstall/multi-device dedup proven; conflict audit durable.
12. **Exclusions:** renaming frozen DB file/table identities.

### F.4 WS-3 — Negative-stock Option C durability

1. **Problem / current evidence:** Option C default constant exists but is unwired; adjustment sink + audit repository unused (D.4). Local path blocks oversell so recovery isn't locally exercised.
2. **Production risk:** if offline oversell is permitted, negative stock could drift without durable adjustment/audit; without `SELECT…FOR UPDATE` the server non-negative invariant can race.
3. **Exact intended behavior:** when a sale would oversell (per owner policy), the sale is preserved with its negative quantity, an explicit durable adjustment record is created, and an audit trail is persisted; reconciliation reports/stock stay exact; server stock RPCs use `SELECT…FOR UPDATE` to serialize.
4. **Likely source:** `sync/inventory_oversell_policy.dart`, `sync/reconciliation_service.dart`, `sync/conflict_audit_repository.dart`, `database_helper.dart`, `cloud_sales_repository.dart`, `supabase/.../phase_m_inventory_conflict_hardening.sql` (add `SELECT…FOR UPDATE`).
5. **Dependencies:** WS-1 (to route reconciliation through runtime); OD6 policy confirmation.
6. **Data/schema implications:** new adjustment/audit table(s) or columns (additive).
7. **Offline implications:** Option C applies at sync reconciliation; local behavior preserves the sale.
8. **Security implications:** server authoritative; concurrency-safe via `FOR UPDATE`.
9. **Test requirements:** oversell-preserves-event tests (existing in `test/sync/`), plus durable-adjustment + audit-persistence tests; server concurrency test.
10. **Manual verification:** offline sale oversells → sync → server shows negative + adjustment row + audit record; reports reflect exact quantity.
11. **Acceptance criteria:** negative quantity preserved; explicit adjustment + audit trail durably persisted and synced; races serialized.
12. **Exclusions:** flipping owner policy away from Option C (that is an owner decision, isolated behind the seam).

### F.5 WS-4 — Licensing commercial model

1. **Problem / current evidence:** no monthly/annual subscription or tiers (B.2/3); offline grace effectively 24h not 7d (B.6); trial offline mismatch (B.7); revocation pull-only (B.9); offline startup forcing (B.10); tamper/hardening gaps (B.11/12).
2. **Production risk:** cannot sell/operate the commercial plans as authorized; offline durability differs from owner intent; revocation latency; tamper surface.
3. **Exact intended behavior:** implement subscription entitlement (monthly/annual) + tiers (Starter 2/3, Professional 5/10, Enterprise ∞; Trial 1/1) enforced server-side on shop/device creation; correct offline grace (paid 7d, trial 0d, perpetual 14d-compat); clear offline startup behavior; poll/realtime revocation; harden cached-entitlement integrity + clock handling; retire or gate the legacy Ed25519 dead path.
4. **Likely source:** `licensing/cloud_licensing_service.dart`, `licensing/offline_grace_policy.dart`, `licensing/entitlement_cache.dart`, `licensing/licensing_service.dart` (legacy), `services/cloud_auth_service.dart`, `database_helper.dart`, `supabase/migrations/*` (plans/tiers/subscription fields, expiry job, quota checks), edge function(s) for entitlement/revocation if needed.
5. **Dependencies:** needs a server schema change + entitlement RPC/function; requires owner confirmation of subscription/`plan` mapping and whether monthly/annual renewals are manual or automated.
6. **Data/schema implications:** additive `plans`/`plan` semantics, tier columns, subscription state; migration V16+.
7. **Offline implications:** grace computation corrected to owner intent; offline startup gating clarified.
8. **Security implications:** entitlements server-authoritative; cached state integrity (digest/HMAC) + clock-rollback enforcement.
9. **Test requirements:** update/extend `test/licensing/*` (phase_e, cloud_licensing) for tiers, subscription, grace, revocation; offline-grace boundary tests; tamper tests.
10. **Manual verification:** trial → start paid; create >tier shops/devices → blocked; revoke license → blocked at next online resolve; offline within grace works, beyond blocks.
11. **Acceptance criteria:** tier limits enforced; grace matches owner spec; revocation propagates with bounded latency; offline startup safe; tamper checks active.
12. **Exclusions:** actual payment/billing provider integration (POST_P/BLOCKED_EXTERNAL); perpetual as launch offering (architectural-compat only).

### F.6 WS-5 — Offline seller sales hardening

1. **Problem / current evidence:** seller offline sales enqueue but never sync (D.5); revocation/permission adjudication intended server-side but unreachable; no pending status visibility; idempotency unstable (WS-2).
2. **Production risk:** permitted offline sales stranded (cloud loss); revoked seller can rack up stranded sales; silent failure (no status).
3. **Exact intended behavior:** preserve permission/entitlement gating; drive queued seller sales through the runtime drain (WS-1); add durable per-write permission/entitlement snapshot to adjudicate at sync time under revocation; expose pending-sync status to the UI.
4. **Likely source:** `seller_session_provisioning.dart`, `database_helper.dart` (snapshot column), `sync/*` (drain, adapter), `widgets/sync_status_indicator.dart`, `screens/settings_screen.dart`.
5. **Dependencies:** WS-1, WS-2.
6. **Data/schema implications:** optional per-queue/per-entity snapshot columns (additive).
7. **Offline implications:** full offline→online lifecycle preserved and made visible.
8. **Security implications:** server still re-authorizes on upload; snapshot provides audit for revoked-seller adjudication.
9. **Test requirements:** offline sale → online drain → server write; revocation→adjudication; duplicate-prevention across devices.
10. **Manual verification:** seller sells offline, comes online, sale appears in owner's server view; revoked seller's queued sale is rejected with audit.
11. **Acceptance criteria:** offline seller sale reliably reaches server; status visible; revocation handled without data loss or silent acceptance.
12. **Exclusions:** removing offline seller sales (owner requires hardening, not removal).

### F.7 WS-6 — Backup/restore safety

1. **Problem / current evidence:** restore rejects `user_version` >8 while current schema is V15 (D.9) — restore is functionally broken for current backups.
2. **Production risk:** users cannot restore a current backup; data-loss perception/incident.
3. **Exact intended behavior:** restore accepts the current schema version and is forward-compatible (pessimistic reject only for genuinely incompatible older-format or newer-than-known); retains integrity/table checks.
4. **Likely source:** `standalone_restore_service.dart`, `database_helper.dart` (version handling), backup/restore tests `test/*backup*`, `test/*restore*`.
5. **Dependencies:** none (independent; do early).
6. **Data/schema implications:** none (behavioral fix in restore validation), maybe version-mapping table.
7. **Offline implications:** none destructive.
8. **Security implications:** restore still authenticated (owner) + integrity-checked.
9. **Test requirements:** backup→restore at V15 round-trip; reject genuinely incompatible versions; corruption→failure test.
10. **Manual verification:** create current backup, restore into fresh install, data intact.
11. **Acceptance criteria:** restore works for current schema; incompatible versions safely rejected; corruption handled without partial apply.
12. **Exclusions:** schema downgrade support.

### F.8 WS-7 — Android release readiness

1. **Problem / current evidence:** release uses debug signing (OD-K2 blocked); package identity `com.almuaman.muaman_store` diverges from productization `com.itech.storemanagement` (D.6).
2. **Production risk:** cannot publish a signed release; package identity mismatch may be a launch blocker.
3. **Exact intended behavior:** resolve (via owner) release signing key/config and final package identity (freeze `com.almuaman.muaman_store` OR approved migration to `com.itech.storemanagement`); configure release build.gradle; verify permissions/storage/import on Android.
4. **Likely source:** `android/app/build.gradle`, key.properties (untracked), `AndroidManifest.xml`, platform code, release docs.
5. **Dependencies:** BLOCKED_OWNER_DECISION (OD-K1 package, OD-K2 signing); WS-8 for pipeline.
6. **Data/schema implications:** none (package identity changes are build config; user-account shop-scoped, not device-scoped — D13).
7. **Offline implications:** none.
8. **Security implications:** signed release; keys never committed.
9. **Test requirements:** Android release build succeeds; install/run smoke test; import/permission tests on device/emulator.
10. **Manual verification:** install signed APK, on/offline flow, import, print/share.
11. **Acceptance criteria:** signed release builds; owner-approved package identity frozen; platform functionality verified.
12. **Exclusions:** renaming frozen desktop/database identifiers (separate boundary).

### F.9 WS-8 — Release/build hardening

1. **Problem / current evidence:** formatting baseline failing (19 files); analyzer clean; Windows pipeline exists; Android release blocked by WS-7; no centralized crash handling; version `1.0.0+1`.
2. **Production risk:** unformatted code/tooling variance; undiagnosed crashes; version mismatch.
3. **Exact intended behavior:** normalize formatting (CI gate) without changing semantics; add builds for both platforms; establish versioning policy; add crash/error handling and logging-without-secrets; confirm leak scan in release.
4. **Likely source:** `analysis_options.yaml`, `tools/release/*`, `installer/muaman.iss`, `pubspec.yaml`, `tool/leak_scan.dart`, runner code.
5. **Dependencies:** WS-7 (Android release); otherwise independent.
6. **Data/schema implications:** none.
7. **Offline implications:** none.
8. **Security implications:** no secret leakage; leak scan enforced.
9. **Test requirements:** formatting gate; release build both platforms; analyzer.
10. **Manual verification:** build Windows+Android installers; version shown correctly.
11. **Acceptance criteria:** formatting gate green; both release builds succeed; versioning consistent; no secrets in artifacts.
12. **Exclusions:** onboarding external crash-reporting SaaS (default POST_P unless owner decides).

### F.10 WS-9 — Business-critical gaps

1. **Problem / current evidence:** missing cost-change warning + "create new item" option; no per-account opening balances; period profit only today/month/all (D.11).
2. **Production risk:** accounting/COGS correctness and owner workflows incomplete vs. stated business-critical requirements.
3. **Exact intended behavior:** warn on purchase-cost change and offer create-new-item; support opening balances per account; support arbitrary-period profit reporting.
4. **Likely source:** `screens/inventory/inventory_screen.dart`, models `product`/`supplier`/`account`, reports screens, DB schema for accounts/ledger.
5. **Dependencies:** none blocking.
6. **Data/schema implications:** new `suppliers`/`accounts`(ledger balance) entities (additive, migration); possible new fields on product history.
7. **Offline implications:** additive local features sync via existing enqueue mechanism (needs WS-1 for cloud durability of new entities).
8. **Security implications:** permission-gated (owner for balances/adjustments).
9. **Test requirements:** cost-change dialog; opening-balance persistence; period-range profit calc.
10. **Manual verification:** change cost → warning + alternate create-new; enter opening balance; run month/quarter report.
11. **Acceptance criteria:** cost-change UX correct; opening balances persist and report correctly; arbitrary-period profit accurate.
12. **Exclusions:** full double-entry accounting (POST_P).

### F.11 WS-10 — Security/supabase final verification (seal)

1. **Problem / current evidence:** strong baseline (D.7); expected edge-function surface is only `invite-employee`; final RLS/migration consistency seal needed.
2. **Production risk:** unnoticed drift in migrations/RLS/edge surface or secret handling.
3. **Exact intended behavior:** final audit confirming RLS coverage across all tables, server-authoritative RBAC, minimal edge surface, no secret leakage, migration consistency, and that no dangerous client-trust assumption was introduced by WS-1…WS-9.
4. **Likely source:** `supabase/migrations/*`, `supabase/functions/*`, `config.toml`, `app/lib/config/*`, `app/lib/services/*`, plus all WS changes.
5. **Dependencies:** runs last, after all other WS.
6. **Data/schema implications:** verification only (may drive re-migration if inconsistency found; additive).
7. **Offline implications:** verify offline enforcement not weakened.
8. **Security implications:** core subject.
9. **Test requirements:** RLS/policy tests, migration replay test, edge function tests, leak scan.
10. **Manual verification:** review migration diff, RLS policies per table, function surface, production config values.
11. **Acceptance criteria:** RLS enforced; RBAC server-authoritative; edge surface minimal+owner-approved; no secrets; migrations consistent with deployed state.
12. **Exclusions:** expanding the edge-function surface beyond owner approval (BLOCKED_OWNER_DECISION if needed).

---

## G. Migration / data considerations
- All schema changes in Phase P are **additive** (new columns/tables; no destructive DDL on existing data), consistent with product principle 7 and the Phase Gate policy (backup + migration test before any schema change).
- Anticipated additive schema increments: `cloud_uuid` backfill (WS-2), Option C adjustment/audit tables (WS-3), subscription/tier/grace fields (WS-4), per-write snapshot (WS-5), accounts/ledger (WS-9). Each requires `PRAGMA user_version` bump + migration test.
- **Critical:** restore service version whitelist must be brought forward with each schema bump (WS-6).
- Frozen DB filename/table identities (`muaman_store.db`, etc.) remain unchanged.

## H. Security considerations
- Preserve server-authoritative model: client cache/permissions are **never** the security authority; every cloud RPC re-authorizes (`require_shop_permission`).
- WS-4 tamper hardening: cached-entitlement integrity (digest/HMAC) and clock-rollback enforcement; do not weaken by introducing client-trusted offline credit.
- No secrets in committed config or artifacts; enforced by leak scan.
- Phase M `SELECT…FOR UPDATE` for inventory serialization (WS-3).

## I. Offline considerations
- Offline remains the default posture; enqueue stays live offline; drain is deferred until connected+licensed+bound.
- Grace semantics corrected to owner spec (paid 7d / trial 0d / perpetual 14d-compat).
- Offline seller sales preserved and hardened (never removed).
- Process-restart recovery: leverage M-I05 recovery sweep on startup (WS-1).

## J. Platform considerations
- Windows + Android parity preserved (D8/D7). WS-7/WS-8 ensure Android release; WS-1 must run on both desktop and Android FFI/plugin DB paths.
- Do NOT rename frozen desktop/database identifiers when handling Android package identity.

## K. Test matrix
- `flutter analyze` must be green (no errors/warnings) at implementation exit.
- `dart format --set-exit-if-changed .` must be green at implementation exit (correct the 19-file baseline as part of WS-8; not during planning).
- `flutter test` must be **all passing** at Phase P implementation exit — including the 3 currently-failing tests, which are classified for Phase P resolution:
  - 2 shop-profile widget-test failures → resolve as part of WS-8/UI verification (they are UI-layout test breakages, not production correctness, but must be green to satisfy the Phase Gate).
  - 1 crash-recovery "window G" failure → resolve as part of WS-1 (queue cleanup contract).
- Existing sync/conflict/idempotency/crash/licensing/migration suites are the regression net and must remain green as they are activated into the runtime.

## L. Manual verification matrix
| WS | Manual check |
|----|--------------|
| WS-1 | online drain after create; offline→online drain; process-restart recovery |
| WS-2 | reinstall/multi-device dedup; conflict→audit |
| WS-3 | offline oversell → negative + adjustment + audit on server |
| WS-4 | trial→paid; tier cap blocked; revocation; offline grace bounds; cold-start offline |
| WS-5 | seller offline sale reaches server; revoked seller adjudicated; status visible |
| WS-6 | current backup→restore round-trip; incompatible rejected |
| WS-7 | signed Android release installs + platform smoke |
| WS-8 | Windows + Android release builds; version; leak scan |
| WS-9 | cost-change warning/create-new; opening balances; period profit |
| WS-10 | RLS/RBAC/edge/secret/migration audit |

## M. Acceptance criteria (Phase P completion definition)
1. The runtime constructs and starts a sync drain owned by the application (WS-1) — the foundational never-sync risk is closed.
2. New offline entities carry stable cloud identity; idempotency and conflict audit durable (WS-2).
3. Option C durability is runtime-wired with durable adjustment + audit; server stock serialized (WS-3).
4. Owner-approved commercial model (subscription + tiers + grace + revocation) is enforced server-authoritatively; tamper checks active (WS-4).
5. Offline seller sales are hardened, visible, and reliably synchronized; revoked-seller adjudication correct (WS-5).
6. Backup→restore works at current schema and is forward-compatible (WS-6).
7. Android release signing + package identity resolved and frozen by owner decision (WS-7).
8. Release/build pipeline green for both platforms; formatting and analyzer gates green; no secret leakage (WS-8).
9. Business-critical gaps (cost-change UX, opening balances, period profit) implemented (WS-9).
10. Security/supabase seal passed (WS-10).
11. `flutter analyze` 0 errors/0 warnings; `dart format` green; **all `flutter test` passing**.
12. Frozen identifiers unchanged; no Phase A–O decision reopened.

## N. Rollback / recovery considerations
- Any WS introducing a schema change must first produce a verified backup and a backward-compatible migration test; rollback = restore additive migration.
- The sync-drain wiring (WS-1) must remain disabled for unlicensed / non-cloud / non-bound tenants so that offline-only shops are never harmed.
- WS-4 grace/tamper changes must not hard-lock existing active paid/trial users unexpectedly (test migration + boundary cases before release).
- WS-6 restore fix protects the upgrade path; corruption handling must not partially apply (unchanged semantics, only whitelist fixed).

## O. Implementation-session boundaries
- **This document is PLANNING ONLY.** It does not authorize implementation.
- Phase P implementation is delivered in a separate, explicitly-authorized `PHASE_P_IMPLEMENTATION` session (or a defined sequence of implementation sessions matching prior phase workflow).
- Each implementation slice must preserve the add-only schema policy and the Phase Gate policy (planning→implementation→tests→clean→commit→remote-lock).
- Remote lock / tag (`phase-p-plannning-baseline-locked` / `phase-p-implementation-locked`) is performed by the dedicated remote-lock session following the established workflow.

## P. Explicit Phase P completion definition
Phase P is COMPLETE only when:
1. Every WS-1…WS-10 acceptance criterion in §M is satisfied and verified.
2. `flutter analyze` (0 err/0 warn) and `dart format --set-exit-if-changed .` are green.
3. `flutter test` is fully green (including the 3 pre-existing failures, resolved within WS-1/WS-8).
4. All Phase P migrations are additive, migration-tested, and the restore whitelist is current.
5. Frozen identifiers are unchanged; no Phase A–O decision reopened.
6. Production configuration carries no secrets; release builds are signed and verifiable.
7. The security/supabase seal (WS-10) is passed.
8. Local implementation commit exists and remote lock is complete per governance.

---

## Q. Classification Summary (foundational findings)

| Finding | Classification |
|---------|----------------|
| Sync drain never constructed/started (never-sync risk) | P_REQUIRED (WS-1) |
| Client `cloud_uuid` missing / idempotency instability | P_REQUIRED (WS-2) |
| Option C durability is a dead seam (OD6 open) | P_REQUIRED (WS-3) — owner confirms Option C at implementation |
| Licensing: no subscription/tiers (commercial launch) | P_REQUIRED (WS-4) |
| Licensing: offline grace is 24h, not owner spec | P_REQUIRED (WS-4) |
| Licensing: revocation pull-only latency | P_RECOMMENDED / P_REQUIRED (WS-4, per owner risk tolerance) |
| Licensing: tamper/clock/cache integrity hardening | P_RECOMMENDED (WS-4) |
| Offline seller sales never sync; no status visibility | P_REQUIRED (WS-1/WS-5) |
| Restore rejects current schema V15 (functional bug) | P_REQUIRED (WS-6, highest-severity standalone bug) |
| Android release signing = debug (OD-K2) | BLOCKED_OWNER_DECISION (WS-7) |
| Android package identity divergence | BLOCKED_OWNER_DECISION (WS-7) |
| Cost-change warning + create-new-item | P_REQUIRED (WS-9) |
| Opening balances per account | P_REQUIRED (WS-9) |
| Arbitrary-period profit reporting | P_RECOMMENDED (WS-9) |
| 2 shop-profile widget-test breakages | P_REQUIRED to exit (WS-8) |
| crash-recovery "window G" queue-cleanup failure | P_REQUIRED to exit (WS-1) |
| 19-file formatting baseline | P_REQUIRED to exit (WS-8) |
| Only `invite-employee` edge function | ALREADY_SATISFIED (recorded; owner may extend later) |
| RLS/RBAC/server-authoritative posture | ALREADY_SATISFIED (preserve; WS-10 seals) |
| Excel import / mandatory cost price / atomic sales / invoice-print | ALREADY_SATISFIED (preserve) |
| Payment/billing provider integration | BLOCKED_EXTERNAL / POST_P |
| Play Store / app-store publishing | POST_P |
| Centralized crash-reporting SaaS | POST_P (owner opt-in) |
| Renaming frozen desktop/db identifiers | OUT_OF_SCOPE |
