-- Phase P Group D D1 (P-OD4): Cost-Change History
-- Table: cloud_cost_history
-- SECURITY DEFINER functions: CRUD functions for cost history
-- RLS: shop-scoped policies
-- Indexes: shop-scoped, product-scoped, timestamp-scoped
--
-- This migration is ADDITIVE ONLY - no destructive changes to existing data.

-- ============================================================================
-- 1. TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS cloud_cost_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES cloud_products(id) ON DELETE RESTRICT,
  product_name TEXT NOT NULL,
  product_barcode TEXT NOT NULL,
  old_cost NUMERIC(12,2) NOT NULL,
  new_cost NUMERIC(12,2) NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  changed_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_cloud_cost_history_old_cost CHECK (old_cost >= 0),
  CONSTRAINT chk_cloud_cost_history_new_cost CHECK (new_cost >= 0),
  CONSTRAINT chk_cloud_cost_history_cost_diff CHECK (old_cost <> new_cost)
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_cloud_cost_history_shop ON cloud_cost_history(shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_cost_history_product ON cloud_cost_history(product_id);
CREATE INDEX IF NOT EXISTS idx_cloud_cost_history_barcode ON cloud_cost_history(product_barcode);
CREATE INDEX IF NOT EXISTS idx_cloud_cost_history_changed_at ON cloud_cost_history(changed_at DESC);

-- ============================================================================
-- 3. RLS
-- ============================================================================

ALTER TABLE cloud_cost_history ENABLE ROW LEVEL SECURITY;

-- Owner can do everything in their shop
CREATE POLICY cloud_cost_history_owner_all
  ON cloud_cost_history
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_cost_history.shop_id
        AND sm.user_id = auth.uid()
        AND sm.role = 'owner'
        AND sm.status = 'ACTIVE'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_cost_history.shop_id
        AND sm.user_id = auth.uid()
        AND sm.role = 'owner'
        AND sm.status = 'ACTIVE'
    )
  );

-- Employee can read cost history in their shop
CREATE POLICY cloud_cost_history_employee_read
  ON cloud_cost_history
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_cost_history.shop_id
        AND sm.user_id = auth.uid()
        AND sm.role = 'employee'
        AND sm.status = 'ACTIVE'
    )
  );

-- Employee can insert cost history in their shop
CREATE POLICY cloud_cost_history_employee_insert
  ON cloud_cost_history
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_cost_history.shop_id
        AND sm.user_id = auth.uid()
        AND sm.role = 'employee'
        AND sm.status = 'ACTIVE'
    )
  );

-- salesOnly CANNOT access cost history (no accounting mutation power)

-- ============================================================================
-- 4. SECURITY DEFINER FUNCTIONS
-- ============================================================================

-- Insert cost history record
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

-- Get cost history for a product
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

-- Get all cost history for a shop
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
  RETURN QUERY
  SELECT ch.id, ch.shop_id, ch.product_id, ch.product_name,
         ch.product_barcode, ch.old_cost, ch.new_cost,
         ch.changed_at, ch.changed_by, ch.created_at
  FROM cloud_cost_history ch
  WHERE ch.shop_id = p_shop_id
  ORDER BY ch.changed_at DESC;
END;
$$;
