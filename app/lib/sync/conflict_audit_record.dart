import 'dart:convert';

import '../sync/sync_status.dart';

/// Typed view of one `conflict_audit` row (Phase M plan §21 / AU-2).
///
/// Carries both worlds' beliefs, the versions in play, the related financial
/// event references and the full resolution trail — enough evidence to prove
/// what happened, where, to which product, and how it was settled.
class ConflictAuditRecord {
  final int id;
  final String shopId;
  final String entityType;
  final int entityId;
  final String? entityUuid;
  final String? productName;
  final String? productBarcode;
  final String operation;
  final Map<String, dynamic>? localBefore;
  final Map<String, dynamic>? localAfter;
  final Map<String, dynamic>? serverBefore;
  final Map<String, dynamic>? serverAfter;
  final List<String> relatedEventIds;
  final int? localVersion;
  final int? serverVersion;
  final String? idempotencyKey;
  final DateTime detectedAt;
  final ConflictLifecycleStatus status;
  final ConflictResolutionMethod? resolutionMethod;
  final String? resolvedByUser;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final int? resultingAdjustmentId;

  bool get isTerminal => status == ConflictLifecycleStatus.RESOLVED;

  ConflictAuditRecord({
    required this.id,
    required this.shopId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.detectedAt,
    required this.status,
    this.entityUuid,
    this.productName,
    this.productBarcode,
    this.localBefore,
    this.localAfter,
    this.serverBefore,
    this.serverAfter,
    this.relatedEventIds = const [],
    this.localVersion,
    this.serverVersion,
    this.idempotencyKey,
    this.resolutionMethod,
    this.resolvedByUser,
    this.resolvedAt,
    this.resolutionNote,
    this.resultingAdjustmentId,
  });

  factory ConflictAuditRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? decodeJson(String? raw) =>
        raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;

    return ConflictAuditRecord(
      id: map['id'] as int,
      shopId: map['shop_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      entityUuid: map['entity_uuid'] as String?,
      productName: map['product_name'] as String?,
      productBarcode: map['product_barcode'] as String?,
      operation: map['operation'] as String,
      localBefore: decodeJson(map['local_before'] as String?),
      localAfter: decodeJson(map['local_after'] as String?),
      serverBefore: decodeJson(map['server_before'] as String?),
      serverAfter: decodeJson(map['server_after'] as String?),
      relatedEventIds: map['related_event_ids'] == null
          ? const []
          : (jsonDecode(map['related_event_ids'] as String) as List)
              .cast<String>(),
      localVersion: (map['local_version'] as num?)?.toInt(),
      serverVersion: (map['server_version'] as num?)?.toInt(),
      idempotencyKey: map['idempotency_key'] as String?,
      detectedAt: DateTime.parse(map['detected_at'] as String),
      status: ConflictLifecycleStatus.tryParse(map['status'] as String?) ??
          ConflictLifecycleStatus.REVIEW_REQUIRED,
      resolutionMethod: map['resolution_method'] == null
          ? null
          : ConflictResolutionMethod.values.firstWhere(
              (m) => m.label == map['resolution_method'],
            ),
      resolvedByUser: map['resolved_by_user'] as String?,
      resolvedAt: map['resolved_at'] == null
          ? null
          : DateTime.parse(map['resolved_at'] as String),
      resolutionNote: map['resolution_note'] as String?,
      resultingAdjustmentId: (map['resulting_adjustment_id'] as num?)?.toInt(),
    );
  }
}
