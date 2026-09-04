-- PHASE P GROUP D D1 — cost_history RLS / tenant isolation pgTAP tests
-- Assumes migration 20260820000037_phase_p_group_d_d1_security_remediation.sql has been applied.
-- Run with: supabase test db --local supabase/tests/d1_cost_history_rls.test.sql

BEGIN;

SELECT plan(38);

-- =============================================================================
-- STRUCTURAL TESTS (T1-T14, 20 assertions)
-- =============================================================================

-- T1: cloud_cost_history table exists
SELECT has_table('public', 'cloud_cost_history', 'T1: cloud_cost_history table exists');

-- T2: RLS is enabled on cloud_cost_history
SELECT results_eq(
  'SELECT rowsecurity FROM pg_tables WHERE schemaname = ''public'' AND tablename = ''cloud_cost_history''',
  ARRAY[true],
  'T2: cloud_cost_history RLS is enabled'
);

-- T3: cloud_cost_history has required columns
SELECT has_column('public', 'cloud_cost_history', 'id', 'T3a: has id column');
SELECT has_column('public', 'cloud_cost_history', 'shop_id', 'T3b: has shop_id column');
SELECT has_column('public', 'cloud_cost_history', 'product_id', 'T3c: has product_id column');
SELECT has_column('public', 'cloud_cost_history', 'old_cost', 'T3d: has old_cost column');
SELECT has_column('public', 'cloud_cost_history', 'new_cost', 'T3e: has new_cost column');
SELECT has_column('public', 'cloud_cost_history', 'changed_at', 'T3f: has changed_at column');

-- T4: shop_id is UUID type
SELECT col_type_is('public', 'cloud_cost_history', 'shop_id', 'uuid',
  'T4a: shop_id is UUID type');

-- T5: NOT NULL constraints
SELECT col_not_null('public', 'cloud_cost_history', 'old_cost', 'T5a: old_cost is NOT NULL');
SELECT col_not_null('public', 'cloud_cost_history', 'new_cost', 'T5b: new_cost is NOT NULL');

-- T6-T8: Functions exist
SELECT has_function('public', 'insert_cloud_cost_history', 'T6: insert_cloud_cost_history function exists');
SELECT has_function('public', 'get_cloud_cost_history_by_product', 'T7: get_cloud_cost_history_by_product function exists');
SELECT has_function('public', 'get_cloud_cost_history_by_shop', 'T8: get_cloud_cost_history_by_shop function exists');

-- T9-T10: Indexes exist
SELECT has_index('public', 'cloud_cost_history', 'idx_cloud_cost_history_shop', 'T9: shop index exists');
SELECT has_index('public', 'cloud_cost_history', 'idx_cloud_cost_history_product', 'T10: product index exists');

-- T11: No permissive SELECT policy with (true)
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND qual = ''true''
     AND cmd = ''SELECT''',
  ARRAY[0::bigint],
  'T11: no permissive SELECT policy with (true)'
);

-- T12: No permissive ALL policy with (true)
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND qual = ''true''
     AND cmd = ''ALL''',
  ARRAY[0::bigint],
  'T12: no permissive ALL policy with (true)'
);

-- T13: Owner ALL policy exists
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND policyname = ''cloud_cost_history_owner_all''',
  ARRAY[1::bigint],
  'T13: owner ALL policy exists'
);

-- T14: Employee read policy exists
SELECT results_eq(
  'SELECT count(*) FROM pg_policies
   WHERE schemaname = ''public''
     AND tablename = ''cloud_cost_history''
     AND policyname = ''cloud_cost_history_employee_read''',
  ARRAY[1::bigint],
  'T14: employee SELECT policy exists'
);

-- =============================================================================
-- BEHAVIORAL TESTS — Fixtures
-- =============================================================================

-- Auth users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'owner_a@test.local', 'x',
   now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'owner_b@test.local', 'x',
   now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'emp_a@test.local', 'x',
   now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'emp_b@test.local', 'x',
   now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', 'sales_a@test.local', 'x',
   now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Shops
