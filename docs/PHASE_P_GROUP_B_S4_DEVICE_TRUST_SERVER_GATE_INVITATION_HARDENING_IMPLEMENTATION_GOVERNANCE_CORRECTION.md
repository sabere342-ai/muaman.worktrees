# PHASE P — GROUP B S4 DEVICE-TRUST SERVER GATE + INVITATION HARDENING — GOVERNANCE CORRECTION

```text
SESSION =
PHASE_P_GROUP_B_S4_DEVICE_TRUST_INVITATION_GOVERNANCE_FORENSIC_CORRECTION_REMOTE_LOCK

MODE =
SINGLE_ADDITIVE_GOVERNANCE_CORRECTION_ONLY_FAIL_CLOSED

IMPLEMENT_S4           = FALSE
CREATE_MIGRATION_00034 = FALSE
CREATE_S4_TEST         = FALSE
CHANGE_PRODUCTION_CODE = FALSE
DEPLOY                  = FALSE
PRODUCTION_MUTATION     = FALSE
START_S5_S6_S7_S8      = FALSE
START_GROUP_C           = FALSE
START_GROUP_D           = FALSE
```

THIS DOCUMENT IS AN ADDITIVE GOVERNANCE CORRECTION TO THE REMOTE-LOCKED
ORIGINAL S4 GOVERNANCE COMMIT `2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5`
(`docs/PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE.md`).

IT CORRECTS ONLY THE CONFLICTING / AMBIGUOUS PORTIONS IDENTIFIED BELOW.
ALL UNCONTESTED AUTHORITY IN `2df4dc7...` REMAINS INHERITED UNCHANGED.

THIS CORRECTION DOES NOT IMPLEMENT S4. IT DOES NOT CREATE MIGRATION `00034`,
DOES NOT CREATE AN S4 pgTAP FILE, DOES NOT EDIT ANY EDGE FUNCTION, DOES NOT
TOUCH `app/lib/**`, SUPABASE PRODUCTION, S1, S2, S3, OR THE ORIGINAL S4
GOVERNANCE FILE.

---

## A. Session Identity

```text
SESSION                = PHASE_P_GROUP_B_S4_DEVICE_TRUST_INVITATION_GOVERNANCE_FORENSIC_CORRECTION_REMOTE_LOCK
MODE                   = SINGLE_ADDITIVE_GOVERNANCE_CORRECTION_ONLY_FAIL_CLOSED
TARGET_UNIT            = Additive correction to committed S4 device-trust + invitation-hardening governance (2df4dc7)
IMPLEMENT_S4           = FALSE
AUTHORIZED_OUTPUT      = ONE ADDITIVE GOVERNANCE CORRECTION ARTIFACT ONLY
EXPECTED_SUCCESS_TOKEN = PASS_PHASE_P_GROUP_B_S4_DEVICE_TRUST_INVITATION_GOVERNANCE_FORENSIC_CORRECTION_REMOTE_LOCKED
```

---

## B. Repository Identity

```text
ROOT              = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
FETCH_URL         = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_URL          = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN     = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن   (SACRED READ-ONLY; never contacted)
```

`origin` is sacred read-only legacy material. This session never fetched from,
pushed to, modified, deleted, renamed, reconfigured, or used `origin` as
recovery. Only the authorized remote `github` was contacted (read-only
`git ls-remote` / `git fetch github`, plus a normal fast-forward push only).

Identity proven before any write:

```text
git rev-parse --show-toplevel = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
git branch --show-current     = codex/i-tech-next-roadmap-freeze
git remote -v                 = github -> https://github.com/sabere342-ai/muaman.worktrees.git (fetch+push)
                                origin -> <legacy OneDrive path> (sacred, untouched)
```

Result: **REPOSITORY_IDENTITY_VERIFIED = TRUE**.
**LEGACY_ORIGIN_CONTACTED = NO.** **LEGACY_ORIGIN_MUTATED = NO.**

---

## C. Entry / Recovery Classification

```text
ENTRY_LOCAL_HEAD           = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5
ENTRY_REMOTE_TRACKING_HEAD = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5
ENTRY_DIRECT_REMOTE_HEAD   = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5   (git ls-remote github)
ENTRY_MERGE_BASE           = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5
AHEAD                      = 0
BEHIND                     = 0

TRACKED_WORKTREE = CLEAN (git diff --exit-code = no output; only pre-existing
                          untracked sacred evidence remains)
INDEX            = EMPTY  (git diff --cached --exit-code = no output)
ACTIVE_GIT_OPERATION = NONE (no MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD /
                             rebase-merge / rebase-apply / BISECT_LOG)
STASH_STATUS     = unrelated WIP on codex/muaman-13-strict-july-workbook-data-migration (left untouched)
```

```text
RECOVERY_CLASSIFICATION = CASE_A_FRESH   (local == tracking == direct remote == 2df4dc7...; AHEAD=0 BEHIND=0)
```

Pre-existing untracked sacred evidence preserved and not staged/modified:
`supabase/.temp/`, `supabase/.branches/`, the untracked Group A Phase Q/OD7
reports, `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md`,
`delivery/I-TECH-Delivery-v1.0.0.zip`, and related untracked forensic material.
No `git clean`, no reset, no stash mutation.

---

