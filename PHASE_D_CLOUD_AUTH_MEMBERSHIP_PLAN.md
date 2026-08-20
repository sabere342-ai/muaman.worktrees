# PHASE D: CLOUD AUTH & MEMBERSHIP PLAN

**Phase:** D - Cloud Auth & Membership
**Project:** I Tech Store Management Application
**Institutional Owner:** I Tech for Technology / I Tech for Technology
**Repository:** C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
**Branch:** codex/i-tech-next-roadmap-freeze
**Starting Baseline:** `03956253ff53e242144a8f1aa9676478720d7379`
**Date:** 2026-08-20
**Status:** Planning artifact - not implemented

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | D - Cloud Auth & Membership |
| Session Type | PHASE_D_PLANNING |
| Baseline Commit | `03956253ff53e242144a8f1aa9676478720d7379` |
| Predecessor Phase | C - Cloud Backend Foundation (CLOSED) |
| Successor Phase | E - Licensing & Trial |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Phase C Closure | `PASS_PHASE_C_REMOTE_LOCKED` |

---

## 2. Governing Documents

| # | Document | Precedence | Relevance |
|---|----------|------------|-----------|
| 1 | `PROJECT_MASTER_PLAN.md` | Highest | Section 13 Phase D definition; Section 8 target auth state; Section 9 architecture principles; Section 11 security principles |
| 2 | `PRODUCTIZATION_ARCHITECTURE_PLAN.md` | High | Section 5 Auth & Membership Model; Section 6 Authorization Model; Section 16 Security Architecture; ADR-001 Supabase selection |
| 3 | `PRODUCTIZATION_MIGRATION_PLAN.md` | Medium | Section 2 Pre-migration requirements; Section 4 User identity upload (Step 4) |
| 4 | `PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md` | High | Section 8.4 Database functions; Section 13 Auth trust boundary; Section 14 Authorization model |
| 5 | `PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md` | Medium | Section 8.1 Cloud schema design; Phase B identity mapping foundation |
| 6 | `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | Reference | Verified baseline: 716 tests, schema v9, 12 tables, 18 permissions, 3 roles |

### Governance Precedence

```
1. PROJECT_MASTER_PLAN.md
2. PRODUCTIZATION_ARCHITECTURE_PLAN.md
3. PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md
4. PRODUCTIZATION_MIGRATION_PLAN.md
5. PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md
```

---

## 3. Verified Starting State

### 3.1 Phase C Closure

```
PHASE_C_PLANNING_BASELINE    = b82c4031c210b00185e4e506732dc55ed3bc6ec5
PHASE_C_IMPLEMENTATION_COMMIT = 03956253ff53e242144a8f1aa9676478720d7379
PHASE_C_FINAL_CLOSURE        = COMPLETE
PASS_PHASE_C_REMOTE_LOCKED   = CONFIRMED
```

### 3.2 Git State

```
HEAD                    = 03956253ff53e242144a8f1aa9676478720d7379
Remote branch (github)  = 03956253ff53e242144a8f1aa9676478720d7379
Divergence              = 0 / 0
Tracked worktree        = CLEAN (no modified tracked files)
Index                   = CLEAN (no staged files)
Preserved artifacts     = MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md, delivery/I-TECH-Delivery-v1.0.0.zip
Stash                   = stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration (PRESERVED)
```

### 3.3 Cloud Foundation (Post Phase C)

| Component | Status | Count |
|-----------|--------|-------|
| Cloud tables | Deployed | 7 (`shops`, `shop_members`, `roles`, `role_permissions_cloud`, `devices`, `licenses`, `activations`) |
| RLS policies | Active | 7 (SELECT-only via `shop_members` lookup) |
| Database functions | Created | 5 (`create_shop_with_owner`, `get_user_shops`, `verify_shop_membership`, `start_trial`, `verify_trial_status`) |
| System roles seeded | Yes | 3 (owner->18 perms, employee->11 perms, salesOnly->2 perms) |

### 3.4 Local Schema (v9, post Phase B)

| Property | Value |
|----------|-------|
| Schema version | 9 |
| Tables | 12 (products, sales, returns, expenses, expense_categories, inventory_count, users, import_batches, invoices, app_settings, role_permissions, customers) |
| `shop_id` column | Present (TEXT, nullable) on ALL 12 tables |
| `cloud_uuid` column | Present (TEXT, nullable) on ALL 12 tables |
| `ShopProfile.cloudUuid` | Present, persisted via `app_settings` key `shopProfile.cloudUuid` |
| Tests | 741+ passing (4 pre-existing legacy failures in `standalone_backup_restore_test.dart`) |

### 3.5 Key Architectural Fact

**No Supabase SDK dependency exists in `app/pubspec.yaml`.** The Flutter app is currently 100% local SQLite. Phase D introduces the first Supabase client integration.

---

## 4. Repository Discovery Summary

### 4.1 Key Files Discovered

| File | Lines | Purpose |
|------|-------|---------|
| `app/lib/models/user.dart` | 79 | User model: `id` (int), `displayName`, `username`, `passwordHash`, `role`, `isActive`, timestamps |
| `app/lib/models/user_role.dart` | 56 | UserRole enum: `owner`, `employee`, `salesOnly` |
| `app/lib/database/user_repository.dart` | 333 | CRUD + `authenticate(username, password)` via PBKDF2 |
| `app/lib/services/session_state.dart` | 43 | ChangeNotifier: `User? _currentUser`, `login()`, `logout()`, `hasPermission()` |
| `app/lib/services/permission_resolver.dart` | 93 | Singleton: `can(role, permission)`, owner always gets everything |
| `app/lib/services/permissions.dart` | 264 | 17 `AppPermission` enums with stable IDs, `PermissionCatalog` defaults |
| `app/lib/services/role_permission_repository.dart` | 115 | Persists role->permission config in `role_permissions` table |
| `app/lib/services/password_hasher.dart` | 62 | PBKDF2-HMAC-SHA256, 100K iterations, 16-byte salt |
| `app/lib/models/shop_profile.dart` | 86 | Immutable: `shopName`, `cloudUuid` (nullable) |
| `app/lib/services/shop_profile_repository.dart` | 90 | Persists profile via `app_settings` key-value |
| `app/lib/services/shop_profile_service.dart` | 133 | ChangeNotifier singleton, authorization-gated writes |
| `app/lib/services/app_settings.dart` | 238 | Key-value store over `app_settings` table, 15+ keys |
| `app/lib/database/database_helper.dart` | 1807 | SQLite schema v9, 12 tables, all CRUD, licensing enforcement |
| `app/lib/screens/auth/login_screen.dart` | 210 | Username/password login UI |
| `app/lib/screens/auth/first_owner_setup_screen.dart` | 247 | Bootstrap owner creation (no users exist) |
| `app/lib/main.dart` | 469 | `AuthGate`: init->`FirstOwnerSetupScreen` or `LoginScreen`->role-based shell |

### 4.2 Current Authentication Flow

```
App Start
  -> DatabaseHelper.instance.database (open SQLite)
  -> AppSettings.initializeDefaults()
  -> PermissionResolver.instance.refresh()
  -> ShopProfileService.instance.load()
  -> LicensingService.instance.initialize()
  -> hasAnyUser()?
     NO  -> FirstOwnerSetupScreen -> createUser(owner) -> login
     YES -> LoginScreen
            -> UserRepository.authenticate(username, password)
            -> PasswordHasher.verifyPassword() (PBKDF2)
            -> SessionState.login(user)
            -> Role-based shell (FullAppShell or SalesOnlyShell)
```

### 4.3 Cloud UUID Foundation (Phase B)

| Location | Field | Purpose |
|----------|-------|---------|
| ALL 12 local tables | `cloud_uuid TEXT` | Maps local row -> cloud UUID |
| ALL 12 local tables | `shop_id TEXT` | Maps local row -> cloud shop UUID |
| `ShopProfile` model | `cloudUuid` | Shop's cloud identity |
| `app_settings` | `shopProfile.cloudUuid` | Persisted shop cloud UUID |
| `users` table | `cloud_uuid` | Will store Supabase `auth.uid()` |
| `users` table | `shop_id` | Will store user's primary shop UUID |

---

## 5. Current Local Authentication Architecture

### 5.1 User Model

```dart
// app/lib/models/user.dart
class User {
  final int? id;            // Local integer PK
  final String displayName;
  final String username;    // UNIQUE, normalized lowercase
  final String passwordHash;// PBKDF2-HMAC-SHA256
  final UserRole role;      // owner | employee | salesOnly
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
}
```

**Phase D addition:** No new columns needed. `users.cloud_uuid` (from Phase B v9 migration) stores the Supabase `auth.uid()`. `users.shop_id` stores the primary cloud shop UUID.

### 5.2 UserRepository

```dart
// app/lib/database/user_repository.dart
class UserRepository {
  Future<int> createUser({required displayName, username, password, role, ...});
  Future<User?> authenticate(String username, String password);  // PBKDF2 verify
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(int id);
  Future<User?> getUserByUsername(String username);
  Future<bool> hasAnyUser();
  Future<int> updateUser({required id, ...});
  Future<void> resetPassword({required id, newPassword, ...});
  Future<void> updateLastLogin(int userId);
}
```

### 5.3 PasswordHasher

```dart
// app/lib/services/password_hasher.dart
// PBKDF2-HMAC-SHA256, 100K iterations, 16-byte salt, 32-byte key
// Format: base64(salt):base64(hash)
```

### 5.4 SessionState

```dart
// app/lib/services/session_state.dart
class SessionState extends ChangeNotifier {
  User? _currentUser;
  void login(User user);        // Sets user, notifyListeners
  void logout();                // Clears user, notifyListeners
  bool hasPermission(AppPermission p);  // Delegates to PermissionResolver
}
```

### 5.5 Key Architectural Constraints

- **Owner always gets all permissions** - `PermissionResolver.effectivePermissions(owner)` returns `PermissionCatalog.allPermissions`
- **Offline-first** - all auth works without network
- **Username-based** - current login uses `username`, not `email`
- **PBKDF2 hashes sacred** - must never be uploaded, reversed, or destroyed

---

## 6. Current Phase C Cloud Foundation

### 6.1 Cloud Schema

```sql
shops (id UUID PK, name TEXT, owner_user_id UUID FK->auth.users, settings JSONB)
shop_members (id UUID PK, shop_id UUID FK->shops, user_id UUID FK->auth.users, role TEXT, status TEXT, invited_at, joined_at)
roles (id UUID PK, shop_id UUID FK->shops, name TEXT, is_system BOOLEAN)
role_permissions_cloud (id UUID PK, role_id UUID FK->roles, permission_id TEXT)
devices (id UUID PK, installation_id UUID, shop_id UUID FK->shops, user_id UUID, platform TEXT, status TEXT)
licenses (id UUID PK, shop_id UUID FK->shops, license_key TEXT UNIQUE, status TEXT, trial/expires timestamps)
activations (id UUID PK, license_id UUID FK->licenses, device_id UUID FK->devices, status TEXT)
```

### 6.2 Database Functions (Phase D Relevant)

```sql
-- Phase D dependency: YES
create_shop_with_owner(p_name TEXT) -> UUID
  -- SECURITY DEFINER, requires auth.uid()
  -- Creates shop + owner shop_member + seeds 3 system roles

