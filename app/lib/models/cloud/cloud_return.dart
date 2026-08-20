class CloudReturn {
  final String id;
  final String shopId;
  final DateTime date;
  final String productName;
  final String barcode;
  final int quantity;
  final double salePrice;
  final double totalReturnValue;
  final double costPrice;
  final double returnedCogs;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudReturn({
    required this.id,
    required this.shopId,
    required this.date,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.salePrice,
    required this.totalReturnValue,
    required this.costPrice,
    required this.returnedCogs,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudReturn.fromJson(Map<String, dynamic> json) {
    return CloudReturn(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      date: DateTime.parse(json['date'] as String),
      productName: json['product_name'] as String,
      barcode: json['barcode'] as String,
      quantity: (json['quantity'] as num).toInt(),
      salePrice: (json['sale_price'] as num).toDouble(),
      totalReturnValue: (json['total_return_value'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      returnedCogs: (json['returned_cogs'] as num).toDouble(),
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
      'product_name': productName,
      'barcode': barcode,
      'quantity': quantity,
      'sale_price': salePrice,
      'total_return_value': totalReturnValue,
      'cost_price': costPrice,
      'returned_cogs': returnedCogs,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
