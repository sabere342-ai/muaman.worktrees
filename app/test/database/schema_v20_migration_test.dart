import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/account.dart';
import 'package:muaman_store/models/ledger_entry.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/sync/sync_status.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tenant_isolation/fixture.dart';

/// Phase P Group D D2: schema v19 -> v20 migration regression
///
/// Proves (W.1 / W.2):
///  - accounts table created with correct columns
///  - opening_balance_entries table created with FK to accounts
///  - migration is idempotent (re-running does not fail or duplicate)
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final helper = DatabaseHelper.instance;

  setUp(() async {
    await bindTestShop('shop-a');
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  test('v20 adds accounts and opening_balance_entries tables', () async {
    final tempDir = await Directory.systemTemp.createTemp('muaman_v20');
    final path = p.join(
        tempDir.path, 'migr_test_${DateTime.now().microsecondsSinceEpoch}.db');
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(path);
    await DatabaseHelper.runFreshOnCreateForTest(testDb, version: 19);
    await DatabaseHelper.setTestDatabase(testDb);

    final beforeAccounts = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
    final beforeEntries = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='opening_balance_entries'");
    expect(beforeAccounts, isEmpty, reason: 'v19 should not have accounts table');
    expect(beforeEntries, isEmpty,
        reason: 'v19 should not have opening_balance_entries table');

    await DatabaseHelper.runUpgradeToV20ForTest(testDb);

    final afterAccounts = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
    final afterEntries = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='opening_balance_entries'");
    expect(afterAccounts, isNotEmpty,
        reason: 'v20 should add accounts table');
    expect(afterEntries, isNotEmpty,
        reason: 'v20 should add opening_balance_entries table');

    // Verify accounts table schema
    final cols = await testDb.rawQuery("PRAGMA table_info(accounts)");
    final colNames = cols.map((c) => (c as Map<String, dynamic>)['name']).toSet();
    expect(colNames, containsAll(['id', 'shop_id', 'name', 'account_type']));

    // Verify FK exists
    final fks = await testDb.rawQuery("PRAGMA foreign_key_list(opening_balance_entries)");
    expect(fks, isNotEmpty,
        reason: 'opening_balance_entries must reference accounts');

    // Idempotency
    await DatabaseHelper.runUpgradeToV20ForTest(testDb);
    final rerunAccounts = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
    expect(rerunAccounts, hasLength(1));

    await testDb.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('migrated schema supports CRUD via helper methods', () async {
    final tempDir = await Directory.systemTemp.createTemp('muaman_v20_crud');
    final path = p.join(
        tempDir.path, 'crud_test_${DateTime.now().microsecondsSinceEpoch}.db');
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(path);
    await DatabaseHelper.runFreshOnCreateForTest(testDb, version: 19);
    await DatabaseHelper.setTestDatabase(testDb);

    await DatabaseHelper.runUpgradeToV20ForTest(testDb);

    final id = await helper.createAccount(
      Account(
        shopId: 'shop-a',
        name: 'حساب اختبار',
        accountType: AccountType.cash,
      ),
      currentRole: UserRole.owner,
    );
    expect(id, greaterThan(0));

    final entryId = await helper.insertOpeningBalance(
      LedgerEntry(
        shopId: 'shop-a',
        accountId: id,
        amount: 2500,
        effectiveDate: '2026-01-01',
        entryKind: EntryKind.opening,
      ),
      currentRole: UserRole.owner,
    );
    expect(entryId, greaterThan(0));

    final balance = await helper.getAccountOpeningBalance(id);
    expect(balance, 2500);

    await testDb.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });
}
