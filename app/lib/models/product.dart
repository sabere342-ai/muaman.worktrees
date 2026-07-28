class Product {
  final int? id;
  final String name;
  final String barcode;
  final int openingQuantity;
  final int soldQuantity;
  final int returnedQuantity;
  final int currentQuantity;
  final double costPrice;
  final double totalInventoryCost;
  final int inventoryAdjustment;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    this.openingQuantity = 0,
    this.soldQuantity = 0,
    this.returnedQuantity = 0,
    this.currentQuantity = 0,
    this.costPrice = 0,
    this.totalInventoryCost = 0,
    this.inventoryAdjustment = 0,
  });

  int get computedCurrentQuantity =>
      openingQuantity - soldQuantity + returnedQuantity + inventoryAdjustment;

  double get computedTotalCost => currentQuantity * costPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'openingQuantity': openingQuantity,
      'soldQuantity': soldQuantity,
      'returnedQuantity': returnedQuantity,
      'currentQuantity': computedCurrentQuantity,
      'costPrice': costPrice,
      'totalInventoryCost': computedCurrentQuantity * costPrice,
      'inventoryAdjustment': inventoryAdjustment,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      openingQuantity: (map['openingQuantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (map['soldQuantity'] as num?)?.toInt() ?? 0,
      returnedQuantity: (map['returnedQuantity'] as num?)?.toInt() ?? 0,
      currentQuantity: (map['currentQuantity'] as num?)?.toInt() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      totalInventoryCost: (map['totalInventoryCost'] as num?)?.toDouble() ?? 0,
      inventoryAdjustment: (map['inventoryAdjustment'] as num?)?.toInt() ?? 0,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    int? openingQuantity,
    int? soldQuantity,
    int? returnedQuantity,
    int? currentQuantity,
    double? costPrice,
    double? totalInventoryCost,
    int? inventoryAdjustment,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      openingQuantity: openingQuantity ?? this.openingQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      costPrice: costPrice ?? this.costPrice,
      totalInventoryCost: totalInventoryCost ?? this.totalInventoryCost,
      inventoryAdjustment: inventoryAdjustment ?? this.inventoryAdjustment,
    );
  }
}
