-- Phase G Migration 25: Cloud Data Foundation
-- Tables: cloud_products, cloud_customers, cloud_sales, cloud_returns,
--   cloud_expenses, cloud_expense_categories, cloud_invoices,
--   cloud_inventory_count, cloud_shop_settings
-- SECURITY DEFINER functions: 19 CRUD/atomic functions
-- RLS: SELECT-only policies on all new tables
-- Indexes: shop-scoped, FK, sync-ready updated_at
--
-- This migration is ADDITIVE ONLY - no destructive changes to existing data.

-- ============================================================================
-- 1. TABLES (dependency order)
-- ============================================================================

-- 1.1 cloud_expense_categories (no FK dependencies beyond shops)
CREATE TABLE IF NOT EXISTS cloud_expense_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uniq_cloud_exp_cat_shop_name UNIQUE (shop_id, name)
);

-- 1.2 cloud_products (no FK dependencies beyond shops)
CREATE TABLE IF NOT EXISTS cloud_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  barcode TEXT NOT NULL,
  opening_quantity INTEGER NOT NULL DEFAULT 0,
  sold_quantity INTEGER NOT NULL DEFAULT 0,
  returned_quantity INTEGER NOT NULL DEFAULT 0,
  current_quantity INTEGER NOT NULL DEFAULT 0,
  cost_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_inventory_cost NUMERIC(14,2) NOT NULL DEFAULT 0,
  inventory_adjustment INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uniq_cloud_products_shop_barcode UNIQUE (shop_id, barcode),
  CONSTRAINT chk_cloud_products_opening_qty CHECK (opening_quantity >= 0),
  CONSTRAINT chk_cloud_products_sold_qty CHECK (sold_quantity >= 0),
  CONSTRAINT chk_cloud_products_returned_qty CHECK (returned_quantity >= 0),
  CONSTRAINT chk_cloud_products_cost_price CHECK (cost_price >= 0)
);

-- 1.3 cloud_customers (no FK dependencies beyond shops)
CREATE TABLE IF NOT EXISTS cloud_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_system BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 1.4 cloud_shop_settings (no FK dependencies beyond shops)
CREATE TABLE IF NOT EXISTS cloud_shop_settings (
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  setting_key TEXT NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID,
  PRIMARY KEY (shop_id, setting_key)
);

-- 1.5 cloud_expenses (FK -> cloud_expense_categories)
CREATE TABLE IF NOT EXISTS cloud_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  category_name TEXT,
  category_id UUID REFERENCES cloud_expense_categories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT chk_cloud_expenses_amount CHECK (amount >= 0)
);

-- 1.6 cloud_inventory_count (FK -> cloud_products)
CREATE TABLE IF NOT EXISTS cloud_inventory_count (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES cloud_products(id) ON DELETE RESTRICT,
  actual_quantity INTEGER NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT '',
  count_date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT chk_cloud_inv_count_qty CHECK (actual_quantity >= 0)
);

-- 1.7 cloud_invoices (FK -> cloud_customers nullable)
CREATE TABLE IF NOT EXISTS cloud_invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  invoice_number TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  customer_name TEXT NOT NULL,
  customer_id UUID REFERENCES cloud_customers(id) ON DELETE SET NULL,
  payment_method TEXT NOT NULL,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_items INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uniq_cloud_invoices_shop_number UNIQUE (shop_id, invoice_number),
  CONSTRAINT chk_cloud_invoices_total CHECK (total_amount >= 0),
  CONSTRAINT chk_cloud_invoices_items CHECK (total_items >= 0)
);

-- 1.8 cloud_sales (FK -> cloud_invoices nullable)
CREATE TABLE IF NOT EXISTS cloud_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES cloud_invoices(id) ON DELETE SET NULL,
  date TIMESTAMPTZ NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  sale_price NUMERIC(12,2) NOT NULL,
  total_sale_value NUMERIC(14,2) NOT NULL,
  cost_price NUMERIC(12,2) NOT NULL,
  cogs NUMERIC(14,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT chk_cloud_sales_qty CHECK (quantity > 0),
  CONSTRAINT chk_cloud_sales_price CHECK (sale_price >= 0)
);

