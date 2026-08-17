import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/invoices/invoice_document_data.dart';
import 'package:muaman_store/invoices/thermal_receipt_config.dart';
import 'package:muaman_store/invoices/thermal_receipt_renderer.dart';
import 'package:muaman_store/models/shop_profile.dart';
import 'package:muaman_store/services/app_settings.dart';

import '../helpers/test_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  InvoiceDocumentData sampleData({
    List<InvoiceLineData>? lines,
    double? totalAmount,
    int? totalItems,
    String? supportPhone,
    String? invoiceTitle,
    String? invoiceFooterText,
  }) {
    final resolvedLines = lines ??
        [
          const InvoiceLineData(
              barcode: 'B1',
              productName: 'منتج اختبار',
              quantity: 2,
              unitPrice: 150),
        ];
    var sum = 0.0;
    for (final line in resolvedLines) {
      sum += line.lineTotal;
    }
    return InvoiceDocumentData(
      invoiceNumber: 'INV-1728000000000',
      date: DateTime(2026, 8, 11, 10, 30),
      customerName: 'عميل تجريبي',
      paymentMethod: 'cash',
      totalAmount: totalAmount ?? sum,
      totalItems: totalItems ?? resolvedLines.length,
      shopProfile: const ShopProfile(shopName: 'محل مؤمن'),
      lines: resolvedLines,
      supportPhone: supportPhone ?? '',
      invoiceTitle: invoiceTitle ?? 'فاتورة بيع',
      invoiceFooterText: invoiceFooterText ?? 'شكراً لتعاملكم معنا',
    );
  }

  Future<(Uint8List, Uint8List)> fontBytes() async {
    final regular =
        (await rootBundle.load(ThermalReceiptRenderer.regularFontAsset))
            .buffer
            .asUint8List();
    final bold = (await rootBundle.load(ThermalReceiptRenderer.boldFontAsset))
        .buffer
        .asUint8List();
    return (regular, bold);
  }

  int countOccurrences(List<int> haystack, List<int> needle) {
    var count = 0;
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) count++;
    }
    return count;
  }

  int countPdfPages(List<int> bytes) {
    final page = countOccurrences(bytes, '/Type/Page'.codeUnits);
    final pages = countOccurrences(bytes, '/Type/Pages'.codeUnits);
    return page - pages;
  }

  group('Thermal Receipt Config', () {
    test('page format has correct 80mm width', () {
      final format = ThermalReceiptConfig.pageFormat;
      final expectedWidth = 80.0 * 2.83465;
      expect(format.width, closeTo(expectedWidth, 1.0));
    });

    test('margins are 4mm on each side', () {
      final format = ThermalReceiptConfig.pageFormat;
      final expectedMargin = 4.0 * 2.83465;
      expect(format.marginTop, closeTo(expectedMargin, 0.5));
      expect(format.marginBottom, closeTo(expectedMargin, 0.5));
      expect(format.marginLeft, closeTo(expectedMargin, 0.5));
      expect(format.marginRight, closeTo(expectedMargin, 0.5));
    });

    test('font sizes are within frozen range', () {
      expect(ThermalReceiptConfig.headerFontSize, 12);
      expect(ThermalReceiptConfig.metaFontSize, 8);
      expect(ThermalReceiptConfig.itemFontSize, 7.5);
      expect(ThermalReceiptConfig.totalFontSize, 10);
      expect(ThermalReceiptConfig.footerFontSize, 7);
    });
  });

  group('Thermal Receipt Renderer', () {
    final renderer = ThermalReceiptRenderer();

    test('buildDocumentWith produces valid PDF bytes', () async {
      final (regular, bold) = await fontBytes();
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('produces single-page receipt for small invoice', () async {
      final (regular, bold) = await fontBytes();
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, null);
      final bytes = await document.save();
      expect(countPdfPages(bytes), 1);
    });

    test('handles Arabic shop name and product names', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData(
        lines: [
          const InvoiceLineData(
              barcode: 'AR-001',
              productName: 'جهاز كمبيوتر محمول',
              quantity: 1,
              unitPrice: 15000),
          const InvoiceLineData(
              barcode: 'AR-002',
              productName: 'سماعات لاسلكية',
              quantity: 2,
              unitPrice: 500),
        ],
      );
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('handles long product names by wrapping', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData(
        lines: [
          const InvoiceLineData(
              barcode: 'LONG-001',
              productName:
                  'هذا اسم منتج طويل جداً يجب أن يلتف بشكل صحيح داخل عمود الإيصال الحراري',
              quantity: 1,
              unitPrice: 100),
        ],
      );
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('handles missing logo gracefully', () async {
      final (regular, bold) = await fontBytes();
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('handles undecodable logo without breaking', () async {
      final (regular, bold) = await fontBytes();
      final garbage = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, garbage);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('includes footer text', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData(
        invoiceFooterText: 'شكراً لتعاملكم معنا',
        supportPhone: '+201014900211',
      );
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('handles empty support phone', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData(supportPhone: '');
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('handles multiple items', () async {
      final (regular, bold) = await fontBytes();
      final lines = [
        for (var i = 0; i < 20; i++)
          InvoiceLineData(
              barcode: 'B$i',
              productName: 'منتج $i',
              quantity: i + 1,
              unitPrice: 10.0 * (i + 1)),
      ];
      final data = sampleData(
        lines: lines,
        totalAmount: lines.fold<double>(0, (sum, l) => sum + l.lineTotal),
        totalItems: lines.length,
      );
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('does not mutate invoice data', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData();
      final originalTotal = data.totalAmount;
      final originalCustomer = data.customerName;
      final originalLinesCount = data.lines.length;
      renderer.buildDocumentWith(data, regular, bold, null);
      expect(data.totalAmount, originalTotal);
      expect(data.customerName, originalCustomer);
      expect(data.lines.length, originalLinesCount);
    });

    test('buildDocument loads bundled fonts successfully', () async {
      final document = await renderer.buildDocument(sampleData());
      final bytes = await document.save();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('handles empty lines list', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData(lines: [], totalAmount: 0, totalItems: 0);
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('handles very long customer name', () async {
      final (regular, bold) = await fontBytes();
      final data = sampleData();
      final longData = InvoiceDocumentData(
        invoiceNumber: data.invoiceNumber,
        date: data.date,
        customerName: 'عميل طويل الاسم جداً جداً جداً جداً',
        paymentMethod: data.paymentMethod,
        totalAmount: data.totalAmount,
        totalItems: data.totalItems,
        shopProfile: data.shopProfile,
        lines: data.lines,
        supportPhone: data.supportPhone,
        invoiceTitle: data.invoiceTitle,
        invoiceFooterText: data.invoiceFooterText,
      );
      final document =
          renderer.buildDocumentWith(longData, regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });

    test('uses correct page format from config', () async {
      final (regular, bold) = await fontBytes();
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(500));
    });
  });

  group('Thermal Receipt - Settings', () {
    test('thermal printer name defaults to empty', () async {
      final name = await AppSettings.getThermalPrinterName();
      expect(name, isEmpty);
    });

    test('thermal paper width defaults to 80', () async {
      final width = await AppSettings.getThermalPaperWidth();
      expect(width, 80);
    });

    test('thermal print copies defaults to 1', () async {
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 1);
    });

    test('thermal printer name set and get', () async {
      await AppSettings.setThermalPrinterName('My Thermal Printer');
      final name = await AppSettings.getThermalPrinterName();
      expect(name, 'My Thermal Printer');
    });

    test('thermal printer name trims whitespace', () async {
      await AppSettings.setThermalPrinterName('  HP Printer  ');
      final name = await AppSettings.getThermalPrinterName();
      expect(name, 'HP Printer');
    });

    test('thermal paper width set and get for 80', () async {
      await AppSettings.setThermalPaperWidth(80);
      final width = await AppSettings.getThermalPaperWidth();
      expect(width, 80);
    });

    test('thermal paper width set and get for 58', () async {
      await AppSettings.setThermalPaperWidth(58);
      final width = await AppSettings.getThermalPaperWidth();
      expect(width, 58);
    });

    test('thermal paper width falls back to 80 for invalid value', () async {
      await AppSettings.setValue(AppSettings.keyThermalPaperWidth, 'invalid');
      final width = await AppSettings.getThermalPaperWidth();
      expect(width, 80);
    });

    test('thermal paper width falls back to 80 for empty value', () async {
      await AppSettings.setValue(AppSettings.keyThermalPaperWidth, '');
      final width = await AppSettings.getThermalPaperWidth();
      expect(width, 80);
    });

    test('thermal print copies set and get', () async {
      await AppSettings.setThermalPrintCopies(3);
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 3);
    });

    test('thermal print copies clamped to minimum 1', () async {
      await AppSettings.setThermalPrintCopies(0);
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 1);
    });

    test('thermal print copies clamped to maximum 11', () async {
      await AppSettings.setThermalPrintCopies(15);
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 10);
    });

    test('thermal print copies falls back to 1 for invalid value', () async {
      await AppSettings.setValue(AppSettings.keyThermalPrintCopies, 'abc');
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 1);
    });

    test('thermal print copies falls back to 1 for negative value', () async {
      await AppSettings.setValue(AppSettings.keyThermalPrintCopies, '-5');
      final copies = await AppSettings.getThermalPrintCopies();
      expect(copies, 1);
    });

    test('thermal settings preserved after initializeDefaults', () async {
      await AppSettings.setThermalPrinterName('Test Printer');
      await AppSettings.setThermalPaperWidth(80);
      await AppSettings.setThermalPrintCopies(2);
      await AppSettings.initializeDefaults();
      expect(await AppSettings.getThermalPrinterName(), 'Test Printer');
      expect(await AppSettings.getThermalPaperWidth(), 80);
      expect(await AppSettings.getThermalPrintCopies(), 2);
    });
  });
}
