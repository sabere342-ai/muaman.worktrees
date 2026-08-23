import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'conflict_audit_record.dart';
import 'sync_status.dart';

/// Durable access to the Phase M v15 `conflict_audit` table (plan §21).
///
/// Audit rows are append/transition-only evidence (AU-1): queue cleanup
/// CANNOT remove them (INV-M18). Every lifecycle transition can run inside
/// the caller's transaction via [executor] so the audit write and its cause
/// (queue transition, resolution apply) commit or roll back together
/// (INV-M17, plan §24 window E/G).
class ConflictAuditRepository {
  final Database _db;

  ConflictAuditRepository(this._db);

  /// Records a newly detected conflict. Returns the audit row id.
  /// The record is written BEFORE the queue entry transitions (OF-4); when
  /// both must be atomic, pass the open transaction as [executor].
  Future<int> recordConflict({
    required String shopId,
    required String entityType,
    required int entityId,
    required String operation,
    String? entityUuid,
    String? productName,
    String? productBarcode,
    Map<String, dynamic>? localBefore,
    Map<String, dynamic>? localAfter,
    Map<String, dynamic>? serverBefore,
    Map<String, dynamic>? serverAfter,
    List<String> relatedEventIds = const [],
    int? localVersion,
    int? serverVersion,
    String? idempotencyKey,
    DatabaseExecutor? executor,
  }) async {
    final target = executor ?? _db;
    return target.insert('conflict_audit', {
      'shop_id': shopId,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_uuid': entityUuid,
      'product_name': productName,
      'product_barcode': productBarcode,
      'operation': operation,
      'local_before': localBefore == null ? null : jsonEncode(localBefore),
      'local_after': localAfter == null ? null : jsonEncode(localAfter),
      'server_before': serverBefore == null ? null : jsonEncode(serverBefore),
      'server_after': serverAfter == null ? null : jsonEncode(serverAfter),
      'related_event_ids':
          relatedEventIds.isEmpty ? null : jsonEncode(relatedEventIds),
      'local_version': localVersion,
      'server_version': serverVersion,
      'idempotency_key': idempotencyKey,
      'detected_at': DateTime.now().toUtc().toIso8601String(),
      'status': ConflictLifecycleStatus.REVIEW_REQUIRED.label,
    });
  }

  Future<ConflictAuditRecord?> getById(int id) async {
    final rows = await _db.query('conflict_audit',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ConflictAuditRecord.fromMap(rows.first);
  }

  /// Open (non-terminal) conflicts for a shop, oldest detection first.
  Future<List<ConflictAuditRecord>> getOpenConflicts({String? shopId}) async {
    return _query(
      "status IN ('REVIEW_REQUIRED', 'RESOLUTION_PENDING')",
      shopId: shopId,
      orderBy: 'detected_at ASC, id ASC',
    );
  }

  Future<List<ConflictAuditRecord>> getByShop(String shopId) =>
      _query('shop_id = ?',
          shopId: null, orderBy: 'detected_at DESC, id DESC', args: [shopId]);

  Future<List<ConflictAuditRecord>> getByIdempotencyKey(
      String idempotencyKey) async {
    final rows = await _db.query('conflict_audit',
        where: 'idempotency_key = ?',
        whereArgs: [idempotencyKey],
        orderBy: 'detected_at ASC, id ASC');
    return rows.map(ConflictAuditRecord.fromMap).toList();
  }

  Future<int> getOpenConflictCount({String? shopId}) async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) AS count FROM conflict_audit "
      "WHERE status IN ('REVIEW_REQUIRED', 'RESOLUTION_PENDING')"
      "${shopId != null ? ' AND shop_id = ?' : ''}",
      shopId != null ? [shopId] : null,
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// REVIEW_REQUIRED → RESOLUTION_PENDING (owner chose an action).
  Future<void> markResolutionPending(int id, {DatabaseExecutor? executor}) =>
      _transitionStatus(id, ConflictLifecycleStatus.RESOLUTION_PENDING,
          executor: executor);

  /// → RESOLVED terminal state carrying who/when/how (CL-3).
  Future<void> markResolved(
    int id, {
    required ConflictResolutionMethod method,
    required String resolvedByUser,
    String? note,
    int? resultingAdjustmentId,
    DatabaseExecutor? executor,
  }) async {
    final target = executor ?? _db;
    final count = await target.update(
      'conflict_audit',
      {
        'status': ConflictLifecycleStatus.RESOLVED.label,
        'resolution_method': method.label,
        'resolved_by_user': resolvedByUser,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        if (note != null) 'resolution_note': note,
        if (resultingAdjustmentId != null)
          'resulting_adjustment_id': resultingAdjustmentId,
      },
      where: 'id = ? AND status != ?',
      whereArgs: [id, ConflictLifecycleStatus.RESOLVED.label],
    );
    if (count == 0) {
      throw StateError('conflict_audit row $id is already RESOLVED');
    }
  }

  Future<List<ConflictAuditRecord>> _query(
    String where, {
    String? shopId,
    required String orderBy,
    List<Object?> args = const [],
  }) async {
    final merged = [...args, if (shopId != null) shopId];
    final clause = shopId != null ? '$where AND shop_id = ?' : where;
    final rows = await _db.query('conflict_audit',
        where: clause, whereArgs: merged, orderBy: orderBy);
    return rows.map(ConflictAuditRecord.fromMap).toList();
  }

  Future<void> _transitionStatus(int id, ConflictLifecycleStatus next,
      {DatabaseExecutor? executor}) async {
    await (executor ?? _db).update(
      'conflict_audit',
      {'status': next.label},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
