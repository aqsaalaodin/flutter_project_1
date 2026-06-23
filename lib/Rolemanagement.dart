import 'package:flutter/material.dart';

// ─── Role Model ───────────────────────────────────────────────────────────────
class RoleModel {
  final int id;
  String roleName;
  String description;
  final String createdAt;

  RoleModel({
    required this.id,
    required this.roleName,
    required this.description,
    required this.createdAt,
  });
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

// ═══════════════════════════════════════════════════════════════════════════════
// ─── PERMISSION MODEL ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════
//
// ✅ RoleMgmtPermissions — Dashboard se aane wali permissions yahan map hoti hain.
//
// Dashboard (dashboardscreen.dart) mein UserPermissions class hai jo Map-based hai.
// Yeh class bool-based hai aur RoleManagementScreen use karta hai.
//
// Dashboard se pass karne ka tarika:
//   RoleManagementScreen(
//     permissions: RoleMgmtPermissions(
//       canViewRoles:   p.canRead('role'),
//       canEditRoles:   p.canUpdate('role'),
//       canDeleteRoles: p.canDelete('role'),
//       canCreateRoles: p.canCreate('role'),
//     ),
//   )

class RoleMgmtPermissions {
  final bool canViewRoles;
  final bool canEditRoles;
  final bool canDeleteRoles;
  final bool canCreateRoles;

  const RoleMgmtPermissions({
    required this.canViewRoles,
    required this.canEditRoles,
    required this.canDeleteRoles,
    required this.canCreateRoles,
  });

  /// Login API response ka "data" object pass karein
  /// Shape: { "permissions": { "role": ["read","create","update","delete"] } }
  factory RoleMgmtPermissions.fromLoginResponse(Map<String, dynamic> data) {
    final permsMap  = data['permissions'] as Map<String, dynamic>? ?? {};
    final roleList  = List<String>.from(permsMap['role'] ?? []);
    return RoleMgmtPermissions(
      canViewRoles:   roleList.contains('read'),
      canEditRoles:   roleList.contains('update'),
      canDeleteRoles: roleList.contains('delete'),
      canCreateRoles: roleList.contains('create'),
    );
  }

  /// Koi permission nahi
  const RoleMgmtPermissions.none()
      : canViewRoles   = false,
        canEditRoles   = false,
        canDeleteRoles = false,
        canCreateRoles = false;

  /// Sab permissions
  const RoleMgmtPermissions.all()
      : canViewRoles   = true,
        canEditRoles   = true,
        canDeleteRoles = true,
        canCreateRoles = true;

  bool get hasAnyAction => canViewRoles || canEditRoles || canDeleteRoles;
}

// Backward compat alias — purana naam bhi kaam kare
typedef UserPermissions = RoleMgmtPermissions;

// ─── Role Management Screen ───────────────────────────────────────────────────
class RoleManagementScreen extends StatefulWidget {
  // Dashboard se pass karo:
  //   RoleManagementScreen(
  //     permissions: RoleMgmtPermissions(
  //       canViewRoles:   p.canRead('role'),
  //       canEditRoles:   p.canUpdate('role'),
  //       canDeleteRoles: p.canDelete('role'),
  //       canCreateRoles: p.canCreate('role'),
  //     ),
  //   )
  final RoleMgmtPermissions permissions;

  const RoleManagementScreen({
    super.key,
    this.permissions = const RoleMgmtPermissions.none(),
  });

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _rowsPerPage = 10;
  int _currentPage = 0;

  // Shorthand getters for cleaner code
  bool get _canView   => widget.permissions.canViewRoles;
  bool get _canEdit   => widget.permissions.canEditRoles;
  bool get _canDelete => widget.permissions.canDeleteRoles;
  bool get _canCreate => widget.permissions.canCreateRoles;
  bool get _hasActions => widget.permissions.hasAnyAction;

