import 'entity_sync_adapter.dart';
import '../sync_status.dart';

/// Phase P Group A A3 (P-OD1 local half): sync adapter for the durable local
/// `stock_adjustments` artifact.
///
/// When a drained sale/event returns `OVERSOLD`, the engine persists a local
/// `stock_adjustments` row and enqueues a `stockAdjustment` sync operation.
/// Draining that entry routes (through [SyncCloudOperationsTransport]) to the
/// A4 owner-gated `create_cloud_stock_adjustment` RPC and adopts the governing
/// server adjustment uuid. The local table is the additive durable evidence;
/// its cells are never rewritten to hide the oversell.
class StockAdjustmentSyncAdapter extends EntitySyncAdapter {
  @override
  SyncEntityType get entityType => SyncEntityType.stockAdjustment;

  @override
  ConflictResolutionPolicy get conflictPolicy =>
      ConflictResolutionPolicy.serverAuthoritative;

  @override
  String get localTableName => 'stock_adjustments';

  @override
  String get cloudTableName => 'cloud_stock_adjustments';

  @override
  String get requiredPermission => 'admin.settings.access';

  @override
  bool get isServerAuthoritative => true;

  @override
  Map<String, dynamic> localToCloudPayload(Map<String, dynamic> localRow) {
    // NOTE: the transport drains from the QUEUED payload (which the engine
    // encodes with the authoritative server identity: the cloud sale uuid,
    // projected current, shortfall, etc.). This mapping is only ever consulted
    // when the engine forwards a conflict resolution onto a local row; it is
    // kept tolerant (the local sale_id cell is an INTEGER local reference, not
    // a cloud uuid — and must never be forwarded as one).
    final saleRef = localRow['sale_id'];
    final cloudSaleUuid = saleRef is String ? saleRef : null;
    return {
      // Cloud product identity (the migrated RPC requires an explicit server
      // product uuid, resolved by the engine from the local product).
      'product_id': localRow['product_id'] as String?,
      'projected_current':
          (localRow['projected_current'] as num?)?.toInt() ?? 0,
      'shortfall': (localRow['shortfall'] as num?)?.toInt() ?? 0,
      'adjustment_type': 'OVERSOLD',
      // Cloud sale uuid of the governing accepted sale (server identity) is
      // authored by the engine at enqueue time; the local integer sale_id is
      // never forwarded as a uuid.
      'sale_id': cloudSaleUuid,
      'notes': 'Auto-recorded A3 Option C adjustment for preserved oversold '
          'event (shop ${localRow['shop_id']})',
    };
  }

  @override
  Map<String, dynamic> cloudToLocalRow(Map<String, dynamic> cloudRow) {
    return {
      'cloud_uuid': cloudRow['id'],
    };
  }

  @override
  String getCloudUuid(Map<String, dynamic> localRow) =>
      localRow['cloud_uuid'] as String? ?? '';

  @override
  int getLocalId(Map<String, dynamic> localRow) =>
      (localRow['id'] as num?)?.toInt() ?? 0;

  @override
  int getServerVersion(Map<String, dynamic> localRow) =>
      (localRow['server_version'] as num?)?.toInt() ?? 0;
}
