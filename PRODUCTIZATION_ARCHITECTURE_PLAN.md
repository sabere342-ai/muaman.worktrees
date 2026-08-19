# PRODUCTIZATION ARCHITECTURE PLAN

**Date:** 2026-08-19
**Baseline:** `6490d2f` on `codex/i-tech-next-roadmap-freeze`
**Supersedes:** V2 roadmap exclusions (Cloud, Android, multi-device)

---

## 1. Current → Target Gap Matrix

| Domain | Current | Target | Gap | Strategy | Phase |
|--------|---------|--------|-----|----------|-------|
| Product Identity | I-TECH (UI) / muaman_store (internal) | I Tech branded, no Muaman in UI | Legacy internal names frozen | Classify + freeze register | A |
| Shop Profile | Hardcoded defaults + user-editable | Dynamic onboarding, no defaults | No onboarding flow | First-run wizard | B |
| Customer Defaults | `'عميل نقدي'` default | No customer-specific defaults | Default data in production | Remove defaults | A |
| Windows | Single platform | Multi-platform | No Android | Android project + parity | K, L |
| Android | None | Full owner + employee | Complete gap | New Flutter Android target | K, L |
| SQLite | Local-only production DB | Local offline cache + cloud | No cloud sync | Cloud backend + sync layer | C, G, H |
| Cloud DB | None | Supabase PostgreSQL | Complete gap | New backend | C |
| Authentication | Local PBKDF2 users table | Cloud identity + local linking | No cloud auth | Supabase Auth | D |
| Users | 3 roles, 18 permissions, local | Cloud membership, RBAC, invites | No cloud users | Multi-tenant membership | D, F |
| Permissions | UI + DB enforcement | UI + server enforcement | Server-only = new | RLS / server functions | F |
| Multi-Tenant | Single shop | Shop-scoped isolation | No tenant concept | shop_id + RLS | B, C |
| Multi-Device | Single device | Cross-device sync | No sync | Sync queue + cloud | H |
| Licensing | Client-side Ed25519 | Cloud licensing + trial | No server | I Tech licensing service | E |
| Trial | None | 14-day server-controlled | No trial | Server trial endpoint | E |
| Sync | None | Queue-based with conflict resolution | Complete gap | Pending-write queue | H |
| Offline | Full offline (local SQLite) | Offline with sync queue | Design for dual-source | SQLite remains local cache | H |
| Inventory | Local atomic | Multi-device atomic | ConFLICT risk | Server-authoritative + conflict policy | M |
| Sales | Local atomic | Cloud + local atomic | Atomicity preservation | Transaction + sync | G, H |
| Excel Import | Fixed-path file | User-selected file (Win+Android) | Platform-specific picker | FilePicker + DocumentPicker | N |
| Invoice | A4 + thermal, local | Cross-platform, I Tech footer | No Android delivery | Platform-adaptive delivery | O |
| Backup | Local file copy | Cloud backup + local | No cloud backup | Supabase backup + local | P |

---

## 2. Keep / Extend / Migrate / Replace Matrix

| Component | Decision | Rationale |
|-----------|----------|-----------|
| SQLite (local) | **KEEP** as offline cache | Essential for offline capability; proven production use |
| `database_helper.dart` | **EXTEND** with cloud sync hooks | Core business logic is solid; add sync layer around it |
| `UserRepository` | **MIGRATE** to cloud-linked | Keep local + add cloud identity linking |
| `PermissionResolver` | **EXTEND** with server-side fallback | Add server-side validation alongside local |
| 18 permissions | **KEEP** + extend | Already correct; add cloud enforcement |
| `role_permissions` table | **KEEP** locally + cloud mirror | Local config remains for offline |
| Password hasher (PBKDF2) | **MIGRATE** to cloud auth | Link local accounts to cloud identities |
| `SessionState` | **EXTEND** with cloud session | Add cloud user context |
| `ShopProfile` | **KEEP** + extend with cloud | Already dynamic; add cloud persistence |
| PDF system | **KEEP** | Proven, works, no change needed |
| Thermal receipt | **KEEP** | Proven, works, no change needed |
| Excel parser (XlsxReader) | **KEEP** | Custom parser, no dependency issues |
| `WorkbookImporter` | **EXTEND** with file picker | Replace fixed path with user selection |
| Inno Setup installer | **KEEP** | Proven Windows delivery; Android uses Gradle |
| Build pipeline (PowerShell) | **KEEP** for Windows | Android uses separate build system |
| Licensing (client-side) | **EXTEND** with cloud backend | Client-side verification remains; add cloud activation |
| `ActivationClient` | **REPLACE** with cloud implementation | Current server is not deployed |
| `CleanStartService` | **EXTEND** with cloud data wipe | Add cloud data deletion option |
| `StandaloneBackupService` | **EXTEND** with cloud backup | Local backup remains; add cloud option |
| `StandaloneRestoreService` | **EXTEND** with cloud restore | Local restore remains; add cloud option |
| Navigation (Navigator) | **REPLACE** with GoRouter (Android) | Need deep linking + responsive layout for Android |
| Theme system | **KEEP** | Already configurable brand color |
| Shop logo | **EXTEND** with cloud storage | Current local path; add cloud storage |

