import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/repositories/cloud/cloud_inventory_repository.dart';
import 'package:muaman_store/repositories/cloud/cloud_sales_repository.dart';

/// Phase M slices M-I02/M-I03 — server contract fixtures for migration 28
/// (plan §15 OC-1..OC-5, matrix B/C: M-C01/02, M-C10/11/12/13).
///
/// [Migration28RpcFixture] mirrors the documented behavior of
/// `20260820000028_phase_m_inventory_conflict_hardening.sql`:
///   - sync_log-keyed idempotency: unknown key → execute; known key →
///     return the ORIGINAL result as IDEMPOTENT without re-executing,
///   - conditional-update oversell guard (allow-oversell branch lifts it
///     but keeps the component equation exact),
///   - rich JSONB returns `{status, id, current_quantity, server_version}`,
///   - count ordering: latest-OBSERVED wins; late older counts are
///     HISTORICAL and never re-adjust.
void main() {
  late Migration28RpcFixture fixture;
  late CloudSalesRepository salesRepo;
  late CloudInventoryRepository inventoryRepo;

  setUp(() {
    fixture = Migration28RpcFixture();
    salesRepo = CloudSalesRepository(rpcOverride: fixture.call);
    inventoryRepo = CloudInventoryRepository(rpcOverride: fixture.call);
  });

  group('M-C10 — same key applies at most once', () {
    test('sale replay returns IDEMPOTENT original result, no second effect',
        () async {
      final first = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 3,
        salePrice: 9.9,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'k-sale-1',
      );
      expect(first.status, 'SYNCED');
      expect(fixture.soldQuantity, 3);

      final replay = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 3,
        salePrice: 9.9,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'k-sale-1',
      );

      expect(replay.idempotentReplay, isTrue);
      expect(replay.currentQuantity, first.currentQuantity);
      expect(replay.serverVersion, first.serverVersion);
      expect(fixture.saleCount, 1, reason: 'no duplicate financial event');
      expect(fixture.soldQuantity, 3, reason: 'stock decremented once');
    });

    test('revert replay reverts at most once (SR-3 / INV-M03)', () async {
      final sale = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 2,
        salePrice: 5.0,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'k-sale-2',
      );

      final revert = await salesRepo.deleteSaleWithRevertV2(
        'shop-1',
        sale.id!,
        idempotencyKey: 'k-revert-1',
      );
      expect(revert.reverted, isTrue);
      expect(fixture.soldQuantity, 0);

      final replay = await salesRepo.deleteSaleWithRevertV2(
        'shop-1',
        sale.id!,
        idempotencyKey: 'k-revert-1',
      );
      expect(replay.idempotentReplay, isTrue);
      expect(fixture.revertCount, 1, reason: 'revert applied exactly once');
    });
  });

  group('M-C11 — distinct logical events apply separately', () {
    test('different keys create two sales with cumulative stock effect',
        () async {
      await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 1,
        salePrice: 5.0,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'k-a',
      );
      await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 1,
        salePrice: 5.0,
        date: DateTime.utc(2026, 8, 21),
        idempotencyKey: 'k-b',
      );

      expect(fixture.saleCount, 2);
      expect(fixture.soldQuantity, 2);
      expect(fixture.currentQuantity, fixture.openingQuantity - 2);
    });
  });

  group('M-C12 — lost-response retry converges', () {
    test('client resends SAME key after response loss; state converges',
        () async {
      // Simulate crash window C/D: RPC committed server-side but the client
      // never saw the response. The retry re-sends the persisted key.
      final lostResponse = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 4,
        salePrice: 7.0,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'persisted-key',
      );

      final retry = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 4,
        salePrice: 7.0,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'persisted-key',
      );

      expect(retry.currentQuantity, lostResponse.currentQuantity);
      expect(retry.serverVersion, lostResponse.serverVersion);
      expect(fixture.saleCount, 1);
      // INV-M20: authoritative convergence state present in both responses.
      expect(lostResponse.serverVersion, greaterThan(0));
    });
  });

  group('M-C01/02 — oversell guard + rich returns', () {
    test('insufficient stock rejects without partial state', () async {
      await expectLater(
        salesRepo.createSaleWithStockV2(
          'shop-1',
          barcode: 'BAR-1',
          quantity: 999,
          salePrice: 5.0,
          date: DateTime.utc(2026, 8, 20),
          idempotencyKey: 'k-over',
        ),
        throwsA(anything),
      );
      expect(fixture.saleCount, 0);
      expect(fixture.soldQuantity, 0);
      expect(fixture.serverVersion, 0);
    });

    test(
        'OD6 seam input allowOversell=true preserves event, marks OVERSOLD, '
        'equation stays exact', () async {
      final result = await salesRepo.createSaleWithStockV2(
        'shop-1',
        barcode: 'BAR-1',
        quantity: 50,
        salePrice: 5.0,
        date: DateTime.utc(2026, 8, 20),
        idempotencyKey: 'k-policy-c',
        allowOversell: true,
      );

      expect(result.status, 'OVERSOLD');
      expect(result.oversold, isTrue);
      expect(result.currentQuantity, fixture.openingQuantity - 50);
      expect(
        fixture.currentQuantity,
        fixture.openingQuantity -
            fixture.soldQuantity +
            fixture.returnedQuantity +
            fixture.inventoryAdjustment,
        reason: 'component equation must hold after every path',
      );
    });

    test('invoice v2 uses ONE key for the whole effect set (OC-5)', () async {
      final items = [
        {'barcode': 'BAR-1', 'quantity': 1, 'sale_price': 5.0},
        {'barcode': 'BAR-2', 'quantity': 2, 'sale_price': 3.0},
      ];
      final invoice = await salesRepo.createInvoiceWithItemsV2(
        'shop-1',
        customerName: 'عميل',
        paymentMethod: 'cash',
        date: DateTime.utc(2026, 8, 20),
        saleItems: items,
        idempotencyKey: 'k-inv-1',
      );

      expect(invoice.status, 'SYNCED');
      expect(fixture.invoiceItemCount, 3);

      final replay = await salesRepo.createInvoiceWithItemsV2(
        'shop-1',
        customerName: 'عميل',
        paymentMethod: 'cash',
        date: DateTime.utc(2026, 8, 20),
        saleItems: items,
        idempotencyKey: 'k-inv-1',
      );

      expect(replay.idempotentReplay, isTrue);
      expect(fixture.invoiceItemCount, 3, reason: 'items not duplicated');
    });
  });

  group('M-C06 — count ordering basics (IC-3)', () {
    test('latest observed count stands; older late count is HISTORICAL',
        () async {
      final standing = await inventoryRepo.saveInventoryCountV2(
        'shop-1',
        productId: 'prod-1',
        actualQuantity: 10,
        observedAt: DateTime.utc(2026, 8, 20, 12, 0),
        idempotencyKey: 'k-count-1',
      );
      expect(standing.status, 'SYNCED');

      // A LATE-ARRIVING OLDER observation must not re-adjust stock.
      final lateOlder = await inventoryRepo.saveInventoryCountV2(
        'shop-1',
        productId: 'prod-1',
        actualQuantity: 99,
        observedAt: DateTime.utc(2026, 8, 19, 8, 0),
        idempotencyKey: 'k-count-2',
      );

      expect(lateOlder.status, 'HISTORICAL');
      expect(lateOlder.currentQuantity, standing.currentQuantity,
          reason: 'late older count must not replace newer observation');
    });

    test('count replay via same key does not double-adjust', () async {
      final first = await inventoryRepo.saveInventoryCountV2(
        'shop-1',
        productId: 'prod-1',
        actualQuantity: 4,
        observedAt: DateTime.utc(2026, 8, 20, 9, 0),
        idempotencyKey: 'k-count-3',
      );
      final replay = await inventoryRepo.saveInventoryCountV2(
        'shop-1',
        productId: 'prod-1',
        actualQuantity: 4,
        observedAt: DateTime.utc(2026, 8, 20, 9, 0),
        idempotencyKey: 'k-count-3',
      );

      expect(replay.idempotentReplay, isTrue);
      expect(replay.currentQuantity, first.currentQuantity);
      expect(fixture.countAdjustmentApplications, 1);
    });
  });
}

