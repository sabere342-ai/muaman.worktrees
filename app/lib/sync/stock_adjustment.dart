import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'sync_status.dart';

/// Lifecycle of one durable local Option C adjustment artifact (P-OD1 local
/// half, Phase P Group A A3).
///
///   OPEN           - recorded, awaiting (or in flight for) server mirroring
///   SYNCED         - the governing server `cloud_stock_adjustments` row was
///                    created (via `create_cloud_stock_adjustment`) and its
///                    uuid adopted locally.
///   RESOLVED       - an owner resolved the discrepancy (still additive; the
///                    artifact and its evidence are never rewritten/deleted).
enum AdjustmentLifecycleStatus {
  OPEN,
  SYNCED,
  RESOLVED;

  String get label => name;

  static AdjustmentLifecycleStatus? tryParse(String? value) {
    if (value == null) return null;
    for (final s in values) {
      if (s.label == value) return s;
    }
    return null;
  }
}

/// Typed view of one `stock_adjustments` row.
class StockAdjustment {
  final int id;
  final String shopId;

  /// Originating local sale (and/or return) event id that caused the
  /// divergence. Kept as references so every outcome stays explainable.
  final int? saleId;
  final int? returnId;

  final String productBarcode;
  final String? productId;

  /// Server-authoritative projected stock after applying ALL preserved
  /// events (negative when an oversell occurred).
  final int projectedCurrent;

  /// How far below zero projected stock fell (= -projected_current when
  /// negative). Strictly positive.
  final int shortfall;

  final List<String> relatedEventIds;

  /// Deterministic adjustment idempotency key, bound durably to the governing
  /// sale/event (never invented on retry).
  final String? idempotencyKey;

  final AdjustmentLifecycleStatus status;

  /// Server `cloud_stock_adjustments` uuid once mirrored.
  final String? cloudUuid;

  final DateTime createdAt;
  final DateTime? resolvedAt;

  StockAdjustment({
    required this.id,
    required this.shopId,
    this.saleId,
    this.returnId,
    required this.productBarcode,
    this.productId,
    required this.projectedCurrent,
    required this.shortfall,
    this.relatedEventIds = const [],
    this.idempotencyKey,
    this.status = AdjustmentLifecycleStatus.OPEN,
    this.cloudUuid,
    required this.createdAt,
    this.resolvedAt,
  });

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int,
      shopId: map['shop_id'] as String,
      saleId: (map['sale_id'] as num?)?.toInt(),
      returnId: (map['return_id'] as num?)?.toInt(),
      productBarcode: map['product_barcode'] as String,
      productId: map['product_id'] as String?,
      projectedCurrent: (map['projected_current'] as num?)?.toInt() ?? 0,
      shortfall: (map['shortfall'] as num?)?.toInt() ?? 0,
      relatedEventIds: map['related_event_ids'] == null
          ? const []
          : (jsonDecode(map['related_event_ids'] as String) as List)
              .cast<String>(),
      idempotencyKey: map['idempotency_key'] as String?,
      status: AdjustmentLifecycleStatus.tryParse(map['status'] as String?) ??
          AdjustmentLifecycleStatus.OPEN,
      cloudUuid: map['cloud_uuid'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      resolvedAt: map['resolved_at'] == null
          ? null
          : DateTime.parse(map['resolved_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'sale_id': saleId,
      'return_id': returnId,
      'product_barcode': productBarcode,
      'product_id': productId,
      'projected_current': projectedCurrent,
      'shortfall': shortfall,
      'related_event_ids':
          relatedEventIds.isEmpty ? null : jsonEncode(relatedEventIds),
      'idempotency_key': idempotencyKey,
      'status': status.label,
      'cloud_uuid': cloudUuid,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}

/// Durable access to the Phase P Group A A3 v18 `stock_adjustments` table.
///
/// The adjustment is ADDITIVE evidence: it is never used to rewrite the
/// preserved sale/return counters or opening quantity (the inventory equation
/// must remain mathematically traceable). Writes participate in the caller's
/// transaction via [executor] (INV-M17) so adjustment + conflict audit +
/// queue state commit or roll back together.
class StockAdjustmentRepository {
  final Database _db;

  StockAdjustmentRepository(this._db);

  /// Persists the adjustment artifact and returns its row id. When
  /// [executor] is provided the insert runs inside the caller's transaction.
  Future<int> insertAdjustment({
    required String shopId,
    int? saleId,
    int? returnId,
    required String productBarcode,
    String? productId,
    required int projectedCurrent,
    required int shortfall,
    List<String> relatedEventIds = const [],
    String? idempotencyKey,
    DatabaseExecutor? executor,
  }) async {
    if (shortfall <= 0) {
      throw StateError('shortfall must be strictly positive, got $shortfall');
    }
    final target = executor ?? _db;
    return target.insert('stock_adjustments', {
      'shop_id': shopId,
      'sale_id': saleId,
      'return_id': returnId,
      'product_barcode': productBarcode,
      'product_id': productId,
      'projected_current': projectedCurrent,
      'shortfall': shortfall,
      'related_event_ids':
          relatedEventIds.isEmpty ? null : jsonEncode(relatedEventIds),
      'idempotency_key': idempotencyKey,
      'status': AdjustmentLifecycleStatus.OPEN.label,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<StockAdjustment?> getById(int id) async {
    final rows = await _db.query('stock_adjustments',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : StockAdjustment.fromMap(rows.first);
  }

  Future<StockAdjustment?> getByIdempotencyKey(String idempotencyKey,
      {DatabaseExecutor? executor}) async {
    final target = executor ?? _db;
    final rows = await target.query('stock_adjustments',
        where: 'idempotency_key = ?', whereArgs: [idempotencyKey], limit: 1);
    return rows.isEmpty ? null : StockAdjustment.fromMap(rows.first);
  }

  Future<List<StockAdjustment>> getOpenAdjustments({String? shopId}) async {
    var where = "status IN ('OPEN','SYNCED')";
    final args = <Object?>[];
    if (shopId != null) {
      where += ' AND shop_id = ?';
      args.add(shopId);
    }
    final rows = await _db.query('stock_adjustments',
        where: where, whereArgs: args, orderBy: 'created_at ASC, id ASC');
    return rows.map(StockAdjustment.fromMap).toList();
  }

  /// Adopts the governing server adjustment uuid once the adjustment sync
  /// drains, inside the caller's transaction.
  Future<void> markSynced(int id, String cloudUuid,
      {DatabaseExecutor? executor}) async {
    await (executor ?? _db).update(
      'stock_adjustments',
      {
        'status': AdjustmentLifecycleStatus.SYNCED.label,
        'cloud_uuid': cloudUuid,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deterministic adjustment idempotency key derived from the governing
  /// event's persisted occurrence token (INV-M19). The SAME logical oversold
  /// event always yields the SAME adjustment key — never invented on retry.
  static String adjustmentKeyFor({
    required SyncEntityType eventType,
    required int localId,
    required String occurrenceToken,
  }) {
    return '${eventType.label}:$localId:ADJUST:$occurrenceToken';
  }
}
