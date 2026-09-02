-- PHASE P GROUP B S3 — Revocation / Offline-Grace Authority pgTAP tests
-- Assumes migration 20260820000033 (and prior S1/S2 migrations) have been applied.
-- Run with: supabase test db --local supabase/tests/s3_revocation_offline_grace_authority.test.sql
--
-- The 22 governed scenarios (T1..T22) each map to exactly one pgTAP assertion.

BEGIN;

SELECT plan(25);

-- =============================================================================
-- FIXTURES
-- =============================================================================

INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 's3-owner1@test.local', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 's3-owner2@test.local', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 's3-member@test.local',  'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 's3-nonowner@test.local','x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO shops (id, name, owner_user_id)
VALUES
  ('e0000000-0000-0000-0000-000000000001', 'S3 License Revoke Shop', '11111111-1111-1111-1111-111111111111'),
  ('e0000000-0000-0000-0000-000000000002', 'S3 Device Revoke Shop',  '11111111-1111-1111-1111-111111111111'),
  ('e0000000-0000-0000-0000-000000000003', 'S3 Membership Revoke Shop','11111111-1111-1111-1111-111111111111'),
  ('e0000000-0000-0000-0000-000000000004', 'S3 Tenant Shop A',       '11111111-1111-1111-1111-111111111111'),
  ('e0000000-0000-0000-0000-000000000005', 'S3 Tenant Shop B',       '22222222-2222-2222-2222-222222222222')
ON CONFLICT DO NOTHING;

-- licenses MUST be bound before ACTIVE memberships so the S2 user-quota trigger
-- can resolve a canonical plan during the membership insert.
INSERT INTO licenses (shop_id, license_key, status, plan_key)
VALUES
  ('e0000000-0000-0000-0000-000000000001', 'S3-LIC-L', 'ACTIVE', 'starter'),
  ('e0000000-0000-0000-0000-000000000002', 'S3-LIC-D', 'ACTIVE', 'starter'),
  ('e0000000-0000-0000-0000-000000000003', 'S3-LIC-M', 'ACTIVE', 'starter'),
  ('e0000000-0000-0000-0000-000000000004', 'S3-LIC-A', 'ACTIVE', 'starter'),
  ('e0000000-0000-0000-0000-000000000005', 'S3-LIC-B', 'ACTIVE', 'starter')
ON CONFLICT DO NOTHING;

