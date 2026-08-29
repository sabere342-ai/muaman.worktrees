# POST PHASE P OWNER DECISIONS — GOVERNANCE DETERMINATION

## A. Session Identity

| Field | Value |
|-------|-------|
| SESSION | `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION` |
| TYPE | GOVERNANCE-DETERMINATION ONLY (no implementation, no push, no activation) |
| DATE | 2026-08-30 |
| REPOSITORY | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| BASELINE | Local = Remote = merge-base = `2ca65bf076c349cfa422c89bc9dc11481dd1949a` |
| GOVERNING ARTIFACTS | `PHASE_P_OWNER_DECISIONS.md`, `PHASE_P_PRODUCTION_HARDENING_PLAN.md`, `PHASE_P_IMPLEMENTATION_CLOSURE_REPORT.md`, `PHASE_P_IMPLEMENTATION_REPAIR_REPORT.md`, `POST_GATE_12_ROADMAP_GOVERNANCE_DETERMINATION.md`, `PROJECT_MASTER_PLAN.md`, `I-TECH-NEXT-ROADMAP-V2-FREEZE.md` |

This session resolves the generic post-lock stage

```text
OWNER DECISIONS REMOTE LOCK
        ↓
AUTHORIZED FOLLOW-UP IMPLEMENTATION / VERIFICATION
        ↓
PHASE P FINAL GOVERNANCE CLOSURE
```

into a concrete, evidence-backed, safely sequenced successor path. It does **not**
implement anything, does **not** push, does **not** activate the sync drain, and
does **not** claim Phase P final closure.

---

## B. Entry Forensics

| Field | Expected | Actual |
|-------|----------|--------|
| TOPLEVEL | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` | Match |
| BRANCH | `codex/i-tech-next-roadmap-freeze` | Match |
| LOCAL_HEAD | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` | Match |
| REMOTE_HEAD (`github/...`, post fetch) | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` | Match |
| MERGE_BASE | `2ca65bf076c349cfa422c89bc9dc11481dd1949a` | Match |
| AHEAD / BEHIND | 0 / 0 | Match |
| INDEX | EMPTY | Match |
| TRACKED WORKTREE | CLEAN | Match |
| UNTRACKED | sacred artifacts + `supabase/.temp/` only | Match (4 entries) |
| AUTHORIZED_REMOTE URLs | github fetch/push = `https://github.com/sabere342-ai/muaman.worktrees.git` | Match |
| LEGACY `origin` | present, local desktop path, NOT authorized | Present; NOT fetched/pushed/renamed/deleted/modified |

**Recovery classification:** `CASE_A_FRESH_GOVERNANCE_DETERMINATION`. The
repository evidence matches the expected remotely-locked handoff exactly. No
destructive recovery (`git reset --hard`, `git clean -fd`, force checkout,
history rewrite, force push) was used or needed. Untracked sacred artifacts were
preserved, not deleted to achieve a clean status.

---

## C. Governance Question

**Why the generic `AUTHORIZED FOLLOW-UP IMPLEMENTATION / VERIFICATION` was
insufficient to begin coding directly:**

The post-lock contract in `PHASE_P_OWNER_DECISIONS.md` §F resolves **twelve**
owner decisions (P-OD1..P-OD12) that span **four structurally distinct
workstream groups** (runtime sync/Option C; licensing/security; Android
identity/signing; accounting/business gaps). Those groups:

1. Carry **independent additive-server-schema** requirements (Option C
   adjustment/audit; plans/tiers/grace; accounts/ledger;
   `cloud_uuid`/snapshot), each needing its own migration planning and a
   migration test + restore-whitelist bump (plan §G, §N).
2. Include **externally provisioned secrets** (Android release keystore,
   P-OD3) that the repository must fail-closed without.
3. Include a **mandatory evidence-gated transport activation** (sync drain,
   P-OD7) that cannot be flipped until live `SyncCloudOperations` transport is
   proven.
4. Depend on **planning-time engineering decisions explicitly deferred** by
   `PHASE_P_OWNER_DECISIONS.md` §E (exact COGS model, revocation transport,
   tamper technique, exact migration columns).

The repository's own protocol (see `POST_GATE_12...DETERMINATION.md` §REMOTE_LOCK
and `PHASE_P_OWNER_DECISIONS.md` §F) requires a **separate remote-lock** after
every local governance determination before the next stage is executed, and
requires each governed product decision to pass a planning stage before
implementation. Therefore a single undifferentiated implementation session is
**not** governed by evidence and would blur four independent schemas, one
secret-dependent gate, and one evidence-gated activation into one unsafe unit.
This determination decomposes that unit and names the first authorized step.

---

