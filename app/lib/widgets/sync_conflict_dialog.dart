import 'package:flutter/material.dart';

enum ConflictStatus {
  none,
  pending,
  resolved,
}

class SyncConflictDialog extends StatelessWidget {
  const SyncConflictDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.conflictCount,
    this.status = ConflictStatus.pending,
  });

  final String entityType;
  final String entityId;
  final int conflictCount;
  final ConflictStatus status;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعارض المزامنة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تم اكت ${
                conflictCount > 1 ? '$conflictCount تعارضات' : 'تعارض واحد'
            }',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'النوع: $entityType',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'تم حفظ البيانات محلياً. سيتم مراجعة التعارضات تلقائياً.',
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
}
