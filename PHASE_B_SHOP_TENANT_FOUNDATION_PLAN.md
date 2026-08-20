# PHASE B: SHOP/TENANT FOUNDATION PLAN

**Phase:** B - Shop/Tenant Foundation
**Session Type:** PHASE_B_PLANNING
**Project:** I Tech Store Management Product
**Owner:** I Tech for Technology
**Baseline:** `a1613bb25464feb26abf8f278606a7c13b7f6859` on `codex/i-tech-next-roadmap-freeze`
**Date:** 2026-08-20

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Phase | B - Shop/Tenant Foundation |
| Session Type | PHASE_B_PLANNING |
| Document Status | Planning artifact - not implemented |
| Baseline Commit | `a1613bb25464feb26abf8f278606a7c13b7f6859` |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Predecessor Phase | A (Pre-A) - COMPLETED |
| Successor Phase | C - Cloud Backend Foundation |
| Verified By | Baseline: 727/727 tests, 0 errors, 0 warnings, format clean |

---

## 2. Status

```
PLANNING_COMPLETE
AWAITING_IMPLEMENTATION_SESSION
```

---

## 3. Baseline

```
REPOSITORY_ROOT    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH             = codex/i-tech-next-roadmap-freeze
HEAD               = a1613bb25464feb26abf8f278606a7c13b7f6859
REMOTE             = github (https://github.com/sabere342-ai/muaman.worktrees.git)
DIVERGENCE         = 0/0 (local in sync with github)
TAG                = i-tech-productization-planning-baseline-locked -> 9c85781
TEST_BASELINE      = 727/727 PASS
ANALYZE_BASELINE   = 0 errors / 0 warnings / 7 infos
FORMAT_BASELINE    = 0 files changed
SCHEMA_VERSION     = 8
```

---

## 4. Governing Sources

| Document | Role | Relevance to Phase B |
|----------|------|---------------------|
| `PROJECT_MASTER_PLAN.md` | Master governing document | Section 13 defines Phase B; Section 12 frozen register; Section 8 target state |
| `PRODUCTIZATION_ARCHITECTURE_PLAN.md` | Detailed architecture | Section 4 multi-tenant model; Section 5 auth model; Section 17 DB evolution |
| `PRODUCTIZATION_MIGRATION_PLAN.md` | Migration strategy | Section 3 Steps 2-3 (cloud shop + roles); Section 4 mapping table |
| `PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md` | Pre-A closure | Frozen register; identity classification; verified baseline |
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | Verified current state | Schema v8; 12 tables; 18 permissions; 3 roles |

### Governance Precedence

```
1. PROJECT_MASTER_PLAN.md            (owner-approved, supersedes all)
2. PRODUCTIZATION_ARCHITECTURE_PLAN.md (detailed design, linked from master)
3. PRODUCTIZATION_MIGRATION_PLAN.md    (migration strategy, linked from architecture)
4. PRE_A_PRODUCT_IDENTITY_GOVERNANCE_PLAN.md (closed predecessor)
5. I-TECH-NEXT-ROADMAP-V2-FREEZE.md    (historical, superseded for productization)
```

No contradictions found between governing documents on Phase B scope.

---

## 5. Phase Identity

```
NEXT_PHASE_ID       = B
NEXT_PHASE_NAME     = Shop/Tenant Foundation
NEXT_PHASE_PURPOSE  = Establish multi-tenant shop identity, design cloud schema,
                      add local schema foundation for tenant isolation,
                      and define identity mapping strategy
AUTHORITATIVE_SOURCE = PROJECT_MASTER_PLAN.md Section 13, Section 8
PREREQUISITES       = Phase A (Pre-A) - COMPLETED
DEPENDENCIES        = None (Phase B is the first post-Pre-A phase)
```

---

## 6. Problem Statement

The current application is a single-tenant, single-device, local-only SQLite application. Every database table lacks a tenant identifier. Every query operates on the full dataset with no shop-level isolation. The `ShopProfile` model is cosmetic only (name, phone, address) with no structural identity.

To support the master plan target state of multi-tenant, multi-user, multi-device, cloud-synced, a foundational tenant isolation layer must be established BEFORE any cloud backend, authentication, sync, or migration work can begin.

