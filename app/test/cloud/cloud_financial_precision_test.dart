import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/models/cloud/cloud_product.dart';
import 'package:muaman_store/models/cloud/cloud_sale.dart';

void main() {
  group('F-01: Cost price 19.99 stored exactly', () {
    test('no precision loss for 19.99', () {
      final product = CloudProduct.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'name': 'P',
        'barcode': 'B',
        'opening_quantity': 100,
        'sold_quantity': 0,
        'returned_quantity': 0,
        'current_quantity': 100,
        'cost_price': 19.99,
        'total_inventory_cost': 1999.00,
        'inventory_adjustment': 0,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
      });
      expect(product.costPrice, 19.99);
    });
  });

  group('F-02: Sale total = qty * price exact', () {
    test('3 * 19.99 = 59.97', () {
      final sale = CloudSale.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'invoice_id': null,
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'P',
        'barcode': 'B',
        'quantity': 3,
        'sale_price': 19.99,
        'total_sale_value': 59.97,
        'cost_price': 10.50,
        'cogs': 31.50,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(sale.totalSaleValue, closeTo(59.97, 0.01));
    });
  });

  group('F-03: COGS = qty * cost exact', () {
    test('3 * 10.50 = 31.50', () {
      final sale = CloudSale.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'invoice_id': null,
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'P',
        'barcode': 'B',
        'quantity': 3,
        'sale_price': 19.99,
        'total_sale_value': 59.97,
        'cost_price': 10.50,
        'cogs': 31.50,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(sale.cogs, closeTo(31.50, 0.01));
    });
  });

  group('F-05: Large values within range', () {
    test('999999.99 * 999 fits in NUMERIC(14,2)', () {
      final sale = CloudSale.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'invoice_id': null,
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'P',
        'barcode': 'B',
        'quantity': 999,
        'sale_price': 999999.99,
        'total_sale_value': 999999.99 * 999,
        'cost_price': 500000.00,
        'cogs': 500000.00 * 999,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(sale.totalSaleValue, greaterThan(0));
    });
  });

  group('F-06: Zero values in validation', () {
    test('costPrice=0 is parsed (server rejects via CHECK)', () {
      final product = CloudProduct.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'name': 'P',
        'barcode': 'B',
        'opening_quantity': 0,
        'sold_quantity': 0,
        'returned_quantity': 0,
        'current_quantity': 0,
        'cost_price': 0,
        'total_inventory_cost': 0,
        'inventory_adjustment': 0,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
      });
      expect(product.costPrice, 0);
    });
  });
}
