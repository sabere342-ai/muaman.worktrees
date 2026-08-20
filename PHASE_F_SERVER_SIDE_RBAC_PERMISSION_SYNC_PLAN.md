# PHASE F: SERVER-SIDE RBAC AND PERMISSION SYNC PLAN

**Phase:** F - Server-Side RBAC and Permission Sync
**Project:** I Tech Store Management Application
**Institutional Owner:** I Tech for Technology / I Tech للتكنولوجيا
**Repository:** C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
**Branch:** codex/i-tech-next-roadmap-freeze
**Date:** 2026-08-20
**Status:** Planning artifact - not implemented

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | F - Server-Side RBAC and Permission Sync |
| Session Type | PHASE_F_PLANNING |
| Baseline Commit | `f586f72529bac62110781755e10061ad0df98e24` |
| Predecessor Phase | E - Licensing & Trial (CLOSED) |
| Successor Phase | G - Cloud Data Foundation |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Phase E Closure | `PASS_PHASE_E_REMOTE_LOCKED` |

---

## 2. Verified Starting Baseline

```
PHASE_D_IMPLEMENTATION = 298f564fcfe17aac919fa0c0edbd97acfc15992a
PHASE_E_PLANNING       = 9a623d43bc184974d758a350611c7bc90dff91e1
PHASE_E_IMPLEMENTATION = f586f72529bac62110781755e10061ad0df98e24

TAG: phase-e-implementation-locked -> f586f72529bac62110781755e10061ad0df98e24

LOCAL_HEAD  = f586f72529bac62110781755e10061ad0df98e24
REMOTE_HEAD = f586f72529bac62110781755e10061ad0df98e24
LOCAL_AHEAD = 0
REMOTE_AHEAD = 0
ANCESTRY    = 298f564 -> 9a623d4 -> f586f725 (verified)
```

### Direct Parent of Phase E Implementation

```
f586f72529bac62110781755e10061ad0df98e24
  parent: 9a623d43bc184974d758a350611c7bc90dff91e1 (Phase E planning)
```

---

## 3. Governing Requirements

### 3.1 Master Plan Mandates

From `PROJECT_MASTER_PLAN.md`:

- **Section 4 (Product Principles), #3:** "Dual-layer enforcement — UI + server/database permission checks"
- **Section 4, #9:** "Permission-driven UI — role determines what you see, not what device you hold"
- **Section 8 (Target State):** "Server-enforced RBAC (not UI-only)"
- **Section 9, #1:** "Cloud authority with local cache — server is source of truth for identity, licensing, authorization"
- **Section 9, #7:** "Fail-closed authorization — no permission = no access, never permissive default"
- **Section 11, #2:** "Server-enforced authorization — RLS or server functions, not just UI checks"
- **Section 12:** All 18 permission IDs are FROZEN (add-only, never rename)
- **Section 13 (Phase Roadmap):** Phase F = "Server-Enforced Permissions — 18 permission mapping, RBAC, security tests"
- **Section 16 (Functional Preservation Matrix):** "18 Permissions: PRESERVED + server-enforced"

### 3.2 Phase E Handoff

From `PHASE_E_LICENSING_TRIAL_PLAN.md` Section 44.2:

> Phase F implements: Server-side RBAC (Edge Functions enforce 18 permissions), Permission sync (cloud to local permission cache), Permission overrides (per-shop permission customization)

### 3.3 Phase D Handoff

From `PHASE_D_CLOUD_AUTH_MEMBERSHIP_PLAN.md` Section 22.3:

> Phase F will: Introduce server-side RBAC via Supabase Edge Functions, Replace local permission checks with cloud permission checks, Sync cloud permissions to local cache for offline use, Add permission override capabilities per-shop

### 3.4 Architecture Principle from Productization Architecture Plan

From `PRODUCTIZATION_ARCHITECTURE_PLAN.md` Section 1:

> Permissions gap: "UI + DB enforcement" -> "UI + server enforcement". Strategy: "RLS / server functions". Phase: F.

---

## 4. Existing RBAC Architecture

### 4.1 Local Permission System (SQLite)

| Component | File | Purpose |
|-----------|------|---------|
| `AppPermission` enum | `app/lib/services/permissions.dart:35-180` | 18 permissions with stable IDs |
| `PermissionCatalog` | `app/lib/services/permissions.dart:184-264` | Default config, encoding, owner-exclusive set |
| `PermissionResolver` | `app/lib/services/permission_resolver.dart:1-93` | Runtime resolution engine (singleton) |
| `RolePermissionRepository` | `app/lib/services/role_permission_repository.dart:1-115` | SQLite persistence in `role_permissions` table |
| `SessionState.hasPermission()` | `app/lib/services/session_state.dart:30-33` | Session-level permission check |
| `DatabaseHelper._requirePermission()` | `app/lib/database/database_helper.dart:509-514` | Data-layer enforcement gate |
| `UserRepository._requireAdminPermission()` | `app/lib/database/user_repository.dart:49-55` | User management gate |
| `ShopProfileService._authorize()` | `app/lib/services/shop_profile_service.dart:108-115` | Settings authorization |

### 4.2 Local Trust Boundary

The current trust boundary is entirely client-side:

```
User.role (local SQLite)
  -> PermissionResolver.can(role, permission)
    -> reads from role_permissions table (local SQLite)
    -> owner always gets all permissions
    -> database mutations gated by _requirePermission()
    -> UI elements gated by hasPermission()
```

**No server-side permission check exists.** The cloud `role_permissions_cloud` table is populated but never queried by the client for authorization decisions.

### 4.3 Cloud Permission System (Supabase)

| Component | File | Purpose |
|-----------|------|---------|
| `roles` table | `supabase/migrations/20260820000002_create_roles.sql` | Per-shop role definitions |
| `role_permissions_cloud` table | `supabase/migrations/20260820000003_create_role_permissions_cloud.sql` | Per-role permission assignments |
| `shop_members` table | `supabase/migrations/20260820000001_create_shop_members.sql` | User-to-shop membership with role |
| Seed data | `supabase/seed.sql` | 3 system roles, 18 permissions seeded |
| RLS policies | `supabase/migrations/20260820000010_rls_policies.sql` | SELECT-only, membership-based |
| SECURITY DEFINER functions | `supabase/migrations/20260820000020_database_functions.sql` | Auth-gated mutations |

### 4.4 Cloud Schema Details

**`roles` table:**
```sql
roles (
  id UUID PK,
  shop_id UUID FK->shops ON DELETE CASCADE,  -- NULL for system-wide templates
  name TEXT NOT NULL,
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ,
  UNIQUE(shop_id, name)
)
```

**`role_permissions_cloud` table:**
```sql
role_permissions_cloud (
  id UUID PK,
  role_id UUID FK->roles ON DELETE CASCADE,
  permission_id TEXT NOT NULL,  -- matches AppPermission.id
  updated_at TIMESTAMPTZ,
  UNIQUE(role_id, permission_id)
)
```

**`shop_members` table:**
```sql
shop_members (
  id UUID PK,
  shop_id UUID FK->shops ON DELETE CASCADE,
  user_id UUID FK->auth.users,
  role TEXT CHECK (role IN ('owner', 'employee', 'salesOnly')),
  status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  invited_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  UNIQUE(shop_id, user_id)
)
```

### 4.5 Current Trust Gaps

| Gap | Risk | Phase F Resolution |
|-----|------|--------------------|
| Local permission checks only | User can bypass by editing SQLite | Server-side enforcement on cloud mutations |
| Cloud `role_permissions_cloud` unused | Server has no RBAC enforcement | Authorization helper queries cloud permissions |
| No permission sync to client | Client uses stale local config | Cloud→local permission sync RPC |
| Owner checks in SQL are role-only | No granular permission enforcement | Permission-aware authorization helpers |
| No per-shop overrides | All shops share same role config | Override table with effective resolution |

---

## 5. Canonical Permission Catalog

### 5.1 Complete Permission Table

| # | Enum Value | Stable ID | Category | Default Owner | Default Employee | Default SalesOnly |
|---|-----------|-----------|----------|:---:|:---:|:---:|
| 1 | `canAccessDashboard` | `dashboard.view` | dashboard | YES | YES | NO |
| 2 | `canAccessInventory` | `inventory.view` | inventory | YES | YES | NO |
| 3 | `canEditProducts` | `inventory.edit` | inventory | YES | YES | NO |
| 4 | `canDeleteProducts` | `inventory.delete` | inventory | YES | NO | NO |
| 5 | `canAccessSales` | `sales.view` | sales | YES | YES | YES |
| 6 | `canCreateSales` | `sales.create` | sales | YES | YES | YES |
| 7 | `canViewSalesHistory` | `sales.history.view` | sales | YES | YES | NO |
| 8 | `canDeleteSales` | `sales.delete` | sales | YES | NO | NO |
| 9 | `canAccessReturns` | `returns.view` | returns | YES | YES | NO |
| 10 | `canCreateReturns` | `returns.create` | returns | YES | YES | NO |
| 11 | `canDeleteReturns` | `returns.delete` | returns | YES | NO | NO |
| 12 | `canAccessExpenses` | `expenses.view` | expenses | YES | YES | NO |
| 13 | `canCreateExpenses` | `expenses.create` | expenses | YES | YES | NO |
| 14 | `canDeleteExpenses` | `expenses.delete` | expenses | YES | NO | NO |
| 15 | `canAccessStocktake` | `stocktake.view` | stocktake | YES | YES | NO |
| 16 | `canManageUsers` | `admin.users.manage` | admin | YES | NO | NO |
| 17 | `canManagePermissions` | `admin.permissions.manage` | admin | YES | NO | NO |
| 18 | `canAccessSettings` | `admin.settings.access` | admin | YES | NO | NO |

