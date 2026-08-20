class CloudProduct {
  final String id;
  final String shopId;
  final String name;
  final String barcode;
  final int openingQuantity;
  final int soldQuantity;
  final int returnedQuantity;
  final int currentQuantity;
  final double costPrice;
  final double totalInventoryCost;
  final int inventoryAdjustment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  CloudProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.barcode,
    this.openingQuantity = 0,
    this.soldQuantity = 0,
    this.returnedQuantity = 0,
    this.currentQuantity = 0,
    this.costPrice = 0,
    this.totalInventoryCost = 0,
    this.inventoryAdjustment = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  int get computedCurrentQuantity =>
      openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment;

  double get computedTotalCost => currentQuantity * costPrice;

  factory CloudProduct.fromJson(Map<String, dynamic> json) {
    return CloudProduct(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      openingQuantity: (json['opening_quantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (json['sold_quantity'] as num?)?.toInt() ?? 0,
      returnedQuantity: (json['returned_quantity'] as num?)?.toInt() ?? 0,
      currentQuantity: (json['current_quantity'] as num?)?.toInt() ?? 0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
      totalInventoryCost:
          (json['total_inventory_cost'] as num?)?.toDouble() ?? 0,
      inventoryAdjustment: (json['inventory_adjustment'] as num?)?.toInt() ?? 0,
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
      'barcode': barcode,
      'opening_quantity': openingQuantity,
      'sold_quantity': soldQuantity,
      'returned_quantity': returnedQuantity,
      'current_quantity': currentQuantity,
      'cost_price': costPrice,
      'total_inventory_cost': totalInventoryCost,
      'inventory_adjustment': inventoryAdjustment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
