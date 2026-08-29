# PHASE P — OWNER DECISIONS GOVERNANCE RESOLUTION

## Session Identity

| Field | Value |
|-------|-------|
| SESSION | `PHASE_P_OWNER_DECISIONS` |
| STATUS | LOCAL GOVERNANCE RESOLUTION (record-only; authorizes decisions, does not implement them) |
| DATE | 2026-08-30 |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| LOCKED_PHASE_P_IMPLEMENTATION_BASELINE | `1a931111b5b63103d282bd647d00afdae2d23b5c` |
| LOCKED_TAG | `phase-p-implementation-locked` (annotated `50ecc097…` → `1a931111…`) |
| RESOLVES | `PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md` §7 open decisions |
| GOVERNING_PLAN | `PHASE_P_PRODUCTION_HARDENING_PLAN.md` |

This artifact resolves the remaining explicit Owner Decisions that block final
Phase P governance closure. Each decision is a product choice supplied
authoritatively by the Owner and is recorded without weakening, reinterpretation,
or silent replacement. The decisions authorize future planning/implementation
of the affected workstreams. **They do not implement any of them.**

---

## A. Decision Status

| Stable ID | Decision | Scope / Workstream | Status |
|-----------|----------|--------------------|--------|
| P-OD1 | WS-3 / OD6 negative-stock Option C durability | WS-3 | APPROVED |
| P-OD2 | WS-7 / OD-K1 Android application identity | WS-7 | APPROVED (migration authorized) |
| P-OD3 | WS-7 / OD-K2 Android production signing | WS-7 | APPROVED (integration authorized; no credentials supplied) |
| P-OD4 | WS-9 purchase cost-change workflow | WS-9 | APPROVED |
| P-OD5 | WS-9 opening balances | WS-9 | APPROVED |
| P-OD6 | WS-9 arbitrary-period profit reporting | WS-9 | APPROVED |
| P-OD7 | Sync drain gated activation | WS-1 (activation gate) | CONDITIONALLY AUTHORIZED AFTER EVIDENCE |
| P-OD8 | Commercial subscription/tier model | WS-4 | APPROVED |
| P-OD9 | Offline grace policy | WS-4 | APPROVED |
| P-OD10 | Revocation enforcement | WS-4 | REQUIRED (mechanism = design detail) |
| P-OD11 | Tamper/clock/entitlement-cache integrity | WS-4 | REQUIRED |
| P-OD12 | Legacy Ed25519 licensing path retirement/isolation | WS-4 | APPROVED (conditional on evidence) |

---

## B. Source Mapping

Maps each decision to its governing Phase P workstream, repository evidence,
prior governing decision, and implementation dependency.

