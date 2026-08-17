import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'invoice_document_data.dart';
import 'invoice_logo_loader.dart';
import 'thermal_receipt_config.dart';

/// Builds an 80mm thermal receipt PDF from [InvoiceDocumentData].
///
/// This is a layout variant of the existing invoice rendering pipeline —
/// it consumes the exact same immutable read model as the A4 PDF renderer
/// and produces a narrow receipt suitable for thermal printers exposed
/// through the Windows print stack.
class ThermalReceiptRenderer {
  ThermalReceiptRenderer({InvoiceLogoLoader? logoLoader})
      : _logoLoader = logoLoader ?? const InvoiceLogoLoader();

  final InvoiceLogoLoader _logoLoader;

  static const String regularFontAsset =
      'assets/fonts/NotoSansArabic-Regular.ttf';
  static const String boldFontAsset = 'assets/fonts/NotoSansArabic-Bold.ttf';

  /// Builds the complete receipt document, loading bundled fonts and logo.
  Future<pw.Document> buildDocument(InvoiceDocumentData data) async {
    final regular =
        (await rootBundle.load(regularFontAsset)).buffer.asUint8List();
    final bold = (await rootBundle.load(boldFontAsset)).buffer.asUint8List();
    final logo = await _logoLoader.loadBytes(data.shopProfile.logoPath);
    return buildDocumentWith(data, regular, bold, logo);
  }

  /// Pure core shared by production and tests — no asset bundle access.
  @visibleForTesting
  pw.Document buildDocumentWith(
    InvoiceDocumentData data,
    Uint8List regularFontBytes,
    Uint8List boldFontBytes,
    Uint8List? logoBytes,
  ) {
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularFontBytes.buffer.asByteData()),
      bold: pw.Font.ttf(boldFontBytes.buffer.asByteData()),
      fontFallback: [pw.Font.helvetica()],
    );

    pw.Image? logo;
    if (logoBytes != null) {
      try {
        final image = pw.MemoryImage(logoBytes);
        logo = pw.Image(image,
            width: ThermalReceiptConfig.logoMaxWidth,
            height: ThermalReceiptConfig.logoMaxHeight,
            fit: pw.BoxFit.contain);
      } catch (_) {
        logo = null;
      }
    }

    return pw.Document(
      title: 'فاتورة حرارية ${data.invoiceNumber}',
      author: data.shopProfile.shopName,
    )..addPage(
        pw.MultiPage(
          pageFormat: ThermalReceiptConfig.pageFormat,
          maxPages: 10,
          theme: theme,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            _header(data, logo),
            pw.SizedBox(height: ThermalReceiptConfig.sectionSpacing),
            _meta(data),
            pw.SizedBox(height: ThermalReceiptConfig.sectionSpacing),
            _itemsSection(data),
            pw.SizedBox(height: ThermalReceiptConfig.sectionSpacing),
            _totals(data),
            pw.SizedBox(height: ThermalReceiptConfig.sectionSpacing),
            _footer(data),
          ],
        ),
      );
  }

  pw.Widget _header(InvoiceDocumentData data, pw.Image? logo) {
    final profile = data.shopProfile;
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        children: [
          if (logo != null)
            pw.Container(
              alignment: pw.Alignment.center,
              child: logo,
            ),
          if (logo != null) pw.SizedBox(height: 4),
          pw.Text(
            profile.shopName,
            style: pw.TextStyle(
                fontSize: ThermalReceiptConfig.headerFontSize,
                fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            data.invoiceTitle,
            style:
                const pw.TextStyle(fontSize: ThermalReceiptConfig.metaFontSize),
            textAlign: pw.TextAlign.center,
          ),
          pw.Divider(
              height: 8, thickness: ThermalReceiptConfig.dividerLineWidth),
        ],
      ),
    );
  }

  pw.Widget _meta(InvoiceDocumentData data) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(data.date);
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _metaLine('رقم الفاتورة', data.invoiceNumber),
          _metaLine('التاريخ', dateStr),
          _metaLine('العميل', data.customerName),
          _metaLine('طريقة الدفع', paymentMethodLabel(data.paymentMethod)),
          pw.Divider(
              height: 8, thickness: ThermalReceiptConfig.dividerLineWidth),
        ],
      ),
    );
  }

  pw.Widget _metaLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: ThermalReceiptConfig.metaFontSize)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style:
                const pw.TextStyle(fontSize: ThermalReceiptConfig.metaFontSize),
            textAlign: pw.TextAlign.left,
            maxLines: 2,
            overflow: pw.TextOverflow.span,
          ),
        ),
      ],
    );
  }

  pw.Widget _itemsSection(InvoiceDocumentData data) {
    if (data.lines.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _itemHeader(),
        pw.SizedBox(height: 2),
        for (final (index, line) in data.lines.indexed)
          _itemRow(index + 1, line),
        pw.Divider(height: 8, thickness: ThermalReceiptConfig.dividerLineWidth),
      ],
    );
  }

  pw.Widget _itemHeader() {
    final style = pw.TextStyle(
        fontSize: ThermalReceiptConfig.itemHeaderFontSize,
        fontWeight: pw.FontWeight.bold);
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text('الصنف', style: style),
        ),
        pw.SizedBox(width: 4),
        pw.Text('الكمية × السعر', style: style),
        pw.SizedBox(width: 8),
        pw.Text('الإجمالي', style: style),
      ],
    );
  }

  pw.Widget _itemRow(int index, InvoiceLineData line) {
    final style =
        const pw.TextStyle(fontSize: ThermalReceiptConfig.itemFontSize);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  line.productName,
                  style: style,
                  maxLines: 2,
                  overflow: pw.TextOverflow.span,
                ),
                pw.Text(
                  line.barcode,
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            '${line.quantity}×${formatMoney(line.unitPrice)}',
            style: style,
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            formatMoney(line.lineTotal),
            style: pw.TextStyle(
                fontSize: ThermalReceiptConfig.itemFontSize,
                fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _totals(InvoiceDocumentData data) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'الإجمالي',
            style: pw.TextStyle(
                fontSize: ThermalReceiptConfig.totalFontSize,
                fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            formatMoney(data.totalAmount),
            style: pw.TextStyle(
                fontSize: ThermalReceiptConfig.totalFontSize,
                fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(InvoiceDocumentData data) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        children: [
          if (data.supportPhone.isNotEmpty)
            pw.Text(
              'للدعم: ${data.supportPhone}',
              style: const pw.TextStyle(
                  fontSize: ThermalReceiptConfig.footerFontSize,
                  color: PdfColors.grey600),
            ),
          pw.Text(
            data.invoiceFooterText,
            style: const pw.TextStyle(
                fontSize: ThermalReceiptConfig.footerFontSize,
                color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
