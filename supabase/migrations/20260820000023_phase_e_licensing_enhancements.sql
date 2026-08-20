-- Phase E Migration 23: Licensing & Trial Enhancements
-- licenses: add updated_at, max_devices, revoked_at, metadata columns
-- activations: add status CHECK constraint
-- New functions: verify_license_entitlement, register_device, activate_device,
--                deactivate_device, get_device_list
--
-- This migration is ADDITIVE ONLY — no destructive changes to existing data.

-- ============================================================================
-- 1. licenses table additions
-- ============================================================================

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS max_devices INTEGER NOT NULL DEFAULT 3;

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN licenses.updated_at IS 'Phase E: last update timestamp for the license record';
COMMENT ON COLUMN licenses.max_devices IS 'Phase E: maximum number of device activations allowed under this license';
COMMENT ON COLUMN licenses.revoked_at IS 'Phase E: timestamp when the license was revoked (terminal state)';
COMMENT ON COLUMN licenses.metadata IS 'Phase E: flexible JSON metadata for the license';

-- ============================================================================
-- 2. activations table: add CHECK constraint on status
-- ============================================================================

ALTER TABLE activations
  ADD CONSTRAINT activations_status_check
  CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED'));

COMMENT ON CONSTRAINT activations_status_check ON activations IS 'Phase E: restrict activation status to valid values';

-- ============================================================================
-- 3. Function: verify_license_entitlement(p_shop_id UUID)
--    Resolves the current entitlement for a given shop.
-- ============================================================================

