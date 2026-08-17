# I-TECH Next Controlled Roadmap V2 Freeze

## 1. Executive Decision

**A — NEW ROADMAP FROZEN / FOLLOW ROADMAP**

The previous roadmap (V1, baseline `2295137`) has terminated after its authorization chain was fully consumed through T3-3 (`6affa41`). A fresh evidence-based reassessment of the repository has been performed. A new controlled roadmap is frozen based on verified repository state. No production implementation is authorized in this session.

## 2. Governing Baseline

| Item | Value |
|---|---|
| Repository | I-TECH / إدارة محل مؤمن |
| New baseline commit | `6affa41` (T3-3 licensing implementation) |
| Previous roadmap baseline | `2295137` (preserved as historical evidence) |
| Accepted branch | `codex/i-tech-next-roadmap-freeze` |
| DB filename | `muaman_store.db` |
| Package name | `muaman_store` |
| Version | `1.0.0+1` |
| Windows CompanyName | I-TECH |
| DB schema version | 7 |
| Test count | 690 passed, 0 failed |

## 3. Previous Roadmap Closure

| Item | Status |
|---|---|
| Roadmap V1 (baseline `2295137`) | **CLOSED** |
| Last accepted commit | `6affa41` (T3-3) |
| Governing decision | C — STOP / NEW ROADMAP AUTHORIZATION REQUIRED |
| Reopening forbidden | YES |

The V1 roadmap consumed its full authorization chain:

```
T1-1: Brand Color Fix              → ACCEPTED (ade506a)
T1-2: Backup Design Freeze         → ACCEPTED (df17d17)
T2-1: Standalone Backup            → ACCEPTED (a3dacd8)
T2-2: Expense Categories           → ACCEPTED (26cd605)
T2-3: Customer Master Design Freeze → ACCEPTED (2728419)
T2-4: Thermal Printing             → ACCEPTED (73c9498)
T3-1: Licensing Policy Freeze      → ACCEPTED (9bcc191)
T3-2: Licensing Technical Contract → ACCEPTED (798c105)
T3-3: Licensing Implementation     → ACCEPTED (6affa41)
```

## 4. Repository / Git Evidence

```
Branch:           codex/i-tech-next-roadmap-freeze
HEAD:             6affa415e527afc2bce00ddd603a1d0bbe39a5b8
Working tree:     clean (no production changes)
```

## 5. Current Application Capability Map

### Core Domain — ALL COMPLETE

| Capability | Status |
|---|---|
| Products (CRUD + stock tracking) | COMPLETE |
| Sales (CRUD + COGS + negative stock prevention) | COMPLETE |
| Returns (CRUD + stock reversal) | COMPLETE |
| Expenses (CRUD + category) | COMPLETE |
| Expense Categories (CRUD + UI) | COMPLETE |
| Inventory Count / Stocktake | COMPLETE |
| Invoices (header + items + PDF A4 + thermal 80mm) | COMPLETE |
| Workbook import (XLSX) | COMPLETE |
| Dashboard | COMPLETE |
| Sales reports (3 tabs) | COMPLETE |
| Barcode auto-generation | COMPLETE |
| Orphan integrity detection | COMPLETE |

### Productization / Configurability — ALL COMPLETE

| Feature | Status |
|---|---|
| Shop name / profile / logo | COMPLETE |
| Configurable brand color | COMPLETE |
| Button style | COMPLETE |
| 18 granular permissions | COMPLETE |
| 3 user roles (owner / employee / salesOnly) | COMPLETE |
| Default customer name | COMPLETE |
| Support phone | COMPLETE |
| Invoice title + footer | COMPLETE |
| Thermal printer config (name, paper width, copies) | COMPLETE |

### Auth / Security — ALL COMPLETE

| Capability | Status |
|---|---|
| First-owner setup | COMPLETE |
| Login / logout | COMPLETE |
| Role-based access control | COMPLETE |
| Dual-layer permission enforcement (UI + DB) | COMPLETE |
| Owner-exclusive admin powers | COMPLETE |

### Data Safety — ALL COMPLETE

