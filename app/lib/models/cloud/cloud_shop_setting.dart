class CloudShopSetting {
  final String shopId;
  final String settingKey;
  final String settingValue;
  final DateTime updatedAt;
  final String? updatedBy;

  CloudShopSetting({
    required this.shopId,
    required this.settingKey,
    required this.settingValue,
    required this.updatedAt,
    this.updatedBy,
  });

  factory CloudShopSetting.fromJson(Map<String, dynamic> json) {
    return CloudShopSetting(
      shopId: json['shop_id'] as String,
      settingKey: json['setting_key'] as String,
      settingValue: json['setting_value'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}
