# POST PHASE P — OWNER-GATED GROUP A — MIGRATION-30 PRODUCTION DEPLOYMENT GOVERNANCE

## A. Session Identity

| Field | Value |
|---|---|
| SESSION | `POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE` |
| SESSION_TYPE | `PRODUCTION_DEPLOYMENT_GOVERNANCE_ONLY` (read repository evidence, git fetch `github`, read-only forensics, define production gates / deployment / live-probe / rollback protocol, create ONE governance artifact, create ONE local governance commit). Does NOT deploy, push, tag, probe, drain, or build. |
| ROOT | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` |
| BRANCH | `codex/i-tech-next-roadmap-freeze` |
| AUTHORIZED_REMOTE | `github` (`https://github.com/sabere342-ai/muaman.worktrees.git`) |
| LEGACY_ORIGIN | `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` — READ-ONLY / UNAUTHORIZED (never fetched, pushed, pulled, renamed, deleted, or modified) |
| PURPOSE | Serialize the exact governed production-deployment and live-presence verification protocol for (1) Migration 30 (`20260820000030_phase_p_a4_cloud_stock_adjustments.sql`), (2) the Migration 28 production/live-presence criterion required by A8 criterion 16, and (3) the production verification gates that must succeed before any future P-OD7 drain activation. Govern only; no mutation of production. |

Authorized actions only:

```text
read repository evidence
git fetch github
read-only git forensics
read migration SQL
read previous deployment plans/reports
reason about deployment ordering
define production gates
define exact future deployment procedure
define exact live-probe procedure
define rollback/fail-stop protocol
create ONE governance artifact
create ONE local governance commit
```

## B. Entry / Recovery Classification

Read-only forensics were performed before any tracked mutation. Only `git fetch github` was issued against the authorized remote; the legacy `origin` was inspected read-only and never contacted.

```text
ROOT        = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze   ✓
BRANCH      = codex/i-tech-next-roadmap-freeze                     ✓
AUTHORIZED_REMOTE = github (fetch = push = https://github.com/sabere342-ai/muaman.worktrees.git)
LEGACY_ORIGIN = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن      (read-only / unauthorized)

LOCAL_HEAD  = f3aee657e7d59ce01c0c82906a274e2da66e0ddd
REMOTE_HEAD = f3aee657e7d59ce01c0c82906a274e2da66e0ddd  (github/codex/... after fetch)
MERGE_BASE  = f3aee657e7d59ce01c0c82906a274e2da66e0ddd
AHEAD       = 0
BEHIND      = 0
INDEX       = EMPTY
TRACKED WK  = CLEAN
UNTRACKED   = sacred trio + supabase/.temp/ only (preserved, never staged, never modified)
HEAD SUBJECT= Select post-Group-A Phase P successor
HEAD PARENT = 7feef87a3d49c2f0d9504d23352d37b700831efb
TAGS AT HEAD= none
```

**RECOVERY_CLASSIFICATION = `CASE_A_FRESH_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE`.**
Repository reality matches the expected locked handoff exactly. No local governance commit for this
session exists above `f3aee65` (no such commit present; remote has not advanced). No destructive
recovery (`git reset --hard`, `git clean -fd`, force checkout, history rewrite, force push) was
used or needed.

## C. Locked Predecessor State

```text
EXPECTED_HEAD   = f3aee657e7d59ce01c0c82906a274e2da66e0ddd
EXPECTED_SUBJECT= Select post-Group-A Phase P successor
EXPECTED_PARENT = 7feef87a3d49c2f0d9504d23352d37b700831efb
LOCAL = REMOTE = MERGE_BASE = f3aee657...
AHEAD = 0
BEHIND = 0
```

The Owner Decision remote-lock token is established by repository reality:

```text
PASS_POST_PHASE_P_OWNER_GATED_GROUP_A_OWNER_SUCCESSOR_SCOPE_DECISION_REMOTE_LOCKED = CONFIRMED
```

The canonical Owner-selected successor:

```text
CANONICAL_SUCCESSOR_SCOPE =
MIGRATION_30_PRODUCTION_DEPLOYMENT_AND_MIGRATION_28_LIVE_PRESENCE_GOVERNANCE

CANONICAL_SUCCESSOR_SESSION =
POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE
```

That Owner decision is not reopened or reinterpreted.

## D. Owner Authorization Chain

```text
OWNER_SELECTS = OPTION_A
```

meaning (verbatim from `POST_PHASE_P_OWNER_GATED_GROUP_A_OWNER_SUCCESSOR_SCOPE_DECISION.md` §E/F):

```text
MIGRATION_30_PRODUCTION_DEPLOYMENT_AND_MIGRATION_28_LIVE_PRESENCE_GOVERNANCE
```

The Owner selected this as the single canonical immediate next governed scope, because:

1. Migration 30 exists in the repository but remains undeployed.
2. Migration 30 contains the server-side P-OD1 / Option C durability half.
3. A8 criterion 16 still lacks a live production-presence probe.
4. Migration 28 live production presence must be confirmed.
5. `*_v2` RPC / `p_allow_oversell` production reality must be established.
6. Drain activation must not occur until this production evidence exists.
7. Deployment/probe governance provides the pragmatic prerequisite before later P-OD7 activation.
8. Group B/C/D remain legitimate Phase P work but are not the immediate canonical successor.

This session serializes the governance of that scope. It does not execute the deployment, the
live probe, or the drain.

## E. Governing Evidence Reviewed

Read directly from the locked repository tree (all read-only). Where a filename differs from the
prompt list, the actual repository reality is used and the discrepancy is noted.

