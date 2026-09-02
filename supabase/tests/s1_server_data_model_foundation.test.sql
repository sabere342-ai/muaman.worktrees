-- PHASE P GROUP B S1 — server data model / migration foundation pgTAP tests
-- Assumes migration 20260820000031_phase_p_group_b_s1_server_data_model_foundation.sql has been applied.
-- Run with: supabase test db --local supabase/tests/s1_server_data_model_foundation.test.sql

BEGIN;

SELECT plan(46);

-- =============================================================================
-- T1: plans exists
-- =============================================================================
SELECT has_table('public', 'plans', 'T1: plans table exists');

-- =============================================================================
-- T2: plans RLS is enabled
-- =============================================================================
SELECT results_eq(
  'SELECT rowsecurity FROM pg_tables WHERE schemaname = ''public'' AND tablename = ''plans''',
  ARRAY[true],
  'T2: plans RLS is enabled'
);

-- =============================================================================
-- T3: plans primary key is key
-- =============================================================================
SELECT col_is_pk('public', 'plans', 'key', 'T3: plans PK is key');

-- =============================================================================
-- T4: deterministic plan seeds
-- =============================================================================
SELECT results_eq(
  'SELECT user_limit, device_limit, trial_days FROM plans WHERE key = ''trial''',
  $$VALUES (1::integer, 1::integer, 14::integer)$$,
  'T4a: trial = 1 user / 1 device / 14 trial days'
);
SELECT results_eq(
  'SELECT user_limit, device_limit FROM plans WHERE key = ''starter''',
  $$VALUES (2::integer, 3::integer)$$,
  'T4b: starter = 2 users / 3 devices'
);
SELECT results_eq(
  'SELECT user_limit, device_limit FROM plans WHERE key = ''professional''',
  $$VALUES (5::integer, 10::integer)$$,
  'T4c: professional = 5 users / 10 devices'
);
SELECT results_eq(
  'SELECT user_limit, device_limit FROM plans WHERE key = ''enterprise''',
  $$VALUES (NULL::integer, NULL::integer)$$,
  'T4d: enterprise = NULL users / NULL devices'
);

-- =============================================================================
-- T5: trial.billing_cadence IS NULL
-- =============================================================================
SELECT is(
  (SELECT billing_cadence FROM plans WHERE key = 'trial'),
  NULL,
  'T5: trial billing_cadence IS NULL'
);

-- =============================================================================
-- T6/T7/T8: starter/professional/enterprise = 'monthly'
-- =============================================================================
SELECT is(
  (SELECT billing_cadence FROM plans WHERE key = 'starter'),
  'monthly',
  'T6: starter billing_cadence = ''monthly'''
);
SELECT is(
  (SELECT billing_cadence FROM plans WHERE key = 'professional'),
  'monthly',
  'T7: professional billing_cadence = ''monthly'''
);
SELECT is(
  (SELECT billing_cadence FROM plans WHERE key = 'enterprise'),
  'monthly',
  'T8: enterprise billing_cadence = ''monthly'''
);

-- =============================================================================
-- T9: billing_cadence remains nullable (correction honored)
-- =============================================================================
SELECT is(
  (SELECT is_nullable::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'plans' AND column_name = 'billing_cadence'),
  'YES',
  'T9: billing_cadence is nullable'
);

-- =============================================================================
-- T10: ENTERPRISE user_limit and device_limit are NULL (no magic integer)
-- =============================================================================
SELECT results_eq(
  'SELECT user_limit, device_limit FROM plans WHERE key = ''enterprise''',
  $$VALUES (NULL::integer, NULL::integer)$$,
  'T10: enterprise limits NULL (unlimited)'
);

-- =============================================================================
-- T11/T12/T13/T14: licenses.plan_key / nullable / FK ; licenses.user_limit
-- =============================================================================
SELECT has_column('public', 'licenses', 'plan_key', 'T11: licenses.plan_key exists');
SELECT is(
  (SELECT is_nullable::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'licenses' AND column_name = 'plan_key'),
  'YES',
  'T12: licenses.plan_key nullable'
);
SELECT results_eq(
  $q$
  SELECT count(*) FROM information_schema.key_column_usage kcu
  WHERE kcu.table_name = 'licenses' AND kcu.column_name = 'plan_key'
    AND kcu.constraint_name IN (
      SELECT conname FROM pg_constraint
      WHERE conrelid = 'licenses'::regclass AND contype = 'f'
    )
  $q$,
  ARRAY[1::bigint],
  'T13: licenses.plan_key is a FK'
);
SELECT has_column('public', 'licenses', 'user_limit', 'T14a: licenses.user_limit exists');
SELECT is(
  (SELECT is_nullable::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'licenses' AND column_name = 'user_limit'),
  'YES',
  'T14b: licenses.user_limit nullable'
);

-- FK target reference check (plans.key)
SELECT results_eq(
  $q$
  SELECT count(*) FROM information_schema.key_column_usage kcu
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = kcu.constraint_name
   AND ccu.table_schema = kcu.table_schema
  WHERE kcu.table_name = 'licenses' AND kcu.column_name = 'plan_key'
    AND ccu.table_name = 'plans' AND ccu.column_name = 'key'
  $q$,
  ARRAY[1::bigint],
  'T13b: licenses.plan_key references plans(key)'
);

