# PHASE C: CLOUD BACKEND FOUNDATION PLAN

**Phase:** C - Cloud Backend Foundation
**Session Type:** PHASE_C_PLANNING
**Project:** I Tech Store Management Product
**Owner:** I Tech for Technology / I Tech للتكنولوجيا
**Baseline:** `453485ed1ee92032a78c6030c7203403f027570f` on `codex/i-tech-next-roadmap-freeze`
**Date:** 2026-08-20

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | C - Cloud Backend Foundation |
| Session Type | PHASE_C_PLANNING |
| Document Status | Planning artifact - not implemented |
| Baseline Commit | `453485ed1ee92032a78c6030c7203403f027570f` |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Predecessor Phase | B (Shop/Tenant Foundation) - COMPLETED |
| Successor Phase | D - Cloud Auth & Membership |
| Verified By | Phase B closure: 741/741 tests pass (4 pre-existing legacy failures) |

---

## 2. Purpose

Phase C establishes the cloud backend infrastructure that all subsequent phases depend on. It creates the Supabase PostgreSQL database with the 7 cloud schema tables designed in Phase B, configures multi-environment support, implements Row-Level Security (RLS) policies for tenant isolation, and prepares the server-side foundation for authentication, licensing, and sync.

Phase C is an **infrastructure-only phase**. It does not modify any Flutter/Dart code, local SQLite schema, or client application behavior. The Flutter app remains entirely local-only after Phase C.

---

## 3. Governing Baseline

```
REPOSITORY_ROOT    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH             = codex/i-tech-next-roadmap-freeze
HEAD               = 453485ed1ee92032a78c6030c7203403f027570f
REMOTE             = github (https://github.com/sabere342-ai/muaman.worktrees.git)
DIVERGENCE         = 0/0 (local in sync with github)
TEST_BASELINE      = 741 passed, 4 failed (pre-existing legacy failures in standalone_backup_restore_test.dart)
SCHEMA_VERSION     = 9 (post Phase B)
CLOUD_SCHEMA       = 0 tables (pre Phase C)
```

---

## 4. Governing Sources

| Document | Role | Relevance to Phase C |
|----------|------|---------------------|
| `PROJECT_MASTER_PLAN.md` | Master governing document | Section 13 defines Phase C; Section 8 target state; Section 9 architecture principles; Section 11 security principles |
| `PRODUCTIZATION_ARCHITECTURE_PLAN.md` | Detailed architecture | ADR-001 (Supabase selected); Section 4 multi-tenant model; Section 5 auth model; Section 6 authorization model; Section 16 security architecture; Section 17 DB evolution |
| `PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md` | Phase B closure | Section 8.1 cloud schema design (deployed in Phase C); Section 9.2 non-goals deferred to Phase C |
| `PRODUCTIZATION_MIGRATION_PLAN.md` | Migration strategy | Section 2 pre-migration requirements (cloud backend deployed) |
| `PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md` | Pre-A closure | Section 16 out-of-scope (Supabase → Phase C) |

### Governance Precedence

```
1. PROJECT_MASTER_PLAN.md            (owner-approved, supersedes all)
2. PRODUCTIZATION_ARCHITECTURE_PLAN.md (detailed design, linked from master)
3. PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md (closed predecessor, defines Phase C dependencies)
4. PRODUCTIZATION_MIGRATION_PLAN.md    (migration strategy, requires cloud backend)
5. PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md (closed predecessor)
```

### RLS Scope Governance Reconciliation

There is an ambiguity between governing documents regarding RLS policy placement:

| Source | Statement | Interpretation |
|--------|-----------|----------------|
| `PROJECT_MASTER_PLAN.md` §13 | Phase C = "Supabase setup, environment, RLS baseline" | RLS policies are Phase C |
| `PHASE_B_SHOP_TENANT_FOUNDATION_PLAN.md` §9.2 | "RLS policies → Phase C" | RLS policies are Phase C |
| `PRODUCTIZATION_ARCHITECTURE_PLAN.md` §6 | Permission mapping table shows "RLS" for server enforcement → Phase F | Client-side RLS integration is Phase F |
| `PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md` §16 | "RLS implementation → F" | RLS implementation is Phase F |

**Resolution:** Phase C implements **server-side RLS policies** on the Supabase PostgreSQL database (infrastructure). Phase F implements **client-side permission-to-RLS mapping** (application integration). These are distinct activities. The master plan's "RLS baseline" refers to the server-side policy definitions, not the client integration. This reconciliation is CONSISTENT with all governing documents.

