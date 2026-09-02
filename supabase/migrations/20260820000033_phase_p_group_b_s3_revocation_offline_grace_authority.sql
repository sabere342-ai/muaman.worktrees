-- Phase P Group B S3: Revocation / Offline-Grace Authority
--
-- ADDITIVE, IDEMPOTENT / REPLAY-SAFE, FORWARD-ONLY, SERVER-AUTHORITATIVE,
-- NON-DESTRUCTIVE. RLS_POLICY_DELTA = ZERO.
--
-- This migration (S3):
--   1. Extends licenses.status CHECK to include REVOKED (idempotent, additive)
--   2. Creates s3_revoke_license(shop_id, reason)  -- owner-only, cascading
--   3. Creates s3_revoke_device(shop_id, device_id, reason) -- owner-only, cascading
--   4. Creates s3_revoke_membership(shop_id, member_user_id, reason) -- owner-only, cascading
--   5. Extends verify_license_entitlement() additively to 16 columns
--      (adds is_revoked, revoked_at) as the server-authoritative revalidation signal
--   6. Rewrites activate_device() to be revocation-aware (rejects REVOKED devices)
--   7. Rewrites register_device() to be revocation-aware (rejects REVOKED re-registration)
--
-- All revocation mutations serialize under the SAME shop-keyed PostgreSQL
-- transaction advisory lock namespace used by S2 activate_device /
-- s2_enforce_user_quota (hashtextextended(shop_id, 0)).
--
-- Owner decisions binding S3:
--   P-OD9  Offline grace: TRIAL 0d, PAID 7d, PERPETUAL 14d compatibility-only.
--          The server-authoritative anchor is activations.last_verified_at and
--          verify_license_entitlement.server_time; no separate grace timer here.
--   P-OD10 Server authoritative for license/membership/device/permission state
--          and revocation.
--   P-OD11 Bounded production hardening; does NOT claim perfect client anti-tamper.
--
-- Non-goals (deferred):
--   S4 device trust / invitation hardening
--   S5 client entitlement integration
--   S6/S7 platform identity / owner UI
--   S8 client clock/tamper enforcement
--   S11 production deployment

-- =============================================================================
-- 1. licenses.status CHECK — add REVOKED (idempotent, additive, non-destructive)
-- =============================================================================
-- REVOKED is a terminal state for S3. S3 does NOT implement an un-revoke API.

ALTER TABLE licenses
  DROP CONSTRAINT IF EXISTS licenses_status_check;

ALTER TABLE licenses
  ADD CONSTRAINT licenses_status_check
  CHECK (status IN ('TRIAL', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'PERPETUAL', 'REVOKED'));

COMMENT ON COLUMN licenses.status IS
  'License status: TRIAL, ACTIVE, EXPIRED, SUSPENDED, PERPETUAL, or REVOKED (S3 terminal).';

-- =============================================================================
-- 2. s3_revoke_license(shop_id, reason)
-- =============================================================================
-- OWNER-ONLY. Sets the shop's revocable license to REVOKED + revoked_at and
-- cascades: revokes ACTIVE activations bound to that license and revokes the
-- shop's ACTIVE devices (revoked_by / revoked_at populated). Audits each device
-- actually transitioned. Idempotent: already-REVOKED / EXPIRED / SUSPENDED is a
-- safe no-op. Deterministic S3_LICENSE_REVOCATION_FAILED on inconsistent state.

