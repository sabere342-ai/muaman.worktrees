# PHASE H: OFFLINE SYNC CORE PLAN

**Phase:** H - Offline Sync Core
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
| Phase | H - Offline Sync Core |
| Session Type | PHASE_H_PLANNING |
| Baseline Commit | `a384f6460b3c8240e428bd42a194dedbe8b06770` |
| Predecessor Phase | G - Cloud Data Foundation (CLOSED) |
| Successor Phase | I - Legacy Data Migration |
| Governing Documents | `PROJECT_MASTER_PLAN.md`, `PRODUCTIZATION_ARCHITECTURE_PLAN.md` |
| Phase G Closure | `PASS_PHASE_G_REMOTE_LOCKED` |

---

## 2. Verified Starting Baseline

```
PHASE_G_PLANNING_COMMIT       = 632d4f18fc5e8892f39b6e1bc635d725b6026652
PHASE_G_IMPLEMENTATION_COMMIT = a384f6460b3c8240e428bd42a194dedbe8b06770
IMPLEMENTATION_PARENT         = 632d4f18fc5e8892f39b6e1bc635d725b6026652
PLANNING_TAG                  = phase-g-planning-baseline-locked -> 632d4f18fc5e8892f39b6e1bc635d725b6026652
IMPLEMENTATION_TAG            = phase-g-implementation-locked -> a384f6460b3c8240e428bd42a194dedbe8b06770
LOCAL_HEAD_BEFORE             = a384f6460b3c8240e428bd42a194dedbe8b06770
REMOTE_HEAD_BEFORE            = a384f6460b3c8240e428bd42a194dedbe8b06770
LOCAL_AHEAD_BEFORE            = 0
REMOTE_AHEAD_BEFORE           = 0
```

### Verification Evidence

```
H-P01: Repository root    = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze (verified)
H-P02: Branch              = codex/i-tech-next-roadmap-freeze (verified)
H-P03: GitHub remote       = github -> https://github.com/sabere342-ai/muaman.worktrees.git (verified)
H-P04: HEAD                = a384f6460b3c8240e428bd42a194dedbe8b06770 (verified)
H-P05: HEAD^               = 632d4f18fc5e8892f39b6e1bc635d725b6026652 (verified)
H-P06: Planning tag        = 632d4f18fc5e8892f39b6e1bc635d725b6026652 (verified)
H-P07: Implementation tag  = a384f6460b3c8240e428bd42a194dedbe8b06770 (verified)
H-P08: Divergence          = 0    0 (verified)
```

### Preserved Stash

```
stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration:
           283ff9d MUAMAN-12: implement local user roles and sales-only access
STATUS: EXISTS - PRESERVED - NOT MODIFIED
```

### Untracked Artifacts (Expected/Preserved)

```
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md  - Preserved from previous sessions
delivery/I-TECH-Delivery-v1.0.0.zip              - Preserved from previous sessions
STATUS: UNTRACKED, NOT PART OF THIS SESSION
```

---

## 3. Governing Requirements

### 3.1 Master Plan Mandates

From `PROJECT_MASTER_PLAN.md`:
- Section 4 #1: Zero data loss
- Section 4 #2: Atomicity survives migration
- Section 4 #3: Dual-layer enforcement
- Section 4 #4: Offline by default
- Section 4 #7: Additive-only schema evolution
- Section 9 #1: Cloud authority with local cache
- Section 9 #2: UUID for cloud, integer for local
- Section 9 #4: Soft delete for sync
- Section 9 #5: Idempotent operations
- Section 9 #7: Fail-closed authorization
- Section 12: All 18 permission IDs FROZEN (add-only)
- Section 12: Inventory formula INVARIANT
- Section 12: Sale atomicity INVARIANT
- Section 12: COGS snapshot INVARIANT
- Section 16: All 16 current capabilities preserved + cloud

### 3.2 Architecture Plan Mandates

From `PRODUCTIZATION_ARCHITECTURE_PLAN.md`:
- Section 9: Queue-based sync architecture with pending-write queue
- Section 9: Operations classification (OFFLINE_SAFE, OFFLINE_WITH_PENDING_SYNC, ONLINE_PREFERRED, ONLINE_REQUIRED)
- Section 9: sync_queue schema with idempotency keys
- Section 9: Conflict resolution per entity type
- Section 9: Version tracking (server_version, updated_at, deleted_at)
- Section 10: Inventory conflict policy (server-authoritative for multi-device)
- Section 17: Schema v13 for Phase H (sync_queue table)

### 3.3 Phase G Handoff

Phase G created (incoming):
- 9 cloud business tables with `shop_id`, `deleted_at`, `updated_at`
- SECURITY DEFINER CRUD functions (19)
- RLS policies for shop isolation
- Indexes including `updated_at` for sync queries
- Dart cloud DTOs and repositories
- Permission enforcement via `require_shop_permission`
- Financial type strategy (NUMERIC)
- Atomic compound operations

Phase H must create:
- sync_queue table (local SQLite)
- server_version columns
- Idempotency key infrastructure
- Sync engine (retry, orchestration, conflict detection)
- Tombstone query logic (reads `deleted_at`)
- Changed-since query logic (reads `updated_at`)
- Offline pending-write processor
- Real-time subscriptions
- Background sync worker
- Local schema v13 changes (sync columns)
- Conflict resolution UI
- Offline reconciliation

### 3.4 Open Owner Decisions Relevant to Phase H

| OD | Decision | Status | Impact on Phase H |
|----|----------|--------|-------------------|
| OD4 | Offline grace duration | OPEN | Determines how long offline writes are allowed before blocking |
| OD7 | Whether seller offline sale is allowed | OPEN | Determines if salesOnly role can create offline sales |
| OD6 | Negative stock policy for offline | OPEN | Determines conflict resolution for stock on sync |

**Decision:** Phase H plan will define DEFAULT policies for OD4/OD6/OD7 that are safe and reversible. These can be refined when the owner decisions are finalized.

---

## 4. Current State

### 4.1 Local SQLite (Schema Version 9)

| Metric | Value |
|--------|-------|
| Tables | 12 |
| Sync fields | `shop_id` + `cloud_uuid` on all 12 tables |
| Soft delete | NONE (all hard deletes) |
| Schema version | 9 |
| Migration path | v1 -> v2 -> v3 -> v4 -> v5 -> v6 -> v7 -> v8 -> v9 |

**Entities (12):**

| Entity | Table | Sync-Ready Fields |
|--------|-------|-------------------|
| Product | products | shop_id, cloud_uuid |
| Sale | sales | shop_id, cloud_uuid |
| Return | returns | shop_id, cloud_uuid |
| Expense | expenses | shop_id, cloud_uuid |
| Expense Category | expense_categories | shop_id, cloud_uuid |
| Invoice | invoices | shop_id, cloud_uuid |
| Customer | customers | shop_id, cloud_uuid |
| Inventory Count | inventory_count | shop_id, cloud_uuid |
| Import Batch | import_batches | shop_id, cloud_uuid |
| User | users | shop_id, cloud_uuid |
| Role Permission | role_permissions | shop_id, cloud_uuid |
| App Setting | app_settings | shop_id, cloud_uuid |

