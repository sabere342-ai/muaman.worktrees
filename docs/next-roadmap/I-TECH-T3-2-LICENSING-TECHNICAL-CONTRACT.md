# I-TECH T3-2: Licensing Technical Contract / Enforcement Design

## 1. Status

```
STATUS: B — ACCEPTED WITH EXPLICIT DEFERRED DECISIONS
```

This document freezes the implementation-ready technical contract for licensing in the I-TECH application. It is a **design freeze only** — no production code is modified, no schema is changed, no dependencies are added, no server is deployed.

The contract is architecture-complete. A small number of commercial policy decisions remain intentionally deferred because the technical architecture safely supports either option. These are explicitly listed in §39.

## 2. Governing References

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` |
| Risk/Dependency Map | `docs/next-roadmap/I-TECH-RISK-DEPENDENCY-MAP.md` |
| T3-1 Policy Freeze | `docs/next-roadmap/I-TECH-T3-1-LICENSING-POLICY-DESIGN-FREEZE.md` |
| T3-1 baseline commit | `9bcc191` |
| This document | T3-2 Licensing Technical Contract / Enforcement Design |
| Step type | Design freeze only — NOT implementation |
| Roadmap classification | Tier 3 — Future Commercial / Platform Work |

### Where T3-2 appears in the roadmap

**T3-1 §25 — Implementation Gate (line 886):**

```
T3-2 — Licensing Technical Contract / Enforcement Design
  → Detailed technical design for key format, signing, validation
  → Schema design for license storage
  → API contract for activation server (if online activation)
  → Device fingerprint algorithm selection
  → Acceptance criteria for implementation
```

**Risk/Dependency Map §5 — Recommended Implementation Sequence (line 167):**

```
6. T3-1: Licensing Policy Design Freeze
   │
   ├── Accept or reject
   │
   [Further items require separate authorization]
```

T3-2 is the natural successor to T3-1 in the frozen roadmap's licensing lineage. It converts T3-1's policy freeze into an implementation-ready technical contract.

### What the roadmap authorizes

T3-1 explicitly enables T3-2 as the next licensing step. This is consistent with the project's established pattern: policy freeze → technical contract → implementation.

### What the roadmap excludes

From `I-TECH-NEXT-ROADMAP-FREEZE.md` line 392:

> Licensing implementation / hardening

is listed under **Explicit Exclusions** (OUT OF SCOPE for the current roadmap).

T3-2 is a **design freeze** — not implementation. This document is the authorized precursor to any future licensing implementation stage.

## 3. Verified Baseline

### Repository context

| Item | Value |
|---|---|
| Project | I-TECH / إدارة محل مؤمن |
| Repository | C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Starting HEAD | `9bcc191` |
| T3-1 baseline verified | YES — HEAD = 9bcc191 |
| T3-1 document exists | YES |
| Frozen roadmap exists | YES |
| Risk/dependency map exists | YES |

### Git evidence

```
9bcc191 (HEAD -> codex/i-tech-next-roadmap-freeze) docs: freeze T3-1 licensing policy design
73c9498 feat: implement 80mm thermal invoice printing
0a61984 docs: freeze T2-4 thermal printing design
2728419 docs: freeze T2-3 customer master design
0cc157e docs: T2-2 expense categories governance report
26cd605 feat(expenses): add expense categories (T2-2)
a3dacd8 feat(backup): implement standalone backup/restore workflow (T2-1)
df17d17 docs: freeze standalone backup/restore design contract (T1-2)
ade506a fix(ui): replace hardcoded brand color with theme-driven primary across 7 screens
2295137 docs: freeze next controlled i-tech roadmap
```

Lineage verified: HEAD contains T3-1 baseline `9bcc191` as a direct ancestor.

## 4. Scope

### In scope

This document defines the complete implementation-ready technical contract for licensing, covering:

- Business identity model
- Cryptographic signing model
- Entitlement token format
- Device identity / fingerprint contract
- Local secure storage contract
- Activation protocol and server API contract
- Offline verification contract
- Transfer / deactivation semantics
- Reinstall behavior
- Entitlement state machine
- Enforcement matrix
- Safe-data-access policy
- Backup / restore boundary
- Migration from existing cosmetic licensing
- Failure behavior
- Clock policy
- Threat model
- Privacy / data minimization
- Dependency implications
- API error contract
- UX contract
- Testing contract
- Implementation sequencing

### Non-goals

This document does NOT:

1. Implement licensing code
2. Deploy or implement an activation server
3. Implement device fingerprinting code
4. Modify database schema
5. Add dependencies to `pubspec.yaml`
6. Modify Windows native/platform code
7. Modify the installer
8. Freeze pricing, duration, subscription, or trial commercial values
9. Select a specific server technology or hosting provider
10. Create route guards or runtime enforcement code

## 5. T3-1 Frozen Inputs — UNCHANGED

All four owner decisions from T3-1 remain frozen and are NOT reopened by this document:

### Decision 1 — Commercial Model

```
RESELLABLE MULTI-SHOP PRODUCT
```

I-TECH is a retail POS product distributed and sold to multiple independent shops. Each shop holds an independent license.

### Decision 2 — Licensing Subject

```
BUSINESS / STORE
```

The license belongs to the Business/Store identity. NOT the owner person, NOT the Windows user account, NOT the physical machine as the commercial subject. The device is an activation/binding constraint, not the licensing subject.

### Decision 3 — Device Policy

```
1 active Windows device per business license
+ controlled transfer
```

### Decision 4 — Connectivity Policy

```
ONLINE ACTIVATION
+ OFFLINE NORMAL RUNTIME
```

## 6. Current Code Audit — Verified Repository Evidence

### Licensing code inventory

| File:line | Symbol | Current Behavior | T3-2 Impact |
|---|---|---|---|
| `app_settings.dart:10` | `keyLicenseKey` | Persists license key string in `app_settings` table | PRESERVED as legacy key; new entitlement stored separately |
| `app_settings.dart:11` | `keyLicenseStatus` | Persists `'active'` or `'inactive'` in `app_settings` table | PRESERVED as legacy key; new state is `EntitlementState` enum |
| `app_settings.dart:38` | Default `inactive` | Initializes `licenseStatus` to `'inactive'` on first run | PRESERVED; new installations use `EntitlementState.UNINITIALIZED` |
| `app_settings.dart:95-97` | `getLicenseKey()` | Returns stored key (or empty string) | PRESERVED for legacy display |
| `app_settings.dart:99-102` | `getLicenseStatus()` | Returns stored status (or `'inactive'`) | PRESERVED for legacy display |
| `app_settings.dart:116-125` | `validateLicenseKey()` | Accepts any `MUAMAN-*` key with 12+ chars, sets status `'active'` | PRESERVED as dead code; replaced by activation protocol |
| `settings_screen.dart:29` | `_licenseController` | TextField controller for license key input | Will be replaced by activation flow UI |
| `settings_screen.dart:42` | `_licenseStatus` | UI state string (`'active'` / `'inactive'`) | Will be replaced by EntitlementState display |
| `settings_screen.dart:501-530` | License section | TextField + activate button + status label | Will be replaced by activation/transfer UI |
| `settings_screen.dart:566-570` | License detail text | Displays license status in Arabic | Will show EntitlementState details |
| `settings_screen.dart:1591-1614` | `_activateLicense()` | Calls `validateLicenseKey`, updates UI state | Will be replaced by server activation flow |

### Enforcement capability matrix

| Capability | Current Status | Evidence |
|---|---|---|
| License enforcement gate | **NOT FOUND** | No screen, route, navigation guard, or business logic checks `licenseStatus` |
| Activation server call | **NOT FOUND** | `validateLicenseKey()` is purely local string-prefix check |
| Device fingerprint / hardware ID | **NOT FOUND** | Zero device identification packages or code |
| Online validation | **NOT FOUND** | Zero HTTP/network imports in `pubspec.yaml` |
| Offline entitlement cache | **NOT FOUND** | No entitlement system; only `app_settings` key-value store |
| Anti-tamper mechanism | **NOT FOUND** | No checksum, CRC, or integrity checking of license data |
| License transfer mechanism | **NOT FOUND** | No deactivation, revocation, or transfer logic |

### Critical architectural facts

| Fact | Evidence |
|---|---|
| No HTTP/networking packages | `pubspec.yaml` — no `http`, `dio`, `fetch`, `web_socket`, `cloud_firestore` |
| No device identity packages | `pubspec.yaml` — no `device_info`, `platform_device_id`, `win32` |
| No crypto signing packages | `pubspec.yaml` — only `crypto: ^3.0.6` (hashing only, used for password hashing) |
| 100% offline application | Zero network calls anywhere in the codebase |
| `app_settings` is a simple key-value table | `key TEXT PRIMARY KEY, value TEXT NOT NULL` |
| `app_settings` survives clean start | `preservedTables` in `clean_start_service.dart:84-88` |
| `app_settings` is included in all backups | `VACUUM INTO` copies entire database |
| Schema version is 7 | `database_helper.dart:113` |
| All 11 tables exist | Verified in restore validation (`standalone_restore_service.dart:110-131`) |

### Existing app_settings keys (frozen, never renamed/removed)

| Key | Default | Purpose |
|---|---|---|
| `licenseKey` | (empty) | Stores the entered license key |
| `licenseStatus` | `'inactive'` | Stores `'active'` or `'inactive'` |

These keys are part of the frozen `app_settings` identity. T3-2 adds new keys; these are preserved for backward compatibility.

## 7. Architecture Overview

### Trust boundaries

```
┌─────────────────────────────────────────────────────────┐
│                  ACTIVATION SERVER                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Private signing key (Ed25519)                     │  │
│  │  License database                                 │  │
│  │  Activation records                               │  │
│  │  Audit log                                        │  │
│  └───────────────────────────────────────────────────┘  │
│  Boundary: Server-side only. Never exposed to client.    │
└─────────────────────────────────────────────────────────┘
                         │
                    HTTPS API
                    (activation,
                     deactivation,
                     transfer,
                     support reset)
                         │
┌─────────────────────────────────────────────────────────┐
│                  WINDOWS CLIENT                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Public verification key (Ed25519)                 │  │  TRUST: Embedded at build time
│  │  Entitlement token (signed, machine-readable)     │  │  TRUST: Verified locally
│  │  Device fingerprint (derived, hashed)             │  │  TRUST: Machine-local only
│  │  Business identity (server-generated UUID)        │  │  TRUST: Created at activation |
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Local activation state                           │  │  STORAGE: DPAPI-protected file
│  │  (separate from business database)                │  │  SEPARATE from muaman_store.db
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Business database (muaman_store.db)              │  │  TRUST: User data, no licensing secrets
│  │  Products, sales, invoices, expenses, settings    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Key trust invariants

1. The **private signing key** NEVER exists in the Windows client. Only the public verification key is embedded.
2. The **entitlement token** is signed by the server. The client can verify it offline using the embedded public key.
3. The **local activation state** is machine-local, encrypted with DPAPI, and separate from the business database.
4. The **business database** (`muaman_store.db`) contains NO licensing secrets. It contains business data only.
5. The **device fingerprint** is a derived hash computed locally. Raw hardware identifiers are never sent to the server — only the derived hash is transmitted.
6. **Backup** copies the business database only. It does NOT copy activation state.
7. **Normal runtime** is entirely offline after activation. The server is contacted only for activation, deactivation, transfer, and support reset.

### Data flow summary

```
ACTIVATION:
  App → (license_key + device_fingerprint_hash) → Server
  Server → (signed_entitlement_token) → App
  App → stores token in DPAPI-protected local file

NORMAL RUNTIME (offline):
  App → reads DPAPI local file → verifies Ed25519 signature with embedded public key
  App → checks business_id match, device_id match, token_version, key_id
  App → determines EntitlementState → enforces at application boundaries

TRANSFER:
  Old device → deactivation API call → server revokes old activation
  New device → activation API call → server issues new token
```

## 8. Trust Boundaries

### Client trust boundary

The client application runs on the shop owner's Windows machine. The client is considered:

- **Modifiable** by a determined attacker (binary patching)
- **Observable** by a determined attacker (debugging, memory inspection)
- **Not a trust anchor** — the client enforces licensing as a commercial courtesy, not as an absolute security guarantee

What the client CAN trust:

- Its own DPAPI-protected local file (tied to the Windows user account and machine)
- The embedded public key (tamper-resistant via code signing, not tamper-proof)
- Its own derived device fingerprint (computed from stable Windows APIs)

What the client CANNOT trust:

- Any locally stored value that could be manually edited (e.g., plaintext `app_settings` rows)
- The system clock (can be manipulated)
- Itself against a determined attacker with admin access

### Activation server trust boundary

The activation server is the authority for:

- License issuance
- Activation state transitions
- Transfer authorization
- Support reset authorization
- Signed entitlement token generation

The server maintains the authoritative record of which device is currently active for each license.

### Private signing key boundary

The Ed25519 private signing key lives exclusively on the activation server (or in a Hardware Security Module connected to the server). It is:

- NEVER transmitted to any client
- NEVER embedded in the application binary
- NEVER stored in any client-side file
- Used ONLY to sign entitlement tokens

If compromised, the key is rotated (see §15). The `key_id` in each token allows the client to track which signing key was used.

### Public verification key boundary

The Ed25519 public verification key is embedded in the application binary at build time. It is used to verify entitlement token signatures offline. It is:

- Public by nature — extraction does not compromise security
- Embedded at build time — cannot be changed without a new build
- Versioned via `key_id` — supporting key rotation
- Not a secret — its compromise has no security impact

### Machine-local activation state boundary

The activation state (entitlement token, metadata) is stored in a DPAPI-protected file in the Windows user profile. It is:

- Tied to the specific Windows user account on the specific machine
- NOT part of the business database
- NOT included in backup/restore
- Encrypted at rest via DPAPI
- Integrity-protected (tamper detection)

### Business database boundary

The business database (`muaman_store.db`) contains business operational data only:

- Products, sales, returns, expenses, invoices, inventory, users, settings
- NO licensing secrets
- NO entitlement tokens
- NO device fingerprints
- NO activation state

