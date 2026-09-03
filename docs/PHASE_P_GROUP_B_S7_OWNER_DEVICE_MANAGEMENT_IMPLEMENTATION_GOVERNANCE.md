# PHASE P — GROUP B — S7 OWNER DEVICE MANAGEMENT — IMPLEMENTATION GOVERNANCE

**Document purpose:** Freeze the exact future implementation contract for Group B **S7 Owner Device Management** against the committed server-authoritative device-trust system. This is a **governance-only** artifact. It does NOT implement S7.

---

## A. Session Contract

```text
SESSION =
PHASE_P_GROUP_B_S7_OWNER_DEVICE_MANAGEMENT_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCK

MODE =
SINGLE_SLICE_IMPLEMENTATION_GOVERNANCE_ONLY_FAIL_CLOSED

TARGET_SLICE =
S7_OWNER_DEVICE_MANAGEMENT

IMPLEMENT_S7 =
FALSE

AUTHORIZED_TRACKED_OUTPUT =
EXACTLY_ONE_NEW_GOVERNANCE_ARTIFACT
(this file)

PRODUCTION_MUTATION =
NO

DEVICE_GATE_ACTIVATION =
FORBIDDEN

S8_OR_LATER_STARTED =
NO

GROUP_D_STARTED =
NO
```

**Tag convention note:** The repository follows a date-prefixed migration naming (`202608200000NN_*.sql`). Throughout this document, references like `migration NN` refer to the numeric suffix, matching the committed S1–S6 naming linked in the authority chain.

---

## B. Repository Identity

```text
ROOT =
C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze

BRANCH =
codex/i-tech-next-roadmap-freeze

AUTHORIZED_REMOTE =
github

AUTHORIZED_REMOTE_URL =
https://github.com/sabere342-ai/muaman.worktrees.git

LEGACY_REMOTE =
origin  (SACRED READ-ONLY — never contacted in this session)
```

Under no circumstances during governance or future S7 implementation may `origin` be contacted (no fetch/pull/push/ls-remote/set-url/remove/rename).

---

## C. Entry / Recovery Classification

**CLASSIFICATION = CASE_A_FRESH**

Verified at session start:

```text
LOCAL_HEAD                    = 69218da499ed004f5dc378c6d378add574c592b4
REMOTE_TRACKING_HEAD (@{u})   = 69218da499ed004f5dc378c6d378add574c592b4
DIRECT_GITHUB_REMOTE_HEAD     = 69218da499ed004f5dc378c6d378add574c592b4
MERGE_BASE                    = 69218da499ed004f5dc378c6d378add574c592b4
AHEAD = 0
BEHIND = 0
TRACKED_WORKTREE = CLEAN
INDEX = EMPTY
ACTIVE_GIT_OPERATION = NONE
(MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG / rebase-merge / rebase-apply / sequencer all absent)
```

Pre-existing sacred untracked evidence was present and was left untouched and unstaged:
`GROUP_A_PHASE_P_OD7_*.md`, `GROUP_A_PHASE_Q_*.md`, `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`, `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`, `delivery/I-TECH-Delivery-v1.0.0.zip`, `supabase/.branches/`, `supabase/.temp/`.

---

## D. Exact S6 Remote-Lock Baseline

```text
S6_IMPLEMENTATION =
69218da499ed004f5dc378c6d378add574c592b4

MESSAGE =
feat: implement Group B S6 platform secure device identity

S6_IMPLEMENTATION_PARENT =
b4e95e43863d82916ffe30c45f6e438a2fe0b1cc   (verified via 69218da^)

S6_GOVERNANCE =
b4e95e43863d82916ffe30c45f6e438a2fe0b1cc
PATH  = docs/PHASE_P_GROUP_B_S6_PLATFORM_SECURE_DEVICE_IDENTITY_IMPLEMENTATION_GOVERNANCE.md
BLOB  = 93d58c5ba6123eab57a0d13e24d7ea2fa893ab21  (verified)
```

S6 closure remains SEALED. Known closure baselines (governed, not re-verified here):

```text
pgTAP S6                     = 35/35 PASS
Deno Edge tests (s6-device-pop) = 16/16 PASS
Dart S6 tests                = 36/36 PASS
Cross-language Dart-sign → Deno-verify = PASS
Full Dart regression         = 1626/1626 PASS
DEVICE GATE                  = OFF / DORMANT
PRODUCTION DEPLOYMENT        = NOT PERFORMED
```

The previous S6 DPAPI correction is part of the sealed implementation and is NOT reopened here.

---

## E. Authority Chain

All four authorities were verified as existing immutable commit objects, with the expected blobs at the expected paths, and all are **ancestors** of the session baseline. No newer committed material supersedes or conflicts with them.

**A. Owner Order — Group B Before Group D**
```text
COMMIT        = 221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4
PATH          = docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md
BLOB          = 37518ed12f0402e059e099be8104b21b2d07c64f   (verified)
AUTHORITY     = GROUP_B_BEFORE_GROUP_D
```
Group D remains ORDERED_SECOND_AND_DEFERRED. **S7 MUST NOT start Group D.**

**B. Authority-Binding Correction**
```text
COMMIT        = 8fc4be8ea06fcff5400b79dbebb373c038738ecf
PATH          = docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md
BLOB          = 57e0f9c393ea9ef3484a5312612f7703509747af   (verified)
```

**C. Group B Master Plan**
```text
COMMIT        = 9ecdc38282cdb7ca6f088263f9e152f920b7a823
PATH          = PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
BLOB          = 6bb57e90f3704a9cdee691b19c45c8107b6207af   (verified)
```
Successor sequence (authorized):
```text
S6 Platform secure device identity
    → per-install keypair / Android Keystore / Windows DPAPI / proof-of-possession
    → dependencies: S4 + S5
S7 Owner device management
    → UI: pending / approve / reject / revoke / lost
    → employee ↔ device
    → dependencies: S4 + S6
S8 Tamper / cache / clock enforcement
    → dependency boundary separate from S7
```
Therefore:
```text
CURRENT AUTHORIZED SUCCESSOR = S7 OWNER DEVICE MANAGEMENT
```
Do NOT broaden S7 into S8.

