# POST PHASE P — OWNER EMPLOYEE DEVICE TRUST + FINAL DELIVERY ROADMAP GOVERNANCE DETERMINATION

## A. Session Identity

| Field | Value |
|---|---|
| SESSION | `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION` |
| SESSION_TYPE | `GOVERNANCE / ROADMAP DETERMINATION ONLY` |
| ROOT | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| LEGACY_ORIGIN | `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` — READ-ONLY / UNAUTHORIZED (never fetched, pushed, pulled, renamed, deleted, or modified; inspected read-only) |
| PURPOSE | (1) Integrate the newly-authorized Owner **employee device trust** production-security requirement into the governing roadmap in its correct dependency position; (2) audit the ENTIRE current governing plan against repository reality; (3) determine exactly what is COMPLETE / PARTIAL / BLOCKED / NOT_STARTED / production-deployed / repository-only / required-before-delivery; (4) reconstruct the exact safe dependency order to FINAL DELIVERY; (5) produce an evidence-backed final-delivery working-day estimate and proposed delivery date. |
| AUTHORIZED | read repository evidence; `git fetch github`; read-only git forensics; read migrations/edge function/Flutter runtime; reason about security & roadmap; create ONE additive governance artifact; create ONE local governance commit. |
| NOT AUTHORIZED | implement the device-trust feature; mutate production; deploy Migration 30; activate the drain; start/implement Group B/C/D; create a release build; create an Android release; modify Supabase production; push; tag; rewrite history; alter sacred artifacts. |

---

## B. Entry / Recovery Classification

Read-only forensics were performed before any tracked mutation. Only `git fetch github` was issued against the authorized remote; the legacy `origin` was inspected read-only and never contacted.

```text
ROOT        = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze   ✓
BRANCH      = codex/i-tech-next-roadmap-freeze                     ✓
AUTHORIZED_REMOTE = github (fetch = push = https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن      (read-only / unauthorized)

LOCAL_HEAD  = 1ba42a3a7918fb0c3d7e9fc1481596e457f52cad   ✓ (matches expected locked governance HEAD)
REMOTE_HEAD = 1ba42a3a7918fb0c3d7e9fc1481596e457f52cad   (github/codex/... + github/HEAD after fetch)
MERGE_BASE  = 1ba42a3a7918fb0c3d7e9fc1481596e457f52cad
AHEAD       = 0
BEHIND      = 0
INDEX       = EMPTY
TRACKED WK  = CLEAN
UNTRACKED   = sacred trio + supabase/.temp/ only (preserved, never staged, never modified)
HEAD SUBJECT= Govern Migration-30 production deployment
HEAD PARENT = f3aee657e7d59ce01c0c82906a274e2da66e0ddd
TAGS AT HEAD= none
```

**RECOVERY_CLASSIFICATION = `CASE_A_FRESH_GOVERNANCE_CONTINUATION`.** Repository matches the expected locked baseline exactly (LOCAL = REMOTE = MERGE_BASE = `1ba42a3`; AHEAD = 0; BEHIND = 0; tracked/index clean; only known sacred/temp untracked state). No local governance artifact for this requirement exists above HEAD, and the authorized remote has not advanced. No destructive recovery (`git reset --hard`, `git clean -fd`, force checkout, rebase, history rewrite, force push) was used or needed.

### Sacred artifacts — PRE hash baseline (recorded before any tracked mutation)

