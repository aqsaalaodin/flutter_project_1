import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_1/Rolemanagement.dart';
import 'package:flutter_project_1/UserManagementScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
      home: const DashboardScreen(),
    );
  }
}

// ─── Colour Palette ───────────────────────────────────────────────────────────
class AppColors {
  static const bg         = Color(0xFFF5F7FA);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F9);
  static const primary    = Color(0xFF1A2B4A);
  static const primaryMid = Color(0xFF243B5E);
  static const accent      = Color(0xFF3B7DD8);
  static const accentLight = Color(0xFFEBF3FF);
  static const red          = Color(0xFFE53935);
  static const redLight     = Color(0xFFFFEBEE);
  static const warning      = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const success      = Color(0xFF26A69A);
  static const purple       = Color(0xFF5C35B5);
  static const purpleLight  = Color(0xFFEFEBFA);
  static const textHead  = Color(0xFF1A2B4A);
  static const textBody  = Color(0xFF3A4A5C);
  static const textMuted = Color(0xFF8A9BB5);
  static const border  = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);
}

// ─── API Constants ────────────────────────────────────────────────────────────
class ApiConstants {
  static const baseUrl = "http://125.209.66.147:5001/api";
  static const token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3OTYwMTcyNCwiZXhwIjoxNzgwMjA2NTI0fQ.UOwXbKrGBDBi2J7DAGiRd01nIMIBnU9R9qryjyCpjLY";

  static Map<String, String> get headers => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
}

// ─── Dashboard Stats Model ────────────────────────────────────────────────────
class DashboardStats {
  final int totalUsers;
  final int totalRoles;
  final int activeUsers;

  const DashboardStats({
    required this.totalUsers,
    required this.totalRoles,
    required this.activeUsers,
  });
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _navIndex = 0;

  // ── Stats State ──────────────────────────────────────────────────────────
  bool _statsLoading = true;
  bool _statsError   = false;
  int  _totalUsers   = 0;
  int  _totalRoles   = 0;
  int  _activeUsers  = 0;

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded,              label: 'Dashboard'),
    _NavItem(icon: Icons.people_alt_rounded,             label: 'Users'),
    _NavItem(icon: Icons.bar_chart_rounded,              label: 'Stats'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchStats(); // ← API call on load
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Fetch Users + Roles from API ──────────────────────────────────────────
  Future<void> _fetchStats() async {
  setState(() {
    _statsLoading = true;
    _statsError   = false;
  });

  try {
    print("=== Fetching stats ===");
    
    final usersRes = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/users"),
      headers: ApiConstants.headers,
    ).timeout(const Duration(seconds: 10));
    
    print("Users status: ${usersRes.statusCode}");
    print("Users body: ${usersRes.body.substring(0, 200)}");

    final rolesRes = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/roles"),
      headers: ApiConstants.headers,
    ).timeout(const Duration(seconds: 10));
    
    print("Roles status: ${rolesRes.statusCode}");
    print("Roles body: ${rolesRes.body.substring(0, 200)}");

    if (usersRes.statusCode == 200 && rolesRes.statusCode == 200) {
      final usersJson = jsonDecode(usersRes.body);
      final rolesJson = jsonDecode(rolesRes.body);

      final int totalUsers  = usersJson['totalCount'] ?? 0;
      final List usersList  = usersJson['users'] ?? [];
      final int activeUsers = usersList.where((u) => u['isActive'] == true).length;
      final List rolesList  = rolesJson['data'] ?? [];
      final int totalRoles  = rolesList.length;

      if (mounted) {
        setState(() {
          _totalUsers   = totalUsers;
          _totalRoles   = totalRoles;
          _activeUsers  = activeUsers;
          _statsLoading = false;
        });
      }
    } else {
      if (mounted) setState(() { _statsLoading = false; _statsError = true; });
    }
  } catch (e) {
    print("=== ERROR: $e ===");
    if (mounted) setState(() { _statsLoading = false; _statsError = true; });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: const _ProfileDrawer(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _TopBar(scaffoldKey: _scaffoldKey),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _WelcomeBanner(),
                      const SizedBox(height: 16),

                      // ── Stats Row — API driven ──────────────────────────
                      _StatsRow(
                        totalUsers:  _totalUsers,
                        totalRoles:  _totalRoles,
                        activeUsers: _activeUsers,
                        isLoading:   _statsLoading,
                        hasError:    _statsError,
                        onRetry:     _fetchStats,
                      ),

                      const SizedBox(height: 20),
                      const _QuickActionsGrid(),
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
                items: _navItems,
                onTap: (i) => setState(() => _navIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _TopBar({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(
                  color: AppColors.primaryMid.withOpacity(0.4), width: 1),
            ),
            child: const Icon(Icons.diamond, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Diamond Paint',
                style: TextStyle(
                    color: AppColors.textHead,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            Text('Paint Solutions',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
          const Spacer(),
          _IconBtn(icon: Icons.notifications_outlined, badge: true, onTap: () {}),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.accent),
              child: const Center(
                child: Text('SA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.badge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Icon(icon, color: AppColors.textMuted, size: 19),
        ),
        if (badge)
          Positioned(
            right: 7, top: 7,
            child: Container(
              width: 7, height: 7,
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
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A2B4A).withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 7)),
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
                const Text('Super Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 0.6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('All systems operational',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
        ),
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: const Icon(Icons.diamond, color: Colors.white, size: 28),
        ),
      ]),
    );
  }
}