**D. P-OD13 Employee Device Trust Authority**
```text
COMMIT        = 8d27878a69cbb6c6f440c28f4f55f3ed323312d4
PATH          = POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md
BLOB          = e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a   (verified)
```
Central security invariant preserved by S7:
```text
VALID EMPLOYEE EMAIL + PASSWORD ALONE
MUST NOT BE SUFFICIENT TO ACCESS SHOP BUSINESS DATA
FROM A NEW UNTRUSTED DEVICE.
```
Device trust is **server-authoritative**. The Owner UI is a management/control surface. The client must never become the security authority merely because it exposes approve/reject/revoke controls.

---

## F. S4 + S6 Dependency Proof

S7 depends on BOTH S4 and S6. Each required commit was proven an ancestor of HEAD via `git merge-base --is-ancestor <commit> HEAD` (exit 0 = ancestor).

**S4**
```text
S4_GOVERNANCE             = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5  [ancestor] VERIFIED
S4_GOVERNANCE_CORRECTION  = 5309749995244c8bfb423b46d897150b839c1f81  [ancestor] VERIFIED
S4_IMPLEMENTATION         = b8889bf59d65037915fcec618f06fc1c1a49ae40  [ancestor] VERIFIED
```

**S6**
```text
S6_GOVERNANCE             = b4e95e43863d82916ffe30c45f6e438a2fe0b1cc  [ancestor] VERIFIED
S6_IMPLEMENTATION         = 69218da499ed004f5dc378c6d378add574c592b4  [ancestor == HEAD] VERIFIED
S6_IMPLEMENTATION_PARENT  = b4e95e43863d82916ffe30c45f6e438a2fe0b1cc  (69218da^) VERIFIED
```

**S5 note:** S5 (client entitlement integration) is a paid dependency of S6 in the plan, but S7's declared dependencies are S4 + S6. S5 is present at HEAD (`5801cea`); S7 does not widen its dependency set beyond S4 + S6.

---

## G. Current Repository Forensics

All items below are **[EXISTING FACT]** verified from the committed tree at HEAD. Classifiers used throughout: `EXISTING FACT` = committed reality; `FUTURE S7 REQUIREMENT` = governed contract for a later implementation slice; `OUT-OF-SCOPE FUTURE SLICE` = belongs to a later authorized slice.

### G.1 Flutter application surfaces

**Navigation/routing.** No named-route table; navigation is imperative `Navigator.push(MaterialPageRoute(...))`. App home is `AuthGate` (`app/lib/main.dart`). Admin surfaces are reached from `SettingsScreen` (`app/lib/screens/settings_screen.dart`) and `FullAppShell` (`main.dart`).

**Owner/admin/settings screens (existing):**
- `app/lib/screens/admin/user_management_screen.dart` (Permission-gated, `AppPermission.canManageUsers`)
- `app/lib/screens/admin/roles_permissions_screen.dart` (Permission-gated, `canManagePermissions`)
- `app/lib/screens/settings/invite_employee_screen.dart`
- `app/lib/screens/settings/license_status_screen.dart`
- `app/lib/screens/settings/shop_selector_screen.dart` — **dead code** (defined, never navigated)
- `app/lib/screens/settings_screen.dart`

**Device management UI — [EXISTING FACT]: NONE exists.** No device-management screen or widget exists under `app/lib/screens` or `app/lib/widgets`. `getDeviceList` and `deactivateDevice` live only on `CloudLicensingService` (`app/lib/licensing/cloud_licensing_service.dart:290,295`) and are NOT invoked from any screen. The licensing status screen (`settings_screen.dart:642`) reads `CloudLicensingService.instance` only for the license/entitlement card; it does not surface device management.

**S6 integration — [EXISTING FACT]: present but NOT integrated into any running path.** `S6DeviceIdentity` (`app/lib/licensing/s6_device_identity.dart`), `S6ProofOfPossession`/`S6CanonicalEnvelope` (`s6_proof_of_possession.dart`), and `SecureSecretStore`/`WindowsDpapiSecureSecretStore`/`InMemorySecureSecretStore` (`app/lib/platform/secure_secret_store.dart`) are referenced only within their own files and tests. No screen/service/repository consumes them.

**Auth/session context.** `CloudAuthService` (`app/lib/services/cloud_auth_service.dart:89`) is the only direct Supabase Auth caller. Tenant context is carried by `ActiveShopContext` (`app/lib/services/active_shop_context.dart:29`, validated `bind/switchShop`, fail-closed) and `SessionState` (`session_state.dart:9`). Shop resolution via `ShopResolver` (`shop_resolver.dart`). Seller provisioning (`seller_session_provisioning.dart`) cannot create/elevate an Owner (`ownerRejected`).

**Owner detection.** Local `User.role == UserRole.owner` (`session_state.dart:33` `currentRole`) plus cloud `membershipRole == 'owner'` (`CloudSession.isOwner`, `ShopMembership.isOwner`). Permission resolver (`app/lib/services/permission_resolver.dart:67`) grants the Owner all permissions unconditionally and never reduces them.

**Models.** There are NO `shop_member`/`employee`/`member`/`device` Dart model classes. Membership/invitation are lightweight structs: `ShopMembership` (`shop_resolver.dart:7`), `CloudSession` (`app/lib/models/cloud_session.dart:10`), `InvitationInfo` (`app/lib/services/invitation_service.dart:6`), `User` (`app/lib/models/user.dart:3`), `UserRole` (`app/lib/models/user_role.dart`). `app/lib/models/cloud/` holds business DTOs only (sales/products/etc.), no device/member DTOs.