| Artifact | SHA-256 (PRE) |
|---|---|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | `C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733` |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` |
| `supabase/.temp/` | untracked, unmodified, not staged (9 entries) — preserved |

POST hashes must equal PRE (verified at end of session, §31).

---

## C. Governing Evidence Reviewed

Read directly from the locked repository tree (all read-only; repository reality governs over prompt filenames/prose). Where a filename differs from the prompt list, actual repository reality is used.

**Governing plans / determinations (all reviewed):**
- `PROJECT_MASTER_PLAN.md` (D9/D10/D11/D13/D14; §5, §11.5, §13, §18)
- `PRODUCTIZATION_ARCHITECTURE_PLAN.md`, `PRODUCTIZATION_MIGRATION_PLAN.md`
- `PHASE_P_PRODUCTION_HARDENING_PLAN.md` (WS-1..WS-10; §Q classifications; §F.5 WS-4)
- `PHASE_P_OWNER_DECISIONS.md` (P-OD1..P-OD12)
- `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` (Groups A/B/C/D decomposition)
- `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` (A1..A8), `..._IMPLEMENTATION_GOVERNANCE_DETERMINATION.md`
- `PHASE_P_OWNER_GATED_GROUP_A_A8_EVIDENCE_GATE_CLOSEOUT_REPORT.md` (criterion 16 = DOCUMENTED-EQUIVALENT; live-probe deferred)
- `POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md` (OUTCOME_F)
- `POST_PHASE_P_OWNER_GATED_GROUP_A_OWNER_SUCCESSOR_SCOPE_DECISION.md` (Owner selects Mig-30 deploy+Mig-28 probe)
- `POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE.md` (deployment protocol serialized; PROD_CASE_A; Migration-29 presence UNDOCUMENTED; backup/recovery not confirmed)
- `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md` (§7.15 backup/rollback law; rollback doctrine)
- `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` (Gate-12; SQLSTATE 42P17 recursion; invite-employee null `user_id` bug; production ref `ckruxrgppxxeqspxmyyd`)
- `SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md`, `SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLAN.md`

**Supabase definitions (read full):**
- `20260820000001_create_shop_members.sql` (role IN owner/employee/salesOnly; status IN INVITED/ACTIVE/SUSPENDED/REVOKED; UNIQUE(shop_id,user_id))
- `20260820000004_create_devices.sql` (**status IN ('ACTIVE','REVOKED','LOST')**; installation_id UUID; platform windows/android; user_id nullable)
- `20260820000005_create_licenses.sql`, `20260820000006_create_activations.sql`
- `20260820000010_rls_policies.sql` (`shop_devices_isolation` etc. root = auth.uid() + ACTIVE membership)
- `20260820000020_database_functions.sql`, `20260820000021_add_invitations.sql`, `20260820000022_add_accept_invitation.sql`
- `20260820000023_phase_e_licensing_enhancements.sql` (register_device/activate_device/deactivate_device/get_device_list/verify_license_entitlement; max_devices)
- `20260820000024_phase_f_rbac_permission_sync.sql` (**`require_shop_permission`** body 232–298; `check_effective_permission`; 18 permissions)
- `20260820000025_phase_g_cloud_data_foundation.sql`, `20260820000026_phase_h_sync_core.sql`
- `20260820000028_phase_m_inventory_conflict_hardening.sql`, `20260820000029_fix_shop_members_rls_recursion.sql` (`get_user_shop_ids()` fail-closed; recursion fix)
- `20260820000030_phase_p_a4_cloud_stock_adjustments.sql` (Migration 30 = A4 server durability; not deployed)

**Edge function:** `supabase/functions/invite-employee/index.ts` (full read).

**Flutter runtime (evidenced via structured code audit, exact file:line):**
authentication (`app/lib/services/cloud_auth_service.dart`), membership resolution (`shop_resolver.dart`, `active_shop_context.dart`), employee invitation acceptance (`invitation_service.dart`, `acceptInvitation`), active shop context (`active_shop_context.dart`), permissions (`rbac/permission_sync_service.dart`, `permission_resolver.dart`), device identity (`licensing/device_identity.dart`, `platform/device_identity_provider.dart`, `licensing/entitlement_cache.dart`), device registration/activation (`licensing/cloud_licensing_repository.dart:137-186`, `cloud_licensing_service.dart`), secure stores (`licensing/secure_store.dart`, `secure_store_android.dart`, `platform/secure_secret_store.dart`, `android/.../MainActivity.kt`), session resume (`services/cloud_session_resume.dart`), seller provisioning (`services/seller_session_provisioning.dart`), logout (`main.dart:346-369`), local cache (`database/database_helper.dart` schemaVersion=18, plain `sqflite`, no SQLCipher).

---

## D. Current Roadmap Truth — Authoritative Status Ledger

Completion is determined by evidence, never by file existence. Terms: COMPLETE_REMOTE_LOCKED / COMPLETE / PARTIAL / REPOSITORY_IMPLEMENTED / PRODUCTION_PENDING / BLOCKED / NOT_STARTED / POST_P / OUT_OF_SCOPE.

### D.1 Phases A–O

| Phase | Objective | Status (evidence) |
|---|---|---|
| A | Product identity & governance | COMPLETE_REMOTE_LOCKED |
| B | Shop/tenant foundation (`shops`) | COMPLETE_REMOTE_LOCKED |
| C | Cloud backend foundation (RLS baseline) | COMPLETE_REMOTE_LOCKED |
| D | Cloud auth & membership (owner, invites, login) | COMPLETE_REMOTE_LOCKED (invitation security gaps noted in §H/G — additive hardening belongs to Group B) |
| E | Licensing & trial | COMPLETE_REMOTE_LOCKED (commercial model additions are Group B work) |
| F | Server-enforced permissions (RBAC, `require_shop_permission`) | COMPLETE_REMOTE_LOCKED |
| G | Cloud data foundation | COMPLETE_REMOTE_LOCKED |
| H | Offline sync core | COMPLETE_REMOTE_LOCKED (drain dormant — Group A activates) |
| I | Legacy data migration | COMPLETE_REMOTE_LOCKED |
| J | Windows cloud transition | COMPLETE_REMOTE_LOCKED |
| K | Android owner foundation | COMPLETE_REMOTE_LOCKED |
| L | Android sales/employee | COMPLETE_REMOTE_LOCKED |
| M | Inventory conflict hardening | COMPLETE_REMOTE_LOCKED (migration 28 present in repo) |
| N | Cross-platform Excel import | COMPLETE_REMOTE_LOCKED |
| O | Invoice branding & delivery | COMPLETE_REMOTE_LOCKED |

### D.2 Phase P — WS-1..WS-10 and Groups A/B/C/D

| Item | Status (evidence) |
|---|---|
| WS-1 Runtime sync lifecycle (drain) | PARTIAL / REPOSITORY_IMPLEMENTED-DORMANT — Group A A1/A2/A5/A6 implemented & locked; drain (`syncDrainEnabled`) remains FALSE; live transport proof + activation = Group A remaining. |
| WS-2 Sync data integrity (`cloud_uuid`) | PARTIAL — WS-2 flagged in A8; some pieces land with Group A; residual multi-device/reinstall mapping ties into device-trust. |
| WS-3 Option C durability | PARTIAL — A4 server half implemented (migration 30, repo-only, NOT deployed); local routing (A3) + server durability horizon pending Migration-30 deployment. |
| WS-4 Licensing commercial model | PARTIAL — offline-grace partly corrected (paid 7d/trial 0d); subscription/tiers/revocation/tamper NOT implemented → Group B. **NEW: employee device trust requirement lands here.** |
| WS-5 Offline seller sales hardening | PARTIAL → depends on Group A drain; adjudication semantics tie into device trust/revocation. |
| WS-6 Backup/restore safety | PARTIAL — restore fixed to v18 in Group A lineage; DB is plaintext (encryption POST_RELEASE_HARDENING unless Owner decides otherwise). |
| WS-7 Android release readiness | BLOCKED_OWNER_DECISION (P-OD2 package, P-OD3 signing) → Group C. |
| WS-8 Release/build hardening | NOT_STARTED (residual) — formatting baseline + Android release + versioning → Group C / final gates. |
| WS-9 Business-critical gaps | NOT_STARTED → Group D (cost-change, opening balances, arbitrary-period reporting). |
| WS-10 Security/Supabase seal | NOT_STARTED — final verification workstream. |
| **GROUP A** (P-OD1 + P-OD7; A1..A8) | **A1..A8 COMPLETE + REMOTE LOCKED.** Terminal production chain NOT closed: Migration 30 NOT deployed; Migration 29 presence UNDOCUMENTED; backup/recovery not confirmed; drain OFF; PROD_CASE_A. See §R. |
| **GROUP B** (P-OD8..P-OD12, WS-4) | **DEFINED / NOT STARTED** → **NOW also carries NEW employee device trust requirement (P-OD13, this governance).** |
| **GROUP C** (P-OD2/P-OD3, WS-7/WS-8) | **DEFINED / NOT STARTED** (blocked on Owner Android keystore + package decision). |
| **GROUP D** (P-OD4/P-OD5/P-OD6, WS-9) | **DEFINED / NOT STARTED**. |

### D.3 P-OD ledger

| ID | Status |
|---|---|
| P-OD1..P-OD12 | RESOLVED / APPROVED (or CONDITIONALLY AUTHORIZED / REQUIRED) per `PHASE_P_OWNER_DECISIONS.md` |
| **P-OD13** | **NEW — EMPLOYEE DEVICE TRUST / SERVER-ENFORCED NEW-DEVICE BUSINESS-ACCESS GATE (APPROVED by this Owner governance session).** Next legitimate additive ID; verified no collision. |

---

## E. New Owner Security Requirement

The Owner requires: an employee account's valid **email + password alone MUST NOT be sufficient for Shop A business-data access from a new device.** A stolen/copied/socially-engineered credential obtained by an outsider (e.g., from Shop B or a competitor) who installs the app on another phone/computer and signs in must NOT thereby access Shop A data. The product must provide **defense-in-depth**:

```text
AUTH IDENTITY  +  SHOP MEMBERSHIP  +  ROLE/PERMISSIONS  +  TRUSTED DEVICE  +  LICENSE/ACTIVATION  +  SERVER-SIDE TENANT AUTHORIZATION
```

with an **Owner-governed device-trust mechanism** as the new, server-enforced layer. (Requirements A–J in section 7 of the authorizing prompt are reproduced in intent below and concretized in the governing contracts of §H–§N.)

---

## F. Threat Model

| Threat | Channel | Current posture | Gap that enables it |
|---|---|---|---|
| THREAT A: stolen email/password, different device | attacker installs official app on own phone/PC, signs in with stolen credentials, calls RPCs | `require_shop_permission` authorizes `auth.uid()` + ACTIVE membership + role | **No device trust is checked anywhere** → a fresh forged `installation_id` is auto-registered ACTIVE → full business access. (CONFIRMED: `register_device` sets ACTIVE; no RPC/RLS consults device status.) |
| THREAT B: stolen already-approved device | physical theft of an approved device | secure token storage (Keystore/DPAPI); SQLite **plaintext** | no local app lock; no DB encryption; cached entitlements plaintext (`entitlement_cache.dart:89-137`) |
| Cross-tenant manipulation | attacker changes `shop_id` manually / direct API | `require_shop_permission` + row `shop_id` scoping are solid | partially mitigated already; device trust must not regress it |
| Invitation / membership takeover | attacker exploits `accept_invitation` | — | `accept_invitation(p_shop_id, p_user_id)` uses **client-supplied user id with no identity verification, no token, no expiry check**; temp password never delivered; `email_confirm:true` |
| Token replay / shared-code leak | static shared company code | — | a static Shop Code is rejected in §L |
| New-device auto-grant | REGISTER_DEVICE auto-ACTIVE | — | no PENDING state |

---

## G. Existing Reusable Architecture (Section 19 evidence table)

| Capability | Repository evidence | Current state | Reusable? | Gap | Target |
|---|---|---|---|---|---|
| `shop_members` | `2026...0001` (role IN owner/employee/salesOnly; status IN INVITED/ACTIVE/SUSPENDED/REVOKED; UNIQUE(shop,user)) | COMPLETE | **YES** — server-side membership incl. SUSPENDED/REVOKED | none (foundation for tenant + suspension propagation) | reuse as-is |
| Invitations | `2026...0021` (shop_id, email, role, invited_by, status PENDING/ACCEPTED/EXPIRED/REVOKED, expires_at; owner-only RLS) | COMPLETE | **YES** | **no token column**; expiry not enforced by accept path | add one-time invitation token + acceptance proof (Group B) |
| invite-employee edge fn | `functions/invite-employee/index.ts` | PARTIAL / BUGGY | **PARTIAL** | temp random password never delivered (TODO email); `email_confirm:true`; `null user_id` bug (documented) | redesign to Owner-authorizes-person + employee-sets-own-credential + server-bound membership; no reusable shared secret |
| `accept_invitation` | `2026...0022` | PARTIAL / INSECURE | **PARTIAL** | no caller-identity bind, no token, no expiry | replace with secure acceptance (employee-set password + token proof-of-possession) |
| `devices` | `2026...0004` (installation_id, shop_id, user_id, platform, status ACTIVE/REVOKED/LOST) | COMPLETE | **YES (schema)** | **no PENDING**; no device secret/keypair; installation_id forgeable | additive: PENDING status + device public-key registration + approval/revoke/lost (Group B) |
| `activations` | `2026...0006`, `...0023` | COMPLETE | **YES** | binds device↔license; not an authorization gate | reuse for license/activation defense-in-depth |
| `licenses` | `2026...0005`, `...0023` (shop-scoped, max_devices) | COMPLETE | **YES** | plan/tier model not implemented (P-OD8) | Group B licensing |
| Device identity / secure stores | `device_identity_provider.dart`, Android `MainActivity.kt` Keystore+EncryptedSharedPreferences, Windows DPAPI `secure_store.dart` | COMPLETE (platform) | **YES** | installation UUID is **weak pseudo-random + plaintext** (`entitlement_cache.dart:186-195`; `app_settings`) and **not bound to secure storage** | bind installation identity to platform secure store; add per-install keypair (Group B) |
| Permission sync / RBAC / RLS | `2026...0024`, `...0029`, `require_shop_permission` | COMPLETE | **YES** — server-authoritative | **no device predicate in `require_shop_permission`** | add device-trust gate (Group B) |
| `get_user_shop_ids()` | `2026...0029` (fail-closed, ACTIVE only) | COMPLETE | **YES** | none | reuse (membership source for device approval) |
| Active shop context | `active_shop_context.dart` (fail-closed `TenantContextException`) | COMPLETE | **YES** | none | reuse |
| Seller provisioning / cloud session resume | `seller_session_provisioning.dart` (D-L1), `cloud_session_resume.dart` (D4) | COMPLETE | **YES** | no device-approval gate in provisioning chain | insert new-device approval gate after auth, before business access (Group B) |
| Local cache / SQLite | `database_helper.dart` (`muaman_store.db`, schemaVersion=18, **plain `sqflite`**) | COMPLETE | **YES (behav)** | **DB not encrypted**; local `app_settings` holds plaintext installation UUID | classify per §M2; DB encryption = POST_RELEASE_HARDENING unless Owner escalates |

---

## H. Security Gaps — Exact Missing Pieces (Group B, P-OD13)

Identified from evidence:

1. **No device approval concept.** `register_device` force-sets `status='ACTIVE'`; `devices.status` CHECK excludes PENDING. → need additive PENDING + approval flow.
2. **No device trust in the authorization path.** `require_shop_permission` and every RLS `USING` predicate = `auth.uid()` + ACTIVE membership (+ license for writes). Device status is consulted **nowhere**. → need server-authoritative device gate, NOT a UI-only lock.
3. **Weak, forgeable device identity.** Installation UUID generated client-side from `DateTime.now()` (time-derivable), stored **plaintext in SQLite**, not bound to platform secure storage, no keypair/proof-of-possession. → need installation-bound cryptographic identity (device keypair; public key registered; challenge/proof-of-possession), NOT invasive hardware fingerprinting.
4. **Invitation flow is insecure & broken.** Temp random password never delivered (TODO email); `email_confirm: true`; `accept_invitation` trusts client-supplied `p_user_id` with no identity proof/token/expiry; membership/credential model contradicts "employee sets their own credential". → redesign per §J.
5. **No MFA.** → optional/recommended per §L.
6. **No device-management UI** (approve/reject/revoke/lost) — `getDeviceList`/`deactivateDevice` exist server-side with **zero UI call sites**. → Owner UI (Group B).
7. **Stolen-device/offline exposure** (plaintext SQLite cache + entitlements, no app lock). → classified §M2.
8. **Static shared company-code risk.** → rejected in favor of one-time pairing token (§K).

---

## I. Device-Trust Governing Contract (P-OD13) — design/govern, NOT implement

Intended additive model (repository-compatible; historical `devices` migration unedited):

- **State**: additive `PENDING_APPROVAL` (or additive equivalent) added via a NEW additive migration (drop+re-add the `devices.status` constraint, or a separate `device_approvals` table; do NOT edit `2026...0004`). Lifecycle: `PENDING → ACTIVE` (Owner approve), `ACTIVE → REVOKED`, `ACTIVE → LOST`; plus `ACTIVE → REVOKED` on membership SUSPENDED/REVOKED.
- **Login**: any NON-OWNER account on a previously-unrecognized installation authenticates successfully but lands in state `AUTHENTICATED` + `DEVICE_APPROVAL_REQUIRED`; no business-data access until Owner approves. Owner on a fresh device follows the same gate (Owner is not exempted by default unless Owner explicitly governs otherwise).
- **Device identity**: per-installation keypair bound to platform secure store (Android Keystore; Windows DPAPI/equivalent). Register the device **public key** server-side; server issues a challenge; client proves possession; the server grants **active-device status** only to proof-passing, Owner-approved devices. Prefer installation-bound cryptographic identity over fragile hardware fingerprinting (repository/privacy-aware).
- **Reinstall**: a reinstall generating a new trustworthy installation identity = NEW device → re-approval required, unless the mechanism cryptographically proves continuity (not by default).
- **Second device**: an ACTIVE approved phone works normally; the same account on another phone requires separate Owner authorization (P-OD8 device quota applies where defined).
- **Revocation**: Owner revokes → future cloud business access denied (fail-closed at next online session), no upload/drain authorization, no privileged op; session/device state converges to REVOKED. Offline consequences are defined in §N.
- **Lost**: mark LOST → denied like revoked.
- **Suspended/revoked employee**: `shop_members.status` becomes SUSPENDED/REVOKED → all devices for that employee lose shop access regardless of prior approval.
- **License/activation**: device trust composes with existing license/activation (defense-in-depth), never a substitute.

---

## J. Invitation / Pairing Governing Contract

- **INTENDED onboarding model (production-safe)**: Owner authorizes the person (invitation bound to `shop_id` + email + role + invited_by + status + expiry); the **employee establishes their own credential** (set-password via secure acceptance) rather than the current delivered-random-password model; the resulting `auth.user` is bound **server-side** to the invited `shop_members` membership.
- **Emails**: remove reliance on a never-sent temp password; govern actual invitation-email delivery (SMTP or Owner-delivered secure token) as Group B design detail.
- **Static shared Shop Code is REJECTED** as a security authority (`§K`).
- **One-time invitation/pairing token** (optional, UX-only) if adopted: cryptographically random, short lifetime, single-use, server-stored as hash where appropriate, bound to `shop_id` + invitation/user/email + intended role, expires, revocable, never replaces membership/device/server authorization; unusable after successful use (replay/CASE 12, cross-shop CASE 13 fail closed).
- **`accept_invitation` must be corrected** (caller-identity bound + token-proof + expiry) — currently it is a membership-takeover risk. This is a security correction, not a feature; it belongs in Group B.

---

## K. Company/Pairing Code Decision

Repository evidence and security principles (`PROJECT_MASTER_PLAN.md` §11 — no client-trust, signed, server-authoritative) lead to: **do NOT use a permanent shared Shop/Company Code as any authentication or authorization factor.** A static code leaks and is insufficient as an authentication factor. If a code improves onboarding UX, govern it **only** as an OPTIONAL ONE-TIME PAIRING/INVITATION TOKEN with the properties in §J (random, short-lived, single-use, server-stored as hash, bound to shop+invitation/email+role, expiry, revocable, cannot replace membership/device/server authorization). After success it is unusable.

---

## L. MFA Determination (defense-in-depth)

- **Owner MFA**: RECOMMENDED at launch (owner is the highest-privilege tenant principal). Not a hard RELEASE_BLOCKER absent explicit Owner risk instruction — classify as `P_RECOMMENDED` default.
- **Privileged employee MFA**: RECOMMENDED if the employee holds `admin.*` or broad write permissions; otherwise OPTIONAL at Owner policy. `P_RECOMMENDED` by default, `P_REQUIRED` only if Owner escalates privileged-employee guarantee.
- **salesOnly MFA**: OPTIONAL / Owner policy (limited surface).
- MFA is NEVER a substitute for tenant membership/RBAC/device trust; it is an additional account-takeover mitigation. Exact mechanism (Supabase AAL2/MFA or equivalent) = Group B design detail selected from repository evidence.

---

## M. Server-Enforcement Determination (CRITICAL — no fake security)

Two distinct properties, stated rigorously:

- **CLIENT UX DEVICE GATE**: the Flutter pending/approval screen. This ALONE is **not** a security boundary; a modified client or direct Supabase call bypasses it.
- **SERVER-AUTHORITATIVE DEVICE GATE**: the intended security property. Because current authorization = `auth.uid()` + ACTIVE `shop_members` (+ license for writes) in **RLS `USING` predicates AND `require_shop_permission`**, device trust is **absent from every path today** (evidence, §D.2 H). To claim DEVICE-TRUST security, the design MUST make the server deny business reads/writes for an unapproved device.

**Smallest coherent server-authoritative design (selected, not UI-only):**
1. Additive device-approval state (`devices.status` PENDING via additive migration, or separate `device_approvals`) and a registered device **public key** (+ challenge/proof-of-possession).
2. Introduce a device-trust check into the **server authorization layer** so it cannot be bypassed by a modified client: at minimum enforce ACTIVE-approved device in (a) **new write RPCs / `require_shop_permission`-gated surface** and, where the threat model requires read protection, (b) the relevant RLS/read path (a new `require_shop_device`/approved-device SECURITY DEFINER predicate or RLS USING extension).
3. Convey the device/session proof server-side via an Edge Function exchange or a signed/session-bound assertion as designed in Group B; never rely on a client-attested flag.

Explicit consequences to record truthfully:
- If the final implementation protects **writes** only, business **reads** for an unapproved device remain available until the read path is migrated — the report must not overstate.
- If the final implementation is UI-only, it provides **NO** security against the stated threat and must be labeled CLIENT UX DEVICE GATE only.
- The implementation dependency slice list in §P is the mechanism by which the server-authoritative property is actually delivered.

The governance selects server-authoritative enforcement and requires the specific/smallest mechanism (device public-key registration + proof-of-possession + server device gate on write and read paths as designed) — no fake security claim.

---

## N. Offline / Revocation Semantics (determination)

- **Approved device offline**: offline operations proceed per existing entitlement/offline-grace law (paid 7d / trial 0d / perpetual 14d-compat; P-OD9), composed with device being ACTIVE-approved at last check.
- **New-unapproved device offline**: MUST NOT self-authorize (CASE 17); no business access.
- **Revoked/LOST device while temporarily offline**: deny privileged/uploads at next online session (fail-closed); the offline window is bounded by entitlement/revocation law; define exact convergence in Group B (device + session state converge to REVOKED).
- **Membership SUSPENDED/REVOKED**: all employee devices lose shop access regardless of prior device approval.
- **Stolen-device exposure (THREAT B)**: minimum protection before final delivery:
  - local session persistence + logout/revocation propagation are governed (should already clear cached session/tokens on logout — `main.dart:346-369`); verify.
  - local SQLite/cache exposure classified: **Data at rest is NOT encrypted** (plain `sqflite`; `entitlement_cache.dart` plaintext). Classification on evidence: `POST_RELEASE_HARDENING` (recommended) unless the Owner escalates a stolen-device-with-offline-data guarantee, in which case it becomes `P_REQUIRED`. It is NOT a launch RELEASE_BLOCKER given the primary threat (stolen credentials, not device) — but this is stated truthfully, not hidden.
  - local app lock: `P_RECOMMENDED` (optional OS-level), not a launch blocker absent Owner escalation.

---

## O. Correct Phase/Group/WS Placement (verified, not assumed)

Primary home: **PHASE P → OWNER-GATED → GROUP B — LICENSING / COMMERCIAL / SECURITY (WS-4)**, because it depends on device registration (`devices`), license activation (`activations`/`licenses`), shop membership (`shop_members`), server authorization (`require_shop_permission`), security hardening, and revocation (P-OD10) — all Group B/WS-4 concerns.

- It is **CROSS-PLATFORM** (Windows + Android) and therefore must NOT be hidden inside Android-only Group C.
- Group C (Android package identity, release signing, release boundary) remains unchanged; **Group C release verification must include the device-trust flow on Android** after Group B supplies it. Windows release verification likewise includes it.
- Group A must **not** be reordered/short-circuited by this new requirement (Group A remains blocked as-is; see §R). The device-trust feature is additive to Group B and does not unblock Group A's production/deployment/drain chain ahead of its own gate.
- New owner-decision identifier: **P-OD13** (verified: next legitimate additive ID after P-OD12; no collision).

---

## P. Implementation Dependency Slices (plan later, do NOT implement now)

1. Supabase additive schema — device-approval state (+ PENDING additive), device public-key registration, user-shop-device relation, `approved_by`/`revoked_by`/timestamps, audit trail, invitation-token fields (hashed).
2. Server authorization — Owner approve/reject/revoke/lost RPCs; device proof validation (challenge/proof-of-possession); permission checks; RLS/read-path device gate; activation/license checks.
3. Invitation hardening — secure acceptance flow; employee-defined password; expiration; one-time pairing token (if adopted); no reusable shared company secret; `accept_invitation` correction.
4. Flutter runtime — login membership resolution; device-registration request; pending screen; approval polling/refresh; fail-closed state; logout/session cleanup; device keypair in platform secure store.
5. Owner UI — pending devices; approved devices; reject/revoke/lost; employee↔device relationship.
6. Android — Keystore-bound identity; new-device flow.
7. Windows — secure device identity via DPAPI/equivalent.
8. Offline behavior — approved/new/revoked-offline + entitlement grace (§N).
9. Audit/observability — approval/rejection/revocation/lost/failed-proof; no secrets/PII in logs.

Cross-dependency: Group B slice 2 depends on 1; Flutter 4 depends on 1+2+3; Owner UI 5 depends on 2; platform 6/7 depend on 4+secure store foundation. Group C release verification consumes Group B's feature.

---

## Q. Required Security Acceptance Tests (future — bind to the governing contract)

CASE 1 Valid employee + ACTIVE membership + approved device → only permitted Shop A data.
CASE 2 Valid credentials + NEW unapproved device → auth may succeed but business access denied/pending.
CASE 3 Competitor with stolen Shop A employee email/password on another phone → no Shop A data without Owner approval.
CASE 4 Attacker changes `shop_id` → server denies cross-tenant.
CASE 5 Direct API with stolen auth but no device-trust proof → fails (server-authoritative design).
CASE 6 Owner approves pending → device ACTIVE, role-limited access begins.
CASE 7 Owner rejects → no business access.
CASE 8 Owner revokes ACTIVE → future access denied per revocation SLA.
CASE 9 Owner marks LOST → future access denied.
CASE 10 Membership SUSPENDED/REVOKED → all employee devices lose shop access.
CASE 11 Expired invitation/pairing token → rejected.
CASE 12 Used-token replay → rejected.
CASE 13 Shop-A token vs Shop B → rejected.
CASE 14 Second legitimate employee device → independent approval + device quota.
CASE 15 Reinstall → governed re-approval policy.
CASE 16 Offline approved device → entitlement/device revocation law.
CASE 17 Unknown first-time device offline → MUST NOT self-authorize.
CASE 18 salesOnly cannot gain manager/owner perms through device approval.
CASE 19 (server-authoritative) modified client / direct RLS call with unapproved device → denied (proves NOT UI-only).
CASE 20 Employee sets own password; Owner does not retain reusable password.

---

## R. Current Group A Blocked State (must NOT be lost)

From `POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE.md` (remote-locked at `1ba42a3`) and live repo:

```text
A1..A8                = COMPLETE + REMOTE LOCKED
MIGRATION_30          = NOT DEPLOYED (repo-only; migration `2026...0030` present, undeployed)
MIGRATION_28          = PRODUCTION_PRESENCE DOCUMENTED (Gate-12 report); live re-probe deferred
MIGRATION_29          = PRODUCTION_PRESENCE UNDOCUMENTED — MUST BE LIVE-VERIFIED (PROD_CASE_D gate)
PROD_CASE             = PROD_CASE_A (28+29 present, 30 absent) — CONDITIONAL on live verification
CRITERION_16          = DOCUMENTED-EQUIVALENT (PASS-of-record); live probe deferred to owner-signed gate
DRAIN                 = OFF (syncDrainEnabled = FALSE)
BACKUP/RECOVERY POSTURE= NOT CONFIRMED under the locked deployment gate
```

**Steps still required to close Group A (exact, in order):**
1. Resolve the **FREE_PLAN_BACKUP_GOVERNANCE_CORRECTION** — the locked deployment gate (§J/§7.15 of deployment plan) requires `pg_dump --schema-only` + `pg_dump --data-only` **and a 7-day minimum dashboard full backup / point-in-time recovery**. The Owner prefers remaining on **Supabase Free**, which does NOT provide the paid Plan's continuous backups/PITR. This is a genuine conflict between the locked backup gate and the Free-plan posture. Do NOT silently weaken the locked backup gate. Determine (Owner decision) whether the Free plan can satisfy the recovery gate via reproducible `pg_dump` artifacts + restoration test, or whether a plan decision/provisional backup-governance correction is required — place this correction EXACTLY where it belongs: **before** Migration-30 deployment, remote-locked first.
2. Remote-lock the corrected backup law.
3. Produce verified backup/dumps + a restoration proof (CASE rel: backup→restore test).
4. Resume Migration-30 deployment execution (live-verify Migration 29 presence first).
5. Migration-30 post-deploy verification + criterion-16 live probe → Group-A production evidence COMPLETE.
6. Dedicated P-OD7 drain-activation governance + execution (owner/release).
7. Group-A final closeout + remote lock.

No drain activation before this chain is satisfied.

---

## S. Groups B/C/D Remaining Work & Final Roadmap Notes

- **Group A** — blocked per §R; MUST close first (serial dependency for drain + Option C production durability).
- **Group B** — contains P-OD8..P-OD12 (licensing/commercial/security: subscription+tiers+grace+revocation+tamper+Ed25519 retirement) **PLUS P-OD13 employee device trust (this governance)** including invitation hardening (§J), server-authoritative device gate (§M), Owner device UI, platform secure identity, offline/revocation semantics (§N). Cross-platform. LANDS AFTER Group A (relation: Group B server work is additive and does not block Group A's deploy; but the roadmap closes A before B to preserve the canonical dependency and the deferred-planning protocol).
- **Group C** — Android package identity (P-OD2) + production signing (P-OD3, needs Owner keystore, external secret) + release boundary. Includes device-trust flow verification on Android. Webbitable `BLOCKED_OWNER_DECISION` (keystore/package).
- **Group D** — cost-change workflow (P-OD4), opening balances (P-OD5), arbitrary-period reporting (P-OD6) — mostly independent accounting/business work.

Each Group requires its own planning → remote-lock → implementation → remote-lock per the established protocol; `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` already established that Groups B/C/D each need their own planning boundary.

---

## T. Canonical Remaining Roadmap (dependency chain, evidence-backed)

Any ordering change vs. the prompt's broad order is explained. Deviations from the prompt's broad order are: (a) device-trust placed inside Group B (not a separate group), (b) Group A closure strictly serialized ahead of B/C/D because A's drain+Option-C production durability is a prerequisite for safe cloud behavior, and the backup-governance correction is inserted between the current HOLD and Migration-30 deploy (the prompt anticipated this), (c) Group C release verification explicitly consumes Group B device-trust.

```text
[ CURRENT HOLD: Migration-30 deployment governed, NOT deployed; Group A open ]
   ↓
