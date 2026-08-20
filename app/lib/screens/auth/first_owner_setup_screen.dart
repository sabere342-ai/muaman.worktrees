import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../database/user_repository.dart';
import '../../models/user_role.dart';
import '../../services/app_settings.dart';
import '../../services/identity_linker.dart';
import '../../licensing/cloud_licensing_service.dart';

class FirstOwnerSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FirstOwnerSetupScreen({super.key, required this.onComplete});

  @override
  State<FirstOwnerSetupScreen> createState() => _FirstOwnerSetupScreenState();
}

class _FirstOwnerSetupScreenState extends State<FirstOwnerSetupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _repo = UserRepository();
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createOwner() async {
    setState(() {
      _error = null;
      _isSaving = true;
    });

    final name = _nameController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final email = _emailController.text.trim();

    if (name.trim().isEmpty) {
      setState(() {
        _error = 'الاسم مطلوب';
        _isSaving = false;
      });
      return;
    }
    if (username.trim().isEmpty) {
      setState(() {
        _error = 'اسم المستخدم مطلوب';
        _isSaving = false;
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _error = 'كلمة المرور مطلوبة';
        _isSaving = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        _isSaving = false;
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _error = 'كلمة المرور وتأكيدها غير متطابقين';
        _isSaving = false;
      });
      return;
    }

    try {
      final hasUsers = await _repo.hasAnyUser();
      if (hasUsers) {
        setState(() {
          _error = 'يوجد مستخدمون بالفعل. لا يمكن إنشاء مالك أولي جديد';
          _isSaving = false;
        });
        return;
      }

      // If Supabase is configured and email is provided, attempt cloud onboarding.
      if (AppConfig.isConfigured && email.isNotEmpty) {
        final linker = IdentityLinker();
        final shopName = await AppSettings.getValue('shopProfile.shopName');
        final effectiveShopName = shopName.isNotEmpty ? shopName : 'المتجر';

        final result = await linker.onboardFreshOwner(
          displayName: name,
          username: username,
          password: password,
          email: email,
          shopName: effectiveShopName,
        );

        if (result.isSuccess) {
          // Phase E: Start trial, register and activate device for the new shop.
          if (result.shopId != null) {
            try {
              final cloudLicensing = CloudLicensingService.instance;
              await cloudLicensing.initialize(
                shopId: result.shopId,
                isCloudLinked: true,
              );
              await cloudLicensing.startTrial(result.shopId!);
              await cloudLicensing.registerDevice(result.shopId!);
              await cloudLicensing.activateDevice(result.shopId!);
            } catch (_) {
              // Licensing setup failure — shop is created, licensing can
              // be resolved on next login.
            }
          }
          if (mounted) widget.onComplete();
          return;
        }

        // If cloud account already exists, local user was created.
        // Proceed to local-only mode.
        if (result.type == LinkResultType.cloudAccountExists ||
            result.type == LinkResultType.networkUnavailable) {
          // Local user was already created by IdentityLinker.
          if (mounted) widget.onComplete();
          return;
        }

        // Unknown error — local user may or may not have been created.
        // Check if local user exists.
        final hasUsersNow = await _repo.hasAnyUser();
        if (hasUsersNow) {
          if (mounted) widget.onComplete();
          return;
        }
      }

      // Fallback: local-only owner creation (no cloud).
      await _repo.createUser(
        displayName: name,
        username: username,
        password: password,
        role: UserRole.owner,
      );

      if (mounted) {
        widget.onComplete();
      }
    } on WeakPasswordException {
      setState(() {
        _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        _isSaving = false;
      });
    } on DuplicateUsernameException {
      setState(() {
        _error = 'اسم المستخدم موجود بالفعل';
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 80, color: Colors.teal.shade700),
                    const SizedBox(height: 16),
                    Text('إعداد النظام',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('يرجى إنشاء حساب المالك الأول',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_error!,
                            style: TextStyle(color: Colors.red.shade800)),
                      ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (AppConfig.isConfigured)
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني (للحساب السحابي)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    if (AppConfig.isConfigured) const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _createOwner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('إنشاء حساب المالك',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
