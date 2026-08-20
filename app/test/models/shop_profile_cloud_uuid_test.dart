import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/shop_profile.dart';
import 'package:muaman_store/services/shop_profile_repository.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  group('ShopProfile cloudUuid', () {
    test('defaultProfile has null cloudUuid', () {
      final profile = ShopProfile.defaultProfile();
      expect(profile.cloudUuid, isNull);
    });

    test('cloudUuid is included in constructor', () {
      const profile = ShopProfile(
        shopName: 'متجر',
        cloudUuid: 'abc-123-uuid',
      );
      expect(profile.cloudUuid, 'abc-123-uuid');
    });

    test('copyWith updates cloudUuid', () {
      const base = ShopProfile(shopName: 'متجر');
      final withUuid = base.copyWith(cloudUuid: 'uuid-1');
      expect(withUuid.cloudUuid, 'uuid-1');
      expect(withUuid.shopName, 'متجر');

      final withNull = base.copyWith(cloudUuid: 'uuid-1');
      final resetUuid = withNull.copyWith();
      expect(resetUuid.cloudUuid, 'uuid-1');
    });

    test('equality includes cloudUuid', () {
      const a = ShopProfile(shopName: 'متجر', cloudUuid: 'uuid-1');
      const b = ShopProfile(shopName: 'متجر', cloudUuid: 'uuid-1');
      const c = ShopProfile(shopName: 'متجر', cloudUuid: 'uuid-2');
      const d = ShopProfile(shopName: 'متجر');

      expect(a, b);
      expect(a == c, false);
      expect(a == d, false);
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes cloudUuid', () {
      const profile = ShopProfile(shopName: 'متجر', cloudUuid: 'test-uuid');
      expect(profile.toString(), contains('cloudUuid: test-uuid'));
    });

    test('two profiles with same fields but different cloudUuid are not equal',
        () {
      const a = ShopProfile(
        shopName: 'متجر',
        phone: '0111',
        cloudUuid: 'uuid-a',
      );
      const b = ShopProfile(
        shopName: 'متجر',
        phone: '0111',
        cloudUuid: 'uuid-b',
      );
      expect(a == b, false);
    });
  });

  group('ShopProfileRepository cloudUuid persistence', () {
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

    test('default profile loads null cloudUuid', () async {
      final profile = await repository.load();
      expect(profile.cloudUuid, isNull);
    });

    test('save and load round-trip preserves cloudUuid', () async {
      const profile = ShopProfile(
        shopName: 'متجر النور',
        cloudUuid: '550e8400-e29b-41d4-a716-446655440000',
      );
      await repository.save(profile);

      final loaded = await repository.load();
      expect(loaded.cloudUuid, '550e8400-e29b-41d4-a716-446655440000');
      expect(loaded.shopName, 'متجر النور');
    });

    test('save and load round-trip with null cloudUuid', () async {
      const profile = ShopProfile(shopName: 'متجر بدون سحابي');
      await repository.save(profile);

      final loaded = await repository.load();
      expect(loaded.cloudUuid, isNull);
    });

    test('updating cloudUuid preserves other fields', () async {
      const original = ShopProfile(
        shopName: 'متجر النور',
        phone: '0111',
        address: 'شارع 10',
      );
      await repository.save(original);

      final updated = original.copyWith(cloudUuid: 'new-uuid');
      await repository.save(updated);

      final loaded = await repository.load();
      expect(loaded.cloudUuid, 'new-uuid');
      expect(loaded.shopName, 'متجر النور');
      expect(loaded.phone, '0111');
      expect(loaded.address, 'شارع 10');
    });

    test('fresh repository sees previously saved cloudUuid', () async {
      await repository.save(const ShopProfile(
        shopName: 'متجر',
        cloudUuid: 'persist-uuid',
      ));

      final freshRepository = ShopProfileRepository();
      final loaded = await freshRepository.load();
      expect(loaded.cloudUuid, 'persist-uuid');
    });
  });
}