**Invitations.** Creation is server-side via Edge Function `invite-employee` (`app/lib/screens/settings/invite_employee_screen.dart:72`, `functions.invoke('invite-employee', ...)`). Acceptance is client-side via RPC `accept_invitation(p_shop_id, p_role, p_email, p_token)` (`cloud_auth_service.dart:189`). Roles offered: `employee`/`salesOnly` (`invite_employee_screen.dart:193`).

**Employee management UI.** `UserManagementScreen` (`user_management_screen.dart`) uses the LOCAL `UserRepository` (`app/lib/database/user_repository.dart`), not cloud RPCs, for listing/creating/editing users; it owns the invitation entry point and enforces `canManageUsers`.

**Repo/RPC calling pattern.** Repositories take an optional injected `SupabaseClient` (default `Supabase.instance.client`) and call `client.rpc('fn', params: {...})`; the Edge Function uses `functions.invoke`. Cataloged RPC names across the app: `get_user_shops`, `create_shop_with_owner`, `accept_invitation`, `verify_license_entitlement`, `start_trial`, `register_device`, `activate_device`, `deactivate_device`, `get_device_list`, `sync_user_permissions`, `require_shop_permission`, `get_shop_permission_overrides`, `set_shop_permission_override`, `delete_shop_permission_override`, plus inventory/product/customer/expense/sales/returns/invoices/settings/migration RPCs. Edge Function invoked: `invite-employee`.

**Role/permission checks.** `AppPermission` enum (`app/lib/services/permissions.dart:35`), `PermissionResolver` (`permission_resolver.dart:23`) owner-short-circuits to all. `PermissionCatalog.ownerExclusive = {canManageUsers, canManagePermissions}` (`permissions.dart:192`).

**Loading/error/empty/refresh patterns (existing admin/settings).** Consistent `_isLoading` → centered `CircularProgressIndicator`; empty → centered text; `RefreshIndicator` for swipe refresh; `SnackBar` success/error (green/red); retry button on load error; save spinners in buttons; RTL-aware dialogs. These established patterns are the baseline S7 UI should follow.

**Local device identity exposure — [EXISTING FACT].**
- Legacy fingerprint: `WindowsDeviceIdentityProvider` reads `MachineGuid`, CPU `ProcessorId`, `baseboard` `SerialNumber`; `AndroidDeviceIdentityProvider` reads `SSAID`/`androidId` (`app/lib/platform/device_identity_provider.dart`). Raw values "never leave the process; only a salted SHA-256 hash is transmitted" (comment at lines 26–27). None are wired to UI.
- S6 cryptographic identity: `S6DeviceIdentity.publicKeyBase64Url` exposed (public metadata only, no private key). Not in UI.
- `installation_id` is a per-install id from `EntitlementCache._keyInstallationId` (`app/lib/licensing/entitlement_cache.dart:159`) passed to `register_device`/`activate_device` (`p_installation_id`).

**Test directory.** S6 Dart tests: `app/test/licensing/s6_device_identity_test.dart`, `s6_proof_of_possession_test.dart`, `s6_platform_secure_device_identity_test.dart`, `secure_store_abstraction_test.dart`; legacy `device_identity_provider_test.dart`. Widget tests: `app/test/widget/roles_permissions_screen_test.dart`; invitation: `app/test/cloud/invitation_acceptance_test.dart`. No dedicated `invite_employee_screen_test.dart` / `user_management_screen_test.dart`.

### G.2 Supabase surfaces

**devices table** (`migration 04`, `20260820000004_create_devices.sql:9-21`):
```sql
devices (
  id UUID PK, installation_id UUID NOT NULL,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),          -- last user; NOT NULL not enforced
  platform text CHECK (platform IN ('windows','android')),
  device_name text, first_seen_at, last_seen_at,
  status text default 'ACTIVE' CHECK (status IN ('ACTIVE','REVOKED','LOST')),
  created_at ...
)
```
After S1 + S4 the status CHECK becomes (see G.3):
```text
status IN ('ACTIVE','REVOKED','LOST','PENDING_APPROVAL','REJECTED')
```
S1 (migration 31) also adds `public_key`, `approved_by`, `approved_at`, `revoked_by`, `revoked_at`. `idx_devices_installation_shop UNIQUE(installation_id, shop_id)` (migration 23 / re-added S3).

**shop_members** (`migration 01`): `shop_id`, `user_id` (FK auth.users), `role CHECK (owner|employee|salesOnly)`, `status CHECK (INVITED|ACTIVE|SUSPENDED|REVOKED)`, `UNIQUE(shop_id,user_id)`.

**roles / role_permissions_cloud** (`migrations 02/03`): seeded owner/employee/salesOnly; permission_id strings.

**invitations** (`migration 21`): `shop_id`, `email`, `role CHECK (employee|salesOnly)`, `invited_by`, `status CHECK (PENDING|ACCEPTED|EXPIRED|REVOKED)`, `expires_at`. S4 adds `token_hash`, `accepted_by`.