**Total: 18 permissions.** Verified from `AppPermission` enum in `app/lib/services/permissions.dart:35-156`.

### 5.2 Owner-Exclusive Permissions

From `PermissionCatalog.ownerExclusive` at `app/lib/services/permissions.dart:192-195`:

- `canManageUsers` (`admin.users.manage`)
- `canManagePermissions` (`admin.permissions.manage`)

These MUST NEVER be granted to non-owner roles, even via overrides.

### 5.3 Canonical Permission Identifier Contract

The stable `id` strings from `AppPermission.id` are the **single canonical identifier** shared between:
- Local SQLite (`role_permissions.permissions` — comma-separated IDs)
- Cloud PostgreSQL (`role_permissions_cloud.permission_id` — one row per ID)
- Dart code (`AppPermission.fromId(id)` resolver)

These IDs are FROZEN per `PROJECT_MASTER_PLAN.md` Section 12. New permissions may be added; existing IDs may never be renamed.

---

## 6. Existing Cloud Schema Review

### 6.1 Tables (12 total across all phases)

| Table | Phase | RLS | Client INSERT/UPDATE/DELETE |
|-------|-------|-----|---------------------------|
| `shops` | C | SELECT-only | NO (SECURITY DEFINER only) |
| `shop_members` | C | SELECT-only | NO (Edge Function / SECURITY DEFINER) |
| `roles` | C | SELECT-only | NO |
| `role_permissions_cloud` | C | SELECT-only | NO |
| `devices` | C | SELECT-only | NO |
| `licenses` | C | SELECT-only | NO |
| `activations` | C | SELECT-only | NO |
| `invitations` | D | SELECT-owner-only | NO |

### 6.2 SECURITY DEFINER Functions (existing)

| Function | Auth Check | Owner Check | Phase |
|----------|------------|-------------|-------|
| `create_shop_with_owner(p_name)` | `auth.uid()` required | N/A (creator becomes owner) | C/D |
| `get_user_shops()` | `auth.uid()` required | N/A | D |
| `verify_shop_membership(p_shop_id)` | `auth.uid()` | N/A | C |
| `start_trial(p_shop_id)` | `auth.uid()` required | YES (owner only) | E |
| `verify_trial_status(p_shop_id)` | None | None | E |
| `verify_license_entitlement(p_shop_id)` | `auth.uid()` + membership | N/A | E |
| `register_device(...)` | `auth.uid()` + membership | N/A | E |
| `activate_device(...)` | `auth.uid()` + membership | N/A | E |
| `deactivate_device(p_activation_id)` | `auth.uid()` | YES (owner only) | E |
| `get_device_list(p_shop_id)` | `auth.uid()` | YES (owner only) | E |
| `accept_invitation(p_shop_id, p_user_id)` | None (self-service) | N/A | D |

### 6.3 RLS Strategy

Current RLS is **membership-only**: authenticated users can SELECT rows for shops where they have `status = 'ACTIVE'` in `shop_members`. All mutations go through SECURITY DEFINER functions that bypass RLS.

**Phase F decision:** RLS remains membership-only. Permission authorization is handled in SECURITY DEFINER functions, not RLS. This avoids duplicating permission logic in both RLS and functions.

---

## 7. Current Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│ FLUTTER CLIENT                                                    │
│                                                                   │
│  SessionState.hasPermission()                                     │
│    -> PermissionResolver.can(role, permission)                    │
│      -> reads local role_permissions SQLite table                  │
│    -> UI elements shown/hidden                                    │
│    -> DatabaseHelper._requirePermission() blocks writes           │
│                                                                   │
│  ⚠ TRUST BOUNDARY: Client-only. User can edit SQLite.            │
│                                                                   │
│  CloudLicensingService.enforceActive()                            │
│    -> reads entitlement from EntitlementCache                     │
│    -> blocks writes if not entitled                               │
│                                                                   │
│  ⚠ TRUST BOUNDARY: Server-authoritative for licensing only.       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ CLOUD (Supabase)                                                  │
│                                                                   │
│  RLS: SELECT-only, membership-based shop isolation                │
│  SECURITY DEFINER functions:                                      │
│    - verify_license_entitlement: checks membership                │
│    - start_trial: checks ownership                                │
│    - activate_device: checks membership                           │
│    - deactivate_device: checks ownership                          │
│                                                                   │
│  ⚠ GAP: No permission-level authorization on cloud mutations.     │
│  ⚠ GAP: role_permissions_cloud populated but never queried        │
│    for authorization.                                             │
└─────────────────────────────────────────────────────────────────┘
```

### Phase F Trust Model

```
Authentication (auth.uid())
       ↓
Shop Membership (shop_members: role + status)
       ↓
License Entitlement (verify_license_entitlement)
       ↓
Permission Resolution (role_permissions_cloud + overrides)
       ↓
Operation Authorization (require_permission helper)
       ↓
Cloud Operation
```

Each layer MUST pass before the next is consulted. A failure at any layer denies the operation (fail closed).

---

## 8. Phase F Scope

### 8.1 Objectives

| # | Objective | Measurable Outcome |
|---|-----------|-------------------|
| O1 | Server-side RBAC | Cloud mutations verify permissions via SECURITY DEFINER helpers |
| O2 | Permission sync | Cloud permissions synced to local cache after login and on changes |
| O3 | Permission overrides | Per-shop customization of role permissions stored in cloud |
| O4 | Effective permission algorithm | Deterministic resolution: override → base role → DENY |
| O5 | Owner protection | Owner permissions immutable; privilege escalation impossible |
| O6 | Licensing + RBAC composition | Permission check AND entitlement check before operations |
| O7 | Local integration | `PermissionResolver` uses cloud-synced data when available |

### 8.2 Explicit Non-Goals

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | Subscription billing | Later session | Owner Decision OD2 unresolved |
| 2 | Full admin dashboard | Later session | Phase F is backend + sync |
| 3 | Real-time permission push | Phase H | Requires realtime subscription |
| 4 | Custom role creation UI | Later session | Schema supports it; no UI needed yet |
| 5 | Audit log UI | Later session | Schema for audit; no UI yet |
| 6 | Multi-factor auth | Later session | Phase E deferred |
| 7 | ABAC / policy engines | Not planned | Over-engineering for current scope |
| 8 | Broad Flutter UI redesign | Not planned | Minimal integration only |

---

## 9. Security Principles

1. **Server authority** — Cloud is the source of truth for all permission decisions
2. **Fail closed** — Unknown/uncertain permission state = denied
3. **No client trust** — Client permission cache is UX optimization, not security authority
4. **Cross-shop isolation** — Permissions are strictly scoped to a single shop
5. **Owner immutability** — Owner always gets all permissions; cannot be reduced
6. **Privilege escalation impossible** — No user can grant themselves elevated permissions
7. **Atomic authorization** — Permission check and mutation are in the same transaction
8. **No secrets in client** — service_role stays server-side
9. **Least privilege** — SECURITY DEFINER functions use minimal required queries
10. **Licensing composition** — Permission alone is insufficient; entitlement must also be valid

---

## 10. Effective Permission Model

### 10.1 Resolution Algorithm

```
effective_permissions(shop_id, user_id) =
  1. Resolve membership:
     member = shop_members WHERE shop_id AND user_id AND status = 'ACTIVE'
     if member IS NULL → DENY ALL

  2. Resolve role:
     role = member.role  ('owner' | 'employee' | 'salesOnly')

  3. Resolve base permissions:
     base = role_permissions_cloud
            JOIN roles ON role_permissions_cloud.role_id = roles.id
            WHERE roles.shop_id = shop_id AND roles.name = role
     → Set of permission_id values

  4. Resolve overrides (owner-only mutations):
     override = shop_permission_overrides
                WHERE shop_id = shop_id AND role = role
     → explicit ALLOW or DENY per permission_id

  5. Compose:
     For each permission P in the canonical 18:
       if override[P] = 'ALLOW' → GRANT
       if override[P] = 'DENY'  → DENY
       if P ∈ base              → GRANT
       otherwise                → DENY

  6. Owner override:
     if role = 'owner' → ALWAYS ALL 18 permissions (immutable)