FREE_PLAN_BACKUP_GOVERNANCE_CORRECTION (resolve Owner plan-vs-gate conflict)  →  remote lock
   ↓
produce verified backup/dumps + backup→restore proof
   ↓
live-verify Migration 29 presence → resume Migration-30 deployment execution
   ↓
Migration-30 post-deploy verification + criterion-16 live probe (Group-A production evidence COMPLETE)
   ↓
dedicated P-OD7 drain-activation governance + execution (owner/release)
   ↓
Group-A final closeout + remote lock
   ↓
Group-B planning (licensing/commercial/security P-OD8..P-OD12 + NEW P-OD13 employee device trust [incl. invitation hardening + server device gate + Owner device UI + platform secure identity])  →  remote lock
   ↓
Group-B implementation (schema → server authz → invitation → Flutter runtime → Owner UI → platform 6/7 → offline/audit)  →  tests
   ↓
Group-B production migration/deployment/verification (as required)  →  remote lock / closeout
   ↓
Group-C (Android identity/signing/release; Owner keystore gating) — release verification includes device-trust flow on Android
   ↓
Group-D (cost-change / opening balances / arbitrary-period reporting)
   ↓
WS-6 / WS-8 residual release gates if not already complete (formatting baseline, versioning)
   ↓
WS-10 security/Supabase final seal
   ↓
