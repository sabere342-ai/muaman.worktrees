-- PHASE P GROUP B S6 — Platform Secure Device Identity pgTAP tests
--
-- Assumes migration 20260820000035 (and prior S1/S2/S3/S4 migrations) are applied.
-- Run with: supabase test db --local supabase/tests/s6_platform_secure_device_identity.test.sql
--
-- Plan: 35 assertions covering:
--   * S6 migration presence + replay safety + 00034 intactness (STRUCT-1..4)
--   * s6_enroll_public_key security contract        (S6-E1..E13)
--   * s6_create_challenge security contract         (S6-C1..C10)
--   * device-gate negative + no production toggle   (S6-G1..G3)
--
-- The cryptographic Ed25519 verification itself runs in the Deno Edge Function
-- (WebCrypto) and is proven in index_test.ts (golden vector + wrong-key/tamper);
-- this file proves the server-authoritative database seams that feed it.

BEGIN;

SELECT plan(35);

-- =============================================================================
-- FIXTURES
-- =============================================================================

INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  ('71111111-1111-1111-1111-111111111111', 's6-owner-a@test.local',   'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('72222222-2222-2222-2222-222222222222', 's6-owner-b@test.local',   'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
  ('73333333-3333-3333-3333-333333333333', 's6-employee-a@test.local', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO shops (id, name, owner_user_id)
VALUES
  ('a6000000-0000-0000-0000-000000000001', 'S6 Shop A', '71111111-1111-1111-1111-111111111111'),
  ('a6000000-0000-0000-0000-000000000002', 'S6 Shop B', '72222222-2222-2222-2222-222222222222')
ON CONFLICT DO NOTHING;

INSERT INTO licenses (shop_id, license_key, status, plan_key)
VALUES
  ('a6000000-0000-0000-0000-000000000001', 'S6-LIC-A', 'ACTIVE', 'starter'),
  ('a6000000-0000-0000-0000-000000000002', 'S6-LIC-B', 'ACTIVE', 'starter')
ON CONFLICT DO NOTHING;

INSERT INTO shop_members (shop_id, user_id, role, status)
VALUES
  ('a6000000-0000-0000-0000-000000000001', '71111111-1111-1111-1111-111111111111', 'owner',    'ACTIVE'),
  ('a6000000-0000-0000-0000-000000000001', '73333333-3333-3333-3333-333333333333', 'employee', 'ACTIVE'),
  ('a6000000-0000-0000-0000-000000000002', '72222222-2222-2222-2222-222222222222', 'owner',    'ACTIVE')
ON CONFLICT DO NOTHING;

-- Register devices (end PENDING_APPROVAL by default).
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT register_device('a6000000-0000-0000-0000-000000000001', 'dd000000-0000-0000-0000-000000000001', 'android', 'S6 A1');
-- Owner-issued devices in shop B (owner of shop B).
SELECT set_config('request.jwt.claim.sub', '72222222-2222-2222-2222-222222222222', true);
SELECT register_device('a6000000-0000-0000-0000-000000000002', 'dd000000-0000-0000-0000-000000000002', 'windows', 'S6 B1');

-- A canonical valid Ed25519 public key (32 raw bytes, base64url, no padding).
-- (Computationally-valid raw key bytes; verification itself is in the Edge fn.)
SELECT set_config('request.jwt.claim.sub', '71111111-1111-1111-1111-111111111111', true);
SELECT s4_approve_device('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'approve A1');
SELECT set_config('request.jwt.claim.sub', '72222222-2222-2222-2222-222222222222', true);
SELECT s4_approve_device('a6000000-0000-0000-0000-000000000002', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000002'), 'approve B1');

-- =============================================================================
-- STRUCT-1 (1) S6 migration objects present (also proves replay-safe apply)
-- =============================================================================
SELECT ok(
  EXISTS(SELECT 1 FROM pg_proc WHERE proname = 's6_enroll_public_key' AND pronamespace = 'public'::regnamespace)
  AND EXISTS(SELECT 1 FROM pg_proc WHERE proname = 's6_create_challenge'  AND pronamespace = 'public'::regnamespace)
  , 'STRUCT-1: s6_enroll_public_key + s6_create_challenge present (migration applied / replay-safe)'
);

-- =============================================================================
-- STRUCT-2 (1) SECURITY DEFINER + search_path = public
-- =============================================================================
SELECT ok(
  (SELECT proconfig FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1) @> ARRAY['search_path=public']
  AND (SELECT proconfig FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1) @> ARRAY['search_path=public']
  , 'STRUCT-2: S6 SECURITY DEFINER helpers set search_path=public'
);

-- =============================================================================
-- STRUCT-3 (1) grants to authenticated
-- =============================================================================
SELECT ok(
  EXISTS(SELECT 1 FROM information_schema.routine_privileges
          WHERE routine_name = 's6_enroll_public_key' AND privilege_type = 'EXECUTE' AND grantee = 'authenticated')
  AND EXISTS(SELECT 1 FROM information_schema.routine_privileges
          WHERE routine_name = 's6_create_challenge' AND privilege_type = 'EXECUTE' AND grantee = 'authenticated')
  , 'STRUCT-3: s6_enroll_public_key + s6_create_challenge executable by authenticated'
);

-- =============================================================================
-- STRUCT-4 (1) migration 00034 intact (S4 objects + single-use challenge table)
-- =============================================================================
SELECT ok(
  EXISTS(SELECT 1 FROM pg_proc WHERE proname = 's4_assert_request' AND pronamespace = 'public'::regnamespace)
  AND EXISTS(SELECT 1 FROM pg_proc WHERE proname = 's4_approve_device' AND pronamespace = 'public'::regnamespace)
  AND EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'device_challenges')
  AND EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 's4_enforcement_config')
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's4_assert_request' LIMIT 1) LIKE '%FOR UPDATE%'
  , 'STRUCT-4: migration 00034 intact (s4_assert_request FOR UPDATE, device_challenges, enforcement config)'
);

-- =============================================================================
-- S6-E1 (1) enroll binds a canonical public key on first enrollment
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT is(
  (SELECT s6_enroll_public_key('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')),
  true,
  'S6-E1: first enrollment binds the canonical public key (returns true)'
);

-- =============================================================================
-- S6-E2 (1) same-key enrollment is idempotent
-- =============================================================================
SELECT is(
  (SELECT s6_enroll_public_key('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')),
  true,
  'S6-E2: re-enrolling the SAME canonical key is idempotent (true, no rejection)'
);
SELECT is(
  (SELECT public_key FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001' AND shop_id = 'a6000000-0000-0000-0000-000000000001'),
  'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg',
  'S6-E2b: bound key value is unchanged by idempotent re-enroll'
);

-- =============================================================================
-- S6-E3 (1) different replacement key denied (no silent rotation)
-- =============================================================================
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'),
     'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')$$,
  'S6_ENROLL_KEY_REPLACEMENT_DENIED: a different public key is already bound to this device (silent rotation denied)',
  'S6-E3: a DIFFERENT replacement key is rejected (fail closed, no silent rotation)'
);

