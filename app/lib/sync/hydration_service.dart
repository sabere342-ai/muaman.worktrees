import 'package:sqflite/sqflite.dart';

import 'adapters/entity_sync_adapter.dart';
import 'sync_queue_repository.dart';

class HydrationService {
  final Database _db;
  final HydrationCloudSource? _cloudSource;
  final Future<void> Function(String message) _logger;

  /// Phase M SG-1: detects unsynced local work so a newer cloud row can
  /// never destructively overwrite a pending local intent.
  final SyncQueueRepository? _queueRepository;

  HydrationService({
    required Database db,
    HydrationCloudSource? cloudSource,
    required Future<void> Function(String message) logger,
    SyncQueueRepository? queueRepository,
  })  : _db = db,
        _cloudSource = cloudSource,
        _logger = logger,
        _queueRepository = queueRepository;

  Future<HydrationResult> hydrate({
    required String shopId,
    required List<EntitySyncAdapter> adapters,
  }) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    int deleted = 0;
    int deferred = 0;

    if (_cloudSource == null) {
      return HydrationResult(
        inserted: 0,
        updated: 0,
        skipped: 0,
        deleted: 0,
        error: 'No cloud source configured',
      );
    }

    for (final adapter in adapters) {
      try {
        final cloudData =
            await _cloudSource.fetchAll(shopId: shopId, adapter: adapter);

        for (final cloudRow in cloudData) {
          final cloudUuid = cloudRow['id'] as String?;
          if (cloudUuid == null || cloudUuid.isEmpty) {
            skipped++;
            continue;
          }

          // Phase J tenant guard: a payload stamped with a DIFFERENT shop id
          // than the hydration target is rejected/routed away — never merged
          // into the wrong tenant (plan §O).
          final rowShopId = cloudRow['shop_id'] as String?;
          if (rowShopId != null &&
              rowShopId.isNotEmpty &&
              rowShopId != shopId) {
            await _logger('Hydration rejected ${adapter.entityType.label} row '
                '$cloudUuid: payload shop $rowShopId != target $shopId');
            skipped++;
            continue;
          }

          final existingLocal =
              await _findLocalByCloudUuid(adapter.localTableName, cloudUuid);

          // Phase M SG-1 pending-op protection: when the local entity has
          // queued (unsynced) work, a newer cloud row must NOT destructively
          // overwrite the unsynced local intent. The row is deferred —
          // preserved as-is for the queue drain / reconciliation pass.
          if (existingLocal != null && _queueRepository != null) {
            final hasPending = await _queueRepository.hasAnyPendingForEntity(
                adapter.entityType.label, (existingLocal['id'] as num).toInt());
            if (hasPending) {
              await _logger(
                  'Hydration deferred ${adapter.entityType.label} row '
                  '$cloudUuid: pending local operation protected (SG-1)');
              deferred++;
              continue;
            }
          }

          final localRow = adapter.cloudToLocalRow(cloudRow);

          if (existingLocal != null) {
            final currentVersion =
                (existingLocal['server_version'] as num?)?.toInt() ?? 0;
            final serverVersion =
                (cloudRow['server_version'] as num?)?.toInt() ?? 0;

            if (serverVersion > currentVersion) {
              await _db.update(
                adapter.localTableName,
                {
                  ...localRow,
                  'shop_id': shopId,
                  'server_version': serverVersion,
                  'sync_status': 'SYNCED',
                  'last_synced_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [existingLocal['id']],
              );
              updated++;
            } else {
              skipped++;
            }
          } else {
            final insertData = {
              ...localRow,
              'cloud_uuid': cloudUuid,
              'shop_id': shopId,
              'server_version':
                  (cloudRow['server_version'] as num?)?.toInt() ?? 1,
              'sync_status': 'SYNCED',
              'last_synced_at': DateTime.now().toIso8601String(),
            };
            await _db.insert(adapter.localTableName, insertData);
            inserted++;
          }

          final deletedAt = cloudRow['deleted_at'];
          if (deletedAt != null && existingLocal != null) {
            await _db.delete(
              adapter.localTableName,
              where: 'id = ?',
              whereArgs: [existingLocal['id']],
            );
            deleted++;
          }
        }

        await _logger('Hydrated ${adapter.entityType.label}: '
            'inserted=$inserted, updated=$updated, skipped=$skipped');
      } catch (e) {
        await _logger('Hydration error for ${adapter.entityType.label}: $e');
      }
    }

    return HydrationResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      deleted: deleted,
      deferred: deferred,
    );
  }

  Future<Map<String, dynamic>?> _findLocalByCloudUuid(
      String tableName, String cloudUuid) async {
    final results = await _db.query(
      tableName,
      where: 'cloud_uuid = ?',
      whereArgs: [cloudUuid],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }
}

class HydrationResult {
  final int inserted;
  final int updated;
  final int skipped;
  final int deleted;

  /// Phase M SG-1: cloud rows NOT applied because a pending local operation
  /// exists for the entity (protected from destructive overwrite).
  final int deferred;

  final String? error;

  HydrationResult({
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
    this.deleted = 0,
    this.deferred = 0,
    this.error,
  });
}

class HydrationCloudSource {
  final Future<List<Map<String, dynamic>>> Function({
    required String shopId,
    required EntitySyncAdapter adapter,
  }) fetchAll;

  final Future<Map<String, dynamic>?> Function({
    required String shopId,
    required String cloudUuid,
    required EntitySyncAdapter adapter,
  })? fetchOne;

  HydrationCloudSource({
    required this.fetchAll,
    this.fetchOne,
  });
}