The existing `licenseKey` and `licenseStatus` rows in `app_settings` are **legacy cosmetic fields** — they are NOT used as cryptographic entitlement proof and are NOT trusted by the new licensing system.

## 9. Business Identity

### Immutable licensing identity

Each business/license has a stable, immutable `business_id` that serves as the licensing subject anchor.

| Property | Value |
|---|---|
| Format | UUID v4 (RFC 4122) |
| Generation | Server-generated at license creation |
| Length | 36 characters (with hyphens) |
| Example | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| Immutability | NEVER changes after creation |
| Uniqueness | Server-enforced unique constraint |

### What identifies the business

| Identity Element | Type | Changeable? | Used for Licensing? |
|---|---|---|---|
| `business_id` | UUID v4 | NO | YES — primary licensing anchor |
| Shop display name | String | YES | NO |
| Shop logo | Binary/path | YES | NO |
| Owner display name | String | YES | NO |
| Phone number | String | YES | NO |
| Address | String | YES | NO |
| Brand color | String | YES | NO |
| Invoice title | String | YES | NO |
| Invoice footer text | String | YES | NO |
| Default customer name | String | YES | NO |
| Support phone | String | YES | NO |

### Critical invariant

**Changing shop display configuration MUST NOT create, destroy, or modify the `business_id`.**

The `business_id` is:

- Created by the server during initial license issuance
- Delivered to the client inside the signed entitlement token
- Persisted in the local activation state (DPAPI-protected file)
- Verified on every token validation (business_id in token must match local business_id)
- NOT editable by the user through any UI or settings screen

### Business identity persistence

The `business_id` is persisted in two places:

1. **Server-side**: Authoritative record in the license database
2. **Client-side**: Stored in the DPAPI-protected local activation file

If the local activation file is lost (e.g., DPAPI corruption, clean Windows reinstall), the business_id can be recovered by re-activating with the same license key. The server returns the same `business_id`.

### Business identity vs display configuration separation

```
LICENSED BUSINESS (immutable):
  business_id = UUID v4
  ├── Created at license issuance
  ├── Never editable by user
  ├── Survives display configuration changes
  └── Used as licensing subject anchor

DISPLAY CONFIGURATION (editable):
  shop_name = "محل أحمد"
  logo = "logo.png"
  owner_name = "أحمد"
  phone = "01012345678"
  address = "شارع التحرير"
  brand_color = "#0D47A1"
  invoice_title = "فاتورة بيع"
  invoice_footer = "شكراً لتعاملكم"
  └── All changeable at any time without affecting licensing
```

### Migration of existing installations

Existing installations do NOT have a `business_id`. Migration behavior:

1. On first activation after T3-2 implementation, the server issues a `business_id` and returns it in the entitlement token.
2. The `business_id` is stored in the local activation file.
3. The existing `licenseKey` and `licenseStatus` in `app_settings` are preserved but no longer used for entitlement verification.
4. Existing installations start in `UNINITIALIZED` state until activated through the new protocol.

## 10. License Identifier Model

### Human-entered identifier

The user types an **activation code** into the application during activation.

| Property | Value |
|---|---|
| Format | `ITECH-XXXX-XXXX-XXXX` (or similar issuer-defined format) |
| Purpose | Identifies the license to the server |
| Contains secrets? | NO — it is an identifier, not a credential |
| Predictable? | Sequentially issued, not random |
| Sufficient for activation alone? | NO — server validates it and issues a signed token |

The activation code is analogous to a product key or order number. It identifies the license but does NOT constitute cryptographic proof of entitlement.

### Cryptographically signed entitlement token

After server validation, the client receives and stores a **signed entitlement token** — a machine-readable, cryptographically signed document that proves the client is entitled to operate.

| Property | Value |
|---|---|
| Format | CBOR-encoded signed payload |
| Signature | Ed25519 |
| Contains secrets? | NO — signed, not encrypted (the signature proves authenticity) |
| Verifiable offline? | YES — client verifies with embedded public key |
| Forgeable without private key? | NO (computationally infeasible) |
| Sufficient for activation? | YES — this IS the entitlement proof |

### Distinction

```
ACTIVATION CODE (human-entered):
  "ITECH-1234-5678-ABCD"
  → Identifies the license to the server
  → NOT cryptographic proof
  → Used during online activation only

ENTITLEMENT TOKEN (signed, machine-readable):
  { license_id, business_id, device_id, ... , signature }
  → IS the cryptographic proof of entitlement
  → Verified offline by the client
  → Stored in DPAPI-protected local file
```

## 11. Cryptographic Contract

### Algorithm selection

| Property | Value |
|---|---|
| Signature family | **Ed25519** (Edwards-curve Digital Signature Algorithm, Curve25519) |
| RFC | RFC 8032 |
| Public key size | 32 bytes |
| Private key size | 32 bytes (seed) |
| Signature size | 64 bytes |
| Security level | ~128-bit (comparable to RSA-3072) |
| Performance | Very fast signing and verification |
| Maturity | Widely deployed (SSH, TLS 1.3, Signal, WireGuard) |

### Justification

- **Compact**: 64-byte signatures are ideal for tokens stored locally
- **Fast**: Both signing and verification are fast enough for offline use
- **Auditable**: Ed25519 is a well-studied, standardized algorithm with no known weaknesses
- **Standard**: Widely supported in cryptographic libraries across languages
- **No custom cryptography**: This is a mature, peer-reviewed algorithm, not a custom construction
- **Future-proof**: Ed25519 is the recommended algorithm for new deployments by most cryptographic standards bodies

### What is signed

The **entitlement payload** (see §12) is serialized to CBOR, then signed with Ed25519.

### Canonical serialization

| Step | Action |
|---|---|
| 1 | Construct the entitlement payload as a map of defined fields |
| 2 | Serialize the payload to **CBOR** (RFC 7049) using deterministic encoding |
| 3 | Sign the resulting byte sequence with the Ed25519 private key |
| 4 | Produce the signed token: `payload_bytes || signature_bytes` (64 bytes appended) |

CBOR is chosen for deterministic serialization (unlike JSON, which allows field reordering and whitespace variation). This ensures the same payload always produces the same byte sequence, preventing signature verification failures due to serialization ambiguity.

### Where the private key lives

```
ACTIVATION SERVER (or HSM):
  - Private signing key (Ed25519 seed, 32 bytes)
  - Used ONLY to sign entitlement tokens
  - NEVER transmitted to any client
  - NEVER embedded in any client binary
  - Accessible ONLY by the signing service
  - Key rotation supported via key_id
```

### Where the public key lives

```
WINDOWS CLIENT (embedded in binary):
  - Public verification key (Ed25519 public key, 32 bytes)
  - Embedded at build time via compile-time constant
  - Used to verify entitlement token signatures offline
  - NOT a secret — extraction has no security impact
  - Versioned via key_id for rotation support
```

### Key rotation

| Aspect | Contract |
|---|---|
| Rotation trigger | Compromise, routine rotation, or algorithm deprecation |
| Mechanism | Server generates new Ed25519 keypair, assigns new `key_id` |
| Client-side | New client builds include new public key + new `key_id` |
| Old tokens | Remain valid until their `key_id` is no longer trusted by new clients |
| Migration | Server can re-issue tokens with new key_id on next activation/transfer |
| Grace period | Old public key accepted for a configurable period during transition |

### Key rotation is NOT a runtime concern

Key rotation happens at build time (new client version) and activation time (server re-issues token). It does NOT require periodic online checks.

### Signing-key compromise

| Step | Action |
|---|---|
| 1 | Detect compromise (audit anomalies, external report) |
| 2 | Immediately generate new keypair on server |
| 3 | Assign new `key_id` to new keypair |
| 4 | Revoke/trust-downgrade old `key_id` |
| 5 | Publish new client build with new public key |
| 6 | On next activation/transfer, tokens are re-issued with new `key_id` |
| 7 | Old tokens with compromised `key_id` are rejected after grace period |

During the grace period, both old and new public keys are accepted. This prevents a sudden outage while allowing gradual migration.

## 12. Entitlement Token

### Token structure

The entitlement token is a CBOR-encoded map with the following fields:

| Field | Type | Size | Description |
|---|---|---|---|
| `token_version` | unsigned int | 1 byte | Token format version (initially `1`) |
| `key_id` | unsigned int | 1-2 bytes | Identifies which signing key was used |
| `license_id` | UUID string | 36 bytes | Unique license identifier |
| `business_id` | UUID string | 36 bytes | Immutable business identity |
| `product_id` | string | variable | Product tier/edition identifier |
| `entitlements` | map | variable | Entitlement fields (see below) |
| `device_id_hash` | bytes | 32 bytes | SHA-256 hash of device fingerprint (not the raw fingerprint) |
| `activation_generation` | unsigned int | 1-2 bytes | Incremented on each activation of this license |
| `issued_at` | epoch seconds | 4-5 bytes | When this token was created |
| `not_before` | epoch seconds | 4-5 bytes | Earliest time this token is valid |
| `signature` | bytes | 64 bytes | Ed25519 signature over the CBOR encoding of all above fields |

### Entitlements sub-map

| Field | Type | Description |
|---|---|---|
| `tier` | string | Commercial tier (initially `"standard"`) |
| `device_limit` | unsigned int | Max concurrent activated devices (initially `1`) |
| `features` | array of strings | Enabled feature identifiers (extensible) |

### Fields intentionally NOT included

| Field | Reason excluded |
|---|---|
| `expires_at` | No commercial expiry policy frozen yet; architecture supports adding this |
| `trial_end` | No trial policy frozen yet; architecture supports adding this |
| `max_users` | No user limit policy frozen yet; architecture supports adding this |
| `max_products` | No product limit policy frozen yet; architecture supports adding this |
| `pricing_tier` | Pricing is a commercial decision, not a technical one |

The architecture is designed so that future entitlement fields can be added by incrementing `token_version` without breaking existing installations.

### Token version semantics

| Version | Meaning |
|---|---|
| `1` | Initial token format (this document) |
| `2+` | Future extensions (add fields, modify structure) |

When a client encounters an unsupported `token_version`, it transitions to `UNSUPPORTED_TOKEN_VERSION` state and prompts the user to update the application.

### Why the device_id_hash is a hash, not the raw fingerprint

The raw device fingerprint (§13) contains Windows Machine GUID, CPU ID, and board serial. Transmitting these raw values to the server would:

- Expose hardware identifiers unnecessarily
- Create a privacy concern if the server database is compromised
- Violate the data minimization principle

Instead, the client computes a SHA-256 hash of the fingerprint with a per-app salt and sends only the 32-byte hash. The server:

- Stores the hash (not the raw values)
- Can verify same-device by comparing hashes
- Cannot reconstruct the original hardware identifiers from the hash
- Has no ability to track hardware beyond the licensing purpose

## 13. Device Identity Contract

### Design goal

```
Stable-enough Windows device identity with controlled tolerance
and transfer recovery for 1-active-device-per-business licensing.
```

### Device fingerprint inputs

| Input | Source | Stability | Why included |
|---|---|---|---|
| Windows Machine GUID | `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MachineGuid` | Survives OS reinstall, app reinstall, disk changes | Most stable Windows identifier |
| CPU Processor ID | `Win32_Processor.ProcessorId` (WMI) | Survives OS reinstall, app reinstall, disk changes | Ties to physical CPU |
| Baseboard Serial Number | `Win32_BaseBoard.SerialNumber` (WMI) | Survives OS reinstall, app reinstall | Ties to motherboard |

### Inputs deliberately excluded

| Input | Why excluded |
|---|---|
| Disk serial numbers | Change on disk replacement; too fragile |
| MAC addresses | Change on network adapter change; privacy-invasive |
| Windows user account | Not tied to hardware; changes on account recreation |
| Display name / hostname | User-editable; not suitable for identity |
| BIOS serial (duplicate) | Redundant with baseboard serial |
| TPM identifier | Not available on all Windows machines; unnecessary complexity |
| GPU identifiers | Not relevant to device identity; change on GPU replacement |

### Normalization and hashing

```
STEP 1: Collect raw values
  machine_guid = read from registry (string)
  cpu_id = read from WMI (string)
  board_serial = read from WMI (string)

STEP 2: Normalize
  Strip leading/trailing whitespace
  Convert to UTF-8 bytes
  If any value is empty or unavailable, use a sentinel "UNAVAILABLE"

STEP 3: Construct canonical input
  canonical = "I-TECH-DEVICE|" + machine_guid + "|" + cpu_id + "|" + board_serial

STEP 4: Hash with salt
  salt = "I-TECH-LICENSING-DEVICE-FINGERPRINT-v1" (fixed per-app constant)
  fingerprint = SHA-256(salt + "|" + canonical)

STEP 5: Output
  device_fingerprint = 32-byte SHA-256 digest
  device_id_hash = fingerprint (what is sent to server and stored in token)
```

### Same-device vs new-device decision

| Change | Device Fingerprint Changes? | Result |
|---|---|---|
| App reinstallation on same machine | NO | Same device — reactivation succeeds |
| Windows reinstall on same hardware | NO | Same device — reactivation succeeds |
| Disk replacement (same machine) | NO | Same device — reactivation succeeds |
| Windows user account recreation | NO | Same device — fingerprint is machine-level |
| App data wipe / clean start | NO (fingerprint recomputed from hardware) | Same device — but activation token lost, reactivation needed |
| Motherboard replacement | YES (board_serial changes) | New device — requires controlled transfer |
| Complete machine replacement | YES (all values change) | New device — requires controlled transfer |
| Partial hardware change (CPU only) | YES (cpu_id changes) | New device — requires controlled transfer |
| VM migration to different host | Likely YES | New device — requires controlled transfer |

### Reinstall behavior

**Same device (fingerprint unchanged):**
1. User reinstalls app or Windows
2. App is in `UNINITIALIZED` state (activation token was lost during reinstall)
3. User enters activation code
4. Server receives device_id_hash
5. Server compares with stored device_id_hash for this license
6. Match found → server issues new token (same business_id, same license_id, incremented activation_generation)
7. User is back to `ACTIVE`