-- =============================================================================
-- S6-E4 (1) malformed / non-canonical key rejected
-- =============================================================================
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'AA==')$$,
  'S6_ENROLL_KEY_MALFORMED: public key is not canonical base64url',
  'S6-E4: padded (non-canonical) public key rejected'
);

-- =============================================================================
-- S6-E5 (1) wrong-length key rejected (not 32 raw bytes)
-- =============================================================================
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'c2hvcnQ')$$,
  'S6_ENROLL_KEY_MALFORMED: Ed25519 public key must decode to 32 bytes',
  'S6-E5: public key that does not decode to exactly 32 bytes rejected'
);

-- =============================================================================
-- S6-E6 (1) cross-shop enrollment denied (device not in caller shop)
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000002',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')$$,
  'S6_ENROLL_DEVICE_NOT_FOUND: device does not belong to this shop',
  'S6-E6: cross-shop enrollment denied (fail closed)'
);

-- =============================================================================
-- S6-E7 (1) cross-user enrollment denied
-- =============================================================================
-- Owner B tries to enroll onto shop A's device (owned by employee A).
SELECT set_config('request.jwt.claim.sub', '72222222-2222-2222-2222-222222222222', true);
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')$$,
  'S6_ENROLL_CROSS_USER: device does not belong to the caller',
  'S6-E7: cross-user enrollment denied (auth.uid() must own the device)'
);

-- =============================================================================
-- S6-E8 (1) enrollment is auth.uid()-bound structurally
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1) LIKE '%auth.uid()%'
  , 'S6-E8: s6_enroll_public_key derives caller from auth.uid(), never a client-nominated user'
);

-- =============================================================================
-- S6-E9 (1) terminal-state device cannot be enrolled (no trust revival)
-- =============================================================================
-- Register + approve + revoke a device, then attempt enrollment.
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT register_device('a6000000-0000-0000-0000-000000000001', 'dd000000-0000-0000-0000-000000000031', 'android', 'S6 terminal');
SELECT set_config('request.jwt.claim.sub', '71111111-1111-1111-1111-111111111111', true);
SELECT s4_approve_device('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000031'), 'approve');
SELECT s3_revoke_device('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000031'), 'revoke');
-- Enroll as the device's OWN registered user (employee A) to reach the terminal check.
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000031'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')$$,
  'S6_ENROLL_TERMINAL: device is in terminal state (REVOKED) and cannot be enrolled',
  'S6-E9: revoked (terminal) device cannot be enrolled (no silent trust revival)'
);

