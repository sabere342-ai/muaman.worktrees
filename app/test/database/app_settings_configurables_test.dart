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
      await AppSettings.setValue(AppSettings.keyDefaultCustomerName, 'عميل A');
      await AppSettings.setValue(AppSettings.keyDefaultCustomerName, 'عميل B');
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

  group('Invoice Title - default', () {
    test('returns default when no key exists', () async {
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة بيع'));
    });

    test('returns default after initializeDefaults', () async {
      await AppSettings.initializeDefaults();
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة بيع'));
    });
  });

  group('Invoice Title - persistence', () {
    test('set and get returns same value', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة ضريبية');
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة ضريبية'));
    });

    test('persists across multiple reads', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'إيصال بيع');
      final title1 = await AppSettings.getInvoiceTitle();
      final title2 = await AppSettings.getInvoiceTitle();
      expect(title1, equals('إيصال بيع'));
      expect(title2, equals('إيصال بيع'));
    });

    test('overwrites previous value', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة A');
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة B');
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة B'));
    });

    test('persists after initializeDefaults does not overwrite', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة مميزة');
      await AppSettings.initializeDefaults();
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة مميزة'));
    });
  });

  group('Invoice Title - trimming', () {
    test('trims leading and trailing whitespace', () async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceTitle, '  فاتورة مرجاني  ');
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة مرجاني'));
    });
  });

  group('Invoice Title - empty/malformed fallback', () {
    test('returns default for empty string in DB', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, '');
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة بيع'));
    });

    test('returns default when key was never created', () async {
      final rows = await testDb.query('app_settings',
          where: 'key = ?', whereArgs: [AppSettings.keyInvoiceTitle]);
      expect(rows, isEmpty);
      final title = await AppSettings.getInvoiceTitle();
      expect(title, equals('فاتورة بيع'));
    });
  });

  group('Invoice Footer Text - default', () {
    test('returns default when no key exists', () async {
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً لتعاملكم معنا'));
    });

    test('returns default after initializeDefaults', () async {
      await AppSettings.initializeDefaults();
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً لتعاملكم معنا'));
    });
  });

  group('Invoice Footer Text - persistence', () {
    test('set and get returns same value', () async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceFooterText, 'نتمنى لكم التوفيق');
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('نتمنى لكم التوفيق'));
    });

    test('persists across multiple reads', () async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceFooterText, 'مع تحياتنا');
      final footer1 = await AppSettings.getInvoiceFooterText();
      final footer2 = await AppSettings.getInvoiceFooterText();
      expect(footer1, equals('مع تحياتنا'));
      expect(footer2, equals('مع تحياتنا'));
    });

    test('overwrites previous value', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceFooterText, 'شكراً A');
      await AppSettings.setValue(AppSettings.keyInvoiceFooterText, 'شكراً B');
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً B'));
    });

    test('persists after initializeDefaults does not overwrite', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceFooterText, 'Message');
      await AppSettings.initializeDefaults();
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('Message'));
    });
  });

  group('Invoice Footer Text - trimming', () {
    test('trims leading and trailing whitespace', () async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceFooterText, '  شكراً لكم  ');
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً لكم'));
    });
  });

  group('Invoice Footer Text - empty/malformed fallback', () {
    test('returns default for empty string in DB', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceFooterText, '');
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً لتعاملكم معنا'));
    });

    test('returns default when key was never created', () async {
      final rows = await testDb.query('app_settings',
          where: 'key = ?', whereArgs: [AppSettings.keyInvoiceFooterText]);
      expect(rows, isEmpty);
      final footer = await AppSettings.getInvoiceFooterText();
      expect(footer, equals('شكراً لتعاملكم معنا'));
    });
  });

  group('I Tech Attribution Text - OD5 fixed non-editable', () {
    test('returns exact OD5 attribution text', () async {
      final attribution = await AppSettings.getItechAttributionText();
      expect(attribution, equals('تم التطوير بواسطة I Tech للتكنولوجيا'));
    });

    test('returns exact OD5 attribution text after initializeDefaults',
        () async {
      await AppSettings.initializeDefaults();
      final attribution = await AppSettings.getItechAttributionText();
      expect(attribution, equals('تم التطوير بواسطة I Tech للتكنولوجيا'));
    });

    test('returns exact OD5 attribution text regardless of stored value',
        () async {
      await AppSettings.setValue(
          AppSettings.keyItechAttributionText, 'custom value');
      final attribution = await AppSettings.getItechAttributionText();
      expect(attribution, equals('تم التطوير بواسطة I Tech للتكنولوجيا'));
    });

    test('default constant matches OD5 exact text', () {
      expect(AppSettings.defaultItechAttributionText,
          equals('تم التطوير بواسطة I Tech للتكنولوجيا'));
    });
  });
}
