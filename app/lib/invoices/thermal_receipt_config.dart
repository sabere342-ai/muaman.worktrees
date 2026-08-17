import 'package:pdf/pdf.dart';

/// Frozen layout constants for the 80mm thermal receipt variant.
///
/// All dimensions are in PDF points (1/72 inch). The 80mm paper width is
/// 226.77pt (80mm ÷ 25.4mm/in × 72pt/in), with 4mm margins on each side
/// leaving ~213pt of usable content width.
class ThermalReceiptConfig {
  const ThermalReceiptConfig._();

  static const double paperWidthMm = 80;
  static const double marginMm = 4;
  static const double usableWidthMm = paperWidthMm - 2 * marginMm;

  static final PdfPageFormat pageFormat = PdfPageFormat(
    PdfPageFormat.mm * paperWidthMm,
    595,
    marginTop: PdfPageFormat.mm * marginMm,
    marginBottom: PdfPageFormat.mm * marginMm,
    marginLeft: PdfPageFormat.mm * marginMm,
    marginRight: PdfPageFormat.mm * marginMm,
  );

  static const double headerFontSize = 12;
  static const double metaFontSize = 8;
  static const double itemFontSize = 7.5;
  static const double itemHeaderFontSize = 7.5;
  static const double totalFontSize = 10;
  static const double footerFontSize = 7;
  static const double dividerLineWidth = 0.5;
  static const double lineHeight = 10;
  static const double logoMaxWidth = 40 * PdfPageFormat.mm;
  static const double logoMaxHeight = 25 * PdfPageFormat.mm;
  static const double sectionSpacing = 6;
}
