import 'dart:math';

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
import '../models/cost_history.dart';
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
import '../migration/maintenance_mode.dart';
import '../services/active_shop_context.dart';
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
    // Phase I / D11: while legacy migration maintenance mode is active every
    // business write throws early, so no live data can change between the
    // pinned snapshot and final stamping. Reads remain allowed.
    MigrationMaintenanceMode.ensureWritesAllowed();
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

  /// Current local schema version. Phase M: v15 adds conflict lifecycle +
  /// audit artifacts. Phase P (WS-2): v16 backfills stable client-generated
  /// `cloud_uuid` values on pre-existing tenant rows (data-only migration) so
  /// every synced entity carries a cloud-stable idempotency identity. Phase P
  /// (WS-5): v17 adds the additive `writer_snapshot` column on `sync_queue` to
  /// persist a durable per-write permission/entitlement snapshot. Single
  /// source of truth for openDatabase + test seams.
  ///
  /// v18 (Phase P Group A A3 — P-OD1 local half): ADDITIVE `stock_adjustments`
  /// table carrying the durable local Option C adjustment artifact + the
  /// deterministic adjustment idempotency key, linked to the originating
  /// oversold sale/event. Additive only; upgrades and fresh installs land on
  /// the identical final shape.
  ///
  /// v19 (Phase P Group D D1 — P-OD4): ADDITIVE `cost_history` table recording
  /// durable cost-price change events per product. Provides auditable
  /// traceability for product cost changes while preserving historical sale
  /// cost snapshots untouched.
  static const int schemaVersion = 19;

  /// UUIDv4-shaped token generator (Phase M §24 / INV-M19). Used for both
  /// sync occurrence tokens and client-generated entity `cloud_uuid` values
  /// (Phase P WS-2). No external dependencies, matching the house pattern in
  /// migration_orchestrator.dart.
  static String _mintUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static String _generateOccurrenceToken() => _mintUuidV4();

  /// Registers the active-shop provider used to stamp sync queue entries.
  static void setSyncShopIdProvider(Future<String?> Function() provider) {
    _syncShopIdProvider = provider;
  }

  /// Removes the active-shop provider. For test teardown only.
  static void clearSyncShopIdProvider() {
    _syncShopIdProvider = null;
  }

  /// Phase P (WS-5): supplies the ACTIVE WRITER identity at enqueue time so
  /// each queue entry carries a durable per-write permission/entitlement
  /// snapshot (revoked-seller adjudication). Registered once during app
  /// startup; reads the live session each call. When null, the snapshot still
  /// records the database-layer facts (permission granted, entitlement active,
  /// shop/entity identity, write instant) but no writer identity.
  static Future<Map<String, dynamic>> Function()? _writerSnapshotProvider;

  /// Registers the active-writer identity provider used to enrich per-write
  /// permission snapshots on sync queue entries (WS-5).
  static void setWriterSnapshotProvider(
      Future<Map<String, dynamic>> Function() provider) {
    _writerSnapshotProvider = provider;
  }

  /// Removes the active-writer identity provider. For test teardown only.
  static void clearWriterSnapshotProvider() {
    _writerSnapshotProvider = null;
  }

  // =================== TENANT ISOLATION (Phase J / WS2–WS4) ===================

  /// Whether strict shop-scoped tenant isolation is armed. Armed exclusively
  /// through [TenantIsolationGate] once the Phase I migration handoff
  /// preconditions pass (plan §N). While DISARMED every read/write path keeps
  /// its legacy behavior so pre-cloud installs are unaffected (compatibility
  /// switch, plan §L).
  static bool _tenantIsolationArmed = false;

  /// Arms/disarms strict tenant filtering. Production code must go through
  /// [TenantIsolationGate]; the direct setter exists for the gate itself and
  /// for tests.
  static void setTenantIsolationArmed(bool armed) {
    _tenantIsolationArmed = armed;
  }

  static bool get tenantIsolationArmed => _tenantIsolationArmed;

  /// Tenant predicate for reads. Legacy mode → no predicate. Armed without an
  /// authorized shop → deny-all predicate: reads fail CLOSED to empty and
  /// never fall back to unscoped access (plan §H standing rule).
  _TenantPredicate _readPredicate() {
    if (!_tenantIsolationArmed) return _TenantPredicate.none;
    return _predicateForContext();
  }

  /// Tenant predicate for mutations. Armed without an authorized shop throws
  /// so a business write can never land silently as local-only/unattributed.
  _TenantPredicate _writePredicate() {
    final p = _readPredicate();
    if (p.deniesAll) {
      throw const TenantIsolationException(
          'لا يوجد متجر مصرح به لتنفيذ هذه العملية');
    }
    return p;
  }

  _TenantPredicate _predicateForContext() {
    final shop = ActiveShopContext.instance.shopId;
    if (shop == null || shop.isEmpty) return _TenantPredicate.denyAll;
    return _TenantPredicate.scoped(shop);
  }

  /// Surfaces a cross-shop mutation attempt instead of letting it masquerade
  /// as a benign "row not found" no-op (plan §K: zero-row mutation of a row
  /// that exists OUTSIDE the active shop must be an explicit ownership error).
  Future<void> _assertNotForeignRow(DatabaseExecutor executor, String table,
      int id, _TenantPredicate p) async {
    if (!p.isScoped) return;
    final rows =
        await executor.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      throw TenantOwnershipException(
          'هذا السجل لا ينتمي إلى المتجر النشط ($table #$id)');
    }
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

  /// Phase M deterministic idempotency key (plan §24 / DR-M04).
  ///
  /// Conceptual form: `entityUuid:operation:occurrenceToken`.
  ///
  /// The occurrence token is generated ONCE per logical operation and
  /// PERSISTED on the sync_queue row (`occurrence_token` column), so process
  /// restart, transport retry, response loss, and worker restart all resend
  /// the SAME logical idempotency key. Distinct logical events (a new user
  /// action) get distinct tokens; the same event can never mint a second key.
  static String _generateSyncKey(
      String entityType, String entityUuid, SyncQueueOperation operation,
      {String? occurrenceToken}) {
    final token = occurrenceToken ?? _generateOccurrenceToken();
    return '$entityType:$entityUuid:${operation.label}:$token';
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

    // Phase P (WS-2): every synced entity must carry a stable client-generated
    // cloud_uuid. When the write did not already mint one (legacy rows,
    // raw-executor inserts), mint it here — inside the caller's transaction,
    // BEFORE the queue row is created — and persist it back onto the row so
    // the idempotency identity is durable beyond the queue. The DELETE path
    // uses the pre-delete snapshot (the row is gone; nothing to persist) but
    // still keys on a stable UUID so server-side dedup keeps working.
    String cloudUuid = row['cloud_uuid'] as String? ?? '';
    final isDeleteSnapshot = existingRow != null;
    if (cloudUuid.isEmpty) {
      cloudUuid = _mintUuidV4();
      if (!isDeleteSnapshot) {
        await executor.update(tableName, {'cloud_uuid': cloudUuid},
            where: 'id = ?', whereArgs: [rowId]);
      }
    }

    final payload = <String, dynamic>{
      'id': rowId,
      'cloud_uuid': cloudUuid,
      'server_version': (row['server_version'] as num?)?.toInt() ?? 0,
      ...adapter.localToCloudPayload(row),
    };

    // Phase P (WS-5): durable per-write permission/entitlement snapshot,
    // captured HERE at enqueue time (post-guard). `_enforceLicensing` and the
    // enclosing method's `_requirePermission` have already run without
    // throwing for this write, so the snapshot truthfully records an active
    // entitlement with the entity's required permission granted. Writer
    // identity is enriched when the session provider is registered.
    final writerIdentityProvider = _writerSnapshotProvider;
    final writerIdentity =
        writerIdentityProvider != null ? await writerIdentityProvider() : null;
    final writerSnapshot = <String, dynamic>{
      'entity_type': adapter.entityType.label,
      'operation': operation.label,
      'permission_granted': true,
      'permission_required': adapter.requiredPermission,
      'entitlement_active': true,
      'shop_id': shopId,
      'entity_uuid': cloudUuid,
      'written_at': DateTime.now().toIso8601String(),
    };
    if (writerIdentity != null && writerIdentity.isNotEmpty) {
      writerSnapshot['writer'] = writerIdentity;
    }

    // Phase M: the occurrence token is minted once per logical operation and
    // persisted with the queue row (INV-M19). Retries/replays reuse it.
    final occurrenceToken = _generateOccurrenceToken();
    final entityUuid = cloudUuid;

    await _syncQueueRepository(db).enqueue(
      entityType: adapter.entityType.label,
      entityId: rowId,
      operation: operation,
      payload: payload,
      idempotencyKey: _generateSyncKey(
          adapter.entityType.label, entityUuid, operation,
          occurrenceToken: occurrenceToken),
      shopId: shopId,
      executor: executor,
      occurrenceToken: occurrenceToken,
      writerSnapshot: writerSnapshot,
    );
  }

  /// Phase N (N-D13): narrow seam for callers that insert business rows with
  /// a raw [DatabaseExecutor] (the workbook importer) and must enqueue the
  /// resulting rows through the SAME machinery as normal writes, inside the
  /// caller's open transaction. Preserves idempotency keys, persisted
  /// occurrence tokens and shop attribution unchanged.
  Future<void> enqueueImportedRowForSync(
    Database db,
    DatabaseExecutor executor, {
    required String tableName,
    required int rowId,
  }) {
    return _enqueueAfterWrite(db, executor,
        tableName: tableName,
        rowId: rowId,
        operation: SyncQueueOperation.CREATE);
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
    if (oldVersion < 14) {
      await _migrateToV14(db);
    }
    if (oldVersion < 15) {
      await _migrateToV15(db);
    }
    if (oldVersion < 16) {
      await _migrateToV16(db);
    }
    if (oldVersion < 17) {
      await _migrateToV17(db);
    }
    if (oldVersion < 18) {
      await _migrateToV18(db);
    }
    if (oldVersion < 19) {
      await _migrateToV19(db);
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
    await DatabaseHelper.instance._createDB(db, schemaVersion);
    await DatabaseHelper.instance._migrateToV13(db);
    await DatabaseHelper.instance._migrateToV14(db);
    if (schemaVersion >= 15) {
      await DatabaseHelper.instance._migrateToV15(db);
    }
    if (schemaVersion >= 16) {
      await DatabaseHelper.instance._migrateToV16(db);
    }
    if (schemaVersion >= 17) {
      await DatabaseHelper.instance._migrateToV17(db);
    }
    if (schemaVersion >= 18) {
      await DatabaseHelper.instance._migrateToV18(db);
    }
    if (schemaVersion >= 19) {
      await DatabaseHelper.instance._migrateToV19(db);
    }
    await db.rawUpdate('PRAGMA user_version = $schemaVersion');
  }

  /// Test-only seam: runs ONLY the production v14 → v15 additive migration
  /// step against a database already at the v14 shape (user_version 14), so
  /// upgrade-path behavior is exercised without replaying older history.
  @visibleForTesting
  static Future<void> runUpgradeToV15ForTest(Database db) async {
    await DatabaseHelper.instance._migrateToV15(db);
  }

  /// Test-only seam: runs ONLY the production v15 → v16 data-backfill step
  /// against a database already at the v15 shape (user_version 15), so the
  /// cloud_uuid backfill is exercised without replaying older history.
  @visibleForTesting
  static Future<void> runUpgradeToV16ForTest(Database db) async {
    await DatabaseHelper.instance._migrateToV16(db);
  }

  /// Test-only seam: runs ONLY the production v16 → v17 additive migration
  /// step against a database already at the v16 shape (user_version 16), so
  /// the sync_queue writer_snapshot column is exercised without replaying
  /// older history.
  @visibleForTesting
  static Future<void> runUpgradeToV17ForTest(Database db) async {
    await DatabaseHelper.instance._migrateToV17(db);
  }

  /// Test-only seam: runs ONLY the production v17 → v18 additive migration
  /// step against a database already at the v17 shape (user_version 17), so
  /// the durable `stock_adjustments` table is exercised without replaying
  /// older history.
  @visibleForTesting
  static Future<void> runUpgradeToV18ForTest(Database db) async {
    await DatabaseHelper.instance._migrateToV18(db);
  }

  /// Test-only seam: runs ONLY the production v18 → v19 additive migration
  /// step against a database already at the v18 shape (user_version 18), so
  /// the durable `cost_history` table is exercised without replaying
  /// older history.
  @visibleForTesting
  static Future<void> runUpgradeToV19ForTest(Database db) async {
    await DatabaseHelper.instance._migrateToV19(db);
  }

  /// Returns the full filesystem path to `muaman_store.db`.
  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'muaman_store.db');
  }

  /// Test-only seam: runs ONLY the production fresh-install path
  /// (`onCreate`) exactly as `openDatabase(version: schemaVersion)`
  /// executes it — no migration replay. Used by the W1 parity test to
  /// prove that a fresh database is byte-equivalent in shape to an
  /// upgraded one at the current schema version.
  @visibleForTesting
  static Future<void> runFreshOnCreateForTest(Database db,
      {int version = schemaVersion}) async {
    await DatabaseHelper.instance._createDB(db, version);
    await db.rawUpdate('PRAGMA user_version = $version');
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
        version: schemaVersion, onCreate: _createDB, onUpgrade: _onUpgrade);
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
    await _createLegacyMigrationProgressTable(db);

    // Phase K / W1 (plan D3): fresh installs MUST land on the exact same
    // v14 shape as upgrade installs. Android ships as fresh installs taking
    // this path, so the v13 artifacts (sync_queue, indexes and sync columns
    // on the 12 tenant-owned tables) are created here as well. The migration
    // is idempotent (IF NOT EXISTS + per-column guards), so replaying it on
    // an already-complete shape is safe.
    await _migrateToV13(db);

    // Phase M: fresh installs land directly on the v15 shape (additive
    // conflict-lifecycle artifacts) when the target version asks for it.
    if (version >= 15) {
      await _migrateToV15(db);
    }

    // Phase P (WS-2): v16 is a data-only backfill (no schema delta) so a fresh
    // install has nothing to fill; the call keeps fresh/upgrade parity exact.
    if (version >= 16) {
      await _migrateToV16(db);
    }

    // Phase P (WS-5): v17 adds the sync_queue writer_snapshot column. On a
    // fresh install the queue table is empty, so the additive column is all
    // that is needed; the call keeps fresh/upgrade parity exact.
    if (version >= 17) {
      await _migrateToV17(db);
    }

    // Phase P Group A A3 (P-OD1 local half): v18 adds the durable local
    // `stock_adjustments` table. On a fresh install the table is created
    // empty; the additive call keeps fresh/upgrade parity exact.
    if (version >= 18) {
      await _migrateToV18(db);
    }

    // Phase P Group D D1 (P-OD4): v19 adds the additive `cost_history` table
    // recording durable cost-price change events per product. On a fresh
    // install the table is created empty; the additive call keeps
    // fresh/upgrade parity exact.
    if (version >= 19) {
      await _migrateToV19(db);
    }

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

  /// Phase I / D8: schema v13 → v14 adds ONE local bookkeeping table,
  /// `legacy_migration_progress` (durable migration checkpoints). No existing
  /// table is altered — the upgrade is purely additive.
  Future<void> _migrateToV14(Database db) async {
    await _createLegacyMigrationProgressTable(db);
  }

  Future<void> _createLegacyMigrationProgressTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS legacy_migration_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id TEXT NOT NULL UNIQUE,
        shop_id TEXT NOT NULL,
        phase TEXT NOT NULL,
        status TEXT NOT NULL,
        snapshot_path TEXT,
        snapshot_sha256 TEXT,
        last_table TEXT,
        last_local_id INTEGER,
        stats_json TEXT,
        started_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_legacy_migration_progress_shop ON legacy_migration_progress(shop_id)');
  }

  /// Phase M (plan §26 / DR-M11/D DR-M13): schema v14 → v15 is ADDITIVE
  /// ONLY — no renames, no drops, no destructive rewrite.
  ///
  /// Adds:
  ///   - `sync_queue.resolution_status`  : conflict lifecycle beyond the
  ///     legacy terminal CONFLICT status (CL-1..CL-3). Legacy CONFLICT rows
  ///     backfill to 'REVIEW_REQUIRED' (CL-4).
  ///   - `sync_queue.occurrence_token`   : persisted deterministic event
  ///     identity for idempotency keys (INV-M19).
  ///   - `conflict_audit` table          : durable conflict evidence that
  ///     survives queue cleanup (AU-1, INV-M18).
  Future<void> _migrateToV15(Database db) async {
    final queueInfo = await db.rawQuery('PRAGMA table_info(sync_queue)');
    final queueColumns = queueInfo.map((r) => r['name'] as String).toSet();
    if (!queueColumns.contains('resolution_status')) {
      await db
          .execute('ALTER TABLE sync_queue ADD COLUMN resolution_status TEXT');
    }
    if (!queueColumns.contains('occurrence_token')) {
      await db
          .execute('ALTER TABLE sync_queue ADD COLUMN occurrence_token TEXT');
    }

    // CL-4: legacy terminal CONFLICT rows upgrade safely to review semantics.
    await db
        .execute("UPDATE sync_queue SET resolution_status = 'REVIEW_REQUIRED' "
            "WHERE status = 'CONFLICT' AND resolution_status IS NULL");

    await _createConflictAuditTable(db);
  }

  Future<void> _createConflictAuditTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conflict_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        entity_uuid TEXT,
        product_name TEXT,
        product_barcode TEXT,
        operation TEXT NOT NULL,
        local_before TEXT,
        local_after TEXT,
        server_before TEXT,
        server_after TEXT,
        related_event_ids TEXT,
        local_version INTEGER,
        server_version INTEGER,
        idempotency_key TEXT,
        detected_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'REVIEW_REQUIRED',
        resolution_method TEXT,
        resolved_by_user TEXT,
        resolved_at TEXT,
        resolution_note TEXT,
        resulting_adjustment_id INTEGER
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_conflict_audit_shop ON conflict_audit(shop_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_conflict_audit_entity ON conflict_audit(entity_type, entity_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_conflict_audit_status ON conflict_audit(status)');
  }

  /// Phase P (plan §F.3 / WS-2): schema v15 → v16 is DATA-ONLY (no column or
  /// table changes — the `cloud_uuid` columns already exist since v9).
  ///
  /// Backfills a stable client-generated `cloud_uuid` onto every pre-existing
  /// tenant-owned row that is missing one, so the entire local store carries a
  /// cloud-stable idempotency identity after upgrade. Existing values are
  /// never overwritten. The same migration replays harmlessly on a fresh
  /// install (zero rows to backfill), keeping fresh-create parity intact.
  Future<void> _migrateToV16(Database db) async {
    // Primary key by table: most tenant tables use `id`, but role_permissions
    // and app_settings use their natural keys.
    const pkColumn = <String, String>{
      'role_permissions': 'role',
      'app_settings': 'key',
    };
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

    await db.transaction((txn) async {
      for (final table in syncTables) {
        final info = await txn.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        if (!columns.contains('cloud_uuid')) {
          continue;
        }
        final pk = pkColumn[table] ?? 'id';
        final rows = await txn.rawQuery(
            'SELECT $pk FROM $table WHERE cloud_uuid IS NULL OR cloud_uuid = \'\'');
        for (final row in rows) {
          final key = row[pk];
          if (key == null) continue;
          await txn.rawUpdate('UPDATE $table SET cloud_uuid = ? WHERE $pk = ?',
              [_mintUuidV4(), key]);
        }
      }
    });
  }

  /// Phase P (plan §F.6 / WS-5): schema v16 → v17 is a single ADDITIVE column
  /// on `sync_queue` (`writer_snapshot`) that persists the durable per-write
  /// permission/entitlement snapshot stamped at enqueue time. Old queue rows
  /// keep NULL (fromMap reads them safely); the migration replays harmlessly
  /// on fresh installs (column present → no-op), keeping fresh/upgrade parity.
  Future<void> _migrateToV17(Database db) async {
    final queueInfo = await db.rawQuery('PRAGMA table_info(sync_queue)');
    final queueColumns = queueInfo.map((r) => r['name'] as String).toSet();
    if (!queueColumns.contains('writer_snapshot')) {
      await db
          .execute('ALTER TABLE sync_queue ADD COLUMN writer_snapshot TEXT');
    }
    SyncQueueRepository.invalidateShapeCache(db);
  }

  /// Phase P Group A A3 (P-OD1 local half): schema v17 → v18 is a single
  /// ADDITIVE table — `stock_adjustments` — holding the durable local Option C
  /// adjustment artifact produced when a drained sale/event returns `OVERSOLD`.
  ///
  /// The row carries the owning shop, the originating sale/event identity, the
  /// product/barcode, the server-authoritative projected stock, the shortfall
  /// (strictly positive), the related event ids, a deterministic adjustment
  /// idempotency key (bound durably to the governing sale), the adjustment
  /// lifecycle status, the server adjustment uuid once synced, and the creation
  /// timestamp. Additive only: existing installs upgrade safely, and the same
  /// table is created on fresh installs (`_createDB` path), keeping parity
  /// exact. Old stock-adjustment rows are never rewritten.
  Future<void> _migrateToV18(Database db) async {
    await _createStockAdjustmentsTable(db);
  }

  /// Phase P Group D D1 (P-OD4): schema v18 → v19 is a single ADDITIVE table
  /// — `cost_history` — holding durable cost-price change events per product.
  ///
  /// Each row captures: the owning shop, the product identity, the old cost,
  /// the new cost, a change timestamp, and optionally the actor who performed
  /// the change. Historical sale cost snapshots are NEVER rewritten. Additive
  /// only: existing installs upgrade safely, and the same table is created on
  /// fresh installs (`_createDB` path), keeping parity exact. Old cost-history
  /// rows are never rewritten.
  Future<void> _migrateToV19(Database db) async {
    await _createCostHistoryTable(db);
  }

  Future<void> _createStockAdjustmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id TEXT NOT NULL,
        sale_id INTEGER,
        return_id INTEGER,
        product_barcode TEXT NOT NULL,
        product_id TEXT,
        projected_current INTEGER NOT NULL,
        shortfall INTEGER NOT NULL,
        related_event_ids TEXT,
        idempotency_key TEXT,
        status TEXT NOT NULL DEFAULT 'OPEN',
        cloud_uuid TEXT,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_adj_shop ON stock_adjustments(shop_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_adj_sale ON stock_adjustments(sale_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_adj_idem ON stock_adjustments(idempotency_key)');
  }

  Future<void> _createCostHistoryTable(Database db) async {
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

    if (product.costPrice.isNaN || product.costPrice.isInfinite) {
      throw ArgumentError('سعر التكلفة غير صالح');
    }

    if (product.costPrice <= 0) {
      throw ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر');
    }

    final db = await database;
    final tp = _writePredicate();

    final dup = await db.rawQuery(
        'SELECT id FROM products WHERE ${tp.prefix('trim(barcode) = ?')} LIMIT 1',
        tp.argsWith([trimmedBarcode]));
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
          ...tp.stamp(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
      );
      await _enqueueAfterWrite(db, txn,
          tableName: 'products',
          rowId: id,
          operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('products',
        where: tp.clause, whereArgs: tp.args, orderBy: 'id ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('products',
        where: tp.prefix('barcode = ?'),
        whereArgs: tp.argsWith([barcode]),
        limit: 1);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getProductByName(String name) async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('products',
        where: tp.prefix('name = ?'), whereArgs: tp.argsWith([name]), limit: 1);
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

    if (product.costPrice.isNaN || product.costPrice.isInfinite) {
      throw ArgumentError('سعر التكلفة غير صالح');
    }

    if (product.costPrice <= 0) {
      throw ArgumentError('يجب أن تكون تكلفة الصنف أكبر من صفر');
    }

    final db = await database;
    final tp = _writePredicate();

    // Duplicate check runs INSIDE the active shop's scope (plan §M); the
    // global UNIQUE constraint remains the cross-shop backstop (Z-1 GLOBAL).
    final dup = await db.rawQuery(
        'SELECT id FROM products WHERE ${tp.prefix('trim(barcode) = ? AND id != ?')}',
        tp.argsWith([trimmedBarcode, product.id]));
    if (dup.isNotEmpty) {
      throw ArgumentError('الباركود موجود مسبقًا');
    }

    final normalized = product.copyWith(
      name: trimmedName,
      barcode: trimmedBarcode,
    );
    return await db.transaction((txn) async {
      // Fetch the current product to detect cost changes.
      final existingMaps = await txn.query('products',
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([product.id]),
          limit: 1);

      final affected = await txn.update(
          'products',
          {
            ...normalized.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([product.id]));
      if (affected == 0) {
        await _assertNotForeignRow(txn, 'products', product.id!, tp);
      }

      // Phase P Group D D1 (P-OD4): Record cost history if cost changed.
      // Executed inside the same transaction for atomicity. The shop id is
      // derived from the tenant authority: the scoped predicate when isolation
      // is armed, otherwise the active shop context (legacy mode). When no
      // tenant context is available the record is skipped so no unattributed
      // history row is ever created (fail-closed tenant safety).
      if (affected > 0 && existingMaps.isNotEmpty) {
        final existing = Product.fromMap(existingMaps.first);
        if (existing.costPrice != normalized.costPrice) {
          final shopId = tp.isScoped
              ? tp.args.first as String
              : ActiveShopContext.instance.shopId;
          if (shopId != null && shopId.isNotEmpty) {
            await recordCostChange(
              txn,
              shopId: shopId,
              productId: product.id!,
              productName: normalized.name,
              productBarcode: normalized.barcode,
              oldCost: existing.costPrice,
              newCost: normalized.costPrice,
            );
          }
        }
      }

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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final productMaps = await txn.query('products',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]), limit: 1);
      if (productMaps.isEmpty) {
        await _assertNotForeignRow(txn, 'products', id, tp);
        return 0;
      }
      final product = Product.fromMap(productMaps.first);

      final List<String> references = [];

      // Reference scans run within the active shop's scope so another shop's
      // history cannot block (or be disclosed by) this deletion.
      final saleRows = await txn.query('sales',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([product.barcode]),
          limit: 1);
      if (saleRows.isNotEmpty) references.add('مبيعات');

      final returnRows = await txn.query('returns',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([product.barcode]),
          limit: 1);
      if (returnRows.isNotEmpty) references.add('مرتجعات');

      final countRows = await txn.query('inventory_count',
          where: tp.prefix('productId = ?'),
          whereArgs: tp.argsWith([id]),
          limit: 1);
      if (countRows.isNotEmpty) references.add('جرد مخزون');

      if (references.isNotEmpty) {
        throw ProductDeletionException(references);
      }

      final affected = await txn.delete('products',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
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
      await _scopedProductAdjustment(db, product.barcode, {
        'soldQuantity': newSold,
        'currentQuantity': newCurrent,
        'totalInventoryCost': newCurrent * product.costPrice,
      });
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
      await _scopedProductAdjustment(db, product.barcode, {
        'soldQuantity': newSold,
        'currentQuantity': newCurrent,
        'totalInventoryCost': newCurrent * product.costPrice,
      });
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
      await _scopedProductAdjustment(db, product.barcode, {
        'returnedQuantity': newReturned,
        'currentQuantity': newCurrent,
        'totalInventoryCost': newCurrent * product.costPrice,
      });
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
      await _scopedProductAdjustment(db, product.barcode, {
        'returnedQuantity': newReturned,
        'currentQuantity': newCurrent,
        'totalInventoryCost': newCurrent * product.costPrice,
      });
    }
  }

  /// Applies a stock-adjustment update to a product already resolved through
  /// the tenant-scoped read path. The predicate keeps the write scoped too.
  Future<void> _scopedProductAdjustment(
      Database db, String barcode, Map<String, Object?> values) async {
    final tp = _writePredicate();
    await db.update(
      'products',
      values,
      where: tp.prefix('barcode = ?'),
      whereArgs: tp.argsWith([barcode]),
    );
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, sale.barcode, tp);

      final productMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([sale.barcode]),
          limit: 1);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert(
        'sales',
        {
          ...sale.toMap()..remove('id'),
          ...tp.stamp(),
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
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([product.id]),
      );

      return id;
    });
  }

  Future<int> insertSaleAndDecrementStock(Sale sale,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateSales);
    final db = await database;
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      if (sale.quantity <= 0) {
        throw ArgumentError('Sale quantity must be greater than zero');
      }
      if (sale.salePrice <= 0) {
        throw ArgumentError('يجب أن يكون سعر البيع أكبر من صفر');
      }

      final productMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([sale.barcode]),
          limit: 1);

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
          ...tp.stamp(),
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
        where: tp.prefix('id = ? AND currentQuantity >= ?'),
        whereArgs: tp.argsWith([product.id, sale.quantity]),
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
    final tp = _writePredicate();
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
          ...tp.stamp(),
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

        final productMaps = await txn.query('products',
            where: tp.prefix('barcode = ?'),
            whereArgs: tp.argsWith([item.barcode]),
            limit: 1);
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
            ...tp.stamp(),
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
    final tp = _readPredicate();
    final maps = await db.query('sales',
        where: tp.clause, whereArgs: tp.args, orderBy: 'id ASC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  /// Loads a single invoice header. Gated by [canViewSalesHistory] like every
  /// other sales-history read, so a previous invoice can never be loaded for an
  /// unauthorized role even through a direct route. Tenant-scoped under armed
  /// isolation: another shop's invoice id resolves to null.
  Future<Invoice?> getInvoiceById(int id, {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('invoices',
        where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]), limit: 1);
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// Loads the sale rows of an invoice in insertion order. Gated by
  /// [canViewSalesHistory].
  Future<List<Sale>> getSalesByInvoiceId(int invoiceId,
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('sales',
        where: tp.prefix('invoiceId = ?'),
        whereArgs: tp.argsWith([invoiceId]),
        orderBy: 'id ASC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end,
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('sales',
        where: tp.prefix('date BETWEEN ? AND ?'),
        whereArgs:
            tp.argsWith([start.toIso8601String(), end.toIso8601String()]),
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final oldData = await txn.query('sales',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([sale.id]));

      if (oldData.isEmpty) {
        await _assertNotForeignRow(txn, 'sales', sale.id!, tp);
        throw StateError('السجل المطلوب تعديله غير موجود');
      }

      final old = Sale.fromMap(oldData.first);
      final oldBarcode = old.barcode;

      final oldProductMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([oldBarcode]),
          limit: 1);
      if (oldProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج القديم للبيع غير موجود');
      }
      final oldProduct = Product.fromMap(oldProductMaps.first);

      await _requireExistingProductByBarcode(txn, trimmedBarcode, tp);

      final newProductMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([trimmedBarcode]),
          limit: 1);
      if (newProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج الجديد للبيع غير موجود');
      }
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
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([sale.id]));
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final saleData = await txn.query('sales',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
      if (saleData.isEmpty) {
        await _assertNotForeignRow(txn, 'sales', id, tp);
        return 0;
      }
      final sale = Sale.fromMap(saleData.first);

      // Inline revert of the sold quantity (same math as
      // [revertSoldQuantity]) so the deletion and its queue entry commit or
      // roll back as one unit.
      final productMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([sale.barcode]),
          limit: 1);
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
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([sale.barcode]),
        );
      }

      final affected = await txn.delete('sales',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
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
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT SUM(totalSaleValue) as total FROM sales${tp.toSqlWhere()}',
        tp.args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCOGS() async {
    final db = await database;
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT SUM(cogs) as total FROM sales${tp.toSqlWhere()}', tp.args);
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      await _requireExistingProductByBarcode(txn, returnItem.barcode, tp);

      final productMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([returnItem.barcode]),
          limit: 1);
      final product = Product.fromMap(productMaps.first);

      final id = await txn.insert(
        'returns',
        {
          ...returnItem.toMap()..remove('id'),
          ...tp.stamp(),
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
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([product.id]),
      );

      return id;
    });
  }

  Future<List<ReturnItem>> getAllReturns() async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('returns',
        where: tp.clause, whereArgs: tp.args, orderBy: 'id ASC');
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final oldData = await txn.query('returns',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([returnItem.id]));

      if (oldData.isEmpty) {
        await _assertNotForeignRow(txn, 'returns', returnItem.id!, tp);
        throw StateError('السجل المطلوب تعديله غير موجود');
      }

      final old = ReturnItem.fromMap(oldData.first);
      final oldBarcode = old.barcode;

      final oldProductMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([oldBarcode]),
          limit: 1);
      if (oldProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج القديم للمرتجع غير موجود');
      }
      final oldProduct = Product.fromMap(oldProductMaps.first);

      await _requireExistingProductByBarcode(txn, trimmedBarcode, tp);

      final newProductMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([trimmedBarcode]),
          limit: 1);
      if (newProductMaps.isEmpty) {
        throw ProductReferenceIntegrityException(
            'المنتج الجديد للمرتجع غير موجود');
      }
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
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([returnItem.id]));
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final data = await txn.query('returns',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
      if (data.isEmpty) {
        await _assertNotForeignRow(txn, 'returns', id, tp);
        return 0;
      }
      final ret = ReturnItem.fromMap(data.first);

      // Inline revert of the returned quantity (same math as
      // [revertReturnedQuantity]) so the deletion and its queue entry commit
      // or roll back as one unit.
      final productMaps = await txn.query('products',
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([ret.barcode]),
          limit: 1);
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
          where: tp.prefix('barcode = ?'),
          whereArgs: tp.argsWith([ret.barcode]),
        );
      }

      final affected = await txn.delete('returns',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
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
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT SUM(totalReturnValue) as total FROM returns${tp.toSqlWhere()}',
        tp.args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalReturnedCOGS() async {
    final db = await database;
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT SUM(returnedCogs) as total FROM returns${tp.toSqlWhere()}',
        tp.args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // =================== EXPENSES ===================
  Future<int> insertExpense(Expense expense, {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canCreateExpenses);
    final db = await database;
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final id = await txn.insert(
        'expenses',
        {
          ...expense.toMap()..remove('id'),
          ...tp.stamp(),
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
    final tp = _readPredicate();
    final maps = await db.query('expenses',
        where: tp.clause, whereArgs: tp.args, orderBy: 'id ASC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    await _enforceLicensing();
    final db = await database;
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final affected = await txn.update(
          'expenses',
          {
            ...expense.toMap(),
            'sync_status': EntitySyncStatus.PENDING.label,
          },
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([expense.id]));
      if (affected == 0) {
        await _assertNotForeignRow(txn, 'expenses', expense.id!, tp);
      }
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final existing = await txn.query('expenses',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]), limit: 1);
      if (existing.isEmpty) {
        await _assertNotForeignRow(txn, 'expenses', id, tp);
        return 0;
      }
      final affected = await txn.delete('expenses',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
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
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses${tp.toSqlWhere()}', tp.args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // =================== EXPENSE CATEGORIES ===================
  Future<int> insertExpenseCategory(ExpenseCategory category,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canManageUsers);
    final db = await database;
    final tp = _writePredicate();
    final normalized = ExpenseCategory.normalize(category.name);
    if (ExpenseCategory.isBlankName(normalized)) {
      throw ArgumentError('اسم التصنيف لا يمكن أن يكون فارغاً');
    }
    // Names are shop-local business data (plan §M PER_SHOP semantics): the
    // duplicate check runs inside the active shop's scope only.
    final existing = await db.query('expense_categories',
        where: tp.prefix('LOWER(name) = LOWER(?)'),
        whereArgs: tp.argsWith([normalized]));
    if (existing.isNotEmpty) {
      throw ArgumentError('التصنيف "$normalized" موجود بالفعل');
    }
    return await db.transaction((txn) async {
      final id = await txn
          .insert('expense_categories', {...tp.stamp(), 'name': normalized});
      await _enqueueAfterWrite(db, txn,
          tableName: 'expense_categories',
          rowId: id,
          operation: SyncQueueOperation.CREATE);
      return id;
    });
  }

  Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('expense_categories',
        where: tp.clause, whereArgs: tp.args, orderBy: 'id ASC');
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  Future<int> renameExpenseCategory(int id, String newName,
      {UserRole? currentRole}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canManageUsers);
    final db = await database;
    final tp = _writePredicate();
    final normalized = ExpenseCategory.normalize(newName);
    if (ExpenseCategory.isBlankName(normalized)) {
      throw ArgumentError('اسم التصنيف لا يمكن أن يكون فارغاً');
    }
    final existing = await db.query('expense_categories',
        where: tp.prefix('LOWER(name) = LOWER(?) AND id != ?'),
        whereArgs: tp.argsWith([normalized, id]));
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
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([id]));
      if (affected == 0) {
        await _assertNotForeignRow(txn, 'expense_categories', id, tp);
      }
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
    final tp = _writePredicate();
    final category = await db.query('expense_categories',
        where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
    if (category.isEmpty) {
      await _assertNotForeignRow(db, 'expense_categories', id, tp);
      throw ArgumentError('التصنيف غير موجود');
    }
    final categoryName = category.first['name'] as String;
    // Usage count is computed within the active shop's scope (plan §J).
    final usageCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE ${tp.prefix('category = ?')}',
        tp.argsWith([categoryName]));
    final count = (usageCount.first['count'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      throw StateError(
          'لا يمكن حذف التصنيف "$categoryName" لأنه مستخدم في $count مصروف');
    }
    return await db.transaction((txn) async {
      final affected = await txn.delete('expense_categories',
          where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]));
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
    final tp = _readPredicate();
    final result = await db.rawQuery(
        'SELECT DISTINCT category FROM expenses WHERE ${tp.prefix('category IS NOT NULL AND category != ""')} ORDER BY category ASC',
        tp.args);
    return result.map((row) => row['category'] as String).toList();
  }

  // =================== INVENTORY COUNT ===================
  /// [observedAt] is the device time of the PHYSICAL count observation
  /// (Phase M §18 IC-1). It travels with the count event as the causal
  /// anchor for server-side (observed_at, arrival) ordering; it defaults
  /// to the save moment when the caller cannot supply a better one.
  Future<int> saveInventoryCount(
      int productId, int actualQuantity, String notes,
      {UserRole? currentRole, DateTime? observedAt}) async {
    await _enforceLicensing();
    _requirePermission(currentRole, AppPermission.canAccessStocktake);
    final db = await database;
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      if (actualQuantity < 0) {
        throw ArgumentError('الكمية الفعلية لا يمكن أن تكون سالبة');
      }

      final productMaps = await txn.query('products',
          where: tp.prefix('id = ?'),
          whereArgs: tp.argsWith([productId]),
          limit: 1);

      if (productMaps.isEmpty) {
        await _assertNotForeignRow(txn, 'products', productId, tp);
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
        ...tp.stamp(),
        'productId': productId,
        'actualQuantity': actualQuantity,
        'notes': notes,
        'countDate': (observedAt ?? DateTime.now()).toIso8601String(),
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
  /// Reference scans are tenant-scoped under armed isolation.
  Future<List<String>> getProductReferences(int productId) async {
    final db = await database;
    final tp = _readPredicate();
    final productMaps = await db.query('products',
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([productId]),
        limit: 1);
    if (productMaps.isEmpty) return [];
    final product = Product.fromMap(productMaps.first);

    final List<String> refs = [];

    final saleRows = await db.query('sales',
        where: tp.prefix('barcode = ?'),
        whereArgs: tp.argsWith([product.barcode]),
        limit: 1);
    if (saleRows.isNotEmpty) refs.add('مبيعات');

    final returnRows = await db.query('returns',
        where: tp.prefix('barcode = ?'),
        whereArgs: tp.argsWith([product.barcode]),
        limit: 1);
    if (returnRows.isNotEmpty) refs.add('مرتجعات');

    final countRows = await db.query('inventory_count',
        where: tp.prefix('productId = ?'),
        whereArgs: tp.argsWith([productId]),
        limit: 1);
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
  /// given [barcode] within the tenant scope. Must be called inside a
  /// transaction ([txn]).
  Future<void> _requireExistingProductByBarcode(Transaction txn, String barcode,
      [_TenantPredicate tp = _TenantPredicate.none]) async {
    final rows = await txn.query('products',
        where: tp.prefix('barcode = ?'),
        whereArgs: tp.argsWith([barcode]),
        limit: 1);
    if (rows.isEmpty) {
      throw ProductReferenceIntegrityException(
          'لا يوجد منتج بالباركود "$barcode"');
    }
  }

  // =================== COST HISTORY (Phase P / Group D / D1) ===================

  /// Records a cost-price change event in the `cost_history` table.
  ///
  /// Must be called inside the same transaction that updates the product cost,
  /// guaranteeing atomicity: if the product update succeeds, the history record
  /// is created; if either fails, neither is committed.
  ///
  /// [shopId] is required for tenant isolation.
  /// [oldCost] and [newCost] must differ for a meaningful record.
  /// [changedBy] is optional actor attribution where architecturally valid.
  Future<void> recordCostChange(
    Transaction txn, {
    required String shopId,
    required int productId,
    required String productName,
    required String productBarcode,
    required double oldCost,
    required double newCost,
    String? changedBy,
  }) async {
    if (oldCost == newCost) return;

    await txn.insert('cost_history', {
      'shop_id': shopId,
      'product_id': productId,
      'product_name': productName,
      'product_barcode': productBarcode,
      'old_cost': oldCost,
      'new_cost': newCost,
      'changed_at': DateTime.now().toIso8601String(),
      'changed_by': changedBy,
    });
  }

  /// Returns cost change history for a specific product, ordered by most
  /// recent first. Tenant-scoped under armed isolation.
  Future<List<CostHistory>> getCostHistoryByProduct(int productId) async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('cost_history',
        where: tp.prefix('product_id = ?'),
        whereArgs: tp.argsWith([productId]),
        orderBy: 'changed_at DESC, id DESC');
    return maps.map((map) => CostHistory.fromMap(map)).toList();
  }

  /// Returns all cost change history records for the active shop, ordered by
  /// most recent first. Tenant-scoped under armed isolation.
  Future<List<CostHistory>> getAllCostHistory() async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('cost_history',
        where: tp.clause, whereArgs: tp.args, orderBy: 'changed_at DESC, id DESC');
    return maps.map((map) => CostHistory.fromMap(map)).toList();
  }

  /// Returns cost history for a product identified by barcode.
  Future<List<CostHistory>> getCostHistoryByBarcode(String barcode) async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('cost_history',
        where: tp.prefix('product_barcode = ?'),
        whereArgs: tp.argsWith([barcode]),
        orderBy: 'changed_at DESC, id DESC');
    return maps.map((map) => CostHistory.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;
    final tp = _readPredicate();
    final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE ${tp.prefix('name != ""')}',
        tp.args);
    final totalQtyResult = await db.rawQuery(
        'SELECT SUM(currentQuantity) as total FROM products${tp.toSqlWhere()}',
        tp.args);
    final totalCostResult = await db.rawQuery(
        'SELECT SUM(totalInventoryCost) as total FROM products${tp.toSqlWhere()}',
        tp.args);
    final salesCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE ${tp.prefix('productName != ""')}',
        tp.args);
    final returnsCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM returns WHERE ${tp.prefix('productName != ""')}',
        tp.args);
    final expensesCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE ${tp.prefix('description != ""')}',
        tp.args);

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
    final tp = _readPredicate();
    return await db.rawQuery('''
      SELECT date,
             COUNT(*) as transactionCount,
             SUM(quantity) as totalQuantity,
             SUM(totalSaleValue) as totalSales,
             SUM(cogs) as totalCOGS,
             SUM(totalSaleValue) - SUM(cogs) as grossProfit
      FROM sales${tp.toSqlWhere()}
      GROUP BY date
      ORDER BY date DESC
    ''', tp.args);
  }

  Future<List<Map<String, dynamic>>> getSalesGroupByProduct(
      {UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final tp = _readPredicate();
    return await db.rawQuery('''
      SELECT productName,
             barcode,
             SUM(quantity) as totalQuantity,
             COUNT(*) as transactionCount,
             AVG(salePrice) as avgPrice,
             SUM(totalSaleValue) as totalSales,
             SUM(cogs) as totalCOGS,
             SUM(totalSaleValue) - SUM(cogs) as grossProfit
      FROM sales${tp.toSqlWhere()}
      GROUP BY barcode
      ORDER BY totalSales DESC
    ''', tp.args);
  }

  Future<Map<String, dynamic>> getSalesSummary({UserRole? currentRole}) async {
    _requireSalesHistoryAccess(currentRole);
    final db = await database;
    final tp = _readPredicate();
    final totalSalesResult = await db.rawQuery(
        'SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty, COUNT(*) as count FROM sales${tp.toSqlWhere()}',
        tp.args);
    final totalCOGSResult = await db.rawQuery(
        'SELECT SUM(cogs) as total FROM sales${tp.toSqlWhere()}', tp.args);
    final todayResult = await db.rawQuery('''
      SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty
      FROM sales WHERE ${tp.prefix("date(date) = date('now', 'localtime')")}
    ''', tp.args);
    final monthResult = await db.rawQuery('''
      SELECT SUM(totalSaleValue) as total, SUM(quantity) as qty
      FROM sales WHERE ${tp.prefix("strftime('%Y-%m', date) = strftime('%Y-%m', 'now', 'localtime')")}
    ''', tp.args);

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
  /// Deliberately GLOBAL (not shop-scoped): generated barcodes rely on the
  /// global `products.barcode UNIQUE` constraint retained per owner decision
  /// Z-1 (GLOBAL). Scoping MAX(id) here would generate colliding barcodes
  /// across shops and violate that constraint on insert.
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
    final tp = _writePredicate();
    return await db.transaction((txn) async {
      final id = await txn.insert('customers', {
        ...tp.stamp(),
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
    final tp = _readPredicate();
    final maps = await db.query('customers',
        where: tp.clause,
        whereArgs: tp.args,
        orderBy: 'isSystem DESC, name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> getActiveCustomers() async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('customers',
        where: tp.prefix('isActive = 1'),
        whereArgs: tp.args,
        orderBy: 'isSystem DESC, name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final tp = _readPredicate();
    final maps = await db.query('customers',
        where: tp.prefix('id = ?'), whereArgs: tp.argsWith([id]), limit: 1);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final tp = _readPredicate();
    final maps = await db.query('customers',
        where: tp.prefix('isActive = 1 AND (name LIKE ? OR phone LIKE ?)'),
        whereArgs: tp.argsWith([q, q]),
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
    final tp = _writePredicate();
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
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([customer.id]),
      );
      if (affected == 0) {
        await _assertNotForeignRow(txn, 'customers', customer.id!, tp);
      }
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
      final tp = _writePredicate();
      await _assertNotForeignRow(db, 'customers', customerId, tp);
      throw StateError('العميل غير موجود');
    }
    if (customer.isSystem) {
      throw StateError('لا يمكن أرشفة العميل النظامي');
    }
    final tp = _writePredicate();
    await db.transaction((txn) async {
      final affected = await txn.update(
        'customers',
        {
          'isActive': 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([customerId]),
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
    final tp = _writePredicate();
    await db.transaction((txn) async {
      final affected = await txn.update(
        'customers',
        {
          'isActive': 1,
          'updatedAt': DateTime.now().toIso8601String(),
          'sync_status': EntitySyncStatus.PENDING.label,
        },
        where: tp.prefix('id = ?'),
        whereArgs: tp.argsWith([customerId]),
      );
      if (affected == 0) {
        await _assertNotForeignRow(txn, 'customers', customerId, tp);
      }
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

/// Tenant scoping predicate applied to every tenant-owned query while strict
/// isolation is armed (Phase J §J/§K contracts).
///
///  - [none]      : legacy mode, no predicate.
///  - [denyAll]   : armed without an authorized shop — matches nothing so
///                  reads fail closed to empty.
///  - scoped(shop): `shop_id = ?`.
class _TenantPredicate {
  final String? clause;
  final List<Object?> args;

  const _TenantPredicate._(this.clause, this.args);

  static const _TenantPredicate none = _TenantPredicate._(null, []);
  static const _TenantPredicate denyAll = _TenantPredicate._('1 = 0', []);

  factory _TenantPredicate.scoped(String shopId) =>
      _TenantPredicate._('shop_id = ?', [shopId]);

  bool get deniesAll => clause == '1 = 0';
  bool get isScoped => clause != null && !deniesAll;

  /// Composes this predicate BEFORE a caller condition:
  /// `(shop_id = ?) AND (caller)`. With no tenant predicate, returns the
  /// caller condition unchanged.
  String prefix(String condition) =>
      clause == null ? condition : '($clause) AND ($condition)';

  /// Nullable-where composition for sqflite query helpers.
  String? andWhere(String? where) =>
      where == null || where.isEmpty ? clause : prefix(where);

  List<Object?> argsWith(List<Object?>? callerArgs) =>
      [...args, ...?callerArgs];

  /// Raw-SQL fragment for queries with no existing WHERE clause.
  String toSqlWhere() => clause == null ? '' : ' WHERE $clause';

  /// Raw-SQL fragment appended inside an existing WHERE clause.
  String toSqlAnd() => clause == null ? '' : ' AND ($clause)';

  /// Insert stamping map (empty in legacy mode).
  Map<String, Object?> stamp() =>
      isScoped ? {'shop_id': args.first as String} : const {};
}

/// Thrown when a business write is attempted while strict tenant isolation is
/// armed but no authorized shop context exists (fail-closed, plan §K).
class TenantIsolationException implements Exception {
  final String message;
  const TenantIsolationException(this.message);

  @override
  String toString() => 'TenantIsolationException: $message';
}

/// Thrown when a mutation targets a row that exists but belongs to another
/// shop. Surfaced explicitly instead of a silent zero-row no-op (plan §K).
class TenantOwnershipException implements Exception {
  final String message;
  const TenantOwnershipException(this.message);

  @override
  String toString() => 'TenantOwnershipException: $message';
}