| Capability | Status |
|---|---|
| Standalone backup | COMPLETE |
| Standalone restore (with pre-save) | COMPLETE |
| Clean-start with mandatory backup + confirmation | COMPLETE |
| Backup integrity verification | COMPLETE |
| Fail-closed on backup failure | COMPLETE |

### Licensing (T3) — CLIENT-SIDE COMPLETE

| Capability | Status |
|---|---|
| Ed25519 entitlement verification | COMPLETE |
| CBOR canonical serialization | COMPLETE |
| Device fingerprint | COMPLETE |
| DPAPI-protected local storage | COMPLETE |
| 13-state entitlement machine | COMPLETE |
| Write-boundary enforcement (18 methods) | COMPLETE |
| Non-destructive restricted mode | COMPLETE |
| Licensing settings UI | COMPLETE |
| Activation server | NOT DEPLOYED (separate infrastructure) |
| Production trusted keys | NOT PROVISIONED |

## 6. Remaining Gaps (Post-T3-3)

### Tier 1 — Immediate Correctness / Delivery

| Gap | Evidence | Risk | Dependency | Priority | Confidence |
|---|---|---|---|---|---|
| T4-1: Customer Master Implementation | No `customers` table; customer is free-text on invoices (T2-3 design frozen at `2728419`) | MEDIUM — enables customer history | None (design already frozen) | HIGH | PROVEN |

### Tier 2 — Core Product Capability

| Gap | Evidence | Risk | Dependency | Priority | Confidence |
|---|---|---|---|---|---|
| T5-1: VAT/Tax | No tax fields anywhere in schema or code | HIGH — accounting boundary | None | MEDIUM | PROVEN |
| T5-2: Supplier/Purchasing Domain | No supplier, purchase, or payment entities | VERY HIGH — major domain expansion | Full design freeze required | MEDIUM | PROVEN |

### Tier 3 — Commercial / Productization

| Gap | Evidence | Risk | Dependency | Priority | Confidence |
|---|---|---|---|---|---|
| T6-1: Activation Server Deployment | `ActivationClient` throws `SocketException` | MEDIUM — blocks new activations | Owner decision on delivery target | HIGH (for resale) / LOW (current shop) | PROVEN |
| T6-2: Production Key Provisioning | `_defaultTrustedKeys` empty | MEDIUM — blocks production builds | T6-1 (server must exist) | HIGH (for resale) / LOW (current shop) | PROVEN |
| T6-3: Grandfathering Policy | Owner decision needed | LOW — architecture supports all options | Owner decision | MEDIUM | OWNER DECISION |

### Tier 4 — Future / Platform

| Gap | Evidence | Risk | Dependency | Priority | Confidence |
|---|---|---|---|---|---|
| T7-1: Multi-Currency | Hardcoded EGP; no currency fields | HIGH — accounting redesign | Owner decision | LOW | PROVEN |
| T7-2: Customer Display | No secondary display support | MEDIUM — optional hardware | Hardware availability | LOW | PROVEN |
| T7-3: Barcode Scanner | No camera/scanner integration | LOW — optional hardware | Hardware availability | LOW | MEDIUM |
| T7-4: Native DPAPI FFI | PowerShell subprocess for DPAPI | LOW — performance only | None | LOW | PROVEN |

## 7. Completed / Closed Gaps (Not to Re-schedule)

| Gap | Original ID | Closure Commit |
|---|---|---|
| Hardcoded brand color | GAP-01 | `ade506a` |
| No standalone backup/restore | GAP-02 | `a3dacd8` |
| Licensing is cosmetic | GAP-03 | `6affa41` |
| No thermal/POS printing | GAP-06 | `73c9498` |
| No expense categories | GAP-08 | `26cd605` |

## 8. Licensing Position After T3-3

### Completed (commit `6affa41`)

- Full client-side licensing architecture: Ed25519, CBOR, DPAPI, device binding, state machine, enforcement, UI
- 18 business write methods protected
- Legacy MUAMAN-* keys neutralized
- Non-destructive restricted mode
- Startup initialization and enforcement wiring