---

## 3. ADR-001: Cloud/Auth/Sync Backend Selection

### Context

The project needs a cloud backend for:
- Authentication (email-based)
- Multi-tenant data storage
- Row-level authorization
- Server-side functions
- Real-time sync (future)

### Options Evaluated

#### Option A: Supabase

| Criterion | Assessment |
|-----------|------------|
| Flutter Windows support | Yes (supabase_flutter + dart directly) |
| Flutter Android support | Yes |
| PostgreSQL/relational | Yes — native PostgreSQL |
| Multi-tenancy | Yes — RLS policies per shop_id |
| RBAC | Yes — RLS + server functions |
| Row-level auth | Yes — native RLS |
| Offline strategy | Yes — local PostgREST cache pattern; or SQLite + sync |
| Pricing | Free tier generous; Pro $25/mo |
| Vendor lock-in | Moderate (PostgreSQL portable, Supabase-specific RLS) |
| Migration complexity | Medium — schema + RLS + functions |
| Security | Good — row-level security, JWT auth |
| Server-side functions | Yes — Edge Functions (Deno) or database functions |
| Email invitations | Yes — Supabase Auth with invite |
| License integration | Yes — server functions |
| Backup/export | Yes — pg_dump, Supabase dashboard |
| Egypt practicality | Good — no regional restrictions, Stripe available |

#### Option B: Firebase Auth + Firestore

| Criterion | Assessment |
|-----------|------------|
| Flutter Windows support | Yes |
| Flutter Android support | Yes |
| PostgreSQL/relational | No — Firestore is NoSQL |
| Multi-tenancy | Possible but not native |
| RBAC | Security Rules (different paradigm) |
| Offline strategy | Excellent — built-in offline persistence |
| Pricing | Free tier; scales per usage |
| Vendor lock-in | High (Firestore data model) |
| Migration complexity | High — NoSQL to relational mismatch |
| Relational suitability | Poor — no JOINs, no RLS in traditional sense |

#### Option C: Custom Backend (Django/Rails/Node)

| Criterion | Assessment |
|-----------|------------|
| Full control | Yes |
| Development effort | Very High — need backend team |
| Maintenance burden | High — server management |
| Cost | Infrastructure + ops |

### Decision

**SELECTED: Supabase**

### Rationale

1. Native PostgreSQL matches existing relational schema
2. RLS provides row-level authorization without custom server code
3. Supabase Auth handles email/password + invitations
4. Edge Functions allow license validation + trial logic
5. Flutter SDK works on both Windows and Android
6. Free tier sufficient for development + early customers
7. Data model is portable (PostgreSQL) if migration needed later

### Risk

- Vendor lock-in via RLS policies (mitigated: PostgreSQL is portable)
- Edge Functions use Deno (mitigated: simple functions, portable)

---

## 4. Multi-Tenant Model

### Conceptual Schema