### 4.2 Cloud Supabase (PostgreSQL)

| Metric | Value |
|--------|-------|
| Tables | 19 |
| Functions | 37 |
| Indexes | 30+ |
| RLS Policies | 19 (all SELECT-only) |
| Soft delete tables | 8 (all cloud_* tables) |

### 4.3 Gap Analysis

| Capability | Local | Cloud | Phase H Bridge |
|-----------|-------|-------|----------------|
| Data creation | SQLite INSERT | RPC → SECURITY DEFINER | Queue local create → sync to cloud |
| Data update | SQLite UPDATE | RPC → SECURITY DEFINER | Queue local update → sync to cloud |
| Data delete | Hard delete | Soft delete (deleted_at) | Queue local delete → cloud soft delete |
| Conflict detection | None | Server timestamp | Add version tracking |
| Offline support | Full | Requires network | Queue-based pending writes |
| Multi-device | No | Yes (UUID isolation) | Sync queue processes per-device |
| Real-time | No | Supabase Realtime | Subscribe to cloud changes |

---

## 5. Phase H Official Objective

**Name:** Offline Sync Core

**Objective:** Implement a queue-based offline sync system that enables multi-device data consistency while preserving the offline-first architecture. The sync engine bridges local SQLite operations with the cloud Supabase backend through an idempotent pending-write queue, conflict detection, and version tracking.

**Core deliverables:**
1. Local sync_queue table and migration to schema v13
2. Sync engine service with retry, idempotency, and conflict handling
3. Background sync worker with connectivity awareness
4. Cloud-to-local hydration for initial and incremental sync
5. Tombstone propagation (local hard delete → cloud soft delete)
6. Changed-since queries for incremental cloud pulls
7. Conflict detection and resolution UI
8. Server_version tracking on cloud entities

---

## 6. In Scope

### 6.1 Schema Changes

- SQLite migration v9 → v13:
  - Add `sync_queue` table
  - Add `server_version INTEGER` to all 12 existing tables
  - Add `sync_status TEXT` to all 12 existing tables (SYNCED, PENDING, CONFLICT)
  - Add `last_synced_at TEXT` to all 12 existing tables
- Supabase migration:
  - Add `server_version INTEGER DEFAULT 1` column to all 9 cloud_* tables
  - Add `sync_version INTEGER` column to all 9 cloud_* tables
  - Create `sync_log` table for server-side sync audit

### 6.2 Sync Engine (Dart)

- `SyncEngine` service: orchestrates full sync lifecycle
- `SyncQueue` repository: local queue CRUD and lifecycle management
- `SyncWorker` service: background periodic sync with connectivity check
- `ConflictResolver` service: conflict detection and resolution logic
- `HydrationService`: initial cloud-to-local data load
- `IncrementalSyncService`: changed-since pull logic

### 6.3 Entity Sync Adapters

One adapter per syncable entity:
- `ProductSyncAdapter`
- `SaleSyncAdapter`
- `ReturnSyncAdapter`
- `ExpenseSyncAdapter`
- `ExpenseCategorySyncAdapter`
- `CustomerSyncAdapter`
- `InvoiceSyncAdapter`
- `InventoryCountSyncAdapter`
- `ShopSettingsSyncAdapter`

### 6.4 UI Changes

- Sync status indicator (enhanced from current green/orange/gray dot)
- Conflict resolution dialog
- Pending operations display
- Last synced timestamp display

### 6.5 Offline Behavior

- All current local operations remain unchanged (write to SQLite first)
- After each local write, enqueue sync operation
- On reconnection, process queue in FIFO order
- Each queue entry has idempotency_key for safe retry
- Conflicts flagged for manual review or auto-resolution per policy

### 6.6 Testing

- Unit tests for sync engine, queue, conflict resolver
- Database tests for schema v13 migration
- Integration tests for offline→online sync cycle
- Conflict scenario tests
- Idempotency tests

---

## 7. Explicit Out of Scope

| Item | Deferred To | Reason |
|------|------------|--------|
| Legacy data migration | Phase I | Phase I handles bulk upload of existing local data to cloud |
| Windows cloud transition | Phase J | Phase J redirects UI to cloud-first |
| Android owner foundation | Phase K | Phase K creates Android onboarding |
| Android sales/employee | Phase L | Phase L creates Android operational screens |
| Inventory conflict hardening | Phase M | Phase M adds advanced concurrency controls |
| Cross-platform Excel import | Phase N | Phase N handles workbook sync |
| Invoice branding | Phase O | Phase O handles template customization |
| Production hardening | Phase P | Phase P adds chaos testing, security audit |
| Real-time subscriptions | Deferred | Supabase Realtime integration deferred to ensure stability |
| Custom conflict resolution UI | Deferred | Basic auto-resolution first; UI refinement in Phase M |
| Bidirectional real-time push | Deferred | Pull-based sync first; push in later phases |

---

## 8. Architecture

### 8.1 Sync Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Application                │
│                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐  │
│  │  UI Layer │───>│ Services │───>│  Sync Engine │  │
│  └──────────┘    └──────────┘    └──────┬───────┘  │
│                                          │          │
│  ┌──────────┐    ┌──────────┐    ┌──────┴───────┐  │
│  │  SQLite  │<──>│  Queue   │<──>│Cloud Repos   │  │
│  │ (local)  │    │ Repository│    │ (Supabase)   │  │
│  └──────────┘    └──────────┘    └──────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │              Background Sync Worker           │   │
│  │  (connectivity check → process queue → retry) │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 8.2 Sync Flow: Local Create

```
1. User performs operation (e.g., create product)
2. DatabaseHelper writes to local SQLite
3. SyncQueue.enqueue(entity_type, entity_id, operation=CREATE, payload)
4. If online: SyncWorker picks up and calls cloud RPC
5. If offline: entry stays PENDING in queue
6. On next reconnection: SyncWorker processes queue
7. Cloud RPC succeeds → queue entry marked SYNCED
8. Cloud RPC fails → retry_count incremented, stays PENDING
9. After max retries → marked FAILED, user notified
```

### 8.3 Sync Flow: Cloud Pull (Hydration)

```
1. On login or reconnection: HydrationService checks last_synced_at
2. If first sync: full pull of all cloud entities for shop
3. If incremental: changed-since query using updated_at index
4. For each cloud entity:
   a. Check if local cloud_uuid exists
   b. If exists: compare server_version, update if newer
   c. If not exists: insert locally with cloud_uuid linkage
5. For deleted_at != NULL: mark local record as soft-deleted or remove
```

### 8.4 Conflict Detection

