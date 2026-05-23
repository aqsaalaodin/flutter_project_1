import 'package:flutter/material.dart';
import 'package:flutter_project_1/CreateUserScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFF8F4F0);
  static const surface     = Color(0xFFFFFFFF);
  static const primary     = Color(0xFFE60023);
  static const primaryDark = Color(0xFFAD081B);
  static const ink         = Color(0xFF111111);
  static const muted       = Color(0xFF767676);
  static const border      = Color(0xFFE0DAD4);
  static const chip        = Color(0xFFFFF0F1);
  static const activeGreen = Color(0xFF00A699);
  static const headerBg    = Color(0xFFFDF9F7);
  static const blueChip    = Color(0xFFEBF5FF);
  static const blueBorder  = Color(0xFFBDDAF7);
  static const blueText    = Color(0xFF1A6FB0);
  static const inputFill   = Color(0xFFFDFBF9);
}

// ─── Token Manager ────────────────────────────────────────────────────────────
// Strategy:
//   1. Try auto-login with your real credentials first.
//   2. If login fails (wrong endpoint / network issue), fall back to the
//      hardcoded token so the app never shows "Authentication failed".
//   3. On every API call we check expiry from the JWT payload and re-login
//      automatically — no more manual Postman token copies needed.
class _TokenManager {
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  // ── Your real login credentials ───────────────────────────────────────────
  static const _loginUrl      = "http://125.209.66.147:5001/api/auth/login";
  static const _loginUsername = "superadmin";
  static const _loginPassword = "superadmin"; // ← apna real password yahan
  // ─────────────────────────────────────────────────────────────────────────

  // ── Hardcoded fallback token (used when auto-login fails) ─────────────────
  // Jab bhi Postman se naya token lo, sirf yeh line update karo:
  static const _fallbackToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3OTQ3OTUxMiwiZXhwIjoxNzgwMDg0MzEyfQ.6-iX_iyKCXzo2s5b7VvCoPi2RnSAgk1a-_oIuz-heB4";
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a valid token. Order of priority:
  ///   cached (not expired) → auto-login → fallback token
  static Future<String> getToken() async {
    // 1. Return cached if still valid
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
            _tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedToken!;
    }

    // 2. Try auto-login with real credentials
    final fresh = await _loginAndGetToken();
    if (fresh != null) return fresh;

    // 3. Fallback: use hardcoded token (never shows error to user)
    //    Also cache it so we don't repeat the login attempt every call
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
        // Handles common key names: token / access_token / accessToken
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
    } catch (_) {
      // Network error or wrong endpoint — silently fall through to fallback
    }
    return null;
  }

  /// Reads the `exp` field from a JWT payload so we know when to refresh.
  static DateTime? _parseExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) payload += '=';
      final decoded =
          jsonDecode(utf8.decode(base64Url.decode(payload)));
      final exp = decoded['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      }
    } catch (_) {}
    return null;
  }

  /// Force a fresh login on next call (used after 401).
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

