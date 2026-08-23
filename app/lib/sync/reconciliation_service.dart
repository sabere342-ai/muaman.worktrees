import 'inventory_oversell_policy.dart';
import 'sync_status.dart';

/// One device's (or the server's) belief about a product's stock components.
///
/// The inventory equation is the ONLY explainability contract:
///   currentQuantity = opening − sold + returned + adjustment
class StockBelief {
  final String barcode;
  final int openingQuantity;
  final int soldQuantity;
  final int returnedQuantity;
  final int inventoryAdjustment;

  const StockBelief({
    required this.barcode,
    required this.openingQuantity,
    required this.soldQuantity,
    required this.returnedQuantity,
    required this.inventoryAdjustment,
  });

  int get currentQuantity =>
      openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment;
}

/// The durable, auditable artifact produced when offline events oversell
/// server stock under the Option-C default (plan §16 OF-1/OF-2, §17).
///
/// It records the discrepancy explicitly — it NEVER rewrites or deletes the
/// preserved financial events, and it never touches COGS/cost snapshots.
class OversellAdjustmentArtifact {
  final String shopId;
  final String barcode;

  /// Server-authoritative computed stock after applying ALL preserved
  /// events (may be negative; SG-10 proves negative current is
  /// representable and equation-explainable).
  final int projectedCurrentQuantity;

  /// How far below zero the projected stock fell (= -projected when
  /// negative). Zero when no discrepancy exists.
  final int shortfall;

  /// The financial events whose application caused the divergence. Kept as
  /// references so every outcome stays explainable event-by-event.
  final List<String> relatedEventIds;

  final DateTime detectedAt;

  const OversellAdjustmentArtifact({
    required this.shopId,
    required this.barcode,
    required this.projectedCurrentQuantity,
    required this.shortfall,
    required this.relatedEventIds,
    required this.detectedAt,
  });
}

/// Outcome of reconciling one batch of offline stock-touching events.
class ReconciliationOutcome {
  /// All events were preserved (INV-M01: no legitimate financial event is
  /// ever lost by reconciliation).
  final bool eventsPreserved;

  /// Non-null when the policy seam produced an explicit adjustment
  /// artifact for the discrepancy (Option C).
  final OversellAdjustmentArtifact? adjustmentArtifact;

  /// True when convergence must wait for owner action (Option D branch of
  /// the seam) — the corresponding conflict becomes REVIEW_REQUIRED.
  final bool requiresOwnerResolution;

  /// True when an owner notification was emitted for the discrepancy.
  final bool ownerNotified;

  /// Human-readable explanation anchored in the stock equation.
  final String explanation;

  const ReconciliationOutcome({
    required this.eventsPreserved,
    required this.explanation,
    this.adjustmentArtifact,
    this.requiresOwnerResolution = false,
    this.ownerNotified = false,
  });
}

/// Offline oversell detection + policy-isolated reconciliation
/// (Phase M plan §16/§17, slices M-I04/M-I05).
///
/// The service is PURE with respect to storage: durable artifact creation
/// and conflict persistence are delegated to injected sinks so the OD6
/// policy choice can never leak into engine behavior and tests can drive
/// deterministic scenarios (M-C03/04/05/09).
class ReconciliationService {
  /// Frozen decision point — never duplicated inside callers.
  final InventoryOversellPolicy policy;

  /// Persists the adjustment artifact durably (local audit/cloud record).
  /// Must be transactional at its call site together with any queue
  /// lifecycle transition (INV-M17).
  final Future<void> Function(OversellAdjustmentArtifact artifact)?
      adjustmentSink;

  /// Owner notification channel (alert/banner). Failures here must never
  /// block or revert reconciliation.
  final Future<void> Function(OversellAdjustmentArtifact artifact)?
      ownerNotifier;

  const ReconciliationService({
    this.policy = InventoryOversellPolicy.shippedDefault,
    this.adjustmentSink,
    this.ownerNotifier,
  });

  /// Reconciles offline sale/return EVENTS against the SERVER stock
  /// authority (DR-M01).
  ///
  /// [serverBelief] is the authoritative component state BEFORE applying
  /// [eventDeltas]; each delta is one preserved financial event (+sale
  /// quantity / −return quantity on stock).
  Future<ReconciliationOutcome> reconcileEvents({
    required String shopId,
    required StockBelief serverBelief,
    required List<StockEventDelta> eventDeltas,
  }) async {
    // Apply every event in arrival order — events are immutable truth and
    // are applied, never merged (IA-3/IA-5).
    var projected = serverBelief.currentQuantity;
    final appliedEventIds = <String>[];
    for (final delta in eventDeltas) {
      projected += delta.stockEffect;
      appliedEventIds.add(delta.eventId);
    }

    final explanation = 'opening(${serverBelief.openingQuantity}) '
        '− sold(${serverBelief.soldQuantity}) '
        '+ returned(${serverBelief.returnedQuantity}) '
        '+ adjustment(${serverBelief.inventoryAdjustment}) '
        '${eventDeltas.isEmpty ? '' : '+ applied events → '}'
        '$projected';

    if (projected >= 0) {
      return ReconciliationOutcome(
        eventsPreserved: true,
        explanation: explanation,
      );
    }

    // Oversold: preserve all events (zero data loss), then let the frozen
    // seam decide the discrepancy handling.
    final artifact = OversellAdjustmentArtifact(
      shopId: shopId,
      barcode: serverBelief.barcode,
      projectedCurrentQuantity: projected,
      shortfall: -projected,
      relatedEventIds: appliedEventIds,
      detectedAt: DateTime.now().toUtc(),
    );

    if (policy.createsAdjustmentArtifact) {
      final sink = adjustmentSink;
      if (sink != null) await sink(artifact);
      final notifier = ownerNotifier;
      if (notifier != null) await notifier(artifact);
      return ReconciliationOutcome(
        eventsPreserved: true,
        adjustmentArtifact: artifact,
        ownerNotified: notifier != null,
        explanation:
            '$explanation; discrepancy recorded as explicit adjustment '
            'artifact (shortfall ${artifact.shortfall})',
      );
    }

    if (policy.blocksUntilOwnerResolves) {
      return ReconciliationOutcome(
        eventsPreserved: true,
        requiresOwnerResolution: true,
        explanation: '$explanation; held for owner resolution',
      );
    }

    // allowNegative (Option B): keep the negative derived stock — it is
    // equation-explainable — without an extra artifact.
    return ReconciliationOutcome(
      eventsPreserved: true,
      explanation: '$explanation; negative derived stock preserved',
    );
  }
}

/// One preserved financial event expressed as its stock effect.
class StockEventDelta {
  final String eventId;
  final SyncEntityType entityType;

  /// Effect on current quantity: sales are negative, returns positive.
  final int stockEffect;

  const StockEventDelta({
    required this.eventId,
    required this.entityType,
    required this.stockEffect,
  });
}
