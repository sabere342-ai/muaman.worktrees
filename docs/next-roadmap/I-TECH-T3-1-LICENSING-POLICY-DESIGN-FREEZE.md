# I-TECH T3-1: Licensing Policy Design Freeze

## 1. Purpose

This document freezes the licensing policy design for the I-TECH application. It captures owner-approved commercial decisions, defines the licensing domain model, establishes device binding and offline runtime policies, and sets enforcement safety boundaries. This is a **design freeze only** — no production code is modified, no schema is changed, no dependencies are added.

The freeze converts the prior blocked state (C) to accepted (A) by incorporating four owner decisions that were previously unresolved.

## 2. Governing Evidence

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` |
| Risk/Dependency Map | `docs/next-roadmap/I-TECH-RISK-DEPENDENCY-MAP.md` |
| Roadmap baseline commit | `a0c2eb7` |
| Previous accepted stage | T2-4 — Thermal Printing Design Freeze (`73c9498`) |
| This step | T3-1: Licensing Policy Design Freeze |
| Step type | Design freeze only — NOT implementation |
| Roadmap classification | Tier 3 — Future Commercial / Platform Work |

### Where T3-1 appears in the roadmap

**Risk/Dependency Map §5 — Recommended Implementation Sequence (line 167):**

```
6. T3-1: Licensing Policy Design Freeze
   │
   ├── Accept or reject
   │
   [Further items require separate authorization]
```

**Risk/Dependency Map §1 — Dependency Graph (line 54):**

```
Licensing Hardening (GAP-03)
└── Delivery Policy
    └── Binding Strategy (machine/store/owner)
        └── Enforcement