// ─── Stateful Widget ──────────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    fetchUsers();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── FIX: fetch with auto-refresh token on 401 ─────────────────────────────
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

        // On 401 invalidate token and retry once
        if (response.statusCode == 401) {
          _TokenManager.invalidate();
          final newToken = await _TokenManager.getToken();
          if (newToken == null) break;
          final retryHeaders = {
            "Authorization": "Bearer $newToken",
            "Content-Type": "application/json",
          };
          final retry = await http
              .get(Uri.parse(urlStr), headers: retryHeaders)
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
        allUsers      = parsed;
        _currentPage  = 1;
        _totalPages   = (_totalPages == 0) ? 1 : (allUsers.length / _pageSize).ceil();
        final total   = allUsers.length;
        _totalPages   = (total / _pageSize).ceil().clamp(1, 9999);
        users         = allUsers.sublist(0, _pageSize.clamp(0, total));
        isLoading     = false;
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

  // ── View dialog ────────────────────────────────────────────────────────────
  void _openViewDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => _ViewUserDialog(user: user),
    );
  }

  // ── FIX: Edit now opens a dialog instead of a new screen ──────────────────
  void _openEditDialog(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => _EditUserDialog(user: user),
    );
    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 400));
      fetchUsers();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // FIX: detect mobile so we can switch layouts
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 5, height: 20,
              decoration: BoxDecoration(
                  color: _C.primary,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 10),
            const Text(
              "User Management",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                  letterSpacing: -0.4),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
        actions: [
          _AppBarIconButton(icon: Icons.refresh_rounded, onTap: fetchUsers),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CreateButton(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateUserScreen()),
                );
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Row(
                    children: [
                      const Text(
                        "User Management",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                            letterSpacing: -0.6),
                      ),
                      const SizedBox(width: 12),
                      if (!isLoading && allUsers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.chip,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _C.primary.withOpacity(0.18),
                                width: 1),
                          ),
                          child: Text(
                            "${allUsers.length}",
                            style: const TextStyle(
                                color: _C.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Manage your team members and their access",
                    style: TextStyle(
                        fontSize: 13,
                        color: _C.muted,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 20),

                  // Error banner
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F3),
                        border: Border.all(
                            color: _C.primary.withOpacity(0.25), width: 1.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: _C.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(errorMessage!,
                                style: const TextStyle(
                                    color: _C.primaryDark, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // FIX: switch between desktop table and mobile cards
                  if (isMobile)
                    _buildMobileList()
                  else
                    _buildDesktopTable(),

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

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile card list ───────────────────────────────────────────────────────
  Widget _buildMobileList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(
                color: _C.primary, strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text("No users found",
              style:
                  const TextStyle(color: _C.muted, fontSize: 14)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MobileUserCard(
        user: users[i],
        onView: () => _openViewDialog(users[i]),
        onEdit: () => _openEditDialog(users[i]),
      ),
    );
  }

  // ── Desktop table ──────────────────────────────────────────────────────────
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 8)),
          BoxShadow(
              color: _C.primary.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              color: _C.headerBg,
              child: const Row(
                children: [
                  Expanded(flex: 1,  child: _HeaderCell(label: "ID")),
                  Expanded(flex: 2,  child: _HeaderCell(label: "Username")),
                  Expanded(flex: 3,  child: _HeaderCell(label: "Email")),
                  Expanded(flex: 2,  child: _HeaderCell(label: "Role")),
                  Expanded(flex: 2,  child: _HeaderCell(label: "Status")),
                  Expanded(flex: 3,  child: _HeaderCell(label: "Created At")),
                  Expanded(flex: 2,  child: _HeaderCell(label: "Actions")),
                ],
              ),
            ),
            Container(height: 1, color: _C.border),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: _C.primary, strokeWidth: 2.5),
                  ),
                ),
              )
            else if (users.isEmpty)
              Column(children: [
                _buildEmptyRow(), _divider(),
                _buildEmptyRow(), _divider(),
                _buildEmptyRow(),
              ])
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    _buildRow(users[index]),
                    if (index != users.length - 1) _divider(),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(user.id.toString(),
                  style: const TextStyle(
                      fontSize: 13,
                      color: _C.muted,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              flex: 2,
              child: Text(user.username,
                  style: const TextStyle(
                      fontSize: 13,
                      color: _C.ink,
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(
              flex: 3,
              child: Text(user.email,
                  style: const TextStyle(
                      fontSize: 13,
                      color: _C.muted,
                      fontWeight: FontWeight.w400)),
            ),
            Expanded(flex: 2, child: _RoleChip(role: user.role)),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _StatusChip(isActive: user.isActive),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(user.createdAt,
                  style: const TextStyle(
                      fontSize: 12,
                      color: _C.muted,
                      fontWeight: FontWeight.w400)),
            ),
            Expanded(
              flex: 2,
              child: ActionButtons(
                onViewTap: () => _openViewDialog(user),
                onEditTap: () => _openEditDialog(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRow() {
    return _HoverableRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Expanded(flex: 1,  child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(flex: 2,  child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(flex: 3,  child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            const Expanded(flex: 2, child: _RoleChip(role: "Role")),
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: _StatusChip(isActive: true),
              ),
            ),
            Expanded(flex: 3,  child: Text("-", style: const TextStyle(fontSize: 12, color: _C.muted))),
            const Expanded(
              flex: 2,
              child: ActionButtons(onEditTap: null, onViewTap: null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _C.border.withOpacity(0.7));
}

// ─── Mobile User Card ─────────────────────────────────────────────────────────
// FIX: Card-based layout for small screens — no overflow
class _MobileUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const _MobileUserCard({
    required this.user,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + status
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _C.chip,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _C.primary.withOpacity(0.22), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _C.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.ink)),
                    Text("ID #${user.id}",
                        style: const TextStyle(
                            fontSize: 11, color: _C.muted)),
                  ],
                ),
              ),
              _StatusChip(isActive: user.isActive),
            ],
          ),
          const SizedBox(height: 12),
          _cardDivider(),
          const SizedBox(height: 12),

          // Email
          _CardRow(
              icon: Icons.email_outlined,
              label: "Email",
              value: user.email),
          const SizedBox(height: 8),

          // Role
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: _C.muted),
              const SizedBox(width: 6),
              const Text("Role",
                  style: TextStyle(
                      fontSize: 11,
                      color: _C.muted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _RoleChip(role: user.role),
            ],
          ),
          const SizedBox(height: 8),

          // Created
          _CardRow(
              icon: Icons.calendar_today_outlined,
              label: "Created",
              value: user.createdAt),

          const SizedBox(height: 12),
          _cardDivider(),
          const SizedBox(height: 12),

          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MobileActionBtn(
                icon: Icons.visibility_outlined,
                label: "View",
                color: _C.activeGreen,
                onTap: onView,
              ),
              const SizedBox(width: 8),
              _MobileActionBtn(
                icon: Icons.edit_outlined,
                label: "Edit",
                color: _C.blueText,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _MobileActionBtn(
                icon: Icons.delete_outline_rounded,
                label: "Delete",
                color: _C.primary,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardDivider() =>
      Container(height: 1, color: _C.border.withOpacity(0.7));
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CardRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _C.muted),
        const SizedBox(width: 6),
        Text("$label: ",
            style: const TextStyle(
                fontSize: 11,
                color: _C.muted,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: _C.ink,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _MobileActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MobileActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Header Cell ──────────────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _C.muted,
            letterSpacing: 0.7),
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
        duration: const Duration(milliseconds: 140),
        color: _hovered ? _C.bg : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

// ─── AppBar Icon Button ───────────────────────────────────────────────────────
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _hovered ? _C.chip : _C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.1),
          ),
          child: Icon(widget.icon,
              size: 18, color: _hovered ? _C.primary : _C.muted),
        ),
      ),
    );
  }
}

