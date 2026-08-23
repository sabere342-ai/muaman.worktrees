/// Rich authoritative return of the Phase M `_v2` stock RPCs
/// (migration 28 / plan §15 OC-3): `{status, id, current_quantity,
/// server_version}` plus oversell/idempotent flags where present.
///
/// INV-M20: after Phase M every server response carries enough state for
/// clients to adopt convergence without guessing.
class StockRpcResult {
  /// SYNCED | OVERSOLD | IDEMPOTENT | HISTORICAL (migration 28 statuses).
  final String status;

  /// Created/affected entity uuid (null on some replays).
  final String? id;

  /// Authoritative post-application stock.
  final int currentQuantity;

  /// Authoritative product version after application.
  final int serverVersion;

  final bool oversold;
  final bool reverted;

  /// True when the server answered from its idempotency log instead of
  /// re-executing (OC-1) — same logical operation applied at most once.
  final bool idempotentReplay;

  const StockRpcResult({
    required this.status,
    this.id,
    required this.currentQuantity,
    required this.serverVersion,
    this.oversold = false,
    this.reverted = false,
    this.idempotentReplay = false,
  });

  factory StockRpcResult.fromJson(dynamic data) {
    if (data is! Map) {
      throw FormatException(
          'Phase M stock RPC returned non-object payload', '$data');
    }
    final map = Map<String, dynamic>.from(data);
    return StockRpcResult(
      status: (map['status'] as String?) ?? 'SYNCED',
      id: map['id'] as String?,
      currentQuantity: (map['current_quantity'] as num?)?.toInt() ?? 0,
      serverVersion: (map['server_version'] as num?)?.toInt() ?? 0,
      oversold: map['oversold'] == true || map['status'] == 'OVERSOLD',
      reverted: map['reverted'] == true,
      idempotentReplay: map['status'] == 'IDEMPOTENT',
    );
  }
}