-- Phase D dependency: YES
get_user_shops() -> TABLE(shop_id, shop_name, owner_user_id, membership_role, membership_status, created_at)
  -- SECURITY DEFINER, requires auth.uid()
  -- Returns only ACTIVE memberships

-- Phase D dependency: NO (Phase F)
verify_shop_membership(p_shop_id UUID) -> BOOLEAN

-- Phase D dependency: NO (Phase E)
start_trial(p_shop_id UUID) -> UUID
verify_trial_status(p_shop_id UUID) -> TABLE(...)
```

### 6.3 RLS Policies

All 7 tables have SELECT-only RLS policies that check `shop_members` for `auth.uid()` with `status = 'ACTIVE'`. INSERT/UPDATE/DELETE are service-role only (no client policies).

### 6.4 Supabase Auth Configuration (config.toml)

```toml
[auth]
enabled = true
site_url = "http://localhost:3000"
additional_redirect_urls = ["https://localhost:3000"]
jwt_expiry = 3600
enable_refresh_token_rotation = true
enable_signup = true

[auth.email]
enable_signup = true
double_confirm_changes = true
enable_confirmations = false  # Dev: no email confirmation required
```

---

## 7. Phase D Objective

Establish cloud identity and membership for the I Tech Store Management Application:

- Owner account creation and cloud onboarding
- Employee/seller invitation via cloud email identity
- Cloud login/logout with Supabase Auth
- Cloud/local identity linking (additive, non-destructive)
- Shop membership lifecycle (INVITED -> ACTIVE -> SUSPENDED/REVOKED)
- Coarse role assignment (owner/employee/salesOnly)
- Offline PBKDF2 authentication preservation

**Phase D does NOT include:** licensing/trial (Phase E), server-enforced 18-permission RBAC (Phase F), cloud CRUD (Phase G), sync (Phase H), legacy migration (Phase I), Windows transition (Phase J), Android (Phase K/L).

---

## 8. In Scope

| # | Deliverable | Type |
|---|-------------|------|
| 1 | `supabase_flutter` SDK integration | Dependency |
| 2 | Environment configuration for Supabase URL + anon key | Config |
| 3 | `CloudAuthService` - Supabase Auth wrapper | New service |
| 4 | `CloudSession` - cloud auth session model | New model |
| 5 | Extended `SessionState` with cloud context | Modify |
| 6 | Extended `UserRepository` for cloud identity linking | Modify |
| 7 | `CloudOnboardingService` - owner cloud signup/linking | New service |
| 8 | Owner cloud linking screen (existing installations) | New screen |
| 9 | Fresh owner cloud onboarding (extend `FirstOwnerSetupScreen`) | Modify |
| 10 | Cloud login flow (extend `LoginScreen`) | Modify |
| 11 | Employee invitation Edge Function | New server-side |
| 12 | Employee invitation UI (owner manages invitations) | New screen |
| 13 | Membership display and management UI | New/Modify screen |
| 14 | Multi-shop selector (when user belongs to multiple shops) | New widget |
| 15 | `AppSettings` additions for cloud auth state persistence | Modify |
| 16 | Unit tests for cloud auth services | New tests |
| 17 | Unit tests for identity linking | New tests |
| 18 | Unit tests for membership resolution | New tests |

---

## 9. Explicit Out of Scope

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | `start_trial()` integration | Phase E | Licensing boundary |
| 2 | `verify_trial_status()` integration | Phase E | Licensing boundary |
| 3 | License activation flow | Phase E | Licensing boundary |
| 4 | 14-day trial UI | Phase E | Licensing boundary |
| 5 | Full 18-permission server RBAC | Phase F | Permission enforcement boundary |
| 6 | Permission mutation cloud sync | Phase F | RBAC boundary |
| 7 | `verify_shop_membership()` client use | Phase F | Permission integration |
| 8 | Cloud CRUD business data | Phase G | Data boundary |
| 9 | Cloud data models (Dart) | Phase G | Data boundary |
| 10 | Sync queue implementation | Phase H | Sync boundary |
| 11 | Offline pending-write queue | Phase H | Sync boundary |
| 12 | Legacy data cloud migration | Phase I | Migration boundary |
| 13 | Local schema changes (beyond app_settings) | N/A | Phase B v9 already prepared everything |
| 14 | Password reset / account recovery | See Section 24 | Classified separately |
| 15 | Real Supabase production project creation | Later session | No deployment in planning |
| 16 | Edge Function deployment | Implementation session | Planned but not deployed in planning |
| 17 | `git push` or remote operations | Separate session | Never in planning |

---

## 10. Architecture Decisions

### ADR-D01: Supabase Flutter SDK Selection

**Decision:** Use `supabase_flutter` package (wraps `supabase` Dart package + `http` client).

**Rationale:**
- Official Supabase Flutter SDK
- Handles session persistence via `SharedPreferences`
- Handles token refresh automatically
- Supports `authStateChanges` stream
- Works on Windows and Android
- Already selected in ADR-001 for the backend

**Risk:** SDK version compatibility with Flutter 3.5.x. Verify latest stable version supports the project's Dart SDK constraint (`^3.5.4`).

### ADR-D02: Dual Authentication Path Architecture

**Decision:** Maintain two parallel authentication paths with identity linking.

```
+-------------------------------------------+
|          Authentication Gate              |
|                                           |
|  Path A: Online (Cloud)                   |
|  +-- Supabase Auth email/password         |
|  +-- Session via JWT                      |
|  +-- get_user_shops() for membership      |
|  +-- Cloud authority                      |
|                                           |
|  Path B: Offline (Local)                  |
|  +-- PBKDF2 username/password             |
|  +-- Session via in-memory User           |
|  +-- Local role_permissions               |
|  +-- Governed fallback                    |
|                                           |
|  Identity Link: users.cloud_uuid <-> auth.uid() |
|  Shop Link: ShopProfile.cloudUuid <-> shops.id  |
+-------------------------------------------+
```

**Rationale:**
- Existing customers have local users that must continue working
- PBKDF2 hashes are sacred - never uploaded or replaced
- Offline capability is a core product principle (Master Plan 4.4)
- Cloud becomes primary authority when online
- Local remains governed fallback when offline

### ADR-D03: Email as Cloud Identity

**Decision:** Supabase Auth uses email/password for cloud identity. Local username-based login is preserved for offline.

**Rationale:**
- Supabase Auth is email-native
- Employee invitations require email delivery (Master Plan Decision D9)
- Local `username` is not tied to email - they coexist
- A local user's `cloud_uuid` links to their Supabase `auth.users.id` which uses email

**Implication:** A local user may have a different `username` (local) than their cloud `email`. These are distinct identity domains.

### ADR-D04: SessionState Extension Strategy

**Decision:** Extend `SessionState` to carry cloud context alongside existing local user.

```dart
class SessionState extends ChangeNotifier {
  User? _currentUser;              // EXISTING - local user
  CloudSession? _cloudSession;     // NEW - cloud auth context
  
