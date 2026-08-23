import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/sync/adapters/inventory_count_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M M-I06 acceptance suite (plan §28 M-I06, §18, §29-G).
///
/// Proves the frozen inventory-count ordering semantics:
///   IC-1 observed_at device observation time travels with the event
///   IC-2/IC-4 count answers "stock at observed_at"; post-observation
///        events stay visible on top of the counted baseline; canonical
///        scenario count=10 / pre-sale 2 / post-sale 1 → final 9
///   IC-3 latest-OBSERVED count wins; late-arriving older counts are
///        history and never re-adjust newer state
///   IC-5 "latest count wins" as a ROW policy is retired: counts are
///        event-like and never LWW row-merged
void main() {
  final adapter = InventoryCountSyncAdapter();

  group('M-I06 — IC-1 observed_at passthrough', () {
    test(
        'localToCloudPayload carries observed_at (device observation time) '
        'with the count event', () {
      final payload = adapter.localToCloudPayload({
        'productId': 42,
        'actualQuantity': 10,
        'notes': 'shelf count',
        'countDate': '2026-08-20T09:00:00.000',
        'observedAt': '2026-08-20T08:55:00.000Z',
      });

      expect(payload['observed_at'], '2026-08-20T08:55:00.000Z',
          reason: 'the explicit device observation time must win');
    });

    test(
        'legacy rows without observedAt fall back to count_date '
        '(additive compatibility)', () {
      final payload = adapter.localToCloudPayload({
        'productId': 42,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-01T10:00:00.000',
      });

      expect(payload['observed_at'], '2026-07-01T10:00:00.000');
    });

    test('cloudToLocalRow maps server observed_at back into the local row', () {
      final row = adapter.cloudToLocalRow({
        'product_id': 'cloud-product-1',
        'actual_quantity': 9,
        'notes': '',
        'count_date': '2026-08-21T10:00:00+00:00',
        'observed_at': '2026-08-21T09:58:00+00:00',
      });

      expect(row['observedAt'], '2026-08-21T09:58:00+00:00');
      expect(row['actualQuantity'], 9);
    });

    test('cloudToLocalRow tolerates servers without observed_at yet', () {
      final row = adapter.cloudToLocalRow({
        'product_id': 'cloud-product-1',
        'actual_quantity': 5,
        'notes': '',
        'count_date': '2026-08-21T10:00:00+00:00',
      });

      expect(row.containsKey('observedAt'), isFalse);
    });
  });

  group('M-I06 — IC-1 clock-skew protection', () {
    test('future observed_at is clamped to arrival', () {
      final arrival = DateTime.utc(2026, 8, 20, 12, 0);
      final skewed = DateTime.utc(2026, 8, 20, 15, 0); // device +3h ahead

      expect(
        InventoryCountOrdering.clampObservedToArrival(skewed, arrival),
        arrival,
      );
    });

    test('past/honest observed_at passes through unclamped', () {
      final arrival = DateTime.utc(2026, 8, 20, 12, 0);
      final honest = DateTime.utc(2026, 8, 20, 11, 30);

      expect(
        InventoryCountOrdering.clampObservedToArrival(honest, arrival),
        honest,
      );
    });
  });

  group('M-I06 — IC-3 latest-OBSERVED wins', () {
    test(
        'late arrival of an OLDER count does NOT replace the standing '
        'newer observation', () {
      final standingObservedAt = DateTime.utc(2026, 8, 20, 15, 0);
      late final lateArrival = DateTime.utc(2026, 8, 20, 9, 0);

      expect(
        InventoryCountOrdering.isStandingAgainst(
          observedAt: lateArrival,
          latestAppliedObservedAt: standingObservedAt,
        ),
        isFalse,
        reason: 'older count arriving late is history only — never re-adjusts',
      );
    });

    test('a genuinely newer count supersedes the previous standing one', () {
      expect(
        InventoryCountOrdering.isStandingAgainst(
          observedAt: DateTime.utc(2026, 8, 21, 8, 0),
          latestAppliedObservedAt: DateTime.utc(2026, 8, 20, 15, 0),
        ),
        isTrue,
      );
    });

    test('first count for a product is always standing', () {
      expect(
        InventoryCountOrdering.isStandingAgainst(
          observedAt: DateTime.utc(2026, 8, 19, 8, 0),
        ),
        isTrue,
      );
    });

    test('equal observation times keep the later arrival standing (>= rule)',
        () {
      final t = DateTime.utc(2026, 8, 20, 10, 0);
      expect(
        InventoryCountOrdering.isStandingAgainst(
          observedAt: t,
          latestAppliedObservedAt: t,
        ),
        isTrue,
      );
    });
  });

  group('M-I06 — IC-2/IC-4 canonical derivation', () {
    test(
        'canonical scenario: count=10 at T; sale of 2 BEFORE T absorbed by '
        'baseline; sale of 1 AFTER T stays visible → final stock = 9', () {
      // Events already applied on the server relative to observed_at T:
      //   - sale qty 2 at T-5min  → PRE-count: inside the counted baseline
      //   - sale qty 1 at T+10min → POST-count: re-applies on top
      const observedQuantity = 10;
      const preObservationSales = 2; // absorbed — NOT subtracted again
      const postObservationSales = 1;
      const postObservationReturns = 0;

      final desiredCurrent = InventoryCountOrdering.resolveDesiredCurrent(
        observedQuantity: observedQuantity,
        postObservationSales: postObservationSales,
        postObservationReturns: postObservationReturns,
      );

      expect(desiredCurrent, 9,
          reason: 'IC-4 frozen outcome: 10 − 1 = 9; the pre-count sale of 2 '
              'is inside the baseline and must not double-subtract');
      expect(preObservationSales, 2); // documented as part of the scenario
    });

    test('post-observation returns increase the projected current', () {
      expect(
        InventoryCountOrdering.resolveDesiredCurrent(
          observedQuantity: 10,
          postObservationSales: 3,
          postObservationReturns: 2,
        ),
        9,
      );
    });

    test('no post-observation events → projection equals observation', () {
      expect(
        InventoryCountOrdering.resolveDesiredCurrent(
          observedQuantity: 7,
          postObservationSales: 0,
          postObservationReturns: 0,
        ),
        7,
      );
    });

    test(
        'adjustment delta keeps the inventory equation exact '
        '(current = opening − sold + returned + adjustment)', () {
      // Product state when a standing count lands: opening=20, sold=14,
      // returned=1, adjustment=0 → current=7. Observation says stock was 10
      // at T, with 1 post-T sale → desired=9.
      const opening = 20, sold = 14, returned = 1, adjustment = 0;
      final current = opening - sold + returned + adjustment;
      expect(current, 7);

      final desired = InventoryCountOrdering.resolveDesiredCurrent(
        observedQuantity: 10,
        postObservationSales: 1,
        postObservationReturns: 0,
      );
      final delta = InventoryCountOrdering.adjustmentDelta(
        desiredCurrent: desired,
        currentQuantity: current,
      );

      expect(delta, 2);

      final newCurrent = opening - sold + returned + (adjustment + delta);
      expect(newCurrent, desired,
          reason: 'after applying the delta the equation must hold exactly');
    });
  });

  group('M-I06 — IC-5 counts are events, never row-LWW-merged', () {
    test('inventoryCount remains event-like in the entity model', () {
      expect(SyncEntityType.inventoryCount.isEventLike, isTrue);
      expect(adapter.isEventLike, isTrue);
    });

    test(
        'a quantity-divergent count conflict resolves to REVIEW_REQUIRED, '
        'never an auto-discarding row merge', () {
      final adapters = <SyncEntityType, EntitySyncAdapter>{
        SyncEntityType.inventoryCount: adapter,
      };
      final resolver = ConflictResolver(adapters);

      final resolution = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {
          'product_id': 'p1',
          'actual_quantity': 10,
          'count_date': '2026-08-20T10:00:00Z',
        },
        serverData: {
          'product_id': 'p1',
          'actual_quantity': 4,
          'count_date': '2026-08-20T10:05:00Z',
        },
        localServerVersion: 1,
        currentServerVersion: 3,
      );

      expect(resolution, isNotNull);
      expect(resolution!.outcome, ConflictOutcome.requiresReview,
          reason: 'event-like divergence on quantities must become durable '
              'review evidence — never a silent LWW overwrite');
    });
  });
}