```
shops
├── id (UUID, PK)
├── name
├── owner_user_id (FK → auth.users)
├── created_at
├── updated_at
└── settings (JSONB or separate table)

shop_members
├── id (UUID, PK)
├── shop_id (FK → shops)
├── user_id (FK → auth.users)
├── role_id (FK → roles)
├── status (INVITED | ACTIVE | SUSPENDED | REVOKED)
├── invited_at
├── joined_at
├── created_at
└── updated_at

roles (per-shop or global)
├── id (UUID, PK)
├── name
├── is_system (boolean — owner/employee/salesOnly are system)
└── created_at

role_permissions (per-shop)
├── role_id (FK → roles)
├── permission_id (TEXT — matches 18 existing permission IDs)
└── updated_at
```

### Key Design Decisions

1. **System roles** (owner, employee, salesOnly) are predefined per shop
2. **Custom roles** can be added in future (architecture supports it)
3. **Per-user overrides** are NOT in initial scope (too complex)
4. **Owner always has all permissions** — enforced server-side
5. **Shop isolation** via RLS: every data table has `shop_id` column, RLS policy filters by authenticated user's shop membership

### Entity Ownership Matrix

| Entity | Owner Scope | Cloud | Local | Sync | Sensitive |
|--------|------------|-------|-------|------|-----------|
| shop | tenant | Yes | Cache | Yes | Yes |
| profile (user) | user | Yes | Cache | Yes | Yes |
| shop_members | tenant | Yes | No | Yes | Yes |
| roles | tenant | Yes | Cache | Yes | No |
| role_permissions | tenant | Yes | Cache | Yes | No |
| products | tenant | Yes | Cache | Yes | No |
| sales | tenant | Yes | Cache | Yes | Yes |
| invoices | tenant | Yes | Cache | Yes | Yes |
| returns | tenant | Yes | Cache | Yes | Yes |
| expenses | tenant | Yes | Cache | Yes | Yes |
| inventory_count | tenant | Yes | Cache | Yes | No |
| expense_categories | tenant | Yes | Cache | Yes | No |
| import_batches | tenant | Yes | Cache | Yes | No |
| app_settings | tenant | Yes | Cache | Yes | No |
| licenses | tenant | Yes | Cache | Yes | Yes |
| devices | tenant | Yes | Cache | Yes | Yes |

---

## 5. Authentication & Membership Model

### Cloud Authentication Flow

```
First Run (Owner)
├── Enter shop name + owner details
├── Create cloud account (email + password)
├── Supabase Auth creates auth.users record
├── Create shop record (owner_user_id = auth user)
├── Create shop_member (owner, ACTIVE)
├── Link local user to cloud identity
└── Begin 14-day trial

Employee Invitation (Owner)
├── Owner enters employee email
├── Owner selects role + permissions
├── Server sends invitation email
├── Employee clicks link → creates account
├── Employee joins shop (shop_member: ACTIVE)
├── Employee logs in on any device
└── Sees only permitted data for their shop
```

### Account Linking Strategy

| Local User | Cloud Identity | Link Method |
|------------|---------------|-------------|
| Owner | Supabase Auth account | Created during onboarding |
| Employee | Supabase Auth account | Invitation → account creation |
| salesOnly | Supabase Auth account | Invitation → account creation |

### Legacy Password Migration

| Step | Action |
|------|--------|
| 1 | Owner creates cloud account (new password) |
| 2 | Local user record linked to cloud identity |
| 3 | Local PBKDF2 hash preserved for offline fallback |
| 4 | On cloud login: cloud password verified |
| 5 | On offline login: local PBKDF2 hash verified |
| 6 | Gradual migration: cloud becomes primary |

### Membership Lifecycle

```
INVITED → ACTIVE → SUSPENDED → REVOKED
                 ↗
         REACTIVATED (from SUSPENDED)
```

---

## 6. Authorization Model

### Current → Target Enforcement

| Layer | Current | Target |
|-------|---------|--------|
| UI | `SessionState.hasPermission()` | Same + cloud session check |
| DB | `DatabaseHelper._requirePermission()` | Same + server RLS |
| Server | None | Supabase RLS policies |

### Server-Side Authorization (Supabase RLS)

