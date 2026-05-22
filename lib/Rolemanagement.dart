import 'package:flutter/material.dart';

// ─── NOTE: AppColors is defined in main.dart. This file reuses it.
// ─── Ensure this file is imported alongside main.dart in your project.

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

// ─── Colour Palette (mirrors main.dart AppColors exactly) ────────────────────
class AppColors {
  static const bg         = Color(0xFFF5F7FA);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F9);
  static const primary    = Color(0xFF1A2B4A);
  static const primaryMid = Color(0xFF243B5E);
  static const accent     = Color(0xFF3B7DD8);
  static const accentLight= Color(0xFFEBF3FF);
  static const red        = Color(0xFFE53935);
  static const redLight   = Color(0xFFFFEBEE);
  static const warning    = Color(0xFFF57F17);
  static const warningLight=Color(0xFFFFF8E1);
  static const success    = Color(0xFF26A69A);
  static const purple     = Color(0xFF5C35B5);
  static const purpleLight= Color(0xFFEFEBFA);
  static const textHead   = Color(0xFF1A2B4A);
  static const textBody   = Color(0xFF3A4A5C);
  static const textMuted  = Color(0xFF8A9BB5);
  static const border     = Color(0xFFE2E8F0);
  static const divider    = Color(0xFFEDF2F7);
}

