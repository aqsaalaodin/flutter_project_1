import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Design Tokens (mirrors UserManagementScreen) ────────────────────────────
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
  static const inputFill   = Color(0xFFFDFBF9);
  static const blueChip    = Color(0xFFEBF5FF);
  static const blueBorder  = Color(0xFFBDDAF7);
  static const blueText    = Color(0xFF1A6FB0);
}

class EditUserScreen extends StatefulWidget {
  final int userId;
  final String initialUsername;
  final String initialEmail;
  final String initialRole;
  final bool initialIsActive;

  const EditUserScreen({
    super.key,
    required this.userId,
    required this.initialUsername,
    required this.initialEmail,
    required this.initialRole,
    required this.initialIsActive,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;

  // ── State ────────────────────────────────────────────────────────────────────
  String? _selectedRole;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoadingRoles = false;
  bool _obscurePassword = true;
  List<Map<String, dynamic>> _roles = [];
  String? _errorMessage;
  String? _debugResponse; // shows raw API response on screen for debugging
  bool _passwordChanged = false;

  // ── Animations ───────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Token ────────────────────────────────────────────────────────────────────
  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3ODUwMDEyNywiZXhwIjoxNzc5MTA0OTI3fQ.fYDaxlSNiXIqvXjvoazBJu5TQ-NFhm2gC6G_oc_J5O8";

  Map<String, String> get _headers => {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

  @override
  void initState() {
    super.initState();

    _usernameCtrl = TextEditingController(text: widget.initialUsername);
    _emailCtrl    = TextEditingController(text: widget.initialEmail);
    _passwordCtrl = TextEditingController();
    _isActive     = widget.initialIsActive;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _fetchRoles();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch roles from API ─────────────────────────────────────────────────────
  Future<void> _fetchRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final response = await http.get(
        Uri.parse("http://125.209.66.147:5001/api/roles"),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = decoded['data'] ?? decoded['roles'] ?? decoded['content'] ?? [];
        }
        setState(() {
          _roles = rawList
              .map<Map<String, dynamic>>((e) => {
                    'id': e['id'] ?? e['roleId'],
                    'name': e['name'] ?? e['roleName'] ?? e['role_name'] ?? '-',
                  })
              .toList();

          // Match pre-selected role
          final match = _roles.firstWhere(
            (r) =>
                r['name'].toString().toLowerCase() ==
                widget.initialRole.toLowerCase(),
            orElse: () => _roles.isNotEmpty ? _roles.first : {'name': widget.initialRole},
          );
          _selectedRole = match['name'].toString();
        });
      }
    } catch (_) {
      // fallback: show text input if roles can't be fetched
      setState(() => _selectedRole = widget.initialRole);
    } finally {
      setState(() => _isLoadingRoles = false);
    }
  }

  // ── Save / PUT ───────────────────────────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (_usernameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Username and email cannot be empty.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Find roleId from selected role name
    final roleMatch = _roles.firstWhere(
      (r) => r['name'].toString() == _selectedRole,
      orElse: () => <String, dynamic>{},
    );
    final roleId = roleMatch['id'];

    // Build body — send every possible field name the API might expect
    final body = <String, dynamic>{
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'is_active': _isActive,
      'isActive': _isActive,
      'status': _isActive ? 'active' : 'inactive',
    };

    if (roleId != null) {
      body['roleId'] = roleId;
      body['role_id'] = roleId;
    }

    if (_passwordChanged && _passwordCtrl.text.isNotEmpty) {
      body['password'] = _passwordCtrl.text;
    }

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("PUT http://125.209.66.147:5001/api/users/${widget.userId}");
    print("Body: ${jsonEncode(body)}");

    try {
      final response = await http.put(
        Uri.parse("http://125.209.66.147:5001/api/users/${widget.userId}"),
        headers: _headers,
        body: jsonEncode(body),
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // Show on screen for debugging
      setState(() => _debugResponse =
          "Status: ${response.statusCode}\nBody: ${response.body.isEmpty ? '(empty)' : response.body}");

      // Accept any 2xx as success
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      if (isSuccess) {
        if (!mounted) return;
        _showSuccessSnackbar();
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.pop(context, true); // true = tells UserManagementScreen to refresh
      } else {
        // Show the REAL error message from server on screen
        String msg = "Update failed (HTTP ${response.statusCode})";
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
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        backgroundColor: _C.activeGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "User updated successfully!",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border, width: 1.1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _C.muted),
          ),
        ),
        titleSpacing: 4,
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
              "Edit User",
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
      ),

