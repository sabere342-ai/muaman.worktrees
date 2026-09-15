# PHASE_P_GATE_2_MIGRATIONS_36_37_38_PRODUCTION_RECONCILIATION_PLANNING_REPORT

> **Session:** `PHASE_P_GATE_2_MIGRATIONS_36_37_38_PRODUCTION_RECONCILIATION_PLANNING`
> **Session Class:** FORENSICS + READ-ONLY PRODUCTION VERIFICATION + PLANNING + GOVERNANCE ONLY
> **Generated:** 2026-09-15
> **Mandatory Entry HEAD:** `5c94a0dfecb4c45ffb461719ca80388684c6c55d`
> **Authorized remote:** `github` (only). `origin` MUST NOT be contacted.

---

## A. SESSION RESULT

```
RESULT_TOKEN =
PASS_PHASE_P_GATE_2_MIGRATIONS_36_37_38_PRODUCTION_RECONCILIATION_PLANNING_REMOTE_LOCKED
```

- This session performed **forensics, read-only Production verification, and planning only**.
- **ZERO Production mutations.** `PRODUCTION_MUTATION_COUNT = 0`.
- Migration 36 (`20260820000036`) is NOT applied to Production schema and NOT recorded in the Production ledger — VERIFIED.
- Migration 37 (`20260820000037`) is NOT applied to Production schema and NOT recorded in the Production ledger — VERIFIED.
- Migration 38 (`20260820000038`) is NOT applied to Production schema and NOT recorded in the Production ledger — VERIFIED.
- Migration 39 (`20260820000039`) is APPLIED to Production schema and RECORDED in the Production ledger — VERIFIED.
- Read-only Production schema/data analysis shows Migrations 36 → 37 → 38 are **safe to apply in that exact order** in a future owner-authorized execution session, **with documented preconditions** (notably: a fresh backup requirement and the 36→37 unguarded-function window handled by running both in one CLI push).
- Governance artifact created, committed (one normal commit), and pushed to `github`.
- Final repository state REMOTE_LOCKED. MANDATORY STOP reached. No successor started.

---

## B. REPOSITORY IDENTITY

| Item | Value | Status |
|------|-------|--------|
| Canonical Root | `C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze` | VERIFIED (`git rev-parse --show-toplevel`) |
| Linked Git Dir | `C:/dev/muaman/.git/worktrees/i-tech-next-roadmap-freeze` | VERIFIED (`git rev-parse --git-dir`) |
| Branch | `codex/i-tech-next-roadmap-freeze` | VERIFIED |
| Tracking Branch | `github/codex/i-tech-next-roadmap-freeze` | VERIFIED |
| Authorized Remote | `github` → `https://github.com/sabere342-ai/muaman.worktrees.git` | VERIFIED (`git remote -v`) |
| Forbidden Remote `origin` | Present in config as a legacy local path (`C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن`); **NOT contacted in this session** | VERIFIED |
| Product / repo identity | I Tech Store Management / `muaman_store` | VERIFIED |

`origin` was never contacted. Only `github` was used, and only via `git ls-remote` (no fetch mutation) for remote verification.

---

## C. ENTRY FORENSICS

| Field | Value | Status |
|-------|-------|--------|
| HEAD | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED — matches mandatory entry exactly |
| LOCAL SHA | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| TRACKING SHA | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` (`github/codex/i-tech-next-roadmap-freeze`) | VERIFIED |
| DIRECT_GITHUB SHA | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` (`git ls-remote github refs/heads/codex/i-tech-next-roadmap-freeze`) | VERIFIED |
| MERGE_BASE | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| AHEAD | 0 | VERIFIED |
| BEHIND | 0 | VERIFIED |
| Tracked modifications | NONE (`git status --porcelain` count = 0) | VERIFIED |
| Staged changes | NONE | VERIFIED |
| `MERGE_HEAD` | ABSENT | VERIFIED |
| `CHERRY_PICK_HEAD` | ABSENT | VERIFIED |
| `REVERT_HEAD` | ABSENT | VERIFIED |
| `BISECT_LOG` | ABSENT | VERIFIED |
| `rebase-merge` / `rebase-apply` | ABSENT | VERIFIED |
| `index.lock` | ABSENT | VERIFIED |
| Stash | `stash@{0}: WIP on codex/muaman-13-strict-july-workbook-data-migration: 283ff9d ...` — pre-existing, on a different branch, PRESERVED, untouched | VERIFIED |

### Untracked inventory (PRE-EXISTING, PRESERVED — not staged, not modified, not deleted)

```
Continue
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_ACTIVATION_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_LIVE_CRITERION_16_PRODUCTION_LEDGER_FORENSIC_CORRECTION_REMOTE_LOCK_REPORT.md
GROUP_A_PHASE_P_OD7_SYNC_DRAIN_OWNER_APPROVED_SPECIFIC_RELEASE_BUILD_ACTIVATION_EXECUTION_REPORT.md
GROUP_A_PHASE_Q_ANDROID_FINAL_RELEASE_IDENTITY_AND_SIGNING_CONFIGURATION_IMPLEMENTATION_FAILED_SESSION_REPORT.md
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
PHASE_P_GATE_2_EXISTING_CONFIRMED_AUTH_SIGNIN_LINKER_IMPLEMENTATION_REPORT.md
PHASE_P_GATE_2_EXISTING_OWNER_CLOUD_LINK_UI_IMPLEMENTATION_REPORT.md
PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_BLOCKED_PREFLIGHT_REPORT.md
PHASE_P_GATE_2_PRODUCTION_EXISTING_OWNER_IDENTITY_LINK_EXECUTION_PLAN.md
PHASE_P_GATE_2_PRODUCTION_IDENTITY_LINKAGE_READ_ONLY_RECONCILIATION_REPORT.md
PHASE_P_GATE_2_PRODUCTION_SIGNIN_LINKER_PREFLIGHT_REPORT.md
PHASE_P_GATE_2_UPDATED_ANDROID_BUILD_INSTALL_AND_REENTRY_PREFLIGHT_REPORT.md
PHASE_P_POST_GROUP_D_ANDROID_SIGNING_RECONCILIATION_IMPLEMENTATION.md
SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
delivery/I-TECH-Delivery-v1.0.0.zip
supabase/.branches/
supabase/.temp/
```

`supabase/.temp/start-secrets/` is present. Its **contents were NOT read** (secret-bearing sacred artifact). No `git clean`, no `reset --hard`, no restore, no stash operation was performed.

### Entry classification

```
CASE_A_FRESH
```
Tracked + index clean, head aligned, remote-locked, no active Git operation; pre-existing untracked preserved.