  final List<RoleModel> _allRoles = [
    RoleModel(id: 1,  roleName: 'Super Admin',         description: 'Full system access and control over all modules',         createdAt: '11/11/2025\n23:45:48'),
    RoleModel(id: 6,  roleName: 'Marketing Manager',   description: 'This role is for marketing managers with limited access',  createdAt: '11/11/2025\n23:57:24'),
    RoleModel(id: 7,  roleName: 'Auditor',             description: 'This role is for auditor only with read access',           createdAt: '11/11/2025\n23:59:45'),
    RoleModel(id: 8,  roleName: 'Marketing Executive', description: 'This role is only for marketing executives',               createdAt: '12/11/2025\n00:00:51'),
    RoleModel(id: 9,  roleName: 'User',                description: 'This is the user role with basic permissions',             createdAt: '12/11/2025\n22:17:05'),
    RoleModel(id: 10, roleName: 'Area Sales Head',     description: 'This is the role for area sales heads',                   createdAt: '16/11/2025\n21:10:34'),
    RoleModel(id: 11, roleName: 'Vendor',              description: 'This role is for vendors with limited portal access',      createdAt: '21/11/2025\n01:46:10'),
    RoleModel(id: 12, roleName: 'Finance',             description: 'This role is reserved for finance department',             createdAt: '22/11/2025\n12:45:12'),
    RoleModel(id: 13, roleName: 'Test Role',           description: '',                                                         createdAt: '11/05/2026\n21:08:14'),
  ];

  List<RoleModel> get _pagedRoles {
    final start = _currentPage * _rowsPerPage;
    final end   = (start + _rowsPerPage).clamp(0, _allRoles.length);
    return _allRoles.sublist(start, end);
  }

  int get _totalPages => (_allRoles.length / _rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _trunc(String text, {int max = 18}) =>
      text.isEmpty ? '' : (text.length > max ? '${text.substring(0, max)}...' : text);

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Delete Dialog ────────────────────────────────────────────────────────
  void _showDeleteDialog(RoleModel role) {
    if (!_canDelete) return; // Guard — should not reach here anyway
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.delete_rounded, color: AppColors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Delete Role',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textBody, fontSize: 13.5, height: 1.55),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                  text: '"${role.roleName}"',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.red)),
              const TextSpan(text: '?\nThis action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final name = role.roleName;
                  setState(() => _allRoles.removeWhere((r) => r.id == role.id));
                  Navigator.pop(context);
                  _snack('Role "$name" deleted', AppColors.red);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── View Dialog ──────────────────────────────────────────────────────────
  void _showViewDialog(RoleModel role) {
    if (!_canView) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 520,
          ),
          child: _ViewRoleDialogContent(role: role),
        ),
      ),
    );
  }