INSERT INTO shops (id, name, owner_user_id)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Shop A', '11111111-1111-1111-1111-111111111111'),
  ('b2000000-0000-0000-0000-000000000002', 'Shop B', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- Licenses (before shop_members for trigger; professional user_limit=5, starter user_limit=2)
INSERT INTO licenses (shop_id, license_key, plan_key, status)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'D1-LIC-A', 'professional', 'ACTIVE'),
  ('b2000000-0000-0000-0000-000000000002', 'D1-LIC-B', 'starter', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- Shop members
INSERT INTO shop_members (shop_id, user_id, role, status)
VALUES
  ('a1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner',    'ACTIVE'),
  ('a1000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'employee', 'ACTIVE'),
  ('a1000000-0000-0000-0000-000000000001', '77777777-7777-7777-7777-777777777777', 'salesOnly', 'ACTIVE'),
  ('b2000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'owner',    'ACTIVE'),
  ('b2000000-0000-0000-0000-000000000002', '55555555-5555-5555-5555-555555555555', 'employee', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- Per-shop roles + permissions (mirrors create_shop_with_owner semantics for Shop A).
-- Employee: inventory.view + inventory.edit; salesOnly: no inventory permissions.
INSERT INTO roles (shop_id, name, is_system)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'employee', true),
  ('a1000000-0000-0000-0000-000000000001', 'salesOnly', true)
ON CONFLICT (shop_id, name) DO NOTHING;

INSERT INTO role_permissions_cloud (role_id, permission_id)
SELECT r.id, p.permission_id
FROM roles r
CROSS JOIN (VALUES
  ('inventory.view'),
  ('inventory.edit')
) AS p(permission_id)
WHERE r.shop_id = 'a1000000-0000-0000-0000-000000000001'
  AND r.name = 'employee'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- cloud_products (needed for FK in cloud_cost_history)
INSERT INTO cloud_products (id, shop_id, name, barcode, cost_price)
VALUES
  ('c1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Product A', 'BAR-A', 100.00),
  ('c2000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000002', 'Product B', 'BAR-B', 200.00)
ON CONFLICT DO NOTHING;

-- Seed cost_history for Shop A (for read tests)
INSERT INTO cloud_cost_history (shop_id, product_id, product_name, product_barcode,
  old_cost, new_cost, changed_by)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001',
   'Product A', 'BAR-A', 80.00, 100.00, '11111111-1111-1111-1111-111111111111');

-- =============================================================================
-- BEHAVIORAL TESTS — RPC Authorization
-- =============================================================================

-- B1: Owner RPC insert own shop -> PASS
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT isnt(
  insert_cloud_cost_history(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'Product A', 'BAR-A', 100.00, 120.00,
    '11111111-1111-1111-1111-111111111111'
  ),
  NULL,
  'B1: owner can RPC insert cost history in own shop'
);

-- B2: Owner RPC read own shop by shop -> PASS
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT isnt(
  (SELECT count(*)::int FROM get_cloud_cost_history_by_shop(
    'a1000000-0000-0000-0000-000000000001'
  )),
  0,
  'B2: owner can RPC read cost history in own shop (by shop)'
);

-- B3: Owner RPC insert cross-shop -> DENY (not_member)
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT throws_ok(
  $$SELECT insert_cloud_cost_history(
    'b2000000-0000-0000-0000-000000000002',
    'c2000000-0000-0000-0000-000000000002',
    'Product B', 'BAR-B', 200.00, 250.00,
    '11111111-1111-1111-1111-111111111111'
  )$$,
  'not_member',
  'B3: owner CANNOT RPC insert cost history into cross-shop'
);

-- B4: Owner RPC read cross-shop by shop -> DENY (not_member)
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT throws_ok(
  $$SELECT count(*) FROM get_cloud_cost_history_by_shop(
    'b2000000-0000-0000-0000-000000000002'
  )$$,
  'not_member',
  'B4: owner CANNOT RPC read cross-shop cost history (by shop)'
);

-- B5: Employee RPC insert own shop -> PASS
SELECT set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
SELECT isnt(
  insert_cloud_cost_history(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'Product A', 'BAR-A', 100.00, 130.00,
    '33333333-3333-3333-3333-333333333333'
  ),
  NULL,
  'B5: employee can RPC insert cost history in own shop'
);

-- B6: Employee RPC read own shop by shop -> PASS
SELECT set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
SELECT isnt(
  (SELECT count(*)::int FROM get_cloud_cost_history_by_shop(
    'a1000000-0000-0000-0000-000000000001'
  )),
  0,
  'B6: employee can RPC read cost history in own shop (by shop)'
);

-- B7: Employee RPC insert cross-shop -> DENY (not_member)
SELECT set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT insert_cloud_cost_history(
    'b2000000-0000-0000-0000-000000000002',
    'c2000000-0000-0000-0000-000000000002',
    'Product B', 'BAR-B', 200.00, 250.00,
    '33333333-3333-3333-3333-333333333333'
  )$$,
  'not_member',
  'B7: employee CANNOT RPC insert cost history into cross-shop'
);

-- B8: Employee RPC read cross-shop by shop -> DENY (not_member)
SELECT set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT count(*) FROM get_cloud_cost_history_by_shop(
    'b2000000-0000-0000-0000-000000000002'
  )$$,
  'not_member',
  'B8: employee CANNOT RPC read cross-shop cost history (by shop)'
);

