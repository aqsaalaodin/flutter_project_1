import 'package:flutter/material.dart';
import 'package:flutter_project_1/CreateUserScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Reuses AppColors from main.dart ─────────────────────────────────────────
// Import or copy AppColors here if needed; using the same tokens for consistency.
class _C {
  // Backgrounds
  static const bg         = Color(0xFFF5F7FA);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F9);

  // Brand — Deep Navy (matches dashboard primary)
  static const primary    = Color(0xFF1A2B4A);
  static const primaryMid = Color(0xFF243B5E);

  // Accent — iOS Blue (matches dashboard accent)
  static const accent      = Color(0xFF3B7DD8);
  static const accentLight = Color(0xFFEBF3FF);

  // Semantic
  static const red          = Color(0xFFE53935);
  static const redLight     = Color(0xFFFFEBEE);
  static const warning      = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const success      = Color(0xFF26A69A);
  static const successLight = Color(0xFFE0F2F1);
  static const purple       = Color(0xFF5C35B5);
  static const purpleLight  = Color(0xFFEFEBFA);

  // Text
  static const textHead  = Color(0xFF1A2B4A);
  static const textBody  = Color(0xFF3A4A5C);
  static const textMuted = Color(0xFF8A9BB5);

  // Chrome
  static const border  = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);

  // Input
  static const inputFill = Color(0xFFF0F4F9);
}

// ─── Token Manager ────────────────────────────────────────────────────────────
class _TokenManager {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  static const _loginUrl      = "http://125.209.66.147:5001/api/auth/login";
  static const _loginUsername = "superadmin";
  static const _loginPassword = "superadmin";

  static const _fallbackToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc4MTI3Mzg4OCwiZXhwIjoxNzgxODc4Njg4fQ.86O2eBhYdAjmXrQhyrkgH80LPXQju9sRxMEepreDdlA";

