class CloudInventoryCount {
  final String id;
  final String shopId;
  final String productId;
  final int actualQuantity;
  final String notes;
  final DateTime countDate;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudInventoryCount({
    required this.id,
    required this.shopId,
    required this.productId,
    this.actualQuantity = 0,
    this.notes = '',
    required this.countDate,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudInventoryCount.fromJson(Map<String, dynamic> json) {
    return CloudInventoryCount(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      productId: json['product_id'] as String,
      actualQuantity: (json['actual_quantity'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      countDate: DateTime.parse(json['count_date'] as String),
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
      'product_id': productId,
      'actual_quantity': actualQuantity,
      'notes': notes,
      'count_date': countDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
