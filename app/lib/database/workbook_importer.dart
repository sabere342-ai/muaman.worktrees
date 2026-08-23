import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../import/workbook_source.dart';
import '../import/workbook_validation.dart';
import '../services/active_shop_context.dart';
import 'database_helper.dart';
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

/// Phase N (N-D12): duplicate-content detection carrying the original
/// import timestamp for the DUPLICATE_DETECTED terminal state.
class WorkbookDuplicateException extends WorkbookValidationException {
  final DateTime originalImportedAt;

  WorkbookDuplicateException(this.originalImportedAt)
      : super(WorkbookErrorCode.duplicateImport, '');

  @override
  String get userMessage =>
      'تم استيراد هذا الملف مسبقًا في $originalImportedAt';
}

class WorkbookImportException implements Exception {
  final String message;
  WorkbookImportException(this.message);
  @override
  String toString() => 'WorkbookImportException: $message';
}

// ======================= PREVIEW MODEL (N-D08/D09) ========================

/// Max row-level error samples surfaced in preview (N-D08/N-T11).
const int maxPreviewRowErrorSamples = 50;

class WorkbookPreviewIssue {
  final WorkbookSeverity severity;
  final String message;

  const WorkbookPreviewIssue(this.severity, this.message);
}

/// Pure observational preview over parsed sheets. Structurally incapable of
/// DB mutation (N-D08): no Database parameter exists anywhere in [buildPreview].
class WorkbookPreview {
  final int products;
  final int sales;
  final int returns;
  final int expenses;
  final int adjustments;

  /// Legacy skip-rule tallies (rows that will NOT be imported).
  final int skippedShortRows;
  final int skippedMissingIdentity;
  final int noteRows;

  final List<WorkbookPreviewIssue> warnings;
  final List<WorkbookPreviewIssue> blockingErrors;
  final List<String> rowErrorSamples;
  final int totalRowErrors;

  final bool hasZeroCostProduct;
  final String? zeroCostProductName;
  final String? zeroCostBarcode;

  const WorkbookPreview({
    required this.products,
    required this.sales,
    required this.returns,
    required this.expenses,
    required this.adjustments,
    required this.skippedShortRows,
    required this.skippedMissingIdentity,
    required this.noteRows,
    required this.warnings,
    required this.blockingErrors,
    required this.rowErrorSamples,
    required this.totalRowErrors,
    required this.hasZeroCostProduct,
    this.zeroCostProductName,
    this.zeroCostBarcode,
  });

  ImportCounts get counts => ImportCounts(
        products: products,
        sales: sales,
        returns: returns,
        expenses: expenses,
        adjustments: adjustments,
      );

  bool get hasBlockingErrors => blockingErrors.isNotEmpty;

  /// Zero-cost presence requires an explicit acknowledgement before confirm.
  bool get requiresZeroCostAcknowledgement => hasZeroCostProduct;
}

