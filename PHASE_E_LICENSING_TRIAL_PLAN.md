# PHASE E: LICENSING & TRIAL PLAN

**Phase:** E - Licensing & Trial
**Project:** I Tech Store Management Application
**Institutional Owner:** I Tech for Technology / I Tech for Technology
**Repository:** C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
**Branch:** codex/i-tech-next-roadmap-freeze
**Starting Baseline:** `298f564fcfe17aac919fa0c0edbd97acfc15992a`
**Date:** 2026-08-20
**Status:** Planning artifact - not implemented

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | E - Licensing & Trial |
| Session Type | PHASE_E_PLANNING |
| Baseline Commit | `298f564fcfe17aac919fa0c0edbd97acfc15992a` |
| Predecessor Phase | D - Cloud Auth & Membership (CLOSED) |
| Successor Phase | F - Server-Enforced Permissions |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Phase D Closure | `PASS_PHASE_D_REMOTE_LOCKED` |

---

## 2. Governing Baselines

```
PHASE_C_FINAL_CLOSURE_COMMIT  = 03956253ff53e242144a8f1aa9676478720d7379
PHASE_D_PLANNING_BASELINE     = 70b4c80ea4ffbc20716e47d5ea35600208b2f537
PHASE_D_IMPLEMENTATION_COMMIT = 298f564fcfe17aac919fa0c0edbd97acfc15992a
PHASE_D_FINAL_LOCKED_BASELINE = 298f564fcfe17aac919fa0c0edbd97acfc15992a

LOCAL_HEAD  = 298f564fcfe17aac919fa0c0edbd97acfc15992a
REMOTE_HEAD = 298f564fcfe17aac919fa0c0edbd97acfc15992a
LOCAL_AHEAD = 0
REMOTE_AHEAD = 0
```

---

## 3. Governing Documents

| # | Document | Precedence | Relevance |
|---|----------|------------|-----------|
| 1 | `PROJECT_MASTER_PLAN.md` | Highest | D12 (14-day server trial), D13 (shop-scoped), D6 (Win+Android), D7 (Owner not Windows-bound) |
| 2 | `PRODUCTIZATION_ARCHITECTURE_PLAN.md` | High | Licensing architecture, device model, activation |
| 3 | `PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md` | High | Cloud schema (devices/licenses/activations), functions (start_trial/verify_trial_status) |
| 4 | `PHASE_D_CLOUD_AUTH_MEMBERSHIP_PLAN.md` | High | CloudSession, SessionState, identity linking, login flow |
| 5 | `PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md` | Medium | Cloud schema origin (Phase B 8.1) |

---

## 4. Repository Discovery

### 4.1 Existing Cloud Schema (Phase C Deployed)

| Table | Status | Key Columns |
|-------|--------|-------------|
| `devices` | DEPLOYED | id UUID PK, installation_id UUID, shop_id FK, user_id FK, platform CHECK(windows/android), status CHECK(ACTIVE/REVOKED/LOST) |
| `licenses` | DEPLOYED | id UUID PK, shop_id FK, license_key UNIQUE, status CHECK(TRIAL/ACTIVE/EXPIRED/SUSPENDED/PERPETUAL), trial_started_at, trial_expires_at, activated_at, subscription_expires_at |
| `activations` | DEPLOYED | id UUID PK, license_id FK, device_id FK, activated_at, last_verified_at, status (NO CHECK constraint) |

### 4.2 Existing Cloud Functions (Phase C Deployed)

| Function | Signature | Purpose |
|----------|-----------|---------|
| `start_trial(p_shop_id UUID)` | RETURNS UUID | Creates 14-day trial license using `now()`. Verifies owner. Checks no existing TRIAL/ACTIVE/PERPETUAL. |
| `verify_trial_status(p_shop_id UUID)` | RETURNS TABLE(has_license, license_status, trial_active, trial_started_at, trial_expires_at, days_remaining) | Returns trial status computed server-side. |

### 4.3 Existing Client Licensing (Phase A)

| Component | File | Status |
|-----------|------|--------|
| `LicensingService` | `app/lib/licensing/licensing_service.dart` | EXISTS - Ed25519 + DPAPI local system |
| `EntitlementState` | `app/lib/licensing/license_state.dart` | EXISTS - 13-state local machine |
| `EntitlementToken` | `app/lib/licensing/entitlement_token.dart` | EXISTS - CBOR/Ed25519 token |
| `DeviceIdentity` | `app/lib/licensing/device_identity.dart` | EXISTS - Windows HW fingerprint |
| `SecureActivationStore` | `app/lib/licensing/secure_store.dart` | EXISTS - DPAPI file storage |
| `ActivationClient` | `app/lib/licensing/licensing_service.dart` | STUB (throws SocketException) |
| `_enforceLicensing()` | `app/lib/database/database_helper.dart` | EXISTS - called before 22 business writes |

### 4.4 Key Findings

1. **Two licensing layers coexist:** Local Ed25519/DPAPI (client-only) and cloud Supabase (server-side). They are NOT connected. `ActivationClient` is a stub.
2. **Cloud schema is sufficient:** `devices`, `licenses`, `activations` tables from Phase C have correct columns for Phase E. No structural redesign needed.
3. **Server functions exist:** `start_trial()` uses `now()` for server-time authority. `verify_trial_status()` computes status server-side.
4. **Client enforcement wired:** `DatabaseHelper._enforceLicensing()` calls `LicensingService.enforceActive()` before every business write. This boundary is established.
5. **`activations.status` has no CHECK constraint.** Phase E should add one.
6. **No `updated_at` on `licenses`.** Phase E should add one.
7. **No `max_devices` on `licenses`.** Phase E should add one.
8. **No `revoked_at` on `licenses`.** Phase E should add one.

---

## 5. Phase E Scope

### 5.1 Objectives

| # | Objective | Measurable Outcome |
|---|-----------|-------------------|
| O1 | Server-authoritative 14-day trial | Trial period calculated exclusively by PostgreSQL `now()` |
| O2 | Shop-scoped licensing | Each shop has independent license/trial lifecycle |
| O3 | Cloud license resolution | Client resolves entitlement state from server after each login |
| O4 | Device activation | Installation tracked per shop, activation limit enforced server-side |
| O5 | Trial non-resettable | Reinstall, clock change, new user cannot restart 14-day period |
| O6 | Offline grace | Cached server state permits limited offline operation |
| O7 | Bridge existing client licensing | Replace Ed25519/DPAPI enforcement with cloud-backed enforcement |
| O8 | Multi-platform readiness | Windows + Android use same cloud licensing |

### 5.2 Explicit Non-Goals

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | Subscription billing provider | Later session | Owner Decision OD2 unresolved |
| 2 | Play Store subscription | Phase K/L | Android scope |
| 3 | Admin dashboard for I Tech | Later session | Not in Phase E scope |
| 4 | Production deployment | Separate session | Planning only |
| 5 | Edge Function for trial/license | Phase E uses RPCs | RPCs sufficient |
| 6 | Full sync engine | Phase H | Sync scope |
| 7 | License key generation for paid | Manual/Admin | Owner Decision OD2 |
| 8 | 2FA / MFA | Later session | Security hardening |
| 9 | Real billing/payment integration | Later session | Architecture prepared only |
| 10 | Full Ed25519/DPAPI removal | Phase E bridges | Existing retained as fallback |

---

## 6. Critical Architecture Principle

```
Authentication answers:
  "Who is the user?"
  -> Supabase Auth JWT, resolved to auth.uid()

Membership answers:
  "Which shop can the user access and with which permissions?"
  -> shop_members table, role + status, resolved via get_user_shops()

Licensing answers:
  "Is this shop currently entitled to use the I Tech application?"
  -> licenses table, server-resolved via verify_license_entitlement()

Activation answers:
  "Is this installation/device authorized under that entitlement?"
  -> activations table, server-enforced max_devices check
```

**These responsibilities are strictly separated. No layer conflates them.**

---

## 7. Licensing Domain Model

### 7.1 Entity Relationships

```
Shop (shops)
  +-- License (licenses) [1:N but only 1 active at a time]
        +-- Activation (activations) [1:N]
              +-- Device (devices) [N:1]

User (auth.users)
  +-- Membership (shop_members) [N:N with shops]
  +-- Device ownership (devices.user_id) [optional]
```

### 7.2 Ownership Scope

| Entity | Scope | Authority |
|--------|-------|-----------|
| License | Shop | Server (Supabase PostgreSQL) |
| Trial | Shop | Server (start_trial RPC) |
| Device | Shop + Installation | Server (register_device RPC) |
| Activation | License + Device | Server (activate_device RPC) |
| Entitlement | Session (derived) | Server (verify_license_entitlement RPC) |

### 7.3 License Record Fields

Existing `licenses` table (Phase C) with Phase E additive columns:

```sql
-- EXISTING columns (NO changes to existing):
id                       UUID PK
shop_id                  UUID FK -> shops ON DELETE CASCADE
license_key              TEXT UNIQUE NOT NULL
plan                     TEXT nullable
status                   TEXT NOT NULL DEFAULT 'TRIAL'
trial_started_at         TIMESTAMPTZ nullable
trial_expires_at         TIMESTAMPTZ nullable
activated_at             TIMESTAMPTZ nullable
subscription_expires_at  TIMESTAMPTZ nullable
created_at               TIMESTAMPTZ NOT NULL DEFAULT now()

-- NEW columns (additive only in Phase E migration):
updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
max_devices              INTEGER NOT NULL DEFAULT 3
revoked_at               TIMESTAMPTZ nullable
metadata                 JSONB DEFAULT '{}'::jsonb
```

### 7.4 License Types (Row Semantics)

All types are rows in the same `licenses` table. No separate tables.

| Type | status | trial_started_at | trial_expires_at | activated_at | subscription_expires_at | max_devices |
|------|--------|-----------------|-----------------|-------------|----------------------|-------------|
| Trial | `TRIAL` | SET | SET (+14d) | NULL | NULL | 3 |
| Paid Active | `ACTIVE` | NULL | NULL | SET | SET (or NULL) | per-plan |
| Perpetual | `PERPETUAL` | NULL | NULL | SET | NULL | per-plan |
| Expired | `EXPIRED` | SET or NULL | SET (past) | SET or NULL | SET (past) | - |
| Suspended | `SUSPENDED` | - | - | - | - | 0 |
| Revoked | `REVOKED` | - | - | - | - | 0 |

---

## 8. Trial Semantics

### 8.1 Trial Duration

