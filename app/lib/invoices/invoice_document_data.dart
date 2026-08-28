import 'package:flutter/foundation.dart';
import '../models/shop_profile.dart';

/// A single line on a printed invoice. Immutable snapshot of the persisted
/// sale row (barcode, name, quantity, unit price). The line total is derived
/// the same way the rest of the app derives it: `quantity * salePrice`.
@immutable
class InvoiceLineData {
  const InvoiceLineData({
    required this.barcode,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String barcode;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

/// Read model for the invoice PDF/preview: everything needed to render the
/// document, assembled from the persisted invoice, its sale rows and the
/// current [ShopProfile] branding. Never recomputes business totals with a
/// different formula than the persisted sale total.
@immutable
class InvoiceDocumentData {
  const InvoiceDocumentData({
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.paymentMethod,
    required this.totalAmount,
    required this.totalItems,
    required this.shopProfile,
    required this.lines,
    this.supportPhone = '',
    this.invoiceTitle = 'فاتورة بيع',
    this.invoiceFooterText = 'شكراً لتعاملكم معنا',
    this.itechAttributionText = 'تم التطوير بواسطة I Tech للتكنولوجيا',
  });

  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String paymentMethod;
  final double totalAmount;
  final int totalItems;
  final ShopProfile shopProfile;
  final List<InvoiceLineData> lines;

  /// Configurable support phone loaded from [AppSettings]. Displayed in the
  /// invoice PDF footer and preview screen as a customer contact point.
  final String supportPhone;

  /// Configurable invoice title loaded from [AppSettings]. Displayed as the
  /// centered heading in the PDF header and in the preview screen.
  final String invoiceTitle;

  /// Configurable footer message loaded from [AppSettings]. Displayed at the
  /// bottom of the invoice PDF and in the preview screen.
  final String invoiceFooterText;

  /// Fixed I Tech attribution text per Owner Decision OD5.
  /// OD5_EXACT_ATTRIBUTION_TEXT = "تم التطوير بواسطة I Tech للتكنولوجيا"
  /// OD5_EDITABILITY_POLICY = FIXED_NON_EDITABLE
  final String itechAttributionText;

  /// Sum of the rendered line totals. For any invoice loaded from persistence
  /// this is exactly [totalAmount]; kept separate so tests can assert the
  /// monetary invariant that gates this feature.
  double get computedLinesTotal =>
      lines.fold(0.0, (sum, line) => sum + line.lineTotal);
}

/// Official money display convention used across the application:
/// integer pounds followed by the currency suffix.
String formatMoney(double value) => '${value.toStringAsFixed(0)} ج.م';

/// ASCII-safe PDF file name derived from the invoice number.
String invoiceFileName(InvoiceDocumentData data) =>
    'invoice_${data.invoiceNumber}.pdf';

/// Arabic label for a stored payment-method code.
String paymentMethodLabel(String code) {
  switch (code) {
    case 'cash':
      return 'نقدي';
    case 'visa':
      return 'فيزا';
    case 'insta_cash':
      return 'إنستا كاش';
    default:
      return code;
  }
}