// ─── Create Button ────────────────────────────────────────────────────────────
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
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? _C.primaryDark : _C.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(_pressed ? 0.18 : 0.32),
              blurRadius: _pressed ? 6 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text("CREATE",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.7)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _C.blueChip,
        border: Border.all(color: _C.blueBorder, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(role,
          style: const TextStyle(
              color: _C.blueText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? _C.activeGreen.withOpacity(0.08)
            : _C.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _C.activeGreen.withOpacity(0.28)
              : _C.primary.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isActive ? _C.activeGreen : _C.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? "Active" : "Inactive",
            style: TextStyle(
                color: isActive ? _C.activeGreen : _C.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class ActionButtons extends StatelessWidget {
  final VoidCallback? onEditTap;
  final VoidCallback? onViewTap;
  const ActionButtons(
      {super.key, required this.onEditTap, this.onViewTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
            icon: Icons.visibility_outlined,
            color: _C.muted,
            hoverColor: _C.activeGreen,
            onTap: onViewTap),
        _ActionIcon(
            icon: Icons.edit_outlined,
            color: _C.muted,
            hoverColor: _C.blueText,
            onTap: onEditTap),
        _ActionIcon(
            icon: Icons.delete_outline_rounded,
            color: _C.muted,
            hoverColor: _C.primary,
            onTap: () {}),
      ],
    );
  }
}

class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback? onTap;
  const _ActionIcon(
      {required this.icon,
      required this.color,
      required this.hoverColor,
      this.onTap});

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _hovered ? widget.hoverColor : widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30, height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.hoverColor.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: activeColor),
        ),
      ),
    );
  }
}