---

## 5. Verified Existing State

### 5.1 Local Database Schema (v9, post Phase B)

| Table | Columns | shop_id? | cloud_uuid? |
|-------|---------|----------|-------------|
| products | 12 | YES (nullable) | YES (nullable) |
| sales | 11 | YES (nullable) | YES (nullable) |
| returns | 10 | YES (nullable) | YES (nullable) |
| expenses | 7 | YES (nullable) | YES (nullable) |
| expense_categories | 5 | YES (nullable) | YES (nullable) |
| inventory_count | 7 | YES (nullable) | YES (nullable) |
| invoices | 11 | YES (nullable) | YES (nullable) |
| import_batches | 19 | YES (nullable) | YES (nullable) |
| customers | 11 | YES (nullable) | YES (nullable) |
| users | 11 | YES (nullable) | YES (nullable) |
| role_permissions | 5 | YES (nullable) | YES (nullable) |
| app_settings | 4 | YES (nullable) | YES (nullable) |

### 5.2 Cloud Database (pre Phase C)

```
CLOUD_TABLES       = 0
CLOUD_RLS_POLICIES = 0
CLOUD_FUNCTIONS    = 0
SUPABASE_PROJECT   = NOT YET CREATED
```

### 5.3 Key Architectural Facts

| Fact | Value | Source |
|------|-------|--------|
| Cloud backend selected | Supabase | ADR-001 in architecture plan |
| Cloud schema designed | 7 tables | Phase B §8.1 |
| Local schema version | 9 | Phase B implementation |
| Auth model planned | Supabase Auth (email/password) | Architecture §5 |
| RLS strategy | Per-shop isolation via shop_id | Architecture §4, §6 |
| Environment plan | dev, test, staging, production | Architecture §16 |
| Secrets policy | No privileged secrets in Flutter binary | Architecture §16, Master §11 |

---

## 6. Problem Statement

The application currently operates as a single-device, local-only SQLite system. Phase B added `shop_id` and `cloud_uuid` columns to all 12 local tables, establishing the schema foundation for multi-tenancy. However, there is no cloud backend to:

1. **Store tenant identity** — no `shops` table exists anywhere
2. **Enforce tenant isolation** — no RLS policies exist
3. **Manage user authentication** — no Supabase Auth configuration
4. **Support multi-device operation** — no server-side device tracking
5. **Enable licensing** — no server-side license management
6. **Facilitate data migration** — no cloud database to migrate INTO

Phase C creates this missing cloud infrastructure so that Phase D (Cloud Auth & Membership) can begin connecting the Flutter client to the cloud.

---

## 7. Phase C Objectives

| # | Objective | Measurable Outcome |
|---|-----------|-------------------|
| O1 | Create Supabase project | Project exists with correct plan tier |
| O2 | Configure environments | Dev, test, staging, production environment configs exist |
| O3 | Deploy cloud schema | 7 tables created in Supabase PostgreSQL |
| O4 | Implement RLS policies | Shop-isolation RLS on all data tables |
| O5 | Create database functions | Server-side functions for auth, licensing, trial |
| O6 | Document environment config | .env.example with all required variables |
| O7 | Verify schema correctness | Migration tests pass against Supabase |

---

## 8. In-Scope Work

### 8.1 Supabase Project Setup

| # | Deliverable | Type | Verification |
|---|-------------|------|-------------|
| 1 | Supabase project creation (development) | Infrastructure | Project dashboard accessible |
| 2 | Supabase project creation (test) | Infrastructure | Project dashboard accessible |
| 3 | Environment configuration files | Config | .env.example complete |
| 4 | Supabase URL and anon key documentation | Config | Documented, no secrets committed |

### 8.2 Cloud Schema Deployment

| # | Table | Type | Source |
|---|-------|------|--------|
| 1 | `shops` | NEW | Phase B §8.1 |
| 2 | `shop_members` | NEW | Phase B §8.1 |
| 3 | `roles` | NEW | Phase B §8.1 |
| 4 | `role_permissions_cloud` | NEW | Phase B §8.1 |
| 5 | `devices` | NEW | Phase B §8.1 |
| 6 | `licenses` | NEW | Phase B §8.1 |
| 7 | `activations` | NEW | Phase B §8.1 |

### 8.3 RLS Policies