  bool get isCloudLinked => _cloudSession != null;
  bool get isOnline => _cloudSession?.isActive ?? false;
  String? get cloudUserId => _cloudSession?.userId;
  String? get activeShopId => _cloudSession?.activeShopId;
}
```

**Rationale:**
- Minimal change to existing architecture
- Cloud session is additive - does not replace local user
- Existing `hasPermission()` continues to work via `PermissionResolver`
- Cloud context enables Phase F server-side permission queries later

### ADR-D05: No Local SQLite Schema Change in Phase D

**Decision:** Phase D does NOT add any new columns or tables to the local SQLite database.

**Rationale:**
- Phase B v9 migration already added `cloud_uuid TEXT` and `shop_id TEXT` to ALL 12 tables
- `users.cloud_uuid` is the natural home for `auth.uid()`
- `ShopProfile.cloudUuid` stores the shop's cloud UUID
- `app_settings` key-value store handles additional cloud auth state
- No schema change = zero migration risk for existing customers

### ADR-D06: Employee Invitation via Edge Function

**Decision:** Employee invitations execute via a Supabase Edge Function that uses the service-role key server-side.

**Rationale:**
- Supabase Auth Admin API (user invitation, user creation) requires the service-role key
- Service-role key MUST NEVER be in the Flutter client binary (Master Plan 11.1)
- Edge Functions execute server-side with service-role privileges
- Edge Functions are the standard Supabase mechanism for trusted server operations

**Architecture:**
```
Flutter Client -> calls Edge Function (with user's JWT)
Edge Function -> validates JWT, checks owner membership
              -> calls Supabase Admin API (invite user)
              -> creates shop_member record with INVITED status
              -> returns success/failure to client
```

### ADR-D07: Offline Grace Policy - OWNER DECISION REQUIRED

**Decision:** Phase D implements the offline fallback infrastructure but does NOT define the offline grace duration.

**Rationale:**
- Owner Decision OD4 ("Offline grace duration") is unresolved in `PROJECT_MASTER_PLAN.md` Section 6
- Phase D cannot invent a security-relevant value
- The offline fallback works with cached membership state
- Phase H sync architecture will define the complete offline policy

**Phase D offline behavior:**
- Known linked owner can authenticate locally offline
- Membership state is cached from last successful cloud login
- Stale membership is flagged but not silently accepted
- Revoked membership is detected on next online sync

### ADR-D08: Multi-Shop Initial Behavior

**Decision:** Phase D supports multi-shop membership at the data level but implements single active shop selection.

**Behavior:**
- `get_user_shops()` returns all active memberships
- If 0 shops: prompt owner to create shop (first onboarding) or show "no active shop" error
- If 1 shop: automatically select as active shop
- If 2+ shops: show shop selector widget, remember last selected in `app_settings`
- Shop selection is local preference, not cloud state

### ADR-D09: Same Password for Local and Cloud (Owner)

**Decision:** For owner onboarding, use the SAME password for both local PBKDF2 and Supabase Auth.

**Rationale:**
- Simpler UX for the owner during initial setup
- Local PBKDF2 hash is never uploaded - it remains for offline fallback only
- The plaintext password goes to Supabase Auth (server-side bcrypt) and to local PBKDF2 (client-side)
- If owner later changes cloud password, local password remains unchanged (offline fallback preserved)

**Risk:** If owner forgets the shared password, both local and cloud login fail. Mitigated by same recovery flow.

---

## 11. Supabase Client Integration

### 11.1 Package Addition

Add to `app/pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.8.0  # Verify latest compatible version
```

This pulls in `supabase` (Dart client), `gotrue` (auth), `postgrest` (DB), `realtime`, and `storage` clients.

### 11.2 Initialization

In `main()`, before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Existing: sqflite FFI initialization
  if (defaultTargetPlatform == TargetPlatform.windows || ...) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // NEW: Supabase initialization
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  runApp(const MyApp());
}
```

### 11.3 Environment Loading Strategy

- `SUPABASE_URL` and `SUPABASE_ANON_KEY` injected via `--dart-define` at build time
- No secrets in source code, `.env` files bundled into binary, or committed files
- `.env.example` (existing) documents required variables
- Development: `supabase start` local instance provides URL + anon key
- Production: real Supabase project URL + anon key (set during deployment)

### 11.4 Windows + Android Compatibility

- `supabase_flutter` supports both platforms
- Session persistence: uses `SharedPreferences` (works on both)
- HTTP client: uses `http` package (already a dependency)
- No platform-specific code needed for Supabase integration

### 11.5 Auth State Observation

```dart
Supabase.instance.client.auth.onAuthStateChange.listen((event) {
  final session = event.session;
  final eventType = event.event;
  // Handle: signedIn, signedOut, tokenRefreshed, passwordRecovery, etc.
});
```

### 11.6 Dependency Injection Boundary

```dart
// Cloud auth service accepts a SupabaseClient for testability
class CloudAuthService {
  final GoTrueClient _auth;
  final PostgrestClient _db;
  CloudAuthService({GoTrueClient? authClient, PostgrestClient? dbClient})
    : _auth = authClient ?? Supabase.instance.client.auth,
      _db = dbClient ?? Supabase.instance.client.from('shops');
}
```

Tests provide fake/mock `GoTrueClient` and `PostgrestClient`.

---

## 12. Existing Owner Cloud Linking

### 12.1 Trigger

After a successful local PBKDF2 login, the app checks `ShopProfile.cloudUuid`:
- If `null` -> owner has no cloud link -> offer cloud linking
- If non-null -> owner has cloud link -> attempt cloud session

### 12.2 Cloud Linking Flow

```
Existing local owner
  -> authenticates locally (PBKDF2)
  -> app checks ShopProfile.cloudUuid
  -> if null: show "Connect to Cloud" dialog
     -> owner enters: email, password (for cloud account)
     -> app calls: auth.signUp(email: email, password: password)
     -> on success:
        -> app calls: rpc('create_shop_with_owner', params: {'p_name': shopName})
        -> receives: cloud shop UUID
        -> persists locally:
           -> AppSettings.setValue('shopProfile.cloudUuid', shopUuid)
           -> UPDATE users SET cloud_uuid = <auth.uid>(), shop_id = shopUuid WHERE id = localUserId
        -> creates CloudSession
        -> app enters cloud-aware mode
     -> on failure:
        -> if "user already exists": owner already has cloud account elsewhere
           -> prompt: "This email is already registered. Log in to link."
           -> alternative flow: sign in with existing cloud account -> link to this local user
        -> if network error: retry or defer
  -> if non-null: attempt cloud session (see Section 14)
```

### 12.3 Identity Proof

The linking is secure because:
1. User must first authenticate locally (PBKDF2) - proves local ownership
2. User then provides email + password for cloud account creation - establishes cloud identity
3. The cloud `auth.uid()` is stored in `users.cloud_uuid` for the authenticated local user
4. No other local user can claim the same cloud UUID (single-device initial linking; Phase H enforces globally)

### 12.4 Duplicate Prevention

- If `users.cloud_uuid` already has a value for ANY local user -> linking already done
- If the Supabase email is already registered -> sign-in flow instead of sign-up
- If the cloud shop already exists for this email -> `get_user_shops()` returns it; no double `create_shop_with_owner` call

### 12.5 Interrupted Onboarding Recovery

| State | Detection | Recovery |
|-------|-----------|----------|
| Cloud account created, shop not created | `auth.uid()` exists but `get_user_shops()` returns empty | Call `create_shop_with_owner()` |
| Shop created, local mapping failed | `ShopProfile.cloudUuid` is null but cloud shop exists | Query `get_user_shops()`, re-persist locally |
| Local mapping exists, cloud membership missing | `ShopProfile.cloudUuid` is set but membership not found | Re-call `create_shop_with_owner()` or investigate |
| Partial state on restart | `AuthGate._initialize()` re-runs, detects incomplete state | Resumes linking |

### 12.6 Idempotency

- `create_shop_with_owner()` is called once per shop creation. PostgreSQL UNIQUE constraint on `shop_members(shop_id, user_id)` prevents duplicate membership.
- Calling `create_shop_with_owner()` twice creates TWO shops. Prevention: check `get_user_shops()` before calling.
- Local `AppSettings.setValue` is an upsert - safe to retry.

---

## 13. Fresh Owner Onboarding

### 13.1 Flow

```
First launch (no local users)
  -> FirstOwnerSetupScreen
  -> User enters: display name, username, password, email
  -> LOCAL: createUser(displayName, username, password, role: owner)
  -> CLOUD: auth.signUp(email: email, password: password)
  -> CLOUD: rpc('create_shop_with_owner', params: {'p_name': shopName})
  -> receives: cloud shop UUID
  -> LOCAL: store cloud_uuid in users row
  -> LOCAL: AppSettings.setValue('shopProfile.cloudUuid', shopUuid)
  -> SessionState.login(user) + CloudSession created
  -> App enters cloud-aware mode
```

### 13.2 Extended FirstOwnerSetupScreen

The current `FirstOwnerSetupScreen` collects: `displayName`, `username`, `password`, `confirmPassword`.

Phase D extends it to also collect:
- `email` field (for Supabase Auth cloud account)
- Reuses the same password for both local and cloud (ADR-D09)

### 13.3 Error Handling

| Error | Handling |
|-------|----------|
| Cloud signup fails (network) | Complete local setup, defer cloud linking, show "Connect to Cloud later" |
| Cloud signup fails (email taken) | Prompt: use different email or sign in to link existing account |
| `create_shop_with_owner()` fails | Retry; if persistent, complete local setup and retry on next launch |
| Local createUser fails | Block entire flow (existing behavior) |

### 13.4 Graceful Degradation

If cloud operations fail during fresh onboarding:
1. Local user is created successfully
2. App functions fully in offline mode
3. Cloud linking is offered on subsequent launches
4. No data loss, no rollback needed

---

## 14. Online Login Flow

### 14.1 Cloud-Aware Login

When `ShopProfile.cloudUuid` is non-null (owner has been cloud-linked):

```
LoginScreen
  -> user enters username + password
  -> LOCAL: UserRepository.authenticate(username, password) [PBKDF2]
  -> if local auth succeeds:
     -> check ShopProfile.cloudUuid
     -> if cloud-linked:
        -> attempt cloud login:
           -> auth.signInWithPassword(
               email: cloudEmail,  // stored in app_settings
               password: password  // same as local password
             )
           -> on success:
              -> get_user_shops() -> resolve active membership
              -> create CloudSession(userId, activeShopId, membershipRole, membershipStatus)
              -> SessionState.login(user) + set cloudSession
           -> on failure (network):
              -> fall back to local-only session
              -> show "Working offline" indicator
           -> on failure (invalid credentials):
              -> show "Cloud password mismatch - use local login only"
     -> if not cloud-linked:
        -> local-only session (existing behavior)
```

### 14.2 Email for Cloud Login

**Problem:** Current login uses `username` (not email). Supabase Auth uses `email`.

**Solution:** Store the cloud email in `app_settings`:

```
Key: 'cloud.auth.email'
Value: the email used for Supabase Auth signup
```

This is NOT a secret - it is the user's own email stored locally for convenience. The user may also re-enter it.

### 14.3 get_user_shops() Resolution

```dart
final response = await Supabase.instance.client.rpc('get_user_shops');
// Returns: [{shop_id, shop_name, owner_user_id, membership_role, membership_status, created_at}, ...]

if (response.isEmpty) {
  // User has no active shop memberships -> error or prompt to create shop
}
if (response.length == 1) {
  // Auto-select the only shop
  activeShopId = response[0]['shop_id'];
}
if (response.length > 1) {
  // Show shop selector (see Section 25)
}
```

### 14.4 Membership Validation

```dart
final membership = response.firstWhere(
  (r) => r['shop_id'] == activeShopId,
  orElse: () => throw StateError('No active membership for selected shop'),
);

if (membership['membership_status'] != 'ACTIVE') {
  // Handle SUSPENDED/REVOKED (see Section 21)
}
```

---

## 15. Session Restoration

### 15.1 App Restart Sequence

```
App Start
  -> DatabaseHelper.instance.database
  -> AppSettings.initializeDefaults()
  -> PermissionResolver.instance.refresh()
  -> ShopProfileService.instance.load()  // loads cloudUuid
  -> LicensingService.instance.initialize()
  -> Supabase.instance.client.auth.currentSession  // check persisted session
     -> if session valid (not expired):
        -> CloudSession restored from persisted session
        -> get_user_shops() to refresh membership
     -> if session expired:
        -> attempt token refresh (automatic via SDK)
        -> if refresh fails: cloud session = null, offline mode
  -> hasAnyUser()?
     NO  -> FirstOwnerSetupScreen
     YES -> check cloud session state
        -> if cloud session active: proceed to role-based shell with cloud context
        -> if no cloud session: LoginScreen (local auth)
```

### 15.2 Token Refresh

`supabase_flutter` handles token refresh automatically when `enable_refresh_token_rotation = true` (configured in Phase C `config.toml`). The client SDK refreshes the JWT before expiry using the refresh token.

If refresh fails:
- Cloud session becomes null
- App falls back to local-only mode
- User sees "Working offline" indicator
- On next successful refresh, cloud context is restored

---

## 16. Offline Authentication Compatibility

### 16.1 Offline Fallback Conditions

Offline fallback is permitted when ALL of:
1. Network is unavailable (Supabase unreachable)
2. User has a local PBKDF2-authenticated account
3. User has a known cloud identity link (`users.cloud_uuid` is set)
4. User had a previous successful cloud login on this installation

### 16.2 Offline Login Flow

```
LoginScreen -> user enters username + password
  -> UserRepository.authenticate(username, password) [PBKDF2]
  -> if local auth succeeds:
     -> SessionState.login(user) -- local-only session
     -> CloudSession = null (no cloud context)
     -> ShopProfile.cloudUuid may be set (from previous linking)
     -> App functions in offline mode
     -> UI shows offline indicator
```

### 16.3 Offline Limitations

| Capability | Offline Status |
|------------|---------------|
| Local CRUD (products, sales, etc.) | FULLY AVAILABLE (existing) |
| Cloud data queries | UNAVAILABLE |
| Employee invitation | UNAVAILABLE |
| Membership changes | UNAVAILABLE (cached from last sync) |
| License verification | UNAVAILABLE (Phase E concern) |
| Cloud permission sync | UNAVAILABLE (Phase F concern) |

### 16.4 Stale Membership Risk

If a user's membership is REVOKED or SUSPENDED while offline:
- The local cached session still works
- On next online connection, `get_user_shops()` will not return the revoked membership
- The app should detect this and invalidate the cloud session
- **Acknowledged risk:** indefinite offline access after revocation - addressed by Phase H sync/offline architecture and Owner Decision OD4

### 16.5 Offline Logout

```
Offline logout:
  -> SessionState.logout() clears _currentUser
  -> CloudSession cleared
  -> No Supabase API call (network unavailable)
  -> Identity mapping (users.cloud_uuid, ShopProfile.cloudUuid) RETAINED
  -> Local data PRESERVED
```

### 16.6 Unresolved: Offline Grace Duration

Owner Decision OD4 ("Offline grace duration") remains OPEN.

Phase D does not invent a value. The offline fallback infrastructure is in place, but the maximum time a revoked user can operate offline without detection is deferred to:
- Phase H (sync architecture)
- Owner Decision OD4 resolution

---

## 17. Logout Flow

### 17.1 Online Logout

```
User presses Logout
  -> Supabase.instance.client.auth.signOut()  // invalidates JWT + refresh token server-side
  -> SessionState.logout()                    // clears _currentUser from memory
  -> CloudSession = null                      // clears cloud context from memory
  -> setState() triggers AuthGate rebuild     // shows LoginScreen
```

### 17.2 State Cleared vs Retained

| State | Cleared? | Reason |
|-------|----------|--------|
| `SessionState._currentUser` | YES (memory) | Session end |
| `CloudSession` | YES (memory) | Session end |
| Supabase JWT/refresh token | YES (SDK clears persisted tokens) | Server-side invalidation |
| `users.cloud_uuid` | NO | Identity mapping - needed for re-login |
| `users.shop_id` | NO | Identity mapping - needed for re-login |
| `ShopProfile.cloudUuid` | NO | Shop identity - needed for re-login |
| `app_settings` cloud keys | NO | Non-secret metadata - needed for re-login |
| Local PBKDF2 password hash | NO | Offline fallback - sacred |
| Local user data | NO | Business data - sacred |
| `PermissionResolver` cache | Optionally refresh | Permissions unchanged |

### 17.3 Offline Logout

```
Offline logout:
  -> SessionState.logout() clears _currentUser
  -> No Supabase call possible
  -> All persistent state retained (same as online)
```
---

## 18. Identity Mapping (Cloud â†” Local)

### 18.1 Linkage Points

Three identity linkage points connect local and cloud domains:

| Linkage | Local Location | Cloud Location | Direction |
|---------|---------------|----------------|-----------|
| Owner identity | `users.cloud_uuid` (TEXT nullable, all 12 tables) | `auth.users.id` (UUID) | Local â†’ Cloud |
| Shop identity | `ShopProfile.cloudUuid` (via `app_settings`) | `shops.id` (UUID) | Bidirectional |
| Email identity | `app_settings['cloud.auth.email']` | `auth.users.email` | Local â†’ Cloud |

### 18.2 Linkage Lifecycle

```
FIRST TIME (Owner Onboarding):
  1. Local owner exists (PBKDF2 auth)
  2. User enters email + password for cloud
  3. auth.signUp() -> cloud user created (UUID)
  4. create_shop_with_owner() -> shop + membership created
  5. UPDATE users SET cloud_uuid = ? WHERE id = ?
  6. UPDATE app_settings SET value = ? WHERE key = 'shopProfile.cloudUuid'
  7. INSERT app_settings (cloud.auth.email) = email
  -> All three linkage points SET

SUBSEQUENT LOGINS:
  1. Check ShopProfile.cloudUuid != null -> cloud-linked
  2. Read cloud.email from app_settings
  3. auth.signInWithPassword(email, password)
  4. Cloud session established

RELINKING (if cloud session lost):
  1. Local auth succeeds
  2. cloud_uuid still set in users table
  3. Offer "Reconnect to cloud" option
  4. auth.signInWithPassword() with stored email
  5. Cloud session restored
```

### 18.3 Linkage Integrity Rules

| Rule | Enforcement |
|------|-------------|
| `users.cloud_uuid` is immutable once set | Application code: no UPDATE after initial set |
| `ShopProfile.cloudUuid` is immutable once set | Application code: no overwrite |
| Cloud UUID must be valid UUID format | Validation at write time |
| Linkage is NEVER deleted | No DELETE from users.cloud_uuid; offline logout retains |

### 18.4 Data Model (No Schema Changes)

Phase D does NOT add new SQLite columns. All linkage uses existing v9 schema:

- `users.cloud_uuid` (TEXT, nullable) - already exists from Phase B
- `app_settings` key-value pairs - already exists from Phase B
- `ShopProfile.cloudUuid` - already exists from Phase B

---

## 19. Shop Resolution (Multi-Shop)

### 19.1 Resolution Algorithm

```dart
Future<int> resolveActiveShop() async {
  final response = await Supabase.instance.client.rpc('get_user_shops');
  final shops = List<Map<String, dynamic>>.from(response);

  if (shops.isEmpty) {
    // User has no shop memberships
    throw StateError('No shop memberships found');
  }

  if (shops.length == 1) {
    // Auto-select the only shop
    return shops[0]['shop_id'];
  }

  // Multiple shops: check last-used preference
  final lastShopId = await AppSettings.get('cloud.lastShopId');
  if (lastShopId != null) {
    final match = shops.where((s) => s['shop_id'].toString() == lastShopId);
    if (match.isNotEmpty) return match.first['shop_id'];
  }

  // No last-used or invalid: show selector dialog
  return _showShopSelector(shops);
}
```

### 19.2 Shop Selector Dialog

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  Select Shop                        â”‚
â”‚                                     â”‚
â”‚  â—‹ I Tech Main Store                â”‚
â”‚    Owner: John Doe                  â”‚
â”‚    Role: owner                      â”‚
â”‚                                     â”‚
â”‚  â—‹ I Tech Branch                    â”‚
â”‚    Owner: John Doe                  â”‚
â”‚    Role: employee                   â”‚
â”‚                                     â”‚
â”‚  [Cancel]                           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 19.3 Last-Used Persistence

```dart
// After shop selection:
await AppSettings.set('cloud.lastShopId', selectedShopId.toString());

// On next login:
final lastShopId = await AppSettings.get('cloud.lastShopId');
```

### 19.4 Shop Switching (In-Session)

During Phase D, shop switching is NOT supported. The user must logout and login again to switch shops. Shop switching is a Phase F concern.

---

## 20. Invitation Architecture

### 20.1 Overview

Owner invites employees via cloud. Employee accepts invitation, creates local account, and is linked to the shop.

### 20.2 Invitation Flow

```
OWNER (online):
  1. Owner opens "Invite Employee" screen
  2. Enters: email, display name, role (employee/salesOnly)
  3. Client calls Edge Function: invite-employee
  4. Edge Function (service-role):
     a. auth.admin.createUser({ email, email_confirm: true })
     b. INSERT INTO shop_members (shop_id, user_id, role, status='PENDING')
     c. INSERT INTO invitations (shop_id, email, role, status='PENDING', expires_at)
     d. Send invitation email (future SMTP integration)
  5. Return success to owner

EMPLOYEE (first time):
  1. Receives invitation email (or manual notification)
  2. Opens app -> FirstOwnerSetupScreen (or new "Accept Invitation" screen)
  3. Enters: email, password, display name
  4. Client calls auth.signUp() or auth.signInWithPassword()
  5. Client calls accept_invitation() RPC
  6. RPC updates shop_members status='ACTIVE'
  7. Employee can now access shop data
```

### 20.3 Edge Function: `invite-employee`

```typescript
// supabase/functions/invite-employee/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Verify caller is shop owner
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { shop_id, email, display_name, role } = await req.json()

  // 1. Create auth user
  const { data: authUser, error: authError } = await supabase.auth.admin
    .createUser({ email, email_confirm: true })

  if (authError) throw authError

  // 2. Create shop membership (PENDING)
  const { error: memberError } = await supabase
    .from('shop_members')
    .insert({
      shop_id,
      user_id: authUser.id,
      role,
      status: 'PENDING'
    })

  if (memberError) throw memberError

  // 3. Create invitation record
  const { error: inviteError } = await supabase
    .from('invitations')
    .insert({
      shop_id,
      email,
      role,
      invited_by: req.headers.get('Authorization'),
      status: 'PENDING',
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    })

  if (inviteError) throw inviteError

  // 4. TODO: Send invitation email (Phase H)
  // await sendInvitationEmail(email, shop_name, invitation_token)

  return new Response(
    JSON.stringify({ success: true, user_id: authUser.id }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

### 20.4 New Database Function: `accept_invitation`

```sql
CREATE OR REPLACE FUNCTION accept_invitation(
  p_shop_id UUID,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_member RECORD;
BEGIN
  -- Find pending invitation
  SELECT * INTO v_member
  FROM shop_members
  WHERE shop_id = p_shop_id
    AND user_id = p_user_id
    AND status = 'PENDING';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'No pending invitation found');
  END IF;

  -- Activate membership
  UPDATE shop_members
  SET status = 'ACTIVE', joined_at = NOW()
  WHERE shop_id = p_shop_id AND user_id = p_user_id;

  -- Update invitation status
  UPDATE invitations
  SET status = 'ACCEPTED', accepted_at = NOW()
  WHERE shop_id = p_shop_id AND email = (
    SELECT email FROM auth.users WHERE id = p_user_id
  );

  RETURN jsonb_build_object('success', true);
END;
$$;
```

### 20.5 New Table: `invitations`

```sql
CREATE TABLE invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('employee', 'salesOnly')),
  invited_by UUID REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL
);

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop owners can view invitations"
  ON invitations FOR SELECT
  USING (
    shop_id IN (
      SELECT shop_id FROM shop_members
      WHERE user_id = auth.uid() AND role = 'owner' AND status = 'ACTIVE'
    )
  );

