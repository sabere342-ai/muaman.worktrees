import 'package:flutter/material.dart';
import '../licensing/cloud_licensing_service.dart';

/// A banner widget that shows trial/license status information.
///
/// Displayed at the top of the main app shell when the user has an active
/// trial or a licensing state that warrants attention.
class TrialRemainingBanner extends StatelessWidget {
  final CloudEntitlementSnapshot entitlement;

  const TrialRemainingBanner({
    super.key,
    required this.entitlement,
  });

  @override
  Widget build(BuildContext context) {
    if (entitlement.blocksWrites) {
      return _buildBlockedBanner(context);
    }

    if (entitlement.isTrial) {
      return _buildTrialBanner(context);
    }

    // Licensed active — no banner needed
    return const SizedBox.shrink();
  }

  Widget _buildTrialBanner(BuildContext context) {
    final days = entitlement.daysRemaining;
    final daysText = days != null
        ? (days > 0
            ? '$days يوم متبقي'
            : (days == 0 ? 'آخر يوم' : 'انتهت الفترة التجريبية'))
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'فترة تجريبية — $daysText',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner(BuildContext context) {
    String message;
    Color bgColor;
    Color fgColor;
    IconData icon;

    switch (entitlement.state) {
      case CloudEntitlementState.expired:
        if (entitlement.isTrial) {
          message = 'انتهت الفترة التجريبية. يرجى تفعيل الرخصة.';
        } else {
          message = 'انتهت صلاحية الرخصة. يرجى التواصل مع I Tech.';
        }
        bgColor = Colors.red.shade50;
        fgColor = Colors.red.shade900;
        icon = Icons.error_outline;
        break;
      case CloudEntitlementState.suspended:
        message = 'تم تعليق الرخصة.';
        bgColor = Colors.amber.shade50;
        fgColor = Colors.amber.shade900;
        icon = Icons.pause_circle_outline;
        break;
      case CloudEntitlementState.revoked:
        message = 'تم إلغاء الرخصة.';
        bgColor = Colors.red.shade50;
        fgColor = Colors.red.shade900;
        icon = Icons.block;
        break;
      case CloudEntitlementState.staleOffline:
        message = 'يتطلب التحقق من الرخصة. يرجى الاتصال بالإنترنت.';
        bgColor = Colors.orange.shade50;
        fgColor = Colors.orange.shade900;
        icon = Icons.cloud_off;
        break;
      case CloudEntitlementState.offlineNoLicense:
        message = 'يتطلب اتصال بالإنترنت للتحقق من الرخصة.';
        bgColor = Colors.grey.shade100;
        fgColor = Colors.grey.shade800;
        icon = Icons.wifi_off;
        break;
      default:
        message = 'يتطلب التحقق من الرخصة.';
        bgColor = Colors.orange.shade50;
        fgColor = Colors.orange.shade900;
        icon = Icons.warning_amber;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
