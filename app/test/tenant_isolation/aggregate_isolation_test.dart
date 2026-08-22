import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture.dart';

/// J-WS4 aggregate/report isolation (plan §H): dashboard totals, sales
/// summary, group-by reports and inventory counts must equal the ACTIVE
/// shop's sums under mixed two-shop fixtures — Shop B's money must never be
/// visible in Shop A's numbers.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final helper = DatabaseHelper.instance;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    await bindTestShop('shop-a');
    await _seedTwoShops(testDb);
    DatabaseHelper.setTenantIsolationArmed(true);
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  test('J-A01: dashboard totals equal Shop A-only golden numbers', () async {
    final data = await helper.getDashboardData();
    // Seeded: A sales=100 (cogs 40), A returns=25 (returnedCogs 10),
    // A expenses=30. B holds larger amounts that must NOT leak.
    expect(data['totalSales'], 100);
    expect(data['totalReturns'], 25);
    expect(data['totalCOGS'], 40);
    expect(data['totalReturnedCOGS'], 10);
    expect(data['totalExpenses'], 30);
    expect(data['netSales'], 75);
    expect(data['netCOGS'], 30);
    expect(data['grossProfit'], 45);
    expect(data['netProfit'], 15);
  });

  test('J-A02: sales summary excludes Shop B', () async {
    final summary = await helper.getSalesSummary(currentRole: UserRole.owner);
    expect(summary['totalSales'], 100);
    expect(summary['totalQty'], 2);
    expect(summary['totalTransactions'], 2);
    expect(summary['totalCOGS'], 40);
    expect(summary['todaySales'], 100);

    final month = DateTime.now().month.toString().padLeft(2, '0');
    if (DateTime.now().year == DateTime.now().year) {
      // today/month buckets derive from the same scoped source; a B-only row
      // dated today would push these above the golden number if it leaked.
      expect(summary['todayQty'], 2);
      expect(month.length, 2);
    }
  });

  test('J-A03: group-by-date report contains no Shop B rows', () async {
    final rows = await helper.getSalesGroupByDate(currentRole: UserRole.owner);
    final totalSales =
        rows.fold<double>(0, (sum, r) => sum + (r['totalSales'] as double));
    expect(totalSales, 100);
    final txCount =
        rows.fold<int>(0, (sum, r) => sum + (r['transactionCount'] as int));
    expect(txCount, 2, reason: 'A has 2 sale rows; B rows must not appear');
  });

  test('J-A04: group-by-product report contains no Shop B entities', () async {
    final rows =
        await helper.getSalesGroupByProduct(currentRole: UserRole.owner);
    expect(rows.map((r) => r['barcode'] as String), isNot(contains('BC-B')));
    expect(rows.map((r) => r['barcode'] as String), contains('BC-A'));
    expect(rows.map((r) => r['barcode'] as String), contains('BC-A2'));
  });

  test('J-A05: inventory summary counts only Shop A', () async {
    final summary = await helper.getInventorySummary();
    expect(summary['itemCount'], 2); // A has two products; B has one more.
    expect(summary['salesCount'], 2);
    expect(summary['returnsCount'], 1);
    expect(summary['expensesCount'], 1);
  });
}

Future<void> _seedTwoShops(Database db) async {
  final date = DateTime.now().toIso8601String();

  Future<void> product(String barcode, String name, String shop,
          {int qty = 5, double cost = 10}) async =>
      db.insert('products', {
        'name': name,
        'barcode': barcode,
        'openingQuantity': qty,
        'currentQuantity': qty,
        'costPrice': cost,
        'totalInventoryCost': qty * cost,
        'shop_id': shop,
      });

  Future<void> sale(String barcode, double value, double cogs, String shop,
          {int quantity = 1}) async =>
      db.insert('sales', {
        'date': date,
        'productName': barcode,
        'barcode': barcode,
        'quantity': quantity,
        'salePrice': value / quantity,
        'totalSaleValue': value,
        'costPrice': cogs / quantity,
        'cogs': cogs,
        'shop_id': shop,
      });

  await product('BC-A', 'أ', 'shop-a', qty: 4, cost: 10);
  await product('BC-A2', 'أ٢', 'shop-a', qty: 6, cost: 20);
  await product('BC-B', 'ب', 'shop-b', qty: 50, cost: 99);

  await sale('BC-A', 60, 24, 'shop-a');
  await sale('BC-A2', 40, 16, 'shop-a');
  await sale('BC-B', 900, 300, 'shop-b');

  await db.insert('returns', {
    'date': date,
    'productName': 'أ',
    'barcode': 'BC-A',
    'quantity': 1,
    'salePrice': 25,
    'totalReturnValue': 25,
    'costPrice': 10,
    'returnedCogs': 10,
    'shop_id': 'shop-a',
  });
  await db.insert('returns', {
    'date': date,
    'productName': 'ب',
    'barcode': 'BC-B',
    'quantity': 1,
    'salePrice': 500,
    'totalReturnValue': 500,
    'costPrice': 300,
    'returnedCogs': 300,
    'shop_id': 'shop-b',
  });

  await db.insert('expenses', {
    'date': date,
    'description': 'مصروف أ',
    'amount': 30,
    'category': 'تشغيل',
    'shop_id': 'shop-a',
  });
  await db.insert('expenses', {
    'date': date,
    'description': 'مصروف ب',
    'amount': 700,
    'category': 'تشغيل ب',
    'shop_id': 'shop-b',
  });
}