```
TRIAL_DURATION = 14 days (constant, server-enforced)
```

From `PROJECT_MASTER_PLAN.md` section 5 Decision D12: "Trial period: 14 days, server-controlled."

### 8.2 Trial Start Event

The trial starts when the **first owner creates a shop** during initial onboarding:

```
AUTHORITATIVE_EVENT = First successful create_shop_with_owner() + start_trial()
```

**Rationale:**
- A shop must exist before licensing (license is shop-scoped)
- Owner must be authenticated (identity established)
- Shop creation + trial start should be atomic
- Matches existing `start_trial()` which requires owner membership

### 8.3 Trial Timing Semantics

| Question | Answer |
|----------|--------|
| When do 14 days start? | When `start_trial()` executes server-side |
| What creates `trial_started_at`? | `now()` inside `start_trial()` PostgreSQL function |
| Where is `trial_started_at` stored? | `licenses.trial_started_at` column (Supabase) |
| How is `trial_ends_at` calculated? | `now() + INTERVAL '14 days'` server-side, stored in `licenses.trial_expires_at` |
| Is it stored or derived? | **Stored** (for performance and offline cache) |
| Reinstall behavior? | Same shop = same license row, trial NOT restarted |
| New device login? | Same shop = same license, trial NOT restarted |
| Clock change? | Irrelevant - server timestamps are authority |
| Delete app + reinstall? | New installation_id, but same shop license persists |
| Create new account + new shop? | NEW trial for NEW shop (each shop gets own trial) |

### 8.4 Trial Non-Resettable Guarantee

```sql
-- Inside start_trial():
IF EXISTS(
  SELECT 1 FROM licenses
  WHERE shop_id = p_shop_id
    AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
) THEN
  RAISE EXCEPTION 'Shop already has an active license or trial';
END IF;
```

Prevents:
- Double-start on retry
- Login from two devices simultaneously
- Network timeout causing duplicate
- Reinstall restarting the trial
- Creating a second owner account for the same shop

### 8.5 Trial Scope

| Scope | Is trial tied to? | Rationale |
|-------|-------------------|-----------|
| Shop | YES | Decision D13: "License scope: Shop-scoped" |
| User | NO | Owner and employees share shop's trial |
| Device | NO | Trial is a shop entitlement, not per-device |
| Organization | N/A | Phase E has single-shop-per-owner model |
| Auth session | NO | Trial persists across logins |

### 8.6 Trial Lifecycle

```
Shop Created
  -> start_trial() called
  -> License row: status='TRIAL', trial_started_at=now(), trial_expires_at=now()+14d
  -> trial_active = true (for 14 days)

After 14 days (server time):
  -> verify_license_entitlement() detects trial_expires_at < now()
  -> Entitlement state: trial_expired
  -> Business writes blocked
  -> Data preserved, read-only mode

Owner activates paid license:
  -> License row updated: status='ACTIVE', activated_at=now()
  -> Entitlement state: licensed_active
  -> Full access restored
```

---

## 9. Server-Time Authority

### 9.1 Mechanism

All time-critical operations use **PostgreSQL `now()`** inside **SECURITY DEFINER functions**:

```sql
-- Trial creation
INSERT INTO licenses (..., trial_started_at, trial_expires_at)
VALUES (..., now(), now() + INTERVAL '14 days');

-- Entitlement verification
IF v_license.trial_expires_at > now() THEN ...

-- Device heartbeat
UPDATE devices SET last_seen_at = now() WHERE ...;

-- Activation verification
UPDATE activations SET last_verified_at = now() WHERE ...;
```

### 9.2 Why This Prevents Tampering

| Attack | Why It Fails |
|--------|-------------|
| Change local clock forward | Server `now()` is independent of client clock |
| Change local clock backward | Server `now()` is independent of client clock |
| Edit local SQLite | Local SQLite has no licensing data (stored in Supabase) |
| Edit SharedPreferences | No licensing timestamps stored locally (cached copy informational only) |
| Edit DPAPI file | DPAPI system replaced by cloud authority |
| Replay old server response | Responses include current timestamp; client detects staleness |
| Direct Supabase REST call | RLS prevents unauthorized writes; SECURITY DEFINER validates ownership |

### 9.3 Client Time Usage

Client-side time used ONLY for:
- **UX display:** "13 days remaining" from cached `server_trial_ends_at - DateTime.now()`
- **Staleness detection:** If `DateTime.now()` significantly ahead of `last_server_sync_at`, force re-sync
- **Never for entitlement decisions:** Server response determines access

---

## 10. Shop-License Relationship

### 10.1 One Active License Per Shop

Enforced by application logic in `start_trial()`: only one TRIAL/ACTIVE/PERPETUAL license per shop.

### 10.2 License Lifecycle per Shop

```
[No license]
  -> start_trial() [owner only, first time]
  -> TRIAL (14 days)
  -> [time passes]
  -> EXPIRED
  -> [owner purchases]
  -> ACTIVE (paid, with expiry or perpetual)
  -> [optional]
  -> SUSPENDED (admin action)
  -> [optional]
  -> REVOKED (admin action, terminal)
```

### 10.3 Multi-License History

A shop may have multiple license rows over time (historical). Only ONE can be in non-terminal active state at a time. `verify_license_entitlement()` resolves the CURRENT effective license:

```sql
SELECT * FROM licenses
WHERE shop_id = p_shop_id
  AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
ORDER BY created_at DESC
LIMIT 1;
```

---

## 11. User/Membership Boundary

### 11.1 Membership is Not Entitlement

```
Membership = user can access shop data (role + permissions)
Entitlement = shop is licensed to use the application
```

A user can have ACTIVE membership but the shop's trial may have expired. In that case:
- User IS authenticated (membership valid)
- User CAN read data (membership allows)
- User CANNOT write business data (entitlement expired)

### 11.2 Owner vs Employee Entitlement

| Role | Can start trial? | Can view license status? | Can activate paid license? |
|------|-----------------|------------------------|--------------------------|
| Owner | YES | YES | YES |
| Employee | NO | YES | NO |
| SalesOnly | NO | NO | NO |

### 11.3 Employee Impact on Trial

Employees do NOT receive individual trials. The shop's license/trial is shared:
- Owner creates shop -> trial starts
- Owner invites employees -> employees join under the SAME shop license
- Trial expires -> ALL users lose write access
- Paid license activated -> ALL users regain write access
- Adding employees does NOT reset trial
- Removing employees does NOT affect trial

---

## 12. Device Model

### 12.1 Identity Hierarchy

```
Installation Identity
  -> Generated once per app install
  -> Stored in app_settings['device.installationId']
  -> UUID v4, generated locally
  -> Survives app restart, login/logout, shop switching
  -> Does NOT survive uninstall + reinstall (new UUID generated)

Device Record (cloud)
  -> One row per (installation_id, shop_id) pair
  -> Represents: "this installation has accessed this shop"
  -> Tracks: platform, device_name, first_seen_at, last_seen_at, status

User Association (optional)
  -> devices.user_id links to the user who registered the device
  -> Multiple users can use same installation
```

### 12.2 Device Identity Distinction

| Identity | Type | Lifetime | Purpose |
|----------|------|----------|---------|
| `auth.uid()` | UUID (Supabase) | Per auth session | User authentication |
| `shop_members.user_id + shop_id` | UUID pair | Persistent | Shop membership |
| `devices.installation_id` | UUID (local) | Per app installation | Device tracking |
| `devices.id` | UUID (cloud) | Persistent | Cloud device record PK |
| `activations.id` | UUID (cloud) | Persistent | Activation record PK |

### 12.3 No Aggressive Hardware Fingerprinting

Phase E uses `installation_id` (locally-generated UUID) for device identity, NOT hardware fingerprinting.

**Rationale:**
- Hardware fingerprinting requires platform-specific native code
- Android has restrictions on hardware identifiers
- `installation_id` is sufficient for activation tracking
- Hardware fingerprinting increases complexity without proportional security benefit

The existing `DeviceIdentity` class (Windows HW fingerprint) is **retained** as a secondary verification signal but NOT as primary device identity for cloud operations.

### 12.4 Installation Identifier Policy

```dart
// Generated once, stored in app_settings
String installationId = app_settings['device.installationId'];
if (installationId == null) {
  installationId = Uuid().v4(); // Generate new
  app_settings['device.installationId'] = installationId;
}
```

**Survives:** app restart, login/logout, shop switching, cache clear
**Does NOT survive:** uninstall + reinstall (new UUID)
**Not a security proof:** installation_id can be edited by someone with filesystem access, but this is acceptable for Phase E (server enforcement is primary)

---

## 13. Activation Model

### 13.1 Activation Scope

```
Activation = binding between a License and a Device
  -> One activation per (license_id, device_id)
  -> License is per-shop
  -> Device is per-installation
  -> Therefore: activation is per-installation-per-shop
```

### 13.2 Activation Lifecycle

```
Device first accesses shop
  -> register_device() RPC: creates devices row if not exists
  -> activate_device() RPC: creates activations row
  -> Activation count checked against max_devices

Device subsequent access
  -> register_device() RPC: updates last_seen_at
  -> Entitlement check: verify_license_entitlement()
  -> No new activation needed

Device removed by owner
  -> deactivate_device() RPC: sets activations.status = 'REVOKED'
  -> Device slot freed

Device installation reinstalled
  -> New installation_id generated
  -> Old devices row becomes stale
  -> New devices row created on next login
  -> Old activation does NOT transfer automatically
  -> Owner must deactivate old device to free slot
```

### 13.3 Max Devices Policy

| License Type | Default max_devices | Notes |
|-------------|--------------------|-------|
| TRIAL | 3 | Can be modified by admin |
| ACTIVE | 3 | Per-plan, adjustable |
| PERPETUAL | 3 | Per-plan, adjustable |
| EXPIRED | 0 | No new activations |
| SUSPENDED | 0 | No new activations |
| REVOKED | 0 | Terminal |

### 13.4 Device Limit Enforcement

```sql
-- Inside activate_device():
SELECT COUNT(*) INTO v_current_count
FROM activations a
JOIN devices d ON a.device_id = d.id
WHERE a.license_id = p_license_id
  AND a.status = 'ACTIVE'
  AND d.status = 'ACTIVE';

IF v_current_count >= v_max_devices THEN
  RAISE EXCEPTION 'Device limit reached (%/%)', v_current_count, v_max_devices;
END IF;
```

### 13.5 Owner Device Policy

The owner needs device activation like any other user. No special owner bypass for device limits. Owner can deactivate their own old devices to free slots.