```sql
-- Example: sales table RLS
CREATE POLICY "shop_isolation" ON sales
  FOR ALL
  USING (
    shop_id IN (
      SELECT shop_id FROM shop_members
      WHERE user_id = auth.uid()
      AND status = 'ACTIVE'
    )
  );

-- Example: permission check for delete
CREATE POLICY "owner_or_manager_delete" ON sales
  FOR DELETE
  USING (
    shop_id IN (
      SELECT sm.shop_id FROM shop_members sm
      JOIN roles r ON sm.role_id = r.id
      WHERE sm.user_id = auth.uid()
      AND (r.name = 'owner' OR sm.role_id IN (
        SELECT rp.role_id FROM role_permissions rp
        WHERE rp.permission_id = 'sales.delete'
      ))
    )
  );
```

### Permission Mapping (18 Current Permissions)

| Current Permission | Cloud Enforcement | Android UI | Notes |
|-------------------|-------------------|------------|-------|
| canAccessDashboard | RLS | Yes | Read-only dashboard |
| canAccessInventory | RLS | Yes | Product listing |
| canEditProducts | RLS + mutation policy | Yes | Create/update products |
| canDeleteProducts | RLS + mutation policy | Yes | Delete products |
| canAccessSales | RLS | Yes | Sales listing |
| canCreateSales | RLS + mutation policy | Yes | Create sales |
| canViewSalesHistory | RLS | Yes | Sales reports |
| canDeleteSales | RLS + mutation policy | Yes | Delete sales |
| canAccessReturns | RLS | Yes | Returns listing |
| canCreateReturns | RLS + mutation policy | Yes | Create returns |
| canDeleteReturns | RLS + mutation policy | Yes | Delete returns |
| canAccessExpenses | RLS | Yes | Expenses listing |
| canCreateExpenses | RLS + mutation policy | Yes | Create expenses |
| canDeleteExpenses | RLS + mutation policy | Yes | Delete expenses |
| canAccessStocktake | RLS | Yes | Inventory count |
| canManageUsers | Server function | Yes | Owner/manager only |
| canManagePermissions | Server function | Yes | Owner only |
| canAccessSettings | Server function | Yes | Owner/manager only |

---

## 7. Licensing & Trial Architecture

### Licensing Service Design

```
I Tech Licensing Service (Supabase Edge Functions + DB)
├── licenses
│   ├── id (UUID)
│   ├── shop_id (FK → shops)
│   ├── license_key (TEXT, UNIQUE) — ITECH-XXXX-XXXX-XXXX-XXXX
│   ├── plan (TEXT)
│   ├── status (TRIAL | ACTIVE | EXPIRED | SUSPENDED | PERPETUAL)
│   ├── trial_started_at (TIMESTAMPTZ)
│   ├── trial_expires_at (TIMESTAMPTZ)
│   ├── activated_at (TIMESTAMPTZ)
│   ├── subscription_expires_at (TIMESTAMPTZ)
│   └── created_at
│
├── activations
│   ├── id (UUID)
│   ├── license_id (FK → licenses)
│   ├── device_id (FK → devices)
│   ├── activated_at
│   ├── last_verified_at
│   └── status
│
└── plans
    ├── id (UUID)
    ├── name
    ├── max_users
    ├── max_devices
    ├── features (JSONB)
    ├── subscription_period (monthly | annual | perpetual)
    └── price
```

### Client-Side Licensing (Extended)

```
Current Ed25519 + CBOR + DPAPI
├── RETAINED: local token verification (offline fallback)
├── ADDED: cloud activation endpoint
├── ADDED: trial status from server
├── ADDED: device registration on activation
└── ADDED: periodic server heartbeat (online)
```

### Trial Lifecycle

```
First Launch
├── Server returns trial_started_at (server time)
├── Client stores trial token locally
├── 14 days: server time checked on activation/heartbeat
├── Expiry: writes blocked, data preserved
└── License activation required to continue

States:
TRIAL_ACTIVE → LICENSED (activation)
TRIAL_ACTIVE → TRIAL_EXPIRED (14 days)
TRIAL_EXPIRED → LICENSED (activation)
LICENSED → SUSPENDED (admin action)
LICENSED → EXPIRED (subscription end)
```

### Offline Grace

- License token signed with `expires_at` + grace period
- Client accepts token within grace window without server check
- Grace duration: **Owner Decision Required** (recommend 7 days)
- On next online contact: server validates actual status

---

## 8. Multi-Device Model

### Device Registration

