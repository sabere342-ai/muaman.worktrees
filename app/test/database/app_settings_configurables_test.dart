import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/services/app_settings.dart';

import '../helpers/test_schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Default Customer Name - default', () {
    test('returns default when no key exists', () async {
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل نقدي'));
    });

    test('returns default after initializeDefaults', () async {
      await AppSettings.initializeDefaults();
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل نقدي'));
    });
  });

  group('Default Customer Name - persistence', () {
    test('set and get returns same value', () async {
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, 'عميل VIP');
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل VIP'));
    });

    test('persists across multiple reads (simulates restart)', () async {
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, 'عميل جملة');
      final name1 = await AppSettings.getDefaultCustomerName();
      final name2 = await AppSettings.getDefaultCustomerName();
      expect(name1, equals('عميل جملة'));
      expect(name2, equals('عميل جملة'));
    });

    test('overwrites previous value', () async {
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, 'عميل A');
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, 'عميل B');
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل B'));
    });

    test('persists after initializeDefaults does not overwrite', () async {
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, 'عميل مميز');
      await AppSettings.initializeDefaults();
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل مميز'));
    });
  });

  group('Default Customer Name - trimming', () {
    test('trims leading and trailing whitespace', () async {
      await AppSettings.setValue(
          AppSettings.keyDefaultCustomerName, '  عميل مرجاني  ');
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل مرجاني'));
    });
  });

  group('Default Customer Name - empty/malformed fallback', () {
    test('returns default for empty string in DB', () async {
      await AppSettings.setValue(AppSettings.keyDefaultCustomerName, '');
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل نقدي'));
    });

    test('returns default when key was never created', () async {
      final rows = await testDb.query('app_settings',
          where: 'key = ?', whereArgs: [AppSettings.keyDefaultCustomerName]);
      expect(rows, isEmpty);
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, equals('عميل نقدي'));
    });
  });

  group('Default Customer Name - no مؤمن fallback', () {
    test('default fallback is not مؤمن', () {
      expect(AppSettings.defaultCustomerName, isNot(equals('مؤمن')));
    });

    test('empty value falls back to neutral default, not مؤمن', () async {
      await AppSettings.setValue(AppSettings.keyDefaultCustomerName, '');
      final name = await AppSettings.getDefaultCustomerName();
      expect(name, isNot(equals('مؤمن')));
      expect(name, equals('عميل نقدي'));
    });
  });

  group('Support Phone - default', () {
    test('returns default when no key exists', () async {
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201014900211'));
    });

    test('returns default after initializeDefaults', () async {
      await AppSettings.initializeDefaults();
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201014900211'));
    });
  });

  group('Support Phone - persistence', () {
    test('set and get returns same value', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+201234567890');
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201234567890'));
    });

    test('persists across multiple reads', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+209876543210');
      final phone1 = await AppSettings.getSupportPhone();
      final phone2 = await AppSettings.getSupportPhone();
      expect(phone1, equals('+209876543210'));
      expect(phone2, equals('+209876543210'));
    });

    test('overwrites previous value', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+201111111111');
      await AppSettings.setValue(AppSettings.keySupportPhone, '+202222222222');
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+202222222222'));
    });

    test('persists after initializeDefaults does not overwrite', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+209999999999');
      await AppSettings.initializeDefaults();
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+209999999999'));
    });
  });

  group('Support Phone - trimming', () {
    test('trims leading and trailing whitespace', () async {
      await AppSettings.setValue(
          AppSettings.keySupportPhone, '  +201555555555  ');
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201555555555'));
    });
  });

  group('Support Phone - empty/malformed fallback', () {
    test('returns default for empty string in DB', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '');
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201014900211'));
    });

    test('returns default when key was never created', () async {
      final rows = await testDb.query('app_settings',
          where: 'key = ?', whereArgs: [AppSettings.keySupportPhone]);
      expect(rows, isEmpty);
      final phone = await AppSettings.getSupportPhone();
      expect(phone, equals('+201014900211'));
    });
  });
}
