import 'package:flutter/material.dart';
import 'package:flutter_project_1/CreateUserScreen.dart';
import 'package:flutter_project_1/EditUserScreen.dart';
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
}

// ─── Model ────────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '-',
      email: json['email'] ?? '-',
      role: json['role'] is Map
          ? (json['role']['name'] ?? json['role']['roleName'] ?? '-')
          : (json['role'] ?? json['roleName'] ?? '-'),
      createdAt: json['created_at'] ?? json['createdAt'] ?? '-',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
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
  List<UserModel> allUsers = [];   // full list from API
  List<UserModel> users = [];      // current page slice
  bool isLoading = true;
  String? errorMessage;

  // ── Pagination ──────────────────────────────────────────────────────────────
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3ODA5MTgzMCwiZXhwIjoxNzc4Njk2NjMwfQ.BnqGBNP7hsNesCzOvuim1t1MfvJzrHSZkExIf6M_zYg";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
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

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final urlsToTry = [
      "http://125.209.66.147:5001/api/users?page=1&size=100",
      "http://125.209.66.147:5001/api/users?page=0&size=100",
      "http://125.209.66.147:5001/api/users",
    ];

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    for (final urlStr in urlsToTry) {
      try {
        final url = Uri.parse(urlStr);
        final response = await http.get(url, headers: headers);

        print("── STATUS: ${response.statusCode} | $urlStr");
        print("   BODY: ${response.body}");

        // 304 = server cached, body will be empty — skip to next url
        // 204 = no content — skip
        if (response.statusCode == 204 ||
            response.statusCode == 304 ||
            response.body.trim().isEmpty) {
          print("   → Skipping (no usable body)");
          continue;
        }

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);
          List<dynamic> rawList = [];

          if (decoded is List) {
            rawList = decoded;
          } else if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              rawList = decoded['data'];
            } else if (decoded.containsKey('users') && decoded['users'] is List) {
              rawList = decoded['users'];
            } else if (decoded.containsKey('content') && decoded['content'] is List) {
              rawList = decoded['content'];
            } else if (decoded.containsKey('items') && decoded['items'] is List) {
              rawList = decoded['items'];
            } else {
              setState(() {
                errorMessage =
                    "Unexpected response format. Keys: ${decoded.keys.toList()}";
                isLoading = false;
              });
              return;
            }
          }

          if (rawList.isEmpty) {
            print("   → List empty, trying next url...");
            continue;
          }

          setState(() {
            allUsers = rawList
                .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                .toList();
            isLoading = false;
          });
          _currentPage = 1;
          _applyPagination();
          print("   ✅ Loaded ${rawList.length} users");
          return;
        }
      } catch (e) {
        print("   ❌ Exception: $e");
        continue;
      }
    }

    setState(() {
      isLoading = false;
      errorMessage = "No data found. Check console for details.";
    });
  }

  // ── Slice allUsers into current page ──────────────────────────────────────
  void _applyPagination() {
    final total = allUsers.length;
    _totalPages = (total / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;

    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    setState(() {
      users = allUsers.sublist(start, end);
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
    _applyPagination();
  }

  // ── Open EditUserScreen and refresh list if saved ──────────────────────────
  void _openEditScreen(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserScreen(
          userId: user.id,
          initialUsername: user.username,
          initialEmail: user.email,
          initialRole: user.role,
          initialIsActive: user.isActive,
        ),
      ),
    );
    if (result == true) {
      // Small delay so server finishes writing before we fetch fresh data
      await Future.delayed(const Duration(milliseconds: 400));
      fetchUsers();
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
                  // Page heading
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

                  // Error banner
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

                  // Table Container
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
                          // Header Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            color: _C.headerBg,
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 1,
                                    child: _HeaderCell(label: "ID")),
                                Expanded(
                                    flex: 2,
                                    child: _HeaderCell(label: "Username")),
                                Expanded(
                                    flex: 3,
                                    child: _HeaderCell(label: "Email")),
                                Expanded(
                                    flex: 2,
                                    child: _HeaderCell(label: "Role")),
                                Expanded(
                                    flex: 2,
                                    child: _HeaderCell(label: "Status")),
                                Expanded(
                                    flex: 3,
                                    child: _HeaderCell(label: "Created At")),
                                Expanded(
                                    flex: 2,
                                    child: _HeaderCell(label: "Actions")),
                              ],
                            ),
                          ),
                          Container(height: 1, color: _C.border),

                          // Rows
                          if (isLoading)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 40),
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
                                    if (index != users.length - 1)
                                      _divider(),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Pagination Footer ─────────────────────────────────
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

  // ── Data row: passes a plain VoidCallback to ActionButtons ─────────────────
  Widget _buildRow(UserModel user) {
    return _HoverableRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                user.id.toString(),
                style: const TextStyle(
                    fontSize: 13,
                    color: _C.muted,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.username,
                style: const TextStyle(
                    fontSize: 13,
                    color: _C.ink,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                user.email,
                style: const TextStyle(
                    fontSize: 13,
                    color: _C.muted,
                    fontWeight: FontWeight.w400),
              ),
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
              child: Text(
                user.createdAt,
                style: const TextStyle(
                    fontSize: 12,
                    color: _C.muted,
                    fontWeight: FontWeight.w400),
              ),
            ),
            Expanded(
              flex: 2,
              child: ActionButtons(
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
            Expanded(
                flex: 1,
                child: Text("-",
                    style:
                        const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(
                flex: 2,
                child: Text("-",
                    style:
                        const TextStyle(fontSize: 13, color: _C.muted))),
            Expanded(
                flex: 3,
                child: Text("-",
                    style:
                        const TextStyle(fontSize: 13, color: _C.muted))),
            const Expanded(flex: 2, child: _RoleChip(role: "Role")),
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: _StatusChip(isActive: true),
              ),
            ),
            Expanded(
                flex: 3,
                child: Text("-",
                    style:
                        const TextStyle(fontSize: 12, color: _C.muted))),
            const Expanded(
              flex: 2,
              child: ActionButtons(onEditTap: null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(height: 1, color: _C.border.withOpacity(0.7));
}

// ─── Header Cell ──────────────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _C.muted,
        letterSpacing: 0.7,
      ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        style: const TextStyle(
          color: _C.blueText,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
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
// Accepts a single nullable VoidCallback for the edit action.
// Navigation logic lives in _UserManagementScreenState._openEditScreen().
class ActionButtons extends StatelessWidget {
  final VoidCallback? onEditTap;
  const ActionButtons({super.key, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.visibility_outlined,
          color: _C.muted,
          hoverColor: _C.muted,
          onTap: () {},
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

  // Build the list of page numbers to show (Google-style with ...)
  List<int?> _buildPageNumbers() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[];
    pages.add(1);
    if (currentPage > 4) pages.add(null); // left ellipsis

    final start = (currentPage - 2).clamp(2, totalPages - 1);
    final end   = (currentPage + 2).clamp(2, totalPages - 1);
    for (int i = start; i <= end; i++) pages.add(i);

    if (currentPage < totalPages - 3) pages.add(null); // right ellipsis
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: info + page size picker ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "Showing 1–10 of 47 users"
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 12.5, color: _C.muted, fontWeight: FontWeight.w400),
                  children: [
                    const TextSpan(text: "Showing "),
                    TextSpan(
                      text: "$startItem–$endItem",
                      style: const TextStyle(
                          color: _C.ink, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: " of "),
                    TextSpan(
                      text: "$totalItems",
                      style: const TextStyle(
                          color: _C.ink, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: " users"),
                  ],
                ),
              ),

              // Rows per page picker
              Row(
                children: [
                  const Text(
                    "Rows:",
                    style: TextStyle(
                        fontSize: 12, color: _C.muted, fontWeight: FontWeight.w500),
                  ),
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
                                  value: s,
                                  child: Text("$s"),
                                ))
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

          // ── Bottom row: prev + page numbers + next ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ← Prev
              _PageBtn(
                label: "←",
                isDisabled: currentPage == 1,
                isActive: false,
                onTap: () => onPageChanged(currentPage - 1),
              ),

              const SizedBox(width: 4),

              // Page number buttons
              ...pageNums.map((p) {
                if (p == null) {
                  // Ellipsis
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
                  onTap: () => onPageChanged(p),
                );
              }),

              const SizedBox(width: 4),

              // → Next
              _PageBtn(
                label: "→",
                isDisabled: currentPage == totalPages,
                isActive: false,
                onTap: () => onPageChanged(currentPage + 1),
              ),
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
    Color bgColor = Colors.transparent;
    Color textColor = _C.muted;
    Color borderColor = Colors.transparent;

    if (widget.isActive) {
      bgColor     = _C.primary;
      textColor   = Colors.white;
      borderColor = _C.primary;
    } else if (_hovered && !widget.isDisabled) {
      bgColor     = _C.chip;
      textColor   = _C.primary;
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
                fontWeight:
                    widget.isActive ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}