```
1. When processing a queued write:
   a. Fetch current server_version from cloud
   b. Compare with server_version at time of local write
   c. If equal: no conflict, proceed
   d. If different: CONFLICT detected
2. Conflict resolution per entity type:
   - Products: last-writer-wins (server timestamp)
   - Sales/Returns: server-authoritative (each is unique, no true conflict)
   - Expenses: last-writer-wins
   - Inventory Count: latest count wins
   - Shop Settings: last-writer-wins
   - Customers: last-writer-wins
   - Invoices: server-authoritative (invoice_number uniqueness)
```

---

## 9. Local Database Impact

### 9.1 Schema v13 Migration

```sql
-- sync_queue table
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,           -- UUID
  entity_type TEXT NOT NULL,     -- 'product', 'sale', 'return', etc.
  entity_id INTEGER NOT NULL,    -- local SQLite PK
  operation TEXT NOT NULL,       -- 'CREATE', 'UPDATE', 'DELETE'
  payload TEXT,                  -- JSON serialized entity
  created_at TEXT NOT NULL,      -- ISO8601 timestamp
  synced_at TEXT,                -- nullable, set on successful sync
  retry_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'PENDING', -- 'PENDING', 'SYNCED', 'FAILED', 'CONFLICT'
  conflict_data TEXT,            -- nullable, JSON of conflict details
  idempotency_key TEXT NOT NULL, -- UUID, unique per operation
  shop_id TEXT                   -- shop identifier
);

-- Sync tracking columns on all 12 existing tables
ALTER TABLE products ADD COLUMN server_version INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN sync_status TEXT DEFAULT 'SYNCED';
ALTER TABLE products ADD COLUMN last_synced_at TEXT;

ALTER TABLE sales ADD COLUMN server_version INTEGER DEFAULT 0;
ALTER TABLE sales ADD COLUMN sync_status TEXT DEFAULT 'SYNCED';
ALTER TABLE sales ADD COLUMN last_synced_at TEXT;

-- ... (same for all 12 tables)
```

### 9.2 Migration Properties

- Forward-only
- Deterministic
- Additive (new table + new nullable columns with defaults)
- Idempotent (safe to restart)
- Zero data loss
- Backup required before execution

---

## 10. Cloud Database Impact

### 10.1 Supabase Migration

```sql
-- Add server_version to all 9 cloud tables
ALTER TABLE cloud_products ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_customers ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_sales ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_returns ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_expenses ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_expense_categories ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_invoices ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_inventory_count ADD COLUMN server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_shop_settings ADD COLUMN server_version INTEGER DEFAULT 1;

-- Sync audit log
CREATE TABLE sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  operation TEXT NOT NULL,
  idempotency_key TEXT UNIQUE NOT NULL,
  actor_user_id UUID REFERENCES auth.users(id),
  status TEXT NOT NULL, -- 'SYNCED', 'CONFLICT', 'FAILED'
  conflict_details JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for sync_log queries
CREATE INDEX idx_sync_log_shop ON sync_log(shop_id, created_at DESC);
CREATE INDEX idx_sync_log_idempotency ON sync_log(idempotency_key);

-- RLS for sync_log (SELECT-only, membership-based)
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_sync_log ON sync_log
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = sync_log.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );
```

### 10.2 Cloud Function Updates

Modify existing CRUD functions to increment `server_version` on each write:

```sql
-- Example: update_cloud_product
-- Add: SET server_version = server_version + 1
-- Add: WHERE server_version = p_expected_version (optimistic lock)
```

### 10.3 New Cloud Functions

```sql
-- Idempotent upsert for sync
CREATE OR REPLACE FUNCTION sync_upsert_entity(
  p_shop_id UUID,
  p_entity_type TEXT,
  p_entity_id UUID,
  p_payload JSONB,
  p_idempotency_key TEXT,
  p_expected_version INTEGER
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check idempotency_key in sync_log
  -- If exists: return existing result (idempotent)
  -- If not: process upsert, log to sync_log
  -- Return {status, server_version, conflict_details}
END;
$$;
```

---

## 11. Flutter/Dart Impact

### 11.1 New Files

| File | Purpose |
|------|---------|
| `lib/sync/sync_engine.dart` | Main sync orchestrator |
| `lib/sync/sync_queue_repository.dart` | Local sync_queue CRUD |
| `lib/sync/sync_worker.dart` | Background sync worker |
| `lib/sync/conflict_resolver.dart` | Conflict detection and resolution |
| `lib/sync/hydration_service.dart` | Initial cloud-to-local load |
| `lib/sync/incremental_sync_service.dart` | Changed-since pull logic |
| `lib/sync/sync_status.dart` | Sync status model (enum + state) |
| `lib/sync/adapters/entity_sync_adapter.dart` | Base adapter interface |
| `lib/sync/adapters/product_sync_adapter.dart` | Product sync adapter |
| `lib/sync/adapters/sale_sync_adapter.dart` | Sale sync adapter |
| `lib/sync/adapters/return_sync_adapter.dart` | Return sync adapter |
| `lib/sync/adapters/expense_sync_adapter.dart` | Expense sync adapter |
| `lib/sync/adapters/expense_category_sync_adapter.dart` | Expense category sync adapter |
| `lib/sync/adapters/customer_sync_adapter.dart` | Customer sync adapter |
| `lib/sync/adapters/invoice_sync_adapter.dart` | Invoice sync adapter |
| `lib/sync/adapters/inventory_count_sync_adapter.dart` | Inventory count sync adapter |
| `lib/sync/adapters/shop_settings_sync_adapter.dart` | Shop settings sync adapter |
| `lib/errors/sync_exception.dart` | Sync-specific error types |
| `test/sync/sync_engine_test.dart` | Sync engine unit tests |
| `test/sync/sync_queue_test.dart` | Sync queue unit tests |
| `test/sync/conflict_resolver_test.dart` | Conflict resolver tests |
| `test/sync/hydration_test.dart` | Hydration tests |
| `test/sync/schema_v13_test.dart` | Schema v13 migration tests |
| `test/sync/idempotency_test.dart` | Idempotency verification tests |

### 11.2 Modified Files

| File | Change |
|------|--------|
| `app/lib/database/database_helper.dart` | Add schema v13 migration, sync queue enqueue after each write, version tracking columns |
| `app/lib/database/user_repository.dart` | Add sync_status and server_version to user CRUD |
| `app/lib/services/session_state.dart` | Add sync state notifications |
| `app/lib/widgets/sync_status_indicator.dart` | Enhanced sync status display |
| `app/lib/screens/settings_screen.dart` | Add sync status section |

### 11.3 Unchanged Files

All existing cloud repositories, services, DTOs, licensing, RBAC, auth remain unchanged. Phase H is additive.

---

## 12. Auth / Membership Integration

### 12.1 Current Chain

```
Supabase Auth (signInWithEmail)
  → CloudSession (userId, shopId, role, status)
    → PermissionSyncService (cloud→local cache)
      → PermissionResolver (owner→cloud→local→defaults)
        → DatabaseHelper enforcement points
```

