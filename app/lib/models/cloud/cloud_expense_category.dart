class CloudExpenseCategory {
  final String id;
  final String shopId;
  final String name;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudExpenseCategory({
    required this.id,
    required this.shopId,
    required this.name,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudExpenseCategory.fromJson(Map<String, dynamic> json) {
    return CloudExpenseCategory(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
