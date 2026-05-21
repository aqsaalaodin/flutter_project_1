import 'package:flutter/material.dart';
import 'package:flutter_project_1/CreateUserScreen.dart';
import 'package:flutter_project_1/EditUserScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // compute()

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
}

// ─── Model ────────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final int roleId;
  final String username;
  final String email;
  final String role;
  final String roleName;
  final String roleDescription;
  // FIX: permissions is now mutable so we can update it after edit
  Map<String, List<String>> permissions;
  final String createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    this.roleId = 0,
    required this.username,
    required this.email,
    required this.role,
    this.roleName = '',
    this.roleDescription = '',
    Map<String, List<String>>? permissions,
    required this.createdAt,
    this.isActive = true,
  }) : permissions = permissions ?? {};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String roleStr = '-';
    String roleNameStr = '';
    String roleDescStr = '';
    Map<String, List<String>> permsMap = {};
    int parsedRoleId = 0;

    if (json['role'] is Map) {
      final roleObj = json['role'] as Map<String, dynamic>;
      roleStr = roleObj['name'] ?? roleObj['roleName'] ?? '-';
      roleNameStr = roleStr;
      roleDescStr = roleObj['description'] ?? '';
      parsedRoleId = roleObj['id'] ?? roleObj['roleId'] ?? 0;
      if (roleObj['permissions'] is Map) {
        final raw = roleObj['permissions'] as Map<String, dynamic>;
        raw.forEach((key, val) {
          if (val is List) {
            permsMap[key] = val.map((e) => e.toString()).toList();
          }
        });
      }
    } else {
      roleStr = json['role'] ?? json['roleName'] ?? '-';
      roleNameStr = roleStr;
      parsedRoleId = json['roleId'] ?? json['role_id'] ?? 0;
    }

    return UserModel(
      id: json['id'] ?? 0,
      roleId: parsedRoleId,
      username: json['username'] ?? '-',
      email: json['email'] ?? '-',
      role: roleStr,
      roleName: roleNameStr,
      roleDescription: roleDescStr,
      permissions: permsMap,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '-',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }
}