| # | Policy | Target Table | Scope |
|---|--------|-------------|-------|
| 1 | `shop_isolation` | `shops` | Owner can read own shop |
| 2 | `shop_member_isolation` | `shop_members` | Members see own shop membership |
| 3 | `shop_roles_isolation` | `roles` | Roles scoped to shop |
| 4 | `shop_role_permissions_isolation` | `role_permissions_cloud` | Permissions scoped to shop roles |
| 5 | `shop_devices_isolation` | `devices` | Devices scoped to shop |
| 6 | `shop_licenses_isolation` | `licenses` | Licenses scoped to shop |
| 7 | `shop_activations_isolation` | `activations` | Activations scoped to shop |

### 8.4 Database Functions

| # | Function | Purpose | Phase |
|---|----------|---------|-------|
| 1 | `create_shop_with_owner()` | Atomic shop + owner membership creation | D dependency |
| 2 | `get_user_shops()` | List shops for authenticated user | D dependency |
| 3 | `verify_shop_membership()` | Check user belongs to shop | F dependency |
| 4 | `start_trial()` | Server-controlled 14-day trial initiation | E dependency |
| 5 | `verify_trial_status()` | Check trial validity by server time | E dependency |

### 8.5 Configuration Files

| # | File | Purpose |
|---|------|---------|
| 1 | `.env.example` | Template for all environment variables |
| 2 | `supabase/migrations/` | Migration SQL files for version control |
| 3 | `supabase/config.ts` or equivalent | Supabase project configuration |

---

## 9. Explicit Non-Goals

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | Flutter client Supabase integration | Phase D | Phase C is infrastructure only |
| 2 | Supabase Auth configuration (email/password) | Phase D | Auth is Phase D scope |
| 3 | Owner account creation flow | Phase D | Auth flow is Phase D |
| 4 | Employee invitation flow | Phase D | Auth flow is Phase D |
| 5 | Client-side login/logout | Phase D | UI is Phase D |
| 6 | SessionState cloud context | Phase D | Client integration is Phase D |
| 7 | Permission-to-RLS client mapping | Phase F | Client integration is Phase F |
| 8 | Server-enforced permission checks | Phase F | Application integration is Phase F |
| 9 | Cloud licensing backend | Phase E | Licensing is Phase E |
| 10 | Trial management logic | Phase E | Licensing is Phase E |
| 11 | Device registration flow | Phase D | Auth flow is Phase D |
| 12 | Cloud data models (Dart) | Phase G | Client models are Phase G |
| 13 | Cloud CRUD operations | Phase G | Client operations are Phase G |
| 14 | Sync queue implementation | Phase H | Sync is Phase H |
| 15 | Offline pending-write queue | Phase H | Sync is Phase H |
| 16 | Legacy data migration | Phase I | Migration is Phase I |
| 17 | Local SQLite query filtering by shop_id | Phase J | Windows transition is Phase J |
| 18 | Android project setup | Phase K | Android is Phase K |
| 19 | Any Flutter/Dart code changes | N/A | Phase C is infrastructure only |
| 20 | Local schema changes | N/A | Phase C does not touch SQLite |
| 21 | pubspec.yaml changes | N/A | No new Flutter dependencies in Phase C |
| 22 | Production deployment | Later session | Phase C creates dev/test environments |
| 23 | Real user/tenant creation | Later session | Phase C is infrastructure setup |

---

## 10. Architecture Boundary

### 10.1 Phase C Target Architecture