Phase B creates this foundation by:
1. Designing the cloud schema for shops, members, and tenant isolation
2. Adding `shop_id` and `cloud_uuid` columns to the local SQLite schema (additive, nullable, backward-compatible)
3. Defining the identity mapping strategy between local integer PKs and cloud UUIDs
4. Establishing the architectural boundary for tenant-scoped queries
---

## 7. Current State

### 7.1 Database Schema (v8)

| Table | Columns | shop_id? | cloud_uuid? |
|-------|---------|----------|-------------|
| products | 10 | NO | NO |
| sales | 9 | NO | NO |
| returns | 8 | NO | NO |
| expenses | 5 | NO | NO |
| expense_categories | 3 | NO | NO |
| inventory_count | 5 | NO | NO |
| invoices | 9 | NO | NO |
| import_batches | 17 | NO | NO |
| customers | 9 | NO | NO |
| users | 9 | NO | NO |
| role_permissions | 3 | NO | NO |
| app_settings | 2 | NO | NO |

### 7.2 Key Architectural Characteristics

| Characteristic | Current Value | Target (Post-Phase B) |
|---------------|---------------|----------------------|
| Tenant model | Single DB file = single shop | shop_id column on all tables |
| Identity mapping | INTEGER PK only | INTEGER PK + nullable cloud_uuid |
| Shop identity | Cosmetic ShopProfile in app_settings | Structural shop_id + cloud UUID |
| Database file | Single `muaman_store.db` | Same file, additive columns only |
| Schema version | 8 | 9 (additive migration) |
| Query scope | Global (all data) | Global (shop_id nullable, filter deferred) |
| Multi-user | 3 roles, 18 permissions, local-only | Same, with shop_id foundation |
| Cloud readiness | None | Schema prepared for Phase C |

### 7.3 Legacy Coupling Inventory

| # | Coupling | Location | Classification | Phase B Action |
|---|----------|----------|----------------|----------------|
| 1 | No shop_id on any table | `database_helper.dart` (12 tables) | STRUCTURAL | Add columns (v9 migration) |
| 2 | DatabaseHelper singleton | `database_helper.dart:17` | ARCHITECTURE | DEFERRED |
| 3 | All queries lack tenant filter | `database_helper.dart` (50+ methods) | QUERY-LEVEL | DEFERRED to Phase J |
| 4 | ShopProfileService singleton | `shop_profile_service.dart:31` | ARCHITECTURE | DEFERRED |
| 5 | ShopProfile model has no id | `shop_profile.dart:10-17` | MODEL | Add cloudUuid field |
| 6 | Logo filename hardcoded | `shop_profile_service.dart:129` | FILE-NAMING | DEFERRED to Phase J |
| 7 | AppSettings keys global | `app_settings.dart:8-28` | SETTINGS | DEFERRED to Phase J |
| 8 | hasAnyUser() global check | `first_owner_setup_screen.dart:82` | AUTH-FLOW | DEFERRED to Phase D |
| 9 | Username uniqueness global | `user_repository.dart:107-110` | USER-MODEL | DEFERRED to Phase D |
| 10 | CleanStartService global wipe | `clean_start_service.dart:72-82` | DATA-SAFETY | DEFERRED to Phase J |
| 11 | Backup/Restore entire DB | `standalone_backup_service.dart:59` | BACKUP | DEFERRED to Phase P |
| 12 | Dashboard aggregates all data | `database_helper.dart:957-1544` | QUERY | DEFERRED to Phase J |
| 13 | Barcode uniqueness global | `database_helper.dart:148` | CONSTRAINT | DECISION REQUIRED |
| 14 | Invoice number uniqueness global | `database_helper.dart:251` | CONSTRAINT | DECISION REQUIRED |
| 15 | SessionState has no shop context | `session_state.dart:7-43` | SESSION | DEFERRED to Phase D |
| 16 | Licensing is device-bound | `licensing_service.dart:39-53` | LICENSING | DEFERRED to Phase E |

---

## 8. Target State

### 8.1 Cloud Schema Design (Supabase PostgreSQL)

The following cloud tables are designed in Phase B but NOT deployed until Phase C:

```sql
-- Cloud: shops table
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settings JSONB DEFAULT '{}'::jsonb
);

-- Cloud: shop_members table
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

-- Cloud: roles table
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_system BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, name)
);

-- Cloud: role_permissions table
CREATE TABLE role_permissions_cloud (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(role_id, permission_id)
);

-- Cloud: devices table
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

-- Cloud: licenses table
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

-- Cloud: activations table
CREATE TABLE activations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  license_id UUID NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_verified_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
);
```

