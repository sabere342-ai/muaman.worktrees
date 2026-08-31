# POST_PHASE_P_FREE_PLAN_BACKUP_RESTORE_PROOF_REPORT

## A. Session Result

```text
SESSION = FREE_PLAN_BACKUP_RESTORE_PROOF
RESULT  = PASS

SUCCESS_TOKEN =
PASS_FREE_PLAN_BACKUP_RESTORE_PROOF_LOCAL_READY

RESTORE_PROOF_LOCAL_CLOSURE = COMPLETE
RESTORE_PROOF_REMOTE_LOCK   = NOT_STARTED
```

This report proves that the already-generated official Supabase CLI logical backup
set can be restored into a safe, isolated, non-production recovery environment and
verified structurally, by row count, by RLS/tenant isolation, and by migration
baseline. All restore-proof acceptance cases (9-19) PASS. Migration 30 was NOT
deployed or applied anywhere as part of this proof.

## B. Repository Identity

```text
ROOT             = C:\dev\muaman.worktrees\i-tech-next-roadmap-freeze
BRANCH           = codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE = github
FETCH_URL        = https://github.com/sabere342-ai/muaman.worktrees.git
PUSH_URL         = https://github.com/sabere342-ai/muaman.worktrees.git
LEGACY_ORIGIN    = C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن
LEGACY_ORIGIN_USED    = NO
LEGACY_ORIGIN_MUTATED = NO
```

## C. Entry / Recovery Classification

```text
classification    = CASE_A_FRESH_RESTORE_PROOF
entry local head  = f7b9b031d5bc05cfaa78c22bc3f54e4dd12dc4aa
entry remote head = f7b9b031d5bc05cfaa78c22bc3f54e4dd12dc4aa
merge base        = f7b9b031d5bc05cfaa78c22bc3f54e4dd12dc4aa
ahead             = 0
behind            = 0
tracked/index     = CLEAN (only pre-authorised untracked sacred artifacts present)
```

Entry git state matched the expected baseline exactly (LOCAL = REMOTE =
`f7b9b031d5bc05cfaa78c22bc3f54e4dd12dc4aa`, AHEAD 0, BEHIND 0, no restore-proof
commit existed, tracked/index clean), classifying the session as
CASE_A_FRESH_RESTORE_PROOF.

## D. Governed Backup Identity

Backup directory (off-repository, Owner-controlled):

```text
C:\Users\saber\Backups\I-Tech-Store-Management\production\pre-migration-30\20260831_204142
```

| File              | Bytes  | SHA-256 (PRE == POST)                                            |
|-------------------|--------|------------------------------------------------------------------|
| roles.sql         |     370 | 168A95A9C745AF5ED4679751F90419AC9DC434240A213B03E32A06D5664C2308 |
| schema.sql        |  189824 | DE72E30C270114677F7AF8283B02E9254A2C8673FB004FAA9521C03C2B18EE08 |
| data.sql          |   31689 | 46D32A0DB1AC977B51BA621A6F22DF65C0972961C44E6E361F444ED74D9945DE |
| history_schema.sql|     887 | 18B99FBBB3EC9FBB964BB255A56171329ACD99B6977ECE2ADDD89FDF5AA5105B |
| history_data.sql  |  171015 | 9A24D34B9BE9D77C1EDF21C8C81CAC47FD17975BB9C1DE7AB2BFCE90946F9DAC |

All five artifacts: exist, byte size match, SHA-256 match, located outside the
repository, and are not tracked by Git.

```text
Supabase CLI version used for generation = 2.115.0
Supabase CLI version present this session = 2.115.0
Docker version this session             = 29.7.2
psql / Postgres client version          = 18.4
Recovery Postgres server version        = PostgreSQL 17.6 (supabase/postgres:17.6.1.159)
```

No SQL business-data contents are reproduced anywhere in this report.

## E. Recovery Environment

```text
environment class  = OPTION 2 - compatible isolated local Supabase environment using Docker
local/cloud        = LOCAL (Docker)
non-production     = YES
disposable         = YES (full destruction after verification)
Postgres version   = 17.6 (public.ecr.aws/supabase/postgres:17.6.1.159, via official local stack)
production target  = NO
recovery identity  = PURPOSE=FREE_PLAN_BACKUP_RESTORE_PROOF_ONLY, PRODUCTION=NO, DISPOSABLE=YES
```