---

## D. REMOTE LOCK BEFORE

| Measurement | Value | Status |
|-------------|-------|--------|
| LOCAL | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| TRACKING | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| DIRECT_GITHUB | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| MERGE_BASE | `5c94a0dfecb4c45ffb461719ca80388684c6c55d` | VERIFIED |
| AHEAD | 0 | VERIFIED |
| BEHIND | 0 | VERIFIED |

`origin` not contacted. `github` verified only via `git ls-remote` (read-only; no fetch).

---

## E. PREDECESSOR AUTHORITY

Predecessor session: `PASS_PHASE_P_GATE_2_MIGRATION_39_LEDGER_ONLY_RECONCILIATION_EXECUTION_REMOTE_LOCKED`, recorded in `PHASE_P_GATE_2_MIGRATION_39_LEDGER_ONLY_RECONCILIATION_EXECUTION_REPORT.md`.

| Check | Result | Status |
|-------|--------|--------|
| Predecessor report artifact present in HEAD | YES | VERIFIED |
| Predecessor exit / this session mandatory HEAD `5c94a0d…` | HEAD | VERIFIED (git log: `5c94a0d docs: record migration 39 ledger reconciliation execution`) |
| Migration 39 ledger repair completed + remote-locked | YES (per predecessor report + re-verification below) | VERIFIED |
| Migration 39 schema APPLIED | YES — re-verified: `uq_shops_one_owner_shop` present; `resolve_owner_shop(text)` present (`SECURITY DEFINER`) | VERIFIED |
| Migration 39 ledger RECORDED | YES — re-verified: row `20260820000039` in `supabase_migrations.schema_migrations`; `migration list --linked` shows remote `20260820000039` | VERIFIED |
| Migrations 36/37/38 schema NOT_APPLIED | YES — re-verified (tables/functions ABSENT) | VERIFIED |
| Migrations 36/37/38 ledger NOT_RECORDED | YES — re-verified (absent from `schema_migrations`; remote blank in `migration list --linked`) | VERIFIED |
| No successor execution already occurred | YES — no execution evidence; all execution session artifacts absent | VERIFIED |
| Predecessor commits ancestors of HEAD | `5c94a0d`, `ae3c757`, `28c507b`, `13ee3cc`, `0d65c13`, `37d1efb`, `95d0e50` all ancestors (`git merge-base --is-ancestor` exit 0) | VERIFIED |
| This session authorized only for planning/forensics | YES (owner instruction; read-only scope) | VERIFIED |

Predecessor performed exactly ONE Production mutation (`supabase migration repair 20260820000039 --status applied --linked`); it is complete and NOT repeated here.

---

## F. MIGRATION FILES AND HASHES

| Migration | Exact filename (in `supabase/migrations/`) | Length (bytes) | SHA-256 (`Get-FileHash`) | Introduced by commit | Commit date |
|-----------|---------------------------------------------|----------------|--------------------------|----------------------|-------------|
| 36 | `20260820000036_phase_p_group_d_d1_cost_history.sql` | 5701 | `3A20248E18E42DC07D1479AD87FA8B341B89D650F003819364A189BA5A1165BE` | `0d65c13` "feat: implement Phase P Group D D1 cost change history" | 2026-09-04 |
| 37 | `20260820000037_phase_p_group_d_d1_security_remediation.sql` | 4256 | `78EB7EF7696A0925EF54BC3922C0320066D41B499C4419842FC164F41658C6BC` | `37d1efb` "fix: remediate Phase P Group D D1 workflow and RPC authorization" | 2026-09-04 |
| 38 | `20260820000038_phase_p_group_d_d2_opening_balances.sql` | 13071 | `3423DBF4D2ADCF833FCE552D0844F1A025899D8A823AA27692B67C5E50A67B79` | `95d0e50` "feat(D2): implement Phase P Group D D2 opening balances" | 2026-09-05 |
| (context) 39 | `20260820000039_phase_p_gate2_owner_shop_uniqueness.sql` | 3966 | (read completely; not hashed — context only) | `13ee3cc` | 2026-09-15 |

Migration files were read completely, statement-by-statement. **None were edited.**

Governance references: `docs/PHASE_P_GROUP_D_*` mark migrations 36/37/38 as **IMMUTABLE**. D1/D2/D3 planning governance confirms D1 (36+37) and D2 (38) are closed/immutable designs.

---

## G. MIGRATION 36 ANALYSIS — Cost History (`20260820000036_phase_p_group_d_d1_cost_history.sql`)

### Intended final schema (additive only)

**Table `cloud_cost_history`**
| Column | Type | Null | Default / Notes |
|--------|------|------|-----------------|
| id | uuid | NOT NULL | PK, `gen_random_uuid()` |
| shop_id | uuid | NOT NULL | FK → `shops(id)` ON DELETE CASCADE |
| product_id | uuid | NOT NULL | FK → `cloud_products(id)` ON DELETE RESTRICT |
| product_name | text | NOT NULL | snapshot |
| product_barcode | text | NOT NULL | snapshot |
| old_cost | numeric(12,2) | NOT NULL | CHECK `>= 0` (`chk_cloud_cost_history_old_cost`) |
| new_cost | numeric(12,2) | NOT NULL | CHECK `>= 0` (`chk_cloud_cost_history_new_cost`) |
| changed_at | timestamptz | NOT NULL | DEFAULT `now()` |
| changed_by | uuid | NULL | |
| created_at | timestamptz | NOT NULL | DEFAULT `now()` |

Table CHECK: `chk_cloud_cost_history_cost_diff` → `old_cost <> new_cost`.

**Indexes (4, `IF NOT EXISTS`)**: `idx_cloud_cost_history_shop(shop_id)`, `idx_cloud_cost_history_product(product_id)`, `idx_cloud_cost_history_barcode(product_barcode)`, `idx_cloud_cost_history_changed_at(changed_at DESC)`.

**RLS**: `enable row level security`; 3 `authenticated` policies (all shop-scoped via `shop_members sm` set membership with `auth.uid()`):
- `cloud_cost_history_owner_all` — FOR ALL, role `owner`, status `ACTIVE` (USING + WITH CHECK).
- `cloud_cost_history_employee_read` — FOR SELECT, role `employee`, status `ACTIVE`.
- `cloud_cost_history_employee_insert` — FOR INSERT, role `employee`, status `ACTIVE`.
- salesOnly: intentionally NOT covered (no accounting mutation power).

