# PROJECT MASTER PLAN — I Tech Product

**Type:** Master Governing Document
**Supersedes:** `I-TECH-NEXT-ROADMAP-V2-FREEZE.md` (roadmap V2 for single-store Windows)
**Date:** 2026-08-19
**Baseline:** `6490d2f` on `codex/i-tech-next-roadmap-freeze`

---

## 1. Project Identity

| Field | Value |
|-------|-------|
| Manufacturer / Publisher | **I Tech للتكنولوجيا** |
| Product Marketing Name | **TBD (Owner Decision)** |
| Legacy Internal Name | `muaman_store` (frozen compatibility identifier) |
| Legacy Human Name | مؤمن (historical, not product identity) |
| Current Platform | Windows (Flutter Desktop) |
| Target Platforms | Windows + Android |
| Current Scope | Single-store, single-device, local SQLite |
| Target Scope | Multi-tenant, multi-user, multi-device, cloud-synced |

---

## 2. Institutional Ownership

**I Tech للتكنولوجيا** is the software manufacturer, publisher, license issuer, and brand owner. The "Muaman" name is a legacy customer identifier, not a product name. It must never appear as marketing identity.

### Identity Classification

| Identifier | Type | Rebrand Status |
|------------|------|----------------|
| `muaman_store` (pubspec name) | FROZEN internal compatibility | FROZEN_UNTIL_MIGRATION |
| `muaman_store.db` | FROZEN database compatibility | FROZEN_UNTIL_MIGRATION |
| `muaman_store.exe` | FROZEN binary compatibility | FROZEN_UNTIL_MIGRATION |
| `{299ADF2A-...}` AppId | FROZEN installer upgrade path | FROZEN_UNTIL_MIGRATION |
| Window title "I-TECH للتكنولوجيا" | UI-visible product identity | SAFE_TO_REBRAND (already I-TECH) |
| Installer AppName "I-TECH للتكنولوجيا" | UI-visible product identity | SAFE_TO_REBRAND (already I-TECH) |
| `defaultCustomerName = 'عميل نقدي'` | Neutral default | REMOVE (no customer-specific defaults) |

---

## 3. Source-of-Truth Report

The verified baseline is documented in:
`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`

Key facts from that report:
- DB schema version: **8**
- Tables: **12** (products, sales, returns, expenses, expense_categories, invoices, customers, users, app_settings, role_permissions, inventory_count, import_batches)
- Permissions: **18** (7 categories)
- Roles: **3** (owner, employee, salesOnly)
- Tests: **716 passing**
- Licensing: Ed25519 + CBOR + DPAPI, 13 entitlement states, 18 write-boundary methods
- Password: PBKDF2-HMAC-SHA256, 100K iterations, salt
- Atomic sales: `insertSaleAndDecrementStock` with `db.transaction()`
- Invoice: A4 PDF + 80mm thermal receipt, Arabic RTL

---

## 4. Product Principles

1. **Zero data loss** — existing customer data is sacred
2. **Atomicity survives migration** — sales, stock, returns remain transactional
3. **Dual-layer enforcement** — UI + server/database permission checks
4. **Offline by default** — the shop works without internet
5. **Server-trusted licensing** — trial and activation controlled by server time
6. **Dynamic shop identity** — no hardcoded defaults in production
7. **Additive-only schema evolution** — no destructive migrations on existing data
8. **Permission-driven UI** — role determines what you see, not what device you hold

---

## 5. Owner-Approved Product Decisions

| # | Decision | Value |
|---|----------|-------|
| D1 | Manufacturer/publisher | I Tech للتكنولوجيا |
| D2 | Muaman as product identity | FORBIDDEN |
| D3 | Shop profile | User-entered on first run |
| D4 | Customer-specific production defaults | FORBIDDEN |
| D5 | I Tech invoice signature | Required ("Powered by I Tech للتكنولوجيا") |
| D6 | Target platforms | Windows + Android |
| D7 | Owner not Windows-dependent | Yes — Android owner parity |
| D8 | Product architecture | Single product, role-based UX |
| D9 | Employee onboarding | Email-based invitation |
| D10 | Multi-user / multi-device | Yes |
| D11 | Initial license activation | Online mandatory |
| D12 | Trial period | 14 days, server-controlled |
| D13 | License scope | Shop-scoped (not device-scoped) |
| D14 | Offline capability | Required |
| D15 | Excel import source | User-selected file (no fixed path) |
| D16 | Existing data preservation | Absolute — zero data loss |

---

## 6. Open Owner Decisions

