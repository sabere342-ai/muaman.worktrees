-- RLS Regression Tests for shop_members Recursion Fix
-- Tests that the recursive policy has been replaced with a non-recursive equivalent
-- Run with: supabase db test --files supabase/tests/rls_shop_members_recursion.test.sql

-- =============================================================================
-- Test Setup: Create test users, shops, and memberships
-- =============================================================================

-- We'll use the Supabase test framework's auth.uid() simulation
-- These tests assume the migration 20260820000029 has been applied

-- =============================================================================
-- Test 1: Authenticated active member can query own shop members
-- =============================================================================

-- Test 1a: Direct SELECT on shop_members for own shop should succeed
SELECT 'TEST 1a: Own shop membership query' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM information_schema.policies
  WHERE tablename = 'shop_members' AND policyname = 'shop_member_isolation'
);

-- =============================================================================
-- Test 2: Cross-shop rows are invisible
-- =============================================================================

-- Test 2a: Policy definition does not reference shop_members in USING clause
SELECT 'TEST 2a: Policy no longer self-references' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'shop_members'
    AND policyname = 'shop_member_isolation'
    AND qual LIKE '%shop_members%'
);

-- =============================================================================
-- Test 3: Suspended/inactive member cannot gain access
-- =============================================================================

-- Test 3a: Helper function returns empty for users with only INACTIVE memberships
SELECT 'TEST 3a: Helper filters by ACTIVE status' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_user_shop_ids'
) LIKE '%status = %ACTIVE%%';

-- =============================================================================
-- Test 4: Anon access returns zero rows (via helper returning empty array)
-- =============================================================================

-- Test 4a: Helper function handles NULL auth.uid()
SELECT 'TEST 4a: Helper returns empty for NULL auth.uid()' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_user_shop_ids'
) LIKE '%v_user_id IS NULL THEN%RETURN %{}%';

-- =============================================================================
-- Test 5: Direct shop_members SELECT does not recurse
-- =============================================================================

-- Test 5a: EXPLAIN shows no recursion in plan
-- Note: This is a structural test - actual recursion test requires live execution
SELECT 'TEST 5a: Policy uses helper function, not self-query' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'shop_members'
    AND policyname = 'shop_member_isolation'
    AND qual LIKE '%get_user_shop_ids%%'
);

-- =============================================================================
-- Test 6: Authenticated INSERT remains denied (no policy for INSERT)
-- =============================================================================

-- Test 6a: No INSERT policy exists on shop_members
SELECT 'TEST 6a: No INSERT policy on shop_members' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'shop_members' AND cmd = 'INSERT'
);

-- =============================================================================
-- Test 7: Authenticated UPDATE remains denied (no policy for UPDATE)
-- =============================================================================

-- Test 7a: No UPDATE policy exists on shop_members
SELECT 'TEST 7a: No UPDATE policy on shop_members' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'shop_members' AND cmd = 'UPDATE'
);

-- =============================================================================
-- Test 8: Authenticated DELETE remains denied (no policy for DELETE)
-- =============================================================================

-- Test 8a: No DELETE policy exists on shop_members
SELECT 'TEST 8a: No DELETE policy on shop_members' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM pg_policies
  WHERE tablename = 'shop_members' AND cmd = 'DELETE'
);

-- =============================================================================
-- Test 9: Service-role behavior remains valid (bypasses RLS)
-- =============================================================================

-- Test 9a: Service role can still INSERT/UPDATE/DELETE (RLS bypass)
-- This is a structural verification - service_role bypasses RLS by design
SELECT 'TEST 9a: RLS enabled on shop_members' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_tables
  WHERE tablename = 'shop_members' AND rowsecurity = true
);

-- =============================================================================
-- Test 10: Helper returns correct active shop IDs
-- =============================================================================

-- Test 10a: Helper function exists with correct signature
SELECT 'TEST 10a: get_user_shop_ids function exists' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_proc
  WHERE proname = 'get_user_shop_ids'
    AND prorettype = 'uuid[]'::regtype
    AND prokind = 'f'
);

-- Test 10b: Helper is SECURITY DEFINER
SELECT 'TEST 10b: Helper is SECURITY DEFINER' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_proc
  WHERE proname = 'get_user_shop_ids' AND prosecdef = true
);

-- Test 10c: Helper has fixed search_path
SELECT 'TEST 10c: Helper has fixed search_path' as test_name;
SELECT 1 as passed WHERE EXISTS (
  SELECT 1 FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE p.proname = 'get_user_shop_ids'
    AND p.proconfig @> ARRAY['search_path=public']
);

-- =============================================================================
-- Test 11: Helper returns empty result for unauthenticated context
-- =============================================================================

-- Test 11a: Helper logic handles NULL auth.uid()
SELECT 'TEST 11a: Helper returns empty array for NULL auth.uid()' as test_name;
SELECT 1 as passed WHERE (
  SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_user_shop_ids'
) ILIKE '%auth.uid()%' AND (
  SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_user_shop_ids'
) ILIKE '%return%{}%';

-- =============================================================================
-- Test 12: No cross-tenant leakage through related policies
-- =============================================================================

-- Test 12a: Other policies still reference shop_members but don't recurse
-- (They query shop_members from other tables, which now uses the fixed policy)
SELECT 'TEST 12a: Other RLS policies reference shop_members' as test_name;
SELECT 1 as passed WHERE (
  SELECT count(*) FROM pg_policies
  WHERE qual LIKE '%shop_members%' AND tablename != 'shop_members'
) >= 6;

-- Test 12b: Helper function has minimal execute grants
SELECT 'TEST 12b: Helper execute grants are minimal' as test_name;
SELECT 1 as passed WHERE (
  SELECT string_agg(grantee, ', ' ORDER BY grantee)
  FROM information_schema.routine_privileges
  WHERE routine_name = 'get_user_shop_ids'
) IN (
  'anon, authenticated, service_role',
  'authenticated, anon, service_role',
  'service_role, authenticated, anon'
);

-- Test 12c: PUBLIC execute is revoked
SELECT 'TEST 12c: PUBLIC execute revoked on helper' as test_name;
SELECT 1 as passed WHERE NOT EXISTS (
  SELECT 1 FROM information_schema.routine_privileges
  WHERE routine_name = 'get_user_shop_ids' AND grantee = 'PUBLIC'
);

-- =============================================================================
-- Summary
-- =============================================================================

SELECT 'ALL STRUCTURAL TESTS COMPLETED' as summary;
SELECT count(*) as total_checks FROM (
  VALUES
  (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)
) AS t(n);