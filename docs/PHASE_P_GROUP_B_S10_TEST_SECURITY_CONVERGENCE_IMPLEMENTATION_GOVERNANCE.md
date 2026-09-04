# Phase P — Group B — S10 Test / Security Convergence — Implementation Governance

**Document purpose:** Freeze the exact implementation-governance contract for Group B **S10 — Test / Security Convergence** against the committed server-authoritative entitlement, device-trust, secure-identity, S8 tamper/cache/clock, and S9 legacy-Ed25519-retirement system. This is a **governance-only** artifact. It does **NOT** implement S10, does **NOT** modify any production Dart, Supabase SQL, migration, RPC, RLS, Auth, or Edge Function surface, and authorizes nothing beyond the exact contract recorded here. A governance remote-lock is **not** an implementation authorization.

```text
AUTHORIZED_UNIT      = S10 — TEST / SECURITY CONVERGENCE
AUTHORIZED_REMOTE    = github  (https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_REMOTE        = origin  (C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن) — SACRED READ-ONLY, NEVER CONTACTED
LEGACY_ORIGIN_CONTACTED = NO
EXPECTED_SUCCESS_TOKEN =
  PASS_PHASE_P_GROUP_B_S10_TEST_SECURITY_CONVERGENCE_IMPLEMENTATION_GOVERNANCE_REMOTE_LOCKED
```

---

## A. Session Identity

```text
REPOSITORY        = muaman_store
WORKTREE ROOT     = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED REMOTE = github (https://github.com/sabere342-ai/muaman.worktrees.git)
ENTRY HEAD SHA    = 27946b4cb26b01b3877ed3293127d224270e1484
PREDECESSOR SHA   = 27946b4cb26b01b3877ed3293127d224270e1484 (S9 implementation)
ENTRY CLASS       = CASE_A_FRESH
TRACKED WORKTREE  = CLEAN (only pre-existing untracked sacred evidence remains, untouched)
INDEX             = EMPTY
```

---

## B. Authority Chain (S8 → S9 → S10)

```text
S8 Governance      = 217615514cb83aba0a629e01e619e418094fd9ae  "docs: govern Group B S8 tamper cache clock enforcement"
S8 Implementation  = 7460f915197db06309aff905be91c10b379b4ab4  "feat: implement Group B S8 tamper cache clock enforcement"
S9 Governance      = 2295b5d7cfcc7f59111d0cbade35f56e66c88941  "docs: govern Group B S9 legacy Ed25519 retirement"
S9 Implementation  = 27946b4cb26b01b3877ed3293127d224270e1484  "feat: implement Group B S9 legacy Ed25519 retirement"   ← HEAD / immediate predecessor
S10 Governance     = THIS ARTIFACT
```

Forensic proof of chain (all verified at entry):

```text
2176155...→ parent a67996a...  subject docs: govern Group B S8 ...
7460f91...→ parent 2176155...  subject feat: implement Group B S8 ...
2295b5d...→ parent 7460f91...  subject docs: govern Group B S9 ...
27946b4...→ parent 2295b5d...  subject feat: implement Group B S9 ...
```

`S9_IMPLEMENTATION_SUCCESSOR = S10` per committed Group B plan and S8/S9 governance artifacts.

---

## C. S10 Official Purpose

Exact definition from committed authority (`PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` §14 and the S-series governance artifacts):

```text
S10 OWNER = Test / security convergence
S10 SCOPE = P-OD13 CASE 1–20 matrix, RLS, quota, offline, revocation, tamper,
            cross-tenant, Android/Windows identity, reconnect
S10 DEPENDENCIES = ALL PRIOR (S1..S9)
```

Direct committed statements establishing purpose:

- `docs/PHASE_P_GROUP_B_S9_...GOVERNANCE.md`: "The full 1–20 final security-matrix convergence belongs to **S10**, NOT S9."
- `docs/PHASE_P_GROUP_B_S8_...GOVERNANCE.md` §H: `S10 = test / security convergence → FORBIDDEN to S8 (final CASE/threat convergence)`; `SERVER_REQUIRED threat classes (fully-compromised-client cases) → S10 server-enforcement`; `Final CASE 1–20 test matrix → S10`.
- `docs/PHASE_P_GROUP_B_S4_...GOVERNANCE_CORRECTION.md`: `convergence of the full 1–20 matrix belongs to S10`.
- `docs/PHASE_P_GROUP_B_S6/S7...GOVERNANCE.md`: `full CASE 1–20 convergence -> S10`.

