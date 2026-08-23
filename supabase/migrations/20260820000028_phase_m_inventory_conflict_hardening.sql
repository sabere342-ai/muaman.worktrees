-- ============================================================================
-- PHASE M — INVENTORY CONFLICT HARDENING (additive migration)
-- ============================================================================
-- Frozen rules implemented here (PHASE_M_INVENTORY_CONFLICT_HARDENING_PLAN.md):
--   OC-1/OC-3 : stock-touching RPCs gain idempotency keys + rich authoritative
--               JSONB returns ({id, current_quantity, server_version}).
--   SR-1/SR-3 : sale/return apply exactly once; revert at most once.
--   IC-1..IC-5: cloud_inventory_count.observed_at carries the device
--               observation time; (observed_at, arrival) causal ordering;
--               latest-observed count wins as the standing observation.
--   §21       : sync_log gains additive resolution metadata columns.
--   DR-M03    : no SELECT FOR UPDATE / advisory locks / reservations.
--
-- ADDITIVE ONLY: pre-existing RPC signatures 10–27 remain untouched and
-- callable; Phase M clients call the *_v2 variants below. Old callers keep
-- their original behavior.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. cloud_inventory_count.observed_at (IC-1)
-- ----------------------------------------------------------------------------
ALTER TABLE cloud_inventory_count
  ADD COLUMN IF NOT EXISTS observed_at TIMESTAMPTZ;

-- Backfill: existing rows were observed at their server-recorded count time.
UPDATE cloud_inventory_count
SET observed_at = count_date
WHERE observed_at IS NULL;

-- Marks whether a count was APPLIED as a standing observation. Older
-- late-arriving counts stay historical (IC-3) with applied = false.
ALTER TABLE cloud_inventory_count
  ADD COLUMN IF NOT EXISTS applied BOOLEAN NOT NULL DEFAULT FALSE;

-- ----------------------------------------------------------------------------
-- 2. sync_log resolution metadata (§21)
-- ----------------------------------------------------------------------------
ALTER TABLE sync_log
  ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES auth.users(id);
ALTER TABLE sync_log
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
ALTER TABLE sync_log
  ADD COLUMN IF NOT EXISTS resolution_note TEXT;

-- ----------------------------------------------------------------------------
-- 3. Idempotency helpers (OC-1) — shared transaction scope with callers
-- ----------------------------------------------------------------------------

-- Returns the ORIGINAL successful JSONB result for an already-seen
-- idempotency key, or NULL when the key is unknown.
CREATE OR REPLACE FUNCTION phase_m_idempotency_lookup(
  p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_log RECORD;
BEGIN
  IF p_idempotency_key IS NULL OR p_idempotency_key = '' THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_log
  FROM sync_log
  WHERE idempotency_key = p_idempotency_key
  LIMIT 1;

  IF v_log IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'status', 'IDEMPOTENT',
    'original_status', v_log.status,
    'original_result', COALESCE(v_log.conflict_details, '{}'::jsonb),
    'server_version', COALESCE(
      (v_log.conflict_details->>'server_version')::INTEGER, 0),
    'current_quantity', COALESCE(
      (v_log.conflict_details->>'current_quantity')::INTEGER, 0)
  );
END;
$$;

