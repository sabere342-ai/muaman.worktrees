import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationContent;

  setUpAll(() {
    final file = File(
        '../supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql');
    migrationContent = file.readAsStringSync();
  });

  group('S-01 to S-09: Cloud tables exist in migration', () {
    test('cloud_products table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_products'));
    });
    test('cloud_customers table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_customers'));
    });
    test('cloud_sales table defined', () {
      expect(
          migrationContent, contains('CREATE TABLE IF NOT EXISTS cloud_sales'));
    });
    test('cloud_returns table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_returns'));
    });
    test('cloud_expenses table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_expenses'));
    });
    test('cloud_expense_categories table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_expense_categories'));
    });
    test('cloud_invoices table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_invoices'));
    });
    test('cloud_inventory_count table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_inventory_count'));
    });
    test('cloud_shop_settings table defined', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_shop_settings'));
    });
  });

  group('S-10: All tables have shop_id UUID NOT NULL', () {
    final tables = [
      'cloud_products',
      'cloud_customers',
      'cloud_sales',
      'cloud_returns',
      'cloud_expenses',
      'cloud_expense_categories',
      'cloud_invoices',
      'cloud_inventory_count',
      'cloud_shop_settings',
    ];
    for (final table in tables) {
      test('$table has shop_id UUID NOT NULL', () {
        expect(migrationContent,
            contains('shop_id UUID NOT NULL REFERENCES shops(id)'));
      });
    }
  });

  group('S-11: All tables have deleted_at TIMESTAMPTZ', () {
    final tables = [
      'cloud_products',
      'cloud_customers',
      'cloud_sales',
      'cloud_returns',
      'cloud_expenses',
      'cloud_expense_categories',
      'cloud_invoices',
      'cloud_inventory_count',
    ];
    for (final table in tables) {
      test('$table has deleted_at', () {
        expect(migrationContent, contains('deleted_at TIMESTAMPTZ'));
      });
    }
  });

  group('S-12: Foreign keys exist', () {
    test('cloud_expenses FK to cloud_expense_categories', () {
      expect(
          migrationContent,
          contains(
              'REFERENCES cloud_expense_categories(id) ON DELETE SET NULL'));
    });
    test('cloud_inventory_count FK to cloud_products', () {
      expect(migrationContent,
          contains('REFERENCES cloud_products(id) ON DELETE RESTRICT'));
    });
    test('cloud_invoices FK to cloud_customers', () {
      expect(migrationContent,
          contains('REFERENCES cloud_customers(id) ON DELETE SET NULL'));
    });
    test('cloud_sales FK to cloud_invoices', () {
      expect(migrationContent,
          contains('REFERENCES cloud_invoices(id) ON DELETE SET NULL'));
    });
  });

  group('S-13: Unique constraints exist', () {
    test('products shop_barcode unique', () {
      expect(migrationContent, contains('UNIQUE (shop_id, barcode)'));
    });
    test('expense_categories shop_name unique', () {
      expect(migrationContent, contains('UNIQUE (shop_id, name)'));
    });
    test('invoices shop_number unique', () {
      expect(migrationContent, contains('UNIQUE (shop_id, invoice_number)'));
    });
  });

  group('S-14: Indexes exist', () {
    final expectedIndexes = [
      'idx_cloud_products_shop_id',
      'idx_cloud_products_updated_at',
      'idx_cloud_customers_shop_id',
      'idx_cloud_customers_name',
      'idx_cloud_sales_shop_id',
      'idx_cloud_sales_invoice_id',
      'idx_cloud_sales_barcode',
      'idx_cloud_sales_date',
      'idx_cloud_sales_updated_at',
      'idx_cloud_returns_shop_id',
      'idx_cloud_returns_barcode',
      'idx_cloud_returns_date',
      'idx_cloud_returns_updated_at',
      'idx_cloud_expenses_shop_id',
      'idx_cloud_expenses_date',
      'idx_cloud_expenses_category_id',
      'idx_cloud_exp_categories_shop_id',
      'idx_cloud_invoices_shop_id',
      'idx_cloud_invoices_customer_id',
      'idx_cloud_invoices_date',
      'idx_cloud_inv_count_shop_id',
      'idx_cloud_inv_count_product_id',
    ];
    for (final idx in expectedIndexes) {
      test('index $idx exists', () {
        expect(migrationContent, contains('CREATE INDEX IF NOT EXISTS $idx'));
      });
    }
  });

  group('S-15 & S-16: RLS enabled with SELECT policies', () {
    final tables = [
      'cloud_products',
      'cloud_customers',
      'cloud_sales',
      'cloud_returns',
      'cloud_expenses',
      'cloud_expense_categories',
      'cloud_invoices',
      'cloud_inventory_count',
      'cloud_shop_settings',
    ];
    for (final table in tables) {
      test('$table has RLS enabled', () {
        expect(migrationContent,
            contains('ALTER TABLE $table ENABLE ROW LEVEL SECURITY'));
      });
    }
  });

  group('S-17: No INSERT/UPDATE/DELETE RLS policies', () {
    test('no FOR INSERT policies', () {
      expect(migrationContent, isNot(contains('FOR INSERT')));
    });
    test('no FOR UPDATE policies', () {
      expect(migrationContent, isNot(contains('FOR UPDATE')));
    });
    test('no FOR DELETE policies', () {
      expect(migrationContent, isNot(contains('FOR DELETE')));
    });
  });

  group('S-18: All 19 SECURITY DEFINER functions exist', () {
    final functions = [
      'create_cloud_product',
      'update_cloud_product',
      'delete_cloud_product',
      'create_cloud_customer',
      'update_cloud_customer',
      'delete_cloud_customer',
      'create_cloud_expense_category',
      'delete_cloud_expense_category',
      'create_cloud_expense',
      'update_cloud_expense',
      'delete_cloud_expense',
      'create_cloud_sale_with_stock',
      'delete_cloud_sale_with_revert',
      'create_cloud_return_with_stock',
      'delete_cloud_return_with_revert',
      'create_cloud_invoice_with_items',
      'save_cloud_inventory_count',
      'get_cloud_shop_settings',
      'update_cloud_shop_setting',
    ];
    for (final fn in functions) {
      test('function $fn exists as SECURITY DEFINER', () {
        expect(migrationContent, contains('CREATE OR REPLACE FUNCTION $fn'));
        expect(migrationContent, contains('SECURITY DEFINER'));
      });
    }
  });

  group('S-19: Financial columns are NUMERIC', () {
    test('cost_price is NUMERIC(12,2)', () {
      expect(migrationContent, contains('cost_price NUMERIC(12,2)'));
    });
    test('total_inventory_cost is NUMERIC(14,2)', () {
      expect(migrationContent, contains('total_inventory_cost NUMERIC(14,2)'));
    });
    test('sale_price is NUMERIC(12,2)', () {
      expect(migrationContent, contains('sale_price NUMERIC(12,2)'));
    });
    test('total_sale_value is NUMERIC(14,2)', () {
      expect(migrationContent, contains('total_sale_value NUMERIC(14,2)'));
    });
    test('cogs is NUMERIC(14,2)', () {
      expect(migrationContent, contains('cogs NUMERIC(14,2)'));
    });
    test('total_return_value is NUMERIC(14,2)', () {
      expect(migrationContent, contains('total_return_value NUMERIC(14,2)'));
    });
    test('returned_cogs is NUMERIC(14,2)', () {
      expect(migrationContent, contains('returned_cogs NUMERIC(14,2)'));
    });
    test('amount is NUMERIC(12,2)', () {
      expect(migrationContent, contains('amount NUMERIC(12,2)'));
    });
    test('total_amount is NUMERIC(14,2)', () {
      expect(migrationContent, contains('total_amount NUMERIC(14,2)'));
    });
  });

  group('S-20: Barcode uniqueness per shop', () {
    test('cloud_products has UNIQUE(shop_id, barcode)', () {
      expect(
          migrationContent,
          contains(
              'CONSTRAINT uniq_cloud_products_shop_barcode UNIQUE (shop_id, barcode)'));
    });
  });

  group('search_path safety', () {
    test('all functions use SET search_path = public', () {
      final searchPathCount =
          'SET search_path = public'.allMatches(migrationContent).length;
      expect(searchPathCount, 19);
    });
  });

  group('GRANT/REVOKE', () {
    test('GRANT EXECUTE on functions to authenticated', () {
      expect(migrationContent, contains('GRANT EXECUTE ON FUNCTION'));
      expect(migrationContent, contains('TO authenticated'));
    });
    test('REVOKE direct table access from authenticated', () {
      expect(migrationContent,
          contains('REVOKE ALL ON cloud_products FROM authenticated'));
      expect(migrationContent,
          contains('REVOKE ALL ON cloud_customers FROM authenticated'));
    });
  });
}