**Security DEFINER functions (3)** — all `SET search_path = public`:
- `insert_cloud_cost_history(p_shop_id uuid, p_product_id uuid, p_product_name text, p_product_barcode text, p_old_cost numeric, p_new_cost numeric, p_changed_by uuid DEFAULT NULL) RETURNS uuid`
- `get_cloud_cost_history_by_product(p_shop_id uuid, p_product_id uuid) RETURNS TABLE(...)`
- `get_cloud_cost_history_by_shop(p_shop_id uuid) RETURNS TABLE(...)`

**CRITICAL SECURITY NOTE**: The migration-36 versions of these functions do **NOT** call `require_shop_permission`. They are `SECURITY DEFINER` and — because migration 36 issues no `REVOKE`/`GRANT` — they inherit PostgreSQL's default `PUBLIC : EXECUTE` grant. This is the exact exposure Migration 37 was authored to remediate. See Section K / I.

### Dependencies on earlier migrations
- `shops` (migration 00), `cloud_products` (migration 25) — both VERIFIED PRESENT in Production.
- `shop_members` (migration 01) — VERIFIED PRESENT.
- No dependency on 37/38/39.

### Production vs repository comparison (object-by-object)
| Object | Expected (repository) | Production actual | Classification |
|--------|----------------------|-------------------|----------------|
| `cloud_cost_history` table | exists | ABSENT (`to_regclass → NULL`) | ABSENT |
| 3 functions | exist | ABSENT (0 rows in `pg_proc`) | ABSENT |
| 4 indexes | exist | ABSENT (name check → 0 rows) | ABSENT |
| 3 policies | exist | ABSENT (table absent) | ABSENT |
| RLS enabled | yes | N/A (table absent) | ABSENT |

```
MIGRATION_36_CURRENT_PRODUCTION_STATUS = NOT_APPLIED (schema) / NOT_RECORDED (ledger)
MIGRATION_36_SAFETY_CLASSIFICATION     = SAFE_WITH_PRECONDITIONS (must be followed by 37 within the same controlled execution; see I/K)
```

---

## H. MIGRATION 37 ANALYSIS — Security Remediation (`20260820000037_phase_p_group_d_d1_security_remediation.sql`)

### Intent
Corrective migration for Migration 36: `DROP` + re-`CREATE` the same three `cloud_cost_history` functions with `require_shop_permission` authorization, then tighten function EXECUTE grants.

### Objects — DROP + CREATE (function body only)
- `insert_cloud_cost_history(uuid, uuid, text, text, numeric, numeric, uuid)` — calls `require_shop_permission(p_shop_id, 'inventory.edit')` before INSERT.
- `get_cloud_cost_history_by_product(uuid, uuid)` — calls `require_shop_permission(p_shop_id, 'inventory.view')`.
- `get_cloud_cost_history_by_shop(uuid)` — calls `require_shop_permission(p_shop_id, 'inventory.view')`.

All three recreated with `SECURITY DEFINER`, `SET search_path = public`.

### Grants
- `REVOKE ALL ON FUNCTION ... FROM PUBLIC` for all three.
- `GRANT EXECUTE ON FUNCTION ... TO authenticated` for all three.

### Dependencies
- **Strictly depends on Migration 36**: the three `DROP FUNCTION IF EXISTS(…)` signatures must match functions created by 36. If 36 is absent, the DROPs are no-ops but the re-created functions reference the non-existent `cloud_cost_history` table (valid at DDL time for plpgsql, runtime failure only when called) — producing a dead/inconsistent surface. **37 must never be applied without 36 first.**
- Depends on `require_shop_permission(uuid,text)` (migration 24, canonically replaced by migration 34). VERIFIED PRESENT in Production with `RETURNS text` and gates (Section K).
- No dependency on 38/39.

### Production vs repository comparison
| Object | Expected (repository) | Production actual | Classification |
|--------|----------------------|-------------------|----------------|
| `insert_cloud_cost_history(uuid,uuid,text,text,numeric,numeric,uuid)` | exists w/ authz body | ABSENT | ABSENT |
| `get_cloud_cost_history_by_product(uuid,uuid)` | exists w/ authz body | ABSENT | ABSENT |
| `get_cloud_cost_history_by_shop(uuid)` | exists w/ authz body | ABSENT | ABSENT |
| Grants (REVOKE PUBLIC / GRANT authenticated) | applied | N/A (functions absent) | ABSENT |

```
MIGRATION_37_CURRENT_PRODUCTION_STATUS = NOT_APPLIED (schema) / NOT_RECORDED (ledger)
MIGRATION_37_SAFETY_CLASSIFICATION     = SAFE_AS_WRITTEN (strictly requires 36 first)
```

---

## I. MIGRATION 38 ANALYSIS — Opening Balances (`20260820000038_phase_p_group_d_d2_opening_balances.sql`)

### Intended final schema (additive only)

**Table `cloud_accounts`**
| Column | Type | Null | Default / Notes |
|--------|------|------|-----------------|
| id | uuid | NOT NULL | PK, `gen_random_uuid()` |
| shop_id | uuid | NOT NULL | FK → `shops(id)` ON DELETE CASCADE |
| name | text | NOT NULL | |
| account_type | text | NOT NULL | CHECK `chk_cloud_account_type` IN (`CASH`,`BANK`,`RECEIVABLE_SUMMARY`,`PAYABLE_SUMMARY`,`CAPITAL`) |
| created_at | timestamptz | NOT NULL | DEFAULT `now()` |
| created_by | uuid | NULL | |
| updated_at | timestamptz | NOT NULL | DEFAULT `now()` |
| deleted_at | timestamptz | NULL | soft delete |
| server_version | integer | NOT NULL | DEFAULT 0 |

**Indexes**: `idx_cloud_accounts_shop(shop_id)`, `idx_cloud_accounts_type(account_type)`, `idx_cloud_accounts_deleted(created_at … deleted_at IS NULL)`.

**Table `cloud_opening_balance_entries`**
| Column | Type | Null | Default / Notes |
|--------|------|------|-----------------|
| id | uuid | NOT NULL | PK, `gen_random_uuid()` |
| shop_id | uuid | NOT NULL | FK → `shops(id)` ON DELETE CASCADE |
| account_id | uuid | NOT NULL | FK → `cloud_accounts(id)` ON DELETE CASCADE |
| amount | numeric(12,2) | NOT NULL | CHECK `chk_ob_amount_nonneg` (`>= 0`) |
| effective_date | date | NOT NULL | |
| entry_kind | text | NOT NULL | CHECK `chk_ob_entry_kind` IN (`OPENING`,`ADJUSTMENT`,`CORRECTION`) |
| corrects_entry_id | uuid | NULL | FK → `cloud_opening_balance_entries(id)` ON DELETE SET NULL |
| correction_reason | text | NULL | |
| notes | text | NULL | |
| idempotency_key | text | NOT NULL | UNIQUE (inline) |
| created_by | uuid | NULL | |
| created_at / updated_at | timestamptz | NOT NULL | DEFAULT `now()` |
| server_version | integer | NOT NULL | DEFAULT 0 |

