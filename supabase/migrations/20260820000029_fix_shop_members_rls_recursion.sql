-- 20260820000029_fix_shop_members_rls_recursion.sql
-- Fixes: shop_members RLS infinite recursion (Defect 1)
-- Strategy: Replace self-referential policy with SECURITY DEFINER helper function

-- 1. Helper function: returns active shop_ids for current user
CREATE OR REPLACE FUNCTION get_user_shop_ids()
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_shop_ids UUID[];
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN '{}'::UUID[];
  END IF;

  SELECT ARRAY_AGG(shop_id) INTO v_shop_ids
  FROM shop_members
  WHERE user_id = v_user_id
    AND status = 'ACTIVE';

  RETURN COALESCE(v_shop_ids, '{}'::UUID[]);
END;
$$;

COMMENT ON FUNCTION get_user_shop_ids IS 'Returns array of shop_ids where the authenticated user has ACTIVE membership. SECURITY DEFINER to bypass RLS and avoid recursion.';

-- 2. Grant minimal execute privileges
GRANT EXECUTE ON FUNCTION get_user_shop_ids() TO authenticated, anon, service_role;
REVOKE ALL ON FUNCTION get_user_shop_ids() FROM PUBLIC;

-- 3. Drop recursive policy
DROP POLICY IF EXISTS shop_member_isolation ON shop_members;

-- 4. Create non-recursive policy using helper
CREATE POLICY shop_member_isolation ON shop_members
  FOR SELECT USING (
    shop_id = ANY(get_user_shop_ids())
      AND status = 'ACTIVE'
  );

COMMENT ON POLICY shop_member_isolation ON shop_members IS 'Non-recursive shop isolation: user sees memberships only for their active shops. Uses get_user_shop_ids() helper (SECURITY DEFINER).';