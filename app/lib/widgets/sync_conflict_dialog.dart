import 'package:flutter/material.dart';

enum ConflictStatus {
  none,
  pending,
  resolved,
}

/// Phase M §22: the reviewed conflict component used by the owner review
/// screen. The legacy minimal API is preserved; optional evidence fields
/// (§22 field list) enrich the dialog when provided.
class SyncConflictDialog extends StatelessWidget {
  const SyncConflictDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.conflictCount,
    this.status = ConflictStatus.pending,
    this.productName,
    this.productBarcode,
    this.localBefore,
    this.localAfter,
    this.serverBefore,
    this.serverAfter,
    this.relatedEventRefs = const [],
    this.deviceIdentity,
    this.userIdentity,
    this.detectedAt,
    this.reason,
    this.recommendedAction,
    this.resolutionState,
  });

  final String entityType;
  final String entityId;
  final int conflictCount;
  final ConflictStatus status;

  // ---- §22 evidence fields (optional) ----
  final String? productName;
  final String? productBarcode;
  final Map<String, dynamic>? localBefore;
  final Map<String, dynamic>? localAfter;
  final Map<String, dynamic>? serverBefore;
  final Map<String, dynamic>? serverAfter;
  final List<String> relatedEventRefs;
  final String? deviceIdentity;
  final String? userIdentity;
  final DateTime? detectedAt;
  final String? reason;
  final String? recommendedAction;
  final String? resolutionState;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعارض المزامنة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تم اكت${conflictCount > 1 ? '$conflictCount تعارضات' : 'تعارض واحد'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'النوع: $entityType',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (productName != null) _line(context, 'المنتج', productName!),
          if (productBarcode != null)
            _line(context, 'الباركود', productBarcode!),
          if (localBefore != null)
            _line(context, 'المحلي قبل', localBefore.toString()),
          if (localAfter != null)
            _line(context, 'المحلي بعد', localAfter.toString()),
          if (serverBefore != null)
            _line(context, 'الخادم قبل', serverBefore.toString()),
          if (serverAfter != null)
            _line(context, 'الخادم بعد', serverAfter.toString()),
          if (relatedEventRefs.isNotEmpty)
            _line(context, 'الأحداث ذات الصلة', relatedEventRefs.join(', ')),
          if (deviceIdentity != null) _line(context, 'الجهاز', deviceIdentity!),
          if (userIdentity != null) _line(context, 'المستخدم', userIdentity!),
          if (detectedAt != null)
            _line(context, 'وقت الاكتشاف', detectedAt!.toIso8601String()),
          if (reason != null) _line(context, 'السبب', reason!),
          if (recommendedAction != null)
            _line(context, 'الإجراء الموصى به', recommendedAction!),
          if (resolutionState != null)
            _line(context, 'حالة القرار', resolutionState!),
          const SizedBox(height: 16),
          Text(
            status == ConflictStatus.resolved
                ? 'تم حل التعارض وتسجيله في سجل التدقيق.'
                : 'تم حفظ البيانات محلياً. سيتم مراجعة التعارضات تلقائياً.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسناً'),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