CREATE POLICY "Service role can insert invitations"
  ON invitations FOR INSERT
  WITH CHECK (true);  -- Edge Function uses service-role
```

---

## 21. Membership Lifecycle

### 21.1 Status State Machine

```
PENDING -> ACTIVE (on accept_invitation)
ACTIVE -> SUSPENDED (owner suspends)
SUSPENDED -> ACTIVE (owner reactivates)
ACTIVE -> REVOKED (owner removes employee)
REVOKED -> (terminal, no reactivation)
```

### 21.2 Status Transitions

| Transition | Trigger | Actor | RPC/Function |
|-----------|---------|-------|--------------|
| PENDING â†’ ACTIVE | Employee accepts invitation | Employee | `accept_invitation()` |
| ACTIVE â†’ SUSPENDED | Owner suspends employee | Owner | Direct UPDATE via Edge Function |
| SUSPENDED â†’ ACTIVE | Owner reactivates employee | Owner | Direct UPDATE via Edge Function |
| ACTIVE â†’ REVOKED | Owner removes employee | Owner | Direct UPDATE via Edge Function |

### 21.3 Status Effects

| Status | Can Login | Can Access Data | Can Be Invited Again |
|--------|-----------|-----------------|---------------------|
| PENDING | NO (no local account yet) | NO | N/A |
| ACTIVE | YES | YES (per role permissions) | N/A |
| SUSPENDED | NO (login blocked) | NO (cached data may be stale) | N/A |
| REVOKED | NO (login blocked) | NO (cached data may be stale) | NO |

### 21.4 Owner Cannot Remove Themselves

The `shop_members` table enforces at least one owner per shop:

```sql
-- Prevent removing the last owner
CREATE OR REPLACE FUNCTION prevent_last_owner_removal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.role = 'owner' THEN
    IF (SELECT COUNT(*) FROM shop_members WHERE shop_id = OLD.shop_id AND role = 'owner' AND status = 'ACTIVE') <= 1 THEN
      RAISE EXCEPTION 'Cannot remove the last owner of a shop';
    END IF;
  END IF;
  RETURN OLD;
