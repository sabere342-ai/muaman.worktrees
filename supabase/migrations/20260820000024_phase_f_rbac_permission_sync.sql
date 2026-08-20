-- Phase F Migration 24: Server-Side RBAC & Permission Sync
-- New tables: shop_permission_overrides, permission_audit_log
-- New functions: check_effective_permission, get_effective_permissions,
--   require_shop_permission, sync_user_permissions,
--   get_shop_permission_overrides, set_shop_permission_override,
--   delete_shop_permission_override
--
-- This migration is ADDITIVE ONLY — no destructive changes to existing data.

-- ============================================================================
-- 1. Table: shop_permission_overrides
--    Per-shop role-level permission overrides. Owner role is excluded.
-- ============================================================================

CREATE TABLE IF NOT EXISTS shop_permission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('employee', 'salesOnly')),
  permission_id TEXT NOT NULL,
  effect TEXT NOT NULL CHECK (effect IN ('ALLOW', 'DENY')),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, role, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_shop_permission_overrides_shop_role
  ON shop_permission_overrides (shop_id, role);

COMMENT ON TABLE shop_permission_overrides IS
  'Phase F: per-shop permission overrides for non-owner roles. Owner permissions are immutable.';

-- ============================================================================
-- 2. Table: permission_audit_log
--    Audit trail for all permission-changing operations.
-- ============================================================================

CREATE TABLE IF NOT EXISTS permission_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL,
  action TEXT NOT NULL,
  target_role TEXT,
  permission_id TEXT,
  old_effect TEXT,
  new_effect TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_permission_audit_shop
  ON permission_audit_log (shop_id, created_at DESC);

COMMENT ON TABLE permission_audit_log IS
  'Phase F: audit trail for permission override and role change operations.';

-- ============================================================================
-- 3. RLS on shop_permission_overrides
--    SELECT-only, membership-based. No client mutations.
-- ============================================================================

ALTER TABLE shop_permission_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_overrides_isolation ON shop_permission_overrides
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = shop_permission_overrides.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- ============================================================================
-- 4. RLS on permission_audit_log
--    SELECT-only, membership-based. No client mutations.
-- ============================================================================

ALTER TABLE permission_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_audit_isolation ON permission_audit_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = permission_audit_log.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- ============================================================================
-- 5. Function: check_effective_permission(p_shop_id, p_role, p_permission_id)
--    Internal helper. Resolves whether a role has a specific permission,
--    considering base role_permissions_cloud + shop_permission_overrides.
--    Owner always returns true (immutable).
--    SECURITY DEFINER to access all tables without RLS interference.
-- ============================================================================

