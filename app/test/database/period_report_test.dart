import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/account.dart';
import 'package:muaman_store/models/ledger_entry.dart';
import 'package:muaman_store/models/period_report.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tenant_isolation/fixture.dart';

/// Phase P Group D D3 (P-OD6): arbitrary-period profit reporting tests.
///
/// Proves:
///  1.  Day preset semantics
///  2.  Week preset semantics (Sunday start)
///  3.  Month boundary
///  4.  Quarter boundary
///  5.  Year boundary
///  6.  Custom range conversion
///  7.  startInclusive boundary included
///  8.  endExclusive boundary excluded
///  9.  Date-only comparison (no timestamp leakage)
///  10. Revenue aggregation
///  11. Returns deduction
///  12. COGS aggregation
///  13. Returned COGS deduction
///  14. Net revenue
///  15. Net COGS
///  16. Gross profit
///  17. Expense deduction
///  18. Opening-balance adjustment inclusion
///  19. Opening-balance adjustment excluded from gross profit
///  20. Net-result calculation
///  21. Empty valid period (zero aggregates, complete=true)
///  22. Missing opening_balance_entries (complete=false, no false net-profit)
///  23. Required source query failure (complete=false)
///  24. Cross-shop tenant isolation
///  25. salesOnly RBAC denial
///  26. Owner allowed
///  27. Employee allowed (per canonical resolver)
///  28. Incomplete PeriodReport suppresses authoritative net-profit labeling
///  29. Historical COGS remains based on stored sale/return snapshots
///  30. Existing today/month/all sales reporting behavior remains intact
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
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<int> insertTestSale({
    required String date,
    required double totalSaleValue,
    double cogs = 0,
    double costPrice = 0,
    int quantity = 1,
    String shopId = 'shop-a',
    String barcode = 'BC-1',
    String productName = 'Test Product',
    double salePrice = 0,
  }) {
    return testDb.insert('sales', {
      'date': date,
      'productName': productName,
      'barcode': barcode,
      'quantity': quantity,
      'salePrice': salePrice == 0 ? totalSaleValue / quantity : salePrice,
      'totalSaleValue': totalSaleValue,
      'costPrice': costPrice,
      'cogs': cogs,
      'shop_id': shopId,
    });
  }

  Future<int> insertTestReturn({
    required String date,
    required double totalReturnValue,
    double returnedCogs = 0,
    double costPrice = 0,
    int quantity = 1,
    String shopId = 'shop-a',
    String barcode = 'BC-1',
    String productName = 'Test Product',
    double salePrice = 0,
  }) {
    return testDb.insert('returns', {
      'date': date,
      'productName': productName,
      'barcode': barcode,
      'quantity': quantity,
      'salePrice': salePrice,
      'totalReturnValue': totalReturnValue,
      'costPrice': costPrice,
      'returnedCogs': returnedCogs,
      'shop_id': shopId,
    });
  }

  Future<int> insertTestExpense({
    required String date,
    required double amount,
    String description = 'Test Expense',
    String shopId = 'shop-a',
  }) {
    return testDb.insert('expenses', {
      'date': date,
      'description': description,
      'amount': amount,
      'category': 'test',
      'shop_id': shopId,
    });
  }

  Future<int> insertTestOpeningBalance({
    required String effectiveDate,
    required double amount,
    required int accountId,
    String shopId = 'shop-a',
    EntryKind kind = EntryKind.opening,
  }) {
    return testDb.insert('opening_balance_entries', {
      'shop_id': shopId,
      'account_id': accountId,
      'amount': amount,
      'effective_date': effectiveDate,
      'entry_kind': kind.value,
      'idempotency_key':
          '${shopId}_${accountId}_${effectiveDate}_${kind.value}',
      'created_by': 'test',
      'created_at': '2026-01-01T00:00:00.000',
      'cloud_uuid': 'test-uuid',
      'sync_status': 'SYNCED',
    });
  }

  // ==================================================================
  // GROUP 1: Period boundary computation (tests 1–6)
  // ==================================================================
  group('D3 — period boundary computation', () {
    test('1: day preset semantics', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.day,
          reference: DateTime(2026, 9, 6));
      expect(bounds.start, '2026-09-06');
      expect(bounds.end, '2026-09-07');
    });

    test('2: week preset semantics (Sunday start)', () {
      final wed = DateTime(2026, 9, 9);
      final bounds =
          PeriodReport.computePeriodBounds(PeriodType.week, reference: wed);
      expect(bounds.start, '2026-09-06');
      expect(bounds.end, '2026-09-13');
    });

    test('2b: week preset when reference is itself Sunday', () {
      final sun = DateTime(2026, 9, 6);
      final bounds =
          PeriodReport.computePeriodBounds(PeriodType.week, reference: sun);
      expect(bounds.start, '2026-09-06');
      expect(bounds.end, '2026-09-13');
    });

    test('3: month boundary', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.month,
          reference: DateTime(2026, 9, 15));
      expect(bounds.start, '2026-09-01');
      expect(bounds.end, '2026-10-01');
    });

    test('3b: month boundary for December', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.month,
          reference: DateTime(2026, 12, 15));
      expect(bounds.start, '2026-12-01');
      expect(bounds.end, '2027-01-01');
    });

    test('4: quarter boundary', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.quarter,
          reference: DateTime(2026, 8, 15));
      expect(bounds.start, '2026-07-01');
      expect(bounds.end, '2026-10-01');
    });

    test('4b: quarter boundary for Q1', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.quarter,
          reference: DateTime(2026, 2, 15));
      expect(bounds.start, '2026-01-01');
      expect(bounds.end, '2026-04-01');
    });

    test('5: year boundary', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.year,
          reference: DateTime(2026, 9, 6));
      expect(bounds.start, '2026-01-01');
      expect(bounds.end, '2027-01-01');
    });

    test('6: custom range conversion', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.customRange,
          customStart: DateTime(2026, 9, 1), customEnd: DateTime(2026, 9, 30));
      expect(bounds.start, '2026-09-01');
      expect(bounds.end, '2026-10-01');
    });

    test('6b: custom range single-day', () {
      final bounds = PeriodReport.computePeriodBounds(PeriodType.customRange,
          customStart: DateTime(2026, 9, 15), customEnd: DateTime(2026, 9, 15));
      expect(bounds.start, '2026-09-15');
      expect(bounds.end, '2026-09-16');
    });
  });

  // ==================================================================
  // GROUP 2: Boundary filtering (tests 7–9)
  // ==================================================================
  group('D3 — boundary filtering', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('7: startInclusive boundary included', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 100);
      expect(report.cogs, 60);
      expect(report.complete, isTrue);
    });

    test('8: endExclusive boundary excluded', () async {
      await insertTestSale(date: '2026-09-30', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 100,
          reason: 'Sep 30 must be within [Sep 1, Oct 1)');

      final reportExcl = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-09-30',
        periodType: PeriodType.customRange,
        currentRole: UserRole.owner,
      );
      expect(reportExcl.revenue, 0,
          reason: 'Sep 30 must be EXCLUDED when end = Sep 30');
    });

    test('9: date-only comparison no timestamp leakage', () async {
      await insertTestSale(
          date: '2026-09-15T14:30:00.000', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-15',
        end: '2026-09-16',
        periodType: PeriodType.day,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 100,
          reason:
              'Full-timestamp sale on Sep 15 must be included by date-only [Sep 15, Sep 16)');

      final reportNextDay = await helper.getPeriodReport(
        start: '2026-09-16',
        end: '2026-09-17',
        periodType: PeriodType.day,
        currentRole: UserRole.owner,
      );
      expect(reportNextDay.revenue, 0,
          reason: 'Sep 15 timestamp must NOT leak into Sep 16 query');
    });
  });

  // ==================================================================
  // GROUP 3: Accounting correctness (tests 10–20)
  // ==================================================================
  group('D3 — accounting correctness', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('10: revenue aggregation', () async {
      await insertTestSale(date: '2026-09-10', totalSaleValue: 100, cogs: 60);
      await insertTestSale(date: '2026-09-15', totalSaleValue: 250, cogs: 100);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 350);
    });

    test('11: returns deduction', () async {
      await insertTestSale(date: '2026-09-10', totalSaleValue: 1000, cogs: 600);
      await insertTestReturn(
          date: '2026-09-15', totalReturnValue: 200, returnedCogs: 120);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 1000);
      expect(report.returns, 200);
      expect(report.netRevenue, 800);
    });

    test('12: COGS aggregation', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 100, cogs: 60);
      await insertTestSale(date: '2026-09-02', totalSaleValue: 200, cogs: 120);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.cogs, 180);
    });

    test('13: returned COGS deduction', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 600);
      await insertTestReturn(
          date: '2026-09-15', totalReturnValue: 200, returnedCogs: 120);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.cogs, 600);
      expect(report.returnedCogs, 120);
      expect(report.netCogs, 480);
    });

    test('14: net revenue', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 0);
      await insertTestReturn(
          date: '2026-09-02', totalReturnValue: 250, returnedCogs: 0);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.revenue, 1000);
      expect(report.returns, 250);
      expect(report.netRevenue, 750);
    });

    test('15: net COGS', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 600);
      await insertTestReturn(
          date: '2026-09-02', totalReturnValue: 200, returnedCogs: 100);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.cogs, 600);
      expect(report.returnedCogs, 100);
      expect(report.netCogs, 500);
    });

    test('16: gross profit', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 600);
      await insertTestReturn(
          date: '2026-09-02', totalReturnValue: 100, returnedCogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      const expectedGp = (1000 - 100) - (600 - 60);
      expect(report.grossProfit, expectedGp);
    });

    test('17: expense deduction', () async {
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 400);
      await insertTestExpense(date: '2026-09-15', amount: 100);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.expenses, 100);
      expect(report.grossProfit, 600);
      expect(report.netResult, 500);
    });

    test('18: opening-balance adjustment inclusion', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      await insertTestOpeningBalance(
          effectiveDate: '2026-09-15', amount: 500, accountId: accountId);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.openingBalanceAdjustments, 500);
      expect(report.netResult, 500);
    });

    test('19: opening-balance adjustment excluded from gross profit', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 400);
      await insertTestOpeningBalance(
          effectiveDate: '2026-09-15', amount: 200, accountId: accountId);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.grossProfit, 600,
          reason: 'Opening balance must NOT enter gross profit');
      expect(report.openingBalanceAdjustments, 200);
      expect(report.netResult, 800);
    });

    test('20: net-result calculation', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      await insertTestSale(date: '2026-09-01', totalSaleValue: 1000, cogs: 400);
      await insertTestReturn(
          date: '2026-09-02', totalReturnValue: 100, returnedCogs: 40);
      await insertTestExpense(date: '2026-09-15', amount: 50);
      await insertTestOpeningBalance(
          effectiveDate: '2026-09-20', amount: 200, accountId: accountId);

      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );

      const netRevenue = 1000 - 100;
      const netCogs = 400 - 40;
      const grossProfit = netRevenue - netCogs;
      const netResult = grossProfit - 50 + 200;
      expect(report.revenue, 1000);
      expect(report.returns, 100);
      expect(report.netRevenue, netRevenue);
      expect(report.cogs, 400);
      expect(report.returnedCogs, 40);
      expect(report.netCogs, netCogs);
      expect(report.grossProfit, grossProfit);
      expect(report.expenses, 50);
      expect(report.openingBalanceAdjustments, 200);
      expect(report.netResult, netResult);
    });
  });

  // ==================================================================
  // GROUP 4: False-profit prevention (tests 21–23)
  // ==================================================================
  group('D3 — false-profit prevention', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('21: empty valid period (zero aggregates, complete=true)', () async {
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isTrue);
      expect(report.revenue, 0);
      expect(report.returns, 0);
      expect(report.netRevenue, 0);
      expect(report.cogs, 0);
      expect(report.returnedCogs, 0);
      expect(report.netCogs, 0);
      expect(report.grossProfit, 0);
      expect(report.expenses, 0);
      expect(report.openingBalanceAdjustments, 0);
      expect(report.netResult, 0);
      expect(report.transactionCount, 0);
    });

    test('22: missing opening_balance_entries means complete=false', () async {
      await testDb.execute('DROP TABLE IF EXISTS opening_balance_entries');
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isFalse,
          reason: 'Dropped opening_balance_entries table must fail closed');
    });

    test('23: required source query failure means complete=false', () async {
      await testDb.execute('DROP TABLE IF EXISTS sales');
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isFalse,
          reason: 'Dropped sales table must fail closed');
    });

    test('23b: tenant isolation not armed means complete=false', () async {
      DatabaseHelper.setTenantIsolationArmed(false);
      await insertTestSale(date: '2026-09-10', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isFalse,
          reason: 'Tenant isolation disarmed must fail closed');
    });
  });

  // ==================================================================
  // GROUP 5: Tenant isolation (test 24)
  // ==================================================================
  group('D3 — tenant isolation', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('24: cross-shop data must not leak', () async {
      await insertTestSale(
          date: '2026-09-10', totalSaleValue: 100, cogs: 60, shopId: 'shop-a');
      await insertTestSale(
          date: '2026-09-10', totalSaleValue: 999, cogs: 500, shopId: 'shop-b');

      // Shop A report
      await bindTestShop('shop-a');
      final reportA = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(reportA.revenue, 100, reason: 'Shop A must only see its own data');
      expect(reportA.cogs, 60);
      expect(reportA.complete, isTrue);

      // Shop B report
      await bindTestShop('shop-b');
      final reportB = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(reportB.revenue, 999, reason: 'Shop B must only see its own data');
      expect(reportB.revenue, isNot(100),
          reason: 'Shop B must NOT see Shop A data');
      expect(reportB.cogs, 500);
      expect(reportB.complete, isTrue);
    });
  });

  // ==================================================================
  // GROUP 6: RBAC (tests 25–27)
  // ==================================================================
  group('D3 — RBAC', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('25: salesOnly RBAC denial', () async {
      expect(
        () => helper.getPeriodReport(
          start: '2026-09-01',
          end: '2026-10-01',
          periodType: PeriodType.month,
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('25b: null role RBAC denial', () async {
      expect(
        () => helper.getPeriodReport(
          start: '2026-09-01',
          end: '2026-10-01',
          periodType: PeriodType.month,
          currentRole: null,
        ),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('26: owner allowed', () async {
      await insertTestSale(date: '2026-09-10', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isTrue);
      expect(report.revenue, 100);
    });

    test('27: employee allowed (per canonical resolver)', () async {
      await insertTestSale(date: '2026-09-10', totalSaleValue: 100, cogs: 60);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.employee,
      );
      expect(report.complete, isTrue);
      expect(report.revenue, 100);
    });
  });

  // ==================================================================
  // GROUP 7: Incomplete suppression contract (test 28)
  // ==================================================================
  group('D3 — incomplete suppression contract', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test(
        '28: incomplete report complete=false suppresses authoritative net-profit',
        () async {
      await testDb.execute('DROP TABLE IF EXISTS opening_balance_entries');
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isFalse);

      // The serialization contract must preserve the complete flag so the UI
      // can suppress the "صافي الربح" / net profit labeling.
      final map = report.toMap();
      expect(map['complete'], 0);
      final restored = PeriodReport.fromMap(map);
      expect(restored.complete, isFalse);
      expect(restored.netResult, isNotNull);
    });

    test('28b: complete=true round-trips through serialization', () async {
      await insertTestSale(date: '2026-09-10', totalSaleValue: 500, cogs: 300);
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.complete, isTrue);
      final map = report.toMap();
      expect(map['complete'], 1);
      final restored = PeriodReport.fromMap(map);
      expect(restored.complete, isTrue);
      expect(restored.netRevenue, 500);
    });
  });

  // ==================================================================
  // GROUP 8: Historical cost invariant (test 29)
  // ==================================================================
  group('D3 — historical cost invariant', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('29: COGS from stored cogs column, not recalculated', () async {
      await insertTestSale(
        date: '2026-09-01',
        totalSaleValue: 1000,
        cogs: 600,
        costPrice: 120,
        quantity: 5,
        salePrice: 200,
      );

      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.cogs, 600,
          reason: 'COGS must come from the stored sales.cogs snapshot, not '
              'quantity * current product cost');
      expect(report.revenue, 1000);
    });

    test('29b: returned COGS from stored returnedCogs column', () async {
      await insertTestReturn(
        date: '2026-09-01',
        totalReturnValue: 200,
        returnedCogs: 120,
        costPrice: 30,
        quantity: 4,
        salePrice: 50,
      );
      final report = await helper.getPeriodReport(
        start: '2026-09-01',
        end: '2026-10-01',
        periodType: PeriodType.month,
        currentRole: UserRole.owner,
      );
      expect(report.returnedCogs, 120,
          reason: 'Returned COGS must come from stored returnedCogs, not '
              'quantity * current product cost');
      expect(report.returns, 200);
    });
  });

  // ==================================================================
  // GROUP 9: Existing behavior regression (test 30)
  // ==================================================================
  group('D3 — existing reporting regression', () {
    setUp(() {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('30: today/month/all sales reporting intact', () async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await insertTestSale(
        date: todayStr,
        totalSaleValue: 100,
        cogs: 60,
        shopId: 'shop-a',
      );

      final summary = await helper.getSalesSummary(currentRole: UserRole.owner);
      expect((summary['todaySales'] as num?)?.toDouble() ?? 0, greaterThan(0),
          reason: 'Today summary must still include today sales');

      final total = await helper.getTotalSales();
      expect(total, greaterThan(0), reason: 'Total sales must still work');

      final allSales = await helper.getAllSales(currentRole: UserRole.owner);
      expect(allSales, isNotEmpty,
          reason: 'getAllSales must still return sales');

      final byDate =
          await helper.getSalesGroupByDate(currentRole: UserRole.owner);
      expect(byDate, isNotEmpty, reason: 'getSalesGroupByDate must still work');

      final byProduct =
          await helper.getSalesGroupByProduct(currentRole: UserRole.owner);
      expect(byProduct, isNotEmpty,
          reason: 'getSalesGroupByProduct must still work');
    });
  });
}
