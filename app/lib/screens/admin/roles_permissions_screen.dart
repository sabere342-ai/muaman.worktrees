import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/permission_resolver.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';

/// Owner-only screen for managing per-role permissions.
///
/// The owner role is shown read-only (always fully privileged). Other roles
/// can be edited and persisted. All writes go through
/// [PermissionResolver.saveRolePermissions] which enforces the owner-only and
/// owner-exclusive rules, and take effect on the affected users' next session.
class RolesPermissionsScreen extends StatefulWidget {
  final SessionState sessionState;

  const RolesPermissionsScreen({super.key, required this.sessionState});

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> {
  late final PermissionResolver _resolver;
  bool _isLoading = true;
  bool _accessDenied = false;
  String? _loadError;
  Map<UserRole, Set<AppPermission>> _current = {};
  final Map<UserRole, Set<AppPermission>> _edits = {};
  UserRole _selectedRole = UserRole.employee;
  bool _isSaving = false;

  bool get _canManagePermissions =>
      widget.sessionState.hasPermission(AppPermission.canManagePermissions);

  @override
  void initState() {
    super.initState();
    _resolver = widget.sessionState.permissionResolver;
    if (!_canManagePermissions) {
      _accessDenied = true;
      _isLoading = false;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _resolver.refresh();
      final snapshot = _resolver.snapshot();
      if (!mounted) return;
      setState(() {
        _current = snapshot;
        _edits.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل الصلاحيات: $e';
        _isLoading = false;
      });
    }
  }

  Set<AppPermission> _effectiveFor(UserRole role) {
    if (_edits.containsKey(role)) return _edits[role]!;
    return _current[role] ?? PermissionCatalog.defaultPermissionsForRole(role);
  }

  void _toggle(AppPermission permission, bool value) {
    final current = _effectiveFor(_selectedRole);
    final updated = Set<AppPermission>.of(current);
    if (value) {
      updated.add(permission);
    } else {
      updated.remove(permission);
    }
    setState(() => _edits[_selectedRole] = updated);
  }

  Future<void> _confirmSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ التغييرات'),
        content:
            const Text('سيتم حفظ صلاحيات هذا الدور وتطبيقها على المستخدمين '
                'عند تسجيل الخروج والدخول مرة أخرى. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      for (final entry in _edits.entries) {
        await _resolver.saveRolePermissions(
          role: entry.key,
          permissions: entry.value,
          actorRole: widget.sessionState.currentRole,
        );
      }
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _edits.clear();
        _current = _resolver.snapshot();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حفظ الصلاحيات بنجاح'),
            backgroundColor: Colors.green),
      );
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل الحفظ: ${e.message}'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة الصلاحيات الافتراضية'),
        content:
            Text('سيتم إرجاع صلاحيات دور "${_selectedRole.displayName}" إلى '
                'الإعدادات الافتراضية. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _resolver.resetRoleToDefaults(
        role: _selectedRole,
        actorRole: widget.sessionState.currentRole,
      );
      _edits.remove(_selectedRole);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _current = _resolver.snapshot();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم استعادة الصلاحيات الافتراضية'),
            backgroundColor: Colors.green),
      );
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل الاستعادة: ${e.message}'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل الاستعادة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صلاحيات الأدوار',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _isLoading || _accessDenied || _loadError != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_accessDenied) {
      return const Center(
        child: Text('غير مصرح بالوصول إلى إدارة الصلاحيات'),
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final isOwnerSelected = _selectedRole == UserRole.owner;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoleSelector(),
        const SizedBox(height: 16),
        if (isOwnerSelected)
          _buildOwnerNotice()
        else
          ..._buildPermissionGroups(),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Wrap(
      spacing: 8,
      children: UserRole.values.map((role) {
        final selected = _selectedRole == role;
        final hasEdits = _edits.containsKey(role);
        return ChoiceChip(
          label: Text(role.displayName),
          selected: selected,
          avatar: hasEdits
              ? const Icon(Icons.circle, size: 12, color: Colors.orange)
              : null,
          onSelected: (value) {
            if (value) {
              setState(() => _selectedRole = role);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildOwnerNotice() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('المالك',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'المالك يتمتع بجميع الصلاحيات دائمًا ولا يمكن تقييده.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 6),
                Text('✓ يُسمح دائمًا'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionGroups() {
    final groups = PermissionCatalog.grouped();
    final effective = _effectiveFor(_selectedRole);

    return [
      for (final category in PermissionCategory.values)
        if (groups.containsKey(category)) ...[
          Text(category.displayName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                for (final permission in groups[category]!)
                  _buildPermissionTile(permission, effective),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
    ];
  }

  Widget _buildPermissionTile(
      AppPermission permission, Set<AppPermission> effective) {
    final isOwnerExclusive =
        PermissionCatalog.ownerExclusive.contains(permission);
    final isEnabled = !isOwnerExclusive;
    return SwitchListTile(
      title: Text(permission.displayName),
      subtitle: Text(
        isOwnerExclusive
            ? '${permission.description} — للمالك فقط'
            : permission.description,
        style: const TextStyle(fontSize: 12),
      ),
      value: effective.contains(permission),
      onChanged: isEnabled ? (value) => _toggle(permission, value) : null,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_selectedRole != UserRole.owner)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _confirmReset,
                  child: const Text('استعادة الافتراضي'),
                ),
              ),
            if (_selectedRole != UserRole.owner) const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving || _edits.isEmpty ? null : _confirmSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('حفظ التغييرات'),
                style: ElevatedButton.styleFrom(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
