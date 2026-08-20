class CloudCustomer {
  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  CloudCustomer({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.isActive = true,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CloudCustomer.fromJson(Map<String, dynamic> json) {
    return CloudCustomer(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'is_active': isActive,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
