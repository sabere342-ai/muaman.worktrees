import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_customer.dart';

class CloudCustomerRepository {
  final SupabaseClient _client;

  CloudCustomerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CloudCustomer>> getCustomers(String shopId) async {
    try {
      final data = await _client
          .from('cloud_customers')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('name');
      return (data as List).map((e) => CloudCustomer.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudCustomer> createCustomer(
    String shopId, {
    required String name,
    String? phone,
    String? address,
    String? notes,
    bool isActive = true,
    bool isSystem = false,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_customer', params: {
        'p_shop_id': shopId,
        'p_name': name,
        'p_phone': phone,
        'p_address': address,
        'p_notes': notes,
        'p_is_active': isActive,
        'p_is_system': isSystem,
      });
      final result = await _client
          .from('cloud_customers')
          .select()
          .eq('id', data as String)
          .single();
      return CloudCustomer.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> updateCustomer(
    String shopId,
    String customerId, {
    String? name,
    String? phone,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_shop_id': shopId,
        'p_customer_id': customerId,
      };
      if (name != null) params['p_name'] = name;
      if (phone != null) params['p_phone'] = phone;
      if (address != null) params['p_address'] = address;
      if (notes != null) params['p_notes'] = notes;
      if (isActive != null) params['p_is_active'] = isActive;
      final data = await _client.rpc('update_cloud_customer', params: params);
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteCustomer(String shopId, String customerId) async {
    try {
      final data = await _client.rpc('delete_cloud_customer', params: {
        'p_shop_id': shopId,
        'p_customer_id': customerId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