  // ─── Edit Dialog ──────────────────────────────────────────────────────────
  void _showEditDialog(RoleModel role) {
    if (!_canEdit) return;
    final nameCtrl = TextEditingController(text: role.roleName);
    final descCtrl = TextEditingController(text: role.description);
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 520,
          ),
          child: _EditRoleDialogContent(
            role: role,
            nameCtrl: nameCtrl,
            descCtrl: descCtrl,
            formKey: formKey,
            onSave: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  role.roleName    = nameCtrl.text.trim();
                  role.description = descCtrl.text.trim();
                });
                Navigator.pop(ctx);
                _snack('Role "${role.roleName}" updated', AppColors.success);
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── Create Dialog ────────────────────────────────────────────────────────
  void _showCreateDialog() {
    if (!_canCreate) return;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 520,
          ),
          child: _CreateRoleDialogContent(
            nameCtrl: nameCtrl,
            descCtrl: descCtrl,
            formKey: formKey,
            onCreate: () {
              if (formKey.currentState!.validate()) {
                final newId = _allRoles.isEmpty
                    ? 1
                    : _allRoles.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
                final now = DateTime.now();
                String p(int n) => n.toString().padLeft(2, '0');
                final ds =
                    '${p(now.day)}/${p(now.month)}/${now.year}\n${p(now.hour)}:${p(now.minute)}:${p(now.second)}';
                setState(() {
                  _allRoles.add(RoleModel(
                    id: newId,
                    roleName: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    createdAt: ds,
                  ));
                });
                Navigator.pop(ctx);
                _snack('Role "${nameCtrl.text.trim()}" created', AppColors.success);
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Text('Role Management',
                        style: TextStyle(
                            color: AppColors.textHead,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.7),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: AppColors.textMuted, size: 19),
                      ),
                    ),
                    // ── CREATE button: sirf tab dikhega jab canCreate == true ──
                    if (_canCreate) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showCreateDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accent.withOpacity(0.30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Row(children: [
                            Icon(Icons.add, color: Colors.white, size: 17),
                            SizedBox(width: 5),
                            Text('CREATE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  Row(children: [
                    _MiniStatCard(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Total Roles',
                      value: '${_allRoles.length}',
                      iconColor: AppColors.purple,
                      iconBg: AppColors.purpleLight,
                    ),
                    const SizedBox(width: 10),
                    const _MiniStatCard(
                      icon: Icons.verified_user_rounded,
                      label: 'Active',
                      value: 'All',
                      iconColor: AppColors.success,
                      iconBg: Color(0xFFE0F2F1),
                    ),
                    const SizedBox(width: 10),
                    const _MiniStatCard(
                      icon: Icons.lock_rounded,
                      label: 'System',
                      value: '1',
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warningLight,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.7),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Row(children: [
                          const Icon(Icons.table_rows_rounded,
                              color: AppColors.textMuted, size: 15),
                          const SizedBox(width: 6),
                          const Text('All Roles',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _ToolbarIconBtn(icon: Icons.view_column_rounded),
                          const SizedBox(width: 7),
                          _ToolbarIconBtn(icon: Icons.filter_list_rounded),
                          const SizedBox(width: 7),
                          _ToolbarIconBtn(icon: Icons.download_rounded),
                        ]),
                      ),
                      // ── Table Header ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                          border: Border(
                              top: BorderSide(color: AppColors.divider, width: 1),
                              bottom: BorderSide(color: AppColors.divider, width: 1)),
                        ),
                        child: Row(children: [
                          const _ColHeader(text: 'ID',   flex: 1),
                          const _ColHeader(text: 'Name', flex: 3),
                          const _ColHeader(text: 'Desc', flex: 3),
                          const _ColHeader(text: 'Date', flex: 2),
                          // ── Actions column: sirf tab dikhao jab koi bhi permission ho ──
                          if (_hasActions)
                            const _ColHeader(text: 'Actions', flex: 3, alignRight: true),
                        ]),
                      ),
                      // ── Rows ───────────────────────────────────────────
                      ..._pagedRoles.asMap().entries.map((e) {
                        return _RoleRow(
                          role: e.value,
                          isEven: e.key % 2 == 0,
                          trunc: _trunc,
                          // Permission flags — individually pass karo
                          canView:   _canView,
                          canEdit:   _canEdit,
                          canDelete: _canDelete,
                          hasActions: _hasActions,
                          onView:   () => _showViewDialog(e.value),
                          onEdit:   () => _showEditDialog(e.value),
                          onDelete: () => _showDeleteDialog(e.value),
                        );
                      }),
                      // ── Pagination ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppColors.divider, width: 1)),
                        ),
                        child: Row(children: [
                          const Text('Rows:',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _rowsPerPage,
                                isDense: true,
                                style: const TextStyle(
                                    color: AppColors.textBody,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                                items: [5, 10, 25, 50]
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: Text('$v')))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _rowsPerPage = v!;
                                  _currentPage = 0;
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_currentPage * _rowsPerPage + 1}–'
                            '${(_currentPage * _rowsPerPage + _pagedRoles.length)} '
                            'of ${_allRoles.length}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                          const Spacer(),
                          _PagBtn(
                              icon: Icons.chevron_left,
                              enabled: _currentPage > 0,
                              onTap: () => setState(() => _currentPage--)),
                          const SizedBox(width: 4),
                          _PagBtn(
                              icon: Icons.chevron_right,
                              enabled: _currentPage < _totalPages - 1,
                              onTap: () => setState(() => _currentPage++)),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.7),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textHead, size: 16),
          ),
        ),
        const SizedBox(width: 11),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(
                  color: AppColors.primaryMid.withOpacity(0.4), width: 1)),
          child: const Icon(Icons.diamond, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Role Management',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
          Text('Manage system roles',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.purple, size: 13),
            const SizedBox(width: 5),
            Text('${_allRoles.length} Roles',
                style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Mini Stat Card ───────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor, iconBg;
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
          Text(value,
              style: const TextStyle(
                  color: AppColors.textHead,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Role Row ─────────────────────────────────────────────────────────────────
class _RoleRow extends StatefulWidget {
  final RoleModel role;
  final bool isEven;
  final String Function(String, {int max}) trunc;

  // ── Permission flags ──
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool hasActions; // true agar koi bhi permission ho

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleRow({
    required this.role,
    required this.isEven,
    required this.trunc,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.hasActions,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RoleRow> createState() => _RoleRowState();
}

class _RoleRowState extends State<_RoleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.accentLight.withOpacity(0.55)
              : widget.isEven
                  ? AppColors.surface
                  : AppColors.bg.withOpacity(0.6),
          border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.6)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ID
            Expanded(
              flex: 1,
              child: Text('${widget.role.id}',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                widget.trunc(widget.role.roleName, max: 14),
                style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Description
            Expanded(
              flex: 3,
              child: Tooltip(
                message: widget.role.description,
                preferBelow: true,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 11.5),
                child: Text(
                  widget.role.description.isEmpty
                      ? '—'
                      : widget.trunc(widget.role.description, max: 16),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                widget.role.createdAt.replaceAll('\n', ' '),
                style: const TextStyle(color: AppColors.textBody, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ── Actions column ────────────────────────────────────────────
            // Sirf tab dikhao jab hasActions == true
            if (widget.hasActions)
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View button — sirf tab jab canView == true
                    if (widget.canView) ...[
                      _ActionIconBtn(
                        icon: Icons.remove_red_eye_outlined,
                        color: AppColors.textMuted,
                        bg: AppColors.surfaceAlt,
                        onTap: widget.onView,
                      ),
                    ],
                    // Edit button — sirf tab jab canEdit == true
                    if (widget.canEdit) ...[
                      if (widget.canView) const SizedBox(width: 5),
                      _ActionIconBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.accent,
                        bg: AppColors.accentLight,
                        onTap: widget.onEdit,
                      ),
                    ],
                    // Delete button — sirf tab jab canDelete == true
                    if (widget.canDelete) ...[
                      if (widget.canView || widget.canEdit) const SizedBox(width: 5),
                      _ActionIconBtn(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.red,
                        bg: AppColors.redLight,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Small Widgets ─────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignRight;
  const _ColHeader(
      {required this.text, required this.flex, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      ),
    );
  }
}

class _ActionIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween(begin: 1.0, end: 0.88).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: widget.color.withOpacity(0.15), width: 0.7),
          ),
          child: Icon(widget.icon, color: widget.color, size: 14),
        ),
      ),
    );
  }
}

class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  const _ToolbarIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Icon(icon, color: AppColors.textMuted, size: 17),
    );
  }
}

