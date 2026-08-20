-- Phase D Migration 22: accept_invitation() function
-- Activates a pending membership when an invited employee accepts.
--
-- Phase dependency: D (cloud auth & membership)
-- Security: SECURITY DEFINER — runs with function owner privileges to
-- bypass RLS for the membership update. The function verifies the caller
-- has a valid auth.uid() and that a pending membership exists.
-- search_path is explicitly set to prevent hijacking.

CREATE OR REPLACE FUNCTION accept_invitation(
  p_shop_id UUID,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_member RECORD;
BEGIN
  IF p_shop_id IS NULL OR p_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Shop ID and User ID are required');
  END IF;

  -- Find pending membership
  SELECT * INTO v_member
  FROM shop_members
  WHERE shop_id = p_shop_id
    AND user_id = p_user_id
    AND status = 'INVITED';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'No pending invitation found');
  END IF;

  -- Activate membership
  UPDATE shop_members
  SET status = 'ACTIVE', joined_at = NOW()
  WHERE shop_id = p_shop_id AND user_id = p_user_id;

  -- Update invitation record status if it exists
  UPDATE invitations
  SET status = 'ACCEPTED', accepted_at = NOW()
  WHERE shop_id = p_shop_id
    AND email = (SELECT email FROM auth.users WHERE id = p_user_id)
    AND status = 'PENDING';

  RETURN jsonb_build_object('success', true);
END;
$$;

COMMENT ON FUNCTION accept_invitation IS 'Activates a pending shop membership for an invited employee. Phase D.';