**S4 device-trust machinery** (`migration 34`):
- Five-state lifecycle via CHECK: `ACTIVE / REVOKED / LOST / PENDING_APPROVAL / REJECTED`.
- `device_challenges(id, shop_id, device_id, challenge, challenge_created_at, expires_at, used_at, created_by)` — single-use (used_at), expiring.
- `device_assertions(id, challenge_id UNIQUE, shop_id, device_id, user_id, is_request_bound, verified_at, signature, signature_format)`.
- `s4_enforcement_config` single row, `device_gate_enabled BOOLEAN DEFAULT false` (dormant).
- `s4_device_gate_enabled()` SECURITY DEFINER, granted to `authenticated`.
- `s4_set_device_gate_enforcement(p_enabled)` SECURITY DEFINER, **granted to service_role only**.
- `s4_current_request_device_is_approved(p_shop_id)` SECURITY DEFINER (request-bound GUC `s4.request_device_id`/`s4.asserted_device`; requires ACTIVE; never degrades to scan).
- `s4_require_owner(p_shop_id)` SECURITY DEFINER (raises `S4_OWNER_ONLY`).
- Owner transitions (SECURITY DEFINER, granted `authenticated`): `s4_approve_device(shop_id, device_id, reason)` → `PENDING_APPROVAL → ACTIVE`; `s4_reject_device(...)` → `REJECTED` (refuses ACTIVE); `s4_mark_device_lost(...)` → `LOST` (cascades ACTIVE activations → REVOKED). `s4_audit_device_transition` granted service_role.
- **NO `s4_revoke_device`;** ACTIVE→REVOKED remains the canonical `s3_revoke_device`.
- `s4_list_devices(shop_id)` SECURITY DEFINER, granted `authenticated` — owner-scoped listing returning `device_id, installation_id, platform, device_name, user_id, status, public_key, approved_at, revoked_at, first_seen_at, last_seen_at`.
- `register_device(shop_id, installation_id, platform, device_name)` rewrite: upsert `ON CONFLICT (installation_id, shop_id)`, new rows default `PENDING_APPROVAL`; terminal REVOKED/LOST/REJECTED re-registration rejected.
- Invitation hardening: `invitations.token_hash`/`accepted_by`; `accept_invitation` rewritten to 4-arg token-based, `auth.uid()`-bound, no client-nominated user (migration 34:633 drops the legacy 2-arg overload).
- `s4_create_invitation(shop_id, email, role, token_hash, expires_at)` (Owner-only, hash-only), `s4_token_hash`, `s4_create_challenge(shop_id, device_id, challenge, ttl=300)`, `s4_assert_request` (service_role only).

**S6 secure-identity machinery** (`migration 35`, additive, no new tables, no RLS change, no gate activation):
- `s6_enroll_public_key(p_shop_id, p_device_id, p_public_key)` SECURITY DEFINER, granted `authenticated`: binds Ed25519 public key to a device exactly once, tenant-scoped `FOR UPDATE`, rejects non-canonical / non-32-byte keys, rejects cross-user substitution (`S6_ENROLL_CROSS_USER`), rejects terminal states, idempotent on same key, denies replacement (`S6_ENROLL_KEY_REPLACEMENT_DENIED`).
- `s6_create_challenge(p_shop_id, p_device_id, p_ttl_seconds default 300)` SECURITY DEFINER, granted `authenticated`: server-generated nonce `s6:<uuid>:<uuid>`, TTL 1–3600s, requires ACTIVE device + bound public_key, reuses `device_challenges`.

**Edge Function `s6-device-pop`** (`supabase/functions/s6-device-pop/index.ts`): POST-only; service-role admin client + user JWT; `auth.getUser()`; fetches challenge by id; routing mismatch → 400; cross-user proof → 403; single-use (used_at) → 400; expiry (server clock) → 400; bound public key required → 400; **lifecycle gate `device.status !== "ACTIVE"` → 403**; strict base64url 32-byte key / 64-byte sig; reconstructs canonical envelope from server authority only; WebCrypto Ed25519 verify → fail closed 401 on failure; on success calls `s4_assert_request` (service-role) → 409 on error. Returns only `{success, challenge_id, device_id, shop_id}` (no secrets).

**Edge Function `invite-employee`** (`supabase/functions/invite-employee/index.ts`): POST-only; verifies caller is ACTIVE owner via service-role `shop_members`; creates/resolves auth user (email_confirm, no temp password); generates 32-byte token; stores SHA-256 hash via `s4_create_invitation` (7-day expiry); inserts `shop_members status='INVITED'`; returns plaintext token once.

**RLS / grants / tenant boundaries — [EXISTING FACT]:**
- RLS enabled on shops, shop_members, roles, role_permissions_cloud, devices, licenses, activations.
- `shop_member_isolation` recreated non-recursively with `get_user_shop_ids()` (migration 29 recursion fix); `get_user_shop_ids()` is SECURITY DEFINER, grants to `authenticated, anon, service_role`, PUBLIC revoked.
- `shop_devices_isolation` on devices (`migration 10:105-113`): ACTIVE membership SELECT only.
- S4 adds a dormant approval AND-layer across 14 business-read surfaces (`NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(shop_id)`), default OFF → behavior identical to predecessor.
- `s4_assert_request`, `s4_set_device_gate_enforcement`, `s4_audit_device_transition` are service-role-only.
- SECURITY DEFINER functions consistently use `SET search_path = public`; `auth.uid()` used throughout for caller identity.

### G.3 Critical state semantics (verified)

**The database does NOT use the literal strings PENDING / APPROVED.** The committed authoritative device lifecycle uses:

```text
status IN ('ACTIVE','REVOKED','LOST','PENDING_APPROVAL','REJECTED')
```

Semantic mapping that S7 MUST use:

| Owner-prompt concept | Committed authoritative representation |
|---|---|
| pending | `PENDING_APPROVAL` |
| approved | `ACTIVE` (set by `s4_approve_device`) |
| rejected | `REJECTED` (set by `s4_reject_device`, terminal) |
| revoked | `REVOKED` (set by canonical `s3_revoke_device`, terminal) |
| lost | `LOST` (set by `s4_mark_device_lost`, terminal) |

S7 MUST map UI semantics onto this existing authoritative model. It MUST NOT introduce duplicate/conflicting state machines without evidence.

