import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/cloud_data_exception.dart';
import '../repositories/cloud/stock_rpc_result.dart';
import 'adapters/entity_sync_adapter.dart';
import 'sync_engine.dart';
import 'sync_status.dart';

/// A1 — production `SyncCloudOperations` transport (P-OD7 deliverable).
///
/// A concrete, real Supabase-backed transport implementing the dormant
/// functional interface [SyncCloudOperations]. Every supported
/// [SyncEntityType] is routed to its authoritative governed RPC with a closed
/// allow-list — never from payload-content RPC/table names — and every call is
/// scoped by the persisted queue `shop_id` (never the ambient active shop).
///
/// Routing contract (resolved from the shipped migrations + repository RPC
/// surface):
///   - sale / returnItem / invoice -> `*_v2` stock-aware idempotent RPCs
///   - inventoryCount -> `save_cloud_inventory_count_v2`
///   - product / customer / expense / expenseCategory / shopSetting ->
///     the governed per-entity `create_cloud_*` / `update_cloud_*` RPCs
///   - DELETE -> `*_v2` stock revert RPCs (sale / returnItem) or the governed
///     per-entity delete RPCs where a delete surface exists; otherwise fail
///     closed (no server delete surface).
///
/// DORMANT BY DESIGN (plan §F / P-OD7): constructing this transport performs
/// zero network activity. It is NOT wired into `main.dart` or `SyncRuntime`
/// (A2 owns runtime attachment); it is instantiable and invocable in tests
/// through an injected RPC seam.
///
/// Tenant isolation (brief §7): `shopId` is the operation authority and is
/// written verbatim into every `p_shop_id`. The transport never consults
/// `ActiveShopContext` or any ambient shop; a shop mismatch is never
/// redirected to another shop.
class SyncCloudOperationsTransport {
  final Future<dynamic> Function(String function, Map<String, dynamic> params)
      _rpc;
  final bool _allowOversell;

  SyncCloudOperationsTransport({
    required Future<dynamic> Function(
            String function, Map<String, dynamic> params)
        rpc,
    bool allowOversell = false,
  })  : _rpc = rpc,
        _allowOversell = allowOversell;

  /// Returns the [SyncCloudOperations] view of this transport (the contract
  /// `SyncRuntime`/`SyncEngine` bind to). A2 will attach this in the
  /// dedicated wiring slice; A1 leaves it unwired.
  SyncCloudOperations toOperations() {
    return SyncCloudOperations(
      upsertEntity: upsertEntity,
      deleteEntity: deleteEntity,
    );
  }