**Purpose (governance determination):** S10 is the **Group B Test / Security Convergence gate**. Its purpose is to **establish, freeze, and prove the final combined security contract** across the completed Group B slices (S1–S9), converging all existing test/static/server evidence into the P-OD13 CASE 1–20 matrix and any additional convergence security matrix, and to close genuine coverage gaps with test-only / evidence-only additions. S10 is **NOT** permission to redesign S1–S9. It does not reopen S9.

### Successor / predecessor relationships

```text
PREDECESSOR(S)  = S1, S2, S3, S4, S5, S6, S7, S8, S9 (all prior — S10 depends on all)
SUCCESSOR       = S11 (Deployment / verification governance) → S12 (Group B closeout)
GROUP C / GROUP D = FORBIDDEN to S10
```

---

## D. Predecessor Closure (S9 is Complete and Immutable)

S9 is **REMOTE_LOCKED** at `27946b4cb26b01b3877ed3293127d224270e1484`.

S9 exact implementation delta (verified by `git show --stat HEAD`):

```text
DELETE  app/lib/licensing/entitlement_token.dart        (344 lines, legacy entitlement-token Ed25519)
DELETE  app/lib/licensing/licensing_service.dart        (455 lines, superseded LicensingService/ActivationClient)
MODIFY  app/lib/licensing/licensing.dart                (barrel export surface — canonical exports kept)
MODIFY  app/lib/screens/settings_screen.dart            (legacy "الترخيص" card removed/rewired)
ADD     app/test/licensing/s9_legacy_ed25519_retirement_test.dart  (571 lines, 20-case S9 scenario matrix)
```

S9 test floors (re-verified this session, evidence-only):

```text
S9 targeted          = 20/20  PASS
S8 floor             = 41/41  PASS
licensing suite      = 236    PASS  (>=236)
full Dart            = 1724   PASS  (>=1724)
selected S4/S6/S7 invitation/device-trust regression = 75/75 PASS
```

S10 MUST NOT reopen S9. The legacy entitlement-token Ed25519 and superseded `LicensingService`/`ActivationClient` must remain retired.

---

## E. Current Architecture — Canonical Security Authority after S9

```text
PRIMARY RUNTIME ENTITLEMENT AUTHORITY = CloudLicensingService  (canonical, server-authoritative via verify_license_entitlement)
S6 DEVICE IDENTITY  = per-install Ed25519 keypair; private seed in Android Keystore / Windows DPAPI (canonical)
S6 PROOF OF POSSESSION = canonical deterministic envelope + Ed25519 verify (server-authoritative)
S8 CACHE INTEGRITY  = device/user/shop-bound authenticated offline cache + trust-server-time high-water
TRUSTED TIME        = lastTrustedServerTimeUtc high-water; anti-rollback; bounded offline grace
RETIRED             = legacy entitlement-token Ed25519 (EntitlementVerifier / EntitlementToken / TokenVerificationResult /
                      TrustedKey / parseSigned / ActivationClient / LicensingSnapshot / standalone LicensingService) — REMOVED
```

Canonical files that MUST remain unchanged (Section K / O):

```text
app/lib/licensing/cloud_licensing_service.dart
app/lib/licensing/cloud_licensing_repository.dart
app/lib/licensing/s6_device_identity.dart
app/lib/licensing/s6_proof_of_possession.dart
app/lib/licensing/s8_cache_integrity.dart
app/lib/licensing/entitlement_cache.dart
app/lib/licensing/offline_grace_policy.dart
app/lib/platform/device_identity_provider.dart
app/lib/screens/settings/license_status_screen.dart
supabase/**  (all migrations / tests / functions / RLS / RPCs)
```

---

## F. Final Group B Security Matrix

This governance artifact grounds the S10 convergence matrix on the committed **P-OD13 CASE 1–20 matrix** (Section 11.2 of `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md`, reproduced in the S4 governance correction) **and** the cross-layer security matrix prescribed by this S10 governance session (Sections 9 of the S10 SUPER PROMPT). The committed P-OD13 1–20 matrix is the authoritative server-side contract; the cross-layer A–G matrix below is the client+static convergence view. Both are reconciled item-by-item. No pass/fail status is fabricated.

### F.1 P-OD13 CASE 1–20 (committed authority)