END;
$$;

CREATE TRIGGER check_last_owner
  BEFORE DELETE ON shop_members
  FOR EACH ROW
  EXECUTE FUNCTION prevent_last_owner_removal();
```

---

## 22. Role Boundary (Local vs Cloud)

### 22.1 Permission Sources

| Source | Scope | Phase |
|--------|-------|-------|
| Local `role_permissions` table | SQLite, per-device | Phase A (existing) |
| Cloud `role_permissions_cloud` table | Supabase, per-shop | Phase C (deployed) |
| Cloud `shop_members.role` | Supabase, per-shop | Phase C (deployed) |

### 22.2 Phase D Role Behavior

Phase D uses ONLY local permissions for authorization decisions:

```
PermissionResolver.can(role, permission)
  -> reads from local role_permissions table
  -> owner gets ALL permissions (hardcoded bypass)
  -> employee/salesOnly get permissions from local table
```

Cloud roles (`shop_members.role`) are stored but NOT yet used for authorization in Phase D.

### 22.3 Phase F Migration Path

Phase F will:
1. Introduce server-side RBAC via Supabase Edge Functions
2. Replace local permission checks with cloud permission checks
3. Sync cloud permissions to local cache for offline use
4. Add permission override capabilities per-shop

### 22.4 Role Mapping

| Local Role | Cloud Role | Notes |
|-----------|------------|-------|
| `UserRole.owner` | `shop_members.role = 'owner'` | 1:1 mapping |
| `UserRole.employee` | `shop_members.role = 'employee'` | 1:1 mapping |
| `UserRole.salesOnly` | `shop_members.role = 'salesOnly'` | 1:1 mapping |

### 22.5 Role Conflict Resolution

If local and cloud roles differ (should not happen in Phase D):
- **Phase D:** Local role wins (cloud role is informational only)
- **Phase F:** Cloud role wins (authoritative source)

---

## 23. Email & Password Strategy

### 23.1 Email as Cloud Identity

| Aspect | Decision |
|--------|----------|
| Cloud identity | Email (Supabase Auth requirement) |
| Local identity | Username (existing, unchanged) |
| Email storage | `app_settings['cloud.auth.email']` (non-secret) |
| Email validation | Supabase Auth handles on signUp/signIn |

### 23.2 Password Strategy

| Aspect | Decision |
|--------|----------|
| Local password | PBKDF2-HMAC-SHA256, 100K iterations, 16-byte salt (existing) |
| Cloud password | Same as local password (user chooses once) |
| Password hashing | Local: PBKDF2; Cloud: Supabase Auth (bcrypt) |
| Password storage | Local: SQLite users table; Cloud: Supabase auth.users |

### 23.3 Password Sync Policy

During owner onboarding:
1. User enters password for local account
2. Same password is used for cloud signUp
3. No automatic sync after initial setup
4. If user changes local password, cloud password is NOT automatically updated
5. **Phase H concern:** Password change sync is deferred

### 23.4 Email Change Policy

- Email is immutable once set (for Phase D)
- Changing email requires:
  1. Supabase Auth email change flow
  2. Update `app_settings['cloud.auth.email']`
  3. Update `users.cloud_uuid` linkage (if email is identity key)
- **Phase H concern:** Email change is deferred

---

## 24. Multi-Shop Support

### 24.1 Phase D Scope

Phase D supports the foundation for multi-shop but does NOT implement full multi-shop:

| Feature | Phase D | Phase F+ |
|---------|---------|----------|
| Owner can have 1 shop | YES | YES |
| Employee can belong to multiple shops | YES (data model) | YES (UI) |
| Shop switching in-session | NO | YES |
| Cross-shop data queries | NO | YES |
| Shop selector on login | YES (if multiple) | YES |

### 24.2 Shop Creation

Only owners can create shops. In Phase D, each owner creates exactly one shop during onboarding.

```dart
// Owner onboarding flow:
final shopResult = await Supabase.instance.client
    .rpc('create_shop_with_owner', params: {
      'p_shop_name': shopName,
      'p_owner_email': email,
      'p_owner_display_name': displayName,
    });
