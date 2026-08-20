import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/models/cloud/cloud_customer.dart';
import 'package:muaman_store/models/cloud/cloud_expense.dart';
import 'package:muaman_store/models/cloud/cloud_inventory_count.dart';
import 'package:muaman_store/models/cloud/cloud_invoice.dart';
import 'package:muaman_store/models/cloud/cloud_product.dart';
import 'package:muaman_store/models/cloud/cloud_return.dart';
import 'package:muaman_store/models/cloud/cloud_sale.dart';
import 'package:muaman_store/models/cloud/cloud_shop_setting.dart';

void main() {
  group('CloudProduct DTO', () {
    test('D-01: fromJson/toJson round-trip preserves all fields', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'shop_id': '660e8400-e29b-41d4-a716-446655440001',
        'name': 'Test Product',
        'barcode': 'ABC-123',
        'opening_quantity': 100,
        'sold_quantity': 20,
        'returned_quantity': 5,
        'current_quantity': 85,
        'cost_price': 19.99,
        'total_inventory_cost': 1699.15,
        'inventory_adjustment': 0,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T12:00:00Z',
        'deleted_at': null,
      };
      final product = CloudProduct.fromJson(json);
      expect(product.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(product.shopId, '660e8400-e29b-41d4-a716-446655440001');
      expect(product.name, 'Test Product');
      expect(product.barcode, 'ABC-123');
      expect(product.openingQuantity, 100);
      expect(product.soldQuantity, 20);
      expect(product.returnedQuantity, 5);
      expect(product.currentQuantity, 85);
      expect(product.costPrice, 19.99);
      expect(product.deletedAt, isNull);

      final roundTrip = product.toJson();
      expect(roundTrip['name'], 'Test Product');
      expect(roundTrip['cost_price'], 19.99);
    });

    test('computedCurrentQuantity matches formula', () {
      final product = CloudProduct.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'name': 'P',
        'barcode': 'B',
        'opening_quantity': 100,
        'sold_quantity': 30,
        'returned_quantity': 10,
        'current_quantity': 80,
        'cost_price': 5.0,
        'total_inventory_cost': 400.0,
        'inventory_adjustment': 0,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
      });
      expect(product.computedCurrentQuantity, 80);
      expect(product.computedTotalCost, 400.0);
    });
  });

  group('CloudCustomer DTO', () {
    test('fromJson handles nullable fields', () {
      final customer = CloudCustomer.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'name': 'Customer',
        'phone': null,
        'address': null,
        'notes': null,
        'is_active': true,
        'is_system': false,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
      });
      expect(customer.phone, isNull);
      expect(customer.address, isNull);
      expect(customer.isActive, true);
      expect(customer.isSystem, false);
    });
  });

  group('CloudSale DTO', () {
    test('fromJson handles nullable invoice_id', () {
      final sale = CloudSale.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'invoice_id': null,
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'Product',
        'barcode': 'BC',
        'quantity': 5,
        'sale_price': 10.0,
        'total_sale_value': 50.0,
        'cost_price': 7.0,
        'cogs': 35.0,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(sale.invoiceId, isNull);
      expect(sale.quantity, 5);
      expect(sale.totalSaleValue, 50.0);
    });
  });

  group('CloudInvoice DTO', () {
    test('fromJson maps all fields', () {
      final invoice = CloudInvoice.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'invoice_number': 'INV-00000001',
        'date': '2026-08-20T10:00:00Z',
        'customer_name': 'Customer',
        'customer_id': 'cust-id',
        'payment_method': 'cash',
        'total_amount': 100.0,
        'total_items': 3,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(invoice.invoiceNumber, 'INV-00000001');
      expect(invoice.customerId, 'cust-id');
      expect(invoice.totalAmount, 100.0);
    });
  });

  group('CloudShopSetting DTO', () {
    test('composite key fields are correct', () {
      final setting = CloudShopSetting.fromJson({
        'shop_id': 'sid',
        'setting_key': 'shopProfile.shopName',
        'setting_value': 'My Shop',
        'updated_at': '2026-08-20T10:00:00Z',
        'updated_by': null,
      });
      expect(setting.shopId, 'sid');
      expect(setting.settingKey, 'shopProfile.shopName');
      expect(setting.settingValue, 'My Shop');
      expect(setting.updatedBy, isNull);
    });
  });

  group('CloudReturn DTO', () {
    test('fromJson handles all fields', () {
      final ret = CloudReturn.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'Product',
        'barcode': 'BC',
        'quantity': 2,
        'sale_price': 10.0,
        'total_return_value': 20.0,
        'cost_price': 7.0,
        'returned_cogs': 14.0,
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(ret.quantity, 2);
      expect(ret.returnedCogs, 14.0);
    });
  });

  group('CloudExpense DTO', () {
    test('fromJson handles nullable category', () {
      final expense = CloudExpense.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'date': '2026-08-20T10:00:00Z',
        'description': 'Rental',
        'amount': 500.0,
        'category_name': 'Rent',
        'category_id': 'cat-id',
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(expense.categoryName, 'Rent');
      expect(expense.categoryId, 'cat-id');
    });
  });

  group('CloudInventoryCount DTO', () {
    test('fromJson handles all fields', () {
      final count = CloudInventoryCount.fromJson({
        'id': 'id',
        'shop_id': 'sid',
        'product_id': 'pid',
        'actual_quantity': 50,
        'notes': 'Q4 count',
        'count_date': '2026-08-20T10:00:00Z',
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(count.productId, 'pid');
      expect(count.actualQuantity, 50);
      expect(count.notes, 'Q4 count');
    });
  });

  group('CloudDataException', () {
    test('maps 401 to unauthenticated', () {
      final e = CloudDataException.fromPostgrest('auth required', 401);
      expect(e.type, CloudDataErrorType.unauthenticated);
      expect(e.httpStatus, 401);
    });

    test('maps 403 with permission text to permissionDenied', () {
      final e = CloudDataException.fromPostgrest(
          'Permission denied: inventory.edit', 403);
      expect(e.type, CloudDataErrorType.permissionDenied);
    });

    test('maps insufficient stock text', () {
      final e = CloudDataException.fromPostgrest(
          'Insufficient stock: available 5, requested 10', 400);
      expect(e.type, CloudDataErrorType.insufficientStock);
    });

    test('maps not found text', () {
      final e = CloudDataException.fromPostgrest('Product not found', 404);
      expect(e.type, CloudDataErrorType.notFound);
    });

    test('maps unique constraint text to conflict', () {
      final e = CloudDataException.fromPostgrest(
          'duplicate key value violates unique constraint', 409);
      expect(e.type, CloudDataErrorType.conflict);
    });

    test('maps license required text', () {
      final e =
          CloudDataException.fromPostgrest('Active license required', 403);
      expect(e.type, CloudDataErrorType.licenseRequired);
    });

    test('maps membership inactive text', () {
      final e =
          CloudDataException.fromPostgrest('Membership is not active', 403);
      expect(e.type, CloudDataErrorType.membershipInactive);
    });

    test('maps not member text', () {
      final e =
          CloudDataException.fromPostgrest('Not a member of this shop', 403);
      expect(e.type, CloudDataErrorType.notMember);
    });

    test('maps 503 to networkError', () {
      final e = CloudDataException.fromPostgrest('Connection refused', 503);
      expect(e.type, CloudDataErrorType.networkError);
    });

    test('maps null status to serverError', () {
      final e = CloudDataException.fromPostgrest('Internal error', null);
      expect(e.type, CloudDataErrorType.serverError);
    });
  });
}
