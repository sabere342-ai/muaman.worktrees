import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../database/workbook_importer.dart';
import '../models/shop_profile.dart';
import '../models/user_role.dart';
import '../services/app_settings.dart';
import '../services/clean_start_service.dart';
import '../services/permissions.dart';
import '../services/session_state.dart';
import '../services/shop_profile_service.dart';
import 'admin/roles_permissions_screen.dart';
import 'admin/user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SessionState sessionState;

  const SettingsScreen({super.key, required this.sessionState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _licenseController = TextEditingController();
  final _workbookPathController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _logoPathController = TextEditingController();
  String _buttonStyle = 'filled';
  String _supportPhone = AppSettings.defaultSupportPhone;
  String _licenseStatus = 'inactive';
  bool _isSaving = false;
  bool _isImporting = false;
  bool _isSavingProfile = false;
  String _currentLogoPath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadShopProfile();
  }

  bool get _canEditShopProfile =>
      widget.sessionState.hasPermission(AppPermission.canAccessSettings);

  bool get _isOwner => widget.sessionState.currentRole == UserRole.owner;

  Future<void> _loadSettings() async {
    await AppSettings.initializeDefaults();
    final buttonStyle = await AppSettings.getButtonStyle();
    final supportPhone = await AppSettings.getSupportPhone();
    final licenseKey = await AppSettings.getLicenseKey();
    final licenseStatus = await AppSettings.getLicenseStatus();
    final workbookPath = await AppSettings.getWorkbookPath();
    setState(() {
      _buttonStyle = buttonStyle;
      _supportPhone = supportPhone;
      _licenseController.text = licenseKey;
      _licenseStatus = licenseStatus;
      _workbookPathController.text = workbookPath;
    });
  }

  Future<void> _loadShopProfile() async {
    await ShopProfileService.instance.load();
    final profile = ShopProfileService.instance.current;
    if (!mounted) return;
    setState(() {
      _shopNameController.text = profile.shopName;
      _ownerNameController.text = profile.ownerOrManagerName;
      _shopPhoneController.text = profile.phone;
      _shopAddressController.text = profile.address;
      _logoPathController.text = profile.logoPath;
      _currentLogoPath = profile.logoPath;
    });
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() => _logoPathController.text = path);
  }

  Future<void> _saveShopProfile() async {
    final shopName = _shopNameController.text.trim();
    if (shopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اسم المحل مطلوب'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      await ShopProfileService.instance.save(
        ShopProfile(
          shopName: shopName,
          ownerOrManagerName: _ownerNameController.text.trim(),
          phone: _shopPhoneController.text.trim(),
          address: _shopAddressController.text.trim(),
          logoPath: _currentLogoPath,
        ),
        actorRole: widget.sessionState.currentRole,
        logoSourcePath: _logoPathController.text.trim(),
      );
      if (!mounted) return;
      final saved = ShopProfileService.instance.current;
      setState(() {
        _isSavingProfile = false;
        _logoPathController.text = saved.logoPath;
        _currentLogoPath = saved.logoPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات المحل بنجاح')),
      );
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل حفظ بيانات المحل: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التطبيق',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('هوية المتجر',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildShopProfileSection(),
            const SizedBox(height: 24),
            const Text('الأمان والصلاحيات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (widget.sessionState
                      .hasPermission(AppPermission.canManagePermissions))
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings,
                          color: Color(0xFF0D47A1)),
                      title: const Text('صلاحيات الأدوار'),
                      subtitle:
                          const Text('التحكم في صلاحيات كل دور من الأدوار'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _openRolesPermissions(context),
                    ),
                  if (widget.sessionState
                      .hasPermission(AppPermission.canManagePermissions))
                    const Divider(height: 1),
                  if (widget.sessionState
                      .hasPermission(AppPermission.canManageUsers))
                    ListTile(
                      leading:
                          const Icon(Icons.people, color: Color(0xFF0D47A1)),
                      title: const Text('إدارة المستخدمين'),
                      subtitle: const Text('إنشاء وتعديل حسابات المستخدمين'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _openUserManagement(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('مظهر الأزرار',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [
                _buttonStyle == 'filled',
                _buttonStyle == 'outlined',
              ],
              onPressed: (index) {
                final style = index == 0 ? 'filled' : 'outlined';
                setState(() => _buttonStyle = style);
                AppSettings.setValue(AppSettings.keyButtonStyle, style);
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ممتلئ'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('محاط'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('دعم ومساعدة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.support_agent, color: Color(0xFF0D47A1)),
                title: Text('رقم الدعم: $_supportPhone'),
                subtitle: const Text('يمكنك نسخ الرقم للتواصل مع الدعم'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _supportPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ رقم الدعم')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('الرخصة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _licenseController,
              decoration: InputDecoration(
                labelText: 'مفتاح الرخصة',
                suffixText: _licenseStatus == 'active' ? 'نشطة' : 'غير نشطة',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _activateLicense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('تفعيل الرخصة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('استيراد بيانات Excel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _workbookPathController,
              decoration: const InputDecoration(
                labelText: 'مسار ملف Excel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isImporting ? null : _importWorkbook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                    ),
                    child: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('استيراد البيانات'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isOwner) ..._buildCleanStartSection(),
            const SizedBox(height: 24),
            const Text('تفاصيل الترخيص',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                'حالة الترخيص: ${_licenseStatus == 'active' ? 'نشطة' : 'غير نشطة'}'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCleanStartSection() {
    return [
      const Text('البيانات التجريبية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مسح جميع بيانات العمليات (الأصناف والمبيعات والمرتجعات '
                'والمصروفات والجرد والفواتير وسجلات الاستيراد) لبدء تشغيل نظيف. '
                'يتم الاحتفاظ بحسابات المستخدمين وصلاحياتهم وبيانات المتجر. '
                'تُنشأ نسخة احتياطية كاملة قبل المسح.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _confirmCleanStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.cleaning_services),
                label: const Text('بدء تشغيل نظيف',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _confirmCleanStart() async {
    String? backupDirectory;
    final confirmationController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          String? getError() {
            if (backupDirectory == null) {
              return 'اختر مجلد النسخة الاحتياطية أولًا';
            }
            if (confirmationController.text.trim() !=
                CleanStartService.confirmationPhrase) {
              return 'اكتب عبارة التأكيد بدقة';
            }
            return null;
          }

          Future<void> pickDirectory() async {
            final picked = await FilePicker.platform
                .getDirectoryPath(dialogTitle: 'مجلد النسخة الاحتياطية');
            if (picked != null && picked.isNotEmpty) {
              setDialogState(() => backupDirectory = picked);
            }
          }

          return AlertDialog(
            title: const Text('بدء تشغيل نظيف'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'سيتم حذف جميع بيانات العمليات نهائيًا. يجب إنشاء نسخة '
                      'احتياطية كاملة قبل المسح.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickDirectory,
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                        backupDirectory ?? 'اختيار مجلد النسخة الاحتياطية'),
                  ),
                  if (backupDirectory != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'نسخة احتياطية: $backupDirectory',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmationController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'عبارة التأكيد',
                      hintText: CleanStartService.confirmationPhrase,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اكتب: "${CleanStartService.confirmationPhrase}"',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                onPressed: getError() == null
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('مسح البيانات'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runCleanStart(backupDirectory!);
  }

  Future<void> _runCleanStart(String backupDirectory) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    try {
      final report = await CleanStartService().run(
        actorRole: widget.sessionState.currentRole,
        backupDirectory: backupDirectory,
        confirmation: CleanStartService.confirmationPhrase,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _showCleanStartResult(report);
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on CleanStartConfirmationException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on CleanStartBackupFailedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل بدء التشغيل النظيف: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCleanStartResult(CleanStartReport report) async {
    final lines = report.deletedCounts.entries
        .map((e) => '${_tableLabel(e.key)}: ${e.value}')
        .join('\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تم بدء التشغيل النظيف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تم مسح البيانات التالية:'),
              const SizedBox(height: 8),
              Text(lines),
              const SizedBox(height: 12),
              Text(
                'النسخة الاحتياطية: ${report.backupPath}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  String _tableLabel(String table) {
    switch (table) {
      case 'products':
        return 'الأصناف';
      case 'sales':
        return 'المبيعات';
      case 'returns':
        return 'المرتجعات';
      case 'expenses':
        return 'المصروفات';
      case 'inventory_count':
        return 'سجلات الجرد';
      case 'invoices':
        return 'الفواتير';
      case 'import_batches':
        return 'سجلات الاستيراد';
      default:
        return table;
    }
  }

  Widget _buildShopProfileSection() {
    if (!_canEditShopProfile) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const ListTile(
          leading: Icon(Icons.store, color: Color(0xFF0D47A1)),
          title: Text('بيانات المتجر'),
          subtitle: Text('غير مصرح لك بتعديل بيانات المتجر'),
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildLogoPreview(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اسم المحل والبيانات التعريفية التي تظهر في التطبيق',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المتجر',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المالك / المسؤول',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shopPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shopAddressController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _logoPathController,
                    decoration: const InputDecoration(
                      labelText: 'مسار صورة الشعار',
                      hintText:
                          'اختر صورة شعار لتُحفظ نسخة منها داخل بيانات التطبيق',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSavingProfile ? null : _pickLogo,
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'اختيار الشعار',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSavingProfile ? null : _saveShopProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _isSavingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('حفظ بيانات المتجر',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    final path = _currentLogoPath;
    if (path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _logoPlaceholder(),
        ),
      );
    }
    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(Icons.store, size: 32, color: Colors.grey.shade500),
    );
  }

  void _openRolesPermissions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: RolesPermissionsScreen(sessionState: widget.sessionState),
        ),
      ),
    );
  }

  void _openUserManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: UserManagementScreen(sessionState: widget.sessionState),
        ),
      ),
    );
  }

  Future<void> _activateLicense() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أدخل مفتاح الرخصة'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    final valid = await AppSettings.validateLicenseKey(key);
    if (!mounted) return;
    setState(() {
      _licenseStatus = valid ? 'active' : 'inactive';
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(valid ? 'تم تفعيل الرخصة بنجاح' : 'مفتاح الرخصة غير صالح'),
        backgroundColor: valid ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _importWorkbook() async {
    final path = _workbookPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أدخل مسار ملف Excel'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الملف غير موجود'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isImporting = true);
    try {
      final report = await WorkbookImporter.import(
        workbookPath: path,
        db: await DatabaseHelper.instance.database,
        allowZeroCost: true,
        skipShaCheck: true,
      );
      await AppSettings.setWorkbookPath(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم الاستيراد بنجاح. المنتجات: ${report.productsImported}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل الاستيراد: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _workbookPathController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _shopPhoneController.dispose();
    _shopAddressController.dispose();
    _logoPathController.dispose();
    super.dispose();
  }
}
