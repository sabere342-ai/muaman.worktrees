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
      inventoryAdjustment INTEGER DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT,
      FOREIGN KEY (productId) REFERENCES products (id)
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
      lastLoginAt TEXT,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      reconciliation_json TEXT,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      createdAt TEXT NOT NULL,
      customerId INTEGER,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS role_permissions (
      role TEXT PRIMARY KEY,
      permissions TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      notes TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      isSystem INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_isActive ON customers(isActive)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_customerId ON invoices(customerId)');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue (
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
      shop_id TEXT
    )
  ''');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at ASC)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_shop_id ON sync_queue(shop_id)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');

  // Phase P Group D D1 (P-OD4): cost_history table for cost-change tracking.
  await db.execute('''
    CREATE TABLE IF NOT EXISTS cost_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop_id TEXT NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      product_barcode TEXT NOT NULL,
      old_cost REAL NOT NULL,
      new_cost REAL NOT NULL,
      changed_at TEXT NOT NULL,
      changed_by TEXT,
      FOREIGN KEY (product_id) REFERENCES products (id)
    )
  ''');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cost_history_shop ON cost_history(shop_id)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cost_history_product ON cost_history(product_id)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cost_history_barcode ON cost_history(product_barcode)');
}