The recovery environment was the official Supabase CLI local stack, provisioned
from a completely isolated OFF-REPOSITORY working directory
(`C:\Users\saber\AppData\Local\Temp\opencode\restore-proof`). The governed
repository's linked-project context / `.temp` was never used for any restore
operation. Target connection was exclusively the ephemeral local instance on
`127.0.0.1:54322`. No credentials are recorded here; connection used a temporary
non-productive local password held only in the process environment.

### Compatibility adjustments (official-documentation category, canonical immutable)

Governed restore required the following role/ownership compatibility adjustments,
all applied on the RECOVERY side or to a temporary DERIVED restore copy, never to
the canonical backup files:

1. roles.sql references the platform-admin parameter-SET grant
   (`GRANT SET ON PARAMETER log_min_messages TO supabase_realtime_admin`). This
   is an administrative grant that the local `postgres` superuser cannot perform
   under supautils; it was applied by running roles.sql under the platform admin
   role `supabase_admin` (the role that owns such grants), per the documented
   role/ownership workaround. Canonical roles.sql unchanged (byte-identical).
2. data.sql contains `COPY` blocks for `storage.buckets` and `storage.objects`
   that reference columns present in the newer production Storage schema
   (`versioning_status`, `archived_at`, `is_delete_marker`, `is_versioned`) but
   absent in the local stack's bundled Storage version. Per the official
   documented workaround for column mismatches, the two incompatible empty
   COPY blocks (both carry 0 rows in the snapshot) were commented out in a
   temporary DERIVED restore copy. Canonical data.sql unchanged (byte-identical).

Derived restore copy SHA-256 (recorded separately from canonical, retained only
during the offline session, then removed):

```text
data_derived.sql SHA-256 = 89478EE40B777F387F7906A0F49ED3A07C95A8D89EEC05D4CC80BF614D8AF687
```

The derived copy is NOT the canonical backup and was deleted during cleanup.

## F. Restore Results

Restore order and independent per-case result (official `psql` fail-fast syntax
`--single-transaction --variable ON_ERROR_STOP=1`):

```text
CASE 10 roles restore            = PASS   (exit 0)
CASE 11 schema restore           = PASS   (exit 0; extensions, RPCs, tables,
                                           constraints, indexes, policies, grants)
CASE 12 data restore             = PASS   (exit 0; auth + public business tables
                                           from DERIVED copy; documented storage
                                           column-compat adjustment)
CASE 13 migration-history restore= PASS   (exit 0 for history_schema.sql and
                                           history_data.sql; 18 migration records)
```

No restore error was hidden or accepted; every case used fail-fast transactional
behavior and a process exit code of zero plus independent verification.

## G. Restore Duration

```text
RESTORE_START_UTC = 2026-08-31T19:55:29Z
RESTORE_END_UTC   = 2026-08-31T19:58:19Z
RESTORE_DURATION_SECONDS = 170.97

MEASURED_RESTORE_DURATION_IS_NOT_GUARANTEED_RTO = YES
```

Measured evidence only. No general production RTO is asserted.

## H. Row Count Evidence

Source snapshot counts derived OFFLINE from the canonical `data.sql` COPY blocks
(no production query). Restored counts from the RECOVERY database only.

