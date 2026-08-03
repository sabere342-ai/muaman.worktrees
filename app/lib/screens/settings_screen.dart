import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../database/workbook_importer.dart';
import '../services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _licenseController = TextEditingController();
  final _workbookPathController = TextEditingController();
  String _buttonStyle = 'filled';
  String _supportPhone = AppSettings.defaultSupportPhone;
  String _licenseStatus = 'inactive';
  bool _isSaving = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

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
    super.dispose();
  }
}