### 8.2 Local Schema v9 Changes

Additive, nullable, backward-compatible changes to `muaman_store.db`:

| Table | New Column | Type | Default | Reason |
|-------|-----------|------|---------|--------|
| products | `shop_id` | TEXT | NULL | Future tenant isolation |
| products | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| sales | `shop_id` | TEXT | NULL | Future tenant isolation |
| sales | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| returns | `shop_id` | TEXT | NULL | Future tenant isolation |
| returns | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| expenses | `shop_id` | TEXT | NULL | Future tenant isolation |
| expenses | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| expense_categories | `shop_id` | TEXT | NULL | Future tenant isolation |
| expense_categories | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| inventory_count | `shop_id` | TEXT | NULL | Future tenant isolation |
| inventory_count | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| invoices | `shop_id` | TEXT | NULL | Future tenant isolation |
| invoices | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| import_batches | `shop_id` | TEXT | NULL | Future tenant isolation |
| import_batches | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| customers | `shop_id` | TEXT | NULL | Future tenant isolation |
| customers | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| users | `shop_id` | TEXT | NULL | Future tenant isolation |
| users | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| role_permissions | `shop_id` | TEXT | NULL | Future per-shop config |
| role_permissions | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |
| app_settings | `shop_id` | TEXT | NULL | Future per-shop settings |
| app_settings | `cloud_uuid` | TEXT | NULL | Future cloud identity mapping |

**Total: 12 tables x 2 columns = 24 new nullable columns**

### 8.3 Identity Mapping Strategy

```
LOCAL INTEGER PK  <->  CLOUD UUID
     (existing)           (new)

Mapping table (created in Phase I, not Phase B):
  migration_mapping (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    local_id INTEGER NOT NULL,
    cloud_uuid TEXT NOT NULL,
    migrated_at TEXT NOT NULL,
    UNIQUE(entity_type, local_id)
  )

ID Strategy:
  - Local PK remains INTEGER (preserved for upgrade compatibility)
  - Cloud PK is UUID v4 (globally unique, multi-device safe)
  - Mapping is bidirectional: local->cloud and cloud->local
  - Mapping table created during legacy data migration (Phase I)
  - Not created in Phase B (Phase B only defines the strategy)
```

### 8.4 Tenant Isolation Architecture

```
Current:  App -> DatabaseHelper (singleton) -> SQLite (single file, no shop_id)
Phase B:  App -> DatabaseHelper (singleton) -> SQLite (single file, shop_id columns added)
Phase J:  App -> DatabaseHelper (singleton) -> SQLite (single file, queries filter by shop_id)
Phase C+: App -> DatabaseHelper -> SQLite (cache) <-> Sync Layer <-> Supabase (cloud)
```

Phase B establishes the schema foundation. Query-level filtering is deferred to Phase J (Windows Cloud Transition) when the app actually begins using shop_id values.
---

## 9. Scope

### 9.1 In Scope

| # | Deliverable | Type | Files Affected |
|---|-------------|------|----------------|
| 1 | Cloud schema design document (Section 8.1) | Design artifact | This planning document |
| 2 | Local schema v9 migration (24 nullable columns) | Code change | `database_helper.dart` |
| 3 | Schema version bump (8 to 9) | Code change | `database_helper.dart` |
| 4 | ShopProfile model: add `cloudUuid` field | Code change | `shop_profile.dart` |
| 5 | ShopProfile persistence: add `cloudUuid` key | Code change | `shop_profile_repository.dart` |
| 6 | Identity mapping strategy document | Design artifact | This planning document |
| 7 | Migration test: verify v8 to v9 upgrade | Code change | `test/database/` |
| 8 | Schema verification test | Code change | `test/database/` |

### 9.2 Explicit Non-Goals

