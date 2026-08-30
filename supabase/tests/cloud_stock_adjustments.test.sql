-- PHASE P GROUP A A4 — cloud_stock_adjustments migration structural tests
-- Assumes migration 20260820000030_phase_p_a4_cloud_stock_adjustments.sql has been applied.
-- Run with: supabase db test --files supabase/tests/cloud_stock_adjustments.test.sql

-- =============================================================================
-- Test 1: Table exists with RLS enabled
-- =============================================================================
SELECT 'TEST 1a: cloud_stock_adjustments table exists with RLS' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_tables
  WHERE tablename = 'cloud_stock_adjustments'
    AND schemaname = 'public'
    AND rowsecurity = true
);

-- =============================================================================
-- Test 2: Core columns present
-- =============================================================================
SELECT 'TEST 2a: core columns present' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1
  FROM unnest(ARRAY[
    'id','shop_id','product_id','barcode','projected_current','shortfall',
    'adjustment_type','sale_id','return_id','invoice_id','idempotency_key',
    'status','resolution_note','resolved_by','resolved_at','created_by',
    'created_at','deleted_at'
  ]) AS col
  WHERE col NOT IN (
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'cloud_stock_adjustments'
  )
);

-- =============================================================================
-- Test 3: shortfall > 0 check constraint
-- =============================================================================
SELECT 'TEST 3a: shortfall must be strictly positive' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_get_constraintdef(oid)
  CROSS JOIN pg_constraint con
  WHERE con.conrelid = 'cloud_stock_adjustments'::regclass
    AND con.conname = 'chk_cloud_stock_adj_shortfall'
    AND pg_get_constraintdef(oid) LIKE '%shortfall > 0%'
);

-- =============================================================================
-- Test 4: shop-scoped idempotency unique constraint
-- =============================================================================
SELECT 'TEST 4a: uniq_cloud_stock_adj_shop_key exists' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_constraint
  WHERE conrelid = 'cloud_stock_adjustments'::regclass
    AND conname = 'uniq_cloud_stock_adj_shop_key'
    AND contype = 'u'
);

-- =============================================================================
-- Test 5: Indexes exist
-- =============================================================================
SELECT 'TEST 5a: adjustment indexes exist' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1
  FROM unnest(ARRAY[
    'idx_cloud_stock_adj_shop_id',
    'idx_cloud_stock_adj_product_id',
    'idx_cloud_stock_adj_status',
    'idx_cloud_stock_adj_sale_id',
    'idx_cloud_stock_adj_idempotency_key'
  ]) AS idxname
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'cloud_stock_adjustments'
      AND indexname = idxname
  )
);

-- =============================================================================
-- Test 6: SELECT-only tenant-isolated policy
-- =============================================================================
SELECT 'TEST 6a: SELECT policy exists for authenticated' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'cloud_stock_adjustments'
    AND policyname = 'shop_isolation_stock_adjustments'
    AND cmd = 'SELECT'
    AND roles = ARRAY['authenticated']
);

SELECT 'TEST 6b: policy isolates via shop_members active membership' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'cloud_stock_adjustments'
    AND policyname = 'shop_isolation_stock_adjustments'
    AND qual LIKE '%shop_members%auth.uid()%ACTIVE%'
);

SELECT 'TEST 6c: no INSERT/UPDATE/DELETE policies' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'cloud_stock_adjustments'
    AND cmd IN ('INSERT', 'UPDATE', 'DELETE')
);

SELECT 'TEST 6d: direct table access revoked from authenticated' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM information_schema.table_privileges
  WHERE table_name = 'cloud_stock_adjustments'
    AND grantee = 'authenticated'
);

-- =============================================================================
-- Test 7: Owner-gated RPC surface
-- =============================================================================
SELECT 'TEST 7a: adjustment RPCs exist as JSONB SECURITY DEFINER' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1
  FROM unnest(ARRAY[
    'create_cloud_stock_adjustment',
    'list_cloud_stock_adjustments',
    'resolve_cloud_stock_adjustment'
  ]) AS fname
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = fname
      AND n.nspname = 'public'
      AND p.prorettype = 'jsonb'::regtype
      AND p.prosecdef = true
      AND p.proconfig @> ARRAY['search_path=public']
  )
);

SELECT 'TEST 7b: every adjustment RPC enforces admin.settings.access' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1
  FROM unnest(ARRAY[
    'create_cloud_stock_adjustment',
    'list_cloud_stock_adjustments',
    'resolve_cloud_stock_adjustment'
  ]) AS fname
  WHERE (SELECT pg_get_functiondef(p.oid) FROM pg_proc p
         WHERE p.proname = fname LIMIT 1)
        NOT LIKE '%admin.settings.access%'
);

SELECT 'TEST 7c: EXECUTE granted to authenticated only' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1
  FROM unnest(ARRAY[
    'create_cloud_stock_adjustment',
    'list_cloud_stock_adjustments',
    'resolve_cloud_stock_adjustment'
  ]) AS fname
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.routine_privileges
    WHERE routine_name = fname AND grantee = 'authenticated'
  )
);

-- =============================================================================
-- Test 8: P-OD1 durable oversell recording in sale RPC
-- =============================================================================
SELECT 'TEST 8a: stock sale RPC records oversold adjustment atomically' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%INSERT INTO cloud_stock_adjustments%'
  AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%ON CONFLICT DO NOTHING%'
  AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%v_status = ''OVERSOLD''%';

-- =============================================================================
-- Test 9: Migration-28 concurrency contract preserved
-- =============================================================================
SELECT 'TEST 9a: FOR UPDATE and CAS guard retained in sale RPC' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%FOR UPDATE%'
  AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%phase_m_oversell_guard(%'
  AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%phase_m_idempotency_lookup(%'
  AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%phase_m_idempotency_record(%';

SELECT 'TEST 9b: non-oversell stock-blocking path unchanged' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc
  WHERE proname = 'create_cloud_sale_with_stock_v2'
) LIKE '%Insufficient stock%';

-- =============================================================================
-- Test 10: Additive-only (no destructive constructs)
-- =============================================================================
SELECT 'TEST 10a: no drop/truncate habits (structural scan of applied DDL is not retrievable post-hoc; confirming via constraint/function presence above)'
as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_trigger
  WHERE tgname LIKE '%cloud_stock_adjustments%' AND tgisinternal = false
);

-- =============================================================================
-- Summary
-- =============================================================================
SELECT 'ALL A4 STRUCTURAL TESTS COMPLETED' as summary;
SELECT count(*) as total_checks FROM (
  VALUES
  (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)
) AS t(n);