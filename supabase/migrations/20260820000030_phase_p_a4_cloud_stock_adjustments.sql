-- ============================================================================
-- PHASE P GROUP A A4 — SERVER-SIDE OPTION C DURABILITY (additive migration)
-- ============================================================================
-- Governs: P-OD1 SERVER HALF (PHASE_P_OWNER_GATED_GROUP_A_A4_SERVER_DURABILITY_MIGRATION)
--
-- Adds the durable, tenant-scoped, traceable, idempotent, auditable,
-- non-silent, reconcilable record for negative-stock (OVERSOLD) events:
--
--   cloud_stock_adjustments
--
-- (1) A negative-stock sale/event MUST NEVER disappear: when an oversold
--     sale is preserved server-side, an explicit adjustment artifact is
--     recorded in the SAME transaction as the sale + stock effect + sync_log
--     idempotency record, so sale, stock state, explicit adjustment, and
--     durable audit evidence commit/rollback atomically.
-- (2) Owner-gated (admin.settings.access) RPC surface to create / list /
--     resolve adjustment artifacts. UI is UX only — every RPC re-verifies
--     the permission server-side (fail-closed).
-- (3) RLS follows the existing shop_id row-level pattern; direct table
--     access is revoked from authenticated (fail-closed read path goes
--     through the owner-gated list RPC only).
--
-- ADDITIVE ONLY, backwards-compatible:
--   * create_cloud_sale_with_stock_v2 is re-created with an IDENTICAL
--     signature/defaults/return contract. The only body change is an
--     additive adjustment insert in the OVERSOLD branch. Legacy callers
--     (p_allow_oversell = FALSE, omitted keys) observe NO behavior change.
--   * Existing grants survive CREATE OR REPLACE (grant is signature-based).
--   * Positioned AFTER migration 20260820000029; does not renumber/modify
--     migrations 1-29.
--   * The migration-28 concurrency contract is preserved untouched:
--     row-lock serialization (SELECT ... FOR UPDATE), the conditional/CAS
--     oversell guard, phase_m_idempotency_lookup / phase_m_idempotency_record,
--     and exact replay semantics all remain exactly as shipped.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. cloud_stock_adjustments — durable Option C (P-OD1) evidence
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cloud_stock_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES cloud_products(id) ON DELETE RESTRICT,
  barcode TEXT NOT NULL,
  -- Post-event server-authoritative stock after applying ALL preserved
  -- events (negative only when an oversell occurred).
  projected_current INTEGER NOT NULL,
  -- How far below zero projected stock fell (strictly positive):
  -- shortfall = -projected_current when the OVERSOLD sale left stock
  -- negative, mirroring the client OversellAdjustmentArtifact model.
  shortfall INTEGER NOT NULL,
  -- OVERSOLD = auto-recorded by create_cloud_sale_with_stock_v2;
  -- MANUAL = explicit owner-governed artifact via the owner RPC.
  adjustment_type TEXT NOT NULL DEFAULT 'OVERSOLD'
    CHECK (adjustment_type IN ('OVERSOLD', 'MANUAL')),
  -- Related financial event linkage (deterministic identity for a sale
  -- whose idempotency key is NULL, i.e. invoice-item oversell events).
  sale_id UUID REFERENCES cloud_sales(id) ON DELETE SET NULL,
  return_id UUID REFERENCES cloud_returns(id) ON DELETE SET NULL,
  invoice_id UUID REFERENCES cloud_invoices(id) ON DELETE SET NULL,
  -- Same logical-operation key as the governing sale where one exists.
  -- Replays short-circuit in phase_m_idempotency_lookup BEFORE any insert,
  -- so this shop-scoped uniqueness is a redundant second guard.
  idempotency_key TEXT,
  status TEXT NOT NULL DEFAULT 'OPEN'
    CHECK (status IN ('OPEN', 'RESOLVED')),
  resolution_note TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uniq_cloud_stock_adj_shop_key UNIQUE (shop_id, idempotency_key),
  CONSTRAINT chk_cloud_stock_adj_shortfall CHECK (shortfall > 0)
);

COMMENT ON TABLE cloud_stock_adjustments IS
  'A4/P-OD1 durable Option C evidence: an explicit, tenant-scoped, idempotent adjustment artifact for every preserved oversold event.';