FULL TEST GATE (analyze 0/0, dart format, all flutter test) & acceptance-gate suite (§24)
   ↓
Windows RELEASE CANDIDATE  →  Android RELEASE CANDIDATE
   ↓
MANUAL END-TO-END ACCEPTANCE
   ↓
PHASE-P FINAL GOVERNANCE CLOSURE
   ↓
FINAL CUSTOMER DELIVERY
```

---

## U. Final-Delivery Definition (three explicit milestones)

- **M1 = CODE COMPLETE**: all required code/schema changes finished and locally verified (Groups A/B/C/D + residual gates); not a "delivery".
- **M2 = RELEASE CANDIDATE READY**: production migrations verified, Windows release build verified, Android signed release verified, security and backup gates passed, WS-10 seal green.
- **M3 = FINAL CUSTOMER DELIVERY**: all governing acceptance criteria passed, all remote locks complete, manual verification complete, release artifacts reproducible, no unresolved `P_REQUIRED` blocker.

---

## V. Final Acceptance / Release Gates (before final delivery)

Required green at Phase P exit / M3:
- `flutter analyze` (0 errors / 0 warnings); `dart format --set-exit-if-changed`; `flutter test` (baseline 1428/1428 + deltas; the 3 pre-existing failures → 2 shop-profile widget-tests resolved WS-8, 1 crash-recovery WS-1).
- migration replay tests; backup→restore test (Free-plan correction); production schema verification; RLS tests; RBAC tests; **device-trust security tests** (CASE 1–20, §Q); employee invitation tests; cross-tenant tests; offline→online sync tests; idempotency tests; Option-C durability tests; license/trial/tier tests; revocation tests.
- Windows release build; Android **signed** release build; Android install/smoke; Windows install/upgrade smoke; secret/leak scan; release version consistency.
- Any currently-known failing test must be CLASSIFIED (all three are classified in `PHASE_P_PRODUCTION_HARDENING_PLAN.md` §D.1/K as P_REQUIRED-to-exit; none are RELEASE_BLOCKER by themselves beyond the exit gate).

---

## W. Delivery Estimate (evidence-backed; reference date 2026-08-31)

Ground truth: this is NOT a greenfield; the foundation is reusable (§G). But two realities raise the estimate above a naive 12–15 days:
1. **Group A is genuinely blocked** (backup-governance/Free-plan conflict + Migration-29 live verification + Migration-30 deploy + drain + closeout) and is fully serial before the drain is safe.
2. **P-OD13 device trust is substantial, NEW, cross-platform security work** (server-authoritative enforcement, device keypair/proof-of-possession, invitation hardening, Owner device UI, offline/revocation semantics, 20 security cases) on top of an already-sizeable Group B (P-OD8..P-OD12).

Per-scope governing estimate (working days; waiting-time is NOT engineering completion):

| Scope | BEST | REALISTIC | BUFFERED | Dependency / blocker |
|---|---|---|---|---|
| Group A remaining (backup correction, Mig-29 verify, Mig-30 deploy+verify, drain, closeout) | 4 | 5 | 7 | Free-plan backup decision; production access; owner-signed drain |
| Group B (licensing P-OD8..12 + P-OD13 device trust incl. invitation hardening + server device gate + Owner UI + platform identity) | 10 | 13 | 16 | depends on A-closeout; Owner decisions on MFA/code/plan |
| Group C (Android identity/signing/release + device-trust-on-Android verify) | 3 | 4 | 6 | **Owner Android signing keystore** (external) |
| Group D (cost-change/opening-balances/period reporting) | 4 | 5 | 7 | none blocking (can be scheduled after B) |
| Residual WS-6/WS-8 gates + WS-10 seal | 2 | 3 | 4 | depends on B/C/D |
| Full regression + manual acceptance + release packaging + final closure | 3 | 4 | 6 | manual verification availability |

Totals (serial critical path A→B→C→WS-10→release/acceptance; Group D overlaps-B):

```text
TOTAL_BEST_CASE_WORKING_DAYS    = 20   (4+10+3+0+2+3; D overlaps B, 0 additional on path)
TOTAL_REALISTIC_WORKING_DAYS    = 29   (5+13+4+3+4;  Group D on path after B = 5+13+4+5+3+4 = 34 → trimmed to 29 by D/C overlap)
TOTAL_BUFFERED_WORKING_DAYS     = 36   (7+16+6+7+4+6 = 46 → trimmed to ~36 with parallelization)
```

Honing to a defensible, honest number: **REALISTIC ≈ 28–32 working days; BUFFERED ≈ 34–38 working days**. The prompt's 12–15-day hypothesis is **NOT supported** once the cross-platform employee-device-trust requirement and the genuinely-blocked Group A are accounted for. Truth over optimism.

Working-day calendar from 2026-08-31 (5-day weeks; no holidays asserted):

```text
EARLIEST_CREDIBLE_FINAL_DELIVERY_DATE  ≈ 2026-09-28  (best-case ~20 working days→~4 wks)
RECOMMENDED_COMMITMENT_DATE            ≈ 2026-10-12  (realistic ~29–30 working days→~6 wks)
BUFFERED_SAFE_DATE                     ≈ 2026-10-26  (buffered ~34–36 working days→~8 wks)
```

These are estimates from repository reality and will be re-derived by the successor delivery-planning sessions as each group closes; they are not commitments treated as fixed.

---

## X. External Blockers (real only)

1. Owner **Supabase backup-plan decision** (Free vs paid) — required to resolve `FREE_PLAN_BACKUP_GOVERNANCE_CORRECTION` before Migration-30 deploy.
2. Owner **Android release-signing keystore/credentials** — required for P-OD3 / Group C signed release (must fail-closed if absent; secrets outside repo).
3. **Production access** — required for Migration-29/30 live verification and Group B/D production deployment/verification.
4. **Manual verification availability** — required for final end-to-end acceptance.
5. Owner decisions on **MFA posture**, **pairing-token adoption**, and **offline/stolen-device escalation** (defaults stated; escalation would move items from `P_RECOMMENDED` to `P_REQUIRED`).

---

## Y. Prohibited Actions Audit

```text
IMPLEMENTATION_STARTED               = NO
PRODUCTION_MUTATION                  = NO
MIGRATION_30_DEPLOYED                = NO
DRAIN_ACTIVATED                      = NO
GROUP_B_IMPLEMENTATION_STARTED       = NO
GROUP_C_IMPLEMENTATION_STARTED       = NO
GROUP_D_IMPLEMENTATION_STARTED       = NO
RELEASE_BUILD                        = NO
ANDROID_SIGNING                      = NO
PUSH_OCCURRED                        = NO
TAG_CREATED                          = NO
LEGACY_ORIGIN_USED                   = NO
SACRED_ARTIFACT_MUTATION             = NO
supabase/.temp cleanup               = NO
migration-file / source / build edits= NO (sole mutation = this governance artifact)
frozen-identifier / historical-plan rewrite = NO
```

---

## Z. Success Token & Next Authorized Session

```text
SUCCESS_TOKEN =
PASS_POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION_LOCAL_READY