```text
| # | Threat / case                              | Fail-closed expectation          |
|---|--------------------------------------------|-----------------------------------|
| 1 | Valid employee + ACTIVE membership + approved device | authorized surface granted |
| 2 | Valid credentials + NEW unapproved device  | business access denied/pending    |
| 3 | Stolen Shop A creds from another phone     | no Shop A data without approval   |
| 4 | Attacker changes shop_id (cross-tenant)    | denied                            |
| 5 | Direct API with stolen auth, no device proof | denied (server-authoritative)    |
| 6 | Owner approves pending device              | ACTIVE, role-limited access       |
| 7 | Owner rejects                              | denied / pending end-state        |
| 8 | Owner revokes ACTIVE                       | future access denied              |
| 9 | Owner marks LOST                           | treated as revoked                |
|10 | Membership SUSPENDED/REVOKED               | all employee devices lose access  |
|11 | Expired invitation / pairing token         | rejected                          |
|12 | Used-token replay                          | rejected (single-use)             |
|13 | Shop-A token vs Shop B                     | rejected (bound to shop+invitation) |
|14 | Second legitimate employee device          | independent approval + device quota |
|15 | Reinstall                                  | governed re-approval              |
|16 | Approved device offline                    | bounded by grace (last-sync + grace) |
|17 | Unknown first-time device offline          | MUST NOT self-authorize           |
|18 | salesOnly cannot gain manager/owner        | permission escalation denied      |
|19 | Modified client / direct RLS call          | denied (server gate in RLS/RPC)   |
|20 | Employee sets own password; no reusable secret | no shared secret retained     |
```

### F.2 Cross-Layer Security Matrix (client + static + server view)

Evidence-class legend:

```text
RUNTIME_PROOF   = verified by a passing Dart test this session
STATIC_PROOF    = verified by committed source/call-graph/scan (no runtime test)
SERVER_PROOF    = committed server SQL / Edge Function test (local execution infrastructure-blocked this session)
PARTIALLY_COVERED = governed scenario exists but not fully connected by tests
NOT_COVERED     = genuine gap for future S10 implementation
INFRASTRUCTURE_BLOCKED = server execution unavailable locally (pre-existing tooling)
```

#### A. Device Identity

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 1 | Installation identity stable across restart | RUNTIME_PROOF | s6_device_identity_test: second load reuses identity |
| 2 | Private seed generated once per install | RUNTIME_PROOF | s6_device_identity_test: fresh store yields new identity persisted once |
| 3 | Private seed remains protected (no plaintext/log/AppSettings/SQLite) | RUNTIME_PROOF | s6_device_identity_test: DPAPI/Keystore, never plaintext, no seed logging, seed not in cache/AppSettings/SQLite |
| 4 | Public key derivation deterministic | RUNTIME_PROOF | s6_device_identity_test: seed → deterministic Ed25519/RFC8032 keypair |
| 5 | Identity does not cross device/install boundary | RUNTIME_PROOF | s6_device_identity_test: distinct identities; s8 D1 device-A cache rejected under device-B |
| 6 | Android Keystore / Windows DPAPI canonical | RUNTIME_PROOF | s6_device_identity_test: Android→Keystore channel; Windows→DPAPI CurrentUser; secure_store_abstraction_test |
| 7 | Hardware fingerprint NOT used as private signing authority | STATIC_PROOF | device_identity_provider_test: fingerprint is COMPATIBILITY_BRIDGE metadata only (S9 gov H-matrix); cryptographic possession is S6DeviceIdentity |

#### B. Device Proof-of-Possession

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 8 | Canonical S6 envelope deterministic | RUNTIME_PROOF | s6_proof_of_possession_test: Scenario 26 byte-identical; order/whitespace independent |
| 9 | Valid Ed25519 PoP succeeds | RUNTIME_PROOF | s6_proof_of_possession_test: Scenario 27–28 frozen pubkey/signature |
| 10 | Wrong public key fails | RUNTIME_PROOF | s6_proof_of_possession_test: valid signature under another key fails |
| 11 | Wrong signature fails | RUNTIME_PROOF | s6_proof_of_possession_test: mutating field invalidates signature |
| 12 | Malformed signature fails | RUNTIME_PROOF | s6_proof_of_possession_test: padding/foreign alphabet/wrong length rejected |
| 13 | Tampered envelope fails | RUNTIME_PROOF | s6_proof_of_possession_test: mutation fails; wrong device/shop/user/challenge body |
| 14 | Replay/challenge misuse fails per server contract | RUNTIME_PROOF + SERVER_PROOF | s6_proof_of_possession_test: consumed marker → cannot assert twice, envelope expiry; server s6-device-pop (SERVER_PROOF, infra-blocked locally) |

