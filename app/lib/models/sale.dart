class Sale {
  final int? id;
  final int? invoiceId;
  final DateTime date;
  final String productName;
  final String barcode;
  final int quantity;
  final double salePrice;
  final double totalSaleValue;
  final double costPrice;
  final double cogs;

  Sale({
    this.id,
    this.invoiceId,
    required this.date,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.salePrice,
    this.totalSaleValue = 0,
    this.costPrice = 0,
    this.cogs = 0,
  });

  double get computedTotalSaleValue => quantity * salePrice;
  double get computedCogs => quantity * costPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'date': date.toIso8601String(),
      'productName': productName,
      'barcode': barcode,
      'quantity': quantity,
      'salePrice': salePrice,
      'totalSaleValue': computedTotalSaleValue,
      'costPrice': costPrice,
      'cogs': computedCogs,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      invoiceId: map['invoiceId'] as int?,
      date: DateTime.parse(map['date'] as String),
      productName: map['productName'] as String,
      barcode: map['barcode'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0,
      totalSaleValue: (map['totalSaleValue'] as num?)?.toDouble() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      cogs: (map['cogs'] as num?)?.toDouble() ?? 0,
    );
  }

  Sale copyWith({
    int? id,
    int? invoiceId,
    DateTime? date,
    String? productName,
    String? barcode,
    int? quantity,
    double? salePrice,
    double? totalSaleValue,
    double? costPrice,
    double? cogs,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      totalSaleValue: totalSaleValue ?? this.totalSaleValue,
      costPrice: costPrice ?? this.costPrice,
      cogs: cogs ?? this.cogs,
    );
  }
}
