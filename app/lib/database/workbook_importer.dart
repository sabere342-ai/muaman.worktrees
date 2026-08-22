import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../services/active_shop_context.dart';
import 'xlsx_reader.dart';

class ReconciliationReport {
  final int productsImported;
  final int salesImported;
  final int returnsImported;
  final int expensesImported;
  final int adjustmentsImported;
  final int totalQuantity;
  final double totalInventoryValue;
  final double totalSales;
  final double totalReturns;
  final double netSales;
  final double totalCogs;
  final double returnedCogs;
  final double netCogs;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;

  ReconciliationReport({
    required this.productsImported,
    required this.salesImported,
    required this.returnsImported,
    required this.expensesImported,
    required this.adjustmentsImported,
    required this.totalQuantity,
    required this.totalInventoryValue,
    required this.totalSales,
    required this.totalReturns,
    required this.netSales,
    required this.totalCogs,
    required this.returnedCogs,
    required this.netCogs,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
  });

  Map<String, dynamic> toJson() => {
        'productsImported': productsImported,
        'salesImported': salesImported,
        'returnsImported': returnsImported,
        'expensesImported': expensesImported,
        'adjustmentsImported': adjustmentsImported,
        'totalQuantity': totalQuantity,
        'totalInventoryValue': totalInventoryValue,
        'totalSales': totalSales,
        'totalReturns': totalReturns,
        'netSales': netSales,
        'totalCogs': totalCogs,
        'returnedCogs': returnedCogs,
        'netCogs': netCogs,
        'grossProfit': grossProfit,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
      };
}

class PreflightResult {
  final List<String> errors;
  final bool hasZeroCostProduct;
  final String? zeroCostProductName;
  final String? zeroCostBarcode;

  PreflightResult({
    required this.errors,
    required this.hasZeroCostProduct,
    this.zeroCostProductName,
    this.zeroCostBarcode,
  });

  bool get isValid => errors.isEmpty;
}

class WorkbookImportException implements Exception {
  final String message;
  WorkbookImportException(this.message);
  @override
  String toString() => 'WorkbookImportException: $message';
}

class WorkbookImporter {
  static const String expectedSha256 =
      'e16c3b7ca089a2cc82fee383c514cc061eb0223e44d7ac1b766807fd28ae47c4';

  static const List<String> expectedSheets = [
    'لوحة التحكم',
    'المخزن',
    'الجرد',
    'المبيعات',
    'المرتجعات',
    'المصروفات',
  ];

  static String _fileSha256(String path) {
    final bytes = File(path).readAsBytesSync();
    return sha256.convert(bytes).toString().toLowerCase();
  }

  static String _normalize(String s) {
    return s.trim();
  }

  static DateTime _serialDateToDateTime(String serial) {
    final days = int.tryParse(serial);
    if (days == null) return DateTime.now();
    return DateTime(1899, 12, 30).add(Duration(days: days));
  }

  static PreflightResult preflight(Map<String, XlsxSheetData> sheets,
      {bool allowZeroCost = false}) {
    final errors = <String>[];

    for (final name in expectedSheets) {
      if (!sheets.containsKey(name)) {
        errors.add('الورقة المطلوبة "$name" غير موجودة');
      }
    }

    if (errors.isNotEmpty) {
      return PreflightResult(
        errors: errors,
        hasZeroCostProduct: false,
      );
    }

    final store = sheets['المخزن']!;
    String? zeroCostName;
    String? zeroCostBarcode;

    for (int i = 1; i < store.rows.length; i++) {
      final row = store.rows[i];
      if (row.length < 8) continue;
      final name = row[1];
      final barcode = row[2];
      if (name == null || name.isEmpty || name == 'ملاحظة') continue;
      if (barcode == null || barcode.isEmpty) continue;

      final costStr = row[7] ?? '0';
      final cost = double.tryParse(costStr) ?? 0;
      if (cost == 0 && name != 'تحزية') {
        errors.add('المنتج "$name" (باركود $barcode) له سعر تكلفة صفري');
      }
      if (cost == 0 && name == 'تحزية') {
        zeroCostName = name;
        zeroCostBarcode = barcode;
      }
    }

    if (zeroCostName != null && !allowZeroCost) {
      errors.add(
        'المنتج "$zeroCostName" (باركود $zeroCostBarcode) له سعر تكلفة صفري. '
        'يجب تأكيد السماح بالاستيراد مع منتج بتكلفة صفرية.',
      );
    }

    return PreflightResult(
      errors: errors,
      hasZeroCostProduct: zeroCostName != null,
      zeroCostProductName: zeroCostName,
      zeroCostBarcode: zeroCostBarcode,
    );
  }