### 13.6 Device Deactivation

Owner can deactivate any device in their shop. This is an owner-only operation via `deactivate_device()` RPC. Sets `activations.status = 'REVOKED'`, freeing one device slot.

### 13.7 Device Transfer

When a user moves to a new device:
1. Old device: owner deactivates it (or it stays stale)
2. New device: installation_id is new, registers as new device
3. New activation created (if slots available)
4. Old activation becomes orphaned (cleaned up periodically or by owner)

---

## 14. License State Machine

### 14.1 Three Separate State Dimensions

Phase E separates concerns into three distinct state dimensions rather than merging them into one monolithic enum:

**Dimension 1: License Entitlement State** (server-resolved)
```
no_license -> trial_active -> trial_expired -> licensed_active -> licensed_expired
                                          \-> licensed_active (perpetual)
                                          \-> licensed_suspended
                                          \-> licensed_revoked
```

**Dimension 2: Device Activation State** (server-resolved)
```
not_registered -> registered -> activated -> deactivated
```

**Dimension 3: Connectivity State** (client-detected)
```
online -> offline -> stale
```

### 14.2 Client-Side Combined Resolution

The client combines all three dimensions to produce a single UI-facing state:

| License Entitlement | Device Activation | Connectivity | Client State | Writes Allowed? |
|--------------------|--------------------|--------------|--------------|----------------|
| trial_active | activated | online | `entitled` | YES |
| trial_active | activated | offline | `entitled_cached` | YES (grace) |
| trial_active | not_registered | online | `activating` | BLOCKED (until activation) |
| trial_active | not_registered | offline | `offline_no_activation` | NO |
| trial_expired | any | any | `expired` | NO |
| licensed_active | activated | online | `entitled` | YES |
| licensed_active | activated | offline | `entitled_cached` | YES (grace) |
| licensed_active | not_registered | online | `activating` | BLOCKED (until activation) |
| licensed_active | deactivated | any | `device_revoked` | NO |
| licensed_active | any | offline (beyond grace) | `stale_offline` | NO |
| licensed_expired | any | any | `expired` | NO |
| licensed_suspended | any | any | `suspended` | NO |
| licensed_revoked | any | any | `revoked` | NO |
| no_license | any | online | `no_license` | NO |
| no_license | any | offline | `offline_no_license` | NO |

### 14.3 Server-Side RPC: verify_license_entitlement()

This is the central server-side function that resolves entitlement for a given shop:

```sql
CREATE OR REPLACE FUNCTION verify_license_entitlement(p_shop_id UUID)
RETURNS TABLE (
  has_license BOOLEAN,
  license_status TEXT,
  is_trial BOOLEAN,
  trial_active BOOLEAN,
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  days_remaining INTEGER,
  hours_remaining INTEGER,
  activated_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  max_devices INTEGER,
  current_devices BIGINT,
  device_slot_available BOOLEAN,
  server_time TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Returns:
- License existence and status
- Trial active/expired with remaining time (server-computed)
- Device count and slot availability
- Server timestamp (for client staleness detection)

### 14.4 State Transition Triggers

| Transition | Trigger | Actor | Server Validation |
|-----------|---------|-------|-------------------|
| no_license -> trial_active | `start_trial()` | Owner | Owner check, no-existing-license check |
| trial_active -> trial_expired | Time (14 days) | Automatic | `trial_expires_at < now()` |
| trial_expired -> licensed_active | Admin issues license | I Tech | Service-role UPDATE |
| licensed_active -> licensed_expired | Time (subscription) | Automatic | `subscription_expires_at < now()` |
| licensed_active -> licensed_suspended | Admin action | I Tech | Service-role UPDATE |
| licensed_suspended -> licensed_active | Admin action | I Tech | Service-role UPDATE |
| licensed_active -> licensed_revoked | Admin action | I Tech | Service-role UPDATE |
| any -> revoked | Admin action | I Tech | Service-role UPDATE (terminal) |

---

## 15. Trial State Machine

### 15.1 Trial States

```
  [NO LICENSE]            [TRIAL ACTIVE]           [TRIAL EXPIRED]
       |                       |                         |
       |  start_trial()        |  now() > expires_at     |
       +---------------------->|                         |
       |                       |                         |
       |                       |  paid activation        |
       |                       +------------------------>|-----> [LICENSED ACTIVE]
       |                       |                         |
       |                       |  (terminal)             |
       |                       +-- REVOKED ------------->
```

### 15.2 Trial-Only Transitions

| From | To | Trigger | Condition |
|------|----|---------|-----------|
| NO LICENSE | TRIAL ACTIVE | `start_trial()` | Owner call, no existing TRIAL/ACTIVE/PERPETUAL |
| TRIAL ACTIVE | TRIAL EXPIRED | Time | `trial_expires_at < now()` server-time |
| TRIAL ACTIVE | LICENSED ACTIVE | Admin issue | I Tech sets status='ACTIVE' |
| TRIAL ACTIVE | REVOKED | Admin action | Terminal |
| TRIAL EXPIRED | LICENSED ACTIVE | Admin issue | I Tech sets status='ACTIVE' |
| TRIAL EXPIRED | REVOKED | Admin action | Terminal |

### 15.3 Trial Cannot Be:

- Restarted (same shop)
- Extended by client (only server)
- Reset by reinstall
- Reset by new user
- Reset by new device
- Reset by changing clock
- Reset by deleting local data

---

## 16. Multi-Device Policy

### 16.1 Default Limits

| License Type | max_devices | Notes |
|-------------|-------------|-------|
| TRIAL | 3 | Default, admin-adjustable |
| ACTIVE | 3 | Default, per-plan |
| PERPETUAL | 3 | Default, per-plan |

### 16.2 Device Counting

Counts distinct `devices` rows with active activations for a given license:

```sql
SELECT COUNT(DISTINCT d.id)
FROM activations a
JOIN devices d ON a.device_id = d.id
WHERE a.license_id = v_license_id
  AND a.status = 'ACTIVE'
  AND d.status = 'ACTIVE';
```

### 16.3 Device Lifecycle Scenarios

| Scenario | Behavior |
|----------|----------|
| First device login | Device registered, activated, count = 1 |
| Second device login | Device registered, activated, count = 2 |
| Third device login | Device registered, activated, count = 3 (at limit) |
| Fourth device login | BLOCKED: device limit reached |
| Owner deactivates old device | Slot freed, count = 2, new device can activate |
| App reinstalled on same machine | New installation_id, new device row, old becomes stale |
| Device replaced (hardware) | Old device stale, new device registered if slots available |
| Device lost/destroyed | Owner deactivates, slot freed |

### 16.4 Stale Device Cleanup

Devices with `last_seen_at` older than 90 days and no recent heartbeat are candidates for soft cleanup. This is a future maintenance concern, not Phase E scope. Owner can always manually deactivate.

---

## 17. Multi-Shop Policy

### 17.1 License is Shop-Scoped

Each shop has its own independent license. The same authenticated user may belong to multiple shops with different license states:

```
User X belongs to:
  Shop A: licensed_active (paid license)
  Shop B: trial_active (14-day trial, 5 days remaining)
  Shop C: trial_expired (trial ended, no paid license)
```

### 17.2 Active Shop Determines Entitlement

When a user selects an active shop:
1. `SessionState.activeShopId` is set to the selected shop
2. `verify_license_entitlement(activeShopId)` is called
3. The result determines what the user can do in THIS shop
4. Switching shops re-resolves entitlement

### 17.3 Shop Switch Does NOT Require Re-Authentication

Switching shops within the same session:
- Does NOT require logout/login
- DOES re-resolve license entitlement for the new shop
- DOES re-check device activation for the new shop
- May change available capabilities (e.g., Shop A allows writes, Shop B does not)

### 17.4 Shop Switch Flow

```
User switches from Shop A to Shop B:
  1. SessionState.setActiveShop(shopB_id)
  2. CloudLicensingService.resolveEntitlement(shopB_id)
     -> calls verify_license_entitlement(shopB_id)
     -> returns: trial_expired for Shop B
  3. App shows: "Trial expired for this shop"
  4. Business writes blocked for Shop B
  5. User can still READ data for Shop B
  6. User can switch back to Shop A (writes allowed)