  static Future<String> getToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
            _tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedToken!;
    }
    final fresh = await _loginAndGetToken();
    if (fresh != null) return fresh;
    _cachedToken = _fallbackToken;
    _tokenExpiry = _parseExpiry(_fallbackToken) ??
        DateTime.now().add(const Duration(hours: 1));
    return _fallbackToken;
  }

  static Future<String?> _loginAndGetToken() async {
    try {
      final response = await http
          .post(
            Uri.parse(_loginUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": _loginUsername,
              "password": _loginPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final t = data['token'] ??
            data['access_token'] ??
            data['accessToken'] ??
            data['data']?['token'] ??
            data['data']?['access_token'];
        if (t != null) {
          _cachedToken = t.toString();
          _tokenExpiry = _parseExpiry(_cachedToken!) ??
              DateTime.now().add(const Duration(hours: 7));
          return _cachedToken;
        }
      }
    } catch (_) {}
    return null;
  }

  static DateTime? _parseExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) payload += '=';
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final exp = decoded['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      }
    } catch (_) {}
    return null;
  }

  static void invalidate() {
    _cachedToken = null;
    _tokenExpiry = null;
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final int? roleId;
  final String createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.roleId,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int? parsedRoleId;
    String parsedRole = '-';
    if (json['role'] is Map) {
      parsedRole   = json['role']['name'] ?? json['role']['roleName'] ?? '-';
      parsedRoleId = json['role']['id'] ?? json['role']['roleId'];
    } else {
      parsedRole   = json['role'] ?? json['roleName'] ?? '-';
      parsedRoleId = json['roleId'] ?? json['role_id'];
    }
    return UserModel(
      id:        json['id'] ?? 0,
      username:  json['username'] ?? '-',
      email:     json['email'] ?? '-',
      role:      parsedRole,
      roleId:    parsedRoleId,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '-',
      isActive:  json['is_active'] ?? json['isActive'] ?? true,
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  List<UserModel> allUsers = [];
  List<UserModel> users    = [];
  bool isLoading           = true;
  String? errorMessage;

  int _currentPage             = 1;
  int _pageSize                = 10;
  int _totalPages              = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    fetchUsers();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading    = true;
      errorMessage = null;
    });

    final token = await _TokenManager.getToken();
    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final urlsToTry = [
      "http://125.209.66.147:5001/api/users?page=1&size=100",
      "http://125.209.66.147:5001/api/users?page=0&size=100",
      "http://125.209.66.147:5001/api/users",
    ];

    for (final urlStr in urlsToTry) {
      try {
        final response = await http
            .get(Uri.parse(urlStr), headers: headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 401) {
          _TokenManager.invalidate();
          final newToken = await _TokenManager.getToken();
          if (newToken == null) break;
          final retry = await http
              .get(Uri.parse(urlStr), headers: {
                "Authorization": "Bearer $newToken",
                "Content-Type": "application/json",
              })
              .timeout(const Duration(seconds: 15));
          if (retry.statusCode == 200) {
            final ok = _parseAndApply(retry.body);
            if (ok) return;
          }
          continue;
        }

        if (response.statusCode == 204 ||
            response.statusCode == 304 ||
            response.body.trim().isEmpty) continue;

        if (response.statusCode == 200) {
          final ok = _parseAndApply(response.body);
          if (ok) return;
        }
      } catch (_) {
        continue;
      }
    }

    setState(() {
      isLoading    = false;
      errorMessage = "Could not load users. Tap refresh to try again.";
    });
  }

  bool _parseAndApply(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map) {
        rawList = decoded['data']    ??
                  decoded['users']   ??
                  decoded['content'] ??
                  decoded['items']   ?? [];
      }
      if (rawList.isEmpty) return false;
      final parsed = rawList
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        allUsers     = parsed;
        _currentPage = 1;
        final total  = allUsers.length;
        _totalPages  = (total / _pageSize).ceil().clamp(1, 9999);
        users        = allUsers.sublist(0, _pageSize.clamp(0, total));
        isLoading    = false;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _applyPagination() {
    setState(() {
      final total = allUsers.length;
      _totalPages = (total / _pageSize).ceil().clamp(1, 9999);
      if (_currentPage > _totalPages) _currentPage = _totalPages;
      final start = (_currentPage - 1) * _pageSize;
      final end   = (start + _pageSize).clamp(0, total);
      users = allUsers.sublist(start, end);
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _applyPagination();
  }

  void _openViewDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _ViewUserDialog(user: user),
    );
  }

  void _openEditDialog(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _EditUserDialog(user: user),
    );
    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      fetchUsers();
    }
  }

  void _openDeleteDialog(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _DeleteUserDialog(user: user),
    );
    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      fetchUsers();
    }
  }

  // ── Stat counts ─────────────────────────────────────────────────────────────
  int get _activeCount   => allUsers.where((u) => u.isActive).length;
  int get _inactiveCount => allUsers.where((u) => !u.isActive).length;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 17, color: _C.textHead),
        ),
        title: Row(
          children: [
            // Diamond logo badge — matches dashboard TopBar
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                color: _C.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User management",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.textHead,
                        letterSpacing: 0.1)),
                Text("Diamond Paint",
                    style: TextStyle(
                        fontSize: 10,
                        color: _C.textMuted,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _C.border),
        ),
        actions: [
          // Refresh button
          _AppBarIconBtn(
            icon: Icons.refresh_rounded,
            onTap: fetchUsers,
          ),
          const SizedBox(width: 8),
          // Create button — opens CreateUserScreen as a dialog
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _CreateButton(
              onTap: () async {
                // ── CHANGED: showDialog instead of Navigator.push ──────────
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withOpacity(0.35),
                  builder: (_) => const CreateUserScreen(),
                );
                // ─────────────────────────────────────────────────────────────
                fetchUsers();
              },
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page heading
                const Text("User management",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _C.textHead)),
                const SizedBox(height: 2),
                const Text("Manage your team members and their access",
                    style: TextStyle(
                        fontSize: 12, color: _C.textMuted)),

                const SizedBox(height: 14),

                // Stats row — matches dashboard _StatsRow
                if (!isLoading)
                  Row(children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        label: "Total users",
                        value: "${allUsers.length}",
                        iconColor: _C.accent,
                        iconBg: _C.accentLight,
                        trend: "+4 this week",
                        trendColor: _C.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: "Active",
                        value: "$_activeCount",
                        iconColor: _C.success,
                        iconBg: _C.successLight,
                        trend: "Online",
                        trendColor: _C.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.block_rounded,
                        label: "Inactive",
                        value: "$_inactiveCount",
                        iconColor: _C.red,
                        iconBg: _C.redLight,
                        trend: "Blocked",
                        trendColor: _C.red,
                      ),
                    ),
                  ]),

                const SizedBox(height: 18),

                // Error banner
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.redLight,
                      border: Border.all(
                          color: _C.red.withOpacity(0.25), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: _C.red, size: 17),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFB71C1C),
                                  fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),

                // Section label row
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 15, color: _C.accent),
                    const SizedBox(width: 6),
                    const Text("All users",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.textHead)),
                    const SizedBox(width: 8),
                    if (!isLoading && allUsers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${allUsers.length}",
                            style: const TextStyle(
                                color: _C.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Table / card list
                isMobile ? _buildMobileList() : _buildDesktopTable(),

                // Pagination
                if (!isLoading && allUsers.isNotEmpty)
                  _PaginationFooter(
                    currentPage:       _currentPage,
                    totalPages:        _totalPages,
                    totalItems:        allUsers.length,
                    pageSize:          _pageSize,
                    pageSizeOptions:   _pageSizeOptions,
                    onPageChanged:     _goToPage,
                    onPageSizeChanged: (size) {
                      setState(() {
                        _pageSize    = size;
                        _currentPage = 1;
                      });
                      _applyPagination();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile card list ───────────────────────────────────────────────────────
  Widget _buildMobileList() {
    if (isLoading) return _loadingWidget();
    if (users.isEmpty) return _emptyWidget();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MobileUserCard(
        user: users[i],
        onView:   () => _openViewDialog(users[i]),
        onEdit:   () => _openEditDialog(users[i]),
        onDelete: () => _openDeleteDialog(users[i]),
      ),
    );
  }

  // ── Desktop table ──────────────────────────────────────────────────────────
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 11, horizontal: 14),
              color: _C.surfaceAlt,
              child: Row(
                children: const [
                  Expanded(flex: 1, child: _HeaderCell("ID")),
                  Expanded(flex: 2, child: _HeaderCell("Username")),
                  Expanded(flex: 3, child: _HeaderCell("Email")),
                  Expanded(flex: 2, child: _HeaderCell("Role")),
                  Expanded(flex: 2, child: _HeaderCell("Status")),
                  Expanded(flex: 2, child: _HeaderCell("Created")),
                  Expanded(flex: 2, child: _HeaderCell("Actions")),
                ],
              ),
            ),
            Container(height: 0.5, color: _C.border),

            if (isLoading)
              _loadingWidget()
            else if (users.isEmpty)
              _emptyWidget()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (_, i) => Column(
                  children: [
                    _buildRow(users[i]),
                    if (i != users.length - 1)
                      Container(height: 0.5, color: _C.divider),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(UserModel user) {
    return _HoverableRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text("#${user.id}",
                  style: const TextStyle(
                      fontSize: 12,
                      color: _C.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _Avatar(username: user.username),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(user.username,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: _C.textHead,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(user.email,
                  style: const TextStyle(
                      fontSize: 12, color: _C.textMuted),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(flex: 2, child: _RoleChip(role: user.role)),
            Expanded(
              flex: 2,
              child: _StatusChip(isActive: user.isActive),
            ),
            Expanded(
              flex: 2,
              child: Text(user.createdAt,
                  style: const TextStyle(
                      fontSize: 11, color: _C.textMuted)),
            ),
            Expanded(
              flex: 2,
              child: _ActionButtons(
                onView:   () => _openViewDialog(user),
                onEdit:   () => _openEditDialog(user),
                onDelete: () => _openDeleteDialog(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingWidget() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
                color: _C.accent, strokeWidth: 2),
          ),
        ),
      );

  Widget _emptyWidget() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text("No users found",
              style: TextStyle(color: _C.textMuted, fontSize: 13)),
        ),
      );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
// Matches dashboard _StatCard exactly
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, trend;
  final Color iconColor, iconBg, trendColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 7,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 9),
        Text(value,
            style: const TextStyle(
                color: _C.textHead,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(label,
            style: const TextStyle(
                color: _C.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(trend,
            style: TextStyle(
                color: trendColor, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String username;
  const _Avatar({required this.username});

  // Cycle through accent colors per first letter — matches dashboard style
  Color _bgColor() {
    final colors = [
      _C.accentLight, _C.purpleLight, _C.successLight,
      _C.warningLight, const Color(0xFFFBE9E7),
    ];
    if (username.isEmpty) return _C.accentLight;
    return colors[username.codeUnitAt(0) % colors.length];
  }

  Color _textColor() {
    final colors = [
      _C.accent, _C.purple, _C.success, _C.warning, const Color(0xFFE65100),
    ];
    if (username.isEmpty) return _C.accent;
    return colors[username.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _bgColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : "U",
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textColor()),
        ),
      ),
    );
  }
}

// ─── Mobile User Card ─────────────────────────────────────────────────────────
class _MobileUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MobileUserCard(
      {required this.user, required this.onView, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Avatar(username: user.username),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _C.textHead)),
                  Text("ID #${user.id}",
                      style: const TextStyle(
                          fontSize: 10.5, color: _C.textMuted)),
                ],
              ),
            ),
            _StatusChip(isActive: user.isActive),
          ]),
          const SizedBox(height: 11),
          Container(height: 0.5, color: _C.divider),
          const SizedBox(height: 11),
          _CardRow(icon: Icons.email_outlined, label: "Email", value: user.email),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.shield_outlined, size: 13, color: _C.textMuted),
            const SizedBox(width: 6),
            const Text("Role ",
                style: TextStyle(
                    fontSize: 11, color: _C.textMuted, fontWeight: FontWeight.w500)),
            _RoleChip(role: user.role),
          ]),
          const SizedBox(height: 7),
          _CardRow(
              icon: Icons.calendar_today_outlined,
              label: "Created",
              value: user.createdAt),
          const SizedBox(height: 11),
          Container(height: 0.5, color: _C.divider),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MobileActBtn(
                  icon: Icons.visibility_outlined,
                  label: "View",
                  color: _C.success,
                  bg: _C.successLight,
                  onTap: onView),
              const SizedBox(width: 7),
              _MobileActBtn(
                  icon: Icons.edit_outlined,
                  label: "Edit",
                  color: _C.accent,
                  bg: _C.accentLight,
                  onTap: onEdit),
              const SizedBox(width: 7),
              _MobileActBtn(
                  icon: Icons.delete_outline_rounded,
                  label: "Delete",
                  color: _C.red,
                  bg: _C.redLight,
                  onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _CardRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: _C.textMuted),
        const SizedBox(width: 5),
        Text("$label: ",
            style: const TextStyle(
                fontSize: 11,
                color: _C.textMuted,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11.5, color: _C.textBody, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _MobileActBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;
  const _MobileActBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.20), width: 0.7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Header Cell ──────────────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _C.textMuted,
            letterSpacing: 0.6),
      );
}

