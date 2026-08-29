import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/expense_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

void main() {
  late ConflictResolver resolver;
  late Map<SyncEntityType, EntitySyncAdapter> adapters;

  setUp(() {
    adapters = {
      SyncEntityType.product: ProductSyncAdapter(),
      SyncEntityType.sale: SaleSyncAdapter(),
      SyncEntityType.expense: ExpenseSyncAdapter(),
    };
    resolver = ConflictResolver(adapters);
  });

  group('ConflictResolver.detectAndResolve', () {
    test('returns null when local version >= server version', () {
      final result = resolver.detectAndResolve(
        entityType: SyncEntityType.product,
        entityId: 1,
        localPayload: {'name': 'Widget'},
        serverData: {'name': 'Gadget'},
        localServerVersion: 5,
        currentServerVersion: 5,
      );

      expect(result, isNull);
    });

    test('returns null when local version > server version', () {
      final result = resolver.detectAndResolve(
        entityType: SyncEntityType.product,
        entityId: 1,
        localPayload: {'name': 'Widget'},
        serverData: {'name': 'Gadget'},
        localServerVersion: 6,
        currentServerVersion: 5,
      );

      expect(result, isNull);
    });

    test('LWW policy accepts local payload', () {
      final result = resolver.detectAndResolve(
        entityType: SyncEntityType.product,
        entityId: 1,
        localPayload: {'name': 'Local Version'},
        serverData: {'name': 'Server Version'},
        localServerVersion: 3,
        currentServerVersion: 5,
      );

      expect(result, isNotNull);
      expect(result!.policy, ConflictResolutionPolicy.lastWriterWins);
      expect(result.resolvedPayload['name'], 'Local Version');
      expect(result.resolutionReason, contains('LWW'));
    });

    test('server-authoritative policy accepts server data', () {
      final result = resolver.detectAndResolve(
        entityType: SyncEntityType.sale,
        entityId: 1,
        localPayload: {'quantity': 5},
        serverData: {'quantity': 10},
        localServerVersion: 1,
        currentServerVersion: 3,
      );

      expect(result, isNotNull);
      expect(result!.policy, ConflictResolutionPolicy.serverAuthoritative);
      expect(result.resolvedPayload['quantity'], 10);
      expect(result.resolutionReason, contains('Server-authoritative'));
    });

    test('throws when no adapter found for entity type', () {
      expect(
        () => resolver.detectAndResolve(
          entityType: SyncEntityType.invoice,
          entityId: 1,
          localPayload: {},
          serverData: {},
          localServerVersion: 1,
          currentServerVersion: 2,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ConflictResolver.resolveVersionConflict', () {
    test('returns null when no conflict (local version >= server)', () {
      final adapter = ProductSyncAdapter();
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'name': 'Widget'},
        serverData: {'name': 'Gadget'},
        localServerVersion: 5,
        currentServerVersion: 3,
      );

      expect(result, isNull);
    });

    test('LWW adapter returns local payload', () {
      final adapter = ProductSyncAdapter();
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'name': 'Local'},
        serverData: {'id': 1, 'name': 'Server'},
        localServerVersion: 2,
        currentServerVersion: 4,
      );

      expect(result, isNotNull);
      expect(result!.resolvedPayload['name'], 'Local');
      expect(result.policy, ConflictResolutionPolicy.lastWriterWins);
    });

    test('server-authoritative adapter returns server data', () {
      final adapter = SaleSyncAdapter();
      final result = resolver.resolveVersionConflict(
        adapter: adapter,
        localPayload: {'id': 1, 'quantity': 5},
        serverData: {'id': 1, 'quantity': 10},
        localServerVersion: 1,
        currentServerVersion: 3,
      );

      expect(result, isNotNull);
      expect(result!.resolvedPayload['quantity'], 10);
      expect(result.policy, ConflictResolutionPolicy.serverAuthoritative);
    });
  });

  group('Adapter conflict policies', () {
    test('ProductSyncAdapter uses LWW', () {
      expect(ProductSyncAdapter().conflictPolicy,
          ConflictResolutionPolicy.lastWriterWins);
    });

    test('SaleSyncAdapter uses server-authoritative', () {
      expect(SaleSyncAdapter().conflictPolicy,
          ConflictResolutionPolicy.serverAuthoritative);
    });

    test('ExpenseSyncAdapter uses LWW', () {
      expect(ExpenseSyncAdapter().conflictPolicy,
          ConflictResolutionPolicy.lastWriterWins);
    });
  });
}
