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
  static const String keyBrandColor = 'brandColor';
  static const String keyInvoiceTitle = 'invoiceTitle';
  static const String keyInvoiceFooterText = 'invoiceFooterText';
  static const String keyBackupDirectory = 'backupDirectory';
  static const String keyThermalPrinterName = 'thermalPrinterName';
  static const String keyThermalPaperWidth = 'thermalPaperWidth';
  static const String keyThermalPrintCopies = 'thermalPrintCopies';
  static const String defaultSupportPhone = '+201014900211';
  static const String defaultCustomerName = 'عميل نقدي';
  static const String defaultButtonStyle = 'filled';
  static const String defaultBrandColor = '#0D47A1';
  static const String defaultInvoiceTitle = 'فاتورة بيع';
  static const String defaultInvoiceFooterText = 'شكراً لتعاملكم معنا';
  static const String defaultThermalPaperWidth = '80';
  static const String defaultThermalPrintCopies = '1';

  static const List<String> buttonStyles = ['filled', 'outlined'];

  static Future<void> initializeDefaults() async {
    final db = await DatabaseHelper.instance.database;
    await _createDefaultIfMissing(db, keyButtonStyle, defaultButtonStyle);
    await _createDefaultIfMissing(db, keySupportPhone, defaultSupportPhone);
    await _createDefaultIfMissing(
        db, keyDefaultCustomerName, defaultCustomerName);
    await _createDefaultIfMissing(db, keyLicenseStatus, 'inactive');
    await _createDefaultIfMissing(db, keyBrandColor, defaultBrandColor);
    await _createDefaultIfMissing(db, keyInvoiceTitle, defaultInvoiceTitle);
    await _createDefaultIfMissing(
        db, keyInvoiceFooterText, defaultInvoiceFooterText);
    await _createDefaultIfMissing(
        db, keyThermalPaperWidth, defaultThermalPaperWidth);
    await _createDefaultIfMissing(
        db, keyThermalPrintCopies, defaultThermalPrintCopies);
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
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : defaultSupportPhone;
  }

  static Future<String> getDefaultCustomerName() async {
    final value = await getValue(keyDefaultCustomerName);
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : defaultCustomerName;
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

  static Future<String> getInvoiceTitle() async {
    final value = await getValue(keyInvoiceTitle);
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : defaultInvoiceTitle;
  }

  static Future<String> getInvoiceFooterText() async {
    final value = await getValue(keyInvoiceFooterText);
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : defaultInvoiceFooterText;
  }

  static Future<String> getThermalPrinterName() async {
    return await getValue(keyThermalPrinterName);
  }

  static Future<void> setThermalPrinterName(String name) async {
    await setValue(keyThermalPrinterName, name.trim());
  }

  static Future<int> getThermalPaperWidth() async {
    final value = await getValue(keyThermalPaperWidth);
    final parsed = int.tryParse(value);
    if (parsed != null && (parsed == 80 || parsed == 58)) return parsed;
    return int.parse(defaultThermalPaperWidth);
  }

  static Future<void> setThermalPaperWidth(int width) async {
    await setValue(keyThermalPaperWidth, '$width');
  }

  static Future<int> getThermalPrintCopies() async {
    final value = await getValue(keyThermalPrintCopies);
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 1 && parsed <= 10) return parsed;
    return int.parse(defaultThermalPrintCopies);
  }

  static Future<void> setThermalPrintCopies(int copies) async {
    final safe = copies.clamp(1, 10);
    await setValue(keyThermalPrintCopies, '$safe');
  }

  static Future<String> getBrandColor() async {
    final value = await getValue(keyBrandColor);
    if (value.isEmpty) return defaultBrandColor;
    try {
      var hex = value.replaceFirst('#', '');
      if (hex.length == 6) {
        int.parse(hex, radix: 16);
        return '#$hex';
      }
      if (hex.length == 8) {
        int.parse(hex, radix: 16);
        return '#${hex.substring(2)}';
      }
      return defaultBrandColor;
    } catch (_) {
      return defaultBrandColor;
    }
  }

  static Future<void> setBrandColor(String hex) async {
    final normalized = hex.startsWith('#') ? hex : '#$hex';
    await setValue(keyBrandColor, normalized);
  }

  static Future<String> getBackupDirectory() async {
    final storedPath = await getValue(keyBackupDirectory);
    if (storedPath.isNotEmpty && Directory(storedPath).existsSync()) {
      return storedPath;
    }
    return '';
  }

  static Future<void> setBackupDirectory(String dirPath) async {
    await setValue(keyBackupDirectory, dirPath);
  }

  static Future<String> getDefaultWorkbookPath() async {
    const fileName = 'شيت_ادارة_محل_شهر8.xlsx';
    const legacyFileName = 'شيت_ادارة_محل_مؤمن_شهر8.xlsx';
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
      for (final name in [fileName, legacyFileName]) {
        final candidate = File(path.join(root, name));
        if (candidate.existsSync()) {
          return candidate.path;
        }
        final nestedCandidate = File(path.join(root, monthFolder, name));
        if (nestedCandidate.existsSync()) {
          return nestedCandidate.path;
        }
      }
    }

    return '';
  }
}