**Indexes**: `idx_cloud_ob_entries_shop`, `idx_cloud_ob_entries_account`, `idx_cloud_ob_entries_effective_date`, `idx_cloud_ob_entries_entry_kind`.

**RLS**: enabled on both tables; SELECT-only policies (`cloud_accounts_select`, `cloud_ob_entries_select`) for `authenticated` ACTIVE shop members (self-join on `shop_members` with `auth.uid()`). **No** direct INSERT/UPDATE/DELETE policies — all mutation is via SECURITY DEFINER RPCs (D2-06=B owner set/correct, owner+employee read, salesOnly denied).

**SECURITY DEFINER functions (5)** — all `SET search_path = public`, all call `require_shop_permission` first:
| Function | Args (identity) | Authz | Returns |
|----------|-----------------|-------|---------|
| `create_cloud_account` | `(uuid, text, text)` | `inventory.edit`; **owner-only**; validates account_type + non-empty name | uuid |
| `update_cloud_account` | `(uuid, uuid, text, text, boolean)` | `inventory.edit`; **owner-only**; soft delete via `p_deleted` | boolean |
| `list_cloud_accounts` | `(uuid)` | `inventory.view` | TABLE(...) |
| `create_cloud_opening_balance` | `(uuid, uuid, numeric, date, text, uuid, text, text, text)` | `inventory.edit`; **owner-only**; account-shop verification; rejects negative; CORRECTION requires `corrects_entry_id`; idempotency on `idempotency_key` (scoped shop+account+kind) | uuid |
| `list_cloud_opening_balances` | `(uuid, uuid)` | `inventory.view` | TABLE(...) |

**Grants**: REVOKE ALL on both tables AND all five functions FROM PUBLIC; GRANT EXECUTE on functions TO authenticated; REVOKE `INSERT, UPDATE, DELETE` on both tables FROM authenticated (defense-in-depth). No `anon` grants.

### Dependencies
- FK targets: `shops` (migration 00), self-referential `cloud_accounts`/`cloud_opening_balance_entries` (within 38).
- `require_shop_permission` (migrations 24/34) — PRESENT.
- Explicitly independent of 36/37 (comment: "D1 tables … are NOT touched"); does not touch 39 objects either.
- Authoring order (37 → 38) and possession of all required dependencies means 38 can run either after 36+37 or standalone; recommended linear order is 36 → 37 → 38.

### Production vs repository comparison
| Object | Expected (repository) | Production actual | Classification |
|--------|----------------------|-------------------|----------------|
| `cloud_accounts` table | exists | ABSENT (`to_regclass → NULL`) | ABSENT |
| `cloud_opening_balance_entries` table | exists | ABSENT (`to_regclass → NULL`) | ABSENT |
| 5 functions | exist | ABSENT (0 rows in `pg_proc`) | ABSENT |
| 7 indexes | exist | ABSENT (name check → 0 rows) | ABSENT |
| 2 policies / RLS / grants | exist | ABSENT (tables absent) | ABSENT |

```
MIGRATION_38_CURRENT_PRODUCTION_STATUS = NOT_APPLIED (schema) / NOT_RECORDED (ledger)
MIGRATION_38_SAFETY_CLASSIFICATION     = SAFE_AS_WRITTEN
```

---

## J. PRODUCTION SCHEMA COMPARISON (read-only)

Production target (re-verified):
```
PROJECT_REF  = ckruxrgppxxeqspxmyyd
NAME         = i-tech-production
REGION       = West EU (Ireland)
DATABASE     = postgres
LINKED       = ● (supabase projects list)
```

Tool used: `supabase db query --linked` with **strictly read-only SELECT/metadata statements**. No mutation was executed.

### Presence matrix (VERIFIED by query)
| Object | Production | Classification |
|--------|-----------|----------------|
| `cloud_cost_history` | NULL (`to_regclass`) | ABSENT |
| `cloud_accounts` | NULL | ABSENT |
| `cloud_opening_balance_entries` | NULL | ABSENT |
| `cloud_products` | PRESENT (`cloud_products`) | MATCH (36 FK target) |
| `shops` | PRESENT | MATCH |
| `shop_members` | PRESENT | MATCH |
| `roles` | PRESENT | MATCH |
| `licenses` | PRESENT | MATCH (37/38 authz path) |
| `role_permissions_cloud` | PRESENT | MATCH |
| `require_shop_permission(uuid,text)` | PRESENT, `SECURITY DEFINER`, `RETURNS text`, body byte-identical to migration 34 canonical | MATCH |
| `resolve_owner_shop(text)` (39) | PRESENT, `SECURITY DEFINER` | MATCH (39 already applied) |
| `uq_shops_one_owner_shop` (39) | PRESENT: `CREATE UNIQUE INDEX uq_shops_one_owner_shop ON public.shops USING btree (owner_user_id)` | MATCH |
| All 36/37/38 index names | ABSENT (only `uq_shops_one_owner_shop` returned) | ABSENT — no name collision |
| Any schema objects named `cloud_cost_history` / `cloud_accounts` / `cloud_opening_balance_entries` | ABSENT across all schemas (`pg_class` relkind r/p/v/m) | ABSENT |
| 36/37/38 policies | ABSENT (tables absent) | ABSENT |

`cloud_products` columns verified: `id uuid`, `shop_id uuid`, `name text NOT NULL`, `barcode text NOT NULL`, `cost_price numeric NOT NULL`, plus inventory counters — all FK/nullability-compatible with migration 36.

Permission catalog: `inventory.edit` and `inventory.view` BOTH PRESENT in `role_permissions_cloud` (mapped: owner 18 perms, employee 11, salesOnly 2). `check_effective_permission` and `s4_device_gate_enabled` functions PRESENT.

**No material conflict between repository SQL and Production for any object.**

---

## K. PRODUCTION DATA SAFETY ANALYSIS (read-only)

### Counts / relationships
| Measure | Value |
|---------|-------|
| shops | 3 |
| shop_members | 3 (all `role=owner`, `status=ACTIVE`) |
| distinct active users | 3 |
| owner memberships | 3 |
| cloud_products | 4 (across 2 shops) |
| production table inventory | 27 public tables (shops, shop_members, roles, role_permissions_cloud, cloud_products, cloud_sales, cloud_returns, cloud_invoices, cloud_expenses, cloud_expense_categories, cloud_customers, cloud_inventory_count, cloud_stock_adjustments, cloud_shop_settings, cloud_migration_ledger, licenses, devices, device_*, invitations, activations, plans, s4_enforcement_config, sync_log, shop_permission_overrides, permission_audit_log) |