CREATE INDEX IF NOT EXISTS idx_cloud_stock_adj_shop_id
  ON cloud_stock_adjustments (shop_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cloud_stock_adj_product_id
  ON cloud_stock_adjustments (product_id);
CREATE INDEX IF NOT EXISTS idx_cloud_stock_adj_status
  ON cloud_stock_adjustments (status);
CREATE INDEX IF NOT EXISTS idx_cloud_stock_adj_sale_id
  ON cloud_stock_adjustments (sale_id);
CREATE INDEX IF NOT EXISTS idx_cloud_stock_adj_idempotency_key
  ON cloud_stock_adjustments (idempotency_key);

-- ----------------------------------------------------------------------------
-- 2. RLS — existing shop_id row-level isolation pattern (SELECT only)
-- ----------------------------------------------------------------------------
ALTER TABLE cloud_stock_adjustments ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_isolation_stock_adjustments ON cloud_stock_adjustments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_stock_adjustments.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

COMMENT ON POLICY shop_isolation_stock_adjustments ON cloud_stock_adjustments IS
  'A4: active members may read adjustment rows of their own shops only (fail-closed tenant isolation; no INSERT/UPDATE/DELETE policies).';

-- ----------------------------------------------------------------------------
-- 3. Automatic adjustment recording in the oversell server flow (P-OD1)
--    Re-creates create_cloud_sale_with_stock_v2 with an IDENTICAL
--    signature/defaults/return contract. The only body change is the
--    additive, transactional OVERSOLD adjustment insert in section 4.
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
  -- (migration 28). Under the policy seam's allow-oversell branch the
  -- quantity predicate is lifted but the row lock + atomic recompute
  -- remain, so the component equation always holds exactly.
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

  -- === A4 ADDITION (additive, P-OD1): durable OVERSOLD adjustment ===
  -- Sale, stock effect, sync_log idempotency record and this adjustment
  -- all commit/rollback in the SAME transaction. A replay never reaches
  -- here (lookup short-circuit above). The record is linked to the
  -- governing sale; shortfall = -projected_current (positive).
  IF v_status = 'OVERSOLD' THEN
    INSERT INTO cloud_stock_adjustments (
      shop_id, product_id, barcode, projected_current, shortfall,
      adjustment_type, sale_id, invoice_id, idempotency_key,
      status, created_by
    ) VALUES (
      p_shop_id, v_product.id, p_barcode, v_new_current,
      GREATEST(0, -v_new_current),
      'OVERSOLD', v_sale_id, p_invoice_id, p_idempotency_key,
      'OPEN', auth.uid()
    ) ON CONFLICT DO NOTHING;
  END IF;

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

COMMENT ON FUNCTION create_cloud_sale_with_stock_v2(UUID, TEXT, INTEGER, NUMERIC(12,2), TIMESTAMPTZ, UUID, TEXT, BOOLEAN) IS
  'A4-additive: identical signature/defaults/return contract; records a durable cloud_stock_adjustments artifact transactionally when an OVERSOLD event is preserved.';

-- ----------------------------------------------------------------------------
-- 4. Owner-gated adjustment RPC surface (admin.settings.access)
--    Server-authoritative: owner bypass + admin.settings.access only.
--    UI is never the security authority.
-- ----------------------------------------------------------------------------

-- 4.1 create_cloud_stock_adjustment
CREATE OR REPLACE FUNCTION create_cloud_stock_adjustment(
  p_shop_id UUID,
  p_product_id UUID,
  p_projected_current INTEGER,
  p_shortfall INTEGER,
  p_adjustment_type TEXT DEFAULT 'OVERSOLD',
  p_sale_id UUID DEFAULT NULL,
  p_return_id UUID DEFAULT NULL,
  p_invoice_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_adj_id UUID;
  v_prior JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  v_prior := phase_m_idempotency_lookup(p_idempotency_key);
  IF v_prior IS NOT NULL THEN
    RETURN v_prior;
  END IF;

  IF p_shortfall <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;
  IF p_adjustment_type NOT IN ('OVERSOLD', 'MANUAL') THEN
    RAISE EXCEPTION 'Invalid adjustment type: %', p_adjustment_type;
  END IF;

  -- Tenant-scoped linkage validation: every supplied identifier must belong
  -- to this shop (fail-closed; never ambient shop context).
  SELECT * INTO v_product
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF p_sale_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM cloud_sales
    WHERE id = p_sale_id AND shop_id = p_shop_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Sale not found in shop';
  END IF;

  IF p_return_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM cloud_returns
    WHERE id = p_return_id AND shop_id = p_shop_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Return not found in shop';
  END IF;

  IF p_invoice_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM cloud_invoices
    WHERE id = p_invoice_id AND shop_id = p_shop_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Invoice not found in shop';
  END IF;

  INSERT INTO cloud_stock_adjustments (
    shop_id, product_id, barcode, projected_current, shortfall,
    adjustment_type, sale_id, return_id, invoice_id, idempotency_key,
    status, resolution_note, created_by
  ) VALUES (
    p_shop_id, p_product_id, v_product.barcode, p_projected_current, p_shortfall,
    p_adjustment_type, p_sale_id, p_return_id, p_invoice_id, p_idempotency_key,
    'OPEN', p_notes, auth.uid()
  ) RETURNING id INTO v_adj_id;

  PERFORM phase_m_idempotency_record(
    p_shop_id, 'stockAdjustment', v_adj_id, 'CREATE',
    p_idempotency_key, 'SYNCED',
    jsonb_build_object(
      'id', v_adj_id,
      'adjustment_type', p_adjustment_type,
      'projected_current', p_projected_current,
      'shortfall', p_shortfall
    )
  );

  RETURN jsonb_build_object(
    'status', 'SYNCED',
    'id', v_adj_id,
    'shop_id', p_shop_id,
    'product_id', p_product_id,
    'barcode', v_product.barcode,
    'projected_current', p_projected_current,
    'shortfall', p_shortfall,
    'adjustment_type', p_adjustment_type,
    'sale_id', p_sale_id,
    'return_id', p_return_id,
    'invoice_id', p_invoice_id,
    'idempotency_key', p_idempotency_key,
    'record_status', 'OPEN',
    'created_at', now()
  );
END;
$$;

-- 4.2 list_cloud_stock_adjustments
CREATE OR REPLACE FUNCTION list_cloud_stock_adjustments(
  p_shop_id UUID,
  p_status TEXT DEFAULT NULL,
  p_product_id UUID DEFAULT NULL,
  p_sale_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 200,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_items JSONB;
  v_total INTEGER;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  IF p_limit <= 0 OR p_limit > 1000 THEN
    RAISE EXCEPTION 'Invalid limit';
  END IF;
  IF p_offset < 0 THEN
    RAISE EXCEPTION 'Invalid offset';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', a.id,
      'shop_id', a.shop_id,
      'product_id', a.product_id,
      'barcode', a.barcode,
      'projected_current', a.projected_current,
      'shortfall', a.shortfall,
      'adjustment_type', a.adjustment_type,
      'sale_id', a.sale_id,
      'return_id', a.return_id,
      'invoice_id', a.invoice_id,
      'idempotency_key', a.idempotency_key,
      'record_status', a.status,
      'resolution_note', a.resolution_note,
      'resolved_by', a.resolved_by,
      'resolved_at', a.resolved_at,
      'created_by', a.created_by,
      'created_at', a.created_at
    ) ORDER BY a.created_at DESC, a.id DESC
  ), '[]'::jsonb) INTO v_items
  FROM cloud_stock_adjustments a
  WHERE a.shop_id = p_shop_id
    AND a.deleted_at IS NULL
    AND (p_status IS NULL OR a.status = p_status)
    AND (p_product_id IS NULL OR a.product_id = p_product_id)
    AND (p_sale_id IS NULL OR a.sale_id = p_sale_id)
  LIMIT p_limit OFFSET p_offset;

  SELECT count(*) INTO v_total
  FROM cloud_stock_adjustments a
  WHERE a.shop_id = p_shop_id
    AND a.deleted_at IS NULL
    AND (p_status IS NULL OR a.status = p_status)
    AND (p_product_id IS NULL OR a.product_id = p_product_id)
    AND (p_sale_id IS NULL OR a.sale_id = p_sale_id);

  RETURN jsonb_build_object('total', v_total, 'items', v_items);
