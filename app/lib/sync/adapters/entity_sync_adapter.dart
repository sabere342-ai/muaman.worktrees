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
}
