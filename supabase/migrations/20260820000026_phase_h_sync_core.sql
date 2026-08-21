-- Phase H Migration 26: Offline Sync Core
-- Adds server_version to all 9 cloud tables, sync_log table,
-- idempotency-aware upsert function, version-aware CRUD updates.
--
-- This migration is ADDITIVE ONLY.

-- ============================================================================
-- 1. Add server_version to all 9 cloud tables
-- ============================================================================

ALTER TABLE cloud_products ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_customers ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_sales ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_returns ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_expenses ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_expense_categories ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_invoices ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_inventory_count ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;
ALTER TABLE cloud_shop_settings ADD COLUMN IF NOT EXISTS server_version INTEGER DEFAULT 1;

-- ============================================================================
-- 2. sync_log table for server-side sync audit
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  operation TEXT NOT NULL,
  idempotency_key TEXT UNIQUE NOT NULL,
  actor_user_id UUID REFERENCES auth.users(id),
  status TEXT NOT NULL,
  conflict_details JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sync_log_shop ON sync_log(shop_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_log_idempotency ON sync_log(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_sync_log_entity ON sync_log(entity_type, entity_id);

-- RLS for sync_log
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_isolation_sync_log ON sync_log
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = sync_log.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- ============================================================================
-- 3. Version-aware CRUD function updates
-- ============================================================================

-- 3.1 Update update_cloud_product to support server_version
CREATE OR REPLACE FUNCTION update_cloud_product(
  p_shop_id UUID,
  p_product_id UUID,
  p_name TEXT DEFAULT NULL,
  p_barcode TEXT DEFAULT NULL,
  p_opening_quantity INTEGER DEFAULT NULL,
  p_cost_price NUMERIC(12,2) DEFAULT NULL,
  p_sold_quantity INTEGER DEFAULT NULL,
  p_returned_quantity INTEGER DEFAULT NULL,
  p_inventory_adjustment INTEGER DEFAULT NULL,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing RECORD;
  v_new_opening INTEGER;
  v_new_sold INTEGER;
  v_new_returned INTEGER;
  v_new_adjustment INTEGER;
  v_new_current INTEGER;
  v_new_cost NUMERIC(12,2);
  v_new_total NUMERIC(14,2);
  v_new_version INTEGER;
  v_conflict JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  SELECT * INTO v_existing
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF p_expected_version IS NOT NULL AND v_existing.server_version != p_expected_version THEN
    v_conflict := jsonb_build_object(
      'status', 'CONFLICT',
      'server_version', v_existing.server_version,
      'expected_version', p_expected_version,
      'server_data', to_jsonb(v_existing)
    );
    RETURN v_conflict;
  END IF;

  IF p_barcode IS NOT NULL AND p_barcode != v_existing.barcode THEN
    IF EXISTS (
      SELECT 1 FROM cloud_products
      WHERE shop_id = p_shop_id AND barcode = trim(p_barcode)
        AND id != p_product_id AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Barcode already exists in this shop';
    END IF;
  END IF;

  v_new_opening := COALESCE(p_opening_quantity, v_existing.opening_quantity);
  v_new_sold := COALESCE(p_sold_quantity, v_existing.sold_quantity);
  v_new_returned := COALESCE(p_returned_quantity, v_existing.returned_quantity);
  v_new_adjustment := COALESCE(p_inventory_adjustment, v_existing.inventory_adjustment);
  v_new_cost := COALESCE(p_cost_price, v_existing.cost_price);
  v_new_current := v_new_opening - v_new_sold + v_new_returned + v_new_adjustment;
  v_new_total := v_new_current * v_new_cost;
  v_new_version := v_existing.server_version + 1;

  UPDATE cloud_products SET
    name = COALESCE(trim(p_name), name),
    barcode = COALESCE(trim(p_barcode), barcode),
    opening_quantity = v_new_opening,
    sold_quantity = v_new_sold,
    returned_quantity = v_new_returned,
    inventory_adjustment = v_new_adjustment,
    cost_price = v_new_cost,
    current_quantity = v_new_current,
    total_inventory_cost = v_new_total,
    server_version = v_new_version,
    updated_at = now()
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'server_version', v_new_version
  );
END;
$$;

-- 3.2 Update update_cloud_expense to support server_version
CREATE OR REPLACE FUNCTION update_cloud_expense(
  p_shop_id UUID,
  p_expense_id UUID,
  p_date TIMESTAMPTZ DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_amount NUMERIC(12,2) DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing RECORD;
  v_new_cat_id UUID;
  v_new_cat_name TEXT;
  v_new_version INTEGER;
  v_conflict JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.create');

  SELECT * INTO v_existing
  FROM cloud_expenses
  WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Expense not found';
  END IF;

  IF p_expected_version IS NOT NULL AND v_existing.server_version != p_expected_version THEN
    v_conflict := jsonb_build_object(
      'status', 'CONFLICT',
      'server_version', v_existing.server_version,
      'expected_version', p_expected_version
    );
    RETURN v_conflict;
  END IF;

  v_new_cat_id := COALESCE(p_category_id, v_existing.category_id);

  IF v_new_cat_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM cloud_expense_categories
      WHERE id = v_new_cat_id AND shop_id = p_shop_id AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Category not found';
    END IF;
    SELECT name INTO v_new_cat_name FROM cloud_expense_categories WHERE id = v_new_cat_id;
  ELSE
    v_new_cat_name := NULL;
  END IF;

  v_new_version := v_existing.server_version + 1;

  UPDATE cloud_expenses SET
    date = COALESCE(p_date, date),
    description = COALESCE(trim(p_description), description),
    amount = COALESCE(p_amount, amount),
    category_id = v_new_cat_id,
    category_name = v_new_cat_name,
    server_version = v_new_version
  WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'server_version', v_new_version
  );
END;
$$;

-- 3.3 Update update_cloud_customer to support server_version
CREATE OR REPLACE FUNCTION update_cloud_customer(
  p_shop_id UUID,
  p_customer_id UUID,
  p_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing RECORD;
  v_new_version INTEGER;
  v_conflict JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  SELECT * INTO v_existing
  FROM cloud_customers
  WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  IF p_expected_version IS NOT NULL AND v_existing.server_version != p_expected_version THEN
    v_conflict := jsonb_build_object(
      'status', 'CONFLICT',
      'server_version', v_existing.server_version,
      'expected_version', p_expected_version
    );
    RETURN v_conflict;
  END IF;

  IF p_name IS NOT NULL AND trim(p_name) = '' THEN
    RAISE EXCEPTION 'Customer name is required';
  END IF;

  v_new_version := v_existing.server_version + 1;

  UPDATE cloud_customers SET
    name = COALESCE(trim(p_name), name),
    phone = COALESCE(p_phone, phone),
    address = COALESCE(p_address, address),
    notes = COALESCE(p_notes, notes),
    is_active = COALESCE(p_is_active, is_active),
    server_version = v_new_version,
    updated_at = now()
  WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'server_version', v_new_version
  );
END;
$$;

-- ============================================================================
-- 4. Idempotent sync upsert function
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_upsert_entity(
  p_shop_id UUID,
  p_entity_type TEXT,
  p_entity_id UUID,
  p_payload JSONB,
  p_idempotency_key TEXT,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing_log RECORD;
  v_permission TEXT;
  v_actor UUID := auth.uid();
BEGIN
  SELECT * INTO v_existing_log
  FROM sync_log
  WHERE idempotency_key = p_idempotency_key;

  IF v_existing_log IS NOT NULL THEN
    RETURN jsonb_build_object(
      'status', 'IDEMPOTENT',
      'original_status', v_existing_log.status,
      'original_result', v_existing_log.conflict_details
    );
  END IF;

  CASE p_entity_type
    WHEN 'product' THEN v_permission := 'inventory.edit';
    WHEN 'sale' THEN v_permission := 'sales.create';
    WHEN 'return' THEN v_permission := 'returns.create';
    WHEN 'expense' THEN v_permission := 'expenses.create';
    WHEN 'expenseCategory' THEN v_permission := 'expenses.create';
    WHEN 'customer' THEN v_permission := 'inventory.edit';
    WHEN 'invoice' THEN v_permission := 'sales.create';
    WHEN 'inventoryCount' THEN v_permission := 'stocktake.view';
    WHEN 'shopSetting' THEN v_permission := 'admin.settings.access';
    ELSE
      RAISE EXCEPTION 'Unknown entity type: %', p_entity_type;
  END CASE;

  PERFORM require_shop_permission(p_shop_id, v_permission);

  INSERT INTO sync_log (shop_id, entity_type, entity_id, operation,
    idempotency_key, actor_user_id, status)
  VALUES (p_shop_id, p_entity_type, p_entity_id, 'SYNC',
    p_idempotency_key, v_actor, 'SYNCED');

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'idempotency_key', p_idempotency_key
  );
END;
$$;

-- ============================================================================
-- 5. GRANT
-- ============================================================================

GRANT EXECUTE ON FUNCTION sync_upsert_entity(UUID, TEXT, UUID, JSONB, TEXT, INTEGER) TO authenticated;