**Employee↔device relationship — [EXISTING FACT]:** direct device→user is `devices.user_id` (the last user who logged in), nullable; the functional owner/approver link is expressed via `shop_members.role='owner'` (through `shop_id`) plus `devices.approved_by/revoked_by`. Proof-of-possession binds user via `device.user_id` (Edge Function check; S6 cross-user checks). There is NO separate `device_members`/`device_owner` association table.

---

## H. Current S7 Gap Matrix

Verified against the committed tree at HEAD.

| S7 capability | Status | Notes / evidence |
|---|---|---|
| Owner can view current-shop devices | **MISSING** (UI) / `s4_list_devices(shop_id)` exists and is granted to `authenticated` | Server authority exists; no UI surfaces it. `s4_list_devices` is owner-scoped and tenant-isolated. Existing higher-level `getDeviceList` (`CloudLicensingService`) is newer and does not use it; see decision in I. |
| Distinct lifecycle/trust-state presentation | **MISSING** (UI) / state machine EXISTS (server) | Five-state machine present (`PENDING_APPROVAL/ACTIVE/REJECTED/REVOKED/LOST`). No UI rendering maps them. |
| Pending | **PARTIAL** | Server produces `PENDING_APPROVAL` on enroll; no UI list/filter. |
| Approve | **PARTIAL** | `s4_approve_device` exists (Owner-only, granted authenticated); no UI calls it. |
| Reject | **PARTIAL** | `s4_reject_device` exists; no UI calls it. |
| Revoke | **PARTIAL** | Server path is `s3_revoke_device` (canonical); no UI calls it. Higher-level `deactivateDevice` exists but is a legacy activation deactivation, NOT S7 device revoke; see note. |
| Lost | **PARTIAL** | `s4_mark_device_lost` exists; no UI calls it. |
| Employee ↔ device relationship visible/manageable | **MISSING** (UI) / weak DEM exists (`devices.user_id`) | `devices.user_id` is indirect; `s4_list_devices` returns `user_id`. No UI presents it. |
| Owner actions via server-authoritative RPCs | **MISSING** (UI wiring) | RPCs exist; nothing calls `s4_approve_device`/`s4_reject_device`/`s4_mark_device_lost`/`s3_revoke_device` from UI. |
| Cross-shop access impossible | **PRESENT** (server, existing fact) | `shop_id` FK + tenant-scoped functions fail closed. S7 must preserve. |
| Non-owner cannot own device-management authority | **PRESENT** (server, existing fact) / **MISSING** (UI) | `s4_require_owner` + Owner permission gating server side; no UI gate in place (no UI exists). S7 must add `canManageDevices`-style Owner gating. |
| No client-forged shop/member/device relationships | **PRESENT** (server) / S7 responsibility to not undermine | Server derives relationships; S7 UI must not pass arbitrary client-controlled relationships. |
| Bind S7 device identity to S6 secure per-install identity | **PARTIAL** | `s6_enroll_public_key` / `s6_create_challenge` / `s6-device-pop` exist; NOT integrated into any client flow or S7 UI. S7 must consume S6 semantics. |
| Revocation/lost/rejection fail closed, no silent re-approval | **PRESENT** (server) / **MISSING** (client cache discipline) | Server terminal states locked; S7 client must re-read authority after mutation. |
| Clear loading/error/empty/refresh behavior | **MISSING** (S7 UI) | Establish using the existing admin/settings screen pattern. |
| Re-read server authority after mutation | **MISSING** (S7 UI) | Governed as a core S7 behavior. |
| Windows + Android cross-platform | **PRESENT** (platform layer) | `SecureSecretStore` DPAPI/Keystore/InMemory exists. S7 must not break it. |
| No secrets/raw identifiers in Owner UI | **MISSING** (S7 UI must enforce) | Governed negative gates (S section). Public metadata only. |

**Out-of-scope items detected during forensics (recorded, NOT to be repaired by S7):**
- `CloudLicensingService.getDeviceList` / `deactivateDevice` (`app/lib/licensing/cloud_licensing_service.dart:290,295`) appear to target the legacy activation/licensing surface (`get_device_list`, `deactivate_device` RPCs, `activationId`). These are **NOT** the S7 device-management contract. S7 must either use the S4/S6 server-authoritative functions directly or, if it maps onto them, explicitly reconcile — it must NOT silently treat legacy activation deactivation as device revocation.
- `ShopSelectorScreen` is dead code (`app/lib/screens/settings/shop_selector_screen.dart`) — not an S7 concern.

---

## I. Exact Future S7 Implementation Scope

S7 owns the **Owner device-management experience and required integration** for the committed server-authoritative trust system. Freeze the following requirements. `EXISTING FACT` = committed reality; `FUTURE S7 REQUIREMENT` = governed contract.

1. **FUTURE S7 REQUIREMENT — Owner can view devices of the current shop.**
   Consume an owner-scoped, tenant-isolated server surface. The committed surface is `s4_list_devices(shop_id)` (SECURITY DEFINER, granted `authenticated`, tenant-isolated, returns owner-relevant device fields). S7 must bind results to `ActiveShopContext.shopId` and must never accept a client-forged `shop_id`.

2. **FUTURE S7 REQUIREMENT — Distinct lifecycle/trust-state presentation.**
   S7 MUST render the five committed states using the authoritative model (Section G.3):
   `PENDING_APPROVAL` (pending), `ACTIVE` (approved/trusted), `REJECTED`, `REVOKED`, `LOST`. Presentational labels MUST map onto these; S7 MUST NOT invent new states.

3. **FUTURE S7 REQUIREMENT — Owner actions cover the authoritative state model.**
   ```text
   pending   → view devices in PENDING_APPROVAL
   approve   → s4_approve_device (PENDING_APPROVAL → ACTIVE)
   reject    → s4_reject_device   (→ REJECTED, terminal)
   revoke    → canonical revocation path (s3_revoke_device, → REVOKED, terminal)
   lost      → s4_mark_device_lost (→ LOST, terminal)
   ```
   All actions MUST go through the server-authoritative SECURITY DEFINER functions. UI state alone MUST NOT grant device trust.

