import 'package:flutter/material.dart';

import '../../models/cloud/cloud_device.dart';
import '../../models/user_role.dart';
import '../../services/active_shop_context.dart';
import '../../services/cloud_device_management_repository.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';

/// S7 Owner device management screen.
///
/// Provides the Owner a secure, server-authoritative view of the current
/// shop's devices and allows only governed lifecycle actions:
///   PENDING_APPROVAL → approve / reject
///   ACTIVE           → revoke (s3_revoke_device) / mark lost
///   REJECTED/REVOKED/LOST → terminal display, no client-side restore
///
/// Security contract:
///   - Owner-only. If the caller cannot be established as an Owner, the
///     screen FAILS CLOSED (access denied) — UI hiding alone is insufficient.
///   - Tenant-bound. Only the authenticated session's shop (ActiveShopContext)
///     is used; a client-forged shop id is never accepted.
///   - Every mutation is routed through the server-authoritative repository
///     and the device list is RE-READ from the server after mutation. No
///     optimistic local fabrication of authoritative state.
class DeviceManagementScreen extends StatefulWidget {
  final SessionState sessionState;
  final CloudDeviceManagementRepository? repository;

  const DeviceManagementScreen({
    super.key,
    required this.sessionState,
    this.repository,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

enum _LoadPhase { loading, success, empty, error }

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  late final CloudDeviceManagementRepository _repository;
  late final ActiveShopContext _shopContext;

  _LoadPhase _phase = _LoadPhase.loading;
  String _errorMessage = '';
  List<CloudDevice> _devices = const [];
  String? _mutationDeviceId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CloudDeviceManagementRepository();
    _shopContext = ActiveShopContext.instance;
    _load();
  }

  bool get _isOwner =>
      widget.sessionState.hasPermission(AppPermission.canManageDevices);

  String? get _shopId => _shopContext.shopId;

  Future<void> _load() async {
    setState(() {
      _phase = _LoadPhase.loading;
      _errorMessage = '';
    });
    try {
      final shopId = _shopId;
      if (shopId == null) {
        setState(() {
          _phase = _LoadPhase.error;
          _errorMessage = 'لا يوجد متجر مرتبط بهذا الحساب';
        });
        return;
      }
      final devices = await _repository.listDevices(shopId);
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _phase = devices.isEmpty ? _LoadPhase.empty : _LoadPhase.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LoadPhase.error;
        _errorMessage = 'تعذر تحميل الأجهزة: $e';
      });
    }
  }

  Future<void> _mutation(
    Future<bool> Function() action,
    CloudDevice device,
  ) async {
    final shopId = _shopId;
    if (shopId == null) {
      _showSnack('لا يوجد متجر مرتبط بهذا الحساب', error: true);
      return;
    }
    setState(() => _mutationDeviceId = device.deviceId);
    try {
      final ok = await action();
      if (!mounted) return;
      setState(() => _mutationDeviceId = null);
      if (ok) {
        _showSnack('تم تنفيذ الإجراء بنجاح');
        // R14: re-read authoritative device list after mutation.
        await _refresh();
      } else {
        _showSnack('فشل تنفيذ الإجراء من الخادم', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _mutationDeviceId = null);
      _showSnack('فشل تنفيذ الإجراء: $e', error: true);
    }
  }

  Future<void> _refresh() async {
    try {
      final shopId = _shopId;
      if (shopId == null) {
        setState(() {
          _phase = _LoadPhase.error;
          _errorMessage = 'لا يوجد متجر مرتبط بهذا الحساب';
        });
        return;
      }
      final devices = await _repository.listDevices(shopId);
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _phase = devices.isEmpty ? _LoadPhase.empty : _LoadPhase.success;
      });
    } catch (e) {
      if (!mounted) return;
      // Post-mutation re-read failure: surface safe error, do NOT fabricate
      // the target state.
      setState(() {
        _phase = _LoadPhase.error;
        _errorMessage = 'تم تنفيذ الإجراء لكن تعذر تحديث القائمة: $e';
      });
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // R9 owner gate: fail closed, not merely hiding buttons.
    if (!_isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة الأجهزة'), centerTitle: true),
        body: const Center(
          child: Text('غير مصرح لك بالوصول إلى إدارة الأجهزة'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأجهزة'), centerTitle: true),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case _LoadPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadPhase.empty:
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(
                child: Text('لا توجد أجهزة في هذا المتجر'),
              ),
            ],
          ),
        );
      case _LoadPhase.error:
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
        );
      case _LoadPhase.success:
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return _DeviceCard(
                device: device,
                mutationInProgress: _mutationDeviceId == device.deviceId,
                onApprove: _canApprove(device)
                    ? () => _mutation(
                          () => _repository.approveDevice(
                            _shopId!,
                            device.deviceId,
                          ),
                          device,
                        )
                    : null,
                onReject: _canReject(device)
                    ? () => _mutation(
                          () => _repository.rejectDevice(
                            _shopId!,
                            device.deviceId,
                          ),
                          device,
                        )
                    : null,
                onRevoke: _canRevoke(device)
                    ? () => _mutation(
                          () => _repository.revokeDevice(
                            _shopId!,
                            device.deviceId,
                          ),
                          device,
                        )
                    : null,
                onMarkLost: _canMarkLost(device)
                    ? () => _mutation(
                          () => _repository.markDeviceLost(
                            _shopId!,
                            device.deviceId,
                          ),
                          device,
                        )
                    : null,
              );
            },
          ),
        );
    }
  }

  bool _canApprove(CloudDevice d) =>
      d.status == DeviceTrustStatus.pendingApproval;
  bool _canReject(CloudDevice d) =>
      d.status == DeviceTrustStatus.pendingApproval;
  bool _canRevoke(CloudDevice d) => d.status == DeviceTrustStatus.active;
  bool _canMarkLost(CloudDevice d) => d.status == DeviceTrustStatus.active;
}

