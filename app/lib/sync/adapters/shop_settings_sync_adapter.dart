import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class ShopSettingsSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.shopSetting;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.lastWriterWins;

  @override
  String get localTableName => 'app_settings';

  @override
  String get cloudTableName => 'cloud_shop_settings';

  @override
  String get requiredPermission => 'admin.settings.access';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'setting_key': localRow['key'] as String,
      'setting_value': localRow['value'] as String,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'key': cloudRow['setting_key'] as String,
      'value': cloudRow['setting_value'] as String,
    };
  }

  @override
  String getCloudUuid(Map<String, dynamic> localRow) =>
      localRow['cloud_uuid'] as String? ?? '';

  @override
  int getLocalId(Map<String, dynamic> localRow) => 0;

  @override
  int getServerVersion(Map<String, dynamic> localRow) =>
      (localRow['server_version'] as num?)?.toInt() ?? 0;
}
