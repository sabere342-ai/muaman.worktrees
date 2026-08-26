# Supabase Production Deployment Plan

## 7.1 Purpose and Deployment Objective

This document defines the complete, executable plan for deploying the I Tech Store Management Application's Supabase backend to production.

**"Supabase production deployment ready" means:**

 1. A dedicated production Supabase project exists and is configured
 2. All 17 migrations apply cleanly in sequence against a clean database
 3. RLS policies are active and verified on all 21 tenant-scoped tables
 4. Auth integration works: signup, login, shop creation, membership, invitations
 5. 14-day server-controlled trial licensing operates correctly
 6. Device activation lifecycle (registration → activation → limits → revocation) functions
 7. RBAC/permission sync operates server-authoritatively
 8. Offline-first sync infrastructure (server_version, sync_log, idempotency) is operational
 9. Cross-tenant isolation is cryptographically verified (SHOP_A cannot access SHOP_B)
 10. Backup/rollback strategy is documented and tested
 11. All deployment gates pass with documented evidence

**This plan does NOT execute deployment.** It provides the deterministic sequence for a future deployment session.

---

## 7.2 Governing Locked Baselines

| Baseline | Commit SHA | Tag |
|----------|------------|-----|
| Phase N Planning | `4f356f1a146ced265f776d213dd5379fa489a7d3` | `phase-n-planning-baseline-locked` |
| Phase N Implementation | `e697759f60952cf567dc03aaa485b91626255a9a` | `phase-n-implementation-locked` |
| Android Remediation | `693f1d92a33af4a5ff7432a20f03994129a405dd` | `phase-n-android-startup-defect-remediation-locked` |
| Supabase Production Deployment Planning | `741b4236d4344e8fbd3f66c8c41af4595da15de7` | `supabase-production-deployment-planning-baseline-locked` |

**Ancestry verified:**
- `phase-n-planning-baseline-locked` → ancestor of `phase-n-implementation-locked` ✓
- `phase-n-implementation-locked` → ancestor of `phase-n-android-startup-defect-remediation-locked` ✓
- `phase-n-android-startup-defect-remediation-locked` → ancestor of `supabase-production-deployment-planning-baseline-locked` ✓

**Current repository HEAD at planning time:** `741b4236d4344e8fbd3f66c8c41af4595da15de7` (Supabase production deployment planning baseline)

