import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class ExpenseSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.expense;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.lastWriterWins;

  @override
  String get localTableName => 'expenses';

  @override
  String get cloudTableName => 'cloud_expenses';

  @override
  String get requiredPermission => 'expenses.create';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'date': localRow['date'] as String,
      'description': localRow['description'] as String,
      'amount': (localRow['amount'] as num?)?.toDouble() ?? 0,
      'category': localRow['category'] as String?,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'date': cloudRow['date'] as String,
      'description': cloudRow['description'] as String,
      'amount': (cloudRow['amount'] as num?)?.toDouble() ?? 0,
      'category': cloudRow['category_name'] as String?,
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