| schema.table                    | backup snapshot | restored | result |
|---------------------------------|-----------------|----------|--------|
| auth.users                      | 6               | 6        | MATCH  |
| auth.identities                 | 6               | 6        | MATCH  |
| auth.sessions                   | 7               | 7        | MATCH  |
| auth.mfa_amr_claims             | 7               | 7        | MATCH  |
| auth.refresh_tokens             | 7               | 7        | MATCH  |
| auth.audit_log_entries          | 0               | 0        | MATCH  |
| public.shops                    | 2               | 2        | MATCH  |
| public.devices                  | 1               | 1        | MATCH  |
| public.licenses                 | 2               | 2        | MATCH  |
| public.activations              | 1               | 1        | MATCH  |
| public.cloud_customers          | 0               | 0        | MATCH  |
| public.cloud_expense_categories | 0               | 0        | MATCH  |
| public.cloud_expenses           | 0               | 0        | MATCH  |
| public.cloud_products           | 4               | 4        | MATCH  |
| public.cloud_inventory_count    | 0               | 0        | MATCH  |
| public.cloud_invoices           | 0               | 0        | MATCH  |
| public.cloud_migration_ledger   | 0               | 0        | MATCH  |
| public.cloud_returns            | 0               | 0        | MATCH  |
| public.cloud_sales              | 2               | 2        | MATCH  |
| public.cloud_shop_settings      | 0               | 0        | MATCH  |
| public.invitations              | 1               | 1        | MATCH  |
| public.permission_audit_log     | 0               | 0        | MATCH  |
| public.roles                    | 9               | 9        | MATCH  |
| public.role_permissions_cloud   | 31              | 31       | MATCH  |
| public.shop_members             | 2               | 2        | MATCH  |
| public.shop_permission_overrides| 0               | 0        | MATCH  |
| public.sync_log                 | 1               | 1        | MATCH  |
| supabase_migrations.schema_migrations | 18       | 18       | MATCH  |

Every represented table matches exactly. No customer/business row contents are
shown.

## I. Structural / RLS / RPC Verification

Verified against system catalogs of the RESTORED database:

- Critical tables present (21 public tenant tables) including shops, shop_members,
  licenses, devices, activations, cloud_products, cloud_sales, cloud_customers,
  cloud_expenses, cloud_inventory_count, cloud_invoices, cloud_returns, roles,
  role_permissions_cloud, sync_log, shop_permission_overrides, invitations,
  permission_audit_log, cloud_migration_ledger, cloud_shop_settings,
  cloud_expense_categories.
- RLS enabled (`relrowsecurity = t`) on all tenant tables.
- Primary keys on all critical tables.
- Foreign keys resolved: shop_members.shop_id -> shops.id,
  shop_members.user_id -> auth.users.id, shops.owner_user_id -> auth.users.id,
  devices.user_id -> auth.users.id, devices.shop_id -> shops.id,
  activations.device_id -> devices.id, activations.license_id -> licenses.id,
  licenses.shop_id -> shops.id, cloud_products.shop_id -> shops.id,
  cloud_sales.shop_id -> shops.id, cloud_sales.invoice_id -> cloud_invoices.id,
  cloud_customers.shop_id -> shops.id, roles.shop_id -> shops.id,
  role_permissions_cloud.role_id -> roles.id, sync_log.shop_id -> shops.id, etc.
- Unique constraints: uniq_cloud_products_shop_barcode, licenses_license_key_key,
  role_permissions_cloud_role_id_permission_id_key, roles_shop_id_name_key,
  shop_members_shop_id_user_id_key, sync_log_idempotency_key_key.
- CHECK constraints present (e.g., chk_cloud_products_cost_price,
  chk_cloud_products_opening_qty, chk_cloud_sales_qty, chk_cloud_expenses_amount,
  shop_members_status_check, shop_members_role_check, activations/licenses/devices
  status checks).
- Indexes present incl. idx_shop_members_shop_id, idx_shop_members_user_id,
  idx_shop_members_shop_user, idx_cloud_products_shop_id,
  idx_cloud_products_updated_at, idx_cloud_sales_shop_id,
  idx_cloud_sales_invoice_id, idx_licenses_license_key, idx_licenses_shop_id,
  idx_devices_shop_id, idx_sync_log_idempotency.
- RLS policies: every tenant table has its isolation policy; `shop_member_isolation`
  present on shop_members (non-recursive; does not reference shop_members).
- Critical RPCs/functions present:
  - Migration 28 Phase-M: phase_m_idempotency_lookup, phase_m_idempotency_record,
    phase_m_oversell_guard(p_available int, p_requested int, p_allow_oversell bool).
  - Migration 28 *_v2: create_cloud_sale_with_stock_v2,
    create_cloud_invoice_with_items_v2, create_cloud_return_with_stock_v2,
    save_cloud_inventory_count_v2, delete_cloud_sale_with_revert_v2,
    delete_cloud_return_with_revert_v2.
  - Migration 29: get_user_shop_ids() SECURITY DEFINER.
  - require_shop_permission() SECURITY DEFINER with search_path=public.
  - Plus get_user_shops(), verify_shop_membership(), verify_license_entitlement(),
    check_effective_permission(), get_effective_permissions(), sync_upsert_entity(),
    create_cloud_sale_with_stock (non-v2), etc.

