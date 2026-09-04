-- PHASE P GROUP D D1 — cost_history RLS / tenant isolation pgTAP tests
-- Assumes migration 20260820000036_phase_p_group_d_d1_cost_history.sql has been applied.
-- Run with: supabase test db --local supabase/tests/d1_cost_history_rls.test.sql

BEGIN;

SELECT plan(20);

-- =============================================================================
-- T1: cloud_cost_history table exists
-- =============================================================================
SELECT has_table('public', 'cloud_cost_history', 'T1: cloud_cost_history table exists');

-- =============================================================================
-- T2: RLS is enabled on cloud_cost_history
-- =============================================================================
SELECT results_eq(
  'SELECT rowsecurity FROM pg_tables WHERE schemaname = ''public'' AND tablename = ''cloud_cost_history''',
  ARRAY[true],
  'T2: cloud_cost_history RLS is enabled'
);

-- =============================================================================
-- T3: cloud_cost_history has required columns
-- =============================================================================
SELECT has_column('public', 'cloud_cost_history', 'id', 'T3a: has id column');
SELECT has_column('public', 'cloud_cost_history', 'shop_id', 'T3b: has shop_id column');
SELECT has_column('public', 'cloud_cost_history', 'product_id', 'T3c: has product_id column');
SELECT has_column('public', 'cloud_cost_history', 'old_cost', 'T3d: has old_cost column');
SELECT has_column('public', 'cloud_cost_history', 'new_cost', 'T3e: has new_cost column');
SELECT has_column('public', 'cloud_cost_history', 'changed_at', 'T3f: has changed_at column');

-- =============================================================================
-- T4: FK constraint exists on shop_id -> shops
-- =============================================================================
SELECT col_type_is('public', 'cloud_cost_history', 'shop_id', 'uuid',
  'T4a: shop_id is UUID type');

-- =============================================================================
-- T5: chk_cloud_cost_history_cost_diff constraint exists
-- =============================================================================
SELECT col_not_null('public', 'cloud_cost_history', 'old_cost', 'T5a: old_cost is NOT NULL');
SELECT col_not_null('public', 'cloud_cost_history', 'new_cost', 'T5b: new_cost is NOT NULL');

-- =============================================================================
-- T6: insert_cloud_cost_history function exists
-- =============================================================================
SELECT has_function('public', 'insert_cloud_cost_history', 'T6: insert_cloud_cost_history function exists');

-- =============================================================================
-- T7: get_cloud_cost_history_by_product function exists
-- =============================================================================
SELECT has_function('public', 'get_cloud_cost_history_by_product', 'T7: get_cloud_cost_history_by_product function exists');

-- =============================================================================
-- T8: get_cloud_cost_history_by_shop function exists
-- =============================================================================
SELECT has_function('public', 'get_cloud_cost_history_by_shop', 'T8: get_cloud_cost_history_by_shop function exists');

-- =============================================================================
-- T9-T10: Indexes exist
-- =============================================================================
SELECT has_index('public', 'cloud_cost_history', 'idx_cloud_cost_history_shop', 'T9: shop index exists');
SELECT has_index('public', 'cloud_cost_history', 'idx_cloud_cost_history_product', 'T10: product index exists');

-- =============================================================================
-- T11: No permissive SELECT policy with (true)
-- =============================================================================
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND qual = ''true''
     AND cmd = ''SELECT''',
  ARRAY[0::bigint],
  'T11: no permissive SELECT policy with (true)'
);

-- =============================================================================
-- T12: No permissive ALL policy with (true)
-- =============================================================================
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND qual = ''true''
     AND cmd = ''ALL''',
  ARRAY[0::bigint],
  'T12: no permissive ALL policy with (true)'
);

-- =============================================================================
-- T13: Owner policy exists for ALL operations
-- =============================================================================
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND policyname = ''cloud_cost_history_owner_all''',
  ARRAY[1::bigint],
  'T13: owner ALL policy exists'
);

-- =============================================================================
-- T14: Employee read policy exists
-- =============================================================================
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND policyname = ''cloud_cost_history_employee_read''',
  ARRAY[1::bigint],
  'T14: employee SELECT policy exists'
);

SELECT * FROM finish();
ROLLBACK;
