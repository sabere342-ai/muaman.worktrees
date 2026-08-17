import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> createTestSchema(Database db) async {
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
      inventoryAdjustment INTEGER DEFAULT 0
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
      cogs REAL DEFAULT 0
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
      returnedCogs REAL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL DEFAULT 0,
      category TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      displayName TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      lastLoginAt TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS import_batches (
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
      reconciliation_json TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoiceNumber TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      customerName TEXT NOT NULL,
      paymentMethod TEXT NOT NULL,
      totalAmount REAL DEFAULT 0,
      totalItems INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS role_permissions (
      role TEXT PRIMARY KEY,
      permissions TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');
}
