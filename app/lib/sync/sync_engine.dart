import '../errors/cloud_data_exception.dart';
import 'adapters/entity_sync_adapter.dart';
import 'conflict_resolver.dart';
import 'sync_queue_repository.dart';
import 'sync_status.dart';

class SyncEngine {
  final SyncQueueRepository _queueRepository;
  final ConflictResolver _conflictResolver;
  final Map<SyncEntityType, EntitySyncAdapter> _adapters;
  final Future<bool> Function() _connectivityCheck;
  final Future<bool> Function() _licenseCheck;
  final Future<String?> Function() _shopIdProvider;
  final Future<void> Function(String entityType, String operation,
      {String? details}) _logger;
  final SyncCloudOperations? _cloudOps;

  SyncEngine({
    required SyncQueueRepository queueRepository,
    required ConflictResolver conflictResolver,
    required Map<SyncEntityType, EntitySyncAdapter> adapters,
    required Future<bool> Function() connectivityCheck,
    required Future<bool> Function() licenseCheck,
    required Future<String?> Function() shopIdProvider,
    required Future<void> Function(String entityType, String operation,
        {String? details}) logger,
    SyncCloudOperations? cloudOps,
  })  : _queueRepository = queueRepository,
        _conflictResolver = conflictResolver,
        _adapters = adapters,
        _connectivityCheck = connectivityCheck,
        _licenseCheck = licenseCheck,
        _shopIdProvider = shopIdProvider,
        _logger = logger,
        _cloudOps = cloudOps;

  Future<SyncResult> processQueue() async {
    final isOnline = await _connectivityCheck();
    if (!isOnline) {
      return SyncResult(
        processed: 0,
        synced: 0,
        failed: 0,
        conflicts: 0,
        skippedOffline: true,
      );
    }

    final isLicenseValid = await _licenseCheck();
    if (!isLicenseValid) {
      return SyncResult(
        processed: 0,
        synced: 0,
        failed: 0,
        conflicts: 0,
        skippedLicenseExpired: true,
      );
    }

    final shopId = await _shopIdProvider();
    if (shopId == null || shopId.isEmpty) {
      return SyncResult(
        processed: 0,
        synced: 0,
        failed: 0,
        conflicts: 0,
        skippedNoShop: true,
      );
    }

    final entries = await _queueRepository.getPendingEntries(shopId: shopId);

    int synced = 0;
    int failed = 0;
    int conflicts = 0;

    for (final entry in entries) {
      try {
        // Phase J tenant guard: queued work must execute strictly under its
        // persisted originating shop id, never the ambient current shop
        // (plan §O). getPendingEntries(shopId:) already filters; this is a
        // defense-in-depth assertion so the invariant cannot regress.
        if (entry.shopId != null &&
            entry.shopId!.isNotEmpty &&
            entry.shopId != shopId) {
          await _logger(entry.entityType, 'TENANT_MISMATCH_SKIPPED',
              details:
                  'entry ${entry.id} belongs to shop ${entry.shopId}, '
                  'cycle shop is $shopId — not executed');
          continue;
        }

        await _logger(entry.entityType, entry.operation.label,
            details: 'Processing queue entry ${entry.id}');

        if (_shouldRetryLater(entry)) {
          continue;
        }

        final entityType = SyncEntityType.values.firstWhere(
          (e) => e.label == entry.entityType,
          orElse: () => SyncEntityType.product,
        );

        final adapter = _adapters[entityType];
        if (adapter == null) {
          await _queueRepository.markFailed(entry.id);
          failed++;
          continue;
        }

        if (entry.operation == SyncQueueOperation.DELETE) {
          final payloadData = entry.payload;
          final cloudOps = _cloudOps;
          if (payloadData != null && cloudOps != null) {
            await cloudOps.deleteEntity(
              adapter: adapter,
              shopId: shopId,
              cloudUuid: payloadData['cloud_uuid'] as String? ?? '',
              entityId: entry.entityId,
            );
          }
        } else if (entry.operation == SyncQueueOperation.CREATE ||
            entry.operation == SyncQueueOperation.UPDATE) {
          final payload = entry.payload;
          final cloudOps = _cloudOps;
          if (payload != null && cloudOps != null) {
            final result = await cloudOps.upsertEntity(
              adapter: adapter,
              shopId: shopId,
              localId: entry.entityId,
              payload: payload,
              idempotencyKey: entry.idempotencyKey,
            );

            if (result.conflict) {
              final resolution = _conflictResolver.resolveVersionConflict(
                adapter: adapter,
                localPayload: payload,
                serverData: result.serverData ?? {},
                localServerVersion: result.localVersion ?? 0,
                currentServerVersion: result.currentServerVersion ?? 0,
              );

              if (resolution != null) {
                await _conflictResolved(entry, resolution);
                await _queueRepository.markSynced(entry.id);
                synced++;
              } else {
                await _queueRepository.markConflict(
                    entry.id, 'Version conflict could not be resolved');
                conflicts++;
              }
              continue;
            }

            if (result.idempotent) {
              await _queueRepository.markSynced(entry.id);
              synced++;
              continue;
            }
          }
        }

        await _queueRepository.markSynced(entry.id);
        synced++;
      } on CloudDataException catch (e) {
        if (e.type == CloudDataErrorType.permissionDenied) {
          await _queueRepository.markFailed(entry.id);
          await _logger(entry.entityType, 'PERMISSION_DENIED',
              details: e.message);
          failed++;
        } else if (e.type == CloudDataErrorType.networkError) {
          break;
        } else if (e.type == CloudDataErrorType.licenseExpired ||
            e.type == CloudDataErrorType.licenseRequired) {
          break;
        } else {
          await _queueRepository.markFailed(entry.id);
          await _logger(entry.entityType, 'SERVER_ERROR', details: e.message);
          failed++;
        }
      } catch (e) {
        await _queueRepository.markFailed(entry.id);
        await _logger(entry.entityType, 'UNKNOWN_ERROR', details: '$e');
        failed++;
      }
    }

    return SyncResult(
      processed: entries.length,
      synced: synced,
      failed: failed,
      conflicts: conflicts,
    );
  }