/// Local emulation of migration 28's documented RPC semantics.
class Migration28RpcFixture {
  final int openingQuantity = 10;
  int soldQuantity = 0;
  int returnedQuantity = 0;
  int inventoryAdjustment = 0;
  int serverVersion = 0;

  int saleCount = 0;
  int revertCount = 0;
  int invoiceItemCount = 0;
  int countAdjustmentApplications = 0;
  DateTime? _latestObserved;

  final Map<String, Map<String, dynamic>> _idempotencyLog = {};

  int get currentQuantity =>
      openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment;

  Future<dynamic> call(String function, Map<String, dynamic> params) async {
    switch (function) {
      case 'create_cloud_sale_with_stock_v2':
        return _sale(params);
      case 'delete_cloud_sale_with_revert_v2':
        return _revertSale(params);
      case 'create_cloud_invoice_with_items_v2':
        return _invoice(params);
      case 'save_cloud_inventory_count_v2':
        return _count(params);
      default:
        throw UnimplementedError(function);
    }
  }

  Map<String, dynamic>? _lookup(String? key) {
    if (key == null || key.isEmpty) return null;
    final original = _idempotencyLog[key];
    if (original == null) return null;
    // Mirrors phase_m_idempotency_lookup(): replays carry an IDEMPOTENT
    // envelope around the original successful result.
    return {
      'status': 'IDEMPOTENT',
      'original_status': original['status'],
      'original_result': original,
      'server_version': original['server_version'],
      'current_quantity': original['current_quantity'],
    };
  }