```

### 10.2 Precedence Rules

| Layer | Source | Precedence | Notes |
|-------|--------|:---:|-------|
| Owner bypass | Hardcoded | HIGHEST | Owner always gets everything |
| Explicit deny override | `shop_permission_overrides` | HIGH | Can reduce from base |
| Explicit allow override | `shop_permission_overrides` | MEDIUM | Can expand from base |
| Base role permissions | `role_permissions_cloud` | LOW | Default per-role config |
| Implicit deny | No match | DEFAULT | Unknown = denied |

### 10.3 Mathematical Properties

- **Deterministic:** Same inputs always produce same output
- **Monotonic within a role:** Overrides only add or remove specific permissions
- **Owner-immune:** Overrides cannot reduce owner permissions
- **Fail-closed:** Missing data = deny (never allow)
- **Shop-scoped:** All resolution is within a single shop context

### 10.4 Override Semantics

The override model uses a simple allow/deny map per (shop_id, role, permission_id):

| Scenario | Base | Override | Effective |
|----------|------|----------|-----------|
| No override | GRANT | (none) | GRANT |
| No override | DENY | (none) | DENY |
| Explicit allow | DENY | ALLOW | GRANT |
| Explicit deny | GRANT | DENY | DENY |
| Override present but permission is owner-exclusive and role ≠ owner | any | ALLOW | DENY (safety) |

---

## 11. Role/Override Model

### 11.1 Chosen Model: Role Permission Overrides Per Shop

Phase F uses **role-level overrides per shop**, not member-specific overrides.

**Chosen model:**
```
shop_permission_overrides (
  shop_id    UUID FK->shops,
  role       TEXT (employee | salesOnly),
  permission_id TEXT,
  effect     TEXT ('ALLOW' | 'DENY'),
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (shop_id, role, permission_id)
)
```

**Rejected alternatives:**

| Alternative | Rejection Reason |
|------------|-----------------|
| Member-specific overrides | Complexity explosion: N members × 18 permissions per shop. Harder to reason about. Harder to audit. Owner needs to manage per-role, not per-member. |
| Shop-level global override | Cannot differentiate between employee and salesOnly at same shop. |
| Permission-level role mapping | Same as current `role_permissions_cloud` but with per-shop overrides — what we chose. |

### 11.2 Owner Role Exclusion

The `shop_permission_overrides` table does NOT include `role = 'owner'`. Owner permissions are immutable and always equal to all 18 permissions. The `UNIQUE(shop_id, role, permission_id)` constraint combined with application logic ensures owner cannot appear in the overrides table.

### 11.3 Override Validation

When an owner sets overrides for a role:
1. Role must not be `owner`
2. No `ownerExclusive` permission may be granted via override
3. Only canonical permission IDs are accepted
4. Shop ID must match the caller's shop

---

## 12. Owner/Privilege Rules

### 12.1 Owner as Cloud Role

Owner is represented via `shop_members.role = 'owner'`. The owner is also the `shops.owner_user_id`. These are always consistent: the first owner is set by `create_shop_with_owner()`.

### 12.2 Immutability Guarantees

| Rule | Enforcement |
|------|-------------|
| Owner always gets all 18 permissions | `PermissionResolver.effectivePermissions(owner)` returns `allPermissions` (line 47) |
| Owner permissions cannot be reduced | No override can target `role = 'owner'` |
| Owner cannot grant self admin via lower role | `ownerExclusive` permissions cannot be granted to non-owner |
| Last owner cannot be removed | `prevent_last_owner_removal()` trigger (Phase D) |

### 12.3 Who May Modify Permissions

| Operation | Required Actor |
|-----------|---------------|
| Modify role permissions (cloud) | Owner of the shop |
| Modify permission overrides (cloud) | Owner of the shop |
| Assign roles to members | Owner via invite/Edge Function |
| Remove members | Owner via Edge Function |
| Change own role | Impossible (owner cannot change own membership) |

### 12.4 Privilege Escalation Prevention

Server-side validation in `require_shop_permission()`:

```sql
-- Pseudocode for server-side check
v_member_role := get_member_role(p_shop_id, auth.uid());
IF v_member_role IS NULL THEN RAISE EXCEPTION; END IF;
IF v_member_role = 'owner' THEN RETURN ALL; END IF;
v_effective := resolve_permissions(p_shop_id, v_member_role);
IF p_permission NOT IN v_effective THEN RAISE EXCEPTION; END IF;
```

The actor's identity (`auth.uid()`) is derived from the JWT, never supplied by the client.

---

## 13. Server Authorization Architecture

### 13.1 Architecture Layers

```
                    ┌──────────────────────────────────┐
                    │       FLUTTER CLIENT              │
                    │  (UI permission checks only)      │
                    └─────────────┬────────────────────┘
                                  │ Supabase RPC / Edge Function calls
                                  ↓
┌─────────────────────────────────────────────────────────────┐
│                    CLOUD AUTHORIZATION STACK                  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Layer 1: Authentication                                 │ │
│  │   auth.uid() from JWT                                   │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Layer 2: Shop Membership                                │ │
│  │   shop_members WHERE user_id = auth.uid()               │ │
│  │   AND shop_id = p_shop_id AND status = 'ACTIVE'         │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Layer 3: License Entitlement                            │ │
│  │   verify_license_entitlement(p_shop_id)                 │ │
│  │   Must be in entitled state                             │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Layer 4: Permission Resolution                          │ │
│  │   require_shop_permission(p_shop_id, p_permission)      │ │
│  │   role_permissions_cloud + overrides → effective set    │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Layer 5: Operation Execution                            │ │
│  │   Business logic within same SECURITY DEFINER function  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 13.2 Separation of Concerns

| Concern | Implementation | Rationale |
|---------|---------------|-----------|
| **RLS** | Membership-only SELECT | Prevents cross-shop data leakage |
| **SECURITY DEFINER functions** | Transactional authorization + mutation | Atomic permission check + data change |
| **Edge Functions** | External API orchestration (invitations) | Requires service-role for Auth Admin API |
| **Flutter client** | UX gating only | Never the security boundary |

---

## 14. Edge Function Strategy

### 14.1 Decision: RPC-first, Edge Functions Where Required

Phase F primarily uses PostgreSQL SECURITY DEFINER functions for authorization. Edge Functions are used only where:
- Service-role is required (Supabase Auth Admin API)
- External API integration is needed
- Complex orchestration requires multiple steps outside a single DB transaction

### 14.2 Existing Edge Function

`invite-employee` — retained from Phase D. Already verifies owner membership before creating users.

### 14.3 New Edge Functions in Phase F

| Function | Purpose | Why Edge Function |
|----------|---------|-------------------|
| `manage-member-role` | Change a member's role (owner only) | Needs service-role to update membership + audit |
| `manage-permission-overrides` | Modify per-shop permission overrides (owner only) | Complex validation, audit trail |

**Note:** The actual permission enforcement (the `require_shop_permission()` check) happens in SECURITY DEFINER database functions, not Edge Functions. Edge Functions orchestrate higher-level workflows.

### 14.4 Shared Helpers

```
supabase/functions/_shared/
  auth.ts        — JWT verification, get authenticated user
  membership.ts  — Verify shop membership + role
  errors.ts      — Standardized error responses
```

---

## 15. RPC / Database Function Strategy

### 15.1 New SECURITY DEFINER Functions

| Function | Purpose | Auth Check |
|----------|---------|------------|
| `get_effective_permissions(p_shop_id)` | Return resolved permissions for caller | `auth.uid()` + membership |
| `require_shop_permission(p_shop_id, p_permission_id)` | Assert caller has permission; RAISE if not | `auth.uid()` + membership + permission |
| `get_shop_permission_overrides(p_shop_id)` | Owner views all overrides for shop | Owner only |
| `set_shop_permission_override(p_shop_id, p_role, p_permission_id, p_effect)` | Owner sets override | Owner only |
| `delete_shop_permission_override(p_shop_id, p_role, p_permission_id)` | Owner removes override | Owner only |
| `sync_user_permissions(p_shop_id)` | Full permission payload for client sync | `auth.uid()` + membership |

### 15.2 Function Design Pattern

Every new function follows the established pattern:

```sql
CREATE OR REPLACE FUNCTION function_name(p_shop_id UUID, ...)
RETURNS ...
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_member_role TEXT;
BEGIN
  -- 1. Authentication check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- 2. Membership check
  SELECT role INTO v_member_role
  FROM shop_members
  WHERE shop_id = p_shop_id AND user_id = v_user_id AND status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'Not a member of this shop';
  END IF;

  -- 3. Permission check (if required)
  -- ...

  -- 4. Business logic
  -- ...
END;
$$;
```

---

## 16. Licensing + RBAC Composition

### 16.1 Enforcement Sequence

```
1. Authenticate         — auth.uid() from JWT
2. Resolve shop         — p_shop_id parameter
3. Verify membership    — shop_members active row
4. Verify entitlement   — license is active/trial
5. Resolve permission   — role_permissions_cloud + overrides
6. Execute operation    — within same SECURITY DEFINER transaction
```

### 16.2 Composition in `require_shop_permission()`

The new helper function combines membership + entitlement + permission:

