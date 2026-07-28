class ReturnItem {
  final int? id;
  final DateTime date;
  final String productName;
  final String barcode;
  final int quantity;
  final double salePrice;
  final double totalReturnValue;
  final double costPrice;
  final double returnedCogs;

  ReturnItem({
    this.id,
    required this.date,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.salePrice,
    this.totalReturnValue = 0,
    this.costPrice = 0,
    this.returnedCogs = 0,
  });

  double get computedTotalReturnValue => quantity * salePrice;
  double get computedReturnedCogs => quantity * costPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'productName': productName,
      'barcode': barcode,
      'quantity': quantity,
      'salePrice': salePrice,
      'totalReturnValue': computedTotalReturnValue,
      'costPrice': costPrice,
      'returnedCogs': computedReturnedCogs,
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      productName: map['productName'] as String,
      barcode: map['barcode'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0,
      totalReturnValue: (map['totalReturnValue'] as num?)?.toDouble() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      returnedCogs: (map['returnedCogs'] as num?)?.toDouble() ?? 0,
    );
  }
}
