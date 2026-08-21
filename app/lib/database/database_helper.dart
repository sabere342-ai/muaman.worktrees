import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/return_item.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/user_role.dart';
import '../services/permissions.dart';
import '../services/permission_resolver.dart';
import '../sync/adapters/customer_sync_adapter.dart';
import '../sync/adapters/entity_sync_adapter.dart';
import '../sync/adapters/expense_category_sync_adapter.dart';
import '../sync/adapters/expense_sync_adapter.dart';
import '../sync/adapters/inventory_count_sync_adapter.dart';
import '../sync/adapters/invoice_sync_adapter.dart';
import '../sync/adapters/product_sync_adapter.dart';
import '../sync/adapters/return_sync_adapter.dart';
import '../sync/adapters/sale_sync_adapter.dart';
import '../sync/sync_queue_repository.dart';
import '../sync/sync_status.dart';
import 'data_importer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Licensing enforcement callback, set by [LicensingService] during
  /// initialization. When set, every business write method invokes this
  /// callback before proceeding. The callback MUST throw if the current
  /// entitlement is anything other than ACTIVE.
  static Future<void> Function()? _onBusinessMutation;

  /// Whether demo/trial data is auto-seeded on a fresh database creation.
  ///
  /// Production (release) builds MUST start empty: this flag defaults to
  /// `false` and is only enabled in dev/demo builds via
  /// `--dart-define=MUAMAN_SEED_DEMO=true`. Tests may override it directly.
  static bool seedDemoEnabled = const bool.fromEnvironment('MUAMAN_SEED_DEMO');

  /// Central permission source used by the data-layer guards. Tests may swap
  /// this with a fresh resolver.
  PermissionResolver permissionResolver = PermissionResolver.instance;

  DatabaseHelper._init();

  /// Registers the licensing enforcement callback. Must be called once during
  /// app startup (in [LicensingService.initialize]).
  static void setLicensingEnforcer(Future<void> Function() enforcer) {
    _onBusinessMutation = enforcer;
  }

  /// Removes the licensing enforcement callback. For test teardown only.
  static void clearLicensingEnforcer() {
    _onBusinessMutation = null;
  }

  Future<void> _enforceLicensing() async {
    final callback = _onBusinessMutation;
    if (callback != null) {
      await callback();
    }
  }

  // =================== SYNC ENQUEUE-AFTER-WRITE (Phase H / H-I09) ===================

  /// Provides the shop a local write should be attributed to when enqueuing
  /// sync operations. Registered during app startup next to the licensing
  /// enforcer. When it returns null (and the row carries no shop_id), writes
  /// stay purely local and no queue entry is created — there is no authorized
  /// cloud tenant to sync towards.
  static Future<String?> Function()? _syncShopIdProvider;

  /// Nesting counter for [runWithoutSyncEnqueue]. While > 0, business writes
  /// do not create queue entries. Cloud-originated apply paths (SyncEngine
  /// conflict resolution, hydration) use this so remote data never echoes
  /// back into the sync queue.
  static int _enqueueSuppressionDepth = 0;

  /// Monotonic sequence guard making idempotency keys unique even when two
  /// writes happen within the same microsecond.
  static int _syncKeySeq = 0;

  /// Registers the active-shop provider used to stamp sync queue entries.
  static void setSyncShopIdProvider(Future<String?> Function() provider) {
    _syncShopIdProvider = provider;
  }

  /// Removes the active-shop provider. For test teardown only.
  static void clearSyncShopIdProvider() {
    _syncShopIdProvider = null;
  }

  /// Runs [action] with sync enqueueing suppressed. Any DatabaseHelper
  /// business write performed inside this scope (e.g. applying a
  /// cloud-resolved row back to SQLite) will NOT enqueue a new sync
  /// operation, preventing CLOUD → LOCAL → QUEUE → CLOUD echo loops.
  static Future<T> runWithoutSyncEnqueue<T>(Future<T> Function() action) async {
    _enqueueSuppressionDepth++;
    try {
      return await action();
    } finally {
      _enqueueSuppressionDepth--;
    }
  }

  /// Adapter registry: local table → sync adapter defining the canonical
  /// cloud payload mapping. Tables without an entry are not cloud-synced
  /// through DatabaseHelper write paths.
  static final Map<String, EntitySyncAdapter> _syncAdaptersByTable = () {
    final adapters = <EntitySyncAdapter>[
      ProductSyncAdapter(),
      SaleSyncAdapter(),
      ReturnSyncAdapter(),
      ExpenseSyncAdapter(),
      ExpenseCategorySyncAdapter(),
      CustomerSyncAdapter(),
      InvoiceSyncAdapter(),
      InventoryCountSyncAdapter(),
    ];
    return {for (final a in adapters) a.localTableName: a};
  }();

  SyncQueueRepository? _syncQueueRepo;
  Database? _syncQueueRepoDb;

  /// Returns a queue repository bound to the current database handle,
  /// rebinding automatically after [setTestDatabase]/[resetForTest].
  SyncQueueRepository _syncQueueRepository(Database db) {
    if (_syncQueueRepo == null || !identical(_syncQueueRepoDb, db)) {
      _syncQueueRepoDb = db;
      _syncQueueRepo = SyncQueueRepository(db);
    }
    return _syncQueueRepo!;
  }

  Future<String?> _resolveSyncShopId(Map<String, dynamic> row) async {
    final provider = _syncShopIdProvider;
    if (provider != null) {
      final active = await provider();
      if (active != null && active.isNotEmpty) return active;
    }
    return row['shop_id'] as String?;
  }

  static String _generateSyncKey(
      String entityType, int entityId, SyncQueueOperation operation) {
    _syncKeySeq++;
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$entityType-$entityId-${operation.label}-$micros-$_syncKeySeq';
  }

  /// Enqueues a sync operation for a successfully written local row.
  ///
  /// Must be called on the same [executor] (transaction) that performed the
  /// write so the queue entry commits or rolls back atomically with it.
  /// Reads the persisted row back through [executor] and builds the payload
  /// with the entity's sync adapter, guaranteeing payload integrity with the
  /// SyncEngine/cloud contract. For deletes the row disappears from SQLite,
  /// so callers pass the pre-delete snapshot via [existingRow].
  /// Skips silently when:
  ///  - inside [runWithoutSyncEnqueue] (cloud-applied write),
  ///  - the table has no sync adapter (non-synced internal write),
  ///  - no owning shop can be resolved (no cloud tenant context).
  Future<void> _enqueueAfterWrite(
    Database db,
    DatabaseExecutor executor, {
    required String tableName,
    required int rowId,
    required SyncQueueOperation operation,
    Map<String, dynamic>? existingRow,
  }) async {
    if (_enqueueSuppressionDepth > 0) return;
    final adapter = _syncAdaptersByTable[tableName];
    if (adapter == null) return;

    Map<String, dynamic>? row;
    if (existingRow != null) {
      row = existingRow;
    } else {
      final rows = await executor.query(tableName,
          where: 'id = ?', whereArgs: [rowId], limit: 1);
      row = rows.isEmpty ? null : rows.first;
    }
    if (row == null) return;

    final shopId = await _resolveSyncShopId(row);
    if (shopId == null || shopId.isEmpty) return;

    final payload = <String, dynamic>{
      'id': rowId,
      'cloud_uuid': row['cloud_uuid'] as String?,
      'server_version': (row['server_version'] as num?)?.toInt() ?? 0,
      ...adapter.localToCloudPayload(row),
    };

    await _syncQueueRepository(db).enqueue(
      entityType: adapter.entityType.label,
      entityId: rowId,
      operation: operation,
      payload: payload,
      idempotencyKey:
          _generateSyncKey(adapter.entityType.label, rowId, operation),
      shopId: shopId,
      executor: executor,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS sales');
      await db.execute('DROP TABLE IF EXISTS returns');
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('DROP TABLE IF EXISTS inventory_count');
      await _createDB(db, newVersion);
      return;
    }
    if (oldVersion < 3) {
      await _createUsersTable(db);
    }
    if (oldVersion < 4) {
      await _createImportBatchesTable(db);
    }
    if (oldVersion < 5) {
      await _createInvoicesTable(db);
      await db.execute('ALTER TABLE sales ADD COLUMN invoiceId INTEGER');
      await _createAppSettingsTable(db);
    }
    if (oldVersion < 6) {
      await _createRolePermissionsTable(db);
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT');
      await _createExpenseCategoriesTable(db);
    }
    if (oldVersion < 8) {
      await _migrateToV8(db);
    }
    if (oldVersion < 9) {
      await _migrateToV9(db);
    }
    if (oldVersion < 13) {
      await _migrateToV13(db);
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('muaman_store.db');
    return _database!;
  }

  static Future<void> setTestDatabase(Database db) async {
    _database = db;
  }

  /// Test-only seam: runs the real `_createDB` (schema + conditional demo
  /// seeding) against the given database so seed gating can be verified
  /// without touching a real database file.
  @visibleForTesting
  static Future<void> runCreateDbForTest(Database db) async {
    await DatabaseHelper.instance._createDB(db, 13);
    await DatabaseHelper.instance._migrateToV13(db);
    await db.rawUpdate('PRAGMA user_version = 13');
  }

  /// Returns the full filesystem path to `muaman_store.db`.
  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'muaman_store.db');
  }

  /// Closes the current database connection. After calling this, the next
  /// access to [database] will reopen the file.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Reopens the database after [close]. The next access to [database] will
  /// lazily open the file again.
  Future<Database> reopen() async {
    _database = null;
    return await database;
  }

  /// Reset the singleton reference (for tests or after file-level restore).
  static void resetForTest() {
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 13, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future<void> _createDB(Database db, int version) async {
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
        cloud_uuid TEXT,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await _createUsersTable(db);
    await _createImportBatchesTable(db);
    await _createInvoicesTable(db);
    await _createAppSettingsTable(db);
    await _createRolePermissionsTable(db);
    await _createExpenseCategoriesTable(db);
    await _createCustomersTable(db);
    if (seedDemoEnabled) {
      await DataImporter.importData(db);
    }
  }

  Future<void> _createImportBatchesTable(Database db) async {
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
        cloud_uuid TEXT
      )
    ''');
  }

  Future<void> _createInvoicesTable(Database db) async {
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
        shop_id TEXT,
        cloud_uuid TEXT
      )
    ''');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        shop_id TEXT,
        cloud_uuid TEXT
      )
    ''');
  }

  Future<void> _createRolePermissionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        role TEXT PRIMARY KEY,
        permissions TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        shop_id TEXT,
        cloud_uuid TEXT
      )
    ''');
  }

  Future<void> _createExpenseCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        shop_id TEXT,
        cloud_uuid TEXT
      )
    ''');
  }

  Future<void> _createCustomersTable(Database db) async {
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
        cloud_uuid TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_isActive ON customers(isActive)');
  }

  Future<void> _migrateToV8(Database db) async {
    await _createCustomersTable(db);

    await db.execute('ALTER TABLE invoices ADD COLUMN customerId INTEGER');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_customerId ON invoices(customerId)');

    final settingsRows = await db.query('app_settings',
        where: "key = ?", whereArgs: ['defaultCustomerName']);
    final defaultName = settingsRows.isNotEmpty
        ? (settingsRows.first['value'] as String).trim()
        : 'عميل نقدي';

    final now = DateTime.now().toIso8601String();
    final systemCustomerId = await db.insert('customers', {
      'name': defaultName.isNotEmpty ? defaultName : 'عميل نقدي',
      'isActive': 1,
      'isSystem': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.rawUpdate('''
      UPDATE invoices
      SET customerId = ?
      WHERE customerId IS NULL
        AND customerName = ?
    ''', [systemCustomerId, defaultName]);

    await db.rawUpdate('''
      UPDATE invoices
      SET customerId = ?
      WHERE customerId IS NULL
    ''', [systemCustomerId]);

    await db.delete('app_settings',
        where: "key = ?", whereArgs: ['defaultCustomerName']);
  }

  Future<void> _migrateToV9(Database db) async {
    const tables = [
      'products',
      'sales',
      'returns',
      'expenses',
      'expense_categories',
      'inventory_count',
      'invoices',
      'import_batches',
      'customers',
      'users',
      'role_permissions',
      'app_settings',
    ];
    for (final table in tables) {
      await db.execute('ALTER TABLE $table ADD COLUMN shop_id TEXT');
      await db.execute('ALTER TABLE $table ADD COLUMN cloud_uuid TEXT');
    }
  }

  Future<void> _migrateToV13(Database db) async {
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

    const syncTables = [
      'products',
      'sales',
      'returns',
      'expenses',
      'expense_categories',
      'inventory_count',
      'invoices',
      'import_batches',
      'customers',
      'users',
      'role_permissions',
      'app_settings',
    ];

    for (final table in syncTables) {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final columns = info.map((r) => r['name'] as String).toSet();

      if (!columns.contains('server_version')) {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN server_version INTEGER DEFAULT 0');
      }
      if (!columns.contains('sync_status')) {
        await db.execute(
            "ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'SYNCED'");
      }
      if (!columns.contains('last_synced_at')) {
        await db.execute('ALTER TABLE $table ADD COLUMN last_synced_at TEXT');
      }
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
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
        cloud_uuid TEXT
      )
    ''');
  }

  // =================== PRODUCTS ===================
  Future<int> insertProduct(Product product, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canEditProducts);
    final trimmedName = product.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('يجب إدخال اسم المنتج');
    }

    final trimmedBarcode = product.barcode.trim();
    if (trimmedBarcode.isEmpty) {
      throw ArgumentError('الباركود مطلوب');
    }

    if (product.costPrice <= 0) {
      throw ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر');
    }

    final db = await database;

    final dup = await db.rawQuery(
        'SELECT id FROM products WHERE trim(barcode) = ? LIMIT 1',
        [trimmedBarcode]);
    if (dup.isNotEmpty) {
      throw ArgumentError('الباركود موجود مسبقًا');
    }

    final normalized = product.copyWith(
      name: trimmedName,
      barcode: trimmedBarcode,
    );
    return await db.transaction((txn) async {
      final id = await txn.insert(
          'products',
          {
            ...normalized.toMap()..remove('id'),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'products', rowId: id, operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'id ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps =
        await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getProductByName(String name) async {
    final db = await database;
    final maps =
        await db.query('products', where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> updateProduct(Product product, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canEditProducts);
    final trimmedName = product.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('يجب إدخال اسم المنتج');
    }

    final trimmedBarcode = product.barcode.trim();
    if (trimmedBarcode.isEmpty) {
      throw ArgumentError('الباركود مطلوب');
    }

    if (product.costPrice <= 0) {
      throw ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر');
    }

    final db = await database;

    final dup = await db.rawQuery(
        'SELECT id FROM products WHERE trim(barcode) = ? AND id != ?',
        [trimmedBarcode, product.id]);
    if (dup.isNotEmpty) {
      throw ArgumentError('الباركود موجود مسبقًا');
    }

    final normalized = product.copyWith(
      name: trimmedName,
      barcode: trimmedBarcode,
    );
    return await db.transaction((txn) async {
      final affected = await txn.update(
          'products',
          {
            ...normalized.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: 'id = ?',
          whereArgs: [product.id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'products',
            rowId: product.id!,
            operation: SyncQueueOperation.UPDATE);
      }
      return affected;
    });
  }

  /// Throws [PermissionDeniedException] unless [currentRole] holds
  /// [permission]. This is the data-layer authorization gate for sensitive
  /// mutations, enforced even if a screen is reached through a direct route.
  void _requirePermission(UserRole? currentRole, AppPermission permission) {
    if (currentRole == null ||
        !permissionResolver.can(currentRole, permission)) {
      throw const PermissionDeniedException(
          'غير مصرح بهذه العملية. هذه الخاصية غير متاحة لدورك.');
    }
  }

  /// Throws [SalesHistoryAccessDeniedException] unless [currentRole] holds the
  /// [AppPermission.canViewSalesHistory] permission. This is the data-layer
  /// gate that prevents sales history (list, reports, previous invoices) from
  /// ever being loaded for an unauthorized role — even if a screen is reached
  /// through a direct/unexpected route.
  void _requireSalesHistoryAccess(UserRole? currentRole) {
    if (currentRole == null ||
        !permissionResolver.can(
            currentRole, AppPermission.canViewSalesHistory)) {
      throw const SalesHistoryAccessDeniedException();
    }
  }

  Future<int> deleteProduct(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteProducts);
    final db = await database;
    return await db.transaction((txn) async {
      final productMaps =
          await txn.query('products', where: 'id = ?', whereArgs: [id]);
      if (productMaps.isEmpty) return 0;
      final product = Product.fromMap(productMaps.first);

      final List<String> references = [];

      final saleRows = await txn.query('sales',
          where: 'barcode = ?', whereArgs: [product.barcode], limit: 1);
      if (saleRows.isNotEmpty) references.add('مبيعات');

      final returnRows = await txn.query('returns',
          where: 'barcode = ?', whereArgs: [product.barcode], limit: 1);
      if (returnRows.isNotEmpty) references.add('مرتجعات');

      final countRows = await txn.query('inventory_count',
          where: 'productId = ?', whereArgs: [id], limit: 1);
      if (countRows.isNotEmpty) references.add('جرد مخزون');

      if (references.isNotEmpty) {
        throw ProductDeletionException(references);
      }

      final affected =
          await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'products',
            rowId: id,
            operation: SyncQueueOperation.DELETE,
            existingRow: productMaps.first);
      }
      return affected;
    });
  }

  Future<void> updateSoldQuantity(String barcode, int quantity) async {
    final db = await database;
    final product = await getProductByBarcode(barcode);
    if (product != null) {
      final newSold = product.soldQuantity + quantity;
      final newCurrent = product.openingQuantity -
          newSold +
          product.returnedQuantity +
          product.inventoryAdjustment;
      await db.update(
        'products',
        {
          'soldQuantity': newSold,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    }
  }

  Future<void> revertSoldQuantity(String barcode, int quantity) async {
    final db = await database;
    final product = await getProductByBarcode(barcode);
    if (product != null) {
      final newSold = product.soldQuantity - quantity;
      final newCurrent = product.openingQuantity -
          newSold +
          product.returnedQuantity +
          product.inventoryAdjustment;
      await db.update(
        'products',
        {
          'soldQuantity': newSold,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    }
  }

  Future<void> updateReturnedQuantity(String barcode, int quantity) async {
    final db = await database;
    final product = await getProductByBarcode(barcode);
    if (product != null) {
      final newReturned = product.returnedQuantity + quantity;
      final newCurrent = product.openingQuantity -
          product.soldQuantity +
          newReturned +
          product.inventoryAdjustment;
      await db.update(
        'products',
        {
          'returnedQuantity': newReturned,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    }
  }

  Future<void> revertReturnedQuantity(String barcode, int quantity) async {
    final db = await database;
    final product = await getProductByBarcode(barcode);
    if (product != null) {
      final newReturned = product.returnedQuantity - quantity;
      final newCurrent = product.openingQuantity -
          product.soldQuantity +
          newReturned +
          product.inventoryAdjustment;
      await db.update(
        'products',
        {
          'returnedQuantity': newReturned,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    }
  }

  // =================== SALES ===================
  Future<int> insertSale(Sale sale, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    if (sale.quantity <= 0) {
      throw ArgumentError('Sale quantity must be greater than zero');
    }
    if (sale.salePrice <= 0) {
      throw ArgumentError('يجب أن يكون سعر البيع أكبر من صفر');
    }
    final db = await database;
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, sale.barcode);

      final productMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [sale.barcode]);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert(
          'sales',
          {
            ...sale.toMap()..remove('id'),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'sales', rowId: id, operation: SyncQueueOperation.CREATE);

      final newSold = product.soldQuantity + sale.quantity;
      final newCurrent = product.openingQuantity -
          newSold +
          product.returnedQuantity +
          product.inventoryAdjustment;

      await txn.update(
        'products',
        {
          'soldQuantity': newSold,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [sale.barcode],
      );

      return id;
    });
  }

  Future<int> insertSaleAndDecrementStock(Sale sale,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    return await db.transaction((txn) async {
      if (sale.quantity <= 0) {
        throw ArgumentError('Sale quantity must be greater than zero');
      }
      if (sale.salePrice <= 0) {
        throw ArgumentError('يجب أن يكون سعر البيع أكبر من صفر');
      }

      final productMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [sale.barcode]);

      if (productMaps.isEmpty) {
        throw StateError('Product with barcode "${sale.barcode}" not found');
      }

      final product = Product.fromMap(productMaps.first);

      if (product.currentQuantity < sale.quantity) {
        throw StateError(
          'Insufficient stock: available ${product.currentQuantity}, requested ${sale.quantity}',
        );
      }

      final id = await txn.insert(
          'sales',
          {
            ...sale.toMap()..remove('id'),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'sales', rowId: id, operation: SyncQueueOperation.CREATE);

      final newSold = product.soldQuantity + sale.quantity;
      final newCurrent = product.openingQuantity -
          newSold +
          product.returnedQuantity +
          product.inventoryAdjustment;

      final affected = await txn.update(
        'products',
        {
          'soldQuantity': newSold,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'id = ? AND currentQuantity >= ?',
        whereArgs: [product.id, sale.quantity],
      );

      if (affected == 0) {
        throw StateError(
            'Stock changed before sale could complete. Please try again.');
      }

      return id;
    });
  }

  Future<int> insertInvoiceWithItems(Invoice invoice, List<Sale> invoiceItems,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    return await db.transaction((txn) async {
      if (invoiceItems.isEmpty) {
        throw ArgumentError('يجب إضافة منتج واحد على الأقل إلى الفاتورة');
      }
      if (invoice.totalAmount <= 0) {
        throw ArgumentError('الإجمالي يجب أن يكون أكبر من صفر');
      }
      if (invoice.customerName.trim().isEmpty) {
        throw ArgumentError('اسم العميل مطلوب');
      }

      final invoiceId = await txn.insert(
          'invoices',
          {
            ...invoice.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'invoices',
          rowId: invoiceId,
          operation: SyncQueueOperation.CREATE);
      for (final item in invoiceItems) {
        if (item.quantity <= 0) {
          throw ArgumentError('الكمية يجب أن تكون أكبر من صفر');
        }
        if (item.salePrice <= 0) {
          throw ArgumentError('سعر البيع يجب أن يكون أكبر من صفر');
        }

        final productMaps = await txn
            .query('products', where: 'barcode = ?', whereArgs: [item.barcode]);
        if (productMaps.isEmpty) {
          throw StateError('المنتج غير موجود: ${item.productName}');
        }

        final product = Product.fromMap(productMaps.first);
        if (product.currentQuantity < item.quantity) {
          throw StateError(
              'الكمية غير كافية للمنتج ${item.productName}. المتاح: ${product.currentQuantity}');
        }

        final saleLineId = await txn.insert(
            'sales',
            {
              ...item.copyWith(invoiceId: invoiceId).toMap()..remove('id'),
              'sync_status': EntitySyncStatus.PENDING.label,
            },
        );
        await _enqueueAfterWrite(db, txn,
            tableName: 'sales',
            rowId: saleLineId,
            operation: SyncQueueOperation.CREATE);

        final newSold = product.soldQuantity + item.quantity;
        final newCurrent = product.openingQuantity -
            newSold +
            product.returnedQuantity +
            product.inventoryAdjustment;

        final affected = await txn.update(
          'products',
          {
            'soldQuantity': newSold,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * product.costPrice,
          },
          where: 'id = ? AND currentQuantity >= ?',
          whereArgs: [product.id, item.quantity],
        );

        if (affected == 0) {
          throw StateError('تغير المخزون قبل حفظ الفاتورة. حاول مرة أخرى.');
        }
      }

      return invoiceId;
    });
  }

  Future<List<Sale>> getAllSales({UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final maps = await db.query('sales', orderBy: 'id ASC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  /// Loads a single invoice header. Gated by [canViewSalesHistory] like every
  /// other sales-history read, so a previous invoice can never be loaded for an
  /// unauthorized role even through a direct route.
  Future<Invoice?> getInvoiceById(int id, {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final maps =
        await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// Loads the sale rows of an invoice in insertion order. Gated by
  /// [canViewSalesHistory].
  Future<List<Sale>> getSalesByInvoiceId(int invoiceId,
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final maps = await db.query('sales',
        where: 'invoiceId = ?', whereArgs: [invoiceId], orderBy: 'id ASC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end,
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final maps = await db.query('sales',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<int> updateSale(Sale sale) async {
    await _enforceLicensing();
    if (sale.quantity <= 0) {
      throw ArgumentError('يجب أن تكون الكمية أكبر من صفر');
    }
    if (sale.salePrice.isNaN || sale.salePrice.isInfinite) {
      throw ArgumentError('سعر البيع غير صالح');
    }
    if (sale.salePrice <= 0) {
      throw ArgumentError('يجب أن يكون سعر البيع أكبر من صفر');
    }

    final trimmedBarcode = sale.barcode.trim();

    final db = await database;
    return await db.transaction((txn) async {
      final oldData =
          await txn.query('sales', where: 'id = ?', whereArgs: [sale.id]);

      if (oldData.isEmpty) {
        throw StateError('السجل المطلوب تعديله غير موجود');
      }

      final old = Sale.fromMap(oldData.first);
      final oldBarcode = old.barcode;

      final oldProductMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [oldBarcode]);
      if (oldProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج القديم للبيع غير موجود');
      }
      final oldProduct = Product.fromMap(oldProductMaps.first);

      await _requireExistingProductByBarcode(txn, trimmedBarcode);

      final newProductMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [trimmedBarcode]);
      final newProduct = Product.fromMap(newProductMaps.first);

      final sameProduct = oldBarcode == trimmedBarcode;

      if (sameProduct) {
        final netEffect = sale.quantity - old.quantity;
        if (netEffect > 0 && newProduct.currentQuantity < netEffect) {
          throw InsufficientStockException(
            productId: newProduct.id!,
            availableQuantity: newProduct.currentQuantity.toDouble(),
            requestedQuantity: netEffect.toDouble(),
          );
        }

        final newSold = newProduct.soldQuantity - old.quantity + sale.quantity;
        final newCurrent = newProduct.openingQuantity -
            newSold +
            newProduct.returnedQuantity +
            newProduct.inventoryAdjustment;

        final affectedProduct = await txn.update(
          'products',
          {
            'soldQuantity': newSold,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * newProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [newProduct.id],
        );
        if (affectedProduct != 1) {
          throw StateError('فشل تحديث المخزون');
        }
      } else {
        final revertedSold = oldProduct.soldQuantity - old.quantity;
        final revertedCurrent = oldProduct.openingQuantity -
            revertedSold +
            oldProduct.returnedQuantity +
            oldProduct.inventoryAdjustment;

        final affectedOld = await txn.update(
          'products',
          {
            'soldQuantity': revertedSold,
            'currentQuantity': revertedCurrent,
            'totalInventoryCost': revertedCurrent * oldProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [oldProduct.id],
        );
        if (affectedOld != 1) {
          throw StateError('فشل تحديث المخزون القديم');
        }

        if (newProduct.currentQuantity < sale.quantity) {
          throw InsufficientStockException(
            productId: newProduct.id!,
            availableQuantity: newProduct.currentQuantity.toDouble(),
            requestedQuantity: sale.quantity.toDouble(),
          );
        }

        final newSold = newProduct.soldQuantity + sale.quantity;
        final newCurrent = newProduct.openingQuantity -
            newSold +
            newProduct.returnedQuantity +
            newProduct.inventoryAdjustment;

        final affectedNew = await txn.update(
          'products',
          {
            'soldQuantity': newSold,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * newProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [newProduct.id],
        );
        if (affectedNew != 1) {
          throw StateError('فشل تحديث المخزون الجديد');
        }
      }

      final updatedSale = Sale(
        id: sale.id,
        date: sale.date,
        productName: sale.productName,
        barcode: trimmedBarcode,
        quantity: sale.quantity,
        salePrice: sale.salePrice,
        costPrice: sale.costPrice,
      );

      final affectedSale = await txn.update(
          'sales',
          {
            ...updatedSale.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: 'id = ?',
          whereArgs: [sale.id]);
      if (affectedSale != 1) {
        throw StateError('فشل تحديث سجل البيع');
      }

      await _enqueueAfterWrite(db, txn,
          tableName: 'sales',
          rowId: sale.id!,
          operation: SyncQueueOperation.UPDATE);

      return 1;
    });
  }

  Future<int> deleteSale(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteSales);
    final db = await database;
    return await db.transaction((txn) async {
      final saleData = await txn.query('sales', where: 'id = ?', whereArgs: [id]);
      if (saleData.isEmpty) return 0;
      final sale = Sale.fromMap(saleData.first);

      // Inline revert of the sold quantity (same math as
      // [revertSoldQuantity]) so the deletion and its queue entry commit or
      // roll back as one unit.
      final productMaps =
          await txn.query('products', where: 'barcode = ?', whereArgs: [sale.barcode]);
      if (productMaps.isNotEmpty) {
        final product = Product.fromMap(productMaps.first);
        final newSold = product.soldQuantity - sale.quantity;
        final newCurrent = product.openingQuantity -
            newSold +
            product.returnedQuantity +
            product.inventoryAdjustment;
        await txn.update(
          'products',
          {
            'soldQuantity': newSold,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * product.costPrice,
          },
          where: 'barcode = ?',
          whereArgs: [sale.barcode],
        );
      }

      final affected =
          await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'sales',
            rowId: id,
            operation: SyncQueueOperation.DELETE,
            existingRow: saleData.first);
      }
      return affected;
    });
  }

  Future<double> getTotalSales() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(totalSaleValue) as total FROM sales');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCOGS() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(cogs) as total FROM sales');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // =================== RETURNS ===================
  Future<int> insertReturn(ReturnItem returnItem,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateReturns);
    if (returnItem.quantity <= 0) {
      throw ArgumentError('يجب أن تكون الكمية أكبر من صفر');
    }
    if (returnItem.salePrice.isNaN || returnItem.salePrice.isInfinite) {
      throw ArgumentError('سعر المرتجع غير صالح');
    }
    if (returnItem.salePrice <= 0) {
      throw ArgumentError('يجب أن يكون سعر المرتجع أكبر من صفر');
    }
    final db = await database;
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, returnItem.barcode);

      final productMaps = await txn.query('products',
          where: 'barcode = ?', whereArgs: [returnItem.barcode]);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert(
          'returns',
          {
            ...returnItem.toMap()..remove('id'),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'returns',
          rowId: id,
          operation: SyncQueueOperation.CREATE);

      final newReturned = product.returnedQuantity + returnItem.quantity;
      final newCurrent = product.openingQuantity -
          product.soldQuantity +
          newReturned +
          product.inventoryAdjustment;

      await txn.update(
        'products',
        {
          'returnedQuantity': newReturned,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'barcode = ?',
        whereArgs: [returnItem.barcode],
      );

      return id;
    });
  }

  Future<List<ReturnItem>> getAllReturns() async {
    final db = await database;
    final maps = await db.query('returns', orderBy: 'id ASC');
    return maps.map((map) => ReturnItem.fromMap(map)).toList();
  }

  Future<int> updateReturn(ReturnItem returnItem) async {
    await _enforceLicensing();
    if (returnItem.quantity <= 0) {
      throw ArgumentError('يجب أن تكون الكمية أكبر من صفر');
    }
    if (returnItem.salePrice.isNaN || returnItem.salePrice.isInfinite) {
      throw ArgumentError('سعر المرتجع غير صالح');
    }
    if (returnItem.salePrice <= 0) {
      throw ArgumentError('يجب أن يكون سعر المرتجع أكبر من صفر');
    }

    final trimmedBarcode = returnItem.barcode.trim();

    final db = await database;
    return await db.transaction((txn) async {
      final oldData = await txn
          .query('returns', where: 'id = ?', whereArgs: [returnItem.id]);

      if (oldData.isEmpty) {
        throw StateError('السجل المطلوب تعديله غير موجود');
      }

      final old = ReturnItem.fromMap(oldData.first);
      final oldBarcode = old.barcode;

      final oldProductMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [oldBarcode]);
      if (oldProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج القديم للمرتجع غير موجود');
      }
      final oldProduct = Product.fromMap(oldProductMaps.first);

      await _requireExistingProductByBarcode(txn, trimmedBarcode);

      final newProductMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [trimmedBarcode]);
      final newProduct = Product.fromMap(newProductMaps.first);

      final sameProduct = oldBarcode == trimmedBarcode;

      if (sameProduct) {
        if (newProduct.currentQuantity < old.quantity) {
          throw ReturnStockReversalException(
            returnId: returnItem.id!,
            currentStock: newProduct.currentQuantity.toDouble(),
            requiredReversalQuantity: old.quantity.toDouble(),
          );
        }

        final newReturned =
            newProduct.returnedQuantity - old.quantity + returnItem.quantity;
        final newCurrent = newProduct.openingQuantity -
            newProduct.soldQuantity +
            newReturned +
            newProduct.inventoryAdjustment;

        final affectedProduct = await txn.update(
          'products',
          {
            'returnedQuantity': newReturned,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * newProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [newProduct.id],
        );
        if (affectedProduct != 1) {
          throw StateError('فشل تحديث المخزون');
        }
      } else {
        final revertedReturned = oldProduct.returnedQuantity - old.quantity;
        final revertedCurrent = oldProduct.openingQuantity -
            oldProduct.soldQuantity +
            revertedReturned +
            oldProduct.inventoryAdjustment;

        if (revertedCurrent < 0) {
          throw ReturnStockReversalException(
            returnId: returnItem.id!,
            currentStock: oldProduct.currentQuantity.toDouble(),
            requiredReversalQuantity: old.quantity.toDouble(),
          );
        }

        final affectedOld = await txn.update(
          'products',
          {
            'returnedQuantity': revertedReturned,
            'currentQuantity': revertedCurrent,
            'totalInventoryCost': revertedCurrent * oldProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [oldProduct.id],
        );
        if (affectedOld != 1) {
          throw StateError('فشل تحديث المخزون القديم');
        }

        final newReturned = newProduct.returnedQuantity + returnItem.quantity;
        final newCurrent = newProduct.openingQuantity -
            newProduct.soldQuantity +
            newReturned +
            newProduct.inventoryAdjustment;

        final affectedNew = await txn.update(
          'products',
          {
            'returnedQuantity': newReturned,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * newProduct.costPrice,
          },
          where: 'id = ?',
          whereArgs: [newProduct.id],
        );
        if (affectedNew != 1) {
          throw StateError('فشل تحديث المخزون الجديد');
        }
      }

      final updatedReturn = ReturnItem(
        id: returnItem.id,
        date: returnItem.date,
        productName: returnItem.productName,
        barcode: trimmedBarcode,
        quantity: returnItem.quantity,
        salePrice: returnItem.salePrice,
        costPrice: returnItem.costPrice,
      );

      final affectedReturn = await txn.update(
          'returns',
          {
            ...updatedReturn.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: 'id = ?',
          whereArgs: [returnItem.id]);
      if (affectedReturn != 1) {
        throw StateError('فشل تحديث سجل المرتجع');
      }

      await _enqueueAfterWrite(db, txn,
          tableName: 'returns',
          rowId: returnItem.id!,
          operation: SyncQueueOperation.UPDATE);

      return 1;
    });
  }

  Future<int> deleteReturn(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteReturns);
    final db = await database;
    return await db.transaction((txn) async {
      final data = await txn.query('returns', where: 'id = ?', whereArgs: [id]);
      if (data.isEmpty) return 0;
      final ret = ReturnItem.fromMap(data.first);

      // Inline revert of the returned quantity (same math as
      // [revertReturnedQuantity]) so the deletion and its queue entry commit
      // or roll back as one unit.
      final productMaps =
          await txn.query('products', where: 'barcode = ?', whereArgs: [ret.barcode]);
      if (productMaps.isNotEmpty) {
        final product = Product.fromMap(productMaps.first);
        final newReturned = product.returnedQuantity - ret.quantity;
        final newCurrent = product.openingQuantity -
            product.soldQuantity +
            newReturned +
            product.inventoryAdjustment;
        await txn.update(
          'products',
          {
            'returnedQuantity': newReturned,
            'currentQuantity': newCurrent,
            'totalInventoryCost': newCurrent * product.costPrice,
          },
          where: 'barcode = ?',
          whereArgs: [ret.barcode],
        );
      }

      final affected =
          await txn.delete('returns', where: 'id = ?', whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'returns',
            rowId: id,
            operation: SyncQueueOperation.DELETE,
            existingRow: data.first);
      }
      return affected;
    });
  }

  Future<double> getTotalReturns() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(totalReturnValue) as total FROM returns');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalReturnedCOGS() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(returnedCogs) as total FROM returns');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // =================== EXPENSES ===================
  Future<int> insertExpense(Expense expense, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateExpenses);
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert(
          'expenses',
          {
            ...expense.toMap()..remove('id'),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'expenses',
          rowId: id,
          operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'id ASC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    await _enforceLicensing();
    final db = await database;
    return await db.transaction((txn) async {
      final affected = await txn.update(
          'expenses',
          {
            ...expense.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: 'id = ?',
          whereArgs: [expense.id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'expenses',
            rowId: expense.id!,
            operation: SyncQueueOperation.UPDATE);
      }
      return affected;
    });
  }

  Future<int> deleteExpense(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteExpenses);
    final db = await database;
    return await db.transaction((txn) async {
      final existing = await txn.query('expenses',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (existing.isEmpty) return 0;
      final affected =
          await txn.delete('expenses', where: 'id = ?', whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'expenses',
            rowId: id,
            operation: SyncQueueOperation.DELETE,
            existingRow: existing.first);
      }
      return affected;
    });
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // =================== EXPENSE CATEGORIES ===================
  Future<int> insertExpenseCategory(ExpenseCategory category,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canManageUsers);
    final db = await database;
    final normalized = ExpenseCategory.normalize(category.name);
    if (ExpenseCategory.isBlankName(normalized)) {
      throw ArgumentError('اسم التصنيف لا يمكن أن يكون فارغاً');
    }
    final existing = await db.query('expense_categories',
        where: 'LOWER(name) = LOWER(?)', whereArgs: [normalized]);
    if (existing.isNotEmpty) {
      throw ArgumentError('التصنيف "$normalized" موجود بالفعل');
    }
    return await db.transaction((txn) async {
      final id =
          await txn.insert('expense_categories', {'name': normalized});
      await _enqueueAfterWrite(db, txn,
          tableName: 'expense_categories',
          rowId: id,
          operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    final db = await database;
    final maps = await db.query('expense_categories', orderBy: 'id ASC');
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  Future<int> renameExpenseCategory(int id, String newName,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canManageUsers);
    final db = await database;
    final normalized = ExpenseCategory.normalize(newName);
    if (ExpenseCategory.isBlankName(normalized)) {
      throw ArgumentError('اسم التصنيف لا يمكن أن يكون فارغاً');
    }
    final existing = await db.query('expense_categories',
        where: 'LOWER(name) = LOWER(?) AND id != ?',
        whereArgs: [normalized, id]);
    if (existing.isNotEmpty) {
      throw ArgumentError('التصنيف "$normalized" موجود بالفعل');
    }
    return await db.transaction((txn) async {
      final affected = await txn.update(
          'expense_categories',
          {
            'name': normalized,
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: 'id = ?',
          whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'expense_categories',
            rowId: id,
            operation: SyncQueueOperation.UPDATE);
      }
      return affected;
    });
  }

  Future<int> deleteExpenseCategory(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canManageUsers);
    final db = await database;
    final category =
        await db.query('expense_categories', where: 'id = ?', whereArgs: [id]);
    if (category.isEmpty) {
      throw ArgumentError('التصنيف غير موجود');
    }
    final categoryName = category.first['name'] as String;
    final usageCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE category = ?',
        [categoryName]);
    final count = (usageCount.first['count'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      throw StateError(
          'لا يمكن حذف التصنيف "$categoryName" لأنه مستخدم في $count مصروف');
    }
    return await db.transaction((txn) async {
      final affected = await txn
          .delete('expense_categories', where: 'id = ?', whereArgs: [id]);
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'expense_categories',
            rowId: id,
            operation: SyncQueueOperation.DELETE,
            existingRow: category.first);
      }
      return affected;
    });
  }

  Future<List<String>> getDistinctExpenseCategories() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT DISTINCT category FROM expenses WHERE category IS NOT NULL AND category != "" ORDER BY category ASC');
    return result.map((row) => row['category'] as String).toList();
  }

  // =================== INVENTORY COUNT ===================
  Future<int> saveInventoryCount(
      int productId, int actualQuantity, String notes,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canAccessStocktake);
    final db = await database;
    return await db.transaction((txn) async {
      if (actualQuantity < 0) {
        throw ArgumentError('الكمية الفعلية لا يمكن أن تكون سالبة');
      }

      final productMaps =
          await txn.query('products', where: 'id = ?', whereArgs: [productId]);

      if (productMaps.isEmpty) {
        throw StateError('المنتج غير موجود');
      }

      final product = Product.fromMap(productMaps.first);
      final countDifference = actualQuantity - product.currentQuantity;
      final newCurrent = actualQuantity;
      final newAdjustment = newCurrent -
          (product.openingQuantity -
              product.soldQuantity +
              product.returnedQuantity);

      final countId = await txn.insert('inventory_count', {
        'productId': productId,
        'actualQuantity': actualQuantity,
        'notes': notes,
        'countDate': DateTime.now().toIso8601String(),
        'sync_status': EntitySyncStatus.PENDING.label,
      });
      await _enqueueAfterWrite(db, txn,
          tableName: 'inventory_count',
          rowId: countId,
          operation: SyncQueueOperation.CREATE);

      final affected = await txn.update(
        'products',
        {
          'inventoryAdjustment': newAdjustment,
          'currentQuantity': newCurrent,
          'totalInventoryCost': newCurrent * product.costPrice,
        },
        where: 'id = ? AND currentQuantity = ?',
        whereArgs: [productId, product.currentQuantity],
      );

      if (affected == 0) {
        throw StateError('تغير المخزون أثناء الحفظ. حاول مرة أخرى');
      }

      return countDifference;
    });
  }

  // =================== DASHBOARD ===================
  Future<Map<String, double>> getDashboardData() async {
    final totalSales = await getTotalSales();
    final totalReturns = await getTotalReturns();
    final totalCOGS = await getTotalCOGS();
    final totalReturnedCOGS = await getTotalReturnedCOGS();
    final totalExpenses = await getTotalExpenses();

    final netSales = totalSales - totalReturns;
    final netCOGS = totalCOGS - totalReturnedCOGS;
    final grossProfit = netSales - netCOGS;
    final netProfit = grossProfit - totalExpenses;

    return {
      'totalSales': totalSales,
      'totalReturns': totalReturns,
      'netSales': netSales,
      'totalCOGS': totalCOGS,
      'totalReturnedCOGS': totalReturnedCOGS,
      'netCOGS': netCOGS,
      'grossProfit': grossProfit,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
    };
  }

  /// Checks whether a product has any historical or operational references.
  /// Returns a list of Arabic reason strings, or an empty list if none found.
  Future<List<String>> getProductReferences(int productId) async {
    final db = await database;
    final productMaps =
        await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (productMaps.isEmpty) return [];
    final product = Product.fromMap(productMaps.first);

    final List<String> refs = [];

    final saleRows = await db.query('sales',
        where: 'barcode = ?', whereArgs: [product.barcode], limit: 1);
    if (saleRows.isNotEmpty) refs.add('مبيعات');

    final returnRows = await db.query('returns',
        where: 'barcode = ?', whereArgs: [product.barcode], limit: 1);
    if (returnRows.isNotEmpty) refs.add('مرتجعات');

    final countRows = await db.query('inventory_count',
        where: 'productId = ?', whereArgs: [productId], limit: 1);
    if (countRows.isNotEmpty) refs.add('جرد مخزون');

    return refs;
  }

  /// Scans all tables for orphan references to non-existent products.
  /// Returns an [IntegrityIssueReport] cataloguing every orphan row found.
  Future<IntegrityIssueReport> findProductReferenceIntegrityIssues() async {
    final db = await database;

    // inventory_count rows whose productId does not match any product
    final orphanCounts = await db.rawQuery('''
      SELECT ic.* FROM inventory_count ic
      WHERE ic.productId NOT IN (SELECT id FROM products)
    ''');

    // sales rows whose barcode does not match any product barcode
    final orphanSales = await db.rawQuery('''
      SELECT s.* FROM sales s
      WHERE s.barcode NOT IN (SELECT barcode FROM products)
    ''');

    // returns rows whose barcode does not match any product barcode
    final orphanReturns = await db.rawQuery('''
      SELECT r.* FROM returns r
      WHERE r.barcode NOT IN (SELECT barcode FROM products)
    ''');

    return IntegrityIssueReport(
      orphanSales: orphanSales,
      orphanReturns: orphanReturns,
      orphanInventoryCounts: orphanCounts,
    );
  }

  /// Throws [ProductReferenceIntegrityException] if no product exists with the
  /// given [barcode]. Must be called inside a transaction ([txn]).
  Future<void> _requireExistingProductByBarcode(
      Transaction txn, String barcode) async {
    final rows =
        await txn.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (rows.isEmpty) {
      throw ProductReferenceIntegrityException(
          'لا يوجد منتج بالباركود "$barcode"');
    }
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;
    final countResult = await db
        .rawQuery('SELECT COUNT(*) as count FROM products WHERE name != ""');
    final totalQtyResult =
        await db.rawQuery('SELECT SUM(currentQuantity) as total FROM products');
    final totalCostResult = await db
        .rawQuery('SELECT SUM(totalInventoryCost) as total FROM products');
    final salesCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE productName != ""');
    final returnsCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM returns WHERE productName != ""');
    final expensesCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE description != ""');

    return {
      'itemCount': (countResult.first['count'] as num?)?.toInt() ?? 0,
      'totalQuantity': (totalQtyResult.first['total'] as num?)?.toInt() ?? 0,
      'totalInventoryValue':
          (totalCostResult.first['total'] as num?)?.toDouble() ?? 0,
      'salesCount': (salesCountResult.first['count'] as num?)?.toInt() ?? 0,
      'returnsCount': (returnsCountResult.first['count'] as num?)?.toInt() ?? 0,
      'expensesCount':
          (expensesCountResult.first['count'] as num?)?.toInt() ?? 0,
    };
  }

  // =================== SALES REPORTS ===================
  Future<List<Map<String, dynamic>>> getSalesGroupByDate(
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    return await db.rawQuery('''
      SELECT date,
             COUNT(*) as transactionCount,
             SUM(quantity) as totalQuantity,
             SUM(totalSaleValue) as totalSales,
             SUM(cogs) as totalCOGS,
             SUM(totalSaleValue) - SUM(cogs) as grossProfit
      FROM sales
      GROUP BY date
      ORDER BY date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getSalesGroupByProduct(
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    return await db.rawQuery('''
      SELECT productName,
             barcode,
             SUM(quantity) as totalQuantity,
             COUNT(*) as transactionCount,
             AVG(salePrice) as avgPrice,
             SUM(totalSaleValue) as totalSales,
             SUM(cogs) as totalCOGS,
             SUM(totalSaleValue) - SUM(cogs) as grossProfit
      FROM sales
      GROUP BY barcode
      ORDER BY totalSales DESC
    ''');
  }

  Future<Map<String, dynamic>> getSalesSummary({UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final totalSalesResult = await db.rawQuery(
        'SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty, COUNT(*) as count FROM sales');
    final totalCOGSResult =
        await db.rawQuery('SELECT SUM(cogs) as total FROM sales');
    final todayResult = await db.rawQuery('''
      SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty
      FROM sales WHERE date(date) = date('now', 'localtime')
    ''');
    final monthResult = await db.rawQuery('''
      SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty
      FROM sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now', 'localtime')
    ''');

    return {
      'totalSales': (totalSalesResult.first['total'] as num?)?.toDouble() ?? 0,
      'totalQty': (totalSalesResult.first['qty'] as num?)?.toInt() ?? 0,
      'totalTransactions':
          (totalSalesResult.first['count'] as num?)?.toInt() ?? 0,
      'totalCOGS': (totalCOGSResult.first['total'] as num?)?.toDouble() ?? 0,
      'grossProfit':
          ((totalSalesResult.first['total'] as num?)?.toDouble() ?? 0) -
              ((totalCOGSResult.first['total'] as num?)?.toDouble() ?? 0),
      'todaySales': (todayResult.first['total'] as num?)?.toDouble() ?? 0,
      'todayQty': (todayResult.first['qty'] as num?)?.toInt() ?? 0,
      'monthSales': (monthResult.first['total'] as num?)?.toDouble() ?? 0,
      'monthQty': (monthResult.first['qty'] as num?)?.toInt() ?? 0,
    };
  }

  // =================== BARCODE GENERATOR ===================
  Future<String> generateBarcode() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as maxId FROM products');
    final maxId = ((result.first['maxId'] as num?)?.toInt() ?? 0) + 1;
    return '200${maxId.toString().padLeft(10, '0')}';
  }

  // =================== CUSTOMERS ===================
  Future<int> insertCustomer(Customer customer, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    final trimmed = customer.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('اسم العميل مطلوب');
    }
    final now = DateTime.now().toIso8601String();
    return await db.transaction((txn) async {
      final id = await txn.insert('customers', {
        'name': trimmed,
        'phone': customer.phone?.trim(),
        'address': customer.address?.trim(),
        'notes': customer.notes?.trim(),
        'isActive': customer.isActive ? 1 : 0,
        'isSystem': customer.isSystem ? 1 : 0,
        'createdAt': now,
        'updatedAt': now,
        'sync_status': EntitySyncStatus.PENDING.label,
      });
      await _enqueueAfterWrite(db, txn,
          tableName: 'customers',
          rowId: id,
          operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps =
        await db.query('customers', orderBy: 'isSystem DESC, name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> getActiveCustomers() async {
    final db = await database;
    final maps = await db.query('customers',
        where: 'isActive = 1', orderBy: 'isSystem DESC, name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps =
        await db.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final maps = await db.query('customers',
        where: 'isActive = 1 AND (name LIKE ? OR phone LIKE ?)',
        whereArgs: [q, q],
        orderBy: 'isSystem DESC, name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<void> updateCustomer(Customer customer,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    if (customer.id == null) {
      throw ArgumentError('Customer id is required for update');
    }
    final trimmed = customer.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('اسم العميل مطلوب');
    }
    final db = await database;
    await db.transaction((txn) async {
      final affected = await txn.update(
        'customers',
        {
          'name': trimmed,
          'phone': customer.phone?.trim(),
          'address': customer.address?.trim(),
          'notes': customer.notes?.trim(),
          'isActive': customer.isActive ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'customers',
            rowId: customer.id!,
            operation: SyncQueueOperation.UPDATE);
      }
    });
  }

  Future<void> archiveCustomer(int customerId, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      throw StateError('العميل غير موجود');
    }
    if (customer.isSystem) {
      throw StateError('لا يمكن أرشفة العميل النظامي');
    }
    await db.transaction((txn) async {
      final affected = await txn.update(
        'customers',
        {
          'isActive': 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (affected > 0) {
        // Customers use soft-state (isActive) rather than tombstones in the
        // local schema; archiving is therefore a normal UPDATE operation.
        await _enqueueAfterWrite(db, txn,
            tableName: 'customers',
            rowId: customerId,
            operation: SyncQueueOperation.UPDATE);
      }
    });
  }

  Future<void> reactivateCustomer(int customerId,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    await db.transaction((txn) async {
      final affected = await txn.update(
        'customers',
        {
          'isActive': 1,
          'updatedAt': DateTime.now().toIso8601String(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (affected > 0) {
        await _enqueueAfterWrite(db, txn,
            tableName: 'customers',
            rowId: customerId,
            operation: SyncQueueOperation.UPDATE);
      }
    });
  }
}

class ProductDeletionException implements Exception {
  final List<String> reasons;
  ProductDeletionException(this.reasons);

  String get message {
    if (reasons.isEmpty) {
      return 'لا يمكن حذف المنتج لوجود معاملات أو سجلات مرتبطة به';
    }
    final joined = reasons.join(' و');
    return 'لا يمكن حذف المنتج لارتباطه بـ $joined سابقة';
  }

  @override
  String toString() => 'ProductDeletionException: $message';
}

class ProductReferenceIntegrityException implements Exception {
  final String message;
  ProductReferenceIntegrityException(this.message);

  @override
  String toString() => 'ProductReferenceIntegrityException: $message';
}

class InsufficientStockException implements Exception {
  final int productId;
  final double availableQuantity;
  final double requestedQuantity;

  InsufficientStockException({
    required this.productId,
    required this.availableQuantity,
    required this.requestedQuantity,
  });

  String get message => 'الكمية المطلوبة غير متوفرة في المخزون';

  @override
  String toString() =>
      'InsufficientStockException: $message (available=$availableQuantity, requested=$requestedQuantity)';
}

class ReturnStockReversalException implements Exception {
  final int returnId;
  final double currentStock;
  final double requiredReversalQuantity;

  ReturnStockReversalException({
    required this.returnId,
    required this.currentStock,
    required this.requiredReversalQuantity,
  });

  String get message =>
      'لا يمكن تعديل المرتجع لأن جزءًا من كميته تم استخدامه من المخزون';

  @override
  String toString() =>
      'ReturnStockReversalException: $message (returnId=$returnId, currentStock=$currentStock, requiredReversal=$requiredReversalQuantity)';
}

/// Thrown when a sales-history read is attempted by a role without the
/// [AppPermission.canViewSalesHistory] permission.
class SalesHistoryAccessDeniedException implements Exception {
  const SalesHistoryAccessDeniedException();

  String get message => 'غير مصرح بمشاهدة سجل المبيعات';

  @override
  String toString() => 'SalesHistoryAccessDeniedException: $message';
}

/// Report returned by [DatabaseHelper.findProductReferenceIntegrityIssues].
class IntegrityIssueReport {
  final List<Map<String, dynamic>> orphanSales;
  final List<Map<String, dynamic>> orphanReturns;
  final List<Map<String, dynamic>> orphanInventoryCounts;

  IntegrityIssueReport({
    required this.orphanSales,
    required this.orphanReturns,
    required this.orphanInventoryCounts,
  });

  bool get hasIssues =>
      orphanSales.isNotEmpty ||
      orphanReturns.isNotEmpty ||
      orphanInventoryCounts.isNotEmpty;

  int get totalOrphans =>
      orphanSales.length + orphanReturns.length + orphanInventoryCounts.length;
}