```sql
CREATE OR REPLACE FUNCTION require_shop_permission(
  p_shop_id UUID,
  p_permission_id TEXT
)
RETURNS TEXT  -- Returns the member's role
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_member_role TEXT;
  v_has_license BOOLEAN;
  v_license_status TEXT;
  v_effective BOOLEAN;
BEGIN
  -- 1. Auth
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- 2. Membership
  SELECT role INTO v_member_role
  FROM shop_members
  WHERE shop_id = p_shop_id AND user_id = v_user_id AND status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- 3. Entitlement (inline check for atomicity)
  SELECT EXISTS(
    SELECT 1 FROM licenses
    WHERE shop_id = p_shop_id AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
  ) INTO v_has_license;

  -- Allow reads even without license; block only for write permissions
  IF NOT v_has_license AND p_permission_id NOT LIKE '%.view' THEN
    RAISE EXCEPTION 'license_required';
  END IF;

  -- 4. Owner bypass
  IF v_member_role = 'owner' THEN
    RETURN v_member_role;
  END IF;

  -- 5. Permission resolution
  v_effective := check_effective_permission(p_shop_id, v_member_role, p_permission_id);

  IF NOT v_effective THEN
    RAISE EXCEPTION 'permission_denied: %', p_permission_id;
  END IF;

  RETURN v_member_role;
END;
$$;
```

### 16.3 Licensing Interaction

| Scenario | Permission | License | Result |
|----------|-----------|---------|--------|
| Active permission + active license | GRANT | ACTIVE | ALLOWED |
| Active permission + expired trial | GRANT | EXPIRED | DENIED (for writes) |
| Denied permission + active license | DENY | ACTIVE | DENIED |
| Owner + expired trial | GRANT (owner) | EXPIRED | DENIED for writes (license blocks) |
| View permission + no license | GRANT | NONE | ALLOWED (reads always ok) |

---

## 17. RLS Strategy

### 17.1 Decision: RLS Remains Membership-Only

RLS policies continue to check only:
- Is the user authenticated (`auth.uid()`)?
- Is the user an ACTIVE member of the shop that owns the row?

RLS does NOT check granular permissions. This is deliberate:

**Why not permission-aware RLS:**
1. Permission checks require resolving `role_permissions_cloud` + overrides → complex queries on every row
2. Performance: RLS runs on every row returned by a query
3. Duplication: Same permission logic would exist in both RLS and SECURITY DEFINER functions
4. Maintenance: Changing a permission policy would require updating both RLS and functions
5. Existing pattern: All mutations already go through SECURITY DEFINER functions

### 17.2 RLS Scope

| Operation | RLS Policy | Permission Check |
|-----------|-----------|-----------------|
| SELECT (reads) | Membership-based shop isolation | None (RLS sufficient) |
| INSERT/UPDATE/DELETE | None (denied) | SECURITY DEFINER function handles |
| RPC calls | N/A (functions bypass RLS) | Function-level authorization |

### 17.3 Direct Table Access Policy

| Table | Direct SELECT | Direct INSERT | Direct UPDATE | Direct DELETE |
|-------|:---:|:---:|:---:|:---:|
| `shops` | YES (RLS) | NO | NO | NO |
| `shop_members` | YES (RLS) | NO | NO | NO |
| `roles` | YES (RLS) | NO | NO | NO |
| `role_permissions_cloud` | YES (RLS) | NO | NO | NO |
| `shop_permission_overrides` | YES (RLS) | NO | NO | NO |
| `devices` | YES (RLS) | NO | NO | NO |
| `licenses` | YES (RLS) | NO | NO | NO |
| `activations` | YES (RLS) | NO | NO | NO |
| `invitations` | YES (owner-only RLS) | NO | NO | NO |

All mutations go through SECURITY DEFINER functions.

---

## 18. Permission Sync Protocol

### 18.1 Source of Truth

```
Cloud = authoritative (role_permissions_cloud + shop_permission_overrides)
Local = cache / UX optimization only
```

Local permission data is NEVER the security authority for cloud operations.

### 18.2 Sync Payload

The `sync_user_permissions(p_shop_id)` RPC returns:

```json
{
  "shop_id": "uuid",
  "member_role": "employee",
  "permissions": ["dashboard.view", "inventory.view", ...],
  "overrides": [
    {"permission_id": "inventory.edit", "effect": "DENY"},
    {"permission_id": "expenses.view", "effect": "ALLOW"}
  ],
  "permission_catalog_version": 1,
  "server_time": "2026-08-20T12:00:00Z",
  "permissions_updated_at": "2026-08-20T11:30:00Z"
}
```

### 18.3 Sync Triggers

| Trigger | Action |
|---------|--------|
| Login / session restore | Full sync |
| Shop change | Sync for new shop |
| App startup (if session valid) | Refresh sync |
| Owner modifies overrides | Owner's client re-syncs |
| License state change | (License sync already handles this) |
| Cloud authorization failure | Force re-sync |
| Manual refresh pull-down | Re-sync |

### 18.4 Sync Response Fields

| Field | Type | Purpose |
|-------|------|---------|
| `shop_id` | UUID | Scope identifier |
| `member_role` | TEXT | Caller's role in this shop |
| `permissions` | TEXT[] | Resolved effective permission IDs |
| `overrides` | ARRAY | Active overrides for caller's role |
| `permission_catalog_version` | INT | For future versioning |
| `server_time` | TIMESTAMPTZ | For staleness detection |
| `permissions_updated_at` | TIMESTAMPTZ | When permissions last changed |

---

## 19. Local Cache Architecture

### 19.1 Storage Mechanism

Store in the existing `app_settings` key-value table:

| Key | Value | Scope |
|-----|-------|-------|
| `cloud.permissions.{shopId}` | JSON blob (sync payload) | Per-shop |
| `cloud.permissions.lastSyncAt` | ISO timestamp | Global |
| `cloud.permissions.version` | Integer | Global |

### 19.2 Cache Model

```dart
class CloudPermissionSnapshot {
  final String shopId;
  final String memberRole;
  final Set<String> permissionIds;  // resolved effective permissions
  final List<PermissionOverride> overrides;
  final int catalogVersion;
  final DateTime serverTime;
  final DateTime permissionsUpdatedAt;
  final DateTime cachedAt;  // local DateTime.now() when cached
}
```

### 19.3 Shop-Scoping

Cached permissions are strictly scoped by `shopId`. When the active shop changes:
1. Load cached permissions for the new shop
2. If cache exists and is fresh → use for UI
3. If cache missing or stale → require online sync
4. Never reuse Shop A permissions for Shop B

### 19.4 Account/Shop-Switch Cleanup

| Event | Action |
|-------|--------|
| Logout | Clear in-memory cache; persistent cache retained for re-login |
| Shop switch | Load new shop's cached permissions; old shop's cache retained |
| Account switch | Clear all in-memory state; persistent cache retained |
| Shop membership removed | Cache for that shop invalidated on next sync |

---

## 20. Cache Freshness/Invalidation

### 20.1 TTL Policy

```
PERMISSION_CACHE_TTL = 1 hour
```

After 1 hour, cached permissions are considered stale. The app should attempt a background re-sync before the next write operation.

### 20.2 Invalidation Triggers

| Trigger | Scope | Action |
|---------|-------|--------|
| Login | All shops | Full re-sync |
| Shop change | Target shop | Sync for target shop |
| App startup | Active shop | Background refresh |
| Owner modifies overrides | Same shop | Re-sync on owner's client |
| Cloud auth failure | Active shop | Force re-sync |
| 401/403 from cloud RPC | Active shop | Force re-sync |
| Manual refresh | Active shop | Re-sync |

### 20.3 Version Token

The `permissions_updated_at` timestamp serves as the version token. On re-sync, if the server's `permissions_updated_at` matches the cached value, the client can skip re-processing (ETag-like optimization).

### 20.4 Logout Cleanup

On logout:
- In-memory permission cache is cleared
- Persistent `app_settings` cache is NOT cleared (available for next login)
- On next login, cache is refreshed via sync

---

## 21. Offline Permission Policy

### 21.1 Offline Permission Behavior

| Scenario | Cached Permission Available | Behavior |
|----------|:---:|---------|
| Online, valid entitlement | YES | Full access per permissions |
| Online, expired entitlement | YES | Read-only (license blocks writes) |
| Offline, cached permissions, valid cached entitlement | YES | UI shows per cached permissions; cloud writes blocked |
| Offline, cached permissions, expired cached entitlement | YES | Read-only; no cloud writes |
| Offline, no cached permissions | NO | Conservative: show minimal UI; no writes |
| Offline, cache beyond TTL | YES | Show UI; warn "permissions may be stale"; no cloud writes |

### 21.2 Critical Rule

**Cached permissions may gate UI elements offline, but NEVER authorize a cloud request.**

Every cloud RPC call is independently authorized by the server. The client's cached permission set is not sent to the server as proof of authorization.

### 21.3 Read-Only vs Cloud-Sensitive Operations

| Operation Type | Offline Permission Use | Server Revalidation |
|---------------|----------------------|-------------------|
| UI visibility | Cached permission acceptable | N/A |
| Local SQLite write | Cached permission + local entitlement | N/A |
| Cloud RPC call | Ignored (server revalidates) | Always required |
| Settings display | Cached permission acceptable | N/A |

---

## 22. Error Contract

### 22.1 Server-Side Error Codes