| Decision | Governing workstream | Existing repository evidence | Prior governing decision | Implementation dependency |
|----------|----------------------|------------------------------|--------------------------|---------------------------|
| P-OD1 (WS-3) | WS-3 Negative-stock Option C durability | `inventory_oversell_policy.dart:17-18` (preserveWithAdjustment default, unwired/dev-seam); `reconciliation_service.dart:104-110` (null sink); `conflict_audit_repository.dart` (tests-only); `cloud_sales_repository.dart:191-210` (p_allow_oversell, no production caller); Phase M `20260820000028…sql` (SELECT FOR UPDATE outstanding, DR-M03); local block `database_helper.dart:1232-1298` | PROJECT_MASTER_PLAN.md OD6; PHASE_M §DR-M06 (OPEN gate); `PHASE_P_PRODUCTION_HARDENING_PLAN.md` §F.4/Q | WS-1 (route reconciliation through runtime); server `SELECT…FOR UPDATE` |
| P-OD2 (WS-7) | WS-7 Android application identity | `app/android/app/build.gradle:9,28` (`com.almuaman.muaman_store`); OD-K1 placeholder comment `build.gradle:26`; `PHASE_K…PLAN.md` §R6/OD-K1, `PHASE_L…PLAN.md` OD-L2 | PROJECT_MASTER_PLAN.md §1 OD1 (marketing name/package); Phase K/L carried OD-K1 | WS-7/WS-8 Android release pipeline; NOT touching frozen desktop/DB identifiers |
| P-OD3 (WS-7) | WS-7 Android production signing | `app/android/app/build.gradle:41` (`signingConfig = signingConfigs.debug`); OD-K2 placeholder `build.gradle:38`; `PHASE_K…PLAN.md` OD-K2, `PHASE_L…PLAN.md` OD-L3 | Phase K/L carried OD-K2 | Owner-controlled keystore provisioning; WS-7/WS-8 |
| P-OD4 (WS-9) | WS-9 purchase cost-change workflow | `app/lib/screens/inventory/inventory_screen.dart` (edit path `195-299` without warning); mandatory cost `inventory_screen.dart:222-230`; `database_helper.dart:903-905,979-981` (cost/COGS) | PROJECT_MASTER_PLAN.md §1 (accounting/inventory correctness); `PHASE_P…PLAN.md` §F.10/Q | Additive schema (history); WS-1 drain for cloud durability of new entities |
| P-OD5 (WS-9) | WS-9 opening balances | No accounts/ledger/supplier entity in schema (verified); `PHASE_P…PLAN.md` §F.10 | PROJECT_MASTER_PLAN.md accounting foundation | Additive schema (accounts/ledger); WS-1 drain |
| P-OD6 (WS-9) | WS-9 arbitrary-period profit reporting | `sales_report_screen.dart:80-81,122-148` (today/month/all only, no range); `sales_screen.dart:356-371` | PROJECT_MASTER_PLAN.md (accounting correctness over convenience) | Additive schema; WS-1 drain; WS-4 data inputs |
| P-OD7 | WS-1 Sync drain activation gate | `app/lib/config/app_config.dart:39` (`syncDrainEnabled = bool.fromEnvironment`, default FALSE); WS-1 `SyncRuntime` (`sync/sync_runtime.dart`) wired but gated; `PHASE_P…PLAN.md` §F.2, §M.1 | `PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md` §3 WS-1 (single flip, dormant), §7 item 4 | Live `SyncCloudOperations` transport proof (mandatory gates); WS-5 hardening |
| P-OD8 (WS-4) | WS-4 Commercial model | No plans/tiers table; `PLANS` text; single `max_devices=3`; `licenses.plan` nullable+unused (`20260820000005_create_licenses.sql`; `phase_e_licensing_enhancements.sql:17`) | PROJECT_MASTER_PLAN.md D12 (14-day trial), OD2 (pricing), OD3 (tier caps) | Server-authoritative entitlement schema (WS-4) |
| P-OD9 (WS-4) | WS-4 Offline grace | `offline_grace_policy.dart:8,13,48-61` (WS-4 already corrected paid 7d / trial 0d / perpetual 14d-compat; retired 24h cap) | PROJECT_MASTER_PLAN.md D14 (offline); `PHASE_P…PLAN.md` §F.5 | None blocking (partly implemented); final semantics frozen |
| P-OD10 (WS-4) | WS-4 Revocation enforcement | Revocation pull-only latency (`cloud_licensing_service.dart:185-236,326-370`); server-authoritative RPC (`require_shop_permission`) | PROJECT_MASTER_PLAN.md §9 (server authority), §11 security | Server-authoritative; exact cadence/realtime = implementation design detail |
| P-OD11 (WS-4) | WS-4 Tamper/clock/cache integrity | `entitlement_token.dart:12,344` (empty trusted keys); `entitlement_cache.dart:89-137` (plaintext); `offline_grace_policy.dart:79-93` (clock-rollback detect unused) | PROJECT_MASTER_PLAN.md §11 (signed tokens, no client-trust) | Server-authoritative, bounded, testable controls |
| P-OD12 (WS-4) | WS-4 Legacy Ed25519 path | `licensing_service.dart:408-431` (ActivationClient "not yet deployed"); `settings_screen.dart:832-869` (LicenseStatusScreen surfaced) | PROJECT_MASTER_PLAN.md §11 security; `PHASE_P…PLAN.md` §F.5 (retire/gate dead seam) | Repository evidence that no required production path depends on legacy seam |