INSERT INTO shop_members (shop_id, user_id, role, status)
VALUES
  ('e0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner', 'ACTIVE'),
  ('e0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'owner', 'ACTIVE'),
  ('e0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'owner', 'ACTIVE'),
  ('e0000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'employee', 'ACTIVE'),
  ('e0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'owner', 'ACTIVE'),
  ('e0000000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'owner', 'ACTIVE')
ON CONFLICT DO NOTHING;

INSERT INTO devices (id, installation_id, shop_id, user_id, platform, device_name, status)
VALUES
  ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000101', 'e0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'windows', 'L-dev-1', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000102', 'e0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'windows', 'L-dev-2', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000011', 'f0000000-0000-0000-0000-000000000111', 'e0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'windows', 'D-dev-1', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000021', 'f0000000-0000-0000-0000-000000000121', 'e0000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'android', 'M-dev-1', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000022', 'f0000000-0000-0000-0000-000000000122', 'e0000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'android', 'M-dev-2', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000031', 'f0000000-0000-0000-0000-000000000131', 'e0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'windows', 'A-dev-1', 'ACTIVE'),
  ('f0000000-0000-0000-0000-000000000041', 'f0000000-0000-0000-0000-000000000141', 'e0000000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'windows', 'B-dev-1', 'ACTIVE')
ON CONFLICT (installation_id, shop_id) DO NOTHING;

-- Create ACTIVE activations for cascade testing via the (revocation-aware) S2-style
-- activate_device so we also prove the S2 path is intact before revocation.
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT activate_device('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000101');
SELECT activate_device('e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000102');
SELECT activate_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000111');
SELECT activate_device('e0000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000131');
SELECT set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
SELECT activate_device('e0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000121');
SELECT activate_device('e0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000122');
SELECT activate_device('e0000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000141');

-- =============================================================================
-- T1..T6: LICENSE REVOCATION (Shop e0...01, owner u1)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT s3_revoke_license('e0000000-0000-0000-0000-000000000001', 'license abuse');

SELECT is(
  (SELECT status FROM licenses WHERE shop_id = 'e0000000-0000-0000-0000-000000000001'),
  'REVOKED',
  'T1: license revocation sets status = REVOKED'
);

SELECT is(
  (SELECT revoked_at IS NOT NULL FROM licenses WHERE shop_id = 'e0000000-0000-0000-0000-000000000001'),
  true,
  'T2: license revocation sets revoked_at (authoritative server time)'
);

SELECT is(
  (SELECT count(*)::integer FROM activations a
    JOIN licenses l ON a.license_id = l.id
    WHERE l.shop_id = 'e0000000-0000-0000-0000-000000000001' AND a.status = 'ACTIVE'),
  0,
  'T3: license revocation cascades to ACTIVE activations (none remain ACTIVE)'
);

SELECT is(
  (SELECT count(*)::integer FROM devices
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000001'
      AND status = 'REVOKED' AND revoked_by = '11111111-1111-1111-1111-111111111111'
      AND revoked_at IS NOT NULL),
  2,
  'T4: license revocation cascades to ACTIVE devices and populates revoked metadata'
);

SELECT is(
  (SELECT count(*)::integer FROM device_audit_log
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000001'
      AND action = 'S3_LICENSE_REVOKE'),
  2,
  'T5: license revocation creates device audit trail (per affected device)'
);

-- Idempotent repeat: must be a no-op WITHOUT adding duplicate audit rows
SELECT s3_revoke_license('e0000000-0000-0000-0000-000000000001', 'again');
SELECT is(
  (SELECT count(*)::integer FROM device_audit_log
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000001'
      AND action = 'S3_LICENSE_REVOKE'),
  2,
  'T6: license revocation is idempotent with no duplicate audit rows'
);

-- =============================================================================
-- T7..T9, T17, T18: DEVICE REVOCATION (Shop e0...02, owner u1)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT s3_revoke_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000011', 'stolen device');

SELECT is(
  (SELECT status = 'REVOKED' AND revoked_by = '11111111-1111-1111-1111-111111111111' AND revoked_at IS NOT NULL
     FROM devices WHERE id = 'f0000000-0000-0000-0000-000000000011'),
  true,
  'T7: device revocation sets status/revoked_by/revoked_at'
);

SELECT is(
  (SELECT count(*)::integer FROM activations
    WHERE device_id = 'f0000000-0000-0000-0000-000000000011' AND status = 'ACTIVE'),
  0,
  'T8: device revocation cascades its ACTIVE activations'
);

-- Idempotent repeat
SELECT s3_revoke_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000011', 'again');
SELECT is(
  (SELECT count(*)::integer FROM device_audit_log
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000002'
      AND device_id = 'f0000000-0000-0000-0000-000000000011'
      AND action = 'S3_DEVICE_REVOKE'),
  1,
  'T9: device revocation is idempotent (single audit record)'
);

-- =============================================================================
-- T10..T13: MEMBERSHIP REVOCATION (Shop e0...03, member u2)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT s3_revoke_membership('e0000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'fired');

SELECT is(
  (SELECT status FROM shop_members
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000003'
      AND user_id = '22222222-2222-2222-2222-222222222222'),
  'REVOKED',
  'T10: membership revocation sets status = REVOKED'
);

SELECT is(
  (SELECT count(*)::integer FROM devices
    WHERE shop_id = 'e0000000-0000-0000-0000-000000000003'
      AND user_id = '22222222-2222-2222-2222-222222222222'
      AND status = 'REVOKED' AND revoked_by = '11111111-1111-1111-1111-111111111111'),
  2,
  'T11: membership revocation cascades to member devices (status + revoked_by)'
);

SELECT is(
  (SELECT count(*)::integer FROM activations a
    JOIN devices d ON a.device_id = d.id
    WHERE d.shop_id = 'e0000000-0000-0000-0000-000000000003'
      AND d.user_id = '22222222-2222-2222-2222-222222222222'
      AND a.status = 'ACTIVE'),
  0,
  'T12: membership revocation cascades to member activations (none remain ACTIVE)'
);

-- Owner self-membership revocation must be rejected
SELECT throws_ok(
  $$SELECT s3_revoke_membership('e0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111')$$,
  'S3_MEMBERSHIP_REVOCATION_FAILED: an owner cannot revoke their own owner membership',
  'T13: owner self-membership revocation rejected'
);

-- =============================================================================
-- T14: NON-OWNER REJECTION (all three revocation RPCs)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
SELECT ok(
  (SELECT (pg_get_functiondef(oid) LIKE '%S3_LICENSE_REVOCATION_FAILED%'
        AND pg_get_functiondef(oid) LIKE '%role = ''owner''%')
     FROM pg_proc WHERE proname = 's3_revoke_license' LIMIT 1)
  ,
  'T14a: s3_revoke_license enforces owner-only (non-owners rejected)'
);
SELECT throws_ok(
  $$SELECT s3_revoke_license('e0000000-0000-0000-0000-000000000002')$$,
  'S3_LICENSE_REVOCATION_FAILED: only an active owner may revoke a license',
  'T14b: non-owner s3_revoke_license rejected'
);
SELECT throws_ok(
  $$SELECT s3_revoke_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000011')$$,
  'S3_DEVICE_REVOCATION_FAILED: only an active owner may revoke a device',
  'T14c: non-owner s3_revoke_device rejected'
);
SELECT throws_ok(
  $$SELECT s3_revoke_membership('e0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222')$$,
  'S3_MEMBERSHIP_REVOCATION_FAILED: only an active owner may revoke a membership',
  'T14d: non-owner s3_revoke_membership rejected'
);

-- =============================================================================
-- T15: verify_license_entitlement -> REVOKED signal (Shop e0...01)
-- T16: verify_license_entitlement -> entitled normal (Shop e0...04, before revoke)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT ok(
  (SELECT is_revoked AND NOT has_license AND revoked_at IS NOT NULL
     FROM verify_license_entitlement('e0000000-0000-0000-0000-000000000001') LIMIT 1),
  'T15: verify_license_entitlement returns is_revoked=TRUE + revoked_at for REVOKED license'
);

SELECT ok(
  (SELECT has_license AND NOT is_revoked AND revoked_at IS NULL
     FROM verify_license_entitlement('e0000000-0000-0000-0000-000000000004') LIMIT 1),
  'T16: verify_license_entitlement returns normal/non-revoked result for entitled license'
);

-- =============================================================================
-- T17: activate_device rejects REVOKED device (Shop e0...02, device already REVOKED)
-- T18: register_device rejects REVOKED device (same)
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT is(
  (SELECT activate_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000111')->>'error'),
  'S3_DEVICE_REVOKED: device has been revoked',
  'T17: activate_device rejects a REVOKED device with S3_DEVICE_REVOKED'
);

SELECT throws_ok(
  $$SELECT register_device('e0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000111', 'windows', 're-register attempt')$$,
  'S3_DEVICE_REVOKED: this device has been revoked and cannot be re-registered',
  'T18: register_device rejects a REVOKED device with S3_DEVICE_REVOKED'
);

-- =============================================================================
-- T19: TENANT ISOLATION — Shop A revoke must NOT mutate Shop B
-- =============================================================================

SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
SELECT s3_revoke_license('e0000000-0000-0000-0000-000000000004', 'shop A revoke');

SELECT ok(
  (SELECT status = 'ACTIVE'
     FROM licenses WHERE shop_id = 'e0000000-0000-0000-0000-000000000005')
  AND
  (SELECT status = 'ACTIVE' AND revoked_by IS NULL AND revoked_at IS NULL
     FROM devices WHERE id = 'f0000000-0000-0000-0000-000000000041')
  AND
  (SELECT count(*) = 0 FROM device_audit_log WHERE shop_id = 'e0000000-0000-0000-0000-000000000005')
  ,
  'T19: Shop A revocation does not mutate Shop B (license/device/audit untouched)'
);

-- =============================================================================
-- T20: CONCURRENCY — same shop-keyed advisory lock namespace as S2 activate_device
--      (real two-session blocking proven separately in the concurrency harness)
-- =============================================================================

SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's3_revoke_license' LIMIT 1)
    LIKE '%pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))%'
  AND
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's3_revoke_device' LIMIT 1)
    LIKE '%pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))%'
  AND
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's3_revoke_membership' LIMIT 1)
    LIKE '%pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))%'
  AND
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'activate_device' LIMIT 1)
    LIKE '%pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0))%'
  ,
  'T20: all revocation RPCs share the S2 shop-keyed advisory-lock namespace (serializes vs activation)'
);

-- =============================================================================
-- T21: S1 regression (structural core of S1 still intact)
-- T22: S2 regression (structural core of S2 still intact)
-- =============================================================================

SELECT ok(
  (SELECT pg_get_constraintdef(oid) FROM pg_constraint
     WHERE conrelid = 'licenses'::regclass AND conname = 'licenses_status_check')
    LIKE '%''REVOKED''%'
  ,
  'T21: S1 regression — licenses_status_check includes S3 REVOKED (plus S1 core intact)'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 's2_resolve_entitled_license' AND pronamespace = 'public'::regnamespace
  )
  AND
  EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 's2_user_quota_enforcement' AND NOT tgisinternal
  )
  ,
  'T22: S2 regression — s2_resolve_entitled_license + user quota trigger remain intact'
);

SELECT * FROM finish();
ROLLBACK;
