import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_shop_setting.dart';
import '../../repositories/cloud/cloud_settings_repository.dart';

class CloudSettingsService {
  final CloudSettingsRepository _repository;

  CloudSettingsService({CloudSettingsRepository? repository})
      : _repository = repository ?? CloudSettingsRepository();

  static const List<String> cloudSyncableKeys = [
    'shopProfile.shopName',
    'shopProfile.ownerOrManagerName',
    'shopProfile.phone',
    'shopProfile.address',
    'supportPhone',
    'brandColor',
    'invoiceTitle',
    'invoiceFooterText',
    'buttonStyle',
  ];

  Future<List<CloudShopSetting>> getSettings(String shopId) =>
      _repository.getSettings(shopId);

  Future<Map<String, String>> getSettingsAsMap(String shopId) =>
      _repository.getSettingsAsMap(shopId);

  Future<bool> updateSetting(
    String shopId, {
    required String key,
    required String value,
  }) {
    if (key.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Setting key is required',
      );
    }
    if (!cloudSyncableKeys.contains(key)) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Setting key not syncable: $key',
      );
    }
    return _repository.updateSetting(shopId, key: key, value: value);
  }
}
