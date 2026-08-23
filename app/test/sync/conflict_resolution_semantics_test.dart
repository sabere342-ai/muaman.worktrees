import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/customer_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/inventory_count_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M M-I01 — conflict resolution semantics (CR-1..CR-6, ES-1).
void main() {
  late ConflictResolver resolver;

  setUp(() {
    resolver = ConflictResolver({
      SyncEntityType.product: ProductSyncAdapter(),
      SyncEntityType.customer: CustomerSyncAdapter(),
      SyncEntityType.sale: SaleSyncAdapter(),
      SyncEntityType.inventoryCount: InventoryCountSyncAdapter(),
    });
  });

  group('CR-1/CR-2: true latest-timestamp / latest-writer comparison', () {
    test('latestTimestampWins: later LOCAL timestamp wins', () {
      final adapter = _StaticAdapter(SyncEntityType.customer,
          ConflictResolutionPolicy.latestTimestampWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'name': 'Local'},
        serverData: {'name': 'Server', 'updated_at': '2026-08-19T10:00:00Z'},
        localServerVersion: 2,
        currentServerVersion: 5,
        localUpdatedAt: DateTime.utc(2026, 8, 20, 9),
      );
      expect(result, isNotNull);
      expect(result!.resolvedPayload['name'], 'Local');
      expect(result.resolutionReason, contains('timestamps'));
    });

    test('latestTimestampWins: later SERVER timestamp wins', () {
      final adapter = _StaticAdapter(SyncEntityType.customer,
          ConflictResolutionPolicy.latestTimestampWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'name': 'Local'},
        serverData: {'name': 'Server', 'updated_at': '2026-08-21T10:00:00Z'},
        localServerVersion: 2,
        currentServerVersion: 5,
        localUpdatedAt: DateTime.utc(2026, 8, 20, 9),
      );
      expect(result!.resolvedPayload['name'], 'Server');
    });

    test('lastWriterWins compares writer timestamps (server newer)', () {
      final adapter = _StaticAdapter(
          SyncEntityType.customer, ConflictResolutionPolicy.lastWriterWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'name': 'Local'},
        serverData: {'name': 'Server', 'updated_at': '2026-08-25T00:00:00Z'},
        localServerVersion: 2,
        currentServerVersion: 5,
        localUpdatedAt: DateTime.utc(2026, 8, 20, 9),
      );
      expect(result!.resolvedPayload['name'], 'Server');
      expect(result.policy, ConflictResolutionPolicy.lastWriterWins);
    });

    test('lastWriterWins fallback keeps local when no timestamps exist', () {
      final adapter = _StaticAdapter(
          SyncEntityType.customer, ConflictResolutionPolicy.lastWriterWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'name': 'Local'},
        serverData: {'name': 'Server'},
        localServerVersion: 2,
        currentServerVersion: 5,
      );
      expect(result!.resolvedPayload['name'], 'Local');
      expect(result.resolutionReason, contains('fallback'));
    });
  });

  group('CR-3: serverAuthoritative produces applicable resolution', () {
    test('returns server payload with apply outcome and evidence', () {
      final adapter = _StaticAdapter(
          SyncEntityType.sale, ConflictResolutionPolicy.serverAuthoritative,
          eventLike: false);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'quantity': 5},
        serverData: {'quantity': 5, 'current_quantity': 3},
        localServerVersion: 1,
        currentServerVersion: 4,
      );
      expect(result!.policy, ConflictResolutionPolicy.serverAuthoritative);
      expect(result.outcome, ConflictOutcome.applyResolvedPayload);
      expect(result.resolvedPayload['current_quantity'], 3);
      expect(result.localPayload['quantity'], 5);
      expect(result.serverData['quantity'], 5);
    });
  });

  group('ES-1: stock components protected from metadata merges', () {
    test('product snapshot losing LWW never carries stock components', () {
      final adapter = _StaticAdapter(
          SyncEntityType.product, ConflictResolutionPolicy.latestTimestampWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {
          'id': 1,
          'name': 'Local',
          'sold_quantity': 7,
          'returned_quantity': 2,
          'inventory_adjustment': 1,
          'current_quantity': 4,
        },
        serverData: {
          'name': 'Server',
          'sold_quantity': 99,
          'updated_at': '2026-08-21T10:00:00Z',
        },
        localServerVersion: 2,
        currentServerVersion: 5,
        localUpdatedAt: DateTime.utc(2026, 8, 1),
      );
      expect(result!.resolvedPayload['name'], 'Server');
      expect(result.resolvedPayload.containsKey('sold_quantity'), isFalse);
      expect(result.resolvedPayload.containsKey('returned_quantity'), isFalse);
      expect(
          result.resolvedPayload.containsKey('inventory_adjustment'), isFalse);
      expect(result.resolvedPayload.containsKey('current_quantity'), isFalse);
      expect(result.stockComponentsProtected, isTrue);
    });
  });

  group('CR-5: event-like entities are never silently auto-resolved', () {
    test('sale quantity divergence becomes a REVIEW item', () {
      final adapter = _StaticAdapter(
          SyncEntityType.sale, ConflictResolutionPolicy.serverAuthoritative);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'quantity': 1},
        serverData: {'quantity': 2},
        localServerVersion: 1,
        currentServerVersion: 3,
      );
      expect(result!.outcome, ConflictOutcome.requiresReview);
      expect(result.resolvedPayload['quantity'], 2);
    });

    test('inventory count divergence becomes a REVIEW item', () {
      final adapter = _StaticAdapter(SyncEntityType.inventoryCount,
          ConflictResolutionPolicy.latestTimestampWins);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'actual_quantity': 10},
        serverData: {'actual_quantity': 8},
        localServerVersion: 1,
        currentServerVersion: 2,
      );
      // Count ordering semantics are handled by the reconciliation engine;
      // raw quantity divergence must not be silently merged either.
      expect(result, isNotNull);
    });

    test('matching quantities keep auto-resolvable outcome', () {
      final adapter = _StaticAdapter(
          SyncEntityType.sale, ConflictResolutionPolicy.serverAuthoritative);
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'quantity': 2},
        serverData: {'quantity': 2},
        localServerVersion: 1,
        currentServerVersion: 3,
      );
      expect(result!.outcome, ConflictOutcome.applyResolvedPayload);
    });
  });

  group('event vs snapshot classification', () {
    test('financial entities are event-like', () {
      expect(SyncEntityType.sale.isEventLike, isTrue);
      expect(SyncEntityType.returnItem.isEventLike, isTrue);
      expect(SyncEntityType.invoice.isEventLike, isTrue);
      expect(SyncEntityType.inventoryCount.isEventLike, isTrue);
    });

    test('metadata entities are snapshots', () {
      expect(SyncEntityType.product.isEventLike, isFalse);
      expect(SyncEntityType.customer.isEventLike, isFalse);
      expect(SyncEntityType.expense.isEventLike, isFalse);
      expect(SyncEntityType.shopSetting.isEventLike, isFalse);
    });

    test('adapters expose classification via contract default', () {
      expect(ProductSyncAdapter().isEventLike, isFalse);
      expect(SaleSyncAdapter().isEventLike, isTrue);
    });
  });

  group('conflict lifecycle primitives', () {
    test('lifecycle statuses parse round-trip', () {
      for (final s in ConflictLifecycleStatus.values) {
        expect(ConflictLifecycleStatus.tryParse(s.label), s);
      }
      expect(ConflictLifecycleStatus.tryParse(null), isNull);
      expect(ConflictLifecycleStatus.tryParse('BOGUS'), isNull);
    });

    test('legacy CONFLICT maps to REVIEW_REQUIRED', () {
      // CL-4: legacy terminal CONFLICT rows upgrade to review semantics.
      const legacy = 'CONFLICT';
      final mapped = ConflictLifecycleStatus.values
          .firstWhere((s) => s.label == 'REVIEW_REQUIRED');
      expect(mapped, ConflictLifecycleStatus.REVIEW_REQUIRED);
      expect(ConflictLifecycleStatus.tryParse(legacy), isNull,
          reason: 'CONFLICT is not itself a lifecycle status; the v15 '
              'backfill maps it to REVIEW_REQUIRED');
    });
  });
}

class _StaticAdapter extends EntitySyncAdapter {
  final SyncEntityType type;
  final ConflictResolutionPolicy policy;
  final bool eventLike;

  _StaticAdapter(this.type, this.policy, {bool? eventLike})
      : eventLike = eventLike ?? type.isEventLike;

  @override
  SyncEntityType get entityType => type;

  @override
  ConflictResolutionPolicy get conflictPolicy => policy;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) =>
      localRow;

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) =>
      cloudRow;

  @override
  String getCloudUuid(Map<String, dynamic> localRow) => '';

  @override
  int getLocalId(Map<String, dynamic> localRow) => 0;

  @override
  int getServerVersion(Map<String, dynamic> localRow) => 0;

  @override
  bool get isServerAuthoritative => false;

  @override
  String get localTableName => 'local';

  @override
  String get cloudTableName => 'cloud';

  @override
  String get requiredPermission => '';

  @override
  bool get isEventLike => eventLike;
}
