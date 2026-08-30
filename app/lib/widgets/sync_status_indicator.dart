import 'package:flutter/material.dart';

/// Small widget that shows the current cloud connectivity and sync status
/// truthfully (Phase P Group A A6 — observability).
///
/// Displays a colored dot:
/// - Red: sync failures or conflicts (action required)
/// - Orange: pending local work that has not converged
/// - Grey: no cloud link configured / unbound
/// - Blue: reconciliation engine armed but no successful sync yet
/// - Green: fully synced — ONLY when authoritative evidence supports it
/// - Amber: cloud-linked but reconciliation is not active (e.g. production
///   drain seam OFF), so "fully synced" must NOT be claimed
///
/// A6 truthfulness invariants:
/// - Pending/failed/conflict counts always win over any success rendering.
/// - A valid cloud/auth session ([isCloudLinked]/[isOnline]) is NOT by itself
///   evidence of convergence. Green success requires [drainActive] (the
///   reconciliation engine is actually armed), a converged queue, and a
///   recorded successful sync ([lastSyncedAt]).
/// - With the production drain seam OFF ([drainActive] false) the app never
///   claims "fully synced": there is no authoritative reconciliation.
///
/// When [failedCount] > 0 or [conflictCount] > 0, shows a red alert badge.
/// When [pendingCount] > 0, shows an orange pending badge.
///
/// An optional [onRetry] callback renders a small retry/reconnect affordance
/// (only meaningful when reconciliation may be attempted/restored). The
/// callback must route through the application-owned runtime so every gate
/// (license, connectivity, shop binding, tenant scope, drain seam) is
/// preserved.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.isCloudLinked,
    required this.isOnline,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.lastSyncedAt,
    this.drainActive = false,
    this.onRetry,
    this.enabled = true,
  });

  final bool isCloudLinked;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final bool drainActive;
  final VoidCallback? onRetry;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final Color dotColor;
    final String tooltip;
    if (failedCount > 0 || conflictCount > 0) {
      dotColor = Colors.red;
      tooltip =
          'تعارضات أو أخطاء في المزامنة ($failedCount خطأ، $conflictCount تعارض)';
    } else if (pendingCount > 0) {
      dotColor = Colors.orange;
      tooltip = '$pendingCount عناصر تنتظر المزامنة';
    } else if (!isCloudLinked) {
      dotColor = Colors.grey;
      tooltip = 'غير مرتبط بال云端';
    } else if (!isOnline) {
      dotColor = Colors.amber;
      tooltip = 'غير متصل حاليًا — لا مزامنة';
    } else if (!drainActive) {
      dotColor = Colors.amber;
      tooltip = 'المزامنة غير نشطة حاليًا — البيانات محفوظة محليًا';
    } else if (lastSyncedAt == null) {
      dotColor = Colors.blue;
      tooltip = 'جاري المزامنة...';
    } else {
      dotColor = Colors.green;
      tooltip = 'مزامنة كاملة';
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (failedCount > 0 || conflictCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${failedCount + conflictCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else if (pendingCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (onRetry != null &&
              !(failedCount == 0 &&
                  conflictCount == 0 &&
                  pendingCount == 0 &&
                  isCloudLinked &&
                  isOnline &&
                  drainActive &&
                  lastSyncedAt != null))
            IconButton(
              icon: const Icon(Icons.refresh, size: 14),
              tooltip: 'إعادة محاولة المزامنة',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