### 12.2 Phase H Integration

The sync engine operates WITHIN the existing auth chain:

```
User logged in (CloudSession exists)
  → SyncEngine activated
    → SyncQueue scoped to shop_id from CloudSession
    → All sync operations use authenticated Supabase client
    → RLS policies enforce shop isolation on cloud reads
    → SECURITY DEFINER functions enforce permissions on cloud writes
```

**Critical rule:** The sync engine NEVER bypasses auth or permission checks. It operates as a downstream consumer of the existing auth infrastructure.

---

## 13. RBAC Integration

### 13.1 Permission Requirements for Sync

| Sync Operation | Required Permission | Enforcement |
|---------------|-------------------|-------------|
| Sync products | `inventory.edit` | Via existing cloud RPCs |
| Sync sales | `sales.create` | Via existing cloud RPCs |
| Sync returns | `returns.create` | Via existing cloud RPCs |
| Sync expenses | `expenses.create` | Via existing cloud RPCs |
| Sync settings | `admin.settings.access` | Via existing cloud RPCs |
| Read cloud data | Membership-based (RLS) | Via RLS SELECT policies |
| Resolve conflicts | Owner or admin | Sync engine checks role |

### 13.2 salesOnly Constraint

If OD7 (seller offline sale) is NOT allowed:
- salesOnly role cannot enqueue CREATE operations for sync
- salesOnly can only perform online (real-time) sales
- Sync engine rejects queued writes from salesOnly role

If OD7 IS allowed:
- salesOnly can create offline sales
- Sales are flagged for owner review on sync
- Server-side `require_shop_permission('sales.create')` still enforced

**Default (safe):** salesOnly offline sales are BLOCKED until OD7 is resolved.

---

## 14. Licensing Integration

### 14.1 Current Enforcement

Every business write in `DatabaseHelper` calls `_enforceLicensing()` which delegates to `CloudLicensingService.enforceActive()`.

### 14.2 Phase H Integration

- Sync engine checks license status BEFORE processing queue
- If license is expired/suspended: queue processing HALTED
- Queued writes from grace period: processed normally if grace hasn't expired
- Entitlement cache updated after each successful sync cycle
- **No change to existing enforcement points**

---

## 15. Data Ownership Model

### 15.1 Entity Authority Matrix

| Entity | Local Authority | Cloud Authority | Sync Direction | Conflict Policy |
|--------|----------------|----------------|----------------|-----------------|
| Product | Local creates, cloud stores | Server version is truth | Bidirectional | LWW (server timestamp) |
| Sale | Local creates, cloud stores | Server version is truth | Local → Cloud | Server-authoritative (each unique) |
| Return | Local creates, cloud stores | Server version is truth | Local → Cloud | Server-authoritative (each unique) |
| Expense | Local creates, cloud stores | Server version is truth | Bidirectional | LWW (server timestamp) |
| Expense Category | Local creates, cloud stores | Server version is truth | Bidirectional | LWW |
| Customer | Local creates, cloud stores | Server version is truth | Bidirectional | LWW |
| Invoice | Local creates, cloud stores | Server version is truth | Local → Cloud | Server-authoritative (number uniqueness) |
| Inventory Count | Local creates, cloud stores | Server version is truth | Local → Cloud | Latest count wins |
| Shop Settings | Local creates, cloud stores | Server version is truth | Bidirectional | LWW |
| User | Local-only (auth is cloud) | Cloud auth is truth | Cloud → Local | Cloud is authority |
| Role Permissions | Local cache | Cloud RBAC is truth | Cloud → Local | Cloud is authority |
| App Settings | Local-only | N/A | N/A | Local only |

### 15.2 ID Mapping Strategy

| Scope | ID Type | Mapping |
|-------|---------|---------|
| Local SQLite PK | INTEGER AUTOINCREMENT | Preserved (existing) |
| Cloud PK | UUID | Existing `cloud_uuid` column |
| sync_queue entry | UUID | New, generated client-side |
| sync_log entry | UUID | Server-generated |

**Mapping is already established:** `cloud_uuid` column on all 12 local tables links to cloud UUID PKs.

---

## 16. Security Model

### 16.1 Threat Model

| # | Threat | Attack Surface | Server Mitigation | Client Mitigation | Required Test |
|---|--------|---------------|-------------------|-------------------|---------------|
| T1 | Cross-shop data leakage | Sync queue | RLS policies + shop_id scoping | Queue scoped to active shop_id | RLS isolation test |
| T2 | Unauthorized INSERT via sync | Sync queue → cloud RPC | `require_shop_permission` in all functions | Sync engine checks local permission first | Permission enforcement test |
| T3 | Unauthorized UPDATE via sync | Sync queue → cloud RPC | `require_shop_permission` + version check | Sync engine checks local permission | Version conflict test |
| T4 | Unauthorized DELETE via sync | Sync queue → cloud RPC | `require_shop_permission` + soft delete | Sync engine checks local permission | Delete propagation test |
| T5 | Privilege escalation via sync | Sync engine | Cloud RBAC is authoritative | No client-side auth bypass | RBAC sync test |
| T6 | Membership spoofing | Sync queue | `shop_members` join in RLS + function | Cloud session validates membership | Membership test |
| T7 | Offline tampering | Local SQLite | N/A (local is cache) | Sync validates on reconnection | Offline integrity test |
| T8 | Replay / duplicate sync | Sync queue retry | Idempotency key in sync_log | Unique idempotency_key per enqueue | Idempotency test |
| T9 | Stale writes | Sync queue | `server_version` check on write | Detect version mismatch | Stale write test |
| T10 | ID collisions | Local INTEGER vs cloud UUID | UUID for cloud, INTEGER for local | cloud_uuid mapping preserved | ID mapping test |
| T11 | License bypass | Sync queue processing | License check before queue processing | Sync engine checks entitlement | License enforcement test |
| T12 | Direct REST/RPC abuse | Supabase client | SECURITY DEFINER + REVOKE ALL | Client only uses RPC layer | SQL security audit |
| T13 | Sync payload interception | Network | HTTPS (Supabase default) | No secrets in payload | Payload audit test |
| T14 | Queue poisoning | Local SQLite corruption | Idempotency key validation | Queue entry integrity checks | Queue integrity test |

### 16.2 Security Invariants

1. Sync engine NEVER bypasses `require_shop_permission`
2. Sync queue entries are ALWAYS scoped to `shop_id`
3. Cloud writes ALWAYS go through existing SECURITY DEFINER functions
4. Idempotency keys are ALWAYS unique (UUID v4)
5. Server version checks are ALWAYS performed before cloud writes
6. No secrets in sync payloads
7. No service_role keys in Flutter binary
8. RLS policies enforce shop isolation on all cloud reads

---

## 17. Sync / Consistency Model

### 17.1 Sync Directions