// ─── Hoverable Row ────────────────────────────────────────────────────────────
class _HoverableRow extends StatefulWidget {
  final Widget child;
  const _HoverableRow({required this.child});

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? _C.surfaceAlt : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

// ─── AppBar Icon Button ───────────────────────────────────────────────────────
class _AppBarIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});

  @override
  State<_AppBarIconBtn> createState() => _AppBarIconBtnState();
}

class _AppBarIconBtnState extends State<_AppBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _hovered ? _C.surfaceAlt : _C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 0.7),
          ),
          child: Icon(widget.icon,
              size: 17, color: _hovered ? _C.accent : _C.textMuted),
        ),
      ),
    );
  }
}

// ─── Create Button ────────────────────────────────────────────────────────────
// Accent blue — matches dashboard action buttons
class _CreateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF2D6BBF) : _C.accent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: _C.accent.withOpacity(_pressed ? 0.12 : 0.25),
              blurRadius: _pressed ? 4 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, size: 15, color: Colors.white),
            SizedBox(width: 5),
            Text("Create user",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ─── Role Chip ────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  // Color scheme keyed to role name
  Color _bg() {
    final r = role.toLowerCase();
    if (r.contains('super')) return _C.purpleLight;
    if (r.contains('admin')) return _C.accentLight;
    if (r.contains('manag')) return _C.successLight;
    return _C.surfaceAlt;
  }

  Color _fg() {
    final r = role.toLowerCase();
    if (r.contains('super')) return _C.purple;
    if (r.contains('admin')) return _C.accent;
    if (r.contains('manag')) return _C.success;
    return _C.textBody;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fg().withOpacity(0.2), width: 0.7),
      ),
      child: Text(role,
          style: TextStyle(
              color: _fg(), fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? _C.successLight : _C.redLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _C.success.withOpacity(0.2)
              : _C.red.withOpacity(0.2),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: isActive ? _C.success : _C.red,
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? "Active" : "Inactive",
            style: TextStyle(
                color: isActive
                    ? const Color(0xFF085041)
                    : const Color(0xFFB71C1C),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ActionButtons({this.onView, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActIcon(icon: Icons.visibility_outlined,    hoverColor: _C.success, bg: _C.successLight, onTap: onView),
        _ActIcon(icon: Icons.edit_outlined,          hoverColor: _C.accent,  bg: _C.accentLight,  onTap: onEdit),
        _ActIcon(icon: Icons.delete_outline_rounded, hoverColor: _C.red,     bg: _C.redLight,     onTap: onDelete),
      ],
    );
  }
}

class _ActIcon extends StatefulWidget {
  final IconData icon;
  final Color hoverColor, bg;
  final VoidCallback? onTap;
  const _ActIcon(
      {required this.icon, required this.hoverColor, required this.bg, this.onTap});

  @override
  State<_ActIcon> createState() => _ActIconState();
}

class _ActIconState extends State<_ActIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28, height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered ? widget.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(widget.icon,
              size: 15,
              color: _hovered ? widget.hoverColor : _C.textMuted),
        ),
      ),
    );
  }
}

