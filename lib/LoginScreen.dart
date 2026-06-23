import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboardscreen.dart';

// ─── Same AppColors jo dashboard mein hain ───────────────────────────────────
class _C {
  static const bg         = Color(0xFFF5F7FA);
  static const surface    = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF1A2B4A);
  static const primaryMid = Color(0xFF243B5E);
  static const accent     = Color(0xFF3B7DD8);
  static const accentLight= Color(0xFFEBF3FF);
  static const textHead   = Color(0xFF1A2B4A);
  static const textBody   = Color(0xFF3A4A5C);
  static const textMuted  = Color(0xFF8A9BB5);
  static const border     = Color(0xFFE2E8F0);
  static const red        = Color(0xFFE53935);
  static const redLight   = Color(0xFFFFEBEE);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure   = true;
  bool _loading   = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _loginUrl = "http://125.209.66.147:5001/api/auth/signin";

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
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username/email and password.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse(_loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usernameOrEmail": username,
          "password"       : password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body  = jsonDecode(res.body);

        // ✅ API response shape: { "data": { "id", "username", "email",
        //    "role": {...}, "permissions": { "user": [...], "role": [...], ... },
        //    "token"/"accessToken": "..." } }
        // Kabhi kabhi backend alag shape bhi de sakta hai, is liye saare
        // common fallback paths cover kar rahe hain.
        final dataObj = (body['data'] is Map) ? body['data'] as Map : null;

        final token = body['token'] ??
            body['accessToken'] ??
            dataObj?['token'] ??
            dataObj?['accessToken'];

        if (token == null) {
          setState(() {
            _loading = false;
            _error   = 'Login succeeded but no token received.';
          });
          return;
        }

        // 🔍 DEBUG: poora login response print karo taake permissions/user
        // ka exact JSON shape dekh sakein (console / DevTools mein milega)
        print('🔍 FULL LOGIN RESPONSE: ${res.body}');

        // ✅ User info nikalo response se (naam/email)
        // userObj wahi object hai jisme username/email/permissions sab hain
        final userObj = (body['user'] is Map)
            ? body['user'] as Map
            : (dataObj?['user'] is Map)
                ? dataObj!['user'] as Map
                : (dataObj ?? body);

        final loggedInUsername = (userObj['username'] ??
                userObj['name'] ??
                userObj['fullName'] ??
                username)
            .toString();
        final loggedInEmail = (userObj['email'] ?? '').toString();

        // ✅ NEW: Permissions nikalo response se
        // Shape: { "user": ["read","create",...], "role": [...], ... }
        final rawPermissions = userObj['permissions'];
        final permissions = (rawPermissions is Map)
            ? UserPermissions.fromJson(
                rawPermissions.map((k, v) => MapEntry(k.toString(), v)))
            : UserPermissions.empty();

        // ✅ Token _TokenManager mein cache hoga via DashboardScreen
        // Direct navigate to Dashboard — ab actual logged-in user ka
        // naam/email/permissions sab pass ho rahe hain
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => DashboardScreen(
              currentUsername: loggedInUsername,
              currentEmail: loggedInEmail,
              permissions: permissions,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else if (res.statusCode == 401) {
        setState(() {
          _loading = false;
          _error   = 'Invalid username or password.';
        });
      } else {
        setState(() {
          _loading = false;
          _error   = 'Login failed (${res.statusCode}). Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = 'Connection error. Check your internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo & Header ──────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: _C.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: _C.primary.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ],
                      ),
                      child: const Icon(Icons.diamond,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 18),
                    const Text('Diamond Paints',
                        style: TextStyle(
                            color: _C.textHead,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Sign in to your account',
                        style:
                            TextStyle(color: _C.textMuted, fontSize: 13)),
                  ]),
                ),

                const SizedBox(height: 40),

                // ── Error Box ──────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _C.redLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _C.red.withOpacity(0.3), width: 0.8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: _C.red, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: _C.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Username / Email Field ─────────────────────────────────
                _Label('Username or Email'),
                const SizedBox(height: 6),
                _Field(
                  controller: _usernameCtrl,
                  hint: 'Enter username or email',
                  icon: Icons.person_outline_rounded,
                  enabled: !_loading,
                  onSubmit: (_) => FocusScope.of(context).nextFocus(),
                ),

                const SizedBox(height: 16),

                // ── Password Field ─────────────────────────────────────────
                _Label('Password'),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _C.border, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    enabled: !_loading,
                    onSubmitted: (_) => _login(),
                    style: const TextStyle(
                        color: _C.textBody, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:      'Enter password',
                      hintStyle:     const TextStyle(
                          color: _C.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: _C.textMuted, size: 19),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _C.textMuted,
                          size: 19,
                        ),
                      ),
                      border:      InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Login Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      disabledBackgroundColor:
                          _C.primary.withOpacity(0.55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ))
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Footer ─────────────────────────────────────────────────
                Center(
                  child: Text(
                    'Diamond Paints Admin Portal',
                    style: TextStyle(
                        color: _C.textMuted.withOpacity(0.6),
                        fontSize: 11),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: _C.textBody, fontSize: 13, fontWeight: FontWeight.w600),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String>? onSubmit;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.border, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller:    controller,
        enabled:       enabled,
        onSubmitted:   onSubmit,
        style: const TextStyle(color: _C.textBody, fontSize: 14),
        decoration: InputDecoration(
          hintText:      hint,
          hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _C.textMuted, size: 19),
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}