| Direction | Method | Trigger |
|-----------|--------|---------|
| Local → Cloud | SyncQueue processing | Background worker or manual trigger |
| Cloud → Local | HydrationService | Login, reconnection, manual refresh |

### 17.2 Consistency Guarantees

| Guarantee | Level | Notes |
|-----------|-------|-------|
| Read-after-write (local) | Strong | SQLite is synchronous |
| Read-after-write (cloud) | Eventual | Cloud reflects after sync |
| Multi-device consistency | Eventual | Dependent on sync frequency |
| Offline availability | Strong | Local SQLite always available |
| Conflict detection | On sync | Version mismatch detection |
| Idempotency | Per operation | Idempotency key prevents duplicates |

### 17.3 Sync Queue Processing Order

```
1. Filter queue by status = 'PENDING'
2. Sort by created_at ASC (FIFO)
3. For each entry:
   a. Check connectivity
   b. Check license status
   c. Fetch current server_version
   d. Compare with expected version
   e. If no conflict: execute cloud RPC
   f. If conflict: resolve per entity policy
   g. On success: mark SYNCED, set synced_at
   h. On failure: increment retry_count
   i. After max retries (5): mark FAILED
```

### 17.4 Retry Policy

| Attempt | Delay | Notes |
|---------|-------|-------|
| 1 | Immediate | First attempt |
| 2 | 5 seconds | Quick retry |
| 3 | 30 seconds | Exponential backoff |
| 4 | 2 minutes | Exponential backoff |
| 5 | 10 minutes | Final attempt |
| >5 | FAILED | User notified, manual retry available |

---

## 18. Migration Strategy

### 18.1 Local SQLite Migration (v9 → v13)

**Properties:**
- Forward-only
- Additive (new table + new nullable columns)
- Deterministic
- Idempotent (safe to restart)
- Zero data loss
- Backup required before execution

**Steps:**
1. Create backup with hash
2. Create `sync_queue` table
3. Add `server_version`, `sync_status`, `last_synced_at` to all 12 tables
4. Set defaults: `server_version = 0`, `sync_status = 'SYNCED'`
5. Verify migration with record counts
6. Verify backup restore works

### 18.2 Supabase Migration

**Properties:**
- Forward-only
- Additive (new columns + new table)
- Deterministic
- Idempotent
- Zero data loss

**Steps:**
1. Add `server_version INTEGER DEFAULT 1` to all 9 cloud tables
2. Create `sync_log` table
3. Add indexes on `sync_log`
4. Add RLS policy on `sync_log`
5. Update existing CRUD functions to increment `server_version`
6. Create `sync_upsert_entity` function
7. Verify with test queries

---

## 19. Error Handling

### 19.1 Sync Error Taxonomy

```dart
enum SyncErrorType {
  networkUnavailable,
  licenseExpired,
  permissionDenied,
  conflictDetected,
  idempotencyViolation,
  versionMismatch,
  serverError,
  maxRetriesExceeded,
  queueCorrupted,
  unknown,
}
```

### 19.2 Error Handling Rules

1. Network errors: queue entry stays PENDING, retry on next connectivity check
2. License errors: queue processing HALTED, entries stay PENDING
3. Permission errors: queue entry marked FAILED, user notified
4. Conflict errors: auto-resolved per policy or marked CONFLICT for manual review
5. Idempotency violations: treated as successful (already processed)
6. Version mismatches: conflict resolution triggered
7. Server errors: retry with backoff
8. Max retries exceeded: marked FAILED, user can manually retry
9. Queue corruption: rebuild from local data

---

## 20. Offline Behavior

### 20.1 Offline Operations

| Operation | Offline Behavior | Sync Behavior |
|-----------|-----------------|---------------|
| Create product | Write to SQLite + enqueue | Sync on reconnection |
| Update product | Write to SQLite + enqueue | Sync on reconnection |
| Delete product | Hard delete SQLite + enqueue DELETE | Cloud soft delete on sync |
| Create sale | Write to SQLite + enqueue | Sync on reconnection |
| Create return | Write to SQLite + enqueue | Sync on reconnection |
| Create expense | Write to SQLite + enqueue | Sync on reconnection |
| Create invoice | Write to SQLite + enqueue | Sync on reconnection |
| Save inventory count | Write to SQLite + enqueue | Sync on reconnection |
| Update settings | Write to SQLite + enqueue | Sync on reconnection |
| View dashboard | Read from SQLite | Cloud preferred when online |
| View reports | Read from SQLite | Cloud preferred when online |

### 20.2 Offline Grace Period (OD4 Default)

| License Type | Default Grace | Notes |
|-------------|---------------|-------|
| Trial | Until trial_ends_at | No additional grace |
| Paid (ACTIVE) | 7 days from last sync | Configurable by owner |
| Perpetual | 14 days from last sync | Configurable by owner |

### 20.3 Offline Sale Policy (OD7 Default)

**Default: BLOCKED for salesOnly role.**
- Owner/employee can create offline sales
- salesOnly must be online for sales
- This default is safe and reversible

---

## 21. Conflict Strategy

### 21.1 Per-Entity Resolution

| Entity | Strategy | Auto-Resolve | Manual Review |
|--------|----------|:---:|:---:|
| Product | Last-writer-wins | Yes | No |
| Sale | Server-authoritative | Yes | No |
| Return | Server-authoritative | Yes | No |
| Expense | Last-writer-wins | Yes | No |
| Expense Category | Last-writer-wins | Yes | No |
| Customer | Last-writer-wins | Yes | No |
| Invoice | Server-authoritative | Yes | No |
| Inventory Count | Latest count wins | Yes | No |
| Shop Settings | Last-writer-wins | Yes | No |

### 21.2 Conflict Resolution Flow

```
1. Detect version mismatch on cloud write
2. Fetch both versions (local payload vs cloud current)
3. Apply resolution policy:
   a. LWW: use local payload (it's more recent locally)
   b. Server-authoritative: discard local, accept cloud
   c. Latest count: compare timestamps, use newer
4. Log resolution in sync_log
5. Update local record with resolved version
6. Mark queue entry SYNCED
```

### 21.3 Future Enhancement (Phase M)

Phase M will add:
- Manual conflict review UI
- Side-by-side comparison
- Owner-selectable resolution
- Conflict history audit trail

---

## 22. Performance Considerations

### 22.1 Sync Payload Size

| Entity | Avg Record Size | 1000 Records | Notes |
|--------|----------------|--------------|-------|
| Product | ~200 bytes | ~200 KB | Compact JSON |
| Sale | ~150 bytes | ~150 KB | Compact JSON |
| Return | ~120 bytes | ~120 KB | Compact JSON |
| Expense | ~100 bytes | ~100 KB | Compact JSON |
| Customer | ~150 bytes | ~150 KB | Compact JSON |
| Invoice | ~200 bytes | ~200 KB | Compact JSON |

**Total initial hydration:** ~1-2 MB for 1000 records per entity (acceptable)