  static Future<ReconciliationReport> _applyImport(
      Map<String, XlsxSheetData> sheets, Database db, String shopId) async {
    final store = sheets['المخزن']!;
    final salesSheet = sheets['المبيعات']!;
    final returnsSheet = sheets['المرتجعات']!;
    final expensesSheet = sheets['المصروفات']!;
    final adjustSheet = sheets['الجرد']!;

    int productsImported = 0;
    int salesImported = 0;
    int returnsImported = 0;
    int expensesImported = 0;
    int adjustmentsImported = 0;

    double totalSalesValue = 0;
    double totalCogsValue = 0;
    double totalReturnsValue = 0;
    double totalReturnedCogsValue = 0;
    double totalExpensesValue = 0;
    int totalQuantity = 0;
    double totalInventoryValue = 0;

    await db.transaction((txn) async {
      for (int i = 1; i < store.rows.length; i++) {
        final row = store.rows[i];
        if (row.length < 10) continue;
        final name = row[1];
        final barcode = row[2];
        if (name == null || name.isEmpty || name == 'ملاحظة') continue;
        if (barcode == null || barcode.isEmpty) continue;

        final openingStr = row[3] ?? '0';
        final soldStr = row[4] ?? '0';
        final returnedStr = row[5] ?? '0';
        final currentStr = row[6] ?? '0';
        final costStr = row[7] ?? '0';
        final adjustStr = row[9] ?? '0';

        final opening = int.tryParse(openingStr) ?? 0;
        final currentQty = int.tryParse(currentStr) ?? 0;
        final costPrice = double.tryParse(costStr) ?? 0;
        final adjustment = int.tryParse(adjustStr) ?? 0;

        final soldQty = int.tryParse(soldStr) ?? 0;
        final returnedQty = int.tryParse(returnedStr) ?? 0;

        if (costPrice <= 0 && name != 'تحزية') {
          continue;
        }

        final normalizedName = _normalize(name);
        final normalizedBarcode = _normalize(barcode);

        await txn.insert('products', {
          'shop_id': shopId,
          'name': normalizedName,
          'barcode': normalizedBarcode,
          'openingQuantity': opening,
          'soldQuantity': soldQty,
          'returnedQuantity': returnedQty,
          'currentQuantity': currentQty,
          'costPrice': costPrice,
          'totalInventoryCost': currentQty * costPrice,
          'inventoryAdjustment': adjustment,
        });

        productsImported++;
        totalQuantity += currentQty;
        totalInventoryValue += currentQty * costPrice;
      }

      for (int i = 1; i < salesSheet.rows.length; i++) {
        final row = salesSheet.rows[i];
        if (row.length < 9) continue;
        final name = row[2];
        if (name == null || name.isEmpty) continue;
        if (name == 'الإجمالي') break;

        final barcode = row[3] ?? '';
        final qtyStr = row[4] ?? '0';
        final priceStr = row[5] ?? '0';
        final costStr = row[7] ?? '0';

        final qty = int.tryParse(qtyStr) ?? 0;
        final price = double.tryParse(priceStr) ?? 0;
        final cost = double.tryParse(costStr) ?? 0;

        if (qty <= 0) continue;
        if (price <= 0) continue;

        final dateSerial = row[1];
        DateTime saleDate;
        if (dateSerial != null && dateSerial.isNotEmpty) {
          saleDate = _serialDateToDateTime(dateSerial);
        } else {
          saleDate = DateTime.now();
        }

        final totalValue = qty * price;
        final cogs = qty * cost;

        await txn.insert('sales', {
          'shop_id': shopId,
          'date': saleDate.toIso8601String(),
          'productName': _normalize(name),
          'barcode': _normalize(barcode),
          'quantity': qty,
          'salePrice': price,
          'totalSaleValue': totalValue,
          'costPrice': cost,
          'cogs': cogs,
        });

        salesImported++;
        totalSalesValue += totalValue;
        totalCogsValue += cogs;
      }

      for (int i = 1; i < returnsSheet.rows.length; i++) {
        final row = returnsSheet.rows[i];
        if (row.length < 9) continue;
        final name = row[2];
        if (name == null || name.isEmpty) continue;
        if (name == 'الإجمالي') break;

        final barcode = row[3] ?? '';
        final qtyStr = row[4] ?? '0';
        final priceStr = row[5] ?? '0';
        final costStr = row[7] ?? '0';

        final qty = int.tryParse(qtyStr) ?? 0;
        final price = double.tryParse(priceStr) ?? 0;
        final cost = double.tryParse(costStr) ?? 0;

        if (qty <= 0) continue;
        if (price <= 0) continue;

        final dateSerial = row[1];
        DateTime returnDate;
        if (dateSerial != null && dateSerial.isNotEmpty) {
          returnDate = _serialDateToDateTime(dateSerial);
        } else {
          returnDate = DateTime.now();
        }

        final totalValue = qty * price;
        final cogs = qty * cost;

        await txn.insert('returns', {
          'shop_id': shopId,
          'date': returnDate.toIso8601String(),
          'productName': _normalize(name),
          'barcode': _normalize(barcode),
          'quantity': qty,
          'salePrice': price,
          'totalReturnValue': totalValue,
          'costPrice': cost,
          'returnedCogs': cogs,
        });

        returnsImported++;
        totalReturnsValue += totalValue;
        totalReturnedCogsValue += cogs;
      }

      for (int i = 1; i < expensesSheet.rows.length; i++) {
        final row = expensesSheet.rows[i];
        if (row.length < 4) continue;
        final desc = row[2];
        if (desc == null || desc.isEmpty) continue;
        if (desc == 'الإجمالي') break;

        final amountStr = row[3] ?? '0';
        final amount = double.tryParse(amountStr) ?? 0;

        final dateSerial = row[1];
        DateTime expDate;
        if (dateSerial != null && dateSerial.isNotEmpty) {
          expDate = _serialDateToDateTime(dateSerial);
        } else {
          expDate = DateTime.now();
        }

        await txn.insert('expenses', {
          'shop_id': shopId,
          'date': expDate.toIso8601String(),
          'description': _normalize(desc),
          'amount': amount,
        });

        expensesImported++;
        totalExpensesValue += amount;
      }

      for (int i = 1; i < adjustSheet.rows.length; i++) {
        final row = adjustSheet.rows[i];
        if (row.length < 5) continue;
        final name = row[1];
        if (name == null || name.isEmpty) continue;
        if (name == 'ملاحظة') break;

        final barcode = row[2] ?? '';
        final actualQtyStr = row[4] ?? '0';
        final notes = row.length > 9 ? (row[9] ?? '') : '';

        final actualQty = int.tryParse(actualQtyStr) ?? 0;

        final productRows = await txn.query('products',
            where: 'barcode = ?', whereArgs: [_normalize(barcode)]);

        if (productRows.isNotEmpty) {
          final productId = productRows.first['id'] as int;
          await txn.insert('inventory_count', {
            'shop_id': shopId,
            'productId': productId,
            'actualQuantity': actualQty,
            'notes': notes,
            'countDate': DateTime.now().toIso8601String(),
          });
        }

        adjustmentsImported++;
      }
    });

    final netSales = totalSalesValue - totalReturnsValue;
    final netCogs = totalCogsValue - totalReturnedCogsValue;
    final grossProfit = netSales - netCogs;
    final netProfit = grossProfit - totalExpensesValue;

    return ReconciliationReport(
      productsImported: productsImported,
      salesImported: salesImported,
      returnsImported: returnsImported,
      expensesImported: expensesImported,
      adjustmentsImported: adjustmentsImported,
      totalQuantity: totalQuantity,
      totalInventoryValue: totalInventoryValue,
      totalSales: totalSalesValue,
      totalReturns: totalReturnsValue,
      netSales: netSales,
      totalCogs: totalCogsValue,
      returnedCogs: totalReturnedCogsValue,
      netCogs: netCogs,
      grossProfit: grossProfit,
      totalExpenses: totalExpensesValue,
      netProfit: netProfit,
    );
  }