### Separate Infrastructure Projects (not Flutter/Dart work)

| Item | Classification |
|---|---|
| Activation server deployment | Backend infrastructure |
| Production Ed25519 keypair generation | Server-side + build-time configuration |
| DPAPI FFI migration | Optional performance improvement |

### Owner Decisions (not engineering)

| Item | Status |
|---|---|
| Grandfathering | OWNER DECISION — architecture supports all options |
| Trial policy | OWNER DECISION — token format supports `expires_at` |
| Pricing tiers | OWNER DECISION — token format supports tier differentiation |
| Delivery target | OWNER DECISION — determines urgency of activation server |

## 9. Frozen Identity Boundaries

All elements from the V1 roadmap's frozen identity remain frozen:

| Element | Value | Status |
|---|---|---|
| DB filename | `muaman_store.db` | FROZEN |
| Package name | `muaman_store` | FROZEN |
| Version | `1.0.0+1` | FROZEN |
| Windows CompanyName | I-TECH | FROZEN |
| Windows ProductName | I-TECH | FROZEN |
| BINARY_NAME | muaman_store | FROZEN |
| DB schema version | 7 | Can increment for additive changes |
| All `app_settings` keys | Current keys | Can add, never rename/remove |
| All 11 table names | Current tables | Can add new tables |
| All existing column names | Current columns | Can add new columns (additive nullable) |
| All 18 permission IDs | Current permissions | Can add new permissions |
| All 3 role names | owner, employee, salesOnly | Can add new roles |

## 10. Explicit Exclusions

The following are OUT OF SCOPE for this roadmap:

- Cloud / Supabase / Firebase / remote backend
- Android / iOS / mobile adaptation
- Multi-device synchronization
- SaaS billing / payment gateway integration
- Online licensing server deployment (separate infrastructure)
- Database encryption
- Any modification to frozen T2 identity
- Any modification to `muaman_store.db` filename
- Any modification to package name, AppId, Windows identity
- Any modification to existing accounting logic
- Any modification to existing inventory logic
- Any new dependencies in `pubspec.yaml` unless required by an authorized step
- Any platform runner changes
- Any Android Gradle changes

## 11. Acceptance Philosophy for Future Steps

Every future executable step must:

1. Be based on verified repository evidence, not assumptions.
2. Have a clear objective, scope, and forbidden scope.
3. Have defined schema impact (prefer additive nullable).
4. Be independently committable and accept/rejectable.
5. Have defined tests (automated where possible, Windows interactive where needed).
6. Have defined rollback expectations.
7. Not modify frozen T2 identity.
8. Not open Cloud/Android scope.
9. Be easy to stop after acceptance — each step stands alone.
10. Have a single next step authorized at any time.

## 12. Roadmap Tiers

### Tier 1 — Immediate (Correctness / Delivery)

```
T4-1: Customer Master Implementation
  │   Type: Implementation (design already frozen at T2-3)
  │   Objective: Implement customer entity with CRUD, link to invoices
  │   Scope: customers table, Customer model, CRUD screen, invoice linkage
  │   Exclusions: Customer balances, receivables, history (future work)
  │   Dependencies: None (design frozen)
  │   Risk: LOW-MEDIUM
  │   Schema: Additive (new table + nullable FK)
  │
  ├── Accept or reject
  │
```

### Tier 2 — Core Product Capability

```
T5-1: VAT / Tax Design Freeze + Implementation
  │   Type: Design Freeze → Implementation
  │   Objective: Define and implement tax configuration and calculation
  │   Scope: Tax rate config, tax on sales, tax on returns, tax reporting
  │   Exclusions: Accounting audit (separate concern)
  │   Dependencies: None (but high accounting risk)
  │   Risk: HIGH — accounting boundary
  │   Schema: Additive (new columns + config)
  │
  ├── Accept or reject
  │
T5-2: Supplier / Purchase Domain Design Freeze
  │   Type: Design Freeze only
  │   Objective: Freeze design contract for supplier + purchasing domain
  │   Scope: Supplier entity, purchase documents, inventory receipt, costing
  │   Exclusions: Implementation (separate step after freeze)
  │   Dependencies: T5-1 accepted (or independent if tax excluded)
  │   Risk: VERY HIGH — major domain expansion + accounting boundary
  │   Schema: Additive (new tables)
  │
  ├── Accept or reject
  │
  [Further items require separate authorization]
```

