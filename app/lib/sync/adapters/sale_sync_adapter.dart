import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class SaleSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.sale;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.serverAuthoritative;

  @override
  String get localTableName => 'sales';

  @override
  String get cloudTableName => 'cloud_sales';

  @override
  String get requiredPermission => 'sales.create';

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
      'total_sale_value': (localRow['totalSaleValue'] as num?)?.toDouble() ?? 0,
      'cost_price': (localRow['costPrice'] as num?)?.toDouble() ?? 0,
      'cogs': (localRow['cogs'] as num?)?.toDouble() ?? 0,
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
      'totalSaleValue': (cloudRow['total_sale_value'] as num?)?.toDouble() ?? 0,
      'costPrice': (cloudRow['cost_price'] as num?)?.toDouble() ?? 0,
      'cogs': (cloudRow['cogs'] as num?)?.toDouble() ?? 0,
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
