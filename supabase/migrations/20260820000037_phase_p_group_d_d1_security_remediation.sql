-- Phase P Group D D1 — Security Remediation (Corrective Migration)
-- DROP + RE-CREATE the three SECURITY DEFINER functions with require_shop_permission authorization.
-- This migration is ADDITIVE ONLY to the schema — no tables/policies/indexes are altered.
-- It replaces only the function bodies of three existing RPCs.

-- ============================================================================
-- 1. DROP + RE-CREATE insert_cloud_cost_history with authorization
-- ============================================================================

DROP FUNCTION IF EXISTS insert_cloud_cost_history(
  UUID, UUID, TEXT, TEXT, NUMERIC, NUMERIC, UUID
);

CREATE OR REPLACE FUNCTION insert_cloud_cost_history(
  p_shop_id UUID,
  p_product_id UUID,
  p_product_name TEXT,
  p_product_barcode TEXT,
  p_old_cost NUMERIC(12,2),
  p_new_cost NUMERIC(12,2),
  p_changed_by UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  INSERT INTO cloud_cost_history (
    shop_id, product_id, product_name, product_barcode,
    old_cost, new_cost, changed_by
  ) VALUES (
    p_shop_id, p_product_id, p_product_name, p_product_barcode,
    p_old_cost, p_new_cost, p_changed_by
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- ============================================================================
-- 2. DROP + RE-CREATE get_cloud_cost_history_by_product with authorization
-- ============================================================================

DROP FUNCTION IF EXISTS get_cloud_cost_history_by_product(UUID, UUID);

CREATE OR REPLACE FUNCTION get_cloud_cost_history_by_product(
  p_shop_id UUID,
  p_product_id UUID
)
RETURNS TABLE (
  id UUID,
  shop_id UUID,
  product_id UUID,
  product_name TEXT,
  product_barcode TEXT,
  old_cost NUMERIC(12,2),
  new_cost NUMERIC(12,2),
  changed_at TIMESTAMPTZ,
  changed_by UUID,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.view');

  RETURN QUERY
  SELECT ch.id, ch.shop_id, ch.product_id, ch.product_name,
         ch.product_barcode, ch.old_cost, ch.new_cost,
         ch.changed_at, ch.changed_by, ch.created_at
  FROM cloud_cost_history ch
  WHERE ch.shop_id = p_shop_id
    AND ch.product_id = p_product_id
  ORDER BY ch.changed_at DESC;
END;
$$;

-- ============================================================================
-- 3. DROP + RE-CREATE get_cloud_cost_history_by_shop with authorization
-- ============================================================================

DROP FUNCTION IF EXISTS get_cloud_cost_history_by_shop(UUID);

CREATE OR REPLACE FUNCTION get_cloud_cost_history_by_shop(
  p_shop_id UUID
)
RETURNS TABLE (
  id UUID,
  shop_id UUID,
  product_id UUID,
  product_name TEXT,
  product_barcode TEXT,
  old_cost NUMERIC(12,2),
  new_cost NUMERIC(12,2),
  changed_at TIMESTAMPTZ,
  changed_by UUID,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.view');

  RETURN QUERY
  SELECT ch.id, ch.shop_id, ch.product_id, ch.product_name,
         ch.product_barcode, ch.old_cost, ch.new_cost,
         ch.changed_at, ch.changed_by, ch.created_at
  FROM cloud_cost_history ch
  WHERE ch.shop_id = p_shop_id
  ORDER BY ch.changed_at DESC;
END;
$$;

-- ============================================================================
-- 4. EXECUTE privilege control
-- ============================================================================

REVOKE ALL ON FUNCTION insert_cloud_cost_history(
  UUID, UUID, TEXT, TEXT, NUMERIC, NUMERIC, UUID
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION insert_cloud_cost_history(
  UUID, UUID, TEXT, TEXT, NUMERIC, NUMERIC, UUID
) TO authenticated;

REVOKE ALL ON FUNCTION get_cloud_cost_history_by_product(UUID, UUID)
  FROM PUBLIC;

GRANT EXECUTE ON FUNCTION get_cloud_cost_history_by_product(UUID, UUID)
  TO authenticated;

REVOKE ALL ON FUNCTION get_cloud_cost_history_by_shop(UUID)
  FROM PUBLIC;

GRANT EXECUTE ON FUNCTION get_cloud_cost_history_by_shop(UUID)
  TO authenticated;