  void _record(String? key, Map<String, dynamic> result) {
    if (key == null || key.isEmpty) return;
    _idempotencyLog[key] = result;
  }

  Map<String, dynamic> _sale(Map<String, dynamic> p) {
    final prior = _lookup(p['p_idempotency_key'] as String?);
    if (prior != null) return prior;

    final quantity = p['p_quantity'] as int;
    if (quantity <= 0) throw Exception('Must be > 0');

    final allow = p['p_allow_oversell'] == true;
    if (currentQuantity < quantity && !allow) {
      throw Exception('Insufficient stock: available $currentQuantity, '
          'requested $quantity');
    }

    soldQuantity += quantity;
    serverVersion += 1;
    saleCount += 1;
    lastSaleQuantity = quantity;

    final status = currentQuantity < 0 ? 'OVERSOLD' : 'SYNCED';
    final result = <String, dynamic>{
      'status': status,
      'id': 'sale-${saleCount}',
      'invoice_id': p['p_invoice_id'],
      'current_quantity': currentQuantity,
      'server_version': serverVersion,
      'oversold': status == 'OVERSOLD',
    };
    _record(p['p_idempotency_key'] as String?, result);
    return result;
  }

  Map<String, dynamic> _revertSale(Map<String, dynamic> p) {
    final prior = _lookup(p['p_idempotency_key'] as String?);
    if (prior != null) return prior;

    // Single-product fixture world: revert restores the last sale's
    // decrement exactly once (SR-3).
    soldQuantity -= lastSaleQuantity;
    serverVersion += 1;
    revertCount += 1;

    final result = <String, dynamic>{
      'status': 'SYNCED',
      'id': p['p_sale_id'],
      'reverted': true,
      'current_quantity': currentQuantity,
      'server_version': serverVersion,
    };
    _record(p['p_idempotency_key'] as String?, result);
    return result;
  }

  int lastSaleQuantity = 0;

  Map<String, dynamic> _invoice(Map<String, dynamic> p) {
    final prior = _lookup(p['p_idempotency_key'] as String?);
    if (prior != null) return prior;

    final items = (p['p_sale_items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    var hadOversold = false;
    for (final item in items) {
      final r = _sale({
        'p_quantity': item['quantity'] as int,
        'p_allow_oversell': p['p_allow_oversell'],
        'p_invoice_id': 'inv-current',
        'p_idempotency_key': null,
      });
      if (r['status'] == 'OVERSOLD') hadOversold = true;
      invoiceItemCount += item['quantity'] as int;
    }

    final result = <String, dynamic>{
      'status': hadOversold ? 'OVERSOLD' : 'SYNCED',
      'id': 'invoice-1',
      'invoice_number': 'INV-00000001',
      'current_quantity': currentQuantity,
      'server_version': serverVersion,
    };
    _record(p['p_idempotency_key'] as String?, result);
    return result;
  }

  Map<String, dynamic> _count(Map<String, dynamic> p) {
    final prior = _lookup(p['p_idempotency_key'] as String?);
    if (prior != null) return prior;

    final observedAt = DateTime.parse(p['p_observed_at'] as String).toUtc();
    final actualQuantity = p['p_actual_quantity'] as int;

    final isStanding =
        _latestObserved == null || !observedAt.isBefore(_latestObserved!);

    if (!isStanding) {
      final historical = <String, dynamic>{
        'status': 'HISTORICAL',
        'id': 'count-hist',
        'observed_at': observedAt.toIso8601String(),
        'superseded_by': _latestObserved!.toIso8601String(),
        'current_quantity': currentQuantity,
        'server_version': serverVersion,
      };
      _record(p['p_idempotency_key'] as String?, historical);
      return historical;
    }

    _latestObserved = observedAt;

    // Standing observation: absolute snapshot applied as derived adjustment
    // (post-observation events stay on top; fixture world has none here).
    final desiredCurrent = actualQuantity;
    final delta = desiredCurrent - currentQuantity;
    inventoryAdjustment += delta;
    serverVersion += 1;
    countAdjustmentApplications += 1;

    final result = <String, dynamic>{
      'status': 'SYNCED',
      'id': 'count-stand',
      'observed_at': observedAt.toIso8601String(),
      'adjustment_delta': delta,
      'current_quantity': currentQuantity,
      'server_version': serverVersion,
    };
    _record(p['p_idempotency_key'] as String?, result);
    return result;
  }
}