Shop/owner distribution (per shop): 3 shops, exactly 3 roles per shop, exactly 1 ACTIVE owner member per shop, product counts 2/2/0.

### New-constraint risk against existing data
- Migrations 36/37/38 contain **no `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE` against existing tables** and **no backfill**. All new `NOT NULL`/`CHECK`/`UNIQUE`/`FK` constraints are created on **new, empty** tables.
- FK targets (`shops.id`, `cloud_products.id`) are valid `uuid` columns with existing rows — no orphan/type issue.
- Existing data therefore **cannot** violate any of the new constraints. Risk: NONE FOUND.

### Pre-existing anomalies (NOT caused by 36–38 and NOT blocking)
- `roles` contains 3 rows with `shop_id IS NULL` (owner/employee/salesOnly) in addition to the 9 properly scoped rows. Pre-existing; migrations 36–38 do not touch `roles`. Recorded here as data-hygiene observation only.
- `shop_members` has no employee/salesOnly members in Production today; 36/37/38 RLS and RPC authorization do not depend on such rows existing.

### Summary
```
PRODUCTION_DATA_COMPATIBILITY = PASS (read-only profiling; no constraint risk to existing data)
```

---

## L. DEPENDENCY GRAPH

```
39 (APPLIED)  ── independent of ──┐
                                 ├──► 36 ──► 37 ──► 38   (required execution order)
36 must precede 37  (STRICT: 37 re-creates 36's functions; 36 creates the table the functions reference)
38 independent of 36/37 but authored after; safe in the linear order 36→37→38
```

| Question | Answer |
|----------|--------|
| Can 37 run absent 36? | Technically the SQL executes (DROP IF EXISTS no-op; CREATE OR REPLACE creates functions), but it would produce functions referencing a missing `cloud_cost_history` — **degraded/invalid surface**. MUST NOT. |
| Can 38 run absent 36/37? | Yes (independent). Still executed in order for simplicity and auditability. |
| Can 36/37/38 run with 39 already present? | YES — no object/name/constraint collision (verified: `resolve_owner_shop`, `uq_shops_one_owner_shop` do not intersect any 36–38 object). |
| Does 39 conflict with 36–38 names? | No. `uq_shops_one_owner_shop` is on `shops(owner_user_id)`; 36–38 never touch that column or index. |
| Does any migration rely on historical schema that has since changed? | No. Dependencies (`shops`, `cloud_products`, `shop_members`, `require_shop_permission`) exist today in their current form. |
| Same intended schema as when authored? | YES — files immutable; Production dependency objects verified. |
| Functions overwritten by later migrations? | 36's 3 functions are overwritten by 37 (intended). 38's 5 functions are final. 39 does not overwrite any 36–38 function. |
| Any migration obsolete/superseded? | No. 36+37 together form the final D1 surface; 38 forms D2. |
| Partial-application tolerance? | Each migration is transactional under `db push`; a failing migration rolls back itself. Between migrations, `db push` fails closed (halt). The app is offline-first and reads local SQLite for these features, so a partially applied D1/D2 set does not break current app operation (functions are dormant server-side). See failure modes in Section T. |

```
DEPENDENCY_ORDER = 36 → 37 → 38  (only valid linear order)
MIGRATION_39_COMPATIBILITY = COMPATIBLE (no conflict)
```

---

## M. SQL STATIC SAFETY REVIEW

Run statement-by-statement. Only CREATE TABLE/INDEX/POLICY/FUNCTION, ALTER TABLE (ENABLE RLS + ADD CONSTRAINT), DROP FUNCTION (37), REVOKE/GRANT. **No destructive statements.** No TRUNCATE/DELETE/UPDATE. No column rewrites. No new NOT NULL on existing tables.

| Check | 36 | 37 | 38 |
|-------|----|----|----|
| `DROP` | none | targeted `DROP FUNCTION IF EXISTS` (3, exact signatures matching 36) | none |
| `TRUNCATE` / `DELETE` / `UPDATE` / `INSERT` | none | none | none |
| Table rewrites / column type changes | none | none | none |
| `NOT NULL` additions on existing tables | none | none | none |
| FK creation | on new table (shops, cloud_products) | — | on new tables (shops, self-ref) |
| Unique constraints | none standalone | — | `idempotency_key UNIQUE` (new empty table) |
| Index risks | empty/new table, non-blocking | — | empty/new tables, non-blocking |
| Locking risks | low (new objects) | low | low |
| Triggers | none | none | none |
| Recursive function behavior | none | none | none (self-retrieval in idempotency only) |
| SECURITY DEFINER | 3 functions, `search_path = public` | 3 functions, `search_path = public` | 5 functions, `search_path = public` |
| Missing `SET search_path` | no (all functions set it) | no | no |
| Overly broad grants | functions default PUBLIC EXECUTE (**until 37**) | PUBLIC revoked → authenticated only | PUBLIC revoked → authenticated only; table DML revoked |
| Assumption objects absent | `CREATE … IF NOT EXISTS` + policy create; objects verified absent | DROP IF EXISTS + CREATE OR REPLACE | `CREATE … IF NOT EXISTS` + policy create; objects verified absent |
| Idempotency | partial (`IF NOT EXISTS` on table/index; functions `CREATE OR REPLACE`) | partial (DROP IF EXISTS safe) | partial (`IF NOT EXISTS`); function-level idempotency-key logic at runtime |
| Transactional | yes (each migration its own transaction under `db push`) | yes | yes |
| Partial-application failure modes | rollback of the single file | rollback of the single file | rollback of the single file |

### Classifications
```
36 = SAFE_WITH_PRECONDITIONS
      PRECONDITION-1: 37 must be executed in the SAME controlled execution session immediately after 36
                       (36's SECURITY DEFINER functions are PUBLIC-executable and unguarded → cross-tenant
                        write/read exposure if 36 is left applied without 37).
      PRECONDITION-2: require fresh backup evidence before the session (Section Q).
37 = SAFE_AS_WRITTEN   (only when 36 has succeeded first)
38 = SAFE_AS_WRITTEN   (no preconditions beyond backup + verified absence)
```

**Window note**: the only security-sensitive interval is between Migration 36 commit and Migration 37 commit. The recommended single `db push` executes both back-to-back within seconds, minimizing this window. A human-checkpointed stop between 36 and 37 is **not** recommended because it extends the exposure window.

