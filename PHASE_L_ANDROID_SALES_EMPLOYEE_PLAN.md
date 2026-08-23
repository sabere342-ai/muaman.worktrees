# PHASE L — ANDROID SALES/EMPLOYEE PLAN

**Product:** I Tech Store Management Application
**Institutional owner:** I Tech for Technology / I Tech للتكنولوجيا
**Status:** PLANNING BASELINE (local commit only)
**Predecessor:** Phase K — Android Owner Foundation (locked)
**Successor:** Phase M — Inventory Conflict Hardening (per roadmap)

---

## 0. Governance and Baseline

### 0.1 Repository identity (verified at planning time)

```text
REPOSITORY_ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
REMOTE            = github https://github.com/sabere342-ai/muaman.worktrees.git
GITHUB_REPOSITORY = sabere342-ai/muaman.worktrees
```

A second remote `origin` points to the legacy OneDrive path; it is pre-existing,
untouched, and not used by any phase gate.

### 0.2 Locked predecessor state (verified)

```text
PHASE_K_IMPLEMENTATION_COMMIT = 0bb24de96f468bc439a0cf0b65525dfbfe0a5702 (= HEAD at session start)
PHASE_K_PLANNING_COMMIT       = da184e2ede845ee75ae03299e6c4110eacb8faa9
PHASE_K_IMPL_TAG              = phase-k-implementation-locked
                                (annotated object d1865791d6163a06bff747bfedf00c20861f3f14,
                                 peeled -> 0bb24de96f468bc439a0cf0b65525dfbfe0a5702)
PHASE_J_IMPL_TAG              = phase-j-implementation-locked -> df7fe2990b2058ffbaef3907d349ff029b5f2f1c
PHASE_J_PLAN_TAG              = phase-j-planning-baseline-locked -> 05ba9084b2d61843d4a3de192c8b38a5088e217f
PHASE_I_IMPL_TAG              = phase-i-implementation-locked -> 986f0dde659233e9868b232996a777ae6b3e5fda

ANCESTRY VERIFIED:
986f0dd -> 05ba908 -> df7fe29 -> da184e2 -> 0bb24de (= HEAD = github/codex/i-tech-next-roadmap-freeze)
```

Remote verification (read-only): `github/codex/i-tech-next-roadmap-freeze` =
`0bb24de96f468bc439a0cf0b65525dfbfe0a5702`; tag `phase-k-implementation-locked`
resolves to `d1865791...` with peeled target `0bb24de...` both locally and on the
remote. Divergence before planning: `0 0`. One transient network retry was needed
for the peeled-tag ls-remote; all values then confirmed.

### 0.3 Preserved artifacts (outside Git — absolute protection)

SHA-256 recorded read-only before planning work and re-verified after:

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
  3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07
delivery/I-TECH-Delivery-v1.0.0.zip
  70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418
```

Both remain UNTRACKED/UNSTAGED/UNCOMMITTED and byte-identical. `git add .`,
`git add -A`, `git clean -fd/-fx`, `git stash -u` are FORBIDDEN for the entire
phase. Explicit-path staging only.

### 0.4 Stash integrity

Pre-existing unrelated stash verified present and untouched:

```text
stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration:
283ff9d MUAMAN-12: implement local user roles and sales-only access
```

Treated as evidence only; never popped/applied/dropped during this session.

### 0.5 Planning-only rule

This plan is created as ONE local commit whose parent MUST be
`0bb24de96f468bc439a0cf0b65525dfbfe0a5702`. No push, no tags, no implementation,
no Supabase changes, no schema bump in this session.

### 0.6 Baseline test state (measured THIS session at locked HEAD)

- Toolchain: Flutter 3.24.5 stable / Dart 3.5.4 on windows_x64.
- `flutter analyze`: **0 errors, 0 warnings, 50 infos** (style-level only).
- `flutter test`: **1215 PASS / 7 FAIL** (~2m36s). The 7 failures reproduce
  exactly the frozen pre-existing classification (Supabase.instance accessed in
  widget tests without initialization):
  - `test/features/shop_profile_settings_widget_test.dart`: 4 failures.
  - `test/widget_test.dart`: 3 failures ("App renders first-owner setup...",
    "App renders login screen...", "Login screen reflects a persisted custom...").
  Count grew from the historical 1186 PASS because Phase K added tests; failure
  count and classification are IDENTICAL. Current numbers are the factual Phase L
  baseline.
- `flutter build apk --debug`: **SUCCESS** (43.2s). A non-fatal SDK-XML-version
  warning from the local Android SDK/toolbox version skew was recorded as an
  environment note (not a project defect).

---

## 1. Canonical Phase Definition

### 1.1 Phase identity

```text
NEXT_PHASE_ID      = PHASE_L
CANONICAL_NAME     = Android Sales/Employee
GOVERNING_SOURCE_A = PROJECT_MASTER_PLAN.md section 13 "Phase Roadmap Overview",
                     line 221: "| L | Android Sales/Employee | Seller login,
                     products, sales, returns |"
GOVERNING_SOURCE_B = PRODUCTIZATION_ARCHITECTURE_PLAN.md section 13
                     "Employee/Seller Experience (Phase L)", lines 674-681:
                     seller can log in with cloud credentials, browse products,
                     create sales, process returns, limited admin based on
                     permissions.
