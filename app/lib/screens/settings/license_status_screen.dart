import 'package:flutter/material.dart';
import '../../licensing/cloud_licensing_service.dart';
import '../../widgets/trial_remaining_banner.dart';

class LicenseStatusScreen extends StatelessWidget {
  final CloudEntitlementSnapshot entitlement;
  final bool isOwner;

  const LicenseStatusScreen({
    super.key,
    required this.entitlement,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حالة الرخصة'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrialRemainingBanner(entitlement: entitlement),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildDetailsCard(),
                    if (entitlement.isTrial &&
                        entitlement.trialExpiresAt != null) ...[
                      const SizedBox(height: 16),
                      _buildTrialInfoCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final (color, label, icon) = _getStatusInfo();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تفاصيل الرخصة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const Divider(),
            _buildDetailRow(
              'نوع الرخصة',
              entitlement.isTrial
                  ? 'فترة تجريبية'
                  : _licenseTypeLabel(entitlement.licenseStatus),
            ),
            _buildDetailRow(
              'حالة الرخصة',
              entitlement.allowsWrites ? 'نشطة' : 'غير نشطة',
            ),
            if (entitlement.maxDevices != null)
              _buildDetailRow(
                'الأجهزة',
                '${entitlement.currentDevices} / ${entitlement.maxDevices}',
              ),
            if (!entitlement.isOnline) _buildDetailRow('الاتصال', 'غير متصل'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialInfoCard() {
    final expires = entitlement.trialExpiresAt!;
    final days = entitlement.daysRemaining;
    final daysText = days != null ? '$days يوم' : '--';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الفترة التجريبية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const Divider(),
            _buildDetailRow('المتبقي', daysText),
            _buildDetailRow(
              'تاريخ الانتهاء',
              '${expires.day}/${expires.month}/${expires.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getStatusInfo() {
    switch (entitlement.state) {
      case CloudEntitlementState.entitled:
        if (entitlement.isTrial) {
          return (Colors.green, 'فترة تجريبية نشطة', Icons.timer);
        }
        return (Colors.green, 'رخصة نشطة', Icons.check_circle);
      case CloudEntitlementState.entitledCached:
        return (Colors.orange, 'متصل — بيانات مؤقتة', Icons.cloud_done);
      case CloudEntitlementState.expired:
        if (entitlement.isTrial) {
          return (Colors.red, 'انتهت الفترة التجريبية', Icons.timer_off);
        }
        return (Colors.red, 'انتهت صلاحية الرخصة', Icons.error);
      case CloudEntitlementState.suspended:
        return (Colors.amber, 'تم تعليق الرخصة', Icons.pause_circle);
      case CloudEntitlementState.revoked:
        return (Colors.red, 'تم إلغاء الرخصة', Icons.block);
      case CloudEntitlementState.staleOffline:
        return (Colors.orange, 'يتطلب اتصال بالإنترنت', Icons.cloud_off);
      case CloudEntitlementState.offlineNoLicense:
        return (Colors.grey, 'يتطلب اتصال بالإنترنت', Icons.wifi_off);
      default:
        return (Colors.grey, 'غير محدد', Icons.help_outline);
    }
  }

  String _licenseTypeLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'مدفوعة';
      case 'PERPETUAL':
        return 'دائم';
      case 'TRIAL':
        return 'فترة تجريبية';
      default:
        return status ?? 'غير معروف';
    }
  }
}