// ─── Pagination Footer ────────────────────────────────────────────────────────
class _PaginationFooter extends StatelessWidget {
  final int currentPage, totalPages, totalItems, pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageChanged, onPageSizeChanged;

  const _PaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  List<int?> _pageNumbers() {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
    final pages = <int?>[1];
    if (currentPage > 4) pages.add(null);
    final start = (currentPage - 2).clamp(2, totalPages - 1);
    final end   = (currentPage + 2).clamp(2, totalPages - 1);
    for (int i = start; i <= end; i++) pages.add(i);
    if (currentPage < totalPages - 3) pages.add(null);
    if (totalPages > 1) pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final startItem = (currentPage - 1) * pageSize + 1;
    final endItem   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: _C.textMuted),
                children: [
                  const TextSpan(text: "Showing "),
                  TextSpan(
                      text: "$startItem–$endItem",
                      style: const TextStyle(
                          color: _C.textHead,
                          fontWeight: FontWeight.w700)),
                  const TextSpan(text: " of "),
                  TextSpan(
                      text: "$totalItems",
                      style: const TextStyle(
                          color: _C.textHead,
                          fontWeight: FontWeight.w700)),
                  const TextSpan(text: " users"),
                ],
              ),
            ),
            Row(children: [
              const Text("Rows:",
                  style: TextStyle(
                      fontSize: 11.5, color: _C.textMuted)),
              const SizedBox(width: 7),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _C.surfaceAlt,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _C.border, width: 0.7),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 15, color: _C.textMuted),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _C.textHead,
                        fontWeight: FontWeight.w600),
                    borderRadius: BorderRadius.circular(9),
                    items: pageSizeOptions
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text("$s")))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onPageSizeChanged(v);
                    },
                  ),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 0.5, color: _C.border),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PgBtn(
                  label: "←",
                  isDisabled: currentPage == 1,
                  isActive: false,
                  onTap: () => onPageChanged(currentPage - 1)),
              const SizedBox(width: 3),
              ..._pageNumbers().map((p) {
                if (p == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text("…",
                        style: TextStyle(
                            fontSize: 12,
                            color: _C.textMuted,
                            fontWeight: FontWeight.w600)),
                  );
                }
                return _PgBtn(
                    label: "$p",
                    isActive: p == currentPage,
                    isDisabled: false,
                    onTap: () => onPageChanged(p));
              }),
              const SizedBox(width: 3),
              _PgBtn(
                  label: "→",
                  isDisabled: currentPage == totalPages,
                  isActive: false,
                  onTap: () => onPageChanged(currentPage + 1)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PgBtn extends StatefulWidget {
  final String label;
  final bool isActive, isDisabled;
  final VoidCallback onTap;
  const _PgBtn(
      {required this.label,
      required this.isActive,
      required this.isDisabled,
      required this.onTap});

  @override
  State<_PgBtn> createState() => _PgBtnState();
}

class _PgBtnState extends State<_PgBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor     = Colors.transparent;
    Color textColor   = _C.textMuted;
    Color borderColor = _C.border;

    if (widget.isActive) {
      bgColor = _C.primary; textColor = Colors.white; borderColor = _C.primary;
    } else if (_hovered && !widget.isDisabled) {
      bgColor = _C.accentLight; textColor = _C.accent; borderColor = _C.accent.withOpacity(0.3);
    } else if (widget.isDisabled) {
      textColor = _C.border;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30, height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor, width: 0.7),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}

