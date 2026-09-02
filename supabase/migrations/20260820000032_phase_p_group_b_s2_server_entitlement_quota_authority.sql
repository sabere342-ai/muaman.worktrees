-- Phase P Group B S2: Server Entitlement + Quota Authority
--
-- ADDITIVE, IDEMPOTENT / REPLAY-SAFE, FORWARD-ONLY, SERVER-AUTHORITATIVE.
--
-- This migration:
--   1. Confirms canonical plan seeds (replay-safe)
--   2. Backfills licenses.plan_key from deterministic license status
--   3. Creates s2_resolve_entitled_license(shop_id) helper
--   4. Creates s2_enforce_user_quota() trigger function
--   5. Attaches user quota trigger on shop_members
--   6. Rewrites activate_device() with plan-based device quota
--   7. Rewrites verify_license_entitlement() with plan-based limits
--
-- Non-goals (deferred):
--   S3: revocation / offline grace
--   S4: device trust / invitation hardening
--   S6/S7: platform identity / owner UI
--   S11: production deployment

-- =============================================================================
-- 1. Canonical plan seed confirmation (replay-safe)
-- =============================================================================
-- S1 created these seeds. S2 confirms idempotently. No overwrite on re-run.
-- Canonical tiers: trial(1/1), starter(2/3), professional(5/10), enterprise(NULL/NULL).

INSERT INTO plans (key, name, user_limit, device_limit, trial_days, billing_cadence)
VALUES
  ('trial',        'Trial',        1,    1,    14,   NULL),
  ('starter',      'Starter',      2,    3,    NULL, 'monthly'),
  ('professional', 'Professional', 5,    10,   NULL, 'monthly'),
  ('enterprise',   'Enterprise',   NULL, NULL, NULL, 'monthly')
ON CONFLICT (key) DO NOTHING;

-- =============================================================================
-- 2. Deterministic license plan_key backfill
-- =============================================================================
-- Backfill only previously unbound (plan_key IS NULL) records.
-- Deterministic, idempotent, forward-only, non-destructive.
--
-- TRIAL status   -> 'trial'
-- ACTIVE status  -> 'starter' (default for paid; no stronger committed evidence)
-- PERPETUAL      -> no paid tier granted (fail-closed compatibility)
-- EXPIRED/SUSPENDED -> not entitled; plan_key left NULL for quota fail-closed
-- NULL/unknown   -> not entitled; plan_key left NULL

UPDATE licenses
SET plan_key = 'trial'
WHERE plan_key IS NULL
  AND status = 'TRIAL';

UPDATE licenses
SET plan_key = 'starter'
WHERE plan_key IS NULL
  AND status = 'ACTIVE';

-- Also populate licenses.user_limit from the referenced plan for compatibility.
-- This is NOT enforcement authority; plans.user_limit is canonical.
UPDATE licenses l
SET user_limit = p.user_limit
FROM plans p
WHERE l.plan_key = p.key
  AND l.user_limit IS NULL;

-- =============================================================================
-- 3. s2_resolve_entitled_license(shop_id) — canonical entitlement resolver
-- =============================================================================
-- Returns the most recent entitled license row and its referenced plan.
-- Entitled states: TRIAL, ACTIVE, PERPETUAL.
-- If no valid plan binding exists, plan_key/plan row are NULL (fail-closed).

