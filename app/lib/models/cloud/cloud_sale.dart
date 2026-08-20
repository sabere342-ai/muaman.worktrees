class CloudSale {
  final String id;
  final String shopId;
  final String? invoiceId;
  final DateTime date;
  final String productName;
  final String barcode;
  final int quantity;
  final double salePrice;
  final double totalSaleValue;
  final double costPrice;
  final double cogs;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudSale({
    required this.id,
    required this.shopId,
    this.invoiceId,
    required this.date,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.salePrice,
    required this.totalSaleValue,
    required this.costPrice,
    required this.cogs,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudSale.fromJson(Map<String, dynamic> json) {
    return CloudSale(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      invoiceId: json['invoice_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      productName: json['product_name'] as String,
      barcode: json['barcode'] as String,
      quantity: (json['quantity'] as num).toInt(),
      salePrice: (json['sale_price'] as num).toDouble(),
      totalSaleValue: (json['total_sale_value'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      cogs: (json['cogs'] as num).toDouble(),
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
      'invoice_id': invoiceId,
      'date': date.toIso8601String(),
      'product_name': productName,
      'barcode': barcode,
      'quantity': quantity,
      'sale_price': salePrice,
      'total_sale_value': totalSaleValue,
      'cost_price': costPrice,
      'cogs': cogs,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
