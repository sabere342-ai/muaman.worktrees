-- Phase C Migration 20: Database functions / RPCs
-- Server-side functions for shop management, membership, and licensing.
--
-- All functions use SECURITY DEFINER with explicit search_path
-- to prevent privilege escalation and search_path injection.
-- These functions execute with the privileges of the function owner (supabase_admin),
-- bypassing RLS as intended for trusted server-side code.

-- =============================================================================
-- 1. create_shop_with_owner()
-- Purpose: Atomically create a new shop and add the creator as owner.
-- Phase dependency: D (cloud auth integration)
-- Arguments:
--   p_name TEXT - The display name of the new shop
-- Returns: UUID (the newly created shop's ID)
-- =============================================================================

CREATE OR REPLACE FUNCTION create_shop_with_owner(p_name TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_shop_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to create a shop';
  END IF;

  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Shop name cannot be empty';
  END IF;

  -- Create the shop
  INSERT INTO shops (name, owner_user_id)
  VALUES (trim(p_name), v_user_id)
  RETURNING id INTO v_shop_id;

  -- Add the creator as owner member
  INSERT INTO shop_members (shop_id, user_id, role, status, joined_at)
  VALUES (v_shop_id, v_user_id, 'owner', 'ACTIVE', now());

  -- Seed system roles for this shop
  INSERT INTO roles (shop_id, name, is_system)
  VALUES
    (v_shop_id, 'owner', true),
    (v_shop_id, 'employee', true),
    (v_shop_id, 'salesOnly', true);

  RETURN v_shop_id;
END;
$$;

COMMENT ON FUNCTION create_shop_with_owner IS 'Atomically creates a shop and adds the authenticated user as owner. Seeds system roles.';

-- =============================================================================
-- 2. get_user_shops()
-- Purpose: List all shops the authenticated user belongs to.
-- Phase dependency: D (cloud auth integration)
-- Returns: TABLE with shop details and membership info
-- =============================================================================

CREATE OR REPLACE FUNCTION get_user_shops()
RETURNS TABLE (
  shop_id UUID,
  shop_name TEXT,
  owner_user_id UUID,
  membership_role TEXT,
  membership_status TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  SELECT
    s.id AS shop_id,
    s.name AS shop_name,
    s.owner_user_id,
    sm.role AS membership_role,
    sm.status AS membership_status,
    s.created_at
  FROM shops s
  INNER JOIN shop_members sm ON sm.shop_id = s.id
  WHERE sm.user_id = v_user_id
    AND sm.status = 'ACTIVE'
  ORDER BY s.created_at ASC;
END;
$$;

COMMENT ON FUNCTION get_user_shops IS 'Returns all shops the authenticated user is an active member of.';

-- =============================================================================
-- 3. verify_shop_membership()
-- Purpose: Check if the authenticated user belongs to a specific shop.
-- Phase dependency: F (client-side permission integration)
-- Arguments:
--   p_shop_id UUID - The shop to verify membership for
-- Returns: BOOLEAN (true if the user is an active member)
-- =============================================================================

CREATE OR REPLACE FUNCTION verify_shop_membership(p_shop_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  IF p_shop_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'ACTIVE'
  ) INTO v_exists;

  RETURN v_exists;
END;
$$;

COMMENT ON FUNCTION verify_shop_membership IS 'Checks if the authenticated user is an active member of the specified shop.';

-- =============================================================================
-- 4. start_trial()
-- Purpose: Server-controlled 14-day trial initiation for a shop's license.
-- Phase dependency: E (licensing)
-- Arguments:
--   p_shop_id UUID - The shop to start a trial for
-- Returns: UUID (the license record ID)
-- Security: Only the shop owner can start a trial.
-- =============================================================================

CREATE OR REPLACE FUNCTION start_trial(p_shop_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_license_id UUID;
  v_is_owner BOOLEAN;
  v_trial_days INTERVAL := '14 days';
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to start a trial';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  -- Verify the user is the owner of the shop
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'Only the shop owner can start a trial';
  END IF;

  -- Check if a trial or active license already exists
  IF EXISTS(
    SELECT 1 FROM licenses
    WHERE shop_id = p_shop_id
      AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
  ) THEN
    RAISE EXCEPTION 'Shop already has an active license or trial';
  END IF;

  -- Create the trial license
  INSERT INTO licenses (shop_id, license_key, status, trial_started_at, trial_expires_at)
  VALUES (
    p_shop_id,
    'TRIAL-' || replace(p_shop_id::text, '-', '') || '-' || to_char(now(), 'YYYYMMDD'),
    'TRIAL',
    now(),
    now() + v_trial_days
  )
  RETURNING id INTO v_license_id;

  RETURN v_license_id;
END;
$$;

COMMENT ON FUNCTION start_trial IS 'Initiates a 14-day server-controlled trial for a shop. Owner-only.';

-- =============================================================================
-- 5. verify_trial_status()
-- Purpose: Check trial validity by server time.
-- Phase dependency: E (licensing)
-- Arguments:
--   p_shop_id UUID - The shop to verify trial status for
-- Returns: TABLE with trial status details
-- =============================================================================

CREATE OR REPLACE FUNCTION verify_trial_status(p_shop_id UUID)
RETURNS TABLE (
  has_license BOOLEAN,
  license_status TEXT,
  trial_active BOOLEAN,
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  days_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license licenses%ROWTYPE;
BEGIN
  IF p_shop_id IS NULL THEN
    has_license := false;
    license_status := NULL;
    trial_active := false;
    trial_started_at := NULL;
    trial_expires_at := NULL;
    days_remaining := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  SELECT * INTO v_license
  FROM licenses
  WHERE shop_id = p_shop_id
    AND status IN ('TRIAL', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'PERPETUAL')
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    has_license := false;
    license_status := NULL;
    trial_active := false;
    trial_started_at := NULL;
    trial_expires_at := NULL;
    days_remaining := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  has_license := true;
  license_status := v_license.status;
  trial_started_at := v_license.trial_started_at;
  trial_expires_at := v_license.trial_expires_at;

  -- Check if trial is currently active (status is TRIAL and not expired)
  IF v_license.status = 'TRIAL' AND v_license.trial_expires_at IS NOT NULL THEN
    IF v_license.trial_expires_at > now() THEN
      trial_active := true;
      days_remaining := EXTRACT(DAY FROM (v_license.trial_expires_at - now()))::INTEGER;
    ELSE
      trial_active := false;
      days_remaining := 0;
    END IF;
  ELSE
    trial_active := false;
    days_remaining := NULL;
  END IF;

  RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION verify_trial_status IS 'Returns the trial/license status for a shop based on server time.';
