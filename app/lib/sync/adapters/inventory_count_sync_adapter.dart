import 'entity_sync_adapter.dart';
import '../sync_status.dart';

class InventoryCountSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.inventoryCount;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.latestTimestampWins;

  @override
  String get localTableName => 'inventory_count';

  @override
  String get cloudTableName => 'cloud_inventory_count';

  @override
  String get requiredPermission => 'stocktake.view';

  @override
  bool get isServerAuthoritative => false;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    return {
      'product_id': localRow['productId'] as int,
      'actual_quantity': localRow['actualQuantity'] as int? ?? 0,
      'notes': localRow['notes'] as String? ?? '',
      'count_date': localRow['countDate'] as String,
      // Phase M §18 IC-1: device observation time travels with the event.
      // Falls back to count_date for legacy rows that predate observed_at.
      'observed_at': (localRow['observedAt'] as String?) ??
          localRow['countDate'] as String,
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'productId': cloudRow['product_id'] as String,
      'actualQuantity': cloudRow['actual_quantity'] as int? ?? 0,
      'notes': cloudRow['notes'] as String? ?? '',
      'countDate': cloudRow['count_date'] as String,
      if (cloudRow['observed_at'] != null)
        'observedAt': cloudRow['observed_at'] as String,
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

/// Phase M §18 — FROZEN count-ordering semantics, mirrored client-side as a
/// pure Dart derivation so the canonical scenarios (IC-3, IC-4) are provable
/// deterministically. This mirrors `save_cloud_inventory_count_v2` in
/// migration 28 exactly; the server remains the authority.
class InventoryCountOrdering {
  InventoryCountOrdering._();

  /// IC-1 clock-skew protection: a future observed_at is clamped to server
  /// arrival time; the skew surfaces in audit instead of corrupting order.
  static DateTime clampObservedToArrival(
      DateTime observedAt, DateTime arrival) {
    if (observedAt.isAfter(arrival)) return arrival;
    return observedAt;
  }

  /// IC-3: latest-OBSERVED count wins as the standing observation. An older
  /// late-arriving count is history only and never re-adjusts newer state.
  static bool isStandingAgainst({
    required DateTime observedAt,
    DateTime? latestAppliedObservedAt,
  }) {
    return latestAppliedObservedAt == null ||
        !observedAt.isBefore(latestAppliedObservedAt);
  }

  /// IC-2/IC-4: the count answers "how much stock existed at observed_at".
  /// Events already applied whose operation time is AFTER the observation
  /// stay visible on top of the counted baseline:
  ///   desired_current = observed − post_sales + post_returns
  /// Pre-observation queued events are absorbed by the counted baseline
  /// (their effect is INSIDE the observed number).
  static int resolveDesiredCurrent({
    required int observedQuantity,
    required int postObservationSales,
    required int postObservationReturns,
  }) {
    return observedQuantity - postObservationSales + postObservationReturns;
  }

  /// Adjustment delta the standing count must contribute to keep the
  /// inventory equation exact (mirrors v_delta in migration 28).
  static int adjustmentDelta({
    required int desiredCurrent,
    required int currentQuantity,
  }) {
    return desiredCurrent - currentQuantity;
  }
}