CREATE OR REPLACE FUNCTION s3_revoke_license(
  p_shop_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id  UUID;
  v_license  licenses%ROWTYPE;
  v_affected BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  -- Caller must be an ACTIVE owner of the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'S3_LICENSE_REVOCATION_FAILED: only an active owner may revoke a license'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Same-shop transaction advisory lock (serializes vs S2 activate/register)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Resolve the shop's most recent revocable license (TRIAL/ACTIVE/PERPETUAL)
  SELECT * INTO v_license
  FROM licenses
  WHERE shop_id = p_shop_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S3_LICENSE_REVOCATION_FAILED: no license exists for this shop'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Idempotent no-op: already terminal/not revocable -> no side effects
  IF v_license.status IN ('REVOKED', 'EXPIRED', 'SUSPENDED') THEN
    RETURN true;
  END IF;

  -- Revoke the license (authoritative server time)
  UPDATE licenses
  SET status = 'REVOKED', revoked_at = now()
  WHERE id = v_license.id;

  -- Cascade: revoke ACTIVE activations bound to this license (any device state)
  UPDATE activations
  SET status = 'REVOKED'
  WHERE license_id = v_license.id
    AND status = 'ACTIVE';

  -- Cascade: revoke the shop's ACTIVE devices; audit only those transitioned.
  -- Because this targets status = 'ACTIVE' only, an already-REVOKED device is
  -- never returned by the UPDATE and is never re-audited (idempotent, no dup).
  WITH affected AS (
    UPDATE devices
    SET status = 'REVOKED',
        revoked_by = v_user_id,
        revoked_at = now()
    WHERE shop_id = p_shop_id
      AND status = 'ACTIVE'
    RETURNING id
  )
  INSERT INTO device_audit_log (shop_id, device_id, actor_user_id, action, detail)
  SELECT p_shop_id, id, v_user_id, 'S3_LICENSE_REVOKE',
         jsonb_build_object('reason', p_reason)
  FROM affected;

  SELECT EXISTS(SELECT 1 FROM device_audit_log WHERE shop_id = p_shop_id) INTO v_affected;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION s3_revoke_license(UUID, TEXT) IS
  'S3: owner-only, server-authoritative license revocation with device/activation cascade and audit. Idempotent.';

-- =============================================================================
-- 3. s3_revoke_device(shop_id, device_id, reason)
-- =============================================================================
-- OWNER-ONLY. Sets a shop device to REVOKED + revoked_by/revoked_at, cascades
-- that device's ACTIVE activations to REVOKED, and audits exactly one transition.
-- Idempotent: already-REVOKED is a safe no-op. Deterministic
-- S3_DEVICE_REVOCATION_FAILED on cross-tenant or missing device.

CREATE OR REPLACE FUNCTION s3_revoke_device(
  p_shop_id UUID,
  p_device_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id  UUID;
  v_device   devices%ROWTYPE;
  v_affected BIGINT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL OR p_device_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID and Device ID are required';
  END IF;

  -- Caller must be an ACTIVE owner of the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'S3_DEVICE_REVOCATION_FAILED: only an active owner may revoke a device'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Same-shop transaction advisory lock
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Target device MUST belong to the shop (tenant scoping)
  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id
    AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S3_DEVICE_REVOCATION_FAILED: device does not belong to this shop'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Idempotent no-op: already REVOKED
  IF v_device.status = 'REVOKED' THEN
    RETURN true;
  END IF;

  -- Revoke the device (authoritative server time, server-derived revoker)
  UPDATE devices
  SET status = 'REVOKED',
      revoked_by = v_user_id,
      revoked_at = now()
  WHERE id = v_device.id;

  -- Cascade: revoke this device's ACTIVE activations
  UPDATE activations
  SET status = 'REVOKED'
  WHERE device_id = v_device.id
    AND status = 'ACTIVE';

  -- Audit exactly one device transition (the one just revoked)
  INSERT INTO device_audit_log (shop_id, device_id, actor_user_id, action, detail)
  VALUES (p_shop_id, v_device.id, v_user_id, 'S3_DEVICE_REVOKE',
          jsonb_build_object('reason', p_reason));

  RETURN true;
END;
$$;

COMMENT ON FUNCTION s3_revoke_device(UUID, UUID, TEXT) IS
  'S3: owner-only, tenant-scoped device revocation with activation cascade and audit. Idempotent.';

-- =============================================================================
-- 4. s3_revoke_membership(shop_id, member_user_id, reason)
-- =============================================================================
-- OWNER-ONLY. Sets the target member's shop_members.status = 'REVOKED' and
-- cascades to that member's ACTIVE devices (REVOKED + revoked_by/at) and their
-- ACTIVE activations (REVOKED), auditing each device transitioned. Cannot revoke
-- the owner's own owner membership. Idempotent: already-REVOKED is a safe no-op.
-- Deterministic S3_MEMBERSHIP_REVOCATION_FAILED on cross-tenant/missing member.

CREATE OR REPLACE FUNCTION s3_revoke_membership(
  p_shop_id UUID,
  p_member_user_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id    UUID;
  v_member     shop_members%ROWTYPE;
  v_caller_role TEXT;
  v_affected   BIGINT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL OR p_member_user_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID and Member User ID are required';
  END IF;

  -- Caller must be an ACTIVE owner of the shop
  SELECT role INTO v_caller_role
  FROM shop_members
  WHERE shop_id = p_shop_id
    AND user_id = v_user_id
    AND status = 'ACTIVE';

  IF NOT FOUND OR v_caller_role IS DISTINCT FROM 'owner' THEN
    RAISE EXCEPTION 'S3_MEMBERSHIP_REVOCATION_FAILED: only an active owner may revoke a membership'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Same-shop transaction advisory lock
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Target membership MUST belong to the shop (tenant scoping)
  SELECT * INTO v_member
  FROM shop_members
  WHERE shop_id = p_shop_id
    AND user_id = p_member_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S3_MEMBERSHIP_REVOCATION_FAILED: membership does not exist in this shop'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Owner cannot revoke their own owner membership
  IF v_member.user_id = v_user_id AND v_member.role = 'owner' THEN
    RAISE EXCEPTION 'S3_MEMBERSHIP_REVOCATION_FAILED: an owner cannot revoke their own owner membership'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Idempotent no-op: already REVOKED (or terminal non-ACTIVE)
  IF v_member.status = 'REVOKED' THEN
    RETURN true;
  END IF;

  -- Revoke the membership
  UPDATE shop_members
  SET status = 'REVOKED'
  WHERE id = v_member.id;

  -- Cascade: revoke the member's ACTIVE devices; audit only those transitioned
  WITH affected AS (
    UPDATE devices
    SET status = 'REVOKED',
        revoked_by = v_user_id,
        revoked_at = now()
    WHERE shop_id = p_shop_id
      AND user_id = p_member_user_id
      AND status = 'ACTIVE'
    RETURNING id
  )
  INSERT INTO device_audit_log (shop_id, device_id, actor_user_id, action, detail)
  SELECT p_shop_id, id, v_user_id, 'S3_MEMBERSHIP_REVOKE',
         jsonb_build_object('reason', p_reason)
  FROM affected;

  -- Cascade: revoke those member devices' ACTIVE activations (any device state,
  -- including already-revoked ones from a prior license/device revocation)
  UPDATE activations a
  SET status = 'REVOKED'
  FROM devices d
  WHERE a.device_id = d.id
    AND d.shop_id = p_shop_id
    AND d.user_id = p_member_user_id
    AND a.status = 'ACTIVE';

  RETURN true;
END;
$$;

COMMENT ON FUNCTION s3_revoke_membership(UUID, UUID, TEXT) IS
  'S3: owner-only, tenant-scoped membership revocation with device/activation cascade and audit. Idempotent.';

-- =============================================================================
-- 5. verify_license_entitlement() — additive revalidation signal (16 columns)
-- =============================================================================
-- Preserves all S2 behavior. Additively extends the return surface with
--   is_revoked BOOLEAN, revoked_at TIMESTAMPTZ.
-- For an entitled license (TRIAL/ACTIVE/PERPETUAL): is_revoked=FALSE, revoked_at=NULL.
-- For a REVOKED license: server-authoritative revocation result
--   (has_license=false, is_revoked=TRUE, revoked_at=licenses.revoked_at, server_time=now()).
--
-- PostgreSQL requires DROP before changing an existing function's return type
-- (OUT/ROW type). This is idempotent (DROP IF EXISTS) and non-destructive
-- (functions hold no data). s2_enforce_user_quota depends on
-- s2_resolve_entitled_license, NOT on this function, so nothing is broken.

DROP FUNCTION IF EXISTS verify_license_entitlement(UUID);

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
  server_time TIMESTAMPTZ,
  is_revoked BOOLEAN,
  revoked_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_latest  licenses%ROWTYPE;
  v_license licenses%ROWTYPE;
  v_plan    plans%ROWTYPE;
  v_active_count BIGINT;
  v_effective_limit INTEGER;
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

  server_time := now();

  -- Most recent license for this shop, regardless of status (S3 revocation signal)
  SELECT * INTO v_latest
  FROM licenses
  WHERE shop_id = p_shop_id
  ORDER BY created_at DESC
  LIMIT 1;

  -- S3: if the latest license is REVOKED, return the authoritative revocation result
  IF v_latest.status = 'REVOKED' THEN
    has_license := false;
    license_status := 'REVOKED';
    is_trial := false;
    trial_active := false;
    trial_started_at := NULL;
    trial_expires_at := NULL;
    days_remaining := NULL;
    hours_remaining := NULL;
    activated_at := v_latest.activated_at;
    subscription_expires_at := v_latest.subscription_expires_at;
    max_devices := NULL;
    current_devices := 0;
    device_slot_available := false;
    is_revoked := true;
    revoked_at := v_latest.revoked_at;
    RETURN NEXT;
    RETURN;
  END IF;

  -- Otherwise, standard S2 entitled-license resolution
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
    is_revoked := false;
    revoked_at := NULL;
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

  -- Resolve plan from plans table (S2 canonical authority)
  SELECT * INTO v_plan
  FROM plans
  WHERE key = v_license.plan_key;

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

  -- Device quota: derive from plans.device_limit (not licenses.max_devices)
  IF v_plan.device_limit IS NULL THEN
    v_effective_limit := NULL;
    max_devices := NULL;
    device_slot_available := true;
  ELSE
    v_effective_limit := v_plan.device_limit;
    max_devices := v_plan.device_limit;
  END IF;

  -- Count current active device activations
  SELECT COUNT(*) INTO v_active_count
  FROM activations a
  JOIN devices d ON a.device_id = d.id
  WHERE a.license_id = v_license.id
    AND a.status = 'ACTIVE'
    AND d.status = 'ACTIVE';

  current_devices := v_active_count;

  IF v_effective_limit IS NOT NULL THEN
    device_slot_available := v_active_count < v_effective_limit;
  END IF;

  is_revoked := false;
  revoked_at := NULL;

  RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION verify_license_entitlement(UUID) IS
  'S3: resolves the current licensing entitlement for a shop and exposes authoritative revocation state (is_revoked/revoked_at) on every revalidation. Server-authoritative.';

-- =============================================================================
-- 6. activate_device() — revocation-aware (preserves all S2 behavior)
-- =============================================================================
-- Preserves: auth/membership check, shop-keyed advisory lock, plan-based device
-- quota (s2_resolve_entitled_license), idempotent re-activation, JSONB return.
-- Adds: rejects a REVOKED device with deterministic S3_DEVICE_REVOKED before
-- any quota/activation path. A revoked device MUST NOT regain activation merely
-- because quota space exists. Does NOT absorb S4 device-trust / PENDING_APPROVAL.

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
  v_user_id         UUID;
  v_entitled        RECORD;
  v_device          devices%ROWTYPE;
  v_activation      activations%ROWTYPE;
  v_active_count    BIGINT;
  v_device_limit    INTEGER;
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

  -- Shop-keyed PostgreSQL transaction advisory lock (same namespace as S2)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Resolve entitled license + plan (server-authoritative)
  SELECT * INTO v_entitled
  FROM s2_resolve_entitled_license(p_shop_id);

  IF v_entitled.license_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No active license for this shop'
    );
  END IF;

  -- Plan must be valid for device quota resolution
  IF v_entitled.plan_key IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'S2_PLAN_AUTHORITY_REQUIRED: no valid canonical plan is bound to the entitled license'
    );
  END IF;

  v_device_limit := v_entitled.device_limit;

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

  -- S3: revocation-aware. A REVOKED device MUST NOT be re-activated.
  IF v_device.status = 'REVOKED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'S3_DEVICE_REVOKED: device has been revoked'
    );
  END IF;

  -- Check for existing activation (idempotent — already ACTIVE)
  SELECT * INTO v_activation
  FROM activations
  WHERE license_id = v_entitled.license_id
    AND device_id = v_device.id
    AND status = 'ACTIVE';

  IF FOUND THEN
    -- Already activated — return success (idempotent)
    RETURN jsonb_build_object(
      'success', true,
      'activation_id', v_activation.id,
      'devices_remaining', CASE
        WHEN v_device_limit IS NULL THEN NULL
        ELSE (SELECT COUNT(*) FROM activations a
              JOIN devices d ON a.device_id = d.id
              WHERE a.license_id = v_entitled.license_id
                AND a.status = 'ACTIVE'
                AND d.status = 'ACTIVE') - v_device_limit
      END
    );
  END IF;

  -- Count current active device activations (after lock acquired)
  SELECT COUNT(*) INTO v_active_count
  FROM activations a
  JOIN devices d ON a.device_id = d.id
  WHERE a.license_id = v_entitled.license_id
    AND a.status = 'ACTIVE'
    AND d.status = 'ACTIVE';

  -- NULL device_limit = unlimited (enterprise)
  IF v_device_limit IS NOT NULL AND v_active_count >= v_device_limit THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'S2_DEVICE_QUOTA_REACHED: device quota reached (' || v_active_count || '/' || v_device_limit || ')',
      'devices_remaining', 0
    );
  END IF;

  -- Create activation
  INSERT INTO activations (license_id, device_id, activated_at, last_verified_at, status)
  VALUES (v_entitled.license_id, v_device.id, now(), now(), 'ACTIVE')
  RETURNING * INTO v_activation;

  RETURN jsonb_build_object(
    'success', true,
    'activation_id', v_activation.id,
    'devices_remaining', CASE
      WHEN v_device_limit IS NULL THEN NULL
      ELSE v_device_limit - v_active_count - 1
    END
  );