| Error Code | Meaning | HTTP | Client Action |
|------------|---------|------|---------------|
| `unauthenticated` | No valid JWT | 401 | Re-login |
| `not_member` | User not in shop | 403 | Contact owner |
| `membership_inactive` | Membership suspended/revoked | 403 | Contact owner |
| `license_required` | No active license for write | 403 | License needed |
| `license_expired` | License/trial expired | 403 | License renewal |
| `permission_denied` | Role lacks required permission | 403 | Contact owner |
| `invalid_permission` | Unknown permission ID | 400 | Bug report |
| `shop_mismatch` | Cross-shop violation | 403 | Bug report |
| `owner_required` | Operation requires owner | 403 | Contact owner |
| `override_violation` | Override grants owner-exclusive | 400 | Not allowed |
| `server_error` | Internal failure | 500 | Retry |

### 22.2 Client-Side Exception Mapping

```dart
enum CloudPermissionError {
  unauthenticated,
  notMember,
  membershipInactive,
  licenseRequired,
  licenseExpired,
  permissionDenied,
  invalidPermission,
  shopMismatch,
  ownerRequired,
  serverError,
  networkError,
}
```

### 22.3 Safe Error Exposure

All error messages are safe to display to the user. No internal details (table names, SQL errors, stack traces) are leaked. Server errors are generic; specific denial reasons are coded.

---

## 23. Schema/Migration Plan

### 23.1 New Migration

```
supabase/migrations/20260820000024_phase_f_rbac_permission_sync.sql
```

### 23.2 New Table: `shop_permission_overrides`

```sql
CREATE TABLE IF NOT EXISTS shop_permission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('employee', 'salesOnly')),
  permission_id TEXT NOT NULL,
  effect TEXT NOT NULL CHECK (effect IN ('ALLOW', 'DENY')),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, role, permission_id)
);

CREATE INDEX idx_shop_permission_overrides_shop_role
  ON shop_permission_overrides (shop_id, role);

COMMENT ON TABLE shop_permission_overrides IS
  'Phase F: per-shop permission overrides for non-owner roles. Owner permissions are immutable.';
```

### 23.3 RLS on `shop_permission_overrides`

```sql
ALTER TABLE shop_permission_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_overrides_isolation ON shop_permission_overrides
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = shop_permission_overrides.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );
```

### 23.4 New Functions

1. `get_effective_permissions(p_shop_id UUID)` — returns resolved permissions for the caller
2. `require_shop_permission(p_shop_id UUID, p_permission_id TEXT)` — asserts permission
3. `sync_user_permissions(p_shop_id UUID)` — full sync payload for client
4. `get_shop_permission_overrides(p_shop_id UUID)` — owner views overrides
5. `set_shop_permission_override(p_shop_id UUID, p_role TEXT, p_permission_id TEXT, p_effect TEXT)` — owner sets override
6. `delete_shop_permission_override(p_shop_id UUID, p_role TEXT, p_permission_id TEXT)` — owner removes override
7. `check_effective_permission(p_shop_id UUID, p_role TEXT, p_permission_id TEXT)` — helper (internal)

### 23.5 Migration Safety

| Aspect | Safety |
|--------|--------|
| Additive only | YES — new table, new functions, new RLS |
| No data loss | YES — no DROP, no DELETE |
| Backward compatible | YES — existing functions unchanged |
| RLS safe | YES — new policy only on new table |
| Rollback possible | YES — DROP TABLE, DROP FUNCTION |
| Idempotent | YES — CREATE OR REPLACE, IF NOT EXISTS |

### 23.6 Local Schema Impact

**NONE.** Phase F does not modify the local SQLite database. No new columns, no new tables, no schema version change. Permission cache is stored via the existing `app_settings` key-value mechanism.

---

## 24. API Contract

### 24.1 New RPC Endpoints

#### `get_effective_permissions(p_shop_id UUID)`
Returns: `TABLE(permission_id TEXT)` — the 18 canonical permission IDs the caller has for this shop.

#### `require_shop_permission(p_shop_id UUID, p_permission_id TEXT)`
Returns: `TEXT` — the caller's role if authorized. RAISES EXCEPTION if not.

#### `sync_user_permissions(p_shop_id UUID)`
Returns: `JSONB` with shape:
```json
{
  "shop_id": "uuid",
  "member_role": "employee",
  "permissions": ["dashboard.view", "inventory.view", ...],
  "overrides": [...],
  "catalog_version": 1,
  "server_time": "2026-08-20T12:00:00Z",
  "updated_at": "2026-08-20T11:30:00Z"
}
```

#### `get_shop_permission_overrides(p_shop_id UUID)`
Returns: `TABLE(role TEXT, permission_id TEXT, effect TEXT, updated_at TIMESTAMPTZ)`. Owner-only.

#### `set_shop_permission_override(p_shop_id UUID, p_role TEXT, p_permission_id TEXT, p_effect TEXT)`
Returns: `BOOLEAN`. Owner-only. Validates: role != owner, permission is canonical, not owner-exclusive.

#### `delete_shop_permission_override(p_shop_id UUID, p_role TEXT, p_permission_id TEXT)`
Returns: `BOOLEAN`. Owner-only.

### 24.2 New Edge Function Endpoints

#### `POST /functions/v1/manage-member-role`
Body: `{ shop_id, target_user_id, new_role }`
Auth: Owner JWT required.
Purpose: Change a member's role. Uses service-role for membership update.

#### `POST /functions/v1/manage-permission-overrides`
Body: `{ shop_id, overrides: [{role, permission_id, effect}] }`
Auth: Owner JWT required.
Purpose: Batch set/delete overrides. Uses service-role for override table writes.

---

## 25. Client Integration Plan

### 25.1 New Files

| File | Purpose | Est. Lines |
|------|---------|-----------|
| `app/lib/rbac/cloud_permission_repository.dart` | Supabase RPC calls for permissions | ~120 |
| `app/lib/rbac/permission_sync_service.dart` | Orchestrates sync, cache, invalidation | ~200 |
| `app/lib/rbac/permission_cache.dart` | Local persistence of cloud permission snapshot | ~100 |
| `app/lib/rbac/permission_exception.dart` | Domain exceptions for permission errors | ~40 |
| `app/lib/rbac/effective_permission_model.dart` | Data model for resolved permissions | ~60 |
| `app/test/rbac/permission_sync_service_test.dart` | Unit tests | ~250 |
| `app/test/rbac/permission_cache_test.dart` | Unit tests | ~100 |

**Total new:** ~870 lines

### 25.2 Modified Files

| File | Changes | Delta |
|------|---------|-------|
| `app/lib/services/permission_resolver.dart` | Add cloud permission source, cloud-first resolution | +60 |
| `app/lib/services/session_state.dart` | Add `cloudPermissions` getter, sync on login/shop change | +30 |
| `app/lib/services/role_permission_repository.dart` | No change (remains for offline fallback) | 0 |
| `app/lib/main.dart` | Wire permission sync on login/init | +20 |
| `app/lib/screens/auth/login_screen.dart` | Trigger permission sync after cloud login | +15 |
| `app/lib/licensing/cloud_licensing_service.dart` | No change (licensing stays separate) | 0 |

**Total modified:** ~125 lines delta

### 25.3 Integration Minimal Change

Phase F does NOT redesign the UI permission system. It adds a cloud permission source that `PermissionResolver` consults. The existing `hasPermission()` API, `_requirePermission()` guards, and UI permission checks all continue to work unchanged.

The key integration point:

```dart
// PermissionResolver gains a cloud source:
class PermissionResolver {
  // Existing:
  Map<UserRole, Set<AppPermission>>? _config;  // local SQLite

  // NEW:
  CloudPermissionSnapshot? _cloudSnapshot;  // cloud sync

  Set<AppPermission> effectivePermissions(UserRole role) {
    if (role == UserRole.owner) return PermissionCatalog.allPermissions;

    // Cloud takes priority when available
    if (_cloudSnapshot != null && _cloudSnapshot!.isFresh) {
      return _cloudSnapshot!.toPermissionSet();
    }

    // Fall back to local config
    final config = _config;
    return config?[role] ?? PermissionCatalog.defaultPermissionsForRole(role);
  }
}
```

---

## 26. Auditability

### 26.1 Audit Trail for Permission Changes

The `shop_permission_overrides` table tracks:
- `created_by` — the auth.uid() of the owner who made the change
- `created_at` / `updated_at` — timestamps

### 26.2 Extended Audit Table (Minimal)

```sql
CREATE TABLE IF NOT EXISTS permission_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL,
  action TEXT NOT NULL,  -- 'override_set', 'override_delete', 'role_change'
  target_role TEXT,
  permission_id TEXT,
  old_effect TEXT,
  new_effect TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_permission_audit_shop ON permission_audit_log (shop_id, created_at DESC);
```

### 26.3 Audit Insert Points

Every permission-changing operation inserts an audit row:
- `set_shop_permission_override` → inserts audit row
- `delete_shop_permission_override` → inserts audit row
- `manage-member-role` (Edge Function) → inserts audit row

---

## 27. Concurrency

### 27.1 Concurrent Permission Mutations

| Scenario | Protection |
|----------|-----------|
| Two owner sessions modify same role | `UNIQUE(shop_id, role, permission_id)` constraint + UPSERT |
| Override modified while operation executes | Atomic: `require_shop_permission()` reads current state within same transaction |
| Role changed during sync | Sync returns latest; client re-syncs on conflict |
| Membership removed while sync occurs | Next sync detects missing membership; cache invalidated |

