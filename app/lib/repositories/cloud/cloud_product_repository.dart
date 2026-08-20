import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_product.dart';

class CloudProductRepository {
  final SupabaseClient _client;

  CloudProductRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CloudProduct>> getProducts(String shopId) async {
    try {
      final data = await _client
          .from('cloud_products')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (data as List).map((e) => CloudProduct.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudProduct> getProduct(String shopId, String productId) async {
    try {
      final data = await _client
          .from('cloud_products')
          .select()
          .eq('shop_id', shopId)
          .eq('id', productId)
          .isFilter('deleted_at', null)
          .single();
      return CloudProduct.fromJson(data);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudProduct> createProduct(
    String shopId, {
    required String name,
    required String barcode,
    int openingQuantity = 0,
    double costPrice = 0,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_product', params: {
        'p_shop_id': shopId,
        'p_name': name,
        'p_barcode': barcode,
        'p_opening_quantity': openingQuantity,
        'p_cost_price': costPrice,
      });
      return await getProduct(shopId, data as String);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> updateProduct(
    String shopId,
    String productId, {
    String? name,
    String? barcode,
    int? openingQuantity,
    double? costPrice,
    int? soldQuantity,
    int? returnedQuantity,
    int? inventoryAdjustment,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_shop_id': shopId,
        'p_product_id': productId,
      };
      if (name != null) params['p_name'] = name;
      if (barcode != null) params['p_barcode'] = barcode;
      if (openingQuantity != null) {
        params['p_opening_quantity'] = openingQuantity;
      }
      if (costPrice != null) {
        params['p_cost_price'] = costPrice;
      }
      if (soldQuantity != null) {
        params['p_sold_quantity'] = soldQuantity;
      }
      if (returnedQuantity != null) {
        params['p_returned_quantity'] = returnedQuantity;
      }
      if (inventoryAdjustment != null) {
        params['p_inventory_adjustment'] = inventoryAdjustment;
      }
      final data = await _client.rpc('update_cloud_product', params: params);
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteProduct(String shopId, String productId) async {
    try {
      final data = await _client.rpc('delete_cloud_product', params: {
        'p_shop_id': shopId,
        'p_product_id': productId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