#### C. Device Trust / Invitation

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 15 | Invitation acceptance tenant-bound | SERVER_PROOF + RUNTIME_PROOF | s4_device_trust test.sql (SERVER_PROOF); invitation_acceptance_test (acceptance flow) |
| 16 | Invitation token/hash semantics fail-closed (expiry, single-use, binding) | SERVER_PROOF | s4 test.sql CASES 11–13,17,19 (SERVER_PROOF, infra-blocked); invite-employee Edge Function (SERVER_PROOF) |
| 17 | Device lifecycle state parsing fail-closed (PENDING/ACTIVE/REVOKED/LOST) | RUNTIME_PROOF | s8 D3 terminal cache stays terminal; s5 malformed/security-state fail-closed |
| 18 | Owner-only device management permission enforced | PARTIALLY_COVERED | device_management_screen_test / device_management_repository_test (UI+RPC); server gate CASE 4–6,9 (SERVER_PROOF) — see Gap G-C18 |
| 19 | Terminal device state cannot be silently restored | RUNTIME_PROOF | s8 C6 REVOKED never restored; D3 LOST/REVOKED stays terminal |
| 20 | Raw device identifiers not leaked where governance forbids | STATIC_PROOF + RUNTIME_PROOF | s6 tests never log/print private seed; DPAPI/Keystore abstraction |
| 21 | Cross-shop device mutations fail | RUNTIME_PROOF + SERVER_PROOF | s6 PoP wrong-shop binding; s8 A5 tenant mismatch; server CASE 4/13 |
| 22 | Unauthorized employee cannot manage devices | PARTIALLY_COVERED | server Owner-only gates CASE 4–6 (SERVER_PROOF); client repository tests — see Gap G-C22 |

#### D. Entitlement Authority

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 23 | CloudLicensingService remains canonical runtime authority | STATIC_PROOF | S9 gov P-OD12 proof; main.dart enforces via cloudLicensingService.enforceActive (canonical); no legacy service registered |
| 24 | Revocation overrides stale/cache entitlement | RUNTIME_PROOF | s8 C6, C7, D3; cloud_licensing blocksWrites revoked/suspended |
| 25 | Suspended/expired/no-license do not regain authority | RUNTIME_PROOF | s5 Scenarios 3,4,4b,4c,5,6,7; cloud_licensing tests |
| 26 | Unknown schema fails closed | RUNTIME_PROOF | s8 A7 unknown schema rejected; s5 Scenario 10 malformed security fields |
| 27 | No retired LicensingService runtime authority | RUNTIME_PROOF + STATIC_PROOF | s9 static proofs: licensing_service.dart removed; no executable reachability |
| 28 | No ActivationClient authority | STATIC_PROOF | s9: ActivationClient removed; no symbol reachable in app/lib executable source |
| 29 | No EntitlementVerifier legacy path | STATIC_PROOF | s9: EntitlementVerifier removed; only licensing.dart:14 doc comment reference remains (non-executable) |
| 30 | No EntitlementToken.parseSigned legacy path | STATIC_PROOF | s9: entitlement_token.dart removed; no parseSigned reachable |

#### E. Authenticated Offline Cache

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 31 | Valid S8 signed cache verifies | RUNTIME_PROOF | s8 A2, E4 |
| 32 | Wrong device identity fails | RUNTIME_PROOF | s8 A6, D1 |
| 33 | Wrong user boundary fails | RUNTIME_PROOF | s8 A6/A5 binding; user-bound cache |
| 34 | Wrong shop boundary fails | RUNTIME_PROOF | s8 A5 tenant mismatch |
| 35 | Tampered payload fails | RUNTIME_PROOF | s8 A3, A4 |
| 36 | Malformed signature fails | RUNTIME_PROOF | s8 A9 |
| 37 | Missing signature fails closed | RUNTIME_PROOF | s8 A8 missing integrity metadata fail-closed |
| 38 | Unsupported schema fails closed | RUNTIME_PROOF | s8 A7 |
| 39 | Replay/rollback cache fails | RUNTIME_PROOF | s8 B5, F1, F2 |
| 40 | Cache cannot be treated as fresh server authority | RUNTIME_PROOF | s8 F3 signature≠fresh authority; E3 server failure never fabricates authority |

#### F. Trusted Time / Clock

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 41 | Protected high-water survives reload | RUNTIME_PROOF | s8 B6 restart preserves trusted anti-rollback state |
| 42 | Clock rollback detected | RUNTIME_PROOF | s8 B2, B5, cloud_licensing isWithinGraceWindow false for clock backwards |
| 43 | Stale server authority cannot overwrite trusted future evidence | RUNTIME_PROOF | s8 B10 future-dated/inconsistent metadata fail-closed; E2 stale timestamp fail-closed |
| 44 | Offline grace bounded | RUNTIME_PROOF | s8 C1/C2/C3 etc.; cloud_licensing grace-window tests |
| 45 | Trial grace 0 days | RUNTIME_PROOF | s8 C1; cloud_licensing trial has NO offline grace |
| 46 | Paid grace 7 days | RUNTIME_PROOF | s8 C2/C3; cloud_licensing paid grace 7 days |
| 47 | Perpetual grace 14 days | RUNTIME_PROOF | s8 C4/C5; cloud_licensing perpetual grace 14 days |
| 48 | Wall-clock manipulation does not extend authority | RUNTIME_PROOF | s8 B8/B9 UTC-normalized (TZ/DST); trusted high-water |