### 27.2 Atomic Authorization

All permission checks happen within a single SECURITY DEFINER function call. The function:
1. Reads membership
2. Reads license
3. Reads effective permissions
4. Executes operation (if authorized)

All within a single PostgreSQL transaction. No TOCTOU (time-of-check-to-time-of-use) vulnerabilities.

---

## 28. Security Threat Model

### 28.1 Threat Analysis

| Threat | Impact | Mitigation | Risk |
|--------|--------|------------|------|
| Client forges role | Unauthorized access | Server never trusts client role; reads from `shop_members` | NONE |
| Client forges permission list | Bypass UI checks | Server enforces via `require_shop_permission()` | NONE |
| Client modifies local cache | Stale permissions | Server revalidates every cloud request | NONE |
| Client changes shop_id | Cross-shop access | Server verifies membership per shop | NONE |
| User from Shop A targets Shop B | Cross-shop attack | RLS + function-level shop_id validation | NONE |
| Removed member uses stale cache | Unauthorized access | Cache invalidated on next sync; membership check | LOW |
| Demoted user uses stale permissions | Over-permission | Cache refreshed on re-login; server enforces | LOW |
| Seller grants self owner/admin | Privilege escalation | Owner-exclusive check in override setter; role change via Edge Function requires owner | NONE |
| Malicious user calls RPC directly | Bypass authorization | Every RPC checks auth.uid() + membership + permission | NONE |
| Unknown permission identifier | Implicit allow | Fail-closed: unknown ID → exception | NONE |
| Direct table mutation bypasses RPC | Bypass authorization | No client INSERT/UPDATE/DELETE policies on any table | NONE |
| Expired license with valid permission | Unauthorized write | `require_shop_permission()` checks entitlement | NONE |
| Service-role exposure | Full bypass | Never in Flutter binary; Edge Functions use server env | NONE |
| SECURITY DEFINER privilege mistake | Privilege escalation | Explicit `SET search_path = public`; minimal queries | LOW |
| Overly broad EXECUTE grant | Unauthorized function use | GRANT EXECUTE to authenticated only; review grants | LOW |
| Race between auth and mutation | TOCTOU | Atomic transaction in SECURITY DEFINER function | NONE |

### 28.2 Mitigation Summary

| Category | Strategy |
|----------|---------|
| Identity spoofing | JWT + `auth.uid()` from server |
| Role spoofing | Server reads role from `shop_members`, never trusts client |
| Permission spoofing | Server resolves from `role_permissions_cloud`, never trusts client |
| Cross-shop attacks | RLS + function-level shop_id validation |
| Privilege escalation | Owner-exclusive invariant enforced server-side |
| Offline abuse | Cached permissions for UI only; cloud requests always revalidate |
| Cache poisoning | Cache is local-only; server always reauthorizes |

---

## 29. Test Strategy

### 29.1 Permission Catalog Tests

| Test | Assertion |
|------|-----------|
| All 18 canonical permissions represented | `AppPermission.values.length == 18` |
| No duplicate stable IDs | All `.id` values unique |
| Invalid permission rejected | `AppPermission.fromId('invalid')` throws |
| Client/server IDs aligned | `role_permissions_cloud` seed matches `AppPermission.id` |
| Owner-exclusive set correct | 2 permissions in `ownerExclusive` |

### 29.2 Authorization Tests

| Test | Assertion |
|------|-----------|
| Permitted user succeeds | `require_shop_permission` returns role |
| Denied user fails | `require_shop_permission` raises exception |
| Unauthenticated fails | `auth.uid() = NULL` → exception |
| Non-member fails | No `shop_members` row → exception |
| Member from another shop fails | Wrong `shop_id` → exception |
| Inactive member fails | `status != 'ACTIVE'` → exception |

### 29.3 Override Tests

| Test | Assertion |
|------|-----------|
| Base allow + explicit deny override → DENY | Override wins |
| Base deny + explicit allow override → GRANT | Override wins |
| No override → base applies | Default behavior |
| Malformed override rejected | CHECK constraint + validation |
| Cross-shop override attempt fails | Shop_id mismatch → exception |
| Unauthorized override mutation fails | Non-owner → exception |
| Owner-exclusive permission override rejected | `admin.users.manage` cannot be ALLOW'd for non-owner |

### 29.4 Owner / Privilege Escalation Tests

| Test | Assertion |
|------|-----------|
| Seller cannot grant self admin permission | Override setter rejects `ownerExclusive` for non-owner |
| Non-owner cannot change protected role | Edge Function requires owner JWT |
| Member cannot alter another shop | Shop_id validation in every function |
| Owner permissions immutable | Override for `role = 'owner'` rejected |

### 29.5 Licensing + RBAC Composition Tests

| Test | Assertion |
|------|-----------|
| Valid permission + invalid license → denied | License check in `require_shop_permission` |
| Valid license + missing permission → denied | Permission check in `require_shop_permission` |
| Both valid → operation permitted | Full check passes |
| Expired trial → write denied | License status check |
| View permission + no license → allowed | Read permissions bypass license check |

### 29.6 Permission Sync Tests

| Test | Assertion |
|------|-----------|
| Sync success | Full payload returned |
| Stale cache refresh | TTL exceeded → re-sync |
| Login triggers sync | Full sync on cloud login |
| Shop change triggers sync | Sync for new shop |
| Logout clears in-memory cache | Cache null after logout |
| Role changed | Next sync returns new permissions |
| Overrides changed | Next sync reflects overrides |
| Membership removed | Next sync detects; cache invalidated |

### 29.7 Security Tests

| Test | Assertion |
|------|-----------|
| No service-role secrets in client | Secret scan |
| No debug bypass | Code review |
| No caller-supplied `user_id` trust | `auth.uid()` used everywhere |
| Cross-shop isolation | RLS + function validation |
| SQL `search_path` explicit | All functions use `SET search_path = public` |
| Grants review | Only `authenticated` can EXECUTE |
| Function authorization | Every function checks auth + membership |

### 29.8 Regression Tests

| Test | Assertion |
|------|-----------|
| Phase D auth/membership healthy | Existing tests pass |
| Phase E licensing tests pass | Existing tests pass |
| Local permission behavior unchanged | `hasPermission()` API unchanged |
| UI permission gating unchanged | All existing `hasPermission` calls work |

---

## 30. Acceptance Gates

| Gate | Purpose | Command/Check | Expected | Status |
|------|---------|---------------|----------|--------|
| F-01 | Repository identity | `git branch --show-current` | `codex/i-tech-next-roadmap-freeze` | BLOCKING |
| F-02 | Baseline/ancestry | `git log --oneline -3` | f586f725 is HEAD | BLOCKING |
| F-03 | Diff scope | `git diff --stat` | Only planning doc | BLOCKING |
| F-04 | Dart formatter | `dart format --set-exit-if-changed app/` | 0 files changed | BLOCKING |
| F-05 | Flutter analyzer | `flutter analyze` | 0 errors, 0 warnings | BLOCKING |
| F-06 | Existing regression tests | `flutter test` | All passing | BLOCKING |
| F-07 | Permission catalog tests | New test file | 18 permissions, no duplicates | BLOCKING |
| F-08 | Server RBAC tests | SQL test / RPC test | Authorization helpers work | BLOCKING |
| F-09 | Permission override tests | SQL test | Override resolution correct | BLOCKING |
| F-10 | Permission sync/cache tests | Unit tests | Sync round-trip works | BLOCKING |
| F-11 | Cross-shop isolation | SQL test | No cross-shop leakage | BLOCKING |
| F-12 | Privilege escalation tests | Unit + SQL tests | No escalation possible | BLOCKING |
| F-13 | Licensing + RBAC composition | Integration test | Both checks enforced | BLOCKING |
| F-14 | SQL security review | Manual review | No unsafe patterns | BLOCKING |
| F-15 | SECURITY DEFINER search_path | `grep` all functions | All use `SET search_path = public` | BLOCKING |
| F-16 | Function grants/revokes | SQL query | Only `authenticated` EXECUTE | BLOCKING |
| F-17 | Secret scan | `grep -r service_role app/` | No matches | BLOCKING |
| F-18 | Debug/bypass scan | `grep -rn 'debug.*allow\|if.*debug'` | No bypass patterns | BLOCKING |
| F-19 | Conflict marker scan | `git diff --check` | No markers | BLOCKING |
| F-20 | Preserved artifact integrity | SHA-256 match | Both files match | BLOCKING |
| F-21 | Preserved stash integrity | `git stash list` | `3f9e4d2e` present | BLOCKING |
| F-22 | Worktree/index integrity | `git status` | Clean except untracked | BLOCKING |
| F-23 | No deployment | Manual | No `supabase db push` | BLOCKING |
| F-24 | No unrelated Phase G work | `git diff --stat` | Only Phase F files | BLOCKING |

---

## 31. Task Breakdown

### F1: Baseline Verification
- **Objective:** Verify repository identity, HEAD, ancestry, remote divergence, stash, artifacts
- **Files:** None (read-only)
- **Schema/API:** None
- **Dependencies:** None
- **Security:** None
- **Tests:** Verification commands
- **Completion:** All checks pass
- **Risks:** None