```
devices
├── id (UUID)
├── installation_id (UUID — generated on first launch)
├── shop_id (FK → shops)
├── user_id (FK → auth.users)
├── platform (windows | android)
├── device_name (TEXT)
├── first_seen_at (TIMESTAMPTZ)
├── last_seen_at (TIMESTAMPTZ)
├── status (ACTIVE | REVOKED | LOST)
└── created_at
```

### Device Management

- Owner sees all registered devices in Settings
- Owner can revoke device access
- Revoked device: cloud auth fails, local data preserved
- Max devices per plan (future pricing)

---

## 9. Offline & Sync Architecture

### Sync Strategy

```
Local SQLite (operational) ←→ Sync Queue ←→ Cloud (Supabase)
```

### Operations Classification

| Operation | Offline Safety | Sync Method |
|-----------|---------------|-------------|
| Product browsing | OFFLINE_SAFE | Read from local cache |
| Sale creation | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |
| Return creation | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |
| Inventory mutation | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |
| Expense creation | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |
| Dashboard/Reports | ONLINE_PREFERRED | Cloud query preferred; local fallback |
| User management | ONLINE_REQUIRED | Server operation |
| Permission changes | ONLINE_REQUIRED | Server operation |
| License activation | ONLINE_REQUIRED | Server operation |
| Device revocation | ONLINE_REQUIRED | Server operation |
| Shop settings | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |
| Excel import | OFFLINE_WITH_PENDING_SYNC | Write local → queue sync |

### Sync Queue Design

```
sync_queue
├── id (UUID)
├── entity_type (TEXT — 'product', 'sale', etc.)
├── entity_id (INTEGER — local PK)
├── operation (CREATE | UPDATE | DELETE)
├── payload (JSONB — serialized entity)
├── created_at (TIMESTAMPTZ)
├── synced_at (TIMESTAMPTZ, nullable)
├── retry_count (INTEGER)
├── status (PENDING | SYNCED | FAILED | CONFLICT)
├── conflict_data (JSONB, nullable)
├── idempotency_key (UUID)
└── shop_id (UUID)
```

### Conflict Resolution

| Entity Type | Conflict Policy |
|-------------|----------------|
| Products | Last-writer-wins (server timestamp) |
| Sales | Server-authoritative (no conflict — each sale is unique) |
| Returns | Server-authoritative (each return unique) |
| Expenses | Last-writer-wins |
| Inventory Count | Server-authoritative (latest count wins) |
| Shop Settings | Last-writer-wins |
| Permissions | Server-authoritative (owner only) |

### ID Strategy

| Scope | ID Type | Rationale |
|-------|---------|-----------|
| Local SQLite PK | INTEGER (existing) | Preserved for upgrade compatibility |
| Cloud PK | UUID v4 | Globally unique, multi-device safe |
| Mapping | `local_id ↔ cloud_uuid` table | Bidirectional lookup |

### Version Tracking

Every cloud-synced entity has:
- `server_version` (INTEGER) — incremented on each update
- `updated_at` (TIMESTAMPTZ) — last modification time
- `deleted_at` (TIMESTAMPTZ, nullable) — soft delete / tombstone

### Pending Write Queue

When offline:
1. Write to local SQLite (immediate)
2. Add entry to `sync_queue`
3. On reconnection: process queue in order
4. Each queue entry has idempotency_key for safe retry
5. Conflicts flagged for manual review or auto-resolution per policy

---

## 10. Inventory Conflict Policy

### The Problem

```
Stock = 1
Windows offline sells 1 → local stock = 0
Android offline sells 1 → local stock = 0
Both sync → Stock should be 0 but two sales happened for stock=1
```

### Policy Options

| Option | Description | Trade-off |
|--------|-------------|-----------|
| A: Server-authoritative stock | Sale requires online stock check | Prevents overselling; blocks offline sales |
| B: Offline provisional sale | Allow offline sale with sync conflict flag | Enables offline; may oversell |
| C: Stock reservation | Reserve stock on first device, sync reservation | Complex; prevents oversell; requires coordination |
| D: Negative stock allowed | Allow negative, reconcile later | Simple; may confuse users; accounting issues |

### Recommended Policy (Owner Decision Required)

