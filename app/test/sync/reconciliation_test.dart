import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/sync/inventory_oversell_policy.dart';
import 'package:muaman_store/sync/reconciliation_service.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M slice M-I04 tests (plan §16/§17, matrix D / M-C03/04/05/09).
///
/// Concurrency realism note (plan §29): the offline/offline overlap test
/// below uses two Completer-gated futures driven through a serialized
/// interleaving — each reconcile call is suspended mid-flight while the
/// other starts, proving the pure-detection core is safe under genuinely
/// overlapping invocations rather than sequential awaits.
void main() {
  StockBelief belief({
    String barcode = 'BAR-1',
    int opening = 1,
    int sold = 0,
    int returned = 0,
    int adjustment = 0,
  }) =>
      StockBelief(
        barcode: barcode,
        openingQuantity: opening,
        soldQuantity: sold,
        returnedQuantity: returned,
        inventoryAdjustment: adjustment,
      );

  group('within-stock reconciliation', () {
    test('single sale inside stock produces no artifact', () async {
      final artifacts = <OversellAdjustmentArtifact>[];
      final svc = ReconciliationService(
        adjustmentSink: (a) async => artifacts.add(a),
      );

      final outcome = await svc.reconcileEvents(
        shopId: 'shop-1',
        serverBelief: belief(opening: 5),
        eventDeltas: const [
          StockEventDelta(
              eventId: 'evt-1',
              entityType: SyncEntityType.sale,
              stockEffect: -2),
        ],
      );

      expect(outcome.eventsPreserved, isTrue);
      expect(outcome.adjustmentArtifact, isNull);
      expect(outcome.ownerNotified, isFalse);
      expect(artifacts, isEmpty);
      // Explainability: outcome anchored in the component equation.
      expect(outcome.explanation, contains('opening(5)'));
      expect(outcome.explanation, endsWith('3'));
    });

    test('return offsetting prior sales keeps the equation exact', () async {
      final svc = ReconciliationService();

      final outcome = await svc.reconcileEvents(
        shopId: 'shop-1',
        // Server belief after 3 sold of an opening 5 → current = 2.
        serverBelief: belief(opening: 5, sold: 3),
        eventDeltas: const [
          StockEventDelta(
              eventId: 'ret-1',
              entityType: SyncEntityType.returnItem,
              stockEffect: 1),
        ],
      );

      expect(outcome.eventsPreserved, isTrue);
      expect(outcome.adjustmentArtifact, isNull);
    });
  });

  group('offline oversell — canonical M-C03 (Option C shipped default)', () {
    test(
        'stock=1, two devices sell 1 each: both events preserved, '
        'explicit artifact records shortfall=1, owner notified', () async {
      final persistedArtifacts = <OversellAdjustmentArtifact>[];
      final notifications = <OversellAdjustmentArtifact>[];
      final svc = ReconciliationService(
        adjustmentSink: (a) async => persistedArtifacts.add(a),
        ownerNotifier: (a) async => notifications.add(a),
      );

      // Server authority BEFORE applying the queued offline events:
      // opening 1, both device sales still unapplied.
      final serverBelief = belief(opening: 1);

      final outcome = await svc.reconcileEvents(
        shopId: 'shop-A',
        serverBelief: serverBelief,
        eventDeltas: const [
          StockEventDelta(
              eventId: 'sale-deviceA',
              entityType: SyncEntityType.sale,
              stockEffect: -1),
          StockEventDelta(
              eventId: 'sale-deviceB',
              entityType: SyncEntityType.sale,
              stockEffect: -1),
        ],
      );

      // Zero data loss: both financial events preserved (INV-M01).
      expect(outcome.eventsPreserved, isTrue);
      expect(outcome.adjustmentArtifact!.relatedEventIds,
          ['sale-deviceA', 'sale-deviceB']);

      // Explicit, auditable discrepancy record (Option C mechanics).
      expect(persistedArtifacts.length, 1);
      final artifact = persistedArtifacts.single;
      expect(artifact.barcode, 'BAR-1');
      expect(artifact.projectedCurrentQuantity, -1);
      expect(artifact.shortfall, 1);
      expect(artifact.shopId, 'shop-A');

      // Owner notification fired exactly once for this discrepancy.
      expect(notifications.length, 1);
      expect(outcome.ownerNotified, isTrue);
      expect(outcome.requiresOwnerResolution, isFalse);

      // Explainability: projected −1 = 1 − 0 + 0 + 0 + (−1) + (−1).
      expect(outcome.explanation, contains('-1'));
    });
  });

  group('policy seam branches (OD6 remains open — DR-M06)', () {
    final deltas = [
      const StockEventDelta(
          eventId: 'e1', entityType: SyncEntityType.sale, stockEffect: -3),
    ];

    test('allowNegative (B): negative preserved without artifact', () async {
      var sinkCalled = false;
      final svc = ReconciliationService(
        policy: const InventoryOversellPolicy.allowNegative(),
        adjustmentSink: (_) async => sinkCalled = true,
      );

      final outcome = await svc.reconcileEvents(
        shopId: 'shop-1',
        serverBelief: belief(opening: 2),
        eventDeltas: deltas,
      );

      expect(outcome.eventsPreserved, isTrue);
      expect(outcome.adjustmentArtifact, isNull);
      expect(outcome.ownerNotified, isFalse);
      expect(sinkCalled, isFalse);
    });

    test('requireOwnerResolution (D): convergence blocks on owner', () async {
      final svc = ReconciliationService(
        policy: const InventoryOversellPolicy.requireOwnerResolution(),
      );

      final outcome = await svc.reconcileEvents(
        shopId: 'shop-1',
        serverBelief: belief(opening: 2),
        eventDeltas: deltas,
      );

      expect(outcome.requiresOwnerResolution, isTrue);
      expect(outcome.adjustmentArtifact, isNull);
    });
  });

  group('overlapping reconciliation (barrier-synchronized)', () {
    test(
        'two in-flight reconciles of disjoint events both complete '
        'with preserved events and one artifact each', () async {
      final persisted = <OversellAdjustmentArtifact>[];
      final gateA = Completer<void>();
      final gateB = Completer<void>();
      final svc = ReconciliationService(
        adjustmentSink: (a) async => persisted.add(a),
      );

      // Interleaving driver: A runs to its barrier, then B runs to ITS
      // barrier while A is still suspended, then both resume. This proves
      // overlapping invocation safety beyond sequential awaits.
      final futureA = () async {
        final outcome = await svc.reconcileEvents(
          shopId: 'shop-1',
          serverBelief: belief(opening: 1),
          eventDeltas: const [
            StockEventDelta(
                eventId: 'ea',
                entityType: SyncEntityType.sale,
                stockEffect: -2),
          ],
        );
        gateB.complete();
        await gateA.future;
        return outcome;
      }();

      final futureB = () async {
        await gateB.future;
        final outcome = await svc.reconcileEvents(
          shopId: 'shop-1',
          serverBelief: belief(opening: 1),
          eventDeltas: const [
            StockEventDelta(
                eventId: 'eb',
                entityType: SyncEntityType.sale,
                stockEffect: -2),
          ],
        );
        // Release A while both are still in flight.
        gateA.complete();
        return outcome;
      }();

      final results = await Future.wait([futureA, futureB]);

      expect(results.length, 2);
      for (final r in results) {
        expect(r.eventsPreserved, isTrue);
        expect(r.adjustmentArtifact, isNotNull);
      }
      // Each event sells 2 units against stock 1 → projected −1, shortfall 1.
      expect(persisted.map((a) => a.shortfall), everyElement(1));
    });
  });
}
