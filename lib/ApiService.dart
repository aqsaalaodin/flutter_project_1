import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Auth Service — Automatic Login & Token Manager ──────────────────────────
// Handles authentication automatically. Fetches a fresh token on startup,
// caches it in memory, and re-authenticates whenever it expires or is rejected.

class AuthService {
  static const _baseUrl  = "http://125.209.66.147:5001/api";
  static const _username = "superadmin";
  static const _password = "admin123";

  static String?   _token;
  static DateTime? _tokenExpiry;
  static bool      _isRefreshing = false;

  // ── Returns a valid token, refreshing automatically if near expiry ─────────
  static Future<String> getToken() async {
    // Reuse cached token if it has more than 5 minutes remaining
    if (_token != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return _token!;
    }

    // Token is absent or about to expire — fetch a new one
    return await _login();
  }

  // ── Performs login and stores the returned token ───────────────────────────
  static Future<String> _login() async {
    // If a refresh is already in progress, wait briefly and return cached token
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_token != null) return _token!;
    }

    _isRefreshing = true;
    try {
      final res = await http
          .post(
            Uri.parse("$_baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "usernameOrEmail": _username,
              "password": _password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);

        // Support multiple common token field names returned by different APIs
        final token = data['token']           ??
                      data['accessToken']     ??
                      data['access_token']    ??
                      data['data']?['token']  ??
                      data['data']?['accessToken'];

        if (token == null) {
          throw Exception("Token not found in login response: ${res.body}");
        }

        _token = token as String;

        // Extract expiry from the JWT payload; fall back to 7 days if absent
        _tokenExpiry = _extractExpiry(_token!) ??
            DateTime.now().add(const Duration(days: 7));

        print("Token refreshed successfully. Expiry: $_tokenExpiry");
        return _token!;
      } else {
        throw Exception("Login failed: ${res.statusCode} — ${res.body}");
      }
    } catch (e) {
      print("Login error: $e");
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Decodes the JWT payload and extracts the expiry timestamp ─────────────
  static DateTime? _extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Add Base64 padding if required before decoding
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final exp = decoded['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  // ── Builds request headers with a valid Bearer token ──────────────────────
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ── Clears the cached token, forcing a fresh login on the next request ─────
  static void invalidateToken() {
    _token = null;
    _tokenExpiry = null;
  }
}

// ─── API Service — Authenticated HTTP Requests with Auto-Retry ───────────────
// Wraps all HTTP methods with automatic authentication.
// If a request returns 401 Unauthorized, the token is invalidated and
// the request is retried once with a freshly obtained token.

class ApiService {
  static const baseUrl = "http://125.209.66.147:5001/api";

  // ── Authenticated GET request ──────────────────────────────────────────────
  static Future<http.Response> get(String endpoint) async {
    return _requestWithRetry(() async {
      final headers = await AuthService.getHeaders();
      return http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
    });
  }

  // ── Authenticated POST request ─────────────────────────────────────────────
  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry(() async {
      final headers = await AuthService.getHeaders();
      return http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
    });
  }

  // ── Authenticated PUT request ──────────────────────────────────────────────
  static Future<http.Response> put(
      String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry(() async {
      final headers = await AuthService.getHeaders();
      return http.put(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
    });
  }

  // ── Authenticated DELETE request ───────────────────────────────────────────
  static Future<http.Response> delete(String endpoint) async {
    return _requestWithRetry(() async {
      final headers = await AuthService.getHeaders();
      return http.delete(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
    });
  }

  // ── Executes a request and retries once with a fresh token on 401 ──────────
  static Future<http.Response> _requestWithRetry(
      Future<http.Response> Function() request) async {
    var response = await request();

    if (response.statusCode == 401) {
      print("401 Unauthorized — invalidating token and retrying...");
      AuthService.invalidateToken();
      response = await request();
    }

    return response;
  }
}