CREATE OR REPLACE FUNCTION check_effective_permission(
  p_shop_id UUID,
  p_role TEXT,
  p_permission_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_override_effect TEXT;
  v_has_base BOOLEAN;
BEGIN
  -- Owner always gets all permissions (immutable)
  IF p_role = 'owner' THEN
    RETURN true;
  END IF;

  -- Validate permission_id is a known canonical ID
  IF p_permission_id IS NULL OR p_permission_id = '' THEN
    RETURN false;
  END IF;

  -- Check for explicit override (owner-exclusive safety: non-owner cannot get
  -- owner-exclusive permissions even via override)
  SELECT effect INTO v_override_effect
  FROM shop_permission_overrides
  WHERE shop_id = p_shop_id
    AND role = p_role
    AND permission_id = p_permission_id;

  IF FOUND THEN
    -- Safety: deny owner-exclusive permissions for non-owner roles
    IF v_override_effect = 'ALLOW' AND p_permission_id IN (
      'admin.users.manage', 'admin.permissions.manage'
    ) THEN
      RETURN false;
    END IF;
    RETURN v_override_effect = 'ALLOW';
  END IF;

  -- Resolve base permissions from role_permissions_cloud
  SELECT EXISTS(
    SELECT 1
    FROM role_permissions_cloud rpc
    JOIN roles r ON r.id = rpc.role_id
    WHERE r.shop_id = p_shop_id
      AND r.name = p_role
      AND rpc.permission_id = p_permission_id
  ) INTO v_has_base;

  RETURN v_has_base;
END;
$$;

COMMENT ON FUNCTION check_effective_permission(UUID, TEXT, TEXT) IS
  'Phase F internal helper: resolves effective permission for a role in a shop. Owner always true.';

-- ============================================================================
-- 6. Function: get_effective_permissions(p_shop_id)
--    Returns the resolved set of permission IDs for the authenticated caller.
--    SECURITY DEFINER with auth.uid() identity.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_effective_permissions(p_shop_id UUID)
RETURNS TABLE(permission_id TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_member_role TEXT;
  v_all_permissions TEXT[] := ARRAY[
    'dashboard.view', 'inventory.view', 'inventory.edit', 'inventory.delete',
    'sales.view', 'sales.create', 'sales.history.view', 'sales.delete',
    'returns.view', 'returns.create', 'returns.delete',
    'expenses.view', 'expenses.create', 'expenses.delete',
    'stocktake.view',
    'admin.users.manage', 'admin.permissions.manage', 'admin.settings.access'
  ];
  v_perm TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Resolve membership
  SELECT sm.role INTO v_member_role
  FROM shop_members sm
  WHERE sm.shop_id = p_shop_id
    AND sm.user_id = v_user_id
    AND sm.status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Owner gets all permissions
  IF v_member_role = 'owner' THEN
    FOR i IN 1..array_length(v_all_permissions, 1) LOOP
      permission_id := v_all_permissions[i];
      RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  -- For non-owner roles, resolve effective permissions
  FOREACH v_perm IN ARRAY v_all_permissions LOOP
    IF check_effective_permission(p_shop_id, v_member_role, v_perm) THEN
      permission_id := v_perm;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION get_effective_permissions(UUID) IS
  'Phase F: returns the resolved effective permission IDs for the authenticated caller in a shop.';

-- ============================================================================
-- 7. Function: require_shop_permission(p_shop_id, p_permission_id)
--    Asserts the caller has a specific permission. Raises exception if not.
--    Combines: auth + membership + entitlement + permission.
--    Returns the member's role on success.
-- ============================================================================

CREATE OR REPLACE FUNCTION require_shop_permission(
  p_shop_id UUID,
  p_permission_id TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_member_role TEXT;
  v_has_license BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Validate permission_id
  IF p_permission_id IS NULL OR p_permission_id = '' THEN
    RAISE EXCEPTION 'invalid_permission';
  END IF;

  -- Membership check
  SELECT sm.role INTO v_member_role
  FROM shop_members sm
  WHERE sm.shop_id = p_shop_id
    AND sm.user_id = v_user_id
    AND sm.status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Entitlement check (inline for atomicity)
  -- View permissions bypass license check; write permissions require active license
  IF p_permission_id NOT LIKE '%.view' THEN
    SELECT EXISTS(
      SELECT 1 FROM licenses
      WHERE shop_id = p_shop_id
        AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
    ) INTO v_has_license;

    IF NOT v_has_license THEN
      RAISE EXCEPTION 'license_required';
    END IF;
  END IF;

  -- Owner bypass
  IF v_member_role = 'owner' THEN
    RETURN v_member_role;
  END IF;

  -- Permission resolution
  IF NOT check_effective_permission(p_shop_id, v_member_role, p_permission_id) THEN
    RAISE EXCEPTION 'permission_denied: %', p_permission_id;
  END IF;

  RETURN v_member_role;
END;
$$;

COMMENT ON FUNCTION require_shop_permission(UUID, TEXT) IS
  'Phase F: server-authoritative permission check. Returns role if authorized, raises exception otherwise.';

-- ============================================================================
-- 8. Function: sync_user_permissions(p_shop_id)
--    Full permission payload for client sync. Returns JSONB.
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_user_permissions(p_shop_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_member_role TEXT;
  v_permissions JSONB;
  v_overrides JSONB;
  v_permissions_updated_at TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Resolve membership
  SELECT sm.role INTO v_member_role
  FROM shop_members sm
  WHERE sm.shop_id = p_shop_id
    AND sm.user_id = v_user_id
    AND sm.status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Build resolved permissions array
  SELECT jsonb_agg(ep.permission_id)
  INTO v_permissions
  FROM get_effective_permissions(p_shop_id) ep;

  -- If null (no permissions), use empty array
  IF v_permissions IS NULL THEN
    v_permissions := '[]'::jsonb;
  END IF;

  -- Get overrides for the caller's role
  IF v_member_role = 'owner' THEN
    v_overrides := '[]'::jsonb;
  ELSE
    SELECT jsonb_agg(jsonb_build_object(
      'permission_id', spo.permission_id,
      'effect', spo.effect
    ))
    INTO v_overrides
    FROM shop_permission_overrides spo
    WHERE spo.shop_id = p_shop_id
      AND spo.role = v_member_role;

    IF v_overrides IS NULL THEN
      v_overrides := '[]'::jsonb;
    END IF;
  END IF;

  -- Get the latest permissions_updated_at timestamp
  SELECT MAX(updated_at) INTO v_permissions_updated_at
  FROM shop_permission_overrides
  WHERE shop_id = p_shop_id;

  IF v_permissions_updated_at IS NULL THEN
    v_permissions_updated_at := now();
  END IF;

  RETURN jsonb_build_object(
    'shop_id', p_shop_id,
    'member_role', v_member_role,
    'permissions', v_permissions,
    'overrides', v_overrides,
    'catalog_version', 1,
    'server_time', now(),
    'updated_at', v_permissions_updated_at
  );
END;
$$;

COMMENT ON FUNCTION sync_user_permissions(UUID) IS
  'Phase F: returns the full permission payload for client synchronization.';

-- ============================================================================
-- 9. Function: get_shop_permission_overrides(p_shop_id)
--    Owner-only: returns all overrides for a shop.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_shop_permission_overrides(p_shop_id UUID)
RETURNS TABLE (
  role TEXT,
  permission_id TEXT,
  effect TEXT,
  updated_at TIMESTAMPTZ
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
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Owner check
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'owner_required';
  END IF;

  RETURN QUERY
  SELECT
    spo.role,
    spo.permission_id,
    spo.effect,
    spo.updated_at
  FROM shop_permission_overrides spo
  WHERE spo.shop_id = p_shop_id
  ORDER BY spo.role, spo.permission_id;
END;
$$;

COMMENT ON FUNCTION get_shop_permission_overrides(UUID) IS
  'Phase F: owner-only function to view all permission overrides for a shop.';

-- ============================================================================
-- 10. Function: set_shop_permission_override(p_shop_id, p_role, p_permission_id, p_effect)
--     Owner-only: sets a permission override. Validates invariants.
-- ============================================================================

CREATE OR REPLACE FUNCTION set_shop_permission_override(
  p_shop_id UUID,
  p_role TEXT,
  p_permission_id TEXT,
  p_effect TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_owner BOOLEAN;
  v_old_effect TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Owner check
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'owner_required';
  END IF;

  -- Validate role (owner excluded from overrides)
  IF p_role IS NULL OR p_role NOT IN ('employee', 'salesOnly') THEN
    RAISE EXCEPTION 'invalid_role';
  END IF;

  -- Validate permission_id
  IF p_permission_id IS NULL OR p_permission_id = '' THEN
    RAISE EXCEPTION 'invalid_permission';
  END IF;

  -- Validate effect
  IF p_effect IS NULL OR p_effect NOT IN ('ALLOW', 'DENY') THEN
    RAISE EXCEPTION 'invalid_effect';
  END IF;

  -- Prevent owner-exclusive permissions from being granted via override
  IF p_effect = 'ALLOW' AND p_permission_id IN (
    'admin.users.manage', 'admin.permissions.manage'
  ) THEN
    RAISE EXCEPTION 'override_violation: owner-exclusive permission cannot be granted to non-owner';
  END IF;

  -- Capture old effect for audit
  SELECT effect INTO v_old_effect
  FROM shop_permission_overrides
  WHERE shop_id = p_shop_id
    AND role = p_role
    AND permission_id = p_permission_id;

  -- Upsert the override
  INSERT INTO shop_permission_overrides (shop_id, role, permission_id, effect, created_by, updated_at)
  VALUES (p_shop_id, p_role, p_permission_id, p_effect, v_user_id, now())
  ON CONFLICT (shop_id, role, permission_id) DO UPDATE SET
    effect = EXCLUDED.effect,
    updated_at = now();

  -- Audit log
  INSERT INTO permission_audit_log (shop_id, actor_user_id, action, target_role, permission_id, old_effect, new_effect)
  VALUES (p_shop_id, v_user_id, 'override_set', p_role, p_permission_id, v_old_effect, p_effect);

  RETURN true;
END;
$$;

COMMENT ON FUNCTION set_shop_permission_override(UUID, TEXT, TEXT, TEXT) IS
  'Phase F: owner-only function to set a permission override. Validates owner-exclusive invariant.';

-- ============================================================================
-- 11. Function: delete_shop_permission_override(p_shop_id, p_role, p_permission_id)
--      Owner-only: removes a permission override.
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_shop_permission_override(
  p_shop_id UUID,
  p_role TEXT,
  p_permission_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_owner BOOLEAN;
  v_old_effect TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  -- Owner check
  SELECT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND role = 'owner'
      AND status = 'ACTIVE'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RAISE EXCEPTION 'owner_required';
  END IF;

  -- Validate inputs
  IF p_role IS NULL OR p_role NOT IN ('employee', 'salesOnly') THEN
    RAISE EXCEPTION 'invalid_role';
  END IF;

  IF p_permission_id IS NULL OR p_permission_id = '' THEN
    RAISE EXCEPTION 'invalid_permission';
  END IF;

  -- Capture old effect for audit
  SELECT effect INTO v_old_effect
  FROM shop_permission_overrides
  WHERE shop_id = p_shop_id
    AND role = p_role
    AND permission_id = p_permission_id;

  -- Delete the override
  DELETE FROM shop_permission_overrides
  WHERE shop_id = p_shop_id
    AND role = p_role
    AND permission_id = p_permission_id;

  -- Audit log (only if something was deleted)
  IF v_old_effect IS NOT NULL THEN
    INSERT INTO permission_audit_log (shop_id, actor_user_id, action, target_role, permission_id, old_effect, new_effect)
    VALUES (p_shop_id, v_user_id, 'override_delete', p_role, p_permission_id, v_old_effect, NULL);
  END IF;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION delete_shop_permission_override(UUID, TEXT, TEXT) IS
  'Phase F: owner-only function to remove a permission override.';

-- ============================================================================
-- 12. Grants: EXECUTE to authenticated role only
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_effective_permissions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION require_shop_permission(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION sync_user_permissions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_shop_permission_overrides(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION set_shop_permission_override(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_shop_permission_override(UUID, TEXT, TEXT) TO authenticated;

-- check_effective_permission is internal helper — no direct EXECUTE grant needed
-- (it is called by other SECURITY DEFINER functions which execute as owner)
