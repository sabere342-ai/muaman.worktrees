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

  group('Brand Color - default', () {
    test('returns default #0D47A1 when no brandColor key exists', () async {
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('returns default after initializeDefaults is called', () async {
      await AppSettings.initializeDefaults();
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });
  });

  group('Brand Color - persistence', () {
    test('set and get brand color returns same value', () async {
      await AppSettings.setBrandColor('#1B5E20');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#1B5E20'));
    });

    test('normalizes color without hash prefix', () async {
      await AppSettings.setBrandColor('6A1B9A');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#6A1B9A'));
    });

    test('persists across multiple reads', () async {
      await AppSettings.setBrandColor('#E65100');
      final color1 = await AppSettings.getBrandColor();
      final color2 = await AppSettings.getBrandColor();
      expect(color1, equals('#E65100'));
      expect(color2, equals('#E65100'));
    });

    test('overwrites previous value', () async {
      await AppSettings.setBrandColor('#1B5E20');
      await AppSettings.setBrandColor('#B71C1C');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#B71C1C'));
    });
  });

  group('Brand Color - malformed value fallback', () {
    test('returns default for empty string value', () async {
      await AppSettings.setValue(AppSettings.keyBrandColor, '');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('returns default for invalid hex string', () async {
      await AppSettings.setValue(AppSettings.keyBrandColor, 'invalid');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('returns default for partial hex', () async {
      await AppSettings.setValue(AppSettings.keyBrandColor, '0D4');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('returns default for too-long hex', () async {
      await AppSettings.setValue(AppSettings.keyBrandColor, '#0D47A1FF00FF');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('no crash on garbage value', () async {
      await AppSettings.setValue(AppSettings.keyBrandColor, '!@#\$%^&*()');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });
  });

  group('Brand Color - legacy behavior', () {
    test('works when brandColor key was never created', () async {
      final rows = await testDb.query('app_settings',
          where: 'key = ?', whereArgs: [AppSettings.keyBrandColor]);
      expect(rows, isEmpty);
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });

    test('initializeDefaults does not overwrite existing brand color',
        () async {
      await AppSettings.setBrandColor('#1B5E20');
      await AppSettings.initializeDefaults();
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#1B5E20'));
    });
  });

  group('Brand Color - valid formats', () {
    test('accepts 6-digit hex with hash', () async {
      await AppSettings.setBrandColor('#00695C');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#00695C'));
    });

    test('accepts 6-digit hex without hash', () async {
      await AppSettings.setBrandColor('283593');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#283593'));
    });

    test('accepts 8-digit hex with hash and normalizes to 6-digit', () async {
      await AppSettings.setBrandColor('#FF0D47A1');
      final color = await AppSettings.getBrandColor();
      expect(color, equals('#0D47A1'));
    });
  });
}
