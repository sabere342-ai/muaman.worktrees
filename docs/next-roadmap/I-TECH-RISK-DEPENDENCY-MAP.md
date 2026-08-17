# I-TECH Risk and Dependency Map

## 1. Dependency Graph

```
Tier 1 (Immediate)
═══════════════════

Brand Color Consistency (GAP-01)
└── No dependencies. Standalone. Can start immediately.

Tier 2 (Domain Expansion)
═════════════════════════

Standalone Backup/Restore (GAP-02)
└── Backup: no dependencies. UI-only.
└── Restore: requires schema version compatibility design.
    └── Backup Retention: no dependencies. Policy + UI.

Expense Categories (GAP-08)
└── No dependencies. Single nullable column + UI.

Customer Master (GAP-04)
└── Customer Table + CRUD
    └── Customer History (link to invoices)
        └── Customer Balances
            └── Receivables / Collections

Thermal Printing (GAP-06)
└── Invoice Data Contract (already stable)
    └── Thermal Layout Design
        └── Physical Printer Acceptance

VAT / Tax (GAP-07)
└── Tax Rate Configuration Design
    └── Tax Calculation on Sales
    └── Tax on Returns
    └── Tax Reporting

Supplier / Purchase Domain (GAP-05)
└── [MAJOR DOMAIN EXPANSION - requires full design]
    ├── Supplier Table + CRUD
    ├── Purchase Documents (purchase + purchase_items)
    ├── Inventory Receipt
    ├── Purchase Costing
    ├── Supplier Payables
    ├── Supplier Payments
    ├── Purchase Returns
    └── Supplier Reporting

Tier 3 (Commercial / Platform)
══════════════════════════════

Licensing Hardening (GAP-03)
└── Delivery Policy
    └── Binding Strategy (machine/store/owner)
        └── Enforcement

Anti-Cloning
└── Licensing Hardening
    └── DB Encryption
    └── File Integrity

Cloud / Supabase
└── OUT OF SCOPE - separate roadmap

Android
└── OUT OF SCOPE - separate roadmap

Multi-Device Sync
└── OUT OF SCOPE - separate roadmap
```

## 2. High-Risk Domain Boundaries

### Accounting Boundary

Any future item that touches `sales`, `returns`, `expenses`, COGS, or profit calculations is in the high-risk accounting boundary. Items in this boundary:

| Item | Accounting Risk | Reason |
|---|---|---|
| VAT/Tax (GAP-07) | HIGH | Affects sale prices, COGS, profit, reporting |
| Supplier Purchases (GAP-05) | VERY HIGH | Affects inventory costing, COGS, payables |
| Customer Receivables | HIGH | Affects financial reporting |
| Multi-Currency (GAP-10) | HIGH | Affects all monetary values |

**Rule:** No item in the accounting boundary may be implemented without a prior design/contract freeze that explicitly defines accounting invariants.

### Inventory Boundary

Any future item that affects stock levels, costing, or product quantities is in the high-risk inventory boundary:

| Item | Inventory Risk | Reason |
|---|---|---|
| Supplier Purchases (GAP-05) | VERY HIGH | New stock receipt path |
| VAT/Tax (GAP-07) | MEDIUM | May affect cost price |

**Rule:** No new stock receipt path may be added without proving it does not break existing `currentQuantity` invariants.

### Identity Boundary

The following are frozen and must never be modified:

| Identity Element | Current Value | Modification Status |
|---|---|---|
| DB filename | `muaman_store.db` | FROZEN |
| Package name | `muaman_store` | FROZEN |
| Version | `1.0.0+1` | FROZEN |
| Windows CompanyName | I-TECH | FROZEN |
| Windows ProductName | I-TECH | FROZEN |
| DB schema version | 6 | Can increment for additive changes |
| `app_settings` keys | All current keys | Can add new keys, never rename/remove |

## 3. Schema Compatibility Map

| Change Type | Safe? | Example |
|---|---|---|
| New nullable column on existing table | YES | `expenses.category` |
| New table | YES | `customers`, `suppliers` |
| New `app_settings` key | YES | `licenseTrialDays` |
| New FK on existing table (nullable) | YES | `invoices.customerId` |
| Rename existing column | NO | Violates frozen identity |
| Drop column | NO | Destructive |
| Change column type | NO | May break existing data |
| Rename table | NO | Violates frozen identity |
| Change `muaman_store.db` filename | NO | FROZEN |
| Change package name | NO | FROZEN |

## 4. Frozen Identity Boundaries

The following elements are part of the T2 frozen compatibility identity and MUST NOT be modified:

1. `muaman_store.db` — database filename
2. `muaman_store` — pubspec package name
3. `1.0.0+1` — version string
4. Windows `Runner.rc` CompanyName, FileDescription, ProductName
5. Windows `CMakeLists.txt` BINARY_NAME
6. All existing `app_settings` key names (new keys may be added)
7. All existing table names (`products`, `sales`, `returns`, `expenses`, `inventory_count`, `invoices`, `import_batches`, `users`, `role_permissions`, `app_settings`)
8. All existing column names in existing tables
9. All existing permission IDs in `AppPermission` enum
10. All existing role names in `UserRole` enum

## 5. Recommended Implementation Sequence

```
1. T1-1: Brand Color Consumption (no dependencies, low risk)
   │
   ├── Accept or reject
   │
2. T2-1: Standalone Backup (no dependencies, low-medium risk)
   │
   ├── Accept or reject
   │
3. T2-2: Expense Categories (no dependencies, low risk)
   │
   ├── Accept or reject
   │
4. T2-3: Customer Master Design Freeze (no dependencies, medium risk)
   │
   ├── Accept or reject
   │
5. T2-4: Thermal Printing Design Freeze (invoice contract stable, medium risk)
   │
   ├── Accept or reject
   │
6. T3-1: Licensing Policy Design Freeze
   │
   ├── Accept or reject
   │
   [Further items require separate authorization]
```

## 6. Areas That Must Remain Separate

| Area | Reason |
|---|---|
| Cloud / Supabase | Requires independently authorized roadmap |
| Android / Mobile | Requires independently authorized roadmap |
| Multi-Device Sync | Requires Cloud first |
| Supplier / Purchase Domain | Requires full domain redesign, high accounting risk |
| VAT / Tax | Requires accounting impact analysis |
| Customer Receivables | Requires Customer Master first |
| Multi-Currency | Requires accounting redesign |
| Licensing Hardening | Requires delivery policy decision |
| Anti-Cloning | Requires licensing + encryption design |

## 7. First Step Risk Assessment

### T1-1: Brand Color Consumption

| Dimension | Assessment |
|---|---|
| Business value | HIGH —兑现 the configurable brand color promise |
| Correctness risk | NONE — no logic changes |
| Implementation risk | LOW — straightforward theme adoption |
| Dependency depth | STANDALONE |
| Compatibility impact | NONE — visual only |
| Validation cost | `flutter analyze` + visual Windows check |
| Blast radius | 7 screen files, ~25 occurrences |
| Reversibility | Fully reversible via git revert |
| Stop conditions | If >5 files require non-trivial changes |

**Conclusion:** T1-1 is the optimal first step. It is high-value, low-risk, standalone, and independently accept/rejectable.
