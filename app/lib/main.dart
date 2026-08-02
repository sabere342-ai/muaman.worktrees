import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/database_helper.dart';
import 'database/user_repository.dart';
import 'models/user_role.dart';
import 'services/session_state.dart';
import 'services/permissions.dart';
import 'services/app_settings.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة محل مؤمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade50,
        fontFamily: 'Noto Sans Arabic',
        appBarTheme: const AppBarTheme(
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await DatabaseHelper.instance.database;
    await AppSettings.initializeDefaults();
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
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
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
          child: const SalesScreen(showAppBar: false, showFab: true),
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
    _NavItem(0, 'لوحة التحكم', Icons.dashboard,
        AppPermission.canAccessDashboard, const DashboardScreen()),
    _NavItem(1, 'المخزن', Icons.inventory_2, AppPermission.canAccessInventory,
        const InventoryScreen()),
    _NavItem(2, 'المبيعات', Icons.shopping_cart, AppPermission.canAccessSales,
        const SalesScreen(showAppBar: false, showFab: true)),
    _NavItem(3, 'المرتجعات', Icons.assignment_return,
        AppPermission.canAccessReturns, const ReturnsScreen()),
    _NavItem(4, 'المصروفات', Icons.money_off, AppPermission.canAccessExpenses,
        const ExpensesScreen()),
    _NavItem(5, 'الجرد', Icons.fact_check, AppPermission.canAccessStocktake,
        const InventoryCountScreen()),
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
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            if (widget.sessionState.hasPermission(AppPermission.canManageUsers))
              IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'إدارة المستخدمين',
                onPressed: () => _openUserManagement(context),
              ),
            if (widget.sessionState.hasPermission(AppPermission.canManageUsers))
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

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(),
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