#### G. Cross-Layer Security

| # | Requirement | Evidence class | Evidence source |
|---|-------------|----------------|-----------------|
| 49 | Shop tenant boundary end-to-end | RUNTIME_PROOF + SERVER_PROOF | s8 A5; s6 PoP shop binding; tenant_isolation suite; server CASE 4/13 |
| 50 | User/session boundary end-to-end | RUNTIME_PROOF + SERVER_PROOF | s8 user binding; cloud/session_resume_binding_test; server CASE 5 |
| 51 | Canonical S6 identity is the same seam used by S8 binding | RUNTIME_PROOF | s8 D4 valid S6 identity composition supports S8 verification |
| 52 | S9 retirement does not weaken S6 | RUNTIME_PROOF | s9 preservation cases; s6 PoP still verifies |
| 53 | S9 retirement does not weaken S8 | RUNTIME_PROOF | s9 preservation cases; s8 suite 41/41 |
| 54 | No silent fallback canonical → retired legacy authority | RUNTIME_PROOF + STATIC_PROOF | s9 Case 14 no silent fallback; no legacy symbol executable-reachable |
| 55 | No new plaintext private signing material | STATIC_PROOF + RUNTIME_PROOF | secret scan clean; s6 no plaintext seed; s8 F4 private key never serialized in cache |
| 56 | No client-only path manufactures server entitlement | RUNTIME_PROOF + SERVER_PROOF | server-authoritative verify_license_entitlement; s8 E3/F3; s5 server-field fail-closed |

---

## G. Existing Evidence Inventory

Mapping each requirement to existing tests / static / server evidence is captured inline in Section F.2. High-level inventory of the governed convergence test surface (all committed, all passing this session):

```text
app/test/licensing/s9_legacy_ed25519_retirement_test.dart      20 pass   (S9)
app/test/licensing/s8_tamper_cache_clock_test.dart             41 pass   (S8)
app/test/licensing/s6_device_identity_test.dart               (in 75/75)
app/test/licensing/s6_platform_secure_device_identity_test.dart
app/test/licensing/s6_proof_of_possession_test.dart           (in 75/75)
app/test/licensing/s5_client_entitlement_integration_test.dart (in 75/75)
app/test/licensing/cloud_licensing_test.dart                  (licensing 236)
app/test/licensing/device_identity_provider_test.dart         (in 75/75)
app/test/licensing/secure_store_abstraction_test.dart         (licensing 236)
app/test/cloud/invitation_acceptance_test.dart                (in 75/75)
app/test/cloud/device_management_repository_test.dart
app/test/widget/device_management_screen_test.dart
app/test/tenant_isolation/**                                  (tenant boundary)
supabase/tests/s1..s6_*.test.sql                              (SERVER_PROOF, infra-blocked locally)
supabase/functions/s6-device-pop/*, invite-employee/*         (SERVER_PROOF, infra-blocked locally)
```

**Static scans this session (Section 18 gates):**

```text
Retired legacy symbols executable-reachable in app/lib?   NO (only licensing.dart:14 doc comment)
Plaintext private seed / private-key literal?             NO
Embedded service-role / JWT / API secret literal?         NO (service-role is comment/identifier, not a secret value)
BEGIN PRIVATE KEY / eyJhbGci... literals present?         NO
Migration 00036 present?                                 NO (highest = 00035)
```

---

## H. Coverage Gaps (genuine, for future S10 implementation)

Only genuine gaps are listed — no fabricated defects, no conversion of pre-existing failures.

```text
G-C18  Case 18 (Owner-only device management permission enforced): client-side coverage exists
       (device_management_screen_test / repository test) but a discrete end-to-end Owner-authorization
       convergence assertion against the full P-OD13 device-gate contract is not yet a single governed
       convergence case. PARTIALLY_COVERED → a convergence test extension may close this.
G-C22  Case 22 (unauthorized employee cannot manage devices) — equivalent PARTIALLY_COVERED client
       convergence assertion; server RPC blocks Owner-only (SERVER_PROOF) but the combined
       client+server end-to-end case is not yet one governed convergence test.
G-SRV  Server-enforcement threat classes (fully-compromised-client cases) deferred by S8 to S10:
       S8 §H explicitly recorded "SERVER_REQUIRED threat classes (fully-compromised-client cases)
       → S10 server-enforcement". Execution of the committed S1–S6 SQL / Edge Function suites is
       INFRASTRUCTURE_BLOCKED locally (no local Postgres/Supabase stack this session), so final
       server-side proof-of-green is not re-obtainable here. The committed server tests are evidence.
       Any required server-enforcement assertion must be test-only; no server delta is authorized
       (Section L).
```

