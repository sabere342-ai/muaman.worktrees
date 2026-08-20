import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/clean_start_service.dart';
import 'package:muaman_store/services/permissions.dart';

import '../helpers/test_schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database testDb;
  late Directory backupDir;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    backupDir = await Directory.systemTemp.createTemp('cleanstart_test');
  });

  tearDown(() async {
    await testDb.close();
    if (backupDir.existsSync()) {
      await backupDir.delete(recursive: true);
    }
  });

  Future<void> seedTransactionalData() async {
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
      'quantity': 1,
      'salePrice': 100.0,
      'totalSaleValue': 100.0,
      'costPrice': 50.0,
      'cogs': 50.0,
    });
    await testDb.insert('returns', {
      'date': '2026-08-01T00:00:00.000',
      'productName': 'منتج تجريبي',
      'barcode': 'TEST-001',
      'quantity': 1,
      'salePrice': 100.0,
      'totalReturnValue': 100.0,
      'costPrice': 50.0,
      'returnedCogs': 50.0,
    });
    await testDb.insert('expenses', {
      'date': '2026-08-01T00:00:00.000',
      'description': 'مصروف تجريبي',
      'amount': 25.0,
    });
    await testDb.insert('inventory_count', {
      'productId': 1,
      'actualQuantity': 10,
      'notes': '',
      'countDate': '2026-08-01T00:00:00.000',
    });
    await testDb.insert('invoices', {
      'invoiceNumber': 'INV-1',
      'date': '2026-08-01T00:00:00.000',
      'customerName': 'زبون تجريبي',
      'paymentMethod': 'نقدي',
      'totalAmount': 100.0,
      'totalItems': 1,
      'createdAt': '2026-08-01T00:00:00.000',
    });
    await testDb.insert('customers', {
      'name': 'عميل تجريبي',
      'phone': '0123456789',
      'isActive': 1,
      'isSystem': 0,
      'createdAt': '2026-08-01T00:00:00.000',
      'updatedAt': '2026-08-01T00:00:00.000',
    });
    await testDb.insert('import_batches', {
      'file_sha256': 'abc123',
      'file_name': 'demo.xlsx',
      'imported_at': '2026-08-01T00:00:00.000',
      'products_count': 1,
      'sales_count': 1,
      'returns_count': 1,
      'expenses_count': 1,
      'adjustments_count': 0,
      'total_quantity': 1,
      'total_inventory_value': 500.0,
      'total_sales': 100.0,
      'total_returns': 100.0,
      'net_sales': 0.0,
      'total_cogs': 50.0,
      'returned_cogs': 50.0,
      'net_cogs': 0.0,
      'gross_profit': 0.0,
      'total_expenses': 25.0,
      'net_profit': -25.0,
    });
    await testDb.insert('expense_categories', {
      'name': 'عام',
    });
  }

  Future<void> seedPreservedData() async {
    await testDb.insert('users', {
      'displayName': 'المالك',
      'username': 'owner',
      'passwordHash': 'dummy:dummy',
      'role': 'owner',
      'isActive': 1,
      'createdAt': '2026-08-01T00:00:00.000',
      'updatedAt': '2026-08-01T00:00:00.000',
    });
    await testDb.insert('role_permissions', {
      'role': 'owner',
      'permissions': '[]',
      'updatedAt': '2026-08-01T00:00:00.000',
    });
    await testDb.insert('app_settings', {
      'key': 'shopProfile.shopName',
      'value': 'متجر تجريبي',
    });
  }

  Future<int> countRows(String table) async {
    final rows = await testDb.rawQuery('SELECT COUNT(*) c FROM $table');
    return (rows.first['c'] as num).toInt();
  }

  test('owner with correct phrase wipes transactions and keeps preserved rows',
      () async {
    await seedTransactionalData();
    await seedPreservedData();

    final report = await CleanStartService().run(
      actorRole: UserRole.owner,
      backupDirectory: backupDir.path,
      confirmation: 'مسح البيانات',
    );

    for (final table in CleanStartService.transactionalTables) {
      expect(await countRows(table), 0, reason: '$table must be empty');
    }
    for (final table in CleanStartService.preservedTables) {
      expect(await countRows(table), greaterThan(0),
          reason: '$table preserved');
    }

    expect(report.deletedCounts.keys,
        containsAll(CleanStartService.transactionalTables));
    expect(report.backupPath, startsWith(backupDir.path));

    // The mandatory snapshot exists and is a valid SQLite database that still
    // holds the pre-wipe rows (products at least).
    final backupFile = File(report.backupPath);
    expect(backupFile.existsSync(), isTrue);
    expect(backupFile.lengthSync(), greaterThan(0));
    final backupDb =
        await databaseFactoryFfiNoIsolate.openDatabase(report.backupPath);
    final backupProducts = await backupDb.query('products');
    expect(backupProducts, isNotEmpty);
    await backupDb.close();
  });

  test('non-owner is denied and nothing is deleted', () async {
    await seedTransactionalData();

    expect(
      () => CleanStartService().run(
        actorRole: UserRole.employee,
        backupDirectory: backupDir.path,
        confirmation: 'مسح البيانات',
      ),
      throwsA(isA<PermissionDeniedException>()),
    );

    expect(await countRows('products'), 1);
    expect(await countRows('sales'), 1);
    // No backup should be written before authorization succeeds.
    expect(backupDir.listSync().whereType<File>().toList(), isEmpty);
  });

  test('wrong confirmation phrase aborts before any backup or deletion',
      () async {
    await seedTransactionalData();

    expect(
      () => CleanStartService().run(
        actorRole: UserRole.owner,
        backupDirectory: backupDir.path,
        confirmation: 'كلمة غير صحيحة',
      ),
      throwsA(isA<CleanStartConfirmationException>()),
    );

    expect(await countRows('products'), 1);
    expect(backupDir.listSync().whereType<File>().toList(), isEmpty);
  });

  test('empty confirmation is rejected', () async {
    await seedTransactionalData();

    expect(
      () => CleanStartService().run(
        actorRole: UserRole.owner,
        backupDirectory: backupDir.path,
        confirmation: '  ',
      ),
      throwsA(isA<CleanStartConfirmationException>()),
    );

    expect(await countRows('products'), 1);
  });

  test('backup failure aborts wipe with nothing deleted', () async {
    await seedTransactionalData();

    // Point the backup at a path that cannot be created as a directory
    // (a file exists at that path), forcing the snapshot to fail.
    final blocker = File('${backupDir.path}${Platform.pathSeparator}blocker');
    await blocker.writeAsString('x');

    expect(
      () => CleanStartService().run(
        actorRole: UserRole.owner,
        backupDirectory: blocker.path,
        confirmation: 'مسح البيانات',
      ),
      throwsA(isA<CleanStartBackupFailedException>()),
    );

    expect(await countRows('products'), 1);
    expect(await countRows('sales'), 1);
    expect(await countRows('returns'), 1);
  });

  test('mid-wipe failure rolls back the whole wipe', () async {
    await seedTransactionalData();

    // Force a failure on the LAST deleted table (products is wiped last in the
    // list). The delete order guarantees sales/returns/... are already deleted
    // inside the transaction when products fails, so a successful rollback
    // proves all-or-nothing behavior.
    await testDb.execute('''
      CREATE TRIGGER block_product_deletion
      BEFORE DELETE ON products
      BEGIN
        SELECT RAISE(ABORT, 'blocked for test');
      END;
    ''');

    await expectLater(
      CleanStartService().run(
        actorRole: UserRole.owner,
        backupDirectory: backupDir.path,
        confirmation: 'مسح البيانات',
      ),
      throwsA(isA<Exception>()),
    );

    // Backup was created before the wipe, but nothing may be deleted.
    expect(backupDir.listSync().whereType<File>().toList(), isNotEmpty);
    for (final table in CleanStartService.transactionalTables) {
      expect(await countRows(table), 1, reason: '$table must survive rollback');
    }
  });

  test('report counts every deleted transactional row', () async {
    await seedTransactionalData();
    await seedPreservedData();

    final report = await CleanStartService().run(
      actorRole: UserRole.owner,
      backupDirectory: backupDir.path,
      confirmation: 'مسح البيانات',
    );

    expect(report.deletedCounts['products'], 1);
    expect(report.deletedCounts['sales'], 1);
    expect(report.deletedCounts['returns'], 1);
    expect(report.deletedCounts['expenses'], 1);
    expect(report.deletedCounts['inventory_count'], 1);
    expect(report.deletedCounts['invoices'], 1);
    expect(report.deletedCounts['customers'], 1);
    expect(report.deletedCounts['import_batches'], 1);
    expect(report.timestamp, isNotNull);
  });
}