END;
$$;

-- 4.3 resolve_cloud_stock_adjustment
CREATE OR REPLACE FUNCTION resolve_cloud_stock_adjustment(
  p_shop_id UUID,
  p_adjustment_id UUID,
  p_resolution_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_cur RECORD;
  v_resolved_at TIMESTAMPTZ;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  SELECT * INTO v_cur
  FROM cloud_stock_adjustments
  WHERE id = p_adjustment_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_cur IS NULL THEN
    RAISE EXCEPTION 'Adjustment not found';
  END IF;

  -- Idempotent resolve: re-resolving an already-resolved artifact preserves
  -- the ORIGINAL resolution authorities (never silently re-stamps).
  IF v_cur.status = 'RESOLVED' AND v_cur.resolved_at IS NOT NULL THEN
    v_resolved_at := v_cur.resolved_at;
  ELSE
    v_resolved_at := now();
    UPDATE cloud_stock_adjustments SET
      status = 'RESOLVED',
      resolved_by = v_actor,
      resolved_at = v_resolved_at,
      resolution_note = p_resolution_note
    WHERE id = p_adjustment_id AND shop_id = p_shop_id;
  END IF;

  RETURN jsonb_build_object(
    'status', 'RESOLVED',
    'id', p_adjustment_id,
    'shop_id', p_shop_id,
    'record_status', 'RESOLVED',
    'resolved_by', COALESCE(v_cur.resolved_by, v_actor),
    'resolved_at', v_resolved_at
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Grants / revoke (existing pattern)
--    Direct table access is revoked from authenticated; the read/write
--    surface is the owner-gated SECURITY DEFINER RPCs only.
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION create_cloud_stock_adjustment(UUID, UUID, INTEGER, INTEGER, TEXT, UUID, UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION list_cloud_stock_adjustments(UUID, TEXT, UUID, UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION resolve_cloud_stock_adjustment(UUID, UUID, TEXT) TO authenticated;

REVOKE ALL ON cloud_stock_adjustments FROM authenticated;