import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class InventoryCountSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.inventoryCount;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.latestTimestampWins;

  @override
  String get localTableName => 'inventory_count';

  @override
  String get cloudTableName => 'cloud_inventory_count';

  @override
  String get requiredPermission => 'stocktake.view';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'product_id': localRow['productId'] as int,
      'actual_quantity': localRow['actualQuantity'] as int? ?? 0,
      'notes': localRow['notes'] as String? ?? '',
      'count_date': localRow['countDate'] as String,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'productId': cloudRow['product_id'] as String,
      'actualQuantity': cloudRow['actual_quantity'] as int? ?? 0,
      'notes': cloudRow['notes'] as String? ?? '',
      'countDate': cloudRow['count_date'] as String,
    };
  }

  @override
  String getCloudUuid(Map<String, dynamic> localRow) =>
      localRow['cloud_uuid'] as String? ?? '';

  @override
  int getLocalId(Map<String, dynamic> localRow) =>
      (localRow['id'] as num?)?.toInt() ?? 0;

  @override
  int getServerVersion(Map<String, dynamic> localRow) =>
      (localRow['server_version'] as num?)?.toInt() ?? 0;
}
