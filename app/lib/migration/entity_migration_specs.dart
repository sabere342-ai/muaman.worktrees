/// Parameterized chunk query over a migration universe table.
class UniverseChunkQuery {
  final String sql;
  final List<Object?> args;
  const UniverseChunkQuery(this.sql, this.args);
}

typedef UniverseQueryBuilder = UniverseChunkQuery Function({
  required int afterLocalId,
  required int limit,
  String? shopId,
});

/// Phase I / D6 cross-entity reference resolution against cloud_uuids already
/// recorded for this batch in earlier phases (P1 categories → P4 expenses,
/// P2 products → P5 counts, P3 customers → P7 invoices). Implementations are
/// backed by the cloud migration ledger mappings fetched/rebuilt on resume
/// (D12) so a restarted process resolves references identically.
abstract class MigrationReferenceResolver {
  String? categoryUuidByName(String? name);
  String? productUuidByLocalId(int localId);
  String? customerUuidByLocalId(int? localId);

  /// Learns a fresh mapping produced during import (ledger confirmation).
  void learn(String localTable, int localId, String? cloudUuid,
      {String? businessKey});
}

/// Frozen per-entity migration path (D1 universe, D6 order, D10 fingerprint
/// inputs, D13 natural keys, D14 financial sums).
class EntityMigrationSpec {
  /// Frozen dependency-order label from D6 ('P1'..'P8'; P9/P10 are handled by
  /// the orchestrator itself).
  final String phase;

  final String entityTypeLabel;
  final String localTableName;
  final String cloudTableName;

  /// D13: tables WITH a natural key skip colliding rows (CONFLICT ledger
  /// status, existing cloud row wins); tables WITHOUT one always append.
  final bool hasNaturalKey;

  /// Selects this table's migration universe from a database executor
  /// (snapshot-scoped): rows not yet cloud-linked, ordered by ascending local
  /// id, chunkable by `local_id > cursor`. Shop attribution/quarantine filters
  /// are applied per D3 via [UniverseQueryBuilder.shopId].
  final UniverseQueryBuilder universeQuery;

  /// Builds the canonical business payload sent to the ingest RPC. This exact
  /// map is also the content_fingerprint input (D10): ids, sync metadata,
  /// shop_id and sync timestamps never enter it.
  final Map<String, dynamic> Function(
          Map<String, dynamic> row, MigrationReferenceResolver resolver)
      businessPayload;

  /// D14 invariant sums: alias -> source column summed at reconciliation.
  final Map<String, String> financialSums;

  const EntityMigrationSpec({
    required this.phase,
    required this.entityTypeLabel,
    required this.localTableName,
    required this.cloudTableName,
    required this.hasNaturalKey,
    required this.universeQuery,
    required this.businessPayload,
    required this.financialSums,
  });
}

double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
String _s(Object? v, {String fallback = ''}) => (v is String) ? v : fallback;

String _idColumn(String table) => table == 'app_settings' ? 'rowid' : 'id';

/// Standard universe query: legacy rows only (cloud_uuid IS NULL), ascending
/// local-id cursor pagination, D3 shop attribution filter applied when
/// [shopId] is provided (NULL-shop rows are adopted by the single licensed
/// batch shop; foreign-shop rows are excluded/quarantined at census time).
///
/// The integer cursor identity is always projected explicitly as
/// `migration_local_id` because `SELECT *` omits the implicit `rowid` for
/// tables without an INTEGER id column (app_settings is keyed by TEXT PK).
UniverseQueryBuilder _defaultUniverse(String table) =>
    ({required int afterLocalId, required int limit, String? shopId}) {
      final idCol = _idColumn(table);
      var sql = 'SELECT $idCol AS migration_local_id, * FROM $table'
          ' WHERE cloud_uuid IS NULL';
      final args = <Object?>[];
      if (shopId != null && shopId.isNotEmpty) {
        sql += ' AND (shop_id IS NULL OR shop_id = ?)';
        args.add(shopId);
      }
      sql += ' AND $idCol > ? ORDER BY $idCol ASC LIMIT ?';
      args
        ..add(afterLocalId)
        ..add(limit);
      return UniverseChunkQuery(sql, args);
    };