4. **FUTURE S7 REQUIREMENT — Employee ↔ device relationship visible/manageable to the extent required by authority.**
   `s4_list_devices` returns `user_id`; `devices.user_id` is the committed indirect link. S7 may present the associated member if derivable from committed authority, but MUST NOT introduce a parallel association mechanism or go beyond what existing schema/RLS supports.

5. **FUTURE S7 REQUIREMENT — Actions via server-authoritative APIs/RPCs only.**
   Call the committed owner-gated RPCs. The UI must not fabricate trust locally.

6. **FUTURE S7 REQUIREMENT — Cross-shop access impossible.**
   S7 must never allow displaying or mutating a device of another shop. Rely on `ActiveShopContext` binding + server RLS/functions.

7. **FUTURE S7 REQUIREMENT — Non-owner clients must not obtain Owner device-management authority.**
   Server: `s4_require_owner` + service/owner grants. Client: gate device-management UI behind Owner role (short-circuit) and a dedicated permission consistent with the permission resolver model.

8. **FUTURE S7 REQUIREMENT — No client-forged relationships.**
   The signed-in Owner must not be able to forge `shop_id`/member/device relationships through client-controlled parameters. All relational identity must derive from server authority / current session.

9. **FUTURE S7 REQUIREMENT — Bind to S6 secure per-install identity.**
   S7 consumes S6 identity/PoP semantics (`s6_enroll_public_key`, `s6_create_challenge`, `s6-device-pop` envelope). S7 MUST NOT redesign, replace, weaken, or create a parallel device-identity mechanism. Displayed device identity binds to the S6 public-key model (`public_key` column) not raw hardware IDs.

10. **FUTURE S7 REQUIREMENT — Revocation/lost/rejection fail closed.**
    No silent re-approval through client caching or UI state. After a terminal state, the client must not re-present the device as trusted.

11. **FUTURE S7 REQUIREMENT — Clear loading/error/empty/refresh behavior.**
    Follow the established admin/settings pattern: loading spinner, empty state, error + retry, `RefreshIndicator`, `SnackBar` success/error. RTL-aware.

12. **FUTURE S7 REQUIREMENT — Re-read server authority after mutation.**
    Security-sensitive state must be re-fetched from the server after approve/reject/revoke/lost, not trusted from optimistic local mutation alone, unless the existing architecture provides a provably safe equivalent.

13. **FUTURE S7 REQUIREMENT — Cross-platform within existing architecture.**
    Work on Windows + Android sharing the committed `SecureSecretStore`/S6 layer. S7 must not break DPAPI/Keystore/InMemory selection.

14. **FUTURE S7 REQUIREMENT — No raw secrets/identifiers in Owner UI.**
    Never display, log, export, transmit as diagnostics, or store: MachineGuid, CPU ID, baseboard serial, SSAID/androidId, private keys, or the S6 seed. Only public identity metadata (e.g. `public_key` display identity, device name, platform) necessary for Owner management may be shown.

15. **FUTURE S7 REQUIREMENT — Owner device management ONLY.**
    This slice does NOT redesign unrelated settings/admin screens.

---

## J. Exact Future Authorized File Surface

Based on evidence, the smallest future S7 surface is governed as follows. This is a **freeze of permitted categories**, NOT authorization to create files during this governance session.

**Flutter (required):**
```text
app/lib/screens/settings/device_management_screen.dart   (new — Owner device-management UI)
app/lib/screens/settings_screen.dart                    (modify — add permission-gated Owner entry tile)
app/lib/rbac/ or app/lib/services/permissions.dart       (modify — add a dedicated device-management
                                                          permission id via PermissionCatalog, consistent
                                                          with canManageUsers/canManagePermissions model)
app/lib/services/ (device management service/repository) (new or modify — owner device RPC wrapper,
                                                          following the CloudLicensingRepository pattern of
                                                          injected SupabaseClient + client.rpc)
app/lib/models/cloud/ or app/lib/services/ (device DTO)   (new — typed device model/state mapping the
                                                          s4_list_devices fields: device_id, installation_id,
                                                          platform, device_name, user_id, status, public_key,
                                                          approved_at, revoked_at, first_seen_at, last_seen_at)
app/test/ (device management + invitation + S6 integration tests)  (new)
```

**Explicitly classified as NOT part of S7's required surface (leave in place):**
```text
app/lib/licensing/s6_device_identity.dart           — S6 sealed; consumed, not modified by S7 unless a
app/lib/licensing/s6_proof_of_possession.dart         minimal integration point is provably required.
app/lib/platform/secure_secret_store.dart             S7 must NOT redesign these.
app/lib/screens/admin/user_management_screen.dart    — employee management, distinct from device mgmt.
app/lib/services/invitation_service.dart             — invitation flow, distinct from device mgmt.
```

**Server / Supabase (see Section K for the delta decision):**

If `K` is NONE, no Supabase migration, function, Edge Function, or pgTAP change is authorized for S7.

Any future server-side addition must follow the committed SECURITY DEFINER `SET search_path=public`, `auth.uid()`, owner-role, and tenant-isolation discipline.

---

## K. Server Delta Decision

**S7_SERVER_SCHEMA_RPC_DELTA = NONE** for the core S7 surface, and **S7_SERVER_SCHEMA_DELTA = NONE.**

Verified reasoning:
- The Owner device-management lifecycle is fully representable with committed authority:
  - List: `s4_list_devices` (exists, granted `authenticated`, owner-scoped, tenant-isolated).
  - Approve/reject/lost: `s4_approve_device`, `s4_reject_device`, `s4_mark_device_lost` (exist, granted `authenticated`).
  - Revoke: canonical `s3_revoke_device` (exists).
  - Employer↔device link: `devices.user_id` (exists).
  - Secure identity: `s6_enroll_public_key`, `s6_create_challenge`, `s6-device-pop` + `public_key` column (exist).
