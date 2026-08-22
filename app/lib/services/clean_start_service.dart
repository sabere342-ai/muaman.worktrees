import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_role.dart';
import 'active_shop_context.dart';
import 'permissions.dart';

/// Thrown when the owner-typed confirmation phrase does not match the required
/// phrase. Nothing is deleted.
class CleanStartConfirmationException implements Exception {
  const CleanStartConfirmationException();

  String get message => 'عبارة التأكيد غير صحيحة. لم يتم مسح أي بيانات.';

  @override
  String toString() => 'CleanStartConfirmationException: $message';
}

/// Thrown when the mandatory backup snapshot cannot be created or verified.
/// The wipe is aborted before any row is deleted (fail-closed).
class CleanStartBackupFailedException implements Exception {
  final String reason;

  const CleanStartBackupFailedException(this.reason);

  String get message => 'فشل إنشاء النسخة الاحتياطية قبل المسح: $reason';

  @override
  String toString() => 'CleanStartBackupFailedException: $reason';
}

/// Report of a successful clean-start wipe.
class CleanStartReport {
  final DateTime timestamp;
  final String backupPath;
  final Map<String, int> deletedCounts;

  /// Non-null when the wipe was scoped to a single cloud shop (Phase J Z-3
  /// default: while strict tenant isolation is armed with an authorized shop
  /// context, only that shop's tenant rows are wiped). Null = global wipe
  /// (owner-gated destructive action, unchanged legacy behavior).
  final String? wipedShopId;

  const CleanStartReport({
    required this.timestamp,
    required this.backupPath,
    required this.deletedCounts,
    this.wipedShopId,
  });
}

/// Commissioning / clean-start flow (MUAMAN-19).
///
/// Fail-closed gates, all enforced in the service (data boundary), never only
/// in the UI:
///   1. Owner-only: a non-owner actor always gets [PermissionDeniedException].
///   2. Explicit confirmation: the owner must type the exact confirmation
///      phrase; a mismatch aborts before anything is touched.
///   3. Mandatory backup snapshot: a consistent SQLite snapshot is written and
///      verified before the wipe; if it cannot be created/read, the wipe is
///      aborted with nothing deleted.
///   4. Transactional wipe: all deletions happen inside one database
///      transaction, so a mid-wipe failure rolls the whole wipe back.
///
/// Scope: transactional data only (products, sales, returns, expenses,
/// inventory_count, invoices, import_batches). Users, role permissions and
/// app settings (including the shop identity) are preserved.
class CleanStartService {
  CleanStartService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// The exact phrase an owner must type to authorize a wipe.
  static const String confirmationPhrase = 'مسح البيانات';

  /// Tables whose rows are wiped. Order does not matter because the deletion
  /// runs inside a single transaction and is all-or-nothing.
  static const List<String> transactionalTables = [
    'inventory_count',
    'sales',
    'returns',
    'expenses',
    'invoices',
    'import_batches',
    'products',
    'expense_categories',
    'customers',
  ];

  /// Tables that must survive the wipe untouched.
  static const Set<String> preservedTables = {
    'users',
    'role_permissions',
    'app_settings',
  };

  Future<CleanStartReport> run({
    required UserRole? actorRole,
    required String backupDirectory,
    required String confirmation,
  }) async {
    _requireOwner(actorRole);
    _requireConfirmation(confirmation);

    final backupPath = await _createBackupSnapshot(backupDirectory);
    final db = await _databaseHelper.database;

    // Phase J (Z-3 default): when strict tenant isolation is armed with an
    // authorized shop context the wipe is scoped to THAT shop's rows only.
    // Without a cloud tenant context the wipe remains the legacy global
    // destructive owner action. System tables are preserved in both modes.
    final shopId = DatabaseHelper.tenantIsolationArmed
        ? ActiveShopContext.instance.shopId
        : null;

    final deletedCounts = <String, int>{};
    await db.transaction((txn) async {
      for (final table in transactionalTables) {
        if (shopId != null && shopId.isNotEmpty) {
          deletedCounts[table] =
              await txn.delete(table, where: 'shop_id = ?', whereArgs: [shopId]);
        } else {
          deletedCounts[table] = await txn.delete(table);
        }
      }
    });

    return CleanStartReport(
      timestamp: DateTime.now(),
      backupPath: backupPath,
      deletedCounts: deletedCounts,
      wipedShopId: (shopId != null && shopId.isNotEmpty) ? shopId : null,
    );
  }

  void _requireOwner(UserRole? actorRole) {
    if (actorRole != UserRole.owner) {
      throw const PermissionDeniedException(
          'مسح البيانات والبدء من جديد مخصص لمالك المتجر فقط.');
    }
  }

  void _requireConfirmation(String confirmation) {
    if (confirmation.trim() != confirmationPhrase) {
      throw const CleanStartConfirmationException();
    }
  }

  /// Writes a consistent SQLite snapshot of the open database to
  /// [backupDirectory] and verifies it is readable before the wipe starts.
  Future<String> _createBackupSnapshot(String backupDirectory) async {
    try {
      final directory = Directory(backupDirectory);
      await directory.create(recursive: true);

      final db = await _databaseHelper.database;
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final backupPath =
          '${directory.path}${Platform.pathSeparator}muaman_cleanstart_$timestamp.db';

      if (File(backupPath).existsSync()) {
        await File(backupPath).delete();
      }

      await db.execute("VACUUM INTO '${_escapeSqlLiteral(backupPath)}'");

      final backupFile = File(backupPath);
      if (!backupFile.existsSync() || backupFile.lengthSync() == 0) {
        throw const CleanStartBackupFailedException(
            'ملف النسخة الاحتياطية غير موجود أو فارغ');
      }

      await _verifyBackup(backupPath);
      return backupPath;
    } on CleanStartBackupFailedException {
      rethrow;
    } catch (e) {
      throw CleanStartBackupFailedException('$e');
    }
  }

  /// Opens the snapshot with a fresh, independent connection and proves it is a
  /// valid, restorable SQLite database (integrity check + a real read) before
  /// any row is deleted. Fails closed on any error.
  Future<void> _verifyBackup(String backupPath) async {
    Database? snapshotDb;
    try {
      snapshotDb = await openDatabase(backupPath, readOnly: true);
      final integrity = await snapshotDb.rawQuery('PRAGMA integrity_check');
      final result = integrity.first.values.first.toString().toLowerCase();
      if (result != 'ok') {
        throw const CleanStartBackupFailedException('النسخة الاحتياطية تالفة');
      }
      final count = await snapshotDb.rawQuery(
          'SELECT COUNT(*) AS c FROM sqlite_master WHERE type = ?', ['table']);
      final tables = (count.first['c'] as num?)?.toInt() ?? 0;
      if (tables == 0) {
        throw const CleanStartBackupFailedException(
            'النسخة الاحتياطية بدون جداول');
      }
    } on CleanStartBackupFailedException {
      rethrow;
    } catch (e) {
      throw CleanStartBackupFailedException(
          'لا يمكن فتح النسخة الاحتياطية: $e');
    } finally {
      await snapshotDb?.close();
    }
  }

  String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");
}
