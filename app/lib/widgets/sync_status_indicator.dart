import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Small widget that shows the current cloud connectivity status.
///
/// Displays a colored dot:
/// - Green: cloud linked and online
/// - Orange: cloud linked but working offline
/// - Gray: no cloud link configured
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.isCloudLinked,
    required this.isOnline,
  });

  final bool isCloudLinked;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    Color dotColor;
    String tooltip;
    if (isCloudLinked && isOnline) {
      dotColor = Colors.green;
      tooltip = 'متصل بال云端';
    } else if (isCloudLinked && !isOnline) {
      dotColor = Colors.orange;
      tooltip = 'يعمل بدون اتصال';
    } else {
      dotColor = Colors.grey;
      tooltip = 'غير مرتبط بال云端';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
