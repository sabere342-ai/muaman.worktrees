import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../sync/conflict_audit_record.dart';
import '../../sync/conflict_audit_repository.dart';
import '../../sync/sync_status.dart';

/// Phase M M-I08 (plan §22, §28): owner conflict review list + detail +
/// resolution actions.
///
/// Authorization model (DR-M10 resolved against existing RBAC):
///   - Resolution is OWNER-ONLY and FAIL-CLOSED. Any other role (employee,
///     salesOnly) or a null session role gets a read-only view.
///   - Before any resolution action executes, a server-side permission
///     re-check ([serverPermissionRecheck]) must pass. The client UI gate
///     is convenience only; the server revalidates every cloud RPC.
///   - Every resolution carries a note and lands in the durable audit
///     trail (RESOLVED + method OWNER).
///
/// RTL/Arabic-first; usable on Windows and Android (shared code path).
class ConflictReviewScreen extends StatefulWidget {
  const ConflictReviewScreen({
    super.key,
    required this.auditRepository,
    this.currentRole,
    this.serverPermissionRecheck,
    required this.onResolve,
    this.resolvedByUser = 'owner',
  });

  final ConflictAuditRepository auditRepository;

  /// Role of the live session. Null ⇒ read-only (fail closed).
  final UserRole? currentRole;

  /// Server-side permission re-check seam. Awaited before every resolution
  /// action; returning false fails the action CLOSED. When null, no cloud
  /// re-check is available ⇒ fail closed for cloud-linked shops.
  final Future<bool> Function({required String action})?
      serverPermissionRecheck;

  /// Applies the chosen resolution to the queue/projection. Must be
  /// transactional at its own boundary (engine/repository contract §16).
  final Future<bool> Function(ConflictAuditRecord record, String note)
      onResolve;

  final String resolvedByUser;

  bool get canResolve => currentRole == UserRole.owner;

  @override
  State<ConflictReviewScreen> createState() => _ConflictReviewScreenState();
}

class _ConflictReviewScreenState extends State<ConflictReviewScreen> {
  late Future<List<ConflictAuditRecord>> _openFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _openFuture = widget.auditRepository.getOpenConflicts();
  }

  Future<void> _resolve(ConflictAuditRecord record, String note,
      {String action = 'apply_resolved'}) async {
    if (!widget.canResolve || _busy) return;
    setState(() => _busy = true);
    try {
      // CL-2: owner chose an action → RESOLUTION_PENDING while executing.
      await widget.auditRepository.markResolutionPending(record.id);

      // Server-side permission re-check (fail closed).
      final recheck = widget.serverPermissionRecheck;
      if (recheck == null || !(await recheck(action: action))) {
        await _failClosed(record, 'فشل التحقق من الصلاحية على الخادم');
        return;
      }

      final applied = await widget.onResolve(record, note);
      if (!applied) {
        await _failClosed(record, 'تعذر تطبيق القرار على البيانات المحلية');
        return;
      }
      // CL-3: terminal, carries who/when/how.
      await widget.auditRepository.markResolved(
        record.id,
        method: ConflictResolutionMethod.OWNER,
        resolvedByUser: widget.resolvedByUser,
        note: note.isEmpty ? 'قرار المالك' : note,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حل التعارض وتسجيل القرار')),
      );
    } catch (e) {
      await _failClosed(record, 'خطأ أثناء الحل: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }

  /// Any failure returns the record to REVIEW_REQUIRED (restartable,
  /// never stuck silently in RESOLUTION_PENDING — plan §24 CL-5/M-I09).
  Future<void> _failClosed(ConflictAuditRecord record, String message) async {
    try {
      await widget.auditRepository.markReviewRequired(record.id);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة تعارضات المزامنة')),
        body: widget.canResolve ? _buildOwnerBody() : _buildReadOnlyBody(),
      ),
    );
  }

  Widget _buildReadOnlyBody() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFFF3E0),
          padding: const EdgeInsets.all(12),
          child: const Text(
            'وضع العرض فقط — حل التعارضات متاح للمالك فقط',
            style: TextStyle(color: Color(0xFF8D6E63)),
          ),
        ),
        Expanded(child: _buildConflictList(interactive: false)),
      ],
    );
  }

  Widget _buildOwnerBody() {
    return _buildConflictList(interactive: true);
  }

  Widget _buildConflictList({required bool interactive}) {
    return FutureBuilder<List<ConflictAuditRecord>>(
      future: _openFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('تعذر تحميل التعارضات: ${snapshot.error}'));
        }
        final records = snapshot.data ?? const <ConflictAuditRecord>[];
        if (records.isEmpty) {
          return const Center(child: Text('لا توجد تعارضات مفتوحة'));
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _buildTile(records[index], interactive),
        );
      },
    );
  }

  Widget _buildTile(ConflictAuditRecord record, bool interactive) {
    return ListTile(
      leading: Icon(
        record.status == ConflictLifecycleStatus.RESOLUTION_PENDING
            ? Icons.hourglass_top
            : Icons.report_problem,
        color: const Color(0xFF4A148C),
      ),
      title: Text('${record.entityType} #${record.entityId}'),
      subtitle: Text(
        '${_statusLabel(record.status)}\n'
        'عملية: ${record.operation} · مفتاح: ${record.idempotencyKey ?? '-'}',
      ),
      isThreeLine: true,
      trailing: interactive
          ? ElevatedButton(
              onPressed: _busy ? null : () => _openResolutionSheet(record),
              child: const Text('حل'),
            )
          : null,
    );
  }

  void _openResolutionSheet(ConflictAuditRecord record) {
    final noteController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('حل التعارض: ${record.entityType} #${record.entityId}',
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 12),
                _evidenceRow('الحالة المحلية قبل التعارض', record.localBefore),
                _evidenceRow('حالة الخادم', record.serverBefore),
                _evidenceRow('الحالة المحلية بعد', record.localAfter),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات القرار'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                _resolve(record, noteController.text.trim());
                              },
                        child: const Text('تطبيق القرار'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _evidenceRow(String label, Map<String, dynamic>? payload) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${payload == null ? '-' : payload.toString()}',
          style: Theme.of(context).textTheme.bodySmall),
    );
  }

  String _statusLabel(ConflictLifecycleStatus status) {
    switch (status) {
      case ConflictLifecycleStatus.REVIEW_REQUIRED:
        return 'بانتظار المراجعة';
      case ConflictLifecycleStatus.RESOLUTION_PENDING:
        return 'قيد التنفيذ';
      case ConflictLifecycleStatus.RESOLVED:
        return 'تم الحل';
    }
  }
}