| # | Item | Deferred To | Reason |
|---|------|-------------|--------|
| 1 | Cloud Supabase project setup | Phase C | Phase B is local-only |
| 2 | RLS policies | Phase C | Requires cloud backend |
| 3 | Cloud authentication | Phase D | Requires cloud backend |
| 4 | Employee invitation flow | Phase D | Requires cloud auth |
| 5 | shop_id column population | Phase J | Values come from cloud |
| 6 | Query-level tenant filtering | Phase J | Requires populated shop_id |
| 7 | SessionState shop context | Phase D | Requires cloud auth |
| 8 | Per-shop clean start | Phase J | Requires tenant-aware queries |
| 9 | Per-shop backup/restore | Phase P | Requires tenant-aware architecture |
| 10 | Cloud sync | Phase H | Requires cloud backend |
| 11 | Licensing changes | Phase E | Separate concern |
| 12 | Android adaptation | Phase K | Separate platform |
| 13 | migration_mapping table creation | Phase I | Created during actual migration |

---

## 10. Preconditions

| # | Prerequisite | Status | Evidence |
|---|-------------|--------|----------|
| 1 | Phase A (Pre-A) completed | SATISFIED | Commit a1613bb verified as HEAD |
| 2 | Planning baseline tag exists | SATISFIED | Tag points to 9c85781 |
| 3 | Tests passing | SATISFIED | 727/727 PASS |
| 4 | Analyzer clean | SATISFIED | 0 errors, 0 warnings |
| 5 | Format clean | SATISFIED | 0 files changed |
| 6 | Clean working tree | SATISFIED | Only preserved untracked files |
| 7 | Clean index | SATISFIED | Nothing staged |
| 8 | Remote in sync | SATISFIED | Divergence 0/0 |
| 9 | Master plan readable | SATISFIED | Read and analyzed |
| 10 | Architecture plan readable | SATISFIED | Read and analyzed |

**ALL PRECONDITIONS SATISFIED**

---

## 11. Architecture

### 11.1 Current Architecture

```
+-------------------------------+
|     Flutter Windows App       |
|  +-------------------------+  |
|  |     UI (15+ screens)    |  |
|  +-------------------------+  |
|  |  Services (12+ files)   |  |
|  |  - PermissionResolver   |  |
|  |  - SessionState         |  |
|  |  - LicensingService     |  |
|  |  - ShopProfileService   |  |
|  +-------------------------+  |
|  |  Database (7+ files)    |  |
|  |  - DatabaseHelper       |  |
|  |  - UserRepository       |  |
|  |  - InvoiceRepository    |  |
|  +-------------------------+  |
|  | SQLite (muaman_store.db)|  |
|  +-------------------------+  |
+-------------------------------+
```

### 11.2 Target Architecture (Post-Phase B)

```
+-------------------------------+
|     Flutter Windows App       |
|  +-------------------------+  |
|  |     UI (15+ screens)    |  |  <-- No change
|  +-------------------------+  |
|  |  Services               |  |
|  |  - ShopProfile          |  |  <-- cloudUuid field added
|  |  (others unchanged)     |  |
|  +-------------------------+  |
|  |  Database               |  |
|  |  - DatabaseHelper       |  |  <-- schema v9: shop_id, cloud_uuid
|  |  (others unchanged)     |  |
|  +-------------------------+  |
|  | SQLite (muaman_store.db)|  |  <-- 24 new nullable columns
|  +-------------------------+  |
+-------------------------------+

Cloud Schema (designed, not deployed):
+-------------------------------+
|  Supabase PostgreSQL          |
|  - shops                      |
|  - shop_members               |
|  - roles                      |
|  - role_permissions_cloud     |
|  - devices                    |
|  - licenses                   |
|  - activations                |
+-------------------------------+
```

### 11.3 Layer Ownership

| Layer | Phase B Change | Owner |
|-------|---------------|-------|
| UI | NONE | N/A |
| Services | ShopProfile cloudUuid field | shop_profile.dart, shop_profile_repository.dart |
| Database | Schema v9 migration, version bump | database_helper.dart |
| Persistence | 24 new nullable columns | SQLite ALTER TABLE (additive) |
| Cloud | Design only (no deployment) | This planning document |

### 11.4 Platform Independence

Phase B changes are entirely platform-independent:
- SQLite schema changes work identically on Windows and Android
- ShopProfile model changes are pure Dart
- No platform-specific code is touched
- No new dependencies are introduced
---

## 12. Data/Persistence Impact

### 12.1 Schema Migration (v8 to v9)

```
Migration type: Additive (ALTER TABLE ADD COLUMN)
Destructive: NO
Backward compatible: YES (all new columns nullable with NULL default)
Existing data affected: NO
Performance impact: NEGLIGIBLE
Rollback possible: YES for code; NO for schema version (forward-only)
```