| # | Decision | Blocks |
|---|----------|--------|
| OD1 | Final product marketing name | Android package naming, marketing materials |
| OD2 | License pricing model | Subscription vs perpetual vs hybrid |
| OD3 | Max users/devices per plan | Device management UI |
| OD4 | Offline grace duration | Offline sync policy |
| OD5 | I Tech invoice footer exact text | Invoice template |
| OD6 | Negative stock policy for offline | Inventory conflict resolution |
| OD7 | Whether seller offline sale is allowed | Sync architecture |

---

## 7. Current State Summary

### Architecture
- Single Flutter Windows app
- SQLite via `sqflite_ffi` (production DB: `muaman_store.db`)
- Local-only, single-user-device model
- PBKDF2 password hashing, 3 roles, 18 permissions
- Ed25519 licensing with 13-state machine
- Atomic sales/returns with `db.transaction()`
- A4 PDF + 80mm thermal receipt invoicing

### Key Components

| Component | Current Technology | Status |
|-----------|-------------------|--------|
| Database | SQLite (sqflite_ffi) | Production |
| Auth | PBKDF2 + local users table | Production |
| Licensing | Ed25519 + CBOR + DPAPI | Client-side complete |
| Permissions | 18-enum + PermissionResolver | Dual-layer enforced |
| Invoice | pdf + printing packages | A4 + thermal |
| Excel | Custom XlsxReader + archive + xml | Working |
| Backup | StandaloneBackupService | Working |
| Build | PowerShell + Inno Setup | Deterministic |

---

## 8. Target State Summary

### Architecture
- Single Flutter product (Windows + Android)
- Cloud backend (Supabase/PostgreSQL) with local SQLite offline cache
- Multi-tenant shop isolation
- Cloud authentication with email-based invitations
- Server-enforced RBAC (not UI-only)
- Cloud licensing with 14-day trial
- Multi-device sync with conflict resolution
- Offline-capable with pending-write queue

### Identity Preservation
- All frozen identifiers (muaman_store.db, AppId, BINARY_NAME) preserved through migration
- New cloud identities use UUIDs with mapping tables
- Existing integer PKs remain as local identifiers

---

## 9. Architecture Principles

1. **Cloud authority with local cache** — server is source of truth for identity, licensing, authorization; local SQLite is operational cache
2. **UUID for cloud, integer for local** — hybrid ID strategy avoids mass migration
3. **Additive schema** — new tables/columns only; never rename/drop existing
4. **Soft delete for sync** — tombstone records instead of hard deletes
5. **Idempotent operations** — every write operation is safe to retry
6. **Progressive enhancement** — features degrade gracefully when offline
7. **Fail-closed authorization** — no permission = no access, never permissive default

---

## 10. Data Safety Principles

1. **Backup before any migration** — mandatory backup with hash + record counts
2. **Migration is restartable** — idempotent steps, no duplicate data on retry
3. **Financial invariants preserved** — sales totals, COGS, returns, expenses, profit all survive migration
4. **Reconciliation required** — record counts and financial totals match before/after
5. **Rollback possible** — every migration phase has a documented rollback path

---

## 11. Security Principles

1. **No secrets in Flutter binary** — service role keys, admin secrets stay server-side
2. **Server-enforced authorization** — RLS or server functions, not just UI checks
3. **PBKDF2 migration** — existing password hashes preserved, linked to cloud identity
4. **License tokens are signed** — Ed25519 verification, not local-only checks
5. **Device registration** — each installation tracked, revocable

---

## 12. Frozen Compatibility Register

| Element | Value | Classification | Migration Phase |
|---------|-------|---------------|----------------|
| DB filename | `muaman_store.db` | FROZEN | Phase J (local preserved) |
| pubspec name | `muaman_store` | FROZEN | Phase J+ |
| BINARY_NAME | `muaman_store` | FROZEN | Phase J+ |
| AppId | `{299ADF2A-...}` | FROZEN | Phase J (installer unchanged) |
| DefaultDirName | `{localappdata}\Programs\muaman_store` | FROZEN | Phase J |
| All app_settings keys | Current keys | FROZEN (add-only) | Never remove |
| All table names | Current 12 tables | FROZEN (add-only) | Never rename |
| All column names | Current columns | FROZEN (add-only) | Never rename |
| All 18 permission IDs | Current permissions | FROZEN (add-only) | Never rename |
| All 3 role names | owner, employee, salesOnly | FROZEN (add-only) | Never rename |
| DB schema version | 8 | Incrementable | Per-phase |

---

## 13. Phase Roadmap Overview