Objects were verified to exist in the RESTORED DATABASE (system catalogs), not by
grep over the SQL files.

## J. shop_members / Tenant Isolation

### Integrity (aggregate only, no identities)

```text
total   memberships       = 2
ACTIVE  memberships       = 2
orphan shop_id references = 0
orphan user_id references = 0
invalid/null required identity references = 0
```

### Dynamic tenant isolation matrix (RECOVERY database only, anonymous labels only)

```text
USER_A -> own  ACTIVE shop (shop_members)     = ALLOWED (1 row)
USER_A -> unrelated shop     (shop_members)   = DENIED  (0 rows)
USER_A -> own  shop (cloud_products)          = ALLOWED (2 rows)
USER_A -> unrelated shop (cloud_products)     = DENIED  (0 rows)

USER_B -> own  ACTIVE shop (shop_members)     = ALLOWED (1 row)
USER_B -> unrelated shop     (shop_members)   = DENIED  (0 rows)
USER_B -> own  shop (cloud_products)          = ALLOWED (2 rows)
USER_B -> unrelated shop (cloud_products)     = DENIED  (0 rows)

anonymous / no auth identity -> shop_members  = 0 rows
anonymous / no auth identity -> cloud_products= 0 rows
anonymous / no auth identity -> shops         = 0 rows
anonymous / no auth identity -> licenses/devices/cloud_sales = 0 rows
```

Cross-tenant access is verifiably not exposed. shop_members isolation is enforced
via the non-recursive Migration 29 policy (`shop_id = ANY(get_user_shop_ids())
AND status='ACTIVE'`); a representative tenant business table (cloud_products)
is verified isolated; anonymous has no tenant exposure. Test used the restored
snapshot's own safe multi-tenant fixtures (labels only) inside a rollback-only
transaction; no production data beyond the snapshot was used.

## K. Migration History

```text
MIGRATION_28 (20260820000028) = PRESENT  (name: phase_m_inventory_conflict_hardening)
MIGRATION_29 (20260820000029) = PRESENT  (name: fix_shop_members_rls_recursion)
MIGRATION_30 (20260820000030) = ABSENT   (not represented as applied)
```

Schema reality is consistent with that history: Migration 28 Phase-M hardened
objects and `*_v2` RPCs are present; Migration 29's `get_user_shop_ids()` and
`shop_member_isolation` non-recursive policy are present; Migration 30-only
objects (cloud_stock_adjustments table and stock-adjust RPCs) are absent
(0 occurrences). No baseline mismatch.

## L. Recovery Cleanup

```text
recovery environment destroyed  = YES (containers stopped, supabase volumes/data removed)
temporary credentials removed    = YES (off-repository temp secrets/session removed)
temporary derived SQL copy removed = YES
canonical backup preserved       = YES (immutable, byte-identical)
RECOVERY_ENVIRONMENT_ACTIVE      = NO
TEMPORARY_SECRET_FILES           = NONE
```

Full off-repository recovery workspace was removed after verification. Canonical
backup directory/SQL files, repository, staging environment, and production were
NOT deleted.

## M. Production Safety

```text
production database contact = NO
production SQL              = NO
production DDL              = NO
production DML              = NO
production mutation         = NO
Migration 30 deployment     = NO
drain activation            = NO
production schema mutation  = NO
production data mutation    = NO
```

The only remote action was `git fetch github` against the authorized GitHub
remote (not a production database operation). Source counts were derived offline
from the canonical backup; production was never queried.

## N. Sacred Artifact Verification (PRE == POST)

```text
MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md
3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07   PRE == POST  PASS

SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md
C8C5BD867E59E606B1B09A63FD2D93057DE380CEB00A4866C567A4F7E6781733   PRE == POST  PASS

delivery/I-TECH-Delivery-v1.0.0.zip
70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418   PRE == POST  PASS
```