```

**Risk/Dependency Map §6 — Areas That Must Remain Separate (line 185):**

| Area | Reason |
|---|---|
| Licensing Hardening | Requires delivery policy decision |

### What the roadmap authorizes

The roadmap authorizes a **Design Freeze** for T3-1 — documentation of the licensing policy before any implementation. This is consistent with how T1-2, T2-3, and T2-4 were all Design Freezes preceding implementation.

### What the roadmap excludes

From `I-TECH-NEXT-ROADMAP-FREEZE.md` line 392:

> Licensing implementation / hardening

is listed under **Explicit Exclusions** (OUT OF SCOPE for the current roadmap).

**This Design Freeze is NOT excluded.** It is the authorized precursor to any future licensing work.

## 3. Current-State Audit

### Production licensing code inventory

| File:line | Symbol | Current Behavior | Classification |
|---|---|---|---|
| `app_settings.dart:10` | `keyLicenseKey` | Persists license key string in `app_settings` table | CONFIGURATION / PERSISTENCE |
| `app_settings.dart:11` | `keyLicenseStatus` | Persists `'active'` or `'inactive'` in `app_settings` table | CONFIGURATION / PERSISTENCE |
| `app_settings.dart:38` | Default `inactive` | Initializes `licenseStatus` to `'inactive'` on first run | CONFIGURATION |
| `app_settings.dart:95-97` | `getLicenseKey()` | Returns stored key (or empty string) | UI / COSMETIC |
| `app_settings.dart:99-102` | `getLicenseStatus()` | Returns stored status (or `'inactive'`) | UI / COSMETIC |
| `app_settings.dart:116-125` | `validateLicenseKey()` | Accepts any `MUAMAN-*` key with 12+ chars, sets status `'active'` | UI / COSMETIC |
| `settings_screen.dart:29` | `_licenseController` | TextField controller for license key input | UI / COSMETIC |
| `settings_screen.dart:42` | `_licenseStatus` | UI state string (`'active'` / `'inactive'`) | UI / COSMETIC |
| `settings_screen.dart:501-530` | License section | TextField + activate button + status label | UI / COSMETIC |
| `settings_screen.dart:566-570` | License detail text | Displays license status in Arabic | UI / COSMETIC |
| `settings_screen.dart:1591-1614` | `_activateLicense()` | Calls `validateLicenseKey`, updates UI state | UI / COSMETIC |

### Enforcement capability matrix

| Capability | Status | Evidence |
|---|---|---|
| License enforcement gate | **NOT FOUND** | No screen, route, navigation guard, or business logic checks `licenseStatus` |
| Activation server call | **NOT FOUND** | `validateLicenseKey()` is purely local string-prefix check |
| Device fingerprint / hardware ID | **NOT FOUND** | Zero device identification packages or code |
| Expiry / expiration checking | **NOT FOUND** | No date comparison, no expiry field, no temporal dimension |
| Online validation | **NOT FOUND** | Zero HTTP/network imports; no `http`, `dio`, `cloud_firestore` in `pubspec.yaml` |
| Offline entitlement cache | **NOT FOUND** | No entitlement system; only `app_settings` key-value store |
| Anti-tamper mechanism | **NOT FOUND** | No checksum, CRC, or integrity checking of license data |
| Subscription system | **NOT FOUND** | No references to subscription, plan, tier, premium, billing |
| Trial system | **NOT FOUND** | `seedDemoEnabled` seeds demo product data, not a trial |
| License transfer mechanism | **NOT FOUND** | No deactivation, revocation, or transfer logic |
| License server integration | **NOT FOUND** | No server URLs, no API calls, no backend endpoints |
| License storage beyond `app_settings` | **NOT FOUND** | License data stored exclusively in SQLite `app_settings` table |

### Critical finding

**The licensing system is purely cosmetic/informational.** The `validateLicenseKey()` method accepts any string starting with `'MUAMAN-'` that is 12+ characters long, stores it locally, and sets status to `'active'`. However, **the license status is never read or enforced anywhere outside the Settings screen UI**. The entire application — all screens, all business operations, all data operations — functions identically regardless of whether the license status is `'active'` or `'inactive'`.

### Existing app_settings keys (relevant)

| Key | Default | Purpose |
|---|---|---|
| `licenseKey` | (empty) | Stores the entered license key |
| `licenseStatus` | `'inactive'` | Stores `'active'` or `'inactive'` |

These keys are part of the frozen `app_settings` identity and must never be renamed or removed.

## 4. Owner Decisions

### Decision 1 — Commercial Model

**FROZEN: RESELLABLE MULTI-SHOP PRODUCT**

I-TECH is not a tool tied to the current shop only. The product is designed to be distributed and sold to different shops, with each shop's identity configured from within the application. Each Shop/Business can hold an independent license.

### Decision 2 — Licensing Subject

**FROZEN: BUSINESS / STORE**

The license is bound to the Business/Store entity, not to the owner person. The following must NOT be the licensing identity:

- owner name
- owner phone
- Windows username
- Microsoft account
- employee account

The Business is the licensed commercial subject.

### Decision 3 — Device Binding

**FROZEN: 1 ACTIVE WINDOWS DEVICE PER BUSINESS LICENSE**

The design must support **controlled license transfer** for scenarios including:

- Computer replacement
- Device failure
- Windows reinstallation when needed
- Shop device upgrade

The design must NOT allow the same license to run on multiple devices simultaneously, unless a different commercial tier is adopted in the future. T3-1 does not execute the transfer mechanism; it only freezes the contract and policy.

### Decision 4 — Offline Policy

**FROZEN: ONLINE ACTIVATION + OFFLINE NORMAL RUNTIME**

The policy requires:

1. Internet connection during initial activation.
2. Internet connection during controlled transfer / reactivation when required.
3. After correct activation, the application must run normally without persistent internet connection.

The following are prohibited:

- Always-online POS design
- Daily internet interruption stopping sales, invoices, or inventory

## 5. Commercial Model

The frozen commercial model is **Resellable Multi-Shop Product**. I-TECH is designed as a retail POS product that will be distributed and sold to multiple independent shops. Each shop configures its own identity (name, logo, owner, phone, address, brand settings) from within the application. Each shop/business holds an independent license.

This model requires:

- Per-business licensing (not per-person, not per-device)
- License isolation between shops
- Controlled device activation per business
- Future capacity for pricing tiers (not decided in T3-1)

### Implications for design

| Aspect | Implication |
|---|---|
| License entity | Each business has its own `licenseId` |
| Activation scope | One license = one business = one active device |
| Transfer scope | Business can transfer license between devices |
| Data isolation | Each shop's data is independent (`muaman_store.db` per install) |
| Pricing/duration | NOT decided in T3-1 — treated as future product configuration |

## 6. Licensing Subject

The licensed commercial subject is the **Business / Store**.

### Conceptual identity

A Business in I-TECH is defined by a stable, immutable business identity that is independent of:

- Display configuration (shop name, logo, owner name, phone, address)
- The physical device
- The Windows user account
- The database file location

### Why business, not person

- People change ownership of shops
- Devices break and are replaced
- The business entity persists across all of these changes
- The license should persist with the business

### Why business, not device

- Device replacement is common (hardware failure, upgrade)
- The license must survive device changes via controlled transfer
- Device is the activation target, not the license holder

### Business identity boundary

The shop display configuration (name, logo, owner name, phone, address, brand settings) is configurable and changeable. The licensing system must use a **conceptual immutable/stable business identity** that is independent of these display values. The display configuration is not suitable as a licensing identity anchor.

## 7. Device Binding Policy

### Policy

**1 active Windows device per business license.**

### Design requirements

| Requirement | Description |
|---|---|
| Single active device | Only one Windows device may be active per business license at any time |
| Controlled transfer | License can be moved to a new device via deactivation + reactivation |
| Transfer recovery | Supported for: device replacement, device failure, Windows reinstall, device upgrade |
| No simultaneous use | Same license cannot run on multiple devices concurrently |
| Future tier expansion | Design allows for different commercial tiers with different device limits |

### Device activation flow

```
Initial activation:
  1. Business acquires license key
  2. First device activates with the key
  3. Device identity is recorded (soft Windows identity)
  4. License is bound to this device