The migration executes 24 `ALTER TABLE ... ADD COLUMN` statements across 12 tables. Each statement adds a nullable TEXT column with NULL default. Existing rows receive NULL for new columns. No existing columns are modified, renamed, or dropped.

### 12.2 Schema Version Policy

Schema version is monotonically increasing. Once upgraded to v9, the database cannot be downgraded to v8 without data loss. This is consistent with the master plan principle of additive-only schema evolution.

### 12.3 Existing Data Preservation

| Aspect | Impact |
|--------|--------|
| Row counts | UNCHANGED |
| Existing columns | UNCHANGED |
| Column types | UNCHANGED |
| Constraints | UNCHANGED |
| Indexes | UNCHANGED |
| New columns | NULL for all existing rows |
| Financial data | UNCHANGED |
| Relationships | UNCHANGED |

---

## 13. Compatibility

### 13.1 Backward Compatibility

| Aspect | Compatible? |
|--------|-------------|
| Existing v8 databases | YES |
| Existing data | YES |
| Existing queries | YES |
| Existing tests | YES |
| Existing backup files | PARTIAL (v8 backups work on v9 app; reverse not guaranteed) |
| Downgrade v9 to v8 | NO (forward-only schema) |

### 13.2 Frozen Compatibility Register

All frozen identifiers from Pre-A are UNCHANGED:

| Element | Value | Phase B Impact |
|---------|-------|----------------|
| DB filename | muaman_store.db | NONE |
| pubspec name | muaman_store | NONE |
| BINARY_NAME | muaman_store | NONE |
| AppId | {299ADF2A-...} | NONE |
| DefaultDirName | {localappdata}\Programs\muaman_store | NONE |
| All app_settings keys | Current 18 keys | NONE (1 new key added) |
| All table names | 12 tables | NONE |
| All column names | Current columns | NONE |
| All 18 permission IDs | Current permissions | NONE |
| All 3 role names | owner, employee, salesOnly | NONE |
| Schema version | 8 -> 9 | INCREMENTED per governance |

---

## 14. Security/Permissions Impact

NONE. Phase B does not add, remove, or modify any permissions. The 18 existing permissions remain unchanged. The new columns are metadata (UUIDs), not sensitive data.

---

## 15. Platform Impact

Phase B changes are 100% platform-independent. The same SQLite schema migration runs identically on Windows and Android. No new dependencies are introduced. No build scripts change. No installer changes.

---

## 16. Migration Strategy

### Local Schema Migration (v8 to v9)

```
OLD_STATE:    Schema v8, 12 tables, no shop_id/cloud_uuid columns
TARGET_STATE: Schema v9, 12 tables, each with shop_id TEXT NULL and cloud_uuid TEXT NULL
DETECTION:    SQLite PRAGMA user_version returns 8
TRANSFORMATION: 24 ALTER TABLE ADD COLUMN statements
IDEMPOTENCY:  onUpgrade called exactly once per version change
BACKWARD_COMPAT: All new columns nullable with NULL default
ROLLBACK:     Schema version forward-only; restore pre-migration backup to recover
```

---

## 17. Workstreams

### Workstream 1: Database Schema v9 Migration

```
Objective: Add shop_id and cloud_uuid columns to all 12 tables
Affected architecture: Database layer
Expected files: database_helper.dart
Implementation steps:
  1. Add v8->v9 migration handler in _onUpgrade
  2. Execute 24 ALTER TABLE ADD COLUMN statements
  3. Bump version from 8 to 9 in _initDB
Dependencies: None
Tests: Migration test, schema verification, data integrity, full test suite
Exit gate: flutter analyze + flutter test + schema verification
```

### Workstream 2: ShopProfile Cloud Identity

```
Objective: Add cloudUuid field to ShopProfile model
Affected architecture: Model + Repository layers
Expected files: shop_profile.dart, shop_profile_repository.dart, app_settings.dart
Implementation steps:
  1. Add cloudUuid field to ShopProfile model
  2. Add shopProfile.cloudUuid key to AppSettings
  3. Update ShopProfileRepository to persist/load cloudUuid
  4. Update copyWith to include cloudUuid
  5. Update equality/hashCode to include cloudUuid
Dependencies: Workstream 1
Tests: Round-trip persistence, backward compat, defaults
Exit gate: flutter analyze + flutter test
```

### Workstream 3: Tests and Verification

