import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Design Tokens ───────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF8F4F0);         // warm parchment canvas
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFE60023);     // Pinterest red
  static const primaryDark = Color(0xFFAD081B);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF767676);
  static const border = Color(0xFFE0DAD4);
  static const chip = Color(0xFFFFF0F1);        // soft red tint
  static const activeGreen = Color(0xFF00A699);
  static const switchTrackOff = Color(0xFFDDD8D3);
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  bool isActive = true;
  bool isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> roles = [
    'Super Admin',
    'Admin',
    'Manager',
    'Vendor',
    'User',
  ];

  final String baseUrl = "http://125.209.66.147:5001/api/users";
  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwidXNlcm5hbWUiOiJzdXBlcmFkbWluIiwidXNlcklkIjoxLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiU3VwZXIgQWRtaW4iLCJyZWdpb25JZHMiOltdLCJjYXJkX25hbWUiOm51bGwsInVzZXJfdHlwZSI6bnVsbCwidXNlcl9jb2RlIjpudWxsLCJwZXJtaXNzaW9ucyI6eyJ2ZW5kb3JBc3NpZ25tZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwidXNlciI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInJvbGUiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSJdLCJ2ZW5kb3JSZXF1ZXN0cyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNob3Bib2FyZFJlcXVlc3QiOlsicmVhZCIsImNyZWF0ZSIsInVwZGF0ZSIsImRlbGV0ZSIsImFwcHJvdmFscyJdLCJyZXF1ZXN0UHJpY2VBZGp1c3RtZW50IjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwicmVxdWVzdFR5cGVzIjpbInJlYWQiLCJjcmVhdGUiLCJ1cGRhdGUiLCJkZWxldGUiXSwic3RhdGlzdGljcyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sImJ1ZGdldE1hbmFnZW1lbnQiOlsiY3JlYXRlIiwicmVhZCIsInVwZGF0ZSIsImRlbGV0ZSJdLCJwYXltZW50cyI6WyJjcmVhdGUiLCJyZWFkIiwidXBkYXRlIiwiZGVsZXRlIl0sInBheW1lbnRCYXRjaCI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl0sInNtdHBTZXR0aW5ncyI6WyJyZWFkIiwiY3JlYXRlIiwidXBkYXRlIiwiZGVsZXRlIl19LCJtb2JpbGVQZXJtaXNzaW9ucyI6e30sImlhdCI6MTc3ODUwMDEyNywiZXhwIjoxNzc5MTA0OTI3fQ.fYDaxlSNiXIqvXjvoazBJu5TQ-NFhm2gC6G_oc_J5O8";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUser() async {
    setState(() => _isLoading = true);
    final url = Uri.parse(baseUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": usernameController.text,
          "email": emailController.text,
          "password": passwordController.text,
          "role": selectedRole,
          "is_active": isActive,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to create user"),
            backgroundColor: _C.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Something went wrong"),
          backgroundColor: _C.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── shared input decoration ────────────────────────────────────────────────
  InputDecoration _dec(String label, {Widget? suffix, IconData? prefixIcon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: _C.muted, fontSize: 13.5, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(
            color: _C.primary, fontSize: 12, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: _C.bg,
        suffixIcon: suffix,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _C.muted)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primaryDark, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primaryDark, width: 1.8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: _C.primary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _C.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Create User",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _C.ink,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  "Fill in the details to add a new member",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _C.muted,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                          _CloseButton(onTap: () => Navigator.pop(context)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Username ────────────────────────────────────────
                      TextFormField(
                        controller: usernameController,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        decoration: _dec("Username *",
                            prefixIcon: Icons.person_outline_rounded),
                        validator: (v) =>
                            v!.isEmpty ? "Please enter username" : null,
                      ),

                      const SizedBox(height: 14),

                      // ── Email ───────────────────────────────────────────
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        decoration: _dec("Email",
                            prefixIcon: Icons.mail_outline_rounded),
                      ),

                      const SizedBox(height: 14),

                      // ── Role Dropdown ───────────────────────────────────
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _C.muted),
                        dropdownColor: _C.surface,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        decoration: _dec("Role *",
                            prefixIcon: Icons.shield_outlined),
                        items: roles
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedRole = v),
                        validator: (v) =>
                            v == null ? "Please select role" : null,
                      ),

                      const SizedBox(height: 18),

                      // ── Active Switch ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _C.activeGreen.withOpacity(0.06)
                              : _C.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? _C.activeGreen.withOpacity(0.25)
                                : _C.border,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: isActive ? _C.activeGreen : _C.muted,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Active",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _C.ink),
                                    ),
                                    Text(
                                      isActive
                                          ? "User can log in"
                                          : "Access suspended",
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isActive
                                              ? _C.activeGreen
                                              : _C.muted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setState(() => isActive = v),
                              activeColor: _C.activeGreen,
                              activeTrackColor:
                                  _C.activeGreen.withOpacity(0.22),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: _C.switchTrackOff,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Password ────────────────────────────────────────
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        decoration: _dec(
                          "Password *",
                          prefixIcon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: _C.muted,
                            ),
                            onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible),
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Please enter password" : null,
                      ),

                      const SizedBox(height: 26),

                      // ── Action Buttons ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _C.muted,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: _C.border, width: 1.2),
                              ),
                            ),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  letterSpacing: 0.6),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Create
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.primary.withOpacity(0.32),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        createUser();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _C.primary.withOpacity(0.55),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "CREATE",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          letterSpacing: 0.8),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Close Button Widget ───────────────────────────────────────────────────────
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered ? _C.chip : _C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.1),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _hovered ? _C.primary : _C.muted,
          ),
        ),
      ),
    );
  }
}