**Default: Server-authoritative stock for multi-device shops.**

- Single-device shops: no conflict (current behavior preserved)
- Multi-device shops: sale creation checks server stock
- Offline mode: sale allowed if local stock > 0; flagged for server reconciliation
- Conflict detected: both sales recorded, stock adjusted to actual, alert shown to owner

### Invariants to Preserve

```
currentQuantity = openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment
```

This formula MUST remain valid at all times, even across sync.

---

## 11. Legacy Data Migration Strategy

### Migration Pipeline

```
Step 1: Pre-Migration Backup
├── Copy muaman_store.db to user-selected location
├── Compute SHA-256 hash
├── Record record counts per table
├── Record financial totals (sales, returns, expenses, COGS, profit)
└── Store backup manifest

Step 2: Create Cloud Shop
├── Generate shop UUID
├── Create shop record in Supabase
├── Link owner to shop
└── Create owner membership

Step 3: Record Mapping
├── For each local table row:
│   ├── Generate cloud UUID
│   ├── Create mapping: local_id ↔ cloud_uuid
│   └── Store in migration_mapping table
└── Preserve all existing relationships (invoice → sales, etc.)

Step 4: Upload Data
├── Upload products → cloud products (with shop_id)
├── Upload sales → cloud sales (with shop_id, cloud_uuid)
├── Upload returns → cloud returns
├── Upload expenses → cloud expenses
├── Upload invoices → cloud invoices
├── Upload customers → cloud customers
├── Upload users → cloud users (linked to auth)
├── Upload settings → cloud settings
├── Upload import_batches → cloud import_batches
└── Each upload is idempotent (safe to retry)

Step 5: Reconciliation
├── Compare record counts (local vs cloud)
├── Compare financial totals
├── Verify all relationships intact
├── Run automated verification script
└── Flag any discrepancies

Step 6: Migration Checkpoint
├── Record migration completion timestamp
├── Store migration manifest
├── Mark migration complete in local DB
└── Enable cloud sync
```

### Migration Properties

| Property | Requirement |
|----------|-------------|
| Idempotent | Safe to restart at any step |
| Restartable | Resumes from last completed step |
| Auditable | Every step logged |
| Recoverable | Backup available at all times |
| No data loss | Reconciliation required before completion |

### Financial Invariants Preserved

| Metric | Pre-Migration | Post-Migration | Must Match |
|--------|--------------|----------------|------------|
| Total sales count | N | N | Yes |
| Total sales value | X | X | Yes |
| Total COGS | Y | Y | Yes |
| Total returns count | M | M | Yes |
| Total returns value | Z | Z | Yes |
| Total expenses | W | W | Yes |
| Gross profit | X-Y | X-Y | Yes |
| Net profit | (X-Y)-W | (X-Y)-W | Yes |
| Product count | P | P | Yes |
| Current quantities | Q per product | Q per product | Yes |

---

## 12. Windows Preservation Strategy

### What Changes

| Area | Change | Risk |
|------|--------|------|
| Local DB | Remains operational cache | LOW |
| Local auth | Enhanced with cloud link | MEDIUM |
| Local licensing | Enhanced with cloud backend | MEDIUM |
| Navigation | Enhanced with responsive layout | LOW |
| UI | Responsive layout for dual-platform | LOW |

### What Does NOT Change

| Area | Status |
|------|--------|
| SQLite schema | Preserved (additive only) |
| Existing data | Zero data loss |
| Atomic sales | Preserved |
| PDF generation | Preserved |
| Thermal receipt | Preserved |
| Build pipeline | Preserved for Windows |
| Installer | Preserved (AppId frozen) |
| BINARY_NAME | Preserved |
| DB filename | Preserved |
| All existing functionality | Preserved |

---

## 13. Android Strategy

### Owner Full Capability (Phase K)

Android owner can:
- Complete first-run shop setup
- Create cloud account
- Manage shop settings
- Manage users + roles + permissions
- View dashboard + reports
- Manage products + inventory
- Process returns
- Manage expenses
- Full admin capability

### Employee/Seller Experience (Phase L)

Android seller can:
- Log in with cloud credentials
- Browse products
- Create sales
- Process returns
- Limited admin (based on permissions)

