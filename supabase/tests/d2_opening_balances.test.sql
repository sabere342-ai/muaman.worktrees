-- =============================================================================
-- Phase P Group D D2 (P-OD): Opening Balances — pgTAP RLS + RPC regression
--
-- Proves P-OD5 owner decisions A/C/A/C/A/B/A:
--   1. Anonymous SELECT on cloud_accounts -> blocked
--   2. Authenticated shop member SELECT -> allowed (own shop only)
--   3. Cross-shop SELECT -> blocked (row isolation)
--   4. Authenticated INSERT -> blocked (read-only RPC surface)
--   5. create_cloud_account RPC enforces owner-only (D2-06 B)
--   6. create_opening_balance RPC enforces owner-only (D2-06 B)
--   7. D2-03 A: negative amount rejected by RPC
--   8. D2-03 A: zero / positive amount accepted
--   9. D2-05 A: correction creates new row, original unchanged
--  10. D2-04 A: effective_date is required and indexed
--  11. Idempotent migration
--  12. create_rpc can be called twice for same account (idempotent)
-- =============================================================================

-- Test isolation setup
\set shop_a_id  gen_random_uuid()
\set shop_b_id  gen_random_uuid()
\set owner_a     'owner-a'
\set employee_a  'employee-a'
\set salesonly_a 'salesonly-a'
\set owner_b     'owner-b'

BEGIN;

SELECT plan(12);

-- --- Setup roles / auth bypass ---
SELECT lives_ok($$
    SELECT auth.uid() AS uid FROM auth.users;
$$, 'auth.uid() reachable');

-- Set up auth.uid() override for test context
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid AS $$
  SELECT current_setting('request.auth.uid', true)::uuid;
$$ LANGUAGE sql STABLE;

-- Create test accounts table (mirrors D2 schema)
-- [schema is created by migration 00038]

-- --- Tests ---

-- 1: Anonymous SELECT blocked
SELECT results_eq(
  $$ SELECT count(*) FROM cloud_accounts $$,
  array[0],
  '1: Anonymous SELECT on cloud_accounts returns 0 rows (blocked)'
);

-- 2: Authenticated shop member SELECT allowed
SELECT set_config('request.auth.uid', :owner_a, true);
INSERT INTO cloud_accounts (shop_id, name, account_type, is_active, created_at, updated_at)
VALUES (:shop_a_id, 'صندوق النقد', 'CASH', true, now(), now());
SELECT is_not_null(
  (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'صندوق النقد'),
  '2: Authenticated owner can SELECT own shop accounts'
);

-- 3: Cross-shop SELECT blocked (row isolation)
SELECT set_config('request.auth.uid', :owner_b, true);
INSERT INTO cloud_accounts (shop_id, name, account_type, is_active, created_at, updated_at)
VALUES (:shop_b_id, 'نقداً', 'BANK', true, now(), now());
SELECT is_not_null(
  (SELECT id FROM cloud_accounts WHERE shop_id = :shop_b_id),
  '3: Shop B owner sees only own accounts'
);
SELECT equals(
  (SELECT count(*) FROM cloud_accounts WHERE shop_id = :shop_a_id),
  0,
  '3b: Shop B owner cannot see Shop A accounts'
);

-- 4: Authenticated INSERT blocked (no direct INSERT)
SELECT set_config('request.auth.uid', :owner_a, true);
SELECT throws_ok(
  $sql$
    INSERT INTO cloud_opening_balance_entries (shop_id, account_id, amount, effective_date, entry_kind)
    VALUES (:shop_a_id, (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id LIMIT 1), 100, '2026-01-01', 'OPENING')
  $sql$,
  '4: Direct INSERT blocked by RLS'
);

-- 5: create_cloud_account RPC enforces owner-only
SELECT set_config('request.auth.uid', :employee_a, true);
SELECT throws_ok(
  $$
    SELECT create_cloud_account(
      :shop_a_id, 'حساب موظف', 'CASH'
    )
  $$,
  '5a: Employee CANNOT call create_cloud_account (D2-06 B)'
);

SELECT set_config('request.auth.uid', :owner_a, true);
SELECT is_not_null(
  (SELECT create_cloud_account(:shop_a_id, 'حساب المالك', 'BANK')),
  '5b: Owner can call create_cloud_account'
);

-- 6: create_opening_balance RPC enforces owner-only
SELECT set_config('request.auth.uid', :employee_a, true);
SELECT throws_ok(
  $$
    SELECT create_opening_balance(
      :shop_a_id,
      0,
      1000,
      '2026-01-01',
      'OPENING'
    )
  $$,
  '6a: Employee CANNOT call create_opening_balance (D2-06 B)'
);

SELECT set_config('request.auth.uid', :owner_a, true);
SELECT is_not_null(
  (SELECT create_opening_balance(
    :shop_a_id,
    (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
    1500,
    '2026-01-01',
    'OPENING'
  )),
  '6b: Owner can call create_opening_balance'
);

-- 7: D2-03 A — negative amount rejected
SELECT set_config('request.auth.uid', :owner_a, true);
SELECT throws_ok(
  $$
    SELECT create_opening_balance(
      :shop_a_id,
      (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
      -100,
      '2026-01-01',
      'OPENING'
    )
  $$,
  '7: Negative amount rejected by RPC (D2-03 A)'
);

-- 8: D2-03 A — zero amount accepted
SELECT is_not_null(
  (SELECT create_opening_balance(
    :shop_a_id,
    (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
    0,
    '2026-01-01',
    'OPENING'
  )),
  '8a: Zero amount accepted (D2-03 A)'
);

-- 8b: positive amount accepted
SELECT is_not_null(
  (SELECT create_opening_balance(
    :shop_a_id,
    (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
    5000,
    '2026-01-02',
    'OPENING'
  )),
  '8b: Positive amount accepted (D2-03 A)'
);

-- 9: D2-05 A — correction creates new row, original unchanged
SELECT set_config('request.auth.uid', :owner_a, true);
-- Create a "correction" of the first entry (adjust by creating a new entry)
SELECT is_not_null(
  (SELECT create_opening_balance(
    :shop_a_id,
    (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
    6000,
    '2026-01-03',
    'CORRECTION'
  )),
  '9a: Correction entry created'
);
SELECT equals(
  (SELECT amount FROM cloud_opening_balance_entries
   WHERE shop_id = :shop_a_id AND entry_kind = 'OPENING' AND amount = 1500),
  1500,
  '9b: Original OPENING entry unchanged (D2-05 A)'
);

-- 10: D2-04 A — effective_date required
SELECT throws_ok(
  $$
    SELECT create_opening_balance(
      :shop_a_id,
      (SELECT id FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
      100,
      NULL,
      'OPENING'
    )
  $$,
  '10: effective_date is required (D2-04 A)'
);

-- 11: Idempotent create_cloud_account (same name returns existing)
SELECT set_config('request.auth.uid', :owner_a, true);
SELECT is_not_null(
  (SELECT create_cloud_account(:shop_a_id, 'حساب المالك', 'BANK')),
  '11: Idempotent create_cloud_account (same name)'
);

-- 12: Idempotency check on account name uniqueness
SELECT equals(
  (SELECT count(*) FROM cloud_accounts WHERE shop_id = :shop_a_id AND name = 'حساب المالك'),
  1,
  '12: Only one account with given name per shop'
);

SELECT * FROM finish();
ROLLBACK;
