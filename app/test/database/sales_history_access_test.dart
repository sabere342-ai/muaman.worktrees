import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);

    await testDb.insert('products', {
      'name': 'منتج تاريخي',
      'barcode': 'BAR-HIST-001',
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
      'barcode': 'BAR-HIST-001',
      'quantity': 2,
      'salePrice': 100,
      'totalSaleValue': 200,
      'costPrice': 50,
      'cogs': 100,
    });
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Sales history data-layer authorization', () {
    test('Owner can read the sales history list', () async {
      final sales = await DatabaseHelper.instance
          .getAllSales(currentRole: UserRole.owner);
      expect(sales.length, 1);
      expect(sales.first.productName, 'منتج تاريخي');
    });

    test('Employee can read the sales history list', () async {
      final sales = await DatabaseHelper.instance
          .getAllSales(currentRole: UserRole.employee);
      expect(sales.length, 1);
    });

    test('SalesOnly cannot read the sales history list (T9)', () async {
      expect(
        () => DatabaseHelper.instance
            .getAllSales(currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('SalesOnly cannot read sales by date range', () async {
      expect(
        () => DatabaseHelper.instance.getSalesByDateRange(
          DateTime(2020),
          DateTime(2030),
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('SalesOnly cannot read the sales summary', () async {
      expect(
        () => DatabaseHelper.instance
            .getSalesSummary(currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('SalesOnly cannot read sales grouped by date', () async {
      expect(
        () => DatabaseHelper.instance
            .getSalesGroupByDate(currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('SalesOnly cannot read sales grouped by product', () async {
      expect(
        () => DatabaseHelper.instance
            .getSalesGroupByProduct(currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('Sales history is denied by default when no role is supplied',
        () async {
      expect(
        () => DatabaseHelper.instance.getAllSales(),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('Owner can read sales report aggregates', () async {
      final summary = await DatabaseHelper.instance
          .getSalesSummary(currentRole: UserRole.owner);
      expect(summary['totalSales'], 200.0);
    });

    test('Owner can read sales history even with prior sales present',
        () async {
      final sales = await DatabaseHelper.instance
          .getAllSales(currentRole: UserRole.owner);
      expect(sales, hasLength(1));
      final byDate = await DatabaseHelper.instance
          .getSalesGroupByDate(currentRole: UserRole.owner);
      expect(byDate, isNotEmpty);
    });
  });
}