```
┌──────────────────────────────────────────┐
│  Supabase Cloud (PostgreSQL)              │
│  ┌────────────────────────────────────┐  │
│  │  Schema: 7 tables                  │  │
│  │  - shops                           │  │
│  │  - shop_members                    │  │
│  │  - roles                           │  │
│  │  - role_permissions_cloud          │  │
│  │  - devices                         │  │
│  │  - licenses                        │  │
│  │  - activations                     │  │
│  ├────────────────────────────────────┤  │
│  │  RLS: 7 shop-isolation policies    │  │
│  ├────────────────────────────────────┤  │
│  │  Functions: 5 server-side fns      │  │
│  └────────────────────────────────────┘  │
│                                           │
│  ┌────────────────────────────────────┐  │
│  │  Auth: Supabase Auth (configured)  │  │  ← Phase D activates
│  │  Edge Functions: None yet          │  │  ← Phase E adds licensing
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  Flutter App (UNCHANGED)                  │
│  ┌────────────────────────────────────┐  │
│  │  SQLite v9 (local, no changes)     │  │
│  │  All existing functionality        │  │
│  │  No cloud connectivity yet         │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 10.2 Layer Ownership

| Layer | Phase C Change | Owner |
|-------|---------------|-------|
| Cloud Schema | Deploy 7 tables | SQL migrations |
| Cloud RLS | Implement shop-isolation policies | SQL policies |
| Cloud Functions | Create 5 server-side functions | SQL functions |
| Cloud Auth | Configure (not activate) | Supabase dashboard |
| Flutter UI | NONE | N/A |
| Flutter Services | NONE | N/A |
| Flutter Database | NONE | N/A |
| Local SQLite | NONE | N/A |
| Build System | NONE | N/A |
| Tests | Infrastructure verification tests only | SQL/integration |

---

## 11. Data / Schema Impact

### 11.1 Cloud Schema (New — Deployed in Phase C)

```sql
-- shops: tenant identity
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settings JSONB DEFAULT '{}'::jsonb
);

-- shop_members: user-tenant membership
CREATE TABLE shop_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'employee', 'salesOnly')),
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  invited_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, user_id)
);

-- roles: per-shop role definitions
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_system BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, name)
);

-- role_permissions_cloud: per-shop permission assignments
CREATE TABLE role_permissions_cloud (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(role_id, permission_id)
);

-- devices: device registration and tracking
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id UUID NOT NULL,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  platform TEXT NOT NULL CHECK (platform IN ('windows', 'android')),
  device_name TEXT,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'REVOKED', 'LOST')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- licenses: shop-scoped licensing