## D. Authority Provenance

The committed Group B authority chain was re-verified directly from Git objects
during this session (`git ls-tree <commit> <path>`) and confirmed present,
unchanged, and ancestor of current `HEAD`:

| Token | Commit | Path | Expected Blob | Actual Blob | Result |
|---|---|---|---|---|---|
| Owner Order | `221bf7f96f1e7b301c68d1ffd79a8a8bac9f43a4` | `docs/OWNER_ORDER_DECISION_GROUP_B_BEFORE_GROUP_D_AFTER_ANDROID_AAB_SUPERSESSION_AND_PLAY_DEFERRAL.md` | `37518ed12f0402e059e099be8104b21b2d07c64f` | `37518ed12f0402e059e099be8104b21b2d07c64f` | PASS |
| Authority-Binding Correction | `8fc4be8ea06fcff5400b79dbebb373c038738ecf` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_AUTHORITY_BINDING_CORRECTION.md` | `57e0f9c393ea9ef3484a5312612f7703509747af` | `57e0f9c393ea9ef3484a5312612f7703509747af` | PASS |
| Post-M30 Exact Binding | `1a4907bc57c00126f131b458a356749abbc4421b` | `docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_POST_MIGRATION_30_EXACT_COMMIT_BINDING_CORRECTION.md` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | `2925ef5cf78ed18975a7fa6be2710c6103a01649` | PASS |
| Group B Master Plan | `9ecdc38282cdb7ca6f088263f9e152f920b7a823` | `PHASE_P_OWNER_GATED_GROUP_B_PLAN.md` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | `6bb57e90f3704a9cdee691b19c45c8107b6207af` | PASS |
| P-OD13 Authority | `8d27878a69cbb6c6f440c28f4f55f3ed323312d4` | `POST_PHASE_P_OWNER_EMPLOYEE_DEVICE_TRUST_AND_FINAL_DELIVERY_GOVERNANCE_DETERMINATION.md` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | `e0016e78397e6251c2d446cd6aee2e8b5fbc8e0a` | PASS |

S1/S2/S3 implementation lineage and blob immutability re-verified at `HEAD`:

```text
S1_MIGRATION (20260820000031) blob @ 334d1ad == @ HEAD = 2ab6436673ecf1ac6e9c39e7fb11403f245dfc2b  (IMMUTABLE)
S2_MIGRATION (20260820000032) blob @ 85e4315  == @ HEAD = 5451fa269870bc98f33aae21ceeb9e74b8db12b8  (IMMUTABLE)
S3_MIGRATION (20260820000033) blob @ 62af446  == @ HEAD = b60487110f9ddd9ade0d6cfde65b0e0b64218bbd  (IMMUTABLE)
```

```text
RESULT = AUTHORITY_CHAIN_VERIFIED
```

The current S4 governance commit `2df4dc7...` binds this document (Section E).

---

## E. Binding to 2df4dc7 (Original S4 Governance)

The original remote-locked S4 governance commit is:

```text
S4_GOVERNANCE_COMMIT = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5
EXPECTED_PARENT      = 62af44695e664722d1ccabf5816f55678d1e049a   (S3 impl)
COMMIT_MESSAGE       = docs: govern Group B S4 device trust and invitation hardening
GOVERNANCE_FILE      = docs/PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE.md
GOVERNANCE_BLOB      = c6175e3c9df48322334eca6f3f46c8cbfdab97e8   (blob equal at 2df4dc7 and @ HEAD)

