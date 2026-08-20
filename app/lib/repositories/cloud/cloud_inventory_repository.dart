import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_inventory_count.dart';

class CloudInventoryRepository {
  final SupabaseClient _client;

  CloudInventoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

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
}