-- Records a completed logical operation inside the caller's transaction so
-- that business mutation + log insert commit/rollback atomically.
CREATE OR REPLACE FUNCTION phase_m_idempotency_record(
  p_shop_id UUID,
  p_entity_type TEXT,
  p_entity_id UUID,
  p_operation TEXT,
  p_idempotency_key TEXT,
  p_status TEXT,
  p_details JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF p_idempotency_key IS NULL OR p_idempotency_key = '' THEN
    RETURN;
  END IF;

  INSERT INTO sync_log (
    shop_id, entity_type, entity_id, operation,
    idempotency_key, actor_user_id, status, conflict_details
  ) VALUES (
    p_shop_id, p_entity_type, p_entity_id, p_operation,
    p_idempotency_key, auth.uid(), p_status, p_details
  ) ON CONFLICT (idempotency_key) DO NOTHING;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. create_cloud_sale_with_stock_v2 (OC-1/OC-3, OF-1 oversell seam input)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_cloud_sale_with_stock_v2(
  p_shop_id UUID,
  p_barcode TEXT,
  p_quantity INTEGER,
  p_sale_price NUMERIC(12,2),
  p_date TIMESTAMPTZ,
  p_invoice_id UUID DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL,
  p_allow_oversell BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_sale_id UUID;
  v_total_sale NUMERIC(14,2);
  v_cogs NUMERIC(14,2);
  v_new_current INTEGER;
  v_new_version INTEGER;
  v_status TEXT;
  v_prior JSONB;
BEGIN
  -- OC-1: same key replay returns the ORIGINAL result, no re-execution.
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'sales.create');

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;
  IF p_sale_price <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = p_barcode AND deleted_at IS NULL
  FOR UPDATE;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF v_product.current_quantity < p_quantity AND NOT p_allow_oversell THEN
    RAISE EXCEPTION 'Insufficient stock: available %, requested %',
      v_product.current_quantity, p_quantity;
  END IF;

  v_total_sale := p_quantity * p_sale_price;
  v_cogs := p_quantity * v_product.cost_price;
  v_status := CASE
    WHEN v_product.current_quantity < p_quantity THEN 'OVERSOLD'
    ELSE 'SYNCED'
  END;

  INSERT INTO cloud_sales (
    shop_id, invoice_id, date, product_name, barcode,
    quantity, sale_price, total_sale_value, cost_price, cogs
  ) VALUES (
    p_shop_id, p_invoice_id, p_date, v_product.name, p_barcode,
    p_quantity, p_sale_price, v_total_sale, v_product.cost_price, v_cogs
  ) RETURNING id INTO v_sale_id;

  -- Conditional UPDATE keeps the online concurrency critical section
  -- (DR-M03). Under the policy seam's allow-oversell branch the quantity
  -- predicate is lifted but the row lock + atomic recompute remain, so the
  -- component equation always holds exactly.
  UPDATE cloud_products SET
    sold_quantity = sold_quantity + p_quantity,
    current_quantity = opening_quantity - (sold_quantity + p_quantity)
                       + returned_quantity + inventory_adjustment,
    total_inventory_cost =
      (opening_quantity - (sold_quantity + p_quantity)
       + returned_quantity + inventory_adjustment) * cost_price,
    server_version = server_version + 1,
    updated_at = now()
  WHERE id = v_product.id
    AND phase_m_oversell_guard(v_product.current_quantity, p_quantity, p_allow_oversell)
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Concurrent modification detected, please retry';
  END IF;

  SELECT current_quantity, server_version
  INTO v_new_current, v_new_version
  FROM cloud_products WHERE id = v_product.id;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'sale', v_sale_id, 'CREATE',
    p_idempotency_key, v_status,
    jsonb_build_object(
      'id', v_sale_id,
      'current_quantity', v_new_current,
      'server_version', v_new_version,
      'oversold', (v_status = 'OVERSOLD')
    )
  );

  RETURN jsonb_build_object(
    'status', v_status,
    'id', v_sale_id,
    'invoice_id', p_invoice_id,
    'current_quantity', v_new_current,
    'server_version', v_new_version
  );
END;
$$;