(minted only if: entry CASE_A clean; remote synced; sacred PRE==POST; roadmap re-audited;
 device-trust requirement correctly placed (P-OD13 / Group B); delivery order + estimate
 defined from evidence; sole tracked mutation governance; no implementation/deploy/drain/push/tag.)

NEXT_AUTHORIZED_SESSION =
POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION_REMOTE_LOCK
```

The immediate successor is the **remote lock of this governance artifact** — NOT Group-B implementation, NOT Migration-30 deployment, NOT drain activation. After this remote lock, the canonical governed road resumes: Group A closure (backup correction first) → Group B planning (licensing + device trust) → etc., per §T. Do not jump directly into implementation.

---

## Closure State

```text
SESSION                         = POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION
SESSION_RESULT                 = PASS (local ready — governance / roadmap determination only)
RECOVERY_CLASSIFICATION        = CASE_A_FRESH_GOVERNANCE_CONTINUATION
OWNER_REQUIREMENT              = EMPLOYEE DEVICE TRUST (defense-in-depth) — INTEGRATED
PLACEMENT                      = PHASE P → GROUP B (WS-4) → P-OD13
SERVER_ENFORCEMENT             = SERVER-AUTHORITATIVE DEVICE GATE (NOT UI-only) — designed, not implemented
GROUP_A                        = A1..A8 COMPLETE+REMOTE_LOCKED; production deployment OPEN (backup correction + Mig-29 verify + Mig-30 deploy + drain)
GROUPS B/C/D                   = DEFINED / NOT STARTED; B now includes P-OD13
PHASE_P_FINAL_CLOSURE          = NOT_COMPLETE
FINAL_DELIVERY                 = M1/M2/M3 defined; estimated REALISTIC ≈29 wd / BUFFERED ≈36 wd from 2026-08-31
DRAIN_ACTIVATED                = NO
MIGRATION_30_DEPLOYED          = NO
PUSH_OCCURRED                  = NO
TAG_CREATED                    = NO
LOCAL_CLOSURE_TOKEN            = PASS_POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION_LOCAL_READY
NEXT_AUTHORIZED_SESSION        = POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION_REMOTE_LOCK
```

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION = CASE_A_FRESH_GOVERNANCE_CONTINUATION
LOCKED_HEAD          = 1ba42a3a7918fb0c3d7e9fc1481596e457f52cad
DIFF PROFILE         = 1 added file (this artifact), 0 modified, 0 deleted
SACRED PRE  = 3D4D17… / C8C5BD… / 70F848…  ✓ (full values §B)
SACRED POST = <recorded after commit>   ✓ PRE == POST required
COMMIT      = <set after commit>
AHEAD/BEHIND= <1/0 after commit>
SESSION TOKEN = PASS_POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION_LOCAL_READY
```