/// The frozen nine paths in strict P1..P8 execution order (D6).
final List<EntityMigrationSpec> kLegacyMigrationSpecs = [
  // P1 expense_categories (no deps)
  EntityMigrationSpec(
    phase: 'P1',
    entityTypeLabel: 'expenseCategory',
    localTableName: 'expense_categories',
    cloudTableName: 'cloud_expense_categories',
    hasNaturalKey: true, // name UNIQUE
    universeQuery: _defaultUniverse('expense_categories'),
    businessPayload: (row, _) => {
      'name': _s(row['name']),
    },
    financialSums: const {},
  ),
  // P2 products (no deps among migrated)
  EntityMigrationSpec(
    phase: 'P2',
    entityTypeLabel: 'product',
    localTableName: 'products',
    cloudTableName: 'cloud_products',
    hasNaturalKey: true, // barcode
    universeQuery: _defaultUniverse('products'),
    businessPayload: (row, _) => {
      'name': _s(row['name']),
      'barcode': _s(row['barcode']),
      'opening_quantity': _i(row['openingQuantity']),
      'sold_quantity': _i(row['soldQuantity']),
      'returned_quantity': _i(row['returnedQuantity']),
      'current_quantity': _i(row['currentQuantity']),
      'cost_price': _d(row['costPrice']),
      'total_inventory_cost': _d(row['totalInventoryCost']),
      'inventory_adjustment': _i(row['inventoryAdjustment']),
    },
    financialSums: const {},
  ),
  // P3 customers (no deps among migrated); business timestamps preserved (D4)
  EntityMigrationSpec(
    phase: 'P3',
    entityTypeLabel: 'customer',
    localTableName: 'customers',
    cloudTableName: 'cloud_customers',
    hasNaturalKey: true, // (name, phone)
    universeQuery: _defaultUniverse('customers'),
    businessPayload: (row, _) => {
      'name': _s(row['name']),
      'phone': row['phone'] as String?,
      'address': row['address'] as String?,
      'notes': row['notes'] as String?,
      'is_active': _i(row['isActive']) == 1,
      'is_system': _i(row['isSystem']) == 1,
      'created_at': _s(row['createdAt']),
    },
    financialSums: const {},
  ),
  // P4 expenses → needs P1 category resolution
  EntityMigrationSpec(
    phase: 'P4',
    entityTypeLabel: 'expense',
    localTableName: 'expenses',
    cloudTableName: 'cloud_expenses',
    hasNaturalKey: false, // history-append semantics
    universeQuery: _defaultUniverse('expenses'),
    businessPayload: (row, resolver) {
      final categoryName = row['category'] as String?;
      return {
        'date': _s(row['date']),
        'description': _s(row['description']),
        'amount': _d(row['amount']),
        'category_name': categoryName,
        'category_id': resolver.categoryUuidByName(categoryName),
      };
    },
    financialSums: const {'amount': 'amount'},
  ),
  // P5 inventory_count → needs P2 productId resolution
  EntityMigrationSpec(
    phase: 'P5',
    entityTypeLabel: 'inventoryCount',
    localTableName: 'inventory_count',
    cloudTableName: 'cloud_inventory_count',
    hasNaturalKey: false,
    universeQuery: _defaultUniverse('inventory_count'),
    businessPayload: (row, resolver) => {
      'product_id': resolver.productUuidByLocalId(_i(row['productId'])) ?? '',
      'actual_quantity': _i(row['actualQuantity']),
      'notes': row['notes'] as String? ?? '',
      'count_date': _s(row['countDate']),
    },
    financialSums: const {},
  ),
  // P6 sales → denormalized names travel inside the row; invoice link deferred
  // to P9 post-pass (D6).
  EntityMigrationSpec(
    phase: 'P6',
    entityTypeLabel: 'sale',
    localTableName: 'sales',
    cloudTableName: 'cloud_sales',
    hasNaturalKey: false,
    universeQuery: _defaultUniverse('sales'),
    businessPayload: (row, _) => {
      'date': _s(row['date']),
      'product_name': _s(row['productName']),
      'barcode': _s(row['barcode']),
      'quantity': _i(row['quantity']),
      'sale_price': _d(row['salePrice']),
      'total_sale_value': _d(row['totalSaleValue']),
      'cost_price': _d(row['costPrice']),
      'cogs': _d(row['cogs']),
    },
    financialSums: const {
      'sales.total_sale_value': 'totalSaleValue',
      'sales.cogs': 'cogs',
    },
  ),
  // P7 invoices → needs P3 customerId; runs AFTER P6 so sale links resolve.
  // Column-presence probe tolerates both fresh (no customerId) and upgraded
  // shapes exactly like _migrateToV13 (plan §1.3 / TM#8).
  EntityMigrationSpec(
    phase: 'P7',
    entityTypeLabel: 'invoice',
    localTableName: 'invoices',
    cloudTableName: 'cloud_invoices',
    hasNaturalKey: true, // invoiceNumber
    universeQuery: _defaultUniverse('invoices'),
    businessPayload: (row, resolver) => {
      'invoice_number': _s(row['invoiceNumber']),
      'date': _s(row['date']),
      'customer_name': _s(row['customerName']),
      'customer_id': resolver.customerUuidByLocalId(
          row.containsKey('customerId') ? _i(row['customerId']) : null),
      'payment_method': _s(row['paymentMethod']),
      'total_amount': _d(row['totalAmount']),
      'total_items': _i(row['totalItems']),
      'created_at': _s(row['createdAt']),
    },
    financialSums: const {'invoices.total_amount': 'totalAmount'},
  ),
  // P8 returns → needs P2 + P6 ordering per frozen sequence.
  EntityMigrationSpec(
    phase: 'P8',
    entityTypeLabel: 'returnItem',
    localTableName: 'returns',
    cloudTableName: 'cloud_returns',
    hasNaturalKey: false,
    universeQuery: _defaultUniverse('returns'),
    businessPayload: (row, _) => {
      'date': _s(row['date']),
      'product_name': _s(row['productName']),
      'barcode': _s(row['barcode']),
      'quantity': _i(row['quantity']),
      'sale_price': _d(row['salePrice']),
      'total_return_value': _d(row['totalReturnValue']),
      'cost_price': _d(row['costPrice']),
      'returned_cogs': _d(row['returnedCogs']),
    },
    financialSums: const {'returns.returned_cogs': 'returnedCogs'},
  ),
];

/// Ninth path: shop profile settings (app_settings keyed rows; `rowid` is the
/// snapshot-local integer identity feeding the ledger's INTEGER local_id).
/// No natural key beyond the composite PK (shop_id, setting_key) enforced
/// server-side per-shop; re-importing the same key/value hits ledger
/// idempotency first.
final EntityMigrationSpec kShopSettingsSpec = EntityMigrationSpec(
  phase: 'P8b',
  entityTypeLabel: 'shopSetting',
  localTableName: 'app_settings',
  cloudTableName: 'cloud_shop_settings',
  hasNaturalKey: false,
  universeQuery: _defaultUniverse('app_settings'),
  businessPayload: (row, _) => {
    'setting_key': _s(row['key']),
    'setting_value': _s(row['value']),
  },
  financialSums: const {},
);

/// All ten execution entries (nine entities; shop settings appended after the
/// frozen P1..P8 sequence because they carry no dependencies).
List<EntityMigrationSpec> get kOrderedLegacyMigrationSpecs =>
    [...kLegacyMigrationSpecs, kShopSettingsSpec];