CREATE TABLE licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  license_key TEXT UNIQUE NOT NULL,
  plan TEXT,
  status TEXT NOT NULL DEFAULT 'TRIAL'
    CHECK (status IN ('TRIAL', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'PERPETUAL')),
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  activated_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- activations: device-license binding
CREATE TABLE activations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  license_id UUID NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_verified_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
);
```

### 11.2 Local Schema Impact

**NONE.** Phase C does not modify the local SQLite database. Schema version remains 9. No ALTER TABLE statements. No new local columns. No new local tables.

### 11.3 Entity Ownership Matrix

| Entity | Cloud Owner | Local Cache | Sync Target | Phase |
|--------|------------|-------------|-------------|-------|
| shops | Cloud (source of truth) | N/A | Phase H | C |
| shop_members | Cloud (source of truth) | N/A | Phase H | C |
| roles | Cloud (source of truth) | Local cache | Phase H | C |
| role_permissions_cloud | Cloud (source of truth) | Local cache | Phase H | C |
| devices | Cloud (source of truth) | N/A | Phase H | C |
| licenses | Cloud (source of truth) | Local cache | Phase H | C |
| activations | Cloud (source of truth) | N/A | Phase H | C |

---

## 12. Migration Strategy

### 12.1 Cloud Schema Migration (New Database)

```
OLD_STATE:    No Supabase project, no cloud tables
TARGET_STATE: Supabase project with 7 tables, 7 RLS policies, 5 functions
DETECTION:    Supabase project does not exist
TRANSFORMATION: CREATE TABLE, CREATE POLICY, CREATE FUNCTION statements
IDEMPOTENCY:  Migration files are versioned and idempotent
ROLLBACK:     Delete Supabase project (no local impact)
```

### 12.2 Migration File Structure

```
supabase/
├── config.toml
├── migrations/
│   ├── 20260820000000_create_shops.sql
│   ├── 20260820000001_create_shop_members.sql
│   ├── 20260820000002_create_roles.sql
│   ├── 20260820000003_create_role_permissions_cloud.sql
│   ├── 20260820000004_create_devices.sql
│   ├── 20260820000005_create_licenses.sql
│   ├── 20260820000006_create_activations.sql
│   ├── 20260820000010_rls_policies.sql
│   └── 20260820000020_database_functions.sql
└── seed.sql (optional test data)
```

### 12.3 Local Database Compatibility

| Aspect | Impact |
|--------|--------|
| Schema version | UNCHANGED (remains 9) |
| Existing tables | UNCHANGED |
| Existing columns | UNCHANGED |
| Existing data | UNCHANGED |
| Existing tests | UNCHANGED |
| Existing queries | UNCHANGED |

---

## 13. Cloud / Backend Impact

### 13.1 Server-Owned Data

| Data | Phase C Action |
|------|---------------|
| Shop identity | Table created, empty |
| User membership | Table created, empty |
| Role definitions | Table created, empty (system roles inserted) |
| Permission assignments | Table created, empty (system permissions inserted) |
| Device registrations | Table created, empty |
| License records | Table created, empty |
| Activation records | Table created, empty |

### 13.2 Client-Owned Data

| Data | Phase C Action |
|------|---------------|
| Products | UNCHANGED (local SQLite) |
| Sales | UNCHANGED (local SQLite) |
| Returns | UNCHANGED (local SQLite) |
| Expenses | UNCHANGED (local SQLite) |
| Invoices | UNCHANGED (local SQLite) |
| Customers | UNCHANGED (local SQLite) |
| Users (local) | UNCHANGED (local SQLite) |
| Settings | UNCHANGED (local SQLite) |

### 13.3 Tenant Identifiers

| Identifier | Type | Phase C Action |
|------------|------|---------------|
| `shops.id` | UUID v4 | Table created |
| `shop_members.shop_id` | UUID FK → shops | Table created |
| `shop_members.user_id` | UUID FK → auth.users | Table created |
| Local `shop_id` columns | TEXT NULL | UNCHANGED (Phase B already added) |
| Local `cloud_uuid` columns | TEXT NULL | UNCHANGED (Phase B already added) |

### 13.4 Foreign Key Relationships

```
auth.users ←── shops.owner_user_id
auth.users ←── shop_members.user_id
shops ←── shop_members.shop_id (CASCADE DELETE)
shops ←── roles.shop_id (CASCADE DELETE)
shops ←── devices.shop_id (CASCADE DELETE)
shops ←── licenses.shop_id (CASCADE DELETE)
roles ←── role_permissions_cloud.role_id (CASCADE DELETE)
licenses ←── activations.license_id (CASCADE DELETE)
devices ←── activations.device_id (CASCADE DELETE)
```

### 13.5 RLS Assumptions

| Assumption | Value |
|------------|-------|
| RLS enabled on all 7 tables | YES |
| Default policy | DENY ALL (fail-closed) |
| Shop isolation | Via `shop_members` lookup for `auth.uid()` |
| Owner bypass | Owner has full access to own shop |
| Unauthenticated | NO access to any table |
| Service role | Bypasses RLS (for server functions only) |

### 13.6 Authentication Trust Boundary

```
┌─────────────────────────────────────────────────────┐
│  TRUST BOUNDARY                                      │
│                                                       │
│  Supabase Auth (server-side)                          │
│  ├── JWT token issued on login                       │
│  ├── JWT contains auth.uid()                         │
│  ├── JWT verified by Supabase before RLS evaluation  │
│  └── JWT expiry enforced by Supabase                 │
│                                                       │
│  RLS Policies (server-side)                           │
│  ├── Evaluate AFTER JWT verification                 │
│  ├── Use auth.uid() to lookup shop membership        │
│  ├── Filter rows by shop_id                          │
│  └── Deny if no matching membership                  │
│                                                       │
│  Server Functions (server-side)                       │
│  ├── Execute with service_role privileges            │
│  ├── Bypass RLS (trusted code)                       │
│  ├── Must validate inputs                            │
│  └── Must not expose service_role to client          │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  UNTRUSTED ZONE                                       │
│                                                       │
│  Flutter Client                                       │
│  ├── Receives anon key (public, RLS-protected)       │
│  ├── All queries filtered by RLS                     │
│  ├── No service_role key in binary                   │
│  └── No privileged secrets in binary                 │
└─────────────────────────────────────────────────────┘
```

### 13.7 Secret Management

| Secret | Storage | In Flutter Binary? |
|--------|---------|-------------------|
| Supabase URL | .env / config | YES (public) |
| Supabase anon key | .env / config | YES (public, RLS-protected) |
| Supabase service_role key | Server functions ONLY | NO |
| Database password | Supabase managed | NO |
| SMTP credentials | Server functions ONLY | NO |

**Rule:** Phase C documentation must NEVER contain real keys, passwords, or tokens. Placeholders only.

---

## 14. Authentication / Authorization Impact

### 14.1 Phase C Auth Scope

Phase C creates the **infrastructure** for authentication but does not **activate** it:

| Auth Component | Phase C Action |
|----------------|---------------|
| Supabase Auth project | Configure (enable email provider) |
| Email/password sign-up | NOT enabled (Phase D) |
| Email confirmation | NOT configured (Phase D) |
| Password reset | NOT configured (Phase D) |
| JWT configuration | Default Supabase settings |
| Session management | Default Supabase settings |

### 14.2 Authorization Model (RLS)

| Concept | Phase C Implementation |
|---------|----------------------|
| Authentication | Supabase Auth configured but not activated for users |
| Shop membership | `shop_members` table with role + status |
| Ownership | `shops.owner_user_id` FK |
| Role | `shop_members.role` CHECK constraint |
| Permission | `role_permissions_cloud.permission_id` |
| Device | `devices` table with platform + status |
| Tenant isolation | RLS policies via `shop_members` lookup |

### 14.3 Identity Separation

Phase C establishes these conceptually distinct identities:

| Identity | Table | Phase C Status |
|----------|-------|---------------|
| Shop/Tenant | `shops` | Table created |
| Human User | `auth.users` | Auth configured |
| Membership | `shop_members` | Table created |
| Device | `devices` | Table created |
| License/Subscription | `licenses` | Table created |

These remain separate. No accidental coupling is introduced.

---

## 15. Compatibility Requirements

### 15.1 Backward Compatibility

| Aspect | Compatible? |
|--------|-------------|
| Existing v9 databases | YES (no local changes) |
| Existing data | YES (no local changes) |
| Existing queries | YES (no local changes) |
| Existing tests | YES (no local changes) |
| Existing backup files | YES (no local changes) |
| Existing functionality | YES (no local changes) |

### 15.2 Frozen Compatibility Register

All frozen identifiers from Pre-A remain UNCHANGED:

| Element | Value | Phase C Impact |
|---------|-------|----------------|
| DB filename | muaman_store.db | NONE |
| pubspec name | muaman_store | NONE |
| BINARY_NAME | muaman_store | NONE |
| AppId | {299ADF2A-...} | NONE |
| DefaultDirName | {localappdata}\Programs\muaman_store | NONE |
| All app_settings keys | Current keys | NONE |
| All table names | 12 local tables | NONE |
| All column names | Current columns | NONE |
| All 18 permission IDs | Current permissions | NONE |
| All 3 role names | owner, employee, salesOnly | NONE |
| Schema version | 9 | NONE (no local change) |

### 15.3 Platform Independence

Phase C changes are entirely platform-independent:
- SQL migrations work on any Supabase project
- No Flutter platform-specific code is touched
- No Windows-specific code is touched
- No Android-specific code is touched
- No new dependencies are introduced

---

## 16. Security Requirements

| # | Requirement | Verification |
|---|-------------|-------------|
| 1 | No real secrets in committed files | Secret scan of all committed files |
| 2 | RLS enabled on ALL 7 tables | SQL inspection |
| 3 | Default policy is DENY ALL | SQL inspection |
| 4 | Service role key never in Flutter binary | Code inspection |
| 5 | Anon key is the only client-side key | Config inspection |
| 6 | CASCADE DELETE on all FK relationships | SQL inspection |
| 7 | CHECK constraints on role and status fields | SQL inspection |
| 8 | UNIQUE constraints on business keys | SQL inspection |
| 9 | Timestamps on all records | SQL inspection |
| 10 | JSONB for flexible settings | SQL inspection |

---

## 17. Failure / Recovery Strategy

| Failure Mode | Impact | Recovery |
|-------------|--------|----------|
| Supabase project creation fails | Cannot proceed | Retry; check Supabase status |
| Migration SQL syntax error | Table not created | Fix SQL, re-run migration |
| RLS policy too restrictive | Legitimate queries blocked | Adjust policy, re-test |
| RLS policy too permissive | Data leak risk | Tighten policy, re-test |
| Function logic error | Server operations fail | Fix function, re-deploy |
| Environment config wrong | Connection fails | Correct config, re-test |
| Supabase outage | Cloud unavailable | Phase C is setup only; no runtime dependency yet |

**Rollback:** Delete Supabase project. No local impact. Flutter app remains fully functional.

---

## 18. Testing Strategy

### 18.1 Infrastructure Verification Tests

| # | Test | Verification Method |
|---|------|-------------------|
| 1 | All 7 tables created | SQL query: information_schema.tables |
| 2 | All columns present with correct types | SQL query: information_schema.columns |
| 3 | All constraints enforced | INSERT invalid data → expect rejection |
| 4 | All RLS policies active | Query as unauthenticated → expect empty/denied |
| 5 | RLS shop isolation works | Insert in shop A, query as shop B → expect empty |
| 6 | CASCADE DELETE works | Delete shop → expect cascaded deletion |
| 7 | Functions execute correctly | Call each function with test data |
| 8 | System roles seeded correctly | SELECT from roles → expect 3 system roles |
| 9 | Environment configs valid | Connection test from supabase CLI |

### 18.2 Regression

All 741 existing tests must continue to pass. Phase C does not touch any Flutter code, so regression is expected to be zero-impact.

### 18.3 Pre-Existing Legacy Failures

The 4 known failures in `standalone_backup_restore_test.dart` remain pre-existing and are NOT addressed by Phase C:

1. "owner restores from backup successfully"
2. "restore creates pre-save safety backup"
3. "restored database is accessible and has restored data"
4. "pre-save backup captures pre-restore state"

---

## 19. Required Implementation Verification

| # | Gate | Criterion | Method |
|---|------|-----------|--------|
| 1 | Schema completeness | All 7 tables exist | SQL inspection |
| 2 | Column correctness | All columns match Phase B §8.1 design | SQL inspection |
| 3 | Constraint enforcement | CHECK, UNIQUE, FK constraints work | INSERT/DELETE tests |
| 4 | RLS enforcement | Unauthenticated queries denied | Supabase client test |
| 5 | RLS shop isolation | Cross-shop data invisible | Multi-shop test |
| 6 | Functions work | All 5 functions return expected results | Function call tests |
| 7 | No local changes | Flutter code unchanged | git diff --stat |
| 8 | No secrets committed | No real credentials in repo | Secret scan |
| 9 | Tests pass | 741+ tests passing | flutter test |
| 10 | Analyzer clean | 0 errors, 0 warnings | flutter analyze |
| 11 | Format clean | 0 files changed | dart format |
| 12 | Diff check clean | No conflict markers | git diff --check |

---

## 20. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Supabase project created (dev) | Project accessible via dashboard |
| 2 | Supabase project created (test) | Project accessible via dashboard |
| 3 | 7 cloud tables deployed | SQL inspection |
| 4 | 7 RLS policies active | Policy inspection |
| 5 | 5 database functions created | Function inspection |
| 6 | System roles seeded (owner, employee, salesOnly) | SELECT query |
| 7 | .env.example complete | File inspection |
| 8 | No real secrets in committed files | Secret scan |
| 9 | All existing tests pass (>= 741) | flutter test |
| 10 | flutter analyze = 0 errors, 0 warnings | flutter analyze |
| 11 | dart format = 0 files changed | dart format |
| 12 | git diff --check clean | git diff --check |
| 13 | No Flutter/Dart code changed | git diff --stat |
| 14 | No local schema changed | git diff --stat |
| 15 | No pubspec.yaml changed | git diff --stat |
| 16 | No frozen identifiers changed | Frozen register verified |
| 17 | Preserved artifacts intact | File existence check |
| 18 | Stash intact | git stash list |

---

## 21. Forbidden Implementation Actions

| # | Forbidden Action | Reason |
|---|-----------------|--------|
| 1 | Modifying any Flutter/Dart file | Phase C is infrastructure only |
| 2 | Modifying local SQLite schema | Phase C does not touch local DB |
| 3 | Adding Flutter dependencies | Phase C does not modify pubspec.yaml |
| 4 | Creating Flutter cloud client code | Phase D scope |
| 5 | Configuring Supabase Auth for users | Phase D scope |
| 6 | Implementing login/logout UI | Phase D scope |
| 7 | Creating cloud data models in Dart | Phase G scope |
| 8 | Implementing sync queue | Phase H scope |
| 9 | Running legacy data migration | Phase I scope |
| 10 | Modifying Windows build | No build changes in Phase C |
| 11 | Deploying to production | Production is later session |
| 12 | Creating real user accounts | Phase D scope |
| 13 | Creating real tenant accounts | Phase D scope |
| 14 | Pushing to remote | Separate lock session |
| 15 | Creating tags | Separate lock session |
| 16 | Modifying preserved artifacts | MUST remain unchanged |
| 17 | Modifying the unrelated stash | MUST remain intact |
| 18 | Deleting any file | No deletions in Phase C |

---

## 22. Implementation Session Contract

### Allowed Files

```
supabase/                     (NEW directory)
├── config.toml               (NEW — Supabase configuration)
├── migrations/               (NEW — SQL migration files)
│   ├── *.sql                 (NEW — schema, RLS, functions)
└── seed.sql                  (NEW — optional test data)

