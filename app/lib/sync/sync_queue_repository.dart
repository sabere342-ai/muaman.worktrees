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

  /// Phase M: persisted deterministic event identity token (INV-M19).
  /// Null for legacy rows created before schema v15.
  final String? occurrenceToken;

  /// Phase M conflict lifecycle beyond the legacy terminal CONFLICT status
  /// (§20): REVIEW_REQUIRED → RESOLUTION_PENDING → RESOLVED.
  final ConflictLifecycleStatus? resolutionStatus;

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
    this.occurrenceToken,
    this.resolutionStatus,
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
      'occurrence_token': occurrenceToken,
      'resolution_status': resolutionStatus?.label,
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
      occurrenceToken: map.containsKey('occurrence_token')
          ? map['occurrence_token'] as String?
          : null,
      resolutionStatus: map.containsKey('resolution_status')
          ? ConflictLifecycleStatus.tryParse(
              map['resolution_status'] as String?)
          : null,
    );
  }

  SyncQueueEntry copyWith({
    SyncQueueStatus? status,
    int? retryCount,
    DateTime? syncedAt,
    String? conflictData,
    String? occurrenceToken,
    ConflictLifecycleStatus? resolutionStatus,
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
      occurrenceToken: occurrenceToken ?? this.occurrenceToken,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
    );
  }
}

class SyncQueueRepository {
  final Database _db;
  static int _idCounter = 0;

  /// Per-database cache of the sync_queue column set (Phase M).
  ///
  /// Databases migrated/opened at schema v15 always carry
  /// `occurrence_token`/`resolution_status`; pre-v15 shapes (legacy rows,
  /// historical fixtures) do not. Writing those columns only when present
  /// keeps v14-era tables readable/writable without data loss.
  static final Expando<Set<String>> _columnShapeCache = Expando<Set<String>>();

  SyncQueueRepository(this._db);

  /// Resolves (and caches) the physical sync_queue column set. Transactions
  /// share their root database's shape, so results are cached under [_db].
  Future<Set<String>> _syncQueueColumns(DatabaseExecutor target) async {
    final cached = _columnShapeCache[_db];
    if (cached != null) return cached;
    final info = await target.rawQuery('PRAGMA table_info(sync_queue)');
    final columns = info.map((r) => r['name'] as String).toSet();
    _columnShapeCache[_db] = columns;
    return columns;
  }

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
    String? occurrenceToken,
  }) async {
    final target = executor ?? _db;
    final existing =
        await _findByIdempotencyKey(idempotencyKey, executor: target);
    if (existing != null) {
      return;
    }

    final columns = await _syncQueueColumns(target);
    final row = <String, dynamic>{
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
    };
    if (columns.contains('occurrence_token')) {
      row['occurrence_token'] = occurrenceToken;
    }
    if (columns.contains('resolution_status')) {
      row['resolution_status'] = null;
    }
    await target.insert('sync_queue', row);
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
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .toIso8601String();
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
