-- Phase P Gate 2: Owner-shop uniqueness defense-in-depth.
--
-- 1. Enforce at most one shop per owner_user_id via a partial unique index.
--    If multiple owner shops already exist for any user, the CREATE INDEX
--    will fail loudly, demanding a data-reconciliation session before this
--    migration can be applied.
--
-- 2. Idempotent resolve_owner_shop(p_name) RPC: advisory-locked,
--    transactional, converges to exactly one owner shop per authenticated
--    identity. Returns the existing single owner shop or creates one if none
--    exists. Raises a deterministic error if multiple owner shops already
--    exist (defense-in-depth Layer 2).

-- =============================================================================
-- Layer 3: Schema-level partial unique index on shops(owner_user_id)
-- =============================================================================

-- Pre-flight check: fail loudly if duplicates already exist, so the
-- migration cannot silently enable the constraint on dirty data.
DO $$
DECLARE
  v_dup_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_dup_count
  FROM (
    SELECT owner_user_id
    FROM shops
    GROUP BY owner_user_id
    HAVING COUNT(*) > 1
  ) dups;

  IF v_dup_count > 0 THEN
    RAISE EXCEPTION
      'PHASE_P_GATE_2_OWNER_SHOP_UNIQUENESS_BLOCKED: '
      '% owner(s) already have multiple shops. '
      'Run a data-reconciliation session before applying this migration.',
      v_dup_count;
  END IF;
END $$;

CREATE UNIQUE INDEX uq_shops_one_owner_shop
  ON shops(owner_user_id);

-- =============================================================================
-- Layer 2: Idempotent resolve_owner_shop(p_name TEXT) RPC
-- =============================================================================

CREATE OR REPLACE FUNCTION resolve_owner_shop(p_name TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_shop_id UUID;
  v_owner_shop_count INTEGER;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to resolve owner shop';
  END IF;

  -- Serialize concurrent owner-shop resolution for the same user.
  -- pg_advisory_xact_lock is session-scoped and automatically released on
  -- COMMIT or ROLLBACK, preventing double-tap / race-condition creation.
  PERFORM pg_advisory_xact_lock(
    hashtext('itech_owner_shop:' || v_user_id::text)
  );

  -- Count existing shops owned by this user.
  SELECT COUNT(*) INTO v_owner_shop_count
  FROM shops
  WHERE owner_user_id = v_user_id;

  -- Case C: multiple owner shops already exist → fail closed with
  -- deterministic error. No silent selection, no cleanup attempt.
  IF v_owner_shop_count > 1 THEN
    RAISE EXCEPTION
      'Multiple owner shops already exist for this account '
      '(count: %). Reconciliation required.',
      v_owner_shop_count;
  END IF;

  -- Case A: exactly one owner shop exists → reuse it.
  IF v_owner_shop_count = 1 THEN
    SELECT id INTO v_shop_id
    FROM shops
    WHERE owner_user_id = v_user_id
    LIMIT 1;

    RETURN v_shop_id;
  END IF;

  -- Case B: no owner shop exists → create exactly one.
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Shop name cannot be empty when creating a new shop';
  END IF;

  INSERT INTO shops (name, owner_user_id)
  VALUES (trim(p_name), v_user_id)
  RETURNING id INTO v_shop_id;

  INSERT INTO shop_members (shop_id, user_id, role, status, joined_at)
  VALUES (v_shop_id, v_user_id, 'owner', 'ACTIVE', now());

  INSERT INTO roles (shop_id, name, is_system)
  VALUES
    (v_shop_id, 'owner', true),
    (v_shop_id, 'employee', true),
    (v_shop_id, 'salesOnly', true);

  RETURN v_shop_id;
END;
$$;

COMMENT ON FUNCTION resolve_owner_shop IS
  'Idempotent owner-shop resolution: returns existing single owner shop, '
  'creates one if none exists, raises if multiple exist. Uses advisory '
  'locking for concurrent-safety.';
