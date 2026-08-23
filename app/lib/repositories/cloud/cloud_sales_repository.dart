import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_invoice.dart';
import '../../models/cloud/cloud_return.dart';
import '../../models/cloud/cloud_sale.dart';
import 'stock_rpc_result.dart';

class CloudSalesRepository {
  /// Lazily-resolved default client; null until actually needed so tests
  /// can construct the repository with an [rpcOverride] only.
  SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ??= Supabase.instance.client;

  /// Test/contract seam (Phase M): when provided, replaces the raw Supabase
  /// RPC transport so the `_v2` contract can be exercised against local
  /// fixtures without a live project.
  final Future<dynamic> Function(String function, Map<String, dynamic> params)?
      _rpcOverride;

  CloudSalesRepository(
      {SupabaseClient? client,
      Future<dynamic> Function(String function, Map<String, dynamic> params)?
          rpcOverride})
      : _injectedClient = client,
        _rpcOverride = rpcOverride;

  Future<dynamic> _rpc(String function, Map<String, dynamic> params) async {
    final override = _rpcOverride;
    if (override != null) return override(function, params);
    return _client.rpc(function, params: params);
  }

  Future<List<CloudSale>> getSales(String shopId) async {
    try {
      final data = await _client
          .from('cloud_sales')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudSale.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudSale> createSaleWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
    String? invoiceId,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_sale_with_stock', params: {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
        'p_invoice_id': invoiceId,
      });
      final result = await _client
          .from('cloud_sales')
          .select()
          .eq('id', data as String)
          .single();
      return CloudSale.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteSaleWithRevert(String shopId, String saleId) async {
    try {
      final data = await _client.rpc('delete_cloud_sale_with_revert', params: {
        'p_shop_id': shopId,
        'p_sale_id': saleId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudReturn> createReturnWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_return_with_stock', params: {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
      });
      final result = await _client
          .from('cloud_returns')
          .select()
          .eq('id', data as String)
          .single();
      return CloudReturn.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteReturnWithRevert(String shopId, String returnId) async {
    try {
      final data =
          await _client.rpc('delete_cloud_return_with_revert', params: {
        'p_shop_id': shopId,
        'p_return_id': returnId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudInvoice> createInvoiceWithItems(
    String shopId, {
    required String customerName,
    String? customerId,
    required String paymentMethod,
    required DateTime date,
    required List<Map<String, dynamic>> saleItems,
  }) async {
    try {
      final data =
          await _client.rpc('create_cloud_invoice_with_items', params: {
        'p_shop_id': shopId,
        'p_customer_name': customerName,
        'p_customer_id': customerId,
        'p_payment_method': paymentMethod,
        'p_date': date.toIso8601String(),
        'p_sale_items': saleItems,
      });
      final result = await _client
          .from('cloud_invoices')
          .select()
          .eq('id', data as String)
          .single();
      return CloudInvoice.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<List<CloudInvoice>> getInvoices(String shopId) async {
    try {
      final data = await _client
          .from('cloud_invoices')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudInvoice.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<List<CloudReturn>> getReturns(String shopId) async {
    try {
      final data = await _client
          .from('cloud_returns')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudReturn.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  // ================= Phase M _v2 idempotent stock RPCs (OC-1/OC-3) =================
  // Additive wrappers over migration 28: same logical operation + same key
  // applies at most once server-side; responses carry authoritative
  // {current_quantity, server_version} so clients never guess convergence.

  /// Creates a sale via `create_cloud_sale_with_stock_v2`.
  Future<StockRpcResult> createSaleWithStockV2(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
    String? invoiceId,
    required String idempotencyKey,
    bool allowOversell = false,
  }) async {
    try {
      final data = await _rpc('create_cloud_sale_with_stock_v2', {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
        'p_invoice_id': invoiceId,
        'p_idempotency_key': idempotencyKey,
        'p_allow_oversell': allowOversell,
      });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  /// Reverts a sale at most once via `delete_cloud_sale_with_revert_v2`.
  Future<StockRpcResult> deleteSaleWithRevertV2(
    String shopId,
    String saleId, {
    required String idempotencyKey,
  }) async {
    try {
      final data = await _rpc('delete_cloud_sale_with_revert_v2', {
        'p_shop_id': shopId,
        'p_sale_id': saleId,
        'p_idempotency_key': idempotencyKey,
      });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  /// Creates a return via `create_cloud_return_with_stock_v2`.
  Future<StockRpcResult> createReturnWithStockV2(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
    required String idempotencyKey,
  }) async {
    try {
      final data = await _rpc('create_cloud_return_with_stock_v2', {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
        'p_idempotency_key': idempotencyKey,
      });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  /// Reverts a return at most once via `delete_cloud_return_with_revert_v2`.
  Future<StockRpcResult> deleteReturnWithRevertV2(
    String shopId,
    String returnId, {
    required String idempotencyKey,
  }) async {
    try {
      final data = await _rpc('delete_cloud_return_with_revert_v2', {
        'p_shop_id': shopId,
        'p_return_id': returnId,
        'p_idempotency_key': idempotencyKey,
      });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  /// Creates an invoice with items via `create_cloud_invoice_with_items_v2`
  /// using ONE invoice-level idempotency key for the whole effect set (OC-5).
  Future<StockRpcResult> createInvoiceWithItemsV2(
    String shopId, {
    required String customerName,
    String? customerId,
    required String paymentMethod,
    required DateTime date,
    required List<Map<String, dynamic>> saleItems,
    required String idempotencyKey,
    bool allowOversell = false,
  }) async {
    try {
      final data = await _rpc('create_cloud_invoice_with_items_v2', {
        'p_shop_id': shopId,
        'p_customer_name': customerName,
        'p_customer_id': customerId,
        'p_payment_method': paymentMethod,
        'p_date': date.toIso8601String(),
        'p_sale_items': saleItems,
        'p_idempotency_key': idempotencyKey,
        'p_allow_oversell': allowOversell,
      });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
