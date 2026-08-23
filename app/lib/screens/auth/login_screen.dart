import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../database/database_helper.dart';
import '../../database/user_repository.dart';
import '../../models/cloud_session.dart';
import '../../models/shop_profile.dart';
import '../../rbac/permission_sync_service.dart';
import '../../services/active_shop_context.dart';
import '../../services/app_settings.dart';
import '../../services/seller_session_provisioning.dart';
import '../../services/session_state.dart';
import '../../services/shop_profile_service.dart';
import '../../services/shop_resolver.dart';
import '../../services/tenant_isolation_gate.dart';
import '../../licensing/cloud_licensing_service.dart';
import '../../widgets/shop_logo.dart';
import 'accept_invitation_screen.dart';

/// Login surface modes. The LOCAL username/password mode remains EXACTLY
/// as before and stays the primary presentation (Windows contract). The
/// CLOUD mode is the Phase L seller email/password path (D-L1).
enum LoginMode { local, cloud }

class LoginScreen extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback? onLoginSuccess;

  /// Initial mode when the screen opens (fresh-device bootstrap opens in
  /// cloud mode; default remains local).
  final LoginMode initialMode;

  /// Whether the local username/password mode is offered at all.
  /// The fresh-device seller bootstrap hides it because no local user row
  /// exists yet by definition.
  final bool allowLocalMode;

  const LoginScreen({
    super.key,
    required this.sessionState,
    this.onLoginSuccess,
    this.initialMode = LoginMode.local,
    this.allowLocalMode = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cloudEmailController = TextEditingController();
  final _cloudPasswordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _repo = UserRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCloudPassword = true;
  String? _error;
  late LoginMode _mode;

  bool get _cloudModeAvailable => AppConfig.isConfigured;

  @override
  void initState() {
    super.initState();
    _mode = (_cloudModeAvailable && !widget.allowLocalMode)
        ? LoginMode.cloud
        : widget.initialMode;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _cloudEmailController.dispose();
    _cloudPasswordController.dispose();
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
        final membership = await ShopResolver().resolveActiveShop();

        // Phase J (WS1 lifecycle): bind the validated tenant context BEFORE
        // any runtime service consumes it.
        await ActiveShopContext.instance.bind(membership.shopId);

        widget.sessionState.setCloudSession(CloudSession(
          userId: session.user.id,
          activeShopId: membership.shopId,
          membershipRole: membership.membershipRole,
          membershipStatus: membership.membershipStatus,
        ));

        try {
          await TenantIsolationGate().restoreAtStartup(
            db: await DatabaseHelper.instance.database,
            shopId: membership.shopId,
          );
        } catch (_) {
          // Gate restoration must never block the login flow.
        }

        final cloudLicensing = CloudLicensingService.instance;
        await cloudLicensing.initialize(
          shopId: membership.shopId,
          isCloudLinked: true,
        );
        await cloudLicensing.registerDevice(membership.shopId);
        await cloudLicensing.activateDevice(membership.shopId);

        try {
          await PermissionSyncService.instance.syncPermissions(
            membership.shopId,
          );
        } catch (_) {
          // Permission sync failure — continue with local defaults.
        }
      }
    } catch (_) {
      // Cloud login failure — operate in offline mode.
      // The local session is already established.
    }
  }

  /// Phase L (D-L1): seller cloud login via OWN credentials. Runs the full
  /// provisioning sequence (sign-in -> ACTIVE membership -> bind -> arm ->
  /// license -> permission sync -> local cache row) through
  /// [provisionSellerSession]; nothing is bound or provisioned unless the
  /// whole authorized chain succeeds.
  Future<void> _cloudLogin() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final email = _cloudEmailController.text.trim();
    final password = _cloudPasswordController.text;

    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      setState(() {
        _error = 'أدخل بريداً إلكترونياً صحيحاً وكلمة مرور';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await provisionSellerSession(
        email: email,
        password: password,
      );

      if (!mounted) return;

      switch (result.status) {
        case SellerSessionStatus.success:
          widget.sessionState.login(result.user!);
          widget.sessionState.setCloudSession(CloudSession(
            userId: result.cloudUserId!,
            activeShopId: result.membership!.shopId,
            membershipRole: result.membership!.membershipRole,
            membershipStatus: result.membership!.membershipStatus,
          ));
          widget.onLoginSuccess?.call();
          break;
        case SellerSessionStatus.invalidCredentials:
          _setError('البريد الإلكتروني أو كلمة المرور غير صحيحة');
          break;
        case SellerSessionStatus.noActiveMembership:
          _setError('لا يوجد متجر نشط مرتبط بهذا الحساب، راجع مالك المتجر');
          break;
        case SellerSessionStatus.ownerRejected:
          _setError(
              'هذا الحساب حساب مالك؛ استخدم شاشة إعداد المالك لتسجيل الدخول');
          break;
        case SellerSessionStatus.bindRejected:
          _setError('تعذر ربط الحساب بالمتجر، راجع مالك المتجر');
          break;
        case SellerSessionStatus.networkUnavailable:
          _setError('لا يوجد اتصال بالإنترنت، تحقق من الشبكة وأعد المحاولة');
          break;
        case SellerSessionStatus.unknownError:
          _setError(result.errorMessage ??
              'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى');
          break;
      }
    } catch (_) {
      if (mounted) {
        _setError('حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى');
      }
    }
  }

  void _setError(String message) {
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _openAcceptInvitation() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AcceptInvitationScreen(
        initialEmail: _cloudEmailController.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final showModeSelector = _cloudModeAvailable && widget.allowLocalMode;
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
                    if (showModeSelector) ...[
                      const SizedBox(height: 12),
                      SegmentedButton<LoginMode>(
                        segments: const [
                          ButtonSegment(
                            value: LoginMode.local,
                            label: Text('حساب محلي'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: LoginMode.cloud,
                            label: Text('دخول الموظفين'),
                            icon: Icon(Icons.cloud_outlined),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mode = selection.first;
                            _error = null;
                          });
                        },
                      ),
                    ],
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
                    if (_mode == LoginMode.local)
                      ..._buildLocalForm()
                    else
                      ..._buildCloudForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLocalForm() {
    return [
      TextField(
        controller: _usernameController,
        focusNode: _usernameFocus,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
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
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildButtonChild('تسجيل الدخول'),
        ),
      ),
    ];
  }

  List<Widget> _buildCloudForm() {
    return [
      TextField(
        controller: _cloudEmailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'البريد الإلكتروني',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.email),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _cloudPasswordController,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          if (!_isLoading) _cloudLogin();
        },
        obscureText: _obscureCloudPassword,
        decoration: InputDecoration(
          labelText: 'كلمة المرور',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureCloudPassword
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: () =>
                setState(() => _obscureCloudPassword = !_obscureCloudPassword),
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _cloudLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildButtonChild('دخول سحابي'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _isLoading ? null : _openAcceptInvitation,
        icon: const Icon(Icons.mark_email_read, size: 18),
        label: const Text('لديك دعوة؟ قبول الدعوة'),
      ),
    ];
  }

  Widget _buildButtonChild(String label) {
    if (!_isLoading) {
      return Text(label, style: const TextStyle(fontSize: 16));
    }
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