**New device (fingerprint changed):**
1. User enters activation code on new device
2. Server receives device_id_hash
3. Server compares with stored device_id_hash → MISMATCH
4. Server returns `TRANSFER_REQUIRED` error
5. User must either:
   a. Deactivate old device (if accessible), or
   b. Contact support for reset

### Tolerance for hardware changes

The three-input fingerprint (MachineGuid + CPU + Board) provides moderate tolerance:

- **Single component replacement** (e.g., new GPU, new disk, new RAM): Fingerprint UNCHANGED
- **Motherboard replacement**: Fingerprint CHANGES (board_serial changes)
- **CPU + motherboard replacement**: Fingerprint CHANGES

This is a reasonable balance: most routine hardware changes are tolerated, while a complete machine replacement triggers the transfer flow.

### Privacy considerations

| Concern | Mitigation |
|---|---|
| Raw hardware identifiers exposed to server | Only the SHA-256 hash is transmitted; raw values never leave the device |
| Server could track hardware across businesses | The hash is per-app (different salt for different apps would produce different hashes) |
| Device identity could be used for surveillance | The identity is used ONLY for licensing — no behavioral data, no location, no personal data |
| DPAPI ties to Windows user account | This is acceptable — the activation is per-user-per-machine, matching the 1-device policy |

### Implementation spike requirement

The exact WMI query implementation for CPU ID and board serial may require a proof-of-concept to verify availability across Windows versions (Windows 10, Windows 11). If WMI is unreliable on some configurations, the fallback is to use only MachineGuid + a hash of the hostname + user profile SID.

**Acceptance criteria for the spike:**
1. The fingerprint is deterministic on the same machine across app restarts
2. The fingerprint survives app reinstallation
3. The fingerprint survives Windows reinstallation on the same hardware
4. The fingerprint changes when the motherboard is replaced
5. WMI queries succeed on Windows 10 and Windows 11
6. If WMI fails, the fallback produces a stable alternative fingerprint

## 14. Signing Key Lifecycle

### Key generation

| Step | Action |
|---|---|
| 1 | Generate Ed25519 keypair (32-byte seed + 32-byte public key) |
| 2 | Assign `key_id` (monotonically increasing integer) |
| 3 | Store private key in server-side HSM or secure vault |
| 4 | Embed public key + `key_id` in client application binary |
| 5 | Record key metadata in server database (creation date, status) |

### Key states

| State | Meaning |
|---|---|
| `ACTIVE` | Currently trusted for signing and verification |
| `DEPRECATED` | Still accepted for verification of existing tokens; no new tokens signed with this key |
| `REVOKED` | No longer accepted; tokens signed with this key are invalid |

### Key rotation procedure

```
1. Generate new keypair, assign new key_id
2. Mark old key as DEPRECATED
3. Build new client version with new public key
4. Deploy new client version
5. On next activation/transfer, server signs token with new key
6. After grace period, mark old key as REVOKED
7. Old client versions with old public key can still verify existing tokens
   until they update or reactivate
```

### Compromise procedure

```
1. Immediately mark compromised key as REVOKED
2. Generate new keypair, assign new key_id
3. All tokens signed with compromised key become invalid immediately
4. Affected users must re-activate (server issues new token with new key)
5. Publish new client version with new public key
6. Audit server logs for suspicious activation patterns
```

## 15. Local Activation Storage

### Why app_settings is NOT sufficient

The current `app_settings` table stores `licenseKey` and `licenseStatus` as editable plaintext SQLite rows:

```sql
INSERT INTO app_settings (key, value) VALUES ('licenseKey', 'MUAMAN-...');
INSERT INTO app_settings (key, value) VALUES ('licenseStatus', 'active');
```

This is NOT sufficient as cryptographic entitlement proof because:

1. **Editable**: Any user with SQLite access can change these values to anything
2. **Not signed**: There is no cryptographic proof that these values were issued by the licensing server
3. **Not integrity-protected**: No tamper detection; values can be modified without detection
4. **Portable via backup**: These values are included in `VACUUM INTO` backups, meaning a backup could theoretically "transfer" activation (violating the 1-device policy)
5. **Not machine-bound**: These values have no connection to the specific hardware

### Recommended storage: DPAPI-protected local file

| Property | Value |
|---|---|
| Storage mechanism | Windows DPAPI (Data Protection API) |
| File location | `%LOCALAPPDATA%\I-TECH\licensing\activation.dat` |
| Encryption | `CryptProtectData` with `CRYPTPROTECT_LOCAL_MACHINE` flag |
| Integrity | HMAC-SHA256 over the file contents, keyed with a per-installation secret |
| Separation | COMPLETELY SEPARATE from `muaman_store.db` |
| Backup included? | NO — file is machine-local, not part of business database |
| Survives app reinstall? | YES — file persists in AppData |
| Survives Windows reinstall? | NO — DPAPI context is lost; reactivation required |
| User editable? | NO — file is binary, encrypted, integrity-protected |

### DPAPI justification

DPAPI is the standard Windows mechanism for protecting local secrets. It:

- Is available on all Windows versions (XP through 11)
- Requires no additional dependencies beyond Windows API
- Encrypts data tied to the Windows user account and machine
- Is used by browsers, email clients, and enterprise software for local secret storage
- Provides machine-level encryption that prevents casual file copying

### File contents (conceptual)

```
activation.dat (DPAPI-protected binary):
  ┌──────────────────────────────────────────────────┐
  │  File version (1 byte)                           │
  │  Entitlement token (CBOR-encoded, variable)      │
  │  business_id (UUID string, 36 bytes)             │
  │  device_fingerprint_hash (32 bytes)              │
  │  activation_metadata (map):                      │
  │    last_verified_at (epoch seconds)              │
  │    activation_count (integer)                    │
  │    created_at (epoch seconds)                    │
  │  HMAC-SHA256 (32 bytes) — integrity check       │
  └──────────────────────────────────────────────────┘
```

### Integrity protection

The file includes an HMAC-SHA256 computed over all fields except the HMAC itself. The HMAC key is derived from:

- A per-installation secret (generated at first activation, stored alongside the file)
- The Windows Machine GUID (provides machine-binding for the HMAC key)

This means:
- Editing the file without knowing the HMAC key will cause integrity check failure
- Copying the file to another machine will fail both DPAPI decryption AND HMAC verification
- The HMAC key is never stored in the business database

### Tamper detection behavior

| Tamper scenario | Detection | Result |
|---|---|---|
| User edits activation.dat directly | HMAC verification fails | `LOCAL_STATE_CORRUPT` state |
| File copied to another machine | DPAPI decryption fails | `LOCAL_STATE_CORRUPT` state |
| File partially overwritten | HMAC verification fails | `LOCAL_STATE_CORRUPT` state |
| File deleted | File not found | `UNINITIALIZED` state |
| File corrupted by disk error | HMAC verification fails | `LOCAL_STATE_CORRUPT` state |

### Recovery from local state corruption

When `LOCAL_STATE_CORRUPT` is detected:
1. Display clear message to user
2. Offer option to re-activate with activation code
3. Offer option to contact support
4. Business data is unaffected (separate database)
5. No data is deleted or modified by the licensing system

## 16. Activation Protocol

### Overview

Activation is the process of:
1. User enters activation code
2. Client contacts server (online required)
3. Server validates and records the activation
4. Server returns a signed entitlement token
5. Client stores the token in the DPAPI-protected local file
6. Client transitions to `ACTIVE` state

### Activation request

```
POST /api/v1/activate
Content-Type: application/json

{
  "activation_code": "ITECH-XXXX-XXXX-XXXX",
  "device_id_hash": "base64-encoded SHA-256 hash",
  "token_version": 1,
  "client_version": "1.0.0",
  "idempotency_key": "UUID-generated per request",
  "nonce": "random-bytes-for-replay-protection",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### Activation response — success

```
HTTP 200 OK

{
  "status": "activated",
  "entitlement_token": "base64-encoded CBOR-signed token",
  "business_id": "UUID-string",
  "license_id": "UUID-string",
  "activation_generation": 1,
  "key_id": 1
}
```

### Activation response — errors

| HTTP Status | Error Code | Meaning |
|---|---|---|
| 404 | `LICENSE_NOT_FOUND` | Activation code does not match any license |
| 403 | `LICENSE_DISABLED` | License has been disabled by administrator |
| 409 | `DEVICE_ALREADY_ACTIVE` | This device is already the active device for this license |
| 409 | `TRANSFER_REQUIRED` | Another device is active; transfer required |
| 400 | `DEVICE_MISMATCH` | Device fingerprint does not match expected device |
| 400 | `BUSINESS_MISMATCH` | Business identity mismatch (should not occur in normal flow) |
| 400 | `TOKEN_VERSION_UNSUPPORTED` | Client requesting unsupported token version |
| 429 | `ACTIVATION_RATE_LIMITED` | Too many activation attempts; retry later |
| 409 | `REQUEST_REPLAYED` | Nonce has been used before (replay attempt) |
| 503 | `SERVER_TEMPORARILY_UNAVAILABLE` | Server is temporarily down; retry later |

### Idempotency

The `idempotency_key` field ensures that:

- Duplicate activation requests (e.g., due to network retry) produce the same result
- The server stores the response associated with each `idempotency_key` for a configurable period (e.g., 24 hours)
- If the same `idempotency_key` is received again, the stored response is returned without re-processing

### Replay protection

The `nonce` field (cryptographically random bytes) prevents replay attacks:

- Each activation request includes a unique nonce
- The server records used nonces (with TTL for storage management)
- If a nonce is reused, the server rejects the request with `REQUEST_REPLAYED`
- The nonce is bound to the request timestamp; stale nonces (e.g., >5 minutes old) are rejected

### Server-side concurrency — one-device invariant

**CRITICAL INVARIANT: AT MOST ONE ACTIVE DEVICE PER BUSINESS LICENSE**

This is enforced at the database level, not merely in application logic:

```sql
-- Server-side schema constraint (conceptual)
CREATE TABLE activations (
  id UUID PRIMARY KEY,
  license_id UUID NOT NULL,
  device_id_hash BYTEA NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  activated_at TIMESTAMPTZ NOT NULL,
  deactivated_at TIMESTAMPTZ,
  activation_generation INTEGER NOT NULL
);

-- Unique constraint: at most one active activation per license
CREATE UNIQUE INDEX one_active_per_license
  ON activations (license_id)
  WHERE status = 'active';
```

This means:
- Two concurrent activation requests for the same license cannot both succeed
- The database constraint prevents exactly one active device at a time
- The application layer handles the race condition gracefully (one succeeds, one gets `TRANSFER_REQUIRED`)

### Activation flow — complete sequence

```
1. User opens app → sees ACTIVATION_REQUIRED screen
2. User enters activation code
3. Client computes device_fingerprint_hash
4. Client sends POST /api/v1/activate
5. Server validates activation_code against license database
6. Server checks if another device is active for this license
   a. If no active device → proceed with activation
   b. If same device_id_hash → return existing token (idempotent)
   c. If different device_id_hash → return TRANSFER_REQUIRED
7. Server generates new activation record (incrementing activation_generation)
8. Server signs entitlement token with Ed25519 private key
9. Server stores activation record in database
10. Server returns signed entitlement token to client
11. Client verifies token signature with embedded public key
12. Client stores token in DPAPI-protected local file
13. Client transitions to ACTIVE state
14. User can now use the application
```

## 17. Server Data Model

### Licenses table

```
licenses
├── license_id          UUID PRIMARY KEY
├── business_id         UUID NOT NULL UNIQUE  -- one license per business
├── activation_code     TEXT NOT NULL UNIQUE   -- human-entered code
├── product_id          TEXT NOT NULL          -- product tier/edition
├── status              TEXT NOT NULL          -- 'active', 'disabled', 'revoked'
├── device_limit        INTEGER NOT NULL DEFAULT 1
├── tier                TEXT NOT NULL DEFAULT 'standard'
├── issued_at           TIMESTAMPTZ NOT NULL
├── created_by          TEXT                  -- support admin identifier
└── metadata            JSONB                 -- extensible fields
```

### Businesses table

```
businesses
├── business_id         UUID PRIMARY KEY
├── display_name        TEXT                  -- for support reference only
├── created_at          TIMESTAMPTZ NOT NULL
├── license_id          UUID REFERENCES licenses(license_id)
└── metadata            JSONB
```

### Activations table

```
activations
├── id                  UUID PRIMARY KEY
├── license_id          UUID NOT NULL REFERENCES licenses(license_id)
├── device_id_hash      BYTEA NOT NULL       -- SHA-256 of device fingerprint
├── status              TEXT NOT NULL DEFAULT 'active'  -- 'active', 'deactivated'
├── activated_at        TIMESTAMPTZ NOT NULL
├── deactivated_at      TIMESTAMPTZ          -- NULL if still active
├── activation_generation INTEGER NOT NULL   -- incremented on each activation
├── client_version      TEXT                 -- app version that activated
└── ip_address          TEXT                 -- for audit only
```

### Activation history table

```
activation_history
├── id                  UUID PRIMARY KEY
├── license_id          UUID NOT NULL
├── device_id_hash      BYTEA NOT NULL
├── action              TEXT NOT NULL        -- 'activated', 'deactivated', 'transferred', 'support_reset'
├── performed_at        TIMESTAMPTZ NOT NULL
├── performed_by        TEXT                 -- 'user', 'support:admin_id'
├── reason              TEXT                 -- optional reason for support actions
└── metadata            JSONB
```

### Signing keys table

```
signing_keys
├── key_id              INTEGER PRIMARY KEY
├── public_key          BYTEA NOT NULL       -- 32-byte Ed25519 public key
├── status              TEXT NOT NULL        -- 'active', 'deprecated', 'revoked'
├── created_at          TIMESTAMPTZ NOT NULL
├── deprecated_at       TIMESTAMPTZ
├── revoked_at          TIMESTAMPTZ
└── rotation_reason     TEXT
```

### Critical unique constraints

| Constraint | Enforced By | Purpose |
|---|---|---|
| One license per business | `licenses.business_id` UNIQUE | Prevent duplicate licensing |
| One activation per license | Partial UNIQUE index on `activations(license_id) WHERE status='active'` | Enforce one-device invariant |
| One activation code per license | `licenses.activation_code` UNIQUE | Prevent code reuse |
| Unique device per license | Application-level check (not DB constraint, since device can change via transfer) | Business rule enforcement |

### Concurrency invariant

The `one_active_per_license` unique partial index ensures that even under concurrent database access, at most one activation record has `status='active'` for any given `license_id`. This is a database-level guarantee, not dependent on application-level locking.

## 18. One-Device Invariant

### Statement

```
FOR ANY license_id:
  COUNT(activations WHERE license_id = X AND status = 'active') <= 1