class _DeviceCard extends StatelessWidget {
  final CloudDevice device;
  final bool mutationInProgress;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;
  final VoidCallback? onMarkLost;

  const _DeviceCard({
    required this.device,
    required this.mutationInProgress,
    this.onApprove,
    this.onReject,
    this.onRevoke,
    this.onMarkLost,
  });

  Color _statusColor() {
    switch (device.status) {
      case DeviceTrustStatus.pendingApproval:
        return Colors.orange;
      case DeviceTrustStatus.active:
        return Colors.green;
      case DeviceTrustStatus.rejected:
        return Colors.red;
      case DeviceTrustStatus.revoked:
        return Colors.grey;
      case DeviceTrustStatus.lost:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.deviceName?.isNotEmpty == true
                        ? device.deviceName!
                        : 'جهاز غير مُسمّى',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (mutationInProgress)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    device.status.labelAr,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
                if (device.platform != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    device.platform == 'android' ? 'أندرويد' : 'ويندوز',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (device.lastSeenAt != null) ...[
              const SizedBox(height: 8),
              _MetaRow('آخر ظهور', _formatTime(device.lastSeenAt!)),
            ],
            if (device.status.isTerminal) ...[
              const SizedBox(height: 8),
              const Text(
                'هذا الجهاز في حالة نهائية ولا يمكن استعادته من هنا.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textDirection: TextDirection.rtl,
              ),
            ],
            if (onApprove != null ||
                onReject != null ||
                onRevoke != null ||
                onMarkLost != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onApprove != null)
                    ElevatedButton(
                      onPressed: mutationInProgress ? null : onApprove,
                      child: const Text('موافقة'),
                    ),
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: mutationInProgress ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('رفض'),
                    ),
                  if (onRevoke != null)
                    OutlinedButton(
                      onPressed: mutationInProgress ? null : onRevoke,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  if (onMarkLost != null)
                    OutlinedButton(
                      onPressed: mutationInProgress ? null : onMarkLost,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text('فقدان'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final pad = (int v) => v.toString().padLeft(2, '0');
    return '${pad(local.day)}/${pad(local.month)}/${local.year} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}
