# PHASE K — ANDROID OWNER FOUNDATION PLAN

**Product:** I Tech Store Management Application
**Institutional owner:** I Tech for Technology / I Tech للتكنولوجيا
**Status:** PLANNING BASELINE (local commit only)
**Predecessor:** Phase J — Windows Cloud Transition (locked)
**Successor:** Phase L — Android Sales/Employee

---

## 0. Governance and Baseline

### 0.1 Repository identity

```text
REPOSITORY_ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
REMOTE            = github https://github.com/sabere342-ai/muaman.worktrees.git
GITHUB_REPOSITORY = sabere342-ai/muaman.worktrees
```

### 0.2 Locked predecessor state (verified at planning time)

```text
PHASE_J_IMPLEMENTATION_COMMIT = df7fe2990b2058ffbaef3907d349ff029b5f2f1c
PHASE_J_PLANNING_COMMIT       = 05ba9084b2d61843d4a3de192c8b38a5088e217f
PHASE_I_IMPLEMENTATION_COMMIT = 986f0dde659233e9868b232996a777ae6b3e5fda
PHASE_J_IMPL_TAG              = phase-j-implementation-locked (annotated -> df7fe29)
PHASE_J_PLAN_TAG              = phase-j-planning-baseline-locked (annotated -> 05ba9084)
PHASE_I_IMPL_TAG              = phase-i-implementation-locked (annotated -> 986f0dde)

ANCESTRY VERIFIED:
986f0dde -> 05ba9084 -> df7fe29 (= HEAD = github/codex/i-tech-next-roadmap-freeze)
```

Remote branch and remote tag `phase-j-implementation-locked` resolved to identical
objects locally and on `github` at planning time.

### 0.3 Planning-only session rule

This phase starts from a planning commit whose parent MUST be
`df7fe2990b2058ffbaef3907d349ff029b5f2f1c`. No push, no tags, no deployment during
the planning session.

### 0.4 Preserved artifacts (outside Git — absolute protection)

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
```

SHA-256 recorded read-only at planning time:

```text
report : 3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07
zip    : 70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
```

They remain UNTRACKED/UNSTAGED/UNMODIFIED. `git add .`, `git add -A`,
`git clean -fd/-fx`, `git stash -u` are FORBIDDEN for the entire phase.

### 0.5 Known pre-existing test failures

Locked Phase J closure baseline: **1186 PASS / 7 FAIL**, failures proven pre-existing
at the Phase J planning baseline (`Supabase.instance` accessed by CloudLicensingService
while Supabase is uninitialized in widget tests).

Rules for Phase K:

- These seven are NOT regressions of Phase K and NOT free wins.
- Any correction requires explicit scope justification inside the Phase K work
  breakdown; incidental fixes outside declared scope are forbidden.
- If the same seven reproduce identically during Phase K verification, classify them
  against this frozen baseline, not against Phase K.

---

## 1. Canonical Phase Definition

### 1.1 Phase identity

```text
NEXT_PHASE_ID    = PHASE_K
CANONICAL_NAME   = Android Owner Foundation
GOVERNING_SOURCE_A = PROJECT_MASTER_PLAN.md section 13 "Phase Roadmap Overview",
                     line 220: "| K | Android Owner Foundation | Android owner
                     onboarding, shop setup, login |"
GOVERNING_SOURCE_B = PRODUCTIZATION_ARCHITECTURE_PLAN.md section 13 "Android Strategy",
                     lines 659–694 ("Owner Full Capability (Phase K)")
