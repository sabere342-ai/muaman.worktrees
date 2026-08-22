import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Durable access to the Phase I v14 bookkeeping table
/// `legacy_migration_progress` (D8). This local mirror caches checkpoints for
/// resume/UI; it is NEVER authoritative over the cloud migration ledger (D5).
class MigrationProgressRepository {
  final Database _db;

  MigrationProgressRepository(this._db);

  Future<void> insertBatch({
    required String batchId,
    required String shopId,
    required String phase,
    required String status,
    String? snapshotPath,
    String? snapshotSha256,
    Map<String, dynamic>? stats,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert('legacy_migration_progress', {
      'batch_id': batchId,
      'shop_id': shopId,
      'phase': phase,
      'status': status,
      'snapshot_path': snapshotPath,
      'snapshot_sha256': snapshotSha256,
      'stats_json': stats == null ? null : jsonEncode(stats),
      'started_at': now,
      'updated_at': now,
    });
  }

  Future<Map<String, dynamic>?> getBatch(String batchId) async {
    final rows = await _db.query('legacy_migration_progress',
        where: 'batch_id = ?', whereArgs: [batchId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Latest batch for [shopId] whose status is not terminal (D12 resume).
  Future<Map<String, dynamic>?> latestNonTerminalBatch(String shopId) async {
    final rows = await _db.query(
      'legacy_migration_progress',
      where: "shop_id = ? AND status NOT IN ('COMPLETED', 'ABORTED')",
      whereArgs: [shopId],
      orderBy: 'started_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> allBatches() =>
      _db.query('legacy_migration_progress', orderBy: 'started_at DESC');

  /// Persists phase/state/checkpoint/stats. Called inside the same
  /// transaction as chunk confirmations when a transaction handle is given
  /// (D9), so crash recovery resumes from the last durable checkpoint.
  Future<void> updateBatch(
    String batchId, {
    DatabaseExecutor? executor,
    String? phase,
    String? status,
    String? lastTable,
    int? lastLocalId,
    Map<String, dynamic>? stats,
    bool clearCheckpoint = false,
    String? completedAt,
  }) async {
    final target = executor ?? _db;
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (phase != null) values['phase'] = phase;
    if (status != null) values['status'] = status;
    if (clearCheckpoint) {
      values['last_table'] = null;
      values['last_local_id'] = null;
    } else {
      if (lastTable != null) values['last_table'] = lastTable;
      if (lastLocalId != null) values['last_local_id'] = lastLocalId;
    }
    if (stats != null) values['stats_json'] = jsonEncode(stats);
    if (completedAt != null) values['completed_at'] = completedAt;

    await target.update(
      'legacy_migration_progress',
      values,
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  static Map<String, dynamic>? decodeStats(Map<String, dynamic> row) {
    final raw = row['stats_json'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