CORROBORATION      = PHASE_K_ANDROID_OWNER_FOUNDATION_PLAN.md section 1.1
                     (names L as successor: "seller login, products, sales,
                     returns"); ARCHITECTURE_PLAN section 9 operations table
                     (sale/return creation = OFFLINE_WITH_PENDING_SYNC);
                     MASTER_PLAN OD7 ("whether seller offline sale is allowed").
PREDECESSOR        = Phase K — Android Owner Foundation
SUCCESSOR          = Phase M — Inventory Conflict Hardening (MASTER_PLAN section
                     13; M depends on H+I so it may technically precede L, but
                     the roadmap lists L then M)
DEPENDENCY_CHAIN   = A -> B -> C -> D -> E -> F -> G -> H -> I -> J -> K -> L
```

The two governing sources AGREE; no conflict to arbitrate.

### 1.2 Frozen technical anchors (ARCHITECTURE_PLAN section 13)

| Item | Value |
|---|---|
| Codebase | Same Flutter codebase, responsive layout |
| Local storage | SQLite, same schema |
| Min SDK | 21 |
| Target SDK | 34 |
| Camera barcode | **Phase L+ / future feature — NOT in L** |
| PDF delivery | Share intent / print service |

### 1.3 Objective

Expose the existing tenant-isolated, permission-controlled, offline-capable
sales/product/returns application safely to Android employees/sellers using the
cloud membership and RBAC foundation built in Phases D–K: a seller authenticates
with their OWN cloud credentials, accepts an invitation, binds to an ACTIVE shop
membership, browses products, creates sales, processes returns, and receives any
limited-admin capability strictly through the server-authoritative permission set
— without regressing Windows and without redesigning Phase J/K architecture.

### 1.4 Explicit non-goals

- Camera barcode scanning (Phase L+; no CAMERA permission, no scanner packages).
- SyncEngine activation in production (Phase J freeze seam; see §11 / D-L7).
- Sale-linked returns data-model change (§10 / D-L6).
- Inventory conflict hardening, negative-stock policy finalization (Phase M).
- Excel import on Android (Phase N), invoice branding rework (Phase O),
  production hardening/release (Phase P).
- Play publishing, production signing, billing, analytics, push notifications
  (commercial workstream; OD-K2 remains open).
- Windows installer/AppId/BINARY_NAME/pubspec-name changes (FROZEN).
- Redesign of ActiveShopContext, TenantIsolationGate, shop-aware query layer,
  hydration/incremental-sync classes.
- Fixing the seven known pre-existing widget-test failures (section 0.6).

---

## 2. Current-State Forensics

All paths relative to repo root; app code under `app/`. Line numbers refer to the
locked Phase K commit `0bb24de`.

### 2.1 Android runtime foundation (inherited from Phase K)

Installable Android build exists and builds green (`flutter build apk --debug`
verified this session). Manifest carries INTERNET permission ONLY plus a
`tools:overrideLibrary` for `androidx.security` with fail-closed Keystore
behavior below API 23 (`app/android/app/src/main/AndroidManifest.xml`). Label is
still the placeholder `muaman_store`; applicationId placeholder
`com.almuaman.muaman_store` (OD-K1 open). Platform abstractions from K:
`lib/platform/device_identity_provider.dart`,
`lib/platform/platform_capabilities.dart`, `lib/platform/secure_secret_store.dart`,
`lib/licensing/secure_store_android.dart`, `lib/services/cloud_session_resume.dart`.

### 2.2 Authentication today is LOCAL-FIRST with a single global cloud email

`LoginScreen._login()` (`app/lib/screens/auth/login_screen.dart:48-103`) REQUIRES
a local user record: `_repo.authenticate(username, password)` against the local
`users` table (PBKDF2). Only afterwards does `_attemptCloudSession` (:106-169)
run, and it signs into Supabase using the email stored ONCE globally in
`app_settings['cloud.auth.email']` (:111-115) — written exclusively by owner
onboarding (`IdentityLinker._persistIdentity`,
`app/lib/services/identity_linker.dart:242`).

Consequences (all evidence-backed):

- An employee has NO way to authenticate with their own cloud credentials
  anywhere in the app.
- A fresh device cannot be used by anyone except by first creating a local owner
  via `FirstOwnerSetupScreen` because `AuthGate` requires
  `_userRepo.hasAnyUser()` (`app/lib/main.dart:239,296`) before showing
  LoginScreen.
- The cloud sign-in email being one global setting means multi-user login on a
  single device is structurally impossible today.
- Cold-start cloud-session resume (Phase K D4) works, but only resumes the
  OWNER's session established through this same local-first path.

### 2.3 Employee accounts today are LOCAL-ONLY rows

`UserManagementScreen` creates employees purely locally
(`app/lib/screens/admin/user_management_screen.dart:85-91` →
`UserRepository.createUser(...)`). No Supabase Auth account, no `shop_members`
row, no invitation. The cloud membership model (Phase D) is fully implemented
server-side but has NO client-facing employee lifecycle.

### 2.4 Invitation stack EXISTS but is DEAD CODE

Implemented and complete, imported NOWHERE in `lib/` (grep over all of lib
returns only self-references):

- `app/lib/screens/auth/accept_invitation_screen.dart` (full UI, takes initialEmail).
- `app/lib/screens/settings/invite_employee_screen.dart` (calls `invite-employee`
  Edge Function with owner JWT, :70-73).
- `app/lib/services/invitation_service.dart` (`acceptInvitation` wrapper :80-97).
- `app/lib/services/cloud_auth_service.dart:189-199` (`accept_invitation` RPC call).

Server side (read-only inspection):

- `supabase/migrations/20260820000021_add_invitations.sql` — invitations table.
- `supabase/migrations/20260820000022_add_accept_invitation.sql` —
  `accept_invitation(p_shop_id UUID, p_user_id UUID) RETURNS JSONB`,
  SECURITY DEFINER, flips `shop_members.status INVITED -> ACTIVE`, marks the
  invitation ACCEPTED, JSON error results (no pending invitation, null args).
- `supabase/functions/invite-employee/index.ts` — service-role account +
  membership creation, verifies caller is authenticated ACTIVE owner of shop.

### 2.5 Shop binding / membership semantics

- `ShopResolver.resolveActiveShop()` (`app/lib/services/shop_resolver.dart:44-76`):
  0 shops → throws; 1 → auto-select; many → last-used pref (`cloud.lastShopId`),
  else FIRST ACTIVE. Multi-shop CHOICE UI (`screens/settings/shop_selector_screen.dart`)
  remains dead code (reconfirmed this session).
- `ActiveShopContext` (`app/lib/services/active_shop_context.dart`): every
  bind/switch validated against ACTIVE memberships via the validator wired at
  startup (`main.dart:195-204`); unconfigured context rejects ALL binds; null
  context under armed isolation = reads fail closed empty, writes throw.
- `TenantIsolationGate` (`app/lib/services/tenant_isolation_gate.dart`): strict
  shop-scoped read/write predicates, conservative default UNARMED, persisted
  arming marker `cloud.tenantIsolationArmed`; Phase K arms it on cold-start
  resume.
- Cold-start resume: `resumeCloudSessionAtStartup`
  (`app/lib/services/cloud_session_resume.dart:44-98`) — resolve → bind → gate →
  licensing → permission sync, fail-closed; wired in `main.dart:229-237`.
- Logout (`main.dart:256-273`): clears SessionState, `ActiveShopContext.unbind()`,
  `PermissionSyncService.reset()`, best-effort `auth.signOut()`. It relies on
  unbound-context fail-closed semantics rather than explicitly suspending the
  isolation runtime flag — verification item V2 below.

### 2.6 RBAC resolution

- Catalog: 18 permissions with stable IDs (`app/lib/services/permissions.dart:35-180`):
  dashboard.view, inventory.view, inventory.edit, inventory.delete, sales.view,
  sales.create, sales.history.view, sales.delete, returns.view, returns.create,
  returns.delete, expenses.view, expenses.create, expenses.delete,
  stocktake.view, admin.users.manage, admin.permissions.manage,
  admin.settings.access.
- Roles frozen: owner / employee / salesOnly. Defaults
  (permissions.dart:200-215): owner=all; employee=all minus deletes/users/
  permissions/settings; **salesOnly={sales.view, sales.create} only**.
- Resolution: `PermissionResolver.can()` — owner always all; non-owner uses the
  CLOUD snapshot when present, else local config. Snapshot applied by
  `PermissionSyncService.syncPermissions(shopId)`
  (`app/lib/rbac/permission_sync_service.dart:47-87`); cached for offline;
  server reauthorizes every RPC independently; client snapshot is never authority.

### 2.7 Shell reachability

`AuthGate.build` (`main.dart:296-317`): role == salesOnly → **SalesOnlyShell**
which renders ONLY SalesScreen inside a PopScope (:320-370) — a salesOnly user
has NO products browsing and NO returns access regardless of granted
permissions. Any other logged-in role gets FullAppShell with
permission-filtered bottom nav (:389-423) plus per-permission AppBar actions
(:465-483). Shell choice is driven by the LOCAL user role
(`SessionState.currentRole`), not by the cloud membership role.

### 2.8 Sales path (verified end-to-end)

- UI entry: SalesScreen; create gated by `canCreateSales`
  (`app/lib/screens/sales/sales_screen.dart:38-39,199`); history gated by
  `canViewSalesHistory` (:35); delete gated by `canDeleteSales` (:256,386).
- Persistence: `insertSaleAndDecrementStock`
  (`app/lib/database/database_helper.dart:1095-1161`) — licensing enforce +
  `_requirePermission(canCreateSales)` + single `db.transaction`: product lookup
  UNDER tenant predicate (`_writePredicate()`), insufficient-stock guard, sale
  insert stamped with tenant + `sync_status='PENDING'`, sync_queue enqueue,
  conditional stock decrement `WHERE ... currentQuantity >= ?` with affected==0
  → throw (race-proof). Invoice path `insertInvoiceWithItems` (:1163-1249) is
  equally atomic across header + lines + stock.
- Cloud: SECURITY DEFINER RPCs `create_cloud_sale_with_stock`,
  `create_cloud_return_with_stock`, `delete_cloud_sale_with_revert` etc. exist
  (`supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql`;
  Dart wrappers `app/lib/repositories/cloud/cloud_sales_repository.dart`) but
  the PRODUCTION sale flow writes SQLite + enqueues only; cloud repos are
  consumed by sync adapters and Phase I migration code, neither of which runs
  in production (§2.11).
- Invoice delivery already Android-adapted (Phase K D8):
  `app/lib/invoices/invoice_delivery.dart` — Android route = system share/print,
  zero arbitrary filesystem writes.

### 2.9 Products path

InventoryScreen reachable via nav item gated `canAccessInventory`
(`main.dart:396-397`); edit FAB gated `canEditProducts`
(`inventory_screen.dart:120,132`); delete gated `canDeleteProducts`. Product
create/edit dialog includes costPrice fields (:198,222) — cost exposure is
governed at SCREEN level, not field level. All product queries/writes run under
tenant predicates. Manual barcode search supported; camera scanning out of scope.

### 2.10 Returns path

ReturnsScreen FAB gated `canCreateReturns`
(`app/lib/screens/returns/returns_screen.dart:144,156`); insert goes to
`insertReturn` (`database_helper.dart:1538-1594`): transactional insert +
returnedQuantity/currentQuantity recomputation + enqueue, tenant-stamped,
licensing-enforced, permission-checked. **Returns reference the PRODUCT barcode,
not an original sale** (`app/lib/models/return_item.dart:2-10` — no saleId
field). No duplicate-restoration risk per sale exists, but return-to-sale
traceability does not exist either.

### 2.11 Offline / sync runtime

sync_queue fills via enqueue-after-write hooks
(`database_helper.dart:220-270`) with idempotency_key + entry.shop_id. NOTHING
drains it: `SyncEngine`/`SyncWorker`/`HydrationService`/`IncrementalSyncService`
are constructed only inside `lib/sync/` itself (grep verified). This is the
documented Phase J freeze seam (Phase K plan D9/R4) — unchanged.

### 2.12 Local database

Schema version **14** (`database_helper.dart:336,352,381`). Phase K W1 closed
the fresh-vs-upgrade parity gap (`test/database/schema_v14_fresh_parity_test.dart`).
All tenant tables carry shop_id/cloud_uuid/v13 sync columns. No v15 justified by
canonical L (§7).

### 2.13 Responsive / phone UX

RTL forced everywhere; bottom-nav shell; no breakpoint framework; no
hundred-dp fixed widths found in sales/inventory screens (grep). LoginScreen
card is scroll-wrapped and phone-viable. Residual risk concentrates in dense
FullAppShell screens (reports/dashboard tables) that default sellers never see.

---

## 3. Gap Analysis

Classification legend: [L] = Phase L work, [V] = verify-only in L,
[O] = out-of-scope/future, [R] = risk tracked.

| ID | Requirement | Current State | Gap | Implementation Needed | Security/Data Impact | Tests Required | Class |
|----|-------------|---------------|-----|----------------------|----------------------|----------------|-------|
| L-GA1 | Seller logs in with OWN cloud credentials | Local user required; cloud email is ONE global app_settings key (login_screen.dart:54-115) | Structural: no email-based cloud login path | Cloud-first login mode: signInWithEmail → get_user_shops → require ACTIVE membership → bind → gate → perm sync → local row provisioning (§5/D-L1/D-L4) | High: must not weaken Windows local auth; fail-closed on no-ACTIVE-membership | Unit: success/no-membership/revoked/offline; widget: new login mode | [L] |
| L-GA2 | Invitation acceptance reachable | Screens+RPC complete but unwired (§2.4) | Navigation wiring only | Wire AcceptInvitationScreen from login surface; wire InviteEmployeeScreen for owners (canManageUsers) | Medium: RPC verifies INVITED server-side | Widget tests both screens; INVITED→ACTIVE→login flow test | [L] |
| L-GA3 | Seller works on fresh device without owner-local setup | AuthGate demands hasAnyUser before LoginScreen (main.dart:296) | Fresh-install gate blocks pure cloud sellers | When Supabase configured and users==0: offer owner setup OR cloud login/accept-invitation; seller path provisions local row (D-L3) | High: fresh install must NOT be able to claim ownership | Fresh-device seller bootstrap tests; offline fresh device unchanged | [L] |
| L-GA4 | Cloud identity ↔ local user mapping for sellers | Only owner linking exists (IdentityLinker) | No seller provisioning | Upsert local users row keyed by cloud_uuid; role mapped ONLY from membership (employee/salesOnly); no local password | Medium: local row is cache, NEVER authorization source | DB tests: idempotent upsert, no duplicate cloud_uuid rows, owner-reject | [L] |
| L-GA5 | Seller shell reflects granted permissions incl. products+returns | SalesOnlyShell hardcodes sales-only view (main.dart:320-370) | Granted inventory/returns permissions unreachable for sellers | Permission-driven shell selection (D-L5): FullAppShell filter produces seller experience; default salesOnly ⇒ identical pixels to today | Low-Medium: presentation-layer RBAC consumption only | Widget matrix per permission combo; default-role regression | [L] |
| L-GA6 | Browse products on Android | InventoryScreen permission-gated, tenant-scoped | Reachability only (GA5) | Verify-only reuse; cost-price policy per D-L8 | Low | Existing inventory suite + viewport widget test | [V] |
| L-GA7 | Create sales on Android (offline-capable) | Atomic local write + queue; production path proven (§2.8) | Works locally TODAY once seller can log in | Verify-only core + explicit offline posture record (D-L7/OD-L1) | HIGH financial invariants (§20 invariants list) | Existing atomicity suite + seller-flow widget test | [L]/[R] |
| L-GA8 | Process returns on Android | Atomic, product-barcode-based (§2.10) | Reachability only (GA5); no sale linkage | Verify-only reuse; linkage deferred (D-L6) | Medium: stock restoration correctness already tested | Existing returns suite + seller-flow test | [V] |
| L-GA9 | Limited admin by permissions | Resolver cloud-first; refresh at login+cold-start | None beyond GA5 | Verify-only; ensure refresh also after invitation acceptance | Low | RBAC suite + refresh-after-accept test | [V] |
| L-GA10 | Tenant isolation for seller paths | Bind validated vs ACTIVE; gate arms at resume/login; RLS authoritative | New seller paths MUST traverse identical sequence | Reuse resume sequence primitives post-cloud-login (no duplicated semantics) | CRITICAL cross-shop leak prevention | Tenant-isolation suite + revoked/expired fail-closed seller tests | [L] |
| L-GA11 | Licensing on seller devices | Per-shop register/activate; enforceActive gates writes | Sellers share shop license; max_devices limits apply | Register seller devices same as K; surface license-blocked state in seller UX | Medium: max_devices exhaustion locks sellers out visibly (never silently bypassed) | Licensing suite + blocked-write seller test | [L] |
| L-GA12 | Offline behavior & queue growth | Queue fills undrained (§2.11) | Offline seller writes accumulate indefinitely | DO NOT activate SyncEngine (D-L7); bounded freeze posture documented; risk recorded | HIGH architectural decision — documented explicitly | Existing queue tests; documented decision | [R] |
| L-GA13 | Phone responsiveness for seller flows | RTL ok; no fixed-width blockers found (§2.13) | Polish unknown until exercised | Responsive presentation adjustments ONLY (no navigation redesign) | Low | Widget tests at ~360dp-class viewports for seller surfaces | [L] |
| L-GA14 | Android invoice delivery | Share/print route done in K (invoice_delivery.dart) | None | Verify-only | Low | Existing invoice delivery tests | [V] |
| L-GA15 | Windows non-regression | Windows primary platform | Shared-code edits touch Windows too | Every shared change preserves Windows-default behavior (§14) | High | FULL existing suite matches §0.6 baseline | [L] |

No additional structural gap found: no new migration, no schema change.

---

## 4. Frozen Design Decisions

Each decision: Decision / Reason / Affected files / Security-Tenant-Accounting
invariants / Alternatives rejected.

### D-L1 — Cloud-first email/password login ADDED ALONGSIDE local login

Decision: LoginScreen gains a cloud authentication mode (email+password via
`CloudAuthService.signInWithEmail`, login_screen imports already include
cloud_auth_service transitively through services). Sequence: signIn →
`get_user_shops` → require ≥1 ACTIVE membership → resolve/bind active shop →
arm TenantIsolationGate → licensing initialize/register/activate →
PermissionSyncService.syncPermissions → provision/match local user row (D-L4) →
SessionState.login + setCloudSession. The LOCAL username/password mode remains
EXACTLY as-is and remains the primary Windows presentation.

Reason: governing objective says "log in with cloud credentials"; the existing
local path is load-bearing for Windows/offline operation and must not regress.

Affected: `app/lib/screens/auth/login_screen.dart` (or extracted
`cloud_login_form.dart` consumed by it), new
`app/lib/services/seller_session_provisioning.dart`.

Security invariants: fail-closed on zero-ACTIVE memberships; no shop id guessed;
server stays authority (RLS + SECURITY DEFINER); no secrets beyond Supabase's
own session persistence.
Tenant invariants: bind only via ActiveShopContext validated path.
Accounting invariants: none touched (auth only).
Rejected: replacing local login (breaks Windows/offline contract); storing
seller passwords locally; silent email-string matching between cloud and local
users (identity-confusion risk).

### D-L2 — Invitation acceptance wired end-to-end reusing existing RPC

Decision: AcceptInvitationScreen becomes reachable from the login surface for a
user who signs up/signs in with their own credentials; InviteEmployeeScreen
becomes reachable from the owner user-management area (gated canManageUsers).
Uses existing `invite-employee` Edge Function + `accept_invitation` RPC +
`get_user_shops`. After acceptance: permission refresh BEFORE entering shell.

Reason: MASTER_PLAN D9 (email-based invitations); all server pieces exist since
Phase D; screens exist unwired.

Affected: login_screen.dart (entry), main.dart routing (post-accept landing),
admin/user_management_screen.dart (owner-side entry point).

Security invariants: acceptance requires an authenticated cloud identity; RPC
verifies pending INVITED row server-side; revoked/expired map to Arabic error
messages.
Tenant/accounting invariants: none altered.
Rejected: client-side inserts into shop_members (RLS forbids; new grants
forbidden); email deep links (no dynamic-link infrastructure in scope).

### D-L3 — Fresh-device seller bootstrapping WITHOUT owner setup

Decision: when Supabase is configured AND no local users exist, AuthGate offers
FirstOwnerSetupScreen (unchanged; first-come ownership) AND the cloud-login /
invitation path. A successful NON-OWNER cloud login provisions the local row and
proceeds; it can NEVER create or elevate an owner role locally. If the resolved
membership role is `owner`, the seller path REJECTS with guidance to use Owner
Setup (prevents ownership hijack of fresh installs; owner identity linking keeps
its dedicated FirstOwnerSetup flow).

Reason: architecture requires seller login on Android without prior owner-local
setup; safety requires the ownership race be impossible to exploit.

Affected: main.dart (AuthGate branching), provisioning service (D-L4).

Security invariants: local role derived ONLY from cloud membership role
(employee/salesOnly); anything else fails closed.
Tenant invariants: unchanged bind validation.
Accounting invariants: none.
Rejected: requiring owner to register each device first (contradicts governing
text); skipping the local user row entirely (breaks SessionState plumbing).

### D-L4 — Local user row as CACHE keyed by cloud_uuid

Decision: on first successful cloud login per device, upsert
`users(cloud_uuid=auth.uid)` with displayName from cloud metadata and role
mapped from membershipRole (employee→employee, salesOnly→salesOnly, else reject).
No local password required for cloud-mode sessions; updateLastLogin maintained;
an existing row with same cloud_uuid is reused.

Reason: SessionState/UserRepository expect a User; a cached row avoids invasive
refactor while making explicit the row is NOT the authorization source.

Affected: `app/lib/database/user_repository.dart` (upsert-by-cloud-uuid method),
provisioning service.

Invariants: users table shape unchanged (NO schema change); logout does not
delete rows (audit trail).
Rejected: v15 dedicated identities table (column already exists); storing cloud
passwords locally.

### D-L5 — Permission-driven shell replaces hardcoded SalesOnlyShell routing

Decision: AuthGate routes EVERY logged-in user to FullAppShell; its existing
permission-filtered nav yields the seller experience naturally (default
salesOnly ⇒ exactly the Sales tab — behaviorally equivalent to today's
SalesOnlyShell for default permissions). SalesOnlyShell is retired from routing
(remove or keep-as-dead-code at implementer discretion; removal requires
updating dependent tests).

Reason: "Limited admin based on permissions" cannot be expressed by a hardcoded
role→shell map; duplication of navigation logic otherwise.

Affected: main.dart.

Security invariants: UI visibility is convenience only; enforcement stays at
DatabaseHelper._requirePermission + licensing enforcer + server RPC/RLS.
Accounting invariants: none.
Rejected: adding tabs INTO SalesOnlyShell (duplicates FullAppShell); GoRouter
migration (deferred by architecture; big-bang rewrite rejected).

### D-L6 — Returns stay product-barcode-based; NO sale-linkage change in L

Decision: no schema change for sale↔return linkage in Phase L.

Reason: canonical scope "process returns" is satisfied by existing atomic
returns; FK-to-sale semantics change accounting/reporting behavior and belong to
Phase M or an explicit owner request. Default bias honored: no speculative v15.

Affected: none (verify-only).
Invariants: inventory formula invariant untouched.
Rejected: sneaking a `sale_id` column into L (scope expansion, migration burden,
zero governing mandate).

### D-L7 — SyncEngine REMAINS deactivated; offline posture explicitly bounded

Decision: Phase L does NOT construct SyncEngine/SyncWorker/HydrationService/
IncrementalSyncService. Offline seller behavior = Phase J freeze semantics:
local atomic write + PENDING queue entry; nothing drains. Recorded as interim
answer to MASTER_PLAN OD7: seller offline sale IS permitted locally under
existing atomic/enforcement rules; cloud propagation waits for the phase that
activates the sync runtime (candidate M or dedicated sync phase).

Reason: activating sync is a cross-platform architectural event (echo loops,
conflict verdicts, hydration ordering) — precisely what Phase K D9 refused to
half-do. Seller path adds NO new offline semantics; it reuses proven ones.

Affected: none (verify-only); documentation.
Invariants: idempotency keys intact; queue entries carry entry.shop_id; no
partial writes.
Rejected: "drain just sales on login" (half-activated sync, untested conflict
paths).

### D-L8 — Cost-price visibility governed at permission-screen granularity

Decision: keep screen-level gating (inventory.view gates ALL product data
including cost columns). No field-level masking invented in L. Documented as
known limitation consistent with frozen 18-permission catalog; if owners want
cost-hidden browsing, that is a future catalog/UX decision
(OUT_OF_PHASE_L_SCOPE unless raised).

Reason: no existing permission expresses "prices but not costs"; catalog is
add-only and no governing doc mandates expansion.

Affected: documentation only.
Rejected: ad-hoc hiding of cost widgets based on role name strings (violates
permission-driven UI principle; trivially cosmetic).

### D-L9 — Android platform envelope stands: minSdk 21 / targetSdk 34 / INTERNET only

No new Android permissions in L (explicitly NO CAMERA); camera scanning stays
Phase L+. Affected: none.

---

## 5. Authentication / Membership Model (target after L)

```text
Seller first time on a device:
  launch -> AuthGate init (DB v14, defaults, resolver, profile, licensing wiring,
           ActiveShopContext.configure(fail-closed validator))
  -> no local users AND Supabase configured:
       offer [Owner Setup] [Cloud Login] [Accept Invitation]
  -> Accept Invitation: signUp/signIn own credentials -> accept_invitation RPC
       -> membership INVITED->ACTIVE (server) -> proceed as cloud login
  -> Cloud Login: signInWithEmail(email,password)
       -> get_user_shops -> 0 shops => fail closed
       -> resolveActiveShop (single / last-used / first-ACTIVE)
       -> ActiveShopContext.bind(shopId)     [ACTIVE-validation, fail closed]
       -> TenantIsolationGate.restoreAtStartup
       -> licensing initialize/registerDevice('android')/activateDevice
       -> PermissionSyncService.syncPermissions(shopId)
       -> upsert local users row by cloud_uuid (role from membership; owner=>reject)
       -> SessionState.login + setCloudSession
       -> FullAppShell (permission-filtered; salesOnly default => Sales tab only)

Cold start with live session: existing resumeCloudSessionAtStartup sequence
(Phase K D4) now covers sellers automatically — same primitives.

Revoked/expired membership: bind fails (validator requires isActive) or the next
resume fails => fail-closed unbound state; UI communicates; no data rendered.

Logout: SessionState.logout, ActiveShopContext.unbind,
PermissionSyncService.reset, best-effort Supabase signOut (existing
main.dart:256-273 sequence reused unchanged).

Multi-shop: selection UI stays OUT of L scope (auto-select rules stand;
ShopSelectorScreen remains dead code). Recorded explicitly: a multi-shop seller
gets last-used/first-ACTIVE deterministically.
```

## 6. RBAC / Authorization Matrix

Enforcement layers: **UI** = widget gating (convenience only), **DB** =
`DatabaseHelper._requirePermission` + licensing enforcer + tenant predicates,
**SRV** = SECURITY DEFINER RPC checks, **RLS** = Postgres row policies. Client
UI hiding is NEVER sufficient authorization.

| Surface / Action | Permission ID | salesOnly default | employee default | owner | UI | DB | SRV/RLS |
|---|---|---|---|---|---|---|---|
| Dashboard tab | dashboard.view | – | yes | yes | yes | read predicate | RLS SELECT |
| Products browse (inventory tab) | inventory.view | –* | yes | yes | yes | read predicate | RLS SELECT |
| Product create/edit | inventory.edit | – | yes | yes | yes | _requirePermission + license | create/update_cloud_product SRV |
| Product delete | inventory.delete | – | – | yes | yes | _requirePermission | delete_cloud_product SRV |
| Sales tab | sales.view | yes | yes | yes | yes | read predicate | RLS SELECT |
| Sales history/reports | sales.history.view | – | yes | yes | yes | read predicate | RLS SELECT |
| Create sale/invoice | sales.create | yes | yes | yes | yes | _requirePermission + license | create_cloud_sale_with_stock SRV |
| Delete sale | sales.delete | – | – | yes | yes | _requirePermission | delete_cloud_sale_with_revert SRV |
| Returns tab | returns.view | –* | yes | yes | yes | read predicate | RLS SELECT |
| Create return | returns.create | –* | yes | yes | yes | _requirePermission + license | create_cloud_return_with_stock SRV |
| Delete return | returns.delete | – | – | yes | yes | _requirePermission | SRV |
| Expenses view/create/delete | expenses.* | – | view+create | all | yes | _requirePermission | SRV |
| Stocktake | stocktake.view | – | yes | yes | yes | read predicate | RLS SELECT |
| Users management (+invite) | admin.users.manage | – | – | yes | yes | _requirePermission | SRV / Edge fn |
| Roles/permissions editor | admin.permissions.manage | – | – | yes | yes | _requirePermission | SRV |
| Settings | admin.settings.access | – | – | yes | yes | n/a | shop-settings SRVs |
| Backup/restore/clean start | admin.settings.access | – | – | yes | yes | n/a | n/a (local files) |
| Licensing/device screens | under settings access | – | – | yes | yes | enforcer | register/activate_device SRV |

\* A seller CAN be granted inventory.view / returns.view / returns.create by the
owner through the existing roles/permissions editor — that IS the "limited
admin based on permissions" contract; the permission-driven shell (D-L5) makes
grants immediately visible. Server enforcement is identical regardless.

Cost-price note: governed by D-L8 (screen-level granularity; no field masking).

## 7. Data Model

```text
SQLite schema change  = NO   (version stays 14)
Supabase migration    = NO
```

Why NO local change: provisioning reuses `users.cloud_uuid`; sales/returns/
products carry full v13 sync columns; nothing in the canonical seller flow needs
a new column/table (returns stay barcode-keyed per D-L6; shop preference reuses
app_settings key `cloud.lastShopId`).

Why NO cloud migration (evidence): invitations table + `accept_invitation`
SECURITY DEFINER RPC (migration …00022), `invite-employee` Edge Function,
`get_user_shops`, `verify_shop_membership`, effective-permission machinery +
`shop_permission_overrides` (…00024), license-gated cloud CRUD RPCs with RLS
SELECT-only policies and revoked direct grants (…00025), sync core with
idempotency/version conflicts (…00026). Phase L adds NO grant, policy, function,
or table server-side.

## 8. Tenant Isolation

- Every seller read/write executes under the bound shop: local queries via
  tenant predicates (`_readPredicate/_writePredicate`); server via RLS plus
  SECURITY DEFINER RPCs parameterized by validated shop.
- Membership validation precedes every bind (login, resume, accept-landing):
  active_shop_context.dart:53-65, fail-closed.
- Cross-shop denial: foreign shop_id rejected client-side AND server-side (RLS
  membership subquery). A tampered client cannot read another shop's rows.
- Multi-shop: deterministic auto-select; `switchShop` API exists but no UI in L;
  any future switch revalidates identically.
- Offline queue affinity: every sync_queue row persists entry.shop_id at enqueue
  (database_helper.dart:232-270). When a sync runtime eventually drains it,
  execution must run under entry.shop_id — existing invariant, regression-tested.
- Sale/return tenant boundary: stamped inside their transactions (`tp.stamp()`).
- NEW L obligation: seller login/resume MUST traverse the identical
  bind→arm→sync-permissions sequence; no shortcut paths; tests in §17.

## 9. Sales Runtime Flow (after L)

```text
Android seller launches app
  -> main(): stock sqflite on Android; Supabase.initialize (dart-defines)
  -> AuthGate init: DB v14 ... ActiveShopContext.configure(validator)
  -> restored valid session? -> resumeCloudSessionAtStartup
       (bind/arm/license/perms)                       [Phase K path]
  -> no session -> Cloud Login: signInWithEmail
  -> get_user_shops -> resolveActiveShop (ACTIVE chain)
  -> ActiveShopContext.bind -> TenantIsolationGate.restoreAtStartup
  -> registerDevice('android') + activateDevice (shared shop license)
  -> PermissionSyncService.syncPermissions -> resolver cloud snapshot
  -> local user row upsert (cache) -> SessionState.login/setCloudSession
  -> FullAppShell filtered by permissions (salesOnly => Sales tab)
  -> SalesScreen: insertSaleAndDecrementStock / insertInvoiceWithItems
       [license enforce + canCreateSales + single txn:
        tenant-scoped product lookup, stock guard, PENDING stamp,
        sync_queue enqueue(idempotency_key, shop_id)]
  -> invoice preview -> Printing.sharePdf/layoutPdf (system share/print; no FS)
  -> ONLINE: cloud copy happens when a sync runtime exists (NOT in L);
     OFFLINE: local record authoritative on device, queued entry waits
```

Windows flow: IDENTICAL to locked Phase J/K behavior at every step (local login
mode unchanged; shell layouts for existing roles unchanged).

## 10. Returns Runtime Flow (after L)

```text
seller (granted returns.view/create) opens Returns tab
  -> list = getAllReturns()            [tenant predicate]
  -> create: barcode/quantity/price form -> insertReturn
       [license enforce + canCreateReturns + single txn:
        tenant product lookup, PENDING insert + enqueue,
        returnedQuantity/currentQuantity recomputed atomically]
  -> delete: canDeleteReturns (owner default) -> deleteReturn
  -> no original-sale linkage (D-L6); refund document = existing invoice
     preview/share path where applicable
  -> offline semantics mirror sales (PENDING queue; no drain in L)
```

## 11. Offline / Sync Semantics (explicit answers)

- What works offline? Everything the current app does offline: browse cached
  products, create sales/returns/invoices atomically locally, local reports.
  Seller-specific: FIRST login requires network; later cold starts use the
  persisted session (expired-refresh degrades to offline boot with cached
  permissions).
- What is queued? Every business write as a PENDING sync_queue entry with
  idempotency key and entry.shop_id.
- Who drains the queue? NOBODY in Phase L (D-L7) — unchanged since the Phase J
  freeze.
- After app restart? Entries persist, still undrained; counters visible through
  SessionState sync-status accessors.
- Conflicts? Cannot arise from L (nothing syncs). When sync activates, verdicts
  follow ARCHITECTURE_PLAN section 9 (sales/returns server-authoritative unique).
- Duplicate prevention? Per-op idempotency keys + transactional local writes +
  replay-safe sync_log design server-side.

FIRST-CLASS ARCHITECTURAL FINDING (not hand-waved): with SyncEngine inactive, an
offline seller device accumulates undrained financial records indefinitely;
those records exist ONLY on that device until a sync runtime ships. This is an
explicit, time-bounded freeze posture inherited from Phase J/K — recorded as
RISK R-L1 and OWNER VISIBILITY item OD-L1 (which phase activates sync; whether
seller offline selling is commercially acceptable — MASTER_PLAN OD7). Phase L
neither fixes nor worsens this relative to locked behavior, and must NOT absorb
sync activation silently.

## 12. Android UX / Responsive Rules

- RTL: forced RTL everywhere including new login/invitation UI.
- Viewport: seller-facing widgets must render at ~360dp-class widths;
  authorized responsive tweaks limited to padding/scroll/font-size adjustments.
- Keyboard/dialogs: forms inside scroll views (LoginScreen pattern).
- Restricted surfaces: tabs/actions simply absent without permission; no
  dead-end screens; permission-denied states reuse existing patterns.
- Product selection: manual barcode/search only (camera OUT per D-L9).
- No desktop file dialogs in seller flows (share/print only).
- Session expiry: explicit re-login prompt when cloud calls repeatedly fail
  auth (small testable addition under GA13); otherwise existing degrade-silently
  behavior.

## 13. Security

- Authentication: Supabase Auth email/password for sellers; local PBKDF2 flow
  untouched; no local storage of cloud passwords; sessions persist only via
  supabase_flutter official mechanism.
- RBAC: three enforcement layers (UI convenience / local hard gates / server
  authority); cloud snapshot never authoritative (contract comment at
  permission_sync_service.dart:17-18 preserved).
- Server authorization: RLS SELECT-only membership policies + SECURITY DEFINER
  mutation RPCs; L adds no grants/policies/functions.
- Licensing: shared shop license; seller devices registered; enforceActive
  blocks business writes identically across platforms; max_devices exhaustion
  surfaced as visible blocked-state messaging (never bypassed silently).
- Secure storage: Keystore-backed path from K reused; no plaintext secrets.
- Device identity: SSAID provider from K reused; no new fingerprint logic.
- No privileged secrets in Flutter binary (anon key only) — unchanged.
- Fail-closed membership: zero-ACTIVE-membership accounts cannot bind, read, or
  write anything.
- Tenant isolation: §8.
- Android permissions: INTERNET only (D-L9).

## 14. Migration / Compatibility

- Windows: login screen gains an OPTIONAL additional sign-in mode (default
  presentation/focus unchanged); unified shells produce identical layouts for
  existing roles/permissions; DatabaseHelper/licensing/isolation semantics
  untouched. Regression gate: full suite vs §0.6 + manual smoke of local login
  + one sale on Windows.
- Android upgrades from Phase K: app-level update only; schema v14 unchanged;
  persisted sessions survive upgrade.
- Fresh Android installs: v14 fresh-parity holds (K W1); new seller bootstrap
  path added alongside owner setup.
- Local DB compatibility: none required (§7); backup/restore paths untouched.
- Session compatibility: CloudSession consumed additively (membershipRole /
  membershipStatus already carried).
- Role compatibility: frozen role names; provisioning maps ONLY
  employee/salesOnly from memberships; owner-role cloud login on a fresh device
  is rejected in favor of Owner Setup (hijack prevention).

## 15. Failure / Recovery Semantics

| Condition | Behavior |
|---|---|
| Offline at boot (seller with prior session) | Resume fails gracefully; cached permissions apply; local data usable; queue grows |
| Offline first-ever login | Clear Arabic error; retry when online; no partial local state |
| Expired session / refresh failure | Behaves like offline boot; re-login needed for cloud features; cached-permission shell renders with degraded banner |
| Revoked membership mid-session | Next bind/resume/validator call fails → unbound fail-closed; writes throw; user informed |
| Permission changed while device offline | Stale snapshot governs LOCAL UI only; server re-checks every RPC — no escalation possible; refresh on next online login/resume |
| License expired / suspended | Enforcer blocks business writes (existing states enum); blocked-state UI shown |
| RPC timeout during auth/login | Mapped to retryable network error class; no partial state |
| Duplicate submission (double-tap) | In-flight button disabling (existing pattern) + transactionality + idempotency keys |
| App killed during sale | Single sqlite txn: fully applied or not at all; no partial write possible |
| App killed during return | Same transactional guarantee |
| Cloud success/local failure | N/A in L for business writes (no production cloud business writes) |
| Local success/cloud failure | Normal offline posture; PENDING entry awaits eventual sync runtime |
| Cross-shop context mismatch | Validator rejects bind; isolation keeps reads empty/writes throwing |

## 16. Implementation Work Breakdown

### CREATE

- `app/lib/services/seller_session_provisioning.dart` — cloud-login
  orchestration (signIn → shops → bind → gate → license → perms → local-row
  upsert) reusing ShopResolver / ActiveShopContext / TenantIsolationGate /
  CloudLicensingService / PermissionSyncService; fully injectable for tests.
- `UserRepository.upsertCloudUser(...)` method (inside
  `app/lib/database/user_repository.dart`) keyed by cloud_uuid.
- Tests (names indicative):
  - `test/cloud/seller_login_flow_test.dart` — success / no-membership /
    revoked / offline / owner-reject matrix.
  - `test/cloud/invitation_acceptance_test.dart` — accept success, no pending,
    network failure; permission refresh after accept.
  - `test/features/seller_shell_permissions_test.dart` — permission-driven tab
    matrix incl. default-salesOnly equivalence.
  - `test/features/fresh_device_seller_bootstrap_test.dart`.
  - `test/database/upsert_cloud_user_test.dart` — idempotency, role mapping.
  - Viewport widget tests for seller surfaces (~360dp-class).

### MODIFY

- `app/lib/screens/auth/login_screen.dart` — add cloud sign-in mode +
  invitation-acceptance entry (extract widgets as needed); local mode intact.
- `app/lib/main.dart` — AuthGate branching (fresh-device options; unified
  shell routing per D-L5); logout sequence reused unchanged.
- `app/lib/screens/admin/user_management_screen.dart` — owner entry point to
  InviteEmployeeScreen (canManageUsers-gated).
- `app/lib/screens/auth/accept_invitation_screen.dart` and
  `app/lib/screens/settings/invite_employee_screen.dart` — minimal adaptation
  only (result handling/routing); core logic already implemented.

### VERIFY ONLY

- Sales/products/returns persistence layers (atomicity, permissions, licensing,
  tenant stamps) — no functional change permitted.
- Invoice delivery share/print path on Android.
- ShopResolver rules; cold-start resume; logout sequence.
- All Supabase migrations/RPCs/RLS (read-only consumption).
- Existing suites: tenant_isolation, rbac, cloud, licensing, database,
  migration, sync.

### DO NOT TOUCH

- `supabase/**` (any file), `app/android/**` (no manifest/gradle changes),
  `app/lib/sync/**` (no wiring), `app/lib/database/database_helper.dart`
  schema/version logic, `app/pubspec.yaml` (NO new dependencies),
  ActiveShopContext/TenantIsolationGate semantics, preserved artifacts, stash,
  governing plan documents, Windows installer configuration.

## 17. Test Strategy

- Unit: seller provisioning matrix; upsertCloudUser idempotency/role mapping;
  invitation result mapping; login-mode selection logic.
- Widget: login screen dual-mode; acceptance flow landing; shell permission
  matrix (incl. equivalence check: default salesOnly == today's SalesOnlyShell
  surface set); restricted-state rendering; phone-viewport seller screens.
- Database: full existing database/migration suites (schema untouched proof);
  upsert tests.
- Tenant isolation: existing suite green PLUS new tests proving seller
  login/resume arms isolation and revoked membership fails closed.
- RBAC: existing suite + refresh-after-acceptance.
- Cloud repository/RPC contract: existing cloud tests green (no client changes
  to repositories).
- Accounting integrity: existing atomic-sale/return/stock suites green
  (insertSaleAndDecrementStock race guard, invoice atomicity, return stock
  restoration) — these are the §20 invariant proofs.
- Offline/recovery: §15 table rows exercised at unit level where feasible.
- Windows regression: FULL suite must equal §0.6 baseline (1215 pass; the seven
  classified failures only if they match §0.6 exactly); analyze 0 errors /
  0 warnings.
- Build gates: `flutter build apk --debug` success; Windows build unaffected
  (release-provenance guard tests remain host-specific and stand).

## 18. Acceptance Gates

Machine-verifiable unless marked MANUAL:

1. `flutter analyze`: 0 errors, 0 warnings.
2. `flutter test`: zero NEW failures vs §0.6 baseline; the seven known failures
   only if they reproduce identically to the frozen classification.
3. New seller-flow tests all pass (login matrix, acceptance, shell matrix,
   bootstrap, upsert).
4. Seller cold-start/resume test proves bind + armed isolation + synced
   permissions without interactive login.
5. Revoked-membership fail-closed test passes.
6. Default-salesOnly shell-equivalence test passes (no behavioral surprise).
7. `flutter build apk --debug` succeeds.
8. `git diff --check` clean; commit contains ONLY authorized files.
9. No changes under `supabase/`, `app/android/`, `app/lib/sync/`; schema
   version still 14 (grep-verifiable).
10. MANUAL: emulator walkthrough evidence in implementation report — invite
    employee (owner device) → accept on second device → seller login → browse
    products → create sale → create return → logout → revoke membership →
    relaunch fails closed.

## 19. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R-L1 | Undrained sync_queue accumulates financial records on long-lived seller devices | HIGH | Explicit freeze posture (D-L7/OD-L1); visible sync counters; activation owned by a dedicated decision/phase |
| R-L2 | Shared login/shell changes regress Windows | HIGH | Additive modes; default behavior preserved; full-suite + manual smoke gates |
| R-L3 | Fresh-device ownership hijack via crafted cloud state | MEDIUM-HIGH | Owner-role rejection in seller path (D-L3); server-side membership truth; tests |
| R-L4 | max_devices exhaustion locks out seller devices | MEDIUM | Visible blocked-state UX; documented; owner-manageable via device list |
| R-L5 | Stale local permission cache misleads seller UI while offline | LOW-MEDIUM | Server re-checks every RPC; UI is convenience; documented semantics |
| R-L6 | Invitation Edge Function operational dependency (service_role env) | MEDIUM | Verify deployment config during implementation; graceful errors |
| R-L7 | OD-K1/K2 still undecided | LOW | Placeholders stand; no distribution blocking development |
| R-L8 | Phone-viewport overflow discovered late | LOW | Viewport widget tests mandated in §17 |

## 20. Owner Decisions

### OD-L1 — Sync runtime activation & seller offline-sale policy (OWNER_DECISION_REQUIRED)
- Question: which phase activates SyncEngine (M? dedicated phase?), and is
  offline seller selling commercially acceptable meanwhile (MASTER_PLAN OD7)?
- Why it matters: undrained queues mean seller-created revenue exists only on
  the device until activation; multi-device oversell risk lands in M.
- Recommended default: keep current freeze posture through L; schedule
  sync-activation immediately after M (conflict hardening first).
- Safe placeholder: current behavior (already shipped since J/K).
- Work that can proceed before the decision: ALL of Phase L.
- Blocked release action: commercial multi-device rollout until decided.

### OD-L2 — Carried OD-K1 (Android applicationId/display label) — NOT blocking L
- Recommendation on record: `com.itech.store`. Placeholder stands.

### OD-L3 — Carried OD-K2 (release signing custody) — NOT blocking L
- Blocks distribution only.

### OD-L4 — Cost-price visibility for non-accounting roles (optional future)
- If owners want cost-hidden browsing, requires catalog/UX decision
  (OUT_OF_PHASE_L_SCOPE unless raised). Current screen-level gating documented
  (D-L8).

None of the above blocks planning approval; all have placeholders/fallbacks.

### Recorded non-scope findings (OUT_OF_PHASE_L_SCOPE)
- Returns lack original-sale traceability (data-model limitation; candidate for
  M or owner-driven request) — documented, not fixed.
- Logout does not explicitly suspend the isolation runtime flag (relies on
  unbound-context fail-closed semantics) — verification item V2 below; if
  implementation proves a gap, fix must be scoped explicitly in the L
  implementation report, not done silently here.
- ShopSelectorScreen remains dead code (multi-shop choice UX unowned by any
  phase document so far).
- Seven pre-existing widget-test failures (§0.6 classification).

Verification items for the L implementation session:
- V1: prove seller resume path exercises the exact K D4 helper sequence.
- V2: verify post-logout state (isolation flag vs marker) matches documented
  fail-closed expectations under both platforms; document result.
- V3: verify invite-employee Edge Function environment prerequisites.
- V4: verify max_devices exhaustion messaging end-to-end.
- V5: exercise seller surfaces at ~360dp viewport; adjust padding only if
  overflow proven.

## 21. Implementation Session Contract

The Phase L implementation agent MAY:
- Create exactly the files in §16 CREATE plus narrowly-scoped compiler/test-
  demanded extras (each justified in the implementation report).
- Modify exactly the files in §16 MODIFY.
- Make presentation-level responsive adjustments within §12 limits.
- Add NO new dependencies; touch NO files listed in §16 DO NOT TOUCH.

The Phase L implementation agent MUST:
- Traverse the canonical bind→arm→license→perm-sync sequence on every new
  authentication path (no shortcuts).
- Keep SQLite schema at 14 and make zero Supabase changes.
- Preserve all §20 accounting invariants: atomic sale + stock decrement; no
  negative stock via the race guard; COGS snapshot at sale time never
  recomputed; returns restore stock once, transactionally; duplicate requests
  idempotent; tenant boundaries on every financial record; shop_id never from
  free-form client input; no silent partial writes between SQLite and cloud.
- Pass §18 gates 1–10 and classify every test against §0.6.
- Record answers to verification items V1–V5 in the implementation report.

The Phase L implementation agent MUST NOT:
- Wire SyncEngine/SyncWorker/HydrationService into production (D-L7).
- Add CAMERA permission or scanner packages (D-L9).
- Change role names, permission IDs, frozen identifiers, or installer config.
- Fix the seven pre-existing failures without dedicated scope justification.
- Push, tag, amend, rebase, or deploy anything.
- Touch preserved artifacts or the unrelated stash.

---

*End of Phase L planning artifact. Planning-only; parent of the planning
commit must be 0bb24de96f468bc439a0cf0b65525dfbfe0a5702.*
