import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'invoice_document_data.dart';
import 'thermal_receipt_config.dart';
import 'thermal_receipt_renderer.dart';

/// Delivery of a thermal receipt: prints the narrow receipt PDF via the
/// Windows print dialog. All operations are read-only for business data.
class ThermalDelivery {
  ThermalDelivery({ThermalReceiptRenderer? renderer})
      : _renderer = renderer ?? ThermalReceiptRenderer();

  final ThermalReceiptRenderer _renderer;

  Future<Uint8List> buildPdfBytes(InvoiceDocumentData data) async {
    final document = await _renderer.buildDocument(data);
    return document.save();
  }

  /// Opens the native print dialog for the thermal receipt.
  ///
  /// Returns true when the document was sent to the printer and false when the
  /// user cancels. Uses the same [Printing.layoutPdf] path as A4 printing,
  /// inheriting the WM_CLOSE protection from MUAMAN-18.
  Future<bool> print(InvoiceDocumentData data) {
    return Printing.layoutPdf(
      name: 'thermal_${data.invoiceNumber}.pdf',
      format: ThermalReceiptConfig.pageFormat,
      onLayout: (_) => buildPdfBytes(data),
    );
  }
}