.env.example                  (NEW — environment variable template)

PHASE_C_CLOUD_BACKEND_FOUNDATION_PLAN.md (this document — planning only)
```

### Forbidden Files

```
app/lib/**                    (NO changes)
app/test/**                   (NO changes)
pubspec.yaml                  (NO changes)
app/pubspec.yaml              (NO changes)
*.dart                        (NO changes)
CMakeLists.txt                (NO changes)
build.gradle                  (NO changes)
AndroidManifest.xml           (NO changes)
Runner.rc                     (NO changes)
muaman.iss                    (NO changes)
```

---

## 23. Remote Closure Expectations

Future implementation closure must verify:

```
CORRECT_REPOSITORY     = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
CORRECT_BRANCH         = codex/i-tech-next-roadmap-freeze
IMPLEMENTATION_BASELINE = 453485ed1ee92032a78c6030c7203403f027570f
CLEAN_TRACKED_TREE     = git status shows only expected untracked artifacts
CLEAN_INDEX            = git diff --cached shows nothing
PRESERVED_UNTRACKED    = MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md,
                         delivery/I-TECH-Delivery-v1.0.0.zip
PRESERVED_STASH        = 1 pre-existing stash unchanged
TESTS_PASSING          = flutter test (all passing, >= 741)
ANALYZER_PASSING       = flutter analyze (0 errors, 0 warnings)
FORMAT_PASSING         = dart format (0 files changed)
DIFF_CHECK_PASSING     = git diff --check (clean)
SCHEMA_VERSION         = 9 (unchanged)
CLOUD_TABLES           = 7 (deployed)
CLOUD_RLS_POLICIES     = 7 (active)
CLOUD_FUNCTIONS        = 5 (created)
IMPLEMENTATION_SCOPE   = supabase/ directory + .env.example
NO_LOCAL_CHANGES       = VERIFIED (no app/lib, app/test, pubspec changes)
REMOTE_DIVERGENCE      = local ahead of github by planning + implementation commits
NO_FORCE_PUSH          = VERIFIED
NO_HISTORY_REWRITE     = VERIFIED
NO_UNRELATED_DESTROYED = VERIFIED
```

---

## 24. Risks / Open Questions

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | Supabase free tier limitations | LOW | MEDIUM | Verify limits before implementation |
| 2 | RLS policy performance | LOW | MEDIUM | Index on shop_id columns |
| 3 | CASCADE DELETE unintended data loss | LOW | HIGH | Test with realistic data volumes |
| 4 | Function security vulnerabilities | LOW | HIGH | Input validation, parameterized queries |
| 5 | Environment config drift | MEDIUM | LOW | Documented .env.example, version-controlled |
| 6 | Supabase schema changes between versions | LOW | LOW | Pin Supabase CLI version |
| 7 | PostgreSQL version differences | VERY LOW | LOW | Supabase manages PostgreSQL version |

### Open Questions

| # | Question | Owner | Blocks? |
|---|----------|-------|---------|
| 1 | Supabase project name/organization | Owner | YES — needed for project creation |
| 2 | Which Supabase plan (free/pro)? | Owner | NO — can start with free |
| 3 | Development Supabase project URL | Implementation | YES — needed for .env |
| 4 | Test Supabase project URL | Implementation | NO — can create later |
| 5 | Staging/production timeline | Owner | NO — not needed for Phase C |
| 6 | System role permission seed data | Architecture | NO — can derive from existing 18 permissions |
| 7 | Database function naming convention | Architecture | NO — can follow Supabase conventions |

---

## 25. Final Planning Gate

```
PHASE_C_PLANNING_GATE = (
  phase_c_scope_is_evidence_backed           = VERIFIED
  AND planning_document_is_complete          = VERIFIED
  AND no_unresolved_governance_contradiction = VERIFIED (RLS reconciled)
  AND no_production_code_changed             = VERIFIED (no files modified)
  AND preserved_artifacts_intact             = VERIFIED
  AND unrelated_stash_intact                 = VERIFIED
  AND diff_scope_is_exact                    = VERIFIED (only .md files)
  AND git_diff_check_passes                  = PENDING (pre-commit)
  AND no_secrets_exist                       = PENDING (pre-commit)
)
```

---

*This document is the Phase C planning artifact for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md phase roadmap.*