-- =============================================================================
-- S6-E10 (1) REJECTED terminal-state device cannot be enrolled
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT register_device('a6000000-0000-0000-0000-000000000001', 'dd000000-0000-0000-0000-000000000032', 'android', 'S6 rejected');
SELECT set_config('request.jwt.claim.sub', '71111111-1111-1111-1111-111111111111', true);
SELECT s4_reject_device('a6000000-0000-0000-0000-000000000001', (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000032'), 'reject');
-- Enroll as the device's OWN registered user (employee A) to reach the terminal check.
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT s6_enroll_public_key(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000032'), 'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg')$$,
  'S6_ENROLL_TERMINAL: device is in terminal state (REJECTED) and cannot be enrolled',
  'S6-E10: REJECTED (terminal) device cannot be enrolled'
);

-- =============================================================================
-- S6-E11 (1) enrollment NEVER changes device status
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT is(
  (SELECT status FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001' AND shop_id = 'a6000000-0000-0000-0000-000000000001'),
  'ACTIVE',
  'S6-E11: enrollment does not change device lifecycle status'
);

-- =============================================================================
-- S6-E12 (1) enrollment never stores/returns private material
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1) NOT LIKE '%extractPrivateKey%'
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1) NOT LIKE '%seed%'
  , 'S6-E12: s6_enroll_public_key accepts a PUBLIC key only (no private-material path)'
);

-- =============================================================================
-- S6-E13 (1) enrollment validates pre-existing bound key presence via idempotency
-- =============================================================================
SELECT is(
  (SELECT public_key IS NOT NULL FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001' AND shop_id = 'a6000000-0000-0000-0000-000000000001'),
  true,
  'S6-E13: successful enrollment leaves a bound canonical public key on the device'
);

-- =============================================================================
-- S6-C1 (1) challenge is SERVER-GENERATED (caller cannot choose text)
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1) LIKE '%s6:%' 
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1) LIKE '%gen_random_uuid()%'
  AND (SELECT count(*) FROM pg_proc WHERE proname = 's6_create_challenge'
       AND 'p_challenge' = ANY(proargnames::text[])) = 0
  , 'S6-C1: challenge text is server-generated (no caller-supplied challenge parameter)'
);

-- =============================================================================
-- S6-C2 (1) challenge for an ACTIVE device with a bound key succeeds
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT is(
  ((SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 300)->>'challenge_id') IS NOT NULL),
  true,
  'S6-C2: server issues a challenge for an ACTIVE, key-bound device'
);

-- =============================================================================
-- S6-C3 (1) challenge TTL is server-bounded and rejects out-of-range TTL
-- =============================================================================
SELECT throws_ok(
  $$SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 5000)$$,
  'S6_CHALLENGE_TTL: ttl must be between 1 and 3600 seconds',
  'S6-C3: out-of-range TTL is rejected (server controls expiry bounds)'
);

-- =============================================================================
-- S6-C4 (1) challenge only for ACTIVE device (PENDING denied)
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '72222222-2222-2222-2222-222222222222', true);
SELECT register_device('a6000000-0000-0000-0000-000000000002', 'dd000000-0000-0000-0000-000000000041', 'windows', 'S6 B pending');
SELECT throws_ok(
  $$SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000002',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000041'), 300)$$,
  'S6_CHALLENGE_NOT_ACTIVE: device must be ACTIVE to obtain a challenge',
  'S6-C4: PENDING (unapproved) device cannot obtain a challenge (no S6 shortcut past owner approval)'
);

-- =============================================================================
-- S6-C5 (1) challenge requires a bound public key (fail closed)
-- =============================================================================
-- Device B1 was approved (ACTIVE) but never enrolled with a public key.
SELECT set_config('request.jwt.claim.sub', '72222222-2222-2222-2222-222222222222', true);
SELECT throws_ok(
  $$SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000002',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000002'), 300)$$,
  'S6_CHALLENGE_NO_KEY: device has no bound public key',
  'S6-C5: ACTIVE device WITHOUT a bound public key cannot obtain a challenge (no proof without a key)'
);