---

## N. APPLICATION COMPATIBILITY REVIEW

Evidence: full Dart sweep of `app/` (lib, test, integration_test) for all migration-36/37/38 objects; plus direct reading of `app/lib/repositories/cloud/cloud_accounting_repository.dart` and `app/lib/sync/sync_cloud_operations_transport.dart`.

### Migration 36/37 — `cloud_cost_history` + 3 functions
- **ZERO Dart call-sites.** No `.rpc('insert_cloud_cost_history'…)`, no `.rpc('get_cloud_cost_history_…')`, no `.from('cloud_cost_history')` anywhere in `app/`.
- The app maintains a **local-only** SQLite `cost_history` table (`app/lib/database/database_helper.dart` `_createCostHistoryTable`, `recordCostChange`, `getCostHistoryByProduct`, `getAllCostHistory`, `getCostHistoryByBarcode`), used by the product cost-change workflow. `app/lib/models/cost_history.dart` is a local mirror model.
- **Result:** current app behavior does NOT depend on 36/37 being applied. They unlock a server-side cost-history surface with no client consumer today.

### Migration 38 — `cloud_accounts` / `cloud_opening_balance_entries` + 5 functions
Call-sites (Dart):
| Surface | File:line | Contract |
|---------|-----------|----------|
| `list_cloud_accounts` | `cloud_accounting_repository.dart:20` | `{'p_shop_id': shopId}`; expects `shop_id,name,account_type,id,server_version` — matches 38 return table |
| `create_cloud_account` | `cloud_accounting_repository.dart:42` | `p_shop_id,p_name,p_account_type`; returns UUID string — matches |
| `update_cloud_account` | `cloud_accounting_repository.dart:74` | `p_shop_id,p_account_id[,p_name,p_account_type,p_deleted]`; returns bool — matches |
| `list_cloud_opening_balances` | `cloud_accounting_repository.dart:88` | `p_shop_id[,p_account_id]`; return fields match 38 — EXACT match |
| `create_cloud_opening_balance` | `cloud_accounting_repository.dart:138` | `p_shop_id,p_account_id,p_amount,p_effective_date,p_entry_kind[,p_corrects_entry_id,p_correction_reason,p_notes,p_idempotency_key]`; returns UUID — matches |
| Sync upserts | `sync_cloud_operations_transport.dart:287-312` | same RPC names + params (`SyncEntityType.account`, `openingBalanceEntry`) |
| Sync deletes | `sync_cloud_operations_transport.dart:360-361` | fail-closed (`CloudDataException` — no server delete surface) |
| Sync adapters | `sync/adapters/accounting_sync_adapter.dart` | `cloudTableName => 'cloud_accounts'` / `'cloud_opening_balance_entries'`, `requiredPermission => 'inventory.edit'` |

- **Model enum parity**: `AccountType` (`CASH/BANK/RECEIVABLE_SUMMARY/PAYABLE_SUMMARY/CAPITAL`) and `EntryKind` (`OPENING/ADJUSTMENT/CORRECTION`) match server CHECK values exactly.
- **Feature surface status**: `CloudAccountingService` exists but **no screen currently consumes it** (`opening_balance_screen.dart` writes to local SQLite only). The D2 cloud surface is dormant in the UI; sync for account/OB entries would currently fail with `CloudDataException` because the RPCs are absent — this is today's production state and is **fail-closed, data-safe**.
- **Latent app-side quirks (post-38, non-blocking, track for D2 feature work)**:
  - `getOpeningBalances` parses `corrects_entry_id` via `(e['corrects_entry_id'] as num?)?.toInt()` — server returns a UUID string; rows with a correction reference would trip a type cast. 
  - `accountId: 0` placeholder / `correctsEntryId: int.tryParse(uuid)` in local mapping.
  These are client-parsing issues, NOT migration blocker issues.

### Conclusion
```
APPLICATION_COMPATIBILITY = COMPATIBLE
- 36/37: no client dependency (server-only surface; dormant).
- 38:   repository + sync contracts exactly match the migration's RPC signatures.
- Production currently has feature code present but unusable for cloud sync of accounts/OB
  because 36–38 are absent → these migrations UNBLOCK that dormant functionality.
- No write testing performed against Production.
```

---

## O. RLS / SECURITY / TENANCY REVIEW

Multi-tenant model: tenant-owned tables carry `shop_id`; RLS filters via `shop_members` membership + `auth.uid()`; RPCs run `SECURITY DEFINER` and self-verify via `require_shop_permission`.

| Requirement | 36 | 37 | 38 |
|-------------|----|----|----|
| `shop_id` present on every tenant table | YES | (no tables) | YES |
| RLS enabled | YES (`cloud_cost_history`) | — | YES (both tables) |
| SELECT policy (shop-scoped) | employee_read | — | both tables SELECT-only (ACTIVE member) |
| INSERT policy | owner_all + employee_insert (shop-scoped) | — | none (RPC-only) |
| UPDATE / DELETE policy | none | — | none (RPC-only) |
| SECURITY DEFINER RPC authz | **NONE (remediated by 37)** | `require_shop_permission` (`inventory.edit` / `inventory.view`) | `require_shop_permission` + owner-only mutation checks |
| `auth.uid()` checks | in policies | in `require_shop_permission` | in `require_shop_permission` + `created_by` uses `auth.uid()` |
| shop-ownership check | policies only | via permission fn | via permission fn + account-shop verification before OB insert |
| Cross-shop leakage risk | HIGH if 36 left without 37 (unguarded SECURITY DEFINER); LOW after 37 | LOW | LOW (permission-gated; idempotency lookup scoped by `p_shop_id`) |
| `authenticated` grants | table policies exist but **no direct table GRANT** (policies inert unless grants added; D1 test expects table privileges = false — function-only surface) | EXECUTE granted to authenticated | EXECUTE granted to authenticated; table DML revoked |
| `anon` grants | none | none | none |
| PUBLIC | functions default-executable until 37 revokes | revoked | revoked |
| `search_path` | `public` on all functions | `public` | `public` |
| Privilege escalation | blocked by 37 (authz added) | none | none (`accounting.edit` owner check) |

Production `require_shop_permission`: VERIFIED live definition is the migration-34 canonical form (`RETURNS text`, membership check, dormant `s4_device_gate_enabled` switch OFF, entitlement/license check for non-`.view` perms, owner bypass before permission resolution). This is fully compatible with 37/38 `v_role := require_shop_permission(...)` and `IF v_role != 'owner'` usage.

