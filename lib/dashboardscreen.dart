import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_1/NotificationService.dart';
import 'package:flutter_project_1/Rolemanagement.dart';
import 'package:flutter_project_1/UserManagementScreen.dart';
import 'package:flutter_project_1/loginscreen.dart';
import 'package:flutter_project_1/statistics_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DiamondPaintsApp());
}

class DiamondPaintsApp extends StatelessWidget {
  const DiamondPaintsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diamond Paints',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ─── Colour Palette ───────────────────────────────────────────────────────────
class AppColors {
  static const bg          = Color(0xFFF5F7FA);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F4F9);
  static const primary     = Color(0xFF1A2B4A);
  static const primaryMid  = Color(0xFF243B5E);
  static const accent      = Color(0xFF3B7DD8);
  static const accentLight = Color(0xFFEBF3FF);
  static const red         = Color(0xFFE53935);
  static const redLight    = Color(0xFFFFEBEE);
  static const warning     = Color(0xFFF57F17);
  static const warningLight= Color(0xFFFFF8E1);
  static const success     = Color(0xFF26A69A);
  static const purple      = Color(0xFF5C35B5);
  static const purpleLight = Color(0xFFEFEBFA);
  static const textHead    = Color(0xFF1A2B4A);
  static const textBody    = Color(0xFF3A4A5C);
  static const textMuted   = Color(0xFF8A9BB5);
  static const border      = Color(0xFFE2E8F0);
  static const divider     = Color(0xFFEDF2F7);
}

// ─── API Constants ────────────────────────────────────────────────────────────
class ApiConstants {
  static const baseUrl   = 'http://125.209.66.147:5001/api';
  static const loginUrl  = 'http://125.209.66.147:5001/api/auth/signin';
  static const adminUser = 'superadmin';
  static const adminPass = 'admin123';

  static Map<String, String> headersWithToken(String token) => {
    'Content-Type' : 'application/json',
    'Authorization': 'Bearer $token',
  };
}

// ─── Token Manager ────────────────────────────────────────────────────────────
class _TokenManager {
  static String?   _cachedToken;
  static DateTime? _expiresAt;

  static Future<String> getToken() async {
    if (_cachedToken != null &&
        _expiresAt   != null &&
        DateTime.now().isBefore(_expiresAt!)) {
      return _cachedToken!;
    }
    return _fetchToken();
  }

  static void invalidate() {
    _cachedToken = null;
    _expiresAt   = null;
  }