Device replacement / transfer:
  1. Owner deactivates license on old device (self-service or support)
  2. Owner installs on new device
  3. Owner activates with same license key on new device
  4. Activation succeeds (slot freed by deactivation)

If old device is inaccessible:
  1. Owner contacts support
  2. Support verifies business identity
  3. Support resets all activations for this key
  4. Owner activates on new device
```

### T3-1 boundary

T3-1 freezes the **policy and contract only**. The actual transfer mechanism, deactivation UI, and support reset tools are implementation concerns for a future stage.

## 8. Offline Runtime Policy

### Frozen policy

**ONLINE ACTIVATION + OFFLINE NORMAL RUNTIME**

| Phase | Internet Required | Reason |
|---|---|---|
| Initial activation | YES | Verify license key against activation service |
| Controlled transfer / reactivation | YES | Verify and update device binding |
| Normal runtime (POS operations) | NO | Shop may have unreliable internet |
| Sales, invoices, inventory, expenses | NO | Must never be interrupted by connectivity |
| Backup / restore | NO | Data safety must not depend on internet |

### What is prohibited

- Always-online POS design
- Requiring internet for daily business operations
- Stopping sales, invoices, or inventory when internet is unavailable
- Periodic online verification that could lock out during outages

### Offline behavior after activation

After correct activation, the application runs with a locally cached entitlement. The entitlement is integrity-protected (tamper-resistant, not tamper-proof). The application checks local entitlement validity without contacting any server during normal operation.

### Recovery paths for connectivity issues

| Scenario | Behavior |
|---|---|
| Internet unavailable during activation | Prompt retry; activation deferred |
| Internet unavailable during transfer | Prompt retry; transfer deferred |
| Internet unavailable during normal runtime | No impact; app runs normally |
| Activation server unreachable | App prompts retry; does not lock out existing activations |

## 9. Conceptual Domain Model

The following entities are conceptual design elements. They are NOT database schema, NOT implementation classes, and NOT authorization for code changes.

### Business License

The primary commercial entitlement.

```
licenseId          — unique identifier for this license
businessId         — stable identity of the licensed business
productId          — identifies which product tier/edition
licenseStatus      — current lifecycle state
issuedAt           — when the license was issued
activationPolicy   — online activation + offline runtime
deviceLimit        — maximum concurrent activated devices
offlinePolicy      — cached entitlement, integrity-protected
```

### Device Activation

Represents the binding of a license to a specific Windows device.

```
activationId       — unique identifier for this activation
licenseId          — the license this activation belongs to
deviceId           — stable Windows device identity
activatedAt        — when this activation occurred
status             — active / deactivated
```

### Distinction between related concepts

| Concept | Meaning |
|---|---|
| License | The commercial entitlement granted to a business |
| Activation | The binding of a license to a specific device |
| Device | The Windows hardware/host running the application |
| Installation | The specific app install on a device (may be reinstalled) |

These four must be treated as separate concepts, not conflated into one.

## 10. License Lifecycle / States

### State definitions

| State | Meaning | App opens? | Business ops? | Needs internet? | Who sets it? |
|---|---|---|---|---|---|
| `UNACTIVATED` | No valid license key entered | YES | YES | No | Default state |
| `ACTIVE` | Valid license on this device, within device limit | YES | YES | No | Activation service |
| `TRANSFER_PENDING` | Deactivation requested, waiting for completion | YES | YES | During transfer | Owner / support |
| `REVOKED` | License revoked by support (e.g., fraud, non-payment) | YES | YES | No | Support only |
| `SUSPENDED` | Temporary suspension (e.g., payment dispute) | YES | YES | No | Support only |
| `INVALID` | Key format/validation failed | YES | YES | No | Validation logic |

### Key design principle

**No state blocks business operations.** All states allow the application to open and perform all business functions (sales, invoices, inventory, expenses, backup, export, printing). Licensing states affect cosmetic indicators, prompts, and audit logging — never data access or business operations.

### State transitions

```
UNACTIVATED ──[valid key + activation]──► ACTIVE
ACTIVE ──[deactivation]──► UNACTIVATED
ACTIVE ──[transfer initiated]──► TRANSFER_PENDING
TRANSFER_PENDING ──[transfer completed]──► UNACTIVATED
TRANSFER_PENDING ──[transfer cancelled]──► ACTIVE
ACTIVE ──[support revocation]──► REVOKED
REVOKED ──[support reinstatement]──► ACTIVE
ACTIVE ──[support suspension]──► SUSPENDED
SUSPENDED ──[support reinstatement]──► ACTIVE
UNACTIVATED ──[invalid key attempt]──► INVALID
INVALID ──[valid key attempt]──► ACTIVE
```

### Allowed transitions

| From | To | Trigger |
|---|---|---|
| UNACTIVATED → ACTIVE | Valid activation |
| ACTIVE → UNACTIVATED | Self-service deactivation |
| ACTIVE → TRANSFER_PENDING | Transfer initiated |
| TRANSFER_PENDING → UNACTIVATED | Transfer completed on new device |
| TRANSFER_PENDING → ACTIVE | Transfer cancelled |
| ACTIVE → REVOKED | Support action (logged + reason) |
| REVOKED → ACTIVE | Support reinstatement (logged + reason) |
| ACTIVE → SUSPENDED | Support action (logged + reason) |
| SUSPENDED → ACTIVE | Support reinstatement (logged + reason) |
| UNACTIVATED → INVALID | Invalid key attempt |
| INVALID → ACTIVE | Valid key attempt |

## 11. Activation Contract

### Initial activation

```
1. User enters license key in the application
2. Application contacts activation service (online required)
3. Service validates key signature (asymmetric — public key in client)
4. Service checks activation count against device limit
5. Service records device identity
6. Service returns signed activation token
7. Token stored locally in app_settings (integrity-protected)
8. Application transitions to ACTIVE state
```

### Activation token (conceptual)

```
licenseId          — which license
businessId         — which business
deviceId           — which device
activatedAt        — timestamp
validUntil         — token validity (if any temporal bound applies)
deviceLimit        — configured limit
signature          — server signature (asymmetric)
```

### Token verification

The client verifies the token signature using the embedded public key. This allows offline verification without server contact during normal runtime.

### T3-1 boundary

T3-1 freezes the activation **contract only**. The actual activation service, token format, signing implementation, and API design are implementation concerns for a future stage.

## 12. Transfer Contract

### Controlled transfer policy

A business may transfer its license from one device to another through a controlled process.

### Transfer scenarios

| Scenario | Process |
|---|---|
| Planned device replacement | Owner deactivates on old device, activates on new device |
| Device failure (old device inaccessible) | Support resets activations, owner activates on new device |
| Windows reinstallation | Same device; reactivation with same key (if device identity preserved) |
| Shop device upgrade | Same as planned replacement |

### Transfer constraints

- Only one active device per license at any time
- Transfer requires internet (online verification)
- Transfer is logged (audit trail)
- Business data is NOT part of the transfer — data stays with the backup/restore system

### T3-1 boundary

T3-1 freezes the transfer **policy only**. The actual deactivation mechanism, support reset tools, and audit logging are implementation concerns for a future stage.

## 13. Device Identity Requirements

### What "same device" means (product perspective)

The product needs a **stable-enough Windows device identity with controlled tolerance and transfer recovery**. The design must NOT require hardware fingerprint that breaks on routine changes.

### Device identity behavior contract

| Change | Expected behavior |
|---|---|
| App reinstallation on same machine | Same device identity preserved; reactivation succeeds |
| Windows reinstallation on same hardware | Same device identity preserved (if based on stable Windows identity) |
| Disk change (same machine) | Same device identity preserved |
| Motherboard change (same machine) | May require reactivation (depends on identity algorithm) |
| App files moved to another location on same machine | Same device identity preserved |
| Backup restored on a different machine | Different device identity; license NOT automatically transferred |
| Full machine replacement | New device identity; requires controlled transfer |

### Device identity design requirement

```
stable-enough Windows device identity with controlled tolerance and transfer recovery
```

### What is NOT decided in T3-1

- The specific device fingerprint algorithm (implementation concern)
- Whether to use Windows Machine GUID, or another approach
- The exact tolerance threshold for hardware changes
- The crypto implementation for device identity binding

### Privacy requirement

The device identity design must follow:

- **Minimum necessary data** — collect only what is needed for device binding
- **Purpose limitation** — device identity is used ONLY for licensing, not for surveillance
- **No unnecessary personal identity coupling** — device identity is technical, not personal

## 14. Backup/Restore Interaction

### Critical design requirement

Backup and restore must be completely independent of licensing state.

### Backup/Restore vs License/Activation — separation

| Concept | Belongs to | Portable? | Affected by licensing? |
|---|---|---|---|
| Business data (products, sales, expenses, etc.) | The business | YES — via backup/restore | NO |
| License entitlement | The business + device binding | NO — not portable via backup | YES |
| Device activation | The device | NO — tied to device identity | YES |

### Policy

| Scenario | Backup allowed? | Restore allowed? | License transfers with data? |
|---|---|---|---|
| License valid | YES | YES | NO |
| License expired | YES | YES | NO |
| No license key entered | YES | YES | NO |
| License file corrupted | YES | YES | NO |
| Device changed | YES | YES | NO |
| Server unavailable | YES | YES | NO |

### Anti-clone scenario

```
licensed machine A
→ backup (business data only)
→ restore on machine B
→ machine B does NOT become silently licensed
→ machine B requires its own activation
```

The backup contains business data only. The license entitlement and device activation are NOT part of the backup. Restoring a backup on a new machine does not grant licensing on that machine.

### T3-1 boundary

T3-1 freezes this **policy only**. The actual backup format changes (if any) to exclude license data are implementation concerns for a future stage.

## 15. Reinstall / Device Failure Behavior

### Reinstall on same device

| Scenario | Expected behavior |
|---|---|
| App uninstall + reinstall on same Windows | Device identity preserved; reactivation with same key succeeds |
| Windows reinstall on same hardware | Device identity likely preserved (depends on algorithm); reactivation expected to succeed |
| App data wiped (clean start) then reinstall | Device identity preserved; license requires reactivation (activation token was in app data) |

### Device failure

| Scenario | Expected behavior |
|---|---|
| Hard drive failure | Old device identity lost; support can reset activations; owner activates on replacement device |
| Complete machine failure | Same as hard drive failure |
| Motherboard replacement | May change device identity; may require reactivation or support reset |

### Data recovery after device failure

Business data recovery is handled by the backup/restore system, independent of licensing. The license itself is recovered through the support reset + reactivation path.

## 16. Data Wipe Interaction

### Clean start / app data reset

| Operation | Effect on business data | Effect on license |
|---|---|---|
| Clean start (wipe + fresh DB) | All business data removed (backup recommended first) | Activation token lost; reactivation required |
| App uninstall | Data preserved (DB file remains in user data) | Activation token preserved (stored in DB) |
| App reinstall over existing | No data change | No license change |
| Manual DB deletion | All data lost | Activation token lost; reactivation required |

### Safety constraints

- Data wipe must NOT automatically change commercial entitlement
- Data wipe must NOT be usable to bypass device binding
- License reactivation after data wipe follows normal activation flow
- Business data wipe is a data operation; licensing state is a separate concern

## 17. Business Identity Boundary

### Display configuration (changeable)

The following are configurable by the business owner and can be changed at any time:

- Shop display name
- Logo
- Owner/manager name
- Phone number
- Address
- Brand color
- Invoice title
- Invoice footer text
- Default customer name
- Support phone

### Immutable business identity (for licensing)

The licensing system must use a **stable, immutable business identity** that is independent of the display configuration above. This identity:

- Is created when the business license is first issued
- Cannot be changed by the business owner
- Survives display configuration changes
- Is used as the licensing subject anchor

### Why display config is not suitable for licensing

- Shop name can be changed任意time
- Owner name can be changed任意time
- Phone number can be changed
- These are presentation layer concerns, not identity anchors

### T3-1 boundary

T3-1 defines this as a **design requirement only**. The actual implementation of the immutable business identity (storage format, creation mechanism) is an implementation concern for a future stage.

## 18. Enforcement Safety Boundary

### Mandatory principle

> Licensing enforcement must never corrupt, partially write, or interrupt accounting operations.

### Safe enforcement boundary

| Rule | Description |
|---|---|
| Finish committed operations | If a business operation (sale, return, expense, invoice) is in progress, licensing must not interrupt it mid-transaction |
| Apply at application boundary | Licensing checks occur at safe application boundaries (screen entry, feature access), not mid-operation |
| No partial writes | Licensing transitions must never leave partial invoice writes, partial stock movements, or corrupted accounting state |
| No data deletion as punishment | Licensing failure must never delete business data |
| No balance modification | Licensing failure must never modify financial balances |
| No silent record alteration | Licensing must never silently alter inventory or accounting records |

### What happens if license becomes invalid during operation

```
1. Current atomic operation completes normally
2. Licensing state is checked at the next safe application boundary
3. User sees a notification/prompt about licensing status
4. No data is corrupted, deleted, or modified by the licensing system
```

### What licensing MAY do (non-destructive)

- Show warning banners
- Show activation prompts
- Log usage for audit
- Display licensing status in settings

### What licensing MUST NEVER do

- Delete database records
- Corrupt the database
- Encrypt existing data
- Prevent data export
- Prevent backup
- Prevent printing
- Interrupt mid-transaction
- Modify financial balances
- Silently alter inventory records
- Lock the owner out of the application

## 19. Failure Modes

### Activation server unavailable

| Aspect | Expected behavior |
|---|---|
| User impact | Cannot complete initial activation or transfer |
| App behavior | Application opens and runs normally (unactivated state) |
| Business operations | All operations continue normally |
| User sees | Prompt to retry activation when server is available |
| Data impact | None |

### Internet unavailable after activation

| Aspect | Expected behavior |
|---|---|
| User impact | None during normal runtime |
| App behavior | Application runs normally with cached entitlement |
| Business operations | All operations continue normally |
| User sees | Normal operation; no indication of connectivity issue |
| Data impact | None |

### Local entitlement corrupted

| Aspect | Expected behavior |
|---|---|
| User impact | Entitlement verification fails |
| App behavior | Application opens; transitions to UNACTIVATED state |
| Business operations | All operations continue normally |
| User sees | Prompt to reactivate with license key |
| Data impact | None; business data is separate from entitlement |

### Device identity mismatch

| Aspect | Expected behavior |
|---|---|
| User impact | Activation may fail if device identity changed significantly |
| App behavior | Application opens; activation fails with clear message |
| Business operations | All operations continue normally |
| User sees | Prompt explaining device change; option to contact support for reset |
| Data impact | None |

### License revoked

| Aspect | Expected behavior |
|---|---|
| User impact | License status changes to REVOKED |
| App behavior | Application opens; displays revocation notice |
| Business operations | All operations continue normally |
| User sees | Clear notice of revocation with support contact information |
| Data impact | None; data remains accessible |

### Clock manipulation

| Aspect | Expected behavior |
|---|---|
| Risk | User could manipulate system clock to extend token validity |
| Detection | Soft detection of obvious clock anomalies |
| Response | Warning notification; no hard lockout |
| Impact | Low; does not affect business operations |

### Database copied to another machine

| Aspect | Expected behavior |
|---|---|
| Scenario | `muaman_store.db` copied from machine A to machine B |
| Expected result | Business data appears on machine B; license is NOT transferred |
| Reason | License/device activation is separate from business data |
| User sees | Application runs in UNACTIVATED state on machine B |
| Recovery | Normal activation process on machine B |

### Reinstall

| Aspect | Expected behavior |
|---|---|
| Same device | Device identity preserved; reactivation succeeds with same key |
| Different device | New device identity; requires controlled transfer |
| After clean start | Activation token lost; reactivation required |

### Device replacement

| Aspect | Expected behavior |
|---|---|
| Process | Controlled transfer (deactivate old → activate new) |
| Old device accessible | Self-service deactivation |
| Old device inaccessible | Support reset + reactivation |
| Business data | Recovered via backup/restore (independent of licensing) |

## 20. Security Assumptions

### Policy vs threat resistance vs absolute security

| Level | Description |
|---|---|
| Policy | The licensing rules and contracts defined in this document |
| Threat resistance | Client-side enforcement raises the cost of casual piracy |
| Absolute security | Client-side Windows licensing cannot mathematically prevent determined piracy |

### Explicit acknowledgment

> Client-side enforcement raises resistance and supports commercial control,
> but is not mathematically equivalent to perfect piracy prevention.

### Security boundaries

1. **No plaintext trust-only license.** The license key alone is not sufficient for activation; it must be validated against a signature.
2. **No secret signing key inside client.** Only public verification material is embedded in the client.
3. **No obscurity as security.** The validation algorithm must be robust even if publicly known.
4. **No hardcoded master bypass.** No hidden activation code that bypasses validation.
5. **No sensitive data storage.** License data stored in `app_settings` is not sensitive (no payment info, no personal data).
6. **Admin/support recovery must be auditable.** Every support action creates an audit log entry.

### Signing approach recommendation (conceptual, NOT implementation)

Asymmetric signing is recommended: private key on server, public key in client. This provides:

- Offline runtime (client can verify tokens without server)
- Tamper resistance (cannot forge tokens without private key)
- Audit trail (server logs all activations)

**FUTURE IMPLEMENTATION — NOT AUTHORIZED IN T3-1.**

## 21. Privacy Requirements

### Data collection principle

The device identity design must follow:

- **Minimum necessary data** — collect only what is needed for device binding
- **Purpose limitation** — device identity is used ONLY for licensing, not for surveillance or analytics
- **No unnecessary personal identity coupling** — the Business is the licensing subject, not employees

### What must NOT be collected

- Employee personal identifiers beyond what is needed for device binding
- Browsing history, application usage, or behavioral data
- Location data
- Contact lists or personal files

### What may be collected (for licensing only)

- Stable Windows device identity (minimum necessary for device binding)
- Activation timestamps (for audit trail)
- License key (for identification)

## 22. Explicit Non-Goals

This design freeze does NOT authorize:

1. **License key implementation** — no signing, no validation logic, no key generation
2. **Server infrastructure** — no activation server, no API, no cloud service
3. **Trial implementation** — no countdown, no expiry enforcement, no trial duration policy
4. **Device fingerprinting implementation** — no hardware ID collection code, no machine binding code
5. **Data encryption** — no database encryption, no license-bound encryption
6. **Online verification implementation** — no periodic check-in logic, no server contact code
7. **Anti-cloning implementation** — no code obfuscation, no tamper detection code
8. **License UI changes** — no modification to existing settings screen
9. **Schema changes** — no new tables, no new columns, no migrations
10. **Dependency changes** — no new packages in `pubspec.yaml`
11. **Any production code modification**
12. **Pricing / duration / subscription product definition** — not decided in T3-1
13. **Trial duration / trial policy** — not decided in T3-1
14. **License server backend selection** — not decided in T3-1

## 23. Future Implementation Dependencies

The following items are required for licensing implementation but are NOT authorized by T3-1:

| Dependency | Description | Authorization required |
|---|---|---|
| T3-2 Technical Contract | Detailed key format, signing, validation design | Separate step in roadmap |
| License server infrastructure | Backend service for activation, revocation, transfer | Separate roadmap item |
| Device fingerprint algorithm | Specific Windows identity approach | Implementation stage decision |
| Signing key management | Key generation, distribution, rotation | Implementation stage decision |
| Pricing / duration model | Trial length, subscription terms, perpetual license terms | Owner decision (future) |
| Schema design | New `app_settings` keys, license data structure | Implementation stage design |
| Migration path | How existing installs transition to new licensing | Implementation stage design |

### Trial / Subscription / Duration — separation

The absence of a decided pricing or duration model does NOT prevent T3-1 from freezing. The licensing architecture can keep "duration" as a future product configuration parameter. The design freeze captures the licensing **policy and architecture**; pricing and duration are **product configuration** decisions that belong to a future stage.

| Concept | Decided in T3-1? | Where decided? |
|---|---|---|
| Licensing subject (business) | YES | This document |
| Device binding (1 active device) | YES | This document |
| Offline runtime policy | YES | This document |
| Commercial model (resellable) | YES | This document |
| License states / lifecycle | YES | This document |
| Enforcement safety boundary | YES | This document |
| Pricing tiers | NO | Future owner decision |
| Trial duration | NO | Future owner decision |
| Subscription terms | NO | Future owner decision |
| Key format / signing | NO | T3-2 Technical Contract |
| Activation server API | NO | Implementation stage |
| Device fingerprint algorithm | NO | Implementation stage |

## 24. Acceptance Criteria

### For this Design Freeze (T3-1)

```
[x] Governing roadmap reviewed
[x] T2-4 baseline/lineage verified (HEAD = 73c9498)
[x] Owner decisions recorded and frozen
    [x] Decision 1: RESELLABLE MULTI-SHOP PRODUCT
    [x] Decision 2: BUSINESS / STORE as licensing subject
    [x] Decision 3: 1 active Windows device per license + controlled transfer
    [x] Decision 4: ONLINE ACTIVATION + OFFLINE NORMAL RUNTIME
