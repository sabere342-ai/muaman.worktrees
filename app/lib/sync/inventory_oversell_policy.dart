import 'sync_status.dart';

/// OD6 decision point (Phase M plan §17 / DR-M06).
///
/// This class is the SINGLE place where the offline negative-stock policy
/// lives. The sync engine and reconciliation machinery must never branch on
/// commercial policy directly — they consult this seam only.
///
/// OD6 REMAINS OPEN. The shipped default ([preserveWithAdjustment], Option C
/// mechanics + owner notification) is classified as
/// ARCHITECTURAL_RECOMMENDATION + TEMPORARY_SAFE_DEFAULT — NOT owner
/// approval. Flipping to pure-B ([allowNegative]) or strict-D
/// ([requireOwnerResolution]) after an owner decision touches only this
/// seam constant and its tests.
class InventoryOversellPolicy {
  /// Shipped temporary default (DR-M06).
  static const InventoryOversellPolicy shippedDefault =
      InventoryOversellPolicy._(OversellPolicyMode.preserveWithAdjustment);

  final OversellPolicyMode mode;

  const InventoryOversellPolicy._(this.mode);

  const InventoryOversellPolicy.allowNegative()
      : this._(OversellPolicyMode.allowNegative);
  const InventoryOversellPolicy.preserveWithAdjustment()
      : this._(OversellPolicyMode.preserveWithAdjustment);
  const InventoryOversellPolicy.requireOwnerResolution()
      : this._(OversellPolicyMode.requireOwnerResolution);

  /// Whether reconciling an oversold divergence must produce an explicit,
  /// durable adjustment artifact (Option C behavior).
  bool get createsAdjustmentArtifact =>
      mode == OversellPolicyMode.preserveWithAdjustment;

  /// Whether convergence must block until an owner resolves the
  /// discrepancy (Option D behavior).
  bool get blocksUntilOwnerResolves =>
      mode == OversellPolicyMode.requireOwnerResolution;
}