  /// Imports a workbook. Every tenant row is stamped with the ACTIVE shop
  /// context (plan §P): an explicit [shopId] argument wins (trust boundaries),
  /// otherwise the bound [ActiveShopContext] is used. Importing with NO
  /// authorized shop context fails closed — imported data must never land as
  /// unattributed rows that strict filtering would hide.
  static Future<ReconciliationReport> import({
    required String workbookPath,
    required Database db,
    bool allowZeroCost = false,
    bool skipShaCheck = true,
    String? expectedSha256,
    String? shopId,
  }) async {
    final effectiveShopId =
        shopId ?? ActiveShopContext.instance.shopId;
    if (effectiveShopId == null || effectiveShopId.isEmpty) {
      throw WorkbookImportException(
          'لا يمكن الاستيراد بدون متجر نشط مرتبط بالسحابة');
    }

    if (!File(workbookPath).existsSync()) {
      throw WorkbookImportException('ملف الوردبوك غير موجود: $workbookPath');
    }

    final actualSha = _fileSha256(workbookPath);
    if (!skipShaCheck) {
      final expected = expectedSha256 ?? WorkbookImporter.expectedSha256;
      if (actualSha != expected) {
        throw WorkbookImportException(
          'توقيع الملف غير متطابق. المتوقع: $expected، الفعلي: $actualSha',
        );
      }
    }

    final batchRows = await db.query('import_batches',
        where: 'file_sha256 = ?', whereArgs: [actualSha]);
    if (batchRows.isNotEmpty) {
      throw WorkbookImportException(
        'تم استيراد هذا الملف مسبقًا في ${batchRows.first['imported_at']}',
      );
    }

    final sheets = XlsxReader.read(workbookPath);

    final preflightResult = preflight(sheets, allowZeroCost: allowZeroCost);
    if (!preflightResult.isValid) {
      throw WorkbookImportException(preflightResult.errors.join('\n'));
    }

    final report = await _applyImport(sheets, db, effectiveShopId);

    await db.insert('import_batches', {
      'shop_id': effectiveShopId,
      'file_sha256': actualSha,
      'file_name': File(workbookPath).uri.pathSegments.last,
      'imported_at': DateTime.now().toIso8601String(),
      'products_count': report.productsImported,
      'sales_count': report.salesImported,
      'returns_count': report.returnsImported,
      'expenses_count': report.expensesImported,
      'adjustments_count': report.adjustmentsImported,
      'total_quantity': report.totalQuantity,
      'total_inventory_value': report.totalInventoryValue,
      'total_sales': report.totalSales,
      'total_returns': report.totalReturns,
      'net_sales': report.netSales,
      'total_cogs': report.totalCogs,
      'returned_cogs': report.returnedCogs,
      'net_cogs': report.netCogs,
      'gross_profit': report.grossProfit,
      'total_expenses': report.totalExpenses,
      'net_profit': report.netProfit,
      'reconciliation_json': jsonEncode(report.toJson()),
    });

    return report;
  }
}