- The existing committed authority is **sufficient** for S7. No new migration (and therefore no `00036`) is justified.

**NO new migration number `00036` is authorized by this governance.** Do not invent one merely for symmetry.

---

## L. Owner UI State/Action Contract

```text
UI displayed lifecycle states (mandatory mapping, server-authoritative):
    PENDING_APPROVAL  → "pending"
    ACTIVE            → "approved / trusted"
    REJECTED          → "rejected" (terminal)
    REVOKED           → "revoked" (terminal)
    LOST              → "lost" (terminal)

Owner actions:
    approve  → s4_approve_device
    reject   → s4_reject_device
    revoke   → canonical revocation (s3_revoke_device path)
    lost     → s4_mark_device_lost

Per-action behavior:
    - Guard by Owner role + device-management permission.
    - Call server RPC; await authoritative result.
    - On success: re-read device list from server authority (Section I.12).
    - On failure: show visible error (SnackBar), keep prior authoritative state; never show false success.
    - Idempotency: repeated identical success actions must have defined behavior (server idempotent where supported, e.g. approving an already-ACTIVE device is idempotent). On non-idempotent terminal actions, server must reject with a clear error surface.
    - Empty state: safe empty list handling when no devices.
    - Loading: initial load and post-mutation re-read show loading; error + retry on failure.
```

---

## M. Employee ↔ Device Contract

Investigated schema first. **FUTURE S7 REQUIREMENT** — S7's representation and enforcement must not allow:

```text
- cross-shop employee-device assignment
- assignment to a non-member
- assignment through a forged client shop_id
- non-owner approval
- non-owner revoke/lost/reject controls
- device trust based only on email/password
- device trust based only on local cache
- device trust based only on UI state
- silent trust restoration after revocation/lost/rejection
- private-key transfer between employees/devices
- S6 public-key binding overwritten by arbitrary client data (S6_ENROLL_KEY_REPLACEMENT_DENIED must hold)
```

