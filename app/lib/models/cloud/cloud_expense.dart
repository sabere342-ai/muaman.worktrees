class CloudExpense {
  final String id;
  final String shopId;
  final DateTime date;
  final String description;
  final double amount;
  final String? categoryName;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudExpense({
    required this.id,
    required this.shopId,
    required this.date,
    required this.description,
    this.amount = 0,
    this.categoryName,
    this.categoryId,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudExpense.fromJson(Map<String, dynamic> json) {
    return CloudExpense(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      categoryName: json['category_name'] as String?,
      categoryId: json['category_id'] as String?,
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
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'category_name': categoryName,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