| Document | Status at HEAD (`f3aee65`) |
|---|---|
| `PROJECT_MASTER_PLAN.md` | reviewed (Phase P is terminal; no Phase Q) |
| `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md` | reviewed (repository-approved deployment protocol) |
| `SUPABASE_DEPLOYMENT_MIGRATION_CORRECTION_PLAN.md` | reviewed (Gate-25 42P13 defect history) |
| `SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md` | reviewed (shop_members RLS recursion + invite-employee null user_id) |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | reviewed (17/17 production ledger as of 2026-08-27) |
| `PHASE_M_INVENTORY_CONFLICT_HARDENING_PLAN.md` | reviewed |
| `PHASE_P_PRODUCTION_HARDENING_PLAN.md` | reviewed |
| `PHASE_P_OWNER_DECISIONS.md` | reviewed (P-OD1 approved; P-OD7 conditionally authorized) |
| `POST_PHASE_P_OWNER_DECISIONS_GOVERNANCE_DETERMINATION.md` | reviewed (Groups A/B/C/D; final-closure conditions) |
| `PHASE_P_OWNER_GATED_GROUP_A_PLAN.md` | reviewed |
| `PHASE_P_OWNER_GATED_GROUP_A_IMPLEMENTATION_GOVERNANCE_DETERMINATION.md` | reviewed (A1..A8 order; migration/deployment boundary) |
| `PHASE_P_OWNER_GATED_GROUP_A_A8_EVIDENCE_GATE_CLOSEOUT_REPORT.md` | reviewed (criterion 16 = DOCUMENTED-EQUIVALENT, live-probe deferred) |
| `POST_PHASE_P_OWNER_GATED_GROUP_A_SUCCESSOR_SCOPE_GOVERNANCE_DETERMINATION.md` | reviewed (OUTCOME_F) |
| `POST_PHASE_P_OWNER_GATED_GROUP_A_OWNER_SUCCESSOR_SCOPE_DECISION.md` | reviewed (OPTION_A) |

SQL (all read directly, full forensic):

```text
supabase/migrations/20260820000028_phase_m_inventory_conflict_hardening.sql
supabase/migrations/20260820000029_fix_shop_members_rls_recursion.sql
supabase/migrations/20260820000030_phase_p_a4_cloud_stock_adjustments.sql
```

Plus cross-referenced dependencies in migrations 10 (shop_members RLS), 24 (`require_shop_permission`),
25 (`cloud_*` tables), 26 (`sync_log`), 20/27 (helper/legacy functions) as needed to establish the
dependency chain.

Repository reality governs over prompt prose. Actual production project identity was taken from
`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` §G and `supabase/.temp/` (linked
project), NOT invented.

## F. Migration 28 Contract

Migration 28 (`20260820000028_phase_m_inventory_conflict_hardening.sql`) is an ADDITIVE hardening
migration that establishes the idempotency/concurrency contract that Migration 30 preserves and
that A8 criterion 16 requires to be live in production. Required database identities (verified
from the SQL):

### F.1 Idempotency / concurrency helpers

| Identity | Signature | Purpose |
|---|---|---|
| `phase_m_idempotency_lookup` | `(p_idempotency_key TEXT) RETURNS JSONB` | Returns ORIGINAL success JSONB for an already-seen idempotency key, else NULL (short-circuits replays before any insert). |
| `phase_m_idempotency_record` | `(p_shop_id UUID, p_entity_type TEXT, p_entity_id UUID, p_operation TEXT, p_idempotency_key TEXT, p_status TEXT, p_details JSONB) RETURNS VOID` | Records a completed logical operation inside the caller's transaction; `INSERT INTO sync_log ... ON CONFLICT (idempotency_key) DO NOTHING`. |
| `phase_m_oversell_guard` | `(p_available INTEGER, p_requested INTEGER, p_allow_oversell BOOLEAN) RETURNS BOOLEAN` (IMMUTABLE, LANGUAGE sql) | `p_allow_oversell OR p_available >= p_requested`; used as the conditional-update predicate. |

### F.2 Required `*_v2` RPC identities (A8 criterion 16 list)