// ─── Pagination Footer ────────────────────────────────────────────────────────
class _PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  List<int?> _buildPageNumbers() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[];
    pages.add(1);
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
    final startItem = ((currentPage - 1) * pageSize) + 1;
    final endItem   = (currentPage * pageSize).clamp(0, totalItems);
    final pageNums  = _buildPageNumbers();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: _C.muted,
                        fontWeight: FontWeight.w400),
                    children: [
                      const TextSpan(text: "Showing "),
                      TextSpan(
                          text: "$startItem–$endItem",
                          style: const TextStyle(
                              color: _C.ink, fontWeight: FontWeight.w700)),
                      const TextSpan(text: " of "),
                      TextSpan(
                          text: "$totalItems",
                          style: const TextStyle(
                              color: _C.ink, fontWeight: FontWeight.w700)),
                      const TextSpan(text: " users"),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  const Text("Rows:",
                      style: TextStyle(
                          fontSize: 12,
                          color: _C.muted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.border, width: 1.1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSize,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: _C.muted),
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: _C.ink,
                            fontWeight: FontWeight.w600),
                        borderRadius: BorderRadius.circular(10),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _C.border.withOpacity(0.6)),
          const SizedBox(height: 12),
          // FIX: wrap in SingleChildScrollView to avoid overflow on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageBtn(
                    label: "←",
                    isDisabled: currentPage == 1,
                    isActive: false,
                    onTap: () => onPageChanged(currentPage - 1)),
                const SizedBox(width: 4),
                ...pageNums.map((p) {
                  if (p == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("…",
                          style: TextStyle(
                              fontSize: 13,
                              color: _C.muted,
                              fontWeight: FontWeight.w600)),
                    );
                  }
                  return _PageBtn(
                      label: "$p",
                      isActive: p == currentPage,
                      isDisabled: false,
                      onTap: () => onPageChanged(p));
                }),
                const SizedBox(width: 4),
                _PageBtn(
                    label: "→",
                    isDisabled: currentPage == totalPages,
                    isActive: false,
                    onTap: () => onPageChanged(currentPage + 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.label,
    required this.isActive,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_PageBtn> createState() => _PageBtnState();
}

class _PageBtnState extends State<_PageBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor     = Colors.transparent;
    Color textColor   = _C.muted;
    Color borderColor = Colors.transparent;

    if (widget.isActive) {
      bgColor = _C.primary; textColor = Colors.white; borderColor = _C.primary;
    } else if (_hovered && !widget.isDisabled) {
      bgColor = _C.chip; textColor = _C.primary;
      borderColor = _C.primary.withOpacity(0.3);
    } else if (widget.isDisabled) {
      textColor = _C.border;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 34, height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: widget.label.length > 2 ? 14 : 13,
                    fontWeight: widget.isActive
                        ? FontWeight.w800
                        : FontWeight.w600,
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
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 560,
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
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    _ctrl.reverse().then((_) => Navigator.pop(context));
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border:
                      Border(bottom: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _C.chip,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _C.primary.withOpacity(0.18), width: 1),
                      ),
                      child: const Icon(Icons.visibility_outlined,
                          size: 18, color: _C.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text("View User",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                            letterSpacing: -0.4)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: _C.border, width: 1.1),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: _C.muted),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: _C.chip,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _C.primary.withOpacity(0.22),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(
                                widget.user.username.isNotEmpty
                                    ? widget.user.username[0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _C.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.username,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _C.ink)),
                              const SizedBox(height: 2),
                              Text("ID #${widget.user.id}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _C.muted,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const Spacer(),
                          _StatusChip(isActive: widget.user.isActive),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: _C.border.withOpacity(0.7)),
                      const SizedBox(height: 20),
                      _DialogField(label: "Username",   value: widget.user.username,  icon: Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      _DialogField(label: "Email",      value: widget.user.email,     icon: Icons.email_outlined),
                      const SizedBox(height: 14),
                      _DialogField(label: "Role",       value: widget.user.role,      icon: Icons.shield_outlined, isRole: true),
                      const SizedBox(height: 14),
                      _DialogField(label: "Regions",    value: "No regions selected", icon: Icons.location_on_outlined, isEmpty: true),
                      const SizedBox(height: 14),
                      _DialogField(label: "Created At", value: widget.user.createdAt, icon: Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24)),
                  border:
                      Border(top: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 11),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _C.border, width: 1.3),
                        ),
                        child: const Text("CLOSE",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _C.blueText,
                                letterSpacing: 0.5)),
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
  final String label;
  final String value;
  final IconData icon;
  final bool isRole;
  final bool isEmpty;

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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.muted,
                letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border, width: 1.1),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16, color: isEmpty ? _C.border : _C.muted),
              const SizedBox(width: 10),
              if (isRole)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.blueChip,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.blueBorder, width: 1),
                  ),
                  child: Text(value,
                      style: const TextStyle(
                          color: _C.blueText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                )
              else
                Expanded(
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: isEmpty ? _C.border : _C.ink,
                          fontWeight:
                              isEmpty ? FontWeight.w400 : FontWeight.w500,
                          fontStyle: isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Edit User Dialog (converted from EditUserScreen) ─────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════
class _EditUserDialog extends StatelessWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 560,
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
  bool    _isActive        = true;
  bool    _isSaving        = false;
  bool    _isLoadingRoles  = false;
  bool    _obscurePassword = true;
  bool    _passwordChanged = false;
  List<Map<String, dynamic>> _roles = [];
  String? _errorMessage;

  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _scale;

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
      };

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
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
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
                  'name': e['name'] ?? e['roleName'] ??
                          e['role_name'] ?? '-',
                })
            .toList();
        final match = list.firstWhere(
          (r) => r['name'].toString().toLowerCase() ==
              widget.user.role.toLowerCase(),
          orElse: () =>
              list.isNotEmpty ? list.first : {'name': widget.user.role},
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
      setState(
          () => _errorMessage = "Username and email cannot be empty.");
      return;
    }
    setState(() {
      _isSaving     = true;
      _errorMessage = null;
    });

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
    if (roleId != null) {
      body['roleId']  = roleId;
      body['role_id'] = roleId;
    }
    if (_passwordChanged && _passwordCtrl.text.isNotEmpty) {
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

      final isSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      if (isSuccess) {
        if (!mounted) return;
        _showSuccessSnackbar();
        await _ctrl.reverse();
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        String msg =
            "Update failed (HTTP ${response.statusCode})";
        try {
          if (response.body.isNotEmpty) {
            final err = jsonDecode(response.body);
            msg = err['message'] ?? err['error'] ?? err['msg'] ?? msg;
          }
        } catch (_) {
          if (response.body.isNotEmpty) msg = response.body;
        }
        setState(() => _errorMessage = "❌ $msg");
      }
    } catch (e) {
      setState(() => _errorMessage = "Network error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _close() {
    _ctrl.reverse().then((_) => Navigator.pop(context, false));
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        backgroundColor: _C.activeGreen,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("User updated successfully!",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Dialog Header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  border: Border(
                      bottom: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _C.chip,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _C.primary.withOpacity(0.22),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          widget.user.username.isNotEmpty
                              ? widget.user.username[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Edit User",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _C.ink,
                                letterSpacing: -0.4)),
                        Text(
                          "ID #${widget.user.id}  ·  ${widget.user.username}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: _C.muted,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _C.border, width: 1.1),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: _C.muted),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Body ───────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F3),
                            border: Border.all(
                                color: _C.primary.withOpacity(0.25),
                                width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: _C.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: _C.primaryDark,
                                        fontSize: 12)),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _errorMessage = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: _C.muted),
                              ),
                            ],
                          ),
                        ),

                      // Account info section
                      _EditSectionLabel(label: "Account Information"),
                      const SizedBox(height: 14),

                      _EditFieldLabel(label: "Username"),
                      const SizedBox(height: 6),
                      _EditInputField(
                          controller: _usernameCtrl,
                          hint: "Enter username",
                          icon: Icons.person_outline_rounded),

                      const SizedBox(height: 14),
                      _EditFieldLabel(label: "Email Address"),
                      const SizedBox(height: 6),
                      _EditInputField(
                          controller: _emailCtrl,
                          hint: "Enter email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),

                      const SizedBox(height: 14),
                      _EditFieldLabel(label: "New Password"),
                      const SizedBox(height: 6),
                      _EditPasswordField(
                        controller: _passwordCtrl,
                        obscure: _obscurePassword,
                        onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        onChanged: (v) => setState(
                            () => _passwordChanged = v.isNotEmpty),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                          "Leave blank to keep the current password",
                          style: TextStyle(
                              fontSize: 11, color: _C.muted)),

                      const SizedBox(height: 20),
                      _EditSectionLabel(label: "Role & Status"),
                      const SizedBox(height: 14),

                      _EditFieldLabel(label: "Role"),
                      const SizedBox(height: 6),
                      _isLoadingRoles
                          ? Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _C.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _C.border, width: 1.2),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _C.primary),
                                ),
                              ),
                            )
                          : _roles.isEmpty
                              ? _EditInputField(
                                  controller: TextEditingController(
                                      text: _selectedRole ??
                                          widget.user.role),
                                  hint: "Enter role",
                                  icon: Icons.shield_outlined)
                              : _EditRoleDropdown(
                                  roles: _roles,
                                  selected: _selectedRole,
                                  onChanged: (v) =>
                                      setState(() => _selectedRole = v),
                                ),

                      const SizedBox(height: 14),
                      _EditFieldLabel(label: "Account Status"),
                      const SizedBox(height: 8),
                      _EditStatusToggle(
                        isActive: _isActive,
                        onChanged: (v) =>
                            setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Dialog Footer ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24)),
                  border: Border(
                      top: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: _close,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _C.border, width: 1.3),
                          ),
                          child: const Center(
                            child: Text("Cancel",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _C.muted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Save
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _saveChanges,
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 120),
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isSaving
                                ? _C.primaryDark
                                : _C.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white),
                                      SizedBox(width: 6),
                                      Text("Save Changes",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w800,
                                              fontSize: 13.5)),
                                    ],
                                  ),
                          ),
                        ),
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