| Phase | Name | Objective |
|-------|------|-----------|
| A | Product Identity & Governance | Establish ownership rules, classify legacy identifiers |
| B | Shop/Tenant Foundation | Shop UUID, tenant boundaries, cloud schema plan |
| C | Cloud Backend Foundation | Supabase setup, environment, RLS baseline |
| D | Cloud Auth & Membership | Owner account, employee invites, login/logout |
| E | Licensing & Trial | I Tech licensing backend, 14-day trial |
| F | Server-Enforced Permissions | 18 permission mapping, RBAC, security tests |
| G | Cloud Data Foundation | Cloud models, CRUD, data ownership |
| H | Offline Sync Core | Sync queue, idempotency, versions, tombstones |
| I | Legacy Data Migration | Backup, shop creation, record mapping, reconciliation |
| J | Windows Cloud Transition | Windows app transitions to cloud architecture |
| K | Android Owner Foundation | Android owner onboarding, shop setup, login |
| L | Android Sales/Employee | Seller login, products, sales, returns |
| M | Inventory Conflict Hardening | Concurrency, stock conflicts, reconciliation |
| N | Cross-Platform Excel Import | File picker, preview, validation, atomic import |
| O | Invoice Branding & Delivery | Dynamic shop profile, I Tech footer, cross-platform |
| P | Production Hardening | Security, backup, chaos testing, release |

### Dependency Chain

```
A → B → C → D → E → F → G → H → I → J → K → L
                                          → M (after H+I)
                                          → N (independent after G)
                                          → O (after G)
                                          → P (final)
```

---

## 14. Phase Gate Policy

No phase advances without:
1. Planning complete
2. Implementation complete
3. Tests pass (`flutter analyze` + `flutter test`)
4. Data integrity checks (where applicable)
5. Migration tests (where applicable)
6. Clean repository
7. Local commit
8. Exit criteria verified

---

## 15. Release Policy

- Local commits only — no push/tag/deploy without explicit authorization
- Remote baseline lock is a separate session
- Each phase produces a verifiable commit
- Installer changes require 13O acceptance gate
- Schema changes require backup + migration test

---

## 16. Functional Preservation Matrix

| Current Capability | Target Status | Migration Risk |
|-------------------|---------------|----------------|
| Product CRUD | PRESERVED + cloud-synced | LOW |
| Sales (atomic) | PRESERVED + cloud-synced | MEDIUM |
| Returns (atomic) | PRESERVED + cloud-synced | MEDIUM |
| Expenses | PRESERVED + cloud-synced | LOW |
| Expense Categories | PRESERVED + cloud-synced | LOW |
| Invoices (A4) | PRESERVED + cloud-synced | LOW |
| Thermal Receipt | PRESERVED + cloud-synced | LOW |
| Dashboard | PRESERVED + cloud-enhanced | LOW |
| Reports | PRESERVED + cloud-enhanced | LOW |
| Inventory Count | PRESERVED + cloud-synced | LOW |
| Workbook Import | PRESERVED + cross-platform file picker | MEDIUM |
| Backup/Restore | PRESERVED + cloud backup option | LOW |
| Clean Start | PRESERVED + cloud data wipe option | LOW |
| 3 User Roles | PRESERVED + extended | LOW |
| 18 Permissions | PRESERVED + server-enforced | MEDIUM |
| Shop Profile | PRESERVED + dynamic onboarding | LOW |
| Licensing (client) | EXTENDED with cloud backend | MEDIUM |
| PDF Invoice | PRESERVED + Android share | LOW |
| Barcode Auto-gen | PRESERVED | NONE |

---

## 17. Roadmap Continuity

Previous roadmap V2 (`I-TECH-NEXT-ROADMAP-V2-FREEZE.md`) was frozen at baseline `6affa41` for single-store Windows work. The V2 roadmap's explicitly excluded items (Cloud, Android, multi-device) are now the primary scope of this master plan.

The V2 roadmap's open items (T4-1 Customer Master through T7-4) are either:
- **Completed** (T4-1 Customer Master is done at `601bff6`)
- **Absorbed** into this plan's phases (licensing → Phase E, permissions → Phase F)
- **Deferred** (VAT, supplier/purchase domain — not in current productization scope)

This master plan does not conflict with V2; it extends beyond V2's scope boundary.

---

## 18. Governing Document Hierarchy

```
PROJECT_MASTER_PLAN.md (this document)
├── PRODUCTIZATION_ARCHITECTURE_PLAN.md (detailed architecture + ADR)
├── PRODUCTIZATION_MIGRATION_PLAN.md (legacy data migration strategy)
├── MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md (verified baseline)
└── I-TECH-NEXT-ROADMAP-V2-FREEZE.md (historical, superseded for productization)
```

---

## 19. Verification Policy

Each phase commit must pass:
- `flutter analyze` — 0 errors, 0 warnings
- `flutter test` — all tests passing
- `git diff --check` — no conflict markers
- Schema changes: migration test with backup
- Cloud changes: integration test with test environment
- No secrets in committed code

---

*This master plan is the single source of truth for project governance and productization direction.*