| Identity | Signature | Concurrency / idempotency |
|---|---|---|
| `create_cloud_sale_with_stock_v2` | `(p_shop_id UUID, p_barcode TEXT, p_quantity INTEGER, p_sale_price NUMERIC(12,2), p_date TIMESTAMPTZ, p_invoice_id UUID DEFAULT NULL, p_idempotency_key TEXT DEFAULT NULL, p_allow_oversell BOOLEAN DEFAULT FALSE) RETURNS JSONB` | `SELECT ... FOR UPDATE` row lock; conditional CAS `UPDATE cloud_products ... WHERE id = ... AND phase_m_oversell_guard(...) AND deleted_at IS NULL`; `IF NOT FOUND THEN RAISE EXCEPTION 'Concurrent modification detected, please retry'`; OC-1 replay via `phase_m_idempotency_lookup`. SECURITY DEFINER, `SET search_path = public`. |
| `delete_cloud_sale_with_revert_v2` | `(p_shop_id UUID, p_sale_id UUID, p_idempotency_key TEXT DEFAULT NULL) RETURNS JSONB` | `FOR UPDATE` row lock; `phase_m_idempotency_lookup` replay; revert-at-most-once (SR-3). |
| `create_cloud_return_with_stock_v2` | `(p_shop_id UUID, p_barcode TEXT, p_quantity INTEGER, p_sale_price NUMERIC(12,2), p_date TIMESTAMPTZ, p_idempotency_key TEXT DEFAULT NULL) RETURNS JSONB` | `FOR UPDATE`; replay lookup. |
| `delete_cloud_return_with_revert_v2` | `(p_shop_id UUID, p_return_id UUID, p_idempotency_key TEXT DEFAULT NULL) RETURNS JSONB` | `FOR UPDATE`; replay lookup; revert-at-most-once. |
| `save_cloud_inventory_count_v2` | `(p_shop_id UUID, p_product_id UUID, p_actual_quantity INTEGER, p_notes TEXT DEFAULT '', p_observed_at TIMESTAMPTZ DEFAULT NULL, p_idempotency_key TEXT DEFAULT NULL) RETURNS JSONB` | `FOR UPDATE`; IC-1..IC-5 causal ordering (latest-OBSERVED count wins); replay lookup. |
| `create_cloud_invoice_with_items_v2` | `(p_shop_id UUID, p_customer_name TEXT, p_payment_method TEXT, p_date TIMESTAMPTZ, p_sale_items JSONB, p_customer_id UUID DEFAULT NULL, p_idempotency_key TEXT DEFAULT NULL, p_allow_oversell BOOLEAN DEFAULT FALSE) RETURNS JSONB` | OC-5 invoice-level idempotency; per-item call into `create_cloud_sale_with_stock_v2`; `p_allow_oversell` forwarded per item. |
| `resolve_sync_conflict` | `(p_shop_id UUID, p_idempotency_key TEXT, p_resolution_method TEXT, p_resolution_note TEXT DEFAULT NULL) RETURNS JSONB` | Owner-only (`admin.settings.access`); updates sync_log resolution metadata. |

### F.3 `p_allow_oversell` contract

`p_allow_oversell BOOLEAN DEFAULT FALSE` appears explicitly in the signatures of:

```text
create_cloud_sale_with_stock_v2
create_cloud_invoice_with_items_v2
```

and is consumed by `phase_m_oversell_guard`. When FALSE (legacy), a sale requiring more than
available stock raises `Insufficient stock: available %, requested %` BEFORE any mutation. When
TRUE, the quantity predicate is lifted but the row lock + atomic recompute remain, so the
component equation (`current_quantity = opening_quantity - sold_quantity + returned_quantity +
inventory_adjustment`) always holds exactly.

### F.4 Row-lock / concurrency protection

`SELECT ... FROM cloud_products WHERE ... FOR UPDATE` is the row-lock serialization in every
stock-touching `*_v2` function. The conditional `UPDATE ... WHERE id = ... AND
phase_m_oversell_guard(...) AND deleted_at IS NULL` plus `IF NOT FOUND` is the compare-and-swap
guard detecting concurrent modification (fail-closed → `RAISE EXCEPTION 'Concurrent modification
detected, please retry'`). This is the "migration-28 concurrency contract" that Migration 30
explicitly preserves untouched.

ALL of the above are SECURITY DEFINER, `SET search_path = public`, and GRANTed to `authenticated`.

### F.5 A8 criterion 16 exact wording

From `PHASE_P_OWNER_GATED_GROUP_A_A8_EVIDENCE_GATE_CLOSEOUT_REPORT.md` §D row 16:

> Criterion 16 — Migration 28 production presence: `*_v2` RPCs and `p_allow_oversell` present in
> production schema. Production presence probe NOT executed here (no deploy; production SQL
> prohibited in A8) → **DOCUMENTED-EQUIVALENT** (owner/live-probe deferred to the owner-signed
> activation gate).

This governance serializes exactly what must be proved live in production to satisfy criterion 16
(see §M).

## G. Migration 29 Dependency State

Migration 29 (`20260820000029_fix_shop_members_rls_recursion.sql`) is the Gate-12 remediation for
the `shop_members` RLS infinite-recursion defect (Defect 1). It:

* creates `get_user_shop_ids()` (SECURITY DEFINER, `SET search_path = public`) returning the
  caller's ACTIVE shop_ids (fail-closed: empty for unauthenticated);
* `DROP POLICY IF EXISTS shop_member_isolation ON shop_members;` (removing the self-referential,
  recursive policy from Migration 10);
* re-creates `shop_member_isolation` as `shop_id = ANY(get_user_shop_ids()) AND status = 'ACTIVE'`.

Migration 29 does NOT depend on Migration 28, and Migration 28 does NOT depend on Migration 29.

### G.1 Why Migration 30 functionally depends on Migration 29 being live

Migration 30's RLS policy `shop_isolation_stock_adjustments` (below, §H.2) reads `shop_members`
directly in its `USING` clause:

```sql
EXISTS (SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_stock_adjustments.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE')
```