CREATE OR REPLACE FUNCTION s2_resolve_entitled_license(p_shop_id UUID)
RETURNS TABLE (
  license_id       UUID,
  license_status   TEXT,
  plan_key         TEXT,
  user_limit       INTEGER,
  device_limit     INTEGER,
  billing_cadence  TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id          AS license_id,
    l.status      AS license_status,
    l.plan_key    AS plan_key,
    p.user_limit  AS user_limit,
    p.device_limit AS device_limit,
    p.billing_cadence AS billing_cadence
  FROM licenses l
  LEFT JOIN plans p ON p.key = l.plan_key
  WHERE l.shop_id = p_shop_id
    AND l.status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
  ORDER BY l.created_at DESC
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION s2_resolve_entitled_license(UUID) IS
  'S2: resolves the current entitled license and plan for a shop. Server-authoritative.';

-- =============================================================================
-- 4. s2_enforce_user_quota() — trigger function for ACTIVE membership transitions
-- =============================================================================
-- Fires on INSERT or UPDATE of shop_members.status.
-- Uses shop-keyed PostgreSQL transaction advisory lock for concurrency safety.
-- Allows bootstrap: first ACTIVE owner of a brand-new shop (no license yet).
-- Rejects N+1 deterministically with S2_USER_QUOTA_REACHED.

CREATE OR REPLACE FUNCTION s2_enforce_user_quota()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_shop_id         UUID;
  v_new_status      TEXT;
  v_old_status      TEXT;
  v_is_insert       BOOLEAN;
  v_active_count    BIGINT;
  v_user_limit      INTEGER;
  v_entitled        RECORD;
BEGIN
  v_shop_id    := COALESCE(NEW.shop_id, OLD.shop_id);
  v_new_status := NEW.status;
  v_old_status := COALESCE(OLD.status, 'NONE');
  v_is_insert  := (TG_OP = 'INSERT');

  -- Only enforce when status transitions TO or is already ACTIVE
  IF v_new_status IS DISTINCT FROM 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  -- Skip if this is an UPDATE and status was already ACTIVE (no change)
  IF NOT v_is_insert AND v_old_status = 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  -- Shop-keyed PostgreSQL transaction advisory lock
  PERFORM pg_advisory_xact_lock(hashtextextended(v_shop_id::text, 0));

  -- Resolve entitled license + plan
  SELECT * INTO v_entitled
  FROM s2_resolve_entitled_license(v_shop_id);

  -- Bootstrap exception: first owner of newly created shop with no license yet
  IF v_entitled.license_id IS NULL THEN
    IF v_is_insert
       AND NEW.role = 'owner'
       AND NOT EXISTS (
         SELECT 1 FROM shop_members
         WHERE shop_id = v_shop_id
           AND status = 'ACTIVE'
       )
    THEN
      RETURN NEW;
    END IF;
    -- No valid plan binding — fail closed
    RAISE EXCEPTION 'S2_PLAN_AUTHORITY_REQUIRED: no valid canonical plan is bound to the entitled license'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Plan must exist and have a valid plan_key
  IF v_entitled.plan_key IS NULL THEN
    RAISE EXCEPTION 'S2_PLAN_AUTHORITY_REQUIRED: no valid canonical plan is bound to the entitled license'
      USING ERRCODE = 'check_violation';
  END IF;

  v_user_limit := v_entitled.user_limit;

  -- NULL user_limit = unlimited (enterprise)
  IF v_user_limit IS NULL THEN
    RETURN NEW;
  END IF;

  -- Count current ACTIVE members (exclude the row being inserted/updated)
  SELECT COUNT(DISTINCT sm.user_id) INTO v_active_count
  FROM shop_members sm
  WHERE sm.shop_id = v_shop_id
    AND sm.status = 'ACTIVE'
    AND (TG_OP = 'INSERT' OR sm.id IS DISTINCT FROM OLD.id);

  -- Check cap: current count >= limit means adding would be N+1
  IF v_active_count >= v_user_limit THEN
    RAISE EXCEPTION 'S2_USER_QUOTA_REACHED: user quota reached (%/%)', v_active_count, v_user_limit
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION s2_enforce_user_quota() IS
  'S2: trigger function enforcing per-shop user quota on ACTIVE membership transitions. Server-authoritative.';

-- Attach trigger (fires for both INSERT and UPDATE)
DROP TRIGGER IF EXISTS s2_user_quota_enforcement ON shop_members;
CREATE TRIGGER s2_user_quota_enforcement
  BEFORE INSERT OR UPDATE OF status ON shop_members
  FOR EACH ROW
  EXECUTE FUNCTION s2_enforce_user_quota();

-- =============================================================================
-- 5. Rewrite activate_device() — plan-based device quota enforcement
-- =============================================================================
-- Preserves: auth/membership check, idempotent re-activation, JSONB return.
-- Adds: shop-keyed advisory lock, plan-based device_limit resolution,
--        deterministic S2_DEVICE_QUOTA_REACHED rejection.
-- Does NOT implement: S4 device trust / proof-of-possession / PENDING_APPROVAL gate.

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

  -- Shop-keyed PostgreSQL transaction advisory lock
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
  'S2: activates a device under the shop license with plan-based device quota enforcement. Server-authoritative.';

-- =============================================================================
-- 6. Rewrite verify_license_entitlement() — plan-based limits
-- =============================================================================
-- Preserves existing return signature.
-- Changes: max_devices now from plans.device_limit (not licenses.max_devices),
--          NULL plan.device_limit treated as unlimited (device_slot_available = TRUE).

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
  v_plan plans%ROWTYPE;
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

  -- Find the most recent entitled license (TRIAL/ACTIVE/PERPETUAL)
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
  server_time := now();

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
    -- Enterprise or missing plan: unlimited
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

  RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION verify_license_entitlement(UUID) IS
  'S2: resolves the current licensing entitlement for a shop. Plan-based device limits. Server-authoritative.';
