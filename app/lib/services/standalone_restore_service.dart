import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_role.dart';
import 'permissions.dart';

class RestoreValidationException implements Exception {
  final String reason;
  const RestoreValidationException(this.reason);
  String get message => 'النسخة الاحتياطية غير صالحة: $reason';
  @override
  String toString() => 'RestoreValidationException: $reason';
}

class RestoreFailedException implements Exception {
  final String reason;
  const RestoreFailedException(this.reason);
  String get message => 'فشلت عملية الاستعادة: $reason';
  @override
  String toString() => 'RestoreFailedException: $reason';
}

class PreSaveBackupFailedException implements Exception {
  final String reason;
  const PreSaveBackupFailedException(this.reason);
  String get message => 'فشل إنشاء النسخة الاحتياطية قبل الاستعادة: $reason';
  @override
  String toString() => 'PreSaveBackupFailedException: $reason';
}

class StandaloneRestoreReport {
  final DateTime timestamp;
  final String restoredFromPath;
  final String preSaveBackupPath;

  const StandaloneRestoreReport({
    required this.timestamp,
    required this.restoredFromPath,
    required this.preSaveBackupPath,
  });
}

class StandaloneRestoreService {
  StandaloneRestoreService({
    DatabaseHelper? databaseHelper,
    String? preSaveDirectory,
    String? databasePathOverride,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _preSaveDirectory = preSaveDirectory,
        _databasePathOverride = databasePathOverride;

  final DatabaseHelper _databaseHelper;
  final String? _preSaveDirectory;
  final String? _databasePathOverride;

  Future<StandaloneRestoreReport> restoreFromBackup({
    required String backupFilePath,
    required UserRole? actorRole,
  }) async {
    if (actorRole != UserRole.owner) {
      throw const PermissionDeniedException(
          'استعادة البيانات مخصصة لمالك المتجر فقط.');
    }

    await _validateBackup(backupFilePath);
    final preSavePath = await _createPreSaveBackup();
    try {
      await _performRestore(backupFilePath);
      return StandaloneRestoreReport(
        timestamp: DateTime.now(),
        restoredFromPath: backupFilePath,
        preSaveBackupPath: preSavePath,
      );
    } on RestoreFailedException {
      rethrow;
    }
  }

  Future<void> _validateBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (!file.existsSync()) {
      throw const RestoreValidationException(
          'ملف النسخة الاحتياطية غير موجود.');
    }
    if (file.lengthSync() == 0) {
      throw const RestoreValidationException('ملف النسخة الاحتياطية فارغ.');
    }

    Database? testDb;
    try {
      testDb = await openDatabase(backupFilePath, readOnly: true);

      final integrity = await testDb.rawQuery('PRAGMA integrity_check');
      final result = integrity.first.values.first.toString().toLowerCase();
      if (result != 'ok') {
        throw const RestoreValidationException('النسخة الاحتياطية تالفة.');
      }

      final versionRows = await testDb.rawQuery('PRAGMA user_version');
      final version = (versionRows.first.values.first as num).toInt();
      if (version != 7 && version != 8) {
        throw RestoreValidationException(
            'إصدار قاعدة البيانات غير متوافق: $version (المطلوب 7 أو 8).');
      }

      final expectedTables = [
        'products',
        'sales',
        'returns',
        'expenses',
        'inventory_count',
        'invoices',
        'import_batches',
        'users',
        'role_permissions',
        'app_settings',
        'expense_categories',
      ];
      if (version >= 8) {
        expectedTables.add('customers');
      }
      for (final table in expectedTables) {
        final result = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
            [table]);
        if (result.isEmpty) {
          throw RestoreValidationException(
              'الجدول $table مفقود في النسخة الاحتياطية.');
        }
      }
    } on RestoreValidationException {
      rethrow;
    } catch (e) {
      throw RestoreValidationException(
          'لا يمكن التحقق من النسخة الاحتياطية: $e');
    } finally {
      await testDb?.close();
    }
  }

  Future<String> _createPreSaveBackup() async {
    try {
      final db = await _databaseHelper.database;
      final dir = _preSaveDirectory;
      final String dbDir;
      if (dir != null) {
        dbDir = dir;
      } else {
        final dbPath = await _databaseHelper.databasePath;
        dbDir = Directory(dbPath).parent.path;
      }
      await Directory(dbDir).create(recursive: true);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final preSavePath =
          '$dbDir${Platform.pathSeparator}muaman_presave_$timestamp.db';

      await db.execute("VACUUM INTO '${_escapeSqlLiteral(preSavePath)}'");

      final preSaveFile = File(preSavePath);
      if (!preSaveFile.existsSync() || preSaveFile.lengthSync() == 0) {
        throw const PreSaveBackupFailedException(
            'ملف النسخة الاحتياطية قبل الاستعادة غير موجود أو فارغ.');
      }

      return preSavePath;
    } on PreSaveBackupFailedException {
      rethrow;
    } catch (e) {
      throw PreSaveBackupFailedException('$e');
    }
  }

  Future<void> _performRestore(String backupFilePath) async {
    try {
      final dbPath =
          _databasePathOverride ?? await _databaseHelper.databasePath;

      await _databaseHelper.close();

      final backupFile = File(backupFilePath);
      final targetFile = File(dbPath);

      if (targetFile.existsSync()) {
        await targetFile.delete();
      }
      await backupFile.copy(dbPath);

      await _databaseHelper.reopen();

      final db = await _databaseHelper.database;
      final integrity = await db.rawQuery('PRAGMA integrity_check');
      final result = integrity.first.values.first.toString().toLowerCase();
      if (result != 'ok') {
        throw const RestoreFailedException('قاعدة البيانات المستعادة تالفة.');
      }
    } on RestoreFailedException {
      rethrow;
    } catch (e) {
      throw RestoreFailedException('$e');
    }
  }

  String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");
}
