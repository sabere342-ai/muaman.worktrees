import 'dart:io';
import 'dart:async';

import 'package:crypto/crypto.dart' as crypto;
import 'package:sqflite/sqflite.dart';

/// Result of a verified snapshot: pinned path + SHA-256 + integrity verdict.
class VerifiedSnapshot {
  final String path;
  final String sha256;
  final bool integrityOk;
  final int fileSize;

  const VerifiedSnapshot({
    required this.path,
    required this.sha256,
    required this.integrityOk,
    required this.fileSize,
  });
}

class SnapshotException implements Exception {
  final String message;
  const SnapshotException(this.message);

  @override
  String toString() => 'SnapshotException: $message';
}

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? value;

  @override
  void add(crypto.Digest data) => value = data;

  @override
  void close() {}
}

/// Phase I / D2 + D11 + D16 snapshot machinery.
///
/// The migration NEVER reads the live file during import: an owner-triggered
/// `VACUUM INTO` snapshot is taken (online, consistent, WAL-safe — same
/// mechanism as StandaloneBackupService but independent of its v7/v8 restore
/// gate, which remains a documented deferred defect), then verified with
/// `PRAGMA integrity_check` and pinned by SHA-256 before any phase starts.
class LegacySnapshotService {
  const LegacySnapshotService();

  /// Creates and verifies a fresh snapshot of [liveDb] inside
  /// [destinationDirectory]. Throws [SnapshotException] on any failure.
  Future<VerifiedSnapshot> createVerifiedSnapshot({
    required Database liveDb,
    required String destinationDirectory,
    required String fileBaseName,
  }) async {
    final directory = Directory(destinationDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    // NOTE: interpolate directory.path — interpolating the Directory object
    // itself would embed "Directory: '<path>'" into the SQL literal.
    final path =
        '${directory.path}${Platform.pathSeparator}${fileBaseName}_$timestamp.db';

    try {
      await liveDb.execute("VACUUM INTO '${_escape(path)}'");
    } catch (e) {
      throw SnapshotException('فشل إنشاء لقطة قاعدة البيانات: $e');
    }

    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw const SnapshotException('ملف اللقطة غير موجود أو فارغ.');
    }

    if (!await verifyPinnedSnapshot(
        path: path, expectedSha256: await hashFile(path))) {
      throw const SnapshotException('اللقطة تالفة (integrity_check فشل).');
    }

    return VerifiedSnapshot(
      path: path,
      sha256: await hashFile(path),
      integrityOk: true,
      fileSize: file.lengthSync(),
    );
  }

  /// Re-verifies an existing snapshot on resume (D12): file present,
  /// integrity ok. Hash equality is checked by the caller against the pin.
  Future<bool> integrityCheck(String path) async {
    Database? db;
    try {
      db = await openDatabase(path, readOnly: true);
      final result = await db.rawQuery('PRAGMA integrity_check');
      final verdict = result.first.values.first.toString().toLowerCase();
      return verdict == 'ok';
    } catch (_) {
      return false;
    } finally {
      await db?.close();
    }
  }

  /// Full re-verification used on resume (D12): exists + hash pin matches +
  /// integrity ok.
  Future<bool> verifyPinnedSnapshot({
    required String path,
    required String expectedSha256,
  }) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    if (await hashFile(path) != expectedSha256) return false;
    return integrityCheck(path);
  }

  /// Streams the file so large stores don't need to fit in memory.
  Future<String> hashFile(String path) async {
    final sink = _DigestSink();
    final converter = crypto.sha256.startChunkedConversion(sink);
    await for (final chunk in File(path).openRead()) {
      converter.add(chunk);
    }
    converter.close();
    return sink.value!.toString();
  }

  /// Opens a read-only handle used by census/reconciliation to read the
  /// authoritative source (D2: all reads come from the snapshot).
  Future<Database> openReadOnly(String path) =>
      openDatabase(path, readOnly: true);

  String _escape(String value) => value.replaceAll("'", "''");
}