There are **no** known genuine coverage gaps in the client canonical matrix: every S6 identity, S6 PoP, S8 cache, clock/grace, and revocation row is covered by a passing runtime test (Section F.2). The residual S10 convergence work is: (1) optionally add a dedicated convergence test file that asserts the P-OD13 CASE 1–20 and cross-layer matrix end-to-end; (2) close G-C18/G-C22 with test/fixture additions; (3) record server-suite evidence/eligibility.

---

## I. Failure Classification

Distinctions preserved — never silently converted:

```text
PRE-EXISTING PRODUCT / TOOLING FINDINGS (NOT S10-owned):
  * app/lib/screens/settings/device_management_screen.dart:4:8 — pre-existing unused import
    (../../models/user_role.dart); predates S9/S10; OUT OF SCOPE; MUST NOT be modified by S10.
  * supabase/tests/cloud_stock_adjustments.test.sql — pre-existing SQL defect
    (pg_get_constraintdef(oid) without FROM, lines 39/43), exit=3, predates S7; documented in
    S7 (line 639), S8 (line 543), S9 (line 592) governance; MUST NOT be rewritten by S10.
  * local pgTAP / server-suite execution unavailable (no local stack) → INFRASTRUCTURE_BLOCKED.

S10-OWNED FAILURES: none currently. Governance identifies only coverage gaps (Section H) to be
  closed by future S10 implementation tests — no runtime product defect is S10-owned today.
```

The governance artifact explicitly distinguishes pre-existing failure / S10-owned failure / infrastructure-tooling failure. No category is silently converted.

---

## J. Future S10 Implementation Scope (exact file allowlist)

Determined after forensic discovery. S10 is a **test + evidence convergence** slice. **Preferred outcome: test-only / evidence-only files.** No production Dart file and no server file enters the allowlist unless committed evidence proves a real uncovered defect requiring a production correction — none such was proven this session.

### J.1 Allowed future implementation paths

```text
PATH:  app/test/licensing/s10_group_b_test_security_convergence_test.dart   (NEW)
WHY:   S8/S9/S6/S7 governance repeatedly assign "final CASE 1–20 test matrix" and "full
       security-matrix convergence" to S10. A dedicated convergence suite asserting the P-OD13
       1–20 matrix and the cross-layer A–G matrix is the natural, named S10 deliverable. Follows the
       repo convention app/test/licensing/sN_<descriptor>_test.dart (mirrors s8_/s9_ naming).
EXPECTED CHANGE TYPE: NEW Dart test file (Dart test only; no production import beyond canonical symbols).
SECURITY REQUIREMENT(S): assert every row of F.2 that can be asserted deterministically at runtime;
       assert no legacy symbol reachable; assert tenant/user/device/clock/grace/revocation fail-closed
       behaviors; keep all existing floor suites green.
WHY NO OTHER FILE IS NEEDED: a single convergence test file can reference existing canonical
       services/S6/S8 fixtures; fixtures are already present (test helpers). No production change.

PATH:  app/test/licensing/s10_group_b_test_security_convergence_test.dart (shared) or
       app/test/cloud/s10_<...>_test.dart — OR explicitly extending the existing
       device_management / invitation acceptance test files (G-C18/G-C22).
WHY:   close the two PARTIALLY_COVERED Owner-authorization rows with client+server-contract
       convergence assertions.
EXPECTED CHANGE TYPE: test-only additions/extensions (deterministic fixtures via existing test helpers).
SECURITY REQUIREMENT(S): Owner-only device management; unauthorized-employee denial; cross-shop denial.
WHY NO OTHER FILE: server enforcement already committed; these are evidence/convergence tests only.

PATH:  (optional, test-only) deterministic fixture file under app/test/helpers if the convergence
       suite needs a shared canonical payload; otherwise reuse test_schema.dart / existing fixtures.
WHY:   reproducibility without touching production.
EXPECTED CHANGE TYPE: test-only utility/fixture.
SECURITY REQUIREMENT(S): no private seed / secret material in fixtures; fail-closed expected values.
WHY NO OTHER FILE: fixture is optional; avoid unless genuinely required.
```

### J.2 Explicitly NOT allowed as future implementation scope

Any production Dart file in Section K, and any supabase/server file, unless a future governance session provides direct evidence of a real defect and an explicit exception. None exists today.

---

## K. Explicit Forbidden Scope (exact no-touch list)