### 22.2 Optimization Strategies

1. **Batch processing:** Process queue entries in batches of 50
2. **Incremental pull:** Use `updated_at` index for changed-since queries
3. **Lazy hydration:** Only pull entities the user has accessed
4. **Compression:** Supabase handles gzip for HTTP responses
5. **Connection pooling:** Supabase SDK manages connection pool
6. **SQLite indexes:** Add indexes on `sync_status` and `created_at` for queue queries

### 22.3 Performance Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large inventory (10K+ products) | Slow initial hydration | Lazy hydration, pagination |
| Large sales history (10K+ sales) | Slow sync | Incremental sync, date-range filtering |
| Network round-trips | High latency | Batch processing, local-first |
| SQLite query cost | Slow queue processing | Indexes on sync_status |
| Memory use | Large payloads | Streaming JSON parsing |

---

## 23. Observability

### 23.1 Sync Status Tracking

| Metric | Storage | UI Display |
|--------|---------|------------|
| sync_status | sync_queue.status | Color indicator (green/orange/red) |
| last_synced_at | Per-entity column | Timestamp display |
| pending_operations | COUNT(sync_queue WHERE status='PENDING') | Badge count |
| failed_operations | COUNT(sync_queue WHERE status='FAILED') | Alert badge |
| retry_count | Per queue entry | Debug info |
| conflict_count | COUNT(sync_queue WHERE status='CONFLICT') | Alert badge |
| cloud_error classification | sync_log.conflict_details | Debug log |

### 23.2 Logging Rules

**MUST log:**
- Sync cycle start/end
- Queue entry processed (entity_type, operation, status)
- Conflict detected and resolved
- Error encountered
- Retry attempted

**MUST NOT log:**
- Passwords
- Tokens
- Service role keys
- Private credentials
- Business data payloads (only metadata)

---

## 24. Secrets Policy

### 24.1 What Phase H Uses

| Secret | Location | Access |
|--------|----------|--------|
| Supabase URL | `AppConfig` (--dart-define) | Compile-time only |
| Supabase Anon Key | `AppConfig` (--dart-define) | Compile-time only |
| Supabase Service Role | Server-side only | NEVER in Flutter |

### 24.2 What Phase H Adds

- No new secrets
- No new API keys
- No new tokens
- No new credentials
- Idempotency keys are UUIDs, not secrets

---

## 25. Platform Requirements

### 25.1 Platform Parity

| Feature | Windows | Android | Notes |
|---------|---------|---------|-------|
| Local SQLite | Yes (sqflite_ffi) | Yes (sqflite) | Same schema |
| Sync queue | Yes | Yes | Same logic |
| Background sync | Yes | Yes | Platform-appropriate |
| Connectivity check | Yes | Yes | Different APIs, same interface |
| Sync status UI | Yes | Yes | Same widget |

### 25.2 Platform-Specific Considerations

- **Windows:** Background sync via timer isolate
- **Android:** Background sync via WorkManager or similar
- **Connectivity:** Abstract connectivity checker interface
- **File paths:** Platform-appropriate SQLite location

---

## 26. Product Identity Requirement

- Brand: I Tech للتكنولوجيا
- No hardcoded shop identity in code
- Shop identity is runtime/configurable data
- All sync operations are shop-scoped
- No customer-specific defaults

---

## 27. Testing Strategy

### 27.1 Unit Tests

| Test Suite | Tests | Coverage |
|-----------|-------|----------|
| SyncEngine | 15+ | Orchestration, lifecycle, error handling |
| SyncQueueRepository | 10+ | CRUD, status transitions, cleanup |
| ConflictResolver | 10+ | Per-entity resolution, version comparison |
| HydrationService | 8+ | Initial load, incremental pull, edge cases |
| EntitySyncAdapters | 5 per adapter | Serialize/deserialize, mapping |
| SyncException | 5+ | Error types, messages |

### 27.2 Database Tests

| Test | Coverage |
|------|----------|
| Schema v13 migration | Table creation, column addition, defaults |
| sync_queue constraints | Unique idempotency_key, status values |
| Sync column defaults | server_version=0, sync_status='SYNCED' |
| Backup/restore | Migration reversible via backup |
| Record count preservation | Zero data loss verification |

### 27.3 Integration Tests

| Test | Scenario |
|------|----------|
| Offline→Online cycle | Create offline, sync on reconnection |
| Multi-device simulation | Device A creates, Device B pulls |
| Conflict resolution | Two devices edit same product |
| Idempotency | Same operation synced twice |
| License expiry during sync | Queue halted, resumed after renewal |
| Permission change during sync | Sync respects new permissions |

### 27.4 Regression Tests

- All 1025 passing tests must remain passing
- All 7 known failing widget tests (Supabase init) remain unchanged
- No new regressions introduced

---

## 28. Acceptance Criteria

### 28.1 Schema

- [ ] SQLite migration v13 completes without data loss
- [ ] sync_queue table created with all required columns
- [ ] All 12 tables have server_version, sync_status, last_synced_at
- [ ] Supabase migration adds server_version to all 9 cloud tables
- [ ] sync_log table created with RLS

### 28.2 Sync Engine

- [ ] SyncQueue.enqueue() creates valid queue entries
- [ ] SyncEngine.processQueue() processes PENDING entries in FIFO
- [ ] Idempotency keys prevent duplicate operations
- [ ] Version mismatch detected and resolved per policy
- [ ] Failed entries retry with backoff
- [ ] Max retries triggers FAILED status
- [ ] Queue cleanup removes old SYNCED entries

### 28.3 Offline

- [ ] All local operations work without network
- [ ] Queue entries created for each local write
- [ ] Queue processing resumes on reconnection
- [ ] Offline grace period enforced per license type
- [ ] salesOnly offline sales blocked by default

### 28.4 Security

- [ ] Sync engine respects require_shop_permission
- [ ] Queue entries scoped to shop_id
- [ ] No secrets in sync payloads
- [ ] RLS enforced on all cloud reads
- [ ] No permission bypass via sync

### 28.5 Testing

- [ ] All new tests pass
- [ ] All existing tests remain passing
- [ ] flutter analyze: 0 errors (warnings/info acceptable)
- [ ] Schema migration test passes
- [ ] Backup/restore test passes

---

## 29. Implementation Order

### Slice H-I01: Schema Foundation

**Objective:** Create sync_queue table and add sync columns to existing tables

**Files:**
- MODIFY: `app/lib/database/database_helper.dart` (add v13 migration)
- CREATE: `app/test/sync/schema_v13_test.dart`

**Database impact:**
- SQLite: sync_queue table, 36 new columns (3 per table x 12 tables)
- Supabase: 9 new server_version columns, sync_log table

**Security impact:** None (schema only)

**Tests:** Migration test, record count preservation, backup/restore

**Gate:** Schema v13 migration test passes, all existing tests pass

**Failure condition:** Any existing test regression