class _PagBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PagBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceAlt : AppColors.divider,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.textBody : AppColors.textMuted,
            size: 17),
      ),
    );
  }
}

class _DialogCloseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DialogCloseBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: const Icon(Icons.close_rounded,
            color: AppColors.textMuted, size: 16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── View Role Dialog ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _ViewRoleDialogContent extends StatefulWidget {
  final RoleModel role;
  const _ViewRoleDialogContent({required this.role});

  @override
  State<_ViewRoleDialogContent> createState() => _ViewRoleDialogContentState();
}

class _ViewRoleDialogContentState extends State<_ViewRoleDialogContent>
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
            color: AppColors.surface,
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
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        size: 17, color: AppColors.purple),
                  ),
                  const SizedBox(width: 10),
                  const Text("View role",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHead)),
                  const Spacer(),
                  _DialogCloseBtn(onTap: _close),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.shield_rounded,
                                color: AppColors.purple, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.role.roleName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textHead)),
                              Text("ID #${widget.role.id}",
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: AppColors.divider),
                      const SizedBox(height: 16),
                      _RoleViewField(
                          label: "Role ID",
                          value: "${widget.role.id}",
                          icon: Icons.tag_rounded),
                      const SizedBox(height: 12),
                      _RoleViewField(
                          label: "Role Name",
                          value: widget.role.roleName,
                          icon: Icons.shield_rounded),
                      const SizedBox(height: 12),
                      _RoleViewField(
                          label: "Description",
                          value: widget.role.description.isEmpty
                              ? "No description provided"
                              : widget.role.description,
                          icon: Icons.description_rounded,
                          isEmpty: widget.role.description.isEmpty),
                      const SizedBox(height: 12),
                      _RoleViewField(
                          label: "Created at",
                          value: widget.role.createdAt.replaceAll('\n', '  '),
                          icon: Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  border: Border(
                      top: BorderSide(color: AppColors.border, width: 0.5)),
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: AppColors.border, width: 0.7),
                        ),
                        child: const Text("Close",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
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

class _RoleViewField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isEmpty;

  const _RoleViewField({
    required this.label,
    required this.value,
    required this.icon,
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
                color: AppColors.textMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(children: [
            Icon(icon,
                size: 15,
                color: isEmpty ? AppColors.border : AppColors.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: isEmpty ? AppColors.textMuted : AppColors.textBody,
                      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Edit Role Dialog ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _EditRoleDialogContent extends StatefulWidget {
  final RoleModel role;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;

  const _EditRoleDialogContent({
    required this.role,
    required this.nameCtrl,
    required this.descCtrl,
    required this.formKey,
    required this.onSave,
  });

  @override
  State<_EditRoleDialogContent> createState() => _EditRoleDialogContentState();
}

class _EditRoleDialogContentState extends State<_EditRoleDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  String? _errorMessage;

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

  void _trySave() {
    if (widget.nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Role name cannot be empty.");
      return;
    }
    setState(() => _errorMessage = null);
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    border: Border(
                        bottom:
                            BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 17, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Edit role",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHead)),
                        Text(
                          "ID #${widget.role.id}  ·  ${widget.role.roleName}",
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _DialogCloseBtn(onTap: _close),
                  ]),
                ),
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
                              color: AppColors.redLight,
                              border: Border.all(
                                  color: AppColors.red.withOpacity(0.2),
                                  width: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.red, size: 15),
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
                                    size: 13, color: AppColors.textMuted),
                              ),
                            ]),
                          ),
                        _RoleSectionLabel("Role information"),
                        const SizedBox(height: 12),
                        _RoleFieldLabel("Role Name"),
                        const SizedBox(height: 5),
                        _RoleInputField(
                          controller: widget.nameCtrl,
                          hint: "Enter role name",
                          icon: Icons.shield_rounded,
                        ),
                        const SizedBox(height: 12),
                        _RoleFieldLabel("Description"),
                        const SizedBox(height: 5),
                        _RoleInputField(
                          controller: widget.descCtrl,
                          hint: "Enter role description",
                          icon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _close,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: AppColors.border, width: 0.7),
                          ),
                          child: const Center(
                            child: Text("Cancel",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _trySave,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accent.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Create Role Dialog ───────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateRoleDialogContent extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final GlobalKey<FormState> formKey;
  final VoidCallback onCreate;

  const _CreateRoleDialogContent({
    required this.nameCtrl,
    required this.descCtrl,
    required this.formKey,
    required this.onCreate,
  });

  @override
  State<_CreateRoleDialogContent> createState() =>
      _CreateRoleDialogContentState();
}

class _CreateRoleDialogContentState extends State<_CreateRoleDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  String? _errorMessage;

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

  void _trySave() {
    if (widget.nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Role name cannot be empty.");
      return;
    }
    setState(() => _errorMessage = null);
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    border: Border(
                        bottom:
                            BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.add_moderator_rounded,
                          size: 17, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Create role",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHead)),
                        Text("Add a new system role",
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const Spacer(),
                    _DialogCloseBtn(onTap: _close),
                  ]),
                ),
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
                              color: AppColors.redLight,
                              border: Border.all(
                                  color: AppColors.red.withOpacity(0.2),
                                  width: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.red, size: 15),
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
                                    size: 13, color: AppColors.textMuted),
                              ),
                            ]),
                          ),
                        _RoleSectionLabel("Role information"),
                        const SizedBox(height: 12),
                        _RoleFieldLabel("Role Name"),
                        const SizedBox(height: 5),
                        _RoleInputField(
                          controller: widget.nameCtrl,
                          hint: "e.g. Sales Manager",
                          icon: Icons.shield_rounded,
                        ),
                        const SizedBox(height: 12),
                        _RoleFieldLabel("Description"),
                        const SizedBox(height: 5),
                        _RoleInputField(
                          controller: widget.descCtrl,
                          hint: "Describe what this role can do...",
                          icon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _close,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: AppColors.border, width: 0.7),
                          ),
                          child: const Center(
                            child: Text("Cancel",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _trySave,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accent.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_moderator_rounded,
                                  size: 15, color: Colors.white),
                              SizedBox(width: 5),
                              Text("Create role",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
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
      ),
    );
  }
}

// ─── Shared Form Sub-widgets ──────────────────────────────────────────────────

class _RoleSectionLabel extends StatelessWidget {
  final String label;
  const _RoleSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 12,
        decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 7),
      Text(label.toUpperCase(),
          style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.0)),
    ]);
  }
}

class _RoleFieldLabel extends StatelessWidget {
  final String label;
  const _RoleFieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody));
}

class _RoleInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _RoleInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  State<_RoleInputField> createState() => _RoleInputFieldState();
}

class _RoleInputFieldState extends State<_RoleInputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focused
                ? AppColors.accent.withOpacity(0.5)
                : AppColors.border,
            width: _focused ? 1.2 : 0.7,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textBody,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding:
                  EdgeInsets.only(bottom: widget.maxLines > 1 ? 44 : 0),
              child: Icon(widget.icon,
                  size: 17,
                  color: _focused ? AppColors.accent : AppColors.textMuted),
            ),
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
          ),
        ),
      ),
    );
  }
}