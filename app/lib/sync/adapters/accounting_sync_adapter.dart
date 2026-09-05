import 'entity_sync_adapter.dart';
import '../sync_status.dart';

/// Phase P Group D D2 (P-OD5): sync adapter for the per-shop `accounts` table.
///
/// Accounts are mutable catalog rows: lastWriterWins is permitted under armed
/// tenant isolation. Writes are owner-gated (D2-06 B) at the data-layer guard;
/// the adapter's `requiredPermission` (`inventory.edit`) mirrors the cloud RPC
/// authorization surface.
class AccountSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.account;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.lastWriterWins;

  @override
  String get localTableName => 'accounts';

  @override
  String get cloudTableName => 'cloud_accounts';

  @override
  String get requiredPermission => 'inventory.edit';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'name': localRow['name'] as String? ?? '',
      'account_type': localRow['account_type'] as String? ?? 'CASH',
      'deleted_at': localRow['deleted_at'] as String?,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'name': cloudRow['name'] as String? ?? '',
      'account_type': cloudRow['account_type'] as String? ?? 'CASH',
      'cloud_uuid': cloudRow['id'] as String?,
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

/// Phase P Group D D2 (P-OD5): sync adapter for the per-shop
/// `opening_balance_entries` table.
///
/// Opening-balance entries are append-only, event-like records (D2-05 A):
/// corrections are distinct new entries, never in-place mutation. They follow
/// the D1 `cost_history` channel model — server-authoritative per-entry, never
/// LWW-resolved, replay idempotent via the idempotency envelope.
class OpeningBalanceEntrySyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.openingBalanceEntry;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.serverAuthoritative;

  @override
  String get localTableName => 'opening_balance_entries';

  @override
  String get cloudTableName => 'cloud_opening_balance_entries';

  @override
  String get requiredPermission => 'inventory.edit';

  @override
  bool get isServerAuthoritative => true;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'account_id': localRow['account_id'] as int? ?? 0,
      'amount': (localRow['amount'] as num?)?.toDouble() ?? 0,
      'effective_date': localRow['effective_date'] as String? ?? '',
      'entry_kind': localRow['entry_kind'] as String? ?? 'OPENING',
      'corrects_entry_id':
          (localRow['corrects_entry_id'] as num?)?.toInt(),
      'correction_reason': localRow['correction_reason'] as String?,
      'notes': localRow['notes'] as String?,
      'idempotency_key': localRow['idempotency_key'] as String? ?? '',
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'account_id': (cloudRow['account_id'] as num?)?.toInt() ?? 0,
      'amount': (cloudRow['amount'] as num?)?.toDouble() ?? 0,
      'effective_date': cloudRow['effective_date'] as String? ?? '',
      'entry_kind': cloudRow['entry_kind'] as String? ?? 'OPENING',
      'corrects_entry_id':
          (cloudRow['corrects_entry_id'] as num?)?.toInt(),
      'correction_reason': cloudRow['correction_reason'] as String?,
      'notes': cloudRow['notes'] as String?,
      'idempotency_key': cloudRow['idempotency_key'] as String? ?? '',
      'cloud_uuid': cloudRow['id'] as String?,
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
