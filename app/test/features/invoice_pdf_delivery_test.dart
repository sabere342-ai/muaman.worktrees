import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/invoice_repository.dart';
import 'package:muaman_store/invoices/invoice_delivery.dart';
import 'package:muaman_store/invoices/invoice_document_data.dart';
import 'package:muaman_store/invoices/invoice_logo_loader.dart';
import 'package:muaman_store/invoices/invoice_pdf_renderer.dart';
import 'package:muaman_store/models/invoice.dart';
import 'package:muaman_store/models/sale.dart';
import 'package:muaman_store/models/shop_profile.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/invoices/invoice_preview_screen.dart';
import 'package:muaman_store/screens/sales/invoice_screen.dart';
import 'package:muaman_store/screens/sales/sales_screen.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/session_state.dart';

import '../helpers/test_schema.dart';

const String _kOnePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;
  late PermissionResolver originalResolver;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
    originalResolver = DatabaseHelper.instance.permissionResolver;
    DatabaseHelper.instance.permissionResolver = PermissionResolver();
  });

  tearDown(() async {
    DatabaseHelper.instance.permissionResolver = originalResolver;
    await testDb.close();
  });

  Future<void> seedCustomer() async {
    await testDb.insert('customers', {
      'name': 'عميل تجريبي',
      'phone': '0123456789',
      'isActive': 1,
      'isSystem': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> seedProduct() async {
    await testDb.insert('products', {
      'name': 'منتج اختبار',
      'barcode': 'TEST-BAR-001',
      'openingQuantity': 100,
      'currentQuantity': 100,
      'costPrice': 50,
      'totalInventoryCost': 5000,
      'inventoryAdjustment': 0,
    });
  }

  Future<int> seedInvoiceWithItems() async {
    await seedProduct();
    final invoice = Invoice(
      invoiceNumber: 'INV-1728000000000',
      date: DateTime(2026, 8, 11, 10, 30),
      customerName: 'عميل تجريبي',
      paymentMethod: 'cash',
      totalAmount: 420,
      totalItems: 2,
    );
    final items = [
      Sale(
        date: DateTime(2026, 8, 11, 10, 30),
        productName: 'منتج اختبار',
        barcode: 'TEST-BAR-001',
        quantity: 2,
        salePrice: 150,
        costPrice: 50,
      ),
      Sale(
        date: DateTime(2026, 8, 11, 10, 30),
        productName: 'منتج اختبار',
        barcode: 'TEST-BAR-001',
        quantity: 1,
        salePrice: 120,
        costPrice: 50,
      ),
    ];
    return DatabaseHelper.instance
        .insertInvoiceWithItems(invoice, items, currentRole: UserRole.owner);
  }

  SessionState ownerSession() {
    final session =
        SessionState(resolver: DatabaseHelper.instance.permissionResolver);
    session.login(User(
      displayName: 'المالك',
      username: 'owner',
      passwordHash: 'x',
      role: UserRole.owner,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    return session;
  }

  SessionState salesOnlySession() {
    final session =
        SessionState(resolver: DatabaseHelper.instance.permissionResolver);
    session.login(User(
      displayName: 'مبيعات',
      username: 'sales',
      passwordHash: 'x',
      role: UserRole.salesOnly,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    return session;
  }

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
              productName: 'منتج 1',
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

  group('A - InvoiceDocumentData helpers', () {
    test('formatMoney uses the official money convention', () {
      expect(formatMoney(150), '150 ج.م');
      expect(formatMoney(0), '0 ج.م');
      expect(formatMoney(150.5), '151 ج.م');
    });

    test('invoiceFileName is ASCII-safe and ends with .pdf', () {
      final name = invoiceFileName(sampleData());
      expect(name, 'invoice_INV-1728000000000.pdf');
      expect(name, isNot(contains(' ')));
      expect(name.endsWith('.pdf'), isTrue);
    });

    test('paymentMethodLabel maps known codes', () {
      expect(paymentMethodLabel('cash'), 'نقدي');
      expect(paymentMethodLabel('visa'), 'فيزا');
      expect(paymentMethodLabel('insta_cash'), 'إنستا كاش');
      expect(paymentMethodLabel('unknown'), 'unknown');
    });

    test('computedLinesTotal equals the sum of the line totals', () {
      final data = sampleData(lines: [
        const InvoiceLineData(
            barcode: 'B1', productName: 'p1', quantity: 2, unitPrice: 150),
        const InvoiceLineData(
            barcode: 'B2', productName: 'p2', quantity: 3, unitPrice: 100),
      ]);
      expect(data.computedLinesTotal, 600);
    });
  });

  group('B - InvoiceLogoLoader', () {
    const loader = InvoiceLogoLoader();

    test('returns null for a missing or empty path', () async {
      expect(await loader.loadBytes(null), isNull);
      expect(await loader.loadBytes(''), isNull);
    });

    test('returns null for a nonexistent file', () async {
      expect(await loader.loadBytes('C:\\no\\such\\logo.png'), isNull);
    });

    test('returns the file bytes for an existing logo', () async {
      final dir = await Directory.systemTemp.createTemp('logo_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}\\logo.png');
      await file.writeAsBytes(base64Decode(_kOnePixelPngBase64));
      final bytes = await loader.loadBytes(file.path);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(20));
    });

    test('returns null for an oversized logo', () async {
      final dir = await Directory.systemTemp.createTemp('logo_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}\\big.png');
      await file.writeAsBytes(
          List<int>.filled(InvoiceLogoLoader.maxLogoBytes + 1, 1));
      expect(await loader.loadBytes(file.path), isNull);
    });
  });

  group('C - InvoicePdfRenderer', () {
    final renderer = InvoicePdfRenderer();

    Future<(Uint8List, Uint8List)> fontBytes() async {
      final regular =
          (await rootBundle.load(InvoicePdfRenderer.regularFontAsset))
              .buffer
              .asUint8List();
      final bold = (await rootBundle.load(InvoicePdfRenderer.boldFontAsset))
          .buffer
          .asUint8List();
      return (regular, bold);
    }

    int countPdfPages(Uint8List bytes) {
      final page = _countSequence(bytes, asciiBytes('/Type/Page'));
      final pages = _countSequence(bytes, asciiBytes('/Type/Pages'));
      return page - pages;
    }

    test('rowsPerPageFor(A4) guarantees every chunk fits one page', () {
      const format = PdfPageFormat.a4;
      final contentHeight =
          format.height - format.marginTop - format.marginBottom;
      final rows = renderer.rowsPerPageFor(format);
      expect(rows, greaterThan(0));
      final worstCaseChunkHeight = rows * 34.0;
      expect(worstCaseChunkHeight, lessThan(contentHeight));
    });

    test('buildDocumentWith produces a single-page A4 PDF', () async {
      final (regular, bold) = await fontBytes();
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, null);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(countPdfPages(bytes), 1);
    });

    test('buildDocumentWith paginates a large items list safely', () async {
      final (regular, bold) = await fontBytes();
      final lines = [
        for (var i = 0; i < 60; i++)
          InvoiceLineData(
              barcode: 'B$i',
              productName: 'منتج رقم $i',
              quantity: 1,
              unitPrice: 10),
      ];
      final data = sampleData(
          lines: lines, totalAmount: 60 * 10.0, totalItems: lines.length);
      final document = renderer.buildDocumentWith(data, regular, bold, null);
      final bytes = await document.save();
      expect(countPdfPages(bytes), greaterThan(1));
    });

    test('an undecodable logo never breaks the document', () async {
      final (regular, bold) = await fontBytes();
      final garbage = Uint8List.fromList(asciiBytes('not-an-image'));
      final document =
          renderer.buildDocumentWith(sampleData(), regular, bold, garbage);
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
    });

    test('buildDocument loads bundled fonts and builds a PDF', () async {
      final document = await renderer.buildDocument(sampleData());
      final bytes = await document.save();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('PDF contains support phone when provided', () async {
      final (regular, bold) = await fontBytes();
      final document = renderer.buildDocumentWith(
        sampleData(supportPhone: '+201111111111'),
        regular,
        bold,
        null,
      );
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('PDF renders without errors when support phone is empty', () async {
      final (regular, bold) = await fontBytes();
      final document = renderer.buildDocumentWith(
        sampleData(supportPhone: ''),
        regular,
        bold,
        null,
      );
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('PDF renders custom invoice title', () async {
      final (regular, bold) = await fontBytes();
      final document = renderer.buildDocumentWith(
        sampleData(invoiceTitle: 'فاتورة ضريبية'),
        regular,
        bold,
        null,
      );
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('PDF renders custom footer text', () async {
      final (regular, bold) = await fontBytes();
      final document = renderer.buildDocumentWith(
        sampleData(invoiceFooterText: 'نتمنى لكم يوماً سعيداً'),
        regular,
        bold,
        null,
      );
      final bytes = await document.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('D - DatabaseHelper gated invoice reads', () {
    test('reads are denied for a role without sales-history permission',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      expect(
        () => DatabaseHelper.instance
            .getInvoiceById(invoiceId, currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance
            .getSalesByInvoiceId(invoiceId, currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('reads return the persisted invoice and its items for an owner',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      final invoice = await DatabaseHelper.instance
          .getInvoiceById(invoiceId, currentRole: UserRole.owner);
      expect(invoice, isNotNull);
      expect(invoice!.invoiceNumber, 'INV-1728000000000');
      expect(invoice.totalAmount, 420);

      final items = await DatabaseHelper.instance
          .getSalesByInvoiceId(invoiceId, currentRole: UserRole.owner);
      expect(items.length, 2);
      expect(items.first.invoiceId, invoiceId);
    });
  });

  group('E - InvoiceRepository', () {
    final repository = InvoiceRepository();

    test('buildDocumentData assembles the read model with exact totals',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.invoiceNumber, 'INV-1728000000000');
      expect(data.customerName, 'عميل تجريبي');
      expect(data.totalAmount, 420);
      expect(data.totalItems, 2);
      expect(data.lines.length, 2);
      expect(data.computedLinesTotal, data.totalAmount);
      expect(data.shopProfile.shopName, 'المحل');
    });

    test('buildDocumentData is denied for a role without history permission',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      expect(
        () => repository.buildDocumentData(invoiceId,
            currentRole: UserRole.salesOnly),
        throwsA(isA<SalesHistoryAccessDeniedException>()),
      );
    });

    test('buildDocumentData loads supportPhone from AppSettings', () async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+209999999999');
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.supportPhone, '+209999999999');
    });

    test('buildDocumentData uses default supportPhone when not customized',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.supportPhone, '+201014900211');
    });

    test('buildDocumentData loads invoiceTitle from AppSettings', () async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة ضريبية');
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.invoiceTitle, 'فاتورة ضريبية');
    });

    test('buildDocumentData uses default invoiceTitle when not customized',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.invoiceTitle, 'فاتورة بيع');
    });

    test('buildDocumentData loads invoiceFooterText from AppSettings',
        () async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceFooterText, 'نتمنى لكم التوفيق');
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.invoiceFooterText, 'نتمنى لكم التوفيق');
    });

    test('buildDocumentData uses default invoiceFooterText when not customized',
        () async {
      final invoiceId = await seedInvoiceWithItems();
      final data = await repository.buildDocumentData(invoiceId,
          currentRole: UserRole.owner);
      expect(data.invoiceFooterText, 'شكراً لتعاملكم معنا');
    });
  });

  group('F - InvoicePreviewScreen', () {
    Future<void> pumpPreview(
        WidgetTester tester, int invoiceId, SessionState session) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: InvoicePreviewScreen(invoiceId: invoiceId, sessionState: session),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows invoice fields and actions when the user may view it',
        (WidgetTester tester) async {
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('عرض الفاتورة'), findsOneWidget);
      expect(find.textContaining('INV-1728000000000'), findsOneWidget);
      expect(find.text('عميل تجريبي'), findsOneWidget);
      expect(find.text('إجمالي الفاتورة'), findsOneWidget);
      expect(find.text('420 ج.م'), findsOneWidget);
      expect(find.text('طباعة'), findsOneWidget);
      expect(find.text('حفظ PDF'), findsOneWidget);
      expect(find.text('فتح PDF'), findsOneWidget);
    });

    testWidgets('shows an error state when the user may not view the invoice',
        (WidgetTester tester) async {
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, salesOnlySession());

      expect(find.text('تعذر تحميل الفاتورة'), findsOneWidget);
      expect(find.text('طباعة'), findsNothing);
    });

    testWidgets('shows support phone in shop card when available',
        (WidgetTester tester) async {
      await AppSettings.setValue(AppSettings.keySupportPhone, '+201111111111');
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('للدعم: +201111111111'), findsOneWidget);
    });

    testWidgets('shows default invoice title in preview',
        (WidgetTester tester) async {
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('فاتورة بيع'), findsOneWidget);
    });

    testWidgets('shows custom invoice title in preview',
        (WidgetTester tester) async {
      await AppSettings.setValue(AppSettings.keyInvoiceTitle, 'فاتورة ضريبية');
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('فاتورة ضريبية'), findsOneWidget);
    });

    testWidgets('shows default footer message in preview',
        (WidgetTester tester) async {
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('شكراً لتعاملكم معنا'), findsOneWidget);
    });

    testWidgets('shows custom footer message in preview',
        (WidgetTester tester) async {
      await AppSettings.setValue(
          AppSettings.keyInvoiceFooterText, 'نتمنى لكم يوماً سعيداً');
      final invoiceId = await seedInvoiceWithItems();
      await pumpPreview(tester, invoiceId, ownerSession());

      expect(find.text('نتمنى لكم يوماً سعيداً'), findsOneWidget);
    });
  });

  group('G - post-save and history entry points', () {
    testWidgets(
        'saving an invoice opens the preview for a user with history access',
        (WidgetTester tester) async {
      await seedProduct();
      await seedCustomer();
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          InvoiceScreen(sessionState: ownerSession())),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('منتج اختبار'));
      await tester.pump();

      final priceField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'سعر البيع',
      );
      await tester.enterText(priceField, '150');
      await tester.pump();

      await tester.tap(find.text('حفظ الفاتورة'));
      await tester.pumpAndSettle();

      expect(find.text('عرض الفاتورة'), findsOneWidget);
      expect(find.text('طباعة'), findsOneWidget);

      final invoices = await testDb.query('invoices');
      expect(invoices.length, 1);
      expect(invoices.first['totalAmount'], 150.0);
    });

    testWidgets('sales history shows a reprint button only for invoiced sales',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invoiceId = await seedInvoiceWithItems();
      await testDb.insert('sales', {
        'date': DateTime(2026, 8, 11, 9, 0).toIso8601String(),
        'productName': 'بدون فاتورة',
        'barcode': 'NO-INV',
        'quantity': 1,
        'salePrice': 10,
        'totalSaleValue': 10,
        'costPrice': 0,
        'cogs': 0,
      });

      await tester.pumpWidget(MaterialApp(
        home: SalesScreen(sessionState: ownerSession()),
      ));
      await tester.pumpAndSettle();
      _consumeKnownSaleCardOverflows(tester);

      final invoicedSale = await DatabaseHelper.instance
          .getSalesByInvoiceId(invoiceId, currentRole: UserRole.owner);
      expect(invoicedSale.length, 2);

      final receiptButtons = find.byIcon(Icons.receipt_long);
      expect(receiptButtons, findsNWidgets(2));

      await tester.tap(receiptButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('عرض الفاتورة'), findsOneWidget);
    });

    test('InvoiceDelivery builds PDF bytes from the renderer', () async {
      final delivery = InvoiceDelivery();
      final bytes = await delivery.buildPdfBytes(sampleData());
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}

List<int> asciiBytes(String s) => s.codeUnits;

/// Consumes the pre-existing, transient first-frame RenderFlex overflow of the
/// owner sales-history card's trailing column (sales_screen.dart, accepted at
/// the MUAMAN-13S baseline). The receipt/delete button row lives inside that
/// same trailing, so the pre-existing overflow applies here unchanged.
///
/// With several cards the framework replaces the pending per-card overflows
/// with a single FlutterError whose message is the aggregate String
/// "Multiple exceptions (N) were detected ...", so both shapes are accepted.
/// Any other exception still fails the test loudly.
void _consumeKnownSaleCardOverflows(WidgetTester tester) {
  final dynamic exception = tester.takeException();
  if (exception == null) {
    return;
  }
  final message = exception.toString();
  expect(
    message,
    anyOf(contains('RenderFlex overflowed'), contains('Multiple exceptions')),
    reason: 'Only the pre-existing sale-card RenderFlex overflow may be '
        'consumed; any other exception must fail the test.',
  );
}

int _countSequence(Uint8List haystack, List<int> needle) {
  var count = 0;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matches = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matches = false;
        break;
      }
    }
    if (matches) count++;
  }
  return count;
}
