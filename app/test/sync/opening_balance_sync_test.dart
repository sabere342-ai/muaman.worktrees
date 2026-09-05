import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/account.dart';
import 'package:muaman_store/models/ledger_entry.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/sync/adapters/accounting_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tenant_isolation/fixture.dart';

/// Phase P Group D D2 (P-OD5): sync adapter tests for the accounting entity
/// family. Verifies the adapter contract against the local schema.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final helper = DatabaseHelper.instance;
  final adapter = AccountSyncAdapter();
  final entryAdapter = OpeningBalanceEntrySyncAdapter();

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

  group('AccountSyncAdapter', () {
    test('entity type is account', () {
      expect(adapter.entityType, SyncEntityType.account);
    });

    test('local table is accounts', () {
      expect(adapter.localTableName, 'accounts');
    });

    test('cloud table is cloud_accounts', () {
      expect(adapter.cloudTableName, 'cloud_accounts');
    });

    test('required permission is inventory.edit', () {
      expect(adapter.requiredPermission, 'inventory.edit');
    });

    test('conflict policy is lastWriterWins', () {
      expect(adapter.conflictPolicy,
          ConflictResolutionPolicy.lastWriterWins);
    });

    test('isServerAuthoritative is false', () {
      expect(adapter.isServerAuthoritative, isFalse);
    });

    test('localToCloudPayload maps name and account_type', () async {
      final id = await helper.createAccount(
        Account(
          shopId: 'shop-a',
          name: 'صندوق النقد',
          accountType: AccountType.cash,
        ),
        currentRole: UserRole.owner,
      );
      final row = await testDb.query('accounts', where: 'id = ?', whereArgs: [id]);
      final payload = adapter.localToCloudPayload(row.first);
      expect(payload['name'], 'صندوق النقد');
      expect(payload['account_type'], 'CASH');
    });

    test('cloudToLocalRow maps fields correctly', () {
      final local = adapter.cloudToLocalRow({
        'id': 'cloud-uuid-1',
        'name': 'بنك الأمان',
        'account_type': 'BANK',
      });
      expect(local['name'], 'بنك الأمان');
      expect(local['account_type'], 'BANK');
      expect(local['cloud_uuid'], 'cloud-uuid-1');
    });

    test('getCloudUuid returns cloud_uuid', () {
      expect(adapter.getCloudUuid({'cloud_uuid': 'abc-123'}), 'abc-123');
      expect(adapter.getCloudUuid({'cloud_uuid': null}), '');
    });

    test('getLocalId returns integer id', () {
      expect(adapter.getLocalId({'id': 42}), 42);
      expect(adapter.getLocalId({'id': null}), 0);
    });

    test('getServerVersion returns integer', () {
      expect(adapter.getServerVersion({'server_version': 3}), 3);
      expect(adapter.getServerVersion({'server_version': null}), 0);
    });
  });

  group('OpeningBalanceEntrySyncAdapter', () {
    test('entity type is openingBalanceEntry', () {
      expect(entryAdapter.entityType, SyncEntityType.openingBalanceEntry);
    });

    test('local table is opening_balance_entries', () {
      expect(entryAdapter.localTableName, 'opening_balance_entries');
    });

    test('cloud table is cloud_opening_balance_entries', () {
      expect(entryAdapter.cloudTableName, 'cloud_opening_balance_entries');
    });

    test('required permission is inventory.edit', () {
      expect(entryAdapter.requiredPermission, 'inventory.edit');
    });

    test('conflict policy is serverAuthoritative', () {
      expect(entryAdapter.conflictPolicy,
          ConflictResolutionPolicy.serverAuthoritative);
    });

    test('isServerAuthoritative is true', () {
      expect(entryAdapter.isServerAuthoritative, isTrue);
    });

    test('isEventLike is true (append-only events)', () {
      expect(entryAdapter.isEventLike, isTrue);
    });

    test('localToCloudPayload maps fields correctly', () async {
      final accountId = await helper.createAccount(
        Account(
          shopId: 'shop-a',
          name: 'نقداً',
          accountType: AccountType.cash,
        ),
        currentRole: UserRole.owner,
      );
      final entryId = await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 1000,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );
      final row = await testDb.query('opening_balance_entries',
          where: 'id = ?', whereArgs: [entryId]);
    final payload = entryAdapter.localToCloudPayload(row.first);
    expect(payload['account_id'], accountId);
      expect(payload['amount'], 1000);
      expect(payload['entry_kind'], 'OPENING');
    });
  });
}