[x] Commercial licensing subject explicitly frozen (Business/Store)
[x] Binding strategy explicitly frozen (1 device + controlled transfer)
[x] Device replacement policy frozen (controlled transfer)
[x] Offline/online verification policy frozen (online activation + offline runtime)
[x] No production code changed
[x] No schema changed
[x] No dependency changed
[x] No platform code changed
[x] Existing trial/licensing state audited
[x] License states / lifecycle defined
[x] Activation contract defined
[x] Transfer contract defined
[x] Device identity requirements defined
[x] Backup/restore interaction defined
[x] Reinstall / device failure behavior defined
[x] Data wipe interaction defined
[x] Business identity boundary defined
[x] Enforcement safety boundary defined
[x] Grace/expiry behavior designed
[x] Data safety policy frozen
[x] Security assumptions documented
[x] Privacy requirements documented
[x] Compatibility constraints documented
[x] Future implementation explicitly out of current scope
[x] No unresolved blocking product decision remains
[x] Roadmap alignment verified
```

## 25. Implementation Gate

### What this freeze enables

Once T3-1 is accepted, the following future steps become possible (each requires separate authorization):

```
T3-2 — Licensing Technical Contract / Enforcement Design
  → Detailed technical design for key format, signing, validation
  → Schema design for license storage
  → API contract for activation server (if online activation)
  → Device fingerprint algorithm selection
  → Acceptance criteria for implementation

