import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_inventory_count.dart';
import 'stock_rpc_result.dart';

class CloudInventoryRepository {
  /// Lazily-resolved default client; null until actually needed so tests
  /// can construct the repository with an [rpcOverride] only.
  SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ??= Supabase.instance.client;

  /// Test/contract seam (Phase M) — see [CloudSalesRepository].
  final Future<dynamic> Function(String function, Map<String, dynamic> params)?
      _rpcOverride;

  CloudInventoryRepository(
      {SupabaseClient? client,
      Future<dynamic> Function(String function, Map<String, dynamic> params)?
          rpcOverride})
      : _injectedClient = client,
        _rpcOverride = rpcOverride;

  Future<List<CloudInventoryCount>> getInventoryCounts(String shopId) async {
    try {
      final data = await _client
          .from('cloud_inventory_count')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('count_date', ascending: false);
      return (data as List)
          .map((e) => CloudInventoryCount.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudInventoryCount> saveInventoryCount(
    String shopId, {
    required String productId,
    required int actualQuantity,
    String notes = '',
  }) async {
    try {
      final data = await _client.rpc('save_cloud_inventory_count', params: {
        'p_shop_id': shopId,
        'p_product_id': productId,
        'p_actual_quantity': actualQuantity,
        'p_notes': notes,
      });
      final result = await _client
          .from('cloud_inventory_count')
          .select()
          .eq('id', data as String)
          .single();
      return CloudInventoryCount.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  /// Phase M (IC-1..IC-5): saves a count as an OBSERVATION at [observedAt]
  /// via `save_cloud_inventory_count_v2`. Latest-observed wins as the
  /// standing observation; late older counts stay historical and never
  /// re-adjust newer state.
  Future<StockRpcResult> saveInventoryCountV2(
    String shopId, {
    required String productId,
    required int actualQuantity,
    String notes = '',
    DateTime? observedAt,
    required String idempotencyKey,
  }) async {
    try {
      final override = _rpcOverride;
      final data = override != null
          ? await override('save_cloud_inventory_count_v2', {
              'p_shop_id': shopId,
              'p_product_id': productId,
              'p_actual_quantity': actualQuantity,
              'p_notes': notes,
              'p_observed_at': observedAt?.toIso8601String(),
              'p_idempotency_key': idempotencyKey,
            })
          : await _client.rpc('save_cloud_inventory_count_v2', params: {
              'p_shop_id': shopId,
              'p_product_id': productId,
              'p_actual_quantity': actualQuantity,
              'p_notes': notes,
              'p_observed_at': observedAt?.toIso8601String(),
              'p_idempotency_key': idempotencyKey,
            });
      return StockRpcResult.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
