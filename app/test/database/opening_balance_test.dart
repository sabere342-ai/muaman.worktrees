import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/account.dart';
import 'package:muaman_store/models/ledger_entry.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tenant_isolation/fixture.dart';

/// Phase P Group D D2 (P-OD5): opening balances as explicit accounting entries.
///
/// Proves:
///  1. account catalog seeded EMPTY per shop
///  2. owner can create/update/delete accounts
///  3. employee CANNOT create/update/delete accounts (D2-06 B)
///  4. salesOnly CANNOT create/update/delete accounts
///  5. owner + employee can read accounts (D2-06 B)
///  6. negative opening balance rejected (D2-03 A)
///  7. zero opening balance accepted (D2-03 A)
///  8. opening balance entry persists correctly
///  9. correction creates new entry, original unchanged (D2-05 A)
/// 10. cross-shop account access fails
/// 11. account balance sum is correct (K3: zero when no entries)
/// 12. v19 -> v20 migration is additive and idempotent
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

  group('D2 — account catalog', () {
    test('1: account catalog seeded EMPTY', () async {
      final accounts = await helper.getAllAccounts();
      expect(accounts, isEmpty);
    });

    test('2: owner can create an account', () async {
      final id = await helper.createAccount(
        Account(
          shopId: 'shop-a',
          name: 'صندوق النقد',
          accountType: AccountType.cash,
        ),
        currentRole: UserRole.owner,
      );
      expect(id, greaterThan(0));
      final accounts = await helper.getAllAccounts();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'صندوق النقد');
      expect(accounts.single.accountType, AccountType.cash);
    });

    test('3: employee CANNOT create an account', () async {
      expect(
        () => helper.createAccount(
          Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(await helper.getAllAccounts(), isEmpty);
    });

    test('4: salesOnly CANNOT create an account', () async {
      expect(
        () => helper.createAccount(
          Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('5: owner + employee can read accounts', () async {
      await helper.createAccount(
        Account(shopId: 'shop-a', name: 'بنك', accountType: AccountType.bank),
        currentRole: UserRole.owner,
      );
      DatabaseHelper.setTenantIsolationArmed(true);
      final accounts = await helper.getAllAccounts();
      expect(accounts, hasLength(1));
    });
  });

  group('D2 — account management', () {
    test('6: owner can update an account', () async {
      final id = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final updated = await helper.updateAccount(
        Account(id: id, shopId: 'shop-a', name: 'محدث', accountType: AccountType.bank),
        currentRole: UserRole.owner,
      );
      expect(updated, 1);
      final fetched = await helper.getAccountById(id);
      expect(fetched!.name, 'محدث');
      expect(fetched.accountType, AccountType.bank);
    });

    test('7: employee CANNOT update an account', () async {
      final id = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.updateAccount(
          Account(id: id, shopId: 'shop-a', name: 'محدث', accountType: AccountType.bank),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('8: owner can soft-delete an account', () async {
      final id = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final deleted = await helper.deleteAccount(id, currentRole: UserRole.owner);
      expect(deleted, 1);
      final fetched = await helper.getAccountById(id);
      expect(fetched, isNull, reason: 'soft-deleted account should not be visible');
    });

    test('9: employee CANNOT delete an account', () async {
      final id = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'حساب', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.deleteAccount(id, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('D2 — opening balance entries', () {
    test('10: negative amount rejected (D2-03 A)', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.insertOpeningBalance(
          LedgerEntry(
            shopId: 'shop-a',
            accountId: accountId,
            amount: -100,
            effectiveDate: '2026-01-01',
            entryKind: EntryKind.opening,
          ),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
      final entries = await helper.getAllOpeningBalanceEntries();
      expect(entries, isEmpty, reason: 'no entry created for negative amount');
    });

    test('11: zero amount accepted (D2-03 A)', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final id = await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 0,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );
      expect(id, greaterThan(0));
      final entries = await helper.getAllOpeningBalanceEntries();
      expect(entries, hasLength(1));
      expect(entries.single.amount, 0);
    });

    test('12: positive opening balance persists', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final id = await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 1500.50,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );
      expect(id, greaterThan(0));

      final entries = await helper.getOpeningBalanceEntriesByAccount(accountId);
      expect(entries, hasLength(1));
      expect(entries.single.amount, 1500.50);
      expect(entries.single.entryKind, EntryKind.opening);
    });

    test('13: correction creates new entry, original unchanged (D2-05 A)', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final originalId = await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 1000,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );

      final correctionId = await helper.correctOpeningBalance(
        originalId,
        1200,
        currentRole: UserRole.owner,
        effectiveDate: '2026-01-02',
        correctionReason: 'تصحيح الرصيد الأولي',
      );

      expect(correctionId, greaterThan(0));
      final entries = await helper.getOpeningBalanceEntriesByAccount(accountId);
      expect(entries, hasLength(2));

      final original = entries.firstWhere((e) => e.id == originalId);
      expect(original.amount, 1000,
          reason: 'original entry must NOT be mutated');
      final correction = entries.firstWhere((e) => e.id == correctionId);
      expect(correction.amount, 1200);
      expect(correction.entryKind, EntryKind.correction);
      expect(correction.correctsEntryId, originalId);
    });

    test('14: account balance sum correct (K3: zero when empty)', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );

      final empty = await helper.getAccountOpeningBalance(accountId);
      expect(empty, 0);

      await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 500,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );
      await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 300,
          effectiveDate: '2026-01-15',
          entryKind: EntryKind.adjustment,
        ),
        currentRole: UserRole.owner,
      );

      final total = await helper.getAccountOpeningBalance(accountId);
      expect(total, 800);
    });

    test('15: employee CANNOT insert opening balance', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.insertOpeningBalance(
          LedgerEntry(
            shopId: 'shop-a',
            accountId: accountId,
            amount: 500,
            effectiveDate: '2026-01-01',
            entryKind: EntryKind.opening,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('16: employee CANNOT correct opening balance', () async {
      final accountId = await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      final originalId = await helper.insertOpeningBalance(
        LedgerEntry(
          shopId: 'shop-a',
          accountId: accountId,
          amount: 500,
          effectiveDate: '2026-01-01',
          entryKind: EntryKind.opening,
        ),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.correctOpeningBalance(
          originalId,
          600,
          currentRole: UserRole.employee,
          effectiveDate: '2026-01-02',
          correctionReason: 'test',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('17: duplicate name rejected', () async {
      await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );
      expect(
        () => helper.createAccount(
          Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.bank),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('18: cross-shop account access fails', () async {
      DatabaseHelper.setTenantIsolationArmed(true);
      await helper.createAccount(
        Account(shopId: 'shop-a', name: 'نقداً', accountType: AccountType.cash),
        currentRole: UserRole.owner,
      );

      await bindTestShop('shop-b');
      final accountsB = await helper.getAllAccounts();
      expect(accountsB, isEmpty,
          reason: 'Shop B must not see Shop A accounts');
    });

    test('19: v19 -> v20 migration is additive and idempotent', () async {
      final tempDir = await Directory.systemTemp.createTemp('muaman_v20_test');
      final path = p.join(
          tempDir.path, 'db_${DateTime.now().microsecondsSinceEpoch}.db');
      final v19Db = await databaseFactoryFfiNoIsolate.openDatabase(path);
      await DatabaseHelper.runFreshOnCreateForTest(v19Db, version: 19);
      await DatabaseHelper.setTestDatabase(v19Db);

      final before = await v19Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
      expect(before, isEmpty, reason: 'v19 does not have accounts table');

      await DatabaseHelper.runUpgradeToV20ForTest(v19Db);
      final after = await v19Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
      expect(after, isNotEmpty,
          reason: 'v20 adds accounts additively');

      // Idempotent re-run
      await DatabaseHelper.runUpgradeToV20ForTest(v19Db);
      final afterRerun = await v19Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'");
      expect(afterRerun, hasLength(1));

      await v19Db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