```
Objective: Verify migration correctness and existing functionality
Affected architecture: Test layer
Expected files: test/database/schema_v9_migration_test.dart (new),
                test/models/shop_profile_cloud_uuid_test.dart (new)
Dependencies: Workstreams 1 and 2
Tests: Migration tests, ShopProfile tests, full regression (727+ tests)
Exit gate: All tests pass, format clean, analyze clean
```

### Execution Order

```
Workstream 1 (Schema v9) -> Workstream 2 (ShopProfile) -> Workstream 3 (Tests)
```

---

## 18. File/Symbol Impact Forecast

| Path / Symbol | Existing/New | Planned Change | Reason | Risk |
|---------------|-------------|----------------|--------|------|
| `app/lib/database/database_helper.dart` | EXISTING | Add v8->v9 migration; bump version to 9 | Schema evolution | LOW |
| `app/lib/models/shop_profile.dart` | EXISTING | Add cloudUuid field, update copyWith, ==, hashCode | Cloud identity | LOW |
| `app/lib/services/shop_profile_repository.dart` | EXISTING | Add cloudUuid key load/save | Persistence | LOW |
| `app/lib/services/app_settings.dart` | EXISTING | Add keyShopProfileCloudUuid constant | New key | LOW |
| `test/database/schema_v9_migration_test.dart` | NEW | Migration verification tests | Test coverage | LOW |
| `test/models/shop_profile_cloud_uuid_test.dart` | NEW | ShopProfile cloudUuid tests | Test coverage | LOW |

Summary: 4 existing files modified, 2 new test files, 0 new dependencies, 0 UI screens modified.

---

## 19. Test Strategy

### New Tests Required

| Test | File | Scenario |
|------|------|----------|
| v8 to v9 migration | schema_v9_migration_test.dart | Create v8 DB, migrate, verify 24 columns |
| Data preservation | schema_v9_migration_test.dart | Insert data in v8, migrate, verify unchanged |
| New columns nullable | schema_v9_migration_test.dart | Verify existing rows have NULL |
| ShopProfile with cloudUuid | shop_profile_cloud_uuid_test.dart | Round-trip persistence |
| ShopProfile without cloudUuid | shop_profile_cloud_uuid_test.dart | Backward compat |
| Default cloudUuid is null | shop_profile_cloud_uuid_test.dart | DefaultProfile has null |

### Regression

All 727 existing tests must pass against v9 schema.

---

## 20. Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | Migration fails on corrupted v8 database | LOW | HIGH | Pre-migration backup recommendation |
| 2 | Existing tests break due to schema change | VERY LOW | MEDIUM | Nullable columns; no query changes |
| 3 | Performance impact from 24 nullable columns | NEGLIGIBLE | LOW | Zero overhead on existing queries |
| 4 | Downgrade v9 to v8 causes issues | LOW | LOW | Forward-only by design |
| 5 | ShopProfile cloudUuid breaks serialization | VERY LOW | LOW | Nullable; existing code ignores unknown |
| 6 | Phase B scope creep into query filtering | MEDIUM | MEDIUM | Strict non-goals; filtering deferred to Phase J |

### Open Questions

| # | Question | Owner | Blocks? |
|---|----------|-------|---------|
| 1 | Barcode uniqueness: per-shop or global? | Owner | NO |
| 2 | Invoice number uniqueness: per-shop or global? | Owner | NO |
| 3 | role_permissions: per-shop or shared? | Architecture | NO |

---

## 21. Rollback/Recovery

| Action | Feasibility |
|--------|-------------|
| Git revert of planning commit | SAFE (planning only) |
| Git revert of implementation commit | SAFE if no v9 databases deployed |
| Restore pre-v9 backup | SAFE (requires user backup) |
| Downgrade v9 database to v8 | NOT POSSIBLE (forward-only schema) |

---

## 22. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Schema version is 9 | PRAGMA user_version |
| 2 | All 12 tables have shop_id TEXT NULL | Schema inspection |
| 3 | All 12 tables have cloud_uuid TEXT NULL | Schema inspection |
| 4 | Existing data preserved | SELECT COUNT per table |
| 5 | ShopProfile has cloudUuid field | Code inspection |
| 6 | ShopProfile persistence supports cloudUuid | Round-trip test |
| 7 | All existing tests pass (>= 727) | flutter test |
| 8 | flutter analyze = 0 errors, 0 warnings | flutter analyze |
| 9 | dart format = 0 files changed | dart format |
| 10 | git diff --check clean | git diff --check |
| 11 | No production logic changes beyond schema + model | git diff --stat |
| 12 | No new dependencies | pubspec.yaml unchanged |
| 13 | No UI changes | Screen files unchanged |
| 14 | No permission changes | permissions.dart unchanged |
| 15 | No frozen identifiers changed | Frozen register verified |