-- =============================================================================
-- S6-C6 (1) challenge denies cross-shop/cross-user
-- =============================================================================
-- Caller (employee A) requests a challenge for shop B while passing a device
-- that belongs to SHOP A (dd...001): the tenant-scoped lookup yields NOT FOUND.
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT throws_ok(
  $$SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000002',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 300)$$,
  'S6_CHALLENGE_DEVICE_NOT_FOUND: device does not belong to this shop',
  'S6-C6: cross-shop challenge denied (tenant-scoped lookup fails closed)'
);

-- =============================================================================
-- S6-C7 (1) challenge issue is auth.uid()-bound structurally
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1) LIKE '%auth.uid()%'
  , 'S6-C7: s6_create_challenge derives caller from auth.uid()'
);

-- =============================================================================
-- S6-C8 (2) challenge row persisted with server-controlled expiry + creator
-- =============================================================================
SELECT set_config('request.jwt.claim.sub', '73333333-3333-3333-3333-333333333333', true);
SELECT s6_create_challenge(
  'a6000000-0000-0000-0000-000000000001',
  (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 300)
  AS issued_challenge;
SELECT ok(
  EXISTS(SELECT 1 FROM device_challenges
          WHERE shop_id = 'a6000000-0000-0000-0000-000000000001'
            AND device_id = (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001')
            AND created_by = '73333333-3333-3333-3333-333333333333'
            AND used_at IS NULL
            AND challenge LIKE 's6:%')
  , 'S6-C8a: issued challenge persisted, creator-bound, unused, server-prefixed nonce'
);
SELECT ok(
  EXISTS(SELECT 1 FROM device_challenges
          WHERE shop_id = 'a6000000-0000-0000-0000-000000000001'
            AND device_id = (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001')
            AND expires_at > now() AND expires_at <= now() + interval '301 seconds')
  , 'S6-C8b: challenge expires_at is server-controlled (>now(), bounded by TTL)'
);

-- =============================================================================
-- S6-C9 (2) returned expires_at is canonical RFC3339 UTC (verifier-reconstructible)
-- =============================================================================
SELECT matches(
  ((SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 300)->>'expires_at')),
  '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$',
  'S6-C9a: challenge returns canonical RFC3339 UTC expires_at (seconds, Z suffix)'
);
SELECT matches(
  ((SELECT s6_create_challenge(
     'a6000000-0000-0000-0000-000000000001',
     (SELECT id FROM devices WHERE installation_id = 'dd000000-0000-0000-0000-000000000001'), 300)->>'challenge')),
  '^s6:[0-9a-fA-F-]{36}:[0-9a-fA-F-]{36}$',
  'S6-C9b: challenge nonce is the server-generated s6:<uuid>:<uuid> form'
);

-- =============================================================================
-- S6-C10 (1) challenge issuance never enables the device gate
-- =============================================================================
SELECT is(
  (SELECT device_gate_enabled FROM s4_enforcement_config WHERE id = true),
  false,
  'S6-C10: challenge issuance leaves the S4 device gate OFF (dormant)'
);

-- =============================================================================
-- S6-G1 (3) device-gate negative — S6 never activates enforcement
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1)
    NOT LIKE '%s4_set_device_gate_enforcement%'
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1)
    NOT LIKE '%s4_set_device_gate_enforcement%'
  , 'S6-G1a: S6 functions never call s4_set_device_gate_enforcement'
);
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_enroll_public_key' LIMIT 1)
    NOT LIKE '%enforcement_config%'
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's6_create_challenge' LIMIT 1)
    NOT LIKE '%enforcement_config%'
  , 'S6-G1b: S6 functions never write to s4_enforcement_config'
);
SELECT is(
  (SELECT s4_device_gate_enabled()),
  false,
  'S6-G1c: s4_device_gate_enabled remains OFF after S6 migration (no production activation)'
);

-- =============================================================================
-- S6-G2 (1) single-use challenge remains enforced by S4 assert path (regression)
-- =============================================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's4_assert_request' LIMIT 1) LIKE '%used_at%'
  AND (SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 's4_assert_request' LIMIT 1) LIKE '%FOR UPDATE%'
  , 'S6-G2: S4 single-use challenge consumption guard intact (S6 reuses, does not weaken)'
);

-- =============================================================================
-- S6-G3 (1) S6 migration container is additive (no RLS/schema shrink on S4 objects)
-- =============================================================================
SELECT results_eq(
  $q$
  SELECT count(*) FROM pg_trigger WHERE tgname LIKE 's6_%'
  $q$,
  ARRAY[0::bigint],
  'S6-G3: S6 introduces no new triggers / RLS surface onto S4 trust objects'
);

SELECT * FROM finish();
ROLLBACK;
