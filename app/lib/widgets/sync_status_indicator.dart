import 'package:flutter/material.dart';

/// Small widget that shows the current cloud connectivity and sync status.
///
/// Displays a colored dot:
/// - Green: cloud linked and online, all synced
/// - Orange: cloud linked but working offline
/// - Red: sync conflicts or failures
/// - Gray: no cloud link configured
///
/// When [pendingCount] > 0, shows a badge with the pending count.
/// When [failedCount] > 0 or [conflictCount] > 0, shows a red dot with
/// an alert badge.
///
/// Renders nothing when [enabled] is false. Callers decide whether a sync
/// indicator is meaningful for their surface (e.g. a seller panel only shows
/// it when the device is actually linked to a cloud tenant).
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.isCloudLinked,
    required this.isOnline,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.lastSyncedAt,
    this.enabled = true,
  });

  final bool isCloudLinked;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    Color dotColor;
    String tooltip;
    if (failedCount > 0 || conflictCount > 0) {
      dotColor = Colors.red;
      tooltip =
          'تعارضات أو أخطاء في المزامنة ($failedCount خطأ، $conflictCount تعارض)';
    } else if (isCloudLinked && isOnline) {
      if (pendingCount > 0) {
        dotColor = Colors.orange;
        tooltip = 'جاري مزامنة $pendingCount عناصر';
      } else {
        dotColor = Colors.green;
        tooltip = 'متصل بال云端 - مزامنة كاملة';
      }
    } else if (isCloudLinked && !isOnline) {
      dotColor = Colors.orange;
      if (pendingCount > 0) {
        tooltip = 'يعمل بدون اتصال - $pendingCount عناصر تنتظر المزامنة';
      } else {
        tooltip = 'يعمل بدون اتصال';
      }
    } else {
      dotColor = Colors.grey;
      tooltip = 'غير مرتبط بال云端';
    }

    return Tooltip(
      message: tooltip,
      child: Stack(
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
    );
  }
}