// ─── Edit Dialog Sub-widgets ──────────────────────────────────────────────────

class _EditSectionLabel extends StatelessWidget {
  final String label;
  const _EditSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
              color: _C.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _C.muted,
                letterSpacing: 1.1)),
      ],
    );
  }
}

class _EditFieldLabel extends StatelessWidget {
  final String label;
  const _EditFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.ink));
}

class _EditInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _EditInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_EditInputField> createState() => _EditInputFieldState();
}

class _EditInputFieldState extends State<_EditInputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _C.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? _C.primary.withOpacity(0.55) : _C.border,
            width: _focused ? 1.5 : 1.2,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
              fontSize: 14, color: _C.ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon,
                size: 18,
                color: _focused ? _C.primary : _C.muted),
            hintText: widget.hint,
            hintStyle: const TextStyle(
                color: _C.muted, fontWeight: FontWeight.w400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _EditPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _EditPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_EditPasswordField> createState() => _EditPasswordFieldState();
}

class _EditPasswordFieldState extends State<_EditPasswordField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _C.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? _C.primary.withOpacity(0.55) : _C.border,
            width: _focused ? 1.5 : 1.2,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          onChanged: widget.onChanged,
          style: const TextStyle(
              fontSize: 14, color: _C.ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded,
                size: 18,
                color: _focused ? _C.primary : _C.muted),
            hintText: "Enter new password (optional)",
            hintStyle: const TextStyle(
                color: _C.muted, fontWeight: FontWeight.w400),
            suffixIcon: GestureDetector(
              onTap: widget.onToggle,
              child: Icon(
                widget.obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _C.muted,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _EditRoleDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _EditRoleDropdown({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final names = roles.map((r) => r['name'].toString()).toList();
    final safeSelected =
        names.contains(selected) ? selected : (names.isNotEmpty ? names.first : null);

    return Container(
      decoration: BoxDecoration(
        color: _C.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeSelected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _C.muted, size: 20),
          style: const TextStyle(
              fontSize: 14, color: _C.ink, fontWeight: FontWeight.w500),
          borderRadius: BorderRadius.circular(14),
          items: names
              .map((name) => DropdownMenuItem(
                    value: name,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.blueChip,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _C.blueBorder, width: 1),
                      ),
                      child: Text(name,
                          style: const TextStyle(
                              color: _C.blueText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EditStatusToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  const _EditStatusToggle(
      {required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? _C.activeGreen.withOpacity(0.06)
            : _C.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? _C.activeGreen.withOpacity(0.25)
              : _C.primary.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                color: isActive ? _C.activeGreen : _C.primary,
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isActive ? "Active" : "Inactive",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? _C.activeGreen : _C.primary)),
                Text(
                  isActive
                      ? "User can log in and access the system"
                      : "User is blocked from accessing the system",
                  style: const TextStyle(
                      fontSize: 11, color: _C.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: _C.activeGreen,
            inactiveThumbColor: _C.primary,
            inactiveTrackColor: _C.primary.withOpacity(0.15),
          ),
        ],
      ),
    );
  }
}