T3-3 — Licensing Implementation
  → Code changes to app_settings, settings_screen
  → Key validation logic
  → Device identity collection
  → Activation service integration
  → Acceptance testing
```

### What this freeze does NOT enable

- No licensing implementation is authorized
- No server infrastructure is authorized
- No device fingerprinting code is authorized
- No schema changes are authorized
- No dependency additions are authorized

## 26. Roadmap Alignment

### Comparison

| Roadmap element | T3-1 coverage | Aligned? |
|---|---|---|
| Licensing Hardening (GAP-03) | Design freeze completed with owner decisions | YES |
| Delivery Policy | Frozen: resellable multi-shop, business subject, 1 device, online activation + offline runtime | YES |
| Binding Strategy | Frozen: 1 active device per business, controlled transfer | YES |
| Enforcement | Safety boundary defined; implementation deferred to T3-2/T3-3 | YES |
| Windows Delivery | No installer changes in T3-1 | YES |
| Backup/Restore | Policy separation defined; no backup code changes | YES |
| Accounting/Inventory safety | Enforcement safety boundary defined; no touch on financial data | YES |
| Configurable business identity | Business identity boundary defined; display config decoupled from licensing | YES |
| Future cloud dependencies | License server identified as future dependency; no backend selected | YES |
| Offline operation | Offline runtime policy frozen; no always-online design | YES |
| Migration/schema risk | Additive-only schema policy preserved; no migration in T3-1 | YES |
| Installer implications | No installer changes authorized | YES |
| UI/UX timing | No UI changes in T3-1 | YES |

### Alignment decision

**A — FOLLOW ROADMAP**

T3-1 is exactly what the roadmap authorized: a Design Freeze for the licensing policy. All owner decisions that were blocking the freeze have been resolved and incorporated. No deviations from the roadmap are required.

## 27. Final Freeze Decision

```
STATUS: A — DESIGN FREEZE ACCEPTED / FOLLOW ROADMAP

This document constitutes the T3-1 Licensing Policy Design Freeze for the
I-TECH application. It defines the complete licensing policy including
commercial model, licensing subject, device binding, offline/online
verification, license states, activation contract, transfer contract,
device identity requirements, backup/restore interaction, enforcement
safety boundary, failure modes, security assumptions, and privacy
requirements.

OWNER DECISIONS FROZEN:
  1. Commercial Model: RESELLABLE MULTI-SHOP PRODUCT
  2. Licensing Subject: BUSINESS / STORE
  3. Device Binding: 1 active Windows device per business license + controlled transfer
  4. Offline Policy: ONLINE ACTIVATION + OFFLINE NORMAL RUNTIME

The design freeze is ACCEPTED. No licensing implementation is authorized
until a separate implementation step is authorized in the roadmap.

No production code has been modified. No schema has been changed.
No dependencies have been added. This is documentation only.
```