COMMIT DELTA             = ONE added governance file only (A <path>)
LOCAL_HEAD == TRACKING == DIRECT_REMOTE == MERGE_BASE == 2df4dc7...   (verified)
AHEAD = 0, BEHIND = 0                                                   (verified)
```

This correction document (a new, distinct file) supersedes ONLY the
conflicting/ambiguous portions documented in Sections F..M below. Every
uncontested authority in `2df4dc7...` (state machine, owner authority,
advisory-lock contract, S2 quota composition, S3 revocation composition,
forbidden scope, dependency structure, implementation-boundary S4/S5/S6/S7/S8)
is inherited unchanged.

---

## F. Material Problems Found (in committed S4 governance 2df4dc7)

### F.1 Request-bound device identity is not explicit (CORRECTION 1)

The original governance defines `s4_device_is_approved(p_shop_id, p_device_id)`
and, at J.3, leaves "device identity resolved from the served device act as
established by S6's future proof-of-possession binding." That defers the
current-request device identity to S6.

**Material problem:** an authenticated `auth.uid()` may own/use multiple device
rows. P-OD13 requires that "there exists some ACTIVE device belonging to this
user" MUST NEVER be treated as proof that the CURRENT request originated from
that device. Under the original wording, the RLS/read gate and
`require_shop_permission` gate could accept ANY approved device of the caller,
not the device actually serving the request — which fails P-OD13 CASES 2/3/5/19
(stolen creds from another phone; direct API without device proof; modified
client).

### F.2 S4/S6 sequencing can brick existing clients (CORRECTION 2)

S4 precedes S6. S6 owns the per-install keypair, Android Keystore, Windows
DPAPI, and client proof-of-possession implementation. The original governance
(J.4) describes activating a mandatory approved-device gate in the RLS/read
path and `require_shop_permission` while the existing client cannot yet supply
request-bound proof. Activating mandatory enforcement now would silently deny
every existing legitimate client.

### F.3 Cryptographic verification capability was not proven (CORRECTION 3)

The original governance (J.5) says "S4's server simply stores the public key
and verifies the proof using the platform cryptographic validation available
server-side" — ambiguous about WHERE Ed25519 verification happens. PostgreSQL's
available SQL crypto surface does NOT verify Ed25519 (Section I).

### F.4 RLS change set was left open-ended (CORRECTION 4)

The original governance (J.4) explicitly says the "EXACT list [is] to be
finalized by the S4 implementation after enumerating every RLS policy." A strict
implementation allowlist must be locked during THIS governance session, not
deferred (no "any relevant business table", no "exact list later", no
"implementation may decide").

### F.5 Invitation token flow is not end-to-end viable as committed (CORRECTION 5)

The original governance (J.10) DEFERS the `invite-employee` Edge Function while
enabling a corrected `accept_invitation` that requires a token. Current truth:
the Edge Function creates invitations WITHOUT populating `token_hash` and uses
`email_confirm:true` + an undelivered temporary password. Enabling a mandatory
token verifier while deferring the token issuer means `token_hash = NULL` for
every new Owner-created invitation → every legitimate new acceptance fails
closed. A mandatory verifier must not be activated before a precise successor
owns and activates issuance.

### F.6 S3 test count was misstated (CORRECTION 6)

The original governance (K.3) records `S3_PG_TAP = committed 22 planned /
actual >`. The real committed test `plan(25)` with 22 governed scenarios and 25
actual assertions that reconcile to the plan.

### F.7 S4 test plan had no single exact total (CORRECTION 7)

The original governance (K.2) uses `>=` minimums and says "PLUS migration/base
assertions ... reconcile the exact running total later." The S4 test contract
must have ONE exact integer for `SELECT plan(N)`.

### F.8 Future implementation allowlist required revision (CORRECTION 8)

The original governance (I.3) restrictively excludes the Edge Function. Per the
Corrected Invitation contract (Section L), a viable end-to-end token flow
requires changing `supabase/functions/invite-employee/index.ts`, so the allowlist
must include it.

---

## G. Corrected Device Request-Binding Contract (supersedes original J.3/J.5 binding wording)

```text
CURRENT_REQUEST_DEVICE_IDENTITY
must be cryptographically/session-bound to the ACTUAL request.

AUTH_UID + SHOP_ID + existence of any approved device
is NOT sufficient for business-data access.
```

The authenticate caller's authenticated identity (`auth.uid()`) determines WHICH
device rows are candidates. But proof that THE CURRENT REQUEST CAME FROM a given
approved device requires a server-side binding to the request:

```text
PERMITTED MECHANISMS (master plan §11.4 — server-authoritative):
  A. Edge Function exchange that cryptographically binds the request to the
     served device (server verifies a proof or signed assertion), OR
  B. signed/session-bound assertion established server-side for the request.

FORBIDDEN:
  - gating based only on auth.uid()
  - gating based only on installation_id sent by the client
  - gating based on "any ACTIVE device for this user"
  - a client-attested flag
  - silently denying all existing legitimate clients
```

The corrected predicate shape:

```text
s4_current_request_device_is_approved(p_shop_id UUID) RETURNS BOOLEAN  (SECURITY DEFINER)
  TRUE iff, for the CURRENT serialized request, the server has established a
  request-bound assertion that a single specific device row
  (devices.id, devices.shop_id, status='ACTIVE') is the device serving the
  request for auth.uid() in p_shop_id.

  It MUST NOT be satisfied merely by "some ACTIVE device exists for auth.uid()
  in p_shop_id."
```

`require_shop_permission` and any S4-gated RLS read predicate MUST gate on
`CURRENT_REQUEST_DEVICE_IDENTITY` (request-bound), never on the existence of any
approved device. Because the request-bound seam is not live until S6 (and the
Edge Function proof seam, Section I), enforcement activation is handled in
Section H.

---

## H. Corrected S4/S6 Activation Boundary (supersedes original J.4 enforcement wording)

### H.1 Decision: dormant server primitives + S6-coordinated enforcement activation

```text
CORRECTED_OPTION = A/C (as allowed by the session contract)

S4 creates the server primitives and DORMANT / NON-ENFORCING approved-device
binding. Mandatory enforcement activation is EXPLICITLY DEFERRED until S6 supplies
request-bound proof (the client cannot yet produce it, so activating now would
brick every existing legitimate client — FORBIDDEN).

ENFORCEMENT_ACTIVATION_OWNER = S6-coordinated boundary (or a future slice that
supplies request-bound proof). At that point the dormant predicate becomes
enforcing and the read/RLS + require_shop_permission gates turn on in a single,
governed, non-regressing change.
```

### H.2 What S4 ships (dormant, fail-closed toward non-disruption now)

```text
- s4_current_request_device_is_approved (Section G) — created, but NOT yet
  wired to deny. It registers the canonical server predicate seam.
- s4 approve / reject / lost owner transitions and s4_list_devices — created.
- Challenge / proof-of-possession server contract — created (records, expiry,
  single-use, binding) but verification is NOT wired into any live request path.