      // ── Body ─────────────────────────────────────────────────────────────────
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page heading ─────────────────────────────────────────────
                  Row(
                    children: [
                      // Avatar circle with initials
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _C.chip,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _C.primary.withOpacity(0.2), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            widget.initialUsername.isNotEmpty
                                ? widget.initialUsername[0].toUpperCase()
                                : "U",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _C.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edit User",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _C.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "ID #${widget.userId}  ·  ${widget.initialUsername}",
                            style: const TextStyle(
                                fontSize: 13,
                                color: _C.muted,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Error banner ─────────────────────────────────────────────
                  if (_errorMessage != null)
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
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: _C.primaryDark, fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _errorMessage = null),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: _C.muted),
                          ),
                        ],
                      ),
                    ),

                  // ── Form Card ────────────────────────────────────────────────
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section label ──────────────────────────────────────
                        _SectionLabel(label: "Account Information"),
                        const SizedBox(height: 16),

                        // Username
                        _FieldLabel(label: "Username"),
                        const SizedBox(height: 6),
                        _InputField(
                          controller: _usernameCtrl,
                          hint: "Enter username",
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 16),

                        // Email
                        _FieldLabel(label: "Email Address"),
                        const SizedBox(height: 6),
                        _InputField(
                          controller: _emailCtrl,
                          hint: "Enter email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _FieldLabel(label: "New Password"),
                        const SizedBox(height: 6),
                        _PasswordField(
                          controller: _passwordCtrl,
                          obscure: _obscurePassword,
                          onToggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          onChanged: (v) =>
                              setState(() => _passwordChanged = v.isNotEmpty),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Leave blank to keep the current password",
                          style: TextStyle(fontSize: 11.5, color: _C.muted),
                        ),

                        const SizedBox(height: 24),
                        _SectionLabel(label: "Role & Status"),
                        const SizedBox(height: 16),

                        // Role dropdown
                        _FieldLabel(label: "Role"),
                        const SizedBox(height: 6),
                        _isLoadingRoles
                            ? Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _C.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _C.border, width: 1.2),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _C.primary),
                                  ),
                                ),
                              )
                            : _roles.isEmpty
                                // fallback text field if API fails
                                ? _InputField(
                                    controller: TextEditingController(
                                        text: _selectedRole ?? widget.initialRole),
                                    hint: "Enter role",
                                    icon: Icons.shield_outlined,
                                  )
                                : _RoleDropdown(
                                    roles: _roles,
                                    selected: _selectedRole,
                                    onChanged: (v) =>
                                        setState(() => _selectedRole = v),
                                  ),

                        const SizedBox(height: 16),

                        // Status toggle
                        _FieldLabel(label: "Account Status"),
                        const SizedBox(height: 8),
                        _StatusToggle(
                          isActive: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Action Buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: _OutlineButton(
                          label: "Cancel",
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save
                      Expanded(
                        flex: 2,
                        child: _SaveButton(
                          isSaving: _isSaving,
                          onTap: _saveChanges,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _C.muted,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.ink,
        ),
      );
}

// ─── Input Field ──────────────────────────────────────────────────────────────
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
                size: 18, color: _focused ? _C.primary : _C.muted),
            hintText: widget.hint,
            hintStyle:
                const TextStyle(color: _C.muted, fontWeight: FontWeight.w400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 15),
          ),
        ),
      ),
    );
  }
}

// ─── Password Field ───────────────────────────────────────────────────────────
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
                size: 18, color: _focused ? _C.primary : _C.muted),
            hintText: "Enter new password (optional)",
            hintStyle:
                const TextStyle(color: _C.muted, fontWeight: FontWeight.w400),
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
                horizontal: 14, vertical: 15),
          ),
        ),
      ),
    );
  }
}

// ─── Role Dropdown ────────────────────────────────────────────────────────────
class _RoleDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _RoleDropdown({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final names = roles.map((r) => r['name'].toString()).toList();
    final safeSelected = names.contains(selected) ? selected : (names.isNotEmpty ? names.first : null);

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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.blueChip,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _C.blueBorder, width: 1),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: _C.blueText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Status Toggle ────────────────────────────────────────────────────────────
class _StatusToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _StatusToggle({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? _C.activeGreen : _C.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _C.activeGreen : _C.primary,
                  ),
                ),
                Text(
                  isActive
                      ? "User can log in and access the system"
                      : "User is blocked from accessing the system",
                  style:
                      const TextStyle(fontSize: 11.5, color: _C.muted),
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

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 50,
          decoration: BoxDecoration(
            color: _hovered ? _C.bg : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border, width: 1.3),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final bool isSaving;
  final VoidCallback onTap;
  const _SaveButton({required this.isSaving, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isSaving) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 50,
        decoration: BoxDecoration(
          color: _pressed ? _C.primaryDark : _C.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(_pressed ? 0.18 : 0.32),
              blurRadius: _pressed ? 6 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: widget.isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}