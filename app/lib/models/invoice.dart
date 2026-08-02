class Invoice {
  final int? id;
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final DateTime createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.paymentMethod,
    required this.totalAmount,
    required this.totalItems,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'totalItems': totalItems,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoiceNumber'] as String,
      date: DateTime.parse(map['date'] as String),
      customerName: map['customerName'] as String,
      paymentMethod: map['paymentMethod'] as String,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      totalItems: (map['totalItems'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