---

### Slice H-I02: Sync Queue Repository

**Objective:** Implement local sync_queue CRUD operations

**Files:**
- CREATE: `app/lib/sync/sync_queue_repository.dart`
- CREATE: `app/lib/sync/sync_status.dart`
- CREATE: `app/lib/errors/sync_exception.dart`
- CREATE: `app/test/sync/sync_queue_test.dart`

**Database impact:** None (uses sync_queue from H-I01)

**Security impact:** Queue entries scoped to shop_id

**Tests:** CRUD operations, status transitions, idempotency key uniqueness

**Gate:** All sync queue tests pass

**Failure condition:** Queue operations fail or idempotency violated

---

### Slice H-I03: Entity Sync Adapters

**Objective:** Create adapter interface and per-entity serialization

**Files:**
- CREATE: `app/lib/sync/adapters/entity_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/product_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/sale_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/return_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/expense_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/expense_category_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/customer_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/invoice_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/inventory_count_sync_adapter.dart`
- CREATE: `app/lib/sync/adapters/shop_settings_sync_adapter.dart`

**Database impact:** None

**Security impact:** Adapters serialize data for cloud RPCs (no auth changes)

**Tests:** Serialize/deserialize round-trips, edge cases

**Gate:** All adapter tests pass

**Failure condition:** Serialization mismatch between local and cloud formats

---

### Slice H-I04: Conflict Resolver

**Objective:** Implement conflict detection and per-entity resolution

**Files:**
- CREATE: `app/lib/sync/conflict_resolver.dart`
- CREATE: `app/test/sync/conflict_resolver_test.dart`

**Database impact:** None

**Security impact:** Conflict resolution respects entity authority model

**Tests:** Version comparison, LWW resolution, server-authoritative resolution

**Gate:** All conflict resolver tests pass

**Failure condition:** Incorrect conflict resolution

---

### Slice H-I05: Cloud Sync Functions

**Objective:** Create Supabase migration for server_version and sync functions

**Files:**
- CREATE: `supabase/migrations/20260820000026_phase_h_sync_core.sql`

**Database impact:**
- Supabase: server_version columns, sync_log table, sync_upsert_entity function
- Update existing CRUD functions to increment server_version

**Security impact:** New function uses SECURITY DEFINER + require_shop_permission

**Tests:** Cloud schema test, function security audit

**Gate:** Migration applies cleanly, all cloud tests pass

**Failure condition:** Migration fails or breaks existing functions

---

### Slice H-I06: Sync Engine Core

**Objective:** Implement main sync orchestrator

**Files:**
- CREATE: `app/lib/sync/sync_engine.dart`
- CREATE: `app/test/sync/sync_engine_test.dart`

**Database impact:** None (uses existing infrastructure)

**Security impact:** Engine checks permissions before each cloud operation

**Tests:** Full sync lifecycle, error handling, retry logic

**Gate:** All sync engine tests pass

**Failure condition:** Sync engine bypasses permission checks

---

### Slice H-I07: Hydration Service

**Objective:** Implement cloud-to-local data pull

**Files:**
- CREATE: `app/lib/sync/hydration_service.dart`
- CREATE: `app/lib/sync/incremental_sync_service.dart`
- CREATE: `app/test/sync/hydration_test.dart`

**Database impact:** Populates local SQLite from cloud data

**Security impact:** Hydration respects RLS (authenticated client)

**Tests:** Initial hydration, incremental pull, edge cases

**Gate:** Hydration tests pass, data integrity verified

**Failure condition:** Hydration creates duplicate or inconsistent data

---

### Slice H-I08: Background Sync Worker

**Objective:** Implement periodic background sync with connectivity awareness

**Files:**
- CREATE: `app/lib/sync/sync_worker.dart`
- MODIFY: `app/lib/services/session_state.dart` (add sync state)

**Database impact:** None

**Security impact:** Worker respects license and permission checks

**Tests:** Connectivity detection, queue processing, lifecycle

**Gate:** Worker tests pass, no resource leaks

**Failure condition:** Worker fails to process queue or leaks resources

---

### Slice H-I09: DatabaseHelper Integration

**Objective:** Wire sync queue enqueue into existing database operations

**Files:**
- MODIFY: `app/lib/database/database_helper.dart` (enqueue after each write)

**Database impact:** Each write creates sync_queue entry

**Security impact:** Enqueue inherits caller's permission context

**Tests:** Verify enqueue after each operation type, verify no regression

**Gate:** All existing tests pass, enqueue tests pass

**Failure condition:** Any existing test regression

---

### Slice H-I10: UI Integration

**Objective:** Enhance sync status indicator and add conflict display

**Files:**
- MODIFY: `app/lib/widgets/sync_status_indicator.dart`
- CREATE: `app/lib/widgets/sync_conflict_dialog.dart`
- MODIFY: `app/lib/screens/settings_screen.dart`

**Database impact:** None

**Security impact:** UI displays sync status (read-only)

**Tests:** Widget tests for new UI components

**Gate:** Widget tests pass, no visual regressions

**Failure condition:** UI shows incorrect sync status

---

### Slice H-I11: Idempotency Tests

**Objective:** Verify idempotency across all sync operations

**Files:**
- CREATE: `app/test/sync/idempotency_test.dart`

**Database impact:** None

**Security impact:** None

**Tests:** Duplicate operation detection, retry safety

**Gate:** All idempotency tests pass

**Failure condition:** Duplicate operations create duplicate records

---

### Slice H-I12: Integration Tests

**Objective:** End-to-end sync cycle tests

**Files:**
- CREATE: `app/test/sync/sync_integration_test.dart`

**Database impact:** Full sync cycle creates and syncs data

**Security impact:** Integration tests respect auth and permissions

**Tests:** Offline→online, multi-device, conflict, license expiry

**Gate:** All integration tests pass

**Failure condition:** Integration test reveals sync bug

---

### Slice H-I13: Final Regression

**Objective:** Verify no regressions across entire test suite

**Files:** None (verification only)

**Database impact:** None

**Security impact:** None

**Tests:** Full test suite

**Gate:** flutter analyze + flutter test all pass

**Failure condition:** Any new regression

---

## 30. File-by-File Expected Changes

### CREATE (25 files)