  static Future<String> _fetchToken() async {
    final res = await http
        .post(
          Uri.parse(ApiConstants.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usernameOrEmail': ApiConstants.adminUser,
            'password'       : ApiConstants.adminPass,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body  = jsonDecode(res.body);
      final token = body['token'] ??
          body['accessToken'] ??
          body['data']?['token'] ??
          body['data']?['accessToken'];
      if (token == null) throw Exception('No token in response.');
      _cachedToken = token as String;
      _expiresAt   = DateTime.now().add(const Duration(minutes: 55));
      return _cachedToken!;
    }
    throw Exception('Token fetch failed — ${res.statusCode}');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── USER PERMISSIONS ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════
//
// Login API response shape:
//   {
//     "data": {
//       "permissions": {
//         "role": ["read","create","update","delete"],
//         "user": ["read","create","update","delete"],
//         ...
//       }
//     }
//   }
//
// Usage in login screen:
//   final permissions = UserPermissions.fromLoginResponse(
//     loginResponse['data'] as Map<String, dynamic>,
//   );

class UserPermissions {
  final Map<String, List<String>> _map;

  const UserPermissions(this._map);

  /// Login response ka poora "data" object pass karein
  factory UserPermissions.fromLoginResponse(Map<String, dynamic> data) {
    final raw = data['permissions'];
    if (raw == null || raw is! Map) return const UserPermissions({});
    final map = <String, List<String>>{};
    (raw as Map).forEach((k, v) {
      if (v is List) {
        map[k.toString()] = v.map((e) => e.toString()).toList();
      }
    });
    return UserPermissions(map);
  }

  /// fromJson — login screen compatibility
  /// Directly permissions map pass karein
  factory UserPermissions.fromJson(Map<String, dynamic> permissionsMap) {
    final map = <String, List<String>>{};
    permissionsMap.forEach((k, v) {
      if (v is List) {
        map[k] = v.map((e) => e.toString()).toList();
      }
    });
    return UserPermissions(map);
  }

  const UserPermissions.none() : _map = const {};
  factory UserPermissions.empty() => const UserPermissions.none();

  bool has(String key)       => (_map[key]?.isNotEmpty) ?? false;
  bool canRead(String key)   => _map[key]?.contains('read')   ?? false;
  bool canCreate(String key) => _map[key]?.contains('create') ?? false;
  bool canUpdate(String key) => _map[key]?.contains('update') ?? false;
  bool canDelete(String key) => _map[key]?.contains('delete') ?? false;

  // Role Management screen shortcuts
  bool get canViewRoles    => canRead('role');
  bool get canCreateRoles  => canCreate('role');
  bool get canEditRoles    => canUpdate('role');
  bool get canDeleteRoles  => canDelete('role');
  bool get hasAnyRoleAction =>
      canViewRoles || canEditRoles || canDeleteRoles;
}

// ─── Helper: Dashboard → RoleManagementScreen permissions ────────────────────
// RoleManagementScreen apni alag RoleMgmtPermissions class use karta hai.
// Yeh function dashboard ki Map-based class se woh banata hai.
RoleMgmtPermissions _toRolePerms(UserPermissions p) {
  return RoleMgmtPermissions(
    canViewRoles:   p.canRead('role'),
    canEditRoles:   p.canUpdate('role'),
    canDeleteRoles: p.canDelete('role'),
    canCreateRoles: p.canCreate('role'),
  );
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final String          currentUsername;
  final String          currentEmail;
  final UserPermissions permissions;

  const DashboardScreen({
    super.key,
    this.currentUsername = 'Super Admin',
    this.currentEmail    = 'superadmin@diamondpaint.com',
    UserPermissions? permissions,
  }) : permissions = permissions ?? const UserPermissions.none();

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  int  _navIndex  = 0;
  bool _scheduled = false;

  bool   _statsLoading = true;
  bool   _statsError   = false;
  String _debugError   = '';
  int    _totalUsers   = 0;
  int    _totalRoles   = 0;
  int    _activeUsers  = 0;

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded,              label: 'Dashboard'),
    _NavItem(icon: Icons.people_alt_rounded,             label: 'Users'),
    _NavItem(icon: Icons.bar_chart_rounded,              label: 'Stats'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget'),
  ];

  // ── Display helpers ────────────────────────────────────────────────────────
  String get _displayName =>
      widget.currentUsername.trim().isNotEmpty
          ? widget.currentUsername.trim()
          : 'User';

  String get _displayEmail => widget.currentEmail.trim();

  String get _initials {
    final n = _displayName;
    if (n.isEmpty) return 'U';
    final parts = n
        .split(RegExp(r'[\s_.]+'))
        .where((x) => x.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchStats();
    WidgetsBinding.instance.addObserver(this);
    _scheduleIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showExactAlarmDialogIfNeeded(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleIfNeeded();
  }

  Future<void> _scheduleIfNeeded() async {
    if (!_scheduled) {
      _scheduled = true;
      await NotificationService.scheduleAll();
      Future.delayed(const Duration(seconds: 35), () {
        if (mounted) setState(() => _scheduled = false);
      });
    }
  }

  // ── Fetch Stats ────────────────────────────────────────────────────────────
  Future<void> _fetchStats() async {
    setState(() {
      _statsLoading = true;
      _statsError   = false;
      _debugError   = '';
    });

    try {
      String token;
      try {
        token = await _TokenManager.getToken();
      } catch (e) {
        if (mounted) {
          setState(() {
            _statsLoading = false;
            _statsError   = true;
            _debugError   = 'LOGIN FAILED:\n$e';
          });
        }
        return;
      }

      final headers = ApiConstants.headersWithToken(token);
      http.Response uRes, rRes;

      try {
        uRes = await http
            .get(Uri.parse('${ApiConstants.baseUrl}/users'), headers: headers)
            .timeout(const Duration(seconds: 15));
        rRes = await http
            .get(Uri.parse('${ApiConstants.baseUrl}/roles'), headers: headers)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        if (mounted) {
          setState(() {
            _statsLoading = false;
            _statsError   = true;
            _debugError   = 'REQUEST FAILED:\n$e';
          });
        }
        return;
      }

      // Retry on 401
      if (uRes.statusCode == 401 || rRes.statusCode == 401) {
        _TokenManager.invalidate();
        try {
          token = await _TokenManager.getToken();
          final h2 = ApiConstants.headersWithToken(token);
          uRes = await http
              .get(Uri.parse('${ApiConstants.baseUrl}/users'), headers: h2)
              .timeout(const Duration(seconds: 15));
          rRes = await http
              .get(Uri.parse('${ApiConstants.baseUrl}/roles'), headers: h2)
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          if (mounted) {
            setState(() {
              _statsLoading = false;
              _statsError   = true;
              _debugError   = 'RETRY FAILED:\n$e';
            });
          }
          return;
        }
      }

      _applyStats(uRes, rRes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _statsError   = true;
          _debugError   = 'ERROR:\n$e';
        });
      }
    }
  }

  void _applyStats(http.Response uRes, http.Response rRes) {
    if (uRes.statusCode == 200 && rRes.statusCode == 200) {
      try {
        final u     = jsonDecode(uRes.body);
        final r     = jsonDecode(rRes.body);
        final List users = u['users'] ?? [];
        if (mounted) {
          setState(() {
            _totalUsers   = u['totalCount'] ?? 0;
            _activeUsers  = users.where((x) => x['isActive'] == true).length;
            _totalRoles   = (r['data'] as List? ?? []).length;
            _statsLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statsLoading = false;
            _statsError   = true;
            _debugError   = 'PARSE ERROR:\n$e';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _statsError   = true;
          _debugError   =
              '/users → ${uRes.statusCode}\n/roles → ${rRes.statusCode}';
        });
      }
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  void _signOut() {
    _TokenManager.invalidate();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: AppColors.bg,
      onDrawerChanged: (isOpen) {
        if (!isOpen) _fetchStats();
      },
      drawer: _ProfileDrawer(
        scaffoldKey:        _scaffoldKey,
        onRefreshDashboard: _fetchStats,
        username:           _displayName,
        email:              _displayEmail,
        initials:           _initials,
        permissions:        widget.permissions,
        onSignOut:          _signOut,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _TopBar(
                scaffoldKey: _scaffoldKey,
                initials:    _initials,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WelcomeBanner(username: _displayName),
                      const SizedBox(height: 16),
                      _StatsRow(
                        totalUsers:  _totalUsers,
                        totalRoles:  _totalRoles,
                        activeUsers: _activeUsers,
                        isLoading:   _statsLoading,
                        hasError:    _statsError,
                        debugError:  _debugError,
                        onRetry:     _fetchStats,
                      ),
                      const SizedBox(height: 20),
                      const _ChartsSection(),
                      const SizedBox(height: 20),
                      const _RecentActivityCard(),
                      const SizedBox(height: 20),
                      const _BudgetCard(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _BottomNavBar(
                selectedIndex: _navIndex,
                items:         _navItems,
                onTap:         (i) => setState(() => _navIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── CHARTS SECTION ───────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _ChartsSection extends StatelessWidget {
  const _ChartsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: const [
          Text('Analytics Overview',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Spacer(),
          Text('FY 2026',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        const _RevenueBarChart(),
        const SizedBox(height: 14),
        const _CategoryDonutChart(),
        const SizedBox(height: 14),
        const _VendorLineChart(),
        const SizedBox(height: 14),
        const _RegionalHBarChart(),
      ],
    );
  }
}

// ─── Chart 1: Revenue Bar Chart ───────────────────────────────────────────────
class _RevenueBarChart extends StatefulWidget {
  const _RevenueBarChart();

  @override
  State<_RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<_RevenueBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int? _hoveredIndex;

  final _data   = [4.2, 5.8, 4.9, 6.7, 7.1, 8.3, 7.6, 9.2, 8.8, 10.4, 9.7, 11.2];
  final _months = ['J','F','M','A','M','J','J','A','S','O','N','D'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:  Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.accent, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue',
                    style: TextStyle(
                        color:      AppColors.textHead,
                        fontSize:   13,
                        fontWeight: FontWeight.w700)),
                Text('PKR in Millions • 2026',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color:        AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('↑ 18.4%',
                  style: TextStyle(
                      color:      AppColors.accent,
                      fontSize:   10,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 18),
          // Bars
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_data.length, (i) {
                  final pct = (_data[i] / 12.0) * _anim.value;
                  final isH = _hoveredIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTapDown:   (_) => setState(() => _hoveredIndex = i),
                      onTapUp:     (_) => setState(() => _hoveredIndex = null),
                      onTapCancel: ()  => setState(() => _hoveredIndex = null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isH)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 3),
                                decoration: BoxDecoration(
                                    color:        AppColors.primary,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text('${_data[i]}M',
                                    style: const TextStyle(
                                        color:      Colors.white,
                                        fontSize:   8,
                                        fontWeight: FontWeight.w700)),
                              ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 100 * pct,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isH
                                      ? [AppColors.accent, const Color(0xFF1A5BB5)]
                                      : [const Color(0xFF5A9BE8), AppColors.accent],
                                  begin: Alignment.topCenter,
                                  end:   Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(_months[i],
                                style: const TextStyle(
                                    color:    AppColors.textMuted,
                                    fontSize: 8.5)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartStat(label: 'Total',      value: 'PKR 94.9M',   color: AppColors.accent),
              _ChartStat(label: 'Avg/Month',  value: 'PKR 7.9M',    color: AppColors.primary),
              _ChartStat(label: 'Best Month', value: 'Dec • 11.2M', color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart 2: Category Donut Chart ───────────────────────────────────────────
class _DonutSlice {
  final String label;
  final double pct;
  final Color  color;
  const _DonutSlice(this.label, this.pct, this.color);
}

class _CategoryDonutChart extends StatefulWidget {
  const _CategoryDonutChart();

  @override
  State<_CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<_CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  final _slices = const [
    _DonutSlice('Exterior Paints', 0.32, Color(0xFF3B7DD8)),
    _DonutSlice('Interior Paints', 0.25, Color(0xFF5C35B5)),
    _DonutSlice('Wood Finish',     0.18, Color(0xFF26A69A)),
    _DonutSlice('Primers',         0.15, Color(0xFFF57F17)),
    _DonutSlice('Specialty',       0.10, Color(0xFFE53935)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color:        AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.donut_large_rounded,
                  color: AppColors.purple, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paint Category Sales',
                    style: TextStyle(
                        color:      AppColors.textHead,
                        fontSize:   13,
                        fontWeight: FontWeight.w700)),
                Text('By product category • Units Sold',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            AnimatedBuilder(
              animation: _anim,
              builder:   (_, __) => SizedBox(
                width:  120,
                height: 120,
                child: CustomPaint(
                    painter: _DonutPainter(_slices, _anim.value)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: _slices
                    .map((s) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color:        s.color,
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s.label,
                                  style: const TextStyle(
                                      color:      AppColors.textBody,
                                      fontSize:   10.5,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text('${(s.pct * 100).round()}%',
                                style: TextStyle(
                                    color:      s.color,
                                    fontSize:   10.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ))
                    .toList(),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final double progress;
  _DonutPainter(this.slices, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = min(cx, cy) - 4;
    const inner = 0.55;
    double start = -pi / 2;

    for (final s in slices) {
      final sweep = 2 * pi * s.pct * progress;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * (1 + inner) / 2),
        start,
        sweep - 0.04,
        false,
        Paint()
          ..color       = s.color
          ..style       = PaintingStyle.stroke
          ..strokeWidth = r * (1 - inner)
          ..strokeCap   = StrokeCap.butt,
      );
      start += sweep;
    }

    final tp = TextPainter(
      text: const TextSpan(children: [
        TextSpan(
            text:  '5\n',
            style: TextStyle(
                color:      AppColors.textHead,
                fontSize:   22,
                fontWeight: FontWeight.w800,
                height:     1.1)),
        TextSpan(
            text:  'Categories',
            style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
      ]),
      textAlign:     TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─── Chart 3: Vendor Line Chart ───────────────────────────────────────────────
class _VendorLineChart extends StatefulWidget {
  const _VendorLineChart();

  @override
  State<_VendorLineChart> createState() => _VendorLineChartState();
}

class _VendorLineChartState extends State<_VendorLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  final List<double> _approved = [12.0, 18, 22, 31, 28, 35, 40, 44, 38, 52, 47, 58];
final List<double> _pending  = [5.0,  8,  6,  11,  9, 14, 10, 16, 13, 18, 15, 21];
  final _months   = ['J','F','M','A','M','J','J','A','S','O','N','D'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color:        const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.show_chart_rounded,
                  color: Color(0xFF2E7D32), size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vendor Requests',
                    style: TextStyle(
                        color:      AppColors.textHead,
                        fontSize:   13,
                        fontWeight: FontWeight.w700)),
                Text('Approved vs Pending • 2026',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
            const Spacer(),
            Row(children: [
              Container(
                  width:  8,
                  height: 8,
                  decoration: BoxDecoration(
                      color:        AppColors.success,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('Approved',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 9)),
              const SizedBox(width: 10),
              Container(
                  width:  8,
                  height: 8,
                  decoration: BoxDecoration(
                      color:        AppColors.warning,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('Pending',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ]),
          ]),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder:   (_, __) => SizedBox(
              height: 130,
              child: CustomPaint(
                size:    Size.infinite,
                painter: _LinePainter(
                  series1:  _approved,
                  series2:  _pending,
                  color1:   AppColors.success,
                  color2:   AppColors.warning,
                  progress: _anim.value,
                  labels:   _months,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartStat(label: 'Total Approved', value: '385',   color: AppColors.success),
              _ChartStat(label: 'Total Pending',  value: '146',   color: AppColors.warning),
              _ChartStat(label: 'Success Rate',   value: '72.5%', color: AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> series1, series2;
  final Color        color1, color2;
  final double       progress;
  final List<String> labels;

  _LinePainter({
    required this.series1,
    required this.series2,
    required this.color1,
    required this.color2,
    required this.progress,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [...series1, ...series2].reduce(max).toDouble();
    const bottomPad = 20.0;
    final h    = size.height - bottomPad;
    final step = size.width / (series1.length - 1);

    void drawSeries(List<double> data, Color color) {
      final path = Path();
      final fill = Path();
      final paint = Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round;

      final count = (data.length * progress).ceil().clamp(1, data.length);
      for (int i = 0; i < count; i++) {
        final x = i * step;
        final y = h - (data[i] / maxVal) * h;
        if (i == 0) {
          path.moveTo(x, y);
          fill.moveTo(x, h);
          fill.lineTo(x, y);
        } else {
          final px  = (i - 1) * step;
          final py  = h - (data[i - 1] / maxVal) * h;
          final cx1 = px + step / 3;
          final cx2 = x  - step / 3;
          path.cubicTo(cx1, py, cx2, y, x, y);
          fill.cubicTo(cx1, py, cx2, y, x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5,
            Paint()..color = color..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(x, y), 3.5,
            Paint()
              ..color       = Colors.white
              ..style       = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }

      fill.lineTo((count - 1) * step, h);
      fill.close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, h))
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(path, paint);
    }

    drawSeries(series1, color1);
    drawSeries(series2, color2);

    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
            text:  labels[i],
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 8.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * step - tp.width / 2, h + 5));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.progress != progress;
}

// ─── Chart 4: Regional Horizontal Bar Chart ───────────────────────────────────
class _RegionData {
  final String label, value;
  final double pct;
  final Color  color;
  const _RegionData(this.label, this.pct, this.color, this.value);
}

class _RegionalHBarChart extends StatefulWidget {
  const _RegionalHBarChart();

  @override
  State<_RegionalHBarChart> createState() => _RegionalHBarChartState();
}

class _RegionalHBarChartState extends State<_RegionalHBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  final _regions = const [
    _RegionData('Lahore Region',     0.88, Color(0xFF3B7DD8), 'PKR 24.2M'),
    _RegionData('Karachi Region',    0.74, Color(0xFF5C35B5), 'PKR 20.4M'),
    _RegionData('Islamabad Region',  0.61, Color(0xFF26A69A), 'PKR 16.8M'),
    _RegionData('Faisalabad Region', 0.49, Color(0xFFF57F17), 'PKR 13.5M'),
    _RegionData('Multan Region',     0.37, Color(0xFFE53935), 'PKR 10.2M'),
    _RegionData('Peshawar Region',   0.28, Color(0xFF795548), 'PKR 7.7M'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color:        AppColors.warningLight,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.map_rounded,
                  color: AppColors.warning, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regional Sales',
                    style: TextStyle(
                        color:      AppColors.textHead,
                        fontSize:   13,
                        fontWeight: FontWeight.w700)),
                Text('Revenue by Region • FY 2026',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder:   (_, __) => Column(
              children: _regions
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(r.label,
                                    style: const TextStyle(
                                        color:      AppColors.textBody,
                                        fontSize:   11,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text(r.value,
                                  style: TextStyle(
                                      color:      r.color,
                                      fontSize:   11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 5),
                            Stack(children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                    color:        AppColors.divider,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                height:  8,
                                width:   (MediaQuery.of(context).size.width - 64) *
                                    r.pct *
                                    _anim.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    r.color.withOpacity(0.7),
                                    r.color
                                  ]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartStat(label: 'Total Revenue', value: 'PKR 92.8M', color: AppColors.primary),
              _ChartStat(label: 'Top Region',    value: 'Lahore',    color: AppColors.accent),
              _ChartStat(label: 'Regions',       value: '6 Active',  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _ChartStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color:      color,
                fontSize:   11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── TOP BAR ──────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String initials;
  const _TopBar({required this.scaffoldKey, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(
                color: AppColors.primaryMid.withOpacity(0.4), width: 1),
          ),
          child: const Icon(Icons.diamond, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Diamond Paint',
                style: TextStyle(
                    color:       AppColors.textHead,
                    fontSize:    14,
                    fontWeight:  FontWeight.w700,
                    letterSpacing: 0.2)),
            Text('Paint Solutions',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
        const Spacer(),
        _IconBtn(
            icon:  Icons.notifications_outlined,
            badge: true,
            onTap: () {}),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width:  34,
            height: 34,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.accent),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color:         Colors.white,
                      fontSize:      11,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final bool         badge;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.badge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(
          width:  34,
          height: 34,
          decoration: BoxDecoration(
            color:        AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Icon(icon, color: AppColors.textMuted, size: 19),
        ),
        if (badge)
          Positioned(
            right: 7,
            top:   7,
            child: Container(
              width:  7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppColors.red, shape: BoxShape.circle),
            ),
          ),
      ]),
    );
  }
}

// ─── Welcome Banner ───────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String username;
  const _WelcomeBanner({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color:      const Color(0xFF1A2B4A).withOpacity(0.28),
              blurRadius: 18,
              offset:     const Offset(0, 7)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,',
                  style: TextStyle(color: Color(0xFF8AABCE), fontSize: 11)),
              const SizedBox(height: 3),
              Text(username,
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15), width: 0.6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width:  7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('All systems operational',
                      style: TextStyle(
                          color:      Colors.white,
                          fontSize:   10,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
        ),
        Container(
          width:  58,
          height: 58,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: const Icon(Icons.diamond, color: Colors.white, size: 28),
        ),
      ]),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int          totalUsers, totalRoles, activeUsers;
  final bool         isLoading, hasError;
  final String       debugError;
  final VoidCallback onRetry;

  const _StatsRow({
    required this.totalUsers,
    required this.totalRoles,
    required this.activeUsers,
    required this.isLoading,
    required this.hasError,
    required this.debugError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _ErrorRetryBar(onRetry: onRetry, debugError: debugError);
    }
    return Row(children: [
      Expanded(
        child: _StatCard(
          icon:       Icons.people_alt_rounded,
          label:      'Total Users',
          value:      isLoading ? '—' : '$totalUsers',
          iconColor:  AppColors.accent,
          iconBg:     AppColors.accentLight,
          trend:      isLoading ? '...' : '+$activeUsers active',
          trendColor: AppColors.accent,
          isLoading:  isLoading,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon:       Icons.shield_rounded,
          label:      'Roles',
          value:      isLoading ? '—' : '$totalRoles',
          iconColor:  AppColors.warning,
          iconBg:     AppColors.warningLight,
          trend:      'Active',
          trendColor: AppColors.warning,
          isLoading:  isLoading,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon:       Icons.pending_actions_rounded,
          label:      'Requests',
          value:      '7',
          iconColor:  AppColors.red,
          iconBg:     AppColors.redLight,
          trend:      'Pending',
          trendColor: AppColors.red,
        ),
      ),
    ]);
  }
}

class _ErrorRetryBar extends StatelessWidget {
  final VoidCallback onRetry;
  final String       debugError;
  const _ErrorRetryBar({required this.onRetry, required this.debugError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.red, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Could not load stats',
                  style: TextStyle(
                      color:      AppColors.red,
                      fontSize:   12.5,
                      fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color:        AppColors.red,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Retry',
                    style: TextStyle(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          if (debugError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:  Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.red.withOpacity(0.3)),
              ),
              child: SelectableText(
                debugError,
                style: const TextStyle(
                    color:      Color(0xFF8B0000),
                    fontSize:   10,
                    fontFamily: 'monospace',
                    height:     1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label, value, trend;
  final Color    iconColor, iconBg, trendColor;
  final bool     isLoading;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
    required this.trend,
    required this.trendColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color:        iconBg,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          isLoading
              ? Container(
                  width:  36,
                  height: 22,
                  decoration: BoxDecoration(
                      color:        AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6)))
              : Text(value,
                  style: const TextStyle(
                      color:      AppColors.textHead,
                      fontSize:   22,
                      fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color:      AppColors.textMuted,
                  fontSize:   9.5,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          isLoading
              ? Container(
                  width:  50,
                  height: 10,
                  decoration: BoxDecoration(
                      color:        AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(4)))
              : Text(trend,
                  style: TextStyle(
                      color:      trendColor,
                      fontSize:   9,
                      fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Recent Activity Card ─────────────────────────────────────────────────────
class _ActivityItem {
  final IconData icon;
  final String   text, time;
  final Color    bg, ic;
  const _ActivityItem({
    required this.icon,
    required this.text,
    required this.time,
    required this.bg,
    required this.ic,
  });
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  static const _items = [
    _ActivityItem(icon: Icons.person_add_rounded,  text: 'New user "test1234" added',   time: '2m ago',  bg: AppColors.accentLight,  ic: Color(0xFF1E7BC4)),
    _ActivityItem(icon: Icons.delete_rounded,      text: 'User #125 removed',           time: '1h ago',  bg: AppColors.redLight,     ic: Color(0xFFC62828)),
    _ActivityItem(icon: Icons.edit_rounded,        text: 'User "updateduser3" modified', time: '3h ago', bg: AppColors.warningLight, ic: AppColors.warning),
    _ActivityItem(icon: Icons.shield_rounded,      text: 'Role permissions updated',     time: '1d ago',  bg: AppColors.purpleLight,  ic: AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history_rounded,
                color: AppColors.accent, size: 17),
            const SizedBox(width: 7),
            const Text('Recent Activity',
                style: TextStyle(
                    color:      AppColors.textHead,
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color:        AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Live',
                  style: TextStyle(
                      color:      AppColors.accent,
                      fontSize:   10,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._items.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color:        a.bg,
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(a.icon, color: a.ic, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a.text,
                        style: const TextStyle(
                            color:      AppColors.textBody,
                            fontSize:   12,
                            fontWeight: FontWeight.w500)),
                  ),
                  Text(a.time,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ]),
              )),
        ],
      ),
    );
  }
}

// ─── Budget Card ──────────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.warning, size: 17),
            SizedBox(width: 7),
            Text('Budget Overview',
                style: TextStyle(
                    color:      AppColors.textHead,
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
            Spacer(),
            Text('FY 2026',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
          const SizedBox(height: 14),
          const _BudgetBar(label: 'Marketing',   pct: 0.65, color: AppColors.accent),
          const SizedBox(height: 11),
          const _BudgetBar(label: 'Operations',  pct: 0.42, color: AppColors.primary),
          const SizedBox(height: 11),
          const _BudgetBar(label: 'Procurement', pct: 0.81, color: Color(0xFFE65100)),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color  color;
  const _BudgetBar({
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: const TextStyle(
                  color:      AppColors.textBody,
                  fontSize:   11.5,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${(pct * 100).round()}%',
              style: TextStyle(
                  color:      color,
                  fontSize:   11.5,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value:           pct,
            minHeight:       6,
            backgroundColor: AppColors.divider,
            valueColor:      AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNavBar extends StatelessWidget {
  final int               selectedIndex;
  final List<_NavItem>    items;
  final ValueChanged<int> onTap;
  const _BottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset:     const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap:     () => onTap(i),
              behavior:  HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sel)
                    Container(
                      width:  20,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                          color:        AppColors.accent,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  Icon(items[i].icon,
                      color: sel ? AppColors.accent : AppColors.textMuted,
                      size:  22),
                  const SizedBox(height: 3),
                  Text(items[i].label,
                      style: TextStyle(
                          color:      sel ? AppColors.accent : AppColors.textMuted,
                          fontSize:   9.5,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── PROFILE DRAWER ───────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionItem {
  final IconData icon;
  final String   label;
  final Color    bg, ic;
  final bool     isRolesMgmt, isUserMgmt;
  final String   featureKey;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.bg,
    required this.ic,
    required this.featureKey,
    this.isRolesMgmt = false,
    this.isUserMgmt  = false,
  });
}

class _ProfileDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback             onRefreshDashboard;
  final String                   username, email, initials;
  final UserPermissions          permissions;
  final VoidCallback             onSignOut;

  const _ProfileDrawer({
    required this.scaffoldKey,
    required this.onRefreshDashboard,
    required this.username,
    required this.email,
    required this.initials,
    required this.permissions,
    required this.onSignOut,
  });

  static const List<_ActionItem> _allActions = [
    _ActionItem(icon: Icons.manage_accounts_rounded,        label: 'User Management', bg: Color(0xFFEBF3FF),     ic: AppColors.accent,  featureKey: 'user',                 isUserMgmt:  true),
    _ActionItem(icon: Icons.admin_panel_settings_rounded,   label: 'Role Management', bg: AppColors.purpleLight, ic: AppColors.purple,  featureKey: 'role',                 isRolesMgmt: true),
    _ActionItem(icon: Icons.assignment_rounded,             label: 'Area Head',       bg: AppColors.accentLight, ic: Color(0xFF1E7BC4), featureKey: 'vendorAssignment'),
    _ActionItem(icon: Icons.store_rounded,                  label: 'Vendor Requests', bg: Color(0xFFFBE9E7),     ic: Color(0xFFE65100), featureKey: 'vendorRequests'),
    _ActionItem(icon: Icons.tune_rounded,                   label: 'Request Items',   bg: Color(0xFFE8F5E9),     ic: Color(0xFF2E7D32), featureKey: 'requestPriceAdjustment'),
    _ActionItem(icon: Icons.category_rounded,               label: 'Request Types',   bg: AppColors.purpleLight, ic: Color(0xFF4527A0), featureKey: 'requestTypes'),
    _ActionItem(icon: Icons.supervised_user_circle_rounded, label: 'SAP Users',       bg: AppColors.accentLight, ic: Color(0xFF00695C), featureKey: 'sapUsers'),
    _ActionItem(icon: Icons.bar_chart_rounded,              label: 'Statistics',      bg: Color(0xFFEBF3FF),     ic: AppColors.primary, featureKey: 'statistics'),
    _ActionItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget Mgmt',     bg: AppColors.redLight,    ic: Color(0xFFC62828), featureKey: 'budgetManagement'),
    _ActionItem(icon: Icons.payment_rounded,                label: 'Payments',        bg: AppColors.accentLight, ic: Color(0xFF00796B), featureKey: 'payments'),
    _ActionItem(icon: Icons.email_rounded,                  label: 'SMTP Settings',   bg: Color(0xFFECEFF1),     ic: Color(0xFF37474F), featureKey: 'smtpSettings'),
    _ActionItem(icon: Icons.batch_prediction_rounded,       label: 'Payment Batch',   bg: Color(0xFFEFEBE9),     ic: Color(0xFF4E342E), featureKey: 'paymentBatch'),
  ];

  // ✅ Sirf wahi actions jo user ki permissions mein hain
  List<_ActionItem> get _visibleActions =>
      _allActions.where((a) => permissions.has(a.featureKey)).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visibleActions;

    return Drawer(
      width:           MediaQuery.of(context).size.width * 0.82,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width:  56,
                    height: 56,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.accent),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   19,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(email.isNotEmpty ? email : 'No email on file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF8AABCE), fontSize: 11.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 0.6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF69F0AE), size: 13),
                    SizedBox(width: 5),
                    Text('Logged in',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
          ),

          // ── Scrollable Menu ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _DrawerSection('Account'),
                _DrawerTile(icon: Icons.person_rounded,        label: 'My Profile',      color: AppColors.accent),
                _DrawerTile(icon: Icons.lock_rounded,          label: 'Change Password', color: AppColors.warning),
                _DrawerTile(icon: Icons.notifications_rounded, label: 'Notifications',   color: AppColors.primary, badge: '3'),

                _DrawerSection('Quick Actions'),

                // ✅ Agar koi permission nahi to message dikhao
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border, width: 0.7),
                      ),
                      child: Row(children: const [
                        Icon(Icons.lock_outline_rounded,
                            color: AppColors.textMuted, size: 17),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No quick actions available for your account.',
                            style: TextStyle(
                                color:      AppColors.textMuted,
                                fontSize:   12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics:    const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:  3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.90,
                      ),
                      itemCount:   visible.length,
                      itemBuilder: (ctx, i) => _DrawerActionTile(
                        item: visible[i],
                        onTap: () {
                          Navigator.pop(context);
                          if (visible[i].isUserMgmt) {
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const UserManagementScreen(),
                              ),
                            ).then((_) => onRefreshDashboard());
                          } else if (visible[i].isRolesMgmt) {
                            // ✅ permissions pass karo RoleManagementScreen ko
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => RoleManagementScreen(
                                  permissions: _toRolePerms(permissions),
                                ),
                              ),
                            ).then((_) => onRefreshDashboard());
                          } else if (visible[i].featureKey == 'statistics') {
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const StatisticsScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),

                _DrawerSection('System'),
                _DrawerTile(icon: Icons.settings_rounded, label: 'Settings',       color: AppColors.textMuted),
                _DrawerTile(icon: Icons.help_rounded,     label: 'Help & Support', color: AppColors.success),
                _DrawerTile(icon: Icons.info_rounded,     label: 'About',          color: AppColors.textMuted),
              ],
            ),
          ),

          // ── Sign Out ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: GestureDetector(
              onTap: onSignOut,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppColors.redLight,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: AppColors.red.withOpacity(0.25), width: 0.8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.red, size: 17),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color:      AppColors.red,
                            fontSize:   13.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Drawer Action Tile ───────────────────────────────────────────────────────
class _DrawerActionTile extends StatefulWidget {
  final _ActionItem  item;
  final VoidCallback onTap;
  const _DrawerActionTile({super.key, required this.item, required this.onTap});

  @override
  State<_DrawerActionTile> createState() => _DrawerActionTileState();
}

class _DrawerActionTileState extends State<_DrawerActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.93).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpecial =
        widget.item.isRolesMgmt || widget.item.isUserMgmt;

    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSpecial
                  ? (widget.item.isRolesMgmt
                      ? AppColors.purple.withOpacity(0.35)
                      : AppColors.accent.withOpacity(0.35))
                  : AppColors.border,
              width: isSpecial ? 1.0 : 0.7,
            ),
            boxShadow: [
              BoxShadow(
                  color:      Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset:     const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color:        widget.item.bg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.item.icon,
                    color: widget.item.ic, size: 19),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines:  2,
                  style: const TextStyle(
                      color:      AppColors.textBody,
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      height:     1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Section & Tile ────────────────────────────────────────────────────
class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color:         AppColors.textMuted,
            fontSize:      10,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.1),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final String?  badge;
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense:          true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color:        color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 17),
      ),
      title: Text(label,
          style: const TextStyle(
              color:      AppColors.textBody,
              fontSize:   13,
              fontWeight: FontWeight.w500)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color:        AppColors.red,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(badge!,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   10,
                      fontWeight: FontWeight.w700)),
            )
          : const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 17),
      onTap: () {},
    );
  }
}