  bool _shouldRetryLater(SyncQueueEntry entry) {
    if (entry.retryCount <= 0) return false;
    if (entry.retryCount > 5) return false;

    const delays = [
      Duration.zero,
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 10),
    ];

    final delayIndex = (entry.retryCount - 1).clamp(0, delays.length - 1);
    final delay = delays[delayIndex];
    final elapsed = DateTime.now().difference(entry.createdAt);

    return elapsed < delay;
  }

  Future<void> _conflictResolved(
      SyncQueueEntry entry, ConflictResolution resolution) async {
    await _logger(
      entry.entityType,
      'CONFLICT_RESOLVED',
      details:
          '${resolution.resolutionReason} [${resolution.policy.name}]',
    );
  }
}

class SyncResult {
  final int processed;
  final int synced;
  final int failed;
  final int conflicts;
  final bool skippedOffline;
  final bool skippedLicenseExpired;
  final bool skippedNoShop;

  SyncResult({
    this.processed = 0,
    this.synced = 0,
    this.failed = 0,
    this.conflicts = 0,
    this.skippedOffline = false,
    this.skippedLicenseExpired = false,
    this.skippedNoShop = false,
  });
}

class SyncCloudOperations {
  final Future<CloudUpsertResult> Function({
    required EntitySyncAdapter adapter,
    required String shopId,
    required int localId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) upsertEntity;

  final Future<void> Function({
    required EntitySyncAdapter adapter,
    required String shopId,
    required String cloudUuid,
    required int entityId,
  }) deleteEntity;

  SyncCloudOperations({
    required this.upsertEntity,
    required this.deleteEntity,
  });
}

class CloudUpsertResult {
  final bool success;
  final bool conflict;
  final bool idempotent;
  final Map<String, dynamic>? serverData;
  final int? localVersion;
  final int? currentServerVersion;
  final String? cloudUuid;

  CloudUpsertResult({
    this.success = false,
    this.conflict = false,
    this.idempotent = false,
    this.serverData,
    this.localVersion,
    this.currentServerVersion,
    this.cloudUuid,
  });
}