// ─── Stats Row — API Driven ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int  totalUsers;
  final int  totalRoles;
  final int  activeUsers;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const _StatsRow({
    required this.totalUsers,
    required this.totalRoles,
    required this.activeUsers,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _ErrorRetryBar(onRetry: onRetry);
    }

    return Row(children: [
      Expanded(
          child: _StatCard(
              icon: Icons.people_alt_rounded,
              label: 'Total Users',
              value: isLoading ? '—' : '$totalUsers',
              iconColor: AppColors.accent,
              iconBg: AppColors.accentLight,
              trend: isLoading ? '...' : '+$activeUsers active',
              trendColor: AppColors.accent,
              isLoading: isLoading)),
      const SizedBox(width: 10),
      Expanded(
          child: _StatCard(
              icon: Icons.shield_rounded,
              label: 'Roles',
              value: isLoading ? '—' : '$totalRoles',
              iconColor: AppColors.warning,
              iconBg: AppColors.warningLight,
              trend: 'Active',
              trendColor: AppColors.warning,
              isLoading: isLoading)),
      const SizedBox(width: 10),
      Expanded(
          child: _StatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Requests',
              value: '7',          // hardcoded — no requests API yet
              iconColor: AppColors.red,
              iconBg: AppColors.redLight,
              trend: 'Pending',
              trendColor: AppColors.red,
              isLoading: false)),
    ]);
  }
}

// ─── Error Retry Bar ──────────────────────────────────────────────────────────
class _ErrorRetryBar extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetryBar({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.25), width: 0.8),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 18),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Could not load stats',
              style: TextStyle(
                  color: AppColors.red,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Retry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, trend;
  final Color iconColor, iconBg, trendColor;
  final bool isLoading;

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 17)),
        const SizedBox(height: 10),
        isLoading
            ? Container(
                width: 36,
                height: 22,
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6)),
              )
            : Text(value,
                style: const TextStyle(
                    color: AppColors.textHead,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        isLoading
            ? Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(4)),
              )
            : Text(trend,
                style: TextStyle(
                    color: trendColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<_ActionItem> _items = [
    _ActionItem(
        icon: Icons.manage_accounts_rounded,
        label: 'User\nMgmt',
        bg: Color(0xFFEBF3FF),
        ic: AppColors.accent,
        isUserMgmt: true),
    _ActionItem(
        icon: Icons.admin_panel_settings_rounded,
        label: 'Roles',
        bg: AppColors.purpleLight,
        ic: AppColors.purple,
        isRoles: true),
    _ActionItem(
        icon: Icons.assignment_rounded,
        label: 'Area\nHead',
        bg: AppColors.accentLight,
        ic: Color(0xFF1E7BC4)),
    _ActionItem(
        icon: Icons.store_rounded,
        label: 'Vendor\nReq',
        bg: Color(0xFFFBE9E7),
        ic: Color(0xFFE65100)),
    _ActionItem(
        icon: Icons.tune_rounded,
        label: 'Req.\nItems',
        bg: Color(0xFFE8F5E9),
        ic: Color(0xFF2E7D32)),
    _ActionItem(
        icon: Icons.category_rounded,
        label: 'Req.\nTypes',
        bg: AppColors.purpleLight,
        ic: Color(0xFF4527A0)),
    _ActionItem(
        icon: Icons.supervised_user_circle_rounded,
        label: 'SAP\nUsers',
        bg: AppColors.accentLight,
        ic: Color(0xFF00695C)),
    _ActionItem(
        icon: Icons.bar_chart_rounded,
        label: 'Statistics',
        bg: Color(0xFFEBF3FF),
        ic: AppColors.primary),
    _ActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Budget',
        bg: AppColors.redLight,
        ic: Color(0xFFC62828)),
    _ActionItem(
        icon: Icons.payment_rounded,
        label: 'Payments',
        bg: AppColors.accentLight,
        ic: Color(0xFF00796B)),
    _ActionItem(
        icon: Icons.email_rounded,
        label: 'SMTP',
        bg: Color(0xFFECEFF1),
        ic: Color(0xFF37474F)),
    _ActionItem(
        icon: Icons.batch_prediction_rounded,
        label: 'Pay\nBatch',
        bg: Color(0xFFEFEBE9),
        ic: Color(0xFF4E342E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Text('Quick Actions',
            style: TextStyle(
                color: AppColors.textHead,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        Spacer(),
        Text('See all',
            style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82),
        itemCount: _items.length,
        itemBuilder: (_, i) => _ActionTile(item: _items[i]),
      ),
    ]);
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color bg, ic;
  final bool isRoles;
  final bool isUserMgmt;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.bg,
    required this.ic,
    this.isRoles   = false,
    this.isUserMgmt = false,
  });
}