// ─── View User Dialog ─────────────────────────────────────────────────────────
class _ViewUserDialog extends StatelessWidget {
  final UserModel user;
  const _ViewUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 520,
        ),
        child: _ViewDialogContent(user: user),
      ),
    );
  }
}

class _ViewDialogContent extends StatefulWidget {
  final UserModel user;
  const _ViewDialogContent({required this.user});

  @override
  State<_ViewDialogContent> createState() => _ViewDialogContentState();
}

class _ViewDialogContentState extends State<_ViewDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() => _ctrl.reverse().then((_) => Navigator.pop(context));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _C.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.visibility_outlined,
                        size: 17, color: _C.accent),
                  ),
                  const SizedBox(width: 10),
                  const Text("View user",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _C.textHead)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.border, width: 0.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _C.textMuted),
                    ),
                  ),
                ]),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _Avatar(username: widget.user.username),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user.username,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textHead)),
                            Text("ID #${widget.user.id}",
                                style: const TextStyle(
                                    fontSize: 11.5, color: _C.textMuted)),
                          ],
                        ),
                        const Spacer(),
                        _StatusChip(isActive: widget.user.isActive),
                      ]),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: _C.divider),
                      const SizedBox(height: 16),
                      _DialogField(label: "Username",   value: widget.user.username,  icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _DialogField(label: "Email",      value: widget.user.email,     icon: Icons.email_outlined),
                      const SizedBox(height: 12),
                      _DialogField(label: "Role",       value: widget.user.role,      icon: Icons.shield_outlined, isRole: true),
                      const SizedBox(height: 12),
                      _DialogField(label: "Regions",    value: "No regions selected", icon: Icons.location_on_outlined, isEmpty: true),
                      const SizedBox(height: 12),
                      _DialogField(label: "Created at", value: widget.user.createdAt, icon: Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  border: Border(
                      top: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: _C.border, width: 0.7),
                        ),
                        child: const Text("Close",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.accent)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Field ─────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isRole, isEmpty;

  const _DialogField({
    required this.label,
    required this.value,
    required this.icon,
    this.isRole  = false,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _C.textMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _C.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 0.7),
          ),
          child: Row(children: [
            Icon(icon, size: 15, color: isEmpty ? _C.border : _C.textMuted),
            const SizedBox(width: 9),
            if (isRole)
              _RoleChip(role: value)
            else
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        color: isEmpty ? _C.textMuted : _C.textBody,
                        fontStyle: isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
          ]),
        ),
      ],
    );
  }
}

