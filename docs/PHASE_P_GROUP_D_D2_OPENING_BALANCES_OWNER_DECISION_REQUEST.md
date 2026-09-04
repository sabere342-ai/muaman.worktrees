# Phase P / Group D / D2 — Opening Balances Owner Decision Request

**Session result:** PASS — D2 owner-decision governance completed. Implementation is NOT started and remains owner-gated until D2-01..D2-07 are explicitly resolved.

**Classification:** PHASE_P_GROUP_D_D2_OWNER_DECISIONS

**Implementation authorization:** NO (every D2-01..D2-07 decision remains `IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES`; no inference, fabrication, or silent default applied).

---

## A. Session Result

```text
SESSION =
  PHASE_P_GROUP_D_D2_OPENING_BALANCES_OWNER_DECISIONS

AUTHORIZED_SCOPE =
  OWNER_DECISION_REQUEST_ONLY

IMPLEMENTATION_AUTHORIZED =
  NO

D1_STATE =
  CLOSED_REMOTE_LOCKED (unchanged)

D2_PLANNING_STATE =
  CLOSED_REMOTE_LOCKED (unchanged)

D2_IMPLEMENTATION_STARTED =
  NO

D3_STARTED =
  NO

PRODUCTION_MUTATION =
  NO

MIGRATION_00038_CREATED =
  NO

schemaVersion_20_CREATED =
  NO

ORIGIN_CONTACTED =
  NO
```

---

## B. Repository Identity (forensic)

```text
ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
LEGACY_REMOTE = origin (NOT contacted)
```

---

## C. Entry Classification and Remote-Lock Proof

```text
ENTRY_CLASSIFICATION = CASE_A_FRESH

ENTRY_LOCAL_HEAD    = ad64bbb8c43192ee67b631424496b71bf5fcacc4
ENTRY_TRACKING_HEAD = ad64bbb8c43192ee67b631424496b71bf5fcacc4
ENTRY_DIRECT_REMOTE = ad64bbb8c43192ee67b631424496b71bf5fcacc4
ENTRY_MERGE_BASE    = ad64bbb8c43192ee67b631424496b71bf5fcacc4
ENTRY_AHEAD         = 0
ENTRY_BEHIND        = 0

ACTIVE_GIT_OPERATION = NONE (no merge/rebase/cherry-pick/revert/bisect)
TRACKED_DELTAS       = NONE
UNTRACKED_PRE_EXISTING_ARTIFACTS = classified, left untouched, not staged
```

```text
GOVERNANCE_PARENT_COMMIT = ad64bbb8c43192ee67b631424496b71bf5fcacc4
GOVERNANCE_ARTIFACT      = docs/PHASE_P_GROUP_D_D2_OPENING_BALANCES_PLANNING_GOVERNANCE.md
GOVERNANCE_BLOB          = 763977c9a311210fb3f51d2cbc3a26cf242526bd
GOVERNANCE_LINES         = 1245
```

---

## D. Authority Chain (evidence, not prose)

```text
PHASE_P_OWNER_DECISIONS.md
  P-OD5 (WS-9 opening balances) = APPROVED  (line 32)
      |
      v
POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md
POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md
      |
      v
POST_MIGRATION_30_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION_REPORT.md
docs/OWNER_ORDER_GROUP_B_BEFORE_GROUP_D_* bindings
      |
      v
PHASE_P_OWNER_GATED_GROUP_B_PLAN.md
Group B S1-S12 closed (154a970 commit = Group B S12 final acceptance)
      |
      v
a6c3993  docs: govern Phase P Group D implementation planning
0d65c13  feat: implement Phase P Group D D1 cost change history
a74fb62  docs: govern Phase P Group D D1 corrective remediation
34a5901  docs: record corrective remediation remote-lock evidence
37d1efb  fix: remediate Phase P Group D D1 workflow and RPC authorization
eb41f04  test: correct D1 RLS assertions + evidence closeout governance
8bf626d  D1 CLOSED_REMOTE_LOCKED (closeout evidence recorded)
      |
      v
ad64bbb8  D2 planning CLOSED_REMOTE_LOCKED (current HEAD)
```

Verified with `git log --first-parent`.

---

## E. Owner Decisions D2-01..D2-07 — PENDING

The planning governance (Section L) records recommendations ONLY. No owner selection exists in the authoritative context. Each decision remains `IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES`.

