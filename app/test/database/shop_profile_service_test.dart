import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/shop_profile.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/services/shop_profile_repository.dart';
import 'package:muaman_store/services/shop_profile_service.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late Directory tempLogoDir;
  late ShopProfileRepository repository;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
    tempLogoDir = Directory.systemTemp.createTempSync('shop_profile_logo_test');
    repository = ShopProfileRepository();
  });

  tearDown(() async {
    if (tempLogoDir.existsSync()) {
      tempLogoDir.deleteSync(recursive: true);
    }
    await testDb.close();
  });

  ShopProfileService service() => ShopProfileService(
        repository: repository,
        logoDirectory: tempLogoDir.path,
      );

  File createLogoFile({String name = 'logo.png'}) {
    final file = File('${tempLogoDir.path}\\$name');
    file.writeAsBytesSync([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    ]);
    return file;
  }

  /// Persists an explicit employee configuration that includes the settings
  /// permission, then refreshes the central resolver so the service honors it.
  Future<void> grantSettingsToEmployee() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'role_permissions',
      {
        'role': UserRole.employee.value,
        'permissions': PermissionCatalog.encodeSet({
          AppPermission.canAccessSales,
          AppPermission.canCreateSales,
          AppPermission.canAccessSettings,
        }),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await PermissionResolver.instance.refresh();
  }

  group('ShopProfileService persistence', () {
    test('restart simulation keeps the saved profile', () async {
      final first = service();
      await first.load();
      await first.save(
        const ShopProfile(shopName: 'متجر النور', phone: '0111'),
        actorRole: UserRole.owner,
      );

      final restarted = service();
      await restarted.load();
      expect(restarted.current.shopName, 'متجر النور');
      expect(restarted.current.phone, '0111');
    });

    test('update persists for the next instance', () async {
      final first = service();
      await first.load();
      await first.save(const ShopProfile(shopName: 'الاسم الأول'),
          actorRole: UserRole.owner);
      await first.save(const ShopProfile(shopName: 'الاسم الثاني'),
          actorRole: UserRole.owner);

      final restarted = service();
      await restarted.load();
      expect(restarted.current.shopName, 'الاسم الثاني');
    });

    test('load without any config yields the default and does not crash',
        () async {
      final s = service();
      await s.load();
      expect(s.isLoaded, true);
      expect(s.current.shopName, ShopProfile.defaultShopName);
    });
  });

  group('ShopProfileService logo handling', () {
    test('logo is persisted as a managed copy and survives restart', () async {
      final source = createLogoFile();
      final s = service();
      await s.load();
      await s.save(
        const ShopProfile(shopName: 'متجر النور'),
        actorRole: UserRole.owner,
        logoSourcePath: source.path,
      );

      final managedPath = s.current.logoPath;
      expect(managedPath, isNotEmpty);
      expect(File(managedPath).existsSync(), true);
      expect(managedPath, startsWith(tempLogoDir.path));

      final restarted = service();
      await restarted.load();
      expect(restarted.current.logoPath, managedPath);
      expect(restarted.current.hasLogo, true);
    });

    test('deleted logo file falls back to no logo on load', () async {
      final source = createLogoFile();
      final s = service();
      await s.load();
      await s.save(
        const ShopProfile(shopName: 'متجر النور'),
        actorRole: UserRole.owner,
        logoSourcePath: source.path,
      );
      final managedPath = s.current.logoPath;
      File(managedPath).deleteSync();

      final restarted = service();
      await restarted.load();
      expect(restarted.current.logoPath, '');
      expect(restarted.current.hasLogo, false);
      expect(restarted.current.shopName, 'متجر النور');
    });

    test('nonexistent logo source path throws ArgumentError and no mutation',
        () async {
      final s = service();
      await s.load();
      await expectLater(
        s.save(
          const ShopProfile(shopName: 'متجر النور'),
          actorRole: UserRole.owner,
          logoSourcePath: '${tempLogoDir.path}\\missing.png',
        ),
        throwsA(isA<ArgumentError>()),
      );

      final after = await repository.load();
      expect(after.shopName, ShopProfile.defaultShopName);
      expect(after.logoPath, '');
    });

    test('unsupported logo extension throws ArgumentError without crash',
        () async {
      final bad = File('${tempLogoDir.path}\\logo.txt');
      bad.writeAsBytesSync([1, 2, 3]);
      final s = service();
      await s.load();
      await expectLater(
        s.save(
          const ShopProfile(shopName: 'متجر النور'),
          actorRole: UserRole.owner,
          logoSourcePath: bad.path,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('blank shopName is rejected without mutation', () async {
      final s = service();
      await s.load();
      await expectLater(
        s.save(
          const ShopProfile(shopName: '   '),
          actorRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
      final after = await repository.load();
      expect(after.shopName, ShopProfile.defaultShopName);
    });
  });

  group('ShopProfileService authorization', () {
    test('an authorized actor (owner) can save', () async {
      final s = service();
      await s.load();
      await s.save(const ShopProfile(shopName: 'متجر النور'),
          actorRole: UserRole.owner);
      expect((await repository.load()).shopName, 'متجر النور');
    });

    test('a role without canAccessSettings cannot save', () async {
      final s = service();
      await s.load();
      await expectLater(
        s.save(const ShopProfile(shopName: 'متجر النور'),
            actorRole: UserRole.salesOnly),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('an unauthorized attempt causes no mutation', () async {
      final s = service();
      await s.load();
      await expectLater(
        s.save(
          const ShopProfile(
              shopName: 'اسم غير مصرح', phone: '0111', address: 'عنوان'),
          actorRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      final after = await repository.load();
      expect(after.shopName, ShopProfile.defaultShopName);
      expect(after.phone, '');
      expect(after.address, '');
    });

    test('a null actor is denied', () async {
      final s = service();
      await s.load();
      await expectLater(
        s.save(const ShopProfile(shopName: 'متجر النور')),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test(
        'permission-based (not role-based): employee granted canAccessSettings '
        'can save', () async {
      await grantSettingsToEmployee();
      final s = service();
      await s.load();

      expect(
        PermissionResolver.instance
            .can(UserRole.employee, AppPermission.canAccessSettings),
        true,
      );
      await s.save(const ShopProfile(shopName: 'متجر النور'),
          actorRole: UserRole.employee);
      expect((await repository.load()).shopName, 'متجر النور');
    });
  });
}
