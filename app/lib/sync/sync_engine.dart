import 'package:sqflite/sqflite.dart';

import '../errors/cloud_data_exception.dart';
import 'adapters/entity_sync_adapter.dart';
import 'conflict_audit_repository.dart';
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

  /// Local projection database. When provided, conflict resolutions are
  /// REALLY applied to the local side (Phase M §8 gap closure) inside the
  /// same transaction that writes the audit evidence and the queue
  /// transition. When null (legacy test harnesses only), the engine falls
  /// back to the historical log-only path; production wiring MUST provide
  /// it so no silent divergence can remain.
  final Database? _localDb;

  /// Durable conflict audit sink (schema v15). When provided together with
  /// [_localDb], every conflict produces persistent evidence before any
  /// lifecycle transition (plan §21/§24).
  final ConflictAuditRepository? _conflictAuditRepository;

  SyncEngine({
    required SyncQueueRepository queueRepository,
    required ConflictResolver conflictResolver,
    required Map<SyncEntityType, EntitySyncAdapter> adapters,
    required Future<bool> Function() connectivityCheck,
    required Future<bool> Function() licenseCheck,
    required Future<String?> Function() shopIdProvider,
    required Future<void> Function(String entityType, String operation,
            {String? details})
        logger,
    SyncCloudOperations? cloudOps,
    Database? localDb,
    ConflictAuditRepository? conflictAuditRepository,
  })  : _queueRepository = queueRepository,
        _conflictResolver = conflictResolver,
        _adapters = adapters,
        _connectivityCheck = connectivityCheck,
        _licenseCheck = licenseCheck,
        _shopIdProvider = shopIdProvider,
        _logger = logger,
        _cloudOps = cloudOps,
        _localDb = localDb,
        _conflictAuditRepository = conflictAuditRepository;

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
              details: 'entry ${entry.id} belongs to shop ${entry.shopId}, '
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
              // A5 (6.1): the persisted queue-entry occurrence-token
              // (canonically embedded in the idempotency key) is threaded
              // through so `_v2` stock revert RPCs honour revert-at-most-once.
              // A DELETE has no surviving local row to converge; the revert
              // plus server idempotency log is the authority.
              idempotencyKey: entry.idempotencyKey,
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
                final applied = await _handleConflict(
                    entry, adapter, resolution, result,
                    shopId: shopId);
                if (applied) {
                  synced++;
                } else {
                  conflicts++;
                }
              } else {
                await _queueRepository.markConflict(
                    entry.id, 'Version conflict could not be resolved');
                conflicts++;
              }
              continue;
            }

            if (result.idempotent) {
              // A5 (6.3): an idempotent replay is success/convergence — the
              // logical effect is already durably present server-side. Adopt
              // the authoritative response and close the entry SYNCED without
              // re-executing the mutation. The SAME logical key (persisted
              // occurrence token inside) returned this envelope.
              await _convergeSuccess(entry, adapter, result, shopId: shopId);
              synced++;
              continue;
            }

            if (!result.success) {
              // A5 (12): a non-conflict, non-idempotent non-success must never
              // be closed as SYNCED (no fake success states). The transport
              // resolves its own business errors to CloudDataException; this
              // guard covers a transport reporting failure structurally.
              await _queueRepository.markFailed(entry.id);
              await _logger(entry.entityType, 'SERVER_ERROR',
                  details: 'Upsert returned failure without conflict or '
                      'idempotent-replay classification');
              failed++;
              continue;
            }

            await _convergeSuccess(entry, adapter, result, shopId: shopId);
            synced++;
            continue;
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

  /// Phase M §8 gap closure: a detected conflict is NEVER log-and-forget.
  ///
  /// Auto-resolvable outcomes are REALLY applied (local projection adopts
  /// the authoritative state, or the local winner reaches the server and
  /// the authoritative response converges back), verified by read-back,
  /// and only then is the queue entry closed — audit evidence, resolution
  /// state, projection apply and completion marker share ONE transaction
  /// (INV-M17).
  ///
  /// Non-auto-resolvable outcomes become durable REVIEW_REQUIRED records.
  ///
  /// Returns true when the entry converged (counted as synced), false when
  /// it landed in durable review (counted as conflict).
  Future<bool> _handleConflict(SyncQueueEntry entry, EntitySyncAdapter adapter,
      ConflictResolution resolution, CloudUpsertResult upsertResult,
      {required String shopId}) async {
    final db = _localDb;
    final audit = _conflictAuditRepository;

    // Legacy test-harness fallback ONLY: engines built without a local
    // database AND without an audit sink cannot apply or record anything,
    // so the historical log-only behavior is preserved for existing suites
    // (plan §33). Production wiring always provides both, making the silent
    // divergence path unreachable.
    if (db == null || audit == null) {
      await _logger(
        entry.entityType,
        'CONFLICT_RESOLVED',
        details: '${resolution.resolutionReason} [${resolution.policy.name}]',
      );
      await _queueRepository.markSynced(entry.id);
      return true;
    }

    try {
      switch (resolution.outcome) {
        case ConflictOutcome.requiresReview:
          await _persistReviewRequired(entry, resolution, upsertResult,
              shopId: shopId);
          return false;
        case ConflictOutcome.applyResolvedPayload:
          if (!resolution.localWins) {
            return await _applyServerWinnerLocally(
                entry, adapter, resolution, upsertResult,
                shopId: shopId);
          }
          return await _pushLocalWinnerAndConverge(
              entry, adapter, resolution, upsertResult,
              shopId: shopId);
      }
    } catch (e) {
      // Fail-safe: any apply/verification failure lands in DURABLE review —
      // never a silent SYNCED with unresolved divergence.
      await _logger(entry.entityType, 'CONFLICT_APPLY_FAILED', details: '$e');
      try {
        await _persistReviewRequired(entry, resolution, upsertResult,
            shopId: shopId, note: 'apply failed after resolution: $e');
      } catch (_) {
        // Audit persistence itself failed; the exception propagates as an
        // unknown processing error by rethrowing to keep visibility.
        rethrow;
      }
      return false;
    }
  }

  Map<String, dynamic> _projectionFromResolution(
      EntitySyncAdapter adapter, ConflictResolution resolution) {
    final mapped = adapter.cloudToLocalRow(resolution.resolvedPayload);
    if (resolution.stockComponentsProtected) {
      mapped.removeWhere((k, _) => kLocalStockComponentColumns.contains(k));
    }
    return mapped;
  }

  /// Server-won resolution: adopt the authoritative server state into the
  /// local projection inside one transaction with audit + queue close.
  Future<bool> _applyServerWinnerLocally(
      SyncQueueEntry entry,
      EntitySyncAdapter adapter,
      ConflictResolution resolution,
      CloudUpsertResult upsertResult,
      {required String shopId}) async {
    final db = _localDb!;
    final audit = _conflictAuditRepository!;
    final adoptedVersion = upsertResult.currentServerVersion ?? 0;
    final projection = _projectionFromResolution(adapter, resolution);

    await db.transaction((txn) async {
      final rows = await txn.query(adapter.localTableName,
          where: 'id = ?', whereArgs: [entry.entityId], limit: 1);
      final existing = rows.isEmpty ? null : rows.first;

      if (existing == null) {
        throw StateError(
            'local row ${entry.entityId} missing; convergence impossible');
      }
      final rowShop = existing['shop_id'] as String?;
      if (rowShop != null && rowShop.isNotEmpty && rowShop != shopId) {
        throw StateError('tenant guard: row belongs to $rowShop');
      }

      final updated = await txn.update(
        adapter.localTableName,
        {
          ...projection,
          'server_version': adoptedVersion,
          'sync_status': 'SYNCED',
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
      if (updated != 1) {
        throw StateError('projection update affected $updated rows');
      }

      // Convergence verification INSIDE the transaction: the adopted
      // server_version must be readable back before anything commits.
      final after = await txn.query(adapter.localTableName,
          where: 'id = ?', whereArgs: [entry.entityId], limit: 1);
      final adoptedAfter =
          (after.first['server_version'] as num?)?.toInt() ?? -1;
      if (adoptedAfter != adoptedVersion) {
        throw StateError(
            'convergence verification failed: version $adoptedAfter != $adoptedVersion');
      }

      final auditId = await audit.recordConflict(
        executor: txn,
        shopId: shopId,
        entityType: entry.entityType,
        entityId: entry.entityId,
        entityUuid: upsertResult.cloudUuid,
        operation: entry.operation.label,
        localBefore: resolution.localPayload,
        localAfter: projection,
        serverBefore: resolution.serverData,
        relatedEventIds: const [],
        localVersion: upsertResult.localVersion,
        serverVersion: adoptedVersion,
        idempotencyKey: entry.idempotencyKey,
      );
      await audit.markResolved(
        auditId,
        method: ConflictResolutionMethod.AUTO,
        resolvedByUser: 'system:auto-convergence',
        note: resolution.resolutionReason,
        executor: txn,
      );
      await _queueRepository.markSynced(entry.id, executor: txn);
      await _queueRepository.setResolutionStatus(
          entry.id, ConflictLifecycleStatus.RESOLVED,
          executor: txn);
    });

    await _logger(entry.entityType, 'CONFLICT_APPLIED_LOCALLY',
        details:
            '${resolution.resolutionReason}; server_version=$adoptedVersion adopted');
    return true;
  }

  /// Local-won true-LWW resolution: push the winning payload to the server
  /// and converge the authoritative response/version back locally.
  Future<bool> _pushLocalWinnerAndConverge(
      SyncQueueEntry entry,
      EntitySyncAdapter adapter,
      ConflictResolution resolution,
      CloudUpsertResult originalResult,
      {required String shopId}) async {
    final db = _localDb!;
    final audit = _conflictAuditRepository!;
    final cloudOps = _cloudOps;
    if (cloudOps == null) {
      throw StateError('no cloud operations wired for local-winner push');
    }

    final repush = await cloudOps.upsertEntity(
      adapter: adapter,
      shopId: shopId,
      localId: entry.entityId,
      payload: resolution.resolvedPayload,
      idempotencyKey: entry.idempotencyKey,
    );
    if (!repush.success && !repush.idempotent) {
      throw StateError('local-winner re-push rejected by server');
    }

    final adoptedVersion = repush.currentServerVersion ??
        repush.localVersion ??
        originalResult.currentServerVersion ??
        0;

    await db.transaction((txn) async {
      final updated = await txn.update(
        adapter.localTableName,
        {
          'server_version': adoptedVersion,
          'sync_status': 'SYNCED',
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
      if (updated != 1) {
        throw StateError(
            'local-winner convergence update affected $updated rows');
      }

      final auditId = await audit.recordConflict(
        executor: txn,
        shopId: shopId,
        entityType: entry.entityType,
        entityId: entry.entityId,
        entityUuid: repush.cloudUuid ?? originalResult.cloudUuid,
        operation: entry.operation.label,
        localBefore: resolution.localPayload,
        serverBefore: resolution.serverData,
        serverAfter: repush.serverData,
        localVersion: originalResult.localVersion,
        serverVersion: adoptedVersion,
        idempotencyKey: entry.idempotencyKey,
      );
      await audit.markResolved(
        auditId,
        method: ConflictResolutionMethod.POLICY,
        resolvedByUser: 'system:true-lww',
        note: resolution.resolutionReason,
        executor: txn,
      );
      await _queueRepository.markSynced(entry.id, executor: txn);
      await _queueRepository.setResolutionStatus(
          entry.id, ConflictLifecycleStatus.RESOLVED,
          executor: txn);
    });

    await _logger(entry.entityType, 'CONFLICT_LOCAL_WINNER_CONVERGED',
        details:
            '${resolution.resolutionReason}; server_version=$adoptedVersion flowed back');
    return true;
  }

  /// A5 (6.3/6.4): converges a drained success OR an IDEMPOTENT replay into
  /// the local projection inside ONE transaction with the queue SYNCED
  /// transition (INV-M17).
  ///
  /// The server response is the authority: `cloud_uuid` and `server_version`
  /// are adopted verbatim when present and never fabricated. Stock components
  /// (`current_quantity` and siblings) are NOT written here — they are owned
  /// by event application (ES-1) and travel through the existing
  /// reconciliation/convergence contract (conflict resolution /
  /// `adapter.cloudToLocalRow`) only when the current flow detects a
  /// divergence requiring it (A5 6.5).
  ///
  /// Tenant authority stays with the persisted queue-entry `shop_id`: the
  /// local row must belong to that shop or convergence fails closed — the
  /// ambient active shop is never consulted.
  ///
  /// A replayed IDEMPOTENT result carries the ORIGINAL authoritative response,
  /// so converging it stamps the durable server identity and closes the entry
  /// SYNCED without re-executing the mutation (A5 6.3). Legacy test harnesses
  /// without a local database keep the historical log-only close so no silent
  /// divergence path can be introduced there.
  Future<void> _convergeSuccess(
    SyncQueueEntry entry,
    EntitySyncAdapter adapter,
    CloudUpsertResult result, {
    required String shopId,
  }) async {
    final db = _localDb;
    final cloudUuid = result.cloudUuid;
    final serverVersion = result.currentServerVersion;
    final hasAuthoritativeMetadata =
        (cloudUuid != null && cloudUuid.isNotEmpty) ||
            (serverVersion != null && serverVersion > 0);

    if (db == null || !hasAuthoritativeMetadata) {
      await _queueRepository.markSynced(entry.id);
      await _logger(entry.entityType, 'CONVERGED',
          details: 'closed SYNCED without authoritative adoption metadata');
      return;
    }

    // Legacy harnesses (plan §33) model only the queue/audit tables, not the
    // synced entity projections; production wiring always ships them. When the
    // local projection table is absent there is no row to converge, so the
    // historical log-only close is preserved (same shape-check idiom as
    // SyncQueueRepository._syncQueueColumns).
    final shape =
        await db.rawQuery('PRAGMA table_info(${adapter.localTableName})');
    if (shape.isEmpty) {
      await _queueRepository.markSynced(entry.id);
      await _logger(entry.entityType, 'CONVERGED',
          details: 'closed SYNCED (legacy harness: '
              '${adapter.localTableName} projection absent)');
      return;
    }

    await db.transaction((txn) async {
      final rows = await txn.query(adapter.localTableName,
          where: 'id = ?', whereArgs: [entry.entityId], limit: 1);
      if (rows.isEmpty) {
        // The local row is already absent (delete/cleanup race); there is
        // nothing to converge, but the durable server effect is acknowledged
        // and the queue entry can close.
        await _queueRepository.markSynced(entry.id, executor: txn);
        return;
      }
      final existing = rows.first;
      final rowShop = existing['shop_id'] as String?;
      if (rowShop != null && rowShop.isNotEmpty && rowShop != shopId) {
        throw StateError(
            'tenant guard: convergence blocked for row in shop $rowShop');
      }

      final updated = await txn.update(
        adapter.localTableName,
        {
          'sync_status': EntitySyncStatus.SYNCED.label,
          'last_synced_at': DateTime.now().toIso8601String(),
          if (cloudUuid != null && cloudUuid.isNotEmpty)
            'cloud_uuid': cloudUuid,
          if (serverVersion != null && serverVersion > 0)
            'server_version': serverVersion,
        },
        where: 'id = ?',
        whereArgs: [entry.entityId],
      );
      if (updated != 1) {
        throw StateError('convergence update affected $updated rows');
      }

      // Convergence verification INSIDE the transaction: the adopted server
      // identity must read back before anything commits (INV-M17).
      final after = await txn.query(adapter.localTableName,
          where: 'id = ?', whereArgs: [entry.entityId], limit: 1);
      if (serverVersion != null && serverVersion > 0) {
        final adoptedVersion =
            (after.first['server_version'] as num?)?.toInt() ?? -1;
        if (adoptedVersion != serverVersion) {
          throw StateError(
              'convergence verification failed: version $adoptedVersion != $serverVersion');
        }
      }
      if (cloudUuid != null && cloudUuid.isNotEmpty) {
        final adoptedUuid = after.first['cloud_uuid'] as String?;
        if (adoptedUuid != cloudUuid) {
          throw StateError(
              'convergence verification failed: uuid $adoptedUuid != $cloudUuid');
        }
      }

      await _queueRepository.markSynced(entry.id, executor: txn);
    });

    await _logger(entry.entityType, 'CONVERGED',
        details: 'adopted server_version=$serverVersion, '
            'cloud_uuid=$cloudUuid');
  }

  /// Durable REVIEW_REQUIRED landing (§20): persistent audit evidence plus
  /// CONFLICT + REVIEW_REQUIRED queue lifecycle in ONE transaction. The
  /// entry is never marked synced.
  Future<void> _persistReviewRequired(SyncQueueEntry entry,
      ConflictResolution resolution, CloudUpsertResult upsertResult,
      {required String shopId, String? note}) async {
    final db = _localDb!;
    final audit = _conflictAuditRepository!;
    final reason = note ?? resolution.resolutionReason;

    await db.transaction((txn) async {
      await audit.recordConflict(
        executor: txn,
        shopId: shopId,
        entityType: entry.entityType,
        entityId: entry.entityId,
        entityUuid: upsertResult.cloudUuid,
        operation: entry.operation.label,
        localBefore: resolution.localPayload,
        serverBefore: resolution.serverData,
        localVersion: upsertResult.localVersion,
        serverVersion: upsertResult.currentServerVersion,
        idempotencyKey: entry.idempotencyKey,
      );
      await _queueRepository.markConflict(entry.id, reason, executor: txn);
      await _queueRepository.setResolutionStatus(
          entry.id, ConflictLifecycleStatus.REVIEW_REQUIRED,
          executor: txn);
    });

    await _logger(entry.entityType, 'CONFLICT_REVIEW_REQUIRED',
        details: reason);
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
    String? idempotencyKey,
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
