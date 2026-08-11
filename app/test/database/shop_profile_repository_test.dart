import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/shop_profile.dart';
import 'package:muaman_store/services/shop_profile_repository.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late ShopProfileRepository repository;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
    repository = ShopProfileRepository();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('ShopProfileRepository persistence', () {
    test('default profile when no config exists', () async {
      final profile = await repository.load();
      expect(profile.shopName, ShopProfile.defaultShopName);
      expect(profile.ownerOrManagerName, '');
      expect(profile.phone, '');
      expect(profile.address, '');
      expect(profile.logoPath, '');
    });

    test('save then read returns the persisted profile', () async {
      const profile = ShopProfile(
        shopName: 'متجر النور',
        ownerOrManagerName: 'أحمد',
        phone: '+201000000000',
        address: 'شارع 10، القاهرة',
        logoPath: 'C:\\managed\\shop_logo.png',
      );
      await repository.save(profile);

      final loaded = await repository.load();
      expect(loaded, profile);
    });

    test('a fresh repository instance sees previously saved data', () async {
      await repository.save(const ShopProfile(shopName: 'متجر النور'));

      final freshRepository = ShopProfileRepository();
      final loaded = await freshRepository.load();
      expect(loaded.shopName, 'متجر النور');
    });

    test('update of an existing value replaces it', () async {
      await repository.save(const ShopProfile(
          shopName: 'متجر قديم', phone: '0111', address: 'عنوان قديم'));
      await repository.save(const ShopProfile(
          shopName: 'متجر جديد', phone: '0222', address: 'عنوان جديد'));

      final loaded = await repository.load();
      expect(loaded.shopName, 'متجر جديد');
      expect(loaded.phone, '0222');
      expect(loaded.address, 'عنوان جديد');
    });

    test('values are trimmed on save', () async {
      await repository
          .save(const ShopProfile(shopName: '  متجر النور  ', phone: ' 0111 '));
      final loaded = await repository.load();
      expect(loaded.shopName, 'متجر النور');
      expect(loaded.phone, '0111');
    });

    test('blank shopName falls back to the migration default on load',
        () async {
      await testDb.insert('app_settings',
          {'key': ShopProfileRepository.keyShopName, 'value': '  '});
      final loaded = await repository.load();
      expect(loaded.shopName, ShopProfile.defaultShopName);
    });
  });

  group('ShopProfileRepository migration / data safety', () {
    test(
        'an existing database with business data and no shop identity '
        'settings loads the safe default without touching business rows',
        () async {
      await testDb.insert('products', {
        'name': 'منتج تاريخي',
        'barcode': 'BAR-001',
        'openingQuantity': 10,
        'soldQuantity': 2,
        'currentQuantity': 8,
        'costPrice': 50,
        'totalInventoryCost': 400,
        'inventoryAdjustment': 0,
      });
      await testDb.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'productName': 'منتج تاريخي',
        'barcode': 'BAR-001',
        'quantity': 2,
        'salePrice': 100,
        'totalSaleValue': 200,
        'costPrice': 50,
        'cogs': 100,
      });
      await testDb.insert('expenses', {
        'date': DateTime.now().toIso8601String(),
        'description': 'إيجار',
        'amount': 500,
      });
      await testDb.insert('returns', {
        'date': DateTime.now().toIso8601String(),
        'productName': 'منتج تاريخي',
        'barcode': 'BAR-001',
        'quantity': 1,
        'salePrice': 100,
        'totalReturnValue': 100,
        'costPrice': 50,
        'returnedCogs': 50,
      });

      final profile = await repository.load();
      expect(profile.shopName, ShopProfile.defaultShopName);

      final productCount =
          (await testDb.rawQuery('SELECT COUNT(*) AS c FROM products'))
              .single['c'] as int;
      final saleCount =
          (await testDb.rawQuery('SELECT COUNT(*) AS c FROM sales')).single['c']
              as int;
      final returnCount =
          (await testDb.rawQuery('SELECT COUNT(*) AS c FROM returns'))
              .single['c'] as int;
      final expenseCount =
          (await testDb.rawQuery('SELECT COUNT(*) AS c FROM expenses'))
              .single['c'] as int;
      expect(productCount, 1);
      expect(saleCount, 1);
      expect(returnCount, 1);
      expect(expenseCount, 1);
    });

    test('fresh installation creates the required storage', () async {
      final freshPath =
          'file:muaman_fresh_${DateTime.now().microsecondsSinceEpoch}?mode=memory&cache=shared';
      final freshDb = await databaseFactoryFfiNoIsolate.openDatabase(freshPath);
      await createTestSchema(freshDb);
      final freshRepository = ShopProfileRepository();
      final profile = await freshRepository.load();
      expect(profile.shopName, ShopProfile.defaultShopName);
      await freshDb.close();
    });

    test('missing shop identity config does not crash', () async {
      final profile = await repository.load();
      expect(profile.shopName, ShopProfile.defaultShopName);
      // Re-loading repeatedly stays stable.
      final again = await repository.load();
      expect(again, profile);
    });

    test('saving a profile does not alter business tables', () async {
      await testDb.insert('products', {
        'name': 'منتج',
        'barcode': 'BAR-002',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10,
        'totalInventoryCost': 50,
        'inventoryAdjustment': 0,
      });

      await repository.save(const ShopProfile(
          shopName: 'متجر النور', phone: '0111', address: 'عنوان'));

      final products = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-002']);
      expect(products, hasLength(1));
      expect(products.first['currentQuantity'], 5);
      expect(products.first['name'], 'منتج');
    });
  });
}