**Determined from actual committed authority (EXISTING FACT):**
- One device ↔ one shop: `devices.shop_id NOT NULL` FK, `UNIQUE(installation_id, shop_id)`. A device is scoped to exactly one shop.
- Device → user: `devices.user_id` (nullable, last user). A member may have multiple devices. One device is associated with the last user; the model does NOT currently bind multiple members to one device.
- Device ownership is **inferred/indirect** at the user level, while shop scope is direct. The Owner/approver link is via `shop_members.role='owner'` through `shop_id` + `devices.approved_by/revoked_by`.
- Owner devices use the same lifecycle (the Owner's own devices enroll via `register_device` → `PENDING_APPROVAL` and are approved by an Owner, subject to not being able to approve a REVOKED/LOST/REJECTED device).
- The employee relationship is **derived** from `devices.user_id` joined to `shop_members` where USB-carried; S7 must present only what committed authority yields and must not invent a `device_members` table.

---

## N. Authorization / Tenant-Isolation Contract

```text
- All S7 device RPCs enforced owner-only server-side (s4_require_owner / owner grants).
- All S7 device reads/mutations scoped by ActiveShopContext.shopId bound to the signed-in member's ACTIVE
  membership; cross-shop access impossible via server RLS + tenant-scoped functions.
- Non-owner clients must not reach Owner device-management controls (client permission gate + server
  enforcement).
- Client must never pass forged shop_id/member_id/device_id relationships.
- RLS: S7 relies on committed policies (shop_devices_isolation, shop_member_isolation, dormant approval
  layer). S7 must not weaken or bypass them.
- SECURITY DEFINER discipline: SET search_path = public; identity from auth.uid() where applicable.
```

---

## O. Secure Identity / PoP Integration Contract

```text
- S7 consumes S6 per-install Ed25519 identity and PoP envelope (s6_enroll_public_key, s6_create_challenge,
  s6-device-pop) where the S7 device-management flow requires identity binding or proof.
- S7 MUST NOT redesign, replace, weaken, or create a parallel device-identity mechanism.
- S7 displayed device identity binds to the S6 `public_key` model; not raw hardware IDs (MachineGuid/SSAID/
  CPU/baseboard).
- PoP/server verification semantics must not be bypassed where required by the flow.
- Private keys and the S6 seed never reach server/UI/logs/tests/diagnostics.
- Enrollment is exactly-once per device; replacement denied server-side must be surfaced, not worked around.
```

---

## P. Failure / Offline / Refresh Semantics

S7 owns Owner management controls. It does NOT own the full S8 tamper/cache/clock convergence. Therefore:

```text
OUT-OF-SCOPE FUTURE SLICE (S8): offline grace policy, monotonic clock enforcement, cache cryptographic
integrity, clock rollback handling, stale entitlement policy, revalidation cadence.
```

FUTURE S7 REQUIREMENT scope:
```text
- revoke/lost/reject must be server-authoritative.
- failed mutation must not remain shown as authoritative success.
- offline Owner mutation must not fabricate approval.
- cached device lists must not authorize business-data access.
- post-mutation state must be re-read from server authority (no false authority from optimistic local
  mutation alone, unless provably safe equivalent exists in the architecture).
```

---

## Q. Future S7 Test Matrix

Govern the future implementation to include tests proving at least the applicable cases below, mapped to the actual architecture:

```text
Owner can list own-shop devices.
Owner cannot list another shop's devices.
Employee/non-owner cannot use Owner device-management controls.
Pending (PENDING_APPROVAL) device cannot become approved through client-only mutation.
Approval goes through authoritative server transition (s4_approve_device).
Reject works and cannot be bypassed by stale UI state.
Revoke works (canonical path) and remains revoked after refresh.
Lost works and remains authoritative after refresh.
Cross-shop device id cannot be mutated.
Cross-shop member id cannot be paired with device.
Invalid/non-member employee assignment fails closed.
Unknown device fails closed.
Malformed identifiers fail closed.
S6 public-key/device-identity binding is not overwritten by arbitrary client data
  (S6_ENROLL_KEY_REPLACEMENT_DENIED / S6_ENROLL_CROSS_USER hold).
Private key never reaches server/UI/logs.
PoP/server verification semantics not bypassed where required.
Repeated/idempotent Owner actions have defined behavior.
Concurrent conflicting transitions produce deterministic server-authoritative behavior where the
  underlying API permits concurrency.
Mutation failure produces visible failure, not false success.
Refresh reconciles UI against server authority.
Empty device list is handled safely.
Revoked/lost/rejected device is never visually represented as trusted after authoritative refresh.
Owner action does not activate the global production device gate.
No tenant-isolation regression.
No licensing regression.
No S6 identity regression.
```

If actual committed authority provides stronger/more specific CASE 1–20 requirements, map S7-relevant cases explicitly instead of replacing them with weaker tests.

---

## R. Required Regression Gates

The future S7 implementation must preserve the already-closed core suites without modifications, keep the floor (do not hard-code an equality total because S7 legitimately adds tests):

```text
FULL_DART_PASS_COUNT >= 1626      (and ZERO failures)
S1 pgTAP = 46/46
S2 pgTAP = 88/88
S3 pgTAP = 25/25
S4 pgTAP = 50/50
S6 pgTAP = 35/35
S6 Deno/WebCrypto = 16/16
S6 Dart = 36/36
plus the newly governed S7 tests.
```

**Pre-existing test-failure note (recorded, OUT-OF-SCOPE):** Two unrelated Supabase tests carry pre-existing SQL defects confirmed in the committed tree and are NOT S7 regressions and must NOT be repaired by S7:
- `supabase/tests/cloud_stock_adjustments.test.sql` — `pg_get_constraintdef(oid)` with no FROM (lines 39,43).
- `supabase/tests/rls_shop_members_recursion.test.sql` — `information_schema.policies` does not exist (line 19).

If S7 were to touch either exact defect, STOP and report the authority collision rather than opportunistically repairing it. Governance evidence does not show S7 touching either.

---

## S. Secret / Privacy Negative Gates

Future implementation must prove:
```text
NO private Ed25519 key in source
NO private key in database
NO private key in logs
NO private key in UI
NO private key in test snapshots
NO service-role key embedded in app
NO Supabase secret embedded in app
NO production token in diff
NO raw MachineGuid/CPU/baseboard identifiers exposed
NO raw SSAID exposed through Owner UI
NO security-sensitive diagnostic dump
```
Only public identity metadata necessary for Owner device management (device name, platform, lifecycle status, and the S6 public-key identity) may be displayed.

---

## T. Device-Gate Negative Gate

```text
DEVICE_GATE_ENABLED = FALSE  (must remain)
```

S7 MUST NOT execute or introduce execution of `s4_set_device_gate_enforcement(true)`, nor make any equivalent production mutation by SQL, RPC, config, Edge Function, test helper, or direct table update. It must not change the production default to enabled, and must not perform production deployment. If future S7 tests require enforcement behavior, governance requires **isolated/local test setup only** with restoration and fail-closed rules. Actual production activation belongs to its separately authorized future slice/deployment sequence.

---

## U. Future Implementation Diff/File Gates

```text
- S7 implementation must touch ONLY the file surface frozen in Section J.
- Must NOT create a parallel device-trust/identity mechanism.
- Must NOT add migration 00036 (Section K = NONE).
- Must NOT modify S6 sealed sources beyond provably minimal integration, and never to weaken identity/PoP.
- Must NOT modify the S4/S6/S3 SECURITY DEFINER functions that already implement the lifecycle.
- Must NOT repair the two pre-existing unrelated SQL test defects (Section R).
- Must NOT activate the device gate (Section T).
- Must NOT expose secrets/raw identifiers (Section S).
```

---

## V. Future Commit / Push / Remote-Lock Contract

```text
- Implement on branch codex/i-tech-next-roadmap-freeze only.
- Commit target remote: github only. NEVER origin.
- Normal commits only; no force push / force-with-lease / history rewrite / tag movement / branch deletion.
- One slice at a time; S7 implementation is a LATER slice requiring a new explicit Owner instruction that
  this governance session does NOT grant.
- After implementation, a normal fast-forward push to github and remote-lock proof mirroring this
  governance session's contract.
```

---

## W. Explicit Non-Goals

S7 governance may reference later slices solely to draw boundaries. S7 MUST NOT implement or govern beyond S7:

```text
- S7 implementation itself (a separate later slice)
- S8 tamper/cache/clock convergence
- S9 legacy Ed25519 retirement
- S10 full CASE 1–20 convergence
- S11 production deployment
- S12 Group B closeout
- Group D planning or implementation
- billing/payment provider integration
- Migration 30 rework
- S1–S6 redesign
- Android release/AAB publication
- Play Console work
- device-gate production activation
- unrelated SQL test repair
- UX redesign of unrelated settings/admin screens
```

---

## X. STOP Boundary

This session is **governance-only**. After completing this artifact, the session commits it once and stops. The next session requires a new explicit Owner instruction to implement S7.

```text
RESULT = PASS
SUCCESS_TOKEN =
PASS_PHASE_P_GROUP_B_S7_OWNER_DEVICE_MANAGEMENT_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED

S7_IMPLEMENTATION_STARTED = NO
PRODUCTION_MUTATION = NO
DEVICE_GATE_ACTIVATED = NO
S8_STARTED = NO
GROUP_D_STARTED = NO
LEGACY_ORIGIN_CONTACTED = NO
```