- Corrected accept_invitation + token issuance/consumption — created (Section L).
- Additive RLS USING conditions on the exact business-data read policies
  (Section J) — created with a DORMANT flag (e.g. a GUC/switch or an
  enforcement table row defaulting to OFF), NOT actively denying existing
  clients.
```

### H.3 Truthful status claims

```text
S4 CLAIMS:
  - server approved-device model + lifecycle transitions (composed with S3)
  - server invite/token hardening + corrected accept_invitation (Section L)
  - server proof-of-possession contract (records + challenge lifecycle)
  - exact dormant RLS change set (Section J) and non-change set (Section K)

S4 DOES NOT CLAIM (until request-bound enforcement is live under H.1):
  - full CASE 2/3/5/19 enforcement while enforcement is dormant (deny not active)
```

This correction supersedes the original claim that S4 fully covers CASE 2/3/5/19
as an implemented deny. Until enforcement activation, P-OD13 CASE 2/3/5/19 are
classified `ENFORCEMENT_PENDING_S6_ACTIVATION` (server primitives present,
deny dormant), NOT `COVERED_BY_S4` as an active deny. The original CASE mapping
is corrected accordingly:

```text
CORRECTED CASE OWNERSHIP (enforcement slice):
  CASE 2  new unapproved device denied            -> ENFORCEMENT_PENDING (S4 dormant primitives)
  CASE 3  stolen creds from another device        -> ENFORCEMENT_PENDING (S4 dormant primitives)
  CASE 5  direct API without device proof         -> ENFORCEMENT_PENDING (S4 dormant primitives)
  CASE 19 modified client / direct RLS            -> ENFORCEMENT_PENDING (S4 dormant primitives)
  (CASE 1, 4, 6, 7, 9, 11, 12, 13, 17 remain as governed by 2df4dc7 with the
   corrected invitation/request-bound semantics of this document.)
```

---

## I. Proven Cryptographic Verification Location (supersedes original J.5 verification wording)

### I.1 Evidence from the repository

```text
- PostgreSQL major_version = 15 (supabase/config.toml:20).
- No migration executes CREATE EXTENSION for pgcrypto, pgsodium, or any
  cryptographic extension (grep across supabase/migrations/202608200000*.sql
  found ZERO CREATE EXTENSION; only builtin gen_random_uuid() UUID defaults).
- config.toml sets extra_search_path = ["public", "extensions"] (the extensions
  schema is on the search path) but no extension is explicitly enabled in the
  committed migrations.
- PostgreSQL 15 core + pgcrypto do NOT expose an Ed25519 signature-verification
  function. pgcrypto provides digest/HMAC/crypt, not Ed25519 verify.
- The Edge Function runtime is Deno; supabase/functions/invite-employee/index.ts
  already calls WebCrypto `crypto.randomUUID()`, proving the runtime exposes the
  WebCrypto API (crypto.subtle) where modern Deno supports
  crypto.subtle.verify("Ed25519", ...).
```

### I.2 Recorded verdict

```text
ED25519_SERVER_VERIFY_LOCATION = Deno Edge Function runtime (WebCrypto / crypto.subtle)
VERIFICATION_PRIMITIVE         = WebCrypto Ed25519 signature verification (subtle.verify)
EDGE_FUNCTION_REQUIRED         = YES (with evidence: no PostgreSQL SQL primitive for
                                 Ed25519 verify exists in the committed repo; DB layer
                                 stores keys + assertion/challenge records only)

POSTGRESQL_SQL_ED25519_VERIFY  = NOT AVAILABLE (do NOT invent unsupported SQL)
```

### I.3 Correction to verification placement

```text
- The S4 migration stores the device PUBLIC KEY and the challenge/assertion
  records ONLY. It must NOT attempt Ed25519 verification inside SQL.
- ED25519 verification must occur in the authorized server seam permitted by the
  master plan (§11.4 "Edge Function exchange or signed/session-bound assertion"):
  a Deno Edge Function using WebCrypto crypto.subtle.verify("Ed25519", ...)
  against the stored public key, OR over a signed/session-bound assertion.
- If and when the Edge Function proof seam is required for enforcement activation
  (Section H), the Edge Function is the verification seam and must be included in
  the allowlist (Section M).