class _ActionTile extends StatefulWidget {
  final _ActionItem item;
  const _ActionTile({super.key, required this.item});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _s = Tween(begin: 1.0, end: 0.93).animate(_c);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _handleUserMgmtTap(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const UserManagementScreen()));
  }

  void _handleRolesTap(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RoleManagementScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpecial = widget.item.isRoles || widget.item.isUserMgmt;
    final Color borderColor = widget.item.isRoles
        ? AppColors.purple.withOpacity(0.35)
        : widget.item.isUserMgmt
            ? AppColors.accent.withOpacity(0.35)
            : AppColors.border;

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        if (widget.item.isUserMgmt) _handleUserMgmtTap(context);
        if (widget.item.isRoles)    _handleRolesTap(context);
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: borderColor, width: isSpecial ? 1.0 : 0.7),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: widget.item.bg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.item.icon, color: widget.item.ic, size: 20),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Activity ──────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  static const _items = [
    _Act(icon: Icons.person_add_rounded,  text: 'New user "test1234" added',       time: '2m ago',  bg: AppColors.accentLight,  ic: Color(0xFF1E7BC4)),
    _Act(icon: Icons.delete_rounded,      text: 'User #125 removed',               time: '1h ago',  bg: AppColors.redLight,     ic: Color(0xFFC62828)),
    _Act(icon: Icons.edit_rounded,        text: 'User "updateduser3" modified',     time: '3h ago',  bg: AppColors.warningLight, ic: AppColors.warning),
    _Act(icon: Icons.shield_rounded,      text: 'Role permissions updated',         time: '1d ago',  bg: AppColors.purpleLight,  ic: AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_rounded, color: AppColors.accent, size: 17),
          const SizedBox(width: 7),
          const Text('Recent Activity',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Live',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
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
                        color: a.bg, borderRadius: BorderRadius.circular(9)),
                    child: Icon(a.icon, color: a.ic, size: 15)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(a.text,
                        style: const TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                            fontWeight: FontWeight.w500))),
                Text(a.time,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ]),
            )),
      ]),
    );
  }
}

class _Act {
  final IconData icon;
  final String text, time;
  final Color bg, ic;
  const _Act({required this.icon, required this.text, required this.time, required this.bg, required this.ic});
}

// ─── Budget Card ──────────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.account_balance_wallet_rounded, color: AppColors.warning, size: 17),
          SizedBox(width: 7),
          Text('Budget Overview',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Spacer(),
          Text('FY 2026',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 14),
        const _Bar(label: 'Marketing',   pct: 0.65, color: AppColors.accent),
        const SizedBox(height: 11),
        const _Bar(label: 'Operations',  pct: 0.42, color: AppColors.primary),
        const SizedBox(height: 11),
        const _Bar(label: 'Procurement', pct: 0.81, color: Color(0xFFE65100)),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _Bar({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 11.5,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('${(pct * 100).round()}%',
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.selectedIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sel)
                    Container(
                        width: 20, height: 3,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2))),
                  Icon(items[i].icon,
                      color: sel ? AppColors.accent : AppColors.textMuted,
                      size: 22),
                  const SizedBox(height: 3),
                  Text(items[i].label,
                      style: TextStyle(
                          color: sel ? AppColors.accent : AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Profile Drawer ───────────────────────────────────────────────────────────
class _ProfileDrawer extends StatelessWidget {
  const _ProfileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.accent),
                  child: const Center(
                    child: Text('SA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Super Admin',
                  style: TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('superadmin@diamondpaint.com',
                  style: TextStyle(color: Color(0xFF8AABCE), fontSize: 11.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 0.6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.verified_rounded, color: Color(0xFF69F0AE), size: 13),
                  SizedBox(width: 5),
                  Text('Super Administrator',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                _DSection('Account'),
                _DTile(icon: Icons.person_rounded,        label: 'My Profile',       color: AppColors.accent),
                _DTile(icon: Icons.lock_rounded,          label: 'Change Password',  color: AppColors.warning),
                _DTile(icon: Icons.notifications_rounded, label: 'Notifications',    color: AppColors.primary, badge: '3'),
                _DSection('System'),
                _DTile(icon: Icons.settings_rounded,      label: 'Settings',         color: AppColors.textMuted),
                _DTile(icon: Icons.help_rounded,          label: 'Help & Support',   color: AppColors.success),
                _DTile(icon: Icons.info_rounded,          label: 'About',            color: AppColors.textMuted),
              ])),
          Padding(
            padding: const EdgeInsets.all(18),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: AppColors.red.withOpacity(0.25), width: 0.8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.red, size: 17),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.red,
                            fontSize: 13.5,
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

class _DSection extends StatelessWidget {
  final String t;
  const _DSection(this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 5),
      child: Text(t.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1)),
    );
  }
}

class _DTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  const _DTile({required this.icon, required this.label, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 17),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textBody, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))
          : const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 17),
      onTap: () {},
    );
  }
}