---

## C. Authorization Boundary

```
THIS ARTIFACT AUTHORIZES DECISIONS.
IT DOES NOT IMPLEMENT THEM.
```

Explicitly, this artifact does **not** authorize, perform, or enable in this
session:

- flipping `AppConfig.syncDrainEnabled` (remains FALSE — P-OD7);
- modifying Android `applicationId`/package (P-OD2 authorizes migration in a
  future session only);
- configuring release signing or creating/guessing any keystore, password, or
  private credential (P-OD3);
- implementing Option C durability (P-OD1);
- adding accounting/ledger/opening-balance schema or records (P-OD5);
- implementing arbitrary-period reports (P-OD6);
- modifying subscription/tier/revocation logic or deployment (P-OD8..P-OD11);
- removing/isolating Ed25519 code (P-OD12) without future evidence;
- modifying production Supabase, deploying anything, or rebuilding delivery
  artifacts.

The only expected tracked mutation is this Governance Artifact.

---

## D. Frozen Boundaries

The following legacy desktop/database identifiers remain **frozen** and are
**not** renamed, modified, or reinterpreted by any decision in this artifact:

```text
muaman_store            (pubspec / binary name)
muaman_store.db         (production database filename)
muaman_store.exe        (legacy binary compatibility)
{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}   (existing Windows identity / AppId)
I-TECH للتكنولوجيا      (Windows installer AppName / window title - already I-TECH)
muaman_store            (existing Linux/CMake identities)
All table names / column names / permission IDs / role names   (add-only)
```

Android package identity (`com.itech.storemanagement`) is an **intentionally
separate boundary** (P-OD2) and does NOT require touching any frozen
desktop/database/CMake/window identity above.

