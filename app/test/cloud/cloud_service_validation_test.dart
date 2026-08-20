import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/repositories/cloud/cloud_expense_repository.dart';
import 'package:muaman_store/repositories/cloud/cloud_product_repository.dart';
import 'package:muaman_store/repositories/cloud/cloud_sales_repository.dart';
import 'package:muaman_store/repositories/cloud/cloud_settings_repository.dart';
import 'package:muaman_store/services/cloud/cloud_expense_service.dart';
import 'package:muaman_store/services/cloud/cloud_product_service.dart';
import 'package:muaman_store/services/cloud/cloud_sales_service.dart';
import 'package:muaman_store/services/cloud/cloud_settings_service.dart';

void main() {
  group('CloudProductService validation', () {
    late CloudProductService service;

    setUp(() {
      service = CloudProductService(
          repository: CloudProductRepository(
              client: SupabaseClient('http://dummy', 'dummy')));
    });

    test('rejects empty name', () {
      expect(
        () => service.createProduct('shop', name: '', barcode: 'BC'),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects empty barcode', () {
      expect(
        () => service.createProduct('shop', name: 'Product', barcode: ''),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects negative opening quantity', () {
      expect(
        () => service.createProduct('shop',
            name: 'P', barcode: 'B', openingQuantity: -1),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects negative cost price', () {
      expect(
        () => service.createProduct('shop',
            name: 'P', barcode: 'B', costPrice: -5),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });
  });

  group('CloudSalesService validation', () {
    late CloudSalesService service;

    setUp(() {
      service = CloudSalesService(
          repository: CloudSalesRepository(
              client: SupabaseClient('http://dummy', 'dummy')));
    });

    test('rejects zero quantity', () {
      expect(
        () => service.createSaleWithStock('shop',
            barcode: 'BC', quantity: 0, salePrice: 10, date: DateTime.now()),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects negative sale price', () {
      expect(
        () => service.createSaleWithStock('shop',
            barcode: 'BC', quantity: 1, salePrice: -1, date: DateTime.now()),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects empty barcode', () {
      expect(
        () => service.createSaleWithStock('shop',
            barcode: '', quantity: 1, salePrice: 10, date: DateTime.now()),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });
  });

  group('CloudExpenseService validation', () {
    late CloudExpenseService service;

    setUp(() {
      service = CloudExpenseService(
          repository: CloudExpenseRepository(
              client: SupabaseClient('http://dummy', 'dummy')));
    });

    test('rejects empty description', () {
      expect(
        () => service.createExpense('shop',
            date: DateTime.now(), description: '', amount: 100),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects negative amount', () {
      expect(
        () => service.createExpense('shop',
            date: DateTime.now(), description: 'Rental', amount: -1),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects empty category name', () {
      expect(
        () => service.createCategory('shop', name: ''),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });
  });

  group('CloudSettingsService validation', () {
    late CloudSettingsService service;

    setUp(() {
      service = CloudSettingsService(
          repository: CloudSettingsRepository(
              client: SupabaseClient('http://dummy', 'dummy')));
    });

    test('rejects non-syncable key', () {
      expect(
        () =>
            service.updateSetting('shop', key: 'workbookPath', value: '/path'),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('allows syncable key', () async {
      try {
        await service.updateSetting('shop',
            key: 'shopProfile.shopName', value: 'My Shop');
      } catch (e) {
        expect(e, isNot(isA<CloudDataException>()),
            reason: 'Valid syncable key should not throw CloudDataException');
      }
    });
  });
}
