import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class ReturnSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.returnItem;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.serverAuthoritative;

  @override
  String get localTableName => 'returns';

  @override
  String get cloudTableName => 'cloud_returns';

  @override
  String get requiredPermission => 'returns.create';

  @override
  bool get isServerAuthoritative => true;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'date': localRow['date'] as String,
      'product_name': localRow['productName'] as String,
      'barcode': localRow['barcode'] as String,
      'quantity': localRow['quantity'] as int? ?? 0,
      'sale_price': (localRow['salePrice'] as num?)?.toDouble() ?? 0,
      'total_return_value':
          (localRow['totalReturnValue'] as num?)?.toDouble() ?? 0,
      'cost_price': (localRow['costPrice'] as num?)?.toDouble() ?? 0,
      'returned_cogs': (localRow['returnedCogs'] as num?)?.toDouble() ?? 0,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'date': cloudRow['date'] as String,
      'productName': cloudRow['product_name'] as String,
      'barcode': cloudRow['barcode'] as String,
      'quantity': cloudRow['quantity'] as int? ?? 0,
      'salePrice': (cloudRow['sale_price'] as num?)?.toDouble() ?? 0,
      'totalReturnValue':
          (cloudRow['total_return_value'] as num?)?.toDouble() ?? 0,
      'costPrice': (cloudRow['cost_price'] as num?)?.toDouble() ?? 0,
      'returnedCogs': (cloudRow['returned_cogs'] as num?)?.toDouble() ?? 0,
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