### F2: Cloud Schema Migration — `shop_permission_overrides` + Audit Log
- **Objective:** Create the new tables and RLS for permission overrides and audit
- **Files:** `supabase/migrations/20260820000024_phase_f_rbac_permission_sync.sql`
- **Schema:** New tables `shop_permission_overrides`, `permission_audit_log`
- **Dependencies:** F1
- **Security:** RLS on new tables; no client mutation policies
- **Tests:** Table creation, RLS isolation
- **Completion:** Migration SQL valid; tables created
- **Risks:** None (additive only)

### F3: Permission Resolution Helper Functions
- **Objective:** Create `check_effective_permission()`, `get_effective_permissions()`, `require_shop_permission()`
- **Files:** `supabase/migrations/20260820000024_phase_f_rbac_permission_sync.sql`
- **Schema:** New SECURITY DEFINER functions
- **Dependencies:** F2
- **Security:** All functions use `auth.uid()`; `SET search_path = public`; atomic permission resolution
- **Tests:** Permission resolution for all 3 roles; override behavior; owner bypass
- **Completion:** Functions handle all 18 permissions correctly
- **Risks:** Performance of permission resolution (mitigated by simple query plan)

### F4: Permission Sync RPC
- **Objective:** Create `sync_user_permissions()` function
- **Files:** Same migration file
- **Schema:** New SECURITY DEFINER function returning JSONB
- **Dependencies:** F3
- **Security:** Returns only caller's permissions; never leaks other members' permissions
- **Tests:** Full payload structure; correctness for each role
- **Completion:** Returns accurate permission snapshot
- **Risks:** None

### F5: Override Management Functions
- **Objective:** Create `get_shop_permission_overrides()`, `set_shop_permission_override()`, `delete_shop_permission_override()`
- **Files:** Same migration file
- **Schema:** New SECURITY DEFINER functions with owner-only checks
- **Dependencies:** F2
- **Security:** Owner-only; validates against owner-exclusive; audit logging
- **Tests:** Owner can set/delete; non-owner cannot; owner-exclusive rejected
- **Completion:** Override CRUD works with full validation
- **Risks:** None

### F6: Cloud Permission Repository (Dart)
- **Objective:** Create `CloudPermissionRepository` for Supabase RPC calls
- **Files:** `app/lib/rbac/cloud_permission_repository.dart`
- **Schema:** None (client-side)
- **Dependencies:** F4, F5
- **Security:** No secrets; uses authenticated Supabase client only
- **Tests:** Mock RPC responses; error handling
- **Completion:** Repository calls all new RPCs correctly
- **Risks:** None

### F7: Permission Cache (Dart)
- **Objective:** Create `PermissionCache` for local persistence of cloud permission snapshots
- **Files:** `app/lib/rbac/permission_cache.dart`
- **Schema:** None (uses `app_settings`)
- **Dependencies:** None
- **Security:** Cache is informational only
- **Tests:** Save/load/clear; TTL check; shop-scoping
- **Completion:** Cache round-trip works correctly
- **Risks:** None

### F8: Permission Sync Service (Dart)
- **Objective:** Create `PermissionSyncService` orchestrating sync, cache, invalidation
- **Files:** `app/lib/rbac/permission_sync_service.dart`
- **Schema:** None (client-side)
- **Dependencies:** F6, F7
- **Security:** Sync respects offline policy; cache never authoritative
- **Tests:** Full sync flow; offline fallback; shop change; logout
- **Completion:** Service correctly syncs and caches permissions
- **Risks:** None

### F9: Permission Exception Classes
- **Objective:** Define `CloudPermissionException` hierarchy
- **Files:** `app/lib/rbac/permission_exception.dart`
- **Schema:** None
- **Dependencies:** None
- **Security:** None
- **Tests:** Exception creation and messages
- **Completion:** All error codes defined
- **Risks:** None

### F10: PermissionResolver Integration
- **Objective:** Modify `PermissionResolver` to consult cloud permissions when available
- **Files:** `app/lib/services/permission_resolver.dart`
- **Schema:** None
- **Dependencies:** F8
- **Security:** Cloud permissions take precedence; local fallback preserved
- **Tests:** Cloud-first resolution; offline fallback; owner invariant preserved
- **Completion:** `effectivePermissions()` consults cloud snapshot
- **Risks:** LOW — existing behavior preserved when cloud unavailable

### F11: SessionState Integration
- **Objective:** Wire permission sync into login/shop-change flow
- **Files:** `app/lib/services/session_state.dart`, `app/lib/main.dart`
- **Schema:** None
- **Dependencies:** F8, F10
- **Security:** Sync triggers on every login; shop change re-syncs
- **Tests:** Login triggers sync; shop change re-syncs
- **Completion:** Permissions are synced on login and shop change
- **Risks:** LOW

### F12: Client Unit Tests
- **Objective:** Write unit tests for all new Dart components
- **Files:** `app/test/rbac/permission_sync_service_test.dart`, `app/test/rbac/permission_cache_test.dart`
- **Schema:** None
- **Dependencies:** F6-F11
- **Security:** Tests cover security scenarios
- **Tests:** All test cases from Section 29.6
- **Completion:** All new tests pass
- **Risks:** None

### F13: Server Security Tests
- **Objective:** Verify all SECURITY DEFINER functions are secure
- **Files:** SQL test scripts (manual or `pg_prove`)
- **Schema:** None
- **Dependencies:** F3-F5
- **Security:** search_path; grants; auth.uid() usage
- **Tests:** All test cases from Section 29.7
- **Completion:** All security tests pass
- **Risks:** None

### F14: Regression and Final Gates
- **Objective:** Run all existing tests + new tests; verify all acceptance gates
- **Files:** None (read-only)
- **Schema:** None
- **Dependencies:** All previous tasks
- **Security:** All security gates pass
- **Tests:** `flutter test`; `flutter analyze`; `dart format`; secret scan
- **Completion:** All gates F-01 through F-24 pass
- **Risks:** None

### F15: Planning Document Commit
- **Objective:** Commit the planning document locally
- **Files:** `PHASE_F_SERVER_SIDE_RBAC_PERMISSION_SYNC_PLAN.md`
- **Schema:** None
- **Dependencies:** F14
- **Security:** No production code in commit
- **Tests:** `git diff --cached --stat`
- **Completion:** Single local commit created
- **Risks:** None

---

## 32. File-Level Change Map

### 32.1 New Files (Phase F Implementation)

| File | Category |
|------|----------|
| `supabase/migrations/20260820000024_phase_f_rbac_permission_sync.sql` | Schema |
| `app/lib/rbac/cloud_permission_repository.dart` | Service |
| `app/lib/rbac/permission_sync_service.dart` | Service |
| `app/lib/rbac/permission_cache.dart` | Service |
| `app/lib/rbac/permission_exception.dart` | Model |
| `app/lib/rbac/effective_permission_model.dart` | Model |
| `supabase/functions/_shared/auth.ts` | Edge Function helper |
| `supabase/functions/_shared/membership.ts` | Edge Function helper |
| `supabase/functions/_shared/errors.ts` | Edge Function helper |
| `supabase/functions/manage-member-role/index.ts` | Edge Function |
| `supabase/functions/manage-permission-overrides/index.ts` | Edge Function |
| `app/test/rbac/permission_sync_service_test.dart` | Test |
| `app/test/rbac/permission_cache_test.dart` | Test |

### 32.2 Modified Files

| File | Changes |
|------|---------|
| `app/lib/services/permission_resolver.dart` | Add cloud permission source |
| `app/lib/services/session_state.dart` | Add cloud permissions getter, sync triggers |
| `app/lib/main.dart` | Wire permission sync on login/init |
| `app/lib/screens/auth/login_screen.dart` | Trigger permission sync after cloud login |

### 32.3 Possible Files (Defer to Implementation)

| File | Reason |
|------|--------|
| `app/lib/screens/admin/roles_permissions_screen.dart` | May need minor updates for cloud sync awareness |
| `app/lib/services/app_settings.dart` | May need new key constants for permission cache |

### 32.4 Not Expected to Change

| File | Reason |
|------|--------|
| `app/lib/licensing/*.dart` | Licensing stays separate |
| `app/lib/database/database_helper.dart` | Local DB unchanged |
| `app/lib/database/user_repository.dart` | Auth unchanged |
| `app/lib/models/user_role.dart` | 3 roles frozen |
| `app/lib/services/permissions.dart` | 18 permissions frozen |
| `supabase/migrations/20260820000023_*.sql` | Phase E migration unchanged |
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | Preserved |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | Preserved |

---

## 33. Security — Fail Closed

Authorization fails closed when:
- User is unauthenticated (`auth.uid() = NULL`)
- Shop does not exist
- Membership does not exist
- Membership is inactive (`status != 'ACTIVE'`)
- Role cannot be resolved
- Permission identifier is unknown
- Override is malformed
- Entitlement is not active (for write operations)
- Server state cannot be verified for a cloud mutation
- Cache is corrupt or from another shop

No debug bypass. No hardcoded backdoor. No embedded service-role key. No client-supplied role trust.

---

## 34. Service Role / Secret Boundary