-- B9: salesOnly RPC insert -> DENY (permission_denied: inventory.edit)
SELECT set_config('request.jwt.claim.sub', '77777777-7777-7777-7777-777777777777', true);
SELECT throws_ok(
  $$SELECT insert_cloud_cost_history(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'Product A', 'BAR-A', 100.00, 150.00,
    '77777777-7777-7777-7777-777777777777'
  )$$,
  'permission_denied: inventory.edit',
  'B9: salesOnly CANNOT RPC insert cost history'
);

-- B10: salesOnly RPC read by shop -> DENY (permission_denied: inventory.view)
SELECT set_config('request.jwt.claim.sub', '77777777-7777-7777-7777-777777777777', true);
SELECT throws_ok(
  $$SELECT count(*) FROM get_cloud_cost_history_by_shop(
    'a1000000-0000-0000-0000-000000000001'
  )$$,
  'permission_denied: inventory.view',
  'B10: salesOnly CANNOT RPC read cost history (by shop)'
);

-- B11: Anon RPC insert -> DENY (unauthenticated)
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT throws_ok(
  $$SELECT insert_cloud_cost_history(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'Product A', 'BAR-A', 100.00, 160.00,
    NULL
  )$$,
  'unauthenticated',
  'B11: anon CANNOT RPC insert cost history'
);

-- B12: Anon RPC read by product -> DENY (unauthenticated)
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT throws_ok(
  $$SELECT count(*) FROM get_cloud_cost_history_by_product(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001'
  )$$,
  'unauthenticated',
  'B12: anon CANNOT RPC read cost history by product'
);

-- B13: Anon RPC read by shop -> DENY (unauthenticated)
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT throws_ok(
  $$SELECT count(*) FROM get_cloud_cost_history_by_shop(
    'a1000000-0000-0000-0000-000000000001'
  )$$,
  'unauthenticated',
  'B13: anon CANNOT RPC read cost history by shop'
);

-- B14: Owner RPC read own shop by product -> PASS (covers third function positively)
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT isnt(
  (SELECT count(*)::int FROM get_cloud_cost_history_by_product(
    'a1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001'
  )),
  0,
  'B14: owner can RPC read cost history in own shop (by product)'
);

-- =============================================================================
-- BEHAVIORAL TESTS — Direct Table (defense-in-depth)
-- =============================================================================

-- B15: anon has no direct INSERT/SELECT grant on cloud_cost_history
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT is(
  has_table_privilege('anon', 'cloud_cost_history', 'INSERT')
    OR has_table_privilege('anon', 'cloud_cost_history', 'SELECT'),
  false,
  'B15: anon has no direct INSERT/SELECT grant on cloud_cost_history'
);

-- B16: authenticated has no direct INSERT/SELECT grant on cloud_cost_history
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT is(
  has_table_privilege('authenticated', 'cloud_cost_history', 'INSERT')
    OR has_table_privilege('authenticated', 'cloud_cost_history', 'SELECT'),
  false,
  'B16: authenticated has no direct INSERT/SELECT grant on cloud_cost_history'
);

-- B17: authorized owner can directly INSERT own shop (positive operational path)
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT lives_ok(
  $$INSERT INTO cloud_cost_history
    (shop_id, product_id, product_name, product_barcode, old_cost, new_cost, changed_by)
  VALUES
    ('a1000000-0000-0000-0000-000000000001',
     'c1000000-0000-0000-0000-000000000001',
     'Product A', 'BAR-A', 90.00, 110.00,
     '11111111-1111-1111-1111-111111111111')$$,
  'B17: owner can directly INSERT into own shop cloud_cost_history'
);

-- B18: owner can directly SELECT own shop data
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT isnt(
  (SELECT count(*)::int FROM cloud_cost_history
   WHERE shop_id = 'a1000000-0000-0000-0000-000000000001'),
  0,
  'B18: owner can directly SELECT own shop cloud_cost_history'
);

SELECT * FROM finish();
ROLLBACK;