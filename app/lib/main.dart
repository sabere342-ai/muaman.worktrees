import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config/app_config.dart';
import 'database/database_helper.dart';
import 'database/user_repository.dart';
import 'licensing/licensing.dart';
import 'licensing/cloud_licensing_service.dart';
import 'models/user_role.dart';
import 'rbac/permission_sync_service.dart';
import 'services/session_state.dart';
import 'services/permissions.dart';
import 'services/permission_resolver.dart';
import 'services/app_settings.dart';
import 'services/active_shop_context.dart';
import 'services/cloud_session_resume.dart';
import 'services/shop_profile_service.dart';
import 'services/shop_resolver.dart';
import 'models/shop_profile.dart';
import 'screens/auth/login_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    await DatabaseHelper.instance.database;
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
  }

  void _onLogout() {
    _sessionState.logout();
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
      return FirstOwnerSetupScreen(onComplete: _onOwnerSetupComplete);
    }

    if (!_sessionState.isLoggedIn) {
      return LoginScreen(sessionState: _sessionState, onLoginSuccess: _onLogin);
    }

    final role = _sessionState.currentRole;

    if (role == UserRole.salesOnly) {
      return SalesOnlyShell(
        sessionState: _sessionState,
        onLogout: _onLogout,
      );
    }

    return FullAppShell(
      sessionState: _sessionState,
      onLogout: _onLogout,
    );
  }
}

class SalesOnlyShell extends StatelessWidget {
  final SessionState sessionState;
  final VoidCallback onLogout;

  const SalesOnlyShell({
    super.key,
    required this.sessionState,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${sessionState.currentUser?.displayName ?? ''} | ${sessionState.currentRole?.displayName ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: onLogout,
            ),
          ],
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              onLogout();
            }
          },
          child: SalesScreen(
              showAppBar: false, showFab: true, sessionState: sessionState),
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

  late final List<_NavItem> _allNavItems = [
    _NavItem(
        0,
        'لوحة التحكم',
        Icons.dashboard,
        AppPermission.canAccessDashboard,
        DashboardScreen(sessionState: widget.sessionState)),
    _NavItem(1, 'المخزن', Icons.inventory_2, AppPermission.canAccessInventory,
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
    _NavItem(4, 'المصروفات', Icons.money_off, AppPermission.canAccessExpenses,
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
        bottomNavigationBar: BottomNavigationBar(
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