```

### 24.3 Employee Shop Membership

Employees are invited to shops via the invitation flow (Section 20). An employee can belong to multiple shops if invited by multiple owners.

### 24.4 Shop Data Isolation

Each shop's data is isolated via RLS policies. Users can only query data for shops they have active memberships in.

---

## 25. Device & Licensing Boundaries

### 25.1 Phase D Boundary

Phase D does NOT implement licensing or device management. These are Phase E concerns.

### 25.2 Phase E Handoff Points

| Component | Phase D Action | Phase E Concern |
|-----------|---------------|-----------------|
| `devices` table | EXISTS (Phase C deployed) | Device registration, fingerprinting |
| `licenses` table | EXISTS (Phase C deployed) | License creation, validation |
| `activations` table | EXISTS (Phase C deployed) | Device-license linking |
| `start_trial()` | EXISTS (Phase C deployed) | Trial activation logic |
| `verify_trial_status()` | EXISTS (Phase C deployed) | Trial validation logic |

### 25.3 Device Identification

Phase D does NOT implement device identification. The `devices` table schema is ready but unused until Phase E.

### 25.4 License Verification

Phase D does NOT verify licenses. The `verify_trial_status()` function exists but is not called until Phase E.

---

## 26. Supabase Changes (Additive Only)

### 26.1 New Tables

| Table | Purpose | RLS |
|-------|---------|-----|
| `invitations` | Track employee invitations | Shop owners can view; service-role can insert |

### 26.2 New Database Functions

| Function | Purpose | Security |
|----------|---------|----------|
| `accept_invitation()` | Activate pending membership | SECURITY DEFINER |

### 26.3 New Edge Functions

| Function | Purpose | Auth |
|----------|---------|------|
| `invite-employee` | Create auth user + shop membership + invitation record | Service-role (owner JWT verified) |

### 26.4 Modified Tables

None. All Phase D changes are additive.

### 26.5 New RLS Policies

| Policy | Table | Operation |
|--------|-------|-----------|
| Shop owners can view invitations | `invitations` | SELECT |
| Service role can insert invitations | `invitations` | INSERT |

### 26.6 Config Changes

No changes to `supabase/config.toml`. Auth settings remain as configured in Phase C.

---

## 27. Flutter File Forecast

### 27.1 New Files (13)

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `app/lib/models/cloud_session.dart` | Cloud session state model | ~45 |
| `app/lib/services/cloud_auth_service.dart` | Supabase Auth wrapper | ~180 |
| `app/lib/services/identity_linker.dart` | Cloud â†” local identity mapping | ~120 |
| `app/lib/services/shop_resolver.dart` | Multi-shop resolution logic | ~95 |
| `app/lib/services/invitation_service.dart` | Invitation accept/list | ~85 |
| `app/lib/screens/auth/cloud_login_screen.dart` | Cloud-aware login UI | ~220 |
| `app/lib/screens/auth/accept_invitation_screen.dart` | Invitation acceptance UI | ~180 |
| `app/lib/screens/settings/shop_selector_screen.dart` | Shop selection dialog | ~140 |
| `app/lib/screens/settings/invite_employee_screen.dart` | Employee invitation UI | ~160 |
| `app/lib/services/invitation_poller.dart` | Background invitation check | ~65 |
| `app/lib/services/sync_status_indicator.dart` | Online/offline status UI | ~45 |
| `app/test/services/cloud_auth_service_test.dart` | Cloud auth unit tests | ~180 |
| `app/test/services/identity_linker_test.dart` | Identity mapping tests | ~120 |

**Total new:** ~1,635 lines

### 27.2 Modified Files (8)

| File | Changes | Lines Delta |
|------|---------|-------------|
| `app/pubspec.yaml` | Add `supabase_flutter: ^2.8.0` | +2 |
| `app/lib/main.dart` | Supabase.initialize, AuthGate cloud check | +35 |
| `app/lib/services/session_state.dart` | Add CloudSession field, cloud-aware login/logout | +45 |
| `app/lib/services/app_settings.dart` | Add cloud.* key constants | +12 |
| `app/lib/screens/auth/login_screen.dart` | Cloud-aware login flow | +65 |
| `app/lib/screens/auth/first_owner_setup_screen.dart` | Cloud linking on onboarding | +55 |
| `app/lib/services/shop_profile_service.dart` | Cloud UUID sync on login | +15 |
| `app/lib/database/user_repository.dart` | Cloud UUID update on linkage | +16 |

**Total modified:** ~245 lines delta

### 27.3 Total Delta Estimate

| Category | Lines |
|----------|-------|
| New files | ~1,635 |
| Modified files | ~245 |
| **Total** | **~1,880** |

---

## 28. Dependencies

### 28.1 New Flutter Dependencies

| Package | Version | Purpose | Justification |
|---------|---------|---------|---------------|
| `supabase_flutter` | ^2.8.0 | Supabase client SDK for Flutter | Official SDK, handles auth, session persistence, token refresh |

### 28.2 Dependency Analysis

```yaml
# Addition to app/pubspec.yaml
dependencies:
  supabase_flutter: ^2.8.0

# Transitive dependencies (added automatically):
# - supabase: ^2.0.0
# - gotrue: ^2.0.0
# - realtime: ^2.0.0
# - postgrest: ^2.0.0
# - storage_client: ^2.0.0
```

### 28.3 Version Compatibility

| Requirement | Current | Compatible |
|-------------|---------|------------|
| Dart SDK | ^3.5.4 | YES (supabase_flutter requires ^3.0.0) |
| Flutter SDK | >=3.0.0 | YES |
| minSdkVersion | 21 (Android) | YES |
| iOS deployment target | 12.0 | YES |

### 28.4 Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Package size increase | supabase_flutter adds ~2MB; acceptable for app |
| Version conflicts | No existing Supabase dependencies; clean addition |
| Breaking changes | Pin to ^2.8.0 for stability |

---

## 29. Environment & Secrets

### 29.1 Required Environment Variables

| Variable | Location | Purpose | Secret? |
|----------|----------|---------|---------|
| `SUPABASE_URL` | `lib/config.dart` or `.env` | Supabase project URL | NO (public) |
| `SUPABASE_ANON_KEY` | `lib/config.dart` or `.env` | Supabase anonymous key | NO (public, RLS protected) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function only | Service-role key for Edge Functions | YES (server-side only) |

### 29.2 Key Distribution

```
Flutter Client:
  - SUPABASE_URL (public)
  - SUPABASE_ANON_KEY (public, RLS protects data)
  - NO service-role key

Edge Functions (Deno):
  - SUPABASE_URL (internal)
  - SUPABASE_SERVICE_ROLE_KEY (secret)
  - SUPABASE_ANON_KEY (internal)

Server (if any):
  - SUPABASE_SERVICE_ROLE_KEY (secret)
```

### 29.3 Security Model

The Flutter client NEVER holds the service-role key. All data access is through:
1. Supabase Auth (authenticated requests)
2. RLS policies (row-level security)
3. Database functions (SECURITY DEFINER)

### 29.4 Configuration Approach

Phase D uses a simple configuration approach:

```dart
// lib/config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
```

Build command:
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx
```

---

## 30. Security Threat Model

### 30.1 Threat Categories

| Threat | Phase D Mitigation |
|--------|-------------------|
| Credential theft | PBKDF2 local, Supabase Auth cloud; no plain-text storage |
| Man-in-the-middle | HTTPS enforced by Supabase; certificate pinning optional |
| Unauthorized data access | RLS policies enforce shop-level isolation |
| Privilege escalation | Owner-only operations enforced at RPC level |
| Session hijacking | JWT + refresh token rotation; token expiry |
| Offline credential reuse | Local PBKDF2 hashes are sacred; never uploaded |
| Service-role key exposure | NEVER in Flutter client; server-side only |
| Invitation abuse | Expiration (7 days); owner-only creation |

### 30.2 Attack Vectors

| Vector | Description | Mitigation |
|--------|-------------|-----------|
| Compromised local device | Attacker has physical access | Local auth + cloud auth; offline fallback limited |
| Compromised network | Attacker intercepts traffic | HTTPS + Supabase TLS |
| Compromised Supabase project | Attacker has admin access | Out of scope; cloud provider responsibility |
| Compromised owner account | Owner credentials stolen | Owner can revoke all memberships; Phase E adds 2FA |

### 30.3 Data Protection

| Data Type | Protection |
|-----------|-----------|
| Passwords | PBKDF2 (local), bcrypt (cloud) - NEVER plain-text |
| Shop data | RLS policies; shop-level isolation |
| User data | RLS policies; user-level isolation |
| Session tokens | Encrypted in transit; short-lived JWT |
| Invitation tokens | Time-limited (7 days); single-use |