```

---

## J. Exact RLS Change Set (supersedes original J.4 "finalize later")

This session performed read-only enumeration of every RLS policy over Shop
business-data reads (migrations `00010`, `00021`, `00024`, `00025`, `00026`,
`00027`, `00029`, `00030`, `00031`) and locks the finite allowlist below.

Notation: "S4 CHANGE REQUIRED?" refers to whether the policy's READ surface will
receive the additive approved-device predicate (dormant, per Section H).
`USING` authority shown as current; `WITH CHECK` = not applicable for SELECT-only
policies (client DML is service-role only, no client policies exist on these
tables).

### J.1 Business-data read policies — S4 CHANGE = YES (additive approved-device predicate)

| TABLE | EXISTING POLICY NAME | OPERATION | CURRENT USING AUTHORITY | S4 CHANGE REQUIRED? | EXACT REASON | NEW/REPLACED POLICY NAME | RECURSION RISK |
|---|---|---|---|---|---|---|---|
| cloud_products | shop_isolation_products (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business data (catalog) - endorsed read by P-OD13 | ADD `s4_approved_device` USING OR-preserving base; name `shop_isolation_products_approval` (additive, keep base) | LOW - predicate is SECURITY DEFINER helper, no self-cycle |
| cloud_customers | shop_isolation_customers (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business data (customers) | `shop_isolation_customers_approval` (additive) | LOW |
| cloud_sales | shop_isolation_sales (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business money/sales data (CASE 1/2/3 core) | `shop_isolation_sales_approval` (additive) | LOW |
| cloud_returns | shop_isolation_returns (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business returns (money) | `shop_isolation_returns_approval` (additive) | LOW |
| cloud_expenses | shop_isolation_expenses (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business expenses (money) | `shop_isolation_expenses_approval` (additive) | LOW |
| cloud_expense_categories | shop_isolation_expense_categories (00025) | SELECT | ACTIVE membership EXISTS | YES | Expense category metadata reachable with business data | `shop_isolation_expense_categories_approval` (additive) | LOW |
| cloud_invoices | shop_isolation_invoices (00025) | SELECT | ACTIVE membership EXISTS | YES | Phase G business invoices (money/CASE 1) | `shop_isolation_invoices_approval` (additive) | LOW |
| cloud_inventory_count | shop_isolation_inventory_count (00025) | SELECT | ACTIVE membership EXISTS | YES | Stock/inventory business data | `shop_isolation_inventory_count_approval` (additive) | LOW |
| cloud_shop_settings | shop_isolation_shop_settings (00025) | SELECT | ACTIVE membership EXISTS | YES | Business settings surface | `shop_isolation_shop_settings_approval` (additive) | LOW |
| cloud_stock_adjustments | shop_isolation_stock_adjustments (00030) | SELECT | ACTIVE membership EXISTS | YES | Business stock adjustments (inventory/money) | `shop_isolation_stock_adjustments_approval` (additive) | LOW |
| sync_log | shop_isolation_sync_log (00026) | SELECT | ACTIVE membership EXISTS | YES | sync_log carries business payload summaries | `shop_isolation_sync_log_approval` (additive) | LOW |
| cloud_migration_ledger | shop_isolation_cloud_migration_ledger (00027) | SELECT | ACTIVE membership EXISTS | YES | migration ledger proxies cloud business rows | `shop_isolation_cloud_migration_ledger_approval` (additive) | LOW |
| licenses | shop_licenses_isolation (00010) | SELECT | ACTIVE membership EXISTS | YES | license/activation (business entitlement data) reachable with approval gate | `shop_licenses_isolation_approval` (additive) | LOW |
| activations | shop_activations_isolation (00010) | SELECT | ACTIVE membership EXISTS | YES | activation records (business entitlement) | `shop_activations_isolation_approval` (additive) | LOW |

### J.2 Server authorization helper — S4 CHANGE = YES (DORMANT)

| TABLE | EXISTING POLICY NAME | OPERATION | CURRENT AUTHORITY | S4 CHANGE REQUIRED? | EXACT REASON | NEW/REPLACED | RECURSION RISK |
|---|---|---|---|---|---|---|---|
| require_shop_permission (SECURITY DEFINER helper, not an RLS policy) | N/A | n/a (server RPC authz) | auth.uid() + ACTIVE membership + role/permission + license | YES (DORMANT) | single narrowest server seam to enforce request-bound device approval when activated (Section H) | add `s4_current_request_device_is_approved` gate inside; activated with Section H | LOW - helper runs SECURITY DEFINER, resolves membership/device directly, no policy recursion |

### J.3 Non-business, bootstrap, authz-definition, and registrar surfaces — S4 CHANGE = NO

Per Section K these remain byte/semantically unchanged.

---

## K. Exact RLS Non-Change Set (supersedes original J.4; must stay byte/semantically unchanged)

| TABLE | POLICY | OPERATION | REASON NOT CHANGED |
|---|---|---|---|
| plans | plans_select (00031) | SELECT | global reference metadata with NO shop_id; not tenant business data |
| devices | shop_devices_isolation (00010) | SELECT | the device REGISTRY; the approved-device predicate READS devices via SECURITY DEFINER — gating devices RLS by the predicate would be recursive. Non-change. |
| shops | shop_isolation (00010) | SELECT | tenant bootstrap metadata; gating would block the not-yet-approved bootstrapping owner; no recursion-free need |
| shop_members | shop_member_isolation (00029, via get_user_shop_ids) | SELECT | membership definition (authz bootstrap); predicate resolves membership without gating it |
| roles | shop_roles_isolation (00010) | SELECT | role definition metadata |
| role_permissions_cloud | shop_role_permissions_isolation (00010) | SELECT | permission definition metadata |
| shop_permission_overrides | shop_overrides_isolation (00024) | SELECT | RBAC override definition metadata |
| permission_audit_log | shop_audit_isolation (00024) | SELECT | audit log, not business data |
| device_audit_log | shop_device_audit_isolation (00031) | SELECT | audit log, not business data |
| invitations | shop_owner_invitations_select (00021) | SELECT | owner administrative view; invitation issuance/accept handled by functions (Section L) |

None of the above may be deleted, renamed, or semantically weakened. All 10
`NON_CHANGE_SET` rows must remain identical at implementation.

Tenant-isolation / recursion / search_path guarantees from `2df4dc7` J.4 are
inherited and reinforced: the predicate and `require_shop_permission` are
SECURITY DEFINER helpers that resolve membership + device directly (mirroring
`require_shop_permission` / `check_effective_permission`), never query
`shop_members` through a policy that requires the predicate; every helper sets
`search_path = public`.

---

## L. Invitation Issuance + Acceptance End-to-End Contract (supersedes original J.10)

### L.1 Selected flow: Owner-delivered secure token (SMTP is NOT mandatory)

The narrowest viable, low-dependency flow consistent with master plan §11.3
("SMTP or Owner-delivered secure token") and CASE 20 (no reusable password):

```text
1. ACTIVE Owner invokes invite-employee (Edge Function) for (shop_id, email, role).
2. The Edge Function:
   a. verifies caller is ACTIVE owner of shop (existing check, unchanged).
   b. creates/resolves the auth user (auth.users) - employee establishes own
      credential at acceptance; NO never-sent temporary password is used.
   c. generates ONE cryptographically random plaintext invitation token
      (>=128-bit entropy).
   d. stores ONLY the HASH of the token (invitations.token_hash), bound to
      invitation + shop_id + email + role + status + expiry (S1 columns).
   e. returns the PLAINTEXT token EXACTLY ONCE to the authorized Owner
      (response); the plaintext is never stored server-side.
