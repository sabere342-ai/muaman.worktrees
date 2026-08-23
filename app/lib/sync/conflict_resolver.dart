import '../errors/sync_exception.dart';
import 'sync_status.dart';
import 'adapters/entity_sync_adapter.dart';

/// What the sync engine must DO with a resolution result.
enum ConflictOutcome {
  /// The resolved payload can be applied locally / re-pushed so both sides
  /// converge. Engine must actually apply it (never log-and-forget).
  applyResolvedPayload,

  /// The conflict represents genuine divergence between immutable records
  /// (event-like entities) that must not be auto-discarded. Engine must
  /// persist a durable REVIEW_REQUIRED conflict record.
  requiresReview,
}

/// Stock component columns owned exclusively by event application
/// (Phase M §14 rule ES-1). Generic metadata conflict resolution must never
/// decide these fields.
const Set<String> kStockComponentKeys = {
  'sold_quantity',
  'returned_quantity',
  'inventory_adjustment',
  'current_quantity',
  'soldQuantity',
  'returnedQuantity',
  'inventoryAdjustment',
  'currentQuantity',
};

/// Local-row column names owned by event application (ES-1). When a
/// resolution is applied to the local projection, these columns are left
/// untouched so event-derived stock is never rewritten by a metadata merge.
const Set<String> kLocalStockComponentColumns = {
  'soldQuantity',
  'returnedQuantity',
  'inventoryAdjustment',
  'currentQuantity',
};

class ConflictResolution {
  final String entityType;
  final String entityId;
  final ConflictResolutionPolicy policy;
  final Map<String, dynamic> resolvedPayload;
  final String resolutionReason;

  /// Both worlds' beliefs at detection time (evidence for durable audit).
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> serverData;

  /// Action the engine must take (see [ConflictOutcome]).
  final ConflictOutcome outcome;

  /// True when stock component columns were stripped from the resolved
  /// payload because they are owned by event application (ES-1).
  final bool stockComponentsProtected;

  /// True when true-LWW picked the LOCAL write as the winner. The engine
  /// must then push the winning payload to the server and converge the
  /// authoritative response back into the local projection.
  final bool localWins;

  ConflictResolution({
    required this.entityType,
    required this.entityId,
    required this.policy,
    required this.resolvedPayload,
    required this.resolutionReason,
    Map<String, dynamic>? localPayload,
    Map<String, dynamic>? serverData,
    this.outcome = ConflictOutcome.applyResolvedPayload,
    this.stockComponentsProtected = false,
    this.localWins = false,
  })  : localPayload = localPayload ?? const {},
        serverData = serverData ?? const {};
}

class ConflictResolver {
  final Map<SyncEntityType, EntitySyncAdapter> _adapters;

  ConflictResolver(this._adapters);

  static DateTime? _tryParseTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  static DateTime? _serverUpdatedAt(Map<String, dynamic> serverData) {
    return _tryParseTime(serverData['updated_at'] ?? serverData['updatedAt']);
  }

  /// Strips stock components from a resolved snapshot payload (ES-1).
  static Map<String, dynamic> _protectStockComponents(
      Map<String, dynamic> payload) {
    final stripped = <String, dynamic>{};
    payload.forEach((k, v) {
      if (!kStockComponentKeys.contains(k)) stripped[k] = v;
    });
    return stripped;
  }

  /// True when two event-like payloads diverge on a quantity-bearing field:
  /// such conflicts are review items, never silently auto-resolved away.
  static bool _eventQuantitiesDiverge(
      Map<String, dynamic> local, Map<String, dynamic> server) {
    const quantityKeys = ['quantity', 'actual_quantity', 'total_items'];
    for (final key in quantityKeys) {
      final l = local[key];
      final s = server[key];
      if (l != null && s != null && l != s) return true;
    }
    return false;
  }

  ConflictResolution? detectAndResolve({
    required SyncEntityType entityType,
    required int entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverData,
    required int localServerVersion,
    required int currentServerVersion,
    DateTime? localUpdatedAt,
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

    return resolveVersionConflict(
      adapter: adapter,
      localPayload: localPayload,
      serverData: serverData,
      localServerVersion: localServerVersion,
      currentServerVersion: currentServerVersion,
      localUpdatedAt: localUpdatedAt,
    );
  }

  ConflictResolution? resolveVersionConflict({
    required EntitySyncAdapter adapter,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverData,
    required int localServerVersion,
    required int currentServerVersion,
    DateTime? localUpdatedAt,
  }) {
    if (localServerVersion >= currentServerVersion) {
      return null;
    }

    final policy = adapter.conflictPolicy;
    final entityTypeLabel = adapter.entityType.label;
    final entityId = (localPayload['id'] ?? 0).toString();

    switch (policy) {
      case ConflictResolutionPolicy.serverAuthoritative:
        // Server projection wins for convergence; local financial rows stay
        // untouched (they are append-only history). Event-like divergence on
        // quantities becomes a REVIEW item instead of silent adoption.
        var outcome = ConflictOutcome.applyResolvedPayload;
        var reason = 'Server-authoritative: server data accepted';
        if (adapter.isEventLike &&
            _eventQuantitiesDiverge(localPayload, serverData)) {
          outcome = ConflictOutcome.requiresReview;
          reason =
              'Server-authoritative: event-like divergence requires review '
              '(local event preserved, server state authoritative)';
        }
        return ConflictResolution(
          entityType: entityTypeLabel,
          entityId: entityId,
          policy: policy,
          resolvedPayload: serverData,
          resolutionReason: reason,
          localPayload: localPayload,
          serverData: serverData,
          outcome: outcome,
        );

      case ConflictResolutionPolicy.lastWriterWins:
      case ConflictResolutionPolicy.latestTimestampWins:
        final localTime = localUpdatedAt ??
            _tryParseTime(
                localPayload['updated_at'] ?? localPayload['updatedAt']);
        final serverTime = _serverUpdatedAt(serverData);
        final bool localIsLater;
        final String basis;
        if (localTime != null && serverTime != null) {
          localIsLater = !localTime.isBefore(serverTime);
          basis = 'timestamps local=$localTime server=$serverTime';
        } else {
          // True writer timestamps unavailable: fall back to accepting the
          // local write (documented legacy behavior), flagged in the reason.
          localIsLater = true;
          basis = 'writer timestamps unavailable; local accepted by fallback';
        }
        final winner = localIsLater ? localPayload : serverData;
        final winnerLabel = localIsLater ? 'local' : 'server';
        final policyLabel = policy == ConflictResolutionPolicy.lastWriterWins
            ? 'LWW'
            : 'Latest timestamp';
        var protected = false;
        var resolved = winner;
        if (adapter.entityType == SyncEntityType.product && !localIsLater) {
          resolved = _protectStockComponents(winner);
          protected = true;
        }
        return ConflictResolution(
          entityType: entityTypeLabel,
          entityId: entityId,
          policy: policy,
          resolvedPayload: resolved,
          resolutionReason:
              '$policyLabel: $winnerLabel payload accepted ($basis)',
          localPayload: localPayload,
          serverData: serverData,
          outcome: ConflictOutcome.applyResolvedPayload,
          stockComponentsProtected: protected,
          localWins: localIsLater,
        );
    }
  }
}