// ─── Role Management Screen ───────────────────────────────────────────────────
class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _rowsPerPage = 10;
  int _currentPage = 0;

  final List<RoleModel> _allRoles = [
    RoleModel(id: 1,  roleName: 'Super Admin',         description: 'Full system access and control over all modules',        createdAt: '11/11/2025\n23:45:48'),
    RoleModel(id: 6,  roleName: 'Marketing Manager',   description: 'This role is for marketing managers with limited access', createdAt: '11/11/2025\n23:57:24'),
    RoleModel(id: 7,  roleName: 'Auditor',             description: 'This role is for auditor only with read access',          createdAt: '11/11/2025\n23:59:45'),
    RoleModel(id: 8,  roleName: 'Marketing Executive', description: 'This role is only for marketing executives',              createdAt: '12/11/2025\n00:00:51'),
    RoleModel(id: 9,  roleName: 'User',                description: 'This is the user role with basic permissions',            createdAt: '12/11/2025\n22:17:05'),
    RoleModel(id: 10, roleName: 'Area Sales Head',     description: 'This is the role for area sales heads',                  createdAt: '16/11/2025\n21:10:34'),
    RoleModel(id: 11, roleName: 'Vendor',              description: 'This role is for vendors with limited portal access',     createdAt: '21/11/2025\n01:46:10'),
    RoleModel(id: 12, roleName: 'Finance',             description: 'This role is reserved for finance department',            createdAt: '22/11/2025\n12:45:12'),
    RoleModel(id: 13, roleName: 'Test Role',           description: '',                                                        createdAt: '11/05/2026\n21:08:14'),
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

  // ─── Snackbar ─────────────────────────────────────────────────────────────
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

  // ─── Shared Input Decoration ──────────────────────────────────────────────
  InputDecoration _inputDec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 17),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border, width: 0.8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border, width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.red, width: 1.4)),
      );

  // ─── Delete Dialog ────────────────────────────────────────────────────────
  void _showDeleteDialog(RoleModel role) {
    showDialog(
      context: context,
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
            child: const Icon(Icons.delete_rounded,
                color: AppColors.red, size: 20),
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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── Header ───────────────────────────────────────────────────
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Role Details',
                        style: TextStyle(
                            color: AppColors.textHead,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text('ID: ${role.id}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ),
                _CloseBtn(onTap: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // ── Fields ───────────────────────────────────────────────────
              _ViewField(label: 'Role ID',     value: '${role.id}',                          icon: Icons.tag_rounded),
              const SizedBox(height: 10),
              _ViewField(label: 'Role Name',   value: role.roleName,                         icon: Icons.shield_rounded),
              const SizedBox(height: 10),
              _ViewField(label: 'Description', value: role.description.isEmpty ? '—' : role.description, icon: Icons.description_rounded, multiline: true),
              const SizedBox(height: 10),
              _ViewField(label: 'Created At',  value: role.createdAt.replaceAll('\n', '  '), icon: Icons.calendar_today_rounded),
              const SizedBox(height: 22),

              // ── Close Button — navy like the dashboard primary ────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Edit Dialog ──────────────────────────────────────────────────────────
  void _showEditDialog(RoleModel role) {
    final nameCtrl = TextEditingController(text: role.roleName);
    final descCtrl = TextEditingController(text: role.description);
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // ── Header ─────────────────────────────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Edit Role',
                          style: TextStyle(
                              color: AppColors.textHead,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text('ID: ${role.id}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ]),
                  ),
                  _CloseBtn(onTap: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                const _FormLabel(label: 'Role Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Role name is required'
                      : null,
                  decoration: _inputDec(
                      hint: 'Enter role name', icon: Icons.shield_rounded),
                  style: const TextStyle(color: AppColors.textHead, fontSize: 13.5),
                ),
                const SizedBox(height: 14),

                const _FormLabel(label: 'Description'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _inputDec(
                      hint: 'Enter role description',
                      icon: Icons.description_rounded),
                  style: const TextStyle(color: AppColors.textHead, fontSize: 13.5),
                ),
                const SizedBox(height: 22),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            role.roleName    = nameCtrl.text.trim();
                            role.description = descCtrl.text.trim();
                          });
                          Navigator.pop(ctx);
                          _snack('Role "${role.roleName}" updated', AppColors.success);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Create Dialog ────────────────────────────────────────────────────────
  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // ── Header — gradient icon matching dashboard banner style ──
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.add_moderator_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Create Role',
                          style: TextStyle(
                              color: AppColors.textHead,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text('Add a new system role',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ]),
                  ),
                  _CloseBtn(onTap: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                const _FormLabel(label: 'Role Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Role name is required'
                      : null,
                  decoration: _inputDec(
                      hint: 'e.g. Sales Manager', icon: Icons.shield_rounded),
                  style: const TextStyle(color: AppColors.textHead, fontSize: 13.5),
                ),
                const SizedBox(height: 14),

                const _FormLabel(label: 'Description'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _inputDec(
                      hint: 'Describe what this role can do...',
                      icon: Icons.description_rounded),
                  style: const TextStyle(color: AppColors.textHead, fontSize: 13.5),
                ),
                const SizedBox(height: 22),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Create Role',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ),
                ]),
              ]),
            ),
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

                  // ── Page Header — mirrors dashboard section header style ──
                  Row(children: [
                    const Text('Role Management',
                        style: TextStyle(
                            color: AppColors.textHead,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    // Refresh — matches dashboard icon button style
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
                    const SizedBox(width: 8),
                    // CREATE — accent blue, matches dashboard CTA style
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
                  ]),
                  const SizedBox(height: 16),

                  // ── Summary Strip — mimics the _StatsRow cards ────────────
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

                  // ── Table Card ────────────────────────────────────────────
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

                      // ── Table toolbar ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Row(children: [
                          // Section label
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

                      // ── Column Headers ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                          border: Border(
                              top: BorderSide(color: AppColors.divider, width: 1),
                              bottom: BorderSide(color: AppColors.divider, width: 1)),
                        ),
                        child: const Row(children: [
                          _ColHeader(text: 'ID',   flex: 1),
                          _ColHeader(text: 'Name', flex: 3),
                          _ColHeader(text: 'Desc', flex: 3),
                          _ColHeader(text: 'Date', flex: 2),
                          _ColHeader(text: 'Actions', flex: 3, alignRight: true),
                        ]),
                      ),

                      // ── Data Rows ─────────────────────────────────────────
                      ..._pagedRoles.asMap().entries.map((e) {
                        return _RoleRow(
                          role: e.value,
                          isEven: e.key % 2 == 0,
                          trunc: _trunc,
                          onView:   () => _showViewDialog(e.value),
                          onEdit:   () => _showEditDialog(e.value),
                          onDelete: () => _showDeleteDialog(e.value),
                        );
                      }),

                      // ── Pagination Footer ─────────────────────────────────
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

  // ─── Top Bar — matches dashboard TopBar exactly ───────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        // Back button — same style as dashboard _IconBtn
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
        // Logo — identical to dashboard diamond circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(
                  color: AppColors.primaryMid.withOpacity(0.4), width: 1)),
          child: const Icon(Icons.diamond, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        // Title stack — same font/size as dashboard top bar
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
        // Purple role count badge — matches dashboard stat badge pattern
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

// ─── Mini Stat Card (matches _StatCard from dashboard) ───────────────────────
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
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleRow({
    required this.role,
    required this.isEven,
    required this.trunc,
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
            // Role Name
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
            // Date — single line, newline replaced with space
            Expanded(
              flex: 2,
              child: Text(
                widget.role.createdAt.replaceAll('\n', ' '),
                style: const TextStyle(color: AppColors.textBody, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Actions
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconBtn(
                    icon: Icons.remove_red_eye_outlined,
                    color: AppColors.textMuted,
                    bg: AppColors.surfaceAlt,
                    onTap: widget.onView,
                  ),
                  const SizedBox(width: 5),
                  _ActionIconBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    bg: AppColors.accentLight,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 5),
                  _ActionIconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    bg: AppColors.redLight,
                    onTap: widget.onDelete,
                  ),
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

/// Column header — uses AppColors constants
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

/// Action icon button — scale animation matching _ActionTile in dashboard
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

/// Toolbar icon button — matches dashboard _IconBtn surfaceAlt style
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

/// Pagination button
class _PagBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PagBtn({required this.icon, required this.enabled, required this.onTap});

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

/// Close button used in dialogs
class _CloseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.7)),
        child: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
      ),
    );
  }
}

// ─── View Field ───────────────────────────────────────────────────────────────
class _ViewField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool multiline;
  const _ViewField({
    required this.label,
    required this.value,
    required this.icon,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Form Label ───────────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textHead,
            fontSize: 12.5,
            fontWeight: FontWeight.w700));
  }
}