```text
app/lib/licensing/s6_device_identity.dart
app/lib/licensing/s6_proof_of_possession.dart
app/lib/licensing/s8_cache_integrity.dart
app/lib/licensing/cloud_licensing_service.dart
app/lib/licensing/cloud_licensing_repository.dart
app/lib/licensing/entitlement_cache.dart
app/lib/licensing/offline_grace_policy.dart
app/lib/platform/device_identity_provider.dart
app/lib/screens/settings/license_status_screen.dart
supabase/**   (migrations, tests, functions, RLS, RPCs, Auth, Edge Functions, schema)
```

Also forbidden for S10:

```text
S9-deleted files (entitlement_token.dart, licensing_service.dart)   — MUST NOT be restored
New legacy verifier / EntitlementToken / EntitlementVerifier path   — FORBIDDEN
Any migration, including 00036                                      — FORBIDDEN
Server redesign / RLS redesign / Auth change / Edge Function change — FORBIDDEN
Sync drain activation / any production activation                  — FORBIDDEN
Group C / Group D                                                   — FORBIDDEN
S11 / S12                                                           — FORBIDDEN
```

If any such file truly must change, governance must provide direct evidence and an explicit exception. None does today.

---

## L. Server Delta Decision

Based on committed evidence, S10 is a test + evidence convergence slice. No committed authority proves a required server schema/RPC/Edge/RLS change for S10.

```text
S10_SERVER_SCHEMA_RPC_DELTA = NONE
S10_MIGRATION_REQUIRED      = NO
S10_SERVER_ENFORCEMENT      = verify-and-record-only (execution INFRASTRUCTURE_BLOCKED locally;
                              committed S1–S6 suites are the evidence; no server delta authored)
```

Any future S10 server assertion must remain test-only against the already-committed server surface. No server delta is authorized.

---

## M. Migration Decision

```text
MIGRATION_00036_CREATED = NO
HIGHEST_COMMITTED_MIGRATION = 20260820000035_phase_p_group_b_s6_platform_secure_device_identity.sql
```

Future S10 implementation must create **no** migration. All S10 work is test/evidence-only on the committed server surface. Any future implementation that believes a server delta is required MUST STOP and return to governance with direct evidence; it must not invent migration `00036`.

---

## N. Legacy Retirement Preservation (S9 must remain irreversible)

```text
LEGACY_ENTITLEMENT_ED25519_AUTHORITY_REINTRODUCTION = FORBIDDEN
S9_LEGACY_AUTHORITY_REINTRODUCED                   = NO
S6_POP_CHANGED                                     = NO
S6_DEVICE_IDENTITY_CHANGED                         = NO
S8_CACHE_INTEGRITY_CHANGED                         = NO
CLOUD_LICENSING_CHANGED                            = NO
```

Static scan this session proves no executable reachability of `EntitlementVerifier`, `EntitlementToken`, `TokenVerificationResult`, `TrustedKey`, `parseSigned`, `ActivationClient`, `LicensingSnapshot`, or standalone `LicensingService` in `app/lib`. The only residual textual match (`licensing.dart:14`) is a documentation comment, not executable reachability. `CloudLicensingService` is canonical and must never be mistaken for the retired standalone `LicensingService`.

---

## O. Security Invariants (S6 / S8 / user / shop / clock / replay / revocation / grace)

```text
I1  Canonical S6 per-install identity is stable, deterministic, never crosses device/install boundary.
I2  S6 private seed is generated once, protected by Keystore/DPAPI, never plaintext/seed-logged.
I3  S6 proof-of-possession is deterministic and server-authoritative; wrong key/signature/envelope fails.
I4  Verification fails closed: unknown/malformed/unsigned input never grants.
I5  Tenant (shop) and user/session boundaries are preserved end-to-end.
I6  S8 authenticated cache is device/user/shop-bound; anti-replay/high-water preserved.
I7  Trusted-server-time high-water survives reload; clock rollback fails closed.
I8  Offline grace is bounded; trial 0d, paid 7d, perpetual 14d; wall-clock cannot extend.
I9  Revocation (license/membership/device) always overrides stale/cache/offline authority; terminal states
    (REVOKED/LOST/EXPIRED) are never silently restored.
I10 After S9, legacy acceptance is NOT silently reachable; no silent fallback canonical→legacy.
I11 No client-only path can manufacture server entitlement; server is the authority.
```

Fail-closed rules (mandatory, frozen):

```text
malformed input → reject; unknown schema → reject; unknown device state → reject;
invalid signature → reject; missing signature → reject; wrong user → reject;
wrong shop → reject; wrong device → reject; stale authority → reject;
revoked entitlement → reject; rollback/replay → reject;
unavailable authoritative proof → restricted / fail-closed per existing contract;
NO legacy fallback.
```