```
RLS_SECURITY_RESULT = PASS (static/read-only analysis)
- Verified absence of all target objects and presence of required authorization dependencies.
- No write-based security testing performed against Production (not authorized).
- The single structural finding is the 36→37 unguarded-function window, mitigated by same-session execution.
```

---

## P. MIGRATION LEDGER ANALYSIS (Production)

Read-only state of `supabase_migrations.schema_migrations`:
- 25 recorded versions: `00,01,02,03,04,05,06,10,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,39`.
- **`20260820000036` ABSENT, `20260820000037` ABSENT, `20260820000038` ABSENT, `20260820000039` PRESENT** — confirms the unusual history `39 recorded/applied while 36–38 absent`.
- `supabase migration list --linked`: Local column shows 36/37/38/39; Remote column blank for 36/37/38, populated for 39. → exactly 3 pending.

### Implications
| Question | Answer |
|----------|--------|
| Can CLI safely execute missing 36→38 afterward? | YES — `db push` applies **all pending migrations in version order**; pending = exactly 36, 37, 38. |
| Command normally used | `supabase db push --linked` (with `--skip-vault`; see Section R). |
| Would CLI attempt only missing migrations? | YES — it compares local vs `schema_migrations` and applies only missing versions, in ascending version order. |
| Historical ordering constraint? | None found. CLI does not require monotonic application times. The ledger has no apply-order semantics beyond the version values. `--dry-run` exists to preview. |
| Ledger repair ever needed? | Not for the normal path: applying a migration inserts its ledger row automatically. Repair is only a fallback for exceptional failure analysis — NOT recommended or authorized. |
| Older missing versions applied after a newer applied version — supported? | VERIFIED-SUFFICIENT (CLI help/behavior for `db push` + `--dry-run`). Precise proof is deferred to the `--dry-run` step inside the future execution session. |
| Read-only planning command available? | `supabase db push --linked --skip-vault --dry-run` (mutates nothing) — RECOMMENDED as the first execution-session step. Also `supabase migration list --linked` (no mutation). |

```
LEDGER_RECONCILIATION_ANALYSIS = SOUND
- Executing 36→37→38 via db push is ledger-self-consistent; no repair required.
- No ledger string/mutation performed in this session.
```

---

## Q. SUPABASE CLI STATE

| Item | Value |
|------|-------|
| Installed CLI | `2.115.0` (VERIFIED via `supabase --version`) |
| Available version observed | `2.117.0` (update notice; NOT installed; not authorized for this session) |
| Install channel | npm global |
| CLI update performed | NO |

---

## R. BACKUP / RECOVERY REQUIREMENTS

- **No Production database backup/snapshot/PITR evidence exists as a verified artifact** (repo documentation only covers the app-local SQLite backup feature).
- The future execution session MUST obtain fresh backup evidence BEFORE executing 36:
  - A full database logical dump under the project's backup contract, and/or
  - A platform snapshot / PITR guarantee statement for `ckruxrgppxxeqspxmyyd`, captured and recorded as evidence before the first mutation.
- Creating a backup in the current session is **NOT authorized** (operational/billing surface outside this planning scope) — therefore backup evidence is recorded as `NOT VERIFIED / REQUIRED AS EXECUTION GATE`.
- Recovery posture: migrations 36/37/38 are **not safely reversible by `ALTER`** (dropping newly created objects is technically possible — `DROP TABLE cloud_cost_history / cloud_accounts / cloud_opening_balance_entries`, `DROP FUNCTION …`, `DROP POLICY`, plus a migration-history repair — but that is a bespoke remediation, not a built-in rollback). Therefore the authoritative recovery path is **restore-from-backup**, which is why fresh backup evidence is a hard gate.

---

## S. RECOMMENDED EXECUTION STRATEGY

### Strategy: AUTO-SEQUENTIAL gated push (recommended)

```
Phase 0  Read-only preconditions (owner-authorized execution session):
         - Re-verify entry forensics + remote lock + Production identity.
         - Verify fresh backup evidence (Section R) — HARD GATE.
         - Re-run read-only absence/ledger checks (tables/functions/indexes/policies ABSENT;
           ledger shows 36/37/38 NOT_RECORDED; data counters match Section K).
         - supabase migration list --linked  → exactly 36, 37, 38 pending.

Phase 1  Dry run (zero mutation):
         supabase db push --linked --skip-vault --dry-run
         → MUST print exactly: 20260820000036, 20260820000037, 20260820000038 (in that order).
         If it lists anything else, STOP and do not execute.

Phase 2  Authorized mutation (single command, applies 36→37→38 in version order):
         supabase db push --linked --skip-vault --include-all
         (--skip-vault: no vault-secret update; config.toml has no vault section anyway —
          stored as defense-in-depth.)
         The 36→37 window (unguarded PUBLIC-executable SECURITY DEFINER functions) is
         minimized to the seconds between the two files in the same CLI run.

Phase 3  Per-migration verification gates executed immediately after push (read-only),
         IN ORDER:
         GATE_36 → GATE_37 → GATE_38  (see Section T for exact checks).

Phase 4  Post-38 comprehensive verification (Section U).
```

### Why not a per-migration CLI stop
The installed CLI does not expose a "push only migration N" flag; `db push`/`migration up` apply the entire pending set. Honoring a human checkpoint between 36 and 37 would require executing SQL files individually and manually maintaining the ledger — rejected because it creates ledger-truth risk and extends the 36→37 exposure window. The recommended design therefore enforces **verification gates** (mandatory pass + fail-closed STOP) on the actual results of 36, then 37, then 38, rather than pauses between runs.

### Specified future authorization scope (recommended owner decision)
One controlled execution session covering **all three migrations** with mandatory per-migration verification gates — NOT migration-36-only, because leaving 36 without 37 would reproduce the very security exposure 37 was authored to close.

---

## T. PER-MIGRATION EXECUTION GATES, FAILURE / RECOVERY

### GATE_36 — after 36 applies
Read-only proof: `20260820000036` in `schema_migrations`; `to_regclass('public.cloud_cost_history')` non-null; 3 indexes present; RLS enabled; 3 policies present; 3 functions present. Then immediately proceed to GATE_37 verification within the same run (do NOT materially pause: exposure window).

### GATE_37 — must not begin (semantically: must pass) unless GATE_36 healthy
Read-only proof: 3 functions present with `require_shop_permission` bodies (`pg_get_functiondef` matches repository); PUBLIC EXECUTE revoked, `authenticated` EXECUTE granted (`PROACL` check); table unchanged.

### GATE_38 — must not begin unless GATE_36 + GATE_37 healthy
Read-only proof: both tables present; RLS enabled; 2 SELECT policies; 5 functions present with expected signatures; grants match (`PRIVILEGE` check: EXECUTE to authenticated, table DML revoked); `idempotency_key` UNIQUE constraint present; CHECK constraints present.

