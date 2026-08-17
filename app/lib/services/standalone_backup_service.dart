import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_role.dart';
import 'permissions.dart';

class StandaloneBackupException implements Exception {
  final String reason;
  const StandaloneBackupException(this.reason);
  String get message => 'فشل إنشاء النسخة الاحتياطية: $reason';
  @override
  String toString() => 'StandaloneBackupException: $reason';
}

class StandaloneBackupReport {
  final DateTime timestamp;
  final String backupPath;
  final int fileSize;
  final int tableCount;

  const StandaloneBackupReport({
    required this.timestamp,
    required this.backupPath,
    required this.fileSize,
    required this.tableCount,
  });
}

class StandaloneBackupService {
  StandaloneBackupService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<StandaloneBackupReport> createBackup({
    required String destinationDirectory,
    required UserRole? actorRole,
  }) async {
    if (actorRole != UserRole.owner) {
      throw const PermissionDeniedException(
          'النسخ الاحتياطي مخصص لمالك المتجر فقط.');
    }

    try {
      final directory = Directory(destinationDirectory);
      if (!directory.existsSync()) {
        throw const StandaloneBackupException(
            'مجلد النسخة الاحتياطية غير موجود.');
      }

      final db = await _databaseHelper.database;
      final timestamp = DateTime.now();
      final timestampStr = timestamp
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final backupPath =
          '${directory.path}${Platform.pathSeparator}muaman_backup_$timestampStr.db';

      await db.execute("VACUUM INTO '${_escapeSqlLiteral(backupPath)}'");

      final backupFile = File(backupPath);
      if (!backupFile.existsSync() || backupFile.lengthSync() == 0) {
        throw const StandaloneBackupException(
            'ملف النسخة الاحتياطية غير موجود أو فارغ.');
      }

      final tableCount = await _verifyBackup(backupPath);
      final fileSize = backupFile.lengthSync();

      return StandaloneBackupReport(
        timestamp: timestamp,
        backupPath: backupPath,
        fileSize: fileSize,
        tableCount: tableCount,
      );
    } on StandaloneBackupException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    } catch (e) {
      throw StandaloneBackupException('$e');
    }
  }

  Future<int> _verifyBackup(String backupPath) async {
    Database? snapshotDb;
    try {
      snapshotDb = await openDatabase(backupPath, readOnly: true);
      final integrity = await snapshotDb.rawQuery('PRAGMA integrity_check');
      final result = integrity.first.values.first.toString().toLowerCase();
      if (result != 'ok') {
        throw const StandaloneBackupException(
            'النسخة الاحتياطية تالفة.');
      }
      final count = await snapshotDb.rawQuery(
          'SELECT COUNT(*) AS c FROM sqlite_master WHERE type = ?', ['table']);
      final tables = (count.first['c'] as num?)?.toInt() ?? 0;
      if (tables == 0) {
        throw const StandaloneBackupException(
            'النسخة الاحتياطية بدون جداول.');
      }
      return tables;
    } on StandaloneBackupException {
      rethrow;
    } catch (e) {
      throw StandaloneBackupException(
          'لا يمكن فتح النسخة الاحتياطية: $e');
    } finally {
      await snapshotDb?.close();
    }
  }

  String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");
}