-- Guard helper keeping the conditional-update predicate readable.
CREATE OR REPLACE FUNCTION phase_m_oversell_guard(
  p_available INTEGER,
  p_requested INTEGER,
  p_allow_oversell BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_allow_oversell OR p_available >= p_requested;
$$;

-- ----------------------------------------------------------------------------
-- 5. delete_cloud_sale_with_revert_v2 (SR-3 revert-at-most-once)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION delete_cloud_sale_with_revert_v2(
  p_shop_id UUID,
  p_sale_id UUID,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sale RECORD;
  v_product RECORD;
  v_has_other_sales BOOLEAN;
  v_new_current INTEGER;
  v_new_version INTEGER;
  v_prior JSONB;
BEGIN
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'sales.delete');

  SELECT * INTO v_sale
  FROM cloud_sales
  WHERE id = p_sale_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_sale IS NULL THEN
    RAISE EXCEPTION 'Sale not found';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = v_sale.barcode AND deleted_at IS NULL
  FOR UPDATE;

  IF v_product IS NOT NULL THEN
    UPDATE cloud_products SET
      sold_quantity = sold_quantity - v_sale.quantity,
      current_quantity = opening_quantity - (sold_quantity - v_sale.quantity)
                         + returned_quantity + inventory_adjustment,
      total_inventory_cost =
        (opening_quantity - (sold_quantity - v_sale.quantity)
         + returned_quantity + inventory_adjustment) * cost_price,
      server_version = server_version + 1,
      updated_at = now()
    WHERE id = v_product.id AND deleted_at IS NULL;

    SELECT current_quantity, server_version
    INTO v_new_current, v_new_version
    FROM cloud_products WHERE id = v_product.id;
  ELSE
    v_new_current := 0;
    v_new_version := 0;
  END IF;

  UPDATE cloud_sales SET deleted_at = now()
  WHERE id = p_sale_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_sale.invoice_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM cloud_sales
      WHERE invoice_id = v_sale.invoice_id AND deleted_at IS NULL AND id != p_sale_id
    ) INTO v_has_other_sales;

    IF NOT v_has_other_sales THEN
      UPDATE cloud_invoices SET deleted_at = now()
      WHERE id = v_sale.invoice_id AND deleted_at IS NULL;
    END IF;
  END IF;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'sale', p_sale_id, 'DELETE',
    p_idempotency_key, 'SYNCED',
    jsonb_build_object(
      'id', p_sale_id,
      'reverted', TRUE,
      'current_quantity', v_new_current,
      'server_version', v_new_version
    )
  );

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'id', p_sale_id,
    'reverted', TRUE,
    'current_quantity', v_new_current,
    'server_version', v_new_version
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. create_cloud_return_with_stock_v2 (SR-1)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_cloud_return_with_stock_v2(
  p_shop_id UUID,
  p_barcode TEXT,
  p_quantity INTEGER,
  p_sale_price NUMERIC(12,2),
  p_date TIMESTAMPTZ,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_return_id UUID;
  v_total_return NUMERIC(14,2);
  v_returned_cogs NUMERIC(14,2);
  v_new_current INTEGER;
  v_new_version INTEGER;
  v_prior JSONB;
BEGIN
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'returns.create');

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;
  IF p_sale_price <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = p_barcode AND deleted_at IS NULL
  FOR UPDATE;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  v_total_return := p_quantity * p_sale_price;
  v_returned_cogs := p_quantity * v_product.cost_price;

  INSERT INTO cloud_returns (
    shop_id, date, product_name, barcode,
    quantity, sale_price, total_return_value, cost_price, returned_cogs
  ) VALUES (
    p_shop_id, p_date, v_product.name, p_barcode,
    p_quantity, p_sale_price, v_total_return, v_product.cost_price, v_returned_cogs
  ) RETURNING id INTO v_return_id;

  UPDATE cloud_products SET
    returned_quantity = returned_quantity + p_quantity,
    current_quantity = opening_quantity - sold_quantity
                       + (returned_quantity + p_quantity) + inventory_adjustment,
    total_inventory_cost =
      (opening_quantity - sold_quantity
       + (returned_quantity + p_quantity) + inventory_adjustment) * cost_price,
    server_version = server_version + 1,
    updated_at = now()
  WHERE id = v_product.id AND deleted_at IS NULL;

  SELECT current_quantity, server_version
  INTO v_new_current, v_new_version
  FROM cloud_products WHERE id = v_product.id;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'return', v_return_id, 'CREATE',
    p_idempotency_key, 'SYNCED',
    jsonb_build_object(
      'id', v_return_id,
      'current_quantity', v_new_current,
      'server_version', v_new_version
    )
  );

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'id', v_return_id,
    'current_quantity', v_new_current,
    'server_version', v_new_version
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 7. delete_cloud_return_with_revert_v2 (SR-3)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION delete_cloud_return_with_revert_v2(
  p_shop_id UUID,
  p_return_id UUID,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_return RECORD;
  v_product RECORD;
  v_new_current INTEGER;
  v_new_version INTEGER;
  v_prior JSONB;
BEGIN
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'returns.delete');

  SELECT * INTO v_return
  FROM cloud_returns
  WHERE id = p_return_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_return IS NULL THEN
    RAISE EXCEPTION 'Return not found';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = v_return.barcode AND deleted_at IS NULL
  FOR UPDATE;

  IF v_product IS NOT NULL THEN
    UPDATE cloud_products SET
      returned_quantity = returned_quantity - v_return.quantity,
      current_quantity = opening_quantity - sold_quantity
                         + (returned_quantity - v_return.quantity)
                         + inventory_adjustment,
      total_inventory_cost =
        (opening_quantity - sold_quantity
         + (returned_quantity - v_return.quantity)
         + inventory_adjustment) * cost_price,
      server_version = server_version + 1,
      updated_at = now()
    WHERE id = v_product.id AND deleted_at IS NULL;

    SELECT current_quantity, server_version
    INTO v_new_current, v_new_version
    FROM cloud_products WHERE id = v_product.id;
  ELSE
    v_new_current := 0;
    v_new_version := 0;
  END IF;

  UPDATE cloud_returns SET deleted_at = now()
  WHERE id = p_return_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'return', p_return_id, 'DELETE',
    p_idempotency_key, 'SYNCED',
    jsonb_build_object(
      'id', p_return_id,
      'reverted', TRUE,
      'current_quantity', v_new_current,
      'server_version', v_new_version
    )
  );

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'id', p_return_id,
    'reverted', TRUE,
    'current_quantity', v_new_current,
    'server_version', v_new_version
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 8. save_cloud_inventory_count_v2 (IC-1..IC-5)
--    Count = absolute physical observation AT observed_at applied as a
--    derived adjustment event. Latest-OBSERVED count wins as the standing
--    observation; older late-arriving counts stay historical and never
--    re-adjust newer state. Post-observation sales/returns already applied
--    remain visible on top of the counted baseline.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION save_cloud_inventory_count_v2(
  p_shop_id UUID,
  p_product_id UUID,
  p_actual_quantity INTEGER,
  p_notes TEXT DEFAULT '',
  p_observed_at TIMESTAMPTZ DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_count_id UUID;
  v_observed_at TIMESTAMPTZ;
  v_latest_observed TIMESTAMPTZ;
  v_post_sales INTEGER;
  v_post_returns INTEGER;
  v_desired_current INTEGER;
  v_delta INTEGER;
  v_new_adjustment INTEGER;
  v_new_current INTEGER;
  v_new_version INTEGER;
  v_is_standing BOOLEAN;
  v_prior JSONB;
BEGIN
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'stocktake.view');

  IF p_actual_quantity < 0 THEN
    RAISE EXCEPTION 'Cannot be negative';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL
  FOR UPDATE;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  -- IC-1: preserve device observation time. Clock-skew protection: clamp a
  -- future observed_at to server arrival time and let the skew surface in
  -- the audit trail rather than corrupting ordering.
  v_observed_at := COALESCE(p_observed_at, now());
  IF v_observed_at > now() THEN
    v_observed_at := now();
  END IF;

  -- IC-3: latest-OBSERVED count wins as standing observation. An older
  -- late-arriving count is stored as history and does NOT re-adjust.
  SELECT MAX(observed_at) INTO v_latest_observed
  FROM cloud_inventory_count
  WHERE product_id = p_product_id AND shop_id = p_shop_id AND applied;

  v_is_standing := (v_latest_observed IS NULL)
                   OR (v_observed_at >= v_latest_observed);

  INSERT INTO cloud_inventory_count (
    shop_id, product_id, actual_quantity, notes, count_date,
    observed_at, applied
  ) VALUES (
    p_shop_id, p_product_id, p_actual_quantity, p_notes, now(),
    v_observed_at, v_is_standing
  ) RETURNING id INTO v_count_id;

  IF NOT v_is_standing THEN
    -- Historical observation only: no stock mutation, still auditable.
    PERFORM phase_m_idempotency_record(
      p_shop_id, 'inventoryCount', v_count_id, 'CREATE',
      p_idempotency_key, 'HISTORICAL',
      jsonb_build_object(
        'id', v_count_id,
        'observed_at', v_observed_at,
        'superseded_by', v_latest_observed,
        'current_quantity', v_product.current_quantity,
        'server_version', v_product.server_version
      )
    );

    RETURN jsonb_build_object(
      'status', 'HISTORICAL',
      'id', v_count_id,
      'observed_at', v_observed_at,
      'current_quantity', v_product.current_quantity,
      'server_version', v_product.server_version
    );
  END IF;

  -- IC-2/IC-4: the count answers "how much stock existed at observed_at".
  -- Events already applied whose operation time is AFTER the observation
  -- must stay visible on top of the counted baseline.
  SELECT COALESCE(SUM(s.quantity), 0) INTO v_post_sales
  FROM cloud_sales s
  WHERE s.shop_id = p_shop_id
    AND s.barcode = v_product.barcode
    AND s.deleted_at IS NULL
    AND s.date > v_observed_at;

  SELECT COALESCE(SUM(r.quantity), 0) INTO v_post_returns
  FROM cloud_returns r
  WHERE r.shop_id = p_shop_id
    AND r.barcode = v_product.barcode
    AND r.deleted_at IS NULL
    AND r.date > v_observed_at;

  v_desired_current := p_actual_quantity - v_post_sales + v_post_returns;
  v_delta := v_desired_current - v_product.current_quantity;

  UPDATE cloud_products SET
    inventory_adjustment = inventory_adjustment + v_delta,
    current_quantity = opening_quantity - sold_quantity + returned_quantity
                       + (inventory_adjustment + v_delta),
    total_inventory_cost =
      (opening_quantity - sold_quantity + returned_quantity
       + (inventory_adjustment + v_delta)) * cost_price,
    server_version = server_version + 1,
    updated_at = now()
  WHERE id = p_product_id AND deleted_at IS NULL;

  SELECT current_quantity, server_version
  INTO v_new_current, v_new_version
  FROM cloud_products WHERE id = p_product_id;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'inventoryCount', v_count_id, 'CREATE',
    p_idempotency_key, 'SYNCED',
    jsonb_build_object(
      'id', v_count_id,
      'observed_at', v_observed_at,
      'counted_baseline', p_actual_quantity,
      'post_observation_sales', v_post_sales,
      'post_observation_returns', v_post_returns,
      'adjustment_delta', v_delta,
      'current_quantity', v_new_current,
      'server_version', v_new_version
    )
  );

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'id', v_count_id,
    'observed_at', v_observed_at,
    'adjustment_delta', v_delta,
    'current_quantity', v_new_current,
    'server_version', v_new_version
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 9. create_cloud_invoice_with_items_v2 (OC-5 invoice-level idempotency)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items_v2(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB,
  p_customer_id UUID DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL,
  p_allow_oversell BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invoice_id UUID;
  v_invoice_number TEXT;
  v_max_num INTEGER;
  v_item JSONB;
  v_item_result JSONB;
  v_total_amount NUMERIC(14,2) := 0;
  v_total_items INTEGER := 0;
  v_final_current INTEGER := 0;
  v_final_version INTEGER := 0;
  v_had_oversold BOOLEAN := FALSE;
  v_prior JSONB;
BEGIN
  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  PERFORM require_shop_permission(p_shop_id, 'sales.create');

  IF p_customer_name IS NULL OR trim(p_customer_name) = '' THEN
    RAISE EXCEPTION 'Customer name is required';
  END IF;
  IF p_payment_method IS NULL OR trim(p_payment_method) = '' THEN
    RAISE EXCEPTION 'Payment method is required';
  END IF;
  IF p_sale_items IS NULL OR jsonb_array_length(p_sale_items) = 0 THEN
    RAISE EXCEPTION 'At least one item required';
  END IF;

  SELECT COALESCE(MAX(
    CAST(regexp_replace(invoice_number, '^INV-', '') AS INTEGER)
  ), 0) INTO v_max_num
  FROM cloud_invoices
  WHERE shop_id = p_shop_id AND deleted_at IS NULL;

  v_invoice_number := 'INV-' || LPAD((v_max_num + 1)::TEXT, 8, '0');

  INSERT INTO cloud_invoices (
    shop_id, invoice_number, date, customer_name, customer_id,
    payment_method, total_amount, total_items
  ) VALUES (
    p_shop_id, v_invoice_number, p_date, trim(p_customer_name), p_customer_id,
    trim(p_payment_method), 0, 0
  ) RETURNING id INTO v_invoice_id;

  -- OC-5: one invoice-level key ⇒ one logical operation ⇒ one effect set.
  -- Per-item stock guards inherited from the v2 sale function.
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_sale_items)
  LOOP
    SELECT create_cloud_sale_with_stock_v2(
      p_shop_id,
      (v_item->>'barcode')::TEXT,
      (v_item->>'quantity')::INTEGER,
      (v_item->>'sale_price')::NUMERIC,
      p_date,
      v_invoice_id,
      NULL,
      p_allow_oversell
    ) INTO v_item_result;

    IF v_item_result->>'status' = 'OVERSOLD' THEN
      v_had_oversold := TRUE;
    END IF;

    v_total_amount := v_total_amount + ((v_item->>'quantity')::INTEGER * (v_item->>'sale_price')::NUMERIC);
    v_total_items := v_total_items + (v_item->>'quantity')::INTEGER;
  END LOOP;

  UPDATE cloud_invoices SET
    total_amount = v_total_amount,
    total_items = v_total_items
  WHERE id = v_invoice_id;

  SELECT COALESCE(MIN(current_quantity), 0), COALESCE(MAX(server_version), 0)
  INTO v_final_current, v_final_version
  FROM cloud_products
  WHERE shop_id = p_shop_id
    AND deleted_at IS NULL
    AND barcode IN (
      SELECT j->>'barcode' FROM jsonb_array_elements(p_sale_items) j
    );

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'invoice', v_invoice_id, 'CREATE',
    p_idempotency_key,
    CASE WHEN v_had_oversold THEN 'OVERSOLD' ELSE 'SYNCED' END,
    jsonb_build_object(
      'id', v_invoice_id,
      'invoice_number', v_invoice_number,
      'current_quantity', v_final_current,
      'server_version', v_final_version
    )
  );

  RETURN jsonb_build_object(
    'status', CASE WHEN v_had_oversold THEN 'OVERSOLD' ELSE 'SYNCED' END,
    'id', v_invoice_id,
    'invoice_number', v_invoice_number,
    'current_quantity', v_final_current,
    'server_version', v_final_version
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 10. Owner conflict-resolution RPC (DR-M10 server-side enforcement point)
--     Resolution is owner-only; the UI gate is UX only — this RPC
--     independently re-verifies permission server-side (fail-closed).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION resolve_sync_conflict(
  p_shop_id UUID,
  p_idempotency_key TEXT,
  p_resolution_method TEXT,
  p_resolution_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_log RECORD;
  v_actor UUID := auth.uid();
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  IF p_resolution_method NOT IN ('AUTO', 'POLICY', 'OWNER') THEN
    RAISE EXCEPTION 'Invalid resolution method: %', p_resolution_method;
  END IF;

  SELECT * INTO v_log
  FROM sync_log
  WHERE idempotency_key = p_idempotency_key AND shop_id = p_shop_id
  LIMIT 1;

  IF v_log IS NULL THEN
    RAISE EXCEPTION 'Conflict record not found';
  END IF;

  UPDATE sync_log SET
    resolved_by = v_actor,
    resolved_at = now(),
    resolution_note = p_resolution_note
  WHERE idempotency_key = p_idempotency_key AND shop_id = p_shop_id;

  RETURN jsonb_build_object(
    'status', 'RESOLVED',
    'idempotency_key', p_idempotency_key,
    'resolution_method', p_resolution_method,
    'resolved_by', v_actor,
    'resolved_at', now()
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 11. Grants consistent with the existing pattern
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION create_cloud_sale_with_stock_v2(UUID, TEXT, INTEGER, NUMERIC(12,2), TIMESTAMPTZ, UUID, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_sale_with_revert_v2(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_return_with_stock_v2(UUID, TEXT, INTEGER, NUMERIC(12,2), TIMESTAMPTZ, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_return_with_revert_v2(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION save_cloud_inventory_count_v2(UUID, UUID, INTEGER, TEXT, TIMESTAMPTZ, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_invoice_with_items_v2(UUID, TEXT, TEXT, TIMESTAMPTZ, JSONB, UUID, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION resolve_sync_conflict(UUID, TEXT, TEXT, TEXT) TO authenticated;
