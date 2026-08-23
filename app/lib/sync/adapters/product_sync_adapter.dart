import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class ProductSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.product;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.lastWriterWins;

  @override
  String get localTableName => 'products';

  @override
  String get cloudTableName => 'cloud_products';

  @override
  String get requiredPermission => 'inventory.edit';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    // Phase M ES-1: product-row pushes carry METADATA components only.
    // sold_quantity / returned_quantity / inventory_adjustment /
    // current_quantity are owned exclusively by event application
    // (sale/return/count/adjustment events) and never travel through a
    // generic product snapshot push (IA-4). Server-side update RPCs keep
    // their existing component values when the args are omitted.
    return {
      'name': localRow['name'] as String,
      'barcode': localRow['barcode'] as String,
      'opening_quantity': localRow['openingQuantity'] as int? ?? 0,
      'cost_price': (localRow['costPrice'] as num?)?.toDouble() ?? 0,
      'total_inventory_cost':
          (localRow['totalInventoryCost'] as num?)?.toDouble() ?? 0,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'name': cloudRow['name'] as String,
      'barcode': cloudRow['barcode'] as String,
      'openingQuantity': cloudRow['opening_quantity'] as int? ?? 0,
      'soldQuantity': cloudRow['sold_quantity'] as int? ?? 0,
      'returnedQuantity': cloudRow['returned_quantity'] as int? ?? 0,
      'currentQuantity': cloudRow['current_quantity'] as int? ?? 0,
      'costPrice': (cloudRow['cost_price'] as num?)?.toDouble() ?? 0,
      'totalInventoryCost':
          (cloudRow['total_inventory_cost'] as num?)?.toDouble() ?? 0,
      'inventoryAdjustment': cloudRow['inventory_adjustment'] as int? ?? 0,
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
