import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF5F7FA);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F9);

  static const primary    = Color(0xFF1A2B4A);
  static const primaryMid = Color(0xFF243B5E);

  static const accent      = Color(0xFF3B7DD8);
  static const accentLight = Color(0xFFEBF3FF);

  static const red          = Color(0xFFE53935);
  static const redLight     = Color(0xFFFFEBEE);

  static const success      = Color(0xFF26A69A);
  static const successLight = Color(0xFFE0F2F1);

  static const warning      = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);

  static const purple      = Color(0xFF5C35B5);
  static const purpleLight = Color(0xFFEFEBFA);

  static const textHead  = Color(0xFF1A2B4A);
  static const textBody  = Color(0xFF3A4A5C);
  static const textMuted = Color(0xFF8A9BB5);

  static const border  = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);
}

// ─── Auth Service — Token Manager ────────────────────────────────────────────
// Yeh class pehle login karti hai aur fresh token return karti hai
// Hardcoded token ka masla hamesha k liye khatam

class _AuthService {
  static const _baseUrl      = "http://125.209.66.147:5001/api";
  static const _loginEmail   = "superadmin";
  static const _loginPass    = "admin123";

  // In-memory token cache (app session tak)
  static String? _cachedToken;

  /// Fresh token lo — agar cache mein hai to wahi, warna login karo
  static Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;
    return await _login();
  }

  /// Token invalidate karo (401 aane par)
  static void invalidate() => _cachedToken = null;

  static Future<String> _login() async {
    final url = Uri.parse("$_baseUrl/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usernameOrEmail": _loginEmail,
        "password": _loginPass,
      }),
    );

    print("Login Status: ${response.statusCode}");
    print("Login Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Common token field names — jo bhi API return kare
      final token = data['token']
          ?? data['accessToken']
          ?? data['access_token']
          ?? data['data']?['token']
          ?? data['data']?['accessToken'];

      if (token == null) {
        throw Exception("Token field nahi mila response mein: ${response.body}");
      }

      _cachedToken = token as String;
      print("Token cached successfully ✓");
      return _cachedToken!;
    } else {
      throw Exception("Login failed: ${response.statusCode} — ${response.body}");
    }
  }
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
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  bool isActive          = true;
  bool isPasswordVisible = false;
  bool _isLoading        = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final List<String> roles = [
    'Super Admin',
    'Admin',
    'Manager',
    'Vendor',
    'User',
  ];

  static const _baseUrl = "http://125.209.66.147:5001/api/users";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
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

  // ── User Create — with auto-token + retry on 401 ──────────────────────────
  Future<void> createUser() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: fresh token lo (login auto hoga agar cached nahi)
      final token = await _AuthService.getToken();

      // Step 2: user create karo
      final success = await _postCreateUser(token);

      // Step 3: agar 401 aaya — token expire tha, dobara login karo
      if (!success) {
        print("401 mila — token invalidate karke retry...");
        _AuthService.invalidate();
        final freshToken = await _AuthService.getToken();
        await _postCreateUser(freshToken, isRetry: true);
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        _showSnack("Error: ${e.toString().replaceAll('Exception: ', '')}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns true = success/handled, false = needs retry (401)
  Future<bool> _postCreateUser(String token, {bool isRetry = false}) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "username" : usernameController.text.trim(),
        "email"    : emailController.text.trim(),
        "password" : passwordController.text,
        "role"     : selectedRole,
        "is_active": isActive,
      }),
    );

    print("Create User Status: ${response.statusCode}");
    print("Create User Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (mounted) Navigator.pop(context, true);
      return true;
    } else if (response.statusCode == 401 && !isRetry) {
      // Retry signal
      return false;
    } else {
      // Parse server error message agar ho
      String errMsg = "User create nahi hua (${response.statusCode})";
      try {
        final body = jsonDecode(response.body);
        errMsg = body['message'] ?? body['error'] ?? errMsg;
      } catch (_) {}

      if (mounted) _showSnack(errMsg);
      return true; // handled
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _C.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Shared input decoration ───────────────────────────────────────────────
  InputDecoration _dec(String label, {Widget? suffix, IconData? prefixIcon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: _C.textMuted, fontSize: 13.5, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(
            color: _C.accent, fontSize: 12, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: _C.bg,
        suffixIcon: suffix,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _C.textMuted)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border, width: 0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ────────────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: _C.primary,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: _C.primaryMid.withOpacity(0.35),
                                  width: 0.8),
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Create User',
                                    style: TextStyle(
                                        color: _C.textHead,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.1)),
                                SizedBox(height: 1),
                                Text('Add a new member to the system',
                                    style: TextStyle(
                                        color: _C.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: _C.surfaceAlt,
                                borderRadius: BorderRadius.circular(9),
                                border:
                                    Border.all(color: _C.border, width: 0.7),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: _C.textMuted, size: 17),
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                            color: _C.divider, thickness: 0.8, height: 0),
                      ),

                      // ── Account Details ───────────────────────────────────
                      const _SectionLabel('Account Details'),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: usernameController,
                        style: const TextStyle(
                            color: _C.textHead,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600),
                        decoration: _dec('Username *',
                            prefixIcon: Icons.person_outline_rounded),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Please enter username' : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            color: _C.textHead,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600),
                        decoration: _dec('Email',
                            prefixIcon: Icons.mail_outline_rounded),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(
                            color: _C.textHead,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600),
                        decoration: _dec(
                          'Password *',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: _C.textMuted,
                            ),
                            onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible),
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter password' : null,
                      ),

                      const SizedBox(height: 18),

                      // ── Permissions ───────────────────────────────────────
                      const _SectionLabel('Permissions'),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _C.textMuted),
                        dropdownColor: _C.surface,
                        style: const TextStyle(
                            color: _C.textHead,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600),
                        decoration: _dec('Role *',
                            prefixIcon: Icons.admin_panel_settings_rounded),
                        items: roles
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedRole = v),
                        validator: (v) =>
                            v == null ? 'Please select role' : null,
                      ),

                      const SizedBox(height: 12),

                      // ── Active Switch ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isActive ? _C.accentLight : _C.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? _C.accent.withOpacity(0.30)
                                : _C.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _C.accent.withOpacity(0.12)
                                    : _C.border.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 17,
                                color: isActive ? _C.accent : _C.textMuted,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Active Status',
                                      style: TextStyle(
                                          color: _C.textHead,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 1),
                                  Text(
                                    isActive
                                        ? 'User can log in'
                                        : 'Access suspended',
                                    style: TextStyle(
                                        color: isActive
                                            ? _C.accent
                                            : _C.textMuted,
                                        fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setState(() => isActive = v),
                              activeColor: _C.accent,
                              activeTrackColor: _C.accent.withOpacity(0.20),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: _C.border,
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                            color: _C.divider, thickness: 0.8, height: 0),
                      ),

                      // ── Action Buttons ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [

                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: _C.surfaceAlt,
                                borderRadius: BorderRadius.circular(11),
                                border:
                                    Border.all(color: _C.border, width: 0.8),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      color: _C.textBody,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),

                          const SizedBox(width: 10),

                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      createUser();
                                    }
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLoading
                                    ? _C.primary.withOpacity(0.55)
                                    : _C.primary,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _C.primary.withOpacity(0.30),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_add_rounded,
                                            color: Colors.white, size: 15),
                                        SizedBox(width: 7),
                                        Text('Create User',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2)),
                                      ],
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

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: _C.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1),
    );
  }
}