END;
$$;

COMMENT ON FUNCTION activate_device(UUID, UUID) IS
  'S3: activates a device under the shop license with plan-based device quota enforcement and revocation awareness. Server-authoritative.';

-- =============================================================================
-- 7. register_device() — revocation-aware (preserves all Phase E behavior)
-- =============================================================================
-- Preserves: auth/membership check, platform validation, and the idempotent
-- (installation_id, shop_id) upsert.
-- Adds (S3): prevents an UPSERT from overwriting a REVOKED device back to
-- ACTIVE. If an existing row is REVOKED, raise S3_DEVICE_REVOKED (established
-- error style for this function) — S3 does NOT implement owner un-revoke.

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
  v_existing devices%ROWTYPE;
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

  -- Same-shop transaction advisory lock (serializes revoke vs register)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- S3: revocation-aware re-registration guard. A previously REVOKED device
  -- MUST NOT be silently upserted back to ACTIVE.
  SELECT * INTO v_existing
  FROM devices
  WHERE installation_id = p_installation_id
    AND shop_id = p_shop_id;

  IF FOUND AND v_existing.status = 'REVOKED' THEN
    RAISE EXCEPTION 'S3_DEVICE_REVOKED: this device has been revoked and cannot be re-registered'
      USING ERRCODE = 'check_violation';
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

-- Add unique index for the upsert if not exists (idempotent)
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_installation_shop
  ON devices (installation_id, shop_id);

COMMENT ON FUNCTION register_device(UUID, UUID, TEXT, TEXT) IS
  'S3: registers or updates a device installation, idempotent, with revocation-aware re-registration rejection.';
