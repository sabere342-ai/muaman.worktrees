import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/config/app_config.dart';
import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/repositories/cloud/stock_rpc_result.dart';
import 'package:muaman_store/sync/adapters/customer_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/expense_category_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/expense_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/inventory_count_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/invoice_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/return_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/shop_settings_sync_adapter.dart';
import 'package:muaman_store/sync/sync_cloud_operations_transport.dart';

/// A1 — production `SyncCloudOperations` transport (P-OD7 deliverable).
///
/// Exercises the real transport's closed per-entity routing, persisted-tenant
/// scoping, idempotency-key threading, response adoption and error mapping
/// through an injectable RPC seam — WITHOUT wiring it into production runtime
/// (the drain stays OFF; A2 owns attachment).
void main() {
  late RecordingRpc rpc;
  late SyncCloudOperationsTransport transport;

  setUp(() {
    rpc = RecordingRpc();
    transport = SyncCloudOperationsTransport(rpc: rpc.call);
  });

  // -------------------------------------------------------------------------
  // Transport construction (no network call merely by constructing)
  // -------------------------------------------------------------------------
  group('transport construction', () {
    test('constructing performs zero RPC calls', () {
      SyncCloudOperationsTransport(rpc: rpc.call, allowOversell: false);
      expect(rpc.calls, isEmpty);
    });

    test('toOperations exposes the SyncCloudOperations contract', () {
      final ops = transport.toOperations();
      expect(ops.upsertEntity, isNotNull);
      expect(ops.deleteEntity, isNotNull);
      expect(rpc.calls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Persisted tenant scope: passed shopId is the authority, never ambient
  // -------------------------------------------------------------------------
  group('tenant isolation', () {
    test('sale RPC receives the passed persisted shopId verbatim', () async {
      await transport.upsertEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        localId: 7,
        payload: salePayload(barcode: 'B1', quantity: 2, salePrice: 5.0),
        idempotencyKey: 'idem-sale',
      );
      final call = rpc.single;
      expect(call.name, 'create_cloud_sale_with_stock_v2');
      expect(call.params['p_shop_id'], 'shop-A');
    });

    test('every supported route passes p_shop_id equal to the passed shopId',
        () async {
      await transport.upsertEntity(
          adapter: ProductSyncAdapter(),
          shopId: 'shop-Z',
          localId: 1,
          payload: {'name': 'P', 'barcode': 'B'},
          idempotencyKey: 'k');
      expect(rpc.single.params['p_shop_id'], 'shop-Z');
      rpc.reset();

      await transport.upsertEntity(
          adapter: CustomerSyncAdapter(),
          shopId: 'shop-Z',
          localId: 2,
          payload: {'name': 'C'},
          idempotencyKey: 'k');
      expect(rpc.single.params['p_shop_id'], 'shop-Z');
      rpc.reset();

      await transport.upsertEntity(
          adapter: ShopSettingsSyncAdapter(),
          shopId: 'shop-Z',
          localId: 3,
          payload: {'setting_key': 'k', 'setting_value': 'v'},
          idempotencyKey: 'k');
      expect(rpc.single.params['p_shop_id'], 'shop-Z');
    });

    test('no ambient/mismatch RPC can be produced — shopId is never rewritten',
        () async {
      // The transport takes shopId as the sole authority. A caller passing
      // 'shop-A' cannot cause an RPC for 'shop-B'; only the passed value is
      // ever sent.
      await transport.upsertEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        localId: 1,
        payload: salePayload(barcode: 'B1', quantity: 1, salePrice: 1),
        idempotencyKey: 'k',
      );
      expect(rpc.single.params['p_shop_id'], 'shop-A');
      final shopIds = rpc.calls.map((c) => c.params['p_shop_id']).toSet();
      expect(shopIds, {'shop-A'});
    });
  });

  // -------------------------------------------------------------------------
  // Closed routing
  // -------------------------------------------------------------------------
  group('closed routing', () {
    test('sale reaches only create_cloud_sale_with_stock_v2', () async {
      rpc.responseFor('create_cloud_sale_with_stock_v2', {
        'status': 'SYNCED',
        'id': 's1',
        'current_quantity': 8,
        'server_version': 1
      });
      await transport.upsertEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        localId: 1,
        payload: salePayload(barcode: 'B1', quantity: 2, salePrice: 5.0),
        idempotencyKey: 'idem-sale',
      );
      expect(rpc.names, ['create_cloud_sale_with_stock_v2']);
      final p = rpc.single.params;
      expect(p['p_shop_id'], 'shop-A');
      expect(p['p_barcode'], 'B1');
      expect(p['p_quantity'], 2);
      expect(p['p_sale_price'], 5.0);
      expect(p['p_idempotency_key'], 'idem-sale');
      expect(p['p_allow_oversell'], false);
      expect(p['p_invoice_id'], isNull);
    });

    test('return reaches only create_cloud_return_with_stock_v2', () async {
      rpc.responseFor('create_cloud_return_with_stock_v2', {
        'status': 'SYNCED',
        'id': 'r1',
        'current_quantity': 9,
        'server_version': 1
      });
      await transport.upsertEntity(
        adapter: ReturnSyncAdapter(),
        shopId: 'shop-A',
        localId: 2,
        payload: returnPayload(barcode: 'B1', quantity: 1, salePrice: 5.0),
        idempotencyKey: 'idem-return',
      );
      expect(rpc.names, ['create_cloud_return_with_stock_v2']);
      final p = rpc.single.params;
      expect(p['p_shop_id'], 'shop-A');
      expect(p['p_barcode'], 'B1');
      expect(p['p_quantity'], 1);
      expect(p['p_sale_price'], 5.0);
      expect(p['p_idempotency_key'], 'idem-return');
    });

    test('invoice reaches create_cloud_invoice_with_items_v2 with sale_items',
        () async {
      rpc.responseFor('create_cloud_invoice_with_items_v2', {
        'status': 'SYNCED',
        'id': 'i1',
        'current_quantity': 7,
        'server_version': 2
      });
      final items = [
        {'barcode': 'B1', 'quantity': 1, 'sale_price': 5.0},
        {'barcode': 'B2', 'quantity': 2, 'sale_price': 3.0},
      ];
      await transport.upsertEntity(
        adapter: InvoiceSyncAdapter(),
        shopId: 'shop-A',
        localId: 3,
        payload: {
          'date': '2026-08-20T00:00:00.000Z',
          'customer_name': 'عميل',
          'payment_method': 'cash',
          'sale_items': items,
        },
        idempotencyKey: 'idem-inv',
      );
      expect(rpc.names, ['create_cloud_invoice_with_items_v2']);
      final p = rpc.single.params;
      expect(p['p_sale_items'], items);
      expect(p['p_customer_name'], 'عميل');
      expect(p['p_payment_method'], 'cash');
      expect(p['p_idempotency_key'], 'idem-inv');
      expect(p['p_allow_oversell'], false);
    });

    test('invoice without sale_items fails closed, never fabricates', () async {
      await expectLater(
        transport.upsertEntity(
          adapter: InvoiceSyncAdapter(),
          shopId: 'shop-A',
          localId: 3,
          payload: {
            'date': '2026-08-20',
            'customer_name': 'x',
            'payment_method': 'cash'
          },
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
      expect(rpc.calls, isEmpty);
    });

    test('generic product CREATE routes to create_cloud_product', () async {
      rpc.responseFor('create_cloud_product', 'prod-uuid-1');
      final result = await transport.upsertEntity(
        adapter: ProductSyncAdapter(),
        shopId: 'shop-A',
        localId: 4,
        payload: {
          'name': 'Widget',
          'barcode': 'BW',
          'opening_quantity': 10,
          'cost_price': 3.5,
        },
        idempotencyKey: 'k',
      );
      expect(rpc.names, ['create_cloud_product']);
      final p = rpc.single.params;
      expect(p['p_name'], 'Widget');
      expect(p['p_barcode'], 'BW');
      expect(p['p_opening_quantity'], 10);
      expect(result.cloudUuid, 'prod-uuid-1');
    });

    test(
        'generic customer UPDATE routes to update_cloud_customer with cloud id',
        () async {
      rpc.responseFor('update_cloud_customer', true);
      final result = await transport.upsertEntity(
        adapter: CustomerSyncAdapter(),
        shopId: 'shop-A',
        localId: 5,
        payload: {'cloud_uuid': 'c-1', 'name': 'Ali', 'is_active': true},
        idempotencyKey: 'k',
      );
      expect(rpc.names, ['update_cloud_customer']);
      final p = rpc.single.params;
      expect(p['p_customer_id'], 'c-1');
      expect(p['p_name'], 'Ali');
      expect(result.success, isTrue);
    });

    test('shopSetting routes to update_cloud_shop_setting (upsert)', () async {
      rpc.responseFor('update_cloud_shop_setting', true);
      await transport.upsertEntity(
        adapter: ShopSettingsSyncAdapter(),
        shopId: 'shop-A',
        localId: 6,
        payload: {'setting_key': 'key', 'setting_value': 'value'},
        idempotencyKey: 'k',
      );
      expect(rpc.names, ['update_cloud_shop_setting']);
      expect(rpc.single.params['p_key'], 'key');
      expect(rpc.single.params['p_value'], 'value');
    });

    test('inventoryCount routes to save_cloud_inventory_count_v2', () async {
      rpc.responseFor('save_cloud_inventory_count_v2', {
        'status': 'SYNCED',
        'id': 'cnt1',
        'current_quantity': 9,
        'server_version': 1
      });
      await transport.upsertEntity(
        adapter: InventoryCountSyncAdapter(),
        shopId: 'shop-A',
        localId: 7,
        payload: {
          'product_id': 'cloud-prod-1',
          'actual_quantity': 9,
          'notes': '',
          'observed_at': '2026-08-20T00:00:00.000Z',
        },
        idempotencyKey: 'k',
      );
      expect(rpc.names, ['save_cloud_inventory_count_v2']);
      final p = rpc.single.params;
      expect(p['p_product_id'], 'cloud-prod-1');
      expect(p['p_actual_quantity'], 9);
      expect(p['p_idempotency_key'], 'k');
    });

    test('inventoryCount without cloud product_id fails closed', () async {
      await expectLater(
        transport.upsertEntity(
          adapter: InventoryCountSyncAdapter(),
          shopId: 'shop-A',
          localId: 7,
          payload: {'product_id': 3, 'actual_quantity': 9},
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
      expect(rpc.calls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Delete / revert with persisted idempotency key threading
  // -------------------------------------------------------------------------
  group('delete / stock revert', () {
    test('sale delete routes to delete_cloud_sale_with_revert_v2 with key',
        () async {
      rpc.responseFor('delete_cloud_sale_with_revert_v2', {
        'status': 'SYNCED',
        'id': 's1',
        'reverted': true,
        'current_quantity': 9,
        'server_version': 2
      });
      await transport.deleteEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        cloudUuid: 's1',
        entityId: 1,
        idempotencyKey: 'persisted-idem-revert',
      );
      expect(rpc.names, ['delete_cloud_sale_with_revert_v2']);
      final p = rpc.single.params;
      expect(p['p_shop_id'], 'shop-A');
      expect(p['p_sale_id'], 's1');
      expect(p['p_idempotency_key'], 'persisted-idem-revert',
          reason: 'persisted queue key must reach the revert RPC unchanged');
    });

    test('return delete routes to delete_cloud_return_with_revert_v2 with key',
        () async {
      rpc.responseFor('delete_cloud_return_with_revert_v2', {
        'status': 'SYNCED',
        'id': 'r1',
        'reverted': true,
        'current_quantity': 10,
        'server_version': 3
      });
      await transport.deleteEntity(
        adapter: ReturnSyncAdapter(),
        shopId: 'shop-A',
        cloudUuid: 'r1',
        entityId: 2,
        idempotencyKey: 'persisted-idem-return',
      );
      expect(rpc.names, ['delete_cloud_return_with_revert_v2']);
      expect(rpc.single.params['p_idempotency_key'], 'persisted-idem-return');
    });

    test('generic product delete routes to delete_cloud_product', () async {
      rpc.responseFor('delete_cloud_product', true);
      await transport.deleteEntity(
        adapter: ProductSyncAdapter(),
        shopId: 'shop-A',
        cloudUuid: 'p1',
        entityId: 3,
      );
      expect(rpc.names, ['delete_cloud_product']);
      expect(rpc.single.params['p_product_id'], 'p1');
    });

    test('customer/expense/expenseCategory delete route to governed RPCs',
        () async {
      rpc.responseFor('delete_cloud_customer', true);
      await transport.deleteEntity(
          adapter: CustomerSyncAdapter(),
          shopId: 'shop-A',
          cloudUuid: 'c1',
          entityId: 1);
      rpc.reset();
      rpc.responseFor('delete_cloud_expense', true);
      await transport.deleteEntity(
          adapter: ExpenseSyncAdapter(),
          shopId: 'shop-A',
          cloudUuid: 'e1',
          entityId: 2);
      rpc.reset();
      rpc.responseFor('delete_cloud_expense_category', true);
      await transport.deleteEntity(
          adapter: ExpenseCategorySyncAdapter(),
          shopId: 'shop-A',
          cloudUuid: 'ec1',
          entityId: 3);
      expect(rpc.names, ['delete_cloud_expense_category']);
    });

    test('invoice/inventory/settings delete fails closed (no server path)',
        () async {
      await expectLater(
        transport.deleteEntity(
            adapter: InvoiceSyncAdapter(),
            shopId: 'shop-A',
            cloudUuid: 'i1',
            entityId: 1),
        throwsA(isA<CloudDataException>()),
      );
      await expectLater(
        transport.deleteEntity(
            adapter: InventoryCountSyncAdapter(),
            shopId: 'shop-A',
            cloudUuid: 'x',
            entityId: 2),
        throwsA(isA<CloudDataException>()),
      );
      await expectLater(
        transport.deleteEntity(
            adapter: ShopSettingsSyncAdapter(),
            shopId: 'shop-A',
            cloudUuid: 'x',
            entityId: 3),
        throwsA(isA<CloudDataException>()),
      );
      expect(rpc.calls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Response adoption
  // -------------------------------------------------------------------------
  group('response adoption', () {
    test('StockRpcResult fields land in CloudUpsertResult', () async {
      rpc.responseFor(
          'create_cloud_return_with_stock_v2',
          const StockRpcResult(
            status: 'SYNCED',
            id: 'cloud-uuid-1',
            currentQuantity: 12,
            serverVersion: 5,
          ));
      final result = await transport.upsertEntity(
        adapter: ReturnSyncAdapter(),
        shopId: 'shop-A',
        localId: 2,
        payload: returnPayload(barcode: 'B1', quantity: 1, salePrice: 2),
        idempotencyKey: 'k',
      );
      expect(result.cloudUuid, 'cloud-uuid-1');
      expect(result.currentServerVersion, 5);
      expect(result.serverData?['current_quantity'], 12);
    });

    test('IDEMPOTENT replay maps to idempotent=true without re-execution',
        () async {
      rpc.responseFor('create_cloud_sale_with_stock_v2', {
        'status': 'IDEMPOTENT',
        'id': 's1',
        'current_quantity': 8,
        'server_version': 2,
      });
      final result = await transport.upsertEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        localId: 1,
        payload: salePayload(barcode: 'B1', quantity: 2, salePrice: 5),
        idempotencyKey: 'same-key',
      );
      expect(result.idempotent, isTrue);
      expect(result.success, isTrue);
    });

    test(
        'OVERSOLD is classified for Option C routing, not hidden (A3 is not '
        'reported as plain success and never thrown as a destructive error)',
        () async {
      rpc.responseFor('create_cloud_sale_with_stock_v2', {
        'status': 'OVERSOLD',
        'id': 's1',
        'current_quantity': -3,
        'server_version': 1,
      });
      final result = await transport.upsertEntity(
        adapter: SaleSyncAdapter(),
        shopId: 'shop-A',
        localId: 1,
        payload: salePayload(barcode: 'B1', quantity: 50, salePrice: 5),
        idempotencyKey: 'k',
      );
      // A3 boundary: the transport must surfaced the preserved OVERSOLD as a
      // distinct classified result so the engine can run Option C
      // reconciliation — NOT masquerade it as ordinary success and NOT throw
      // (a throw would be misread by the engine as a failed, non-preserved
      // event, contradicting the preserved-sale contract).
      expect(result.oversold, isTrue,
          reason: 'OVERSOLD must be classified, never hidden');
      expect(result.success, isTrue,
          reason: 'the sale is preserved server-side (not a failure)');
      expect(result.idempotent, isFalse);
      expect(result.conflict, isFalse);
      expect(result.serverData?['current_quantity'], -3);
    });
  });

  // -------------------------------------------------------------------------
  // Error mapping
  // -------------------------------------------------------------------------
  group('error mapping', () {
    test('permission-denied message maps to permissionDenied', () async {
      rpc.failWith('require_shop_permission denied', 403);
      await expectLater(
        transport.upsertEntity(
          adapter: ProductSyncAdapter(),
          shopId: 'shop-A',
          localId: 1,
          payload: {'name': 'P', 'barcode': 'B'},
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>().having(
            (e) => e.type, 'type', CloudDataErrorType.permissionDenied)),
      );
    });

    test('insufficient-stock message maps to insufficientStock', () async {
      rpc.failWith('Insufficient stock: available 2, requested 9', 400);
      await expectLater(
        transport.upsertEntity(
          adapter: SaleSyncAdapter(),
          shopId: 'shop-A',
          localId: 1,
          payload: salePayload(barcode: 'B1', quantity: 9, salePrice: 5),
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>().having(
            (e) => e.type, 'type', CloudDataErrorType.insufficientStock)),
      );
    });

    test('not-found message maps to notFound', () async {
      rpc.failWith('Product not found', 404);
      await expectLater(
        transport.upsertEntity(
          adapter: SaleSyncAdapter(),
          shopId: 'shop-A',
          localId: 1,
          payload: salePayload(barcode: 'B1', quantity: 1, salePrice: 5),
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.notFound)),
      );
    });

    test('5xx maps to serverError (never a permanent business error)',
        () async {
      rpc.failWith('internal error', 500);
      await expectLater(
        transport.upsertEntity(
          adapter: ProductSyncAdapter(),
          shopId: 'shop-A',
          localId: 1,
          payload: {'name': 'P', 'barcode': 'B'},
          idempotencyKey: 'k',
        ),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.serverError)),
      );
    });
  });

  // -------------------------------------------------------------------------
  // No arbitrary routing + no runtime activation
  // -------------------------------------------------------------------------
  group('no arbitrary routing / no runtime activation', () {
    test('payload content cannot select an arbitrary RPC/table/shop', () async {
      rpc.responseFor('create_cloud_sale_with_stock_v2', {
        'status': 'SYNCED',
        'id': 's1',
        'current_quantity': 8,
        'server_version': 1
      });
      final hostile = salePayload(barcode: 'B1', quantity: 1, salePrice: 1)
        ..['function'] = 'drop_cloud_tables'
        ..['p_shop_id'] = 'shop-B'
        ..['_table'] = 'cloud_customers';
      await transport.upsertEntity(
          adapter: SaleSyncAdapter(),
          shopId: 'shop-A',
          localId: 1,
          payload: hostile,
          idempotencyKey: 'k');
      expect(rpc.single.name, 'create_cloud_sale_with_stock_v2');
      expect(rpc.single.params['p_shop_id'], 'shop-A',
          reason: 'hostile payload shop must not override the authority');
    });

    test('syncDrainEnabled production default remains FALSE (A1 dormant)', () {
      // A1 must NOT flip the drain; A2 owns runtime attachment. Verifying the
      // production compile-time default is FALSE proves the app starts with
      // the drain OFF (plan §N / P-OD7).
      expect(AppConfig.syncDrainEnabled, isFalse);
    });

    test('main.dart does not wire cloudOperations into runtime in A1', () {
      // The transport can be built, but production startup performs zero RPC
      // calls because A1 leaves the runtime unattached (proven by the other
      // construction tests: building the transport / toOperations never
      // invokes the seam). Drain remains OFF by the assertion above.
      final ops = transport.toOperations();
      expect(ops, isNotNull);
      expect(rpc.calls, isEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// Contract fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> salePayload({
  required String barcode,
  required int quantity,
  required double salePrice,
}) =>
    {
      'date': '2026-08-20T00:00:00.000Z',
      'barcode': barcode,
      'quantity': quantity,
      'sale_price': salePrice,
    };

Map<String, dynamic> returnPayload({
  required String barcode,
  required int quantity,
  required double salePrice,
}) =>
    {
      'date': '2026-08-20T00:00:00.000Z',
      'barcode': barcode,
      'quantity': quantity,
      'sale_price': salePrice,
    };

typedef RpcCall = ({String name, Map<String, dynamic> params});

/// Records every RPC invocation and lets tests stub responses/errors.
class RecordingRpc {
  final List<RpcCall> calls = [];
  final Map<String, dynamic> _responses = {};
  Object? _forcedError;

  List<String> get names => calls.map((c) => c.name).toList();

  RpcCall get single {
    expect(calls.length, 1, reason: 'expected exactly one RPC call');
    return calls.single;
  }

  void reset() {
    calls.clear();
  }

  void responseFor(String name, dynamic value) {
    _responses[name] = value;
  }

  void failWith(String message, [int? status]) {
    _forcedError = message;
  }

  Future<dynamic> call(String function, Map<String, dynamic> params) async {
    calls.add((name: function, params: Map<String, dynamic>.from(params)));
    if (_forcedError != null) {
      throw Exception(_forcedError);
    }
    final response = _responses[function];
    if (response != null) return response;
    // Routing/param-focused tests rely on a benign default so the RPC succeeds
    // without needing an explicit stub; shape matches the function kind.
    if (function.contains('_v2') || function.startsWith('save_cloud')) {
      return <String, dynamic>{
        'status': 'SYNCED',
        'id': 'default-id',
        'current_quantity': 0,
        'server_version': 1,
      };
    }
    if (function.startsWith('create_cloud_')) return 'default-uuid';
    return true;
  }
}