CORROBORATION    = PHASE_G_CLOUD_DATA_FOUNDATION_PLAN.md roadmap table row 8
                   ("Android implementation | Phase K/L");
                   PHASE_H_OFFLINE_SYNC_CORE_PLAN.md line 280 ("Android owner
                   foundation | Phase K ... creates Android onboarding");
                   PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md line 232 ("Android is
                   Phase K");
                   PHASE_J_WINDOWS_CLOUD_TRANSITION_PLAN.md line 117 (explicit
                   non-goal: "Android onboarding (K)")
PREDECESSOR      = Phase J — Windows Cloud Transition
SUCCESSOR        = Phase L — Android Sales/Employee (seller login, products, sales,
                   returns)
DEPENDENCY_CHAIN = A -> B -> C -> D -> E -> F -> G -> H -> I -> J -> K -> L
                   (PROJECT_MASTER_PLAN.md section 13)
```

Governing-document hierarchy (PROJECT_MASTER_PLAN.md section 18) makes
PROJECT_MASTER_PLAN.md the top authority. MASTER_PLAN's one-line objective (owner
onboarding, shop setup, login) is the entry surface; ARCHITECTURE_PLAN section 13
defines the terminal capability bar ("Owner Full Capability"). The documents agree;
no governing-plan conflict exists.

### 1.2 Canonical scope

Phase K makes the existing Flutter codebase run correctly on Android for the shop
owner: first-run onboarding (cloud account + shop creation), cloud/local login,
active-shop binding, dashboard/reports, products/inventory, expenses, returns, shop
settings, users/roles/permissions management — full admin capability — while Windows
remains untouched as primary platform.

Frozen technical anchors (ARCHITECTURE_PLAN section 13):

| Item | Value |
|---|---|
| Min SDK | 21 |
| Target SDK | 34 |
| Codebase | Same Flutter codebase, responsive layout |
| Local storage | SQLite, same schema (sqflite) |
| Camera barcode | Phase L+ (NOT in K) |
| PDF delivery | Share intent / print service |

### 1.3 Objective

Deliver an installable Android build in which a shop owner can complete first-run
setup, sign in, and operate the shop against the Phase C–J Supabase backend with
correct tenant isolation, licensing enforcement, and offline-first behavior — without
regressing Windows.

### 1.4 Explicit non-goals

- Employee/seller experience and seller-first UX (Phase L).
- Camera barcode scanning (Phase L+).
- Cross-platform Excel import via SAF DocumentPicker (Phase N per MASTER_PLAN section 13
  and ARCHITECTURE_PLAN section 14). Workbook import is NOT required on Android in K.
- Inventory conflict hardening (M), invoice branding/delivery rework (O),
  production hardening (P).
- Play Store publication and subscription billing (separate commercial workstream).
- Windows installer / BINARY_NAME / AppId changes (frozen, PROJECT_MASTER_PLAN section 12).
- Redesign of Phase J architecture: ActiveShopContext, TenantIsolationGate,
  shop-aware queries, hydration/incremental-sync semantics.

---

## 2. Current-State Forensics

All paths relative to repo root; app code under `app/`.

### 2.1 Bootstrap and runtime flow today

Single entrypoint `app/lib/main.dart`, no platform entry variants:

1. `main()` (main.dart:33–57): FFI sqflite init gated on desktop platforms (:35–40 —
   Android falls through to stock sqflite, which is correct); conditional
   `Supabase.initialize` from dart-defines (:45–54).
2. `MyApp` (:66–148): RTL Arabic MaterialApp (`ar_EG`, bundled Noto Sans Arabic fonts).
3. `AuthGate._initialize()` (:170–228): DatabaseHelper open -> AppSettings defaults ->
   PermissionResolver.refresh -> ShopProfileService.load -> CloudLicensingService
   initialize + enforcer wiring (:179–182) -> sync shop-id provider wiring (:188–189) ->
   `ActiveShopContext.configure(membershipValidator)` fail-closed (:194–203) ->
   cloud-session restore check (:209–219) -> `_userRepo.hasAnyUser()`.
4. Routing (:258–299): FirstOwnerSetupScreen -> LoginScreen -> SalesOnlyShell /
   FullAppShell (bottom navigation shell, main.dart:485–497).

Owner onboarding exists today and is platform-neutral:
`screens/auth/first_owner_setup_screen.dart` creates the local owner and, when
Supabase is configured and an email is provided, calls `IdentityLinker.onboardFreshOwner`
(`lib/services/identity_linker.dart:162–210`) performing cloud signUp ->
`create_shop_with_owner` RPC -> identity link, then trial start + device
registration/activation via CloudLicensingService.

Login: `screens/auth/login_screen.dart:106–169` performs local auth then optional cloud
session: `resolveActiveShop()` -> `ActiveShopContext.bind(shopId)` (:125) -> CloudSession
-> `TenantIsolationGate().restoreAtStartup` (:137–141) -> licensing device
register/activate (:147–154) -> `PermissionSyncService.syncPermissions` (:157–160);
all failures degrade silently to offline mode.

### 2.2 Android platform folder status

`app/android/` is the STOCK Flutter template:

- Manifest label `"muaman_store"` (AndroidManifest.xml:3); **no permissions declared —
  no INTERNET permission**.
- Stock Kotlin `MainActivity` under package `com.almuaman.muaman_store`.
- applicationId/namespace `com.almuaman.muaman_store`
  (`android/app/build.gradle`:9,24) with TODOs at :23 (unique application id) and
  :35–36 (release signed with debug keys).
- AGP 8.1.0 / Kotlin 1.8.22 / Java 1.8 compat (`android/settings.gradle`:21–22).

### 2.3 Platform coupling inventory

- `main.dart:35–40` FFI gate — safe for Android unchanged.
- `lib/licensing/device_identity.dart:97,120,142` — all hardware-ID probes return an
  `"UNAVAILABLE"` sentinel off-Windows: Android fingerprints would COLLIDE across devices.
- `lib/licensing/cloud_licensing_service.dart:492–495` — `_detectPlatform()` hardcodes
  `'windows'` (comment explicitly notes Android needs detection work); `_getDeviceName()`
  returns constant `'Desktop'` (:497–503). Server-side `register_device` ALREADY accepts
  platform `'windows'|'android'` (supabase migration `..._phase_e_licensing_enhancements.sql`
  L196–198; `devices` CHECK, migration `20260820000004_create_devices.sql` L14).
- `lib/licensing/secure_store.dart:30,240,256` — DPAPI gated on Windows; non-Windows
  fallback is XOR obfuscation marked "NOT secure — development/testing only" (:239–244).
- Desktop path heuristics: workbook default discovery walks `Directory.current` parents
  and exe dir (`lib/services/app_settings.dart:208–242`); activation files under
  `%LOCALAPPDATA%` (`secure_store.dart:26–44`).
- Filesystem-touching features: backup via `FilePicker.getDirectoryPath` +
  `VACUUM INTO` (settings_screen.dart:1171–1172; standalone_backup_service.dart:46–59);
  restore by raw db-file copy (standalone_restore_service.dart:159–193); clean-start
  snapshot export (clean_start_service.dart:155–176); logo file copy
  (shop_profile_service.dart:60,118–128); PDF save via `FilePicker.saveFile`
  (invoice_delivery.dart:42–50). Printing/PDF share via `printing` works on Android
  (invoice_delivery.dart:26–31,57; thermal_delivery.dart:26–30).
- No `path_provider` direct dependency; no `flutter_secure_storage`; no window manager
  package (window sizing native-only, windows/runner/main.cpp:28–30).
- No responsive breakpoint framework; navigation is already bottom-nav; RTL enforced.

### 2.4 Runtime wiring findings (verified, not assumed)

- `ShopSelectorScreen` (`screens/settings/shop_selector_screen.dart`) is DEAD CODE in
  production paths — imported nowhere else in lib/. Multi-shop resolution auto-selects
  single/last-used/first ACTIVE membership (`shop_resolver.dart:44–76`).
- `SyncEngine`, `SyncWorker`, `HydrationService`, `IncrementalSyncService` are fully
  implemented under `lib/sync/` but are NOT constructed anywhere in production code
  (constructor references exist only inside lib/sync plus comments). sync_queue fills
  via enqueue-after-write hooks; nothing drains it in this freeze build. Phase J
  operates cloud-first through SECURITY DEFINER CRUD RPCs.
- `TenantIsolationGate.restoreAtStartup` fires only from LoginScreen post-cloud-login,
  not on cold start with a restored Supabase session (main.dart:209–219 checks the
  session without re-binding ActiveShopContext). Gap matters more on Android where
  process death/restart is frequent.
- `CleanStartService` / `StandaloneRestoreService` reachable only from Settings UI
  (settings_screen.dart:1350,1566–1569).
- `AcceptInvitationScreen` / `InviteEmployeeScreen` exist but unwired — employee
  invitation UX belongs to Phase L; RPCs exist since Phase D.

### 2.5 Local database state

- Schema version **14** (`database_helper.dart:371`). v14 = Phase I additive
  `legacy_migration_progress` (:686–713). Nothing bumped after Phase I.
- All tenant-owned tables carry additive `shop_id TEXT` + `cloud_uuid TEXT` (v9) and
  v13 sync columns (`server_version INTEGER DEFAULT 0`, `sync_status TEXT DEFAULT 'SYNCED'`,
  `last_synced_at TEXT`) plus `sync_queue` (`idempotency_key UNIQUE`, indexed shop_id).
- No local soft-delete columns; deletes are hard locally, soft in cloud payloads.
- Known parity defect: production `_createDB` (:374–461) does not create v13 artifacts
  (`sync_queue`, sync columns); tests compensate via `runCreateDbForTest` seam (:331–336)
  replaying `_migrateToV13`+`_migrateToV14`. Fresh production installs take onCreate.
  See W1 (section 11).

### 2.6 Cloud state

Latest migration: `20260820000027_phase_i_legacy_migration.sql`.

Everything Phase K needs server-side ALREADY exists:

- `devices.platform CHECK IN ('windows','android')`; `register_device` upserts on
  `(installation_id, shop_id)` accepting `'android'`.
- `licenses` / `activations` with max_devices enforcement (`activate_device`),
  `deactivate_device`, `get_device_list`.
- `create_shop_with_owner`, `get_user_shops`, `verify_shop_membership`, `start_trial`,
  `verify_trial_status`.
- RBAC: `get_effective_permissions`, `check_effective_permission`,
  `require_shop_permission` (license-gated writes), `sync_user_permissions`,
  `shop_permission_overrides`, `permission_audit_log`.
- Nine `cloud_*` data tables: RLS ENABLED with SELECT-only active-membership policies,
  soft-delete `deleted_at`, `server_version`, shop-scoped indexes; direct table access
  REVOKEd from authenticated; all mutations through SECURITY DEFINER RPCs.
- Sync layer: `sync_log` idempotency, version-conflict verdicts, `sync_upsert_entity`.
- Migration ledger (`cloud_migration_ledger`) for Phase I adoption.

No new cloud migration is REQUIRED by canonical Phase K scope. If implementation proves
one unavoidable, it must be justified as an explicit deviation in the implementation
report.

### 2.7 Test state

- `flutter analyze` executed in this planning session: **0 errors, 0 warnings, 50
  infos** (style-level lints only).
- Historical locked baseline: 1186 PASS / 7 pre-existing FAIL (section 0.5). The full
  suite was NOT re-executed in this planning session; last proven numbers stand.
- 81 test files under `app/test/` (cloud, database, licensing, migration, rbac, sync,
  tenant_isolation, widget, ...) using sqflite_common_ffi harness; several
  Windows-release-provenance guard tests are host/build-specific and irrelevant to
  Android runtime behavior.

---

## 3. Gap Analysis

| # | Requirement | Current state | Gap | Implementation needed | Test evidence needed |
|---|---|---|---|---|---|
| GA1 | Installable Android build | Stock template; no INTERNET permission; debug signing; unbranded label | Not runnable against Supabase | Manifest INTERNET permission; minSdk 21 / targetSdk 34; label + applicationId handling per OD-K1; signing story per OD-K2 | `flutter build apk --debug` succeeds; boot smoke |
| GA2 | Owner first-run onboarding | FirstOwnerSetupScreen + IdentityLinker.onboardFreshOwner implemented, platform-neutral | Reachability/layout on small screens only | Verify-only reuse; adaptive layout if needed | Widget test of setup screen; emulator integration evidence |
| GA3 | Owner login + shop binding on cold start | LoginScreen binds ActiveShopContext post-login only | Restored cloud session never re-binds shop (main.dart:209–219) | Bind ActiveShopContext + arm TenantIsolationGate on restored session at AuthGate init | Unit/widget test: cold start with stored session -> shop bound, isolation armed |
| GA4 | Licensing device identity on Android | Sentinel fingerprints collide across devices | Real Android identity missing | Android device fingerprint via platform channel (e.g., SSAID) in device_identity.dart with injected abstraction; Windows path byte-identical | Unit tests with injected identity; collision test (two devices -> distinct ids) |
| GA5 | Licensing platform reporting | `_detectPlatform()` hardcodes 'windows' | Server sees Android device as windows | Report `'android'` when running on Android; server already accepts it | Unit test for platform detection mapping; register_device payload assertion |
| GA6 | Secure local licensing/secret storage on Android | XOR fallback marked insecure | No Keystore-backed storage | Introduce secure storage abstraction; Android implementation backed by Keystore (flutter_secure_storage or platform channel); keep Windows DPAPI path unchanged | Unit tests via abstraction; no plaintext secret assertions |
| GA7 | Cloud CRUD from Android | SECURITY DEFINER RPCs platform-agnostic; supabase_flutter works on Android | None functional | Verify-only; ensure AppConfig dart-define provisioning documented for Android builds | Existing cloud service tests; emulator login evidence |
| GA8 | RBAC permission sync on owner device | PermissionSyncService wired post-login | Same cold-start gap as GA3 | Sync permissions on restored-session path too | Test: restored session -> effective permissions refreshed |
| GA9 | Tenant isolation on Android | Shop-scoped queries enforced locally (Phase J) + RLS server-side | None beyond GA3 binding gap | Verify-only; add regression tests that isolation predicates are active regardless of platform | Tenant-isolation suite green; new cold-start isolation test |
| GA10 | Offline-first operation | Local SQLite remains operational cache; writes queue to sync_queue | sync_queue never drains in production build (no SyncEngine wiring) — pre-existing Phase J freeze behavior, not an Android defect | OUT OF SCOPE unless required: wiring the sync runtime is a Phase J architecture seam; any activation must be justified and tested cross-platform. Record as RISK R4 | If activated: sync engine tests incl. offline/online transitions |
| GA11 | Responsive layout for phones | Fixed bottom-nav shell; RTL everywhere; no breakpoints; some screens assume wide layout | Owner screens must be usable on phone-sized displays | Add responsive adjustments where screens overflow; no navigation redesign | Widget tests at phone viewport sizes |
| GA12 | Filesystem features on Android (backup/restore/clean-start/logo/PDF save) | Desktop file-picker semantics; raw db-file overwrite restore; `%LOCALAPPDATA%` paths | Scoped-storage incompatibilities | Minimum viable: logo copy into app-documents dir via path_provider; PDF save -> share/print path; backup/restore/clean-start either adapted to app-scoped dirs OR feature-flagged unavailable-on-Android with explicit UI message (no silent breakage). Full SAF import stays Phase N | Unit tests for path resolution; UI-state tests for flagged features |
| GA13 | Arabic RTL + fonts | Already forced RTL with bundled fonts | None expected | Verify-only on Android | Emulator screenshot evidence |
| GA14 | Windows non-regression | Windows is primary platform | Risk of regression from shared-code changes | All shared changes must be platform-abstraction gated with default = current behavior | Full existing suite must match locked baseline |

---

## 4. Frozen Design Decisions

Each decision: decision / reason / affected files / invariants protected / alternatives rejected.

### D1 — Single Flutter codebase, additive Android target
Decision: enable Android inside `app/` with platform abstractions; no fork of lib/.
Reason: ARCHITECTURE_PLAN section 13 freezes "same Flutter codebase with responsive layout".
Affected: android/ manifest+gradle, new platform service abstractions.
Invariants: all frozen identifiers (PROJECT_MASTER_PLAN section 12); existing behavior defaults preserved.
Rejected: separate Android app/repository; KMP rewrite.

### D2 — No local schema version bump in Phase K
Decision: schema v14 stands unless a concrete Phase K change requires new columns/tables.
Reason: canonical scope needs no structural change; all tenant/sync/licensing structures exist.
Affected: database_helper.dart.
Invariants: create-vs-upgrade parity rule (test/sync/schema_v14_test.dart:104–117).
Rejected: speculative v15.

### D3 — W1 create-vs-upgrade parity fix is IN SCOPE (bounded)
Decision: make production onCreate produce the same v14 shape as upgrade (create
`sync_queue` and sync columns in `_createDB`), covered by a fresh-install parity test.
Reason: Android ships as FRESH INSTALLS taking onCreate; shipping Android without
sync_queue would diverge fresh vs upgrade installs and break enqueue-after-write hooks.
Affected: database_helper.dart (_createDB), new parity test.
Invariants: v13/v14 migration ladder untouched; upgrade path byte-compatible.
Rejected: leaving the gap ("tests pass anyway") — unacceptable for Android fresh installs;
bumping version instead.

### D4 — Cold-start session restore binds shop context (GA3)
Decision: when AuthGate finds a valid restored Supabase session, resolve active shop,
bind ActiveShopContext, arm TenantIsolationGate, and sync permissions — same sequence
as LoginScreen.
Reason: Android process death makes cold-start-with-session the COMMON case; without
binding, tenant predicates stay disarmed.
Affected: main.dart (AuthGate), possibly extracted shared "cloud session resume" helper reused by LoginScreen.
Invariants: fail-closed membership validation; no auto-login without verified session; LoginScreen behavior unchanged.
Rejected: forcing users through LoginScreen every process death (UX-hostile, no governing basis).

### D5 — Android device identity via platform channel behind abstraction
Decision: introduce injectable DeviceIdentityProvider; Windows keeps reg.exe/wmic
pipeline; Android returns SSAID-based fingerprint; sentinel retained only as last resort.
Reason: register_device upserts on (installation_id, shop_id); colliding fingerprints
corrupt device/activation bookkeeping.
Affected: lib/licensing/device_identity.dart, android platform channel, cloud_licensing_service.dart injection point.
Invariants: server contract unchanged; Windows fingerprint algorithm byte-identical.
Rejected: random UUID per install (loses reinstall stability expectations set by Windows model); ANDROID_ID read without channel.

### D6 — Platform reporting becomes truthful ('android')
Decision: _detectPlatform() returns actual platform; device name from Android device info.
Affected: cloud_licensing_service.dart:492–503.
Invariants: server CHECK accepts 'windows'|'android' only; audit rows remain accurate.
Rejected: continuing to report 'windows'.

### D7 — Secure storage abstraction for licensing secrets
Decision: interface-first secure store; Windows = existing DPAPI files; Android =
Keystore-backed storage. The insecure XOR fallback may remain only for test profiles.
Affected: lib/licensing/secure_store.dart, new Android implementation.
Invariants: no plaintext secrets at rest; Windows behavior unchanged.
Rejected: reusing XOR fallback on production Android (explicitly insecure).

### D8 — Scoped-storage policy: adapt minimum, flag the rest
Decision: on Android, features requiring arbitrary filesystem access behave explicitly:
logo -> app documents directory (path_provider); PDF delivery -> print/share;
backup/restore/clean-start -> app-scoped directories or clearly disabled with
explanatory UI; workbook import button hidden/disabled on Android (Phase N).
No silent failures.
Affected: settings_screen.dart, standalone_backup_service.dart,
standalone_restore_service.dart, clean_start_service.dart, shop_profile_service.dart,
invoice_delivery.dart, app_settings.dart.
Invariants: Windows flows unchanged; no data loss paths introduced; user always informed.
Rejected: pulling full SAF document-tree plumbing into K (Phase N territory).

### D9 — Sync runtime NOT activated in Phase K
Decision: do not wire SyncEngine/SyncWorker/HydrationService into production startup.
Reason: this is a Phase J freeze-behavior seam, platform-independent; activating it is
a cross-platform architectural change, not Android foundation work. Recorded as RISK R4
and OWNER/ARCHITECTURE follow-up.
Affected: none (verify-only).
Invariants: no echo loops, idempotency guarantees preserved by NOT half-wiring.
Rejected: opportunistic activation during K.

### D10 — Onboarding reuses FirstOwnerSetupScreen/IdentityLinker unchanged functionally
Decision: reuse existing flow; only presentation-level adaptation allowed.
Reason: it already performs signUp -> create_shop_with_owner -> trial -> device registration.
Affected: possibly layout-only tweaks.
Invariants: RPC sequence order preserved; local owner creation guard intact.
Rejected: building a parallel Android onboarding wizard.

### D11 — minSdk 21 / targetSdk 34 frozen per ARCHITECTURE_PLAN
Affected: android/app/build.gradle.
Rejected: raising minSdk above 21 without owner decision on supported devices.

---

## 5. Data Model

### Local (SQLite)

- Version stays **14** (D2).
- W1 (D3): onCreate gains v13 artifact creation so fresh == upgraded:
  - tables/columns affected: `sync_queue`; `server_version`, `sync_status`,
    `last_synced_at` on the 12 tenant-owned tables.
- No changes to keys, constraints, indices, soft-delete model (none locally),
  cloud_uuid semantics (local UUID v4 written at insert), or shop_id semantics
  (assigned from ActiveShopContext / legacy adoption).
- Backup compatibility: v7/v8 legacy restore replays upgrades to v14 unchanged;
  StandaloneRestoreService behavior NOT modified in K beyond scoped-storage flagging (D8).

### Cloud (Supabase)

- No migration required (section 2.6). Tables consumed: shops, shop_members, roles,
  role_permissions_cloud, devices, licenses, activations, invitations (read-side later L),
  cloud_* data tables, sync_log, permission tables, migration ledger.
- shop_id remains THE tenant boundary; RLS SELECT-only policies plus SECURITY DEFINER
  write RPCs remain the authoritative enforcement. Client never relies on its own
  filtering for server safety.

---

## 6. Tenant Isolation

- Shop-scoped reads/writes: unchanged Phase J local predicates; every tenant-owned
  query executes under the active shop_id.
- Cold-start protection (D4): restored-session startup MUST bind ActiveShopContext and
  arm TenantIsolationGate BEFORE any tenant-owned data is rendered; if shop resolution
  fails, fail closed (no data access), matching `ActiveShopContext.configure` semantics.
- Cross-shop protection: membership validator remains authoritative for what the user
  may bind; RLS + SECURITY DEFINER RPCs enforce server-side regardless of client state.
- Sync isolation: sync_queue entries carry persisted entry.shop_id; queue execution (when
  it exists) runs under entry's shop, never ambient context — existing invariant,
  regression-tested.
- Restore/import isolation: legacy restore resets to pre-migration arming behavior per
  Phase J section P policy; unchanged in K.
- Tests: existing tenant_isolation suite must stay green; new cold-start binding test
  (GA3) asserts isolation armed without LoginScreen traversal.

## 7. Runtime Flow (end-to-end after Phase K)

```text
Android cold start
  -> main(): stock sqflite factory on Android; Supabase.initialize via dart-defines
  -> AuthGate._initialize():
       open DB v14 (fresh installs now include sync_queue/sync columns via W1)
       defaults -> permission resolver -> shop profile load
       CloudLicensingService.initialize(enforcer wired)
       ActiveShopContext.configure(membershipValidator) [fail-closed]
       IF valid restored Supabase session:
           resolveActiveShop -> ActiveShopContext.bind(shopId)
           TenantIsolationGate.restoreAtStartup
           PermissionSyncService.syncPermissions
           licensing device register/activate (platform 'android', SSAID fingerprint)
       hasAnyUser?
  -> FirstOwnerSetupScreen (first run):
       create owner -> IdentityLinker.onboardFreshOwner
         (signUp -> create_shop_with_owner -> link)
       start_trial -> register_device('android') -> activate_device
  -> LoginScreen (subsequent): local auth + optional cloud session as today
  -> FullAppShell: dashboard/reports/products/inventory/expenses/returns/settings
       all writes license-enforced, tenant-scoped, cloud-first via RPCs;
       offline-first: local cache serves reads; queued writes persist in sync_queue
```

Windows flow is IDENTICAL to the locked Phase J behavior at every step.

## 8. Failure / Recovery Semantics

| Condition | Behavior |
|---|---|
| Offline at boot | App boots from local SQLite; offline-first reads; cloud features degrade silently (existing pattern); queued writes remain PENDING |
| Network loss mid-operation | RPC failure handled by existing service error paths; local write already durable; no partial cloud state due to idempotency_key design |
| Auth expiry | Existing session-expiry checks skip cloud paths gracefully (LoginScreen pattern); D4 resume path must treat expired sessions exactly like absent sessions |
| License failure / trial expiry | enforcer hook blocks business writes as today; UI banner reflects server-computed state; Android-specific failures (identity/activation) surface through same states enum |
| RLS denial / RPC error | Treated as cloud unavailability by client; server remains authoritative; no client-side bypass attempted |
| Sync failure | No production sync loop (D9); queue grows locally; retry_count/status columns intact |
| Duplicate operation | Idempotency keys prevent double application when sync/cloud replays occur |
| App restart / process death (Android-common) | D4 guarantees shop context and isolation re-arm before data screens |
| Crash during onboarding | FirstOwnerSetupScreen guard ("users exist") prevents duplicate owners; cloud signUp retry path follows existing IdentityLinker handling |

## 9. Security

- Authentication: Supabase Auth password sign-in; local users unchanged; identity link
  model untouched.
- Authorization/RBAC: server-side effective permissions remain authoritative;
  PermissionSyncService refresh included in D4 resume path.
- RLS: SELECT-only membership policies + SECURITY DEFINER writes; direct table grants
  revoked; K adds NO new grant, policy, or definer function.
- Tenant boundary: shop_id everywhere; active shop context explicit and fail-closed.
- Sensitive local state: licensing secrets move to Keystore-backed storage on Android
  (D7); no plaintext secrets at rest on any platform.
- Server trust boundary: client never receives service_role material; anon key only.
- Android hardening minimums: INTERNET permission only (no extra dangerous permissions
  in K); release signing decision tracked as OD-K2.

## 10. Migration / Compatibility

- Existing Windows installs: unaffected; upgrade path byte-compatible (D2/D3); installer
  frozen identifiers untouched.
- Fresh Windows installs: now receive full v14 shape via onCreate (W1 fix) — this CLOSES
  a latent divergence rather than introducing one.
- Upgrade installs: ladder <9 -> <13 -> <14 preserved; parity test proves
  fresh == upgraded shape.
- Backup restore: v7/v8 legacy acceptance and replay-to-v14 unchanged; restore attribution
  policy (Phase J section P) unchanged.
- Mixed-version compatibility: cloud schema unchanged; old Windows clients and new
  Android clients share identical RPC contracts.
- Rollback limitations: W1 touches only onCreate path; rollback = revert commit; no data
  migration to undo. Android distribution artifacts are additive.

## 11. Implementation Work Breakdown

### CREATE

- `app/lib/platform/device_identity_provider.dart` (abstraction; Windows impl wraps
  existing probes; Android impl via platform channel).
- Android platform channel code: `app/android/app/src/main/kotlin/.../DeviceIdentityPlugin.kt`
  (or equivalent MethodChannel handler inside MainActivity) + Dart side wiring.
- `app/lib/licensing/secure_store_android.dart` or equivalent Keystore-backed
  implementation behind existing secure-store interface.
- Parity test: `app/test/database/schema_v14_fresh_parity_test.dart` (fresh onCreate ==
  upgraded shape).
- Cold-start resume tests: `app/test/cloud/session_resume_binding_test.dart` (+ widget
  variant as needed).
- Platform-detection unit tests: `app/test/licensing/platform_reporting_test.dart`.
- Scoped-storage flagging widget tests (backup/restore/clean-start/import disabled-or-
  adapted states).

### MODIFY

- `app/android/app/src/main/AndroidManifest.xml` — INTERNET permission; label handling
  pending OD-K1.
- `app/android/app/build.gradle` — minSdk 21, targetSdk 34; signing config pending OD-K2;
  applicationId pending OD-K1 (placeholder retained until decided).
- `app/lib/main.dart` — D4 cold-start resume sequence in AuthGate.
- `app/lib/licensing/device_identity.dart` — delegate to provider abstraction.
- `app/lib/licensing/cloud_licensing_service.dart` — truthful platform detection (D6),
  injectable identity provider (D5).
- `app/lib/database/database_helper.dart` — `_createDB` creates v13 artifacts (W1/D3).
- `app/lib/services/shop_profile_service.dart` + logo loading — app-documents logo dir on
  Android via path_provider (add dependency).
- `app/lib/invoices/invoice_delivery.dart` — Android save -> share/print route.
- Settings surfaces (`settings_screen.dart`, services listed in D8) — scoped-storage
  behavior/flagging.
- `app/pubspec.yaml` — add path_provider (and secure-storage mechanism chosen in D7);
  nothing else without justification.

### VERIFY ONLY

- FirstOwnerSetupScreen / IdentityLinker flows on phone layout.
- LoginScreen sequence (unchanged).
- ShopResolver multi-shop resolution rules.
- Supabase migrations (no changes).
- Tenant-isolation suite, RBAC suite, licensing suite, migration suite.
- Windows build pipeline (release provenance guard tests).

---

## 12. Test Strategy

- Unit: platform detection mapping; device identity provider (both platforms, injected);
  secure store abstraction; W1 parity logic.
- Database/migration: schema_v14_fresh_parity_test proving fresh == upgraded; full
  existing database suite green.
- Tenant isolation: existing suite + cold-start armed-isolation regression.
- Integration/widget: AuthGate routing matrix (fresh/restored-session/expired/no-users);
  settings feature-flag states on Android profile.
- Cloud SQL/RLS: no changes required; existing cloud tests green.
- Regression: full `flutter test` compared against locked baseline (1186/7) — identical
  seven failures allowed ONLY if they match the frozen classification.
- Static: `flutter analyze` 0 errors / 0 warnings.
- Build gates: `flutter build apk --debug` succeeds; Windows build unaffected.
- Emulator evidence (manual, recorded in implementation report): onboarding -> login ->
  dashboard -> product CRUD -> sale write blocked/enabled by license state.

## 13. Acceptance Gates

Machine-verifiable unless marked MANUAL:

1. `flutter analyze`: 0 errors, 0 warnings (infos tolerated within baseline character).
2. `flutter test`: zero NEW failures vs locked baseline; the seven known failures, if
   present, match classification section 0.5 exactly.
3. New parity test passes (fresh == upgraded v14 shape).
4. Cold-start resume test passes (shop bound, isolation armed, permissions synced).
5. Device-identity collision test passes (distinct fingerprints per simulated device).
6. `flutter build apk --debug` succeeds with INTERNET permission present.
7. `git diff --check` clean; commit contains only authorized files.
8. Windows target untouched semantically: existing suites green (gate 2 covers).
9. MANUAL: emulator walkthrough evidence captured in implementation report.
10. No new Supabase migration in the diff (or explicitly justified deviation).

## 14. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Shared-code changes regress Windows | HIGH | abstraction-first design; default = current behavior; full-suite gate 2 |
| R2 | Keystore/secure-storage integration complexity | MEDIUM | interface-first (D7) allows staged rollout; XOR fallback confined to test profiles |
| R3 | Device fingerprint edge cases (SSAID availability/restrictions) | MEDIUM | sentinel last-resort + server max_devices bounds damage; documented behavior |
| R4 | sync_queue grows undrained on long-lived Android installs | MEDIUM | pre-existing freeze behavior (D9); monitor; activation is separate architectural decision |
| R5 | Scoped-storage surprises on OEMs | LOW-MEDIUM | D8 flags rather than fakes capability; no silent breakage |
| R6 | OD-K1/K2 undecided at implementation time | LOW | placeholder package/signing retained; gates defined so decisions slot in without refactor |
| R7 | Responsive regressions on tablets/large phones | LOW | verify-only presentation tweaks; no navigation redesign |

## 15. Owner Decisions

- OD-K1 (carries PRE_A OD1 forward): final Android applicationId and display label
  (recommendation on record: `com.itech.store`). Placeholder `com.almuaman.muaman_store`
  remains until decided. NOT blocking implementation start; blocks release distribution.
- OD-K2: Android release signing ownership (keystore custody). Debug-signed debug builds
  acceptable for development; release distribution requires this decision.
- Carried context (not blocking, previously flagged): products.barcode global-vs-per-shop
  uniqueness (Phase J plan section Z) — schema-level decision remains open; Phase K does
  not change it.
- Multi-shop commercial entitlement per owner account: governed by existing membership
  model; no new commercial terms introduced by K.

None of the above blocks planning approval; all have defined placeholders/fallbacks.

## 16. Implementation Session Contract

The Phase K implementation agent MAY:

- Create/modify exactly the files in section 11 plus tests, plus narrowly-scoped
  additional files required by compiler/test evidence (each justified in report).
- Add dependencies limited to path_provider and the chosen secure-storage mechanism.
- Touch android/ configuration per OD-K1/K2 placeholders.

MUST NOT:

- Modify Supabase migrations, RLS, or RPCs without an approved deviation record.
- Bump local schema version beyond 14.
- Wire SyncEngine/SyncWorker/HydrationService into production (D9).
- Alter Phase J architecture semantics (ActiveShopContext, TenantIsolationGate,
  shop-scoped query layer, hydration/incremental-sync classes).
- Fix the seven pre-existing widget-test failures without dedicated scope justification.
- Touch preserved artifacts (section 0.4) or the stash (`muaman-13 WIP`).
- Push, tag, amend history, or deploy anything.

Verification obligations: gates 1–10 of section 13; final report must classify every
test result against the locked baseline.

---

*End of Phase K planning artifact.*