// ─── Edit User Dialog ─────────────────────────────────────────────────────────
class _EditUserDialog extends StatelessWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 520,
        ),
        child: _EditDialogContent(user: user),
      ),
    );
  }
}

class _EditDialogContent extends StatefulWidget {
  final UserModel user;
  const _EditDialogContent({required this.user});

  @override
  State<_EditDialogContent> createState() => _EditDialogContentState();
}

class _EditDialogContentState extends State<_EditDialogContent>
    with SingleTickerProviderStateMixin {
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;

  String? _selectedRole;
  bool _isActive       = true;
  bool _isSaving       = false;
  bool _isLoadingRoles = false;
  bool _obscurePwd     = true;
  bool _pwdChanged     = false;
  List<Map<String, dynamic>> _roles = [];
  String? _errorMessage;

  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _TokenManager.getToken();
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _emailCtrl    = TextEditingController(text: widget.user.email);
    _passwordCtrl = TextEditingController();
    _isActive     = widget.user.isActive;

    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _fetchRoles();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse("http://125.209.66.147:5001/api/roles"),
              headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = decoded['data'] ?? decoded['roles'] ??
                    decoded['content'] ?? [];
        }
        final list = rawList
            .map<Map<String, dynamic>>((e) => {
                  'id':   e['id'] ?? e['roleId'],
                  'name': e['name'] ?? e['roleName'] ?? e['role_name'] ?? '-',
                })
            .toList();
        final match = list.firstWhere(
          (r) => r['name'].toString().toLowerCase() ==
              widget.user.role.toLowerCase(),
          orElse: () => list.isNotEmpty ? list.first : {'name': widget.user.role},
        );
        setState(() {
          _roles        = list;
          _selectedRole = match['name'].toString();
        });
      }
    } catch (_) {
      setState(() => _selectedRole = widget.user.role);
    } finally {
      setState(() => _isLoadingRoles = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Username and email cannot be empty.");
      return;
    }
    setState(() { _isSaving = true; _errorMessage = null; });

    final roleMatch = _roles.firstWhere(
        (r) => r['name'].toString() == _selectedRole,
        orElse: () => <String, dynamic>{});
    final roleId = roleMatch['id'];

    final body = <String, dynamic>{
      'username':  _usernameCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'is_active': _isActive,
      'isActive':  _isActive,
      'status':    _isActive ? 'active' : 'inactive',
    };
    if (roleId != null) { body['roleId'] = roleId; body['role_id'] = roleId; }
    if (_pwdChanged && _passwordCtrl.text.isNotEmpty) {
      body['password'] = _passwordCtrl.text;
    }

    try {
      final headers = await _authHeaders();
      final response = await http
          .put(
            Uri.parse(
                "http://125.209.66.147:5001/api/users/${widget.user.id}"),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        _showSnackbar("User updated successfully!", _C.success);
        await _ctrl.reverse();
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        String msg = "Update failed (HTTP ${response.statusCode})";
        try {
          if (response.body.isNotEmpty) {
            final err = jsonDecode(response.body);
            msg = err['message'] ?? err['error'] ?? err['msg'] ?? msg;
          }
        } catch (_) {
          if (response.body.isNotEmpty) msg = response.body;
        }
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      setState(() => _errorMessage = "Network error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _close() => _ctrl.reverse().then((_) => Navigator.pop(context, false));

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 9),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(children: [
                  _Avatar(username: widget.user.username),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Edit user",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textHead)),
                      Text(
                        "ID #${widget.user.id}  ·  ${widget.user.username}",
                        style: const TextStyle(
                            fontSize: 11, color: _C.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.border, width: 0.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _C.textMuted),
                    ),
                  ),
                ]),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: _C.redLight,
                            border: Border.all(
                                color: _C.red.withOpacity(0.2), width: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: _C.red, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: Color(0xFFB71C1C),
                                      fontSize: 12)),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _errorMessage = null),
                              child: const Icon(Icons.close_rounded,
                                  size: 13, color: _C.textMuted),
                            ),
                          ]),
                        ),

                      _SectionLabel("Account information"),
                      const SizedBox(height: 12),

                      _FieldLabel("Username"),
                      const SizedBox(height: 5),
                      _InputField(
                          controller: _usernameCtrl,
                          hint: "Enter username",
                          icon: Icons.person_outline_rounded),

                      const SizedBox(height: 12),
                      _FieldLabel("Email address"),
                      const SizedBox(height: 5),
                      _InputField(
                          controller: _emailCtrl,
                          hint: "Enter email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),

                      const SizedBox(height: 12),
                      _FieldLabel("New password"),
                      const SizedBox(height: 5),
                      _PasswordField(
                        controller: _passwordCtrl,
                        obscure: _obscurePwd,
                        onToggle: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                        onChanged: (v) =>
                            setState(() => _pwdChanged = v.isNotEmpty),
                      ),
                      const SizedBox(height: 4),
                      const Text("Leave blank to keep current password",
                          style: TextStyle(
                              fontSize: 10.5, color: _C.textMuted)),

                      const SizedBox(height: 18),
                      _SectionLabel("Role & status"),
                      const SizedBox(height: 12),

                      _FieldLabel("Role"),
                      const SizedBox(height: 5),
                      _isLoadingRoles
                          ? Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: _C.inputFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _C.border, width: 0.7),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _C.accent),
                                ),
                              ),
                            )
                          : _roles.isEmpty
                              ? _InputField(
                                  controller: TextEditingController(
                                      text: _selectedRole ??
                                          widget.user.role),
                                  hint: "Enter role",
                                  icon: Icons.shield_outlined)
                              : _RoleDropdown(
                                  roles: _roles,
                                  selected: _selectedRole,
                                  onChanged: (v) =>
                                      setState(() => _selectedRole = v),
                                ),

                      const SizedBox(height: 12),
                      _FieldLabel("Account status"),
                      const SizedBox(height: 6),
                      _StatusToggle(
                        isActive: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  border: Border(
                      top: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: _C.border, width: 0.7),
                        ),
                        child: const Center(
                          child: Text("Cancel",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textMuted)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveChanges,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? const Color(0xFF2D6BBF)
                              : _C.accent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                                color: _C.accent.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_rounded,
                                        size: 15, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text("Save changes",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit dialog sub-widgets ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 12,
        decoration: BoxDecoration(
            color: _C.accent, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 7),
      Text(label.toUpperCase(),
          style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _C.textMuted,
              letterSpacing: 1.0)),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _C.textBody));
}

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _C.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focused ? _C.accent.withOpacity(0.5) : _C.border,
            width: _focused ? 1.2 : 0.7,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
              fontSize: 13.5, color: _C.textBody, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon,
                size: 17,
                color: _focused ? _C.accent : _C.textMuted),
            hintText: widget.hint,
            hintStyle: const TextStyle(color: _C.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _C.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focused ? _C.accent.withOpacity(0.5) : _C.border,
            width: _focused ? 1.2 : 0.7,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          onChanged: widget.onChanged,
          style: const TextStyle(
              fontSize: 13.5, color: _C.textBody, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded,
                size: 17,
                color: _focused ? _C.accent : _C.textMuted),
            hintText: "New password (optional)",
            hintStyle: const TextStyle(color: _C.textMuted),
            suffixIcon: GestureDetector(
              onTap: widget.onToggle,
              child: Icon(
                widget.obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 17, color: _C.textMuted,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
          ),
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _RoleDropdown(
      {required this.roles, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final names = roles.map((r) => r['name'].toString()).toList();
    final safeSelected =
        names.contains(selected) ? selected : (names.isNotEmpty ? names.first : null);

    return Container(
      decoration: BoxDecoration(
        color: _C.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border, width: 0.7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeSelected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _C.textMuted, size: 18),
          style: const TextStyle(
              fontSize: 13.5, color: _C.textBody, fontWeight: FontWeight.w500),
          borderRadius: BorderRadius.circular(12),
          items: names
              .map((name) => DropdownMenuItem(
                    value: name,
                    child: _RoleChip(role: name),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  const _StatusToggle({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? _C.success.withOpacity(0.05)
            : _C.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? _C.success.withOpacity(0.2)
              : _C.red.withOpacity(0.18),
          width: 0.7,
        ),
      ),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
              color: isActive ? _C.success : _C.red,
              shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isActive ? "Active" : "Inactive",
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? const Color(0xFF085041)
                          : const Color(0xFFB71C1C))),
              Text(
                isActive
                    ? "User can log in and access the system"
                    : "User is blocked from accessing the system",
                style: const TextStyle(
                    fontSize: 10.5, color: _C.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: _C.success,
          inactiveThumbColor: _C.red,
          inactiveTrackColor: _C.red.withOpacity(0.15),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Delete User Dialog ────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════
class _DeleteUserDialog extends StatelessWidget {
  final UserModel user;
  const _DeleteUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _DeleteDialogContent(user: user),
      ),
    );
  }
}

class _DeleteDialogContent extends StatefulWidget {
  final UserModel user;
  const _DeleteDialogContent({required this.user});

  @override
  State<_DeleteDialogContent> createState() => _DeleteDialogContentState();
}

class _DeleteDialogContentState extends State<_DeleteDialogContent>
    with SingleTickerProviderStateMixin {
  bool _isDeleting  = false;
  String? _errorMsg;

  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cancel() => _ctrl.reverse().then((_) => Navigator.pop(context, false));

  Future<void> _confirmDelete() async {
    setState(() { _isDeleting = true; _errorMsg = null; });

    try {
      final token = await _TokenManager.getToken();
      final response = await http
          .delete(
            Uri.parse(
                "http://125.209.66.147:5001/api/users/${widget.user.id}"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 15));

      // 200, 204 both mean success
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201) {
        if (!mounted) return;
        _showSnackbar();
        await _ctrl.reverse();
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // Try to parse an error message from the body
        String msg = "Delete failed (HTTP ${response.statusCode})";
        try {
          if (response.body.isNotEmpty) {
            final err = jsonDecode(response.body);
            msg = err['message'] ?? err['error'] ?? err['msg'] ?? msg;
          }
        } catch (_) {
          if (response.body.isNotEmpty) msg = response.body;
        }
        setState(() { _isDeleting = false; _errorMsg = msg; });
      }
    } catch (e) {
      setState(() { _isDeleting = false; _errorMsg = "Network error: $e"; });
    }
  }

  void _showSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: _C.red,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 9),
          Text(
            'User "${widget.user.username}" deleted.',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ]),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(children: [
                  // Red warning icon badge
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _C.redLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 19, color: _C.red),
                  ),
                  const SizedBox(width: 12),
                  const Text("Delete user",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _C.textHead)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isDeleting ? null : _cancel,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _C.border, width: 0.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _C.textMuted),
                    ),
                  ),
                ]),
              ),

              // ── Body ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // User info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _C.border, width: 0.7),
                      ),
                      child: Row(children: [
                        _Avatar(username: widget.user.username),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.username,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textHead)),
                              const SizedBox(height: 2),
                              Text(widget.user.email,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _C.textMuted),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoleChip(role: widget.user.role),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Warning message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _C.red.withOpacity(0.18), width: 0.7),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(Icons.warning_amber_rounded,
                                size: 16,
                                color: _C.red.withOpacity(0.8)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _C.textBody,
                                    height: 1.5),
                                children: [
                                  const TextSpan(
                                      text:
                                          "This action is permanent and cannot be undone. "),
                                  TextSpan(
                                    text: widget.user.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _C.textHead),
                                  ),
                                  const TextSpan(
                                      text:
                                          "'s account, settings, and access will be permanently removed."),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error banner (shown only on API failure)
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: _C.redLight,
                          border: Border.all(
                              color: _C.red.withOpacity(0.2), width: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: _C.red, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMsg!,
                                style: const TextStyle(
                                    color: Color(0xFFB71C1C),
                                    fontSize: 12)),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _errorMsg = null),
                            child: const Icon(Icons.close_rounded,
                                size: 13, color: _C.textMuted),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Footer ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  border: Border(
                      top: BorderSide(color: _C.border, width: 0.5)),
                ),
                child: Row(children: [
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting ? null : _cancel,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: _C.border, width: 0.7),
                        ),
                        child: const Center(
                          child: Text("Cancel",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textMuted)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete confirm
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isDeleting ? null : _confirmDelete,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isDeleting
                              ? const Color(0xFFB71C1C)
                              : _C.red,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                                color: _C.red.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Center(
                          child: _isDeleting
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.delete_rounded,
                                        size: 15,
                                        color: Colors.white),
                                    SizedBox(width: 6),
                                    Text("Yes, delete user",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}