### Android Technical Decisions

| Decision | Value |
|----------|-------|
| Package ID | OWNER_DECISION_REQUIRED (recommend `com.itech.store`) |
| Min SDK | 21 (Android 5.0) |
| Target SDK | 34 |
| Architecture | Same Flutter codebase with responsive layout |
| Local storage | SQLite (same schema, sqflite package) |
| Camera barcode | Phase L+ (future feature) |
| File access | Document picker for Excel import |
| PDF delivery | Share intent / print service |

---

## 14. Excel Import Evolution

### Current State
- `WorkbookImporter` reads from hardcoded `workbookPath`
- Custom `XlsxReader` parser (no dart_html dependency)
- SHA-256 batch tracking for deduplication

### Target State (Phase N)

```
User selects file
├── Windows: FilePicker (existing package)
├── Android: DocumentPicker (storage access framework)
├── Validate workbook
├── Preview imported products
├── Confirm import
├── Atomic import with batch tracking
└── Result summary
```

### Security Requirements

| Check | Description |
|-------|-------------|
| File size | Max 10MB |
| Extension | .xlsx only |
| Content | Validate actual XLSX structure |
| SHA-256 | Track batch hash for deduplication |
| Malformed | Graceful error, no crash |
| Partial import | Atomic — all or nothing |
| Permissions | Platform-appropriate storage access |

---

## 15. Invoice Branding Evolution

### Current State
- Shop profile in header
- `InvoiceDocumentData` read model
- Support phone in footer
- No I Tech branding

### Target State (Phase O)

```
Invoice Layout:
┌─────────────────────────────┐
│ SHOP NAME (dynamic)         │
│ Owner/Manager Name          │
│ Phone | Address             │
│ Logo (if set)               │
├─────────────────────────────┤
│ Invoice lines               │
│ ...                         │
├─────────────────────────────┤
│ Totals                      │
├─────────────────────────────┤
│ "شكراً لتعاملكم معنا"       │
│ Powered by I Tech للتكنولوجيا│
└─────────────────────────────┘
```

### Platform Delivery

| Platform | Delivery Method |
|----------|----------------|
| Windows | Print dialog + PDF save (current) |
| Android | Share intent + PDF save + print service |

---

## 16. Security Architecture

### Trust Boundaries

```
Flutter Client
├── Local SQLite (encrypted at rest on Android)
├── User-selected files (Excel)
│
Cloud Backend (Supabase)
├── Authentication provider (Supabase Auth)
├── Database (PostgreSQL with RLS)
├── Edge Functions (license, trial)
├── Storage (logos, backups)
│
I Tech Licensing Service
├── License issuance
├── Trial management
├── Device management
└── Entitlement enforcement
```

### Secrets Management

| Secret | Storage |
|--------|---------|
| Supabase anon key | Flutter client (public, RLS-protected) |
| Supabase service role key | Server functions only |
| Ed25519 private key | Server functions only |
| SMTP credentials | Server functions only |
| Database password | Supabase managed |

**Rule:** No privileged secrets in Flutter binary.

### Environment Plan

| Environment | Purpose | Backend |
|-------------|---------|---------|
| Development | Local development | Supabase local / docker |
| Test | Automated tests | Supabase test project |
| Staging | Pre-production validation | Supabase staging project |
| Production | Live customers | Supabase production project |

---

## 17. Database Evolution Plan

### Schema Version Progression

| Version | Phase | Changes | Backup Required |
|---------|-------|---------|-----------------|
| 8 (current) | Baseline | Current schema | N/A |
| 9 | B | Add cloud_uuid columns, shop_id columns | Yes |
| 10 | D | Add cloud identity columns to users | Yes |
| 11 | E | Add licensing columns (trial, cloud activation) | Yes |
| 12 | G | Add sync_version, deleted_at, updated_at columns | Yes |
| 13 | H | Add sync_queue table | Yes |

### Migration Rules

1. All migrations are additive (new columns, new tables)
2. New columns are nullable with defaults
3. No column renames or drops
4. Each migration tested with backup + restore
5. Migration version incremented per phase

---

## 18. Architecture Diagrams

### Current Architecture

