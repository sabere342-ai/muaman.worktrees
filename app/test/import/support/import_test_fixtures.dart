import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Minimal XLSX builder for Phase N tests (N-D18 synthetic fixtures).
/// Cells are emitted as `t="str"` plain values, which the repository
/// XlsxReader reads directly — no sharedStrings needed.
Uint8List buildXlsxBytes(Map<String, List<List<String?>>> sheets) {
  final archive = Archive();

  void addEntry(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String colRef(int index) {
    var i = index;
    final sb = StringBuffer();
    while (i >= 0) {
      sb.write(String.fromCharCode(65 + (i % 26)));
      i = (i ~/ 26) - 1;
    }
    return sb.toString().split('').reversed.join();
  }

  final rels = StringBuffer();
  final sheetTags = StringBuffer();
  var sheetIndex = 0;
  sheets.forEach((name, rows) {
    sheetIndex++;
    final sheetXml = StringBuffer();
    sheetXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetData>');
    for (var r = 0; r < rows.length; r++) {
      sheetXml.write('<row r="${r + 1}">');
      final cells = rows[r];
      for (var c = 0; c < cells.length; c++) {
        if (cells[c] == null || cells[c]!.isEmpty) continue;
        sheetXml.write('<c r="${colRef(c)}${r + 1}" t="str">'
            '<v>${cells[c]!.replaceAll('&', '&amp;').replaceAll('<', '&lt;')}</v></c>');
      }
      sheetXml.write('</row>');
    }
    sheetXml.write('</sheetData></worksheet>');
    addEntry('xl/worksheets/sheet$sheetIndex.xml', sheetXml.toString());

    rels.write('<Relationship Id="rId$sheetIndex" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
        'relationships/worksheet" Target="worksheets/sheet$sheetIndex.xml"/>');
    final escapedName = name.replaceAll('&', '&amp;');
    sheetTags.write('<sheet name="$escapedName" sheetId="$sheetIndex" '
        'r:id="rId$sheetIndex"/>');
  });

  addEntry(
      'xl/workbook.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets>$sheetTags</sheets></workbook>');

  addEntry(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '$rels</Relationships>');

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// Path of the real repository workbook used by the legacy regression suite.
String repoWorkbookPath() {
  final repoRoot = Directory.current.parent.path;
  return path.join(repoRoot, 'app', 'شهر 8', 'شيت_ادارة_محل_مؤمن_شهر8.xlsx');
}

Future<Database> openImportTestDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      barcode TEXT UNIQUE NOT NULL,
      openingQuantity INTEGER DEFAULT 0,
      soldQuantity INTEGER DEFAULT 0,
      returnedQuantity INTEGER DEFAULT 0,
      currentQuantity INTEGER DEFAULT 0,
      costPrice REAL DEFAULT 0,
      totalInventoryCost REAL DEFAULT 0,
      inventoryAdjustment INTEGER DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoiceId INTEGER,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalSaleValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      cogs REAL DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE returns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalReturnValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      returnedCogs REAL DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL DEFAULT 0,
      category TEXT,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE import_batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_sha256 TEXT NOT NULL UNIQUE,
      file_name TEXT NOT NULL,
      imported_at TEXT NOT NULL,
      products_count INTEGER DEFAULT 0,
      sales_count INTEGER DEFAULT 0,
      returns_count INTEGER DEFAULT 0,
      expenses_count INTEGER DEFAULT 0,
      adjustments_count INTEGER DEFAULT 0,
      total_quantity INTEGER DEFAULT 0,
      total_inventory_value REAL DEFAULT 0,
      total_sales REAL DEFAULT 0,
      total_returns REAL DEFAULT 0,
      net_sales REAL DEFAULT 0,
      total_cogs REAL DEFAULT 0,
      returned_cogs REAL DEFAULT 0,
      net_cogs REAL DEFAULT 0,
      gross_profit REAL DEFAULT 0,
      total_expenses REAL DEFAULT 0,
      net_profit REAL DEFAULT 0,
      reconciliation_json TEXT,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id INTEGER NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT,
      created_at TEXT NOT NULL,
      synced_at TEXT,
      retry_count INTEGER DEFAULT 0,
      status TEXT DEFAULT 'PENDING',
      conflict_data TEXT,
      idempotency_key TEXT NOT NULL UNIQUE,
      shop_id TEXT,
      occurrence_token TEXT,
      resolution_status TEXT
    )
  ''');
  return db;
}

Map<String, List<List<String?>>> validSyntheticWorkbook() => {
      'لوحة التحكم': [
        [null, 'عنوان'],
      ],
      'المخزن': [
        [
          null,
          'الاسم',
          'الباركود',
          'افتتاحي',
          'بيع',
          'مرتجع',
          'الحالي',
          'التكلفة',
          null,
          'تعديل'
        ],
        [null, 'منتج أ', '100', '5', '2', '1', '4', '10', null, '0'],
        [null, 'منتج ب', '200', '3', '1', '0', '2', '20', null, '0'],
      ],
      'الجرد': [
        [null, 'الاسم', 'الباركود', null, 'فعلي'],
        [null, 'منتج أ', '100', null, '6'],
      ],
      'المبيعات': [
        [
          null,
          'التاريخ',
          'الاسم',
          'الباركود',
          'كمية',
          'السعر',
          null,
          'التكلفة',
          'ملاحظة'
        ],
        [null, '45000', 'منتج أ', '100', '2', '15', null, '5', '-'],
      ],
      'المرتجعات': [
        [
          null,
          'التاريخ',
          'الاسم',
          'الباركود',
          'كمية',
          'السعر',
          null,
          'التكلفة',
          'ملاحظة'
        ],
        [null, '45000', 'منتج أ', '100', '1', '15', null, '5', '-'],
      ],
      'المصروفات': [
        [null, 'التاريخ', 'البيان', 'المبلغ'],
        [null, '45000', 'إيجار', '500'],
      ],
    };
