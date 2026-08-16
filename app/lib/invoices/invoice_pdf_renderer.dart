import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'invoice_document_data.dart';
import 'invoice_logo_loader.dart';

/// Builds the A4 Arabic/RTL invoice PDF from an [InvoiceDocumentData].
///
/// Rendering strategy:
///  - Default `pdf` build settings are used on purpose: the package's built-in
///    RTL path (`bidi.logicalToVisual` + right-to-left line mirroring) produces
///    correctly shaped and ordered Arabic without any compile-time define.
///  - The items list is chunked into fixed-size tables before layout so every
///    top-level widget is smaller than one page. This keeps `pw.MultiPage`
///    from ever exceeding a page with a single widget (its only failure mode
///    for overflowing content).
class InvoicePdfRenderer {
  InvoicePdfRenderer({InvoiceLogoLoader? logoLoader})
      : _logoLoader = logoLoader ?? const InvoiceLogoLoader();

  static const String regularFontAsset =
      'assets/fonts/NotoSansArabic-Regular.ttf';
  static const String boldFontAsset = 'assets/fonts/NotoSansArabic-Bold.ttf';

  final InvoiceLogoLoader _logoLoader;
  String _currentSupportPhone = '';

  /// Builds the document, loading the bundled Arabic fonts and the shop logo.
  Future<pw.Document> buildDocument(InvoiceDocumentData data) async {
    final regular =
        (await rootBundle.load(regularFontAsset)).buffer.asUint8List();
    final bold = (await rootBundle.load(boldFontAsset)).buffer.asUint8List();
    final logo = await _logoLoader.loadBytes(data.shopProfile.logoPath);
    return buildDocumentWith(data, regular, bold, logo);
  }

  /// Pure core shared by production and tests: no asset bundle or file access.
  @visibleForTesting
  pw.Document buildDocumentWith(
    InvoiceDocumentData data,
    Uint8List regularFontBytes,
    Uint8List boldFontBytes,
    Uint8List? logoBytes,
  ) {
    _currentSupportPhone = data.supportPhone;
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularFontBytes.buffer.asByteData()),
      bold: pw.Font.ttf(boldFontBytes.buffer.asByteData()),
      fontFallback: [pw.Font.helvetica()],
    );

    pw.Image? logo;
    if (logoBytes != null) {
      try {
        logo = pw.Image(pw.MemoryImage(logoBytes), width: 90);
      } catch (_) {
        // Fail safe: an undecodable logo must never break the invoice.
        logo = null;
      }
    }

    final rowsPerPage = rowsPerPageFor(PdfPageFormat.a4);
    final chunks = _chunk(data.lines, rowsPerPage);

    return pw.Document(
      title: 'فاتورة ${data.invoiceNumber}',
      author: data.shopProfile.shopName,
    )..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          maxPages: 100,
          theme: theme,
          textDirection: pw.TextDirection.rtl,
          footer: (context) => _footer(),
          build: (context) => [
            _header(data, logo),
            pw.SizedBox(height: 10),
            _meta(data),
            pw.SizedBox(height: 10),
            for (final chunk in chunks) ...[
              _itemsTable(chunk),
              pw.SizedBox(height: 8),
            ],
            _totals(data),
          ],
        ),
      );
  }

  /// Number of item rows per chunk that can never overflow a page, computed
  /// from the worst case (every row wrapping to two lines at the table font
  /// size) minus a fixed reserve for the header/meta/totals/footer blocks.
  @visibleForTesting
  int rowsPerPageFor(PdfPageFormat format) {
    final contentHeight =
        format.height - format.marginTop - format.marginBottom;
    const fixedReserve = 330.0;
    const worstCaseRowHeight = 34.0;
    final available = contentHeight - fixedReserve;
    final rows = (available / worstCaseRowHeight).floor();
    return rows < 5 ? 5 : rows;
  }

  List<List<(int, InvoiceLineData)>> _chunk(
      List<InvoiceLineData> lines, int perChunk) {
    final chunks = <List<(int, InvoiceLineData)>>[];
    for (var i = 0; i < lines.length; i += perChunk) {
      chunks.add([
        for (var j = i; j < lines.length && j < i + perChunk; j++)
          (j + 1, lines[j]),
      ]);
    }
    return chunks;
  }

  pw.Widget _header(InvoiceDocumentData data, pw.Image? logo) {
    final profile = data.shopProfile;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(profile.shopName,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  if (profile.ownerOrManagerName.trim().isNotEmpty)
                    pw.Text(profile.ownerOrManagerName.trim(),
                        style: const pw.TextStyle(fontSize: 9)),
                  if (profile.phone.trim().isNotEmpty)
                    pw.Text(profile.phone.trim(),
                        style: const pw.TextStyle(fontSize: 9)),
                  if (profile.address.trim().isNotEmpty)
                    pw.Text(profile.address.trim(),
                        style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (logo != null)
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: logo,
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('فاتورة بيع',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _meta(InvoiceDocumentData data) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('رقم الفاتورة: ${data.invoiceNumber}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
              'التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(data.date)}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('العميل: ${data.customerName}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('طريقة الدفع: ${paymentMethodLabel(data.paymentMethod)}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('عدد الأصناف: ${data.totalItems}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(List<(int, InvoiceLineData)> rows) {
    const widths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(26),
      1: pw.FixedColumnWidth(172),
      2: pw.FixedColumnWidth(70),
      3: pw.FixedColumnWidth(48),
      4: pw.FixedColumnWidth(74),
      5: pw.FixedColumnWidth(92),
    };
    return pw.Table(
      columnWidths: widths,
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        _tableRow(
          const [
            'م',
            'الصنف',
            'الباركود',
            'الكمية',
            'سعر الوحدة',
            'الإجمالي',
          ],
          isHeader: true,
        ),
        for (final (index, line) in rows)
          _tableRow([
            '$index',
            line.productName,
            line.barcode,
            '${line.quantity}',
            formatMoney(line.unitPrice),
            formatMoney(line.lineTotal),
          ]),
      ],
    );
  }

  pw.TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    final style = pw.TextStyle(
      fontSize: isHeader ? 9 : 8.5,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.TableRow(
      children: [
        for (final cell in cells)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(
              cell,
              style: style,
              textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.center,
            ),
          ),
      ],
    );
  }

  pw.Widget _totals(InvoiceDocumentData data) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('إجمالي الفاتورة',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(formatMoney(data.totalAmount),
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _footer() {
    final phone = _currentSupportPhone;
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        children: [
          if (phone.isNotEmpty)
            pw.Text(
              'للدعم: $phone',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          pw.Text(
            'شكراً لتعاملكم معنا',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
