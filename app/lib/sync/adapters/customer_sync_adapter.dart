import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class CustomerSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.customer;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.lastWriterWins;

  @override
  String get localTableName => 'customers';

  @override
  String get cloudTableName => 'cloud_customers';

  @override
  String get requiredPermission => 'inventory.edit';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'name': localRow['name'] as String,
      'phone': localRow['phone'] as String?,
      'address': localRow['address'] as String?,
      'notes': localRow['notes'] as String?,
      'is_active': (localRow['isActive'] as int? ?? 1) == 1,
      'is_system': (localRow['isSystem'] as int? ?? 0) == 1,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'name': cloudRow['name'] as String,
      'phone': cloudRow['phone'] as String?,
      'address': cloudRow['address'] as String?,
      'notes': cloudRow['notes'] as String?,
      'isActive': (cloudRow['is_active'] as bool? ?? true) ? 1 : 0,
      'isSystem': (cloudRow['is_system'] as bool? ?? false) ? 1 : 0,
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