| Secret | Location | Flutter Client |
|--------|----------|:---:|
| `SUPABASE_URL` | Build-time `--dart-define` | YES (public) |
| `SUPABASE_ANON_KEY` | Build-time `--dart-define` | YES (public) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function env only | NO |
| Database password | Supabase managed | NO |
| JWT signing key | Supabase managed | NO |
| Edge Function secrets | Edge Function env | NO |

Phase F planning must preserve this boundary. No new secrets introduced.

---

## 35. Grants / Execution Rights

| Function | EXECUTE Grant |
|----------|:---:|
| `get_effective_permissions` | `authenticated` |
| `require_shop_permission` | `authenticated` |
| `sync_user_permissions` | `authenticated` |
| `get_shop_permission_overrides` | `authenticated` |
| `set_shop_permission_override` | `authenticated` |
| `delete_shop_permission_override` | `authenticated` |
| `check_effective_permission` | Not directly callable (internal helper) |

No `anon` or `PUBLIC` EXECUTE on any new function.

---

## 36. Canonical Permission Versioning

### 36.1 Decision: Version Token in Sync Response

The sync response includes `catalog_version` (integer). Currently set to `1`. This enables future compatibility:

- If client version < server catalog → unknown permissions silently ignored (existing behavior in `decodeSet`)
- If client version > server catalog → server returns what it knows; client uses defaults for unknown
- Unknown permissions are always denied (fail closed)

### 36.2 Version Increment Triggers

Increment `catalog_version` when:
- New permissions are added to `AppPermission` enum
- Existing permission semantics change (not just renaming, which is forbidden)
- Owner-exclusive set changes

This is a future concern. Phase F sets version to `1` and establishes the mechanism.

---

## 37. Database Constraints

### 37.1 New Constraints

| Table | Constraint | Purpose |
|-------|-----------|---------|
| `shop_permission_overrides` | `UNIQUE(shop_id, role, permission_id)` | One override per permission per role per shop |
| `shop_permission_overrides` | `CHECK (role IN ('employee', 'salesOnly'))` | Owner excluded |
| `shop_permission_overrides` | `CHECK (effect IN ('ALLOW', 'DENY'))` | Binary effect |
| `shop_permission_overrides` | `FK shop_id -> shops ON DELETE CASCADE` | Shop deletion cleans up |
| `permission_audit_log` | `FK shop_id -> shops ON DELETE CASCADE` | Shop deletion cleans up |

### 37.2 Indexes

| Table | Index | Purpose |
|-------|-------|---------|
| `shop_permission_overrides` | `(shop_id, role)` | Permission resolution query |
| `permission_audit_log` | `(shop_id, created_at DESC)` | Audit log query |

---

## 38. Migration Strategy

| Aspect | Approach |
|--------|----------|
| Filename | `20260820000024_phase_f_rbac_permission_sync.sql` |
| Type | Additive only |
| Backfill | None needed (new tables start empty) |
| Defaults | `created_at DEFAULT now()`, `updated_at DEFAULT now()` |
| Nullability | `created_by` nullable (for service-role operations) |
| Constraint timing | Immediate (no data to validate) |
| Rollback | `DROP TABLE shop_permission_overrides; DROP TABLE permission_audit_log; DROP FUNCTION ...` |
| Compatibility | Fully backward compatible; existing functions unchanged |
| Preserved data | All existing role mappings and permissions untouched |

---

## 39. Edge Function Structure

```
supabase/functions/
  _shared/
    auth.ts           — JWT verification helper
    membership.ts     — Shop membership verification
    errors.ts         — Standardized error response format
  invite-employee/
    index.ts          — EXISTING, retained from Phase D
  manage-member-role/
    index.ts          — NEW: role change (owner only)
  manage-permission-overrides/
    index.ts          — NEW: override batch management (owner only)
```

Each Edge Function:
1. Verifies JWT via `_shared/auth.ts`
2. Verifies owner membership via `_shared/membership.ts`
3. Performs operation with service-role client
4. Returns standardized response via `_shared/errors.ts`

---

## 40. Permission Administration Flow

### 40.1 Scope Decision

Phase F implements the **server-side backend** for permission management. The existing UI (`roles_permissions_screen.dart`) continues to work for local permission configuration.

Phase F does NOT include:
- New UI for cloud permission overrides
- New admin console
- New permission management screens

The existing `roles_permissions_screen.dart` can be extended in a later phase to use the cloud sync API. For Phase F, the override management is accessible via:
1. Direct RPC calls from the existing admin screen (for testing)
2. Future admin UI (Phase G+)

### 40.2 Rationale

The governing Phase F scope is "server-side RBAC, sync, and overrides" — not a complete admin console. Adding admin UI would expand scope beyond the authorized boundaries.

---

## 41. Deferred Observations from Phase E

These Phase E observations may be relevant to Phase F but are NOT automatically in scope:

1. **`metadata` JSONB column lacks schema validation** — Not relevant to RBAC. Deferred.
2. **`activate_device` has a count-then-insert race window** — Mitigated by PostgreSQL transaction atomicity. Not a Phase F concern.
3. **`deactivate_device` lacks an extra defensive inner WHERE** — Could add `AND status = 'ACTIVE'` to the UPDATE. Not blocking Phase F.

---

## 42. Risks

| Risk | Probability | Impact | Mitigation |
|------|:---:|:---:|------------|
| Permission resolution query performance | LOW | LOW | Simple query plan; small dataset (18 permissions × 3 roles) |
| Client cache staleness | MEDIUM | LOW | 1-hour TTL; forced refresh on auth failure |
| Edge Function deployment issues | LOW | MEDIUM | Test with `supabase functions serve` locally first |
| Conflict with future Phase G data model | LOW | LOW | Phase F schema is additive; no Phase G dependencies |
| Override complexity growth | LOW | LOW | Constrained to 2 roles × 18 permissions max |

---

## 43. Implementation Order

```
F1  Baseline verification
 ↓
F2  Cloud schema migration
 ↓
F3  Permission resolution helpers (SQL)
 ↓
F4  Permission sync RPC (SQL)
 ↓
F5  Override management functions (SQL)
 ↓
F6  Cloud permission repository (Dart)
 ↓
F7  Permission cache (Dart)
 ↓
F8  Permission sync service (Dart)
 ↓
F9  Permission exceptions (Dart)
 ↓
F10 PermissionResolver integration
 ↓
F11 SessionState + login integration
 ↓
F12 Client unit tests
 ↓
F13 Server security tests
 ↓
F14 Regression and final gates
 ↓
F15 Planning document commit
```

Critical path: F1 → F2 → F3 → F4 → F6 → F8 → F10 → F11 → F14

---

## 44. Definition of Done

Phase F implementation is complete when:

1. `shop_permission_overrides` table exists with RLS
2. `permission_audit_log` table exists with RLS
3. All 7 new SECURITY DEFINER functions are deployed
4. `sync_user_permissions()` returns correct payload
5. Override CRUD works with owner-only enforcement
6. `PermissionResolver` uses cloud permissions when available
7. Login triggers permission sync
8. Shop change triggers re-sync
9. Offline fallback to local permissions works
10. All 18 permissions resolve correctly for all 3 roles
11. Owner always gets all permissions (immutable)
12. Licensing + RBAC composition enforced
13. All existing tests pass
14. All new tests pass
15. `flutter analyze` clean
16. `dart format` clean
17. No secrets in client code
18. No debug bypass
19. Preserved artifacts intact
20. Local planning commit created

---

## 45. Implementation Session Entry Contract

Before starting Phase F implementation:

```
VERIFIED:
  [x] Repository identity correct
  [x] Phase E baseline locked
  [x] Ancestry chain intact
  [x] Remote divergence = 0
  [x] Planning document committed locally
  [x] All governing documents reviewed
  [x] Existing permission architecture mapped
  [x] Existing cloud schema reviewed
  [x] Security trust gaps identified
  [x] Effective permission model designed
  [x] Permission override model designed
  [x] Server-side enforcement architecture designed
  [x] Licensing + RBAC composition designed
  [x] Permission sync designed
  [x] Local cache semantics designed
  [x] Offline behavior designed
  [x] Cache invalidation designed
  [x] Test matrix designed
  [x] Implementation tasks sequenced
  [x] File-level scope mapped
  [x] Threat model completed
```

---

## 46. Remote Lock Follow-up Contract

After local Phase F implementation commit:

```
NEXT SESSION: Phase F Remote Implementation Baseline Lock Session
  1. Verify local HEAD = Phase F implementation commit
  2. Verify all acceptance gates pass
  3. Push to github
  4. Create annotated tag: phase-f-implementation-locked
  5. Verify remote = local = tag
  6. Verify stash intact
  7. Verify preserved artifacts intact
  8. Emit: PASS_PHASE_F_REMOTE_LOCKED
```

---

## 47. Non-Goals Reinforcement

This planning document does NOT:
- Implement any production code
- Create any Supabase migration for execution
- Deploy any Edge Functions
- Deploy any database changes
- Create or modify any users
- Modify licensing behavior
- Change Phase E security rules
- Implement billing/subscriptions
- Implement Phase G or later
- Push to GitHub
- Create a remote tag
- Rewrite history
- Force push

---

*This document is the Phase F planning artifact for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md phase roadmap.*
