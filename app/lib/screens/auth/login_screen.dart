import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../database/user_repository.dart';
import '../../models/shop_profile.dart';
import '../../services/app_settings.dart';
import '../../services/session_state.dart';
import '../../models/cloud_session.dart';
import '../../services/shop_profile_service.dart';
import '../../services/shop_resolver.dart';
import '../../widgets/shop_logo.dart';

class LoginScreen extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback? onLoginSuccess;

  const LoginScreen(
      {super.key, required this.sessionState, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _repo = UserRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.trim().isEmpty || password.isEmpty) {
      setState(() {
        _error = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await _repo.authenticate(username, password);

      if (user == null) {
        final existingUser = await _repo.getUserByUsername(username);
        if (existingUser != null && !existingUser.isActive) {
          setState(() {
            _error = 'هذا الحساب غير نشط، راجع مالك النظام';
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _error = 'اسم المستخدم أو كلمة المرور غير صحيحة';
          _isLoading = false;
        });
        return;
      }

      await _repo.updateLastLogin(user.id!);
      final updatedUser = await _repo.getUserById(user.id!);

      if (mounted && updatedUser != null) {
        widget.sessionState.login(updatedUser);

        // Attempt cloud session if user has cloud link and Supabase is configured.
        await _attemptCloudSession(updatedUser, password);

        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تسجيل الدخول';
          _isLoading = false;
        });
      }
    }
  }

  /// After successful local auth, attempt cloud login if the user is cloud-linked.
  Future<void> _attemptCloudSession(dynamic user, String password) async {
    if (!AppConfig.isConfigured) return;
    if (user.cloudUuid == null || (user.cloudUuid as String).isEmpty) return;

    try {
      final cloudEmail = await AppSettings.getValue('cloud.auth.email');
      if (cloudEmail.isEmpty) return;

      final auth = Supabase.instance.client.auth;
      await auth.signInWithPassword(email: cloudEmail, password: password);

      final session = auth.currentSession;
      if (session != null) {
        final resolver = ShopResolver();
        final membership = await resolver.resolveActiveShop();
        widget.sessionState.setCloudSession(CloudSession(
          userId: session.user.id,
          activeShopId: membership.shopId,
          membershipRole: membership.membershipRole,
          membershipStatus: membership.membershipStatus,
        ));
      }
    } catch (_) {
      // Cloud login failure — operate in offline mode.
      // The local session is already established.
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
                    const ShopLogo(size: 80),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: ShopProfileService.instance,
                      builder: (context, _) {
                        final shopName =
                            ShopProfileService.instance.current.shopName.trim();
                        return Text(
                          'إدارة ${shopName.isEmpty ? ShopProfile.neutralShopName : shopName}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('تسجيل الدخول',
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
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isLoading) _login();
                      },
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('تسجيل الدخول',
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