`supabase/.temp/` preserved untouched.

## O. Canonical Backup PRE/POST Hash Verification

All five canonical files recomputed after restore; all PRE == POST.

```text
CANONICAL_BACKUP_MUTATED = NO
```

| File               | PRE SHA-256 (== POST)                                            |
|--------------------|------------------------------------------------------------------|
| roles.sql          | 168A95A9C745AF5ED4679751F90419AC9DC434240A213B03E32A06D5664C2308 |
| schema.sql         | DE72E30C270114677F7AF8283B02E9254A2C8673FB004FAA9521C03C2B18EE08 |
| data.sql           | 46D32A0DB1AC977B51BA621A6F22DF65C0972961C44E6E361F444ED74D9945DE |
| history_schema.sql | 18B99FBBB3EC9FBB964BB255A56171329ACD99B6977ECE2ADDD89FDF5AA5105B |
| history_data.sql   | 9A24D34B9BE9D77C1EDF21C8C81CAC47FD17975BB9C1DE7AB2BFCE90946F9DAC |

## P. Acceptance Matrix CASES 1-20

```text
CASE 1  roles dump created successfully        = PASS (inherited from locked generation; reverified)
CASE 2  schema dump created successfully       = PASS (inherited; reverified)
CASE 3  data dump created successfully         = PASS (inherited; reverified)
CASE 4  migration history captured             = PASS (inherited; reverified)
CASE 5  backup artifacts non-empty             = PASS (inherited; reverified)
CASE 6  SHA-256 recorded                       = PASS (reverified PRE/POST)
CASE 7  off-repository                         = PASS (reverified)
CASE 8  no secret in governance evidence       = PASS (reverified)
CASE 9  safe non-production recovery env       = PASS (THIS SESSION)
CASE 10 roles restore                          = PASS (THIS SESSION)
CASE 11 schema restore                         = PASS (THIS SESSION)
CASE 12 data restore                           = PASS (THIS SESSION)
CASE 13 migration-history restore              = PASS (THIS SESSION)
CASE 14 row-count comparisons                  = PASS (THIS SESSION; exact)
CASE 15 RLS/policies/RPCs/constraints          = PASS (THIS SESSION)
CASE 16 shop_members + tenant isolation        = PASS (THIS SESSION; dynamic matrix)
CASE 17 Migration 28/29 baseline               = PASS (THIS SESSION)
CASE 18 recovery environment destroyed/secured= PASS (THIS SESSION)
CASE 19 production untouched                   = PASS (THIS SESSION)
CASE 20 retention location confirmed           = PASS (inherited + reverified)

CASES_1_TO_20 = PASS
RESTORE_PROOF_GATES = COMPLETE
```

## Q. Repository Mutation

```text
tracked files added   = 1
tracked files modified = 0
tracked files deleted  = 0

sole added file =
POST_PHASE_P_FREE_PLAN_BACKUP_RESTORE_PROOF_REPORT.md
```

## R. Prohibited Actions

```text
force push                        = NO
push of any kind                  = NO
tag creation                      = NO
history rewrite / rebase / reset --hard / amend = NO
clean -fd                         = NO
contact legacy origin             = NO
modify / stage / delete sacred artifacts = NO
modify / delete / regenerate canonical backup = NO
restore into production           = NO
production SQL / mutation / deploy= NO
Migration 29 live production probe= NO
Migration 30 deployment/application= NO
drain activation                  = NO
Group B/C/D start                 = NO
release / Android build           = NO
paid Supabase upgrade / PITR      = NO
overwrite existing staging/test project = NO
commit / print credentials        = NO
commit customer/business data     = NO
```

## S. Final Closure State

```text
PUSH_OCCURRED = NO
TAG_CREATED   = NO
FORCE_PUSH    = NO
```

Local closure only. A separate authorized session will perform the remote lock.

## T. Next Authorized Session

```text
NEXT_AUTHORIZED_SESSION =
FREE_PLAN_BACKUP_RESTORE_PROOF_REMOTE_LOCK
```

Do NOT start it from this session.
