import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class InvoiceSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.invoice;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.serverAuthoritative;

  @override
  String get localTableName => 'invoices';

  @override
  String get cloudTableName => 'cloud_invoices';

  @override
  String get requiredPermission => 'sales.create';

  @override
  bool get isServerAuthoritative => true;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'invoice_number': localRow['invoiceNumber'] as String,
      'date': localRow['date'] as String,
      'customer_name': localRow['customerName'] as String,
      'payment_method': localRow['paymentMethod'] as String,
      'total_amount': (localRow['totalAmount'] as num?)?.toDouble() ?? 0,
      'total_items': localRow['totalItems'] as int? ?? 0,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'invoiceNumber': cloudRow['invoice_number'] as String,
      'date': cloudRow['date'] as String,
      'customerName': cloudRow['customer_name'] as String,
      'paymentMethod': cloudRow['payment_method'] as String,
      'totalAmount': (cloudRow['total_amount'] as num?)?.toDouble() ?? 0,
      'totalItems': cloudRow['total_items'] as int? ?? 0,
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
