import '../errors/sync_exception.dart';
import 'sync_status.dart';
import 'adapters/entity_sync_adapter.dart';

class ConflictResolution {
  final String entityType;
  final String entityId;
  final ConflictResolutionPolicy policy;
  final Map<String, dynamic> resolvedPayload;
  final String resolutionReason;

  ConflictResolution({
    required this.entityType,
    required this.entityId,
    required this.policy,
    required this.resolvedPayload,
    required this.resolutionReason,
  });
}

class ConflictResolver {
  final Map<SyncEntityType, EntitySyncAdapter> _adapters;

  ConflictResolver(this._adapters);

  ConflictResolution? detectAndResolve({
    required SyncEntityType entityType,
    required int entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverData,
    required int localServerVersion,
    required int currentServerVersion,
  }) {
    if (localServerVersion >= currentServerVersion) {
      return null;
    }

    final adapter = _adapters[entityType];
    if (adapter == null) {
      throw SyncException(
        type: SyncErrorType.unknown,
        message: 'No adapter for entity type: ${entityType.label}',
      );
    }

    final policy = adapter.conflictPolicy;

    switch (policy) {
      case ConflictResolutionPolicy.lastWriterWins:
        return ConflictResolution(
          entityType: entityType.label,
          entityId: entityId.toString(),
          policy: policy,
          resolvedPayload: localPayload,
          resolutionReason:
              'LWW: local changes accepted (version $localServerVersion -> $currentServerVersion)',
        );

      case ConflictResolutionPolicy.serverAuthoritative:
        return ConflictResolution(
          entityType: entityType.label,
          entityId: entityId.toString(),
          policy: policy,
          resolvedPayload: serverData,
          resolutionReason:
              'Server-authoritative: cloud version accepted (version $currentServerVersion)',
        );

      case ConflictResolutionPolicy.latestTimestampWins:
        return ConflictResolution(
          entityType: entityType.label,
          entityId: entityId.toString(),
          policy: policy,
          resolvedPayload: localPayload,
          resolutionReason:
              'Latest timestamp: local version accepted (version $localServerVersion -> $currentServerVersion)',
        );
    }
  }

  ConflictResolution? resolveVersionConflict({
    required EntitySyncAdapter adapter,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverData,
    required int localServerVersion,
    required int currentServerVersion,
  }) {
    if (localServerVersion >= currentServerVersion) {
      return null;
    }

    final policy = adapter.conflictPolicy;

    switch (policy) {
      case ConflictResolutionPolicy.lastWriterWins:
        return ConflictResolution(
          entityType: adapter.entityType.label,
          entityId: (localPayload['id'] ?? 0).toString(),
          policy: policy,
          resolvedPayload: localPayload,
          resolutionReason: 'LWW: local payload accepted',
        );

      case ConflictResolutionPolicy.serverAuthoritative:
        return ConflictResolution(
          entityType: adapter.entityType.label,
          entityId: (localPayload['id'] ?? 0).toString(),
          policy: policy,
          resolvedPayload: serverData,
          resolutionReason: 'Server-authoritative: server data accepted',
        );

      case ConflictResolutionPolicy.latestTimestampWins:
        return ConflictResolution(
          entityType: adapter.entityType.label,
          entityId: (localPayload['id'] ?? 0).toString(),
          policy: policy,
          resolvedPayload: localPayload,
          resolutionReason: 'Latest timestamp: local payload accepted',
        );
    }
  }
}