// ── Top-level isolate function for JSON parsing ───────────────────────────────
List<UserModel> _parseUsers(String body) {
  final dynamic decoded = jsonDecode(body);
  List<dynamic> rawList = [];
  if (decoded is List) {
    rawList = decoded;
  } else if (decoded is Map) {
    for (final key in ['data', 'users', 'content', 'items']) {
      if (decoded[key] is List) {
        rawList = decoded[key] as List<dynamic>;
        break;
      }
    }
  }
  return rawList
      .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ─── Default permissions used as fallback ─────────────────────────────────────
// FIX: Extracted to a top-level getter so both View and Edit use the same source
Map<String, List<String>> _defaultPermissions() => {
  'vendorAssignment':       ['read', 'create', 'update', 'delete'],
  'user':                   ['read', 'create', 'update', 'delete'],
  'role':                   ['read', 'create', 'update', 'delete'],
  'vendorRequests':         ['read', 'create', 'update', 'delete'],
  'shopboardRequest':       ['read', 'create', 'update', 'delete', 'approvals'],
  'requestPriceAdjustment': ['read', 'create', 'update', 'delete'],
  'requestTypes':           ['read', 'create', 'update', 'delete'],
  'statistics':             ['create', 'read', 'update', 'delete'],
  'budgetManagement':       ['create', 'read', 'update', 'delete'],
  'payments':               ['create', 'read', 'update', 'delete'],
  'paymentBatch':           ['read', 'create', 'update', 'delete'],
  'smtpSettings':           ['read', 'create', 'update', 'delete'],
};

// ─── FIX: Static permissions cache keyed by user ID ──────────────────────────
// Yeh cache dialog close hone ke baad bhi permissions yaad rakhta hai.
// Jab user cross kare ya cancel kare, edited permissions yahan stored rehti hain.
// Jab dialog dobara khule, wohi saved permissions load hoti hain — fresh seed nahi.
final Map<int, Map<String, List<String>>> _userPermissionsCache = {};

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  List<UserModel> allUsers = [];
  List<UserModel> users = [];
  bool isLoading = true;
  String? errorMessage;

  static List<UserModel>? _cachedUsers;

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3ODc0OTc1NSwiZXhwIjoxNzc5MzU0NTU1fQ.Sb5xCnHnUoIoN2c3JvBU1ldMDe2_7wJBsPGeGyZe-v0";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    if (_cachedUsers != null && _cachedUsers!.isNotEmpty) {
      allUsers = List.of(_cachedUsers!);
      isLoading = false;
      _applyPaginationSilent();
      _refreshInBackground();
    } else {
      fetchUsers(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshInBackground() async {
    final fresh = await _loadFromNetwork(sendNoCache: false);
    if (fresh != null && mounted) {
      setState(() {
        allUsers = fresh;
        _cachedUsers = fresh;
        _applyPaginationSilent();
      });
    }
  }

  Future<void> fetchUsers({bool forceRefresh = true}) async {
    if (forceRefresh) {
      _cachedUsers = null;
      // FIX: Refresh karti toh permissions cache bhi clear karo
      // taake fresh data se naye permissions aayein
      _userPermissionsCache.clear();
    }
    if (mounted) setState(() { isLoading = true; errorMessage = null; });

    final result = await _loadFromNetwork(sendNoCache: forceRefresh);
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() {
        allUsers = result;
        _cachedUsers = result;
        _currentPage = 1;
        _applyPaginationSilent();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        if (allUsers.isEmpty) errorMessage = "Could not load users.";
      });
    }
  }

  Future<List<UserModel>?> _loadFromNetwork({required bool sendNoCache}) async {
    final urls = [
      "http://125.209.66.147:5001/api/users?page=1&size=100",
      "http://125.209.66.147:5001/api/users?page=0&size=100",
      "http://125.209.66.147:5001/api/users",
    ];
    final headers = <String, String>{
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      if (sendNoCache) "Cache-Control": "no-cache",
    };
    for (final urlStr in urls) {
      try {
        final response = await http
            .get(Uri.parse(urlStr), headers: headers)
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 304) return _cachedUsers;
        if (response.statusCode == 204 || response.body.trim().isEmpty) continue;
        if (response.statusCode == 200) {
          final parsed = await compute(_parseUsers, response.body);
          if (parsed.isEmpty) continue;
          return parsed;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  void _applyPaginationSilent() {
    final total = allUsers.length;
    _totalPages = (total / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    users = allUsers.sublist(start, end);
  }

  void _applyPagination() {
    setState(() {
      final total = allUsers.length;
      _totalPages = (total / _pageSize).ceil();
      if (_totalPages == 0) _totalPages = 1;
      if (_currentPage > _totalPages) _currentPage = _totalPages;
      final start = (_currentPage - 1) * _pageSize;
      final end = (start + _pageSize).clamp(0, total);
      users = allUsers.sublist(start, end);
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
    _applyPagination();
  }

  void _openViewDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      // FIX: View dialog ko cached permissions pass karo
      builder: (_) => _ViewRoleDialog(
        user: user,
        cachedPermissions: _userPermissionsCache[user.id],
      ),
    );
  }

  void _openEditScreen(UserModel user) async {
    final result = await showDialog<Map<String, List<String>>?>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => _EditRoleDialog(
        user: user,
        token: token,
        // FIX: Cached permissions pass karo — agar pehle edit hua hai toh wahi load hoga
        initialPermissions: _userPermissionsCache[user.id],
      ),
    );

    // FIX: Dialog ne jo bhi permissions return kiye (cancel ya save dono mein),
    // unhe cache mein store karo. Is tarah dobara kholne par same state milegi.
    if (result != null && mounted) {
      setState(() {
        _userPermissionsCache[user.id] = result;
        // UserModel mein bhi update karo taake View dialog bhi updated dekhe
        final idx = allUsers.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          allUsers[idx].permissions = result;
        }
      });
    }

    // Agar API update successful tha (result == true equivalent), refresh karo
    // Lekin ab hum permissions map return karte hain, toh null check se pata chalega
    // Agar save hua toh network refresh
    if (result != null) {
      // Check if it was a successful save by refreshing after delay
      await Future.delayed(const Duration(milliseconds: 400));
      // Only refresh network if result came from save (not cancel)
      // Cancel bhi result return karta hai saved state ke saath — yeh intentional hai
    }
  }

  @override
  Widget build(BuildContext context) {
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
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "User Management",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _C.ink,
                letterSpacing: -0.4,
              ),
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
                    builder: (context) => const CreateUserScreen(),
                  ),
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
                  Row(
                    children: [
                      const Text(
                        "User Management",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.ink,
                          letterSpacing: -0.6,
                        ),
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
                              fontWeight: FontWeight.w700,
                            ),
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

                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F3),
                        border: Border.all(
                            color: _C.primary.withOpacity(0.25),
                            width: 1.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: _C.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                  color: _C.primaryDark, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: _C.primary.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            color: _C.headerBg,
                            child: const Row(
                              children: [
                                Expanded(flex: 1, child: _HeaderCell(label: "ID")),
                                Expanded(flex: 2, child: _HeaderCell(label: "Username")),
                                Expanded(flex: 3, child: _HeaderCell(label: "Email")),
                                Expanded(flex: 2, child: _HeaderCell(label: "Role")),
                                Expanded(flex: 2, child: _HeaderCell(label: "Status")),
                                Expanded(flex: 3, child: _HeaderCell(label: "Created At")),
                                Expanded(flex: 2, child: _HeaderCell(label: "Actions")),
                              ],
                            ),
                          ),
                          Container(height: 1, color: _C.border),

                          if (isLoading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: _C.primary,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            )
                          else if (users.isEmpty)
                            Column(
                              children: [
                                _buildEmptyRow(),
                                _divider(),
                                _buildEmptyRow(),
                                _divider(),
                                _buildEmptyRow(),
                              ],
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    _buildRow(users[index]),
                                    if (index != users.length - 1) _divider(),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (!isLoading && allUsers.isNotEmpty)
                    _PaginationFooter(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      totalItems: allUsers.length,
                      pageSize: _pageSize,
                      pageSizeOptions: _pageSizeOptions,
                      onPageChanged: _goToPage,
                      onPageSizeChanged: (size) {
                        setState(() {
                          _pageSize = size;
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

  Widget _buildRow(UserModel user) {
    return _HoverableRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(user.id.toString(),
                  style: const TextStyle(fontSize: 13, color: _C.muted, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              flex: 2,
              child: Text(user.username,
                  style: const TextStyle(fontSize: 13, color: _C.ink, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              flex: 3,
              child: Text(user.email,
                  style: const TextStyle(fontSize: 13, color: _C.muted, fontWeight: FontWeight.w400)),
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
                  style: const TextStyle(fontSize: 12, color: _C.muted, fontWeight: FontWeight.w400)),
            ),
            Expanded(
              flex: 2,
              child: ActionButtons(
                onViewTap: () => _openViewDialog(user),
                onEditTap: () => _openEditScreen(user),
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
            Expanded(flex: 1, child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(flex: 2, child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(flex: 3, child: Text("-", style: const TextStyle(fontSize: 13, color: _C.muted))),
            const Expanded(flex: 2, child: _RoleChip(role: "Role")),
            const Expanded(
              flex: 2,
              child: Padding(padding: EdgeInsets.only(left: 4), child: _StatusChip(isActive: true)),
            ),
            Expanded(flex: 3, child: Text("-", style: const TextStyle(fontSize: 12, color: _C.muted))),
            const Expanded(flex: 2, child: ActionButtons(onEditTap: null, onViewTap: null)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _C.border.withOpacity(0.7));
}

// ─── Header Cell ──────────────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.muted, letterSpacing: 0.7),
    );
  }
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
      onExit: (_) => setState(() => _hovered = false),
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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hovered ? _C.chip : _C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.1),
          ),
          child: Icon(widget.icon, size: 18, color: _hovered ? _C.primary : _C.muted),
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
            Text(
              "CREATE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.7,
              ),
            ),
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
      child: Text(
        role,
        style: const TextStyle(color: _C.blueText, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
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
        color: isActive ? _C.activeGreen.withOpacity(0.08) : _C.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? _C.activeGreen.withOpacity(0.28) : _C.primary.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
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
              fontWeight: FontWeight.w600,
            ),
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
  const ActionButtons({super.key, required this.onEditTap, this.onViewTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.visibility_outlined,
          color: _C.muted,
          hoverColor: _C.activeGreen,
          onTap: onViewTap,
        ),
        _ActionIcon(
          icon: Icons.edit_outlined,
          color: _C.muted,
          hoverColor: _C.blueText,
          onTap: onEditTap,
        ),
        _ActionIcon(
          icon: Icons.delete_outline_rounded,
          color: _C.muted,
          hoverColor: _C.primary,
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── Action Icon ──────────────────────────────────────────────────────────────
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.hoverColor,
    this.onTap,
  });

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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor.withOpacity(0.10) : Colors.transparent,
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
    if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12.5, color: _C.muted, fontWeight: FontWeight.w400),
                  children: [
                    const TextSpan(text: "Showing "),
                    TextSpan(text: "$startItem–$endItem",
                        style: const TextStyle(color: _C.ink, fontWeight: FontWeight.w700)),
                    const TextSpan(text: " of "),
                    TextSpan(text: "$totalItems",
                        style: const TextStyle(color: _C.ink, fontWeight: FontWeight.w700)),
                    const TextSpan(text: " users"),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text("Rows:",
                      style: TextStyle(fontSize: 12, color: _C.muted, fontWeight: FontWeight.w500)),
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
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _C.muted),
                        style: const TextStyle(fontSize: 12.5, color: _C.ink, fontWeight: FontWeight.w600),
                        borderRadius: BorderRadius.circular(10),
                        items: pageSizeOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text("$s")))
                            .toList(),
                        onChanged: (v) { if (v != null) onPageSizeChanged(v); },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageBtn(label: "←", isDisabled: currentPage == 1, isActive: false,
                  onTap: () => onPageChanged(currentPage - 1)),
              const SizedBox(width: 4),
              ...pageNums.map((p) {
                if (p == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text("…", style: TextStyle(fontSize: 13, color: _C.muted, fontWeight: FontWeight.w600)),
                  );
                }
                return _PageBtn(
                  label: "$p",
                  isActive: p == currentPage,
                  isDisabled: false,
                  onTap: () => onPageChanged(p),
                );
              }),
              const SizedBox(width: 4),
              _PageBtn(label: "→", isDisabled: currentPage == totalPages, isActive: false,
                  onTap: () => onPageChanged(currentPage + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Individual Page Button ───────────────────────────────────────────────────
class _PageBtn extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PageBtn({required this.label, required this.isActive, required this.isDisabled, required this.onTap});

  @override
  State<_PageBtn> createState() => _PageBtnState();
}

class _PageBtnState extends State<_PageBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = _C.muted;
    Color borderColor = Colors.transparent;

    if (widget.isActive) {
      bgColor = _C.primary; textColor = Colors.white; borderColor = _C.primary;
    } else if (_hovered && !widget.isDisabled) {
      bgColor = _C.chip; textColor = _C.primary; borderColor = _C.primary.withOpacity(0.3);
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
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.label.length > 2 ? 14 : 13,
                fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── View Role Dialog ─────────────────────────────────────────────────────────
// FIX: cachedPermissions parameter added — agar user ne pehle edit kiya tha
//      toh wahi permissions show hongi, fresh seed nahi.
// ═══════════════════════════════════════════════════════════════════════════════

class _ViewRoleDialog extends StatelessWidget {
  final UserModel user;
  // FIX: Cached permissions jo parent ne pass ki hain
  final Map<String, List<String>>? cachedPermissions;

  const _ViewRoleDialog({required this.user, this.cachedPermissions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _ViewRoleContent(user: user, cachedPermissions: cachedPermissions),
    );
  }
}

class _ViewRoleContent extends StatefulWidget {
  final UserModel user;
  final Map<String, List<String>>? cachedPermissions;

  const _ViewRoleContent({required this.user, this.cachedPermissions});

  @override
  State<_ViewRoleContent> createState() => _ViewRoleContentState();
}

class _ViewRoleContentState extends State<_ViewRoleContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  // FIX: Priority order:
  // 1. Parent se aaya cached permissions (user ne cross kiya tha pehle)
  // 2. UserModel mein stored permissions (API se aayi thi)
  // 3. Hardcoded fallback (sirf tab jab koi bhi nahi)
  Map<String, List<String>> get _permissions {
    if (widget.cachedPermissions != null && widget.cachedPermissions!.isNotEmpty) {
      return widget.cachedPermissions!;
    }
    if (widget.user.permissions.isNotEmpty) {
      return widget.user.permissions;
    }
    return _defaultPermissions();
  }

  int get _totalPermissions =>
      _permissions.values.fold(0, (sum, list) => sum + list.length);

  String _toLabel(String key) {
    final spaced = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.93, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    _ctrl.reverse().then((_) { if (mounted) Navigator.pop(context); });
  }

  @override
  Widget build(BuildContext context) {
    final perms = _permissions;
    final total = _totalPermissions;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 12)),
            ],
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadonlyField(label: "Role Name *", value: widget.user.role),
                      const SizedBox(height: 14),
                      _buildReadonlyField(
                        label: "Description",
                        value: widget.user.roleDescription.isEmpty
                            ? "Full system access with all permissions"
                            : widget.user.roleDescription,
                        minLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: _C.surface,
                          border: Border.all(color: _C.border, width: 1.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Text("Permissions",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.ink, letterSpacing: -0.2)),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 1, color: _C.border),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Current Permissions ($total)",
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _C.ink)),
                            ),
                            const SizedBox(height: 12),
                            ...perms.entries.map((entry) {
                              final label = _toLabel(entry.key);
                              final caps  = entry.value.map(_cap).join(', ');
                              return _buildPermissionRow(label: label, actions: caps);
                            }),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 20, color: _C.ink),
          const SizedBox(width: 10),
          const Text("View Role",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.ink, letterSpacing: -0.3)),
          const Spacer(),
          GestureDetector(
            onTap: _close,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.bg, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.border, width: 1.1),
              ),
              child: const Icon(Icons.close_rounded, size: 17, color: _C.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyField({required String label, required String value, int minLines = 1}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border(bottom: BorderSide(color: _C.border, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _C.ink)),
          if (minLines > 1) const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({required String label, required String actions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.ink)),
              const SizedBox(height: 3),
              Text(actions, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: _C.muted)),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: _C.border.withOpacity(0.7)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.3),
              ),
              child: const Text("CLOSE",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.blueText, letterSpacing: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Role Model ───────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class RoleModel {
  final int id;
  final String name;
  final String description;
  final Map<String, List<String>> permissions;

  const RoleModel({required this.id, required this.name, required this.description, required this.permissions});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final Map<String, List<String>> perms = {};
    final dynamic rawPerms = json['permissions'];
    if (rawPerms is Map) {
      rawPerms.forEach((key, val) {
        if (val is List) perms[key.toString()] = val.map((e) => e.toString()).toList();
      });
    } else if (rawPerms is List) {
      for (final p in rawPerms) {
        if (p is Map) {
          final feature = p['feature']?.toString() ?? p['name']?.toString() ?? p['module']?.toString() ?? '';
          final actions = p['actions'];
          if (feature.isNotEmpty && actions is List) {
            perms[feature] = actions.map((e) => e.toString()).toList();
          }
        }
      }
    }
    return RoleModel(
      id: json['id'] ?? json['roleId'] ?? 0,
      name: json['name'] ?? json['roleName'] ?? '',
      description: json['description'] ?? '',
      permissions: perms,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Edit Role Dialog ─────────────────────────────────────────────────────────
// FIX: initialPermissions parameter added + returns current permissions on close
// ═══════════════════════════════════════════════════════════════════════════════

class _EditRoleDialog extends StatelessWidget {
  final UserModel user;
  final String token;
  // FIX: Previously saved permissions (agar user ne pehle cross kiya tha)
  final Map<String, List<String>>? initialPermissions;

  const _EditRoleDialog({
    required this.user,
    required this.token,
    this.initialPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _EditRoleContent(
        user: user,
        token: token,
        initialPermissions: initialPermissions,
      ),
    );
  }
}

class _EditRoleContent extends StatefulWidget {
  final UserModel user;
  final String token;
  final Map<String, List<String>>? initialPermissions;

  const _EditRoleContent({
    required this.user,
    required this.token,
    this.initialPermissions,
  });

  @override
  State<_EditRoleContent> createState() => _EditRoleContentState();
}

class _EditRoleContentState extends State<_EditRoleContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  List<RoleModel> _availableRoles = [];
  bool _rolesLoading = true;
  String? _rolesError;

  String? _selectedFeature;
  List<String> _selectedActions = [];

  late Map<String, List<String>> _currentPermissions;

  bool _isSaving = false;

  static const _allFeatures = [
    'vendorAssignment', 'user', 'role', 'vendorRequests', 'shopboardRequest',
    'requestPriceAdjustment', 'requestTypes', 'statistics',
    'budgetManagement', 'payments', 'paymentBatch', 'smtpSettings',
  ];

  static const _allActions = ['read', 'create', 'update', 'delete'];

  String _toLabel(String key) {
    final spaced = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  int get _totalPermissions =>
      _currentPermissions.values.fold(0, (s, l) => s + l.length);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.93, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();

    _nameCtrl = TextEditingController(text: widget.user.role);
    _descCtrl = TextEditingController(
        text: widget.user.roleDescription.isEmpty
            ? 'Full system access with all permissions'
            : widget.user.roleDescription);

    // FIX: Permission priority:
    // 1. initialPermissions (cached from previous session — most important)
    // 2. user.permissions (API se aayi)
    // 3. defaultPermissions (sirf last resort)
    if (widget.initialPermissions != null && widget.initialPermissions!.isNotEmpty) {
      _currentPermissions = Map<String, List<String>>.from(
          widget.initialPermissions!.map((k, v) => MapEntry(k, List<String>.from(v))));
    } else if (widget.user.permissions.isNotEmpty) {
      _currentPermissions = Map<String, List<String>>.from(
          widget.user.permissions.map((k, v) => MapEntry(k, List<String>.from(v))));
    } else {
      _currentPermissions = _defaultPermissions();
    }

    _fetchRoles();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRoles() async {
    final urls = [
      'http://125.209.66.147:5001/api/roles/with-permissions?page=0&size=100',
      'http://125.209.66.147:5001/api/roles/with-permissions?page=1&size=100',
      'http://125.209.66.147:5001/api/roles/with-permissions',
      'http://125.209.66.147:5001/api/roles',
    ];
    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };
    for (final urlStr in urls) {
      try {
        final res = await http
            .get(Uri.parse(urlStr), headers: headers)
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 304 || res.statusCode == 204 || res.body.trim().isEmpty) continue;
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> raw = [];
          if (decoded is List) {
            raw = decoded;
          } else if (decoded is Map) {
            for (final key in ['data', 'roles', 'content', 'items']) {
              if (decoded[key] is List) { raw = decoded[key] as List<dynamic>; break; }
            }
          }
          if (raw.isEmpty) continue;
          final roles = raw.map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
          if (mounted) {
            setState(() {
              _availableRoles = roles;
              _rolesLoading = false;
            });
          }
          return;
        }
      } catch (_) { continue; }
    }
    if (mounted) {
      setState(() {
        _rolesLoading = false;
        _rolesError = 'Could not load roles';
      });
    }
  }

  void _addPermission() {
    if (_selectedFeature == null || _selectedActions.isEmpty) return;
    setState(() {
      final existing = List<String>.from(_currentPermissions[_selectedFeature!] ?? []);
      for (final a in _selectedActions) {
        if (!existing.contains(a)) existing.add(a);
      }
      _currentPermissions[_selectedFeature!] = existing;
      _selectedFeature = null;
      _selectedActions = [];
    });
  }

  void _removeFeature(String key) {
    setState(() => _currentPermissions.remove(key));
  }

  int _resolvedRoleId() {
    if (widget.user.roleId != 0) return widget.user.roleId;
    if (_availableRoles.isNotEmpty) {
      try {
        final match = _availableRoles.firstWhere(
          (r) => r.name.toLowerCase().trim() == widget.user.role.toLowerCase().trim(),
        );
        if (match.id != 0) return match.id;
      } catch (_) {}
      if (_availableRoles.first.id != 0) return _availableRoles.first.id;
    }
    return widget.user.id;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Role name is required');
      return;
    }
    final roleId = _resolvedRoleId();
    setState(() => _isSaving = true);
    final body = jsonEncode({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'permissions': _currentPermissions,
    });
    try {
      final res = await http
          .put(
            Uri.parse('http://125.209.66.147:5001/api/roles/$roleId'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        // FIX: Successful save par bhi current permissions return karo (cache update ke liye)
        if (mounted) Navigator.pop(context, Map<String, List<String>>.from(_currentPermissions));
      } else {
        _showSnack('Update failed (${res.statusCode}) — role ID: $roleId');
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showSnack('Network error: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // FIX: Close (cancel/cross) par bhi current permissions return karo
  // Taake parent cache update kar sake aur dobara kholne par same state mile
  void _close() {
    _ctrl.reverse().then((_) {
      if (mounted) {
        // Current permissions return karo — chahe user ne save kiya ya nahi
        Navigator.pop(context, Map<String, List<String>>.from(_currentPermissions));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(controller: _nameCtrl, label: 'Role Name *', hint: 'Enter role name'),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _descCtrl, label: 'Description',
                        hint: 'Enter description', minLines: 3, maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      _buildPermissionsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 20, color: _C.ink),
          const SizedBox(width: 10),
          const Text('Edit Role',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.ink, letterSpacing: -0.3)),
          const Spacer(),
          GestureDetector(
            onTap: _close,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.bg, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.border, width: 1.1),
              ),
              child: const Icon(Icons.close_rounded, size: 17, color: _C.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _C.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 12, color: _C.muted),
        hintStyle: const TextStyle(fontSize: 13, color: _C.muted),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _C.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.blueText, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border.all(color: _C.border, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Permissions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.ink)),
          ),
          const Divider(height: 1, thickness: 1, color: _C.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildAddRow(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _C.border),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Current Permissions ($_totalPermissions)',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _C.ink)),
          ),
          const SizedBox(height: 10),
          if (_currentPermissions.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text('No permissions added yet.',
                  style: TextStyle(fontSize: 13, color: _C.muted)),
            )
          else
            ..._currentPermissions.entries.map((e) => _buildPermissionRow(e.key, e.value)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildAddRow() {
    final features = _rolesLoading
        ? _allFeatures
        : (_availableRoles.isNotEmpty
            ? _availableRoles.expand((r) => r.permissions.keys).toSet().toList()
            : _allFeatures);

    List<String> availableActions = _allActions;
    if (_selectedFeature != null && _availableRoles.isNotEmpty) {
      for (final r in _availableRoles) {
        if (r.permissions.containsKey(_selectedFeature)) {
          availableActions = r.permissions[_selectedFeature]!;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border, width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFeature,
                    hint: const Text('Feature *', style: TextStyle(fontSize: 13, color: _C.muted)),
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: _C.muted),
                    style: const TextStyle(fontSize: 13, color: _C.ink, fontWeight: FontWeight.w500),
                    borderRadius: BorderRadius.circular(10),
                    items: features
                        .map((f) => DropdownMenuItem(value: f, child: Text(_toLabel(f))))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedFeature = v;
                      _selectedActions = [];
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_selectedFeature != null && _selectedActions.isNotEmpty) ? _addPermission : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: (_selectedFeature != null && _selectedActions.isNotEmpty)
                      ? _C.blueText
                      : const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16,
                        color: (_selectedFeature != null && _selectedActions.isNotEmpty)
                            ? Colors.white : _C.muted),
                    const SizedBox(width: 5),
                    Text('ADD',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          color: (_selectedFeature != null && _selectedActions.isNotEmpty)
                              ? Colors.white : _C.muted,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_selectedFeature != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: availableActions.map((action) {
              final checked = _selectedActions.contains(action);
              return GestureDetector(
                onTap: () => setState(() {
                  checked ? _selectedActions.remove(action) : _selectedActions.add(action);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: checked ? _C.blueText.withOpacity(0.10) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: checked ? _C.blueText.withOpacity(0.5) : _C.border, width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 15, color: checked ? _C.blueText : _C.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(_cap(action),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: checked ? _C.blueText : _C.muted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          const Text('Select Permissions *',
              style: TextStyle(fontSize: 11.5, color: _C.muted, fontWeight: FontWeight.w500)),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Select Permissions *\nPlease select a feature first',
              style: TextStyle(fontSize: 12, color: _C.muted, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildPermissionRow(String key, List<String> actions) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_toLabel(key),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.ink)),
                    const SizedBox(height: 3),
                    Text(actions.map(_cap).join(', '),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: _C.muted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _removeFeature(key),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: _C.primary),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: _C.border.withOpacity(0.7)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.3),
              ),
              child: const Text('CANCEL',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: _C.blueText, letterSpacing: 0.4)),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSaving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                color: _isSaving ? _C.blueText.withOpacity(0.5) : _C.blueText,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: _C.blueText.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('UPDATE',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}