-- =============================================================================
-- T15/T16: devices status CHECK accepts PENDING_APPROVAL + ACTIVE/REVOKED/LOST
-- =============================================================================
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint con
    WHERE con.conrelid = 'devices'::regclass
      AND con.conname = 'devices_status_check'
      AND pg_get_constraintdef(con.oid) LIKE '%PENDING_APPROVAL%'
  ),
  'T15: devices status CHECK accepts PENDING_APPROVAL'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint con
    WHERE con.conrelid = 'devices'::regclass
      AND con.conname = 'devices_status_check'
      AND pg_get_constraintdef(con.oid) LIKE '%ACTIVE%'
      AND pg_get_constraintdef(con.oid) LIKE '%REVOKED%'
      AND pg_get_constraintdef(con.oid) LIKE '%LOST%'
  ),
  'T16: devices status CHECK accepts ACTIVE, REVOKED, LOST'
);

-- =============================================================================
-- T17-T21: devices public-key / approval / revocation fields exist
-- =============================================================================
SELECT has_column('public', 'devices', 'public_key', 'T17: devices.public_key exists');
SELECT has_column('public', 'devices', 'approved_by', 'T18: devices.approved_by exists');
SELECT has_column('public', 'devices', 'approved_at', 'T19: devices.approved_at exists');
SELECT has_column('public', 'devices', 'revoked_by', 'T20: devices.revoked_by exists');
SELECT has_column('public', 'devices', 'revoked_at', 'T21: devices.revoked_at exists');

-- =============================================================================
-- T22: no private_key column exists
-- =============================================================================
SELECT is_empty(
  $q$
  SELECT column_name FROM information_schema.columns
  WHERE table_name = 'devices' AND column_name = 'private_key'
  $q$,
  'T22: no private_key column on devices'
);

-- =============================================================================
-- T23: no password/secret private-material column exists on devices
-- =============================================================================
SELECT is_empty(
  $q$
  SELECT column_name FROM information_schema.columns
  WHERE table_name = 'devices'
    AND (column_name ILIKE '%password%'
      OR column_name ILIKE '%secret%'
      OR column_name ILIKE '%private_key%'
      OR column_name ILIKE '%token%')
  $q$,
  'T23: no password/secret/private-material column on devices'
);

-- =============================================================================
-- T24/T25: invitations.token_hash / accepted_by exist
-- =============================================================================
SELECT has_column('public', 'invitations', 'token_hash', 'T24: invitations.token_hash exists');
SELECT has_column('public', 'invitations', 'accepted_by', 'T25: invitations.accepted_by exists');

-- =============================================================================
-- T26: idx_invitations_token_hash partial index exists
-- =============================================================================
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'invitations' AND indexname = 'idx_invitations_token_hash'
      AND indexdef ILIKE '%token_hash IS NOT NULL%'
  ),
  'T26: idx_invitations_token_hash partial index'
);

-- =============================================================================
-- T27/T28: device_audit_log exists + RLS enabled
-- =============================================================================
SELECT has_table('public', 'device_audit_log', 'T27: device_audit_log table exists');
SELECT results_eq(
  'SELECT rowsecurity FROM pg_tables WHERE schemaname = ''public'' AND tablename = ''device_audit_log''',
  ARRAY[true],
  'T28: device_audit_log RLS enabled'
);

-- =============================================================================
-- T29/T30: device_audit_log has shop_id + created_at
-- =============================================================================
SELECT has_column('public', 'device_audit_log', 'shop_id', 'T29: device_audit_log has shop_id');
SELECT has_column('public', 'device_audit_log', 'created_at', 'T30: device_audit_log has created_at');

-- =============================================================================
-- T31/T32/T33/T34: required indexes
-- =============================================================================
SELECT has_index('public', 'device_audit_log', 'idx_device_audit_shop', 'T31: idx_device_audit_shop');
SELECT has_index('public', 'devices', 'idx_devices_status', 'T32: idx_devices_status');
SELECT has_index('public', 'licenses', 'idx_licenses_plan_key', 'T33: idx_licenses_plan_key');
SELECT has_index('public', 'plans', 'idx_plans_key', 'T34: idx_plans_key');

-- =============================================================================
-- T35: existing business RLS surfaces remain intact (no weakening)
-- =============================================================================
SELECT results_eq(
  'SELECT count(*) FROM pg_policies WHERE tablename = ''devices'' AND policyname = ''shop_devices_isolation'' AND cmd = ''SELECT''',
  ARRAY[1::bigint],
  'T35a: devices RLS intact'
);
SELECT results_eq(
  'SELECT count(*) FROM pg_policies WHERE tablename = ''licenses'' AND policyname = ''shop_licenses_isolation'' AND cmd = ''SELECT''',
  ARRAY[1::bigint],
  'T35b: licenses RLS intact'
);
SELECT results_eq(
  'SELECT count(*) FROM pg_policies WHERE tablename = ''shop_members'' AND policyname = ''shop_member_isolation'' AND cmd = ''SELECT''',
  ARRAY[1::bigint],
  'T35c: shop_members RLS intact'
);
SELECT is_empty(
  $q$
  SELECT grantee, privilege_type FROM information_schema.table_privileges
  WHERE table_name IN ('plans', 'device_audit_log')
    AND grantee IN ('PUBLIC', 'anon', 'authenticated')
    AND privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  $q$,
  'T35d: no anonymous/authenticated DML grant on new S1 tables'
);

-- =============================================================================
-- T36: historical migration surface intact (sample of prior objects)
--   Full 00000..00030 immutability is proven by Git; structural sample here.
-- =============================================================================
SELECT has_table('public', 'cloud_stock_adjustments', 'T36a: historical cloud_stock_adjustments intact');
SELECT has_table('public', 'permission_audit_log', 'T36b: historical permission_audit_log intact');
SELECT results_eq(
  'SELECT count(*) FROM pg_proc WHERE proname = ''register_device'' AND pronamespace = ''public''::regnamespace',
  ARRAY[1::bigint],
  'T36c: historical register_device RPC intact'
);

SELECT * FROM finish();