| # | File | Purpose | Phase Slice |
|---|------|---------|-------------|
| 1 | `app/lib/sync/sync_engine.dart` | Main sync orchestrator | H-I06 |
| 2 | `app/lib/sync/sync_queue_repository.dart` | Queue CRUD | H-I02 |
| 3 | `app/lib/sync/sync_worker.dart` | Background worker | H-I08 |
| 4 | `app/lib/sync/conflict_resolver.dart` | Conflict resolution | H-I04 |
| 5 | `app/lib/sync/hydration_service.dart` | Cloud→local pull | H-I07 |
| 6 | `app/lib/sync/incremental_sync_service.dart` | Changed-since pull | H-I07 |
| 7 | `app/lib/sync/sync_status.dart` | Status model | H-I02 |
| 8 | `app/lib/sync/adapters/entity_sync_adapter.dart` | Base adapter | H-I03 |
| 9 | `app/lib/sync/adapters/product_sync_adapter.dart` | Product adapter | H-I03 |
| 10 | `app/lib/sync/adapters/sale_sync_adapter.dart` | Sale adapter | H-I03 |
| 11 | `app/lib/sync/adapters/return_sync_adapter.dart` | Return adapter | H-I03 |
| 12 | `app/lib/sync/adapters/expense_sync_adapter.dart` | Expense adapter | H-I03 |
| 13 | `app/lib/sync/adapters/expense_category_sync_adapter.dart` | Category adapter | H-I03 |
| 14 | `app/lib/sync/adapters/customer_sync_adapter.dart` | Customer adapter | H-I03 |
| 15 | `app/lib/sync/adapters/invoice_sync_adapter.dart` | Invoice adapter | H-I03 |
| 16 | `app/lib/sync/adapters/inventory_count_sync_adapter.dart` | Inventory adapter | H-I03 |
| 17 | `app/lib/sync/adapters/shop_settings_sync_adapter.dart` | Settings adapter | H-I03 |
| 18 | `app/lib/errors/sync_exception.dart` | Sync errors | H-I02 |
| 19 | `app/lib/widgets/sync_conflict_dialog.dart` | Conflict UI | H-I10 |
| 20 | `supabase/migrations/20260820000026_phase_h_sync_core.sql` | Cloud migration | H-I05 |
| 21 | `app/test/sync/schema_v13_test.dart` | Schema test | H-I01 |
| 22 | `app/test/sync/sync_queue_test.dart` | Queue test | H-I02 |
| 23 | `app/test/sync/sync_engine_test.dart` | Engine test | H-I06 |
| 24 | `app/test/sync/conflict_resolver_test.dart` | Conflict test | H-I04 |
| 25 | `app/test/sync/hydration_test.dart` | Hydration test | H-I07 |
| 26 | `app/test/sync/idempotency_test.dart` | Idempotency test | H-I11 |
| 27 | `app/test/sync/sync_integration_test.dart` | Integration test | H-I12 |

### MODIFY (4 files)

| # | File | Change | Phase Slice |
|---|------|--------|-------------|
| 1 | `app/lib/database/database_helper.dart` | Add v13 migration + enqueue after writes | H-I01, H-I09 |
| 2 | `app/lib/services/session_state.dart` | Add sync state notifications | H-I08 |
| 3 | `app/lib/widgets/sync_status_indicator.dart` | Enhanced sync display | H-I10 |
| 4 | `app/lib/screens/settings_screen.dart` | Add sync status section | H-I10 |

### UNCHANGED

All existing cloud repositories, services, DTOs, licensing, RBAC, auth, models, screens remain unchanged.

---

## 31. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | Schema migration breaks existing data | Low | Critical | Backup before migration, test restore |
| R2 | Sync engine bypasses permission checks | Low | Critical | Security tests, code review |
| R3 | Idempotency keys collide | Very Low | High | UUID v4 generation |
| R4 | Conflict resolution loses data | Medium | High | Conservative LWW, manual review in Phase M |
| R5 | Background worker drains battery | Medium | Medium | Connectivity-aware, configurable intervals |
| R6 | Large sync payloads cause OOM | Low | High | Batch processing, streaming |
| R7 | Queue corruption | Low | High | Integrity checks, rebuild capability |
| R8 | License check blocks legitimate sync | Low | Medium | Grace period, clear error messages |
| R9 | OD4/OD6/OD7 defaults conflict with owner intent | Medium | Medium | Defaults are safe and reversible |
| R10 | Phase I migration depends on Phase H sync | High | High | Phase H must be complete before Phase I |

---

## 32. Rollback / Recovery Plan

### 32.1 Local Rollback

1. Restore from pre-migration backup
2. Verify record counts match
3. Resume normal operations

### 32.2 Cloud Rollback

1. Remove server_version columns (ALTER TABLE DROP COLUMN)
2. Drop sync_log table
3. Revert CRUD function changes
4. Verify existing functions work

### 32.3 Sync Queue Recovery

If sync_queue is corrupted:
1. Rebuild queue from local data + cloud_uuid mapping
2. Set all entries to PENDING
3. Reprocess on next sync cycle

---

## 33. Non-Goals

1. Real-time bidirectional push (deferred)
2. Advanced conflict resolution UI (Phase M)
3. Legacy data migration (Phase I)
4. Android implementation (Phase K/L)
5. Excel import sync (Phase N)
6. Invoice branding (Phase O)
7. Production hardening (Phase P)
8. Multi-shop sync (single shop only in Phase H)
9. Data encryption at rest (Supabase handles)
10. Custom sync intervals (fixed intervals in Phase H)

---

## 34. Definition of Done

Phase H is complete when:

1. SQLite schema v13 migration implemented and tested
2. Supabase sync migration implemented and deployed
3. Sync queue repository implemented and tested
4. All 9 entity sync adapters implemented and tested
5. Conflict resolver implemented and tested
6. Sync engine implemented and tested
7. Hydration service implemented and tested
8. Background sync worker implemented and tested
9. DatabaseHelper integration complete
10. UI enhancements complete
11. All new tests pass
12. All existing tests pass (1025+ passing, 7 known failing)
13. flutter analyze: 0 errors
14. No secrets in committed code
15. No production code regression
16. Planning artifact committed locally
17. Commit parent is Phase G implementation commit

---

## 35. Planning Verification Checklist

### BASELINE
- [x] Repository identity correct
- [x] Phase G baseline locked
- [x] Ancestry chain intact
- [x] Remote divergence = 0
- [x] All governing documents reviewed
- [x] Existing cloud schema reviewed
- [x] Local SQLite schema forensically inventoried

### DESIGN
- [x] Sync architecture defined
- [x] Entity sync matrix completed
- [x] Conflict resolution strategy defined
- [x] Offline behavior specified
- [x] Idempotency strategy defined
- [x] Security threat model completed
- [x] Error taxonomy defined
- [x] Performance considerations documented

### BOUNDARIES
- [x] Phase H/I boundary explicit
- [x] Phase H/J boundary explicit
- [x] Phase H/M boundary explicit
- [x] Open owner decisions classified (OD4/OD6/OD7 defaults set)

### DELIVERABLES
- [x] SQL migration layout defined
- [x] Dart file manifest defined (25 create, 4 modify)
- [x] Test matrix defined (13 slices)
- [x] Implementation order specified
- [x] Rollback strategy defined

### PREPARATION
- [x] No production code modified in this session
- [x] Preserved artifacts verified
- [x] Worktree integrity confirmed
- [x] Baseline tests recorded (1025 pass, 7 fail pre-existing)

**NEXT SESSION:**
Phase H Remote Planning Baseline Lock Session