3. Owner securely delivers the token to the intended employee (out-of-band;
   SMTP optional, not required; no temp password).
4. Employee authenticates/establishes own credential (no reliance on an
   undelivered temp password; CASE 20).
5. Employee calls corrected accept_invitation with: auth.uid() (authenticated
   caller), shop_id, role, email, and the plaintext token.
6. accept_invitation:
   a. derives accepted user from auth.uid() - NEVER a client-supplied p_user_id.
   b. hashes the supplied token; compares against invitations.token_hash.
   c. validates shop_id/email/role/expiry/status (PENDING; not ACCEPTED/EXPIRED/REVOKED).
   d. single-use: on success consumes the token (status->ACCEPTED,
      accepted_at/accepted_by set); replay rejected.
   e. sets shop_members.status='ACTIVE' + joined_at for auth.uid().
   f. fails closed on ANY mismatch.
   g. serializes under the shop-keyed advisory lock
      pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0)).
```

### L.2 Issuance is not deferred past enforcement

```text
ISSUER_PRECEDES_OR_IS_ATOMIC_WITH_VERIFIER_ACTIVATION = TRUE
The corrected accept_invitation (token verifier) is NOT activated as a mandatory
deny for the modern Owner-issued flow until the invite-employee Edge Function
issuance (L.1) is live. Ordering for the S4 implementation:
  1. implement Edge Function issuance (L.1) first (or same slice),
  2. then implement corrected accept_invitation (L.2) consuming it.
