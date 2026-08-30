import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config/app_config.dart';
import 'services/app_crash_handler.dart';
import 'database/database_helper.dart';
import 'database/user_repository.dart';
import 'licensing/licensing.dart';
import 'licensing/cloud_licensing_service.dart';
import 'rbac/permission_sync_service.dart';
import 'services/session_state.dart';
import 'services/permissions.dart';
import 'services/permission_resolver.dart';
import 'services/app_settings.dart';
import 'services/active_shop_context.dart';
import 'services/cloud_session_resume.dart';
import 'services/seller_session_provisioning.dart';
import 'services/shop_profile_service.dart';
import 'services/shop_resolver.dart';
import 'models/shop_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/accept_invitation_screen.dart';
import 'screens/auth/first_owner_setup_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/returns/returns_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/inventory_count/inventory_count_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'sync/sync_cloud_operations_transport.dart';
import 'sync/sync_runtime.dart';

void main() {
  // Phase P (WS-8): centralized crash/error capture. The Flutter binding is
  // initialized INSIDE the same guarded zone that owns runApp so binding
  // ownership and app execution share one Dart Zone (Flutter debugCheckZone
  // invariant). Every uncaught error — framework, platform or zone-level —
  // is routed through the no-secret sink (redacts configured credentials).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppCrashHandler.install();
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Initialize Supabase if configured (Phase D).
      // When not configured (placeholders), Supabase is skipped and the app
      // operates in offline-only mode.
      if (AppConfig.isConfigured) {
        try {
          await Supabase.initialize(
            url: AppConfig.supabaseUrl,
            publishableKey: AppConfig.supabaseAnonKey,
          );
        } catch (_) {
          // Supabase initialization failure — app operates in offline mode.
        }
      }

      runApp(const MyApp());
    },
    (error, stack) =>
        AppCrashHandler.report('Uncaught zone error: $error', stack),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color _brandColor = const Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    ShopProfileService.instance.addListener(_onProfileChanged);
    _loadBrandColor();
  }

  @override
  void dispose() {
    ShopProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _loadBrandColor() async {
    try {
      final hex = await AppSettings.getBrandColor();
      final color = _parseHexColor(hex);
      if (mounted) setState(() => _brandColor = color);
    } catch (_) {
      // Keep default brand color
    }
  }

  static Color _parseHexColor(String hex) {
    try {
      var h = hex.replaceFirst('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse('0x$h'));
    } catch (_) {
      return const Color(0xFF0D47A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = ShopProfileService.instance.current.shopName.trim();
    return MaterialApp(
      title:
          'إدارة ${shopName.isEmpty ? ShopProfile.neutralShopName : shopName}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandColor,
          brightness: Brightness.light,
        ).copyWith(primary: _brandColor),
        scaffoldBackgroundColor: Colors.grey.shade50,
        fontFamily: 'Noto Sans Arabic',
        appBarTheme: AppBarTheme(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SessionState _sessionState = SessionState();
  final UserRepository _userRepo = UserRepository();
  bool _isInitializing = true;
  bool _hasUsers = false;
  bool _cloudAvailable = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final db = await DatabaseHelper.instance.database;
    await AppSettings.initializeDefaults();
    await PermissionResolver.instance.refresh();
    await ShopProfileService.instance.load();

    // Initialize licensing and wire enforcement into the database layer.
    // Phase E: CloudLicensingService replaces the old LicensingService as
    // the enforcement boundary. The old service is retained as fallback.
    final cloudLicensingService = CloudLicensingService.instance;
    await cloudLicensingService.initialize();
    DatabaseHelper.setLicensingEnforcer(
        () => cloudLicensingService.enforceActive());

    // Phase H: wire the active-shop provider so enqueue-after-write hooks can
    // attribute sync queue entries to the correct tenant. Phase J: the
    // provider now delegates to the single authoritative ActiveShopContext
    // (validated membership) instead of reading the session ad hoc.
    DatabaseHelper.setSyncShopIdProvider(
        () async => ActiveShopContext.instance.shopId);

    // Phase P (WS-5): wire the active-writer identity provider so every sync
    // queue entry carries a durable per-write permission/entitlement snapshot
    // (revoked-seller adjudication). Reads the LIVE session each call; the
    // database-layer facts (permission granted, entitlement active, shop and
    // entity identity, write instant) are always captured regardless.
    DatabaseHelper.setWriterSnapshotProvider(() async {
      final user = _sessionState.currentUser;
      String? cloudUserId;
      try {
        cloudUserId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {
        cloudUserId = null;
      }
      if (user == null) {
        return {'cloud_user_uuid': cloudUserId};
      }
      return {
        'role': user.role.name,
        'display_name': user.displayName,
        'cloud_user_uuid': cloudUserId,
      };
    });

    // Phase J (WS1): wire the membership validator that authorizes every
    // bind/switch of the tenant context against the user's ACTIVE cloud
    // memberships. Fail-closed: any resolver error rejects the shop.
    ActiveShopContext.instance.configure(
      membershipValidator: (shopId) async {
        try {
          final memberships = await ShopResolver().getAllMemberships();
          return memberships.any((m) => m.isActive && m.shopId == shopId);
        } catch (_) {
          return false;
        }
      },
    );

    // Phase P (WS-1): configure the application-owned sync runtime. The
    // production A1 transport is attached here (A2) so the runtime genuinely
    // owns a real SyncCloudOperations implementation. Attaching the
    // transport performs ZERO network activity — the constructor is dormant
    // — and the drain seam (AppConfig.syncDrainEnabled) defaults to FALSE
    // (owner decision, plan §N): with it off the runtime only manages and
    // publishes queue status; it constructs no SyncWorker/SyncEngine and
    // performs zero cloud calls. Shop/license/connectivity gating inside
    // ensureStarted keeps offline-only tenants untouched, and every operation
    // remains scoped by the persisted queue shop_id (never the ambient shop).
    SyncRuntime.instance.configure(
      database: db,
      adapters: buildStandardAdapters(),
      cloudOperations: SyncCloudOperationsTransport(
        rpc: (function, params) =>
            Supabase.instance.client.rpc(function, params: params),
        allowOversell: true,
      ).toOperations(),
      sessionState: _sessionState,
      shopIdProvider: () async => ActiveShopContext.instance.shopId,
      licenseCheck: () async {
        try {
          await cloudLicensingService.enforceActive();
          return true;
        } catch (_) {
          return false;
        }
      },
      connectivityCheck: () async =>
          _sessionState.isCloudLinked && _sessionState.isOnline,
      drainEnabled: AppConfig.syncDrainEnabled,
    );

    // Phase F: Permission sync service is available for cloud permission
    // synchronization. It will be triggered after cloud session is established.

    // Check if Supabase is available and try to restore cloud session.
    if (AppConfig.isConfigured) {
      try {
        final auth = Supabase.instance.client.auth;
        final currentSession = auth.currentSession;
        if (currentSession != null && !currentSession.isExpired) {
          _cloudAvailable = true;
        }
      } catch (_) {
        _cloudAvailable = false;
      }
    }

    // Phase K (D4): cold-start session resume. A valid restored Supabase
    // session (the COMMON case on Android after process death) must bind the
    // active shop context, arm strict tenant isolation and refresh synced
    // permissions BEFORE any tenant-owned data renders — the same sequence
    // LoginScreen performs after interactive cloud login. Fail-closed: if no
    // authorized shop can be bound, nothing is bound and unbound semantics
    // apply.
    if (AppConfig.isConfigured && _cloudAvailable) {
      try {
        await resumeCloudSessionAtStartup(
          resolveActiveShop: () => ShopResolver().resolveActiveShop(),
        );
      } catch (_) {
        // Resume must never block startup; offline-first boot continues.
      }
    }

    // Phase P (WS-1): after cold-start resume the runtime establishes (or
    // re-provisions) the drain for the bound tenant. Fail-closed when no
    // shop is bound; zero network when the drain seam is OFF.
    try {
      await SyncRuntime.instance.ensureStarted();
      await SyncRuntime.instance.publishStatus();
    } catch (_) {
      // Runtime provisioning must never block startup.
    }

    final hasUsers = await _userRepo.hasAnyUser();
    if (mounted) {
      setState(() {
        _hasUsers = hasUsers;
        _isInitializing = false;
      });
    }
  }

  void _onOwnerSetupComplete() {
    setState(() => _hasUsers = true);
  }

  void _onLogin() {
    setState(() {});
    // Phase P (WS-1): re-establish the drain for the freshly bound tenant.
    try {
      SyncRuntime.instance.ensureStarted();
    } catch (_) {
      // Best-effort; the periodic cycle also re-evaluates on every tick.
    }
  }

  void _onLogout() {
    _sessionState.logout();
    // Phase P (WS-1): tear down the drain runtime for the logged-out tenant.
    try {
      SyncRuntime.instance.stop();
    } catch (_) {
      // Best-effort teardown; ensureStarted is fail-closed on next session.
    }
    // Phase J: release the tenant context and suspend strict isolation for
    // this runtime. The persistence marker survives so the next authorized
    // login re-evaluates and re-arms (TenantIsolationGate.restoreAtStartup).
    ActiveShopContext.instance.unbind();
    // Phase F: Clear cloud permission state on logout.
    PermissionSyncService.instance.reset();
    // Sign out from Supabase if cloud session was active.
    if (_cloudAvailable) {
      try {
        Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Best-effort cloud sign out.
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('جاري التحميل...',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasUsers) {
      // Phase L (D-L3): fresh-device bootstrap. When Supabase is configured
      // AND no local users exist, offer Owner Setup (first-come ownership,
      // unchanged) ALONGSIDE the seller cloud-login / invitation path. A
      // non-owner cloud login provisions its own cache row and proceeds;
      // it can NEVER create or elevate an owner role locally (enforced in
      // the provisioning service). Without Supabase the historical
      // behavior stands unchanged.
      if (offersFreshDeviceCloudBootstrap(
        hasLocalUsers: _hasUsers,
        supabaseConfigured: AppConfig.isConfigured,
      )) {
        return _FreshDeviceGate(
          sessionState: _sessionState,
          onOwnerSetupComplete: _onOwnerSetupComplete,
          onSellerAuthenticated: () => setState(() => _hasUsers = true),
        );
      }
      return FirstOwnerSetupScreen(onComplete: _onOwnerSetupComplete);
    }

    if (!_sessionState.isLoggedIn) {
      return LoginScreen(sessionState: _sessionState, onLoginSuccess: _onLogin);
    }

    // Phase L (D-L5): permission-driven shell for EVERY logged-in user.
    // The former hardcoded salesOnly -> SalesOnlyShell routing is retired;
    // FullAppShell's existing permission-filtered navigation yields the
    // seller experience naturally (default salesOnly => exactly the Sales
    // tab), and any owner-granted extra permissions become visible
    // immediately. UI visibility is convenience only: enforcement stays at
    // DatabaseHelper._requirePermission + licensing enforcer + server
    // RPC/RLS.
    return FullAppShell(
      sessionState: _sessionState,
      onLogout: _onLogout,
    );
  }
}

/// Phase L (D-L3): fresh-device bootstrap surface. Offers Owner Setup
/// (unchanged first-come ownership) alongside the seller cloud login and
/// the invitation-acceptance entry, per the locked Phase L plan section 5.
class _FreshDeviceGate extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback onOwnerSetupComplete;
  final VoidCallback onSellerAuthenticated;

  const _FreshDeviceGate({
    required this.sessionState,
    required this.onOwnerSetupComplete,
    required this.onSellerAuthenticated,
  });

  @override
  State<_FreshDeviceGate> createState() => _FreshDeviceGateState();
}

enum _FreshDeviceView { landing, ownerSetup, cloudLogin }

class _FreshDeviceGateState extends State<_FreshDeviceGate> {
  _FreshDeviceView _view = _FreshDeviceView.landing;

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _FreshDeviceView.ownerSetup:
        return FirstOwnerSetupScreen(onComplete: widget.onOwnerSetupComplete);
      case _FreshDeviceView.cloudLogin:
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: const Text('دخول الموظفين'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    setState(() => _view = _FreshDeviceView.landing),
              ),
            ),
            body: LoginScreen(
              sessionState: widget.sessionState,
              onLoginSuccess: widget.onSellerAuthenticated,
              initialMode: LoginMode.cloud,
              allowLocalMode: false,
            ),
          ),
        );
      case _FreshDeviceView.landing:
        return _buildLanding();
    }
  }

  Widget _buildLanding() {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.storefront,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'مرحباً بك في إدارة المتجر',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر كيفية بدء الاستخدام على هذا الجهاز',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _view = _FreshDeviceView.ownerSetup),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('إعداد المالك',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _view = _FreshDeviceView.cloudLogin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cloud_outlined),
                        label: const Text('تسجيل دخول موظف',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                const AcceptInvitationScreen(),
                          ));
                          // After acceptance the local cache row exists and
                          // membership is ACTIVE; continue to the normal
                          // login/shell flow.
                          if (context.mounted) {
                            widget.onSellerAuthenticated();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.mark_email_read),
                        label: const Text('قبول دعوة',
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

class FullAppShell extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback onLogout;

  const FullAppShell({
    super.key,
    required this.sessionState,
    required this.onLogout,
  });

  @override
  State<FullAppShell> createState() => _FullAppShellState();
}

class _FullAppShellState extends State<FullAppShell> {
  int _currentIndex = 0;

  // Phase L (D-L5): nav destinations are derived from the CURRENT session
  // on every build so a session swap re-filters permissions and rebuilds
  // the embedded screens against the active identity.
  List<_NavItem> get _allNavItems => [
        _NavItem(
            0,
            'لوحة التحكم',
            Icons.dashboard,
            AppPermission.canAccessDashboard,
            DashboardScreen(sessionState: widget.sessionState)),
        _NavItem(
            1,
            'المخزن',
            Icons.inventory_2,
            AppPermission.canAccessInventory,
            InventoryScreen(sessionState: widget.sessionState)),
        _NavItem(
            2,
            'المبيعات',
            Icons.shopping_cart,
            AppPermission.canAccessSales,
            SalesScreen(
                showAppBar: false,
                showFab: true,
                sessionState: widget.sessionState)),
        _NavItem(
            3,
            'المرتجعات',
            Icons.assignment_return,
            AppPermission.canAccessReturns,
            ReturnsScreen(sessionState: widget.sessionState)),
        _NavItem(
            4,
            'المصروفات',
            Icons.money_off,
            AppPermission.canAccessExpenses,
            ExpensesScreen(sessionState: widget.sessionState)),
        _NavItem(5, 'الجرد', Icons.fact_check, AppPermission.canAccessStocktake,
            InventoryCountScreen(sessionState: widget.sessionState)),
      ];

  List<_NavItem> get _visibleNavItems {
    return _allNavItems
        .where((item) => widget.sessionState.hasPermission(item.permission))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    widget.sessionState.addListener(_onSessionChanged);
  }

  @override
  void didUpdateWidget(covariant FullAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sessionState, widget.sessionState)) {
      oldWidget.sessionState.removeListener(_onSessionChanged);
      widget.sessionState.addListener(_onSessionChanged);
    }
  }

  @override
  void dispose() {
    widget.sessionState.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!widget.sessionState.isLoggedIn && mounted) {
      widget.onLogout();
    }
  }

  void _navigateTo(int index) {
    final items = _visibleNavItems;
    if (index >= 0 && index < items.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleNavItems;
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(items.isNotEmpty ? items[_currentIndex].label : ''),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            if (widget.sessionState.hasPermission(AppPermission.canManageUsers))
              IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'إدارة المستخدمين',
                onPressed: () => _openUserManagement(context),
              ),
            if (widget.sessionState.hasPermission(AppPermission.canCreateSales))
              IconButton(
                icon: const Icon(Icons.person_search),
                tooltip: 'العملاء',
                onPressed: () => _openCustomers(context),
              ),
            if (widget.sessionState
                .hasPermission(AppPermission.canAccessSettings))
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'الإعدادات',
                onPressed: () => _openSettings(context),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${widget.sessionState.currentUser?.displayName ?? ''} | ${widget.sessionState.currentRole?.displayName ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: items.isNotEmpty
            ? items[_currentIndex].screen
            : const SizedBox.shrink(),
        // Phase L (D-L5): BottomNavigationBar requires >= 2 destinations;
        // a seller restricted to exactly ONE permitted tab renders without
        // the bar (behaviorally equivalent surface set to the retired
        // single-screen shell).
        bottomNavigationBar: items.length >= 2
            ? BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _navigateTo,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                items: items
                    .map((item) => BottomNavigationBarItem(
                          icon: Icon(item.icon),
                          label: item.label,
                        ))
                    .toList(),
              )
            : null,
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

  void _openCustomers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomersScreen(sessionState: widget.sessionState),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(sessionState: widget.sessionState),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final String label;
  final IconData icon;
  final AppPermission permission;
  final Widget screen;

  _NavItem(this.index, this.label, this.icon, this.permission, this.screen);
}