```

### Enforcement layers

| Layer | Mechanism | Failure mode |
|---|---|---|
| Database | Partial unique index on `(license_id) WHERE status = 'active'` | Database rejects second active activation |
| Application | SELECT + check before INSERT | Handles race condition gracefully |
| Client | Token contains device_id_hash; client verifies local device matches | Detects device mismatch offline |

### Race condition handling

```
Timeline:
  T1: Device A sends activation request
  T2: Device B sends activation request (before A's completes)
  T3: Server processes A → succeeds → one_active_per_license satisfied
  T4: Server processes B → database constraint violated → TRANSFER_REQUIRED returned

User experience:
  Device A: Shows "Activation successful"
  Device B: Shows "This license is active on another device. Transfer required."
```

## 19. Transfer / Deactivation

### Normal transfer — old device available

```
OLD DEVICE:
  1. User opens app on old device
  2. User navigates to Settings → License → Deactivate
  3. Client sends POST /api/v1/deactivate
  4. Server marks activation as 'deactivated'
  5. Server records in activation_history
  6. Client deletes local activation token (DPAPI file)
  7. Client transitions to UNINITIALIZED state

NEW DEVICE:
  8. User installs app on new device
  9. User enters activation code
  10. Client sends POST /api/v1/activate
  11. Server checks: no active device for this license → activation succeeds
  12. Server returns new signed entitlement token
  13. Client stores token → ACTIVE state
```

### Deactivation request

```
POST /api/v1/deactivate
Content-Type: application/json

{
  "license_id": "UUID-string",
  "device_id_hash": "base64-encoded hash",
  "idempotency_key": "UUID",
  "nonce": "random-bytes",
  "timestamp": "ISO-8601"
}
```

### Deactivation response — success

```
HTTP 200 OK

{
  "status": "deactivated",
  "license_id": "UUID-string",
  "deactivated_at": "ISO-8601"
}
```

### Transfer request

A transfer is a single API call that deactivates the old device and activates the new one atomically:

```
POST /api/v1/transfer
Content-Type: application/json

{
  "activation_code": "ITECH-XXXX-XXXX-XXXX",
  "new_device_id_hash": "base64-encoded hash",
  "idempotency_key": "UUID",
  "nonce": "random-bytes",
  "timestamp": "ISO-8601"
}
```

The server:
1. Validates the activation code
2. Checks the old device is the currently active device
3. Deactivates the old device
4. Activates the new device
5. Issues a new signed entitlement token
6. Returns the token

### Transfer response — success

```
HTTP 200 OK

{
  "status": "transferred",
  "entitlement_token": "base64-encoded CBOR-signed token",
  "business_id": "UUID-string",
  "license_id": "UUID-string",
  "activation_generation": 2,
  "key_id": 1
}
```

### Old device unavailable — support-assisted reset

When the old device is lost, broken, or inaccessible:

```
1. User contacts support with:
   a. Activation code (proof of license ownership)
   b. Business identity information (shop name, owner name, etc.)
2. Support verifies business identity against server records
3. Support executes support reset:
   POST /api/v1/support/reset
   {
     "license_id": "UUID-string",
     "reason": "Device lost/failure",
     "support_admin_id": "UUID-string"
   }
4. Server:
   a. Deactivates ALL active activations for this license
   b. Records in activation_history with support_admin_id and reason
   c. Optionally increments a "reset_generation" counter
5. User activates on new device normally
```

### Support reset request

```
POST /api/v1/support/reset
Content-Type: application/json
Authorization: Bearer <support_admin_token>

{
  "license_id": "UUID-string",
  "reason": "string — reason for reset",
  "support_admin_id": "UUID-string",
  "idempotency_key": "UUID",
  "nonce": "random-bytes",
  "timestamp": "ISO-8601"
}
```

### Important limitation — offline revocation

A previously valid signed entitlement on a permanently offline device cannot receive instant server revocation. This is a **physical limitation**, not a design flaw:

| Scenario | Behavior |
|---|---|
| Old device is online | Deactivation API call succeeds; token invalidated immediately |
| Old device is offline after deactivation | Local token still passes Ed25519 verification locally; app continues to function until next activation attempt or token expiry (if added in future) |
| Old device never reconnects | Token remains locally valid until the user tries to re-activate, update, or if expiry is added |
| Support reset executed while old device is offline | Old device's local token is cryptographically stale (activation_generation incremented); but locally it still passes signature check until next server contact |

**This is the accepted residual risk.** The system is designed so that:
1. The old device CANNOT activate on a new license (it has the old token, not a new one)
2. The old device CANNOT be used to activate a second device (the server knows the transfer happened)
3. The old device's local token will fail on next server contact (activation_generation mismatch)
4. If a future expiration field is added, the old token will expire naturally

## 20. Reinstall Behavior

### Same device — app reinstalled

| Step | Behavior |
|---|---|
| App is uninstalled | DPAPI activation file may persist in AppData (if user doesn't delete manually) |
| App is reinstalled | If DPAPI file persists → ACTIVE immediately |
| App is reinstalled (DPAPI file deleted) | UNINITIALIZED → user enters activation code → server recognizes same device_id_hash → reactivation succeeds |

### Same device — Windows reinstalled

| Step | Behavior |
|---|---|
| Windows is reinstalled | DPAPI activation file is lost (DPAPI context is new) |
| App is installed fresh | UNINITIALIZED |
| User enters activation code | Server receives device_id_hash → matches stored hash → reactivation succeeds |

### Same device — data wiped (clean start)

| Step | Behavior |
|---|---|
| Clean start executed | Business data wiped; `app_settings` preserved; DPAPI activation file UNAFFECTED (separate from DB) |
| App restarts | Reads DPAPI file → token valid → ACTIVE |

### New device — controlled transfer required

| Step | Behavior |
|---|---|
| App installed on new device | UNINITIALIZED |
| User enters activation code | Server receives device_id_hash → does NOT match → TRANSFER_REQUIRED |
| User deactivates old device (or contacts support) | Old device deactivated |
| User activates on new device | Server accepts → new token issued |

### Lost activation state but same hardware

| Step | Behavior |
|---|---|
| DPAPI file deleted or corrupted | LOCAL_STATE_CORRUPT |
| User re-activates with activation code | Server receives device_id_hash → matches → reactivation succeeds |

### Restored business backup

| Step | Behavior |
|---|---|
| Backup from machine A restored on machine B | Business data copied; DPAPI activation file NOT in backup |
| App on machine B | UNINITIALIZED (no activation token) |
| User must activate | Normal activation flow; if machine B is a different device, transfer may be needed |

## 21. Offline Verification

### What is verified locally

After successful activation, the client verifies the entitlement token locally on every app startup:

| Check | Description | Failure Result |
|---|---|---|
| File exists | DPAPI activation file exists | `UNINITIALIZED` |
| DPAPI decryption | File can be decrypted with current user context | `LOCAL_STATE_CORRUPT` |
| HMAC integrity | HMAC-SHA256 verification passes | `LOCAL_STATE_CORRUPT` |
| Token parsing | CBOR payload parses correctly | `LOCAL_STATE_CORRUPT` |
| Signature verification | Ed25519 signature valid with embedded public key | `INVALID_SIGNATURE` |
| `key_id` check | `key_id` in token matches a trusted key | `UNSUPPORTED_TOKEN_VERSION` |
| `token_version` check | Version is supported by this client | `UNSUPPORTED_TOKEN_VERSION` |
| `business_id` match | Token's `business_id` matches locally stored `business_id` | `BUSINESS_MISMATCH` |
| `device_id_hash` match | Token's `device_id_hash` matches current device fingerprint | `DEVICE_MISMATCH` |
| Token expiry (future) | If `expires_at` is present and in the future | `EXPIRED` (future) |

### Public key used for verification

The client uses the embedded public key (from the application binary) to verify the Ed25519 signature. This verification is purely local — no server contact required.

### Revocation limitations while offline

| Scenario | Limitation |
|---|---|
| Server revokes a license | Offline client cannot know until next server contact |
| Server resets activations (support) | Offline client's token remains locally valid until next server contact |
| Server rotates signing key | Offline client can still verify with its embedded key |

This is the accepted trade-off for offline runtime. The mitigation is:
1. Revoked/reset tokens fail on next server contact
2. Future token expiry (if added) provides automatic time-bounded validity
3. The system is designed for commercial courtesy enforcement, not absolute security

## 22. Entitlement State Machine

### States

| State | ID | Description |
|---|---|---|
| `UNINITIALIZED` | 0 | No activation has ever been performed on this installation |
| `ACTIVATION_REQUIRED` | 1 | User must activate to access protected operations |
| `ACTIVE` | 2 | Valid entitlement, verified, on correct device |
| `ACTIVE_RESTRICTED` | 3 | Entitlement valid but in restricted/safe mode (e.g., after expiry — future) |
| `INVALID_SIGNATURE` | 4 | Entitlement token signature verification failed |
| `LOCAL_STATE_CORRUPT` | 5 | Activation file exists but is corrupted/unreadable |
| `BUSINESS_MISMATCH` | 6 | Token's business_id does not match local business_id |
| `DEVICE_MISMATCH` | 7 | Token's device_id_hash does not match current device |
| `TRANSFER_REQUIRED` | 8 | Device mismatch indicates transfer needed |
| `REVOKED` | 9 | Server has revoked this license (detected on next server contact) |
| `UNSUPPORTED_TOKEN_VERSION` | 10 | Token version not supported by this client version |
| `ACTIVATING` | 11 | Activation request in progress (transient state) |

### State transitions

```
UNINITIALIZED ──[activate request]──► ACTIVATING
ACTIVATING ──[server success]──► ACTIVE
ACTIVATING ──[server error]──► ACTIVATION_REQUIRED
ACTIVATING ──[network unavailable]──► ACTIVATION_REQUIRED

ACTIVE ──[token corruption detected]──► LOCAL_STATE_CORRUPT
ACTIVE ──[device fingerprint changed]──► DEVICE_MISMATCH
ACTIVE ──[business_id mismatch]──► BUSINESS_MISMATCH
ACTIVE ──[token expired]──► ACTIVE_RESTRICTED (future)
ACTIVE ──[server revocation detected]──► REVOKED
ACTIVE ──[unsupported key_id]──► UNSUPPORTED_TOKEN_VERSION

ACTIVE ──[user initiates deactivation]──► UNINITIALIZED
ACTIVE ──[user initiates transfer]──► ACTIVATING

LOCAL_STATE_CORRUPT ──[re-activation success]──► ACTIVE
LOCAL_STATE_CORRUPT ──[user discards]──► UNINITIALIZED

DEVICE_MISMATCH ──[user transfers]──► ACTIVE (on new device)
DEVICE_MISMATCH ──[user contacts support]──► ACTIVATING (after support reset)

BUSINESS_MISMATCH ──[user contacts support]──► (investigation)

REVOKED ──[support reinstatement]──► ACTIVATING

UNSUPPORTED_TOKEN_VERSION ──[app update]──► ACTIVE (after update)

UNINITIALIZED ──[no activation attempt]──► ACTIVATION_REQUIRED (at enforcement boundary)
```

### State details

#### UNINITIALIZED

| Property | Value |
|---|---|
| Cause | Fresh installation, or activation file deleted |
| Evidence | No DPAPI activation file found |
| User-facing behavior | Activation prompt shown on first protected operation |
| Allowed operations | ALL read-only operations, backup, export, settings viewing, activation |
| Blocked operations | New sales, new expenses, new inventory adjustments, customer/supplier mutations, data wipe |
| Recovery route | Enter activation code → server activation → ACTIVE |
| Network required | YES (for activation) |

#### ACTIVATION_REQUIRED

| Property | Value |
|---|---|
| Cause | No valid entitlement; enforcement boundary reached |
| Evidence | Same as UNINITIALIZED (this is the operational state at enforcement time) |
| User-facing behavior | Activation screen with activation code input field |
| Allowed operations | ALL read-only operations, backup, export, activation |
| Blocked operations | Same as UNINITIALIZED |
| Recovery route | Enter activation code → ACTIVE |
| Network required | YES |

#### ACTIVE

| Property | Value |
|---|---|
| Cause | Valid entitlement token, verified signature, matching device and business |
| Evidence | DPAPI file contains valid signed token |
| User-facing behavior | Normal application operation; optional subtle indicator in settings |
| Allowed operations | ALL operations |
| Blocked operations | None |
| Recovery route | N/A (healthy state) |
| Network required | NO |

#### ACTIVE_RESTRICTED (Future — NOT active in initial implementation)

| Property | Value |
|---|---|
| Cause | Entitlement has expired (if expiry is added in future) |
| Evidence | Token's `expires_at` is in the past |
| User-facing behavior | Warning banner; restricted mode; activation/transfer available |
| Allowed operations | Read-only, backup, export, activation, transfer, reports |
| Blocked operations | New sales, new expenses, new inventory adjustments, mutations |
| Recovery route | Re-activate online → ACTIVE |
| Network required | YES (for re-activation) |

#### INVALID_SIGNATURE

| Property | Value |
|---|---|
| Cause | Ed25519 signature verification failed |
| Evidence | Token present, signature does not match |
| User-facing behavior | "License data appears invalid. Please reactivate." |
| Allowed operations | Read-only, backup, export, activation |
| Blocked operations | New commercial transactions |
| Recovery route | Re-activate → ACTIVE |
| Network required | YES |

#### LOCAL_STATE_CORRUPT

| Property | Value |
|---|---|
| Cause | DPAPI file exists but cannot be parsed, decrypted, or fails HMAC |
| Evidence | File exists, integrity check fails |
| User-facing behavior | "License data is corrupted. Please reactivate." |
| Allowed operations | Read-only, backup, export, activation |
| Blocked operations | New commercial transactions |
| Recovery route | Re-activate → ACTIVE (server recognizes same device) |
| Network required | YES |

#### BUSINESS_MISMATCH

| Property | Value |
|---|---|
| Cause | Token's business_id does not match locally stored business_id |
| Evidence | business_id comparison fails |
| User-facing behavior | "This license belongs to a different business. Contact support." |
| Allowed operations | Read-only, backup, export, activation, support contact |
| Blocked operations | New commercial transactions |
| Recovery route | Contact support for investigation |
| Network required | NO (but support contact may require internet) |

#### DEVICE_MISMATCH

| Property | Value |
|---|---|
| Cause | Device fingerprint has changed since activation |
| Evidence | device_id_hash in token does not match current device |
| User-facing behavior | "This device is different from the registered device. Transfer your license." |
| Allowed operations | Read-only, backup, export, transfer initiation, activation |
| Blocked operations | New commercial transactions |
| Recovery route | Transfer (if old device accessible) or support reset |
| Network required | YES (for transfer/activation) |

#### TRANSFER_REQUIRED

| Property | Value |
|---|---|
| Cause | Server determined that a transfer is needed |
| Evidence | Server response with TRANSFER_REQUIRED error |
| User-facing behavior | "Transfer your license to this device. Deactivate the old device or contact support." |
| Allowed operations | Read-only, backup, export, transfer initiation, support contact |
| Blocked operations | New commercial transactions |
| Recovery route | Deactivate old device + activate new, or support reset |
| Network required | YES |

#### REVOKED

| Property | Value |
|---|---|
| Cause | Server has revoked the license (e.g., non-payment, fraud) |
| Evidence | Server response indicating revocation during activation attempt |
| User-facing behavior | "Your license has been revoked. Contact support." |
| Allowed operations | Read-only, backup, export, support contact |
| Blocked operations | New commercial transactions |
| Recovery route | Contact support for reinstatement |
| Network required | YES (for detection and reinstatement) |

#### UNSUPPORTED_TOKEN_VERSION

| Property | Value |
|---|---|
| Cause | Token version not supported by this client build |
| Evidence | token_version > max supported version |
| User-facing behavior | "Please update the application to the latest version." |
| Allowed operations | Read-only, backup, export |
| Blocked operations | New commercial transactions |
| Recovery route | Update application → re-verify token → ACTIVE |
| Network required | NO (but update requires internet) |

#### ACTIVATING (transient)

| Property | Value |
|---|---|
| Cause | Activation request in progress |
| Evidence | Network request pending |
| User-facing behavior | Loading indicator "Activating..." |
| Allowed operations | None (waiting for server response) |
| Blocked operations | All (transient state) |
| Recovery route | Wait for response, or cancel → UNINITIALIZED |
| Network required | YES |

## 23. Enforcement Matrix

### Enforcement boundary principle

Licensing enforcement occurs at **deterministic application boundaries**:

1. **App startup**: After database initialization and defaults are loaded, before the main UI renders
2. **Session/login**: When a user session is created
3. **Feature access**: When a user navigates to a protected feature
4. **Operation initiation**: Before a protected business operation begins

Enforcement NEVER occurs:
1. Mid-transaction (after a business operation has started)
2. Inside database transaction callbacks
3. As a side effect of background operations

### Enforcement mechanism

```
On each enforcement boundary check:

1. Read DPAPI activation file
2. Verify integrity (HMAC, parsing)
3. Verify signature (Ed25519)
4. Verify business_id match
5. Verify device_id_hash match
6. Determine EntitlementState
7. Look up allowed/blocked operations for current state
8. If operation is blocked → show prompt, do NOT proceed
9. If operation is allowed → proceed normally

This check takes < 10ms (local file read + signature verification).
No network call is involved.
```

### Operation classification

| Operation | Category | Protected? |
|---|---|---|
| App startup | System | YES — determines initial state |
| Session/login creation | Auth | NO — always allowed |
| Dashboard access | Read | NO |
| Read existing records | Read | NO |
| View reports | Read | NO |
| Print existing records | Read | NO |
| Create new sale | Transaction | YES |
| Create new expense | Transaction | YES |
| Create new inventory adjustment | Transaction | YES |
| Create new invoice | Transaction | YES |
| Process return | Transaction | YES |
| Customer/supplier mutations | Mutation | YES |
| Product creation/editing | Mutation | YES |
| Settings changes (non-license) | Config | YES |
| License management (activate, transfer) | Recovery | NO — always allowed |
| Backup | Safety | NO — always allowed |
| Export data | Safety | NO — always allowed |
| Restore from backup | Safety | NO — always allowed |
| Data wipe (clean start) | Safety | NO — always allowed |
| Support information | Recovery | NO — always allowed |

### Enforcement matrix by state

| Operation | UNINITIALIZED | ACTIVE | INVALID_SIGNATURE | LOCAL_STATE_CORRUPT | DEVICE_MISMATCH | TRANSFER_REQUIRED | REVOKED | UNSUPPORTED_TOKEN_VERSION |
|---|---|---|---|---|---|---|---|---|
| Read records | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Reports | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Print existing | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Create sale | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| Create expense | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| Inventory adjust | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| Customer/supplier | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| Product mutation | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| Settings (non-license) | BLOCK | ALLOW | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |
| License activate | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| License transfer | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Backup | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Export | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Restore | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Data wipe | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Support info | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |

### In-flight transaction safety

```
CRITICAL RULE:
  Once a protected business operation has been AUTHORIZED (state check passed)
  and the database transaction has begun, the transaction MUST complete.

  Licensing state changes that occur during an in-flight transaction:
  - Are noted but NOT enforced mid-transaction
  - Take effect at the NEXT enforcement boundary
  - NEVER cause partial writes
  - NEVER corrupt accounting or inventory state
  - NEVER delete or modify records mid-transaction

Implementation pattern:
  1. Check entitlement state BEFORE beginning transaction
  2. If allowed, begin database transaction
  3. Execute entire business operation within transaction
  4. Commit transaction
  5. Check entitlement state again at next boundary

  The entitlement check is a GATE, not a SUBSCRIBER to transaction events.
```

## 24. Safe Data Access / Non-Destructive Enforcement

### Restricted mode (safe mode)

When entitlement is not valid, the application enters a **restricted mode** that:

1. **Protects the user's data**: All existing records remain fully accessible
2. **Allows data safety operations**: Backup, export, and data protection are always available
3. **Blocks new commercial operations**: Creating new sales, expenses, or mutations is restricted
4. **Provides clear recovery path**: Activation and transfer are always available
5. **Does not hold data hostage**: The user can always view, export, and back up their data

### Restricted mode capabilities

| Capability | Available? | Reason |
|---|---|---|
| View products | YES | Read-only; data safety |
| View sales history | YES | Read-only; data safety |
| View expenses | YES | Read-only; data safety |
| View reports | YES | Read-only; data safety |
| Print existing invoices | YES | Read-only; data safety |
| Export data (XLSX) | YES | Data safety; user data protection |
| Create backup | YES | Data safety; user data protection |
| Restore from backup | YES | Data safety; user data protection |
| Create new sale | NO | Protected commercial operation |
| Create new expense | NO | Protected commercial operation |
| Adjust inventory | NO | Protected commercial operation |
| Create/edit products | NO | Protected commercial operation |
| Process returns | NO | Protected commercial operation |
| Activate license | YES | Recovery path |
| Transfer license | YES | Recovery path |
| Contact support | YES | Recovery path |

### Why this model is NOT ransomware-like

1. The user can ALWAYS access their existing data
2. The user can ALWAYS back up their data
3. The user can ALWAYS export their data
4. The user can ALWAYS print their existing records
5. The only restriction is on CREATING new commercial transactions
6. The recovery path (activation) is always available
7. The restriction is proportional to the licensing model (1 device per business)

### Why this model IS enforceable

1. The restriction is meaningful: a shop cannot operate without creating sales
2. The restriction is at the right boundary: before transactions begin, not mid-operation
3. The restriction is recoverable: activation is available immediately
4. The restriction does not destroy data: existing records remain accessible
5. The restriction is proportional: it matches the commercial model

## 25. Backup / Restore Contract

### Business backup = business data disaster recovery

Backup is a data-safety feature. It preserves business data for disaster recovery.

Backup MUST NOT function as portable device activation.

### Backup content

| Content | Included in backup? | Reason |
|---|---|---|
| Products | YES | Business data |
| Sales | YES | Business data |
| Returns | YES | Business data |
| Expenses | YES | Business data |
| Invoices | YES | Business data |
| Inventory counts | YES | Business data |
| Import batches | YES | Business data |
| Expense categories | YES | Business data |
| Users | YES | Business data (preserved during clean start) |
| Role permissions | YES | Configuration (preserved during clean start) |
| App settings | YES | Configuration (preserved during clean start) |
| License key / status (legacy) | YES (in app_settings) | Legacy fields; not used for entitlement |
| **Entitlement token** | **NO** | **Machine-local, DPAPI-protected, NOT in database** |
| **Activation metadata** | **NO** | **Machine-local, DPAPI-protected, NOT in database** |

### Backup behavior scenarios

| Scenario | Backup allowed? | License state in backup? | Notes |
|---|---|---|---|
| Activated machine | YES | Legacy fields only | Entitlement token is not in DB |
| Unactivated machine | YES | Legacy fields only | Same |
| Server unavailable | YES | N/A | Backup is offline operation |

### Restore behavior scenarios

| Scenario | Restore allowed? | License state after restore? | Notes |
|---|---|---|---|
| Same machine, restore over existing | YES | Unchanged (DPAPI file unaffected) | Entitlement token is separate from DB |
| Same machine, clean restore | YES | Unchanged (DPAPI file unaffected) | Business data replaced; activation preserved |
| New machine | YES | UNINITIALIZED | No DPAPI file on new machine; activation needed |
| New machine, over existing activation | YES | UNINITIALIZED (new DB) or existing (if DB overlay) | Activation from old machine not portable |
| Business ID mismatch (restore from different business) | YES | UNINITIALIZED | Different business needs its own activation |
| Duplicate restored database | YES | Depends on machine | License is not in the DB |

### Backup does NOT depend on licensing server

Backup creation is a purely local operation:
1. Reads the local database
2. Creates a copy via `VACUUM INTO`
3. Verifies integrity
4. Returns result

No network call is made during backup. No licensing server is contacted.

### Anti-clone mechanism

```
Machine A (licensed):
  ├── muaman_store.db (business data)
  └── activation.dat (DPAPI-protected entitlement)

User copies muaman_store.db to Machine B:
  Machine B:
  ├── muaman_store.db (business data — copied)
  └── (no activation.dat — DPAPI file NOT in backup)

Result on Machine B:
  - All business data accessible
  - Entitlement state: UNINITIALIZED
  - User must activate on Machine B
  - If Machine B is a different device → transfer may be required
```

### Current implementation impact

The current backup/restore system (`StandaloneBackupService`, `StandaloneRestoreService`) uses `VACUUM INTO` to copy the entire database. Since the entitlement token is stored in a DPAPI-protected file OUTSIDE the database, the existing backup/restore implementation naturally achieves the separation required by this contract.

**No changes to the backup/restore implementation are required** to achieve backup/activation separation. The separation is structural: entitlement is in a DPAPI file, business data is in SQLite.

## 26. Migration from Existing Cosmetic Licensing

### Current state

| Field | Current behavior | T3-2 behavior |
|---|---|---|
| `licenseKey` in `app_settings` | Stores any `MUAMAN-*` string | PRESERVED as legacy; NOT used for entitlement |
| `licenseStatus` in `app_settings` | Stores `'active'` or `'inactive'` | PRESERVED as legacy; NOT used for entitlement |
| `validateLicenseKey()` | Accepts any `MUAMAN-*` key with 12+ chars | PRESERVED as dead code; NOT called by new system |
| Settings screen license UI | TextField + activate button | Will be replaced by activation/transfer UI |

### Migration rules

| Rule | Description |
|---|---|
| Legacy keys preserved | `licenseKey` and `licenseStatus` rows remain in `app_settings` |
| Legacy keys ignored | The new entitlement system NEVER reads or trusts these values |
| No automatic migration | Existing cosmetic keys do NOT automatically become valid entitlement |
| No data loss | Legacy keys are not deleted; they are simply not used |
| New business_id | Generated at first activation after T3-2 implementation |
| Clean start preserves | `app_settings` (including legacy keys) survives clean start |
| Backup includes | Legacy keys in `app_settings` (harmlessly) |

### Migration flow for existing installations

```
1. User installs new version (with T3-2 licensing)
2. App starts → EntitlementState = UNINITIALIZED (no DPAPI file)
3. Legacy licenseStatus may still be 'active' in app_settings
4. New system IGNORES legacy licenseStatus
5. User is prompted to activate with new activation code
6. Server validates, issues signed entitlement token
7. Token stored in DPAPI file
8. EntitlementState = ACTIVE
9. Legacy licenseKey/licenseStatus remain in app_settings but are unused
```

### Grandfathering — technical hook

The architecture supports a grandfathering path, but the commercial decision is deferred:

**Option A — No grandfathering (activation required):**
- All existing installations must activate with new activation codes
- Legacy cosmetic keys are simply ignored
- This is the default behavior

**Option B — Grandfathering with grace period:**
- Existing installations with `licenseStatus == 'active'` and a `licenseKey` matching `MUAMAN-*` pattern
- Are granted a grace period (configurable, e.g., 30/60/90 days)
- During grace period: full operation allowed (treated as ACTIVE)
- After grace period: must activate with new system
- This requires a technical hook but not an immediate commercial decision

**The architecture supports both options. The choice is a future owner decision (§39).**

## 27. Failure Behavior

### Corrupt local activation state

| Aspect | Behavior |
|---|---|
| Detection | HMAC verification or DPAPI decryption fails |
| State | `LOCAL_STATE_CORRUPT` |
| User sees | "License data is corrupted. Please reactivate." |
| Business data | Unaffected |
| Recovery | Re-activate with activation code |
| Network needed | YES |

### Invalid signature

| Aspect | Behavior |
|---|---|
| Detection | Ed25519 signature verification fails |
| State | `INVALID_SIGNATURE` |
| User sees | "License data appears invalid. Please reactivate." |
| Business data | Unaffected |
| Recovery | Re-activate with activation code |
| Network needed | YES |

### Wrong device

| Aspect | Behavior |
|---|---|
| Detection | device_id_hash in token does not match current device |
| State | `DEVICE_MISMATCH` / `TRANSFER_REQUIRED` |
| User sees | "This device is different from the registered device. Transfer your license." |
| Business data | Unaffected |
| Recovery | Transfer or support reset |
| Network needed | YES |

### Wrong business

| Aspect | Behavior |
|---|---|
| Detection | business_id in token does not match local business_id |
| State | `BUSINESS_MISMATCH` |
| User sees | "This license belongs to a different business. Contact support." |
| Business data | Unaffected |
| Recovery | Support investigation |
| Network needed | NO (but support contact may) |

### Unsupported token version

| Aspect | Behavior |
|---|---|
| Detection | token_version > max supported by client |
| State | `UNSUPPORTED_TOKEN_VERSION` |
| User sees | "Please update the application to the latest version." |
| Business data | Unaffected |
| Recovery | Update application |
| Network needed | NO (but update requires internet) |

### Server unavailable during new activation

| Aspect | Behavior |
|---|---|
| Detection | Network timeout or server error during activation request |
| State | `ACTIVATION_REQUIRED` (unchanged) |
| User sees | "Could not connect to activation server. Please try again." |
| Business data | Unaffected |
| Recovery | Retry when server is available |
| Network needed | YES |

### Activation replay attempt

| Aspect | Behavior |
|---|---|
| Detection | Server detects reused nonce |
| Response | `REQUEST_REPLAYED` error |
| User sees | "Activation request already processed. Please try again." |
| Business data | Unaffected |
| Recovery | New activation request with fresh nonce |
| Network needed | YES |

### Concurrent activation

| Aspect | Behavior |
|---|---|
| Detection | Database constraint `one_active_per_license` |
| Response | One succeeds, one gets `TRANSFER_REQUIRED` |
| User sees | Success on first device; transfer prompt on second |
| Business data | Unaffected on both devices |
| Recovery | Normal transfer flow |
| Network needed | YES |

## 28. Clock Policy

### Design principle

Core perpetual/offline licensing must NOT be dependent on fragile system-clock assumptions.

### Clock scenarios

| Scenario | Detection | Behavior | Impact |
|---|---|---|---|
| Clock rollback (Windows time set back) | Token `issued_at` in the future relative to system clock | Soft warning; no hard lockout | Minimal — token still verified for signature |
| Clock jump forward | Token `expires_at` (if present) appears expired | Warning banner; restricted mode (if expiry added in future) | Low — affects future expiry, not core verification |
| Timezone change | No impact on epoch-based timestamps | None | None |
| DST change | No impact on epoch-based timestamps | None | None |
| Invalid system clock (year 2099) | Anomaly detection: `issued_at` far in the future | Warning notification; no hard lockout | Low |
| Offline + clock manipulated | Token verified locally; clock affects expiry only | If no expiry field: no impact | None for current architecture |

### Clock handling for current architecture

Since the initial token format (v1) does NOT include an `expires_at` field, clock manipulation has **no impact** on core licensing verification in the current design. Token verification is based on:

1. Signature validity (cryptographic, not time-dependent)
2. Business ID match (not time-dependent)
3. Device ID match (not time-dependent)
4. Key ID trust (not time-dependent)

Clock becomes relevant only when a future `expires_at` field is added. At that point:

- The `expires_at` field will be relative to server time (embedded in the token at signing time)
- Client will compare `expires_at` against system clock with a configurable tolerance window (e.g., ±24 hours)
- Obvious clock manipulation (e.g., system clock set to year 1999) will trigger a warning but not a hard lockout
- The system will prefer "allow with warning" over "deny and corrupt data"

## 29. Threat Model

### Threat classification

| Threat | Classification | Mitigation |
|---|---|---|
| Editing `app_settings` rows | **PREVENTED** | New system ignores `app_settings` licensing values; entitlement is in DPAPI file |
| Copying DPAPI activation file to another PC | **PREVENTED** | DPAPI decryption tied to Windows user + machine; HMAC tied to MachineGuid |
| Copying business database to another PC | **PREVENTED (for licensing)** | Database contains no entitlement; new PC requires activation |
| Copying entitlement token to another PC | **PREVENTED** | DPAPI + HMAC + device_id_hash verification |
| Replaying activation response | **PREVENTED** | Nonce + timestamp + server-side nonce tracking |
| Activation endpoint replay | **PREVENTED** | Idempotency key + nonce + timestamp |
| Activation race (two devices simultaneously) | **PREVENTED** | Database constraint `one_active_per_license` |
| Device fingerprint spoofing | **MITIGATED** | WMI values are not easily spoofed by casual users; a determined attacker with admin access could spoof, but this is accepted residual risk |
| Clock manipulation | **MITIGATED** | No expiry in v1; future expiry will use tolerance window |
| Patching client enforcement | **ACCEPTED RESIDUAL RISK** | Client-side enforcement is commercial courtesy, not absolute security; a determined attacker with binary modification tools can bypass client checks |
| Extracting embedded public key | **NOT A THREAT** | Public key is not secret; extraction has no security impact |
| Extracting server endpoints from client | **DETECTABLE** | API endpoints are not secret; server validates all requests independently |
| Offline cloning (copy entire machine image) | **MITIGATED** | Cloned machine would have same device_id_hash; but activation_generation tracking and server-side records detect anomalies |
| Support reset abuse | **MITIGATED** | Support resets require business identity verification, are logged with admin ID, and are auditable |
| Brute-force activation code guessing | **MITIGATED** | Rate limiting on activation endpoint; activation codes are long enough to prevent practical brute-force |
| Man-in-the-middle during activation | **MITIGATED** | HTTPS/TLS for all activation server communication |
| Server database breach | **ACCEPTED RESIDUAL RISK** | Server stores device_id_hash (not raw hardware), activation history; no business operational data; breach does not expose customer financial data |

### Explicit acknowledgment

> Client-side enforcement raises the cost of casual piracy and supports commercial
> control. It is NOT mathematically equivalent to perfect piracy prevention. A
> determined attacker with administrative access to the Windows machine can bypass
> client-side licensing checks. This is an accepted and standard reality for
> desktop application licensing.

## 30. Privacy / Data Minimization

### Data sent to activation server

| Data | Sent? | Justification |
|---|---|---|
| Activation code | YES | Required to identify the license |
| Device fingerprint hash (SHA-256) | YES | Required for device binding |
| Client version | YES | Diagnostic; support |
| IP address | YES (server-side) | Audit trail; abuse detection |
| Timestamp | YES | Audit trail; replay protection |
| Idempotency key | YES | Duplicate request handling |
| Nonce | YES | Replay protection |

### Data NOT sent to activation server

| Data | Sent? | Reason |
|---|---|---|
| Raw hardware identifiers (MachineGuid, CPU ID, Board Serial) | NO | Only the derived hash is sent |
| Business operational data (sales, inventory, expenses) | NO | Not relevant to licensing |
| Customer data | NO | Not relevant to licensing |
| Supplier data | NO | Not relevant to licensing |
| Invoice contents | NO | Not relevant to licensing |
| Financial records | NO | Not relevant to licensing |
| Owner personal information | NO | Not relevant to licensing |
| Shop display name | NO | Not relevant to licensing (business_id is sufficient) |
| Employee data | NO | Not relevant to licensing |
| Database contents | NO | Not relevant to licensing |
| Browsing behavior | NO | Not collected |
| Location data | NO | Not collected |
| Application usage patterns | NO | Not collected |

### Server-side data retention

| Data | Retention | Reason |
|---|---|---|
| License records | Indefinite (while license is active) | Business record |
| Activation records | Indefinite (while license is active) | Audit trail |
| Activation history | Indefinite | Audit trail; support |
| Device fingerprint hashes | While license is active | Device binding |
| IP addresses | 90 days rolling window | Abuse detection |
| Nonces | 24 hours | Replay protection |
| Idempotency keys | 24 hours | Duplicate handling |

## 31. Server Independence of Business Runtime

### Normal runtime — no server dependency

After successful activation:
- The application runs entirely offline
- No periodic online check is required
- No heartbeat to the server
- No license renewal check
- No subscription status poll

### Server failure during different operations

| Operation | Server required? | Behavior if server down |
|---|---|---|
| Normal business operations | NO | No impact; app runs normally |
| Viewing records | NO | No impact |
| Creating sales | NO | No impact (if ACTIVE) |
| Creating expenses | NO | No impact (if ACTIVE) |
| Reports | NO | No impact |
| Backup | NO | No impact |
| Export | NO | No impact |
| Printing | NO | No impact |
| **New activation** | **YES** | Prompt retry; activation deferred |
| **Transfer** | **YES** | Prompt retry; transfer deferred |
| **Support reset** | **YES** | Prompt retry; support must perform reset |
| **Deactivation** | **YES** | Prompt retry; deactivation deferred |

### Server downtime scenarios

| Scenario | Impact on active installations | Impact on new activations |
|---|---|---|
| Brief outage (< 1 hour) | None | Retry needed |
| Extended outage (hours) | None | Deferred until server restored |
| Maintenance window | None | Deferred; server should announce maintenance |
| DNS failure | None | Retry needed (or use IP if configured) |
| TLS failure | None | Retry needed |
| Complete server decommission | None for existing activations | New activations impossible; must deploy new server |

## 32. Dependency Implications

### Dependencies required for implementation

| Category | Candidate | Why needed | Dart/Flutter standard? | Windows implications |
|---|---|---|---|---|
| Asymmetric crypto | `ed25519` or `cryptography` package | Ed25519 signing/verification | NO — third-party package needed | None (pure Dart) |
| CBOR serialization | `cbor` package | Deterministic token serialization | NO — third-party package needed | None (pure Dart) |
| HTTP client | `http` or `dio` package | Activation server communication | `http` is semi-standard; `dio` is third-party | None |
| Secure local storage | Windows DPAPI via `win32` package or FFI | Encrypted activation file storage | NO — platform-specific | Windows-only; uses `CryptProtectData` API |
| Device identity | WMI queries via `win32` package or FFI | CPU ID, Board Serial for fingerprint | NO — platform-specific | Windows-only; uses WMI |
| JSON (if used instead of CBOR) | `dart:convert` | JSON serialization | YES — standard Dart | None |
| UUID generation | `uuid` package | business_id, license_id generation | NO — third-party | None (pure Dart) |

### Dependency risk assessment

| Dependency | Maintenance risk | Security risk | License risk |
|---|---|---|---|
| `ed25519` / `cryptography` | Low — mature crypto library | Low — standard algorithm | Permissive |
| `cbor` | Low — stable format | Low — serialization only | Permissive |
| `http` | Low — widely used | Low — standard HTTP | Permissive |
| `win32` | Medium — Windows API wrapper | Medium — requires correct API usage | MIT |
| `uuid` | Low — stable utility | Low — UUID generation only | Permissive |

### Recommendation

Defer final dependency selection to the implementation stage. The T3-2 contract specifies the algorithms and interfaces, not the specific package versions. The implementation agent should:

1. Check the latest stable versions of candidate packages
2. Verify Windows desktop compatibility
3. Verify no Android/iOS-only limitations
4. Select based on maintenance activity, security audit history, and license compatibility

## 33. API Error Contract

### Error response format

```json
{
  "error": {
    "code": "DEVICE_MISMATCH",
    "message": "Device fingerprint does not match the registered device.",
    "retryable": false,
    "support_required": true
  }
}
```

### Error classification

#### Retryable errors

| Error Code | HTTP Status | Meaning | Retry strategy |
|---|---|---|---|
| `SERVER_TEMPORARILY_UNAVAILABLE` | 503 | Server is temporarily down | Exponential backoff, max 5 retries |
| `ACTIVATION_RATE_LIMITED` | 429 | Too many requests | Wait for retry-after header |
| `NETWORK_TIMEOUT` | 408 / timeout | Request timed out | Retry once after 5 seconds |

#### Permanent errors

| Error Code | HTTP Status | Meaning | User action |
|---|---|---|---|
| `LICENSE_NOT_FOUND` | 404 | Activation code not recognized | Check code; contact support |
| `LICENSE_DISABLED` | 403 | License disabled by admin | Contact support |
| `TOKEN_VERSION_UNSUPPORTED` | 400 | Client version too old | Update application |
| `INVALID_PARAMETERS` | 400 | Malformed request | Update application (bug) |

#### Support-required errors

| Error Code | HTTP Status | Meaning | User action |
|---|---|---|---|
| `TRANSFER_REQUIRED` | 409 | Another device is active | Deactivate old device or contact support |
| `DEVICE_MISMATCH` | 400 | Device changed | Transfer or contact support |
| `BUSINESS_MISMATCH` | 400 | Business identity mismatch | Contact support |
| `REVOKED` | 403 | License revoked | Contact support |

#### Local-corruption errors

| Error Code | Source | Meaning | User action |
|---|---|---|---|
| `LOCAL_STATE_CORRUPT` | Local verification | Activation file corrupted | Re-activate |
| `INVALID_SIGNATURE` | Local verification | Token signature invalid | Re-activate |
| `BUSINESS_MISMATCH` | Local verification | Business ID mismatch | Contact support |
| `DEVICE_MISMATCH` | Local verification | Device fingerprint changed | Transfer or support |

### Error handling in client

```
On server response:
  1. Parse error code
  2. If retryable → retry with backoff (max retries)
  3. If permanent → show user message; no retry
  4. If support-required → show user message with support contact
  5. If local-corruption → transition to appropriate EntitlementState
  6. NEVER silently ignore errors
  7. NEVER delete business data on error
  8. NEVER modify financial records on error
```

## 34. UX Contract

### First activation

```
Screen: "تفعيل الرخصة" (License Activation)
Content:
  - Arabic instruction text explaining activation is required
  - Text input field for activation code (ITECH-XXXX-XXXX-XXXX format hint)
  - "تفعيل" (Activate) button
  - "هل لديك مشكلة؟ اتصل بالدعم" (Having trouble? Contact support) link
Behavior:
  - Button disabled until code is entered
  - Loading spinner during activation
  - On success → normal app
  - On error → appropriate error message
```

### Successful activation

```
Screen: Normal application
Indicator: Optional subtle "الرخصة نشطة" (License Active) in Settings
Behavior:
  - Full application functionality
  - No interruption, no prompt
```

### Offline active state

```
Indicator: None during normal operation
Settings may show: "آخر تحقق: [date]" (Last verified: [date])
No warning, no prompt, no interruption
```

### Invalid / corrupt local entitlement

```
Screen: "بيانات الرخصة غير صالحة" (License data is invalid)
Content:
  - Clear message in Arabic
  - "يرجى إعادة تفعيل الرخصة" (Please reactivate your license)
  - Activation code input field
  - "تفعيل" (Activate) button
  - Existing data is safe message: "بياناتك آمنة" (Your data is safe)
Behavior:
  - User can reactivate immediately
  - User can navigate to backup/export before reactivating
```

### Device mismatch

```
Screen: "جهاز مختلف" (Different device)
Content:
  - "هذا الجهاز مختلف عن الجهاز المسجل" (This device is different from the registered device)
  - Options:
    a. "نقل الرخصة" (Transfer license) — if old device accessible
    b. "اتصل بالدعم" (Contact support) — if old device not accessible
  - "بياناتك آمنة على هذا الجهاز" (Your data is safe on this device)
Behavior:
  - User can view/export/back up data
  - User cannot create new commercial transactions
```

### Transfer required

```
Screen: "نقل مطلوب" (Transfer required)
Content:
  - "الرخصة نشطة على جهاز آخر" (License is active on another device)
  - "يرجى نقل الرخصة إلى هذا الجهاز" (Please transfer the license to this device)
  - Steps explanation in Arabic
  - Support contact information
Behavior:
  - User can view/export/back up data
  - User cannot create new commercial transactions
```

### Server unavailable during activation

```
Screen: Activation screen with error
Content:
  - "تعذر الاتصال بخادم التفعيل" (Could not connect to activation server)
  - "يرجى المحاولة مرة أخرى" (Please try again)
  - "_retry" button
Behavior:
  - Retry available
  - App remains in current state
```

### Support reset path

```
Screen: Support information
Content:
  - "معلومات الدعم" (Support Information)
  - Your activation code: [displayed from app_settings legacy key or from user input]
  - Your business name: [from shop profile]
  - "اتصل بالدعم الفني للحصول على المساعدة" (Contact technical support for assistance)
Behavior:
  - User can copy support information
  - User can initiate activation/transfer after support resets
```

### Safe mode / restricted state

```
Screen: Normal app with restrictions
Indicator: Subtle warning banner: "الرخصة غير مفعلة — الوضع المحدود" (License not activated — restricted mode)
Content:
  - All existing data visible
  - Reports accessible
  - Backup/export accessible
  - New transaction buttons show locked icon or disabled with tooltip
Behavior:
  - Clear communication about what is restricted
  - Clear path to activation
  - No data loss, no panic
```

### Arabic language considerations

All user-facing licensing messages must be in Arabic (the primary language of the application). Technical terms (activation code, license key) may use Latin characters as they are formatted that way. Error messages must use clear, non-technical Arabic that a shop owner can understand.

## 35. Schema / Storage Design

### Local activation state (client-side)

**NOT a database table.** This is a DPAPI-protected binary file.

```
File: %LOCALAPPDATA%\I-TECH\licensing\activation.dat

Structure (conceptual):
  version        : uint8        -- file format version (1)
  token_bytes    : bytes        -- CBOR-encoded entitlement token
  business_id    : UUID string  -- local copy for quick comparison
  device_hash    : bytes        -- local copy of device fingerprint hash
  metadata       : map
    created_at   : epoch        -- when this file was created
    last_check   : epoch        -- last successful verification
    activation_n : uint16       -- local activation count
  hmac           : bytes        -- HMAC-SHA256 integrity check
```

### Server-side schema (conceptual)

```
licenses
  license_id       UUID PK
  business_id      UUID UNIQUE NOT NULL
  activation_code  TEXT UNIQUE NOT NULL
  product_id       TEXT NOT NULL
  status           TEXT NOT NULL  -- 'active', 'disabled', 'revoked'
  device_limit     INT NOT NULL DEFAULT 1
  tier             TEXT NOT NULL DEFAULT 'standard'
  issued_at        TIMESTAMPTZ NOT NULL
  created_by       TEXT
  metadata         JSONB

businesses
  business_id      UUID PK
  display_name     TEXT
  created_at       TIMESTAMPTZ NOT NULL
  license_id       UUID FK → licenses
  metadata         JSONB

activations
  id               UUID PK
  license_id       UUID NOT NULL FK → licenses
  device_id_hash   BYTEA NOT NULL
  status           TEXT NOT NULL DEFAULT 'active'
  activated_at     TIMESTAMPTZ NOT NULL
  deactivated_at   TIMESTAMPTZ
  activation_gen   INT NOT NULL
  client_version   TEXT
  ip_address       TEXT

activation_history
  id               UUID PK
  license_id       UUID NOT NULL
  device_id_hash   BYTEA NOT NULL
  action           TEXT NOT NULL  -- 'activated', 'deactivated', 'transferred', 'support_reset'
  performed_at     TIMESTAMPTZ NOT NULL
  performed_by     TEXT
  reason           TEXT
  metadata         JSONB

signing_keys
  key_id           INT PK
  public_key       BYTEA NOT NULL
  status           TEXT NOT NULL  -- 'active', 'deprecated', 'revoked'
  created_at       TIMESTAMPTZ NOT NULL
  deprecated_at    TIMESTAMPTZ
  revoked_at       TIMESTAMPTZ
  rotation_reason  TEXT
```

### Indexes (material)

```sql
-- Enforce one active device per license
CREATE UNIQUE INDEX idx_one_active_per_license
  ON activations (license_id)
  WHERE status = 'active';

-- Fast lookup by activation code
CREATE UNIQUE INDEX idx_license_by_code
  ON licenses (activation_code);

-- Fast lookup by business
CREATE UNIQUE INDEX idx_license_by_business
  ON licenses (business_id);

-- Activation history audit
CREATE INDEX idx_history_by_license
  ON activation_history (license_id, performed_at DESC);

-- Rate limiting
CREATE INDEX idx_activations_by_ip
  ON activations (ip_address, activated_at DESC);
```

## 36. Testing Contract

### Unit tests — Cryptography

| Test | Expected |
|---|---|
| Valid signed entitlement verifies successfully | PASS |
| Tampered payload fails verification | FAIL (as expected) |
| Invalid signature fails verification | FAIL (as expected) |
| Wrong public key fails verification | FAIL (as expected) |
| Token with wrong business_id detected | BUSINESS_MISMATCH |
| Token with wrong device_id_hash detected | DEVICE_MISMATCH |
| Unsupported token_version detected | UNSUPPORTED_TOKEN_VERSION |
| Corrupted local state detected | LOCAL_STATE_CORRUPT |
| CBOR round-trip preserves all fields | PASS |
| HMAC verification catches file modification | FAIL (as expected) |

### Unit tests — Activation

| Test | Expected |
|---|---|
| First activation succeeds | ACTIVE |
| Same-device reactivation is idempotent | ACTIVE (same token or refreshed) |
| Second different device rejected | TRANSFER_REQUIRED |
| Deactivation then activation succeeds | ACTIVE |
| Concurrent activation race preserves one-device invariant | One succeeds, one fails |
| Activation with invalid code fails | LICENSE_NOT_FOUND |
| Activation with disabled license fails | LICENSE_DISABLED |
| Replay attempt rejected | REQUEST_REPLAYED |
| Idempotent duplicate request returns same result | Same response |

### Unit tests — Offline

| Test | Expected |
|---|---|
| Valid activated app starts with no network | ACTIVE |
| App restart remains usable offline | ACTIVE |
| Server outage does not break valid activation | ACTIVE |
| Device fingerprint computed correctly on same machine | Deterministic |
| Device fingerprint changes on different hardware | Different hash |
| Business ID persisted in DPAPI file | Match with token |

### Unit tests — Backup/Restore

| Test | Expected |
|---|---|
| Backup does not include DPAPI activation file | Entitlement not in backup |
| Restore same machine retains activation | ACTIVE (DPAPI file unaffected) |
| Restore new machine requires activation | UNINITIALIZED |
| Business ID from backup does not affect activation | Independent |
| Clean start does not delete DPAPI file | ACTIVE (if DPAPI file exists) |

### Unit tests — Enforcement

| Test | Expected |
|---|---|
| Protected operation blocked before transaction starts | BLOCKED |
| Allowed operation proceeds normally | ALLOWED |
| License transition does not break in-flight transaction | Transaction completes |
| Read-only operations always allowed | ALLOWED |
| Backup always allowed | ALLOWED |
| Export always allowed | ALLOWED |
| Activation always allowed | ALLOWED |

### Unit tests — Migration

| Test | Expected |
|---|---|
| Legacy cosmetic key/status not used as entitlement | UNINITIALIZED |
| New activation after legacy data works correctly | ACTIVE |
| Legacy keys preserved in app_settings | Present but unused |

### Integration tests — Activation server

| Test | Expected |
|---|---|
| Full activation flow end-to-end | ACTIVE |
| Full transfer flow end-to-end | ACTIVE (new device) |
| Support reset flow end-to-end | ACTIVE (after reset) |
| Deactivation flow end-to-end | UNINITIALIZED |
| Server-side one-device invariant maintained | Only one active per license |

## 37. Implementation Sequencing

### Recommended implementation order

```
PHASE 1: Foundation (no user-visible change)
├── 1.1 DPAPI local storage service
├── 1.2 Device fingerprint computation
├── 1.3 Ed25519 verification (with test keypair)
├── 1.4 CBOR serialization
├── 1.5 Entitlement token parser/verifier
└── 1.6 EntitlementState manager

PHASE 2: Server foundation (deployed separately)
├── 2.1 Database schema (licenses, businesses, activations, etc.)
├── 2.2 Ed25519 key generation and management
├── 2.3 Activation API endpoint
├── 2.4 Deactivation API endpoint
├── 2.5 Transfer API endpoint
├── 2.6 Support reset API endpoint
└── 2.7 Admin dashboard (basic)

PHASE 3: Client-server integration
├── 3.1 HTTP client for activation server
├── 3.2 Activation flow (UI + service)
├── 3.3 Deactivation flow
├── 3.4 Transfer flow
└── 3.5 Error handling and retry logic

PHASE 4: Enforcement
├── 4.1 EntitlementState check at app startup
├── 4.2 EntitlementState check at operation boundaries
├── 4.3 Restricted mode UI
├── 4.4 Safe-mode data access
└── 4.5 Migration from legacy licensing

PHASE 5: Polish
├── 5.1 UX refinement (Arabic messages, error states)
├── 5.2 Support information display
├── 5.3 Clock tolerance handling (if expiry added)
└── 5.4 Comprehensive test suite
```

### Dependency graph

```
1.1 DPAPI storage ─┐
1.2 Device fingerprint ─┤
1.3 Ed25519 verification ─┤── 1.6 EntitlementState manager ── 4.1-4.5 Enforcement
1.4 CBOR serialization ─┤                                              │
1.5 Token parser ───────┘                                              │
                                                                       │
2.1-2.7 Server ────── 3.1-3.5 Client-server ──────────────────────────┘
```

### Risk-reduction order

The phases are ordered to reduce risk:
1. **Phase 1** validates that DPAPI, device fingerprinting, and crypto work on Windows desktop
2. **Phase 2** can be developed in parallel (server is independent)
3. **Phase 3** integrates client and server; integration issues surface here
4. **Phase 4** adds enforcement; this is where the enforcement matrix is validated
5. **Phase 5** is polish and edge cases

## 38. Contradiction Audit

### Business license vs device binding

**Test:** The license belongs to the business, but one device is the activation target.

**Resolution:** These concepts are NOT conflated. The `business_id` is the licensing subject. The `device_id_hash` is the activation binding. A business can transfer its license between devices. The business identity persists across device changes. The device is a constraint, not the subject.

**Result:** NO CONTRADICTION.

### Offline runtime vs revocation

**Test:** Do not promise instant remote revocation of a permanently offline installation.

**Resolution:** The contract explicitly acknowledges this limitation (§19, "Important limitation — offline revocation"). A permanently offline device with a valid signed entitlement will continue to pass local verification until the token expires (if expiry is added) or until the device next contacts the server. This is documented as accepted residual risk, not hidden.

**Result:** NO CONTRADICTION.

### Backup portability vs activation binding

**Test:** Business backup must not silently clone activation.

**Resolution:** The entitlement token is stored in a DPAPI-protected file SEPARATE from the business database. `VACUUM INTO` copies only the SQLite database, not the DPAPI file. Backup naturally excludes activation state. No changes to the backup/restore implementation are required.

**Result:** NO CONTRADICTION.

### Same-device reinstall vs one-device limit

**Test:** Same-device reinstall should not automatically look like a second commercial device.

**Resolution:** The device fingerprint is based on stable hardware identifiers (MachineGuid, CPU ID, Board Serial) that survive app reinstall and Windows reinstall. The server recognizes the same device_id_hash and issues a new token without consuming a new commercial seat.

**Result:** NO CONTRADICTION.

### Enforcement vs data safety

**Test:** Invalid entitlement must not destroy data, but enforcement must still have meaningful effect.

**Resolution:** The enforcement matrix (§23) blocks NEW commercial transactions but allows ALL read-only operations, backup, export, and activation. Existing data is never touched. The user can always view, print, export, and back up their data. Only new transaction creation is restricted. This is meaningful (a shop cannot operate without creating sales) without being destructive (no data is lost).

**Result:** NO CONTRADICTION.

### Editable shop identity vs immutable business identity

**Test:** Changing shop name/logo must not bypass licensing.

**Resolution:** The `business_id` is a UUID generated by the server, stored in the DPAPI file, and verified against the token's `business_id`. Shop display configuration (name, logo, etc.) is in `app_settings` and shop profile — completely separate from the licensing system. Changing the shop name has zero effect on licensing.

**Result:** NO CONTRADICTION.

### Server activation vs server-independent normal runtime

**Test:** Already valid installations must not depend on server uptime during ordinary operations.

**Resolution:** The activation protocol (§16) is used ONLY for activation, deactivation, transfer, and support reset. Normal runtime uses local DPAPI file + Ed25519 verification with the embedded public key. No server contact occurs during normal operation. The offline runtime contract (§21) is explicit.

**Result:** NO CONTRADICTION.

### Summary

All seven contradiction tests pass. The contract is internally consistent.

## 39. Open Owner Decisions

### Decision A — Grandfathering existing installations

| Aspect | Detail |
|---|---|
| Question | Should existing installations with cosmetic `licenseStatus == 'active'` be granted automatic continued operation (grandfathering), or must all installations activate through the new system? |
| Options | A1: No grandfathering — all must activate. A2: Grace period — existing "active" installations get N days of continued operation. A3: Permanent grandfathering — existing installations are permanently treated as valid. |
| Classification | **DEFERRED — ARCHITECTURE SUPPORTS EITHER POLICY** |
| Impact | Low — the EntitlementState system can treat legacy `licenseStatus == 'active'` as a grandfathering signal without architectural changes |

### Decision B — Restricted mode scope

| Aspect | Detail |
|---|---|
| Question | In restricted/unactivated mode, should ALL read-only operations be allowed, or should some operations also be restricted? |
| Options | B1: All read-only allowed (recommended — data safety). B2: Some read-only restricted. |
| Classification | **DEFERRED — ARCHITECTURE SUPPORTS EITHER POLICY** |
| Impact | Low — the enforcement matrix (§23) can be adjusted without structural changes |

### Decision C — Activation code format

| Aspect | Detail |
|---|---|
| Question | What is the exact format of the activation code? `ITECH-XXXX-XXXX-XXXX` or another format? |
| Options | C1: `ITECH-XXXX-XXXX-XXXX` (16 alphanumeric chars). C2: Another format. |
| Classification | **DEFERRED — ARCHITECTURE SUPPORTS EITHER FORMAT** |
| Impact | Trivial — this is a cosmetic/UX decision, not architectural |

### Decision D — Commercial expiry / trial policy

| Aspect | Detail |
|---|---|
| Question | Should the entitlement token include an expiration date? Should there be a trial period? |
| Options | D1: No expiry (perpetual license). D2: Time-limited license (annual, monthly, etc.). D3: Trial period (N days). D4: Deferred. |
| Classification | **DEFERRED — ARCHITECTURE SUPPORTS EITHER POLICY** |
| Impact | Low — the token format supports `expires_at` as a future field. The enforcement matrix supports `ACTIVE_RESTRICTED` for expired states. No structural changes needed. |

### Decision E — Pricing tiers

| Aspect | Detail |
|---|---|
| Question | Should different commercial tiers (basic, standard, premium) have different feature sets or device limits? |
| Options | E1: Single tier (standard). E2: Multiple tiers with different entitlements. |
| Classification | **DEFERRED — ARCHITECTURE SUPPORTS EITHER POLICY** |
| Impact | Low — the `entitlements.tier` and `entitlements.features` fields in the token support tier differentiation without structural changes |

### Summary

No decision is BLOCKING T3-2. All five decisions are classified as DEFERRED with architecture supporting either option. The technical contract is implementation-ready regardless of which policy choices are made.

## 40. Acceptance Gate

### Why T3-2 is accepted

1. **Complete coverage**: The contract answers all questions a future implementation agent would need: what identifies the business, what identifies the device, what is signed, how activation works, how transfer works, where activation is stored, how offline verification works, where enforcement occurs, what invalid states allow, and how backup/restore behaves.

2. **T3-1 respected**: All four frozen owner decisions are preserved. No frozen policy is reopened or contradicted.

3. **No contradictions**: The contradiction audit (§38) passes all seven tests.

4. **No production changes**: Only a documentation file is created. No Dart code, no schema, no dependencies, no platform changes.

5. **Implementation-ready**: The contract provides enough detail that a future implementation agent can implement licensing mechanically without inventing architecture or product rules.

6. **Non-blocking deferred decisions**: The five open owner decisions (§39) are all classified as DEFERRED with architecture supporting either option. None blocks implementation.

## 41. Explicit Next-Step Boundary

T3-2 is a design freeze. It enables but does NOT authorize the following:

```
T3-3 — Licensing Implementation (if authorized by roadmap)
  → DPAPI local storage implementation
  → Device fingerprint computation
  → Ed25519 verification
  → CBOR token serialization
  → Activation server deployment
  → Client-server integration
  → Enforcement implementation
  → UX implementation
  → Testing
```

**T3-3 is NOT authorized by this document.** Authorization requires:
1. T3-2 accepted by the owner
2. A separate governed authorization for the implementation stage
3. Verification that the roadmap supports T3-3 execution

## 42. What Changed

| File | Change |
|---|---|
| `docs/next-roadmap/I-TECH-T3-2-LICENSING-TECHNICAL-CONTRACT.md` | NEW — complete technical contract |

No other files are modified.

## 43. What Did NOT Change

```
NO production Dart code changed
NO database schema changed
NO migrations created
NO dependencies added to pubspec.yaml
NO Windows native/platform code changed
NO activation server implemented
NO device fingerprint implemented
NO runtime enforcement implemented
NO installer changed
NO existing tests modified
NO existing documentation modified
```

---

```
T3-2 — Licensing Technical Contract / Enforcement Design
Official Governance Report
```

## Outcome

```
B — ACCEPTED WITH EXPLICIT DEFERRED DECISIONS
```

## Roadmap Alignment

```
A — FOLLOW ROADMAP
```

T3-2 is the authorized successor to T3-1 in the frozen roadmap's licensing lineage. It converts the T3-1 policy freeze into an implementation-ready technical contract, consistent with the project's established pattern (policy freeze → technical contract → implementation).

## Governing Evidence

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` |
| Risk/Dependency Map | `docs/next-roadmap/I-TECH-RISK-DEPENDENCY-MAP.md` |
| T3-1 Policy Freeze | `docs/next-roadmap/I-TECH-T3-1-LICENSING-POLICY-DESIGN-FREEZE.md` |
| T3-1 baseline commit | `9bcc191` |

## Context Verification

| Item | Value |
|---|---|
| Project | I-TECH / إدارة محل مؤمن |
| Worktree | C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze |
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Starting HEAD | `9bcc191` |
| Final HEAD | `9bcc191` (documentation-only; no commit yet at time of writing) |

## Current Licensing Audit

The current licensing system is **purely cosmetic**:

- `validateLicenseKey()` accepts any `MUAMAN-*` string with 12+ characters
- No cryptographic validation, no server call, no device binding
- License status is stored in `app_settings` as editable plaintext
- License status is NEVER enforced anywhere in the application
- No HTTP/networking packages exist in `pubspec.yaml`
- No device identity packages exist in `pubspec.yaml`
- The application is 100% offline
- Backup/restore copies the entire database including `app_settings`
- Clean start preserves `app_settings` (including license fields)

## T3-1 Frozen Inputs — Confirmed Unchanged

| Decision | Status |
|---|---|
| Commercial Model: RESELLABLE MULTI-SHOP PRODUCT | PRESERVED |
| Licensing Subject: BUSINESS / STORE | PRESERVED |
| Device Policy: 1 active Windows device + controlled transfer | PRESERVED |
| Connectivity: ONLINE ACTIVATION + OFFLINE NORMAL RUNTIME | PRESERVED |

## Technical Contract Frozen

| Aspect | Frozen Design |
|---|---|
| Business identity | Server-generated UUID v4, immutable, separate from display config |
| Cryptography | Ed25519 asymmetric signing, CBOR canonical serialization |
| Entitlement token | Signed CBOR with license_id, business_id, device_id_hash, entitlements, key_id |
| Device identity | MachineGuid + CPU ID + Board Serial → SHA-256 with app salt |
| Activation | HTTPS API with idempotency, replay protection, server-side one-device invariant |
| Local secure storage | DPAPI-protected file, separate from business database, HMAC integrity |
| Offline verification | Local Ed25519 signature verification with embedded public key |
| Transfer | Deactivate old + activate new, or support-assisted reset |
| Reinstall | Same device: reactivation succeeds. New device: transfer required. |
| State machine | 12 states with deterministic transitions and per-state operation permissions |
| Enforcement | Application-boundary enforcement; never mid-transaction; non-destructive |
| Backup/restore | Entitlement excluded from backup (DPAPI file separate from SQLite) |
| Migration | Legacy cosmetic keys preserved but ignored; new activation required |
| Threat model | Realistic; client-side enforcement; accepted residual risks documented |
| Privacy | Data minimization; only derived hashes sent to server; no business data shared |

## Enforcement Matrix Summary

| State | Read/View | Create Transactions | Backup/Export | Activate/Transfer |
|---|---|---|---|---|
| ACTIVE | ALLOW | ALLOW | ALLOW | ALLOW |
| UNINITIALIZED / ACTIVATION_REQUIRED | ALLOW | BLOCK | ALLOW | ALLOW |
| DEVICE_MISMATCH / TRANSFER_REQUIRED | ALLOW | BLOCK | ALLOW | ALLOW |
| LOCAL_STATE_CORRUPT | ALLOW | BLOCK | ALLOW | ALLOW |
| INVALID_SIGNATURE | ALLOW | BLOCK | ALLOW | ALLOW |
| SERVER_UNAVAILABLE | ALLOW | ALLOW (if previously ACTIVE) | ALLOW | BLOCK (retry) |
| REVOKED | ALLOW | BLOCK | ALLOW | ALLOW (support) |

## What Changed

| File | Change |
|---|---|
| `docs/next-roadmap/I-TECH-T3-2-LICENSING-TECHNICAL-CONTRACT.md` | NEW — complete T3-2 technical contract |

## What Did NOT Change

```
NO production Dart code
NO schema
NO migration
NO dependencies
NO Windows native code
NO activation server
NO fingerprint implementation
NO runtime enforcement
NO installer changes
```

## Validation

Pre-commit validation will be performed after document creation:

```
git diff --check
git status --short
git diff --stat
```

Expected: Only `I-TECH-T3-2-LICENSING-TECHNICAL-CONTRACT.md` modified. No production files.

## Git

| Item | Value |
|---|---|
| Branch | `codex/i-tech-next-roadmap-freeze` |
| Baseline | `9bcc191` |
| Final commit | Pending (documentation commit after validation) |
| Commit count | 1 (T3-2 documentation only) |
| Merge count | 0 |
| Working tree | Documentation change only; pre-existing Flutter noise excluded |
| Push status | NOT pushed (per instructions) |
| Tag status | NOT tagged (per instructions) |

## Risks / Deferred Decisions

### Implementation work

| Risk | Mitigation |
|---|---|
| WMI queries may fail on some Windows configurations | Implementation spike with fallback to MachineGuid-only |
| DPAPI behavior may differ across Windows versions | Test on Windows 10 and 11; use standard CryptProtectData API |
| CBOR package maturity in Dart ecosystem | Evaluate alternatives (JSON with canonicalization) if needed |
| Ed25519 package availability in Dart | Multiple options available (`ed25519`, `cryptography`) |
| Server infrastructure not yet selected | Deferred to implementation stage; contract is server-agnostic |

### Commercial decisions

| Decision | Impact |
|---|---|
| Grandfathering existing installations | Architecture supports either option |
| Commercial expiry/trial policy | Architecture supports adding expiry fields |
| Pricing tiers | Architecture supports tier differentiation |
| Activation code format | Cosmetic; architecture supports any format |
| Restricted mode scope | Architecture supports adjustment |

### Technical debt

| Item | Notes |
|---|---|
| Legacy `licenseKey`/`licenseStatus` in `app_settings` | Preserved for backward compatibility; not used by new system |
| `validateLicenseKey()` dead code | Preserved until UI replacement is implemented |

### Accepted residual security risks

| Risk | Justification |
|---|---|
| Client-side binary patching can bypass enforcement | Standard for desktop licensing; server-side activation provides the real commercial control |
| Offline device retains valid token after server-side revocation | Physical limitation of offline architecture; mitigated by activation_generation and future expiry |
| Device fingerprint spoofing by admin user | Low threat in target deployment (shop owner = legitimate user) |
| Support reset abuse | Mitigated by identity verification and audit logging |

## Acceptance Gate

T3-2 is accepted because:

1. The technical contract is **complete** — it answers all architectural questions needed for implementation
2. The contract is **internally consistent** — the contradiction audit passes all seven tests
3. The contract **respects T3-1** — all four frozen owner decisions are preserved
4. **No production code** was modified — this is documentation only
5. All deferred decisions are **non-blocking** — the architecture supports either policy choice
6. The contract is **detailed enough** that a future implementation agent can implement without inventing architecture

## Single Next Proposed Governed Step

The roadmap's licensing lineage after T3-2 is:

```
T3-1: Licensing Policy Design Freeze → ACCEPTED (9bcc191)
T3-2: Licensing Technical Contract / Enforcement Design → ACCEPTED (this document)
T3-3: Licensing Implementation → NOT YET AUTHORIZED
```

The next logical step is **T3-3 — Licensing Implementation**, which would implement the frozen technical contract. However, T3-3 is NOT authorized by this document or by the current governing evidence. Authorization requires:

1. Owner acceptance of T3-2
2. A separate governed authorization for the implementation stage
3. Verification that the roadmap supports T3-3 execution (currently listed as "EXPLICIT EXCLUSIONS" in the frozen roadmap)

```
NEXT STEP IS NOT AUTHORIZED FOR EXECUTION UNLESS EXPLICITLY APPROVED.
```