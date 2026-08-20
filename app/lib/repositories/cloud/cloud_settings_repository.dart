import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_shop_setting.dart';

class CloudSettingsRepository {
  final SupabaseClient _client;

  CloudSettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CloudShopSetting>> getSettings(String shopId) async {
    try {
      final data = await _client
          .rpc('get_cloud_shop_settings', params: {'p_shop_id': shopId});
      return (data as List).map((e) => CloudShopSetting.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> updateSetting(
    String shopId, {
    required String key,
    required String value,
  }) async {
    try {
      final data = await _client.rpc('update_cloud_shop_setting', params: {
        'p_shop_id': shopId,
        'p_key': key,
        'p_value': value,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<Map<String, String>> getSettingsAsMap(String shopId) async {
    final settings = await getSettings(shopId);
    return {for (var s in settings) s.settingKey: s.settingValue};
  }
}
