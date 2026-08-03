import 'dart:io';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';

class AppSettings {
  static const String _tableName = 'app_settings';

  static const String keyButtonStyle = 'buttonStyle';
  static const String keySupportPhone = 'supportPhone';
  static const String keyLicenseKey = 'licenseKey';
  static const String keyLicenseStatus = 'licenseStatus';
  static const String keyDefaultCustomerName = 'defaultCustomerName';
  static const String keyWorkbookPath = 'workbookPath';
  static const String defaultSupportPhone = '+201014900211';
  static const String defaultCustomerName = 'عميل نقدي';
  static const String defaultButtonStyle = 'filled';

  static const List<String> buttonStyles = ['filled', 'outlined'];

  static Future<void> initializeDefaults() async {
    final db = await DatabaseHelper.instance.database;
    await _createDefaultIfMissing(db, keyButtonStyle, defaultButtonStyle);
    await _createDefaultIfMissing(db, keySupportPhone, defaultSupportPhone);
    await _createDefaultIfMissing(
        db, keyDefaultCustomerName, defaultCustomerName);
    await _createDefaultIfMissing(db, keyLicenseStatus, 'inactive');
  }

  static Future<void> _createDefaultIfMissing(
      dynamic db, String key, String value) async {
    final existing = await db.query(_tableName,
        columns: ['value'], where: 'key = ?', whereArgs: [key]);
    if (existing.isEmpty) {
      await db.insert(_tableName, {'key': key, 'value': value});
    }
  }

  static Future<String> getValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_tableName,
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return '';
    return rows.first['value'] as String;
  }

  static Future<void> setValue(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(_tableName,
        columns: ['key'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (existing.isEmpty) {
      await db.insert(_tableName, {'key': key, 'value': value});
    } else {
      await db.update(_tableName, {'value': value},
          where: 'key = ?', whereArgs: [key]);
    }
  }

  static Future<String> getButtonStyle() async {
    final value = await getValue(keyButtonStyle);
    return buttonStyles.contains(value) ? value : defaultButtonStyle;
  }

  static Future<String> getSupportPhone() async {
    final value = await getValue(keySupportPhone);
    return value.isNotEmpty ? value : defaultSupportPhone;
  }

  static Future<String> getDefaultCustomerName() async {
    final value = await getValue(keyDefaultCustomerName);
    return value.isNotEmpty ? value : defaultCustomerName;
  }

  static Future<String> getLicenseKey() async {
    return await getValue(keyLicenseKey);
  }

  static Future<String> getLicenseStatus() async {
    final value = await getValue(keyLicenseStatus);
    return value.isNotEmpty ? value : 'inactive';
  }

  static Future<String> getWorkbookPath() async {
    final storedPath = await getValue(keyWorkbookPath);
    if (storedPath.isNotEmpty && File(storedPath).existsSync()) {
      return storedPath;
    }
    return getDefaultWorkbookPath();
  }

  static Future<void> setWorkbookPath(String path) async {
    await setValue(keyWorkbookPath, path);
  }

  static Future<bool> validateLicenseKey(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return false;
    if (normalized.startsWith('MUAMAN-') && normalized.length >= 12) {
      await setValue(keyLicenseKey, normalized);
      await setValue(keyLicenseStatus, 'active');
      return true;
    }
    return false;
  }

  static Future<String> getDefaultWorkbookPath() async {
    const fileName = 'شيت_ادارة_محل_مؤمن_شهر8.xlsx';
    const monthFolder = 'شهر 8';

    final searchRoots = <String>{};
    var current = Directory.current;
    for (var i = 0; i < 4; i++) {
      searchRoots.add(current.path);
      current = current.parent;
    }

    final exeDir = Directory(Platform.resolvedExecutable).parent;
    current = exeDir;
    for (var i = 0; i < 4; i++) {
      searchRoots.add(current.path);
      current = current.parent;
    }

    for (final root in searchRoots) {
      final candidate = File(path.join(root, fileName));
      if (candidate.existsSync()) {
        return candidate.path;
      }
      final nestedCandidate = File(path.join(root, monthFolder, fileName));
      if (nestedCandidate.existsSync()) {
        return nestedCandidate.path;
      }
    }

    return '';
  }
}