## D. Dependency Determination

### Group A — Runtime Sync / Option C durability

Includes P-OD1, P-OD7, WS-1, WS-2, WS-3, WS-5.

Dependency order (from plan §F.1 / §A findings):
```
stable cloud identity (WS-2) ← integral to durable writes
        ↓
runtime sync lifecycle / drain (WS-1, foundational)   ← highest-severity never-sync risk
        ↓
queue representation + durable enqueue (existing, live)
        ↓
live production SyncCloudOperations transport proof   ← P-OD7 MANDATORY EVIDENCE GATE
        ↓ ONLY AFTER gate proven
server stock serialization SELECT…FOR UPDATE + conflict reconciliation (WS-3, phase M extension)
        ↓
immutable audit evidence (adjustment + audit rows)
        ↓
drain activation (syncDrainEnabled = TRUE) ONLY at a dedicated governed gate
```
- Per-write snapshot (WS-5) depends on WS-1/WS-2.
- **The drain must NOT be flipped by this or any planning session.** It remains
  `FALSE` until live-transport evidence is produced and remotely locked.
- Requires: additive schema (adjustment/audit, `cloud_uuid`, snapshot) — each a
  separate planned migration with a migration test and restore-whitelist bump.
- Requires its own planning boundary before implementation, because the exact
  migration columns and serialization mechanics are deferred to planning
  (P-OD1 §E).

### Group B — Licensing / Commercial / Security

Includes P-OD8, P-OD9, P-OD10, P-OD11, P-OD12, WS-4.

Changes require **both** additive Supabase schema/RPC work **and** Flutter
entitlement-model changes:
- Additive `plans`/`plan`/tier/subscription schema; entitlement/revocation RPCs;
  expiry/quota enforcement server-side (plan §F.5).
- Client entitlement model, offline-grace already partly corrected (WS-4
  partial), cached-entitlement integrity + clock checks (P-OD11),
  legacy Ed25519 retirement proof (P-OD12).
- Revocation transport cadence is an engineering design detail deferred to
  planning (P-OD10 §E).
- **Distinct planning boundary required**: Supabase migration/deployment
  planning is separate from local Flutter entitlement implementation, because
  the server schema/function surface must be designed and (eventually, in a
  governed deployment session) migrated before the client can depend on it.
- Nothing is deployed by this or any planning session.

### Group C — Android Identity / Signing

Includes P-OD2, P-OD3, WS-7, WS-8.

- Package migration `com.almuaman.muaman_store` → `com.itech.storemanagement`
  (P-OD2) touches `app/android/app/build.gradle` applicationId/package paths and
  is authorized **only** through a governed implementation boundary; frozen
  desktop/database identities are untouched.
- Release signing (P-OD3) requires **owner provisioned** keystore/credentials
  that remain outside the repository; release build must **fail closed** when
  absent; repo holds safe templates/instructions only.
- **Distinct release-boundary planning required**: this group must not be
  implemented in the same scope as Group A/B/D because it depends on an external
  secret and changes Android build identity. A separate release/verification
  gate is required.

### Group D — Accounting / Business-Critical Gaps

Includes P-OD4, P-OD5, P-OD6, WS-9.

- Cost-change workflow (P-OD4) requires additive history schema; exact costing
  model (weighted-average vs LIFO/FIFO/specific) is deferred to planning §E.
- Opening balances (P-OD5) require additive accounts/ledger/supplier schema as
  explicit accounting entries — **no fabricated historical transactions**.
- Arbitrary-period reporting (P-OD6) must distinguish revenue/COGS/gross/
  operating/net (only where data supports) / receivables / payables /
  opening-balance effects — **no false "net profit"**.
- **Distinct schema/accounting planning boundary required before
  implementation**, because the accounts/ledger foundation, opening-balance
  representation, and reporting inputs must be designed first; full double-entry
  accounting remains `POST_P`/excluded.

### Cross-group conclusion

All four groups require their own planning (and each planning needs a remote
lock) before implementation. They share no implementation affordance that would
justify merging them into a single implementation session. The safe order is
**Group A first** (foundational runtime + drain, the single largest risk),
because it unblocks correct behavior of offline sales, Option C, and status. The
exact per-scope plans, migration specs, and gates are the object of the first
authorized planning boundary.

---

## E. Successor Scope Determination