```


---

## 18. Offline Policy

### 18.1 Core Principle

The application is Local-first.

Business data such as products, sales, returns, expenses, customers, suppliers, and reports remains stored locally in SQLite.

Licensing controls entitlement to perform protected mutations; expiration or loss of connectivity MUST NOT delete local business data.

Where product policy permits, expired or unresolved entitlement should degrade to a safe read-only / license-required state rather than destructive behavior.

### 18.2 Authority Model

Online license resolution from the I Tech backend is authoritative.

The client may persist the latest successfully resolved entitlement snapshot for temporary offline use, but that snapshot is a cache only.

The following remain server-authoritative:

- license status
- trial_started_at
- trial_ends_at
- paid-license starts_at / expires_at
- suspension
- revocation
- max device entitlement
- activation validity
- authoritative server time

Neither SQLite, SharedPreferences/app_settings, the Windows clock, nor the Android clock may create, reset, extend, renew, suspend, revoke, or otherwise redefine entitlement.

### 18.3 Offline Entitlement Resolution

| Scenario | Last Authoritative State | Offline Behavior |
| --- | --- | --- |
| First install with no successful licensing sync | None | No write entitlement; online verification required |
| Previously verified trial and trial still valid under cached authoritative snapshot | trial_active | Temporary offline writes allowed within validation window |
| Previously verified paid license | licensed_active | Temporary offline writes allowed within validation window |
| Cached trial already expired | trial_expired | No protected writes; read-only/license-required state |
| Cached license expired/suspended/revoked | non-entitled | No protected writes |
| Device never successfully activated | none | No write entitlement; online activation required |
| Entitlement cache missing/corrupt/unreadable | unknown | Fail closed for protected writes; preserve readable local data |
| Cached entitlement exceeds permitted offline validation window | stale | Online revalidation required before protected writes |

### 18.4 Cached Entitlement Snapshot

After each successful authoritative online resolution, the client may cache values such as:

    cloud.license.status
    cloud.license.trialActive
    cloud.license.trialExpiresAt
    cloud.license.licenseStartsAt
    cloud.license.licenseExpiresAt
    cloud.license.serverTimeAtVerification
    cloud.license.maxDevices
    cloud.license.currentDevices
    cloud.license.lastSuccessfulVerificationAt
    cloud.device.activated
    cloud.device.activationId

If useful for tamper detection, the client may additionally retain:

    cloud.license.localWallClockAtVerification
    cloud.license.lastObservedLocalWallClock

These local-clock fields are NOT authoritative entitlement data.

**Field Classification:**

AUTHORITATIVE CACHED COPY:
- status, trial expiry, license expiry, max devices, activation result, server time

LOCAL METADATA:
- cache-write timestamp, last observed wall clock, local installation identifier

DERIVED:
- display strings such as "3 days remaining", UI banner state, tentative offline-age calculation

### 18.5 Offline Validation Window

Bounded offline entitlement validation window:

    OFFLINE_REVALIDATION_WINDOW = 24 hours

An otherwise entitled installation should attempt server revalidation at least once every 24 hours before continuing protected mutations.

This 24-hour value is an offline revalidation policy. It MUST NOT:

- add 24 hours to the trial
- extend trial_ends_at
- renew an expired license
- override suspension/revocation once known
- create entitlement for a never-verified installation

If PROJECT_MASTER_PLAN.md or an already-approved product rule specifies a different duration, follow the governing rule and document the difference.

### 18.6 Do Not Use DateTime.now() as Licensing Authority

Do NOT implement a rule whose security decision is simply:

    DateTime.now() < trialEndsAt

or:

    DateTime.now().difference(lastSyncedAt) < 24 hours

as the sole proof of entitlement.

The device wall clock is user-controlled.

Changing it backwards must never extend a trial.

Changing it forwards may conservatively cause early revalidation, which is acceptable from a security perspective, but should produce a clear recoverable UX rather than data loss.

### 18.7 Server-Time Anchor

Every successful online entitlement resolution returns an authoritative server timestamp:

    server_time_at_verification

The entitlement snapshot also contains server-derived absolute expiry timestamps:

    trial_ends_at, license_expires_at

The client uses these values as authoritative temporal anchors.

While the process remains alive, a monotonic elapsed-time source may be used to estimate progression from server_time_at_verification because a monotonic timer is not affected by normal wall-clock edits:

    estimated_server_now = server_time_at_verification + monotonic_elapsed_since_verification

Do not claim that a process-local monotonic timer survives an application restart.

### 18.8 Restart and Persistent Clock-Tamper Handling

After an application restart, the client cannot prove elapsed server time solely from a process-local monotonic timer.

Therefore the offline policy must fail safely.

Persist the last observed local wall-clock value only as a tamper-detection heuristic.

If the current device time moves materially backwards relative to the last observed value (beyond a small tolerance for normal clock synchronization):

    CLOCK_ROLLBACK_DETECTED

Then:

- do not extend cached entitlement
- do not reset any expiry
- require authoritative online revalidation before protected writes
- preserve all local data
- allow safe read access according to product policy
- show a recoverable "license verification required" state

The exact tolerance should be defined during implementation and tested.

### 18.9 Trial-Specific Offline Rules

For trial entitlement:

- Trial duration is exactly 14 days according to authoritative server state.
- Offline mode MUST NOT create a trial.
- Offline mode MUST NOT restart a trial.
- Offline mode MUST NOT extend trial_ends_at.
- Reinstall MUST NOT create a new trial for the same shop.
- Creating another user or employee MUST NOT create a new trial.
- Switching devices MUST NOT create a new shop trial.
- Local clock rollback MUST NOT extend trial access.
- If cached authoritative state already says trial_expired, protected writes remain blocked.
- If authoritative trial_ends_at is known to have been reached, protected writes remain blocked.
- If the client cannot safely establish whether an offline trial remains valid, it must require online revalidation rather than assume entitlement.
- A stale entitlement cache cannot override trial expiry.
- Offline grace is never added to trial_ends_at.

### 18.10 Paid-License Offline Rules

A previously verified paid license may use the same bounded offline validation mechanism.

However:

- offline cache cannot renew the license
- offline cache cannot undo suspension
- offline cache cannot undo revocation
- offline cache cannot increase max_devices
- offline cache cannot authorize a previously unactivated installation

Once the client learns from the server that a license is suspended, revoked, or expired, that non-entitled state must be cached and respected offline.

### 18.11 First-Run / Never-Verified Rule

A device or installation that has never successfully completed authoritative licensing resolution receives no offline write entitlement.

    FIRST INSTALL + NO SERVER VERIFICATION = ONLINE VERIFICATION REQUIRED

This prevents a fresh install from fabricating a local entitlement record.

### 18.12 Reinstall Rule

Reinstalling may remove local cache and installation metadata.

That does NOT affect the server-side shop trial or license.

After reinstall:

- authenticate
- resolve shop membership
- resolve shop entitlement from server
- register/resolve installation/device according to Phase E device policy
- activate if allowed

No local reinstall event may reset the 14-day trial.

### 18.13 Cache Corruption

If cached entitlement data is malformed, incomplete, internally inconsistent, from another shop, from another activation, or unreadable, the application must fail closed for protected mutations.

It must NOT delete business data.

Online entitlement revalidation should repair the cache.

### 18.14 Shop Switching

Entitlement cache must be scoped by active shop.

Never reuse Shop A entitlement for Shop B.

When the active shop changes:

- load the entitlement snapshot for that shop if one exists
- otherwise require resolution
- independently verify device activation for that shop
- recompute application access state

### 18.15 Membership Interaction

Cached licensing entitlement does not override membership.

The application must still respect the latest known membership state.

When online, revoked or disabled membership takes precedence immediately.

An employee never receives a separate 14-day trial simply because the employee authenticated on another installation.

### 18.16 Offline Security Posture

Offline mode is a temporary continuity mechanism, not an alternate licensing authority.

| State | Offline Posture |
| --- | --- |
| UNKNOWN | fail closed for protected writes |
| KNOWN EXPIRED / SUSPENDED / REVOKED | fail closed for protected writes |
| KNOWN ACTIVE + VALID RECENT SNAPSHOT | temporary offline entitlement per policy |
| CLOCK ROLLBACK / CACHE TAMPER / CORRUPTION | authoritative online revalidation required |

In every case: NO DESTRUCTIVE DATA ACTION.

### 18.17 Design Note on Local Cache Security

Phase E does NOT introduce cryptographically signed offline entitlement tokens.

The local entitlement snapshot is a continuity cache protected primarily by bounded staleness, server authority, reinstall behavior, server-side trial identity, revalidation requirements, and fail-closed mutation gating.

Do not describe ordinary local JSON/preferences as "trusted" merely because its original values came from the server.

A user with sufficient local machine access may edit local application state.

The architecture must not depend on the local cache as the permanent security authority.


---

## 19. Offline Grace

### 19.1 Grace Policy

| License State | Offline Grace Duration | Rationale |
| --- | --- | --- |
| TRIAL (active) | Until cached trial_ends_at | Server-computed expiry is authoritative |
| ACTIVE (paid) | 7 days from last server sync | Paid customer should not be blocked by brief connectivity loss |
| PERPETUAL | 14 days from last server sync | Perpetual license gets longest grace |
| EXPIRED | None | Already expired |
| SUSPENDED | None | Already suspended |
| REVOKED | None | Already revoked |
| Never-synced | None | Must go online first |

### 19.2 Grace Does NOT Extend License

Offline grace is a UX accommodation, not a license extension:

- Grace allows the app to continue operating based on last known good state
- Grace does NOT extend trial_ends_at or subscription_expires_at
- Grace does NOT create new entitlement that did not exist
- Grace expires when the staleness threshold is exceeded
- The server is always the authority; offline grace is temporary trust of cached state

### 19.3 First Launch Without Internet

- No cached entitlement exists
- No server resolution possible
- App shows: "Internet connection required for first-time setup"
- User must connect to internet to start trial / activate
- Once synced, offline grace applies per policy above

---

## 20. Local Cache Boundary

### 20.1 Data Classification

| Data | Classification | Source | Mutable by Client? |
| --- | --- | --- | --- |
| license status | cached | server RPC response | NO |
| trial_active | cached | server RPC response | NO |
| trial_ends_at | cached | server RPC response | NO |
| server_time | cached | server RPC response | NO |
| max_devices | cached | server RPC response | NO |
| current_devices | cached | server RPC response | NO |
| last_synced_at | derived | local DateTime.now() | YES |
| device.activated | cached | server RPC response | NO |
| device.activation_id | cached | server RPC response | NO |
| installation_id | authoritative | local-generated UUID | Once only |
| EntitlementState | derived | computed from cached values | YES |

### 20.2 What is NEVER Stored Locally

- trial_started_at (server-authoritative)
- license_key (server-authoritative)
- activated_at (server-authoritative)
- subscription_expires_at (server-authoritative)
- revoked_at (server-authoritative)

### 20.3 Cache Integrity

The local cache is informational. If tampered with, next server sync overwrites with authoritative values. Cached values are NEVER used to grant NEW entitlement. Cached values CAN be used to MAINTAIN existing entitlement during offline grace. Cached values CAN be used to DENY entitlement when expiry is clearly passed.

---

## 21. Flutter Licensing Architecture

### 21.1 Layered Design

```
UI Layer (Screens/Widgets)
    |
    v
CloudLicensingService (domain logic)
    |
    +-- CloudLicensingRepository (Supabase RPC calls)
    |       |
    |       +-- verify_license_entitlement() RPC
    |       +-- start_trial() RPC
    |       +-- register_device() RPC
    |       +-- activate_device() RPC
    |       +-- deactivate_device() RPC
    |
    +-- EntitlementCache (local persistence of server snapshot)
    |
    +-- OfflineGracePolicy (staleness + clock-tamper detection)
    |
    v
DatabaseHelper._enforceLicensing() (existing enforcement boundary)
```

### 21.2 CloudLicensingService Responsibilities

| Method | Purpose |
| --- | --- |
| initialize() | Startup: load cache, check staleness, attempt online resolution |
| resolveEntitlement(shopId) | Call verify_license_entitlement RPC, update cache |
| startTrial(shopId) | Call start_trial RPC, update cache |
| registerDevice(shopId) | Call register_device RPC |
| activateDevice(shopId) | Call activate_device RPC |
| deactivateDevice(activationId) | Owner deactivates a device |
| refreshEntitlement(shopId) | Force online revalidation |
| checkEntitlement() | Return current cached + derived entitlement state |

### 21.3 EntitlementCache Responsibilities

| Method | Purpose |
| --- | --- |
| save(shopId, snapshot) | Persist server snapshot to app_settings |
| load(shopId) | Load cached snapshot for a shop |
| isStale(shopId) | Check if cache exceeds OFFLINE_REVALIDATION_WINDOW |
| detectClockRollback() | Compare current wall clock to last observed |
| clear(shopId) | Invalidate cache for a shop |

### 21.4 Enforcement Boundary

The existing `DatabaseHelper._enforceLicensing()` mechanism is retained. The callback is updated:

```
// Before Phase E:
DatabaseHelper.setLicensingEnforcer(() => LicensingService.instance.enforceActive());

