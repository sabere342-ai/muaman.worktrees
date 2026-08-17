import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/return_item.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/invoice.dart';
import '../models/user_role.dart';
import '../services/permissions.dart';
import '../services/permission_resolver.dart';
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
    await DatabaseHelper.instance._createDB(db, 7);
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
        version: 7, onCreate: _createDB, onUpgrade: _onUpgrade);
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
        countDate TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await _createUsersTable(db);
    await _createImportBatchesTable(db);
    await _createInvoicesTable(db);
    await _createAppSettingsTable(db);
    await _createRolePermissionsTable(db);
    await _createExpenseCategoriesTable(db);
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
        reconciliation_json TEXT
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
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRolePermissionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        role TEXT PRIMARY KEY,
        permissions TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createExpenseCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
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
        lastLoginAt TEXT
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
    return await db.insert('products', normalized.toMap()..remove('id'));
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
    return await db.update('products', normalized.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
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

      return await txn.delete('products', where: 'id = ?', whereArgs: [id]);
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
    final db = await database;
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, sale.barcode);

      final productMaps = await txn
          .query('products', where: 'barcode = ?', whereArgs: [sale.barcode]);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert('sales', sale.toMap()..remove('id'));

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

      final id = await txn.insert('sales', sale.toMap()..remove('id'));

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

      final invoiceId = await txn.insert('invoices', invoice.toMap());
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

        await txn.insert(
            'sales', item.copyWith(invoiceId: invoiceId).toMap()..remove('id'));

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

      final affectedSale = await txn.update('sales', updatedSale.toMap(),
          where: 'id = ?', whereArgs: [sale.id]);
      if (affectedSale != 1) {
        throw StateError('فشل تحديث سجل البيع');
      }

      return 1;
    });
  }

  Future<int> deleteSale(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteSales);
    final db = await database;
    final saleData = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (saleData.isNotEmpty) {
      final sale = Sale.fromMap(saleData.first);
      await revertSoldQuantity(sale.barcode, sale.quantity);
    }
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
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
    final db = await database;
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, returnItem.barcode);

      final productMaps = await txn.query('products',
          where: 'barcode = ?', whereArgs: [returnItem.barcode]);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert('returns', returnItem.toMap()..remove('id'));

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

      final affectedReturn = await txn.update('returns', updatedReturn.toMap(),
          where: 'id = ?', whereArgs: [returnItem.id]);
      if (affectedReturn != 1) {
        throw StateError('فشل تحديث سجل المرتجع');
      }

      return 1;
    });
  }

  Future<int> deleteReturn(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteReturns);
    final db = await database;
    final data = await db.query('returns', where: 'id = ?', whereArgs: [id]);
    if (data.isNotEmpty) {
      final ret = ReturnItem.fromMap(data.first);
      await revertReturnedQuantity(ret.barcode, ret.quantity);
    }
    return await db.delete('returns', where: 'id = ?', whereArgs: [id]);
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
    return await db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'id ASC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    await _enforceLicensing();
    final db = await database;
    return await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canDeleteExpenses);
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
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
    return await db.insert('expense_categories', {'name': normalized});
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
    return await db.update('expense_categories', {'name': normalized},
        where: 'id = ?', whereArgs: [id]);
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
    return await db
        .delete('expense_categories', where: 'id = ?', whereArgs: [id]);
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

      await txn.insert('inventory_count', {
        'productId': productId,
        'actualQuantity': actualQuantity,
        'notes': notes,
        'countDate': DateTime.now().toIso8601String(),
      });

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
