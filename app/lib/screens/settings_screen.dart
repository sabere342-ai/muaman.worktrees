import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/workbook_importer.dart';
import '../import/picker_workbook_source.dart';
import '../import/workbook_source.dart';
import '../import/workbook_validation.dart';
import '../licensing/licensing.dart';
import '../licensing/cloud_licensing_service.dart';
import 'settings/license_status_screen.dart';
import '../models/shop_profile.dart';
import '../models/user_role.dart';
import '../platform/platform_capabilities.dart';
import '../services/app_settings.dart';
import '../services/clean_start_service.dart';
import '../services/permissions.dart';
import '../services/standalone_backup_service.dart';
import '../services/standalone_restore_service.dart';
import '../services/session_state.dart';
import '../services/shop_profile_service.dart';
import 'admin/roles_permissions_screen.dart';
import 'admin/user_management_screen.dart';
import 'expenses/expense_categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SessionState sessionState;

  const SettingsScreen({super.key, required this.sessionState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _licenseController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _logoPathController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _invoiceTitleController = TextEditingController();
  final _invoiceFooterTextController = TextEditingController();
  final _thermalPrinterNameController = TextEditingController();
  String _buttonStyle = 'filled';
  bool _isSavingProfile = false;
  String _currentLogoPath = '';
  String _brandColor = AppSettings.defaultBrandColor;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _lastBackupDirectory = '';
  String _thermalPrinterName = '';
  int _thermalPaperWidth = 80;
  int _thermalPrintCopies = 1;

  // T3-3 licensing state
  EntitlementState _entitlementState = EntitlementState.uninitialized;
  String _businessId = '';
  bool _isActivating = false;

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
    final brandColor = await AppSettings.getBrandColor();
    final invoiceTitle = await AppSettings.getInvoiceTitle();
    final invoiceFooterText = await AppSettings.getInvoiceFooterText();
    final backupDir = await AppSettings.getBackupDirectory();
    final thermalPrinterName = await AppSettings.getThermalPrinterName();
    final thermalPaperWidth = await AppSettings.getThermalPaperWidth();
    final thermalPrintCopies = await AppSettings.getThermalPrintCopies();

    // Load T3-3 licensing state
    final licensingService = LicensingService.instance;
    final snapshot = licensingService.current;
    final entitlementState = snapshot.state;
    final parsedToken = snapshot.parsedToken;

    setState(() {
      _buttonStyle = buttonStyle;
      _supportPhoneController.text = supportPhone;
      _licenseController.text = licenseKey;
      _brandColor = brandColor;
      _invoiceTitleController.text = invoiceTitle;
      _invoiceFooterTextController.text = invoiceFooterText;
      _lastBackupDirectory = backupDir;
      _thermalPrinterName = thermalPrinterName;
      _thermalPrinterNameController.text = thermalPrinterName;
      _thermalPaperWidth = thermalPaperWidth;
      _thermalPrintCopies = thermalPrintCopies;
      _entitlementState = entitlementState;
      _businessId = parsedToken?.token.businessId ?? '';
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
            const Text('مظهر التطبيق',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildBrandColorSection(),
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
                      leading: Icon(Icons.admin_panel_settings,
                          color: Theme.of(context).colorScheme.primary),
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
                      leading: Icon(Icons.people,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('إدارة المستخدمين'),
                      subtitle: const Text('إنشاء وتعديل حسابات المستخدمين'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _openUserManagement(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('إدارة المصروفات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (widget.sessionState
                      .hasPermission(AppPermission.canManageUsers))
                    ListTile(
                      leading: Icon(Icons.category,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('تصنيفات المصروفات'),
                      subtitle: const Text('إدارة تصنيفات المصروفات'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _openExpenseCategories(context),
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
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'رقم الدعم الفني',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _supportPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف للدعم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveSupportPhone,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ رقم الدعم',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('إفتراضيات الفاتورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.title,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'عنوان الفاتورة المطبوع',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _invoiceTitleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الفاتورة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يظهر في أعلى الفاتورة PDF والمعرض',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveInvoiceTitle,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ عنوان الفاتورة',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.short_text,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'رسالة تذييل الفاتورة',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _invoiceFooterTextController,
                      decoration: const InputDecoration(
                        labelText: 'رسالة التذييل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تظهر في أسفل الفاتورة PDF والمعرض',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveInvoiceFooterText,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ رسالة التذييل',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildThermalPrinterSection(),
            const SizedBox(height: 24),
            _buildLicensingSection(),
            const SizedBox(height: 24),
            _buildCloudLicensingSection(),
            const SizedBox(height: 24),
            _buildSyncStatusSection(),
            const SizedBox(height: 24),
            // Phase N: unified cross-platform Excel import wizard
            // (Windows native dialog / Android SAF picker — no fixed path).
            const ExcelImportSection(),
            const SizedBox(height: 24),
            ..._buildOwnerFileFeaturesSection(),
          ],
        ),
      ),
    );
  }

  /// Phase K (D8): owner-facing filesystem features (backup/restore and
  /// clean-start) render normally on desktop; on Android they are replaced
  /// by explicit explanatory cards so no feature silently fails under
  /// scoped storage.
  List<Widget> _buildOwnerFileFeaturesSection() {
    if (!PlatformCapabilities.isAndroid) {
      return [
        ..._buildBackupRestoreSection(),
        const SizedBox(height: 24),
        ..._buildCleanStartSection(),
      ];
    }
    return [
      _buildAndroidUnavailableCard(
        'النسخ الاحتياطي والاستعادة',
        'إنشاء نسخ احتياطية خارجية واستعادتها يتطلب وصولاً مباشراً للملفات '
            'وهو غير متاح على Android في هذه المرحلة. استخدم جهاز الكمبيوتر '
            '(ويندوز) لإدارة النسخ الاحتياطية.',
      ),
      const SizedBox(height: 24),
      _buildAndroidUnavailableCard(
        'البداية الجديدة',
        'تصدير لقطة البداية الجديدة إلى ملف خارجي غير متاح على Android في '
            'هذه المرحلة. استخدم جهاز الكمبيوتر (ويندوز) لهذه العملية.',
      ),
    ];
  }

  Widget _buildAndroidUnavailableCard(String title, String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensingSection() {
    final isActive = _entitlementState == EntitlementState.active;
    final stateLabel = _entitlementState.labelAr;
    final stateColor = isActive
        ? Colors.green
        : _entitlementState == EntitlementState.uninitialized
            ? Colors.grey
            : Colors.orange;

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
                Icon(Icons.verified, color: stateColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('الترخيص',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Entitlement state
            _buildLicensingDetailRow('حالة الترخيص', stateLabel, stateColor),
            if (_businessId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildLicensingDetailRow('معرف النشاط', _businessId),
            ],
            const SizedBox(height: 16),
            // Activation input
            if (!isActive) ...[
              TextField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'مفتاح التفعيل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isActivating ? null : _activateRealLicense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isActivating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('تفعيل',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deactivateLicense,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء التفعيل',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLicensingDetailRow(String label, String value,
      [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildCloudLicensingSection() {
    final cloudLicensing = CloudLicensingService.instance;
    final snapshot = cloudLicensing.currentState;
    final isEntitled = snapshot.allowsWrites;
    final stateLabel = _cloudStateLabel(snapshot);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseStatusScreen(
                entitlement: snapshot,
                isOwner: _isOwner,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isEntitled ? Icons.cloud_done : Icons.cloud_off,
                    color: isEntitled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('ترخيص السحابة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stateLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: isEntitled
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                textDirection: TextDirection.rtl,
              ),
              if (snapshot.isTrial && snapshot.daysRemaining != null) ...[
                const SizedBox(height: 4),
                Text(
                  'متبقي ${snapshot.daysRemaining} يوم',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
              if (!snapshot.isOnline) ...[
                const SizedBox(height: 4),
                Text(
                  'غير متصل — بيانات مؤقتة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _cloudStateLabel(CloudEntitlementSnapshot snapshot) {
    switch (snapshot.state) {
      case CloudEntitlementState.entitled:
        return snapshot.isTrial ? 'فترة تجريبية نشطة' : 'رخصة نشطة';
      case CloudEntitlementState.entitledCached:
        return 'نشط (بيانات مؤقتة)';
      case CloudEntitlementState.expired:
        return snapshot.isTrial ? 'انتهت الفترة التجريبية' : 'انتهت الصلاحية';
      case CloudEntitlementState.suspended:
        return 'تم التعليق';
      case CloudEntitlementState.revoked:
        return 'تم الإلغاء';
      case CloudEntitlementState.staleOffline:
        return 'يتطلب اتصال بالإنترنت';
      case CloudEntitlementState.offlineNoLicense:
        return 'يتطلب اتصال بالإنترنت';
      case CloudEntitlementState.noLicense:
        return 'لا توجد رخصة';
      default:
        return 'غير محدد';
    }
  }

  Widget _buildSyncStatusSection() {
    final pendingCount = widget.sessionState.pendingSyncCount;
    final failedCount = widget.sessionState.failedSyncCount;
    final conflictCount = widget.sessionState.conflictSyncCount;
    final lastSyncedAt = widget.sessionState.lastSyncedAt;
    final isCloudLinked = widget.sessionState.isCloudLinked;

    Color statusColor;
    String statusLabel;
    if (!isCloudLinked) {
      statusColor = Colors.grey;
      statusLabel = 'غير مرتبط بالسحابة';
    } else if (failedCount > 0 || conflictCount > 0) {
      statusColor = Colors.red;
      statusLabel = 'يوجد مشاكل في المزامنة';
    } else if (pendingCount > 0) {
      statusColor = Colors.orange;
      statusLabel = 'جاري المزامنة ($pendingCount)';
    } else {
      statusColor = Colors.green;
      statusLabel = 'مزامنة كاملة';
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
                Icon(Icons.sync, color: statusColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('حالة المزامنة',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: TextStyle(fontSize: 13, color: statusColor),
              textDirection: TextDirection.rtl,
            ),
            if (lastSyncedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'آخر مزامنة: ${_formatSyncTime(lastSyncedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textDirection: TextDirection.rtl,
              ),
            ],
            if (failedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$failedCount عناصر فاشلة',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                textDirection: TextDirection.rtl,
              ),
            ],
            if (conflictCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$conflictCount تعارضات',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                textDirection: TextDirection.rtl,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  Future<void> _activateRealLicense() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أدخل مفتاح التفعيل'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isActivating = true);
    try {
      final result = await LicensingService.instance.activate(
        activationCode: key,
      );
      if (!mounted) return;
      setState(() {
        _isActivating = false;
        _entitlementState = LicensingService.instance.currentState;
        _businessId = result.businessId ?? _businessId;
      });
      if (result.success) {
        _licenseController.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'تم تفعيل الرخصة بنجاح'
              : result.error ?? 'فشل التفعيل'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActivating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التفعيل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateLicense() async {
    try {
      await LicensingService.instance.deactivate();
      if (!mounted) return;
      setState(() {
        _entitlementState = LicensingService.instance.current.state;
        _businessId = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء التفعيل'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBrandColorSection() {
    final swatches = <MapEntry<String, String>>[
      const MapEntry('أزرق I-TECH', '#0D47A1'),
      const MapEntry('Teal', '#00695C'),
      const MapEntry('Indigo', '#283593'),
      const MapEntry('Purple', '#6A1B9A'),
      const MapEntry('Orange', '#E65100'),
      const MapEntry('Red', '#B71C1C'),
      const MapEntry('Green', '#1B5E20'),
    ];
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
                Icon(Icons.palette,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لون الهوية الأساسي للتطبيق',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: swatches.map((entry) {
                final isSelected = _brandColor == entry.value;
                final color = _hexToColor(entry.value);
                return GestureDetector(
                  onTap: () async {
                    setState(() => _brandColor = entry.value);
                    await AppSettings.setBrandColor(entry.value);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم تغيير لون الهوية إلى ${entry.key}. يُفعّل عند إعادة التشغيل.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      var h = hex.replaceFirst('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse('0x$h'));
    } catch (_) {
      return const Color(0xFF0D47A1);
    }
  }

  Widget _buildThermalPrinterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الطابعة الحرارية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.print,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'إعدادات طباعة الفواتير الحرارية (80 مم)',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'اسم الطابعة (اتركه فارغاً لنافذة الطباعة)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.print),
                  ),
                  controller: _thermalPrinterNameController,
                  onChanged: (value) {
                    _thermalPrinterName = value;
                  },
                  onSubmitted: (_) => _saveThermalPrinterName(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('عرض الورق: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('80 مم'),
                      selected: _thermalPaperWidth == 80,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _thermalPaperWidth = 80);
                          AppSettings.setThermalPaperWidth(80);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('58 مم'),
                      selected: _thermalPaperWidth == 58,
                      onSelected: null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('عدد النسخ: '),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _thermalPrintCopies > 1
                          ? () {
                              setState(() => _thermalPrintCopies--);
                              AppSettings.setThermalPrintCopies(
                                  _thermalPrintCopies);
                            }
                          : null,
                    ),
                    Text('$_thermalPrintCopies',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _thermalPrintCopies < 10
                          ? () {
                              setState(() => _thermalPrintCopies++);
                              AppSettings.setThermalPrintCopies(
                                  _thermalPrintCopies);
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _saveThermalPrinterName,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ إعدادات الطابعة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveThermalPrinterName() async {
    await AppSettings.setThermalPrinterName(_thermalPrinterName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات الطابعة الحرارية')),
    );
  }

  List<Widget> _buildBackupRestoreSection() {
    return [
      const Text('النسخ الاحتياطي',
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
                'إنشاء نسخة احتياطية من جميع البيانات الحالية. '
                'هذه عملية آمنة ولا تمسح أي بيانات.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _createBackup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'استعادة البيانات من نسخة احتياطية سابقة. '
                'سيتم إنشاء نسخة احتياطية من البيانات الحالية قبل الاستعادة.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isRestoring ? null : _restoreFromBackup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.restore),
                label: const Text('استعادة البيانات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _createBackup() async {
    String? backupDirectory =
        _lastBackupDirectory.isNotEmpty ? _lastBackupDirectory : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickDirectory() async {
            final picked = await FilePicker.platform
                .getDirectoryPath(dialogTitle: 'مجلد النسخة الاحتياطية');
            if (picked != null && picked.isNotEmpty) {
              setDialogState(() => backupDirectory = picked);
            }
          }

          return AlertDialog(
            title: const Text('إنشاء نسخة احتياطية'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('سيتم إنشاء نسخة احتياطية كاملة من جميع البيانات. '
                      'هذه عملية آمنة ولا تمسح أي بيانات.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickDirectory,
                    icon: const Icon(Icons.folder_open),
                    label: Text(backupDirectory ?? 'اختيار مجلد الحفظ'),
                  ),
                  if (backupDirectory != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'سيتم الحفظ في: $backupDirectory',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: backupDirectory != null
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('إنشاء النسخة'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runBackup(backupDirectory!);
  }

  Future<void> _runBackup(String directory) async {
    setState(() => _isBackingUp = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final report = await StandaloneBackupService().createBackup(
        destinationDirectory: directory,
        actorRole: widget.sessionState.currentRole,
      );
      await AppSettings.setBackupDirectory(directory);
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _lastBackupDirectory = directory;
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تم إنشاء النسخة الاحتياطية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المسار: ${report.backupPath}'),
                const SizedBox(height: 8),
                Text('الحجم: ${_formatFileSize(report.fileSize)}'),
                const SizedBox(height: 8),
                Text('عدد الجداول: ${report.tableCount}'),
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
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on StandaloneBackupException catch (e) {
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
            content: Text('فشل إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (picked == null || picked.files.isEmpty || !mounted) return;

    final filePath = picked.files.single.path;
    if (filePath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة البيانات'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سيتم استبدال جميع البيانات الحالية. '
                  'سيتم إنشاء نسخة احتياطية من البيانات الحالية أولاً.'),
              const SizedBox(height: 12),
              Text('ملف الاستعادة: ${picked.files.single.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runRestore(filePath);
  }

  Future<void> _runRestore(String filePath) async {
    setState(() => _isRestoring = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final report = await StandaloneRestoreService().restoreFromBackup(
        backupFilePath: filePath,
        actorRole: widget.sessionState.currentRole,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تمت الاستعادة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تمت الاستعادة من: ${report.restoredFromPath}'),
                const SizedBox(height: 8),
                Text(
                    'نسخة احتياطية قبل الاستعادة: ${report.preSaveBackupPath}'),
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
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on RestoreValidationException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on RestoreFailedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on PreSaveBackupFailedException catch (e) {
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
            content: Text('فشلت عملية الاستعادة: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: Icon(Icons.store,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('بيانات المتجر'),
                subtitle: const Text('غير مصرح لك بتعديل بيانات المتجر'),
              ),
              const Divider(),
              // I Tech attribution (OD5: FIXED_NON_EDITABLE)
              Row(
                children: [
                  Icon(Icons.verified,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نسب التطوير',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppSettings.defaultItechAttributionText,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            // I Tech attribution (OD5: FIXED_NON_EDITABLE)
            Row(
              children: [
                Icon(Icons.verified,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نسب التطوير',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppSettings.defaultItechAttributionText,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSavingProfile ? null : _saveShopProfile,
              style: ElevatedButton.styleFrom(
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

  Future<void> _saveSupportPhone() async {
    final value = _supportPhoneController.text.trim();
    final toSave = value.isNotEmpty ? value : AppSettings.defaultSupportPhone;
    await AppSettings.setValue(AppSettings.keySupportPhone, toSave);
    if (!mounted) return;
    setState(() => _supportPhoneController.text = toSave);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ رقم الدعم')),
    );
  }

  Future<void> _saveInvoiceTitle() async {
    final value = _invoiceTitleController.text.trim();
    final toSave = value.isNotEmpty ? value : AppSettings.defaultInvoiceTitle;
    await AppSettings.setValue(AppSettings.keyInvoiceTitle, toSave);
    if (!mounted) return;
    setState(() => _invoiceTitleController.text = toSave);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ عنوان الفاتورة')),
    );
  }

  Future<void> _saveInvoiceFooterText() async {
    final value = _invoiceFooterTextController.text.trim();
    final toSave =
        value.isNotEmpty ? value : AppSettings.defaultInvoiceFooterText;
    await AppSettings.setValue(AppSettings.keyInvoiceFooterText, toSave);
    if (!mounted) return;
    setState(() => _invoiceFooterTextController.text = toSave);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ رسالة التذييل')),
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

  void _openExpenseCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: ExpenseCategoriesScreen(sessionState: widget.sessionState),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _shopPhoneController.dispose();
    _shopAddressController.dispose();
    _logoPathController.dispose();
    _supportPhoneController.dispose();
    _invoiceTitleController.dispose();
    _invoiceFooterTextController.dispose();
    _thermalPrinterNameController.dispose();
    super.dispose();
  }
}

/// Seam between the wizard UI and the importer/database (N-D18). The default
/// implementation routes to [WorkbookImporter] with the real local database;
/// tests inject a controller instead of standing up SQLite inside widget
/// bindings.
class ExcelImportController {
  const ExcelImportController();

  Future<WorkbookPreparation> prepare(PickedWorkbook workbook) async =>
      WorkbookImporter.prepareFromSource(
        workbook: workbook,
        db: await DatabaseHelper.instance.database,
      );

  Future<WorkbookImportOutcome> confirm(
    PickedWorkbook workbook, {
    required bool allowZeroCost,
  }) async =>
      WorkbookImporter.importFromSource(
        workbook: workbook,
        db: await DatabaseHelper.instance.database,
        allowZeroCost: allowZeroCost,
        enqueueSync: true, // N-D13 default for the user flow
      );
}

/// Phase N (§20.16/§20.17): cross-platform workbook import wizard.
///
/// SELECT → VALIDATE → PREVIEW → CONFIRM → ATOMIC IMPORT → SUMMARY.
/// Used identically on Windows (native .xlsx dialog) and Android (SAF
/// document picker through the same [PickerWorkbookSource]); the Phase K
/// unavailable-card for THIS feature is retired. No path text field exists
/// and no stored/default workbook path is consulted (N-D16/N-T24).
class ExcelImportSection extends StatefulWidget {
  /// Injectable for tests; defaults to the real platform picker.
  final WorkbookSource? workbookSource;

  /// Injectable orchestration seam for tests; defaults to the real importer.
  final ExcelImportController? controller;

  const ExcelImportSection({super.key, this.workbookSource, this.controller});

  @override
  State<ExcelImportSection> createState() => _ExcelImportSectionState();
}

enum _ImportFlowStage { idle, validating, previewReady, importing, summary }

class _ExcelImportSectionState extends State<ExcelImportSection> {
  late final WorkbookSource _source =
      widget.workbookSource ?? PickerWorkbookSource();
  late final ExcelImportController _controller =
      widget.controller ?? const ExcelImportController();

  _ImportFlowStage _stage = _ImportFlowStage.idle;

  PickedWorkbook? _picked;
  WorkbookPreparation? _preparation;
  WorkbookImportOutcome? _outcome;
  bool _allowZeroCost = false;

  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _resetFlow();
  }

  void _resetFlow() {
    _picked = null;
    _preparation = null;
    _outcome = null;
    _allowZeroCost = false;
    _inlineError = null;
    _stage = _ImportFlowStage.idle;
  }

  Future<void> _selectFile() async {
    setState(() {
      _resetFlow();
    });

    final pick = await _source.pick();
    if (!mounted) return;
    if (pick.status == WorkbookPickStatus.cancelled) {
      // N-FR03: clean cancel → IDLE, no error surfaced.
      return;
    }
    if (pick.status == WorkbookPickStatus.error || pick.workbook == null) {
      setState(() {
        _inlineError = pick.errorMessage ?? 'تعذر اختيار الملف. حاول مرة أخرى.';
      });
      return;
    }

    setState(() {
      _picked = pick.workbook;
      _stage = _ImportFlowStage.validating;
    });

    try {
      final preparation = await _controller.prepare(pick.workbook!);
      if (!mounted) return;
      setState(() {
        _preparation = preparation;
        _stage = _ImportFlowStage.previewReady;
      });
    } on WorkbookDuplicateException catch (e) {
      if (!mounted) return;
      setState(() {
        _outcome = WorkbookImportOutcome(
          status: WorkbookImportStatus.duplicateDetected,
          fileSha256: '',
          fileName: pick.workbook!.fileName,
          originalImportedAt: e.originalImportedAt,
        );
        _stage = _ImportFlowStage.summary;
      });
    } on WorkbookValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError = e.userMessage;
        _stage = _ImportFlowStage.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineError = WorkbookErrorCode.internalUnexpected.userMessage;
        _stage = _ImportFlowStage.idle;
      });
    }
  }

  Future<void> _confirmImport() async {
    final picked = _picked;
    if (picked == null || _stage != _ImportFlowStage.previewReady) return;

    setState(() => _stage = _ImportFlowStage.importing);

    final outcome = await _controller.confirm(
      picked,
      allowZeroCost: _allowZeroCost, // explicit zero-cost acknowledgement
    );

    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _stage = _ImportFlowStage.summary;
    });
  }

  void _cancelPreview() {
    setState(() => _resetFlow());
  }

  bool get _confirmEnabled {
    final preview = _preparation?.preview;
    if (preview == null) return false;
    if (preview.hasBlockingErrors) return false;
    if (preview.requiresZeroCostAcknowledgement && !_allowZeroCost) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('استيراد بيانات Excel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._buildBody(),
      ],
    );
  }

  List<Widget> _buildBody() {
    switch (_stage) {
      case _ImportFlowStage.idle:
        return _buildIdle();
      case _ImportFlowStage.validating:
        return _buildValidating();
      case _ImportFlowStage.previewReady:
        return _buildPreview();
      case _ImportFlowStage.importing:
        return _buildImporting();
      case _ImportFlowStage.summary:
        return _buildSummary();
    }
  }

  List<Widget> _buildIdle() {
    return [
      if (_inlineError != null) ...[
        Text(
          _inlineError!,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 8),
      ],
      ElevatedButton.icon(
        key: const ValueKey('select-workbook-button'),
        onPressed: _selectFile,
        icon: const Icon(Icons.file_open),
        label: const Text('اختيار ملف Excel'),
      ),
    ];
  }

  List<Widget> _buildValidating() {
    return const [
      SizedBox(height: 8),
      Center(child: CircularProgressIndicator()),
      SizedBox(height: 8),
      Center(child: Text('جارٍ التحقق من الملف...')),
    ];
  }

  List<Widget> _buildPreview() {
    final preview = _preparation!.preview;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الملف: ${_preparation!.fileName}'),
              const SizedBox(height: 4),
              Text('المحتوى المتوقع: منتجات ${preview.products} — مبيعات '
                  '${preview.sales} — مرتجعات ${preview.returns} — مصروفات '
                  '${preview.expenses} — جرد ${preview.adjustments}'),
              if (preview.skippedShortRows > 0)
                Text('صفوف قصيرة سيتم تجاهلها: ${preview.skippedShortRows}'),
              if (preview.skippedMissingIdentity > 0)
                Text('صفوف بدون اسم/باركود سيتم تجاهلها: '
                    '${preview.skippedMissingIdentity}'),
              if (preview.totalRowErrors > 0)
                Text('صفوف بقيم غير صالحة: ${preview.totalRowErrors}',
                    style: const TextStyle(color: Colors.orange)),
              for (final sample in preview.rowErrorSamples.take(3))
                Text(sample,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              for (final warning in preview.warnings.take(5))
                Text('تنبيه: ${warning.message}',
                    style: const TextStyle(color: Colors.orange)),
              if (preview.hasZeroCostProduct) ...[
                CheckboxListTile(
                  key: const ValueKey('zero-cost-ack'),
                  contentPadding: EdgeInsets.zero,
                  title:
                      const Text('أؤكد السماح بالاستيراد مع منتج بتكلفة صفرية'),
                  value: _allowZeroCost,
                  onChanged: (v) => setState(() => _allowZeroCost = v ?? false),
                ),
              ],
              for (final blocking in preview.blockingErrors)
                Text(blocking.message,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              key: const ValueKey('confirm-import-button'),
              onPressed: _confirmEnabled ? _confirmImport : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('تأكيد الاستيراد'),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _cancelPreview,
            child: const Text('إلغاء'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildImporting() {
    return const [
      SizedBox(height: 8),
      Center(child: CircularProgressIndicator()),
      SizedBox(height: 8),
      Center(child: Text('جارٍ الاستيراد...')),
    ];
  }

  List<Widget> _buildSummary() {
    final outcome = _outcome!;
    return [
      Card(
        color: outcome.status == WorkbookImportStatus.succeeded
            ? Colors.green.shade50
            : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outcome.status.arabicLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('الملف: ${outcome.fileName}'),
              if (outcome.fileSha256.isNotEmpty)
                Text(
                    'بصمة الملف: ${outcome.fileSha256.substring(0, outcome.fileSha256.length.clamp(0, 12))}…'),
              if (outcome.originalImportedAt != null)
                Text('تاريخ الاستيراد الأصلي: ${outcome.originalImportedAt}'),
              if (outcome.status == WorkbookImportStatus.succeeded) ...[
                Text('منتجات: ${outcome.counts.products}'),
                Text('مبيعات: ${outcome.counts.sales}'),
                Text('مرتجعات: ${outcome.counts.returns}'),
                Text('مصروفات: ${outcome.counts.expenses}'),
                Text('تعديلات جرد: ${outcome.counts.adjustments}'),
                if (outcome.batchId != null)
                  Text('رقم الدفعة: ${outcome.batchId}'),
              ],
              for (final warning in outcome.warnings)
                Text('تنبيه: $warning',
                    style: const TextStyle(color: Colors.orange)),
              for (final error in outcome.errors)
                Text(error, style: const TextStyle(color: Colors.red)),
              if (outcome.rolledBack)
                const Text('لم يتم حفظ أي بيانات وتم التراجع عن كل التغييرات.',
                    style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: () => setState(_resetFlow),
        child: const Text('استيراد ملف آخر'),
      ),
    ];
  }
}