```text
SUCCESSOR_SCOPE = POST_PHASE_P_OWNER_DECISIONS GOVERNANCE REMOTE LOCK
                  (locks this determination, then authorizes the scoped
                   PHASE P owner-gated planning boundary)
SUCCESSOR_IDENTITY = A dedicated remote-lock session for THIS governance
                     determination, followed by a governed, decomposed
                     planning phase for the Phase P owner-gated workstreams
                     (Group A first).
PLANNING_REQUIRED = YES (each of Groups A-D requires its own planning +
                    remote-lock before its implementation; this is mandatory
                    per repository protocol and the deferred engineering
                    decisions in PHASE_P_OWNER_DECISIONS.md §E)
IMPLEMENTATION_AUTHORIZED = NO
```

`IMPLEMENTATION_AUTHORIZED` is **NO** because repository governance does not
permit direct implementation from a governance determination without the
intervening dedicated remote-lock and subsequent per-scope planning/remote-lock
stages. No production code path is authorized here.

The immediate successor **session** is the dedicated remote-lock session for this
governance determination (consistent with `POST_GATE_12...` and
`PHASE_P_OWNER_DECISIONS.md` §F). After that lock, the next governed step is the
creation and remote-locking of a **Phase P Owner-Gated Planning** scope starting
with **Group A** (runtime sync/Option C + live transport evidence gate).

---

## F. Deferred Scopes (NOT authorized by this successor)

The immediate successor does **not** authorize:

- **Group A** implementation: durable Option C (P-OD1), any runtime sync drain
  wiring beyond the existing dormant seam, `SyncCloudOperations` transport
  construction, `SELECT…FOR UPDATE` server changes, or **any** drain flip
  (P-OD7).
- **Group B** implementation: plans/tiers/subscription/grace/revocation changes,
  entitlement RPCs, cache-integrity/tamper/clock controls, legacy Ed25519
  retirement (P-OD8..P-OD12), or any Supabase deployment.
- **Group C** implementation: Android package migration or release-signing
  configuration (P-OD2/P-OD3); no keystore/credential creation.
- **Group D** implementation: cost-change workflow, opening balances,
  arbitrary-period reporting, or any accounts/ledger schema (P-OD4/P-OD5/P-OD6).
- Any push to `github`; any tag creation/movement; any claim of
  `PHASE_P_FINAL_CLOSURE = COMPLETE`.

Each group remains deferred and will be brought into implementation only through
its own planning → remote-lock → implementation → remote-lock sequence.

---

## G. Final Phase P Closure Conditions

`PHASE_P_FINAL_CLOSURE = COMPLETE` requires, at minimum (per plan §M and §P):

1. Every WS-1..WS-10 acceptance criterion satisfied, including:
   - Group A: real production `SyncCloudOperations` transport proven (live
     transport evidence gate, P-OD7) and drain activated only at a governed
     gate; Option C durability runtime-wired with durable adjustment + audit;
     server stock serialized.
   - Group B: subscription/tier/grace/revocation enforced server-authoritatively;
     tamper checks active; legacy Ed25519 path retired only after evidence that
     no required production path depends on it (P-OD12).
   - Group C: Android package identity migrated to `com.itech.storemanagement`
     and production release signing configured with owner-provisioned secrets
     (fail closed; secrets external).
   - Group D: cost-change workflow, opening balances, arbitrary-period reporting
     implemented with accounting correctness (no false net profit).
   - WS-6 restore forward-compatible; WS-10 security/supabase seal passed.
2. `flutter analyze` 0 errors/0 warnings; `dart format --set-exit-if-changed`
   green; **all** `flutter test` passing (1428+ baseline, plus new tests).
3. All Phase P migrations additive, migration-tested, restore whitelist current.
4. Frozen identifiers unchanged; no Phase A–O decision reopened.
5. Production config secret-free; release builds signed/verifiable.
6. Local implementation commits exist and each governed remote lock complete
   per the planning→lock→implementation→lock protocol.

This remains **NOT COMPLETE** and is not claimed by this session.

---

## H. Successor Authorization

```text
POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION_LOCAL_CLOSURE = COMPLETE
POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION_REMOTE_LOCK    = NOT_STARTED
PHASE_P_FINAL_CLOSURE                                                = NOT_COMPLETE

NEXT_AUTHORIZED_SESSION =
POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION_REMOTE_LOCK
```

This is the sole immediate successor. After that remote lock completes, the
governed next step is the **Phase P Owner-Gated Planning** boundary, beginning
with Group A (runtime sync / Option C) and its live-transport evidence gate.

---

## Notes

- This artifact records a governance determination only. It does not reopen any
  owner decision (P-OD1..P-OD12 remain resolved), does not implement any of them,
  and does not pre-authorize any implementation session in a way that bypasses
  the mandatory planning + remote-lock stages.
- Frozen identifiers and sacred artifacts are unchanged (see J/K below).
- The legacy `origin` remote was not fetched from, pushed to, renamed, deleted,
  or modified.
