-- Phase P Group B S6: Platform Secure Device Identity
--
-- ADDITIVE, IDEMPOTENT / REPLAY-SAFE, FORWARD-ONLY, SERVER-AUTHORITATIVE.
-- This migration is S6-only and does NOT modify migration 00034.
--
-- S6 adds (to the existing S4 server trust clay):
--   1. A narrow PUBLIC-KEY ENROLLMENT seam that binds a canonical Ed25519
--      public key to a device exactly once (device, shop, user, installation),
--      is idempotent for the SAME already-bound key, rejects a DIFFERENT
--      replacement key, and never reactivates terminal device state.
--   2. A server-generated CHALLENGE seam where the caller does NOT choose the
--      challenge text: the server generates a cryptographically strong nonce,
--      controls expires_at, and binds the challenge to the authenticated user,
--      shop, device, and (via the device row) installation.
--
-- S6 never stores a private key, never silently rotates a bound public key,
-- never enables the S4 device gate, and does not deploy to production.
--
-- Ed25519 RFC 8032: public key = 32 bytes, canonical base64url (no padding).
-- The actual signature verification runs in the Deno Edge Function (WebCrypto).

-- =============================================================================
-- 1. s6_enroll_public_key — bind canonical Ed25519 public key exactly once
-- =============================================================================
-- Security contract (Governance Section O):
--   - accepts a PUBLIC key only (never private material)
--   - derives/verifies caller identity server-side (auth.uid())
--   - canonicalizes + validates the Ed25519 public key (32 bytes, base64url)
--   - binds exactly once, scoped to (device_id, shop_id, user_id, installation_id)
--   - idempotent for the SAME already-bound canonical key
--   - REJECTS a DIFFERENT replacement key (fail closed, no silent rotation)
--   - rejects cross-shop / cross-user substitution
--   - never reactivates terminal device state (REVOKED/LOST/REJECTED)
--   - never changes device status
--   - never stores or uploads a private key