### Sacred artifacts

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.temp/   (must remain untracked/unmodified)
```

---

## E. Notes on Owner Decisions vs. Implementation Details

To keep real product choices distinct from ordinary engineering detail, the
following are **Owner Decisions** (authoritative, this artifact), and the
following are **implementation design details** (left to the future
planning/implementation session, not treated as artificial Owner-Decision
blockers):

**Owner Decisions (recorded here):**

- P-OD1: negative-stock sale/event must never disappear; event, stock state,
  explicit adjustment evidence, and immutable/durable audit must persist;
  server-side stock changes concurrency-safe (row-level serialization /
  `SELECT … FOR UPDATE` where architecturally applicable); multi-device
  reconciliation must not silently overwrite/erase the oversell event; reports
  mathematically traceable to persisted transactions and adjustments.
- P-OD2: canonical Android package = `com.itech.storemanagement` aligned with
  `I Tech Store Management` / `I Tech لإدارة المحلات`; migration from
  `com.almuaman.muaman_store` authorized for a future implementation session;
  frozen desktop/DB identifiers untouched.
- P-OD3: production releases MUST use proper owner-controlled release signing;
  debug signing never used for production; signing secrets never committed;
  keystore/password/private credentials remain outside source control; repo may
  contain safe templates/instructions only; release signing fails closed if
  required config missing; agent must not generate/guess/upload/invent a
  keystore or production secret without owner provisioning.
- P-OD4: purchase at a different cost must warn the authorized user and offer a
  non-destructive choice (A) update/accept per governed costing model, or
  (B) create a new distinct product record; no silent destructive overwrite;
  historical sales/purchases remain traceable.
- P-OD5: opening balances supported as explicit accounting entries/balances
  (not fabricated historical transactions); auditability required.
- P-OD6: user-selected reporting periods beyond a hard-coded month; correctly
  distinguish revenue / COGS / gross profit / applicable operating effects /
  net result (only where data supports it) / receivables / payables /
  opening-balance effects; never label "net profit" unless inputs actually
  support it; accounting correctness over UI convenience.
- P-OD7: `syncDrainEnabled` remains FALSE until a mandatory evidence gate proves
  the real production `SyncCloudOperations` transport (context, tenant
  isolation, permissions, entitlement, enqueue→drain, retry/idempotency, stable
  cloud identity, offline recovery, conflict, counters, reconnect, no
  cross-shop movement, no duplicates, no secret leakage, runtime sanity).
- P-OD8: subscription-only model; 14-day trial; monthly + annual billing; tiers
  (TRIAL 1/1, STARTER 2/3, PROFESSIONAL 5/10, ENTERPRISE ∞/∞); server
  authoritative; client checks UX only, never the security authority.
- P-OD9: offline grace TRIAL 0d / PAID 7d / PERPETUAL 14d compatibility-only;
  product stays subscription-only; PERPETUAL must never silently become a sold
  commercial plan.
- P-OD10: server authoritative for subscription validity, license state,
  membership, device authorization, permission state; revocation/expiry not
  dependent solely on indefinitely stale local state.
- P-OD11: reasonable production hardening required — clock rollback/
  manipulation, stale entitlement cache, cache tampering, entitlement replay,
  server revalidation, fail-safe behavior, offline-grace abuse; no client
  perfect anti-tamper claim; server-authoritative bounded testable controls; no
  unnecessary device-sensitive data collection.
- P-OD12: legacy token/signature path must not remain exposed as if active only
  after evidence proves no required production path depends on it.

**Implementation design details (NOT Owner decisions — deferred to planning):**

- Exact `SELECT … FOR UPDATE` statement placement and inventory serialization
  mechanics (P-OD1).
- The precise costing model (weighted-average vs. LIFO/FIFO/specific) used by
  the P-OD4 "update/accept" option, determined using repository evidence and
  sound accounting behavior.
- Reporting-period filter UI/UX and exact net-result derivation thresholds
  (P-OD6).
- The Supabase polling/realtime/mechanism and cadence for revocation/expiry
  propagation (P-OD10) — decided with evidence and documented trade-offs.
- The concrete tamper/HMAC/clock-check technique for entitlement-cache integrity
  (P-OD11).
- The specific approach/commit that retires or isolates the legacy Ed25519 seam
  once evidence is produced (P-OD12).
- The exact DB migration columns/tables for Option C audit, cost-change history,
  opening balances, and cloud-stable identity (WS-2/WS-3/WS-9).

These engineering details do not block any Owner Decision recorded above.

---

## F. Successor Authorization

Per repository governance (see `POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md`
remote-lock protocol and the established per-phase
planning→implementation→remote-lock sequence), a locally-committed governance
artifact is followed by a dedicated **remote-lock** session before the next
stage is executed. The repository does **not** permit proceeding directly to
implementation for a governed product decision without a separate remote lock.

```text
PHASE_P_OWNER_DECISIONS_LOCAL_CLOSURE = COMPLETE
PHASE_P_OWNER_DECISIONS_REMOTE_LOCK  = NOT_STARTED

PHASE_P_FINAL_CLOSURE = NOT_COMPLETE

NEXT_AUTHORIZED_SESSION =
PHASE_P_OWNER_DECISIONS_REMOTE_LOCK
```

This artifact does **not** claim Phase P final closure. Owner Decisions are
resolved and recorded; they still require remote governance lock, any
implementation authorized by those decisions, and completion/verification of
the authorized follow-up implementation before Phase P final closure.

---

## G. Governing Principle

Sequence respected by this session:

```text
LOCKED PHASE P IMPLEMENTATION BASELINE (1a931111)
        ↓
PHASE P OWNER DECISIONS — LOCAL GOVERNANCE RESOLUTION   (this artifact)
        ↓
OWNER DECISIONS REMOTE LOCK                            (next authorized)
        ↓
AUTHORIZED FOLLOW-UP IMPLEMENTATION / VERIFICATION
        ↓
PHASE P FINAL GOVERNANCE CLOSURE
```

No stage was skipped. No destructive recovery, history rewrite, push, or tag
operation was performed by this session.