**Branch:** `codex/i-tech-next-roadmap-freeze`
**Authorized remote:** `github` (https://github.com/sabere342-ai/muaman.worktrees.git)
**Legacy remote (SACRED — untouched):** `origin` (C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن)

---

## 7.3 Current Backend Inventory

### Tables (21 tenant-scoped + Auth)

| Table | Purpose | RLS | Phase |
|-------|---------|-----|-------|
| `shops` | Tenant identity | ✅ | C |
| `shop_members` | User-tenant membership | ✅ | C |
| `roles` | Per-shop role definitions | ✅ | C |
| `role_permissions_cloud` | Permission assignments | ✅ | C |
| `devices` | Device registration | ✅ | C |
| `licenses` | Shop licensing/trial | ✅ | C |
| `activations` | Device-license binding | ✅ | C |
| `invitations` | Employee invitations | ✅ | D |
| `shop_permission_overrides` | Per-shop permission overrides | ✅ | F |
| `permission_audit_log` | Permission change audit | ✅ | F |
| `cloud_products` | Product catalog | ✅ | G |
| `cloud_customers` | Customer directory | ✅ | G |
| `cloud_sales` | Sales records | ✅ | G |
| `cloud_returns` | Return records | ✅ | G |
| `cloud_expenses` | Expense records | ✅ | G |
| `cloud_expense_categories` | Expense categories | ✅ | G |
| `cloud_invoices` | Invoices | ✅ | G |
| `cloud_inventory_count` | Stocktake observations | ✅ | G |
| `cloud_shop_settings` | Per-shop settings | ✅ | G |
| `sync_log` | Sync audit trail | ✅ | H |
| `cloud_migration_ledger` | Legacy migration audit | ✅ | I |

**Auth dependencies:** `auth.users` (Supabase managed)

### Enums / Constraints

- `shop_members.role`: `owner`, `employee`, `salesOnly`
- `shop_members.status`: `INVITED`, `ACTIVE`, `SUSPENDED`, `REVOKED`
- `devices.platform`: `windows`, `android`
- `devices.status`: `ACTIVE`, `REVOKED`, `LOST`
- `licenses.status`: `TRIAL`, `ACTIVE`, `EXPIRED`, `SUSPENDED`, `PERPETUAL`
- `activations.status`: `ACTIVE`, `REVOKED`, `EXPIRED`
- `invitations.status`: `PENDING`, `ACCEPTED`, `EXPIRED`, `REVOKED`
- `shop_permission_overrides.effect`: `ALLOW`, `DENY`
- `shop_permission_overrides.role`: `employee`, `salesOnly` (owner excluded)

### Functions (52 total final identities: 44 client-callable RPCs, 4 internal helpers, 4 migration-only)

| # | Function | Purpose | Phase | Category | Auth / Grants |
|---|----------|---------|-------|----------|---------------|
| 1 | `create_shop_with_owner(p_name)` | Create shop + owner membership | C | RPC | JWT, GRANT to authenticated |
| 2 | `get_user_shops()` | List user's active shops | C | RPC | JWT, GRANT to authenticated |
| 3 | `verify_shop_membership(p_shop_id)` | Check membership | C | RPC | JWT, GRANT to authenticated |
| 4 | `start_trial(p_shop_id)` | Owner: start 14-day trial | C | RPC | JWT + owner, GRANT to authenticated |
| 5 | `verify_trial_status(p_shop_id)` | Check trial status | C | RPC | JWT, GRANT to authenticated |
| 6 | `accept_invitation(p_shop_id, p_user_id)` | Activate invited membership | D | RPC | JWT, GRANT to authenticated |
| 7 | `verify_license_entitlement(p_shop_id)` | Full license status | E | RPC | JWT, GRANT to authenticated |
| 8 | `register_device(p_shop_id, p_installation_id, p_platform, p_device_name)` | Register device | E | RPC | JWT, GRANT to authenticated |
| 9 | `activate_device(p_shop_id, p_installation_id)` | Activate device | E | RPC | JWT, GRANT to authenticated |
| 10 | `deactivate_device(p_activation_id)` | Owner: revoke device | E | RPC | JWT + owner, GRANT to authenticated |
| 11 | `get_device_list(p_shop_id)` | Owner: list devices | E | RPC | JWT + owner, GRANT to authenticated |
| 12 | `check_effective_permission(p_shop_id, p_role, p_permission_id)` | Resolves base + override permissions | F | **Internal Helper** | SECURITY DEFINER, **NOT GRANTED** |
| 13 | `get_effective_permissions(p_shop_id)` | Resolved permissions for caller | F | RPC | JWT, GRANT to authenticated |
| 14 | `require_shop_permission(p_shop_id, p_permission_id)` | Assert permission | F | RPC | JWT, GRANT to authenticated |
| 15 | `sync_user_permissions(p_shop_id)` | Full permission payload | F | RPC | JWT, GRANT to authenticated |
| 16 | `get_shop_permission_overrides(p_shop_id)` | Owner: view overrides | F | RPC | JWT + owner, GRANT to authenticated |
| 17 | `set_shop_permission_override(p_shop_id, p_role, p_permission_id, p_effect)` | Owner: set override | F | RPC | JWT + owner, GRANT to authenticated |
| 18 | `delete_shop_permission_override(p_shop_id, p_role, p_permission_id)` | Owner: delete override | F | RPC | JWT + owner, GRANT to authenticated |
| 19 | `create_cloud_product(p_shop_id, p_name, p_barcode, p_opening_quantity, p_cost_price)` | Create product | G | RPC | `inventory.edit`, GRANT to authenticated |
| 20 | `update_cloud_product(p_shop_id, p_product_id, ..., p_expected_version)` | Update product (version-aware) | G/H | RPC | `inventory.edit`, GRANT to authenticated |
| 21 | `delete_cloud_product(p_shop_id, p_product_id)` | Delete product | G | RPC | `inventory.delete`, GRANT to authenticated |
| 22 | `create_cloud_customer(p_shop_id, p_name, p_phone, p_address, p_notes, p_is_active, p_is_system)` | Create customer | G | RPC | `inventory.edit`, GRANT to authenticated |
| 23 | `update_cloud_customer(p_shop_id, p_customer_id, ..., p_expected_version)` | Update customer (version-aware) | G/H | RPC | `inventory.edit`, GRANT to authenticated |
| 24 | `delete_cloud_customer(p_shop_id, p_customer_id)` | Delete customer | G | RPC | `inventory.delete`, GRANT to authenticated |
| 25 | `create_cloud_expense_category(p_shop_id, p_name)` | Create expense category | G | RPC | `expenses.create`, GRANT to authenticated |
| 26 | `delete_cloud_expense_category(p_shop_id, p_category_id)` | Delete category | G | RPC | `expenses.delete`, GRANT to authenticated |
| 27 | `create_cloud_expense(p_shop_id, p_date, p_description, p_amount, p_category_id)` | Create expense | G | RPC | `expenses.create`, GRANT to authenticated |
| 28 | `update_cloud_expense(p_shop_id, p_expense_id, ..., p_expected_version)` | Update expense (version-aware) | G/H | RPC | `expenses.create`, GRANT to authenticated |
| 29 | `delete_cloud_expense(p_shop_id, p_expense_id)` | Delete expense | G | RPC | `expenses.delete`, GRANT to authenticated |
| 30 | `create_cloud_sale_with_stock(p_shop_id, p_barcode, p_quantity, p_sale_price, p_date, p_invoice_id)` | Atomic sale + stock | G | RPC | `sales.create`, GRANT to authenticated |
| 31 | `delete_cloud_sale_with_revert(p_shop_id, p_sale_id)` | Revert sale + stock | G | RPC | `sales.delete`, GRANT to authenticated |
| 32 | `create_cloud_return_with_stock(p_shop_id, p_barcode, p_quantity, p_sale_price, p_date)` | Atomic return + stock | G | RPC | `returns.create`, GRANT to authenticated |
| 33 | `delete_cloud_return_with_revert(p_shop_id, p_return_id)` | Revert return + stock | G | RPC | `returns.delete`, GRANT to authenticated |
| 34 | `create_cloud_invoice_with_items(p_shop_id, p_customer_name, p_payment_method, p_date, p_sale_items, p_customer_id)` | Invoice + items | G | RPC | `sales.create`, GRANT to authenticated |
| 35 | `save_cloud_inventory_count(p_shop_id, p_product_id, p_actual_quantity, p_notes)` | Stocktake + adjust | G | RPC | `stocktake.view`, GRANT to authenticated |
| 36 | `get_cloud_shop_settings(p_shop_id)` | Get settings | G | RPC | `admin.settings.access`, GRANT to authenticated |
| 37 | `update_cloud_shop_setting(p_shop_id, p_key, p_value)` | Update setting | G | RPC | `admin.settings.access`, GRANT to authenticated |
| 38 | `sync_upsert_entity(p_shop_id, p_entity_type, p_entity_id, p_payload, p_idempotency_key, p_expected_version)` | Idempotent sync upsert | H | RPC | JWT + perm, GRANT to authenticated |
| 39 | `migration_upsert_chunk(p_batch_id, p_shop_id, p_local_table, p_rows)` | Legacy migration chunk ingest | I | **Migration-Only** | `admin.settings.access`, GRANT to authenticated |
| 40 | `migration_post_pass_links(p_batch_id, p_shop_id, p_links)` | Link invoices↔sales post-pass | I | **Migration-Only** | `admin.settings.access`, GRANT to authenticated |
| 41 | `migration_fetch_ledger(p_batch_id, p_shop_id)` | Fetch migration ledger | I | **Migration-Only** | `admin.settings.access`, GRANT to authenticated |
| 42 | `migration_reconcile_batch(p_batch_id, p_shop_id)` | Reconcile batch financials | I | **Migration-Only** | `admin.settings.access`, GRANT to authenticated |
| 43 | `phase_m_idempotency_lookup(p_idempotency_key)` | Lookup prior idempotent result | M | **Internal Helper** | **NOT GRANTED** |
| 44 | `phase_m_idempotency_record(p_shop_id, p_entity_type, p_entity_id, p_operation, p_idempotency_key, p_status, p_details)` | Record idempotent operation | M | **Internal Helper** | **NOT GRANTED** |
| 45 | `phase_m_oversell_guard(p_available, p_requested, p_allow_oversell)` | Oversell predicate (SQL IMMUTABLE) | M | **Internal Helper** | **NOT GRANTED** |
| 46 | `create_cloud_sale_with_stock_v2(p_shop_id, p_barcode, p_quantity, p_sale_price, p_date, p_invoice_id, p_idempotency_key, p_allow_oversell)` | Idempotent sale with oversell seam | M | RPC | `sales.create`, GRANT to authenticated |
| 47 | `delete_cloud_sale_with_revert_v2(p_shop_id, p_sale_id, p_idempotency_key)` | Idempotent revert sale | M | RPC | `sales.delete`, GRANT to authenticated |
| 48 | `create_cloud_return_with_stock_v2(p_shop_id, p_barcode, p_quantity, p_sale_price, p_date, p_idempotency_key)` | Idempotent return | M | RPC | `returns.create`, GRANT to authenticated |
| 49 | `delete_cloud_return_with_revert_v2(p_shop_id, p_return_id, p_idempotency_key)` | Idempotent revert return | M | RPC | `returns.delete`, GRANT to authenticated |
| 50 | `save_cloud_inventory_count_v2(p_shop_id, p_product_id, p_actual_quantity, p_notes, p_observed_at, p_idempotency_key)` | Idempotent count + observed_at | M | RPC | `stocktake.view`, GRANT to authenticated |
| 51 | `create_cloud_invoice_with_items_v2(p_shop_id, p_customer_name, p_payment_method, p_date, p_sale_items, p_customer_id, p_idempotency_key, p_allow_oversell)` | Idempotent invoice | M | RPC | `sales.create`, GRANT to authenticated |
| 52 | `resolve_sync_conflict(p_shop_id, p_idempotency_key, p_resolution_method, p_resolution_note)` | Owner conflict resolution | M | RPC | `admin.settings.access`, GRANT to authenticated |

**All 52 functions:** `SECURITY DEFINER`, `SET search_path = public`, execute as `supabase_admin` (bypass RLS).
**Category Legend:** RPC = client-callable via `authenticated` role grant; Internal Helper = not granted, used by other SECURITY DEFINER functions; Migration-Only = one-shot legacy migration RPCs.
**Replacement Note:** Functions 20, 23, 28 (`update_cloud_product`, `update_cloud_customer`, `update_cloud_expense`) are defined in Migration 25 (Phase G) and **replaced** in Migration 26 (Phase H) with version-aware signatures. The final identities are the Phase H versions.

### Edge Functions (1)

| Function | File | Purpose |
|----------|------|---------|
| `invite-employee` | `supabase/functions/invite-employee/index.ts` | Owner invites employee; creates auth user + membership + invitation record |

### Seeds

- 3 system roles: `owner` (18 perms), `employee` (11 perms), `salesOnly` (2 perms)
- Seeded via `supabase/seed.sql` — runs once per project

### Storage

- Enabled in `config.toml` (50MiB limit)
- No buckets defined in migrations — future work if needed

### Environment Variables Required

| Variable | Used By | Sensitivity |
|----------|---------|-------------|
| `SUPABASE_URL` | Client config (dart-define) | Public |
| `SUPABASE_ANON_KEY` | Client config (dart-define) | Public |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function `invite-employee` | **SECRET — NEVER IN CLIENT** |
| Database credentials | Supabase managed | Managed by Supabase |

---

## 7.4 Migration Deployment Order

**Authoritative count: 17 migrations** (derived from `supabase/migrations/*.sql`)

| Order | File | Phase | Key Operations |
|-------|------|-------|----------------|
| 1 | `20260820000000_create_shops.sql` | C | `shops` table, indexes |
| 2 | `20260820000001_create_shop_members.sql` | C | `shop_members` table, indexes, FK → shops |
| 3 | `20260820000002_create_roles.sql` | C | `roles` table, FK → shops |
| 4 | `20260820000003_create_role_permissions_cloud.sql` | C | `role_permissions_cloud`, FK → roles |
| 5 | `20260820000004_create_devices.sql` | C | `devices` table, FK → shops |
| 6 | `20260820000005_create_licenses.sql` | C | `licenses` table, FK → shops |
| 7 | `20260820000006_create_activations.sql` | C | `activations` table, FK → licenses, devices |
| 8 | `20260820000010_rls_policies.sql` | C | Enable RLS on 7 core tables, 7 SELECT policies |
| 9 | `20260820000020_database_functions.sql` | C | 5 RPCs: create_shop_with_owner, get_user_shops, verify_shop_membership, start_trial, verify_trial_status |
| 10 | `20260820000021_add_invitations.sql` | D | `invitations` table, RLS (owner-only SELECT) |
| 11 | `20260820000022_add_accept_invitation.sql` | D | `accept_invitation()` RPC |
| 12 | `20260820000023_phase_e_licensing_enhancements.sql` | E | ALTER licenses (updated_at, max_devices, revoked_at, metadata), ALTER activations (CHECK), 7 licensing/device RPCs |
| 13 | `20260820000024_phase_f_rbac_permission_sync.sql` | F | `shop_permission_overrides`, `permission_audit_log`, 11 RPCs, GRANTs |
| 14 | `20260820000025_phase_g_cloud_data_foundation.sql` | G | 9 cloud tables, indexes, RLS (9 policies), 19 CRUD/atomic RPCs, REVOKE direct table access |
| 15 | `20260820000026_phase_h_sync_core.sql` | H | ADD server_version to 9 cloud tables, `sync_log` table + RLS, UPDATE 3 CRUD RPCs for version-awareness, `sync_upsert_entity()` |
| 16 | `20260820000027_phase_i_legacy_migration.sql` | I | `cloud_migration_ledger` table + RLS, 4 migration RPCs |
| 17 | `20260820000028_phase_m_inventory_conflict_hardening.sql` | M | ALTER cloud_inventory_count (observed_at, applied), ALTER sync_log (resolved_*), 2 idempotency helpers, 6 _v2 stock RPCs, `resolve_sync_conflict()`, GRANTs |

### Prerequisites

- Clean PostgreSQL 15+ database (Supabase default)
- `pgcrypto` extension for `gen_random_uuid()` (enabled by default)
- `auth` schema present (Supabase managed)
- No pre-existing tables with conflicting names

### Failure Handling

| Failure Point | Action |
|---------------|--------|
| Migration 1-7 (DDL) | Stop. Investigate. Do not proceed. |
| Migration 8 (RLS) | Stop. RLS is security-critical. |
| Migration 9 (RPCs) | Stop. Functions required by later phases. |
| Migration 10-11 | Can continue if D complete; invitations are additive. |
| Migration 12 (Licensing) | Stop. Licensing is revenue-critical. |
| Migration 13 (RBAC) | Stop. Permissions are authorization-critical. |
| Migration 14 (Cloud Data) | Stop. Business data foundation. |
| Migration 15 (Sync) | Stop. Sync infrastructure. |
| Migration 16 (Migration) | Can continue; legacy migration is one-shot. |
| Migration 17 (Phase M) | Stop. Inventory conflict hardening is data-integrity-critical. |

### Verification After Each Migration

```sql
-- After each migration, verify:
SELECT * FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
SELECT * FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;
SELECT proname FROM pg_proc WHERE pronamespace = 'public'::regnamespace ORDER BY proname;
```

---

## 7.5 Environment Separation

| Environment | Purpose | Supabase Project | Validation Required |
|-------------|---------|------------------|---------------------|
| **LOCAL** | Developer iteration | Local Supabase CLI (`supabase start`) | All migrations apply; unit/contract tests pass |
| **STAGING** | Pre-production validation | Dedicated staging Supabase project | **ALL GATES 0-10 MUST PASS** before production |
| **PRODUCTION** | Live customer data | Dedicated production Supabase project | Gates 0-12 pass; authorized deployment only |

**MANDATORY: STAGING BEFORE PRODUCTION**

No production deployment without:
1. Staging project created and configured
2. All 17 migrations applied to staging
3. Gates 0-10 passing on staging with documented evidence
4. Explicit authorization to proceed to production

**No destructive production experimentation.** Production is for live customer traffic only.

---

## 7.6 Secrets and Key Management

### Secret Categories

| Secret | Where It Exists | Where It MUST NOT Exist |
|--------|-----------------|-------------------------|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function env (`invite-employee`), CI/CD secrets, deployment scripts | **Flutter client**, `pubspec.yaml`, any committed file, localSupabase config |
| `SUPABASE_DB_PASSWORD` | Supabase dashboard (managed), CI/CD for direct psql if needed | Client, repo, logs |
| `SUPABASE_JWT_SECRET` | Supabase managed (Auth) | Never exposed |
| `SUPABASE_URL` | Client (dart-define), CI/CD, deployment scripts | Safe to be public |
| `SUPABASE_ANON_KEY` | Client (dart-define), CI/CD, deployment scripts | Safe to be public |

### Build-Time vs Runtime

| Variable | Build-Time (dart-define) | Runtime (Supabase project settings) |
|----------|--------------------------|-------------------------------------|
| `SUPABASE_URL` | ✅ Required | ✅ Project URL |
| `SUPABASE_ANON_KEY` | ✅ Required | ✅ Project anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | ❌ NEVER | ✅ Edge Function env only |

### Critical Invariant

> **SERVICE_ROLE / PRIVATE SERVER KEYS MUST NEVER BE SHIPPED IN THE FLUTTER CLIENT**

The Flutter client receives only:
- `SUPABASE_URL` (public)
- `SUPABASE_ANON_KEY` (public, anon role)

All server-side mutations use `service_role` via:
- Edge Functions (`invite-employee`)
- SECURITY DEFINER RPCs (execute as `supabase_admin`)

---

## 7.7 RLS Verification

### Tenant-Scoped Tables Requiring RLS Verification (21 tables)

| Table | RLS Policy | Isolation Key |
|-------|------------|---------------|
| `shops` | `shop_isolation` | `shop_id` via `shop_members` |
| `shop_members` | `shop_member_isolation` | `shop_id` via self-join |
| `roles` | `shop_roles_isolation` | `shop_id` via `shop_members` |
| `role_permissions_cloud` | `shop_role_permissions_isolation` | `shop_id` via `roles` → `shop_members` |
| `devices` | `shop_devices_isolation` | `shop_id` via `shop_members` |
| `licenses` | `shop_licenses_isolation` | `shop_id` via `shop_members` |
| `activations` | `shop_activations_isolation` | `shop_id` via `licenses` → `shop_members` |
| `invitations` | `shop_owner_invitations_select` | `shop_id` + `role = 'owner'` via `shop_members` |
| `shop_permission_overrides` | `shop_overrides_isolation` | `shop_id` via `shop_members` |
| `permission_audit_log` | `shop_audit_isolation` | `shop_id` via `shop_members` |
| `cloud_products` | `shop_isolation_products` | `shop_id` via `shop_members` |
| `cloud_customers` | `shop_isolation_customers` | `shop_id` via `shop_members` |
| `cloud_sales` | `shop_isolation_sales` | `shop_id` via `shop_members` |
| `cloud_returns` | `shop_isolation_returns` | `shop_id` via `shop_members` |
| `cloud_expenses` | `shop_isolation_expenses` | `shop_id` via `shop_members` |
| `cloud_expense_categories` | `shop_isolation_expense_categories` | `shop_id` via `shop_members` |
| `cloud_invoices` | `shop_isolation_invoices` | `shop_id` via `shop_members` |
| `cloud_inventory_count` | `shop_isolation_inventory_count` | `shop_id` via `shop_members` |
| `cloud_shop_settings` | `shop_isolation_shop_settings` | `shop_id` via `shop_members` |
| `sync_log` | `shop_isolation_sync_log` | `shop_id` via `shop_members` |
| `cloud_migration_ledger` | `shop_isolation_cloud_migration_ledger` | `shop_id` via `shop_members` |

**Total: 21 tables with RLS enabled** (7 core + 1 invitations + 2 RBAC + 9 cloud data + 1 sync + 1 migration)

### Verification Plan

#### Positive Tests (Should Succeed)

For each table, as an authenticated user with ACTIVE membership in SHOP_A:
```sql
-- Should return rows for SHOP_A only
SELECT * FROM <table> WHERE shop_id = 'SHOP_A_UUID';
```

#### Negative Tests (Should Return Empty / Deny)

For each table, as an authenticated user with ACTIVE membership in SHOP_A:
```sql
-- Should return ZERO rows for SHOP_B
SELECT * FROM <table> WHERE shop_id = 'SHOP_B_UUID';

-- Direct insert/update/delete should fail (no client policies)
INSERT INTO <table> ...; -- ERROR: permission denied
```

#### Cross-Tenant Isolation Test Matrix

| Actor | Target Table | Expected Result |
|-------|--------------|-----------------|
| User_A (member of SHOP_A) | `shops` | Sees SHOP_A only |
| User_A (member of SHOP_A) | `shop_members` | Sees SHOP_A memberships only |
| User_A (member of SHOP_A) | `cloud_products` | Sees SHOP_A products only |
| User_A (member of SHOP_A) | `cloud_sales` | Sees SHOP_A sales only |
| User_A (member of SHOP_A) | `licenses` | Sees SHOP_A license only |
| User_A (member of SHOP_A) | `activations` | Sees SHOP_A activations only |
| User_A (member of SHOP_A) | `invitations` | Sees SHOP_A invitations (if owner) |
| User_A (member of SHOP_A) | `sync_log` | Sees SHOP_A sync log only |
| User_B (member of SHOP_B) | Any SHOP_A table | Zero rows / permission denied |

---

## 7.8 Authentication and Shop Bootstrap Verification

### Complete Flow

| Step | Action | RPC / Auth | Expected Evidence |
|------|--------|------------|-------------------|
| 1 | Owner signs up | `supabase.auth.signUp(email, password)` | Auth user created, session returned |
| 2 | Owner signs in | `supabase.auth.signInWithPassword(email, password)` | Valid JWT session |
| 3 | Owner creates shop | `create_shop_with_owner(p_name)` | Returns `shop_id`; shop row exists; owner membership ACTIVE |
| 4 | System roles seeded | (triggered by RPC) | 3 roles in `roles` with `is_system=true`; 31 permission assignments in `role_permissions_cloud` |
| 5 | Owner invites employee | Edge Function `invite-employee` (service_role) | Auth user created; membership INVITED; invitation PENDING |
| 6 | Employee accepts invitation | `accept_invitation(p_shop_id, p_user_id)` | Membership → ACTIVE; joined_at set; invitation → ACCEPTED |
| 7 | Employee signs in | `supabase.auth.signInWithPassword(email, password)` | Valid JWT session |
| 8 | Membership resolution | `get_user_shops()` | Returns shop with correct role/status |
| 9 | Role/permission resolution | `sync_user_permissions(p_shop_id)` | Returns permissions matching role + overrides |

### Verification Checklist

- [ ] Owner signup creates auth user
- [ ] Owner login returns valid session
- [ ] `create_shop_with_owner` creates shop + owner membership + system roles + permissions
- [ ] `get_user_shops` returns correct shop list
- [ ] `verify_shop_membership` returns true for member, false for non-member
- [ ] Edge Function `invite-employee` creates user + membership(INVITED) + invitation(PENDING)
- [ ] `accept_invitation` activates membership + updates invitation
- [ ] Employee login works
- [ ] Employee sees only invited shop in `get_user_shops`
- [ ] `sync_user_permissions` returns correct permission set for role

---

## 7.9 Licensing and 14-Day Trial

### Architecture

**Server-controlled.** Client never determines trial validity.

| Function | Purpose | Authority |
|----------|---------|-----------|
| `start_trial(p_shop_id)` | Owner initiates 14-day trial | Owner-only, server time |
| `verify_trial_status(p_shop_id)` | Check trial status | Server time |
| `verify_license_entitlement(p_shop_id)` | Full entitlement (trial + license + devices) | Server time |

### Validation Scenarios

| Scenario | Setup | Expected Result |
|----------|-------|-----------------|
| Trial creation | Owner calls `start_trial` | License status = `TRIAL`, `trial_expires_at` = now() + 14 days |
| Trial active | Within 14 days | `trial_active = true`, `days_remaining > 0` |
| Trial expired | After 14 days | `trial_active = false`, `days_remaining = 0`, status = `EXPIRED` |
| Valid license | License status = `ACTIVE`/`PERPETUAL` | `has_license = true`, `trial_active = false` |
| Expired license | License status = `EXPIRED` | `has_license = true`, `license_status = EXPIRED` |
| Revoked license | License status = `SUSPENDED`/`REVOKED` | `has_license = true`, `license_status = SUSPENDED` |
| No license | No license row | `has_license = false` |
| Clock manipulation resistance | Server time used exclusively | Client clock changes have NO effect |

### Device Activation Limits

- `licenses.max_devices` (default 3, set at trial start)
- `verify_license_entitlement` returns `current_devices`, `device_slot_available`
- `activate_device` enforces limit atomically
- Owner can `deactivate_device` to free slot

---

## 7.10 Device Activation Lifecycle

### Flow

| Step | Action | RPC | Verification |
|------|--------|-----|--------------|
| 1 | App starts, generates `installation_id` (local UUID) | — | Persisted locally |
| 2 | User logs in, has shop membership | — | `verify_shop_membership` |
| 3 | Register device | `register_device(p_shop_id, p_installation_id, p_platform, p_device_name)` | Device row created/updated, status=ACTIVE |
| 4 | Activate device | `activate_device(p_shop_id, p_installation_id)` | Activation row created, status=ACTIVE, `devices_remaining` decremented |
| 5 | Periodic verification | (background) | `last_verified_at` updated |
| 6 | Owner revokes | `deactivate_device(p_activation_id)` | Activation status=REVOKED, slot freed |
| 7 | Re-login / re-activate | `activate_device` again | Idempotent: returns existing activation if active |

### Limits

- Per-license `max_devices` (default 3)
- Enforced in `activate_device` with row-level lock
- Idempotent: re-activating same device returns existing activation

---

## 7.11 RBAC / Permission Sync

### Architecture

| Layer | Authority |
|-------|-----------|
| **Server** | `require_shop_permission` — asserts on every mutating RPC |
| **Server** | `check_effective_permission` — resolves base + overrides |
| **Server** | `sync_user_permissions` — returns full payload for client cache |
| **Client** | `PermissionSyncService` — caches snapshot, updates `PermissionResolver` |
| **Client** | `PermissionResolver` — UI gating only (convenience) |
| **Client** | `DatabaseHelper._requirePermission` — local enforcement (defense in depth) |

### Permission IDs (18 canonical)

```
dashboard.view
inventory.view, inventory.edit, inventory.delete
sales.view, sales.create, sales.history.view, sales.delete
returns.view, returns.create, returns.delete
expenses.view, expenses.create, expenses.delete
stocktake.view
admin.users.manage, admin.permissions.manage, admin.settings.access
```

### Role Defaults (from seed.sql)

| Role | Permissions |
|------|-------------|
| `owner` | All 18 |
| `employee` | 11 (all except `.delete` and `admin.*`) |
| `salesOnly` | 2 (`sales.view`, `sales.create`) |

### Overrides (Phase F)

- Owner can `ALLOW`/`DENY` specific permissions for `employee`/`salesOnly`
- Owner-exclusive permissions (`admin.users.manage`, `admin.permissions.manage`) CANNOT be granted via override
- Audit trail in `permission_audit_log`

### Verification

| Test | Expected |
|------|----------|
| Owner gets all 18 permissions | ✅ |
| Employee gets 11 base permissions | ✅ |
| SalesOnly gets 2 base permissions | ✅ |
| Owner override ALLOW on `inventory.delete` for employee | Employee gets it |
| Owner override DENY on `sales.create` for employee | Employee loses it |
| Override granting `admin.users.manage` to employee | REJECTED by RPC |
| `require_shop_permission` on write perm without license | REJECTED (`license_required`) |
| `require_shop_permission` on view perm without license | ALLOWED (view bypasses license) |

---

## 7.12 Cloud Data Foundation

### Production Cloud Tables (9 business tables)

| Table | Natural Key | Soft Delete | Sync Column |
|-------|-------------|-------------|-------------|
| `cloud_products` | `(shop_id, barcode)` | `deleted_at` | `server_version` |
| `cloud_customers` | `(shop_id, name, phone)` | `deleted_at` | `server_version` |
| `cloud_sales` | None (append-only history) | `deleted_at` | `server_version` |
| `cloud_returns` | None (append-only history) | `deleted_at` | `server_version` |
| `cloud_expenses` | None (append-only history) | `deleted_at` | `server_version` |
| `cloud_expense_categories` | `(shop_id, name)` | `deleted_at` | `server_version` |
| `cloud_invoices` | `(shop_id, invoice_number)` | `deleted_at` | `server_version` |
| `cloud_inventory_count` | None (observations) | `deleted_at` | `server_version` |
| `cloud_shop_settings` | `(shop_id, setting_key)` | N/A (no soft delete) | `server_version` |

### Constraints Verified

- All tables have `shop_id` FK → `shops(id)` CASCADE DELETE
- All tables have `shop_id` index + `updated_at`/`created_at` indexes for sync
- All tables have RLS SELECT-only policies
- Direct table access REVOKED from `authenticated` role (Phase G)
- All mutations via SECURITY DEFINER RPCs with permission checks

---

## 7.13 Sync Deployment Verification

### Offline-First Architecture

```
Local SQLite mutation
        ↓
Outbox/queue entry (sync_queue) with idempotency_key
        ↓
Cloud push via RPC (sync_upsert_entity or _v2 RPCs)
        ↓
Server persistence (atomic: business row + sync_log)
        ↓
Pull / incremental sync (version-aware CRUD)
        ↓
Local convergence (apply server_version, resolve conflicts)
```

### Verification Checklist

| Component | Code Exists | Wired at Runtime | Evidence Required |
|-----------|-------------|------------------|-------------------|
| Local SQLite mutation | ✅ | ✅ | Local DB writes |
| Outbox/queue creation | ✅ | ✅ | `sync_queue` entries with idempotency_key |
| Cloud push (legacy RPCs) | ✅ | ✅ | `create_cloud_sale_with_stock` etc. |
| Cloud push (_v2 idempotent) | ✅ | ✅ | `create_cloud_sale_with_stock_v2` returns `{id, current_quantity, server_version}` |
| Server persistence | ✅ | ✅ | Business row + `sync_log` in same transaction |
| Pull / incremental sync | ✅ | ⚠️ PARTIAL | Version-aware CRUD RPCs exist; client pull logic needs verification |
| Local convergence | ✅ | ⚠️ PARTIAL | `server_version` applied; conflict detection via `sync_upsert_entity` |
| Idempotency | ✅ | ✅ | `sync_log.idempotency_key` UNIQUE; `_v2` RPCs return IDEMPOTENT |
| Retry | ✅ | ✅ | Client retries with same idempotency_key |
| Soft delete | ✅ | ✅ | `deleted_at` columns; RPCs filter `deleted_at IS NULL` |
| Conflict behavior | ✅ | ⚠️ PARTIAL | `sync_upsert_entity` returns CONFLICT; `resolve_sync_conflict` RPC exists |

**Critical distinction:** Phase H sync core (version-aware CRUD, `sync_upsert_entity`, `sync_log`) is DEPLOYED. Phase M _v2 idempotent RPCs are DEPLOYED. Client-side pull/convergence logic exists in code but **runtime integration must be verified at deployment time**.

---

## 7.14 Cross-Tenant Isolation Security Test

**MANDATORY — Must be tested against real production-equivalent Supabase authorization**

### Test Setup

```sql
-- Create two shops
SHOP_A: owner = User_A
SHOP_B: owner = User_B

-- Create members
User_A: ACTIVE owner of SHOP_A
User_B: ACTIVE owner of SHOP_B
Employee_A: ACTIVE employee of SHOP_A
Employee_B: ACTIVE employee of SHOP_B
```

### Test Matrix

| Actor | Operation | Target | Expected |
|-------|-----------|--------|----------|
| User_A (SHOP_A owner) | SELECT | SHOP_A `cloud_products` | ✅ Rows returned |
| User_A (SHOP_A owner) | SELECT | SHOP_B `cloud_products` | ❌ Zero rows |
| User_A (SHOP_A owner) | INSERT | SHOP_B `cloud_products` | ❌ Permission denied (RLS) |
| User_A (SHOP_A owner) | RPC `create_cloud_product` | SHOP_B | ❌ `require_shop_permission` → `not_member` |
| Employee_A (SHOP_A) | SELECT | SHOP_A `cloud_sales` | ✅ Rows returned |
| Employee_A (SHOP_A) | SELECT | SHOP_B `cloud_sales` | ❌ Zero rows |
| Employee_A (SHOP_A) | RPC `create_cloud_sale_with_stock` | SHOP_B | ❌ `not_member` |
| User_A (SHOP_A owner) | RPC `start_trial` | SHOP_B | ❌ `Only the shop owner can start a trial` |
| User_A (SHOP_A owner) | RPC `activate_device` | SHOP_B device | ❌ `Not a member of this shop` |
| User_A (SHOP_A owner) | RPC `sync_user_permissions` | SHOP_B | ❌ `not_member` |
| User_A (SHOP_A owner) | Edge Function `invite-employee` | SHOP_B | ❌ `Only the shop owner can invite employees` |

### Execution Requirements

- Run against **staging Supabase project** with real Auth users
- Use actual JWT tokens from `signInWithPassword`
- Verify RLS + RPC authorization + Edge Function authorization
- Document: timestamp, user IDs, shop IDs, SQL/RPC calls, results

---

## 7.15 Backup and Rollback Strategy

### Pre-Deployment (Staging & Production)

| Artifact | Method | Retention |
|----------|--------|-----------|
| Database schema dump | `pg_dump --schema-only` | Until next successful deployment |
| Database data dump | `pg_dump --data-only` | Until next successful deployment |
| Full backup | Supabase dashboard → Database → Backups | 7 days minimum |
| Migration history | `SELECT * FROM supabase_migrations.schema_migrations` | Permanent |

### Rollback Decision Process

| Trigger | Decision |
|---------|----------|
| Migration fails (syntax, constraint, FK) | **AUTO-STOP** — Do not proceed. Fix migration, re-deploy. |
| RLS policy missing/incorrect | **STOP** — Security regression. Fix before continuing. |
| Data loss detected | **ROLLBACK** — Restore from pre-deployment backup. |
| Performance regression > 50% | **ROLLBACK** — Restore, investigate. |
| Auth/membership broken | **ROLLBACK** — Restore, investigate. |

### Restore Procedure

```bash
# 1. Disable client access (maintenance mode)
# 2. Restore from Supabase backup (point-in-time recovery)
# 3. Verify schema_migrations table matches expected state
# 4. Run verification queries (RLS, RPCs, data integrity)
# 5. Re-enable client access
```

### Responsibility Boundary

| Phase | Responsible |
|-------|-------------|
| Migration authoring | Development team |
| Staging deployment & verification | Deployment engineer |
| Production deployment authorization | Product owner + Tech lead |
| Production deployment execution | Deployment engineer |
| Post-deployment verification | Deployment engineer + QA |
| Rollback execution | Deployment engineer |
| Rollback authorization | Tech lead |

**Never assume arbitrary SQL migrations are safely reversible.** Most migrations are ADDITIVE ONLY but some ALTER columns, add constraints, or replace functions. Rollback = restore from backup.

---

## 7.16 Observability and Deployment Evidence

### Required Evidence Per Deployment

| Gate | Evidence | Format |
|------|----------|--------|
| GATE 3 Migration Deployment | `supabase db push` output, migration timing | Logs + timestamps |
| GATE 4 Schema Verification | `pg_tables`, `pg_policies`, `pg_proc` queries | Markdown tables |
| GATE 5 RLS/Tenant Isolation | Cross-tenant test matrix results | Pass/Fail table + timestamps |
| GATE 6 Auth/Membership | Flow verification checklist | Signed checklist |
| GATE 7 Licensing/Trial | `verify_license_entitlement` outputs for each scenario | JSON responses |
| GATE 8 Device Activation | Device register/activate/revoke flow | JSON responses |
| GATE 9 RBAC | Permission sync + override tests | JSON responses |
| GATE 10 Sync | Idempotency key replay, version conflict, convergence | Logs + JSON |
| GATE 12 Production Smoke | End-to-end: login → shop → sale → sync → verify | Sanitized screenshots/logs |

### Sanitization Rules

- **NEVER** include: JWT tokens, service_role keys, database passwords, real emails, PII
- **REPLACE** with: `[REDACTED]`, `user_XXX`, `shop_XXX`
- **INCLUDE**: Structure, status codes, timing, row counts, schema names

---

## 7.17 Deployment Gates

| Gate | Name | Prerequisites | Actions | Evidence | PASS Criteria | BLOCKED/FAIL Criteria |
|------|------|---------------|---------|----------|---------------|------------------------|
| **GATE 0** | Repository/Baseline Integrity | Git clean, HEAD at baseline, tags present | `git status`, `git log`, tag verification | Git output | Clean working tree, correct HEAD, ancestry verified | Any uncommitted changes, wrong HEAD, missing tags |
| **GATE 1** | Staging Project Ready | Supabase project created, CLI linked | `supabase link`, `supabase status` | Project ref, URL | Project accessible, CLI authenticated | Link fails, project not found |
| **GATE 2** | Secrets/Config Ready | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SERVICE_ROLE_KEY` in CI/CD | Set in Supabase dashboard / CI secrets | Confirmation (sanitized) | All 3 present, service_role NOT in client build | Missing secret, service_role in client |
| **GATE 3** | Migration Deployment | GATE 0-2 pass | `supabase db push` (or `migration up`) | Full migration log | All 17 migrations applied, 0 errors | Any migration error |
| **GATE 4** | Schema Verification | GATE 3 pass | Query tables, policies, functions | Schema inventory | 21 tables, 21 RLS policies, 44 client-callable RPCs | Missing table/policy/function |
| **GATE 5** | RLS / Tenant Isolation | GATE 4 pass | Cross-tenant test matrix (7.14) | Test matrix results | All 10 negative tests return 0 rows / deny | Any cross-tenant leak |
| **GATE 6** | Auth / Membership | GATE 4 pass | Full flow (7.8) | Checklist + JSON | All 9 steps succeed | Any step fails |
| **GATE 7** | Licensing / Trial | GATE 4 pass | 7 scenarios (7.9) | RPC outputs | All scenarios match expected | Trial/license logic incorrect |
| **GATE 8** | Device Activation | GATE 4,7 pass | Full lifecycle (7.10) | RPC outputs | Register→activate→revoke→re-activate works | Limit bypass, idempotency failure |
| **GATE 9** | RBAC | GATE 4,6 pass | Permission matrix (7.11) | RPC outputs | All role/override combos correct | Owner-exclusive granted, license bypass |
| **GATE 10** | Offline/Cloud Sync | GATE 4 pass | Idempotency, version, conflict (7.13) | Logs + JSON | Same key → IDEMPOTENT; version mismatch → CONFLICT | Data loss, double-apply, silent failure |
| **GATE 11** | Production Deployment Authorization | GATE 0-10 pass on STAGING | Explicit approval | Signed authorization | Written approval from PO + Tech Lead | No approval, staging gates failed |
| **GATE 12** | Production Smoke Verification | GATE 11 pass, prod deployed | End-to-end flow on production | Sanitized logs | Login → shop → sale → sync → verify | Any production error |

---

## 7.18 Production Deployment Sequence

```text
SESSION 1: SUPABASE_STAGING_DEPLOYMENT
  1. Create staging Supabase project
  2. Link local CLI: supabase link --project-ref <staging-ref>
  3. Set secrets: SERVICE_ROLE_KEY in Edge Function env
  4. Deploy migrations: supabase db push
  5. Deploy Edge Function: supabase functions deploy invite-employee
  6. Run seed.sql (if fresh project)
  7. Verify GATE 0-4

SESSION 2: SUPABASE_STAGING_VERIFICATION
  1. Run cross-tenant isolation tests (GATE 5)
  2. Run auth/membership flow (GATE 6)
  3. Run licensing/trial tests (GATE 7)
  4. Run device activation tests (GATE 8)
  5. Run RBAC/permission tests (GATE 9)
  6. Run sync/integration tests (GATE 10)
  7. Document all evidence
  8. Obtain GATE 11 authorization

SESSION 3: SUPABASE_PRODUCTION_DEPLOYMENT
  1. Create production Supabase project
  2. Link CLI: supabase link --project-ref <prod-ref>
  3. Set production secrets (SERVICE_ROLE_KEY in Edge Function)
  4. Deploy migrations: supabase db push
  5. Deploy Edge Function: supabase functions deploy invite-employee
  6. Run seed.sql
  7. Verify GATE 0-4 on production

SESSION 4: SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION
  1. Run GATE 5-10 on production (read-only verification where possible)
  2. Run GATE 12 production smoke test
  3. Monitor for 24h: error rates, latency, RLS denials
  4. Document evidence
  5. Sign off
```

**Each session is independent.** This planning session ends after local commit.

---

## 7.19 Negative Scope

This deployment does NOT authorize:

- [ ] Unrelated feature work
- [ ] Broad refactoring
- [ ] UI redesign
- [ ] Phase O product feature work
- [ ] Silent schema redesign (all changes must be in migrations)
- [ ] Production deployment without passed staging gates
- [ ] Service-role key in Flutter client
- [ ] Destructive production testing
- [ ] Mutation of the sacred legacy remote (`origin`)
- [ ] Changes to `supabase/config.toml` (local dev only)
- [ ] Changes to existing migration files (immutable once deployed)
- [ ] Direct table access from client (all mutations via RPC)

---

## 7.20 Roll-Forward / Stop Conditions

| Condition | Action |
|-----------|--------|
| All staging gates pass, authorization obtained | **CONTINUE** → Production deployment |
| Any staging gate fails | **STOP** → Fix, re-verify staging |
| Production migration fails | **STOP** → Do not proceed. Rollback via backup. |
| Production GATE 5 (RLS) fails | **ROLL BACK** → Immediate restore from pre-deploy backup |
| Production GATE 12 smoke test fails | **ROLL BACK** → Restore, investigate |
| Data corruption detected | **ROLL BACK** → Restore, escalate |
| Security breach suspected | **STOP** → **ESCALATE** → Security team, revoke keys, audit |

---

## 7.21 Future Session Boundaries

| Session | Scope | Authorization Required |
|---------|-------|------------------------|
| `SUPABASE_STAGING_DEPLOYMENT` | Create staging project, deploy migrations + Edge Function, basic schema verification | Tech lead |
| `SUPABASE_STAGING_VERIFICATION` | Full gate verification (5-10), evidence collection | Tech lead + QA |
| `SUPABASE_PRODUCTION_DEPLOYMENT` | Create production project, deploy migrations + Edge Function | **PO + Tech lead (GATE 11)** |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION` | Production gates 5-10 + smoke test (GATE 12) | Tech lead + QA |

**This planning session creates the plan only. It does not execute any session above.**

---

# Appendix A: Migration File Checksums (for integrity verification)

```text
20260820000000_create_shops.sql                    [verify at deployment]
20260820000001_create_shop_members.sql             [verify at deployment]
20260820000002_create_roles.sql                    [verify at deployment]
20260820000003_create_role_permissions_cloud.sql   [verify at deployment]
20260820000004_create_devices.sql                  [verify at deployment]
20260820000005_create_licenses.sql                 [verify at deployment]
20260820000006_create_activations.sql              [verify at deployment]
20260820000010_rls_policies.sql                    [verify at deployment]
20260820000020_database_functions.sql              [verify at deployment]
20260820000021_add_invitations.sql                 [verify at deployment]
20260820000022_add_accept_invitation.sql           [verify at deployment]
20260820000023_phase_e_licensing_enhancements.sql  [verify at deployment]
20260820000024_phase_f_rbac_permission_sync.sql    [verify at deployment]
20260820000025_phase_g_cloud_data_foundation.sql   [verify at deployment]
20260820000026_phase_h_sync_core.sql               [verify at deployment]
20260820000027_phase_i_legacy_migration.sql        [verify at deployment]
20260820000028_phase_m_inventory_conflict_hardening.sql  [verify at deployment]
```

---

# Appendix B: Client Build Configuration

```bash
# Production build command (example)
flutter build apk \
  --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --release

# iOS
flutter build ios \
  --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --release

# Windows
flutter build windows \
  --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --release
```

**Never include `SUPABASE_SERVICE_ROLE_KEY` in any client build.**

---

# Appendix C: Supabase CLI Commands Reference

```bash
# Link to project
supabase link --project-ref <project-ref>

# Check status
supabase status

# Deploy migrations
supabase db push

# Deploy Edge Functions
supabase functions deploy invite-employee

# Set Edge Function secrets
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<key> --project-ref <ref>

# Generate types (for client)
supabase gen types typescript --project-id <ref> > types/supabase.ts

# Backup (via dashboard or pg_dump)
pg_dump -h <host> -U postgres -d postgres --schema-only > schema.sql
pg_dump -h <host> -U postgres -d postgres --data-only > data.sql
```

---

**END OF PLAN**

This plan is derived from repository reality as of commit `741b4236d4344e8fbd3f66c8c41af4595da15de7` (tag `supabase-production-deployment-planning-baseline-locked`). All counts, function signatures, table names, and architectural details are sourced from the actual migration files and client code. Items marked `REQUIRES DEPLOYMENT-TIME VERIFICATION` cannot be fully validated until executed against a live Supabase project.