-- 1.9 cloud_returns (no FK dependencies beyond shops)
CREATE TABLE IF NOT EXISTS cloud_returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  sale_price NUMERIC(12,2) NOT NULL,
  total_return_value NUMERIC(14,2) NOT NULL,
  cost_price NUMERIC(12,2) NOT NULL,
  returned_cogs NUMERIC(14,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT chk_cloud_returns_qty CHECK (quantity > 0),
  CONSTRAINT chk_cloud_returns_price CHECK (sale_price >= 0)
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

-- cloud_products
CREATE INDEX IF NOT EXISTS idx_cloud_products_shop_id ON cloud_products (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_products_updated_at ON cloud_products (shop_id, updated_at);

-- cloud_customers
CREATE INDEX IF NOT EXISTS idx_cloud_customers_shop_id ON cloud_customers (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_customers_name ON cloud_customers (shop_id, name);

-- cloud_sales
CREATE INDEX IF NOT EXISTS idx_cloud_sales_shop_id ON cloud_sales (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_sales_invoice_id ON cloud_sales (invoice_id);
CREATE INDEX IF NOT EXISTS idx_cloud_sales_barcode ON cloud_sales (shop_id, barcode);
CREATE INDEX IF NOT EXISTS idx_cloud_sales_date ON cloud_sales (shop_id, date);
CREATE INDEX IF NOT EXISTS idx_cloud_sales_updated_at ON cloud_sales (shop_id, created_at DESC);

-- cloud_returns
CREATE INDEX IF NOT EXISTS idx_cloud_returns_shop_id ON cloud_returns (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_returns_barcode ON cloud_returns (shop_id, barcode);
CREATE INDEX IF NOT EXISTS idx_cloud_returns_date ON cloud_returns (shop_id, date);
CREATE INDEX IF NOT EXISTS idx_cloud_returns_updated_at ON cloud_returns (shop_id, created_at DESC);

-- cloud_expenses
CREATE INDEX IF NOT EXISTS idx_cloud_expenses_shop_id ON cloud_expenses (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_expenses_date ON cloud_expenses (shop_id, date);
CREATE INDEX IF NOT EXISTS idx_cloud_expenses_category_id ON cloud_expenses (category_id);

-- cloud_expense_categories
CREATE INDEX IF NOT EXISTS idx_cloud_exp_categories_shop_id ON cloud_expense_categories (shop_id);

-- cloud_invoices
CREATE INDEX IF NOT EXISTS idx_cloud_invoices_shop_id ON cloud_invoices (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_invoices_customer_id ON cloud_invoices (customer_id);
CREATE INDEX IF NOT EXISTS idx_cloud_invoices_date ON cloud_invoices (shop_id, date);

-- cloud_inventory_count
CREATE INDEX IF NOT EXISTS idx_cloud_inv_count_shop_id ON cloud_inventory_count (shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_inv_count_product_id ON cloud_inventory_count (product_id);

-- ============================================================================
-- 3. RLS - SELECT-only policies on all Phase G tables
-- ============================================================================

ALTER TABLE cloud_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_products ON cloud_products
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_products.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_customers ON cloud_customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_customers.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_sales ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_sales ON cloud_sales
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_sales.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_returns ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_returns ON cloud_returns
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_returns.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_expenses ON cloud_expenses
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_expenses.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_expense_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_expense_categories ON cloud_expense_categories
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_expense_categories.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_invoices ON cloud_invoices
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_invoices.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_inventory_count ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_inventory_count ON cloud_inventory_count
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_inventory_count.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

ALTER TABLE cloud_shop_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY shop_isolation_shop_settings ON cloud_shop_settings
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_shop_settings.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- ============================================================================
-- 4. SIMPLE CRUD SECURITY DEFINER FUNCTIONS
-- ============================================================================

-- 4.1 create_cloud_product
CREATE OR REPLACE FUNCTION create_cloud_product(
  p_shop_id UUID,
  p_name TEXT,
  p_barcode TEXT,
  p_opening_quantity INTEGER DEFAULT 0,
  p_cost_price NUMERIC(12,2) DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product_id UUID;
  v_current_qty INTEGER;
  v_total_cost NUMERIC(14,2);
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Product name is required';
  END IF;
  IF p_barcode IS NULL OR trim(p_barcode) = '' THEN
    RAISE EXCEPTION 'Barcode is required';
  END IF;
  IF p_opening_quantity < 0 THEN
    RAISE EXCEPTION 'Cannot be negative';
  END IF;
  IF p_cost_price < 0 THEN
    RAISE EXCEPTION 'Cost price must be >= 0';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_products
    WHERE shop_id = p_shop_id AND barcode = trim(p_barcode) AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Barcode already exists in this shop';
  END IF;

  v_current_qty := p_opening_quantity;
  v_total_cost := v_current_qty * p_cost_price;

  INSERT INTO cloud_products (
    shop_id, name, barcode, opening_quantity,
    sold_quantity, returned_quantity, current_quantity,
    cost_price, total_inventory_cost, inventory_adjustment
  ) VALUES (
    p_shop_id, trim(p_name), trim(p_barcode), p_opening_quantity,
    0, 0, v_current_qty,
    p_cost_price, v_total_cost, 0
  ) RETURNING id INTO v_product_id;

  RETURN v_product_id;
END;
$$;

-- 4.2 update_cloud_product
CREATE OR REPLACE FUNCTION update_cloud_product(
  p_shop_id UUID,
  p_product_id UUID,
  p_name TEXT DEFAULT NULL,
  p_barcode TEXT DEFAULT NULL,
  p_opening_quantity INTEGER DEFAULT NULL,
  p_cost_price NUMERIC(12,2) DEFAULT NULL,
  p_sold_quantity INTEGER DEFAULT NULL,
  p_returned_quantity INTEGER DEFAULT NULL,
  p_inventory_adjustment INTEGER DEFAULT NULL
)
RETURNS BOOLEAN
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
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  SELECT * INTO v_existing
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Product not found';
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

  IF v_new_opening < 0 OR v_new_sold < 0 OR v_new_returned < 0 THEN
    RAISE EXCEPTION 'Cannot be negative';
  END IF;
  IF v_new_cost < 0 THEN
    RAISE EXCEPTION 'Cost price must be >= 0';
  END IF;

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
    updated_at = now()
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.3 delete_cloud_product
CREATE OR REPLACE FUNCTION delete_cloud_product(
  p_shop_id UUID,
  p_product_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.delete');

  SELECT * INTO v_product
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_sales
    WHERE shop_id = p_shop_id AND barcode = v_product.barcode AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot delete product with sales history';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_returns
    WHERE shop_id = p_shop_id AND barcode = v_product.barcode AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot delete product with return history';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_inventory_count
    WHERE product_id = p_product_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot delete product with stocktake records';
  END IF;

  UPDATE cloud_products SET deleted_at = now(), updated_at = now()
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.4 create_cloud_customer
CREATE OR REPLACE FUNCTION create_cloud_customer(
  p_shop_id UUID,
  p_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT true,
  p_is_system BOOLEAN DEFAULT false
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

  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Customer name is required';
  END IF;

  INSERT INTO cloud_customers (
    shop_id, name, phone, address, notes, is_active, is_system
  ) VALUES (
    p_shop_id, trim(p_name), p_phone, p_address, p_notes, p_is_active, p_is_system
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- 4.5 update_cloud_customer
CREATE OR REPLACE FUNCTION update_cloud_customer(
  p_shop_id UUID,
  p_customer_id UUID,
  p_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing RECORD;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  SELECT * INTO v_existing
  FROM cloud_customers
  WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  IF p_name IS NOT NULL AND trim(p_name) = '' THEN
    RAISE EXCEPTION 'Customer name is required';
  END IF;

  UPDATE cloud_customers SET
    name = COALESCE(trim(p_name), name),
    phone = COALESCE(p_phone, phone),
    address = COALESCE(p_address, address),
    notes = COALESCE(p_notes, notes),
    is_active = COALESCE(p_is_active, is_active),
    updated_at = now()
  WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.6 delete_cloud_customer
CREATE OR REPLACE FUNCTION delete_cloud_customer(
  p_shop_id UUID,
  p_customer_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'inventory.edit');

  IF NOT EXISTS (
    SELECT 1 FROM cloud_customers
    WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  UPDATE cloud_customers SET deleted_at = now(), updated_at = now()
  WHERE id = p_customer_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.7 create_cloud_expense_category
CREATE OR REPLACE FUNCTION create_cloud_expense_category(
  p_shop_id UUID,
  p_name TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.create');

  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Category name is required';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_expense_categories
    WHERE shop_id = p_shop_id AND name = trim(p_name) AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Category already exists';
  END IF;

  INSERT INTO cloud_expense_categories (shop_id, name)
  VALUES (p_shop_id, trim(p_name))
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- 4.8 delete_cloud_expense_category
CREATE OR REPLACE FUNCTION delete_cloud_expense_category(
  p_shop_id UUID,
  p_category_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_category RECORD;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.delete');

  SELECT * INTO v_category
  FROM cloud_expense_categories
  WHERE id = p_category_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_category IS NULL THEN
    RAISE EXCEPTION 'Category not found';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_expenses
    WHERE category_id = p_category_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot delete category with expenses';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cloud_expenses
    WHERE shop_id = p_shop_id AND category_name = v_category.name AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot delete category with expenses';
  END IF;

  UPDATE cloud_expense_categories SET deleted_at = now()
  WHERE id = p_category_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.9 create_cloud_expense
CREATE OR REPLACE FUNCTION create_cloud_expense(
  p_shop_id UUID,
  p_date TIMESTAMPTZ,
  p_description TEXT,
  p_amount NUMERIC(12,2),
  p_category_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_cat_name TEXT := NULL;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.create');

  IF p_description IS NULL OR trim(p_description) = '' THEN
    RAISE EXCEPTION 'Description is required';
  END IF;
  IF p_amount < 0 THEN
    RAISE EXCEPTION 'Cannot be negative';
  END IF;

  IF p_category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM cloud_expense_categories
      WHERE id = p_category_id AND shop_id = p_shop_id AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Category not found';
    END IF;
    SELECT name INTO v_cat_name FROM cloud_expense_categories WHERE id = p_category_id;
  END IF;

  INSERT INTO cloud_expenses (shop_id, date, description, amount, category_id, category_name)
  VALUES (p_shop_id, p_date, trim(p_description), p_amount, p_category_id, v_cat_name)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- 4.10 update_cloud_expense
CREATE OR REPLACE FUNCTION update_cloud_expense(
  p_shop_id UUID,
  p_expense_id UUID,
  p_date TIMESTAMPTZ DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_amount NUMERIC(12,2) DEFAULT NULL,
  p_category_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing RECORD;
  v_new_cat_id UUID;
  v_new_cat_name TEXT;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.create');

  SELECT * INTO v_existing
  FROM cloud_expenses
  WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_existing IS NULL THEN
    RAISE EXCEPTION 'Expense not found';
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

  UPDATE cloud_expenses SET
    date = COALESCE(p_date, date),
    description = COALESCE(trim(p_description), description),
    amount = COALESCE(p_amount, amount),
    category_id = v_new_cat_id,
    category_name = v_new_cat_name
  WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 4.11 delete_cloud_expense
CREATE OR REPLACE FUNCTION delete_cloud_expense(
  p_shop_id UUID,
  p_expense_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'expenses.delete');

  IF NOT EXISTS (
    SELECT 1 FROM cloud_expenses
    WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Expense not found';
  END IF;

  UPDATE cloud_expenses SET deleted_at = now()
  WHERE id = p_expense_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- ============================================================================
-- 5. ATOMIC COMPOUND SECURITY DEFINER FUNCTIONS
-- ============================================================================

-- 5.1 create_cloud_sale_with_stock
CREATE OR REPLACE FUNCTION create_cloud_sale_with_stock(
  p_shop_id UUID,
  p_barcode TEXT,
  p_quantity INTEGER,
  p_sale_price NUMERIC(12,2),
  p_date TIMESTAMPTZ,
  p_invoice_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_sale_id UUID;
  v_total_sale NUMERIC(14,2);
  v_cogs NUMERIC(14,2);
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'sales.create');

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;
  IF p_sale_price <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = p_barcode AND deleted_at IS NULL;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF v_product.current_quantity < p_quantity THEN
    RAISE EXCEPTION 'Insufficient stock: available %, requested %',
      v_product.current_quantity, p_quantity;
  END IF;

  v_total_sale := p_quantity * p_sale_price;
  v_cogs := p_quantity * v_product.cost_price;

  INSERT INTO cloud_sales (
    shop_id, invoice_id, date, product_name, barcode,
    quantity, sale_price, total_sale_value, cost_price, cogs
  ) VALUES (
    p_shop_id, p_invoice_id, p_date, v_product.name, p_barcode,
    p_quantity, p_sale_price, v_total_sale, v_product.cost_price, v_cogs
  ) RETURNING id INTO v_sale_id;

  UPDATE cloud_products SET
    sold_quantity = sold_quantity + p_quantity,
    current_quantity = opening_quantity - (sold_quantity + p_quantity) + returned_quantity + inventory_adjustment,
    total_inventory_cost = (opening_quantity - (sold_quantity + p_quantity) + returned_quantity + inventory_adjustment) * cost_price,
    updated_at = now()
  WHERE id = v_product.id
    AND current_quantity >= p_quantity
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Concurrent modification detected, please retry';
  END IF;

  RETURN v_sale_id;
END;
$$;

-- 5.2 delete_cloud_sale_with_revert
CREATE OR REPLACE FUNCTION delete_cloud_sale_with_revert(
  p_shop_id UUID,
  p_sale_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sale RECORD;
  v_product RECORD;
  v_has_other_sales BOOLEAN;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'sales.delete');

  SELECT * INTO v_sale
  FROM cloud_sales
  WHERE id = p_sale_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_sale IS NULL THEN
    RAISE EXCEPTION 'Sale not found';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = v_sale.barcode AND deleted_at IS NULL;

  IF v_product IS NOT NULL THEN
    UPDATE cloud_products SET
      sold_quantity = sold_quantity - v_sale.quantity,
      current_quantity = opening_quantity - (sold_quantity - v_sale.quantity) + returned_quantity + inventory_adjustment,
      total_inventory_cost = (opening_quantity - (sold_quantity - v_sale.quantity) + returned_quantity + inventory_adjustment) * cost_price,
      updated_at = now()
    WHERE id = v_product.id AND deleted_at IS NULL;
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

  RETURN FOUND;
END;
$$;

-- 5.3 create_cloud_return_with_stock
CREATE OR REPLACE FUNCTION create_cloud_return_with_stock(
  p_shop_id UUID,
  p_barcode TEXT,
  p_quantity INTEGER,
  p_sale_price NUMERIC(12,2),
  p_date TIMESTAMPTZ
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_return_id UUID;
  v_total_return NUMERIC(14,2);
  v_returned_cogs NUMERIC(14,2);
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'returns.create');

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;
  IF p_sale_price <= 0 THEN
    RAISE EXCEPTION 'Must be > 0';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = p_barcode AND deleted_at IS NULL;

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
    current_quantity = opening_quantity - sold_quantity + (returned_quantity + p_quantity) + inventory_adjustment,
    total_inventory_cost = (opening_quantity - sold_quantity + (returned_quantity + p_quantity) + inventory_adjustment) * cost_price,
    updated_at = now()
  WHERE id = v_product.id AND deleted_at IS NULL;

  RETURN v_return_id;
END;
$$;

-- 5.4 delete_cloud_return_with_revert
CREATE OR REPLACE FUNCTION delete_cloud_return_with_revert(
  p_shop_id UUID,
  p_return_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_return RECORD;
  v_product RECORD;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'returns.delete');

  SELECT * INTO v_return
  FROM cloud_returns
  WHERE id = p_return_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_return IS NULL THEN
    RAISE EXCEPTION 'Return not found';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE shop_id = p_shop_id AND barcode = v_return.barcode AND deleted_at IS NULL;

  IF v_product IS NOT NULL THEN
    UPDATE cloud_products SET
      returned_quantity = returned_quantity - v_return.quantity,
      current_quantity = opening_quantity - sold_quantity + (returned_quantity - v_return.quantity) + inventory_adjustment,
      total_inventory_cost = (opening_quantity - sold_quantity + (returned_quantity - v_return.quantity) + inventory_adjustment) * cost_price,
      updated_at = now()
    WHERE id = v_product.id AND deleted_at IS NULL;
  END IF;

  UPDATE cloud_returns SET deleted_at = now()
  WHERE id = p_return_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  RETURN FOUND;
END;
$$;

-- 5.5 create_cloud_invoice_with_items
CREATE OR REPLACE FUNCTION create_cloud_invoice_with_items(
  p_shop_id UUID,
  p_customer_name TEXT,
  p_customer_id UUID DEFAULT NULL,
  p_payment_method TEXT,
  p_date TIMESTAMPTZ,
  p_sale_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invoice_id UUID;
  v_invoice_number TEXT;
  v_max_num INTEGER;
  v_item JSONB;
  v_item_sale_id UUID;
  v_total_amount NUMERIC(14,2) := 0;
  v_total_items INTEGER := 0;
BEGIN
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

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_sale_items)
  LOOP
    SELECT create_cloud_sale_with_stock(
      p_shop_id,
      (v_item->>'barcode')::TEXT,
      (v_item->>'quantity')::INTEGER,
      (v_item->>'sale_price')::NUMERIC,
      p_date,
      v_invoice_id
    ) INTO v_item_sale_id;

    v_total_amount := v_total_amount + ((v_item->>'quantity')::INTEGER * (v_item->>'sale_price')::NUMERIC);
    v_total_items := v_total_items + (v_item->>'quantity')::INTEGER;
  END LOOP;

  UPDATE cloud_invoices SET
    total_amount = v_total_amount,
    total_items = v_total_items
  WHERE id = v_invoice_id;

  RETURN v_invoice_id;
END;
$$;

-- 5.6 save_cloud_inventory_count
CREATE OR REPLACE FUNCTION save_cloud_inventory_count(
  p_shop_id UUID,
  p_product_id UUID,
  p_actual_quantity INTEGER,
  p_notes TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product RECORD;
  v_count_id UUID;
  v_adjustment INTEGER;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'stocktake.view');

  IF p_actual_quantity < 0 THEN
    RAISE EXCEPTION 'Cannot be negative';
  END IF;

  SELECT * INTO v_product
  FROM cloud_products
  WHERE id = p_product_id AND shop_id = p_shop_id AND deleted_at IS NULL;

  IF v_product IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  INSERT INTO cloud_inventory_count (shop_id, product_id, actual_quantity, notes, count_date)
  VALUES (p_shop_id, p_product_id, p_actual_quantity, p_notes, now())
  RETURNING id INTO v_count_id;

  v_adjustment := p_actual_quantity - v_product.current_quantity;

  UPDATE cloud_products SET
    inventory_adjustment = inventory_adjustment + v_adjustment,
    current_quantity = opening_quantity - sold_quantity + returned_quantity + (inventory_adjustment + v_adjustment),
    total_inventory_cost = (opening_quantity - sold_quantity + returned_quantity + (inventory_adjustment + v_adjustment)) * cost_price,
    updated_at = now()
  WHERE id = p_product_id AND deleted_at IS NULL;

  RETURN v_count_id;
END;
$$;

-- 5.7 get_cloud_shop_settings
CREATE OR REPLACE FUNCTION get_cloud_shop_settings(
  p_shop_id UUID
)
RETURNS TABLE (
  setting_key TEXT,
  setting_value TEXT,
  updated_at TIMESTAMPTZ,
  updated_by UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  RETURN QUERY
  SELECT css.setting_key, css.setting_value, css.updated_at, css.updated_by
  FROM cloud_shop_settings css
  WHERE css.shop_id = p_shop_id;
END;
$$;

-- 5.8 update_cloud_shop_setting
CREATE OR REPLACE FUNCTION update_cloud_shop_setting(
  p_shop_id UUID,
  p_key TEXT,
  p_value TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  IF p_key IS NULL OR trim(p_key) = '' THEN
    RAISE EXCEPTION 'Setting key is required';
  END IF;

  INSERT INTO cloud_shop_settings (shop_id, setting_key, setting_value, updated_at, updated_by)
  VALUES (p_shop_id, p_key, p_value, now(), v_caller)
  ON CONFLICT (shop_id, setting_key) DO UPDATE SET
    setting_value = p_value,
    updated_at = now(),
    updated_by = v_caller;

  RETURN true;
END;
$$;

-- ============================================================================
-- 6. GRANT / REVOKE
-- ============================================================================

-- Grant execute on all Phase G functions to authenticated role
GRANT EXECUTE ON FUNCTION create_cloud_product(UUID, TEXT, TEXT, INTEGER, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cloud_product(UUID, UUID, TEXT, TEXT, INTEGER, NUMERIC, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_product(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_customer(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cloud_customer(UUID, UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_customer(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_expense_category(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_expense_category(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_expense(UUID, TIMESTAMPTZ, TEXT, NUMERIC, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cloud_expense(UUID, UUID, TIMESTAMPTZ, TEXT, NUMERIC, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_expense(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_sale_with_stock(UUID, TEXT, INTEGER, NUMERIC, TIMESTAMPTZ, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_sale_with_revert(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_return_with_stock(UUID, TEXT, INTEGER, NUMERIC, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_cloud_return_with_revert(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_invoice_with_items(UUID, TEXT, UUID, TEXT, TIMESTAMPTZ, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION save_cloud_inventory_count(UUID, UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cloud_shop_settings(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cloud_shop_setting(UUID, TEXT, TEXT) TO authenticated;

-- Revoke direct table access from authenticated role
REVOKE ALL ON cloud_products FROM authenticated;
REVOKE ALL ON cloud_customers FROM authenticated;
REVOKE ALL ON cloud_sales FROM authenticated;
REVOKE ALL ON cloud_returns FROM authenticated;
REVOKE ALL ON cloud_expenses FROM authenticated;
REVOKE ALL ON cloud_expense_categories FROM authenticated;
REVOKE ALL ON cloud_invoices FROM authenticated;
REVOKE ALL ON cloud_inventory_count FROM authenticated;
REVOKE ALL ON cloud_shop_settings FROM authenticated;