CREATE OR REPLACE FUNCTION s6_enroll_public_key(
  p_shop_id UUID,
  p_device_id UUID,
  p_public_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_device  devices%ROWTYPE;
  v_decoded BYTEA;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'S6_ENROLL_AUTH: authentication required' USING ERRCODE = 'check_violation';
  END IF;

  IF p_shop_id IS NULL OR p_device_id IS NULL OR p_public_key IS NULL OR p_public_key = '' THEN
    RAISE EXCEPTION 'S6_ENROLL_INVALID: shop_id, device_id, and public_key are required' USING ERRCODE = 'check_violation';
  END IF;

  -- Canonicalize + validate the Ed25519 public key (Section J).
  -- Canonical form: base64url WITHOUT padding, 32 raw bytes. Strictly reject
  -- padding, non-URL alphabet, embedded whitespace, and wrong length. This is
  -- a deterministic canonicalization that rejects ambiguous encodings.
  IF p_public_key ~ '[^A-Za-z0-9_\-]' OR p_public_key LIKE '%=%' THEN
    RAISE EXCEPTION 'S6_ENROLL_KEY_MALFORMED: public key is not canonical base64url' USING ERRCODE = 'check_violation';
  END IF;
  BEGIN
    v_decoded := decode(replace(replace(p_public_key, '-', '+'), '_', '/')
                         || CASE WHEN (length(p_public_key) % 4) = 2 THEN '=='
                                 WHEN (length(p_public_key) % 4) = 3 THEN '='
                                 ELSE '' END, 'base64');
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'S6_ENROLL_KEY_MALFORMED: public key is not valid base64url' USING ERRCODE = 'check_violation';
  END;
  IF octet_length(v_decoded) <> 32 THEN
    RAISE EXCEPTION 'S6_ENROLL_KEY_MALFORMED: Ed25519 public key must decode to 32 bytes' USING ERRCODE = 'check_violation';
  END IF;

  -- Tenant-scoped device lookup (fail-closed cross-shop). FOR UPDATE to
  -- serialize concurrent enrollment attempts on the same device.
  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id AND shop_id = p_shop_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S6_ENROLL_DEVICE_NOT_FOUND: device does not belong to this shop' USING ERRCODE = 'check_violation';
  END IF;

  -- Cross-user substitution reject: the enrollment must be performed by the
  -- device's own user in the shop.
  IF v_device.user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'S6_ENROLL_CROSS_USER: device does not belong to the caller' USING ERRCODE = 'check_violation';
  END IF;

  -- Terminal device states must NEVER regain trust through enrollment.
  IF v_device.status IN ('REVOKED', 'LOST', 'REJECTED') THEN
    RAISE EXCEPTION 'S6_ENROLL_TERMINAL: device is in terminal state (%) and cannot be enrolled', v_device.status
      USING ERRCODE = 'check_violation';
  END IF;

  -- Binding semantics:
  --   - public_key IS NULL            -> bind now (exactly once)
  --   - public_key = provided         -> idempotent success (same bound key)
  --   - public_key != provided        -> REPLACE a trusted key -> DENIED
  IF v_device.public_key IS NULL THEN
    UPDATE devices SET public_key = p_public_key WHERE id = v_device.id;
    RETURN true;
  END IF;

  IF v_device.public_key = p_public_key THEN
    RETURN true; -- idempotent: same exact binding already present
  END IF;

  RAISE EXCEPTION 'S6_ENROLL_KEY_REPLACEMENT_DENIED: a different public key is already bound to this device (silent rotation denied)'
    USING ERRCODE = 'check_violation';
END;
$$;

COMMENT ON FUNCTION s6_enroll_public_key(UUID, UUID, TEXT) IS
  'S6: binds a canonical Ed25519 public key to a device exactly once, scoped to device/shop/user/installation. Idempotent for the same key; rejects a different replacement key; never reactivates terminal states; never stores a private key.';

GRANT EXECUTE ON FUNCTION s6_enroll_public_key(UUID, UUID, TEXT) TO authenticated;

-- =============================================================================
-- 2. s6_create_challenge — SERVER-GENERATED challenge (no caller-chosen text)
-- =============================================================================
-- Security contract (Governance Section P):
--   - caller does NOT choose challenge text; server generates a CSPRNG nonce
--   - server controls expires_at (client clock cannot extend it)
--   - binds the challenge to: current authenticated user + shop + device
--   - installation is bound transitively via the device row
--   - reuses the existing device_challenges infrastructure (no new trust table)
--   - single-use consumption remains server-authoritative (s4_assert_request)
--
-- Challenge randomness uses PostgreSQL core gen_random_uuid() (122-bit CSPRNG
-- entropy per call, guaranteed PG 13+) ×2 – cryptographically suitable without
-- a pgcrypto schema dependency.

CREATE OR REPLACE FUNCTION s6_create_challenge(
  p_shop_id UUID,
  p_device_id UUID,
  p_ttl_seconds INTEGER DEFAULT 300
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_device  devices%ROWTYPE;
  v_challenge TEXT;
  v_challenge_id UUID;
  v_expires_at TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'S6_CHALLENGE_AUTH: authentication required' USING ERRCODE = 'check_violation';
  END IF;

  IF p_shop_id IS NULL OR p_device_id IS NULL THEN
    RAISE EXCEPTION 'S6_CHALLENGE_INVALID: shop_id and device_id are required' USING ERRCODE = 'check_violation';
  END IF;

  IF p_ttl_seconds IS NULL OR p_ttl_seconds < 1 OR p_ttl_seconds > 3600 THEN
    RAISE EXCEPTION 'S6_CHALLENGE_TTL: ttl must be between 1 and 3600 seconds' USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id AND shop_id = p_shop_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S6_CHALLENGE_DEVICE_NOT_FOUND: device does not belong to this shop' USING ERRCODE = 'check_violation';
  END IF;

  IF v_device.user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'S6_CHALLENGE_CROSS_USER: device does not belong to the caller' USING ERRCODE = 'check_violation';
  END IF;

  -- Proof-of-possession happens on an APPROVED (ACTIVE) device only, per the
  -- frozen lifecycle (enroll -> PENDING -> owner approval -> ACTIVE -> proof).
  -- A PENDING/unapproved device cannot obtain a challenge that would later
  -- assert; this prevents any S6 shortcut around owner approval (Section T).
  IF v_device.status <> 'ACTIVE' THEN
    RAISE EXCEPTION 'S6_CHALLENGE_NOT_ACTIVE: device must be ACTIVE to obtain a challenge' USING ERRCODE = 'check_violation';
  END IF;

  -- The bound public key must exist before any proof can be produced; fail
  -- closed early if the device was not enrolled (Section S step 7).
  IF v_device.public_key IS NULL OR v_device.public_key = '' THEN
    RAISE EXCEPTION 'S6_CHALLENGE_NO_KEY: device has no bound public key' USING ERRCODE = 'check_violation';
  END IF;

  -- Server generates the nonce/challenge text. Caller never supplies it.
  v_challenge := 's6:' || gen_random_uuid()::text || ':' || gen_random_uuid()::text;

  -- Server controls expiry (client clock cannot extend server authority).
  v_expires_at := now() + make_interval(secs => p_ttl_seconds);

  INSERT INTO device_challenges (shop_id, device_id, challenge, expires_at, created_by)
  VALUES (p_shop_id, p_device_id, v_challenge, v_expires_at, v_user_id)
  RETURNING id INTO v_challenge_id;

  -- Return expires_at as a canonical RFC3339 UTC string (seconds precision,
  -- 'Z' suffix) so the client signs exactly the string the verifier later
  -- reconstructs from the stored timestamptz — byte-identical envelope.
  RETURN jsonb_build_object(
    'challenge_id', v_challenge_id,
    'challenge', v_challenge,
    'expires_at', to_char(v_expires_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'shop_id', p_shop_id,
    'device_id', p_device_id
  );
END;
$$;

COMMENT ON FUNCTION s6_create_challenge(UUID, UUID, INTEGER) IS
  'S6: SERVER-GENERATED challenge nonce bound to the authenticated user, shop, device (and installation via the device row). Server controls expires_at. Caller never supplies challenge text. Reuses device_challenges.';

GRANT EXECUTE ON FUNCTION s6_create_challenge(UUID, UUID, INTEGER) TO authenticated;

-- =============================================================================
-- 3. No RLS changes, no schema/table changes, no enforcement activation.
--    The S4 device gate remains OFF by default and is NOT touched here.
-- =============================================================================