  Future<CloudUpsertResult> upsertEntity({
    required EntitySyncAdapter adapter,
    required String shopId,
    required int localId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final result = await _dispatchUpsert(
      adapter: adapter,
      shopId: shopId,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );
    return _adoptUpsertResult(adapter, result);
  }

  Future<void> deleteEntity({
    required EntitySyncAdapter adapter,
    required String shopId,
    required String cloudUuid,
    required int entityId,
    String? idempotencyKey,
  }) async {
    await _dispatchDelete(
      adapter: adapter,
      shopId: shopId,
      cloudUuid: cloudUuid,
      idempotencyKey: idempotencyKey,
    );
  }

  // ---------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------

  Future<dynamic> _call(String function, Map<String, dynamic> params) async {
    try {
      return await _rpc(function, params);
    } on CloudDataException {
      rethrow;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    } catch (e) {
      // Keyword-driven mapping is intentionally reused so raw transport
      // errors (test fixtures, unusual client errors) keep meaningful
      // categories; net/HTTP failures surface as PostgrestException in
      // production and map through the branch above.
      throw CloudDataException.fromPostgrest('$e', null);
    }
  }

  Future<dynamic> _dispatchUpsert({
    required EntitySyncAdapter adapter,
    required String shopId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) {
    final params = <String, dynamic>{'p_shop_id': shopId};
    switch (adapter.entityType) {
      case SyncEntityType.sale:
        return _call('create_cloud_sale_with_stock_v2', {
          ...params,
          'p_barcode': _str(payload, 'barcode'),
          'p_quantity': _int(payload, 'quantity'),
          'p_sale_price': _num(payload, 'sale_price'),
          'p_date': _str(payload, 'date'),
          // The local sale adapter does not carry an invoice link; omitting
          // it (NULL) never fabricates a linkage.
          'p_invoice_id': null,
          'p_idempotency_key': idempotencyKey,
          'p_allow_oversell': _allowOversell,
        });
      case SyncEntityType.returnItem:
        return _call('create_cloud_return_with_stock_v2', {
          ...params,
          'p_barcode': _str(payload, 'barcode'),
          'p_quantity': _int(payload, 'quantity'),
          'p_sale_price': _num(payload, 'sale_price'),
          'p_date': _str(payload, 'date'),
          'p_idempotency_key': idempotencyKey,
        });
      case SyncEntityType.invoice:
        final items = payload['sale_items'];
        if (items is! List || items.isEmpty) {
          throw CloudDataException(
            type: CloudDataErrorType.invalidInput,
            message: 'Invoice sync requires the per-item sale_items breakdown; '
                'a cloud invoice cannot be created from summary fields alone.',
          );
        }
        return _call('create_cloud_invoice_with_items_v2', {
          ...params,
          'p_customer_name': _str(payload, 'customer_name'),
          'p_payment_method': _str(payload, 'payment_method'),
          'p_date': _str(payload, 'date'),
          'p_sale_items': items,
          'p_customer_id': null,
          'p_idempotency_key': idempotencyKey,
          'p_allow_oversell': _allowOversell,
        });
      case SyncEntityType.inventoryCount:
        final productId = _strOrNull(payload, 'product_id');
        if (productId == null || productId.isEmpty) {
          throw CloudDataException(
            type: CloudDataErrorType.invalidInput,
            message:
                'Inventory count sync requires a cloud product_id (UUID) for '
                'the counted product; the local product reference cannot be '
                'guessed into a server product identity here.',
          );
        }
        return _call('save_cloud_inventory_count_v2', {
          ...params,
          'p_product_id': productId,
          'p_actual_quantity': _int(payload, 'actual_quantity'),
          'p_notes': _str(payload, 'notes'),
          'p_observed_at': _strOrNull(payload, 'observed_at'),
          'p_idempotency_key': idempotencyKey,
        });
      case SyncEntityType.product:
        final cloudUuid = _strOrNull(payload, 'cloud_uuid');
        if (cloudUuid == null || cloudUuid.isEmpty) {
          // A product CREATE has no cloud identity yet; the server mints it.
          return _call('create_cloud_product', {
            ...params,
            'p_name': _str(payload, 'name'),
            'p_barcode': _str(payload, 'barcode'),
            'p_opening_quantity': _int(payload, 'opening_quantity'),
            'p_cost_price': _num(payload, 'cost_price'),
          });
        }
        return _call('update_cloud_product', {
          ...params,
          'p_product_id': cloudUuid,
          'p_name': _strOrNull(payload, 'name'),
          'p_barcode': _strOrNull(payload, 'barcode'),
          'p_opening_quantity': _intOrNull(payload, 'opening_quantity'),
          'p_cost_price': _doubleOrNull(payload, 'cost_price'),
        });
      case SyncEntityType.customer:
        final cloudUuid = _strOrNull(payload, 'cloud_uuid');
        if (cloudUuid == null || cloudUuid.isEmpty) {
          return _call('create_cloud_customer', {
            ...params,
            'p_name': _str(payload, 'name'),
            'p_phone': _strOrNull(payload, 'phone'),
            'p_address': _strOrNull(payload, 'address'),
            'p_notes': _strOrNull(payload, 'notes'),
            'p_is_active': _bool(payload, 'is_active', defaultValue: true),
            'p_is_system': _bool(payload, 'is_system'),
          });
        }
        return _call('update_cloud_customer', {
          ...params,
          'p_customer_id': cloudUuid,
          'p_name': _strOrNull(payload, 'name'),
          'p_phone': _strOrNull(payload, 'phone'),
          'p_address': _strOrNull(payload, 'address'),
          'p_notes': _strOrNull(payload, 'notes'),
          'p_is_active': _boolOrNull(payload, 'is_active'),
        });
      case SyncEntityType.expense:
        final cloudUuid = _strOrNull(payload, 'cloud_uuid');
        if (cloudUuid == null || cloudUuid.isEmpty) {
          return _call('create_cloud_expense', {
            ...params,
            'p_date': _str(payload, 'date'),
            'p_description': _str(payload, 'description'),
            'p_amount': _num(payload, 'amount'),
            // The expense adapter carries a category NAME, not a server
            // category UUID. Omitting p_category_id is truthful: no UUID is
            // fabricated from a name; category attribution is preserved only
            // when a usable id is present.
            'p_category_id': _strOrNull(payload, 'category_id'),
          });
        }
        return _call('update_cloud_expense', {
          ...params,
          'p_expense_id': cloudUuid,
          'p_date': _strOrNull(payload, 'date'),
          'p_description': _strOrNull(payload, 'description'),
          'p_amount': _doubleOrNull(payload, 'amount'),
          'p_category_id': _strOrNull(payload, 'category_id'),
        });
      case SyncEntityType.expenseCategory:
        final cloudUuid = _strOrNull(payload, 'cloud_uuid');
        if (cloudUuid == null || cloudUuid.isEmpty) {
          return _call('create_cloud_expense_category', {
            ...params,
            'p_name': _str(payload, 'name'),
          });
        }
        // No governed update RPC exists for expense categories; a client
        // update has no safe server path, so it fails closed rather than
        // fabricating one.
        throw CloudDataException(
          type: CloudDataErrorType.invalidInput,
          message: 'No governed update RPC exists for expense categories; '
              'updating an existing category has no safe cloud path.',
        );
      case SyncEntityType.shopSetting:
        // update_cloud_shop_setting is an upsert keyed on (shop_id, key), so
        // it serves both CREATE and UPDATE.
        return _call('update_cloud_shop_setting', {
          ...params,
          'p_key': _str(payload, 'setting_key'),
          'p_value': _str(payload, 'setting_value'),
        });
    }
  }

  Future<void> _dispatchDelete({
    required EntitySyncAdapter adapter,
    required String shopId,
    required String cloudUuid,
    String? idempotencyKey,
  }) async {
    final params = <String, dynamic>{'p_shop_id': shopId};
    switch (adapter.entityType) {
      case SyncEntityType.sale:
        await _call('delete_cloud_sale_with_revert_v2', {
          ...params,
          'p_sale_id': cloudUuid,
          'p_idempotency_key': idempotencyKey,
        });
      case SyncEntityType.returnItem:
        await _call('delete_cloud_return_with_revert_v2', {
          ...params,
          'p_return_id': cloudUuid,
          'p_idempotency_key': idempotencyKey,
        });
      case SyncEntityType.product:
        await _call('delete_cloud_product', {
          ...params,
          'p_product_id': cloudUuid,
        });
      case SyncEntityType.customer:
        await _call('delete_cloud_customer', {
          ...params,
          'p_customer_id': cloudUuid,
        });
      case SyncEntityType.expense:
        await _call('delete_cloud_expense', {
          ...params,
          'p_expense_id': cloudUuid,
        });
      case SyncEntityType.expenseCategory:
        await _call('delete_cloud_expense_category', {
          ...params,
          'p_category_id': cloudUuid,
        });
      case SyncEntityType.invoice:
      case SyncEntityType.inventoryCount:
      case SyncEntityType.shopSetting:
        // No governed server delete surface for these event/setting types;
        // an invoice is retired by reverting its constituent sales, counts
        // and settings carry no server-side delete. Fail closed truthfully.
        throw CloudDataException(
          type: CloudDataErrorType.invalidInput,
          message:
              'No governed server delete path for ${adapter.entityType.label}',
        );
    }
  }

  // ---------------------------------------------------------------------
  // Response adoption (brief §11) + error/result seam
  // ---------------------------------------------------------------------

  CloudUpsertResult _adoptUpsertResult(EntitySyncAdapter adapter, dynamic raw) {
    if (raw == null) {
      throw CloudDataException(
        type: CloudDataErrorType.serverError,
        message: 'Transport returned no server result',
      );
    }

    // Stock-aware `_v2` RPCs return JSONB with authoritative fields.
    if (_isStockResult(adapter.entityType)) {
      final result = _asStockResult(raw);
      // OVERSOLD is a state A3 owns (Option C reconciliation). A1 must never
      // silently treat it as normal success (brief §11): fail through the
      // governed seam so the entry is not marked SYNCED.
      if (result.oversold || result.status == 'OVERSOLD') {
        throw CloudDataException(
          type: CloudDataErrorType.conflict,
          message:
              'Oversold stock event requires reconciliation (A3); preserved '
              'untouched, not treated as synced.',
          serverMessage: result.status,
        );
      }
      return CloudUpsertResult(
        success: true,
        idempotent: result.idempotentReplay,
        cloudUuid: result.id,
        serverData: {
          'current_quantity': result.currentQuantity,
          'server_version': result.serverVersion,
          'id': result.id,
        },
        currentServerVersion:
            result.serverVersion > 0 ? result.serverVersion : null,
      );
    }

    // Generic entity RPCs return a scalar id/bool.
    if (raw is String) {
      // create_*_entity returns the new UUID.
      return CloudUpsertResult(success: true, cloudUuid: raw);
    }
    if (raw is bool) {
      // update_*_entity returns a boolean applied flag.
      return CloudUpsertResult(success: raw);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final status = map['status'] as String?;
      if (status == 'IDEMPOTENT') {
        return CloudUpsertResult(success: true, idempotent: true);
      }
      return CloudUpsertResult(
        success: map['success'] == true || status == 'SYNCED',
        cloudUuid: map['id'] as String?,
      );
    }
    throw CloudDataException(
      type: CloudDataErrorType.serverError,
      message: 'Transport returned an unrepresentable server result',
    );
  }

  bool _isStockResult(SyncEntityType type) =>
      type == SyncEntityType.sale ||
      type == SyncEntityType.returnItem ||
      type == SyncEntityType.invoice ||
      type == SyncEntityType.inventoryCount;

  StockRpcResult _asStockResult(dynamic raw) {
    if (raw is StockRpcResult) return raw;
    if (raw is Map) return StockRpcResult.fromJson(raw);
    throw CloudDataException(
      type: CloudDataErrorType.serverError,
      message: 'Stock RPC returned a non-object payload',
    );
  }

  // ---------------------------------------------------------------------
  // Payload helpers (SQLite rows carry num/String/null values)
  // ---------------------------------------------------------------------

  static String? _strOrNull(Map<String, dynamic> m, String key) {
    final v = m[key];
    return v is String ? v : null;
  }

  static String _str(Map<String, dynamic> m, String key) =>
      m[key] as String? ?? '';

  static int _int(Map<String, dynamic> m, String key) =>
      (m[key] as num?)?.toInt() ?? 0;

  static int? _intOrNull(Map<String, dynamic> m, String key) =>
      (m[key] as num?)?.toInt();

  static double _num(Map<String, dynamic> m, String key) =>
      (m[key] as num?)?.toDouble() ?? 0;

  static double? _doubleOrNull(Map<String, dynamic> m, String key) =>
      (m[key] as num?)?.toDouble();

  static bool _bool(Map<String, dynamic> m, String key,
          {bool defaultValue = false}) =>
      m[key] == true ||
      ((m[key] is num) && (m[key] as num) == 1) ||
      defaultValue;

  static bool? _boolOrNull(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v == 1;
    return null;
  }
}