No security-negative may become permissive for UX reasons.

---

## P. Future Test Contract (exact commands + floors)

### P.1 S10 Targeted Test

```text
EXACT FILENAME (final) = app/test/licensing/s10_group_b_test_security_convergence_test.dart
```

If future S10 implementation adds a convergence suite, it must assert the P-OD13 CASE 1–20 and the cross-layer F.2 matrix deterministically.

### P.2 Mandatory regression floors (must not be reduced)

```text
S9 targeted                >= 20/20
S8 floor                   >= 41/41
licensing suite            >= 236      (flutter test test/licensing)
full Dart                  >= 1724     (flutter test)
selected invitation/device trust regression >= 75/75
```

Plus any server regression floors discovered from S1–S6 (execution infrastructure-blocked locally; committed suites retained as evidence).

### P.3 Exact baseline commands (governance re-verified this session, evidence only)

```text
cd app
flutter analyze
flutter test test/licensing/s9_legacy_ed25519_retirement_test.dart
flutter test test/licensing/s8_tamper_cache_clock_test.dart
flutter test test/licensing
flutter test
flutter test test/licensing/s6_device_identity_test.dart
         test/licensing/s6_proof_of_possession_test.dart
         test/licensing/s5_client_entitlement_integration_test.dart
         test/licensing/device_identity_provider_test.dart
         test/cloud/invitation_acceptance_test.dart
```

Future S10 implementation must keep these green; do not reduce a floor merely to go green.

---

## Q. Analyzer Contract

```text
NEW ISSUES FROM S10 = FORBIDDEN
CURRENT ANALYZER    = 0 errors; 1 warning (pre-existing, out of scope); 66 info-level lint hints (pre-existing)
PRE-EXISTING WARNING= app/lib/screens/settings/device_management_screen.dart:4:8
                       unused import '../../models/user_role.dart'  → predates S9/S10, OUT OF SCOPE
```

Future S10 implementation may add only `info`-level hints attributable to its own new test file (and should prefer none). It MUST NOT introduce errors or new warnings, and MUST NOT "fix" the pre-existing warning as part of S10.

---

## R. Secrets / Cryptographic Material

```text
No private seed / private key / JWT / API secret / service-role secret is committed in source or tests.
Static scan this session: BEGIN PRIVATE KEY literals = none; eyJhbGci... JWT literals = none;
plaintext S6 seed = none; service-role appears only as comments/identifiers, not a secret value.
```

Future S10 implementation (tests/fixtures) must likewise contain no plaintext private seed or secret material.

---

## S. Implementation Entry Gate

Future S10 implementation MUST begin from the S10 governance commit **REMOTE_LOCKED** (this artifact), with a clear tracked worktree, and requires a **separate explicit Owner authorization** to implement. Governance readiness is NOT implementation authorization.

---

## T. Implementation Stop Rule

```text
S10_IMPLEMENTATION_STARTED = NO
S11_STARTED                = NO
S12_STARTED                = NO
GROUP_C_STARTED            = NO
GROUP_D_STARTED            = NO
SYNC_DRAIN_CHANGED         = NO
PRODUCTION_MUTATED         = NO
MIGRATION_00036_CREATED    = NO
LEGACY_ORIGIN_CONTACTED    = NO
FORCE_PUSH_USED            = NO
RESET_REBASE_AMEND_USED    = NO
```

---

## U. Final Governance Decision

```text
S10_IMPLEMENTATION_GOVERNANCE_READY
```

Evidence:
- Entry forensically `CASE_A_FRESH`; local = tracking = direct GitHub remote = `27946b4...`; AHEAD=0 / BEHIND=0.
- Full predecessor chain S8→S9 verified; S9 remote-locked and immutable.
- Committed S10 authority discovered: Group B Test / Security Convergence (P-OD13 CASE 1–20 matrix, RLS, quota, offline, revocation, tamper, cross-tenant, Android/Windows identity, reconnect); dependencies = all prior.
- Baseline validation re-run this session (evidence only; no code changed): analyzer 0 errors, S9 20/20, S8 41/41, licensing 236, full Dart 1724, selected regression 75/75.
- Cross-layer security matrix (56 rows) classified; genuine coverage gaps (G-C18, G-C22, G-SRV) identified as future test-only scope.
- Server delta frozen NONE; migration 00036 NOT created; S9 legacy retirement irreversibly preserved.
- Future implementation allowlist is test/evidence-only.

---

*This document is governance only. It authorizes no implementation. S10 implementation requires a separate explicit Owner instruction after this artifact is remote-locked, per Section S / T.*