The allowlist MUST therefore include supabase/functions/invite-employee/index.ts
(Section M).
```

### L.3 Legacy / transitional behavior

For any invitation row created BEFORE issuance is deployed (token_hash = NULL),
the corrected accept_invitation fails closed (no token -> no acceptance). The
S4 implementation must reset/reissue such rows to a valid token via the Owner
issuance path, or leave them expired, as a governed cleanup — it must NOT silently
accept a NULL-token invitation. This keeps the flow end-to-end viable without an
unsafe default.

---

## M. Exact Future Implementation Allowlist (supersedes original I.3)

After resolving the above, the future S4 implementation MAY write ONLY these
files (a finite, locked allowlist):

```text
supabase/migrations/20260820000034_phase_p_group_b_s4_device_trust_server_gate_invitation_hardening.sql
supabase/tests/s4_device_trust_server_gate_invitation_hardening.test.sql
supabase/functions/invite-employee/index.ts        (REQUIRED by Corrected Invitation flow, Section L)
```

All three are REQUIRED by the corrected end-to-end design (the Edge Function is
no longer optional: it is the token issuer and the Ed25519 verification seam,
Sections I/L).

FORBIDDEN (unchanged from 2df4dc7):
```text
supabase/migrations/20260820000000.sql .. 20260820000033.sql  (immutable)
supabase/tests/s1/s2/s3_*.test.sql                            (immutable)
app/lib/**                                                     (client identity = S6)
supabase/config.toml / seed.sql / .env* / secrets / keystores
```

Migration number must be re-evaluated against real history at the future
implementation entry. Never overwrite an existing authorized `00034` (none
exists at this session; verified).

---

## N. Exact pgTAP Scenario / Assertion Plan (supersedes original K.2 open-endedness)

### N.1 One exact S4 test contract

```text
S4_GOVERNED_SCENARIOS    = 30
S4_SECURITY_ASSERTIONS   = 47   (scenario-level assertions: each scenario's
                                count is FIXED exactly to its stated minimum; no ">=")
S4_STRUCTURAL_ASSERTIONS = 3    (base/schema/migration + regression anchors,
                                mirroring the 3 structural assertions in the S3 base)
S4_TOTAL_PGTAP_PLAN      = 50   (47 + 3)  == ONE EXACT INTEGER
```

The future test file MUST open with:

```sql
SELECT plan(50);
```

and the implementation pre-commit gate MUST verify the real file contains exactly
50 assertions that reconcile to this value (no regex counting; use the actual
`plan(N)` and reconcile with real assertions, per the S3 plan-count lesson).

### N.2 Scenario -> assertion mapping (each count is EXACT, not a minimum)

Mapping reuses the original 30-scenario matrix with per-scenario EXACT counts:

| ID | Scenario / invariant | pgTAP assertion type | Exact count | Expected result |
|---|---|---|---|---|
| S4-01 | New employee device untrusted by default (PENDING_APPROVAL, not ACTIVE) | is | 2 | status=PENDING_APPROVAL; s4 approval false |
| S4-02 | Approved-device request gate shape (request-bound predicate) | is | 2 | predicate requires request-bound approved device, rejects "any approved" |
| S4-03 | Approved device obtains permitted access (server path) | is | 2 | allowed |
| S4-04 | Approval is Owner-only (employee/non-owner rejected) | throws_ok | 1 | denied for non-owner |
| S4-05 | Reject is Owner-only | throws_ok | 1 | denied for non-owner |
| S4-06 | Revoke / lost is Owner-only | throws_ok | 2 | denied for non-owner |
| S4-07 | Cross-shop device approval denied | throws_ok | 1 | cross-tenant denied |
| S4-08 | Revoked membership cannot use previously approved device | is | 1 | denied post-revocation |
| S4-09 | Revoked device remains denied | is | 1 | denied |
| S4-10 | Lost device denied | is | 1 | denied |
| S4-11 | Revoked/lost device cannot silently re-register as trusted | is | 2 | PENDING not ACTIVE on re-register |
| S4-12 | Invitation caller cannot nominate another p_user_id (auth.uid-bound) | is | 2 | accepted user == auth.uid(); nominated id NOT used |
| S4-13 | Expired invitation denied | throws_ok | 1 | denied |
| S4-14 | Revoked invitation denied | throws_ok | 1 | denied |
| S4-15 | Invalid token denied | throws_ok | 1 | denied |
| S4-16 | Replayed token denied | throws_ok | 1 | denied |
| S4-17 | Invitation token stored as hash (not plaintext) | is | 2 | token_hash != plaintext; length != plaintext |
| S4-18 | Successful acceptance binds authenticated caller | is | 2 | membership + accepted_by = auth.uid() |
| S4-19 | Accepted invitation is single-use | is | 2 | second accept denied; status=ACCEPTED |
| S4-20 | Proof challenge expiry | is | 1 | expired challenge rejected |
| S4-21 | Proof challenge replay rejection | is | 2 | reused challenge rejected |
| S4-22 | Invalid proof rejection | is | 1 | rejected |
| S4-23 | Proof bound to correct user/device/shop | is | 2 | wrong binding rejected |
| S4-24 | Approval does not bypass S2 quota | is | 2 | approve beyond capacity denied (dormant-ready) |
| S4-25 | S3 license revocation overrides device approval | is | 2 | denied |
| S4-26 | S3 membership revocation overrides device approval | is | 2 | denied |
| S4-27 | Same-shop concurrency serialization (approve vs revoke; two accepts; challenge reuse) | lives_ok / is | 2 | serialized under shop lock |
| S4-28 | Cross-shop operations do not globally block | lives_ok / is | 1 | independent |
| S4-29 | RLS tenant isolation remains intact | is | 2 | cross-shop read denied |
| S4-30 | Dormant enforcement wiring does not deny existing legitimate clients | is | 2 | enforcement OFF => prior access preserved; flag toggles |
| STRUCT-1 | migration 00034 object presence / idempotent replay | is | 1 | function/table/columns present; replay-safe |
| STRUCT-2 | search_path = public enforced on SECURITY DEFINER helpers | is | 1 | search_path == public |
| STRUCT-3 | S1/S2/S3 regression anchors (S1=46, S2=88, S3=25 pass) | is | 1 | all green |

Column totals reconcile: scenarios `S4-01..S4-30` sum to **47**; `STRUCT-1..3`
sum to **3**; total **50**.

---

## O. S1 / S2 / S3 Regression Gates (corrected)

```text
S1_PG_TAP = plan(46), 46 assertions - must remain green (verified at HEAD)
S2_PG_TAP = plan(88), 88 assertions - must remain green (verified at HEAD)
S3_PG_TAP = plan(25), 22 governed scenarios (T1..T22), 25 assertions reconcile
            to plan - must remain green
S3_GOVERNED_SCENARIOS = 22
S3_PGTAP_PLAN         = 25

DO NOT describe S3 as "22/22", "22 planned / actual >", or derive counts by
regex-counting assertion names. Use the actual plan(N) and reconcile with real
assertions.
```

S1 = plan(46) and S2 = plan(88) were re-read from the committed test files during
this session.

---

## P. Concurrency / Advisory-Lock Contract (inherited + invitation accept noted)

```text
ADVISORY_LOCK_NAMESPACE = hashtextextended(p_shop_id::text, 0)   (S2/S3 canonical)

REQUIRED SERIALIZATION (unchanged from 2df4dc7 J.6, plus):
  invitation accept vs invitation revoke
  invitation accept vs expiry
  two simultaneous invitation accepts (token single-use race)
  approve vs revoke / lost / membership / license revocation / device quota
  proof challenge replay / concurrent reuse
```

`pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))` is reused for every
S4 owner transition and for corrected `accept_invitation`. S2 quota authority,
S3 revocation authority, and the advisory-lock namespace are PRESERVED. S4 does
NOT create a competing revoke authority (`s3_revoke_device` is canonical).
Pending device quota policy remains explicit and source-consistent with S2
(approval consumes a slot; PENDING does not) — unchanged from `2df4dc7` J.7.

---

## Q. Success / Failure Criteria

```text
SUCCESS:
  - original S4 governance (2df4dc7) remote-locked and unmodified
  - this correction file created, committed (normal commit), fast-forward pushed
    to github, remote-locked
  - every Correction 1..8 resolved with an exact, evidence-based decision
  - exact RLS change set (J) and non-change set (K) locked
  - exact pgTAP plan locked (N: 30/47/3/50)
  - invitation issuance + acceptance end-to-end viable (L)
  - Ed25519 verification seam proven (I)
  - S4 implementation NOT started; no migration/test/Edge Function/app change

FAILURE / BLOCKED:
  - any material ambiguity remains on: request-bound device identity, crypto
    verification capability, RLS exact change set, invitation issuance,
    S4/S6 sequencing  -> RESULT = BLOCKED and S4 implementation NOT authorized
  - remote drift at push time (STOP / BLOCKED_REMOTE_DRIFT; no auto-rebase)
```

---

## R. Implementation Authorization Boundary

The future S4 implementation session may run ONLY when ALL hold:

```text
- this governance correction is committed and remote-locked
- original S4 governance (2df4dc7) remote-locked
- S1 (334d1ad), S2 (85e4315), S3 (62af446) remote-locked and unchanged
- repository clean in the governed sense; no active Git operation
- next authorized migration (00034 at HEAD, or adapted to real history) confirmed
- implementer stays within the EXACT allowlist (Section M)
- separate owner authorization for the S4 IMPLEMENTATION session exists
  (governance alone does not authorize implementation)
- enforcement activation remains governed by Section H (S6-coordinated or later)
```

---

## S. Mandatory Stop Before S4 Implementation

```text
THIS CORRECTION SESSION DOES NOT IMPLEMENT S4.

STOP.
DO NOT IMPLEMENT S4.
DO NOT CREATE MIGRATION 00034.
DO NOT CREATE S4 pgTAP.
DO NOT MODIFY invite-employee YET.
DO NOT START S5.
DO NOT START S6.
DO NOT START S7.
DO NOT START S8.
DO NOT START S9.
DO NOT START S10.
DO NOT START S11.
DO NOT START S12.
DO NOT START GROUP C.
DO NOT START GROUP D.
DO NOT DEPLOY TO SUPABASE PRODUCTION.
```

---

## T. Non-Actions Ledger (this governance correction session)

```text
S4_IMPLEMENTATION_STARTED = FALSE
SQL_MIGRATION_CREATED     = FALSE   (no 00034; no empty reservation)
S4_TEST_CREATED           = FALSE
EDGE_FUNCTION_CHANGED     = FALSE
RLS_CHANGED               = FALSE
AUTH_CHANGED              = FALSE
DEVICE_LOGIC_CHANGED      = FALSE
INVITATION_LOGIC_CHANGED  = FALSE
LICENSE_IMPL_CHANGED      = FALSE
CONFIGURATION_CHANGED     = FALSE
PRODUCTION_DEPLOYED       = FALSE
S1/S2/S3_MIGRATION_EDITED = FALSE
S1/S2/S3_TEST_EDITED      = FALSE
MIGRATION_00000..00033_EDITED = FALSE
ORIGINAL_S4_GOVERNANCE_EDITED = FALSE   (2df4dc7 file untouched)
APP_LIB_CHANGED           = FALSE
GROUP_B_OTHER_SLICES_STARTED = FALSE
GROUP_C_STARTED           = FALSE
GROUP_D_ADVANCED          = FALSE
SACRED_EVIDENCE_MUTATED   = FALSE
LEGACY_ORIGIN_MUTATED     = FALSE
LEGACY_ORIGIN_CONTACTED   = FALSE
FORCE_PUSH_USED           = FALSE
FORCE_WITH_LEASE_USED     = FALSE
REBASE_USED               = FALSE
AMEND_USED                = FALSE
HARD_RESET_USED           = FALSE
GIT_CLEAN_USED            = FALSE
```

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION   = CASE_A_FRESH
ENTRY_HEAD             = 2df4dc7aea4e0d07d18a5e9c8b7b1d95d988aae5
ENTRY_PARENT           = 62af44695e664722d1ccabf5816f55678d1e049a
ENTRY AHEAD/BEHIND     = 0 / 0
DIFF PROFILE           = 1 added file (this correction), 0 modified, 0 deleted
SACRED EVIDENCE        = preserved (untracked; never staged/modified)
CORRECTION FILE        = docs/PHASE_P_GROUP_B_S4_DEVICE_TRUST_SERVER_GATE_INVITATION_HARDENING_IMPLEMENTATION_GOVERNANCE_CORRECTION.md
RECOMMENDED COMMIT     = docs: correct Group B S4 device trust and invitation governance
FUTURE IMPL MIGRATION  = 20260820000034 (created ONLY by the future S4 implementation)
```
