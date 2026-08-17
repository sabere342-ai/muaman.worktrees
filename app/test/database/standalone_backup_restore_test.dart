import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/services/standalone_backup_service.dart';
import 'package:muaman_store/services/standalone_restore_service.dart';

import '../helpers/test_schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('StandaloneBackupService', () {
    late Database testDb;
    late Directory backupDir;

    setUp(() async {
      testDb = await databaseFactoryFfiNoIsolate
          .openDatabase(inMemoryDatabasePath);
      await createTestSchema(testDb);
      await testDb.execute('PRAGMA user_version = 7');
      await DatabaseHelper.setTestDatabase(testDb);
      backupDir = await Directory.systemTemp.createTemp('backup_test');
    });

    tearDown(() async {
      await testDb.close();
      DatabaseHelper.resetForTest();
      if (backupDir.existsSync()) {
        await backupDir.delete(recursive: true);
      }
    });

    Future<void> seedData() async {
      await testDb.insert('products', {
        'name': 'منتج تجريبي',
        'barcode': 'TEST-001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 50.0,
        'totalInventoryCost': 500.0,
        'inventoryAdjustment': 0,
      });
      await testDb.insert('sales', {
        'date': '2026-08-01T00:00:00.000',
        'productName': 'منتج تجريبي',
        'barcode': 'TEST-001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalSaleValue': 200.0,
        'costPrice': 50.0,
        'cogs': 100.0,
      });
      await testDb.insert('expenses', {
        'date': '2026-08-01T00:00:00.000',
        'description': 'مصروف تجريبي',
        'amount': 25.0,
      });
      await testDb.insert('users', {
        'displayName': 'المالك',
        'username': 'owner',
        'passwordHash': 'dummy:dummy',
        'role': 'owner',
        'isActive': 1,
        'createdAt': '2026-08-01T00:00:00.000',
        'updatedAt': '2026-08-01T00:00:00.000',
      });
      await testDb.insert('app_settings', {
        'key': 'shop_name',
        'value': 'متجر مؤمن',
      });
    }

    test('owner creates backup successfully', () async {
      await seedData();

      final report = await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      expect(report.backupPath, startsWith(backupDir.path));
      expect(report.fileSize, greaterThan(0));
      expect(report.tableCount, greaterThan(0));

      final backupFile = File(report.backupPath);
      expect(backupFile.existsSync(), isTrue);
    });

    test('backup file is valid SQLite with correct data', () async {
      await seedData();

      final report = await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      final backupDb = await databaseFactoryFfiNoIsolate
          .openDatabase(report.backupPath);

      final products = await backupDb.query('products');
      expect(products, hasLength(1));
      expect(products.first['name'], 'منتج تجريبي');

      final sales = await backupDb.query('sales');
      expect(sales, hasLength(1));

      final users = await backupDb.query('users');
      expect(users, hasLength(1));

      final settings = await backupDb.query('app_settings');
      expect(settings, isNotEmpty);

      await backupDb.close();
    });

    test('source database remains intact after backup', () async {
      await seedData();

      await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      final rows = await testDb.query('products');
      expect(rows, hasLength(1));
    });

    test('non-owner is denied', () async {
      await seedData();

      expect(
        () => StandaloneBackupService().createBackup(
          destinationDirectory: backupDir.path,
          actorRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      expect(backupDir.listSync().whereType<File>().toList(), isEmpty);
    });

    test('non-existent directory throws exception', () async {
      await seedData();

      expect(
        () => StandaloneBackupService().createBackup(
          destinationDirectory:
              '${backupDir.path}${Platform.pathSeparator}nonexistent',
          actorRole: UserRole.owner,
        ),
        throwsA(isA<StandaloneBackupException>()),
      );
    });

    test('backup filename starts with muaman_backup_', () async {
      await seedData();

      final report = await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      final filename = File(report.backupPath).uri.pathSegments.last;
      expect(filename, startsWith('muaman_backup_'));
      expect(filename, endsWith('.db'));
    });

    test('multiple backups create distinct files', () async {
      await seedData();

      final report1 = await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      await Future.delayed(const Duration(milliseconds: 1100));

      final report2 = await StandaloneBackupService().createBackup(
        destinationDirectory: backupDir.path,
        actorRole: UserRole.owner,
      );

      expect(report1.backupPath, isNot(equals(report2.backupPath)));
      expect(File(report1.backupPath).existsSync(), isTrue);
      expect(File(report2.backupPath).existsSync(), isTrue);
    });
  });

  group('StandaloneRestoreService', () {
    late Database testDb;
    late Directory restoreDir;
    late Directory preSaveDir;
    late String liveDbPath;
    late String backupFilePath;

    setUp(() async {
      restoreDir = await Directory.systemTemp.createTemp('restore_test');
      preSaveDir = await Directory.systemTemp.createTemp('presave_test');
      liveDbPath =
          '${restoreDir.path}${Platform.pathSeparator}muaman_store.db';

      testDb = await openDatabase(liveDbPath,
          version: 7, onCreate: (db, version) async {
        await createTestSchema(db);
      });
      await testDb.execute('PRAGMA user_version = 7');
      await DatabaseHelper.setTestDatabase(testDb);

      await testDb.insert('products', {
        'name': 'منتج تجريبي',
        'barcode': 'TEST-001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 50.0,
        'totalInventoryCost': 500.0,
        'inventoryAdjustment': 0,
      });
      await testDb.insert('users', {
        'displayName': 'المالك',
        'username': 'owner',
        'passwordHash': 'dummy:dummy',
        'role': 'owner',
        'isActive': 1,
        'createdAt': '2026-08-01T00:00:00.000',
        'updatedAt': '2026-08-01T00:00:00.000',
      });
      await testDb.insert('app_settings', {
        'key': 'shop_name',
        'value': 'متجر مؤمن',
      });

      final backupReport = await StandaloneBackupService().createBackup(
        destinationDirectory: restoreDir.path,
        actorRole: UserRole.owner,
      );
      backupFilePath = backupReport.backupPath;
    });

    tearDown(() async {
      try {
        await testDb.close();
      } catch (_) {}
      DatabaseHelper.resetForTest();
      if (restoreDir.existsSync()) {
        await restoreDir.delete(recursive: true);
      }
      if (preSaveDir.existsSync()) {
        await preSaveDir.delete(recursive: true);
      }
    });

    test('owner restores from backup successfully', () async {
      final report = await StandaloneRestoreService(
        preSaveDirectory: preSaveDir.path,
        databasePathOverride: liveDbPath,
      ).restoreFromBackup(
        backupFilePath: backupFilePath,
        actorRole: UserRole.owner,
      );

      expect(report.restoredFromPath, backupFilePath);
      expect(report.preSaveBackupPath, isNotEmpty);
      expect(File(report.preSaveBackupPath).existsSync(), isTrue);
    });

    test('restore creates pre-save safety backup', () async {
      final report = await StandaloneRestoreService(
        preSaveDirectory: preSaveDir.path,
        databasePathOverride: liveDbPath,
      ).restoreFromBackup(
        backupFilePath: backupFilePath,
        actorRole: UserRole.owner,
      );

      final preSaveFile = File(report.preSaveBackupPath);
      expect(preSaveFile.existsSync(), isTrue);
      expect(preSaveFile.lengthSync(), greaterThan(0));

      final preSaveDb = await databaseFactoryFfiNoIsolate
          .openDatabase(report.preSaveBackupPath);
      final preSaveProducts = await preSaveDb.query('products');
      expect(preSaveProducts, hasLength(1));
      expect(preSaveProducts.first['name'], 'منتج تجريبي');
      await preSaveDb.close();
    });

    test('non-owner is denied', () async {
      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath: backupFilePath,
          actorRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('non-existent file is rejected', () async {
      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath:
              '${restoreDir.path}${Platform.pathSeparator}nonexistent.db',
          actorRole: UserRole.owner,
        ),
        throwsA(isA<RestoreValidationException>()),
      );
    });

    test('empty file is rejected', () async {
      final emptyFile =
          File('${restoreDir.path}${Platform.pathSeparator}empty.db');
      await emptyFile.writeAsBytes([]);

      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath: emptyFile.path,
          actorRole: UserRole.owner,
        ),
        throwsA(isA<RestoreValidationException>()),
      );
    });

    test('corrupted file is rejected', () async {
      final corruptFile =
          File('${restoreDir.path}${Platform.pathSeparator}corrupt.db');
      await corruptFile.writeAsBytes([1, 2, 3, 4, 5]);

      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath: corruptFile.path,
          actorRole: UserRole.owner,
        ),
        throwsA(isA<RestoreValidationException>()),
      );
    });

    test('wrong schema version is rejected', () async {
      final wrongVersionDir =
          await Directory.systemTemp.createTemp('wrong_version');
      final wrongVersionPath =
          '${wrongVersionDir.path}${Platform.pathSeparator}wrong.db';
      final wrongVersionDb = await openDatabase(wrongVersionPath,
          version: 1, onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
      });
      await wrongVersionDb.close();

      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath: wrongVersionPath,
          actorRole: UserRole.owner,
        ),
        throwsA(isA<RestoreValidationException>()),
      );

      await wrongVersionDir.delete(recursive: true);
    });

    test('missing table in backup is rejected', () async {
      final incompleteDir =
          await Directory.systemTemp.createTemp('incomplete');
      final incompletePath =
          '${incompleteDir.path}${Platform.pathSeparator}incomplete.db';
      final incompleteDb = await openDatabase(incompletePath,
          version: 7, onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT)');
      });
      await incompleteDb.close();

      expect(
        () => StandaloneRestoreService(
          preSaveDirectory: preSaveDir.path,
          databasePathOverride: liveDbPath,
        ).restoreFromBackup(
          backupFilePath: incompletePath,
          actorRole: UserRole.owner,
        ),
        throwsA(isA<RestoreValidationException>()),
      );

      await incompleteDir.delete(recursive: true);
    });

    test('restored database is accessible and has restored data', () async {
      await testDb.delete('products');
      final rows = await testDb.query('products');
      expect(rows, isEmpty);

      await StandaloneRestoreService(
        preSaveDirectory: preSaveDir.path,
        databasePathOverride: liveDbPath,
      ).restoreFromBackup(
        backupFilePath: backupFilePath,
        actorRole: UserRole.owner,
      );

      final db = await DatabaseHelper.instance.database;
      final products = await db.query('products');
      expect(products, hasLength(1));
      expect(products.first['name'], 'منتج تجريبي');
    });

    test('pre-save backup captures pre-restore state', () async {
      await testDb.insert('products', {
        'name': 'منتج ثاني',
        'barcode': 'TEST-002',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 30.0,
        'totalInventoryCost': 150.0,
        'inventoryAdjustment': 0,
      });

      final report = await StandaloneRestoreService(
        preSaveDirectory: preSaveDir.path,
        databasePathOverride: liveDbPath,
      ).restoreFromBackup(
        backupFilePath: backupFilePath,
        actorRole: UserRole.owner,
      );

      final preSaveDb = await databaseFactoryFfiNoIsolate
          .openDatabase(report.preSaveBackupPath);
      final preSaveProducts = await preSaveDb.query('products');
      expect(preSaveProducts, hasLength(2));
      await preSaveDb.close();
    });
  });
}
