import 'package:sqflite/sqflite.dart';

import 'adapters/entity_sync_adapter.dart';
import 'hydration_service.dart';

class IncrementalSyncService {
  final Database _db;
  final HydrationCloudSource? _cloudSource;
  final Future<void> Function(String message) _logger;

  IncrementalSyncService({
    required Database db,
    HydrationCloudSource? cloudSource,
    required Future<void> Function(String message) logger,
  })  : _db = db,
        _cloudSource = cloudSource,
        _logger = logger;

  Future<IncrementalSyncResult> pullChanges({
    required String shopId,
    required List<EntitySyncAdapter> adapters,
    required DateTime since,
  }) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    int deleted = 0;

    if (_cloudSource == null) {
      return IncrementalSyncResult(
        inserted: 0,
        updated: 0,
        skipped: 0,
        deleted: 0,
        error: 'No cloud source configured',
      );
    }

    for (final adapter in adapters) {
      try {
        final cloudData = await _cloudSource.fetchAll(shopId: shopId, adapter: adapter);

        for (final cloudRow in cloudData) {
          final cloudUuid = cloudRow['id'] as String?;
          if (cloudUuid == null || cloudUuid.isEmpty) {
            skipped++;
            continue;
          }

          final updatedAt = cloudRow['updated_at'] as String?;
          if (updatedAt != null) {
            final updatedDateTime = DateTime.tryParse(updatedAt);
            if (updatedDateTime != null && updatedDateTime.isBefore(since)) {
              skipped++;
              continue;
            }
          }

          final existingLocal = await _findLocalByCloudUuid(adapter.localTableName, cloudUuid);
          final localRow = adapter.cloudToLocalRow(cloudRow);

          if (existingLocal != null) {
            final currentVersion = (existingLocal['server_version'] as num?)?.toInt() ?? 0;
            final serverVersion = (cloudRow['server_version'] as num?)?.toInt() ?? 0;

            if (serverVersion > currentVersion) {
              await _db.update(
                adapter.localTableName,
                {
                  ...localRow,
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
              'server_version': (cloudRow['server_version'] as num?)?.toInt() ?? 1,
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

        await _logger('Incremental sync ${adapter.entityType.label}: '
            'inserted=$inserted, updated=$updated, skipped=$skipped');
      } catch (e) {
        await _logger('Incremental sync error for ${adapter.entityType.label}: $e');
      }
    }

    return IncrementalSyncResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      deleted: deleted,
    );
  }

  Future<Map<String, dynamic>?> _findLocalByCloudUuid(String tableName, String cloudUuid) async {
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

class IncrementalSyncResult {
  final int inserted;
  final int updated;
  final int skipped;
  final int deleted;
  final String? error;

  IncrementalSyncResult({
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
    this.deleted = 0,
    this.error,
  });
}
