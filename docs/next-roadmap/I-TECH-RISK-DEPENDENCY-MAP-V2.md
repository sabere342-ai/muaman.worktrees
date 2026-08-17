# I-TECH Risk and Dependency Map V2

## 1. Post-T3-3 Dependency Graph

```
Tier 1 (Immediate — Correctness / Delivery)
════════════════════════════════════════════

Customer Master Implementation (T4-1)
└── Depends on: T2-3 design freeze (COMPLETE: 2728419)
└── No other dependencies. Standalone additive feature.


Tier 2 (Core Product Capability)
═════════════════════════════════

VAT / Tax Configuration (T5-1)
└── Depends on: None (can proceed independently)
└── Risk: Accounting boundary — affects sale prices, COGS, profit
└── Requires: Design freeze before implementation

Supplier / Purchase Domain (T5-2)
└── [MAJOR DOMAIN EXPANSION]
    ├── Supplier Table + CRUD
    ├── Purchase Documents (purchase + purchase_items)
    ├── Inventory Receipt
    ├── Purchase Costing
    ├── Supplier Payables
    └── Supplier Payments
└── Risk: VERY HIGH — affects inventory costing, COGS, accounting
└── Requires: Full design freeze before implementation


Tier 3 (Commercial / Productization)
═════════════════════════════════════

Activation Server Deployment (T6-1)
└── Depends on: Owner decision on delivery target
└── Type: Separate infrastructure project (not Flutter/Dart)
└── Required for: New activations in resale scenarios

Production Key Provisioning (T6-2)
└── Depends on: T6-1 (server must exist to sign tokens)
└── Type: Build-time configuration + server key generation
└── Required for: Production builds

Grandfathering Policy (T6-3)
└── Depends on: Owner decision
└── Type: Policy decision, not engineering
└── Architecture supports all options


Tier 4 (Future / Platform)
═══════════════════════════

Multi-Currency (T7-1)
└── Depends on: Owner decision on necessity
└── Risk: HIGH — affects all monetary values
└── Requires: Schema + accounting redesign

Customer Display (T7-2)
└── Depends on: Hardware availability
└── Risk: MEDIUM — optional hardware feature

Barcode Scanner Integration (T7-3)
└── Depends on: Hardware availability
└── Risk: LOW — optional hardware feature

Native DPAPI FFI Migration (T7-4)
└── Depends on: None
└── Risk: LOW — performance improvement only
└── Current PowerShell approach is functional
```

## 2. High-Risk Domain Boundaries

### Accounting Boundary

Any future item that touches `sales`, `returns`, `expenses`, COGS, or profit calculations is in the high-risk accounting boundary:

| Item | Accounting Risk | Reason |
|---|---|---|
| VAT/Tax (T5-1) | HIGH | Affects sale prices, COGS, profit, reporting |
| Supplier Purchases (T5-2) | VERY HIGH | Affects inventory costing, COGS, payables |
| Customer Receivables | HIGH | Affects financial reporting |
| Multi-Currency (T7-1) | HIGH | Affects all monetary values |

**Rule:** No item in the accounting boundary may be implemented without a prior design/contract freeze that explicitly defines accounting invariants.

### Inventory Boundary

Any future item that affects stock levels, costing, or product quantities:

| Item | Inventory Risk | Reason |
|---|---|---|
| Supplier Purchases (T5-2) | VERY HIGH | New stock receipt path |
| VAT/Tax (T5-1) | MEDIUM | May affect cost price |

**Rule:** No new stock receipt path may be added without proving it does not break existing `currentQuantity` invariants.

### Identity Boundary (FROZEN)

The following elements are part of the frozen T2 compatibility identity and MUST NOT be modified:

