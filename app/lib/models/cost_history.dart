class CostHistory {
  final int? id;
  final String shopId;
  final int productId;
  final String productName;
  final String productBarcode;
  final double oldCost;
  final double newCost;
  final String changedAt;
  final String? changedBy;

  CostHistory({
    this.id,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.productBarcode,
    required this.oldCost,
    required this.newCost,
    required this.changedAt,
    this.changedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'product_id': productId,
      'product_name': productName,
      'product_barcode': productBarcode,
      'old_cost': oldCost,
      'new_cost': newCost,
      'changed_at': changedAt,
      'changed_by': changedBy,
    };
  }

  factory CostHistory.fromMap(Map<String, dynamic> map) {
    return CostHistory(
      id: map['id'] as int?,
      shopId: map['shop_id'] as String? ?? '',
      productId: (map['product_id'] as num?)?.toInt() ?? 0,
      productName: map['product_name'] as String? ?? '',
      productBarcode: map['product_barcode'] as String? ?? '',
      oldCost: (map['old_cost'] as num?)?.toDouble() ?? 0,
      newCost: (map['new_cost'] as num?)?.toDouble() ?? 0,
      changedAt: map['changed_at'] as String? ?? '',
      changedBy: map['changed_by'] as String?,
    );
  }
}