```
┌──────────────────────────────┐
│       Flutter Windows App     │
│  ┌─────────────────────────┐ │
│  │     UI (15 screens)     │ │
│  ├─────────────────────────┤ │
│  │  Services (12 files)    │ │
│  │  - PermissionResolver   │ │
│  │  - SessionState         │ │
│  │  - LicensingService     │ │
│  │  - ShopProfileService   │ │
│  ├─────────────────────────┤ │
│  │  Database (7 files)     │ │
│  │  - DatabaseHelper       │ │
│  │  - UserRepository       │ │
│  │  - InvoiceRepository    │ │
│  ├─────────────────────────┤ │
│  │  SQLite (muaman_store.db)│ │
│  └─────────────────────────┘ │
└──────────────────────────────┘
```

### Target Architecture

```
┌──────────────┐     ┌──────────────┐
│ Windows App  │     │ Android App  │
│ (Flutter)    │     │ (Flutter)    │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └────────┬───────────┘
                │
        ┌───────┴────────┐
        │  Shared Domain  │
        │  Layer (Flutter)│
        └───────┬────────┘
                │
       ┌────────┴────────┐
       │                 │
  ┌────┴────┐     ┌──────┴──────┐
  │ Local   │     │  Sync Layer  │
  │ SQLite  │←───→│  (Queue +    │
  │ (cache) │     │   Resolver)  │
  └─────────┘     └──────┬──────┘
                         │
                ┌────────┴────────┐
                │  Cloud Backend   │
                │  (Supabase)      │
                ├─────────────────┤
                │ Auth (email/pwd) │
                │ PostgreSQL + RLS │
                │ Edge Functions   │
                │ Storage          │
                └────────┬────────┘
                         │
                ┌────────┴────────┐
                │ I Tech Licensing │
                │ Service          │
                ├─────────────────┤
                │ License issuance │
                │ Trial mgmt      │
                │ Device mgmt     │
                └─────────────────┘
```

---

## 19. Backward Compatibility Register

| Invariant | Current Value | Classification | Migration Rule |
|-----------|--------------|----------------|----------------|
| AppId | `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` | FROZEN | Never change |
| DB filename | `muaman_store.db` | FROZEN | Never change |
| BINARY_NAME | `muaman_store` | FROZEN | Never change |
| pubspec name | `muaman_store` | FROZEN | Never change |
| DefaultDirName | `{localappdata}\Programs\muaman_store` | FROZEN | Never change |
| Window title | `I-TECH للتكنولوجيا` | FROZEN | Never change |
| All app_settings keys | Current 13 keys | FROZEN (add-only) | Never rename/remove |
| All table names | 12 tables | FROZEN (add-only) | Never rename |
| All column names | Current columns | FROZEN (add-only) | Never rename |
| All 18 permission IDs | 18 permissions | FROZEN (add-only) | Never rename |
| All 3 role names | owner, employee, salesOnly | FROZEN (add-only) | Never rename |
| Schema version | 8 | INCREMENTABLE | +1 per migration phase |
| Inventory formula | `openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment` | INVARIANT | Must always hold |
| Sale atomicity | `insertSaleAndDecrementStock` with `db.transaction()` | INVARIANT | Must survive migration |
| COGS snapshot | `costPrice` at sale time | INVARIANT | Must survive migration |

---

## 20. P1-P3 Audit Findings Disposition

| Finding | Disposition | Phase |
|---------|-------------|-------|
| P1: Zero sale price accepted | FIX_BEFORE_PRODUCTIZATION | Pre-A |
| P1: Zero cost price accepted | FIX_BEFORE_PRODUCTIZATION | Pre-A |
| P2: Product deletion orphans inventory_count | FIX_DURING_PHASE_G | G |
| P2: UI doesn't catch DB duplicate barcode | FIX_DURING_PHASE_G | G |
| P3: No negative-stock guard at DB layer | FIX_DURING_PHASE_M | M |
| P3: Race condition in sale dialog | DEFER (low risk, multi-device makes this different) | - |
| P3: Missing .trim() on some inputs | FIX_DURING_PHASE_G | G |

---

*This document is the detailed architecture plan for I Tech productization.*
*Linked from PROJECT_MASTER_PLAN.md.*