// After Phase E:
DatabaseHelper.setLicensingEnforcer(() => CloudLicensingService.instance.enforceActive());
```

The `enforceActive()` method checks the current entitlement state (from cache + derived) and throws `LicenseActivationRequiredException` if writes are not allowed.

### 21.5 Why NOT Modify CloudSession

CloudSession remains a pure authentication/membership value object. Licensing state is a separate concern managed by CloudLicensingService. This avoids turning CloudSession into a God Object.

The flow is:

    CloudSession (auth + membership)
    -> CloudLicensingService.resolveEntitlement(activeShopId)
    -> EntitlementState (derived)
    -> DatabaseHelper enforcement

---

## 22. CloudSession Integration

### 22.1 SessionState Extension

SessionState gains a licensing-awareness without absorbing licensing logic:

```
class SessionState extends ChangeNotifier {
  User? _currentUser;
  CloudSession? _cloudSession;
  // NEW: not owned by SessionState, but consulted during login flow

  // After login + shop resolution:
  // CloudLicensingService.resolveEntitlement(activeShopId)
  // Result stored in CloudLicensingService._currentState
  // SessionState does NOT store licensing state directly
}
```

### 22.2 Integration Flow

```
Login
  -> Supabase Auth (CloudAuthService)
  -> Identity resolution (users.cloud_uuid)
  -> Shop membership (get_user_shops)
  -> Active shop selection (ShopResolver)
  -> License resolution (CloudLicensingService.resolveEntitlement)
  -> Device registration/activation (CloudLicensingService.registerDevice)
  -> Entitlement state determined
  -> DatabaseHelper enforcement wired
  -> Application shell (with entitlement-aware UI)
```

---

## 23. First Owner Setup Integration

### 23.1 Trial Start During Onboarding

When a fresh owner completes setup:

```
FirstOwnerSetupScreen
  -> create local user (UserRepository)
  -> cloud signup (auth.signUp)
  -> create shop (create_shop_with_owner RPC)
  -> receives shop_id
  -> start trial (start_trial RPC) <-- NEW in Phase E
  -> register device (register_device RPC) <-- NEW in Phase E
  -> activate device (activate_device RPC) <-- NEW in Phase E
  -> persist identity (IdentityLinker)
  -> CloudLicensingService caches entitlement snapshot
  -> App enters cloud-aware mode with active trial
```

### 23.2 Idempotency

- `start_trial()` is idempotent: checks for existing license first
- `register_device()` is idempotent: upserts by (installation_id, shop_id)
- `activate_device()` is idempotent: checks for existing activation first
- Double-submit, retry, and timeout are all safe

### 23.3 Partial Success Recovery

| State | Detection | Recovery |
| --- | --- | --- |
| Shop created, trial not started | get_user_shops returns shop, verify_license_entitlement returns no_license | Call start_trial |
| Trial started, device not registered | verify_license_entitlement returns entitlement, but device not activated | Call register_device + activate_device |
| Device registered, activation failed | device exists but no activation, device limit check | Show device limit message or retry |

---

## 24. Login Flow Integration

### 24.1 Complete Login Flow (Post Phase E)

```
LoginScreen
  -> LOCAL: UserRepository.authenticate(username, password) [PBKDF2]
  -> SessionState.login(user)
  -> Check ShopProfile.cloudUuid
     -> if null: local-only mode (no cloud licensing)
     -> if set: cloud-aware mode
        -> Supabase Auth signInWithPassword
        -> get_user_shops -> resolve active membership
        -> ShopResolver.resolveActiveShop
        -> CloudLicensingService.resolveEntitlement(activeShopId)
           -> verify_license_entitlement(activeShopId) RPC
           -> register_device(activeShopId) RPC
           -> activate_device(activeShopId) RPC (if needed)
           -> cache entitlement snapshot
        -> Set enforcement callback
        -> App shell with entitlement-aware UI
```

### 24.2 Branch: Trial Active

```
Entitlement: trial_active, device activated
  -> Allow all operations
  -> Show trial banner: "Trial: X days remaining"
  -> Settings shows license section with trial info
```

### 24.3 Branch: Trial Expired

```
Entitlement: trial_expired
  -> Block all business writes
  -> Allow reads
  -> Show: "Trial expired. License required."
  -> Settings shows license section with renewal prompt
  -> Owner can see "Contact I Tech" for paid license
```

### 24.4 Branch: Licensed Active

```
Entitlement: licensed_active, device activated
  -> Allow all operations
  -> No trial banner
  -> Settings shows license section with license info
```

### 24.5 Branch: Device Limit Reached

```
Entitlement: entitled but device not activated, limit reached
  -> Block business writes until device slot available
  -> Show: "Device limit reached. Contact shop owner."
  -> Owner can deactivate old devices
```

### 24.6 Branch: Server Unreachable (Cached Entitlement)

```
Entitlement: cached, within grace window
  -> Allow writes based on cached entitlement
  -> Show offline indicator
  -> Attempt background revalidation
```

### 24.7 Branch: Server Unreachable (No Cache)

```
Entitlement: unknown, never synced
  -> Block all business writes
  -> Show: "Internet connection required for license verification"
```

### 24.8 Branch: Clock Rollback Detected

```
Entitlement: unknown (clock tamper suspected)
  -> Block all business writes
  -> Show: "License verification required"
  -> Require online revalidation
```

---

## 25. Backend Authority Model

### 25.1 Client vs Server Operations

| Operation | Client Direct? | Server RPC? | Edge Function? | Notes |
| --- | --- | --- | --- | --- |
| Read license status | NO | YES (RLS) | NO | Via verify_license_entitlement |
| Start trial | NO | YES (SECURITY DEFINER) | NO | start_trial function |
| Activate device | NO | YES (SECURITY DEFINER) | NO | activate_device function |
| Deactivate device | NO | YES (SECURITY DEFINER) | NO | owner-only check |
| Register device | NO | YES (SECURITY DEFINER) | NO | register_device function |
| Update license status | NO | NO (service-role only) | NO | I Tech admin only |
| Set trial dates | NO | NO (service-role only) | NO | I Tech admin only |
| Change max_devices | NO | NO (service-role only) | NO | I Tech admin only |
| Suspend license | NO | NO (service-role only) | NO | I Tech admin only |
| Revoke license | NO | NO (service-role only) | NO | I Tech admin only |

### 25.2 What the Client Can NEVER Do

- Set trial_started_at
- Set trial_ends_at
- Change license status
- Change max_devices
- Bypass device activation
- Override server entitlement decision
- Mutate any licensing table directly

### 25.3 SECURITY DEFINER vs Edge Function Decision

Phase E uses PostgreSQL SECURITY DEFINER functions for ALL licensing operations. No Edge Functions are needed.

**Rationale:**
- PostgreSQL RPCs are sufficient for all licensing operations
- SECURITY DEFINER functions execute with database owner privileges
- They can validate auth.uid(), check ownership, enforce constraints
- Edge Functions add complexity without benefit for these operations
- The only Edge Function (invite-employee) exists from Phase D and is retained
- If future operations require external API calls (email, payment), Edge Functions may be added then

---

## 26. Supabase Schema Changes

### 26.1 New Migration

```
supabase/migrations/20260820000023_phase_e_licensing_enhancements.sql
```

### 26.2 Schema Changes (Additive Only)

**licenses table additions:**

```sql
ALTER TABLE licenses ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE licenses ADD COLUMN max_devices INTEGER NOT NULL DEFAULT 3;
ALTER TABLE licenses ADD COLUMN revoked_at TIMESTAMPTZ nullable;
ALTER TABLE licenses ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
```

**activations table fix:**

```sql
ALTER TABLE activations ADD CONSTRAINT activations_status_check
  CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED'));