| Identity Element | Current Value | Status |
|---|---|---|
| DB filename | `muaman_store.db` | FROZEN |
| Package name | `muaman_store` | FROZEN |
| Version | `1.0.0+1` | FROZEN |
| Windows CompanyName | I-TECH | FROZEN |
| Windows ProductName | I-TECH | FROZEN |
| BINARY_NAME | muaman_store | FROZEN |
| DB schema version | 7 | Can increment for additive changes |
| `app_settings` keys | All current keys | Can add new keys, never rename/remove |
| All existing table names | 11 tables | Can add new tables |
| All existing column names | All columns | Can add new columns (additive nullable) |
| All existing permission IDs | 18 permissions | Can add new permissions |
| All existing role names | owner, employee, salesOnly | Can add new roles |

## 3. Schema Compatibility Map

| Change Type | Safe? | Example |
|---|---|---|
| New nullable column on existing table | YES | `expenses.category` (done in v7) |
| New table | YES | `customers`, `suppliers` |
| New `app_settings` key | YES | `thermalPrinterName` (done) |
| New FK on existing table (nullable) | YES | `invoices.customerId` (future) |
| Rename existing column | NO | Violates frozen identity |
| Drop column | NO | Destructive |
| Change column type | NO | May break existing data |
| Rename table | NO | Violates frozen identity |
| Change `muaman_store.db` filename | NO | FROZEN |
| Change package name | NO | FROZEN |

## 4. Areas That Must Remain Separate

| Area | Reason |
|---|---|
| Cloud / Supabase | Requires independently authorized roadmap |
| Android / Mobile | Requires independently authorized roadmap |
| Multi-Device Sync | Requires Cloud first |
| Supplier / Purchase Domain | Requires full domain redesign, high accounting risk |
| VAT / Tax | Requires accounting impact analysis |
| Customer Receivables | Requires Customer Master first |
| Multi-Currency | Requires accounting redesign |
| Activation Server | Separate infrastructure project |

## 5. Recommended Implementation Sequence

```
1. T4-1: Customer Master Implementation
   │   (Design already frozen at T2-3; implementation only)
   │
   ├── Accept or reject
   │
2. T5-1: VAT / Tax Design Freeze + Implementation
   │   (Requires accounting invariants document)
   │
   ├── Accept or reject
   │
3. T5-2: Supplier / Purchase Domain Design Freeze
   │   (Major domain expansion; requires comprehensive design)
   │
   ├── Accept or reject
   │
   [Further items require separate authorization]
```

## 6. First Step Risk Assessment

### T4-1: Customer Master Implementation

| Dimension | Assessment |
|---|---|
| Business value | MEDIUM — enables customer history, repeat-customer tracking |
| Correctness risk | LOW — additive schema, no existing logic changes |
| Implementation risk | LOW-MEDIUM — new table + CRUD + invoice linkage |
| Dependency depth | STANDALONE — design already frozen |
| Compatibility impact | ADDITIVE ONLY — new nullable FK on invoices |
| Validation cost | `flutter analyze` + `flutter test` + manual verification |
| Blast radius | New files + 2 modified files (database_helper, invoice_screen) |
| Reversibility | Fully reversible via git revert |
| Stop conditions | If invoice linkage requires >3 files beyond customer CRUD, stop and reassess |

**Conclusion:** T4-1 is the optimal next step. Design is already frozen, implementation is additive, risk is low-medium, and it delivers tangible customer-management value.

## 7. Areas No Longer Requiring Attention

| Area | Status | Evidence |
|---|---|---|
| Brand color consistency | RESOLVED | `ade506a` — theme-driven across 7 screens |
| Standalone backup/restore | RESOLVED | `a3dacd8` — full implementation |
| Expense categories | RESOLVED | `26cd605` — full implementation |
| Thermal/POS printing | RESOLVED | `73c9498` — full implementation |
| Licensing (client-side) | RESOLVED | `6affa41` — full implementation |
| Legacy MUAMAN-* keys | RESOLVED | Neutralized in T3-3 |
| Permission enforcement | RESOLVED | Dual-layer (UI + DB) enforcement |

---

```
I-TECH Risk and Dependency Map V2
Post-T3-3 reassessment complete.
```