### Gate failure behavior (any gate)
```
STOP. 
- Do NOT auto-repair, do NOT re-run, do NOT rollback, do NOT continue to the next migration.
- Determine from the ledger exactly which of 36/37/38 actually committed.
- If 36 committed but 37 failed: the unguarded SECURITY DEFINER functions are exposed —
  record URGENT; do NOT leave unattended; report immediately and await authorization.
- Report evidence and await a new explicit Owner decision.
```

### Recovery paths (documented, not executed)
- **Full DB restore** from the pre-execution backup (authoritative; requires the backup gate to have been met).
- **Bespoke manual rollback** (drop created tables/functions/policies/indexes + single-version ledger repair) — technically possible, but NOT a built-in path and requires explicit authorization if ever needed. Do not claim an automatic rollback exists.

---

## U. POST-38 VERIFICATION PLAN (future; not executed here)

- **Ledger**: `schema_migrations` contains 36, 37, 38 (and pre-existing 39); `migration list --linked` fully aligned; exactly 0 pending.
- **Schema objects**: presence + definitions (`pg_get_functiondef` byte-compare vs repository SQL) for all 8 functions, 3 tables, 11 indexes, 2 unique/CHECK sets, 5 policies, RLS flags, grant sets.
- **`require_shop_permission`**: unchanged (byte-identical to migration-34 canonical) after 36–38.
- **Data integrity**: owner/shop/user/product counters unchanged vs Section K baseline; new tables contain 0 rows initially.
- **Security/tenancy**: no cross-shop leak in static policy review; PUBLIC has no EXECUTE on any new function/table; no `anon` grants; RLS enabled everywhere.
- **Application**: local `flutter test` regression for cost-history and opening-balance local paths; verify sync adapters resolve the now-present RPCs (no test writes to Production).
- **Restart / relogin / offline**: no app runtime dependency on the new server objects for local operation; no relogin requirement; no sync behavior change for entities other than account/OB (which now resolve instead of throwing `CloudDataException`).
- **Local stack**: apply 36→37→38 to the local Supabase stack and run `d1_cost_history_rls.test.sql` (note: `d2_opening_balances.test.sql` is STALE — it references `create_opening_balance`/`is_active` which differ from the shipped `create_cloud_opening_balance`/no-`is_active` schema; do not treat that stale file as acceptance evidence until corrected under a separate authorized task).
- **Future sync implications**: account/OB sync channels move from fail-closed to functional; reconciliation/conflict behavior unchanged for other entities.

---

## V. RELEASE / SUCCESSOR RESTRICTIONS

```
OD7_SYNC_DRAIN_ACTIVATED           = NO
RC_STARTED                         = NO
DELIVERY_STARTED                   = NO
PLAY_PRODUCTION_STARTED            = NO
FINAL_COMPREHENSIVE_RELEASE_VALIDATION_STARTED = NO

RELEASE_PROGRESSION_BEFORE_36_38_RECONCILIATION = NO
```
Default rule confirmed: the project MAY NOT proceed to OD7 Sync Drain, RC, Delivery, Android final productization, Play Production, or final comprehensive release validation until migrations 36–38 are reconciled and verified. Correctness > schedule. Nothing in this repository's authority overrides this default.

---

## W. EXACT FUTURE OWNER DECISION REQUIRED

The Owner must decide and authorize (in a separate execution session):

```
DECISION = APPROVE PRODUCTION RECONCILIATION EXECUTION FOR MIGRATIONS 36→37→38
SCOPE    = ONE controlled execution session:
           1) fresh backup evidence gate,
           2) supabase db push --linked --skip-vault --dry-run  (read-only confirmation),
           3) supabase db push --linked --skip-vault --include-all  (applies 36, 37, 38 in order),
           4) mandatory read-only GATE_36 / GATE_37 / GATE_38 verification,
           5) STOP on any gate failure (no auto-repair/rollback/continue),
           6) post-38 verification per Section U,
           7) governance commit + push to github + remote-lock proof.
EXCLUDED  = any other Production mutation, migration repair, sync drain, RC/Delivery/Play,
            app code/SQL/config changes, CLI upgrade.
```

---

## X. REPOSITORY MUTATION INVENTORY

| Action | Count |
|--------|-------|
| Governance report artifact created | 1 (`PHASE_P_GATE_2_MIGRATIONS_36_37_38_PRODUCTION_RECONCILIATION_PLANNING_REPORT.md`) |
| Normal governance commit | 1 (proposed: `docs: plan production reconciliation for migrations 36 37 38`) |
| Push to `github` | 1 (normal fast-forward) |
| Push to `origin` | 0 |
| Migration SQL / app code / config / dependencies / tests / generated files modified | 0 |
| Sacred/untracked artifacts modified | 0 (preserved) |

---

## Y. PRODUCTION MUTATION INVENTORY

```
PRODUCTION_MUTATION_COUNT = 0

MIGRATION_36_EXECUTED = NO
MIGRATION_37_EXECUTED = NO
MIGRATION_38_EXECUTED = NO
MIGRATION_36_LEDGER_REPAIRED = NO
MIGRATION_37_LEDGER_REPAIRED = NO
MIGRATION_38_LEDGER_REPAIRED = NO
MIGRATION_39_REEXECUTED = NO
APPLICATION_DATA_MUTATED = NO
AUTH_MUTATED = NO
RLS_MUTATED = NO
SYNC_DRAIN_ACTIVATED = NO
RC_STARTED = NO
DELIVERY_STARTED = NO
PLAY_PRODUCTION_STARTED = NO
```

All read-only Production accesses used `supabase db query --linked` / `supabase migration list --linked` with SELECT/READ metadata only.

---

## Z. FINAL STOP DECLARATION

This planning/forensic session is complete and remote-locked.

```
MIGRATION_36_EXECUTED        = NO
MIGRATION_37_EXECUTED        = NO
MIGRATION_38_EXECUTED        = NO
SUCCESSOR_STARTED            = NO
OD7_SYNC_DRAIN_ACTIVATED     = NO
RC_STARTED                   = NO
DELIVERY_STARTED             = NO
PLAY_PRODUCTION_STARTED      = NO
MANDATORY_STOP_REACHED       = YES
```

**STOP.** Migrations 36/37/38 must NOT be executed, their ledger entries must NOT be repaired, no successor may begin, sync drain / RC / Delivery / Play Production must NOT start — until the Owner explicitly authorizes the execution session defined in Sections R, S, T, U.