```text
D2-01 — ACCOUNT MODEL
  OWNER_SELECTION       = PENDING_OWNER
  OPTIONS               = A) additive per-shop account catalog (EMPTY seeded)
                          B) fixed minimal system-set of accounts
                          C) single implicit shop opening balance
  RECOMMENDED_DEFAULT   = A) additive per-shop account catalog, empty by default
  RATIONALE             = PENDING_OWNER
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-02 — SIGN CONVENTION
  OWNER_SELECTION       = PENDING_OWNER
  POSITIVE_MEANS        = PENDING_OWNER (A asset/debit-like | B liability/credit-like | C type-aware)
  NEGATIVE_MEANS        = PENDING_OWNER
  ZERO_RULE             = PENDING_OWNER
  RECOMMENDED_DEFAULT   = C) type-aware direction (CASH/BANK/RECEIVABLE_SUMMARY positive = owned/owed to shop; PAYABLE_SUMMARY/CAPITAL positive = obligation)
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-03 — NEGATIVE BALANCES
  OWNER_SELECTION       = PENDING_OWNER
  VALIDATION_RULE       = PENDING_OWNER
  DATABASE_RULE         = PENDING_OWNER
  UI_RULE               = PENDING_OWNER
  RECOMMENDED_DEFAULT   = A) negatives rejected (zero/positive only), direction via account TYPE
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-04 — EFFECTIVE DATE
  OWNER_SELECTION       = PENDING_OWNER
  DATE_REQUIRED         = PENDING_OWNER
  DATE_MUTABLE          = PENDING_OWNER
  TIMEZONE_SEMANTICS    = PENDING_OWNER
  INDEX_REQUIRED        = PENDING_OWNER
  RECOMMENDED_DEFAULT   = C) per-entry effective_date column, additive, indexed, future-D3-only use
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-05 — EDIT / CORRECTION MODEL
  OWNER_SELECTION       = PENDING_OWNER
  DIRECT_EDIT_ALLOWED   = PENDING_OWNER
  DELETE_ALLOWED        = PENDING_OWNER
  CORRECTION_LINK_REQUIRED = PENDING_OWNER
  AUDIT_EFFECT          = PENDING_OWNER
  RECOMMENDED_DEFAULT   = A) append-only + corrective adjustment entries (corrects_entry_id / correction_reason)
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-06 — RBAC
  OWNER_SELECTION       = PENDING_OWNER
  OWNER_CAN_CREATE      = PENDING_OWNER
  OWNER_CAN_CORRECT     = PENDING_OWNER
  OWNER_CAN_VIEW        = PENDING_OWNER
  EMPLOYEE_CAN_CREATE   = PENDING_OWNER
  EMPLOYEE_CAN_CORRECT  = PENDING_OWNER
  EMPLOYEE_CAN_VIEW     = PENDING_OWNER
  SALES_ONLY_RULE       = PENDING_OWNER (denied)
  NEW_PERMISSION_REQUIRED = PENDING_OWNER (whether permissions.dart change is needed)
  RECOMMENDED_DEFAULT   = B) owner set/correct + owner/employee read-only view; salesOnly/unauthenticated denied
  IMPLEMENTATION_BINDING= PENDING_OWNER

D2-07 — ENTRY TIMING
  OWNER_SELECTION       = PENDING_OWNER
  ENTRY_WINDOW          = PENDING_OWNER
  LOCK_RULE             = PENDING_OWNER
  CORRECTION_AFTER_LOCK = PENDING_OWNER
  RECOMMENDED_DEFAULT   = A) dedicated owner opening-balance setup workflow; never inside customer/supplier creation
  IMPLEMENTATION_BINDING= PENDING_OWNER
```

```text
OWNER_DECISIONS_REQUIRED = D2-01..D2-07 (all IMPLEMENTATION_BLOCKED_UNTIL_RESOLVED = YES)
RESOLUTION_MECHANISM = explicit owner selection recorded in an authoritative governed artifact
NOT_FABRICATED       = YES
```

---

## F. What Was NOT Created (OUTCOME A discipline)

```text
migration 20260820000038_*.sql  = NOT created
schemaVersion 20                = NOT created
account.dart / ledger_entry.dart / opening_balance_screen.dart
cloud_accounting_repository.dart / cloud_accounting_service.dart
accounting_sync_adapter.dart    = NOT created
permissions.dart change         = NOT made
new tests                       = NOT created
new RPCs                        = NOT created
sync adapter / transport change = NOT created
```

No implementation, no migration, no schema, no UI, no sync, no RPC, no tests that require implementation.

---

## G. Denylist Compliance

```text
D1 source redesign     = NONE
D3 reporting           = NONE (not started)
00036 / 00037 edits    = NONE
production deployment  = NONE
origin contact         = NONE
force push             = NONE
```

---

## H. Next Lawful Step

```text
1. Owner resolves D2-01..D2-07 explicitly (accept recommended defaults in one action is permitted).
2. A new owner-authorized D2 implementation session begins at section 8 of the D2 implementation contract.
3. Until then: IMPLEMENTATION_AUTHORIZED = NO.
```

---

## I. Remote-Lock Proof (post-push)

```text
POST_PUSH_LOCAL    =
POST_PUSH_TRACKING =
POST_PUSH_REMOTE   =
POST_PUSH_MERGE_BASE =
POST_PUSH_AHEAD    =
POST_PUSH_BEHIND   =
```