If Migration 29 is NOT live in production, the pre-existing recursive `shop_member_isolation`
policy from Migration 10 remains in force. A client-context evaluation of this `USING` predicate
would then trigger the documented infinite-recursion (SQLSTATE 42P17 "infinite recursion detected
in policy for relation shop_members"), matching the exact failure mode characterized in
`SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md` and `SUPABASE_PRODUCTION_POST_DEPLOYMENT_
VERIFICATION_REPORT.md` §N (`RLS_AUTHENTICATED_ISOLATION = PARTIAL` due to the pre-existing bug).

Although Migration 30 also `REVOKE ALL ON cloud_stock_adjustments FROM authenticated` (so the
policy is largely a defensive read guard and direct table access is blocked), correct, deterministic
`shop_members` reads required for proper tenant isolation ARE established by Migration 29's
recursion fix. For fail-closed governance, Migration 30 requires Migration 29 proven present.

### G.2 Production presence of Migration 29 is UNDOCUMENTED

`SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` (2026-08-27) records production at
17/17 = migrations `000000`..`000028`, and predates commit `a68a257` (2026-08-28) which created
Migration 29. Therefore **no repository evidence documents Migration 29 as deployed to
production**. Migration 29's live production presence MUST be live-verified before Migration 30
deployment is safe. This is the single most consequential unresolved precondition of this
governance.

## H. Migration 30 Contract

Migration 30 (`20260820000030_phase_p_a4_cloud_stock_adjustments.sql`) is the Phase P Group A A4
"server-side Option C durability" additive migration. Exact deployment effect, verified from SQL:

### H.1 Schema: `cloud_stock_adjustments`

| Aspect | Repository reality |
|---|---|
| Table | `cloud_stock_adjustments` (`CREATE TABLE IF NOT EXISTS`) |
| Tenant | `shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE` — row-level tenant scoping |
| Product linkage | `product_id UUID NOT NULL REFERENCES cloud_products(id) ON DELETE RESTRICT`; `barcode TEXT NOT NULL` |
| Financial linkage | `sale_id UUID REFERENCES cloud_sales(id) ON DELETE SET NULL`; `return_id UUID REFERENCES cloud_returns(id) ON DELETE SET NULL`; `invoice_id UUID REFERENCES cloud_invoices(id) ON DELETE SET NULL` |
| Auditability | `created_by UUID REFERENCES auth.users(id)`, `resolved_by UUID REFERENCES auth.users(id)`, `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `resolved_at TIMESTAMPTZ`, `deleted_at TIMESTAMPTZ`, `resolution_note TEXT` |
| Status model | `status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','RESOLVED'))` |
| Type model | `adjustment_type TEXT NOT NULL DEFAULT 'OVERSOLD' CHECK (adjustment_type IN ('OVERSOLD','MANUAL'))` |
| Numeric state | `projected_current INTEGER NOT NULL`; `shortfall INTEGER NOT NULL` with `CHECK (shortfall > 0)` |
| Idempotency | `idempotency_key TEXT`; `CONSTRAINT uniq_cloud_stock_adj_shop_key UNIQUE (shop_id, idempotency_key)` as a redundant second guard behind `phase_m_idempotency_lookup` |
| Indexes | `idx_cloud_stock_adj_shop_id (shop_id, created_at DESC)`, `idx_cloud_stock_adj_product_id (product_id)`, `idx_cloud_stock_adj_status (status)`, `idx_cloud_stock_adj_sale_id (sale_id)`, `idx_cloud_stock_adj_idempotency_key (idempotency_key)` — all `CREATE INDEX IF NOT EXISTS` |

### H.2 RLS

`ALTER TABLE cloud_stock_adjustments ENABLE ROW LEVEL SECURITY;` and one SELECT-only policy
`shop_isolation_stock_adjustments` (FOR SELECT TO authenticated, using the shop_members active
membership predicate). No INSERT/UPDATE/DELETE policy exists. Direct table access is fail-closed.

### H.3 Existing RPC replacement

`create_cloud_sale_with_stock_v2` is re-created with an **IDENTICAL signature/defaults/return
contract** (`(UUID, TEXT, INTEGER, NUMERIC(12,2), TIMESTAMPTZ, UUID, TEXT, BOOLEAN)`, `RETURNS
JSONB`, SECURITY DEFINER, `SET search_path = public`). The ONLY body change is an additive,
transactional OVERSOLD adjustment insert:

```sql
IF v_status = 'OVERSOLD' THEN
  INSERT INTO cloud_stock_adjustments (... ) VALUES (... ) ON CONFLICT DO NOTHING;
END IF;
```

The migration-28 concurrency contract (row lock `FOR UPDATE`, `phase_m_oversell_guard` CAS
predicate, `phase_m_idempotency_lookup`/`phase_m_idempotency_record`, exact replay) is preserved
verbatim. `p_allow_oversell` is retained in the signature and delegated to
`phase_m_oversell_guard`. Existing grants survive `CREATE OR REPLACE` (grant is signature-based).

### H.4 New owner-governed RPC surface (enumerated directly from SQL)

| Identity | Signature | Permission |
|---|---|---|
| `create_cloud_stock_adjustment` | `(p_shop_id UUID, p_product_id UUID, p_projected_current INTEGER, p_shortfall INTEGER, p_adjustment_type TEXT DEFAULT 'OVERSOLD', p_sale_id UUID DEFAULT NULL, p_return_id UUID DEFAULT NULL, p_invoice_id UUID DEFAULT NULL, p_notes TEXT DEFAULT NULL, p_idempotency_key TEXT DEFAULT NULL) RETURNS JSONB` | `require_shop_permission(p_shop_id,'admin.settings.access')` |
| `list_cloud_stock_adjustments` | `(p_shop_id UUID, p_status TEXT DEFAULT NULL, p_product_id UUID DEFAULT NULL, p_sale_id UUID DEFAULT NULL, p_limit INTEGER DEFAULT 200, p_offset INTEGER DEFAULT 0) RETURNS JSONB` | `require_shop_permission(p_shop_id,'admin.settings.access')` |
| `resolve_cloud_stock_adjustment` | `(p_shop_id UUID, p_adjustment_id UUID, p_resolution_note TEXT DEFAULT NULL) RETURNS JSONB` | `require_shop_permission(p_shop_id,'admin.settings.access')` |

All are SECURITY DEFINER, `SET search_path = public`. `create_*` and `resolve_*` enforce the
`p_shortfall > 0` / type-in-enum validation and tenant-scoped FK linkage (every supplied
sale/return/invoice must belong to `p_shop_id` — fail-closed, never ambient context).
`create_cloud_stock_adjustment` and (via `create_cloud_sale_with_stock_v2`) auto-recorded
adjustments use `phase_m_idempotency_lookup` / `phase_m_idempotency_record`.

### H.5 Security

```text
SECURITY DEFINER          = ALL four RPCs (create_cloud_sale_with_stock_v2 + 3 new owner RPCs)
search_path               = public (SET search_path = public) on every SECURITY DEFINER body
permission enforcement    = require_shop_permission(p_shop_id, 'sales.create' | 'admin.settings.access') server-side, fail-closed; UI is never the security authority
RLS                       = ENABLE ROW LEVEL SECURITY on cloud_stock_adjustments; SELECT-only policy; no INSERT/UPDATE/DELETE policy
GRANT / REVOKE            = GRANT EXECUTE ON the 3 new owner RPCs TO authenticated; REVOKE ALL ON cloud_stock_adjustments FROM authenticated (direct table access is revoked from authenticated; read/write surface is the owner-gated RPCs only)
tenant isolation          = shop_id row-level scoping verified in every RPC + policy
```

No `service_role` grant, no dynamic SQL, no `GRANT ALL ON`, no JWT handling within the migration
(matches the A8 no-secret-leak audit findings at §F of the A8 report).

## I. Production-State Classification Matrix

The future deployment execution session MUST classify production state deterministically before
any mutation, using live evidence (metadata inspection — never blind migration apply):

| Case | Production reality (live-verified) | Classification / disposition |
|---|---|---|
| PROD_CASE_A | Migrations 28 + 29 present, 30 absent | `EXPECTED_DEPLOYMENT_CASE` — potentially eligible for Migration 30 deployment after all preflight gates (§J) pass |
| PROD_CASE_B | Migration 30 already present | `VERIFY_ONLY` — do NOT reapply; require verification-only classification (no re-run, no repair) |
| PROD_CASE_C | Migration 28 absent | `BLOCKED_REQUIRED_MIGRATION_28_ABSENT` — Migration 30 must NOT be deployed until separately governed recovery establishes correct state |
| PROD_CASE_D | Migration 29 absent | `BLOCKED_REQUIRED_MIGRATION_29_ABSENT` — no blind Migration 30 apply; separate governed recovery required first |
| PROD_CASE_E | Migration history says present but required objects missing | `BLOCKED_PRODUCTION_SCHEMA_DRIFT` — no destructive repair |
| PROD_CASE_F | Objects exist but migration history inconsistent | `BLOCKED_PRODUCTION_MIGRATION_HISTORY_INCONSISTENCY` — no forced repair; separate recovery governance required |
| PROD_CASE_G | Unexpected future migrations already present | Determine whether they invalidate safe application of Migration 30; fail closed unless repository evidence proves compatibility |

Default safety law (applies always):

```text
NO DEPLOYMENT IF REQUIRED PREDECESSOR MIGRATIONS ARE NOT PROVEN PRESENT
```

Never propose "apply missing migrations blindly" as recovery. Unexpected production-history states
require forensic classification first.

## J. Deployment Preconditions

The future deployment execution session must prove ALL of the following before any mutation. If
project identity cannot be proved → `BLOCKED_PRODUCTION_PROJECT_IDENTITY_UNVERIFIED`, no
deployment.

```text
correct Supabase project identity           (name i-tech-production, ref ckruxrgppxxeqspxmyyd — match supabase status / supabase/.temp/linked-project.json / supabase projects list)
correct production project ref              (ckruxrgppxxeqspxmyyd — NOT staging ldkttyljtolnwlipjimb)
authenticated CLI/session identity          (supabase login / supabase status confirms authenticated)
no accidental local/dev/staging target      (never deploy while linked to a non-production project)
repository HEAD matches locked deployment-governance baseline
migration 30 file hash matches locked baseline
Migration 28 production presence            (live-verified; PROD_CASE_A and not C)
Migration 29 production presence            (live-verified; PROD_CASE_A and not D)
Migration 30 production absence             (PROD_CASE_A, not B)
required Migration-28 RPC signatures present(*_v2 set, §F.2)
p_allow_oversell signature present          (create_cloud_sale_with_stock_v2 + create_cloud_invoice_with_items_v2)
required helper functions present           (phase_m_idempotency_lookup, phase_m_idempotency_record, phase_m_oversell_guard, require_shop_permission)
production migration history coherent       (supabase migration list --linked coherent; no drift)
no unexpected drift                         (no unexpected future migrations, no schema drift)
backup/recovery posture confirmed           (pg_dump --schema-only/--data-only + dashboard backup verified; §15)
no secrets exposed                          (terminal transcripts redact; no secret values recorded)
required predecessor migrations proven present (Migration 28 and Migration 29)
```

No deployment while production is missing Migration 28 or Migration 29 (PROD_CASE_C / PROD_CASE_D).

## K. Future Deployment Execution Contract

Defines exactly what the later, separately-authorized production deployment SESSION may execute.
These are future instructions — NOT authorization for this session. This session performs NONE of
these operations.

```text
DEPLOY_TARGET = production Supabase project only (i-tech-production, ref ckruxrgppxxeqspxmyyd)
DEPLOY_SCOPE  = Migration 30 only, assuming migrations 1..29 already proven present
DEPLOY_METHOD = repository-approved Supabase migration mechanism (supabase db push / --linked,
                against the correctly linked production project, after full preflight §J)
```

Protocol commands (future session; repository-supported, see `SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md`
§7.18/Appendix C and the Gate-12 §M sequence), performed ONLY after §J all-PASS:

```text
supabase link --project-ref <prod-ref>                 # prod-ref = ckruxrgppxxeqspxmyyd
supabase status                                        # confirm identity
supabase migration list --linked                       # confirm pre-state (28 & 29 present, 30 absent)
supabase db push --linked                              # deploys Migration 30 (the only pending migration)
supabase migration list --linked                       # confirm Migration 30 recorded
```

NO MANUAL COPY/PASTE SQL unless explicitly required by a separately documented recovery case.
NO MIGRATION HISTORY REPAIR (`supabase migration repair`) unless separately governed —
`supabase migration repair` is explicitly forbidden by the correction plan (destroys clean-replay
guarantee) and is NOT authorized here.

The future session MUST discover exact flags via `supabase --help` / current Supabase docs rather
than assuming syntax from memory ("Do not assume command syntax from memory" — correction plan §11.3).

## L. Migration-30 Post-Deploy Verification

After the future deployment, exact checks MUST pass before the migration is considered provisioned.
Classification markers distinguish evidence types:

```text
SCHEMA_PRESENCE              = cloud_stock_adjustments table, expected columns/constraints/indexes
SECURITY_PRESENCE            = RLS enabled, policy exists, GRANT/REVOKE posture, SECURITY DEFINER + search_path
RPC_SIGNATURE_PRESENCE       = preserved create_cloud_sale_with_stock_v2 signature; p_allow_oversell present; 3 new owner RPCs present
MIGRATION_HISTORY_PRESENCE   = Migration 30 recorded in supabase_migrations.schema_migrations / migration list
BEHAVIORAL_VERIFICATION      = optional, controlled, read-only or non-mutating where sufficient (§N/O)
```

Require ALL of the following (read-only where possible):

```text
Migration 30 recorded in migration history
cloud_stock_adjustments table exists
expected columns exist            (page 1: shop_id, product_id, barcode, projected_current, shortfall, adjustment_type, sale_id, return_id, invoice_id, idempotency_key, status, resolution_note, resolved_by, resolved_at, created_by, created_at, deleted_at)
expected constraints exist         (PK, uniq_cloud_stock_adj_shop_key, chk_cloud_stock_adj_shortfall, FK to shops/cloud_products/cloud_sales/cloud_returns/cloud_invoices/auth.users)
expected indexes exist             (5 indexes, §H.1)
RLS enabled
expected RLS policy exists         (shop_isolation_stock_adjustments)
direct unauthorized mutation path is absent   (no INSERT/UPDATE/DELETE policy; REVOKE ALL ON cloud_stock_adjustments FROM authenticated)
existing create_cloud_sale_with_stock_v2 signature preserved  (UUID,TEXT,INTEGER,NUMERIC(12,2),TIMESTAMPTZ,UUID,TEXT,BOOLEAN)
p_allow_oversell still present     (in create_cloud_sale_with_stock_v2 and create_cloud_invoice_with_items_v2)
new Migration-30 owner RPCs exist  (create_cloud_stock_adjustment, list_cloud_stock_adjustments, resolve_cloud_stock_adjustment)
expected GRANT/REVOKE posture exists
SECURITY DEFINER posture matches locked SQL
search_path matches locked SQL     (public)
```

## M. Criterion-16 Live Probe Contract

The future live production-presence probe must establish production reality, not repository
existence. It MUST be READ-ONLY metadata inspection against the PRODUCTION project
(`ckruxrgppxxeqspxmyyd`), redacting secrets. It must prove:

```text
CREATE PROCEDURE/proc existence:
*_v2 functions exist in production       (create_cloud_sale_with_stock_v2, delete_cloud_sale_with_revert_v2,
                                          create_cloud_return_with_stock_v2, delete_cloud_return_with_revert_v2,
                                          save_cloud_inventory_count_v2, create_cloud_invoice_with_items_v2)
expected signatures exist                (via pg_proc / information_schema.routines)
p_allow_oversell exists in applicable signatures
required Migration-28 helpers exist       (phase_m_idempotency_lookup, phase_m_idempotency_record,
                                           phase_m_oversell_guard)
migration history contains Migration 28   (supabase_migrations.schema_migrations / migration list --linked)
```

Required probe primitives (read-only):

```text
SELECT proname, pg_get_function_identity_arguments(oid)
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('create_cloud_sale_with_stock_v2', 'delete_cloud_sale_with_revert_v2',
                  'create_cloud_return_with_stock_v2', 'delete_cloud_return_with_revert_v2',
                  'save_cloud_inventory_count_v2', 'create_cloud_invoice_with_items_v2',
                  'phase_m_idempotency_lookup', 'phase_m_idempotency_record', 'phase_m_oversell_guard');
SELECT version FROM supabase_migrations.schema_migrations ORDER BY version;
```

Binary result:

```text
CRITERION_16_LIVE_PROBE = PASS   (all required identities/signatures + migration history confirmed present in production)
CRITERION_16_LIVE_PROBE = FAIL   (any required identity absent, signature mismatch, or migration history gap)
```

Never convert partial evidence to PASS. Historical documentation (e.g., the 2026-08-27 report) is
NOT a substitute for a current live probe of production reality.

## N. Optional Controlled Behavioral Probe

Determination from repository governance:

| Verification technique | Classification |
|---|---|
| Read-only inspection of production catalog metadata (pg_proc, schema_migrations, information_schema) | `READ_ONLY_METADATA` — sufficient for criterion 16 and most §L checks |
| Read-only invocation of a non-mutating RPC that performs only SELECT (e.g., sanity `list_cloud_stock_adjustments` on a test/empty shop, no records created) | `READ_ONLY_RPC` — permitted ONLY under explicit separate authorization and only if provably non-mutating |
| Any probe creating business records (sales, invoices, stock movements, adjustments, users, audit entries) | `CONTROLLED_MUTATING_PROBE` — MUST NOT be casually executed; requires explicit separate authorization plus a cleanup/reconciliation law (§20) |
| Direct insert/update/delete against cloud_stock_adjustments / any business table for "testing" | `PROHIBITED` |
| Contained DB transaction (BEGIN; ... ROLLBACK;) non-committing sanity checks | `CONTROLLED_MUTATING_PROBE` if it acquires locks/writes, else `READ_ONLY` — requires review |

Prefer non-mutating (`READ_ONLY_METADATA`) evidence wherever sufficient, which it is for
criterion 16 and the Migration-30 post-deploy verification in §L/§M. Any mutating production test
requires separate explicit authorization and reconciliation law; none is authorized by this session.

## O. P-OD1 Completion Semantics

Migration 30 is the server-side P-OD1 Option C durability half (as recorded in the A4 migration
header and the successor-scope determination). It may be stated:

```text
P_OD1_SERVER_HALF = PRODUCTION_PRESENT
```

ONLY when ALL of the following hold (each independently verified live):

```text
Migration 30 applied
migration history confirmed
schema confirmed
RPC signatures confirmed
security posture confirmed
post-deployment verification PASS
```

Repository existence alone is NOT production completion. Current expected state is
`REPOSITORY_IMPLEMENTED / PRODUCTION_DEPLOYMENT_PENDING`.

## P. P-OD7 / Drain Boundary

This governance session does NOT activate the drain. Drain activation cannot become eligible until
required evidence succeeds:

```text
Migration 28 live presence = PASS
Migration 30 deployment    = PASS
Migration 30 post-deploy verification = PASS
A8 criterion 16            = PASS
required production RPC contract = PASS
no unresolved production schema drift
```

Even after all evidence:

```text
DRAIN_ACTIVATION_EXECUTOR = OWNER / RELEASE ONLY
```

and activation remains a separate governed action (release-build override
`--dart-define=SYNC_DRAIN_ENABLED=true` at `app/lib/config/app_config.dart`, executed only by the
owner/release at a dedicated governed gate). This session declares:

```text
DRAIN_ACTIVATED = NO
```

## Q. Failure / Recovery / Rollback Law

Migration 30 is additive but re-creates `create_cloud_sale_with_stock_v2` (replaces a function
body). Fail-stop behavior, by phase of failure:

| Failure phase | Behavior |
|---|---|
| Failure before migration transaction commits | Fail-stop; no schema change persisted; re-verify and retry after fix. Do NOT mark migration applied. |
| Failure during migration | `supabase db push` halts at the first error (Supabase executes migrations strictly sequentially). No later migration is applied. Re-verify; correct/clear the transactional failure (forward, not repair) per governing protocol. |
| Migration history recorded but object verification fails | `STOP`. Do NOT hand-edit history. Do NOT re-run destructively. Escalate as `BLOCKED_PRODUCTION_SCHEMA_DRIFT` / `BLOCKED_PRODUCTION_MIGRATION_HISTORY_INCONSISTENCY`; require separate recovery governance. |
| Migration applied but application contract fails | `AUTO-STOP` (deployment plan §7.15). Do not proceed. Forward recovery; rollback via restore if required. |
| Security/RLS verification fails | `STOP`; rollback doctrine per §7.20 (GATE 5 RLS fail → ROLL BACK). Restore from pre-deploy backup. |
| Unexpected schema drift discovered after apply | `STOP`; classify; no destructive repair. |

Transactional behavior: under `supabase db push`, each statement runs within the migration and the
migration is recorded atomically on the remote migration runner. Never assume arbitrary SQL is
safely reversible; most migrations are ADDITIVE, but some ALTER/replace functions. Rollback is
NOT a routine operation.

```text
ROLLBACK_METHOD = NEW FORWARD RECOVERY MIGRATION
```

unless repository evidence explicitly establishes another safe canonical approach (e.g., restore
from pre-deployment backup per §7.15). Never authorize:

```text
manual deletion of migration history
dropping production schema blindly
resetting production database
destructive Supabase reset on production
editing Migration 30 after deployment
renumbering migration files
force repair without governance
supabase migration repair (forbidden by correction plan)
```

## R. Groups B / C / D Boundary

```text
GROUP_B = DEFINED / NOT AUTHORIZED / NOT STARTED (this session does not plan or start Group B)
GROUP_C = DEFINED / NOT AUTHORIZED / NOT STARTED
GROUP_D = DEFINED / NOT AUTHORIZED / NOT STARTED
```

This session governs only Migration-30 production deployment + Migration-28 live presence. It does
NOT create any Group B/C/D plan, does NOT authorize them, and does NOT select ordering among them.
All remain legitimate Phase P work, unstarted.

## S. Phase P Final-Closure Boundary

Phase P final closure is NOT COMPLETE. It requires Groups A–D, drain activation, and production
deployment/verification. This session does NOT close Phase P and does NOT create a Phase Q (none
exists in the master roadmap; P is terminal). No Phase Q identity is invented.

## T. Prohibited Actions Audit

```text
implementation                    = NO
production connection             = NO
production deployment             = NO
Migration 30 apply                = NO
Migration 28 apply                = NO
Migration 29 apply                = NO
Supabase SQL mutation             = NO
supabase db push                  = NO
migration repair                  = NO
criterion-16 live probe           = NO
production behavioral probe       = NO
Edge Function deployment          = NO
drain activation                  = NO
SYNC_DRAIN_ENABLED=true           = NO
release build                     = NO
Android build/signing             = NO
Group B planning                  = NO
Group C planning                  = NO
Group D planning                  = NO
Phase P final closure             = NO
Phase Q creation                  = NO
merge                             = NO
rebase                            = NO
cherry-pick                       = NO
reset --hard                      = NO
git clean                         = NO
force checkout                    = NO
push                              = NO
force push                        = NO
tag creation/movement             = NO
legacy-origin network use         = NO
sacred artifact mutation          = NO
supabase/.temp cleanup            = NO
unrelated tracked mutation        = NO
```

## U. Sacred Artifact Verification

| Artifact | SHA-256 (PRE == POST) | Result |
|---|---|---|
| `MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md` | `3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07` | ✓ unchanged (PRE) |
| `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md` | `C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733` | ✓ unchanged (PRE) |
| `delivery/I-TECH-Delivery-v1.0.0.zip` | `70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418` | ✓ unchanged (PRE) |
| `supabase/.temp/` | untracked, unmodified, not staged (9 entries) | ✓ preserved |

POST hashes are re-computed after the local commit (§U in the final forensic report). PRE == POST
is required.

## V. Governance Determination

Repository evidence for the deployment semantics is coherent and resolvable. Deterministic outcome:

```text
GOVERNANCE_OUTCOME =
DEPLOYMENT_PROTOCOL_SERIALIZED

MIGRATION_30_DEPLOYMENT =
AUTHORIZED_ONLY_AFTER_GOVERNANCE_REMOTE_LOCK

CRITERION_16_LIVE_PROBE =
AUTHORIZED_ONLY_IN_LATER_GOVERNED_EXECUTION_SESSION

DEPLOYMENT_OCCURRED =
NO

LIVE_PROBE_OCCURRED =
NO
```

Critical unresolved precondition surfaced (not blocking serialization, but mandatory for the
deployment execution session): **Migration 29's production presence is UNDOCUMENTED and MUST be
live-verified** (PROD_CASE_D gate) before Migration 30 deployment. This does not prevent writing
the protocol; it makes the PROD_CASE_A eligibility conditional on live verification.

## W. Success Token

Minted only because: tracked worktree clean at entry, unexpected files unchanged (sole sacred/temp
untracked state), local history not divergent, remote not advanced, migration dependencies
resolved and serialized, governance protocol unambiguous, sacred hashes match, no deployment/live
probe performed.

```text
PASS_POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE_LOCAL_READY
```

## X. Next Authorized Session

The immediate next session MUST be the remote lock of this governance artifact, NOT production
deployment:

```text
NEXT_AUTHORIZED_SESSION =
POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE_REMOTE_LOCK
```

Only after that remote lock succeeds may a deployment execution session become eligible. The
recommended later deployment execution session identity (NOT authorized ahead of the remote-lock
gate), matching repository convention:

```text
POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT
```

```text
DEPLOYMENT_SESSION_STARTED = NO
LIVE_PROBE_SESSION_STARTED = NO
```

---

## Closure State

```text
SESSION                         = POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE
SESSION_RESULT                 = PASS (local ready)
GOVERNANCE_LOCAL_CLOSURE       = COMPLETE
GOVERNANCE_REMOTE_LOCK         = NOT_STARTED
RECOVERY_CLASSIFICATION        = CASE_A_FRESH_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE
OWNER_DECISION                 = SELECT_OPTION_A (confirmed)
CANONICAL_SUCCESSOR_SCOPE      = MIGRATION_30_PRODUCTION_DEPLOYMENT_AND_MIGRATION_28_LIVE_PRESENCE_GOVERNANCE
GOVERNANCE_OUTCOME             = DEPLOYMENT_PROTOCOL_SERIALIZED
PRODUCTION_STATE               = PENDING_GOVERNED_DEPLOYMENT
MIGRATION_30_DEPLOYED          = NO
CRITERION_16_LIVE_PROBE        = NOT PERFORMED
MIGRATION_29_PRODUCTION_PRESENCE = UNDOCUMENTED / MUST BE LIVE-VERIFIED (conditional gate)
DRAIN_ACTIVATED                = NO
P_OD1_SERVER_HALF              = REPOSITORY_IMPLEMENTED / PRODUCTION_DEPLOYMENT_PENDING
DEPLOYMENT_OCCURRED            = NO
LIVE_PROBE_OCCURRED            = NO
PUSH_OCCURRED                  = NO
TAG_CREATED                    = NO
LOCAL_CLOSURE_TOKEN            = PASS_POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE_LOCAL_READY
NEXT_AUTHORIZED_SESSION        = POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE_REMOTE_LOCK
```

---

## Execution Record (session-entered)

```text
ENTRY CLASSIFICATION = CASE_A_FRESH_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE
LOCKED_HEAD          = f3aee657e7d59ce01c0c82906a274e2da66e0ddd
DIFF PROFILE         = 1 added file (this artifact), 0 modified, 0 deleted
SACRED PRE  = 3D4D17… / C8C5BD… / 70F848…  ✓ (full values §U)
SACRED POST = (recorded after commit)
COMMIT      = (set after commit)
AHEAD/BEHIND= (1/0 after commit)
SESSION TOKEN = PASS_POST_PHASE_P_OWNER_GATED_GROUP_A_MIGRATION_30_PRODUCTION_DEPLOYMENT_GOVERNANCE_LOCAL_READY
```
