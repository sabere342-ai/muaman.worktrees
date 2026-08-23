import '../sync_status.dart';

abstract class EntitySyncAdapter {
  SyncEntityType get entityType;

  ConflictResolutionPolicy get conflictPolicy;

  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow);

  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow);

  String getCloudUuid(Map<String, dynamic> localRow);

  int getLocalId(Map<String, dynamic> localRow);

  int getServerVersion(Map<String, dynamic> localRow);

  bool get isServerAuthoritative;

  String get localTableName;

  String get cloudTableName;

  String get requiredPermission;

  /// Event-like entities (sales/returns/invoices/inventory counts) are
  /// immutable observations: never LWW-resolved, replay idempotent.
  bool get isEventLike => entityType.isEventLike;

  /// Device-side operation/writer timestamp of the local row, when the raw
  /// local row carries one. Used by true-LWW conflict comparison.
  String? getLocalUpdatedAt(Map<String, dynamic> localRow) {
    final v = localRow['updatedAt'] ?? localRow['updated_at'];
    return v is String ? v : null;
  }
}