```

### 26.3 New Database Functions

| Function | Purpose |
| --- | --- |
| verify_license_entitlement(p_shop_id UUID) | Resolve current entitlement for a shop |
| register_device(p_shop_id UUID, p_installation_id UUID, p_platform TEXT, p_device_name TEXT) | Register or update a device |
| activate_device(p_shop_id UUID, p_installation_id UUID) | Activate a device under the shop license |
| deactivate_device(p_activation_id UUID) | Owner deactivates a device |
| get_device_list(p_shop_id UUID) | Owner views all devices for their shop |

### 26.4 Modified Functions

None. Existing `start_trial()` and `verify_trial_status()` are retained as-is. The new `verify_license_entitlement()` supersedes `verify_trial_status()` for client use but the old function remains for backward compatibility.

### 26.5 New RLS Policies

| Policy | Table | Operation |
| --- | --- | --- |
| (none new) | licenses | Existing SELECT-only policy sufficient |
| (none new) | devices | Existing SELECT-only policy sufficient |
| (none new) | activations | Existing SELECT-only policy sufficient |

All mutations go through SECURITY DEFINER functions. No client-side INSERT/UPDATE/DELETE policies needed.

---

## 27. RLS Design

### 27.1 Current RLS (Phase C, Unchanged)

All 7 original tables + invitations have SELECT-only RLS. Authenticated users can read rows for shops they are active members of. INSERT/UPDATE/DELETE are service-role only.

### 27.2 Phase E RLS Impact

No new RLS policies are needed. The existing policies are sufficient:

- Client reads licenses/devices/activations via RLS (SELECT only)
- Client mutations go through SECURITY DEFINER RPCs (bypass RLS)
- Service-role operations (admin) bypass RLS entirely

### 27.3 Tenant Isolation

RLS ensures:
- User in Shop A cannot read Shop B's license
- User in Shop A cannot read Shop B's devices
- User in Shop A cannot read Shop B's activations
- Only owners of a shop can see device lists (via RPC authorization, not RLS)

### 27.4 Anti-Cross-Shop Attack

| Attack | Mitigation |
| --- | --- |
| Read cross-shop license | RLS blocks (no shop_members row for target shop) |
| Activate device in wrong shop | SECURITY DEFINER function checks auth.uid() ownership |
| Start trial for wrong shop | start_trial() checks auth.uid() is owner of target shop |
| Deactivate device in wrong shop | deactivate_device() checks auth.uid() is owner |

---

## 28. RPC / Database Function Design

### 28.1 verify_license_entitlement(p_shop_id UUID)

```sql
CREATE OR REPLACE FUNCTION verify_license_entitlement(p_shop_id UUID)
RETURNS TABLE (
  has_license BOOLEAN,
  license_status TEXT,
  is_trial BOOLEAN,
  trial_active BOOLEAN,
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  days_remaining INTEGER,
  hours_remaining INTEGER,
  activated_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  max_devices INTEGER,
  current_devices BIGINT,
  device_slot_available BOOLEAN,
  server_time TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Behavior:
- Verifies caller has active membership in the shop
- Finds the most recent active license (TRIAL/ACTIVE/PERPETUAL)
- Computes trial_active based on trial_expires_at vs now()
- Counts current device activations
- Returns server_time for client staleness detection

### 28.2 register_device(p_shop_id UUID, p_installation_id UUID, p_platform TEXT, p_device_name TEXT)

```sql
CREATE OR REPLACE FUNCTION register_device(
  p_shop_id UUID,
  p_installation_id UUID,
  p_platform TEXT,
  p_device_name TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Behavior:
- Verifies caller has active membership
- Upserts device by (installation_id, shop_id)
- Updates last_seen_at to now()
- Returns device.id

### 28.3 activate_device(p_shop_id UUID, p_installation_id UUID)

```sql
CREATE OR REPLACE FUNCTION activate_device(
  p_shop_id UUID,
  p_installation_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Behavior:
- Verifies caller has active membership
- Finds the shop's active license
- Finds the device by (installation_id, shop_id)
- Checks for existing activation (idempotent)
- Counts current active activations against max_devices
- If limit reached, returns error
- Creates activation if needed
- Returns {success, activation_id, devices_remaining}

### 28.4 deactivate_device(p_activation_id UUID)

```sql
CREATE OR REPLACE FUNCTION deactivate_device(p_activation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Behavior:
- Verifies caller is owner of the shop linked to the activation
- Sets activations.status = 'REVOKED'
- Returns true on success

### 28.5 get_device_list(p_shop_id UUID)

```sql
CREATE OR REPLACE FUNCTION get_device_list(p_shop_id UUID)
RETURNS TABLE (
  device_id UUID,
  installation_id UUID,
  platform TEXT,
  device_name TEXT,
  status TEXT,
  first_seen_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ,
  activation_id UUID,
  activation_status TEXT,
  activated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

Behavior:
- Verifies caller is owner of the shop
- Returns all devices with their activation status for the shop

---

## 29. Edge Function Decision

### 29.1 Decision: No New Edge Functions in Phase E

All licensing operations use PostgreSQL SECURITY DEFINER functions. No Edge Functions are needed.

### 29.2 Rationale

| Operation | RPC Sufficient? | Edge Function Needed? |
| --- | --- | --- |
| Trial creation | YES | NO |
| License resolution | YES | NO |
| Device registration | YES | NO |
| Device activation | YES | NO |
| Device deactivation | YES | NO |
| Device listing | YES | NO |
| License admin (future) | Service-role | Possible |

### 29.3 Future Edge Function Triggers

Edge Functions may be needed if:
- Email notifications for trial expiry (SMTP integration)
- Payment webhook processing (billing provider)
- External API integration (I Tech admin backend)

None of these are Phase E scope.

---

## 30. I Tech Administrative Licensing Boundary

### 30.1 I Tech Admin Authority

I Tech for Technology retains server-side administrative authority over all licenses. This is implemented via service-role operations (not client-accessible).

### 30.2 Administrative Operations (Future)

| Operation | Implementation | Phase |
| --- | --- | --- |
| Issue license | Service-role UPDATE on licenses | Later session |
| Extend trial | Service-role UPDATE trial_expires_at | Later session |
| Renew license | Service-role UPDATE subscription_expires_at | Later session |
| Suspend license | Service-role UPDATE status='SUSPENDED' | Later session |
| Revoke license | Service-role UPDATE status='REVOKED' | Later session |
| Increase device limit | Service-role UPDATE max_devices | Later session |
| Manual activation | Service-role INSERT into activations | Later session |

### 30.3 Admin Portal

Phase E does NOT include an admin portal. The administrative operations are designed to be executable via:
- Direct database access (service-role)
- Future admin API (not in Phase E scope)
- Future admin dashboard (not in Phase E scope)

### 30.4 License Issuance Flow (Future)

When I Tech issues a paid license to a shop:

1. I Tech creates/updates the license record via service-role
2. Sets status='ACTIVE', activated_at=now(), subscription_expires_at
3. Sets max_devices per plan
4. Owner's next login resolves the new entitlement
5. No client-side action needed for license issuance


---

## 31. Security Threat Model

### 31.1 Threat Analysis

| Threat | Impact | Mitigation | Residual Risk |
| --- | --- | --- | --- |
| Local clock rollback | Could appear to extend trial | Server-time authority; monotonic timer; clock-rollback detection; fail-closed | LOW |
| Local clock forward | Could skip trial | Conservative: early revalidation triggered, no harm | LOW |
| Delete local database | Removes local data | Licensing is server-side; data loss is user's own action | LOW |
| Delete app preferences | Removes cached entitlement | Cache is informational; online revalidation restores state | LOW |
| Reinstall application | New installation_id | Same shop license persists; trial NOT restarted | LOW |
| Edit SQLite | Licensing not in SQLite | No licensing data in local DB | NONE |
| Edit cached license | Cache tampered | Server sync overwrites; clock-rollback detection; fail-closed | LOW |
| Direct Supabase REST mutation | Modify license data | RLS blocks unauthorized writes; SECURITY DEFINER validates ownership | LOW |
| Cross-shop license access | Read wrong shop license | RLS enforces shop isolation | LOW |
| Cross-shop activation | Activate in wrong shop | RPC checks auth.uid() ownership | LOW |
| Trial timestamp manipulation | Extend trial | Server-only timestamp authority; client cannot set timestamps | LOW |
| Duplicate activation | Claim multiple slots | Idempotent RPC; unique constraints; atomic slot counting | LOW |
| Race-condition device-limit bypass | Exceed max_devices | Atomic COUNT + INSERT in SECURITY DEFINER function | LOW |
| Employee attempting separate trial | Multiple trials | Trial is shop-scoped; employee cannot start trial | NONE |
| New-user trial reset attempt | Reset 14-day period | start_trial checks existing license; cannot restart | NONE |
| JWT misuse | Impersonate user | Supabase Auth handles JWT validation; RLS checks auth.uid() | LOW |
| Revoked membership | Access after removal | Online: membership check immediate; offline: stale membership detected on sync | LOW |
| Server outage | Cannot verify license | Offline grace policy; bounded window; fail-closed | MEDIUM |
| Offline abuse | Extended free use | Bounded offline window; never-online gets no entitlement | MEDIUM |
| Installation-id replacement | Bypass device tracking | New installation_id = new device row; does not transfer activation | LOW |

### 31.2 Security Principles

1. Server is always the source of truth for licensing
2. Client cache is never the security authority
3. Local clock is never the licensing authority
4. RLS enforces tenant isolation at database level
5. SECURITY DEFINER functions validate business rules server-side
6. No licensing secrets in Flutter binary
7. Fail-closed: uncertainty results in denied writes, not granted writes
8. No destructive data action on licensing failure

---

## 32. Anti-Tampering Strategy

### 32.1 Defense Layers

| Layer | Mechanism | What It Prevents |
| --- | --- | --- |
| Server authority | PostgreSQL now() in RPCs | Client clock manipulation |
| RLS | Row-level security | Cross-shop data access |
| SECURITY DEFINER | Server-side validation | Client bypass of business rules |
| Cache bounded staleness | 24-hour revalidation window | Indefinite offline entitlement |
| Clock-rollback detection | Compare wall clock to last observed | Backdating to extend trial |
| Monotonic timer | Process-elapsed estimation | Forward-clock early expiry (acceptable) |
| Idempotent RPCs | Unique constraints, upserts | Duplicate activations, double trials |
| Atomic operations | Database transactions | Race conditions on device limits |

### 32.2 What Is NOT Protected

- The local cache can be read by someone with machine access (informational only)
- A user can uninstall and reinstall (new installation_id, but same license)
- A user can create a new Supabase account with a different email (gets a new shop = new trial, but this is legitimate behavior for a new business)
- A user can share their installation_id with another machine (but this creates a new device row, not a security breach)

### 32.3 Security vs Usability Tradeoff

Phase E prioritizes:
1. No false denials for legitimate users
2. Bounded abuse tolerance (offline grace window)
3. Server authority for all security decisions
4. Graceful degradation over hard lockout

The architecture accepts that a determined attacker with full machine access may temporarily abuse offline grace. The bounded window and server revalidation limit the blast radius.

---

## 33. Idempotency

### 33.1 Operations and Idempotency

| Operation | Idempotent? | Mechanism |
| --- | --- | --- |
| start_trial | YES | Checks for existing TRIAL/ACTIVE/PERPETUAL before insert |
| register_device | YES | Upserts by (installation_id, shop_id) |
| activate_device | YES | Checks for existing activation before insert |
| deactivate_device | YES | Sets status='REVOKED' (already revoked is no-op) |
| verify_license_entitlement | YES | Read-only, no side effects |
| get_device_list | YES | Read-only, no side effects |

### 33.2 Unique Constraints

| Table | Constraint | Prevents |
| --- | --- | --- |
| licenses | license_key UNIQUE | Duplicate license keys |
| licenses | Application logic (start_trial check) | Multiple active licenses per shop |
| shop_members | (shop_id, user_id) UNIQUE | Duplicate membership |
| activations | Application logic (activate_device check) | Duplicate activations per device per license |

### 33.3 Conflict Strategy

All licensing RPCs use a check-then-act pattern within a single SECURITY DEFINER function execution, which is atomic within the PostgreSQL transaction. This prevents:

- Two concurrent start_trial calls from creating two trials
- Two concurrent activate_device calls from exceeding device limit
- Two concurrent register_device calls from creating duplicate rows

---

## 34. Concurrency

### 34.1 Concurrent Scenarios

| Scenario | Expected Behavior | Protection |
| --- | --- | --- |
| Same owner logs in from two devices simultaneously | Both devices registered, both activated (if slots available) | Atomic activate_device with COUNT check |
| Two devices claim last remaining slot | One succeeds, one fails with "device limit reached" | Database transaction ensures atomic counting |
| Two setup requests create trial concurrently | One succeeds, one fails with "shop already has license" | start_trial checks existing before insert |
| License revoked while client is offline | Client continues with cached state until revalidation | Bounded offline grace; revalidation detects revocation |
| Owner deactivates device while that device is online | Device loses write entitlement on next revalidation | Server state is authoritative |

### 34.2 Database-Level Protection

All concurrent protection is database-level:

- PostgreSQL transactions ensure atomicity
- SECURITY DEFINER functions execute as a single unit
- CHECK constraints enforce valid states
- UNIQUE constraints prevent duplicates
- No application-level lock needed

### 34.3 Client-Side Concurrency

The Flutter app is single-threaded (main isolate). There is no client-side concurrency concern for licensing operations. Sequential RPC calls are sufficient.

---

## 35. Failure / Recovery Matrix

### 35.1 Failure Scenarios

| Scenario | Expected Behavior | User State | Retry | Data Safety | Security |
| --- | --- | --- | --- | --- | --- |
| Network unavailable | Use cached entitlement | "Working offline" indicator | Background retry | Local data preserved | Grace policy applies |
| Supabase unavailable | Use cached entitlement | "Server temporarily unavailable" | Exponential backoff | Local data preserved | Grace policy applies |
| RPC timeout | Use cached entitlement | "Verification timed out, retrying" | Automatic retry | Local data preserved | Grace policy applies |
| Duplicate trial request | Server rejects with error | "Shop already has trial/license" | No retry needed | No duplicate trial | Idempotent |
| Duplicate activation | Server returns existing activation | No visible error | No retry needed | No duplicate slot used | Idempotent |
| Device limit exceeded | Server rejects with error | "Device limit reached" | Owner deactivates old device | No limit bypass | Atomic counting |
| Membership revoked mid-session | Online: immediate detection | "Access revoked" | Re-login required | Local data preserved | Membership check |
| License expires mid-session | Next revalidation detects | "License expired" | Online required for renewal | Local data preserved | Server authority |
| License suspended remotely | Next revalidation detects | "License suspended" | Contact I Tech | Local data preserved | Server authority |
| Shop changed | Re-resolve entitlement | Entitlement changes per shop | Automatic | Local data preserved | Shop-scoped |
| JWT expired | Token refresh or re-login | "Session expired" | Automatic refresh | Local data preserved | Supabase handles |
| Reinstall | New installation_id | Re-authenticate and re-activate | Online required | Local cache lost | No trial reset |
| Cache corruption | Fail closed | "License verification required" | Online revalidation | Local data preserved | Fail-closed |
| Clock rollback detected | Require online revalidation | "License verification required" | Online required | Local data preserved | No entitlement extension |
| Clock forward | Early revalidation trigger | "License verification required" | Online revalidation | Local data preserved | Conservative |
| Migration failure | N/A (server-side) | Error message | Manual resolution | Server data preserved | N/A |

---

## 36. Error Model

### 36.1 Dart Exception Classes

| Exception | Trigger | UI Response |
| --- | --- | --- |
| LicenseActivationRequiredException | Writes blocked (existing) | "License activation required" |
| TrialExpiredException | trial_expired entitlement | "Trial expired. License required." |
| LicenseExpiredException | licensed_expired entitlement | "License expired. Contact I Tech." |
| LicenseSuspendedException | licensed_suspended entitlement | "License suspended. Contact I Tech." |
| DeviceLimitReachedException | Device limit exceeded | "Device limit reached. Contact shop owner." |
| DeviceRevokedException | Device activation revoked | "This device is no longer authorized." |
| EntitlementUnknownException | Cannot determine entitlement | "License verification required. Connect to internet." |
| ClockRollbackDetectedException | Clock tamper suspected | "System time anomaly detected. Please verify." |

### 36.2 Error State Mapping

These exceptions map to UI states, not raw error strings. The UI layer renders appropriate Arabic messages based on the exception type.

---

## 37. UX States

### 37.1 Application States

| State | Visual | Behavior |
| --- | --- | --- |
| Entitled (trial) | Green status dot + trial banner | Full access, "X days remaining" banner |
| Entitled (paid) | Green status dot, no banner | Full access |
| Entitled (cached/offline) | Orange status dot + offline indicator | Full access, offline warning |
| Expired (trial) | Red status indicator | Read-only, "Trial expired" message |
| Expired (paid) | Red status indicator | Read-only, "License expired" message |
| Suspended | Yellow status indicator | Read-only, "License suspended" message |
| Revoked | Red status indicator | Read-only, "License revoked" message |
| No license | Gray status indicator | Read-only, "License required" message |
| Device limit | Orange warning | Read-only, "Device limit reached" message |
| Activating | Spinner | Transient, waiting for server |
| Server unreachable | Orange indicator | Cached entitlement or "Verification required" |
| Clock anomaly | Yellow warning | "System time anomaly" + online required |

### 37.2 Trial Remaining Display

The "X days remaining" display is derived from:

    days_remaining = (cached_trial_expires_at - estimated_server_now).inDays

Where estimated_server_now uses monotonic timer from last server sync (see Section 18.7).

The display clearly communicates it is approximate. Exact calculation happens server-side.

### 37.3 Settings License Section

The settings screen shows:

- License status (Arabic)
- Trial remaining (if trial)
- License expiry (if paid)
- Device count / max devices
- Option to deactivate device (owner only)
- Option to contact I Tech for paid license

---

## 38. Flutter File Forecast

### 38.1 New Files

| File | Purpose | Est. Lines |
| --- | --- | --- |
| app/lib/licensing/cloud_licensing_service.dart | Cloud-backed licensing orchestration | ~250 |
| app/lib/licensing/cloud_licensing_repository.dart | Supabase RPC calls for licensing | ~180 |
| app/lib/licensing/entitlement_cache.dart | Local persistence of server snapshot | ~120 |
| app/lib/licensing/offline_grace_policy.dart | Staleness and clock-tamper detection | ~100 |
| app/lib/licensing/license_exception.dart | Domain exception classes | ~60 |
| app/lib/screens/settings/license_status_screen.dart | License status UI | ~200 |
| app/lib/widgets/trial_remaining_banner.dart | Trial countdown banner widget | ~80 |
| app/test/licensing/cloud_licensing_service_test.dart | Unit tests | ~250 |
| app/test/licensing/entitlement_cache_test.dart | Unit tests | ~150 |

**Total new:** ~1,390 lines

### 38.2 Modified Files

| File | Changes | Delta |
| --- | --- | --- |
| app/lib/main.dart | Wire CloudLicensingService instead of old LicensingService | +20 |
| app/lib/database/database_helper.dart | Update enforcement callback | +5 |
| app/lib/services/session_state.dart | Add entitlement-awareness | +15 |
| app/lib/screens/auth/login_screen.dart | Add licensing resolution after login | +30 |
| app/lib/screens/auth/first_owner_setup_screen.dart | Add trial start after shop creation | +25 |
| app/lib/screens/settings_screen.dart | Add license status section | +40 |
| app/lib/services/app_settings.dart | Add cloud.license.* key constants | +20 |

**Total modified:** ~155 lines delta

### 38.3 Total Delta Estimate

| Category | Lines |
| --- | --- |
| New files | ~1,390 |
| Modified files | ~155 |
| **Total** | **~1,545** |

---

## 39. Migration Forecast

### 39.1 Migration Files

```
supabase/migrations/20260820000023_phase_e_licensing_enhancements.sql
```

This is the ONLY migration needed for Phase E.

### 39.2 Migration Contents

1. ALTER TABLE licenses: add updated_at, max_devices, revoked_at, metadata
2. ALTER TABLE activations: add status CHECK constraint
3. CREATE FUNCTION verify_license_entitlement()
4. CREATE FUNCTION register_device()
5. CREATE FUNCTION activate_device()
6. CREATE FUNCTION deactivate_device()
7. CREATE FUNCTION get_device_list()

### 39.3 Migration Safety

| Aspect | Safety |
| --- | --- |
| Additive only | YES - new columns with defaults, new functions |
| No data loss | YES - no DROP, no DELETE, no destructive operation |
| Backward compatible | YES - existing functions unchanged, new columns have defaults |
| RLS safe | YES - no policy changes |
| Rollback possible | YES - ALTER TABLE DROP COLUMN, DROP FUNCTION |
| Idempotent | YES - CREATE OR REPLACE for functions, IF NOT EXISTS patterns |

### 39.4 Local Schema Impact

**NONE.** Phase E does not modify the local SQLite database. No new columns, no new tables, no schema version change.

---

## 40. Test Strategy

### 40.1 Unit Tests

| Test | Component | Assertion |
| --- | --- | --- |
| License state resolution | CloudLicensingService | Correct entitlement state from mock RPC response |
| Trial active boundary (1 day remaining) | CloudLicensingService | Writes allowed |
| Trial expired boundary (0 hours remaining) | CloudLicensingService | Writes blocked |
| Trial expired boundary (past expiry) | CloudLicensingService | Writes blocked |
| Licensed active | CloudLicensingService | Writes allowed |
| Licensed expired | CloudLicensingService | Writes blocked |
| Device limit at capacity | CloudLicensingService | DeviceLimitReachedException |
| Device limit one below | CloudLicensingService | Activation succeeds |
| Cached entitlement save/load | EntitlementCache | Correct round-trip |
| Cache staleness detection | EntitlementCache | Stale after 24 hours |
| Clock rollback detection | EntitlementCache | Detected and flagged |
| Entitlement cache corruption | EntitlementCache | Fail closed |
| Shop-scoped entitlement | CloudLicensingService | Different shops, different states |
| Offline grace within window | OfflineGracePolicy | Writes allowed |
| Offline grace beyond window | OfflineGracePolicy | Writes blocked |
| Session integration | SessionState + CloudLicensingService | Correct state after login |

### 40.2 Database Tests

| Test | RPC | Assertion |
| --- | --- | --- |
| Single trial per shop | start_trial | Second call raises exception |
| Server timestamp authority | start_trial | trial_started_at = now(), not client time |
| Client cannot set trial dates | verify_license_entitlement | Returns server-computed values only |
| RLS shop isolation | Direct query | User in Shop A cannot read Shop B licenses |
| Unauthorized mutation rejected | Direct INSERT | Anon/authenticated cannot INSERT into licenses |
| Atomic device activation | activate_device | Concurrent calls respect device limit |
| Device limit enforcement | activate_device | Limit exceeded raises exception |
| Revocation | deactivate_device | Status changes to REVOKED |
| Idempotent trial creation | start_trial | Calling twice does not create duplicate |
| Idempotent device registration | register_device | Calling twice updates last_seen_at |
| Owner-only device list | get_device_list | Non-owner gets error |

### 40.3 Integration Tests

| Test | Flow | Assertion |
| --- | --- | --- |
| First owner setup -> trial | Onboarding | Trial created, device activated |
| Login -> license resolution | Login flow | Entitlement resolved correctly |
| Second device activation | Multi-device | Both devices activated |
| Device limit reached | Multi-device | Fourth device blocked |
| Trial expiry | Time progression | Writes blocked after 14 days |
| Paid license activation | Admin flow | Full access restored |
| Offline reconnect | Connectivity loss | Cache used, then revalidated |
| Membership revoked | Auth flow | Entitlement check fails |
| Multi-shop selection | Shop switch | Entitlement re-resolved per shop |
| Clock rollback | Tamper detection | Online revalidation required |

### 40.4 Security Tests

| Test | Attack | Assertion |
| --- | --- | --- |
| Local clock attack | Set clock back 30 days | Trial NOT extended |
| REST mutation attempt | Direct Supabase INSERT into licenses | RLS/permission denied |
| Cross-shop access | Read license for unjoined shop | RLS blocks |
| Cross-shop activation | Activate device in unjoined shop | RPC rejects |
| Duplicate concurrent trial | Two start_trial calls simultaneously | Only one trial created |
| Duplicate concurrent final-slot activation | Two activate_device at limit | Only one succeeds |
| Reinstall/reset attempt | New installation_id | Same shop license persists |
| Client-set trial timestamps | Attempt to POST trial_started_at | No client INSERT path exists |

---

## 41. Acceptance Gates

### 41.1 Definition of Done

| Gate | Criteria | Verification |
| --- | --- | --- |
| G1: Server authority | All trial/licensing timestamps from PostgreSQL now() | SQL inspection |
| G2: Trial non-resettable | Reinstall does not restart trial | Manual test |
| G3: Shop-scoped | Different shops have independent licenses | Manual test |
| G4: Device activation | Installation registered and activated | Manual test |
| G5: Device limit | Fourth device blocked on trial | Manual test |
| G6: Offline grace | Cached entitlement works offline within window | Manual test |
| G7: Clock tamper | Clock rollback detected, online revalidation required | Manual test |
| G8: Entitlement gating | Expired trial blocks writes, preserves data | Manual test |
| G9: Multi-shop | Shop switch re-resolves entitlement | Manual test |
| G10: Tests pass | All new and existing tests pass | flutter test |
| G11: Analyzer clean | 0 errors, 0 warnings | flutter analyze |
| G12: Format clean | 0 files changed | dart format |
| G13: Diff check | No conflict markers | git diff --check |
| G14: No secrets | No privileged keys in client | Secret scan |
| G15: No local schema change | SQLite schema unchanged | Code inspection |
| G16: Preserved artifacts | MUAMAN report + delivery zip + stash intact | File check |

---

## 42. Rollback Strategy

### 42.1 Rollback Triggers

| Trigger | Action |
| --- | --- |
| Test failure rate > 20% | Revert all changes |
| Critical licensing bug | Revert all changes |
| Data loss detected | Revert all changes |
| Security vulnerability | Revert all changes |

### 42.2 Rollback Procedure

```
1. git revert HEAD
2. Drop new cloud objects:
   DROP FUNCTION IF EXISTS verify_license_entitlement;
   DROP FUNCTION IF EXISTS register_device;
   DROP FUNCTION IF EXISTS activate_device;
   DROP FUNCTION IF EXISTS deactivate_device;
   DROP FUNCTION IF EXISTS get_device_list;
   ALTER TABLE licenses DROP COLUMN IF EXISTS updated_at;
   ALTER TABLE licenses DROP COLUMN IF EXISTS max_devices;
   ALTER TABLE licenses DROP COLUMN IF EXISTS revoked_at;
   ALTER TABLE licenses DROP COLUMN IF EXISTS metadata;
   ALTER TABLE activations DROP CONSTRAINT IF EXISTS activations_status_check;
3. Verify: flutter test
```

### 42.3 Rollback Safety

| Component | Safe to Revert? | Notes |
| --- | --- | --- |
| Flutter code | YES | No data dependencies |
| Cloud functions | YES | DROP FUNCTION |
| Cloud columns | YES | DROP COLUMN |
| Existing data | YES | No data modified by Phase E |

---

## 43. Implementation Sequence

### 43.1 Task Breakdown

| Task | Depends On | Priority |
| --- | --- | --- |
| E1: Supabase schema migration (new columns + constraints) | None | P0 |
| E2: Server functions (verify_license_entitlement, register_device, activate_device, deactivate_device, get_device_list) | E1 | P0 |
| E3: Update start_trial (if needed, otherwise keep as-is) | E1 | P0 |
| E4: CloudLicensingRepository (Supabase RPC calls) | E2 | P0 |
| E5: EntitlementCache (local persistence) | None | P0 |
| E6: OfflineGracePolicy (staleness + clock detection) | E5 | P0 |
| E7: LicenseException classes | None | P0 |
| E8: CloudLicensingService (orchestration) | E4, E5, E6, E7 | P0 |
| E9: Integrate with DatabaseHelper enforcement | E8 | P0 |
| E10: Integrate with main.dart initialization | E8 | P0 |
| E11: Integrate with LoginScreen flow | E8 | P0 |
| E12: Integrate with FirstOwnerSetupScreen flow | E8 | P0 |
| E13: TrialRemainingBanner widget | E8 | P1 |
| E14: LicenseStatusScreen | E8 | P1 |
| E15: Settings screen license section | E14 | P1 |
| E16: Unit tests | E8 | P0 |
| E17: Database tests | E2 | P0 |
| E18: Integration tests | All | P1 |
| E19: Security tests | All | P1 |

### 43.2 Critical Path

```
E1 -> E2 -> E4 -> E8 -> E9 -> E10 -> E11 -> E12 -> E16 -> E18
```

### 43.3 Parallel Workstreams

| Stream | Tasks |
| --- | --- |
| Cloud backend | E1, E2, E3 |
| Flutter services | E4, E5, E6, E7, E8 |
| Flutter integration | E9, E10, E11, E12 |
| Flutter UI | E13, E14, E15 |
| Testing | E16, E17, E18, E19 |

---

## 44. Phase F Handoff

### 44.1 What Phase F Receives

| Component | Status |
| --- | --- |
| CloudLicensingService | COMPLETED |
| Entitlement resolution | COMPLETED |
| Device activation | COMPLETED |
| Enforcement boundary | COMPLETED |
| Offline grace | COMPLETED |

### 44.2 What Phase F Implements

| Feature | Description |
| --- | --- |
| Server-side RBAC | Edge Functions enforce 18 permissions |
| Permission sync | Cloud to local permission cache |
| Permission overrides | Per-shop permission customization |

---

## 45. Open Decisions

| ID | Decision | Status | Phase |
| --- | --- | --- | --- |
| OD1 | Offline grace duration for paid licenses | OPEN (7 days recommended) | Phase E |
| OD2 | Subscription billing provider | OPEN | Later session |
| OD3 | Max devices per plan (beyond default 3) | OPEN | Later session |
| OD4 | Admin portal for I Tech | OPEN | Later session |
| OD5 | Email notifications for trial expiry | OPEN | Later session |
| OD6 | Cryptographic signed offline tokens | DEFERRED | Later session if needed |

---

## 46. Exit Criteria

| # | Criterion | Verification |
| --- | --- | --- |
| 1 | Server-authoritative 14-day trial | SQL inspection of start_trial |
| 2 | Trial non-resettable | Reinstall test |
| 3 | Shop-scoped licensing | Multi-shop test |
| 4 | Device activation working | Multi-device test |
| 5 | Device limit enforced | Limit test |
| 6 | Offline grace bounded | Offline test |
| 7 | Clock tamper detected | Clock test |
| 8 | Entitlement gating working | Expiry test |
| 9 | All tests pass | flutter test |
| 10 | No SQLite schema changes | Code inspection |
| 11 | No data loss | Data verification |
| 12 | No secrets in client | Security review |
| 13 | Preserved artifacts intact | File check |
| 14 | Stash preserved | git stash list |

---

## 47. Baseline Test Awareness

Phase D closure documented:

    Phase D targeted tests = 22/22 PASS
    Full test suite = 763 passed, 4 failed
    Known baseline failures = 4
    Known failure = RestoreFailedException: no such table: customers

Phase E must NOT attribute these pre-existing failures to its own changes. Any new regressions must be clearly separated.

---

## 48. Preserved Artifacts

The following must remain untouched:

    MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
    delivery/I-TECH-Delivery-v1.0.0.zip
    stash@{0}

Do not:
- Edit
- Stage
- Commit
- Delete
- Apply stash
- Pop stash
- Drop stash

---

## 49. Planning Commit

After all gates pass:

    git add PHASE_E_LICENSING_TRIAL_PLAN.md
    git commit -m "Plan Phase E licensing and trial"

Single local commit only. No push.

Expected parent: 298f564fcfe17aac919fa0c0edbd97acfc15992a

---

## 50. Appendices

### 50.1 Glossary

| Term | Definition |
| --- | --- |
| Entitlement | Server-determined right to use the application for a shop |
| Trial | 14-day time-limited entitlement, server-calculated |
| License | Paid or perpetual entitlement, server-managed |
| Activation | Binding between a license and a device installation |
| Device | A unique app installation identified by installation_id |
| Installation | A specific app install on a specific machine |
| Offline Grace | Temporary continuation of entitlement based on cached server state |
| Server Time | PostgreSQL now() inside SECURITY DEFINER functions |
| Monotonic Timer | Process-elapsed time source unaffected by wall-clock edits |
| Staleness | Age of cached entitlement beyond revalidation window |
| Clock Rollback | Device time moving backwards relative to last observed value |
| Fail Closed | Deny protected writes when entitlement is uncertain |

### 50.2 Reference Documents

| Document | Path |
| --- | ---|
| Master Plan | PROJECT_MASTER_PLAN.md |
| Phase C Plan | PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md |
| Phase D Plan | PHASE_D_CLOUD_AUTH_MEMBERSHIP_PLAN.md |
| Source of Truth | MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md |

### 50.3 Migration File Naming Convention

Following the existing convention:

    202608200000XX_description.sql

Phase E migration:

    20260820000023_phase_e_licensing_enhancements.sql

---

*This document is the Phase E planning artifact for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md phase roadmap.*