CREATE OR REPLACE FUNCTION verify_license_entitlement(p_shop_id UUID)
RETURNS TABLE (
  has_license BOOLEAN,
  license_status TEXT,
  is_trial BOOLEAN,
  trial_active BOOLEAN,
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  days_remaining INTEGER,
  hours_remaining INTEGER,
  activated_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  max_devices INTEGER,
  current_devices BIGINT,
  device_slot_available BOOLEAN,
  server_time TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_license licenses%ROWTYPE;
  v_active_count BIGINT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  -- Verify the caller has active membership in the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'Not a member of this shop';
  END IF;

  -- Find the most recent active license (TRIAL/ACTIVE/PERPETUAL)
  SELECT * INTO v_license
  FROM licenses
  WHERE shop_id = p_shop_id
    AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    has_license := false;
    license_status := NULL;
    is_trial := false;
    trial_active := false;
    trial_started_at := NULL;
    trial_expires_at := NULL;
    days_remaining := NULL;
    hours_remaining := NULL;
    activated_at := NULL;
    subscription_expires_at := NULL;
    max_devices := NULL;
    current_devices := 0;
    device_slot_available := false;
    server_time := now();
    RETURN NEXT;
    RETURN;
  END IF;

  has_license := true;
  license_status := v_license.status;
  is_trial := v_license.status = 'TRIAL';
  trial_started_at := v_license.trial_started_at;
  trial_expires_at := v_license.trial_expires_at;
  activated_at := v_license.activated_at;
  subscription_expires_at := v_license.subscription_expires_at;
  max_devices := v_license.max_devices;
  server_time := now();

  -- Compute trial_active and remaining time
  IF v_license.status = 'TRIAL' AND v_license.trial_expires_at IS NOT NULL THEN
    IF v_license.trial_expires_at > now() THEN
      trial_active := true;
      days_remaining := EXTRACT(DAY FROM (v_license.trial_expires_at - now()))::INTEGER;
      hours_remaining := EXTRACT(HOUR FROM (v_license.trial_expires_at - now()))::INTEGER;
    ELSE
      trial_active := false;
      days_remaining := 0;
      hours_remaining := 0;
    END IF;
  ELSE
    trial_active := false;
    days_remaining := NULL;
    hours_remaining := NULL;
  END IF;

  -- Count current active device activations
  SELECT COUNT(*) INTO v_active_count
  FROM activations a
  JOIN devices d ON a.device_id = d.id
  WHERE a.license_id = v_license.id
    AND a.status = 'ACTIVE'
    AND d.status = 'ACTIVE';

  current_devices := v_active_count;
  device_slot_available := v_active_count < v_license.max_devices;

  RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION verify_license_entitlement(UUID) IS 'Phase E: resolves the current licensing entitlement for a shop, server-authoritative';

-- ============================================================================
-- 4. Function: register_device(p_shop_id, p_installation_id, p_platform, p_device_name)
--    Registers or updates a device record. Idempotent via upsert.
-- ============================================================================

CREATE OR REPLACE FUNCTION register_device(
  p_shop_id UUID,
  p_installation_id UUID,
  p_platform TEXT,
  p_device_name TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_device_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  IF p_installation_id IS NULL THEN
    RAISE EXCEPTION 'Installation ID is required';
  END IF;

  IF p_platform IS NULL OR p_platform NOT IN ('windows', 'android') THEN
    RAISE EXCEPTION 'Platform must be windows or android';
  END IF;

  -- Verify the caller has active membership in the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'Not a member of this shop';
  END IF;

  -- Upsert device by (installation_id, shop_id)
  INSERT INTO devices (installation_id, shop_id, user_id, platform, device_name, first_seen_at, last_seen_at, status)
  VALUES (p_installation_id, p_shop_id, v_user_id, p_platform, p_device_name, now(), now(), 'ACTIVE')
  ON CONFLICT (installation_id, shop_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    device_name = EXCLUDED.device_name,
    last_seen_at = now(),
    status = 'ACTIVE'
  RETURNING id INTO v_device_id;

  RETURN v_device_id;
END;
$$;

-- Add unique index for the upsert if not exists
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_installation_shop
  ON devices (installation_id, shop_id);

COMMENT ON FUNCTION register_device(UUID, UUID, TEXT, TEXT) IS 'Phase E: registers or updates a device installation, idempotent';

-- ============================================================================
-- 5. Function: activate_device(p_shop_id, p_installation_id)
--    Activates a device under the shop license. Enforces max_devices.
-- ============================================================================

CREATE OR REPLACE FUNCTION activate_device(
  p_shop_id UUID,
  p_installation_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_license licenses%ROWTYPE;
  v_device devices%ROWTYPE;
  v_activation activations%ROWTYPE;
  v_active_count BIGINT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL OR p_installation_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID and Installation ID are required';
  END IF;

  -- Verify the caller has active membership in the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'Not a member of this shop';
  END IF;

  -- Find the shop's active license
  SELECT * INTO v_license
  FROM licenses
  WHERE shop_id = p_shop_id
    AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No active license for this shop'
    );
  END IF;

  -- Find the device
  SELECT * INTO v_device
  FROM devices
  WHERE installation_id = p_installation_id
    AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Device not registered. Call register_device first.'
    );
  END IF;

  -- Check for existing activation (idempotent)
  SELECT * INTO v_activation
  FROM activations
  WHERE license_id = v_license.id
    AND device_id = v_device.id
    AND status = 'ACTIVE';

  IF FOUND THEN
    -- Already activated — return success with existing activation
    RETURN jsonb_build_object(
      'success', true,
      'activation_id', v_activation.id,
      'devices_remaining', v_license.max_devices - (
        SELECT COUNT(*) FROM activations a
        JOIN devices d ON a.device_id = d.id
        WHERE a.license_id = v_license.id
          AND a.status = 'ACTIVE'
          AND d.status = 'ACTIVE'
      )
    );
  END IF;

  -- Count current active activations
  SELECT COUNT(*) INTO v_active_count
  FROM activations a
  JOIN devices d ON a.device_id = d.id
  WHERE a.license_id = v_license.id
    AND a.status = 'ACTIVE'
    AND d.status = 'ACTIVE';

  -- Check device limit
  IF v_active_count >= v_license.max_devices THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Device limit reached (' || v_active_count || '/' || v_license.max_devices || ')',
      'devices_remaining', 0
    );
  END IF;

  -- Create activation
  INSERT INTO activations (license_id, device_id, activated_at, last_verified_at, status)
  VALUES (v_license.id, v_device.id, now(), now(), 'ACTIVE')
  RETURNING * INTO v_activation;

  RETURN jsonb_build_object(
    'success', true,
    'activation_id', v_activation.id,
    'devices_remaining', v_license.max_devices - v_active_count - 1
  );
END;
$$;

COMMENT ON FUNCTION activate_device(UUID, UUID) IS 'Phase E: activates a device under the shop license, enforces max_devices';

-- ============================================================================
-- 6. Function: deactivate_device(p_activation_id UUID)
--    Owner-only: deactivates a device activation.
-- ============================================================================

CREATE OR REPLACE FUNCTION deactivate_device(p_activation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_activation activations%ROWTYPE;
  v_license licenses%ROWTYPE;
  v_is_owner BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_activation_id IS NULL THEN
    RAISE EXCEPTION 'Activation ID is required';
  END IF;

  -- Find the activation
  SELECT * INTO v_activation
  FROM activations
  WHERE id = p_activation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Activation not found';
  END IF;

  -- Find the license
  SELECT * INTO v_license
  FROM licenses
  WHERE id = v_activation.license_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'License not found';
  END IF;

  -- Verify the caller is the owner of the shop
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = v_license.shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'Only the shop owner can deactivate devices';
  END IF;

  -- Deactivate (set status to REVOKED)
  UPDATE activations
  SET status = 'REVOKED'
  WHERE id = p_activation_id;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION deactivate_device(UUID) IS 'Phase E: owner-only device deactivation, frees a device slot';

-- ============================================================================
-- 7. Function: get_device_list(p_shop_id UUID)
--    Owner-only: returns all devices with activation status for the shop.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_device_list(p_shop_id UUID)
RETURNS TABLE (
  device_id UUID,
  installation_id UUID,
  platform TEXT,
  device_name TEXT,
  status TEXT,
  first_seen_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ,
  activation_id UUID,
  activation_status TEXT,
  activated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_owner BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  -- Verify the caller is the owner of the shop
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'Only the shop owner can view the device list';
  END IF;

  RETURN QUERY
  SELECT
    d.id AS device_id,
    d.installation_id,
    d.platform,
    d.device_name,
    d.status,
    d.first_seen_at,
    d.last_seen_at,
    a.id AS activation_id,
    a.status AS activation_status,
    a.activated_at
  FROM devices d
  LEFT JOIN activations a ON a.device_id = d.id AND a.status = 'ACTIVE'
  WHERE d.shop_id = p_shop_id
  ORDER BY d.first_seen_at DESC;
END;
$$;

COMMENT ON FUNCTION get_device_list(UUID) IS 'Phase E: owner-only function to list all devices and activations for a shop';