---

## 23. Definition of Done

```
PHASE_B_DONE = (
  schema_version = 9
  AND all 12 tables have shop_id TEXT NULL
  AND all 12 tables have cloud_uuid TEXT NULL
  AND existing data preserved
  AND ShopProfile has cloudUuid field
  AND ShopProfile persistence supports cloudUuid
  AND new tests pass
  AND all existing tests pass (>= 727)
  AND flutter analyze = 0 errors, 0 warnings
  AND dart format = 0 files changed
  AND git diff --check clean
  AND no UI changes
  AND no permission changes
  AND no frozen identifier changes
  AND no new dependencies
  AND planning commit created
  AND no push/tag/deploy performed
)
```

---

## 24. Implementation Session Boundary

Allowed: Edit database_helper.dart, shop_profile.dart, shop_profile_repository.dart, app_settings.dart; create 2 test files; run format/analyze/test; create commit.

Forbidden: Modifying query logic to filter by shop_id; adding shop_id population; creating migration_mapping table; adding Supabase dependencies; modifying UI screens; modifying permission/licensing/backup/clean-start logic; any cloud connectivity; any push/tag/deploy.

---

## 25. Remote/Final Integrity Requirements

Future implementation closure must verify:

```
CORRECT_REPOSITORY     = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
CORRECT_BRANCH         = codex/i-tech-next-roadmap-freeze
IMPLEMENTATION_BASELINE = a1613bb25464feb26abf8f278606a7c13b7f6859
EXPECTED_ANCESTRY      = 9c85781 -> 04b6655 -> a1613bb -> [phase_b_commit]
CLEAN_TRACKED_TREE     = git status shows no tracked changes
CLEAN_INDEX            = git diff --cached shows nothing
PRESERVED_UNTRACKED    = MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md,
                         delivery/I-TECH-Delivery-v1.0.0.zip
PRESERVED_STASH        = 1 pre-existing stash unchanged
TESTS_PASSING          = flutter test (all passing, >= 727)
ANALYZER_PASSING       = flutter analyze (0 errors, 0 warnings)
FORMAT_PASSING         = dart format (0 files changed)
DIFF_CHECK_PASSING     = git diff --check (clean)
SCHEMA_VERSION         = 9
IMPLEMENTATION_SCOPE   = database_helper.dart + shop_profile.dart +
                         shop_profile_repository.dart + app_settings.dart + 2 test files
BRANCH_ANCESTRY        = Pre-A commits -> Phase B commit
REMOTE_DIVERGENCE      = local ahead of github by planning + implementation commits
NO_FORCE_PUSH          = VERIFIED
NO_HISTORY_REWRITE     = VERIFIED
NO_UNRELATED_DESTROYED = VERIFIED
```

---

## 26. Governing Constraints

### Product Identity Rules

All product identity rules from Pre-A remain in effect. No owner decisions (OD1-OD7) block Phase B.

### Roadmap Continuity

Phase B is the first phase of the master plan A->B->C->... chain after completed Pre-A (Phase A). It does not conflict with any closed roadmap.

---

## 27. Governance Consistency Check

| Governing Plan Topic | Phase B Plan Alignment | Verdict |
|---------------------|----------------------|---------|
| Phase ordering A->B->C | Phase B follows completed Phase A | CONSISTENT |
| Schema version 8->9 in Phase B | Architecture plan Section 17 confirms | CONSISTENT |
| Additive-only schema | Phase B adds nullable columns only | CONSISTENT |
| Frozen compatibility register | No frozen identifiers changed | CONSISTENT |
| Zero data loss | No existing data deleted or modified | CONSISTENT |
| Cloud schema designed not deployed | Phase B designs; Phase C deploys | CONSISTENT |
| No owner decisions required | Phase B is purely structural | CONSISTENT |

**GOVERNANCE_CONSISTENCY = PASS**

---

*This document is the Phase B planning artifact for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md phase roadmap.*