---

## 31. Failure & Recovery Matrix

### 31.1 Failure Scenarios

| Scenario | Failure Mode | Recovery |
|----------|-------------|----------|
| Network unavailable | Supabase unreachable | Offline fallback (local auth only) |
| Supabase Auth down | Login/signup fails | Retry with backoff; offline fallback |
| Database function fails | RPC error | Display error; retry |
| Edge Function fails | Invitation fails | Display error to owner |
| Token refresh fails | Session expires | Re-login required |
| Cloud UUID mismatch | Identity corruption | Re-link via owner onboarding |

### 31.2 Error Handling

```dart
try {
  final response = await Supabase.instance.client
      .auth.signInWithPassword(email: email, password: password);
} on AuthException catch (e) {
  // Handle auth errors
  if (e.message.contains('Invalid login credentials')) {
    showError('Invalid email or password');
  } else if (e.message.contains('Email not confirmed')) {
    showError('Please confirm your email');
  } else {
    showError('Authentication failed: ${e.message}');
  }
} on NetworkException {
  // Offline fallback
  showOfflineIndicator();
  // Proceed with local auth only
}
```

### 31.3 Recovery Procedures

| Failure | Recovery Steps |
|---------|---------------|
| Lost cloud session | Re-login with email/password |
| Corrupted identity link | Re-link via settings (future Phase) |
| Invited user not appearing | Check invitation status; resend if expired |
| Shop not found | Verify shop exists; contact support |

---

## 32. Idempotency Guarantees

### 32.1 Operations

| Operation | Idempotent? | Notes |
|-----------|-------------|-------|
| `auth.signUp()` | NO (creates new user) | Use `auth.admin.createUser()` for idempotent creation |
| `auth.signInWithPassword()` | YES (returns same session) | Safe to retry |
| `create_shop_with_owner()` | NO (creates new shop) | Owner should only create once |
| `accept_invitation()` | YES (checks status first) | Safe to retry |
| `get_user_shops()` | YES (read-only) | Safe to retry |
| `invite-employee` Edge Function | NO (creates new user) | Owner should only invite once per email |

### 32.2 Retry Strategy

| Operation | Retry Count | Backoff |
|-----------|-------------|---------|
| Auth operations | 3 | Exponential (1s, 2s, 4s) |
| Database functions | 3 | Exponential (1s, 2s, 4s) |
| Edge Functions | 2 | Linear (5s, 10s) |

### 32.3 Duplicate Prevention

- `auth.admin.createUser()` returns existing user if email already exists
- `shop_members` has unique constraint on `(shop_id, user_id)`
- `invitations` allows multiple per email but tracks status

---

## 33. Migration Safety

### 33.1 Zero-Destructive Policy

Phase D follows the zero-destructive migration policy:

| Rule | Enforcement |
|------|-------------|
| No SQLite schema changes | No new columns/tables in Phase D |
| No data deletion | Local user data preserved |
| No PK changes | Integer PKs remain |
| Additive only | New cloud tables/functions only |

### 33.2 Rollback Capability

| Change | Rollback Method |
|--------|----------------|
| New `supabase_flutter` dependency | Remove from pubspec.yaml |
| New cloud table `invitations` | DROP TABLE invitations |
| New RPC `accept_invitation` | DROP FUNCTION accept_invitation |
| New Edge Function `invite-employee` | Remove function directory |
| New RLS policies | DROP POLICY |
| New app_settings keys | DELETE FROM app_settings |

### 33.3 Data Preservation

| Data Type | Preserved? | Notes |
|-----------|------------|-------|
| Local user accounts | YES | Never modified in Phase D |
| Local shop data | YES | Never modified in Phase D |
| Cloud shop data | YES | Created in Phase C; unchanged |
| Cloud user data | YES | Created in Phase C; unchanged |
| Identity mappings | YES | Created in Phase D; immutable once set |

### 33.4 Phase Boundary Integrity

| Phase | Boundary Maintained? |
|-------|---------------------|
| Phase A (local) | YES - no changes |
| Phase B (schema v9) | YES - no changes |
| Phase C (cloud backend) | YES - no changes |
| Phase D (cloud auth) | ADDITIVE ONLY |
| Phase E (licensing) | NOT TOUCHED |
| Phase F (server RBAC) | NOT TOUCHED |
| Phase G (real-time sync) | NOT TOUCHED |
| Phase H (offline architecture) | NOT TOUCHED |

---

## 34. Test Strategy

### 34.1 Test Types

| Type | Scope | Count (est.) | Framework |
|------|-------|--------------|-----------|
| Unit tests | Services, models | ~250 | flutter_test |
| Widget tests | Login, setup screens | ~80 | flutter_test |
| Integration tests | Auth flows | ~40 | integration_test |
| Cloud tests | Supabase integration | ~30 | integration_test (mocked) |

### 34.2 Test Coverage Targets

| Component | Coverage Target |
|-----------|----------------|
| `CloudAuthService` | 90% |
| `IdentityLinker` | 85% |
| `ShopResolver` | 80% |
| `InvitationService` | 85% |
| `SessionState` (cloud) | 90% |
| Login screen (cloud) | 80% |

### 34.3 Mock Strategy

```dart
// Mock Supabase client for unit tests
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSession extends Mock implements Session {}
```

### 34.4 Test Data

| Data | Source |
|------|--------|
| Test users | Factory functions (not seeded) |
| Test shops | Factory functions |
| Test memberships | Factory functions |
| Test invitations | Factory functions |

### 34.5 Test Isolation

- Each test uses fresh mock instances
- No shared state between tests
- Database state is reset per test
- Cloud state is mocked (no real Supabase calls in unit tests)

---

## 35. Implementation Sequence

### 35.1 Task Breakdown

| Task | Depends On | Est. Hours | Priority |
|------|-----------|------------|----------|
| T1: Add supabase_flutter dependency | None | 1 | P0 |
| T2: Create CloudSession model | None | 2 | P0 |
| T3: Implement CloudAuthService | T1 | 8 | P0 |
| T4: Implement IdentityLinker | T3 | 4 | P0 |
| T5: Update SessionState | T2, T3 | 4 | P0 |
| T6: Update main.dart (AuthGate) | T3, T5 | 3 | P0 |
| T7: Update LoginScreen | T3, T5 | 4 | P0 |
| T8: Update FirstOwnerSetupScreen | T3, T4 | 4 | P0 |
| T9: Implement ShopResolver | T3 | 3 | P1 |
| T10: Implement InvitationService | T3 | 3 | P1 |
| T11: Create CloudLoginScreen | T7 | 4 | P1 |
| T12: Create AcceptInvitationScreen | T10 | 3 | P1 |
| T13: Create ShopSelectorScreen | T9 | 3 | P1 |
| T14: Create InviteEmployeeScreen | T10 | 4 | P1 |
| T15: Write unit tests | T3-T10 | 12 | P0 |
| T16: Write widget tests | T7, T8, T11-T14 | 8 | P1 |
| T17: Write integration tests | All | 8 | P1 |
| T18: Cloud migration (invitations table) | None | 2 | P0 |
| T19: Cloud migration (accept_invitation) | None | 2 | P0 |
| T20: Deploy Edge Function | None | 2 | P1 |

**Total estimated:** ~80 hours

### 35.2 Critical Path

```
T1 -> T3 -> T4 -> T5 -> T6 -> T7 -> T8 -> T15 -> T17
```

### 35.3 Parallel Workstreams

| Stream | Tasks |
|--------|-------|
| Cloud backend | T18, T19, T20 (can run in parallel with Flutter) |
| Flutter core | T1-T8 (sequential) |
| Flutter UI | T9-T14 (can parallelize after T3) |
| Testing | T15-T17 (after core implementation) |

---

## 36. Diff Forecast

### 36.1 Lines Changed

| Category | Lines |
|----------|-------|
| New files (13) | ~1,635 |
| Modified files (8) | ~245 |
| **Total delta** | **~1,880** |

### 36.2 File Changes Detail

| File | Type | Lines |
|------|------|-------|
| `app/pubspec.yaml` | Modified | +2 |
| `app/lib/models/cloud_session.dart` | New | ~45 |
| `app/lib/services/cloud_auth_service.dart` | New | ~180 |
| `app/lib/services/identity_linker.dart` | New | ~120 |
| `app/lib/services/shop_resolver.dart` | New | ~95 |
| `app/lib/services/invitation_service.dart` | New | ~85 |
| `app/lib/screens/auth/cloud_login_screen.dart` | New | ~220 |
| `app/lib/screens/auth/accept_invitation_screen.dart` | New | ~180 |
| `app/lib/screens/settings/shop_selector_screen.dart` | New | ~140 |
| `app/lib/screens/settings/invite_employee_screen.dart` | New | ~160 |
| `app/lib/services/invitation_poller.dart` | New | ~65 |
| `app/lib/services/sync_status_indicator.dart` | New | ~45 |
| `app/test/services/cloud_auth_service_test.dart` | New | ~180 |
| `app/test/services/identity_linker_test.dart` | New | ~120 |
| `app/lib/main.dart` | Modified | +35 |
| `app/lib/services/session_state.dart` | Modified | +45 |
| `app/lib/services/app_settings.dart` | Modified | +12 |
| `app/lib/screens/auth/login_screen.dart` | Modified | +65 |
| `app/lib/screens/auth/first_owner_setup_screen.dart` | Modified | +55 |
| `app/lib/services/shop_profile_service.dart` | Modified | +15 |
| `app/lib/database/user_repository.dart` | Modified | +16 |

