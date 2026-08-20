class CloudInvoice {
  final String id;
  final String shopId;
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String? customerId;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final DateTime createdAt;
  final DateTime? deletedAt;

  CloudInvoice({
    required this.id,
    required this.shopId,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    this.customerId,
    required this.paymentMethod,
    this.totalAmount = 0,
    this.totalItems = 0,
    required this.createdAt,
    this.deletedAt,
  });

  factory CloudInvoice.fromJson(Map<String, dynamic> json) {
    return CloudInvoice(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      date: DateTime.parse(json['date'] as String),
      customerName: json['customer_name'] as String,
      customerId: json['customer_id'] as String?,
      paymentMethod: json['payment_method'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
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
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_id': customerId,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'total_items': totalItems,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