/// Builds the observational preview with EXACTLY the same skip/accept rules
/// as [_applyImport], so preview counts can never diverge from committed
/// counts (N-T05).
WorkbookPreview buildPreview(Map<String, XlsxSheetData> sheets) {
  var products = 0;
  var sales = 0;
  var returns = 0;
  var expenses = 0;
  var adjustments = 0;
  var skippedShortRows = 0;
  var skippedMissingIdentity = 0;
  var noteRows = 0;
  final warnings = <WorkbookPreviewIssue>[];
  final blockingErrors = <WorkbookPreviewIssue>[];
  final rowErrorSamples = <String>[];
  var totalRowErrors = 0;
  var hasZeroCostProduct = false;
  String? zeroCostName;
  String? zeroCostBarcode;
  final seenBarcodes = <String>{};
  var duplicateBarcodeCount = 0;

  void addRowError(String message) {
    totalRowErrors++;
    if (rowErrorSamples.length < maxPreviewRowErrorSamples) {
      rowErrorSamples.add(message);
    }
  }

  for (final name in WorkbookImporter.expectedSheets) {
    if (!sheets.containsKey(name)) {
      blockingErrors.add(WorkbookPreviewIssue(
        WorkbookSeverity.blocking,
        'الورقة المطلوبة "$name" غير موجودة',
      ));
    }
  }
  if (blockingErrors.isNotEmpty) {
    return WorkbookPreview(
      products: 0,
      sales: 0,
      returns: 0,
      expenses: 0,
      adjustments: 0,
      skippedShortRows: 0,
      skippedMissingIdentity: 0,
      noteRows: 0,
      warnings: const [],
      blockingErrors: blockingErrors,
      rowErrorSamples: const [],
      totalRowErrors: 0,
      hasZeroCostProduct: false,
    );
  }

  final store = sheets['المخزن']!;
  for (int i = 1; i < store.rows.length; i++) {
    final row = store.rows[i];
    if (row.length < 8) {
      skippedShortRows++;
      continue;
    }
    final name = row[1];
    final barcode = row[2];
    if (name == null || name.isEmpty || name == 'ملاحظة') {
      noteRows++;
      continue;
    }
    if (barcode == null || barcode.isEmpty) {
      skippedMissingIdentity++;
      continue;
    }
    final normalized = barcode.trim();
    if (!seenBarcodes.add(normalized)) duplicateBarcodeCount++;

    final costStr = row[7] ?? '0';
    final cost = double.tryParse(costStr);
    if (cost == null) {
      addRowError('المخزن صف ${i + 1}: قيمة تكلفة غير رقمية "$costStr"');
      continue;
    }
    if (cost == 0 && name != 'تحزية') {
      warnings.add(WorkbookPreviewIssue(
        WorkbookSeverity.warning,
        'المنتج "$name" (باركود $barcode) له سعر تكلفة صفري',
      ));
      continue;
    }
    if (cost == 0 && name == 'تحزية') {
      hasZeroCostProduct = true;
      zeroCostName = name;
      zeroCostBarcode = barcode;
    }
    products++;
  }

  final salesSheet = sheets['المبيعات']!;
  for (int i = 1; i < salesSheet.rows.length; i++) {
    final row = salesSheet.rows[i];
    if (row.length < 9) {
      skippedShortRows++;
      continue;
    }
    final name = row[2];
    if (name == null || name.isEmpty) {
      skippedMissingIdentity++;
      continue;
    }
    if (name == 'الإجمالي') break;
    final qtyStr = row[4] ?? '0';
    final priceStr = row[5] ?? '0';
    final qty = int.tryParse(qtyStr);
    final price = double.tryParse(priceStr);
    if (qty == null || price == null) {
      addRowError('المبيعات صف ${i + 1}: قيمة عدد/سعر غير رقمية');
      continue;
    }
    if (qty <= 0 || price <= 0) {
      skippedMissingIdentity++;
      continue;
    }
    sales++;
  }

  final returnsSheet = sheets['المرتجعات']!;
  for (int i = 1; i < returnsSheet.rows.length; i++) {
    final row = returnsSheet.rows[i];
    if (row.length < 9) {
      skippedShortRows++;
      continue;
    }
    final name = row[2];
    if (name == null || name.isEmpty) {
      skippedMissingIdentity++;
      continue;
    }
    if (name == 'الإجمالي') break;
    final qtyStr = row[4] ?? '0';
    final priceStr = row[5] ?? '0';
    final qty = int.tryParse(qtyStr);
    final price = double.tryParse(priceStr);
    if (qty == null || price == null) {
      addRowError('المرتجعات صف ${i + 1}: قيمة عدد/سعر غير رقمية');
      continue;
    }
    if (qty <= 0 || price <= 0) {
      skippedMissingIdentity++;
      continue;
    }
    returns++;
  }

  final expensesSheet = sheets['المصروفات']!;
  for (int i = 1; i < expensesSheet.rows.length; i++) {
    final row = expensesSheet.rows[i];
    if (row.length < 4) {
      skippedShortRows++;
      continue;
    }
    final desc = row[2];
    if (desc == null || desc.isEmpty) {
      skippedMissingIdentity++;
      continue;
    }
    if (desc == 'الإجمالي') break;
    final amountStr = row[3] ?? '0';
    if (double.tryParse(amountStr) == null) {
      addRowError('المصروفات صف ${i + 1}: قيمة مبلغ غير رقمية "$amountStr"');
      continue;
    }
    expenses++;
  }

  final adjustSheet = sheets['الجرد']!;
  for (int i = 1; i < adjustSheet.rows.length; i++) {
    final row = adjustSheet.rows[i];
    if (row.length < 5) {
      skippedShortRows++;
      continue;
    }
    final name = row[1];
    if (name == null || name.isEmpty) {
      skippedMissingIdentity++;
      continue;
    }
    if (name == 'ملاحظة') break;
    final actualQtyStr = row[4] ?? '0';
    if (int.tryParse(actualQtyStr) == null) {
      addRowError('الجرد صف ${i + 1}: قيمة كمية غير رقمية "$actualQtyStr"');
      continue;
    }
    adjustments++;
  }

  if (duplicateBarcodeCount > 0) {
    warnings.add(WorkbookPreviewIssue(
      WorkbookSeverity.info,
      'عدد الباركودات المكررة في المخزن: $duplicateBarcodeCount',
    ));
  }

  return WorkbookPreview(
    products: products,
    sales: sales,
    returns: returns,
    expenses: expenses,
    adjustments: adjustments,
    skippedShortRows: skippedShortRows,
    skippedMissingIdentity: skippedMissingIdentity,
    noteRows: noteRows,
    warnings: warnings,
    blockingErrors: blockingErrors,
    rowErrorSamples: rowErrorSamples,
    totalRowErrors: totalRowErrors,
    hasZeroCostProduct: hasZeroCostProduct,
    zeroCostProductName: zeroCostName,
    zeroCostBarcode: zeroCostBarcode,
  );
}

