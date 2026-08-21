import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'sync_status.dart';

class SyncQueueEntry {
  final String id;
  final String entityType;
  final int entityId;
  final SyncQueueOperation operation;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final SyncQueueStatus status;
  final String? conflictData;
  final String idempotencyKey;
  final String? shopId;

  SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    required this.createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.status = SyncQueueStatus.PENDING,
    this.conflictData,
    required this.idempotencyKey,
    this.shopId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.label,
      'payload': payload != null ? jsonEncode(payload) : null,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'retry_count': retryCount,
      'status': status.label,
      'conflict_data': conflictData,
      'idempotency_key': idempotencyKey,
      'shop_id': shopId,
    };
  }

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    return SyncQueueEntry(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      operation: SyncQueueOperation.values.firstWhere(
        (o) => o.label == map['operation'],
        orElse: () => SyncQueueOperation.CREATE,
      ),
      payload: map['payload'] != null
          ? jsonDecode(map['payload'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      status: SyncQueueStatus.values.firstWhere(
        (s) => s.label == map['status'],
        orElse: () => SyncQueueStatus.PENDING,
      ),
      conflictData: map['conflict_data'] as String?,
      idempotencyKey: map['idempotency_key'] as String,
      shopId: map['shop_id'] as String?,
    );
  }

  SyncQueueEntry copyWith({
    SyncQueueStatus? status,
    int? retryCount,
    DateTime? syncedAt,
    String? conflictData,
  }) {
    return SyncQueueEntry(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      conflictData: conflictData ?? this.conflictData,
      idempotencyKey: idempotencyKey,
      shopId: shopId,
    );
  }
}

class SyncQueueRepository {
  final Database _db;
  static int _idCounter = 0;

  SyncQueueRepository(this._db);

  /// [executor] lets a caller participate in an open transaction so the
  /// local business write and its queue entry commit or roll back together.
  /// When omitted the repository's root database handle is used.
  Future<void> enqueue({
    required String entityType,
    required int entityId,
    required SyncQueueOperation operation,
    Map<String, dynamic>? payload,
    required String idempotencyKey,
    String? shopId,
    DatabaseExecutor? executor,
  }) async {
    final target = executor ?? _db;
    final existing = await _findByIdempotencyKey(idempotencyKey, executor: target);
    if (existing != null) {
      return;
    }

    await target.insert('sync_queue', {
      'id': _generateId(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.label,
      'payload': payload != null ? jsonEncode(payload) : null,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'status': SyncQueueStatus.PENDING.label,
      'idempotency_key': idempotencyKey,
      'shop_id': shopId,
    });
  }

  Future<List<SyncQueueEntry>> getPendingEntries({String? shopId}) async {
    String whereClause = "status = 'PENDING'";
    List<dynamic> whereArgs = [];

    if (shopId != null) {
      whereClause += ' AND shop_id = ?';
      whereArgs.add(shopId);
    }

    final maps = await _db.query(
      'sync_queue',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SyncQueueEntry.fromMap(m)).toList();
  }

  Future<List<SyncQueueEntry>> getFailedEntries({String? shopId}) async {
    String whereClause = "status = 'FAILED'";
    List<dynamic> whereArgs = [];

    if (shopId != null) {
      whereClause += ' AND shop_id = ?';
      whereArgs.add(shopId);
    }

    final maps = await _db.query(
      'sync_queue',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SyncQueueEntry.fromMap(m)).toList();
  }

  Future<int> getPendingCount({String? shopId}) async {
    String whereClause = "status = 'PENDING'";
    List<dynamic> whereArgs = [];

    if (shopId != null) {
      whereClause += ' AND shop_id = ?';
      whereArgs.add(shopId);
    }

    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE $whereClause',
        whereArgs);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getFailedCount({String? shopId}) async {
    String whereClause = "status = 'FAILED'";
    List<dynamic> whereArgs = [];

    if (shopId != null) {
      whereClause += ' AND shop_id = ?';
      whereArgs.add(shopId);
    }

    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE $whereClause',
        whereArgs);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getConflictCount({String? shopId}) async {
    String whereClause = "status = 'CONFLICT'";
    List<dynamic> whereArgs = [];

    if (shopId != null) {
      whereClause += ' AND shop_id = ?';
      whereArgs.add(shopId);
    }

    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE $whereClause',
        whereArgs);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markSynced(String entryId) async {
    await _db.update(
      'sync_queue',
      {
        'status': SyncQueueStatus.SYNCED.label,
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> markFailed(String entryId) async {
    final maps = await _db.query('sync_queue',
        where: 'id = ?', whereArgs: [entryId], limit: 1);
    if (maps.isEmpty) return;

    final entry = SyncQueueEntry.fromMap(maps.first);
    final newRetryCount = entry.retryCount + 1;

    if (newRetryCount > 5) {
      await _db.update(
        'sync_queue',
        {
          'status': SyncQueueStatus.FAILED.label,
          'retry_count': newRetryCount,
        },
        where: 'id = ?',
        whereArgs: [entryId],
      );
    } else {
      await _db.update(
        'sync_queue',
        {'retry_count': newRetryCount},
        where: 'id = ?',
        whereArgs: [entryId],
      );
    }
  }

  Future<void> markConflict(String entryId, String conflictData) async {
    await _db.update(
      'sync_queue',
      {
        'status': SyncQueueStatus.CONFLICT.label,
        'conflict_data': conflictData,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> retryEntry(String entryId) async {
    await _db.update(
      'sync_queue',
      {
        'status': SyncQueueStatus.PENDING.label,
        'retry_count': 0,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> cleanupSynced({int olderThanDays = 7}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: olderThanDays)).toIso8601String();
    await _db.delete(
      'sync_queue',
      where: "status = 'SYNCED' AND synced_at < ?",
      whereArgs: [cutoff],
    );
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [entryId]);
  }

  Future<SyncQueueEntry?> _findByIdempotencyKey(String key,
      {DatabaseExecutor? executor}) async {
    final maps = await (executor ?? _db).query(
      'sync_queue',
      where: 'idempotency_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SyncQueueEntry.fromMap(maps.first);
  }

  Future<bool> hasPendingForEntity(
      String entityType, int entityId, SyncQueueOperation operation) async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE entity_type = ? AND entity_id = ? AND operation = ? AND status = 'PENDING'",
      [entityType, entityId, operation.label],
    );
    return ((result.first['count'] as num?)?.toInt() ?? 0) > 0;
  }

  String _generateId() {
    _idCounter++;
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'sq-$now-$_idCounter';
  }
}