### 36.3 Cloud Changes

| Change | Type |
|--------|------|
| `supabase/migrations/20260820000021_add_invitations.sql` | New migration |
| `supabase/migrations/20260820000022_add_accept_invitation.sql` | New migration |
| `supabase/functions/invite-employee/index.ts` | New Edge Function |

---

## 37. Rollback Plan

### 37.1 Rollback Triggers

| Trigger | Action |
|---------|--------|
| Test failure rate > 20% | Revert all changes |
| Critical bug in auth flow | Revert all changes |
| Data loss detected | Revert all changes |
| Security vulnerability | Revert all changes |

### 37.2 Rollback Procedure

```bash
# 1. Revert code changes
git revert HEAD

# 2. Remove new dependency
# (handled by git revert)

# 3. Drop new cloud objects
DROP FUNCTION IF EXISTS accept_invitation;
DROP TABLE IF EXISTS invitations;
DROP FUNCTION IF EXISTS invite_employee_edge;

# 4. Verify rollback
flutter test
```

### 37.3 Rollback Safety

| Component | Safe to Revert? | Notes |
|-----------|----------------|-------|
| Flutter code | YES | No data dependencies |
| supabase_flutter | YES | Remove dependency |
| Cloud tables | YES | Drop tables |
| Cloud functions | YES | Drop functions |
| Edge Functions | YES | Remove function |
| Identity mappings | CAUTION | Local data preserved; cloud data orphaned |

---

## 38. Acceptance Gates

### 38.1 Definition of Done

| Gate | Criteria |
|------|----------|
| G1: Dependency | `supabase_flutter` added and builds successfully |
| G2: Cloud auth | Owner can sign up and sign in via Supabase Auth |
| G3: Identity link | Owner's local user linked to cloud UUID |
| G4: Shop creation | Owner creates shop via `create_shop_with_owner()` |
| G5: Employee invite | Owner invites employee; invitation recorded |
| G6: Employee accept | Employee accepts invitation; membership ACTIVE |
| G7: Offline fallback | Local auth works when offline |
| G8: Session persistence | Cloud session persists across app restarts |
| G9: Tests pass | All new tests pass; no regression in existing tests |
| G10: Zero destructive | No SQLite schema changes; no data loss |

### 38.2 Verification Commands

```bash
# Build verification
flutter build apk --debug

# Test verification
flutter test

# Integration test verification
flutter test integration_test/

# Cloud verification (manual)
# 1. Owner sign up
# 2. Owner create shop
# 3. Owner invite employee
# 4. Employee accept invitation
# 5. Employee login
```

### 38.3 Sign-Off Requirements

| Role | Sign-Off |
|------|----------|
| Owner | Verify owner onboarding flow |
| Employee | Verify employee invitation flow |
| Technical Lead | Verify code quality and test coverage |
| Security Review | Verify no service-role key in client |

---

## 39. Phase E Handoff

### 39.1 What Phase E Receives

| Component | Status |
|-----------|--------|
| `devices` table | EXISTS (Phase C) |
| `licenses` table | EXISTS (Phase C) |
| `activations` table | EXISTS (Phase C) |
| `start_trial()` | EXISTS (Phase C) |
| `verify_trial_status()` | EXISTS (Phase C) |
| Cloud auth integration | COMPLETED (Phase D) |
| Identity mapping | COMPLETED (Phase D) |

### 39.2 What Phase E Implements

| Feature | Description |
|---------|-------------|
| Device registration | Fingerprint devices |
| License creation | Generate licenses |
| License verification | Validate licenses |
| Trial activation | Use `start_trial()` |
| Trial validation | Use `verify_trial_status()` |

### 39.3 Dependencies

Phase E depends on:
1. Cloud auth integration (Phase D) - DONE
2. Identity mapping (Phase D) - DONE
3. Shop membership (Phase D) - DONE

---

## 40. Phase F Handoff

### 40.1 What Phase F Receives

| Component | Status |
|-----------|--------|
| Shop membership model | COMPLETED (Phase D) |
| Role mapping | COMPLETED (Phase D) |
| Invitation system | COMPLETED (Phase D) |
| Multi-shop foundation | COMPLETED (Phase D) |

### 40.2 What Phase F Implements

| Feature | Description |
|---------|-------------|
| Server-side RBAC | Edge Functions enforce permissions |
| Permission sync | Cloud â†’ local permission cache |
| Permission overrides | Per-shop permission customization |
| Real-time sync | Live permission updates |

### 40.3 Dependencies

Phase F depends on:
1. Cloud auth integration (Phase D) - DONE
2. Shop membership model (Phase D) - DONE
3. Multi-shop foundation (Phase D) - DONE

---

## 41. Open Decisions

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| OD1 | Offline grace duration | OPEN | Phase H |
| OD2 | Password change sync | OPEN | Phase H |
| OD3 | Email change policy | OPEN | Phase H |
| OD4 | Multi-shop switching UX | OPEN | Phase F |
| OD5 | Device fingerprinting method | OPEN | Phase E |
| OD6 | License key format | OPEN | Phase E |
| OD7 | Trial duration | OPEN | Phase E |
| OD8 | Real-time sync protocol | OPEN | Phase G |

---

## 42. Exit Criteria

### 42.1 Phase D Exit Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Owner can sign up via Supabase Auth | Manual test |
| 2 | Owner can sign in via Supabase Auth | Manual test |
| 3 | Owner's local user linked to cloud UUID | Code inspection |
| 4 | Owner creates shop via RPC | Manual test |
| 5 | Owner invites employee | Manual test |
| 6 | Employee accepts invitation | Manual test |
| 7 | Employee can sign in | Manual test |
| 8 | Offline fallback works | Manual test |
| 9 | All tests pass | `flutter test` |
| 10 | No SQLite schema changes | Code inspection |
| 11 | No data loss | Data verification |
| 12 | No service-role key in client | Security review |

### 42.2 Closure Requirements

| Requirement | Status |
|-------------|--------|
| All exit criteria met | PENDING |
| Code review completed | PENDING |
| Security review completed | PENDING |
| Documentation updated | PENDING |
| Phase D plan committed | PENDING |

---

## 43. Appendix A: File Inventory

### 43.1 New Files

| # | File Path | Purpose |
|---|-----------|---------|
| 1 | `app/lib/models/cloud_session.dart` | Cloud session state model |
| 2 | `app/lib/services/cloud_auth_service.dart` | Supabase Auth wrapper |
| 3 | `app/lib/services/identity_linker.dart` | Cloud â†” local identity mapping |
| 4 | `app/lib/services/shop_resolver.dart` | Multi-shop resolution logic |
| 5 | `app/lib/services/invitation_service.dart` | Invitation accept/list |
| 6 | `app/lib/screens/auth/cloud_login_screen.dart` | Cloud-aware login UI |
| 7 | `app/lib/screens/auth/accept_invitation_screen.dart` | Invitation acceptance UI |
| 8 | `app/lib/screens/settings/shop_selector_screen.dart` | Shop selection dialog |
| 9 | `app/lib/screens/settings/invite_employee_screen.dart` | Employee invitation UI |
| 10 | `app/lib/services/invitation_poller.dart` | Background invitation check |
| 11 | `app/lib/services/sync_status_indicator.dart` | Online/offline status UI |
| 12 | `app/test/services/cloud_auth_service_test.dart` | Cloud auth unit tests |
| 13 | `app/test/services/identity_linker_test.dart` | Identity mapping tests |

### 43.2 Modified Files

| # | File Path | Changes |
|---|-----------|---------|
| 1 | `app/pubspec.yaml` | Add `supabase_flutter: ^2.8.0` |
| 2 | `app/lib/main.dart` | Supabase.initialize, AuthGate cloud check |
| 3 | `app/lib/services/session_state.dart` | Add CloudSession field |
| 4 | `app/lib/services/app_settings.dart` | Add cloud.* key constants |
| 5 | `app/lib/screens/auth/login_screen.dart` | Cloud-aware login flow |
| 6 | `app/lib/screens/auth/first_owner_setup_screen.dart` | Cloud linking on onboarding |
| 7 | `app/lib/services/shop_profile_service.dart` | Cloud UUID sync |
| 8 | `app/lib/database/user_repository.dart` | Cloud UUID update |

### 43.3 Cloud Files

| # | File Path | Purpose |
|---|-----------|---------|
| 1 | `supabase/migrations/20260820000021_add_invitations.sql` | Invitations table + RLS |
| 2 | `supabase/migrations/20260820000022_add_accept_invitation.sql` | Accept invitation RPC |
| 3 | `supabase/functions/invite-employee/index.ts` | Edge Function |

---

## 44. Appendix B: Glossary

| Term | Definition |
|------|-----------|
| Cloud Auth | Authentication via Supabase Auth (email + password) |
| Local Auth | Authentication via PBKDF2 password hash in SQLite |
| Identity Linking | Connecting local user to cloud UUID |
| Shop Membership | User's relationship to a shop (role + status) |
| Invitation | Owner's request for employee to join shop |
| Cloud Session | Authenticated session with Supabase (JWT + refresh token) |
| Offline Fallback | Operating with local auth when cloud is unreachable |
| RLS | Row-Level Security (Supabase PostgreSQL feature) |
| SECURITY DEFINER | PostgreSQL function that runs with owner privileges |
| Edge Function | Supabase serverless function (Deno runtime) |
| PBKDF2 | Password-Based Key Derivation Function 2 (local hashing) |
| JWT | JSON Web Token (cloud session token) |

---

**END OF PHASE D CLOUD AUTH & MEMBERSHIP PLAN**