/// Observational pre-import preparation (§20.10): validation + hash +
/// duplicate probe + preview. Performs ZERO writes.
class WorkbookPreparation {
  final String fileSha256;
  final String fileName;
  final WorkbookPreview preview;

  const WorkbookPreparation({
    required this.fileSha256,
    required this.fileName,
    required this.preview,
  });
}

class _ApplyResult {
  final ReconciliationReport report;
  final int batchId;
  _ApplyResult(this.report, this.batchId);
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

  /// Single atomic transaction (N-D10/N-D13): business rows + optional sync
  /// queue rows + the import_batches row ALL commit or ALL roll back together.
  static Future<_ApplyResult> _applyImport(
    Map<String, XlsxSheetData> sheets,
    Database db,
    String shopId, {
    required String fileSha256,
    required String fileName,
    required bool enqueueSync,
    @visibleForTesting Future<void> Function()? debugFailurePoint,
  }) async {
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

    int batchId = -1;

    final helper = enqueueSync ? DatabaseHelper.instance : null;

    await db.transaction((txn) async {
      Future<void> enqueue(String tableName, int rowId) async {
        await helper!.enqueueImportedRowForSync(db, txn,
            tableName: tableName, rowId: rowId);
      }

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

        final productId = await txn.insert('products', {
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
        if (helper != null) await enqueue('products', productId);

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

        final saleId = await txn.insert('sales', {
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
        if (helper != null) await enqueue('sales', saleId);

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

        final returnId = await txn.insert('returns', {
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
        if (helper != null) await enqueue('returns', returnId);

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

        final expenseId = await txn.insert('expenses', {
          'shop_id': shopId,
          'date': expDate.toIso8601String(),
          'description': _normalize(desc),
          'amount': amount,
        });
        if (helper != null) await enqueue('expenses', expenseId);

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
          final countId = await txn.insert('inventory_count', {
            'shop_id': shopId,
            'productId': productId,
            'actualQuantity': actualQty,
            'notes': notes,
            'countDate': DateTime.now().toIso8601String(),
          });
          if (helper != null) await enqueue('inventory_count', countId);
        }

        adjustmentsImported++;
      }

      // Test hook (N-T14): injected late failure must roll back EVERYTHING
      // above together with the batch row inserted right below it.
      if (debugFailurePoint != null) {
        await debugFailurePoint();
      }

      // N-D10: the batch record is part of the SAME transaction — a
      // successful import can never exist without its batch row.
      batchId = await txn.insert('import_batches', {
        'shop_id': shopId,
        'file_sha256': fileSha256,
        'file_name': fileName,
        'imported_at': DateTime.now().toIso8601String(),
        'products_count': productsImported,
        'sales_count': salesImported,
        'returns_count': returnsImported,
        'expenses_count': expensesImported,
        'adjustments_count': adjustmentsImported,
        'total_quantity': totalQuantity,
        'total_inventory_value': totalInventoryValue,
        'total_sales': totalSalesValue,
        'total_returns': totalReturnsValue,
        'net_sales': totalSalesValue - totalReturnsValue,
        'total_cogs': totalCogsValue,
        'returned_cogs': totalReturnedCogsValue,
        'net_cogs': totalCogsValue - totalReturnedCogsValue,
        'gross_profit': (totalSalesValue - totalReturnsValue) -
            (totalCogsValue - totalReturnedCogsValue),
        'total_expenses': totalExpensesValue,
        'net_profit': (totalSalesValue - totalReturnsValue) -
            (totalCogsValue - totalReturnedCogsValue) -
            totalExpensesValue,
        'reconciliation_json': jsonEncode(_buildReport(
          productsImported: productsImported,
          salesImported: salesImported,
          returnsImported: returnsImported,
          expensesImported: expensesImported,
          adjustmentsImported: adjustmentsImported,
          totalQuantity: totalQuantity,
          totalInventoryValue: totalInventoryValue,
          totalSalesValue: totalSalesValue,
          totalCogsValue: totalCogsValue,
          totalReturnsValue: totalReturnsValue,
          totalReturnedCogsValue: totalReturnedCogsValue,
          totalExpensesValue: totalExpensesValue,
        ).toJson()),
      });
    });

    final report = _buildReport(
      productsImported: productsImported,
      salesImported: salesImported,
      returnsImported: returnsImported,
      expensesImported: expensesImported,
      adjustmentsImported: adjustmentsImported,
      totalQuantity: totalQuantity,
      totalInventoryValue: totalInventoryValue,
      totalSalesValue: totalSalesValue,
      totalCogsValue: totalCogsValue,
      totalReturnsValue: totalReturnsValue,
      totalReturnedCogsValue: totalReturnedCogsValue,
      totalExpensesValue: totalExpensesValue,
    );

    return _ApplyResult(report, batchId);
  }

  static ReconciliationReport _buildReport({
    required int productsImported,
    required int salesImported,
    required int returnsImported,
    required int expensesImported,
    required int adjustmentsImported,
    required int totalQuantity,
    required double totalInventoryValue,
    required double totalSalesValue,
    required double totalCogsValue,
    required double totalReturnsValue,
    required double totalReturnedCogsValue,
    required double totalExpensesValue,
  }) {
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

  // ===================== SHARED CORE (hash-once, §20.12) ===================

  static Uint8List _readBytes(PickedWorkbook workbook) {
    try {
      return File(workbook.path).readAsBytesSync();
    } catch (_) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.accessError,
        'تعذر قراءة الملف',
      );
    }
  }

  static Map<String, dynamic>? _findDuplicateBatch(
      List<Map<String, Object?>> batchRows) {
    if (batchRows.isEmpty) return null;
    return batchRows.first;
  }

  /// Observational preparation (validate → hash → dedup probe → preview).
  /// Throws typed [WorkbookValidationException]s on invalid input; NEVER
  /// touches the database with writes (N-T12).
  static Future<WorkbookPreparation> prepareFromSource({
    required PickedWorkbook workbook,
    required Database db,
  }) async {
    validateWorkbookSelection(workbook);
    final bytes = _readBytes(workbook);
    validateWorkbookBytes(bytes.length);

    final sha = sha256.convert(bytes).toString().toLowerCase();

    final dup = _findDuplicateBatch(await db
        .query('import_batches', where: 'file_sha256 = ?', whereArgs: [sha]));
    if (dup != null) {
      throw WorkbookDuplicateException(
          DateTime.parse(dup['imported_at'] as String));
    }

    final sheets = XlsxReader.readBytes(bytes);
    final preview = buildPreview(sheets);

    return WorkbookPreparation(
      fileSha256: sha,
      fileName: workbook.fileName,
      preview: preview,
    );
  }

  /// New UI entry point (N-D17 envelope). Terminal states:
  /// SUCCEEDED / FAILED_ROLLED_BACK / DUPLICATE_DETECTED / INVALID.
  static Future<WorkbookImportOutcome> importFromSource({
    required PickedWorkbook workbook,
    required Database db,
    bool allowZeroCost = false,
    bool enqueueSync = true,
    String? shopId,
    @visibleForTesting Future<void> Function()? debugFailurePoint,
  }) async {
    try {
      final effectiveShopId = shopId ?? ActiveShopContext.instance.shopId;
      if (effectiveShopId == null || effectiveShopId.isEmpty) {
        throw const WorkbookValidationException(
          WorkbookErrorCode.validationFailure,
          'لا يمكن الاستيراد بدون متجر نشط مرتبط بالسحابة',
        );
      }

      validateWorkbookSelection(workbook);
      final bytes = _readBytes(workbook);
      validateWorkbookBytes(bytes.length);

      final sha = sha256.convert(bytes).toString().toLowerCase();

      final dup = _findDuplicateBatch(await db
          .query('import_batches', where: 'file_sha256 = ?', whereArgs: [sha]));
      if (dup != null) {
        return WorkbookImportOutcome(
          status: WorkbookImportStatus.duplicateDetected,
          fileSha256: sha,
          fileName: workbook.fileName,
          originalImportedAt: DateTime.parse(dup['imported_at'] as String),
          errors: [],
        );
      }

      final sheets = XlsxReader.readBytes(bytes);
      final preflightResult = preflight(sheets, allowZeroCost: allowZeroCost);
      if (!preflightResult.isValid) {
        return WorkbookImportOutcome(
          status: WorkbookImportStatus.invalid,
          fileSha256: sha,
          fileName: workbook.fileName,
          errors: preflightResult.errors,
        );
      }

      final result = await _applyImport(
        sheets,
        db,
        effectiveShopId,
        fileSha256: sha,
        fileName: workbook.fileName,
        enqueueSync: enqueueSync,
        debugFailurePoint: debugFailurePoint,
      );

      return WorkbookImportOutcome(
        status: WorkbookImportStatus.succeeded,
        fileSha256: sha,
        fileName: workbook.fileName,
        batchId: result.batchId,
        counts: ImportCounts(
          products: result.report.productsImported,
          sales: result.report.salesImported,
          returns: result.report.returnsImported,
          expenses: result.report.expensesImported,
          adjustments: result.report.adjustmentsImported,
        ),
      );
    } on WorkbookValidationException catch (e) {
      return WorkbookImportOutcome(
        status: WorkbookImportStatus.invalid,
        fileSha256: '',
        fileName: workbook.fileName,
        // All messages thrown by this module are curated Arabic strings;
        // raw parser internals never reach this layer (§20.18).
        errors: [e.message],
        rolledBack: e.code == WorkbookErrorCode.databaseFailure ||
            e.code == WorkbookErrorCode.rollbackFailure,
      );
    } catch (_) {
      // Transaction-scope failures: SQLite guarantees full rollback of the
      // single transaction (N-D19 honesty — local rollback only).
      return WorkbookImportOutcome(
        status: WorkbookImportStatus.failedRolledBack,
        fileSha256: '',
        fileName: workbook.fileName,
        rolledBack: true,
        errors: [WorkbookErrorCode.databaseFailure.userMessage],
      );
    }
  }

  /// Legacy entry point (kept for existing tests/callers, N-D15). The new UI
  /// flow never routes through [skipShaCheck]/pinned-hash semantics.
  ///
  /// [enqueueSync] defaults to FALSE here so legacy callers keep the old
  /// no-queue behavior exactly (N-D13 backward compatibility).
  static Future<ReconciliationReport> import({
    required String workbookPath,
    required Database db,
    bool allowZeroCost = false,
    bool skipShaCheck = true,
    String? expectedSha256,
    String? shopId,
    bool enqueueSync = false,
  }) async {
    final effectiveShopId = shopId ?? ActiveShopContext.instance.shopId;
    if (effectiveShopId == null || effectiveShopId.isEmpty) {
      throw WorkbookImportException(
          'لا يمكن الاستيراد بدون متجر نشط مرتبط بالسحابة');
    }

    if (!File(workbookPath).existsSync()) {
      throw WorkbookImportException('ملف الوردبوك غير موجود: $workbookPath');
    }

    final fileName = File(workbookPath).uri.pathSegments.last;

    final picked = PickedWorkbook(
      path: workbookPath,
      fileName: fileName,
      sizeBytes: File(workbookPath).lengthSync(),
    );

    try {
      validateWorkbookSelection(picked);
    } on WorkbookValidationException catch (e) {
      throw WorkbookImportException(e.message);
    }

    final bytes = File(workbookPath).readAsBytesSync();

    final actualSha = sha256.convert(bytes).toString().toLowerCase();
    if (!skipShaCheck) {
      final expected = expectedSha256 ?? WorkbookImporter.expectedSha256;
      if (actualSha != expected) {
        throw WorkbookImportException(
          'توقيع الملف غير متطابق. المتوقع: $expected، الفعلي: $actualSha',
        );
      }
    }

    final dup = _findDuplicateBatch(await db.query('import_batches',
        where: 'file_sha256 = ?', whereArgs: [actualSha]));
    if (dup != null) {
      throw WorkbookImportException(
        'تم استيراد هذا الملف مسبقًا في ${dup['imported_at']}',
      );
    }

    final Uint8List sheetsBytes = bytes;
    final sheets = XlsxReader.readBytes(sheetsBytes);

    final preflightResult = preflight(sheets, allowZeroCost: allowZeroCost);
    if (!preflightResult.isValid) {
      throw WorkbookImportException(preflightResult.errors.join('\n'));
    }

    final result = await _applyImport(
      sheets,
      db,
      effectiveShopId,
      fileSha256: actualSha,
      fileName: fileName,
      enqueueSync: enqueueSync,
    );

    return result.report;
  }
}