### Tier 3 — Commercial / Productization

```
T6-1: Activation Server Deployment
  │   Type: Separate infrastructure project
  │   Objective: Deploy backend activation service
  │   Scope: Server API (activate, deactivate, transfer, support reset)
  │   Dependencies: Owner decision on delivery target
  │   Note: NOT a Flutter/Dart task
  │
T6-2: Production Key Provisioning
  │   Type: Build-time configuration
  │   Objective: Generate Ed25519 keypair, embed public key
  │   Dependencies: T6-1
  │
T6-3: Grandfathering Policy
  │   Type: Owner decision
  │   Objective: Decide migration policy for existing installations
  │   Dependencies: Owner decision
  │   Note: Architecture supports all options
```

### Tier 4 — Future / Platform

```
T7-1: Multi-Currency
T7-2: Customer Display
T7-3: Barcode Scanner Integration
T7-4: Native DPAPI FFI Migration
```

## 13. Owner Decisions

The following are genuine owner decisions that may affect roadmap prioritization:

| # | Decision | Options | Impact | Blocks Next Step? |
|---|---|---|---|---|
| 1 | Delivery target | A: Current shop only / B: Resale / C: Both | Determines urgency of activation server | NO |
| 2 | Grandfathering | A: No grandfathering / B: Grace period / C: Permanent | Migration UX | NO |
| 3 | Trial policy | A: No trial / B: Time-limited / C: Deferred | Token expiry field | NO |
| 4 | Pricing model | A: Perpetual / B: Subscription / C: Deferred | Token expiry behavior | NO |
| 5 | Customer entity priority | A: Yes (implement now) / B: No (free-text sufficient) / C: Deferred | Determines if T4-1 proceeds | **YES — blocks T4-1 authorization** |

**Decision 5 is the only decision that blocks the next implementation step.** If the owner determines that customer management is NOT a priority, then T4-1 should be replaced with a different first step.

## 14. Single Next Authorized Step

**T4-1: Customer Master Implementation**

| Aspect | Detail |
|---|---|
| Stage name | T4-1 |
| Type | Implementation (design already frozen at T2-3, commit `2728419`) |
| Objective | Implement customer entity with CRUD operations and invoice linkage |
| Why it outranks alternatives | Design already frozen; additive-only; low-medium risk; no accounting boundary; delivers tangible customer-management value |
| Exact scope | `customers` table, `Customer` model, CRUD screen, invoice `customerName` → `customerId` FK migration, invoice creation with customer selection |
| Explicit exclusions | Customer balances, receivables, payment tracking, customer history reporting, supplier domain, VAT, multi-currency |
| Dependencies | T2-3 design freeze (COMPLETE); Owner Decision #5 (customer entity priority) |
| Risk | LOW-MEDIUM |
| Schema impact | Additive — new `customers` table, nullable `customerId` FK on `invoices` |
| Acceptance criteria | 1. `customers` table exists with CRUD operations. 2. Invoice creation allows selecting existing customer or entering new name. 3. `invoices.customerName` preserved for backward compatibility. 4. `flutter analyze` passes. 5. Existing tests pass. 6. No existing functionality broken. |
| Rollback | Git revert (single commit) |

## 15. Roadmap Alignment Decision

```
A — NEW ROADMAP CAN BE FROZEN
```

The previous roadmap (V1) has terminated. A fresh evidence-based reassessment has been performed. The new roadmap (V2) is based on verified repository state at commit `6affa41`. All gaps are evidence-based, all priorities are risk-assessed, and a single next step is authorized.

---

```
I-TECH Next Controlled Roadmap V2 Freeze
Baseline: 6affa41
Status: FROZEN
Next step: T4-1 — Customer Master Implementation
```
